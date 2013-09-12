object frmAuthDialog: TfrmAuthDialog
  Left = 0
  Top = 0
  Caption = 'Authorization'
  ClientHeight = 475
  ClientWidth = 721
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ScreenSnap = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pClient: TPanel
    Left = 0
    Top = 0
    Width = 721
    Height = 440
    Align = alClient
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    ExplicitLeft = 256
    ExplicitTop = 64
    ExplicitWidth = 185
    ExplicitHeight = 41
    object wbBrowser: TWebBrowser
      Left = 0
      Top = 0
      Width = 721
      Height = 440
      Align = alClient
      TabOrder = 0
      ExplicitLeft = 192
      ExplicitTop = 128
      ExplicitWidth = 300
      ExplicitHeight = 150
      ControlData = {
        4C000000844A00007A2D00000000000000000000000000000000000000000000
        000000004C000000000000000000000001000000E0D057007335CF11AE690800
        2B2E126208000000000000004C0000000114020000000000C000000000000046
        8000000000000000000000000000000000000000000000000000000000000000
        00000000000000000100000000000000000000000000000000000000}
    end
  end
  object pBottom: TPanel
    Left = 0
    Top = 440
    Width = 721
    Height = 35
    Align = alBottom
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    DesignSize = (
      721
      35)
    object lblHint: TLabel
      Left = 8
      Top = 9
      Width = 111
      Height = 13
      Caption = 'Paste given code here:'
    end
    object edToken: TEdit
      Left = 141
      Top = 6
      Width = 493
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object btnOk: TButton
      Left = 640
      Top = 6
      Width = 75
      Height = 23
      Action = aConfirm
      Anchors = [akTop, akRight]
      TabOrder = 1
    end
  end
  object alMain: TActionList
    Left = 352
    Top = 240
    object aConfirm: TAction
      Caption = 'Confirm'
      Hint = 'Confirm'
      OnExecute = aConfirmExecute
      OnUpdate = aConfirmUpdate
    end
  end
end
