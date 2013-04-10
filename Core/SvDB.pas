unit SvDB;

interface

uses
  Classes
  ,Generics.Collections
  ;

type
  ISQLBuilder = interface(IInvokable)
    function ToString(): string;

    function Select(): ISQLBuilder;
    function Column(const AColumnName: string): ISQLBuilder;
    function From(const ATableName: string): ISQLBuilder;
    function Join(const AJoinCriteria: string): ISQLBuilder;
    function LeftOuterJoin(const AJoinCriteria: string): ISQLBuilder;
    function RightOuterJoin(const AJoinCriteria: string): ISQLBuilder;
    function Where(const ACriteria: string): ISQLBuilder;
    function GroupBy(const AGroupByCriteria: string): ISQLBuilder;
    function OrderBy(const AOrderByCriteria: string): ISQLBuilder;
  end;

  TAnsiSQLBuilder = class;

  TJoinType = (jtNone, jtInner, jtLeftOuter, jtRightOuter);

  TSQLTable = class
  private
    FTablename: string;
    FJoinType: TJoinType;
  public
    constructor Create(const ATablename: string; AJoinType: TJoinType = jtNone); virtual;

    function ToString(): string; override;
  end;

  TSQLStatementType = (stSelect, stInsert, stUpdate, stDelete);

  TSQLStatement = class
  private
    FOwner: TAnsiSQLBuilder;
  public
    constructor Create(AOwner: TAnsiSQLBuilder); virtual;

    function ToString(): string; override;

    property Owner: TAnsiSQLBuilder read FOwner;
  end;

  TSelectStatement = class(TSQLStatement)
  public
    function ToString(): string; override;
  end;

  TAnsiSQLBuilder = class(TInterfacedObject, ISQLBuilder)
  private
    FSQLStmtType: TSQLStatementType;
    FColumns: TStringList;
    FTable: TSQLTable;
    FJoinedTables: TObjectList<TSQLTable>;
    FWhereCriterias: TStringList;
    FGroupByCriterias: TStringList;
    FOrderByCriterias: TStringList;
  protected
    function DoBuildSQL(AStatement: TSQLStatement): string; virtual;
  public
    constructor Create(); virtual;
    destructor Destroy; override;

    function ToString(): string; override;

    function Select(): ISQLBuilder; virtual;
    function Column(const AColumnName: string): ISQLBuilder; virtual;
    function From(const ATableName: string): ISQLBuilder; virtual;
    function Join(const AJoinCriteria: string): ISQLBuilder; virtual;
    function LeftOuterJoin(const AJoinCriteria: string): ISQLBuilder; virtual;
    function RightOuterJoin(const AJoinCriteria: string): ISQLBuilder; virtual;
    function Where(const ACriteria: string): ISQLBuilder; virtual;
    function GroupBy(const AGroupByCriteria: string): ISQLBuilder; virtual;
    function OrderBy(const AOrderByCriteria: string): ISQLBuilder; virtual;
  end;


  function AnsiSQLBuilder(): ISQLBuilder;


implementation

uses
  SysUtils
  ;

type
  EAnsiSQLBuilderException = class(Exception);


function AnsiSQLBuilder(): ISQLBuilder;
begin
  Result := TAnsiSQLBuilder.Create();
end;


{ TAnsiSQLBuilder }

function TAnsiSQLBuilder.Column(const AColumnName: string): ISQLBuilder;
begin
  FColumns.Add(AColumnName);
  Result := Self;
end;

constructor TAnsiSQLBuilder.Create;
begin
  inherited Create;
  FSQLStmtType := stSelect;
  FColumns := TStringList.Create;
  FColumns.Delimiter := ',';
  FColumns.StrictDelimiter := True;
  FTable := TSQLTable.Create('');
  FJoinedTables := TObjectList<TSQLTable>.Create(True);
  FGroupByCriterias := TStringList.Create;
  FGroupByCriterias.Delimiter := ',';
  FGroupByCriterias.StrictDelimiter := True;
  FWhereCriterias := TStringList.Create;
  FOrderByCriterias := TStringList.Create;
  FOrderByCriterias.Delimiter := ',';
  FOrderByCriterias.StrictDelimiter := True;
end;

destructor TAnsiSQLBuilder.Destroy;
begin
  FColumns.Free;
  FTable.Free;
  FJoinedTables.Free;
  FGroupByCriterias.Free;
  FWhereCriterias.Free;
  FOrderByCriterias.Free;
  inherited Destroy;
end;

function TAnsiSQLBuilder.DoBuildSQL(AStatement: TSQLStatement): string;
begin
  Assert(Assigned(AStatement));
  Result := AStatement.ToString;
end;

function TAnsiSQLBuilder.From(const ATableName: string): ISQLBuilder;
begin
  FTable.FTablename := ATableName;
  Result := Self;
end;

function TAnsiSQLBuilder.GroupBy(const AGroupByCriteria: string): ISQLBuilder;
begin
  FGroupByCriterias.Add(AGroupByCriteria);
  Result := Self;
end;

function TAnsiSQLBuilder.Join(const AJoinCriteria: string): ISQLBuilder;
begin
  FJoinedTables.Add(TSQLTable.Create(AJoinCriteria, jtInner));
  Result := Self;
end;

function TAnsiSQLBuilder.LeftOuterJoin(const AJoinCriteria: string): ISQLBuilder;
begin
  FJoinedTables.Add(TSQLTable.Create(AJoinCriteria, jtLeftOuter));
  Result := Self;
end;

function TAnsiSQLBuilder.OrderBy(const AOrderByCriteria: string): ISQLBuilder;
begin
  FOrderByCriterias.Add(AOrderByCriteria);
  Result := Self;
end;

function TAnsiSQLBuilder.RightOuterJoin(const AJoinCriteria: string): ISQLBuilder;
begin
  FJoinedTables.Add(TSQLTable.Create(AJoinCriteria, jtRightOuter));
  Result := Self;
end;

function TAnsiSQLBuilder.Select: ISQLBuilder;
begin
  FSQLStmtType := stSelect;
  Result := Self;
end;

function TAnsiSQLBuilder.ToString: string;
var
  LStatement: TSQLStatement;
begin
  Result := '';

  case FSQLStmtType of
    stSelect: LStatement := TSelectStatement.Create(Self);
    stInsert: raise EAnsiSQLBuilderException.Create('Insert Not implemented');
    stUpdate: raise EAnsiSQLBuilderException.Create('Update Not implemented');
    stDelete: raise EAnsiSQLBuilderException.Create('Delete Not implemented');
  end;

  try
    Result := DoBuildSQL(LStatement);
  finally
    LStatement.Free;
  end;
end;

function TAnsiSQLBuilder.Where(const ACriteria: string): ISQLBuilder;
begin
  FWhereCriterias.Add(ACriteria);
  Result := Self;
end;

{ TSQLStatement }

constructor TSQLStatement.Create(AOwner: TAnsiSQLBuilder);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TSQLStatement.ToString: string;
begin
  Result := '';
end;

{ TSelectStatement }

function TSelectStatement.ToString: string;
var
  i: Integer;
  LBuilder: TStringBuilder;
begin
  Result := '';
  if (Owner.FColumns.Count < 1) or (Owner.FTable.FTablename = '') then
    Exit;

  LBuilder := TStringBuilder.Create;
  try
    LBuilder.Append('SELECT ' + Owner.FColumns.DelimitedText).AppendLine;
    LBuilder.Append(' FROM ' + Owner.FTable.ToString);

    for i := 0 to FOwner.FJoinedTables.Count - 1 do
    begin
      LBuilder.AppendLine.Append(' ' + FOwner.FJoinedTables[i].ToString);
    end;

    for i := 0 to FOwner.FWhereCriterias.Count - 1 do
    begin
      if i = 0 then
        LBuilder.AppendLine.Append(' WHERE ')
      else
        LBuilder.Append(' AND ');

      LBuilder.Append('(' + FOwner.FWhereCriterias[i] + ')');
    end;

    if FOwner.FGroupByCriterias.Count > 0 then
    begin
      LBuilder.AppendLine.Append(' GROUP BY ' + FOwner.FGroupByCriterias.DelimitedText);
    end;

    if FOwner.FOrderByCriterias.Count > 0 then
    begin
      LBuilder.AppendLine.Append(' ORDER BY ' + FOwner.FOrderByCriterias.DelimitedText);
    end;


    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

{ TSQLTable }

constructor TSQLTable.Create(const ATablename: string; AJoinType: TJoinType);
begin
  inherited Create();
  FTablename := ATablename;
  FJoinType := AJoinType;
end;

function TSQLTable.ToString: string;
begin
  Result := FTablename;
  case FJoinType of
    jtNone: Result := FTablename;
    jtInner: Result := 'JOIN ' + FTablename;
    jtLeftOuter: Result := 'LEFT OUTER JOIN ' + FTablename;
    jtRightOuter: Result := 'RIGHT OUTER JOIN ' + FTablename;
  end;
end;

end.
