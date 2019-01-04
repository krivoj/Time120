object FormServer: TFormServer
  Left = 0
  Top = 0
  Caption = 'Soccer Server'
  ClientHeight = 573
  ClientWidth = 1110
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 23
    Top = 536
    Width = 31
    Height = 13
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 211
    Top = 470
    Width = 86
    Height = 13
    Caption = 'max brain number'
  end
  object Label3: TLabel
    Left = 88
    Top = 275
    Width = 76
    Height = 13
    Caption = 'Time before bot'
  end
  object Memo1: TMemo
    Left = 574
    Top = 258
    Width = 528
    Height = 305
    Lines.Strings = (
      '')
    TabOrder = 0
  end
  object advLiveMatches: TAdvStringGrid
    Left = 23
    Top = 8
    Width = 1079
    Height = 244
    Cursor = crHandPoint
    TabStop = False
    Color = 8081721
    ColCount = 7
    DefaultColWidth = 100
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
    TabOrder = 1
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
    FixedColWidth = 100
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
      100
      100
      100
      100
      100
      100
      100)
    RowHeights = (
      22)
  end
  object btnKillAllBrain: TButton
    Left = 408
    Top = 400
    Width = 129
    Height = 25
    Caption = 'Kill all matches'
    TabOrder = 2
    OnClick = btnKillAllBrainClick
  end
  object btnStopAllBrain: TButton
    Left = 273
    Top = 400
    Width = 129
    Height = 25
    Caption = 'Stop all matches'
    TabOrder = 3
    OnClick = btnStopAllBrainClick
  end
  object btnStartAllBrain: TButton
    Left = 138
    Top = 400
    Width = 129
    Height = 25
    Caption = 'Start all matches'
    TabOrder = 4
    OnClick = btnStartAllBrainClick
  end
  object btnRefreshListGames: TButton
    Left = 8
    Top = 400
    Width = 129
    Height = 25
    Caption = 'Refresh Games'
    TabOrder = 5
    OnClick = btnRefreshListGamesClick
  end
  object Button1: TButton
    Left = 408
    Top = 456
    Width = 121
    Height = 25
    Caption = 'create accounts test100'
    TabOrder = 6
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 408
    Top = 487
    Width = 121
    Height = 25
    Caption = 'create teams test100'
    TabOrder = 7
    OnClick = Button2Click
  end
  object RzNumericEdit1: TRzNumericEdit
    Left = 208
    Top = 489
    Width = 89
    Height = 21
    TabOrder = 8
    DisplayFormat = ',0;(,0)'
  end
  object CheckBox1: TCheckBox
    Left = 208
    Top = 512
    Width = 89
    Height = 17
    Caption = 'active'
    TabOrder = 9
  end
  object Button3: TButton
    Left = 408
    Top = 518
    Width = 121
    Height = 25
    Caption = 'Update Uniforms'
    TabOrder = 10
    OnClick = Button3Click
  end
  object RzNumericEdit2: TRzNumericEdit
    Left = 489
    Top = 272
    Width = 65
    Height = 21
    TabOrder = 11
    DisplayFormat = '#'
    Value = 3000.000000000000000000
  end
  object RzNumericEdit3: TRzNumericEdit
    Left = 489
    Top = 299
    Width = 65
    Height = 21
    TabOrder = 12
    DisplayFormat = '#'
    Value = 12000.000000000000000000
  end
  object RadioButton1: TRadioButton
    Left = 370
    Top = 274
    Width = 113
    Height = 17
    Caption = 'AI Fixed '
    TabOrder = 13
  end
  object RadioButton2: TRadioButton
    Left = 370
    Top = 297
    Width = 113
    Height = 17
    Caption = 'AI RandomRange'
    Checked = True
    TabOrder = 14
    TabStop = True
  end
  object RzNumericEdit4: TRzNumericEdit
    Left = 183
    Top = 272
    Width = 65
    Height = 21
    TabOrder = 15
    DisplayFormat = '#'
    Value = 1000.000000000000000000
  end
  object CheckBox2: TCheckBox
    Left = 23
    Top = 491
    Width = 97
    Height = 17
    Caption = 'Log all '
    TabOrder = 16
  end
  object Tcpserver: TWSocketThrdServer
    LineLimit = 1024
    LineEnd = #13#10
    OnLineLimitExceeded = TcpserverLineLimitExceeded
    Proto = 'tcp'
    LocalAddr = '0.0.0.0'
    LocalAddr6 = '::'
    LocalPort = '0'
    SocksLevel = '5'
    ExclusiveAddr = False
    ComponentOptions = []
    OnDataAvailable = TcpserverDataAvailable
    OnError = TcpserverError
    OnBgException = TcpserverBgException
    OnSocksError = TcpserverSocksError
    SocketErrs = wsErrTech
    onException = TcpserverException
    OnClientDisconnect = TcpserverClientDisconnect
    OnClientConnect = TcpserverClientConnect
    MultiListenSockets = <>
    ClientsPerThread = 1
    OnThreadException = TcpserverThreadException
    Left = 184
    Top = 328
    Banner = ''
  end
  object QueueThread: SE_ThreadTimer
    Interval = 5000
    KeepAlive = True
    OnTimer = QueueThreadTimer
    Left = 32
    Top = 272
  end
  object MatchThread: SE_ThreadTimer
    Interval = 200
    OnTimer = MatchThreadTimer
    Left = 328
    Top = 272
  end
  object threadBot: SE_ThreadTimer
    Enabled = True
    Interval = 10000
    KeepAlive = True
    OnTimer = threadBotTimer
    Left = 104
    Top = 320
  end
end
