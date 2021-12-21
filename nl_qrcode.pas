unit nl_qrcode;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ubarcodes;

type

  { TForm2 }

  TForm2 = class(TForm)
    BarcodeQR1: TBarcodeQR;
    Labelqrcode: TLabel;
    PanelQRcode: TPanel;
  private

  public

  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

end.

