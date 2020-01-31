unit SGT.AspectCollection;

interface

uses Rtti, Generics.Collections, SGT.AspectsIntf, TypInfo, Classes;

type

  TAspectAttribute = class(TCustomAttribute)
  public
    function GetAspect: IAspect; virtual; abstract;
  end;

  TAspectCollection = class (TInterfacedObject, IAspectCollection)
  private
    FAspects: TList<IAspect>;
    FRttiType: TRttiObject;
  protected
    procedure AddAspect(Aspect: IAspect);
    function AspectCount: integer;
    function GetAspect(index: integer): IAspect;
    property RttiType: TRttiObject read FRttiType;
    constructor Create(AType: TRttiObject);
  public
    function Aspects: TArray<IAspect>;
    destructor Destroy; override;
  end;

implementation

uses SGT.RttiHelpers;
{ TAspectsContainer }

procedure TAspectCollection.AddAspect(Aspect: IAspect);
begin
  FAspects.Add(Aspect);
end;

function TAspectCollection.AspectCount: integer;
begin
  result:= FAspects.Count;
end;

function TAspectCollection.Aspects: TArray<IAspect>;
begin
  result:= FAspects.ToArray();
end;

constructor TAspectCollection.Create(AType: TRttiObject);
begin
  FAspects:= TList<IAspect>.Create;
  if Assigned(AType) then
  begin
    AType.ForEachAttributeOfType<TAspectAttribute>(procedure (Attr: TAspectAttribute)
    begin
      AddAspect(Attr.GetAspect);
    end);
    FRttiType:= AType;
  end;
end;

destructor TAspectCollection.Destroy;
begin
  TUtil.FreeInterfaceList<IAspect>(FAspects);
  inherited;
end;

function TAspectCollection.GetAspect(index: integer): IAspect;
begin
  if index< FAspects.Count then
    result:= FAspects[index]
  else
    result:= nil;
end;

end.
