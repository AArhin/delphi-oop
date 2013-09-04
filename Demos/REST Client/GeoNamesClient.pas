unit GeoNamesClient;

interface

uses
  REST.Client
  ,Generics.Collections
  ,HTTPClientInterface
  ,HTTP.Attributes
  ;

type
  TStatus = class
  private
    FMessage: string;
    FValue: Integer;
  public
    property message: string read FMessage write FMessage;
    property value: Integer read FValue write FValue;
  end;

  TStatusMessage = class
  private
    FStatus: TStatus;
  public
    destructor Destroy; override;

    property status: TStatus read FStatus write FStatus;
  end;

  geoname = class
  private
    FtoponymName: string;
    Fname: string;
    Flat: Integer;
    Flng: Integer;
    FgeonameId: Int64;
    FcountryCode: string;
    FcountryName: string;
    Ffcl: string;
    Ffcode: string;
    Fpopulation: Integer;
  public
    property toponymName: string read FtoponymName write FtoponymName;
    property name: string read Fname write Fname;
    property lat: Integer read Flat write Flat;
    property lng: Integer read Flng write Flng;
    property geonameId: Int64 read FgeonameId write FgeonameId;
    property countryCode: string read FcountryCode write FcountryCode;
    property countryName: string read FcountryName write FcountryName;
    property fcl: string read Ffcl write Ffcl;
    property fcode: string read Ffcode write Ffcode;
    property population: Integer read Fpopulation write Fpopulation;

  end;

  TSvObjectList<T: class> = class(TObjectList<T>)
  public
    constructor Create(); reintroduce; overload;
  end;

  TGeonames = class
  private
    Fgeonames: TSvObjectList<geoname>;
    FtotalResultsCount: Integer;
  public
    destructor Destroy; override;

    property totalResultsCount: Integer read FtotalResultsCount write FtotalResultsCount;
    property geonames: TSvObjectList<geoname> read Fgeonames write Fgeonames;
  end;

  [Path('/neighboursJSON')]
  TGeonamesClient = class(TRESTClient)
  public
    [GET]
    [Consumes(MEDIA_TYPE.JSON)]
    function GetNeighbours(geonameId: Int64; const username: string = 'demo'): TGeonames; virtual;
    [POST]
    [Produces(MEDIA_TYPE.JSON)]
    [Consumes(MEDIA_TYPE.JSON)]
    function GetStatus(AMessage: TStatusMessage): TStatusMessage; virtual;

  end;

implementation

{ TGeonamesClient }
{$WARNINGS OFF}
function TGeonamesClient.GetNeighbours(geonameId: Int64; const username: string): TGeonames;
begin
  Writeln('GetNeighbours');
end;

function TGeonamesClient.GetStatus(AMessage: TStatusMessage): TStatusMessage;
begin
  Writeln('GetStatus');
end;
{$WARNINGS ON}
{ TMessage }

destructor TStatusMessage.Destroy;
begin
  FStatus.Free;
  inherited;
end;

{ TGeonames }

destructor TGeonames.Destroy;
begin
  Fgeonames.Free;
  inherited;
end;

{ TSvObjectList<T> }

constructor TSvObjectList<T>.Create;
begin
  inherited Create(True);
end;

end.
