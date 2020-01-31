unit SGT.MethodInfo;

interface

uses SGT.AspectsIntf, Rtti, Generics.Collections, SGT.AspectCollection, TypInfo, SysUtils;

type
  TMethodInfo = class(TAspectCollection, IMethodInfo)
  private
    FTypeInfo: Pointer;
    FParametersInfo: IParametersInfo;
    function Invoke(const Instance: IInstance; Args: TArray<TValue>; AvoidTypeAspects: boolean = false): TValue;
    function ClassTypeInfo: ITypeInfo;
    function GetRttiMethod: TRttiMethod;
    function Parameters: IParametersInfo;
    //function PropertyAspect: IAspect;
  public
    constructor Create(const ATypeInfo: ITypeInfo; AMethod: TRttiMethod);
    destructor Destroy; override;
  end;

implementation

type

  TParameterInfo = class (TInterfacedObject, IParameterInfo)
  private
    FParameterInfo: TRttiParameter;
    FPosition: integer;
    function RttiInfo:TRttiParameter;
    function IsRef: boolean;
    function Position: integer;
  public
    constructor Create(AParameterInfo: TRTtiParameter; Position: integer);
  end;

{$region  'TParameterInfo' }

constructor TParameterInfo.Create(AParameterInfo: TRTtiParameter; Position: integer);
begin
  FParameterInfo:= AParameterInfo;
  FPosition:= Position;
end;

function TParameterInfo.IsRef: boolean;
begin
  result:= (pfVar in FParameterInfo.Flags) OR  (pfOut in FParameterInfo.Flags);
end;

function TParameterInfo.Position: integer;
begin
  result:= FPosition;
end;

function TParameterInfo.RttiInfo: TRttiParameter;
begin
  result:= FParameterInfo;
end;
{$endregion}


type
  TParametersInfo = class(TInterfacedObject, IParametersInfo)
  private
    FParameters: TList<IParameterInfo>;
    FHasRef: Boolean;
  public
    function ParametersInfo: TArray<IParameterInfo>;
    function Parameter(index: integer): IParameterInfo; overload;
    function Parameter(name: string): IParameterInfo; overload;
    function HasRefParameters: boolean;
    function Count: integer;
    constructor Create(AMethod: TRttiMethod);
    destructor Destroy; override;
  end;

{$region 'TParametersInfo' }

function TParametersInfo.Count: integer;
begin
  result:= FParameters.Count;
end;

constructor TParametersInfo.Create(AMethod: TRttiMethod);
var
  LParam: TRttiParameter;

begin
  FParameters:= TList<IParameterInfo>.Create();
  FHasRef:= false;

  for LParam in AMethod.GetParameters() do
  begin
    FParameters.Add(TParameterInfo.Create(LParam, FParameters.Count));
    FHasRef:= FHasRef OR (pfVar IN LParam.Flags) OR (pfOut IN LParam.Flags);
  end;

end;

destructor TParametersInfo.Destroy;
begin
  FParameters.Free;
  inherited;
end;

function TParametersInfo.HasRefParameters: boolean;
begin
  result:= FHasRef;
end;

function TParametersInfo.Parameter(name: string): IParameterInfo;
var
  LInfo: IParameterInfo;
begin
   name:= LowerCase(name);
   for LInfo in FParameters do
    if LowerCase(LInfo.RttiInfo.Name)= name then
      Exit(LInfo);

   result:= nil;
end;

function TParametersInfo.Parameter(index: integer): IParameterInfo;
begin
  if (index> FParameters.Count) then
    Exit(nil);

  result:= FParameters[index];
end;

function TParametersInfo.ParametersInfo: TArray<IParameterInfo>;
begin
  result:= FParameters.ToArray();
end;
{$endregion}

type

  TParameterValues = class(TInterfacedObject, IParameterValues)
  private
    FParametersInfo: IParametersInfo;
    FValues: Array of TValue;
    function ParametersInfo: TArray<IParameterInfo>;
    function Parameter(index: integer): IParameterInfo; overload;
    function Parameter(name: string): IParameterInfo; overload;
    function Count: integer;
    function HasRefParameters: boolean;
    function Values: TArray<TValue>;
    procedure _Set(Name: string; value: TValue); overload;
    procedure _Set(Position:integer; value: TValue); overload;
    function Get(Name: String): TValue; overload;
    function Get(Position: integer): TValue; overload;
  public
    constructor Create(AParametersInfo: IParametersInfo; AValues: array of TValue);
  end;

{$region  'TParametersValue' }

function TParameterValues.Get(Name: String): TValue;
var
  LParam: IParameterInfo;
begin
  LParam:= FParametersInfo.Parameter(Name);
  if (LParam = nil) then
    raise Exception.CreateFmt('Parameter %s not found', [Name]);

  result:= FValues[LParam.Position];
end;

function TParameterValues.Count: integer;
begin
  result:= Length(FValues);
end;

constructor TParameterValues.Create(AParametersInfo: IParametersInfo; AValues: array of TValue);
var
  i: integer;
begin
  FParametersInfo:= AParametersInfo;
  SetLength(FValues, AParametersInfo.Count);
  for i:=0 to AParametersInfo.Count-1 do
    if i<= High(AValues) then
      FValues[i]:= AValues[i];
end;

function TParameterValues.Get(Position: integer): TValue;
begin
  if (Position>High(FValues)) then
    raise Exception.CreateFmt('Parameter %d out of index', [Position]);
  result:= FValues[Position];
end;

function TParameterValues.HasRefParameters: boolean;
begin
  result:= FParametersInfo.HasRefParameters;
end;

function TParameterValues.Parameter(name: string): IParameterInfo;
begin
  result:= FParametersInfo.Parameter(name);
end;

function TParameterValues.Parameter(index: integer): IParameterInfo;
begin
    result:= FParametersInfo.Parameter(index);
end;

function TParameterValues.ParametersInfo: TArray<IParameterInfo>;
begin
    result:= FParametersInfo.ParametersInfo;
end;

function TParameterValues.Values: TArray<TValue>;
var i: integer;
begin
  SetLength(result, Length(FValues));
  for i:= 0 to Length(FValues) -1 do
    result[i]:= FValues[i];

end;

procedure TParameterValues._Set(Name: string; value: TValue);
var
  LParam: IParameterInfo;
begin
  LParam:= FParametersInfo.Parameter(Name);
  if (LParam = nil) then
    raise Exception.CreateFmt('Parameter %s not found', [Name]);
  FValues[LParam.Position]:= value;
end;

procedure TParameterValues._Set(Position: integer; value: TValue);
begin
  if (Position>High(FValues)) then
    raise Exception.CreateFmt('Parameter %d out of index', [Position]);
  FValues[Position]:= value;
end;
{$endregion}

type
  TInvocationContext = class(TInterfacedObject, IInvocationContext)
  private
    FError: IError;
    FInstance: IInstance;
    FMethodInfo: IMethodInfo;
    FParameters: IParameterValues;
    FIndex: Integer;
    FAspectCollIndex: Integer;
    FCurrentAspects: Array [0..2] of IAspectCollection;
    function MethodInfo: IMethodInfo;
    function Instance: IInstance;
    function Parameters: IParameterValues;
    procedure SetError(Error: IError);
    function GetError: IError;
    property Error: IError read GetError write SetError;
    function InvokeNext: TValue;
  public
    constructor Create(AMethodInfo: TMethodInfo; AInstance: IInstance; AValues: Array of TValue; ApplyTypeAspects: Boolean = true);
  end;

{$region 'TInvocationContext' }

constructor TInvocationContext.Create(AMethodInfo: TMethodInfo;
  AInstance: IInstance; AValues: Array of TValue; ApplyTypeAspects: Boolean = true);begin
  FMethodInfo:= AMethodInfo;
  FInstance:= AInstance;
  FIndex:= 0;
  FParameters:= TParameterValues.Create(AMethodInfo.Parameters, AValues);

  if ApplyTypeAspects then
    FAspectCollIndex:= 0
  else
    FAspectCollIndex:= 1;

  FCurrentAspects[0]:= FMethodInfo.ClassTypeInfo;
  FCurrentAspects[1]:= FMethodInfo;
  FCurrentAspects[2]:= AInstance;
end;

function TInvocationContext.GetError: IError;
begin
  result:= FError;
end;

function TInvocationContext.Instance: IInstance;
begin
  result:= FInstance;
end;

function TInvocationContext.MethodInfo: IMethodInfo;
begin
  result:= FMethodInfo;
end;

function TInvocationContext.InvokeNext: TValue;
var
  LAspect: IAspect;
  LValues: Array of TValue;
  LArray: TArray<TValue>;
  i: integer;
begin
  LAspect:= FCurrentAspects[FAspectCollIndex].GetAspect(FIndex);
  if Assigned(LAspect) then
  begin
    FIndex:= FIndex + 1;
    result:= LAspect.Invoke(self);
  end
  else
    if (FAspectCollIndex < 2 ) then
    begin
      Inc(FAspectCollIndex);
      FIndex:=0;
      result:= InvokeNext;
    end
    else
    begin
      LArray:= FParameters.Values;
      SetLength(LValues, Length(LArray));
      for i:=0 to Length(LArray)-1 do
        LValues[i]:= LArray[i];

      result:= FMethodInfo.GetRttiMethod.Invoke(FInstance.InstanceRef, LArray)
    end;

end;

function TInvocationContext.Parameters: IParameterValues;
begin
  result:= FParameters;
end;

procedure TInvocationContext.SetError(Error: IError);
begin
  FError:= Error;
end;

{$endregion}

{ TMethodInfo }

function TMethodInfo.ClassTypeInfo: ITypeInfo;
begin
  result:= ITypeInfo(FTypeInfo)
end;

constructor TMethodInfo.Create(const ATypeInfo: ITypeInfo;
  AMethod: TRttiMethod);
begin
  inherited Create(AMethod);
  FTypeInfo:= Pointer(ATypeInfo);
  FParametersInfo:= TParametersInfo.Create(AMethod);
end;

destructor TMethodInfo.Destroy;
begin
  inherited;
end;

function TMethodInfo.GetRttiMethod: TRttiMethod;
begin
  result:= TRttiMethod(RttiType);
end;

function TMethodInfo.Invoke(const Instance: IInstance; Args: TArray<TValue>;
  AvoidTypeAspects: boolean): TValue;
var
  LInvocationCtx: IInvocationContext;
begin
  LInvocationCtx:= TInvocationContext.Create(Self, Instance, Args);
  result:= LInvocationCtx.InvokeNext;
end;

function TMethodInfo.Parameters: IParametersInfo;
begin
  result:= FParametersInfo;
end;

end.
