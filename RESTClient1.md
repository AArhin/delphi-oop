# Usage example #

In this example we will show you how to consume OData.org RESTful web service using SvRestClient. Full source code can be found in RestClientGUI [Demo project](https://code.google.com/p/delphi-oop/source/browse/#svn%2Ftrunk%2FDemos%2FREST%20Client).

First define our types:
```
uses
  SvREST.Client
  ,SvContainers
  ,SvHTTP.Attributes
  ;

type
  TCustomer = class
  private
    ...
  public
    ...
  end;

  TCustomers = class
  private
    FValue: TSvObjectList<TCustomer>;
  public
    destructor Destroy; override;

    property Value: TSvObjectList<TCustomer> read FValue write FValue;
  end;

```
_Note that our declared types must be correctly mapped with data structures produced by RESTful service._

Define our REST client:

```
  TODataNorthwindClient = class(TSvRESTClient)
  public
    [GET] [Path('/Customers')] [Consumes(MEDIA_TYPE.JSON)]
    function GetCustomers(): TCustomers; virtual;
  end;
```

_Note that our declared methods should be virtual, public and correctly annotated._

Or if you use Delphi XE2 or higher define an interface:
```
  IODataNorthwindClient = interface(IInvokable)
    ['{055E3262-AA1E-43E7-90BC-7A1E84D0746D}']
    [GET] [Path('/Customers')] [Consumes(MEDIA_TYPE.JSON)]
    function GetCustomers(): TCustomers;
  end;
```

As you see, our `TODataNorthwindClient` should inherit from `TSvRESTClient` class. If you are using XE2 or higher you only need to define your interface, there is no need to inherit from any other class. Attributes are used here to define various properties which will be used by our client, e.g. `[Consumes(MEDIA_TYPE.JSON)]` and function return type specifies that `TSvRESTClient` will automatically deserialize received json string from the server into `TODataNorthwindClient` instance, `[GET]` specifies that GET HTTP method will be used, `[Path('/Customers')]` specifies relative path from the base URL.

That's it. Now we just need to create our client and call `GetCustomers()` method:

![https://lh6.googleusercontent.com/-J9ZRzCwLYos/UjoSKrjpxDI/AAAAAAAAC4k/WJLMNnOoEO8/w1005-h603-no/RestDemo.jpg](https://lh6.googleusercontent.com/-J9ZRzCwLYos/UjoSKrjpxDI/AAAAAAAAC4k/WJLMNnOoEO8/w1005-h603-no/RestDemo.jpg)


### Injection ###
SvRESTClient can automatically inject IHttpResponse interface which belongs to the current context. To demonstrate this we need to change our method definition:
```
[GET] [Path('/Customers')] [Consumes(MEDIA_TYPE.JSON)]
function GetCustomers([Context] out AResponse; IHttpResponse): TCustomers; virtual;
```
We added a new AResponse parameter to our method annotated with [Context](Context.md) attribute which tells client to inject IHttpResponse intance into AResponse argument after the call is made. So now we can write our code like this:
```
var
  LResponse: IHttpResponse;
  LCustomers: TCustomers;
  LHeadersText, LResponseText: string;
begin
  LCustomers := FClient.GetCustomers(LResponse);
  if (LResponse.GetResponseCode = 200) then
  begin
    LHeadersText := LResponse.GetHeadersText;
    LResponseText := LResponse.GetResponseText;
  end;
end;
```

# Path #
Suppose we want to make a GET request with a variable in our path, e.g. http://localhost/unittest/{AId} where AId is our variable. We must define our method as follows:
```
[GET]
[Path('/unittest/{AId}')]
[Consumes(MEDIA_TYPE.JSON)]
function GetPerson([QueryParam] const AId: string): TCouchPerson; virtual;
```
This way SvRESTClient will inject your given AId value into main URL. So if you call function like this:
`LPerson := FClient.GetPerson('11D7');`
Request will be made using this URL: http://localhost/unittest/11D7



_More usage examples of SvREST Client can be found in the unit tests of delphi-oop library._