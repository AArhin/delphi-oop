program SvSerializerTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  TestSvSerializerJson in 'TestSvSerializerJson.pas',
  SvSerializerJson in '..\SvSerializerJson.pas',
  SvSerializer in '..\SvSerializer.pas',
  SQLite3 in 'SQLite3.pas',
  SQLiteTable3 in 'SQLiteTable3.pas',
  SvSerializer.Extensions.SQLite in '..\SvSerializer.Extensions.SQLite.pas',
  SvSerializerXML in '..\SvSerializerXML.pas';

{$R *.RES}

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := True;
  if IsConsole then
    with TextTestRunner.RunRegisteredTests do
      Free
  else
    GUITestRunner.RunRegisteredTests;
end.

