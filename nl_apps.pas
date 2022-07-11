unit nl_apps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,fphttpclient, nl_functions, strutils;

Function PostMessageToHost(host:string;port:integer;message:string):string;
Procedure LoadAppToPanel(texto, user:string);

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

Procedure LoadAppToPanel(texto,user:string);
var
  counter    : integer = 0;
  ThisData   : string  = '';
    ThisCom  : string  = '';
    ThisDet  : String  = '';
Begin
form1.LabelAppUser.Caption := user;
REPEAT
   ThisData := Parameter(Texto,counter);
   if ThisData <> '' then
      begin
      ThisData := StringReplace(ThisData,':',' ',[rfReplaceAll, rfIgnoreCase]);
      ThisCom  := Parameter(ThisData,0);
      if uppercase(ThisCom) = 'APPNAME' then
         Form1.LabelAppName.Caption := Parameter(ThisData,1);
      if uppercase(ThisCom) = 'BALANCE' then
         begin
         ThisDet := StringReplace(Parameter(ThisData,1),',',' ',[rfReplaceAll, rfIgnoreCase]);
         Form1.SG_App_Account.rowcount:= Form1.SG_App_Account.rowcount+1;
         Form1.SG_App_Account.Cells[0,Form1.SG_App_Account.rowcount-1]:=Parameter(ThisDet,0);
         Form1.SG_App_Account.Cells[2,Form1.SG_App_Account.rowcount-1]:=Parameter(ThisDet,1);
         if uppercase(Parameter(ThisDet,1)) = 'INTEGER' then Form1.SG_App_Account.Cells[1,Form1.SG_App_Account.rowcount-1]:= '0';
         if uppercase(Parameter(ThisDet,1)) = 'CURRENCY' then Form1.SG_App_Account.Cells[1,Form1.SG_App_Account.rowcount-1]:= int2curr(0);
         end;
      if uppercase(ThisCom) = 'INFO' then
         begin
         ThisDet := StringReplace(Parameter(ThisData,1),',',' ',[rfReplaceAll, rfIgnoreCase]);
         Form1.SG_App_Info.rowcount:= Form1.SG_App_Info.rowcount+1;
         Form1.SG_App_Info.Cells[0,Form1.SG_App_Info.rowcount-1]:=Parameter(ThisDet,0);
         Form1.SG_App_Info.Cells[2,Form1.SG_App_Info.rowcount-1]:=Parameter(ThisDet,1);
         if uppercase(Parameter(ThisDet,1)) = 'INTEGER' then Form1.SG_App_Info.Cells[1,Form1.SG_App_Info.rowcount-1]:= '0';
         if uppercase(Parameter(ThisDet,1)) = 'CURRENCY' then Form1.SG_App_Info.Cells[1,Form1.SG_App_Info.rowcount-1]:= int2curr(0);
         end;
      end;
   Inc(Counter);
UNTIL ThisData = '' ;

End;

END. // END UNIT

