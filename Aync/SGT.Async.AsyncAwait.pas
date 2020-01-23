unit SGT.Async.AsyncAwait;

interface

uses SysUtils, Rtti, TypInfo;
type

  TaskStatus = (tsWaiting, tsCanceled, tsRunning, tsFinish, tsError);

  ITaskResult = interface
    ['{10876582-B3D7-4039-A7D7-522D12273641}']
    function Error: Exception;
    function Parameters: TArray<TValue>;
    function Value: TValue;
  end;

  ITaskResult<T> = interface (ITaskResult)
    ['{DA4802B4-B025-4870-B8AB-6B2F2DCFAFCC}']
    function Value: T;
  end;

  TTaskResult = class (TInterfacedObject, ITaskResult)
  private
    FError: Exception;
    FParameters: TArray<TValue>;
    FValue: TValue;
    function Error: Exception;
    function Parameters: TArray<TValue>;
    function Value: TValue;
  public
    constructor Create(Parameters: TArray<TValue>; Error: Exception = nil); overload;
    constructor Create(Error: Exception = nil); overload;
    constructor Create(Parameters: TArray<TValue>; Result: TValue; Error: Exception = nil); overload;
    constructor Create(Result: TValue; Error: Exception = nil); overload;
    destructor destroy; overload;
  end;

  TTaskResult<T> = class(TTaskResult)
    function Value: T;
  end;

  ITask = interface
    ['{B2AAF1F9-1D66-4B85-9FD5-347AB1AC5F1E}']
    function Status: TaskStatus;
    procedure Cancel;
    function Wait(Milliseconds: Cardinal = INFINITE): boolean;
    function Result: ITaskResult; overload;
  end;

  ITask<T> = interface (ITask)
    function Result: ITaskResult<T>; overload;
  end;

  TAwaitProc = reference to procedure (TaskResult: ITaskResult);
  TAwaitProc<T> = reference to procedure (TaskResult: ITaskResult<T>);

  IAsyncExecutor = interface
    function NewTask(AProcAddr: Pointer; Await: TAwaitProc = nil; ResultTypeInfo: PTypeInfo = nil): ITask overload;
    function NewTask(AProcAddr: Pointer; Params: TArray<TValue>; Await: TAwaitProc = nil; ResultTypeInfo: PTypeInfo = nil ): ITask overload;
    function WaitForAll(Tasks: TArray<ITask>; Milliseconds: cardinal = INFINITE): boolean; overload;
  end;

  TAsync = class (TObject)
  public
    class function NewTask(AProcAddr: Pointer; Await: TAwaitProc = nil; ResTypeInfo: PTypeInfo = nil ): ITask overload;
    class function NewTask(AProcAddr: Pointer; Params: TArray<TValue>; Await: TAwaitProc = nil; ResTypeInfo: PTypeInfo = nil ): ITask overload;
{    class function NewTask<TResult>(AFuncAddr: Pointer; Await: TAwaitProc<TResult> = nil ): ITask<TResult> overload;
    class function NewTask<TResult>(AFuncAddr: Pointer; Params: TArray<TValue>; Await: TAwaitProc<TResult> = nil ): ITask<TResult> overload;
    class function NewTask(AProc: TProc; Await: TAwaitProc = nil ): ITask overload;
    class function NewTask<T1>(AProc: TProc<T1>; Arg1: T1; Await: TAwaitProc = nil ): ITask overload;
    class function NewTask<T1,T2>(AProc: TProc<T1, T2>; Arg1: T1; Arg2: T2; Await: TAwaitProc = nil ): ITask overload;
    class function NewTask<T1,T2,T3>(AProc: TProc<T1,T2,T3>; Arg1: T1; Arg2: T2; Arg3: T3; Await: TAwaitProc = nil ): ITask overload;
    class function NewTask<T1,T2,T3,T4>(AProc: TProc<T1,T2,T3, T4>; Arg1: T1; Arg2: T2; Arg3: T3; Arg4:T4; Await: TAwaitProc = nil ): ITask overload;
    class function NewTask<TResult>(AFunc: TFunc<TResult>; Await: TAwaitProc<TResult> = nil): ITask<TResult> overload;
    class function NewTask<T1,TResult>(AFunc: TFunc<T1,TResult>; Arg1: T1; Await: TAwaitProc<TResult> = nil ): ITask<TResult> overload;
    class function NewTask<T1,T2,TResult>(AFunc: TFunc<T1,TResult>; Arg1: T1; Arg2: T2; Await: TAwaitProc<TResult> = nil ): ITask<TResult> overload;
    class function NewTask<T1,T2,T3,TResult>(AFunc: TFunc<T1,TResult>;  Arg1: T1; Arg2: T2; Arg3: T3; Await: TAwaitProc<TResult> = nil ): ITask<TResult> overload;
    class function NewTask<T1,T2,T3,T4,TResult>(AFunc: TFunc<T1,TResult>; Arg1: T1; Arg2: T2; Arg3: T3; Arg4:T4; Await: TAwaitProc<TResult> = nil ): ITask<TResult> overload;
 }   class function WaitAll(Tasks: TArray<ITask>; Milliseconds: cardinal = INFINITE): boolean; overload;
    class procedure SetAsync(AAsync: IAsyncExecutor);
  end;


implementation

uses Windows, AsyncCalls;

var
  Async: IAsyncExecutor;
  CriticalSection: TRtlCriticalSection;

type
  THausladenTask = class (TInterfacedObject, ITask)
  private
    FHandle: IAsyncCall;
    function Status: TaskStatus;
    procedure Cancel;
    function Wait(Milliseconds: Cardinal = INFINITE): boolean;
    function Result: ITaskResult; overload;
  public
    constructor Create(Handle: IAsyncCall);
  end;

  THausladenAsync = class (TInterfacedObject, IAsyncExecutor)
  protected
    function NewTask(AProcAddr: Pointer; Await: TAwaitProc = nil; ResultTypeInfo: PTypeInfo = nil ): ITask overload;
    function NewTask(AProcAddr: Pointer; Params: TArray<TValue>; Await: TAwaitProc = nil; ResultTypeInfo: PTypeInfo = nil  ): ITask overload;
    function WaitForAll(Tasks: TArray<ITask>; Milliseconds: cardinal = INFINITE): boolean; overload;
  end;


{ THausladenTask }

procedure THausladenTask.Cancel;
begin
  FHandle.CancelInvocation;
end;

constructor THausladenTask.Create(Handle: IAsyncCall);
begin
  FHandle:= Handle;
end;

function THausladenTask.Result: ITaskResult;
begin
  FHandle.Sync;
  result:= ITaskResult(FHandle.ReturnValue);
end;

function THausladenTask.Status: TaskStatus;
begin
  if FHandle.Finished then result:= TaskStatus.tsFinish
  else if FHandle.Canceled then result:= TaskStatus.tsCanceled
  else result:= TaskStatus.tsRunning;
end;

function THausladenTask.Wait(Milliseconds: Cardinal): boolean;
var LRes: cardinal;
begin
  LRes:= AsyncMultiSync([FHandle],true, Milliseconds);
  result:= (LRes<>WAIT_TIMEOUT) and (LRes<>WAIT_FAILED);
end;


function InternalAsyncExecute(ProcAddr: Pointer; Params: TArray<TValue>; ResultTypeInfo: PTypeInfo; Await: TAwaitProc): TTaskResult; cdecl;
var
  LError: Exception;
  LResultValue: TValue;
begin
  LError:= nil;
  try
    LResultValue:= Invoke(ProcAddr, Params, TCallConv.ccReg, ResultTypeInfo);
  except
    LError:= Exception(AcquireExceptionObject)
  end;
  Result:=  TTaskResult.Create(Params, LResultValue, LError);
  if Assigned(Await) then
  begin
    if not System.IsConsole then
      EnterMainThread;
    try
      Await(Result);
    finally
      if not System.IsConsole then
        LeaveMainThread;
    end;
  end;
end;

{ THausladenAsync }

function THausladenAsync.NewTask(AProcAddr: Pointer; Await: TAwaitProc = nil; ResultTypeInfo: PTypeInfo = nil): ITask;
begin
  result:= NewTask(AProcAddr, nil, Await, ResultTypeInfo);
end;

function THausladenAsync.NewTask(AProcAddr: Pointer; Params: TArray<TValue>;
  Await: TAwaitProc = nil; ResultTypeInfo: PTypeInfo = nil  ): ITask;
begin
  result:= THausladenTask.Create(AsyncCall(@InternalAsyncExecute, [AProcAddr, Params, ResultTypeInfo, Await]));
end;

function THausladenAsync.WaitForAll(Tasks: TArray<ITask>;
  Milliseconds: cardinal): boolean;
var FAsyncCalls: Array of IAsyncCall;
    i: integer;
    LRes: cardinal;
begin
  SetLength(FAsyncCalls, Length(Tasks));
  for i:=0 to Length(Tasks)-1 do
    FAsyncCalls[i]:= THausladenTask(Tasks[i]).FHandle;
  LRes:= AsyncMultiSync(FAsyncCalls,true, Milliseconds);
  result:= (LRes<>WAIT_TIMEOUT) and (LRes<>WAIT_FAILED);
end;


{ TAsync }

class function TAsync.NewTask(AProcAddr: Pointer; Params: TArray<TValue>;
  Await: TAwaitProc; ResTypeInfo: PTypeInfo): ITask;
begin
  result:=  Async.NewTask(AProcAddr, Params, Await, ResTypeInfo);
end;

class function TAsync.NewTask(AProcAddr: Pointer; Await: TAwaitProc; ResTypeInfo: PTypeInfo): ITask;
begin
  result:=  NewTask(AProcAddr, nil, Await, ResTypeInfo);
end;


class procedure TAsync.SetAsync(AAsync: IAsyncExecutor);
begin
  if AASync=nil then
    raise Exception.Create('AAsync can''t be null');
  EnterCriticalSection(CriticalSection);
  try
    Async:= AAsync;
  finally
    LeaveCriticalSection(CriticalSection);
  end;
end;

class function TAsync.WaitAll(Tasks: TArray<ITask>;
  Milliseconds: cardinal): boolean;
begin
  result:= Async.WaitForAll(Tasks, Milliseconds);
end;

{ TTaskResut }

constructor TTaskResult.Create(Parameters: TArray<TValue>; Error: Exception);
begin
  Create(Parameters,nil, Error);
end;

constructor TTaskResult.Create(Error: Exception);
begin
  Create(nil, nil, Error);
end;

constructor TTaskResult.Create(Result: TValue; Error: Exception);
begin
  Create(nil,Result, Error);
end;

constructor TTaskResult.Create(Parameters: TArray<TValue>; Result: TValue;
  Error: Exception);
begin
  FParameters:= Parameters;
  FValue:= Result;
  FError:= Error;
end;

destructor TTaskResult.destroy;
begin
  if FError<> nil then
    try
      FError.Free;
    except
    end;
end;

function TTaskResult.Error: Exception;
begin
  result:= FError;
end;

function TTaskResult.Parameters: TArray<TValue>;
begin
  result:= FParameters;
end;

function TTaskResult.Value: TValue;
begin
  result:= FValue;
end;

{ TTaskResult<T> }

function TTaskResult<T>.Value: T;
begin
  result:= FValue.AsType<T>();
end;

initialization
  Async:= THausladenAsync.Create;
end.
