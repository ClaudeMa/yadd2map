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
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure eLatitudeChange(Sender: TObject);
    procedure eLongitudeChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    mModified: boolean;
    mConfDir: String;
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
    if MessageDlg('Question', 'RX position was changed. Quit anyway?',
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
  geoJsondata.Properties.Date := FormatDateTime('dd/mm/yyyy', now);
  geoJsondata.Properties.Hour := FormatDateTime('hh/nn/00', now);
  geoJsondata.Properties.MMSI := '';
  geoJsondata.Properties.Name := 'RX position';
  geoJsondata.Properties.Description := '';
  GeoJson.addData(geoJsonData, True);
  GeoJson.Addfooter;
  GeoJson.save('map/data/home.json');
  GeoJson.Free;
  myInifile := TIniFile.Create(mConfDir + '/yaddtomap.conf');
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

procedure TFRxPosition.FormShow(Sender: TObject);
var
  myIniFile: TIniFile;
begin
  mConfDir := GetAppConfigFile(false);
  myIniFile := TIniFile.Create(mConfDir + '/yaddtomap.conf');
  eLatitude.Value := myIniFile.ReadFloat('Rx position', 'latitude', 0);
  eLongitude.Value := myIniFile.ReadFloat('Rx position', 'longitude', 0);
  mModified := False;
end;


initialization
  {$I rxposition.lrs}

end.
