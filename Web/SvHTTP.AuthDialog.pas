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
    procedure wbBrowserNavigateComplete2(ASender: TObject; const pDisp: IDispatch; var URL: OleVariant);
  private
    { Private declarations }
    FAccessCode: string;
    FURL: string;
    procedure SetURL(const Value: string);
  protected
    procedure DoConfirm();

    procedure DoTitleChange(ASender: TObject; const Text: WideString);
  public
    { Public declarations }
    property AccessCode: string read FAccessCode write FAccessCode;
    property URL: string read FURL write SetURL;
  end;

//var
//  frmAuthDialog: TfrmAuthDialog;

  function GetResponceCode(const AURL: string; out AAccessCode: string): Boolean;

implementation

uses
  StrUtils
  ;

{$R *.dfm}

function GetResponceCode(const AURL: string; out AAccessCode: string): Boolean;
var
  LDialog: TfrmAuthDialog;
begin
  LDialog := TfrmAuthDialog.Create(nil);
  try
    LDialog.URL := AURL;

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



procedure TfrmAuthDialog.DoTitleChange(ASender: TObject; const Text: WideString);
const
  TITLE_SUCCESS = 'Success ';
var
  LParse: TStringList;
begin
  if not StartsText(TITLE_SUCCESS, Text) then
    Exit;

  LParse := TStringList.Create;
  try
    LParse.NameValueSeparator := '=';
    LParse.Delimiter := '&';
    LParse.StrictDelimiter := True;
    LParse.DelimitedText := Copy(Text, Length(TITLE_SUCCESS)+1, Length(Text)-1);
    if LParse.Count > 0 then
    begin
      FAccessCode := LParse.Values['code'];
      if (FAccessCode <> '') then
        ModalResult := mrOk;
    end;
  finally
    LParse.Free;
  end;
end;

procedure TfrmAuthDialog.FormCreate(Sender: TObject);
begin
  DesktopFont := True;
end;

procedure TfrmAuthDialog.SetURL(const Value: string);
begin
  if FURL <> Value then
  begin
    FURL := Value;
    wbBrowser.Navigate(FURL);
  end;
end;

procedure TfrmAuthDialog.wbBrowserNavigateComplete2(ASender: TObject; const pDisp: IDispatch; var URL: OleVariant);
begin
  wbBrowser.OnTitleChange := DoTitleChange;
end;

end.
