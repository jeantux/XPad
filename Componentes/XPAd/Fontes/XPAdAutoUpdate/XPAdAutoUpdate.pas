unit XPAdAutoUpdate;

interface

uses
  System.Classes, System.SysUtils, System.StrUtils, System.Math, XPAdMethods,
  Messages, XPADBase, Vcl.ExtCtrls, IdHTTP, idFTP, XPAdAutoUpdatePersistent,
  XPAdAutoUpdateMessages, IdFTPCommon, IdException, System.Zip, IdComponent;

type
  TMethodDownload = (mdFTP, mdHTTP);
  TEngineUpdate = (eaScript, eaExternal);
  TMethodVersion = (mvManually, mvINI, mvAPI);

  XPAdMetError            = procedure(Sender: TObject; NumErro: Integer; MsgErro: String) of object;
  XPAdMetFound            = procedure(Sender: TObject; Version: Integer; Size: Integer) of object;

  XPAdMetBeforeDecompress = procedure(Sender: TObject; Files: Integer) of object;
  XPAdMetAfterDecompress  = procedure(Sender: TObject; Files: Integer; FileName: String) of object;

  XPAdMetBeforeUpdate     = procedure(Sender: TObject) of object;
  XPAdMetAfterUpdate      = procedure(Sender: TObject) of object;

  XPAdMetBeforeDownload   = procedure(Sender: TObject; VesionLocal, VersionFTP: Integer) of object;
  XPAdMetAfterDownload    = procedure(Sender: TObject; const Downloaded: Boolean) of object;

  XPAdMetWork             = procedure(Sender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64) of object;

  TXPAdThread = class(TThread)
  private
    FHTTP: TIdHTTP;
    FFTP: TIdFTP;
    FRemoteDir: String;
    FDirDownload: String;
    FOwner: TComponent;
  protected
    procedure Terminate;
    procedure Execute; override;
    procedure DoDownloadFTP;
    procedure DoDownloadHTTP;
    procedure Download(Method: TMethodDownload);
  public
    constructor Create(AOwner: TComponent);
  end;

  TXPAdAutoUpdate = class(TXPAdBase)
  private
    FTimeSearch: Integer;
    FBackup: Boolean;
    FShowErrors: Boolean;
    FMethodDownload: TMethodDownload;
    FDirDownload: String;
    FShowMsgs: Boolean;
    FSizeArchiveFTP: Integer;

    FTimer: TTimer;
    FHTTP: TIdHTTP;
    FFTP: TIdFTP;
    FThread: TXPAdThread;

    FError: XPAdMetError;
    FFound: XPAdMetFound;

    FBeforeDecompress: XPAdMetBeforeDecompress;
    FAfterDecompress: XPAdMetAfterDecompress;

    FBeforeDownload: XPAdMetBeforeDownload;
    FAfterDownload: XPAdMetAfterDownload;

    FBeforeUpdate: XPAdMetBeforeUpdate;
    FAfterUpdate: XPAdMetAfterUpdate;
    FConf: TXPAdConf;
    FDirBackupFile: String;
    FAutoSearchUpdate: Boolean;
    FMethodVersion: TMethodVersion;
    FLocalVersion: Integer;
    FRemoteVersion: Integer;
    FWork: XPAdMetWork;

    procedure Timer(Sender: TObject);
    procedure setConf(const Value: TXPAdConf);
    procedure Decompress;
    procedure SearchUpdate;
    procedure ConfigureConnection;
    procedure setTimeSearch(const Value: Integer);
    procedure AlterLocalVersion;
    procedure setAutoSearchUpdate(Value: Boolean);
    procedure Validate();
    function ConnectFTPServer: Boolean;
    function getApplicationName: string;
    function getDirExe: string;
  protected
    { Protected declarations }
  public
    CurrentBytes: Int64;
    TotalBytes: Int64;
    FileOut: String;
    function getLocalVersion: smallint;
    function getRemoteVersion: smallint;
    procedure Upgrade();
    procedure Cancel;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
  published
    property Config: TXPAdConf read FConf write setConf;
    property MethodDownload: TMethodDownload read FMethodDownload write FMethodDownload default mdHTTP;
    property ShowMsgs: Boolean read FShowMsgs write FShowMsgs default true;
    property ShowErrors: Boolean read FShowErrors write FShowErrors default true;
    property Backup: Boolean read FBackup write FBackup Default true;
    property DirBackupFile: String read FDirBackupFile write FDirBackupFile;
    property DirDownload: String read FDirDownload write FDirDownload;
    property TimeSearch: Integer read FTimeSearch write setTimeSearch;
    property AutoSearchUpdate: Boolean read FAutoSearchUpdate write setAutoSearchUpdate;
    property MethodVersion: TMethodVersion read FMethodVersion write FMethodVersion default mvManually;
    property LocalVersion: Integer read FLocalVersion write FLocalVersion;
    property RemoteVersion: Integer read FRemoteVersion write FRemoteVersion;

    property OnError: XPAdMetError read FError write FError;
    property OnFound: XPAdMetFound read FFound write FFound;
    property OnBeforeDecompress: XPAdMetBeforeDecompress read FBeforeDecompress write FBeforeDecompress;
    property OnAfterDecompress: XPAdMetAfterDecompress read FAfterDecompress write FAfterDecompress;
    property OnBeforeDownload: XPAdMetBeforeDownload read FBeforeDownload write FBeforeDownload;

    property OnAfterDownload: XPAdMetAfterDownload read FAfterDownload write FAfterDownload;
    property OnBeforeUpdate: XPAdMetBeforeUpdate read FBeforeUpdate write FBeforeUpdate;
    property OnAfterUpdate: XPAdMetAfterUpdate read FAfterUpdate write FAfterUpdate;
    property OnWork: XPAdMetWork read FWork write FWork;
  end;

procedure Register;

implementation

uses
  Vcl.Forms, Vcl.Dialogs, Winapi.Windows,
  System.IniFiles;

procedure Register;
begin
  RegisterComponents('XPAd', [TXPAdAutoUpdate]);
end;

{ TXPAdThread }

constructor TXPAdThread.Create(AOwner: TComponent);
begin
  inherited Create(true);
  FreeOnTerminate := true;
  FOwner := AOwner;
  FFTP := TXPAdAutoUpdate(FOwner).FFTP;
  FHTTP := TXPAdAutoUpdate(FOwner).FHTTP;
  FRemoteDir := TXPAdAutoUpdate(FOwner).FConf.FTP.Dir;
  FDirDownload := TXPAdAutoUpdate(FOwner).FDirDownload;
  Resume;
end;

procedure TXPAdThread.DoDownloadFTP;
var
  ZipFileName: string;
begin
  ZipFileName := TXPAdAutoUpdate(FOwner).FConf.FTP.ZipFileName;

  if FileExists(TXPAdAutoUpdate(FOwner).getDirExe + ZipFileName) then
    DeleteFile(PWideChar(TXPAdAutoUpdate(FOwner).getDirExe + ZipFileName));

  TXPAdAutoUpdate(FOwner).FSizeArchiveFTP := FFTP.Size(TXPAdAutoUpdate(FOwner).FConf.FTP.Dir + ZipFileName);

  if (Assigned(TXPAdAutoUpdate(FOwner).FWork)) then
    FFTP.OnWork := TXPAdAutoUpdate(FOwner).FWork;

  FFTP.Get(TXPAdAutoUpdate(FOwner).FConf.FTP.Dir + ZipFileName,
    TXPAdAutoUpdate(FOwner).getDirExe + ZipFileName, true, true);
end;

procedure TXPAdThread.DoDownloadHTTP;
var
  myFile: TFileStream;
begin
  myFile := TFileStream.Create(TXPAdAutoUpdate(FOwner).FConf.FTP.Dir +
    TXPAdAutoUpdate(FOwner).FConf.FTP.ZipFileName, fmCreate);

  FHTTP.Get(TXPAdAutoUpdate(FOwner).FConf.HTTP.Server + ':' +
    TXPAdAutoUpdate(FOwner).FConf.HTTP.Port.ToString, myFile);
end;

procedure TXPAdThread.Download(Method: TMethodDownload);
var
  nNumLocalVersion, nNumFTPVersion: smallint;
begin
  nNumLocalVersion := TXPAdAutoUpdate(FOwner).getLocalVersion;
  nNumFTPVersion := TXPAdAutoUpdate(FOwner).getRemoteVersion;

  if (nNumLocalVersion < nNumFTPVersion) then
  begin
    if Assigned(TXPAdAutoUpdate(FOwner).FBeforeDownload) then
      TXPAdAutoUpdate(FOwner).FBeforeDownload(FOwner, TXPAdAutoUpdate(FOwner).getLocalVersion, TXPAdAutoUpdate(FOwner).getRemoteVersion);

    try
      case Method of
        mdFTP: DoDownloadFTP;
        mdHTTP: DoDownloadHTTP;
      end;

    if Assigned(TXPAdAutoUpdate(FOwner).FAfterDownload) then
      TXPAdAutoUpdate(FOwner).FAfterDownload(FOwner, true);
    except
      On E: Exception do
      begin
        if E is EIdConnClosedGracefully then
          Exit;

        raise Exception.Create(MErro_Upgrade_Fail + E.Message);

        if Assigned(TXPAdAutoUpdate(FOwner).FAfterDownload) then
          TXPAdAutoUpdate(FOwner).FAfterDownload(FOwner, false);

        if (TXPAdAutoUpdate(FOwner).FShowErrors) then
          ShowMessage(MErro_Upgrade_Fail + E.Message);

        Abort;
      end;
    end;

    TXPAdAutoUpdate(FOwner).Decompress;
    TXPAdAutoUpdate(FOwner).AlterLocalVersion;

    if(TXPAdAutoUpdate(FOwner).FShowMsgs)then
      ShowMessage(MInf_Complete);
  end
  else
  begin
    if(TXPAdAutoUpdate(FOwner).FShowMsgs)then
      ShowMessage(MInf_Updated);
  end;

  if(Assigned(TXPAdAutoUpdate(FOwner).FAfterUpdate))then
    TXPAdAutoUpdate(FOwner).FAfterUpdate(Self);
end;

procedure TXPAdThread.Execute;
begin
  Download(mdFTP);
  inherited;
end;

procedure TXPAdThread.Terminate;
begin
  inherited;
end;

{ TXPAdAutoUpdate }

function TXPAdAutoUpdate.getDirExe: string;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

function TXPAdAutoUpdate.getApplicationName: string;
begin
  Result := ExtractFileName(Application.ExeName);
end;

constructor TXPAdAutoUpdate.Create(AOwner: TComponent);
begin
  inherited;
  FConf := TXPAdConf.Create(AOwner);
  FMethodDownload := mdFTP;
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  FTimer.OnTimer := Timer;
  FSizeArchiveFTP := 0;
end;

destructor TXPAdAutoUpdate.Destroy;
begin
  FConf.Free;
  FTimer.Free;
  inherited;
end;

procedure TXPAdAutoUpdate.Cancel;
begin
  if (FTimer <> nil) then
    FTimer.Enabled := False;

  if (FThread <> nil) then
  begin
    FThread.Terminate;
    FThread.Destroy;
  end;
end;

procedure TXPAdAutoUpdate.ConfigureConnection();
begin
  if (FMethodDownload = mdFTP) then
  begin
    if (FConf.FTP <> nil) then
    begin
      FFTP.Username     := FConf.FTP.User;
      FFTP.Password     := FConf.FTP.Password;
      FFTP.Host         := FConf.FTP.Server;
      FFTP.Port         := FConf.FTP.Port;
      FFTP.Passive      := FConf.FTP.PassiveMode;
      FFTP.TransferType := TUtils.IIF<TIdFTPTransferType>(FConf.FTP.BinaryMode, ftBinary, ftASCII);
    end;
  end
  else if (FMethodDownload = mdHTTP) then
  begin
    if (FConf.FTP <> nil) then
    begin
      // Implementado no momento do request
    end;
  end;

end;

function TXPAdAutoUpdate.ConnectFTPServer: Boolean;
begin
  if (FFTP.Connected) then
    FFTP.Disconnect;

  try
    FFTP.Connect;
    FTimer.Enabled := False;
    Result := true;
  except
    On E: Exception do
    begin
      raise Exception.Create(MErro_CFG_ServerNotFound + E.Message);
      ShowMessage(MErro_Upgrade_Fail + E.Message);

      FTimer.Enabled := False;
      Result := False;
    end;
  end;
end;

procedure TXPAdAutoUpdate.Decompress;
var
  UnZipper: TZipFile;
  sZIPName: string;
  sNameEXE: string;
begin
  sNameEXE := ReplaceStr(getApplicationName, '.exe', '');

  if(Backup)then
  begin
    if (not(DirectoryExists(DirBackupFile))) then
      ForceDirectories(DirBackupFile);

    if FileExists(PWideChar(DirBackupFile + sNameEXE + '_BK.exe')) then
      DeleteFile(PWideChar(DirBackupFile + sNameEXE + '_BK.exe'));
  end;

  RenameFile(getDirExe + sNameEXE + '.exe', FDirBackupFile+sNameEXE+'_BK.exe');
  sZIPName := getDirExe + FConf.FTP.ZipFileName;


  if Assigned(FBeforeDecompress) then
    FBeforeDecompress(Self, UnZipper.FileCount);

  UnZipper := TZipFile.Create();
  try
    UnZipper.Open(sZIPName, zmRead);
    UnZipper.ExtractAll(getDirExe);
    UnZipper.Close;

    if Assigned(FAfterDecompress) then
      FAfterDecompress(Self, UnZipper.FileCount, FConf.FTP.ZipFileName);
  finally
    FreeAndNil(UnZipper);
  end;
end;

procedure TXPAdAutoUpdate.setAutoSearchUpdate(Value: Boolean);
begin
  FTimer.Interval := FTimeSearch;
  FTimer.Enabled := Value;
end;

procedure TXPAdAutoUpdate.SearchUpdate;
var
  nNumLocalVersion, nNumFTPVersion: Integer;
begin
  try
    Validate();

    if (FFTP = nil) then
      FFTP := TIdFTP.Create;

    ConfigureConnection;

    if not ConnectFTPServer then
      Exit;

    nNumLocalVersion := getLocalVersion;
    nNumFTPVersion := getRemoteVersion;

    if (nNumLocalVersion < nNumFTPVersion) then
    begin
      if Assigned(FFound) then
        FFound(Self, nNumFTPVersion, FSizeArchiveFTP);
    end;

  except
    on E: Exception do
    begin
      FTimer.Enabled := False;

      raise Exception.Create(MErro_Search+ E.Message);

      if Assigned(FError) then
        FError(Self, NErro_Generic_DirectoryNotFound, MErro_Search);

      if (FShowErrors) then
        ShowMessage(MErro_Search);
      end;
  end;
end;

procedure TXPAdAutoUpdate.Timer(Sender: TObject);
begin
  SearchUpdate;
end;

function TXPAdAutoUpdate.getLocalVersion: smallint;
var { Alterar para arquivo JSON }
  sNumeroVersao: string;
  oArquivoINI: TIniFile;
begin
  Result := 0;
  case FMethodVersion of
    mvManually:
    begin
      Result := LocalVersion;
    end;
    mvINI:
    begin
      oArquivoINI := TIniFile.Create(getDirExe + 'versionLocal.ini');
      try
        sNumeroVersao := oArquivoINI.ReadString('version', 'number', EmptyStr);
        sNumeroVersao := StringReplace(sNumeroVersao, '.', EmptyStr, [rfReplaceAll]);
        Result := StrToIntDef(sNumeroVersao, 0);
      finally
        FreeAndNil(oArquivoINI);
      end;
    end;
    mvAPI:
    begin
      Result := 0;
    end;
  end;
end;

function TXPAdAutoUpdate.getRemoteVersion: smallint;
var
  sNumeroVersao: string;
  oArquivoINI: TIniFile;
begin
  Result := 0;
  case FMethodVersion of
    mvManually:
    begin
      Result := FRemoteVersion;
    end;
    mvINI:
    begin
      if FileExists(getDirExe + 'versionFTP.ini') then
        DeleteFile(PWideChar(getDirExe + 'versionFTP.ini'));

      FFTP.Get(FConf.FTP.Dir + 'versionFTP.ini', getDirExe + 'versionFTP.ini', true, true);

      oArquivoINI := TIniFile.Create(getDirExe + 'versionFTP.ini');
      try
        sNumeroVersao := oArquivoINI.ReadString('version', 'number',
          EmptyStr);
        sNumeroVersao := StringReplace(sNumeroVersao, '.', EmptyStr,
          [rfReplaceAll]);
        Result := StrToIntDef(sNumeroVersao, 0);
      finally
        FreeAndNil(oArquivoINI);
      end;
    end;
    mvAPI:
    begin
      Result := 0;
    end;
  end;

end;

procedure TXPAdAutoUpdate.AlterLocalVersion;
var
  oArquivoLocal, oArquivoFTP: TIniFile;
  sNumNewVersion: string;
begin
  if(FMethodVersion = mvINI)then
  begin
    oArquivoFTP := TIniFile.Create(getDirExe + 'versionFTP.ini');
    oArquivoLocal := TIniFile.Create(getDirExe + 'versionLocal.ini');
    try
      sNumNewVersion := oArquivoFTP.ReadString('version', 'number', EmptyStr);
      oArquivoLocal.WriteString('version', 'number', sNumNewVersion);
    finally
      FreeAndNil(oArquivoFTP);
      FreeAndNil(oArquivoLocal);
    end;
  end;
end;

procedure TXPAdAutoUpdate.setConf(const Value: TXPAdConf);
begin
  FConf.Assign(Value);
end;

procedure TXPAdAutoUpdate.setTimeSearch(const Value: Integer);
begin
  FTimeSearch := Value;
end;

procedure TXPAdAutoUpdate.Upgrade;
begin
  Validate();

  if(Assigned(FBeforeUpdate))then
    FBeforeUpdate(Self);

  if (FFTP = nil) then
    FFTP := TIdFTP.Create;

  ConfigureConnection;

  if not ConnectFTPServer then
    Exit;

  if FThread <> nil Then
  begin
    FThread.Terminate;
    FThread.Free;
  end;

  FThread := TXPAdThread.Create(Self);
end;

procedure TXPAdAutoUpdate.Validate();
begin
  if(getDirExe.IsEmpty)then
  begin
    ShowMessage(MValid_DirNotFound);
    Abort;
  end;

  if(getApplicationName.IsEmpty)then
  begin
    ShowMessage(MValid_AppNameNotFound);
    Abort;
  end;
end;

end.
