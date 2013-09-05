unit RESTClientIntegrationTest;

interface

uses
  TestFramework, SvHTTPClientInterface, Generics.Collections, Classes, Rtti, SvVMI, SvREST.Client
  ,SvHTTP.Attributes, SvREST.Method
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
  [QueryParamNameValue('Page', '1')]
  TUsaJobsRESTClient = class(TRESTClient)
  private
    FLastURL: string;
  protected
    function GenerateUrl(ARestMethod: TRESTMethod): string; override;
  public
    [GET]
    [Consumes(MEDIA_TYPE.JSON)]
    [QueryParamNameValue('series', '2210')]
    function GetITJobs(): TJobs; virtual;
  end;

  TUSAJobsIntegrationTests = class(TTestCase)
  private
    FRESTClient: TUsaJobsRESTClient;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GetITJobs();
  end;

implementation

uses
  SvWeb.Consts
  ,StrUtils
  ;

{ TUSAJobsIntegrationTests }

procedure TUSAJobsIntegrationTests.GetITJobs;
var
  LJobs: TJobs;
begin
  LJobs := FRESTClient.GetITJobs();
  try
    CheckTrue(LJobs.JobData <> nil);

    CheckTrue( ContainsText(FRESTClient.FLastURL, 'series=2210') );
    CheckTrue( ContainsText(FRESTClient.FLastURL, 'Page=1') );
  finally
    LJobs.Free;
  end;
end;

procedure TUSAJobsIntegrationTests.SetUp;
begin
  inherited;
  FRESTClient := TUsaJobsRESTClient.Create('https://data.usajobs.gov/api');
  FRESTClient.SetHttpClient(HTTP_CLIENT_INDY);
end;

procedure TUSAJobsIntegrationTests.TearDown;
begin
  inherited;
  FRESTClient.Free;
end;

{ TUsaJobsRESTClient }

function TUsaJobsRESTClient.GenerateUrl(ARestMethod: TRESTMethod): string;
begin
  Result := inherited GenerateUrl(ARestMethod);
  FLastURL := Result;
end;

{$WARNINGS OFF}
function TUsaJobsRESTClient.GetITJobs(): TJobs;
begin
  //do nothing
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
  FJobData.Free;
  inherited;
end;

initialization
  RegisterTest(TUSAJobsIntegrationTests.Suite);

end.
