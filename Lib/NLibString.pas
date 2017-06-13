unit NLibString;


interface

uses System.Classes, System.SysUtils;

  { Search SubStr in S }
  function NPosIC(const SubStr: string; const S: String; StartPos: integer = 0): Integer;
  function NPosRev(const SubStr: string; const S: string; StartPos: integer = 0): integer;
  function NPosRevIC(const SubStr: string; const S: string; StartPos: integer = 0): integer;

  { Get Left/Right/Center string after searching SubStr in S }
  function NLeftOfPos(const SubStr: String; const S: String): String;
  function NLeftOfPosIC(const SubStr: String; const S: String): String;
  function NLeftOfPosRev(const SubStr: String; const S: String): String;
  function NLeftOfPosRevIC(const SubStr: String; const S: String): String;

//  function NLeftOfChars(const AChars: TCharSet; const S: String): string;

  function NLeftOfPosP(const SubStr: string; var S: String; IgnoreSubStrAtStart: Boolean = True): string;
  function NLeftOfPosICP(const SubStr: string; var S: String; IgnoreSubStrAtStart: Boolean = True): string;

  function NRightOfPos(const SubStr: String; const S: String): String;
  function NRightOfPosIC(const SubStr: String; const S: String): String;
  function NRightOfPosRev(const SubStr: String; const S: String): String;
  function NRightOfPosRevIC(const SubStr: String; const S: String): String;
  //function NRightOfChars(const AChars: TCharSet; const S: String): string;

//  function NCenterBetweenChars(const AChars: TCharSet; const S: String): string;

  { Eliminate string }
  function NEliminateChars(const ARemoveChars: TSysCharSet; const S: String): String;


  function NPosOfComment(ALine: String): Integer;         // Return comment start position. If 1 then full line comment
  function NTruncComment(ALine: String): String;          // Return comment start position. If 1 then full line comment

  { Padding, Quote, Length-Trim }
  function NStrOfLength(const S: String; const WantedLength: Integer; AFillChar: Char = ' '; FillToTail: Boolean = true): String;

  function NQuoteSide(const S: String; AQuoteChar: char = ''''): String;
  function NDeQuoteSide(S: String; AQuoteChar: char = ''''): String;

  { Procedure version of string library }
  function NConcat(const S, AddValue, ADelim: String): String;
  procedure NConcatP(var S: String; const AddValue, ADelim: String);

  function NCountOfChar(const AChar: Char; const S: String): Integer;
  function NCountOfChars(const AChars: TSysCharSet; const S: String): Integer;


  { Investigate string chars }
  function NIsNumberOnly(S: String): Boolean;

  procedure NExtractStrings(const DelimStr: string; S: string; AStrings: TStrings; TrimWord: boolean = True; IgnoreDelimAtStart: boolean = True);


  function NExtractFileNameWithoutExt(f: String): String;

  function IsInArray(v: Integer; Values: Array of Integer): Boolean;

  function StrToHex(S: String): String; overload;
  function StrToHex(S: AnsiString): String; overload;

  function ConcatStr(Strings: array of string; ADelimiter: string = '/'; AIgnoreEmpty: boolean = True): string;


  { Boolean type conversion }
  function StringToBool(ABoolStr: string): Boolean;
  function StringToBoolDef(ABoolStr: string; ADefValue: Boolean): Boolean;
  function BooleanToStr(AValue: Boolean; ATrueFalseValues: Array of String): string; overload;
  function BooleanToStr(AValue: Boolean): string; overload;

  function MaskString(AData: String; AMaskChar: Char = '*'; ADivCount: Integer = 4; ADivDelim: String = '-'): String; overload;
  function MaskString(AData: String; AFirstShowDigit, ALastShowDigit: Integer; AMaskChar: Char = '*'): String; overload;


const
  KTOKEN_FULLLINE_COMMENTS: Array[0..2] of String = ('#', '--', '//');
  KTOKEN_INLINE_COMMENTS: Array[0..2] of String = (' #', ' --', ' //');

  BooleanStrings: Array[0..5] of String = ('Y', 'N', 'Yes', 'No', 'True', 'False');
  BooleanStringsTrue: Array[0..2] of String = ('Y', 'Yes', 'True');
  BooleanStringsFalse: Array[0..2] of String = ('N', 'No', 'False');

implementation

uses System.StrUtils, System.AnsiStrings;

function ConcatStr(Strings: array of string; ADelimiter: string = '/'; AIgnoreEmpty: boolean = True): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to High(Strings) do begin
    if (Strings[i] = '') and AIgnoreEmpty then
      Continue;
    if Result <> '' then
      Result := Result + ADelimiter;
    Result := Result + trim(Strings[i]);
  end;
end;


function StrToHex(S: String): String;
var
  i: Integer;
begin
  result := '';
  for i:=1 to Length(S) do
    result := result + IntToHex(Ord(S[i]), 2) + ' ';
  result := trim(result);
end;

function StrToHex(S: AnsiString): String;
var
  i: Integer;
begin
  result := '';
  for i:=1 to Length(S) do
    result := result + IntToHex(Ord(S[i]), 2) + ' ';
  result := trim(result);
end;

function IsInArray(v: Integer; Values: Array of Integer): Boolean;
var
  i: Integer;
begin
  for i in Values do
    if v = i then
      Exit(true);
  Exit(false);
end;

function NCountOfChar(const AChar: Char; const S: String): Integer;
var
  i: integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
    if s[i] = AChar then
      Inc(Result);
end;

function NCountOfChars(const AChars: TSysCharSet; const S: String): Integer;
var
  i: integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
    if CharInSet(s[i], AChars) then
      Inc(Result);
end;



function NIsNumberOnly(S: String): Boolean;
var
  i: Integer;
begin
  result := false;
  for i:=1 to Length(s) do begin
    if not (CharInSet(s[1], ['0'..'9', ',', '.'])) then
      Exit;
  end;
  result := true;
end;


function NLeftOfPos(const SubStr: String; const S: String): String;
var
  p: integer;
begin
  p := Pos(SubStr, S);
  if p = 0 then
    Result := S
  else
    Result := Copy(S, 1, p - 1);
end;

function NLeftOfPosIC(const SubStr: String; const S: String): String;
var
  p: integer;
begin
  p := Pos(Uppercase(SubStr), Uppercase(S));
  if p = 0 then
    Result := S
  else
    Result := Copy(S, 1, p - 1);
end;

{-------------------------------------------------------------------------------
*BeforeRev
 This function Kscans a string from the right and returns the portion of the
 string before SubStr.
 Example: BeforeRev('.','c:\my.file.txt') > 'c:\my.file'
 Example: BeforeRev('[','c:\my.file.txt') > 'c:\my.file.txt'
See also Before, AfterRev
-------------------------------------------------------------------------------}
function NLeftOfPosRev(const SubStr: String; const S: String): String;
var
  p: integer;
begin
  p := NPosRev(SubStr, S);
  if p = 0 then
    Result := S
  else
    Result := Copy(S, 1, p - 1);
end;

function NLeftOfPosRevIC(const SubStr: String; const S: String): String;
var
  p: integer;
begin
  p := NPosRevIC(SubStr, S);
  if p = 0 then
    Result := S
  else
    Result := Copy(S, 1, p - 1);
end;


function NRightOfPos(const SubStr: String; const S: String): String;
var
  p: integer;
begin
  p := Pos(SubStr, S);
  if p = 0 then
    Result := S
  else
    Result := Copy(S, p + Length(SubStr), Length(S));
end;

function NRightOfPosIC(const SubStr: String; const S: String): String;
var
  p: integer;
begin
  p := Pos(Uppercase(SubStr), Uppercase(S));
  if p = 0 then
    Result := S
  else
    Result := Copy(S, p + Length(SubStr), Length(S));
end;

{-------------------------------------------------------------------------------
*BeforeRev
 This function Kscans a string from the right and returns the portion of the
 string before SubStr.
 Example: BeforeRev('.','c:\my.file.txt') > 'c:\my.file'
 Example: BeforeRev('[','c:\my.file.txt') > 'c:\my.file.txt'
See also Before, AfterRev
-------------------------------------------------------------------------------}
function NRightOfPosRev(const SubStr: String; const S: String): String;
var
  p: integer;
begin
  p := NPosRev(SubStr, S);
  if p = 0 then
    Result := S
  else
    Result := Copy(S, p + Length(SubStr), Length(S));
end;

function NRightOfPosRevIC(const SubStr: String; const S: String): String;
var
  p: integer;
begin
  p := NPosRevIC(SubStr, S);
  if p = 0 then
    Result := S
  else
    Result := Copy(S, p + Length(SubStr), Length(S));
end;








function NPosIC(const SubStr: string; const S: String; StartPos: Integer = 0): Integer;
begin
  if StartPos < 2 then
    result := Pos(Uppercase(SubStr), Uppercase(S))
  else
    result := PosEx(Uppercase(SubStr), Uppercase(S), StartPos);
end;

function NPosRevIC(const SubStr: string; const S: string; StartPos: Integer = 0): Integer;
begin
  result := NPosRev(Uppercase(SubStr), Uppercase(S), StartPos);
end;

{-------------------------------------------------------------------------------
* PosRev - Find SubStr in S from backwards.
Use optional StartPos to specify position to start scan backwards from.
If StartPos is not specified then it will start at the end (length) of s.

Example:  PosRev('the','the man there') > 9
          PosRev('the','the man there',5) > 1
-------------------------------------------------------------------------------}
function NPosRev(const SubStr: string; const S: string; StartPos: integer = 0): integer;
var
  SubLen: integer;
  SLen:   integer;
  Match:  boolean;
  i, j:   integer;
  si:     integer;
  c1:     char;
begin
  Result := 0;
  SubLen := Length(SubStr);
  if SubLen = 0 then
    Exit;
  SLen := Length(s);
  if (StartPos < 1) or (StartPos > SLen) then
    StartPos := SLen;
  if SubLen > StartPos then
    Exit;
  c1 := SubStr[1];
  for i := StartPos downto 1 do begin
    if s[i] = c1 then begin
      Match := True;
      si    := i;
      for j := 2 to SubLen do begin
        Inc(si);
        if si > SLen then
          Match := False
        else if s[si] <> SubStr[j] then
          Match := False;
        if Match = False then
          Break;
      end;
      if Match = True then begin
        Result := i;
        Break;
      end;
    end;
  end;
end;


function NExtractFileNameWithoutExt(f: string): string;
begin
  result := ChangeFileExt(ExtractFileName(f), '');
end;

function NConcat(const S, AddValue, ADelim: String): String;
begin
  if S = '' then
    Result := AddValue
  else begin
    if AddValue <> '' then
      Result := S + ADelim + AddValue
    else
      result := S;
  end;
end;

procedure NConcatP(var S: String; const AddValue, ADelim: string);
begin
  if S = '' then
    S := AddValue
  else begin
    if AddValue <> '' then
      S := S + ADelim + AddValue;
  end;
end;

function NStrOfLength(const S: String; const WantedLength: Integer; AFillChar: Char = ' '; FillToTail: Boolean = true): String;
begin
  if Length(S) < WantedLength then begin
    if FillToTail then
      result := S + StringOfChar(AFillChar, WantedLength - Length(S))
    else
      result := StringOfChar(AFillChar, WantedLength - Length(S)) + S;
  end
  else if Length(S) > WantedLength then
    result := Copy(S, 1, WantedLength)
  else
    result := S;
end;

function NPosOfComment(ALine: String): Integer; // Return comment start position. If 1 then full line comment

  function _IsStartWith(ACommentTokens: Array of String): Boolean;
  var
    ii: Integer;
  begin
    result := false;
    for ii := Low(ACommentTokens) to High(ACommentTokens) do begin
      result := StartsText(ACommentTokens[ii], ALine);
      if result then
        exit;
    end;
  end;

  function _IsInLine(ACommentTokens: Array of String): Integer;
  var
    ii: Integer;
  begin
    result := 0;
    for ii := Low(ACommentTokens) to High(ACommentTokens) do begin
      result := Pos(ACommentTokens[ii], ALine);
      if result > 0 then
        exit;
    end;
  end;

begin
  // Full comment line
  if _IsStartWith(KTOKEN_FULLLINE_COMMENTS) then begin
    result := 1;
    Exit;
  end;
  // Include comment Portion in given line
  result := _IsInLine(KTOKEN_INLINE_COMMENTS);
end;


function NTruncComment(ALine: String): String;   // Return comment start position. If 1 then full line comment
var
  AIdx: Integer;
begin
  AIdx := NPosOfComment(ALine);
  if AIdx > 0 then
    result :=Copy(ALine, 1, AIdx-1)
  else
    result := ALine;
end;

function NLeftOfPosP(const SubStr: string; var S: String; IgnoreSubStrAtStart: Boolean = True): string;
var
  p: integer;
begin
  p := Pos(SubStr, S);
  if p = 1 then
    if IgnoreSubStrAtStart then begin
      S := Copy(S, p + Length(SubStr), Length(s));
      p := Pos(SubStr, S);
    end;
  if p = 0 then begin
    Result := S;
    S := '';
    Exit;
  end;
  Result := Copy(S, 1, p - 1);
  S := Copy(S, p + Length(SubStr), Length(S));
end;

function NLeftOfPosICP(const SubStr: string; var S: String; IgnoreSubStrAtStart: Boolean = True): string;
var
  p: integer;
begin
  p := Pos(UpperCase(SubStr), UpperCase(S));
  if p = 1 then
    if IgnoreSubStrAtStart then begin
      S := Copy(S, p + Length(SubStr), Length(s));
      p := Pos(UpperCase(SubStr), UpperCase(S));
    end;
  if p = 0 then begin
    Result := S;
    S := '';
    Exit;
  end;
  Result := Copy(S, 1, p - 1);
  S := Copy(S, p + Length(SubStr), Length(S));
end;

procedure NExtractStrings(const DelimStr: String; S: String; AStrings: TStrings; TrimWord: boolean = True; IgnoreDelimAtStart: boolean = True);
var
  i: Integer;
begin
  if Length(DelimStr) < 1 then begin
    if TrimWord then
      AStrings.Add(Trim(S))
    else
      AStrings.Add(S);
  end
  else begin
    if IgnoreDelimAtStart and StartsText(DelimStr, S) then
      S := Copy(S, 2, Length(S));
    if Length(DelimStr) = 1 then begin
      ExtractStrings([DelimStr[1]], [], PWideChar(S), AStrings);
      for i:=0 to AStrings.Count-1 do
        AStrings[i] := Trim(AStrings[i]);
      if IgnoreDelimAtStart then
        for i:=AStrings.Count-1 downto 0 do
          if AStrings[i] = '' then
            AStrings.Delete(i);
    end
    else begin
      while S <> '' do begin
        if TrimWord then
          AStrings.Add(Trim(NLeftOfPosICP(DelimStr, S, IgnoreDelimAtStart)))
        else
          AStrings.Add(NLeftOfPosICP(DelimStr, S, IgnoreDelimAtStart));
      end;
    end;
  end;
end;

function NEliminateChars(Const ARemoveChars: TSysCharSet; Const S: string): string;
var
  i: integer;
  RLen: integer;
begin
  RLen := 0;
  //We first calculate the length to avoid repeated mem allocation
  for i := 1 to Length(s) do begin
    if not (CharInSet(s[i], ARemoveChars)) then
      Inc(Rlen);
  end;
  SetLength(Result, RLen);
  if Rlen = 0 then
    Exit;
  RLen := 0;
  for i := 1 to Length(s) do begin
    if not (CharInSet(s[i], ARemoveChars)) then begin
      Inc(RLen);
      Result[RLen] := s[i];
    end;
  end;
end;
{

function NLeftOfChars(const AChars: TCharSet; const S: String): string;
var
  i, p: integer;
begin
  p := 0;
  Result := '';
  for i := 1 to Length(s) do begin
    if s[i] in AChars then begin
      p := i;
      break;
    end;
  end;
  if p > 0 then
    result := Copy(s, 1, p-1)
  else
    result := S;
end;

function NRightOfChars(const AChars: TCharSet; const S: String): string;
var
  i, p: integer;
begin
  p := 0;
  Result := '';
  for i := 1 to Length(s) do begin
    if s[i] in AChars then begin
      p := i;
      break;
    end;
  end;
  if p > 0 then
    result := Copy(s, 1, p-1)
  else
    result := S;
end;

var
  b: Boolean;
  i: integer;
begin
  b := false;
  Result := '';
  for i:=1 to Length(s) downto 1 do begin
    if not (s[i] in AChars) then begin
      Result := System.Copy(s, 1, i);
      Break;
    end;
  end;
end;
          }


{function NCenterBetweenChars(const AChars: TCharSet; const S: String): string;
begin
  result := NRightOfChars(AChars, NLeftOfChars(AChars, S));
end;
}
function NQuoteSide(const S: String; AQuoteChar: char = ''''): String;
begin
  if (Length(S) > 1) and (S[1] = aQuoteChar) and (S[Length(S)] = aQuoteChar) then
    result := S
  else
    result := AQuoteChar + S + AQuoteChar;
end;

function NDeQuoteSide(S: String; AQuoteChar: char = ''''): String;
begin
  if (Length(S) > 0) and (S[1] = aQuoteChar) then
    S := Copy(S, 2, Length(S));
  if (Length(S) > 0) and (S[Length(S)] = aQuoteChar) then
    S := Copy(S, 1, Length(S)-1);
  result := S;
end;




function StringToBool(ABoolStr: string): Boolean;
begin
  result := IndexText(ABoolStr, BooleanStringsTrue) >= 0;
end;

function StringToBoolDef(ABoolStr: string; ADefValue: Boolean): Boolean;
begin
  if IndexText(ABoolStr, BooleanStrings) >= 0 then
    result := IndexText(ABoolStr, BooleanStringsTrue) >= 0
  else
    result := ADefValue;
end;

function BooleanToStr(AValue: Boolean; ATrueFalseValues: Array of String): string;
begin
  if High(ATrueFalseValues) = 1 then begin
    if AValue then
      result := ATrueFalseValues[0]
    else
      result := ATrueFalseValues[1];
  end
  else
    result := IfThen(AValue, 'True', 'False');
end;

function BooleanToStr(AValue: Boolean): string; overload;
begin
  result := IfThen(AValue, 'True', 'False');
end;



(*
  Mask string.
  :: Input '1234567890123456'
   if ADivCount=1   -> '****************'
   if ADivCount=2   -> '12345678-********'
   if ADivCount=3   -> '12345-******-23456'
   if ADivCount=4   -> '1234-****-****-3456'
*)

function MaskString(AData: String; AMaskChar: Char = '*'; ADivCount: Integer = 4; ADivDelim: String = '-'): String;
var
  AFullLen, ADivLen: Integer;
begin
  if not (ADivCount in [1,2,3,4]) then
    ADivCount := 1;
  AFullLen := Length(AData);
  ADivLen := AFullLen div ADivCount;
  if ADivLen < 1 then
    result := AData
  else begin
    case ADivCount of
      1: result := DupeString(AMaskChar, AFullLen);
      2: result := LeftStr(AData, ADivLen) + ADivDelim + DupeString(AMaskChar, AFullLen - ADivLen);
      3: result := LeftStr(AData, ADivLen) + ADivDelim +
                   DupeString(AMaskChar, AFullLen - (ADivLen * 2)) + ADivDelim +
                   RightStr(AData, ADivLen);
      4: result := LeftStr(AData, ADivLen) + ADivDelim +
                   DupeString(AMaskChar, AFullLen - (ADivLen * 3)) + ADivDelim +
                   DupeString(AMaskChar, ADivLen) + ADivDelim +
                   RightStr(AData, ADivLen);
    end;
  end;
end;

function MaskString(AData: String; AFirstShowDigit, ALastShowDigit: Integer; AMaskChar: Char = '*'): String;
var
  AFullLen: Integer;
begin
  AFullLen := Length(AData);
  if AFullLen > AFirstShowDigit + ALastShowDigit then
    result := LeftStr(AData, AFirstShowDigit) + DupeString(AMaskChar, AFullLen - (AFirstShowDigit + ALastShowDigit)) +
              RightStr(AData, ALastShowDigit)
  else begin
    result := AData;
  end;
end;

end.



