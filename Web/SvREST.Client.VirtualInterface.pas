unit SvREST.Client.VirtualInterface;

interface

uses
  Rtti
  ,TypInfo
  ,SvREST.Client
  ,SvWeb.Consts
  ,SvHTTPClientInterface
  ;

type
  TSvRESTClientInitParams = record
    HttpClientName: string;
    EncodeParameters: Boolean;
    Authentication: IHttpAuthentication;
    InterfaceTypeInfo: PTypeInfo;
    BaseURL: string;
  end;

  TVirtualRESTClient = class(TSvRESTClient)

  end;
  //XE2 and higher
  TSvRESTClientVirtualInterface = class(TVirtualInterface)
  private
    FClient: TVirtualRESTClient;
  public
    constructor Create(AInterfaceTypeInfo: PTypeInfo; const AUrl: string; const AHttpClient: string = HTTP_CLIENT_INDY); overload;
    constructor Create(const AInitParams: TSvRESTClientInitParams); overload;
    destructor Destroy; override;
  end;

implementation

{ TRESTClientVirtualInterface }

constructor TSvRESTClientVirtualInterface.Create(AInterfaceTypeInfo: PTypeInfo; const AUrl: string; const AHttpClient: string);
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
      //restore arguments
      for i := Low(Args)+1 to High(Args) do
      begin
        Args[i] := LArgs[i-1];
      end;
    end);
  FClient.SetHttpClient(AHttpClient);
end;

constructor TSvRESTClientVirtualInterface.Create(
  const AInitParams: TSvRESTClientInitParams);
var
  LHttpClient: string;
begin
  LHttpClient := AInitParams.HttpClientName;
  if (LHttpClient = '') then
    LHttpClient := HTTP_CLIENT_INDY;
  Create(AInitParams.InterfaceTypeInfo, AInitParams.BaseURL, LHttpClient);
  FClient.EncodeParameters := AInitParams.EncodeParameters;
  FClient.DoInvokeMethods := False;
  FClient.Authentication := AInitParams.Authentication;
end;

destructor TSvRESTClientVirtualInterface.Destroy;
begin
  FClient.Free;
  inherited Destroy;
end;

end.
