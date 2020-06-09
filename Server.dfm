object FormServer: TFormServer
  Left = 0
  Top = 0
  Caption = 'Time120 Server'
  ClientHeight = 653
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
    Width = 104
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
    Left = 225
    Top = 318
    Width = 129
    Height = 25
    Caption = 'Kill all matches'
    TabOrder = 1
    OnClick = btnKillAllBrainClick
  end
  object btnStopAllBrain: TButton
    Left = 225
    Top = 287
    Width = 129
    Height = 25
    Caption = 'Stop all matches'
    TabOrder = 2
    OnClick = btnStopAllBrainClick
  end
  object btnStartAllBrain: TButton
    Left = 225
    Top = 256
    Width = 129
    Height = 25
    Caption = 'Start all matches'
    TabOrder = 3
    OnClick = btnStartAllBrainClick
  end
  object Button1: TButton
    Left = 408
    Top = 431
    Width = 137
    Height = 25
    Caption = 'create 300 accounts test '
    TabOrder = 4
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 408
    Top = 462
    Width = 137
    Height = 25
    Caption = 'create 300 teams test'
    TabOrder = 5
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 408
    Top = 524
    Width = 137
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
    Top = 333
    Width = 97
    Height = 17
    Caption = 'Log all in'
    TabOrder = 9
    OnClick = CheckBox2Click
  end
  object CheckBoxActiveMacthes: TCheckBox
    Left = 8
    Top = 260
    Width = 124
    Height = 17
    Caption = 'Show Active Matches'
    Checked = True
    State = cbChecked
    TabOrder = 10
  end
  object CheckBox1: TCheckBox
    Left = 8
    Top = 283
    Width = 124
    Height = 17
    Caption = 'Create Bots Active'
    TabOrder = 11
  end
  object Edit1: TEdit
    Left = 138
    Top = 279
    Width = 65
    Height = 21
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 12
    Text = '0'
  end
  object edit4: TEdit
    Left = 138
    Top = 303
    Width = 65
    Height = 21
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 13
    Text = '1000'
  end
  object Edit2: TEdit
    Left = 489
    Top = 274
    Width = 65
    Height = 21
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 14
    Text = '3000'
  end
  object Edit3: TEdit
    Left = 489
    Top = 296
    Width = 65
    Height = 21
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 15
    Text = '12000'
  end
  object Panel1: TPanel
    Left = 201
    Top = 358
    Width = 185
    Height = 98
    TabOrder = 16
    object Button5: TButton
      Left = 8
      Top = 59
      Width = 121
      Height = 25
      Caption = 'register account'
      TabOrder = 0
      OnClick = Button5Click
    end
    object Edit5: TEdit
      Left = 16
      Top = 8
      Width = 113
      Height = 21
      TabOrder = 1
      Text = 'username'
    end
    object Edit6: TEdit
      Left = 16
      Top = 32
      Width = 113
      Height = 21
      TabOrder = 2
      Text = 'password'
    end
  end
  object Button6: TButton
    Left = 408
    Top = 375
    Width = 137
    Height = 25
    Caption = 'load from replay(lastmove)'
    TabOrder = 17
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 408
    Top = 555
    Width = 137
    Height = 25
    Caption = 'LevelUp Talent(FORCETALENT)'
    TabOrder = 18
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 408
    Top = 586
    Width = 137
    Height = 25
    Caption = 'LevelUp Talent 2 (FORCETALENT)'
    TabOrder = 19
    OnClick = Button8Click
  end
  object StringGrid1: TStringGrid
    Left = 8
    Top = 8
    Width = 1009
    Height = 233
    DefaultRowHeight = 18
    FixedCols = 0
    FixedRows = 0
    TabOrder = 20
  end
  object Button4: TButton
    Left = 233
    Top = 483
    Width = 121
    Height = 25
    Caption = 'Maintenance'
    TabOrder = 21
    OnClick = Button4Click
  end
  object Button9: TButton
    Left = 233
    Top = 514
    Width = 121
    Height = 25
    Caption = 'Pause All except'
    TabOrder = 22
    OnClick = Button9Click
  end
  object Edit7: TEdit
    Left = 233
    Top = 545
    Width = 65
    Height = 21
    Alignment = taCenter
    AutoSize = False
    NumbersOnly = True
    TabOrder = 23
    Text = '0'
  end
  object Edit8: TEdit
    Left = 304
    Top = 545
    Width = 65
    Height = 21
    Alignment = taCenter
    AutoSize = False
    NumbersOnly = True
    TabOrder = 24
    Text = '0'
  end
  object Button10: TButton
    Left = 73
    Top = 570
    Width = 121
    Height = 25
    Caption = 'Random Market Sell'
    TabOrder = 25
    OnClick = Button10Click
  end
  object ProgressBar1: TProgressBar
    Left = 408
    Top = 493
    Width = 137
    Height = 17
    TabOrder = 26
  end
  object Memo2: TMemo
    Left = 574
    Top = 585
    Width = 75
    Height = 33
    Lines.Strings = (
      '')
    TabOrder = 27
  end
  object Button11: TButton
    Left = 408
    Top = 620
    Width = 137
    Height = 25
    Caption = 'Attribute LvlUp'
    TabOrder = 28
    OnClick = Button11Click
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
    Left = 88
    Top = 384
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
    Left = 112
    Top = 496
  end
  object threadBot: SE_ThreadTimer
    Enabled = True
    Interval = 500
    KeepAlive = True
    OnTimer = threadBotTimer
    Left = 104
    Top = 432
  end
  object FolderDialog1: TFolderDialog
    Caption = 'Select Folder Replay'
    Title = 'Select Folder Replay'
    DialogX = 0
    DialogY = 0
    Version = '1.1.3.0'
    Left = 466
    Top = 337
  end
end
