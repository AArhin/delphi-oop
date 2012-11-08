unit Model.User;

interface

type
  TUser = class
  private
    FName: string;
    FEmail: string;
  protected
    procedure SetName(const Value: string);
    procedure SetEMail(const Value: string);
  public
    constructor Create(const AName, AEmail: string); virtual;

    property Name: string read FName write SetName;
    property Email: string read FEmail write SetEMail;
  end;

implementation

uses
  DSharp.Bindings
  ;

{ TUser }

constructor TUser.Create(const AName, AEmail: string);
begin
  inherited Create;
  FName := AName;
  FEmail := AEmail;
end;

procedure TUser.SetEMail(const Value: string);
begin
  if FEmail <> Value then
  begin
    FEmail := Value;
    NotifyPropertyChanged(Self, 'Email');
  end;
end;

procedure TUser.SetName(const Value: string);
begin
  if FName <> Value then
  begin
    FName := Value;
    NotifyPropertyChanged(Self, 'Name');
  end;
end;

end.
