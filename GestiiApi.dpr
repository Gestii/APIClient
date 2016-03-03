program GestiiApi;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {Form2},
  uUploadThread in 'uUploadThread.pas',
  uAPIThread in 'uAPIThread.pas',
  uReportThread in 'uReportThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
