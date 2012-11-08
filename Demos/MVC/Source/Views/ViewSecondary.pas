unit ViewSecondary;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs

  , ExtCtrls, StdCtrls, DSharp.Bindings.VCLControls {<-- must be the last unit in uses}
  ;

type
  TfrmSecondary = class(TForm)
    edtName: TEdit;
    edtEmail: TEdit;
    pbCanvas: TPaintBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSecondary: TfrmSecondary;

implementation

{$R *.dfm}

end.
