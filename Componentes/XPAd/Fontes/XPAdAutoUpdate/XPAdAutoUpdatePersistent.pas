unit XPAdAutoUpdatePersistent;

interface

Uses Classes, SysUtils, System.StrUtils;

type
  TPrioridade = (tpOptional, tpRequired);
  TEngineUpdate = (euInternal, euExternal);

  {Classe de configuracao HTTP}
  TXPAdConfHTTP = Class(TPersistent)
  private
    FServer     : String;
    FPort       : Integer;
    FDir        : String;
    FSSL        : Boolean;
    procedure setPort(const Value: Integer);
    procedure setSSL(const Value: boolean);
    public
    constructor Create(AOwner : TComponent);
    procedure Assign(Source : TPersistent); override;
  published
    property  Server : String read FServer write FServer;
    property  Port    : Integer read fPort write setPort Default 80;
    property  Dir  : String read FDir write FDir;
    property  SSL      : boolean read FSSL write setSSL Default False;
  End;

  {Classe de configuracao FTP}
  TXPAdConfFTP      = Class(TPersistent)
  private
    FServer      : String;
    FPort        : Integer;
    FUser        : String;
    FPassword    : String;
    FDir         : String;
    FZipFileName : String;
    FModeBinario : Boolean;
    FModePassivo : Boolean;
    procedure setPort(const Value: Integer);
    function getZipFileName(): String;
  public
    constructor Create(AOwner : TComponent);
    procedure Assign(Source : TPersistent); override;
  published
    property Server : String read FServer write FServer;
    property Port    : Integer read FPort write setPort Default 21;
    property User  : String read FUser write FUser;
    property Password    : String read FPassword write FPassword;
    property Dir: String read FDir write FDir;
    property BinaryMode : Boolean read FModeBinario write FModeBinario Default False;
    property PassiveMode : Boolean read FModePassivo write FModePassivo Default True;
    property ZipFileName: String read getZipFileName write FZipFileName;
  End;

  {Classe de configuração PROXY}
  TXPAdConfProxy    = Class(TPersistent)
  private
    FServer         : String;
    FPort            : Integer;
    FUser          : String;
    FPassword            : String;
    FActive            : Boolean;
    procedure setPort(const Value: Integer);
  public
    constructor Create(AOwner : TComponent);
    procedure Assign(Source : TPersistent); override;
  published
    property Server : String read FServer write fServer;
    property Port    : Integer read FPort write setPort Default 3128;
    property User  : String read FUser write FUser;
    property Password    : String read FPassword write FPassword;
    property Active    : Boolean read FActive write FActive Default False;
  End;

  {Classe de configurações}
  TXPAdConf = Class(TPersistent)
  private
    FFTP              : TXPAdConfFTP;
    FHTTP             : TXPAdConfHTTP;
    FProxy            : TXPAdConfProxy;
    procedure setFTP(const Value: TXPAdConfFTP);
    procedure setHTTP(const Value: TXPAdConfHTTP);
    procedure setProxy(const Value: TXPAdConfProxy);
  public
    constructor Create(AOwner : TComponent);
    destructor Destroy; override;
    procedure Assign(Source : TPersistent); override;
  published
    property FTP      : TXPAdConfFTP read FFTP write setFTP;
    property HTTP     : TXPAdConfHTTP read FHTTP write setHTTP;
    property Proxy    : TXPAdConfProxy read FProxy write setProxy;
  end;

implementation

uses
  XPAdMethods;

{ TXPAdConfHTTP }

procedure TXPAdConfHTTP.Assign(Source: TPersistent);
begin
  if Source is TXPAdConfHTTP Then
    with Source as TXPAdConfHTTP do
    begin
      Server := Server;
      Port   := Port;
      Dir    := Dir;
      SSL    := SSL;
    end
  else
    inherited;
end;

constructor TXPAdConfHTTP.Create(AOwner: TComponent);
begin
     FServer := 'localhost';
     FPort    := 80;
     FSSL      := False;
end;

procedure TXPAdConfHTTP.setPort(const Value: Integer);
begin
  fPort := Value;
end;

procedure TXPAdConfHTTP.setSSL(const Value: boolean);
begin
  FSSL := Value;
  if Value then
    FPort := 443
  else
    FPort := 80;
end;

{ TXPAdConfFTP }

procedure TXPAdConfFTP.Assign(Source: TPersistent);
begin
  if Source is TXPAdConfFTP then
    With Source as TXPAdConfFTP Do
      Begin
        Self.Server      := Server;
        Self.Port        := Port;
        Self.User        := User;
        Self.Password    := Password;
        Self.Dir         := Dir;
        Self.BinaryMode  := BinaryMode;
        Self.PassiveMode := PassiveMode;
      End
  Else inherited;
end;

constructor TXPAdConfFTP.Create(AOwner: TComponent);
begin
  FServer      := 'localhost';
  FPort        := 21;
  FDir         := '/';
  FModeBinario := True;
  FModePassivo := True;
end;

function TXPAdConfFTP.getZipFileName(): String;
begin
  if(FZipFileName.IsEmpty)then
    Result := 'update.zip'
  else
    Result := FZipFileName;
end;

procedure TXPAdConfFTP.setPort(const Value: Integer);
begin
  FPort := Value;
end;

{ TXPAdConfProxy }

procedure TXPAdConfProxy.Assign(Source: TPersistent);
begin
  if Source is TXPAdConfProxy then
    With Source as TXPAdConfProxy Do
      Begin
        Self.Server    := Server;
        Self.Port      := Port;
        Self.User      := User;
        Self.Password  := Password;
        Self.Active    := Active;
      End
  Else inherited;
end;

constructor TXPAdConfProxy.Create(AOwner: TComponent);
begin
  FServer   := 'localhost';
  FPort     := 3128;
  FUser     := '';
  FPassword := '';
  FActive   := False;
end;

procedure TXPAdConfProxy.setPort(const Value: Integer);
begin
  FPort := Value;
end;

{ TXPAdConf }

procedure TXPAdConf.Assign(Source: TPersistent);
begin
  if Source is TXPAdConf then
  begin
    FTP   := TXPAdConf(Source).FTP;
    HTTP  := TXPAdConf(Source).HTTP;
    Proxy := TXPAdConf(Source).Proxy;
  end
  else
    inherited;
end;

constructor TXPAdConf.Create(AOwner: TComponent);
begin
  FFTP    := TXPAdConfFTP.Create(AOwner);
  FHTTP   := TXPAdConfHTTP.Create(AOwner);
  FProxy  := TXPAdConfProxy.Create(AOwner);
end;

destructor TXPAdConf.Destroy;
begin
  FFTP.Free;
  FHTTP.Free;
  FProxy.Free;
  inherited;
end;

procedure TXPAdConf.setFTP(const Value: TXPAdConfFTP);
begin
  FFTP.Assign(Value);
end;

procedure TXPAdConf.setHTTP(const Value: TXPAdConfHTTP);
begin
  FHTTP.Assign(Value);
end;

procedure TXPAdConf.setProxy(const Value: TXPAdConfProxy);
begin
  FProxy.Assign(Value);
end;

end.
