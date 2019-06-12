program SimpleRESTServer;
{$APPTYPE GUI}

uses
  Vcl.Forms,
  Web.WebReq,
  IdHTTPWebBrokerBridge,
  AOknoGl_frm in 'ProjectForms\AOknoGl_frm.pas' {MainForm},
  WebModuleUnit1 in 'ProjectForms\WebModuleUnit1.pas' {ModulWEB: TWebModule},
  Vcl.Themes,
  Vcl.Styles,
  JOSE.Core.Base in 'ProjectForms\JOSE.Core.Base.pas',
  JOSE.Core.Builder in 'ProjectForms\JOSE.Core.Builder.pas',
  JOSE.Core.JWA.Compression in 'ProjectForms\JOSE.Core.JWA.Compression.pas',
  JOSE.Core.JWA.Encryption in 'ProjectForms\JOSE.Core.JWA.Encryption.pas',
  JOSE.Core.JWA.Factory in 'ProjectForms\JOSE.Core.JWA.Factory.pas',
  JOSE.Core.JWA in 'ProjectForms\JOSE.Core.JWA.pas',
  JOSE.Core.JWA.Signing in 'ProjectForms\JOSE.Core.JWA.Signing.pas',
  JOSE.Core.JWE in 'ProjectForms\JOSE.Core.JWE.pas',
  JOSE.Core.JWK in 'ProjectForms\JOSE.Core.JWK.pas',
  JOSE.Core.JWS in 'ProjectForms\JOSE.Core.JWS.pas',
  JOSE.Core.JWT in 'ProjectForms\JOSE.Core.JWT.pas',
  JOSE.Core.Parts in 'ProjectForms\JOSE.Core.Parts.pas',
  JOSE.Cryptography.RSA in 'ProjectForms\JOSE.Cryptography.RSA.pas',
  JOSE.Encoding.Base64 in 'ProjectForms\JOSE.Encoding.Base64.pas',
  JOSE.Hashing.HMAC in 'ProjectForms\JOSE.Hashing.HMAC.pas',
  JOSE.Types.Bytes in 'ProjectForms\JOSE.Types.Bytes.pas',
  JOSE.Types.JSON in 'ProjectForms\JOSE.Types.JSON.pas';

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
