unit SvREST.Method;

interface

uses
  SvHTTPClientInterface
  ,Generics.Collections
  ,Rtti
  ;

type
  TParameterType = (ptBody, ptHeader);

  TRESTMethodParameter = class
  private
    FName: string;
    FValue: TValue;
    FIsNameless: Boolean;
    FIsDisabled: Boolean;
    FParamType: TParameterType;
  public
    function ToString(): string; reintroduce;

    property IsDisabled: Boolean read FIsDisabled write FIsDisabled;
    property IsNameless: Boolean read FIsNameless write FIsNameless;
    property Name: string read FName write FName;
    property ParamType: TParameterType read FParamType write FParamType;
    property Value: TValue read FValue write FValue;
  end;

  TRESTMethod = class
  private
    FRequestType: TRequestType;
    FName: string;
    FPath: string;
    FParameters: TObjectList<TRESTMethodParameter>;
    FHeaderParameters: TObjectList<TRESTMethodParameter>;
    FReturnValue: TValue;
    FConsumeMediaType: MEDIA_TYPE;
    FUrl: string;
    FProduceMediaType: MEDIA_TYPE;
    FHeaderParameteres: TObjectList<TRESTMethodParameter>;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    function GetEnabledParameters: TArray<TRESTMethodParameter>;
    function GetHeaderParameters: TArray<TRESTMethodParameter>;

    property ConsumeMediaType: MEDIA_TYPE read FConsumeMediaType write FConsumeMediaType;
    property ProduceMediaType: MEDIA_TYPE read FProduceMediaType write FProduceMediaType;
    property Name: string read FName write FName;
    property RequestType: TRequestType read FRequestType write FRequestType;
    property Path: string read FPath write FPath;
    property HeaderParameteres: TObjectList<TRESTMethodParameter> read FHeaderParameteres;
    property Parameters: TObjectList<TRESTMethodParameter> read FParameters;
    property ReturnValue: TValue read FReturnValue write FReturnValue;
    property Url: string read FUrl write FUrl;
  end;

implementation

{ TRESTMethod }

constructor TRESTMethod.Create;
begin
  FParameters := TObjectList<TRESTMethodParameter>.Create(True);
  FHeaderParameters := TObjectList<TRESTMethodParameter>.Create(True);
  FReturnValue := TValue.Empty;
end;

destructor TRESTMethod.Destroy;
begin
  FParameters.Free;
  FHeaderParameters.Free;
  inherited Destroy;
end;

function TRESTMethod.GetEnabledParameters: TArray<TRESTMethodParameter>;
var
  I, LIndex: Integer;
begin
  SetLength(Result, Parameters.Count);
  LIndex := 0;
  for I := 0 to Parameters.Count - 1 do
  begin
    if not Parameters[I].IsDisabled and (Parameters[i].ParamType = ptBody) then
    begin
      Result[LIndex] := Parameters[i];
      Inc(LIndex);
    end;
  end;

  SetLength(Result, LIndex);
end;

function TRESTMethod.GetHeaderParameters: TArray<TRESTMethodParameter>;
var
  I, LIndex: Integer;
begin
  SetLength(Result, Parameters.Count);
  LIndex := 0;
  for I := 0 to Parameters.Count - 1 do
  begin
    if (Parameters[i].ParamType = ptHeader) then
    begin
      Result[LIndex] := Parameters[i];
      Inc(LIndex);
    end;
  end;

  SetLength(Result, LIndex);
end;

{ TRESTMethodParameter }

function TRESTMethodParameter.ToString: string;
begin
  Result := FValue.ToString;
end;

end.
