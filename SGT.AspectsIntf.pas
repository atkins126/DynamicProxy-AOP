unit SGT.AspectsIntf;

interface

uses Rtti, SysUtils;

type

  IAspect = interface;
  IMethodInfo = interface;

  IValue = interface
    ['{F62DEED4-9FA8-43CC-A4EE-E61FFE45A905}']
    function Get: TValue;
    procedure _Set(Value:TValue);
    function TypeInfo: TRttiType;
  end;

  IProperty = interface
    ['{F0163492-54A6-4CD7-B9AD-052834EF41F9}']
    function GetValue: IValue;
    procedure SetValue(Value: IValue);
    property Value: IValue read GetValue write SetValue;
    function Name: String;
  end;

  IAspectCollection = interface
    ['{CC214754-45B4-4D16-80ED-85F88F2166B5}']
    function AspectCount: integer;
    procedure AddAspect(Aspect: IAspect);
    function GetAspect(index: integer): IAspect;
    function Aspects: TArray<IAspect>;
  end;

  IPropertyInfo = interface(IAspectCollection)
    ['{C54FEC55-4179-458A-AC49-DF4A0508460D}']
    function RttiInfo: TRttiProperty;
  end;

  IInstance = interface (IAspectCollection)
    ['{A3DBAFF4-295D-45A5-9346-D1217BC91DAD}']
    function InstanceRef: TObject;
  end;


  ITypeInfo = interface (IAspectCollection)
    ['{1ABE6C72-5254-4945-9EAF-E59E80494121}']
    function TypeInfo: TRttiType;
    function GetMethod(MethodName:string): IMethodInfo;
    function Properties: TArray<IPropertyInfo>;
    function GetMethods: TArray<IMethodInfo>;
    function Invoke(MethodName: string; const Instance: IInstance; Args: TArray<TValue>; AvoidTypeAspects: boolean = false): TValue;
  end;

  IParameterInfo = interface
    ['{5F483B0C-5E81-4A13-B541-48FBF0420042}']
    function RttiInfo:TRttiParameter;
    function IsRef: boolean;
    function Position: integer;
  end;

  IParametersInfo = interface
    ['{A0B5F763-3886-4EA8-AD9D-3D894AC09FA4}']
    function ParametersInfo: TArray<IParameterInfo>;
    function Parameter(index: integer): IParameterInfo; overload;
    function Parameter(name: string): IParameterInfo; overload;
    function Count: integer;
    function HasRefParameters: boolean;
  end;

  IParameterValues = interface (IParametersInfo)
    ['{FA6A1825-65FC-44BB-96A3-76192F17748A}']
    function Values: TArray<TValue>;
    procedure _Set(Name: string; value: TValue); overload;
    procedure _Set(Position:integer; value: TValue); overload;
    function Get(Name: String): TValue; overload;
    function Get(Position: integer): TValue; overload;
  end;


  IMethodInfo = interface (IAspectCollection)
    ['{EAFA3FD4-A7FD-4F7C-879A-9D4DF64F2603}']
    function Invoke(const Instance: IInstance; Args: TArray<TValue>; AvoidTypeAspects: boolean = false): TValue;
    function ClassTypeInfo: ITypeInfo;
    function GetRttiMethod: TRttiMethod;
    function Parameters: IParametersInfo;
    //function PropertyAspect: IAspect;
  end;

  IError = interface
    ['{A9E686AA-8FB8-40B6-8E6A-34858C882E76}']
    function Error: Exception;
    procedure RaiseError;

  end;

  IInvocationContext = interface
    ['{DC1EFDC9-A6EE-465A-A668-2475CA27E812}']
    function MethodInfo: IMethodInfo;
    function Instance: IInstance;
    function Parameters: IParameterValues;
    procedure SetError(Error: IError);
    function GetError: IError;
    property Error: IError read GetError write SetError;
    function InvokeNext: TValue;
  end;

  IAspect = interface
    ['{63AFC5D6-EFA9-4598-B31A-3A88B4EF5C27}']
    function Invoke(Context: IInvocationContext): TValue;
    procedure NotifyDestroy(Instance: IInstance);
  end;

  TInvokeDelegate = reference to function (Context: IInvocationContext): TValue;

function NewAspect(InvokeDelegate: TInvokeDelegate): IAspect;

implementation

type
  TAspectClass = class (TInterfacedObject, IAspect)
  private
    FDelegate: TInvokeDelegate;
  public
    constructor Create(ADelegate: TInvokeDelegate);
    function Invoke(Context: IInvocationContext): TValue;
    procedure NotifyDestroy(Instance: IInstance);
  end;

{ TAspectClass }

constructor TAspectClass.Create(ADelegate: TInvokeDelegate);
begin
  FDelegate:= ADelegate;
end;

function TAspectClass.Invoke(Context: IInvocationContext): TValue;
begin
  if Assigned(FDelegate) then
    result:= FDelegate(Context)
  else
    result:= Context.InvokeNext;

end;

procedure TAspectClass.NotifyDestroy(Instance: IInstance);
begin

end;

function NewAspect(InvokeDelegate: TInvokeDelegate): IAspect;
begin
  result:= TAspectClass.Create(InvokeDelegate);
end;

end.
