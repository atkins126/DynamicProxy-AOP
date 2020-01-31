unit SGT.TypeInfo;

interface

uses SGT.AspectsIntf, Rtti, Generics.Collections, TypInfo, Sgt.AspectCollection,
  SysUtils;

type

  TTypeInfo = class (TAspectCollection, ITypeInfo)
  private
    class var FTypes: TDictionary<PTypeInfo, ITypeInfo>;
    FProps: TList<IPropertyInfo>;
    FMethods: TList<IMethodInfo>;

    function TypeInfo: TRttiType;
    function Properties: TArray<IPropertyInfo>;
    function GetMethods: TArray<IMethodInfo>;
    function GetMethod(MethodName:string): IMethodInfo;
    constructor Create(ARttiType: TRttiType);
    function Invoke(MethodName: string; const Instance: IInstance; Args: TArray<TValue>; AvoidTypeAspects: boolean = false): TValue;
  public
    destructor Destroy; override;
    class constructor Create;
    class destructor Destroy;
    class procedure AddType(ATypeInfo: PTypeInfo);
    class function GetType(ATypeInfo: PTypeInfo): ITypeInfo;

  end;

implementation

uses SGT.MethodInfo, SGT.RttiHelpers;

{ TTypeInfo }

class procedure TTypeInfo.AddType(ATypeInfo: PTypeInfo);
var
  LCtx: TRttiContext;
begin
  if FTypes.ContainsKey(ATypeInfo) then
    Exit;

  MonitorEnter(FTypes);
  try

    LCtx:= TRttiContext.Create;
    try
      FTypes.Add(AtypeInfo, TTypeInfo.Create(LCtx.GetType(ATypeInfo)));
    finally
      LCtx.Free;
    end;
  finally
    MonitorExit(FTypes)
  end;
end;

class constructor TTypeInfo.Create;
begin
  FTypes:= TDictionary<PTypeInfo, ITypeInfo>.Create;
end;

destructor TTypeInfo.Destroy;
begin
  inherited;
  TUtil.FreeInterfaceList<IMethodInfo>(FMethods);
  TUtil.FreeInterfaceList<IPropertyInfo>(FProps);
end;

constructor TTypeInfo.Create(ARttiType: TRttiType);
var
  LMethod: TRttiMethod;
begin
  inherited Create(ARttiType);

  FMethods:= TList<IMethodInfo>.Create;
  FProps:= TList<IPropertyInfo>.Create;
  for LMethod in ARttiType.GetMethods() do
    FMethods.Add(TMethodInfo.Create(Self, LMethod));
end;

class destructor TTypeInfo.Destroy;
var
  LKey: PTypeInfo;
begin
  for LKey in TTypeInfo.FTypes.Keys do
    TTypeInfo.FTypes[LKey]:= nil;
  FTypes.Free;
end;

function TTypeInfo.GetMethod(MethodName: string): IMethodInfo;
var
  LMethodInfo: IMethodInfo;
begin
  for LMethodInfo in FMethods do
    if (CompareText(LMethodInfo.GetRttiMethod.Name, MethodName)= 0) then
      Exit(LMethodInfo);

  result:= nil;
end;

function TTypeInfo.GetMethods: TArray<IMethodInfo>;
begin
  result:= FMethods.ToArray();
end;

class function TTypeInfo.GetType(ATypeInfo: PTypeInfo): ITypeInfo;
begin
  if not FTypes.TryGetValue(ATypeInfo, result) then
  begin
    AddType(ATypeInfo);
    result:= GetType(ATypeInfo);
  end;
end;

function TTypeInfo.Invoke(MethodName: string; const Instance: IInstance;
  Args: TArray<TValue>; AvoidTypeAspects: boolean): TValue;
var
  LMethod: IMethodInfo;
begin
  LMethod:= GetMethod(MethodName);
  if not Assigned(LMethod) then
    raise Exception.CreateFmt('Can''t find method %s', [MethodName]);
  result:= LMethod.Invoke(Instance, Args, AvoidTypeAspects);
end;

function TTypeInfo.Properties: TArray<IPropertyInfo>;
begin
  result:= FProps.ToArray();
end;

function TTypeInfo.TypeInfo: TRttiType;
begin
  result:=  TRttiType(RttiType)
end;

end.
