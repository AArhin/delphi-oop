unit SvHTTPClient.Factory;

interface

uses
  SvHTTPClientInterface
  ,SvHTTPClient
  ,Generics.Collections
  ;

type
  THttpClientClass = class of THTTPClient;

  TConstructorFunc = reference to function(): IHttpClient;

  TSvHTTPClientFactory = class
  private
    class var
      FClients: TDictionary<string, THttpClientClass>;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure RegisterHTTPClient(const AClientName: string; AClass: THttpClientClass);
    class function GetInstance(const AClientName: string): IHttpClient;
  end;

implementation

uses
  SysUtils
  ;

type
  EHttpClientFactoryNotRegistered = class(Exception);

{ THTTPClientFactory }

class constructor TSvHTTPClientFactory.Create;
begin
  FClients := TDictionary<string, THttpClientClass>.Create;
end;

class destructor TSvHTTPClientFactory.Destroy;
begin
  FClients.Free;
end;

class function TSvHTTPClientFactory.GetInstance(const AClientName: string): IHttpClient;
var
  LClient: THttpClientClass;
begin
  if not FClients.TryGetValue(AClientName, LClient) then
    raise EHttpClientFactoryNotRegistered.CreateFmt('Http client "%S" not registered', [AClientName]);

  Result := LClient.Create();
end;

class procedure TSvHTTPClientFactory.RegisterHTTPClient(const AClientName: string;
  AClass: THttpClientClass);
begin
  FClients.AddOrSetValue(AClientName, AClass);
end;

end.
