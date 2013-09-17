unit CouchDBTest;

interface

uses
  TestFramework
  ,SvHTTPClientInterface
  ,SvRest.Client
  ,SvHTTP.Attributes
  ;

type
  TCouchPerson = class
  private
    FName: string;
    FId: Integer;
    FLastEdited: TDateTime;
  public
    property Name: string read FName write FName;
    property LastEdited: TDateTime read FLastEdited write FLastEdited;
    property MyId: Integer read FId write FId;
  end;

  TCouchDBInfo = class
  private
    Fdb_name: string;
    Fdisk_size: Int64;
    Fdoc_count: Int64;
  public
    property db_name: string read Fdb_name write Fdb_name;
    property disk_size: Int64 read Fdisk_size write Fdisk_size;
    property doc_count: Int64 read Fdoc_count write Fdoc_count;

  end;

  TCouchAddResponse = class

  end;

  TCouchDBResponse = class
  private
    Frev: string;
    Fok: Boolean;
    Fid: string;
  public
    property ok: Boolean read Fok write Fok;
    property id: string read Fid write Fid;
    property rev: string read Frev write Frev;
  end;

  TCouchDBClient = class(TRESTClient)
  public
    [POST]
    [Path('/unittest')]
    [Consumes(MEDIA_TYPE.JSON)]
    [Produces(MEDIA_TYPE.JSON)]
    {$WARNINGS OFF}
    function AddPerson(APerson: TCouchPerson): TCouchDBResponse; virtual;

    [GET]
    [Path('/unittest/{AId}')]
    [Consumes(MEDIA_TYPE.JSON)]
    [Produces(MEDIA_TYPE.JSON)]
    function GetPerson(const AId: string): TCouchPerson; virtual;

    [Path('/unittest/')]
    [Consumes(MEDIA_TYPE.JSON)]
    [PUT]
    function CreateDatabase(): TCouchDBResponse; virtual;

    [Path('/unittest/')]
    [Consumes(MEDIA_TYPE.JSON)]
    [DELETE]
    function DeleteDatabase(): TCouchDBResponse; virtual;

    [Path('/unittest')]
    [Consumes(MEDIA_TYPE.JSON)]
    [Produces(MEDIA_TYPE.JSON)]
    [GET]
    function GetDBInfo(): TCouchDBInfo; virtual;

    {$WARNINGS ON}
  end;


  TCouchDBTest = class(TTestCase)
  private
    FClient: TCouchDBClient;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  protected
    procedure CreateDatabase();
    procedure DeleteDatabase();
  published
    procedure Add_Get_Document();
  end;

implementation

uses
  SvWeb.Consts
  ,SysUtils
  ,IdHTTP
  ;

{ TCouchDBTest }

procedure TCouchDBTest.Add_Get_Document;
var
  LResp: TCouchDBResponse;
  LPerson, LNewPerson: TCouchPerson;
begin
  LPerson := TCouchPerson.Create;
  try
    LPerson.Name := 'FooBar';
    LPerson.LastEdited := Now;
    LPerson.MyId := 1;
    LResp := FClient.AddPerson(LPerson);
    try
      CheckTrue(LResp.ok);

      LNewPerson := FClient.GetPerson(LResp.id);
      try
        CheckEquals(LPerson.Name, LNewPerson.Name);
        CheckEquals(LPerson.MyId, LNewPerson.MyId);
      finally
        LNewPerson.Free;
      end;
    finally
      LResp.Free;
    end;
  finally
    LPerson.Free;
  end;
end;

procedure TCouchDBTest.CreateDatabase;
var
  LResp: TCouchDBResponse;
  LDBInfo: TCouchDBInfo;
begin
  try
  LResp := FClient.CreateDatabase;
    try
      CheckTrue(LResp.ok);
    finally
      LResp.Free;
    end;
  except
    //eat
  end;

  LDBInfo := FClient.GetDBInfo();
  try
    CheckEquals('unittest', LDBInfo.db_name);
  finally
    LDBInfo.Free;
  end;
end;

procedure TCouchDBTest.DeleteDatabase;
var
  LDBInfo: TCouchDBInfo;
begin
  try
    LDBInfo := FClient.GetDBInfo();
    try
      if SameText('unittest', LDBInfo.db_name) then
      begin
        FClient.DeleteDatabase();
      end;
    finally
      LDBInfo.Free;
    end;
  except

  end;
end;

procedure TCouchDBTest.Setup;
begin
  inherited;
  FClient := TCouchDBClient.Create('http://127.0.0.1:5984');
  FClient.SetHttpClient(HTTP_CLIENT_INDY);
  CreateDatabase();
end;

procedure TCouchDBTest.TearDown;
begin
  inherited;
  DeleteDatabase();
  FClient.Free;
end;

 {$WARNINGS OFF}

{ TCouchDBClient }

function TCouchDBClient.AddPerson(APerson: TCouchPerson): TCouchDBResponse;
begin

end;

function TCouchDBClient.CreateDatabase: TCouchDBResponse;
begin

end;

function TCouchDBClient.DeleteDatabase: TCouchDBResponse;
begin

end;

function TCouchDBClient.GetDBInfo: TCouchDBInfo;
begin

end;

function TCouchDBClient.GetPerson(const AId: string): TCouchPerson;
begin

end;

{$WARNINGS ON}

function CouchDBInstalled(): Boolean;
var
  LHttp: TIdHTTP;
  LResp: string;
begin
  LHttp := TIdHTTP.Create(nil);
  try
    try
      LResp := LHttp.Get('http://127.0.0.1:5984');
      Result := LResp <> '';
    except
      Result := False;
    end;
  finally
    LHttp.Free;
  end;
end;

initialization
  if CouchDBInstalled then
    RegisterTest(TCouchDBTest.Suite);

end.
