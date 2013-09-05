unit SvREST.Client.VirtualInterface;

interface

uses
  Rtti
  ,TypInfo
  ,SvREST.Client
  ,SvWeb.Consts
  ;

type
  TVirtualRESTClient = class(TRESTClient)

  end;
  //XE2 and higher
  TRESTClientVirtualInterface = class(TVirtualInterface)
  private
    FClient: TVirtualRESTClient;
  public
    constructor Create(AInterfaceTypeInfo: PTypeInfo; const AUrl: string; const AHttpClient: string = HTTP_CLIENT_INDY); overload;
    destructor Destroy; override;
  end;

implementation

{ TRESTClientVirtualInterface }

constructor TRESTClientVirtualInterface.Create(AInterfaceTypeInfo: PTypeInfo; const AUrl: string; const AHttpClient: string);
begin
  FClient := TVirtualRESTClient.Create(AUrl, nil, AInterfaceTypeInfo);
  inherited Create(AInterfaceTypeInfo,
    procedure(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue)
    var
      LArgs: TArray<TValue>;
      i: Integer;
    begin
      LArgs := nil;  //first argument self so we remove it
      if Length(Args) > 1 then
      begin
        SetLength(LArgs, Length(Args) - 1);

        for i := Low(Args)+1 to High(Args) do
        begin
          LArgs[i-1] := Args[i];
        end;
      end;

      FClient.DoOnAfter(nil, Method, LArgs, Result);
    end);
  FClient.SetHttpClient(AHttpClient);
end;

destructor TRESTClientVirtualInterface.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

end.
