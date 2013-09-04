unit REST.Method;

interface

uses
  HTTPClientInterface
  ,Generics.Collections
  ,Rtti
  ;

type
  TRESTMethodParameter = class
  private
    FName: string;
    FValue: TValue;
  public
    function ToString(): string; reintroduce;

    property Name: string read FName write FName;
    property Value: TValue read FValue write FValue;
  end;

  TRESTMethod = class
  private
    FRequestType: TRequestType;
    FName: string;
    FPath: string;
    FParameters: TObjectList<TRESTMethodParameter>;
    FReturnValue: TValue;
    FConsumeMediaType: MEDIA_TYPE;
    FUrl: string;
    FProduceMediaType: MEDIA_TYPE;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    property ConsumeMediaType: MEDIA_TYPE read FConsumeMediaType write FConsumeMediaType;
    property ProduceMediaType: MEDIA_TYPE read FProduceMediaType write FProduceMediaType;
    property Name: string read FName write FName;
    property RequestType: TRequestType read FRequestType write FRequestType;
    property Path: string read FPath write FPath;
    property Parameters: TObjectList<TRESTMethodParameter> read FParameters;
    property ReturnValue: TValue read FReturnValue write FReturnValue;
    property Url: string read FUrl write FUrl;
  end;

implementation

{ TRESTMethod }

constructor TRESTMethod.Create;
begin
  FParameters := TObjectList<TRESTMethodParameter>.Create(True);
  FReturnValue := TValue.Empty;
end;

destructor TRESTMethod.Destroy;
begin
  FParameters.Free;
  inherited Destroy;
end;

{ TRESTMethodParameter }

function TRESTMethodParameter.ToString: string;
begin
  Result := FValue.ToString;
end;

end.
