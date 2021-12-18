unit nl_network;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, IdGlobal, dialogs, nl_functions, nl_language;

function GetNodeStatus(Host,Port:String):string;
function GetSumary():boolean;

implementation

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
   if ClientChannel.Connected then
      begin
         TRY
         ClientChannel.IOHandler.InputBuffer.Clear;
         ClientChannel.Disconnect;
         EXCEPT on E:exception do
            begin
            ToLog(Format(rsError0005,[E.Message]));
            end;
         END{try};
      end;
   ClientChannel.Host:=Host;
   ClientChannel.Port:=StrToIntDef(Port,8080);
      TRY
      ClientChannel.ConnectTimeout:= 1000;
      ClientChannel.ReadTimeout:=500;
      ClientChannel.Connect;
      ClientChannel.IOHandler.WriteLn('NODESTATUS');
      result := ClientChannel.IOHandler.ReadLn(IndyTextEncoding_UTF8);
      ClientChannel.Disconnect();
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
ClientChannel.Host:='192.210.226.118';
ClientChannel.Port:=8080;
ClientChannel.ConnectTimeout:= 1000;
ClientChannel.ReadTimeout:=500;
//ClientChannel.OnWork:=;
TRY
ClientChannel.Connect;
ClientChannel.IOHandler.WriteLn('GETSUMARY');
AFileStream := TFileStream.Create(SumaryFilename, fmCreate);
   TRY
   ClientChannel.IOHandler.ReadStream(AFileStream);
   result := true;
   EXCEPT on E:Exception do
      begin

      end;
   END{Try};
FINALLY
AFileStream.Free;
ClientChannel.Disconnect();
END{try};

End;





END. // END UNIT.

