program yadd2map;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  zcomponent,
  lazcontrols,
  main,
  geojson,
  rxposition, BrookThread, brookdt, ActionMap, aprsfi, about
  {$IFDEF UNIX}
  , cthreads
  {$ENDIF} ;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='Yadd2Map';
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFAprsfi, FAprsfi);
  Application.CreateForm(TFAbout, FAbout);
  Application.Run;
end.
