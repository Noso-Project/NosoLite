unit nl_apps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,fphttpclient, nl_functions, strutils, nl_Language, nl_data;

Type
  TPoolThread = class(TThread)
  protected
    procedure Execute; override;
  public
    Constructor Create(const CreateSuspended : boolean);
  end;

  TActiveUser = packed record
     Address  : string;
     WithLTC  : string;
     DepoLTC  : String;
     end;

Procedure RunPoolStatusRequest;
Procedure SetPoolUser(Address, deposit, withdraw: string);
Procedure StartPoolThread();
Function PostMessageToHost(host:string;port:integer;message:string):string;
Procedure RefreshPoolDataGrid(useraddress,ltcTier:string;usernoso,usernusdo,usershares,poolnoso,poolnusdo,
          poolshares,PoolVolume:int64);
Procedure ShowAppPanel(LabMessage:String;InText:String;showEdit:integer;ShowButtons:boolean);
Procedure HideAppPanel();
Function GetPoolRanSeed():String;
Procedure ProcessStatusResponse(LineText:String);

CONST
  peOFF    = 0;
  peNormal = 1;
  peROnly  = 2;
  peCoin   = 3;

var
  PoolThread     : TPoolThread;
  LastPoolUpdate : Int64 = 0;
  PoolUser       : TActiveUser;
  PoolAddress    : String = 'N3yzCQtd6MEDwkPK6SpXpMpxPACgbF3';
  MessagePro     : string = '';
  PoolEditStyle  : integer;

implementation

Uses
  nl_mainform;

// THREAD

constructor TPoolThread.Create(const CreateSuspended: Boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TPoolThread.Execute;
Begin
While not terminated do
   begin
   sleep(100);
   if LastPoolUpdate+10<UTCTime then
      begin
      RunPoolStatusRequest();
      end;
   end;
End;

Procedure RunPoolStatusRequest;
var
  ReqResponse : string;
Begin
ReqResponse := PostMessageToHost(LiqPoolHost,LiqPoolPort,'STATUS '+PoolUser.Address);
if parameter(ReqResponse,0)= 'STATUS' then
   begin
   if MessagePro = '' then HideAppPanel();
   ProcessStatusResponse(ReqResponse);
   LastPoolUpdate := UTCTime;
   end
else if parameter(ReqResponse,0)= 'ERROR' then
   begin
   ShowAppPanel('Reconnecting...','',0,false);
   MessagePro := '';
   LastPoolUpdate := UTCTime-5;
   end;

End;

Procedure SetPoolUser(Address, deposit, withdraw: string);
Begin
PoolUser.Address:=Address;
PoolUser.DepoLTC:=deposit;
PoolUser.WithLTC:=withdraw;
End;

Procedure StartPoolThread();
Begin
PoolThread := TPoolThread.Create(true);
PoolThread.FreeOnTerminate:=true;
PoolThread.Start;
End;

Function PostMessageToHost(host:string;port:integer;message:string):string;
var
  HTTPClient: TFPHTTPClient;
  Resultado : String = '';
  RequestBodyStream: TStringStream;
  { No need for the params string list }
begin
Result := '';
HTTPClient := TFPHTTPClient.Create(nil);
RequestBodyStream:= TStringStream.Create(message, TEncoding.UTF8);
HTTPClient.IOTimeout:=3000; // <-- THIS is too restrictive, ONLY needed if you get stuck for more than 1 minute
   TRY
   HTTPClient.AllowRedirect := True; // <-- I always forget this LOL!!
   HTTPClient.RequestBody:= RequestBodyStream;
   Resultado := HTTPClient.Post('http://'+host+':'+Port.ToString);
   Except on E:Exception do
      Resultado := 'ERROR : '+E.Message;
   end;
Result := Resultado;
RequestBodyStream.Free;
HTTPClient.Free;
End;

Procedure RefreshPoolDataGrid(useraddress, ltcTier:string;usernoso,usernusdo,usershares,poolnoso,
          poolnusdo,poolshares,PoolVolume:int64);
var
  Supply : extended;
Begin
form1.LabelPoolUser.caption := useraddress;
form1.LAbelPoolTier.Caption:=Format(rsGUI0049,[ltcTier]);

form1.GridPoolData.Cells[1,1] := Int2Curr2Dec(usernoso);
form1.GridPoolData.Cells[1,2] := Int2Curr2Dec(usernusdo);
form1.GridPoolData.Cells[1,3] := usershares.ToString;
form1.GridPoolData.Cells[3,1] := Int2Curr2Dec(poolnoso);
form1.GridPoolData.Cells[3,2] := Int2Curr2Dec(poolnusdo);
form1.GridPoolData.Cells[3,3] := EnoughDecimals(poolnusdo / poolnoso);
form1.GridPoolData.Cells[3,4] := poolshares.ToString;

form1.LabelPoolVolume.Caption:=FOrmat(rsGUI0044,[Int2Curr(PoolVolume)]);
supply := ((GetSumaryLastBlock *50)+10303);
Form1.LabelPooMarketCap.Caption:=FOrmat(rsGUI0048,[FormatFloat('0,000.00',supply*(poolnusdo / poolnoso))]);
form1.LabelPoolMainPrice.Caption:=EnoughDecimals(poolnusdo / poolnoso);
End;

Procedure ShowAppPanel(LabMessage:String;InText:String;showEdit:integer;ShowButtons:boolean);
Begin
PoolEditStyle := showEdit;
Form1.PanelPoolTop.Enabled:=false;
Form1.PanelPoolMain.Enabled:=false;
Form1.PanelPoolMain.Enabled:=false;
Form1.LabelPoolMessages.Caption:=LabMessage;
Form1.PanelPoolMessages.Visible:=true;
Form1.PanelPoolMessages.BringToFront;
if InText <>'' then
   begin
   Form1.TextPoolMessages.Caption:=InText;
   Form1.TextPoolMessages.visible:=true;
   end
else
   begin
   Form1.TextPoolMessages.Caption:='';
   Form1.TextPoolMessages.Caption:='';
   end;
if showEdit = 0 then     // Disable
   begin
   Form1.EditPoolMessages.Text    :='';
   Form1.EditPoolMessages.visible := false;
   Form1.ButtonPoolCancelMessage.Visible:=false;
   end
else if showedit = 1 then // Normal
   begin
   Form1.EditPoolMessages.Text    :='';
   Form1.EditPoolMessages.visible := true;
   Form1.ButtonPoolCancelMessage.Visible:=true;
   end
else if showedit = 2 then // Readonly
   begin
   Form1.EditPoolMessages.Text    :='';
   Form1.EditPoolMessages.visible := true;
   Form1.EditPoolMessages.ReadOnly:=true;
   Form1.ButtonPoolCancelMessage.Visible:=true;
   end
else if showedit = 3 then // Ammounts
   begin
   Form1.EditPoolMessages.ReadOnly:=true;
   Form1.EditPoolMessages.Alignment:=taRightJustify;
   Form1.EditPoolMessages.Text    :='0.00000000';
   Form1.EditPoolMessages.visible := true;
   Form1.ButtonPoolCancelMessage.Visible:=true;
   end;
if ShowButtons then Form1.PanelButtonsPoolMessage.Visible:=true
else Form1.PanelButtonsPoolMessage.Visible:=false;
End;

Procedure HideAppPanel();
Begin
Form1.PanelPoolTop.Enabled:=true;
Form1.PanelPoolMain.Enabled:=true;
Form1.PanelPoolMain.Enabled:=true;
Form1.PanelPoolMessages.Visible:=false;
Form1.PanelPoolMessages.SendToBack;
if MessagePro = 'DEPNOSOOK' then
   begin
   Form1.PageCOntrol.ActivePage:= Form1.TabWallet;
   Form1.TabWallet.TabVisible:=true;
   Form1.EditSCDest.Text := PoolAddress;
   Form1.MemoSCCon.Text:=PoolUser.Address;
   MessagePro := '';
   end;
if MessagePro = 'WITHLTCNOADOK' then
   begin
   if ValidateLitecoin(Trim(Form1.EditPoolMessages.Text)) then
      begin
      ShowAppPanel('Withdraw LTC','Address valid!',0,true);
      MessagePro := 'INFO';
      end
   else
      begin
      ShowAppPanel('Withdraw LTC','Invalid address',0,true);
      MessagePro := 'INFO';
      end;
   end;
End;

Function GetPoolRanSeed():String;
var
  TNumber : integer;
Begin
Result := '';
Randomize;
Repeat
  TNumber := Random(26)+65;
  Result := Result + Chr(TNumber);
Until length(result)>=8;
End;

Procedure ProcessStatusResponse(LineText:String);
var
  NosoBalance, nUSDoBalance : int64;
  Shares     : integer;
  Address    : string;
  LTCTicker  : String;
  PoolNoso,PoolnUSDo  : int64;
  PoolShares : integer;
  PoolVolume : int64;
Begin
if Parameter(LineText,0) = 'STATUS' then
   begin
   Address      := Parameter(LineText,1);
   NosoBalance  := StrToInt64Def(Parameter(LineText,2),0);
   nUSDoBalance := StrToInt64Def(Parameter(LineText,3),0);
   Shares       := StrToIntDef(Parameter(LineText,4),0);
   LTCTicker    := Parameter(LineText,7);
   PoolNoso     := StrToInt64Def(Parameter(LineText,8),0);
   PoolnUSDo    := StrToInt64Def(Parameter(LineText,9),0);
   PoolShares   := StrToIntDef(Parameter(LineText,10),0);
   PoolVolume   := StrToInt64Def(Parameter(LineText,11),0);
   RefreshPoolDataGrid(Address,LTCTicker,NosoBalance,nUSDoBalance,Shares,PoolNoso,PoolnUSDo,PoolShares,PoolVolume);
   end;
End;

Finalization
if assigned(PoolThread) then
   begin
   PoolThread.Terminate;
   PoolThread.WaitFor;
   end;

END. // END UNIT

