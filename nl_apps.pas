unit nl_apps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,fphttpclient, nl_functions, strutils, nl_Language;

Function PostMessageToHost(host:string;port:integer;message:string):string;
Procedure RefreshPoolDataGrid(useraddress,ltcTier:string;usernoso,usernusdo,usershares,poolnoso,poolnusdo,
          poolshares,PoolVolume:int64);

implementation

Uses
  nl_mainform;

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
HTTPClient.IOTimeout:=60000; // <-- THIS is too restrictive, ONLY needed if you get stuck for more than 1 minute
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

END. // END UNIT

