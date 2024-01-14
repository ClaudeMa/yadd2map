unit vessel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, Dateutils;

type
  TLatLon = record
    Latitude: string;
    Longitude: string;
  end;

  TVessel = class(TObject)
  private
    aLatLon: TlatLon;
    aVesselName: string;
    aVesselMmsi: string;
    aLastDate: TdateTime;
    aVesselComment: string;
  public
    constructor Create;
    procedure setVesselData(rawJson: string);
    property Position: TlatLon read aLatLon write aLatlon;
    property Name: string read aVesselName write aVesselname;
    property Mmsi: string read aVesselMmsi write aVesselMmsi;
    property LastHeard: TdateTime read aLastDate write aLastDate;
    property Comment: string read aVesselComment write aVesselComment;

  end;

implementation

constructor Tvessel.Create;
begin
  aLatlon.Latitude := '0';
  aLatlon.Longitude := '0';
  aVesselName := '';
  aVesselMmsi := '';
  aLastDate := UnixToDateTime(3600);
end;

procedure Tvessel.setVesselData(rawJson: ansistring);
var
  jsonData: TJSONData;
  entries: TJSONArray;
  entriesObject: TJSONOBject;
  found: integer;
begin
  jsonData := GETJson(rawJson);
  if jSonData.JSONType = jtObject then
  begin
    found := TJSONObject(jSonData).Items[3].AsInteger;
    if found = 0 then
    begin
      aVesselname := 'Not Found';
      exit;
    end;
    entries := TJSONARRAY(jSonData.Items[4]);
    entriesObject := TJSONObject(entries.Items[0]);
    aVesselName := TJSONObject(entriesObject).Items[1].AsString;
    aVesselMmsi := TJSONObject(entriesObject).Items[2].AsString;
    aVesselComment := TJSONObject(entriesObject).Items[12].AsString;
    alatLon.Latitude := TJSONObject(entriesObject).Items[6].AsString;
    aLatLon.Longitude := TJSONObject(entriesObject).Items[7].AsString;
    aLastDate := UnixToDateTime(TJSONObject(entriesObject).Items[5].AsInteger);
  end;
end;

end.

