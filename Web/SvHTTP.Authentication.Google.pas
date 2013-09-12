unit SvHTTP.Authentication.Google;

interface

uses
  SvHTTP.Authentication.OAuth
  ;

type
  TSvGoogleAuth = class(TSvOAuth)
  protected
    function GetAccessURL(): string; override;
    function GetTokenAccessURL(): string; override;
    function EncodeParams(): Boolean; override;
  public
    constructor Create(); override;

    function GetCustomRequestHeader(): string; override;
    function DoAuthenticate(): Boolean; override;
  end;

implementation

uses
  SysUtils
  ;

const
  AUTH_HEADER_BEARER = 'Authorization: Bearer %s';

  ENDPOINT_URI = 'https://accounts.google.com/o/oauth2/auth';
  ENDPOINT_TOKEN_URI = 'https://accounts.google.com/o/oauth2/token';

  OAUTH_URI =
    'https://accounts.google.com/o/oauth2/auth?client_id=%s&redirect_uri=%s&scope=%s&response_type=code';
  URI_REDIRECT = 'urn:ietf:wg:oauth:2.0:oob';


{ TSvGoogleAuth }

constructor TSvGoogleAuth.Create;
begin
  inherited Create;
  RedirectUri := URI_REDIRECT;
end;

function TSvGoogleAuth.DoAuthenticate: Boolean;
begin
  Result := inherited DoAuthenticate();
end;

function TSvGoogleAuth.EncodeParams: Boolean;
begin
  Result := False;
end;

function TSvGoogleAuth.GetAccessURL: string;
begin
  Result := Format(OAUTH_URI, [ClientID, RedirectUri, UrlEncode(Scope)]);
end;

function TSvGoogleAuth.GetCustomRequestHeader: string;
begin
  Result := Format(AUTH_HEADER_BEARER, [AccessToken]);
end;

function TSvGoogleAuth.GetTokenAccessURL: string;
begin
  Result := ENDPOINT_TOKEN_URI;
end;

end.
