unit SvREST.Method;

interface

uses
  SvHTTPClientInterface
  ,Generics.Collections
  ,Rtti
  ;

type
  TSvRESTParameterType = (ptBody, ptHeader);

  TSvRESTMethodParameter = class
  private
    FName: string;
    FValue: TValue;
    FIsNameless: Boolean;
    FIsDisabled: Boolean;
    FParamType: TSvRESTParameterType;
    FIsInjectable: Boolean;
  public
    function ToString(): string; reintroduce;

    property IsDisabled: Boolean read FIsDisabled write FIsDisabled;
    property IsNameless: Boolean read FIsNameless write FIsNameless;
    property IsInjectable: Boolean read FIsInjectable write FIsInjectable;
    property Name: string read FName write FName;
    property ParamType: TSvRESTParameterType read FParamType write FParamType;
    property Value: TValue read FValue write FValue;
  end;

  TSvRESTMethod = class
  private
    FRequestType: TRequestType;
    FName: string;
    FPath: string;
    FParameters: TObjectList<TSvRESTMethodParameter>;
    FHeaderParameters: TObjectList<TSvRESTMethodParameter>;
    FReturnValue: TValue;
    FConsumeMediaType: MEDIA_TYPE;
    FUrl: string;
    FProduceMediaType: MEDIA_TYPE;
    FHeaderParameteres: TObjectList<TSvRESTMethodParameter>;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    function GetEnabledParameters: TArray<TSvRESTMethodParameter>;
    function GetHeaderParameters: TArray<TSvRESTMethodParameter>;

    property ConsumeMediaType: MEDIA_TYPE read FConsumeMediaType write FConsumeMediaType;
    property ProduceMediaType: MEDIA_TYPE read FProduceMediaType write FProduceMediaType;
    property Name: string read FName write FName;
    property RequestType: TRequestType read FRequestType write FRequestType;
    property Path: string read FPath write FPath;
    property HeaderParameteres: TObjectList<TSvRESTMethodParameter> read FHeaderParameteres;
    property Parameters: TObjectList<TSvRESTMethodParameter> read FParameters;
    property ReturnValue: TValue read FReturnValue write FReturnValue;
    property Url: string read FUrl write FUrl;
  end;

implementation

{ TRESTMethod }

constructor TSvRESTMethod.Create;
begin
  FParameters := TObjectList<TSvRESTMethodParameter>.Create(True);
  FHeaderParameters := TObjectList<TSvRESTMethodParameter>.Create(True);
  FReturnValue := TValue.Empty;
end;

destructor TSvRESTMethod.Destroy;
begin
  FParameters.Free;
  FHeaderParameters.Free;
  inherited Destroy;
end;

function TSvRESTMethod.GetEnabledParameters: TArray<TSvRESTMethodParameter>;
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

function TSvRESTMethod.GetHeaderParameters: TArray<TSvRESTMethodParameter>;
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

function TSvRESTMethodParameter.ToString: string;
begin
  Result := FValue.ToString;
end;

end.
