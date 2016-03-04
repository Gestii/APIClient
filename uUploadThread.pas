unit uUploadThread;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.StdCtrls,
  Generics.Collections,
  StrUtils,
  uAPIThread;

type
  UploadThread = class(TApiThread)
    private
      statusCodes: TDictionary<integer, string>;

      appPath: String;
      apiKey: String;
      url: String;
      layoutId: String;

      function getCodeDescription(code: integer): String;

      function doCompleteProcess(url: String; apiKey: String; fileName: String;
        layoutId: String): boolean;
      function uploadFile(url: String; apiKey: String; fileName: String;
        layoutId: String): String;
      function checkUploadStatus(url: String; apiKey: String;
        uploadId: integer): String;
      function downloadErrors(url: String; apiKey: String;
        uploadId: integer;filename:string): String;
    protected
      procedure Execute; override;
    public
      destructor Destroy; override;
      constructor Create(logMemo: TMemo; appPath: String; apiKey: String;
        url: String ); overload;
      procedure iniciar(layoutId: String);
    end;

  implementation

uses
  superobject;

{ UploadThread }

function UploadThread.checkUploadStatus(url, apiKey: String;
  uploadId: integer): String;
var
  params : TStringList;
begin
  Result := 'Unknow error';
  url := url + '/api/v1/tasks/'+IntToStr(uploadId);
  params := TStringList.Create;
  params.Append('apikey=' + apiKey);
  try
    Result := doGet(url, params);
  except
    on e : Exception do begin
      Result := '{"status_code":-3,"msg":"'+e.Message+'"}';
    end;
  end;
  params.Free;
end;

constructor UploadThread.Create(logMemo: TMemo; appPath, apiKey, url: String);
begin
  inherited Create(logMemo,appPath,apiKey,url);
  statusCodes := TDictionary<integer,String>.Create;
  statusCodes.Add(0, 'En cola de procesamiento.');
  statusCodes.Add(1, 'Validando el archivo importado.');
  statusCodes.Add(2, 'Procesando el archivo importado.');
  statusCodes.Add(3, 'Importación realizada con éxito.');
  statusCodes.Add(105, 'El archivo importado está vacío.');
  statusCodes.Add(110, 'Se encontraron encabezados duplicados en el archivo.');
  statusCodes.Add(111, 'Se ha encontrado un encabezado vacío.');
  statusCodes.Add(120, 'Falta la columna "Folio".');
  statusCodes.Add(121, 'Falta la columna "Calle".');
  statusCodes.Add(122, 'Falta la columna "Colonia".');
  statusCodes.Add(123, 'Falta la columna "CP".');
  statusCodes.Add(124, 'Falta la columna "Municipio".');
  statusCodes.Add(125, 'Falta la columna "Estado".');
  statusCodes.Add(200, 'Errores múltiples. Archivo de errores descargado.');
  statusCodes.Add(422, 'Error desconocido.');
end;


destructor UploadThread.Destroy;
begin
  statusCodes.Free;
  inherited;
end;

function UploadThread.doCompleteProcess(url, apiKey, fileName: String;
  layoutId: String): boolean;
var
  resultString : String;
  json : ISuperObject;
  uploadId : integer;
  status : integer;
  responseCode : integer;
  i: Integer;
  currentStatus : integer;
  fileResult : TStringList;
  fileNameResult : String;
begin
  resultString := uploadFile(url, apikey, filename, layoutId);
  json := SO(resultString);
  //if (not resultString.StartsWith('{')) then begin
  if not AnsiStartsStr('{', resultString) then begin
    responseCode := 422;
  end else if (Assigned(json.O['status_code'])) then begin
    responseCode := json.AsObject.I['status_code'];
  end else begin
    responseCode := 200;
  end;
  if (responseCode >= 200) and (responseCode < 300) then begin
    uploadId := json.AsObject.I['id'];
    status := json.AsObject.I['status'];
    writeToLog('Procesando Archivo: '+IntToStr(uploadId));
    currentStatus := -1;
    for i := 0 to 999 do begin
      Sleep(3000);
      resultString := checkUploadStatus(url, apikey, uploadId);
      json := SO(resultString);
      status := json.AsObject.I['status'];
      if (status <> currentStatus) then begin
        writeToLog(getCodeDescription(status));
        currentStatus := status;
      end;
      if (status > 2) then begin
        break;
      end;
    end;
    if (status = 3) then begin
      fileNameResult := appPath + 'correctos\';
      ForceDirectories(fileNameResult);
      fileNameResult := fileNameResult + ExtractFileName(fileName);
      CopyFile(PChar(fileName), PChar(fileNameResult), False);
      System.SysUtils.DeleteFile(fileName);
      writeToLog('Archivo procesado correctamente');
    end else begin
      fileNameResult := appPath + 'errores\';
      ForceDirectories(fileNameResult);
      CopyFile(PChar(fileName), PChar(fileNameResult + ExtractFileName(fileName)), False);
      System.SysUtils.DeleteFile(fileName);
      if (status = 200) then begin
        downloadErrors(url, apikey, uploadId, fileNameResult  + 'errores_' + ExtractFileName(fileName));
      end;
    end;
  end else begin
    if (Assigned(json.O['msg'])) then begin
      writeToLog(json.AsObject.S['msg']);
    end else begin
      writeToLog(resultString);
    end;
    fileNameResult := appPath + 'errores\';
    ForceDirectories(fileNameResult);
    fileNameResult := fileNameResult + ExtractFileName(fileName);
    CopyFile(PChar(fileName), PChar(fileNameResult), False);
    System.SysUtils.DeleteFile(fileName);
  end;
end;



function UploadThread.downloadErrors(url, apiKey: String;
  uploadId: integer; filename:string): String;
var
  params : TStringList;
begin
  Result := '';
  url := url + '/api/v1/cdn/uploads/'+IntToStr(uploadId);
  params := TStringList.Create;
  params.Append('apikey=' + apiKey);
  try
    Result := doGet(url, params,filename);
  except
    on e : Exception do begin
      Result := '{"status_code":-4,"msg":"'+e.Message+'"}';
    end;
  end;
  params.Free;
end;

procedure UploadThread.Execute;
var
  fileName : String;
  searchResult : TSearchRec;
  fileExt : String;
begin
  while not terminated do begin
    if FindFirst('*.*', faAnyFile, searchResult) = 0 then begin
      repeat
        fileExt := ExtractFileExt(searchResult.Name);
        if ((fileExt = '.csv') or (fileExt = '.zip')) then begin
          fileName := appPath + searchResult.Name;
          writeToLog('Archivo encontrado: '+ExtractFileName(fileName));
          doCompleteProcess(url, apiKey, fileName, layoutId);
          writeToLog('Terminado: '+ExtractFileName(fileName));
        end;
      until FindNext(searchResult) <> 0;
      FindClose(searchResult);
    end;
    Sleep(1000);
  end;
end;

function UploadThread.getCodeDescription(code: integer): String;
begin
  if (statusCodes.ContainsKey(code)) then begin
    Result := statusCodes.Items[code];
  end else begin
    Result := 'Error desconocido: '+IntToStr(code);
  end;
end;

procedure UploadThread.iniciar(layoutId: String);
begin
  self.layoutId := layoutId;
  resume;
end;

function UploadThread.uploadFile(url, apiKey, fileName: String;
  layoutId: String): String;
var
  params : TStringList;
  fileData : TStringList;
begin
  Result := '';
  url := url + '/api/v1/tasks/uploads';
  params := TStringList.Create;
  params.Append('apikey=' + apiKey);
  params.Append('layout=' + layoutId);
  try
    if (FileExists(fileName)) then begin
      fileData := TStringList.Create;
      fileData.LoadFromFile(fileName);
      if (trim(fileData.Text) <> '') then begin
        params.Append('file=' + fileData.Text);
        fileData.Free;
        Result := doPost(url, params);
      end else begin
        Result := '{"status_code":105,"msg":"Archivo vacío"}';
      end;
    end else begin
      Result := '{"status_code":-1,"msg":"El archivo no existe"}';
    end;
  except
    on e : Exception do begin
      Result := '{"status_code":-2,"msg":"'+e.Message+'"}';
    end;
  end;
  params.Free;
end;


end.
