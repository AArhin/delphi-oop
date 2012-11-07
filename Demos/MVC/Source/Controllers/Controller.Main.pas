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
  TMainController = class(TBaseController<TUser, TfrmMain>)
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

  function CreateMainController(AView: TObject): IController<TUser, TfrmMain>;

implementation

uses
  Graphics
  ;

function CreateMainController(AView: TObject): IController<TUser, TfrmMain>;
begin
  Result := TMainController.Create(TUser.Create, AView as TfrmMain);
  Result.AutoFreeModel := True;
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
