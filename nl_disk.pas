unit nl_disk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, nl_cripto, nl_language, dialogs;

Procedure VerifyFilesStructure();
Procedure CreateNewWallet();
Procedure LoadWallet();

implementation

// verify the app files structure
Procedure VerifyFilesStructure();
Begin
if not directoryexists(WalletDirectory) then CreateDir(WalletDirectory);
if not FileExists(WalletFileName) then CreateNewWallet() else LoadWallet();
End;

//******************************************************************************
// WALLET
//******************************************************************************

// Creates a new wallet
Procedure CreateNewWallet();
Begin
if not fileexists(WalletFileName) then
   begin
   setlength(ARRAY_Addresses,1);
   TRY
   assignfile(FILE_Wallet,WalletFileName);
   rewrite(FILE_Wallet);
   ARRAY_Addresses[0] := CreateNewAddress();
   seek(FILE_Wallet,0);
   write(FILE_Wallet,ARRAY_Addresses[0]);
   closefile(FILE_Wallet);
   EXCEPT on E:Exception do
     begin
     ShowMessage(format(rsError0001,[e.Message]));
     end;
   END;
   end;
End;

Procedure LoadWallet();
var
  counter : integer = 0;
Begin
TRY
assignfile(FILE_Wallet,WalletFileName);
reset(FILE_Wallet);
setlength(ARRAY_Addresses,filesize(FILE_Wallet));
for counter := 0 to length(ARRAY_Addresses)-1 do
   begin
   seek(FILE_Wallet,counter);
   Read(FILE_Wallet,ARRAY_Addresses[counter]);
   ARRAY_Addresses[counter].Pending:=0;
   end;
closefile(FILE_Wallet);
EXCEPT on E:Exception do
  begin
  ShowMessage(format(rsError0002,[e.Message]));
  end;
END;
End;


END. // END UNIT

