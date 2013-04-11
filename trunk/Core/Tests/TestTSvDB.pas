unit TestTSvDB;

interface

uses
  TestFramework, SvDB
  ;

type
  TSvAnsiSQLBuilderTests = class(TTestCase)
  private
    FSQLBuilder: ISQLBuilder;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Select();
    procedure Select_Union();
  end;

  TSvTransactSQLBuilderTests = class(TTestCase)
  private
    FSQLBuilder: ISQLBuilder;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure SelectTop();
  end;

implementation


{ TSvSQLBuilderTests }

procedure TSvAnsiSQLBuilderTests.Select;
var
  LSQL, LPreviousSQL: string;
begin
  CheckEquals('', FSQLBuilder.ToString);

  LSQL := FSQLBuilder
    .Select.Column('C.FIRSTNAME').Column('C.LASTNAME').ToString;
  CheckEquals('', LSQL);

  LSQL := FSQLBuilder
    .From('dbo.Customers C')
    .Join('dbo.Details D on D.ID=C.ID').ToString;
  CheckEquals('SELECT C.FIRSTNAME,C.LASTNAME'+ #13#10 + ' FROM dbo.Customers C'+ #13#10 +' JOIN dbo.Details D on D.ID=C.ID', LSQL);

  LSQL := FSQLBuilder
    .Where('C.CUSTNAME = ''Foobar''')
    .Where('D.CUSTORDER = 1')
    .ToString;
  CheckEquals('SELECT C.FIRSTNAME,C.LASTNAME'+ #13#10 + ' FROM dbo.Customers C'+ #13#10 +' JOIN dbo.Details D on D.ID=C.ID'+#13#10+
    ' WHERE (C.CUSTNAME = ''Foobar'') AND (D.CUSTORDER = 1)', LSQL);

  LSQL := FSQLBuilder.Select.Column('SUM(D.CUSTCOUNT)')
    .GroupBy('C.FIRSTNAME')
    .GroupBy('C.LASTNAME')
    .ToString;
  CheckEquals('SELECT C.FIRSTNAME,C.LASTNAME,SUM(D.CUSTCOUNT)'+ #13#10 + ' FROM dbo.Customers C'+ #13#10 +' JOIN dbo.Details D on D.ID=C.ID'+#13#10+
    ' WHERE (C.CUSTNAME = ''Foobar'') AND (D.CUSTORDER = 1)'+ #13#10+
    ' GROUP BY C.FIRSTNAME,C.LASTNAME', LSQL);
  LPreviousSQL := LSQL;

  LSQL := FSQLBuilder.Having('C.LASTNAME <> ''''').ToString;
  CheckEquals(LPreviousSQL + #13#10 + ' HAVING (C.LASTNAME <> '''')', LSQL);
  LPreviousSQL := LSQL;
  LSQL := FSQLBuilder
    .OrderBy('1 ASC')
    .OrderBy('C.LASTNAME').ToString;

  CheckEquals(LPreviousSQL + #13#10 + ' ORDER BY 1 ASC,C.LASTNAME', LSQL);
end;

procedure TSvAnsiSQLBuilderTests.Select_Union;
var
  LSQL: string;
begin
  LSQL := FSQLBuilder
  .Select
    .From('dbo.Customers C')
    .Join('dbo.Details D on D.ID=C.ID')
    .Column('C.FIRSTNAME').Column('C.LASTNAME')
  .Union('SELECT NULL, NULL')
  .ToString;
  CheckEquals('SELECT C.FIRSTNAME,C.LASTNAME'+ #13#10 + ' FROM dbo.Customers C'+ #13#10 +' JOIN dbo.Details D on D.ID=C.ID'+ #13#10 +
    'UNION' + #13#10 +
    'SELECT NULL, NULL', LSQL);
end;

procedure TSvAnsiSQLBuilderTests.SetUp;
begin
  inherited;
  FSQLBuilder := TAnsiSQLBuilder.Create();
end;

procedure TSvAnsiSQLBuilderTests.TearDown;
begin
  inherited;
end;

{ TSvTransactSQLBuilderTests }

procedure TSvTransactSQLBuilderTests.SelectTop;
var
  LSQL: string;
begin
  LSQL := FSQLBuilder
    .Select.Top(100).Column('C.FIRSTNAME').Column('C.LASTNAME').ToString;
  CheckEquals('', LSQL);

  LSQL := FSQLBuilder
    .From('dbo.Customers C')
    .Join('dbo.Details D on D.ID=C.ID').ToString;
  CheckEquals('SELECT TOP 100 C.FIRSTNAME,C.LASTNAME'+ #13#10 + ' FROM dbo.Customers C'+ #13#10 +' JOIN dbo.Details D on D.ID=C.ID', LSQL);
end;

procedure TSvTransactSQLBuilderTests.SetUp;
begin
  inherited;
  FSQLBuilder := TTransactSQLBuilder.Create();
end;

procedure TSvTransactSQLBuilderTests.TearDown;
begin
  inherited;
end;

initialization
  RegisterTest(TSvAnsiSQLBuilderTests.Suite);
  RegisterTest(TSvTransactSQLBuilderTests.Suite);

end.
