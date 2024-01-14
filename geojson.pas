unit geojson;

{$mode objfpc}

interface

uses
  Classes, SysUtils;

type
  TGEOJsonGeometry = record
    Gtype: string;
    Latitude: string;
    Longitude: string;
  end;

  TGEOJsonProperties = record
    MMSI: string;
    Name: string;
    Description: string;
    Date: string;
    Hour: string;
    Frequency: String;
    Last: String;
    Comment: String;
    uptodate: Integer;
  end;

  TGEOJsonData = record
    Geometry: TGEOJsonGeometry;
    Properties: TGEOJsonProperties;
  end;

  TGEOJson = class(TObject)
  private
    fileData: TStringList;
  public
    constructor Create;
    procedure AddHeader;
    procedure Addfooter;
    procedure AddData(AGeoJsonData: TGEOJsonData; ALast: boolean = False);
    procedure Save(AFileName: string);

  end;

const
  TAB = #9;
  TABTAB = TAB + TAB;
  TABTABTAB = TAB + TAB + TAB;

implementation

constructor TGEOJson.Create;
begin
  fileData := TStringList.Create;
end;

procedure TGEOJson.ADDheader;
begin
  fileData.Add('{');
  fileData.Add(TAB + '"type": "FeatureCollection",');
  fileData.Add(TAB + '"features": [');
end;

procedure TGEOJson.ADDFooter;
begin
  fileData.Add(TAB + ']');
  fileData.Add('}');
end;

procedure TGEOJson.addData(AGeoJsonData: TGEOJsonData; ALast: boolean = False);
begin
  fileData.Add(TABTAB + '{');
  fileData.Add(TABTABTAB + '"type": "Feature",');
  fileData.Add(TABTABTAB + '"properties": {');
  fileData.Add(TABTABTAB + TAB + '"Date": "' + AGeoJsonData.Properties.Date + '",');
  fileData.Add(TABTABTAB + TAB + '"Hour": "' + AGeoJsonData.Properties.Hour + '",');
  fileData.Add(TABTABTAB + TAB + '"Mmsi": "' + AGeoJsonData.Properties.MMSI + '",');
  fileData.Add(TABTABTAB + TAB + '"Name": "' + AGeoJsonData.Properties.Name + '",');
  fileData.Add(TABTABTAB + TAB + '"Frequency": "' + AGeoJsonData.Properties.Frequency + '",');
  fileData.Add(TABTABTAB + TAB + '"Last": "' + AGeoJsonData.Properties.Last + '",');
  fileData.Add(TABTABTAB + TAB + '"uptodate": "' + IntToStr(AGeoJsonData.Properties.uptodate) + '",');
  fileData.Add(TABTABTAB + TAB + '"Comment": "' + AGeoJsonData.Properties.Comment + '",');
  fileData.Add(TABTABTAB + TAB + '"Description": "' +
    AGeoJsonData.Properties.Description + '"');
  fileData.Add('');
  fileData.Add(TABTABTAB + '},');
  fileData.Add(TABTABTAB + '"geometry": {');
  fileData.Add(TABTABTAB + TAB + '"type": "' + AGeoJsonData.Geometry.Gtype + '",');
  fileData.Add(TABTABTAB + TAB + '"coordinates": [' + AGeoJsonData.Geometry.Longitude +
    ',' + AGeoJsonData.Geometry.Latitude + ']');
  fileData.Add(TABTABTAB + '}');
  if ALast then
    fileData.Add(TABTAB + '}')
  else
    fileData.Add(TABTAB + '},');
end;

procedure TGEOJson.save(AFileName: string);
begin
  fileData.SaveToFile(AFileName);
  fileData.Free;
end;


end.
