unit SGT.Container;

interface

uses Rtti, TypInfo, Generics.Collections;

type
  IFactory = interface
    ['{48614D3C-4E63-4700-A55B-B50B8ADD6E58}']
    function Create(ATypeInfo: PTypeInfo): TValue;
  end;

  TFactory = Class(TObject)
  private
    class var Factory: IFactory;
  public
    class function Create<T>: T;
    class procedure SetFactory(NewFactory: IFactory);
  end;

  TContainer = class
  private
    class var FRegisteredTypes: TObjectDictionary<PTypeInfo, TDictionary<String, IFactory>>;
    class procedure RegisterType(ATypeInfo: PTypeInfo; AClass: TClass; AServiceName: String); overload;
    class function ResolveFrom(ATypeInfo: PTypeInfo; HelperClass: TClass): TValue; overload;
  public
    class constructor Create;
    class destructor Destroy;
    class function Resolve<T>: T; overload;
    class function Resolve<T>(Args: Array of TValue): T; overload;
    class function Resolve<T>(AServiceName: String): T; overload;
    class function Resolve<T>(AServiceName: String; Args: Array of TValue): T; overload;
    class procedure RegisterType<I: IInterface>(C: TClass; AServiceName: String=''); overload;
    class procedure RegisterType<I: IInterface; C: Class>(AServiceName: String=''); overload;
    class procedure RegisterType<T: Class>(AServiceName: String); overload;
  end;

implementation

{ TFactory }

class function TFactory.Create<T>: T;
begin
  result:= Factory.Create(TypeInfo(T)).AsType<T>;
end;

class procedure TFactory.SetFactory(NewFactory: IFactory);
begin
  Factory:= NewFactory;
end;

{ TContainer }

class constructor TContainer.Create;
begin
  FRegisteredTypes:= TObjectDictionary<PTypeInfo, TDictionary<String, IFactory>>.Create;
end;

class destructor TContainer.Destroy;
begin
  FRegisteredTypes.Free;
end;

class procedure TContainer.RegisterType(ATypeInfo: PTypeInfo; AClass: TClass;
  AServiceName: String);
begin

end;

class procedure TContainer.RegisterType<I, C>(AServiceName: String);
begin

end;

class procedure TContainer.RegisterType<I>(C: TClass; AServiceName: String);
begin

end;

class procedure TContainer.RegisterType<T>(AServiceName: String);
begin

end;

class function TContainer.Resolve<T>: T;
begin

end;

class function TContainer.Resolve<T>(Args: array of TValue): T;
begin

end;

class function TContainer.Resolve<T>(AServiceName: String): T;
begin

end;

class function TContainer.Resolve<T>(AServiceName: String;
  Args: array of TValue): T;
begin

end;

class function TContainer.ResolveFrom(ATypeInfo: PTypeInfo;
  HelperClass: TClass): TValue;
begin

end;

end.
