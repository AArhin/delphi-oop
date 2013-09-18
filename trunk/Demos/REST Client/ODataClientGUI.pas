unit ODataClientGUI;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ODataNorthwindClient, VirtualTrees, ExtCtrls;

type
  TfrmOData = class(TForm)
    pcData: TPageControl;
    tsCustomers: TTabSheet;
    pTop: TPanel;
    btnGet: TButton;
    vtCustomers: TVirtualStringTree;
    tsJson: TTabSheet;
    mmoJSON: TMemo;
    btnGetJSON: TButton;
    tsOrders: TTabSheet;
    btnGetOrders: TButton;
    vtOrders: TVirtualStringTree;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGetClick(Sender: TObject);
    procedure vtCustomersGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType; var CellText: string);
    procedure btnGetJSONClick(Sender: TObject);
    procedure btnGetOrdersClick(Sender: TObject);
    procedure vtOrdersGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType; var CellText: string);
    procedure vtCustomersDblClick(Sender: TObject);
  private
    { Private declarations }
    FRestClient: TODataNorthwindClient;
    FCustomers: TCustomers;
    FOrders: TOrders;
  protected
    procedure DoGetOrders();
  public
    { Public declarations }
  end;

var
  frmOData: TfrmOData;

implementation

uses
  SvWeb.Consts
  ,SvHTTPClient.Indy
  ;

{$R *.dfm}

procedure TfrmOData.btnGetClick(Sender: TObject);
begin
  FCustomers.Free;
  FCustomers := FRestClient.GetCustomers();
  vtCustomers.RootNodeCount := FCustomers.Value.Count;
  pcData.ActivePageIndex := 0;
end;

procedure TfrmOData.btnGetJSONClick(Sender: TObject);
begin
  mmoJSON.Lines.Text := FRestClient.GetCustomersJSON;
  pcData.ActivePageIndex := 2;
end;

procedure TfrmOData.btnGetOrdersClick(Sender: TObject);
begin
  DoGetOrders();
end;

procedure TfrmOData.DoGetOrders;
var
  LCustomer: TCustomer;
begin
  if not Assigned(vtCustomers.FocusedNode) then
    Exit;

  LCustomer := FCustomers.Value[vtCustomers.FocusedNode.Index];
  FOrders.Free;
  FOrders := FRestClient.GetCustomerOrders(Format('CustomerID eq %S', [QuotedStr(LCustomer.CustomerId)]));
  vtOrders.RootNodeCount := FOrders.Value.Count;
  pcData.ActivePageIndex := 1;
end;

procedure TfrmOData.FormCreate(Sender: TObject);
begin
  DesktopFont := True;
  ReportMemoryLeaksOnShutdown := True;
  pcData.ActivePageIndex := 0;
  FCustomers := nil;
  FOrders := nil;
  FRestClient := TODataNorthwindClient.Create('http://services.odata.org/V3/Northwind/Northwind.svc');
  FRestClient.SetHttpClient(HTTP_CLIENT_INDY);
  FRestClient.EncodeParameters := True;
end;

procedure TfrmOData.FormDestroy(Sender: TObject);
begin
  FRestClient.Free;
  FCustomers.Free;
  FOrders.Free;
end;

procedure TfrmOData.vtCustomersDblClick(Sender: TObject);
begin
  DoGetOrders();
end;

procedure TfrmOData.vtCustomersGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType; var CellText: string);
var
  LCustomer: TCustomer;
begin
  LCustomer := FCustomers.Value[Node.Index];
  case Column of
    0: CellText := LCustomer.CustomerId;
    1: CellText := LCustomer.CompanyName;
    2: CellText := LCustomer.ContactName;
    3: CellText := LCustomer.ContactTitle;
    4: CellText := LCustomer.Address;
    5: CellText := LCustomer.City;
    6: CellText := LCustomer.Country;
    7: CellText := LCustomer.Phone;
    8: CellText := LCustomer.Fax;
  end;
end;

procedure TfrmOData.vtOrdersGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType; var CellText: string);
var
  LOrder: TOrder;
begin
  LOrder := FOrders.Value[Node.Index];
  case Column of
    0: CellText := IntToStr(LOrder.OrderId);
    1: CellText := LOrder.CustomerId;
    2: CellText := LOrder.OrderDate;
    3: CellText := LOrder.ShippedDate;
    4: CellText := LOrder.ShipName;
    5: CellText := LOrder.ShipAddress;
    6: CellText := LOrder.ShipCity;
    7: CellText := LOrder.ShipCountry;
  end;
end;

end.
