unit nl_mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, lclintf, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Grids, Menus, StdCtrls, nl_GUI, nl_disk, nl_data, nl_functions, IdTCPClient,
  nl_language, nl_cripto, Clipbrd, Buttons, Spin, nl_explorer, IdComponent,
  strutils, Types, nl_qrcode, DefaultTranslator, infoform, nl_consensus,
  nl_network, splashform, formlog, formnetwork, formliqpool, nosonosocfg, nosoconsensus,
  nosotime,nosodebug;

type

  { TForm1 }

  TForm1 = class(TForm)
    CBMultisend: TCheckBox;
    Edit2: TEdit;
    EditSCDest: TEdit;
    EditSCMont: TEdit;
    GVTsGrid: TStringGrid;
    ImageBlockInfo: TImage;
    ImageList: TImageList;
    ImageSync: TImage;
    ImageDownload: TImage;
    ImgSCDest: TImage;
    ImgSCMont: TImage;
    Label14: TLabel;
    Label15: TLabel;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    Labelsupply: TLabel;
    Labelstake: TLabel;
    Labelsummary: TLabel;
    LabelTime: TLabel;
    LabelDownload: TLabel;
    LabelBlockInfo: TLabel;
    LabelCLock: TLabel;
    LabelLocked: TLabel;
    LBalance1: TLabel;
    LSCTop: TLabel;
    LSCTop1: TLabel;
    MainMenu: TMainMenu;
    MemoSCCon: TMemo;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem20: TMenuItem;
    MM_File_Exit: TMenuItem;
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
    Panel23: TPanel;
    PanelTransferGVT: TPanel;
    PC_GVTs: TPageControl;
    PanelSupply: TPanel;
    PanelTrxInfo: TPanel;
    PanelDown: TPanel;
    PanelBlockInfo: TPanel;
    PanelBalance: TPanel;
    PanelSend: TPanel;
    Panelstake: TPanel;
    Panelsummary: TPanel;
    PanelSync: TPanel;
    PanelStatus: TPanel;
    PanelDownload: TPanel;
    PUMAddressess: TPopupMenu;
    SBSCMax: TSpeedButton;
    SBSCPaste: TSpeedButton;
    SCBitCancel: TBitBtn;
    SCBitClea: TBitBtn;
    SCBitConf: TBitBtn;
    SCBitSend: TBitBtn;
    SCBitSend1: TBitBtn;
    SGridAddresses: TStringGrid;
    SGridSC: TStringGrid;
    TabGVTs: TTabSheet;
    TabGVTsGVTs: TTabSheet;
    TabGVTsPolls: TTabSheet;
    TabWallet: TTabSheet;
    StartTimer : TTimer;
    procedure CBMultisendChange(Sender: TObject);
    procedure EditSCDestChange(Sender: TObject);
    procedure EditSCMontChange(Sender: TObject);
    procedure EditSCMontKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure GVTsGridResize(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem15Click(Sender: TObject);
    procedure MenuItem16Click(Sender: TObject);
    procedure MenuItem17Click(Sender: TObject);
    procedure MenuItem18Click(Sender: TObject);
    procedure MenuItem19Click(Sender: TObject);
    procedure MenuItem20Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure MM_File_ExitClick(Sender: TObject);
    procedure PanelBlockInfoClick(Sender: TObject);
    Procedure StartTimerRun(Sender: TObject);
    Procedure RunAppStart();

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
    procedure SGridAddressesKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SGridAddressesPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure SGridAddressesResize(Sender: TObject);

  private

  public

  end;

function IsValidDestination(Address:string):boolean;

var
  Form1: TForm1;

implementation

uses
  LCLType;

{$R *.lfm}

{ TForm1 }

//******************************************************************************
// FORM RELATIVE EVENTS
//******************************************************************************

// On create form events
procedure TForm1.FormCreate(Sender: TObject);
var
  counter:integer;
Begin
// Initialize exit menu shortcuts
{$IFDEF LINUX}
  MM_File_Exit.ShortCut := KeyToShortCut(VK_Q, [ssCtrl]);
{$ENDIF}
{$IFDEF WINDOWS}
  MM_File_Exit.ShortCut := KeyToShortCut(VK_X, [ssAlt]);
{$ENDIF}

// Initializae Critical sections
InitCriticalSection(CS_ARRAY_Addresses);
InitCriticalSection(CS_LOG);
InitCriticalSection(CS_ArrayNodes);
InitCriticalSection(CS_Masternodes);

//Initialize dynamic arrays
setlength(ARRAY_Addresses,0);
setlength(ARRAY_Nodes,0);
setlength(ARRAY_Sumary,0);
Setlength(ARRAY_Pending,0);
//LogLines :=TStringList.create;
form1.Caption:='Nosolite '+ProgramVersion;
End;

// On show form events
procedure TForm1.FormShow(Sender: TObject);
Begin
if G_FirstRun then
   begin
   G_FirstRun := false;
   Form4.Label1.Caption:='Nosolite '+ProgramVersion;
   Form1.StartTimer:= TTimer.Create(Form1);
   Form1.StartTimer.Enabled:=true;
   Form1.StartTimer.Interval:=1;
   Form1.StartTimer.OnTimer:= @form1.StartTimerRun;
   Form1.Visible:=false;
   end;
End;

Procedure TForm1.StartTimerRun(Sender: TObject);
Begin
StartTimer.Enabled:=false;
RunAppStart;
End;

Procedure TForm1.RunAppStart();
var
  MainnetTime : int64;
  UpdatedMNs  : String = '';
Begin
  VerifyFilesStructure;
    ToStartLog('Files verified');
  LoadGUIInterface();
  UpdateWalletFromSumary();
  RefreshAddresses();
  RefreshNodes();
  RefreshStatus();
  InitDeepDeb(DeepDebLogFilename,format('Nosolite %s',[ProgramVersion]));
  CreateNewLog('main',MainLogFilename);
  RefreshGVTs;
    ToStartLog('GVTs updated');
  SetNodesArray(GetCFGDataStr(1));
  StartAutoConsensus;
    ToStartLog('Consensus started');
  GetTimeOffset(PArameter(GetCFGDataStr,2));
  ToStartLog('TIME: '+NosoT_TimeOffset.ToString);
  //MainnetTime := GetMainnetTimestamp;
  //if MainnetTime<>0 then MainNetOffSet := UTCTime-MainnetTime;
  //ToLog(Format('Offset: %d seconds',[MainNetOffSet]));
  //ToStartLog('Mainnet time synced');

UpdatedMNs := GetMNsFromNode;
  ToStartLog('MNs file retrieved');

if StrToIntDef(Parameter(UpdatedMNs,0),-1)> MasternodesLastBlock then
   begin
   SaveMnsToFile(UpdatedMNs);
   //FillArrayNodes;
   ToStartLog('Nodes updated');
   end;
//Pendings_String := GetPendings();
//ProcessPendings();
Sleep(500);
   Form1.Visible:=true;
   form4.Visible:=false;
   THREAD_Update := TUpdateThread.Create(true);
   THREAD_Update.FreeOnTerminate:=true;
   THREAD_Update.Start;
   form1.PageControl.ActivePage := form1.TabWallet;
End;

// On close query form events
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
Begin
Closing_App := true;
Repeat
  sleep(1);
until ( (not FillingNodes) and (not GettingSum) );
THREAD_Update.Terminate;
THREAD_Update.WaitFor;
SaveOptions;
End;

// On close form events
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Begin
DoneCriticalSection(CS_ARRAY_Addresses);
DoneCriticalSection(CS_LOG);
DoneCriticalSection(CS_ArrayNodes);
DoneCriticalSection(CS_Masternodes);
StopAutoConsensus;
//LogLines.Free;
application.Terminate;
End;

// Prepare canvas for adressess grid
procedure TForm1.SGridAddressesPrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  ts: TTextStyle;
  CurrPos : integer;
Begin
Currpos := ARow-1;
if (ACol>1)  then
   begin
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (Sender as TStringGrid).Canvas.TextStyle := ts;
   end;
if ( (Acol=2) and (ARow>0) ) then
   begin
   if ARRAY_Pending[Currpos].incoming-ARRAY_Pending[Currpos].outgoing < 0 then
      (Sender as TStringGrid).Canvas.Brush.Color := clRed
   else if ARRAY_Pending[Currpos].incoming-ARRAY_Pending[Currpos].outgoing > 0 then
      (Sender as TStringGrid).Canvas.Brush.Color := clMoneyGreen;
   end;
if ( (Acol=0) and (ARow>0) ) then
   begin
   if AnsiContainsStr(Parameter(G_NosoCFGStr,5),ARRAY_Addresses[currpos].Hash) then
      begin
      (sender as TStringGrid).Canvas.Brush.Color :=  clRed;
      end;
   end;
End;

// Grid addresses on resize
procedure TForm1.SGridAddressesResize(Sender: TObject);
var
  GridWidth : integer;
Begin
GridWidth := form1.SGridAddresses.Width;
form1.SGridAddresses.ColWidths[0] := ThisPercent(40,GridWidth);
form1.SGridAddresses.ColWidths[1] := ThisPercent(18,GridWidth);
form1.SGridAddresses.ColWidths[2] := ThisPercent(18,GridWidth);
form1.SGridAddresses.ColWidths[3] := ThisPercent(24,GridWidth,true);
end;

// Grid GVTS resize
procedure TForm1.GVTsGridResize(Sender: TObject);
var
  GridWidth : integer;
Begin
GridWidth := form1.GVTsGrid.Width;
form1.GVTsGrid.ColWidths[0] := ThisPercent(20,GridWidth);
form1.GVTsGrid.ColWidths[1] := ThisPercent(79,GridWidth,true);
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
   // Lock icon
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
if ((CurrPos>=0) and (Acol = 3)) then
   begin
   // MN icon
   If AnsiContainsStr(GetMasternodes,ARRAY_Addresses[CurrPos].Hash) then
      begin
      ColWidth := (sender as TStringGrid).ColWidths[3];
      Bitmap:=TBitmap.Create;
      ImageList.GetBitmap(4,Bitmap);
      myRect := Arect;
      myrect.Left:=myRect.Left+4;
      myRect.Right := myrect.Left+20;
      myrect.Bottom:=myrect.Top+20;
      (sender as TStringGrid).Canvas.StretchDraw(myRect,bitmap);
      Bitmap.free
      end;
   if ( (ARRAY_Addresses[CurrPos].Balance div 100000000 > Int_StakeSize) and
        (not AnsiContainsStr(GetMasternodes,ARRAY_Addresses[CurrPos].Hash)) ) then
      begin
      ColWidth := (sender as TStringGrid).ColWidths[3];
      Bitmap:=TBitmap.Create;
      ImageList.GetBitmap(3,Bitmap);
      myRect := Arect;
      myrect.Left:=myRect.Left+4;
      myRect.Right := myrect.Left+20;
      myrect.Bottom:=myrect.Top+20;
      (sender as TStringGrid).Canvas.StretchDraw(myRect,bitmap);
      Bitmap.free
      end;
   end;
End;

// Grid addresses on keyup
procedure TForm1.SGridAddressesKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  Procedure TryMoveUpAddress();
  var
    tempdata    :WalletData;
    tempPending : PendingData;
    CurrRow     : integer;
  Begin
  CurrRow := SGridAddresses.Row-1;
  if CurrRow>0 then
     begin
     tempdata    := ARRAY_Addresses[currRow-1];
     tempPending := ARRAY_Pending[currRow-1];
     ARRAY_Addresses[currRow-1] := ARRAY_Addresses[currRow];
     ARRAY_Addresses[currRow] := Tempdata;

     ARRAY_Pending[currRow-1] := ARRAY_Pending[currRow];
     ARRAY_Pending[currRow]   := tempPending;

     RefreshAddresses;
     SaveWallet();
     SGridAddresses.Row :=SGridAddresses.Row-1
     end;
  end;

  Procedure TryMoveDownAddress();
  var
    tempdata:WalletData;
    tempPending : PendingData;
    CurrRow : integer;
  Begin
  CurrRow := SGridAddresses.Row-1;
  if CurrRow<length(ARRAY_Addresses)-1 then
     begin
     tempdata := ARRAY_Addresses[currRow+1];
     tempPending := ARRAY_Pending[currRow+1];
     ARRAY_Addresses[currRow+1] := ARRAY_Addresses[currRow];
     ARRAY_Addresses[currRow] := Tempdata;
     ARRAY_Pending[currRow+1] := ARRAY_Pending[currRow];
     ARRAY_Pending[currRow] := tempPending;

     RefreshAddresses;
     SaveWallet();
     SGridAddresses.Row :=SGridAddresses.Row+1
     end;
  end;

begin
if SGridAddresses.Row>0 then
   begin
   if (Key = VK_Q) then
      TryMoveUpAddress;
   if (Key = VK_A) then
      TryMoveDownAddress;
   if (Key = VK_H) then
      form4.Visible := true;
   end
end;

//******************************************************************************
// Addresses Pop Up menu
//******************************************************************************

// On context pop up; before showing the menu
procedure TForm1.SGridAddressesContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
Begin
// Show lock/unlock proprely
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
// if address is locked disable options
if ARRAY_Addresses[SGridAddresses.Row-1].PrivateKey[1]='*' then
   begin
   menuitem7.enabled:=false;
   menuitem6.enabled:=false;
   menuitem15.enabled:=false;
   end
else
   begin
   menuitem7.enabled:=true;
   menuitem6.enabled:=true;
   menuitem15.enabled:=true;
   end;
// Enable-Disable customize
if ((ARRAY_Addresses[SGridAddresses.Row-1].custom<>'') or (ARRAY_Addresses[SGridAddresses.Row-1].Balance<=Customfee) or
   (ARRAY_Addresses[SGridAddresses.Row-1].PrivateKey[1]='*') ) then
   menuitem17.Enabled:=false
else menuitem17.Enabled:=true;

End;

// Import address from keys
procedure TForm1.MenuItem3Click(Sender: TObject);
var
  UserString : string = '';
  InputResult : boolean;
Begin
InputResult := InputQuery(rsDIA0001, rsDIA0002, TRUE, UserString);
if ((InputResult) and (UserString<>'')) then
   begin
   ImportKeys(UserString);
   REF_Addresses := true;
   end;
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
   Delete(ARRAY_Pending,CurrPosition,1);
   MoveAddressToTrash(CurrWallet);
   SAVE_Wallet := true;
   REF_Addresses := true;
   end
else ToLog('main',rsError0009);
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
  pass1: string= '';
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
      ToLog('main',format(rsError0011,[ARRAY_Addresses[CurrPos].Hash]));
      end;
   END{Try};
   if SignProcess then
      begin
      ARRAY_Addresses[CurrPos].PrivateKey := decrypted;
      REF_Addresses := true;
      SAVE_Wallet := true;
      end
   else ToLog('main',format(rsError0011,[ARRAY_Addresses[CurrPos].Hash]));
   end;
end;

// Edit address label
procedure TForm1.MenuItem11Click(Sender: TObject);
var
  NewLabel : String;
Begin
newlabel := GetLabelAddress(ARRAY_Addresses[SGridAddresses.Row-1].Hash);
if InputQuery('Edit label', 'Enter label', newlabel) then
   begin
   SetLabelValue(ARRAY_Addresses[SGridAddresses.Row-1].Hash,NewLabel);
   Ref_Addresses := true;
   end;

End;

// Certificate
procedure TForm1.MenuItem15Click(Sender: TObject);
var
  currpos : integer;
  currtime, address : string;
  Certificate : string;
Begin
currtime := UTCTime.ToString;
CurrPos := SGridAddresses.Row-1;
if isAddressLocked(ARRAY_Addresses[currpos]) then
   ToLog('main',rsError0013)
else
   begin
   address := GetAddressToShow(ARRAY_Addresses[currpos].Hash);
   Certificate := ARRAY_Addresses[currpos].PublicKey+':'+currtime+':'+
      GetStringSigned('I OWN THIS ADDRESS '+address+currtime,ARRAY_Addresses[currpos].PrivateKey);
   Certificate := EncodeCertificate(Certificate);
   form3.BorderIcons:=form3.BorderIcons+[bisystemmenu];
   form3.memorequest.Text:=format(rsGUI0020,[address]);
   form3.memoresult.Text:=format('%s',[Certificate]);
   form3.ShowModal;
   end;
End;

// QR code
procedure TForm1.MenuItem16Click(Sender: TObject);
var
  currpos : integer;
  ToShow: string;
Begin
if form2.Visible then form2.Close;
CurrPos := SGridAddresses.Row-1;
ToShow := GetAddressToShow(ARRAY_Addresses[CurrPos].Hash);
QRAddress := ToShow;
if ARRAY_Addresses[CurrPos].PrivateKey[1]='*' then
  begin
  QRKeys := '';
  form2.Button2.Visible:=false;
  end
else
   begin
   QRKeys := ARRAY_Addresses[CurrPos].PublicKey+' '+ARRAY_Addresses[CurrPos].PrivateKey;
   //ToLog(ARRAY_Addresses[CurrPos].PublicKey+' '+ARRAY_Addresses[CurrPos].PrivateKey);
   form2.Button2.Visible:=true;
   end;
form2.show;
End;

// Customize address
procedure TForm1.MenuItem17Click(Sender: TObject);
var
  HashAddres : String;
  Newalias   : string = '';
  OrderStr   : String = '';
  OperResult : integer;
Begin
HashAddres := ARRAY_Addresses[SGridAddresses.Row-1].hash;
Newalias := InputBox(ARRAY_Addresses[SGridAddresses.Row-1].hash,'Enter a custom alias', '');
if Not IsValidCustomName(Newalias) then
   begin
   ShowInfoForm(Format(rsGUI0031,[HashAddres]),rsGUI0032);  // 'Invalid custom alias'
   exit;
   end;
if IsValidHashAddress(Newalias) then
   begin
   ShowInfoForm(Format(rsGUI0031,[HashAddres]),rsGUI0033);   //'Alias can not be a valid hash address'
   exit;
   end;
if ARRAY_Addresses[SGridAddresses.Row-1].Custom <>'' then
   begin
   ShowInfoForm(Format(rsGUI0031,[HashAddres]),rsGUI0037);   //'Address already have an alias'
   exit;
   end;
OrderStr := GetCustomOrder(HashAddres,Newalias, SGridAddresses.Row-1);
OperResult := StrToIntDef(SendOrder(OrderStr),-1);
if OperResult = 0 then ShowInfoForm(Format(rsGUI0031,[HashAddres]),Format(rsGUI0024,[Newalias]))
else if OperResult = -1 then ShowInfoForm(Format(rsGUI0031,[HashAddres]),rsGUI0023+': '+rsGUI0034)
else if OperResult > 0 then ShowInfoForm(Format(rsGUI0031,[HashAddres]),Format(rsGUI0030,[OperResult.ToString]));
End;

// Import addresses from file
procedure TForm1.MenuItem2Click(Sender: TObject);
begin
ShowExplorer(GetCurrentDir,rsGUI0010,'*.pkw',true);
end;

//******************************************************************************
// Main menu
//******************************************************************************

// Check certificate
procedure TForm1.MenuItem18Click(Sender: TObject);
var
  InString : string = '';
  PubKey,SignTime,Signhash, Address : string;
Begin
InString := InputBox('Check certificate','Enter certificate','');
if InString = '' then exit;
InString := DecodeCertificate(InString);
InString := StringReplace(InString,':',' ',[rfReplaceAll, rfIgnoreCase]);
pubkey := Parameter(InString,0);
SignTime := Parameter(InString,1);
Signhash := Parameter(InString,2);
Address := GetAddressFromPublicKey(pubkey);
if AddressSumaryIndex(Address) >= 0 then
   if ARRAY_Sumary[AddressSumaryIndex(Address)].custom <> '' then Address := ARRAY_Sumary[AddressSumaryIndex(Address)].custom;

if VerifySignedString('I OWN THIS ADDRESS '+Address+SignTime,Signhash,pubkey) then
   begin
   form3.BorderIcons:=form3.BorderIcons+[bisystemmenu];
   form3.memorequest.Text:=rsGUI0026;
   form3.memoresult.Text:=format(rsGUI0027,[address,TimeSinceStamp(StrToInt64(SignTime))]);
   form3.ShowModal;
   end
else
   begin
   form3.BorderIcons:=form3.BorderIcons+[bisystemmenu];
   form3.memorequest.Text:=rsGUI0026;
   form3.memoresult.Text:=rsGUI0028;
   form3.ShowModal;
   end;
End;

// Open wallet folder
procedure TForm1.MenuItem19Click(Sender: TObject);
Begin
TRY
OpenDocument(GetCurrentDir+directoryseparator+'wallet');
EXCEPT ON E:Exception do
   ToLog('main',e.Message);
END; {TRY}
End;

// Zip wallet folder (To be implemented)
procedure TForm1.MenuItem20Click(Sender: TObject);
Begin

End;

// Close app
procedure TForm1.MM_File_ExitClick(Sender: TObject);
Begin
  Close;
End;

// Show log
procedure TForm1.MenuItem12Click(Sender: TObject);
Begin
if not form5.Visible then Form5.Show;
End;

// Click on panel
procedure TForm1.PanelBlockInfoClick(Sender: TObject);
begin
if not form6.Visible then form6.Show;
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
  TextAmmount : string;
  OperResult : String = '';
  ErrorCode : integer = 0;
Begin
TextAmmount:= StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]);
ammount := StrToInt64Def(TextAmmount,-1);
form3.BorderIcons:=form3.BorderIcons+[bisystemmenu];
form3.memorequest.Text:=format(rsGUI0022,[Int2Curr(ammount),EditSCDest.Text,MemoSCCon.Text]);
form3.memoresult.Text:=rsGUI0021;
form1.Enabled:=false;
form3.Show;
application.ProcessMessages;
OperResult :=SendTo(EditSCDest.Text,ammount,MemoSCCon.Text);
if ( (OperResult <>'') and (Parameter(OperResult,0)<>'ERROR') ) then
   begin
   form3.memoresult.Text:=format(rsGUI0024,[OperResult]);
   tolog('main','Order: '+OperResult);
   end
else
   begin
   ErrorCode := StrToIntDef(Parameter(OperResult,1),0);
   if errorcode = 0 then form3.memoresult.Text:= format(rsGUI0030,['Unknown'])
   else form3.memoresult.Text:= format(rsGUI0030,[ErrorCode.ToString])
   end;
application.ProcessMessages;
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
else ToLog('main',rsError0010);
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
if EditSCMont.Text = '0.00000000' then PanelTrxInfo.Visible:=false
else PanelTrxInfo.Visible:=true;
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

