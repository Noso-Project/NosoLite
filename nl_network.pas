unit nl_network;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, IdGlobal, dialogs;

function GetNodeStatus(Host,Port:String):string;

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
         //ShowMessage(E.message)
         end;
      END{try};
   end;

End;

END. // END UNIT.

