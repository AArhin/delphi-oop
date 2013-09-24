unit SvHTTPClient.Response;

interface

uses
  SvHTTPClientInterface
  ,Classes
  ;

type
  THttpResponse = class(TInterfacedObject, IHttpResponse)
  private
    FHeaders: string;
    FResponseCode: Integer;
    FResponseStream: TStream;
    procedure SetResponseStream(const Value: TStream);
  protected
    function GetHeadersText(): string; virtual;
    function GetResponseCode: Integer; virtual;
    function GetResponseText: string; virtual;
    function GetResponseStream: TStream; virtual;
  public
    constructor Create(); virtual;
    destructor Destroy; override;


    property Headers: string read FHeaders write FHeaders;
    property ResponseCode: Integer read FResponseCode write FResponseCode;
    property ResponseStream: TStream read FResponseStream write SetResponseStream;
  end;

implementation

{ THttpResponse }

constructor THttpResponse.Create;
begin
  inherited Create;
  FResponseStream := TMemoryStream.Create;
end;

destructor THttpResponse.Destroy;
begin
  FResponseStream.Free;
  inherited Destroy;
end;

function THttpResponse.GetHeadersText: string;
begin
  Result := FHeaders;
end;

function THttpResponse.GetResponseCode: Integer;
begin
  Result := FResponseCode;
end;

function THttpResponse.GetResponseStream: TStream;
begin
  Result := FResponseStream;
end;

function THttpResponse.GetResponseText: string;
begin
  Result := '';
  if FResponseStream is TStringStream then
    Result := TStringStream(FResponseStream).DataString;
end;

procedure THttpResponse.SetResponseStream(const Value: TStream);
begin
  if not Assigned(Value) then
    FResponseStream.Size := 0
  else
  begin
    if Value is TStringStream then
    begin
      FResponseStream.Free;
      FResponseStream := TStringStream.Create;
    end;
    FResponseStream.CopyFrom(Value, 0);
  end;
end;

end.
