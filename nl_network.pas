unit nl_network;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, IdGlobal, dialogs, nl_functions, nl_language;

function GetNodeStatus(Host,Port:String):string;
function GetSumary():boolean;

implementation

Uses
  nl_mainform;

// Connects a client and returns the nodestatus
function GetNodeStatus(Host,Port:String):string;
var
  Errored : boolean = false;
Begin
result := '';
if Host = '127.0.0.1' then
   begin
   errored := true;
   end;
if not errored then
   begin
   if form1.ClientChannel.Connected then
      begin
         TRY
         form1.ClientChannel.IOHandler.InputBuffer.Clear;
         form1.ClientChannel.Disconnect;
         EXCEPT on E:exception do
            begin
            ToLog(Format(rsError0005,[E.Message]));
            end;
         END{try};
      end;
   form1.ClientChannel.Host:=Host;
   form1.ClientChannel.Port:=StrToIntDef(Port,8080);
      TRY
      form1.ClientChannel.ConnectTimeout:= 1000;
      form1.ClientChannel.ReadTimeout:=500;
      form1.ClientChannel.Connect;
      form1.ClientChannel.IOHandler.WriteLn('NODESTATUS');
      result := form1.ClientChannel.IOHandler.ReadLn(IndyTextEncoding_UTF8);
      form1.ClientChannel.Disconnect();
      EXCEPT on E:Exception do
         begin
         ToLog(Format(rsError0006,[Host,E.message]));
         end;
      END{try};
   end;
End;

// Downloads the sumary file from a node
function GetSumary():boolean;
var
  AFileStream : TFileStream;
Begin
result := false;
form1.ClientChannel.Host:='192.210.226.118';
form1.ClientChannel.Port:=8080;
form1.ClientChannel.ConnectTimeout:= 1000;
form1.ClientChannel.ReadTimeout:=500;
AFileStream := TFileStream.Create(SumaryFilename, fmCreate);
TRY
form1.ClientChannel.Connect;
form1.ClientChannel.IOHandler.WriteLn('GETSUMARY');
   TRY
   form1.ClientChannel.IOHandler.ReadStream(AFileStream);
   result := true;
   EXCEPT on E:Exception do
      begin
      ToLog(Format(rsError0008,[form1.ClientChannel.Host]));
      end;
   END{Try};
EXCEPT on E:Exception do
   begin
   ToLog(Format(rsError0008,[form1.ClientChannel.Host]));
   end;
END{try};
if form1.ClientChannel.Connected then form1.ClientChannel.Disconnect();
AFileStream.Free;
End;





END. // END UNIT.

