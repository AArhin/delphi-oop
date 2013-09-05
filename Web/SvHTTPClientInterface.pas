unit SvHTTPClientInterface;

interface

uses
  Classes
  ;

type
  {$SCOPEDENUMS ON}
  MEDIA_TYPE = (JSON, XML);
  {$SCOPEDENUMS OFF}

  TRequestType = (rtGet, rtPost, rtPut, rtDelete);

const
  MEDIA_TYPES : array[MEDIA_TYPE] of string = ('application/json', 'application/xml');

type
  IHttpClient = interface(IInvokable)
  ['{2DD5616C-9C53-4487-82B0-1ABA1CB87345}']
    function Delete(const AUrl: string): Integer;
    function Get(const AUrl: string; AResponse: TStream): Integer;
    function Post(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer;
    function Put(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer;

    procedure SetConsumeMediaType(const AMediaType: MEDIA_TYPE);
    function GetConsumeMediaType(): MEDIA_TYPE;
    function GetProduceMediaType: MEDIA_TYPE;
    procedure SetProduceMediaType(const Value: MEDIA_TYPE);

    procedure SetUpHttps();

    property ConsumeMediaType: MEDIA_TYPE read GetConsumeMediaType write SetConsumeMediaType;
    property ProduceMediaType: MEDIA_TYPE read GetProduceMediaType write SetProduceMediaType;
  end;

implementation

end.
