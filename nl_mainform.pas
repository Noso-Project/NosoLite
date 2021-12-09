unit nl_mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Grids, Menus, nl_GUI;

type

  { TForm1 }

  TForm1 = class(TForm)
    MainMenu: TMainMenu;
    MM_File: TMenuItem;
    PageControl: TPageControl;
    PanelBalance: TPanel;
    PanelStatus: TPanel;
    SGridAddresses: TStringGrid;
    TabWallet: TTabSheet;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

// On create form events
procedure TForm1.FormCreate(Sender: TObject);
Begin

End;

// On show form events
procedure TForm1.FormShow(Sender: TObject);
Begin

End;

// On resize form events
procedure TForm1.FormResize(Sender: TObject);
begin
ResizeSGridAddresses();
end;

// On close query form events
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
Begin

End;

// On close form events
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Begin

End;




END. // END PROGRAM

