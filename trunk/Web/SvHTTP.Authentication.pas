unit SvHTTP.Authentication;

interface

uses
  SvHttpClientInterface
  ;

type
  TSvAuthentication = class(TInterfacedObject, IHttpAuthentication)
  public
    function GetCustomRequestHeader(): string; virtual; abstract;
    function DoAuthenticate(): Boolean; virtual; abstract;
  end;

implementation

{ TSvAuthentication }



end.
