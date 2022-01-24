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
    Button1: TButton;
    Button2: TButton;
    Labelqrcode: TLabel;
    PnaelQRbuttons: TPanel;
    PanelQRcode: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  Form2: TForm2;
  QRAddress, QRKeys : string;

implementation

{$R *.lfm}

{ TForm2 }

// Show address at open
procedure TForm2.FormShow(Sender: TObject);
Begin
Labelqrcode.Font.Color:=clBlack;
BarcodeQR1.Text:=QRAddress;
Labelqrcode.Caption:=QRAddress;
End;

// Show address button
procedure TForm2.Button1Click(Sender: TObject);
Begin
Labelqrcode.Font.Color:=clBlack;
BarcodeQR1.Text:=QRAddress;
Labelqrcode.Caption:=QRAddress;
End;

// Show keys button
procedure TForm2.Button2Click(Sender: TObject);
Begin
Labelqrcode.Font.Color:=clRed;
BarcodeQR1.Text:=QRKeys;
Labelqrcode.Caption:='['+QRAddress+']';
End;

// Clean variables onclose
procedure TForm2.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Begin
QRAddress := '';
QRKeys := '';
End;

END.

