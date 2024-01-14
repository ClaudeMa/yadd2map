unit about;

{$mode objfpc}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

type

  { TFAbout }

  TFAbout = class(TForm)
    Button1: TButton;
    Image1: TImage;
    Panel1: TPanel;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    procedure Button1Click(Sender: TObject);
    procedure StaticText3Click(Sender: TObject);
  private

  public

  end;

var
  FAbout: TFAbout;

implementation

{ TFAbout }

procedure TFAbout.Button1Click(Sender: TObject);
begin
  close;
end;

procedure TFAbout.StaticText3Click(Sender: TObject);
begin

end;

initialization
  {$I about.lrs}

end.

