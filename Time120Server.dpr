program Time120Server;

uses
  Vcl.Forms,
  Server in 'Server.pas' {FormServer},
  SoccerBrainv3 in 'SoccerBrainv3.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormServer, FormServer);
  Application.Run;
end.
