unit nl_apps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,fphttpclient, nl_functions, strutils, nl_Language, nl_data;

Type
  TPoolThread = class(TThread)
  private
      procedure RefreshData;
  protected
    procedure Execute; override;
  public
    Constructor Create(const CreateSuspended : boolean);
  end;

  TActiveUser = packed record
     Address  : string;
     DepoLTC  : String;
     end;

Procedure RunPoolStatusRequest;
Procedure SetPoolUser(Address, deposit: string);
Procedure StartPoolThread();
Function PostMessageToHost(host:string;port:integer;message:string):string;
Procedure RefreshPoolDataGrid(useraddress,ltcTier:string;usernoso,usernusdo,usershares,poolnoso,poolnusdo,
          poolshares,PoolVolume:int64);
Procedure ShowAppPanel(LabMessage:String;InText:String;showEdit:integer;ShowButtons:boolean);
Procedure HideAppPanel();
Procedure ShowTradePanel();
Procedure HideTradePanel();
Procedure ShowWithdrawPanel();
Procedure HideWithdrawPanel();
Function GetPoolRanSeed():String;
Procedure ProcessStatusResponse(LineText:String);

CONST
  peOFF    = 0;
  peNormal = 1;
  peROnly  = 2;
  peCoin   = 3;
  PoolPub  = 'BImqS58bt56WV2yg4+HqtVCdEC2C1h0KYNyN2kjP0DKGDZXhn1uYtvKnkCcoX1t9FOVNu27jt4bK7l92K3AwPho=';

var
  PoolThread     : TPoolThread;
  LastPoolUpdate : Int64 = 0;
  PoolUser       : TActiveUser;
  PoolAddress    : String = 'N3yzCQtd6MEDwkPK6SpXpMpxPACgbF3';
  MessagePro     : string = '';
  PoolEditStyle  : integer;
  PoolNoso       : int64 = 0;
  PoolnUSDo      : int64 = 0;
  PoolShares     : integer = 0;
  PoolBuyFee     : integer = 0;
  PoolSellFee    : integer = 100;

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
      Synchronize(@RefreshData)
      end;
   end;
End;

procedure TPoolThread.RefreshData();
Begin
RunPoolStatusRequest;
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

Procedure SetPoolUser(Address, deposit: string);
Begin
PoolUser.Address:=Address;
PoolUser.DepoLTC:=deposit;
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
HTTPClient.IOTimeout:=3000; //
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
   if MessagePro = 'WITHLTCNOAD' then form1.ButtonPoolOkMessage.Enabled:=false;
   end
else if showedit = 2 then // Readonly
   begin
   Form1.EditPoolMessages.Text    :='';
   if MessagePro = 'DEPNUSDO' then Form1.EditPoolMessages.Text := PoolUser.DepoLTC;
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
form1.ButtonPoolOkMessage.Enabled:=true;
if MessagePro = 'DEPNOSOOK' then
   begin
   Form1.PageCOntrol.ActivePage:= Form1.TabWallet;
   Form1.TabWallet.TabVisible:=true;
   Form1.EditSCDest.Text := 'liqpool';
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

Procedure ShowTradePanel();
Begin
Form1.PanelPoolTop.Enabled:=false;
Form1.PanelPoolMain.Enabled:=false;
Form1.PanelPoolMain.Enabled:=false;
Form1.PanelPoolTrade.Visible:=true;
Form1.PanelPoolTrade.BringToFront;
MessagePro := 'TRADE';
Form1.Label10.Caption:=Format('Fee %s %%',[FormatFLoat('0.00',PoolBuyFee*100/10000)]);
Form1.Label24.Caption:=Format('Fee %s %%',[FormatFLoat('0.00',PoolSellFee*100/10000)]);;
End;

Procedure HideTradePanel();
Begin
Form1.PanelPoolTop.Enabled:=true;
Form1.PanelPoolMain.Enabled:=true;
Form1.PanelPoolMain.Enabled:=true;
Form1.PanelPoolTrade.Visible:=false;
Form1.PanelPoolTrade.SendToBack;
MessagePro := '';
End;

Procedure ShowWithdrawPanel();
Begin
Form1.PanelPoolTop.Enabled:=false;
Form1.PanelPoolMain.Enabled:=false;
Form1.PanelPoolMain.Enabled:=false;
Form1.PanelWithdraw.Visible:=true;
Form1.PanelWithdraw.BringToFront;
End;

Procedure HideWithdrawPanel();
Begin
Form1.PanelPoolTop.Enabled:=true;
Form1.PanelPoolMain.Enabled:=true;
Form1.PanelPoolMain.Enabled:=true;
Form1.PanelWithdraw.Visible:=false;
Form1.PanelWithdraw.SendToBack;
MessagePro := '';
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
  PoolVolume : int64;
Begin
if Parameter(LineText,0) = 'STATUS' then
   begin
   Address      := Parameter(LineText,1);
   NosoBalance  := StrToInt64Def(Parameter(LineText,2),0);
   nUSDoBalance := StrToInt64Def(Parameter(LineText,3),0);
   Shares       := StrToIntDef(Parameter(LineText,4),0);
   LTCTicker    := Parameter(LineText,6);
   PoolNoso     := StrToInt64Def(Parameter(LineText,7),0);
   PoolnUSDo    := StrToInt64Def(Parameter(LineText,8),0);
   PoolShares   := StrToIntDef(Parameter(LineText,9),0);
   PoolVolume   := StrToInt64Def(Parameter(LineText,10),0);
   PoolBuyFee   := StrToInt64Def(Parameter(LineText,11),PoolBuyFee);
   PoolSellFee   := StrToInt64Def(Parameter(LineText,12),PoolSellFee);
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

