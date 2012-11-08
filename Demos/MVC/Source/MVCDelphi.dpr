// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
program MVCDelphi;

uses
  Forms,
  ViewMain in 'Views\ViewMain.pas' {frmMain},
  Model.User in 'Models\Model.User.pas',
  Controller.Main in 'Controllers\Controller.Main.pas',
  ViewSecondary in 'Views\ViewSecondary.pas' {frmSecondary};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  CreateMainController(TUser.Create('MVC Demo', 'mvc@gmail.com '));
  ReportMemoryLeaksOnShutdown := True;
  Application.Run;
end.
