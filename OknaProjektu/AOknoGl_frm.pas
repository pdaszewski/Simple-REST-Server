unit AOknoGl_frm;

interface

uses
  Winapi.Messages
  ,System.SysUtils
  ,System.Variants
  ,System.Classes
  ,Vcl.Graphics
  ,Vcl.Controls
  ,Vcl.Forms
  ,Vcl.Dialogs
  ,Vcl.AppEvnts
  ,Vcl.StdCtrls
  ,IdHTTPWebBrokerBridge
  ,Web.HTTPApp
  ,Vcl.ExtCtrls
  ,Data.DB
  ,Data.Win.ADODB
  ,DateUtils
  ,ComObj
  ,System.Hash
  ,JOSE.Core.JWT
  ,JOSE.Core.JWS
  ,JOSE.Core.JWK
  ,JOSE.Core.JWA
  ,JOSE.Types.JSON
  ,Vcl.Imaging.pngimage
  ,Vcl.Menus
  ,IdBaseComponent
  ,IdComponent
  ,IdIOHandler
  ,IdIOHandlerSocket
  ,IdIOHandlerStack
  ,IdSSL
  ,IdSSLOpenSSL
  ,IdTCPConnection
  ,Vcl.Samples.Spin;

type
 tokens = record
  token : string[200];
  valid_until : TDateTime;
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
    lbox_log: TListBox;
    btn_JWTtest: TButton;
    Image1: TImage;
    TrayIcon1: TTrayIcon;
    btn_do_traya: TButton;
    LogsPopup: TPopupMenu;
    Wyczylogi1: TMenuItem;
    SaveLogsToFile: TMenuItem;
    N1: TMenuItem;
    SaveDialog: TSaveDialog;
    SaveLogs: TTimer;
    pnl_ladowanie_info: TPanel;
    connections_count: TSpinEdit;
    Label4: TLabel;

    function Token_verification(token:  String): Boolean;
    function Generate_JTW: string;

    procedure OnGetSSLPassword(var APassword: String);
    function Body_builder(string_text: String): String;
    function Format_the_request(request_in, resources: string): String;

    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure btn_StartClick(Sender: TObject);
    procedure btn_STOPClick(Sender: TObject);
    procedure btn_openBrowserClick(Sender: TObject);
    procedure AutoRunTimer(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure btn_do_trayaClick(Sender: TObject);
    procedure Wyczylogi1Click(Sender: TObject);
    procedure SaveLogsToFileClick(Sender: TObject);
    procedure SaveLogsTimer(Sender: TObject);
    procedure btn_JWTtestClick(Sender: TObject);

  private
    FServer: TIdHTTPWebBrokerBridge;
    procedure StartServer;
    { Private declarations }
  public
   Var
    DB_connection_string : String;

  end;

const
 number_of_tokens = 10000;
 life_time_of_token = 45; //minut

 version = '1.0.0';

var
  MainForm: TMainForm;
  tab_tokeny : array[1..number_of_tokens] of tokens;
  logs_folder: string;
  server: string;


implementation

{$R *.dfm}

uses
  WinApi.Windows
  ,Winapi.ShellApi
  ,JOSE.Types.Bytes
  ,JOSE.Core.Builder;

function TMainForm.Token_verification(token:  String): Boolean;
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
  fileName: string;
  config_file: TextFile;
  line: string;
  data_base: string;
begin
 AutoRun.Enabled:=False;
 fileName:=ExtractFilePath(Application.ExeName)+'Data\config.dat';
 if FileExists(fileName)=True then
  Begin
   AssignFile(config_file,fileName);
   Reset(config_file);
   Repeat
    Readln(config_file,line);
    if Pos('[server]=',line)>0 then
     Begin
      Delete(line,1,Length('[server]='));
      server:=Trim(line);
     End;
    if Pos('[db]=',line)>0 then
     Begin
      Delete(line,1,Length('[db]='));
      data_base:=Trim(line);
     End;
    if Pos('[port]=',line)>0 then
     Begin
      Delete(line,1,Length('[port]='));
      EditPort.Text:=Trim(line);
     End;
   Until eof(config_file);
  End;

 DB_connection_string:='Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog='+data_base+';Data Source='+server;

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

function TMainForm.Generate_JTW: string;
var
  LToken: TJWT;
begin
  LToken := TJWT.Create(TJWTClaims);
  try
    LToken.Claims.IssuedAt := Now;
    LToken.Claims.Expiration := IncMinute(Now,life_time_of_token);
    LToken.Claims.Issuer := 'Simple REST Server';
    Generate_JTW:=TJOSE.SHA256CompactToken('TopSecret', LToken);
  finally
    LToken.Free;
  end;
end;

procedure TMainForm.btn_JWTtestClick(Sender: TObject);
begin
 ShowMessage('JWT libraries available: '+#13+Generate_JTW);
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
  choice: Integer;
begin
 choice := MessageBox(Handle,
 PWideChar('Are you sure you want to stop and close the REST server?' + #13 +
 'Dependent services will stop working!'), 'Close the REST server', MB_YESNO + MB_ICONQUESTION);
 if choice = mrYes then
  Begin
   FServer.Active := False;
   FServer.Bindings.Clear;
   SaveLogsTimer(Self);
   Close;
  End;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  LIOHandleSSL: TIdServerIOHandlerSSLOpenSSL;
  i: Integer;
  application_path: string;
begin
  application_path:=ExtractFilePath(Application.ExeName);
  logs_folder:=application_path+'Logs\';
  if DirectoryExists(logs_folder)=False then CreateDir(logs_folder);

  FServer := TIdHTTPWebBrokerBridge.Create(Self);

  LIOHandleSSL                          := TIdServerIOHandlerSSLOpenSSL.Create(FServer);
  LIOHandleSSL.SSLOptions.CertFile      := application_path+'Data\Certyfikaty\ia.crt';
  LIOHandleSSL.SSLOptions.RootCertFile  := application_path+'Data\Certyfikaty\ca.crt';
  LIOHandleSSL.SSLOptions.KeyFile       := application_path+'Data\Certyfikaty\ia.key';
  LIOHandleSSL.SSLOptions.Mode          := sslmServer;
  //LIOHandleSSL.SSLOptions.VerifyMode    := [sslvrfPeer,sslvrfFailIfNoPeerCert,sslvrfClientOnce];
  LIOHandleSSL.SSLOptions.VerifyDepth   := 10;
  LIOHandleSSL.SSLOptions.Method        := sslvSSLv23;
  LIOHandleSSL.SSLOptions.SSLVersions   := [sslvSSLv23];
  LIOHandleSSL.OnGetPassword            := OnGetSSLPassword;

  //FServer.IOHandler                     := LIOHandleSSL;

  Caption:='REST server - version: '+version;
  for i := 1 to number_of_tokens do
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

procedure TMainForm.SaveLogsToFileClick(Sender: TObject);
begin
 SaveDialog.Title:='Save logs to file';
 if SaveDialog.Execute then
  Begin
   lbox_log.Items.SaveToFile(SaveDialog.FileName);
   ShowMessage('Logs saved to file:'+#13+SaveDialog.FileName);
  End;
end;

procedure TMainForm.SaveLogsTimer(Sender: TObject);
Var
 log_file : String;
 log_list : TStringList;
begin
 log_file:=logs_folder+'log_'+DateToStr(Date)+'.txt';
 log_list:=TStringList.Create;
 if FileExists(log_file)=True then log_list.LoadFromFile(log_file);
 log_list.Text:=log_list.Text+lbox_log.Items.Text;
 log_list.SaveToFile(log_file);
 log_list.Free;
 lbox_log.Clear;
end;

procedure TMainForm.Wyczylogi1Click(Sender: TObject);
begin
 lbox_log.Clear;
end;

function TMainForm.Body_builder(string_text: String): String;
Var
 body: String;
Begin
 body:='<html>' +
        '<head><title>Simple REST Server</title></head>' +
        '<body>'+string_text+'</body>' +
        '</html>';
 lbox_log.Items.Add('Response: '+string_text);
 Body_builder:=body;
End;

function TMainForm.Format_the_request(request_in, resources: string): String;
Var
  end_result : String;
  poz_start: Integer;
  poz_end: Integer;
  i: Integer;
  my_char: Char;
Begin
 request_in:=AnsiLowerCase(request_in);
 if Pos('token',request_in)>0 then
  Begin
   poz_start:=Pos('token',request_in);
   poz_end:=0;
   for i := poz_start to Length(request_in) do
    Begin
     my_char:=request_in[i];
     if (my_char='&') and (poz_end=0) then poz_end:=i;
    End;
   if poz_end=0 then poz_end:=Length(request_in);
   Delete(request_in,poz_start,poz_end-poz_start+1);
  End;

 if request_in<>'' then
  end_result:='Resource: "'+resources+'" - '+trim(StringReplace(request_in,'&',' ',[rfReplaceAll]))
 else
  end_result:='Resource: "'+resources+'"';

 Format_the_request:=end_result;
End;

end.
