unit nl_apps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,fphttpclient, nl_functions, strutils;

Function PostMessageToHost(host:string;port:integer;message:string):string;

implementation

Uses
  nl_mainform;

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
HTTPClient.IOTimeout:=60000; // <-- THIS is too restrictive, ONLY needed if you get stuck for more than 1 minute
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

END. // END UNIT

