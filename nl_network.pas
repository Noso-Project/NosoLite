unit nl_network;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, IdGlobal, dialogs, nl_functions, nl_language,
  IdTCPClient;

function SendOrder(OrderString:String):String;
function GetPendings():string;
function GetMainnetTimestamp(Trys:integer=5):int64;
function GetMNsFromNode(Trys:integer=5):string;

implementation

Uses
  nl_mainform, nl_Disk;

// Sends a order to the mainnet
function SendOrder(OrderString:String):String;
var
  Client    : TidTCPClient;
  RanNode   : integer;
  ThisNode  : NodeData;
  TrysCount : integer = 0;
  WasOk     : Boolean = false;
Begin
Result := '';
Client := TidTCPClient.Create(nil);
REPEAT
Inc(TrysCount);
RanNode := Random(length(ARRAY_Nodes));
ThisNode := ARRAY_Nodes[RanNode];
Client.Host:=ThisNode.host;
Client.Port:=thisnode.port;
Client.ConnectTimeout:= 3000;
Client.ReadTimeout:=3000;
//Tolog(OrderString);
TRY
Client.Connect;
Client.IOHandler.WriteLn(OrderString);
Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
WasOK := True;
EXCEPT on E:Exception do
   begin
   ToLog(Format(rsError0015,[E.Message]));
   end;
END{Try};
UNTIL ( (WasOk) or (TrysCount=3) );
if result <> '' then REF_Addresses := true;
if client.Connected then Client.Disconnect();
client.Free;
End;

function GetPendings():string;
var
  Client : TidTCPClient;
  RanNode  : integer;
  ThisNode : NodeData;
Begin
Result := '';
RanNode := Random(length(ARRAY_Nodes));
ThisNode := ARRAY_Nodes[RanNode];
Client := TidTCPClient.Create(nil);
Client.Host:=Thisnode.host;
Client.Port:=thisnode.port;
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

function GetMainnetTimestamp(Trys:integer=5):int64;
var
  Client : TidTCPClient;
  RanNode : integer;
  ThisNode : NodeData;
  WasDone : boolean = false;
Begin
Result := 0;
Client := TidTCPClient.Create(nil);
REPEAT
   ThisNode := PickRandomNode;
   Client.Host:=ThisNode.host;
   Client.Port:=ThisNode.port;
   Client.ConnectTimeout:= 1000;
   Client.ReadTimeout:= 1000;
   TRY
   Client.Connect;
   Client.IOHandler.WriteLn('NSLTIME');
   Result := StrToInt64Def(Client.IOHandler.ReadLn(IndyTextEncoding_UTF8),0);
   WasDone := true;
   EXCEPT on E:Exception do
      begin
      WasDone := False;
      end;
   END{Try};
Inc(Trys);
UNTIL ( (WasDone) or (Trys = 5) );
if client.Connected then Client.Disconnect();
client.Free;
End;

function GetMNsFromNode(Trys:integer=5):string;
var
  Client : TidTCPClient;
  RanNode : integer;
  ThisNode : NodeData;
  WasDone : boolean = false;
Begin
Result := '';
Client := TidTCPClient.Create(nil);
REPEAT
   ThisNode := PickRandomNode;
   Client.Host:=ThisNode.host;
   Client.Port:=ThisNode.port;
   Client.ConnectTimeout:= 3000;
   Client.ReadTimeout:= 3000;
   TRY
   Client.Connect;
   Client.IOHandler.WriteLn('NSLMNS');
   Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   WasDone := true;
   EXCEPT on E:Exception do
      begin
      WasDone := False;
      end;
   END{Try};
Inc(Trys);
UNTIL ( (WasDone) or (Trys = 5) );
if client.Connected then Client.Disconnect();
client.Free;
End;

END. // END UNIT.

