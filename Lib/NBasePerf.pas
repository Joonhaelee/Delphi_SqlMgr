unit NBasePerf;

interface

uses System.Generics.Collections, System.Classes, System.SysUtils;

type

  TNPerfCounter = class
  public
    CounterName: String;    // Performance name. any character
    StartTime: TDateTime;
    ElapsedMS: Single;
    PerformCount: Int64;    // Perform count. It is increased every AddCounter()
    RecordCount: Int64;     // item count. Max 9,223,372,036,854,775,808.
    Dirty: Boolean;
    procedure Start;
    procedure Done(ARecord: Int64 = 1);
  end;

  TNPerf = class(TDictionary<String, TNPerfCounter>)
  private
    fThreadSafe: Boolean;
    procedure _PrintDebug(AStrings: TStrings; ACounterName: String = '');
    procedure _Start(ACounter: String);
    procedure _Done(ACounter: String; ACountValue: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    class procedure PrintDebug(AStrings: TStrings; ACounterName: String = '');
    class procedure Start(ACounter: String);
    class procedure Done(ACounter: String; ACountValue: Integer = 1);
    class procedure SetThreadSafe(Value: Boolean);
  end;

implementation

uses DateUtils, Math;

var
  _GlobalPerf: TNPerf;

function GlobalPerf: TNPerf;
begin
  if _GlobalPerf = nil then
    _GlobalPerf := TNPerf.Create;
  result := _GlobalPerf;
end;

{ TNPerf }

constructor TNPerf.Create;
begin
  inherited Create;
end;

destructor TNPerf.Destroy;
begin
  inherited;
end;

class procedure TNPerf.SetThreadSafe(Value: Boolean);
begin
  GlobalPerf.fThreadSafe := Value;
end;

class procedure TNPerf.Start(ACounter: String);
begin
  GlobalPerf._Start(ACounter);
end;

class procedure TNPerf.Done(ACounter: String; ACountValue: Integer = 1);
begin
  GlobalPerf._Done(ACounter, ACountValue);
end;

class procedure TNPerf.PrintDebug(AStrings: TStrings; ACounterName: String);
begin
  GlobalPerf._PrintDebug(AStrings, ACounterName);
end;

procedure TNPerf._PrintDebug(AStrings: TStrings; ACounterName: String = '');
var
  k: String;
  AStr1, AStr2: String;
begin
  if fThreadSafe then
    TMonitor.Enter(Self);
  try
    for k in Keys do begin
      with Items[k] do begin
        if (ACounterName = '') or SameText(CounterName, ACounterName) then begin

          if RecordCount > 0 then
            AStr1 := formatFloat('#,0', ElapsedMS / RecordCount)
          else
            AStr1 := '?';
          if PerformCount > 0 then
            AStr2 := formatFloat('#,0', ElapsedMS / PerformCount)
          else
            AStr2 := '?';
          AStrings.Add(format('%s : Total performed=%s, elapsed=%s, record=%s. avg per record=%s(ms), avg per perform=%s(ms)',
             [CounterName,
              formatFloat('#,0', PerformCount),
              formatFloat('#,0.000', ElapsedMS),
              formatFloat('#,0', RecordCount),
              AStr1, AStr2]));
        end;
      end;
    end;
  finally
    if fThreadSafe then
      TMonitor.Exit(Self);
  end;
end;

procedure TNPerf._Start(ACounter: String);
var
  p: TNPerfCounter;
begin
  if Self = nil then
    Exit;
  if fThreadSafe then
    TMonitor.Enter(Self);
  try
    if not TryGetValue(ACounter, p) then begin
      p := TNPerfCounter.Create;
      p.CounterName := ACounter;
      Add(ACounter, p);
    end
    else if p.Dirty then
      raise Exception.Create(format('Performance counter "%s" duplicated', [ACounter]));
    p.Start;
  finally
    if fThreadSafe then
      TMonitor.Exit(Self);
  end;
end;

procedure TNPerf._Done(ACounter: String; ACountValue: Integer);
var
  p: TNPerfCounter;
begin
  if Self = nil then
    Exit;
  if fThreadSafe then
    TMonitor.Enter(Self);
  try
    if not TryGetValue(ACounter, p) then begin
      p := TNPerfCounter.Create;
      p.CounterName := ACounter;
      Add(ACounter, p);
    end;
    p.Dirty := false;
    p.Done(ACountValue);
  finally
    if fThreadSafe then
      TMonitor.Exit(Self);
  end;
end;

{ TNPerfCounter }

procedure TNPerfCounter.Done(ARecord: Int64 = 1);
begin
  ElapsedMS := ElapsedMS + MilliSecondsBetween(StartTime, now);
  PerformCount := PerformCount + 1;
  RecordCount := RecordCount + ARecord;
  Dirty := false;
end;

procedure TNPerfCounter.Start;
begin
  StartTime := Now;
  Dirty := true;
end;

end.

