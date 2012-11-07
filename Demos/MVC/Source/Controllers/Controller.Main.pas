unit Controller.Main;

interface

uses
  Controller.Base
  ,ViewMain
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
    {$HINTS ON}
  protected
    procedure Initialize(); override;

    procedure DoOnCanvasPaint(Sender: TObject);
  end;

  function CreateMainController: IController<TUser>;

implementation

uses
  Graphics
  ,Forms
  ;

function CreateMainController: IController<TUser>;
begin
  TControllerFactory<TUser>.RegisterFactoryMethod(TfrmMain
  , function(AViewClass: TClass): IController<TUser>
    begin
      Application.CreateForm(TfrmMain, frmMain);
      Result := TMainController.Create(TUser.Create, frmMain);
      Result.AutoFreeModel := True;
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

procedure TMainController.Initialize;
begin
  Model.Name := 'MVC Demo';
  Model.Email := 'mvc@gmail.com';
  pbCanvas.OnPaint := DoOnCanvasPaint;
end;

end.
