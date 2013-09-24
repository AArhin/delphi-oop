unit SvHTTPClient.Response;

interface

uses
  SvHTTPClientInterface
  ,Classes
  ;

type
  TSvHttpResponse = class(TInterfacedObject, IHttpResponse)
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

constructor TSvHttpResponse.Create;
begin
  inherited Create;
  FResponseStream := TMemoryStream.Create;
end;

destructor TSvHttpResponse.Destroy;
begin
  FResponseStream.Free;
  inherited Destroy;
end;

function TSvHttpResponse.GetHeadersText: string;
begin
  Result := FHeaders;
end;

function TSvHttpResponse.GetResponseCode: Integer;
begin
  Result := FResponseCode;
end;

function TSvHttpResponse.GetResponseStream: TStream;
begin
  Result := FResponseStream;
end;

function TSvHttpResponse.GetResponseText: string;
begin
  Result := '';
  if FResponseStream is TStringStream then
    Result := TStringStream(FResponseStream).DataString;
end;

procedure TSvHttpResponse.SetResponseStream(const Value: TStream);
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
