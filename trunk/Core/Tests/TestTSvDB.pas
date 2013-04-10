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
  LSQL := FSQLBuilder
    .OrderBy('1 ASC')
    .OrderBy('C.LASTNAME').ToString;

  CheckEquals(LPreviousSQL + #13#10 + ' ORDER BY 1 ASC,C.LASTNAME', LSQL);
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

initialization
  RegisterTest(TSvAnsiSQLBuilderTests.Suite);

end.
