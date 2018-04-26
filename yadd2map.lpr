program yadd2map;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  zcomponent,
  lazcontrols,
  main,
  geojson,
  rxposition;

{$R *.res}

begin
  Application.Title := 'Yadd to Map';
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
