program Time120Server;

uses
  EMemLeaks,
  EResLeaks,
  EDialogWinAPIMSClassic,
  EDialogWinAPIEurekaLogDetailed,
  EDialogWinAPIStepsToReproduce,
  EDebugExports,
  EFixSafeCallException,
  EMapWin32,
  EAppVCL,
  ExceptionLog7,
  Vcl.Forms,
  Server in 'Server.pas' {FormServer},
  SoccerBrainv3 in 'SoccerBrainv3.pas',
  utilities in 'utilities.pas',
  SoccerAIv3 in 'SoccerAIv3.pas',
  SoccerTypes in 'SoccerTypes.pas',
  validate in 'validate.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormServer, FormServer);
  Application.Run;
end.
