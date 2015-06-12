# SvDelegate #
You can add multiple event listeners to SvDelegates:
```
type
  TAnonMethod = reference to procedure(const AName: string);

var
  LDelegate: SvDelegate<TAnonMethod>;
  LEvent: TAnonMethod;
begin
  LDelegate.Add(procedure(const AName: string)
  begin
    DoSomething(AName);
  end);
  //add another event listener
  LDelegate.Add(procedure(const AName: string)
  begin
    DoSomethingMore(AName);
  end);
  //call these methods
  for LEvent in LDelegate do LEvent('Bob');
end;
```

_Simple methods (procedure of object) are also supported._