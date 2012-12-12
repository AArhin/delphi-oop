unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, SvClasses;

type
  TForm3 = class(TForm)
    ed1: TLabeledEdit;
    lblPath: TLabel;
    btn1: TButton;
    btnGoUp: TButton;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnGoUpClick(Sender: TObject);
  private
    { Private declarations }
    FPathBuilder: TPathBuilder;
  public
    { Public declarations }
    procedure PrintPath();
  end;

var
  Form3: TForm3;

implementation


{$R *.dfm}

procedure TForm3.btn1Click(Sender: TObject);
begin
  FPathBuilder.Add(ed1.Text);
  PrintPath();
end;

procedure TForm3.btnGoUpClick(Sender: TObject);
begin
  FPathBuilder.GoUpFolder();
  PrintPath();
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  FPathBuilder := TPathBuilder.InitCurrentDir;
  PrintPath();
end;

procedure TForm3.PrintPath;
begin
  lblPath.Caption := FPathBuilder.ToString;
end;

end.
