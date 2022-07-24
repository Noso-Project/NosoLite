unit nl_GUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_functions, nl_language, nl_data, graphics, DateUtils;

Procedure LoadGUIInterface();
Procedure RefreshAddresses();
Procedure RefreshNodes();
Procedure RefreshStatus();
Procedure RefreshGVTs();
Function BestHashReadeable(BestDiff:String):string;

implementation

uses
  nl_mainform;


// Loads all the GUI
Procedure LoadGUIInterface();
Begin
form1.SGridAddresses.FocusRectVisible:=false;
form1.SGridAddresses.Cells[0,0] := rsGUI0001;
form1.SGridAddresses.Cells[1,0] := rsGUI0002;
form1.SGridAddresses.Cells[2,0] := rsGUI0003;
form1.SGridAddresses.Cells[3,0] := rsGUI0004;
form1.SGridNodes.FocusRectVisible:=false;
form1.SGridNodes.Cells[0,0] := rsGUI0005;
form1.SGridNodes.Cells[1,0] := rsGUI0006;
form1.SGridNodes.Cells[2,0] := rsGUI0007;
form1.SGridNodes.Cells[3,0] := rsGUI0008;
form1.SGridNodes.Cells[4,0] := rsGUI0018;
form1.SGridNodes.Cells[5,0] := rsGUI0019;
form1.SGridNodes.Cells[6,0] := rsGUI0029;
form1.SGridNodes.Cells[7,0] := 'Version';
Form1.SGridSC.Cells[0,0]:=rsGUI0014;
Form1.SGridSC.Cells[0,1]:=rsGUI0015;
Form1.SGridSC.Cells[0,2]:=rsGUI0016;
form1.CBMultisend.Checked:=WO_Multisend;
Form1.GVTsGrid.Cells[0,0]:= rsGUI0035;
Form1.GVTsGrid.Cells[1,0]:= rsGUI0036;
form1.GVTsGrid.FocusRectVisible:=false;
End;

// Refresh the adressess grid
Procedure RefreshAddresses();
var
  counter : integer = 0;
Begin
Int_WalletBalance := 0;
Int_LockedBalance := 0;
EnterCriticalSection(CS_ARRAY_Addresses);
form1.SGridAddresses.RowCount:=length(ARRAY_Addresses)+1;

if length(ARRAY_Addresses)>0 then
   begin
   for counter := 0 to length(ARRAY_Addresses)-1 do
      begin
      form1.SGridAddresses.Cells[0,counter+1] := GetAddressToShow(ARRAY_Addresses[counter].Hash);
      form1.SGridAddresses.Cells[1,counter+1] := GetLabelAddress(ARRAY_Addresses[counter].Hash);
      form1.SGridAddresses.Cells[2,counter+1] := Int2Curr(ARRAY_Pending[counter].incoming-ARRAY_Pending[counter].outgoing);
      form1.SGridAddresses.Cells[3,counter+1] := Int2Curr(ARRAY_Addresses[counter].Balance-ARRAY_Pending[counter].outgoing);
      if ARRAY_Addresses[counter].PrivateKey[1] = '*' then
         Int_LockedBalance := Int_LockedBalance+ARRAY_Addresses[counter].Balance-ARRAY_Pending[counter].outgoing
      else Int_WalletBalance := Int_WalletBalance+ARRAY_Addresses[counter].Balance-ARRAY_Pending[counter].outgoing;
      end;
   end;
LeaveCriticalSection(CS_ARRAY_Addresses);
form1.LBalance1.Caption:=Format(rsGUI0009,[Int2Curr(Int_WalletBalance)]);
form1.LabelLocked.Caption:=Format(rsGUI0009,[Int2Curr(Int_LockedBalance)]);
End;

// Refresh the nodes grid
Procedure RefreshNodes();
var
  counter : integer = 0;
Begin
Form1.LabelNodes.caption := 'Block: '+MasternodesLastBlock.ToString+'+';
form1.SGridNodes.RowCount:=length(ARRAY_Nodes)+1;
if length(ARRAY_Nodes)>0 then
   begin
   for counter := 0 to length(ARRAY_Nodes)-1 do
      begin
      form1.SGridNodes.Cells[0,counter+1] := ARRAY_Nodes[counter].Host;
      form1.SGridNodes.Cells[1,counter+1] := ARRAY_Nodes[counter].Block.ToString;
      form1.SGridNodes.Cells[2,counter+1] := ARRAY_Nodes[counter].Pending.ToString;
      form1.SGridNodes.Cells[3,counter+1] := ARRAY_Nodes[counter].Branch+'/'+ARRAY_Nodes[counter].SumHash;
      form1.SGridNodes.Cells[4,counter+1] := ARRAY_Nodes[counter].MNsHash+'-'+ARRAY_Nodes[counter].MNsCount.ToString+'-'+ARRAY_Nodes[counter].Checks.ToString;
      form1.SGridNodes.Cells[5,counter+1] := ARRAY_Nodes[counter].Peers.ToString;
      form1.SGridNodes.Cells[6,counter+1] := BestHashReadeable(ARRAY_Nodes[counter].NMSDiff);
      form1.SGridNodes.Cells[7,counter+1] := ARRAY_Nodes[counter].version;
      end;
   end;
Form1.TabNodes.Caption:=Format('Nodes (%d)',[length(ARRAY_Nodes)]);
End;

// Refresh the status bar
Procedure RefreshStatus();
var
  Supply : extended;
Begin
Int_TotalSupply := (WO_LastBlock*50)+10303;
supply := Int_TotalSupply/1000000;
Int_StakeSize  := (Int_TotalSupply div 500)+1;
supply := (((WO_LastBlock*50)+10303)/1000000);
if Wallet_Synced then form1.PanelBlockInfo.Color:=clGreen
else form1.PanelBlockInfo.Color:=clRed;
form1.LabelBlockInfo.Caption:=GetSumaryLastBlock.ToString;
Form1.Labelsupply.Caption:=FormatFloat('0.00', Supply)+'M';
Form1.Labelsupply.Hint:=format(rsGUI0025,[FormatFloat('0.00', Supply)]);
form1.LabelTime.Caption:=TimestampToDate(G_UTCTime);
form1.labelstake.Caption:=IntToStr(Int_StakeSize)+' NOSO';
form1.Labelsummary.Caption:=FormatFloat('0.00', (length(ARRAY_Sumary)+1)/1000)+'k';
End;

Procedure RefreshGVTs();
var
  counter : integer;
Begin
Form1.GVTsGrid.RowCount:=1;
For Counter := 0 to Length(ARRAY_GVTs)-1 do
   begin
   if WalletAddressIndex(ARRAY_GVTs[counter].owner) >=0 then
      begin
      Form1.GVTsGrid.RowCount:=Form1.GVTsGrid.RowCount+1;
      Form1.GVTsGrid.Cells[0,Form1.GVTsGrid.RowCount-1] := ARRAY_GVTs[counter].number;
      Form1.GVTsGrid.Cells[1,Form1.GVTsGrid.RowCount-1] := ARRAY_GVTs[counter].owner;
      end;
   end;
Int_GVTOwned := Form1.GVTsGrid.RowCount-1;
if Int_GVTOwned = 0 then Form1.TabGVTs.TabVisible:=false
else Form1.TabGVTs.TabVisible:=true;
Form1.TabGVTs.Caption:=Format('GVTs (%d)',[Int_GVTOwned]);
End;

Function BestHashReadeable(BestDiff:String):string;
var
  counter :integer = 0;
Begin
if bestdiff = '' then BestDiff := 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';
repeat
  counter := counter+1;
until bestdiff[counter]<> '0';
Result := (Counter-1).ToString+'.';
if counter<length(BestDiff) then Result := Result+bestdiff[counter];
End;

END. // END UNIT

