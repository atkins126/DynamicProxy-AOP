unit SGT.Nullable;

// Código de http://blogs.embarcadero.com/abauer/2008/09/18/38869

interface
uses SysUtils, Rtti, TypInfo;


type

  // Como se indica en el articulo, esta clase solo es para ser usada como
  // campo de una clase que automaticamente inicializa FHasValue a false o
  // creada con uno de los constructores create para que FHasValue esté
  // correctemente inicializada

  // Packed record asegura que los datos estarán en posiciones de memoria contiguas
  // necesario para su tratamiento a bajo nivel

  Nullable<T> = packed record
  private
    FHasValue: Boolean;
    FValue: T;
    function GetValue: T;
    function GetHasValue: Boolean;
  public
    constructor Create(AValue: T); overload;
    procedure SetValue(Value: T);
    function GetValueOrDefault: T; overload;
    function GetValueOrDefault(Default: T): T; overload;
    procedure Clear;
    property HasValue: Boolean read GetHasValue;
    property Value: T read GetValue;

    class operator NotEqual(const ALeft, ARight: Nullable<T>): Boolean;
    class operator Equal(ALeft, ARight: Nullable<T>): Boolean;

    class operator Implicit(Value: Nullable<T>): T;
    class operator Implicit(Value: T): Nullable<T>;
    class operator Explicit(Value: Nullable<T>): T;

    class function TypeInfo: PTypeInfo; static;
    class function Empty: Nullable<T>; static;
  end;

function IsNullable(const AValue:TValue): Boolean; overload;
function IsNullable(ATypeInfo: PTypeInfo): Boolean; overload;
function GetNullableValue(const AValue: TValue): TValue;
procedure SetNullableValue(const ANullableValue, AValue: TValue);
function MakeNullable(TypeInfo: PTypeInfo): TValue;
function NullableValueTypeInfo(TypeInfo: PTypeInfo): PTypeInfo;

implementation

Uses System.Generics.Defaults;

function IsNullable(const AValue:TValue): Boolean;
begin
  result:= not AValue.IsEmpty and IsNullable(AValue.TypeInfo);
end;

function IsNullable(ATypeInfo: PTypeInfo): Boolean;
begin
  result:= (ATypeInfo.Kind = tkRecord) and (Copy(LowerCase(ATypeInfo.Name), 1, 9)='nullable<')
end;

function GetNullableValue(const AValue: TValue): TValue;
var
  LMethod: TRttiField;
begin
  if not IsNullable(AValue) then
    raise Exception.Create('Not is a nullable value.');
  if Boolean(AValue.GetReferenceToRawData^) then
  begin
    LMethod:= TRttiContext.Create.GetType(AValue.TypeInfo).GetField('FValue');
    result:= LMethod.GetValue(AValue.GetReferenceToRawData);
  end
  else
    result:= TValue.Empty;
end;

procedure SetNullableValue(const ANullableValue, AValue: TValue);
var
  LCtx: TRttiContext;
  LInternalValue: TValue;
begin
  if not IsNullable(ANullableValue) then
    raise Exception.Create('Not is a nullable value.');

  if AValue.IsEmpty then
    Boolean(AValue.GetReferenceToRawData^):= FALSE
  else
    if IsNullable(AValue) then
    begin
      Move(AValue.GetReferenceToRawData^, ANullableValue.GetReferenceToRawData^, SizeOf(Boolean));
      if Not Boolean(AValue.GetReferenceToRawData^) then
        Exit;
      LCtx.GetType(ANullableValue.TypeInfo).GetMethod('SetValue').Invoke(ANullableValue,[GetNullableValue(AValue)]);
    end
    else
      LCtx.GetType(ANullableValue.TypeInfo).GetMethod('SetValue').Invoke(ANullableValue,[AValue])
end;

function MakeNullable(TypeInfo: PTypeInfo): TValue;
begin
  if not IsNullable(TypeInfo) then
    raise Exception.Create('Not is a nullable type.');
  TValue.Make(NIL, TypeInfo, result);
  Boolean(Result.GetReferenceToRawData^):= FALSE
end;

function NullableValueTypeInfo(TypeInfo: PTypeInfo): PTypeInfo;
begin
  if not IsNullable(TypeInfo) then
    raise Exception.Create('Not is a nullable type.');
  result:= TRttiContext.Create.GetType(TypeInfo).GetField('FValue').FieldType.Handle;
end;

{ Nullable<T> }

procedure Nullable<T>.Clear;
begin
  FValue:= Default(T);
  FHasValue:= FALSE;
end;

constructor Nullable<T>.Create(AValue: T);
begin
  FValue := AValue;
  FHasValue:= TRUE;
end;

class function Nullable<T>.Empty: Nullable<T>;
begin
  Result.FHasValue:= FALSE;
  Result.FValue:= Default(T);
end;

class operator Nullable<T>.Equal(ALeft, ARight: Nullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TEqualityComparer<T>.Default;
    Result := Comparer.Equals(ALeft.Value, ARight.Value);
  end else
    Result := ALeft.HasValue = ARight.HasValue;
end;

class operator Nullable<T>.Explicit(Value: Nullable<T>): T;
begin
  Result := Value.Value;
end;

function Nullable<T>.GetHasValue: Boolean;
begin
  Result := FHasValue;
end;

function Nullable<T>.GetValue: T;
begin
  if not HasValue then
    //raise Exception.Create('Invalid operation, Nullable type has no value');
    result:= Default(T)
  else
    Result := FValue;
end;

function Nullable<T>.GetValueOrDefault: T;
begin
  if HasValue then
    Result := FValue
  else
    Result := Default(T);
end;

function Nullable<T>.GetValueOrDefault(Default: T): T;
begin
  if not HasValue then
    Result := Default
  else
    Result := FValue;
end;


class operator Nullable<T>.Implicit(Value: Nullable<T>): T;
begin
  Result := Value.Value;
end;

class operator Nullable<T>.Implicit(Value: T): Nullable<T>;
begin
  Result := Nullable<T>.Create(Value);
end;

class operator Nullable<T>.NotEqual(const ALeft, ARight: Nullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TEqualityComparer<T>.Default;
    Result := not Comparer.Equals(ALeft.Value, ARight.Value);
  end else
    Result := ALeft.HasValue <> ARight.HasValue;
end;

procedure Nullable<T>.SetValue(Value: T);
begin
  FValue:= Value;
  FHasValue:= TRUE;
end;

class function Nullable<T>.TypeInfo: PTypeInfo;
begin
  result:= System.TypeInfo(T);
end;

end.
