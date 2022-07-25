unit nl_functions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,strutils, nl_data, nl_language, dateutils;

// General functions
function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
function Int2Curr(Value: int64): string;
Function Parameter(LineText:String;ParamNumber:int64):String;
Function IsValidCustomName(AddNAme:String):Boolean;

// Array nodes functions
Procedure LoadSeedNodes(STR_Source:string);
Function GetNodeIndex(Index:integer):NodeData;
Function ArrayNodesLength():integer;
Function PickRandomNode():NodeData;

// Time related
function UTCTime():int64;
function TimestampToDate(timestamp:int64):String;
function TimeSinceStamp(value:int64):string;
Function BlockAge():integer;

// Network

function Consensus():Boolean;
Function GetSumaryLastBlock():Integer;
function GetAddressBalanceFromSumary(address:string):int64;
function GetAddressPendingPays(address : string):int64;
function GetAddressToShow(address:string):String;
function IsAddressOnWallet(address:string):Boolean;
Procedure ToLog(StringToAdd:String);
function TryInsertAddress(Address:WalletData):boolean;
function GetMaximunToSend(ammount:int64):int64;
function IsValidAddressHash(Address:String):boolean;
function IsValid58(base58text:string):boolean;
function AddressSumaryIndex(Address:string):integer;


function GetFee(monto:int64):Int64;
function GetOrderHash(TextLine:string):String;
function GetTransferHash(TextLine:string):String;
Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; reference,
  ordertime:String;linea:integer):OrderData;
function GetPTCEcn(OrderType:String):String;
function GetStringFromOrder(order:orderdata):String;
function WalletAddressIndex(address:string):integer;
function isAddressLocked(address:walletdata):boolean;
Procedure UpdateWalletFromSumary();
Procedure ProcessPendings();

// Masternodes
Procedure SetMasterNodes(TValue:string);
Function GetMasternodes():String;
Function MasternodesLastBlock():Integer;

// Labels
Function GetLabelAddress(Address:String):String;
Procedure SetLabelValue(Address,LabelStr:String);


implementation

uses
  nl_cripto, nl_network, nl_Disk;

// ***************
// *** GENERAL ***
// ***************

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

// Verify if an address custom name is valid
Function IsValidCustomName(AddNAme:String):Boolean;
var
  counter : integer;
Begin
Result := true;
if ((length(AddNAme) <5) or (length(AddNAme) >40)) then
   begin
   result := false;
   exit;
   end;
for counter := 1 to length(AddNAme) do
   begin
   if pos(AddNAme[counter],CustomValid)=0 then
      begin
      Result := false;
      break;
      end;
   end;
End;

// ******************
// *** ARRAY NODES ***
// ******************

// Fill the nodes array with nodes data
Procedure LoadSeedNodes(STR_Source:string);
var
  counter      : integer = 1;
  IsParamEmpty : boolean = false;
  ThisParam    : string = '';
  ThisNode     : NodeData;
  IpAndPort    : string;
Begin
EnterCriticalSection(CS_ArrayNodes);
SetLEngth(ARRAY_Nodes,0);
Repeat
   begin
   ThisParam := parameter(STR_Source,counter);
   if ThisParam = '' then IsParamEmpty := true
   else
      begin
      ThisNode := Default(NodeData);
      ThisParam := StringReplace(ThisParam,':',' ',[rfReplaceAll, rfIgnoreCase]);
      IpAndPort := Parameter(ThisParam,0);
      IpAndPort :=  StringReplace(ThisParam,';',' ',[rfReplaceAll, rfIgnoreCase]);
      ThisNode.host:=Parameter(IpAndPort,0);
      ThisNode.port:=StrToIntDef(Parameter(IpAndPort,1),8080);
      ThisNode.block:=0;
      ThisNode.Pending:=0;
      ThisNode.updated:=0;
      ThisNode.Branch:='';
      Insert(ThisNode,ARRAY_Nodes,length(ARRAY_Nodes));
      counter := counter+1;
      end;
   end;
until IsParamEmpty;
LeaveCriticalSection(CS_ArrayNodes);
End;

// Returns a specific node data
Function GetNodeIndex(Index:integer):NodeData;
Begin
if index > ArrayNodesLength then
   begin
   result := Default(NodeData);
   exit;
   end;
EnterCriticalSection(CS_ArrayNodes);
Result := ARRAY_Nodes[index];
LeaveCriticalSection(CS_ArrayNodes);
End;

Function ArrayNodesLength():integer;
Begin
EnterCriticalSection(CS_ArrayNodes);
Result := Length(ARRAY_Nodes);
LeaveCriticalSection(CS_ArrayNodes);
End;

Function PickRandomNode():NodeData;
var
  TNumber : integer = 0;
  Trys   : integer = 0;
Begin
Result := Default(NodeData);
if ArrayNodesLength>0 then
   begin
   REPEAT
      TNumber := Random(ArrayNodesLength);
      Inc(Trys);
   UNTIL ( (GetNodeIndex(Tnumber).Synced) or (Trys >= ArrayNodesLength) );
   Result := GetNodeIndex(Tnumber);
   end;
End;

// ************
// *** TIME ***
// ************

// Returns the UTCTime
function UTCTime():int64;
var
  G_TIMEUTCTimeOffset : int64;
  GetUTCTimestamp : int64;
Begin
G_TIMEUTCTimeOffset := GetLocalTimeOffset*60;
GetUTCTimestamp := DateTimeToUnix(now);
result := GetUTCTimestamp+G_TIMEUTCTimeOffset-MainNetOffSet;
End;

// Returns a DateTime format from a Unix time
function TimestampToDate(timestamp:int64):String;
var
  DateToShow : TDateTime;
begin
DateToShow := UnixToDateTime(timestamp);
result := DateTimeToStr(DateToShow);
end;

//Shows time since timestamp
function TimeSinceStamp(value:int64):string;
var
CurrStamp : Int64 = 0;
Diferencia : Int64 = 0;
Begin
CurrStamp := UTCTime;
Diferencia := CurrStamp - value;
if diferencia div 60 < 1 then result := '<1m'
else if diferencia div 3600 < 1 then result := IntToStr(diferencia div 60)+'m'
else if diferencia div 86400 < 1 then result := IntToStr(diferencia div 3600)+'h'
else if diferencia div 2592000 < 1 then result := IntToStr(diferencia div 86400)+'d'
else if diferencia div 31536000 < 1 then result := IntToStr(diferencia div 2592000)+'M'
else result := IntToStr(diferencia div 31536000)+' Y'
end;

Function BlockAge():integer;
Begin
Result := UTCtime mod 600;
End;

// ***************
// *** NETWORK ***
// ***************


// Calculates the mainnet consensus
function Consensus():Boolean;
var
  counter : integer;
  ArrT : array of ConsensusData;
  CBlock : integer = 0;
  CBranch : string = '';
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

// Get the consensus pendings
SetLength(ArrT,0);
For counter := 0 to length (ARRAY_Nodes)-1 do
   Begin
   AddValue(ARRAY_Nodes[counter].Pending.ToString);
   cPending := GetHighest.ToInteger;
   End;

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
End;

// Returns the last block updated on sumary
Function GetSumaryLastBlock():Integer;
Begin
if length(ARRAY_Sumary) = 0 then result := 0
else result := ARRAY_Sumary[0].LastOP;
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

function GetAddressPendingPays(address : string):int64;
Begin
result := 0;
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
   insert(Default(PendingData),ARRAY_Pending,length(ARRAY_Pending));
   ToLog(Format(rsGUI0012,[GetAddressToShow(Address.Hash)]));
   end
else
   begin
   ToLog(Format(rsError0007,[GetAddressToShow(Address.Hash)]));
   end;
End;

// Returns the maximun ammount that can be send
function GetMaximunToSend(ammount:int64):int64;
var
  Available : int64;
  maximum : int64;
  Fee : int64;
  SenT : int64;
  Diff : int64;
Begin
Available := ammount;
maximum := (Available * Comisiontrfr) div (Comisiontrfr+1);
Fee := maximum div Comisiontrfr;
SenT := maximum + Fee;
Diff := Available-SenT;
result := maximum+Diff;
End;

// Checks if a string is a valid address
function IsValidAddressHash(Address:String):boolean;
var
  OrigHash : String;
  Clave:String;
Begin
result := false;
trim(address);
if ((length(address)>20) and (address[1] = 'N') ) then
   begin
   OrigHash := Copy(Address,2,length(address)-3);
   if IsValid58(OrigHash) then
      begin
      Clave := BMDecTo58(BMB58resumen(OrigHash));
      OrigHash := 'N'+OrigHash+clave;
      if OrigHash = Address then result := true else result := false;
      end;
   end
End;

// Returns if a string is a valid Base58
function IsValid58(base58text:string):boolean;
var
  counter : integer;
Begin
result := true;
if length(base58text) > 0 then
   begin
   for counter := 1 to length(base58text) do
      begin
      if pos (base58text[counter],B58Alphabet) = 0 then
         begin
         result := false;
         break;
         end;
      end;
   end
else result := false;
End;

// Returns the address sumary index
function AddressSumaryIndex(Address:string):integer;
var
  cont : integer = 0;
Begin
result := -1;
trim(Address);
if ((address <> '') and (length(ARRAY_Sumary) > 0)) then
   begin
   for cont := 0 to length(ARRAY_Sumary)-1 do
      begin
      if ((ARRAY_Sumary[cont].Hash=address) or (ARRAY_Sumary[cont].Custom=address)) then
         begin
         result:= cont;
         break;
         end;
      end;
   end;
End;





// Returns the fee
function GetFee(monto:int64):Int64;
Begin
Result := monto div Comisiontrfr;
if result < MinimunFee then result := MinimunFee;
End;

// Returns a order hash
function GetOrderHash(TextLine:string):String;
Begin
Result := HashSHA256String(TextLine);
Result := 'OR'+BMHexTo58(Result,36);
End;

// Returns a transfer hash
function GetTransferHash(TextLine:string):String;
var
  Resultado : String = '';
  Sumatoria, clave : string;
Begin
Resultado := HashSHA256String(TextLine);
Resultado := BMHexTo58(Resultado,58);
sumatoria := BMB58resumen(Resultado);
clave := BMDecTo58(sumatoria);
Result := 'tR'+Resultado+clave;
End;

Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; reference,
  ordertime:String;linea:integer):OrderData;
var
  MontoDisponible, Montotrfr, comisionTrfr : int64;
  OrderInfo : orderdata;
Begin

MontoDisponible := ARRAY_Addresses[WalletAddressIndex(origen)].Balance-GetAddressPendingPays(Origen);
if MontoDisponible>comision then ComisionTrfr := Comision
else comisiontrfr := montodisponible;
if montodisponible>monto+comision then montotrfr := monto
else montotrfr := montodisponible-comision;
if montotrfr <0 then montotrfr := 0;
OrderInfo := Default(OrderData);
OrderInfo.OrderID    := '';
OrderInfo.OrderLines := 1;
OrderInfo.OrderType  := 'TRFR';
OrderInfo.TimeStamp  := StrToInt64(OrderTime);
OrderInfo.reference  := reference;
OrderInfo.TrxLine    := linea;
OrderInfo.Sender     := ARRAY_Addresses[WalletAddressIndex(origen)].PublicKey;
OrderInfo.Address    := ARRAY_Addresses[WalletAddressIndex(origen)].Hash;
OrderInfo.Receiver   := Destino;
OrderInfo.AmmountFee := ComisionTrfr;
OrderInfo.AmmountTrf := montotrfr;
OrderInfo.Signature  := GetStringSigned(ordertime+origen+destino+IntToStr(montotrfr)+
                     IntToStr(comisiontrfr)+IntToStr(linea),
                     ARRAY_Addresses[WalletAddressIndex(origen)].PrivateKey);
OrderInfo.TrfrID     := GetTransferHash(ordertime+origen+destino+IntToStr(monto)+IntToStr(WO_LastBlock));
Result := OrderInfo;
End;

// Returns the header
function GetPTCEcn(OrderType:String):String;
Begin
result := 'NSL'+OrderType+' '+IntToStr(protocol)+' '+ProgramVersion+' '+UTCTime.ToString+' ';
End;

// Returns an string from a order data
function GetStringFromOrder(order:orderdata):String;
Begin
result:= Order.OrderType+' '+
         Order.OrderID+' '+
         IntToStr(order.OrderLines)+' '+
         order.OrderType+' '+
         IntToStr(Order.TimeStamp)+' '+
         Order.reference+' '+
         IntToStr(order.TrxLine)+' '+
         order.Sender+' '+
         Order.Address+' '+
         Order.Receiver+' '+
         IntToStr(Order.AmmountFee)+' '+
         IntToStr(Order.AmmountTrf)+' '+
         Order.Signature+' '+
         Order.TrfrID;
End;

// Returns the wallet index of the specified address
function WalletAddressIndex(address:string):integer;
var
  counter : integer = 0;
Begin
Result := -1;
for counter := 0 to length(ARRAY_Addresses)-1 do
   begin
   if ((ARRAY_Addresses[counter].Hash = address) or (ARRAY_Addresses[counter].Custom = address )) then
      begin
      result := counter;
      break;
      end;
   end;
if ( (not IsValidAddressHash(address)) and (AddressSumaryIndex(address)<0) ) then result := -1;
End;

// Return if a wallet is locked
function isAddressLocked(address:walletdata):boolean;
Begin
if copy(address.PrivateKey,1,1) = '*' then result := true
else result := false;
End;

// Updates the wallet balances from the available sumary file
Procedure UpdateWalletFromSumary();
var
  counter : integer;
Begin
EnterCriticalSection(CS_ARRAY_Addresses);
for counter := 0 to length(ARRAY_Addresses)-1 do
   begin
   ARRAY_Addresses[counter].Balance:=GetAddressBalanceFromSumary(ARRAY_Addresses[counter].Hash);
   end;
LeaveCriticalSection(CS_ARRAY_Addresses);
setlength(ARRAY_Pending,length(ARRAY_Addresses));
End;

Procedure ProcessPendings();
var
  ThisOrder : String;
  Counter : integer = 0;
  TO_type, TO_sender, TO_Receiver : string;
  TO_ammount, TO_fee : int64;
  add_Index : integer;
Begin
setlength(ARRAY_Pending,0);
setlength(ARRAY_Pending,length(ARRAY_Addresses));
repeat
   begin
   thisorder := parameter(Pendings_String,counter);
   if thisorder <> '' then
      begin
      thisorder :=StringReplace(thisorder,',',' ',[rfReplaceAll, rfIgnoreCase]);
      TO_type := parameter(thisorder,0);
      TO_sender := parameter(thisorder,1);
      TO_Receiver := parameter(thisorder,2);
      TO_ammount := parameter(thisorder,3).ToInt64;
      TO_fee := parameter(thisorder,4).ToInt64;
      if TO_type = 'TRFR' then
         begin

         add_Index := WalletAddressIndex(TO_sender);
         if add_Index >= 0 then
            ARRAY_Pending[add_Index].outgoing:=ARRAY_Pending[add_Index].outgoing+TO_ammount+TO_fee;
         add_Index := WalletAddressIndex(TO_Receiver);
         if add_Index >= 0 then
            ARRAY_Pending[add_Index].incoming:=ARRAY_Pending[add_Index].incoming+TO_ammount;

         end;
      end;
   counter := counter+1;
   end;
until thisorder = '';
//tolog(Pendings_String);
End;

// MASTERNODES

Procedure SetMasterNodes(TValue:string);
Begin
EnterCriticalSection(CS_Masternodes);
G_Masternodes := TValue;
LeaveCriticalSection(CS_Masternodes);
End;

Function GetMasternodes():String;
Begin
EnterCriticalSection(CS_Masternodes);
Result := G_Masternodes;
LeaveCriticalSection(CS_Masternodes);
End;

Function MasternodesLastBlock():Integer;
Begin
EnterCriticalSection(CS_Masternodes);
Result := StrToIntDef(Parameter(G_Masternodes,0),0);
LeaveCriticalSection(CS_Masternodes);
End;

// Labels

Function GetLabelAddress(Address:String):String;
var
  Counter : integer;
Begin
result := '';
For counter := 0 to length(ARRAY_Labels)-1 do
   begin
   if ARRAY_Labels[counter].Address=Address then
      begin
      result := ARRAY_Labels[counter].LabelSt;
      Break;
      end;
   end;
End;

Procedure SetLabelValue(Address,LabelStr:string);
var
  Counter : integer;
  Added   : boolean = false;
  NewLabel: TypeLabel;
Begin
For counter := 0 to length(ARRAY_Labels)-1 do
   begin
   if ARRAY_Labels[counter].Address=address then
      begin
      ARRAY_Labels[counter].LabelSt:=LabelStr;
      if LabelStr = '' then Delete(ARRAY_Labels,counter,1);
      Added := true;
      break;
      end;
   end;
If not Added then
   begin
   NewLabel.Address:=Address;
   NewLabel.LabelSt:=LabelStr;
   Insert(NewLAbel,ARRAY_Labels,length(ARRAY_Labels));
   end;
SaveLabelsToDisk();
End;

END. // END UNIT

