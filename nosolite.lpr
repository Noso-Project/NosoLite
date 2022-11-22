program nosolite;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, nl_mainform, nl_language, nl_GUI, nl_data, nl_functions, nl_disk,
  nl_cripto, nl_network, nl_signerUtils, indylaz, nl_explorer, nl_qrcode,
  infoform, NosoCoreUnit, nl_apps, nl_consensus, splashform, formlog, formnetwork;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormExplorer, FormExplorer);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TForm4, Form4);
  Application.CreateForm(TForm5, Form5);
  Application.CreateForm(TForm6, Form6);
  Application.Run;
end.

