unit uReportThread;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.StdCtrls,
  Generics.Collections,
  StrUtils,
  uAPIThread,
  superobject;

type
  TReportThread = class(TApiThread)
    private
      filecache : TstringList;
      function getTasks: ISuperObject;
      function downloadReport(task:ISuperObject):boolean;
      procedure addToCache(id:string);
    protected
      procedure Execute; override;
    public
      destructor Destroy; override;
      constructor Create(logMemo: TMemo; appPath: String; apiKey: String;
        url: String ); overload;
      procedure iniciar();
    end;

implementation


uses IOUtils;

{ UReportdThread }

procedure TReportThread.addToCache(id: string);
begin
  filecache.Add(id);
  if filecache.Count > 1000 then begin
    fileCache.Delete(0);
  end;
  fileCache.SaveToFile(apppath+'file.cache');
end;

constructor TReportThread.Create(logMemo: TMemo; appPath, apiKey, url: String);
begin
  inherited Create(logMemo,appPath,apiKey,url);
  ForceDirectories(appPath + 'reportes\');
  filecache := TstringList.Create;
  fileCache.Duplicates := dupIgnore;
  fileCache.Sorted := true;
  if TFile.exists(apppath+'file.cache') then begin
    fileCache.LoadFromFile(apppath+'file.cache');
  end;
end;

destructor TReportThread.Destroy;
begin
  fileCache.SaveToFile(apppath+'file.cache');
  fileCache.Free;
  inherited;
end;

function TReportThread.downloadReport(task: ISuperObject): boolean;
var
  params : TStringList;
  response: string;
  fileNameResult: string;
  fileName: string;
  fileResult: TStringList;
  reporturl: string;
begin
  Result := true;
  reporturl := url + '/api/v1/cdn/reports/'+task['id'].AsString;
  fileNameResult := appPath + 'reportes\'+TASK['caption'].asString;
  params := TStringList.Create;
  fileResult := TStringList.Create;
  try
    ForceDirectories(ExtractFilePath(fileNameResult));
    params.Append('apikey=' + apiKey);
    doGet(reporturl, params,fileNameResult);
  except
    on e : Exception do begin
      writeToLog(reporturl+' '+e.Message);
      result := false;
    end;
  end;
  params.Free;
  fileResult.Free;
end;

procedure TReportThread.Execute;
var
  tasks: ISuperObject;
  task: ISuperObject;
  index: Integer;
begin
  {$IFDEF DEBUG }
    sleeptime := 10000;
  {$ELSE}
    sleeptime := 300000;
  {$ENDIF}

  while not terminated do begin
    tasks := getTasks;
    for task in tasks do begin
      if (task.IsType(stObject))
        and (task['status'].AsInteger = 3)
        and (task['type'].AsString = 'report')
        and (not filecache.Find(task['id'].AsString,index))
        and downloadReport(Task) then begin
          writeToLog('Se descargó el reporte: '+Task['caption'].AsString);
          addtoCache(task['id'].AsString);
      end;
    end;
    doSleep;
  end;
end;

function TReportThread.getTasks: ISuperObject;
var
  taskurl : String;
  params: TStringList;
  d: string;
  response: string;
begin
  d:=formatDateTime('yymmdd',now()+1);
  taskurl := url + '/api/v1/tasks/';
  params := TStringList.Create;
  try
    params.Append('apikey=' + apiKey);
    params.Append('created_at='+d+'000000-5d');
    params.Append('limit=100');
    try
      response := doGet(taskurl, params);
      result := loadJson(response);
    except
      on e : Exception do begin
        response := '{"status_code":-4,"msg":"'+e.Message+'"}';
      end;
    end;
  finally
    params.Free;
  end;            
end;

procedure TReportThread.iniciar();
begin
  resume;
end;

end.
