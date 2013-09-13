unit SvHTTPClientInterface;

interface

uses
  Classes
  ;

type
  {$SCOPEDENUMS ON}
  MEDIA_TYPE = (DEFAULT, JSON, XML, FORM);
  {$SCOPEDENUMS OFF}

  TRequestType = (rtGet, rtPost, rtPut, rtDelete);

const
  MEDIA_TYPES : array[MEDIA_TYPE] of string = ('text/html, */*', 'application/json', 'application/xml', 'application/x-www-form-urlencoded');

type
  IHttpAuthentication = interface(IInvokable)
    ['{6E58F0D0-1DDC-478E-8EFA-E810BC2960FD}']
    function DoAuthenticate(ARefreshAuthentication: Boolean = False): Boolean;
    function GetCustomRequestHeader(): string;
  end;

  IHttpClient = interface(IInvokable)
  ['{2DD5616C-9C53-4487-82B0-1ABA1CB87345}']
    function Delete(const AUrl: string): Integer;
    function Get(const AUrl: string; AResponse: TStream): Integer;
    function Post(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer;
    function Put(const AUrl: string; AResponse: TStream; ASourceContent: TStream): Integer;

    procedure SetCustomRequestHeader(const AHeaderValue: string);
    procedure ClearCustomRequestHeaders();

    procedure SetConsumeMediaType(const AMediaType: MEDIA_TYPE);
    function GetConsumeMediaType(): MEDIA_TYPE;
    function GetProduceMediaType: MEDIA_TYPE;
    procedure SetProduceMediaType(const Value: MEDIA_TYPE);

    function GetLastResponseCode(): Integer;
    function GetLastResponseText(): string;

    procedure SetUpHttps();

    property ConsumeMediaType: MEDIA_TYPE read GetConsumeMediaType write SetConsumeMediaType;
    property ProduceMediaType: MEDIA_TYPE read GetProduceMediaType write SetProduceMediaType;
  end;

implementation

end.
