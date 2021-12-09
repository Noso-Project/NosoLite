unit nl_GUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Procedure ResizeSGridAddresses();

implementation

uses
  nl_mainform;

// Returns the X percentage of a specified number
function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Begin
result := (percent*thiswidth) div 100;
if RestarBarra then result := result-19;
End;

// Resize the stringgrid containing the addresses
Procedure ResizeSGridAddresses();
var
  GridWidth : integer;
Begin
GridWidth := form1.SGridAddresses.Width;
form1.SGridAddresses.ColWidths[0] := ThisPercent(40,GridWidth);
form1.SGridAddresses.ColWidths[1] := ThisPercent(20,GridWidth);
form1.SGridAddresses.ColWidths[2] := ThisPercent(20,GridWidth);
form1.SGridAddresses.ColWidths[3] := ThisPercent(20,GridWidth,true);
End;

END. // END UNIT

