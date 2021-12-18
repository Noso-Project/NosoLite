unit nl_explorer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Grids,
  StdCtrls, Buttons, CheckLst, nl_language, nl_functions, fileutil, Types, nl_data;

type

  { TFormExplorer }

  TFormExplorer = class(TForm)
    ButCancelAdd: TSpeedButton;
    CheckBoxSelectAll: TCheckBox;
    CHLBAddresses: TCheckListBox;
    ComBoxMask: TComboBox;
    EditPath: TEdit;
    EditFilename: TEdit;
    ImageList: TImageList;
    LabAdd: TLabel;
    PanelAddTop: TPanel;
    PanelAddresses: TPanel;
    PanelExplorer: TPanel;
    PanelTop: TPanel;
    PanelBottom: TPanel;
    ButFolderUp: TSpeedButton;
    GridExplorer: TStringGrid;
    ButAccept: TSpeedButton;
    ButOkAdd: TSpeedButton;
    procedure ButAcceptClick(Sender: TObject);
    procedure ButCancelAddClick(Sender: TObject);
    procedure ButFolderUpClick(Sender: TObject);
    procedure ButOkAddClick(Sender: TObject);
    procedure CheckBoxSelectAllClick(Sender: TObject);
    procedure ComBoxMaskChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GridExplorerDblClick(Sender: TObject);
    procedure GridExplorerDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure GridExplorerPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure GridExplorerSelection(Sender: TObject; aCol, aRow: Integer);
    Procedure LoadDirectory(const Directory: String);
    function OnlyName(const conpath: String): String;
  private
    FActiveDir: String;
    FilesDir: TStringList;
    FoldersDir: TStringList;

  public

  end;

Procedure ShowExplorer(const Directory: String; FormTitle,SetMask:string;FixedName:boolean);

var
  FormExplorer: TFormExplorer;
  FResult : STring = '';
  FileMasK : String;
  FileArray : array of walletdata;

implementation

{$R *.lfm}

{ TFormExplorer }

//******************************************************************************
// FORM RELATIVE EVENTS
//******************************************************************************

// On create
procedure TFormExplorer.FormCreate(Sender: TObject);
Begin
GridExplorer.FocusRectVisible:=false;
GridExplorer.Cells[0,0] := rsEXP0001;
FilesDir := TStringList.Create;
FoldersDir := TStringList.Create;
End;

// On show form
procedure TFormExplorer.FormShow(Sender: TObject);
Begin
End;

// On form resize
procedure TFormExplorer.FormResize(Sender: TObject);
Begin
GridExplorer.colwidths[0] := thispercent(100,GridExplorer.Width);
End;

// On form close
procedure TFormExplorer.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Begin
FormExplorer.PanelAddresses.Visible:=false;
End;

// On form Destroy
procedure TFormExplorer.FormDestroy(Sender: TObject);
Begin
FilesDir.Free;
FoldersDir.Free;
End;

//******************************************************************************
// STRINGGRID explorer
//******************************************************************************

// On double click
procedure TFormExplorer.GridExplorerDblClick(Sender: TObject);
Begin
if (GridExplorer.Row > 0) and (Copy(GridExplorer.Cells[0,GridExplorer.Row],1,3) = '   ' ) then
   begin
   FActiveDir := FActiveDir+DirectorySeparator+ Copy(GridExplorer.Cells[0,GridExplorer.Row],4,Length(GridExplorer.Cells[0,GridExplorer.Row]));
   LoadDirectory(FActiveDir);
   end;
if (GridExplorer.Row > 0) and (Copy(GridExplorer.Cells[0,GridExplorer.Row],1,3) <> '   ' ) then
    begin
    EditFilename.Text := GridExplorer.Cells[0,GridExplorer.Row];
    //ButAcceptClick(nil);
    end;
End;

// On Draw Cell
procedure TFormExplorer.GridExplorerDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  Bitmap    : TBitmap;
  myRect    : TRect;
Begin
if copy((sender as TStringGrid).Cells[0,arow],1,3) = '   ' then
   begin
   Bitmap:=TBitmap.Create;
   ImageList.GetBitmap(0,Bitmap);
   myRect := Arect;
   myrect.Left:=myRect.Left+6;
   myRect.Right := myrect.Left+16;
   myrect.Bottom:=myrect.Top+16;
   (sender as TStringGrid).Canvas.StretchDraw(myRect,bitmap);
   Bitmap.free
   end;
End;

// On prepare canvas
procedure TFormExplorer.GridExplorerPrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
Begin
if ((arow = GridExplorer.Row) and (arow>0)) then
   begin
   (Sender as TStringGrid).Canvas.Brush.Color :=  clblue;
   (Sender as TStringGrid).Canvas.Font.Color:=clwhite
   end;
End;

// On selection
procedure TFormExplorer.GridExplorerSelection(Sender: TObject; aCol,
  aRow: Integer);
Begin
EditFilename.Text := GridExplorer.Cells[0,GridExplorer.Row];
if Copy(EditFilename.Text,1,3) = '   ' then EditFilename.Text := '';
End;

//******************************************************************************
// PANEL EXPLORER
//******************************************************************************

// Button go up folder
procedure TFormExplorer.ButFolderUpClick(Sender: TObject);
var
  counter : integer;
Begin
for counter := length(FActiveDir) downto 1 do
   begin
   if FActiveDir[counter] = DirectorySeparator then
      begin
      FActiveDir := copy(FActiveDir,1,counter-1);
      LoadDirectory(FActiveDir);
      Break;
      end;
   end;
End;

// Change mask combobox
procedure TFormExplorer.ComBoxMaskChange(Sender: TObject);
Begin
FileMasK := FormExplorer.ComBoxMask.Text;
FormExplorer.LoadDirectory(FActiveDir);
End;

// Button open file
procedure TFormExplorer.ButAcceptClick(Sender: TObject);
var
  PathFile : String;
  WalletFile : file of WalletData;
  ThisData : WalletData;
  Counter : integer;
Begin
if EditFilename.Text = '' then
   begin
   FormExplorer.Hide;
   end
else
   begin
   SetLength(FileArray,0);
   PathFile := FActiveDir+DirectorySeparator+EditFilename.Text;
   if fileexists(PathFile) then
      begin
      AssignFile(WalletFile,PathFile);
      TRY
      Reset(WalletFile);
      for counter := 0 to filesize(WalletFile)- 1 do
         begin
         seek(walletfile,counter);
         read(walletfile,ThisData);
         insert(ThisData,FileArray,length(filearray));
         end;
      CloseFile(WalletFile);
      EXCEPT on E:Exception do
         begin
         // ERROR READING FILE
         end;
      END{Try};
      FormExplorer.PanelAddresses.Visible:=true;
      CHLBAddresses.Clear;
      for counter := 0 to length(filearray)-1 do
         begin
         CHLBAddresses.AddItem(GetAddressToShow(filearray[counter].Hash),nil);
         end;
      end;
   end;
End;

//******************************************************************************
// PANEL ADDRESSESS
//******************************************************************************

// Button confirm import
procedure TFormExplorer.ButOkAddClick(Sender: TObject);
var
  counter : integer;
Begin
for counter := 0 to length(FileArray)-1 do
   if CHLBAddresses.Checked[counter] then TryInsertAddress(FileArray[counter]);
FormExplorer.Close;
End;

// Checkbox select all addressess
procedure TFormExplorer.CheckBoxSelectAllClick(Sender: TObject);
var
  counter : integer;
Begin
for counter := 0 to CHLBAddresses.Count-1 do
   CHLBAddresses.Checked[counter] := CheckBoxSelectAll.Checked;
End;

// Button cancel addresses
procedure TFormExplorer.ButCancelAddClick(Sender: TObject);
Begin
FormExplorer.PanelAddresses.Visible:=false;
End;

//******************************************************************************
// UNIT FUNCTIONS
//******************************************************************************

// When a explorer is called to be displayed
Procedure ShowExplorer(const Directory: String; FormTitle,SetMask:string;FixedName:boolean);
Begin
FormExplorer.Caption:=FormTitle;
FileMasK := SetMask;
FormExplorer.LoadDirectory(Directory);
FormExplorer.EditFilename.ReadOnly:=FixedName;
if FormExplorer.ComBoxMask.Items.count>1 then FormExplorer.ComBoxMask.Items.Delete(1);
FormExplorer.ComBoxMask.ItemIndex:=1;
FormExplorer.ComBoxMask.Items.Add(SetMask);
FormExplorer.ComBoxMask.ItemIndex:=1;
FormExplorer.Show;
FResult := '';
FormExplorer.GridExplorer.ColWidths[0] := thispercent(100,FormExplorer.GridExplorer.Width);
End;

// Loads the specified folder
procedure TFormExplorer.LoadDirectory(const Directory: String);
var
  cont: Integer;
Begin
  FilesDir.Clear;
  FoldersDir.Clear;
  GridExplorer.RowCount := 1;
  FindAllFiles(FilesDir, Directory, FileMask, False);
  FindAllDirectories(FoldersDir, Directory, False);
  if FoldersDir.Count > 0 then
    for cont := 0 to FoldersDir.Count-1 do
      begin
        GridExplorer.RowCount := GridExplorer.RowCount+1;
        GridExplorer.Cells[0,cont+1] := '   ' + OnlyName(FoldersDir[cont]);
      end;
  if FilesDir.Count > 0 then
    for cont := 0 to FilesDir.Count-1 do
      begin
        GridExplorer.RowCount := GridExplorer.RowCount+1;
        GridExplorer.Cells[0,GridExplorer.RowCount-1] := OnlyName(FilesDir[cont]);
      end;
  EditPath.Text := Directory;
  FActiveDir := Directory;
  EditFilename.Text := GridExplorer.Cells[0,GridExplorer.Row];
  if Copy(EditFilename.Text,1,3) = '   ' then EditFilename.Text := '';
  if GridExplorer.RowCount=1 then EditFilename.Text := '';
End;

// Returns only the name (without path) of the specified dile
function TFormExplorer.OnlyName(const conpath: String): String;
var
  cont: Integer;
Begin
  result := '';
  for cont := Length(conpath) downto 1 do
   if conpath[cont] = DirectorySeparator then
     begin
       Result := Copy(conpath, cont+1, Length(conpath));
       Break;
     end;
End;

END. // END UNIT.

