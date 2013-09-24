unit ODataNorthwindClient;

interface

uses
  SvHTTP.Attributes
  ,SvHTTPClientInterface
  ,SvREST.Client
  ,SvContainers
  ;

type
  TCustomer = class
  private
    FCustomerId: string;
    FCompanyName: string;
    FContactName: string;
    FContactTitle: string;
    FAddress: string;
    FCity: string;
    FCountry: string;
    FPhone: string;
    FFax: string;
  public
    property CustomerId: string read FCustomerId write FCustomerId;
    property CompanyName: string read FCompanyName write FCompanyName;
    property ContactName: string read FContactName write FContactName;
    property ContactTitle: string read FContactTitle write FContactTitle;
    property Address: string read FAddress write FAddress;
    property City: string read FCity write FCity;
    property Country: string read FCountry write FCountry;
    property Phone: string read FPhone write FPhone;
    property Fax: string read FFax write FFax;
  end;

  TCustomers = class
  private
    FValue: TSvObjectList<TCustomer>;
  public
    destructor Destroy; override;

    property Value: TSvObjectList<TCustomer> read FValue write FValue;
  end;

  TOrder = class
  private
    FOrderId: Integer;
    FCustomerId: string;
    FEmployeeId: Integer;
    FOrderDate: string;
    FShippedDate: string;
    FShipName: string;
    FShipAddress: string;
    FShipCity: string;
    FShipCountry: string;
  public
    property OrderId: Integer read FOrderId write FOrderId;
    property CustomerId: string read FCustomerId write FCustomerId;
    property EmployeeId: Integer read FEmployeeId write FEmployeeId;
    property OrderDate: string read FOrderDate write FOrderDate;
    property ShippedDate: string read FShippedDate write FShippedDate;
    property ShipName: string read FShipName write FShipName;
    property ShipAddress: string read FShipAddress write FShipAddress;
    property ShipCity: string read FShipCity write FShipCity;
    property ShipCountry: string read FShipCountry write FShipCountry;
  end;

  TOrders = class
  private
    FValue: TSvObjectList<TOrder>;
  public
    destructor Destroy; override;

    property Value: TSvObjectList<TOrder> read FValue write FValue;
  end;

  TODataNorthwindClient = class(TRESTClient)
  public
    [GET] [Path('/Customers')] [Consumes(MEDIA_TYPE.JSON)]
    {$WARNINGS OFF}
    function GetCustomers([Context] out AResponse: IHttpResponse): TCustomers; virtual;
    ///Orders?$filter=CustomerID eq 'ALFKI'
    [GET] [Path('/Orders')] [Consumes(MEDIA_TYPE.JSON)]
    function GetCustomerOrders([QueryParam('$filter')] const AFilter: string; [Context] out AResponse: IHttpResponse): TOrders; virtual;
    {$WARNINGS ON}
  end;

implementation


{$WARNINGS OFF}
{ TODataNorthwindClient }

function TODataNorthwindClient.GetCustomerOrders(const AFilter: string; out AResponse: IHttpResponse): TOrders;
begin
  //
end;

function TODataNorthwindClient.GetCustomers(out AResponse: IHttpResponse): TCustomers;
begin
  //
end;

{$WARNINGS ON}

{ TCustomers }

destructor TCustomers.Destroy;
begin
  FValue.Free;
  inherited Destroy;
end;

{ TOrders }

destructor TOrders.Destroy;
begin
  FValue.Free;
  inherited Destroy;
end;

end.
