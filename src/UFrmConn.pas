unit UFrmConn;

interface

uses
  Windows, Messages, Forms, StdCtrls, PNGImage, ExtCtrls, Classes,
  Controls;

type
  TFrmConn = class(TForm)
    Label1: TLabel;
    Image1: TImage;
    Label2: TLabel;
    Label3: TLabel;
    BtnConn: TButton;
    BtnCan: TButton;
    EdUser: TEdit;
    EdPass: TEdit;
    EdServ: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    EdPort: TEdit;
    procedure BtnCanClick(Sender: TObject);
    procedure BtnConnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure EdPortKeyPress(Sender: TObject; var Key: Char);
    procedure EdPortChange(Sender: TObject);
    procedure EdServKeyPress(Sender: TObject; var Key: Char);
    procedure EdPassKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function AjustarConexao(var server, username, passwd: string;
  var port: Integer; ParentWindow: HWND): Boolean;

implementation

uses SysUtils;
{$R *.dfm}

function AjustarConexao(var server, username, passwd: string;
  var port: Integer; ParentWindow: HWND): Boolean;
var
  FrmConn: TFrmConn;
begin
  FrmConn := TFrmConn.CreateParented(ParentWindow);
  FrmConn.EdServ.Text := server;
  FrmConn.EdUser.Text := username;
  FrmConn.EdPass.Text := passwd;
  FrmConn.EdPort.Text := IntToStr(port);
  if FrmConn.ShowModal <> mrOk then
  begin
    Result := False;
    FrmConn.Free;
    Exit;
  end;
  server := FrmConn.EdServ.Text;
  username := FrmConn.EdUser.Text;
  passwd := FrmConn.EdPass.Text;
  port := StrToIntDef(FrmConn.EdPort.Text, port);
  FrmConn.Free;
  Result := True;
end;

procedure TFrmConn.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if ParentWindow <> 0 then
  begin
    Params.Style := Params.Style and not WS_CHILD;
    if BorderStyle = bsNone then
      Params.Style := Params.Style or WS_POPUP;
  end;
end;

procedure TFrmConn.BtnCanClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFrmConn.BtnConnClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TFrmConn.FormShow(Sender: TObject);
begin
  MessageBeep(48);
end;

procedure TFrmConn.EdPortKeyPress(Sender: TObject; var Key: Char);
begin
  EdServKeyPress(Sender, Key);
  if not CharInSet(Key, ['0' .. '9']) then
    Key := #0;
end;

procedure TFrmConn.EdPortChange(Sender: TObject);
begin
  if Length(TEdit(Sender).Text) = 0 then
  begin
    TEdit(Sender).Text := '0';
    TEdit(Sender).SelectAll;
  end;
end;

procedure TFrmConn.EdServKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
  begin
    PostMessage(Handle, WM_NEXTDLGCTL, 0, 0);
    Key := #0;
  end;
end;

procedure TFrmConn.EdPassKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
  begin
    BtnConn.Click;
    Key := #0;
  end;
end;

procedure TFrmConn.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel;
end;

end.
