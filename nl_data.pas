unit nl_data;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdTCPClient, dateutils, strutils;

Type

WalletData = Packed Record
   Hash : String[40];              // Public hash
   Custom : String[40];            // Custom alias
   PublicKey : String[255];        // Public key
   PrivateKey : String[255];       // Private key
   Balance : int64;                // Last known balance
   Pending : int64;                // Last pending balance
   Score : int64;                  // Aditional field
   LastOP : int64;                 // last operation block
   end;

DivResult = packed record
   cociente : string[255];
   residuo : string[255];
   end;


TUpdateThread = class(TThread)
    private
      procedure UpdateNodes;
      procedure UpdateAddresses;
      procedure UpdateLog;
      procedure UpdateStatus;
      procedure showsync;
      procedure hidesync;
      procedure showdownload;
      procedure hidedownload;
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

NodeData = packed record
   host      : string[60];
   Peers     : integer;
   Version   : string[10];
   port      : integer;
   block     : integer;
   Pending   : integer;
   Branch    : String[40];
   MNsHash   : string[32];
   MNsCount  : integer;
   Updated   : integer;
   LBHash    : String[32];
   NMSDiff   : String[32];
   LBTimeEnd : Int64;
   Checks    : integer;
   Synced    : boolean;
   SumHash   : string[5];
   LBMiner   : String[32];
   LBPoW     : int64;
   LBSolDiff : string[32];
   GVTHash   : String[5];
   end;

ConsensusData = packed record
   Value : string[40];
   count : integer;
   end;

OrderData = Packed Record
   Block : integer;
   OrderID : String[64];
   OrderLines : Integer;
   OrderType : String[6];
   TimeStamp : Int64;
   Reference : String[64];
     TrxLine : integer;
     Sender : String[120];    // La clave publica de quien envia
     Address : String[40];
     Receiver : String[40];
     AmmountFee : Int64;
     AmmountTrf : Int64;
     Signature : String[120];
     TrfrID : String[64];
   end;

SumaryData = Packed Record
   Hash : String[40]; // El hash publico o direccion
   Custom : String[40]; // En caso de que la direccion este personalizada
   Balance : int64; // el ultimo saldo conocido de la direccion
   Score : int64; // estado del registro de la direccion.
   LastOP : int64;// tiempo de la ultima operacion en UnixTime.
   end;

PendingData = Packed Record
   incoming : int64;
   outgoing : int64;
   end;

AppData     = packed record
   name     : string[20];
   code     : string[100];
   RegAddr  : string[40];
   end;

TMNData     = packed record
   ip      : string[15];
   port    : integer;
   Address : string[32];
   Count   : integer;
   end;

TGVT = packed record
     number   : string[2];
     owner    : string[32];
     Hash     : string[64];
     control  : integer;
     end;

CONST
  WalletDirectory   = 'wallet'+directoryseparator;  // Wallet folder
  DataDirectory     = 'data'+directoryseparator;
  WalletFileName    = WalletDirectory+'wallet.pkw';  // Wallet keys file
  TrashFilename     = WalletDirectory+'trash.pkw';
  SumaryFilename    = DataDirectory+'sumary.psk';
  ZipSumaryFilename = DataDirectory+'sumary.zip';
  OptionsFilename   = DataDirectory+'options.nsl';                // Options file
  MNsFilename       = DataDirectory+'masternodes.txt';
  GVTFilename       = DataDirectory+'gvts.psk';
  Customizationfee =25000;
  Comisiontrfr = 10000;
  MinimunFee = 10;
  Protocol = 2;
  ProgramVersion = '1.24';

  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';
  CustomValid : String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890@*+-_:';
  Customfee   = 25000;

var
  FILE_Wallet  : File of WalletData; // Wallet file pointer
  FILE_Trash   : File of WalletData;
  FILE_Options : textfile;
  FILE_Sumary  : File of SumaryData;
  FILE_MNs     : TextFile;
  FILE_GVTs    : File of TGVT;

  ARRAY_Addresses : array of WalletData;
  ARRAY_Nodes     : array of NodeData;
  ARRAY_Sumary    : array of SumaryData;
  ARRAY_Pending   : array of PendingData;
  ARRAY_GVTs      : array of TGVT;

  THREAD_Update : TUpdateThread;

  STR_SeedNodes : String = '0 109.230.238.240;8080:X:X '+
                             '198.144.190.194;8080:X:X '+
                             '149.57.226.244;8080:X:X '+
                             '107.172.193.176;8080:X:X '+
                             '66.151.117.247;8080:X:X '+
                             '192.3.73.184;8080:X:X '+
                             '107.175.24.151;8080:X:X '+
                             '149.57.137.108;8080:X:X '+
                             '159.196.1.198:8080:X:X '+
                             '101.100.138.125:8080:X:X';

  Int_LastThreadExecution : int64 = 0;
  Int_WalletBalance       : int64 = 0;
  Int_LockedBalance       : int64 = 0;
  Int_SumarySize          : int64 = 0;
  Int_LastPendingCount    : int64 = 0;
    Pendings_String       : string = '';
  Int_TotalSupply         : integer = 0;
  Int_StakeSize           : integer = 0;

  WO_LastBlock    : integer = 0;
  WO_LastSumary   : string = '';
  WO_Refreshrate  : integer = 60;
  WO_Multisend    : boolean = false;
  WO_UseSeedNodes : Boolean = false;

  // Global variables
  SAVE_Wallet    : Boolean = false;
  Closing_App    : boolean = false;
  Wallet_Synced  : Boolean = false;
  REF_Addresses  : Boolean = false;
  REF_Nodes      : Boolean = false;
  REF_Status     : Boolean = false;
  LogLines       : TStringList;
  G_UTCTime      : int64;
  G_FirstRun     : boolean = true;
  MainNetOffSet  : int64 = 0;

  // Critical Sections
  CS_ARRAY_Addresses: TRTLCriticalSection;
  CS_LOG            : TRTLCriticalSection;
  CS_ArrayNodes     : TRTLCriticalSection;

  // Apps Related
  ArrApps           : array of AppData;


implementation

Uses
  nl_mainform, nl_network, nl_functions, nl_GUI, nl_language, nl_disk, nl_consensus;

constructor TUpdateThread.Create(CreateSuspended : boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TUpdateThread.UpdateNodes();
Begin
RefreshNodes();
REF_Nodes := false
End;

procedure TUpdateThread.UpdateAddresses();
Begin
RefreshAddresses;
REF_Addresses := false;
End;

procedure TUpdateThread.UpdateLog();
Begin
EnterCriticalSection(CS_LOG);
While LogLines.Count>0 do
   begin
   Form1.MemoLog.lines.Add(LogLines[0]);
   LogLines.Delete(0);
   end;
LeaveCriticalSection(CS_LOG);
End;

procedure TUpdateThread.UpdateStatus();
Begin
RefreshStatus();
REF_Status := false;
End;

procedure TUpdateThread.showsync();
Begin
Form1.Panelsync.Visible:=true;
End;

procedure TUpdateThread.hidesync();
Begin
Form1.Panelsync.Visible:=false;
End;

procedure TUpdateThread.showdownload();
Begin
Form1.PanelDownload.Visible:=true;
End;

procedure TUpdateThread.hidedownload();
Begin
Form1.PanelDownload.Visible:=false;
End;

procedure TUpdateThread.Execute;
var
  counter : integer;
  LLine : String = '';
  ActualTime : int64;
Begin
While not terminated do
   begin
   if ((UTCTime >= Int_LastThreadExecution+WO_Refreshrate) and (WO_Refreshrate>0) and
        (BlockAge>=10) and (BlockAge<595) ) then
      begin
      Synchronize(@showsync);
      //sleep(1);
      SyncDuration := Fillnodes;
      // ToLog(format('Sync time: %d ms',[SyncDuration]));
      Synchronize(@hidesync);
      if Consensus then
         begin
         Synchronize(@showdownload);
         if GetSumary then
            begin
            LoadSumary;
            REF_Addresses := true;
            if ARRAY_Sumary[0].LastOP = WO_LastBlock then
               Wallet_Synced := true
            else Wallet_Synced := false;
            REF_Status := true;
            end;
         Synchronize(@hidedownload);
         end;
      REF_Nodes := true;
      Int_LastThreadExecution := UTCTime;
      end;
   if SAVE_Wallet then SaveWallet;
   if REF_Addresses then Synchronize(@UpdateAddresses);
   if LogLines.Count>0 then Synchronize(@UpdateLog);
   if REF_Nodes then Synchronize(@UpdateNodes);
   if REF_Status then Synchronize(@UpdateStatus);
   if UTCTime <> G_UTCTime then
      begin
      G_UTCTime := UTCTime;
      Synchronize(@UpdateStatus);
      end;
   Sleep(10);
   end;
End;

END. // END UNIT

