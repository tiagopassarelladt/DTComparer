unit Unit4;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, DTComparer;

type
  TForm4 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    ProgressBar1: TProgressBar;
    Label3: TLabel;
    Button1: TButton;
    DTComparer1: TDTComparer;
    Memo1: TMemo;
    Label4: TLabel;
    GroupBox1: TGroupBox;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    Label5: TLabel;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure DTComparer1Status(Msg: string; TotalRegistros,
      PosicaoAtual: Integer);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.Button1Click(Sender: TObject);
begin
      DTComparer1.BancoMaster      := Edit1.Text;
      DTComparer1.BancoCliente     := Edit2.Text;
      DTComparer1.CaminhoVendorLib := ExtractFilePath( Application.ExeName ) + 'fbclient.dll';
      DTComparer1.UserName         := 'SYSDBA';
      DTComparer1.SenhaBanco       := 'masterkey';
      DTComparer1.Porta            := '3050';
      DTComparer1.Server           := 'localhost';
      if CheckBox1.Checked then
      DTComparer1.ComparaValoresDefault := True;
      if CheckBox2.Checked then
      DTComparer1.VerificaTriggers := true;
      if CheckBox3.Checked then
      DTComparer1.VerificaIndices  := True;

      DTComparer1.Script := Memo1.Text;

      DTComparer1.ComparaBancos;

      label5.Caption := 'Scripts Executados: ' + DTComparer1.ScriptsExecutados.ToString;
end;

procedure TForm4.Button2Click(Sender: TObject);
begin
      if OpenDialog1.Execute then
         Edit1.Text := OpenDialog1.FileName;
end;

procedure TForm4.Button3Click(Sender: TObject);
begin
     if OpenDialog1.Execute then
         Edit2.Text := OpenDialog1.FileName;
end;

procedure TForm4.DTComparer1Status(Msg: string; TotalRegistros,
  PosicaoAtual: Integer);
begin
      ProgressBar1.Min      := 0;
      ProgressBar1.Max      := TotalRegistros;
      ProgressBar1.Position := PosicaoAtual;
      Label3.Caption        := Msg;
end;

end.