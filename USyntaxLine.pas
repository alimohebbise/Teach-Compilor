 unit USyntaxLine;
    {Ali_Mohebbi}
interface
    {Ali_Mohebbi}
uses Dialogs, SysUtils, IOUtils, Character, Types, Generics.Collections;
    {Ali_Mohebbi}
type                                              {Ali_Mohebbi}
  TStrList= array of string;

  TStackRec<T> = record
    Stk: TStack<T>;
    class operator Initialize(out Dest: TStackRec<T>);
    class operator Finalize(var Dest: TStackRec<T>);
    procedure Push(const Value: T); inline;
    function Pop: T; inline;
    function Peek: T; inline;
  end;

  TCode= record                                   {Ali_Mohebbi}
     Op, Addr1, Addr2, Target: string;
  end;

  TCodeList= array of TCode;                      {Ali_Mohebbi}
  HCodeList = record helper for TCodeList
    function Add(Op, Addr1, Addr2, Target: String): Integer;
    function ToLines: TStrList;
  end;

  TSyntaxLine= record
  private const
    EofCh= #1;
  private
    Text: string;
    Pos, NewPos: Integer;
    Loc: TPoint;
  public
    procedure Clear;
    procedure SetText(L: string);
    procedure LoadFile(FName: string);
    function JumpTo(APos: Integer): string;
    function IsEof: Boolean;                      {Ali_Mohebbi}
    function CurrentLine: string;
    procedure SyntaxError(Msg: string);
    // Regular
    function IsUnread: Boolean;
    function SkipUnread: string;
    function IsId: Boolean;
    function SkipId: string;
    function IsInt: Boolean;
    function SkipInt: Integer;
    function IsDate: Boolean;
    function SkipDate: string;
    function IsNum: Boolean;
    function SkipNum: Double;
    function IsStr: Boolean;                      {Ali_Mohebbi}
    function SkipStrQuot: string;
    function SkipStrVal: string;
    // Irregular
    function IsSep(Sep: string): Boolean;         {Ali_Mohebbi}
    function SkipSep(Sep: string): string;
    function IsKey(Key: string): Boolean;         {Ali_Mohebbi}
    function SkipKey(Key: string): string;
    // Advanced
    function IsNext(Any: string): Boolean;
    function Skip(Any: string): string;
    // Decision
    function WhichIs(L: TStrList): Integer;       {Ali_Mohebbi}
    function InList(L: TStrList): Boolean;        {Ali_Mohebbi}
    // Parser
    function SkipSXY: string;                     {Ali_Mohebbi}
    function SkipSPNV: string;
    // Translator
    function SkipDepth: Integer;                  {Ali_Mohebbi}
    function SkipExpVal: Double;                  {Ali_Mohebbi}
    // Code
  private type
    TSemanticAction = (saId, saNum, saStr, saAdd, saSub, saMul, saDiv, saOr, saAnd,
      saLess, saEqual, saGreat, saLessEq, saNotEq, saGreatEq, saNeg, saNot, saCopy, saThen, saElse, saTarget, saLabel, saDoWhile, saEndWhile, saToFor, saDoFor, saEndFor);
  private
    SS: TStackRec<String>;
    Codes: TCodeList;
    TempNo: Integer;                                                      {Ali_Mohebbi}
    function NewTemp: string;
    procedure DoAction(Act: TSemanticAction; TokenVal: String = '');
  public
    procedure SkipExp;
    procedure SkipStatement;
    procedure SkipAssign;
    procedure SkipIf;
    procedure SkipWhile;
    procedure SkipFor;
    function SkipCodes: TCodeList;
  end;

     {Ali_Mohebbi}
implementation

uses Math;

{ TSyntaxLine }

procedure TSyntaxLine.Clear;
begin
  Text:= '';
  Pos:= 1;
  Loc:= Point(1, 1);
end;
    {Ali_Mohebbi}
function TSyntaxLine.CurrentLine: string;
var
  p1, p2: Integer;
begin
  for p1:= Pos downto 1 do
    if Text[p1] in [#10, #13] then
      Break;

  for p2:= Pos to High(Text) do
    if Text[p2] in [#10, #13] then
      Break;

  Result:= Copy(Text, p1+ 1, p2- p1- 1);
end;
procedure TSyntaxLine.DoAction(Act: TSemanticAction; TokenVal: String);          {Ali_Mohebbi}
var
  L, R, Temp: String;
  P1, P2, L1: Integer;
begin
  case Act of
    saId, saNum, saStr:
      SS.Push(TokenVal);
    saAdd..saGreatEq:
      begin
        R := SS.Pop;
        L := SS.Pop;
        Temp := NewTemp;
        Codes.Add(TokenVal, L, R, Temp);
        SS.Push(Temp);
      end;
    saNeg, saNot:                                        {Ali_Mohebbi}
      begin
        Temp := NewTemp;
        Codes.Add(TokenVal, SS.Pop, '', Temp);
        SS.Push(Temp);
      end;
    saCopy:                                              {Ali_Mohebbi}
      begin
        R := SS.Pop;
        L := SS.Pop;
        Codes.Add(':=', R, '', L);
      end;
    saThen:                                              {Ali_Mohebbi}
      begin
        P1 := Codes.Add('jf', SS.Pop, '', '');
        SS.Push(P1.ToString);
      end;
    saTarget:                                            {Ali_Mohebbi}
      Codes[SS.Pop.ToInteger].Target:= Length(Codes).ToString;
    saElse:                                              {Ali_Mohebbi}
      begin
        P1 := SS.Pop.ToInteger;
        P2 := Codes.Add('j', '', '', '');
        SS.Push(P2.ToString);
        Codes[P1].Target:= Length(Codes).ToString;       {Ali_Mohebbi}
      end;
    saLabel:
      SS.Push(Length(Codes).ToString);
    saDoWhile:
      begin
        P1 := Codes.Add('JF', SS.Pop, '', '');
        SS.Push(P1.ToString);
      end;
    saEndWhile:
      begin
        P1 := SS.Pop.ToInteger;
        L1 := SS.Pop.ToInteger;
        Codes.Add('J', '', '', L1.ToString);
        Codes[P1].Target := Length(Codes).ToString;
      end;
    saToFor:                                         {Ali_Mohebbi}
      begin
        R:= SS.Pop;
        L:= SS.Peek;
        Codes.Add(':=', R, '', L);
      end;
    saDoFor:                                         {Ali_Mohebbi}
      begin
        R:= SS.Pop;
        L:= SS.Peek;
        Temp:= NewTemp;
        L1:= Codes.Add('<=', L, R, Temp);
        P1:= Codes.Add('JF', Temp, '', '');
        SS.Push(L1.ToString);
        SS.Push(P1.ToString);
      end;
    saEndFor:                                       {Ali_Mohebbi}
      begin
        P1:= SS.Pop.ToInteger;
        L1:= SS.Pop.ToInteger;
        R:= SS.Pop;
        Codes.Add('Inc', R, '', '');
        Codes.Add('J', '', '', L1.ToString);
        Codes[P1].Target:= Length(Codes).ToString;
      end;
  end;
end;


function TSyntaxLine.InList(L: TStrList): Boolean;       {Ali_Mohebbi}
begin
  Result:= WhichIs(L)<> -1;
end;

{Ali_Mohebbi}
function TSyntaxLine.IsEof: Boolean;
begin
  Result:= (Pos> High(Text)) or (Text[Pos]= EofCh);
end;
function TSyntaxLine.IsId: Boolean;
var
  p, State: Integer;
begin
  SkipUnread;
  State:= 0;
      {Ali_Mohebbi}
  for p:= Pos to High(Text) do
    case State of
      0:
        if Text[p].IsLetter then
          State:= 1
        else
          Break;
      1:
        if Text[p].IsLetterOrDigit then
          State:= 1
        else
          Break;
    end;
      {Ali_Mohebbi}
  Result:= State in [1];
  if Result then NewPos:= p;
end;

function TSyntaxLine.IsInt: Boolean;
var
  p, State: Integer;
begin
  SkipUnread;
  State:= 0;
           {Ali_Mohebbi}
  for p:= Pos to High(Text) do
    case State of
      0:
        if Text[p] in ['+', '-'] then
          State:= 1
        else if Text[p].IsDigit then
          State:= 2
        else
          Break;
      1:
        if Text[p].IsDigit then
          State:= 2
        else
          Break;
      2:
        if Text[p].IsDigit then            {Ali_Mohebbi}
          State:= 2
        else
          Break;
    end;

  Result:= State in [2];
  if Result then NewPos:= p;
end;

function TSyntaxLine.IsDate: Boolean;
var
  p, State: Integer;
  Year, Month, Day: Integer;
begin
  SkipUnread;
  State:= 0;

  for p:= Pos to High(Text) do
    case State of
      0:
        if Text[p].IsDigit then
          State:= 1
        else
          Break;
      1:
        if Text[p].IsDigit then
          State:= 2
        else
          Break;
      2:
        if Text[p].IsDigit then
          State:= 3
        else
          Break;
      3:
        if Text[p].IsDigit then
          State:= 4
        else
          Break;
      4:
        if Text[p]= '/' then
          State:= 5
        else
          Break;
      5:
        if Text[p].IsDigit then
          State:= 6
        else
          Break;
      6:
        if Text[p].IsDigit then
          State:= 7
        else
          Break;
      7:
        if Text[p]= '/' then
          State:= 8
        else
          Break;
      8:
        if Text[p].IsDigit then
          State:= 9
        else
          Break;
      9:
        if Text[p].IsDigit then
          State:= 10
        else
          Break;
      10:
        Break;
    end;

  Result:= State= 10;
  if Result then
  begin
    NewPos:= p;
    Result:= TryStrToInt(Copy(Text, Pos, 4), Year)
      and TryStrToInt(Copy(Text, Pos+ 5, 2), Month)
      and TryStrToInt(Copy(Text, Pos+ 8, 2), Day)
      and (Year>= 0) and (Year<= 9999)
      and (Month>= 1) and (Month<= 12)
      and (Day>= 1)
      and (((Month<= 6) and (Day<= 31)) or ((Month> 6) and (Day<= 30)));
  end;
end;

function TSyntaxLine.IsKey(Key: string): Boolean;
begin
  Result:= IsId and (Copy(Text, Pos, NewPos- Pos).ToUpper= Key.ToUpper);
end;

function TSyntaxLine.IsNext(Any: string): Boolean;          {Ali_Mohebbi}
var
  T: string;
begin
  SkipUnread;

  T:= Any.ToUpper;
  if T= '#ID' then
    Result:= IsId
  else if T= '#INT' then
    Result:= IsInt
  else if T= '#DATE' then
    Result:= IsDate
  else if T= '#NUM' then
    Result:= IsNum
  else if T= '#STR' then
    Result:= IsStr
  else if (Any.Length>= 2) and (Any[1]= '$') then
    Result:= IsKey(Copy(Any, 2))
  else
    Result:= IsSep(Any);
end;

function TSyntaxLine.IsNum: Boolean;        {Ali_Mohebbi}
var
  p, State: Integer;
begin
  SkipUnread;
  State:= 0;
                                            {Ali_Mohebbi}
  for p:= Pos to High(Text) do
    case State of
      0:                                    {Ali_Mohebbi}
        if Text[p] in ['+', '-'] then
          State:= 1
        else if Text[p].IsDigit then
          State:= 2
        else
          Break;
      1:                                    {Ali_Mohebbi}
        if Text[p].IsDigit then
          State:= 2
        else
          Break;
      2:                                    {Ali_Mohebbi}
        if Text[p].IsDigit then
          State:= 2
        else if Text[p]= '.' then
          State:= 3
        else if Text[p].ToUpper= 'E' then
          State:= 5
        else
          Break;
      3:                                    {Ali_Mohebbi}
        if Text[p].IsDigit then
          State:= 4
        else
          Break;
      4:                                    {Ali_Mohebbi}
        if Text[p].IsDigit then
          State:= 4
        else if Text[p].ToUpper= 'E' then
          State:= 5
        else
          Break;
      5:                                    {Ali_Mohebbi}
        if Text[p] in ['+', '-'] then
          State:= 6
        else if Text[p].IsDigit then
          State:= 7
        else
          Break;
      6:                                    {Ali_Mohebbi}
        if Text[p].IsDigit then
          State:= 7
        else
          Break;
      7:                                    {Ali_Mohebbi}
        if Text[p].IsDigit then
          State:= 7
        else
          Break;
    end;

  Result:= State in [2, 4, 7];
  if Result then NewPos:= p;
end;

function TSyntaxLine.IsSep(Sep: string): Boolean;     {Ali_Mohebbi}
begin
  SkipUnread;

  Result:= Copy(Text, Pos, Sep.Length).ToUpper= Sep.ToUpper;

  if Result then
    NewPos:= Pos+ Sep.Length;
end;

function TSyntaxLine.IsStr: Boolean;      {Ali_Mohebbi}
var
  p, State: Integer;
begin
  SkipUnread;
  State:= 0;

  for p:= Pos to High(Text) do
    case State of                        {Ali_Mohebbi}
      0:
        if Text[p]= '''' then
          State:= 1
        else if Text[p]= '#' then
          State:= 3
        else
          Break;
      1:                                 {Ali_Mohebbi}
        if Text[p]= '''' then
          State:= 2
        else if Text[p] in [#10, #13] then
          Break
        else
          State:= 1;
      2:                                 {Ali_Mohebbi}
        if Text[p]= '''' then
          State:= 1
        else if Text[p]= '#' then
          State:= 3
        else
          Break;
      3:                                 {Ali_Mohebbi}
        if Text[p].IsDigit then
          State:= 4
        else
          Break;
      4:                                 {Ali_Mohebbi}
        if Text[p]= '''' then
          State:= 1
        else if Text[p]= '#' then
          State:= 3
        else if Text[p].IsDigit then
          State:= 4
        else
          Break;
    end;

  Result:= State in [2, 4];
  if Result then NewPos:= p;
end;

{Ali_Mohebbi}
function TSyntaxLine.IsUnread: Boolean;
var
  p, State: Integer;
begin
//  SkipUnread;
  State:= 0;
      {Ali_Mohebbi}
  for p:= Pos to High(Text) do
    case State of
      0:
        if Text[p]= '/' then
          State:= 1
        else if Text[p].IsWhiteSpace then
          State:= 5
        else
          Break;
      1:
        if Text[p]= '*' then
          State:= 2
        else if Text[p]= '/' then
          State:= 6
        else
          Break;
      2:      {Ali_Mohebbi}
        if Text[p]= '*' then
          State:= 3
        else
          State:= 2;
      3:      {Ali_Mohebbi}
        if Text[p]= '*' then
          State:= 3
        else if Text[p]= '/' then
          State:= 4
        else
          State:= 2;
      4:
        Break;
      5:
        if Text[p].IsWhiteSpace then
          State:= 5
        else
          Break;
      6:
        if Text[p] in [#10, #13] then
          State:= 7
        else
          State:= 6;
      7:
        Break;
    end;
      {Ali_Mohebbi}
  Result:= State in [4, 5, 7];
  if Result then NewPos:= p;
end;

{Ali_Mohebbi}
function TSyntaxLine.JumpTo(APos: Integer): string;
begin
  Result:= '';
  while Pos< APos do
  begin
    Result:= Result+ Text[Pos];
    if Text[Pos]= #10 then
    begin
      Inc(Loc.X);
      Loc.Y:= 1;
    end
    else
      Inc(Loc.Y);
    Inc(Pos);
  end;
end;
     {Ali_Mohebbi}
procedure TSyntaxLine.LoadFile(FName: string);
begin
  Clear;
  Text:= TFile.ReadAllText(Fname) + EofCh;
end;
function TSyntaxLine.NewTemp: string;                  {Ali_Mohebbi}
begin
  Inc(TempNo);
  Result:= 'T'+ TempNo.ToString;
end;

{Ali_Mohebbi}
procedure TSyntaxLine.SetText(L: string);
begin
  Clear;
  Text:= L+ EofCh;
end;
function TSyntaxLine.Skip(Any: string): string;        {Ali_Mohebbi}
var
  T: string;
begin
  T:= Any.ToUpper;
  if T= '#ID' then
    Result:= SkipId
  else if T= '#INT' then
    Result:= SkipInt.ToString
  else if T= '#DATE' then
    Result:= SkipDate
  else if T= '#NUM' then
    Result:= SkipNum.ToString
  else if T= '#STRQUOT' then
    Result:= SkipStrQuot
  else if T= '#STRVAL' then
    Result:= SkipStrVal
  else if (Any.Length>= 2) and (Any[1]= '$') then
    Result:= SkipKey(Copy(Any, 2))
  else
    Result:= SkipSep(Any);
end;

procedure TSyntaxLine.SkipAssign;                  {Ali_Mohebbi}
begin
  DoAction(saId, SkipId);
  SkipSep(':=');
  SkipExp;
  DoAction(saCopy, ':=');
end;


function TSyntaxLine.SkipCodes: TCodeList;        {Ali_Mohebbi}
begin
  Codes:= nil;
  TempNo:= 0;
  SkipStatement;
  Result:= Codes;
end;

function TSyntaxLine.SkipDepth: Integer;   {Ali_Mohebbi}

  procedure SkipS; forward;
  procedure SkipL; forward;
  procedure SkipL1; forward;

type
  TSemanticStack= TStackRec<Integer>;
  TSemanticAction= (saZero, saInc, saMax);

var
  SS: TSemanticStack;

  procedure DoAction(Act: TSemanticAction);       {Ali_Mohebbi}
  begin
    case Act of
      saZero:
        SS.Push(0);
      saInc:
        SS.Push(SS.Pop+ 1);
      saMax:
        SS.Push(Max(SS.Pop, SS.Pop));
    end;
  end;

  procedure SkipS;                                {Ali_Mohebbi}
  begin
    case WhichIs(['(', 'a']) of
      0:
        begin
          Skip('(');
          SkipL;
          Skip(')');
          DoAction(saInc);
        end;
      1:
        begin
          Skip('a');
          DoAction(saZero);
        end;
    else
      SyntaxError('" (, a" expected');
    end;
  end;

  procedure SkipL;
  begin
    SkipS;
    SkipL1;
  end;

  procedure SkipL1;
  begin
    if IsNext(',') then
    begin
      Skip(',');
      SkipS;
      DoAction(saMax);
      SkipL1;
    end
    else
      { null };
  end;

begin                                      {Ali_Mohebbi}
  SkipS;
  Result:= SS.Pop;
end;

procedure TSyntaxLine.SkipExp;

  procedure SkipC; forward;
  procedure SkipC1; forward;
  procedure SkipA; forward;
  procedure SkipA1; forward;
  procedure SkipM; forward;
  procedure SkipM1; forward;
  procedure SkipP; forward;

  procedure SkipC;             {Ali_Mohebbi}
  begin
    SkipA;
    SkipC1;
  end;

  procedure SkipC1;            {Ali_Mohebbi}
  begin
    case WhichIs(['<=', '<>', '>=', '<', '=', '>']) of
      0:
        begin
          SkipSep('<=');
          SkipA;
          DoAction(saLessEq, '<=');
        end;
      1:
        begin
          SkipSep('<>');
          SkipA;
          DoAction(saNotEq, '<>');
        end;
      2:
        begin
          SkipSep('>=');
          SkipA;
          DoAction(saGreatEq, '>=');
        end;
      3:                                 {Ali_Mohebbi}
        begin
          SkipSep('<');
          SkipA;
          DoAction(saLess, '<');
        end;
      4:                                 {Ali_Mohebbi}
        begin
          SkipSep('=');
          SkipA;
          DoAction(saEqual, '=');
        end;
      5:                                 {Ali_Mohebbi}
        begin
          SkipSep('>');
          SkipA;
          DoAction(saGreat, '>');
        end;
    else
      { null };
    end;
  end;

  procedure SkipA;                      {Ali_Mohebbi}
  begin
    SkipM;
    SkipA1;
  end;

  procedure SkipA1;                       {Ali_Mohebbi}
  begin
    case WhichIs(['+', '-', '$or']) of
      0:                                  {Ali_Mohebbi}
        begin
          SkipSep('+');
          SkipM;
          DoAction(saAdd, '+');
          SkipA1;
        end;
      1:                                  {Ali_Mohebbi}
        begin
          SkipSep('-');
          SkipM;
          DoAction(saSub, '-');
          SkipA1;
        end;
      2:                                  {Ali_Mohebbi}
        begin
          SkipKey('or');
          SkipM;
          DoAction(saOr, 'or');
          SkipA1;
        end;
    else
      { null };
    end;
  end;

  procedure SkipM;                          {Ali_Mohebbi}
  begin
    SkipP;
    SkipM1;
  end;

  procedure SkipM1;                         {Ali_Mohebbi}
  begin
    case WhichIs(['*', '/', '$and']) of
      0:
        begin                               {Ali_Mohebbi}
          SkipSep('*');
          SkipP;
          DoAction(saMul, '*');
          SkipM1;
        end;
      1:                                    {Ali_Mohebbi}
        begin
          SkipSep('/');
          SkipP;
          DoAction(saDiv, '/');
          SkipM1;
        end;
      2:                                    {Ali_Mohebbi}
        begin
          SkipKey('and');
          SkipP;
          DoAction(saAnd, 'and');
          SkipM1;
        end;
    else
      { null };
    end;
  end;

  procedure SkipP;                                   {Ali_Mohebbi}
  begin
    case WhichIs(['-', 'not', '(', '#id', '#num', '#str']) of
      0:                                             {Ali_Mohebbi}
        begin
          SkipSep('-');
          SkipP;
          DoAction(saNeg, 'neg');
        end;
      1:                                             {Ali_Mohebbi}
        begin
          SkipKey('not');
          SkipP;
          DoAction(saNot, 'not');
        end;
      2:                                             {Ali_Mohebbi}
        begin
          SkipSep('(');
          SkipC;
          SkipSep(')');
        end;
      3: DoAction(saId, SkipId);                     {Ali_Mohebbi}
      4: DoAction(saNum, SkipNum.ToString);          {Ali_Mohebbi}
      5: DoAction(saStr, SkipStrQuot);               {Ali_Mohebbi}
    else
      SyntaxError('"-, not, (, id, num, str expected"');
    end;
  end;

begin
  SkipC;
end;

function TSyntaxLine.SkipExpVal: Double;      {Ali_Mohebbi}

  procedure SkipA; forward;
  procedure SkipA1; forward;
  procedure SkipM; forward;
  procedure SkipM1; forward;
  procedure SkipP; forward;

type
  TSemanticStack = TStackRec<Double>;
  TSemanticAction = (saAdd, saSub, saMul, saDiv, saNeg, saNum);

var
  SS: TSemanticStack;

  procedure DoAction(Act: TSemanticAction; TokenVal: Double = 0);    {Ali_Mohebbi}
  var
    L, R: Double;
  begin
    case Act of
      saAdd:
        SS.Push(SS.Pop + SS.Pop);
      saSub:
        begin
          R := SS.Pop;
          L := SS.Pop;
          SS.Push(L - R);
        end;
      saMul:
        SS.Push(SS.Pop * SS.Pop);
      saDiv:
        begin
          R := SS.Pop;
          L := SS.Pop;
          SS.Push(L / R);
        end;
      saNeg:
        SS.Push(-SS.Pop);
      saNum:
        SS.Push(TokenVal);
    end;
  end;


  procedure SkipA;                            {Ali_Mohebbi}
  begin
    SkipM;
    SkipA1;
  end;

  procedure SkipA1;                           {Ali_Mohebbi}
  begin
    if IsSep('+') then
    begin
      Skip('+');
      SkipM;
      DoAction(saAdd);
      SkipA1;
    end
    else if IsSep('-') then
    begin
      Skip('-');
      SkipM;
      DoAction(saSub);
      SkipA1;
    end
    else
      { null };
  end;

  procedure SkipM;                            {Ali_Mohebbi}
  begin
    SkipP;
    SkipM1;
  end;

  procedure SkipM1;                           {Ali_Mohebbi}
  begin
    if IsSep('*') then
    begin
      Skip('*');
      SkipP;
      DoAction(saMul);
      SkipM1;
    end
    else if IsSep('/') then
    begin
      Skip('/');
      SkipP;
      DoAction(saDiv);
      SkipM1;
    end
    else
      { null }
  end;

  procedure SkipP;                            {Ali_Mohebbi}
  begin
    case WhichIs(['-', '(', '#num']) of
      0:
        begin
          Skip('-');
          SkipP;
          DoAction(saNeg);
        end;
      1:
        begin
          Skip('(');
          SkipA;
          Skip(')');
        end;
      2:
        DoAction(saNum, SkipNum)
    else
      SyntaxError('"- , ( , num expected"');
    end;
  end;

begin                                      {Ali_Mohebbi}
  SkipA;
  Result:= SS.Pop;
end;

procedure TSyntaxLine.SkipFor;                {Ali_Mohebbi}
begin
  SkipKey('for');
  DoAction(saId, SkipId);
  SkipSep(':=');
  SkipExp;
  SkipKey('to');
  DoAction(saToFor);
  SkipExp;
  SkipSep('do');
  DoAction(saDoFor);
  SkipStatement;
  DoAction(saEndFor);
end;


function TSyntaxLine.SkipId: string;       {Ali_Mohebbi}
begin
  if IsId then
    Result:= JumpTo(NewPos)
  else
    SyntaxError('Invalid id');
end;

procedure TSyntaxLine.SkipIf;                   {Ali_Mohebbi}

  procedure SkipIf1;
  begin
    if IsKey('else') then
    begin
      SkipKey('else');
      DoAction(saElse);
      SkipStatement;
      DoAction(saTarget);
    end
    else { null }
      DoAction(saTarget);
  end;

begin
  SkipKey('if');
  SkipExp;
  SkipKey('then');
  DoAction(saThen);
  SkipStatement;
  SkipIf1;
end;


function TSyntaxLine.SkipInt: Integer;
begin
  if IsInt then                              {Ali_Mohebbi}
    Result:= JumpTo(NewPos).ToInteger
  else
    SyntaxError('Invalid integer');
end;

function TSyntaxLine.SkipDate: string;
begin
  if IsDate then
    Result:= JumpTo(NewPos)
  else
    SyntaxError('Invalid date');
end;

function TSyntaxLine.SkipKey(Key: string): string;       {Ali_Mohebbi}
begin
  if IsKey(Key) then
    Result:= JumpTo(NewPos)
  else
    SyntaxError('"'+ Key+ '" Expected');
end;

function TSyntaxLine.SkipNum: Double;        {Ali_Mohebbi}
begin
  if IsNum then
    Result:= JumpTo(NewPos).ToDouble
  else
    SyntaxError('Invalid number');
end;

function TSyntaxLine.SkipSep(Sep: string): string;           {Ali_Mohebbi}
begin
  if IsSep(Sep) then
    Result:= JumpTo(NewPos)
  else
    SyntaxError('"'+ Sep+ '" Expected');
end;

function TSyntaxLine.SkipSPNV: string;      {Ali_Mohebbi}

  procedure SkipS; forward;
  procedure SkipP; forward;
  procedure SkipN; forward;
  procedure SkipV; forward;

  procedure SkipS;
  begin
    case WhichIs(['d', 'e', 'b', 'c']) of
      0, 1:                              {Ali_Mohebbi}
        begin
          SkipP;
          Result:= Result+ Skip('a');
          SkipN;
        end;
      2:                                 {Ali_Mohebbi}
        begin
          SkipV;
          SkipP;
        end;
      3:                                 {Ali_Mohebbi}
        Result:= Result+ Skip('c');
    else
      SyntaxError('"d, e, b, c" Expected')
    end;
  end;

  procedure SkipP;                  {Ali_Mohebbi}
  begin
    case WhichIs(['d', 'e']) of
      0:
        begin
          Result:= Result + Skip('d');
          SkipN;
          SkipP;
        end;
      1:
        Result:= Result + Skip('e');
    else
      SyntaxError('"d, e" Expected')
    end;
  end;

  procedure SkipN;                  {Ali_Mohebbi}
  begin
    case WhichIs(['b', 'd', 'e', EofCh]) of
      0:
        begin
          SkipV;
          Result:= Result + Skip('a');
        end;
      1..3:
        { null };
    else
      SyntaxError('"b, d, e, Eof" Expected')
    end;
  end;

  procedure SkipV;                  {Ali_Mohebbi}
  begin
    Result:= Result+ Skip('b');
  end;

begin
  Result:= '';
  SkipS;
end;

procedure TSyntaxLine.SkipStatement;        {Ali_Mohebbi}
begin
  case WhichIs(['$if', '$while', '$for', '#id']) of
    0:
      SkipIf;
    1:
      SkipWhile;
    2:
      SkipFor;
    3:
      SkipAssign;
  else
    SyntaxError('Statement expected: if , while, for, id');
  end;
end;


function TSyntaxLine.SkipStrQuot: string;   {Ali_Mohebbi}
begin
  if IsStr then
    Result:= JumpTo(NewPos)
  else
    SyntaxError('Invalid string');
end;

function TSyntaxLine.SkipStrVal: string;     {Ali_Mohebbi}
begin
  { TODO : For Future }
end;

function TSyntaxLine.SkipSXY: string;       {Ali_Mohebbi}

  procedure SkipS; forward;
  procedure SkipX; forward;
  procedure SkipY; forward;

  procedure SkipS;                          {Ali_Mohebbi}
  begin
    SkipX;
    Result:= Result+ Skip('d');
    SkipY;
  end;
                                            {Ali_Mohebbi}
  procedure SkipX;
  begin
    if IsNext('a') then
    begin
      Result:= Result + Skip('a');
      SkipX;
    end
    else
      { null };
  end;

  procedure SkipY;                          {Ali_Mohebbi}
  begin
    if IsNext('b') then
    begin
      Result:= Result + Skip('b');
      SkipY;
      SkipS;
    end
    else
      { null };
  end;
begin                                      {Ali_Mohebbi}
  Result:= '';
  SkipS;
end;

function TSyntaxLine.SkipUnread: string;
begin
  Result:= '';
  while IsUnread do                          {Ali_Mohebbi}
    Result:= Result+ JumpTo(NewPos);
end;

procedure TSyntaxLine.SkipWhile;             {Ali_Mohebbi}
begin
  SkipKey('while');
  DoAction(saLabel);
  SkipExp;
  SkipKey('do');
  DoAction(saDoWhile);
  SkipStatement;
  DoAction(saEndWhile);
end;


{Ali_Mohebbi}
procedure TSyntaxLine.SyntaxError(Msg: string);
var
  Pt, Ln, Ch: string;
begin
  Ln:= 'Line = '+ CurrentLine;
  Ch:= 'Ch = '+ Text[Pos];
  Pt:= 'Loc = ('+ Loc.X.ToString+ ' , '+ Loc.Y.ToString+ ')';
  MessageDlg(Msg+ #10#10+ Ln+ #10+ Ch+ #10+ Pt, mtError, [mbOK], 0);
  Abort;
end;
function TSyntaxLine.WhichIs(L: TStrList): Integer;       {Ali_Mohebbi}
var
  i: Integer;
begin
  SkipUnread;

  Result:= -1;
  for i:= 0 to High(L) do
    if IsNext(L[i]) then
      Exit(i);
end;

{Ali_Mohebbi}
{ TStackRec<T> }

class operator TStackRec<T>.Finalize(var Dest: TStackRec<T>);
begin
  Dest.Stk.Free;
end;

class operator TStackRec<T>.Initialize(out Dest: TStackRec<T>);
begin
  Dest.Stk:= TStack<T>.Create;
end;

function TStackRec<T>.Peek: T;
begin
  Result:= Stk.Peek;
end;

function TStackRec<T>.Pop: T;
begin
  Result:= Stk.Pop;
end;

procedure TStackRec<T>.Push(const Value: T);
begin
  Stk.Push(Value);
end;

{ HCodeList }

function HCodeList.Add(Op, Addr1, Addr2, Target: String): Integer;     {Ali_Mohebbi}
var
  ACode: TCode;
begin
  ACode.Op := Op;
  ACode.Addr1 := Addr1;
  ACode.Addr2 := Addr2;
  ACode.Target := Target;

  Self := Self + [ACode];
  Result := High(Self);
end;


function HCodeList.ToLines: TStrList;                                  {Ali_Mohebbi}
var
  i: Integer;
  S: String;
begin
  for i := 0 to High(Self) do
  begin
    S := string.Join(', ', [Self[i].Op, Self[i].Addr1, Self[i].Addr2, Self[i].Target]);
    Result := Result + ['[' + FormatFloat('00', i) + '] ' + '(' + S + ')'];
  end;
end;


end.
