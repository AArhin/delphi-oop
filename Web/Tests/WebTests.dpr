program WebTests;


{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  SvTesting.DUnit,
  RESTClientTest in 'RESTClientTest.pas',
  SvREST.Client in '..\SvREST.Client.pas',
  SvHTTPClientInterface in '..\SvHTTPClientInterface.pas',
  SvHTTPClient.Factory in '..\SvHTTPClient.Factory.pas',
  SvHTTP.Attributes in '..\SvHTTP.Attributes.pas',
  SvREST.Method in '..\SvREST.Method.pas',
  SvWeb.Consts in '..\SvWeb.Consts.pas',
  SvHTTPClient.Mock in '..\SvHTTPClient.Mock.pas',
  SvHTTPClient.Indy in '..\SvHTTPClient.Indy.pas',
  RESTClientIntegrationTest in 'RESTClientIntegrationTest.pas';

{$R *.RES}

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := True;
  if IsConsole then
    with TextTestRunner.RunRegisteredTests do
      Free
  else
    TSvGUITestRunner.RunRegisteredTests;

end.

