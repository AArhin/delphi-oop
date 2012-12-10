{*******************************************************}
{                                                       }
{       SvSerializerJson                                }
{                                                       }
{       Copyright (C) 2011 "Linas Naginionis"           }
{                                                       }
{*******************************************************}

unit SvSerializerJson;

interface

uses
  Classes, SvSerializer, SysUtils, DBXJSON, Rtti, Types;

type
  TSvJsonString = class(TJSONString)
  private
    function EscapeValue(const AValue: string): string;
  public
    constructor Create(const AValue: string); overload;
  end;

  TSvJsonSerializer = class(TSvAbstractSerializer)
  private
    FMainObj: TJSONObject;
    ss: TStringStream;
    FStream: TStream;
    FFormatSettings, FOldFormatSettings: TFormatSettings;
    FOldNullStrConvert: Boolean;
  protected
    procedure BeginSerialization(); override;
    procedure EndSerialization(); override;
    procedure BeginDeSerialization(AStream: TStream); override;
    procedure EndDeSerialization(AStream: TStream); override;

    function DoSetFromNumber(AJsonNumber: TJSONNumber): TValue; virtual;
    function DoSetFromString(AJsonString: TJSONString; AType: TRttiType; var ASkip: Boolean): TValue; virtual;
    function DoSetFromArray(AJsonArray: TJSONArray; AType: TRttiType; const AObj: TValue; AProp: TRttiProperty; var ASkip: Boolean): TValue; virtual;
    function DoSetFromObject(AJsonObject: TJSONObject; AType: TRttiType; const AObj: TValue; AProp: TRttiProperty; var ASkip: Boolean): TValue; virtual;

    function DoGetFromArray(const AFrom: TValue; AProp: TRttiProperty): TJSONValue; virtual;
    function DoGetFromClass(const AFrom: TValue; AProp: TRttiProperty): TJSONValue; virtual;
    function DoGetFromEnum(const AFrom: TValue; AProp: TRttiProperty): TJSONValue; virtual;
    function DoGetFromRecord(const AFrom: TValue; AProp: TRttiProperty): TJSONValue; virtual;
    function DoGetFromVariant(const AFrom: TValue; AProp: TRttiProperty): TJSONValue; virtual;

    function FindRecordFieldName(const AFieldName: string; ARecord: TRttiRecordType): TRttiField;
  
    procedure SerializeObject(const AKey: string; const obj: TValue; AStream: TStream;
      ACustomProps: TStringDynArray); override;
    procedure DeSerializeObject(const AKey: string; obj: TValue; AStream: TStream;
      ACustomProps: TStringDynArray); override;

    function GetValue(const AFrom: TValue; AProp: TRttiProperty): TJSONValue; virtual;
    function SetValue(const AFrom: TJSONValue; const AObj: TValue; AProp: TRttiProperty; AType: TRttiType; var Skip: Boolean): TValue; virtual;
  public
    constructor Create(AOwner: TSvSerializer); override;
    destructor Destroy; override;
    
  end;

implementation

uses
  TypInfo,
  Variants,
  StrUtils,
  DB;

const
  CT_QUALIFIEDNAME = 'QualifiedName';
  CT_DATASET_RECORDS = 'rows';

{ TSvJsonSerializerFactory }

procedure TSvJsonSerializer.BeginDeSerialization(AStream: TStream);
var
  LBytes: TBytesStream;
  LJsonVal: TJSONValue;
begin
  inherited;
  FMainObj := nil;
  FOldNullStrConvert := NullStrictConvert;
  NullStrictConvert := False;
  if Assigned(AStream) then
  begin
    //parse json stream
    LBytes := TBytesStream.Create();
    try
      LBytes.CopyFrom(AStream, AStream.Size);
      LBytes.Position := 0;

      if LBytes.Size > 0 then
      begin
        LJsonVal := TJSONObject.ParseJSONValue(LBytes.Bytes, 0, LBytes.Size, True);

        if Assigned(LJsonVal) and (LJsonVal is TJSONObject) then
        begin
          FMainObj := TJSONObject(LJsonVal);
        end;
      end;
      
    finally
      LBytes.Free;
    end;
  end
  else
  begin
    PostError('Cannot deserialize from nil stream');
    raise ESvSerializeException.Create('Cannot deserialize from nil stream');
  end;
end;

procedure TSvJsonSerializer.EndDeSerialization(AStream: TStream);
begin
  inherited;
  NullStrictConvert := FOldNullStrConvert;
  if Assigned(FMainObj) then
    FMainObj.Free;
end;

procedure TSvJsonSerializer.BeginSerialization;
begin
  inherited;
  FMainObj := TJSONObject.Create;
  ss := TStringStream.Create('', TEncoding.UTF8);
  FOldNullStrConvert := NullStrictConvert;
  NullStrictConvert := False;
end;

constructor TSvJsonSerializer.Create(AOwner: TSvSerializer);
begin
  inherited Create(AOwner);
  FMainObj := nil;
  ss := nil;
  FFormatSettings := TFormatSettings.Create;
  FFormatSettings.DecimalSeparator := '.';
  FFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  FFormatSettings.DateSeparator := '-';
  FOldFormatSettings := FormatSettings;
end;

procedure TSvJsonSerializer.DeSerializeObject(const AKey: string; obj: TValue;
  AStream: TStream; ACustomProps: TStringDynArray);
var
  LType: TRttiType;
  LProp: TRttiProperty;
  LValue: TValue;
  LObject: TJSONObject;
  LPair: TJSONPair;
  LPropName: string;
  I: Integer;
  LSkip: Boolean;
  LField: TRttiField;
  LAttrib: SvSerialize;
begin
  inherited;
  LObject := nil;
  if not obj.IsEmpty and Assigned(FMainObj) then
  begin
    if AKey = '' then
    begin
      LObject := FMainObj;
    end
    else
    begin
      LPair := FMainObj.Get(GetObjectUniqueName(AKey, obj));
      if Assigned(LPair) and (LPair.JsonValue is TJSONObject) then
      begin
        LObject := TJSONObject(LPair.JsonValue);
      end;
    end;

    if Assigned(LObject) then
    begin
      LType := TSvRttiInfo.GetType(obj);

      if Length(ACustomProps) > 0 then
      begin
        for I := Low(ACustomProps) to High(ACustomProps) do
        begin
          LProp := LType.GetProperty(ACustomProps[I]);
          if Assigned(LProp) and (LProp.IsWritable) then
          begin
            LPropName := LProp.Name;
            LPair := LObject.Get(LPropName);
            if Assigned(LPair) then
            begin
              LValue := SetValue(LPair.JsonValue, obj, LProp, LProp.PropertyType, LSkip);
              if not LSkip then
                TSvRttiInfo.SetValue(LProp, obj, LValue);
            end;
          end;
        end;
      end
      else
      begin
        if LType.IsRecord then
        begin
          for LField in LType.AsRecord.GetFields do
          begin
            LPropName := LField.Name;
            LPair := LObject.Get(LPropName);
            if Assigned(LPair) then
            begin
              LValue := SetValue(LPair.JsonValue, obj, TRttiProperty(LField), LField.FieldType, LSkip);
              if not LSkip then
                TSvRttiInfo.SetValue(LField, obj, LValue);
            end;
          end;
        end
        else
        begin
          for LProp in LType.GetProperties do
          begin
            if not LProp.IsWritable then
              Continue;

            if IsTransient(LProp) then
              Continue;

            LPropName := LProp.Name;
            if TSvSerializer.TryGetAttribute(LProp, LAttrib) then
            begin
              if (LAttrib.Name <> '') then
                LPropName := LAttrib.Name;
            end;

            LPair := LObject.Get(LPropName);
            if Assigned(LPair) then
            begin
              LValue := SetValue(LPair.JsonValue, obj, LProp, LProp.PropertyType, LSkip);
              if not LSkip then
                TSvRttiInfo.SetValue(LProp, obj, LValue);
            end;
          end;
        end;
      end;
    end;
  end;
end;

destructor TSvJsonSerializer.Destroy;
begin
  inherited Destroy;
end;

function TSvJsonSerializer.DoGetFromArray(const AFrom: TValue;
  AProp: TRttiProperty): TJSONValue;
var
  i: Integer;
  LJsonArray: TJSONArray;
begin
  Result := TJSONArray.Create();
  LJsonArray := TJSONArray(Result);
  for i := 0 to AFrom.GetArrayLength - 1 do
  begin
    LJsonArray.AddElement(GetValue(AFrom.GetArrayElement(i), nil));
  end;
end;

function TSvJsonSerializer.DoGetFromClass(const AFrom: TValue;
  AProp: TRttiProperty): TJSONValue;
var
  i, iRecNo: Integer;
  LJsonArray: TJSONArray;
  LJsonObject: TJSONObject;
  LType, LEnumType: TRttiType;
  LEnumMethod, LMoveNextMethod: TRttiMethod;
  LEnumerator: TValue;
  LCurrentProp: TRttiProperty;
  LDst: TDataSet;
begin
  Result := nil;
  LType := TSvRttiInfo.GetType(AFrom.TypeInfo);
  if Assigned(LType) and (AFrom.IsObject) then
  begin
    if AFrom.AsObject is TDataset then
    begin
     // Result := TJSONObject.Create;
      LDst := TDataSet(AFrom.AsObject);

      Result := TJSONArray.Create();
     // TJSONObject(Result).AddPair(TJSONPair.Create(CT_DATASET_RECORDS,
     //   Result));
      LDst.DisableControls;
      FormatSettings := FFormatSettings;
      try
        iRecNo := LDst.RecNo;
        LDst.First;
        while not LDst.Eof do
        begin
          LJsonObject := TJSONObject.Create();
          for i := 0 to LDst.Fields.Count - 1 do
          begin
            if LDst.Fields[i].IsNull then
            begin
              LJsonObject.AddPair(LDst.Fields[i].FieldName, TJSONNull.Create);
            end
            else
            begin
              LJsonObject.AddPair(LDst.Fields[i].FieldName, TSvJsonString.Create(LDst.Fields[i].AsString));
            end;

          end;
          TJSONArray(Result).AddElement(LJsonObject);
          LDst.Next;
        end;

        LDst.RecNo := iRecNo;
      finally
        FormatSettings := FOldFormatSettings;
        LDst.EnableControls;
      end;
    end
    else
    begin
      if IsTypeEnumerable(LType, LEnumMethod) then
      begin
        //enumerator exists
        Result := TJSONArray.Create();
        LJsonArray := TJSONArray(Result);
        LEnumerator := LEnumMethod.Invoke(AFrom,[]);
        LEnumType :=  TSvRttiInfo.GetType(LEnumerator.TypeInfo);
        LMoveNextMethod := LEnumType.GetMethod('MoveNext');
        LCurrentProp := LEnumType.GetProperty('Current');
        Assert(Assigned(LMoveNextMethod), 'MoveNext method not found');
        Assert(Assigned(LCurrentProp), 'Current property not found');
        while LMoveNextMethod.Invoke(LEnumerator.AsObject,[]).asBoolean do
        begin
          LJsonArray.AddElement(GetValue(LCurrentProp.GetValue(LEnumerator.AsObject), LCurrentProp));
        end;

        if LEnumerator.IsObject then
        begin
          LEnumerator.AsObject.Free;
        end;
      end
      else
      begin
        //other object types
        Result := TJSONObject.Create;
          //try to serialize
       // TJSONObject(Result).AddPair(TJSONPair.Create(CT_QUALIFIEDNAME,
       //   TSvJsonString.Create(rType.QualifiedName)));

        for LCurrentProp in LType.GetProperties do
        begin
          if IsTransient(LCurrentProp) then
          begin
            Continue;
          end;
          if LCurrentProp.Visibility in [mvPublic,mvPublished] then
          begin
            //try to serialize only published properties
            TJSONObject(Result).AddPair(TJSONPair.Create(LCurrentProp.Name,
              GetValue(LCurrentProp.GetValue(AFrom.AsObject), LCurrentProp)));
          end;
        end;
      end;
    end;
  end;
end;

function TSvJsonSerializer.DoGetFromEnum(const AFrom: TValue;
  AProp: TRttiProperty): TJSONValue;
var
  bVal: Boolean;
begin
  if AFrom.TryAsType<Boolean>(bVal) then
  begin
    if bVal then
      Result := TJSONTrue.Create
    else
      Result := TJSONFalse.Create;
  end
  else
  begin
    Result := TSvJsonString.Create(AFrom.ToString);
  end;
end;

function TSvJsonSerializer.DoGetFromRecord(const AFrom: TValue;
  AProp: TRttiProperty): TJSONValue;
var
  LType: TRttiType;
  LRecordType: TRttiRecordType;
  LField: TRttiField;
begin
  LType := TSvRttiInfo.GetType(AFrom.TypeInfo);
  LRecordType := LType.AsRecord;
  Result := TJSONObject.Create();
  for LField in LRecordType.GetFields do
  begin
    TJSONObject(Result).AddPair(TJSONPair.Create(LField.Name,
      GetValue(LField.GetValue(AFrom.GetReferenceToRawData), nil)));
  end;
end;

function TSvJsonSerializer.DoGetFromVariant(const AFrom: TValue;
  AProp: TRttiProperty): TJSONValue;
var
  LVariant: Variant;
begin
  LVariant := AFrom.AsVariant;

  if VarIsNull(LVariant) or VarIsEmpty(LVariant) then
    Result := TJSONNull.Create
  else
    Result := TSvJsonString.Create(VarToStr(LVariant));
end;

function TSvJsonSerializer.DoSetFromArray(AJsonArray: TJSONArray; AType: TRttiType;
  const AObj: TValue; AProp: TRttiProperty; var ASkip: Boolean): TValue;
var
  LJsonValue: TJSONValue;
  arrVal: array of TValue;
  i, x: Integer;
  LDst: TDataSet;
  LField: TField;
  sVal: string;
  LObject: TObject;
  LValue, LEnumerator: TValue;
  bCreated: Boolean;
  LEnumMethod, LClearMethod: TRttiMethod;
  LParamsArray: TArray<TRttiParameter>;
begin
  bCreated := False;
  LValue := TValue.Empty;
  if Assigned(AType) then
  begin
    case AType.TypeKind of
      tkArray:
      begin
        SetLength(arrVal, AJsonArray.Size);

        for i := 0 to Length(arrVal)-1 do
        begin
          arrVal[i] := SetValue(AJsonArray.Get(i), AObj, AProp, TRttiArrayType(AType).ElementType, ASkip);
        end;

        Result := TValue.FromArray(AType.Handle, arrVal);
      end;
      tkDynArray:
      begin
        SetLength(arrVal, AJsonArray.Size);

        for i := 0 to Length(arrVal)-1 do
        begin
          arrVal[i] := SetValue(AJsonArray.Get(i), AObj, AProp, TRttiDynamicArrayType(AType).ElementType, ASkip);
        end;

        Result := TValue.FromArray(AType.Handle, arrVal);
      end;
      tkClass:
      begin
        if Assigned(AType) then
        begin
          if Assigned(AProp) then
          begin
            Result := TSvRttiInfo.GetValue(AProp, AObj);
            if Result.AsObject is TDataSet then
            begin
              //deserialize TDataSet
              LDst := TDataSet(Result.AsObject);

              if Assigned(AJsonArray) then
              begin
                LDst.DisableControls;
                FormatSettings := FFormatSettings;
                try
                  for i := 0 to AJsonArray.Size - 1 do
                  begin
                    try
                      LDst.Append;

                      for x := 0 to TJSONObject(AJsonArray.Get(i)).Size - 1 do
                      begin
                        //get fieldname from json object
                        sVal := TJSONObject(AJsonArray.Get(i)).Get(x).JsonString.Value;
                        LField := LDst.FindField(sVal);
                        if Assigned(LField) then
                        begin
                          //check if not null
                          if TJSONObject(AJsonArray.Get(i)).Get(x).JsonValue is TJSONNull then
                            LField.Clear
                          else
                            LField.AsString := TJSONObject(AJsonArray.Get(i)).Get(x).JsonValue.Value;
                        end;
                      end;

                      LDst.Post;
                    except
                      on E:Exception do
                      begin
                        PostError(E.Message);
                      end;
                    end;
                  end;

                finally
                  LDst.EnableControls;
                  FormatSettings := FOldFormatSettings;
                end;
                Exit;
              end;

            end;
          end
          else
          begin
            //if AProp not assigned then we must create it
            if AType.IsInstance then
            begin
              LObject := TSvSerializer.CreateType(AType.Handle);
              if Assigned(LObject) then
              begin
                LValue := LObject;
                bCreated := True;
              end;
            end;
          end;

          LEnumMethod := TSvRttiInfo.GetBasicMethod('Add', AType);
          if Assigned(LEnumMethod) and ( (Assigned(AProp)) or not (LValue.IsEmpty)  ) then
          begin
            if LValue.IsEmpty and Assigned(AProp) then
              LValue := TSvRttiInfo.GetValue(AProp, AObj);
           // AValue := AProp.GetValue(AObj);

            if LValue.AsObject = nil then
            begin
              LValue := TSvSerializer.CreateType(AProp.PropertyType.Handle);
              bCreated := True;
            end;

            LClearMethod := TSvRttiInfo.GetBasicMethod('Clear', AType);
            if Assigned(LClearMethod) and (Length(LClearMethod.GetParameters) = 0) then
            begin
              LClearMethod.Invoke(LValue, []);
            end;

            LParamsArray := LEnumMethod.GetParameters;

            if Length(LParamsArray) > 1 then
            begin
              SetLength(arrVal, Length(LParamsArray));
              //probably we are dealing with key value pair class like TDictionary

              for i := 0 to AJsonArray.Size - 1 do
              begin
                LJsonValue := AJsonArray.Get(i);


                Assert(Length(LParamsArray) = TJSONObject(LJsonValue).Size, 'Parameters count differ');
                if LJsonValue is TJSONObject then
                begin
                  for x := 0 to TJSONObject(LJsonValue).Size - 1 do
                  begin
                    arrVal[x] := SetValue(TJSONObject(LJsonValue).Get(x).JsonValue,
                      AObj, nil, LParamsArray[x].ParamType, ASkip);
                  end;
                end
                else if LJsonValue is TJSONArray then
                begin
                  for x := 0 to TJSONArray(LJsonValue).Size - 1 do
                  begin
                    arrVal[x] :=
                      SetValue(TJSONArray(LJsonValue).Get(x), AObj, nil, LParamsArray[x].ParamType, ASkip);
                  end;
                end;

                LEnumerator := LEnumMethod.Invoke(LValue, arrVal);
              end;
            end
            else
            begin
              SetLength(arrVal, AJsonArray.Size);

              for i := 0 to Length(arrVal)-1 do
              begin
                LJsonValue := AJsonArray.Get(i);

                {TODO -oLinas -cGeneral : fix arguments}
                //AParams[0].ParamType.AsInstance.
                arrVal[i] := SetValue(LJsonValue, AObj, nil, LParamsArray[0].ParamType, ASkip);


                LEnumerator := LEnumMethod.Invoke(LValue, [arrVal[i]]);
              end;
            end;

            if bCreated then
            begin
              Result := LValue;
              ASkip := False;
              Exit;
            end;
            ASkip := True;
          end;
        end;
      end
      else
      begin
        ASkip := True;
        PostError('Cannot assign array data to non array type');
       // raise ESvSerializeException.Create('Cannot assign array data to non array type');
      end;
    end;
  end;
end;

function TSvJsonSerializer.DoSetFromNumber(AJsonNumber: TJSONNumber): TValue;
var
  sVal: string;
  LInt: Integer;
  LInt64: Int64;
begin
  sVal := AJsonNumber.ToString;

  if TryStrToInt(sVal, LInt) then
  begin
    Result := LInt;
  end
  else if TryStrToInt64(sVal, LInt64) then
  begin
    Result := LInt64;
  end
  else
  begin
    Result := AJsonNumber.AsDouble;
  end;
end;

function TSvJsonSerializer.DoSetFromObject(AJsonObject: TJSONObject; AType: TRttiType;
  const AObj: TValue; AProp: TRttiProperty; var ASkip: Boolean): TValue;
var
  i: Integer;
  LField: TRttiField ;
  LRecordType: TRttiRecordType ;
  LCurrProp: TRttiProperty;
  LObject: TObject;
begin
  if Assigned(AType) then
  begin
    case AType.TypeKind of
      tkRecord:
      begin
        TValue.MakeWithoutCopy(nil, AType.Handle, Result);
        LRecordType := TSvRttiInfo.GetType(AType.Handle).AsRecord;

        for i := 0 to AJsonObject.Size - 1 do
        begin
          //search for property name
          LField := FindRecordFieldName(AJsonObject.Get(i).JsonString.Value, LRecordType);
          if Assigned(LField) then
          begin
            {DONE -oLinas -cGeneral : fix arguments}
            LField.SetValue(Result.GetReferenceToRawData,
              SetValue(AJsonObject.Get(i).JsonValue, AObj, nil, LField.FieldType, ASkip));
          end;
        end;
      end;
      tkClass:
      begin
        //AType := TSvRttiInfo.GetType(AType.Handle);
        if Assigned(AProp) and (AObj.AsObject <> nil) then
        begin
          Result := TSvRttiInfo.GetValue(AProp, AObj);
          if (Result.IsObject) and (Result.AsObject = nil) then
          begin
            Result := TSvSerializer.CreateType(AType.Handle);
          end;

          for i := 0 to AJsonObject.Size - 1 do
          begin
            LCurrProp := AType.GetProperty(AJsonObject.Get(i).JsonString.Value);
            if Assigned(LCurrProp) then
            begin
              if IsTransient(LCurrProp) then
              begin
                Continue;
              end;

              LCurrProp.SetValue(GetRawPointer(Result), SetValue(AJsonObject.Get(i).JsonValue, Result {AObj}, LCurrProp,
                LCurrProp.PropertyType, ASkip));
            end;
          end;
         //  Result := AProp.GetValue(AObj);
        end
        else
        begin
          {DONE -oLinas -cGeneral : create new class and set all props}
          LObject := TSvSerializer.CreateType(AType.Handle);
          if Assigned(LObject) then
          begin
            Result := LObject;
            for i := 0 to AJsonObject.Size - 1 do
            begin
              LCurrProp := AType.GetProperty(AJsonObject.Get(i).JsonString.Value);
              if Assigned(LCurrProp) then
              begin
                if IsTransient(LCurrProp) then
                begin
                  Continue;
                end;
                LCurrProp.SetValue(Result.AsObject, SetValue(AJsonObject.Get(i).JsonValue, Result, LCurrProp,
                  LCurrProp.PropertyType, ASkip));
              end;
            end;
          end;
        end;
      end
      else
      begin
        ASkip := True;
      end;
    end;
  end;
end;

function TSvJsonSerializer.DoSetFromString(AJsonString: TJSONString; AType: TRttiType;
  var ASkip: Boolean): TValue;
var
  i: Integer;
begin
  if Assigned(AType) then
  begin
    case AType.TypeKind of
      tkEnumeration:
      begin
        Result := TValue.FromOrdinal(AType.Handle,
          GetEnumValue(AType.Handle, AJsonString.Value));
      end;
      tkSet:
      begin
        i := StringToSet(AType.Handle, AJsonString.Value);
        TValue.Make(@i, AType.Handle, Result);
      end;
      tkVariant:
      begin
        Result := TValue.FromVariant(AJsonString.Value);
      end;
      tkUString, tkWString, tkLString, tkWChar, tkChar, tkString:
      begin
        //avoid skip
        Result := AJsonString.Value;
      end
      else
      begin
        //error msg value, skip
        PostError('Cannot set unknown type value: ' + AType.ToString);
        ASkip := True;
      end;
    end;
  end
  else
  begin
    Result := AJsonString.Value;
  end;
end;

procedure TSvJsonSerializer.EndSerialization;
begin
  inherited;

  NullStrictConvert := FOldNullStrConvert;

  ss.WriteString(FMainObj.ToString);

  ss.Position := 0;

  FStream.CopyFrom(ss, ss.Size);

  FMainObj.Free;

  ss.Free;
end;

function TSvJsonSerializer.FindRecordFieldName(const AFieldName: string; ARecord: TRttiRecordType): TRttiField;
var
  LField: TRttiField;
begin
  for LField in ARecord.GetFields do
  begin
    if SameText(AFieldName, LField.Name) then
      Exit(LField);
  end;
  Result := nil;
end;

function TSvJsonSerializer.GetValue(const AFrom: TValue; AProp: TRttiProperty): TJSONValue;
begin
  if IsTransient(AProp) then
    Exit(TJSONNull.Create);

  if AFrom.IsEmpty then
    Result := TJSONNull.Create
  else
  begin
    //Result := nil;
    case AFrom.Kind of
      tkInteger: Result := TJSONNumber.Create(AFrom.AsInteger);
      tkInt64: Result := TJSONNumber.Create(AFrom.AsInt64);
      tkEnumeration:
      begin
        Result := DoGetFromEnum(AFrom, AProp);
      end;
      tkSet:
      begin
        Result := TSvJsonString.Create(AFrom.ToString);
      end;
      tkFloat: Result := TJSONNumber.Create(AFrom.AsExtended);
      tkString, tkWChar, tkLString, tkWString, tkChar, tkUString:
        Result := TSvJsonString.Create(AFrom.AsString);
      tkArray, tkDynArray:
      begin
        Result := DoGetFromArray(AFrom, AProp);
      end;
      tkVariant:
      begin
        Result := DoGetFromVariant(AFrom, AProp);
      end;
      tkClass:
      begin
        Result := DoGetFromClass(AFrom, AProp);
      end;
      tkRecord:
      begin
        Result := DoGetFromRecord(AFrom, AProp);
      end
     { tkMethod: ;
      tkInterface: ;
      tkClassRef: ;
      tkPointer: ;
      tkProcedure: ; }
      else
      begin
        PostError('Unsupported type: ' + AFrom.ToString);
        Result := TSvJsonString.Create('Unsupported type: ' + AFrom.ToString);
        //  raise ESvSerializeException.Create('Unsupported type: ' + AFrom.ToString);
      end;
    end;
  end;
end;

procedure TSvJsonSerializer.SerializeObject(const AKey: string; const obj: TValue;
  AStream: TStream; ACustomProps: TStringDynArray);
var
  LType: TRttiType;
  LProp: TRttiProperty;
  LValue: TValue;
  LObject: TJSONObject;
  LPair: TJSONPair;
  LPropName: string;
  I: Integer;
  LField: TRttiField;
  LAttrib: SvSerialize;
begin
  inherited;

  if not obj.IsEmpty and (Assigned(AStream)) then
  begin
    FStream := AStream;
    LType := TSvRttiInfo.GetType(obj);
    //create main object
    if AKey = '' then
    begin
      LObject := FMainObj;
    end
    else
    begin
      LObject := TJSONObject.Create();
      LPair := TJSONPair.Create(GetObjectUniqueName(AKey, obj), LObject);
      FMainObj.AddPair(LPair);
    end;

    if Length(ACustomProps) > 0 then
    begin
      for I := Low(ACustomProps) to High(ACustomProps) do
      begin
        LProp := LType.GetProperty(ACustomProps[I]);
        if Assigned(LProp) then
        begin
          LValue := TSvRttiInfo.GetValue(LProp, obj);

          LPropName := LProp.Name;
                    
          LPair := TJSONPair.Create(TSvJsonString.Create(LPropName), GetValue(LValue, LProp));

          LObject.AddPair(LPair);
        end;        
      end;
    end
    else
    begin
      if LType.IsRecord then
      begin
        for LField in LType.AsRecord.GetFields do
        begin
          LValue := LField.GetValue(obj.GetReferenceToRawData);
          LPropName := LField.Name;
          LPair := TJSONPair.Create(TSvJsonString.Create(LPropName),
            GetValue(LValue, TRttiProperty(LField)));

          LObject.AddPair(LPair);
        end;
      end
      else
      begin
        for LProp in LType.GetProperties do
        begin
          if IsTransient(LProp) then
            Continue;

          LValue := TSvRttiInfo.GetValue(LProp, obj);

          LPropName := LProp.Name;
          if TSvSerializer.TryGetAttribute(LProp, LAttrib) then
          begin
            if (LAttrib.Name <> '') then
              LPropName := LAttrib.Name;

            if Assigned(LAttrib.GetData) then
            begin
              LValue := LAttrib.GetData(LValue);
            end;
          end;

          LPair := TJSONPair.Create(TSvJsonString.Create(LPropName),
            GetValue(LValue, LProp));

          LObject.AddPair(LPair);
        end;
      end;
    end;
  end;
end;

function TSvJsonSerializer.SetValue(const AFrom: TJSONValue; const AObj: TValue; AProp: TRttiProperty; AType: TRttiType; var Skip: Boolean): TValue;
begin
  Skip := False;

  if IsTransient(AProp) then
  begin
    Skip := True;
    Exit(TValue.Empty);
  end;

  if Assigned(AFrom) then
  begin
    if AFrom is TJSONNumber then
    begin
      Result := DoSetFromNumber(TJSONNumber(AFrom));
    end
    else if AFrom is TJSONString then
    begin
      Result := DoSetFromString(TJSONString(AFrom), AType, Skip);
    end
    else if AFrom is TJSONTrue then
    begin
      Result := True;
    end
    else if AFrom is TJSONFalse then
    begin
      Result := False;
    end
    else if AFrom is TJSONNull then
    begin
      Result := TValue.Empty;
    end
    else if AFrom is TJSONArray then
    begin
      Result := DoSetFromArray(TJSONArray(AFrom), AType, AObj, AProp, Skip);
    end
    else if AFrom is TJSONObject then
    begin
      Result := DoSetFromObject(TJSONObject(AFrom), AType, AObj, AProp, Skip);
    end
    else
    begin
      Skip := True;
      PostError('Unsupported value type: ' + AFrom.ToString);
       // raise ESvSerializeException.Create('Unsupported value type: ' + AFrom.ClassName)
    end;
  end;
end;

{ TSvJsonString }

constructor TSvJsonString.Create(const AValue: string);
begin
  {$IF CompilerVersion >= 23}
  inherited Create(AValue);
  {$ELSE}
  inherited Create(EscapeValue(AValue));
  {$IFEND}
end;

function TSvJsonString.EscapeValue(const AValue: string): string;

  procedure AddChars(const AChars: string; var Dest: string; var AIndex: Integer); inline;
  begin
    System.Insert(AChars, Dest, AIndex);
    System.Delete(Dest, AIndex + 2, 1);
    Inc(AIndex, 2);
  end;

  procedure AddUnicodeChars(const AChars: string; var Dest: string; var AIndex: Integer); inline;
  begin
    System.Insert(AChars, Dest, AIndex);
    System.Delete(Dest, AIndex + 6, 1);
    Inc(AIndex, 6);
  end;

var
  i, ix: Integer;
  LChar: Char;
begin
  Result := AValue;
  ix := 1;
  for i := 1 to System.Length(AValue) do
  begin
    LChar :=  AValue[i];
    case LChar of
      '/', '\', '"':
      begin
        System.Insert('\', Result, ix);
        Inc(ix, 2);
      end;
      #8:  //backspace \b
      begin
        AddChars('\b', Result, ix);
      end;
      #9:
      begin
        AddChars('\t', Result, ix);
      end;
      #10:
      begin
        AddChars('\n', Result, ix);
      end;
      #12:
      begin
        AddChars('\f', Result, ix);
      end;
      #13:
      begin
        AddChars('\r', Result, ix);
      end;
      #0 .. #7, #11, #14 .. #31:
      begin
        AddUnicodeChars('\u' + IntToHex(Word(LChar), 4), Result, ix);
      end
      else
      begin
        if Word(LChar) > 127 then
        begin
          AddUnicodeChars('\u' + IntToHex(Word(LChar), 4), Result, ix);
        end
        else
        begin
          Inc(ix);
        end;
      end;
    end;
  end;
end;

end.
