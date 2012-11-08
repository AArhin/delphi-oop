unit ViewMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls

  , DSharp.Bindings.VCLControls {<-- must be the last unit in uses};

type
  TfrmMain = class(TForm)
    edtName: TEdit;
    edtEmail: TEdit;
    lbl1: TLabel;
    lbl2: TLabel;
    pbCanvas: TPaintBox;
    btnNewForm: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
