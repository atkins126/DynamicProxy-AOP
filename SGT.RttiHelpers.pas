unit SGT.RttiHelpers;

interface

Uses Rtti, SysUtils, TypInfo, Variants, Generics.Collections, Classes;

type

  TAttrRecord<T: TCustomAttribute> = record
    Attribute: T;
    Member: TRttiMember;
  end;

  TForEachAttributeOfType<T: TCustomAttribute> = reference to procedure
    (Attribute: T);

  TForEachTypeAttributeOfType<T: TCustomAttribute> = reference to procedure
    (Attribute: T; Member: TRttiMember);

  TAttributeFilter<T: TCustomAttribute> = reference to function
    (Attributte: T): boolean;

  TRttiMemberHelper = class helper for TRttiObject
  public
    function GetAttributesOfType<T: TCustomAttribute>: TArray<T>; overload;
    function GetAttributeOfType<T: TCustomAttribute>: T; overload;
    function GetAttributesOfType<T: TCustomAttribute>(Filter: TAttributeFilter<T>): TArray<T>; overload;
    function GetAttributeOfType<T: TCustomAttribute>(Filter: TAttributeFilter<T>): T; overload;
    procedure ForEachAttributeOfType<T: TCustomAttribute>
      (Proc: TForEachAttributeOfType<T>); overload;
    procedure ForEachAttributeOfType<T: TCustomAttribute>
      (Proc: TForEachAttributeOfType<T>; Filter: TAttributeFilter<T>); overload;

    function GetValue(Instance: TValue): TValue;
    procedure SetValue(Instance: TValue; AValue: TValue);
    function TypeInfo: PTypeInfo;
  end;

  TRttiTypeHelper = class helper for TRttiType
  public
    function GetMemberAttributesOfType<T: TCustomAttribute>: TArray<TAttrRecord<T>>; overload;
    function GetMemberAttributesOfType<T: TCustomAttribute>(Filter: TAttributeFilter<T>): TArray<TAttrRecord<T>>; overload;
    procedure ForEachMemberAttributeOfType<T: TCustomAttribute>
      (Proc: TForEachTypeAttributeOfType<T>); overload;
    procedure ForEachMemberAttributeOfType<T: TCustomAttribute>
      (Proc: TForEachTypeAttributeOfType<T>; Filter: TAttributeFilter<T>); overload;
  end;

  TUtil = class
  private
    class var FGUIDTypeInfo: TDictionary<TGUID,PTypeInfo>;
  public
    class constructor Create;
    class destructor Destroy;
    class function IIf<T>(const Expression: Boolean;
      TrueValue: T; FalseValue: T): T;
    class function ArrayToTArray<T>(Data: Array of T): TArray<T>;

    class procedure Append<T>(var Data: TArray<T>; Value: T);
    class function GetGUIDTypeInfo(IID: TGUID): PTypeInfo;
    class procedure RegisterGUID(ATypeInfo: PTypeInfo);
    class procedure FreeInterfaceList<T: IInterface>(AList: TList<T>);

  end;



{***************************************************************************}
{                                                                           }
{           Delphi.Mocks                                                    }
{                                                                           }
{           Copyright (C) 2011 Vincent Parrett                              }
{                                                                           }
{           http://www.finalbuilder.com                                     }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

(*
  SameValue/CompareValue Copyright (c) 2011, Stefan Glienke
  Used with permission.
*)


type
  //TValue really needs to have an Equals operator overload!
  TValueHelper = record helper for TValue
    function Equals(const value : TValue) : boolean;
    function IsFloat: Boolean;
    function IsNumeric: Boolean;
    function IsPointer: Boolean;
    function IsString: Boolean;
    function IsBoolean: Boolean;
    function IsByte: Boolean;
    function IsCardinal: Boolean;
    function IsCurrency: Boolean;
    function IsDate: Boolean;
    function IsDateTime: Boolean;
    function IsDouble: Boolean;
    function IsInteger: Boolean;
    function IsInt64: Boolean;
    function IsShortInt: Boolean;
    function IsSingle: Boolean;
    function IsSmallInt: Boolean;
    function IsTime: Boolean;
    function IsUInt64: Boolean;
    function IsVariant: Boolean;
    function IsWord: Boolean;
    function IsInterface: Boolean;
    function AsDouble: Double;
    function AsFloat: Extended;
    function AsSingle: Single;
    function AsPointer: Pointer;
    //added by jlrozano
    function ConvertTo<T>: TValue; overload;
    function ConvertTo(ToTypeInfo: PTypeInfo): TValue; overload;
  end;

function CompareValue(const Left, Right: TValue): Integer;
function SameValue(const Left, Right: TValue): Boolean;

// End code Delphi-Mocks

function ConvertValue(AValue: TValue; ToTypeInfo: PTypeInfo): TValue;

function ValueAsVariant(const AValue: TValue): Variant;

function GetFieldOrProperty(ATypeInfo: Pointer; const Name: String): TRttiMember;
function FindMember(ATypeInfo: Pointer; const Name: String): TRttiMember;
function FindMemberGetter(ATypeInfo: Pointer; const Name: String): TRttiMember;
function FindMemberSetter(ATypeInfo: Pointer; const Name: String): TRttiMember;
function GetMember(ATypeInfo: Pointer; const Name: String): TRttiMember;
function TryGetPropertyValue(Instance: TValue; PropertyName: String; out Value: TValue): boolean;
//function GetMemberValue(AObject: TValue; const Name: String): TValue;
//procedure SetMemberValue(AObject: TValue; const Name: String; const Value: TValue);

function TryGetObjectFromValue(const AValue: TValue; out AObject:TObject): boolean;
function GetObjectFromValue(AValue: TValue): TObject;

function GetResultFromType(AtypeInfo: PTypeInfo; const Obj: TObject): TValue;

function IsGetter(Method: TRttiMethod): Boolean;
function IsSetter(Method: TRttiMethod): Boolean;

function GUIDTypeInfo(const GUID: TGUID): PTypeInfo;
procedure RegisterGUIDTypeInfo(AInterfaceTypeInfo: PTypeInfo);

implementation

uses
  Math, SGT.Nullable;

var
  FGUIDTypeInfo: TDictionary<TGUID, PTypeInfo>;

function ConvertValue(AValue: TValue; ToTypeInfo: PTypeInfo): TValue;
var
  LFloat: Double;
  LInt: Integer;
  ATypeInfo: PTypeInfo;
  LValue: TValue;
  LIsNullableResult: Boolean;

  function DefaultResult(IsNullable: Boolean): TValue;
  begin
    if IsNullable then
      result:= MakeNullable(ToTypeInfo)
    else
      TValue.MakeWithoutCopy(nil, ToTypeInfo, Result);
  end;

  function IsEmpty(const AValue: TValue):boolean;
  begin
    result:= AValue.IsEmpty Or (IsNullable(AValue) and GetNullableValue(AValue).IsEmpty);
  end;

begin
  LIsNullableResult:= IsNullable(ToTypeInfo);

  if IsEmpty(AValue) then
    Exit(DefaultResult(LIsNullableResult));

  if ToTypeInfo = AValue.TypeInfo then
    Exit(AValue);

  if IsNullable(AValue) then
  begin
    LValue:= GetNullableValue(AValue);
    AValue:= LValue;

    if ToTypeInfo = AValue.TypeInfo then
      Exit(AValue);
  End;

  if IsNullable(ToTypeInfo) then
  begin
//    if (AValue.IsEmpty) Or (AValue.ToString='') then
//      Exit(MakeNullable(ToTypeInfo));

    ATypeInfo:= NullableValueTypeInfo(ToTypeInfo)
  end
  else
    AtypeInfo:= ToTypeInfo;



  if not AValue.TryCast(AtypeInfo,result) then
  begin
    case AValue.TypeInfo.Kind of
      tkInteger:
        case ATypeInfo.Kind of
          tkFloat: begin
                     LFloat:= AValue.AsInteger;
                     result:= LFloat;
                   end  ;
          tkLString,
          tkWString,
          tkUString,
          tkString: result:= IntToStr(AValue.AsInteger);
          tkChar,
          tkWChar:  result:= IntToStr(AValue.AsInteger)[1];
          tkVariant: result:= TValue.FromVariant(AValue.AsVariant);
        end;
      tkInt64:
        case ATypeInfo.Kind of
          tkFloat: begin
                     LFloat:= AValue.AsInt64;
                     result:= LFloat;
                   end  ;
          tkLString,
          tkWString,
          tkUString,
          tkString: result:= IntToStr(AValue.AsInt64);
          tkChar,
          tkWChar:  result:= IntToStr(AValue.AsInt64)[1];
          tkVariant: result:= TValue.FromVariant(AValue.AsVariant);
        end;
      tkWChar,
      tkChar:
        case ATypeInfo.Kind of
          tkInteger: if AValue.AsType<WideChar> in ['0'..'9'] then
                        result:= StrToInt(AValue.AsString)
                     else
                        result:= Integer(0);
          tkInt64:  if AValue.AsType<WideChar> in ['0'..'9'] then
                        result:= StrToInt64(AValue.AsString)
                    else
                        result:= Int64(0);
          tkFloat: if AValue.AsType<WideChar> in ['0'..'9'] then
                      result:= StrToFloat(AVAlue.AsString)
                   else
                      TValue.MakeWithoutCopy(nil, TypeInfo(Extended), Result);
          tkLString,
          tkWString,
          tkUString,
          tkString: result:= AValue.AsString;
          tkChar,
          tkWChar:  result:= AValue;
          tkVariant: result:= TValue.FromVariant(AValue.AsVariant);
        end;
      tkEnumeration:
        case ATypeInfo.Kind of
          tkInteger,
          tkInt64,

          tkFloat: Result:= Byte(AValue.GetReferenceToRawData^);
          tkLString,
          tkWString,
          tkUString,
          tkString: result:= AValue.ToString;
          tkVariant: result:= TValue.FromVariant(AValue.AsVariant);
        end;
      tkFloat:
        case ATypeInfo.Kind of
          tkInteger: result:= Integer(Trunc(AValue.AsInteger));
          tkInt64:  result:= Trunc(AValue.AsInteger);
          tkLString,
          tkWString,
          tkUString,
          tkString: if AValue.TypeInfo = TypeInfo(TDateTime) then
                      result:= DateTimeToStr(AValue.AsType<Extended>)
                   else
                   if AValue.TypeInfo = TypeInfo(TDate) then
                      result:= DateToStr(AValue.AsType<Extended>)
                   else
                     result:= FloatToStr(AvAlue.AsType<Double>);
          tkChar,
          tkWChar:  result:= FloatToStr(AValue.AsType<Double>)[1];
          tkVariant: result:= TValue.FromVariant(AValue.AsVariant);
        end;
      tkString,
      tkLString,
      tkWString,
      tkUString: begin
        if AValue.AsString='' then
          TValue.MakeWithoutCopy(nil, ATypeInfo, Result)
        else
          case ATypeInfo.Kind of
            tkInteger: result:= StrToInt(AValue.AsString);
            tkInt64:  result:= StrToInt64(AValue.AsString);
            tkFloat: if ATypeInfo = TypeInfo(TDateTime) then
                        result:= StrToDateTime(Avalue.AsString)
                     else
                     if ATypeInfo = TypeInfo(TDate) then
                        result:= StrToDate(Avalue.AsString)
                     else
                       result:= StrToFloat(AVAlue.AsString);
            tkEnumeration: begin
                    LInt:= GetEnumValue(ATypeInfo, AValue.AsString);
                    TValue.Make(@LInt, ATypeInfo, Result);
            end;
            tkVariant: result:= TValue.FromVariant(AValue.AsVariant);
          end;
      end;
      tkvariant: begin end;

    end;
  end;

  // la salida espera un tipo Nullable
  if LIsNullableResult then
  begin
    LValue:= MakeNullable(ToTypeInfo);
    SetNullableValue(LValue, Result);
    Result:= LValue;
  end;
end;


procedure RegisterGUIDTypeInfo(AInterfaceTypeInfo: PTypeInfo);
begin
  if (AInterfaceTypeInfo.Kind=tkInterface) And (GetTypeData(AInterfaceTypeInfo).GUID<>TGUID.Empty) and
     not FGUIDTypeInfo.ContainsKey(GetTypeData(AInterfaceTypeInfo).GUID) then
      FGUIDTypeInfo.Add(GetTypeData(AInterfaceTypeInfo).GUID, AInterfaceTypeInfo);
end;

function GUIDTypeInfo(const GUID: TGUID): PTypeInfo;
var
  LType: TRttiType;
begin
  if not FGUIDTypeInfo.TryGetValue(GUID, result) then
  begin
    for LType in TRttiContext.Create.GetTypes do
      if (LType is TRttiInterfaceType) And (TRttiInterfaceType(LType).GUID = GUID) then
      begin
        result:= LType.Handle;
        FGUIDTypeInfo.Add(GUID, result);
      end;
  end;
end;

function GetResultFromType(AtypeInfo: PTypeInfo; const Obj: TObject): TValue;
//var
//  LInterfaz: IInterface;
//  LResult: IInterface;
begin
  if ATypeInfo.Kind=tkClass then
    result := Obj
  else
    begin
      TValue.Make(nil, ATypeInfo, Result);
      Obj.GetInterface(GetTypeData(ATypeInfo).GUID, Result.GetReferenceToRawData^);
//      TValue.Make(@LResult, ATypeInfo, Result);
    end;
end;


function GetFieldOrProperty(ATypeInfo: Pointer; const Name: String): TRttiMember;
var
  LCtx: TRttiContext;
  LType: TRttiType;
begin
  LType := LCtx.GetType(ATypeInfo);
  result := LType.GetField(Name);
  if not Assigned(Result) then
    result := LType.GetProperty(Name);
  if not Assigned(result) then
    raise Exception.CreateFmt('Can''t find a member with name %s into class %s ',
        [Name, LType.Name]);
end;

function FindMember(ATypeInfo: Pointer; const Name: String): TRttiMember;
var
  LCtx: TRttiContext;
  LType: TRttiType;
begin
  LType := LCtx.GetType(ATypeInfo);
  result := LType.GetField(Name);
  if not Assigned(Result) then
    result := LType.GetProperty(Name);
  if not Assigned(Result) then
    result := LType.GetMethod(Name);
  if not Assigned(Result) then
    result := LType.GetMethod('Set'+Name);
  if not Assigned(Result) then
    result := LType.GetMethod('Get'+Name);
end;

function FindMemberGetter(ATypeInfo: Pointer; const Name: String): TRttiMember;
var
  LCtx: TRttiContext;
  LType: TRttiType;
begin
  LType := LCtx.GetType(ATypeInfo);
  result := LType.GetField(Name);
  if not Assigned(Result) then
    result := LType.GetProperty(Name);
  if not Assigned(Result) then
    result := LType.GetMethod('Get'+Name);
  if not Assigned(Result) then
  begin
    result := LType.GetMethod(Name);
    if (result<>nil) And not IsGetter(TRttiMethod(result)) then
      result:= nil;
  end;
end;


function TryGetPropertyValue(Instance: TValue; PropertyName: String; out Value: TValue): boolean;
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMember: TRttiMember;

begin
  LType := LCtx.GetType(Instance.TypeInfo);

  LMember := LType.GetField(PropertyName);

  if not Assigned(LMember) then
    LMember := LType.GetProperty(PropertyName);

  if not Assigned(LMember) then
    LMember := LType.GetMethod('Get'+PropertyName);

  if not Assigned(LMember) then
  begin
    LMember := LType.GetMethod(PropertyName);
    if (LMember<>nil) And not IsGetter(TRttiMethod(LMember)) then
      LMember:= nil;
  end;

  result:= LMember<>nil;

  if result then
    Value:= LMember.GetValue(Instance);
end;

function FindMemberSetter(ATypeInfo: Pointer; const Name: String): TRttiMember;
var
  LCtx: TRttiContext;
  LType: TRttiType;
begin
  LType := LCtx.GetType(ATypeInfo);
  result := LType.GetField(Name);
  if not Assigned(Result) then
    result := LType.GetProperty(Name);
  if not Assigned(Result) then
    result := LType.GetMethod('Set'+Name);
  if not Assigned(Result) then
  begin
    result := LType.GetMethod(Name);
    if (result<>nil) And not IsSetter(TRttiMethod(result)) then
      result:= nil;
  end;
end;


function GetMember(ATypeInfo: Pointer; const Name: String): TRttiMember;
begin
  result := FindMember(AtypeInfo, Name);
  if not Assigned(result) then
    raise Exception.CreateFmt('Can''t find a member with name %s into class %s ',
        [Name, PTypeInfo(ATypeInfo).Name]);
end;

function IsGetter(Method: TRttiMethod): Boolean;
begin
  result:= (Method.MethodKind= mkFunction) And (Length(Method.GetParameters)=0);
end;


function IsSetter(Method: TRttiMethod): Boolean;
begin
  result:= (Method.MethodKind= mkProcedure) And (Length(Method.GetParameters)=1);
end;

//function GetMemberValue(AObject: TValue; const Name: String): TValue;
//var
//  LIndex: integer;
//  c: char;
//  LMemberValue: TValue;
//  LToken, LRest: String;
//
//begin
//  LIndex := 0;
//  for c in Name do
//    if c<>'.' then inc(LIndex)
//    else break;
//  if LIndex=0 then
//    raise Exception.Create('Invalid member name');
//
//  LToken:= Copy(Name, 1, LIndex);
//  LRest:= Copy(Name, LIndex+2, Length(Name));
//
//  LMemberValue:= GetMember(AObject.TypeInfo, LToken).GetValue(AObject);
//
//  if LRest='' then
//    result := LMemberValue
//  else
//  begin
//    if LMemberValue.IsObject then
//      result := GetMemberValue(LMemberValue.AsObject,LRest)
//    else
//    if LMemberValue.TypeInfo.Kind = tkInterface then
//      result := GetMemberValue(TObject(LMemberValue.AsInterface),LRest)
//    else
//      raise Exception.Create('Invalid member name. '+LToken+' is not a object or interface.');
//  end;
//end;
//
//procedure SetMemberValue(AObject: TValue; const Name: String; const Value: TValue);
//var
//  LIndex: integer;
//  c: char;
//  LToken, LRest: String;
//  LMemberValue: TValue;
//begin
//  LIndex := 0;
//  for c in Name do
//    if c<>'.' then inc(LIndex)
//    else break;
//
//  if LIndex=0 then
//    raise Exception.Create('Invalid member name');
//
//  LToken:= Copy(Name, 1, LIndex);
//  LRest:= Copy(Name, LIndex+2, Length(Name));
//
//  if LIndex= length(Name) then
//     GetMember(AObject.TypeInfo, LToken).SetValue(AObject, Value)
//  else
//    begin
//      LMemberValue:=GetMember(AObject.TypeInfo, LToken).GetValue(AObject);
//      if LMemberValue.IsObject then
//        SetMemberValue(LMemberValue.AsObject,LRest, Value)
//      else
//      if LMemberValue.TypeInfo.Kind = tkInterface then
//        SetMemberValue(TObject(LMemberValue.AsInterface),LRest, Value)
//      else
//        raise Exception.Create('Invalid member name. '+LToken+' is not a object or interface.');
//    end;
//
//end;


function TryGetObjectFromValue(const AValue: TValue; out AObject: TObject): boolean;
begin
  if (AValue.IsEmpty) then
    AObject:= nil
  else
  if AValue.TypeInfo.Kind=tkInterface then
    AObject := TObject(Avalue.AsInterface)
  else if AValue.IsObject then
    AObject := AValue.AsObject
  else
    AObject := nil;

  result := AObject<>nil;
end;

function GetObjectFromValue(AValue: TValue): TObject;
begin
  if not TryGetObjectFromValue(AValue, result) then
    raise Exception.Create('Invalid object value');
end;

{ TRttiTypeHelper }

procedure TRttiTypeHelper.ForEachMemberAttributeOfType<T>(
  Proc: TForEachTypeAttributeOfType<T>; Filter :TAttributeFilter<T>);
var
  LMember: TRttiMember;
  LType: TRttiType;
  LProc: TForEachAttributeOfType<T>;
begin
  LType := Self;
  LProc := procedure (Attribute: T)
  begin
    Proc(Attribute, LMember)
  end;

  for LMember in LType.GetFields do
      LMember.ForEachAttributeOfType<T>(LProc, Filter);

  for LMember in LType.GetProperties do
      LMember.ForEachAttributeOfType<T>(LProc, Filter);

end;

procedure TRttiTypeHelper.ForEachMemberAttributeOfType<T>(
  Proc: TForEachTypeAttributeOfType<T>);
begin
  ForEachMemberAttributeOfType<T>(Proc, function (Attribute: T) : boolean
    begin
      result := TRUE;
    end);
end;


function TRttiTypeHelper.GetMemberAttributesOfType<T>(Filter: TAttributeFilter<T>): TArray<TAttrRecord<T>>;
var
  LMember: TRttiMember;
  LIndex: Integer;
  LProc: TForEachAttributeOfType<T>;
  LType: TRttiType;
  LOut: TArray<TAttrRecord<T>>;

begin
  LIndex := 0;
  SetLength(LOut, 10);

  LProc := procedure (Attribute: T)
      begin
        LOut[LIndex].Attribute := Attribute;
        LOut[LIndex].Member := LMember;
        inc(LIndex);
        if LIndex = Length(LOut) then
          SetLength(LOut, LIndex + 10);
      end;

  LType := Self;

  while Assigned(LType) do
  begin
    for LMember in LType.GetFields do
     LMember.ForEachAttributeOfType<T>(LProc, Filter);

    for LMember in Ltype.GetProperties do
      LMember.ForEachAttributeOfType<T>(LProc, Filter);

    LType := LType.BaseType;
  end;

  if LIndex < Length(LOut) then
    SetLength(LOut, LIndex);

  result := LOut;
end;

function TRttiTypeHelper.GetMemberAttributesOfType<T>: TArray<TAttrRecord<T>>;
begin
  result := GetMemberAttributesOfType<T>(function (Attribute: T): boolean
    begin
      result := TRUE;
    end);
end;

{ TRttiMemberHelper }

procedure TRttiMemberHelper.ForEachAttributeOfType<T>(
  Proc: TForEachAttributeOfType<T>; Filter : TAttributeFilter<T>);
var
  LAttr: TCustomAttribute;
begin
   for LAttr in GetAttributes do
   begin
    if LAttr is T And Filter(T(LAttr)) then
    begin
      Proc(T(LAttr));
    end;
   end;
end;

procedure TRttiMemberHelper.ForEachAttributeOfType<T>(
  Proc: TForEachAttributeOfType<T>);
begin
  ForEachAttributeOfType<T>(Proc, function (Attribute: T) : boolean
    begin
      result := TRUE;
    end);
end;

function TRttiMemberHelper.GetAttributesOfType<T> (Filter: TAttributeFilter<T>): TArray<T>;
var
  LAttr: TCustomAttribute;
  LIndex: Integer;
begin
  LIndex := 0;
  SetLength(Result, 0);
  for LAttr in GetAttributes do
    if LAttr is T  and (Filter(T(LAttr))) then
    begin
      SetLength(Result, LIndex + 1);
      Result[LIndex] := T(LAttr);
      inc(LIndex);
    end;
end;

function TRttiMemberHelper.GetAttributeOfType<T> (Filter: TAttributeFilter<T>): T;
var
  LAttr: TCustomAttribute;
begin

  for LAttr in GetAttributes do
    if LAttr is T  and (Filter(T(LAttr))) then
      Exit(T(LAttr));

  result := nil;
end;

function TRttiMemberHelper.GetValue(Instance: TValue): TValue;
begin
  if (self is TRttiProperty) And (Instance.IsObject) then
    Exit(TRttiProperty(Self).GetValue(Instance.AsObject));
  if (self is TRttiField) And (Instance.IsObject)then
    Exit(TRttiField(Self).GetValue(Instance.AsObject));
  if (self is TRttiMethod) then
     if  Not IsGetter(TRttiMethod(Self)) then
        raise Exception.CreateFmt('%s.%s is not getter method',
                [TRttiMethod(Self).Parent.Name,TRttiMethod(Self).Name])
     else
      Exit(TRttiMethod(Self).Invoke(Instance,[]));

  raise Exception.Create('Invalid member type in GetValue method.');
end;

procedure TRttiMemberHelper.SetValue(Instance: TValue; AValue: TValue);
var
  FNullable: TValue;

begin

  if not (Self is TRttiMethod) And (AValue.TypeInfo<>TypeInfo) And IsNullable(TypeInfo) then
  begin
    FNullable:= GetValue(Instance);
    TRttiContext.Create.GetType(TypeInfo).GetMethod('SetValue').Invoke(FNullable,[AValue]);
    AValue:= FNullable;
  end;

  if (self is TRttiProperty) And (Instance.IsObject) then
    TRttiProperty(Self).SetValue(Instance.AsObject, AValue)
  else
  if (self is TRttiField) And (Instance.IsObject) then
    TRttiField(Self).SetValue(Instance.AsObject, AValue)
  else
  if (self is TRttiMethod) then
     if  Not IsSetter(TRttiMethod(Self)) then
        raise Exception.CreateFmt('%s.%s is not setter method',
                [TRttiMethod(Self).Parent.Name,TRttiMethod(Self).Name])
     else
      TRttiMethod(Self).Invoke(Instance,[AValue])
  else
  raise Exception.Create('Invalid member type in SetValue method.');

end;

function TRttiMemberHelper.TypeInfo: PTypeInfo;
begin
  if (self is TRttiProperty) then
    result:= TRttiProperty(Self).PropertyType.Handle
  else
  if (self is TRttiField) then
    result:= TRttiField(Self).FieldType.Handle
  else
  if (Self is TRttiMethod) then
    if (TRttiMethod(Self).MethodKind = mkFunction) then
      result := TRttiMethod(Self).ReturnType.Handle
    else
    if IsSetter(TRttiMethod(Self)) then
      result := TRttiMethod(Self).GetParameters[0].ParamType.Handle
    else
      raise Exception.Create('Invalid member type in TypeInfo method.'+Self.ClassName);
end;

function TRttiMemberHelper.GetAttributesOfType<T>: TArray<T>;
begin
  result := GetAttributesOfType<T>(function (Attribute: T): boolean
    begin
      result := true
    end);
end;

function TRttiMemberHelper.GetAttributeOfType<T>: T;
begin
  result := GetAttributeOfType<T>(function (Attribute: T): boolean
    begin
      result := true
    end);
end;

{ TIIF }

class procedure TUtil.Append<T>(var Data: TArray<T>; Value: T);
begin

  if Data=nil then
    SetLength(Data, 1)
  else
    SetLength(Data, Length(Data)+1);

  Data[Length(Data)-1]:= Value;
end;

class function TUtil.ArrayToTArray<T>(Data: array of T): TArray<T>;
var
  i: Integer;
begin
  SetLength(Result, Length(Data));
  for i:= 0 to Length(Data)-1 do Result[i]:= Data[i];
end;

class constructor TUtil.Create;
begin
  FGUIDTypeInfo:= TDictionary<TGUID, PTypeInfo>.Create;
end;

class destructor TUtil.Destroy;
begin
  FGUIDTypeInfo.Free;
end;

class procedure TUtil.FreeInterfaceList<T>(AList: TList<T>);
var
  i: integer;
begin
  for I := 0 to Alist.Count-1 do
      AList[i]:= nil;
  AList.Free;
end;

class function TUtil.GetGUIDTypeInfo(IID: TGUID): PTypeInfo;
var
  LType: TRttiType;
begin
  if not FGUIDTypeInfo.TryGetValue(IID, result) then
  begin
    result:= nil;
    for LType in TRttiContext.Create.GetTypes do
    begin
      if (LType is TRttiInterfaceType) And  (GetTypeData(LType.Handle).Guid=IID) then
      begin
        result:= LType.Handle;
        break;
      end;
    end;

    FGUIDTypeInfo.AddOrSetValue(IID,Result);
  end;

end;

class function TUtil.IIf<T>(const Expression: Boolean; TrueValue,
  FalseValue: T): T;
begin
  if Expression then
    result := TrueValue
  else
    result := FalseValue
end;

class procedure TUtil.RegisterGUID(ATypeInfo: PTypeInfo);
begin
  if (ATypeInfo.Kind= tkInterface) then
    FGUIDTypeInfo.AddOrSetValue(GetTypeData(ATypeInfo).GUID, AtypeInfo );
end;


function CompareValue(const Left, Right: TValue): Integer;
var
  LLeft, LRight: TValue;
begin
  if IsNullable(Left) Or IsNullable(Right) then
  begin
    if IsNullable(Left) then
      LLeft:= GetNullableValue(Left)
    else
      LLeft:= Left;

    if IsNullable(Right) then
      LRight:= GetNullableValue(Right)
    else
      LRight:= Right;

    result:= CompareValue(LLeft, LRight);
  end
  else
  if Left.IsEmpty Or Right.IsEmpty then
  begin
    if Left.IsEmpty AND Right.IsEmpty then
      result:=0
    else
    if Left.IsEmpty then
      result:=1
    else
      result:= -1;
  end
  else
  if Left.IsOrdinal and Right.IsOrdinal then
  begin
    Result := Math.CompareValue(Left.AsOrdinal, Right.AsOrdinal);
  end else
  if Left.IsFloat and Right.IsFloat then
  begin
    Result := Math.CompareValue(Left.AsFloat, Right.AsFloat);
  end else
  if Left.IsString and Right.IsString then
  begin
    Result := SysUtils.CompareStr(Left.AsString, Right.AsString);
  end else
  begin
    Result := 0;
  end;
end;

function SameValue(const Left, Right: TValue): Boolean;
var
  LLeft, LRight: TValue;

  function IsEmpty(const v: TValue): boolean;
  begin
    result:= v.IsEmpty or (v.ToString='')
  end;

begin
  if IsNullable(Left) Or IsNullable(Right) then
  begin
    if IsNullable(Left) then
      LLeft:= GetNullableValue(Left)
    else
      LLeft:= Left;

    if IsNullable(Right) then
      LRight:= GetNullableValue(Right)
    else
      LRight:= Right;

    result:= SameValue(LLeft, LRight);
  end
  else
  if IsEmpty(Left) Or IsEmpty(Right) then
    result:= IsEmpty(Left) AND IsEmpty(Right)
  else
  if Left.IsNumeric and Right.IsNumeric then
  begin
    if Left.IsOrdinal then
    begin
      if Right.IsOrdinal then
      begin
        Result := Left.AsOrdinal = Right.AsOrdinal;
      end else
      if Right.IsSingle then
      begin
        Result := Math.SameValue(Left.AsOrdinal, Right.AsSingle);
      end else
      if Right.IsDouble then
      begin
        Result := Math.SameValue(Left.AsOrdinal, Right.AsDouble);
      end
      else
      begin
        Result := Math.SameValue(Left.AsOrdinal, Right.AsExtended);
      end;
    end else
    if Left.IsSingle then
    begin
      if Right.IsOrdinal then
      begin
        Result := Math.SameValue(Left.AsSingle, Right.AsOrdinal);
      end else
      if Right.IsSingle then
      begin
        Result := Math.SameValue(Left.AsSingle, Right.AsSingle);
      end else
      if Right.IsDouble then
      begin
        Result := Math.SameValue(Left.AsSingle, Right.AsDouble);
      end
      else
      begin
        Result := Math.SameValue(Left.AsSingle, Right.AsExtended);
      end;
    end else
    if Left.IsDouble then
    begin
      if Right.IsOrdinal then
      begin
        Result := Math.SameValue(Left.AsDouble, Right.AsOrdinal);
      end else
      if Right.IsSingle then
      begin
        Result := Math.SameValue(Left.AsDouble, Right.AsSingle);
      end else
      if Right.IsDouble then
      begin
        Result := Math.SameValue(Left.AsDouble, Right.AsDouble);
      end
      else
      begin
        Result := Math.SameValue(Left.AsDouble, Right.AsExtended);
      end;
    end
    else
    begin
      if Right.IsOrdinal then
      begin
        Result := Math.SameValue(Left.AsExtended, Right.AsOrdinal);
      end else
      if Right.IsSingle then
      begin
        Result := Math.SameValue(Left.AsExtended, Right.AsSingle);
      end else
      if Right.IsDouble then
      begin
        Result := Math.SameValue(Left.AsExtended, Right.AsDouble);
      end
      else
      begin
        Result := Math.SameValue(Left.AsExtended, Right.AsExtended);
      end;
    end;
  end else
  if Left.IsString and Right.IsString then
  begin
    Result := Left.AsString = Right.AsString;
  end else
  if Left.IsClass and Right.IsClass then
  begin
    Result := Left.AsClass = Right.AsClass;
  end else
  if Left.IsObject and Right.IsObject then
  begin
    Result := Left.AsObject = Right.AsObject;
  end else
  if Left.IsPointer and Right.IsPointer then
  begin
    Result := Left.AsPointer = Right.AsPointer;
  end else
  if Left.IsVariant and Right.IsVariant then
  begin
    Result := Left.AsVariant = Right.AsVariant;
  end else
  if Left.TypeInfo.Kind = Right.TypeInfo.Kind then
  begin
    Result := Left.AsPointer = Right.AsPointer;
  end else
  begin
    Result := False;
  end;
end;

{ TValueHelper }

function TValueHelper.AsDouble: Double;
begin
  Result := AsType<Double>;
end;

function TValueHelper.AsFloat: Extended;
begin
  Result := AsType<Extended>;
end;

function TValueHelper.AsPointer: Pointer;
begin
  ExtractRawDataNoCopy(@Result);
end;

function TValueHelper.AsSingle: Single;
begin
  Result := AsType<Single>;
end;

function TValueHelper.ConvertTo(ToTypeInfo: PTypeInfo): TValue;
begin
  result:= ConvertValue(Self, ToTypeInfo);
end;

function TValueHelper.ConvertTo<T>: TValue;
begin
  result:= ConvertTo(System.TypeInfo(T));
end;

function TValueHelper.Equals(const value : TValue) : boolean;
begin
  result := SameValue(Self, value);
end;

function TValueHelper.IsBoolean: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Boolean);
end;

function TValueHelper.IsByte: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Byte);
end;

function TValueHelper.IsCardinal: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Cardinal);
end;

function TValueHelper.IsCurrency: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Currency);
end;

function TValueHelper.IsDate: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(TDate);
end;

function TValueHelper.IsDateTime: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(TDateTime);
end;

function TValueHelper.IsDouble: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Double);
end;

function TValueHelper.IsFloat: Boolean;
begin
  Result := Kind = tkFloat;
end;

function TValueHelper.IsInt64: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Int64);
end;

function TValueHelper.IsInteger: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Integer);
end;

function TValueHelper.IsInterface: Boolean;
begin
  result := Kind = tkInterface;
end;

function TValueHelper.IsNumeric: Boolean;
begin
  Result := Kind in [tkInteger, tkChar, tkEnumeration, tkFloat, tkWChar, tkInt64];
end;

function TValueHelper.IsPointer: Boolean;
begin
  Result := Kind = tkPointer;
end;

function TValueHelper.IsShortInt: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(ShortInt);
end;

function TValueHelper.IsSingle: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Single);
end;

function TValueHelper.IsSmallInt: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(SmallInt);
end;

function TValueHelper.IsString: Boolean;
begin
  Result := Kind in [tkChar, tkString, tkWChar, tkLString, tkWString, tkUString];
end;

function TValueHelper.IsTime: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(TTime);
end;

function TValueHelper.IsUInt64: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(UInt64);
end;

function TValueHelper.IsVariant: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Variant);
end;

function TValueHelper.IsWord: Boolean;
begin
  Result := TypeInfo = System.TypeInfo(Word);
end;


function ValueAsVariant(const AValue: TValue): Variant;
begin
  if AValue.IsEmpty then
    result:= NULL
  else
  if IsNullable(AValue) then
    result:= ValueAsVariant(GetNullableValue(AValue))
  else
  if not (AValue.IsEmpty) And (AValue.TypeInfo.Kind = tkClass) then
    result:= Integer(AValue.AsObject)
  else
  if AValue.TypeInfo=TypeInfo(Boolean) then
    result:= AValue.AsBoolean
  else
  if AValue.TypeInfo.Kind = tkEnumeration then
    result:= AValue.ToString
  else
    result:= AValue.AsVariant;
end;

initialization
  FGUIDTypeInfo:= TDictionary<TGUID, PTypeInfo>.Create;
finalization
  FGUIDTypeInfo.Free;
end.
