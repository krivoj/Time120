object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsNone
  Caption = 'Time120'
  ClientHeight = 1140
  ClientWidth = 1829
  Color = clBtnFace
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
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 1407
    Top = 15
    Width = 258
    Height = 900
    BevelOuter = bvNone
    TabOrder = 2
    Visible = False
    object Label1: TLabel
      Left = 187
      Top = 676
      Width = 61
      Height = 29
      Caption = 'F1-F2'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Memo1: TMemo
      Left = 0
      Top = 0
      Width = 252
      Height = 129
      Lines.Strings = (
        '')
      TabOrder = 0
    end
    object Memo3: TMemo
      Left = 0
      Top = 394
      Width = 252
      Height = 119
      Lines.Strings = (
        '')
      TabOrder = 1
    end
    object Button6: TButton
      Left = 0
      Top = 515
      Width = 75
      Height = 25
      Caption = 'set ball'
      TabOrder = 2
      OnClick = Button6Click
    end
    object Button2: TButton
      Left = 0
      Top = 631
      Width = 75
      Height = 25
      Caption = 'lstsoccer'
      TabOrder = 3
      OnClick = Button2Click
    end
    object Button7: TButton
      Left = 81
      Top = 577
      Width = 75
      Height = 25
      Caption = 'Show SubCells'
      TabOrder = 4
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 0
      Top = 577
      Width = 75
      Height = 25
      Caption = 'Rnd fatigue'
      TabOrder = 5
      OnClick = Button8Click
    end
    object Button10: TButton
      Left = 0
      Top = 608
      Width = 75
      Height = 25
      Caption = 'Test Corner'
      TabOrder = 6
      OnClick = Button10Click
    end
    object CheckBox1: TCheckBox
      Left = 81
      Top = 515
      Width = 113
      Height = 17
      Caption = 'Show Ids/Surname'
      TabOrder = 7
    end
    object MemoC: TMemo
      Left = 0
      Top = 269
      Width = 252
      Height = 122
      Lines.Strings = (
        '')
      TabOrder = 9
    end
    object CheckBoxAI0: TCheckBox
      Left = 0
      Top = 658
      Width = 87
      Height = 17
      Caption = 'AI0'
      Color = 16744448
      ParentColor = False
      TabOrder = 8
      OnClick = CheckBoxAI0Click
    end
    object CheckBoxAI1: TCheckBox
      Left = 0
      Top = 676
      Width = 87
      Height = 17
      Caption = 'AI1'
      TabOrder = 10
      OnClick = CheckBoxAI1Click
    end
    object Edit3: TEdit
      Left = 81
      Top = 534
      Width = 49
      Height = 21
      TabOrder = 11
    end
    object Memo2: TMemo
      Left = 0
      Top = 132
      Width = 252
      Height = 134
      Lines.Strings = (
        '')
      TabOrder = 12
    end
    object CheckBox2: TCheckBox
      Left = 81
      Top = 662
      Width = 113
      Height = 17
      Caption = 'Pause'
      TabOrder = 13
      OnClick = CheckBox2Click
    end
    object Button3: TButton
      Left = 213
      Top = 606
      Width = 38
      Height = 25
      Caption = 'load'
      TabOrder = 14
      OnClick = Button3Click
    end
    object CheckBox3: TCheckBox
      Left = 81
      Top = 630
      Width = 94
      Height = 17
      Caption = 'ThreadCurMove'
      TabOrder = 15
      OnClick = CheckBox3Click
    end
    object Button4: TButton
      Left = 213
      Top = 575
      Width = 38
      Height = 25
      Caption = 'think'
      TabOrder = 16
      OnClick = Button4Click
    end
    object CnSpinEdit1: TCnSpinEdit
      Left = 155
      Top = 608
      Width = 52
      Height = 22
      MaxValue = 255
      MinValue = 0
      TabOrder = 17
      Value = 0
    end
    object editN1: TEdit
      Left = 136
      Top = 534
      Width = 25
      Height = 21
      NumbersOnly = True
      TabOrder = 18
      Text = '0'
    end
    object EditN2: TEdit
      Left = 167
      Top = 534
      Width = 25
      Height = 21
      NumbersOnly = True
      TabOrder = 19
      Text = '0'
    end
    object Button5: TButton
      Left = 0
      Top = 699
      Width = 75
      Height = 25
      Caption = 'unlimited time'
      TabOrder = 20
      OnClick = Button5Click
    end
    object CheckBox4: TCheckBox
      Left = 9
      Top = 742
      Width = 94
      Height = 17
      Caption = 'tackle_failed'
      TabOrder = 21
      OnClick = CheckBox4Click
    end
    object CheckBox5: TCheckBox
      Left = 9
      Top = 765
      Width = 94
      Height = 17
      Caption = 'setfault'
      TabOrder = 22
      OnClick = CheckBox5Click
    end
    object CheckBox6: TCheckBox
      Left = 9
      Top = 788
      Width = 94
      Height = 17
      Caption = 'setRed'
      TabOrder = 23
      OnClick = CheckBox6Click
    end
    object CheckBox7: TCheckBox
      Left = 9
      Top = 811
      Width = 94
      Height = 17
      Caption = 'setAlwaysGol'
      TabOrder = 24
      OnClick = CheckBox7Click
    end
    object CheckBox8: TCheckBox
      Left = 9
      Top = 834
      Width = 104
      Height = 17
      Caption = 'setPosCroCorner'
      TabOrder = 25
      OnClick = CheckBox8Click
    end
    object CheckBox9: TCheckBox
      Left = 9
      Top = 857
      Width = 104
      Height = 17
      Caption = 'Buff 100%'
      TabOrder = 26
      OnClick = CheckBox9Click
    end
    object Button9: TButton
      Left = 192
      Top = 532
      Width = 75
      Height = 25
      Caption = 'set Turn'
      TabOrder = 27
      OnClick = Button9Click
    end
    object Button1: TButton
      Left = 81
      Top = 699
      Width = 120
      Height = 25
      Caption = 'Pve GetTotalMarket'
      TabOrder = 28
      OnClick = Button1Click
    end
    object Button11: TButton
      Left = 97
      Top = 738
      Width = 120
      Height = 25
      Caption = 'pveAllOtherthinkmarket'
      TabOrder = 29
      OnClick = Button11Click
    end
    object Button12: TButton
      Left = 144
      Top = 776
      Width = 75
      Height = 25
      Caption = 'test lifepspan'
      TabOrder = 30
      OnClick = Button12Click
    end
  end
  object PanelMain: SE_Panel
    Left = 32
    Top = 246
    Width = 210
    Height = 174
    BevelOuter = bvNone
    Color = 8081721
    DoubleBuffered = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Calibri'
    Font.Style = []
    ParentDoubleBuffered = False
    ParentFont = False
    TabOrder = 0
    object btnReplay: TCnSpeedButton
      Left = 11
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
    object btnSinglePlayer: TCnSpeedButton
      Left = 2
      Top = 24
      Width = 200
      Height = 32
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'Single Player'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = btnSinglePlayerClick
    end
    object btnMultiPlayer: TCnSpeedButton
      Left = 2
      Top = 62
      Width = 200
      Height = 32
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'MultiPlayer'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = btnMultiPlayerClick
    end
    object BtnExit: TCnSpeedButton
      Left = 2
      Top = 98
      Width = 200
      Height = 32
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'btnExit'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = BtnExitClick
    end
    object lbl_language: TLabel
      Left = 2
      Top = 136
      Width = 71
      Height = 19
      AutoSize = False
      Caption = 'language'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = []
      ParentFont = False
    end
    object ComboBox1: TComboBox
      Left = 79
      Top = 136
      Width = 123
      Height = 23
      AutoComplete = False
      Color = 8081721
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Calibri'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      TabStop = False
      OnCloseUp = ComboBox1CloseUp
      OnKeyDown = ComboBox1KeyDown
      OnKeyPress = ComboBox1KeyPress
    end
  end
  object SE_Theater1: SE_Theater
    Left = 8
    Top = 26
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
    OnAfterVisibleRender = SE_Theater1AfterVisibleRender
    OnSpriteMouseMove = SE_Theater1SpriteMouseMove
    OnSpriteMouseDown = SE_Theater1SpriteMouseDown
    OnSpriteMouseUp = SE_Theater1SpriteMouseUp
    OnTheaterMouseMove = SE_Theater1TheaterMouseMove
    OnTheaterMouseDown = SE_Theater1TheaterMouseDown
    OnTheaterMouseUp = SE_Theater1TheaterMouseUp
    VirtualWidth = 900
    Virtualheight = 1440
    OnMouseWheel = SE_Theater1MouseWheel
    TabOrder = 1
    OnMouseDown = SE_Theater1MouseDown
  end
  object PanelSell: SE_Panel
    Left = 701
    Top = 56
    Width = 164
    Height = 58
    BevelOuter = bvNone
    Color = 8081721
    TabOrder = 3
    Visible = False
    object btnConfirmSell: TCnSpeedButton
      Left = 3
      Top = 36
      Width = 74
      Height = 22
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'confirm'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = btnConfirmSellClick
    end
    object BtnBackSell: TCnSpeedButton
      Left = 83
      Top = 36
      Width = 74
      Height = 22
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'confirm'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = BtnBackSellClick
    end
    object edtSell: TEdit
      Left = 3
      Top = 3
      Width = 150
      Height = 27
      Alignment = taCenter
      Color = 8081721
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4308735
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
  object PanelDismiss: SE_Panel
    Left = 531
    Top = 56
    Width = 164
    Height = 58
    BevelOuter = bvNone
    Color = 8081721
    TabOrder = 5
    Visible = False
    object BtnConfirmDismiss: TCnSpeedButton
      Left = 3
      Top = 36
      Width = 74
      Height = 22
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'confirm'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = BtnConfirmDismissClick
    end
    object BtnBackDismiss: TCnSpeedButton
      Left = 83
      Top = 36
      Width = 74
      Height = 22
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'confirm'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = BtnBackDismissClick
    end
    object lbl_Dismiss: TLabel
      Left = 8
      Top = 0
      Width = 145
      Height = 30
      AutoSize = False
      Caption = 'lbl_Dismiss'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4308735
      Font.Height = -13
      Font.Name = 'Calibri'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
  object ToolSpin: TCnSpinEdit
    Left = 531
    Top = 843
    Width = 74
    Height = 29
    AutoSelect = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    MaxValue = 255
    MinValue = 0
    ParentFont = False
    TabOrder = 4
    Value = 0
    Visible = False
    OnChange = ToolSpinChange
    OnKeyPress = toolSpinKeyPress
  end
  object PanelBuy: SE_Panel
    Left = 383
    Top = 251
    Width = 418
    Height = 102
    BevelOuter = bvNone
    Color = 8081721
    TabOrder = 6
    Visible = False
    object btnConfirmBuy: TCnSpeedButton
      Left = 0
      Top = 76
      Width = 74
      Height = 22
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'confirm'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = btnConfirmBuyClick
    end
    object BtnBackBuy: TCnSpeedButton
      Left = 331
      Top = 76
      Width = 74
      Height = 22
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'confirm'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = BtnBackBuyClick
    end
    object lbl_ConfirmBuy: TLabel
      Left = 8
      Top = 0
      Width = 409
      Height = 57
      AutoSize = False
      Caption = 'lbl_ConfirmBuy'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4308735
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
  object PanelGameOver: SE_Panel
    Left = 261
    Top = 371
    Width = 500
    Height = 300
    BevelOuter = bvNone
    Color = 8081721
    ParentBackground = False
    TabOrder = 7
    Visible = False
    object lbl_Gameover1: TLabel
      Left = 13
      Top = 11
      Width = 372
      Height = 38
      Alignment = taCenter
      AutoSize = False
      Caption = 'lbl_Gameover1'
      Color = 8081721
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
    object btnGameOverOK: TCnSpeedButton
      Left = 166
      Top = 171
      Width = 75
      Height = 28
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'OK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
    end
    object lbl_GameOver2: TLabel
      Left = 13
      Top = 67
      Width = 372
      Height = 38
      Alignment = taCenter
      AutoSize = False
      Caption = 'lbl_Gameover2'
      Color = 8081721
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
    object lbl_GameOver3: TLabel
      Left = 188
      Top = 130
      Width = 196
      Height = 38
      AutoSize = False
      Caption = 'lbl_Gameover3'
      Color = 8081721
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = False
      WordWrap = True
    end
    object Image1: TImage
      Left = 138
      Top = 121
      Width = 44
      Height = 44
      Picture.Data = {
        07544269746D617086150000424D861500000000000036000000280000002900
        00002C000000010018000000000050150000E10E0000E10E0000000000000000
        000000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF000000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0029E78344D5DB35D6EA24D8E723D7EA24D7E929D8E74ACFF035DDAD38E37E
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF004DD5AF38D2F428D1FF12D4
        FF00DBFF00DAFF00D5FF06D3FF00D6FF00D9FF00DBFF04D6FF1ED3FF27D7FF46
        D3E000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF000000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0044DAA239CEFF0ED8FF00DAFF05D6FF00DCFF00DAFF
        00DBFF03DBFF03DCFF00DCFF01DBFF01DCFD00DDFC07D9FE02D7FF00DBFF20D3
        FF3BD5E400FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF000000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF002EDCB715D1FF00DBFF01DCFE0BD8FD0CDBFE07E0FF03E0FF05DFFF05
        DDFF05DCFE06DCFF06DDFF05E0FE03E1FC02DCFE01D8FD03DAFF00DAFF00D8FF
        30CBFF3ADEAA00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        000000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0025D8FF
        07D6FF00D9FF03DAFD02E0FB01E4FE09DEFF11CFFB07C7F905C0F603BCF402BA
        F204BBF405C0F706C6F70ACEFB05DAFD01E4FE05E1FB06DBFC00DAFF00DBFF05
        DAFF45D1E400FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF000000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0025D0FF00D8FF00DAFE05
        DBFE06DEFF10D9FF0ACAF800B9F600ACF600A8F400A8F200AAF201AAF305A8F5
        02A9F300A9F001ADF108B2F403C5F70AD6FB10DEFF01DDFF09DAFD02DAFF06D7
        FF40CCFF00FF0000FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF00
        00FF0000FF0000FF0000FF0000FF003BC6FF00DBFF01DBFE01DDFD06E0FF06CF
        F903B8EF00ACED01A8F402AAF800ACF700AEF700AFF600AEF502ACFA03ACF903
        ADF404AEF202AAF400A8F101B2EE07C8F80BDCFF04DFFE00DDFB00DBFE00D7FF
        47C9FF00FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000
        FF0000FF0000FF0029D5F400DCFF01DBFE05DDFF0EDDFF07C6F400ACEE00A7F2
        01AEF501AFF600B0F300B1F102AFF402ADF604ADF704ADF602AEF600AFF400B0
        F300B0F300B0F400AEF201A8F205B9F507D9FE01DFFF00DCFE00D9FF0CD6FF00
        FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000FF0000FF
        0037DAC306D5FF00DAFF01DEFF0CDCFF07BFF500A9EE02AAF703ABFA02AEF701
        AFF501AFF401AFF301B0F301AEF000AAEE00ACEE00B0F100B0F300AFF500B0F4
        01B0F303AEF605ABF801A7F201B8F108D9FE01DFFF02D9FE00DBFF12D4FF00FF
        0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000FF0000FF0017D2FF
        00DBFF04DBFD07E2FF05C6F400A9ED00AAF900AFF500B0F200B0F401AFF502AD
        F802ACF900AEF101BCF204C6F504C1F600B4F101AEF207ADF505ADF502AFF302
        AFF300B1F004AEF402A8F002BCEF08DCFE05DEFE02DAFE00DBFF40CBFF00FF00
        00FF0000FF0000FF000000FF0000FF0000FF0000FF0037D2FF00D9FF05DBFE05
        E2FF08CDF800ACEB04ACF601AEF600AFF400AFF501AFF501AEF600AFF400B0F4
        00ABEE06C4F605E3FF04DBFF02B6F200ABF603AEF503AEF501AEF501AFF501AF
        F501AFF402ADF600A6F204C1F704E0FF00DDFE06D9FF12D2FF00FF0000FF0000
        FF0000FF000000FF0000FF0000FF0000FF0010D6FF00D9FF01E1FD0CDCFE06B6
        EE00ABEF04ADF600B0F400AFF601AEF601AEF601AEF600ADF603ACF702A9F105
        C2F602E1FF01D9FD02B4F300ABF800AEF502AEF401AEF601AEF601AEF700AFF4
        01AEF501AAF800ADEE05D1FB01E2FE08DAFC00DCFF43CDFF00FF0000FF0000FF
        000000FF0000FF0000FF0000FF0002D6FF0ED6FE00E6FD04C9F701AAEF01B0F4
        02AFF400AFF600AEF601AEF601AEF601AEF601AFF802ABF500A5EB05C3F402E2
        FF02D8FD02B4F300ABF701AEF502AEF401AEF601AEF601AEF600AEF501AEF501
        AEF600AAED04BCF305E1FF04DEF800DBFF18D1FF00FF0000FF0000FF000000FF
        0000FF0000FF0026D2FB04D8FF09DCFD0CDBFB00B4F600A7F801B0F300B1F101
        AEF601AEF701AEF601AEF600ABF701B7F209D0FA04B8EF04C2F301E1FF03D9FD
        02B4F100ACF701AEF502AEF401AEF601AEF601AEF601AEF600AEF600AFF301AD
        F103ADF20AD0FB00E3FA04DAFF00D7FF35D6DC00FF0000FF000000FF0000FF00
        00FF001ECFFF00DEFF00E2FE0DCEFB01AAF802ABFA01AEF401AFF301AEF601AE
        F701AEF601AEF600AAF702B5F10DDEFF05DFFF01D7FA02DBFE01D7FD01B0F702
        A6FB00B0F400B0F301AEF701AEF601AEF601AEF601AEF600AFF402AFF502A7F3
        07C2F902E4FC06DAFC05D7FF19D9EF00FF0000FF000000FF0000FF0000FF0010
        D1FF00DCFF03E0FF02C5FA00A9F502AEF601AEF601AEF701AEF601AEF601AEF6
        01AEF601ADF601ACF604B9F803D6FE01DFFF01DAFC06D6FF03BAF601A6F003AA
        F103AFF500AEF701AEF601AEF601AEF601AEF601AEF601AEF600A9F503BAF804
        DFFB02DCFC00DCFF2BCFFF00FF0000FF000000FF0000FF002DE0AD04D7FF00DC
        FF04DFFF01BEF400A8F401ADF601AEF601AEF601AEF601AEF601AEF601AEF601
        AFF500ADF800A6F401A9EC04C9F701DEFF03D9FF03DFFC00CEF505B2F503AAF6
        00AEF601AEF601AEF601AEF601AEF601AEF601AEF601ABF603B3F303DAFB04DC
        FF00DBFF22D2FF00FF0000FF000000FF0000FF0047D0F400DAFF03DCFF05DEFE
        01BCF200A9F401ADF701AEF601AEF601AEF601AEF601AEF601AEF600ABF601B5
        F308CDFD01B6F103C1F203DEFF00D9FB01DBFD08E3FF03D9FF00B5F501AAF601
        AEF601AEF601AEF601AEF601AEF601AEF602ABF704AFF204D5FA07DBFF00D9FF
        14D5FF00FF0000FF000000FF0000FF0039D4E400D6FF04DCFF05DCFE01B8F002
        A8F502ADF701AEF601AEF601AEF601AEF601AEF601AEF600AAF701B4EE0ADEFD
        05DDFF00D5FB03DEFC03D7FA01B2F20ABEFC05DDFE00BEF401A9F601AEF601AE
        F601AEF601AEF601AEF600AEF603ABF704ACF304D3F908DCFF00D9FF10D5FF00
        FF0000FF000000FF0000FF004CD0F400D8FF04DBFF05DBFF01B8F102A8F802AD
        F701AEF601AEF601AEF601AEF601AEF601AEF601ADF700ADF206BEF509D5FD03
        DFFE00DEFB05DBFD03B5F501A1F101B3F301B4F601ADF701AEF601AEF601AEF6
        01AEF601AEF601AEF603ABF805ACF703D3FC05DCFF00DBFF14D4FF00FF0000FF
        000000FF0000FF0029E1AE03D6FF02DBFF04DEFF01BDF301A8F501ADF601AEF6
        01AEF601AEF601AEF601AEF601AEF601AEF602ADF600AAF000AFED04CCF906DB
        FF08D8FF06DCFE01CCF601B2EF01AAF401AEF701AEF601AEF601AEF601AEF601
        AEF601AEF601ABF704B0F503D8FB03DCFF00DBFF1FD2FF00FF0000FF000000FF
        0000FF0000FF000DD3FF00DDFE03E0FF03C2F600A8F201ADF601AEF601AEF601
        AEF601AEF601AEF601AEF601AEF602AFF502ADF600A6F107C0F607DDFF00D9FD
        00DEFC02E6FF03D8FF01B3F501ABF601AEF601AEF601AEF601AEF601AEF601AE
        F600AAF501B6F302DDFA02DCFD00DBFF2BD0FF00FF0000FF000000FF0000FF00
        00FF001BD1FF00DEFD03E1FE04CAFA00AAF301ADF701AEF601AEF601AEF601AE
        F601AEF601AEF601ADF600B0F201AFF200A8F406C1F803E2FE01D9F701BBF107
        C4FA08DDFD01BCF601A9F601AEF601AEF601AEF601AEF601AEF601AEF700A8F3
        02BFF702E2FC03DCFD00D9FF1AD8F300FF0000FF000000FF0000FF0000FF0019
        D9FA04D7FF06DEFD01D7FB01ACF500AAF900AFF501AFF502AEF501AFF501AFF6
        01ABF700ACF500AEF300ADF500A5F404C0F702E2FD02D8FB01B1F402A2F404B3
        F401B3F600ABF601ADF602AFF502AEF500AEF600B0F301AFF405A6F106C7F906
        E3FD08D9FE00D9FF2FD8DD00FF0000FF000000FF0000FF0000FF0023DDDD00D7
        FF04DBFD08E0FC02BDF700A8F302AEF600AEF500AFF400AEF501B0F401B1F301
        B1F101B2F001B1F301ABF004C3F402E1FF01D9FE01B8F301ABF301ACF001B2F0
        01B3F100AFF302AFF502AEF500AEF500AFF300ACEF04B1F208D9FE02DFFB00DB
        FF1CCEFF00FF0000FF0000FF000000FF0000FF0000FF0000FF0014D3FF00DAFF
        09E0FE02D4FB01AEEB01ACF401ADF800B0F400ABF501B3F309CFFC08D2FD08D0
        FD07D1FD07CFFD04D4FD00DCFD01DAFD04D2FE07CFFE07D1FE05D3FE0BD5FD08
        C2F800ACF103AFF600AEF501ADF700ABEE05C6F705E2FF00DDFB02D8FF2CD1FF
        00FF0000FF0000FF000000FF0000FF0000FF0000FF0036D1FF00DAFF08DAFF01
        DFFF03C1F200A7F105ABFB00B0F300A9F702B5F204E2FC01E5FF02E2FF01E4FD
        01E4FE02E1FF02DFFF00E0FE01E2FF01E3FF00E1FF00E4FE07E7FF08CDFA00AC
        EF03B0F500AEF501A7F701B5F407DCFF02DDFE01D9FF08D2FF00FF0000FF0000
        FF0000FF000000FF0000FF0000FF0000FF0000FF0016D1FF07D7FF00DFFE03DB
        FE00B7F102A9F303ADF802ABF500B5F100CCF902CBFB03CAFB00CCF801CCF801
        CAFA04C9FB03CAFB01CBF900CBFA00CAFB00CBF803CEFB03BEF600ADF102AEF7
        00ACF300ADEF08CFFC05E1FF01DDFE00D9FF38C6FF00FF0000FF0000FF0000FF
        000000FF0000FF0000FF0000FF0000FF0042CDFF00DAFF07D9FE06E0FF05D4FA
        00B0EE01A8F603AEF601AEF300ABF602AAF503ABF400ABF300ABF300ACF300AC
        F200ACF200ABF200ABF200ACF200ACF200ABF200ACF504ADFA02A8F700ABED05
        CCF606E2FF03DCFE03DAFF02DAFF00FF0000FF0000FF0000FF0000FF000000FF
        0000FF0000FF0000FF0000FF0000FF001CD5FF00DBFF04DAFE08DCFF0BD1FD00
        B3EE01A6F103AAFB01ACF701AEF601B0F401B0F301B0F301B0F301B0F301B0F3
        01B0F301B0F301B0F300B0F200B0F301AEF604A7F801AAF404CAF804DDFF00DC
        FE00D9FF00D7FF36D6EF00FF0000FF0000FF0000FF0000FF000000FF0000FF00
        00FF0000FF0000FF0000FF0000FF001BD2FF00DCFF03DAFE08DEFF06D8FC01BC
        F300A9EE01AAF101AEF600AFF502AFF301AFF302AFF302AFF301AFF301AFF302
        AFF302AFF301AEF400ADF300ACED01B6F108CFFD05DEFF00DDFC00DCFF00D7FF
        29D4F500FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0017D1FF00DDFF01DAFD05DEFF05DDFF05CCF8
        01B5F002A8F400A7F501ABF303ADF401ADF403ADF503ACF402ACF301ACF300AA
        F004A6F503ADF404C5F506DDFE03E0FD03DBFC00DBFC00D9FF3AC9FF00FF0000
        FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0023D0FF00DAFF02D7FF01DCFF05E2FE01DCFC01
        CBFB04B9F804B2F602B0F300AEF100ACF102ABF202ADF102B3F305BAF604C4FA
        06D5FE04E1FF00DFFF00DDFD05DBFF00D6FF2ED2FF00FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0024D8FF07D6FF00DBFF00DCFC04DDFC0AE0FE09DD
        FF0AD6FF06D3FB04D0F904CEF907CEFB08D2FC06D6FD06DCFF09DFFF04DFFE04
        DDFD00DAFE01D8FF0BD8FF3CD6E200FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF000000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0028CFFF03D5FF00DAFF05D8FF09D9FE00DFFE
        00E0FE00E1FE00E1FF02DFFF01DEFF00DEFD00DFFB06D8FF00D8FF00D9FF10D3
        FF2FCEFF00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF000000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0028D0FF0DD3FF00DBFF00DAFF00DBFF00
        DDFE00DBFF00DAFF00DCFF00DBFF00DCFF05D8FF22CEFF39CFFF00FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        000000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF004CCDF024D8ED28D4FF30CBFF28CD
        FF24CFFF2ECDFF2CD4FF38D2F134E0AB00FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF000000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF000000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF00
        00FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF
        0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000
        FF0000FF0000FF0000FF0000FF0000FF0000}
      Stretch = True
      Transparent = True
    end
  end
  object PanelLogin: SE_Panel
    Left = 824
    Top = 239
    Width = 210
    Height = 237
    BevelOuter = bvNone
    Color = 8081721
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 8
    Visible = False
    object Label2: TLabel
      Left = 4
      Top = 26
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
    object btnLogin: TCnSpeedButton
      Left = 1
      Top = 156
      Width = 200
      Height = 32
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'btnLogin'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = BtnLoginClick
    end
    object lbl_username: TLabel
      Left = 4
      Top = 26
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
      Left = 4
      Top = 88
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
    object lbl_ConnectionStatus: TLabel
      Left = 5
      Top = 7
      Width = 200
      Height = 13
      Alignment = taCenter
      AutoSize = False
      Caption = 'Server offline'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Calibri'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
    object btnMultiPlayerBAck: TCnSpeedButton
      Left = 1
      Top = 194
      Width = 200
      Height = 32
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'btnMultiPlayerBAck'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = btnMultiPlayerBAckClick
    end
    object Edit1: TEdit
      Left = 3
      Top = 51
      Width = 200
      Height = 21
      TabOrder = 0
      Text = 'test2'
    end
    object Edit2: TEdit
      Left = 3
      Top = 113
      Width = 200
      Height = 21
      PasswordChar = '*'
      TabOrder = 1
      Text = 'test2'
      OnKeyDown = Edit2KeyDown
    end
  end
  object PanelSinglePlayer: SE_Panel
    Left = 51
    Top = 426
    Width = 210
    Height = 127
    BevelOuter = bvNone
    Color = 8081721
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 9
    Visible = False
    object btnContinue: TCnSpeedButton
      Left = 2
      Top = 10
      Width = 200
      Height = 32
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'btnContinue'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = btnContinueClick
    end
    object btnRestart: TCnSpeedButton
      Left = 2
      Top = 48
      Width = 200
      Height = 32
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'btnRestart'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = btnRestartClick
    end
    object btnSinglePlayerBAck: TCnSpeedButton
      Left = 2
      Top = 86
      Width = 200
      Height = 32
      Cursor = crHandPoint
      Color = clGray
      DownBold = False
      FlatBorder = False
      HotTrackBold = False
      Caption = 'btnSinglePlayerBAck'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      Margin = 4
      ParentFont = False
      OnClick = btnSinglePlayerBAckClick
    end
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
  object SE_players: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 2
    Theater = SE_Theater1
    Left = 720
    Top = 888
  end
  object SE_ball: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 3
    Theater = SE_Theater1
    OnSpriteDestinationReached = SE_ballSpriteDestinationReached
    OnSpritePartialMove = SE_ballSpritePartialMove
    Left = 720
    Top = 944
  end
  object SE_numbers: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 4
    Theater = SE_Theater1
    Left = 776
    Top = 944
  end
  object SE_interface: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 4
    Theater = SE_Theater1
    Left = 840
    Top = 944
  end
  object mainThread: SE_ThreadTimer
    Interval = 30
    KeepAlive = True
    OnTimer = mainThreadTimer
    Left = 760
    Top = 1016
  end
  object ThreadCurrentIncMove: SE_ThreadTimer
    Interval = 300
    KeepAlive = True
    OnTimer = ThreadCurrentIncMoveTimer
    Left = 824
    Top = 1016
  end
  object FolderDialog1: TFolderDialog
    Caption = 'Select Folder Replay'
    Title = 'Select Folder Replay'
    DialogX = 0
    DialogY = 0
    Version = '1.1.3.0'
    Left = 1696
    Top = 592
  end
  object SE_FieldPoints: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = True
    IsoPriority = False
    Priority = 1
    Theater = SE_Theater1
    Left = 496
    Top = 944
  end
  object SE_BackGround: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 0
    Theater = SE_Theater1
    Left = 496
    Top = 752
  end
  object SE_FieldPointsReserve: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = True
    IsoPriority = False
    Priority = 1
    Theater = SE_Theater1
    Left = 496
    Top = 904
  end
  object SE_ShotCells: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 1
    Theater = SE_Theater1
    Left = 496
    Top = 1008
  end
  object SE_FieldPointsSpecial: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 1
    Theater = SE_Theater1
    Left = 496
    Top = 856
  end
  object SE_MainInterface: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 296
    Top = 816
  end
  object SE_PlayerDetails: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    Left = 376
    Top = 816
  end
  object SE_Aml: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 72
    Top = 776
  end
  object SE_Market: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 72
    Top = 840
  end
  object SE_Spectator: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 72
    Top = 904
  end
  object SE_Score: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 72
    Top = 968
  end
  object SE_Live: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    Left = 128
    Top = 904
  end
  object SE_CountryTeam: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 160
    Top = 712
  end
  object SE_MainStats: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 216
    Top = 816
  end
  object SE_Loading: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 10
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 296
    Top = 696
  end
  object SE_Skills: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 6
    Theater = SE_Theater1
    Left = 568
    Top = 808
  end
  object SE_Uniform: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    Left = 280
    Top = 944
  end
  object SE_TacticsSubs: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 176
    Top = 904
  end
  object SE_LifeSpan: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 280
    Top = 1040
  end
  object SE_FieldPointsOut: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 1
    Theater = SE_Theater1
    Left = 560
    Top = 904
  end
  object SE_Green: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 7
    Theater = SE_Theater1
    Left = 640
    Top = 808
  end
  object SE_RANK: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 296
    Top = 760
  end
  object SE_GameOver: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 11
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 376
    Top = 696
  end
  object SE_Standings: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 5
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 72
    Top = 720
  end
  object SE_YesNo: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 11
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 456
    Top = 696
  end
  object SE_PreMatch: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 10
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 184
    Top = 616
  end
  object SE_Help: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 10
    Theater = SE_Theater1
    Visible = False
    RenderBitmap = VisibleRender
    Left = 536
    Top = 704
  end
  object SE_Simulation: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 10
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 104
    Top = 616
  end
  object SE_InfoError: SE_Engine
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 11
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 608
    Top = 696
  end
  object SE_matchInfo: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 11
    Theater = SE_Theater1
    RenderBitmap = VisibleRender
    Left = 688
    Top = 696
  end
  object sfSaves: SE_SearchFiles
    SubDirectories = True
    OnValidateFile = sfSavesValidateFile
    Left = 848
    Top = 504
  end
  object SE_Circles: SE_Engine
    ClickSprites = False
    PixelCollision = False
    HiddenSpritesMouseMove = False
    IsoPriority = False
    Priority = 1
    Theater = SE_Theater1
    Left = 768
    Top = 888
  end
end
