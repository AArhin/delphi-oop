unit SvHTTP.Attributes;

interface

uses
  SvHTTPClientInterface
  ;

type
  GETAttribute = class(TCustomAttribute)
  end;

  POSTAttribute = class(TCustomAttribute)
  end;

  PUTAttribute = class(TCustomAttribute)
  end;

  DELETEAttribute = class(TCustomAttribute)
  end;

  QueryParamsAttribute = class(TCustomAttribute)
  end;

  FormParamsAttribute = class(TCustomAttribute)
  end;

  HeaderParamsAttribute = class(TCustomAttribute)
  end;

  PathAttribute = class(TCustomAttribute)
  public
    Path: string;
  public
    constructor Create(const APath: string);
  end;

  ProducesAttribute = class(TCustomAttribute)
  public
    MediaType: MEDIA_TYPE;
  public
    constructor Create(const AMediaType: MEDIA_TYPE);
  end;

  ConsumesAttribute = class(ProducesAttribute);

implementation

{ ProducesAttribute }

constructor ProducesAttribute.Create(const AMediaType: MEDIA_TYPE);
begin
  inherited Create();
  MediaType := AMediaType;
end;

{ PathAttribute }

constructor PathAttribute.Create(const APath: string);
begin
  inherited Create;
  Path := APath;
end;

end.
