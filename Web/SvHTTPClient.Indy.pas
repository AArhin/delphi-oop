unit SvHTTPClient.Indy;

interface

uses
  SvHTTPClient
  ,SvHTTPClientInterface
  ,IdHTTP
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
  public
    constructor Create(); override;
    destructor Destroy; override;

    function Delete(const AUrl: string): Integer; override;
    function Get(const AUrl: string; AResponse: TStream): Integer; override;
    function Post(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; override;
    function Put(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; override;

    procedure SetUpHttps(); override;
  end;

implementation

uses
  SvHTTPClient.Factory
  ,IdSSLOpenSSL
  ,SvWeb.Consts
//  ,IdIOHandler
 // ,IdIOHandlerSocket
 // ,IdIOHandlerStack
//  ,IdSSL
  ;

{ TIndyHTTPClient }

constructor TIndyHTTPClient.Create;
begin
  inherited Create();
  FClient := TIdHTTP.Create(nil);
  FClient.Request.ContentEncoding := 'utf-8';
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

function TIndyHTTPClient.Get(const AUrl: string; AResponse: TStream): Integer;
begin
  FClient.Get(AUrl, AResponse);
  Result := FClient.ResponseCode;
end;

function TIndyHTTPClient.GetConsumeMediaType: MEDIA_TYPE;
begin
  Result := FConsumeMediaType;
end;

function TIndyHTTPClient.GetProduceMediaType: MEDIA_TYPE;
begin
  Result := FProduceMediaType;
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
  THTTPClientFactory.RegisterHTTPClient(HTTP_CLIENT_INDY, TIndyHTTPClient);

end.
