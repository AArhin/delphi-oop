unit HTTPClient.Indy;

interface

uses
  HTTPClient
  ,IdHTTP
  ,Classes
  ;

type
  TIndyHTTPClient = class(THTTPClient)
  private
    FClient: TIdHTTP;
    FMediaType: MEDIA_TYPE;
  protected
    procedure SetMediaType(const AMediaType: MEDIA_TYPE); override;
    function GetMediaType(): MEDIA_TYPE; override;
  public
    constructor Create(); override;
    destructor Destroy; override;

    function Delete(const AUrl: string): Integer; override;
    function Get(const AUrl: string; AResponse: TStream): Integer; override;
    function Post(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; override;
    function Put(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; override;
  end;

implementation

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

function TIndyHTTPClient.GetMediaType: MEDIA_TYPE;
begin
  Result := FMediaType;
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

procedure TIndyHTTPClient.SetMediaType(const AMediaType: MEDIA_TYPE);
begin
  FMediaType := AMediaType;
  FClient.Request.Accept := MEDIA_TYPES[AMediaType];
  FClient.Request.ContentType := MEDIA_TYPES[AMediaType];
end;

initialization
  THTTPClientFactory.RegisterHTTPClient('idHttp', TIndyHTTPClient);

end.
