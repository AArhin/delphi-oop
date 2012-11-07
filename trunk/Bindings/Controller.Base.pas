(* MVC Controller.pas
* Created: 2012-11-07 18:23:01
* Copyright (c) 2012, Linas Naginionis
* Contacts: lnaginionis@gmail.com or support@soundvibe.net or linas@vikarina.lt
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
unit Controller.Base;

interface

uses
  Rtti
  ;

type
  Initializable = interface
    ['{FB868AF7-D9EB-4567-9946-5A010CAFAE0E}']
    procedure Initialize();
  end;

  IController<TModel, TView: class> = interface
    ['{AD4951E2-9AE0-4D45-A11F-BD4C70F19349}']
    function GetModel: TModel;
    function GetView: TView;
    function GetAutoFreeView: Boolean;
    function GetAutoFreeModel: Boolean;
    procedure SetAutoFreeView(const Value: Boolean);
    procedure SetAutoFreeModel(const Value: Boolean);

    property AutoFreeView: Boolean read GetAutoFreeView write SetAutoFreeView;
    property AutoFreeModel: Boolean read GetAutoFreeModel write SetAutoFreeModel;
    property Model: TModel read GetModel;
    property View: TView read GetView;
  end;


  ///	<summary>
  ///	  Base controller class  
  ///	</summary>
  ///	<typeparam name="TModel">
  ///	  Model class type
  ///	</typeparam>
  ///	<typeparam name="TView">
  ///	  View (form) class type
  ///	</typeparam>
  ///	<remarks>
  ///	  Controller automatically injects it's fields (marked with Bind
  ///	  attributes) with the same fields from the View. Names of these fields
  ///	  must match.
  ///	</remarks>
  TBaseController<TModel, TView: class> = class(TInterfacedObject, Initializable, IController<TModel, TView>)
  private
    FModel: TModel;
    FView: TView;
    FAutoFreeModel: Boolean;
    FAutoFreeView: Boolean;
    function GetModel: TModel;
    function GetView: TView;
    function GetAutoFreeView: Boolean;
    function GetAutoFreeModel: Boolean;
    procedure SetAutoFreeView(const Value: Boolean);
    procedure SetAutoFreeModel(const Value: Boolean);
  protected
    constructor Create(AModel: TModel; AView: TView); virtual;

    function GetViewComponent(const AComponentName: string): TValue; virtual;
    procedure InjectViewProperties(); virtual;
    /// <remarks>
    /// Descendants must override and write initialization code here
    /// </remarks>
    procedure Initialize(); virtual; abstract;
  public
    destructor Destroy; override;

    ///	<summary>
    ///	  If True then View will be destroyed when controller is freed.
    ///	</summary>
    property AutoFreeView: Boolean read GetAutoFreeView write SetAutoFreeView;

    ///	<summary>
    ///	  If True then Model will be destroyed when controller is freed.
    ///	</summary>
    property AutoFreeModel: Boolean read GetAutoFreeModel write SetAutoFreeModel;

    property Model: TModel read GetModel;
    property View: TView read GetView;
  end;

implementation

uses
  SvBindings
  ;

{ TBaseController<TModel, TView> }

constructor TBaseController<TModel, TView>.Create(AModel: TModel; AView: TView);
begin
  inherited Create();
  FModel := AModel;
  FView := AView;
  InjectViewProperties();
  TDataBindManager.BindView(Self, AModel);
  Initialize();
end;

destructor TBaseController<TModel, TView>.Destroy;
begin
  if FAutoFreeModel then
    FModel.Free;
  if FAutoFreeView then
    FView.Free;
  inherited Destroy;
end;

function TBaseController<TModel, TView>.GetAutoFreeModel: Boolean;
begin
  Result := FAutoFreeModel;
end;

function TBaseController<TModel, TView>.GetAutoFreeView: Boolean;
begin
  Result := FAutoFreeView;
end;

function TBaseController<TModel, TView>.GetModel: TModel;
begin
  Result := FModel;
end;

function TBaseController<TModel, TView>.GetView: TView;
begin
  Result := FView;
end;

function TBaseController<TModel, TView>.GetViewComponent(
  const AComponentName: string): TValue;
var
  LType: TRttiType;
  LField: TRttiField;
begin
  Result := TValue.Empty;

  LType := TRttiContext.Create.GetType(FView.ClassType);
  LField := LType.GetField(AComponentName);
  if Assigned(LField) then
  begin
    Result := LField.GetValue(TObject(FView));
  end;
end;

procedure TBaseController<TModel, TView>.InjectViewProperties;
var
  LType: TRttiType;
  LField: TRttiField;
  LAttr: TCustomAttribute;
begin
  LType := TRttiContext.Create.GetType(Self.ClassType);
  for LField in LType.GetFields do
  begin
    for LAttr in LField.GetAttributes do
    begin
      if LAttr is BindAttribute then
      begin
        LField.SetValue(Self, GetViewComponent(LField.Name));
        Break;
      end;
    end;
  end;
end;

procedure TBaseController<TModel, TView>.SetAutoFreeModel(const Value: Boolean);
begin
  FAutoFreeModel := Value;
end;

procedure TBaseController<TModel, TView>.SetAutoFreeView(const Value: Boolean);
begin
  FAutoFreeView := Value;
end;

end.
