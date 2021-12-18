unit nl_functions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,strutils, nl_data, nl_language;

function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
function Int2Curr(Value: int64): string;
Procedure LoadSeedNodes();
Function Parameter(LineText:String;ParamNumber:int64):String;
function Consensus():Boolean;
function GetAddressBalanceFromSumary(address:string):int64;
function GetAddressToShow(address:string):String;
function IsAddressOnWallet(address:string):Boolean;
Procedure ToLog(StringToAdd:String);
function TryInsertAddress(Address:WalletData):boolean;

implementation

// Returns the X percentage of a specified number
function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Begin
result := (percent*thiswidth) div 100;
if RestarBarra then result := result-19;
End;

// Returns the GUI representation of any ammount of coins
function Int2Curr(Value: int64): string;
Begin
Result := IntTostr(Abs(Value));
result :=  AddChar('0',Result, 9);
Insert('.',Result, Length(Result)-7);
If Value <0 THen Result := '-'+Result;
End;

// Fill the nodes array with seed nodes data
Procedure LoadSeedNodes();
var
  counter : integer = 1;
  IsParamEmpty : boolean = false;
  ThisParam : string = '';
  ThisNode : NodeData;
Begin
Repeat
   begin
   ThisParam := parameter(STR_SeedNodes,counter);
   if ThisParam = '' then IsParamEmpty := true
   else
      begin
      ThisParam := StringReplace(ThisParam,':',' ',[rfReplaceAll, rfIgnoreCase]);
      ThisNode.host:=Parameter(ThisParam,0);
      ThisNode.port:=StrToIntDef(Parameter(ThisParam,1),8080);
      ThisNode.block:=0;
      ThisNode.Pending:=0;
      ThisNode.Branch:='';
      Insert(ThisNode,ARRAY_Nodes,length(ARRAY_Nodes));
      counter := counter+1;
      end;
   end;
until IsParamEmpty;
End;

// Returs parameters from a string
Function Parameter(LineText:String;ParamNumber:int64):String;
var
  Temp : String = '';
  ThisChar : Char;
  Contador : int64 = 1;
  WhiteSpaces : int64 = 0;
  parentesis : boolean = false;
Begin
while contador <= Length(LineText) do
   begin
   ThisChar := Linetext[contador];
   if ((thischar = '(') and (not parentesis)) then parentesis := true
   else if ((thischar = '(') and (parentesis)) then
      begin
      result := '';
      exit;
      end
   else if ((ThisChar = ')') and (parentesis)) then
      begin
      if WhiteSpaces = ParamNumber then
         begin
         result := temp;
         exit;
         end
      else
         begin
         parentesis := false;
         temp := '';
         end;
      end
   else if ((ThisChar = ' ') and (not parentesis)) then
      begin
      WhiteSpaces := WhiteSpaces +1;
      if WhiteSpaces > Paramnumber then
         begin
         result := temp;
         exit;
         end;
      end
   else if ((ThisChar = ' ') and (parentesis) and (WhiteSpaces = ParamNumber)) then
      begin
      temp := temp+ ThisChar;
      end
   else if WhiteSpaces = ParamNumber then temp := temp+ ThisChar;
   contador := contador+1;
   end;
if temp = ' ' then temp := '';
Result := Temp;
End;

// Calculates the mainnetconsensus
function Consensus():Boolean;
var
  counter, TotalNodes : integer;
  ArrT : array of ConsensusData;
  CBlock : integer = 0;
  CBranch : string = '';

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
Result := false;
// Get the consensus block number
SetLength(ArrT,0);
For counter := 0 to length (ARRAY_Nodes)-1 do
   Begin
   AddValue(ARRAY_Nodes[counter].block.ToString);
   CBlock := GetHighest.ToInteger;
   End;

// Get the consensus summary
SetLength(ArrT,0);
For counter := 0 to length (ARRAY_Nodes)-1 do
   Begin
   AddValue(ARRAY_Nodes[counter].Branch);
   CBranch := GetHighest;
   End;

if ((CBlock=WO_LastBlock) and (CBranch=WO_LastSumary) and (not Wallet_Synced)) then
   Begin
   Wallet_Synced := true;
   REF_Status := true;
   End;

if (CBlock>WO_LastBlock) then
   begin
   result := true;
   WO_LastBlock := CBlock;
   WO_LastSumary := CBranch;
   end;

End;

// Return the summary balance for the specified address
function GetAddressBalanceFromSumary(address:string):int64;
var
  cont : integer;
Begin
Result := 0;
for cont := 0 to length(ARRAY_Sumary)-1 do
   begin
   if ((address = ARRAY_Sumary[cont].Hash) or (address = ARRAY_Sumary[cont].Custom)) then
      begin
      result := ARRAY_Sumary[cont].Balance;
      break;
      end;
   end;
End;

// Returns the address OUTPUT to show: hash or custom (if any)
function GetAddressToShow(address:string):String;
var
  cont : integer;
Begin
result := address;
for cont := 0 to length(ARRAY_Sumary)-1 do
   begin
   if ((address = ARRAY_Sumary[cont].hash) and (ARRAY_Sumary[cont].custom <>'')) then
      begin
      result := ARRAY_Sumary[cont].custom;
      break;
      end;
   end;

End;

// Returns if an address exists in the wallet
function IsAddressOnWallet(address:string):Boolean;
var
  Counter : integer;
Begin
Result := false;
For Counter := 0 to length(ARRAY_Addresses)-1 do
   begin
   if ((address=ARRAY_Addresses[Counter].Hash) or (address=ARRAY_Addresses[Counter].Custom)) then
      begin
      result := true;
      break;
      end;
   end;
End;

// Adds a new line to the log
Procedure ToLog(StringToAdd:String);
Begin
EnterCriticalSection(CS_LOG);
LogLines.Add(Format(rsGUI0011,[DateTimeToStr(now),StringToAdd]));
LeaveCriticalSection(CS_LOG);
End;

// Trys to add a new address in the wallet
function TryInsertAddress(Address:WalletData):boolean;
Begin
result := false;
if not IsAddressOnWallet(Address.Hash) then
   begin
   EnterCriticalSection(CS_ARRAY_Addresses);
   Insert(Address,ARRAY_Addresses,length(ARRAY_Addresses));
   LeaveCriticalSection(CS_ARRAY_Addresses);
   result := true;
   SAVE_Wallet := true;
   REF_Addresses := true;
   ToLog(Format(rsGUI0012,[GetAddressToShow(Address.Hash)]));
   end
else
   begin
   ToLog(Format(rsError0007,[GetAddressToShow(Address.Hash)]));
   end;
End;

END. // END UNIT

