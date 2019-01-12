object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Soccer'
  ClientHeight = 1112
  ClientWidth = 1823
  Color = 8081721
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 6
    Top = 826
    Width = 1366
    Height = 182
    BevelOuter = bvNone
    TabOrder = 0
    object Memo1: TMemo
      Left = 11
      Top = 6
      Width = 252
      Height = 163
      Lines.Strings = (
        '')
      TabOrder = 0
    end
    object Memo3: TMemo
      Left = 527
      Top = 7
      Width = 252
      Height = 162
      Lines.Strings = (
        '')
      TabOrder = 1
    end
    object Button6: TButton
      Left = 1055
      Top = 14
      Width = 75
      Height = 25
      Caption = 'set ball'
      TabOrder = 2
      OnClick = Button6Click
    end
    object Button2: TButton
      Left = 1167
      Top = 144
      Width = 75
      Height = 25
      Caption = 'lstsoccer'
      TabOrder = 3
      OnClick = Button2Click
    end
    object Button7: TButton
      Left = 1167
      Top = 123
      Width = 75
      Height = 25
      Caption = 'Show ShotCells'
      TabOrder = 4
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 1055
      Top = 75
      Width = 75
      Height = 25
      Caption = 'Rnd fatigue'
      TabOrder = 5
      OnClick = Button8Click
    end
    object Button10: TButton
      Left = 1055
      Top = 106
      Width = 75
      Height = 25
      Caption = 'Test Corner'
      TabOrder = 6
      OnClick = Button10Click
    end
    object CheckBox1: TCheckBox
      Left = 1201
      Top = 84
      Width = 113
      Height = 17
      Caption = 'Show Ids/Surname'
      TabOrder = 7
    end
    object MemoC: TMemo
      Left = 785
      Top = 7
      Width = 252
      Height = 162
      Lines.Strings = (
        '')
      TabOrder = 9
    end
    object CheckBoxAI0: TCheckBox
      Left = 1058
      Top = 131
      Width = 87
      Height = 17
      TabOrder = 8
      OnClick = CheckBoxAI0Click
    end
    object CheckBoxAI1: TCheckBox
      Left = 1058
      Top = 154
      Width = 87
      Height = 17
      TabOrder = 10
      OnClick = CheckBoxAI1Click
    end
    object Button1: TButton
      Left = 1055
      Top = 45
      Width = 75
      Height = 25
      Caption = 'set player'
      TabOrder = 11
      OnClick = Button1Click
    end
    object Edit3: TEdit
      Left = 1136
      Top = 48
      Width = 49
      Height = 21
      TabOrder = 12
    end
    object Memo2: TMemo
      Left = 269
      Top = 7
      Width = 252
      Height = 163
      Lines.Strings = (
        '')
      TabOrder = 13
    end
    object CheckBox2: TCheckBox
      Left = 1240
      Top = 154
      Width = 113
      Height = 17
      Caption = 'Pause'
      TabOrder = 14
      OnClick = CheckBox2Click
    end
    object Button3: TButton
      Left = 1302
      Top = 127
      Width = 38
      Height = 25
      Caption = 'load'
      TabOrder = 15
      OnClick = Button3Click
    end
    object CheckBox3: TCheckBox
      Left = 1258
      Top = 104
      Width = 94
      Height = 17
      Caption = 'ThreadCurMove'
      TabOrder = 16
      OnClick = CheckBox3Click
    end
    object Button4: TButton
      Left = 1318
      Top = 151
      Width = 38
      Height = 25
      Caption = 'think'
      TabOrder = 17
      OnClick = Button4Click
    end
    object CnSpinEdit1: TCnSpinEdit
      Left = 1244
      Top = 126
      Width = 52
      Height = 22
      MaxValue = 255
      MinValue = 0
      TabOrder = 18
      Value = 0
    end
    object editN1: TEdit
      Left = 1191
      Top = 48
      Width = 25
      Height = 21
      NumbersOnly = True
      TabOrder = 19
      Text = '0'
    end
    object EditN2: TEdit
      Left = 1222
      Top = 48
      Width = 25
      Height = 21
      NumbersOnly = True
      TabOrder = 20
      Text = '0'
    end
  end
  object PanelBack: SE_Panel
    Left = 8
    Top = 21
    Width = 1393
    Height = 788
    TabOrder = 1
    object imgshpfree: TImage
      Left = 153
      Top = 28
      Width = 20
      Height = 20
      Stretch = True
      Transparent = True
      Visible = False
    end
    object PanelCombatLog: SE_Panel
      Left = 917
      Top = 10
      Width = 466
      Height = 172
      Color = 8081721
      TabOrder = 0
      Visible = False
      object SE_GridDice: SE_Grid
        Left = 9
        Top = 6
        Width = 440
        Height = 158
        Cursor = crHandPoint
        MouseScrollRate = 1.000000000000000000
        MouseWheelInvert = False
        MouseWheelValue = 10
        MouseWheelZoom = True
        MousePan = True
        MouseScroll = False
        BackColor = 8081721
        AnimationInterval = 300
        GridInfoCell = False
        GridVisible = False
        GridColor = clSilver
        GridCellWidth = 40
        GridCellHeight = 30
        GridCellsX = 10
        GridCellsY = 4
        GridHexSmallWidth = 10
        CollisionDelay = 0
        ShowPerformance = False
        VirtualWidth = 212
        Virtualheight = 212
        Passive = True
        TabOrder = 0
        CellBorder = CellBorderNone
        Font.Charset = ANSI_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
      end
    end
    object PanelScore: SE_Panel
      Left = 26
      Top = 111
      Width = 640
      Height = 51
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 1
      Visible = False
      object lbl_Nick0: TCnAAScrollText
        Left = 27
        Top = 3
        Width = 280
        Height = 20
        ParentEffect.ParentColor = False
        ParentEffect.ParentFont = False
        Fonts = <
          item
            Name = 'Title1'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -13
            Font.Name = 'Verdana'
            Font.Style = [fsBold]
            Effect.Shadow.Enabled = True
          end
          item
            Name = 'Title2'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -13
            Font.Name = 'Verdana'
            Font.Style = [fsBold]
            Effect.Shadow.Enabled = True
            Effect.Shadow.OffsetX = 1
            Effect.Shadow.OffsetY = 1
          end
          item
            Name = 'Title3'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlue
            Font.Height = -15
            Font.Name = #191#172#204#229'_GB2312'
            Font.Style = []
            Effect.Shadow.Enabled = True
          end
          item
            Name = 'Text1'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -12
            Font.Name = #191#172#204#229'_GB2312'
            Font.Style = []
            Effect.Shadow.OffsetX = 1
            Effect.Shadow.OffsetY = 1
          end
          item
            Name = 'Text2'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clTeal
            Font.Height = -11
            Font.Name = #191#172#204#229'_GB2312'
            Font.Style = []
            Effect.Shadow.Enabled = True
            Effect.Shadow.OffsetX = 1
            Effect.Shadow.OffsetY = 1
          end
          item
            Name = 'Title4'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -29
            Font.Name = #193#165#202#233
            Font.Style = [fsBold]
            Effect.Shadow.Enabled = True
            Effect.Gradual.Enabled = True
            Effect.Gradual.StartColor = 16720384
            Effect.Gradual.EndColor = 2232575
            Effect.Blur = 50
            Effect.Outline = True
          end
          item
            Name = 'Text3'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlue
            Font.Height = -15
            Font.Name = #193#165#202#233
            Font.Style = []
            Effect.Shadow.Enabled = True
            Effect.Shadow.OffsetX = 1
            Effect.Shadow.OffsetY = 1
            Effect.Gradual.Enabled = True
            Effect.Gradual.Style = gsTopToBottom
            Effect.Gradual.StartColor = 13382417
            Effect.Gradual.EndColor = 16720554
          end>
        Labels = <
          item
            Name = 'Left'
            Style = lsLeftJustify
          end
          item
            Name = 'Center'
            Style = lsCenter
          end
          item
            Name = 'Right'
            Style = lsRightJustify
          end
          item
            Name = 'Owner'
            Style = lsRegOwner
          end
          item
            Name = 'Organization'
            Style = lsRegOrganization
          end
          item
            Name = 'AppTitle'
            Style = lsAppTitle
          end
          item
            Name = 'Date'
            Style = lsDate
          end
          item
            Name = 'Time'
            Style = lsTime
          end>
        Active = False
        ScrollDelay = 80
        Text.Fade = False
        Text.FadeHeight = 0
        Text.TailSpace = 0
        Text.Lines.Strings = (
          '<Title1>Team'
          '<Title2>NickName')
        Text.Font.Charset = DEFAULT_CHARSET
        Text.Font.Color = clBlack
        Text.Font.Height = -11
        Text.Font.Name = 'Tahoma'
        Text.Font.Style = []
        Text.BackColor = 8081721
      end
      object lbl_Nick1: TCnAAScrollText
        Left = 336
        Top = 3
        Width = 280
        Height = 20
        ParentEffect.ParentColor = False
        ParentEffect.ParentFont = False
        Fonts = <
          item
            Name = 'Title1'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -13
            Font.Name = 'Verdana'
            Font.Style = [fsBold]
            Effect.Shadow.Enabled = True
          end
          item
            Name = 'Title2'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWhite
            Font.Height = -13
            Font.Name = 'Verdana'
            Font.Style = [fsBold]
            Effect.Shadow.Enabled = True
            Effect.Shadow.OffsetX = 1
            Effect.Shadow.OffsetY = 1
          end
          item
            Name = 'Title3'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlue
            Font.Height = -15
            Font.Name = #191#172#204#229'_GB2312'
            Font.Style = []
            Effect.Shadow.Enabled = True
          end
          item
            Name = 'Text1'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -12
            Font.Name = #191#172#204#229'_GB2312'
            Font.Style = []
            Effect.Shadow.OffsetX = 1
            Effect.Shadow.OffsetY = 1
          end
          item
            Name = 'Text2'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clTeal
            Font.Height = -11
            Font.Name = #191#172#204#229'_GB2312'
            Font.Style = []
            Effect.Shadow.Enabled = True
            Effect.Shadow.OffsetX = 1
            Effect.Shadow.OffsetY = 1
          end
          item
            Name = 'Title4'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -29
            Font.Name = #193#165#202#233
            Font.Style = [fsBold]
            Effect.Shadow.Enabled = True
            Effect.Gradual.Enabled = True
            Effect.Gradual.StartColor = 16720384
            Effect.Gradual.EndColor = 2232575
            Effect.Blur = 50
            Effect.Outline = True
          end
          item
            Name = 'Text3'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlue
            Font.Height = -15
            Font.Name = #193#165#202#233
            Font.Style = []
            Effect.Shadow.Enabled = True
            Effect.Shadow.OffsetX = 1
            Effect.Shadow.OffsetY = 1
            Effect.Gradual.Enabled = True
            Effect.Gradual.Style = gsTopToBottom
            Effect.Gradual.StartColor = 13382417
            Effect.Gradual.EndColor = 16720554
          end>
        Labels = <
          item
            Name = 'Left'
            Style = lsLeftJustify
          end
          item
            Name = 'Center'
            Style = lsCenter
          end
          item
            Name = 'Right'
            Style = lsRightJustify
          end
          item
            Name = 'Owner'
            Style = lsRegOwner
          end
          item
            Name = 'Organization'
            Style = lsRegOrganization
          end
          item
            Name = 'AppTitle'
            Style = lsAppTitle
          end
          item
            Name = 'Date'
            Style = lsDate
          end
          item
            Name = 'Time'
            Style = lsTime
          end>
        Active = False
        ScrollDelay = 80
        Text.Fade = False
        Text.FadeHeight = 0
        Text.TailSpace = 0
        Text.Lines.Strings = (
          '<Title1>Team'
          '<Title2>NickName')
        Text.Font.Charset = DEFAULT_CHARSET
        Text.Font.Color = clBlack
        Text.Font.Height = -11
        Text.Font.Name = 'Tahoma'
        Text.Font.Style = []
        Text.BackColor = 8081721
      end
      object lbl_score: TLabel
        Left = 307
        Top = 3
        Width = 27
        Height = 20
        Alignment = taCenter
        AutoSize = False
        Caption = '2-1'
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        Transparent = False
      end
      object lbl_minute: TLabel
        Left = 3
        Top = 3
        Width = 27
        Height = 20
        Alignment = taCenter
        AutoSize = False
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clLime
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        Transparent = False
      end
      object btnTactics: TCnSpeedButton
        Tag = 119
        Left = 53
        Top = 29
        Width = 20
        Height = 20
        Cursor = crHandPoint
        AllowAllUp = True
        Color = clBtnFace
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 2
        Caption = 'T'
        Margin = 4
        OnClick = btnTacticsClick
      end
      object btnSubs: TCnSpeedButton
        Tag = 119
        Left = 79
        Top = 29
        Width = 20
        Height = 20
        Cursor = crHandPoint
        AllowAllUp = True
        Color = clBtnFace
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 2
        Margin = 4
        OnClick = btnSubsClick
      end
      object btnWatchLiveExit: TCnSpeedButton
        Left = 259
        Top = 27
        Width = 60
        Height = 21
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'EXIT'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        Visible = False
        OnClick = btnWatchLiveExitClick
      end
      object btnAudioStadium: TCnSpeedButton
        Tag = 119
        Left = 618
        Top = 3
        Width = 20
        Height = 20
        Cursor = crHandPoint
        AllowAllUp = True
        Color = clBtnFace
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 3
        Margin = 4
        OnClick = btnAudioStadiumClick
      end
      object ToolSpin: TCnSpinEdit
        Left = 340
        Top = 5
        Width = 49
        Height = 22
        AutoSelect = False
        MaxValue = 255
        MinValue = 0
        TabOrder = 0
        Value = 0
        Visible = False
        OnChange = ToolSpinChange
        OnKeyPress = toolSpinKeyPress
      end
      object SE_GridTime: SE_Grid
        Left = 89
        Top = 29
        Width = 230
        Height = 18
        MouseScrollRate = 1.000000000000000000
        MouseWheelInvert = False
        MouseWheelValue = 10
        MouseWheelZoom = False
        MousePan = False
        MouseScroll = False
        BackColor = 8081721
        AnimationInterval = 20
        GridInfoCell = False
        GridVisible = False
        GridColor = clSilver
        GridCellWidth = 40
        GridCellHeight = 30
        GridCellsX = 10
        GridCellsY = 4
        GridHexSmallWidth = 10
        CollisionDelay = 0
        ShowPerformance = False
        VirtualWidth = 212
        Virtualheight = 294
        Passive = True
        TabOrder = 1
        CellBorder = CellBorderNone
        CellBorderColor = clGray
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
      end
    end
    object PanelSell: SE_Panel
      Left = 189
      Top = 249
      Width = 116
      Height = 58
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 2
      Visible = False
      object btnConfirmSell: TCnSpeedButton
        Left = 19
        Top = 33
        Width = 74
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'confirm'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnConfirmSellClick
      end
      object edtSell: TEdit
        Left = 3
        Top = 3
        Width = 109
        Height = 27
        Alignment = taCenter
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
    end
    object PanelMain: SE_Panel
      Left = 1136
      Top = 188
      Width = 241
      Height = 225
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 3
      Visible = False
      object btnFormation: TCnSpeedButton
        Left = 3
        Top = 17
        Width = 233
        Height = 32
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'formazione'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnFormationClick
      end
      object btnMainPlay: TCnSpeedButton
        Left = 3
        Top = 49
        Width = 233
        Height = 32
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'play'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnMainPlayClick
      end
      object btnWatchLive: TCnSpeedButton
        Left = 3
        Top = 81
        Width = 233
        Height = 32
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnWatchLive'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnWatchLiveClick
      end
      object btnMarket: TCnSpeedButton
        Left = 3
        Top = 145
        Width = 233
        Height = 32
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnMarket'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnMarketClick
      end
      object btnStandings: TCnSpeedButton
        Left = 3
        Top = 113
        Width = 233
        Height = 32
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnStandings'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnStandingsClick
      end
      object btnExit: TCnSpeedButton
        Left = 3
        Top = 177
        Width = 233
        Height = 32
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnExit'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnExitClick
      end
    end
    object PanelCountryTeam: SE_Panel
      Left = 1031
      Top = 367
      Width = 281
      Height = 293
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 4
      Visible = False
      object btnSelCountryTeam: TCnSpeedButton
        Left = 3
        Top = 253
        Width = 275
        Height = 32
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnselcountryteam'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnSelCountryTeamClick
      end
      object advCountryTeam: TAdvStringGrid
        Left = 3
        Top = 3
        Width = 273
        Height = 244
        Cursor = crHandPoint
        TabStop = False
        Color = 8081721
        ColCount = 2
        DefaultColWidth = 268
        DrawingStyle = gdsClassic
        FixedCols = 0
        RowCount = 1
        FixedRows = 0
        Font.Charset = ANSI_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = []
        GridLineWidth = 0
        Options = [goVertLine]
        ParentFont = False
        ParentShowHint = False
        ScrollBars = ssNone
        ShowHint = False
        TabOrder = 0
        OnKeyPress = advCountryTeamKeyPress
        HoverRowColor = clBlue
        HoverRowColorTo = clBlue
        HoverRowCells = [hcNormal, hcSelected]
        DragDropSettings.ShowCells = False
        DragDropSettings.OleAcceptFiles = False
        DragDropSettings.OleAcceptText = False
        DragDropSettings.OleAcceptURLs = False
        HTMLHint = True
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -16
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ControlLook.FixedGradientHoverFrom = clGray
        ControlLook.FixedGradientHoverTo = clWhite
        ControlLook.FixedGradientDownFrom = clGray
        ControlLook.FixedGradientDownTo = clSilver
        ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
        ControlLook.DropDownHeader.Font.Color = clWindowText
        ControlLook.DropDownHeader.Font.Height = -11
        ControlLook.DropDownHeader.Font.Name = 'Tahoma'
        ControlLook.DropDownHeader.Font.Style = []
        ControlLook.DropDownHeader.Visible = True
        ControlLook.DropDownHeader.Buttons = <>
        ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
        ControlLook.DropDownFooter.Font.Color = clWindowText
        ControlLook.DropDownFooter.Font.Height = -11
        ControlLook.DropDownFooter.Font.Name = 'Tahoma'
        ControlLook.DropDownFooter.Font.Style = []
        ControlLook.DropDownFooter.Visible = True
        ControlLook.DropDownFooter.Buttons = <>
        EnableHTML = False
        EnableWheel = False
        EnhRowColMove = False
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'Tahoma'
        FilterDropDown.Font.Style = []
        FilterDropDown.TextChecked = 'Checked'
        FilterDropDown.TextUnChecked = 'Unchecked'
        FilterDropDownClear = '(All)'
        FilterEdit.TypeNames.Strings = (
          'Starts with'
          'Ends with'
          'Contains'
          'Not contains'
          'Equal'
          'Not equal'
          'Larger than'
          'Smaller than'
          'Clear')
        FixedColWidth = 268
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'Tahoma'
        FixedFont.Style = [fsBold]
        FloatFormat = '%.2f'
        HoverButtons.Buttons = <>
        HoverButtons.Position = hbLeftFromColumnLeft
        HTMLSettings.ImageFolder = 'images'
        HTMLSettings.ImageBaseName = 'img'
        IntelliPan = ipNone
        IntelliZoom = False
        MouseActions.AutoSizeColOnDblClick = False
        MouseActions.WheelIncrement = 1
        Navigation.AdvanceOnEnterLoop = False
        Navigation.AdvanceAutoEdit = False
        Navigation.AdvanceSkipReadOnlyCells = False
        Navigation.AutoComboSelect = False
        Navigation.AllowCtrlEnter = False
        Navigation.AllowClipboardRowGrow = False
        Navigation.AllowClipboardColGrow = False
        Navigation.EditSelectAll = False
        Navigation.ComboGetUpDown = False
        Navigation.CursorWalkAlwaysEdit = False
        Navigation.LeftRightRowSelect = False
        Navigation.CopyHTMLTagsToClipboard = False
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -11
        PrintSettings.Font.Name = 'Tahoma'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'Tahoma'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -11
        PrintSettings.HeaderFont.Name = 'Tahoma'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -11
        PrintSettings.FooterFont.Name = 'Tahoma'
        PrintSettings.FooterFont.Style = []
        PrintSettings.PageNumSep = '/'
        SearchFooter.FindNextCaption = 'Find &next'
        SearchFooter.FindPrevCaption = 'Find &previous'
        SearchFooter.Font.Charset = DEFAULT_CHARSET
        SearchFooter.Font.Color = clWindowText
        SearchFooter.Font.Height = -11
        SearchFooter.Font.Name = 'Tahoma'
        SearchFooter.Font.Style = []
        SearchFooter.HighLightCaption = 'Highlight'
        SearchFooter.HintClose = 'Close'
        SearchFooter.HintFindNext = 'Find next occurrence'
        SearchFooter.HintFindPrev = 'Find previous occurrence'
        SearchFooter.HintHighlight = 'Highlight occurrences'
        SearchFooter.MatchCaseCaption = 'Match case'
        ShowDesignHelper = False
        SortSettings.DefaultFormat = ssAutomatic
        Version = '7.9.0.3'
        ColWidths = (
          268
          268)
        RowHeights = (
          22)
      end
    end
    object PanelListMatches: SE_Panel
      Left = 685
      Top = 204
      Width = 685
      Height = 292
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Color = 8081721
      TabOrder = 5
      Visible = False
      object btnMatchesRefresh: TCnSpeedButton
        Left = 581
        Top = 251
        Width = 88
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnMatchesRefresh'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnMatchesRefreshClick
      end
      object btnMatchesListBack: TCnSpeedButton
        Left = 15
        Top = 251
        Width = 88
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnMatchesListBack'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnMatchesListBackClick
      end
      object SE_GridAllBrain: SE_Grid
        Left = 3
        Top = 0
        Width = 674
        Height = 245
        Cursor = crHandPoint
        MouseScrollRate = 1.000000000000000000
        MouseWheelInvert = False
        MouseWheelValue = 10
        MouseWheelZoom = False
        MousePan = True
        MouseScroll = False
        BackColor = 8081721
        AnimationInterval = 20
        GridInfoCell = False
        GridVisible = False
        GridColor = clSilver
        GridCellWidth = 40
        GridCellHeight = 30
        GridCellsX = 10
        GridCellsY = 4
        GridHexSmallWidth = 10
        CollisionDelay = 0
        ShowPerformance = False
        VirtualWidth = 212
        Virtualheight = 212
        Passive = True
        TabOrder = 0
        OnGridCellMouseDown = SE_GridAllBrainGridCellMouseDown
        CellBorder = CellBorderNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
      end
    end
    object PanelCorner: SE_Panel
      Left = 1034
      Top = 548
      Width = 316
      Height = 238
      Color = 8081721
      TabOrder = 6
      Visible = False
      object SE_GridFreeKick: SE_Grid
        Left = 11
        Top = 11
        Width = 286
        Height = 222
        MouseScrollRate = 1.000000000000000000
        MouseWheelInvert = False
        MouseWheelValue = 10
        MouseWheelZoom = False
        MousePan = False
        MouseScroll = False
        BackColor = 8081721
        AnimationInterval = 20
        GridInfoCell = False
        GridVisible = False
        GridColor = clSilver
        GridCellWidth = 40
        GridCellHeight = 30
        GridCellsX = 10
        GridCellsY = 4
        GridHexSmallWidth = 10
        CollisionDelay = 0
        ShowPerformance = False
        VirtualWidth = 212
        Virtualheight = 212
        Passive = True
        TabOrder = 0
        OnGridCellMouseDown = SE_GridFreeKickGridCellMouseDown
        CellBorder = CellBorderNone
        CellBorderColor = clGray
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
      end
    end
    object PanelLogin: SE_Panel
      Left = 14
      Top = 183
      Width = 169
      Height = 195
      BevelOuter = bvNone
      Color = 8081721
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 7
      object lbl_username: TLabel
        Left = 20
        Top = 21
        Width = 71
        Height = 19
        Caption = 'Username'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lbl_Password: TLabel
        Left = 16
        Top = 83
        Width = 67
        Height = 19
        Caption = 'Password'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object btnReplay: TCnSpeedButton
        Left = 21
        Top = 3
        Width = 70
        Height = 17
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'Replay'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        Visible = False
        OnClick = btnReplayClick
      end
      object btnLogin: TCnSpeedButton
        Left = 16
        Top = 145
        Width = 137
        Height = 32
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnLogin'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = BtnLoginClick
      end
      object lbl_ConnectionStatus: TLabel
        Left = 103
        Top = 6
        Width = 100
        Height = 13
        Caption = 'lbl_ConnectionStatus'
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Calibri'
        Font.Style = []
        ParentColor = False
        ParentFont = False
        Transparent = False
      end
      object Edit1: TEdit
        Left = 16
        Top = 46
        Width = 137
        Height = 21
        TabOrder = 0
        Text = 'test2'
      end
      object Edit2: TEdit
        Left = 17
        Top = 108
        Width = 137
        Height = 21
        PasswordChar = '*'
        TabOrder = 1
        Text = 'test2'
        OnKeyDown = Edit2KeyDown
      end
    end
    object PanelError: SE_Panel
      Left = 672
      Top = 140
      Width = 401
      Height = 121
      BevelOuter = bvNone
      Color = clRed
      ParentBackground = False
      TabOrder = 8
      Visible = False
      object lbl_Error: TLabel
        Left = 13
        Top = 11
        Width = 372
        Height = 66
        Alignment = taCenter
        AutoSize = False
        Caption = 'lbl_MoneyF'
        Color = clRed
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        Transparent = False
        WordWrap = True
      end
      object BtnErrorOK: TCnSpeedButton
        Left = 158
        Top = 80
        Width = 75
        Height = 28
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'OK'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnErrorOKClick
      end
    end
    object SE_Theater1: SE_Theater
      Left = 323
      Top = 153
      Width = 288
      Height = 217
      MouseScrollRate = 1.000000000000000000
      MouseWheelInvert = False
      MouseWheelValue = 10
      MouseWheelZoom = False
      MousePan = False
      MouseScroll = False
      BackColor = 8347711
      AnimationInterval = 20
      GridInfoCell = False
      GridVisible = False
      GridColor = clSilver
      GridCellWidth = 40
      GridCellHeight = 30
      GridCellsX = 10
      GridCellsY = 4
      GridHexSmallWidth = 10
      CollisionDelay = 0
      ShowPerformance = False
      OnBeforeVisibleRender = SE_Theater1BeforeVisibleRender
      OnSpriteMouseMove = SE_Theater1SpriteMouseMove
      OnSpriteMouseDown = SE_Theater1SpriteMouseDown
      OnSpriteMouseUp = SE_Theater1SpriteMouseUp
      OnTheaterMouseMove = SE_Theater1TheaterMouseMove
      VirtualWidth = 212
      Virtualheight = 212
      Visible = False
      TabOrder = 9
    end
    object PanelInfoPlayer0: SE_Panel
      Left = 25
      Top = 298
      Width = 317
      Height = 294
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 10
      Visible = False
      object se_lblSurname0: TLabel
        Left = 3
        Top = 8
        Width = 117
        Height = 16
        Caption = 'se_lblSurname0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -13
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object lbl_talent0: TLabel
        Left = 3
        Top = 201
        Width = 59
        Height = 13
        Caption = 'lbl_talent0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object lbl_descrTalent0: TLabel
        Left = 7
        Top = 220
        Width = 75
        Height = 13
        AutoSize = False
        Caption = 'lbl_descrTalent0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentFont = False
        Transparent = True
        WordWrap = True
      end
      object Portrait0: TCnSpeedButton
        Left = 0
        Top = 30
        Width = 74
        Height = 74
        ShadowColor = 8081721
        Color = 8081721
        DownColor = 8081721
        DownBold = False
        FlatBorder = True
        HotTrackBold = False
        HotTrackColor = 8081721
        LightColor = 8081721
        ModernBtnStyle = bsFlat
        Margin = 4
        Spacing = 0
      end
      object btnTalentBmp0: TCnSpeedButton
        Left = 16
        Top = 137
        Width = 32
        Height = 32
        ShadowColor = 8081721
        Color = 8081721
        DownColor = 8081721
        DownBold = False
        FlatBorder = True
        HotTrackBold = False
        HotTrackColor = 8081721
        LightColor = 8081721
        ModernBtnStyle = bsFlat
        Margin = 4
        Spacing = 0
      end
      object btnxp0: TCnSpeedButton
        Left = 103
        Top = 250
        Width = 47
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'XP'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        Visible = False
        OnClick = btnxp0Click
      end
      object btnsell0: TCnSpeedButton
        Left = 3
        Top = 109
        Width = 74
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnsell'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        Visible = False
        OnClick = btnsell0Click
      end
      object btnDismiss0: TCnSpeedButton
        Left = 3
        Top = 266
        Width = 74
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnDismiss'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        Visible = False
        OnClick = btnDismiss0Click
      end
      object SE_Grid0: SE_Grid
        Left = 88
        Top = 29
        Width = 212
        Height = 195
        MouseScrollRate = 1.000000000000000000
        MouseWheelInvert = False
        MouseWheelValue = 10
        MouseWheelZoom = False
        MousePan = False
        MouseScroll = False
        BackColor = 8081721
        AnimationInterval = 20
        GridInfoCell = False
        GridVisible = False
        GridColor = clSilver
        GridCellWidth = 40
        GridCellHeight = 30
        GridCellsX = 10
        GridCellsY = 4
        GridHexSmallWidth = 10
        CollisionDelay = 0
        ShowPerformance = False
        VirtualWidth = 212
        Virtualheight = 212
        Passive = True
        TabOrder = 0
        CellBorder = CellBorderNone
        CellBorderColor = clGray
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
      end
    end
    object PanelformationSE: SE_Panel
      Left = 3
      Top = 0
      Width = 966
      Height = 40
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 11
      Visible = False
      object lbl_MoneyF: TLabel
        Left = 316
        Top = 20
        Width = 84
        Height = 13
        AutoSize = False
        Caption = 'lbl_MoneyF'
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Calibri'
        Font.Style = []
        ParentColor = False
        ParentFont = False
        Transparent = False
      end
      object lbl_RankF: TLabel
        Left = 316
        Top = 6
        Width = 84
        Height = 13
        AutoSize = False
        Caption = 'lbl_RankF'
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Calibri'
        Font.Style = []
        ParentColor = False
        ParentFont = False
        Transparent = False
      end
      object lbl_TurnF: TLabel
        Left = 399
        Top = 6
        Width = 121
        Height = 13
        AutoSize = False
        Caption = 'lbl_TurnF'
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Calibri'
        Font.Style = []
        ParentColor = False
        ParentFont = False
        Transparent = False
      end
      object lbl_PointsF: TLabel
        Left = 398
        Top = 20
        Width = 67
        Height = 13
        AutoSize = False
        Caption = 'lbl_PointsF'
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Calibri'
        Font.Style = []
        ParentColor = False
        ParentFont = False
        Transparent = False
      end
      object lbl_MIF: TLabel
        Left = 471
        Top = 20
        Width = 49
        Height = 13
        AutoSize = False
        Caption = 'lbl_MIF'
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentColor = False
        ParentFont = False
        Transparent = False
      end
      object lbl_TeamName: TLabel
        Left = 3
        Top = 11
        Width = 302
        Height = 20
        AutoSize = False
        Caption = 'lbl_teamname'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -16
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object se_lblPlay: TCnSpeedButton
        Left = 613
        Top = 6
        Width = 115
        Height = 28
        Cursor = crHandPoint
        Color = clBtnFace
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'valid formatiom'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -13
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
      end
      object BtnFormationBack: TCnSpeedButton
        Left = 819
        Top = 6
        Width = 75
        Height = 28
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'back'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = BtnFormationBackClick
      end
      object BtnFormationReset: TCnSpeedButton
        Left = 738
        Top = 6
        Width = 75
        Height = 28
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'reset'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = BtnFormationResetClick
      end
      object BtnFormationUniform: TCnSpeedButton
        Left = 533
        Top = 6
        Width = 75
        Height = 28
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'uniform'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = BtnFormationUniformClick
      end
    end
    object PanelInfoplayer1: SE_Panel
      Left = 329
      Top = 457
      Width = 317
      Height = 294
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 12
      Visible = False
      object se_lblSurname1: TLabel
        Left = 3
        Top = 8
        Width = 117
        Height = 16
        Caption = 'se_lblSurname1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -13
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object lbl_talent1: TLabel
        Left = 46
        Top = 231
        Width = 59
        Height = 13
        Caption = 'lbl_talent1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object lbl_descrtalent1: TLabel
        Left = 28
        Top = 252
        Width = 75
        Height = 13
        AutoSize = False
        Caption = 'lbl_descrTalent1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentFont = False
        Transparent = True
        WordWrap = True
      end
      object Portrait1: TCnSpeedButton
        Left = 8
        Top = 38
        Width = 74
        Height = 74
        ShadowColor = 8081721
        Color = 8081721
        DownColor = 8081721
        DownBold = False
        FlatBorder = True
        HotTrackBold = False
        HotTrackColor = 8081721
        LightColor = 8081721
        ModernBtnStyle = bsFlat
        Margin = 4
        Spacing = 0
      end
      object btnTalentBmp1: TCnSpeedButton
        Left = 24
        Top = 145
        Width = 32
        Height = 32
        ShadowColor = 8081721
        Color = 8081721
        DownColor = 8081721
        DownBold = False
        FlatBorder = True
        HotTrackBold = False
        HotTrackColor = 8081721
        LightColor = 8081721
        ModernBtnStyle = bsFlat
        Margin = 4
        Spacing = 0
      end
      object SE_Grid1: SE_Grid
        Left = 88
        Top = 30
        Width = 212
        Height = 195
        MouseScrollRate = 1.000000000000000000
        MouseWheelInvert = False
        MouseWheelValue = 10
        MouseWheelZoom = False
        MousePan = False
        MouseScroll = False
        BackColor = 8081721
        AnimationInterval = 20
        GridInfoCell = False
        GridVisible = False
        GridColor = clSilver
        GridCellWidth = 40
        GridCellHeight = 30
        GridCellsX = 10
        GridCellsY = 4
        GridHexSmallWidth = 10
        CollisionDelay = 0
        ShowPerformance = False
        VirtualWidth = 212
        Virtualheight = 212
        Passive = True
        TabOrder = 0
        CellBorder = CellBorderNone
        CellBorderColor = clGray
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
      end
    end
    object PanelSkill: SE_Panel
      Left = 768
      Top = 380
      Width = 260
      Height = 201
      BevelOuter = bvNone
      Color = 16744576
      ParentBackground = False
      TabOrder = 13
      Visible = False
      object SE_GridSkill: SE_Grid
        Left = 28
        Top = 14
        Width = 212
        Height = 107
        Cursor = crHandPoint
        MouseScrollRate = 1.000000000000000000
        MouseWheelInvert = False
        MouseWheelValue = 10
        MouseWheelZoom = False
        MousePan = False
        MouseScroll = False
        BackColor = 8081721
        AnimationInterval = 20
        GridInfoCell = False
        GridVisible = False
        GridColor = clSilver
        GridCellWidth = 40
        GridCellHeight = 30
        GridCellsX = 10
        GridCellsY = 4
        GridHexSmallWidth = 10
        CollisionDelay = 0
        ShowPerformance = False
        VirtualWidth = 212
        Virtualheight = 212
        Passive = True
        TabOrder = 0
        OnGridCellMouseDown = SE_GridSkillGridCellMouseDown
        OnGridCellMouseMove = SE_GridSkillGridCellMouseMove
        CellBorder = CellBorderNone
        CellBorderColor = clGray
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
      end
    end
    object PanelXPplayer0: SE_Panel
      Left = 28
      Top = 559
      Width = 317
      Height = 290
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 14
      Visible = False
      object btnxpBack0: TCnSpeedButton
        Left = 267
        Top = 6
        Width = 47
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'Back'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnxpBack0Click
      end
      object SE_GridXP0: SE_Grid
        Left = 43
        Top = 39
        Width = 212
        Height = 195
        MouseScrollRate = 1.000000000000000000
        MouseWheelInvert = False
        MouseWheelValue = 10
        MouseWheelZoom = False
        MousePan = True
        MouseScroll = False
        BackColor = 8081721
        AnimationInterval = 20
        GridInfoCell = False
        GridVisible = False
        GridColor = clSilver
        GridCellWidth = 40
        GridCellHeight = 30
        GridCellsX = 10
        GridCellsY = 4
        GridHexSmallWidth = 10
        CollisionDelay = 0
        ShowPerformance = False
        VirtualWidth = 212
        Virtualheight = 212
        Passive = True
        TabOrder = 0
        OnGridCellMouseDown = SE_GridXP0GridCellMouseDown
        OnGridCellMouseMove = SE_GridXP0GridCellMouseMove
        CellBorder = CellBorderNone
        CellBorderColor = clGray
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
      end
    end
    object PanelUniform: SE_Panel
      Left = 652
      Top = 587
      Width = 317
      Height = 223
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 15
      Visible = False
      object btnUniformBack: TCnSpeedButton
        Left = 265
        Top = 5
        Width = 47
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'Back'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnUniformBackClick
      end
      object UniformPortrait: TCnSpeedButton
        Left = 113
        Top = 53
        Width = 74
        Height = 92
        Cursor = crHandPoint
        AllowAllUp = True
        ShadowColor = 8081721
        Color = 8081721
        DownBold = False
        FlatBorder = True
        HotTrackBold = False
        LightColor = 8081721
        ModernBtnStyle = bsFlat
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = Btn_UniformHomeClick
      end
      object btn_UniformHome: TCnSpeedButton
        Left = 113
        Top = 15
        Width = 104
        Height = 17
        Color = 8081721
        DownColor = clBlue
        DownBold = True
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 1
        Down = True
        Caption = 'btn_UniformHome'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Margin = 4
        ParentFont = False
        OnClick = Btn_UniformHomeClick
      end
      object btn_UniformAway: TCnSpeedButton
        Left = 113
        Top = 34
        Width = 104
        Height = 17
        Color = 8081721
        DownColor = clBlue
        DownBold = True
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 1
        Caption = 'btn_UniformAway'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Margin = 4
        ParentFont = False
        OnClick = Btn_UniformAwayClick
      end
      object ck_Jersey1: TCnSpeedButton
        Left = 220
        Top = 140
        Width = 49
        Height = 15
        Cursor = crHandPoint
        Color = 8081721
        DownColor = clBlue
        DownBold = True
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 2
        Down = True
        Caption = 'maglia'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Margin = 4
        ParentFont = False
      end
      object ck_Shorts: TCnSpeedButton
        Left = 121
        Top = 157
        Width = 76
        Height = 15
        Cursor = crHandPoint
        Color = 8081721
        DownColor = clBlue
        DownBold = True
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 2
        Caption = 'pantaloncini'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Margin = 4
        ParentFont = False
      end
      object ck_Socks1: TCnSpeedButton
        Left = 20
        Top = 119
        Width = 65
        Height = 15
        Cursor = crHandPoint
        Color = 8081721
        DownColor = clBlue
        DownBold = True
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 2
        Caption = 'calzettoni'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Margin = 4
        ParentFont = False
      end
      object ck_Jersey2: TCnSpeedButton
        Left = 156
        Top = 140
        Width = 49
        Height = 15
        Cursor = crHandPoint
        Color = 8081721
        DownColor = clBlue
        DownBold = True
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 2
        Caption = 'maglia'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Margin = 4
        ParentFont = False
      end
      object ck_Socks2: TCnSpeedButton
        Left = 73
        Top = 140
        Width = 65
        Height = 15
        Cursor = crHandPoint
        Color = 8081721
        DownColor = clBlue
        DownBold = True
        FlatBorder = False
        HotTrackBold = False
        GroupIndex = 2
        Caption = 'calzettoni'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Margin = 4
        ParentFont = False
      end
      object se_gridColors: TAdvStringGrid
        Left = 3
        Top = 181
        Width = 289
        Height = 31
        Cursor = crHandPoint
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Color = 8081721
        ColCount = 13
        Ctl3D = False
        DefaultRowHeight = 16
        DrawingStyle = gdsClassic
        FixedCols = 0
        RowCount = 1
        FixedRows = 0
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentCtl3D = False
        ParentFont = False
        ScrollBars = ssNone
        TabOrder = 0
        GridLineColor = 8081721
        HoverRowCells = [hcNormal, hcSelected]
        OnClickCell = se_gridColorsClickCell
        ActiveCellFont.Charset = DEFAULT_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Tahoma'
        ActiveCellFont.Style = [fsBold]
        ControlLook.FixedGradientHoverFrom = clGray
        ControlLook.FixedGradientHoverTo = clWhite
        ControlLook.FixedGradientDownFrom = clGray
        ControlLook.FixedGradientDownTo = clSilver
        ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
        ControlLook.DropDownHeader.Font.Color = clWindowText
        ControlLook.DropDownHeader.Font.Height = -11
        ControlLook.DropDownHeader.Font.Name = 'Tahoma'
        ControlLook.DropDownHeader.Font.Style = []
        ControlLook.DropDownHeader.Visible = True
        ControlLook.DropDownHeader.Buttons = <>
        ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
        ControlLook.DropDownFooter.Font.Color = clWindowText
        ControlLook.DropDownFooter.Font.Height = -11
        ControlLook.DropDownFooter.Font.Name = 'Tahoma'
        ControlLook.DropDownFooter.Font.Style = []
        ControlLook.DropDownFooter.Visible = True
        ControlLook.DropDownFooter.Buttons = <>
        EnableWheel = False
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'Tahoma'
        FilterDropDown.Font.Style = []
        FilterDropDown.TextChecked = 'Checked'
        FilterDropDown.TextUnChecked = 'Unchecked'
        FilterDropDownClear = '(All)'
        FilterEdit.TypeNames.Strings = (
          'Starts with'
          'Ends with'
          'Contains'
          'Not contains'
          'Equal'
          'Not equal'
          'Larger than'
          'Smaller than'
          'Clear')
        FixedRowHeight = 16
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'Tahoma'
        FixedFont.Style = [fsBold]
        Flat = True
        FloatFormat = '%.2f'
        HoverButtons.Buttons = <>
        HoverButtons.Position = hbLeftFromColumnLeft
        HTMLSettings.ImageFolder = 'images'
        HTMLSettings.ImageBaseName = 'img'
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -11
        PrintSettings.Font.Name = 'Tahoma'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'Tahoma'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -11
        PrintSettings.HeaderFont.Name = 'Tahoma'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -11
        PrintSettings.FooterFont.Name = 'Tahoma'
        PrintSettings.FooterFont.Style = []
        PrintSettings.PageNumSep = '/'
        SearchFooter.FindNextCaption = 'Find &next'
        SearchFooter.FindPrevCaption = 'Find &previous'
        SearchFooter.Font.Charset = DEFAULT_CHARSET
        SearchFooter.Font.Color = clWindowText
        SearchFooter.Font.Height = -11
        SearchFooter.Font.Name = 'Tahoma'
        SearchFooter.Font.Style = []
        SearchFooter.HighLightCaption = 'Highlight'
        SearchFooter.HintClose = 'Close'
        SearchFooter.HintFindNext = 'Find next occurrence'
        SearchFooter.HintFindPrev = 'Find previous occurrence'
        SearchFooter.HintHighlight = 'Highlight occurrences'
        SearchFooter.MatchCaseCaption = 'Match case'
        ShowSelection = False
        SortSettings.DefaultFormat = ssAutomatic
        Version = '7.9.0.3'
        ColWidths = (
          64
          64
          64
          64
          64
          64
          64
          64
          64
          64
          64
          64
          64)
        RowHeights = (
          16)
      end
    end
    object PanelMarket: SE_Panel
      Left = 725
      Top = 180
      Width = 588
      Height = 292
      BevelOuter = bvNone
      Color = 8081721
      TabOrder = 16
      Visible = False
      object se_lblmaxvalue: TLabel
        Left = 255
        Top = 253
        Width = 82
        Height = 13
        AutoSize = False
        Caption = 'se_lblmaxvalue'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentFont = False
        Transparent = True
        WordWrap = True
      end
      object btnMarketBack: TCnSpeedButton
        Left = 3
        Top = 267
        Width = 88
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'Back'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnMarketBackClick
      end
      object btnMarketRefresh: TCnSpeedButton
        Left = 352
        Top = 266
        Width = 88
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'btnMarketRefresh'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnMarketRefreshClick
      end
      object advMarket: TAdvStringGrid
        Left = 14
        Top = 8
        Width = 559
        Height = 239
        Cursor = crHandPoint
        TabStop = False
        BorderStyle = bsNone
        Color = 8081721
        ColCount = 13
        DefaultColWidth = 330
        DrawingStyle = gdsClassic
        FixedCols = 0
        RowCount = 1
        FixedRows = 0
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -13
        Font.Name = 'Calibri'
        Font.Style = []
        GridLineWidth = 0
        Options = [goVertLine]
        ParentFont = False
        ParentShowHint = False
        ScrollBars = ssNone
        ShowHint = False
        TabOrder = 0
        HoverRowColor = clBlue
        HoverRowColorTo = clBlue
        HoverRowCells = [hcNormal, hcSelected]
        OnClickCell = advMarketClickCell
        HTMLHint = True
        ActiveCellFont.Charset = ANSI_CHARSET
        ActiveCellFont.Color = clWindowText
        ActiveCellFont.Height = -11
        ActiveCellFont.Name = 'Calibri'
        ActiveCellFont.Style = [fsBold]
        ActiveCellColor = 144
        ControlLook.FixedGradientHoverFrom = clGray
        ControlLook.FixedGradientHoverTo = clWhite
        ControlLook.FixedGradientDownFrom = clGray
        ControlLook.FixedGradientDownTo = clSilver
        ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
        ControlLook.DropDownHeader.Font.Color = clWindowText
        ControlLook.DropDownHeader.Font.Height = -11
        ControlLook.DropDownHeader.Font.Name = 'Tahoma'
        ControlLook.DropDownHeader.Font.Style = []
        ControlLook.DropDownHeader.Visible = True
        ControlLook.DropDownHeader.Buttons = <>
        ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
        ControlLook.DropDownFooter.Font.Color = clWindowText
        ControlLook.DropDownFooter.Font.Height = -11
        ControlLook.DropDownFooter.Font.Name = 'Tahoma'
        ControlLook.DropDownFooter.Font.Style = []
        ControlLook.DropDownFooter.Visible = True
        ControlLook.DropDownFooter.Buttons = <>
        EnhRowColMove = False
        Filter = <>
        FilterDropDown.Font.Charset = DEFAULT_CHARSET
        FilterDropDown.Font.Color = clWindowText
        FilterDropDown.Font.Height = -11
        FilterDropDown.Font.Name = 'Tahoma'
        FilterDropDown.Font.Style = []
        FilterDropDown.TextChecked = 'Checked'
        FilterDropDown.TextUnChecked = 'Unchecked'
        FilterDropDownClear = '(All)'
        FilterEdit.TypeNames.Strings = (
          'Starts with'
          'Ends with'
          'Contains'
          'Not contains'
          'Equal'
          'Not equal'
          'Larger than'
          'Smaller than'
          'Clear')
        FixedColWidth = 330
        FixedRowHeight = 22
        FixedFont.Charset = DEFAULT_CHARSET
        FixedFont.Color = clWindowText
        FixedFont.Height = -11
        FixedFont.Name = 'Tahoma'
        FixedFont.Style = [fsBold]
        FloatFormat = '%.2f'
        HoverButtons.Buttons = <>
        HoverButtons.Position = hbLeftFromColumnLeft
        HTMLSettings.ImageFolder = 'images'
        HTMLSettings.ImageBaseName = 'img'
        IntelliPan = ipNone
        IntelliZoom = False
        MouseActions.AutoSizeColOnDblClick = False
        Navigation.AdvanceOnEnterLoop = False
        Navigation.AdvanceAutoEdit = False
        Navigation.AdvanceSkipReadOnlyCells = False
        Navigation.AutoComboSelect = False
        Navigation.AllowCtrlEnter = False
        Navigation.AllowClipboardRowGrow = False
        Navigation.AllowClipboardColGrow = False
        Navigation.EditSelectAll = False
        Navigation.ComboGetUpDown = False
        Navigation.CursorWalkAlwaysEdit = False
        Navigation.LeftRightRowSelect = False
        Navigation.CopyHTMLTagsToClipboard = False
        PrintSettings.DateFormat = 'dd/mm/yyyy'
        PrintSettings.Font.Charset = DEFAULT_CHARSET
        PrintSettings.Font.Color = clWindowText
        PrintSettings.Font.Height = -11
        PrintSettings.Font.Name = 'Tahoma'
        PrintSettings.Font.Style = []
        PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
        PrintSettings.FixedFont.Color = clWindowText
        PrintSettings.FixedFont.Height = -11
        PrintSettings.FixedFont.Name = 'Tahoma'
        PrintSettings.FixedFont.Style = []
        PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
        PrintSettings.HeaderFont.Color = clWindowText
        PrintSettings.HeaderFont.Height = -11
        PrintSettings.HeaderFont.Name = 'Tahoma'
        PrintSettings.HeaderFont.Style = []
        PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
        PrintSettings.FooterFont.Color = clWindowText
        PrintSettings.FooterFont.Height = -11
        PrintSettings.FooterFont.Name = 'Tahoma'
        PrintSettings.FooterFont.Style = []
        PrintSettings.PageNumSep = '/'
        SearchFooter.FindNextCaption = 'Find &next'
        SearchFooter.FindPrevCaption = 'Find &previous'
        SearchFooter.Font.Charset = DEFAULT_CHARSET
        SearchFooter.Font.Color = clWindowText
        SearchFooter.Font.Height = -11
        SearchFooter.Font.Name = 'Tahoma'
        SearchFooter.Font.Style = []
        SearchFooter.HighLightCaption = 'Highlight'
        SearchFooter.HintClose = 'Close'
        SearchFooter.HintFindNext = 'Find next occurrence'
        SearchFooter.HintFindPrev = 'Find previous occurrence'
        SearchFooter.HintHighlight = 'Highlight occurrences'
        SearchFooter.MatchCaseCaption = 'Match case'
        ShowSelection = False
        ShowDesignHelper = False
        SortSettings.DefaultFormat = ssAutomatic
        Version = '7.9.0.3'
        ColWidths = (
          330
          330
          330
          330
          330
          330
          330
          330
          330
          330
          330
          330
          330)
        RowHeights = (
          22)
      end
      object edtsearchprice: TEdit
        Left = 239
        Top = 266
        Width = 109
        Height = 22
        Alignment = taCenter
        AutoSize = False
        Color = 8081721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
      end
    end
    object PanelDismiss: SE_Panel
      Left = 189
      Top = 185
      Width = 116
      Height = 58
      Color = 8081721
      TabOrder = 17
      Visible = False
      object lbl_ConfirmDismiss: TLabel
        Left = 3
        Top = 3
        Width = 110
        Height = 27
        AutoSize = False
        Caption = 'se_lbldescrtalent1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentFont = False
        Transparent = True
        WordWrap = True
      end
      object btnConfirmDismiss: TCnSpeedButton
        Left = 19
        Top = 33
        Width = 74
        Height = 22
        Cursor = crHandPoint
        Color = clGray
        DownBold = False
        FlatBorder = False
        HotTrackBold = False
        Caption = 'confirm'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4308735
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Margin = 4
        ParentFont = False
        OnClick = btnConfirmDismissClick
      end
    end
  end
  object DXSound1: TDXSound
    AutoInitialize = False
    Options = []
    Left = 832
    Top = 1056
  end
  object tcp: TWSocket
    LineLimit = 1024
    LineEnd = #13#10
    Proto = 'tcp'
    LocalAddr = '0.0.0.0'
    LocalAddr6 = '::'
    LocalPort = '0'
    SocksLevel = '5'
    ExclusiveAddr = False
    ComponentOptions = []
    OnDataAvailable = tcpDataAvailable
    OnSessionClosed = tcpSessionClosed
    OnSessionConnected = tcpSessionConnected
    SocketErrs = wsErrTech
    onException = tcpException
    Left = 359
    Top = 982
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 928
    Top = 832
  end
  object SE_field: SE_Engine
    PixelCollision = False
    IsoPriority = False
    Priority = 0
    Theater = SE_Theater1
    Left = 632
    Top = 944
  end
  object SE_players: SE_Engine
    PixelCollision = False
    IsoPriority = False
    Priority = 1
    Theater = SE_Theater1
    Left = 680
    Top = 944
  end
  object SE_ball: SE_Engine
    PixelCollision = False
    IsoPriority = False
    Priority = 2
    Theater = SE_Theater1
    OnSpriteDestinationReached = SE_ballSpriteDestinationReached
    Left = 720
    Top = 944
  end
  object SE_numbers: SE_Engine
    ClickSprites = False
    PixelCollision = False
    IsoPriority = False
    Priority = 3
    Theater = SE_Theater1
    Left = 768
    Top = 944
  end
  object SE_interface: SE_Engine
    ClickSprites = False
    PixelCollision = False
    IsoPriority = False
    Priority = 3
    Theater = SE_Theater1
    Left = 816
    Top = 944
  end
  object mainThread: SE_ThreadTimer
    Interval = 30
    KeepAlive = True
    OnTimer = mainThreadTimer
    Left = 768
    Top = 1016
  end
  object ThreadCurMove: SE_ThreadTimer
    Interval = 300
    KeepAlive = True
    OnTimer = ThreadCurMoveTimer
    Left = 824
    Top = 1016
  end
  object FolderDialog1: TFolderDialog
    Caption = 'Select Folder Replay'
    Title = 'Select Folder Replay'
    DialogX = 0
    DialogY = 0
    Version = '1.1.3.0'
    Left = 1424
    Top = 600
  end
  object DXSound2: TDXSound
    AutoInitialize = False
    Options = []
    Left = 872
    Top = 1056
  end
  object DXSound3: TDXSound
    AutoInitialize = False
    Options = []
    Left = 912
    Top = 1056
  end
  object DXSound4: TDXSound
    AutoInitialize = False
    Options = []
    Left = 952
    Top = 1056
  end
  object DXSound5: TDXSound
    AutoInitialize = False
    Options = []
    Left = 992
    Top = 1056
  end
  object DXSound6: TDXSound
    AutoInitialize = False
    Options = []
    Left = 1032
    Top = 1056
  end
  object DXSound7: TDXSound
    AutoInitialize = False
    Options = []
    Left = 1080
    Top = 1056
  end
  object DXSound8: TDXSound
    AutoInitialize = False
    Options = []
    Left = 1120
    Top = 1056
  end
  object DXSound9: TDXSound
    AutoInitialize = False
    Options = []
    Left = 1160
    Top = 1056
  end
  object DXSound10: TDXSound
    AutoInitialize = False
    Options = []
    Left = 1200
    Top = 1056
  end
end
