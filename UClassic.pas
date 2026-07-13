unit UClassic;
   {Ali_Mohebbi}
interface
   {Ali_Mohebbi}
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls;
   {Ali_Mohebbi}
type
  TFClassic = class(TForm)
    PanelTop: TPanel;
    PanelLeft: TPanel;
    PanelClient: TPanel;
    MemoInp: TMemo;
    MemoOut: TMemo;
    BtnSave: TButton;
    BtnRun: TButton;
    ComboInp: TComboBox;
    BtnCode: TButton;
    BtnDate: TButton;
    BtnTranslator: TButton;
    BtnParser: TButton;
    BtnDecision: TButton;
    BtnIrregular: TButton;
    BtnStr: TButton;
    BtnNum: TButton;
    BtnInt: TButton;
    BtnId: TButton;
    BtnUnread: TButton;
    procedure FormActivate(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure ComboInpChange(Sender: TObject);
    procedure BtnRunClick(Sender: TObject);
    procedure BtnUnreadClick(Sender: TObject);
    procedure BtnIdClick(Sender: TObject);
    procedure BtnIntClick(Sender: TObject);
    procedure BtnNumClick(Sender: TObject);
    procedure BtnStrClick(Sender: TObject);
    procedure BtnIrregularClick(Sender: TObject);
    procedure BtnDecisionClick(Sender: TObject);
    procedure BtnParserClick(Sender: TObject);
    procedure BtnTranslatorClick(Sender: TObject);
    procedure BtnDateClick(Sender: TObject);
    procedure BtnCodeClick(Sender: TObject);
  private
    function ResolveFileName(const FileName: string): string;
  public
    { Public declarations }
  end;
    {Ali_Mohebbi}
var
  FClassic: TFClassic;
    {Ali_Mohebbi}
implementation
    {Ali_Mohebbi}
{$R *.dfm}
    {Ali_Mohebbi}
uses
  USyntaxLine, IOUtils;
    {Ali_Mohebbi}
var
  Inp: TSyntaxLine;
    {Ali_Mohebbi}
function TFClassic.ResolveFileName(const FileName: string): string;
begin
  if FileName= '' then
    Exit('');

  if TPath.IsPathRooted(FileName) then
    Exit(FileName);

  if FileExists(FileName) then
    Exit(TPath.GetFullPath(FileName));

  if FileExists(TPath.Combine(TDirectory.GetCurrentDirectory, FileName)) then
    Exit(TPath.Combine(TDirectory.GetCurrentDirectory, FileName));

  if FileExists(TPath.Combine(TDirectory.GetCurrentDirectory, 'Win32', 'Debug', FileName)) then
    Exit(TPath.Combine(TDirectory.GetCurrentDirectory, 'Win32', 'Debug', FileName));

  Result:= TPath.Combine(TDirectory.GetCurrentDirectory, FileName);
end;

procedure TFClassic.BtnCodeClick(Sender: TObject);             {Ali_Mohebbi}
begin
  MemoOut.Lines.Clear;
  MemoOut.Lines.Add('Codes =');
  MemoOut.Lines.AddStrings(Inp.SkipCodes.ToLines);
end;

procedure TFClassic.BtnDateClick(Sender: TObject);
begin
  MemoOut.Lines.Text:= Inp.SkipDate;
end;

procedure TFClassic.BtnDecisionClick(Sender: TObject);         {Ali_Mohebbi}
var
  S: String;
begin
  case Inp.WhichIs(['#id', '$if', '$while', '$for']) of
    0:                                                         {Ali_Mohebbi}
      begin
        S:= Inp.SkipId;
        S:= S+ ' '+ Inp.SkipSep(':=');
        S:= S+ ' '+ Inp.SkipId;
        S:= S+ ' '+ Inp.SkipSep('+');
        S:= S+ ' '+ Inp.SkipId;
      end;
    1:                                                         {Ali_Mohebbi}
      begin
        S:= Inp.SkipKey('if');
        S:= S+ ' '+ Inp.SkipId;
        S:= S+ ' '+ Inp.SkipSep('=');
        S:= S+ ' '+ Inp.SkipId;
        S:= S+ ' '+ Inp.SkipKey('then');
      end;
    2:                                                         {Ali_Mohebbi}
      begin
        S:= Inp.SkipKey('while');
        S:= S+ ' '+ Inp.SkipId;
        S:= S+ ' '+ Inp.SkipSep('=');
        S:= S+ ' '+ Inp.SkipId;
        S:= S+ ' '+ Inp.SkipKey('do');
      end;
    3:                                                         {Ali_Mohebbi}
     begin
        S:= Inp.SkipKey('for');
        S:= S+ ' '+ Inp.SkipId;
        S:= S+ ' '+ Inp.SkipSep(':=');
        S:= S+ ' '+ Inp.SkipId;
        S:= S+ ' '+ Inp.SkipKey('to');
        S:= S+ ' '+ Inp.SkipId;
        S:= S+ ' '+ Inp.SkipKey('do');
      end;
  else
    Inp.SyntaxError('if , while , for , id Expected')
  end;

  MemoOut.Lines.Text:= S;
end;

procedure TFClassic.BtnIdClick(Sender: TObject);
begin
  MemoOut.Lines.Text:= Inp.SkipId;
end;

procedure TFClassic.BtnIntClick(Sender: TObject);
begin
  MemoOut.Lines.Text:= Inp.SkipInt.ToString;         {Ali_Mohebbi}
end;

procedure TFClassic.BtnIrregularClick(Sender: TObject);        {Ali_Mohebbi}
var
  S: String;
begin
  // for #id := #int to #int do
  S:= Inp.Skip('for');
  S:= S+ ' '+ Inp.Skip('#id');
  S:= S+ ' '+ Inp.Skip(':=');
  S:= S+ ' '+ Inp.Skip('#int');
  S:= S+ ' '+ Inp.Skip('$to');
  S:= S+ ' '+ Inp.Skip('#int');
  S:= S+ ' '+ Inp.Skip('$do');
  MemoOut.Lines.Text:= S;
end;

procedure TFClassic.BtnNumClick(Sender: TObject);
begin
  MemoOut.Lines.Text:= Inp.SkipNum.ToString;
end;

procedure TFClassic.BtnParserClick(Sender: TObject); {Ali_Mohebbi}
begin
  MemoOut.Lines.Text:= Inp.SkipSXY;
//  MemoOut.Lines.Text:= Inp.SkipSPNV;
end;

procedure TFClassic.BtnRunClick(Sender: TObject);    {Ali_Mohebbi}
var                                                  {Ali_Mohebbi}
  F: String;
begin                                                {Ali_Mohebbi}
  F:= UpperCase(ComboInp.Text);                      {Ali_Mohebbi}
  if F= 'UNREAD.TXT' then
    BtnUnread.Click
  else if F= 'INT.TXT' then
    BtnInt.Click
  else if F= 'ID.TXT' then
    BtnId.Click
  else if F= 'NUM.TXT' then
    BtnNum.Click
  else if F= 'STR.TXT' then
    BtnStr.Click
  else if F= 'IRREGULAR.TXT' then                    {Ali_Mohebbi}
    BtnIrregular.Click
  else if F= 'DECISION.TXT' then
    BtnDecision.Click
  else if F= 'PARSER.TXT' then
    BtnParser.Click
  else if F= 'TRANSLATOR.TXT' then
    BtnTranslator.Click
  else if F= 'DATE.TXT' then
    BtnDate.Click
  else if F= 'CODE.TXT' then
    BtnCode.Click;
end;                                                 {Ali_Mohebbi}

procedure TFClassic.BtnSaveClick(Sender: TObject);     {Ali_Mohebbi}
var
  FileName: string;
begin
  FileName:= ResolveFileName(ComboInp.Text);
  MemoInp.Lines.SaveToFile(FileName);
  Inp.LoadFile(FileName);
end;

procedure TFClassic.BtnStrClick(Sender: TObject);                 {Ali_Mohebbi}
begin
  MemoOut.Lines.Text:= Inp.SkipStrQuot;
end;

procedure TFClassic.BtnTranslatorClick(Sender: TObject);          {Ali_Mohebbi}
begin
//  MemoOut.Lines.Text:= 'Depth = '+ Inp.SkipDepth.ToString;
  MemoOut.Lines.Text:= 'ExpVal = '+ Inp.SkipExpVal.ToString;
end;

procedure TFClassic.BtnUnreadClick(Sender: TObject);
begin
  MemoOut.Lines.Text:= Inp.SkipUnread;                            {Ali_Mohebbi}
end;

procedure TFClassic.ComboInpChange(Sender: TObject);              {Ali_Mohebbi}
var
  FileName: string;
begin
  FileName:= ResolveFileName(ComboInp.Text);
  MemoInp.Lines.LoadFromFile(FileName);
  Inp.LoadFile(FileName);
end;

procedure TFClassic.FormActivate(Sender: TObject);                {Ali_Mohebbi}
var
  i: Integer;
  F: TArray<String>;
  FileName: string;
begin                                                             {Ali_Mohebbi}
  F:= TDirectory.GetFiles(TDirectory.GetCurrentDirectory, '*.txt');
  F:= F + TDirectory.GetFiles(TDirectory.GetCurrentDirectory + '/Win32/Debug', '*.txt');
  for i:= 0 to High(F) do
    F[i]:= TPath.GetFileName(F[i]);
           {Ali_Mohebbi}
  ComboInp.Items.Clear;
  ComboInp.Items.AddStrings(F);
  ComboInp.ItemIndex:= 0;

  FileName:= ResolveFileName(ComboInp.Text);
  MemoInp.Lines.LoadFromFile(FileName);
  Inp.LoadFile(FileName);
end;
        {Ali-Mohebbi}
end.
