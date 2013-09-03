unit SvVMI;

interface

uses
  Rtti
  ,Generics.Collections
  ,SysUtils
  ;

type
  TInterceptBeforeNotify = reference to procedure(Instance: TObject;
    Method: TRttiMethod; const Args: TArray<TValue>; out DoInvoke: Boolean;
    out Result: TValue);
  TInterceptAfterNotify = reference to procedure(Instance: TObject;
    Method: TRttiMethod; const Args: TArray<TValue>; var Result: TValue);
  TInterceptExceptionNotify = reference to procedure(Instance: TObject;
    Method: TRttiMethod; const Args: TArray<TValue>; out RaiseException: Boolean;
    TheException: Exception; out Result: TValue);

  TSvVirtualMethodInterceptor = class
  private type
    TExtraMethodInfo = (eiNormal, eiObjAddRef, eiObjRelease, eiFreeInstance);
    TInterceptInfo = class
    private
      FExtraMethodInfo: TExtraMethodInfo;
      FImpl: TMethodImplementation;
      FOriginalCode: Pointer;
      FProxyCode: Pointer;
      FMethod: TRttiMethod;
    public
      constructor Create(AOriginalCode: Pointer; AMethod: TRttiMethod;
        const ACallback: TMethodImplementationCallback;
        const ExtraMethodInfo: TExtraMethodInfo);
      destructor Destroy; override;
      property ExtraMethodInfo: TExtraMethodInfo read FExtraMethodInfo;
      property OriginalCode: Pointer read FOriginalCode;
      property ProxyCode: Pointer read FProxyCode;
      property Method: TRttiMethod read FMethod;
    end;

  private
    FContext: TRttiContext;
    FOriginalClass: TClass;
    FProxyClass: TClass;
    FProxyClassData: Pointer;
    FIntercepts: TObjectList<TInterceptInfo>;
    FImplementationCallback: TMethodImplementationCallback;
    FOnBefore: TInterceptBeforeNotify;
    FOnAfter: TInterceptAfterNotify;
    FOnException: TInterceptExceptionNotify;
  protected
    procedure CreateProxyClass; virtual;
    procedure RawCallback(UserData: Pointer; const Args: TArray<TValue>;
      out Result: TValue);  virtual;
  protected
    procedure DoBefore(Instance: TObject; Method: TRttiMethod;
      const Args: TArray<TValue>; out DoInvoke: Boolean; out Result: TValue);
    procedure DoAfter(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>;
      var Result: TValue);
    procedure DoException(Instance: TObject; Method: TRttiMethod;
      const Args: TArray<TValue>; out RaiseException: Boolean;
      TheException: Exception; out Result: TValue);
  public
    constructor Create(AClass: TClass); virtual;
    destructor Destroy; override;
    procedure Proxify(AInstance: TObject);
    procedure UnProxify(AInstance: TObject);
    property OriginalClass: TClass read FOriginalClass;
    property ProxyClass: TClass read FProxyClass;
    property OnBefore: TInterceptBeforeNotify read FOnBefore write FOnBefore;
    property OnAfter: TInterceptAfterNotify read FOnAfter write FOnAfter;
    property OnException: TInterceptExceptionNotify read FOnException write FOnException;
  end;

implementation

uses
  TypInfo
  ,SysConst
  ;


type
  PProxyClassData = ^TProxyClassData;
  TProxyClassData = record
    SelfPtr: TClass;
    IntfTable: Pointer;
    AutoTable: Pointer;
    InitTable: Pointer;
    TypeInfo: PTypeInfo;
    FieldTable: Pointer;
    MethodTable: Pointer;
    DynamicTable: Pointer;
{$IFNDEF NEXTGEN}
    ClassName: PShortString;
{$ELSE NEXTGEN}
    ClassName: MarshaledAString;
{$ENDIF NEXTGEN}
    InstanceSize: Integer;
    Parent: ^TClass;
  end;

function HasUntypedParameter(AMethod: TRttiMethod): Boolean;
var
  Param: TRttiParameter;
begin
  for Param in AMethod.GetParameters do
    if Param.ParamType = nil then Exit(True);
  Exit(False);
end;


{ TSvVirtualMethodInterceptor }

constructor TSvVirtualMethodInterceptor.Create(AClass: TClass);
begin
  FOriginalClass := AClass;
  FIntercepts := TObjectList<TInterceptInfo>.Create(True);
  FImplementationCallback := RawCallback;

  CreateProxyClass;
end;




procedure TSvVirtualMethodInterceptor.CreateProxyClass;
  function GetExtraMethodInfo(m: TRttiMethod): TExtraMethodInfo;
  var
    methodName: string;
  begin
    methodName := m.Name;
    // The following conditions are tested by caller.
    // m.DispatchKind is dkVtable
    // m.MethodKind is mkFunction or mkProcedure
    if methodName = 'FreeInstance' then
      Result:= eiFreeInstance
{$IFDEF AUTOREFCOUNT}
    else if methodName = '__ObjAddRef' then
      Result:= eiObjAddRef
    else if methodName = '__ObjRelease' then
      Result:= eiObjRelease
{$ENDIF AUTOREFCOUNT}
    else
      Result:= eiNormal;
  end;

{$POINTERMATH ON}
type
  PVtable = ^Pointer;
{$POINTERMATH OFF}
var
  t: TRttiType;
  m: TRttiMethod;
  size, classOfs: Integer;
  ii: TInterceptInfo;
  extraMInfo: TExtraMethodInfo;
  {$IF CompilerVersion < 23}
  maxIndex: Integer;
  {$IFEND}
begin
  t := FContext.GetType(FOriginalClass);
  {$IF CompilerVersion > 22}
  size := (t as TRttiInstanceType).VmtSize;
  {$ELSE}
  maxIndex := -1;
  for m in t.GetMethods do
  begin
    if m.DispatchKind <> dkVtable then
      Continue;
    if m.VirtualIndex > maxIndex then
      maxIndex := m.VirtualIndex;
  end;
  // maxIndex is the index of the latest entry, but that's not the count - that's +1.
  size := SizeOf(Pointer) * (1 + maxIndex - (vmtSelfPtr div SizeOf(Pointer)));
  {$IFEND}
  classOfs := -vmtSelfPtr;
  FProxyClassData := AllocMem(size);
  FProxyClass := TClass(PByte(FProxyClassData) + classOfs);
  Move((PByte(FOriginalClass) - classOfs)^, FProxyClassData^, size);
  PProxyClassData(FProxyClassData)^.Parent := @FOriginalClass;
  PProxyClassData(FProxyClassData)^.SelfPtr := FProxyClass;

  for m in t.GetMethods do
  begin
    if m.DispatchKind <> dkVtable then
      Continue;
    if not (m.MethodKind in [mkFunction, mkProcedure]) then
      Continue;
    if not m.HasExtendedInfo then
      Continue;
    if HasUntypedParameter(m) then
      Continue;

    extraMInfo := GetExtraMethodInfo(m);
{$IFDEF AUTOREFCOUNT}
    if extraMInfo in [eiObjAddRef, eiObjRelease] then
      Continue;
{$ENDIF AUTOREFCOUNT}
    ii := TInterceptInfo.Create(PVtable(FOriginalClass)[m.VirtualIndex],
      m, FImplementationCallback, extraMInfo);
    FIntercepts.Add(ii);
    PVtable(FProxyClass)[m.VirtualIndex] := ii.ProxyCode;
  end;
end;

destructor TSvVirtualMethodInterceptor.Destroy;
begin
  FIntercepts.Free;
  FreeMem(FProxyClassData);
  inherited;
end;

procedure TSvVirtualMethodInterceptor.DoAfter(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>;
  var Result: TValue);
begin
  if Assigned(FOnAfter) then
    FOnAfter(Instance, Method, Args, Result);
end;

procedure TSvVirtualMethodInterceptor.DoBefore(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>;
  out DoInvoke: Boolean; out Result: TValue);
begin
  if Assigned(FOnBefore) then
    FOnBefore(Instance, Method, Args, DoInvoke, Result);
end;

procedure TSvVirtualMethodInterceptor.DoException(Instance: TObject; Method: TRttiMethod; const Args: TArray<TValue>;
  out RaiseException: Boolean; TheException: Exception; out Result: TValue);
begin
  if Assigned(FOnException) then
    FOnException(Instance, Method, Args, RaiseException, TheException, Result);
end;

procedure TSvVirtualMethodInterceptor.Proxify(AInstance: TObject);
begin
  if PPointer(AInstance)^ <> OriginalClass then
    raise EInvalidCast.CreateRes(@SInvalidCast);
  PPointer(AInstance)^ := ProxyClass;
end;

procedure TSvVirtualMethodInterceptor.RawCallback(UserData: Pointer; const Args: TArray<TValue>; out Result: TValue);
procedure PascalShiftSelfLast(cc: TCallConv);
{$IFDEF CPUX86}
  var
    receiver: array[1..SizeOf(TValue)] of Byte;
  begin
    if cc <> ccPascal then Exit;
    Move(Args[0], receiver, SizeOf(TValue));
    Move(Args[1], Args[0], SizeOf(TValue) * (Length(Args) - 1));
    Move(receiver, Args[Length(Args) - 1], SizeOf(TValue));
  end;
{$ELSE !CPUX86}
  begin

  end;
{$ENDIF !CPUX86}

  procedure PascalShiftSelfFirst(cc: TCallConv);
{$IFDEF CPUX86}
  var
    receiver: array[1..SizeOf(TValue)] of Byte;
  begin
    if cc <> ccPascal then Exit;
    Move(Args[Length(Args) - 1], receiver, SizeOf(TValue));
    Move(Args[0], Args[1], SizeOf(TValue) * (Length(Args) - 1));
    Move(receiver, Args[0], SizeOf(TValue));
  end;
{$ELSE !CPUX86}
  begin

  end;
{$ENDIF !CPUX86}

var
  inst: TObject;
  ii: TInterceptInfo;
  argList: TArray<TValue>;
  parList: TArray<TRttiParameter>;
  i: Integer;
  go: Boolean;
begin
  ii := TInterceptInfo(UserData);
  inst := Args[0].AsObject;

  SetLength(argList, Length(Args) - 1);
  for i := 1 to Length(Args) - 1 do
    argList[i - 1] := Args[i];
  try
    go := True;
    DoBefore(inst, ii.Method, argList, go, Result);
    if go then
    begin
      try
        parList := ii.Method.GetParameters;
        for i := 1 to Length(Args) - 1 do
        begin
          if
{$IFDEF CPUX86}
            ((ii.Method.CallingConvention in [ccCdecl, ccStdCall, ccSafeCall]) and (pfConst in parList[i-1].Flags) and (parList[i-1].ParamType.TypeKind = tkVariant)) or
{$ENDIF CPUX86}
            ((pfConst in parList[i - 1].Flags) and (parList[i - 1].ParamType.TypeSize > SizeOf(Pointer)))
            or ([pfVar, pfOut] * parList[i - 1].Flags <> []) then
            Args[i] := argList[i - 1].GetReferenceToRawData
          else
            Args[i] := argList[i - 1];
        end;

        PascalShiftSelfLast(ii.Method.CallingConvention);
        try
          if ii.Method.ReturnType <> nil then
            Result := Invoke(ii.OriginalCode, Args, ii.Method.CallingConvention, ii.Method.ReturnType.Handle)
          else
            Result := Invoke(ii.OriginalCode, Args, ii.Method.CallingConvention, nil);
        finally
          PascalShiftSelfFirst(ii.Method.CallingConvention);
        end;
      except
        on e: Exception do
        begin
          DoException(inst, ii.Method, argList, go, e, Result);
          if go then
            raise;
        end;
      end;
      if ii.ExtraMethodInfo = eiFreeInstance then
        Pointer(inst) := nil;
      DoAfter(inst, ii.Method, argList, Result);
    end;
  finally
    // Set modified by-ref arguments
    for i := 1 to Length(Args) - 1 do
      Args[i] := argList[i - 1];
  end;
end;

procedure TSvVirtualMethodInterceptor.UnProxify(AInstance: TObject);
begin
  if PPointer(AInstance)^ <> ProxyClass then
    raise EInvalidCast.CreateRes(@SInvalidCast);
  PPointer(AInstance)^ := OriginalClass;
end;

{ TSvVirtualMethodInterceptor.TInterceptInfo }

constructor TSvVirtualMethodInterceptor.TInterceptInfo.Create(AOriginalCode: Pointer; AMethod: TRttiMethod;
        const ACallback: TMethodImplementationCallback;
        const ExtraMethodInfo: TExtraMethodInfo);
begin
  FImpl := AMethod.CreateImplementation(Pointer(Self), ACallback);
  FOriginalCode := AOriginalCode;
  FProxyCode := FImpl.CodeAddress;
  FMethod := AMethod;
  FExtraMethodInfo := ExtraMethodInfo;
end;

destructor TSvVirtualMethodInterceptor.TInterceptInfo.Destroy;
begin
  FImpl.Free;
  inherited;
end;

end.
