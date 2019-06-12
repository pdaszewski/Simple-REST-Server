unit WebModuleUnit1;

interface

uses
  System.SysUtils
  ,System.Classes
  ,Web.HTTPApp
  ,Data.DB
  ,Data.Win.ADODB
  ,System.JSON
  ,ClipBrd
  ,DateUtils
  ,Datasnap.DSAuth
  ,System.NetEncoding
  ,StrUtils
  ,ActiveX
  ,Data.Bind.Components
  ,Data.Bind.ObjectScope
  ,IdHTTPHeaderInfo
  ,IdHTTPWebBrokerBridge;

type

TIdHTTPAppRequestHelper = class helper for TIdHTTPAppRequest
  public
    function GetRequestInfo: TIdEntityHeaderInfo;
  end;

type
  TModulWEB = class(TWebModule)
    procedure WebModule1DefaultHandlerAction(Sender: TObject; Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    function EscapeString(const AValue: string): string;

    procedure ShowMyCategories(Request: TWebRequest; Response: TWebResponse);

    procedure ModulWEBack_show_categoriesAction(Sender: TObject; Request: TWebRequest; Response: TWebResponse;  var Handled: Boolean);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WebModuleClass: TComponentClass = TModulWEB;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  AOknoGl_frm;

{$R *.dfm}

function TIdHTTPAppRequestHelper.GetRequestInfo: TIdEntityHeaderInfo;
  begin
    Result := FRequestInfo;
  end;

procedure TModulWEB.ModulWEBack_show_categoriesAction(Sender: TObject; Request: TWebRequest; Response: TWebResponse;
var Handled: Boolean);
begin
  Handled := True;

  MainForm.lbox_log.Items.Add('[' + DateTimeToStr(Now) + '] - ' + MainForm.Format_the_request(Request.Query, '/show_categories'));
  case Request.MethodType of
    mtGet:
      ShowMyCategories(Request, Response);
  else
    begin
      Response.StatusCode := 400;
      Response.Content := 'request error 400 - bad request (bad method type)';
      Response.SendResponse;
    end;
  end;
end;

procedure TModulWEB.ShowMyCategories(Request: TWebRequest; Response: TWebResponse);
var
  newDBconnection: TADOConnection;
  ADOQuery: TADOQuery;
  json_array: TJSONArray;
  main_object: TJSONObject;
  category_object: TJSONObject;
  is_everything_OK: Boolean;
  error_description: String;
  response_code: Integer;
  group_id: string;
begin
  CoInitialize(nil);
  newDBconnection := TADOConnection.Create(Self);
  MainForm.connections_count.value:=MainForm.connections_count.value+1;
  newDBconnection.Close;
  newDBconnection.ConnectionString := MainForm.DB_connection_string;
  newDBconnection.ConnectionTimeout:=10;
  newDBconnection.CommandTimeout:=30;
  newDBconnection.LoginPrompt :=False;
  newDBconnection.Connected   := True;
  newDBconnection.Open;
  ADOQuery:=TADOQuery.Create(Self);
  ADOQuery.Connection:=newDBconnection;
  ADOQuery.CommandTimeout:=30;

  is_everything_OK :=True;
  group_id := Request.QueryFields.values['group_id'];

  if group_id='' then
   Begin
    is_everything_OK := False;
    error_description:= 'The required parameters were not provided';
   End;

  if is_everything_OK=True then
   Begin
    response_code:=200;

    try
      try
        ADOQuery.Close;
        ADOQuery.SQL.Text := 'SELECT * FROM categories WHERE id_group=' + group_id;
        ADOQuery.Open;
        if ADOQuery.RecordCount > 0 then
         Begin
          main_object := TJSONObject.Create;
          json_array  := TJSONArray.Create;

          ADOQuery.First;
          Repeat
           category_object := TJSONObject.Create;

           category_object.AddPair('main_id',TJSONNumber.Create(ADOQuery.FieldByName('main_id').AsInteger));
           category_object.AddPair('own_id' ,TJSONNumber.Create(ADOQuery.FieldByName('own_id').AsInteger));
           category_object.AddPair('name'   ,TJSONString.Create(Trim(ADOQuery.FieldByName('name').AsString)));
           category_object.AddPair('visible',TJSONBool.Create(True));

           json_array.AddElement(category_object);
           ADOQuery.Next;
          Until ADOQuery.Eof;

          main_object.AddPair('categories',json_array);

          Response.StatusCode   := response_code;
          Response.ContentType  := 'application/json; charset=utf-8';
          Response.Content      := main_object.ToString;

         End
        else response_code := 404;
        ADOQuery.Close;
      finally

      end;
    except
      response_code := 400;
    end;

    if response_code<>200 then
     Begin
      Response.StatusCode := response_code;
      if response_code=400 then
       Response.Content := 'REQUEST ERROR - 400 - Bad request';
      if response_code=404 then
       Response.Content := 'REQUEST ERROR - 404 - Not Found';
     End;

   End
  else
   Begin
    Response.StatusCode := 400;
    Response.Content := 'REQUEST ERROR - 400 - '+error_description;
   End;

 ADOQuery.Free;
 newDBconnection.Close;
 newDBconnection.Free;
 CoUninitialize;
 MainForm.connections_count.value:=MainForm.connections_count.value-1;
end;

procedure TModulWEB.WebModule1DefaultHandlerAction(Sender: TObject; Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
 Response.StatusCode := 400;
 Response.Content := 'REQUEST ERROR - 400!';
 Response.SendResponse;
end;

function TModulWEB.EscapeString(const AValue: string): string;
const
  ESCAPE = '\';
  // QUOTATION_MARK = '"';
  REVERSE_SOLIDUS = '\';
  SOLIDUS = '/';
  BACKSPACE = #8;
  FORM_FEED = #12;
  NEW_LINE = #10;
  CARRIAGE_RETURN = #13;
  HORIZONTAL_TAB = #9;
var
  AChar: Char;
begin
  Result := '';
  for AChar in AValue do
  begin
    case AChar of
      // !! Double quote (") is handled by TJSONString
      // QUOTATION_MARK: Result := Result + ESCAPE + QUOTATION_MARK;
      REVERSE_SOLIDUS: Result := Result + ESCAPE + REVERSE_SOLIDUS;
      SOLIDUS: Result := Result + ESCAPE + SOLIDUS;
      BACKSPACE: Result := Result + ESCAPE + 'b';
      FORM_FEED: Result := Result + ESCAPE + 'f';
      NEW_LINE: Result := Result + ESCAPE + 'n';
      CARRIAGE_RETURN: Result := Result + ESCAPE + 'r';
      HORIZONTAL_TAB: Result := Result + ESCAPE + 't';
      else
      begin
        if (Integer(AChar) < 32) or (Integer(AChar) > 126) then
          Result := Result + ESCAPE + 'u' + IntToHex(Integer(AChar), 4)
        else
          Result := Result + AChar;
      end;
    end;
  end;
end;

end.
