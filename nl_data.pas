unit nl_data;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdTCPClient;

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
      procedure UpdateGUI;
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
   end;

ConsensusData = packed record
   Value : string[40];
   count : integer;
   end;

CONST
  WalletDirectory = 'wallet'+directoryseparator;  // Wallet folder
  WalletFileName = WalletDirectory+'wallet.psk';  // Wallet keys file
  OptionsFilename = 'options.nsl';                // Options file

  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';

var
  FILE_Wallet : File of WalletData;       // Wallet file pointer
  FILE_Options : textfile;

  ARRAY_Addresses : array of WalletData;
  ARRAY_Nodes : array of NodeData;

  THREAD_Update : TUpdateThread;
  ClientChannel : TIdTCPClient;

  STR_SeedNodes : String = 'DefNodes '+
                                 '45.146.252.103:8080 '+
                                 '194.156.88.117:8080 '+
                                 '192.210.226.118:8080 '+
                                 '107.172.5.8:8080 '+
                                 '185.239.239.184:8080 '+
                                 '109.230.238.240:8080';
  WO_LastBlock : integer = 0;
  WO_LastSumary : string = '';
  WO_Refreshrate : integer = 15;


implementation

Uses
  nl_mainform, nl_network, nl_functions, nl_GUI, nl_language;

constructor TUpdateThread.Create(CreateSuspended : boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TUpdateThread.UpdateGUI();
Begin
//Form1.LabelCLock.Caption:=DateTimeToStr(now);
form1.LabelBlock.Caption:='Block: '+WO_LastBlock.ToString;
RefreshNodes();
End;

procedure TUpdateThread.Execute;
var
  counter : integer;
  LLine : String = '';
Begin
While not terminated do
   begin
   For counter := 0 to length(ARRAY_Nodes)-1 do
      begin
      LLine := GetNodeStatus(ARRAY_Nodes[counter].host,ARRAY_Nodes[counter].port.ToString);
      if LLine <> '' then
         begin
         ARRAY_Nodes[counter].block:=Parameter(LLine,2).ToInteger();
         ARRAY_Nodes[counter].Pending:=Parameter(LLine,3).ToInteger();
         ARRAY_Nodes[counter].Branch:=Parameter(LLine,5);
         end
      else
         begin
         ARRAY_Nodes[counter].block:=0;
         ARRAY_Nodes[counter].Pending:=0;
         ARRAY_Nodes[counter].Branch:=rsError0003;
         end;
      end;
   Consensus;
   Synchronize(@UpdateGUI);
   Sleep(WO_Refreshrate*1000);
   end;
End;

END. // END UNIT

