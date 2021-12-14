unit nl_mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Grids, Menus, StdCtrls, nl_GUI, nl_disk, nl_data;

type

  { TForm1 }

  TForm1 = class(TForm)
    LBalance: TLabel;
    MainMenu: TMainMenu;
    MM_File: TMenuItem;
    PageControl: TPageControl;
    PanelBalance: TPanel;
    PanelStatus: TPanel;
    SGridAddresses: TStringGrid;
    TabWallet: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure SGridAddressesPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

//******************************************************************************
// FORME RELATIVE EVENTS
//******************************************************************************

// On create form events
procedure TForm1.FormCreate(Sender: TObject);
Begin
//Initialize dynamic arrays
setlength(ARRAY_Addresses,0);
// Verify files structure
VerifyFilesStructure;

End;

// On show form events
procedure TForm1.FormShow(Sender: TObject);
Begin
LoadGUIInterface();
RefreshAddresses();
End;

// On resize form events
procedure TForm1.FormResize(Sender: TObject);
begin
ResizeSGridAddresses();
end;

// On close query form events
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
Begin

End;

// On close form events
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Begin

End;

// Prepare canvas for adressess grid
procedure TForm1.SGridAddressesPrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  ts: TTextStyle;
Begin
if (ACol>0)  then
   begin
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (Sender as TStringGrid).Canvas.TextStyle := ts;
   end;

End;



END. // END PROGRAM

