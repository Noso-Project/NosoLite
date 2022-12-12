unit formliqpool;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  fphttpclient;

type

  { TForm7 }

  TForm7 = class(TForm)
    Memo1: TMemo;
    PageControl1: TPageControl;
    TabConsole: TTabSheet;
    TabTrade: TTabSheet;
  private

  public

  end;

Function PostMessageToHost(host:string;port:integer;message:string):string;

var
  Form7: TForm7;

IMPLEMENTATION

Function PostMessageToHost(host:string;port:integer;message:string):string;
var
  HTTPClient: TFPHTTPClient;
  Resultado : String = '';
  RequestBodyStream: TStringStream;
  { No need for the params string list }
begin
Result := '';
HTTPClient := TFPHTTPClient.Create(nil);
RequestBodyStream:= TStringStream.Create(message, TEncoding.UTF8);
HTTPClient.IOTimeout:=3000; //
   TRY
   HTTPClient.AllowRedirect := True; // <-- I always forget this LOL!!
   HTTPClient.RequestBody:= RequestBodyStream;
   Resultado := HTTPClient.Post('http://'+host+':'+Port.ToString);
   Except on E:Exception do
      Resultado := 'ERROR : '+E.Message;
   end;
Result := Resultado;
RequestBodyStream.Free;
HTTPClient.Free;
End;

{$R *.lfm}

END.

