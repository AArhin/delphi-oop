program RestClientGUI;

uses
  Forms,
  ODataClientGUI in 'ODataClientGUI.pas' {frmOData},
  ODataNorthwindClient in 'ODataNorthwindClient.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmOData, frmOData);
  Application.Run;
end.
