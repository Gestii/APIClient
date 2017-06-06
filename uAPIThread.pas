unit uAPIThread;

interface

uses
  System.SysUtils,
  System.Classes,
  IdTCPConnection,
  IdHTTPHeaderInfo,
  IdIOHandler,
  IdBaseComponent,
  Vcl.StdCtrls,
  superobject;

type
  TApiThread = class(TThread)
  protected
    sleepTime: integer;
    logMemo: TMemo;
    appPath: String;
    apiKey: String;
    url: String;
    function doPost(url: string; params: TStringList): string;
    function getURL(url: String; params: TStringList): String;
    function doGet(url: String; params: TStringList; filename:string = ''): String;
    function loadJson(text: string): ISuperObject;
    procedure writeToLog(msg: String);
    procedure doSleep;
  public
    constructor Create(logMemo: TMemo; lappPath: String; lapiKey: String; lurl: String); overload;
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
    try
      http.Get(TIdURI.URLEncode(getURL(url, params)), response);
    Except
      on E: EIdHTTPProtocolException do
      begin
        if E.ErrorCode = 429 then begin
          sleep(30000);
          http.Get(TIdURI.URLEncode(getURL(url, params)), response);
        end else if E.ErrorCode = 404 then begin
          response.Clear;
        end else begin
          raise
        end;
      end;

    end;
    if (filename <> '') and (response.Size > 0) then begin
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
  http := TIdHTTP.Create(nil);
  response := TStringStream.Create;
  try
    with sslHandler do
    begin
      SSLOptions.Method := sslvSSLv3;
      SSLOptions.Mode := sslmUnassigned;
      SSLOptions.VerifyMode := [];
      SSLOptions.VerifyDepth := 0;
      host := '';
    end;
    Result := '';

    http.Request.ContentType := 'application/x-www-form-urlencoded';
    http.IOHandler := sslHandler;
    try
      http.Post(TIdURI.URLEncode(url), params, response);
      Result := response.DataString;
    except
      on e: EIdHTTPProtocolException do
      begin
        Result := e.ErrorMessage;
      end;
    end;
  finally
    response.Free;
    sslHandler.Free;
    http.Free;
  end;
end;

procedure TApiThread.doSleep;
var
  delta: integer;
  i: Integer;
begin
  delta := sleeptime div 100;
  for i := 0 to 99 do begin
    sleep(delta);
    if terminated then begin
      break;
    end;
  end;

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

function TApiThread.loadJson(text:string):ISuperObject;
begin
  if text = '' then begin
    text := '{}';
  end;

  result := SO(text);

  if not assigned(result) then begin
    raise Exception.Create('Invalid JSON');
  end;


end;

end.
