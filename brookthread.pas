unit BrookThread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

procedure Start(const APort: Integer);
procedure Stop;

implementation

uses
  BrookUtils, BrookFCLHttpAppBroker, BrookApplication,
  fpmimetypes,
  BrookHTTPConsts,
  BrookStaticFileBroker,
  ActionUpdate,
  ActionMap;

type

  { TBrookThread }

  TBrookThread = class(TThread)
  private
    FPort: Integer;
    PublicHTMLDir: string;
  public
    constructor Create(const ASuspended: Boolean);
    procedure Execute; override;
    property Port: Integer read FPort write FPort;
  end;

constructor TBrookThread.Create(const ASuspended: Boolean);
begin
  inherited Create(ASuspended);
  MimeTypes.LoadFromFile('mime.types');
  PublicHTMLDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))+'map');
  BrookSettings.Charset := BROOK_HTTP_CHARSET_UTF_8;
  BrookSettings.Page404File := PublicHTMLDir + '404.html';
  BrookSettings.Page500File := PublicHTMLDir + '500.html';
  BrookStaticFileRegisterDirectory('/js/', PublicHTMLDir + 'js');
  BrookStaticFileRegisterDirectory('/data/', PublicHTMLDir + 'data');
  BrookStaticFileRegisterDirectory('/img/', PublicHTMLDir + 'img');
  //BrookSettings.Port := 8000;
end;

procedure TBrookThread.Execute;
begin
  BrookSettings.Port := FPort;
  BrookApp.Run;
end;

var
  LBrookThread: TBrookThread;

procedure Start(const APort: Integer);
begin
  LBrookThread := TBrookThread.Create(true);
  LBrookThread.Port := Aport;
  LBrookThread.FreeOnTerminate := true;
  LBrookThread.Start;
end;

procedure Stop;
var
  LApp: TBrookHttpApplication;
begin
  if Assigned(LBrookThread) then begin
    LApp := (BrookApp.Instance as TBrookHttpApplication);
    LApp.Terminate;
    BrookApp.Terminate;
    LBrookThread.Terminate;
  end;
end;

end.

