You decorate your form with attributes which will help you to bind your visual control with model easily. You can even write custom expressions to add more logic to the binding process.

# Example #

Say you have a form like this:

```
type
  TfrmTest = class(TForm)
    [Bind('Name', 'Text')]
    edt1: TEdit;
    [Bind('Name', 'Caption')]
    lbl1: TLabel;
    Memo1: TMemo;
    [Bind('IsEnabled', 'Enabled')]
    Button1: TButton;
    [Bind('IsChecked', 'Checked')]
    CheckBox1: TCheckBox;
    [Bind('ID', 'Value')]
    SpinEdit1: TSpinEdit;
    [Bind('Color', 'Selected')]
    ColorBox1: TColorBox;
    [Bind('Date', 'Date')]
    DateTimePicker1: TDateTimePicker;
    [Bind('Points', 'Position')]
    TrackBar1: TTrackBar;
    [BindExpression('Caption', 'Text', 'Uppercase(Caption)', 'UpperCase(Text)')]
    edScript: TEdit;
    [BindExpression('CurrentDate', 'Text', 'FormatDateTime(''yyyy-mmmm-dd'',CurrentDate)', '')]
    edDate: TEdit;
```

And you have your model:
```
type
  TData = class
  private
    FName: string;
    FID: Integer;
    FDate: TDateTime;
    FPoints: Integer;
    FColor: TColor;
    FIsChecked: Boolean;
    FIsEnabled: Boolean;
    FCaption: string;
    FCurrentDate: TDateTime;
    procedure SetName(const Value: string);
    procedure SetID(const Value: Integer);
    procedure SetDate(const Value: TDateTime);
    procedure SetPoints(const Value: Integer);
    procedure SetColor(const Value: TColor);
    procedure SetIsChecked(const Value: Boolean);
    procedure SetIsEnabled(const Value: Boolean);
    procedure SetCaption(const Value: string);
    procedure SetCurrentDate(const Value: TDateTime);
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetDefaults();
    procedure Clear();

    property Name: string read FName write SetName;
    property Caption: string read FCaption write SetCaption;
    property CurrentDate: TDateTime read FCurrentDate write SetCurrentDate;
    property ID: Integer read FID write SetID;
    property Date: TDateTime read FDate write SetDate;
    property Points: Integer read FPoints write SetPoints;
    property Color: TColor read FColor write SetColor;
    property IsChecked: Boolean read FIsChecked write SetIsChecked;
    property IsEnabled: Boolean read FIsEnabled write SetIsEnabled;
  end;
```

Then all you need is to call:
```
TDataBindManager.BindView(FForm, FData);
```
And all the hard work will be automatically done for you. For example, if you change form's control value, corresponding model's value will change also.

```
//if we change edit value
FForm.edScript.Text := 'test';
//now our model also changes to FData.Caption := 'TEST';
CheckEqualsString('TEST', FData.Caption);
```



