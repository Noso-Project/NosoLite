unit nl_mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Grids, Menus, StdCtrls, nl_GUI, nl_disk, nl_data, nl_functions, IdTCPClient,
  nl_language, nl_cripto, Clipbrd, Buttons, Spin, nl_explorer, IdComponent, strutils, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    CBMultisend: TCheckBox;
    ClientChannel: TIdTCPClient;
    EditSCDest: TEdit;
    EditSCMont: TEdit;
    ImageBlockInfo: TImage;
    ImageList: TImageList;
    ImageSync: TImage;
    ImageDownload: TImage;
    ImgSCDest: TImage;
    ImgSCMont: TImage;
    LabelTime: TLabel;
    LabelDownload: TLabel;
    LabelBlockInfo: TLabel;
    LabelCLock: TLabel;
    LBalance: TLabel;
    LSCTop: TLabel;
    MainMenu: TMainMenu;
    MemoLog: TMemo;
    MemoSCCon: TMemo;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    MM_File: TMenuItem;
    PageControl: TPageControl;
    PanelDown: TPanel;
    PanelBlockInfo: TPanel;
    PanelBalance: TPanel;
    PanelSend: TPanel;
    PanelSync: TPanel;
    PanelStatus: TPanel;
    PanelDownload: TPanel;
    POMRefresh: TPopupMenu;
    PUMAddressess: TPopupMenu;
    SBSCMax: TSpeedButton;
    SBSCPaste: TSpeedButton;
    SCBitCancel: TBitBtn;
    SCBitClea: TBitBtn;
    SCBitConf: TBitBtn;
    SCBitSend: TBitBtn;
    SGridAddresses: TStringGrid;
    SGridNodes: TStringGrid;
    SGridSC: TStringGrid;
    TabNodes: TTabSheet;
    TabLog: TTabSheet;
    TabWallet: TTabSheet;
    procedure CBMultisendChange(Sender: TObject);
    procedure ClientChannelWork(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);
    procedure ClientChannelWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure ClientChannelWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    procedure EditSCDestChange(Sender: TObject);
    procedure EditSCMontChange(Sender: TObject);
    procedure EditSCMontKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuItem14Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure PanelBlockInfoContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure SBSCMaxClick(Sender: TObject);
    procedure SBSCPasteClick(Sender: TObject);
    procedure SCBitCancelClick(Sender: TObject);
    procedure SCBitCleaClick(Sender: TObject);
    procedure SCBitConfClick(Sender: TObject);
    procedure SCBitSendClick(Sender: TObject);
    procedure SGridAddressesContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure SGridAddressesDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure SGridAddressesPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
  private

  public

  end;

function IsValidDestination(Address:string):boolean;

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
Closing_App := true;
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

// Grid addresses draw cell
procedure TForm1.SGridAddressesDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Bitmap    : TBitmap;
  myRect    : TRect;
  CurrPos   : integer;
  ColWidth : Integer;
Begin
CurrPos := aRow-1;
if ((CurrPos >=0) and (Acol = 0)) then
   begin
   if copy(ARRAY_Addresses[CurrPos].PrivateKey,1,1) = '*' then
      begin
      ColWidth := (sender as TStringGrid).ColWidths[0];
      Bitmap:=TBitmap.Create;
      ImageList.GetBitmap(2,Bitmap);
      myRect := Arect;
      myrect.Left:=ColWidth-20;
      myRect.Right := ColWidth-4;
      myrect.top:=myrect.Top+2;
      myrect.Bottom:=myrect.Top+18;
      (sender as TStringGrid).Canvas.StretchDraw(myRect,bitmap);
      Bitmap.free
      end;
   end;
End;

//******************************************************************************
// Client channel
//******************************************************************************

// On work begin
procedure TForm1.ClientChannelWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
Begin
Int_SumarySize := AWorkCountMax;
End;

// Client on work
procedure TForm1.ClientChannelWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
Begin
//Form1.LabelDownload.Caption:=IntToStr(((AWorkCount*100) div Int_SumarySize))+' %';
End;

// On work end
procedure TForm1.ClientChannelWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
Begin
Tolog(format(rsGUI0013,[Int_SumarySize div 1024]));
//Form1.LabelDownload.Caption  := '0 %';
End;


//******************************************************************************
// Addresses Pop Up menu
//******************************************************************************

// On context pop up; before showing the menu
procedure TForm1.SGridAddressesContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
if copy(ARRAY_Addresses[SGridAddresses.Row-1].PrivateKey,1,1) = '*' then
   begin
   menuitem9.Visible:=false;
   menuitem10.Visible:=true;
   end
else
   begin
   menuitem9.Visible:=true;
   menuitem10.Visible:=false;
   end;
end;

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

// Set address as default
procedure TForm1.MenuItem6Click(Sender: TObject);
var
  CurrentW, FirstW : WalletData;
  CurrPosition : integer;
Begin
if SGridAddresses.Row > 1 then
   begin
   EnterCriticalSection(CS_ARRAY_Addresses);
   CurrPosition := SGridAddresses.Row-1;
   CurrentW := ARRAY_Addresses[CurrPosition];
   FirstW := ARRAY_Addresses[0];
   ARRAY_Addresses[CurrPosition] := FirstW;
   ARRAY_Addresses[0] := CurrentW;
   LeaveCriticalSection(CS_ARRAY_Addresses);
   REF_Addresses := true;
   SAVE_Wallet := true;
   end;
End;

// Delete address
procedure TForm1.MenuItem8Click(Sender: TObject);
var
  CurrWallet : walletData;
  CurrPosition : integer;
Begin
if length(ARRAY_Addresses)>1 then
   begin
   CurrPosition := SGridAddresses.Row-1;
   EnterCriticalSection(CS_ARRAY_Addresses);
   CurrWallet := ARRAY_Addresses[CurrPosition];
   Delete(ARRAY_Addresses,CurrPosition,1);
   LeaveCriticalSection(CS_ARRAY_Addresses);
   MoveAddressToTrash(CurrWallet);
   SAVE_Wallet := true;
   REF_Addresses := true;
   end
else ToLog(rsError0009);
End;

// Lock Address
procedure TForm1.MenuItem9Click(Sender: TObject);
var
  pass1, pass2 : string;
  PassHash : String;
  crypted : string;
  CurrPos : integer;
Begin
CurrPos := SGridAddresses.Row-1;
pass1 := InputBox('Lock address','Please enter your password', '');
if length(pass1)<8 then
   begin
   ShowMessage(rsDIA0004);
   end
else
   begin
   pass2 := InputBox('Lock address','Confirm your password', '');
   if pass1 <> pass2 then
      begin
      ShowMessage(rsDIA0005);
      end
   else
      begin
      PassHash := HashSha256String(pass1);
      crypted := '*'+XorEncode(PassHash,ARRAY_Addresses[CurrPos].PrivateKey);
      ARRAY_Addresses[CurrPos].PrivateKey := crypted;
      REF_Addresses := true;
      SAVE_Wallet := true;
      end
   end;
End;



// Unlock address
procedure TForm1.MenuItem10Click(Sender: TObject);
var
  CurrPos : integer;
  pass1: string;
  PassHash : String;
  crypted, decrypted : string;
  Signature : String;
  SignProcess : boolean = false;
begin
CurrPos := SGridAddresses.Row-1;
pass1 := InputBox('Unlock address','Please enter your password', '');
if length(pass1)<8 then
   begin
   ShowMessage(rsDIA0004);
   end
else
   begin
   PassHash := HashSha256String(pass1);
   crypted := ARRAY_Addresses[CurrPos].PrivateKey;
   delete(Crypted,1,1);
   decrypted := XorDecode(PassHash, crypted);
   TRY
   Signature := GetStringSigned('VERIFICATION',decrypted);
   SignProcess := VerifySignedString('VERIFICATION',signature,ARRAY_Addresses[CurrPos].PublicKey);
   EXCEPT on E:Exception do
      begin
      ToLog(format(rsError0011,[ARRAY_Addresses[CurrPos].Hash]));
      end;
   END{Try};
   if SignProcess then
      begin
      ARRAY_Addresses[CurrPos].PrivateKey := decrypted;
      REF_Addresses := true;
      SAVE_Wallet := true;
      end
   else ToLog(format(rsError0011,[ARRAY_Addresses[CurrPos].Hash]));
   end;
end;

// Import addresses from file
procedure TForm1.MenuItem2Click(Sender: TObject);
begin
ShowExplorer(GetCurrentDir,rsGUI0010,'*.pkw',true);
end;

//******************************************************************************
// Refresh PoP Up menu
//******************************************************************************

// On popup menu
procedure TForm1.PanelBlockInfoContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
Begin
menuitem11.Checked:=false;
menuitem12.Checked:=false;
menuitem13.Checked:=false;
menuitem14.Checked:=false;
if WO_Refreshrate = 15 then menuitem11.Checked:=true;
if WO_Refreshrate = 60 then menuitem12.Checked:=true;
if WO_Refreshrate = 600 then menuitem13.Checked:=true;
if WO_Refreshrate = 0 then menuitem14.Checked:=true;
End;

// 15 segs
procedure TForm1.MenuItem11Click(Sender: TObject);
Begin
WO_Refreshrate := 15;
SaveOptions;
End;

procedure TForm1.MenuItem12Click(Sender: TObject);
begin
WO_Refreshrate := 60;
SaveOptions;
end;

procedure TForm1.MenuItem13Click(Sender: TObject);
begin
WO_Refreshrate := 600;
SaveOptions;
end;

procedure TForm1.MenuItem14Click(Sender: TObject);
begin
WO_Refreshrate := 0;
SaveOptions;
end;

//******************************************************************************
// Send coins panel
//******************************************************************************

function IsValidDestination(Address:string):boolean;
Begin
result := false;
if AddressSumaryIndex(Address)>=0 then result := true;
if IsValidAddressHash(Address) then result := true;
End;

// Copy clipboard to destination
procedure TForm1.SBSCPasteClick(Sender: TObject);
Begin
EditSCDest.Text:=Clipboard.AsText;
End;

// Button cancel on click
procedure TForm1.SCBitCancelClick(Sender: TObject);
Begin
EditSCDest.Enabled:=true;
EditSCMont.Enabled:=true;
MemoSCCon.Enabled:=true;
SCBitSend.Visible:=true;
SCBitConf.Visible:=false;
SCBitCancel.Visible:=false;
End;

// Clear panel
procedure TForm1.SCBitCleaClick(Sender: TObject);
Begin
EditSCDest.Enabled:=true;EditSCDest.Text:='';
EditSCMont.Enabled:=true;EditSCMont.Text:='0.00000000';
MemoSCCon.Enabled:=true;MemoSCCon.Text:='';
SCBitSend.Visible:=true;
SCBitConf.Visible:=false;
SCBitCancel.Visible:=false;
End;

// Confirm button click
procedure TForm1.SCBitConfClick(Sender: TObject);
var
  ammount : int64;
Begin
ammount := StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1);
SendTo(EditSCDest.Text,ammount,MemoSCCon.Text);
SCBitCleaClick(nil);
End;

// Send button click
procedure TForm1.SCBitSendClick(Sender: TObject);
var
  ammount : int64;
Begin
EditSCDest.Text :=StringReplace(EditSCDest.Text,' ','',[rfReplaceAll, rfIgnoreCase]);
ammount := StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1);
if ( (IsValidDestination(EditSCDest.Text) ) and
   (ammount>0) and
   (ammount<=GetMaximunToSend(Int_WalletBalance)) ) then
   begin
   MemoSCCon.Text:=Parameter(MemoSCCon.text,0);
   EditSCDest.Enabled:=false;
   EditSCMont.Enabled:=false;
   MemoSCCon.Enabled:=false;
   SCBitSend.Visible:=false;
   SCBitConf.Visible:=true;
   SCBitCancel.Visible:=true;
   end
else ToLog(rsError0010);
End;

// Set the maximun available ammount
procedure TForm1.SBSCMaxClick(Sender: TObject);
Begin
if WO_MultiSend then EditSCMont.Text:=Int2curr(GetMaximunToSend(Int_WalletBalance))
else EditSCMont.Text:=Int2Curr(GetMaximunToSend(ARRAY_Addresses[0].Balance))
End;

// Change the WO_Multisend status
procedure TForm1.CBMultisendChange(Sender: TObject);
Begin
if CBMultisend.Checked then WO_Multisend := true
else WO_Multisend := false;
SaveOptions;
End;

// Destination edit on change
procedure TForm1.EditSCDestChange(Sender: TObject);
Begin
EditSCDest.Text :=StringReplace(EditSCDest.Text,' ','',[rfReplaceAll, rfIgnoreCase]);
if EditSCDest.Text = '' then ImgSCDest.Picture.Clear
else
   begin
   if ((IsValidAddressHash(EditSCDest.Text)) or (AddressSumaryIndex(EditSCDest.Text)>=0)) then
     Form1.ImageList.GetBitmap(0,ImgSCDest.Picture.Bitmap)
   else Form1.ImageList.GetBitmap(1,ImgSCDest.Picture.Bitmap);
   end;
End;

// Ammount edit on change
procedure TForm1.EditSCMontChange(Sender: TObject);
var
  ammount : int64;
Begin
ammount := StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1);
if ((ammount>0) and (ammount<=GetMaximunToSend(Int_WalletBalance)))then
  begin
  Form1.ImageList.GetBitmap(0,ImgSCMont.Picture.Bitmap);
  end
else Form1.ImageList.GetBitmap(1,ImgSCMont.Picture.Bitmap);
if EditSCMont.Text = '0.00000000' then ImgSCMont.Picture.Clear;
End;

// Ammount edit on key pressed
procedure TForm1.EditSCMontKeyPress(Sender: TObject; var Key: char);
var
  Permitido : string = '1234567890.';
  Ultimo    : char;
  Actualmente : string;
  currpos : integer;
  ParteEntera : string;
  ParteDecimal : string;
  PosicionEnElPunto : integer;
Begin
if key = chr(27) then          // ESC keys clears
  begin
  EditSCMont.Text := '0.00000000';
  EditSCMont.SelStart := 1;
  exit;
  end;
ultimo := char(key);
if pos(ultimo,permitido)= 0 then exit;  // Not valid key
Actualmente := EditSCMont.Text;
PosicionEnElPunto := Length(Actualmente)-9;
currpos := EditSCMont.SelStart;
if key = '.' then                      // decimal point
   begin
   EditSCMont.SelStart := length(EditSCMont.Text)-8;
   exit;
   end;
if ((EditSCMont.SelStart > length(EditSCMont.Text)-9) and
   (EditSCMont.SelStart < length(EditSCMont.Text)))    then // it is in decimals
   begin
   Actualmente[currpos+1] := ultimo;
   EditSCMont.Text:=Actualmente;
   EditSCMont.SelStart := currpos+1;
   end;
if EditSCMont.SelStart <= length(EditSCMont.Text)-9 then // it is in integers
   begin
   ParteEntera := copy(actualmente,1,length(Actualmente)-9);
   ParteDecimal := copy(actualmente,length(Actualmente)-7,8);
   if currpos = PosicionEnElPunto then // esta justo antes del punto
      begin
      if length(parteentera)>7 then exit;
      ParteEntera := ParteEntera+Ultimo;
      ParteEntera := IntToStr(StrToIntDef(ParteEntera,0));
      actualmente := parteentera+'.'+partedecimal;
      EditSCMont.Text:=Actualmente;
      EditSCMont.SelStart := Length(Actualmente)-9;
      end
   else
      begin
      Actualmente[currpos+1] := ultimo;
      ParteEntera := copy(actualmente,1,length(Actualmente)-9);
      ParteEntera := IntToStr(StrToIntDef(ParteEntera,0));
      actualmente := parteentera+'.'+partedecimal;
      EditSCMont.Text:=Actualmente;
      EditSCMont.SelStart := currpos+1;
      if ((currpos=0) and (ultimo='0')) then EditSCMont.SelStart := 0;
      end;
   end;
End;




END. // END PROGRAM

