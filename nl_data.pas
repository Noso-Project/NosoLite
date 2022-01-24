unit nl_data;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdTCPClient, dateutils;

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
   host : string[60];
   port : integer;
   block : integer;
   Pending: integer;
   Branch : String[40];
   MNsHash : string[5];
   MNsCount : integer;
   Updated : boolean;
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

CONST
  WalletDirectory = 'wallet'+directoryseparator;  // Wallet folder
  DataDirectory   = 'data'+directoryseparator;
  WalletFileName = WalletDirectory+'wallet.pkw';  // Wallet keys file
  TrashFilename  = WalletDirectory+'trash.pkw';
  SumaryFilename = DataDirectory+'sumary.psk';
  ZipSumaryFilename = DataDirectory+'sumary.zip';
  OptionsFilename = DataDirectory+'options.nsl';                // Options file
  Comisiontrfr = 10000;
  MinimunFee = 10;
  Protocol = 1;
  ProgramVersion = '1.0';

  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';
  Customfee   = 25000;

var
  FILE_Wallet : File of WalletData; // Wallet file pointer
  FILE_Trash  : File of WalletData;
  FILE_Options : textfile;
  FILE_Sumary : File of SumaryData;

  ARRAY_Addresses : array of WalletData;
  ARRAY_Nodes : array of NodeData;
  ARRAY_Sumary : array of SumaryData;
  ARRAY_Pending : array of PendingData;

  THREAD_Update : TUpdateThread;

  STR_SeedNodes : String = 'DefNodes '+
                                 '23.94.21.83:8080 '+
                                 '45.146.252.103:8080 '+
                                 '107.172.5.8:8080 '+
                                 '109.230.238.240:8080 '+
                                 '172.245.52.208:8080 '+
                                 '192.210.226.118:8080 '+
                                 '194.156.88.117:8080';
  Int_LastThreadExecution : int64 = 0;
  Int_WalletBalance       : int64 = 0;
  Int_LockedBalance       : int64 = 0;
  Int_SumarySize          : int64 = 0;
  Int_LastPendingCount    : int64 = 0;
    Pendings_String       : string = '';

  WO_LastBlock : integer = 0;
  WO_LastSumary : string = '';
  WO_Refreshrate : integer = 15;
  WO_Multisend : boolean = false;

  // Global variables
  SAVE_Wallet : Boolean = false;
  Closing_App : boolean = false;
  Wallet_Synced : Boolean = false;
  REF_Addresses : Boolean = false;
  REF_Nodes : Boolean = false;
  REF_Status : Boolean = false;
  LogLines : TStringList;
  G_UTCTime : int64;
  G_FirstRun : boolean = true;

  // Critical Sections
  CS_ARRAY_Addresses: TRTLCriticalSection;
  CS_LOG            : TRTLCriticalSection;


implementation

Uses
  nl_mainform, nl_network, nl_functions, nl_GUI, nl_language, nl_disk;

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
   ActualTime := DateTimeToUnix(now);
   if ((ActualTime >= Int_LastThreadExecution+WO_Refreshrate) and (WO_Refreshrate>0)) then
      begin
      Synchronize(@showsync);
      sleep(1);
      For counter := 0 to length(ARRAY_Nodes)-1 do
         begin
         LLine := '';
         if not terminated then LLine := GetNodeStatus(ARRAY_Nodes[counter].host,ARRAY_Nodes[counter].port.ToString);
         if LLine <> '' then
            begin
            ARRAY_Nodes[counter].block:=Parameter(LLine,2).ToInteger();
            ARRAY_Nodes[counter].Pending:=Parameter(LLine,3).ToInteger();
            ARRAY_Nodes[counter].Branch:=Parameter(LLine,5);
            ARRAY_Nodes[counter].MNsHash:=Parameter(LLine,8);
            ARRAY_Nodes[counter].MNsCount:= StrToIntDef(Parameter(LLine,9),0);
            ARRAY_Nodes[counter].Updated:=true;
            end
         else
            begin
            ARRAY_Nodes[counter].block:=0;
            ARRAY_Nodes[counter].Pending:=0;
            ARRAY_Nodes[counter].Branch:=rsError0003;
            ARRAY_Nodes[counter].MNsHash:='';
            ARRAY_Nodes[counter].MNsCount:=0;
            ARRAY_Nodes[counter].Updated:=false;
            end;
         end;
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
      Int_LastThreadExecution := DateTimeToUnix(now);
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

