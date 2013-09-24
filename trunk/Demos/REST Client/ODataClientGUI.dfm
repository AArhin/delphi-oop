object frmOData: TfrmOData
  Left = 0
  Top = 0
  Caption = 'Consume OData REST service (Demo)'
  ClientHeight = 565
  ClientWidth = 989
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pcData: TPageControl
    Left = 0
    Top = 41
    Width = 989
    Height = 524
    ActivePage = tsCustomers
    Align = alClient
    TabOrder = 0
    object tsCustomers: TTabSheet
      Caption = 'Customers'
      object vtCustomers: TVirtualStringTree
        Left = 0
        Top = 0
        Width = 981
        Height = 496
        Align = alClient
        BorderStyle = bsNone
        DrawSelectionMode = smBlendedRectangle
        Header.AutoSizeIndex = 0
        Header.DefaultHeight = 17
        Header.Font.Charset = DEFAULT_CHARSET
        Header.Font.Color = clWindowText
        Header.Font.Height = -11
        Header.Font.Name = 'Tahoma'
        Header.Font.Style = []
        Header.Options = [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoShowSortGlyphs, hoVisible]
        TabOrder = 0
        TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
        TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toShowRoot, toShowTreeLines, toThemeAware, toUseBlendedImages, toUseBlendedSelection, toUseExplorerTheme, toHideTreeLinesIfThemed]
        TreeOptions.SelectionOptions = [toExtendedFocus, toFullRowSelect]
        OnDblClick = vtCustomersDblClick
        OnGetText = vtCustomersGetText
        Columns = <
          item
            Position = 0
            Width = 80
            WideText = 'CustID'
          end
          item
            Position = 1
            Width = 100
            WideText = 'CompanyName'
          end
          item
            Position = 2
            Width = 100
            WideText = 'ContactName'
          end
          item
            Position = 3
            Width = 100
            WideText = 'ContactTitle'
          end
          item
            Position = 4
            Width = 100
            WideText = 'Address'
          end
          item
            Position = 5
            Width = 100
            WideText = 'City'
          end
          item
            Position = 6
            Width = 100
            WideText = 'Country'
          end
          item
            Position = 7
            Width = 100
            WideText = 'Phone'
          end
          item
            Position = 8
            Width = 100
            WideText = 'Fax'
          end>
        WideDefaultText = ''
      end
    end
    object tsOrders: TTabSheet
      Caption = 'Orders'
      ImageIndex = 2
      object vtOrders: TVirtualStringTree
        Left = 0
        Top = 0
        Width = 981
        Height = 496
        Align = alClient
        BorderStyle = bsNone
        DrawSelectionMode = smBlendedRectangle
        Header.AutoSizeIndex = 0
        Header.DefaultHeight = 17
        Header.Font.Charset = DEFAULT_CHARSET
        Header.Font.Color = clWindowText
        Header.Font.Height = -11
        Header.Font.Name = 'Tahoma'
        Header.Font.Style = []
        Header.Options = [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoShowSortGlyphs, hoVisible]
        TabOrder = 0
        TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
        TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toShowRoot, toShowTreeLines, toThemeAware, toUseBlendedImages, toUseBlendedSelection, toUseExplorerTheme, toHideTreeLinesIfThemed]
        TreeOptions.SelectionOptions = [toExtendedFocus, toFullRowSelect]
        OnGetText = vtOrdersGetText
        Columns = <
          item
            Position = 0
            Width = 80
            WideText = 'OrderId'
          end
          item
            Position = 1
            Width = 100
            WideText = 'CustomerId'
          end
          item
            Position = 2
            Width = 100
            WideText = 'OrderDate'
          end
          item
            Position = 3
            Width = 100
            WideText = 'ShippedDate'
          end
          item
            Position = 4
            Width = 100
            WideText = 'ShipName'
          end
          item
            Position = 5
            Width = 100
            WideText = 'ShipAddress'
          end
          item
            Position = 6
            Width = 100
            WideText = 'ShipCity'
          end
          item
            Position = 7
            Width = 100
            WideText = 'ShipCountry'
          end>
        WideDefaultText = ''
      end
    end
    object tsJson: TTabSheet
      Caption = 'JSON'
      ImageIndex = 1
      object mmoJSON: TMemo
        Left = 0
        Top = 0
        Width = 981
        Height = 496
        Align = alClient
        BorderStyle = bsNone
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object tsHeaders: TTabSheet
      Caption = 'Response Headers'
      ImageIndex = 3
      object mmoHeaders: TMemo
        Left = 0
        Top = 0
        Width = 981
        Height = 496
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
      end
    end
  end
  object pTop: TPanel
    Left = 0
    Top = 0
    Width = 989
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    object btnGet: TButton
      Left = 4
      Top = 7
      Width = 181
      Height = 23
      Caption = 'Get customers as objects'
      TabOrder = 0
      OnClick = btnGetClick
    end
    object btnGetOrders: TButton
      Left = 191
      Top = 7
      Width = 185
      Height = 23
      Caption = 'Get Selected Customer Orders'
      TabOrder = 1
      OnClick = btnGetOrdersClick
    end
  end
end
