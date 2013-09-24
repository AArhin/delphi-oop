unit SvHTTPClient.Indy;

interface

uses
  SvHTTPClient
  ,SvHTTPClientInterface
  ,IdHTTP
  ,idHeaderList
  ,IdComponent
  ,Classes
  ;

type
  TIndyHTTPClient = class(THTTPClient)
  private
    FClient: TIdHTTP;
    FConsumeMediaType: MEDIA_TYPE;
    FProduceMediaType: MEDIA_TYPE;
  protected
    procedure SetConsumeMediaType(const AMediaType: MEDIA_TYPE); override;
    function GetConsumeMediaType(): MEDIA_TYPE; override;
    function GetProduceMediaType: MEDIA_TYPE; override;
    procedure SetProduceMediaType(const Value: MEDIA_TYPE); override;
    procedure DoStatus (ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);

  public
    constructor Create(); override;
    destructor Destroy; override;

    procedure SetCustomRequestHeader(const AHeaderValue: string); override;
    procedure ClearCustomRequestHeaders(); override;

    function GetLastResponseCode(): Integer; override;
    function GetLastResponseText(): string; override;
    function GetLastResponseHeaders(): string; override;

    function Delete(const AUrl: string): Integer; override;
    function Get(const AUrl: string; AResponse: TStream): Integer; override;
    function Post(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; override;
    function Put(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; override;
    function Head(const AUrl: string): Integer; override;
    function Options(const AUrl: string): Integer; override;

    procedure SetUpHttps(); override;
  end;

implementation

uses
  SvHTTPClient.Factory
  ,IdSSLOpenSSL
  ,SvWeb.Consts
  ,SysUtils
//  ,IdIOHandler
 // ,IdIOHandlerSocket
 // ,IdIOHandlerStack
//  ,IdSSL
  ;

{ TIndyHTTPClient }

procedure TIndyHTTPClient.SetCustomRequestHeader(const AHeaderValue: string);
var
  LIndex, LOldIndex: Integer;
  LHeaderName: string;
begin
  LIndex := FClient.Request.CustomHeaders.Add(AHeaderValue);
  LHeaderName := FClient.Request.CustomHeaders.Names[LIndex];
  //remove old values with this header name
  for LOldIndex := LIndex-1 downto 0 do
  begin
    if SameText(LHeaderName, FClient.Request.CustomHeaders.Names[LOldIndex]) then
    begin
      FClient.Request.CustomHeaders.Delete(LOldIndex);
    end;
  end;
end;

procedure TIndyHTTPClient.ClearCustomRequestHeaders;
begin
  FClient.Request.CustomHeaders.Clear;
end;

constructor TIndyHTTPClient.Create;
begin
  inherited Create();
  FClient := TIdHTTP.Create(nil);
  FClient.HTTPOptions := FClient.HTTPOptions - [hoForceEncodeParams];
  FClient.AllowCookies := False;
 // FClient.Request.AcceptEncoding := 'gzip,deflate';
  FClient.OnStatus := DoStatus;
end;

function TIndyHTTPClient.Delete(const AUrl: string): Integer;
begin
  FClient.Delete(AUrl);
  Result := FClient.ResponseCode;
end;

destructor TIndyHTTPClient.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

procedure TIndyHTTPClient.DoStatus(ASender: TObject; const AStatus: TIdStatus;
  const AStatusText: string);
begin
  case AStatus of
    hsResolving: ;
    hsConnecting:
    begin
      //
    end;
    hsConnected:
    begin
      //
    end;
    hsDisconnecting: ;
    hsDisconnected: ;
    hsStatusText: ;
    ftpTransfer: ;
    ftpReady: ;
    ftpAborted: ;
  end;
end;

function TIndyHTTPClient.Get(const AUrl: string; AResponse: TStream): Integer;
begin
  FClient.Get(AUrl, AResponse);
  Result := FClient.ResponseCode;
end;

function TIndyHTTPClient.GetConsumeMediaType: MEDIA_TYPE;
begin
  Result := FConsumeMediaType;
end;

function TIndyHTTPClient.GetLastResponseCode: Integer;
begin
  Result := FClient.ResponseCode;
end;

function TIndyHTTPClient.GetLastResponseHeaders: string;
begin
  Result := FClient.Response.RawHeaders.Text;
end;

function TIndyHTTPClient.GetLastResponseText: string;
begin
  Result := FClient.ResponseText;
end;

function TIndyHTTPClient.GetProduceMediaType: MEDIA_TYPE;
begin
  Result := FProduceMediaType;
end;

function TIndyHTTPClient.Head(const AUrl: string): Integer;
begin
  FClient.Head(AUrl);
  Result := FClient.ResponseCode;
end;

function TIndyHTTPClient.Options(const AUrl: string): Integer;
begin
  FClient.Options(AUrl);
  Result := FClient.ResponseCode;
end;

function TIndyHTTPClient.Post(const AUrl: string; AResponse, ASourceContent: TStream): Integer;
begin
  FClient.Post(AUrl, ASourceContent, AResponse);
  Result := FClient.ResponseCode;
end;

function TIndyHTTPClient.Put(const AUrl: string; AResponse, ASourceContent: TStream): Integer;
begin
  FClient.Put(AUrl, ASourceContent, AResponse);
  Result := FClient.ResponseCode;
end;

procedure TIndyHTTPClient.SetConsumeMediaType(const AMediaType: MEDIA_TYPE);
begin
  FConsumeMediaType := AMediaType;
  FClient.Request.Accept := MEDIA_TYPES[FConsumeMediaType];
end;

procedure TIndyHTTPClient.SetProduceMediaType(const Value: MEDIA_TYPE);
begin
  FProduceMediaType := Value;
  FClient.Request.ContentType := MEDIA_TYPES[FProduceMediaType];
  if (FProduceMediaType in [MEDIA_TYPE.JSON, MEDIA_TYPE.XML]) then
  begin
    FClient.Request.ContentEncoding := 'utf-8';
  end;
end;

procedure TIndyHTTPClient.SetUpHttps;
var
  LHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  inherited;
  LHandler := TIdSSLIOHandlerSocketOpenSSL.Create(FClient);
  FClient.IOHandler := LHandler;
end;

initialization
  TSvHTTPClientFactory.RegisterHTTPClient(HTTP_CLIENT_INDY, TIndyHTTPClient);

end.
