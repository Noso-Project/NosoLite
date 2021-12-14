unit nl_data;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

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

CONST
  WalletDirectory = 'wallet'+directoryseparator;  // Wallet folder
  WalletFileName = WalletDirectory+'wallet.psk';  // Wallet keys file

  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';

var
  FILE_Wallet : File of WalletData;       // Wallet file pointer

  ARRAY_Addresses : array of WalletData;

  THREAD_Update : TUpdateThread;


implementation

constructor TUpdateThread.Create(CreateSuspended : boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TUpdateThread.UpdateGUI();
Begin
// GUI update here
End;

procedure TUpdateThread.Execute;
Begin
// all the process to update
Synchronize(@UpdateGUI);
// wait OptionsRefreshRate
End;

END. // END UNIT

