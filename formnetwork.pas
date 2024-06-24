unit formnetwork;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids, nl_functions, nl_data;

type

  { TForm6 }

  TForm6 = class(TForm)
    LabelNodes: TLabel;
    SGridNodes: TStringGrid;
    procedure SGridNodesPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure SGridNodesResize(Sender: TObject);
  private

  public

  end;

var
  Form6: TForm6;

implementation



{$R *.lfm}

{ TForm6 }

procedure TForm6.SGridNodesResize(Sender: TObject);
var
  GridWidth : integer;
Begin
GridWidth := form6.Width;
SGridNodes.ColWidths[0] := ThisPercent(17,GridWidth);
SGridNodes.ColWidths[1] := ThisPercent(10,GridWidth);
SGridNodes.ColWidths[2] := ThisPercent(10,GridWidth);
SGridNodes.ColWidths[3] := ThisPercent(15,GridWidth);
SGridNodes.ColWidths[4] := ThisPercent(15,GridWidth);
SGridNodes.ColWidths[5] := ThisPercent(8,GridWidth);
SGridNodes.ColWidths[6] := ThisPercent(8,GridWidth);
SGridNodes.ColWidths[7] := ThisPercent(17,GridWidth,true);
end;

procedure TForm6.SGridNodesPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
var
  ts: TTextStyle;
Begin
ts := (Sender as TStringGrid).Canvas.TextStyle;
if aRow > 0 then
   begin
   {
   if ARRAY_Nodes[aRow-1].Updated=0 then (Sender as TStringGrid).Canvas.Brush.Color :=  clgreen;
   if ((ARRAY_Nodes[aRow-1].Updated>0) and (ARRAY_Nodes[aRow-1].Updated<6)) then (Sender as TStringGrid).Canvas.Brush.Color :=  clyellow;
   if ARRAY_Nodes[aRow-1].Updated>5 then (Sender as TStringGrid).Canvas.Brush.Color := clRed;
   if ( (ARRAY_Nodes[aRow-1].Updated=0) and (not ARRAY_Nodes[aRow-1].Synced) ) then (Sender as TStringGrid).Canvas.Brush.Color := clAqua;
   }
   end;
end;

end.

