unit GoogleOAuthTest;

interface

uses
  TestFramework
  ,SvHTTPClientInterface
  ,SvRest.Client
  ,SvHTTP.Authentication.Google
  ,SvHTTP.Attributes
  ;

type
  TGooglePlusPerson = class
  private
    Fkind: string;
    Fgender: string;
    FdisplayName: string;
    Fid: string;
  public
    property kind: string read Fkind write Fkind;
    property gender: string read Fgender write Fgender;
    property displayName: string read FdisplayName write FdisplayName;
    property id: string read Fid write Fid;
  end;


  TGoogleClient = class(TRESTClient)
  public
    [GET]
    [Path('/people/me')]
    [Consumes(MEDIA_TYPE.JSON)]
    {$WARNINGS OFF}
    function GetMe(): TGooglePlusPerson; virtual;
    {$WARNINGS ON}
  end;

  TGoogleOAuthTest = class(TTestCase)
  private
    FGoogleAuth: TSvGoogleAuth;
    FClient: TGoogleClient;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Authenticate_And_GetMe();
  end;

implementation

uses
  SvWeb.Consts
  ;

//androidmaniac13@gmail.com

{ TGoogleOAuthTest }

procedure TGoogleOAuthTest.Authenticate_And_GetMe;
var
  LPerson: TGooglePlusPerson;
begin
  FGoogleAuth.AccessToken := 'ya29.AHES6ZSEuqCTbIavTdo9OL4Az-VSgi3lxyf-x5iEbZbey5pTPw';
  FGoogleAuth.RefreshToken := '1/5pElECbO_RwX8gZoUdCV3SB9i1fH366vb6uXwSbfvNE';
  FGoogleAuth.ClientSecret := 'secret';
  FGoogleAuth.ClientId := 'id';
  FGoogleAuth.RedirectUri := 'uri';

  CheckTrue( FGoogleAuth.DoAuthenticate );

  FClient.Authentication := FGoogleAuth;
  LPerson := FClient.GetMe();
  try
    CheckEquals('Linas Naginionis', LPerson.displayName);
    CheckEquals('male', LPerson.gender);
  finally
    LPerson.Free;
  end;
end;

procedure TGoogleOAuthTest.Setup;
begin
  inherited;
  FGoogleAuth := TSvGoogleAuth.Create();
  FClient := TGoogleClient.Create('https://www.googleapis.com/plus/v1');
  FClient.SetHttpClient(HTTP_CLIENT_INDY);
end;

procedure TGoogleOAuthTest.TearDown;
begin
  inherited;
  FClient.Free;
end;

{ TGoogleClient }

{$WARNINGS OFF}

function TGoogleClient.GetMe: TGooglePlusPerson;
begin
  //
end;

{$WARNINGS ON}

initialization
  RegisterTest(TGoogleOAuthTest.Suite);

end.
