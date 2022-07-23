unit infoform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TForm3 }

  TForm3 = class(TForm)
    memoresult: TMemo;
    memorequest: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    Panelresult: TPanel;
    Panelrequest: TPanel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private

  public

  end;

Procedure ShowInfoform(RequestText,ResultText:String);

var
  Form3: TForm3;

implementation

{$R *.lfm}

uses
  nl_mainform;

{ TForm3 }

Procedure ShowInfoform(RequestText,ResultText:String);
Begin
form3.BorderIcons:=form3.BorderIcons+[bisystemmenu];
form3.memorequest.Text:=RequestText;
form3.memoresult.Text:=ResultText;
form3.ShowModal;
End;

procedure TForm3.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
form1.enabled := true;
end;

END. // END UNIT

