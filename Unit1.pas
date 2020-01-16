unit Unit1;
{$DEFINE TOOLS}

      { TODO  : sistemare market grid}

      { TODO  : verificare suoni, sul rigore è mancata l'esultanza
            bug grafico probabile dopo espulsione non trova sprite perchè passato di lista. occorre accettare nil
            bug grafico dopo gol
            suono palo con 12 }
      { TODO : finire traduzioni DATA/EN}
      { TODO : tattiche deve mostrare solo i propri player. non si possono conoscere la tattiche avversarie }

      { TODO : standings. mutex request/snapshot db distinct worldteam e invio come icsSendfile, dinamyc selfposition, snapshot primi 100.
         standings valida solo dopo 20 gare e activity account
         guilds: stesso per guild del proprio tyeam
         chat: altro server in futuro come per gli account. utilizzo CnnAtext + edit1.text
        }

      // procedure importanti:
      //    procedure SE_GridSkillGridCellMouseDown  click sulla skill ---> input verso il server
      //    procedure tcpDataAvailable <--- input dal server
      //    procedure ClientLoadBrainMM  ( incMove: Byte ) Carica il brain arrivato dal server
      //    procedure Anim --> esegue realmente l'animazione

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Types, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, generics.collections, Strutils, Inifiles,math, FolderDialog,generics.defaults,
  Vcl.Grids, Vcl.ComCtrls,  Vcl.Menus, Vcl.Mask,
  Vcl.StdCtrls, Vcl.ExtCtrls, Winapi.MMSystem,    // Delphi libraries

  DSE_Random ,     // DSE Package
  DSE_PathPlanner,
  DSE_theater,
  DSE_ThreadTimer,
  dse_bitmap,
  dse_defs,
  DSE_misc,
  DSE_SearchFiles,
  DSE_GRID,
  DSE_Panel,

  SoccerBrainv3,   // il cuore del gioco, si occupa della singola partita

  CnButtons,CnSpin,CnAAFont, CnAACtrls, CnColorGrid, // CnVCLPack

  ZLIBEX,                             // delphizlib invio dati compressi tra server e client

  OverbyteIcsWndControl, OverbyteIcsWSocket   ;  // OverByteIcsWSocketE ics con modifica. vedi directory External.Packages\overbyteICS del progetto



const GCD_DEFAULT = 200;        // global cooldown, minimo 200 ms tra un input verso il server e l'altro ( anti-cheating )
const ScaleSprites = 40;        // riduzione generica di tutto gli sprite player
const ScaleSpritesFace = 30;        // riduzione face
const FieldCellW = 64;
const FieldCellH = 64;
const DEFAULT_SPEED_BALL = 4;
const DEFAULT_SPEED_PLAYER = 4;
const DEFAULT_SPEEDMAX_BALL = 7;
const BallZ0Y = 16;             // la palla sta più in basso, vicino ai piedi dello sprite player
const Ball0X = 3;               // la palla sta più avanti rispetto allo sprite player
const sprite1cell = 900;        // ms tempo che impiega un player a spostarsi di una cella
const ShowRollLifeSpan = 1600;  // ms tempo di comparsa dei roll
const ShowFaultLifeSpan = 1600; // ms notifica in caso di fallo
const msSplashTurn = 1600;
const STANDARD_MP_MS = 50;
const EndOfLine = 'ENDSOCCER';  // tutti i pacchetti Tcp tra server e client finiscono con questo marker
type TArray8192 = array [0..8191] of AnsiChar; // i buf[0..255] of  TArray8192 contengono il buffer Tcp in entrata

type TSpriteArrowDirection = record  // le frecce durante waitforSomething
  offset : TPoint;
  angle : single;
end;

// Schermate di gioco, es. ScreenWatchLive quando guardo una partita di altri giocatori.
type TGameScreen =(ScreenLogin, ScreenSelectCountry, ScreenSelectTeam, ScreenMain,
                  ScreenWaitingFormation, ScreenFormation,
                  ScreenWaitingLiveMatch, ScreenLiveMatch, ScreenTactics, ScreenSubs,
                  ScreenSelectLiveMatch, ScreenWaitingWatchLive, ScreenWatchLive,
                  ScreenMarket );

  type TMouseWaitFor = (WaitForNone, WaitForAuth, // in attesa di autenticazione login
  WaitForXY_ShortPass, WaitForXY_LoftedPass, WaitForXY_Crossing,
  WaitForXY_Move,WaitForXY_PowerShot , WaitForXY_PrecisionShot, WaitForXY_Dribbling,WaitFor_Corner, // in attesa di input di gioco
  WaitForXY_FKF1,  // chi batte la short.passing o lofted.pass
  WaitForXY_FKF2,  // chi batte il cross
  WaitForXY_FKA2,  // i 3 saltatori
  WaitForXY_FKD2,  // i 3 saltatori in difesa
  WaitForXY_FKF3,  // chi batte la punizione
  WaitForXY_FKD3,  // la barriera
  WaitForXY_FKF4,  // chi batte il rigore
  WaitForXY_CornerCOF ,  // chi batte il corner
  WaitForXY_CornerCOA ,  // i 3 coa ( attaccanti sul corner )
  WaitForXY_CornerCOD );  // i 3 coa ( difensori sul corner )

Type TAnimationScript = class // letta dal TForm1.mainThreadTimer. Produce l'animazione degli sprite.
  Ts: TstringList;              // contiene tsScript del server. è l'animazione già accaduta sul server e ora il client deve mostrarla con gli sprite
  Index : Integer;              // cicla per gli elementi di Ts
  WaitMovingPlayers: boolean;   // Aspetta che tutti i player siano fermi
  wait: integer;                // tempo di attesa prima di procedere al prossimo elemento di Ts
  memo: Tmemo;                  // utile per log
  Constructor Create;
  Destructor destroy;
  procedure Reset;
  procedure TsAdd ( v: string );
end;
type  TPointArray4 = array[0..3] of TPoint;

Type TFieldPoint = class
  Cell : TPoint;
  Pixel : TPoint;
end;


type
  TForm1 = class(TForm)
    PanelMain: SE_panel;
      btnFormation: TcnSpeedButton;
      btnMainPlay: TcnSpeedButton;
      btnWatchLive: TcnSpeedButton;
      btnMarket: TcnSpeedButton;
      btnStandings: TcnSpeedButton;
      btnExit: TcnSpeedButton;

    PanelBack: SE_Panel;
      SE_Theater1: SE_Theater;

    Panel1: TPanel;
      Memo1: TMemo;
      Memo2: TMemo;
      Memo3: TMemo;
      MemoC: TMemo;
      Button6: TButton;
      Button2: TButton;
      Button7: TButton;
      Button8: TButton;
      Button10: TButton;
      CheckBox1: TCheckBox;
      CheckBoxAI0: TCheckBox;
      CheckBoxAI1: TCheckBox;
      CheckBox2: TCheckBox;
      Button1: TButton;
      Edit3: TEdit;
      CheckBox3: TCheckBox;
      Button4: TButton;
      CnSpinEdit1: TCnSpinEdit;
      editN1: TEdit;
      EditN2: TEdit;

    PanelCombatLog: SE_panel;
      SE_GridDice: SE_Grid;

    PanelScore: SE_panel;
      btnSubs: TcnSpeedButton;
      btnTactics: TcnSpeedButton;
      lbl_Nick0: TCnAAScrollText;
      lbl_Nick1: TCnAAScrollText;
      lbl_score: TLabel;
      lbl_minute: TLabel;
    btnOverrideUniformWhite: TCnSpeedButton;
      ToolSpin: TCnSpinEdit;
      SE_GridTime: SE_Grid;
      btnWatchLiveExit: TcnSpeedButton;


    PanelCountryTeam: SE_panel;
      SE_GridCountryTeam: SE_Grid;
      btnSelCountryTeam: TcnSpeedButton;

    PanelListMatches: SE_panel;
      btnMatchesRefresh: TcnSpeedButton;
      btnMatchesListBack: TcnSpeedButton;
      SE_GridAllBrain: SE_Grid;

    PanelCorner: SE_panel;
      SE_GridFreeKick: SE_Grid;

    PanelLogin: SE_panel;
      lbl_username: TLabel;
      lbl_Password: TLabel;
      Edit1: TEdit;
      Edit2: TEdit;
      FolderDialog1: TFolderDialog;
      btnLogin: TcnSpeedButton;
      btnReplay: TcnSpeedButton;
      lbl_ConnectionStatus: TLabel;

    PanelInfoPlayer0: SE_Panel;
        SE_GridXP0: SE_Grid;
        SE_Grid0: SE_Grid;
        lbl_descrTalent01: TLabel;
        Portrait0: TCnSpeedButton;
        lbl_Surname0: TLabel;
        lbl_talent01: TLabel;
        btnTalentBmp01: TCnSpeedButton;
        lbl_talent02: TLabel;
        lbl_descrTalent02: TLabel;
        btnTalentBmp02: TCnSpeedButton;
    PanelDismiss: SE_panel;
        btnDismiss0: TcnSpeedButton;
        btnConfirmDismiss: TcnSpeedButton;
        lbl_ConfirmDismiss: TLabel;

      PanelSell: SE_panel;
        edtSell: TEdit;
        btnsell0: TcnSpeedButton;



    PanelXPplayer0: SE_panel;
      btnxp0: TcnSpeedButton;
      btnxpBack0: TcnSpeedButton;

    Panelformation: SE_Panel;
      lbl_TeamName: TLabel;
      BtnFormationBack: TcnSpeedButton;
      btnUniformBack: TcnSpeedButton;
      BtnFormationReset: TcnSpeedButton;
      lbl_MoneyF: TLabel;
      lbl_RankF: TLabel;
      lbl_TurnF: TLabel;
      lbl_PointsF: TLabel;
      lbl_MIF: TLabel;
      BtnFormationUniform: TcnSpeedButton;

    PanelSkill: SE_Panel;
      SE_GridSkill: SE_Grid;

    PanelUniform: SE_panel;
      ck_Shorts: TCnSpeedButton;
    Schema0: TCnSpeedButton;
      btn_UniformHome: TCnSpeedButton;
      btn_UniformAway: TCnSpeedButton;
      CnColorGrid1: TCnColorGrid;

    PanelMarket: SE_panel;
      SE_GridMarket: SE_Grid;
      btnMarketBack: TcnSpeedButton;
      btnMarketRefresh: TcnSpeedButton;
      edtsearchprice: TEdit;
      btnConfirmSell: TcnSpeedButton;
      lbl_maxvalue: TLabel;

    PanelError: SE_panel;
      lbl_Error: TLabel;
      BtnErrorOK: TCnSpeedButton;


    SE_field: SE_Engine;
    SE_players: SE_Engine;
    SE_ball: SE_Engine;
    se_lblPlay: TcnSpeedButton;
    SE_numbers: SE_Engine;
    SE_interface: SE_Engine;

    mainThread: SE_ThreadTimer;
    ThreadCurMove: SE_ThreadTimer;
    Timer1: TTimer;

    tcp: TWSocket;
    PanelMatchInfo: SE_Panel;
    SE_GridMatchInfo: SE_Grid;
    Label1: TLabel;
    btnLogout: TCnSpeedButton;
    btnOverrideUniformBlack: TCnSpeedButton;
    btnSelCountryTeamBack: TCnSpeedButton;
    Button5: TButton;
    Button9: TButton;
    ck_Jersey2: TCnSpeedButton;
    ck_Jersey1: TCnSpeedButton;
    Schema2: TCnSpeedButton;
    Schema1: TCnSpeedButton;
    Schema3: TCnSpeedButton;

// General
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnMainPlayClick(Sender: TObject);
    procedure btnErrorOKClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure BtnLoginClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);


// first time select country and team
    procedure SE_GridCountryTeamGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);

// LiveMatch GamePlay utilities
    procedure btnTacticsClick(Sender: TObject);
    procedure btnSkillPASSClick(Sender: TObject);
    procedure btnSubsClick(Sender: TObject);

// Tcp
    procedure tcpSessionConnected(Sender: TObject; ErrCode: Word);
    procedure tcpException(Sender: TObject; SocExcept: ESocketException);
    procedure tcpSessionClosed(Sender: TObject; ErrCode: Word);
    procedure tcpDataAvailable(Sender: TObject; ErrCode: Word);

// Threads And timers
    procedure mainThreadTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ThreadCurMoveTimer(Sender: TObject);
    procedure LoadAnimationScript; // tsScript arriva dal server e contiene l'animazione da realizzare qui sul client

// Tools
    procedure CheckBoxAI0Click(Sender: TObject);
    procedure CheckBoxAI1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

// Mouse on Theater
    procedure SE_Theater1SpriteMouseMove(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Shift: TShiftState; Var Handled: boolean);
    procedure SE_Theater1SpriteMouseDown(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton; Shift: TShiftState);
    procedure SE_Theater1SpriteMouseUp(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton; Shift: TShiftState);
    procedure SE_Theater1TheaterMouseMove(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Shift: TShiftState);
    procedure SE_ballSpriteDestinationReached(ASprite: SE_Sprite);

// Formation
    procedure BtnFormationBackClick(Sender: TObject);
    procedure BtnFormationResetClick(Sender: TObject);
    procedure btnFormationClick(Sender: TObject);

// Market
    procedure btnMarketBackClick(Sender: TObject);
    procedure btnMarketClick(Sender: TObject);
    procedure btnMarketRefreshClick(Sender: TObject);
    procedure ClientLoadMarket;
    procedure SE_GridMarketGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
    procedure btnConfirmSellClick(Sender: TObject);
    procedure btnConfirmDismissClick(Sender: TObject);
    procedure btnDismiss0Click(Sender: TObject);
    procedure btnsell0Click(Sender: TObject);

// XP
    procedure btnxp0Click(Sender: TObject);
    procedure btnxpBack0Click(Sender: TObject);
    procedure SE_GridXP0GridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
    procedure SE_GridXP0GridCellMouseMove(Sender: TObject; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);


// replay
    procedure btnReplayClick(Sender: TObject);
    procedure ToolSpinChange(Sender: TObject);
    procedure toolSpinKeyPress(Sender: TObject; var Key: Char);


// Skill
    procedure SE_GridSkillGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
    procedure SE_GridSkillGridCellMouseMove(Sender: TObject; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);

// WatchLive
    procedure btnWatchLiveClick(Sender: TObject);
    procedure ClientLoadListMatchFile;
    procedure SE_GridAllBrainGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
    procedure btnMatchesRefreshClick(Sender: TObject);
    procedure btnMatchesListBackClick(Sender: TObject);
    procedure btnWatchLiveExitClick(Sender: TObject);


// Combat Log
    procedure SE_GridDiceWriteRow  ( team: integer; attr, Surname, ids, num1, flags: string);
    procedure ClearInterface;
    procedure lbl_scoreMouseEnter(Sender: TObject);
    procedure lbl_scoreMouseLeave(Sender: TObject);
    procedure ShowMatchInfo;


// Uniform
    procedure BtnFormationUniformClick(Sender: TObject);
    procedure btnUniformBackClick(Sender: TObject);
    procedure Btn_UniformHomeClick(Sender: TObject);
    procedure Btn_UniformAwayClick(Sender: TObject);


    procedure btnStandingsClick(Sender: TObject);
    procedure SE_GridFreeKickGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
    procedure CnColorGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure btnSelCountryTeamClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnLogoutClick(Sender: TObject);
    procedure btnOverrideUniformWhiteClick(Sender: TObject);
    procedure btnOverrideUniformBlackClick(Sender: TObject);
    procedure btnSelCountryTeamBackClick(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Schema0Click(Sender: TObject);

  private
    { Private declarations }
    fSelectedPlayer : TSoccerPlayer;
    procedure ShowFace ( aPlayer: TSoccerPlayer );
    procedure AddFace ( aPlayer: TSoccerPlayer );
    procedure  SetSelectedPlayer ( aPlayer: TSoccerPlayer);
    function FieldGuid2Cell (guid:string): Tpoint;

    procedure ArrowShowShpIntercept( CellX, CellY : Integer; ToEmptyCell: boolean);
    procedure ArrowShowMoveAutoTackle( CellX, CellY : Integer);
    procedure ArrowShowLopheading(CellX, CellY : Integer; ToEmptyCell: boolean);
    procedure ArrowShowCrossingHeading( CellX, CellY : Integer) ;
    procedure ArrowShowDribbling( anOpponent: TSoccerPlayer; CellX, CellY : Integer);
    procedure hidechances;

    // Score
    procedure i_Tml ( MovesLeft,team: string );  // animazione internal mosse rimaste
    procedure SetTmlPosition ( team: string );
    procedure i_tuc ( team: string );          // animazione internal turn change
    procedure RefreshGridTime;
    procedure i_red ( ids: string );           // animazione internal red card (espulsione)
    procedure i_Yellow ( ids: string );        // animazione internal yellow card (ammonizione)
    procedure i_Injured ( ids: string );       // animazione internal infortunio

    // interface
    procedure LoadGridFreeKick ( team : integer; stat: string; clearMark: boolean );
    procedure CreateSplash (aString: string; msLifespan: integer) ;
    procedure RemoveChancesAndInfo  ;
    procedure CornerSetBall;
    procedure CornerSetPlayer ( aPlayer: TsoccerPlayer);

    procedure Logmemo ( ScriptLine : string );

    // highlight field cell
    procedure HighLightField ( CellX, CellY, LifeSpan : integer );
    procedure HighLightFieldFriendly ( aPlayer: TSoccerPlayer; cells: char );
    procedure HighLightFieldFriendly_hide;

    // Animation
    procedure ClientLoadBrainMM ( incMove: Byte; FirstTime: boolean) ;  // carica il brain e lo script
    function ClientLoadScript ( incMove: Byte) : Integer;               // riempe TAnimationScript
    procedure Anim ( Script: string );                                  // esegue TAnimationScript
      procedure AnimCommon ( Cmd:string);
    procedure PrepareAnim;
    procedure SpriteReset ;
    procedure UpdateSubSprites;
    procedure MoveInReserves ( aPlayer: TSoccerPlayer );                // mette uno sprite player nelle riserve
    procedure CancelDrag(aPlayer: TsoccerPlayer; ResetCellX, ResetCellY: integer ); // anulla il dragdrop dello sprite
    procedure FirstShowRoll;

    procedure SelectedPlayerPopupSkill ( CellX, CellY: integer);
    procedure RoundBorder (bmp: TBitmap; w,h: Integer);

    // check ball position
    function inGolPosition ( PixelPosition: Tpoint ): Boolean;
    function inCrossBarPosition ( PixelPosition: Tpoint ): Boolean;
    function inGKCenterPosition ( PixelPosition: Tpoint ): Boolean;

    function isTvCellFormation ( Team, CellX, CellY: integer ): boolean;
    procedure LoadTranslations ;

    function Capitalize ( aString : string  ): String;

    // Screen init
    procedure SetTheaterMatchSize;
    procedure InitializeTheaterMatch;
    procedure InitializeTheaterFormations;
    procedure Createfield;
    procedure CreateFieldPoints;
    procedure createNoiseTV;


    procedure ClientLoadFormation ;
      procedure PreloadUniform(ha:Byte;   UniformSchemaIndex: integer);
      procedure PreloadUniformGK(ha:Byte;  UniformSchemaIndex: integer);
      function DarkColor(aColor: TColor): TColor;
      function softlight(aColor: TColor): TColor;
      function i_softlight(ib, ia: integer): integer;

      procedure ColorizeFault( Team:Byte;  var FaultBitmap: SE_Bitmap);
      procedure ColorizeArrowCircle( Team:Byte;   ShapeBitmap: SE_Bitmap);

    function RndGenerate( Upper: integer ): integer;
    function RndGenerate0( Upper: integer ): integer;
    function RndGenerateRange( Lower, Upper: integer ): integer;

    function findlstSkill (SkillName: string ): integer;
    function findPlayerMyBrainFormation ( guid: string ): TSoccerPlayer;
    procedure UpdateFormation ( Guid: string; Team, TvCellX, TvCellY: integer);
    function CheckFormationTeamMemory : Boolean; // in memoria mybrainformation lstsoccerplayer.formationcellX
      procedure RefreshCheckFormationMemory;

    procedure SetGlobalCursor ( aCursor: Tcursor);

    procedure SetupGridXP (GridXP: SE_grid; aPlayer: TsoccerPlayer);
    procedure SetupGridAttributes (GridAT: SE_grid; aPlayer: TsoccerPlayer; show:char);

    procedure CreateArrowDirection ( Player1 , Player2: TSoccerPlayer ); overload;
    procedure CreateArrowDirection ( Player1 : TSoccerPlayer;  CellX, CellY: integer ); overload;
    procedure CreateCircle(  Player : TSoccerPlayer  ); overload;
    procedure CreateCircle(  Team,  CellX, CellY: integer  );overload;
    procedure CreateBaseAttribute ( CellX, CellY, Value: Integer );
// Mouse movement sulla SE_GridSkill
    procedure PrsMouseEnter ( Sender : TObject);
    procedure PosMouseEnter ( Sender : TObject);

    procedure SetGameScreen (const aGameScreen:TGameScreen);
  public
    { Public declarations }
    aInfoPlayer: TSoccerPlayer;
    fGameScreen: TGameScreen;
    MouseWaitFor : TMouseWaitFor;
//    function InvertFormationCell (FormationCellX , FormationCellY : integer): Tpoint;


    function GetDominantColor ( Team: integer  ): TColor;
    function GetContrastColor( cl: TColor  ): TColor;


    property  GameScreen :TGameScreen read fGameScreen write SetGameScreen;
    procedure SetTcpFormation;

    property  SelectedPlayer: TSoccerPlayer read fSelectedPlayer write SetSelectedPlayer;

end;

var
  Form1: TForm1;
  aScript, OldScript : string;

  xpNeedTal: array [1..NUM_TALENT] of integer;  // come i talenti sul db game.talents. xp necessaria per trylevelup del talento
  SelCountryTeam: string;
  Language: string;
  MutexAnimation : Cardinal;
  oldCellXMouseMove, oldCellYMouseMove: Integer;
  dir_log: string;
  MyBrain: TSoccerBrain;
  MyBrainFormation: TSoccerBrain;
  RandGen: TtdBasePRNG;
  GCD: Integer; // global cooldown temporaneo per braininput
  dir_tmp, dir_stadium, dir_ball, dir_skill, dir_player, dir_interface, dir_data, dir_sound, dir_attributes, dir_help, dir_talent: string;
  LastSpriteMouseMoveGuid: string;
  lastMouseMovePlayer:TSoccerPlayer;
  WAITING_GETFORMATION, WAITING_STOREFORMATION: boolean;

  // il client si mette in attesa di una rispoosta dal server:



  DontDoPlayers: Boolean; // non accetta click sui player
  oldVisualCmd: string;

  se_gridskilloldCol, se_gridskilloldRow : Integer;

  TranslateMessages : TStringList;
  TalentEditing : boolean;
  AnimationScript : TAnimationScript;
  FormationsPreset: TList<TFormation>;
  ADVSKoldCol, ADVSKoldRow: integer;
  tsCoa: Tstringlist;
  tsCod: Tstringlist;
  UsePlaySoundBall: boolean;


  oldPlayer: TSoccerPlayer;
  oldShift: TShiftState;

  Score: Tscore;

  SE_DragGuid: Se_Sprite; // sprite che sto spostando con il drag and drop
  Animating:Boolean;
//  StringTalents: array [1..NUM_TALENT] of string;
  StringTalents: array [0..255] of string;
  LstSkill: array[0..13] of string; // 13 skill totali
  ShowPixelInfo: Boolean;

  keyTimer : Word;

  viewMatch : Boolean; // sto guardando in modalità spettatore
  ViewReplay: Boolean; // sto guardando un reaply locale
  LiveMatch: Boolean;  // sono in livematch 1vs1

  MyGuidTeam: Integer;       // identificatore assoluto del mio team sul DB game.teams
  MyGuidTeamName: string;    // il nome del team che corrisponde ad una squadra del cuore reale
  LocalSeconds: Integer;     // Quando i 120 seocndi si esauriscono, il turno termina
  LastGuidTurn: Integer;
  lastStrError: string;
  LastCellx2,LastCelly2: Integer;


  Rewards : array [1..4, 1..20] of Integer;

  lstInteractivePlayers: TList<TInteractivePlayer>; // lista che contiene i player interagiscono durante il turno dell'avversario
  MarkingMoveAll: Boolean;

  FirstLoadOK: Boolean; // Primo caricamento della partita avvenuto. Avviene anche durante un reconnect

  TsWorldCountries, TsNationTeams : TStringList;

  Buf3 : array [0..255] of TArray8192;    // array globali. vengono riempiti in Tcp.dataavailable. una partita non va oltre 255 turni, di solito 120 + recupero
  MM3 : array [0..255] of TMemoryStream;  // copia di cui sopra ma in formato stream, per un accesso rapido a certe informazioni

  LastTcpincMove,CurrentIncMove: byte;
  incMoveAllProcessed : array [0..255] of boolean;
  incMoveReadTcp : array [0..255] of boolean;

  TSUniforms: array [0..1] of Tstringlist;
  UniformBitmapBW,FaultBitmapBW,InOutBitmap : SE_Bitmap;

  // Team General
  NextHa: Byte;                 // prossima partita in cas o fuori (home,away)
  mi: SmallInt;                 // media inglese
  points: Integer;              // punti
  MatchesPlayedTeam: Integer;   // totale partite giocate
  Money: Integer;               // Denaro
  TotMarket: Integer;           // Valore totale dei player


  btn_Schema : array [0..Schemas-1] of TCnSpeedButton;

  FieldPoints : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsReserve : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsCorner : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsPenalty : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsCrossBar : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsCrossGol : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsCrossOut : TObjectList<TFieldPoint>; // 8 risoluzioni video

  procedure RoundCornerOf(Control: TWinControl) ;
implementation

{$R *.dfm}

uses Unit2{Unit ShowPanel }, Unit3;
procedure RoundCornerOf(Control: TWinControl) ;
var
   R: TRect;
   Rgn: HRGN;
begin
   with Control do begin
     R := ClientRect;
     rgn := CreateRoundRectRgn(R.Left, R.Top, R.Right, R.Bottom, 20, 20) ;
     Perform(EM_GETRECT, 0, lParam(@r)) ;
     InflateRect(r, - 4, - 4) ;
     Perform(EM_SETRECTNP, 0, lParam(@r)) ;
     SetWindowRgn(Handle, rgn, True) ;
     Invalidate;
   end;
end;

function TryDecimalStrToInt( const S: string; out Value: Integer): Boolean;
begin
   result := ( pos( '$', S ) = 0 ) and TryStrToInt( S, Value );
end;

function RemoveEndOfLine(const Line : String) : String;
begin
    if (Length(Line) >= Length(EndOfLine)) and
       (StrLComp(PChar(@Line[1 + Length(Line) - Length(EndOfLine)]),
                 PChar(EndOfLine),
                 Length(EndOfLine)) = 0) then
        Result := Copy(Line, 1, Length(Line) - Length(EndOfLine))
    else
        Result := Line;
end;

function PointInPolyRgn(const P: TPoint; const Points: array of TPoint): Boolean;
type
  PPoints = ^TPoints;
  TPoints = array [0..0] of TPoint;
var
  Rgn: HRGN;
begin
  Rgn := CreatePolygonRgn(PPoints(@Points)^, High(Points) + 1, WINDING);
  try
    Result := PtInRegion(Rgn, P.X, P.Y);
  finally
    DeleteObject(Rgn);
  end;
end;

procedure CalculateChance  ( A, B: integer; var chanceA, chanceB: integer; var chanceColorA, chanceColorB: Tcolor);
var
  AI, BI, TA, TB: integer;
begin
  TA := 0;
  TB := 0;
  for AI := 1 to 4 do begin
    for BI := 1 to 4 do begin
      if A+AI >= B+BI then inc (TA)
        else inc (TB);
    end;
  end;
  chanceA := trunc (( TA * 100 ) / 16);
  if chanceA = 0 then begin
    chanceA := 1;
  end else if chanceA = 100 then chanceA := 99;

  chanceB := trunc (( TB * 100 ) / 16);
  if chanceB = 0 then begin
    chanceB := 1;
  end else if chanceB = 100 then chanceB := 99;

  case chanceA of
    0..33: begin
      chancecolorA:= clRed;
    end;
    34..66: begin
      chancecolorA:= clYellow;
    end;
    67..100: begin
      chancecolorA:= clGreen;
    end;
  end;

  case chanceB of
    0..33: begin
      chancecolorB:= clRed;
    end;
    34..66: begin
      chancecolorB:= clYellow;
    end;
    67..100: begin
      chancecolorB:= clGreen;
    end;
  end;
end;

Constructor TAnimationScript.create;
begin
  Ts:= TstringList.Create ;
  Index := -1;

end;
Destructor TAnimationScript.destroy ;
begin
  memo.Clear ;
  Ts.free;
  inherited;
end;
procedure TAnimationScript.Reset;
begin
  memo.Clear ;
  Index := -1;
  Wait := -1;
  WaitMovingPlayers := false;
  Ts.clear;
end;
procedure TAnimationScript.TsAdd ( v: string );
begin
  Ts.Add ( v );
 // memo.Lines.Add( v );
end;

procedure TForm1.BtnLoginClick(Sender: TObject);
var
  ini : TIniFile;
begin
  if GCD <= 0 then begin
    tcp.SendStr( 'login,'+Edit1.text +',' + Edit2.text + EndofLine);
    ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'client.ini');
    ini.WriteString('lastlogin', 'username', Edit1.text);
    ini.WriteString('lastlogin', 'pwd',Edit2.text);
    ini.Free;


    GCD := GCD_DEFAULT;
  end;
end;


procedure TForm1.btnLogoutClick(Sender: TObject);
begin
  tcp.CloseDelayed;
end;

procedure TForm1.btnMainPlayClick(Sender: TObject);
begin
      WaitForSingleObject ( MutexAnimation, INFINITE );
      AnimationScript.Reset;
      FirstLoadOK:= False;
      ReleaseMutex(MutexAnimation );

  if GCD <= 0 then begin
    if CheckFormationTeamMemory then begin
     LiveMatch := True;
     tcp.SendStr( 'queue' + endofline);
    // gameScreen := ScreenWaitingLiveMatch;
    end
    else begin
      ShowFormations;
      InitializeTheaterFormations;
     end;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnMarketBackClick(Sender: TObject);
begin
  PanelMarket.Visible := False;
  GameScreen := ScreenMain;
//  ShowMain;
end;

procedure TForm1.btnMarketClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    if GameScreen =  ScreenMain then
    tcp.SendStr( 'market,' +  IntToStr(MaxInt)  + EndofLine);
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnMarketRefreshClick(Sender: TObject);
var
  aPrice : Integer;
begin
  if GCD <= 0 then begin
    aPrice := StrToIntDef(edtsearchprice.text,0);
    tcp.SendStr( 'market,' + IntTostr(aPrice) + EndofLine);
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnMatchesListBackClick(Sender: TObject);
begin
  GameScreen := ScreenMain;

end;

procedure TForm1.btnMatchesRefreshClick(Sender: TObject);
begin
  btnWatchLiveClick ( btnWatchLive );
end;

procedure TForm1.btnOverrideUniformBlackClick(Sender: TObject);
var
  i: Integer;
  aSprite : SE_Sprite;
begin

  if btnOverrideUniformBlack.Down then begin
    for I := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      if MyBrain.lstSoccerPlayer[i].Team = 1 then
        MyBrain.lstSoccerPlayer[i].SE_Sprite.BlendMode := SE_BlendReflect;
    end;
  end
  else begin
    for I := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      if MyBrain.lstSoccerPlayer[i].Team = 1 then
        MyBrain.lstSoccerPlayer[i].SE_Sprite.BlendMode := SE_BlendNormal;
    end;
  end;

end;



procedure TForm1.btnOverrideUniformWhiteClick(Sender: TObject);
var
  i: Integer;
  aSprite : SE_Sprite;
begin

  if btnOverrideUniformWhite.Down then begin
    for I := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      if MyBrain.lstSoccerPlayer[i].Team = 1 then
        MyBrain.lstSoccerPlayer[i].SE_Sprite.BlendMode := SE_BlendAverage;
    end;
  end
  else begin
    for I := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      if MyBrain.lstSoccerPlayer[i].Team = 1 then
        MyBrain.lstSoccerPlayer[i].SE_Sprite.BlendMode := SE_BlendNormal;
    end;
  end;

end;

procedure TForm1.btnReplayClick(Sender: TObject);
var
  i: Integer;
  sf : SE_SearchFiles;
begin
  {$ifdef tools}
  ViewReplay := True;
  ToolSpin.Visible := True;
  // dialogs
  FolderDialog1.Directory := dir_log;

  if not FolderDialog1.Execute then begin
    ViewReplay := false;
    ToolSpin.Visible := false;
    Exit;
  end;
  sf :=  SE_SearchFiles.Create(nil);

  sf.MaskInclude.add ('*.is');
  sf.FromPath := FolderDialog1.Directory;
  sf.SubDirectories := False;
  sf.Execute ;

  while Sf.SearchState <> ssIdle do begin
    Application.ProcessMessages ;
  end;

  sf.ListFiles.Sort;

  if sf.ListFiles.Count > 0 then begin
    if FileExists( FolderDialog1.Directory  + '\' + sf.ListFiles[0] ) then begin
      InitializeTheaterMatch;
      GameScreen := ScreenLiveMatch ;
      MM3[0].LoadFromFile( FolderDialog1.Directory   + '\' + sf.ListFiles[0]);
      CopyMemory( @Buf3[0], MM3[0].Memory, MM3[0].size  );
      ClientLoadBrainMM ( 0, true ); // sempre true durante replay
      SE_players.ProcessSprites(2000); //<-- forza l'inserimento in lstsprites da lstnewsprite o dopo il remove non li troverà
      CurrentIncMove :=  0;
      ClientLoadScript( 0 );
      if Mybrain.tsScript.Count = 0 then begin
        ClientLoadBrainMM ( 0, true ); // sempre true durante replay
      end
      else
        LoadAnimationScript; // if ts[0] = server_Plm CL_ ecc..... il vecchio ClientLoadbrain . alla fine il thread chiama  ClientLoadBrainMM
    end
    else ViewReplay := false;
  end
  else ViewReplay := false;

  sf.Free;

  {$endif tools}

end;


procedure TForm1.btnSelCountryTeamBackClick(Sender: TObject);
begin
  SelCountryTeam := '';
  GameScreen := ScreenSelectCountry;
end;

procedure TForm1.btnSelCountryTeamClick(Sender: TObject);
begin
  // una volta all'inizio del gioco
  if (GCD <= 0) and ( StrToIntDef(SelCountryTeam,0) <> 0 ) then begin
    if GameScreen =  ScreenSelectCountry then
    tcp.SendStr( 'selectedcountry,' + SelCountryTeam + EndofLine)
    else if GameScreen =  ScreenSelectTeam then begin
      if (Application.MessageBox  ( PChar(Translate('lbl_ConfirmTeam') + ' : ' + TsNationTeams.Values [SelCountryTeam] ) , pChar(Translate('lbl_ConfirmTeam')),  MB_YESNO )) = IDYES then begin
        WAITING_GETFORMATION:= True;
        tcp.SendStr(  'selectedteam,' + SelCountryTeam + EndofLine);
      end
      else GameScreen :=  ScreenSelectCountry;
    end;
    GCD := GCD_DEFAULT;
  end;

end;

procedure TForm1.btnsell0Click(Sender: TObject);
var
  aPlayer: TSoccerPlayer;
begin
  case btnsell0.Tag of  // onMarket
    1: begin
      WAITING_GETFORMATION:= True;
      btnsell0.Tag:=0;
      btnsell0.Caption := Translate('lbl_Sell');
      tcp.SendStr( 'cancelsell,'+ se_grid0.SceneName  + EndofLine); // solo a sinistra in formation
    end;
    0: begin
      if TotMarket < 3 then begin
        PanelSell.Visible := True;
        PanelSell.BringToFront;
        aPlayer:= MyBrainFormation.GetSoccerPlayer2( se_grid0.SceneName ) ;
        edtSell.Text  := IntToStr(aPlayer.MarketValue);
      end
      else begin
        lastStrError:= 'lbl_ErrorMarketMax';
        ShowError( Translate('lbl_ErrorMarketMax'));
      end;
    end;
  end;

end;

procedure TForm1.btnSkillPASSClick(Sender: TObject);
begin
  if MyBrain.w_CornerSetup then Exit;

  if GCD <= 0 then begin
    if ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PASS'+ EndOfLine);
    GCD := GCD_DEFAULT;
    PanelCorner.Visible := false;
  end;

end;


procedure TForm1.btnStandingsClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    tcp.SendStr(  'standings' + EndofLine  );
    GCD := GCD_DEFAULT;
  end;
 { TODO : riceve in zlib la query pvp dell m.i. vicine a me }
end;

procedure TForm1.Button10Click(Sender: TObject);
begin
  {$ifdef tools}
  if SelectedPlayer = nil  then Exit;

  if GCD <= 0 then begin
    tcp.SendStr(  'testcorner,' + SelectedPlayer.ids + EndofLine  );
    GCD := GCD_DEFAULT;
  end;
  {$endif tools}

{ brainServer.tsScript.Add('SERVER_POS,' + SelectedPlayer.ids ) ;
 brainServer.CornerSetup ( SelectedPlayer );
// brainServer.tsScript.Add('E') ;
 brainServer.SaveData;
// ClientNotifyFileData (Dir_Data + Format('%.*d',[3, brainServer.incMove]) + '.ini');
  CopyFile(PChar(brainserver.Dir_Data + Format('%.*d',[3, brainServer.incMove]) + '.ini'),PChar(Dir_Data + Format('%.*d',[3, brainServer.incMove]) + '.ini'), false);
 inc(brainServer.incMove);}

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'setplayer,' +  Edit3.Text + ',' +  EditN1.Text + ',' +  EditN2.Text + EndOfLine ) ;
    GCD := GCD_DEFAULT;

  end;
{$endif tools}
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  i: integer;
begin
  {$ifdef tools}

  memoC.Lines.Clear ;
  for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
    memoC.Lines.Add((MyBrain.lstSoccerPlayer [i].Ids + '.' +
                     MyBrain.lstSoccerPlayer [i].surname + '.' +
                  //   inttostr(MyBrain.lstSoccerPlayer [i].BallControl)) );
//                     Inttostr(MyBrain.lstSoccerPlayer [i].cellx) + '.' +
//                     inttostr(MyBrain.lstSoccerPlayer [i].celly)) );
                       IntToStr( MyBrain.lstSoccerPlayer [i].se_sprite.SubSprites.count)) );
  end;
//  MemoC.Lines.Add( 'nSprites se_players :' + IntToStr(SE_players.SpriteCount) );
//  for I := 0 to SE_players.SpriteCount -1 do begin
//    MemoC.Lines.Add( SE_players.Sprites[i].Guid );

//  end;
  {$endif tools}

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  {$ifdef tools}
  CheckBox3.Enabled := False;
  ThreadCurMove.Enabled := False;
  if  CnSpinEdit1.Value > 0 then
   ClientLoadBrainMM ( trunc( CnSpinEdit1.Value - 1), false );
  CurrentIncMove :=  trunc( CnSpinEdit1.Value);
  ClientLoadScript( trunc( CnSpinEdit1.Value)  );
  if Mybrain.tsScript.Count = 0 then begin
    ClientLoadBrainMM ( trunc( CnSpinEdit1.Value), true );
  end
  else
    LoadAnimationScript; // if ts[0] = server_Plm CL_ ecc..... il vecchio ClientLoadbrain . alla fine il thread chiama  ClientLoadBrainMM
  {$endif tools}
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  MyBrain.AI_Think(MyBrain.TeamTurn);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'utime' + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'setball,' + EditN1.Text + ',' +  EditN2.Text + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}
end;


procedure TForm1.Button7Click(Sender: TObject);
var
  i,c: Integer;
  aPoint : PPointL;
  bmp: SE_Bitmap;
  aSprite,aSEField: SE_Sprite;
begin
  {$ifdef tools}

  if GameScreen <> ScreenLiveMatch  then Exit;


    for i:= 0 to 30 do begin
      aSprite := se_field.FindSprite('shotcell'+inttostr(i));
      if aSprite <> nil then
        se_field.RemoveSprite (aSprite);
    end;

    bmp:= SE_Bitmap.Create (20,12);
    bmp.Bitmap.Canvas.Brush.Color := clRed;
    bmp.Bitmap.Canvas.Ellipse(2,2,19,7);
    for i:= 0 to Mybrain.ShotCells.Count -1 do begin
          if (Mybrain.ShotCells[i].DoorTeam <> SelectedPlayer.Team) and
            (Mybrain.ShotCells[i].CellX = SelectedPlayer.CellX) and (Mybrain.ShotCells[i].CellY = SelectedPlayer.CellY) then begin
          // sono sopra questa shotcell
          // tra le celle adiacenti, solo la X attuale e ciclo per le Y
           //   aShotCell := brain.ShotCells[I];

          for c := 0 to  Mybrain.ShotCells[i].subCell.Count -1 do begin
            aPoint := Mybrain.ShotCells[i].subCell.Items [c];
            aSEField := SE_field.FindSprite(IntToStr (aPoint.X ) + '.' + IntToStr (aPoint.Y ));

            aSprite := se_field.CreateSprite  ( bmp.Bitmap , 'shotcell'+inttostr(c),1,1,100, aSEField.Position.X ,aSEField.Position.Y,true);
            aSprite.Priority := 30;

            //anOpponent := Brain.GetSoccerPlayer(aPoint.X ,aPoint.Y );
          end;
      end;
    end;
    bmp.Free;
  {$endif tools}

end;

procedure TForm1.Button8Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr(  'randomstamina' + EndofLine  );
    GCD := GCD_DEFAULT;
  end;
{$endif tools}
end;

procedure TForm1.Button9Click(Sender: TObject);
var
  i,c: Integer;
  aPoint : PPointL;
  bmp: SE_Bitmap;
  aSprite,aSEField: SE_Sprite;
begin
  {$ifdef tools}

  if GameScreen <> ScreenLiveMatch  then Exit;


    for i:= 0 to 30 do begin
      aSprite := se_field.FindSprite('shotcell'+inttostr(i));
      if aSprite <> nil then
        se_field.RemoveSprite (aSprite);
    end;

    bmp:= SE_Bitmap.Create (20,12);
    bmp.Bitmap.Canvas.Brush.Color := clRed;
    bmp.Bitmap.Canvas.Ellipse(2,2,19,7);
    for i:= 0 to Mybrain.ShotCells.Count -1 do begin
          // sono sopra questa shotcell
          // tra le celle adiacenti, solo la X attuale e ciclo per le Y
           //   aShotCell := brain.ShotCells[I];

            aSEField := SE_field.FindSprite(IntToStr (Mybrain.ShotCells[i].CellX ) + '.' + IntToStr (Mybrain.ShotCells[i].CellY ));

            aSprite := se_field.CreateSprite  ( bmp.Bitmap , 'shotcell'+inttostr(c),1,1,100, aSEField.Position.X ,aSEField.Position.Y,true);
            aSprite.Priority := 30;

    end;
    bmp.Free;
  {$endif tools}


end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Timer1.Enabled := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  I: Integer;
  ini : TIniFile;
begin
  // deve essere ubgual a quella del server formcreate
  xpNeedTal[TALENT_ID_GOALKEEPER] := 50;
  xpNeedTal[TALENT_ID_CHALLENGE] := 50;
  xpNeedTal[TALENT_ID_TOUGHNESS] := 50;
  xpNeedTal[TALENT_ID_POWER] := 50;
  xpNeedTal[TALENT_ID_CROSSING] := 50;
  xpNeedTal[TALENT_ID_LONGPASS] := 50;
  xpNeedTal[TALENT_ID_EXPERIENCE] := 50;
  xpNeedTal[TALENT_ID_DRIBBLING] := 40;
  xpNeedTal[TALENT_ID_BULLDOG] := 50;
  xpNeedTal[TALENT_ID_OFFENSIVE] := 50;
  xpNeedTal[TALENT_ID_DEFENSIVE] := 50;
  xpNeedTal[TALENT_ID_BOMB] := 50;
  xpNeedTal[TALENT_ID_PLAYMAKER] := 50;
  xpNeedTal[TALENT_ID_FAUL] := 50;
  xpNeedTal[TALENT_ID_MARKING] := 50;
  xpNeedTal[TALENT_ID_POSITIONING] := 50;
  xpNeedTal[TALENT_ID_FREEKICKS] := 40;
  xpNeedTal[TALENT_ID_AGILITY] := 50;
  xpNeedTal[TALENT_ID_RAPIDPASSING] := 50;
  xpNeedTal[TALENT_ID_AGGRESSION] := 50;
  xpNeedTal[TALENT_ID_ACE] := 50;
  xpNeedTal[TALENT_ID_HEADING] := 50;
  xpNeedTal[TALENT_ID_FINISHING] := 50;
  xpNeedTal[TALENT_ID_DIVING] := 50;

  MutexAnimation:=CreateMutex(nil,false,'tsscript');

  //SE_GridCountryTeam.Active := false;

  for I := 0 to Schemas-1 do begin
    btn_Schema[i] := FindComponent ( 'Schema' + IntToStr(i)) as TcnSpeedButton;
  end;



  {$ifdef tools}
  btnReplay.Visible := True;
  //ToolSpin.Visible := True;

  Panel1.Visible := True;
  Panel1.BringToFront;

  {$endif tools}
  TsUniforms[0]:= Tstringlist.create;
  TsUniforms[1]:= Tstringlist.create;

  for I := 0 to 255 do begin
    MM3[i]:= TMemoryStream.Create;
  end;

  CurrentIncMove := 0;
  lstInteractivePlayers:= TList<TInteractivePlayer>.create;
  lbl_Nick0.Text.Lines.Clear;
  lbl_Nick1.Text.Lines.Clear;


  edtSell.Left := ( (PanelSell.Width div 2) - (edtSell.Width div 2) )  ;
//////  edtBid.Top := lblSurname.top;

  FormatSettings.DecimalSeparator := '.';
  RandGen := TtdCombinedPRNG.Create(0, 0);
  MyBrainFormation:= TSoccerBrain.Create ('Formation');

  GCD:= 0;
  //form1.Height  := iraTheater1.Top + iraTheater1.Height +35;
  MyBrain := TSoccerBrain.Create(  '') ;
  MyBrain.incMove := 0; // +1 nella ricerca .ini


  TsCoa:= Tstringlist.Create;
  TsCod:= Tstringlist.Create;

  AnimationScript:= TAnimationScript.Create ;
  AnimationScript.memo  := memo3;
  MainThread.Enabled := true;
//  CreateRewards;

  FormationsPreset := TList<TFormation>.Create;
  CreateFormationsPreset;

  dir_tmp := ExtractFilePath(application.exename) + 'bmp\tmp\';
  dir_stadium := ExtractFilePath(application.exename) + 'bmp\stadium\';
  dir_ball := ExtractFilePath(application.exename) + 'bmp\ball\';
  dir_skill := ExtractFilePath(application.exename) + 'bmp\skill\';
  dir_player := ExtractFilePath(application.exename) + 'bmp\player\';
  dir_interface := ExtractFilePath(application.exename) + 'bmp\interface\';
  dir_data := ExtractFilePath(application.exename) + 'data\';
  dir_sound := ExtractFilePath(application.exename) + 'sounds\';
  dir_attributes := ExtractFilePath(application.exename) + 'bmp\attributes\';
  dir_help := ExtractFilePath(application.exename) + 'help\';
  dir_talent := ExtractFilePath(application.exename) +  'bmp\talent\';

  ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'client.ini');
  dir_log := ini.ReadString('directory','log','c:\temp');
  Language := ini.ReadString('LANGUAGE','Text','EN');
  Edit1.text := ini.ReadString('lastlogin','username','');
  Edit2.text := ini.ReadString('lastlogin','pwd','');
  ini.Free;

  LoadTranslations;


  Application.ProcessMessages ;

  // rispetto l'esatto ordine dei talenti sul server
  StringTalents[1]:= 'goalkeeper';
  StringTalents[2] := 'challenge'; // lottatore
  StringTalents[3] := 'toughness'; // durezza
  StringTalents[4] := 'power';      // potenza
  StringTalents[5] :=  'crossing';
  StringTalents[6] :=  'longpass';  // solo distanza
  StringTalents[7] :=  'experience';  // pressing gratis
  StringTalents[8] :=  'dribbling';
  StringTalents[9] :=  'bulldog';
  StringTalents[10] :=  'offensive';
  StringTalents[11] :=  'defensive';
  StringTalents[12] :=  'bomb';
  StringTalents[13] :=  'playmaker';
  StringTalents[14] :=  'faul';
  StringTalents[15] :=  'marking';
  StringTalents[16] :=  'positioning';
  StringTalents[17] :=  'freekicks';
  StringTalents[18] :=  'agility';
  StringTalents[19] :=  'rapidpassing';
  StringTalents[20] :=  'aggression';
  StringTalents[21] :=  'ace';
  StringTalents[22] :=  'heading';
  StringTalents[23] :=  'finishing';
  StringTalents[24] :=  'diving';

  StringTalents[128] :=  'advanced_challenge';
  StringTalents[129] :=  'advanced_toughness';
  StringTalents[130] :=  'advanced_power';
  StringTalents[131] :=  'advanced_crossing';
  StringTalents[132] :=  'advanced_experience';
  StringTalents[133] :=  'advanced_dribbling';
  StringTalents[134] :=  'advanced_bulldog';
  StringTalents[135] :=  'advanced_aggression';
  StringTalents[136] :=  'advanced_bomb';
  StringTalents[137] :=  'precise_crossing';
  StringTalents[138] :=  'super_dribbling';
  StringTalents[139] :=  'buff_defense';
  StringTalents[140] :=  'buff_middle';
  StringTalents[141] :=  'buff_forward';

  StringTalents[250] :=  'gkmiracle';
  StringTalents[251] :=  'gkpenalty';


  LstSkill[0]:= 'Move';
  LstSkill[1]:= 'Short.Passing';
  LstSkill[2]:= 'Lofted.Pass';
  LstSkill[3]:= 'Crossing';
  LstSkill[4]:= 'Precision.Shot';
  LstSkill[5]:= 'Power.Shot';
  LstSkill[6]:= 'Dribbling';
  LstSkill[7]:= 'Protection';
  LstSkill[8]:= 'Tackle';
  LstSkill[9]:= 'Pressing';
  LstSkill[10]:= 'Corner.Kick';
  LstSkill[11]:= 'BuffD';
  LstSkill[12]:= 'BuffM';
  LstSkill[13]:= 'BuffF';

  btnFormation.Caption := Translate('lbl_Formation');
  btnMainPlay.Caption := Translate('lbl_Play');
  btnWatchLive.Caption := Translate('lbl_watchlive');
  btnMarket.Caption := Translate('lbl_Market');
  btnStandings.Caption := Translate('lbl_Standings');
  btnExit.Caption := Translate('lbl_Exit');
  btnConfirmSell.Caption := Translate('lbl_Confirm');
  btnWatchLiveExit.Caption :=  Translate('lbl_Exit');
  btnSelCountryTeam.Caption :=  Translate('lbl_Select');

  btnDismiss0.Caption :=  Translate('lbl_Dismiss');
  lbl_ConfirmDismiss.Caption := Translate('lbl_ConfirmDismiss');

  btnFormationUniform.Caption :=  Translate('lbl_Uniform');
  ck_Jersey1.Caption :=   Translate('lbl_Jersey') + ' 1';
  ck_Jersey2.Caption :=   Translate('lbl_Jersey') + ' 2';
  ck_Shorts.Caption :=   Translate('lbl_Shorts');
  btn_UniformHome.Caption := Translate('lbl_Home');
  btn_UniformAway.Caption := Translate('lbl_Away');

  btnLogin.Caption := Translate('lbl_Login');

  btnMarketBack.Caption := Translate('lbl_Back');
  btnMarketRefresh.Caption := Translate('lbl_Search');

  btnMatchesRefresh.Caption := Translate('lbl_Refresh');
  btnMatchesListBack.Caption := Translate('lbl_Back');

  lbl_MIF.Caption := Translate('lbl_MI');
  lbl_RankF.Caption := Translate('lbl_Rank');
  lbl_pointsF.Caption := Translate('lbl_Points');
  lbl_TurnF.Caption := Translate('lbl_NextTurn');
  lbl_MoneyF.Caption := Translate('lbl_Money');

  btnSelCountryTeamBack.Caption := Translate( 'lbl_Cancel');

  UniformBitmapBW := SE_Bitmap.Create (dir_player + 'bw.bmp');
  FaultBitmapBW := SE_Bitmap.Create (dir_interface + 'fault.bmp');
  InOutBitmap := SE_Bitmap.Create (dir_interface + 'inout.bmp');
  InOutBitmap.Stretch( 40,40 );


  TsWorldCountries:= TStringList.Create;
  TsNationTeams:= TStringList.Create;
  TsWorldCountries.StrictDelimiter := True;
  TsNationTeams.StrictDelimiter := True;

  SetTheaterMatchSize;

  btnSubs.Glyph.LoadFromFile ( dir_interface + 'inout.bmp') ;
  btnSubs.Glyph.LoadFromFile ( dir_interface + 'inout.bmp') ;

  btnOverrideUniformWhite.Glyph.LoadFromFile ( dir_interface + 'w.bmp') ;
  btnOverrideUniformBlack.Glyph.LoadFromFile ( dir_interface + 'b.bmp') ;

  DeleteDirData;





  Timer1Timer(Timer1);
  Timer1.Enabled := True;
  ShowPanelBack;
  ShowLogin;

//  SE_GridTime.thrdAnimate.Priority := tplowest;
  SE_GridXP0.thrdAnimate.Priority := tplowest;
//  SE_Gridcountryteam.thrdAnimate.Priority := tplowest;


end;
procedure TForm1.FormDestroy(Sender: TObject);
var
  i: integer;
begin
  FieldPoints.Free;
  FieldPointsReserve.Free;
  FieldPointsCorner.Free;
  FieldPointsPenalty.Free;
  FieldPointsCrossBar.Free;
  FieldPointsCrossGol.Free;
  FieldPointsCrossOut.Free;

  FaultBitmapBW.Free;
  UniformBitmapBW.Free;
  tsUniforms[1].Free;
  tsUniforms[0].Free;

  lstInteractivePlayers.Free;
  RandGen.free;

  se_players.RemoveAllSprites ;
  se_ball.RemoveAllSprites ;
  se_interface.RemoveAllSprites ;
  se_field.RemoveAllSprites ;
  se_numbers.RemoveAllSprites ;

  TsCoa.free;
  TsCod.free;

  AnimAtionScript.Reset;
  AnimationScript.Ts.Free;
  AnimationScript.Free;
  TranslateMessages.Free;
  TsWorldCountries.Free;
  TsNationTeams.Free;

  for I := 0 to 255 do begin
    MM3[i].Free;
  end;
  CloseHandle(Mutex);

  //  If MyBrainFormation <> nil then MyBrainFormation.free;
//  if Mybrain <> nil then MyBrain.free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
{$IFDEF  tools}
 if Key = VK_F1 then
  Panel1.Visible := not Panel1.Visible

  else if Key = VK_F2 then begin
    if Panel1.Left = 0 then
      Panel1.Left := Form1.Width - Panel1.width
      else Panel1.Left:=0;

   end;
{$ENDIF}

  if (ssShift in Shift) then begin
    if (GameScreen = ScreenFormation) or (GameScreen = ScreenLiveMatch ) or (GameScreen = ScreenWatchLive )  then begin
      if lastMouseMovePlayer <> nil then
      SetupGridAttributes (SE_Grid0, lastMouseMovePlayer, 'h'  );  // history
    end;

  end;

{  if Key = 84 then begin
    if not SE_TheaterPassive.visible then
      ShowTheaterPassive
  end;}
end;
procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if not (ssShift in Shift) then begin

    if (GameScreen = ScreenFormation) or (GameScreen = ScreenLiveMatch ) or (GameScreen = ScreenWatchLive )  then begin
      if lastMouseMovePlayer <> nil then
      SetupGridAttributes (SE_Grid0, lastMouseMovePlayer, 'a'  );  // attributi
    end;
  end;


end;

procedure TForm1.SetTheaterMatchSize ;
begin
  form1.Width := 1366;
  Form1.Height := 738;
  Panel1.Left := Form1.Width - Panel1.width;
  Panel1.Top := 0;

  se_theater1.VirtualWidth := FieldCellW*16; // 12 + 4 per le riserve a sinistra e destra
  se_theater1.Virtualheight := FieldCellH*7;
  se_theater1.Width := se_theater1.VirtualWidth ;
  se_theater1.Height  := se_theater1.Virtualheight ;//960 ;
  se_theater1.Left := 320;//(form1.Width div 2) - (SE_Theater1.Width div 2);
  se_theater1.Top :=  56;//(form1.Height div 2) - (SE_Theater1.Height div 2);
  PanelSkill.Left := SE_Theater1.Left + (SE_Theater1.Width div 2) - (PanelSkill.Width div 2);
  PanelSkill.Top := SE_Theater1.Top + SE_Theater1.Height ;

end;


procedure TForm1.SE_ballSpriteDestinationReached(ASprite: SE_Sprite);
begin
//  MyBrain.Ball.Moving := False;
 //se è dentro la porta playsound gol e stadio

 if inGolPosition (ASprite.Position ) then  begin


   playsound ( pchar (dir_sound +  'net.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
   ASprite.PositionY:= ASprite.Position.Y +1; // fix sound net 2 volte
   Sleep(300);
   playsound ( pchar (dir_sound +  'gol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
 end
 else if inCrossBarPosition (ASprite.Position ) then begin
   playsound ( pchar (dir_sound +  'crossbar.wav' ) , 0, SND_FILENAME OR SND_ASYNC);

   ASprite.PositionY:= ASprite.Position.Y +1; // fix sound crossbar 2 volte
   Sleep(300);

   playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
 end
 else if inGKCenterPosition (ASprite.Position ) then begin
   playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
 end;
end;

procedure TForm1.BtnFormationBackClick(Sender: TObject);
begin
  if PanelUniform.Visible then
    Exit;

  WAITING_STOREFORMATION := True;
  GameScreen := ScreenWaitingFormation;
  SetTcpFormation;
//ShowMain;
end;

procedure TForm1.BtnFormationResetClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    GCD := GCD_DEFAULT;
    if PanelUniform.Visible then
      Exit;
    WAITING_GETFORMATION:=true;
    tcp.SendStr(  'resetformation' + endofline);
  end;

end;

procedure TForm1.BtnFormationUniformClick(Sender: TObject);
begin
  if PanelUniform.Visible then
    Exit;

  PanelUniform.Left := (PanelBack.Width div 2) - (PanelUniform.width div 2);
  PanelUniform.Top := (PanelBack.height div 2) - (PanelUniform.height div 2);
  PanelUniform.Visible:= True;

  // mostro subito in casa lo schema scelto
  btn_UniformHome.Down := True;
  btn_Schema [ StrToInt ( TSUniforms[0][3] ) ].Down := True;
  Btn_UniformHomeClick(Btn_UniformHome);
end;

procedure TForm1.SE_GridSkillGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
  Sprite: SE_Sprite);
var
  aDoor: TPoint;
begin
{  LstSkill[0]:= 'Move';
  LstSkill[1]:= 'Short.Passing';
  LstSkill[2]:= 'Lofted.Pass';
  LstSkill[3]:= 'Crossing';
  LstSkill[4]:= 'Precision.Shot';
  LstSkill[5]:= 'Power.Shot';
  LstSkill[6]:= 'Dribbling';
  LstSkill[7]:= 'Protection';
  LstSkill[8]:= 'Tackle';
  LstSkill[9]:= 'Pressing';
  LstSkill[10]:= 'Corner.Kick'; }
  if se_players.IsAnySpriteMoving or se_ball.IsAnySpriteMoving   then  exit;
  panelSkill.Visible := False;

  if se_gridskill.Cells [0,CellY].Ids = 'Move' then begin
          MouseWaitFor  :=  WaitForXY_Move;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Short.Passing' then begin
          MouseWaitFor  :=  WaitForXY_ShortPass;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Lofted.Pass' then begin
          MouseWaitFor  :=  WaitForXY_LoftedPass;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Crossing' then begin

    if GCD <= 0 then begin
          MouseWaitFor  :=  WaitForXY_Crossing;

          if MyBrain.w_FreeKick2 then begin   // in caso di freeKick2 il cross è automatico
            MouseWaitFor := WaitForNone;
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'CRO2' + EndofLine);
            hidechances;
          end;
          GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Precision.Shot' then begin
    if GCD <= 0 then begin
          MouseWaitFor := WaitForNone;
          aDoor:= MyBrain.GetOpponentDoor (SelectedPlayer );
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PRS'  + EndofLine);
            hidechances;
           GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Power.Shot' then begin
    if GCD <= 0 then begin
          MouseWaitFor := WaitForNone;
          aDoor:= MyBrain.GetOpponentDoor (SelectedPlayer );
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'POS' + EndofLine);
          hidechances;
          GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Dribbling' then begin
          MouseWaitFor := WaitForNone;
          MouseWaitFor := WaitForXY_Dribbling;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Protection' then begin
    if GCD <= 0 then begin
          MouseWaitFor := WaitForNone;
          if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PRO'  + EndofLine);
          GCD := GCD_DEFAULT;
          hidechances;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Tackle' then begin
    if GCD <= 0 then begin
          MouseWaitFor := WaitForNone;
          if Mybrain.Ball.Player <> nil then begin
            if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin
              // Tackle può portare anche ai falli e relativi infortuni e cartellini. Un tackle da dietro ha alte possibilità di generare un fallo
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'TAC' + ',' + SelectedPlayer.Ids  + EndofLine);
                  hidechances;
            end;
          end;
      GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Pressing' then begin
    if GCD <= 0 then begin
          MouseWaitFor := WaitForNone;
          if Mybrain.Ball.Player <> nil then begin
            if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PRE,' + SelectedPlayer.Ids  + EndofLine);
                  hidechances;
            end;
          end;
     GCD := GCD_DEFAULT;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Corner.Kick' then begin
         // non più usata
    if GCD <= 0 then begin
          MouseWaitFor := WaitForNone;
          // sul brain iscof batterà il corner
            if  ( LiveMatch ) and  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'COR' + EndofLine);
            GCD := GCD_DEFAULT;
            hidechances;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Pass' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'PASS'+ EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Stay' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) and  ( not SelectedPlayer.stay)
         then tcp.SendStr( 'STAY,' + SelectedPlayer.Ids  + EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'Free' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) and  ( SelectedPlayer.stay)
        then tcp.SendStr( 'FREE,' + SelectedPlayer.Ids + EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'BuffD' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam)
        then tcp.SendStr( 'BUFFD,' + SelectedPlayer.Ids + EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'BuffM' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam)
        then tcp.SendStr( 'BUFFM,' + SelectedPlayer.Ids + EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end
  else if se_gridskill.Cells [0,CellY].Ids = 'BuffF' then begin
    if GCD <= 0 then begin
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam)
        then tcp.SendStr( 'BUFFF,' + SelectedPlayer.Ids + EndOfLine);
      GCD := GCD_DEFAULT;
      hidechances;
    end;
  end;


end;

procedure TForm1.SE_GridSkillGridCellMouseMove(Sender: TObject; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
var
  aSeField : SE_Sprite;
  y: integer;
begin
  // se ho già cliccato sulla skill passando sul mouse sopra ad un'altyra skill non creo i circle
  case MousewaitFor of
    WaitForXY_ShortPass: exit ;
    WaitForXY_LoftedPass: exit;
    WaitForXY_Crossing: exit;
    WaitForXY_Move: exit;
    WaitForXY_Dribbling: exit;
{    WaitFor_Corner: ;
    WaitForNone: ;
    WaitForAuth: ;
    WaitForXY_PowerShot: ;
    WaitForXY_PrecisionShot: ;
    WaitForXY_FKF1: ;
    WaitForXY_FKF2: ;
    WaitForXY_FKA2: ;
    WaitForXY_FKD2: ;
    WaitForXY_FKF3: ;
    WaitForXY_FKD3: ;
    WaitForXY_FKF4: ;
    WaitForXY_CornerCOF: ;
    WaitForXY_CornerCOA: ;
    WaitForXY_CornerCOD: ;  }
  end;

  if (CellX = se_gridskilloldCol) and (CellY = se_gridskilloldRow) then Exit;
  se_gridskilloldCol := CellX;
  se_gridskilloldRow := CellY;

  SE_interface.RemoveAllSprites;
  HighLightFieldFriendly_hide;

  for y := 0 to SE_GridSkill.RowCount -1 do begin
    SE_GridSkill.Cells[0,y].BackColor := $007B5139;
    SE_GridSkill.Cells[0,y].FontColor := clyellow; // $0041BEFF;
    SE_GridSkill.Cells[1,y].BackColor := $007B5139;
    SE_GridSkill.Cells[1,y].FontColor  := clyellow; //$0041BEFF;
  end;


  SE_GridSkill.Cells [0,CellY].BackColor := clblack;
  SE_GridSkill.Cells [1,CellY].BackColor := clblack;
  SE_GridSkill.Cells [0, CellY ].FontColor := $0041BEFF;
  SE_GridSkill.Cells [1, CellY ].FontColor := $0041BEFF;


  SE_GridSkill.CellsEngine.ProcessSprites(2000);
  SE_GridSkill.refreshSurface ( SE_GridSkill );


  if se_gridskill.Cells[0,CellY].Ids = 'Precision.Shot' then
    PrsMouseEnter ( nil )
  else if se_gridskill.Cells[0,CellY].Ids = 'Power.Shot' then
    PosMouseEnter ( nil );



end;

procedure TForm1.SE_GridXP0GridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
  Sprite: SE_Sprite);
begin

  if GCD <= 0 then begin
    GCD := GCD_DEFAULT;
    if se_gridxp0.cells [ CellX, CellY ].BackColor = clgray then begin  // clgray indica che può passare di livello
      WAITING_GETFORMATION:= True;
      case CellY of
        0: begin
          tcp.SendStr( 'levelupattribute,'+ se_gridxp0.SceneName + ',0'  + EndofLine);
        end;
        1: begin
          tcp.SendStr( 'levelupattribute,'+ se_gridxp0.SceneName + ',1'  + EndofLine);
        end;
        2: begin
          tcp.SendStr( 'levelupattribute,'+ se_gridxp0.SceneName + ',2'  + EndofLine);
        end;
        3: begin
          tcp.SendStr( 'levelupattribute,'+ se_gridxp0.SceneName + ',3'  + EndofLine);
        end;
        4: begin
          tcp.SendStr( 'levelupattribute,'+ se_gridxp0.SceneName + ',4'  + EndofLine);
        end;
        5: begin
          tcp.SendStr( 'levelupattribute,'+ se_gridxp0.SceneName + ',5'  + EndofLine);
        end;
        // 6 vuota
        7..23: begin
          tcp.SendStr( 'leveluptalent,'+ se_gridxp0.SceneName + ',' + IntTostr (CellY - 6) + EndofLine); // i talenti qui sotto
        end;
      end;
    end;
  end;

end;


procedure TForm1.SE_GridXP0GridCellMouseMove(Sender: TObject; Shift: TShiftState; CellX, CellY: Integer; Sprite: SE_Sprite);
var
  a,b: Integer;
  Ts:TStringList;
begin
  if Length ( SE_GridXP0.Cells[1,CellY].Text) >= 5 then  begin

    ts := TStringList.Create;
    ts.Delimiter := '/';
    ts.StrictDelimiter:= True;
    ts.DelimitedText := SE_GridXP0.Cells[1,CellY].text;

    a := StrToInt(ts[0]);
    b := StrToInt(ts[1]);
    if a >= b then begin

      SE_GridXP0.Cursor := crHandPoint;
//      Cursor := crHandPoint;

    end
    else SE_GridXP0.Cursor := crDefault;

    ts.Free;

  end;
end;

procedure TForm1.InitializeTheaterMatch;
var
  i: Integer;
begin
  se_theater1.Active := False;
  for I := 0 to se_theater1.EngineCount -1 do begin
    se_Theater1.Engines [i].RemoveAllSprites ;
  end;
  SetTheaterMatchSize;
  createField;
//  CreateHiddenField;
  se_Theater1.Visible := True;
  se_Theater1.Active := True;
  SE_GridTime.Active := True;
  //SE_GridDice.Active := True;

end;

procedure TForm1.InitializeTheaterFormations;
var
  i: Integer;
begin
  se_theater1.Active := False;
  for I := 0 to se_theater1.EngineCount -1 do begin
    se_Theater1.Engines [i].RemoveAllSprites ;
  end;
  SetTheaterMatchSize;
  createField;
//  CreateHiddenField;
  se_Theater1.sceneName := 'tactics';
  se_theater1.Active := true;
  se_Theater1.Visible := True;
  SE_GridXP0.Active := True;
  SE_GridDice.Active := false;
  PanelFormation.Visible := True;

end;
function TForm1.softlight(aColor:Tcolor): TColor;
var
  aRGB: TRGB;
begin
  aRGB := TColor2TRGB(aColor);
  aRGB.b:=  i_softlight( aRGB.b,aRGB.b);
  aRGB.g:=  i_softlight( aRGB.g,aRGB.g);
  aRGB.r:=  i_softlight( aRGB.r,aRGB.r);
  result := TRGB2TColor ( aRGB );
end;
function TForm1.DarkColor(aColor: TColor): TColor;
var
  aRGB: TRGB;
  rr: integer;
begin
  if aColor= clblack then begin
   Result:=aColor;
  end
  else if aColor= clWhite then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 214;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clGray then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 87;
    aRGB.g := 87;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clRed then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 0;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= $004080FF then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 87;
    aRGB.b := 53;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clyellow then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 214;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clGreen then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 0;
    aRGB.g := 87;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clLime then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 0;
    aRGB.g := 214;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clAqua then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 0;
    aRGB.g := 214;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clBlue then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 0;
    aRGB.g := 0;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= $00FF0080 then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 87;
    aRGB.g := 0;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= $00FF80FF then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 214;
    aRGB.g := 87;
    aRGB.b := 214;
    Result := TRGB2TColor(aRGB);
  end
  else if aColor= clMaroon then begin
    aRGB := TColor2TRGB ( aColor);
    aRGB.r := 87;
    aRGB.g := 0;
    aRGB.b := 0;
    Result := TRGB2TColor(aRGB);
  end;



end;

function TForm1.i_softlight(ib, ia: integer): integer;
var
  a, b, r: double;
begin
  a := ia / 255;
  b := ib / 255;
  if b < 0.5 then
    r := 2 * a * b + sqr(a) * (1 - 2 * b)
  else
    r := sqrt(a) * (2 * b - 1) + (2 * a) * (1 - b);
  result := trunc(r * 255);
end;
procedure TForm1.PreloadUniform( ha:Byte;  UniformSchemaIndex: integer);
var
  s,x,y: Integer;
  tmpSchema : SE_Bitmap;
begin
  tmpSchema := SE_Bitmap.Create;

    for s := 0 to Schemas -1 do begin
      tmpSchema.LoadFromFileBMP( dir_player + 'schema' + IntToStr(s) + '.bmp' );
      for x := 0 to tmpSchema.Width-1 do begin
        for y := 0 to tmpSchema.height-1 do begin
          if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clRed then
            tmpSchema.Bitmap.Canvas.Pixels [x,y] := StringToColor ( CnColorgrid1.CustomColors [  StrToInt(TsUniforms[ha][0])])  //<-- se fuori casa prende la maglia giusta
          else if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clBlue then
            tmpSchema.Bitmap.Canvas.Pixels [x,y] := StringToColor ( CnColorgrid1.CustomColors [  StrToInt(TsUniforms[ha][1])])  //<-- se fuori casa prende la maglia giusta
          else if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clBlack then
            tmpSchema.Bitmap.Canvas.Pixels [x,y] := StringToColor ( CnColorgrid1.CustomColors [  StrToInt(TsUniforms[ha][2])]);  //<-- se fuori casa prende la maglia giusta
        end;
      end;

      // se è lo schema selezionato lo salvo come color0 o color1 prima dello stretch
      if s = UniformSchemaIndex then begin
        btn_Schema[s].Down := True;
        tmpSchema.Bitmap.SaveToFile(dir_tmp + 'color' + IntToStr(ha) + '.bmp');
      end;
      // stretch in base a ScaleSprites e width e Height del TcnButton
      tmpSchema.Stretch (    (ScaleSprites * btn_Schema[s].Width ) div 100, (ScaleSprites * btn_Schema[s].Height ) div 100);
      tmpSchema.Bitmap.SaveToFile(dir_tmp + 'schema' + IntToStr(s) + '.bmp'); // salvo i 4 o più schemi
      btn_Schema[s].Glyph.LoadFromFile( dir_tmp + 'schema' + IntToStr(s) + '.bmp');

    end;

    tmpSchema.Free;
end;
procedure TForm1.PreloadUniformGK( ha:Byte;   UniformSchemaIndex: Integer);
var
  s,x,y: Integer;
  tmpSchema : SE_Bitmap;
begin
  tmpSchema := SE_Bitmap.Create;

    for s := 0 to Schemas -1 do begin

      tmpSchema.LoadFromFileBMP( dir_player + 'schema' + IntToStr(s) +'.bmp' );
      for x := 0 to tmpSchema.Width-1 do begin
        for y := 0 to tmpSchema.height-1 do begin
          if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clRed then
            tmpSchema.Bitmap.Canvas.Pixels [x,y] := ClGray
          else if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clBlue then
            tmpSchema.Bitmap.Canvas.Pixels [x,y] := clGray
          else if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clBlack then
            tmpSchema.Bitmap.Canvas.Pixels [x,y] := clBlack ;
        end;
      end;

      // se è lo schema selezionato lo salvo come colorGK prima dello stretch
      if s = UniformSchemaIndex then begin
        btn_Schema[s].Down := True;
        tmpSchema.Bitmap.SaveToFile(dir_tmp + 'colorgk.bmp');
      end;
      // stretch in base a ScaleSprites e width e Height del TcnButton
      tmpSchema.Stretch (    (ScaleSprites * btn_Schema[s].Width ) div 100, (ScaleSprites * btn_Schema[s].Height ) div 100);
      tmpSchema.Bitmap.SaveToFile(dir_tmp +  'schemagk' + IntToStr(s) + '.bmp'); // salvo i 4 o più schemi
      btn_Schema[s].Glyph.LoadFromFile( dir_tmp  + 'schemagk' + IntToStr(s) + '.bmp');

    end;
    tmpSchema.Free;

end;
procedure TForm1.ColorizeFault( Team:Byte;  var FaultBitmap: SE_Bitmap);
var
  x,y: Integer;
begin
(* mantengo x per i 2 colori *)
    for x := 0 to FaultBitmap.Width-1 do begin
      for y := 0 to FaultBitmap.height-1 do begin

        if x > 19 then begin


             // maglia 1
            if FaultBitmapBW.Bitmap.Canvas.Pixels[x,y] = clBlack then
              FaultBitmap.Bitmap.Canvas.Pixels [x,y] := StringToColor (  CnColorgrid1.CustomColors [  StrToInt(TsUniforms[Team][0])]);


        end

        else begin  // schiarisco

             // maglia 2
            if FaultBitmapBW.Bitmap.Canvas.Pixels[x,y] = clBlack then
              FaultBitmap.Bitmap.Canvas.Pixels [x,y] := StringToColor (  CnColorgrid1.CustomColors [  StrToInt(TsUniforms[Team][1])]);

        end;


      end;
    end;

//    FaultBitmap.Bitmap.SaveToFile(dir_tmp + 'color.bmp');
end;
procedure TForm1.ColorizeArrowCircle( Team:Byte;  ShapeBitmap: SE_Bitmap);
var
  x,y: Integer;
begin
(* mantengo x per i 2 colori *)
    for x := 0 to ShapeBitmap.Width-1 do begin
      for y := 0 to ShapeBitmap.height-1 do begin

        if x > (ShapeBitmap.Width div 2) then begin


             // maglia 1
            if ShapeBitmap.Bitmap.Canvas.Pixels[x,y] = clBlack then begin
              ShapeBitmap.Bitmap.Canvas.Pixels [x,y] := StringToColor (  CnColorgrid1.CustomColors [  StrToInt(TsUniforms[Team][0])]);
              if ShapeBitmap.Bitmap.Canvas.Pixels [x,y] = clWhite then  // fix maglia bianca non trasparente
                ShapeBitmap.Bitmap.Canvas.Pixels [x,y] := clwhite -1

            end;

        end

        else begin

             // maglia 2
            if ShapeBitmap.Bitmap.Canvas.Pixels[x,y] = clBlack then begin
              ShapeBitmap.Bitmap.Canvas.Pixels [x,y] := StringToColor (  CnColorgrid1.CustomColors [  StrToInt(TsUniforms[Team][1])]);
              if ShapeBitmap.Bitmap.Canvas.Pixels [x,y] = clWhite then   // fix maglia bianca non trasparente
                ShapeBitmap.Bitmap.Canvas.Pixels [x,y] := clwhite -1
            end;
        end;


      end;
    end;

end;
procedure TForm1.ClientLoadFormation ;
var
  i,x,y: Integer;
  count: Byte;
  aPlayer: TSoccerPlayer;
  guid,age,Matches_Played,Matches_Left,stamina,Injured, yellowcard, Disqualified,Cur,lenSurname,LenHistory,LenXP,onmarket,face: Integer;
  rank: Byte;
  AIFormation_x,AIFormation_y: ShortInt;
  lenteamName, lenUniformH,lenUniformA : Integer;
  Surname, talent : string;
  DisqualifiedSprite, InjuredSprite, YellowSprite: se_SubSprite;
  aMirror: TPoint;
  FC: TFormationCell;
  TvCell,TvReserveCell: TPoint;
//  aCell: TSoccerCell;
  bmp: se_BITMAP;
  aSEField: SE_Sprite;
  SS: TStringStream;
  dataStr, Attributes,tmps : string;
  GraphicSe: boolean;
  TalentID1,TalentID2: Byte;
  TsHistory,tsXP: TStringList;
  DefaultSpeed,DefaultDefense,DefaultPassing,DefaultBallControl  ,DefaultShot,DefaultHeading: Byte;
  UniformBitmap,UniformBitmapGK:SE_Bitmap;
  aColor: TColor;
  IndexTal: Integer;
  LocalHA : string;
procedure setupBMp (bmp:TBitmap; aColor: Tcolor);
begin
  BMP.Canvas.Font.Size := 8;
  BMP.Canvas.Font.Quality := fqAntiAliased;
  BMP.Canvas.Font.Color := aColor;
  BMP.Canvas.Font.Style :=[fsbold];
  BMP.Canvas.Brush.Style:= bsClear;
end;
begin


  if  WAITING_GETFORMATION then begin
    WAITING_GETFORMATION := False;
    fGameScreen := ScreenFormation;
    GraphicSE:= True;
  end
  else if  WAITING_STOREFORMATION then begin
    WAITING_STOREFORMATION := False;
    GameScreen := ScreenMain;
    GraphicSE:= false;
  end;

  // MM3 e buf3 contengono il buffer del team
  TotMarket := 0;

  MyBrainFormation.ClearReserveSlot;
  MyBrainFormation.lstSoccerPlayer.Clear;

  SS:= TStringStream.Create;
  SS.Size := MM3[0].Size;
  Mm3[0].Position := 0;
  SS.CopyFrom( MM3[0], MM3[0].size );
  dataStr := SS.DataString;
  SS.Free;

  Cur := 0;
  MyGuidTeam:= PDWORD(@buf3 [0][ cur ])^;
  Cur := Cur + 4;
  lenteamName :=  Ord( buf3[0] [ cur ]);
  MyGuidteamName := MidStr( dataStr, cur + 2  , lenteamName );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
  cur  := cur + lenteamName + 1;

  lenUniformH :=  Ord( buf3[0] [ cur ]);
  tmps := MidStr( dataStr, cur + 2  , lenUniformH );
  TsUniforms[0].CommaText := tmps;


  cur  := cur + lenUniformH + 1;
  lenUniformA :=  Ord( buf3[0] [ cur ]);
  tmps := MidStr( dataStr, cur + 2  , lenUniformA );
  TsUniforms[1].CommaText := tmps;

  cur  := cur + lenUniformA + 1;
  NextHa :=  Ord( buf3[0] [ cur ]); // prossima partita in cas o fuori (home,away)
  Cur := Cur + 1;
  mi :=  PDWORD(@buf3[0] [ cur ])^; // media inglese
  Cur := Cur + 4;
  points :=  PDWORD(@buf3[0] [ cur ])^; // punti classifica
  Cur := Cur + 4;
  MatchesPlayedTeam :=  PDWORD(@buf3[0] [ cur ])^; // totale partite giocate
  Cur := Cur + 4;
  Money :=  PDWORD(@buf3[0] [ cur ])^; // denaro del team
  Cur := Cur + 4;
  Rank :=  Ord( buf3[0] [ cur ]);     // rank del team
  Cur := Cur + 1;
  lbl_TeamName.Caption := MyGuidteamName;
  lbl_MIF.Caption := Translate('lbl_MI')  + ' ' + IntToStr(mi);
  lbl_RankF.Caption := Translate('lbl_Rank') + ' ' + IntToStr(rank);
  lbl_pointsF.Caption := Translate('lbl_Points') + ' ' + IntToStr(points);
  lbl_TurnF.Caption := Translate('lbl_NextTurn') + ' ' + IntToStr(MatchesPlayedTeam+1) + '/38' ;
  lbl_MoneyF.Caption := Translate('lbl_Money') + ' ' + IntToStr(Money)  ;


  if GraphicSE then begin

    PreLoadUniform(NextHa, StrToInt( tsUniforms[NextHa][3] ));  // crea 4 schemas bmp ma salva come color quello selezionato

    if btn_UniformHome.down then  // IntToStr(NextHa)
      localHA := '0'
    else
      localHA := '1';
    UniformBitmap := SE_Bitmap.Create (dir_tmp + 'color' + localHA + '.bmp'); // carico la base red-blue-black

    Portrait0.Glyph.LoadFromFile(dir_tmp + 'color' + localHA +'.bmp');

//    if NextHa = 0 then
 //     btn_UniformHome.Down:= True
 //     else
 //       btn_UniformAway.Down:= True;
 //   btn_Schema [ StrToint (tsUniforms[NextHa][3]) ].Down := True;

    PreLoadUniformGK(StrToInt (LocalHA),  StrToInt( tsUniforms[ StrToInt(LocalHa)  ][3]));
    UniformBitmapGK := SE_Bitmap.Create (dir_tmp + 'colorgk.bmp');
  end;

  MyBrain.Score.DominantColor[0]:= StrToInt( TsUniforms[0][0] );
  if TsUniforms[0][0] = TsUniforms[0][1] then
    MyBrain.Score.FontColor[0]:= GetContrastColor(  StrToInt(TsUniforms[0][0]) )
    else MyBrain.Score.FontColor[0]:= StrToInt( TsUniforms[0][1] );

  MyBrain.Score.DominantColor[1]:= StrToInt( TsUniforms[1][0] );
  if TsUniforms[1][0] = TsUniforms[1][1] then
    MyBrain.Score.FontColor[1]:= GetContrastColor(  StrToInt(TsUniforms[1][0]) )
    else MyBrain.Score.FontColor[1]:= StrToInt( TsUniforms[1][1] );


  count := ord (buf3[0] [ cur ]);   // quanti player
  Cur := Cur + 1; //
  //PDWORD(@buf3[0] [ cur ])^;
    for I := 0 to count -1 do begin
      guid :=  PDWORD(@buf3[0] [ cur ])^; // player identificativo globale
      Cur := Cur + 4;
      lenSurname :=  Ord( buf3[0] [ cur ]);
      Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
      cur  := cur + lenSurname + 1;

      Matches_Played := PWORD(@buf3[0] [ cur ])^;  // partite giocate dle player
      Cur := Cur + 2 ;
      Matches_Left := PWORD(@buf3[0] [ cur ])^;    // partite rimanenti prima di finire la carriera
      Cur := Cur + 2 ;
      Age :=  Ord( buf3[0] [ cur ]);               // età
      Cur := Cur + 1 ;
      TalentID1 := Ord( buf3[0] [ cur ]);           // identificativo talento
      Cur := Cur + 1;
      TalentID2 := Ord( buf3[0] [ cur ]);           // identificativo talento
      Cur := Cur + 1;

      Stamina := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;

      DefaultSpeed := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultDefense := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultPassing := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultBallControl := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultShot := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      DefaultHeading := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      Attributes:= IntTostr( DefaultSpeed) + ',' + IntTostr( DefaultDefense) + ',' + IntTostr( DefaultPassing) + ',' + IntTostr( DefaultBallControl) + ',' +
                   IntTostr( DefaultShot) + ',' + IntTostr( DefaultHeading) ;

      AIFormation_x := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      AIFormation_y := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      injured := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      yellowcard := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      disqualified := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      onmarket := Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      face :=  PDWORD(@buf3[0] [ cur ])^; // face bmp viso
      Cur := Cur + 4;


      aPlayer:= TSoccerPlayer.create(0,MyGuidTeam,Matches_Played,IntToStr(guid),'',surname,Attributes,TalentID1,TalentID2);
      aPlayer.TalentId1 := TalentID1;
      aPlayer.TalentId2 := TalentID2;
      aPlayer.GuidTeam := MyguidTeam;
      aPlayer.Stamina := Stamina;
      aPlayer.AIFormationCellX := AIFormation_x;
      aPlayer.AIFormationCellY := AIFormation_y;
      aPlayer.Injured := injured;
      aPlayer.yellowcard := yellowcard;
      aPlayer.Disqualified := Disqualified;
      aPlayer.onmarket := Boolean( onmarket);
      TotMarket := TotMarket + onmarket;
      aPlayer.face := face;

      if GraphicSE then begin

        if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
          aPlayer.SE_Sprite := se_Players.CreateSprite(UniformBitmap.Bitmap , aPlayer.Ids,1,1,1000,0,0,true)
        else
          aPlayer.SE_Sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , aPlayer.Ids,1,1,1000,0,0,true);

        aPlayer.SE_Sprite.Scale := ScaleSprites;
        AddFace ( aPlayer );
        aPlayer.se_sprite.ModPriority := i+2;
      end;

      tsHistory := TStringList.Create;
      LenHistory :=  Ord( buf3[0] [ cur ]);
      tsHistory.commaText := MidStr( dataStr, cur + 2  , LenHistory );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
      cur  := cur + LenHistory + 1;
//      tsHistory.commaText := ini.readString('player' + IntToStr(i),'History','0,0,0,0,0,0' ); // <-- 6 attributes
      aPlayer.History_Speed         := StrToInt( tsHistory[0]);
      aPlayer.History_Defense       := StrToInt( tsHistory[1]);
      aPlayer.History_Passing       := StrToInt( tsHistory[2]);
      aPlayer.History_BallControl   := StrToInt( tsHistory[3]);
      aPlayer.History_Shot          := StrToInt( tsHistory[4]);
      aPlayer.History_Heading       := StrToInt( tsHistory[5]);
      tsHistory.Free;

      tsXP := TStringList.Create;
      LenXP :=  Ord( buf3[0] [ cur ]);
 //     tsXP.commaText := ini.readString('player' + IntToStr(i),'xp','0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0' ); // <-- 6 attributes , 17 talenti
      tsXP.commaText := MidStr( dataStr, cur + 2  , LenXP );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
      cur  := cur + LenXP + 1;

      // rispettare esatto ordine dei talenti sul db
      aPlayer.xp_Speed         := aPlayer.xp_Speed + StrToInt( tsXP[0]);
      aPlayer.xp_Defense       := aPlayer.xp_Defense + StrToInt( tsXP[1]);
      aPlayer.xp_Passing       := aPlayer.xp_Passing + StrToInt( tsXP[2]);
      aPlayer.xp_BallControl   := aPlayer.xp_BallControl + StrToInt( tsXP[3]);
      aPlayer.xp_Shot          := aPlayer.xp_Shot + StrToInt( tsXP[4]);
      aPlayer.xp_Heading       := aPlayer.xp_Heading + StrToInt( tsXP[5]);

      for IndexTal := 1 to NUM_TALENT do begin
        aPlayer.xpTal[IndexTal]:=aPlayer.xpTal[IndexTal] + StrToInt( tsXP[IndexTal+5])
      end;

      tsXP.Free;


      MyBrainFormation.AddSoccerPlayer(aPlayer); // uso anche questa lista per trovare gli sprite inKeyDown
      if MyBrainFormation.isReserveSlot  ( AIFormation_x,AIFormation_y )  then begin // le riserve tutte a sinistra

          TvReserveCell:= MyBrainFormation.ReserveSlotTV [0,AIFormation_x,AIFormation_y  ];
          MyBrainFormation.PutInReserveSlot(aPlayer) ;

          if GraphicSE then begin

            aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.X ) + '.' + IntToStr (TvReserveCell.Y ));
            aPlayer.se_Sprite.Position := aSEField.Position;
          end;


      end
      else begin // player normali
        TvCell := MyBrainFormation.AIField [0,AIFormation_x,AIFormation_y];  // traduce solo celle del campo

        if GraphicSE then begin
          aSEField := SE_field.FindSprite(IntToStr (TvCell.X ) + '.' + IntToStr (TvCell.Y ));
          aPlayer.se_Sprite.Position := aSEField.Position;
        end;
        aPlayer.Cells := TvCell;
        aPlayer.DefaultCells := TvCell;

      end;


      if GraphicSE then begin
        if  aPlayer.YellowCard > 0  then begin
          YellowSprite := se_SubSprite.create (dir_interface + 'yellow.bmp','yellow', 0,0,true,true);
          setupBMp (YellowSprite.lBmp.Bitmap , clBlack );
          YellowSprite.lBmp.Bitmap.Canvas.TextOut(0,0, IntToStr(aPlayer.YellowCard));
          aPlayer.SE_Sprite.SubSprites.Add( YellowSprite ) ;
        end;
        if aPlayer.disqualified > 0 then begin
          DisqualifiedSprite := se_SubSprite.create ( dir_interface + 'disqualified.bmp','disqualified', 0,0,true,true);
          setupBMp (DisqualifiedSprite.lBmp.Bitmap , clWhite );
          DisqualifiedSprite.lBmp.Bitmap.Canvas.TextOut(3,0, IntToStr(aPlayer.disqualified));
          aPlayer.SE_Sprite.SubSprites.Add( DisqualifiedSprite ) ;
        end;
        if aPlayer.injured > 0  then begin
          InjuredSprite := se_SubSprite.create (dir_interface + 'injured.bmp','injured', 0,0,true,true);
          setupBMp (InjuredSprite.lBmp.Bitmap , clMaroon );
          InjuredSprite.lBmp.Bitmap.Canvas.TextOut(0,0, IntToStr(aPlayer.Injured));
          aPlayer.SE_Sprite.SubSprites.Add( InjuredSprite ) ;
        end;
      end;
    end;

    if GraphicSE then
      UniformBitmap.Free;

    RefreshCheckFormationMemory;

end;
procedure TForm1.CreateNoiseTV;    // https://www.youtube.com/watch?v=BB7jEHPBf-4
var
  bmp:SE_Bitmap;
  aSprite: SE_Sprite;
  AString: string;
begin
  btnsell0.Visible := false;
  btnXp0.Visible := false;
  btndismiss0.Visible:= false;

  SE_field.RemoveAllSprites;
  SE_players.RemoveAllSprites;
  SE_interface.RemoveAllSprites;
  aSprite:=SE_interface.CreateSprite( dir_interface + 'noiseTV.bmp' , 'noiseTV' ,4,1, 10, (SE_Theater1.VirtualWidth div 2), (SE_Theater1.Virtualheight div 2) ,false );
  aSprite.Scale := 160;
  AString :=  Translate( 'lbl_waitingwatchlive');
  bmp:=SE_Bitmap.Create(300,200);
  bmp.bitmap.Canvas.font.Name := 'calibri';
  bmp.bitmap.Canvas.font.Size  := 16;
  bmp.bitmap.Canvas.font.Style := [fsBold];
  bmp.bitmap.Canvas.font.Color := clWhite-1;
  bmp.Width := bmp.Bitmap.Canvas.TextWidth(  AString );
  bmp.Height := bmp.Bitmap.Canvas.Textheight( AString);
  bmp.bitmap.Canvas.TextOut(0,0,AString);

  if (GameScreen  = ScreenWaitingLiveMatch)  or (GameScreen = ScreenWaitingWatchLive) then begin  // in caso di waitingformation non c'è  cancel
    aSprite := SE_interface.CreateSprite( bmp.bitmap, 'waitingsignal',1,1,1000, (SE_Theater1.VirtualWidth div 2), SE_Theater1.Virtualheight  - 50 , true   );
    aSprite.Priority := 10;
    bmp.Free;
    AString :=  Translate( 'lbl_Cancel');
    bmp:=SE_Bitmap.Create(88,22);
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
    bmp.bitmap.Canvas.font.Name := 'calibri';
    bmp.bitmap.Canvas.font.Size  := 12;
    bmp.bitmap.Canvas.font.Style := [fsBold];
    bmp.bitmap.Canvas.font.Color := $0041BEFF;
    bmp.Width := bmp.Bitmap.Canvas.TextWidth(  AString );
    bmp.Height := bmp.Bitmap.Canvas.Textheight( AString);
    bmp.bitmap.Canvas.TextOut(0,0,AString);

    aSprite := SE_interface.CreateSprite( bmp.bitmap, 'cancel',1,1,1000, (SE_Theater1.VirtualWidth div 2), SE_Theater1.Virtualheight  - 30 , false   );
    aSprite.Priority := 10;
    bmp.Free;
  end;
  SE_interface.ClickSprites := True;
end;
procedure TForm1.Createfield;
var
  x,y: Integer;
  bmp: se_BITMAP;
  aSEField: SE_Sprite;
  aSubSprite: SE_subSprite;
begin
  SE_field.RemoveAllSprites;
  for x := -2 to 13 do begin
    for y := 0 to 6 do begin
      if IsOutSide(X,Y) then begin
        bmp:= se_bitmap.Create(FieldCellW,FieldCellH);
        bmp.Bitmap.Canvas.Brush.Color :=  $7B5139;
        bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
        aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),false );
        bmp.Free;
      end
      else begin
        bmp:= se_bitmap.Create(FieldCellW,FieldCellH);      // disegno le righe
        bmp.Bitmap.Canvas.Brush.Color :=  $328362;
        bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
        RoundBorder (bmp.Bitmap , bmp.Width , bmp.Height);
        if (x = 1) and ( y= 2) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 2) and ( y= 2) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 1) and ( y= 4) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,bmp.Height-1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 2) and ( y= 4) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,bmp.Height-1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            bmp.Bitmap.Canvas.MoveTo(bmp.Width-1 ,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 2) and ( y= 3) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(bmp.Width-1 ,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 10) and ( y= 2) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 9) and ( y= 2) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,1);
            bmp.Bitmap.Canvas.MoveTo(1,1);
            bmp.Bitmap.Canvas.LineTo(1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 10) and ( y= 4) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,bmp.Height-1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 9) and ( y= 4) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1,bmp.Height-1);
            bmp.Bitmap.Canvas.LineTo(bmp.Bitmap.Width -1 ,bmp.Height-1);
            bmp.Bitmap.Canvas.MoveTo(1 ,1);
            bmp.Bitmap.Canvas.LineTo(1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 9) and ( y= 3) then begin
            bmp.Bitmap.Canvas.pen.Color :=  clwhite;
            bmp.Bitmap.Canvas.MoveTo(1 ,1);
            bmp.Bitmap.Canvas.LineTo(1 ,bmp.Height-1);
            aSEField:= SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        end
        else if (x = 0) and ( y= 3) then begin
            aSEField:= SE_field.CreateSprite( dir_stadium + 'door.bmp', IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
            aSEField.Scale := ScaleSprites;
        end
        else if (x = 11) and ( y= 3) then begin
            aSEField := SE_field.CreateSprite( dir_stadium + 'door.bmp', IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
            aSEfield.Flipped:= True;
            aSEField.Scale := ScaleSprites;
        end
        else
          aSEField := SE_field.CreateSprite( bmp.Bitmap, IntToStr(x)+'.'+IntToStr(y) ,1,1,1000, ((x+2)*bmp.Width)+(bmp.Width div 2) ,((y)*bmp.Height)+(bmp.height div 2),true  );
        bmp.Free;
      end;

      // aggiungo il subsprite
      bmp:= se_bitmap.Create(FieldCellW-4,FieldCellH-4);      // disegno le righe
      bmp.Bitmap.Canvas.Brush.Color :=  $48A881;//$3E906E;
      bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
      aSubSprite := SE_SubSprite.create(bmp,'highlight', 2, 2, false, false );
      aSEField.SubSprites.Add(aSubSprite);
      bmp.Free;

    end;
  end;


end;
procedure TForm1.CreateFieldPoints;
var
  AFieldPoint: TFieldPoint;
begin
  // le 2 porte devono essere oggetti a parte. il gk deve stare sotto la traversa. Oppure il gk davanti alla porta
  // effetti speciali: i guanti del portiere. il calcio dei cerchi

  FieldPoints := TObjectList<TFieldPoint>.Create(True);
  FieldPointsReserve := TObjectList<TFieldPoint>.Create(True);
  FieldPointsCorner := TObjectList<TFieldPoint>.Create(True);
  FieldPointsPenalty := TObjectList<TFieldPoint>.Create(True);
  FieldPointsCrossBar := TObjectList<TFieldPoint>.Create(True);
  FieldPointsCrossGol := TObjectList<TFieldPoint>.Create(True);
  FieldPointsCrossOut := TObjectList<TFieldPoint>.Create(True);

  // 1440x900
  // i 2 gk
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,3);   AFieldPoint.Pixel := Point  (220,454); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,3);  AFieldPoint.Pixel := Point  (1216,454); FieldPoints.Add( AFieldPoint);

  // Le celle del campo in gioco normali
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,0);  AFieldPoint.Pixel := Point  (306,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,0);  AFieldPoint.Pixel := Point  (386,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,0);  AFieldPoint.Pixel := Point  (470,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,0);  AFieldPoint.Pixel := Point  (570,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,0);  AFieldPoint.Pixel := Point  (670,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,0);  AFieldPoint.Pixel := Point  (770,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,0);  AFieldPoint.Pixel := Point  (870,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,0);  AFieldPoint.Pixel := Point  (970,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,0);  AFieldPoint.Pixel := Point  (1062,246); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,0);  AFieldPoint.Pixel := Point  (1140,246); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,1);  AFieldPoint.Pixel := Point  (290,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,1);  AFieldPoint.Pixel := Point  (378,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,1);  AFieldPoint.Pixel := Point  (466,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,1);  AFieldPoint.Pixel := Point  (564,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,1);  AFieldPoint.Pixel := Point  (668,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,1);  AFieldPoint.Pixel := Point  (774,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,1);  AFieldPoint.Pixel := Point  (870,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,1);  AFieldPoint.Pixel := Point  (976,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,1);  AFieldPoint.Pixel := Point  (1075,312); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,1);  AFieldPoint.Pixel := Point  (1161,312); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,2);  AFieldPoint.Pixel := Point  (275,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,2);  AFieldPoint.Pixel := Point  (363,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,2);  AFieldPoint.Pixel := Point  (450,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,2);  AFieldPoint.Pixel := Point  (600,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,2);  AFieldPoint.Pixel := Point  (668,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,2);  AFieldPoint.Pixel := Point  (780,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,2);  AFieldPoint.Pixel := Point  (880,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,2);  AFieldPoint.Pixel := Point  (990,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,2);  AFieldPoint.Pixel := Point  (1086,388); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,2);  AFieldPoint.Pixel := Point  (1172,388); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,3);  AFieldPoint.Pixel := Point  (255,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,3);  AFieldPoint.Pixel := Point  (343,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,3);  AFieldPoint.Pixel := Point  (440,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,3);  AFieldPoint.Pixel := Point  (550,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,3);  AFieldPoint.Pixel := Point  (660,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,3);  AFieldPoint.Pixel := Point  (783,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,3);  AFieldPoint.Pixel := Point  (888,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,3);  AFieldPoint.Pixel := Point  (997,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,3);  AFieldPoint.Pixel := Point  (1100,466); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,3);  AFieldPoint.Pixel := Point  (1200,466); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,4);  AFieldPoint.Pixel := Point  (237,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,4);  AFieldPoint.Pixel := Point  (336,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,4);  AFieldPoint.Pixel := Point  (430,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,4);  AFieldPoint.Pixel := Point  (544,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,4);  AFieldPoint.Pixel := Point  (660,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,4);  AFieldPoint.Pixel := Point  (780,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,4);  AFieldPoint.Pixel := Point  (890,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,4);  AFieldPoint.Pixel := Point  (1010,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,4);  AFieldPoint.Pixel := Point  (1115,554); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,4);  AFieldPoint.Pixel := Point  (1210,554); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,5);  AFieldPoint.Pixel := Point  (412,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,5);  AFieldPoint.Pixel := Point  (308,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,5);  AFieldPoint.Pixel := Point  (420,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,5);  AFieldPoint.Pixel := Point  (540,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,5);  AFieldPoint.Pixel := Point  (660,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,5);  AFieldPoint.Pixel := Point  (780,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,5);  AFieldPoint.Pixel := Point  (900,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,5);  AFieldPoint.Pixel := Point  (1010,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,5);  AFieldPoint.Pixel := Point  (1120,656); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,5);  AFieldPoint.Pixel := Point  (1237,656); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,6);  AFieldPoint.Pixel := Point  (186,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,6);  AFieldPoint.Pixel := Point  (290,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,6);  AFieldPoint.Pixel := Point  (413,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,6);  AFieldPoint.Pixel := Point  (530,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,6);  AFieldPoint.Pixel := Point  (650,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,6);  AFieldPoint.Pixel := Point  (785,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,6);  AFieldPoint.Pixel := Point  (910,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,6);  AFieldPoint.Pixel := Point  (1020,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,6);  AFieldPoint.Pixel := Point  (1133,746); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,6);  AFieldPoint.Pixel := Point  (1260,746); FieldPoints.Add( AFieldPoint);

  // le riserve
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,6);  AFieldPoint.Pixel := Point  (186,746); FieldPointsReserve.Add( AFieldPoint);


end;
procedure TForm1.RefreshCheckFormationMemory;
begin

    if CheckFormationTeamMemory then begin
      btnMainPlay.Enabled := True;
      SE_lblPlay.Font.Color := clGreen;
      SE_lblPlay.Caption := 'Formation OK' ;
    end
    else begin
      btnMainPlay.Enabled := false;
      SE_lblPlay.Font.Color := clRed;
      SE_lblPlay.Caption :=  'Invalid Formation' ;
    end;

end;
function TForm1.RndGenerate( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (1, Upper + 1));
end;
function TForm1.RndGenerate0( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (0, Upper + 1));
end;
function TForm1.RndGenerateRange( Lower, Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (Lower, Upper + 1));
end;

procedure TForm1.RoundBorder (bmp: TBitmap; w,h: Integer);
var
x,y: Integer;
begin

      bmp.Canvas.Pixels [0,0]:= $7B5139;
      bmp.Canvas.Pixels [0,1]:= $7B5139;
      bmp.Canvas.Pixels [0,2]:= $7B5139;
      bmp.Canvas.Pixels [1,0]:= $7B5139;
      bmp.Canvas.Pixels [2,0]:= $7B5139;

      bmp.Canvas.Pixels [w-3,0]:= $7B5139;
      bmp.Canvas.Pixels [w-2,0]:= $7B5139;
      bmp.Canvas.Pixels [w-1,0]:= $7B5139;
      bmp.Canvas.Pixels [w-1,1]:= $7B5139;
      bmp.Canvas.Pixels [w-1,2]:= $7B5139;

      bmp.Canvas.Pixels [w-3,h-1]:= $7B5139;
      bmp.Canvas.Pixels [w-2,h-1]:= $7B5139;
      bmp.Canvas.Pixels [w-1,h-1]:= $7B5139;
      bmp.Canvas.Pixels [w-1,h-2]:= $7B5139;
      bmp.Canvas.Pixels [w-1,h-3]:= $7B5139;

      bmp.Canvas.Pixels [0,h-3]:= $7B5139;
      bmp.Canvas.Pixels [0,h-2]:= $7B5139;
      bmp.Canvas.Pixels [0,h-1]:= $7B5139;
      bmp.Canvas.Pixels [1,h-1]:= $7B5139;
      bmp.Canvas.Pixels [2,h-1]:= $7B5139;

      for x := 0 to bmp.Width -1 do begin
          bmp.Canvas.Pixels [x,0]:= $7B5139;
          bmp.Canvas.Pixels [x,bmp.Height -1]:= $7B5139;
      end;
      for y := 0 to bmp.height -1 do begin
          bmp.Canvas.Pixels [0,y]:= $7B5139;
          bmp.Canvas.Pixels [bmp.width-1,y]:= $7B5139;
      end;


end;

function TForm1.findPlayerMyBrainFormation ( guid: string ): TSoccerPlayer;
var
  i: integer;
begin
  for I := 0 to MyBrainFormation.lstSoccerPlayer.Count -1 do begin
    if  MyBrainFormation.lstSoccerPlayer[i].Ids = guid then begin
      Result :=  MyBrainFormation.lstSoccerPlayer[i];
      Exit;
    end;

  end;

end;
procedure TForm1.CreateCircle( Player : TSoccerPlayer );
var
  filename : string;
  posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Circle : SE_Sprite;
begin
    fileName := dir_interface + 'circle.bmp';
    if Player.team = 0 then begin
      ArrowDirection.offset.X := -10;
      ArrowDirection.offset.Y := +10;
    end
    else begin
      ArrowDirection.offset.X := +10;
      ArrowDirection.offset.Y := +10;
    end;

    posX := Player.se_sprite.Position.X + ArrowDirection.offset.X;
    posY := Player.se_sprite.Position.Y + ArrowDirection.offset.Y;
    Circle := SE_interface.CreateSprite(filename,'Circle', 1,1,1000,  posX,posY, true);
    ColorizeArrowCircle ( Player.team,   Circle.BMP );
    Circle.Scale := 10;

end;
procedure TForm1.CreateCircle( Team, CellX, CellY: integer );
var
  filename : string;
  posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Circle : SE_Sprite;
  aSeField: SE_Sprite;
begin

    fileName := dir_interface + 'circle.bmp';
    if team = 0 then begin
      ArrowDirection.offset.X := -10;
      ArrowDirection.offset.Y := +10;
    end
    else begin
      ArrowDirection.offset.X := +10;
      ArrowDirection.offset.Y := +10;
    end;


    aSeField := SE_field.FindSprite( IntToStr(CellX) + '.' + IntToStr(CellY) );
    posX := aSeField.Position.X + ArrowDirection.offset.X;
    posY := aSeField.Position.Y + ArrowDirection.offset.Y;
    Circle := SE_interface.CreateSprite(filename,'Circle', 1,1,1000,  posX,posY, true);
    Circle.Scale := 10;
    ColorizeArrowCircle ( team,   Circle.BMP );

end;
procedure TForm1.CreateArrowDirection ( Player1 , Player2: TSoccerPlayer );
var
  filename : string;
  X1,X2,Y1,Y2,posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Arrow : SE_Sprite;
begin
  X1:= Player1.CellX;
  Y1:= Player1.CellY;
  X2:= Player2.CellX;
  Y2:= Player2.CellY;

  // se uguale creo un circle ed esco
  if (X1=X2) and (Y1=Y2) then begin
    fileName := dir_interface + 'circle.bmp';
    if Player1.team = 0 then begin
      ArrowDirection.offset.X := -10;
      ArrowDirection.offset.Y := +10;
    end
    else begin
      ArrowDirection.offset.X := +10;
      ArrowDirection.offset.Y := +10;
    end;

    posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
    posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;

    Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
    Arrow.Scale := 10;
    ColorizeArrowCircle ( Player1.team,   Arrow.BMP );
    Exit;
  end;

  fileName := dir_interface + 'arrow.bmp';

  ArrowDirection.angle :=   AngleOfLine ( Player1.se_sprite.Position , Player2.se_sprite.Position );

  if (X2 = X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 = X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 < X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 > X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 > X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 < X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 > X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := 0;
  end
  else if (X2 < X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := 0;
  end;

  posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
  posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;


  Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
  Arrow.Angle := ArrowDirection.angle ;
  Arrow.Scale := 16;
  ColorizeArrowCircle ( Player1.team,   Arrow.BMP );

end;
procedure TForm1.CreateArrowDirection ( Player1 : TSoccerPlayer; CellX, CellY: integer );
var
  filename : string;
  X1,X2,Y1,Y2,posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Arrow : SE_Sprite;
begin
  X1:= Player1.CellX;
  Y1:= Player1.CellY;
  X2:= CellX;
  Y2:= CellY;

  // se uguale creo un circle ed esco
  if (X1=X2) and (Y1=Y2) then begin
    fileName := dir_interface + 'circle.bmp';
    if Player1.team = 0 then begin
      ArrowDirection.offset.X := -10;
      ArrowDirection.offset.Y := +10;
    end
    else begin
      ArrowDirection.offset.X := +10;
      ArrowDirection.offset.Y := +10;
    end;

    posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
    posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;
    Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
    Arrow.Scale := 10;
    ColorizeArrowCircle ( Player1.team,   Arrow.BMP );
    Exit;
  end;


  fileName := dir_interface + 'arrow.bmp';

  ArrowDirection.angle :=   AngleOfLine ( Point(Player1.CellX,Player1.CellY) , Point ( CellX, CellY));

  if (X2 = X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 = X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 < X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 > X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := -20;
  end
  else if (X2 > X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 < X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := +20;
  end
  else if (X2 > X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := +20;
   ArrowDirection.offset.Y  := 0;
  end
  else if (X2 < X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := -20;
   ArrowDirection.offset.Y  := 0;
  end;

  posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
  posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;

  Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
  Arrow.Angle := ArrowDirection.angle ;
  Arrow.Scale := 16;
  ColorizeArrowCircle ( Player1.team,   Arrow.BMP );

end;

procedure TForm1.PrsMouseEnter ( Sender : TObject);
var
  i,ii,c : Integer;
  anOpponent,aGK: TSoccerPlayer;
  aPoint : PPointL;
  Modifier,BaseShot: Integer;
  aDoor, BarrierCell: TPoint;
  aSeField: SE_Sprite;
begin
  hidechances;


  if SelectedPlayer = nil then Exit;
  Modifier := 0;
  aDoor := Mybrain.GetOpponentDoor ( SelectedPlayer );
  if absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, adoor.X, adoor.Y  ) > PowerShotRange then exit;


  if MyBrain.w_FreeKick3 then begin
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    BaseShot :=  SelectedPlayer.DefaultShot + Mybrain.MalusPrecisionShot[SelectedPlayer.CellX] +1 +
                  Abs(Integer(  (SelectedPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (SelectedPlayer.TalentId2 = TALENT_ID_FREEKICKS) ));  // . il +1 è importante al shot. è una freekick3
    if BaseShot <= 0 then BaseShot := 1;
    CreateBaseAttribute (  selectedPlayer.CellX, SelectedPlayer.CellY, BaseShot) ;
  // mostro le 4 chance in barriera
    BarrierCell := MyBrain.GetBarrierCell( MyBrain.TeamFreeKick , MyBrain.Ball.CellX, MyBrain.Ball.CellY  ) ;
    CreateCircle( aGK.Team, BarrierCell.X, BarrierCell.Y );
//    CreateBaseAttribute (  BarrierCell.X, BarrierCell.Y , aGK.Defense) ;
{    b := 0;
    for I :=  0 to Mybrain.lstSoccerPlayer.Count -1 do begin
      anOpponent := Mybrain.lstSoccerPlayer[i];
      if (anOpponent.CellX = BarrierCell.X) and (anOpponent.CellY = BarrierCell.Y) then begin
        Inc(b);
        /////CreateTextChanceValue (anOpponent.ids,anOpponent.Defense , dir_attributes + 'Defense', 0, B*18, aCell.PixelX, acell.PixelY  );
      end;
    end;   }

  // mostro la chance el portiere e la mia
    CreateCircle( aGK );
    CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;


  end
  else if MyBrain.w_FreeKick4 then begin
    BaseShot :=  SelectedPlayer.DefaultShot + modifier_penalty +1 +Abs(Integer(  (SelectedPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (SelectedPlayer.TalentId2 = TALENT_ID_FREEKICKS) ));  // . il +1 è importante al shot. è una freekick4
    CreateBaseAttribute (  selectedPlayer.CellX, SelectedPlayer.CellY, BaseShot) ;

    // il pos non ha quel +1 ma ha la respinta
    if BaseShot <= 0 then BaseShot := 1;
  // mostro la chance el portiere e la mia
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
    CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end
  else begin
    BaseShot :=  SelectedPlayer.Shot + Mybrain.MalusPrecisionShot[SelectedPlayer.CellX];
    if BaseShot <= 0 then BaseShot := 1;
    CreateBaseAttribute (  selectedPlayer.CellX, SelectedPlayer.CellY, BaseShot) ;

    for Ii := 0 to MyBrain.ShotCells.Count -1 do begin

      if (MyBrain.ShotCells[ii].DoorTeam <> SelectedPlayer.Team) and
      (MyBrain.ShotCells[ii].CellX = SelectedPlayer.CellX) and (MyBrain.ShotCells[ii].CellY = SelectedPlayer.CellY) then begin

        for c := 0 to  MyBrain.ShotCells[ii].subCell.Count -1 do begin
          aPoint :=  MyBrain.ShotCells[ii].subCell.Items [c];
          anOpponent := Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y );
          if  anOpponent = nil then continue;
          if Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y ).Team <> SelectedPlayer.Team then begin
            if SelectedPlayer.CellX = anOpponent.cellX then Modifier := soccerbrainv3.modifier_defenseShot else Modifier :=0;
            CreateArrowDirection( anOpponent, SelectedPlayer );
            CreateBaseAttribute (  aPoint.x, aPoint.y, anOpponent.Defense) ;
          end;
        end;
      end;
    end;

    // mostro la chance el portiere
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
    CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end;

end;
procedure TForm1.CreateBaseAttribute ( CellX, CellY, value: integer );
var
  aSeField: SE_Sprite;
  sebmp: SE_Bitmap;

begin

    // la skill usata e i punteggi
    aSEField := SE_field.FindSprite( IntToStr(CellX) + '.' + IntToStr(CellY) );

    sebmp:= Se_bitmap.Create (32,32);
    sebmp.Bitmap.Canvas.Brush.color := clGray;

    sebmp.Bitmap.Canvas.Ellipse(6,6,26,26);
    sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
    sebmp.Bitmap.Canvas.Font.Size := 10;
    sebmp.Bitmap.Canvas.Font.Style := [fsbold];
    sebmp.Bitmap.Canvas.Font.Color := clYellow;
    if length(  IntToStr(Value)) = 1 then
      sebmp.Bitmap.Canvas.TextOut( 12,8, IntToStr(Value))
      else sebmp.Bitmap.Canvas.TextOut( 7,8, IntToStr(Value));

    // o è una skill o è un attributo nel panelcombat
//    if Translate ( 'skill_' + ts[3]) <> '' then
//      SE_GridDicewriterow ( aplayer.Team,  UpperCase( Translate ( 'skill_' + ts[3])),  aplayer.surname,  aPlayer.ids , ts[2], '' )
//      else SE_GridDicewriterow ( aplayer.Team,  UpperCase( Translate ( 'attribute_' + ts[3])),  aplayer.surname,  aPlayer.ids , ts[2], '' );

    se_interface.CreateSprite( sebmp.bitmap, 'numbers', 1, 1, 100, aSEField.Position.X  , aSEField.Position.Y , true );
    sebmp.Free;

end;
procedure TForm1.Btn_UniformHomeClick(Sender: TObject);
var
  ha : Byte;
begin
    if Btn_UniformHome.Down then
     ha := 0
     else ha :=1;

    PreLoadUniform( ha,  StrToInt( tsUniforms[0][3]) );  // usa tsuniforms e  UniformBitmapBW

end;

procedure TForm1.Btn_UniformAwayClick(Sender: TObject);
var
  ha : Byte;
begin
    if Btn_UniformAway.Down then
     ha := 1
     else ha :=0;

    PreLoadUniform( ha, StrToInt(tsUniforms[1][3]) );  // usa tsuniforms e  UniformBitmapBW

end;


procedure TForm1.mainThreadTimer(Sender: TObject);
var
  FirstTickCount: longint;
begin

  WaitForSingleObject ( MutexAnimation, INFINITE );

  GCD := GCD - SE_ThreadTimer ( Sender).Interval;
  if (GameScreen = ScreenLiveMatch) or (GameScreen = ScreenWatchLive ) then Begin


    if AnimationScript.Index = -1 then begin
     ReleaseMutex ( MutexAnimation );
     exit;
    end;

    if AnimationScript.wait > -1 then begin
      AnimationScript.wait := AnimationScript.wait - MainThread.Interval ;
      if AnimationScript.wait <=0 then begin
        AnimationScript.wait :=-1;
      end
      else begin
        Application.ProcessMessages ;
        ReleaseMutex ( MutexAnimation );
        exit;
      end;
    end;

    if ( SE_ball.IsAnySpriteMoving  ) then begin   // la palla si sta muovendo
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      Application.ProcessMessages ;
      ReleaseMutex ( MutexAnimation );
      exit;
    end;


    if (AnimationScript.waitMovingPlayers) then begin // se devo apsettare i players

       if se_players.IsAnySpriteMoving  then  begin
          se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
          Application.ProcessMessages ;
          ReleaseMutex ( MutexAnimation );
          exit;
       end;
    end;


    if AnimationScript.Index <= AnimationScript.Ts.Count -1  then begin

      if AnimationScript.Index = 0  then
        PanelCorner.Visible := False;  // SC_FREEKICK mai per prima istruzione
      if se_ball.IsAnySpriteMoving then begin
       ReleaseMutex ( MutexAnimation );
       exit;
      end;


    {$ifdef tools}
      toolSpin.Visible := false;
    {$endif tools}
      Animating:= True;
      anim (AnimationScript.Ts[ AnimationScript.Index ]); // muove gli sprite
      AnimationScript.Index := AnimationScript.Index + 1;

//      if AnimationScript.Index >=  AnimationScript.Ts.Count -1 then
//        AnimationScript.Reset;

    end
    else begin
      AnimationScript.Index := -1;
    //  AnimationScript.Reset;
    // qui ho terminato l'animazione ma alcuni sprite potrebbero ancora muoversi in questo momento

      while ( SE_ball.IsAnySpriteMoving  ) or (SE_players.IsAnySpriteMoving ) do begin
        Application.ProcessMessages ;
      end;
       ReleaseMutex ( MutexAnimation );
    {$ifdef tools}
      if viewReplay then
        toolSpin.Visible := true;
    {$endif tools}



      Animating:= false;
//      FirstTickCount := GetTickCount;   // margine di sicurezza o il successivo ClientLoadBrainMM svuota la lstSoccerPlayer
//       repeat
//         Application.ProcessMessages;
//       until ((GetTickCount-FirstTickCount) >= Longint(2000));

      ClientLoadBrainMM ( CurrentIncMove, false ) ; // <-- false, gli sprite e le liste non saranno mai svuotate
      SpriteReset;
//      UpdateSubSprites;
      incMoveAllProcessed [CurrentIncMove] := True; // caricato e completamente eseguito
  //    inc ( CurrentIncMove );
    end;

  end;
  ReleaseMutex(MutexAnimation);


end;
procedure TForm1.SetGlobalCursor ( aCursor: Tcursor);
begin
    SE_GridAllbrain.Cursor := aCursor;
    SE_Theater1.Cursor := aCursor;

end;

procedure TForm1.PosMouseEnter ( Sender : TObject);
var
  ii,c : Integer;
  anOpponent,aGK: TSoccerPlayer;
  aPoint : PPointL;
  Modifier,BaseShot: Integer;
  BarrierCell: TPoint;
  aDoor: TPoint;

begin
  hidechances;
  if SelectedPlayer = nil then Exit;
  Modifier := 0;
  aDoor := Mybrain.GetOpponentDoor ( SelectedPlayer );
  if absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, adoor.X, adoor.Y  ) > PowerShotRange then exit;

  if MyBrain.w_FreeKick3 then begin
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    BaseShot :=  SelectedPlayer.DefaultShot + Mybrain.MalusPrecisionShot[SelectedPlayer.CellX] +1 +
                  Abs(Integer(  (SelectedPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (SelectedPlayer.TalentId2 = TALENT_ID_FREEKICKS) ));  // . il +1 è importante al shot. è una freekick3    if BaseShot <= 0 then BaseShot := 1;
    CreateBaseAttribute (  SelectedPlayer.CellX,SelectedPlayer.CellY, BaseShot) ;
  // mostro le 4 chance in barriera
    BarrierCell := MyBrain.GetBarrierCell( MyBrain.TeamFreeKick , MyBrain.Ball.CellX, MyBrain.Ball.CellY  ) ;
    CreateCircle( aGK.Team, BarrierCell.X, BarrierCell.Y );

    CreateCircle( aGK );
    CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end
  else if MyBrain.w_FreeKick4 then begin
    BaseShot :=  SelectedPlayer.DefaultShot + modifier_penalty +
                  Abs(Integer(  (SelectedPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (SelectedPlayer.TalentId2 = TALENT_ID_FREEKICKS) ));
       // . il +2 è importante al shot. è una freekick4
    if BaseShot <= 0 then BaseShot := 1;
    CreateBaseAttribute (  SelectedPlayer.CellX,SelectedPlayer.CellY, BaseShot) ;

    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
    CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end
  else begin
    BaseShot :=  SelectedPlayer.Shot + Mybrain.MalusPowerShot[SelectedPlayer.CellX]  ;
    if BaseShot <= 0 then BaseShot := 1;
    CreateBaseAttribute (  SelectedPlayer.CellX,SelectedPlayer.CellY, BaseShot) ;

    for Ii := 0 to MyBrain.ShotCells.Count -1 do begin

      if (MyBrain.ShotCells[ii].DoorTeam <> SelectedPlayer.Team) and
      (MyBrain.ShotCells[ii].CellX = SelectedPlayer.CellX) and (MyBrain.ShotCells[ii].CellY = SelectedPlayer.CellY) then begin

        for c := 0 to  MyBrain.ShotCells[ii].subCell.Count -1 do begin
          aPoint := MyBrain.ShotCells[ii].subCell.Items [c];
          anOpponent := Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y );
          if  anOpponent = nil then continue;
          if Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y ).Team <> SelectedPlayer.Team then begin
            if SelectedPlayer.CellX = anOpponent.cellX then Modifier := soccerbrainv3.modifier_defenseShot else Modifier :=0;
            CreateArrowDirection( anOpponent, SelectedPlayer );
            CreateBaseAttribute (  aPoint.x, aPoint.y, anOpponent.defense );

          end;
        end;
      end;
    end;

    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
    CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end;

end;

procedure TForm1.UpdateFormation ( Guid: string; Team, TvCellX, TvCellY: integer);
var
  i: Integer;
  AICell: TPoint;
  aPlayer: TSoccerPlayer;
begin
  (* Aggiorna la MyBrainFormation, solo fuori da un match *)
   for i := 0 to MyBrainFormation.lstSoccerPlayer.count -1 do begin
      aPlayer := MyBrainFormation.lstSoccerPlayer[i];
      if aPlayer.Ids = Guid then begin
        if ((TvCellX = 0) and (TvCellY=3)) or (TvCellX = 2)  or  (TvCellX = 5) or (TvCellX = 8) then begin // uso TvCell
          AICell:=  MybrainFormation.Tv2AiField ( Team, TvCellX, TvCellY );
          aPlayer.DefaultCellS := Point  (TvCellX,TvCellY );
          aPlayer.AIFormationCellX  := AICell.X ;
          aPlayer.AIFormationCellY  := AICell.Y ;
          aPlayer.CellX :=  TvCellX;
          aPlayer.CellY :=  TvCellY;
          RefreshCheckFormationMemory;
          Exit;
        end
        else begin  // riserva
          MyBrainFormation.PutInReserveSlot(aPlayer) ;
          RefreshCheckFormationMemory;
          Exit;
        end;
      end;
   end;


end;
procedure TForm1.CheckBox2Click(Sender: TObject);
begin
  {$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'pause,' + BoolToStr(CheckBox2.Checked) + EndOfLine  ) ;
    GCD := GCD_DEFAULT;
  end;
  {$endif tools}
end;

procedure TForm1.CheckBox3Click(Sender: TObject);
begin

  ThreadCurMove.Enabled := CheckBox3.Checked;

end;

procedure TForm1.CheckBoxAI0Click(Sender: TObject);
begin
  {$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr(  'aiteam,0,' +  BoolToStr(CheckBoxAI0.Checked)  + EndOfLine );
    GCD := GCD_DEFAULT;
  end;
  {$endif tools}

end;

procedure TForm1.CheckBoxAI1Click(Sender: TObject);
begin
  {$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr(  'aiteam,1,' +  BoolToStr(CheckBoxAI1.Checked)  + EndOfLine );
    GCD := GCD_DEFAULT;
  end;
  {$endif tools}

end;

function TForm1.CheckFormationTeamMemory : Boolean;
var
  i,i2,pcount,pdisq: Integer;
  aPlayer: TSoccerPlayer;
  CellPoint : TPoint;
  lstCellPoint: TList<TPoint>;
  DupFound: Boolean;
begin
  (* controlla in locale memoria *)
  // controlla se sono schierati 11 giocatori a parte i disqualified. se può farlo deve giocare col massimo dei giocatori
  Result:= False;

  pcount:=0;
  pdisq:=0;
  lstCellPoint:= TList<TPoint>.Create;

  // non leggo la situazione direttamente dagli sprite, ma dal file ini così leggo tutte le formazioni di tutte le squadre
  for i := 0 to  MyBrainFormation.lstSoccerPlayer.count -1 do begin
    aPlayer := MyBrainFormation.lstSoccerPlayer[i];
    if isOutSideAI (aPlayer.AIformationCellX,aPlayer.AIFormationCellY)  or (aPlayer.disqualified  > 0)  then continue;

    if (aPlayer.AIformationCellY = 6) or
       (aPlayer.AIformationCellY= 3) or
       (aPlayer.AIformationCellY = 9) or
       ((aPlayer.AIformationCellY = 11) and ( aPlayer.AIformationCellX = 3) )  then begin
         Inc(pCount);
       end;

    // cerco celle duplicate
//    if (aPlayer.CellX <> 0) and  (aPlayer.CellY <> 0) then begin
      DupFound:= False;
      for i2 := 0 to lstCellPoint.Count -1 do begin
        if (lstCellPoint[i2].X = aPlayer.AIformationCellX) and (lstCellPoint[i2].Y = aPlayer.AIformationCellY) then  begin
          MyBrainFormation.PutInReserveSlot(aPlayer);
          MoveInReserves(aPlayer);
//          aPlayer.Cells := Point(0,0);
          Dec(pCount);
          DupFound:=True;
        end;
//      end;

      if not DupFound then begin
        CellPoint.X :=  aPlayer.AIformationCellX;
        CellPoint.Y :=  aPlayer.AIformationCellY;
        lstCellPoint.Add (CellPoint);
      end;
    end;



  end;

  for i := 0 to  MyBrainFormation.lstSoccerPlayer.count -1 do begin
    aPlayer := MyBrainFormation.lstSoccerPlayer[i];
    if aPlayer.disqualified > 0 then Inc(pDisq);// è lo stesso;
    //if aPlayer.injured > 0 then Inc(pDisq);
  end;

  // se sono 11 non sqlificati altrimenti...
  if pcount = 11 then begin
    result := True;
  end;

  // qui result è false perchè maggiore o inferiore a 11
  if pcount > 11 then begin
    result := false;
  end;

  // ... ti perdono il fatto che non puoi scherarne 11 tra gli squalificati
  if (result = false) and (MyBrainFormation.lstSoccerPlayer.count > 0) then begin
    if (MyBrainFormation.lstSoccerPlayer.count - pdisq) < 11 then begin
      Result:= True; // formazione valida con quello che è disponibile
    end;

  end;

  lstCellPoint.Free;

end;

function TForm1.inGolPosition ( PixelPosition: Tpoint ): boolean;
var
  aSEField: SE_Sprite;
begin

  Result := False;
  aSEField := SE_field.FindSprite('0.3');
  if (PixelPosition.X = aSEField.Position.X - 20) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;
  aSEField := SE_field.FindSprite('11.3');
  if (PixelPosition.X = aSEField.Position.X + 20) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;

end;
function TForm1.inCrossBarPosition ( PixelPosition: Tpoint ): Boolean;
var
  aSEField: SE_Sprite;
begin

  Result := False;
  aSEField := SE_field.FindSprite('0.3');
  if (PixelPosition.X = aSEField.Position.X - 10) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;
  aSEField := SE_field.FindSprite('11.3');
  if (PixelPosition.X = aSEField.Position.X + 10) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;

end;
function TForm1.inGKCenterPosition ( PixelPosition: Tpoint ): boolean;
var
  aSEField: SE_Sprite;
begin

  Result := False;
  aSEField := SE_field.FindSprite('0.3');
  if (PixelPosition.X = aSEField.Position.X ) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;
  aSEField := SE_field.FindSprite('11.3');
  if (PixelPosition.X = aSEField.Position.X ) and (PixelPosition.Y = aSEField.Position.Y) then
    result := True;

end;
procedure Tform1.SpriteReset ;
var
  i: integer;
  aPlayer: TsoccerPlayer;
  aSEField: SE_Sprite;
  rndy: Integer;
  ACellBarrier,TvReserveCell: TPoint;

begin
  // la palla
    aSEField := SE_field.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));
    Mybrain.Ball.SE_Sprite.Position  := aSEField.Position;
    Mybrain.Ball.SE_Sprite.PositionY := Mybrain.Ball.SE_Sprite.Position.Y + BallZ0Y;
    Mybrain.Ball.SE_Sprite.FrameXmax := 0 ; // palla ferma

    if Mybrain.Ball.Player <> nil then begin
      case Mybrain.Ball.Player.team of
        0: begin
          Mybrain.Ball.SE_Sprite.PositionX  :=   Mybrain.Ball.SE_Sprite.PositionX + abs(Ball0X);
          Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
        end;
        1: begin
          Mybrain.Ball.SE_Sprite.PositionX  :=   Mybrain.Ball.SE_Sprite.PositionX - abs(Ball0X);
          Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
        end;
      end;

    end;

    Mybrain.Ball.SE_Sprite.BlendMode := se_BlendNormal;
    Mybrain.Ball.SE_Sprite.Visible := True;

    if Mybrain.w_CornerSetup then begin//   (brain.w_Coa) or (brain.w_Cod)  then begin
      CornerSetBall;
    end;

    // i player
    for I := 0 to Mybrain.lstSoccerPlayer.Count -1 do begin
      aPlayer := Mybrain.lstSoccerPlayer [i];

      if MyBrainFormation.isReserveSlot  ( aPlayer.AIFormationCellX, aPlayer.AIFormationCellY )  then begin // le riserve tutte a sinistra

         TvReserveCell:= MyBrainFormation.ReserveSlotTV [aPlayer.team,aPlayer.AIFormationCellX, aPlayer.AIFormationCellY  ];
             // MyBrainFormation.PutInReserveSlot(aPlayer) ;

         MyBrain.ReserveSlot [aPlayer.Team, aPlayer.AIFormationCellX, aPlayer.AIFormationCellY]:= aPlayer.Ids;

        aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.x)+ '.' + IntToStr (TvReserveCell.Y));

        aPlayer.se_Sprite.Position := aSEField.Position;
        aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

            if GameScreen = ScreenSubs then
              aPlayer.se_Sprite.Visible := True
              else aPlayer.se_Sprite.Visible := false;

      end
      else begin  // player normali

        aSEField := SE_field.FindSprite(IntToStr (aPlayer.CellX ) + '.' + IntToStr (aPlayer.CellY ));
        aPlayer.se_Sprite.Position := aSEField.position  ;
        aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

      end;


      if MyBrain.w_FreeKick3  then begin
        if aPlayer.isFKD3 then begin
          ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
          aSeField := SE_field.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));
          rndY := RndGenerateRange(3,22);
          if Odd(RndGenerate(2)) then rndY := -rndY;
          aPlayer.se_Sprite.Position := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
          aPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
        end;
      end;

        if Mybrain.w_CornerSetup and aPlayer.isCOF then begin//   (brain.w_Coa) or (brain.w_Cod)  then begin
          CornerSetPlayer ( aPlayer );
       end;

       aPlayer.SE_Sprite.Visible := True;
    end;

    // le riserve
    for I := 0 to Mybrain.lstSoccerReserve.Count -1 do begin
      aPlayer := Mybrain.lstSoccerReserve [i];
      if MyBrainFormation.isReserveSlot  ( aPlayer.AIFormationCellX, aPlayer.AIFormationCellY )  then begin // le riserve tutte a sinistra

         TvReserveCell:= MyBrainFormation.ReserveSlotTV [aPlayer.team,aPlayer.AIFormationCellX, aPlayer.AIFormationCellY  ];

            MyBrain.ReserveSlot [aPlayer.Team, aPlayer.cellx, aPlayer.cellY]:= aPlayer.Ids;
        aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.x)+ '.' + IntToStr (TvReserveCell.Y));

            aPlayer.se_Sprite.Position := aSEField.Position;
            aPlayer.se_sprite.MoverData.Destination := aSEField.Position;
            if GameScreen = ScreenSubs then
              aPlayer.SE_Sprite.Visible := True
              else aPlayer.se_sprite.Visible := False;
      end;
    end;


  Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;

  UpdateSubSprites;
  HighLightFieldFriendly_hide; // qualsiasi evidenziazione scompare
//  application.ProcessMessages ;

  SetGlobalCursor( crHandPoint);


end;
procedure TForm1.CornerSetBall;
var
  CornerMap: TCornerMap;
  aSEField: SE_Sprite;
begin
  CornerMap := Mybrain.GetCorner ( Mybrain.TeamCorner , Mybrain.Ball.CellY, OpponentCorner) ; // mi restituisce la cell del corner reale
  aSEField := SE_field.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));

  Mybrain.Ball.SE_Sprite.Position :=  point ( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );
  Mybrain.Ball.SE_Sprite.MoverData.Destination :=  point ( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );

end;
procedure TForm1.CornerSetPlayer ( aPlayer: TsoccerPlayer);
var
  CornerMap: TCornerMap;
  aSEField: SE_Sprite;
begin
  CornerMap := Mybrain.GetCorner ( Mybrain.TeamCorner , Mybrain.Ball.CellY, OpponentCorner) ; // mi restituisce la cell del corner reale
  aSEField := SE_field.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));

  aPlayer.SE_Sprite.Position :=  Point( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );
  aPlayer.SE_Sprite.MoverData.Destination  :=  Point( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );

end;

procedure Tform1.RemoveChancesAndInfo;
var
  i: integer;
begin
  for I := 0 to Mybrain.lstSoccerPlayer.Count -1 do begin
    Mybrain.lstSoccerPlayer[i].Se_Sprite.Labels.Clear ;;
    Mybrain.lstSoccerPlayer[i].Se_Sprite.SubSprites.Clear;
    AddFace (Mybrain.lstSoccerPlayer[i]);
  end;

end;

procedure Tform1.PrepareAnim;
begin
  Form1.PanelCombatLog.Visible := True;
  SE_GridDice.ClearData ;
  SE_GridDice.RowCount :=1;
  SE_GridDice.CellsEngine.ProcessSprites(2000);
  SE_GridDice.refreshSurface (SE_GridDice);
 // RemoveChancesAndInfo;
  HideChances;
  AnimationScript.Reset ;
end;
procedure Tform1.CreateSplash (aString: string; msLifespan: integer) ;
var
  w: Integer;
  bmp: SE_Bitmap;
  aSprite: SE_Sprite;
begin

  SE_interface.RemoveAllSprites;
  HighLightFieldFriendly_hide;
  bmp:= SE_Bitmap.Create(600,40);
  bmp.Bitmap.Canvas.Brush.color := clblack;
  bmp.Bitmap.Canvas.Font.Name := 'Calibri';
  bmp.Bitmap.Canvas.Font.Quality := fqNonAntialiased;
  bmp.Bitmap.Canvas.font.Size := 24;
  bmp.Bitmap.Canvas.Font.Style := [fsBold];
  bmp.Bitmap.Canvas.font.Color := clyellow;
  bmp.Bitmap.Canvas.FillRect(rect(0,0,bmp.Width ,bmp.Height ));
  w:= bmp.Bitmap.Canvas.TextWidth(aString);
  bmp.Bitmap.Canvas.TextOut( (bmp.Bitmap.Width div 2)  - (w div 2), 0 ,aString );

  aSprite := se_interface.CreateSprite(bmp.Bitmap, aString, 1,1, 20,(se_theater1.VirtualBitmap.Width div 2),(se_theater1.VirtualBitmap.Height div 2), true  );
  //aSprite.LifeSpan := 80;
  aSprite.LifeSpan := msLifespan;
  lbl_score.Caption := IntToStr(Mybrain.Score.gol [0]) +'-'+ IntToStr(Mybrain.Score.gol [1]);
  aSprite.MoverData.Speed := 10;
  aSprite.MoverData.Destination := Point( aSprite.Position.X , aSprite.Position.Y - 200 );

  bmp.Free;
end;

procedure TForm1.LoadTranslations ;
var
  ini: TIniFile;
begin
  TranslateMessages:= TStringList.Create;
  TranslateMessages.StrictDelimiter := True;


  ini:= TIniFile.Create(dir_data + 'text\' + language + '\messages.txt' );
  ini.ReadSectionValues ('Messages',TranslateMessages ) ;
  ini.Free;


end;
Function TForm1.Capitalize ( aString : string  ): String;
begin
   if Length ( astring ) > 0 then
    Result :=  UPPERCASE (aString[1]) + RightStr ( aString , Length ( aString ) -1 )
    else
      result := '';

end;


function TForm1.ClientLoadScript ( incMove: Byte) : Integer;
var
  StartScript: Integer;
  SS : TStringStream;
  lentsscript: word;
begin
  AnimationScript.Reset ;
  Mybrain.tsScript.Clear ;

{
  str:= AnsiString  ( tsScript.CommaText );
  LentsScript := Length (str);
  MMbraindata.Write( @LentsScript, sizeof(integer) );
  MMbraindata.Write( @str[1] , Length(str) );

}
  StartScript := PWORD(@buf3[incMove][ 0 ])^;   // punta ai 2 byte word che indicano la lunghezza della stringa
  if StartScript = 0 then Exit;
  SS:= TStringStream.Create;
  SS.Size := MM3[incMove].Size;
  Mm3[incMove].Position := 0;
  SS.CopyFrom( MM3[incMove], MM3[incMove].size );


  // se non c'è tsscript la stringa è lunga 0
  lentsscript := PWORD(@buf3[incMove][ StartScript ])^;
  if lentsscript > 0 then
    Mybrain.tsScript.CommaText := midStr ( SS.DataString , StartScript +1+2, lentsscript ); //+1 ragiona in base 1  +2 per len della stringa

  SS.Free;
  incMoveReadTcp [incMove ] := True; // Letto e caricato
  result := Mybrain.tsScript.Count;
end;

procedure TForm1.CnColorGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
var
  UniformBitmap: SE_Bitmap;
  ha : Byte;
begin
    // non salvo il colore in sè, ma un index
    if btn_UniformHome.Down then
     ha := 0
     else ha :=1;

    if ck_Jersey1.Down then
      TSUniforms[ha][0] := IntToStr( aCol )
    else if ck_Jersey2.Down then
      TSUniforms[ha][1] := IntToStr( aCol )
    else if ck_Shorts.Down then
      TSUniforms[ha][2] := IntToStr( aCol );

//    TSUniforms[ha][3] := schema;

{      else if ck_Socks1.Down then           // vecchia versione con socks
      TSUniforms[ha][3] := IntToStr( aCol )
      else if ck_Socks2.Down then
      TSUniforms[ha][4] := IntToStr( aCol );   }

   // UniformBitmap := SE_Bitmap.Create (dir_player + 'bw.bmp');
    PreLoadUniform( ha, StrToInt( TSUniforms[ha][3] )   );  // usa tsuniforms
 //   UniformBitmap.free;
 //   UniformPortrait.Glyph.LoadFromFile(dir_tmp + 'color' + IntToStr(ha)+ '.bmp');

end;

procedure Tform1.ClientLoadBrainMM  ( incMove: Byte; FirstTime: boolean );
var
  SS : TStringStream;
  lenuser0,lenuser1,lenteamname0,lenteamname1,lenuniform0,lenuniform1,lenSurname: byte;
  lenMatchInfo: word;
  dataStr,tmpStr: string;
  Cur: Integer;
  TotPlayer,TotReserve: byte;
  aSEField, aSprite: se_Sprite;
  i,ii , aAge,aCellX,aCellY,aTeam,aGuidTeam,nMatchesPlayed,nMatchesLeft,pcount,rndY,aStamina: integer;
  DefaultCellX,DefaultCellY: ShortInt;
  TalentID1,TalentID2: Byte;
  aPlayer: TSoccerPlayer;
  FC: TFormationCell;
  aPoint : TPoint;
//  aCell: TSoccerCell;
  aName, aSurname,  Attributes,aIds: string;
  bmp: se_Bitmap;
  PenaltyCell: TPoint;
  bmp1: SE_Bitmap;
  Injured: Integer;
  CornerMap: TCornerMap;
  ACellBarrier,TvReserveCell: TPoint;
  DefaultSpeed, DefaultDefense , DefaultPassing, DefaultBallControl, DefaultShot, DefaultHeading: Byte;
  Speed, Defense , Passing, BallControl, Shot, Heading: ShortInt;
  UniformBitmap : array[0..1] of SE_Bitmap;
  UniformBitmapGK: SE_bitmap;
begin
  PanelSkill.Visible:= False;
  if FirstTime then begin
    se_players.RemoveAllSprites ;
{      for I := 0 to SE_players.SpriteCount -1 do begin
        aPlayer := se_Players.Sprites[i];
        aPlayer.SE_Sprite.DeleteSubSprite('star' );
        aPlayer.SE_Sprite.DeleteSubSprite('disqualified' );
        aPlayer.SE_Sprite.DeleteSubSprite('injured' );
        aPlayer.SE_Sprite.DeleteSubSprite('yellow' );
        aPlayer.SE_Sprite.DeleteSubSprite('inout' );
        aPlayer.SE_Sprite.DeleteSubSprite('buffd' );
        aPlayer.SE_Sprite.DeleteSubSprite('buffm' );
        aPlayer.SE_Sprite.DeleteSubSprite('bufff' );
        aPlayer.SE_Sprite.DeleteSubSprite('stay' );    // lascio FACE
        AddFace ( aPlayer );
      end;             }
    SE_players.ProcessSprites(2000);
    MyBrain.lstSoccerPlayer.Clear ;
    MyBrain.lstSoccerReserve.Clear;
  end;
    MyBrain.ClearReserveSlot;

  SS := TStringStream.Create;
  SS.Size := MM3[incMove].Size;
  MM3[incMove].Position := 0;
  ss.CopyFrom( MM3[incMove], MM3[incMove].size );
  //    dataStr := RemoveEndOfLine(string(buf));
  dataStr := SS.DataString;
  SS.Free;

  if RightStr(dataStr,2) <> 'IS' then Exit;


  // a 0 c'è la word che indica dove comincia tsScript
  cur := 2;
  lenuser0:=  Ord( buf3[incMove] [ cur ]);                 // ragiona in base 0
  MyBrain.Score.Username [0] := MidStr( dataStr, cur +2  , lenUser0 );// ragiona in base 1
  cur  := cur + lenuser0 + 1;
  lenuser1:=  Ord( buf3[incMove][Cur]);                 // ragiona in base 0
  MyBrain.Score.Username [1] := MidStr( dataStr, Cur + 2, lenUser1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenUser1 + 1;

  lenteamname0 :=  Ord( buf3[incMove][ cur ]);
  MyBrain.Score.Team [0]  := MidStr( dataStr, cur + 2  , lenteamname0 );// ragiona in base 1
  cur  := cur + lenteamname0 + 1;
  lenteamname1:=  Ord( buf3[incMove][Cur]);                 // ragiona in base 0
  MyBrain.Score.Team [1] := MidStr( dataStr, Cur + 2, lenteamname1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenteamname1 + 1;

  MyBrain.Score.TeamGuid [0] :=  PDWORD(@buf3[incMove][ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.TeamGuid [1] :=  PDWORD(@buf3[incMove][ cur ])^;

  cur := cur + 4 ;
  MyBrain.Score.TeamMI [0] :=  PDWORD(@buf3[incMove][ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.TeamMI [1] :=  PDWORD(@buf3[incMove][ cur ])^;
  cur := cur + 4 ;

  MyBrain.Score.Country [0] :=  PWORD(@buf3[incMove][ cur ])^;
  cur := cur + 2 ;
  MyBrain.Score.Country [1] :=  PWORD(@buf3[incMove][ cur ])^;
  cur := cur + 2 ;

  lenUniform0 :=  Ord( buf3[incMove][ cur ]);
  MyBrain.Score.Uniform [0]  := MidStr( dataStr, cur + 2  , lenUniform0 );// ragiona in base 1
  cur  := cur + lenUniform0 + 1;
  lenUniform1:=  Ord( buf3[incMove][Cur]);                 // ragiona in base 0
  MyBrain.Score.Uniform [1] := MidStr( dataStr, Cur + 2, lenUniform1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenUniform1 + 1;

  TsUniforms[0].CommaText := MyBrain.Score.Uniform [0] ; // in formazione casa/trasferta
  TsUniforms[1].CommaText := MyBrain.Score.Uniform [1] ;

  PreLoadUniform (0, StrToInt( TsUniforms[0][3]));
  UniformBitmap[0] := SE_Bitmap.Create (dir_tmp + 'color0.bmp');
//  Portrait0.Glyph.LoadFromFile(dir_tmp + 'color0.bmp');
  PreLoadUniform (1, StrToInt( TsUniforms[1][3]));
  UniformBitmap[1] := SE_Bitmap.Create (dir_tmp + 'color1.bmp');
  PreLoadUniformGK (0, StrToInt( TsUniforms[0][3] ));   // i gk sono tuuti uguali
  PreLoadUniformGK (1, StrToInt( TsUniforms[1][3] ));
  UniformBitmapGK := SE_Bitmap.Create (dir_tmp + 'colorgk.bmp');
  MyBrain.Score.DominantColor[0]:=  StringToColor( CnColorgrid1.CustomColors [ StrToInt( TsUniforms[0][0] )]);
  if TsUniforms[0][0] = TsUniforms[0][1] then
    MyBrain.Score.FontColor[0]:= GetContrastColor( StringToColor( CnColorgrid1.CustomColors [ StrToInt(TsUniforms[0][0])]) )
    else MyBrain.Score.FontColor[0]:= StringToColor( CnColorgrid1.CustomColors [ StrToInt( TsUniforms[0].Strings[1] )]);

  MyBrain.Score.DominantColor[1]:= StringToColor( CnColorgrid1.CustomColors [ StrToInt( TsUniforms[1][0] ) ]);
  if TsUniforms[1][0] = TsUniforms[1][1] then
    MyBrain.Score.FontColor[1]:= GetContrastColor( StringToColor( CnColorgrid1.CustomColors [ StrToInt(TsUniforms[1][0])]) )
    else MyBrain.Score.FontColor[1]:= StringToColor( CnColorgrid1.CustomColors [StrToInt( TsUniforms[1][1] )]);

  MyBrain.Score.Gol [0] :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.Gol [1] :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;

  MyBrain.Score.BuffD[0]:= Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffD[1]:= Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffM[0]:= Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffM[1]:= Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffF[0]:= Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffF[1]:= Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.TeamSubs[0]:= Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.TeamSubs[1]:= Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;


  // season e seasonRound
  MyBrain.Score.Season [0] :=  PDWORD(@buf3[incMove][ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.Season [1] :=  PDWORD(@buf3[incMove][ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.SeasonRound [0] :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.SeasonRound [1] :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;

  MyBrain.Minute :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Finished := Boolean ( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  LocalSeconds  :=  Ord( buf3[incMove][ cur ]);
  MyBrain.fmilliseconds :=  (PWORD(@buf3[incMove][ cur ])^ ) * 1000;
  cur := cur + 2 ;
  MyBrain.TeamTurn :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.FTeamMovesLeft :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.GameStarted :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.FlagEndGame :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.Shpbuff :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.ShpFree :=    Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.incMove :=    Ord( buf3[incMove][ cur ]);   // supplementari, rigori, può sforare 255 ?
  cur := cur + 1 ;
  i_tml ( IntToStr( MyBrain.FTeamMovesLeft ) ,  IntToStr( MyBrain.TeamTurn ) )  ;

  // aggiungo la palla
  se_ball.RemoveAllSprites ;
  SE_ball.ProcessSprites(20);
//  application.ProcessMessages ;
  if MyBrain.Ball <> nil then
    MyBrain.Ball.Free;

  MyBrain.Ball := Tball.create(MyBrain);
  MyBrain.Ball.CellX :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Ball.CellY :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;


    // aggiungo la palla
    aSEField := SE_field.FindSprite(IntToStr (MyBrain.Ball.CellX ) + '.' + IntToStr (MyBrain.Ball.CellY ));


    Mybrain.Ball.SE_Sprite := se_Ball.CreateSprite(dir_ball + 'ball1.bmp','ball',1,1,5,
                                              aSEField.Position.X   , aSEField.Position.Y , true);
   // Mybrain.Ball.SE_Sprite.Scale := 100;    Mybrain.Ball.SE_Sprite.Position :=aSEField.Position;
    Mybrain.Ball.Se_sprite.Scale := 40;
    Mybrain.Ball.SE_Sprite.MoverData.Speed:= DEFAULT_SPEED_BALL;
    Mybrain.Ball.SE_Sprite.PositionY := Mybrain.Ball.SE_Sprite.Position.Y + BallZ0Y;
    Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.Se_sprite.Position;
    Mybrain.Ball.SE_Sprite.FrameXmax := 0 ; // palla ferma


    if Mybrain.Ball.Player <> nil then begin
      case Mybrain.Ball.Player.team of
        0: begin
          Mybrain.Ball.SE_Sprite.PositionX  :=   Mybrain.Ball.SE_Sprite.PositionX + abs(Ball0X);
          Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
        end;
        1: begin
          Mybrain.Ball.SE_Sprite.PositionX  :=   Mybrain.Ball.SE_Sprite.PositionX - abs(Ball0X);
          Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
        end;
      end;

    end;


  MyBrain.TeamCorner :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.w_CornerSetup :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Coa:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Cod:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_CornerKick:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  MyBrain.TeamfreeKick :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.w_FreeKickSetup1 :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka1:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick1:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup2 :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka2:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fkd2:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick2:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup3 :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka3:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fkd3:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick3:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup4 :=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka4:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick4:=  Boolean( Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;

  lenMatchInfo:=  PWORD(@buf3[incMove][Cur] )^; // punta ai 2 byte word che indicano la lunghezza della stringa
  // se non c'è MatchInfo la stringa è lunga 0
  if lenMatchInfo > 0 then
    MyBrain.MatchInfo.CommaText :=  midStr ( DataStr , Cur +1+2, lenMatchInfo ); //+1 ragiona in base 1  +2 per len della stringa

  cur := Cur + lenMatchInfo + 2;


  lbl_Nick0.Text.Lines.Clear;
  lbl_Nick0.Text.Lines.Add ( '<Title1>' +  UpperCase( MyBrain.Score.Team [0]));
  lbl_Nick0.Text.Lines.Add ( '<Title1>' +  MyBrain.Score.UserName[0]);
  lbl_Nick1.Text.Lines.Clear;
  lbl_Nick1.Text.Lines.Add ( '<Title1>' +  UpperCase( MyBrain.Score.Team [1]));
  lbl_Nick1.Text.Lines.Add ( '<Title1>' +  MyBrain.Score.UserName[1]);


  lbl_score.Caption := IntToStr(Mybrain.Score.gol [0]) +'-'+ IntToStr(Mybrain.Score.gol [1]);

  lbl_minute.Caption := IntToStr(MyBrain.Minute) +'''';



  totPlayer :=  Ord( buf3[incMove][ cur ]);
  Cur := Cur + 1;
  // cursore posizionato sul primo player
  for I := 0 to totPlayer -1 do begin

//    PlayerGuid := StrToInt(spManager.lstSoccerPlayer[i].Ids); // dipende dalla gestione players, se divido per nazioni?
    aIds := IntToStr( PDWORD(@buf3[incMove][ cur ])^);
    Cur := Cur + 4;
    aGuidTeam := PDWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[incMove][ cur ]);
    aSurname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;
    aTeam := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1 ;
    aAge :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1 ;

    nMatchesplayed := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2 ;
    nMatchesLeft := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2 ;
    TalentID1 := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    TalentID2 := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    aStamina := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    DefaultSpeed := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultDefense := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultPassing := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultBallControl := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultShot := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultHeading := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Attributes:= IntTostr( DefaultSpeed) + ',' + IntTostr( DefaultDefense) + ',' + IntTostr( DefaultPassing) + ',' + IntTostr( DefaultBallControl) + ',' +
                 IntTostr( DefaultShot) + ',' + IntTostr( DefaultHeading) ;

    if FirstTime then begin
      aPlayer:= TSoccerPlayer.Create( aTeam,
                                 MyBrain.Score.TeamGuid [aTeam] ,
                                 nMatchesPlayed,
                                 aIds,
                                 aName,
                                 aSurname,
                                 Attributes,
                                 TalentID1,TalentID2  );     // attributes e defaultAttrributes sono uguali
      MyBrain.AddSoccerPlayer(aPlayer);       // lo aggiune per la prima ed unica volta
    end
    else begin
      aPlayer := MyBrain.GetSoccerPlayer (aIds);
      if aPlayer = nil then begin  // è entrato una riserva
        // è per forza nelle riserve
        aPlayer := MyBrain.GetSoccerPlayer2 (aIds);
        MyBrain.AddSoccerPlayer(aPlayer);       // lo aggiune per la prima ed unica volta
        for ii := MyBrain.lstSoccerReserve.Count -1 downto 0 do begin   // lo elimino dalle riserve
          if MyBrain.lstSoccerReserve[ii].Ids = aPlayer.ids then begin
            MyBrain.lstSoccerReserve.Delete(ii);                        // non elimina l'oggetto
            Break;
          end;

        end;

      end;
    end;
    aPlayer.Stamina := aStamina;
    aPlayer.TalentId1:= TalentID1;
    aPlayer.TalentId2:= TalentID2;

    aPlayer.Speed := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Defense := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Passing := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BallControl := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Shot := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Heading := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    Injured:= Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Injured := Injured;
    if Injured > 0 then begin
      aPlayer.Speed :=1;
      aPlayer.Defense :=1;
      aPlayer.Passing :=1;
      aPlayer.BallControl :=1;
      aPlayer.Shot :=1;
      aPlayer.Heading :=1;
    end;


    aPlayer.YellowCard :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.redcard :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.disqualified :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.gameover :=  Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;

    aPlayer.AIFormationCellX := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.AIFormationCellY  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    DefaultCellX := Ord( buf3[incMove][ cur ]);;
    Cur := Cur + 1;
    DefaultCellY := Ord( buf3[incMove][ cur ]);;
    Cur := Cur + 1;
    aPlayer.DefaultCellS :=  Point( DefaultCellX, DefaultCellY); // innesca e setta il role

    aPlayer.CellX := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.CellY := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

      (* variabili di gioco *)
    aPlayer.Stay  := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.CanMove  := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.CanSkill := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.CanDribbling := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.PressingDone  := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.BonusTackleTurn  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusLopBallControlTurn  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusProtectionTurn  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.UnderPressureTurn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusSHPturn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusSHPAREAturn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonuSPLMturn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusFinishingTurn := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    aPlayer.isCOF := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.isFK1 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.isFK2 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.isFK3 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.isFK4 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.isFKD3 := Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;
    aPlayer.face := PDWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 4;
    aPlayer.BonusBuffD := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusBuffM := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusBuffF := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    if FirstTime then begin

      if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
        aPlayer.Se_Sprite := se_players.CreateSprite( UniformBitmap[aTeam].bitmap ,aPlayer.Ids,1,1,100,0,0,true)
      else
        aPlayer.Se_Sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , aPlayer.Ids,1,1,1000,0,0,true);
      aPlayer.Se_Sprite.Scale:= ScaleSprites;
      AddFace ( aPlayer );
      aPlayer.Se_Sprite.ModPriority := i+2;
      aPlayer.Se_Sprite.MoverData.Speed := DEFAULT_SPEED_PLAYER;

    end;


            // se è eaPlayerulso o sostituito è ancora in lstsoccerplayer, non lstreserve
//            if aPlayer.Gameover or playerout  then begin

    if MyBrain.isReserveSlot  ( aPlayer.AIFormationCellX, aPlayer.AIFormationCellY )  then begin // le riserve tutte a sinistra

      TvReserveCell:= MyBrain.ReserveSlotTV [aPlayer.team,aPlayer.AIFormationCellX, aPlayer.AIFormationCellY  ];
     // MyBrainFormation.PutInReserveSlot(aPlayer) ;

      MyBrain.ReserveSlot [aPlayer.Team, aPlayer.AIFormationCellX, aPlayer.AIFormationCellY]:= aPlayer.Ids;

      aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.X ) + '.' + IntToStr (TvReserveCell.Y));

      aPlayer.Se_Sprite.Position := aSEField.Position;
      aPlayer.Se_Sprite.MoverData.Destination := aSEField.Position;
    end
    else begin  // player normali
      aSEField := SE_field.FindSprite(IntToStr (aPlayer.CellX ) + '.' + IntToStr (aPlayer.CellY ));
      aPlayer.Se_Sprite.Position := aSEField.position  ;
      aPlayer.Se_Sprite.MoverData.Destination := aSEField.Position;

      if GameScreen = ScreenSubs then
        aPlayer.Se_Sprite.Visible := True
        else aPlayer.Se_Sprite.Visible := false;

    end;

    if MyBrain.w_FreeKick3  then begin
      if aPlayer.isFKD3 then begin
        ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
        aSeField := SE_field.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));
        rndY := RndGenerateRange(3,22);
        if Odd(RndGenerate(2)) then rndY := -rndY;
        aPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
      end;
    end

    else if MyBrain.w_CornerSetup then begin
      if aPlayer.isCOF then begin
        CornerSetPlayer( aPlayer );
      end;
    end;

    aPlayer.SE_Sprite.Visible := True;




  end;

  totReserve :=  Ord( buf3[incMove][ cur ]);
  Cur := Cur + 1;
  // cursore posizionato sul primo Reserve
  for I := 0 to totReserve -1 do begin

//    PlayerGuid := StrToInt(aPlayerManager.lstSoccerPlayer[i].Ids); // dipende dalla gestione players, se divido per nazioni?
    aIds := IntToStr( PDWORD(@buf3[incMove][ cur ])^);
    Cur := Cur + 4;
    aGuidTeam := PDWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[incMove][ cur ]);
    aSurname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;
    aTeam := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1 ;
    aAge :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1 ;

    nMatchesPlayed := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2 ;
    nMatchesLeft := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2 ;
    TalentID1 := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    TalentID2 := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    aStamina := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    DefaultSpeed := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultDefense := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultPassing := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultBallControl := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultShot := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    DefaultHeading := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    Attributes:= IntTostr( DefaultSpeed) + ',' + IntTostr( DefaultDefense) + ',' + IntTostr( DefaultPassing) + ',' + IntTostr( DefaultBallControl) + ',' +
                 IntTostr( DefaultShot) + ',' + IntTostr( DefaultHeading) ;

    if FirstTime then begin
      aPlayer:= TSoccerPlayer.Create( aTeam,
                                 MyBrain.Score.TeamGuid [aTeam] ,
                                 nMatchesPlayed,
                                 aIds,
                                 aName,
                                 aSurname,
                                 Attributes,
                                 TalentID1,TalentID2  );     // attributes e defaultAttrributes sono uguali
      MyBrain.AddSoccerReserve(aPlayer);
    end
    else
      aPlayer := MyBrain.GetSoccerPlayer2 (aIds);

    aPlayer.Stamina := aStamina;
    aPlayer.TalentId1:= TalentID1;
    aPlayer.TalentId2:= TalentID2;

    aPlayer.Speed := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Defense := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Passing := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BallControl := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Shot := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Heading := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    Injured:= Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.Injured := Injured;
    if Injured > 0 then begin
      aPlayer.Speed :=1;
      aPlayer.Defense :=1;
      aPlayer.Passing :=1;
      aPlayer.BallControl :=1;
      aPlayer.Shot :=1;
      aPlayer.Heading :=1;
    end;


    aPlayer.YellowCard :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.redcard :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.disqualified :=  Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.gameover :=  Boolean( Ord( buf3[incMove][ cur ]));
    Cur := Cur + 1;

    aPlayer.AIFormationCellX := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.AIFormationCellY  := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    DefaultCellX := Ord( buf3[incMove][ cur ]);;
    Cur := Cur + 1;
    DefaultCellY := Ord( buf3[incMove][ cur ]);;
    Cur := Cur + 1;
    aPlayer.DefaultCellS :=  Point( DefaultCellX, DefaultCellY); // innesca e setta il role

    aPlayer.CellX := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.CellY := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;

    aPlayer.face := PDWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 4;


                    // fare preloadBrain, diverso da formation
    if firstTime then begin

      if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
        aPlayer.SE_sprite := se_players.CreateSprite( UniformBitmap[aTeam].bitmap ,aPlayer.Ids,1,1,100,0,0,true)
      else
        aPlayer.SE_sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , aPlayer.Ids,1,1,1000,0,0,true);
      aPlayer.SE_sprite.Scale:= ScaleSprites;
      AddFace ( aPlayer );
      aPlayer.SE_sprite.ModPriority := i+2;
      aPlayer.SE_sprite.MoverData.Speed := DEFAULT_SPEED_PLAYER;
    end;

      //        aPlayer.aPlayerrite.SoundFolder := dir_sound;
      { in formationcell_xy  0 6 coincide con 0 6 riserva. 0 6 non è una formnation valida, quindi ok }
//      if  MyBrain.isReserveSlot  ( aPlayer.CellX  , aPlayer.CellY )  then begin // le riserve tutte a sinistra o tutte a destra
      if MyBrain.isReserveSlot  ( aPlayer.AIFormationCellX, aPlayer.AIFormationCellY )  then begin // le riserve tutte a sinistra

        TvReserveCell:= MyBrain.ReserveSlotTV [aPlayer.team,aPlayer.AIFormationCellX, aPlayer.AIFormationCellY  ];
       // MyBrainFormation.PutInReserveSlot(aPlayer) ;

        MyBrain.ReserveSlot [aPlayer.Team, aPlayer.AIFormationCellX, aPlayer.AIFormationCellY]:= aPlayer.Ids;

        aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.X ) + '.' + IntToStr (TvReserveCell.Y));

      aPlayer.SE_sprite.Position := aSEField.Position;
      aPlayer.SE_sprite.MoverData.Destination := aSEField.Position;
     end;

      if GameScreen = ScreenSubs then
        aPlayer.SE_sprite.Visible := True
        else aPlayer.SE_sprite.Visible := false;


  end;
  UniformBitmap[0].Free;
  UniformBitmap[1].Free;
  UpdateSubSprites;
  // cur posizionato sull'inizio di tsscript

{

    CLIENTLOADSCRIPT

  str:= AnsiString  ( tsScript.CommaText );
  LentsScript := Length (str);
  MMbraindata.Write( @LentsScript, sizeof(integer) );
  MMbraindata.Write( @str[1] , Length(str) );

}


  if MyBrain.w_Fka1 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        CornerMap := MyBrain.GetCorner (MyBrain.TeamTurn , Mybrain.Ball.CellY, OpponentCorner );
        HighLightField ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        MouseWaitFor :=  WaitForXY_FKF1; //'Scegli chi batterà il fk1';
        LoadGridFreeKick (MyBrain.TeamTurn, 'Passing',true);
        ShowCornerFreeKickGrid;   //
    end
    else begin
      PanelCorner.Visible := False;
      PanelCombatLog.Visible:= True;
    end;
  end
  else if MyBrain.w_FreeKick1  then begin
//    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
//      SelectedPlayerPopupSkill ( MyBrain.Ball.CellX, MyBrain.Ball.CellY );
//    end
//    else PanelCorner.Visible := False;
    PanelCorner.Visible := False;
    PanelCombatLog.Visible:= True;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkill( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Fka2 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        HighLightField ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        MouseWaitFor := WaitForXY_FKF2; //'Scegli chi batterà il fk2';
        LoadGridFreeKick (MyBrain.TeamTurn, 'Crossing',true);
        ShowCornerFreeKickGrid;   //
    end
    else begin
      PanelCorner.Visible := False;
      PanelCombatLog.Visible:= True;
    end;
  end
  else if MyBrain.w_Fkd2 then begin

    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      CornerMap := MyBrain.GetCorner (MyBrain.TeamTurn , Mybrain.Ball.CellY, OpponentCorner );
      HighLightField( CornerMap.HeadingCellD [0].X,CornerMap.HeadingCellD [0].Y,0);
      LoadGridFreeKick (MyBrain.TeamTurn, 'Heading',true);
      ShowCornerFreeKickGrid;
    end
    else begin
      PanelCorner.Visible := False;
      PanelCombatLog.Visible:= True;
    end;
  end
  else if MyBrain.w_FreeKick2  then begin
      PanelCorner.Visible := False;
      SE_GridFreeKick.Active := False;
      if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
          tcp.SendStr( 'CRO2' + endofline);
      end;
  end
  else if MyBrain.w_Fka3 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        HighLightField ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        MouseWaitFor := WaitForXY_FKF3; //'Scegli chi batterà il fk3';
        LoadGridFreeKick (MyBrain.TeamTurn, 'Shot',true);
        ShowCornerFreeKickGrid;   //
    end
    else begin
      PanelCorner.Visible := False;
      PanelCombatLog.Visible:= True;
    end;
  end
  else if MyBrain.w_Fkd3 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      ACellBarrier :=  MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
      HighLightField( aCellBarrier.X,  aCellBarrier.Y,0 );
      LoadGridFreeKick (MyBrain.TeamTurn, 'Defense',true);
      ShowCornerFreeKickGrid;
    end
    else begin
      PanelCorner.Visible := False;
      PanelCombatLog.Visible:= True;
    end;

  end
  else if MyBrain.w_FreeKick3  then begin
    PanelCorner.Visible := False;
    SE_GridFreeKick.Active := False;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkill( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Fka4 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        PenaltyCell := MyBrain.GetPenaltyCell ( MyBrain.TeamTurn );
        HighLightField ( PenaltyCell.x,PenaltyCell.Y  ,0 );
        MouseWaitFor := WaitForXY_FKF4; //'Scegli chi batterà il fk4';
        LoadGridFreeKick (MyBrain.TeamTurn, 'Shot',true);
        ShowCornerFreeKickGrid;   //
    end
    else begin
      PanelCorner.Visible := False;
      PanelCombatLog.Visible:= True;
    end;
  end
  else if MyBrain.w_FreeKick4  then begin
    PanelCorner.Visible := False;
    SE_GridFreeKick.Active := False;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkill( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Coa then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        HighLightField ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        MouseWaitFor := WaitForXY_CornerCOF;
        LoadGridFreeKick (MyBrain.TeamTurn, 'Crossing',true);
        ShowCornerFreeKickGrid;   //
    end
    else begin
      PanelCorner.Visible := False;
      PanelCombatLog.Visible:= True;
    end;
  end
  else if MyBrain.w_Cod then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      CornerMap := MyBrain.GetCorner (MyBrain.TeamTurn , Mybrain.Ball.CellY, OpponentCorner );
      HighLightField( CornerMap.HeadingCellD [0].X,CornerMap.HeadingCellD [0].Y,0);
      LoadGridFreeKick (MyBrain.TeamTurn, 'Heading',true);
      ShowCornerFreeKickGrid;
    end
    else begin
      PanelCorner.Visible := False;
      PanelCombatLog.Visible:= True;
    end;

  end
  else if MyBrain.w_CornerKick  then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        tcp.SendStr( 'COR' + endofline);
    end;
  end;

   btnTactics.Down := false;  // clientloadbrain risponde sempre resettando a screenlivematch
   btnsubs.Down := false;

   btnTactics.Visible := Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam;

   if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
    or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then begin
     btnsubs.Visible := False;
     btntactics.Visible := False;
   end
   else begin
    btnsubs.Visible := True;
    btntactics.Visible := true;
   end;

   PanelCombatLog.Left := SE_Theater1.Left; //PanelSkill.Left + PanelSkill.Width;


    if (Mybrain.Score.TeamGuid [0]  = MyGuidTeam ) or (Mybrain.Score.TeamGuid [1]  = MyGuidTeam ) then
      btnWatchLiveExit.Visible := false
    else begin
      btnWatchLiveExit.Left := (PanelScore.Width div 2) - ( btnWatchLiveExit.Width div 2 );
      btnWatchLiveExit.Visible := true;
    end;
     SetGlobalCursor(crHandPoint );

     //if (not AudioCrowd.Playing) and ( not btnAudioStadium.Down) then begin
     // AudioCrowd.Play;
     //end;

   if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
    or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then begin
     btnsubs.Visible := False;
   end
   else btnsubs.Visible := True;
//   if Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam then begin

    if Mybrain.TeamTurn = 0 then begin
      btnSubs.Left := 3;
      btnTactics.Left := btnSubs.Left + btnSubs.Width;
      lbl_Nick0.Active := True;
      lbl_Nick1.Reset;
      lbl_Nick1.Active := false;
    end
    else if Mybrain.TeamTurn = 1 then begin
      lbl_Nick0.Active := false;
      lbl_Nick0.Reset;
      lbl_Nick1.Active := true;
      btnTactics.Left := lbl_Nick1.Left + lbl_Nick1.Width;// - btnTactics.Width ;
      btnSubs.Left := btnTactics.Left - btnSubs.Width;
    end;

end;

procedure  Tform1.SetSelectedPlayer ( aPlayer: TSoccerPlayer);
var
  i,L: Integer;
  aSubSprite : SE_SubSprite;
begin
  fSelectedPlayer := aPlayer;
  HighLightFieldFriendly_hide;
  se_gridskilloldCol := -100; // forza il mouseover sulla stessa skill se cambio selectedplayer
  se_gridskilloldRow := -100;
    for i := 0 to se_players.SpriteCount -1 do begin
      if fSelectedPlayer <> nil then begin

        if se_players.Sprites [i].Guid = aPlayer.ids then begin
          aSubSprite:= se_players.Sprites [i].FindSubSprite ('selected');
          if aSubSprite = nil then begin
            aSubSprite := SE_SubSprite.create( dir_interface + 'selected.bmp', 'selected', 0,0, True , true);
            se_players.Sprites [i].SubSprites.add ( aSubSprite );
          end;
        end
        else  begin
          se_players.Sprites [i].DeleteSubSprite ('selected');
        end;

      end;
    end;

end;
procedure Tform1.SetTmlPosition ( team: string );
begin
  if team = '0' then
      SE_GridTime.Left := lbl_Nick0.Left + 32
  else
      SE_GridTime.Left := lbl_Nick1.Left + 50;
end;
procedure TForm1.refreshGridTime;
var
  y: Integer;
  bmp: SE_Bitmap;
begin
  SE_GridTime.ClearData;   // importante anche pr memoryleak
  SE_GridTime.DefaultColWidth := 16;
  SE_GridTime.DefaultRowHeight := 32;
  SE_GridTime.ColCount :=3; // i 5 bitmap delle mosse, shpo free e la progressBar
  SE_GridTime.RowCount :=1;
  SE_GridTime.Columns[0].Width := 50;
  SE_GridTime.Columns[1].Width := 32;
  SE_GridTime.Columns[2].Width := 120;
  SE_GridTime.Height := 16;
  SE_GridTime.Width := 50+32+120;
  SE_GridTime.top := PanelScore.Height - SE_GridTime.Height ;

  for y := 0 to SE_GridTime.RowCount -1 do begin
    SE_GridTime.Rows[y].Height := 10;
  end;



  bmp:= SE_bitmap.Create ( dir_ball + 'ball2.bmp');

  SE_GridTime.AddSE_Bitmap(0,0, MyBrain.TeamMovesLeft ,Bmp,true);

  bmp.Free;

  if MyBrain.ShpFree > 0 then begin
    bmp:= SE_bitmap.Create ( dir_interface + 'shpfree.bmp');
    SE_GridTime.AddSE_Bitmap(1,0,1,bmp,true);
    bmp.Free;
  end;

  SE_GridTime.AddProgressBar(2,0,100,clWhite,pbStandard);

 // SE_GridTime.CellsEngine.ProcessSprites(2000);
 // SE_GridTime.RefreshSurface (SE_GridTime);

end;

procedure Tform1.i_tml ( MovesLeft,team: string );
begin

  SetTmlPosition ( Team );
  DontDoPlayers:= False;
  lbl_minute.Caption := IntToStr(MyBrain.Minute) +'''';

  RefreshGridTime;

end;
procedure Tform1.i_tuc ( team: string );
begin

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

   SetTmlPosition ( Team );
    //CreateSplash ( Translate('Round',1)  + ' ' + MyBrain.Score.Team [MyBrain.TeamTurn],msSplashTurn);

   RefreshGridTime;

   btnTactics.Visible := Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam;


   if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
    or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then begin
     btnsubs.Visible := False;
   end
   else btnsubs.Visible := True;
//   if Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam then begin
    if team = '0' then begin
      btnSubs.Left := lbl_Nick0.Left;
      btnTactics.Left := btnSubs.Left + btnSubs.Width;
      lbl_Nick0.Active := True;
      lbl_Nick1.Active := false;
      lbl_Nick1.Reset;
    end
    else if team = '1' then begin
      lbl_Nick0.Active := False;
      lbl_Nick0.Reset;
      lbl_Nick1.Active := true;
      btnTactics.Left := lbl_Nick1.Left + lbl_Nick1.Width - btnTactics.Width ;
      btnSubs.Left := btnTactics.Left - btnSubs.Width;
    end;



end;
procedure Tform1.i_red ( ids: string );
var
  aPlayer: TSoccerPlayer;
begin

    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
    aPlayer:= MyBrain.GetSoccerPlayer2(ids);
    SE_GridDicewriterow ( aplayer.Team, Translate('lbl_RedCard'),  aplayer.surname,  aplayer.ids , 'I','I.'+  Translate('lbl_RedCard'));
    MyBrain.PutInReserveSlot(aPlayer); // anticipa quello che farà il server
    MoveInReserves (aPlayer);

end;
procedure Tform1.i_yellow ( ids: string );
var
  aPlayer: TSoccerPlayer;
begin

    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
    aPlayer:= MyBrain.GetSoccerPlayer2(ids);
    SE_GridDicewriterow ( aplayer.Team, Translate('lbl_YellowCard'),  aplayer.surname,  aplayer.ids , 'I','I.'+Translate('lbl_YellowCard'));

end;
procedure TForm1.lbl_scoreMouseEnter(Sender: TObject);
begin
  ShowMatchInfo;
end;
procedure TForm1.lbl_scoreMouseLeave(Sender: TObject);
begin
  PanelMatchInfo.visible := False;
end;
procedure TForm1.ShowMatchInfo;
var
  y: Integer;
  tmp: TStringList;
  bmp: SE_Bitmap;
begin
  SE_GridMatchInfo.ClearData;   // importante anche pr memoryleak
  SE_GridMatchInfo.DefaultColWidth := 16;
  SE_GridMatchInfo.DefaultRowHeight := 12;
  SE_GridMatchInfo.ColCount := 3; // minute, bitmap, descrizione
  SE_GridMatchInfo.RowCount := MyBrain.MatchInfo.Count; // il numero di eventi scritto
  SE_GridMatchInfo.Columns[0].Width := 30;
  SE_GridMatchInfo.Columns[1].Width := 16;
  SE_GridMatchInfo.Columns[2].Width := 200;
  SE_GridMatchInfo.Width :=  SE_GridMatchInfo.TotalCellsWidth;

  for y := 0 to SE_GridMatchInfo.RowCount -1 do begin
    SE_GridMatchInfo.Rows[y].Height := 12;
    SE_GridMatchInfo.Cells[2,y].FontName := 'Verdana';
    SE_GridMatchInfo.Cells[2,y].FontSize := 8;
    SE_GridMatchInfo.cells [0,y].FontColor := clWhite;
    SE_GridMatchInfo.cells [2,y].FontColor := clWhite;
  end;
  SE_GridMatchInfo.Height := imin ( SE_GridMatchInfo.TotalCellsHeight , 738 );

  { parsing della matchinfo }
  tmp := TStringList.Create;
  tmp.Delimiter := '.';
  tmp.StrictDelimiter := True;
  for y:= 0 to MyBrain.MatchInfo.Count -1 do begin         // es. MyBrain.MatchInfo[y] 19.golprs.454  45.sub.126.138
    tmp.DelimitedText := MyBrain.MatchInfo[y];
    SE_GridMatchInfo.Cells[0,y].Text :=  tmp[0] + '''';
    if tmp[1] = 'sub' then begin
      bmp:= SE_Bitmap.Create ( dir_interface + 'infoinout.bmp');
      SE_GridMatchInfo.AddSE_Bitmap (1,y,1,bmp,true );
      bmp.Free;
      SE_GridMatchInfo.Cells[2,y].Text := MyBrain.GetSoccerPlayer2( tmp[2] ).SurName + '--->'+ MyBrain.GetSoccerPlayer2( tmp[3] ).SurName;
    end
    else if ( pos ('gol', tmp[1], 1 ) <> 0) and  (  pos ('4', tmp[1], 1 )  = 0)  then begin // gol normali, prs,pos,prs3pos3,gol.volley,gol.crossing
      bmp:= SE_Bitmap.Create ( dir_interface + 'infogolball.bmp');
      SE_GridMatchInfo.AddSE_Bitmap (1,y,1,bmp,true );
      bmp.Free;
      SE_GridMatchInfo.Cells[2,y].Text := MyBrain.GetSoccerPlayer2( tmp[2] ).SurName ;
    end
    else if ( pos ('gol', tmp[1], 1 ) <> 0) and  (  pos ('4', tmp[1], 1 ) <> 0)  then begin // gol su rigore
      bmp:= SE_Bitmap.Create ( dir_interface + 'infopenaltygol.bmp');
      SE_GridMatchInfo.AddSE_Bitmap (1,y,1,bmp,false );
      bmp.Free;
      SE_GridMatchInfo.Cells[2,y].Text := MyBrain.GetSoccerPlayer2( tmp[2] ).SurName ;
    end
    else if ( pos ('4fail', tmp[1], 1 ) <> 0) then begin // rigore fallito
      bmp:= SE_Bitmap.Create ( dir_interface + 'infopenaltyfail.bmp');
      SE_GridMatchInfo.AddSE_Bitmap (1,y,1,bmp,false );
      bmp.Free;
      SE_GridMatchInfo.Cells[2,y].Text := MyBrain.GetSoccerPlayer2( tmp[2] ).SurName ;
    end
    else if ( pos ('yc', tmp[1], 1 ) <> 0) then begin
      bmp:= SE_Bitmap.Create ( dir_interface + 'infoyellow.bmp');
      SE_GridMatchInfo.AddSE_Bitmap (1,y,1,bmp,true );
      bmp.Free;
      SE_GridMatchInfo.Cells[2,y].Text := MyBrain.GetSoccerPlayer2( tmp[2] ).SurName ;
    end
    else if ( pos ('rc', tmp[1], 1 ) <> 0) then begin
      bmp:= SE_Bitmap.Create ( dir_interface + 'infored.bmp');
      SE_GridMatchInfo.AddSE_Bitmap (1,y,1,bmp,true );
      bmp.Free;
      SE_GridMatchInfo.Cells[2,y].Text := MyBrain.GetSoccerPlayer2( tmp[2] ).SurName ;
    end;

    //SE_GridMatchInfo.Cells[2,y].Text :=  MyBrain.MatchInfo[y];


  end;

  tmp.Free;

  SE_GridMatchInfo.CellsEngine.ProcessSprites(2000);
  SE_GridMatchInfo.refreshSurface ( SE_GridMatchInfo );

  PanelMatchInfo.Left := PanelScore.Left + (PanelScore.Width div 2) - (PanelMatchInfo.Width div 2);
  PanelMatchInfo.Top := PanelScore.Top + PanelScore.Height;
  RoundCornerOf ( PanelMatchInfo );
  PanelMatchInfo.Visible := True;
  PanelMatchInfo.BringToFront;
  SE_GridMatchInfo.CellsEngine.ProcessSprites(2000);
  SE_GridMatchInfo.refreshSurface ( SE_GridMatchInfo );

end;

procedure Tform1.i_injured ( ids: string );
var
  aPlayer: TSoccerPlayer;
begin
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
     aPlayer:= MyBrain.GetSoccerPlayer2(ids);
     SE_GridDicewriterow ( aplayer.Team, Translate('lbl_Injured'),  aplayer.surname,  aplayer.ids , 'I','I.' +Translate('lbl_Injured') );
     // MoveInReserves (aPlayer);
     // aPlayer.Sprite.Visible := false;
     // AdvScoreClickCell(advScore,0,0); btntactics
end;
procedure TForm1.AnimCommon ( Cmd:string);
var
  tsCmd: TStringList;
  aPlayer: TSoccerPlayer;
begin
  tsCmd:= TstringList.Create ;
  tsCmd.CommaText := Cmd;//Mybrain.tsScript [0];

  if (tsCmd[0]= 'sc_player')  or (tsCmd[0]='sc_pa') then begin
    // il player è già posizionato
    AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
  end
  else if tsCmd[0]= 'sc_DICE' then begin
//    TsScript.add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +','+
//    IntTostr(aPlayer.Passing)+',Short.Passing,'+ aPlayer.ids+','+IntTostr(Roll.value) + ',' + Roll.fatigue + '.'+AC+ ',0');
    aPlayer :=  MyBrain.GetSoccerPlayer (  tsCmd[6] );
//    if aPlayer = nil then  asm int 3 ; end;

    AnimationScript.Tsadd ('cl_showroll,' + aPlayer.Ids + ',' + tsCmd[3]  + ',' + tsCmd[5] + ',' + tsCmd[8] );
  end
  else if (tsCmd[0]= 'sc_fault')  then begin
    AnimationScript.Tsadd ('cl_fault,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
    AnimationScript.Tsadd ('cl_wait,1500');
  end
  else if tsCmd[0]= 'sc_ai.movetoball' then begin   // movetoball prima di aimoveall
    AnimationScript.Tsadd ('cl_wait,2000');
  end
  else if tsCmd[0]= 'sc_mtbDICE' then begin
    aPlayer :=  MyBrain.GetSoccerPlayer (  tsCmd[6] );
//    if aPlayer = nil then asm int 3 ; end;
    AnimationScript.Tsadd ('cl_mtbshowroll,' + aPlayer.Ids + ',' + tsCmd[3]  + ',' + tsCmd[5] +',' + tsCmd[8]); // 8= F N , nessun talentid
    AnimationScript.Tsadd ('cl_wait,1600');
  end
  else if tsCmd[0]= 'sc_TML' then begin
    AnimationScript.TsAdd  ( 'cl_tml,' + tsCmd[1] + ','+ tsCmd[2] );
  end
  else if tsCmd[0]= 'sc_TUC' then begin
    AnimationScript.TsAdd  ( 'cl_tuc,' + tsCmd[1]);
  end
  else if tsCmd[0]= 'sc_fault.cheatballgk' then begin
   AnimationScript.TsAdd  ( 'cl_fault.cheatballgk,' + tsCmd[1] + ',' + tsCmd[2] +',' +tsCmd[3] ); // teamFavour Cellx, celly
    AnimationScript.Tsadd ('cl_wait,1500');
  end
  else if tsCmd[0]= 'sc_fault.cheatball' then begin
   AnimationScript.TsAdd  ( 'cl_fault.cheatball,' + tsCmd[1] + ',' + tsCmd[2] +',' + tsCmd[3] ); // teamFavour Cellx, celly
    AnimationScript.Tsadd ('cl_wait,1500');
  end
  else if tsCmd[0]= 'sc_GAMEOVER' then begin
    AnimationScript.TsAdd  ( 'cl_splash.gameover');
    AnimationScript.TsAdd  ( 'cl_wait,3000');
  end;

  tsCmd.free;

end;
procedure TForm1.Logmemo ( ScriptLine : string );
begin

    if Pos ('sc_ai.moveall', ScriptLine,1) <> 0 then begin
      MarkingMoveAll := True;
    end
    else if Pos ('sc_ai.endmoveall',ScriptLine,1) <> 0 then begin
      MarkingMoveAll := False;
      memo2.Lines.Add(ScriptLine);
      Exit;
    end;
    // SC_ST
    if Pos ('SC_ST', ScriptLine,1) <> 0 then Exit;

    if not MarkingMoveAll then
      memo1.Lines.Add( ScriptLine )
      else memo2.Lines.Add(ScriptLine);

end;
procedure TForm1.Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=13 then begin
    Key :=0;
    BtnLoginClick ( BtnLogin);
  end;
end;

procedure TForm1.LoadAnimationScript;  // tsScript arriva dal server e contiene l'animazione da realizzare qui sul client
var
  TsCmd : TstringList;
  aTackle,exBallPlayer, BallPlayer: TSoccerPlayer;
  I: Integer;
begin
  tsCmd:= TstringList.Create ;

  tsCmd.CommaText := Mybrain.tsScript [0];

  MarkingMoveAll:= False;
  LogMemo ( tsCmd.CommaText );

//*****************************************************************************************************************************************
//
//
//   if tsCmd[0] = 'SERVER_PLM'   Player move, un player si muove con o senza palla
//
//*****************************************************************************************************************************************
    if tsCmd[0] = 'SERVER_PLM' then begin   // ids aplayer.cellx, aplayer.celly, cellx celly

      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Move,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;
      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );


        if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd (  'cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_bounce' then begin
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+',0');
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
         // AnimationScript.Tsadd ('cl_sound,soundtackle');
        end
        else if tsCmd[0]= 'sc_ai.moveall' then begin
          AnimationScript.Tsadd ('cl_ball.stop' );
        end
        else if tsCmd[0]= 'sc_noswap' then begin
          // 1 ids tackle
          // 2 ids defender
          // 3 cellx
          // 4 celly
          // 5 cellx provenienza tentativo tackle
          // 6 celly provenienza tentativo tackle

         // AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
         // Dist := AbsDistance(StrToInt( tsCmd[5]),StrToInt( tsCmd[6]),StrToInt( tsCmd[3]),StrToInt( tsCmd[4])     );
         // AnimationScript.Tsadd ('cl_wait,' + IntTostr(( dist * sprite1cell)));

        end
    // in realtà qui sono già swappati nel brain
        else if tsCmd[0] = 'sc_swap' then begin  // in caso di contrasto automatico difensivo ( tackle automatico )
          // 1 ids tackle
          // 2 ids defender
          // 3 cellx
          // 4 celly
          // 5 cellx provenienza tackle riuscito
          // 6 celly provenienza tackle riuscito

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]);
          AnimationScript.Tsadd ('cl_wait,' + IntTostr((  sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4] +',' +   tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');

        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;


        i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll;   // prima mostro i Roll ( tiro dado 1d4 )

    end
//*****************************************************************************************************************************************
//
//
//   else if (tsCmd[0]= 'SERVER_SHP') then begin    Short.Passing, passaggio corto.
//
//*****************************************************************************************************************************************
    else if (tsCmd[0]= 'SERVER_SHP') then begin   // ids aplayer.cellx aplayer.celly  cellx celly

      if SE_GridTime.Cells[1,0].Bitmap <> nil then begin
        SE_GridTime.Cells[1,0].Bitmap.Free;
        SE_GridTime.Cells[1,0].Bitmap := nil;
      end;

      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Short.Passing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;

      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

        if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6]  );

        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end
        else if tsCmd[0]='sc_bounce' then begin  // rimbalzo nel caso venga intercettato
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+',0');
        end
        else if tsCmd[0]= 'sc_player.move.intercept' then begin
          AnimationScript.Tsadd ('cl_player.move.intercept,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;

        i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait,' + IntTostr( sprite1cell));
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr( 1000 ));
      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll ;

    end

//*****************************************************************************************************************************************
//
//
//   else if (tsCmd[0]= 'SERVER_TAC') or (tsCmd[0] = 'SERVER_DRI')  Tackle oppure Dribbling
//
//*****************************************************************************************************************************************
    else if (tsCmd[0]= 'SERVER_TAC') or (tsCmd[0] = 'SERVER_DRI') then begin   // ids aplayer.cellx aplayer.celly cellx celly

      PrepareAnim;
      if tsCmd[0]= 'SERVER_TAC' then
      AnimationScript.Tsadd ( 'cl_mainskillused,Tackle,'+ tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5])
      else
      AnimationScript.Tsadd ( 'cl_mainskillused,Dribbling,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;

      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

        if tsCmd[0]= 'sc_tackle.no' then begin   // il tackle non riesce, il player ci prova ma torna nella sua cella
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo tackle
          // 4 celly provenienza tentativo tackle
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

          aTackle := MyBrain.GetSoccerPlayer(tsCmd[1]);

          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] ); // va sulla cella della palla
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));  // aspetto un po'
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );  // torna alla cella di partenza

        end
        else if tsCmd[0] = 'sc_tackle.ok' then begin  // il tackle riesce
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo tackle
          // 4 celly provenienza tentativo tackle
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale
          aTackle := MyBrain.GetSoccerPlayer(tsCmd[1]);
          exBallPlayer := MyBrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');

          AnimationScript.Tsadd ('cl_player.move,'      +  exBallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));

        end
        else if tsCmd[0] = 'sc_tackle.ok10' then begin // il tackle riesce perfettamente, se può avanza di una cella nella direzione del tackle
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo tackle
          // 4 celly provenienza tentativo tackle
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale
          aTackle := Mybrain.GetSoccerPlayer(tsCmd[1]);      // il player che che fa tackle sul portatore di palla
          exBallPlayer := Mybrain.GetSoccerPlayer(tsCmd[2]); // il player che aveva la palla ma l'ha persa
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');

          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] +',' + tsCmd[1]+ ',0'  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));


        end
        else if tsCmd[0]= 'sc_dribbling.no' then begin
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo dribbling
          // 4 celly provenienza tentativo dribbling
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

          BallPlayer := Mybrain.GetSoccerPlayer(tsCmd[1]);
         // aTackle := Mybrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[3] + ','+tsCmd[4] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end
        else if tsCmd[0]= 'sc_dribbling.ok.10' then begin    // uguale a sotto
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo dribbling
          // 4 celly provenienza tentativo dribbling
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

          BallPlayer := Mybrain.GetSoccerPlayer(tsCmd[1]);
          aTackle := Mybrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move.toball,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end
        else if tsCmd[0]= 'sc_dribbling.ok' then begin
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo dribbling
          // 4 celly provenienza tentativo dribbling
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

          BallPlayer := Mybrain.GetSoccerPlayer(tsCmd[1]);
          aTackle := Mybrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move.toball,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move.toball,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end


        else if tsCmd[0]= 'sc_yellow' then begin

          AnimationScript.TsAdd  ( 'cl_yellow,' + tsCmd[1]);
        end
        else if tsCmd[0]= 'sc_red' then begin
          AnimationScript.TsAdd  ( 'cl_red,' + tsCmd[1]);
        end
        else if tsCmd[0]= 'sc_injured' then begin
          AnimationScript.TsAdd  ( 'cl_injured,' + tsCmd[1]);
        end
        else if tsCmd[0]= 'sc_FREEKICK1.FKA1' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
          AnimationScript.Tsadd ('cl_freekick1.fka1,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
        end
        else if tsCmd[0]= 'sc_FREEKICK2.FKA2' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
          AnimationScript.Tsadd ('cl_freekick2.fka2,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
        end
        else if tsCmd[0]= 'sc_FREEKICK3.FKA3' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
          AnimationScript.Tsadd ('cl_freekick3.fka3,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
        end
        else if tsCmd[0]= 'sc_FREEKICK4.FKA4' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
//          AnimationScript.Ts.Insert(AnimationScript.Index + 1 ,'cl_wait,3000');
          AnimationScript.Tsadd ('cl_freekick4.fka4,' + tsCmd[1]+','+tsCmd[2] +','+tsCmd[3] );
        end
        else if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6]   );
         // AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd (  'cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_bounce' then begin
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+',0');
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;


        i := i+1;
      end;


      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr(MaxDistance*Sprite1cell));
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr( 1000 ));
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll;


    end


//*****************************************************************************************************************************************
//
//
//   tsCmd[0] = 'SERVER_LOP'
//
//*****************************************************************************************************************************************


   else if tsCmd[0] = 'SERVER_LOP' then begin
      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Lofted.Pass,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;
      i:=1;
      //MainPlayer :=   Mybrain.GetSoccerPlayer ( tsCmd[1]);
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

        if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6]  );
        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end

    // in realtà qui sono già swappati nel brain
        else if tsCmd[0] = 'sc_lop.heading.bounce' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 ids aHeading
          // 4 cellx aPlayer
          // 5 celly aPlayer
          // 6 cellx aFriend
          // 7 celly aFriend
          // 8 cellx aHeading
          // 9 celly aHeading
          // 10 cellx  Ball.cellx
          // 11 celly Ball.cellx


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[3] + ',' + tsCmd[8] + ','+tsCmd[9]  +',' + tsCmd[6] + ','+tsCmd[7] );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[6]+ ','+tsCmd[7] +',' + tsCmd[8] + ','+tsCmd[9] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[1]+ ',heading' );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[1]+ ',0' );

        end
        else if tsCmd[0] = 'sc_lop.ballcontrol.bounce' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aFriend
          // 6 celly aFriend
          // 7 cellx  Ball.cellx
          // 8 celly Ball.cellx

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+ ',' + tsCmd[1]+ ',0' );
        end
        else if tsCmd[0] = 'sc_lop.ballcontrol.bounce.toball' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aFriend
          // 6 celly aFriend
          // 7 cellx  Ball.cellx
          // 8 celly Ball.cellx

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'  +  tsCmd[2] + ','+tsCmd[5]+ ','+tsCmd[6] + ','+tsCmd[7]+','+tsCmd[8] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

        end
        else if tsCmd[0] = 'sc_lop.ballcontrol.ok10' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aFriend
          // 6 celly aFriend

          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );

        end
        else if tsCmd[0] = 'sc_lop.no' then begin
          // 1 ids aPlayer
          // 2 cellx aPlayer
          // 3 celly aPlayer
          // 4 cellx  Ball.cellx
          // 5 celly Ball.cellx
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[2] + ','+tsCmd[3]+ ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[1]+ ',0' );
        end
        else if tsCmd[0] = 'sc_lop.ok10' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx  Ball.cellx
          // 6 celly Ball.cellx
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );

        end
        else if tsCmd[0] = 'sc_lop.back.bounce' then begin  // esiste sul volley
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_lop.back.swap.bounce' then begin   // esiste sul volley
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end

        else if tsCmd[0] = 'sc_lop.bounce' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball

          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,0'  );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if (tsCmd[0] = 'sc_pos.bounce.gk')  or (tsCmd[0] = 'sc_lop.bounce.gk') then begin  // anche tiro al volo
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,'+tsCmd[9]  );
          AnimationScript.Tsadd ('cl_ball.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
          //QUI tsCmd [7] e tsCmd [8] indicano la cella di uscita - MyBrain.,ball è già sulla cella del corner

        end

        //crossbar e gol uguali pos e prs
        else if (tsCmd[0] = 'sc_lop.bounce.crossbar')  or (tsCmd[0] = 'sc_prs.bounce.crossbar') then begin
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL)  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+',bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_lop.gol'   then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  aPlayer
          // 5 celly aPlayer
          // 6 cellx  aHeadingFriend
          // 7 celly aHeadingFriend
          // 8 cellx aGK
          // 9 celly aGK
          // 10 cellx Ball
          // 11 celly Ball

                  { TsScript.add ('sc_cross.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) ); }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,volley'  );

          AnimationScript.Tsadd ('cl_lop.gol,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ','  + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol'  );
          AnimationScript.TsAdd  ( 'cl_wait,3000');
        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;

        i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait,' + IntTostr(Sprite1cell));
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr( 1000 ));
      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll;
   end


//*****************************************************************************************************************************************
//
//
//    else if (tsCmd[0] = 'SERVER_CRO') or (tsCmd[0] = 'SERVER_POS') or (tsCmd[0] = 'SERVER_PRS') or (tsCmd[0] = 'SERVER_COR') then begin
//
//*****************************************************************************************************************************************


   else if (tsCmd[0] = 'SERVER_CRO')  or (tsCmd[0] = 'SERVER_POS') or (tsCmd[0] = 'SERVER_PRS') or (tsCmd[0] = 'SERVER_COR')
      or (tsCmd[0] = 'SERVER_POS3' ) or (tsCmd[0] = 'SERVER_PRS3' ) or (tsCmd[0] = 'SERVER_POS4' ) or (tsCmd[0] = 'SERVER_PRS4' )   then begin


      PrepareAnim;
      if tsCmd[0] = 'SERVER_CRO' then
        AnimationScript.Tsadd ( 'cl_mainskillused,Crossing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5])
      else if  Pos ( 'POS', tsCmd[0] ,1) <> 0 then
        AnimationScript.Tsadd ( 'cl_mainskillused,Power.Shot,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5])
      else if  Pos ( 'PRS', tsCmd[0] ,1) <> 0 then
        AnimationScript.Tsadd ( 'cl_mainskillused,Precision.Shot,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5])
      else if  tsCmd[0] =  'SERVER_COR' then
        AnimationScript.Tsadd ( 'cl_mainskillused,Crossing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;

      if (tsCmd[0] = 'SERVER_COR')then begin
        // prepare corner
        AnimationScript.Tsadd ('cl_prepare.corner,' +  tsCmd[1] +  ','+tsCmd[2]+ ','+tsCmd[3] );
      end;

      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

//***********************************************************************************************************
//
//           POS
//
//
//***********************************************************************************************************
        if tsCmd[0] = 'sc_pos.back.bounce' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_pos.back.swap.bounce' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end

        else if tsCmd[0] = 'sc_pos.bounce' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,0'  );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_pos.bounce.gk' then begin
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+',bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end

        //crossbar e gol uguali pos e prs
        else if (tsCmd[0] = 'sc_pos.bounce.crossbar')  or (tsCmd[0] = 'sc_prs.bounce.crossbar') then begin
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+',bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if (tsCmd[0] = 'sc_pos.gol') or  (tsCmd[0] = 'sc_prs.gol')  then begin
          // 1 ids aPlayer
          // 2 ids aGK
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGK
          // 6 celly aGK
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)

          AnimationScript.Tsadd ('cl_' + rightStr(tsCmd[0],7) +',' + IntToStr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,'+tsCmd[9]  );
        end

//***********************************************************************************************************
//
//          PRS
//
//
//***********************************************************************************************************


        else if tsCmd[0] = 'sc_prs.back.stealball' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball


          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_player.move,'  +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[7] + ','+tsCmd[8] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_prs.stealball' then begin
          // 1 ids aPlayer
          // 2 ids anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx anOpponent
          // 6 celly anOpponent
          // 7 cellx Ball
          // 8 celly Ball

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end
        else if tsCmd[0] = 'sc_prs.gk' then begin
          // 1 ids aPlayer
          // 2 aGK anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 aGK anOpponent
          // 6 aGK anOpponent
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );
        end



        else if tsCmd[0]='sc_bounce.heading' then begin  // ids , cellx, celly , dstcellx, dstcelly

//          aPlayer:= Mybrain.GetSoccerPlayer(tsCmd[1]);

          AnimationScript.Tsadd (  'cl_ball.bounce.heading,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]='sc_bounce.gk' then begin
//          aGK := Mybrain.GetSoccerPlayer  ( StrToInt(tsCmd[1]),StrToInt(tsCmd[2]));
          AnimationScript.Tsadd (  'cl_ball.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]='sc_bounce.crossbar' then begin
//          aGK := Mybrain.GetSoccerPlayer  ( StrToInt(tsCmd[1]),StrToInt(tsCmd[2]));
          AnimationScript.Tsadd (  'cl_ball.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]= 'sc_player.move.toball' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move.toball,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end

//***********************************************************************************************************
//
//           CORNER o CRO2 ( freekick2 )
//
//
//***********************************************************************************************************
    // in realtà qui sono già swappati nel brain
        else if (tsCmd[0] = 'sc_corner.headingdef.swap.bounce') or (tsCmd[0] = 'sc_cro2.headingdef.swap.bounce')  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aHeadingOpponent
          // 4 cellx Corner
          // 5 celly Corner
          // 6 cellx aPlayer
          // 7 celly aPlayer
          // 8 cellx aHeadingFriend    già swappati i 2 heading sul corner
          // 9 celly aHeadingFriend
          // 10 cellx aHeadingOpponent
          // 11 celly aHeadingOpponent
          // 12 cellx  Ball.cellx
          // 13 celly Ball.cellx
{                     TsScript.add ('sc_corner.headingdef.swap.bounce,' + aPlayer.Ids +','  + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly)
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));  }


          // già swappati nel corner
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[10] + ','+tsCmd[11]  +',' + tsCmd[8] + ','+tsCmd[9] );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[3] + ',' + tsCmd[8] + ','+tsCmd[9]  +',' + tsCmd[10] + ','+tsCmd[11] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,heading'  );


          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[12] + ','+tsCmd[13]+',0,0'  );

        end
        else if (tsCmd[0] = 'sc_corner.headingdef.bounce') or  (tsCmd[0] = 'sc_cro2.headingdef.bounce')   then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aHeadingOpponent
          // 4 cellx Corner
          // 5 celly Corner
          // 6 cellx aPlayer
          // 7 celly aPlayer
          // 8 cellx aHeadingOpponent
          // 9 celly aHeadingOpponent
          // 10 cellx  Ball.cellx
          // 11 celly Ball.cellx

                  {   TsScript.add ('sc_corner.headingdef.bounce,' + aPlayer.Ids +',' + aHeadingFriend.ids +',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));   }


          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );

        end
        else if (tsCmd[0] = 'sc_corner.headingatt.swap') or  (tsCmd[0] ='sc_cro2.headingatt.swap') then begin
          // 1 ids aHeadingFriend
          // 2 ids aHeadingOpponent
          // 3 cellx  aHeadingFriend
          // 4 celly aHeadingFriend
          // 5 cellx aHeadingOpponent
          // 6 celly aHeadingOpponent

                      { TsScript.add ('sc_corner.headingatt.swap,' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly)
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)); }
          // già swappati nel corner
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[1] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

        end
        else if (tsCmd[0] = 'sc_corner.bounce.gk') or (tsCmd[0] = 'sc_cro2.bounce.gk') then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  Corner
          // 5 celly Corner
          // 6 cellx  aPlayer
          // 7 celly aPlayer
          // 8 cellx  aHeadingFriend
          // 9 celly aHeadingFriend
          // 10 cellx aGK
          // 11 celly aGK
          // 12 cellx Ball
          // 13 celly Ball
          // 14 left right


                { TsScript.add ('sc_corner.bounce.gk,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) ); }
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[8]+ ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );
          AnimationScript.Tsadd ('cl_ball.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[12] + ','+tsCmd[13]+',0,0'  );

        end
        else if (tsCmd[0] = 'sc_corner.bounce.crossbar') or (tsCmd[0] = 'sc_cro2.bounce.crossbar') then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  Corner
          // 5 celly Corner
          // 6 cellx  aPlayer
          // 7 celly aPlayer
          // 8 cellx  aHeadingFriend
          // 9 celly aHeadingFriend
          // 10 cellx aGK
          // 11 celly aGK
          // 12 cellx Ball
          // 13 celly Ball
          // 14 left right

                 {  TsScript.add ('sc_pos.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) );   }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[8]+ ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[12] + ','+tsCmd[13]+',0,0'  );

        end
        else if (tsCmd[0] = 'sc_corner.gol') or (tsCmd[0] = 'sc_cro2.gol') then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  Corner
          // 5 celly Corner
          // 6 cellx  aPlayer
          // 7 celly aPlayer
          // 8 cellx  aHeadingFriend
          // 9 celly aHeadingFriend
          // 10 cellx aGK
          // 11 celly aGK
          // 12 cellx Ball
          // 13 celly Ball
          // 14 left right

                  { TsScript.add ('sc_corner.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) ); }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );

          if (tsCmd[0] = 'sc_corner.gol') then
            AnimationScript.Tsadd ('cl_corner.gol,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol'  )
          else if (tsCmd[0] = 'sc_cro2.gol') then
            AnimationScript.Tsadd ('cl_cro2.gol,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol'  );



    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 Z
    //7 Left o right 1 2

        end

//***********************************************************************************************************
//
//           CROSS
//
//
//***********************************************************************************************************


        else if tsCmd[0] = 'sc_cross.gol'  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  aPlayer
          // 5 celly aPlayer
          // 6 cellx  aHeadingFriend
          // 7 celly aHeadingFriend
          // 8 cellx aGK
          // 9 celly aGK
          // 10 cellx Ball
          // 11 celly Ball
          // 12 left right

                  { TsScript.add ('sc_cross.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) ); }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ',' + tsCmd[7]+',0,heading'  );

          AnimationScript.Tsadd ('cl_cross.gol,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+ tsCmd[11]+',0,gol'  );
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 Z
    //7 Left o right 1 2

        end
        else if tsCmd[0] = 'sc_cross.bounce.crossbar'  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  aPlayer
          // 5 celly aPlayer
          // 6 cellx  aHeadingFriend
          // 7 celly aHeadingFriend
          // 8 cellx aGK
          // 9 celly aGK
          // 10 cellx Ball
          // 11 celly Ball

                 {  TsScript.add ('sc_pos.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY)  );   }

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+',0,heading'  );
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[6]+ ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );

        end
        else if tsCmd[0] = 'sc_cross.bounce.gk'  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aGK
          // 4 cellx  aPlayer
          // 5 celly aPlayer
          // 6 cellx  aHeadingFriend
          // 7 celly aHeadingFriend
          // 8 cellx aGK
          // 9 celly aGK
          // 10 cellx Ball
          // 11 celly Ball
                  {TsScript.add ('sc_cross.bounce.gk,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY)  ); }


          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+',0,heading'  );
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[6]+ ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,bar'  );
          AnimationScript.Tsadd ('cl_ball.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );

        end
        else if tsCmd[0] = 'sc_cross.headingdef.swap.bounce'  then begin
          // 1 ids aPlayer
          // 2 ids aHeadingFriend
          // 3 ids aHeadingOpponent
          // 4 cellx aPlayer
          // 5 celly aPlayer
          // 6 cellx aHeadingFriend    già swappati i 2 heading sul corner
          // 7 celly aHeadingFriend
          // 8 cellx aHeadingOpponent
          // 9 celly aHeadingOpponent
          // 10 cellx  Ball.cellx
          // 11 celly Ball.cellx
{                   TsScript.add ('sc_cross.headingdef.swap.bounce,' + aPlayer.Ids +',' + aHeadingFriend.ids + ',' + aHeading.ids
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly)
                                                               + ',' + IntTostr(aHeading.cellx)+',' + IntTostr(aHeading.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));}


          // già swappati nel cross
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[8] + ','+tsCmd[9]  +',' + tsCmd[6] + ','+tsCmd[7] );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[3] + ',' + tsCmd[6] + ','+tsCmd[7]  +',' + tsCmd[8] + ','+tsCmd[9] );
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,heading'  );


          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );

        end
        else if tsCmd[0] = 'sc_cross.headingdef.bounce'  then begin
          // 1 ids aPlayer
          // 2 ids aGhost
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aGhost
          // 6 celly aGhost
          // 7 cellx  Ball.cellx
          // 8 celly Ball.cellx

                  { TsScript.add ('sc_cross.headingdef.bounce,' + aPlayer.Ids +',' + aGhost.ids + ','
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                               + ',' + IntTostr(aGhost.cellx)+',' + IntTostr(aGhost.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly)); }


          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,heading'  );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0'  );

        end





        else if tsCmd[0]='sc_ball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_ball.move.toball' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]= 'sc_gol.cross' then begin
          AnimationScript.Tsadd ('cl_gol.cross,' + tsCmd[1] + ','+ tsCmd[2]+','+tsCmd[3] + ','+ tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]= 'sc_CORNER.COA' then begin
//  TsScript.add ('sc_CORNER.COA,' + intTostr(TeamTurn) + ',' + IntTostr( CornerMap.CornerCell.X) +','+IntTostr( CornerMap.CornerCell.Y) ) ; // richiesta al client corner free kick
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 3500)));
//          AnimationScript.Ts.Insert(AnimationScript.Index + 1 ,'cl_wait,3000');
          AnimationScript.Tsadd ('cl_corner.coa,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );

        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;

        i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait,' + IntTostr((  Sprite1cell)));
      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
//      AnimationScript.Tsadd ('cl_wait,' + IntTostr( 1000 ));
      AnimationScript.Index := 0;

      Mybrain.tsScript.Clear ;
      FirstShowRoll;   // prima tutti i showroll da eseguire in AnimationScript

   end
   else if tsCmd[0] = 'SERVER_PASS' then begin   // tscmd[1] il team che passa
     // tt := tsCmd[1];
      PrepareAnim;
      SE_GridDicewriterow ( StrToInt( tsCmd[1]) , Translate('skill_pass'),  '',  '' , 'S','S.' + Translate('skill_pass'));
      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;
      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;

//      if tt = '0' then
//        AnimationScript.TsAdd  ( 'cl_tuc,' + '1')
 //       else AnimationScript.TsAdd  ( 'cl_tuc,' + '0');



   end
   else if (tsCmd[0] = 'SERVER_BUFFD') or (tsCmd[0] = 'SERVER_BUFFM') or (tsCmd[0] = 'SERVER_BUFFF') then begin   // tscmd[1] aPlayer.ids
      PrepareAnim;
      SE_GridDicewriterow ( StrToInt( tsCmd[1])  , tsCmd[0],  '',  '' , 'S','S.' + tsCmd[0] );
      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;
      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end


   // Corner

   else if tsCmd[0] = 'SERVER_COA.IS' then begin   // cof + swapstring

      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'COA.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_coa.is,' + tsCmd.CommaText );  // cof coa + swapstring
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      MouseWaitFor := WaitForXY_CornerCOD;

      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0] = 'SERVER_COD.IS' then begin

      PrepareAnim;
      MouseWaitFor :=  WaitForNone; //WaitForXY_CornerCOD := false;

      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'COD.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_cod.is,' + tsCmd.CommaText );  //  cod + swapstring
          AnimationScript.Tsadd ('cl_wait,2000');
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;


      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0] = 'SERVER_FKA1.IS' then begin
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin

          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
          if tsCmd[0] = 'FKA1.IS' then begin
            tsCmd.Delete(0);
            AnimationScript.Tsadd ('cl_fka1.is,' + tsCmd.CommaText );  // team, fka1 + swapstring
          end
          else AnimCommon ( tsCmd.commatext );

          i := i+1;
      end;

      AnimationScript.Index := 0;
      MouseWaitFor := WaitForNone;

      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0] = 'SERVER_FKA2.IS' then begin   // fka2 + swapstring
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin

        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKA2.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fka2.is,' + tsCmd.CommaText );  // team, fka1 + swapstring
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      MouseWaitFor := WaitForXY_FKD2;

      Mybrain.tsScript.Clear ;
   end

   else if tsCmd[0] = 'SERVER_FKD2.IS' then begin

      PrepareAnim;
      AnimationScript.Reset ;

      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKD2.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fka2.is,' + tsCmd.CommaText );  // team, fkd2 + swapstring
        end
        else  AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      MouseWaitFor := WaitForNone;


      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0] = 'SERVER_FKA3.IS' then begin   // fkf3 + swapstring
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKA3.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fka3.is,' + tsCmd.CommaText );  // team, fka3 + swapstring
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      MouseWaitFor := WaitForXY_FKD3;

      Mybrain.tsScript.Clear ;
   end

   else if tsCmd[0] = 'SERVER_FKD3.IS' then begin // barriera

      PrepareAnim;
      i:=1;

      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKD3.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fkd3.is,' + tsCmd.CommaText );  // team, fkd3 + swapstring
          AnimationScript.Tsadd ('cl_wait,2000');
        end
        else if (tsCmd[0]= 'sc_player.barrier')  then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move.barrier,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      MouseWaitFor := WaitForNone;
      AnimationScript.Index := 0;


      Mybrain.tsScript.Clear ;
   end

   else if tsCmd[0] = 'SERVER_FKA4.IS' then begin   // fkf4 + swapstring
      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

        if tsCmd[0] = 'FKA4.IS' then begin
          tsCmd.Delete(0);
          AnimationScript.Tsadd ('cl_fka4.is,' + tsCmd.CommaText );  // team, fkd4 + swapstring
          AnimationScript.Tsadd ('cl_wait,2000');
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      MouseWaitFor := WaitForNone;

      Mybrain.tsScript.Clear ;
   end


   else if tsCmd[0]= 'SERVER_TACTIC' then begin
      // il player è già posizionato


      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );
        if tsCmd[0] = 'sc_tactic' then begin
          AnimationScript.Tsadd ('cl_tactic,' +  tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] +  ',' + tsCmd[4]+ ',' + tsCmd[5]  ); // ids , defaultcellx, defaultcelly , newdefx, newdefy
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(1000));
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0]= 'SERVER_SUB' then begin
      // il player è già posizionato

      PrepareAnim;
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );
        if tsCmd[0] = 'sc_sub' then begin
          AnimationScript.Tsadd ('cl_sub,' +  tsCmd[1] + ',' + tsCmd[2] ); // ids1 , ids2
          AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
        end
        else AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0]= 'SERVER_STAY' then begin
      // il player è già posizionato
      PrepareAnim;
      AnimationScript.Tsadd ('cl_tactic,' +  tsCmd[1]  ); // ids1
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );
          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end
   else if tsCmd[0]= 'SERVER_FREE' then begin
      // il player è già posizionato
      PrepareAnim;
      AnimationScript.Tsadd ('cl_tactic,' +  tsCmd[1]  ); // ids1
      i:=1;
      while tsCmd[0] <> 'E' do begin
        tsCmd.CommaText := Mybrain.tsScript [i];
        LogMemo ( tsCmd.CommaText );

          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Index := 0;
      Mybrain.tsScript.Clear ;
   end


    //
    // esterni per semplici movimenti
    // comandi singoli
    //



   else if tsCmd[0]= 'SERVER_PRE' then begin
// server   TsScript.add ('SERVER_PRE,' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY) + ',' + IntToStr(Ball.Player.CellX) + ',' + IntToStr(Ball.Player.CellY) ) ;

      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Pressing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;
      AnimationScript.Tsadd ('cl_pressing,' + tsCmd[1] );
      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
        if tsCmd[0]= 'sc_dribbling.ok' then begin
          // 1 ids dribbling
          // 2 ids defender
          // 3 cellx provenienza tentativo dribbling
          // 4 celly provenienza tentativo dribbling
          // 5 cellX contrasto intermedio
          // 6 cellY contrasto intermedio
          // 7 cellx finale
          // 8 cellx finale

          BallPlayer := Mybrain.GetSoccerPlayer(tsCmd[1]);
          aTackle := Mybrain.GetSoccerPlayer(tsCmd[2]);

          AnimationScript.Tsadd ('cl_player.move.toball,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move.toball,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move.toball,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
//          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end
        else begin
          AnimCommon ( tsCmd.commatext );
        end;

          i := i+1;
      end;


      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Tsadd ('cl_wait,2500');
      AnimationScript.Index := 0;


      Mybrain.tsScript.Clear ;
   end

   else if tsCmd[0]= 'SERVER_PRO' then begin
// server    TsScript.add ('SERVER_PRO,' + aPlayer.ids + ',' + IntToStr(aPlayer.cellX) + ',' + IntToStr(aPlayer.cellY)+ ',' + IntToStr(aPlayer.cellX) + ',' + IntToStr(aPlayer.cellY) ) ;
      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Protection,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;
      AnimationScript.Tsadd ('cl_protection' );
      i:=1;


      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );
          AnimCommon ( tsCmd.commatext );
          i := i+1;
      end;

      AnimationScript.Tsadd ('cl_wait.moving.players'); // Attende che tutti i movimenti dei player siano terminati prima di procedere
      AnimationScript.Tsadd ('cl_wait,2500');
      AnimationScript.Index := 0;


      Mybrain.tsScript.Clear ;
   end;



//  if Mybrain.tsScript.count > 0 then begin
//    Mybrain.tsScript.Delete(0);
//  end;
  //Mybrain.tsScript.Clear ;
  TsCmd.Free;
  for i := 0 to AnimationScript.Ts.Count -1 do begin
    memo3.Lines.Add(AnimationScript.Ts[i]);
  end;


end;


procedure TForm1.FirstShowRoll ; // primo mostriamo i roll, in seguito l'animazione
var
  i,NextDice: Integer;
  Main : string;
  tmp: TStringList;
  label retry;
begin
//  nextdice := 0;
  for i := 1 to AnimationScript.Ts.Count -1 do begin   // a partire da 1. setto il mainskillused
    if LeftStr ( AnimationScript.Ts[i],16) = 'cl_mainskillused' then begin
      Main := AnimationScript.Ts[i];
      AnimationScript.Ts[i]:='';
//      NextDice:=i;
      Break;
    end;
  end;

//  if NextDice > 0 then   begin
//    AnimationScript.Ts.Insert(0,Main);
//    AnimationScript.Ts.Insert(1,'cl_wait,2000');
//  end;

  tmp := TStringList.Create;

  for i := 1 to AnimationScript.Ts.Count -1 do begin
    if LeftStr (AnimationScript.Ts[i],11) = 'cl_showroll' then begin
      tmp.add (AnimationScript.Ts[i]);
      AnimationScript.Ts[i]:='';
    end;
  end;

  for i := AnimationScript.Ts.Count -1 downto 1 do begin
    if AnimationScript.Ts[i] = '' then begin
      AnimationScript.Ts.Delete(i);
    end;
  end;

  NextDice:=1;
  for i := 0 to tmp.Count -1 do begin
      AnimationScript.Ts.Insert ( NextDice, tmp[i]);
//      AnimationScript.Ts.Insert ( NextDice+1, 'cl_wait,1600');
      NextDice := NextDice + 1;
  end;

  tmp.Free;

  // dopo ogni showroll o mainskilled inserisco il clwait, per dare un certo tempo di leggere i roll
Retry:
  for i := 0 to AnimationScript.Ts.Count -2 do begin
    if LeftStr (AnimationScript.Ts[i],11) = 'cl_showroll' then begin
      if pos ( 'cl_wait' , AnimationScript.Ts[i+1],1) = 0 then begin
        AnimationScript.Ts.Insert ( i+1,'cl_wait,1800');
        goto retry;
      end;
    end
    else if LeftStr (AnimationScript.Ts[i],16) = 'cl_mainskillused' then begin
      if pos ( 'cl_wait' , AnimationScript.Ts[i+1],1) = 0 then begin
        AnimationScript.Ts.Insert ( i+1,'cl_wait,1800');
        goto retry;
      end;
    end;
  end;


end;



procedure TForm1.UpdateSubSprites;
var
  p,i2: Integer;
  SeSprite,aSubSprite: SE_SubSprite;

  aPlayer: TSoccerPlayer;
begin

    for P:= 0 to MyBrain.lstSoccerPlayer.Count -1 do begin

        aPlayer:= MyBrain.lstSoccerPlayer [P];
        aPlayer.SE_Sprite.Labels.Clear ;
        aPlayer.SE_Sprite.RemoveAllSubSprites;
{        aPlayer.SE_Sprite.DeleteSubSprite('star' );
        aPlayer.SE_Sprite.DeleteSubSprite('disqualified' );
        aPlayer.SE_Sprite.DeleteSubSprite('injured' );
        aPlayer.SE_Sprite.DeleteSubSprite('yellow' );
        aPlayer.SE_Sprite.DeleteSubSprite('inout' );
        aPlayer.SE_Sprite.DeleteSubSprite('buffd' );
        aPlayer.SE_Sprite.DeleteSubSprite('buffm' );
        aPlayer.SE_Sprite.DeleteSubSprite('bufff' );
        aPlayer.SE_Sprite.DeleteSubSprite('stay' ); }   // lascio FACE
        AddFace ( aPlayer );

         if (aPlayer.BonusSHPturn > 0) or (aPlayer.BonusPLMTurn > 0)
         or (aPlayer.BonusTackleTurn > 0) or (aPlayer.BonusLopBallControlTurn > 0)
         or (aPlayer.BonusProtectionTurn > 0) or(aPlayer.BonusFinishingTurn > 0)
         then begin
            SeSprite := se_SubSprite.create ( dir_attributes + 'star.bmp','star', 0,0,true,true);
            aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
         end
         else if (aPlayer.RedCard > 0) or (aPlayer.Yellowcard = 2)
         or (aPlayer.disqualified > 0)
         then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'disqualified.bmp','disqualified', 0,0,true,true);
            aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
         end
         else if (aPlayer.Injured  > 0)  then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'injured.bmp','injured', 0,0,true,true);
            aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
         end
         else if (aPlayer.YellowCard  > 0)  then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'yellow.bmp','yellow', 0,0,true,true);
            aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
         end
         else if (aPlayer.PlayerOut  )  then begin
            SeSprite := se_SubSprite.create ( dir_interface + 'inout.bmp','inout', 0,0,true,true);
            aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
         end;

         if (aPlayer.stay  )  then begin
            if aPlayer.GuidTeam = MyGuidTeam then begin
              SeSprite := se_SubSprite.create ( dir_interface + 'stay.bmp','stay', 0,0,true,true);
              aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
            end;
         end;

         if (aPlayer.BonusbuffD > 0 )  then begin
            SeSprite := se_SubSprite.create ( dir_talent + '139.bmp','buffd', 0,18,true,true);
            SeSprite.lBmp.Stretch(12,12);
            aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
         end;
         if (aPlayer.BonusbuffM > 0 )  then begin
            SeSprite := se_SubSprite.create ( dir_talent + '140.bmp','buffm', 0,18,true,true);
            SeSprite.lBmp.Stretch(12,12);
//            aPlayer.se_sprite.FindSubSprite('buffm');
//            aPlayer.se_sprite.SubSprites[0].lX
            aPlayer.SE_Sprite.SubSprites.Add(SeSprite);

         end;
         if (aPlayer.BonusbuffF > 0 )  then begin
            SeSprite := se_SubSprite.create ( dir_talent + '141.bmp','bufff', 0,18,true,true);
            SeSprite.lBmp.Stretch(12,12);
            aPlayer.SE_Sprite.SubSprites.Add(SeSprite);

         end;

      // se l'avversario ha la palla ed è il nostro turno
          if (MyBrain.TeamTurn <> MyBrain.GetTeamBall) and (MyBrain.GetTeamBall <> -1)  then begin
           //  CreateTextChanceValueSE (  MyBrain.Ball.Player.ids, MyBrain.Ball.Player.BallControl   , dir_attributes + 'Ball.Control',0,0,0,0);
          end;
    end;
    for P:= 0 to MyBrain.lstSoccerReserve.Count -1 do begin

        aPlayer:= MyBrain.lstSoccerReserve [P];
        aPlayer.SE_Sprite.Labels.Clear ;
//        aPlayer.SE_Sprite.RemoveAllSubSprites;
        aPlayer.SE_Sprite.DeleteSubSprite('star' );
        aPlayer.SE_Sprite.DeleteSubSprite('disqualified' );
        aPlayer.SE_Sprite.DeleteSubSprite('injured' );
        aPlayer.SE_Sprite.DeleteSubSprite('yellow' );
        aPlayer.SE_Sprite.DeleteSubSprite('inout' );
        aPlayer.SE_Sprite.DeleteSubSprite('buffd' );
        aPlayer.SE_Sprite.DeleteSubSprite('buffm' );
        aPlayer.SE_Sprite.DeleteSubSprite('bufff' );
        aPlayer.SE_Sprite.DeleteSubSprite('stay' );    // lascio FACE
//        aPlayer.SE_Sprite.DeleteSubSprite('face' );    // lascio FACE

       if (aPlayer.RedCard > 0) or (aPlayer.Yellowcard = 2)
       or (aPlayer.disqualified > 0)
       then begin
          SeSprite := se_SubSprite.create ( dir_interface + 'disqualified.bmp','disqualified', 0,0,true,true);
          aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
       end
       else if (aPlayer.Injured  > 0)  then begin
          SeSprite := se_SubSprite.create ( dir_interface + 'injured.bmp','injured', 0,0,true,true);
          aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
       end
       else if (aPlayer.PlayerOut )  then begin
          SeSprite := se_SubSprite.create ( dir_interface + 'inout.bmp','inout', 0,0,true,true);
          aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
       end;


    end;

   for I2 := se_Players.SpriteCount -1 downto 0 do begin
    aSubSprite:= Se_Players.Sprites[i2].FindSubSprite('selected');
    if aSubSprite <> nil then
      Se_Players.Sprites[i2].SubSprites.Remove(aSubSprite);
   end;


end;


procedure TForm1.SE_GridAllBrainGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
  Sprite: SE_Sprite);
begin
  if GCD <= 0 then begin

    if CellX = 9 then begin   // ha cliccato su icona TV
      if SE_GridAllBrain.Cells[0,CellY].ids <> ''  then begin
        if (not viewMatch)  then begin
          gameScreen := ScreenWaitingWatchLive ;
          MemoC.Lines.Add('--->Tcp : viewmatch,' + SE_GridAllBrain.Cells[0,CellY].ids ); // col 0 = brainIds
          tcp.SendStr(  'viewmatch,' + SE_GridAllBrain.Cells[0,CellY].ids + EndofLine );
          viewMatch := True;
          SetGlobalCursor( crHourGlass);
        end;
      end;
    end;
    GCD := GCD_DEFAULT;
  end;


end;

procedure TForm1.SE_GridCountryTeamGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;  Sprite: SE_Sprite);
var
  y: Integer;
begin

  SelCountryTeam := SE_GridCountryTeam.Cells[0, CellY].ids;
  for y:= SE_GridCountryTeam.RowCount -1 downto 0 do begin
    SE_GridCountryTeam.Cells[0,y].FontColor := clWhite;
  end;

  SE_GridCountryTeam.Cells[0,CellY].FontColor := clYellow;
//  SE_GridCountryTeam.CellsEngine.ProcessSprites(20);
//  SE_GridCountryTeam.refreshSurface ( SE_GridCountryTeam );

end;

procedure TForm1.Anim ( Script: string );
var
  i,rndY,posY: Integer;
  ts: TstringList;
  aPoint: TPoint;
  netgol,head: Integer;
  aPath: dse_pathPlanner.Tpath;
  aStep: dse_pathPlanner.TpathStep ;
//  aCell,aCell2: TSoccerCell;
  aPlayer,aPlayer2, aTackle, aGK, aBarrierPlayer : TSoccerPlayer;
  srcCellX, srcCellY, dstCellX, dstCellY,Z : integer; // Source e destination Cells
  Dst, TmpX,tmpY: integer;
  CornerMap: TCornerMap;
  aCellBarrier: TPoint;
  sebmp: SE_Bitmap;
  seSprite: SE_Sprite;
//  ASoccerCellFK, ASoccerCell: TSoccerCell;
  modifierX,ModifierY,visX,visY: integer;
  aSEField: SE_Sprite;
  aSize:TSize;
  FaultBitmap: SE_Bitmap;
  ff:Byte;
  flags: Tstringlist;
begin


  ts := TstringList.Create ;
  ts.CommaText := Script;

  if ts[0] = 'cl_showroll' then begin
    //1 aPlayer.ids
    //2 Roll Totale
    //3 Skill used
    //4 N o F e talentid
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    flags:= Tstringlist.Create;
    flags.Delimiter :='.';
    flags.DelimitedText := ts[4];
    // i punteggi
    sebmp:= Se_bitmap.Create (32,32);
    if flags[0] = 'F' then
      sebmp.Bitmap.Canvas.Font.color := clMaroon
    else        //  'N'
      sebmp.Bitmap.Canvas.Font.color := clYellow;

    if flags[1] <> '0' then                        // si attiva il talento
      sebmp.Bitmap.Canvas.Font.Color := clGreen;
    flags.Free;

    sebmp.Bitmap.Canvas.Brush.color := clGray;
    sebmp.Bitmap.Canvas.Ellipse(6,6,26,26);
    sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
    sebmp.Bitmap.Canvas.Font.Size := 10;
    sebmp.Bitmap.Canvas.Font.Style := [fsbold];
    //sebmp.Bitmap.Canvas.Font.Color := clYellow;
    if length(  ts[2] ) = 1 then
      sebmp.Bitmap.Canvas.TextOut( 12,8, ts[2])
      else sebmp.Bitmap.Canvas.TextOut( 7,8, ts[2]);

    // o è una skill o è un attributo nel panelcombat
    if Translate ( 'skill_' + ts[3]) <> '' then
      SE_GridDicewriterow ( aplayer.Team,  UpperCase( Translate ( 'skill_' + ts[3])),  aplayer.surname,  aPlayer.ids , ts[2],  ts[4] )
      else SE_GridDicewriterow ( aplayer.Team,  UpperCase( Translate ( 'attribute_' + ts[3])),  aplayer.surname,  aPlayer.ids , ts[2],  ts[4] );

    SeSprite := se_numbers.CreateSprite( sebmp.bitmap, 'numbers', 1, 1, 100, aPlayer.SE_Sprite.Position.X  , aPlayer.SE_Sprite.Position.Y , true );
    SeSprite.LifeSpan := ShowRollLifeSpan;
    sebmp.Free;

  end
  else if ts[0] = 'cl_pressing' then begin
    //1 aPlayer.ids chi fa il pressing
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    SE_GridDicewriterow ( aplayer.Team,  UpperCase( Translate ( 'skill_Pressing')),  aplayer.surname,  aPlayer.ids , ''  , 'S.-2' );
   // SE_GridDicewriterow ( MyBrain.ball.player.Team,  UpperCase( Translate ( 'attribute_Ball.Control')),  MyBrain.ball.player.surname,  MyBrain.ball.player.ids , '-2'  , 'I.-2' );

  end
  else if ts[0] = 'cl_protection' then begin
    SE_GridDicewriterow ( MyBrain.ball.player.Team,  UpperCase( Translate ( 'skill_Protection')),  MyBrain.ball.player.surname,  MyBrain.ball.player.ids , ''  , 'S.+2' );
//  SE_GridDicewriterow ( MyBrain.ball.player.Team,  UpperCase( Translate ( 'attribute_Ball.Control')),  MyBrain.ball.player.surname,  MyBrain.ball.player.ids , '+2'  , 'I.+2' );
  end
  else if ts[0] = 'cl_mtbshowroll' then begin
    //1 aPlayer.ids
    //2 Roll Totale
    //3 Skill used
    //4 N o F e talentid
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    flags:= Tstringlist.Create;
    flags.Delimiter :='.';
    flags.DelimitedText := ts[4];

    if flags[1] <> '0' then                        // si attiva il talento
      sebmp.Bitmap.Canvas.Font.Color := clGreen;
    flags.Free;

    // i punteggi
    sebmp:= Se_bitmap.Create (32,32);
    sebmp.Bitmap.Canvas.Brush.color := clGray;
    sebmp.Bitmap.Canvas.Ellipse(6,6,26,26);
    sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
    sebmp.Bitmap.Canvas.Font.Size := 10;
    sebmp.Bitmap.Canvas.Font.Style := [fsbold];
  //  sebmp.Bitmap.Canvas.Font.Color := clYellow;
    if length(ts[2]) = 1 then
      sebmp.Bitmap.Canvas.TextOut( 12,8, ts[2])
      else sebmp.Bitmap.Canvas.TextOut( 7,8, ts[2]);
    SE_GridDicewriterow ( aplayer.Team,  UpperCase( Translate ( 'skill_Move')),  aplayer.surname,  aPlayer.ids , ts[2], ts[4] );

    SeSprite := se_numbers.CreateSprite( sebmp.bitmap, 'numbers', 1, 1, 100, aPlayer.SE_Sprite.Position.X  , aPlayer.SE_Sprite.Position.Y , true );
    SeSprite.LifeSpan := ShowRollLifeSpan;
    sebmp.Free;

  end
  else if ts[0] = 'cl_mainskillused' then begin
    //1 skill
    //2 aPlayer.ids
    //3 aPlayer.cellx
    //4 aPlayer.cellY
    //5 cellx         // non sempre
    //6 cellY         // non sempre
    aPlayer := MyBrain.GetSoccerPlayer(ts[2]);

    // la skill usata e i punteggi
    aSEField := SE_field.FindSprite( Ts[5] + '.' + Ts[6] );

    sebmp:= Se_bitmap.Create (80,14);
    sebmp.FillRect(0,0,sebmp.Width,sebmp.Height,$007B5139);
//    sebmp.Bitmap.Canvas.Brush.color := $007B5139;
    sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
    sebmp.Bitmap.Canvas.Font.Size := 8;
    sebmp.Bitmap.Canvas.Font.Style := [fsbold];
    sebmp.Bitmap.Canvas.Font.Color := clYellow;
    ASize:=sebmp.Bitmap.Canvas.TextExtent(ts[1]);
    sebmp.Resize( aSize.Width, aSize.Height, $007B5139  );
      sebmp.Bitmap.Canvas.Brush.Style := bsClear;
      sebmp.Bitmap.Canvas.TextOut( 1,0, ts[1]);
//    SE_GridDicewriterow ( ts[1], aplayer.surname,  aPlayer.ids , 'VS');

    posY := aSEField.Position.Y - 30;
    if PosY < 20 then posY := 30;


    SeSprite := se_numbers.CreateSprite( sebmp.bitmap, 'numbers', 1, 1, 100, aSEField.Position.X  ,  posY, false );
    SeSprite.LifeSpan := ShowRollLifeSpan * 2;
    sebmp.Free;

    HighLightField( StrToInt(Ts[3]), StrToInt(Ts[4]) , ShowRollLifeSpan * 2);
    HighLightField( StrToInt(Ts[5]), StrToInt(Ts[6]) , ShowRollLifeSpan * 2);

    posY := aSEField.Position.Y -aSize.Height;
    if PosY < 20 then posY := 30;

    SeSprite := se_numbers.CreateSprite( dir_interface + 'arrowmoving.bmp', 'cone', 8, 1, 5, aSEField.Position.X  ,posY , true );
//    seSprite.Angle := AngleOfLine( aPlayer.se_sprite.Position, aSEField.Position  ) ;
    SeSprite.LifeSpan := ShowRollLifeSpan * 2;
//    SeSprite.Scale := 50;

  end

  else if ts[0] = 'cl_sub' then begin

     // sono veramente già swappati sul brain , ma qui ancora no perchè il clientloadbrain ciene caricato dopo questo scritp
     aPlayer:= MyBrain.GetSoccerPlayer2(ts[1]);
     aPlayer2:= MyBrain.GetSoccerPlayer2(ts[2]);
     // sono veramente già swappati quindi la sefield è di aplayer2 , quello che verrà sostituito

     SE_GridDicewriterow ( aplayer.Team, Translate('lbl_Substitution'),  aplayer.surname,  aplayer2.surname , 'S','S.' + Translate('lbl_Substitution'));
     aSeField := SE_field.FindSprite( IntToStr(aPlayer2.CellX )+ '.' + IntToStr(aPlayer2.CellY ) );
     seSprite:= SE_interface.CreateSprite(InOutBitmap.BITMAP ,'inout',1,1,10,aSEField.Position.X, aSEField.Position.Y,true  );
     seSprite.LifeSpan := ShowFaultLifeSpan;


  end
  else if ts[0] = 'cl_tactic' then begin
     aPlayer:= MyBrain.GetSoccerPlayer2(ts[1]);
     SE_GridDicewriterow ( aplayer.Team, Translate('lbl_Tactic'),  aplayer.surname,  aplayer.ids , 'S','S.' + Translate('lbl_Tactic'));

  end
  else if (ts[0] = 'cl_buffd') or (ts[0] = 'cl_buffm') or (ts[0] = 'cl_bufff') then begin
     aPlayer:= MyBrain.GetSoccerPlayer2(ts[1]);
     SE_GridDicewriterow ( aplayer.Team, Translate('lbl_Tactic'),  aplayer.surname,  aplayer.ids , 'S','S.' + Translate('lbl_Tactic'));
  end
  else if ts[0] = 'cl_sound' then begin
    if ts[1]='soundishot' then begin
      playsound ( pchar (dir_sound +  'shot.wav' ) , 0, SND_FILENAME OR SND_ASYNC)
    end
    else if ts[1]='soundtackle' then begin
       playsound ( pchar (dir_sound +  'tackle.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
    end;
  end
  else if ts[0] = 'cl_red' then begin
    i_red(ts[1]);

  end
  else if ts[0] = 'cl_injured' then begin

    i_injured(ts[1]);
  end
  else if ts[0] = 'cl_yellow' then begin

    i_Yellow(ts[1]);
  end
  else if ts[0] = 'cl_tuc' then begin
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) and  (se_Ball.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      i_tuc ( ts[1]);
  end
  else if ts[0] = 'cl_tml' then begin
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) and  (se_Ball.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      i_tml ( ts[1], ts[2]);
  end
  else if ts[0] = 'cl_player.move.heading' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo per heading
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;
//    aPlayer.Sprite.NotifyDestinationReached := true;

  end
  else if ts[0] = 'cl_player.speed' then begin
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    aPlayer.Se_Sprite.MoverData.Speed := strToFloat(ts[2]);
  end
  else if ts[0] = 'cl_ball.stop' then begin
    MyBrain.Ball.Se_sprite.FrameXmax :=0;
  end
  else if ts[0] = 'cl_player.move.barrier' then begin

    ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
    aSeField := SE_field.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));

    rndY := RndGenerateRange(3,22);
    if Odd(RndGenerate(2)) then rndY := -rndY;
    aBarrierPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    aBarrierPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
//    aBarrierPlayer.SE_Sprite.Position := Point (aSeField.Position.X , aSeField.Position.Y + rndY);
  end
  else if ts[0] = 'cl_player.move' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;
//    aPlayer.Sprite.NotifyDestinationReached := true;
  end
  else if ts[0] = 'cl_player.move.toball' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    case aPlayer.team of
      0: begin
        Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X +abs(Ball0X),aSEField.Position.Y + BallZ0Y);
      end;
      1: begin
        Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X -abs(Ball0X),aSEField.Position.Y+ BallZ0Y);
      end;
    end;
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;
//    aPlayer.Sprite.NotifyDestinationReached := true;

  end
  else if ts[0] = 'cl_player.move.intercept' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

  end
  else if ts[0] = 'cl_player.move.strange' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

  end
  else if ts[0] = 'cl_ball.move' then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 ids eventuale azione
    //7 heading, intercept, stop ecc... oppure gol,bar, o un numero per dire quale angolo
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    Mybrain.Ball.SE_Sprite.Destinationreached:= false;
    Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
//    Mybrain.Ball.SE_Sprite.FrameXmax := Mybrain.Ball.SE_Sprite.FramesX ;
//    Mybrain.Ball.Moving :=True  ;

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    if ts[7] = 'heading' then begin
      Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X , aSEField.Position.Y - 20) ; // forza il calculateVectors
    end
    else if ts[7] = 'gol' then begin
      case dstCellX of
        0: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X -20 , aSEField.Position.Y ) ; // forza il calculateVectors
        end;
        11: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X +20 , aSEField.Position.Y ) ; // forza il calculateVectors
        end;
      end;
    end
    else if ts[7] = 'bar' then begin
      case dstCellX of
        0: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X -10 , aSEField.Position.Y ) ; // forza il calculateVectors
        end;
        11: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aSEField.Position.X +10 , aSEField.Position.Y ) ; // forza il calculateVectors
        end;
      end;

    end
{    else if ts[7] = '1' then begin
      aSEField := SE_field.FindSprite( '-1.2');
      Mybrain.Ball.se_sprite.MoverData.Destination := aSEField.Position

    end
    else if ts[7] = '2' then begin
      aSEField := SE_field.FindSprite( '11.2');
      Mybrain.Ball.se_sprite.MoverData.Destination := aSEField.Position

    end  }
    else
      Mybrain.Ball.se_sprite.MoverData.Destination := aSEField.Position;

  {    if Mybrain.Ball.Player <> nil then begin
        if Mybrain.Ball.Player.Role='G' then begin
          AudioNoGol.Position:=0;
          AudioNoGol.Play;
        end;
      end; }

  end
  else if ts[0] = 'cl_ball.move.toball' then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 ids eventuale azione
    //7 heading, intercept, stop ecc...
//    srcCellX :=  StrToInt(Ts[2]);
//    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);


    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    head:=0;
    if Ts[7] = 'heading' then head:= -20;
    Mybrain.Ball.SE_Sprite.Destinationreached:= false;
    Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
//    Mybrain.Ball.SE_Sprite.FrameXmax := Mybrain.Ball.SE_Sprite.FramesX ;
//    Mybrain.Ball.Moving :=True  ;

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    //aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

      if Mybrain.Ball.Player = nil then
        Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X ,aSEField.Position.Y + BallZ0Y+ head)
      else begin

        case Mybrain.Ball.Player.team of
          0: begin
            Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X  +abs(Ball0X),aSEField.Position.Y + BallZ0Y);
          end;
          1: begin
            Mybrain.Ball.SE_Sprite.MoverData.Destination := point (aSEField.Position.X -abs(Ball0X),aSEField.Position.Y + BallZ0Y);
          end;
        end;

        {if Mybrain.Ball.Player.Role='G' then begin
          AudioNoGol.Position:=0;
          AudioNoGol.Play;
        end;}
      end;


  end
  else if  (ts[0] = 'cl_ball.bounce') or (ts[0] = 'cl_ball.bounce.heading') or (ts[0] = 'cl_ball.bounce.back')
     or (ts[0] = 'cl_ball.bounce.crossbar') or (ts[0] = 'cl_ball.bounce.gk')
    then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 ids eventuale azione
    //7 heading, intercept, stop ecc...

   //QUI tsCmd [4] e tsCmd [5] indicano la cella di uscita - MyBrain.,ball è già sulla cella del corner

    if (ts[0] = 'cl_ball.bounce') or (ts[0] = 'cl_ball.bounce.heading') or (ts[0] = 'cl_ball.bounce.back') then begin
      playsound ( pchar (dir_sound +  'bounce.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
    end

    else if (ts[0] = 'cl_ball.bounce.gk') then  begin
      playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
    end;

//    (ts[0] = 'cl_ball.bounce.crossbar') <-- gestita in se_ball.destinationreached
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);

//    CornerMap := MyBrain.GetCorner ( MyBrain.TeamCorner ,  dstCellY, OpponentCorner );

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    Mybrain.Ball.SE_Sprite.Destinationreached:= false;
    Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
//    Mybrain.Ball.SE_Sprite.FrameXmax := Mybrain.Ball.SE_Sprite.FramesX ;
//    Mybrain.Ball.Moving :=True  ;

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    Mybrain.Ball.se_sprite.MoverData.Destination := aSEField.Position;

  end


  else if ts[0] = 'cl_prepare.corner' then begin

    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    CornerSetPlayer (aPlayer);

  end
  else if ts[0] = 'cl_wait' then begin
    //1 milliseconds
    AnimationScript.wait :=StrToInt(Ts[1]);

  end
  else if ts[0] = 'cl_wait.moving.players' then begin
    //1 milliseconds
    AnimationScript.waitMovingPlayers := true;

  end
  else if ts[0] = 'cl_destroy' then begin
//    AnimationScript.Reset ;
    SpriteReset ;
  end
  else if (ts[0]= 'cl_pos.gol') or (ts[0]= 'cl_prs.gol') or (ts[0]= 'cl_corner.gol') or (ts[0]= 'cl_cro2.gol') or (ts[0]= 'cl_cross.gol') or (ts[0]= 'cl_lop.gol') then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 Z
    //7 Left o right 1 2

    // la palla in MyBrain è già a 6 3 o 5 3, ma lo sprite no
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) and (se_ball.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);


    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    Mybrain.Ball.SE_Sprite.Destinationreached:= false;
    Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
//    Mybrain.Ball.SE_Sprite.FrameXmax := Mybrain.Ball.SE_Sprite.FramesX ;
//    Mybrain.Ball.Moving :=True  ;

    aSEField := SE_field.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
      case dstCellX of
        0: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point(  aSEField.Position.X - 20, aSEField.Position.Y);
        end;
        11: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point(  aSEField.Position.X + 20, aSEField.Position.Y);
        end;
      end;
      CreateSplash( 'Gol!', 2000 );
      SE_GridDicewriterow ( 0,   'Gol!!!',  '',  '' , '', 'I.'+'I.GOL!!!' );

  end
  else if ts[0]= 'cl_splash.gameover' then begin
    ShowMatchInfo;
//    SE_GridDicewriterow ( 0,  UpperCase( Translate ( 'lbl_GameOver' )),  '',  '' , '', '' );
//    playsound ( pchar (dir_sound +  'gameover.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
//    se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
    Sleep(2000);
    AnimationScript.Reset ;
    LiveMatch := False;
    ViewMatch := False;
    GameScreen := ScreenMain;
  end
// da qui in poi carico prima il brain
  else if ts[0]= 'cl_corner.coa' then begin   // richiede un coa , mostro lo splash corner
      // teamturn e corner , cornerx cornery

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
    PanelSkill.Visible := false;
     // Cl_BrainLoaded := true;
     // ClientLoadBrainSE(dir_data + Format('%.*d',[3, MyBrain.incMove+1]) + '.ini'); // forzo la lettura del brain, devo sapere adesso

      tscoa.Clear;
      //CreateSplash ('Corner',msSplashTurn);
      SE_GridDicewriterow ( 0,  UpperCase( Translate ( 'lbl_Corner' )),  '',  '' , 'I', 'I.CORNE' );


  end
  else if ts[0]= 'cl_coa.is' then begin  // conferma di COF + COA + swapstring scelto dal client e automatica richiesta COD

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

//      tscoa.Clear;
      tscod.Clear;

  end


  else if ts[0]= 'cl_cod.is' then begin  // conferma di COD + swapstring scelto dal client

     // tscod.Clear;
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;


  end
  else if ts[0]= 'cl_freekick1.fka1' then begin   // richiede un fka1 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
    tscoa.Clear;
    tscod.clear;

    SE_GridDicewriterow ( 0,  UpperCase( Translate ( 'lbl_FreeKick' )),  '',  '' , 'I', 'I.FREEKICK1' );

  end
  else if ts[0]= 'cl_freekick2.fka2' then begin   // richiede un fka2 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;
    SE_GridDicewriterow ( 0,  UpperCase( Translate ( 'lbl_FreeKick' )),  '',  '' , 'I', 'I.FREEKICK2' );


  end

  else if ts[0]= 'cl_freekick3.fka3' then begin   // richiede un fka3 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;
    SE_GridDicewriterow ( 0,  UpperCase( Translate ( 'lbl_FreeKick' )),  '',  '' , 'I', 'I.FREEKICK3' );


  end

  else if ts[0]= 'cl_freekick4.fka4' then begin   // richiede un fka4 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;
    SE_GridDicewriterow ( 0,  UpperCase( Translate ( 'lbl_FreeKick' )),  '',  '' ,'I', 'I.FREEKICK4' );

  end

  else if ts[0]= 'cl_fka1.is' then begin  // team, conferma di FKF1 + swapstring scelto dal client

    // attendo i precendenti sc_player
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

  end

  else if ts[0]= 'cl_fka2.is' then begin  // conferma di FKF2 + FKA2 + swapstring scelto dal client e automatica richiesta FKD2
//      tscoa.Clear;
      tscod.Clear;
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;



  end
  else if ts[0]= 'cl_fkd2.is' then begin  // conferma difkd2 + swapstring scelto dal client

     // tscod.Clear;
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;

  end

  else if ts[0]= 'cl_fka3.is' then begin  // conferma di FKF3 e basta + swapstring scelto dal client e automatica richiesta FKD2 (barriera)
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscod.Clear;



  end
  else if ts[0]= 'cl_fkd3.is' then begin  // conferma di fkd3 + swapstring scelto dal client  (barriera)

     // tscod.Clear;
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
        // tscod contiene l'ultimo cod barriera
       // schiera barriera

  end
  else if ts[0]= 'cl_fka4.is' then begin  // conferma di FKF4, la celladel rigore  era stata liberata
    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;


  end
  else if ts[0]= 'cl_fault' then begin    //  team a favore, cellx, celly
// TsScript.add ('sc_fault,' + aPlayer.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
     aPlayer := MyBrain.GetSoccerPlayer( ts[1] );
     if aPlayer.Team = 0 then ff := 1
     else ff := 0;
     FaultBitmap:= SE_Bitmap.Create ( FaultBitmapBW );
     ColorizeFault(  ff , FaultBitmap );
     aSeField := SE_field.FindSprite(  ts[2] + '.' + ts[3] );
     seSprite:= SE_interface.CreateSprite(FaultBitmap.BITMAP ,'fault',1,1,10,aSEField.Position.X, aSEField.Position.Y,true  );
     FaultBitmap.Free;
     seSprite.LifeSpan := ShowFaultLifeSpan;
     playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
     SE_GridDicewriterow ( aplayer.Team, Translate('lbl_Fault'),  aplayer.surname,  aPlayer.ids , 'I','I.FAULT');

  end
  else if ts[0]= 'cl_fault.cheatballgk' then begin   // TeamFavour, cerco il portiere avversario
     FaultBitmap:= SE_Bitmap.Create ( FaultBitmapBW );
     ColorizeFault(  StrToInt(ts[1]) , FaultBitmap );
     aSeField := SE_field.FindSprite(  ts[2] + '.' + ts[3] );
     seSprite:= SE_interface.CreateSprite(FaultBitmap.BITMAP ,'fault',1,1,10,aSEField.Position.X, aSEField.Position.Y,true  );
     FaultBitmap.Free;
     seSprite.LifeSpan := ShowFaultLifeSpan;
     SE_GridDicewriterow ( 0,  UpperCase( Translate ( 'lbl_Fault' )),  '',  '' , 'I','I.FAULT');
     playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);

     // sul server: TsScript.add ('sc_fault.cheatballgk,' + intTostr(TeamFaultFavour) +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo

     SE_GridDicewriterow ( StrToInt(ts[1]), Translate('lbl_Fault'),  '',  '' , 'I','I.FAULT');
  end
  else if ts[0]= 'cl_fault.cheatball' then begin  // TeamFavour, cerco la cella della palla
     FaultBitmap:= SE_Bitmap.Create ( FaultBitmapBW );
     ColorizeFault(  StrToInt(ts[1]) , FaultBitmap );
     aSeField := SE_field.FindSprite(  ts[2] + '.' + ts[3] );
     seSprite:= SE_interface.CreateSprite(FaultBitmap.BITMAP ,'fault',1,1,10,aSEField.Position.X, aSEField.Position.Y,true  );
     FaultBitmap.Free;
     seSprite.LifeSpan := ShowFaultLifeSpan;
// sul server:  TsScript.add ('sc_fault.cheatball,' + intTostr(TeamFaultFavour) + ',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo

     SE_GridDicewriterow ( StrToInt(ts[1]), Translate('lbl_Fault'),  '',  '' , 'I','I.FAULT');
     playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);

  end;

  ts.free;
  Application.ProcessMessages ;



end;

procedure TForm1.btnTacticsClick(Sender: TObject);
begin
(* Premuto durante la partita  mostra anche la formazione avversaria , premuto solo nel mio turno *)
    // posso cliccare quando è tuto fermo e quando sta a me

  if SE_DragGuid <> nil then
    Exit;

  if MyBrain.w_CornerSetup or MyBrain.w_CornerKick or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 or
  (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) or Animating  then Exit;

  if btnTactics.Down  then begin

    GameScreen := ScreenTactics ;

  end
  else begin

    SpriteReset;

    MyBrain.Ball.SE_Sprite.Visible := True;
    fGameScreen := ScreenLiveMatch;    // attenzione alla f, non innescare

  end;

end;
procedure TForm1.btnUniformBackClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    createNoiseTV;
    WAITING_GETFORMATION:= True;
    tcp.SendStr(  'setuniform,' +  TSUniforms[0].CommaText + ',' + TSUniforms[1].CommaText + endofline);
    PanelUniform.Visible:= false;
    GCD := GCD_DEFAULT;
  end;

end;

procedure TForm1.btnSubsClick(Sender: TObject);
begin
(* Premuto durante la partita , premuto solo nel mio turno *)
  if SE_DragGuid <> nil then
    Exit;
  if btnSubs.Down then begin

    // posso cliccare quando è tuto fermo e quando sta a me
    if MyBrain.w_CornerSetup or MyBrain.w_CornerKick or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 or
    (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) or Animating then Exit;

    GameScreen := ScreenSubs
  end
  else begin

    fGameScreen := ScreenLiveMatch;    // attenzione alla f, non innescare
    SpriteReset;
    MyBrain.Ball.SE_Sprite.Visible := True;

  end;
end;

procedure TForm1.btnWatchLiveClick(Sender: TObject);
begin

    if GCD <= 0 then begin
      MemoC.Lines.Add('--->Tcp : listmatch'  );
      if (not viewMatch) and (not LiveMatch) then tcp.SendStr( 'listmatch' + EndofLine );
      GCD := GCD_DEFAULT;
    end;

end;

procedure TForm1.btnWatchLiveExitClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    if ViewReplay then begin
      //AudioCrowd.Stop;
      ToolSpin.Visible := false;
      ViewReplay := false;
      WaitForSingleObject(MutexAnimation ,INFINITE);
      while (se_ball.IsAnySpriteMoving ) or (se_players.IsAnySpriteMoving )  do begin
        se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
        application.ProcessMessages ;
      end;
      ReleaseMutex(MutexAnimation);
      gamescreen := ScreenLogin;
    end
    else if viewMatch then begin
      //AudioCrowd.Stop;
      viewMatch := False;
      tcp.SendStr( 'closeviewmatch' + EndofLine);
      WaitForSingleObject(MutexAnimation,INFINITE);
      while (se_ball.IsAnySpriteMoving ) or (se_players.IsAnySpriteMoving ) do begin
        se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
        application.ProcessMessages ;
      end;
      ReleaseMutex(MutexAnimation);
      gamescreen := ScreenMain;
    end;

    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnxp0Click(Sender: TObject);
begin
  PanelXPPlayer0.Visible := True;
  SE_GridXP0.Active := True;
  SetupGridXP(SE_Gridxp0,lastMouseMovePlayer);
end;

procedure TForm1.btnxpBack0Click(Sender: TObject);
begin
  PanelXPPlayer0.Visible := false;
  SE_GridXP0.Active := False;

end;

procedure TForm1.btnConfirmDismissClick(Sender: TObject);
begin

  if GCD <= 0 then begin
    WAITING_GETFORMATION:= True;
    tcp.SendStr( 'dismiss,'+ se_grid0.SceneName + EndofLine); // solo a sinistra in formation
    PanelDismiss.Visible:= False;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.btnConfirmSellClick(Sender: TObject);
var
  i,tGK: Integer;
  aPlayer: TSoccerPlayer;
begin
  if GCD <= 0 then begin
    aPlayer:= MyBrainformation.GetSoccerPlayer2 (se_grid0.SceneName);
    if StrToIntDef(edtSell.Text,0) < aPlayer.MarketValue then begin
        ShowError ( Translate ('warning_nosell_lowprice'));
        edtSell.Text := IntToStr( aPlayer.MarketValue);
        Exit;
    end;

    GCD := GCD_DEFAULT;
    PanelSell.Visible := False;
    if aPlayer.TalentId1 = TALENT_ID_GOALKEEPER then begin
      tGK:=0;
      for I := MyBrainFormation.lstSoccerPlayer.Count -1 downto 0 do begin
        if MyBrainFormation.lstSoccerPlayer[i].TalentId1 = TALENT_ID_GOALKEEPER then
          tGK := tGK +1;
      end;
      if (tGK = 1) and (aPlayer.TalentId1 = TALENT_ID_GOALKEEPER) then begin
        ShowError ( Translate ('warning_nosellgk'));
        Exit;
      end;
    end;


      WAITING_GETFORMATION:= True;
      btnsell0.Tag:=1;
      btnsell0.Caption := Translate('lbl_CancelSell');
      tcp.SendStr( 'sell,'+ se_grid0.SceneName  + ',' + edtSell.Text + EndofLine); // solo a sinistra in formation
  end;

end;

procedure TForm1.btnDismiss0Click(Sender: TObject);
begin
  PanelDismiss.Visible := True;
  PanelDismiss.BringToFront;
end;

procedure TForm1.btnErrorOKClick(Sender: TObject);
begin
  PanelError.Visible := False;
  if lastStrError = 'errorlogin' then
    PanelLogin.Visible := True;

end;

procedure TForm1.btnExitClick(Sender: TObject);
begin
  Application.Terminate ;
end;

procedure TForm1.btnFormationClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    tcp.SendStr( 'getformation' + EndofLine);
    WAITING_GETFORMATION := True;
    GCD := GCD_DEFAULT;
  end;
end;

function TForm1.isTvCellFormation ( Team, CellX, CellY: integer ): boolean;
begin
  Result := False;
  case team of
    0: if ((CellX = 0) and (CellY=3)) or ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) then Result:= True;
    1: if ((CellX = 11) and (CellY=3)) or ((CellX = 9)  or  (CellX = 6) or (CellX = 3))  then Result:= True;
  end;

end;
procedure TForm1.MoveInReserves ( aPlayer: TSoccerPlayer );
var
  asefield: SE_Sprite;
  TvReserveCell: TPoint;
begin
//   aPlayer.Cells := MyBrain.PutInReserveSlot ( aPlayer );
   TvReserveCell:= MyBrainFormation.ReserveSlotTV [aPlayer.team,aPlayer.CellX,aPlayer.CellY  ];
   aSEField := SE_field.FindSprite(IntToStr (TvReserveCell.x ) + '.' + IntToStr (TvReserveCell.y ));

   aPlayer.se_sprite.MoverData.speed:=20;
   aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

end;
procedure TForm1.CancelDrag ( aPlayer: TsoccerPlayer; ResetCellX, ResetCellY: integer );
var
  aSEField : SE_Sprite;
begin
  if SE_DragGuid <> nil then begin
    aSEField := SE_field.FindSprite(IntToStr (ResetCellX ) + '.' + IntToStr (ResetCellY ));
    aPlayer.se_sprite.MoverData.speed:=20;
    aPlayer.SE_Sprite.MoverData.Destination := aSEField.Position ;
    SE_DragGuid := nil;
  end;
  SE_interface.RemoveAllSprites;

end;

procedure Tform1.HighLightField ( CellX, CellY, LifeSpan : integer);
var
  aSEField : SE_Sprite;
begin
  aSEField := SE_field.FindSprite(IntToStr (CellX ) + '.' + IntToStr (CellY ));
  aSEField.SubSprites[0].lVisible := true;
end;
procedure Tform1.HighLightFieldFriendly ( aPlayer: TSoccerPlayer; cells: char );
var
  i,Y,CellX: integer;
  aSEField : SE_Sprite;
  bmp: SE_Bitmap;
  aPlayer2: TSoccerPlayer;
begin

  // mostro il subsprite di un colore verde più chiaro

  if cells= 'b' then begin // solo sostituzioni , illumino solo possibili compagni da sostituire tenendo conto del GK
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
      aPlayer2 := MyBrain.lstSoccerPlayer[i];
      if aPlayer2.Team = aPlayer.Team  then begin
        if (aPlayer.TalentID1 = TALENT_ID_GOALKEEPER) and (aPlayer2.TalentID1 = TALENT_ID_GOALKEEPER) then begin
          aSEField := SE_field.FindSprite(IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
          aSEField.SubSprites[0].lVisible := true;
        end
        else if (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER) and (aPlayer2.TalentID1 <> TALENT_ID_GOALKEEPER) then begin
          aSEField := SE_field.FindSprite(IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
          aSEField.SubSprites[0].lVisible := true;
        end

      end;
    end;
  end
  else if cells= 's' then begin // solo sostituzioni a distanza > 4, illumino solo possibili compagni da sostituire tenendo conto del GK
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
      aPlayer2 := MyBrain.lstSoccerPlayer[i]; // può contenere -4 1 , un giocatore sostiuito
      if isOutSide ( aPlayer2.cellX, aPlayer2.cellY) then continue;
      
      if aPlayer2.Team = aPlayer.Team  then begin

        if AbsDistance(aPlayer2.CellX, aPlayer2.CellY, MyBrain.Ball.CellX ,MyBrain.Ball.celly) >= 4 then begin

          if (aPlayer.TalentID1 = TALENT_ID_GOALKEEPER) and (aPlayer2.TalentID1 = TALENT_ID_GOALKEEPER) then begin
            aSEField := SE_field.FindSprite(IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
            aSEField.SubSprites[0].lVisible := true;
          end
          else if (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER ) and (aPlayer2.TalentId1 <> TALENT_ID_GOALKEEPER) then begin

            aSEField := SE_field.FindSprite(IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
            aSEField.SubSprites[0].lVisible := true;
          end
        end;
      end;
    end;
  end

  else if cells = 'f' then begin // solo celle libere e del proprio team formation
    for CellX := 0 to 11 do begin
      for Y := 0 to 6 do begin
        aPlayer2 := MyBrain.GetSoccerPlayerDefault( CellX, Y );
        if aPlayer2 <> nil then Continue; // skip cella occupata da player
        if ((CellX = 0)  and (Y = 3)) or ((CellX = 11)  and (Y = 3)) then Continue; // tactic non permessa sulla cella portiere

        aSEField := SE_field.FindSprite(IntToStr ( CellX ) + '.' + IntToStr (Y ));


        if ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team = 0) then begin

            aSEField.SubSprites[0].lVisible := true;
        end
        else if ( (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team = 1) then begin

        end;

      end;

    end;
  end

  else if cells = 't' then begin // celle libere o occupate del proprio team formation
    for CellX := 0 to 11 do begin
      for Y := 0 to 6 do begin
        //aPlayer2 := MyBrain.GetSoccerPlayerDefault( CellX, Y );
        //if aPlayer2 <> nil then Continue; // skip cella occupata da player

        if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin   // non è un  goalkeeper

          if ((CellX = 0)  and (Y = 3)) or ((CellX = 11)  and (Y = 3)) then Continue; // tactic non permessa sulla cella portiere

          aSEField := SE_field.FindSprite(IntToStr ( CellX ) + '.' + IntToStr (Y ));


          if ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team = 0) then begin
            aSEField.SubSprites[0].lVisible := true;
          end
          else if ( (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team = 1) then begin
            aSEField.SubSprites[0].lVisible := true;

          end;

        end
        else begin  //  è un  goalkeeper

          if aPlayer.Team = 0 then begin
            aSEField := SE_field.FindSprite(IntToStr ( 0 ) + '.' + IntToStr ( 3 ));
          end
          else begin
            aSEField := SE_field.FindSprite(IntToStr ( 11 ) + '.' + IntToStr ( 3 ));
          end;

          aSEField.SubSprites[0].lVisible := true;

        end;

      end;

    end;
  end;

  bmp.Free;
end;
procedure Tform1.HighLightFieldFriendly_hide;
var
  i: Integer;
begin
  for I := 0 to SE_field.SpriteCount -1 do begin
    SE_field.Sprites [i].SubSprites[0].lVisible := false;

  end;
end;

procedure TForm1.hidechances ;
begin
   //for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
   // MyBrain.lstSoccerPlayer [i].SE_Sprite.Labels.Clear;
   //end;
   SE_interface.removeallSprites;
   HighLightFieldFriendly_hide;


end;
procedure TForm1.Schema0Click(Sender: TObject);
var
  Ha: byte;
begin
    if Btn_UniformHome.Down then
     ha := 0
     else ha :=1;

  //  UniformBitmap := SE_Bitmap.Create (dir_player + 'bw.bmp');
    tsUniforms[ha][3] := IntToStr( TCnSpeedButton(Sender).TAG ) ;
    PreLoadUniform( ha,  TCnSpeedButton(Sender).TAG );  // usa tsuniforms

end;

procedure Tform1.SelectedPlayerPopupSkill ( CellX, CellY: integer);
var
  i,y: integer;
  tmp: integer;
  aList : TObjectList<TSoccerPlayer>;
  label LoadGridSkill,PreloadGridSkill;
procedure setupBMp (bmp:TBitmap; aColor: Tcolor);
begin
  BMP.Canvas.Font.Size := 8;
  BMP.Canvas.Font.Quality := fqAntiAliased;
  BMP.Canvas.Font.Color := aColor; //$0041BEFF; //clBlack;//$00C0C0;
  BMP.Canvas.Font.Style :=[fsbold];
  BMP.Canvas.Brush.Style:= bsClear;
end;
begin

  case MousewaitFor of
{    WaitForXY_ShortPass:  ;
    WaitForXY_LoftedPass: ;
    WaitForXY_Crossing: ;
    WaitForXY_Move: ;
    WaitForXY_Dribbling: ;
    WaitFor_Corner: ;
    WaitForNone: ;
    WaitForAuth: ;
    WaitForXY_PowerShot: ;
    WaitForXY_PrecisionShot: ; }
    WaitForXY_FKF1: exit ;
    WaitForXY_FKF2: exit;
    WaitForXY_FKA2: exit;
    WaitForXY_FKD2: exit;
    WaitForXY_FKF3: exit;
    WaitForXY_FKD3: exit;
    WaitForXY_FKF4: exit;
    WaitForXY_CornerCOF: exit;
    WaitForXY_CornerCOA: exit;
    WaitForXY_CornerCOD: exit;
  end;

    if PanelCorner.Visible  then   // input solo da SE_GridFreeKick
      Exit;

  //  if MyBrain.w_CornerSetup  then SelectedPlayer := MyBrain.GetCof
  //  else SelectedPlayer :=  MyBrain.GetSoccerPlayer (  CellX, CellY );

    if MyBrain.w_FreeKick1 then SelectedPlayer := MyBrain.GetFK1
    else if MyBrain.w_FreeKick2 then SelectedPlayer := MyBrain.GetFK2
    else if MyBrain.w_FreeKick3 then SelectedPlayer := MyBrain.GetFK3
    else if MyBrain.w_FreeKick4 then SelectedPlayer := MyBrain.GetFK4
    else SelectedPlayer :=  MyBrain.GetSoccerPlayer (  CellX, CellY );


    if SelectedPlayer=nil then exit;
//    if SelectedPlayer.Team <> MyBrain.TeamTurn then begin
    if (SelectedPlayer.Team <> MyBrain.TeamTurn) or (SelectedPlayer.GuidTeam <> MyGuidTeam)  then begin
      exit;
    end;



    SelectedPlayer.ActiveSkills.Clear ;
    if Not SelectedPlayer.CanSkill then goto PreloadGridSkill;
//    if SelectedPlayer.GuidTeam <> MyGuidTeam then Exit;

   // HideChances;


    if SelectedPlayer.isCOF then begin
      if SelectedPlayer.Role <> 'G' then SelectedPlayer.ActiveSkills.Add('Corner.Kick=' + IntTostr(SelectedPlayer.Passing +
                                    Abs(Integer(   (SelectedPlayer.TalentId1 = TALENT_ID_CROSSING) or (SelectedPlayer.TalentId2 = TALENT_ID_CROSSING)  ))) );
      goto LoadGridSkill; // break
    end
    else if SelectedPlayer.isFK1 then begin
      if SelectedPlayer.Role <> 'G' then begin
        SelectedPlayer.ActiveSkills.Add('Short.Passing=' + IntTostr(SelectedPlayer.Passing ));
        SelectedPlayer.ActiveSkills.Add('Lofted.Pass=' + IntTostr(SelectedPlayer.Passing ));
        goto LoadGridSkill; // break
      end;
    end
    else if SelectedPlayer.isFK2 then begin
//      if SelectedPlayer.Role <> 'G' then SelectedPlayer.ActiveSkills.Add('Crossing=' + IntTostr(SelectedPlayer.Passing + SelectedPlayer.Tal_Crossing  ));
      Exit;
      goto LoadGridSkill; // break
    end
    else if SelectedPlayer.isFK3 then begin
      if SelectedPlayer.Role <> 'G' then begin
        SelectedPlayer.ActiveSkills.Add('Power.Shot=' + IntTostr(SelectedPlayer.shot  ));
        SelectedPlayer.ActiveSkills.Add('Precision.Shot=' + IntTostr(SelectedPlayer.shot  ));
        goto LoadGridSkill; // break
      end;
    end
    else if SelectedPlayer.isFK4 then begin
      if SelectedPlayer.Role <> 'G' then begin
        SelectedPlayer.ActiveSkills.Add('Power.Shot=' + IntTostr(SelectedPlayer.shot  ));
        SelectedPlayer.ActiveSkills.Add('Precision.Shot=' + IntTostr(SelectedPlayer.shot  ));
        goto LoadGridSkill; // break
      end;
    end;


    if (SelectedPlayer.CanMove) and (SelectedPlayer.Role <> 'G')then begin
      tmp:= SelectedPlayer.speed - Abs(Integer(SelectedPlayer.HasBall));
      if tmp <= 0 then tmp := 1;

      if not SelectedPlayer.PressingDone then SelectedPlayer.ActiveSkills.Add('Move=' + IntTostr( tmp  ) );
    end;



    if SelectedPlayer.HasBall then begin
      // Skill Standard Comuni
      if SelectedPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then // i gk non  usano short.passing (getlinepoints)
        SelectedPlayer.ActiveSkills.Add('Short.Passing=' + IntTostr(SelectedPlayer.Passing));//; + SelectedPlayer.tal_longpass)  );

      SelectedPlayer.ActiveSkills.Add('Lofted.Pass=' + IntTostr(SelectedPlayer.Passing ));//+ SelectedPlayer.tal_longpass  ));
      // Se nella metà campo avversaria e in shotCell aggiungo gli Shot

      if SelectedPlayer.InShotCell then begin
        SelectedPlayer.ActiveSkills.Add('Precision.Shot=' + IntTostr( SelectedPlayer.shot   ));
        SelectedPlayer.ActiveSkills.Add('Power.Shot=' + IntTostr( SelectedPlayer.Shot  ));
      end;

      if (SelectedPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) and not (MyBrain.w_CornerKick) and not (MyBrain.w_FreeKick1) and not (MyBrain.w_FreeKick2) and not
       (MyBrain.w_FreeKick3) and not(MyBrain.w_FreeKick4)
       then SelectedPlayer.ActiveSkills.Add('Protection=2'); // ha la palla

      if (SelectedPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) and ( MyBrain.GetFriendInCrossingArea( SelectedPlayer ) ) then begin // ha la palla
        SelectedPlayer.tmp :=0;
        if (SelectedPlayer.TalentId1 = TALENT_ID_CROSSING) or  (SelectedPlayer.TalentId2 = TALENT_ID_CROSSING) then
          SelectedPlayer.tmp := SelectedPlayer.tmp + 1;
        if (SelectedPlayer.TalentId2 = TALENT_ID_PRECISE_CROSSING) and ( (SelectedPlayer.CellX = 1)  or (SelectedPlayer.CellY = 10)  ) then
          SelectedPlayer.tmp := SelectedPlayer.tmp + 1;

        SelectedPlayer.ActiveSkills.Add('Crossing=' + IntTostr(SelectedPlayer.Passing + SelectedPlayer.tmp ));
      end;
      if SelectedPlayer.canDribbling then begin
        if (SelectedPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) then begin
          aList := TObjectList<TSoccerPlayer>.Create (false);
          MyBrain.GetNeighbournsOpponent (SelectedPlayer.cellX, SelectedPlayer.CellY, SelectedPlayer.Team, aList  );

          if aList.Count > 0 then begin
            SelectedPlayer.tmp :=0;
            if (SelectedPlayer.TalentId1 = TALENT_ID_DRIBBLING) or  (SelectedPlayer.TalentId2 = TALENT_ID_DRIBBLING) then
              SelectedPlayer.tmp := SelectedPlayer.tmp + 1;
            if (SelectedPlayer.TalentId2 = TALENT_ID_ADVANCED_DRIBBLING) then
              SelectedPlayer.tmp := SelectedPlayer.tmp + 1;

            SelectedPlayer.ActiveSkills.Add('Dribbling=' + IntTostr(SelectedPlayer.BallControl  + SelectedPlayer.tmp ) );
          end;
          // ha la palla e ci sono avversari a distanza 1 da potere dribblare
          aList.Free;
        end;
      end;
    end

    // se non ha la palla
    else if Not(SelectedPlayer.HasBall) then begin
        // se la palla è a distanza 1 e appartiene a un player avversario
      if  AbsDistance (Mybrain.Ball.CellX  ,Mybrain.Ball.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin
        if Mybrain.Ball.Player <> nil then begin
          if( AbsDistance ( SelectedPlayer.CellX, SelectedPlayer.CellY , Mybrain.Ball.CellX , Mybrain.Ball.CellY ) = 1) and
            (Mybrain.Ball.Player.Team <> SelectedPlayer.Team) and( MyBrain.Ball.Player.TalentId1 <> TALENT_ID_GOALKEEPER)  // se la palla è del gk no pressing
          then begin
            if (SelectedPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) and ( not SelectedPlayer.PressingDone) then
                  SelectedPlayer.ActiveSkills.Add('Tackle=' + IntTostr(SelectedPlayer.Defense  +
                                                  Abs(Integer(   (SelectedPlayer.TalentId1 = TALENT_ID_TOUGHNESS) or  (SelectedPlayer.TalentId2 = TALENT_ID_TOUGHNESS)  ))) );
            if (SelectedPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) and ( not SelectedPlayer.PressingDone) then SelectedPlayer.ActiveSkills.Add('Pressing=-2');
          end;
        end;
      end;


    end;

    if  MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 then
      goto LoadGridSkill;

PreLoadGridSkill:
    SelectedPlayer.ActiveSkills.Add('Pass=0');
    if (SelectedPlayer.Role <> 'G') then begin
      if SelectedPlayer.stay then SelectedPlayer.ActiveSkills.Add('Free=0')
      else SelectedPlayer.ActiveSkills.Add('Stay=0');
    {  buff reparto deve fare parte del reparto e avere il talento e il buff deve essere a 0 }
      if (SelectedPlayer.TalentId2 = TALENT_ID_BUFF_DEFENSE) and ( MyBrain.Score.BuffD[SelectedPlayer.team] = 0 )
      and ( SelectedPlayer.Role ='D') then
        SelectedPlayer.ActiveSkills.Add('BuffD=20');

      if (SelectedPlayer.TalentId2 = TALENT_ID_BUFF_MIDDLE) and ( MyBrain.Score.BuffM[SelectedPlayer.team] = 0 )
      and ( SelectedPlayer.Role ='M') then
        SelectedPlayer.ActiveSkills.Add('BuffM=20');

      if (SelectedPlayer.TalentId2 = TALENT_ID_BUFF_FORWARD) and ( MyBrain.Score.BuffF[SelectedPlayer.team] = 0 )
      and ( SelectedPlayer.Role ='F') then
        SelectedPlayer.ActiveSkills.Add('BuffF=20');
    end;
LoadGridSkill:
    if SelectedPlayer.ActiveSkills.count = 0 then
     Exit;

  SE_GridSkill.ClearData;
  SE_GridSkill.DefaultColWidth := 80;
  SE_GridSkill.DefaultRowHeight := 16;
  SE_GridSkill.Rows [0].Height := 16;
  SE_GridSkill.ColCount := 2;
  SE_GridSkill.RowCount := SelectedPlayer.ActiveSkills.count;
  SE_GridSkill.Columns[0].Width := 140;  // nome skill tradotta
  SE_GridSkill.Columns[1].Width := 16;

  SE_gridSkill.VirtualWidth := SE_GridSkill.TotalCellsWidth;
  SE_gridSkill.VirtualHeight := SE_GridSkill.TotalCellsHeight;

  for y := 0 to SE_GridSkill.RowCount -1 do begin
    SE_GridSkill.Rows[y].Height := 16;
    SE_GridSkill.Cells[0,y].BackColor := $007B5139;
    SE_GridSkill.Cells[0,y].FontName := 'Verdana';
    SE_GridSkill.Cells[0,y].FontSize := 8;
    SE_GridSkill.Cells[0,y].FontColor := clyellow; // $0041BEFF;
    SE_GridSkill.Cells[1,y].BackColor := $007B5139;
    SE_GridSkill.Cells[1,y].FontName := 'Verdana';
    SE_GridSkill.Cells[1,y].FontSize := 8;
    SE_GridSkill.Cells[1,y].FontColor  := clyellow; //$0041BEFF;
    SE_GridSkill.cells[1,y].CellAlignmentH := hCenter;      // username 1
  end;


  for I := 0 to SelectedPlayer.ActiveSkills.count -1 do begin
    se_gridskill.Cells[0,i].Ids := SelectedPlayer.ActiveSkills.Names [i]; // IDS contiene il nome della skill originale (English)
    se_gridskill.Cells[0,i].Text := Translate( 'skill_' + SelectedPlayer.ActiveSkills.Names [i]); // tradotta
    if SelectedPlayer.ActiveSkills.ValueFromIndex [i] <> '0' then se_gridskill.Cells[1,i].Text := SelectedPlayer.ActiveSkills.ValueFromIndex [i];
    if (se_gridskill.Cells[0,i].Ids  ='Stay') or  (se_gridskill.Cells[0,i].Ids ='Free') then begin
      se_gridskill.Cells[0,i].BackColor := clSilver;
      se_gridskill.Cells[1,i].BackColor := clSilver;
      se_gridskill.Cells[0,i].FontColor := clBlack;
      se_gridskill.Cells[1,i].FontColor := clBlack;
    end;
  end;

  SE_GridSkill.Width := 140+16;
  SE_GridSkill.Height := SE_GridSkill.Virtualheight;
  PanelSkill.Width := SE_gridskill.Width + 9;
  PanelSkill.Height := SE_gridskill.Height + 9;
  SE_GridSkill.Left := 3;
  SE_GridSkill.top := 3;
  PanelSkill.Left := SE_Theater1.Left + (SE_Theater1.Width div 2) - (PanelSkill.Width div 2);

  RoundCornerOf  ( PanelSkill );
  PanelSkill.Visible := True;

//    visX := se_Theater1.XVirtualToVisible(SelectedPlayer.SE_Sprite.Position.X) - (PanelSkill.Width div 2) + se_theater1.Left ;
//    visY := se_Theater1.YVirtualToVisible(SelectedPlayer.SE_Sprite.Position.Y + SelectedPlayer.SE_Sprite.BMP.Height div 2 )+10 +se_theater1.Top  ;
//    PanelSkill.Left := visX;
//    PanelSkill.Top := visY ;
  PanelSkill.BringToFront ;
  SE_GridSkill.CellsEngine.ProcessSprites(2000);
  SE_GridSkill.refreshSurface ( SE_GridSkill );

end;

procedure TForm1.SE_Theater1TheaterMouseMove(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Shift: TShiftState);
var
  aPlayer: TSoccerPlayer;
begin
//    caption := IntToStr(VirtualX) + '  ' +  IntToStr(VirtualY);
    panelsell.Visible := false;

    if (se_dragGuid <> nil) then begin


     se_dragGuid.MoverData.Destination := Point(VirtualX,VirtualY);
     se_dragGuid.Position := Point (VirtualX,VirtualY);

  //  if GameScreen = ScreenFormation then begin
  //     aPlayer := MyBrain.GetSoccerPlayer2 ( se_dragGuid.Guid );
  //     HighLightFieldFriendly ( aPlayer, 't' ); // team e talent goalkeeper  , illumina celle di formazione libere o occupate
  //   end;

    end;
end;

function TForm1.findlstSkill (SkillName: string ): integer;
var
  i: Integer;
begin
  for I := Low(LstSkill) to High(LstSkill) do begin
    if lstSkill[i]=SkillName then begin
      Result := i;
      Exit;
      end;
    end;
end;
procedure TForm1.SE_GridFreeKickGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
  Sprite: SE_Sprite);
var
  aCellBarrier : TPoint;
  CornerMap: tCornerMap;
  SwapPlayer: TSoccerPlayer;
  TeamCornerOrfreeKick: Integer;
  rndY : Integer;
  aSeField: SE_Sprite;
begin
  // Questa grid compare sui freekicks e sui corner. Permette di selezinare i giocatori dalla grid. Per esempio chi batterà il corner
  // e i 3 coa ( saltatori )
  if (GCD > 0) or (CellY = 0) then exit;
  // Qui sotto ci sono 3 blocchi: richiesta COF, FKF     COA      COD
  if SE_GridFreeKick.Cells [0,CellY].FontColor <> clSilver then begin  // squalificati, infortunati o già utilizzati sono tutti grigi
    SE_GridFreeKick.Cells [0,CellY].FontColor := clSilver;
    SE_GridFreeKick.Cells [1,CellY].FontColor := clSilver;
    SE_GridFreeKick.Cells [2,CellY].FontColor := clSilver;
    if  MouseWaitFor = WaitForXY_FKF1 then begin    // sto aspettando chi batterà una punizione freekick1

      SelectedPlayer:= MyBrain.GetSoccerPlayer(SE_GridFreeKick.Cells [0,CellY].ids  ) ; // ids
      TsCoa.add (SelectedPlayer.Ids);
      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
        tcp.SendStr( 'FREEKICK1_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
      GCD := GCD_DEFAULT;
      MouseWaitFor := WaitForNone;
      PanelCorner.Visible := False;
    end
    else if (MouseWaitFor = WaitForXY_FKF4) and (MyBrain.w_Fka4 ) then begin   // sto aspettando chi batterà un rigore
      SelectedPlayer:= MyBrain.GetSoccerPlayer(SE_GridFreeKick.Cells [0,CellY].ids  ) ; // ids
      TsCoa.add (SelectedPlayer.Ids);

      if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
        tcp.SendStr( 'FREEKICK4_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
      GCD := GCD_DEFAULT;
      MouseWaitFor := WaitForNone;
      PanelCorner.Visible := False;
    end
    else if (MouseWaitFor = WaitForXY_CornerCOF) or (MouseWaitFor = WaitForXY_FKF2)  then begin // sto aspettando chi batterà il corner

      SelectedPlayer:= MyBrain.GetSoccerPlayer(SE_GridFreeKick.Cells [0,CellY].ids  ) ; // ids
      tscoa.Add ( SelectedPlayer.Ids );

      if ((MouseWaitFor = WaitForXY_CornerCOF) and (MyBrain.w_Coa)) then begin
        MouseWaitFor := WaitForXY_CornerCOA;
        TeamCornerOrfreeKick :=  MyBrain.TeamCorner;
        CornerMap := MyBrain.GetCorner ( TeamCornerOrfreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
        aSeField := SE_field.FindSprite( IntToStr(CornerMap.CornerCell.X) +'.' + IntToStr(CornerMap.CornerCell.Y) );
        SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.CornerCell.X, CornerMap.CornerCell.Y);
        SelectedPlayer.SE_Sprite.MoverData.Destination := Point( aSEField.Position.X + CornerMap.CornerCellOffset.X , aSEField.Position.Y + CornerMap.CornerCellOffset.Y );

        while (MyBrain.GameStarted ) and ((Animating) or (se_players.IsAnySpriteMoving )) do begin
          se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
          application.ProcessMessages ;
        end;

        CornerSetPlayer(SelectedPlayer);
       // SelectedPlayer.SE_Sprite.Position := aSeField.Position;
      end
      else if ((MouseWaitFor = WaitForXY_FKF2) and (MyBrain.w_Fka2 )) then begin   // sto aspettando chi batterà una punizione freekick2
        aSeField := SE_field.FindSprite( IntToStr(MyBrain.Ball.cellX) +'.' + IntToStr(MyBrain.Ball.cellY) );
        SwapPlayer := MyBrain.GetSoccerPlayer( MyBrain.Ball.cellX,MyBrain.Ball.CellY);
        MouseWaitFor := WaitForXY_FKA2;
        TeamCornerOrfreeKick :=  MyBrain.TeamFreeKick;
        CornerMap := MyBrain.GetCorner ( TeamCornerOrfreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
        SelectedPlayer.SE_Sprite.MoverData.Destination :=  aSeField.Position;
       // SelectedPlayer.SE_Sprite.Position :=  aSeField.Position;
      end;




      // setto anche la palla
//        Mybrain.Ball.SE_Sprite.MoverData.Destination := aSeField.Position ;
//        Mybrain.Ball.SE_Sprite.Position := aSeField.Position ;


        // swappo come farà il brain un eventuale swapplayer
        if SwapPlayer <> nil then begin
          if SwapPlayer.Ids <> SelectedPlayer.ids then begin
          SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X   , aSeField.Position.Y + 30 );
        //  SwapPlayer.SE_Sprite.Position := Point (SelectedPlayer.SE_Sprite.Position.X   , SelectedPlayer.SE_Sprite.Position.Y +30);
          end;
        end;


//        SetPolyCellColor( CornerMap.HeadingCellA [0].X,CornerMap.HeadingCellA [0].Y, clyellow);
        if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then
          HighLightField ( CornerMap.HeadingCellA [0].X,CornerMap.HeadingCellA [0].Y,0);

      LoadGridFreeKick (TeamCornerOrfreeKick, 'Heading' , false);

      // ribadisco per via del reload
      SE_GridFreeKick.cells [0,CellY].FontColor := clSilver;
      SE_GridFreeKick.cells [1,CellY].FontColor := clSilver;
      SE_GridFreeKick.cells [2,CellY].FontColor := clSilver;

    end
    else if ((MouseWaitFor = WaitForXY_CornerCOA) and (MyBrain.w_Coa)) or ((MouseWaitFor = WaitForXY_FKA2) and (MyBrain.w_Fka2 ))  then begin

        SelectedPlayer:= MyBrain.GetSoccerPlayer(SE_GridFreeKick.Cells [0,CellY].ids  ) ; // ids
        // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)
        if ((MouseWaitFor = WaitForXY_CornerCOA) and (MyBrain.w_Coa)) then
          TeamCornerOrfreeKick :=  MyBrain.TeamCorner
          else if ((MouseWaitFor = WaitForXY_FKA2) and (MyBrain.w_Fka2 )) then
           TeamCornerOrfreeKick :=  MyBrain.TeamFreeKick;

        CornerMap := MyBrain.GetCorner ( TeamCornerOrfreeKick , Mybrain.Ball.CellY,OpponentCorner) ;


        aSeField := SE_field.FindSprite( IntToStr(CornerMap.HeadingCellA [TsCoa.count-1].X) +'.' + IntToStr(CornerMap.HeadingCellA [TsCoa.count-1].Y) );


        SelectedPlayer.SE_Sprite.MoverData.Destination := aSeField.Position ;
    //    SelectedPlayer.SE_Sprite.Position := aSeField.Position;

        // swappo come farà il brain un eventuale swapplayer
        SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellA [TsCoa.count-1].X, CornerMap.HeadingCellA [TsCoa.count-1].Y);
        TsCoa.add (SelectedPlayer.Ids);//<-- dopo la riga sopra

        if SwapPlayer <> nil then begin
          if SwapPlayer.Ids <> SelectedPlayer.ids then begin
          SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X, aSeField.Position.Y +30);
       //   SwapPlayer.SE_Sprite.Position := Point (SelectedPlayer.SE_Sprite.Position.X, SelectedPlayer.SE_Sprite.Position.Y +30);
          end;
        end;

        if tsCoa.Count = 4 then begin   // cof + 3 coa
          if ((MouseWaitFor = WaitForXY_CornerCOA) and (MyBrain.w_Coa)) then begin
            if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
              tcp.SendStr(  'CORNER_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
            MouseWaitFor := WaitForNone;
            PanelCorner.Visible := False;
          end
          else if ((MouseWaitFor = WaitForXY_FKA2) and (MyBrain.w_Fka2 )) then begin
            if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
              tcp.SendStr( 'FREEKICK2_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
            MouseWaitFor := WaitForNone;
            PanelCorner.Visible := False;
          end;
//            tsCoa.Clear ;  non svuotare
          exit;
        end;

      // se sono io
        if MyBrain.Score.AI[MyBrain.TeamTurn] = false then
          HighLightField( CornerMap.HeadingCellA [TsCoa.count-1].X,CornerMap.HeadingCellA [TsCoa.count-1].Y,0 );

    end
    else if ((MouseWaitFor = WaitForXY_CornerCOD) and (MyBrain.w_Cod)) or ((MouseWaitFor = WaitForXY_FKD2) and (MyBrain.w_Fkd2 )) then begin
      SelectedPlayer:= MyBrain.GetSoccerPlayer(SE_GridFreeKick.Cells [0,CellY].ids ) ; // ids

      // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)
      if ((MouseWaitFor = WaitForXY_CornerCOD) and (MyBrain.w_CoD)) then
        TeamCornerOrfreeKick :=  MyBrain.TeamCorner
        else if ((MouseWaitFor = WaitForXY_FKD2) and (MyBrain.w_Fkd2 )) then
         TeamCornerOrfreeKick :=  MyBrain.TeamFreeKick;
      CornerMap := MyBrain.GetCorner ( TeamCornerOrfreeKick , Mybrain.Ball.CellY,OpponentCorner) ;

      aSeField := SE_field.FindSprite( IntToStr(CornerMap.HeadingCellD [TsCod.count].X) +'.' + IntToStr(CornerMap.HeadingCellD [TsCod.count].Y) );

      // 2 direzioni in cui guardare ... fix?
      SelectedPlayer.SE_Sprite.MoverData.Destination := aSeField.Position ;
   //   SelectedPlayer.SE_Sprite.Position := aSeField.Position ;

      // swappo non come farà il brain un eventuale swapplayer, ma affianco gli sprite
      TsCod.add (SelectedPlayer.Ids);//<-- prima della riga sotto
      SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellD [TsCod.count-1].X, CornerMap.HeadingCellD [TsCod.count-1].Y);

      if SwapPlayer <> nil then begin
        if SwapPlayer.Ids <> SelectedPlayer.ids then begin
        SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X   , aSeField.Position.Y +30);
    //    SwapPlayer.SE_Sprite.Position := Point (SelectedPlayer.SE_Sprite.Position.X   , SelectedPlayer.SE_Sprite.Position.Y +30);
        end;
      end;

      if tsCod.Count = 3 then begin  // 3 cod
        if ((MouseWaitFor = WaitForXY_CornerCOD) and (MyBrain.w_Cod)) then begin
          if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
            tcp.SendStr( 'CORNER_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
          MouseWaitFor := WaitForNone;
          PanelCorner.Visible := False;
        end
        else if ((MouseWaitFor = WaitForXY_FKD2) and (MyBrain.w_Fkd2 )) then begin
          if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
            tcp.SendStr( 'FREEKICK2_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
          MouseWaitFor := WaitForNone;
          GCD := GCD_DEFAULT;
          PanelCorner.Visible := False;
        end;
        exit;
      end;

      //c'è exit sopra, TsCod.count è corretto
      if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then
        HighLightField( CornerMap.HeadingCellD [TsCod.count].X,CornerMap.HeadingCellD [TsCod.count].Y ,0);
      // sposto la freccia
//          aSprite := e_Highlights.FindSpritebyIDS('arrowcor' );
//          aCell:= GetPolyCells (CornerMap.HeadingCellD [TsCod.count].X,CornerMap.HeadingCellD [TsCod.count].Y );
//          aSprite.MoverData.Destination :=   Point (aCell.PixelX , aCell.pixelY -20);
//          aSprite.Position := Point (aCell.PixelX , aCell.pixelY -20);


    end
    else if (MouseWaitFor = WaitForXY_FKF3) and (MyBrain.w_Fka3 ) then begin // punizione dal limite
      SelectedPlayer:= MyBrain.GetSoccerPlayer(SE_GridFreeKick.Cells [0,CellY].ids  ) ; // ids
      TsCoa.add (SelectedPlayer.Ids);

      aSeField := SE_field.FindSprite( IntToStr(MyBrain.Ball.CellX) +'.' + IntToStr(MyBrain.Ball.CellY) );
//          SwapPlayer := MyBrain.GetSoccerPlayer( MyBrain.Ball.cellX,MyBrain.Ball.CellY);
      MouseWaitFor := WaitForXY_FKD3;
//          CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
      // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)

     // ACellBarrier :=  MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
     // aSeField := SE_field.FindSprite( IntToStr(ACellBarrier.X) +'.' + IntToStr(ACellBarrier.Y) );
      SelectedPlayer.SE_Sprite.MoverData.Destination := aSeField.Position ;

     //   if SwapPlayer <> nil then begin
     //     if SwapPlayer.Ids <> SelectedPlayer.ids then begin
     //       SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X , aSeField.Position.Y + 30) ;
     //     end;
     //   end;

    //  if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then
    //    HighLightField( ACellBarrier.X, ACellBarrier.Y ,0);

        if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'FREEKICK3_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
        PanelCorner.Visible := False;
        GCD := GCD_DEFAULT;

    end
    else if ((MouseWaitFor = WaitForXY_FKD3) and (MyBrain.w_Fkd3 )) then begin // BARRIERA
      SelectedPlayer:= MyBrain.GetSoccerPlayer(SE_GridFreeKick.Cells [0,CellY].ids  ) ; // ids

      // la posizione degli sprite deve essere eseguita adesso. Dal server arriverà la conferma (e quindi Spritereset)
      CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
      ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.CellY)  ; // la cella barriera !!!!
      aSeField := SE_field.FindSprite( IntToStr(ACellBarrier.X) +'.' + IntToStr(ACellBarrier.Y) );


      rndY := RndGenerateRange(3,22);
      if Odd(RndGenerate(2)) then rndY := -rndY;

      SelectedPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X  , aSeField.Position.Y + rndY);
  //    SelectedPlayer.SE_Sprite.Position := Point (aSeField.Position.X  , aSeField.Position.Y + rndY);

      // swappo non come farà il brain un eventuale swapplayer, ma affianco gli sprite
      TsCod.add (SelectedPlayer.Ids);// in barriera swappo solo il primo
      if tsCod.Count = 1 then begin // in barriera swappo solo il primo
        SwapPlayer := MyBrain.GetSoccerPlayer( ACellBarrier.X , ACellBarrier.Y );

        if SwapPlayer <> nil then begin
          if SwapPlayer.Ids <> SelectedPlayer.ids then begin
           SwapPlayer.SE_Sprite.MoverData.Destination := Point (aSeField.Position.X +30  , aSeField.Position.Y   );
     //     SwapPlayer.SE_Sprite.Position := Point (SelectedPlayer.SE_Sprite.Position.X   , SelectedPlayer.SE_Sprite.Position.Y + 30);
          end;
        end;
      end
      else if tsCod.Count = 4 then begin  // 4 in barriera
        if  ( LiveMatch ) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
          tcp.SendStr( 'FREEKICK3_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
        PanelCorner.Visible := False;
        GCD := GCD_DEFAULT;
        MouseWaitFor := WaitForNone;
        exit;
      end;

    end;


  end;
end;

procedure TForm1.SE_GridMarketGridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
  Sprite: SE_Sprite);
begin
  if GCD <= 0 then begin

    if MyBrainFormation.lstSoccerPlayer.Count < 18 then begin
      WAITING_GETFORMATION:= True;
      tcp.SendStr( 'buy,'+ SE_GridMarket.Cells[0,CellY].ids + EndofLine)
    end
      else ShowError(Translate('warning_max18'));
    GCD := GCD_DEFAULT;
  end;

end;

procedure TForm1.LoadGridFreeKick ( team : integer; Stat:string; clearMark: boolean );
var
  i,Y: integer;
  aPlayer: TSoccerPlayer;
begin
  PanelSkill.Visible := False;

  if ClearMark then begin
    SE_GridFreeKick.ClearData ;  // sul corner i COA seguono il COF e il COF non può essere anche un COA
    SE_GridFreeKick.DefaultColWidth := 120;
    SE_GridFreeKick.DefaultRowHeight := 16;
    SE_GridFreeKick.ColCount := 3; // Role, Surname, Attribute Value
    SE_GridFreeKick.RowCount := 12; // header + al massimo 11 giocatori in campo in quel momento

    SE_GridFreeKick.Columns [0].Width:=50;
    SE_GridFreeKick.Columns [1].Width:=120;
    SE_GridFreeKick.Columns [2].Width:=80;
    SE_GridFreeKick.Height := (SE_GridFreeKick.RowCount * SE_GridFreeKick.DefaultRowHeight  ) + 4 ;
    SE_GridFreeKick.Width := SE_GridFreeKick.VirtualWidth;

    // colori header
    SE_GridFreeKick.Rows[0].Height := 16;
    SE_GridFreeKick.Cells [0,0].FontColor := clWhite;
    SE_GridFreeKick.Cells [1,0].FontColor := clWhite;
    SE_GridFreeKick.Cells [2,0].FontColor := clWhite;
    SE_GridFreeKick.Cells [0,0].BackColor := clblack;
    SE_GridFreeKick.Cells [1,0].BackColor := clblack;
    SE_GridFreeKick.Cells [2,0].BackColor := clblack;

    //colori rows
    for y := 1 to SE_GridFreeKick.RowCount -1 do begin
      SE_GridFreeKick.Rows[y].Height := 16;

      SE_GridFreeKick.Cells [0,y].FontName := 'Verdana';
      SE_GridFreeKick.Cells [0,y].FontSize := 8;
      SE_GridFreeKick.cells [0,y].FontColor := clWhite;

      SE_GridFreeKick.Cells [1,y].FontName := 'Verdana';
      SE_GridFreeKick.Cells [1,y].FontSize := 8;
      SE_GridFreeKick.cells [1,y].FontColor := clWhite;

      SE_GridFreeKick.Cells [2,y].FontName := 'Verdana';
      SE_GridFreeKick.Cells [2,y].FontSize := 8;
      SE_GridFreeKick.cells [2,y].FontColor := clWhite;

      SE_GridFreeKick.Cells [0,y].CellAlignmentH := hCenter;
      SE_GridFreeKick.Cells [2,y].CellAlignmentH  := hCenter;

    end;

    SE_GridFreeKick.Cells [0,0].Text := Translate ( 'lbl_Role');
    SE_GridFreeKick.Cells [1,0].Text := Translate ( 'lbl_Surname');
    SE_GridFreeKick.Cells [2,0].Text := stat; //Translate (Stat);

  end;


  Y := 1;
  for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
    aPlayer:= MyBrain.lstSoccerPlayer[i];
    if aPlayer.Team = Team then begin
      if aPlayer.Gameover then Continue; // espulsi  o sostituiti

      if aPlayer.Role = 'G' then begin
        SE_GridFreeKick.Cells [0, Y].FontColor := clSilver;
        SE_GridFreeKick.Cells [1, Y].FontColor := clSilver;
        SE_GridFreeKick.Cells [2, Y].FontColor := clSilver;
      end;

      SE_GridFreeKick.Cells [0, Y].ids  :=aPlayer.Ids ;
      SE_GridFreeKick.Cells [0, Y].Text :=aPlayer.Role;
      SE_GridFreeKick.Cells [1, Y].Text :=aPlayer.Surname;


      if (Stat = 'Crossing') or (Stat = 'Passing')  then begin
        aPlayer.tmp :=0;
        if (aPlayer.TalentId1 = TALENT_ID_CROSSING) or  (aPlayer.TalentId2 = TALENT_ID_CROSSING) then
          aPlayer.tmp := aPlayer.tmp + 1;
        // se è corner oppure se la palla è sul fondo. la palla, non il player
        if (MyBrain.w_CornerSetup) or ( ( MyBrain.Ball.CellX = 1)  or (MyBrain.Ball.CellY = 10)  ) and
          (aPlayer.TalentId2 = TALENT_ID_PRECISE_CROSSING)  then
            SelectedPlayer.tmp := SelectedPlayer.tmp + 1;

        SE_GridFreeKick.Cells [2,Y].Text := IntTostr (aPlayer.defaultPassing + SelectedPlayer.tmp);
      end
      else if Stat = 'Heading' then
        SE_GridFreeKick.Cells [2,Y].Text := IntTostr(aPlayer.defaultheading)
      else if Stat = 'Shot' then
        SE_GridFreeKick.Cells [2,Y].Text := IntTostr(aPlayer.DefaultShot )
      else if Stat = 'Defense' then
        SE_GridFreeKick.Cells [2,Y].Text := IntTostr(aPlayer.defaultDefense);

      inc (Y);
    end;
  end;

  SE_GridFreeKick.CellsEngine.ProcessSprites(2000);
  SE_GridFreeKick.refreshSurface ( SE_GridFreeKick );
  PanelCorner.Height := SE_GridFreeKick.Height + 8;
  PanelCorner.Visible := True;

end;
function TForm1.GetDominantColor ( Team: integer  ): TColor;
begin
  if Team = 0 then result := clred
    else Result := $FE0001;

end;
function TForm1.GetContrastColor( cl: TColor  ): TColor;
var
  a: double;
  d: Integer;
  aTrgb: DSE_defs.TRGB;
begin
    aTrgb := TColor2TRGB(cl);

    a := 1 - ( 0.299 * aTrgb.R + 0.587 * aTrgb.G + 0.114 * aTrgb.B)/255;

    if (a < 0.5) then
       d := 0 // bright colors - black font
    else
       d  := 254; // dark colors - white font  non 355 clwhite usato per bsclear
    aTrgb.r := d;
    aTrgb.g := d;
    aTrgb.b := d;
    Result := TRGB2TColor(aTrgb);
end;

procedure TForm1.SE_Theater1SpriteMouseDown(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton;
  Shift: TShiftState);
var
  i: integer;
  aPlayer: TSoccerPlayer;
  FriendlyWall,OpponentWall,FinalWall: boolean;
  MoveValue: Integer;
  MyParam: TSoccerParam;
  aHeadingFriend,aFriend: TSoccerPlayer;
  aPoint: TPoint;
  CellX,CellY: integer;
  aPath: dse_pathPlanner.Tpath;
  Highlight: SE_SubSprite;
  aSeField: SE_Sprite;

begin
  if (animating) or (not se_Theater1.Active)  then Exit;

  if GameScreen = ScreenFormation then begin

    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites

        aPlayer := findPlayerMyBrainFormation (lstSprite[i].guid);
     //  if (Button = mbLeft) and (SE_DragGuid = nil) then begin
//          lstSprite[i].ChangeBitmap( dir_player + 'face.bmp',1,1,1000 );
 //       end
        if Button = mbLeft then begin
          if (aPlayer.GuidTeam = MyGuidTeam) and (aPlayer.disqualified = 0) then begin
            se_dragGuid := lstSprite[i];
            HighLightFieldFriendly ( aPlayer, 't' ); // team e talent goalkeeper  , illumina celle di formazione libere o occupate
            if MyBrain.isReserveSlot(aPlayer.CellX , aPlayer.CellX ) then
              MyBrain.ReserveSlot[0,aPlayer.CellX,aPlayer.celly]:='';
            Exit;
          end
          else SE_DragGuid := nil;
        end;
      end;
    end;


  end

  else if (GameScreen  = ScreenWaitingLiveMatch)  or (GameScreen = ScreenWaitingWatchLive) then begin
    for I := 0 to lstSprite.Count -1 do begin
      if lstSprite[i].Guid = 'cancel' then begin
        if GCD <= 0 then begin
          if (GameScreen  = ScreenWaitingLiveMatch) then
            tcp.SendStr( 'cancelqueue' + EndofLine)
            else if (GameScreen  = ScreenWaitingWatchLive) then
            tcp.SendStr( 'cancelqueuespectator' + EndofLine);
          GCD := GCD_DEFAULT;
        end;
        GameScreen := ScreenMain;
        Exit;
      end;
    end;

  end

  else if GameScreen = ScreenTactics then begin

    if Button = MbRight then begin
      if SE_DragGuid <> nil then begin
        aPlayer := MyBrain.GetSoccerPlayer2 (Se_dragGuid.guid); // trova tutti  comunque
        if aPlayer <> nil then
          CancelDrag (aPlayer, aPlayer.defaultcellX, aPlayer.defaultCellY);
      end;
      SE_DragGuid := nil;
      HighLightFieldFriendly_hide;
      GameScreen := ScreenTactics ;
      Exit;
    end;
    SE_interface.RemoveAllSprites;


      for I := 0 to lstSprite.Count -1 do begin

        if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites

            aPlayer := MyBrain.GetSoccerPlayer2 (lstSprite[i].guid); // trova tutti  comunque
            if aPlayer.GuidTeam  <> MyGuidTeam then begin // sposto solo i miei
              CancelDrag(aPlayer, aPlayer.DefaultCellX, aPlayer.DefaultCellY );
              Exit;
            end;

            if (aPlayer.GuidTeam = MyGuidTeam) and (aPlayer.disqualified = 0) and not (aPlayer.Gameover ) then begin
                SE_dragGuid := lstSprite[i];
                if not MyBrain.isReserveSlot ( aPlayer.CellX, aPlayer.CellY) then
                  HighLightFieldFriendly ( aPlayer, 'f' ); // team e talent goalkeeper  , illumina celle di formazione libere
                  Exit;
            end;
        end;
      end;

  end
  else if GameScreen = ScreenSubs then begin

    if Button = MbRight then begin
      SE_DragGuid := nil;
      HighLightFieldFriendly_hide;
      GameScreen := ScreenSubs ;
      Exit;
    end;
    SE_interface.RemoveAllSprites;
    // voglio fare una sostituzione

    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites

          aPlayer := MyBrain.GetSoccerPlayer2 (lstSprite[i].guid); // trova tutti  comunque
          if MyBrain.Score.TeamSubs [ aPlayer.team ] >= 3 then begin
            CancelDrag ( aPlayer, aPlayer.CellX, aPlayer.CellY  );
            Exit;
          end;

          if aPlayer.GuidTeam  <> MyGuidTeam then Exit;   // sposto solo i miei   e solo quelli della panchina

          if (aPlayer.GuidTeam = MyGuidTeam) and (aPlayer.disqualified = 0) and not (aPlayer.Gameover )
              and (MyBrain.isReserveSlot ( aPlayer.CellX, aPlayer.CellY)) then begin
              SE_dragGuid := lstSprite[i];
              HighLightFieldFriendly ( aPlayer , 's' ); // team e talent goalkeeper a distanza < 4 , illumina celle di formazione occupate da compagni
              Exit;
    //          ReserveSlot[aPlayer.CellX,aPlayer.celly]:='';
          end;
       //   Exit;
      end;
    end;
  end

  else if GameScreen = ScreenLiveMatch then begin

    if Button = MbRight then begin

      SE_DragGuid := nil;
      HighLightFieldFriendly_hide;
      if PanelCorner.Visible then Exit;


      MouseWaitFor := WaitForNone;
  //    hideinterface('sks');
      hidechances;
      PanelSkill.Visible := False;
      //AnimationScript.Reset ;
      //SpriteResetSE(true);
       Exit;
    end;

    if GCD > 0 then Exit;




      for I := 0 to lstSprite.Count -1 do begin


        if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites

          case MouseWaitFor of

            WaitForXY_ShortPass: exit ;
            WaitForXY_LoftedPass: exit;
            WaitForXY_Crossing: exit;
            WaitForXY_Move: exit;
            WaitForXY_Dribbling: exit;
            WaitFor_Corner: exit;
            WaitForXY_FKF1: exit;
            WaitForXY_FKF2: exit;
            WaitForXY_FKA2: exit;
            WaitForXY_FKD2: exit;
            WaitForXY_FKF3: exit;
            WaitForXY_FKD3: exit;
            WaitForXY_FKF4: exit;
            WaitForXY_CornerCOF: exit;
            WaitForXY_CornerCOA: exit;
            WaitForXY_CornerCOD: exit;

{            WaitForNone: ;
            WaitForAuth: ;
            WaitForXY_PowerShot: ;
            WaitForXY_PrecisionShot: ; }
          end;
            // lo faccio qui perchè se gli engine cambiano priorità rimane corretto
            if DontDoPlayers then Exit;
            fSelectedPlayer := MyBrain.GetSoccerPlayer2 (lstSprite[i].guid); // trova tutti  comunque
            if SelectedPlayer.GuidTeam = MyGuidTeam then begin

              if not IsOutside ( SelectedPlayer.CellX, SelectedPlayer.CellY) then begin
                SelectedPlayerPopupSkill( SelectedPlayer.CellX, SelectedPlayer.CellY );
                Exit;
              end;
            end;
        end;

        // qui sopra SelectedPlayerPopupSkill compare solo se può comparire. se cìè un waitfor non agisce
        // se arriva qui ed è attivo un waitfor 'aspetto' che sia se_field per avere le coordinate. il player lo trovo via celle
      // un player si muove CON o SENZA palla

        if lstSprite[i].Engine = se_Field then begin
           aPoint:= FieldGuid2Cell (lstSprite[i].guid);
           CellX := aPoint.X;
           CellY := aPoint.Y;

          if MouseWaitFor = WaitForXY_Move  then begin
            if  SelectedPlayer = nil then Exit;
            if  not SelectedPlayer.CanSkill  then Exit;
            if  not SelectedPlayer.CanMove then Exit;

            // trick, se non è visibile il subsprite highlight non posso muovermi li'
            aSeField := SE_field.FindSprite( IntToStr(CellX)+'.' + IntToStr(CellY) )  ;
            if not aSeField.SubSprites[0].lVisible  then
              Exit;

            if  SelectedPlayer.HasBall then begin
              MoveValue := SelectedPlayer.Speed -1;
              if MoveValue <=0 then MoveValue:=1;

              FriendlyWall := true;
              OpponentWall := true;
              FinalWall := true;
              MyParam := withball;
            end
            else begin
              MoveValue := SelectedPlayer.Speed ;
              FriendlyWall := false;
              OpponentWall := false;
              FinalWall := true;
              MyParam := withoutball;
            end;
            if (SelectedPlayer.CellX = CellX) and (SelectedPlayer.CellY = CellY) then exit;
                MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.Celly, CellX, CellY,
                                      MoveValue{Limit},false{useFlank},FriendlyWall{FriendlyWall},
                                      OpponentWall{OpponentWall},FinalWall{FinalWall},TruncOneDir{OneDir}, SelectedPlayer.MovePath );

            if (SelectedPlayer.MovePath.Count > 0) then begin

              MouseWaitFor := WaitForNone;
              DontDoPlayers := true;
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then
                tcp.SendStr( 'PLM' + ',' + SelectedPlayer.Ids   + ',' +
                IntToStr(SelectedPlayer.MovePath[ SelectedPlayer.MovePath.Count -1].X ) +  ',' +
                IntToStr(SelectedPlayer.MovePath[ SelectedPlayer.MovePath.Count -1].Y ) + EndofLine );   // mando l'ultima cella del path
              GCD := GCD_DEFAULT;
              hidechances;
            end;
          end
          else if (SelectedPlayer = Mybrain.Ball.Player) and (MouseWaitFor = WaitForXY_Shortpass) then begin

            if absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) > (ShortPassRange +
                Abs(Integer(   (SelectedPlayer.TalentId1 = TALENT_ID_LONGPASS) or (SelectedPlayer.TalentId2 = TALENT_ID_LONGPASS)  ))) then exit;


            aFriend := MyBrain.GetSoccerPlayer ( CellX, CellY );
            if aFriend <> nil then begin
              if aFriend.Team <> SelectedPlayer.Team  then begin
              // hack
              exit;
              end;
            end;

            aPath:= dse_pathPlanner.Tpath.Create ;
            GetLinePoints ( Mybrain.Ball.CellX ,Mybrain.Ball.CellY,  CellX, CellY , aPath );
            aPath.Steps.Delete(0); // elimino la cella di partenza

            if aPath.Count > 0 then begin
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'SHP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + EndofLine );
              GCD := GCD_DEFAULT;
              hidechances;
            end;

            MouseWaitFor := WaitForNone;
            DontDoPlayers := true;
            aPath.Free;
          end
          else if (SelectedPlayer = Mybrain.Ball.Player) and (MouseWaitFor = WaitForXY_Loftedpass)  then begin
            // controllo lato client. il server lo ripete
            if ( SelectedPlayer.Role <> 'G' ) and
            ( (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) >( LoftedPassRangeMax +
                Abs(Integer(   (SelectedPlayer.TalentId1 = TALENT_ID_LONGPASS) or  (SelectedPlayer.TalentId2 = TALENT_ID_LONGPASS)  ))))
             or (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  )   < LoftedPassRangeMin ) )
             then exit
             else begin // è un portiere
            if (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) > ( 5))   // oltre sua metacampo
             or (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  )   <  LoftedPassRangeMin )
             then exit;
             end;

            if IsGKCell(Cellx,Celly) then Exit;

            aPlayer := MyBrain.GetSoccerPlayer(CellX,CellY);
            if aPlayer <> nil then begin
              if (aPlayer.Team <> SelectedPlayer.Team) or ( aPlayer = SelectedPlayer) then exit;
            end;
            if SelectedPlayer.Role <> 'G' then begin
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'LOP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + ',N' + EndofLine);
              GCD := GCD_DEFAULT;
              hidechances;
            end
            else begin
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'LOP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + ',GKLOP'+ EndofLine );
              GCD := GCD_DEFAULT;
              hidechances;
            end;

            MouseWaitFor := WaitForNone;
            DontDoPlayers := true;

          end
          else if (SelectedPlayer = Mybrain.Ball.Player) and (MouseWaitFor = WaitForXY_Crossing)  then begin
            // controllo lato client. il server lo ripete
            if (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) > (CrossingRangeMax +
                Abs(Integer(   (SelectedPlayer.TalentId1 = TALENT_ID_LONGPASS) or (SelectedPlayer.TalentId2 = TALENT_ID_LONGPASS)   ))))
             or (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  )   < CrossingRangeMin )
             then exit;

            if not MyBrain.GetFriendInCrossingArea( SelectedPlayer ) then exit;
            aHeadingFriend := MyBrain.GetSoccerPlayer(CellX,CellY);
            if aHeadingFriend = nil then exit;
            if aHeadingFriend.Team  <> SelectedPlayer.Team then exit;
            if not (aHeadingFriend.InCrossingArea) then exit;
            if (aHeadingFriend.Team <> SelectedPlayer.Team) or ( aHeadingFriend.ids = SelectedPlayer.ids) then exit;

            if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'CRO' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + EndofLine );
            GCD := GCD_DEFAULT;
            hidechances;

            MouseWaitFor := WaitForNone;
            DontDoPlayers := true;

          end
          else if (SelectedPlayer = Mybrain.Ball.Player) and (MouseWaitFor =WaitForXY_Dribbling)  then begin
            // controllo lato client. il server lo ripete

            if (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) = 1) and (SelectedPlayer.CanDribbling ) then begin

              aPlayer := MyBrain.GetSoccerPlayer(CellX,CellY);
              if aPlayer = nil then exit;
                if (aPlayer.Team = SelectedPlayer.Team) or ( aPlayer = SelectedPlayer) then exit;
              if (not viewMatch) and  (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr(  'DRI' + ','  + IntToStr(CellX) +  ',' + IntToStr(CellY ) + EndofLine );
              GCD := GCD_DEFAULT;
              hidechances;

              MouseWaitFor := WaitForNone;
              DontDoPlayers := true;
            end;
          end;
        end;

    end;
  end;

end;
procedure TForm1.AddFace ( aPlayer: TSoccerPlayer );
var
  aSubSprite: SE_SubSprite;
  i: integer;
begin
  WaitForSingleObject ( MutexAnimation, INFINITE ); // il mousemove che genera questa procedura può avvenire durante il clear della lstsoccerplayer
  for I := se_Players.SpriteCount -1 downto 0 do begin  // rimuovo tutti i face e solo i face ( stay e cartellini rimangono)
    aSubSprite:= aPlayer.se_sprite.FindSubSprite('face');
    if aSubSprite <> nil then
       aPlayer.se_sprite.SubSprites.Remove(aSubSprite);
  end;
  // aggiungo la faccia come subsprite
  aSubSprite := SE_SubSprite.create( dir_player + IntTostr(aPlayer.face) +'.bmp' , 'face', 0  ,0, true, true );
  aSubSprite.lBmp.Stretch (trunc (( aSubSprite.lBmp.Width * ScaleSpritesFace ) / 100), trunc (( aSubSprite.lBmp.Height * ScaleSpritesFace ) / 100)  );
  // qui non viene calcolato lo scale dello sprite.
  aPlayer.se_sprite.DrawFrame; // forza lo scale
  aSubSprite.lX := (aPlayer.se_sprite.BMPCurrentFrame.Width div 2) - (aSubSprite.lBmp.Width div 2);  // center
  aSubSprite.ly := 0;  // center
  aPlayer.se_sprite.AddSubSprite(aSubSprite);
  //aSubSprite.Free;
  ReleaseMutex(MutexAnimation);
  //aSprite.ChangeBitmap( IntTostr(aPlayer.face) +'.bmp',1,1,1000 );

end;

procedure TForm1.ShowFace ( aPlayer: TSoccerPlayer );
var
  aSubSprite: SE_SubSprite;
  i: integer;
begin
  WaitForSingleObject ( MutexAnimation, INFINITE ); // il mousemove che genera questa procedura può avvenire durante il clear della lstsoccerplayer
  for I := se_Players.SpriteCount -1 downto 0 do begin  // rimuovo tutti i face e solo i face ( stay e cartellini rimangono)
    aSubSprite:= Se_Players.Sprites[i].FindSubSprite('face');
    if aSubSprite <> nil then
      Se_Players.Sprites[i].SubSprites.Remove(aSubSprite);
  end;
  // aggiungo la faccia come subsprite
  aSubSprite := SE_SubSprite.create( dir_player + IntTostr(aPlayer.face) +'.bmp' , 'face', 0  ,0, true, true );
  aSubSprite.lBmp.Stretch (trunc (( aSubSprite.lBmp.Width * ScaleSpritesFace ) / 100), trunc (( aSubSprite.lBmp.Height * ScaleSpritesFace ) / 100)  );
  aSubSprite.lX := (aPlayer.se_sprite.BMPCurrentFrame.Width div 2) - (aSubSprite.lBmp.Width div 2);  // center
  aSubSprite.ly := 0;  // center
  aPlayer.se_sprite.AddSubSprite(aSubSprite);
  ReleaseMutex(MutexAnimation);

  //aSprite.ChangeBitmap( IntTostr(aPlayer.face) +'.bmp',1,1,1000 );

end;

procedure TForm1.SE_Theater1SpriteMouseMove(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Shift: TShiftState; Var Handled: boolean);
var
  aPlayer,aFriend,anOpponent: TSoccerPlayer;
  I,MoveValue, CellX, CellY : Integer;
  aPoint: TPoint;
  anInteractivePlayer: TInteractivePlayer;
  ToEmptyCell, FriendlyWall, OpponentWall,FinalWall: Boolean;
begin
  // una volta processati gli sprite settare  Handled:= TRUE o la SE:Theater non manderà più la lista degli sprite.

  if (not Se_Theater1.Active) then Exit;
  if SE_DragGuid <> nil then begin
    Handled := True;
    Exit;
  end;
  panelsell.Visible := false;

  for I := lstSprite.Count -1 downto 0 do begin   // lstSprite è protetta fino a quando handled è false

    if lstSprite[i].Engine = se_players then begin

      if GameScreen = ScreenFormation  then begin
        aPlayer:= MyBrainFormation.GetSoccerPlayer2( lstSprite[i].guid );

        if LastSpriteMouseMoveGuid = lstSprite[i].guid then continue;
        LastSpriteMouseMoveGuid := lstSprite[i].guid;
        lastMouseMovePlayer := MyBrain.GetSoccerPlayer2 ( lstSprite[i].guid );

        btnxp0.Visible := True;
        btnsell0.Visible := True;
        btnDismiss0.Visible := True;
        PanelDismiss.Visible := False;
        if aPlayer.OnMarket then begin
          btnsell0.Caption := Translate ('lbl_CancelSell');
          btnsell0.Tag := 1;
        end
        else begin
          btnsell0.Caption := Translate ('lbl_Sell');
          btnsell0.Tag := 0;                              // il tag per azione button
        end;

       // aPlayer:= MyBrainFormation.GetSoccerPlayer2( lstSprite[i].guid );
       // if aPLayer <> nil then begin
          SE_GridXP0.SceneName:= aPlayer.Ids;
          SetupGridXP ( SE_GridXP0, aPlayer  );
       // end;

      end
      else begin  // no ScreenFormation
        btnDismiss0.Visible := false;
        btnXP0.Visible := false;
        btnSell0.Visible := false;
        aPlayer:= MyBrain.GetSoccerPlayer2( lstSprite[i].guid );
      //  if LastSpriteMouseMoveGuid = lstSprite[i].guid then continue;  // verificare se è tutto ok ora
      //  LastSpriteMouseMoveGuid := lstSprite[i].guid;

      end;

      // sia in caso di screenformation o in caso di partita live


        //ShowFace ( aPlayer );
        portrait0.Glyph.LoadFromFile(dir_player + IntTostr(aPlayer.face) + '.bmp');

        if not (ssShift in Shift) then begin

          SE_Grid0.SceneName:= aPlayer.Ids;;
          SetupGridAttributes (SE_Grid0, aPlayer, 'a'  );  // attributi
        end
        else begin //  ssShift in Shift
          // come sopra ma mostro la history

          SetupGridAttributes (SE_Grid0, aPlayer, 'h'  ); // history

        end;

        if CheckBox1.Checked then
          lbl_Surname0.Caption := aPlayer.Ids + ' ' + aPlayer.SurName + ' (' + aPlayer.Role +')'
            else lbl_Surname0.Caption := aPlayer.SurName + ' (' + aPlayer.Role +')' ;



         if aPlayer.TalentID1 <> 0 then begin
           lbl_talent01.Caption :=  Capitalize  ( Translate( 'talent_' + capitalize (  StringTalents[aPlayer.TalentId1]) ));
           lbl_descrTalent01.Caption := Translate('descr_talent_' + StringTalents[aPlayer.TalentId1]);
           btnTalentBmp01.Glyph.LoadFromFile( dir_talent + IntToStr(aPlayer.TalentId1) + '.bmp' );
           btnTalentBmp01.Visible := True;

           if aPlayer.TalentID2 <> 0 then begin
             lbl_talent02.Caption :=  Capitalize  ( Translate( 'talent_' + capitalize (  StringTalents[aPlayer.TalentId2]) ));
             lbl_descrTalent02.Caption := Translate('descr_talent_' + StringTalents[aPlayer.TalentId2]);
             btnTalentBmp02.Glyph.LoadFromFile( dir_talent + IntToStr(aPlayer.TalentId2) + '.bmp' );
             btnTalentBmp02.Visible := True;
           end
           else begin
             lbl_talent02.Caption:='';
             lbl_descrTalent02.Caption:='';
             btnTalentBmp02.Visible := False;

           end;
         end
         else begin
           lbl_talent01.Caption:='';
           lbl_descrTalent01.Caption:='';
           btnTalentBmp01.Visible := False;
           lbl_talent02.Caption:='';
           lbl_descrTalent02.Caption:='';
           btnTalentBmp02.Visible := False;
         end;

        // la width è dinamica, devo settare qui le posizioni
        lbl_Talent01.Left := PanelinfoPlayer0.Width div 2 - lbl_Talent01.Width div 2 ;
        lbl_Talent01.Top := SE_grid0.Top + SE_grid0.Height + 6 ;
        lbl_descrtalent01.Left := SE_grid0.Left ;
        lbl_descrtalent01.Top := Form1.lbl_Talent01.Top + lbl_Talent01.Height + 8;
        lbl_descrtalent01.Width := SE_grid0.Width ;
        lbl_descrtalent01.Height := 74;

        lbl_Talent02.Left := PanelinfoPlayer0.Width div 2 - lbl_Talent02.Width div 2 ;
        lbl_Talent02.Top := lbl_Talent01.Top + 110;
        lbl_descrtalent02.Left := SE_grid0.Left ;
        lbl_descrtalent02.Top := lbl_Talent02.Top + lbl_Talent02.Height + 8;
        lbl_descrtalent02.Width := SE_grid0.Width ;
        lbl_descrtalent02.Height := 74;

        Form1.btnTalentBmp01.Left :=  (Form1.Portrait0.Width div 2) - Form1.Portrait0.Left - 16;
        Form1.btnTalentBmp01.top := 200;
        Form1.btnTalentBmp02.Left :=  (Form1.Portrait0.Width div 2) - Form1.Portrait0.Left - 16;
        Form1.btnTalentBmp02.top := 200 + 110;

     // end;
    end


      // qui sopra la parte infoplayer. da qui in poi le arrowdirection
      // non usare EXIt ma continue

    else if lstSprite[i].Engine = SE_field then  begin
      aPoint:= FieldGuid2Cell (lstSprite[i].guid);

     // if (aPoint.X = oldCellXMouseMove)  or (aPoint.Y = oldCellYMouseMove) then continue;

      CellX := aPoint.X;
      CellY := aPoint.Y;

      if GameScreen = ScreenLiveMatch then begin


        if MouseWaitFor = WaitForXY_Shortpass then begin       // shp su friend o cella vuota
          ClearInterface;
          ToEmptyCell := true;
          if (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  ) > (ShortPassRange +
              Abs(Integer(   (MyBrain.Ball.Player.TalentId1 = TALENT_ID_LONGPASS) or (MyBrain.Ball.Player.TalentId2 = TALENT_ID_LONGPASS)    ))))
          or (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  ) = 0)
          then continue;
          aFriend := MyBrain.GetSoccerPlayer(CellX,CellY);
          if aFriend <> nil then begin
            if (aFriend.Ids = MyBrain.Ball.Player.ids) or (aFriend.Team <> MyBrain.Ball.Player.Team ) then continue;
            ToEmptyCell := false;
          end;
          CreateBaseAttribute (  CellX, CellY, SelectedPlayer.Passing );
          ArrowShowShpIntercept ( CellX, CellY, ToEmptyCell) ;
          HighLightField( CellX, CellY, 0);
        end
        else if MouseWaitFor = WaitForXY_Move then begin       // di 2 o più mostro intercept autocontrasto

          ClearInterface;
          if  SelectedPlayer.HasBall then begin
            MoveValue := SelectedPlayer.Speed -1;
            if MoveValue <=0 then MoveValue:=1;

            FriendlyWall := true;
            OpponentWall := true;
            FinalWall := true;
          end
          else begin
            MoveValue := SelectedPlayer.Speed ;
            FriendlyWall := false;
            OpponentWall := false;
            FinalWall := true;
          end;

          MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.Celly, CellX, CellY,
                                MoveValue{Limit},false{useFlank},FriendlyWall{FriendlyWall},
                                OpponentWall{OpponentWall},FinalWall{FinalWall},AbortMultipleDirection{OneDir}, SelectedPlayer.MovePath );
          if SelectedPlayer.MovePath.Count > 0 then begin
            // ultimo del path, non cellx celly
            HighLightField (SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y, 0 );
            if  SelectedPlayer.HasBall then begin
              //CreateBaseAttribute (  CellX, CellY, SelectedPlayer.BallControl );
              ArrowShowMoveAutoTackle  ( SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y) ;
              HighLightField (SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y, 0 );
            end;
          end;
        end
        else if MouseWaitFor = WaitForXY_LoftedPass then begin  // mostro i colpi di testa difensivi o chi arriva sulla palla
          ClearInterface;
          ToEmptyCell := true;
          if ( MyBrain.Ball.Player.Role <> 'G' ) and
          ( (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  ) >( LoftedPassRangeMax +
                 Abs(Integer((MyBrain.Ball.Player.TalentId1 = TALENT_ID_LONGPASS) or (MyBrain.Ball.Player.TalentId2 = TALENT_ID_LONGPASS)))))
           or (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  )   < LoftedPassRangeMin ) )
           then begin
             continue;
           end
           else begin // è un portiere
            if (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  ) > ( 5))   // oltre sua metacampo
             or (absDistance (MyBrain.Ball.Player.CellX , MyBrain.Ball.Player.CellY, Cellx, Celly  )   < LoftedPassRangeMin )
             then begin
               continue;
             end;
          end;
          aFriend := MyBrain.GetSoccerPlayer(CellX,CellY);
          if aFriend <> nil then begin
            if (aFriend.Ids = MyBrain.Ball.Player.ids) or (aFriend.Team <> MyBrain.Ball.Player.Team ) then continue;
            ToEmptyCell := false;
          end;

          CreateBaseAttribute (  CellX, CellY, SelectedPlayer.Passing );
          ArrowShowLopHeading( CellX, CellY, ToEmptyCell) ;
          HighLightField( CellX, CellY, 0);
          if aFriend <> nil then begin
            CreateBaseAttribute (  CellX, CellY, aFriend.BallControl );
            if aFriend.InCrossingArea then
              CreateBaseAttribute (  CellX, CellY, aFriend.Shot );
          end;
        end
        else if MouseWaitFor = WaitForXY_Crossing then begin   // mostro i colpi di testa difensivi o chi arriva sulla palla
          ClearInterface;
          if (absDistance ( MyBrain.ball.Player.CellX ,  MyBrain.ball.Player.CellY, CellX, CellY  ) > (CrossingRangeMax +
              Abs(Integer( (MyBrain.Ball.Player.TalentId1 = TALENT_ID_LONGPASS) or (MyBrain.Ball.Player.TalentId2 = TALENT_ID_LONGPASS) ))))
            or (absDistance ( MyBrain.ball.Player.CellX ,  MyBrain.ball.Player.CellY, CellX, CellY  ) < CrossingRangeMin)  then begin
             continue;
          end;
          aFriend := MyBrain.GetSoccerPlayer(CellX,CellY);
          if aFriend <> nil then begin
            if (aFriend.Ids = MyBrain.Ball.Player.ids) or (aFriend.Team <> MyBrain.Ball.Player.Team ) then continue;
            if aFriend.InCrossingArea then begin
              CreateBaseAttribute (  CellX, CellY, SelectedPlayer.Passing );
              ArrowShowCrossingHeading( CellX, CellY) ;
              CreateBaseAttribute (  CellX, CellY, aFriend.heading );
              HighLightField( CellX, CellY, 0);
            end;
          end
          else continue;

        end
        else if MouseWaitFor = WaitForXY_Dribbling then begin  // mostro freccia su opponent da dribblare
          ClearInterface;
          anOpponent := MyBrain.GetSoccerPlayer(CellX,CellY);
          if anOpponent = nil then continue;
            if (anOpponent.Team = SelectedPlayer.Team)  or (anOpponent.Ids = SelectedPlayer.ids) or
            (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, CellX, CellY  ) > 1) then begin
             continue;
            end;

          ArrowShowDribbling( anOpponent, CellX, CellY);
          HighLightField( CellX, CellY, 0);

  //          CalculateChance  (SelectedPlayer.BallControl + SelectedPlayer.tal_Dribbling -2, anOpponent.Defense , chanceA,chanceB,chanceColorA,chanceColorB);
        end
        else if MouseWaitFor = WaitForXY_PowerShot then begin // mostro opponent, intercept, e portiere
          ClearInterface;
//          SE_interface.removeallSprites;
        end
        else if MouseWaitFor = WaitForXY_PrecisionShot then begin // mostro opponent, intercept, e portiere
          ClearInterface;
//          SE_interface.removeallSprites;
        end
        else if MouseWaitFor = WaitFor_Corner then begin   // mostro opponent, e frecce contrarie
          ClearInterface;
//          SE_interface.removeallSprites;
        end;
      end;
    end;
  end;

  handled := True;
end;
procedure TForm1.SE_GridDiceWriteRow  ( team: integer; attr, Surname, ids, num1, flags: string);
var
  Row: Integer;
  I,c,r: Integer;
  aSize: TSize;
  sebmp: SE_Bitmap;
  flag: TStringList;
  ColNum, ColSurname, ColIds , ColText : Integer;
begin
  Row := SE_GridDice.RowCount -1;
//  Flag[1] = ACT

  SE_GridDice.Cells [4, Row ].BackColor := SE_GridDice.BackColor ;
  SE_GridDice.cells [4, Row ].FontColor := clYellow;
//  if num1 <> 'FAULT' then SE_GridDice.Cells[ 4, Row].Text := vs;
  if team = 0 then begin
    ColIds      :=0;
    ColSurname  :=1;
    ColText     :=2;
    ColNum      :=3;
  end
  else begin
    ColIds      :=7;
    ColSurname  :=6;
    ColText     :=5;
    ColNum      :=4;
  end;


  flag:= Tstringlist.create;
  flag.Delimiter := '.';
  flag.DelimitedText := flags;
    if (flag[0] = 'F') or (flag[0]='N') or (flag[0]='S') then begin        // è un Roll o una skill senza roll
      SE_GridDice.Cells [ColSurname, Row ].BackColor := MyBrain.Score.DominantColor[team];
      SE_GridDice.Cells [ColText, Row ].BackColor := MyBrain.Score.DominantColor[team];
      SE_GridDice.Cells [ColNum, Row ].BackColor := MyBrain.Score.DominantColor[team];
      SE_GridDice.Cells [ColSurname, Row ].FontColor := GetContrastColor( MyBrain.Score.DominantColor[team]);
      SE_GridDice.Cells [ColText, Row ].FontColor := GetContrastColor( MyBrain.Score.DominantColor[team]);
      SE_GridDice.Cells [ColNum, Row ].FontColor := GetContrastColor( MyBrain.Score.DominantColor[team]);

   // SE_GridDice.Cells[ 3, Row].Text := num1;

      if flag[0] <> 'S' then begin  // pressing, protection, sub,stay,free,buffd,buffm,bufff,pass

        sebmp:= Se_bitmap.Create (32,32);
        sebmp.Bitmap.Canvas.Brush.color := clPurple;
        sebmp.Bitmap.Canvas.FillRect(  Rect(0,0,32,32));
        sebmp.Bitmap.Canvas.Brush.color := clGray;
        sebmp.Bitmap.Canvas.Ellipse(6,6,26,26);
        sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
        sebmp.Bitmap.Canvas.Font.Size := 10;
        sebmp.Bitmap.Canvas.Font.Style := [fsbold];
        sebmp.Bitmap.Canvas.Font.Color := clYellow;
        if flag[1] <> '0' then                        // si attiva il talento
          sebmp.Bitmap.Canvas.Font.Color := clGreen;
        if flag[0]= 'F' then
          sebmp.Bitmap.Canvas.Font.Color := clMaroon;

        if length( num1 ) = 1 then
          sebmp.Bitmap.Canvas.TextOut( 12,8, num1)
          else sebmp.Bitmap.Canvas.TextOut( 7,8, num1);

        SE_GridDice.AddSE_Bitmap(ColNum,Row,1,sebmp,true);
        sebmp.Free;
      end;
    end
    else  begin // 'I.  freekick, YC, RC
      SE_GridDice.Cells [ColSurname, Row ].BackColor := clGray;
      SE_GridDice.Cells [ColText, Row ].BackColor := clGray;
      SE_GridDice.Cells [ColNum, Row ].BackColor := clGray;
      SE_GridDice.Cells [ColSurname, Row ].FontColor := clyellow;
      SE_GridDice.Cells [ColText, Row ].FontColor := clyellow;
      SE_GridDice.Cells [ColNum, Row ].FontColor := clyellow;

     // SE_GridDice.Cells[ ColNum, Row].Text := flag[1];
    end;



    SE_GridDice.Cells[ ColText, Row].Text := UpperCase(attr);
    SE_GridDice.Cells[ ColSurname, Row].Text := Surname;
    SE_GridDice.Cells[ ColIds, Row].Text := ids;   // utile per link futuro

    SE_GridDice.AddRow;

  for c := 0 to SE_GridDice.ColCount -1 do begin
    for r := 0 to SE_GridDice.RowCount -1 do begin
      SE_GridDice.Rows[r].Height := 18;
      SE_GridDice.Cells [c,r].Fontsize := 7;
      SE_GridDice.Cells [c,r].Fontname := 'Verdana';
      SE_GridDice.cells [6,r].CellAlignmentH := hRight;
      SE_GridDice.cells [5,r].CellAlignmentH := hLeft;
      SE_GridDice.cells [1,r].CellAlignmentH := hLeft;
      SE_GridDice.cells [2,r].CellAlignmentH := hLeft;
    end;
  end;

  PanelCombatLog.Width := SE_GridDice.Width +3 + 3;
  RoundCornerOf( PanelCombatLog);
  SE_GridDice.CellsEngine.ProcessSprites(2000);
  SE_GridDice.refreshSurface ( SE_GridDice );
  flag.Free;
end;
procedure TForm1.ClearInterface;
begin
  SE_interface.removeallSprites; // rimuovo le frecce
  SE_interface.ProcessSprites(2000);
  HighLightFieldFriendly_hide;  // rimuovo gli highlight
end;
procedure TForm1.ArrowShowMoveAutoTackle ( CellX, CellY : Integer);
var
  i,au,MoveValue: Integer;
  aCellList: TList<TPoint>;
  label Myexit;
begin
   SE_interface.removeallSprites;
//  hidechances;
  MoveValue := SelectedPlayer.Speed -1;
  if MoveValue <=0 then MoveValue:=1;
  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY, MoveValue,True,true , True,aCellList); // noplayer,noOutside
  // se mi muovo col mouse s una possibile cella - qui solo hasball=true -
  for I := 0 to aCellList.Count -1 do begin
    if (aCellList[i].X= CellX) and (aCellList[i].Y= CellY) then begin
      MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.CellY, CellX, CellY,
                              MoveValue{Limit},false{useFlank},true{FriendlyWall},
                              true{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, SelectedPlayer.MovePath );

      // PLM Precompilo la lista di possibili autotackle perchè non si ripetano
      if SelectedPlayer.MovePath.count > 0 then begin// solo se si muove di 2 o più ? > 1  per il momento la regola è: non cella finale
        MyBrain.CompileAutoTackleList (SelectedPlayer.Team{avversari di}, 1{MaxDistance},  SelectedPlayer.MovePath, lstInteractivePlayers  );
      end;

      for au := 0 to lstInteractivePlayers.Count -1 do begin
        lstInteractivePlayers[au].Attribute := atDefense;
        CreateArrowDirection( lstInteractivePlayers[au].Player  , lstInteractivePlayers[au].Cell.X ,lstInteractivePlayers[au].Cell.Y );
        CreateBaseAttribute (  lstInteractivePlayers[au].Player.CellX, lstInteractivePlayers[au].Player.CellY, lstInteractivePlayers[au].Player.Defense );
      end;

      break; //goto MyExit;
    end;

  end;
Myexit:
  aCellList.Free;


end;
procedure TForm1.ArrowShowShpIntercept ( CellX, CellY : Integer; ToEmptyCell: boolean);
var
  aPath: dse_pathPlanner.Tpath;
  i,y: integer;
  anIntercept, anOpponent,aFriend: TSoccerPlayer;
  aInteractivePlayer: TInteractivePlayer;
  LstMoving: TList<TInteractivePlayer>;

begin
  // calcola il percorso della palla in linea retta e ottiene un path di celle interessate
  aPath:= dse_pathPlanner.Tpath.Create;
  SoccerBrainv3.GetLinePoints ( MyBrain.Ball.CellX ,MyBrain.Ball.CellY,  CellX, CellY, aPath );
  aPath.Steps.Delete(0); // elimino la cella di partenza

    // SHP Precompilo la lista di possibili intercept perchè non si ripetano
  MyBrain.CompileInterceptList (  MyBrain.Ball.Player.Team{avversari di}, 1{MaxDistance}, aPath, lstInteractivePlayers  );

  for I := 0 to aPath.Count -1 do begin
       // cella per cella o trovo un opponente o trovo un intercept

      anOpponent:= MyBrain.GetSoccerPlayer ( aPath[i].X,aPath[i].Y);
      if anOpponent <> nil then begin
          if anOpponent.Team <> MyBrain.Ball.Player.Team then begin
            aInteractivePlayer:= TInteractivePlayer.Create;
            aInteractivePlayer.Player  :=  anOpponent;                    // aggiungo per il mousemove anche il difensore davanti alla palla
            aInteractivePlayer.Cell := Point ( aPath[i].X ,aPath[i].Y );
            aInteractivePlayer.Attribute := atDefense;
            lstInteractivePlayers.add (aInteractivePlayer);
            CreateArrowDirection( anOpponent, aPath[i].X,aPath[i].Y );
            CreateBaseAttribute (  aPath[i].X,aPath[i].Y, anOpponent.Defense );
          end;
      end

      else begin // no opponent ma possibile intercept su cella vuota

        for Y := 0 to lstInteractivePlayers.count -1 do begin
          anIntercept := lstInteractivePlayers[Y].Player;
          if ( lstInteractivePlayers[Y].Cell.X = aPath[i].X) and (lstInteractivePlayers[Y].Cell.Y = aPath[i].Y) then begin  // se questa cella
            lstInteractivePlayers[Y].Attribute := atDefense;  { TODO -cgameplay : intercept potrebbe usare atBallControl? }
            CreateArrowDirection( anIntercept, aPath[i].X,aPath[i].Y );
            aFriend := MyBrain.GetSoccerPlayer ( CellX , CellY);
            if aFriend = nil then
   { toemptycells lo devo riportare adesso }
            CreateBaseAttribute (  anIntercept.CellX, anIntercept.Celly, anIntercept.Defense )
            else  CreateBaseAttribute (  anIntercept.CellX, anIntercept.Celly, anIntercept.Defense );

          end
        end;

      end
  end;

  // compilo la lista di compagni che possono raggiungere quella cella e mostro la loro speed. solo su cella vuota finale
  // solo nel caso non vi siano intercept
  if (ToEmptyCell)  and (lstInteractivePlayers.Count = 0) then begin
    LstMoving:= TList<TInteractivePlayer>.create;
    MyBrain.CompileMovingList (1{MaxDistance}, CellX, CellY, LstMoving  );
    for Y := 0 to LstMoving.count -1 do begin
      LstMoving[Y].Attribute := atSpeed;
      CreateArrowDirection( LstMoving[Y].Player, CellX,CellY );
      CreateBaseAttribute (  CellX,CellY,  LstMoving[Y].Player.Speed );
    end;

    LstMoving.Free;
  end;


  aPath.Free;
end;
procedure TForm1.ArrowShowLopheading(CellX, CellY : Integer; ToEmptyCell:
    boolean);
var
  y: integer;
  aheading: TSoccerPlayer;
  ToEmptyCellMalus: integer;
  LstMoving: TList<TInteractivePlayer>;

begin

  if not ToEmptyCell then begin
    // LOP su friend

    // LOP Precompilo la lista di possibili Heading perchè non si ripetano
    MyBrain.CompileHeadingList (SelectedPlayer.Team{avversari di}, 1{MaxDistance}, CellX, CellY, lstInteractivePlayers  );
    for Y := 0 to lstInteractivePlayers.count -1 do begin
         // cella per cella o trovo un opponent o trovo un intercept
      aHeading := lstInteractivePlayers[Y].Player;
      if ( lstInteractivePlayers[Y].Cell.X = CellX) and (lstInteractivePlayers[Y].Cell.Y = CellY) then begin  // se questa cella
            // CalculateChance  ( SelectedPlayer.Passing , aHeading.Heading  , chanceA,chanceB,chanceColorA,chanceColorB);
            lstInteractivePlayers[Y].Attribute := atHeading;
            CreateArrowDirection( aHeading, CellX,CellY );
            CreateBaseAttribute (  aHeading.CellX, aHeading.CellY, aHeading.Heading );

      end;

    end;

  end

  else begin
    // LOP su cella vuota
  // compilo la lista di compagni che possono raggiungere quella cella e mostro la loro speed. solo su cella vuota finale
    LstMoving:= TList<TInteractivePlayer>.create;
    MyBrain.CompileMovingList (1{MaxDistance}, CellX, CellY, LstMoving  );
    for Y := 0 to LstMoving.count -1 do begin
      LstMoving[Y].Attribute := atSpeed;
      CreateArrowDirection( LstMoving[Y].Player, CellX,CellY );
      CreateBaseAttribute (  LstMoving[Y].Player.CellX, LstMoving[Y].Player.CellY, LstMoving[Y].Player.Speed );
    end;

    LstMoving.Free;
  end;

end;

procedure TForm1.ArrowShowCrossingHeading ( CellX, CellY : Integer);
var
  y,BonusDefenseHeading,BaseHeading: integer;
  aheading: TSoccerPlayer;
  aInteractivePlayer: TInteractivePlayer;
  ToEmptyCellMalus: integer;
  LstMoving: TList<TInteractivePlayer>;

begin

  HighLightField (CellX ,CellY,0);

  BonusDefenseHeading := MyBrain.GetCrossDefenseBonus (SelectedPlayer, CellX, CellY );
  // CRO Precompilo la lista di possibili Heading perchè non si ripetano
  MyBrain.CompileHeadingList (SelectedPlayer.Team{avversari di}, 1{MaxDistance}, CellX, CellY, lstInteractivePlayers  );
  for Y := 0 to lstInteractivePlayers.count -1 do begin
    aHeading := lstInteractivePlayers[Y].Player;
       // cella per cella o trovo un opponent o trovo un intercept
    if ( lstInteractivePlayers[Y].Cell.X = CellX) and (lstInteractivePlayers[Y].Cell.Y = CellY) then begin  // se questa cella
     //     CalculateChance  ( aFriend.heading, aHeading.Heading + BonusDefenseHeading  , chanceA,chanceB,chanceColorA,chanceColorB);
     //     BaseHeading :=  LstHeading[Y].Player.Heading + BonusDefenseHeading;
     //     if Baseheading <= 0 then Baseheading :=1;
      CreateArrowDirection( lstInteractivePlayers[Y].Player, CellX,CellY );
      CreateBaseAttribute (  lstInteractivePlayers[Y].Player.CellX,lstInteractivePlayers[Y].Player.CellY, lstInteractivePlayers[Y].Player.heading );

    end;

  end;

end;
procedure TForm1.ArrowShowDribbling ( anOpponent: TSoccerPlayer; CellX, CellY : Integer);
var
  anInteractivePlayer : TInteractivePlayer;
begin

  anInteractivePlayer := TInteractivePlayer.Create ;
  anInteractivePlayer.Player := anOpponent;
  anInteractivePlayer.Cell.X := cellX;
  anInteractivePlayer.Cell.Y := cellY;
  anInteractivePlayer.Attribute := atDefense;
  CreateArrowDirection(  MyBrain.ball.Player, CellX,CellY );
  CreateBaseAttribute (  SelectedPlayer.CellX,SelectedPlayer.CellY, SelectedPlayer.BallControl +
      Abs(Integer(   (SelectedPlayer.TalentId1 = TALENT_ID_DRIBBLING) or (SelectedPlayer.TalentId2 = TALENT_ID_DRIBBLING)   ))  );
  CreateBaseAttribute (  CellX,CellY, anOpponent.Defense  );

end;
function Tform1.FieldGuid2Cell (guid:string): Tpoint;
var
  x: Integer;
begin
  x:= Pos( '.',guid,1);
  result.X :=  StrToInt( LeftStr(guid, x -1 )  );
  result.Y :=  StrToInt( RightStr(guid, Length(guid) - x   )  );

end;
procedure TForm1.SE_Theater1SpriteMouseUp(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton;  Shift: TShiftState);
var
  aPlayer,aPlayer2: TSoccerPlayer;
  i, CellX, CellY: integer;
  aSeField: SE_Sprite;
  AICell, Acell,aPoint: TPoint;
  label reserve;
  label exitScreenSubs;
begin
  if Se_DragGuid = nil then Exit;

  for I := 0 to lstSprite.Count -1 do begin
    if lstSprite[i].Engine = se_field then begin
      aSEField := SE_field.FindSprite(lstSprite[i].guid );
      Acell := FieldGuid2Cell ( lstSprite[i].guid);
      CellX := Acell.X;
      Celly := acell.Y;
      Break;
    end;
  end;

  if GameScreen = ScreenFormation then begin


    aPlayer := findPlayerMyBrainFormation (Se_DragGuid.Guid);
    if (aPlayer.disqualified > 0) or (aPlayer.Injured > 0) then goto reserve;


        if not IsOutSide ( CellX, CellY) then begin

          if (CellX = 0) or (CellX = 2)  or  (CellX = 5) or (CellX = 8) then begin // uso TvCell

            if (isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER) then goto reserve;    // un goalkeeper può essere schierato solo in porta
            if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 = TALENT_ID_GOALKEEPER) then goto reserve;    // un goalkeeper può essere schierato solo in porta

             //MoveInDefaultField(aPlayer);
             // se c'è un player in quella polyCell lo sposto nelle riserve
            for i := 0 to MyBrainFormation.lstSoccerPlayer.count -1 do begin
              aPlayer2 := MyBrainFormation.lstSoccerPlayer[i];
              AICell:=  MyBrainFormation.Tv2AiField ( 0, CellX, CellY );  // 0 è il mio team, sposto solo i miei
              if (aPlayer2.AIFormationCellX  = AICell.X) and (aPlayer2.AIFormationCellY  = AICell.Y) and ( aPlayer2.ids <> se_DragGuid.guid ) then begin  // un player nel .ini a cellX,celly  lo metto nelle riserver
                MyBrainFormation.PutInReserveSlot( aPlayer2 );
                RefreshCheckFormationMemory;
                MoveInReserves(aPlayer2);
              end;
            end;

             // e dopo storo il nuovo player
             Updateformation ( se_DragGuid.guid, 0, CellX, CellY); // passo delle TvCell che converte in Aicells che sotra nel db tramite MyBrainFormation
            // aPlayer.DefaultCells := Point(CellX ,CellY);// deafultcells la uso in memoria, non ha valore di dato da storare
             SE_DragGuid.MoverData.Destination := aSeField.Position;
             SE_DragGuid.Position := aSeField.Position;


            se_DragGuid := nil;
            HighLightFieldFriendly_hide ;
          end
          else begin
    reserve:
              MyBrainFormation.PutInReserveSlot( aPlayer );
              RefreshCheckFormationMemory;
              MoveInReserves(aPlayer);
              se_DragGuid := nil;
            HighLightFieldFriendly_hide ;

          end;
        end
        else if IsOutSide ( CellX, CellY) then begin // lo metto nelle riserve
              MyBrainFormation.PutInReserveSlot( aPlayer );
              RefreshCheckFormationMemory;
              MoveInReserves(aPlayer);
              se_DragGuid := nil;
            HighLightFieldFriendly_hide ;
        end;

  end
  else if GameScreen = ScreenTactics then begin

    if GCD > 0 then Exit;

    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = se_field then begin   // sposto solo players , non altri sprites

        //cellX e CellY devono essere in campo, mai fuori
        if SE_DragGuid = nil then Exit;
        aPlayer := MyBrain.GetSoccerPlayer2 (SE_DragGuid.Guid); // mouseup su qualsiasi cella
        aPlayer2 := MyBrain.GetSoccerPlayerDefault (CellX, CellY); // mouseup su qualsiasi cella
        if IsOutSide( CellX, CellY) then Begin
          CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
          Exit;
        end;


        // il mouseup è solo in campo, mai click fuori dal campo
        if aPlayer2 <> nil then begin
          CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
         Exit; // deve essere una cella vuota non ocupata da player
        end;

        if (aPlayer.Team  = 0)
        and ( (CellX = 1) or (CellX = 3)  or (CellX = 4) or (CellX = 6) or (CellX = 7) or (CellX = 9) or (CellX = 10) or (CellX = 11) ) then Begin
          CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
          Exit;
        end;

        if (aPlayer.Team  = 1)
        and ( (CellX = 0) or (CellX = 1)  or (CellX = 2) or (CellX = 4) or (CellX = 5) or (CellX = 7) or (CellX = 8) or (CellX = 10) ) then Begin
          CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
          Exit;
        end;

          // se_dragguid deve essere uno già in campo
//        if MyBrain.isReserveSlot ( aPlayer.CellX , aPlayer.CellY ) then Exit;   //

          // gk solo nel posto del gk
          if (isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER) then  begin
            CancelDrag ( aPlayer,aPlayer.DefaultCellX , aPlayer.DefaultCellY );
            exit;    // un goalkeeper può essere schierato solo in porta
          end;
          if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.TalentId1 = TALENT_ID_GOALKEEPER) then begin    // un goalkeeper può essere schierato solo in porta
            CancelDrag (aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
            Exit;
          end;
          SE_DragGuid := nil;
          tcp.SendStr( 'TACTIC,' + aPlayer.ids + ',' + IntToStr(CellX) + ',' + IntToStr(CellY) + EndOfLine );// il server risponde con clientLoadbrain
          HighLightFieldFriendly_hide;
          GameScreen := ScreenLiveMatch;
          Exit;
  //        aPlayer.DefaultCellS  := point (CellX,CellY);
  //        MoveInDefaultField(aPlayer);
  //        aPlayer.DefaultCellS  := point (CellX,CellY);
  //        MoveInDefaultField(aPlayer);
  //        aPlayer2.Cells := MyBrain.NextReserveSlot(aPlayer2);
  //        MoveInReserves(aPlayer2);


      end;


    end;
  end
  else if GameScreen = ScreenSubs then begin
    if GCD > 0 then Exit;
    // le subs devono puntare celle in campo e occupate da player friendly
    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = se_field then begin   // sposto solo players , non altri sprites

        aPlayer := MyBrain.GetSoccerPlayer2 (SE_DragGuid.Guid); // mouseup su qualsiasi cella
        if MyBrain.Score.TeamSubs [ aPlayer.team ] >= 3 then goto exitScreenSubs;
        //cellX e CellY devono essere in campo, mai fuori
        if IsOutSide( CellX, CellY) then goto exitScreenSubs;
        if SE_DragGuid = nil then goto exitScreenSubs;


        // il mouseup è solo in campo, mai click fuori dal campo
        aPlayer2 := MyBrain.GetSoccerPlayer (CellX, CellY); // mouseup su qualsiasi cella
        if aPlayer2 <> nil then begin
          // se_dragguid deve essere uno che proviene dalla panchina
          // gk solo nel posto del gk
          if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
          or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then goto exitScreenSubs;
          if aPlayer.Ids = aPlayer2.Ids then goto exitScreenSubs;
          if (isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER) then goto exitScreenSubs;;    // un goalkeeper può essere schierato solo in porta
          if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 = TALENT_ID_GOALKEEPER) then goto exitScreenSubs;;    // un goalkeeper può essere schierato solo in porta
          if aPlayer.Team <>  MyBrain.TeamTurn  then goto exitScreenSubs;;  // sposto solo i miei
          if aPlayer.gameover then goto exitScreenSubs;;  // non espulsi o già sostitutiti
          if aPlayer.disqualified > 0 then goto exitScreenSubs;;  // non squalificati
          if not MyBrain.isReserveSlot ( aPlayer.CellX, aPlayer.cellY) then goto exitScreenSubs;; // solo uno dalla panchina su una cella già occupata
          if AbsDistance(aPlayer2.CellX, aPlayer2.CellY, MyBrain.Ball.CellX ,MyBrain.Ball.celly) < 4 then goto exitScreenSubs;;
//          if ((CellX = 0) or (CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team <> 0) then
//            goto exitScreenSubs;;
//          if ((CellX = 11) or (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team <> 1) then
//            goto exitScreenSubs;;

          SE_DragGuid := nil;
          HighLightFieldFriendly_hide;
          tcp.SendStr( 'SUB,' + aPlayer.ids + ',' + aPlayer2.ids + EndOfLine );// il server risponde con clientLoadbrain
          fGameScreen := ScreenLiveMatch;
          Exit;
        end
        else begin // aplayer2 ! non esiste, metto via tutto
exitScreenSubs:
          SE_DragGuid := nil;
          HighLightFieldFriendly_hide;
          MoveInReserves(aPlayer);
          Exit;
        end;
      end;
    end;

  end;

end;
procedure TForm1.SetupGridXP (GridXP: SE_grid; aPlayer: TsoccerPlayer);
var
  i,y: Integer;
  ts :TStringList;
  a,b: integer;
begin
  GridXp.ClearData;   // importante anche pr memoryleak
  GridXp.DefaultColWidth := 16;
  GridXp.DefaultRowHeight := 16;
  GridXp.ColCount := 2;
  GridXp.RowCount := 6 + NUM_TALENT + 1; // stat num_talent 1 vuota
  GridXp.Columns[0].Width := 120;
  GridXp.Columns[1].Width := 60;
//  GridXp.Columns[2].Width := 40;
  GridXp.Width := GridXp.VirtualWidth;

  GridXP.ScrollBarColor := clWhite;
  GridXP.ScrollBarWidth := 10;
  GridXP.ScrollBarHeight := 20;
  GridXP.ScrollBars := SBVertical;

  for y := 0 to gridXP.RowCount -1 do begin
    GridXp.Rows[y].Height := 16;
    gridXP.Cells[0,y].FontName := 'Verdana';
    gridXP.Cells[0,y].FontSize := 8;
    gridXP.Cells[0,y].FontColor := clWhite;
    gridXP.Cells[1,y].FontColor  := clWhite;
    gridXP.Cells[1,y].CellAlignmentH := hRight;
    gridXP.AddProgressBar(1,y, 0 ,$00804000,pbstandard);
  end;
  GridXp.VirtualHeight := GridXP.TotalCellsHeight;

  GridXP.Cells[0,0].Text :=  Translate('attribute_Speed');
  GridXP.Cells[0,1].Text :=  Translate('attribute_Defense');
  GridXP.Cells[0,2].Text :=  Translate('attribute_Passing');
  GridXP.Cells[0,3].Text :=  Translate('attribute_Ball.Control');
  GridXP.Cells[0,4].Text :=  Translate('attribute_Shot');
  GridXP.Cells[0,5].Text :=  Translate('attribute_Heading');

  GridXP.Cells[0,6].Text :=  '';

  if (aPlayer.DefaultSpeed >= 4) or (aPlayer.Age > 24) or (aPlayer.History_Speed > 0) or (aPlayer.TalentId1=TALENT_ID_GOALKEEPER)  then begin
     // dopo i 24 anni non incrementa più in speed.speed incrementa solo una volta e al amssimo a 4
      GridXP.Cells[1,0].Text  := '' ;
      GridXP.Cells[1,0].ProgressBarValue :=  0;
  end
  else  begin
      GridXP.Cells[1,0].Text  := IntToStr(aPlayer.xp_Speed) + '/' + IntToStr(xp_SPEED_POINTS) ;
      GridXP.Cells[1,0].ProgressBarValue :=  (aPlayer.xp_Speed * 100) div xp_SPEED_POINTS;
  end;

  if aPlayer.DefaultDefense < 6 then begin
    if aPlayer.DefaultShot >= 3 then begin // difesa / shot
      GridXP.Cells[1,1].Text  := '' ;
      GridXP.Cells[1,1].ProgressBarValue :=  0;
    end
    else begin
      GridXP.Cells[1,1].Text  := IntToStr(aPlayer.xp_Defense) + '/' + IntToStr(xp_DEFENSE_POINTS) ;
      GridXP.Cells[1,1].ProgressBarValue :=  (aPlayer.xp_Defense * 100) div xp_DEFENSE_POINTS;
    end;
  end;
  if aPlayer.DefaultPassing < 6 then begin
    GridXP.Cells[1,2].Text  := IntToStr(aPlayer.xp_Passing) + '/' + IntToStr(xp_PASSING_POINTS) ;
    GridXP.Cells[1,2].ProgressBarValue :=  (aPlayer.xp_Passing * 100) div xp_PASSING_POINTS;
  end;
  if aPlayer.DefaultBallControl < 6 then begin
    if (aPlayer.TalentId1=TALENT_ID_GOALKEEPER) then begin
      GridXP.Cells[1,3].Text  := '' ;
      GridXP.Cells[1,3].ProgressBarValue :=  0;
    end
    else begin
      GridXP.Cells[1,3].Text  := IntToStr(aPlayer.xp_BallControl) + '/' + IntToStr(xp_BALLCONTROL_POINTS) ;
      GridXP.Cells[1,3].ProgressBarValue :=  (aPlayer.xp_BallControl * 100) div xp_BALLCONTROL_POINTS;
    end;
  end;
  if aPlayer.DefaultShot < 6 then begin
    if (aPlayer.DefaultDefense >= 3) or (aPlayer.TalentId1=TALENT_ID_GOALKEEPER) then begin // difesa / shot
      GridXP.Cells[1,4].Text  := '' ;
      GridXP.Cells[1,4].ProgressBarValue :=  0;
    end
    else begin
      GridXP.Cells[1,4].Text  := IntToStr(aPlayer.xp_Shot) + '/' + IntToStr(xp_SHOT_POINTS) ;
      GridXP.Cells[1,4].ProgressBarValue :=  (aPlayer.xp_Shot * 100) div xp_SHOT_POINTS;
    end;
  end;
  if aPlayer.DefaultHeading < 6 then begin
    // Heading incrementa solo una volta
    if (aPlayer.History_Heading > 0) or (aPlayer.TalentId1=TALENT_ID_GOALKEEPER) then begin
      GridXP.Cells[1,5].Text  := '' ;
      GridXP.Cells[1,5].ProgressBarValue :=  0;
    end
    else begin
      GridXP.Cells[1,5].Text  := IntToStr(aPlayer.xp_Heading) + '/' + IntToStr(xp_HEADING_POINTS) ;
      GridXP.Cells[1,5].ProgressBarValue :=  (aPlayer.xp_Heading * 100) div xp_HEADING_POINTS;
    end;
  end;

  GridXP.Cells[1,6].Text  := '';

  // rispetto l'esatto ordine dei talenti sul DB
  if aPlayer.TalentId1 = 0 then begin

    for I := 1 to NUM_TALENT do begin
      GridXP.Cells[0,i+6].Text := Translate('Talent_' + Capitalize (stringTalents[i])); // comincio dalla riga 7, la 6 è vuota
    end;

    for I := 1 to NUM_TALENT do begin
      GridXP.Cells[1,i+6].Text := IntToStr(aPlayer.xpTal[I]) + '/' + IntToStr (xpNeedTal[I]); // ogni talento necessita di una certa xp
      GridXP.Cells[1,i+6].ProgressBarValue :=  (aPlayer.xpTal[I] * 100) div xpNeedTal[I];
    end;


  end
  else begin
    for I := 7 to GridXP.RowCount -1 do begin
      GridXP.Cells[0,i].Text:= '';
      GridXP.Cells[1,i].Text:= '';
    //  GridXP.RemoveBitmap (2,i);
    end;

  end;

  ts := TStringList.Create;
  ts.Delimiter := '/';
  ts.StrictDelimiter:= True;
  for I := 0 to GridXP.RowCount -1 do begin
    ts.DelimitedText := GridXP.Cells[1,i].Text ;
    if Length( ts.DelimitedText) < 5 then Continue;

    a := StrToInt(ts[0]);
    b := StrToInt(ts[1]);
    if a >= b then begin   // se sono arrivato a 120 o anche oltre
      GridXP.Cells[0,i].BackColor := clGray;
      GridXP.Cells[1,i].BackColor := clGray;
      GridXP.Cells [0,i].FontColor := $0041BEFF;
      GridXP.Cells [1,i].FontColor := $0041BEFF;
    end;

  end;
  ts.Free;

  GridXP.CellsEngine.ProcessSprites(20);
  GridXP.refreshSurface ( GridXP );
end;
procedure TForm1.SetupGridAttributes (GridAT: SE_grid; aPlayer: TsoccerPlayer; show: char);
var
  i,y: Integer;
  ts :TStringList;
  bmp: SE_bitmap;
begin

  GridAT.ClearData;   // importante anche pr memoryleak
  GridAT.DefaultColWidth := 16;
  GridAT.DefaultRowHeight := 16;
  GridAT.ColCount :=4; // descrizione, vuoto, valore, bitmaps o progressbar
  GridAT.RowCount :=9; // 6 attributi + eta , valore, stamina
  GridAT.Columns[0].Width := 80;
  GridAT.Columns[1].Width := 30; // align right
  GridAT.Columns[2].Width := 10; // vuota
  GridAT.Columns[3].Width := 12*9; //9 massimo valore attributo
  GridAT.Height := 16*9;// 9 righe
  GridAT.Width := 80+30+10+(12*9);

  for y := 0 to GridAT.RowCount -1 do begin
    GridAT.Rows[y].Height := 16;

    GridAT.Cells[0,y].FontName := 'Verdana';
    GridAT.Cells[0,y].FontSize := 8;
    GridAT.cells [0,y].FontColor := clWhite;

    GridAT.Cells[1,y].FontSize := 8;
    GridAT.cells [1,y].FontColor := clWhite;
    GridAT.cells [1,y].FontColor := clYellow;
    GridAT.Cells[1,y].CellAlignmentH := hRight;

  end;

  if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin
    GridAT.Cells[0,0].text:= Translate('attribute_Speed');
    GridAT.Cells[0,1].text:= Translate('attribute_Defense');
    GridAT.Cells[0,2].text:= Translate('attribute_Passing');
    GridAT.Cells[0,3].text:= Translate('attribute_Ball.Control');
    GridAT.Cells[0,4].text:= Translate('attribute_Shot');
    GridAT.Cells[0,5].text:= Translate('attribute_Heading');
    GridAT.Cells[0,6].text:= Translate('lbl_Age');
    GridAT.Cells[0,7].text:= Translate('lbl_MarketValue');
    GridAT.Cells[0,8].text:= Translate('attribute_Stamina');
  end
  else begin
    GridAT.Cells[0,1].text:= Translate('attribute_Defense');
    GridAT.Cells[0,2].text:= Translate('attribute_Passing');
    GridAT.Cells[0,6].text:= Translate('lbl_Age');
    GridAT.Cells[0,7].text:= Translate('lbl_MarketValue');
    GridAT.Cells[0,8].text:= Translate('attribute_Stamina');
  end;

  if Show = 'a' then begin

    // ora aggiungo i dati

    if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin
      GridAT.Cells[1,0].Text := IntTostr(aPlayer.Speed);
      GridAT.Cells[1,1].Text := IntTostr(aPlayer.Defense);
      GridAT.Cells[1,2].Text := IntTostr(aPlayer.Passing);
      GridAT.Cells[1,3].Text := IntTostr(aPlayer.BallControl);
      GridAT.Cells[1,4].Text := IntTostr(aPlayer.Shot);
      GridAT.Cells[1,5].Text := IntTostr(aPlayer.Heading);
      GridAT.Cells[1,6].Text := IntTostr(aPlayer.Age);
      GridAT.Cells[1,7].Text := IntTostr(aPlayer.MarketValue);
      GridAT.Cells[1,8].Text := IntTostr(aPlayer.Stamina);
    end
    else begin
      GridAT.Cells[1,1].Text := IntTostr(aPlayer.Defense);
      GridAT.Cells[1,2].Text := IntTostr(aPlayer.Passing);
      GridAT.Cells[1,6].Text := IntTostr(aPlayer.Age);
      GridAT.Cells[1,7].Text := IntTostr(aPlayer.MarketValue);
      GridAT.Cells[1,8].Text := IntTostr(aPlayer.Stamina);

    end;
    // i bmp
    bmp:= SE_bitmap.Create ( dir_ball + 'ball2.bmp');

    if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin
      GridAT.AddSE_Bitmap ( 3, 0, aPlayer.Speed, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 1, aPlayer.Defense, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 2, aPlayer.Passing, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 3, aPlayer.BallControl, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 4, aPlayer.Shot, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 5, aPlayer.Heading, bmp, true );
    end
    else begin
      GridAT.AddSE_Bitmap ( 3, 1, aPlayer.Defense, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 2, aPlayer.Passing, bmp, true );
    end;
    bmp.Free;
  end
  else if show = 'h' then begin

    if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin
      GridAT.Cells[1,0].Text := IntTostr(aPlayer.history_Speed);
      GridAT.Cells[1,1].Text := IntTostr(aPlayer.history_Defense);
      GridAT.Cells[1,2].Text := IntTostr(aPlayer.history_Passing);
      GridAT.Cells[1,3].Text := IntTostr(aPlayer.history_BallControl);
      GridAT.Cells[1,4].Text := IntTostr(aPlayer.history_Shot);
      GridAT.Cells[1,5].Text := IntTostr(aPlayer.history_Heading);
      GridAT.Cells[1,6].Text := IntTostr(aPlayer.Age);
      GridAT.Cells[1,7].Text := IntTostr(aPlayer.MarketValue);
      GridAT.Cells[1,8].Text := IntTostr(aPlayer.Stamina);
    end
    else begin
      GridAT.Cells[1,1].Text := IntTostr(aPlayer.history_Defense);
      GridAT.Cells[1,2].Text := IntTostr(aPlayer.history_Passing);
      GridAT.Cells[1,6].Text := IntTostr(aPlayer.Age);
      GridAT.Cells[1,7].Text := IntTostr(aPlayer.MarketValue);
      GridAT.Cells[1,8].Text := IntTostr(aPlayer.Stamina);

    end;
    // i bmp
    bmp:= SE_bitmap.Create ( dir_ball + 'ball2.bmp');

    if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin
      GridAT.AddSE_Bitmap ( 3, 0, aPlayer.history_Speed, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 1, aPlayer.history_Defense, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 2, aPlayer.history_Passing, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 3, aPlayer.history_BallControl, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 4, aPlayer.history_Shot, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 5, aPlayer.history_Heading, bmp, true );
    end
    else begin
      GridAT.AddSE_Bitmap ( 3, 2, aPlayer.history_Passing, bmp, true );
      GridAT.AddSE_Bitmap ( 3, 3, aPlayer.history_BallControl, bmp, true );
    end;
    bmp.Free;
  end;

  GridAT.AddProgressBar(3,8, (aPlayer.Stamina * 100 ) div 120 ,clGreen {//$00804000},pbstandard); // cellx, celly, value, style
   if aPlayer.Stamina <= 60 then
    GridAT.Cells [3,8].ProgressBarColor := clRed
    else GridAT.Cells [3,8].ProgressBarColor:=clGreen {//$00804000};


  GridAT.CellsEngine.ProcessSprites(20);
  GridAT.RefreshSurface ( GridAT );




end;


procedure TForm1.SetTcpFormation;
var
  i: Integer;
  TcpForm: TStringList;
  aPlayer: TSoccerPlayer;
begin
  if GCD <= 0 then begin
    TcpForm:= TStringList.Create ;
    { TODO -cfuturismi : check duplicati anche qui come sul server }
    for i := 0 to MyBrainFormation.lstSoccerPlayer.Count -1 do begin
      aPlayer := MyBrainFormation.lstSoccerPlayer[i];
  // il server valida anche gli Ids, qui il client non può perchè non conosce gli id
           TcpForm.Add( aPlayer.ids  + '=' +
           IntToStr(aPlayer.AIFormationCellX ) + ':' +
           IntToStr(aPlayer.AIFormationCellY ));
    end;

    tcp.SendStr(  'setformation,' +  TcpForm.CommaText + endofline);
    TcpForm.Free;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.tcpDataAvailable(Sender: TObject; ErrCode: Word);
var
  I, LEN, totalString: Integer;
  Buf     : array [0..8191] of AnsiChar;
  ini : Tinifile;
  Ts: TstringList;
  filename,tmpStr: string;
  MMbraindata: TMemoryStream;
  MMbraindataZIP: TMemoryStream;
  SignaturePK : string;
  SignatureBEGINBRAIN: string ;
  DeCompressedStream: TZDecompressionStream;
  s1,s2,s3,s4,InBuffer: string;
  MM,MM2 : TMemoryStream;
  label firstload;
begin
 //   MMbraindata:= TMemoryStream.Create;
 //   MMbrainData.Size := TWSocket(Sender).BufSize;
 //   Len := TWSocket(Sender).Receive(MMbrainData.Memory , TWSocket(Sender).BufSize );
 //   SetString(aaa, PAnsiChar( MMbrainData.Memory ), MMbraindata.Size ); //div SizeOf(Char));
 //   MMbraindata.Free;
//    Len := TCustomLineWSocket(Sender).Receive(@Buf, Sizeof(Buf) - 1);

    // arrivano dati compressi solo dopo beginbrain e beginteam

    MM := TMemoryStream.Create;  // potrebbe anche non servire a nulla
    MM.Size := Sizeof(Buf) - 1;
    Len := TWSocket(Sender).Receive( MM.Memory,  Sizeof(Buf) - 1);
    CopyMemory( @Buf, MM.Memory, Len  ); // metto nel buffer per i comandi non compressi
    TWSocket(Sender).DeleteBufferedData ;
//    Len := TWSocket(Sender).Receive(@Buf, Sizeof(Buf) - 1);

    if Len <= 0 then begin
      MM.Free;
      Exit;
    end;

    // COMPRESSED PACKED
    { string(buf) mi tronca la stringa zippata }
 //   SetLength( dataStr ,  Len - 19 );
    tmpStr := String(Buf);
    if MidStr( tmpStr,1,4 )= 'GUID' then begin  // guid,guidteam,teamname,nextha,mi
  //    dal server arriva una prima parte stringa e poi uno stream compresso:
  //    Cli.SendStr( 'GUID,' + IntToStr(Cli.GuidTeam ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + ',' +
  //    'BEGINBRAIN' +  chr ( abrain.incMove )   +  brainManager.GetBrainStream ( abrain ) + EndofLine);

      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );
      viewMatch := false;
      LiveMatch := true;
      s1 := ExtractWordL (2, tmpStr, ',');
      s2 := ExtractWordL (3, tmpStr, ',');
      s3 := ExtractWordL (4, tmpStr, ',');
      s4 := ExtractWordL (5, tmpStr, ',');
      MyGuidTeam :=  StrToInt(s1);
      MyGuidTeamName :=  s2;


      TotalString := 4 + 5 + Length (s1) + Length (s2) +Length (s3) +Length (s4) ; //4 è la lunghezza di 'GUID' e 5 sono le virgole
      LastTcpIncMove := ord (buf [TotalString + 10 ]); // 10 è lunghezza di BEGINBRAIN. mi posiziono sul primo byte che indica IncMove
      MemoC.Lines.Add('BEGINBRAIN '+  IntToStr(LastTcpIncMove) );

      MM2:= TMemoryStream.Create;
      MM2.Write( buf[  TotalString + 11 ] , len - 11 - TotalString ); // elimino s4 e incmove 11 -11. e prima elimino la parte stringa
      DeCompressedStream:= TZDeCompressionStream.Create( MM2  );


      MM3[LastTcpIncMove].Clear;
      MM3[LastTcpIncMove].CopyFrom ( DeCompressedStream, 0);
      MM2.free;     // endsoccer si perde da solo decomprimendo
      DeCompressedStream.Free;
      CopyMemory( @Buf3[LastTcpIncMove], mm3[LastTcpIncMove].Memory , mm3[LastTcpIncMove].size  ); // copia del buf per non essere sovrascritti
      MM3[LastTcpIncMove].SaveToFile( dir_data + IntToStr(LastTcpIncMove) + '.IS');
//      goto firstload;
      if not FirstLoadOK  then begin   // avvio partita o ricollegamento
       // AnimationScript.Reset;
        InitializeTheaterMatch;
        SE_interface.RemoveAllSprites;
        GameScreen:= ScreenLiveMatch; // initializetheatermAtch
        CurrentIncMove := LastTcpIncMove;
        ClientLoadBrainMM (CurrentIncMove, true) ;   // (incmove)
        FirstLoadOK := True;

        if ViewReplay then ToolSpin.Visible := True;
        for I := 0 to 255 do begin
         incMoveAllProcessed [i] := false;
         incMoveReadTcp [i] := false;
        end;
        for I := 0 to CurrentIncMove do begin
         incMoveAllProcessed [i] := true; // caricato e completamente eseguito
         incMoveReadTcp [i] := true;
        end;


        SpriteReset;
        // se è la prima volta, ricevo una partita terminata
        if (mybrain.finished) then begin //and   (Mybrain.Score.TeamGuid [0]  = MyGuidTeam ) or (Mybrain.Score.TeamGuid [1]  = MyGuidTeam ) then begin
          ShowMatchInfo;
        end
        else
          ThreadCurMove.Enabled := true; // eventuale splahscreen compare tramite tsscript e obbliga al pulsante exit. 30 seconplay se c'è il suo guidteam
      end;

      MM.Free;
      Exit;
    end
    else if MidStr( tmpStr,1,10 )= 'BEGINBRAIN' then begin   { il byte incmove nella stringa}


        MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

        LastTcpIncMove := ord (buf [10]);
        MemoC.Lines.Add('BEGINBRAIN '+  IntToStr(LastTcpIncMove) );

        // elimino beginbrain
        MM2:= TMemoryStream.Create;
        MM2.Write( buf[11] , len - 11 ); // elimino beginbrain   e incmove 11 -11

        // su mm3 ho 9c78 compressed
         DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
  //       mm3[incmove].clearM
         MM3[LastTcpIncMove].Clear;
  //       DeCompressedStream.Position := 0;
         MM3[LastTcpIncMove].CopyFrom ( DeCompressedStream, 0);
         MM2.free;     // endsoccer si perde da solo decomprimendo
         DeCompressedStream.Free;
  //      CopyMemory( @Buf3, mm3.Memory , mm3.size  ); // copia del buf per non essere sovrascritti
        CopyMemory( @Buf3[LastTcpIncMove], mm3[LastTcpIncMove].Memory , mm3[LastTcpIncMove].size  ); // copia del buf per non essere sovrascritti
        MM3[LastTcpIncMove].SaveToFile( dir_data + IntToStr(LastTcpIncMove) + '.IS');
    firstload:
        if viewMatch or LiveMatch then begin
          if not FirstLoadOK  then begin   // avvio partita o ricollegamento. se è la prima volta
            InitializeTheaterMatch;
            GameScreen:= ScreenLiveMatch; // initializetheatermAtch
            CurrentIncMove := LastTcpIncMove;
            ClientLoadBrainMM (CurrentIncMove, true) ;   // (incmove)
            FirstLoadOK := True;
            for I := 0 to 255 do begin
             incMoveAllProcessed [i] := false;
             incMoveReadTcp [i] := false;
            end;
            for I := 0 to CurrentIncMove do begin
             // caricato e completamente eseguito
             incMoveAllProcessed [i] := true;
             incMoveReadTcp [i] := true;
            end;


            SpriteReset;
            ThreadCurMove.Enabled := true;

          end;

        end;
          MM.Free;
          Exit;
    end
    else if MidStr(tmpStr,1,9 )= 'BEGINTEAM' then begin

      ThreadCurMove.Enabled := false; // parte solo in beginbrain
      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

      // elimino beginbrain
      MM2:= TMemoryStream.Create;
      MM2.Write( buf[9] , len - 9 ); // elimino beginteam

      // su mm3 ho 9c78 compressed
       DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
       MM3[0].Clear;
//       DeCompressedStream.Position := 0;
       MM3[0].CopyFrom ( DeCompressedStream, 0);
       MM2.free;     // endsoccer si perde da solo decomprimendo
       DeCompressedStream.Free;
      CopyMemory( @Buf3[0][0], mm3[0].Memory , mm3[0].size  ); // copia del buf per non essere sovrascritti
      GameScreen := ScreenFormation;

      ClientLoadFormation;
      MM.Free;
      Exit;
    end
    else if MidStr(tmpStr,1,11 )= 'BEGINMARKET' then begin
      ThreadCurMove.Enabled := false; // parte solo in beginbrain
      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

      // elimino beginbrain
      MM2:= TMemoryStream.Create;
      MM2.Write( buf[11] , len - 11 ); // elimino beginMarket

      // su mm3 ho 9c78 compressed
      DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
      MM3[0].Clear;
//       DeCompressedStream.Position := 0;
      MM3[0].CopyFrom ( DeCompressedStream, 0);
      MM2.free;     // endsoccer si perde da solo decomprimendo
      DeCompressedStream.Free;
      CopyMemory( @Buf3[0][0], mm3[0].Memory , mm3[0].size  ); // copia del buf per non essere sovrascritti
      GameScreen := ScreenMarket;
      ClientLoadMarket;
      MM.Free;
      Exit;
    end
    else if MidStr(tmpStr,1,8 )= 'BEGINLAB' then begin
      ThreadCurMove.Enabled := false; // parte solo in beginbrain
      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

      // elimino beginbrain
      MM2:= TMemoryStream.Create;
      MM2.Write( buf[8] , len - 8 ); // elimino beginLAB

      // su mm3 ho 9c78 compressed
      DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
      MM3[0].Clear;
//       DeCompressedStream.Position := 0;
      MM3[0].CopyFrom ( DeCompressedStream, 0);
      MM2.free;     // endsoccer si perde da solo decomprimendo
      DeCompressedStream.Free;
      CopyMemory( @Buf3[0][0], mm3[0].Memory , mm3[0].size  ); // copia del buf per non essere sovrascritti
      ClientLoadListMatchFile;
      GameScreen := ScreenSelectLiveMatch;
      MM.Free;
      Exit;
    end;

    ThreadCurMove.Enabled := false; // parte solo in beginbrain
    MemoC.Lines.Add( 'normal size: ' + IntToStr(Len) );

  //  Buf[Len]       := #0;              { Nul terminate  }
    Ts:= Tstringlist.Create ;
    Ts.StrictDelimiter := True;
    ts.CommaText := RemoveEndOfLine(String(Buf));
//    ts.CommaText := RemoveEndOfLine(aaa);
    MemoC.Lines.Add('<---Tcp:'+ Ts.CommaText);
    if rightstr(ts[0],4) = 'guid' then begin   // guid,guidteam,teamname,nextha,mi
      MyGuidTeam := StrToInt(ts[1]);
      MyGuidTeamName := ts[2];
      Caption := Edit1.Text + '-' + MyGuidTeamName;
      GameScreen := ScreenMain;
    end
    else if  ts[0] = 'BEGINWT' then begin  // lista team della country selezionata
      SE_GridCountryTeam.Active := true;
      ts.Delete(0); // BEGINWT
      TsNationTeams.CommaText := ts.CommaText;
      GameScreen := ScreenSelectTeam;

    end
    else if  ts[0] = 'BEGINWC' then begin // lista country
      SE_GridCountryTeam.Active := true;
      ts.Delete(0); // BEGINWC
      TsWorldCountries.CommaText := ts.CommaText;
      GameScreen := ScreenSelectCountry;
    end
    else if  ts[0] = 'BEGINLM' then begin // lista match attivi-
      ts.Delete(0); // BEGINLM
    end
    else if ts[0] = 'avg' then begin   // media ms di attesa, da fare in futuro
      //MyGuidTeam := StrToInt(ts[1]);
      //MyGuidTeamName := ts[2];
      //Caption := Edit1.Text + '-' + MyGuidTeamName;
      GameScreen := ScreenWaitingLiveMatch;
    end
    else if ts[0] = 'errorlogin' then begin
      lastStrError:= ts[0];
      ShowError( Translate(ts[0]));
    end
    else if ts[0] = 'errorformation' then begin
      lastStrError:= ts[0];
      ShowError( Translate(ts[0]));
    end
    else if ts[0] = 'la' then begin  // level up attribute : guid, value
//      ShowError( Translate(ts[0]));
      ShowLevelUpA ( ts[1], ts[2] );
    end
    else if ts[0] = 'lt' then begin  // level up talent : guid, value
//      ShowError( Translate(ts[0]));
      ShowLevelUpT ( ts[1], ts[2] );
    end;

    ts.Free;
    MM.Free;

end;

procedure TForm1.tcpException(Sender: TObject; SocExcept: ESocketException);
begin

      MemoC.Lines.add('Can''t connect, error ' + SocExcept.ErrorMessage);
      GameScreen := ScreenLogin;

end;

procedure TForm1.tcpSessionClosed(Sender: TObject; ErrCode: Word);
begin
      WaitForSingleObject ( MutexAnimation, INFINITE );
      AnimationScript.Reset;
      FirstLoadOK:= False;
      ReleaseMutex(MutexAnimation );
      LastTcpincMove := 0;
      CurrentIncMove:=0;
      MyGuidTeam := 0;
      Timer1.Enabled := true;
      lbl_ConnectionStatus.Color := clRed;
      lbl_ConnectionStatus.Caption := 'connecting';
      GameScreen := ScreenLogin;
      MyBrainFormation.lstSoccerPlayer.Clear;
      ThreadCurMove.Enabled := False;
      viewMatch := false;
      LiveMatch := false;
end;

procedure TForm1.tcpSessionConnected(Sender: TObject; ErrCode: Word);
begin
    if ErrCode <> 0 then begin
      Timer1.Enabled := true;
      MemoC.Lines.add('Can''t connect, error #' + IntToStr(ErrCode));
      GameScreen := ScreenLogin;
      MouseWaitFor := WaitForAuth;
      lbl_ConnectionStatus.Color := clRed;
      lbl_ConnectionStatus.Caption := 'connecting';
      ThreadCurMove.Enabled := False;
      viewMatch := false;
      LiveMatch := false;

    end
    else  begin
      se_Theater1.Active := true;
      MemoC.Lines.add('Session Connected.');
      //GameScreen := ScreenLogin;
      MouseWaitFor := WaitForAuth;
      lbl_ConnectionStatus.Color := clGreen;
      lbl_ConnectionStatus.Caption := 'connected';
      viewMatch := false;
      LiveMatch := false;
    end;
end;

procedure TForm1.ThreadCurMoveTimer(Sender: TObject);
begin
      // brain in memoria e sprite a video
      // se c'è lo script lo eseguo
    WaitForSingleObject ( MutexAnimation, INFINITE );

    if ( SE_ball.IsAnySpriteMoving  ) or (SE_players.IsAnySpriteMoving ) or ( Animating ) then begin
      ReleaseMutex(MutexAnimation);
      Exit;
    end;


    if CurrentIncMove <= LastTcpIncMove  then begin

    //  if incMoveAllProcessed [CurrentIncMove] = false then begin   // se non è stato ancora caricato ed eseguito nella tsScript

      if incMoveReadTcp [CurrentIncMove] = false then begin   // se non è stato ancora caricato letto in Tcp

        ClientLoadScript ( CurrentIncMove ); // ( MM3, buf3 ); // punta direttamente dove comincia tsScript . riempe mybrain.tscript.commatext

        if Mybrain.tsScript.Count = 0 then begin           // se animationScript ha finito di processare tutte le commatext di Mybrain.tsscript
          ClientLoadBrainMM ( CurrentIncMove, false);      // oppure se non c'è stringa commatext
          incMoveReadTcp [CurrentIncMove] := True; // caricato e completamente eseguito
          incMoveAllProcessed [CurrentIncMove] := True; // caricato e completamente eseguito
         // Inc(CurrentIncMove); // se maggiore al giro dopo aspetta
        end
        else begin
          if AScript <> Mybrain.tsScript.CommaText then begin  // solo script diversi.
            AScript := Mybrain.tsScript.CommaText ;
            LoadAnimationScript; // fa mybrain.tscript.clear ma prima riempe animationScript.  alla fine il thread chiama  ClientLoadBrainMM
          end;
      // per questro motivo MM3 e buf3 devono essere globali
        end;
//          Inc(CurrentIncMove); // se maggiore al giro dopo aspetta
      end
      else begin  // // se è già stato letto in Tcp.  se maggiore al giro dopo aspetta
        if incMoveAllProcessed [CurrentIncMove] = True then // se AnimationScript è terminata
          Inc(CurrentIncMove);
      end;
    end;

    ReleaseMutex(MutexAnimation);


end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  ini : TInifile;
begin
    if ViewReplay then
      exit;
    if Tcp.State = wsConnecting then
        Exit;

    if Tcp.State <> wsConnected then  begin

        ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'client.ini');
        tcp.Addr := ini.ReadString('tcp','addr','127.0.0.1');
        Tcp.Port := ini.ReadString('tcp','port','2018');
        ini.Free;

        tcp.LineMode := true;
        tcp.LineLimit := 8192;
        tcp.LineEdit  := false;
        tcp.LineEnd := EndOfLine;
        tcp.LingerOnOff := wsLingerOn;
        Tcp.Connect;
    end;


      if MyBrain.GameStarted  then begin
        localseconds := localseconds - (Timer1.Interval div 1000);
        if LocalSeconds < 0 then LocalSeconds := 0;

        SE_GridTime.Cells[2,0].ProgressBarValue :=  (localseconds * 100) div 120;
      end;
end;




procedure TForm1.ToolSpinChange(Sender: TObject);
var
  AChar: Char;
begin
  aChar := #13;
  toolSpinKeyPress(Sender, aChar);

end;

procedure TForm1.toolSpinKeyPress(Sender: TObject; var Key: Char);
begin
  {$ifdef tools}
  if Key=#13 then begin
    ThreadCurMove.Enabled := False;
    Key:=#0;

    ViewReplay := True;
  // dialogs
    if FileExists( FolderDialog1.Directory  + '\' + Format('%.*d',[3, Trunc(toolSpin.Value)]) + '.IS'  ) then begin
      AnimationScript.Reset;
      MM3[Trunc(toolSpin.Value)].LoadFromFile( FolderDialog1.Directory  + '\' + Format('%.*d',[3, Trunc(toolSpin.Value)]) + '.IS');
      CopyMemory( @Buf3[Trunc(toolSpin.Value)], MM3[Trunc(toolSpin.Value)].Memory, MM3[Trunc(toolSpin.Value)].size  );

      if Trunc(toolSpin.Value) > 0 then begin
        MM3[Trunc(toolSpin.Value)-1].LoadFromFile( FolderDialog1.Directory  + '\' + Format('%.*d',[3, Trunc(toolSpin.Value)-1]) + '.IS');
        CopyMemory( @Buf3[Trunc(toolSpin.Value)-1], MM3[Trunc(toolSpin.Value)-1].Memory, MM3[Trunc(toolSpin.Value)-1].size  );
        ClientLoadBrainMM ( Trunc(toolSpin.Value)-1, false );
      end;

      CurrentIncMove :=  Trunc(toolSpin.Value);
      ClientLoadScript( Trunc(toolSpin.Value) );
      if Mybrain.tsScript.Count = 0 then begin
        ClientLoadBrainMM ( Trunc(toolSpin.Value), true );
      end
      else
        LoadAnimationScript; // if ts[0] = server_Plm CL_ ecc..... il vecchio ClientLoadbrain . alla fine il thread chiama  ClientLoadBrainMM
    end
    else begin
      ShowMessage('file missing');
    end;

  end;
  {$endif tools}
end;

procedure TForm1.SetGameScreen (const aGameScreen:TGameScreen);
var
  i,y: Integer;
  aPlayer: TSoccerPlayer;
  aSeField: SE_Sprite;

begin

  fGameScreen:= aGameScreen;

  if fGameScreen = ScreenLogin then begin
    //AudioCrowd.Stop;
    WaitForSingleObject ( MutexAnimation, INFINITE );
    AnimationScript.Reset;
    FirstLoadOK:= False;
    Animating := false;
    ReleaseMutex(MutexAnimation );
    LastTcpIncMove := 0;
    CurrentIncMove := 0;

    SE_Theater1.Visible := false;
    SE_GridMatchInfo.Visible := False;
    SE_GridTime.Active := False;
    SE_GridMarket.Active := False;
    viewMatch := False;

    SE_Theater1.Active := False;
    SE_GridTime.Active := False;
    SE_GridDice.Active := false;
    SE_GridXP0.Active := False;
    SE_GridCountryTeam.Active := false;

    ShowLogin;

  end
  else if fGameScreen = ScreenMain then begin
    //AudioCrowd.Stop;
    SE_interface.ClickSprites := false;
    ThreadCurMove.Enabled := false; // parte solo in beginbrain
    WaitForSingleObject ( MutexAnimation, INFINITE );
    AnimationScript.Reset;
    FirstLoadOK:= False;
    Animating := false;
    ReleaseMutex(MutexAnimation );
    LastTcpIncMove := 0;
    CurrentIncMove := 0;

    btnWatchLiveExit.Visible := false;
    PanelInfoPlayer0.Visible:= false;
    PanelXPPlayer0.Visible := false;
    PanelScore.Visible := false;
      lbl_Nick0.Active := False;
      lbl_Nick1.Active := False;

    SE_Theater1.Active := False;
    SE_GridDice.Active := false;
    SE_GridXP0.Active := False;
    SE_GridTime.Active := False;
    SE_GridCountryTeam.Active := false;

    ShowMain;
    //ClientLoadFormation ;
    btnMainPlay.Enabled := CheckFormationTeamMemory;

  end
  else if (fGameScreen = ScreenSelectCountry) or (fGameScreen = ScreenSelectTeam )then begin
    //AudioCrowd.Stop;
    SE_Theater1.Visible := false;

    SE_Theater1.Active := False;
    SE_GridTime.Active := False;
    SE_GridDice.Active := False;
    SE_GridXP0.Active := False;
    SE_GridCountryTeam.Active := true;

    PanelMain.Visible := false;
    PanelLogin.Visible := false;

    SE_GridCountryTeam.ClearData;   // importante anche pr memoryleak
    SE_GridCountryTeam.DefaultColWidth := 16;
    SE_GridCountryTeam.DefaultRowHeight := 16;
    SE_GridCountryTeam.ColCount :=1; // nazione o team
    SE_GridCountryTeam.Columns [0].Width := SE_GridCountryTeam.Width;
    SE_GridCountryTeam.ScrollBarColor := clWhite;
    SE_GridCountryTeam.ScrollBarWidth := 16;
    SE_GridCountryTeam.ScrollBarHeight := 20;
    SE_GridCountryTeam.ScrollBars := SBVertical;


    if fGameScreen = ScreenSelectCountry then begin

      SE_GridCountryTeam.RowCount := TsWorldCountries.count;
      for y := 0 to SE_GridCountryTeam.RowCount -1 do begin
        SE_GridCountryTeam.Rows[y].Height := 16;
        SE_GridCountryTeam.Cells[0,y].FontName := 'Verdana';
        SE_GridCountryTeam.Cells[0,y].FontSize := 8;
        SE_GridCountryTeam.cells [0,y].FontColor := clWhite;
        SE_GridCountryTeam.Cells[0,y].Text:= TsWorldCountries.ValueFromIndex[y];
        SE_GridCountryTeam.Cells[0,y].Ids:= TsWorldCountries.Names[y];
      end;
    end
    else if fGameScreen = ScreenSelectTeam then begin

      SE_GridCountryTeam.RowCount := TsNationTeams.Count;
      for y := 0 to SE_GridCountryTeam.RowCount -1 do begin
        SE_GridCountryTeam.Rows[y].Height := 16;
        SE_GridCountryTeam.Cells[0,y].FontName := 'Verdana';
        SE_GridCountryTeam.Cells[0,y].FontSize := 8;
        SE_GridCountryTeam.cells [0,y].FontColor := clWhite;
        SE_GridCountryTeam.Cells[0,y].Text:= TsNationTeams.ValueFromIndex[y];
        SE_GridCountryTeam.Cells[0,y].Ids:= TsNationTeams.Names[y];
      end;
    end;

    PanelCountryTeam.Visible := True;
    SE_GridCountryTeam.SetViewXY(0,0);
  end
  else if fGameScreen = ScreenWaitingFormation then begin // si accede cliccando back - settcpformation, in attesa
    //AudioCrowd.Stop;

    SE_Theater1.Visible := true;

    SE_Theater1.Active := true;
    SE_GridTime.Active := False;
    SE_GridDice.Active := False;
    SE_GridXP0.Active := false;
    SE_GridCountryTeam.Active := false;

    SetTheaterMatchSize;
    PanelInfoPlayer0.Visible := False;
    PanelMarket.Visible:= False;
    PanelSell.Visible:= false;
    PanelDismiss.Visible:= false;
    Panelformation.Visible:= false;
    CreateNoiseTv;

  end
  else if fGameScreen = ScreenFormation then begin    // diversa da ScreenLiveFormations che prende i dati dal brain

    SE_Theater1.Active := True;
    SE_GridXP0.Active := True;
    SE_GridDice.Active := False;
    SE_GridTime.Active := False;
    SE_GridCountryTeam.Active := false;

    //AudioCrowd.Stop;
    PanelCombatLog.Visible := False;
   // SE_Theater1.Visible := false;
  //  SE_GridTime.Active := False;

    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelCountryTeam.Visible := false;
    PanelListMatches.Visible := false;
    PanelSell.Visible := false;
    PanelMarket.Visible := False;

    PanelScore.Visible:= False;
      lbl_Nick0.Active := False;
      lbl_Nick1.Active := False;

    btnWatchLiveExit.Visible := false;
    PanelInfoPlayer0.Visible:= True;
    PanelXPPlayer0.Visible := false;
    InitializeTheaterFormations;
    ShowFormations;
  end

  else if fGameScreen = ScreenTactics then begin    // btnTACTICS prende i dati dal brain

    if MyBrain.w_CornerSetup or MyBrain.w_CornerKick or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 or
    (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) or Animating then Exit;
   // MyBrain.ClearReserveSlot; // questo va bene e poi le devo riempire con putinreserveslot

    PanelSkill.Visible := False;
    PanelCombatLog.Visible := False;
    // passo da cells a defaultcell. E' visibile anche l'avversario

    for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
      aPlayer := MyBrain.lstSoccerPlayer [i];
      if aPlayer.gameover then Continue;    // espulsi o già sostituiti

        aSEField := SE_field.FindSprite(IntToStr (aPlayer.DefaultCellX ) + '.' + IntToStr (aPlayer.DefaultCellY ));
        aPlayer.se_Sprite.Position := aSEField.position  ;
        aPlayer.se_sprite.MoverData.Destination := aSEField.Position;

       aPlayer.se_sprite.Visible := True;
    end;
    for I := 0 to MyBrain.lstSoccerReserve.Count -1  do begin
      aPlayer := MyBrain.lstSoccerReserve [i];
      //if aPlayer.gameover then Continue;    // espulsi o già sostituiti
      aPlayer.se_sprite.Visible := False
    end;

//    lblSubsLeft.Caption := Translate ( 'Substitutions' ) + ' ' + IntToStr( MyBrain.Score.TeamSubs [MyBrain.TeamTurn]  - MyBrain.InQueueSubsTeam (MyBrain.TeamTurn) );

    MyBrain.Ball.Se_Sprite.Visible := False;


  end
  else if fGameScreen = ScreenSubs then begin    // btnSubs

    PanelSkill.Visible := False;
    PanelCombatLog.Visible := False;

    for I := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      aPlayer := MyBrain.lstSoccerPlayer [i];
        // rendo invisibili i player espulsi o già sostituiti e tutti i player hostile

        if aPlayer.gameover then aPlayer.se_sprite.Visible := False;   // espulsi o già sostituiti
        if  MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin  // nel mio turno
        // rendo invisibili i player Hostile
          if aPlayer.GuidTeam <> MyGuidTeam then
            aPlayer.se_sprite.Visible := False;
        // rendo invisibili i player friendly IN CAMPO distanti >= 4
          if AbsDistance(aPlayer.CellX, aPlayer .CellY, MyBrain.Ball.CellX ,MyBrain.Ball.celly) < 4 then
            aPlayer.se_sprite.Visible := False;
        end;



    end;

    for I := 0 to MyBrain.lstSoccerReserve.Count -1  do begin
      aPlayer := MyBrain.lstSoccerReserve [i];
        if aPlayer.gameover then aPlayer.se_sprite.Visible := False;   // espulsi o già sostituiti
        if  MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin  // nel mio turno
          if aPlayer.GuidTeam <> MyGuidTeam then
            aPlayer.se_sprite.Visible := False
            else aPlayer.se_sprite.Visible := true;
        end;
    end;

    MyBrain.Ball.Se_Sprite.Visible := False;

  end


  else if fGameScreen = ScreenWaitingLiveMatch then begin // si accede cliccando queue
    //AudioCrowd.Stop;
    SE_Theater1.Visible := True;

    SE_Theater1.Active := True;
    SE_GridTime.Active := True;
    //SE_GridDice.Active := True;
    SE_GridXP0.Active := False;
    SE_GridCountryTeam.Active := false;


    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelListMatches.Visible := false;
    SetTheaterMatchSize;
    CreateNoiseTv;

  end
  else if (fGameScreen = ScreenLivematch) or (fGameScreen = ScreenWatchLive) then begin
//    SetTheaterMatchSizeSE;
    SE_Theater1.Visible := True;

    SE_Theater1.Active := True;
    SE_GridTime.Active := True;
    SE_GridXP0.Active := False;
    SE_GridCountryTeam.Active := false;


    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelListMatches.Visible := false;
    btnWatchLiveExit.Visible := false;
    PanelInfoPlayer0.Visible:= True;
    PanelXPPlayer0.Visible := false;
    PanelScore.Visible := true;

    ShowScore;
    SE_GridDice.ClearData;
    SE_GridDice.DefaultColWidth := 80;
    SE_GridDice.DefaultRowHeight := 18;
    SE_GridDice.ColCount :=8;
    SE_GridDice.RowCount :=1;
    SE_GridDice.Columns [0].Width := 1;
    SE_GridDice.Columns [1].Width := 100;
    SE_GridDice.Columns [2].Width := 100;

    SE_GridDice.Columns [3].Width := 32;
    SE_GridDice.Columns [4].Width := 32;

    SE_GridDice.Columns [5].Width := 100;
    SE_GridDice.Columns [6].Width := 100;
    SE_GridDice.Columns [7].Width := 1 ;

   // SE_GridDice.Height := 16*9;// 9 righe
    SE_GridDice.Width := SE_GridDice.TotalCellsWidth;
    PanelCombatLog.Width := SE_GridDice.Width +3 + 3;
    SE_GridDice.rows[0].Height := 18;
    //SE_GridDice.thrdAnimate.Priority := tpLowest;
    //SE_GridDice.Active := True;

//    SE_GridDice.AnimationInterval := 300;
//    SE_GridDice.CellsEngine.ProcessSprites(2000);
//    SE_GridDice.refreshSurface (SE_GridDice);


  end
  else if fGameScreen = ScreenWaitingWatchLive then begin // si accede cliccando l'icona TV
    //AudioCrowd.Stop;
    SE_Theater1.Visible := True;

    SE_Theater1.Active := True;
    SE_GridTime.Active := True;
    //SE_GridDice.Active := True;
    SE_GridXP0.Active := False;
    SE_GridCountryTeam.Active := false;

    PanelMain.Visible := false;
    PanelLogin.Visible := false;
    PanelListMatches.Visible := false;
    SetTheaterMatchSize;
    CreateNoiseTv;

  end
  else if fGameScreen = ScreenSelectLiveMatch then begin
    //AudioCrowd.Stop;
    SE_Theater1.Active := False;
    SE_GridTime.Active := False;
    SE_GridDice.Active := False;
    SE_GridXP0.Active := False;
    SE_GridCountryTeam.Active := False;


    btnWatchLiveExit.Visible := false;
    PanelLogin.Visible := false;
    PanelMain.Visible := false;
    SE_Theater1.Visible := false;
    PanelListMatches.Visible := True;
    SE_GridAllBrain.CellsEngine.ProcessSprites(20);
    SE_GridAllBrain.refreshSurface ( SE_GridAllBrain );
  end
  else if fGameScreen = ScreenMarket then begin
    //AudioCrowd.Stop;
    SE_Theater1.Active := False;
    SE_GridTime.Active := False;
    SE_GridDice.Active := False;
    SE_GridXP0.Active := False;
    SE_GridCountryTeam.Active := False;

    btnWatchLiveExit.Visible := false;
    PanelLogin.Visible := false;
    PanelMain.Visible := false;
    SE_Theater1.Visible := false;
    PanelListMatches.Visible := false;
    PanelMarket.Visible:= True;
  end;


end;
procedure TForm1.ClientLoadListMatchFile ;
var
  i,y,count,Country0,Country1,ActiveMatchesCount,Cur,LBrainIds,LUserName0,LUserName1,LTeamName0,LTeamName1: Integer;
  bmpflags, cBitmap: SE_Bitmap;
  SS : TStringStream;
  dataStr: string;
begin
{ nel server è salvato cossì:
  MM.Write( @BrainManager.lstbrain.count , SizeOf(word) );
  for i := BrainManager.lstbrain.count -1 downto 0 do begin

    MM.Write( @BrainManager.lstBrain[i].BrainIDS, Length (BrainManager.lstBrain[i].BrainIDS) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.UserName[0], Length (BrainManager.lstBrain[i].Score.UserName) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.UserName[1], Length (BrainManager.lstBrain[i].Score.UserName) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.Team[0], Length (BrainManager.lstBrain[i].Score.Team[0]) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.Team[1], Length (BrainManager.lstBrain[i].Score.Team[1]) +1 );
    MM.Write( @BrainManager.lstBrain[i].Score.Country[0], sizeof (word ) );
    MM.Write( @BrainManager.lstBrain[i].Score.Country[1], sizeof (word ) );
    MM.Write( @BrainManager.lstBrain[i].Score.Gol[0], sizeof (byte ) );
    MM.Write( @BrainManager.lstBrain[i].Score.Gol[1], sizeof (byte ) );
    MM.Write( @BrainManager.lstBrain[i].minute, sizeof (byte ) );                       '

  end;
}
  // su MM3 globale c'è la lista
  SS := TStringStream.Create;
  SS.Size := MM3[0].Size;
  MM3[0].Position := 0;
  ss.CopyFrom( MM3[0], MM3[0].size );
  dataStr := SS.DataString;
  SS.Free;

  bmpflags := SE_Bitmap.Create ( dir_interface + 'flags.bmp');

  SE_GridAllBrain.Left := 3;
  SE_GridAllBrain.top := 3;
  SE_GridAllBrain.ClearData;
  SE_GridAllBrain.DefaultColWidth := 80;
  SE_GridAllBrain.DefaultRowHeight := 22;
  SE_GridAllBrain.ColCount := 11;
  SE_GridAllBrain.Rows [0].Height :=22;     //username 0   + brainIds in Ids
  SE_GridAllBrain.Columns [0].Width :=80;     //username 0   + brainIds in Ids
  SE_GridAllBrain.Columns [1].Width :=30;     // bandiera nazione 0
  SE_GridAllBrain.Columns [2].Width :=135;    // teamname  0
  SE_GridAllBrain.Columns [3].Width :=20;     // gol 0
  SE_GridAllBrain.Columns [4].Width :=20;     // gol 1
  SE_GridAllBrain.Columns [5].Width :=135;    // teamname  1
  SE_GridAllBrain.Columns [6].Width :=30;     // bandiera nazione 1
  SE_GridAllBrain.Columns [7].Width :=80;     //username 1
  SE_GridAllBrain.Columns [8].Width :=60;  // vuoto
  SE_GridAllBrain.Columns [9].Width :=30;  // icona tv
  SE_GridAllBrain.Columns [10].Width :=40;  // minute

  // a 0 c'è la word che indica dove comincia
  cur := 0;
  ActiveMatchesCount:=   PWORD(@buf3[0][ cur ])^;                // ragiona in base 0
  SE_GridAllBrain.RowCount := ActiveMatchesCount;
  Cur := Cur + 2; // è una word

  for y := 0 to SE_GridAllBrain.RowCount -1 do begin
    SE_GridAllBrain.Rows[y].Height := 16;
    SE_GridAllBrain.Cells[0,y].FontName := 'Verdana';
    SE_GridAllBrain.Cells[0,y].FontSize := 8;
    SE_GridAllBrain.Cells[0,y].FontColor := clWhite;
    SE_GridAllBrain.Cells[1,y].FontColor  := clWhite;
    SE_GridAllBrain.cells [0,y].CellAlignmentH := hCenter;      // Username 0
    SE_GridAllBrain.cells [7,y].CellAlignmentH := hCenter;      // username 1
    SE_GridAllBrain.cells [2,y].CellAlignmentH := hCenter;      // team 0
    SE_GridAllBrain.cells [5,y].CellAlignmentH := hCenter;      // team 0
    SE_GridAllBrain.cells [3,y].CellAlignmentH := hCenter;      // gol 0
    SE_GridAllBrain.cells [4,y].CellAlignmentH := hCenter;      // gol 1
    SE_GridAllBrain.cells [10,y].CellAlignmentH := hLeft;      // Minute
  end;


  for I := 0 to ActiveMatchesCount -1 do begin
    LBrainIds :=  Ord( buf3[0][ cur ]);
    SE_GridAllBrain.Cells[0,i].ids  := MidStr( dataStr, cur + 2  , LBrainIds );// ragiona in base 1   , setto solo IDS qui
    cur  := cur + LBrainIds + 1;

    LuserName0 :=  Ord( buf3[0][ cur ]);
    SE_GridAllBrain.Cells[0,i].Text  := MidStr( dataStr, cur + 2  , LuserName0 ); // colonna 0 e 7 per gli username
    cur  := cur + LuserName0 + 1;
    LuserName1 :=  Ord( buf3[0][ cur ]);
    SE_GridAllBrain.Cells[7,i].text  := MidStr( dataStr, cur + 2  , LuserName1 );
    cur  := cur + LuserName1 + 1;


    LTeamName0 :=  Ord( buf3[0][ cur ]);
    SE_GridAllBrain.Cells[2,i].Text  := MidStr( dataStr, cur + 2  , LTeamName0 );
    cur  := cur + LTeamName0 + 1;
    LTeamName1 :=  Ord( buf3[0][ cur ]);
    SE_GridAllBrain.Cells[5,i].Text  := MidStr( dataStr, cur + 2  , LTeamName1 );
    cur  := cur + LTeamName1 + 1;


    Country0:=  PWORD(@buf3[0][ cur ])^;                // ragiona in base 0
    cBitmap := SE_Bitmap.Create (60,40);

    case Country0  of
      1: begin
        bmpflags.CopyRectTo( cBitmap, 2,12,0,0,60,40,False,0 );
      end;
      2: begin
        bmpflags.CopyRectTo( cBitmap, 66,12,0,0,60,40,False,0 );
      end;
      3: begin
        bmpflags.CopyRectTo( cBitmap, 130,12,0,0,60,40,False,0 );
      end;
      4: begin
        bmpflags.CopyRectTo( cBitmap, 194,12,0,0,60,40,False,0 );
      end;
      5: begin
        bmpflags.CopyRectTo( cBitmap, 259,12,0,0,60,40,False,0 );
      end;
    end;
    cBitmap.Stretch(30,22);
    SE_GridAllBrain.AddSE_Bitmap (1,i,1,cBitmap,false );
    Cur := Cur + 2;

    Country1:=  PWORD(@buf3[0][ cur ])^;               // ragiona in base 0
    cBitmap := SE_Bitmap.Create (60,40);

    case Country1  of
      1: begin
        bmpflags.CopyRectTo( cBitmap, 2,12,0,0,60,40,False,0 );
      end;
      2: begin
        bmpflags.CopyRectTo( cBitmap, 66,12,0,0,60,40,False,0 );
      end;
      3: begin
        bmpflags.CopyRectTo( cBitmap, 130,12,0,0,60,40,False,0 );
      end;
      4: begin
        bmpflags.CopyRectTo( cBitmap, 194,12,0,0,60,40,False,0 );
      end;
      5: begin
        bmpflags.CopyRectTo( cBitmap, 259,12,0,0,60,40,False,0 );
      end;
    end;
    cBitmap.Stretch(30,22);
    SE_GridAllBrain.AddSE_Bitmap (6,i,1,cBitmap,false );
    Cur := Cur + 2;


    SE_GridAllBrain.Cells[3,i].Text :=  IntToStr( ord ( buf3[0][ cur ]));   // gol 0
    Cur := Cur + 1;
    SE_GridAllBrain.Cells[4,i].Text :=  IntToStr( ord ( buf3[0][ cur ]));   // gol 1
    Cur := Cur + 1;

    SE_GridAllBrain.Cells[10,i].Text :=  IntToStr ( ord ( buf3[0][ cur ]));
    Cur := Cur + 1;

    // 9 vuota

    cBitmap := SE_Bitmap.Create ( dir_interface + 'tv.bmp');
    SE_GridAllBrain.AddSE_Bitmap (9,i,1,cBitmap,false );



  end;

  bmpflags.Free;
end;
procedure TForm1.ClientLoadMarket ;
var
  i,i1,RecordCount,Cur,LSurName,Age : Integer;
  talentID1, talentId2 : byte;
  cBitmap: SE_Bitmap;
  SS : TStringStream;
  dataStr: string;
  MatchesPlayed,MatchesLeft: Word;
  x,y: Integer;
begin
{
    MM.Write( @Count , SizeOf(word) );

    for i := MyQuerymarket.RecordCount -1 downto 0 do begin

      MM.Write( @guidplayer, sizeof ( integer ) );
      MM.Write( @name[0], Length (name) +1 );
      MM.Write( @sellprice, sizeof ( integer ) );

      MM.Write( @speed, sizeof ( byte ) );
      MM.Write( @defense, sizeof ( byte ) );
      MM.Write( @passing, sizeof ( byte ) );
      MM.Write( @ballcontrol, sizeof ( byte ) );
      MM.Write( @shot, sizeof ( byte ) );
      MM.Write( @heading, sizeof ( byte ) );
      MM.Write( @talent, sizeof ( byte ) );

      MM.Write( @matches_played, sizeof ( word ) );
      MM.Write( @matches_left, sizeof ( word ) );
}
  // su MM3 globale c'è la lista
  SS := TStringStream.Create;
  SS.Size := MM3[0].Size;
  MM3[0].Position := 0;
  ss.CopyFrom( MM3[0], MM3[0].size );
  //    dataStr := RemoveEndOfLine(string(buf));
  dataStr := SS.DataString;
  SS.Free;

  SE_GridMarket.ClearData;   // importante anche pr memoryleak
  SE_GridMarket.DefaultColWidth := 16;
  SE_GridMarket.DefaultRowHeight := 22;
  SE_GridMarket.ColCount :=14; // descrizione, vuoto, valore, bitmaps o progressbar
  SE_GridMarket.RowCount :=1;
  SE_GridMarket.Columns [0].Width :=1;      // guidplayer
  SE_GridMarket.Columns [1].Width :=120;     // name
  SE_GridMarket.Columns [2].Width :=80;     // sell
  SE_GridMarket.Columns [3].Width :=100;    // s
  SE_GridMarket.Columns [4].Width :=100;     // d
  SE_GridMarket.Columns [5].Width :=100;     // p
  SE_GridMarket.Columns [6].Width :=100;    // bc
  SE_GridMarket.Columns [7].Width :=100;     // sh
  SE_GridMarket.Columns [8].Width :=100;     // h
  SE_GridMarket.Columns [9].Width :=60;  // talentid1
  SE_GridMarket.Columns [10].Width :=60;  // talentid2
  SE_GridMarket.Columns [11].Width :=80;  // age
  SE_GridMarket.Columns [12].Width :=120;  // matches left
  SE_GridMarket.Columns [13].Width :=60;  // BUY
  SE_GridMarket.Width := SE_GridMarket.TotalCellsWidth;

  SE_GridMarket.ScrollBarColor := clWhite;
  SE_GridMarket.ScrollBarWidth := 10;
  SE_GridMarket.ScrollBarHeight := 20;
  SE_GridMarket.ScrollBars := SBVertical;

  SE_GridMarket.Cells[0,0].Text := '';
  SE_GridMarket.Cells[1,0].Text := Translate('lbl_Surname');
  SE_GridMarket.Cells[2,0].Text := Translate('lbl_Price');
  SE_GridMarket.Cells[3,0].Text := Translate('attribute_Speed');
  SE_GridMarket.Cells[4,0].Text := Translate('attribute_Defense');
  SE_GridMarket.Cells[5,0].Text := Translate('attribute_Passing');
  SE_GridMarket.Cells[6,0].Text := Translate('attribute_Ball.Control');
  SE_GridMarket.Cells[7,0].Text := Translate('attribute_Shot');
  SE_GridMarket.Cells[8,0].Text := Translate('attribute_Heading');
  SE_GridMarket.Cells[9,0].Text := Translate('lbl_Talent');
  SE_GridMarket.Cells[10,0].Text := Translate('lbl_Talent');
  SE_GridMarket.Cells[11,0].Text := Translate('lbl_Age');
  SE_GridMarket.Cells[12,0].Text := Translate('lbl_MatchesLeft');

  SE_GridMarket.Cells [2,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [3,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [4,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [5,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [6,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [7,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [8,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [9,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [10,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [11,0].CellAlignmentH := hCenter;
  SE_GridMarket.Cells [12,0].CellAlignmentH := hCenter;

  SE_GridMarket.Rows[0].Height := 22;

  for x := 0 to SE_GridMarket.ColCount -1 do begin

    SE_GridMarket.Cells[x,y].FontName := 'Verdana';
    SE_GridMarket.Cells[x,y].FontSize := 8;
    SE_GridMarket.cells [x,y].FontColor := clYellow;
  end;

  // a 0 c'è la word che indica dove comincia
  cur := 0;
  RecordCount:=   PWORD(@buf3[0][ cur ])^;                // ragiona in base 0
  SE_GridMarket.RowCount := RecordCount + 1; // intestazione presente
  SE_GridMarket.Virtualheight := SE_GridMarket.TotalCellsHeight;

  for y := 1 to SE_GridMarket.RowCount -1 do begin

    for x := 0 to SE_GridMarket.ColCount -1 do begin

      SE_GridMarket.Rows[y].Height := 22;
      SE_GridMarket.Cells[x,y].FontName := 'Verdana';
      SE_GridMarket.Cells[x,y].FontSize := 8;
      SE_GridMarket.cells [x,y].FontColor := clWhite;
    end;
  end;

  for y := 1 to SE_GridMarket.RowCount -1 do begin  // Non intestazione
    SE_GridMarket.Cells [2,y].CellAlignmentH := hright;
    SE_GridMarket.Cells [3,y].CellAlignmentH := hcenter;
    SE_GridMarket.Cells [4,y].CellAlignmentH := hcenter;
    SE_GridMarket.Cells [5,y].CellAlignmentH := hcenter;
    SE_GridMarket.Cells [6,y].CellAlignmentH := hcenter;
    SE_GridMarket.Cells [7,y].CellAlignmentH := hcenter;
    SE_GridMarket.Cells [8,y].CellAlignmentH := hcenter;
    SE_GridMarket.Cells [11,y].CellAlignmentH := hcenter;
    SE_GridMarket.Cells [12,y].CellAlignmentH := hright;
  end;


  Cur := Cur + 2; // è una word

  for I := 0 to RecordCount -1 do begin
    I1 := i +1;                                  // intestazione grid
    SE_GridMarket.Cells[0,i1].ids  := IntToStr( PDWORD(@buf3[0][ cur ])^); // ids servirà per comprare
    Cur := Cur + 4;

    LSurname :=  Ord( buf3[0][ cur ]);
    SE_GridMarket.Cells[1,i1].Text  := MidStr( dataStr, cur + 2  , LSurname );// ragiona in base 1
    cur  := cur + LSurname + 1;

    SE_GridMarket.Cells[2,i1].Text  :=  IntToStr( PDWORD(@buf3[0][ cur ])^); // sellprice
    Cur := Cur + 4;

    SE_GridMarket.Cells[3,i1].Text  :=  IntToStr( Ord( buf3[0][ cur ]));  // speed
    Cur := Cur + 1;
    SE_GridMarket.Cells[4,i1].Text  :=  IntToStr( Ord( buf3[0][ cur ]));  //
    Cur := Cur + 1;
    SE_GridMarket.Cells[5,i1].Text  :=  IntToStr( Ord( buf3[0][ cur ]));  //
    Cur := Cur + 1;
    SE_GridMarket.Cells[6,i1].Text  :=  IntToStr( Ord( buf3[0][ cur ]));  //
    Cur := Cur + 1;
    SE_GridMarket.Cells[7,i1].Text  :=  IntToStr( Ord( buf3[0][ cur ]));  //
    Cur := Cur + 1;
    SE_GridMarket.Cells[8,i1].Text  :=  IntToStr( Ord( buf3[0][ cur ]));  // heading
    Cur := Cur + 1;

    talentID1 :=  Ord( buf3[0][ cur ]);
    Cur := Cur + 1;
    talentID2:=  Ord( buf3[0][ cur ]);
    Cur := Cur + 1;

    if talentID1 <> 0 then begin
      cBitmap := SE_Bitmap.Create ( dir_talent + IntToStr( talentID1 )+'.bmp' ) ;
      cBitmap.Stretch(30,22);
      SE_GridMarket.AddSE_Bitmap (9,i1,1, cBitmap,true);
    end;
    if talentID2 <> 0 then begin
      cBitmap := SE_Bitmap.Create ( dir_talent + IntToStr (talentID2)+'.bmp' ) ;
      cBitmap.Stretch(30,22);
      SE_GridMarket.AddSE_Bitmap (10,i1,1, cBitmap,true);
    end;

    MatchesPlayed :=  PWORD(@buf3[0][ cur ])^;
    Cur := Cur + 2;

    MatchesLeft :=  PWORD(@buf3[0][ cur ])^;
    Cur := Cur + 2;

    Age:= Trunc(  MatchesPlayed  div SEASON_MATCHES) + 18 ;

    SE_GridMarket.Cells[11,i1].Text  :=  IntToStr( age );
    SE_GridMarket.Cells[12,i1].Text  :=  IntToStr( MatchesLeft );

    SE_GridMarket.Cells[13,i1].BackColor := clGray;
    SE_GridMarket.Cells[13,i1].FontColor := $0041BEFF;
    SE_GridMarket.cells[13,i1].Text := Translate('lbl_Buy');


  end;

  SE_GridMarket.CellsEngine.ProcessSprites(2000);
  SE_GridMarket.refreshSurface ( SE_GridMarket );


end;

// utilities
{
procedure TForm1.MovMouseEnter ( Sender : TObject);
var
  I, MoveValue: Integer;
  FriendlyWall, OpponentWall,FinalWall: Boolean;
  aCellList: TList<TPoint>;
begin
//  hidechances;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
  SE_GridDice.ClearData;
  SE_GridDice.RowCount := 1;
  SE_GridDice.CellsEngine.ProcessSprites(2000);
  SE_GridDice.refreshSurface (SE_GridDice);

  if SelectedPlayer = nil then Exit;
  if  SelectedPlayer.HasBall then begin
    MoveValue := SelectedPlayer.Speed -1;
    if MoveValue <=0 then MoveValue:=1;

    FriendlyWall := true;
    OpponentWall := true;
    FinalWall := true;
  end
  else begin
    MoveValue := SelectedPlayer.Speed ;
    FriendlyWall := false;
    OpponentWall := false;
    FinalWall := true;
  end;

  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY, MoveValue,True,true , True,aCellList); // noplayer,noOutside
  for I := 0 to aCellList.Count -1 do begin

          MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.Celly, aCellList[i].X, aCellList[i].Y,
                                MoveValue,false,FriendlyWall,
                                OpponentWall,FinalWall,ExcludeNotOneDir, SelectedPlayer.MovePath );
      if SelectedPlayer.MovePath.Count > 0 then begin
        HighLightField (aCellList[i].X, aCellList[i].Y, 0 );
      end;

  end;
  aCellList.Free;


end;

procedure TForm1.ShpMouseEnter ( Sender : TObject);
var
  I: Integer;
  aCellList: TList<TPoint>;
  aPlayer: TSoccerPlayer;
begin
  hidechances;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
  SE_GridDice.ClearData ;
  SE_GridDice.RowCount := 1;
  SE_GridDice.CellsEngine.ProcessSprites(2000);
  SE_GridDice.refreshSurface (SE_GridDice);
  if SelectedPlayer = nil then Exit;

  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY, ShortPassRange + SelectedPlayer.tal_longpass  ,false,True,true ,aCellList); // noplayer,noOutside

  for I := 0 to aCellList.Count -1 do begin
    aPlayer := MyBrain.GetSoccerPlayer(aCellList[i].X, aCellList[i].Y);
    if aPlayer <> nil then begin
      if (aPlayer.Team <> SelectedPlayer.team) or (aPlayer.Ids = SelectedPlayer.Ids) then Continue;
    end;
   // HighLightField2 ( aCellList[i].X, aCellList[i].Y );
    HighLightField (aCellList[i].X, aCellList[i].Y, 0);

  end;
  aCellList.Free;


end;
procedure TForm1.LopMouseEnter ( Sender : TObject);
var
  I: Integer;
  aCellList: TList<TPoint>;
  aPlayer: TSoccerPlayer;
begin
  hidechances;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
  SE_GridDice.ClearData ;
  SE_GridDice.RowCount := 1;
  SE_GridDice.CellsEngine.ProcessSprites(2000);
  SE_GridDice.refreshSurface (SE_GridDice);

  if SelectedPlayer = nil then Exit;

  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY, LoftedPassRangeMax + SelectedPlayer.tal_longpass  ,false, True, true,aCellList); // noplayer,noOutside


  for I := 0 to aCellList.Count -1 do begin
    if AbsDistance(SelectedPlayer.CellX, SelectedPlayer.CellY,aCellList[i].X, aCellList[i].Y) < LoftedPassRangeMin then Continue;

    aPlayer := MyBrain.GetSoccerPlayer(aCellList[i].X, aCellList[i].Y);
    if aPlayer <> nil then begin
      if aPlayer.Team <> SelectedPlayer.team then Continue;
    end;
    HighLightField (aCellList[i].X, aCellList[i].Y , 0);

  end;
  aCellList.Free;


end;
procedure TForm1.CroMouseEnter ( Sender : TObject);
var
  I: Integer;
  aCellList: TList<TPoint>;
  aPlayer: TSoccerPlayer;
begin
  hidechances;
  SE_GridDice.ClearData ;
  SE_GridDice.RowCount := 1;
  SE_GridDice.CellsEngine.ProcessSprites(2000);
  SE_GridDice.refreshSurface (SE_GridDice);
  if SelectedPlayer = nil then Exit;

  aCellList:= TList<TPoint>.Create;

  MyBrain.GetNeighbournsCells( SelectedPlayer.CellX, SelectedPlayer.CellY,CrossingRangeMax + SelectedPlayer.tal_longpass  ,false,True,True, aCellList); // noplayer,noOutside


  for I := 0 to aCellList.Count -1 do begin
    if AbsDistance(SelectedPlayer.CellX, SelectedPlayer.CellY,aCellList[i].X, aCellList[i].Y) < CrossingRangeMin then Continue;

    aPlayer := MyBrain.GetSoccerPlayer(aCellList[i].X, aCellList[i].Y);
    if aPlayer <> nil then begin
      if aPlayer.Team <> SelectedPlayer.team then Continue;
      if not aPlayer.InCrossingArea  then Continue;
      HighLightField (aCellList[i].X, aCellList[i].Y,0);

    end;

  end;
  aCellList.Free;


end;
procedure TForm1.DriMouseEnter ( Sender : TObject);
var
  I: Integer;
  aPlayerList: TObjectList<TSoccerPlayer>;
  aPlayer: TSoccerPlayer;
begin
  hidechances;
  PanelCombatLog.Left :=  (PanelBack.Width div 2 ) - (PanelCombatLog.Width div 2 );   ;
  SE_GridDice.ClearData ;
  SE_GridDice.RowCount := 1;
  SE_GridDice.CellsEngine.ProcessSprites(2000);
  SE_GridDice.refreshSurface (SE_GridDice);
  if SelectedPlayer = nil then Exit;

  aPlayerList:= TObjectList<TSoccerPlayer>.create(False);

  MyBrain.GetNeighbournsOpponent( SelectedPlayer.CellX, SelectedPlayer.CellY, SelectedPlayer.Team ,aPlayerList);

  for I := 0 to aPlayerList.Count -1 do begin
   // HighLightField2 ( aCellList[i].X, aCellList[i].Y );
      HighLightField (aPlayerList[i].cellX, aPlayerList[i].cellY,0);
  end;

  aPlayerList.Free;


end;

procedure TForm1.TackleMouseEnter ( Sender : TObject);
begin
  hidechances;
  PanelCombatLog.Left := PanelSkill.Left + PanelSkill.Width;
  SE_GridDice.ClearData ;
  SE_GridDice.RowCount := 1;
  SE_GridDice.CellsEngine.ProcessSprites(2000);
  SE_GridDice.refreshSurface (SE_GridDice);

  if Mybrain.Ball.Player <> nil then begin
    if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin

      CreateArrowDirection ( SelectedPlayer , Mybrain.Ball.Player );
      SE_GridDiceWriteRow  ( SelectedPlayer.Team, UpperCase(Translate('attribute_Defense')),
        SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(SelectedPlayer.Defense + SelectedPlayer.Tal_Toughness));
      SE_GridDiceWriteRow  ( Mybrain.Ball.Player.Team,  UpperCase(Translate('attribute_Ball.Control')),
        Mybrain.Ball.Player.SurName, Mybrain.Ball.Player.Ids, 'VS',IntToStr(Mybrain.Ball.Player.BallControl + Mybrain.Ball.Player.Tal_Power));
     // CreateTextChanceValueSE ( Mybrain.Ball.Player.ids, Mybrain.Ball.Player.BallControl + Mybrain.Ball.Player.tal_Power   , 0,0,0,0 );
     // CreateTextChanceValueSE ( SelectedPlayer.ids, SelectedPlayer.Defense + SelectedPlayer.tal_toughness  , 0,0,0,0);
    end;
  end;

end;

}
end.


