unit nl_GUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_functions, nl_language, nl_data, graphics, DateUtils;

Procedure ResizeSGridAddresses();
Procedure ResizeSGridNodes();
Procedure LoadGUIInterface();
Procedure RefreshAddresses();
Procedure RefreshNodes();
Procedure RefreshStatus();

implementation

uses
  nl_mainform;

// Resize the stringgrid containing the addresses
Procedure ResizeSGridAddresses();
var
  GridWidth : integer;
Begin
GridWidth := form1.SGridAddresses.Width;
form1.SGridAddresses.ColWidths[0] := ThisPercent(40,GridWidth);
form1.SGridAddresses.ColWidths[1] := ThisPercent(18,GridWidth);
form1.SGridAddresses.ColWidths[2] := ThisPercent(18,GridWidth);
form1.SGridAddresses.ColWidths[3] := ThisPercent(24,GridWidth,true);
End;

// Resize the stringgrid containing the nodes
Procedure ResizeSGridNodes();
var
  GridWidth : integer;
Begin
GridWidth := form1.SGridNodes.Width;
form1.SGridNodes.ColWidths[0] := ThisPercent(40,GridWidth);
form1.SGridNodes.ColWidths[1] := ThisPercent(20,GridWidth);
form1.SGridNodes.ColWidths[2] := ThisPercent(20,GridWidth);
form1.SGridNodes.ColWidths[3] := ThisPercent(20,GridWidth,true);
End;

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
Form1.SGridSC.Cells[0,0]:=rsGUI0014;
Form1.SGridSC.Cells[0,1]:=rsGUI0015;
Form1.SGridSC.Cells[0,2]:=rsGUI0016;
form1.CBMultisend.Checked:=WO_Multisend;
End;

// Refresh the adressess grid
Procedure RefreshAddresses();
var
  counter : integer = 0;
Begin
Int_WalletBalance := 0;
EnterCriticalSection(CS_ARRAY_Addresses);
form1.SGridAddresses.RowCount:=length(ARRAY_Addresses)+1;
if length(ARRAY_Addresses)>0 then
   begin
   for counter := 0 to length(ARRAY_Addresses)-1 do
      begin
      form1.SGridAddresses.Cells[0,counter+1] := GetAddressToShow(ARRAY_Addresses[counter].Hash);
      form1.SGridAddresses.Cells[1,counter+1] := Int2Curr(ARRAY_Pending[counter].incoming);
      form1.SGridAddresses.Cells[2,counter+1] := Int2Curr(ARRAY_Pending[counter].outgoing);
      form1.SGridAddresses.Cells[3,counter+1] := Int2Curr(ARRAY_Addresses[counter].Balance);
      Int_WalletBalance := Int_WalletBalance+ARRAY_Addresses[counter].Balance;
      end;
   end;
LeaveCriticalSection(CS_ARRAY_Addresses);
form1.LBalance.Caption:=Format(rsGUI0009,[Int2Curr(Int_WalletBalance)]);
End;

// Refresh the nodes grid
Procedure RefreshNodes();
var
  counter : integer = 0;
Begin
form1.SGridNodes.RowCount:=length(ARRAY_Nodes)+1;
if length(ARRAY_Nodes)>0 then
   begin
   for counter := 0 to length(ARRAY_Nodes)-1 do
      begin
      form1.SGridNodes.Cells[0,counter+1] := ARRAY_Nodes[counter].Host;
      form1.SGridNodes.Cells[1,counter+1] := ARRAY_Nodes[counter].Block.ToString;
      form1.SGridNodes.Cells[2,counter+1] := ARRAY_Nodes[counter].Pending.ToString;
      form1.SGridNodes.Cells[3,counter+1] := ARRAY_Nodes[counter].Branch;
      end;
   end;
End;

// Refresh the status bar
Procedure RefreshStatus();
Begin
if Wallet_Synced then form1.PanelBlockInfo.Color:=clGreen
else form1.PanelBlockInfo.Color:=clRed;
form1.LabelBlockInfo.Caption:=WO_LastBlock.ToString;
form1.LabelTime.Caption:=TimestampToDate(G_UTCTime);
End;

END. // END UNIT

