unit nl_disk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, nl_cripto, nl_language, dialogs, nl_functions, fileutil,
  Zipper;

Procedure VerifyFilesStructure();
Procedure CreateNewWallet();
Procedure LoadWallet();
Procedure SaveWallet();
Procedure CreateTrashWallet();
Procedure MoveAddressToTrash(Address:WalletData);
Procedure SaveOptions();
Procedure LoadOptions();
Procedure CreateSumary();
Procedure LoadSumary();
Procedure UnZipSumary();


implementation

// verify the app files structure
Procedure VerifyFilesStructure();
Begin
if not directoryexists(WalletDirectory) then CreateDir(WalletDirectory);
if not directoryexists(DataDirectory) then CreateDir(DataDirectory);
if not FileExists(WalletFileName) then CreateNewWallet() else LoadWallet();
if not FileExists(TrashFilename) then CreateTrashWallet();
if not FileExists(OptionsFilename) then SaveOptions() else LoadOptions();
if not FileExists(SumaryFilename) then CreateSumary() else LoadSumary();
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
     ToLog(format(rsError0001,[e.Message]));
     end;
   END;
   end;
End;

// Loads the wallet from disk
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
   ToLog(format(rsError0002,[e.Message]));
   end;
END{Try};
End;

// Save wallet file to disk
Procedure SaveWallet();
var
  Counter:integer;
  Previous : int64;
Begin
copyfile (WalletFileName,WalletFileName+'.bak');
assignfile(FILE_Wallet,WalletFileName);
reset(FILE_Wallet);
EnterCriticalSection(CS_ARRAY_Addresses);
TRY
For Counter := 0 to length(ARRAY_Addresses)-1 do
   begin
   seek(FILE_Wallet,Counter);
   Previous := ARRAY_Addresses[Counter].Pending;
   ARRAY_Addresses[Counter].Pending := 0;
   write(FILE_Wallet,ARRAY_Addresses[Counter]);
   ARRAY_Addresses[Counter].Pending := Previous;
   end;
Truncate(FILE_Wallet);
EXCEPT on E:Exception do
   begin
   ToLog(Format(rsError0004,[E.Message]))
   end;
END{Try};
LeaveCriticalSection(CS_ARRAY_Addresses);
SAVE_Wallet := false;
closefile(FILE_Wallet);
End;

// Creates the trash wallet file
Procedure CreateTrashWallet();
Begin
assignfile(FILE_Trash,TrashFilename);
rewrite(FILE_Trash);
closefile(FILE_Trash);
End;

// Moves an address to the trash wallet
Procedure MoveAddressToTrash(Address:WalletData);
Begin
assignfile(FILE_Trash,TrashFilename);
reset(FILE_Trash);
seek(FILE_Trash,FileSize(FILE_Trash));
write(FILE_Trash,Address);
closefile(FILE_Trash);
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
writeln(FILE_Options,'multisend '+BoolToStr(WO_MultiSend,true));
CloseFile(FILE_Options);
EXCEPT on E:Exception do
   begin

   end;
END{Try};

End;

// Load the options file
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
    if parameter(LLine,0) ='multisend' then WO_Multisend:=StrToBool(Parameter(LLine,1));
   end;
CloseFile(FILE_Options);
EXCEPT on E:Exception do
   begin

   end;
END{Try};
End;

//******************************************************************************
// SUMARY
//******************************************************************************

// Creates a empty sumary file
Procedure CreateSumary();
Begin
SetLength(ARRAY_Sumary,0);
assignfile(FILE_Sumary,SumaryFilename);
Rewrite(FILE_Sumary);
CloseFile(FILE_Sumary);
End;

// Loads a sumary to memory
Procedure LoadSumary();
var
  Counter : integer = 0;
Begin
TRY
SetLength(ARRAY_Sumary,0);
assignfile(FILE_Sumary,SumaryFilename);
Reset(FILE_Sumary);
SetLength(ARRAY_Sumary,fileSize(FILE_Sumary));
for Counter := 0 to Filesize(FILE_Sumary)-1 do
   Begin
   seek(FILE_Sumary,Counter);
   read(FILE_Sumary,ARRAY_Sumary[Counter]);
   end;
CloseFile(FILE_Sumary);
UpdateWalletFromSumary();
EXCEPT on E:Exception do
   begin
   end
END{Try};
End;

// Unzip the received sumary file
Procedure UnZipSumary();
var
  UnZipper: TUnZipper;
Begin
TRY
UnZipper := TUnZipper.Create;
   try
   UnZipper.FileName := ZipSumaryFilename;
   UnZipper.OutputPath := '';
   UnZipper.Examine;
   UnZipper.UnZipAllFiles;
   finally
   UnZipper.Free;
   tolog(HashMD5File(SumaryFilename));
   end;
//if delfile then Trydeletefile(ZipSumaryFilename);
EXCEPT on E:Exception do
   begin
   tolog ('Error unzipping block file');
   end;
END{Try};
End;

END. // END UNIT

