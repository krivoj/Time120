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
  object Label3: TLabel
    Left = 8
    Top = 306
    Width = 124
    Height = 13
    Caption = 'Queue Max Time (ms)'
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
  object btnKillAllBrain: TButton
    Left = 273
    Top = 431
    Width = 129
    Height = 25
    Caption = 'Kill all matches'
    TabOrder = 1
    OnClick = btnKillAllBrainClick
  end
  object btnStopAllBrain: TButton
    Left = 273
    Top = 400
    Width = 129
    Height = 25
    Caption = 'Stop all matches'
    TabOrder = 2
    OnClick = btnStopAllBrainClick
  end
  object btnStartAllBrain: TButton
    Left = 273
    Top = 369
    Width = 129
    Height = 25
    Caption = 'Start all matches'
    TabOrder = 3
    OnClick = btnStartAllBrainClick
  end
  object Button1: TButton
    Left = 408
    Top = 456
    Width = 121
    Height = 25
    Caption = 'create accounts test100'
    TabOrder = 4
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 408
    Top = 487
    Width = 121
    Height = 25
    Caption = 'create teams test100'
    TabOrder = 5
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 408
    Top = 518
    Width = 121
    Height = 25
    Caption = 'Update Uniforms'
    TabOrder = 6
    OnClick = Button3Click
  end
  object RadioButton1: TRadioButton
    Left = 370
    Top = 274
    Width = 113
    Height = 17
    Caption = 'AI Fixed '
    TabOrder = 7
    OnClick = RadioButton1Click
  end
  object RadioButton2: TRadioButton
    Left = 370
    Top = 300
    Width = 113
    Height = 17
    Caption = 'AI RandomRange'
    Checked = True
    TabOrder = 8
    TabStop = True
    OnClick = RadioButton2Click
  end
  object CheckBox2: TCheckBox
    Left = 8
    Top = 373
    Width = 97
    Height = 17
    Caption = 'Log all '
    TabOrder = 9
  end
  object SE_GridLiveMatches: SE_Grid
    Left = 8
    Top = 8
    Width = 1081
    Height = 225
    MouseScrollRate = 1.000000000000000000
    MouseWheelInvert = False
    MouseWheelValue = 10
    MouseWheelZoom = False
    MousePan = False
    MouseScroll = False
    BackColor = clNavy
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
    TabOrder = 10
    CellBorder = CellBorderNone
    CellBorderColor = clGray
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Verdana'
    Font.Style = []
  end
  object CheckBoxActiveMacthes: TCheckBox
    Left = 8
    Top = 260
    Width = 124
    Height = 17
    Caption = 'Show Active Matches'
    Checked = True
    State = cbChecked
    TabOrder = 11
  end
  object CheckBox1: TCheckBox
    Left = 8
    Top = 283
    Width = 124
    Height = 17
    Caption = 'Create Bots Active'
    TabOrder = 12
  end
  object Edit1: TEdit
    Left = 138
    Top = 279
    Width = 65
    Height = 21
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 13
    Text = '0'
  end
  object edit4: TEdit
    Left = 138
    Top = 303
    Width = 65
    Height = 21
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 14
    Text = '1000'
  end
  object Edit2: TEdit
    Left = 489
    Top = 274
    Width = 65
    Height = 21
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 15
    Text = '3000'
  end
  object Edit3: TEdit
    Left = 489
    Top = 296
    Width = 65
    Height = 21
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 16
    Text = '12000'
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
    Left = 208
    Top = 456
    Banner = ''
  end
  object QueueThread: SE_ThreadTimer
    Interval = 5000
    KeepAlive = True
    OnTimer = QueueThreadTimer
    Left = 48
    Top = 440
  end
  object MatchThread: SE_ThreadTimer
    Interval = 200
    OnTimer = MatchThreadTimer
    Left = 264
    Top = 472
  end
  object threadBot: SE_ThreadTimer
    Enabled = True
    Interval = 10000
    KeepAlive = True
    OnTimer = threadBotTimer
    Left = 136
    Top = 448
  end
end
