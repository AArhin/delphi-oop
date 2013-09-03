unit REST.Client;

interface

uses
  Rtti
  ,HTTPClient
  ,SvVMI
  ,Generics.Collections
  ,Classes
  ;


type

  GETAttribute = class(TCustomAttribute)
  end;

  POSTAttribute = class(TCustomAttribute)
  end;

  PUTAttribute = class(TCustomAttribute)
  end;

  DELETEAttribute = class(TCustomAttribute)
  end;

  QueryParamsAttribute = class(TCustomAttribute)
  end;

  FormParamsAttribute = class(TCustomAttribute)
  end;

  HeaderParamsAttribute = class(TCustomAttribute)
  end;

  PathAttribute = class(TCustomAttribute)
  public
    Path: string;
  public
    constructor Create(const APath: string);
  end;

  ProducesAttribute = class(TCustomAttribute)
  public
    MediaType: MEDIA_TYPE;
  public
    constructor Create(const AMediaType: MEDIA_TYPE);
  end;

  ConsumesAttribute = class(ProducesAttribute);

  TRequestType = (rtGet, rtPost, rtPut, rtDelete);

  TRESTMethodParameter = class
  private
    FName: string;
    FValue: TValue;
  public
    function ToString(): string; reintroduce;

    property Name: string read FName write FName;
    property Value: TValue read FValue write FValue;
  end;

  TRESTMethod = class
  private
    FRequestType: TRequestType;
    FName: string;
    FPath: string;
    FParameters: TObjectList<TRESTMethodParameter>;
    FReturnValue: TValue;
    FMediaType: MEDIA_TYPE;
    FUrl: string;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    property MediaType: MEDIA_TYPE read FMediaType write FMediaType;
    property Name: string read FName write FName;
    property RequestType: TRequestType read FRequestType write FRequestType;
    property Path: string read FPath write FPath;
    property Parameters: TObjectList<TRESTMethodParameter> read FParameters;
    property ReturnValue: TValue read FReturnValue write FReturnValue;
    property Url: string read FUrl write FUrl;
  end;


  TRESTClient<T: class> = class(TInterfacedObject)
  private
    FCtx: TRttiContext;
    FURL: string;
    FVMI: TSvVirtualMethodInterceptor;
    FHttp: THTTPClient;
    FMethods: TObjectDictionary<Pointer,TRESTMethod>;
  protected
    procedure DoOnAfter(Instance: TObject; Method: TRttiMethod;
      const Args: TArray<TValue>; var Result: TValue);
    procedure DoRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TRESTMethod;
      var Result: TValue);
    procedure DoGetRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TRESTMethod;
      var Result: TValue); virtual;
    procedure DoPostRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TRESTMethod;
      var Result: TValue); virtual;
    function IsMethodMarked(AMethod: TRttiMethod): Boolean;
    function GetRESTMethod(AMethod: TRttiMethod): TRESTMethod;
    function GetRequestType(AMethod: TRttiMethod): TRequestType;
    procedure EnumerateRESTMethods();
    function GenerateUrl(ARestMethod: TRESTMethod): string;
    function DoCheckPathParameters(const AUrl: string; ARestMethod: TRESTMethod): string;
    function GenerateSourceContent(ARestMethod: TRESTMethod): TStream;
    function GetSerializedDataString(const AValue: TValue; ARestMethod: TRESTMethod): string;
    function SerializeObjectToString(AObject: TObject; ARestMethod: TRESTMethod): string;
    procedure FillRestMethodParameters(const Args: TArray<TValue>; ARestMethod: TRESTMethod; AMethod: TRttiMethod);
    function ConsumeMediaType(ARttiType: TRttiType; const ASource: TValue; ARestMethod: TRESTMethod): TValue; virtual;
    function ConsumeMediaTypeAsString(ARttiType: TRttiType; const ASource: TValue; ARestMethod: TRESTMethod): string; virtual;
  public
    constructor Create(const AUrl: string); virtual;
    destructor Destroy; override;

    procedure SetHttpClient(const AHttpClientName: string = 'idHttp');

    property HttpClient: THTTPClient read FHttp;
    property Url: string read FURL;
  end;

implementation

uses
  SvSerializer
  ,SvSerializerSuperJson
  ,SvSerializerNativeXML
  ,SysUtils
  ,SysConst
  ,StrUtils
  ;

{ TRESTClient }

function TRESTClient<T>.ConsumeMediaType(ARttiType: TRttiType; const ASource: TValue; ARestMethod: TRESTMethod): TValue;
begin
  Result := TValue.Empty;
  if ARttiType <> nil then
  begin
    if ARttiType.IsInstance then
    begin
      Result := ARttiType.AsInstance.MetaclassType.Create;
      case ARestMethod.MediaType of
        MEDIA_TYPE.JSON: TSvSerializer.DeSerializeObject(Result.AsObject, GetSerializedDataString(ASource, ARestMethod), sstSuperJson);
        MEDIA_TYPE.XML: TSvSerializer.DeSerializeObject(Result.AsObject, GetSerializedDataString(ASource, ARestMethod), sstNativeXML);
      end;
    end
    else
      Result := ASource.ToString;
  end;
end;

function TRESTClient<T>.ConsumeMediaTypeAsString(ARttiType: TRttiType; const ASource: TValue;
  ARestMethod: TRESTMethod): string;
begin
  Result := '';
  if ARttiType <> nil then
  begin
    if ARttiType.IsInstance then
    begin
      Result := GetSerializedDataString(ASource, ARestMethod);
    end
    else
      Result := ASource.ToString;
  end;
end;

constructor TRESTClient<T>.Create(const AUrl: string);
begin
  inherited Create();
  FCtx := TRttiContext.Create;
  FURL := AUrl;
  FHttp := nil;
  FVMI := TSvVirtualMethodInterceptor.Create(Self.ClassType);
  FMethods := TObjectDictionary<Pointer,TRESTMethod>.Create([doOwnsValues]);

  FVMI.OnBefore := procedure(Instance: TObject;
    Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
    out Result: TValue)
    begin
      DoInvoke := False;
      DoOnAfter(Instance, Method, Args, Result);
    end;

 { FVMI.OnAfter := procedure(Instance: TObject;
    Method: TRttiMethod; const Args: TArray<TValue>; var Result: TValue)
    begin
      DoOnAfter(Instance, Method, Args, Result);
    end;}

  EnumerateRESTMethods();
  FVMI.Proxify(Self);
end;

destructor TRESTClient<T>.Destroy;
begin
  if Assigned(FHttp) then
    FHttp.Free;
  FMethods.Free;
  FVMI.Unproxify(Self);
  FVMI.Free;
  inherited Destroy;
end;

function TRESTClient<T>.DoCheckPathParameters(const AUrl: string; ARestMethod: TRESTMethod): string;
var
  i: Integer;
  LPosTokenStart, LPosTokenEnd: Integer;
  LParsedParamName: string;
begin
  Result := AUrl;
  LPosTokenEnd := 0;
  LPosTokenStart := PosEx('{', Result);
  if LPosTokenStart > 0 then
    LPosTokenEnd := PosEx('}', Result, LPosTokenStart);
  while (LPosTokenStart > 0) and (LPosTokenEnd > LPosTokenStart) do
  begin
    LParsedParamName := Copy(Result, LPosTokenStart + 1, LPosTokenEnd - LPosTokenStart - 1);
    //search for this parameter
    for i := ARestMethod.Parameters.Count - 1 downto 0 do
    begin
      if SameText(LParsedParamName, ARestMethod.Parameters[i].Name) then
      begin
        //inject parameter value into query
        Result := ReplaceStr(Result, '{' + LParsedParamName + '}', ARestMethod.Parameters[i].ToString);
        ARestMethod.Parameters.Delete(i);
        Break;
      end;
    end;
    LPosTokenStart := PosEx('{', Result);
      if LPosTokenStart > 0 then
        LPosTokenEnd := PosEx('}', Result, LPosTokenStart);
  end;
end;

procedure TRESTClient<T>.DoGetRequest(Method: TRttiMethod; const Args: TArray<TValue>;
  ARestMethod: TRESTMethod; var Result: TValue);
var
  LResponse: TStringStream;
  LDataString: string;
begin
  LResponse := TStringStream.Create;
  try
    if (FHttp.Get(ARestMethod.Url, LResponse) = 200)  then
    begin
      if LResponse.Size > 0 then
      begin
        Result := ConsumeMediaType(Method.ReturnType, LResponse, ARestMethod);
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TRESTClient<T>.DoOnAfter(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>;
  var Result: TValue);
var
  LMethod: TRESTMethod;
begin
  if not FMethods.TryGetValue(Method.Handle, LMethod) then
    Exit;

  FillRestMethodParameters(Args, LMethod, Method);
  DoRequest(Method, Args, LMethod, Result);
end;

procedure TRESTClient<T>.DoPostRequest(Method: TRttiMethod; const Args: TArray<TValue>;
  ARestMethod: TRESTMethod; var Result: TValue);
var
  LResponse: TStringStream;
  LSourceContent: TStream;
begin
  LResponse := TStringStream.Create;
  LSourceContent := GenerateSourceContent(ARestMethod);
  try
    if (FHttp.Post(ARestMethod.Url, LResponse, LSourceContent) = 200) then
    begin
      if LResponse.Size > 0 then
      begin
        Result := ConsumeMediaType(Method.ReturnType, LResponse, ARestMethod);
      end;
    end;
  finally
    LSourceContent.Free;
    LResponse.Free;
  end;
end;

procedure TRESTClient<T>.DoRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TRESTMethod;
  var Result: TValue);
begin
  FHttp.MediaType := ARestMethod.MediaType;
  ARestMethod.Url := GenerateUrl(ARestMethod);

  case ARestMethod.RequestType of
    rtGet: DoGetRequest(Method, Args, ARestMethod, Result);
    rtPost: DoPostRequest(Method, Args, ARestMethod, Result);
    rtPut: ;
    rtDelete: ;
  end;
end;

procedure TRESTClient<T>.EnumerateRESTMethods;
var
  LType: TRttiType;
  LMethod: TRttiMethod;
  LAttr: TCustomAttribute;
begin
  FMethods.Clear;

  LType := FCtx.GetType(Self.ClassType);
  for LMethod in LType.GetMethods do
  begin
    if IsMethodMarked(LMethod) then
    begin
      FMethods.Add(LMethod.Handle, GetRESTMethod(LMethod));
    end;
  end;

  for LAttr in LType.GetAttributes do
  begin
    if LAttr is PathAttribute then
    begin
      FURL := FURL + PathAttribute(LAttr).Path;
      Exit;
    end;
  end;
end;

procedure TRESTClient<T>.FillRestMethodParameters(const Args: TArray<TValue>; ARestMethod: TRESTMethod; AMethod: TRttiMethod);
var
  i: Integer;
  LParameters: TArray<TRttiParameter>;
begin
  LParameters := AMethod.GetParameters;
  for i := Low(Args) to High(Args) do
  begin
    ARestMethod.Parameters[i].Value := ConsumeMediaTypeAsString(LParameters[i].ParamType, Args[i], ARestMethod);
  end;
end;

function TRESTClient<T>.GenerateSourceContent(ARestMethod: TRESTMethod): TStream;
var
  LParams: TStringList;
  i: Integer;
begin
  Result := TMemoryStream.Create;
  LParams := TStringList.Create;
  try
    for i := 0 to ARestMethod.Parameters.Count - 1 do
    begin
      LParams.Add(Format('"%S"="%S"'
        , [ARestMethod.Parameters[i].Name, ARestMethod.Parameters[i].ToString]));
    end;
    LParams.SaveToStream(Result, TEncoding.UTF8);
  finally
    LParams.Free;
  end;
end;

function TRESTClient<T>.GenerateUrl(ARestMethod: TRESTMethod): string;
var
  i: Integer;
begin
  Result := FURL;
  if ARestMethod.Path <> '' then
    Result := Result + ARestMethod.Path;

  if ARestMethod.RequestType <> rtGet then
    Exit;

  Result := DoCheckPathParameters(Result, ARestMethod);

  if ARestMethod.Parameters.Count > 0 then
    Result := Result + '?';

  for i := 0 to ARestMethod.Parameters.Count - 1 do
  begin
    if i <> 0 then
      Result := Result + '&';

    Result := Result + Format('%S=%S', [ARestMethod.Parameters[i].Name, ARestMethod.Parameters[i].ToString]);
  end;
end;

function TRESTClient<T>.GetRequestType(AMethod: TRttiMethod): TRequestType;
var
  LAttrib: TCustomAttribute;
begin
  for LAttrib in AMethod.GetAttributes do
  begin
    if LAttrib is GETAttribute then
      Exit(rtGet)
    else if LAttrib is POSTAttribute then
      Exit(rtPost)
    else if LAttrib is PUTAttribute then
      Exit(rtPut)
    else if LAttrib is DELETEAttribute then
      Exit(rtDelete);
  end;
  Result := rtGet;
end;

function TRESTClient<T>.GetRESTMethod(AMethod: TRttiMethod): TRESTMethod;
var
  LAttr: TCustomAttribute;
  LParam: TRttiParameter;
  LRestParam: TRESTMethodParameter;
begin
  Result := TRESTMethod.Create;
  Result.Name := AMethod.Name;

  for LAttr in AMethod.GetAttributes do
  begin
    if LAttr is GETAttribute then
      Result.RequestType := rtGet
    else if LAttr is POSTAttribute then
      Result.RequestType := rtPost
    else if LAttr is PUTAttribute then
      Result.RequestType := rtPut
    else if LAttr is DELETEAttribute then
      Result.RequestType := rtDelete
    else if LAttr is PathAttribute then
      Result.Path := PathAttribute(LAttr).Path
    else if LAttr is ConsumesAttribute then
      Result.MediaType := ConsumesAttribute(LAttr).MediaType;
  end;

  for LParam in AMethod.GetParameters do
  begin
    LRestParam := TRESTMethodParameter.Create;
    LRestParam.Name := LParam.Name;
    Result.Parameters.Add(LRestParam);
  end;
end;

function TRESTClient<T>.GetSerializedDataString(const AValue: TValue; ARestMethod: TRESTMethod): string;
var
  LObject: TObject;
begin
  Result := '';
  if AValue.IsEmpty then
    Exit;

  if AValue.IsObject then
  begin
    LObject := AValue.AsObject;
    if not Assigned(LObject) then
      Exit;

    if LObject is TStringStream then
      Result := TStringStream(LObject).DataString
    else
    begin
      //serialize object to string
      Result := SerializeObjectToString(LObject, ARestMethod);
    end;
  end
  else
  begin
    Result := AValue.ToString;
  end;
end;

function TRESTClient<T>.IsMethodMarked(AMethod: TRttiMethod): Boolean;
var
  LAttrib: TCustomAttribute;
begin
  for LAttrib in AMethod.GetAttributes do
  begin
    Result := (LAttrib is GETAttribute) or (LAttrib is POSTAttribute)
      or (LAttrib is DELETEAttribute) or (LAttrib is PUTAttribute);
    if Result then
      Exit;
  end;
  Result := False;
end;

function TRESTClient<T>.SerializeObjectToString(AObject: TObject; ARestMethod: TRESTMethod): string;
begin
  Result := '';
  case ARestMethod.MediaType of
    MEDIA_TYPE.JSON: TSvSerializer.SerializeObject(AObject, Result, sstSuperJson);
    MEDIA_TYPE.XML: TSvSerializer.SerializeObject(AObject, Result, sstNativeXML);
  end;
end;

procedure TRESTClient<T>.SetHttpClient(const AHttpClientName: string);
begin
  if Assigned(FHttp) then
    FreeAndNil(FHttp);

  FHttp := THTTPClientFactory.GetInstance(AHttpClientName);
end;

{ TRESTMethodParameter }

function TRESTMethodParameter.ToString: string;
begin
  Result := FValue.ToString;
end;

{ TRESTMethod }

constructor TRESTMethod.Create;
begin
  inherited Create();
  FParameters := TObjectList<TRESTMethodParameter>.Create(True);
  FReturnValue := TValue.Empty;
end;

destructor TRESTMethod.Destroy;
begin
  FParameters.Free;
  inherited Destroy;
end;

{ PathAttribute }

constructor PathAttribute.Create(const APath: string);
begin
  inherited Create;
  Path := APath;
end;

{ ProducesAttribute }

constructor ProducesAttribute.Create(const AMediaType: MEDIA_TYPE);
begin
  inherited Create();
  MediaType := AMediaType;
end;

end.
