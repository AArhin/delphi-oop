unit HTTPClient;

interface

uses
  Classes
  ,HTTPClientInterface
  ;

type
  THTTPClient = class(TInterfacedObject, IHttpClient)
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

implementation

uses
  SysUtils
  ;

{ THTTPClient }

constructor THTTPClient.Create;
begin
  inherited Create;
end;


end.
