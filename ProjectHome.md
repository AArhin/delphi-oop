# Project moved to [bitbucket](https://bitbucket.org/soundvibe/delphi-oop) #

Object oriented programming for Delphi >= 2010


# Core: #

  * **Design Patterns** - Software design patters (supports >= Delphi 2010) which uses new Delphi language features. Currently implemented patterns: Factory, Multiton, Singleton, Lazy initialization.
  * **Threading** - Futures, Parallel ForEach, Async, etc. [Wiki Page](Threading.md)
  * **Strings** - Object oriented TSvString type.
  * **Delegates** - implementation of multicast events [Wiki Page](Delegates.md)
  * **Classes** - Tuples, generic Enum type, TPathBuilder.
  * **Testing** - DUnit extensions.
  * **Logging** - wraps [Log4D](http://sourceforge.net/projects/log4d/)
  * **DB** - [Dynamic SQL Builder](SQLBuilder.md)


# Bindings: #
  * **SvBindings** - extensions to automate data binding using attributes. Requires [DSharp](http://code.google.com/p/delphisorcery/) library.
  * **MVC (Model View Controller)** pattern implementation

# Persistence: #
  * **SvSerializer** - powerful serializer class which can serialize/deserialize multiple objects. Supports different backends: [json](http://json.org/) (using [superobject](https://code.google.com/p/superobject/) or DBXJSON), XML (using [NativeXml](http://www.simdesign.nl/forum/viewforum.php?f=2)), CSV.

# Web: #
  * **[RESTClient](RESTClient1.md)** - consume RESTful web services using your own annotated class and it's methods (similar to [JAX-RS](http://en.wikipedia.org/wiki/Java_API_for_RESTful_Web_Services)). Supports Google OAuth 2.0 authentication.

_Mostly tested with Delphi XE._