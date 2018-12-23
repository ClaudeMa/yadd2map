unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, simpleipc, sqlite3conn, sqldb, LResources, Forms, Controls,
  shellApi, Graphics, Dialogs, StdCtrls, DateUtils, Buttons, lNetComponents,
  lNet, ExtCtrls, Menus, GeoJson, ComCtrls, EditBtn, ZConnection, ZDataset,
  RichMemo, JLabeledIntegerEdit, strutils, xquery, simpleinternet, fpHTTP,
  RxPosition, BrookFCLEventLogHandler, process, lclIntf,
  //{$IFDEF WINDOWS}
  w32internetaccess;
//{$ELSE}
// synapseinternetaccess;
//{$ENDIF}

type

  TShip = record
    MMSSI: string;
    Devise: string;
  end;

  TCoast = record
    MMSI: string;
    Country: string;
    Name: string;
    Latitude: string;
    Longitude: string;
  end;

  TLatLon = record
    Latitude: string;
    Longitude: string;
  end;

  TYAddUDPRecord = record
    rxId: string;
    rx: string;
    Fmt: string;
    MMSITo: string;
    Cat: string;
    MMSIFrom: string;
    TC1: string;
    TC2: string;
    Lat: string;
    Lon: string;
    Freq: string;
    EOS: string;
    CECC: string;
    Name: string;
  end;

  { TFormMain }

  TFormMain = class(TForm)
    BrookFCLEventLogHandler1: TBrookFCLEventLogHandler;
    btnClose: TBitBtn;
    btnMap: TBitBtn;
    btnUrl: TButton;
    ButtonConnect: TButton;
    cbYadd: TCheckBox;
    cbRemoteLogging: TCheckBox;
    cbHeard: TComboBox;
    cbWebServer: TCheckBox;
    eDateHeard: TDateEdit;
    EditSent: TEdit;
    editReceived: TEdit;
    editRemotehost: TEdit;
    editRemotePort: TEdit;
    eHttpPort: TJLabeledIntegerEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblUrl: TLabel;
    lable3: TLabel;
    MemoLogs: TRichMemo;
    MemoText: TRichMemo;
    mSaveLogBook: TMenuItem;
    mSettings: TMenuItem;
    mRxPosition: TMenuItem;
    panel1: TPanel;
    panelYadNet: TPanel;
    panelYadd: TPanel;
    PopupMenu1: TPopupMenu;
    ProgressBar1: TProgressBar;
    RemoteUDP: TLUDPComponent;
    webLed: TShape;
    TimerData: TTimer;
    YaddUDP: TLUDPComponent;
    EditPort: TEdit;
    LabelPort: TLabel;
    MainMenu1: TMainMenu;
    mExit: TMenuItem;
    MenuItemAbout: TMenuItem;
    MenuItemHelp: TMenuItem;
    mFile: TMenuItem;
    PageControl1: TPageControl;
    panelBottom: TPanel;
    Panel2: TPanel;
    rcvLed: TShape;
    sndLed: TShape;
    tabYadd: TTabSheet;
    tabLogs: TTabSheet;
    TimerQuit: TTimer;
    sConnection: TZConnection;
    sQuery: TZQuery;
    mapQuery: TZQuery;
    procedure btnCloseClick(Sender: TObject);
    procedure btnMapClick(Sender: TObject);
    procedure btnUrlClick(Sender: TObject);
    procedure cbRemoteLoggingChange(Sender: TObject);
    procedure cbYaddChange(Sender: TObject);
    procedure cbWebServerChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LTCPComponentError(const msg: string; aSocket: TLSocket);
    procedure LTCPComponentReceive(aSocket: TLSocket);
    procedure LTcpComponentDisconnect(aSocket: TLSocket);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure mExitClick(Sender: TObject);
    procedure mRxPositionClick(Sender: TObject);
    procedure mSaveLogBookClick(Sender: TObject);
    procedure TimerDataTimer(Sender: TObject);
    procedure TimerQuitTimer(Sender: TObject);
  private
    FNet: TLConnection;
    FRemoteNet: TLConnection;
    FIsServer: boolean;
    FRemoteLogging: boolean;
    FFnt: TFontParams;
    WebUrl: String;
    function YaddUdpRecord(buffer: string): TYaddUdpRecord;
    function GetLatLon(MMSI: string): TLatLon;
    function getShipName(AMmsi: string): string;
    function SaveLogRecord(LogRecord: TYAddUDPRecord): boolean;
    function genGeoJson: integer;
    function GetCoastInfo(AMmsi: string): TCoast;
    function GetIpAddrList(): string;
    procedure appendText(AMemo: TRichMemo; AStr: string; AColor: TColor = clBlack);
  public
  end;

const
  URL = 'https://www.marinetraffic.com/en/ais/details/ships/mmsi:';
  SHIP_COLOR = clBlue;
  COAST_COLOR = clGreen;
  ERROR_COLOR = clRed;

var
  FormMain: TFormMain;

implementation

uses BrookThread;

{ TFormMain }

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Timerdata.Enabled := false;
  sQuery.Close;
  mapQuery.Close;
  sConnection.Disconnect;
  CloseAction := caFree;
  BrookThread.Stop;
  if FRemoteNet.Connected then
  begin
    FRemoteNet.Disconnect;
  end;
  if FNet.Connected then
  begin
    CloseAction := caNone;
    FNet.Disconnect;
    TimerQuit.Enabled := True;
  end;
end;

procedure TFormMain.cbYaddChange(Sender: TObject);
begin
  if cbYadd.Checked then
  begin
    if FNet.Listen(StrToInt(EditPort.Text)) then
    begin
      Rcvled.Brush.Color := clGreen;
      FIsServer := True;
    end;
  end
  else
  begin
    Fnet.Disconnect;
    Rcvled.Brush.Color := clRed;
    FIsServer := false;
  end;
end;

procedure TFormMain.cbWebServerChange(Sender: TObject);
begin
     if cbWebServer.Checked then
     begin
       Weburl := 'http://' + trim(GetIpAddrList) + ':' + trim(eHttpPort.Text) + '/map';
       lblUrl.Caption:= 'URL : ' + weburl;
       btnUrl.Enabled:= true;
       BrookThread.Start(StrToInt(eHttpPort.Text));
       Webled.Brush.Color := clGreen;
       appendtext(MemoLogs,'Web server started on port ' + eHttpPort.Text, SHIP_COLOR);
     end
     else
     begin
        btnUrl.Enabled := false;
       lblUrl.Caption:= 'URL : ???';
        BrookThread.Stop;
        WebLed.Brush.Color := clRed;
        appendtext(MemoLogs,'Web server stopped', ERROR_COLOR);
     end;
end;

procedure TFormMain.btnCloseClick(Sender: TObject);
begin
  if MessageDlg('Question', 'Exit Yadd2Map?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    Close;
  end;
end;

procedure TFormMain.btnMapClick(Sender: TObject);
var
  nbRecord: integer = 0;
begin
  nbRecord := genGeoJson;
  if nbRecord > 0 then
  begin
    Appendtext(MemoLogs, FormatdateTime('dd/mm/yy hh:nn', now) +
      ':  manual update: ' + IntToStr(nbRecord) + ' record to show on map', SHIP_COLOR);
    if timerdata.Enabled = False then
      timerData.Enabled := True;
    if MessageDlg('Question', 'Open new web brownser?', mtConfirmation,
      [mbYes, mbNo], 0) = mrYes then
      ShellExecute(self.Handle, PChar('open'), PChar('map\map.html'),
        PChar(''), PChar(''), 1);
  end
  else
    ShowMessage('Nothing to show on map today');
end;

procedure TFormMain.btnUrlClick(Sender: TObject);
begin
  OpenURL(weburl);
end;

procedure TFormMain.cbRemoteLoggingChange(Sender: TObject);
begin
  if cbRemoteLogging.Checked then
  begin
    if FRemoteNet.Connect(EditRemoteHost.Text, StrToInt(EditRemotePort.Text)) then
    begin
      SndLed.Brush.Color := clGreen;
      FIsServer := True;
      FremoteLogging := True;
    end;
  end
  else
  begin
    FRemoteNet.Disconnect;
    FremoteLogging := false;
    FIsServer := false;
    SndLed.Brush.Color := clRed;
  end;
end;

procedure TFormMain.LTCPComponentError(const msg: string; aSocket: TLSocket);
begin
  AppendText(MemoLogs, FormatdateTime('dd/mm/yy hh:nn', now) + ': ' + msg, ERROR_COLOR);
end;

procedure TFormMain.LTCPComponentReceive(aSocket: TLSocket);
var
  s: string;
  mRecord: TYaddUdpRecord;
  mLatLon: TLatLon;
  n: integer;
  mmsiType: string;
  mmsicolor: TColor;
  coast: TCoast;
begin
  if aSocket.GetMessage(s) > 0 then
  begin
    Appendtext(MemoText, s);
    editReceived.Text := IntToStr(StrToInt(editReceived.Text) + 1);
    if FRemoteLogging then
    begin
      if FRemoteNet is TLUdp then
      begin
        if FIsServer then;
        begin
          n := TLUdp(FRemoteNet).SendMessage(s, editRemoteHost.Text);
          editSent.Text := IntToStr(StrToInt(editSent.Text) + 1);
          if n < Length(s) then
            Appendtext(MemoLogs, FormatdateTime('dd/mm/yy hh:nn', now) +
              ': Error on send [' + IntToStr(n) + ']', ERROR_COLOR);
        end;
      end;
    end;
    mRecord := YaddUdpRecord(s);
    if AnsiContainsText(mrecord.MMSIFrom, '~') then
    begin
      Appendtext(Memotext, 'Incomplete MMSI: skipped', ERROR_COLOR);
      exit;
    end;
    if leftStr(mRecord.MMSIFrom, 1) <> '0' then
    begin
      mmsiType := 'SHIP';
      mmsicolor := SHIP_COLOR;
      mLatLon := GetLatLon(mRecord.MMSIFrom);
      mRecord.Lat := mLatLon.Latitude;
      mRecord.Lon := mlatLon.Longitude;
      mrecord.Name := GetShipName(mRecord.MMSIFrom);
    end
    else if leftStr(mRecord.MMSIFrom, 1) = '0' then
    begin
      mmsiType := 'COAST';
      mmsicolor := COAST_COLOR;
      coast := GetCoastInfo(mRecord.MMSIFrom);
      mrecord.Name := coast.Name + ' (' + coast.Country + ')';
      mRecord.Lat := coast.Latitude;
      mRecord.Lon := coast.Longitude;
    end;
    Appendtext(Memotext, FormatdateTime('dd/mm/yy hh:nn', now) +
      ': ' + mmsiType + ' "' + mrecord.Name + '" at ' + mRecord.Lat +
      '/' + mRecord.Lon, mmsicolor);
    SaveLogRecord(mrecord);
  end;
end;

procedure TFormMain.LTcpComponentDisconnect(aSocket: TLSocket);
begin
  AppendText(MemoLogs, 'Connection lost', ERROR_COLOR);
end;

procedure TFormMain.MenuItemAboutClick(Sender: TObject);
begin
  MessageDlg('Yadd To Map - copyright(c) 2018 under the Gnu Public Licence V3',
    mtInformation, [mbOK], 0);
end;

procedure TFormMain.mExitClick(Sender: TObject);
begin
  if MessageDlg('Question', 'Exit Yadd2Map?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    Close;
  end;
end;

procedure TFormMain.mRxPositionClick(Sender: TObject);
var
  FRXPosition: TFRxPosition;
begin
  FRxPosition := TFRxPosition.Create(self);
  FRxPosition.ShowModal;
  FRxPosition.Free;
end;

procedure TFormMain.mSaveLogBookClick(Sender: TObject);
const
  UTF8BOM: array[0..2] of byte = ($EF, $BB, $BF);
var
  UTF8Str: UTF8String;
  fileStream: TFileStream;
  fileName: string;
begin
  UTF8Str := UTF8Encode(MemoLogs.Text);
  fileName := formatDateTime('YYMMDD', now) + '_yadd2map.log';
  fileStream := TFileStream.Create('logs' + DirectorySeparator + fileName, fmCreate);
  try
    fileStream.WriteBuffer(UTF8BOM[0], SizeOf(UTF8BOM));
    fileStream.WriteBuffer(PAnsiChar(UTF8Str)^, Length(UTF8Str));
  finally
    fileStream.Free;
  end;
end;


procedure TFormMain.TimerDataTimer(Sender: TObject);
begin
  AppendText(MemoLogs, FormatdateTime('dd/mm/yy hh:nn', now) +
    ': update : ' + IntToStr(GenGeoJson) + ' records on map');
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FNet := YaddUDP;
  FRemoteNet := RemoteUDP;
  FIsServer := False;
  FRemoteLogging := False;
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  MemoText.Clear;
  MemoLogs.GetTextAttributes(0, FFnt);
  MemoLogs.Clear;
  try
    sConnection.Database := GetCurrentDir + '/db/logbook.db';
    sconnection.Connect;
    Appendtext(MemoLogs, FormatdateTime('dd/mm/yy hh:nn', now) +
      ': Connected to database ' + sConnection.Database);
  except
    On e: Exception do
    begin
      Appendtext(MemoLogs, e.Message, ERROR_COLOR);
      ShowMessage('Unable to connect to database "' + GetCurrentDir + '/db/logbook.db". Data will not be save');
    end;
  end;
end;

procedure TFormMain.TimerQuitTimer(Sender: TObject);
begin
  Close;
end;

function TFormMain.YaddUdpRecord(buffer: string): TYaddUdpRecord;
var
  arrs: array of string;
begin
  arrs := buffer.Split(';');
  Result.RxId := arrs[0];
  Result.Rx := arrs[1];
  Result.Fmt := arrs[2];
  Result.MMSITo := arrs[3];
  Result.Cat := arrs[4];
  Result.MMSIFrom := arrs[5];
  Result.TC1 := arrs[6];
  Result.TC2 := arrs[7];
  Result.FREQ := arrs[9];
  Result.EOS := arrs[10];
  Result.CECC := arrs[11];
end;

function TFormMain.GetLatLon(MMSI: string): TLatLon;
var
  v: IXQValue;
  arrs: array of string;
  s: string;
begin
  try
    for v in Query('doc("' + URL + MMSI + '")//a/.') do
    begin
      if AnsiContainsText(v.toString, '°') then
      begin
        arrs := v.toString.Split('/');
        s := StringReplace(Trim(arrs[0]), '°', '', [rfReplaceAll]);
        Result.Latitude := s;
        s := StringReplace(Trim(arrs[1]), '°', '', [rfReplaceAll]);
        Result.Longitude := s;
      end;
    end;
  except
    On e: Exception do
    begin
      AppendText(memoLogs, FormatdateTime('dd/mm/yy hh:nn', now) +
        ': ' + e.Message, ERROR_COLOR);
      Result.Latitude := '0';
      Result.Longitude := '0';
    end;
  end;
end;

function TFormMain.getShipName(AMmsi: string): string;
var
  v: IXQValue;
begin
  try
    for v in Query('doc("' + URL + Ammsi + '")//h1/.') do
      Result := v.toString;
  except
    On e: Exception do
    begin
      memoLogs.Append(FormatDateTime('hh:nn', now) + ': ' + e.Message);
      Result := 'UNKNOW';
    end;
  end;
end;

procedure TFormMain.appendText(AMemo: TRichMemo; AStr: string;
  AColor: TColor = clBlack);
begin
  FFnt.Color := AColor;
  with AMemo do
  begin
    Lines.Add(AStr);
    SelStart := Length(Lines.Text);
    SetTextAttributes(selstart - Length(AStr) - 1, selstart, FFnt);
  end;
end;

function TFormMain.SaveLogRecord(LogRecord: TYAddUDPRecord): boolean;
var
  querySQL: string;
begin
  try
    querySQL :=
      'INSERT INTO logs (log_date, log_time, rx_frequencie, fmt, cat, mmsi_from, name_from, mmsi_to, tc1, tc2, latitude, longitude, frequencie, eos, cecc) VALUES ("' + FormatDateTime('yyyy-mm-dd', now) + '", "' + FormatDateTime('hh:nn:00', now) + '", "' + logRecord.rx + '", "' + logRecord.Fmt + '", "' + logRecord.Cat + '", "' + logRecord.MMSIFrom + '", "' + logRecord.Name + '", "' + logRecord.MMSITo + '", "' + logRecord.TC1 + '", "' + logRecord.TC2 + '", "' + logRecord.Lat + '", "' + logRecord.Lon + '", "' + logRecord.Freq + '", "' + logRecord.EOS + '", "' + logRecord.CECC + '");';
    sQuery.SQL.Clear;
    sQuery.SQL.Add(querySQL);
    sQuery.ExecSQL;
    Result := True;
  except
    on e: Exception do
    begin
      Appendtext(MemoLogs, FormatDateTime('hh:nn', now) + ': ' +
        squery.SQL.Text, ERROR_COLOR);
      Appendtext(MemoLogs, FormatDateTime('hh:nn', now) + ': ' + e.Message, ERROR_COLOR);
      Result := False;
    end;
  end;
end;

function TFormMain.genGeoJson: integer;
var
  queryString: string;
  myYear, myMonth, myDay: word;
  myHour, myMinute, mySecond, myMilli: word;
  geoJSON: TGeoJson;
  geoJsonData: TGEOJsonData;
  nbRecord: integer = 0;
  prevdate: string = '';
  where: string;
  startTime: string;
  minute: string;
  hh: integer;
  recordCount: Integer;
  i: Integer;
begin
  if CompareDate(eDateHeard.Date, Now) = 0 then
  begin
    if cbHeard.ItemIndex = 4 then
    begin
      where := ' WHERE log_date = "' + FormatDateTime('yyyy-mm-dd', now) +
        '" AND latitude <> 0  AND longitude <> 0 GROUP BY mmsi_from ORDER BY name_from;';
    end
    else
    begin
      DecodeDateTime(now, myYear, myMonth, myDay,
        myHour, myMinute, mySecond, myMilli);
      if myMinute < 10 then
        minute := '0' + IntToStr(myMinute)
      else
        minute := IntToStr(myMinute);
      case cbHeard.ItemIndex of
        0:
          hh := myHour - 1;
        1:
          hh := myHour - 2;
        2:
          hh := myHour - 6;
        3:
          hh := myHour - 12;
      end;
      if hh < 0 then
      begin
        prevDate := FormatDateTime('yyyy-mm-dd', IncDay(Today, -1));
        hh := 24 + hh;
      end;
      if hh < 10 then
        startTime := '0' + IntToStr(hh) + ':' + minute + ':00'
      else
        startTime := IntToStr(hh) + ':' + minute + ':00';
      if prevDate <> emptyStr then
        where := ' PRINTF("%s %s", log_date, log_time) > "' + prevDate +
          ' ' + startTime + '" '
      else
        where := ' PRINTF("%s %s", log_date, log_time) > "' +
          FormatDateTime('yyyy-mm-dd', now) + ' ' + startTime + '" ';
    end;
  end
  else
  begin
    where := ' log_date = "' + FormatDateTime('yyyy-mm-dd', eDateHeard.Date) + '" ';
  end;
  queryString := 'SELECT * FROM logs WHERE ' + where +
    ' AND latitude <> 0  AND longitude <> 0 GROUP BY mmsi_from ORDER BY name_from;';
  mapQuery.SQL.Clear;
  mapQuery.SQL.Add(queryString);
  try
    mapQuery.Open;
  except
    On e: Exception do
    begin
      Appendtext(memoLogs, FormatdateTime('dd/mm/yy hh:nn', now) +
        ': ' + e.Message, ERROR_COLOR);
      Result := 0;
      exit;
    end;
  end;
  RecordCount := MapQuery.RecordCount;
  i := 1;
  if RecordCount > 0 then
  begin
    ProgressBar1.Max := mapQuery.RecordCount;
    GeoJson := TGeoJson.Create;
    GeoJson.AddHeader;
    while not mapquery.EOF do
    begin
      geoJsonData.Geometry.Gtype := 'Point';
      geoJsondata.Geometry.Latitude :=
        StringReplace(mapQuery.FieldByName('latitude').AsString, ',',
        '.', [rfReplaceAll]);
      geoJsondata.Geometry.Longitude :=
        StringReplace(mapQuery.FieldByName('longitude').AsString, ',',
        '.', [rfReplaceAll]);
      geoJsondata.Properties.Date := mapQuery.FieldByName('log_date').AsString;
      geoJsondata.Properties.Hour := mapQuery.FieldByName('log_time').AsString;
      geoJsondata.Properties.Name := mapQuery.FieldByName('name_from').AsString;
      geoJsondata.Properties.MMSI := mapQuery.FieldByName('mmsi_from').AsString;
      if leftStr(geoJsondata.Properties.MMSI, 1) <> '0' then
        geoJsondata.Properties.Description := 'SHIP'
      else
        geoJsondata.Properties.Description := 'COAST';
      mapQuery.Next;
      if (geoJsonData.Geometry.Longitude <> '0') and
        (geoJsonData.Geometry.Latitude <> '0') then
      begin
        if MapQuery.EOF then
          GeoJson.addData(geoJsonData, true)
        else
          GeoJson.addData(geoJsonData);
      end;
      progressbar1.StepIt;
      Inc(nbRecord);
    end;
    GeoJson.Addfooter;
    GeoJson.save('map/data/data.json');
    GeoJson.Free;
    mapQuery.Close;
    Progressbar1.Position := 0;
    Result := nbRecord;
  end
  else
  begin
    AppendText(MemoLogs, FormatDateTime('hh:nn', now) + ': No data for Geojson',
      ERROR_COLOR);
    Result := 0;
  end;
end;

function TFormMain.GetCoastInfo(AMmsi: string): TCoast;
begin
  sQuery.SQL.Clear;
  sQuery.SQL.Add('SELECT * FROM coasts WHERE mmsi = "' + AMmsi + '";');
  sQuery.Open;
  if sQuery.RecordCount > 0 then
  begin
    Result.MMSI := sQuery.FieldByName('mmsi').AsString;
    Result.Country := sQuery.FieldByName('country').AsString;
    Result.Name := sQuery.FieldByName('name').AsString;
    Result.Latitude := sQuery.FieldByName('latitude').AsString;
    Result.Longitude := sQuery.FieldByName('longitude').AsString;
  end
  else
  begin
    Result.MMSI := AMmsi;
    Result.Country := '?';
    Result.Name := 'Unknow';
    Result.Latitude := '0';
    Result.Longitude := '0';
  end;
end;

function TFormMain.GetIpAddrList(): string;
var
  AProcess: TProcess;
  s: string;
  sl: TStringList;
  i, n: integer;

begin
  Result:='';
  sl:=TStringList.Create();
  {$IFDEF WINDOWS}
  AProcess:=TProcess.Create(nil);
  AProcess.CommandLine := 'ipconfig.exe';
  AProcess.Options := AProcess.Options + [poUsePipes, poNoConsole];
  try
    AProcess.Execute();
    Sleep(500); // poWaitOnExit don't work as expected
    sl.LoadFromStream(AProcess.Output);
  finally
    AProcess.Free();
  end;
  for i:=0 to sl.Count-1 do
  begin
    if (Pos('IPv4', sl[i])=0) and (Pos('IP-', sl[i])=0) and (Pos('IP Address', sl[i])=0) then Continue;
    s:=sl[i];
    s:=Trim(Copy(s, Pos(':', s)+1, 999));
    if Pos(':', s)>0 then Continue; // IPv6
    Result:=Result+s+'  ';
  end;
  {$ENDIF}
  {$IFDEF UNIX}
  AProcess:=TProcess.Create(nil);
  AProcess.CommandLine := '/sbin/ifconfig';
  AProcess.Options := AProcess.Options + [poUsePipes, poWaitOnExit];
  try
    AProcess.Execute();
    sl.LoadFromStream(AProcess.Output);
  finally
    AProcess.Free();
  end;

  for i:=0 to sl.Count-1 do
  begin
    n:=Pos('inet addr:', sl[i]);
    if n=0 then Continue;
    s:=sl[i];
    s:=Copy(s, n+Length('inet addr:'), 999);
    Result:=Result+Trim(Copy(s, 1, Pos(' ', s)))+'  ';
  end;
  {$ENDIF}
  sl.Free();
end;

initialization
  {$I main.lrs}

end.
