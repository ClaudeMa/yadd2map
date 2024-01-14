unit aprsfi;

{$mode objfpc}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, kmemo, LCLIntf, Buttons, IniFiles, fpjson, jsonparser, fphttpclient,
  OpenSslsockets, strUtils;

type

  { TFAprsfi }

  TFAprsfi = class(TForm)
    btnCancel: TBitBtn;
    btnOk: TBitBtn;
    Button1: TButton;
    eApiKey: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label2Click(Sender: TObject);
  private
    mConfDir: string;
    mApiKey: string;
  public
    property ApiKey: string read mApiKey write mApiKey;
  end;

var
  FAprsfi: TFAprsfi;

implementation

{ TFAprsfi }

procedure TFAprsfi.Button1Click(Sender: TObject);
begin
  openUrl('https://aprs.fi/account/');
end;

procedure TFAprsfi.Label2Click(Sender: TObject);
begin
  openUrl('https://aprs.fi/');
end;

procedure TFAprsfi.FormCreate(Sender: TObject);
var
  myIni: TInifile;
begin
  mApiKey := '';
  eApiKey.Clear;
  {$IFDEF WIN32}
  mConfDir := GetEnvironmentVariable('appdata') + DirectorySeparator +  'Yadd2Map' + DirectorySeparator;
  {$ENDIF}
 {$ifdef Unix}
  ConfigFilePath := GetAppConfigFile(False) + '.conf';
 {$endif}
  myIni := TIniFile.Create(mConfDir + 'yadd2map.conf' );
  try
    mApiKey := myIni.ReadString('API', 'ApiKey', '');
    eApiKey.Text := mApiKey;
  finally
    myIni.Free;
  end;
end;

procedure TFAprsfi.btnOkClick(Sender: TObject);
var
  myIni: TIniFile;
  AprsFiUrl: string;
  httpClient: TFPHTTPClient;
  rawjson: string;
begin
  if trim(eApiKey.Text) = emptyStr then
  begin
    ShowMessage('the API key is required');
    eApiKey.SetFocus;
    exit;
  end;
  AprsFiUrl := 'https://api.aprs.fi/api/get?name=F4IKH&what=loc&apikey=' +
    eApiKey.Text + '&format=json';
  httpClient := TFPHTTPClient.Create(nil);
  httpClient.AddHeader('Accept', 'application/json');
  httpClient.AddHeader('Content-Type', 'application/json');
  try
    rawJson := httpClient.Get(AprsFiUrl);
    httpClient.Free;
  except
    ShowMessage('http request error please retry');
    exit;
  end;
  if AnsiContainsStr(rawjSon, 'fail') then
  begin
    ShowMessage('Wrong API KEY. Please retry');
    eApiKey.SetFocus;
    exit;
  end;
  myIni := TIniFile.Create(mConfDir + 'yadd2map.conf');
  try
    myIni.WriteString('API', 'ApiKey', eApiKey.Text);
  finally
    myIni.Free;
  end;
  mApiKey := eApiKey.Text;
  Close;
end;

procedure TFAprsfi.btnCancelClick(Sender: TObject);
begin
  Close;
end;

initialization
  {$I aprsfi.lrs}

end.
