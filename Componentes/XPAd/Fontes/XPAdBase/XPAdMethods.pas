unit XPAdMethods;

interface

Uses System.Classes, System.SysUtils, Messages, Vcl.Forms,
  Vcl.Dialogs, IniFiles, Winapi.ShellAPI, System.Variants, Winapi.Windows;

type
  TUtils = class
  private

    public
      class function IIF<T>(Condition: Boolean; CondTrue, CondFalse: T): T;
      class function getVersion(App : TFileName): String;
      class function CompareVersion(Atual, Disponivel: String): Shortint;
      class function IncVersion(Versao:String): String;
      class function SizeOfFile(FileName: string): integer;
      class function DateOfFile(FileName : String) : TDateTime;
      class procedure CloseApp;
      class procedure RestartApp;
  end;

implementation

{ TUtils }

class function TUtils.IIF<T>(Condition: Boolean; CondTrue, CondFalse: T): T;
begin
  if(Condition)then
    Result := CondTrue
  else
    Result := CondFalse;
end;


class procedure TUtils.CloseApp;
begin
  WinExec(PAnsiChar(Application.ExeName), SW_SHOW);
  Application.Terminate;
end;

class function TUtils.CompareVersion(Atual, Disponivel: String): Shortint;
var
   TCurret, TAvailable : TStrings;
   I : Integer;
   S, A, D : String;
begin
  TCurret      := TStringList.Create;
  TAvailable := TStringList.Create;

  S := Atual;
  I := Pos('.',S);
  TCurret.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  I := Pos('.',S);
  TCurret.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  I := Pos('.',S);
  TCurret.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  TCurret.Add(S);

  S := Disponivel;
  I := Pos('.',S);
  TAvailable.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  I := Pos('.',S);
  TAvailable.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  I := Pos('.',S);
  TAvailable.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  TAvailable.Add(S);
  A := '';
  D := '';
  try
    for I := 0 to
      TCurret.Count -1 Do A := A + TCurret.Strings[I];
    for I := 0 to
      TAvailable.Count -1 Do D := D + TAvailable.Strings[I];
    if StrToInt(A) < StrToInt(D) then
      Result := 1
    else
    if StrToInt(A) = StrToInt(D) then
      Result := 0
    else
      Result := -1;
  finally
    FreeAndNil(TCurret);
    FreeAndNil(TAvailable);
  end;
end;

class function TUtils.DateOfFile(FileName: String): TDateTime;
begin
  Result := FileDateToDateTime(FileAge(Filename));
end;

class function TUtils.SizeOfFile(FileName: string): integer;
var
 f: File of byte;
 oldMode: integer;
begin
  oldMode := FileMode;
  AssignFile(f, FileName);
  try
    FileMode := fmOpenRead;
    Reset(f);
    result := FileSize(f);
  finally
    CloseFile(f);
    FileMode := oldMode;
  end;
end;

class function TUtils.IncVersion(Versao: String): String;
var
 TVersao : TStrings;
 I : Integer;
 S : String;
begin
  Result := '';
  TVersao      := TStringList.Create;
  S := versao;
  I := Pos('.',S);
  TVersao.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  I := Pos('.',S);
  TVersao.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  I := Pos('.',S);
  TVersao.Add(Copy(S,1,I-1));
  Delete(S,1,I);
  TVersao.Add(S);

  if (StrToInt(TVersao[3]) + 1) > 9 Then
  begin
    TVersao[3] := '0';
    if (StrToInt(TVersao[2]) + 1) > 9 Then
    begin
     TVersao[2] := '0';
      if (StrToInt(TVersao[1]) + 1) > 9 Then
      begin
        TVersao[1] := '0';
        TVersao[0] := IntToStr(StrToInt(TVersao[0]) + 1);
      end
      else
        TVersao[1] := IntToStr(StrToInt(TVersao[1]) + 1);
    end
   else TVersao[2] := IntToStr(StrToInt(TVersao[2]) + 1);
  end
  else TVersao[3] := IntToStr(StrToInt(TVersao[3]) + 1);
  Try
    S := TVersao[0] + '.' + TVersao[1] + '.' + TVersao[2] + '.' + TVersao[3];
    Result := S;
  Finally
    FreeAndNil(TVersao);
  end;
end;

class procedure TUtils.RestartApp;
begin
  ShellExecute(Application.Handle, 'open', PChar(Application.ExeName), nil, nil, SW_SHOWNORMAL);
  Application.Terminate;
end;

class function TUtils.getVersion(App: TFileName): String;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
  V1, V2, V3, V4: Word;
  Prog : AnsiString;
  versionExtended : String;
begin
  Prog := App;
  versionExtended := '0.0.0.0';

  if FileExists(Prog) And ((ExtractFileExt(Prog) = '.exe') Or (ExtractFileExt(Prog) = '.dll')) Then
  try
    VerInfoSize := GetFileVersionInfoSize(PChar(prog), Dummy);
    GetMem(VerInfo, VerInfoSize);
    GetFileVersionInfo(PChar(prog), 0, VerInfoSize, VerInfo);
    VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
    with VerValue^ do
    begin
      V1 := dwFileVersionMS shr 16;
      V2 := dwFileVersionMS and $FFFF;
      V3 := dwFileVersionLS shr 16;
      V4 := dwFileVersionLS and $FFFF;
    end;
    FreeMem(VerInfo, VerInfoSize);
    versionExtended := Copy (IntToStr (100 + v1), 3, 2) + '.' + Copy (IntToStr (100 + v2), 3, 2) + '.' + Copy (IntToStr (100 + v3), 3, 2) + '.' + Copy (IntToStr (100 + v4), 3, 2);
    Result := versionExtended;
  except
    Result := versionExtended;
  end
  else
    Result := versionExtended;
end;

end.
