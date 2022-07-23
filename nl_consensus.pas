unit nl_consensus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdTCPClient, IdGlobal, nl_data, nl_functions, strutils, nl_language;

Type

TTGetNodeStatus = class(TThread)
 private
   Slot: Integer;
 protected
   procedure Execute; override;
 public
   constructor Create(const CreatePaused: Boolean;TSlot:Integer);
 end;

Function GetSyncingThreads():Integer;
Procedure SetSyncingThreads(value:integer);
Procedure CloseSyncingThread();
Function FillNodes():int64;
Function CalculateConsensus():NodeData;

var
  GetConsensus     : boolean = false;
  GettingConsensus : boolean = false;
  SyncingThreads   : integer = 0;
  SyncDuration     : int64;
  MainConsensus    : NodeData;

  // Critical sections
  CS_CSThread      : TRTLCriticalSection;

IMPLEMENTATION

constructor TTGetNodeStatus.Create(const CreatePaused: Boolean; TSlot:Integer);
begin
inherited Create(CreatePaused);
Slot := TSlot;
FreeOnTerminate := True;
end;

procedure TTGetNodeStatus.Execute;
var
  TCPClient : TidTCPClient;
  LineText  : String = '';
  Sucess    : Boolean = false;
  ThisNode  : NodeData;
  Trys      : integer = 0;
Begin
ThisNode := GetNodeIndex(Slot);
TCPClient := TidTCPClient.Create(nil);
TCPclient.Host:=ThisNode.host;
TCPclient.Port:=ThisNode.port;
TCPclient.ConnectTimeout:= 800;
TCPclient.ReadTimeout:=800;
REPEAT
   TRY
   TCPclient.Connect;
   TCPclient.IOHandler.WriteLn('NODESTATUS');
   LineText := TCPclient.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   TCPclient.Disconnect();
   Sucess := true;
   EXCEPT on E:Exception do
      Sucess := false;
   END{try};
Inc(Trys)
until ((Sucess) or (Trys >=3));
TCPClient.Free;
if sucess then
   begin
   ThisNode.Peers     :=Parameter(LineText,1).ToInteger();
   ThisNode.block     :=Parameter(LineText,2).ToInteger();
   ThisNode.Pending   :=Parameter(LineText,3).ToInteger();
   ThisNode.Branch    :=AddCharR(' ',(Parameter(LineText,5)),5);
   ThisNode.Version   :=Parameter(LineText,6);
   ThisNode.MNsHash   :=AddCharR(' ',(Parameter(LineText,8)),5);
   ThisNode.MNsCount  := StrToIntDef(Parameter(LineText,9),0);
   ThisNode.Updated   :=0;
   ThisNode.LBHash    :=AddCharR(' ',(Parameter(LineText,10)),5);
   ThisNode.NMSDiff   :=AddCharR(' ',(Parameter(LineText,11)),5);
   ThisNode.LBTimeEnd :=StrToIntDef(Parameter(LineText,12),0);
   ThisNode.Checks    :=StrToIntDef(Parameter(LineText,14),0);
   ThisNode.SumHash   :=Parameter(LineText,17);
   ThisNode.GVTHash   :=Parameter(LineText,18);

   EnterCriticalSection(CS_ArrayNodes);
   ARRAY_Nodes[slot] := ThisNode;
   LeaveCriticalSection(CS_ArrayNodes);
   end
else
   begin
   ThisNode.block    := 0;
   ThisNode.Pending  := 0;
   ThisNode.Version  := rsError0003;
   ThisNode.Branch   := rsError0003;
   ThisNode.MNsHash  := rsError0003;
   ThisNode.MNsCount := 0;
   ThisNode.Updated  := ThisNode.Updated+1;
   ThisNode.NMSDiff  := rsError0003;
   ThisNode.SumHash  := rsError0003;
   ThisNode.Version  := rsError0003;
   ThisNode.Peers    := 0;

   EnterCriticalSection(CS_ArrayNodes);
   ARRAY_Nodes[slot] := ThisNode;
   LeaveCriticalSection(CS_ArrayNodes);
   end;
CloseSyncingThread;
End;

Function GetSyncingThreads():Integer;
Begin
EnterCriticalSection(CS_CSThread);
Result := SyncingThreads;
LeaveCriticalSection(CS_CSThread);
End;

Procedure SetSyncingThreads(value:integer);
Begin
EnterCriticalSection(CS_CSThread);
SyncingThreads := value;
LeaveCriticalSection(CS_CSThread);
End;

Procedure CloseSyncingThread();
Begin
EnterCriticalSection(CS_CSThread);
SyncingThreads := SyncingThreads-1;
LeaveCriticalSection(CS_CSThread);
End;

Function FillNodes():int64;
Var
  Counter   : integer;
  UseThread : TTGetNodeStatus;
  StartTime : int64;
  Cycles    : integer = 0;
Begin
SetSyncingThreads(ArrayNodesLength);
StartTime := GetTickCount64;
For Counter := 0 to ArrayNodesLength-1 do
   begin
   UseThread := TTGetNodeStatus.Create(True,counter);
   UseThread.FreeOnTerminate:=true;
   UseThread.Start;
   Sleep(1);
   end;
REPEAT
   sleep(1);
   Inc(Cycles);
UNTIL ( (GetSyncingThreads <= 0) or (Cycles>=3000) );
if GetSyncingThreads>0 then
   begin
   // ToLog('ERROR: Open threads '+GetSyncingThreads.ToString);
   end;
Result := GetTickCount64-StartTime;
End;

Function CalculateConsensus():NodeData;
var
  counter  : integer;
  ArrT     : array of ConsensusData;
  CBlock   : integer = 0;
  CBranch  : string = '';
  cPending : integer = 0;

   function GetHighest():string;
   var
     maximum : integer = 0;
     counter : integer;
     MaxIndex : integer = 0;
   Begin
   for counter := 0 to length(ArrT)-1 do
      begin
      if ArrT[counter].count> maximum then
         begin
         maximum := ArrT[counter].count;
         MaxIndex := counter;
         end;
      end;
   result := ArrT[MaxIndex].Value;
   End;

   Procedure AddValue(Tvalue:String);
   var
     counter : integer;
     added : Boolean = false;
     ThisItem : ConsensusData;
   Begin
   for counter := 0 to length(ArrT)-1 do
      begin
      if Tvalue = ArrT[counter].Value then
         begin
         ArrT[counter].count+=1;
         Added := true;
         end;
      end;
   if not added then
      begin
      ThisItem.Value:=Tvalue;
      ThisItem.count:=1;
      Insert(ThisITem,ArrT,length(ArrT));
      end;
   End;

Begin
Result := Default(NodeData);
// Get the consensus block number
SetLength(ArrT,0);
For counter := 0 to length (ARRAY_Nodes)-1 do
   Begin
   AddValue(ARRAY_Nodes[counter].block.ToString);
   Result.block := GetHighest.ToInteger;
   End;
// Get the consensus summary
SetLength(ArrT,0);
For counter := 0 to length (ARRAY_Nodes)-1 do
   Begin
   AddValue(ARRAY_Nodes[counter].Branch);
   Result.Branch := GetHighest;
   End;
// Get the consensus pendings
SetLength(ArrT,0);
For counter := 0 to length (ARRAY_Nodes)-1 do
   Begin
   AddValue(ARRAY_Nodes[counter].Pending.ToString);
   Result.Pending := GetHighest.ToInteger;
   End;
// Get the consensus GVTHash
SetLength(ArrT,0);
For counter := 0 to length (ARRAY_Nodes)-1 do
   Begin
   AddValue(ARRAY_Nodes[counter].GVTHash);
   Result.GVTHash := GetHighest;
   End;
{

if ((CBlock=WO_LastBlock) and (CBranch=WO_LastSumary) and (not Wallet_Synced)) then
   Wallet_Synced := true;

if (CBlock>WO_LastBlock) then
   begin
   result := true;
   WO_LastBlock := CBlock;
   WO_LastSumary := CBranch;
   Int_LastPendingCount := 0;
   end;

if cPending>Int_LastPendingCount  then
   begin
   Pendings_String := GetPendings();
   ProcessPendings();
   Int_LastPendingCount := cPending;
   end;

For counter := 0 to length (ARRAY_Nodes)-1 do
   begin
   if ( (ARRAY_Nodes[counter].block=CBlock) and (ARRAY_Nodes[counter].Branch = CBranch) ) then
      ARRAY_Nodes[counter].Synced:=true
   else ARRAY_Nodes[counter].Synced:=false;
   end;
}
End;

INITIALIZATION
InitCriticalSection(CS_CSThread);

FINALIZATION
DoneCriticalSection(CS_CSThread);


END.// END UNIT

