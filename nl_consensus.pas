unit nl_consensus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdTCPClient, IdGlobal, nl_data, nl_functions, strutils, nl_language, Nl_disk,
  nosodebug,nosoconsensus;

Type

TTGetNodeStatus = class(TThread)
 private
   Slot: Integer;
 protected
   procedure Execute; override;
 public
   constructor Create(const CreatePaused: Boolean;TSlot:Integer);
 end;

TFillThread = class(TThread)
  protected
    procedure Execute; override;
  public
    Constructor Create(const CreateSuspended : boolean);
  end;

TGetSumThread = class(TThread)
  protected
    procedure Execute; override;
  public
    Constructor Create(const CreateSuspended : boolean);
  end;

Function GetSyncingThreads():Integer;
Procedure SetSyncingThreads(value:integer);
Procedure CloseSyncingThread();
Function FillNodes():int64;
Procedure RunFillNodes();

function GetSumary():boolean;
Procedure RunGetSumary();

Function CalculateConsensus():NodeData;

Procedure RunUpdateGVTs();
function GetGVTsFile():boolean;

var
  NodesFilled      : boolean = false;
  FillingNodes     : boolean = false;

  GettingSum       : boolean = false;
  SumReceived      : boolean = false;
  GoodSumary       : boolean = false;


  SyncingThreads   : integer = 0;
  SyncDuration     : int64;
  MainConsensus    : NodeData;

  UpdatingGVTs     : boolean = false;

  // Critical sections
  CS_CSThread      : TRTLCriticalSection;

IMPLEMENTATION

// Thread GetNodeStatus

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
TCPclient.ConnectTimeout:= 500;
TCPclient.ReadTimeout:=500;
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

// Thread FillNodes

constructor TFillThread.Create(const CreateSuspended: Boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TFillThread.Execute;
Begin
FillNodes;
NodesFilled  := true;
FillingNodes :=false;
End;

// Thread TGetSumThread

constructor TGetSumThread.Create(const CreateSuspended: Boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TGetSumThread.Execute;
Begin
if GetSumary then GoodSumary := true
else GoodSumary := false;
SumReceived  := true;
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
  LCycles    : integer = 0;
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
LCycles := 0;
REPEAT
   sleep(1);
   //Inc(LCycles);
   LCycles := LCycles+1;
UNTIL ( (GetSyncingThreads <= 0) or (GetTickCount64-StartTime>=5000) );
Result := GetTickCount64-StartTime;
ToLog('main',Format('FN: %d ms / %d Cyc / %d OT',[result,Lcycles,GetSyncingThreads]));
End;

Procedure RunFillNodes();
var
  ThisThread : TFillThread;
Begin
FillingNodes :=true;
ThisThread := TFillThread.Create(True);
ThisThread.FreeOnTerminate:=true;
ThisThread.Start;
End;

function GetSumary():boolean;
var
  TCPClient      : TidTCPClient;
  MyStream       : TMemoryStream;
  DownloadedFile : Boolean = false;
  HashLine       : string;
  RanNode        : integer;
  ThisNode       : string;
Begin
Result         := false;
TCPClient      := TidTCPClient.Create(nil);
ThisNode       := GetRandonNode;
TCPClient.Host := Parameter(ThisNode,0);
TCPClient.Port := StrToIntDef(Parameter(ThisNode,1),8080);
TCPClient.ConnectTimeout:= 1000;
TCPClient.ReadTimeout:=800;
MyStream       := TMemoryStream.Create;
TRY
TCPClient.Connect;
TCPClient.IOHandler.WriteLn('GETZIPSUMARY');
   TRY
   HashLine := TCPClient.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   TCPClient.IOHandler.ReadStream(MyStream);
   result := true;
   MyStream.SaveToFile(ZipSumaryFilename);
   EXCEPT on E:Exception do
      begin

      end;
   END{Try};
EXCEPT on E:Exception do
   begin

   end;
END{try};
if TCPClient.Connected then TCPClient.Disconnect();
TCPClient.Free;
MyStream.Free;
GettingSum := false;
End;

Procedure RunGetSumary();
var
  ThisThread : TGetSumThread;
Begin
GettingSum := True;
ThisThread := TGetSumThread.Create(True);
ThisThread.FreeOnTerminate:=true;
ThisThread.Start;
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

For counter := 0 to length (ARRAY_Nodes)-1 do
   begin
   if ( (ARRAY_Nodes[counter].block=Result.block) and (ARRAY_Nodes[counter].Branch = Result.Branch) ) then
      ARRAY_Nodes[counter].Synced:=true
   else ARRAY_Nodes[counter].Synced:=false;
   end;

End;

Procedure RunUpdateGVTs();
Begin
if GetGVTsFile then
   begin
   REF_GVTS := true;
   LoadGVTsFile();
   end;
UpdatingGVTs := true;
End;

function GetGVTsFile():boolean;
var
  TCPClient      : TidTCPClient;
  MyStream       : TMemoryStream;
  DownloadedFile : Boolean = false;
  HashLine       : string;
  RanNode        : integer;
  ThisNode       : string;
Begin
Result         := false;
TCPClient      := TidTCPClient.Create(nil);
ThisNode       := GetRandonNode;
TCPClient.Host := Parameter(ThisNode,0);
TCPClient.Port := StrToIntDef(Parameter(ThisNode,1),8080);
TCPClient.ConnectTimeout:= 1000;
TCPClient.ReadTimeout:=800;
MyStream       := TMemoryStream.Create;
TRY
TCPClient.Connect;
TCPClient.IOHandler.WriteLn('NSLGVT');
   TRY
   HashLine := TCPClient.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   TCPClient.IOHandler.ReadStream(MyStream);
   result := true;
   MyStream.SaveToFile(GVTFilename);
   EXCEPT on E:Exception do
      begin

      end;
   END{Try};
EXCEPT on E:Exception do
   begin

   end;
END{try};
if TCPClient.Connected then TCPClient.Disconnect();
TCPClient.Free;
MyStream.Free;
End;

INITIALIZATION
InitCriticalSection(CS_CSThread);

FINALIZATION
DoneCriticalSection(CS_CSThread);


END.// END UNIT

