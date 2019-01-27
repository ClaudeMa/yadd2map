unit ActionMap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BrookAction, ZConnection, ZDataset, GeoJson, dateutils;

type

  { TMap }

  TMap = class(TBrookAction)
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Get; override;
  private
    Connection: TZConnection;
    Query: TZQuery;
    function genHour(hh: integer; mm: integer; diff: integer = 2): string;
    function genGeoJson(AQuery: TZQuery): integer;
    function checkValue(AParamValue: string): boolean;
  end;

implementation

{ TMap }

constructor TMap.Create;
begin
  inherited Create;
  Connection := TZConnection.Create(nil);
  Connection.Database := GetCurrentDir + DirectorySeparator + 'db/logbook.db';
  Connection.Protocol := 'sqlite-3';
  Connection.Connect;
  Query := TZQuery.Create(nil);
  Query.Connection := Connection;
end;

destructor TMap.Destroy;
begin
  Query.Free;
  Connection.Free;
  inherited Destroy;
end;

procedure TMap.Get;
var
  where: string = '';
  queryString: string;
  ParamName: string;
  Paramvalue: string;
  I: integer;
begin
  if Params.Count = 0 then
  begin
    WHERE := 'WHERE  PRINTF("%s %s", log_date, log_time) > "' +
      FormatDateTime('yyyy-mm-dd ', now) + genHour(HourOfTheDay(now),
      MinuteOfTheHour(now)) + ':00" ';
    queryString := 'SELECT * FROM logs ' + where +
      ' AND latitude <> 0  AND longitude <> 0  GROUP BY mmsi_from ORDER BY name_from, log_date, log_time;';
  end
  else
  begin
    for I := 0 to Pred(Params.Count) do
    begin
      Params.GetNameValue(I, paramName, paramValue);
      if paramname = 'hour' then
      begin
        if checkValue(ParamValue) then
        begin
          if (HourOfTheDay(now) - StrToInt(ParamValue)) < 0 then
            WHERE := 'WHERE  PRINTF("%s %s", log_date, log_time) > "' +
              FormatDateTime('yyyy-mm-dd ', IncDay(now, -1)) +
              genHour(HourOfTheDay(now), MinuteOfTheHour(now),
              StrToInt(ParamValue)) + ':00" '
          else
            WHERE := 'WHERE  PRINTF("%s %s", log_date, log_time) > "' +
              FormatDateTime('yyyy-mm-dd ', now) +
              genHour(HourOfTheDay(now), MinuteOfTheHour(now),
              StrToInt(ParamValue)) + ':00" ';
        queryString := 'SELECT * FROM logs ' + where +
          ' AND latitude <> 0  AND longitude <> 0 GROUP BY mmsi_from ORDER BY name_from, log_date, log_time;';
        end;
      end
      else if ParamName = 'date' then
        queryString := 'SELECT * FROM logs WHERE log_date = "' +
          Paramvalue + '" AND latitude <> 0  AND longitude <> 0  GROUP BY mmsi_from ORDER BY name_from, log_date, log_time;'
      else if ParamName = 'today' then
      begin
        queryString := 'SELECT * FROM logs WHERE log_date = "' +
          FormatdateTime('yyyy-mm-dd', now) +
          '" AND latitude <> 0  AND longitude <> 0  GROUP BY mmsi_from ORDER BY name_from, log_date, log_time;';
      end
      else
      begin
        WHERE := 'WHERE  log_date = "' + FormatDateTime('yyyy-mm-dd', now) + '"';
        queryString := 'SELECT * FROM logs ' + where +
          ' AND latitude <> 0  AND longitude <> 0  GROUP BY mmsi_from ORDER BY name_from, log_date, log_time;';
      end;
    end;
  end;
  Query.SQL.Clear;
  Query.SQL.Add(queryString);
  Query.Open;
  genGeoJson(query);
  Render('map/index.html');
end;

function TMap.genHour(hh: integer; mm: integer; diff: integer = 2): string;
var
  s: string;
  i: integer;
begin
  i := hh - diff;
  if i < 0 then
  begin
    i := 24 - abs(i);
  end;
  if i < 10 then
    s := '0' + IntToStr(i)
  else
    s := IntToStr(i);
  if mm < 10 then
    Result := s + ':0' + IntToStr(mm)
  else
    Result := s + ':' + IntToStr(mm);
end;

function TMap.genGeoJson(AQuery: TZQuery): integer;
var

  geoJSON: TGeoJson;
  geoJsonData: TGEOJsonData;
  nbRecord: integer = 0;
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
    geoJsondata.Properties.Frequency := AQuery.FieldByName('frequencie').AsString;
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

function TMap.checkValue(AParamValue: string): boolean;
begin
  if AParamvalue = '1' then
    Result := True
  else if APAramValue = '2' then
    Result := True
  else if APAramValue = '6' then
    Result := True
  else if APAramValue = '12' then
    Result := True
  else
    Result := False;
end;

initialization
  TMap.Register('map/');

end.
