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

  TOrderDetail = class
  private
    FOrderId: Integer;
    FProductId: Integer;
    FUnitPrice: Currency;
    FQuantity: Integer;
    FDiscount: Single;
  public
    property OrderId: Integer read FOrderId write FOrderId;
    property ProductId: Integer read FProductId write FProductId;
    property UnitPrice: Currency read FUnitPrice write FUnitPrice;
    property Quantity: Integer read FQuantity write FQuantity;
    property Discount: Single read FDiscount write FDiscount;
  end;

  TOrderDetails = class
  private
    Fvalue: TsvObjectList<TOrderDetail>;
  public
    destructor Destroy; override;

    property value: TSvObjectList<TOrderDetail> read Fvalue write Fvalue;
  end;

  TNortwindClient = class(TRESTClient)
  public
    [GET]
    [Path('/Order_Details')]
    [Consumes(MEDIA_TYPE.JSON)]
    function GetOrderDetails(): TOrderDetails; virtual;
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

  TODataTests = class(TTestCase)
  private
    FRESTClient: TNortwindClient;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GetOrderDetails();
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

{ TOrderDetails }

destructor TOrderDetails.Destroy;
begin
  Fvalue.Free;
  inherited Destroy;
end;

{$WARNINGS OFF}
{ TNortwindClient }

function TNortwindClient.GetOrderDetails: TOrderDetails;
begin
  //
end;

{$WARNINGS ON}

{ TODataTests }

procedure TODataTests.GetOrderDetails;
var
  LOrderDetails: TOrderDetails;
begin
  LOrderDetails := FRESTClient.GetOrderDetails;
  try
    CheckTrue(LOrderDetails.value.Count > 0);
  finally
    LOrderDetails.Free;
  end;
end;

procedure TODataTests.SetUp;
begin
  inherited;
  FRESTClient := TNortwindClient.Create('http://services.odata.org/V3/Northwind/Northwind.svc');
  FRESTClient.SetHttpClient(HTTP_CLIENT_INDY);
end;

procedure TODataTests.TearDown;
begin
  inherited;
  FRESTClient.Free;
end;

initialization
  RegisterTest(TUSAJobsIntegrationTests.Suite);
  RegisterTest(TODataTests.Suite);

end.
