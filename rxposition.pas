unit rxposition;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, ExtCtrls, JLabeledFloatEdit, GeoJson, IniFiles;

type

  { TFRxPosition }

  TFRxPosition = class(TForm)
    btnCancel: TBitBtn;
    btnOk: TBitBtn;
    eLatitude: TJLabeledFloatEdit;
    eLongitude: TJLabeledFloatEdit;
    Panel1: TPanel;
    Panel2: TPanel;
    StaticText1: TStaticText;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure eLatitudeChange(Sender: TObject);
    procedure eLongitudeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    mModified: boolean;
    mConfDir: string;
  public

  end;

var
  FRxPosition: TFRxPosition;

implementation

{ TFRxPosition }

procedure TFRxPosition.btnCancelClick(Sender: TObject);
begin
  if mModified then
  begin
    if MessageDlg('Question', 'RX position was changed. Exit anyway?',
      mtConfirmation, [mbYes, mbNo], 0) = mrNo then
      exit;
  end;
  Close;
end;

procedure TFRxPosition.btnOkClick(Sender: TObject);
var
  geoJSON: TGeoJson;
  geoJsonData: TGEOJsonData;
  myIniFile: TiniFile;
begin
  if not mModified then
    Close;
  GeoJson := TGeoJson.Create;
  GeoJson.AddHeader;
  geoJsonData.Geometry.Gtype := 'Point';
  geoJsondata.Geometry.Latitude :=
    StringReplace(FloatToStr(eLatitude.Value), ',', '.', [rfReplaceAll]);
  geoJsondata.Geometry.Longitude :=
    StringReplace(FloatToStr(eLongitude.Value), ',', '.', [rfReplaceAll]);
  geoJsondata.Properties.Date := FormatDateTime(shortDateFormat, now);
  geoJsondata.Properties.Hour := FormatDateTime(ShortTimeFormat, now);
  geoJsondata.Properties.MMSI := '';
  geoJsondata.Properties.Name := 'RX position';
  geoJsondata.Properties.Description := '';
  geoJsondata.Properties.Last := '';
  geoJsondata.Properties.Comment := '';
  geoJsonData.Properties.Frequency := '';
  GeoJson.addData(geoJsonData, True);
  GeoJson.Addfooter;
  GeoJson.save('map/data/home.json');
  GeoJson.Free;
  myInifile := TIniFile.Create(mConfDir + '/yadd2map.conf');
  myInifile.WriteFloat('Rx position', 'latitude', eLatitude.Value);
  myInifile.WriteFloat('Rx position', 'longitude', eLongitude.Value);
  myIniFile.Free;
  Close;
end;

procedure TFRxPosition.eLatitudeChange(Sender: TObject);
begin
  mModified := True;
end;

procedure TFRxPosition.eLongitudeChange(Sender: TObject);
begin
  mModified := True;
end;

procedure TFRxPosition.FormCreate(Sender: TObject);
begin
  {$IFDEF WIN32}
  mConfDir := GetEnvironmentVariable('appdata') + DirectorySeparator +  'Yadd2Map' + DirectorySeparator;
  {$ENDIF}
end;

procedure TFRxPosition.FormShow(Sender: TObject);
var
  flname: String;
  myIniFile: TIniFile;
begin
try
  flname := mConfDir + 'yadd2map.conf';
  myIniFile := TIniFile.Create(flName);
  eLatitude.Value := myIniFile.ReadFloat('Rx position', 'latitude', 0);
  eLongitude.Value := myIniFile.ReadFloat('Rx position', 'longitude', 0);
  mModified := False;
  except
    on E : Exception do
    begin
       showmessage('Error:' + #13 + e.Message);
    end;
  end;
  myIniFile.free;
end;


initialization
  {$I rxposition.lrs}

end.
