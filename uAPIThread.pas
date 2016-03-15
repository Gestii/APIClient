unit uAPIThread;

interface

uses
  System.SysUtils,
  System.Classes,
  IdTCPConnection,
  IdHTTPHeaderInfo,
  IdIOHandler,
  IdBaseComponent,
  Vcl.StdCtrls;

type
  TApiThread = class(TThread)
  protected
    logMemo: TMemo;
    appPath: String;
    apiKey: String;
    url: String;
    function doPost(url: string; params: TStringList): string;
    function getURL(url: String; params: TStringList): String;
    function doGet(url: String; params: TStringList; filename:string = ''): String;
    procedure writeToLog(msg: String);
  public
    constructor Create(logMemo: TMemo; lappPath: String; lapiKey: String;
        lurl: String ); overload;
  end;

implementation

uses
  IdHTTP,
  IdURI,
  IdSSLOpenSSL;

constructor TApiThread.Create(logMemo: TMemo; lappPath, lapiKey, lurl: String);
begin
  inherited Create(true);
  FreeOnTerminate := true;
  self.logMemo := logMemo;
  self.appPath := lappPath;
  self.apiKey := lapiKey;
  self.url := lurl;
end;

function TApiThread.doGet(url: String; params: TStringList; filename:string = ''): String;
var
  http : TIdHTTP;
  sslHandler : TIdSSLIOHandlerSocketOpenSSL;
  response : TStringStream;
  fileData : TStringList;
begin
  sslHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  with sslHandler do begin
    SSLOptions.Method := sslvSSLv3;
    SSLOptions.Mode := sslmUnassigned;
    SSLOptions.VerifyMode := [];
    SSLOptions.VerifyDepth := 0;
    host := '';
  end;

  Result := '';
  http := TIdHTTP.Create(nil);
  http.HandleRedirects := true;
  http.Request.ContentType := 'application/x-www-form-urlencoded';
  http.IOHandler := sslHandler;
  response := TStringStream.Create;
  try
    http.Get(TIdURI.URLEncode(getURL(url, params)), response);
    if filename <> '' then begin
      response.SaveToFile(filename);
    end;
    Result := response.DataString;
  finally
    response.Free;
    sslHandler.Free;
    http.Free;
  end;
end;

function TApiThread.doPost(url: string; params: TStringList): string;
var
  http: TIdHTTP;
  sslHandler: TIdSSLIOHandlerSocketOpenSSL;
  response: TStringStream;
  fileData: TStringList;
begin
  sslHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  with sslHandler do
  begin
    SSLOptions.Method := sslvSSLv3;
    SSLOptions.Mode := sslmUnassigned;
    SSLOptions.VerifyMode := [];
    SSLOptions.VerifyDepth := 0;
    host := '';
  end;
  Result := '';
  http := TIdHTTP.Create(nil);
  http.Request.ContentType := 'application/x-www-form-urlencoded';
  http.IOHandler := sslHandler;
  response := TStringStream.Create;
  try
    http.Post(TIdURI.URLEncode(url), params, response);
    Result := response.DataString;
  except
    on e: EIdHTTPProtocolException do
    begin
      Result := e.ErrorMessage;
    end;
  end;
  response.Free;
end;

function TApiThread.getURL(url: String; params: TStringList): String;
var
  i: Integer;
begin
  Result := url + '?';
  for i := 0 to params.Count - 1 do begin
    Result := Result + params[i] + '&';
  end;
end;

procedure TApiThread.writeToLog(msg: String);
begin
  if (Assigned(LogMemo)) then begin
    Synchronize(procedure begin logMemo.Lines.Append(formatDateTime('yyyy/mm/dd hh:nn ',now)+ msg) end);
  end;
end;

end.
