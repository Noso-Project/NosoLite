unit nl_disk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, nl_cripto, nl_language, dialogs, nl_functions;

Procedure VerifyFilesStructure();
Procedure CreateNewWallet();
Procedure LoadWallet();
Procedure SaveOptions();
Procedure LoadOptions();

implementation

// verify the app files structure
Procedure VerifyFilesStructure();
Begin
if not directoryexists(WalletDirectory) then CreateDir(WalletDirectory);
if not FileExists(WalletFileName) then CreateNewWallet() else LoadWallet();
if not FileExists(OptionsFilename) then SaveOptions() else LoadOptions();
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
END{Try};
End;

//******************************************************************************
// OPTIONS
//******************************************************************************

Procedure SaveOptions();
Begin
TRY
Assignfile(FILE_Options, OptionsFilename);
rewrite(FILE_Options);
writeln(FILE_Options,'block '+WO_LastBlock.ToString);
writeln(FILE_Options,'sumary '+WO_LastSumary);
writeln(FILE_Options,'refresh '+WO_Refreshrate.ToString);
CloseFile(FILE_Options);
EXCEPT on E:Exception do
   begin

   end;
END{Try};

End;

Procedure LoadOptions();
var
  LLine : string;
Begin
TRY
Assignfile(FILE_Options, OptionsFilename);
reset(FILE_Options);
while not eof(FILE_Options) do
   begin
   readln(FILE_Options,LLine);
    if parameter(LLine,0) ='block' then WO_LastBlock:=Parameter(LLine,1).ToInteger();
    if parameter(LLine,0) ='sumary' then WO_LastSumary:=Parameter(LLine,1);
    if parameter(LLine,0) ='refresh' then WO_Refreshrate:=Parameter(LLine,1).ToInteger();
   end;
CloseFile(FILE_Options);
EXCEPT on E:Exception do
   begin

   end;
END{Try};
End;

END. // END UNIT

