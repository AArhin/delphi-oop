unit REST.Client;

interface

uses
  Rtti
  ,HTTPClientInterface
  ,REST.Method
  ,Web.Consts
  ,SvVMI
  ,Generics.Collections
  ,Classes
  ,TypInfo
  ;

type
  TRESTClient = class(TInterfacedObject)
  private
    FCtx: TRttiContext;
    FURL: string;
    FVMI: TSvVirtualMethodInterceptor;
    FHttp: IHTTPClient;
    FMethods: TObjectDictionary<Pointer,TRESTMethod>;
    FProxyObject: TObject;
    FProxyTypeInfo: PTypeInfo;
  protected
    procedure DoOnAfter(Instance: TObject; Method: TRttiMethod;
      const Args: TArray<TValue>; var Result: TValue);
    procedure DoRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TRESTMethod;
      var Result: TValue); virtual;
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
    constructor Create(const AUrl: string; AProxyObject: TObject = nil; AProxyType: PTypeInfo = nil); virtual;
    destructor Destroy; override;

    procedure SetHttpClient(const AHttpClientName: string = HTTP_CLIENT_INDY);

    property HttpClient: IHTTPClient read FHttp write FHttp;
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
  ,HTTPClient.Factory
  ,HTTP.Attributes
  ;

{ TRESTClient }

function TRESTClient.ConsumeMediaType(ARttiType: TRttiType; const ASource: TValue; ARestMethod: TRESTMethod): TValue;
begin
  Result := TValue.Empty;
  if ARttiType <> nil then
  begin
    if ARttiType.IsInstance then
    begin
      Result := ARttiType.AsInstance.MetaclassType.Create;
      case ARestMethod.ConsumeMediaType of
        MEDIA_TYPE.JSON: TSvSerializer.DeSerializeObject(Result.AsObject, GetSerializedDataString(ASource, ARestMethod), sstSuperJson);
        MEDIA_TYPE.XML: TSvSerializer.DeSerializeObject(Result.AsObject, GetSerializedDataString(ASource, ARestMethod), sstNativeXML);
      end;
    end
    else
      Result := ASource.ToString;
  end;
end;

function TRESTClient.ConsumeMediaTypeAsString(ARttiType: TRttiType; const ASource: TValue;
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

constructor TRESTClient.Create(const AUrl: string; AProxyObject: TObject = nil; AProxyType: PTypeInfo = nil);
begin
  inherited Create();
  FProxyObject := AProxyObject;
  if FProxyObject = nil then
    FProxyObject := Self;

  FProxyTypeInfo := AProxyType;
  if FProxyTypeInfo = nil then
    FProxyTypeInfo := Self.ClassInfo;

  FCtx := TRttiContext.Create;
  FURL := AUrl;
  FHttp := nil;
  FVMI := TSvVirtualMethodInterceptor.Create(FProxyObject.ClassType);
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
  FVMI.Proxify(FProxyObject);
end;

destructor TRESTClient.Destroy;
begin
  FMethods.Free;
  FVMI.Unproxify(FProxyObject);
  FVMI.Free;
  inherited Destroy;
end;

function TRESTClient.DoCheckPathParameters(const AUrl: string; ARestMethod: TRESTMethod): string;
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

procedure TRESTClient.DoGetRequest(Method: TRttiMethod; const Args: TArray<TValue>;
  ARestMethod: TRESTMethod; var Result: TValue);
var
  LResponse: TStringStream;
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

procedure TRESTClient.DoOnAfter(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>;
  var Result: TValue);
var
  LMethod: TRESTMethod;
begin
  if not FMethods.TryGetValue(Method.Handle, LMethod) then
    Exit;

  FillRestMethodParameters(Args, LMethod, Method);
  DoRequest(Method, Args, LMethod, Result);
end;

procedure TRESTClient.DoPostRequest(Method: TRttiMethod; const Args: TArray<TValue>;
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

procedure TRESTClient.DoRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TRESTMethod;
  var Result: TValue);
begin
  FHttp.ConsumeMediaType := ARestMethod.ConsumeMediaType;
  FHttp.ProduceMediaType := ARestMethod.ProduceMediaType;
  ARestMethod.Url := GenerateUrl(ARestMethod);

  case ARestMethod.RequestType of
    rtGet: DoGetRequest(Method, Args, ARestMethod, Result);
    rtPost: DoPostRequest(Method, Args, ARestMethod, Result);
    rtPut: ;
    rtDelete: ;
  end;
end;

procedure TRESTClient.EnumerateRESTMethods;
var
  LType: TRttiType;
  LMethod: TRttiMethod;
  LAttr: TCustomAttribute;
begin
  FMethods.Clear;

  LType := FCtx.GetType(FProxyTypeInfo);
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

procedure TRESTClient.FillRestMethodParameters(const Args: TArray<TValue>; ARestMethod: TRESTMethod; AMethod: TRttiMethod);
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

function TRESTClient.GenerateSourceContent(ARestMethod: TRESTMethod): TStream;
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

function TRESTClient.GenerateUrl(ARestMethod: TRESTMethod): string;
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

function TRESTClient.GetRequestType(AMethod: TRttiMethod): TRequestType;
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

function TRESTClient.GetRESTMethod(AMethod: TRttiMethod): TRESTMethod;
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
    else if LAttr is ProducesAttribute then
      Result.ProduceMediaType := ProducesAttribute(LAttr).MediaType
    else if LAttr is ConsumesAttribute then
      Result.ConsumeMediaType := ConsumesAttribute(LAttr).MediaType;
  end;

  for LParam in AMethod.GetParameters do
  begin
    LRestParam := TRESTMethodParameter.Create;
    LRestParam.Name := LParam.Name;
    Result.Parameters.Add(LRestParam);
  end;
end;

function TRESTClient.GetSerializedDataString(const AValue: TValue; ARestMethod: TRESTMethod): string;
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

function TRESTClient.IsMethodMarked(AMethod: TRttiMethod): Boolean;
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

function TRESTClient.SerializeObjectToString(AObject: TObject; ARestMethod: TRESTMethod): string;
begin
  Result := '';
  case ARestMethod.ProduceMediaType of
    MEDIA_TYPE.JSON: TSvSerializer.SerializeObject(AObject, Result, sstSuperJson);
    MEDIA_TYPE.XML: TSvSerializer.SerializeObject(AObject, Result, sstNativeXML);
  end;
end;

procedure TRESTClient.SetHttpClient(const AHttpClientName: string);
begin
  FHttp := THTTPClientFactory.GetInstance(AHttpClientName);
end;


end.
