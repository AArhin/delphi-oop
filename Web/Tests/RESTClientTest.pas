unit RESTClientTest;

interface

uses
  TestFramework, SvHTTPClientInterface, Generics.Collections, Classes, Rtti, SvVMI, SvREST.Client
  ,SvHTTP.Attributes, SvREST.Method
  {$IF CompilerVersion > 22} , SvREST.Client.VirtualInterface {$IFEND}
  ;

type
  TWebEntity = class
  private
    FId: Integer;
  public
    property Id: Integer read FId write FId;
  end;

  ITestRESTClient = interface(IInvokable)
    ['{055E3262-AA1E-43E7-90BC-7A1E84D0746D}']
    [GET]
    [Path('/Entities')]
    [Consumes(MEDIA_TYPE.JSON)]
    function GetEntity(AId: Integer): TWebEntity;
  end;

  TMockRestClient = class(TRESTClient)
  private
    FDoGetRequestResult: TValue;
  protected
    procedure DoGetRequest(Method: TRttiMethod; const Args: TArray<TValue>; ARestMethod: TRESTMethod;
      var Result: TValue); override;
  public
    [GET]
    [Path('/Entities')]
    [Consumes(MEDIA_TYPE.JSON)]
    function GetEntity(AId: Integer): TWebEntity; virtual;


    property DoGetRequestResult: TValue read FDoGetRequestResult write FDoGetRequestResult;
  end;



  TestTRESTClient = class(TTestCase)
  private
    FRESTClient: TMockRestClient;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DoRequest;
    procedure GetRequestType;
    procedure GenerateUrl;
    procedure DoCheckPathParameters;
    procedure GenerateSourceContent;
    procedure FillRestMethodParameters;
    procedure ConsumeMediaTypeAsString;
  end;

  {$IF CompilerVersion > 22} 
  TestVirtualRESTClient = class(TTestCase)
  private
    FClient: ITestRESTClient;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure GetEntity();
  end;
  {$IFEND}

implementation

uses
  SvHTTPClient.Indy
  ,SysUtils
  ,SvWeb.Consts
  ;


procedure TestTRESTClient.SetUp;
begin
  FRESTClient := TMockRestClient.Create('http://localhost');
  FRESTClient.SetHttpClient(HTTP_CLIENT_MOCK);
end;

procedure TestTRESTClient.TearDown;
begin
  FRESTClient.Free;
  FRESTClient := nil;
end;

procedure TestTRESTClient.DoRequest;
var
  _Result: TValue;
  LRestMethod: TRESTMethod;
  Args: TArray<TValue>;
  LMethod: TRttiMethod;
  LEntity: TWebEntity;
begin
  LMethod := TRttiContext.Create.GetType(FRESTClient.ClassType).GetMethod('GetEntity');
  Args := TArray<TValue>.Create(1);
  LRestMethod := FRESTClient.GetRESTMethod(LMethod, TRttiContext.Create.GetType(FRESTClient.ClassType));
  LEntity := TWebEntity.Create;
  try
    LEntity.Id := 2;

    FRESTClient.FillRestMethodParameters(Args, LRestMethod, LMethod);

    FRESTClient.DoGetRequestResult := LEntity;

    FRESTClient.DoRequest(LMethod, Args, LRestMethod, _Result);

    CheckEquals(2, (_Result.AsObject as TWebEntity).Id);

  finally
    LRestMethod.Free;
    LEntity.Free;
  end;
end;

procedure TestTRESTClient.GetRequestType;
var
  ReturnValue: TRequestType;
  LMethod: TRttiMethod;
begin
  LMethod := TRttiContext.Create.GetType(FRESTClient.ClassType).GetMethod('GetEntity');
  ReturnValue := FRESTClient.GetRequestType(LMethod);
  CheckEquals(Ord(rtGet), Ord(ReturnValue));
end;

procedure TestTRESTClient.GenerateUrl;
var
  LUrl: string;
  LMethod: TRttiMethod;
  LRestMethod: TRESTMethod;
  LArgs: TArray<TValue>;
begin
  LMethod := TRttiContext.Create.GetType(FRESTClient.ClassType).GetMethod('GetEntity');
  LRestMethod := FRESTClient.GetRESTMethod(LMethod, TRttiContext.Create.GetType(FRESTClient.ClassType));
  try
    LArgs := TArray<TValue>.Create(1);
    FRESTClient.FillRestMethodParameters(LArgs, LRestMethod, LMethod);
    LUrl := FRESTClient.GenerateUrl(LRestMethod);
    CheckEquals('http://localhost/Entities?AId=1', LUrl);
  finally
    LRestMethod.Free;
  end;
end;

procedure TestTRESTClient.DoCheckPathParameters;
var
  ReturnValue: string;
  LMethod: TRttiMethod;
  LRestMethod: TRESTMethod;
  AUrl: string;
  LArgs: TArray<TValue>;
begin
  LMethod := TRttiContext.Create.GetType(FRESTClient.ClassType).GetMethod('GetEntity');
  LRestMethod := FRESTClient.GetRESTMethod(LMethod, TRttiContext.Create.GetType(FRESTClient.ClassType));
  try
    AUrl := 'http://localhost/Entities?{AId}';
    LArgs := TArray<TValue>.Create(1);
    FRESTClient.FillRestMethodParameters(LArgs, LRestMethod, LMethod);
    ReturnValue := FRESTClient.DoCheckPathParameters(AUrl, LRestMethod);

    CheckEquals('http://localhost/Entities?1', ReturnValue);
  finally
    LRestMethod.Free;
  end;
end;

procedure TestTRESTClient.GenerateSourceContent;
var
  LStream: TStream;
  LMethod: TRttiMethod;
  LRestMethod: TRESTMethod;
  LArgs: TArray<TValue>;
  LStringStream: TStringList;
begin
  LMethod := TRttiContext.Create.GetType(FRESTClient.ClassType).GetMethod('GetEntity');
  LRestMethod := FRESTClient.GetRESTMethod(LMethod, TRttiContext.Create.GetType(FRESTClient.ClassType));
  try
    LArgs := TArray<TValue>.Create(1);
    FRESTClient.FillRestMethodParameters(LArgs, LRestMethod, LMethod);
    LStream := FRESTClient.GenerateSourceContent(LRestMethod);
    LStringStream := TStringList.Create();
    try
      LStream.Position := 0;
      LStringStream.LoadFromStream(LStream);

      CheckEquals('"AId"="1"', LStringStream[0]);
    finally
      LStream.Free;
      LStringStream.Free;
    end;
  finally
    LRestMethod.Free;
  end;
end;


procedure TestTRESTClient.FillRestMethodParameters;
var
  LMethod: TRttiMethod;
  LRestMethod: TRESTMethod;
  LArgs: TArray<TValue>;
  LValue: string;
begin
  LMethod := TRttiContext.Create.GetType(FRESTClient.ClassType).GetMethod('GetEntity');
  LRestMethod := FRESTClient.GetRESTMethod(LMethod, TRttiContext.Create.GetType(FRESTClient.ClassType));
  try
    LArgs := TArray<TValue>.Create(1);
    FRESTClient.FillRestMethodParameters(LArgs, LRestMethod, LMethod);
    CheckEquals(1, LRestMethod.Parameters.Count);
    LValue := LRestMethod.Parameters[0].ToString;
    CheckEquals('1', LValue);
  finally
    LRestMethod.Free;
  end;
end;

procedure TestTRESTClient.ConsumeMediaTypeAsString;
var
  ReturnValue: string;
  LMethod: TRttiMethod;
  LRestMethod: TRESTMethod;
begin
  LMethod := TRttiContext.Create.GetType(FRESTClient.ClassType).GetMethod('GetEntity');
  LRestMethod := FRESTClient.GetRESTMethod(LMethod, TRttiContext.Create.GetType(FRESTClient.ClassType));
  try
    ReturnValue := FRESTClient.ConsumeMediaTypeAsString(LMethod.GetParameters[0].ParamType, 2, LRestMethod);
    CheckEquals('2', ReturnValue);
  finally
    LRestMethod.Free;
  end;
end;

{ TMockRestClient }

procedure TMockRestClient.DoGetRequest(Method: TRttiMethod; const Args: TArray<TValue>;
  ARestMethod: TRESTMethod; var Result: TValue);
begin
  Result := FDoGetRequestResult;
end;

function TMockRestClient.GetEntity(AId: Integer): TWebEntity;
begin
  Result := TWebEntity.Create;
  Result.Id := AId;
end;

{$IF CompilerVersion > 22} 

{ TestVirtualRESTClient }

procedure TestVirtualRESTClient.GetEntity;
var
  LEntity: TWebEntity;
begin
  LEntity := FClient.GetEntity(2);
  CheckTrue(LEntity = nil);
end;

procedure TestVirtualRESTClient.SetUp;
begin
  inherited;
  FClient := TRESTClientVirtualInterface.Create(TypeInfo(ITestRestClient), 'http://localhost', HTTP_CLIENT_MOCK) as ITEstRestClient;
end;

procedure TestVirtualRESTClient.TearDown;
begin
  inherited;

end;

{$IFEND}

initialization
  RegisterTest(TestTRESTClient.Suite);
  {$IF CompilerVersion > 22} 
  RegisterTest(TestVirtualRESTClient.Suite);
  {$IFEND}
end.

