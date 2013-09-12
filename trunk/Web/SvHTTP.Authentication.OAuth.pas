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

  TRequestAccessClient = class(TRESTClient)
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

  TSvOAuth = class(TSvAuthentication)
  private
    FAccessToken: string;
    FRefreshToken: string;
    FClientId: string;
    FClientSecret: string;
    FScope: string;
    FRedirectUri: string;
    FResponseType: string;
    FState: string;
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
    function DoAuthenticate(): Boolean; override;


    property AccessToken: string read FAccessToken write FAccessToken;
    property ClientId: string read FClientId write FClientId;
    property ClientSecret: string read FClientSecret write FClientSecret;
    property ExpiresIn: Integer read FExpiresIn write FExpiresIn;
    property Scope: string read FScope write FScope;
    property RedirectUri: string read FRedirectUri write FRedirectUri;
    property RefreshToken: string read FRefreshToken write FRefreshToken;
    property ResponseCode: string read FResponseCode write FResponseCode;
    property ResponseType: string read FResponseType write FResponseType;
    property State: string read FState write FState;

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

constructor TSvOAuth.Create;
begin
  inherited Create;
  FRedirectUri := DEF_REDIRECT_URI;
  FResponseType := DEF_RESPONSE_TYPE;
end;

destructor TSvOAuth.Destroy;
begin

  inherited Destroy;
end;

function TSvOAuth.DoAuthenticate: Boolean;
var
  LClient: TRequestAccessClient;
  LResponseModel: TOAuthAccessResponseModel;
begin
  Result := (FAccessToken <> '');

  if not Result then
  begin
    LClient := TRequestAccessClient.Create(GetTokenAccessURL);
    LClient.SetHttpClient(HTTP_CLIENT_INDY);
    LClient.EncodeParameters := EncodeParams;
    try
      if (FRefreshToken = '') then
      begin
        if (FResponseCode <> '') or GetResponceCode(GetAccessURL, FResponseCode)  then
        begin
          LResponseModel := LClient.GetAccess(FResponseCode, FClientId, FClientSecret, FRedirectUri);
          try
            FAccessToken := LResponseModel.access_token;
            FRefreshToken := LResponseModel.refresh_token;
            FResponseType := LResponseModel.token_type;
            FExpiresIn := LResponseModel.expires_in;
            Result := (FAccessToken <> '');
          finally
            LResponseModel.Free;
          end;
        end;
      end
      else
      begin
        LResponseModel := LClient.RefreshAccess(FClientId, FClientSecret, FRefreshToken);
        try
          FAccessToken := LResponseModel.access_token;
          FResponseType := LResponseModel.token_type;
          FExpiresIn := LResponseModel.expires_in;
          Result := (FAccessToken <> '');
        finally
          LResponseModel.Free;
        end;
      end;
    finally
      LClient.Free;
    end;
  end;
end;

function TSvOAuth.EncodeParams: Boolean;
begin
  Result := False;
end;

function TSvOAuth.GetCustomRequestHeader: string;
begin
  Result := Format(AUTH_HEADER, [FResponseType, FAccessToken]);
end;

function TSvOAuth.UrlEncode(const S: string): string;
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
