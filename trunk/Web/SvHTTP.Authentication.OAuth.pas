unit SvHTTP.Authentication.OAuth;

interface

uses
  SvHTTP.Authentication
  ,SvRest.Client
  ,SvHTTP.Attributes
  ,SvHTTPClientInterface
  ;

type
  TOAuthAccessResponseModel = class
  private
    Faccess_token: string;
    Frefresh_token: string;
    Fexpires_in: Integer;
    Ftoken_type: string;
  public
    property access_token: string read Faccess_token write Faccess_token;
    property refresh_token: string read Frefresh_token write Frefresh_token;
    property expires_in: Integer read Fexpires_in write Fexpires_in;
    property token_type: string read Ftoken_type write Ftoken_type;
  end;

  TRequestAccessClient = class(TSvRESTClient)
  public
    [POST]
    [Consumes(MEDIA_TYPE.JSON)]
    [Produces(MEDIA_TYPE.FORM)]
    {$WARNINGS OFF}
    function GetAccess(const code, client_id, client_secret, redirect_uri: string; const grant_type: string = 'authorization_code'): TOAuthAccessResponseModel; virtual;

    [POST]
    [Consumes(MEDIA_TYPE.JSON)]
    [Produces(MEDIA_TYPE.FORM)]
    function RefreshAccess(const client_id, client_secret, refresh_token: string; const grant_type: string = 'refresh_token'): TOAuthAccessResponseModel; virtual;
    {$WARNINGS ON}
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Base class implementing OAuth 2.0 authentication.
  ///	</summary>
  {$ENDREGION}
  TSvOAuth2 = class(TSvAuthentication)
  private
    FAccessToken: string;
    FRefreshToken: string;
    FClientId: string;
    FClientSecret: string;
    FScope: string;
    FRedirectUri: string;
    FTokenType: string;
  //  FState: string;
    FResponseCode: string;
    FExpiresIn: Integer;
  protected
    function GetAccessURL(): string; virtual; abstract;
    function GetTokenAccessURL(): string; virtual; abstract;
    function UrlEncode(const S: string): string; virtual;
    function EncodeParams(): Boolean; virtual;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    function GetCustomRequestHeader(): string; override;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Indicates that authentication should be executed. Basically you
    ///	  <b>never</b> need to call DoAuthenticate(True) because Clients will
    ///	  refresh tokens automatically.
    ///	</summary>
    {$ENDREGION}
    function DoAuthenticate(ARefreshAuthentication: Boolean = False): Boolean; override;


    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Represents access token which will be used to authenticate all
    ///	  further requests. Save this value safely. It is retrieved after
    ///	  DoAuthenticate() call if it's successful.
    ///	</summary>
    {$ENDREGION}
    property AccessToken: string read FAccessToken write FAccessToken;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Indicates the client that is making the request. The value passed in
    ///	  this parameter must exactly match the value shown in the APIs Console.
    ///	</summary>
    {$ENDREGION}
    property ClientId: string read FClientId write FClientId;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Represents ClientSecret which should be obtained from the API
    ///	  provider.
    ///	</summary>
    {$ENDREGION}
    property ClientSecret: string read FClientSecret write FClientSecret;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  The remaining lifetime on the access token.
    ///	</summary>
    {$ENDREGION}
    property ExpiresIn: Integer read FExpiresIn write FExpiresIn;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Represents scope value. Scope is space delimited set of permissions
    ///	  the application requests.
    ///	</summary>
    {$ENDREGION}
    property Scope: string read FScope write FScope;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Represents RedirectUri value. It's one of the redirect_uri values
    ///	  registered at the APIs Console.
    ///	</summary>
    {$ENDREGION}
    property RedirectUri: string read FRedirectUri write FRedirectUri;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Represents RefreshToken. It is obtained after first successful
    ///	  authorization and should be kept safely for later use. It is used
    ///	  when access token expires.
    ///	</summary>
    {$ENDREGION}
    property RefreshToken: string read FRefreshToken write FRefreshToken;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Represents ResponseCode which user retrieves after logging in into
    ///	  it's application and should pasted into the our dialog's edit box.
    ///	</summary>
    {$ENDREGION}
    property ResponseCode: string read FResponseCode write FResponseCode;

    {$REGION 'Documentation'}
    ///	<summary>
    ///	  Represents server used authorization type .
    ///	</summary>
    {$ENDREGION}
    property TokenType: string read FTokenType write FTokenType;
  //  property State: string read FState write FState;

  end;

implementation

uses
  SysUtils
  ,SvHTTP.AuthDialog
  ,SvWeb.Consts
  ;

const
  AUTH_HEADER = 'Authorization: %S %S';

  DEF_REDIRECT_URI = 'http://localhost';
  DEF_RESPONSE_TYPE = 'code';

  DEF_GRANT_TYPE = 'authorization_code';
  DEF_CONTENT_TYPE = 'application/x-www-form-urlencoded';


{ TSvOAuth }

constructor TSvOAuth2.Create;
begin
  inherited Create;
  FRedirectUri := DEF_REDIRECT_URI;
  FTokenType := DEF_RESPONSE_TYPE;
end;

destructor TSvOAuth2.Destroy;
begin

  inherited Destroy;
end;

function TSvOAuth2.DoAuthenticate(ARefreshAuthentication: Boolean): Boolean;
var
  LClient: TRequestAccessClient;
  LResponseModel: TOAuthAccessResponseModel;
begin
  if ARefreshAuthentication then
    FAccessToken := '';
  Result := (FAccessToken <> '');

  if not Result then
  begin
    LClient := TRequestAccessClient.Create(GetTokenAccessURL);
    LClient.SetHttpClient(HTTP_CLIENT_INDY);
    LClient.EncodeParameters := EncodeParams;
    try
      if ARefreshAuthentication then
      begin
        LResponseModel := LClient.RefreshAccess(FClientId, FClientSecret, FRefreshToken);
        try
          FAccessToken := LResponseModel.access_token;
          FTokenType := LResponseModel.token_type;
          FExpiresIn := LResponseModel.expires_in;
          Result := (FAccessToken <> '');
        finally
          LResponseModel.Free;
        end;
      end
      else
      begin
        if (FResponseCode <> '') or GetResponceCode(GetAccessURL, FResponseCode)  then
        begin
          LResponseModel := LClient.GetAccess(FResponseCode, FClientId, FClientSecret, FRedirectUri);
          try
            FAccessToken := LResponseModel.access_token;
            FRefreshToken := LResponseModel.refresh_token;
            FTokenType := LResponseModel.token_type;
            FExpiresIn := LResponseModel.expires_in;
            Result := (FAccessToken <> '');
          finally
            LResponseModel.Free;
          end;
        end;
      end;
    finally
      LClient.Free;
    end;
  end;
end;

function TSvOAuth2.EncodeParams: Boolean;
begin
  Result := False;
end;

function TSvOAuth2.GetCustomRequestHeader: string;
begin
  Result := Format(AUTH_HEADER, [FTokenType, FAccessToken]);
end;

function TSvOAuth2.UrlEncode(const S: string): string;
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

{ TRequestAccessClient }

{$WARNINGS OFF}

function TRequestAccessClient.GetAccess(const code, client_id, client_secret, redirect_uri,
  grant_type: string): TOAuthAccessResponseModel;
begin
  //
end;


function TRequestAccessClient.RefreshAccess(const client_id, client_secret, refresh_token: string;
  const grant_type: string): TOAuthAccessResponseModel;
begin
  //
end;

{$WARNINGS ON}


end.
