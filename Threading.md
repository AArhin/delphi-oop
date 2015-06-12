# TSvParallel #

## Async ##
Async is very easy way to run your code in the separate thread.
```
TSvParallel.Async(
    procedure //runs in separate thread
    begin
      DoSomeLengthyMethod();
    end,
    procedure  //runs when separate thread terminates
    begin
      UpdateGUI();
    end);
```
## Parallel ForEach ##
Parallel ForEach lets you write the loop which will be executed in parallel.
```
//We can set MaxThreads number to use
TSvParallel.MaxThreads := 10;
TSvParallel.ForEach(0, 99, 
  procedure(const i: NativeInt; var Abort: Boolean) 
  begin  //executes in separate threads 
    DoSomeStuff(i);
  end);
```
# Futures #
A future is a stand-in for a computational result that is initially unknown but becomes available at a later time. The process of calculating the result can occur in parallel with other computations.

```
var
  LCount: TSvFuture<Integer>;
begin
  LCount := function: Integer 
  begin
    Result := GetCount();  //long lasting method, it will be executed in parallel instantly
  end;

  CallSomeOtherMethods(); 
  WriteLn('Our calculated count is: ');
  WriteLn(LCount);
end;
```