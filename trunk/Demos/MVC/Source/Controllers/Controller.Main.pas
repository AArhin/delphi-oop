unit Controller.Main;

interface

uses
  Controller.Base
  ,Model.User
  ,SvBindings
  ,StdCtrls
  ,ExtCtrls
  ;

type
  TMainController = class(TBaseController<TUser>)
  private
    {$HINTS OFF}
    [Bind('Name', 'Text')]
    edtName: TEdit;
    [Bind('Email', 'Text')]
    edtEmail: TEdit;
    [Bind]
    pbCanvas: TPaintBox;
    [Bind]
    btnNewForm: TButton;
    {$HINTS ON}
  protected
    procedure Initialize(); override;

    procedure DoOnCanvasPaint(Sender: TObject);
    procedure DoOpenNewForm(Sender: TObject);
  end;

  function CreateMainController(AUser: TUser): IController<TUser>;

implementation

uses
  Graphics
  ,Forms
  ,ViewMain
  ,ViewSecondary
  ;

function CreateMainController(AUser: TUser): IController<TUser>;
begin
  TControllerFactory<TUser>.RegisterFactoryMethod(TfrmMain
  , function: IController<TUser>
    begin
      Application.CreateForm(TfrmMain, frmMain);
      Result := TMainController.Create(AUser, frmMain);
      Result.AutoFreeModel := True;
    end);

  TControllerFactory<TUser>.RegisterFactoryMethod(TfrmSecondary
  , function: IController<TUser>
    var
      LForm: TfrmSecondary;
    begin
      LForm := TfrmSecondary.Create(Application);
      Result := TMainController.Create(AUser, LForm);
      LForm.ShowModal;
    end);

  Result := TControllerFactory<TUser>.GetInstance(TfrmMain);
end;

{ TMainController }

procedure TMainController.DoOnCanvasPaint(Sender: TObject);
var
  LText: string;
  LPaintBox: TPaintBox;
begin
  LPaintBox := Sender as TPaintBox;
  LText := Model.Name + ' ' + Model.Email;
  LPaintBox.Canvas.Brush.Color := clWhite;
  LPaintBox.Canvas.FillRect(LPaintBox.Canvas.ClipRect);
  LPaintBox.Canvas.Font.Color := clBlue;
  LPaintBox.Canvas.TextOut(5,5, LText);
end;

procedure TMainController.DoOpenNewForm(Sender: TObject);
begin
  TControllerFactory<TUser>.GetInstance(TfrmSecondary);
end;

procedure TMainController.Initialize;
begin
  if Assigned(pbCanvas) then
    pbCanvas.OnPaint := DoOnCanvasPaint;
  if Assigned(btnNewForm) then
    btnNewForm.OnClick := DoOpenNewForm;
end;

end.
