unit ActionUpdate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BrookAction, ZConnection, ZDataset, GeoJson, dateutils;

type

  { THello }

  TUpdate = class(TBrookAction)
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Get; override;
  private
    Connection: TZConnection;
    Query: TZQuery;
    function genGeoJson(AQuery: TZQuery): integer;


  end;


implementation

{ TUpdate }

constructor TUpdate.Create;
begin
  inherited Create;
  Connection := TZConnection.Create(nil);
  Connection.Database := GetCurrentDir + DirectorySeparator + 'logbook.db';
  Connection.Protocol := 'sqlite-3';
  Connection.Connect;
  Query := TZQuery.Create(nil);
  Query.Connection := Connection;
end;

destructor TUpdate.Destroy;
begin
  Query.Free;
  Connection.Free;
  inherited Destroy;
end;

procedure TUpdate.Get;
var
  I: integer;
  paramName: string;
  paramValue: string;
  curHour: word;
  curMinute: word;
  hh, mm: string;
  where: string;
begin
  try
    for I := 0 to Pred(Params.Count) do
    begin
      Params.GetNameValue(I, paramName, paramValue);
      if paramname = 'hour' then
      begin
        curHour := HourOfTheDay(now);
        curMinute := MinuteOfTheDay(now);
        curhour := curHour - StrToInt(paramValue);
        if curHour < 10 then
          hh := '0' + IntToStr(curHour)
        else
          hh := IntToStr(curhour);
        if curminute < 0 then
          mm := '0' + IntToStr(curMinute)
        else
          mm := IntToStr(curminute);
        where := ' AND log_time > "' + hh + ':' + mm + ':00"';
      end;
    end;

    Query.SQL.Clear;
    Query.SQL.Add('SELECT * FROM logs WHERE log_date = "2018-04-26"' + where + ';');
    Query.Open;
    if Query.RecordCount = 0 then
      Write('no data')
    else
    begin
      genGeoJson(query);
      render('/map/index.html');
    end;
  except
    on e: Exception do
    begin
      Write('Error');
      Write(e.Message);
    end;
  end;
end;

function TUpdate.genGeoJson(AQuery: TZQuery): integer;
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
begin
  GeoJson := TGeoJson.Create;
  GeoJson.AddHeader;
  while not AQuery.EOF do
  begin
    geoJsonData.Geometry.Gtype := 'Point';
    geoJsondata.Geometry.Latitude :=
      StringReplace(AQuery.FieldByName('latitude').AsString, ',',
      '.', [rfReplaceAll]);
    geoJsondata.Geometry.Longitude :=
      StringReplace(AQuery.FieldByName('longitude').AsString, ',',
      '.', [rfReplaceAll]);
    geoJsondata.Properties.Date := AQuery.FieldByName('log_date').AsString;
    geoJsondata.Properties.Hour := AQuery.FieldByName('log_time').AsString;
    geoJsondata.Properties.Name := AQuery.FieldByName('name_from').AsString;
    geoJsondata.Properties.MMSI := AQuery.FieldByName('mmsi_from').AsString;
    geoJsondata.Properties.Frequency := AQuery.FieldByName('rx_frequencie').AsString;
    if leftStr(geoJsondata.Properties.MMSI, 1) <> '0' then
      geoJsondata.Properties.Description := 'SHIP'
    else
      geoJsondata.Properties.Description := 'COAST';
    AQuery.Next;
    if (geoJsonData.Geometry.Longitude <> '0') and
      (geoJsonData.Geometry.Latitude <> '0') then
    begin
      if AQuery.EOF then
        GeoJson.addData(geoJsonData, True)
      else
        GeoJson.addData(geoJsonData);
    end;
    Inc(nbRecord);
  end;
  GeoJson.Addfooter;
  GeoJson.save('map/data/data.json');
  GeoJson.Free;
  Result := nbRecord;
end;

initialization
  TUpdate.Register('/update');

end.
