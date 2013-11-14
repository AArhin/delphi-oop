unit SvBindings.VCLControls;

interface

uses
  ExtCtrls
  ,Controls
  ,Messages
  ,Classes
  ,DSharp.Bindings.Notifications
  ;

type
  TButtonedEdit = class(ExtCtrls.TButtonedEdit, INotifyPropertyChanged)
  private
    FNotifyPropertyChanged: INotifyPropertyChanged;
    property NotifyPropertyChanged: INotifyPropertyChanged
      read FNotifyPropertyChanged implements INotifyPropertyChanged;
    procedure WMChar(var Message: TWMChar); message WM_CHAR;
  protected
    procedure Change; override;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  DSharp.Bindings.Exceptions
  ,Windows
  ;

{ TButtonedEdit }

procedure TButtonedEdit.Change;
begin
  inherited;
  NotifyPropertyChanged.DoPropertyChanged('Text');
end;

procedure TButtonedEdit.CMExit(var Message: TCMExit);
begin
  try
    NotifyPropertyChanged.DoPropertyChanged('Text', utLostFocus);
    inherited;
  except
    on EValidationError do
    begin
      SetFocus;
    end;
  end;
end;

constructor TButtonedEdit.Create(AOwner: TComponent);
begin
  inherited;
  FNotifyPropertyChanged := TNotifyPropertyChanged.Create(Self);
end;

procedure TButtonedEdit.WMChar(var Message: TWMChar);
begin
  inherited;
  if Message.CharCode = VK_RETURN then
  begin
    NotifyPropertyChanged.DoPropertyChanged('Text', utExplicit);
  end;
end;

end.
