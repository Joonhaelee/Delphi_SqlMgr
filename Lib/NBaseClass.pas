{
@abstrcat ( Basic foundation class definition )
@author   ( Joonhae.lee@gmail.com )
@created  ( 2014.12 )
@lastmod  ( 2014.12 )
}

unit NBaseClass;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections;

type

  { Base ancestor of data class }
  TNData = class(TPersistent)
  private
    fTagObject: TObject;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ResetValues; virtual;
    function Clone(ASource: TPersistent; AResetBeforeCopy: Boolean = false): TNData; virtual;
    procedure PrintDebug(AStrings: TStrings; Indent: String = '  ');
    property TagObject: TObject read fTagObject write fTagObject;
  end;
  TNDataClass = class of TNData;

  { Base ancestor for database data object }
  TNSqlData = class(TNData)
  public
    TotalRecordCount: Integer;
    Page: Integer;
    RecordsPerPage: Integer;
//    FromRec: Integer;
//    RecCount: Integer;
    SortFields: String;
  end;

  { TNList : Conainer for TNData }
  TNList = class(TObjectList<TNData>)
  public
    destructor Destroy; override;
    procedure Clone(ASrc: TNList; AnItemClass: TNDataClass);
    procedure Clear; virtual;
    procedure FreeItems; virtual;
    procedure PrintDebug(AStrings: TStrings; Indent: String = ''); virtual;
    function Find(APropName: String; AValue: Variant): TNData; overload;
  end;

implementation

uses DateUtils, NBaseRtti, NBasePerf, TypInfo;

{ TNData }

constructor TNData.Create;
begin
  inherited create;
  fTagObject := nil;
  TNPerf.Done(format('Class.Counter.%s', [ClassName]));
end;

destructor TNData.Destroy;
begin
  TNPerf.Done(format('Class.Counter.%s', [ClassName]), -1);
  inherited;
end;

procedure TNData.ResetValues;
begin
  TNRtti.ClearObjectFields(Self, true);
end;

function TNData.Clone(ASource: TPersistent; AResetBeforeCopy: Boolean = false): TNData;
begin
  if Self <> ASource then begin
    if ASource = nil then
      ResetValues
    else
      TNRtti.CloneObjectFields(ASource, Self, true, AResetBeforeCopy);
  end;
  Exit(Self);
end;

procedure TNData.PrintDebug(AStrings: TStrings; Indent: String = '  ');
begin
  TNRtti.PrintObjectValues(Self, AStrings, Indent);
end;

{ TNList }

function TNList.Find(APropName: String; AValue: Variant): TNData;
var
  i: Integer;
begin
  result := nil;
  for i:=0 to Count-1 do begin
    if GetPropValue(Items[i], APropName) = AValue then begin
      result := Items[i];
      Exit;
    end;
  end;
end;

procedure TNList.FreeItems;
var
  i: Integer;
begin
  for i:=Count-1 downto 0 do
    Items[i].Free;
  Clear;
end;

procedure TNList.Clear;
begin
  inherited Clear;
end;

procedure TNList.Clone(ASrc: TNList; AnItemClass: TNDataClass);
var
  s, n: TNData;
begin
  Clear;
  if ASrc = nil then
    Exit;
  for s in ASrc do begin
    n := AnItemClass.Create;
    n.Clone(s);
    Add(n);
  end;
end;

destructor TNList.Destroy;
begin
  inherited;
end;

procedure TNList.PrintDebug(AStrings: TStrings; Indent: String = '');
var
  i: Integer;
begin
  for i:=0 to Count-1 do begin
    AStrings.Add(Indent + format('%d''th item: %s', [i, Items[i].ClassName]));
    TNRtti.PrintObjectValues(Items[i], AStrings, Indent + Indent, false);
  end;
end;


end.


