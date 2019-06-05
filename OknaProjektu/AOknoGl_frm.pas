unit AOknoGl_frm;

interface

uses
  Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.AppEvnts, Vcl.StdCtrls, IdHTTPWebBrokerBridge, Web.HTTPApp, Vcl.ExtCtrls,
  Data.DB, Data.Win.ADODB, DateUtils, ComObj, System.Hash,

  JOSE.Core.JWT,
  JOSE.Core.JWS,
  JOSE.Core.JWK,
  JOSE.Core.JWA,

  JOSE.Types.JSON, Vcl.Imaging.pngimage, Vcl.Menus, IdBaseComponent,
  IdComponent, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL, IdTCPConnection, Vcl.Samples.Spin;

type
 tokeny = record
  token : string[200];
  wazny_do : TDateTime;
 end;

type
 APIKey = record
  Key : string[100];
  App : string[100];
 end;

type
  TMainForm = class(TForm)
    btn_Start: TButton;
    btn_STOP: TButton;
    EditPort: TEdit;
    Label1: TLabel;
    ApplicationEvents1: TApplicationEvents;
    btn_openBrowser: TButton;
    AutoRun: TTimer;
    lbox_logi: TListBox;
    btn_JWTtest: TButton;
    Image1: TImage;
    TrayIcon1: TTrayIcon;
    btn_do_traya: TButton;
    PopupLogow: TPopupMenu;
    Wyczylogi1: TMenuItem;
    Zapiszlogidopliku1: TMenuItem;
    N1: TMenuItem;
    SaveDialog: TSaveDialog;
    ZapiszLogi: TTimer;
    pnl_ladowanie_info: TPanel;
    connections_count: TSpinEdit;
    Label4: TLabel;

    function Weryfikacja_tokenu(token:  String): Boolean;
    function Generuj_JTW: string;

    procedure OnGetSSLPassword(var APassword: String);
    function Body_builder(wpis: String): String;
    function Formatuj_request(request_in, zasob: string): String;

    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure btn_StartClick(Sender: TObject);
    procedure btn_STOPClick(Sender: TObject);
    procedure btn_openBrowserClick(Sender: TObject);
    procedure AutoRunTimer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure btn_do_trayaClick(Sender: TObject);
    procedure Wyczylogi1Click(Sender: TObject);
    procedure Zapiszlogidopliku1Click(Sender: TObject);
    procedure ZapiszLogiTimer(Sender: TObject);
    procedure btn_JWTtestClick(Sender: TObject);

  private
    FServer: TIdHTTPWebBrokerBridge;
    procedure StartServer;
    { Private declarations }
  public
   Var
    string_polaczenia_DB : String;

  end;

const
 ilosc_tokenow = 10000;
 ilosc_kluczy = 10;
 czas_zycia_tokenu = 45; //minut

 wersja = '1.0.0';

var
  MainForm: TMainForm;
  tab_tokeny : array[1..ilosc_tokenow] of tokeny;
  polaczenie_DB: string;
  folder_logow: string;
  serwer: string;


implementation

{$R *.dfm}

uses
  WinApi.Windows, Winapi.ShellApi,JOSE.Types.Bytes, JOSE.Core.Builder;

function TMainForm.Weryfikacja_tokenu(token:  String): Boolean;
var
  LToken: TJWT;
  LSigner: TJWS;
  LCompactToken: string;
  AKey: TJWK;
begin
  Result := False;
  LCompactToken := token;

  AKey := TJWK.Create('Simple REST Server');

  LToken := TJWT.Create;
  try
  try
    LSigner := TJWS.Create(LToken);
    LSigner.SkipKeyValidation := True;
    try
      LSigner.SetKey(AKey);
      LSigner.CompactToken := LCompactToken;
      LSigner.VerifySignature;
    finally
      LSigner.Free;
    end;

    if LToken.Verified then
      Result := True;

    if LToken.Claims.Expiration < Now then
      Result := False;

  finally
    LToken.Free;
  end;
  except
   Result := False;
  end;
End;

procedure TMainForm.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
  btn_Start.Enabled := not FServer.Active;
  btn_STOP.Enabled := FServer.Active;
  EditPort.Enabled := not FServer.Active;
end;

procedure TMainForm.AutoRunTimer(Sender: TObject);
var
  plikName: string;
  plik_konfiguracji: TextFile;
  linia: string;
  poz: Integer;
  data_base: string;
begin
 AutoRun.Enabled:=False;
 plikName:=ExtractFilePath(Application.ExeName)+'Dane\konfiguracja.dat';
 if FileExists(plikName)=True then
  Begin
   AssignFile(plik_konfiguracji,plikName);
   Reset(plik_konfiguracji);
   Repeat
    Readln(plik_konfiguracji,linia);
    if Pos('[server]=',linia)>0 then
     Begin
      Delete(linia,1,Length('[server]='));
      serwer:=Trim(linia);
     End;
    if Pos('[db]=',linia)>0 then
     Begin
      Delete(linia,1,Length('[db]='));
      data_base:=Trim(linia);
     End;
    if Pos('[port]=',linia)>0 then
     Begin
      Delete(linia,1,Length('[port]='));
      EditPort.Text:=Trim(linia);
     End;
   Until eof(plik_konfiguracji);
  End;

 polaczenie_DB:='Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog='+data_base+';Data Source='+serwer;
 string_polaczenia_DB:=polaczenie_DB;

 Application.ProcessMessages;
 btn_Start.Visible:=True;
 btn_STOP.Visible:=True;
 btn_openBrowser.Visible:=True;
 pnl_ladowanie_info.Visible:=True;
 Application.ProcessMessages;
 btn_StartClick(Self);
 pnl_ladowanie_info.Visible:=False;
 Application.ProcessMessages;
end;

procedure TMainForm.btn_do_trayaClick(Sender: TObject);
begin
 Hide();
 WindowState := wsMinimized;
 TrayIcon1.Visible := True;
 TrayIcon1.ShowBalloonHint;
end;

function TMainForm.Generuj_JTW: string;
var
  LToken: TJWT;
begin
  LToken := TJWT.Create(TJWTClaims);
  try
    LToken.Claims.IssuedAt := Now;
    LToken.Claims.Expiration := IncMinute(Now,czas_zycia_tokenu);
    LToken.Claims.Issuer := 'Simple REST Server';
    Generuj_JTW:=TJOSE.SHA256CompactToken('TopSecret', LToken);
  finally
    LToken.Free;
  end;
end;

procedure TMainForm.btn_JWTtestClick(Sender: TObject);
begin
 ShowMessage('Biblioteki OpenSSL dostêpne: '+#13+Generuj_JTW);
end;

procedure TMainForm.btn_openBrowserClick(Sender: TObject);
var
  LURL: string;
begin
  StartServer;
  LURL := 'http://localhost:8443/show_categories?group_id=1';
  ShellExecute(0, nil, PChar(LURL), nil, nil, SW_SHOWNOACTIVATE);
end;

procedure TMainForm.btn_StartClick(Sender: TObject);
begin
  StartServer;
end;

procedure TMainForm.btn_STOPClick(Sender: TObject);
var
  wyb: Integer;
begin
 wyb := MessageBox(Handle,
 PWideChar('Czy na pewno chcesz zatrzymaæ i zamkn¹æ serwer REST?' + #13 +
 'Us³ugi zale¿ne przestan¹ dzia³aæ!'), 'Zamykanie serwera REST', MB_YESNO + MB_ICONQUESTION);
 if wyb = mrYes then
  Begin
   FServer.Active := False;
   FServer.Bindings.Clear;
   ZapiszLogiTimer(Self);
   Close;
  End;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  LIOHandleSSL: TIdServerIOHandlerSSLOpenSSL;
  i: Integer;
  sciezka: string;
  plik_szablonu: string;
begin
  sciezka:=ExtractFilePath(Application.ExeName);
  folder_logow:=sciezka+'Logi\';

  if DirectoryExists(folder_logow)=False then CreateDir(folder_logow);

  FServer := TIdHTTPWebBrokerBridge.Create(Self);

  LIOHandleSSL                          := TIdServerIOHandlerSSLOpenSSL.Create(FServer);
  LIOHandleSSL.SSLOptions.CertFile      := sciezka+'Dane\Certyfikaty\ia.crt';
  LIOHandleSSL.SSLOptions.RootCertFile  := sciezka+'Dane\Certyfikaty\ca.crt';
  LIOHandleSSL.SSLOptions.KeyFile       := sciezka+'Dane\Certyfikaty\ia.key';
  LIOHandleSSL.SSLOptions.Mode          := sslmServer;
  //LIOHandleSSL.SSLOptions.VerifyMode    := [sslvrfPeer,sslvrfFailIfNoPeerCert,sslvrfClientOnce];
  LIOHandleSSL.SSLOptions.VerifyDepth   := 10;
  LIOHandleSSL.SSLOptions.Method        := sslvSSLv23;
  LIOHandleSSL.SSLOptions.SSLVersions   := [sslvSSLv23];
  LIOHandleSSL.OnGetPassword            := OnGetSSLPassword;

  //FServer.IOHandler                     := LIOHandleSSL;

  Caption:='Serwer REST - wersja: '+wersja;
  for i := 1 to ilosc_tokenow do
   Begin
    tab_tokeny[i].token:='';
   End;

end;

procedure TMainForm.OnGetSSLPassword(var APassword: String);
begin
  APassword := '';
end;

procedure TMainForm.StartServer;
begin
 if not FServer.Active then
  begin
    FServer.Bindings.Clear;
    FServer.DefaultPort := StrToInt(EditPort.Text);
    FServer.Active := True;
  end;
end;

procedure TMainForm.TrayIcon1DblClick(Sender: TObject);
begin
 TrayIcon1.Visible := False;
 Show();
 WindowState := wsNormal;
 Application.BringToFront();
end;

procedure TMainForm.Zapiszlogidopliku1Click(Sender: TObject);
begin
 SaveDialog.Title:='Zapisz logi do pliku';
 if SaveDialog.Execute then
  Begin
   lbox_logi.Items.SaveToFile(SaveDialog.FileName);
   ShowMessage('Logi zapisane do pliku:'+#13+SaveDialog.FileName);
  End;
end;

procedure TMainForm.ZapiszLogiTimer(Sender: TObject);
Var
 plik_logow : String;
 logi_pom : TStringList;
begin
 plik_logow:=folder_logow+'log_'+DateToStr(Date)+'.txt';
 logi_pom:=TStringList.Create;
 if FileExists(plik_logow)=True then logi_pom.LoadFromFile(plik_logow);
 logi_pom.Text:=logi_pom.Text+lbox_logi.Items.Text;
 logi_pom.SaveToFile(plik_logow);
 logi_pom.Free;
 lbox_logi.Clear;
end;

procedure TMainForm.Wyczylogi1Click(Sender: TObject);
begin
 lbox_logi.Clear;
end;

function TMainForm.Body_builder(wpis: String): String;
Var
 wynik: String;
Begin
 wynik:='<html>' +
        '<head><title>Simple REST Server</title></head>' +
        '<body>'+wpis+'</body>' +
        '</html>';
 lbox_logi.Items.Add('OdpowiedŸ: '+wpis);
 Body_builder:=wynik;
End;

function TMainForm.Formatuj_request(request_in, zasob: string): String;
Var
 wynik : String;
  poz_start: Integer;
  poz_end: Integer;
  i: Integer;
  znak: Char;
Begin
 request_in:=AnsiLowerCase(request_in);
 if Pos('token',request_in)>0 then
  Begin
   poz_start:=Pos('token',request_in);
   poz_end:=0;
   for i := poz_start to Length(request_in) do
    Begin
     znak:=request_in[i];
     if (znak='&') and (poz_end=0) then poz_end:=i;
    End;
   if poz_end=0 then poz_end:=Length(request_in);
   Delete(request_in,poz_start,poz_end-poz_start+1);
  End;

 if request_in<>'' then
  wynik:='Zasób: "'+zasob+'" - '+trim(StringReplace(request_in,'&',' ',[rfReplaceAll]))
 else
  wynik:='Zasób: "'+zasob+'"';

 Formatuj_request:=wynik;
End;

end.
