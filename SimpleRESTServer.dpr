program SimpleRESTServer;
{$APPTYPE GUI}

uses
  Vcl.Forms,
  Web.WebReq,
  IdHTTPWebBrokerBridge,
  AOknoGl_frm in 'OknaProjektu\AOknoGl_frm.pas' {MainForm},
  WebModuleUnit1 in 'OknaProjektu\WebModuleUnit1.pas' {ModulWEB: TWebModule},
  Vcl.Themes,
  Vcl.Styles,
  JOSE.Core.Base in 'OknaProjektu\JOSE.Core.Base.pas',
  JOSE.Core.Builder in 'OknaProjektu\JOSE.Core.Builder.pas',
  JOSE.Core.JWA.Compression in 'OknaProjektu\JOSE.Core.JWA.Compression.pas',
  JOSE.Core.JWA.Encryption in 'OknaProjektu\JOSE.Core.JWA.Encryption.pas',
  JOSE.Core.JWA.Factory in 'OknaProjektu\JOSE.Core.JWA.Factory.pas',
  JOSE.Core.JWA in 'OknaProjektu\JOSE.Core.JWA.pas',
  JOSE.Core.JWA.Signing in 'OknaProjektu\JOSE.Core.JWA.Signing.pas',
  JOSE.Core.JWE in 'OknaProjektu\JOSE.Core.JWE.pas',
  JOSE.Core.JWK in 'OknaProjektu\JOSE.Core.JWK.pas',
  JOSE.Core.JWS in 'OknaProjektu\JOSE.Core.JWS.pas',
  JOSE.Core.JWT in 'OknaProjektu\JOSE.Core.JWT.pas',
  JOSE.Core.Parts in 'OknaProjektu\JOSE.Core.Parts.pas',
  JOSE.Cryptography.RSA in 'OknaProjektu\JOSE.Cryptography.RSA.pas',
  JOSE.Encoding.Base64 in 'OknaProjektu\JOSE.Encoding.Base64.pas',
  JOSE.Hashing.HMAC in 'OknaProjektu\JOSE.Hashing.HMAC.pas',
  JOSE.Types.Bytes in 'OknaProjektu\JOSE.Types.Bytes.pas',
  JOSE.Types.JSON in 'OknaProjektu\JOSE.Types.JSON.pas';

{$R *.res}

begin
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;
  Application.Initialize;
  Application.Title := 'Simple REST Server';
  TStyleManager.TrySetStyle('Carbon');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
