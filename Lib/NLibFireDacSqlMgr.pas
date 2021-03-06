unit NLibFireDacSqlMgr;

interface

uses
  WinApi.Windows, System.SysUtils, System.Classes, TypInfo, SqlTimSt,
  System.Rtti, Variants,
  DBConsts, DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  NBaseClass, NBaseRtti, NLibString, NLibSqlMgr;

type

  { Sql Manager for FireDAC }
  TNFDSqlMgr = class(TNSqlManager)
  public
    { Default Sql Component Transation Support }
    procedure StartTransaction(AComp: TObject); override;
    procedure Commit(AComp: TObject); override;
    procedure Rollback(AComp: TObject); override;
  protected
    fCLOBFields: TStringList;
    fBLOBFields: TStringList;
    function _GetConcatedCols_Sqlite(AQuery: TFDQuery; ATableName, AFieldName: String): String;
    function _GetConcatedCols(AQuery: TFDQuery; ATableName, AFieldName: String): String;
    procedure _ReplaceTableFieldsItem(ASql: TNSql); override;
    function _GetRecordCountOf(AQuery: TObject): Integer; override;
    { Define your component to support }
    function _IsSupportedQuery(AQuery: TObject): Boolean; override;
    function _IsSupportedSQL(ASQL: TObject): Boolean; override;
    { Fill Sql.params of UniDAC components }
    procedure _FillParams(AQueryOrSQL: TObject; ASql: String; AParamObj: TPersistent); override;
    procedure _FillParams(AQueryOrSQL: TObject; ASql: String; AParams: Array of String); override;
//    procedure _GetParamList(AQueryOrSQL: TObject; ASql: String; AParams: TStrings); override;
    { Open, execute sql statement }
    procedure _OpenQuery(AQuery: TObject); override;
    function _ExcuteQuery(ASql: TObject): Integer; override;
    { Load dataset to list, object }
    function _LoadObjectFromDataSet(AQuery: TObject; AResult: TPersistent): integer; override;
    function _GetObjectFromDataSet(AQuery: TObject; AResultClassName: string): TNData; override;
    function _GetListFromDataSet(AQuery: TObject; AResultClassName: string; InterProc: TNotifyEvent = nil): TNList; overload; override;
    procedure _GetListFromDataSet(AQuery: TObject; AResultClassName: string; AReturnList: TNList; InterProc: TNotifyEvent = nil); overload; override;
    { Get Value }
    function _GetValue(AQuery: TObject; AFieldName: string = ''): Variant; override;

    function _GetConnected: Boolean; override;
    procedure _SetConnected(value: Boolean); override;
    function _GetLastSqlRtcAborted: Boolean; override;
  public
    constructor Create(AOwner: TComponent; ADBPlatform, ANodeName: String); override;
    destructor Destroy; override;
    procedure CloseQuery(AQuery: TObject); override;
    function TnxIsActive(AQueryObj: TObject; var eCode: String): Boolean; override;
    function IsAvailableObject(ASqlOrQueryObj: TObject): Boolean; override;
    function GetLastAutoIncrement: Int64; override;
    class function IOType: TNSqlManagerType; override;
  end;

implementation

uses System.StrUtils, System.Math, System.DateUtils, NLibDateTime;

{ TNFDSqlMgr }

(*==============================================================================
  Replace internal reserved word
   Format. Do not use space
    ** $AsColumns.#TableName#.ColPrefix.'ExceptCol1','ExceptCol2'
    ** $AsUpdate.#TableName#.ColPrefix.'ExceptCol1','ExceptCol2'
    ** $AsParams.#TableName#.'ExceptCol1','ExceptCol2'
   Ex
    ** AsColumns.TH_Rental.A.'LastUpdateTimeS'
   Cach item name
   ** TableName.ExceptCols
   ** Update.TableName.ExceptCols
==============================================================================*)
const
  _Sql_GetFbTableCols: String =
       'SELECT trim(Column_Name) PropName, ' +
              '''?'' || trim(Column_Name) COL, ' +
              '''?'' || trim(Column_Name) || '' = :'' || trim(Column_Name) UPDATE_COL, ' +
              'DATA_TYPE ' +
         'FROM ALL_TAB_COLUMNS ' +
        'WHERE Table_Name = Upper(''%s'') ' +    // {1} TableName
             ' %s ' +                            // {2} 'AND NOT COLUMN_NAME IN (''%s'') '  Must be uppercase
    ' ORDER BY COLUMN_ID ';

  _Sql_GetOraTableCols: String =
       'SELECT trim(Column_Name) PropName, ' +
              '''?'' || trim(Column_Name) COL, ' +
              '''?'' || trim(Column_Name) || '' = :'' || trim(Column_Name) UPDATE_COL, ' +
              'DATA_TYPE ' +
         'FROM ALL_TAB_COLUMNS ' +
        'WHERE Owner = (select USERNAME from v$session where audsid = USERENV(''SessionId'')) ' +
         ' AND Table_Name = Upper(''%s'') ' +    // {1} TableName
             ' %s ' +                            // {2} 'AND NOT COLUMN_NAME IN (''%s'') '  Must be uppercase
       ' ORDER BY COLUMN_ID ';


(* Check
------------------------------------------------------------------------------*)
constructor TNFDSqlMgr.Create(AOwner: TComponent; ADBPlatform, ANodeName: String);
begin
  inherited Create(AOwner, ADBPlatform, ANodeName);
  fCLOBFields := TStringList.Create;
  fCLOBFields.Sorted := true;
  fCLOBFields.Duplicates := dupIgnore;
  fBLOBFields := TStringList.Create;
  fBLOBFields.Sorted := true;
  fBLOBFields.Duplicates := dupIgnore;
end;

destructor TNFDSqlMgr.Destroy;
begin
  fCLOBFields.Free;
  fBLOBFields.Free;
  inherited;
end;

function TNFDSqlMgr._GetConnected: Boolean;
begin
  result := Assigned(fDefaultQueryComponent) and
           (fDefaultQueryComponent is TFDQuery) and
           (TFDQuery(fDefaultQueryComponent).Connection <> nil) and
           (TFDQuery(fDefaultQueryComponent).Connection.Connected);
end;

procedure TNFDSqlMgr._SetConnected(value: Boolean);
begin
  if Assigned(fDefaultQueryComponent) and
    (fDefaultQueryComponent is TFDQuery) and
    (TFDQuery(fDefaultQueryComponent).Connection <> nil) then begin
    if not TFDQuery(fDefaultQueryComponent).Connection.Connected then
      try
        TFDQuery(fDefaultQueryComponent).Connection.Connected := true;
      except
      end;
  end;
end;

function TNFDSqlMgr._GetLastSqlRtcAborted: Boolean;
begin
  result := false;
end;

function TNFDSqlMgr.TnxIsActive(AQueryObj: TObject; var eCode: String): Boolean;
begin
  result := false;
  if AQueryObj is TFDQuery then begin
    with TFDQuery(AQueryObj) do begin
      if Connection = nil then
        raise ENSqlException.Create('Connection object is not assigned');
      if Connection.Connected then begin
        if Transaction <> nil then
          result := Transaction.Active
        else
          result := Connection.InTransaction;
        if not result then
          eCode := 'Busy';
      end
      else
        eCode := 'Not connected';
    end;
  end
  else if AQueryObj is TFDCommand then begin
    with TFDCommand(AQueryObj) do begin
      if Connection = nil then
        raise ENSqlException.Create('Connection object is not assigned');
      if Connection.Connected then begin
        if Transaction <> nil then
          result := Transaction.Active
        else
          result := Connection.InTransaction;
        if not result then
          eCode := 'Busy';
      end
      else
        eCode := 'Not connected';
    end;
  end
  else
    eCode := 'Not supported query object';
end;

function TNFDSqlMgr.IsAvailableObject(ASqlOrQueryObj: TObject): Boolean;
begin
  result := Assigned(ASqlOrQueryObj) and
           (((ASqlOrQueryObj is TFDQuery) and (TFDQuery(ASqlOrQueryObj).Connection <> nil) and TFDQuery(ASqlOrQueryObj).Connection.Connected)) or
            ((ASqlOrQueryObj is TFDCommand) and (TFDCommand(ASqlOrQueryObj).Connection <> nil) and TFDCommand(ASqlOrQueryObj).Connection.Connected);
end;

function _CorrectExceptCols(AExceptCols: String): String;
var
  i: Integer;
  AStrList: TStringList;
begin
  AStrList := TStringList.Create;
  try
    NExtractStrings(',', AExceptCols, AStrList);
    for i:=0 to AStrList.Count-1 do
      AStrList.Strings[i] := NQuoteSide(NDeQuoteSide(AStrList.Strings[i], '"'));
    result := '';
    for i:=0 to AStrList.Count-1 do
      NConcatP(result, AStrList.Strings[i], ',');
  finally
    AStrList.Free;
  end;
end;

procedure TNFDSqlMgr._ReplaceTableFieldsItem(ASql: TNSql);

  function _AsCacheItemName(APrefix, ATableName, AExceptCols: String): String;
  begin
    if APrefix <> '' then
      result := format('%s.%s.%s', [APrefix, ATableName, AExceptCols])
    else
      result := format('%s.%s', [ATableName, AExceptCols]);
  end;

  function _BuildQuery(ATableName, AExceptCols: String): String;
  begin
    if AExceptCols <> '' then
      AExceptCols := format(' AND NOT COLUMN_NAME IN (%s) ', [Uppercase(AExceptCols)]);
    result := format(IfThen(SameText(PlatformDB, 'ORA'), _Sql_GetOraTableCols, _Sql_GetFbTableCols), [ATableName, AExceptCols]);
  end;

var
  i, k: Integer;
  AStrings: TStringList;
  ASqlStr, AReplaceItem, APrefix, ATableName, AColPrefix, AExceptCols, TmpStr: String;
begin
  if not Assigned(fInlineReplaceCache) then
    fInlineReplaceCache := TStringList.Create;

  AStrings := TStringList.Create;
  try
    for i:=ASql.ReplaceItems.Count-1 downto 0 do begin
      ATableName := '';
      AReplaceItem := '';
      APrefix := '';
      if StartsText('AsColumns.', ASql.ReplaceItems[i]) then begin
        AReplaceItem := ASql.ReplaceItems[i];
        AStrings.Clear;
        NExtractStrings('.', Trim(AReplaceItem), AStrings, true, false);
        ATableName := AStrings[1];
        if (AStrings.Count > 2) and (AStrings[2] <> '') then
          AColPrefix  := AStrings[2] + '.'
        else
          AColPrefix := '';
        if AStrings.Count > 3 then AExceptCols := AStrings[3] else
          AExceptCols := '';
      end
      else if StartsText('AsParams.', ASql.ReplaceItems[i]) then begin
        AReplaceItem := ASql.ReplaceItems[i];
        AStrings.Clear;
        NExtractStrings('.', Trim(AReplaceItem), AStrings, true, false);
        ATableName := AStrings[1];
        AColPrefix := ':';
        if AStrings.Count > 2 then AExceptCols := AStrings[2] else
          AExceptCols := '';
      end
      else if StartsText('AsUpdate.', ASql.ReplaceItems[i]) then begin
        APrefix := 'Update';
        AReplaceItem := ASql.ReplaceItems[i];
        AStrings.Clear;
        NExtractStrings('.', Trim(AReplaceItem), AStrings, true, false);
        ATableName := AStrings[1];
        if AStrings.Count > 2 then AColPrefix  := AStrings[2] else
          AColPrefix := '';
        if AStrings.Count > 3 then AExceptCols := AStrings[3] else
          AExceptCols := '';
      end;
      if AExceptCols <> '' then
        AExceptCols := _CorrectExceptCols(AExceptCols);

      if AReplaceItem <> '' then begin
        if fInlineReplaceCache.IndexOfName(_AsCacheItemName(APrefix, ATableName, AExceptCols)) < 0 then begin
          if SameText(PlatformDB, PLATFORM_DB_SQLITE) then begin
            TmpStr := _GetConcatedCols_Sqlite(TFDQuery(DefaultQuery), ATableName, 'COL');
            if TmpStr <> '' then
              fInlineReplaceCache.Add(format('%s=%s', [_AsCacheItemName('', ATableName, AExceptCols), TmpStr]));
            TmpStr := _GetConcatedCols_Sqlite(TFDQuery(DefaultQuery), ATableName, 'UPDATE_COL');
            if TmpStr <> '' then
              fInlineReplaceCache.Add(format('%s=%s', [_AsCacheItemName('Update', ATableName, AExceptCols), TmpStr]));
          end
          else begin
            with TFDQuery(DefaultQuery) do begin
              if Active then
                TFDQuery(DefaultQuery).Close;
              Sql.Text := _BuildQuery(ATableName, AExceptCols);
              Prepare;
              Open;
              if IsEmpty then begin
                _WriteLog(SQL_LOG_ERROR, format('Sql(%s) script invalid. Internal replace item "%s" can not be handled', [ASql.Name, AReplaceItem]));
                Close;
              end;

              TmpStr := _GetConcatedCols(TFDQuery(DefaultQuery), ATableName, 'COL');
              if TmpStr <> '' then
                fInlineReplaceCache.Add(format('%s=%s', [_AsCacheItemName('', ATableName, AExceptCols), TmpStr]));
              TmpStr := _GetConcatedCols(TFDQuery(DefaultQuery), ATableName, 'UPDATE_COL');
              if TmpStr <> '' then
                fInlineReplaceCache.Add(format('%s=%s', [_AsCacheItemName('Update', ATableName, AExceptCols), TmpStr]));
            end;
          end;
        end;

        ASqlStr := StringReplace(fInlineReplaceCache.Values[_AsCacheItemName(APrefix, ATableName, AExceptCols)],
                                 '?', AColPrefix, [rfReplaceAll]);
        if ASqlStr = '' then begin
          _WriteLog(SQL_LOG_ERROR, format('Sql(%s) script invalid. Internal replace item "%s" can not be handled', [ASql.Name, AReplaceItem]));
        end
        else begin
          _WriteLog(SQL_LOG_DEBUG, format('Sql(%s)''s inplace item "%s" replaced to %s', [ASql.Name, AReplaceItem, ASqlStr]));
          for k:=0 to ASql.SqlLines.Count-1 do
            ASql.SqlLines[k] := StringReplace(ASql.SqlLines[k], '&' + AReplaceItem + '&', ASqlStr, [rfReplaceAll, rfIgnoreCase]);
        end;
        ASql.ReplaceItems.Delete(i);
      end;
    end;
  finally
    AStrings.Free;
    if TFDQuery(DefaultQuery).Active then
      TFDQuery(DefaultQuery).Close;
  end;
end;

function TNFDSqlMgr._GetRecordCountOf(AQuery: TObject): Integer;
begin
  if AQuery is TFDQuery then begin
    if TFDQuery(AQuery).Active and (not TFDQuery(AQuery).IsEmpty) then
      Exit(TFDQuery(AQuery).RecordCount)
    else
      Exit(0);
  end
  else if AQuery is TFDCommand then begin
    if TFDCommand(AQuery).Active then
      Exit(TFDCommand(AQuery).RowsAffected)
    else
      Exit(0);
  end;
end;

function TNFDSqlMgr.GetLastAutoIncrement: Int64;
begin
  if fDefaultQueryComponent is TFDQuery then begin
    result := TFDQuery(fDefaultQueryComponent).Connection.GetLastAutoGenValue('');
  end
  else
    result := 0;
end;

function TNFDSqlMgr._GetConcatedCols_Sqlite(AQuery: TFDQuery; ATableName, AFieldName: String): String;
var
  i, c: Integer;
  rType: TRttiType;
  rMember: TRttiMember;
  AFieldNames: TStringList;
  S: String;
begin
  result := '';
  rType := TNRtti.RttiCtx.FindType(fTableBeanMapper.MappedBean[ATableName]);
  if Assigned(rType) then begin
    if not rType.ClassType.InheritsFrom(TNData) then begin
      _WriteLog(SQL_LOG_WARN, format('Bean class "%s" was not inherited from TNData', [rType.Name]));
      Exit;
    end;
  end
  else begin
    _WriteLog(SQL_LOG_WARN, format('Bean class "%s" not found', [fTableBeanMapper.MappedBean[ATableName]]));
    Exit;
  end;

  AFieldNames := TStringList.Create;
  AQuery.Connection.GetFieldNames('', '', ATableName, '', AFieldNames);
  c := 0;
  for i:=0 to AFieldNames.Count-1 do begin
    S := fTableBeanMapper.MappedBeanField[NConcat(ATableName, AFieldNames.Strings[i], '.')];
    rMember := TNRtti.GetMember(rType, S);
    if rMember = nil then begin
      _WriteLog(SQL_LOG_WARN, format('Property "%s.%s" was not implemented', [rType.Name, S]));
      Continue;
    end;
    if (c <> 0) and (c mod 5 = 0) then
      result := result + #13#10;
    // ?field1, ?field2, ?field3
    if SameText(AFieldName, 'COL') then
       NConcatP(result, '?' + AFieldNames.Strings[i], ', ')
    // ?field1 = :field1, ?field2 = :field2
    else
       NConcatP(result, '?' + format('%s = :%s', [AFieldNames.Strings[i], AFieldNames.Strings[i]]), ', ');
    Inc(c);
  end;
end;

function TNFDSqlMgr._GetConcatedCols(AQuery: TFDQuery; ATableName, AFieldName: String): String;
var
  i: Integer;
  rType: TRttiType;
  rMember: TRttiMember;
  AFieldNames: TStringList;
  S: String;
begin
  result := '';
  rType := TNRtti.RttiCtx.FindType(fTableBeanMapper.MappedBean[ATableName]);
  if Assigned(rType) then begin
    if not rType.ClassType.InheritsFrom(TNData) then begin
      _WriteLog(SQL_LOG_WARN, format('Bean class "%s" was not inherited from TNData', [rType.Name]));
      Exit;
    end;
  end
  else begin
    _WriteLog(SQL_LOG_WARN, format('Bean class "%s" not found', [fTableBeanMapper.MappedBean[ATableName]]));
    Exit;
  end;
  i := 0;
  with AQuery do begin
    if Active then
      First;
    while not Eof do begin

      (*========================================================================
       데이터베이스 테이블 필드중 Property 로 구현되지 않은 것은 제외합니다.
       -- 데이터베이스 변경과 실행파일 변경이 동시에 이루어지지 않을 경우 오류 방지를 위함.
      ========================================================================*)
      S := fTableBeanMapper.MappedBeanField[NConcat(ATableName, AFieldNames.Strings[i], '.')];
      rMember := TNRtti.GetMember(rType, S);
      if rMember = nil then begin
        _WriteLog(SQL_LOG_WARN, format('Property "%s.%s" was not implemented', [rType.Name, S]));
        Continue;
      end;

      if (i <> 0) and (i mod 5 = 0) then
        result := result + #13#10;
      Inc(i);
      NConcatP(result, AQuery.FieldByName(AFieldName).AsString, ', ');
      if SameText(FieldByName('DATA_TYPE').AsString, 'CLOB') then
        fCLOBFields.Add(FieldByName('PropName').AsString)
      else if SameText(FieldByName('DATA_TYPE').AsString, 'BLOB') then
        fBLOBFields.Add(FieldByName('PropName').AsString);
      Next;
    end;
  end;
end;

function TNFDSqlMgr._IsSupportedQuery(AQuery: TObject): Boolean;
begin
  result := AQuery is TFDQuery;
end;

function TNFDSqlMgr._IsSupportedSQL(ASQL: TObject): Boolean;
begin
  result := (ASQL is TFDQuery) or (ASQL is TFDCommand);
end;

procedure TNFDSqlMgr.CloseQuery(AQuery: TObject);
begin
  if (AQuery is TFDQuery) and (TFDQuery(AQuery).Active) then begin
    TFDQuery(AQuery).Close;
  end
  else
    _WriteLog(SQL_LOG_WARN, format('%s is not support close() routine', [AQuery.ClassName]));
end;

function TNFDSqlMgr._GetValue(AQuery: TObject; AFieldName: string): Variant;
begin
  with TFDQuery(AQuery) do begin
    if (not Active) or IsEmpty then begin
      result := Null;
      Exit;
    end
    else begin
      if AFieldName <> '' then
        result := FieldByName(AFieldName).Value
      else if Fields.Count > 0 then
        result := Fields[0].Value
      else
        raise EDatabaseError.Create(SFieldNameMissing);
    end;
  end;
end;

(*==============================================================================
  Load dataset record to object. return value is loaded property count
==============================================================================*)
function TNFDSqlMgr._LoadObjectFromDataSet(AQuery: TObject; AResult: TPersistent): integer;
var
  i: integer;
  rType: TRttiType;
  rMember: TRttiMember;
  AValue: Variant;
  la: Largeint;
begin
  Result := 0;
  if not Assigned(AResult) then
    raise ENSqlClassInvalid.Create('Result object was not assigned.');

  rType := TNRtti.RttiCtx.GetType(AResult.ClassType);
  if not Assigned(rType) then
    raise ENSqlClassInvalid(format('RTTI data not found(Class "%s")', [AResult.ClassName]));

  with TFDQuery(AQuery) do begin
    if (not Active) or IsEmpty then
      Exit;
    // Loop with Field List.
    for i := 0 to Fields.Count - 1 do begin
      with Fields[i] do begin
        // Find matched property and skip if not exist
        rMember := TNRtti.GetMember(rType, FieldName, pioWritable);
        if rMember <> nil then begin
            { OS 언어설정에 따라, 다국어 데이터를 String 에 담으면 깨지는 경우가 있습니다.
              예- 일본어, 중국어 자료를 한국어 OS 에서 String 변수에 담으면, 일부 문자 처리못함.
              따라서, Sync 등 전송이 목적인 경우, Unicode 로 조회된 자료를(Variant) 직접 UTF8로 Encoding 합니다. }
            if DataType in N_DBTYPES_SUPPORTED then begin
              if SameText(PlatformDB, 'Sqlite') and
                 SameText(TNRtti.GetMemberTypeName(rMember), 'System.TDateTime') and
                 (DataType in [ftInteger, ftLargeInt]) then begin
                try
                  la := AsLargeInt;
                  // as default, we use UTC time to sqlite integer fields !!
                  // No, 2015.6 we decided to use local time instead of UTC time. !!
                  // So all of fields of database use local time. Then, we do not have to convert it to local time again.
                  // That is, on UnixToDateTime(), we have to set "true" on its second parameter !!!!
                  // for details, look its source
                  TNRtti.SetMemberValue(rMember, AResult, UnixToDateTime(la, true));
                except
                  on e: EInvalidCast do begin
                    _WriteLog(SQL_LOG_ERROR, format('Can not retrieve/set field %s(%s) to %s.%s(%s). %s. %s',
                      [FieldName, GetEnumName(TypeInfo(TFieldType), Ord(DataType)),
                       rType.Name, rMember.Name, TNRtti.GetMemberTypeName(rMember),
                       E.ClassName, e.Message]));
                  end;
                end;
              end
              else begin
                try
                  TNRtti.SetMemberValue(rMember, AResult, AsVariant);
                except
                  on e: EInvalidCast do begin
                    _WriteLog(SQL_LOG_ERROR, format('Can not retrieve/set field %s(%s) to %s.%s(%s). %s. %s',
                      [FieldName, GetEnumName(TypeInfo(TFieldType), Ord(DataType)),
                       rType.Name, rMember.Name, TNRtti.GetMemberTypeName(rMember),
                       E.ClassName, e.Message]));
                  end;
                end;
              end;
            end
            else begin
              _WriteLog(SQL_LOG_WARN, format('Field %s is not supported type', [FieldName]));
            end;
            { To prevent memory leak of typed variant. We have to set "UnAssigned" explicity}
            if not VarIsNull(AValue) then
              AValue := UnAssigned;
        end;
      end;
    end;
    Inc(Result);
  end;
end;

function TNFDSqlMgr._GetObjectFromDataSet(AQuery: TObject; AResultClassName: string): TNData;
begin
  result := nil;
  with TFDQuery(AQuery) do begin
    if (not Active) or isEmpty then
      Exit;
  end;
  // Instantiate the given class
  Result := _GetInstanceOf(AResultClassName);
  _LoadObjectFromDataSet(AQuery, Result);
end;

procedure TNFDSqlMgr._GetListFromDataSet(AQuery: TObject; AResultClassName: string; AReturnList: TNList; InterProc: TNotifyEvent = nil);
var
  c: Integer;
begin
  with TFDQuery(AQuery) do begin
    c := 0;
    while not EOF do begin
      AReturnList.Add(_GetObjectFromDataSet(AQuery, AResultClassName));
      Inc(c);
      if Assigned(InterProc) and (c mod 2 = 0) then
        InterProc(Self);
      Next;
    end;
  end;
end;

function TNFDSqlMgr._GetListFromDataSet(AQuery: TObject; AResultClassName: string; InterProc: TNotifyEvent = nil): TNList;
var
  c: Integer;
begin
  Result := nil;
  with TFDQuery(AQuery) do begin
    if (not Active) or isEmpty then begin
      result := TNList.Create;
    end;
    c := 0;
    while not EOF do begin
      if not Assigned(Result) then
        Result := TNList.Create;
      Result.Add(_GetObjectFromDataSet(AQuery, AResultClassName));
      Inc(c);
      if Assigned(InterProc) and (c mod 2 = 0) then
        InterProc(Self);
      Next;
    end;
  end;
end;

(*==============================================================================
  - Default Query, Sql 로 Execute 할때는 자동으로 각 건을 Transaction 처리함.
  - 수동으로 Transaction 을 처리할 경우 StaticQuery, StaticSql 을 사용할 것.
  - 처리된 레코드수를 알려면 반드시 Prepare 를 수행해야 함.
==============================================================================*)
function TNFDSqlMgr._ExcuteQuery(ASql: TObject): Integer;
begin
  result := 0;
  _DoBeforeQuery(ASql);
  try
    if ASql is TFDQuery then begin
      with TFDQuery(ASql) do begin
        // TFDQuery(ASql).SpecificOptions.Values['TemporaryLobUpdate'] := 'False';
        Execute;
        result := RowsAffected;
      end;
    end
    else if ASql is TFDCommand then begin
      with TFDCommand(ASql) do begin
        Execute;
        result := RowsAffected;
      end;
    end;
  finally
    _DoPostQuery(ASql);
  end;
end;

procedure TNFDSqlMgr._OpenQuery(AQuery: TObject);
begin
  _DoBeforeQuery(AQuery);
  try
    TFDQuery(AQuery).Open;
  finally
    _DoPostQuery(AQuery);
  end;
end;

{procedure TNFDSqlMgr._GetParamList(AQueryOrSQL: TObject; ASql: String; AParams: TStrings);
var
  i: integer;
  ASqlParams: TFDParams;
begin
  ASqlParams := nil;
  if AQueryOrSQL is TFDQuery then begin
    TFDQuery(AQueryOrSQL).SQL.Text := ASql;
    TFDQuery(AQueryOrSQL).Prepare;
    ASqlParams := TFDQuery(AQueryOrSQL).Params;
  end
  else if AQueryOrSQL is TFDCommand then begin
    TFDCommand(AQueryOrSQL).CommandText.Text := ASql;
    TFDCommand(AQueryOrSQL).Prepare;
    ASqlParams := TFDCommand(AQueryOrSQL).Params;
  end;
  if not Assigned(ASqlParams) then
    Exit;
  for i := 0 to ASqlParams.Count - 1 do
    AParams.Add(ASqlParams[i].Name);
end;
}
(*==============================================================================
  Support dynamic param setting
  ------------------------------------------------------------------------------
  -- When CLOB field exist, sql may include following statement
  ------------------------------------------------------------------------------
      INSERT INTO ATable(Field1, Field2, Field3)
      VALUES(:Field1, :Field2, EMPTY_CLOB())
        RETURNING
          Field3
        INTO
         :Field3
===============================================================================*)
procedure TNFDSqlMgr._FillParams(AQueryOrSQL: TObject; ASql: String; AParamObj: TPersistent);
var
  i: integer;
  ASqlParam: TFDParam;
  ASqlParams: TFDParams;
  AValue: TValue;
  rType: TRttiType;
  rMember: TRttiMember;
  AParamLog: String;
begin
  ASqlParams := nil;
  if AQueryOrSQL is TFDQuery then begin
    TFDQuery(AQueryOrSQL).SQL.Text := ASql;
    if not SameText(PlatformDB, PLATFORM_DB_SQLITE) then
      TFDQuery(AQueryOrSQL).Prepare;
    ASqlParams := TFDQuery(AQueryOrSQL).Params;
  end
  else if AQueryOrSQL is TFDCommand then begin
    TFDCommand(AQueryOrSQL).CommandText.Text := ASql;
    if not SameText(PlatformDB, PLATFORM_DB_SQLITE) then
      TFDCommand(AQueryOrSQL).Prepare;
    ASqlParams := TFDCommand(AQueryOrSQL).Params;
  end;
  if not Assigned(ASqlParams) or (ASqlParams.Count < 1) or (AParamObj = nil) then begin
    if SameText(PlatformDB, PLATFORM_DB_SQLITE) then begin
      if AQueryOrSQL is TFDQuery then TFDQuery(AQueryOrSQL).Prepare
      else if AQueryOrSQL is TFDCommand then TFDCommand(AQueryOrSQL).Prepare;
    end;
    Exit;
  end;

  rType := TNRtti.RttiCtx.GetType(AParamObj.ClassType);
  if rType = nil then
    raise ENSqlClassInvalid(format('RTTI data not found(Class "%s")', [AParamObj.ClassName]));

  AParamLog := '';
  for i := 0 to ASqlParams.Count - 1 do begin
    rMember := TNRtti.GetMember(rType, ASqlParams[i].Name, pioReadable);

    if Assigned(rMember) then begin
      AValue := TNRtti.GetMemberValue(rMember, AParamObj);
      if SameText(TNRtti.GetMemberTypeName(rMember), 'System.TDateTime') then begin // Do not localize
        if SameText(PlatformDB, 'SQLITE') then begin
          // on sql lite, use integer type for datetime data.
          // and save its value as UTC time always
          // Unix use UTC time always. So DateTimeToUnix(inputDateTime, false) will convert inputDateTime to UTC time
          // 2015.6. We decided to use local time instead of UTC time !!
          // So, we just set to "true" on second parameter of DateTimeToUnix()
          ASqlParams[i].AsLargeInt := DateTimeToUnix(AValue.AsExtended, true);
        end
        else begin
          if EndsText('TimeK', rMember.Name) or EndsText('TimeS', rMember.Name) then begin
            if SameText(PlatformDB, 'ORA') then begin
              ASqlParams[i].AsSQLTimeStamp := DateTimeToSQLTimeStamp(AValue.AsExtended);
            end
            else begin
              ASqlParams[i].DataType := ftTimeStamp;
              ASqlParams[i].AsDateTime := AValue.AsExtended;
            end;
          end
          else
            ASqlParams[i].AsDateTime := AValue.AsExtended;
        end;
      end
      else begin
        case TNRtti.GetMemberType(rMember) of
          TTypeKind.tkInteger:
              ASqlParams[i].AsInteger := AValue.AsInteger;
          TTypeKind.tkInt64:
              ASqlParams[i].AsLargeInt := AValue.AsInt64;
          TTypeKind.tkFloat:
              ASqlParams[i].AsFloat := AValue.AsExtended;
          TTypeKind.tkChar, TTypeKind.tkString, TTypeKind.tkLString:
              ASqlParams[i].AsString := AValue.AsString;
          TTypeKind.tkWChar, TTypeKind.tkWString, TTypeKind.tkUString:
              ASqlParams[i].AsWideString := AValue.AsString;
          else
            raise ENSqlClassInvalid(format('Field "%s.%s" type is not supported for database parameter', [AParamObj.ClassName, rMember.Name]));
        end;
      end;
      NConcatP(AParamLog, format('%s=%s', [ASqlParams[i].Name, AValue.ToString]), ',');
    end
    else
      _WriteLog(SQL_LOG_WARN, format('Fail to set parameter %s(property not found)', [ASqlParams[i].Name]));
  end;
  if not AParamLog.IsEmpty then
    _WriteLog(SQL_LOG_DEBUG, '*Param ' + AParamLog);
  if SameText(PlatformDB, PLATFORM_DB_SQLITE) then begin
    if AQueryOrSQL is TFDQuery then TFDQuery(AQueryOrSQL).Prepare
    else if AQueryOrSQL is TFDCommand then TFDCommand(AQueryOrSQL).Prepare;
  end;
end;

procedure TNFDSqlMgr._FillParams(AQueryOrSQL: TObject; ASql: String; AParams: Array of String);
var
  i: integer;
  AStrValue, AParamLog: string;
  ASqlParams: TFDParams;
  ADateTimeValue: TDateTime;
begin
  ASqlParams := nil;
  if AQueryOrSQL is TFDQuery then begin
    TFDQuery(AQueryOrSQL).SQL.Text := ASql;
    if not SameText(PlatformDB, PLATFORM_DB_SQLITE) then
      TFDQuery(AQueryOrSQL).Prepare;
    TFDQuery(AQueryOrSQL).Prepare;
    ASqlParams := TFDQuery(AQueryOrSQL).Params;
  end
  else if AQueryOrSQL is TFDCommand then begin
    TFDCommand(AQueryOrSQL).CommandText.Text := ASql;
    if not SameText(PlatformDB, PLATFORM_DB_SQLITE) then
      TFDCommand(AQueryOrSQL).Prepare;
    ASqlParams := TFDCommand(AQueryOrSQL).Params;
  end;
  if not Assigned(ASqlParams) or (ASqlParams.Count < 1) or (Length(AParams) = 0) then begin
    if SameText(PlatformDB, PLATFORM_DB_SQLITE) then begin
      if AQueryOrSQL is TFDQuery then TFDQuery(AQueryOrSQL).Prepare
      else if AQueryOrSQL is TFDCommand then TFDCommand(AQueryOrSQL).Prepare;
    end;
    Exit;
  end;

  (*============================================================================
    배열로 Parameter Value 가 전달된 경우, 순서대로 채웁니다.
    따라서, 전달된 배열의 갯수가 최소한 SQL 의 param count 보다 크거나 같아야 합니다.
  ============================================================================*)
  if ASqlParams.Count > (High(AParams) + 1) then
    raise ENSqlParamCountInvalid.Create(format('%d parameters expected. but %d passed.',
      [ASqlParams.Count, (High(AParams) + 1)]));

  // Sql Param does not provide data type information.
  // So the sql.param value should be set depend on passed value's data type(AParams)
  AParamLog := '';
  for i := 0 to ASqlParams.Count - 1 do begin
    if (Length(AParams[i]) > 4) and (StartsText('<TS>', AParams[i]) or StartsText('<DT>', AParams[i])) then begin
      ADateTimeValue := StringToDateTime(Copy(AParams[i], 5, MaxInt));
      if SameText(PlatformDB, 'SQLITE') then begin
        ASqlParams[i].AsLargeInt := DateTimeToUnix(ADateTimeValue, false);
      end
      else
        ASqlParams[i].AsDateTime := ADateTimeValue;
    end
    else
      ASqlParams[i].Value := AParams[i];
    NConcatP(AParamLog, format('%s=%s', [ASqlParams[i].Name, AParams[i]]), ',');
  end;   // End For
  if not AParamLog.IsEmpty then
    _WriteLog(SQL_LOG_DEBUG, '*Param ' + AParamLog);
  if SameText(PlatformDB, PLATFORM_DB_SQLITE) then begin
    if AQueryOrSQL is TFDQuery then TFDQuery(AQueryOrSQL).Prepare
    else if AQueryOrSQL is TFDCommand then TFDCommand(AQueryOrSQL).Prepare;
  end;
end;

procedure TNFDSqlMgr.StartTransaction(AComp: TObject);
begin
  if AComp is TFDQuery then begin
    with TFDQuery(AComp) do begin
      if Transaction <> nil then begin
        if Transaction.Active then begin
          Transaction.Commit;
          if AComp <> fDefaultQueryComponent then
            _WriteLog(SQL_LOG_WARN, 'Static transaction is active, it may be committed forcely');
        end;
        Transaction.StartTransaction;
      end
      else begin
        if Connection.InTransaction then begin
          Connection.Commit;
          if AComp <> fDefaultQueryComponent then
            _WriteLog(SQL_LOG_WARN, 'Static transaction is active, it may be committed forcely');
        end;
        Connection.StartTransaction;
      end;
    end;
  end
  else if AComp is TFDCommand then begin
    with TFDCommand(AComp) do begin
      if Transaction <> nil then begin
        if Transaction.Active then begin
          Transaction.Commit;
          if AComp <> fDefaultSqlComponent then
            _WriteLog(SQL_LOG_WARN, 'Static transaction is active, it may be committed forcely');
        end;
        Transaction.StartTransaction;
      end
      else begin
        if Connection.InTransaction then begin
          Connection.Commit;
          if AComp <> fDefaultSqlComponent then
            _WriteLog(SQL_LOG_WARN, 'Static transaction is active, it may be committed forcely');
        end;
        Connection.StartTransaction;
      end;
    end;
  end;
end;

procedure TNFDSqlMgr.Commit(AComp: TObject);
begin
  if AComp is TFDQuery then begin
    with TFDQuery(AComp) do begin
      if Transaction <> nil then begin
        if Transaction.Active then
          Transaction.Commit;
      end
      else begin
        if Connection.InTransaction then
          Connection.Commit;
      end;
    end;
  end
  else if AComp is TFDCommand then begin
    with TFDCommand(AComp) do begin
      if Transaction <> nil then begin
        if Transaction.Active then
          Transaction.Commit;
      end
      else begin
        if Connection.InTransaction then
          Connection.Commit;
      end;
    end;
  end;
end;

procedure TNFDSqlMgr.Rollback(AComp: TObject);
begin
  if AComp is TFDQuery then begin
    with TFDQuery(AComp) do begin
      if Transaction <> nil then begin
        if Transaction.Active then
          Transaction.Rollback;
      end
      else begin
        if Connection.InTransaction then
          Connection.Rollback;
      end;
    end;
  end
  else if AComp is TFDCommand then begin
    with TFDCommand(AComp) do begin
      if Transaction <> nil then begin
        if Transaction.Active then
          Transaction.Rollback;
      end
      else begin
        if Connection.InTransaction then
          Connection.Rollback;
      end;
    end;
  end;
end;

class function TNFDSqlMgr.IOType: TNSqlManagerType;
begin
  result := smtDB;
end;

end.

