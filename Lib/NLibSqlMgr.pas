{===============================================================================
@abstrcat ( Tyche sql manager )
@author   ( Joonhae.lee@gmail.com )
@created  ( 2014.12 )
@lastmod  ( 2004.12 )

Sql manager and database object container.
Got inspiration from Ibatis framework
===============================================================================}

unit NLibSqlMgr;

interface

uses System.Classes, System.SysUtils, System.SyncObjs, System.TypInfo, System.IOUtils,
  Data.DB, System.Generics.Collections, System.Rtti, System.Variants,
  NBaseRtti,
  NBaseClass;

type

  { Exception }
  ENSqlException = class(Exception);
  ENSqlNotDefined = class(ENSqlException);
  ENSqlClassNotFound = class(ENSqlException);
  ENSqlClassInvalid = class(ENSqlException);
  ENSqlClassCreateError = class(ENSqlException);
  ENSqlFieldTypeNotSupported = class(ENSqlException);
  ENSqlQueryComponentNotSupported = class(ENSqlException);
  ENSqlQueryComponentInvalid = class(ENSqlException);
  ENSqlParamTypeInvalid = class(ENSqlException);
  ENSqlParamCountInvalid = class(ENSqlException);
  ENSqlParamNotFound = class(ENSqlException);
  ENSqlPropNotFound = class(ENSqlException);
  ENSqlPropTypeNotSupported = class(ENSqlException);
  ENSqlMatchPropNotExist = class(ENSqlException);
  ENSqlScriptInvalid = class(ENSqlException);

  //
  ENSqlLogError = class(Exception);

  { Sql type }
  TNSqlType = (stSelect, stInsert, stUpdate, stDelete);

const
  PLATFORM_DB_ORA = 'ORA';
  PLATFORM_DB_FB2 = 'FB2';
  PLATFORM_DB_SQLITE = 'SQLITE';

  SQL_LOG_DEBUG = 0;
  SQL_LOG_INFO  = 2;
  SQL_LOG_WARN  = 3;
  SQL_LOG_ERROR = 4;
  SQL_LOG_ENTER = 5;
  SQL_LOG_EXIT  = 7;

  cstSqlTypeNames: array[stSelect..stDelete] of string =
    ('Select', 'Insert', 'Update', 'Delete');

  { String }
  N_DBTYPES_STRING: set of TFieldType = [ftString, ftWideString, ftFixedChar, ftMemo, ftWideMemo, ftFmtMemo];
  { Integer }
  N_DBTYPES_INT: set of TFieldType = [ftSmallint, ftInteger, ftWord, ftBytes];
  { Int64 }
  N_DBTYPES_INT64: set of TFieldType = [ftLargeInt, ftAutoInc];
  { Float }
  N_DBTYPES_FLOAT: set of TFieldType = [ftFloat, ftCurrency, ftExtended, ftSingle];
  { DateTime }
  N_DBTYPES_DATETIME: set of TFieldType = [ftDate, ftTime, ftDateTime, ftTimeStamp];
  { Supported data types }
  N_DBTYPES_SUPPORTED: set of TFieldType =
    [ftString, ftWideString, ftFixedChar, ftMemo, ftWideMemo, ftFmtMemo,
     ftSmallint, ftInteger, ftWord, ftBytes,
     ftLargeInt, ftAutoInc,
     ftFloat, ftCurrency, ftExtended, ftSingle,
     ftDate, ftTime, ftDateTime, ftTimeStamp];


{-------------------------------------------------------------------------------
  ** Look DB.pas
  TFieldType = (ftUnknown, ftString, ftSmallint, ftInteger, ftWord, // 0..4
    ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, // 5..11
    ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
    ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString, // 19..24
    ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
    ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
    ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
    ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream, //42..48
    ftTimeStampOffset, ftObject, ftSingle); //49..51


  TFieldType = (ftUnknown, ftString, ftSmallint, ftInteger, ftWord,
    ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime,
    ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo,
    ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString,
    ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob,
    ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd);
-------------------------------------------------------------------------------}
type

  TKTableBeanFieldMapper = class
  private
    fTableBeanMapper: TDictionary<String, String>;       // TableName=QualifiedBeanClassName
    fBeanTableMapper: TDictionary<String, String>;       // QualifiedBeanClassName=TableName
    fTableBeanFieldMapper: TDictionary<String, String>;  // TableName.FieldName=BeanFieldName
    fBeanTableFieldMapper: TDictionary<String, String>;
    function GetMappedBean(ATableName: String): String;
    function GetMappedBeanField(ATableNameDotField: String): String;
    function GetMappedTable(AQualifiedBeanClazz: String): String;
    function GetMappedTableField(AQualifiedBeanClazzDotField: String): String;  // QualifiedBeanClassName.FieldName=TableFieldName
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadMappingFile(f: String);
    property MappedBean[ATableName: String]: String read GetMappedBean;
    property MappedTable[ABeanClazz: String]: String read GetMappedTable;
    property MappedBeanField[ATableNameDotField: String]: String read GetMappedBeanField;
    property MappedTableField[ABeanClazzDotField: String]: String read GetMappedTableField;
  end;

{-------------------------------------------------------------------------------
  : If - dynamic sql supported by TNSqlCondition class
  : The dynamic statement should be blocked as followings
    <if ParamName[operator][CompareValue]>
      Sql statements if evaluation is true
    <else>
      Sql statements if evaluation is false
    </if>
  : The <else> token is optional
  : ParamName must be one of the properties of passed parameter object
  : Operator must be one of ( =, !=, <>, > <, >=, <= )
-------------------------------------------------------------------------------}
  TNSqlCondEvalType = (cetNullCheck, cetNumric, cetString);

  TNSqlCondition = class(TNData)
  private
    fParamName: String;             // Parameter name. It should be a property name of parameter object. Normally
    fOperator: String;              // =, !=, <>, > <, >=, <=
    fEvalType: TNSqlCondEvalType;   // compareValue is numeric or not ?. If quoted, It assumed as non-numeric
    fValue: String;                 // A compare value value. It should be quoted by " or ' if string value
    fEvalResult: Boolean;           // Evaluate result. It is evaluated before every query
  published
    property ParamName: String read fParamName write fParamName;
    property CondOperator: String read fOperator write fOperator;
    property EvalType: TNSqlCondEvalType read fEvalType write fEvalType;
    property Value: String read fValue write fValue;
    property EvalResult: Boolean read fEvalResult write fEvalResult;
  end;

{-------------------------------------------------------------------------------
  - Helper class to parse Sql script
  : Each TNSql.SqlLines.Objects[index] links to TNSqlApplyLine object
-------------------------------------------------------------------------------}
  TNSqlApplyLine = class(TNData)
  private
    fConditionIndex: Integer;      // Index of SqlConditions
    fIncludeWhen: Boolean;         // 조건평가가 어떨 때 포함되는가 ?  "true" means this line is in <if> block, "false" means this line is <else> block
  public
    constructor Create; override;
    procedure SetApplyLine(ASqlApplyLine: TNSqlApplyLine);
  published
    property ConditionIndex: Integer read fConditionIndex write fConditionIndex;
    property IncludeWhen: Boolean read fIncludeWhen write fIncludeWhen;
  end;

  TNSqlManager = class;

{-------------------------------------------------------------------------------
 Class TNSql.
 - Sql object container.
 - Note, Even though the database support unicode and muti-bytes characters,
   You can not use multi-byte characters in SQL script file !!
-------------------------------------------------------------------------------}
  TNSql = class(TNData)
  private
    fSqlMgr: TNSqlManager;
    fName: string;                   // Should be unique system globally. = hash key
    fResultClassName: String;        // Can be null
    fSqlType: TNSqlType;             // Select, Insert, Update, Delete,
    fSqlLines: TStringList;          // 원본 SQL 문
    fReplaceItems: TStringList;      // 원본 SQL 에 정의된 치환항목(&**&)
    fSqlConditions: TList;           // 정의된 조건문. 첫번째 항목은 Default (true) 로 if-dynamic block 에 해당되지 않는 SQL 문에 링크됨
    fPreparedSql: String;            // 각 Sql 실행시 조건(if-dynamic) 및 치환이 완료된 실행될 Sql. Unicode Support
    fLastApplyLine: TNSqlApplyLine;
    { Name, Result 항목을 로딩합니다. <sql name=SelectTC_KioskConfig result=TC_KioskConfig> }
    function SetSqlInfo(ALine: String; var eMsg, dMsg: String): Boolean;
    procedure StartSqlCondition(ALine: string);
    procedure ReverseSqlCondition;
    procedure EndSqlCondition;
    procedure AddSqlLine(ALine: string);
    procedure ExtractReplaceItems(ALine: string);
  protected
    procedure DetectSqlType;
    procedure EvalConditions(AParamObj: TPersistent); overload;
    procedure PrepareSql(AParamObj: TPersistent); overload;
    procedure PrepareSql(AParams: Array of String); overload;
    function GetText: String;
  public
    constructor Create; override;
    destructor Destroy; override;
    function GetSqlApply(Idx: Integer): TNSqlApplyLine;
    function GetSqlCondition(Idx: Integer): TNSqlCondition;
    property SqlMgr: TNSqlManager read fSqlMgr write fSqlMgr;
  published
    property Text: String read GetText;
    property SqlConditions: TList read fSqlConditions;
    property Name: string read fName;                   // Should be unique system globally. = hash key
    property ResultClassName: String read fResultClassName;
    property SqlType: TNSqlType read fSqlType;
    property ReplaceItems: TStringList read fReplaceItems;
    property SqlLines: TStringList read fSqlLines;
    property PreparedSql: String read fPreparedSql;
  end;


  TNSqlManagerType = (smtDB, smtRtc);

  TNSqlLogEvent = procedure(Sender: TObject; ALevel: Integer; ALog: String) of object;

  TNSqlManager = class(TComponent)
  protected
    fInitialized: Boolean;    // Set to true When ReplaceInternalTableFields() called
    fSqls: TDictionary<String, TNSql>;
    fDBPlatform: String;
    fNodeName: String;
    fHtmlSelectedSqlName: String;
  protected
    fInteractive: Boolean;
    { Support for thread safe }
//    fSqlItemCriSection: TCriticalSection;            // Sql item should be thread safe while prepare params
//    fDefaultCompCriSection: TCriticalSection;        // Default query component should be thread safe
//    fEventCriSection: TCriticalSection;              //
    { Class information cache }
    { Default Query, SQL component }
    fDefaultQueryComponent: TObject;
    fDefaultSqlComponent: TObject;
    { Event for debug }
    fOnWriteLog: TNSqlLogEvent;
    fOnBeforeQuery: TNotifyEvent;
    fOnPostQuery: TNotifyEvent;
    { Loaded Sqls }
    fLoadedSqlFiles: TStringList; // FileName=Version
    fInlineReplaceCache: TStringList;
    { Parse sql script and load it as TNSql }

    fTableBeanMapper: TKTableBeanFieldMapper;

    procedure _AddNewSql(ASql: TNSql);
    function _ParseSql(AStrings: TStrings): Integer;
    function _GetSql(ASqlName: string): TNSql;
    function _GetSqlExist(ASqlName: string): Boolean;
    function _GetBeanClassName(ASqlName: String; AQuery: TObject): String; virtual;
    { Misc Rtti helper methods }
    function _GetInstanceOf(AClassName: string): TNData;
//    function _GetPropInfo(AnObj: TPersistent): TKClassPropInfo;
    { Property Access Methods }
    procedure _SetDefaultQuery(AQueryComponent: TObject);
    procedure _SetDefaultSQL(ASQLComponent: TObject);
    { Validate if passed Query or SQL object is supported. it not, exception will be raised }
    procedure _ValidateQueryComp(AQuery: TObject);
    procedure _ValidateSQLComp(ASQL: TObject);

    { Utility methods : }
    procedure _ReplaceTableFieldsItem(ASql: TNSql); virtual; abstract;
    function _GetRecordCountOf(AQuery: TObject): Integer; virtual; abstract;
    { Abstract methods. The decendant class must implements following methods }
    { Define your component to support }
    function _IsSupportedQuery(AQuery: TObject): Boolean; virtual;
    function _IsSupportedSQL(ASQL: TObject): Boolean; virtual;
    { Fill Sql.params }
    procedure _FillParams(AQueryOrSQL: TObject; ASql: String; AParamObj: TPersistent); overload; virtual;
    procedure _FillParams(AQueryOrSQL: TObject; ASql: String; AParams: Array of String); overload; virtual;
//    procedure _GetParamList(AQueryOrSQL: TObject; ASql: String; AParams: TStrings); virtual;
    { Open, execute sql statement }
    procedure _OpenQuery(AQuery: TObject); virtual;
    function _ExcuteQuery(ASql: TObject): Integer; virtual;
    { Actual IO of database. such as open, execute, fetch }
    function _GetListFromDataSet(AQuery: TObject; AResultClassName: string; InterProc: TNotifyEvent = nil): TNList; overload; virtual;
    procedure _GetListFromDataSet(AQuery: TObject; AResultClassName: string; AReturnList: TNList; InterProc: TNotifyEvent = nil); overload; virtual;
    function _GetObjectFromDataSet(AQuery: TObject; AResultClassName: string): TNData; virtual;
    function _LoadObjectFromDataSet(AQuery: TObject; AResult: TPersistent): integer; virtual;
    { Get Value }
    function _GetValue(AQuery: TObject; AFieldName: string = ''): Variant; virtual;

    {---------------------------------------------------------------------------
      Handle magic info. such as file version, encrypted engine version
     --------------------------------------------------------------------------}
    function _GetConnected: Boolean; virtual; abstract;
    procedure _SetConnected(value: Boolean); virtual; abstract;
    function _GetSqlCount: Integer;
    //
  protected
    procedure _Open(AQuery: TObject; ASqlName: string; AParamObj: TPersistent); overload; virtual;
    procedure _OpenRecordCount(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; ACountFieldName: String = 'RecordCount');  overload; virtual;
    procedure _OpenPage(AQuery: TObject; ASqlName: string; AParamObj: TPersistent); virtual;

    function _WrapCountQuery(ASelectSql: String; ACountFieldName: String): String; virtual;
    function _WrapPageQuery_Sqlite(ASelectSql: String; AParamObj: TPersistent): String; overload; virtual;
    function _WrapPageQuery_ORA(ASelectSql: String; AParamObj: TPersistent): String; virtual;
    function _WrapPageQuery_FB(ASelectSql: String; AParamObj: TPersistent): String; overload; virtual;

    procedure _DoBeforeQuery(AQueryObj: TObject);
    procedure _DoPostQuery(AQueryObj: TObject);
    function _GetLastSqlRtcAborted: Boolean; virtual; abstract;
    procedure _WriteLog(ALevel: Integer; ALog: String);
  public
    { Default Sql Component Transation Support }
    procedure StartTransaction(AComp: TObject); virtual; abstract;
    procedure Commit(AComp: TObject); virtual; abstract;
    procedure Rollback(AComp: TObject); virtual; abstract;
    property Connected: Boolean read _GetConnected write _SetConnected;
    class function IOType: TNSqlManagerType; virtual; abstract;
    property SqlCount: Integer read _GetSqlCount;
    property Initialized: Boolean read fInitialized;
  public
    constructor Create(AOwner: TComponent; ADBPlatform, ANodeName: String); virtual;
    destructor Destroy; override;
    procedure LoadMapperFile(f: String);
    function PlatformDB: String; virtual;       // Must be impelmented
    function PlatformNode: String; virtual;     // Must be impelmented
    function IsAvailableObject(ASqlOrQueryObj: TObject): Boolean; virtual; abstract;
    procedure LoadSqlFile(AFile: string);
    procedure LoadSqlFiles(ADir: String; AExt: string = '*.sql'); overload;
    procedure LoadSqlFiles(AFiles: TStrings); overload;
    function TnxIsActive(AQueryObj: TObject; var eCode: String): Boolean; virtual; abstract;
    procedure ReplaceInternalTableFields;
    { Get count from list after automated wrapping }
    function GetCountOfList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent): Integer; overload; virtual;
    function GetCountOfList(ASqlName: string; AParamObj: TPersistent): Integer; overload; virtual;
    { Query and return List of object }
    function GetList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; InterProc: TNotifyEvent = nil): TNList; overload;
    function GetList(ASqlName: string; AParamObj: TPersistent; InterProc: TNotifyEvent = nil): TNList; overload;     // with default component
    procedure GetList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; AReturnList: TNList; InterProc: TNotifyEvent = nil); overload;
    procedure GetList(ASqlName: string; AParamObj: TPersistent; AReturnList: TNList; InterProc: TNotifyEvent = nil); overload;     // with default component
    { Query and return List of object - page mode }
    function GetPagedList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; InterProc: TNotifyEvent = nil): TNList; overload;
    function GetPagedList(ASqlName: string; AParamObj: TPersistent; InterProc: TNotifyEvent = nil): TNList; overload;     // with default component
    procedure GetPagedList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; AReturnList: TNList; InterProc: TNotifyEvent = nil); overload;
    procedure GetPagedList(ASqlName: string; AParamObj: TPersistent; AReturnList: TNList; InterProc: TNotifyEvent = nil); overload;     // with default component
    { Query and return Object }
    function GetObject(AQuery: TObject; ASqlName: string; AParamObj: TPersistent): TPersistent; overload;
    function GetObject(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; AResult: TPersistent): integer; overload;
    function GetObject(ASqlName: string; AParamObj: TPersistent): TPersistent; overload;                    // with default component
    function GetObject(ASqlName: string; AParamObj, AResult: TPersistent): integer; overload;               // with default component
    { Query and return value as variant }
    function GetValue(AQuery: TObject; ASqlName, AFieldName: string; AParamObj: TPersistent): variant; overload;
    function GetValue(ASqlName, AFieldName: string; AParamObj: TPersistent): variant; overload;             // with default component
    { Open query. This method does not fetch data, just open query }
    procedure Open(AQuery: TObject; ASqlName: string; AParamObj: TPersistent); overload;
    { Close query. }
    procedure CloseQuery(AQuery: TObject); virtual;
    { Execute and return row count affected. Transaction must be handled at outside by caller }
    function Execute(ASqlComp: TObject; ASqlName: string; AParamObj: TPersistent;
                     AllowZeroOnRemoteSql: Boolean = false): integer; overload; virtual;
    function Execute(ASqlName: string; AParamObj: TPersistent;
                     AllowZeroOnRemoteSql: Boolean = false): integer; overload; virtual;
    function GetLastAutoIncrement: Int64; virtual; abstract;
    { debug }
    procedure PrintDebug(AStrings: TStrings); virtual;
    property LastSqlRtcAborted: Boolean read _GetLastSqlRtcAborted;
    { Access properties }
    property TableBeanMapper: TKTableBeanFieldMapper read fTableBeanMapper;
    property DefaultQuery: TObject Read fDefaultQueryComponent Write _SetDefaultQuery;
    property DefaultSql: TObject Read fDefaultSqlComponent Write _SetDefaultSQL;
    property SqlExist[ASqlName: String]: Boolean read _GetSqlExist;
    property Sql[ASqlName: String]: TNSql read _GetSql;
    property Interactive: Boolean read fInteractive write fInteractive;
    property OnWriteLog: TNSqlLogEvent read fOnWriteLog write fOnWriteLog;
    property OnBeforeQuery: TNotifyEvent read fOnBeforeQuery write fOnBeforeQuery;
    property OnPostQuery: TNotifyEvent read fOnPostQuery write fOnPostQuery;
  end;

  TKPageInfo = Class
  private
    fPage: Integer;
    fTotalRecordCount: Integer;
    fRecordCountPerPage: Integer;
    procedure SetPage(const Value: Integer);
    procedure SetTotalRecordCount(const Value: Integer);
    function GetEndRow: Integer;
    function GetStartRow: Integer;
    function GetPageCount: Integer;
    procedure SetRecordCountPerPage(const Value: Integer);
    function GetCurrPageRecordCount: Integer;
  public
    constructor Create;
  published
    property TotalRecordCount: Integer read fTotalRecordCount write SetTotalRecordCount;
    property RecordCountPerPage: Integer read fRecordCountPerPage write SetRecordCountPerPage;
    property Page: Integer read fPage write SetPage;
    property PageCount: Integer read GetPageCount;
    property CurrPageRecordCount: Integer read GetCurrPageRecordCount;
    property StartRow: Integer read GetStartRow;
    property EndRow: Integer read GetEndRow;
  end;

//  function GsmTnxIsAvailable(var eCode: String; IfNotRaiseError: Boolean = false): Boolean;
//  function GeTNDataClass(AClassName: String): TNDataClass;

var
{-------------------------------------------------------------------------------
  Global Sql Manager "gsm"
  - It must be descendant of TNSqlManager
  - Must be thread safe.
-------------------------------------------------------------------------------}
//  gsm: TNSqlManager;
  gsmLocal: TNSqlManager;

implementation

uses System.Math, System.DateUtils, System.StrUtils, System.IniFiles,
  NBasePerf, NLibString;

const
  // Sql Token
  cstSqlStartToken = '<sql';
  cstSqlEndToken   = '</sql>';

  cstSqlIfToken = '<if';
  cstSqlElseToken = '<else>';
  cstSqlEndIfToken = '</if>';

{ TNSqlCondition }


{ TNSqlApplyLine }
constructor TNSqlApplyLine.Create;
begin
  inherited Create;
  ConditionIndex := 0;
  IncludeWhen := true;
end;

procedure TNSqlApplyLine.SetApplyLine(ASqlApplyLine: TNSqlApplyLine);
begin
  ConditionIndex := ASqlApplyLine.ConditionIndex;
  IncludeWhen := ASqlApplyLine.IncludeWhen;
end;

{ Class TNSql }
constructor TNSql.Create;
begin
  inherited Create;
  fSqlMgr := nil;

  fSqlLines := TStringList.Create;
  fReplaceItems := TStringList.Create;
  fReplaceItems.CaseSensitive := False;
  fReplaceItems.Sorted := True;
  fReplaceItems.Duplicates := dupIgnore;

  fSqlConditions := TList.Create;
  // Add Default Condition as true
  fSqlConditions.Add(TNSqlCondition.create);
  TNSqlCondition(fSqlConditions.Items[0]).EvalResult := true;

  fLastApplyLine := TNSqlApplyLine.Create;

end;

destructor TNSql.Destroy;
var
  i: Integer;
begin
  fLastApplyLine.Free;
  while fSqlConditions.Count > 0 do begin
    TObject(fSqlConditions.Items[fSqlConditions.Count-1]).Free;
    fSqlConditions.Delete(fSqlConditions.Count-1);
  end;
  fSqlConditions.Free;
  fReplaceItems.Free;
  // Free SqlApplyLine Objects
  for i:=0 to fSqlLines.Count-1 do
    TObject(fSqlLines.Objects[i]).Free;
  fSqlLines.Free;
  inherited;
end;

{ Extract Replace items. It should be started and ended with "&" char.
  It may replace by parameter property has same name } 
procedure TNSql.ExtractReplaceItems(ALine: string);
var
  s, e: integer;
  AnItem: string;
begin
  s := PosEx('&', ALine, 1);
  while s > 0 do begin
    e := PosEx('&', ALine, s + 1);
    if e > s then begin
      AnItem := Copy(ALine, s + 1, e - s - 1);
      if Length(AnItem) > 0 then begin
        fReplaceItems.Add(AnItem);
      end
      else
        raise ENSqlScriptInvalid.Create(format('Sql parameter invalid. %s', [ALine]));
    end
    // "%" Token 이 정상적으로 마감되지 않았음.
    else
      raise ENSqlScriptInvalid.Create(format('Sql parameter invalid. %s', [ALine]));
    s := PosEx('&', ALine, e + 1);
  end;
end;

procedure TNSql.AddSqlLine(ALine: string);
var
  ASqlApplyLine: TNSqlApplyLine;
begin
  // Purge comment portion
  ALine := Trim(NTruncComment(ALine));
  // cstSqlIfToken = '<if';
  if StartsText(cstSqlIfToken, ALine) then begin
    StartSqlCondition(ALine);
  end
  // cstSqlElseToken = '<else>';
  else if StartsText(cstSqlElseToken, ALine) then begin
    ReverseSqlCondition;
  end
  // cstSqlEndIfToken = '</if>';
  else if StartsText(cstSqlEndIfToken, ALine) then begin
    EndSqlCondition;
  end
  // Yes. It's a real sql script
  else begin
    ExtractReplaceItems(ALine);
    ASqlApplyLine := TNSqlApplyLine.Create;
    ASqlApplyLine.SetApplyLine(fLastApplyLine);
    fSqlLines.AddObject(ALine, ASqlApplyLine);
  end;
end;

procedure TNSql.DetectSqlType;
var
  i: integer;
begin
  fSqlType := stSelect;
  for i := 0 to fSqlLines.Count - 1 do begin
    if Trim(fSqlLines[i]) = '' then
      Continue;
    if StartsText('INSERT', Trim(fSqlLines[i])) then
      fSqlType := stInsert
    else if StartsText('UPDATE', Trim(fSqlLines[i])) then
      fSqlType := stUpdate
    else if StartsText('DELETE', Trim(fSqlLines[i])) then
      fSqlType := stDelete;
    Exit;
  end;
end;

function TNSql.SetSqlInfo(ALine: String; var eMsg, dMsg: String): Boolean;
// <sql name=MyName result=ResultTypeOrClassName>
var
  AStrList: TStringList;
  ADB, ANode: String;
begin
  result := false;
  eMsg := '';
  dMsg := '';
  AStrList := TStringList.Create;
  try
    if Pos('>', ALine) < 1 then              // Find first ">"
      eMsg := format('Sql script header invalid. "%s"', [ALine]);

    ALine := StringReplace(ALine, cstSqlStartToken, '', []);      // KPReplaceIC(cstSqlStartToken, '', ALine);   // Replace "<sql" -> ''
    ALine := StringReplace(ALine, '>', '', [rfReplaceAll]);            // Replace ">" -> ''

    ExtractStrings([' '], [], PWideChar(ALine), AStrList);
    fName := Trim(AStrList.Values['Name']);
    fResultClassName := Trim(AStrList.Values['Result']);
    ADB := Trim(AStrList.Values['_DB']);
    ANode := Trim(AStrList.Values['_Node']);
    if fName = '' then
      eMsg := format('Sql script header invalid. "%s"', [ALine])
    else if (ANode <> '') and (not SameText(SqlMgr.PlatformNode, ANode)) then
      dMsg := format('Sql item ignored. Not for "%s" node. "%s"', [SqlMgr.PlatformNode, ALine])
    else if (ADB <> '') and (not SameText(SqlMgr.PlatformDB, ADB)) then
      dMsg := format('Sql item ignored. Not for my database(%s). "%s"', [SqlMgr.PlatformDB, ALine])
    else
      result := true;
  finally
    AStrList.Free;
  end;
end;

function TNSql.GetSqlApply(Idx: Integer): TNSqlApplyLine;
begin
  result := TNSqlApplyLine(fSqlLines.Objects[Idx]);
end;

function TNSql.GetSqlCondition(Idx: Integer): TNSqlCondition;
begin
  result := TNSqlCondition(fSqlConditions.Items[Idx]);
end;

const
  _SQL_COND_OPERATORS: Array[0..6] of String = ('=', '<', '>',  '<=', '>=', '!=', '<>');

//<if param = value>
procedure TNSql.StartSqlCondition(ALine: string);

  function _GetOperatorIndex(AString: String; var APos: Integer): Integer;
  var
    i: Integer;
  begin
    result := -1;
    for i:=High(_SQL_COND_OPERATORS) downto Low(_SQL_COND_OPERATORS) do begin
      APos := Pos(_SQL_COND_OPERATORS[i], AString);
      if APos > 0 then begin
        result := i;
        Exit;
      end;
    end;
  end;

var
  AIdx, AOpPos: Integer;
  ACond: TNSqlCondition;
begin
  ACond := TNSqlCondition.Create;

  ALine := NLeftOfPosRev('>', Trim(ALine));               // Eliminate trailing after ">"
  ALine := Copy(ALine, 5);                                // <if xxx=yyy --> xxx=yyy

  // Extract param name, operator, compare value
  AIdx := _GetOperatorIndex(ALine, AOpPos);
  if AIdx < 0 then begin
    ACond.EvalType := cetNullCheck;
    ACond.ParamName := ALine;
    ACond.CondOperator := '=';
    ACond.Value := 'notnull';
  end
  else begin
    ACond.CondOperator := _SQL_COND_OPERATORS[AIdx];
    ACond.ParamName := Trim(Copy(ALine, 1, AOpPos-1));
    // Extract value
    ACond.Value := Trim(Copy(ALine, AOpPos + Length(ACond.CondOperator), MAXINT));
    // Eval Type, Null check 할 경우 인용부호 없이 null 또는 notnull 을 정의해야 함.
    if SameText(ACond.Value, 'null') or SameText(ACond.Value, 'notnull') then
      ACond.EvalType := cetNullCheck
    else if NIsNumberOnly(ACond.Value) then
      ACond.EvalType := cetNumric
    else
      ACond.EvalType := cetString;

    // Purge preceding or trailing quoted char
    if ACond.EvalType = cetString then
      ACond.Value := NDeQuoteSide(NDeQuoteSide(Trim(ACond.Value),  ''''), '"');
  end;

  fSqlConditions.Add(ACond);
  // Set
  fLastApplyLine.ConditionIndex := fSqlConditions.Count-1;
  fLastApplyLine.IncludeWhen := true;
end;

{ If meet <else> ... }
procedure TNSql.ReverseSqlCondition;
begin
  fLastApplyLine.IncludeWhen := false;
end;

procedure TNSql.EndSqlCondition;
begin
  // Reset to default condition
  fLastApplyLine.ConditionIndex := 0;
  fLastApplyLine.IncludeWhen := true;
end;


procedure TNSql.EvalConditions(AParamObj: TPersistent);
var
  i: Integer;
  AValueOfObj: TValue;
  ANumValueOfObj: Extended;
  AStrValueOfObj: String;
  rType: TRttiType;
  AFieldOrPropFound: Boolean;
  ANumValueOfCond: Extended;
begin
  // first item is default..
  if fSqlConditions.Count < 2 then
    Exit;

  rType := nil;
  if Assigned(AParamObj) then
    rType := TNRtti.RttiCtx.GetType(AParamObj.ClassType);

  try
    (* On each conditions, We have to compare it with input value
    --------------------------------------------------------------------------*)
    for i:=1 to fSqlConditions.Count-1 do begin
      with TNSqlCondition(fSqlConditions.Items[i]) do begin
        EvalResult := false;

        (* Some special conditions must be compared configured value
        ----------------------------------------------------------------------*)
        if SameText(ParamName, '_Node') then begin
          AValueOfObj := TValue.From(SqlMgr.PlatformNode);
        end
        else if SameText(ParamName, '_DB') then begin
          AValueOfObj := TValue.From(SqlMgr.PlatformDB);
        end
        (* Null condition means "if property of param object is exist"
        ----------------------------------------------------------------------*)
        else if EvalType <> cetNullCheck then begin
          AValueOfObj := TNRtti.GetMemberValue(rType, AParamObj, ParamName);
        end
        else
          AValueOfObj := TValue.Empty;

        // If numeric condition(Such as "<OwnerNo > 0>"
        case EvalType of
          TNSqlCondEvalType.cetNumric:
            begin
              if AValueOfObj.Kind in N_TYPES_NUMERIC then begin
                if TryStrToFloat(value, ANumValueOfCond) then begin
                  ANumValueOfObj := AValueOfObj.AsExtended;
                  case IndexText(CondOperator, _SQL_COND_OPERATORS) of  // ['=', '<', '>', '<=', '>=', '!=', '<>']
                    0: EvalResult := ANumValueOfObj = ANumValueOfCond;
                    1: EvalResult := ANumValueOfObj < ANumValueOfCond;
                    2: EvalResult := ANumValueOfObj > ANumValueOfCond;
                    3: EvalResult := ANumValueOfObj <= ANumValueOfCond;
                    4: EvalResult := ANumValueOfObj >= ANumValueOfCond;
                    5,6: EvalResult := ANumValueOfObj <> ANumValueOfCond;
                  end;
                end;
              end;
            end;
          // If string condition(Such as "<DiscStatusCD > "DSAA">"
          TNSqlCondEvalType.cetString:
            begin
              if AValueOfObj.Kind in N_TYPES_STRING then
                AStrValueOfObj := AValueOfObj.AsString
              else
                AStrValueOfObj := '';

              if MatchText(ParamName, ['_Node', '_DB']) then begin
                if IndexText(CondOperator, _SQL_COND_OPERATORS) =  0 then
                  EvalResult := SameText(AStrValueOfObj, Value)
                else
                  EvalResult := not SameText(AStrValueOfObj, Value);
              end
              else begin
                case IndexText(CondOperator, _SQL_COND_OPERATORS) of  // ['=', '<', '>', '<=', '>=', '!=', '<>']
                  0: EvalResult := SameText(AStrValueOfObj, Value);
                  1: EvalResult := CompareText(AStrValueOfObj, Value) < 0; // Returns 0 if s1=s2, >1 if s1>s2, <1 if s1<s2
                  2: EvalResult := CompareText(AStrValueOfObj, Value) > 0;
                  3: EvalResult := SameText(AStrValueOfObj, Value) or (CompareText(AStrValueOfObj, Value) < 0);
                  4: EvalResult := SameText(AStrValueOfObj, Value) or (CompareText(AStrValueOfObj, Value) > 0);
                  5,6: EvalResult := not SameText(AStrValueOfObj, Value);
                end;
              end;
            end;
          TNSqlCondEvalType.cetNullCheck:
            begin
              AFieldOrPropFound := TNRtti.GetMember(rType, ParamName) <> nil;
              case IndexText(CondOperator, _SQL_COND_OPERATORS) of  // ['=', '<', '>', '<=', '>=', '!=', '<>']
                0:
                  begin
                    if SameText(Value, 'null') then
                      EvalResult := not AFieldOrPropFound
                    else
                      EvalResult := AFieldOrPropFound;
                  end;
                else
                  begin
                    if SameText(Value, 'null') then
                      EvalResult := AFieldOrPropFound
                    else
                      EvalResult := not AFieldOrPropFound;
                  end;
              end;
            end;
          end;  // End case
      end;      // End with
    end;        // End for
  finally
  end;
end;

// Task #1. Set PreparedSql (Must Call Text)
procedure TNSql.PrepareSql(AParams: Array of String);
begin
  (* We can not process Eval conditions(such as "<OwnerNo>0") and replace items with array parameters.
     We can process replace items only.
     Sql 조건은 Open array 로 처리 불가 (이름을 모르므로)
  ----------------------------------------------------------------------------*)
  if (fSqlConditions.Count < 2) and (fReplaceItems.Count < 1) then begin
    if Length(fPreparedSql) < 1 then
      fPreparedSql := Text;
  end
  else
    fPreparedSql := Text;
  SqlMgr._WriteLog(SQL_LOG_INFO, format('%s prepared with open array params(%d)', [Self.Name, Length(AParams)]));
//  fSqlMgr._WriteLog(SQL_LOG_DEBUG, #13 + fPreparedSql);
end;


(* Task #1. Eval Condition Expr,
   Task #2. Set PreparedSql (Must Call Text)
   Task #3. Replace &word& in sql
------------------------------------------------------------------------------*)
procedure TNSql.PrepareSql(AParamObj: TPersistent);
var
  i: integer;
  AValue: TValue;
  rType: TRttiType;
  rMember: TRttiMember;
begin
  (* Perform Conditional Expressions such as "<OwnerNo > 0>"
  ----------------------------------------------------------------------------*)
  EvalConditions(AParamObj);

  (* If replace items are not exist then exit(to prevent overhead)
  ----------------------------------------------------------------------------*)
  if (fSqlConditions.Count < 2) and (fReplaceItems.Count < 1) then begin
    if Length(fPreparedSql) < 1 then
      fPreparedSql := Text;
  end
  else begin
    fPreparedSql := Text;
    if fReplaceItems.Count > 0 then begin
      if not Assigned(AParamObj) then begin
        fSqlMgr._WriteLog(SQL_LOG_WARN, format('Sql replace items exist but parameter is nil(%s)', [Self.Name]));
      end
      else begin
        rType := TNRtti.RttiCtx.GetType(AParamObj.ClassType);
        if not Assigned(rType) then begin
          SqlMgr._WriteLog(SQL_LOG_WARN, format('Sql parameter class invalid(%s). Must be descendent of TPersistent', [Self.Name]));
        end
        else begin
          for i:=0 to fReplaceItems.Count - 1 do begin
            rMember := TNRtti.GetMember(rType, fReplaceItems.Strings[i]);
            if rMember <> nil then begin
              AValue := TNRtti.GetMemberValue(rMember, AParamObj);
              if AValue.Kind in N_TYPES_STRING then
                fPreparedSql := StringReplace(fPreparedSql, '&' + fReplaceItems.Strings[i] + '&', AValue.AsString, [rfReplaceAll])
              else if AValue.Kind in N_TYPES_NUMERIC then
                fPreparedSql := StringReplace(fPreparedSql, '&' + fReplaceItems.Strings[i] + '&', FloatToStr(AValue.AsExtended), [rfReplaceAll])
              else
                SqlMgr._WriteLog(SQL_LOG_WARN, format('Sql replace item can not be replaced. property "%s" type is not primitive(%s)',
                  [fReplaceItems.Strings[i], Self.Name]));
            end
            else begin
              if Pos('&' + fReplaceItems.Strings[i] + '&', fPreparedSql) > 0 then begin
                SqlMgr._WriteLog(SQL_LOG_WARN, format('Sql replace item can not be replaced. property "%s" not found(%s)', [fReplaceItems.Strings[i], Self.Name]));
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  SqlMgr._WriteLog(SQL_LOG_INFO, format('%s prepared with param %s', [Self.Name, GetClassName(AParamObj)]));
//  SqlMgr._WriteLog(SQL_LOG_DEBUG, fPreparedSql);
end;

type
  TStringListAccess = class(TStringList);

{
  GetText function for if-dynamic support.
  각 라인은 Objects[i] 에 TNSqlAppline 을 객체로 링크하고 있음.
  해당 Link 에 정의된 값에 따라...
}
function TNSql.GetText: String;
var
  I, Count: Integer;
begin
  result := '';
  Count := fSqlLines.Count;
  for I := 0 to Count-1 do begin
    if GetSqlApply(i).IncludeWhen = GetSqlCondition(GetSqlApply(I).ConditionIndex).EvalResult then begin
      if result <> '' then
        result := result + sLineBreak;
      result := result + TStringListAccess(fSqlLines).Get(I);
    end;
  end;
end;

function TNSqlManager.PlatformDB: String;
begin
  if fDBPlatform = '' then
    raise ENSqlException.Create('Database platform was not defined');
  result := fDBPlatform;
end;

function TNSqlManager.PlatformNode: String;
begin
  if fNodeName = '' then
    raise ENSqlException.Create('Node platform was not defined');
  result := fNodeName;
end;

constructor TNSqlManager.Create(AOwner: TComponent; ADBPlatform, ANodeName: String);
begin
  inherited Create(AOwner);
  fSqls := TDictionary<String, TNSql>.Create;

  fDBPlatform := ADBPlatform; // Ora or FB2
  fNodeName := ANodeName;     // Server or Kiosk
  fLoadedSqlFiles := TStringList.Create;

//  fSqlItemCriSection := TCriticalSection.Create;
//  fDefaultCompCriSection := TCriticalSection.Create;
//  fEventCriSection := TCriticalSection.Create;
  fInlineReplaceCache := TStringList.Create;

//  fLastLocalIOResult := sr Local;
//  fLastRemoteIOResult := srRemote;
  fTableBeanMapper := TKTableBeanFieldMapper.Create;
end;

procedure TNSqlManager.LoadMapperFile(f: String);
begin
  fTableBeanMapper.LoadMappingFile(f);
end;

destructor TNSqlManager.Destroy;
var
  k: String;
begin
  for k in fSqls.Keys do
    fSqls.Items[k].Free;
  fInlineReplaceCache.Free;
  fLoadedSqlFiles.Free;

//  fSqlItemCriSection.Free;
//  fDefaultCompCriSection.Free;
//  fEventCriSection.Free;

  fDefaultQueryComponent := nil;
  fDefaultSqlComponent := nil;
  fSqls.Free;
  FreeAndNil(fTableBeanMapper);
  inherited;
end;

procedure TNSqlManager._WriteLog(ALevel: Integer; ALog: String);
begin
  if Assigned(fOnWriteLog) then
    fOnWriteLog(Self, ALevel, ALog);
end;

procedure TNSqlManager._DoBeforeQuery(AQueryObj: TObject);
begin
  if Assigned(fOnBeforeQuery) then begin
    TMonitor.Enter(Self);
    try
      fOnBeforeQuery(AQueryObj);
    finally
      TMonitor.Exit(Self);
    end;
  end;
end;

procedure TNSqlManager._DoPostQuery(AQueryObj: TObject);
begin
  if Assigned(fOnPostQuery) then begin
    TMonitor.Enter(Self);
    try
      fOnPostQuery(AQueryObj);
    finally
      TMonitor.Exit(Self);
    end;
  end;
end;

procedure TNSqlManager._AddNewSql(ASql: TNSql);
begin
  if _GetSqlExist(ASql.Name) then
    raise ENSqlScriptInvalid.Create(format('"%s" sql duplicated', [ASql.Name]));
  ASql.DetectSqlType;
  fSqls.Add(ASql.Name, ASql);
end;

function TNSqlManager._GetSqlExist(ASqlName: string): Boolean;
var
  s: TNSql;
begin
  result := fSqls.TryGetValue(ASqlName, s);
end;

function TNSqlManager._GetSql(ASqlName: string): TNSql;
begin
  if not fSqls.TryGetValue(ASqlName, result) then
    raise ENSqlNotDefined.Create(format('SQL "%s" was not defined', [ASqlName]));
end;

function TNSqlManager._GetBeanClassName(ASqlName: String; AQuery: TObject): String;
begin
  result := _GetSql(ASqlName).ResultClassName;
end;

procedure TNSqlManager._SetDefaultQuery(AQueryComponent: TObject);
begin
  if not Assigned(AQueryComponent) then
    fDefaultQueryComponent := nil
  else if not _IsSupportedQuery(AQueryComponent) then
    raise ENSqlQueryComponentNotSupported.Create(format('%s is not supported component', [AQueryComponent.ClassName]))
  else
    fDefaultQueryComponent := AQueryComponent;
end;

procedure TNSqlManager._SetDefaultSQL(ASQLComponent: TObject);
begin
  if not Assigned(ASQLComponent) then
    fDefaultSQLComponent := nil
  else if not _IsSupportedSQL(ASQLComponent) then
    raise ENSqlQueryComponentNotSupported.Create(format('%s is not supported component', [ASQLComponent.ClassName]))
  else
    fDefaultSQLComponent := ASQLComponent;
end;

function TNSqlManager._ParseSql(AStrings: TStrings): Integer;
var
  i, ALineCnt: integer;
  ASql: TNSql;
  ALine, eMsg, dMsg: string;
begin
  i := 0;
  try
    result := 0;
    ASql := nil;
    ALineCnt := AStrings.Count;
    while i < ALineCnt do begin
      ALine := Trim(AStrings.Strings[i]);
      try
        // Ignore magic line & full comment line
        if NPosOfComment(ALine) = 1 then
          Continue;

        // "<sql" Meet. New sql token
        if StartsText(cstSqlStartToken, ALine) then begin

          // 이전 Sql 이 정상적으로 종료되지 않았으므로, 버림.
          if Assigned(ASql) then begin
            _WriteLog(SQL_LOG_WARN, format('Sql item "%s" ignored. Close tag "</sql>" not found.', [ASql.Name]));
            FreeAndNil(ASql);
          end;
          // Start new sql
          ASql := TNSql.Create;
          ASql.SqlMgr := Self;

          // Set name and result of sql
          if not ASql.SetSqlInfo(ALine, eMsg, dMsg) then begin
            if eMsg <> '' then
              _WriteLog(SQL_LOG_WARN, eMsg);
            if dMsg <> '' then
              _WriteLog(SQL_LOG_DEBUG, dMsg);
            FreeAndNil(ASql);
            ASql := nil;
            // Start tag 에 오류가 존재하므로, 새로운 "<Sql" 을 만날때까지 버림.
            Inc(i);
            while i < ALineCnt do begin
              if StartsText(cstSqlStartToken, AStrings[i]) then begin
                Dec(i);
                break;
              end;
              Inc(i);
            end;
          end;
        end

        // "</sql>" meet. A Sql Section is closed.
        else if StartsText(cstSqlEndToken, ALine) then begin
          if Assigned(ASql) then begin
            if ASql.SqlLines.Count > 0 then begin
              _AddNewSql(ASql);
              _WriteLog(SQL_LOG_DEBUG, format('Sql item "%s" parsed.', [ASql.Name]) + ASql.SqlLines.Text);
              Inc(Result);
              ASql := nil;
            end
            else begin
              FreeAndNil(ASql);
              ASql := nil;
            end;
          end;
        end
      
        // Sql Line
        else begin
          if Assigned(ASql) then
            ASql.AddSqlLine(AStrings.Strings[i]);
        end;
      
      finally
        Inc(i);
      end;
    end;

    // Ignore If not ended properly
    if Assigned(ASql) then begin
      _WriteLog(SQL_LOG_WARN, format('Sql item "%s" ignored. Close tag "</sql>" not found.', [ASql.Name]));
      FreeAndNil(ASql);
    end;

  except
    on e: Exception do begin
      _WriteLog(SQL_LOG_WARN, format('Error while _ParseSql(Line=%d)(%s)', [i, e.Message]));
      raise;
    end;
  end;
end;

function TNSqlManager._GetInstanceOf(AClassName: string): TNData;
var
  AnObj: TObject;
begin
  AnObj := TNRtti.ObjectInstance(AClassName);
  if AnObj = nil then
    raise ENSqlClassNotFound.Create(format('Class "%s" not found', [AClassName]));
  if AnObj is TNData then begin
    result := TNData(AnObj);
  end
  else begin
    FreeAndNil(AnObj);
    raise ENSqlClassInvalid.Create(format('Expected descendant of TNData but "%s" found', [AClassName]));
  end;
end;

procedure TNSqlManager.LoadSqlFile(AFile: string);
var
  AStrings: TStringList;
begin
  if FileExists(AFile) then begin
    try
      TNPerf.Start('Loading.Sql.File');
      AStrings := TStringList.Create;
      try
        AStrings.LoadFromFile(AFile);
        if _ParseSql(AStrings) > 0 then begin
          fLoadedSqlFiles.Add(AFile);
        end;
      finally
        AStrings.Free;
        TNPerf.Done('Loading.Sql.File');
      end;
      _WriteLog(SQL_LOG_DEBUG, format('Sql file "%s" loaded', [AFile]));
    except
      on e: Exception do begin
        _WriteLog(SQL_LOG_ERROR, format('Error while LoadSqlFile(%s)(%s)%s', [AFile, e.ClassName, e.Message]));
      end;
    end;
  end
  else
    _WriteLog(SQL_LOG_WARN, format('Sql file "%s" not found', [AFile]));
end;

procedure TNSqlManager.LoadSqlFiles(ADir: String; AExt: string = '*.sql');
var
  FileName: String;
  FilterPredicate: TDirectory.TFilterPredicate;
begin
  FilterPredicate := function(const Path: string; const SearchRec: TSearchRec): Boolean
                       begin
                         Result := (System.IOUtils.TPath.MatchesPattern(SearchRec.Name, AExt{'*.*'}, False));
                         //  (SearchRec.Attr = faAnyFile);
                       end;
  for FileName in TDirectory.GetFiles(ADir, FilterPredicate) do begin
    try
      LoadSqlFile(FileName);
    except
      on e: Exception do begin
        _WriteLog(SQL_LOG_ERROR, format('Error while LoadSqlFiles(%s)(%s)%s', [FileName, e.ClassName, e.Message]));
      end;
    end;
  end;
end;


procedure TNSqlManager.LoadSqlFiles(AFiles: TStrings);
var
  i: Integer;
begin
  for i:=0 to AFiles.Count-1 do begin
    LoadSqlFile(AFiles.Strings[i]);
  end;
end;

procedure TNSqlManager._ValidateQueryComp(AQuery: TObject);
begin
  if not Assigned(AQuery) then
    raise ENSqlException.Create('Query object is not assigned');
  if not _IsSupportedQuery(AQuery) then
    raise ENSqlQueryComponentNotSupported.Create(format('%s is not supported component', [AQuery.ClassName]));
end;

procedure TNSqlManager._ValidateSQLComp(ASQL: TObject);
begin
  if not Assigned(ASQL) then
    raise ENSqlException.Create('Query object is not assigned');
  if not _IsSupportedSQL(ASQL) then
    raise ENSqlQueryComponentNotSupported.Create(format('%s is not supported component', [ASQL.ClassName]));
end;




(*------------------------------------------------------------------------------
  Open dataset
------------------------------------------------------------------------------*)
procedure TNSqlManager._Open(AQuery: TObject; ASqlName: string; AParamObj: TPersistent);
var
  ASql: TNSql;
begin
  TNPerf.Start('SqlMgr.Open.' + ASqlName);
  try
  _ValidateQueryComp(AQuery);
  try
    ASql := _GetSql(ASqlName);                              // Pick sql definition
    TMonitor.Enter(Self);                                   // TNSql item must be handled thread safely
    try
      ASql.PrepareSql(AParamObj);                           // Replace sql.replaceItems. eg. %item%
      _FillParams(AQuery, ASql.PreparedSql, AParamObj);     // Fill sql.params Replace sql.parameters. eg. :Param
    finally
      TMonitor.Exit(Self);
    end;
    _OpenQuery(AQuery);                                     // Open query actually
  except
    on e: Exception do begin
      _WriteLog(SQL_LOG_ERROR, format('Error while _Open(%s)(%s) %s', [ASqlName, e.ClassName, e.Message]));
      raise;
    end;
  end;
  finally
    TNPerf.Done('SqlMgr.Open.' + ASqlName);
  end;
end;


procedure TNSqlManager.Open(AQuery: TObject; ASqlName: string; AParamObj: TPersistent);
begin
  _Open(AQuery, ASqlName, AParamObj);
end;

function TNSqlManager.GetCountOfList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent): Integer;
var
  v: Variant;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  try
    _OpenRecordCount(AQuery, ASqlName, AParamObj, 'RecordCount');
    v := _GetValue(AQuery, 'RecordCount');
    if VarIsNull(v) then
      result := 0
    else
      result := v;
    CloseQuery(AQuery);
    _WriteLog(SQL_LOG_INFO, format('%d records found in sql(%s)', [result, ASqlName]))
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

function TNSqlManager.GetCountOfList(ASqlName: string; AParamObj: TPersistent): Integer;
begin
  TMonitor.Enter(Self);
  try
    StartTransaction(fDefaultQueryComponent);
    try
      Result := GetCountOfList(fDefaultQueryComponent, ASqlName, AParamObj);
    finally
      Commit(fDefaultQueryComponent);
    end;
  finally;
    TMonitor.Exit(Self);
  end;
end;

(*------------------------------------------------------------------------------
  Open query and fetch all records to list
------------------------------------------------------------------------------*)
function TNSqlManager.GetList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; InterProc: TNotifyEvent = nil): TNList;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  try
    _Open(AQuery, ASqlName, AParamObj);
    Result := _GetListFromDataSet(AQuery, _GetBeanClassName(ASqlName, AQuery), InterProc);
    CloseQuery(AQuery);
    if Result <> nil then
      _WriteLog(SQL_LOG_INFO, format('%d records fetched', [result.Count]))
    else
      _WriteLog(SQL_LOG_INFO, 'No record fetched');
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

(* Query with default query object.
   1) must be thread safe
   2) must be auto commit
------------------------------------------------------------------------------*)
function TNSqlManager.GetList(ASqlName: string; AParamObj: TPersistent; InterProc: TNotifyEvent = nil): TNList;
begin
  TMonitor.Enter(Self);
  try
    StartTransaction(fDefaultQueryComponent);
    try
      Result := GetList(fDefaultQueryComponent, ASqlName, AParamObj, InterProc);
    finally
      Commit(fDefaultQueryComponent);
    end;
  finally;
    TMonitor.Exit(Self);
  end;
end;

procedure TNSqlManager.GetList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; AReturnList: TNList; InterProc: TNotifyEvent = nil);
var
  c: Integer;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  try
    c := AReturnList.Count;
    _Open(AQuery, ASqlName, AParamObj);
    _GetListFromDataSet(AQuery, _GetBeanClassName(ASqlName, AQuery), AReturnList, InterProc);
    CloseQuery(AQuery);
    if c < AReturnList.Count then
      _WriteLog(SQL_LOG_INFO, format('%d records fetched', [AReturnList.Count - c]))
    else
      _WriteLog(SQL_LOG_INFO, 'No record fetched');
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

procedure TNSqlManager.GetList(ASqlName: string; AParamObj: TPersistent; AReturnList: TNList; InterProc: TNotifyEvent = nil);
var
  c: Integer;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  try
    c := AReturnList.Count;
    _Open(fDefaultQueryComponent, ASqlName, AParamObj);
    _GetListFromDataSet(fDefaultQueryComponent, _GetBeanClassName(ASqlName, fDefaultQueryComponent), AReturnList, InterProc);
    CloseQuery(fDefaultQueryComponent);
    if c < AReturnList.Count then
      _WriteLog(SQL_LOG_INFO, format('%d records fetched', [AReturnList.Count - c]))
    else
      _WriteLog(SQL_LOG_INFO, 'No record fetched');
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

(*------------------------------------------------------------------------------
  Open query and fetch all records to list
------------------------------------------------------------------------------*)
function TNSqlManager.GetPagedList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; InterProc: TNotifyEvent = nil): TNList;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] Paged.%s', [ASqlName]));
  try
    _OpenPage(AQuery, ASqlName, AParamObj);
    Result := _GetListFromDataSet(AQuery, _GetBeanClassName(ASqlName, AQuery), InterProc);
    CloseQuery(AQuery);
    if Result <> nil then
      _WriteLog(SQL_LOG_INFO, format('%d records fetched', [result.Count]))
    else
      _WriteLog(SQL_LOG_INFO, 'No record fetched');
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] Paged.%s', [ASqlName]));
  end;
end;

(* Query with default query object.
   1) must be thread safe
   2) must be auto commit
------------------------------------------------------------------------------*)
function TNSqlManager.GetPagedList(ASqlName: string; AParamObj: TPersistent; InterProc: TNotifyEvent = nil): TNList;
begin
  TMonitor.Enter(Self);
  try
    StartTransaction(fDefaultQueryComponent);
    try
      Result := GetPagedList(fDefaultQueryComponent, ASqlName, AParamObj, InterProc);
    finally
      Commit(fDefaultQueryComponent);
    end;
  finally;
    TMonitor.Exit(Self);
  end;
end;

procedure TNSqlManager.GetPagedList(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; AReturnList: TNList; InterProc: TNotifyEvent = nil);
var
  c: Integer;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] Paged.%s', [ASqlName]));
  try
    c := AReturnList.Count;
    _OpenPage(AQuery, ASqlName, AParamObj);
    _GetListFromDataSet(AQuery, _GetBeanClassName(ASqlName, AQuery), AReturnList, InterProc);
    CloseQuery(AQuery);
    if c < AReturnList.Count then
      _WriteLog(SQL_LOG_INFO, format('%d records fetched', [AReturnList.Count - c]))
    else
      _WriteLog(SQL_LOG_INFO, 'No record fetched');
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] Paged.%s', [ASqlName]));
  end;
end;

procedure TNSqlManager.GetPagedList(ASqlName: string; AParamObj: TPersistent; AReturnList: TNList; InterProc: TNotifyEvent = nil);
var
  c: Integer;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] Paged.%s', [ASqlName]));
  try
    c := AReturnList.Count;
    _OpenPage(fDefaultQueryComponent, ASqlName, AParamObj);
    _GetListFromDataSet(fDefaultQueryComponent, _GetBeanClassName(ASqlName, fDefaultQueryComponent), AReturnList, InterProc);
    CloseQuery(fDefaultQueryComponent);
    if c < AReturnList.Count then
      _WriteLog(SQL_LOG_INFO, format('%d records fetched', [AReturnList.Count - c]))
    else
      _WriteLog(SQL_LOG_INFO, 'No record fetched');
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] Paged.%s', [ASqlName]));
  end;
end;

procedure TNSqlManager._OpenPage(AQuery: TObject; ASqlName: string; AParamObj: TPersistent);
var
  ASql: TNSql;
begin
  TNPerf.Start('SqlMgr.OpenPage.' + ASqlName);
  try
  _ValidateQueryComp(AQuery);
  try
    ASql := _GetSql(ASqlName);                                  // Pick sql definition
    TMonitor.Enter(Self);                                   // TNSql item must be handled thread safely
    try
      ASql.PrepareSql(AParamObj);                               // Replace sql.replaceItems. eg. %item%
      if SameText(PlatformDB, PLATFORM_DB_SQLITE) then
        _FillParams(AQuery, _WrapPageQuery_Sqlite(ASql.PreparedSql, AParamObj), AParamObj)
      else if SameText(PlatformDB, PLATFORM_DB_FB2) then
        _FillParams(AQuery, _WrapPageQuery_FB(ASql.PreparedSql, AParamObj), AParamObj)
      else if SameText(PlatformDB, PLATFORM_DB_ORA) then
        _FillParams(AQuery, _WrapPageQuery_ORA(ASql.PreparedSql, AParamObj), AParamObj);
    finally
      TMonitor.Exit(Self);
    end;
    _OpenQuery(AQuery);                                       // Open query actually
  except
    on e: Exception do begin
      _WriteLog(SQL_LOG_ERROR, format('Error while _OpenPage(%s)(%s) %s', [ASqlName, e.ClassName, e.Message]));
      raise e;
    end;
  end;
  finally
    TNPerf.Done('SqlMgr.OpenPage.' + ASqlName);
  end;
end;

{ Sql Item must be used exclusivly. because it's sql statements is buit at runtime }
procedure TNSqlManager._OpenRecordCount(AQuery: TObject; ASqlName: string; AParamObj: TPersistent; ACountFieldName: String = 'RecordCount');
var
  ASql: TNSql;
begin
  TNPerf.Start('SqlMgr.OpenRecordCount.' + ASqlName);
  try
  _ValidateQueryComp(AQuery);
  try
    ASql := _GetSql(ASqlName);                                                            // Pick sql definition
    TMonitor.Enter(Self);                                                             // TNSql item must be handled thread safely
    try
      ASql.PrepareSql(AParamObj);                                                         // Replace sql.replaceItems. eg. %item%
      _FillParams(AQuery, _WrapCountQuery(ASql.PreparedSql, ACountFieldName), AParamObj); // Wrap Record Count Query and Fill sql.params Replace sql.parameters. eg. :Param
    finally
      TMonitor.Exit(Self);
    end;
    _OpenQuery(AQuery);                                                                   // Open query actually
  except
    on e: Exception do begin
      _WriteLog(SQL_LOG_ERROR, format('Error while _OpenRecordCount(%s)(%s) %s', [ASqlName, e.ClassName, e.Message]));
      raise;
    end;
  end;
  finally
    TNPerf.Done('SqlMgr.OpenRecordCount.' + ASqlName);
  end;

end;

{ Open query and fetch first record to object. Integer version return the selected row count for convenience }
function TNSqlManager.GetObject(AQuery: TObject; ASqlName: string; AParamObj: TPersistent): TPersistent;
var
  c: Integer;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  try
    Open(AQuery, ASqlName, AParamObj);
    Result := _GetObjectFromDataSet(AQuery, _GetBeanClassName(ASqlName, AQuery));
    c := _GetRecordCountOf(AQuery);
    if c <= 1 then
      _WriteLog(SQL_LOG_INFO, format('%d record fetched', [c]))
    else
      _WriteLog(SQL_LOG_INFO, format('1 record fetched. but more records found(%d totally)', [c]));
    CloseQuery(AQuery);
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

function TNSqlManager.GetObject(AQuery: TObject; ASqlName: string; AParamObj, AResult: TPersistent): integer;
var
  c: Integer;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  try
    Open(AQuery, ASqlName, AParamObj);
    result := _LoadObjectFromDataSet(AQuery, AResult);
    c := _GetRecordCountOf(AQuery);
    if c <= 1 then
      _WriteLog(SQL_LOG_INFO, format('%d record fetched', [c]))
    else
      _WriteLog(SQL_LOG_INFO, format('1 record fetched. but more records found(%d totally)', [c]));
    CloseQuery(AQuery);
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

function TNSqlManager.GetObject(ASqlName: string; AParamObj: TPersistent): TPersistent;
begin
  TMonitor.Enter(Self);
  try
    StartTransaction(fDefaultQueryComponent);
    try
      Result := GetObject(fDefaultQueryComponent, ASqlName, AParamObj);
    finally
      Commit(fDefaultQueryComponent);
    end;
  finally;
    TMonitor.Exit(Self);
  end;
end;

function TNSqlManager.GetObject(ASqlName: string; AParamObj, AResult: TPersistent): integer;
begin
  TMonitor.Enter(Self);
  try
    StartTransaction(fDefaultQueryComponent);
    try
      Result := GetObject(fDefaultQueryComponent, ASqlName, AParamObj, AResult);
    finally
      Commit(fDefaultQueryComponent);
    end;
  finally;
    TMonitor.Exit(Self);
  end;
end;

{ Open query and fetch a field named passed "AFieldName" to variant type }
function TNSqlManager.GetValue(AQuery: TObject; ASqlName, AFieldName: string; AParamObj: TPersistent): variant;
var
  c: Integer;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  try
    Open(AQuery, ASqlName, AParamObj);
    Result := _GetValue(AQuery, AFieldName);
    c := _GetRecordCountOf(AQuery);
    if c <= 1 then
      _WriteLog(SQL_LOG_INFO, format('Field %s (%s) retrieved', [AFieldName, VarToStr(result)]))
    else
      _WriteLog(SQL_LOG_INFO, format('Field %s (%s) retrieved from first record. but more records found(%d totally)', [AFieldName, VarToStr(result), c]));
    CloseQuery(AQuery);
  finally
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

function TNSqlManager.GetValue(ASqlName, AFieldName: string; AParamObj: TPersistent): variant;
begin
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  TMonitor.Enter(Self);
  try
    StartTransaction(fDefaultQueryComponent);
    try
      Result := GetValue(fDefaultQueryComponent, ASqlName, AFieldName, AParamObj);
    finally
      Commit(fDefaultQueryComponent);
    end;
  finally;
    TMonitor.Exit(Self);
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

function TNSqlManager._WrapCountQuery(ASelectSql: String; ACountFieldName: String): String;
begin
  result := 'SELECT COUNT(*) ' + ACountFieldName + ' FROM ( ' + #13#10 +
            ASelectSql +
            ')';
end;

(*==============================================================================
  Wrap select sql -> Paged select sql.
  ** 이 Query 는 반드시 Object Parameter 로만 수행할 수 있습니다.
  ** Row index 처리가 DB 마다 다르므로, Parameter 순서가 달라 Open Array Parameter 로는 수행할 수 없습니다.
  ** Start, End row parameter 비교방법에 주의하십시오.
    -> 0, 10 :: 이렇게 주면 안됩니다. Equal 비교를 수행합니다.
    -> 1, 10 :: OK
  ** Firebird 에서는 Order by 다음에 주므로, 주의해야 합니다.
     Sql 이 Parsing 된 이후에 Wrapping 을 하므로 여기에서 SortFields 를 사용할 수 없습니다.
*==============================================================================*)
function TNSqlManager._WrapPageQuery_ORA(ASelectSql: String; AParamObj: TPersistent): String;
begin
  if Assigned(AParamObj) and (AParamObj.InheritsFrom(TNSqlData)) then begin
    with TNSqlData(AParamObj) do
      result := 'SELECT * FROM ' + #13#10 +
                '  (SELECT RowNum RNUM, PageQuery_.* FROM (' + #13#10 +
                ASelectSql +
                format('         ) PageQuery_ ' + #13#10 +
                       '    WHERE RowNum <= :%d) ' + #13#10 +
                       ' WHERE RNUM >= :%d ', [RecordsPerPage * (Page - 1) + 1, RecordsPerPage * RecordsPerPage]);
  end
  else
    raise ENSqlClassInvalid.Create('Invalid page sql parameter. TNSqlData expected');
end;

function TNSqlManager._WrapPageQuery_Sqlite(ASelectSql: String; AParamObj: TPersistent): String;
begin
  if Assigned(AParamObj) and (AParamObj.InheritsFrom(TNSqlData)) then begin
    with TNSqlData(AParamObj) do
      result := 'SELECT * FROM (' + #13#10 +
                 ASelectSql +
                ') PageQuery_ ' + #13#10 +
                'ORDER BY ' + IfThen(SortFields = '', '1', SortFields) + #13#10 +
                format('LIMIT %d, %d', [RecordsPerPage * (Page - 1), RecordsPerPage]);
  end
  else
    raise ENSqlClassInvalid.Create('Invalid page sql parameter. TNSqlData expected');
end;

(*==============================================================================
  Wrap select sql -> Paged select sql.
  ** On firebird, we have to use "order by" clause to use paged query
  ** SQL syntax : Order by %fields% ROWS :From TO :To
     That is, ParamObj must have "SortFields" property and values
  ** if paramObj has not SortFields value, then we use "order by 1" forcely
*==============================================================================*)
function TNSqlManager._WrapPageQuery_FB(ASelectSql: String; AParamObj: TPersistent): String;
begin
  if Assigned(AParamObj) and (AParamObj.InheritsFrom(TNSqlData)) then begin
    with TNSqlData(AParamObj) do
        result := 'SELECT * FROM (' + #13#10 +
                  ASelectSql +
                  ') PageQuery_ ' + #13#10 +
                  ' ORDER BY ' + IfThen(SortFields = '', '1', SortFields) + #13 +
                  format(' ROWS :%s TO :%s', [RecordsPerPage * (Page - 1) + 1, RecordsPerPage * RecordsPerPage]);
  end
  else
    raise ENSqlClassInvalid.Create('Invalid page sql parameter. TNSqlData expected');
end;


procedure TNSqlManager.CloseQuery(AQuery: TObject);
begin
  raise ENSqlException.Create(format('%s.CloseQuery() was not implemented', [ClassName]));
end;

{ Execute SQL script. It should return the affected row count }
function TNSqlManager.Execute(ASqlComp: TObject; ASqlName: string; AParamObj: TPersistent;
                              AllowZeroOnRemoteSql: Boolean = false): integer;
var
  ASql: TNSql;
begin
  result := 0;
  _WriteLog(SQL_LOG_ENTER, format('[SQL] %s', [ASqlName]));
  TNPerf.Start('SqlMgr.Execute.' + ASqlName);
  try
    _ValidateSQLComp(ASqlComp);
    try
      ASql := _GetSql(ASqlName);                                    // Find proper sql definition. If not found exception will be raised
      TMonitor.Enter(Self);                                         // Thread safe
      try
        ASql.PrepareSql(AParamObj);                                 // Replace sql.replaceItems. eg. %item%
        _FillParams(ASqlComp, ASql.PreparedSql, AParamObj);         // Fill sql.params Replace sql.parameters. eg. :Param
      finally
        TMonitor.Exit(Self);
      end;
      result := _ExcuteQuery(ASqlComp);                             // Step 5. Excute query actually
      _WriteLog(SQL_LOG_INFO, format('%d rows affected', [result]));
    except
      on e: Exception do begin
        _WriteLog(SQL_LOG_ERROR, format('Error while Execute(%s)(%s) %s', [ASqlName, e.ClassName, e.Message]));
        raise;
      end;
    end;
  finally
    TNPerf.Done('SqlMgr.Execute.' + ASqlName);
    _WriteLog(SQL_LOG_EXIT, format('[SQL] %s', [ASqlName]));
  end;
end;

function TNSqlManager.Execute(ASqlName: string; AParamObj: TPersistent;
                              AllowZeroOnRemoteSql: Boolean = false): integer;
begin
  TMonitor.Enter(Self);
  try
    StartTransaction(fDefaultSqlComponent);
    try
      Result := Execute(fDefaultSqlComponent, ASqlName, AParamObj, AllowZeroOnRemoteSql);
    finally
      Commit(fDefaultSqlComponent);
    end;
  finally;
    TMonitor.Exit(Self);
  end;
end;

procedure TNSqlManager.ReplaceInternalTableFields;
var
  k: String;
begin
  TMonitor.Enter(Self);
  try
    TMonitor.Enter(Self);
    try
      for k in fSqls.Keys do
        _ReplaceTableFieldsItem(fSqls.Items[k]);
    finally
      TMonitor.Exit(Self);
    end;
  finally
    fInitialized := true;
    TMonitor.Exit(Self);
  end;
end;

procedure TNSqlManager.PrintDebug(AStrings: TStrings);
var
  i: Integer;
  k: String;
begin
  TMonitor.Enter(Self);
  try
    AStrings.Add(format(' >>> Sql Manager Class %s debug <<<', [ClassName]));
    AStrings.Add(format(' -> Default query = %s', [GetClassName(fDefaultQueryComponent)]));
    AStrings.Add(format(' -> Default sql = %s',   [GetClassName(fDefaultSqlComponent)]));
    AStrings.Add(format(' -> Loaded sql files = %d', [fLoadedSqlFiles.Count]));
    AStrings.AddStrings(fLoadedSqlFiles);
    AStrings.Add(format(' -> Cached inline replace items = %d', [fInlineReplaceCache.Count]));
    AStrings.AddStrings(fInlineReplaceCache);
    i := 1;
    for k in fSqls.Keys do begin
      AStrings.Add(format(' -> %d''th query ---', [i]));
      fSqls.Items[k].PrintDebug(AStrings, '   ');
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

function _SortByName(item1, item2: Pointer): Integer;
begin
  result := CompareText(TNSql(item1).Name, TNSql(item2).Name);
end;

function TNSqlManager._ExcuteQuery(ASql: TObject): Integer;
begin
  result := 0;
end;

procedure TNSqlManager._FillParams(AQueryOrSQL: TObject; ASql: String; AParamObj: TPersistent);
begin
  raise ENSqlException.Create(format('%s did not implement _FillParams()', [ClassName]));
end;

procedure TNSqlManager._FillParams(AQueryOrSQL: TObject; ASql: String; AParams: Array of String);
begin
  raise ENSqlException.Create(format('%s did not implement _FillParams()', [ClassName]));
end;

{procedure TNSqlManager._GetParamList(AQueryOrSQL: TObject; ASql: String; AParams: TStrings);
begin
  raise ENSqlException.Create(format('%s did not implement _GetParamList()', [ClassName]));
end;
}
function TNSqlManager._GetListFromDataSet(AQuery: TObject; AResultClassName: string; InterProc: TNotifyEvent = nil): TNList;
begin
  raise ENSqlException.Create(format('%s did not implement _GetListFromDataSet()', [ClassName]));
end;

procedure TNSqlManager._GetListFromDataSet(AQuery: TObject; AResultClassName: string; AReturnList: TNList; InterProc: TNotifyEvent = nil);
begin
  raise ENSqlException.Create(format('%s did not implement _GetListFromDataSet()', [ClassName]));
end;


{function TNSqlManager._GetObjectXMLFromDataSet(AQuery: TObject; AxmlRecID: string): String;
begin
  raise ENSqlException.Create(format('%s did not implement _GetObjectXMLFromDataSet()', [ClassName]));
end;

function TNSqlManager._GetListXMLFromDataSet(AQuery: TObject; AxmlRecID, AxmlRecCountID: string): String;
begin
  raise ENSqlException.Create(format('%s did not implement _GetXMLFromDataSet()', [ClassName]));
end;

function TNSqlManager._GetComboXMLFromDataSet(AQuery: TObject; AxmlRecID: string): String;
begin
  raise ENSqlException.Create(format('%s did not implement _GetComboXMLFromDataSet()', [ClassName]));
end;

function TNSqlManager._GetComboListXMLFromDataSet(AQuery: TObject; AxmlRecID, AxmlRecCountID: string): String;
begin
  raise ENSqlException.Create(format('%s did not implement _GetComboListXMLFromDataSet()', [ClassName]));
end;
}
function TNSqlManager._GetObjectFromDataSet(AQuery: TObject; AResultClassName: string): TNData;
begin
  raise ENSqlException.Create(format('%s did not implement _GetObjectFromDataSet()', [ClassName]));
end;

function TNSqlManager._GetValue(AQuery: TObject; AFieldName: string = ''): variant;
begin
  raise ENSqlException.Create(format('%s did not implement _GetValue()', [ClassName]));
end;

function TNSqlManager._IsSupportedQuery(AQuery: TObject): Boolean;
begin
  raise ENSqlException.Create(format('%s did not implement _IsSupportedQuery()', [ClassName]));
end;

function TNSqlManager._IsSupportedSQL(ASQL: TObject): Boolean;
begin
  raise ENSqlException.Create(format('%s did not implement _IsSupportedSQL()', [ClassName]));
end;

function TNSqlManager._LoadObjectFromDataSet(AQuery: TObject; AResult: TPersistent): integer;
begin
  raise ENSqlException.Create(format('%s did not implement _LoadObjectFromDataSet()', [ClassName]));
end;

procedure TNSqlManager._OpenQuery(AQuery: TObject);
begin
  raise ENSqlException.Create(format('%s did not implement _OpenQuery()', [ClassName]));
end;


{ TKPageInfo }

procedure TKPageInfo.SetRecordCountPerPage(const Value: Integer);
begin
  if Value < 1 then
    raise Exception.Create('Record count per page must be greater than 0');
  if fRecordCountPerPage <> value then
    fRecordCountPerPage := Value;
end;

function TKPageInfo.GetPageCount: Integer;
begin
  result := fTotalRecordCount div fRecordCountPerPage;
  if fTotalRecordCount mod fRecordCountPerPage > 0 then
    Inc(result);
  if result < 0 then
    result := 0;
end;

// database rownum or rows is based on 1.  Page is based on 1 also
// database did not allow 0 as rownum or rows parameter
function TKPageInfo.GetStartRow: Integer;
begin
  result := (fPage - 1) * fRecordCountPerPage + 1;
  if result < 1 then
    result := 1;
end;

function TKPageInfo.GetEndRow: Integer;
begin
  result := fPage * fRecordCountPerPage;
  if result > fTotalRecordCount then
    result := fTotalRecordCount;
  if result < 1 then
    result := 1;
end;                            

procedure TKPageInfo.SetPage(const Value: Integer);
begin
  if (fTotalRecordCount > 0) and (Value < 1) then
    raise Exception.Create('Record count per page must be greater than 0');
  if fPage <> value then
    fPage := Value;
end;

procedure TKPageInfo.SetTotalRecordCount(const Value: Integer);
begin
  if fTotalRecordCount <> value then
    fTotalRecordCount := Value;
end;

constructor TKPageInfo.Create;
begin
  inherited Create;
  fRecordCountPerPage := 10;
  fTotalRecordCount := 0;
  fPage := 1;
end;

function TKPageInfo.GetCurrPageRecordCount: Integer;
begin
  if fPage * fRecordCountPerPage > fTotalRecordCount then
    result := fTotalRecordCount - ((fPage - 1) * fRecordCountPerPage)
  else
    result := fRecordCountPerPage;
end;

function TNSqlManager._GetSqlCount: Integer;
begin
  result := fSqls.Count;
end;


{ TKTableBeanFieldMapper }

constructor TKTableBeanFieldMapper.Create;
begin
  fTableBeanMapper := TDictionary<String, String>.Create;       // TableName=QualifiedBeanClassName
  fBeanTableMapper := TDictionary<String, String>.Create;       // QualifiedBeanClassName=TableName
  fTableBeanFieldMapper := TDictionary<String, String>.Create;  // TableName.FieldName=BeanFieldName
  fBeanTableFieldMapper := TDictionary<String, String>.Create;
end;

destructor TKTableBeanFieldMapper.Destroy;
begin
  FreeAndNil(fTableBeanMapper);
  FreeAndNil(fBeanTableMapper);
  FreeAndNil(fTableBeanFieldMapper);
  FreeAndNil(fBeanTableFieldMapper);
  inherited;
end;

function TKTableBeanFieldMapper.GetMappedBean(ATableName: String): String;
begin
  if not fTableBeanMapper.TryGetValue(ATableName, result) then
    result := ATableName;
end;

function TKTableBeanFieldMapper.GetMappedBeanField(ATableNameDotField: String): String;
begin
  if not fTableBeanFieldMapper.TryGetValue(ATableNameDotField, result) then
    result := ATableNameDotField;
end;

function TKTableBeanFieldMapper.GetMappedTable(AQualifiedBeanClazz: String): String;
begin
  if not fBeanTableMapper.TryGetValue(AQualifiedBeanClazz, result) then
    result := AQualifiedBeanClazz;
end;

function TKTableBeanFieldMapper.GetMappedTableField(AQualifiedBeanClazzDotField: String): String;
begin
  if not fBeanTableFieldMapper.TryGetValue(AQualifiedBeanClazzDotField, result) then
    result := AQualifiedBeanClazzDotField;
end;

procedure TKTableBeanFieldMapper.LoadMappingFile(f: String);
var
  i: Integer;
  AnIni: TIniFile;
  ASections: TStringList;
  AValues: TStringList;
  S: String;
begin
  TMonitor.Enter(Self);
  try
    if not FileExists(f) then
      Exit;
    AnIni := TIniFile.Create(f);
    ASections := TStringList.Create;
    AValues := TStringList.Create;
    try
      AnIni.ReadSections(ASections);
      for s in ASections do begin
        AValues.Clear;
        AnIni.ReadSectionValues(s, AValues);
        // TableName=QualifiedClassName
        // Bean class must be qualified name
        if SameText(s, 'Tables') then begin
          for i:=0 to AValues.Count-1 do begin
            fTableBeanMapper.Add(AValues.Names[i], AValues.ValueFromIndex[i]);
            fBeanTableMapper.Add(AValues.ValueFromIndex[i], AValues.Names[i]);
          end;
        end
        // TableName.FieldName=QualifiedClassName.FieldName
        // Bean class must be qualified name
        else if SameText(s, 'Fields') then begin
          for i:=0 to AValues.Count-1 do begin
            fTableBeanFieldMapper.Add(AValues.Names[i], AValues.ValueFromIndex[i]);
            fBeanTableFieldMapper.Add(AValues.ValueFromIndex[i], AValues.Names[i]);
          end;
        end;
      end;
    finally
      FreeAndNil(ASections);
      FreeAndNil(AValues);
      FreeAndNil(AnIni);
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;


end.


