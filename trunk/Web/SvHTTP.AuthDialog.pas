unit SvHTTP.AuthDialog;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, OleCtrls, SHDocVw, ExtCtrls, ActnList;

type
  TfrmAuthDialog = class(TForm)
    pClient: TPanel;
    pBottom: TPanel;
    wbBrowser: TWebBrowser;
    edToken: TEdit;
    lblHint: TLabel;
    btnOk: TButton;
    alMain: TActionList;
    aConfirm: TAction;
    procedure FormCreate(Sender: TObject);
    procedure aConfirmUpdate(Sender: TObject);
    procedure aConfirmExecute(Sender: TObject);
  private
    { Private declarations }
    FAccessCode: string;
  protected
    procedure DoConfirm();
  public
    { Public declarations }
    property AccessCode: string read FAccessCode write FAccessCode;
  end;

//var
//  frmAuthDialog: TfrmAuthDialog;

  function GetResponceCode(const AURL: string; out AAccessCode: string): Boolean;

implementation

{$R *.dfm}

function GetResponceCode(const AURL: string; out AAccessCode: string): Boolean;
var
  LDialog: TfrmAuthDialog;
begin
  LDialog := TfrmAuthDialog.Create(nil);
  try
    LDialog.wbBrowser.Navigate(AURL);

    Result := (LDialog.ShowModal = mrOk);
    if Result then
    begin
      AAccessCode := LDialog.AccessCode;
    end;
  finally
    LDialog.Release;
  end;
end;

procedure TfrmAuthDialog.aConfirmExecute(Sender: TObject);
begin
  DoConfirm();
end;

procedure TfrmAuthDialog.aConfirmUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (edToken.Text <> '') and (Length(edToken.Text) > 1);
end;

procedure TfrmAuthDialog.DoConfirm;
begin
  FAccessCode := edToken.Text;
  ModalResult := mrOk;
end;

procedure TfrmAuthDialog.FormCreate(Sender: TObject);
begin
  DesktopFont := True;

end;

end.
