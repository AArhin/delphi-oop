unit HTTPClient;

interface

uses
  Classes
  ,Generics.Collections
  ;

type
  {$SCOPEDENUMS ON}
  MEDIA_TYPE = (JSON, XML);
  {$SCOPEDENUMS OFF}

const
  MEDIA_TYPES : array[MEDIA_TYPE] of string = ('application/json', 'application/xml');

type
  THttpClientClass = class of THTTPClient;

  THTTPClient = class(TInterfacedObject)
  protected
    procedure SetConsumeMediaType(const AMediaType: MEDIA_TYPE); virtual; abstract;
    function GetConsumeMediaType(): MEDIA_TYPE; virtual; abstract;
    function GetProduceMediaType: MEDIA_TYPE; virtual; abstract;
    procedure SetProduceMediaType(const Value: MEDIA_TYPE); virtual; abstract;
  public
    constructor Create(); virtual;

    function Delete(const AUrl: string): Integer; virtual; abstract;
    function Get(const AUrl: string; AResponse: TStream): Integer; virtual; abstract;
    function Post(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; virtual; abstract;
    function Put(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer; virtual; abstract;

    property ConsumeMediaType: MEDIA_TYPE read GetConsumeMediaType write SetConsumeMediaType;
    property ProduceMediaType: MEDIA_TYPE read GetProduceMediaType write SetProduceMediaType;
  end;

  TConstructorFunc = reference to function(): THTTPClient;

  THTTPClientFactory = class
  private
    class var
      FClients: TDictionary<string, THttpClientClass>;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure RegisterHTTPClient(const AClientName: string; AClass: THttpClientClass);
    class function GetInstance(const AClientName: string): THTTPClient;
  end;

implementation

uses
  SysUtils
  ;

type
  EHttpClientFactoryNotRegistered = class(Exception);

{ THTTPClientFactory }

class constructor THTTPClientFactory.Create;
begin
  FClients := TDictionary<string, THttpClientClass>.Create;
end;

class destructor THTTPClientFactory.Destroy;
begin
  FClients.Free;
end;

class function THTTPClientFactory.GetInstance(const AClientName: string): THTTPClient;
var
  LClient: THttpClientClass;
begin
  if not FClients.TryGetValue(AClientName, LClient) then
    raise EHttpClientFactoryNotRegistered.CreateFmt('Http client "%S" not registered', [AClientName]);

  Result := LClient.Create();
end;

class procedure THTTPClientFactory.RegisterHTTPClient(const AClientName: string; AClass: THttpClientClass);
begin
  FClients.AddOrSetValue(AClientName, AClass);
end;

{ THTTPClient }

constructor THTTPClient.Create;
begin
  inherited Create;
end;


end.
