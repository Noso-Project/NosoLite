unit nl_disk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, nl_cripto, nl_language, dialogs, nl_functions, fileutil,
  Zipper, splashform,nosonosocfg,nosodebug;

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
Procedure CreateMNsFile();
Procedure LoadMNsFromFile();
Procedure FillArrayNodes();
Procedure SaveMnsToFile(LineText:String);
Procedure SaveCFGToFile(LineText:String);
Function GetVerificators(LineText:String):String;
// GVTs
Procedure CreateGVTsFile();
Procedure LoadGVTsFile();
// Labels
Procedure CreateLabelsFile();
Procedure LoadLabelsFile();
Procedure SaveLabelsToDisk();
// Start log
Procedure CreateStartLog();
Procedure ToStartLog(TextLine:String);

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
if not FileExists(MNsFilename) then CreateMNsFile() else LoadMNsFromFile();
if not FileExists(GVTFilename) then CreateGVTsFile() else LoadGVTsFile();
if not FileExists(LabelsFilename) then CreateLabelsFile() else LoadLabelsFile();
CreateStartLog();
SetCFGFilename(DataDirectory+CFGFilename);
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
     ToLog('main',format(rsError0001,[e.Message]));
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
   ToLog('main',format(rsError0002,[e.Message]));
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
   ToLog('main',Format(rsError0004,[E.Message]))
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
writeln(FILE_Options,'multisend '+BoolToStr(WO_MultiSend,true));
writeln(FILE_Options,'liqpoolhost '+LiqPoolHost);
writeln(FILE_Options,'liqpoolport '+LiqPoolPort.ToString);

CloseFile(FILE_Options);
EXCEPT on E:Exception do
   begin

   end;
END{Try};

End;

// Load the options file
Procedure LoadOptions();
var
  LLine   : string;
  Thisapp : appData;
Begin
TRY
Assignfile(FILE_Options, OptionsFilename);
reset(FILE_Options);
while not eof(FILE_Options) do
   begin
   readln(FILE_Options,LLine);
    if parameter(LLine,0) ='block' then WO_LastBlock:=Parameter(LLine,1).ToInteger();
    if parameter(LLine,0) ='sumary' then WO_LastSumary:=Parameter(LLine,1);
    if parameter(LLine,0) ='multisend' then WO_Multisend:=StrToBool(Parameter(LLine,1));
    if parameter(LLine,0) ='liqpoolhost' then LiqPoolHost:=Parameter(LLine,1);
    if parameter(LLine,0) ='liqpoolport' then LiqPoolPort:=StrToIntDef(Parameter(LLine,1),0);
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
   TRY
   UnZipper.FileName := ZipSumaryFilename;
   UnZipper.OutputPath := '';
   UnZipper.Examine;
   UnZipper.UnZipAllFiles;
   FINALLY
   UnZipper.Free;
   END;
EXCEPT on E:Exception do
   begin
   tolog ('main','Error unzipping block file');
   end;
END{Try};
End;

//******************************************************************************
// MASTERNODES
//******************************************************************************

// Creates a new default empty masternodes file
Procedure CreateMNsFile();
Begin
assignfile(FILE_MNs,MNsFilename);
Rewrite(FILE_MNs);
write(FILE_MNs,STR_SeedNodes);
CloseFile(FILE_MNs);
LoadMNsFromFile;
End;

Procedure LoadMNsFromFile();
var
  LineText : String;
Begin
assignfile(FILE_MNs,MNsFilename);
Reset(FILE_MNs);
ReadLn(FILE_MNs,LineText);
CloseFile(FILE_MNs);
SetMasternodes(LineText);
FillArrayNodes;
End;

Procedure FillArrayNodes();
Begin
if WO_UseSeedNodes then LoadSeedNodes(Parameter(NosoCFGString,1))
else LoadSeedNodes(GetVerificators(GetMasterNodes));
End;

Procedure SaveMnsToFile(LineText:String);
Begin
assignfile(FILE_MNs,MNsFilename);
Rewrite(FILE_MNs);
SetMasternodes(LineText);
write(FILE_MNs,LineText);
CloseFile(FILE_MNs);
End;

Procedure SaveCFGToFile(LineText:String);
Begin
assignfile(FILE_CFG,CFGFilename);
Rewrite(FILE_CFG);
write(FILE_CFG,LineText);
CloseFile(FILE_CFG);
End;

Function GetVerificators(LineText:String):String;
var
  counter   : integer = 1;
  count2    : integer;
  ThisParam : string;
  ThisMN    : TMnData;
  Ip        : string;
  Port      : integer;
  Address   : string;
  Count     : integer;
  ArrNodes  : array of TMnData;
  Added     : boolean;
  VersCount : integer;
Begin
Result := MasternodesLastBlock.ToString+' ';
SetLEngth(ArrNodes,0);
repeat
  thisParam := Parameter(LineText,counter);
  if ThisParam <>'' then
     begin
     Added := false;
     ThisParam := StringReplace(ThisParam,':',' ',[rfReplaceAll, rfIgnoreCase]);
     ThisParam := StringReplace(ThisParam,';',' ',[rfReplaceAll, rfIgnoreCase]);
     ThisMN.Ip := Parameter(ThisParam,0);
     ThisMN.Port := StrToIntDef(Parameter(ThisParam,1),8080);
     ThisMN.Address := Parameter(ThisParam,2);
     ThisMN.Count   := StrToIntDef(Parameter(ThisParam,3),1);
     if Length(ArrNodes) = 0 then Insert(ThisMN,ArrNodes,0)
     else
        begin
        for count2 := 0 to length(ArrNodes)-1 do
           begin
           if ThisMN.count > ArrNodes[count2].count then
              begin
              Insert(ThisMN,ArrNodes,count2);
              Added := true;
              Break;
              end;
           end;
        if not Added then Insert(ThisMN,ArrNodes,length(ArrNodes));
        end;
     end;
  Inc(Counter);
until thisParam = '';
VersCount := (length(ArrNodes) div 10)+3;
Delete(ArrNodes,VersCount,Length(ArrNodes));
for counter := 0 to length(ArrNodes)-1 do
   begin
   Result := Result+ ArrNodes[counter].ip+';'+IntToStr(ArrNodes[counter].port)+':'+ArrNodes[counter].address+':'+
             IntToStr(ArrNodes[counter].count)+' ';
   end;
Result := Trim(Result);
End;

//******************************************************************************
// GVTs
//******************************************************************************

// Creates a new GVTs File
Procedure CreateGVTsFile();
Begin
assignfile(FILE_GVTs,GVTFilename);
Rewrite(FILE_GVTs);
CloseFile(FILE_GVTs);
LoadGVTsFile();
End;

// Load GVTS from file
Procedure LoadGVTsFile();
var
  LineText : String;
  Counter  : integer;
  ThisGVT  : TGVT;
Begin
assignfile(FILE_GVTs,GVTFilename);
Reset(FILE_GVTs);
SetLength(ARRAY_GVTs,Filesize(FILE_GVTs));
For Counter := 0 to Filesize(FILE_GVTs)-1 do
   begin
   seek(FILE_GVTs,counter);
   Read(FILE_GVTs,ThisGVT);
   ARRAY_GVTs[counter] := ThisGVT;
   end;
CloseFile(FILE_GVTs);
End;

//******************************************************************************
// LABELS
//******************************************************************************

Procedure CreateLabelsFile();
Begin
assignfile(FILE_Labels,LabelsFilename);
Rewrite(FILE_Labels);
CloseFile(FILE_Labels);
LoadGVTsFile();
End;

Procedure LoadLabelsFile();
var
  ThisLine : string;
  ThisData : TypeLabel;
Begin
assignfile(FILE_Labels,LabelsFilename);
Reset(FILE_Labels);
SetLength(ARRAY_Labels,0);
While not eof(FILE_Labels) do
   begin
   ReadLn(FILE_Labels,ThisLine);
   ThisData.Address:=Parameter(ThisLine,0);
   ThisData.LabelSt:=Parameter(ThisLine,1);
   Insert(ThisData,ARRAY_Labels,LEngth(ARRAY_Labels));
   end;
CloseFile(FILE_Labels);
End;

Procedure SaveLabelsToDisk();
var
  Counter : integer;
Begin
assignfile(FILE_Labels,LabelsFilename);
Rewrite(FILE_Labels);
For counter := 0 to length(ARRAY_Labels)-1 do
   writeln(FILE_Labels,ARRAY_Labels[counter].Address+' '+ARRAY_Labels[counter].LabelSt);
CloseFile(FILE_Labels);
End;

//******************************************************************************
// START LOG
//******************************************************************************

Procedure CreateStartLog();
Begin
assignfile(FILE_StartLog,StartLogFilename);
Rewrite(FILE_StartLog);
CloseFile(FILE_StartLog);
End;

Procedure ToStartLog(TextLine:String);
Begin
  assignfile(FILE_StartLog,StartLogFilename);
  Append(FILE_StartLog);
  WriteLn(FILE_StartLog,TextLine);
  CloseFile(FILE_StartLog);
  form4.LabelSplash.Caption:=form4.LabelSplash.Caption+TextLine+slinebreak;
  form4.LabelSplash.Update;
End;

END. // END UNIT

