unit nl_functions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,strutils, nl_data;

function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
function Int2Curr(Value: int64): string;
Procedure LoadSeedNodes();
Function Parameter(LineText:String;ParamNumber:int64):String;
function Consensus():Boolean;

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

function Consensus():Boolean;
var
  counter, TotalNodes : integer;
  ArrT : array of ConsensusData;
  CBlock : integer = 0;

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
SetLength(ArrT,0);
For counter := 0 to length (ARRAY_Nodes)-1 do
   Begin
   AddValue(ARRAY_Nodes[counter].block.ToString);
   CBlock := GetHighest.ToInteger;
   End;
if CBlock <> WO_LastBlock then
   begin
   WO_LastBlock := CBlock;
   result := true;
   end;

End;

END. // END UNIT

