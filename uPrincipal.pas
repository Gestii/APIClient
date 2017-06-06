unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdHTTP, IdURI, IdSSLOpenSSL, superobject, Generics.Collections,
  Vcl.ExtCtrls, iniFiles, uUploadThread,uReportThread;

type
  TForm2 = class(TForm)
    Timer1: TTimer;
    Memo1: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
  private
    tUpload : UploadThread;
    tReport : TreportThread;
    closeApp : boolean;
    statusCodes : TDictionary<integer, string>;
    { Private declarations }
    function getCodeDescription(code : integer) : String;
    function getURL(url : String; params : TStringList) : String;
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Memo1.Lines.Add('Terminando ejecucion de hilos');
  tUpload.Terminate;
  tReport.Terminate;
  sleep(2000);
end;

function TForm2.getCodeDescription(code: integer): String;
begin
  if (statusCodes.ContainsKey(code)) then begin
    Result := statusCodes.Items[code];
  end else begin
    Result := 'Error desconocido: '+IntToStr(code);
  end;
end;

function TForm2.getURL(url: String; params: TStringList): String;
var
  i: Integer;
begin
  Result := url + '?';
  for i := 0 to params.Count - 1 do begin
    Result := Result + params[i];
  end;
end;


procedure TForm2.Timer1Timer(Sender: TObject);
var
  appPath : String;
  apiKey : String;
  url : String;
  layoutId : String;
  iniFile : TIniFile;
  sleepTime: Integer;
begin
  Timer1.Enabled := false;

  iniFile := TIniFile.Create(ExtractFilePath(Application.ExeName)+'api_config.ini');
  try
    apiKey := iniFile.ReadString('API', 'apikey', '');
    layoutId := iniFile.ReadString('API', 'layout', 'default');
    url := iniFile.ReadString('API', 'url', 'https://agencia.gestii.com');
    sleepTime := iniFile.ReadInteger('API', 'sleepTime', 1000);

    iniFile.WriteString('API', 'apikey', apiKey);
    iniFile.WriteString('API', 'layout', layoutId);
    iniFile.WriteString('API', 'url', url);
    iniFile.WriteInteger('API', 'sleepTime', sleepTime);
  finally
    iniFile.Free;
  end;
  tUpload := UploadThread.Create(Memo1,ExtractFilePath(Application.ExeName),apiKey, url );
  tUpload.iniciar(layoutId,sleepTime);

  tReport := TReportThread.Create(Memo1,ExtractFilePath(Application.ExeName),apiKey, url);
  tReport.iniciar();

end;

end.
