object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'frmMain'
  ClientHeight = 466
  ClientWidth = 663
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lbl1: TLabel
    Left = 8
    Top = 8
    Width = 68
    Height = 13
    Caption = 'Enter a name:'
  end
  object lbl2: TLabel
    Left = 248
    Top = 8
    Width = 72
    Height = 13
    Caption = 'Enter an email:'
  end
  object pbCanvas: TPaintBox
    Left = 32
    Top = 72
    Width = 201
    Height = 161
  end
  object edtName: TEdit
    Left = 32
    Top = 32
    Width = 201
    Height = 21
    TabOrder = 0
    TextHint = 'Name'
  end
  object edtEmail: TEdit
    Left = 248
    Top = 32
    Width = 201
    Height = 21
    TabOrder = 1
  end
end
