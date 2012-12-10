{*******************************************************}
{                                                       }
{       SvSerializerSuperJson                           }
{                                                       }
{       Copyright (C) 2012 "Linas Naginionis"           }
{                                                       }
{*******************************************************}
unit SvSerializerSuperJson;

interface

uses
  Classes, SvSerializer, SysUtils, superobject, Rtti, Types;

type
  TSvSuperJsonSerializer = class(TSvAbstractSerializer<ISuperObject>)
  private
    FMainObj: ISuperObject;
  protected
    procedure BeginSerialization(); override;
    procedure EndSerialization(); override;
    procedure BeginDeSerialization(AStream: TStream); override;
    procedure EndDeSerialization(AStream: TStream); override;

    function DoSetFromNumber(AJsonNumber: ISuperObject): TValue; override;
    function DoSetFromString(AJsonString: ISuperObject; AType: TRttiType; var ASkip: Boolean): TValue; override;
    function DoSetFromArray(AJsonArray: ISuperObject; AType: TRttiType; const AObj: TValue; AProp: TRttiProperty; var ASkip: Boolean): TValue; override;
    function DoSetFromObject(AJsonObject: ISuperObject; AType: TRttiType; const AObj: TValue; AProp: TRttiProperty; var ASkip: Boolean): TValue; override;

    function DoGetFromArray(const AFrom: TValue; AProp: TRttiProperty): ISuperObject; override;
    function DoGetFromClass(const AFrom: TValue; AProp: TRttiProperty): ISuperObject; override;
    function DoGetFromEnum(const AFrom: TValue; AProp: TRttiProperty): ISuperObject; override;
    function DoGetFromRecord(const AFrom: TValue; AProp: TRttiProperty): ISuperObject; override;
    function DoGetFromVariant(const AFrom: TValue; AProp: TRttiProperty): ISuperObject; override;

    function ToString(): string; override;
    function SOString(const AValue: string): ISuperObject;

    procedure SerializeObject(const AKey: string; const obj: TValue; AStream: TStream;
      ACustomProps: TStringDynArray); override;
    procedure DeSerializeObject(const AKey: string; obj: TValue; AStream: TStream;
      ACustomProps: TStringDynArray); override;

    function GetValue(const AFrom: TValue; AProp: TRttiProperty): ISuperObject; override;
    function SetValue(const AFrom: ISuperObject; const AObj: TValue; AProp: TRttiProperty; AType: TRttiType; var Skip: Boolean): TValue; override;

    function GetValueAsVariant(AObject: ISuperObject): Variant;
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

{ TSvSuperJsonSerializer }

procedure TSvSuperJsonSerializer.BeginDeSerialization(AStream: TStream);
begin
  inherited;
  FMainObj := TSuperObject.ParseStream(AStream, False);
end;

procedure TSvSuperJsonSerializer.BeginSerialization;
begin
  inherited;
  FMainObj := SO();
end;

constructor TSvSuperJsonSerializer.Create(AOwner: TSvSerializer);
begin
  inherited Create(AOwner);
  FMainObj := nil;
end;

procedure TSvSuperJsonSerializer.DeSerializeObject(const AKey: string; obj: TValue; AStream: TStream;
  ACustomProps: TStringDynArray);
var
  LType: TRttiType;
  LProp: TRttiProperty;
  LValue: TValue;
  LObject: ISuperObject;
  LPropName: string;
  I: Integer;
  LSkip: Boolean;
  LField: TRttiField;
  LAttrib: SvSerialize;
  LSuperProp: ISuperObject;
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
      LObject := FMainObj.O[GetObjectUniqueName(AKey, obj)];
    end;

    if Assigned(LObject) and (LObject.IsType(stObject)) then
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

            LSuperProp := LObject.O[LPropName];
            if Assigned(LSuperProp) then
            begin
              LValue := SetValue(LSuperProp, obj, LProp, LProp.PropertyType, LSkip);
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
            LSuperProp := LObject.O[LPropName];
            if Assigned(LSuperProp) then
            begin
              LValue := SetValue(LSuperProp, obj, TRttiProperty(LField), LField.FieldType, LSkip);
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

            LSuperProp := LObject.O[LPropName];
            if Assigned(LSuperProp) then
            begin
              LValue := SetValue(LSuperProp, obj, LProp, LProp.PropertyType, LSkip);
              if not LSkip then
                TSvRttiInfo.SetValue(LProp, obj, LValue);
            end;
          end;
        end;
      end;
    end;
  end;
end;

destructor TSvSuperJsonSerializer.Destroy;
begin
  FMainObj := nil;
  inherited;
end;

function TSvSuperJsonSerializer.DoGetFromArray(const AFrom: TValue; AProp: TRttiProperty): ISuperObject;
var
  i: Integer;
  LJsonArray: TSuperArray;
begin
  Result := TSuperObject.Create(stArray);
  LJsonArray := Result.AsArray;
  for i := 0 to AFrom.GetArrayLength - 1 do
  begin
    LJsonArray.Add(GetValue(AFrom.GetArrayElement(i), nil));
  end;
end;

function TSvSuperJsonSerializer.DoGetFromClass(const AFrom: TValue; AProp: TRttiProperty): ISuperObject;
var
  i, iRecNo: Integer;
  LJsonArray: TSuperArray;
  LJsonObject: ISuperObject;
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
      LDst := TDataSet(AFrom.AsObject);
      Result := TSuperObject.Create(stArray);
      LDst.DisableControls;
      FormatSettings := FFormatSettings;
      try
        iRecNo := LDst.RecNo;
        LDst.First;
        while not LDst.Eof do
        begin
          LJsonObject := TSuperObject.Create;
          for i := 0 to LDst.Fields.Count - 1 do
          begin
            if LDst.Fields[i].IsNull then
            begin
              LJsonObject.N[LDst.Fields[i].FieldName] := TSuperObject.Create(stNull);
            end
            else
            begin
              LJsonObject.O[LDst.Fields[i].FieldName] := SOString(LDst.Fields[i].AsString);
            end;

          end;
          Result.AsArray.Add(LJsonObject);
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
        Result := TSuperObject.Create(stArray);
        LJsonArray := Result.AsArray;
        LEnumerator := LEnumMethod.Invoke(AFrom,[]);
        LEnumType :=  TSvRttiInfo.GetType(LEnumerator.TypeInfo);
        LMoveNextMethod := LEnumType.GetMethod('MoveNext');
        LCurrentProp := LEnumType.GetProperty('Current');
        Assert(Assigned(LMoveNextMethod), 'MoveNext method not found');
        Assert(Assigned(LCurrentProp), 'Current property not found');
        while LMoveNextMethod.Invoke(LEnumerator.AsObject,[]).asBoolean do
        begin
          LJsonArray.Add(GetValue(LCurrentProp.GetValue(LEnumerator.AsObject), LCurrentProp));
        end;

        if LEnumerator.IsObject then
        begin
          LEnumerator.AsObject.Free;
        end;
      end
      else
      begin
        //other object types
        Result := TSuperObject.Create;
          //try to serialize

        for LCurrentProp in LType.GetProperties do
        begin
          if IsTransient(LCurrentProp) then
          begin
            Continue;
          end;
          if LCurrentProp.Visibility in [mvPublic,mvPublished] then
          begin
            //try to serialize only published properties
            Result.O[LCurrentProp.Name] := GetValue(LCurrentProp.GetValue(AFrom.AsObject), LCurrentProp);
          end;
        end;
      end;
    end;
  end;
end;

function TSvSuperJsonSerializer.DoGetFromEnum(const AFrom: TValue; AProp: TRttiProperty): ISuperObject;
var
  bVal: Boolean;
begin
  if AFrom.TryAsType<Boolean>(bVal) then
  begin
    if bVal then
      Result := SO(True)
    else
      Result := SO(False);
  end
  else
  begin
    Result := SOString(AFrom.ToString);
  end;
end;

function TSvSuperJsonSerializer.DoGetFromRecord(const AFrom: TValue; AProp: TRttiProperty): ISuperObject;
var
  LType: TRttiType;
  LRecordType: TRttiRecordType;
  LField: TRttiField;
begin
  LType := TSvRttiInfo.GetType(AFrom.TypeInfo);
  LRecordType := LType.AsRecord;
  Result := SO;
  for LField in LRecordType.GetFields do
  begin
    Result.O[LField.Name] := GetValue(LField.GetValue(AFrom.GetReferenceToRawData), nil);
  end;
end;

function TSvSuperJsonSerializer.DoGetFromVariant(const AFrom: TValue; AProp: TRttiProperty): ISuperObject;
var
  LVariant: Variant;
begin
  LVariant := AFrom.AsVariant;

  if VarIsNull(LVariant) or VarIsEmpty(LVariant) then
    Result := SO(Null)
  else
    Result := SOString(VarToStr(LVariant));
end;

function TSvSuperJsonSerializer.DoSetFromArray(AJsonArray: ISuperObject; AType: TRttiType; const AObj: TValue;
  AProp: TRttiProperty; var ASkip: Boolean): TValue;
var
  LJsonValue: ISuperObject;
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
  LJsonArray: TSuperArray;
  LEntry: ISuperObject;
  LEnum: TSuperAvlEntry;
begin
  bCreated := False;
  LValue := TValue.Empty;
  if Assigned(AType) then
  begin
    LJsonArray := AJsonArray.AsArray;
    case AType.TypeKind of
      tkArray:
      begin
        SetLength(arrVal, LJsonArray.Length);

        for i := 0 to Length(arrVal)-1 do
        begin
          arrVal[i] := SetValue(LJsonArray.N[i], AObj, AProp, TRttiArrayType(AType).ElementType, ASkip);
        end;

        Result := TValue.FromArray(AType.Handle, arrVal);
      end;
      tkDynArray:
      begin
        SetLength(arrVal, LJsonArray.Length);

        for i := 0 to Length(arrVal)-1 do
        begin
          arrVal[i] := SetValue(LJsonArray.N[i], AObj, AProp, TRttiDynamicArrayType(AType).ElementType, ASkip);
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

              if Assigned(LJsonArray) then
              begin
                LDst.DisableControls;
                FormatSettings := FFormatSettings;
                try
                  for i := 0 to LJsonArray.Length - 1 do
                  begin
                    try
                      LDst.Append;
                      for LEnum in LJsonArray.N[i].AsObject do
                      begin
                        sVal := LEnum.Name;
                        LField := LDst.FindField(sVal);
                        if Assigned(LField) then
                        begin
                          LField.AsString := LEnum.Value.AsString;
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

              for i := 0 to LJsonArray.Length - 1 do
              begin
                LJsonValue := LJsonArray.N[i];

                //Assert(Length(LParamsArray) = LJsonValue.AsArray.Length, 'Parameters count differ');
                if LJsonValue.IsType(stObject) then
                begin
                  x := 0;
                  for LEntry in LJsonValue do
                  begin
                    arrVal[x] := SetValue(LEntry,
                      AObj, nil, LParamsArray[x].ParamType, ASkip);
                    Inc(x);
                  end;
                //  for x := 0 to TJSONObject(LJsonValue).Size - 1 do
                //  begin

                 // end;
                end
                else if LJsonValue.IsType(stArray) then
                begin
                  for x := 0 to LJsonValue.AsArray.Length - 1 do
                  begin
                    arrVal[x] :=
                      SetValue(LJsonValue.AsArray.N[x], AObj, nil, LParamsArray[x].ParamType, ASkip);
                  end;
                end;

                LEnumerator := LEnumMethod.Invoke(LValue, arrVal);
              end;
            end
            else
            begin
              SetLength(arrVal, LJsonArray.Length);

              for i := 0 to Length(arrVal)-1 do
              begin
                LJsonValue := LJsonArray.N[i];

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

function TSvSuperJsonSerializer.DoSetFromNumber(AJsonNumber: ISuperObject): TValue;
var
  sVal: string;
  LInt: Integer;
  LInt64: Int64;
begin
  sVal := AJsonNumber.AsString;

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

function TSvSuperJsonSerializer.DoSetFromObject(AJsonObject: ISuperObject; AType: TRttiType; const AObj: TValue;
  AProp: TRttiProperty; var ASkip: Boolean): TValue;
var
  LField: TRttiField ;
  LRecordType: TRttiRecordType ;
  LCurrProp: TRttiProperty;
  LObject: TObject;
  LJsonObject: TSuperTableString;
  LEntry: TSuperAvlEntry;
begin
  if Assigned(AType) then
  begin
    LJsonObject := AJsonObject.AsObject;
    case AType.TypeKind of
      tkRecord:
      begin
        TValue.MakeWithoutCopy(nil, AType.Handle, Result);
        LRecordType := TSvRttiInfo.GetType(AType.Handle).AsRecord;

        for LEntry in LJsonObject do
        begin
          LField := FindRecordFieldName(LEntry.Name, LRecordType);
          if Assigned(LField) then
          begin
            {DONE -oLinas -cGeneral : fix arguments}
            LField.SetValue(Result.GetReferenceToRawData,
              SetValue(LEntry.Value, AObj, nil, LField.FieldType, ASkip));
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

          for LEntry in LJsonObject do
          begin
            LCurrProp := AType.GetProperty(LEntry.Name);
            if Assigned(LCurrProp) then
            begin
              if IsTransient(LCurrProp) then
              begin
                Continue;
              end;

              LCurrProp.SetValue(GetRawPointer(Result), SetValue(LEntry.Value, Result {AObj}, LCurrProp,
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

            for LEntry in LJsonObject do
            begin
              LCurrProp := AType.GetProperty(LEntry.Name);
              if Assigned(LCurrProp) then
              begin
                if IsTransient(LCurrProp) then
                begin
                  Continue;
                end;
                LCurrProp.SetValue(Result.AsObject, SetValue(LEntry.Value, Result, LCurrProp,
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

function TSvSuperJsonSerializer.DoSetFromString(AJsonString: ISuperObject; AType: TRttiType;
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
          GetEnumValue(AType.Handle, AJsonString.AsString));
      end;
      tkSet:
      begin
        i := StringToSet(AType.Handle, AJsonString.AsString);
        TValue.Make(@i, AType.Handle, Result);
      end;
      tkVariant:
      begin
        Result := TValue.FromVariant(AJsonString.AsString);
      end;
      tkUString, tkWString, tkLString, tkWChar, tkChar, tkString:
      begin
        //avoid skip
        Result := AJsonString.AsString;
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
    Result := AJsonString.AsString;
  end;
end;

procedure TSvSuperJsonSerializer.EndDeSerialization(AStream: TStream);
begin
  inherited;
end;

procedure TSvSuperJsonSerializer.EndSerialization;
begin
  inherited;
  FMainObj := nil;
end;

function TSvSuperJsonSerializer.GetValue(const AFrom: TValue; AProp: TRttiProperty): ISuperObject;
begin
  if IsTransient(AProp) then
    Exit(SO(Null));

  if AFrom.IsEmpty then
    Result := SO(Null)
  else
  begin
    //Result := nil;
    case AFrom.Kind of
      tkInteger: Result := SO(AFrom.AsInteger);
      tkInt64: Result := SO(AFrom.AsInt64);
      tkEnumeration:
      begin
        Result := DoGetFromEnum(AFrom, AProp);
      end;
      tkSet:
      begin
        Result := SOString(AFrom.ToString);
      end;
      tkFloat: Result := SO(AFrom.AsExtended);
      tkString, tkWChar, tkLString, tkWString, tkChar, tkUString:
        Result := SOString(AFrom.AsString);
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
        Result := SOString('Unsupported type: ' + AFrom.ToString);
        //  raise ESvSerializeException.Create('Unsupported type: ' + AFrom.ToString);
      end;
    end;
  end;
end;

function TSvSuperJsonSerializer.GetValueAsVariant(AObject: ISuperObject): Variant;
var
  LInt64: Int64;
  LInt: Integer;
begin
  Result := Null;
  if Assigned(AObject) then
  begin
    case AObject.DataType of
      stBoolean: Result := AObject.AsBoolean;
      stDouble: Result := AObject.AsDouble ;
      stCurrency: Result := AObject.AsCurrency ;
      stInt:
      begin
        LInt64 := AObject.AsInteger;
        if TryStrToInt(IntToStr(LInt64), LInt) then
          Result := LInt
        else
          Result := LInt64;
      end;

      stObject, stArray, stString, stMethod: Result := AObject.AsString;
    end;
  end;
end;

procedure TSvSuperJsonSerializer.SerializeObject(const AKey: string; const obj: TValue; AStream: TStream;
  ACustomProps: TStringDynArray);
var
  LType: TRttiType;
  LProp: TRttiProperty;
  LValue: TValue;
  LObject: ISuperObject;
  LPropName: string;
  I: Integer;
  LField: TRttiField;
  LAttrib: SvSerialize;
begin
  inherited;

  if not obj.IsEmpty and (Assigned(AStream)) then
  begin
    Stream := AStream;
    LType := TSvRttiInfo.GetType(obj);
    //create main object
    if AKey = '' then
    begin
      LObject := FMainObj;
    end
    else
    begin
      LObject := SO();
      FMainObj.O[GetObjectUniqueName(AKey, obj)] := LObject;
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
          LObject.O[LPropName] := GetValue(LValue, LProp);
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
          LObject.O[LPropName] := GetValue(LValue, TRttiProperty(LField));
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
          LObject.O[LPropName] := GetValue(LValue, LProp);
        end;
      end;
    end;
  end;
end;

function TSvSuperJsonSerializer.SetValue(const AFrom: ISuperObject; const AObj: TValue; AProp: TRttiProperty;
  AType: TRttiType; var Skip: Boolean): TValue;
begin
  Skip := False;

  if IsTransient(AProp) then
  begin
    Skip := True;
    Exit(TValue.Empty);
  end;

  if Assigned(AFrom) then
  begin
    if (AFrom.IsType(stInt)) or (AFrom.IsType(stDouble)) or (AFrom.IsType(stCurrency)) then
    begin
      Result := DoSetFromNumber(AFrom);
    end
    else if AFrom.IsType(stString) then
    begin
      Result := DoSetFromString(AFrom, AType, Skip);
    end
    else if AFrom.IsType(stBoolean) then
    begin
      Result := AFrom.AsBoolean;
    end
    else if AFrom.IsType(stNull) then
    begin
      Result := TValue.Empty;
    end
    else if AFrom.IsType(stArray) then
    begin
      Result := DoSetFromArray(AFrom, AType, AObj, AProp, Skip);
    end
    else if AFrom.IsType(stObject) then
    begin
      Result := DoSetFromObject(AFrom, AType, AObj, AProp, Skip);
    end
    else
    begin
      Skip := True;
      PostError('Unsupported value type: ' + AFrom.AsString);
       // raise ESvSerializeException.Create('Unsupported value type: ' + AFrom.ClassName)
    end;
  end;
end;

function TSvSuperJsonSerializer.SOString(const AValue: string): ISuperObject;
var
  LValue: Variant;
begin
  LValue := AValue;
  Result := SO(LValue);
end;

function TSvSuperJsonSerializer.ToString: string;
begin
  Result := FMainObj.AsJSon();
end;

end.
