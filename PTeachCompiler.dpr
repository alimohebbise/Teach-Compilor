program PTeachCompiler;
        {Ali_Mohebbi}
uses
  Vcl.Forms,
  UClassic in 'UClassic.pas' {FClassic},
  USyntaxLine in 'USyntaxLine.pas';
         {Ali_Mohebbi}
{$R *.res}
         {Ali_Mohebbi}
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFClassic, FClassic);
  Application.Run;
end.
