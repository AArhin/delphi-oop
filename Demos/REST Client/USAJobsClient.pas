unit USAJobsClient;

interface

uses
  SvREST.Client
  ,Generics.Collections
  ,SvHTTPClientInterface
  ,SvHTTP.Attributes
  ;

type
  TSvObjectList<T: class> = class(TObjectList<T>)
  public
    constructor Create(); reintroduce; overload;
  end;

  TJobData = class
  private
    FJobTitle: string;
    FOrganizationName: string;
    FJobSummary: string;
  public
    property JobTitle: string read FJobTitle write FJobTitle;
    property OrganizationName: string read FOrganizationName write FOrganizationName;
    property JobSummary: string read FJobSummary write FJobSummary;
  end;

  TJobs = class
  private
    FTotalJobs: Integer;
    FJobData: TSvObjectList<TJobData>;
  public
    destructor Destroy; override;

    property TotalJobs: Integer read FTotalJobs write FTotalJobs;
    property JobData: TSvObjectList<TJobData> read FJobData write FJobData;
  end;

  //https://data.usajobs.gov/Rest
  [Path('/jobs')]
  TUSAJobsClient = class(TRESTClient)
  public
    [GET]
    [Consumes(MEDIA_TYPE.JSON)]
    function GetITJobs(series: Integer = 2210; Page: Integer = 1): TJobs; virtual;
  end;

implementation

{ TUSAJobsClient }
{$WARNINGS OFF}
function TUSAJobsClient.GetITJobs(series: Integer; Page: Integer): TJobs;
begin
  //
end;
{$WARNINGS ON}
{ TSvObjectList<T> }

constructor TSvObjectList<T>.Create;
begin
  inherited Create(True);
end;

{ TJobs }

destructor TJobs.Destroy;
begin
  if Assigned(FJobData) then
    FJobData.Free;
  inherited;
end;

end.
