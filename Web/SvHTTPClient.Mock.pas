unit SvHTTPClient.Mock;

interface

uses
  SvHTTPClient
  ,SvHTTPClientInterface
  ,Classes
  ;

type
  TMockHttpClient = class(THTTPClient)
  private
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

    procedure SetCustomRequestHeader(const AHeaderValue: string); override;
    procedure ClearCustomRequestHeaders(); override;

    function Delete(const AUrl: string): Integer; override;
    function Get(const AUrl: string; AResponse: TStream): Integer; override;
    function Post(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; override;
    function Put(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; override;
    function Head(const AUrl: string): Integer; override;
    function Options(const AUrl: string): Integer; override;

    procedure SetUpHttps(); override;
    function GetLastResponseCode(): Integer; override;
    function GetLastResponseText(): string; override;
    function GetLastResponseHeaders(): string; override;

  end;

implementation

uses
  SvHTTPClient.Factory
  ,SvWeb.Consts
  ;


{ TMockHttpClient }

procedure TMockHttpClient.SetCustomRequestHeader(const AHeaderValue: string);
begin
  inherited;
end;

procedure TMockHttpClient.ClearCustomRequestHeaders;
begin
  inherited;
end;

constructor TMockHttpClient.Create;
begin
  inherited;

end;

function TMockHttpClient.Delete(const AUrl: string): Integer;
begin
  Result := 200;
end;

destructor TMockHttpClient.Destroy;
begin

  inherited;
end;

function TMockHttpClient.Get(const AUrl: string; AResponse: TStream): Integer;
begin
  Result := 200;

end;

function TMockHttpClient.GetConsumeMediaType: MEDIA_TYPE;
begin
  Result := FConsumeMediaType;
end;

function TMockHttpClient.GetLastResponseCode: Integer;
begin
  Result := 200;
end;

function TMockHttpClient.GetLastResponseHeaders: string;
begin
  Result := '';
end;

function TMockHttpClient.GetLastResponseText: string;
begin
  Result := '';
end;

function TMockHttpClient.GetProduceMediaType: MEDIA_TYPE;
begin
  Result := FProduceMediaType;
end;

function TMockHttpClient.Head(const AUrl: string): Integer;
begin
  Result := 200;
end;

function TMockHttpClient.Options(const AUrl: string): Integer;
begin
  Result := 200;
end;

function TMockHttpClient.Post(const AUrl: string; AResponse,
  ASourceContent: TStream): Integer;
begin
  Result := 200;
end;

function TMockHttpClient.Put(const AUrl: string; AResponse,
  ASourceContent: TStream): Integer;
begin
  Result := 200;
end;

procedure TMockHttpClient.SetConsumeMediaType(const AMediaType: MEDIA_TYPE);
begin
  FConsumeMediaType := AMediaType;
end;

procedure TMockHttpClient.SetProduceMediaType(const Value: MEDIA_TYPE);
begin
  FProduceMediaType := Value;
end;

procedure TMockHttpClient.SetUpHttps;
begin
  inherited;
end;

initialization
  THTTPClientFactory.RegisterHTTPClient(HTTP_CLIENT_MOCK, TMockHttpClient);

end.
