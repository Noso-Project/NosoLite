unit nl_functions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,strutils;

function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
function Int2Curr(Value: int64): string;

implementation

// Returns the X percentage of a specified number
function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Begin
result := (percent*thiswidth) div 100;
if RestarBarra then result := result-19;
End;

// Returns the GUI representation of any ammount of coins
function Int2Curr(Value: int64): string;
begin
Result := IntTostr(Abs(Value));
result :=  AddChar('0',Result, 9);
Insert('.',Result, Length(Result)-7);
If Value <0 THen Result := '-'+Result;
end;

END. // END UNIT

