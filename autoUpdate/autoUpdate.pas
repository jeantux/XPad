{*******************************************************}
{                                                       }
{            Jean Carlos - Delphi Runtime               }
{          2019 - https://github.com/jeaanca            }
{                                                       }
{*******************************************************}

unit autoUpdate;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.Graphics, idftpcommon,
  Vcl.ExtCtrls, IdFTP, IdException, IniFiles, ShellAPI, System.Zip;

type
  TAutoUpdate = class(TComponent)
  private
    FTamanhoExe: integer;
    FidFTP: TidFTP;
    FUsername: string;
    FPassword: string;
    FHost: string;
    FPort: Integer;
    function getDirExe: string;
    function ConnectFTPServer: boolean;
    function getLocalVersion: smallint;
    function getFTPVersion: smallint;
    procedure DownloadUpdate;
    procedure UpdateVersion;
    procedure ConfigureConnection;
    procedure UnZip();

  public
    constructor Create(AOwner: TComponent); override;
    procedure Execute();
  published
    property Username: string read FUsername write FUsername;
    property Password: string read FPassword write FPassword;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;
  end;

const
  VERSION = 'version';
  VERSIONNUMBER = 'number';

implementation

function TAutoUpdate.getDirExe: string;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

procedure TAutoUpdate.ConfigureConnection();
begin
  FidFTP.Username     := FUsername;
  FidFTP.Password     := FPassword;
  FidFTP.Host         := FHost;
  FidFTP.Port         := FPort;
  FidFTP.Passive      := True;
  FidFTP.TransferType := ftBinary;
end;

function TAutoUpdate.ConnectFTPServer: boolean;
begin
  ConfigureConnection;

  if FidFTP.Connected then
    FidFTP.Disconnect;
  try
    FidFTP.Connect;
    Result := True;
  except
    On E:Exception do
    begin
      ShowMessage('Falha na conexão com o banco de Dados: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TAutoUpdate.getLocalVersion: smallint;
var
  sNumeroVersao: string;
  oArquivoINI: TIniFile;
begin
  oArquivoINI := TIniFile.Create(getDirExe + 'versionLocal.ini');
  try
    sNumeroVersao := oArquivoINI.ReadString(VERSION, VERSIONNUMBER, EmptyStr);
    sNumeroVersao := StringReplace(sNumeroVersao, '.', EmptyStr, [rfReplaceAll]);
    result := StrToIntDef(sNumeroVersao, 0);
  finally
    FreeAndNil(oArquivoINI);
  end;
end;

function TAutoUpdate.getFTPVersion: smallint;
var
  sNumeroVersao: string;
  oArquivoINI: TIniFile;
begin
  if FileExists(getDirExe + 'versionFTP.ini') then
    DeleteFile(getDirExe + 'versionFTP.ini');

  FidFTP.Get('autoupdate/versionFTP.ini', getDirExe + 'versionFTP.ini', True, True);

  oArquivoINI := TIniFile.Create(getDirExe + 'versionFTP.ini');
  try
    sNumeroVersao := oArquivoINI.ReadString(VERSION, VERSIONNUMBER, EmptyStr);
    sNumeroVersao := StringReplace(sNumeroVersao, '.', EmptyStr, [rfReplaceAll]);
    result := StrToIntDef(sNumeroVersao, 0);
  finally
    FreeAndNil(oArquivoINI);
  end;
end;

constructor TAutoUpdate.Create(AOwner: TComponent);
begin
  inherited;
  FidFTP := TIdFTP.Create(Self);
end;

procedure TAutoUpdate.DownloadUpdate;
begin
  try
    if FileExists(getDirExe + 'update.zip') then
      DeleteFile(getDirExe + 'update.zip');

    FTamanhoExe := FidFTP.Size('autoupdate/update.zip');

    FidFTP.Get('autoupdate/update.zip',
      getDirExe + 'update.zip', True, True);
  except
    On E:Exception do
    begin
      if E is EIdConnClosedGracefully then
        Exit;

      ShowMessage('Erro ao baixar a atualização: ' + E.Message);

      Abort;
    end;
  end;
end;

procedure TAutoUpdate.UpdateVersion;
var
  oArquivoLocal, oArquivoFTP: TIniFile;
  sNumeroNovaVersao: string;
begin
  oArquivoFTP := TIniFile.Create(getDirExe + 'versionFTP.ini');
  oArquivoLocal := TIniFile.Create(getDirExe + 'versionLocal.ini');
  try
    sNumeroNovaVersao := oArquivoFTP.ReadString(VERSION, VERSIONNUMBER, EmptyStr);
    oArquivoLocal.WriteString(VERSION, VERSIONNUMBER, sNumeroNovaVersao);
  finally
    FreeAndNil(oArquivoFTP);
    FreeAndNil(oArquivoLocal);
  end;
end;

procedure TAutoUpdate.UnZip();
var
  UnZipper: TZipFile;
  sZIPName: string;
begin
  if FileExists(getDirExe + 'SisBackup.exe') then
    DeleteFile(getDirExe + 'SisBackup.exe');

  RenameFile(getDirExe + 'Sistema.exe', getDirExe + 'SisBackup.exe');
  sZIPName := getDirExe + 'update.zip';

  UnZipper := TZipFile.Create();
  try
    UnZipper.Open(sZIPName, zmRead);
    UnZipper.ExtractAll(getDirExe);
    UnZipper.Close;
  finally
    FreeAndNil(UnZipper);
  end;
end;

procedure TAutoUpdate.Execute();
var
  nNumeroVersaoLocal, nNumeroVersaoFTP: smallint;
begin
  if not ConnectFTPServer then
    Exit;

  nNumeroVersaoLocal := getLocalVersion;
  nNumeroVersaoFTP := getFTPVersion;

  if nNumeroVersaoLocal < nNumeroVersaoFTP then
  begin
    DownloadUpdate;
    UnZip;
    UpdateVersion;

    ShowMessage('Sistema atualizado com sucesso!');
  end
  else
    ShowMessage('O sistema está na ultima versão!');
end;

end.


