{
@abstrcat ( Basic RTTI(RunTime Type Information Helper )
@author   ( Joonhae.lee@gmail.com )
@created  ( 2014.12 )
@lastmod  ( 2014.12 )
}

unit NBaseRtti;

interface

uses System.SysUtils, System.Generics.Collections, System.TypInfo,
  System.Rtti, System.Classes, System.Json;

type

  { Attribute to define class info for debugging }

  _NCLASS = class(TCustomAttribute)
  public
    DEBUG: Boolean;
    constructor Create(ADebug: Boolean);
  end;

  TNPropIOType = (pioReadable, pioWritable, pioNone);

  TNRtti = class
  protected
    fRTTICtx: TRttiContext;
    fSecureFieldNamesOnDebug: TStringList;
    class function GetRttiCtx: TRttiContext; static;
    class function GetNClassAttr(rObject: TRttiObject): _NCLASS;
  public
    constructor Create;
    destructor Destroy; override;
    class function TestUserType(AClass: TClass): Boolean;
    class function ObjectInstance(TypeName: string): TObject; overload;
    class function ObjectInstance(rType: TRttiType): TObject; overload;
    class function ObjectInstance(TypeName: string; AParamObj: TObject): TObject; overload;
    class function ObjectInstance(rType: TRttiType; AParamObj: TObject): TObject; overload;
    class function EnumNameOf(Value: TValue): String; overload;
    class function EnumNameOf(AObject: TObject; AFieldName: String): String; overload;

    class procedure ClearObjectFields(AObject: TObject; ARecursive: boolean = true);
    class procedure CloneObjectFields(ASrc, ADest: TObject; ARecursive: boolean = true; ADoClear: Boolean = true);

    class property RttiCtx: TRttiContext read GetRttiCtx;

    // print details
    class procedure AddSecureFieldOnDebug(AQualifiedFieldName: String);
    class procedure PrintObjectValues(AObject: TObject; AStrings: TStrings; Indent: String = '  '; PrintClassName: Boolean = true);
    class procedure PrintObjectFields(AObject: TObject; AStrings: TStrings; Indent: String = '  '; PrintClassName: Boolean = true);
    class procedure PrintObjectProperties(AObject: TObject; AStrings: TStrings; Indent: String = '  '; PrintClassName: Boolean = true);

    class function GetMember(rType: TRttiType; AName: String; WantedPropType: TNPropIOType = pioReadable): TRttiMember;
    class function GetMemberValue(rType: TRttiType; AnObj: TObject; AName: String): TValue; overload;
    class function GetMemberValue(rMember: TRttiMember; AnObj: TObject): TValue; overload;
    class procedure SetMemberValue(rMember: TRttiMember; AnObj: TObject; AValue: TValue); overload;
    class procedure SetMemberValue(rMember: TRttiMember; AnObj: TObject; AValue: Variant); overload;

    class function GetMemberType(rMember: TRttiMember): TTypeKind;
    class function GetMemberTypeName(rMember: TRttiMember): String;

  end;

  EKRttiException = class(Exception);
  EKRttiPropTypeNotSupported = class(Exception);

const
  N_TYPES_STRING:     set of System.TTypeKind = [tkChar, tkString, tkWChar, tkLString, tkWString, tkUString];
  N_TYPES_ORD:        set of System.TTypeKind = [tkInteger];
  N_TYPES_INT64:      set of System.TTypeKind = [tkInt64];
  N_TYPES_DOUBLE:     set of System.TTypeKind = [tkFloat];
  N_TYPES_ENUM:       set of System.TTypeKind = [tkEnumeration];

  N_TYPES_NUMERIC:    set of System.TTypeKind = [tkInteger, tkInt64, tkFloat];

  KPROP_TYPES_SUPPORT:    set of System.TTypeKind = [tkChar, tkString, tkWChar, tkLString, tkWString,
                                              tkInteger,
                                              tkInt64,
                                              tkFloat,
                                              tkEnumeration];
  KPROP_TYPES_MUTE:       set of System.TTypeKind = [tkClass];

{

  System.TTypeKind = (tkUnknown, tkInteger, tkChar, tkEnumeration, tkFloat,
    tkString, tkSet, tkClass, tkMethod, tkWChar, tkLString, tkWString,
    tkVariant, tkArray, tkRecord, tkInterface, tkInt64, tkDynArray, tkUString,
    tkClassRef, tkPointer, tkProcedure );
}

  function GetClassName(O: TObject): String;

implementation

uses System.DateUtils, System.StrUtils, NBasePerf, NBaseClass,
  FMX.dialogs;

var
  _GlobalRtti: TNRtti;

function GetClassName(O: TObject): String;
begin
  if O = nil then
    result := 'nil'
  else
    result := O.ClassName;
end;

{ _NCLASS :: RTTI attribute }

constructor _NCLASS.Create(ADebug: Boolean);
begin
  DEBUG := ADebug;
end;

{ TNRtti }

class function TNRtti.GetRttiCtx: TRttiContext;
begin
  if _GlobalRtti = nil then
    _GlobalRtti := TNRtti.Create;
  result := _GlobalRtti.fRttiCtx;
end;

class function TNRtti.GetNClassAttr(rObject: TRttiObject): _NCLASS;
var
  tAttr: TCustomAttribute;
begin
  result := nil;
  if rObject = nil then
    Exit;
  for tAttr in rObject.GetAttributes do
    if tAttr is _NCLASS then
      result := _NCLASS(tAttr);
end;

class function TNRtti.TestUserType(AClass: TClass): Boolean;
begin
  result := RttiCtx.GetType(AClass) <> nil;
end;

class function TNRtti.ObjectInstance(TypeName: string): TObject;
var
  rType: TRttiType;
begin
  rType := RttiCtx.FindType(TypeName);
  if rType <> nil then
    try
      Exit(ObjectInstance(rType));
    finally
      FreeAndNil(rType);
    end;
  Exit(nil);
end;

class function TNRtti.ObjectInstance(rType: TRttiType): TObject;
var
  mType: TRTTIMethod;
  metaClass: TClass;
begin
  result := nil;
  for mType in rType.GetMethods do begin
    if mType.HasExtendedInfo and mType.IsConstructor then begin
      if Length(mType.GetParameters) = 0 then begin
        // invoke
        metaClass := rType.AsInstance.MetaclassType;
        Exit(mType.Invoke(metaClass, []).AsObject);
      end;
    end;
  end;
end;

class function TNRtti.ObjectInstance(TypeName: string; AParamObj: TObject): TObject;
var
  rType: TRttiType;
begin
  rType := RttiCtx.FindType(TypeName);
  if rType <> nil then
    try
      Exit(ObjectInstance(rType, AParamObj));
    finally
      FreeAndNil(rType);
    end;
  Exit(nil);
end;

class function TNRtti.ObjectInstance(rType: TRttiType; AParamObj: TObject): TObject;
var
  mType: TRTTIMethod;
  metaClass: TClass;
begin
  result := nil;
  for mType in rType.GetMethods do begin
    if mType.HasExtendedInfo and mType.IsConstructor then begin
      if Length(mType.GetParameters) = 1 then begin
        if mType.GetParameters[0].ParamType.TypeKind = TTypeKind.tkClass then begin
          // invoke
          metaClass := rType.AsInstance.MetaclassType;
          Exit(mType.Invoke(metaClass, [AParamObj]).AsObject);
        end
        else
          raise Exception.Create('Type of constructor parameter invalid');
      end;
    end;
  end;
end;


class function TNRtti.GetMember(rType: TRttiType; AName: String; WantedPropType: TNPropIOType): TRttiMember;
var
  rField: TRttiField;
  rProp: TRttiProperty;
begin
  for rField in rType.GetFields do
    if SameText(rField.Name, AName) then
      Exit(rField);
  for rProp in rType.GetProperties do
    if SameText(rProp.Name, AName) then begin
      if (WantedPropType = pioReadable) and rProp.IsReadable then
        Exit(rProp)
      else if (WantedPropType = pioWritable) and rProp.IsWritable then
        Exit(rProp)
      else if WantedPropType = pioNone then
        Exit(rProp);
      Exit(nil);
    end;
  Exit(nil);
end;

class function TNRtti.GetMemberValue(rMember: TRttiMember; AnObj: TObject): TValue;
begin
  if rMember is TRttiField then
    Exit(TRttiField(rMember).GetValue(AnObj));
  if rMember is TRttiProperty then
    if TRttiProperty(rMember).IsReadable then
      Exit(TRttiProperty(rMember).GetValue(AnObj));
  Exit(TValue.Empty);
end;

class function TNRtti.GetMemberValue(rType: TRttiType; AnObj: TObject; AName: String): TValue;
var
  rMember: TRttiMember;
begin
  rMember := GetMember(rType, AName);
  if rMember <> nil then
    Exit(GetMemberValue(rMember, AnObj));
  Exit(TValue.Empty);
end;

class procedure TNRtti.SetMemberValue(rMember: TRttiMember; AnObj: TObject; AValue: TValue);
begin
  if rMember is TRttiField then
    TRttiField(rMember).SetValue(AnObj, AValue);
  if rMember is TRttiProperty then
    if TRttiProperty(rMember).IsWritable then
      TRttiProperty(rMember).SetValue(AnObj, AValue);
end;

class procedure TNRtti.SetMemberValue(rMember: TRttiMember; AnObj: TObject; AValue: Variant);
begin
  SetMemberValue(rMember, AnObj, TValue.FromVariant(AValue));
end;

class function TNRtti.GetMemberType(rMember: TRttiMember): TTypeKind;
begin
  if rMember is TRttiField then
    Exit(TRttiField(rMember).FieldType.TypeKind);
  if rMember is TRttiProperty then
    Exit(TRttiProperty(rMember).PropertyType.TypeKind);
  Exit(TTypeKind.tkUnknown);
end;

class function TNRtti.GetMemberTypeName(rMember: TRttiMember): String;
begin
  if rMember is TRttiField then
    Exit(TRttiField(rMember).FieldType.QualifiedName);
  if rMember is TRttiProperty then
    Exit(TRttiProperty(rMember).PropertyType.QualifiedName);
  Exit('');
end;

class function TNRtti.EnumNameOf(Value: TValue): String;
begin
  result := GetEnumName(Value.TypeInfo, TValueData(Value).FAsSLong);
end;

constructor TNRtti.Create;
begin
  inherited;
  fSecureFieldNamesOnDebug := TStringList.Create;
end;

destructor TNRtti.Destroy;
begin
  FreeAndNil(fSecureFieldNamesOnDebug);
  inherited;
end;

class procedure TNRtti.AddSecureFieldOnDebug(AQualifiedFieldName: String);
begin
  if _GlobalRtti = nil then
    _GlobalRtti := TNRtti.Create;
  _GlobalRtti.fSecureFieldNamesOnDebug.Add(AQualifiedFieldName); // must be "classname.fieldname"
end;

class function TNRtti.EnumNameOf(AObject: TObject; AFieldName: String): String;
var
  rType: TRttiType;
  rField: TRttiField;
  AValue: TValue;
begin
  if AObject = nil then
    Exit('');
  rType := RttiCtx.GetType(AObject);
  if rType = nil then
    Exit('');
  rField := rType.GetField(AFieldName);
  if rField = nil then
    Exit('');
  AValue := rField.GetValue(AObject);
  result := GetEnumName(AValue.TypeInfo, TValueData(AValue).FAsSLong);
end;


class procedure TNRtti.PrintObjectProperties(AObject: TObject; AStrings: TStrings; Indent: String = '  '; PrintClassName: Boolean = true);

  function _MaskSecurityPropValue(AValue: String): String;
  var
    ALen: Integer;
  begin
    ALen := Length(AValue);
    if ALen >= 8 then // Print First, Last 4 digit
      result := LeftStr(AValue, ALen div 4) + DupeString('*', ALen - (ALen div 4)*2) + RightStr(AValue, ALen div 4)
    else if ALen >= 4 then
      result := LeftStr(AValue, ALen div 2) + DupeString('*', ALen - (ALen div 2))
    else
      result := DupeString('*', ALen);
  end;

var
  i: Integer;
  rType: TRttiType;
  rProp: TRttiProperty;
  rClassAttr: _NCLASS;
  v: TValue;
begin
  if AObject = nil then
    Exit;
  rType := RttiCtx.GetType(AObject.ClassType);
  if rType = nil then
    Exit;
  rClassAttr := GetNClassAttr(rType);
  if (rClassAttr = nil) or (not rClassAttr.DEBUG) then
    Exit;
  if PrintClassName then
    AStrings.Add(Indent + '<< Class: ' + rType.Name + '>>');
  AStrings.Add(Indent + '<Properties>');
  for rProp in rType.GetProperties do begin
    if not (rProp.Visibility in [mvPublic, mvPublished]) then
      Continue;
    if not rProp.IsReadable then
      Continue;
    v := rProp.GetValue(AObject);
    case rProp.PropertyType.TypeKind of
      TTypeKind.tkFloat:
        begin
          if SameText(rProp.PropertyType.QualifiedName, 'System.TDateTime') then begin // Do not localize
            AStrings.Add(Indent + '-' + rProp.Name + ' : ' + formatDateTime('yyyy/mm/dd hh:nn:ss', v.AsExtended) + '(' + rProp.PropertyType.Name + ')');
          end
          else
            AStrings.Add(Indent + '-' + rProp.Name + ' : ' + v.ToString + '(' + rProp.PropertyType.Name + ')');
        end;
      TTypeKind.tkString,
      TTypeKind.tkWString,
      TTypeKind.tkLString,
      TTypeKind.tkUString:
        begin
          if _GlobalRtti.fSecureFieldNamesOnDebug.IndexOf(format('%s.%s', [rType.Name, rProp.Name])) >= 0 then
            AStrings.Add(Indent + '-' + rProp.Name + ' : ' + _MaskSecurityPropValue(v.ToString) + '(' + rProp.PropertyType.Name + ')')
          else
            AStrings.Add(Indent + '-' + rProp.Name + ' : ' + v.ToString + '(' + rProp.PropertyType.Name + ')');
        end;
      TTypeKind.tkInteger,
      TTypeKind.tkInt64,
      TTypeKind.tkChar,
      TTypeKind.tkWChar,
      TTypeKind.tkEnumeration:
        begin
          AStrings.Add(Indent + '-' + rProp.Name + ' : ' + v.ToString + '(' + rProp.PropertyType.Name + ')');
        end;
      TTypeKind.tkClass:
        begin
          if (v.IsEmpty) or (v.AsObject is TJSONAncestor) then
            Continue;
          if v.AsObject is TStrings then begin
            AStrings.Add(Indent + '-' + rProp.Name + ' : {' + rProp.PropertyType.Name + '}');
            for i:=0 to TStrings(v.AsObject).Count-1 do
              AStrings.Add(Indent + Indent + format('(%d)%s', [i, TStrings(v.AsObject).Strings[i]]));
          end
          else if v.AsObject is TNList then begin
            AStrings.Add(Indent + '-' + rProp.Name + ' : {' + rProp.PropertyType.Name + '}');
            for i:=0 to TNList(v.AsObject).Count-1 do
              PrintObjectValues(TNList(v.AsObject).Items[i], AStrings, Indent + Indent, false);
          end
          else begin
            AStrings.Add(Indent + '-' + rProp.Name + ' : {' + rProp.PropertyType.Name + '}');
            PrintObjectValues(v.AsObject, AStrings, Indent + Indent, false);
          end;
        end;
    end;
  end;
end;

class procedure TNRtti.PrintObjectFields(AObject: TObject; AStrings: TStrings; Indent: String = '  '; PrintClassName: Boolean = true);

  function _MaskSecurityPropValue(AValue: String): String;
  var
    ALen: Integer;
  begin
    ALen := Length(AValue);
    if ALen >= 8 then // Print First, Last 4 digit
      result := LeftStr(AValue, ALen div 4) + DupeString('*', ALen - (ALen div 4)*2) + RightStr(AValue, ALen div 4)
    else if ALen >= 4 then
      result := LeftStr(AValue, ALen div 2) + DupeString('*', ALen - (ALen div 2))
    else
      result := DupeString('*', ALen);
  end;

var
  i: Integer;
  rType: TRttiType;
  rField: TRttiField;
  rClassAttr: _NCLASS;
  v: TValue;
begin
  if AObject = nil then
    Exit;
  rType := RttiCtx.GetType(AObject.ClassType);
  if rType = nil then
    Exit;
  rClassAttr := GetNClassAttr(rType);
  if (rClassAttr = nil) or (not rClassAttr.DEBUG) then
    Exit;
  if PrintClassName then
    AStrings.Add(Indent + '<< Class: ' + rType.Name + '>>');
  AStrings.Add(Indent + '<Fields> ');
  for rField in rType.GetFields do begin
    if not (rField.Visibility in [mvPublic, mvPublished]) then
      Continue;
    v := rField.GetValue(AObject);
    case rField.FieldType.TypeKind of
      TTypeKind.tkString,
      TTypeKind.tkWString,
      TTypeKind.tkLString,
      TTypeKind.tkUString:
        begin
          if _GlobalRtti.fSecureFieldNamesOnDebug.IndexOf(format('%s.%s', [rType.Name, rField.Name])) >= 0 then
            AStrings.Add(Indent + '-' + rField.Name + ' : ' + _MaskSecurityPropValue(v.ToString) + '(' + rField.FieldType.Name + ')')
          else
            AStrings.Add(Indent + '-' + rField.Name + ' : ' + v.ToString + '(' + rField.FieldType.Name + ')');
        end;
      TTypeKind.tkFloat:
        begin
          if SameText(rField.FieldType.QualifiedName, 'System.TDateTime') then begin // Do not localize
            AStrings.Add(Indent + '-' + rField.Name + ' : ' + formatDateTime('yyyy/mm/dd hh:nn:ss', v.AsExtended) + '(' + rField.FieldType.Name + ')');
          end
          else
            AStrings.Add(Indent + '-' + rField.Name + ' : ' + v.ToString + '(' + rField.FieldType.Name + ')');
        end;
      TTypeKind.tkInteger,
      TTypeKind.tkInt64,
      TTypeKind.tkChar,
      TTypeKind.tkWChar,
      TTypeKind.tkEnumeration:
        AStrings.Add(Indent + '-' + rField.Name + ' : ' + v.ToString + '(' + rField.FieldType.Name + ')');
      TTypeKind.tkClass:
        begin
          if (v.IsEmpty) or (v.AsObject is TJSONAncestor) then
            Continue;
          if v.AsObject is TStrings then begin
            AStrings.Add(Indent + '-' + rField.Name + ' : {' + rField.FieldType.Name + '}');
            for i:=0 to TStrings(v.AsObject).Count-1 do
              AStrings.Add(Indent + Indent + format('(%d)%s', [i, TStrings(v.AsObject).Strings[i]]));
          end
          else if v.AsObject is TNList then begin
            AStrings.Add(Indent + '-' + rField.Name + ' : {' + rField.FieldType.Name + '}');
            for i:=0 to TNList(v.AsObject).Count-1 do begin
              AStrings.Add(Indent + Indent + format('> Item %d(%s)', [i, TNList(v.AsObject).Items[i].ClassName]));
              PrintObjectValues(TNList(v.AsObject).Items[i], AStrings, Indent + Indent + Indent, false);
            end;
          end
          else begin
            AStrings.Add(Indent + '-' + rField.Name + ' : {' + rField.FieldType.Name + '}');
            PrintObjectValues(v.AsObject, AStrings, Indent + Indent, false);
          end;
        end;
    end;
  end;
end;

class procedure TNRtti.PrintObjectValues(AObject: TObject; AStrings: TStrings; Indent: String = '  '; PrintClassName: Boolean = true);
begin
  if AObject = nil then
    Exit;
  if PrintClassName then
    AStrings.Add(Indent + '<< Class: ' + AObject.ClassName + ' >>');
  PrintObjectFields(AObject, AStrings, Indent, false);
  PrintObjectProperties(AObject, AStrings, Indent, false);
end;

{ Clear the value of all fields }
class procedure TNRtti.ClearObjectFields(AObject: TObject; ARecursive: boolean = true);
var
  rType: TRttiType;
  rField: TRttiField;
  AFieldObj: TObject;
  rClassAttr: _NCLASS;
  v: TValue;
begin
  rType := RttiCtx.GetType(AObject.ClassType);
  if rType = nil then
    Exit;

  for rField in rType.GetFields do begin
    try
    case rField.FieldType.TypeKind of
      // integer, float
      TTypeKind.tkInteger, TTypeKind.tkInt64, TTypeKind.tkFloat:
        rField.SetValue(AObject, 0);
      // string
      TTypeKind.tkLString, TTypeKind.tkWString, TTypeKind.tkUString,
      TTypeKind.tkChar, TTypeKind.tkWChar, TTypeKind.tkString:
        rField.SetValue(AObject, '');
      // Enumaration
      TTypeKind.tkEnumeration:
        begin
          v := TValue.FromOrdinal(rField.FieldType.Handle, 0);
          rField.SetValue(AObject, v);
        end;
      // Object
      TTypeKind.tkClass:
        begin
          if ARecursive then begin
            AFieldObj := rField.GetValue(AObject).AsObject;
            if AFieldObj <> nil then begin
              if AFieldObj is TStrings then begin
                TStrings(AFieldObj).Clear;
              end
              else if AFieldObj is TNList then begin
                TNList(AFieldObj).Clear;
              end
              else begin
                // We just clear the classes which written by ourselve.
                // Or all of un-attended/inherited fields will be reset !! that's not what we want and so dangerous.
                rClassAttr := GetNClassAttr(RttiCtx.GetType(AFieldObj.ClassType));
                if rClassAttr <> nil then
                  ClearObjectFields(AFieldObj, ARecursive);
              end;
            end;
          end;
        end;
      TTypeKind.tkRecord,
      TTypeKind.tkDynArray,
      TTypeKind.tkArray:
        begin
          ; // fixme
        end;
      TTypeKind.tkSet,
      TTypeKind.tkMethod, TTypeKind.tkVariant,
      TTypeKind.tkInterface, TTypeKind.tkPointer,
      TTypeKind.tkClassRef, TTypeKind.tkProcedure:
        begin
          ; // fixme
        end;
    end;
    except
      on e: Exception do begin
        showMessage(format('%s.%s', [AObject.ClassName, rField.Name]));
      end;
    end;
  end;
end;

class procedure TNRtti.CloneObjectFields(ASrc, ADest: TObject; ARecursive: boolean = true; ADoClear: Boolean = true);
var
  i: Integer;
  rTypeSrc: TRttiType;
  rFieldSrc: TRttiField;
  rTypeDest: TRttiType;
  rFieldDest: TRttiField;
  rClassAttr: _NCLASS;
  AFieldObj: TObject;
  ASrcObj: TObject;
  rItemDest: TRttiType;
begin
  if ADest = nil then
    Exit;
  if ASrc = nil then begin
    ClearObjectFields(ADest, ARecursive);
    Exit;
  end;

  rTypeDest := TNRtti.RttiCtx.GetType(ADest.ClassType);
  if rTypeDest = nil then
    Exit;
  rTypeSrc := TNRtti.RttiCtx.GetType(ASrc.ClassType);
  if rTypeSrc = nil then begin
    if ADoClear then
      ClearObjectFields(ADest, ARecursive);
    Exit;
  end;

  for rFieldDest in rTypeDest.GetFields do begin
    rFieldSrc := rTypeSrc.GetField(rFieldDest.Name);
    case rFieldDest.FieldType.TypeKind of
      TTypeKind.tkInteger, TTypeKind.tkInt64, TTypeKind.tkFloat:
        begin
          if rFieldSrc = nil then begin
            if ADoClear then
              rFieldDest.SetValue(ADest, 0);
          end
          else
            rFieldDest.SetValue(ADest, rFieldSrc.GetValue(ASrc));
        end;
      TTypeKind.tkLString, TTypeKind.tkWString, TTypeKind.tkUString,
      TTypeKind.tkChar, TTypeKind.tkWChar, TTypeKind.tkString:
        begin
          if rFieldSrc = nil then begin
            if ADoClear then
              rFieldDest.SetValue(ADest, '');
          end
          else
            rFieldDest.SetValue(ADest, rFieldSrc.GetValue(ASrc));
        end;
      TTypeKind.tkEnumeration: //
        begin
          rFieldDest.SetValue(ADest, rFieldSrc.GetValue(ASrc));
        end;
      TTypeKind.tkClass:
        begin
          if ARecursive then begin
            AFieldObj := rFieldDest.GetValue(ADest).AsObject;
            ASrcObj := rFieldDest.GetValue(ASrc).AsObject;
            if (AFieldObj is TStrings) and (ASrcObj <> nil) then begin
              TStrings(AFieldObj).Assign(TStrings(ASrcObj));
            end
            else if (AFieldObj is TNList) and (ASrcObj is TNList) then begin
              if ADoClear then
                TNList(AFieldObj).Clear;
              if TNList(ASrcObj).Count > 0 then begin
                rItemDest := TNRtti.RttiCtx.GetType(TNList(ASrcObj).Items[0].ClassType);
                for i:=0 to TNList(ASrcObj).Count-1 do begin
                  TNList(AFieldObj).Add(TNData(TNRtti.ObjectInstance(rItemDest)).Clone(TNList(ASrcObj).Items[i]));
                end;
              end;
            end
            else if (AFieldObj is TNData) and (ASrcObj is TNData) then begin
              rClassAttr := GetNClassAttr(RttiCtx.GetType(AFieldObj.ClassType));
              if rClassAttr <> nil then
                TNData(AFieldObj).Clone(TNData(ASrcObj), ADoClear);
            end;
          end;
        end;
      TTypeKind.tkRecord,
      TTypeKind.tkDynArray,
      TTypeKind.tkArray:
        begin
          ; // fixme
        end;
      TTypeKind.tkSet, TTypeKind.tkMethod, TTypeKind.tkVariant,
      TTypeKind.tkInterface, TTypeKind.tkPointer,
      TTypeKind.tkClassRef, TTypeKind.tkProcedure:
        begin
          ; // fixme
        end;
    end;
  end;
end;

end.




