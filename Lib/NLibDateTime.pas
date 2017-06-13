unit NLibDateTime;

interface

uses
  System.Classes, System.SysUtils, System.UITypes, System.UIConsts, System.Types,
  Winapi.Winsock, Winapi.Windows;

  { Datetime type conversion }
  function StringToDateTime(ADateStr: string): TDateTime;
  function TryStringToDate(ADateStr: string; var AOutValue: TDateTime): Boolean;
  function TryStringToTime(ATimeStr: string; var AOutValue: TDateTime): Boolean;
  function TryStringToDateTime(ADateTimeStr: string; var AOutValue: TDateTime): Boolean;
  function TryExpireYYMMToDateTime(AYYMM: string; var AOutValue: TDateTime): Boolean;
  function TryUSMilitary_ToUTCTime(ADateTimeStr: string; var AOutValue: TDateTime): Boolean;
  function TryUSMilitary_ToLocalDateTime(ADateTimeStr: string; var AOutValue: TDateTime): Boolean;
  function TryDateTimeTo_USMilitary_DateTime(ADateTime: TDateTime; var AOutValue: String): Boolean;

  function UTCTimeToLocalTime(v: TDateTime): TDateTime;
  function GetUTCTime: TDateTime; overload;
  function GetUTCTime(v: TDateTime): TDateTime; overload;
  function OffsetFromUTC: TDateTime;
  procedure GetTimeZoneName(var ATZName: String; var AnOffset: TDateTime);


  function GetFullAgeOf(ABirthday: TDateTime): Integer;
  function GetThisYearBirthdayOf(ABirthday: TDateTime): TDateTime;

  function FileTimeToLocalDateTime(filetime: TFileTime): TDatetime;

implementation

uses IOUtils, TypInfo, StrUtils, DateUtils, Math, Registry, NLibString;

function FileTimeToLocalDateTime(filetime: TFileTime ): TDatetime;
var
  LocalFileTime: TFileTime;
  dostime: Longint;
begin
  FileTimeToLocalFileTime(filetime, LocalFileTime);
  if FileTimeToDosDateTime(LocalFileTime, LongRec(dostime).Hi,
                           LongRec(dostime).Lo) then
   result := FiledateToDatetime( dostime )
 else
   result := 0.0;
end;

function GetFullAgeOf(ABirthday: TDateTime): Integer;
var
  ABirthY, ABirthM, ABirthD: Word;
  ANowY, ANowM, ANowD: Word;
begin
  if ABirthday >= now then
    result := 0
  else begin
    DecodeDate(ABirthday, ABirthY, ABirthM, ABirthD);
    DecodeDate(Now, ANowY, ANowM, ANowD);
    if ABirthY < 1900 then
      result := 0
    else if ABirthY = ANowY then
      result := 0
    else begin
      // Birthday is past or not ?
      if (ANowM * 100 + ANowD) < (ABirthM * 100 + ABirthD) then
        Dec(ANowY);
      result := ANowY - ABirthY;
    end;
  end;
end;

function GetThisYearBirthdayOf(ABirthday: TDateTime): TDateTime;
var
  ABirthY, ABirthM, ABirthD: Word;
begin
  if ABirthday < 1 then
    result := 0
  else begin
    DecodeDate(ABirthday, ABirthY, ABirthM, ABirthD);
    result := EncodeDate(YearOf(Now), ABirthM, ABirthD);
  end;
end;

function UTCTimeToLocalTime(v: TDateTime): TDateTime;
begin
  result := TTimeZone.Local.ToLocalTime(v);
end;

function GetUTCTime: TDateTime; overload;
begin
  result := GetUTCTime(now);
end;

function GetUTCTime(v: TDateTime): TDateTime; overload;
begin
  result := TTimeZone.Local.ToUniversalTime(v);
end;

function OffsetFromUTC: TDateTime;
var
  iBias: Integer;
  tmez: TTimeZoneInformation;
begin
  try
    case GetTimeZoneInformation(tmez) of
      TIME_ZONE_ID_INVALID:  raise Exception.Create('System time zone invalid');
      TIME_ZONE_ID_UNKNOWN:  iBias := tmez.Bias;
      TIME_ZONE_ID_DAYLIGHT: iBias := tmez.Bias + tmez.DaylightBias;
      TIME_ZONE_ID_STANDARD: iBias := tmez.Bias + tmez.StandardBias;
      else
        raise Exception.Create('Fail to retrieve system time zone');
    end;
    {We use ABS because EncodeTime will only accept positve values}
    Result := EncodeTime(Abs(iBias) div 60, Abs(iBias) mod 60, 0, 0);
    {The GetTimeZone function returns values oriented towards convertin
     a GMT time into a local time.  We wish to do the do the opposit by returning
     the difference between the local time and GMT.  So I just make a positive
     value negative and leave a negative value as positive}
    if iBias > 0 then begin
      Result := 0 - Result;
    end;
  except
    result := 0;
  end;
end;

procedure GetTimeZoneName(var ATZName: String; var AnOffset: TDateTime);
var
  iBias: Integer;
  tmez: TTimeZoneInformation;
begin
  try
    case GetTimeZoneInformation(tmez) of
      TIME_ZONE_ID_INVALID:
        begin
          ATZName := tmez.StandardName;
          raise Exception.Create('System time zone invalid');
        end;
      TIME_ZONE_ID_UNKNOWN:
        begin
          iBias := tmez.Bias;
          ATZName := tmez.StandardName;
        end;
      TIME_ZONE_ID_DAYLIGHT:
        begin
          iBias := tmez.Bias + tmez.DaylightBias;
          ATZName := tmez.StandardName;
        end;
      TIME_ZONE_ID_STANDARD:
        begin
          iBias := tmez.Bias + tmez.StandardBias;
          ATZName := tmez.StandardName;
        end;
      else begin
        ATZName := 'Unknown';
        raise Exception.Create('Fail to retrieve system time zone');
      end;
    end;
    {We use ABS because EncodeTime will only accept positve values}
    AnOffset := EncodeTime(Abs(iBias) div 60, Abs(iBias) mod 60, 0, 0);
    {The GetTimeZone function returns values oriented towards convertin
     a GMT time into a local time.  We wish to do the do the opposit by returning
     the difference between the local time and GMT.  So I just make a positive
     value negative and leave a negative value as positive}
    if iBias > 0 then begin
      AnOffset := 0 - AnOffset;
    end;
  except
    AnOffset := 0;
  end;
end;

function TryStringToTime(ATimeStr: string; var AOutValue: TDateTime): Boolean;
var
  hh, nn, ss, ms: Integer;
begin
  result := false;
  try
    case Length(ATimeStr) of
      // hhnnss
      6:
      begin
        if TryStrToInt(Copy(ATimeStr, 1, 2), hh) and
           TryStrToInt(Copy(ATimeStr, 3, 2), nn) and
           TryStrToInt(Copy(ATimeStr, 5, 2), ss) then begin
          AOutValue := EncodeTime(hh, nn, ss, 0);
          result := true;
        end;
      end;
      // hh:nn:ss
      8:
      begin
        if TryStrToInt(Copy(ATimeStr, 1, 2), hh) and
           TryStrToInt(Copy(ATimeStr, 4, 2), nn) and
           TryStrToInt(Copy(ATimeStr, 7, 2), ss) then begin
          AOutValue := EncodeTime(hh, nn, ss, 0);
          result := true;
        end;
      end;
      // hhnnsszzz
      9:
      begin
        if TryStrToInt(Copy(ATimeStr, 1, 2), hh) and
           TryStrToInt(Copy(ATimeStr, 3, 2), nn) and
           TryStrToInt(Copy(ATimeStr, 5, 2), ss) and
           TryStrToInt(Copy(ATimeStr, 7, 3), ms) then begin
          AOutValue := EncodeTime(hh, nn, ss, ms);
          result := true;
        end;
      end;
      // hh:nn:ss.zzz
      12:
      begin
        if TryStrToInt(Copy(ATimeStr, 1, 2), hh) and
           TryStrToInt(Copy(ATimeStr, 4, 2), nn) and
           TryStrToInt(Copy(ATimeStr, 7, 2), ss) and
           TryStrToInt(Copy(ATimeStr, 10, 3), ms) then begin
          AOutValue := EncodeTime(hh, nn, ss, ms);
          result := true;
        end;
      end;
    end;
  except
    ;
  end;
end;

// Choose century for "yymmdd".
function _ChoosePrefixCentury(ADateStr: String): String;
var
  AInt, ACurrYear: Integer;
begin
  if TryStrToInt(Copy(ADateStr, 1, 2), AInt) then begin
    ACurrYear := YearOf(Now) - (YearOf(Now) div 100) * 100; // 2008 -> 08
    if AInt <= ACurrYear then
      result := IntToStr((YearOf(Now) div 100))             // if "07" -> return "20"
    else
      result := IntToStr((YearOf(Now) div 100) - 1);        // if "09" -> return "19"
  end;
end;

function TryStringToDate(ADateStr: string; var AOutValue: TDateTime): Boolean;
var
  yy, mm, dd: Integer;
begin
  result := false;
  try
    case Length(ADateStr) of
      // yymmdd
      6:
      begin
        if TryStrToInt(_ChoosePrefixCentury(ADateStr) + Copy(ADateStr, 1, 2), yy) and
           TryStrToInt(Copy(ADateStr, 3, 2), mm) and
           TryStrToInt(Copy(ADateStr, 5, 2), dd) then begin
          AOutValue := EncodeDate(yy, mm ,dd);
          result := true;
        end;
      end;
      // yyyymmdd, yy-mm-dd
      8:
      begin
        if (Pos('-', ADateStr) > 0) or (Pos('/', ADateStr) > 0) then begin
          if TryStrToInt(_ChoosePrefixCentury(ADateStr) + Copy(ADateStr, 1, 2), yy) and
             TryStrToInt(Copy(ADateStr, 4, 2), mm) and
             TryStrToInt(Copy(ADateStr, 7, 2), dd) then begin
              AOutValue := EncodeDate(yy, mm ,dd);
              result := true;
          end;
        end
        else begin
          if TryStrToInt(Copy(ADateStr, 1, 4), yy) and
             TryStrToInt(Copy(ADateStr, 5, 2), mm) and
             TryStrToInt(Copy(ADateStr, 7, 2), dd) then begin
            AOutValue := EncodeDate(yy, mm ,dd);
            result := true;
          end;
        end;
      end;
      // yyyy-mm-dd
      10:
      begin
        if TryStrToInt(Copy(ADateStr, 1, 4), yy) and
           TryStrToInt(Copy(ADateStr, 6, 2), mm) and
           TryStrToInt(Copy(ADateStr, 9, 2), dd) then begin
          AOutValue := EncodeDate(yy, mm ,dd);
          result := true;
        end;
      end;
    end;
  except
    ;
  end;
end;

function TryExpireYYMMToDateTime(AYYMM: string; var AOutValue: TDateTime): Boolean;
var
  yy, mm, dd: Integer;
begin
  if TryStrToInt(Copy(AYYMM, 1, 2), yy) and
     TryStrToInt(Copy(AYYMM, 3, 2), mm) then begin
    AOutValue := EncodeDateTime(2000 + yy, mm, 1, 23, 59, 59, 0);
    dd := DateUtils.DaysInMonth(AOutValue);
    AOutValue := EncodeDateTime(2000 + yy, mm, dd, 23, 59, 59, 0);
    result := true;
  end
  else
    result := false;
end;

const
  //                                       -1                                                    -12
  _UTC_OFFSET_N: Array[0..11] of String = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M');
  //                                       +1                                                    +12
  _UTC_OFFSET_P: Array[0..11] of String = ('N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y');

(* US Millitary date and time must be in the following format: ^.^
  :  12345678901234567890      12345678901234567890123
  : "YYYY-MM-DDTHH:MM:SSZ" or "YYYY-MM-DDTHH:MM:SS.MSZ".

  This is explained in more detail below:
    YYYY Four-digit year, e.g. "2005"
    MM  Two-digit month.
    DD Two-digit day.
    T Indicates time follows the date.
    HH Hours in military time (24-hour format).
    MM  Minutes
    SS Seconds
    MS Milliseconds (Optional)
     ** piney : I don't know the precision of this value exactly. I assumed it as 10 milliseconds
    Z 1-character (US military) representation of the time zone,
      "A" - "M" are negative offsets -1 to -12, with "J" not being used.
      "N" - "Y" are positive offsets 1 to 12, and "Z" indicates GMT/UTC (no offset).

  For instance, "2004-05-26T15:00:00.00Z" is May 26th, 2004 at 3:00pm GMT.
------------------------------------------------------------------------------*)
function TryUSMilitary_ToUTCTime(ADateTimeStr: string; var AOutValue: TDateTime): Boolean;
var
  ATimeZ: String;
begin
  result := false;
  try
    if Pos('T', ADateTimeStr) = 11 then begin
      if Length(ADateTimeStr) = 20 then begin
        result := TryStringToDateTime(Copy(ADateTimeStr, 1, 10) + ' ' +
                                      Copy(ADateTimeStr, 12, 8),
                                      AOutValue);
      end
      else if Length(ADateTimeStr) = 23 then begin
        result := TryStringToDateTime(Copy(ADateTimeStr, 1, 10) + ' ' +
                                      Copy(ADateTimeStr, 12, 11) + '0',
                                      AOutValue);
      end;

      if result then begin
        ATimeZ := ADateTimeStr[Length(ADateTimeStr)];
        if SameText(ATimeZ, 'Z') then begin
          ;
        end
        else if IndexText(ATimeZ, _UTC_OFFSET_N) >= 0 then begin
          AOutValue := AOutValue - (IndexText(ATimeZ, _UTC_OFFSET_N) + 1) / 24;
        end
        else if IndexText(ATimeZ, _UTC_OFFSET_N) >= 0 then begin
          AOutValue := AOutValue + (IndexText(ATimeZ, _UTC_OFFSET_N) + 1) / 24;
        end;
      end;
    end;
  except
  end;
end;

function TryUSMilitary_ToLocalDateTime(ADateTimeStr: string; var AOutValue: TDateTime): Boolean;
var
  AUtcTime: TDateTime;
begin
  result := false;
  if TryUSMilitary_ToUTCTime(ADateTimeStr, AUtcTime) then begin
    AOutValue := AUtcTime + OffsetFromUTC;
    result := true;
  end;
end;

// return as YYYY-MM-DDTHH:NN:SS.FFZ"
function TryDateTimeTo_USMilitary_DateTime(ADateTime: TDateTime; var AOutValue: String): Boolean;
var
  ATimeZ: String;
  AOffsetFromUTC, AUtcTime: TDateTime;
  H, M, S, MS: Word;
begin
  result := false;
  try
    ATimeZ := '';
    AOffsetFromUTC := OffsetFromUTC;
    AUtcTime := ADateTime - AOffsetFromUTC;
    DecodeTime(AOffsetFromUTC, H, M, S, MS);
    if H = 0 then begin
      ATimeZ := 'Z';
    end
    else if H in [1..12] then begin
      if AOffsetFromUTC < 0 then
        ATimeZ := _UTC_OFFSET_N[H-1]
      else
        ATimeZ := _UTC_OFFSET_P[H-1];
    end;
    if ATimeZ <> '' then begin
      AOutValue := formatDateTime('yyyy-mm-ddThh:nn:ss.zz', AUTCTime) + ATimeZ;
      result := true;
    end;
  except
  end;
end;

function TryStringToDateTime(ADateTimeStr: string; var AOutValue: TDateTime): Boolean;
var
  yy, mm, dd, hh, nn, ss, ms: Integer;
begin
  result := false;
  AOutValue := 0;
  yy := 0;
  mm := 0;
  dd := 0;
  hh := 0;
  nn := 0;
  ss := 0;
  ms := 0;
  try
    case Length(ADateTimeStr) of
      // yymmdd -> hhnnss
      // yyyymmdd -> hh:nn:ss
      6,
      8: result := TryStringToDate(ADateTimeStr, AOutValue) or TryStringToTime(ADateTimeStr, AOutValue);
      10: result := TryStringToDate(ADateTimeStr, AOutValue);
      // yyyymmddhhnnss
      14:
      begin
        if TryStrToInt(Copy(ADateTimeStr, 1, 4), yy) and
           TryStrToInt(Copy(ADateTimeStr, 5, 2), mm) and
           TryStrToInt(Copy(ADateTimeStr, 7, 2), dd) and
           TryStrToInt(Copy(ADateTimeStr, 9, 2), hh) and
           TryStrToInt(Copy(ADateTimeStr, 11, 2), nn) and
           TryStrToInt(Copy(ADateTimeStr, 13, 2), ss) then begin
          AOutValue := EncodeDateTime(yy, mm ,dd, hh, nn, ss, 0);
          result := true;
        end;
      end;
      // yyyymmdd hhnnss
      15:
      begin
        if TryStrToInt(Copy(ADateTimeStr, 1, 4), yy) and
           TryStrToInt(Copy(ADateTimeStr, 5, 2), mm) and
           TryStrToInt(Copy(ADateTimeStr, 7, 2), dd) and
           TryStrToInt(Copy(ADateTimeStr, 10, 2), hh) and
           TryStrToInt(Copy(ADateTimeStr, 12, 2), nn) and
           TryStrToInt(Copy(ADateTimeStr, 14, 2), ss) then begin
          AOutValue := EncodeDateTime(yy, mm ,dd, hh, nn, ss, 0);
          result := true;
        end;
      end;
      // yyyymmddhhnnsszzz or yy/mm/dd hh:nn:ss
      17:
      begin
        if (Pos('-', ADateTimeStr) < 1) and (Pos('/', ADateTimeStr) < 1) then begin
          if TryStrToInt(Copy(ADateTimeStr, 1, 4), yy) and
             TryStrToInt(Copy(ADateTimeStr, 5, 2), mm) and
             TryStrToInt(Copy(ADateTimeStr, 7, 2), dd) and
             TryStrToInt(Copy(ADateTimeStr, 9, 2), hh) and
             TryStrToInt(Copy(ADateTimeStr, 11, 2), nn) and
             TryStrToInt(Copy(ADateTimeStr, 13, 2), ss) and
             TryStrToInt(Copy(ADateTimeStr, 15, 3), ms) then begin
            AOutValue := EncodeDateTime(yy, mm ,dd, hh, nn, ss, ms);
            result := true;
          end;
        end
        else begin
          if TryStrToInt(_ChoosePrefixCentury(ADateTimeStr) + Copy(ADateTimeStr, 1, 2), yy) and
             TryStrToInt(Copy(ADateTimeStr, 4, 2), mm) and
             TryStrToInt(Copy(ADateTimeStr, 7, 2), dd) and
             TryStrToInt(Copy(ADateTimeStr, 10, 2), hh) and
             TryStrToInt(Copy(ADateTimeStr, 13, 2), nn) and
             TryStrToInt(Copy(ADateTimeStr, 16, 2), ss) then begin
            AOutValue := EncodeDateTime(yy, mm ,dd, hh, nn, ss, 0);
            result := true;
          end;
        end;
      end;
      // yyyy-mm-dd hh:nn:ss
      19:
      begin
        if TryStrToInt(Copy(ADateTimeStr, 1, 4), yy) and
           TryStrToInt(Copy(ADateTimeStr, 6, 2), mm) and
           TryStrToInt(Copy(ADateTimeStr, 9, 2), dd) and
           TryStrToInt(Copy(ADateTimeStr, 12, 2), hh) and
           TryStrToInt(Copy(ADateTimeStr, 15, 2), nn) and
           TryStrToInt(Copy(ADateTimeStr, 18, 2), ss) then begin
            AOutValue := EncodeDateTime(yy, mm ,dd, hh, nn, ss, 0);
          result := true;
        end;
      end;
      // yyyy-mm-dd hh:nn:ss.zzz
      // 12345678901234567890123
      23:
      begin
        if TryStrToInt(Copy(ADateTimeStr, 1, 4), yy) and
           TryStrToInt(Copy(ADateTimeStr, 6, 2), mm) and
           TryStrToInt(Copy(ADateTimeStr, 9, 2), dd) and
           TryStrToInt(Copy(ADateTimeStr, 12, 2), hh) and
           TryStrToInt(Copy(ADateTimeStr, 15, 2), nn) and
           TryStrToInt(Copy(ADateTimeStr, 18, 2), ss) and
           TryStrToInt(Copy(ADateTimeStr, 21, 3), ms) then begin
          AOutValue := EncodeDateTime(yy, mm ,dd, hh, nn, ss, ms);
          result := true;
        end;
      end;
    end;
  except
    ;
  end;
end;

function StringToDateTime(ADateStr: string): TDateTime;
begin
  if not TryStringToDateTime(ADateStr, result) then
    raise Exception.Create(format('"%s" can not be converted to datetime', [ADateStr]));
end;


end.


