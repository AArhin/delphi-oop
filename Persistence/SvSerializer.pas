(*
* Copyright (c) 2011, Linas Naginionis
* Contacts: lnaginionis@gmail.com or support@soundvibe.net
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the <organization> nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)
{*******************************************************}
{                                                       }
{       SvSerializer                                    }
{                                                       }
{       Copyright (C) 2011 "Linas Naginionis"           }
{                                                       }
{*******************************************************}

unit SvSerializer;

{$I sv.inc}
interface

uses
  SysUtils, Classes, Rtti, Generics.Collections, Types, TypInfo;

type
  TSvVisibilities = set of TMemberVisibility;

  TSvSerializer = class;

  SvSerialize = class(TCustomAttribute)
  private
    FName: string;
    FGetData : TFunc<TValue, TValue>;
    FSetData : TProc<TValue>;
  public
    constructor Create(const AName: string = ''); overload;
    constructor Create(const AName: string; aGetData : TFunc<TValue, TValue>;
      aSetData : TProc<TValue>); overload; //not implemented yet

    property GetData : TFunc<TValue, TValue> read FGetData write FGetData;
    property SetData : TProc<TValue> read FSetData write FSetData;
    property Name: string read FName;
  end;

  /// <remarks>
  /// Properties marked as [SvTransient] are ignored during serialization/deserialization
  /// </remarks>
  SvTransientAttribute = class(TCustomAttribute);

  ESvSerializeException = class(Exception);

  TSvSerializeFormat = (sstJson = 0, sstXML);

  TSvRttiInfo = class
  strict private
    class var
      FCtx: TRttiContext;
    class constructor Create;
    class destructor Destroy;
  public
    class property Context: TRttiContext read FCtx;
    class function FindType(const AQualifiedName: string): TRttiType;
    class function GetType(ATypeInfo: Pointer): TRttiType; overload;
    class function GetType(AClass: TClass): TRttiType; overload;
    class function GetType(const Value: TValue): TRttiType; overload;
    class function GetTypes: TArray<TRttiType>;
    class function GetPackages: TArray<TRttiPackage>;
    class function GetBasicMethod(const AMethodName: string; AType: TRttiType): TRttiMethod;
    class procedure SetValue(AProp: TRttiProperty; const AInstance, AValue: TValue); overload;
    class procedure SetValue(AField: TRttiField; const AInstance, AValue: TValue); overload;
    class function GetValue(AProp: TRttiProperty; const AInstance: TValue): TValue;
  end;

  TSvAbstractSerializer = class
  private
    FOwner: TSvSerializer;
    FErrors: TList<string>;
  protected
    procedure BeginSerialization(); virtual;
    procedure EndSerialization(); virtual; abstract;
    procedure BeginDeSerialization(AStream: TStream); virtual;
    procedure EndDeSerialization(AStream: TStream); virtual; abstract;

    procedure SerializeObject(const AKey: string; const obj: TValue; AStream: TStream;
      ACustomProps: TStringDynArray); virtual; abstract;
    procedure DeSerializeObject(const AKey: string; obj: TValue; AStream: TStream;
      ACustomProps: TStringDynArray); virtual; abstract;
    function GetObjectUniqueName(const AKey: string; obj: TObject): string; overload; virtual;
    function GetObjectUniqueName(const AKey: string; obj: TValue): string; overload; virtual;
    procedure PostError(const ErrorText: string); virtual;

    function IsTypeEnumerable(ARttiType: TRttiType; out AEnumMethod: TRttiMethod): Boolean; virtual;
    function IsTransient(AProp: TRttiProperty): Boolean;
  public
    constructor Create(AOwner: TSvSerializer); virtual;
    destructor Destroy; override;

    procedure ClearErrors();

    property Errors: TList<string> read FErrors;
    property Owner: TSvSerializer read FOwner;
  end;

  /// <summary>
  /// Serializer class which can serialize almost any type to a file or a stream
  /// </summary>
  TSvSerializer = class
  private
    FObjs: TDictionary<string, TPair<TValue,TStringDynArray>>;
    FSerializeFormat: TSvSerializeFormat;
    FFactory: TSvAbstractSerializer;
    procedure SetSerializeFormat(const Value: TSvSerializeFormat);
    function GetObject(const AName: string): TObject;
    function GetCount: Integer;
    function GetErrorCount: Integer;
  protected
    procedure CreateFactory(AFormat: TSvSerializeFormat); virtual;

    procedure DoSerialize(AStream: TStream); virtual;
    procedure DoDeSerialize(AStream: TStream); virtual;


  public
    constructor Create(AFormat: TSvSerializeFormat = sstJson); virtual;
    destructor Destroy; override;
    /// <summary>
    /// Adds object to be used in serialization. Properties will be serialized with SvSerialize attribute
    /// </summary>
    /// <param name="AKey">unique key name which defines where to store object properties</param>
    /// <param name="obj">object to serialize</param>
    procedure AddObject(const AKey: string; const obj: TObject);
    /// <summary>
    /// Adds object and it's named properties which will be used in serialization
    /// </summary>
    /// <param name="AKey">unique key name which defines where to store object properties</param>
    /// <param name="obj">object to serialize</param>
    /// <param name="APropNames">object properties to serialize</param>
    procedure AddObjectCustomProperties(const AKey: string; const obj: TObject;
      APropNames: array of string);
    /// <summary>
    /// Adds object and all of it's properties in given visibility which will be used in serialization
    /// </summary>
    /// <param name="AKey">unique key name which defines where to store object properties</param>
    /// <param name="obj">object to serialize</param>
    /// <param name="AVisibilities">Visibilities of properties to serialize</param>
    procedure AddObjectProperties(const AKey: string; const obj: TObject;
      AVisibilities: TSvVisibilities = [mvPublished]);
    procedure RemoveObject(const AKey: string); overload;
    procedure RemoveObject(const AObj: TObject); overload;
    procedure ClearObjects;

    property Count: Integer read GetCount;
    property Objects[const AName: string]: TObject read GetObject; default;

    class function GetAttribute(AProp: TRttiProperty): SvSerialize;
    class function TryGetAttribute(AProp: TRttiProperty; out AAtribute: SvSerialize): Boolean;
    
    class function GetPropertyByName(const APropName: string; ARttiType: TRttiType): TRttiProperty;
    /// <summary>
    /// Deserializes all added objects from the file
    /// </summary>
    /// <param name="AFilename">filename from where to load object's properties</param>
    procedure DeSerialize(const AFromFilename: string); overload; virtual;
    /// <summary>
    /// Deserializes all added objects from the stream
    /// </summary>
    /// <param name="AStream">stream from where to load object's properties</param>
    procedure DeSerialize(AFromStream: TStream); overload; virtual;
    /// <summary>
    /// Deserializes all added objects from the string
    /// </summary>
    /// <param name="AStream">stream from where to load object's properties</param>
    procedure DeSerialize(const AFromString: string; const AEncoding: TEncoding); overload;
    /// <summary>
    /// Serializes all added objects to the file
    /// </summary>
    /// <param name="AFilename">filename where to store objects</param>
    procedure Serialize(const AToFilename: string); overload; virtual;
    /// <summary>
    /// Serializes all added objects to the stream
    /// </summary>
    /// <param name="AStream">stream where to store objects</param>
    procedure Serialize(AToStream: TStream); overload; virtual;
    /// <summary>
    /// Serializes all added objects to the string
    /// </summary>
    /// <param name="AStream">stream where to store objects</param>
    procedure Serialize(var AToString: string; const AEncoding: TEncoding); overload; virtual;
    /// <summary>
    ///  Marshalls record's properties into stream
    /// </summary>
    procedure Marshall<T: record>(const AWhat: T; AToStream: TStream); overload;
    /// <summary>
    ///  Marshalls record's properties into file
    /// </summary>
    procedure Marshall<T: record>(const AWhat: T; var AToString: string; const AEncoding: TEncoding); overload;
    /// <summary>
    ///  Marshalls record's properties into string
    /// </summary>
    procedure Marshall<T: record>(const AWhat: T; const AToFilename: string); overload;
    /// <summary>
    ///  Returns record unmarshalled from stream
    /// </summary>
    function UnMarshall<T: record>(AFromStream: TStream): T; overload;
    /// <summary>
    ///  Returns record unmarshalled from file
    /// </summary>
    function UnMarshall<T: record>(const AFromFilename: string): T; overload;
    /// <summary>
    ///  Returns record unmarshalled from string
    /// </summary>
    function UnMarshall<T: record>(const AFromString: string; AEncoding: TEncoding): T; overload;

    function GetErrors(): TArray<string>;
    function GetErrorsAsString(): string;

    class function CreateType<T: class>: T; overload;
    class function CreateType(ATypeInfo: PTypeInfo): TObject; overload;

    property ErrorCount: Integer read GetErrorCount;
    property Factory: TSvAbstractSerializer read FFactory;
    property SerializeFormat: TSvSerializeFormat read FSerializeFormat write SetSerializeFormat;
  end;

implementation

uses
  SvSerializerJson,
  SvSerializerXML;

{ SvSerialize }

constructor SvSerialize.Create(const  AName: string);
begin
  Create(AName, nil, nil);
end;

constructor SvSerialize.Create(const AName: string; aGetData: TFunc<TValue, TValue>;
  aSetData: TProc<TValue>);
begin
  inherited Create();
  FName := AName;
  FGetData := aGetData;
  FSetData := aSetData;
end;

{ TSvBaseSerializer }

procedure TSvSerializer.AddObject(const AKey: string; const obj: TObject);
begin
  AddObjectCustomProperties(AKey, obj, []);
end;

procedure TSvSerializer.AddObjectCustomProperties(const AKey: string; const obj: TObject;
  APropNames: array of string);
var
  LPair: TPair<TValue,TStringDynArray>;
  LArray: TStringDynArray;
  i: Integer;
begin
  if Assigned(obj) then
  begin
    LPair.Key := obj;
    SetLength(LArray, Length(APropNames));
    for i := Low(APropNames) to High(APropNames) do
    begin
      LArray[i] := APropNames[i];
    end;

    LPair.Value := LArray;
    FObjs.AddOrSetValue(AKey, LPair);
  end;
end;

procedure TSvSerializer.AddObjectProperties(const AKey: string; const obj: TObject; AVisibilities: TSvVisibilities);
var
  LType: TRttiType;
  LCurrProp: TRttiProperty;
  LArray: array of string;
  LStrings: TStringlist;
  i: Integer;
  LValue: TValue;
begin
  if Assigned(obj) then
  begin
    LValue := obj;
    LType := TSvRttiInfo.GetType(LValue);
    LStrings := TStringList.Create;
    try
      for LCurrProp in LType.GetProperties do
      begin
        if LCurrProp.Visibility in AVisibilities then
        begin
          LStrings.Add(LCurrProp.Name);
        end;

      end;

      SetLength(LArray, LStrings.Count);
      for i := 0 to LStrings.Count - 1 do
      begin
        LArray[i] := LStrings[i];
      end;

      AddObjectCustomProperties(AKey, obj, LArray);

    finally
      LStrings.Free;
    end;

  end;
end;

procedure TSvSerializer.ClearObjects;
begin
  FObjs.Clear;
end;

constructor TSvSerializer.Create(AFormat: TSvSerializeFormat);
begin
  inherited Create();
  FSerializeFormat := AFormat;
  FObjs := TDictionary<string, TPair<TValue,TStringDynArray>>.Create();
  FFactory := nil;
  CreateFactory(FSerializeFormat);
end;

procedure TSvSerializer.CreateFactory(AFormat: TSvSerializeFormat);
begin
  if Assigned(FFactory) then
    FreeAndNil(FFactory);

  case AFormat of
    sstJson: FFactory := TSvJsonSerializer.Create(Self);
    {$WARNINGS OFF}
    sstXML: FFactory := TSvXMLSerializer.Create(Self);
    {$WARNINGS ON}
  end;
end;

class function TSvSerializer.CreateType(ATypeInfo: PTypeInfo): TObject;
var
  LType: TRttiType;
  LMethCreate: TRttiMethod;
  LInstanceType: TRttiInstanceType;
begin
  LType := TSvRttiInfo.GetType(ATypeInfo);        
  for LMethCreate in LType.GetMethods do
  begin
    if (LMethCreate.IsConstructor) and (Length(LMethCreate.GetParameters) = 0) then
    begin
      LInstanceType := LType.AsInstance;

      Result := LMethCreate.Invoke(LInstanceType.MetaclassType, []).AsObject;
      Exit;
    end;
  end;  
  Result := nil;
end;

class function TSvSerializer.CreateType<T>: T;
var
  LValue: TValue;
  LType: TRttiType;
  LMethCreate: TRttiMethod;
  LInstanceType: TRttiInstanceType;
begin
  LType := TSvRttiInfo.GetType(TypeInfo(T));

  for LMethCreate in LType.GetMethods do
  begin
    if (LMethCreate.IsConstructor) and (Length(LMethCreate.GetParameters) = 0) then
    begin
      LInstanceType := LType.AsInstance;

      LValue := LMethCreate.Invoke(LInstanceType.MetaclassType, []);

      Result := LValue.AsType<T>;

      Exit;
    end;
  end;
end;

procedure TSvSerializer.DeSerialize(const AFromFilename: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AFromFilename, fmOpenRead or fmShareDenyNone);
  try
    DeSerialize(fs);
  finally
    fs.Free;
  end;
end;

procedure TSvSerializer.DeSerialize(AFromStream: TStream);
begin
  {DONE -oLinas -cGeneral : deserialize from stream}
  DoDeSerialize(AFromStream);
end;

procedure TSvSerializer.DeSerialize(const AFromString: string;
  const AEncoding: TEncoding);
var
  ss: TStringStream;
begin
  ss := TStringStream.Create(AFromString, AEncoding);
  try
    DeSerialize(ss);
  finally
    ss.Free;
  end;
end;

destructor TSvSerializer.Destroy;
begin
  FObjs.Free;
  FFactory.Free;
  inherited Destroy;
end;

procedure TSvSerializer.DoDeSerialize(AStream: TStream);
var
  LPair: TPair<string, TPair<TValue,TStringDynArray>>;
begin
  inherited;
  FFactory.BeginDeSerialization(AStream);
  try
    for LPair in FObjs do
    begin
      FFactory.DeSerializeObject(LPair.Key, LPair.Value.Key, AStream, LPair.Value.Value);
    end;
  finally
    FFactory.EndDeSerialization(AStream);
  end;
end;

procedure TSvSerializer.DoSerialize(AStream: TStream);
var
  LPair: TPair<string, TPair<TValue,TStringDynArray>>;
begin
  inherited;

  FFactory.BeginSerialization;
  try
    for LPair in FObjs do
    begin
      FFactory.SerializeObject(LPair.Key, LPair.Value.Key, AStream, LPair.Value.Value);
    end;

  finally
    FFactory.EndSerialization;
  end;
end;

class function TSvSerializer.GetAttribute(AProp: TRttiProperty): SvSerialize;
var
  LAttr: TCustomAttribute;
begin
  for LAttr in AProp.GetAttributes do
  begin
    if LAttr is SvSerialize then
    begin
      Exit(SvSerialize(LAttr));
    end;
  end;

  Result := nil;
end;

function TSvSerializer.GetCount: Integer;
begin
  Result := FObjs.Count;
end;

function TSvSerializer.GetErrorCount: Integer;
begin
  Result := FFactory.FErrors.Count;
end;

function TSvSerializer.GetErrors: TArray<string>;
begin
  Result := FFactory.FErrors.ToArray;
end;

function TSvSerializer.GetErrorsAsString: string;
var
  LErrors: TList<string>;
  I: Integer;
begin
  Result := '';
  LErrors := FFactory.FErrors;
  for I := 0 to LErrors.Count - 1 do
  begin
    Result := Result + LErrors[I] + #13#10;
  end;
end;

function TSvSerializer.GetObject(const AName: string): TObject;
var
  LPair: TPair<TValue,TStringDynArray>;
begin
  if FObjs.TryGetValue(AName, LPair) then
    Result := LPair.Key.AsObject
  else
    Result := nil;
end;

class function TSvSerializer.GetPropertyByName(const APropName: string; ARttiType: TRttiType): TRttiProperty;
var
  LProp: TRttiProperty;
begin
  for LProp in ARttiType.GetProperties do
  begin
    if SameText(APropName, LProp.Name) then
    begin
      Exit(LProp);
    end;
  end;
  Result := nil;
end;

procedure TSvSerializer.Marshall<T>(const AWhat: T; var AToString: string;
  const AEncoding: TEncoding);
var
  ss: TStringStream;
begin
  AToString := '';
  ss := TStringStream.Create('', AEncoding);
  try
    Marshall(AWhat, ss);

    AToString := ss.DataString;
  finally
    ss.Free;
  end;
end;

procedure TSvSerializer.Marshall<T>(const AWhat: T; AToStream: TStream);
var
  LValue: TValue;
  LArray: TStringDynArray;
begin
  LValue := TValue.From<T>(AWhat);
  FFactory.BeginSerialization;
  try
    FFactory.SerializeObject('Main', LValue, AToStream, LArray);
  finally
    FFactory.EndSerialization;
  end;
end;


procedure TSvSerializer.Marshall<T>(const AWhat: T; const AToFilename: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AToFilename, fmCreate);
  try
    Marshall<T>(AWhat, fs);
  finally
    fs.Free;
  end;
end;


procedure TSvSerializer.RemoveObject(const AObj: TObject);
var
  LPair: TPair<string, TPair<TValue,TStringDynArray>>;
  ptrLeft, ptrRight: Pointer;
begin
  Assert(Assigned(AObj), 'Cannot remove nil object');

  for LPair in FObjs do
  begin
    ptrLeft := AObj;
    ptrRight := LPair.Value.Key.AsObject;

    if ptrLeft = ptrRight then
    begin
      RemoveObject(LPair.Key);
      Exit;
    end;
  end;
end;

procedure TSvSerializer.RemoveObject(const AKey: string);
begin
  FObjs.Remove(AKey);
end;

procedure TSvSerializer.Serialize(const AToFilename: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AToFilename, fmCreate);
  try
    Serialize(fs);
  finally
    fs.Free;
  end;
end;

procedure TSvSerializer.Serialize(AToStream: TStream);
begin
  {DONE -oLinas -cGeneral : serialize to stream}
  DoSerialize(AToStream);
end;

procedure TSvSerializer.Serialize(var AToString: string; const AEncoding: TEncoding);
var
  ss: TStringStream;
begin
  AToString := '';
  ss := TStringStream.Create('', AEncoding);
  try
    Serialize(ss);

    AToString := ss.DataString;
  finally
    ss.Free;
  end;
end;

procedure TSvSerializer.SetSerializeFormat(const Value: TSvSerializeFormat);
begin
  if FSerializeFormat <> Value then
  begin
    FSerializeFormat := Value;

    CreateFactory(FSerializeFormat);
  end;

end;



class function TSvSerializer.TryGetAttribute(AProp: TRttiProperty;
  out AAtribute: SvSerialize): Boolean;
begin
  AAtribute := GetAttribute(AProp);
  Result := Assigned(AAtribute);
end;

function TSvSerializer.UnMarshall<T>(const AFromString: string;
  AEncoding: TEncoding): T;
var
  ss: TStringStream;
begin
  ss := TStringStream.Create(AFromString, AEncoding);
  try
    Result := UnMarshall<T>(ss);
  finally
    ss.Free;
  end;
end;

function TSvSerializer.UnMarshall<T>(AFromStream: TStream): T;
var
  LValue: TValue;
  LArray: TStringDynArray;
begin          
  //Result := T.Create;
  LValue := TValue.From<T>(Result);
  FFactory.BeginDeSerialization(AFromStream);
  try
    FFactory.DeSerializeObject('Main', LValue, AFromStream, LArray);
  finally
    FFactory.EndDeSerialization(AFromStream);
  end;
  Result := LValue.AsType<T>;
end;

function TSvSerializer.UnMarshall<T>(const AFromFilename: string): T;
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AFromFilename, fmOpenRead or fmShareDenyNone);
  try
    Result := UnMarshall<T>(fs);
  finally
    fs.Free;
  end;
end;

{ TSvSerializerFactory }

function TSvAbstractSerializer.GetObjectUniqueName(const AKey: string; obj: TObject): string;
begin
  if Assigned(obj) then
  begin
    Result := Format('%S.%S',[obj.ClassName, AKey]);
  end
  else
  begin
    raise ESvSerializeException.Create('Cannot get object unique name. Object cannot be nil');
  end;
end;

procedure TSvAbstractSerializer.BeginDeSerialization(AStream: TStream);
begin
  ClearErrors;
end;

procedure TSvAbstractSerializer.BeginSerialization;
begin
  ClearErrors;
end;

procedure TSvAbstractSerializer.ClearErrors;
begin
  FErrors.Clear;
end;

constructor TSvAbstractSerializer.Create(AOwner: TSvSerializer);
begin
  inherited Create();
  FOwner := AOwner;
  FErrors := TList<string>.Create;
end;

destructor TSvAbstractSerializer.Destroy;
begin
  FErrors.Free;
  inherited Destroy;
end;

function TSvAbstractSerializer.GetObjectUniqueName(const AKey: string; obj: TValue): string;
begin
  if not obj.IsEmpty then
  begin
    Result := Format('%S.%S',[obj.TypeInfo.Name, AKey]);
  end
  else
  begin
    raise ESvSerializeException.Create('Cannot get object unique name. Object cannot be nil');
  end;
end;

function TSvAbstractSerializer.IsTransient(AProp: TRttiProperty): Boolean;
var
  LAttrib: TCustomAttribute;
begin
  if Assigned(AProp) then
  begin
    for LAttrib in AProp.GetAttributes do
    begin
      if LAttrib is SvTransientAttribute then
      begin
        Exit(True);
      end;
    end;
  end;
  Result := False;
end;

function TSvAbstractSerializer.IsTypeEnumerable(ARttiType: TRttiType; out AEnumMethod: TRttiMethod): Boolean;
begin
  AEnumMethod := ARttiType.GetMethod('GetEnumerator');     
  Result := Assigned(AEnumMethod);
end;


procedure TSvAbstractSerializer.PostError(const ErrorText: string);
begin
  if ErrorText <> '' then
    FErrors.Add(ErrorText);
end;

{ TSvRttiInfo }

class constructor TSvRttiInfo.Create;
begin
  FCtx := TRttiContext.Create;
end;

class destructor TSvRttiInfo.Destroy;
begin
  FCtx.Free;
end;

class function TSvRttiInfo.FindType(const AQualifiedName: string): TRttiType;
begin
  Result := FCtx.FindType(AQualifiedName);
end;

class function TSvRttiInfo.GetBasicMethod(const AMethodName: string; AType: TRttiType): TRttiMethod;
var
  LMethod: TRttiMethod;
  iParCount, iCurrParCount, iCount: Integer;
begin
  LMethod := nil;
  iParCount := 0;
  iCurrParCount := 0;
  for Result in AType.GetMethods do
  begin
    if SameText(Result.Name, AMethodName) then
    begin
      iCount := Length(Result.GetParameters);
      if (iCount < iParCount) or (iCount = 0) then
      begin
        Exit;
      end
      else
      begin
        if (iCount > iCurrParCount) then
        begin
          Inc(iParCount);
        end;

        iCurrParCount := iCount;
        LMethod := Result;
      end;
    end;
  end;

  Result := LMethod;
end;

class function TSvRttiInfo.GetPackages: TArray<TRttiPackage>;
begin
  Result := FCtx.GetPackages;
end;

class function TSvRttiInfo.GetType(AClass: TClass): TRttiType;
begin
  Result := FCtx.GetType(AClass);
end;

class function TSvRttiInfo.GetTypes: TArray<TRttiType>;
begin
  Result := FCtx.GetTypes;
end;

class function TSvRttiInfo.GetValue(AProp: TRttiProperty; const AInstance: TValue): TValue;
begin
  if AInstance.IsObject then
    Result := AProp.GetValue(AInstance.AsObject)
  else
    Result := AProp.GetValue(AInstance.GetReferenceToRawData);
end;

class procedure TSvRttiInfo.SetValue(AField: TRttiField; const AInstance, AValue: TValue);
begin
  if AInstance.IsObject then
    AField.SetValue(AInstance.AsObject, AValue)
  else
    AField.SetValue(AInstance.GetReferenceToRawData, AValue);
end;

class procedure TSvRttiInfo.SetValue(AProp: TRttiProperty; const AInstance, AValue: TValue);
begin
  if AInstance.IsObject then
    AProp.SetValue(AInstance.AsObject, AValue)
  else
    AProp.SetValue(AInstance.GetReferenceToRawData, AValue);
end;

class function TSvRttiInfo.GetType(ATypeInfo: Pointer): TRttiType;
begin
  Result := FCtx.GetType(ATypeInfo);
end;

class function TSvRttiInfo.GetType(const Value: TValue): TRttiType;
begin
  Result := GetType(Value.TypeInfo);
end;

end.
