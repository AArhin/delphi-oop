unit SvHTTP.Attributes;

interface

uses
  SvHTTPClientInterface
  ;

type
  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Notifies that GET request should be used.
  ///	</summary>
  {$ENDREGION}
  GETAttribute = class(TCustomAttribute)
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Notifies that POST request should be used.
  ///	</summary>
  {$ENDREGION}
  POSTAttribute = class(TCustomAttribute)
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Notifies that PUT request should be used.
  ///	</summary>
  {$ENDREGION}
  PUTAttribute = class(TCustomAttribute)
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Notifies that DELETE request should be used.
  ///	</summary>
  {$ENDREGION}
  DELETEAttribute = class(TCustomAttribute)
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Notifies that method parameter will be used as a request parameter with
  ///	  the given name.
  ///	</summary>
  {$ENDREGION}
  QueryParamAttribute = class(TCustomAttribute)
  public
    Name: string;
    constructor Create(const AName: string = ''); virtual;
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Sets custom name and value to the request parameter.
  ///	</summary>
  {$ENDREGION}
  QueryParamNameValueAttribute = class(TCustomAttribute)
  public
    Name: string;
    Value: string;
    constructor Create(const AName, AValue: string); virtual;
  end;

  FormParamAttribute = class(TCustomAttribute)
  end;

  HeaderParamAttribute = class(TCustomAttribute)
  end;


  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Represents parameter which should be posted in the request body without
  ///	  any name. Should be used when API requires to send json or xml
  ///	  documents in the request body.
  ///	</summary>
  {$ENDREGION}
  BodyParamAttribute = class(TCustomAttribute)
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  TransientParam makes sure that parameter won't be used in the request.
  ///	</summary>
  {$ENDREGION}
  TransientParamAttribute = class(TCustomAttribute)
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Represents relative path from the base URL.
  ///	</summary>
  {$ENDREGION}
  PathAttribute = class(TCustomAttribute)
  public
    Path: string;
  public
    constructor Create(const APath: string);
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Represents Content_Type which will be used in the request.
  ///	</summary>
  {$ENDREGION}
  ProducesAttribute = class(TCustomAttribute)
  public
    MediaType: MEDIA_TYPE;
  public
    constructor Create(const AMediaType: MEDIA_TYPE);
  end;

  {$REGION 'Documentation'}
  ///	<summary>
  ///	  Represents media type which should be accepted.
  ///	</summary>
  {$ENDREGION}
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

{ QueryParamNameValueAttribute }

constructor QueryParamNameValueAttribute.Create(const AName, AValue: string);
begin
  inherited Create();
  Name := AName;
  Value := AValue;
end;

{ QueryParamAttribute }

constructor QueryParamAttribute.Create(const AName: string);
begin
  inherited Create();
  Name := AName;
end;

end.
