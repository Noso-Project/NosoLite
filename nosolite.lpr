program nosolite;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, nl_mainform, nl_language, nl_GUI, nl_data, nl_functions, nl_disk,
  nl_cripto, nl_network, nl_signerUtils, indylaz, nl_explorer, nl_qrcode,
  infoform, NosoCoreUnit;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormExplorer, FormExplorer);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.

