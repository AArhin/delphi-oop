unit SvHTTP.Authentication;

interface

uses
  SvHttpClientInterface
  ;

type
  TSvAuthentication = class(TInterfacedObject, IHttpAuthentication)
  public
    function GetCustomRequestHeader(): string; virtual; abstract;
    function DoAuthenticate(ARefreshAuthentication: Boolean = False): Boolean; virtual; abstract;
  end;

implementation

{ TSvAuthentication }



end.
