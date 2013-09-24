unit SvREST.Client;

interface

uses
  Rtti
  ,SvHTTPClientInterface
  ,SvREST.Method
  ,SvWeb.Consts
  ,SvVMI
  ,Generics.Collections
  ,Classes
  ,TypInfo
  ;

type
  TSvRESTClient = class(TInterfacedObject)
  private
    FCtx: TRttiContext;
    FURL: string;
    FVMI: TSvVirtualMethodInterceptor;
    FHttp: IHTTPClient;
    FMethods: TObjectDictionary<Pointer,TSvRESTMethod>;
    FProxyObject: TObject;
    FProxyTypeInfo: PTypeInfo;
    FDoInvokeMethods: Boolean;
    FAuthentication: IHttpAuthentication;
    FEncodeParameters: Boolean;
    procedure SetHeaders(const AHasAuth: Boolean; ARestMethod: TSvRESTMethod);
  protected
    procedure DoOnAfter(Instance: TObject; Method: TRttiMethod;
      const Args: TArray<TValue>; var Result: TValue);
    procedure DoRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TSvRESTMethod;
      var Result: TValue); virtual;
    function InternalDoRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TSvRESTMethod;
      var AResult: TValue): IHttpResponse; virtual;

    function IsMethodMarked(AMethod: TRttiMethod): Boolean;
    function GetRESTMethod(AMethod: TRttiMethod; AType: TRttiType): TSvRESTMethod;
    procedure EnumerateRESTMethods();
    function GenerateUrl(ARestMethod: TSvRESTMethod): string; virtual;
    function DoCheckPathParameters(const AUrl: string; ARestMethod: TSvRESTMethod): string;
    function GenerateSourceContent(ARestMethod: TSvRESTMethod): TStream;
    function GetSerializedDataString(const AValue: TValue; ARestMethod: TSvRESTMethod): string;
    function SerializeObjectToString(AObject: TObject; ARestMethod: TSvRESTMethod): string;
    procedure FillRestMethodParameters(const Args: TArray<TValue>; ARestMethod: TSvRESTMethod; AMethod: TRttiMethod);
    procedure InjectRestMethodOutParameters(const Args: TArray<TValue>; ARestMethod: TSvRESTMethod; AMethod: TRttiMethod; AResponse: IHttpResponse);
    function ConsumeMediaType(ARttiType: TRttiType; const ASource: TValue; ARestMethod: TSvRESTMethod): TValue; virtual;
    function ConsumeMediaTypeAsString(ARttiType: TRttiType; const ASource: TValue; ARestMethod: TSvRESTMethod): string; virtual;
    function UrlEncode(const S: string): string; virtual;
    function UrlEncodeRFC3986(const URL: string): string; virtual;
    function HasAuthentication(): Boolean; virtual;
    function HttpResultOK(AResponseCode: Integer): Boolean; virtual;
    function OneParamInBody(ARestMethod: TSvRESTMethod): Boolean;
  public
    constructor Create(const AUrl: string; AProxyObject: TObject = nil; AProxyType: PTypeInfo = nil); virtual;
    destructor Destroy; override;

    procedure SetHttpClient(const AHttpClientName: string = HTTP_CLIENT_INDY);

    function IsHttps(): Boolean;
    function GetLastResponseCode(): Integer;
    function GetLastResponseText(): string;

    property Authentication: IHttpAuthentication read FAuthentication write FAuthentication;
    property EncodeParameters: Boolean read FEncodeParameters write FEncodeParameters;
    property DoInvokeMethods: Boolean read FDoInvokeMethods write FDoInvokeMethods;
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
  ,SvHTTPClient.Factory
  ,SvHTTP.Attributes
  ,SvHTTPClient.Response
  ;

type
  ERestClientException = class(Exception);

{ TRESTClient }

function TSvRESTClient.ConsumeMediaType(ARttiType: TRttiType; const ASource: TValue; ARestMethod: TSvRESTMethod): TValue;
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
    begin
      case ARttiType.TypeKind of
        tkString, tkWString, tkUString, tkLString:
          Result := GetSerializedDataString(ASource, ARestMethod);
        tkInteger, tkInt64, tkFloat: Result := GetLastResponseCode;
      end;
    end;
  end;
end;

function TSvRESTClient.ConsumeMediaTypeAsString(ARttiType: TRttiType; const ASource: TValue;
  ARestMethod: TSvRESTMethod): string;
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

constructor TSvRESTClient.Create(const AUrl: string; AProxyObject: TObject = nil; AProxyType: PTypeInfo = nil);
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
  FMethods := TObjectDictionary<Pointer,TSvRESTMethod>.Create([doOwnsValues]);

  FVMI.OnBefore := procedure(Instance: TObject;
    Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
    out Result: TValue)
    begin
      DoInvoke := FDoInvokeMethods;
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

destructor TSvRESTClient.Destroy;
begin
  FMethods.Free;
  FVMI.Unproxify(FProxyObject);
  FVMI.Free;
  inherited Destroy;
end;

function TSvRESTClient.DoCheckPathParameters(const AUrl: string; ARestMethod: TSvRESTMethod): string;
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
        ARestMethod.Parameters[i].IsDisabled := True;
        Break;
      end;
    end;
    LPosTokenStart := PosEx('{', Result);
      if LPosTokenStart > 0 then
        LPosTokenEnd := PosEx('}', Result, LPosTokenStart);
  end;
end;

procedure TSvRESTClient.DoOnAfter(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>;
  var Result: TValue);
var
  LMethod: TSvRESTMethod;
begin
  if not FMethods.TryGetValue(Method.Handle, LMethod) then
    Exit;

  DoRequest(Method, Args, LMethod, Result);
end;

procedure TSvRESTClient.DoRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TSvRESTMethod;
  var Result: TValue);
var
  LHttpCode: Integer;
  LHasAuth: Boolean;
  LResponse: IHttpResponse;
begin
  FillRestMethodParameters(Args, ARestMethod, Method);
  FHttp.ConsumeMediaType := ARestMethod.ConsumeMediaType;
  FHttp.ProduceMediaType := ARestMethod.ProduceMediaType;

  LHasAuth := HasAuthentication;
  SetHeaders(LHasAuth, ARestMethod);

  ARestMethod.Url := GenerateUrl(ARestMethod);
  LResponse := InternalDoRequest(Method, Args, ARestMethod, Result);
  InjectRestMethodOutParameters(Args, ARestMethod, Method, LResponse);
  LHttpCode := LResponse.GetResponseCode;

  if HttpResultOK(LHttpCode) then
    Exit;

  case LHttpCode of
    HTTP_RESPONSE_AUTH_FAILED:
    begin
      //refresh token
      if LHasAuth then
      begin
        if FAuthentication.DoAuthenticate(True) then
        begin
          DoRequest(Method, Args, ARestMethod, Result);
        end;
      end;
    end;
    HTTP_RESPONSE_OK: //do nothing;
    else
    begin
      raise ERestClientException.CreateFmt('Error code: %D. %S', [LHttpCode, GetLastResponseText]);
    end;
  end;
end;

procedure TSvRESTClient.EnumerateRESTMethods;
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
      FMethods.Add(LMethod.Handle, GetRESTMethod(LMethod, LType));
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

procedure TSvRESTClient.FillRestMethodParameters(const Args: TArray<TValue>; ARestMethod: TSvRESTMethod; AMethod: TRttiMethod);
var
  i: Integer;
  LParameters: TArray<TRttiParameter>;
  LRestParam: TSvRESTMethodParameter;
  LAttrib: TCustomAttribute;
  LSkip: Boolean;
begin
  LParameters := AMethod.GetParameters;
  for i := Low(Args) to High(Args) do
  begin
    LSkip := False;
    LRestParam := ARestMethod.Parameters[i];
    LRestParam.IsDisabled := False;
    LRestParam.IsInjectable := False;
    LRestParam.Value := TValue.Empty;
    for LAttrib in LParameters[i].GetAttributes do
    begin
      if (LAttrib.ClassType = TransientParamAttribute) then
        LSkip := True
      else if (LAttrib.ClassType = ContextAttribute) then
      begin
        LSkip := True;
        LRestParam.IsInjectable := True;
      end
      else if LAttrib.ClassType = BodyParamAttribute then
      begin
        LRestParam.IsNameless := True;
        LRestParam.Name := '';
        LRestParam.Value := ConsumeMediaTypeAsString(LParameters[i].ParamType, Args[i], ARestMethod);
      end
      else if LAttrib.ClassType = QueryParamNameValueAttribute then
      begin
        LRestParam.IsNameless := False;
        LRestParam.Name := QueryParamNameValueAttribute(LAttrib).Name;
        LRestParam.Value := QueryParamNameValueAttribute(LAttrib).Value;
      end
      else if (LAttrib.ClassType = QueryParamAttribute) then
      begin
        LRestParam.IsNameless := False;
        if (QueryParamAttribute(LAttrib).Name <> '') then
          LRestParam.Name := QueryParamAttribute(LAttrib).Name;
        LRestParam.Value := ConsumeMediaTypeAsString(LParameters[i].ParamType, Args[i], ARestMethod);
      end
      else if (LAttrib.ClassType = HeaderParamAttribute) then
      begin
        LRestParam.IsNameless := False;
        LRestParam.ParamType := ptHeader;
        if (HeaderParamAttribute(LAttrib).Name <> '') then
          LRestParam.Name := HeaderParamAttribute(LAttrib).Name;
        LRestParam.Value := ConsumeMediaTypeAsString(LParameters[i].ParamType, Args[i], ARestMethod);
      end;
    end;

    if LSkip then
    begin
      LRestParam.IsDisabled := True;
    end
    else
    begin
      if LRestParam.Value.IsEmpty then
        LRestParam.Value := ConsumeMediaTypeAsString(LParameters[i].ParamType, Args[i], ARestMethod);
    end;
  end;
end;

function TSvRESTClient.GenerateSourceContent(ARestMethod: TSvRESTMethod): TStream;
var
  i: Integer;
  LParamValue, LParamName: string;
  LParameters: TArray<TSvRESTMethodParameter>;
begin
  if not (ARestMethod.RequestType in [rtPost, rtPut]) then
    Exit(nil);

  Result := TStringStream.Create('', TEncoding.UTF8);

  LParameters := ARestMethod.GetEnabledParameters();
  for i := 0 to Length(LParameters) - 1 do
  begin
    if i <> 0 then
      TStringStream(Result).WriteString('&');

    if (LParameters[i].IsNameless) or (LParameters[i].Name = '') then
    begin
      LParamValue := LParameters[i].ToString;
      if FEncodeParameters then
        LParamValue := UrlEncodeRFC3986(LParamValue);
      TStringStream(Result).WriteString(LParamValue);
      Continue;
    end;

    LParamValue := LParameters[i].ToString;
    LParamName := LParameters[i].Name;
    if FEncodeParameters then
    begin
      LParamName := UrlEncodeRFC3986(LParamName);
      LParamValue := UrlEncodeRFC3986(LParamValue);
    end;
    TStringStream(Result).WriteString(Format('%S=%S',
      [LParamName, LParamValue]));
  end;
end;

function TSvRESTClient.GenerateUrl(ARestMethod: TSvRESTMethod): string;
var
  i: Integer;
  LParamValue, LParamName: string;
  LParameters: TArray<TSvRESTMethodParameter>;
begin
  Result := FURL;
  if ARestMethod.Path <> '' then
    Result := Result + ARestMethod.Path;

  if ARestMethod.RequestType <> rtGet then
    Exit;

  Result := DoCheckPathParameters(Result, ARestMethod);

  if ARestMethod.Parameters.Count > 0 then
    Result := Result + '?';

  LParameters := ARestMethod.GetEnabledParameters();
  for i := Low(LParameters) to High(LParameters) do
  begin
    if i <> 0 then
      Result := Result + '&';

    LParamName := LParameters[i].Name;
    LParamValue := LParameters[i].ToString;
    if FEncodeParameters then
    begin
      LParamName := UrlEncodeRFC3986(LParamName);
      LParamValue := UrlEncodeRFC3986(LParamValue);
    end;

    Result := Result + Format('%S=%S', [LParamName, LParamValue]);
  end;
end;

function TSvRESTClient.GetLastResponseCode: Integer;
begin
  Result := FHttp.GetLastResponseCode;
end;

function TSvRESTClient.GetLastResponseText: string;
begin
  Result := FHttp.GetLastResponseText();
end;

procedure TSvRESTClient.SetHeaders(const AHasAuth: Boolean; ARestMethod: TSvRESTMethod);
var
  LHeaders: TArray<TSvRESTMethodParameter>;
  LHeader: TSvRESTMethodParameter;
  LName, LValue: string;
begin
  LHeaders := ARestMethod.GetHeaderParameters();
  for LHeader in LHeaders do
  begin
    LName := LHeader.Name;
    LValue := LHeader.ToString;
    if FEncodeParameters then
    begin
      LName := UrlEncodeRFC3986(LName);
      LValue := UrlEncodeRFC3986(LValue);
    end;
    FHttp.SetCustomRequestHeader(Format('%S: %S', [LName, LValue]));
  end;

  if AHasAuth then
  begin
    FHttp.SetCustomRequestHeader(FAuthentication.GetCustomRequestHeader);
  end;
end;

function TSvRESTClient.GetRESTMethod(AMethod: TRttiMethod; AType: TRttiType): TSvRESTMethod;
var
  LAttr: TCustomAttribute;
  LParam: TRttiParameter;
  LRestParam: TSvRESTMethodParameter;
begin
  Result := TSvRESTMethod.Create;
  Result.Name := AMethod.Name;

  for LParam in AMethod.GetParameters do
  begin
    LRestParam := TSvRESTMethodParameter.Create;
    LRestParam.Name := LParam.Name;
    Result.Parameters.Add(LRestParam);
  end;

  for LAttr in AType.GetAttributes do
  begin
    if LAttr.ClassType = QueryParamNameValueAttribute then
    begin
      LRestParam := TSvRESTMethodParameter.Create;
      LRestParam.Name := QueryParamNameValueAttribute(LAttr).Name;
      LRestParam.Value := QueryParamNameValueAttribute(LAttr).Value;
      Result.Parameters.Add(LRestParam);
    end;
  end;

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
    else if LAttr.ClassType = HEADAttribute then
      Result.RequestType := rtHead
    else if LAttr.ClassType = OPTIONSAttribute then
      Result.RequestType := rtOptions
    else if LAttr is PathAttribute then
      Result.Path := PathAttribute(LAttr).Path
    else if LAttr.ClassType = ConsumesAttribute then
      Result.ConsumeMediaType := ConsumesAttribute(LAttr).MediaType
    else if LAttr.ClassType = ProducesAttribute then
      Result.ProduceMediaType := ProducesAttribute(LAttr).MediaType
    else if LAttr.ClassType = QueryParamNameValueAttribute then
    begin
      LRestParam := TSvRESTMethodParameter.Create;
      LRestParam.Name := QueryParamNameValueAttribute(LAttr).Name;
      LRestParam.Value := QueryParamNameValueAttribute(LAttr).Value;
      Result.Parameters.Add(LRestParam);
    end;
  end;
end;

function TSvRESTClient.GetSerializedDataString(const AValue: TValue; ARestMethod: TSvRESTMethod): string;
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

function TSvRESTClient.HasAuthentication: Boolean;
begin
  Result := Assigned(FAuthentication) and (FAuthentication.DoAuthenticate);
end;

function TSvRESTClient.HttpResultOK(AResponseCode: Integer): Boolean;
begin
  Result := (AResponseCode >= 200) and (AResponseCode < 300)
end;

procedure TSvRESTClient.InjectRestMethodOutParameters(const Args: TArray<TValue>;
  ARestMethod: TSvRESTMethod; AMethod: TRttiMethod; AResponse: IHttpResponse);
var
  i: Integer;
  LRestParam: TSvRESTMethodParameter;
begin
  for i := Low(Args) to High(Args) do
  begin
    LRestParam := ARestMethod.Parameters[i];
    if LRestParam.IsInjectable then
    begin
      if (Args[i].TypeInfo = TypeInfo(IHttpResponse)) then
      begin
        Args[i] := TValue.From<IHttpResponse>(AResponse);
      end;
    end;
  end;
end;

function TSvRESTClient.InternalDoRequest(Method: TRttiMethod; const Args: TArray<TValue>;
  ARestMethod: TSvRESTMethod; var AResult: TValue): IHttpResponse;
var
  LResponse: TSvHttpResponse;
  LResponseStream: TStringStream;
  LSourceContent: TStream;
  LCode: Integer;
  LUrl: string;
begin
  LResponse := TSvHttpResponse.Create;
  LResponseStream := TStringStream.Create;
  LSourceContent := GenerateSourceContent(ARestMethod);
  LCode := 0;
  try
    LUrl := ARestMethod.Url;
    try
      case ARestMethod.RequestType of
        rtGet: LCode := FHttp.Get(LUrl, LResponseStream);
        rtPost: LCode := FHttp.Post(LUrl, LResponseStream, LSourceContent);
        rtPut: LCode := FHttp.Put(LUrl, LResponseStream, LSourceContent);
        rtDelete: LCode := FHttp.Delete(LUrl);
        rtHead: LCode := FHttp.Head(LUrl);
        rtOptions: LCode := FHttp.Options(LUrl);
      end;
    except
      LCode := GetLastResponseCode();
    end;

    LResponse.ResponseCode := LCode;
    LResponse.ResponseStream := LResponseStream;
    LResponse.Headers := FHttp.GetLastResponseHeaders;

    if HttpResultOK(LCode) then
    begin
      if LResponseStream.Size > 0 then
      begin
        AResult := ConsumeMediaType(Method.ReturnType, LResponseStream, ARestMethod);
      end;
    end;

  finally
    Result := LResponse;
    LResponseStream.Free;
    LSourceContent.Free;
  end;
end;

function TSvRESTClient.IsHttps: Boolean;
begin
  Result := StartsText('https', FURL);
end;

function TSvRESTClient.IsMethodMarked(AMethod: TRttiMethod): Boolean;
var
  LAttrib: TCustomAttribute;
begin
  for LAttrib in AMethod.GetAttributes do
  begin
    Result := (LAttrib is GETAttribute) or (LAttrib is POSTAttribute)
      or (LAttrib is DELETEAttribute) or (LAttrib is PUTAttribute) or (LAttrib is HEADAttribute)
      or (LAttrib is OPTIONSAttribute);
    if Result then
      Exit;
  end;
  Result := False;
end;

function TSvRESTClient.OneParamInBody(ARestMethod: TSvRESTMethod): Boolean;
begin
  Result := (ARestMethod.Parameters.Count = 1) and (ARestMethod.ProduceMediaType in [MEDIA_TYPE.JSON, MEDIA_TYPE.XML]);
end;

function TSvRESTClient.SerializeObjectToString(AObject: TObject; ARestMethod: TSvRESTMethod): string;
begin
  Result := '';
  case ARestMethod.ProduceMediaType of
    MEDIA_TYPE.JSON: TSvSerializer.SerializeObject(AObject, Result, sstSuperJson);
    MEDIA_TYPE.XML: TSvSerializer.SerializeObject(AObject, Result, sstNativeXML);
  end;
end;

procedure TSvRESTClient.SetHttpClient(const AHttpClientName: string);
begin
  FHttp := TSvHTTPClientFactory.GetInstance(AHttpClientName);
  if IsHttps then
    FHttp.SetUpHttps();
end;


function TSvRESTClient.UrlEncode(const S: string): string;
var
  Ch : Char;
begin
  Result := '';
  for Ch in S do
  begin
    if ((Ch >= '0') and (Ch <= '9')) or
       ((Ch >= 'a') and (Ch <= 'z')) or
       ((Ch >= 'A') and (Ch <= 'Z')) or
       (Ch = '.') or (Ch = '-') or (Ch = '_') or (Ch = '~') then
      Result := Result + Ch
    else
      Result := Result + '%' + SysUtils.IntToHex(Ord(Ch), 2);
  end;
end;

function TSvRESTClient.UrlEncodeRFC3986(const URL: string): string;
var
  URL1: string;
begin
  URL1 := URLEncode(URL);
  URL1 := StringReplace(URL1, ' ', '+', [rfReplaceAll, rfIgnoreCase]);
  Result := URL1;
end;

end.
