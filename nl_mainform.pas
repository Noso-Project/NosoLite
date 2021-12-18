unit nl_mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Grids, Menus, StdCtrls, nl_GUI, nl_disk, nl_data, nl_functions, IdTCPClient,
  nl_language, nl_cripto, Clipbrd, nl_explorer;

type

  { TForm1 }

  TForm1 = class(TForm)
    ImageBlockInfo: TImage;
    ImageSync: TImage;
    ImageDownload: TImage;
    LabelBlockInfo: TLabel;
    LabelCLock: TLabel;
    LBalance: TLabel;
    MainMenu: TMainMenu;
    MemoLog: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MM_File: TMenuItem;
    PageControl: TPageControl;
    PanelBlockInfo: TPanel;
    PanelBalance: TPanel;
    PanelSync: TPanel;
    PanelStatus: TPanel;
    PanelDownload: TPanel;
    PUMAddressess: TPopupMenu;
    SGridAddresses: TStringGrid;
    SGridNodes: TStringGrid;
    TabNodes: TTabSheet;
    TabLog: TTabSheet;
    TabWallet: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
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
// FORM RELATIVE EVENTS
//******************************************************************************

// On create form events
procedure TForm1.FormCreate(Sender: TObject);
Begin
// Initializae Critical sections
InitCriticalSection(CS_ARRAY_Addresses);
InitCriticalSection(CS_LOG);
//Initialize dynamic arrays
setlength(ARRAY_Addresses,0);
setlength(ARRAY_Nodes,0);
setlength(ARRAY_Sumary,0);
LogLines :=TStringList.create;
ClientChannel := TIdTCPClient.Create(form1);
LoadSeedNodes();

// Verify files structure
VerifyFilesStructure;

End;

// On show form events
procedure TForm1.FormShow(Sender: TObject);
Begin
LoadGUIInterface();
RefreshAddresses();
RefreshNodes();
RefreshStatus();

THREAD_Update := TUpdateThread.Create(true);
THREAD_Update.FreeOnTerminate:=true;
THREAD_Update.Start;
End;

// On resize form events
procedure TForm1.FormResize(Sender: TObject);
begin
ResizeSGridAddresses();
ResizeSGridNodes();
end;

// On close query form events
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
Begin
THREAD_Update.Terminate;
THREAD_Update.WaitFor;
SaveOptions;
End;

// On close form events
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Begin
DoneCriticalSection(CS_ARRAY_Addresses);
DoneCriticalSection(CS_LOG);
ClientChannel.Free;
LogLines.Free;
application.Terminate;
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

//******************************************************************************
// Addresses Pop Up menu
//******************************************************************************

// Import address from keys
procedure TForm1.MenuItem3Click(Sender: TObject);
var
  UserString : string = '';
  InputResult : boolean;
Begin
InputResult := InputQuery(rsDIA0001, rsDIA0002, TRUE, UserString);
if ((InputResult) and (UserString<>'')) then ImportKeys(UserString);
End;

// Copy address to clipboard
procedure TForm1.MenuItem4Click(Sender: TObject);
begin
if SGridAddresses.Row>0 then Clipboard.AsText:=SGridAddresses.Cells[0,SGridAddresses.Row];
end;

// Generate new address
procedure TForm1.MenuItem5Click(Sender: TObject);
Begin
TryInsertAddress(CreateNewAddress);
End;

// Import addresses from file
procedure TForm1.MenuItem2Click(Sender: TObject);
begin
ShowExplorer(GetCurrentDir,rsGUI0010,'*.pkw',true);
end;

END. // END PROGRAM

