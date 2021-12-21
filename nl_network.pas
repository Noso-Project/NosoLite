unit nl_network;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, IdGlobal, dialogs, nl_functions, nl_language,
  IdTCPClient;

function GetNodeStatus(Host,Port:String):string;
function GetSumary():boolean;
function SendOrder(OrderString:String):String;
function GetPendings():string;

implementation

Uses
  nl_mainform, nl_Disk;

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
  DownloadedFile : Boolean = false;
  HashLine : string;
Begin
result := false;
form1.ClientChannel.Host:='192.210.226.118';
form1.ClientChannel.Port:=8080;
form1.ClientChannel.ConnectTimeout:= 1000;
form1.ClientChannel.ReadTimeout:=500;
AFileStream := TFileStream.Create(ZipSumaryFilename, fmCreate);
TRY
form1.ClientChannel.Connect;
form1.ClientChannel.IOHandler.WriteLn('GETZIPSUMARY');
   TRY
   HashLine := form1.ClientChannel.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   ToLog(format(rsGUI0017,[parameter(HashLine,1)]));
   form1.ClientChannel.IOHandler.ReadStream(AFileStream);
   result := true;
   DownloadedFile := true;
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
if DownloadedFile then UnZipSumary();
End;

// Sends a order to the mainnet
function SendOrder(OrderString:String):String;
var
  Client : TidTCPClient;
Begin
Result := '';
Client := TidTCPClient.Create(nil);
Client.Host:='192.210.226.118';
Client.Port:=8080;
Client.ConnectTimeout:= 1000;
Client.ReadTimeout:=500;
TRY
Client.Connect;
Client.IOHandler.WriteLn(OrderString);
Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
if result = 'ok' then REF_Addresses := true;
EXCEPT on E:Exception do
   begin
   ToLog(Format(rsError0015,[E.Message]));
   end;
END{Try};
if client.Connected then Client.Disconnect();
client.Free;
End;

function GetPendings():string;
var
  Client : TidTCPClient;
Begin
Result := '';
Client := TidTCPClient.Create(nil);
Client.Host:='192.210.226.118';
Client.Port:=8080;
Client.ConnectTimeout:= 1000;
Client.ReadTimeout:=1500;
TRY
Client.Connect;
Client.IOHandler.WriteLn('NSLPEND');
Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
REF_Addresses := true;
EXCEPT on E:Exception do
   begin
   ToLog(Format(rsError0014,[E.Message]));
   Int_LastPendingCount := 0;
   end;
END;{Try}
if client.Connected then Client.Disconnect();
client.Free;
End;


END. // END UNIT.

