program SvCoreTests;
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



{$R *.dres}

uses
  Forms,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  TestSvThreading in 'TestSvThreading.pas',
  SvThreading in '..\SvThreading.pas',
  TestSvDesignPatterns in 'TestSvDesignPatterns.pas',
  SvDesignPatterns in '..\SvDesignPatterns.pas',
  SvHelpers in '..\SvHelpers.pas',
  TestSvHelpers in 'TestSvHelpers.pas',
  SvClasses in '..\SvClasses.pas',
  TestSvClasses in 'TestSvClasses.pas',
  SvRttiUtils in '..\SvRttiUtils.pas',
  SvContainers in '..\SvContainers.pas',
  TestSvContainers in 'TestSvContainers.pas',
  SvCollections.Tries in '..\SvCollections.Tries.pas',
  TestSvEvents in 'TestSvEvents.pas',
  SvDelegates in '..\SvDelegates.pas',
  SvTesting.DUnit in '..\SvTesting.DUnit.pas',
  TestSvRttiUtils in 'TestSvRttiUtils.pas',
  TestSvTesting in 'TestSvTesting.pas',
  SvLogging in '..\SvLogging.pas',
  SvLogging.Log4D in '..\SvLogging.Log4D.pas',
  SvLogging.Log4D.Appenders in '..\SvLogging.Log4D.Appenders.pas',
  TestSvLoggingLog4D in 'TestSvLoggingLog4D.pas';

{$R *.RES}

begin
  Application.Initialize;
  {$WARNINGS OFF}
  ReportMemoryLeaksOnShutdown := True;
  {$WARNINGS ON}
  if IsConsole then
    with TextTestRunner.RunRegisteredTests do
      Free
  else
    TSvGUITestRunner.RunRegisteredTests;
   // GUITestRunner.RunRegisteredTests;
end.

