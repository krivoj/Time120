unit Unit1;
{$DEFINE TOOLS}
{$R-}

  { TODO -cbug :
    inizo partita LOP e poi non arriva PASS, ma fa un solo turno
    controllare invio dati dal server corrotto dopo un tot di inattività. o è compressione o è ics o è il mm3 o il brain.

    fine partita rimane su sto caricando perchè è ancora in inliveguidteam (5 secondi) .fare IF FLAGENDGAME
    if Minute >= 120 then FlagEndGame := True; // le sostituzioni non incrementano i minuti    deve usare anche finished

  }
  { TODO -ctest :
    bug lastman. ricalcolare le condizioni . anche la nuova versione forse non va bene. c'è sicuro errore perchè compare al 44' di una partita
    islastman diventa islastman ( aplayer, ballplayer)

    verificare in spritereset e ovunque la palla sempre in movimento, tanto corner e freekick settano la palla
    Server, gender bonus. controllare anche AI.
  }
  { TODO -ctodoreali :
    cl_splash.gameover aggiungere miGain
    esagoni dei colori blu, viola ecc... anche stelle. e stelle in showgameover
    dopo rank1 comincia il campionato a 38 gare per i punti. se ne fa 70, vince la coppa ( hall of fame )
    aggiungere frecce doppie a nuovo team
    fare passaggio rank sul server
    fare comparire nome skill in basso sul mouseover della skill se_skills

    ischeatingball è  da rifare. Isolare la palla tenendo conto dle fatto che i Gk può finire il turno con la palla tra le mani.
    .tmp da mettere come variabili gender  TALENT_ID_ADVANCED_CROSSING ha bisogno di +2 dal fondo

    standings, icone mappamondo, country, fra il team. you e il team. il team è la somma di tutti i team come il tuo. refresh ogni 24 ore.
    anzi alcune query ogni settimana. tutto su dbforge in mantanaince
    il team non ha classifica tra il team stesso. 3 icona a sinistra , 2 a destra

    creare più formazioni , forse bug nella fatigue

    icona skill short.passing piede+palla
  }
  { TODO -csviluppo :
    campionato a 32 squadre, 16, 8 etc.... ?
    implementare versione locale o campionati in rete indipendente ?
    ordinare per performance  i cmd dal client ?
    gestire incrossbarposition, ingolposition con nextsound?

    ssl con passwordrandom
    Aggiorno classifica cannonieri ?

    aggiunta di 2 talenti
      talento Volley+2 prereq: bomb. volley si attiva anche con roll 9.

      TALENT_ID_PLAYMAKER estensione livello 2:
      talento se gioca centro 234(sua metacampo) ha +2 passaggio  +3m ( regista ) . solo sua metacampo

    Valutare se Pos (tiro potente) può innescare autogol


    funzione aggiungi amico
    cellx, celly fare Shortint. cambiare tutti i tpoint in TShortPoint
           }

      // procedure importanti:
      //    procedure tcpDataAvailable <--- input dal server
      //    procedure ClientLoadBrainMM  ( incMove: Byte ) Carica il brain arrivato dal server
      //    procedure Anim --> esegue realmente l'animazione

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Types, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, generics.collections, Strutils, Inifiles,math, FolderDialog,generics.defaults,
  Vcl.Grids, Vcl.ComCtrls,  Vcl.Menus, Vcl.Mask,
  Vcl.StdCtrls, Vcl.ExtCtrls, Winapi.MMSystem,    // Delphi libraries

  SoccerBrainv3,   // il cuore del gioco, si occupa della singola partita


  DSE_Random ,     // DSE Package
  DSE_PathPlanner,
  DSE_theater,
  DSE_ThreadTimer,
  dse_bitmap,
  dse_defs,
  DSE_misc,
  DSE_SearchFiles,
  DSE_Panel,


  CnButtons,CnSpin,CnAAFont, CnAACtrls, // CnVCLPack

  ZLIBEX,                             // delphizlib invio dati compressi tra server e client

  OverbyteIcsWndControl, OverbyteIcsWSocket   ;  // OverByteIcsWSocketE ics con modifica. vedi directory External.Packages\overbyteICS del progetto



const GCD_DEFAULT = 200;        // global cooldown, minimo 200 ms tra un input verso il server e l'altro ( anti-cheating )
const DEFAULT_SPEED_BALL = 10;
const SPEED_BALL_SHP = 4;
const DEFAULT_SPEED_BALL_LOW = 4;
const ANIMATION_BALL_LOW = 1000;
const ANIMATION_BALL = 30;
const DEFAULT_SPEEDMAX_BALL = 14;
const DEFAULT_SPEED_PLAYER = 10;
const DEFAULT_SPEED_PLAYER_FORMATION = 12;
const Ball0X = 35;               // la palla sta più avanti rispetto allo sprite player
const sprite1cell = 300;        // ms tempo che impiega un player a spostarsi di una cella
const ShowRollLifeSpan = 1000;  // ms tempo di comparsa dei roll
const ShowRollDestination = 2200;  // ms tempo di comparsa di selected.bmp
const ShowFaultLifeSpan = 1600; // ms notifica in caso di fallo
const msSplashTurn = 1600;
const STANDARD_MP_MS = 50;
const EndOfLine = 'ENDSOCCER';  // tutti i pacchetti Tcp tra server e client finiscono con questo marker
type TArray8192 = array [0..8191] of AnsiChar; // i buf[0..255] of  TArray8192 contengono il buffer Tcp in entrata
const ScaleSprites = 0;        // riduzione generica di tutto gli sprite player
const ScaleSpritesBarrier = 85;        // riduzione generica dei player in barriera
const ScaleSpritesFace = 50;        // riduzione face
const ProximityMouse = 40;
Const YMAINBUTTON = 900-56;
Const YLBLMAINBUTTON = 84;
Const YTML = 870;
Const PixelsGolDeep = 24;
Const PixelsCrossbarY = 18;
Const PixelsGKBounce = 32;
Const PixelsGKTake = 24;
// market
  const XSurname = 72; XFitness = 290; XPrice = 1300; XSpeed = 380; XDefense = 460; XPassing =540; XBallControl = 620; XShot = 700; XHeading = 780;
  const XTalents = 870; XAge = 990; XMatchsLeft = 1050;
  const WSurname = 130; WFitness = 80; WPrice = 64; WSpeed = 80; WDefense = 80; WPassing =80; WBallControl = 80; WShot = 80; WHeading = 80;
  const WTalents = 80; WAge = 30; WMatchsLeft = 60;     LY = 4;  FontNameMarket = 'Calibri'; FontSizeMarket = 14;
//AML
  const XUsername0 = 0; XFlag0 = 250; XTeamName0 = 280;  XScore = 640;  XTeamName1 = 660; XFlag1 = 940; XUsername1 = 970; XTV = 1280; XMinute = 1240;
  const WUsername = 250;              WTeamName = 280; WScore = 60; WMinute = 60;
type TStringAlignment = ( TStringCenter, TStringRight);
type TSpriteArrowDirection = record  // le frecce durante waitforSomething
  offset : TPoint;
  angle : single;
end;
// Schermate di gioco, es. ScreenWatchLive quando guardo una partita di altri giocatori.
type TGameScreen =(ScreenLogin, ScreenSelectCountry, ScreenSelectTeam,
                  ScreenFormation,ScreenPlayerDetails,
                  ScreenWaitingFormation, ScreenWaitingLive, ScreenWaitingSpectator,
                  ScreenSpectator,ScreenLive,
                  ScreenTactics, ScreenSubs, ScreenCorner, ScreenFreeKick, ScreenPenalty,
                  ScreenAml, ScreenMarket );

  type TMouseWaitFor = (WaitForGreen, WaitForNone, WaitForAuth, // in attesa di autenticazione login
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
  WaitForXY_CornerCOD ,   // i 3 coa ( difensori sul corner )
  WaitForXY_SetPlayer
  );
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
  Team : Byte;
end;
Type TPointBoolean = record
  X,Y: integer;
  value : boolean;
end;
pPointBoolean = ^TPointBoolean;

type
  TForm1 = class(TForm)

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
      Edit3: TEdit;
      CheckBox3: TCheckBox;
      Button4: TButton;
      CnSpinEdit1: TCnSpinEdit;
      editN1: TEdit;
      EditN2: TEdit;

    PanelLogin: SE_panel;
      lbl_username: TLabel;
      lbl_Password: TLabel;
      Edit1: TEdit;
      Edit2: TEdit;
      FolderDialog1: TFolderDialog;
      btnLogin: TcnSpeedButton;
      btnReplay: TcnSpeedButton;
      lbl_ConnectionStatus: TLabel;

    PanelError: SE_panel;
      lbl_Error: TLabel;
      BtnErrorOK: TCnSpeedButton;

    mainThread: SE_ThreadTimer;
    ThreadCurMove: SE_ThreadTimer;
    Timer1: TTimer;

    tcp: TWSocket;
    Label1: TLabel;
    Button5: TButton;

    SE_players: SE_Engine;
    SE_ball: SE_Engine;
    SE_numbers: SE_Engine;
    SE_interface: SE_Engine;
    SE_FieldPoints: SE_Engine;
    SE_BackGround: SE_Engine;
    SE_FieldPointsReserve: SE_Engine;
    SE_ShotCells: SE_Engine;
    SE_FieldPointsSpecial: SE_Engine;
    SE_MainInterface: SE_Engine;
    SE_PlayerDetails: SE_Engine;
    SE_Aml: SE_Engine;
    SE_Market: SE_Engine;
    SE_Score: SE_Engine;
    SE_Live: SE_Engine;
    SE_CountryTeam: SE_Engine;
    SE_Skills: SE_Engine;
    SE_Uniform: SE_Engine;
    SE_TacticsSubs: SE_Engine;
    SE_MainStats: SE_Engine;
    SE_Loading: SE_Engine;
    SE_Spectator: SE_Engine;
    SE_LifeSpan: SE_Engine;
    SE_FieldPointsOut: SE_Engine;

    PanelSell: SE_Panel;
      btnConfirmSell: TCnSpeedButton;
      edtSell: TEdit;
      BtnBackSell: TCnSpeedButton;
    ToolSpin: TCnSpinEdit;
      BtnExit: TCnSpeedButton;
    PanelDismiss: SE_Panel;
      BtnConfirmDismiss: TCnSpeedButton;
      BtnBackDismiss: TCnSpeedButton;
      lbl_Dismiss: TLabel;
    PanelBuy: SE_Panel;
      btnConfirmBuy: TCnSpeedButton;
      BtnBackBuy: TCnSpeedButton;
      lbl_ConfirmBuy: TLabel;
    SE_Green: SE_Engine;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    CheckBox9: TCheckBox;
    SE_RANK: SE_Engine;
    Button9: TButton;
    PanelGameOver: SE_Panel;
    lbl_Gameover1: TLabel;
    btnGameOverOK: TCnSpeedButton;
    lbl_GameOver2: TLabel;
    lbl_GameOver3: TLabel;
    Image1: TImage;
    SE_GameOver: SE_Engine;

// General

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnErrorOKClick(Sender: TObject);
    procedure BtnLoginClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

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
    procedure Button3Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Edit2KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

// Mouse on Theater
    procedure SE_Theater1TheaterMouseDown(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Button: TMouseButton;
      Shift: TShiftState);
    procedure SE_Theater1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SE_Theater1SpriteMouseMove(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Shift: TShiftState; Var Handled: boolean);
    procedure SE_Theater1SpriteMouseDown(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton; Shift: TShiftState);
      procedure ScreenFormation_SE_Players ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
        function CreateSurnameSubSprite (aPlayer: TSoccerPlayer): SE_Bitmap;

      procedure ScreenFormation_SE_MainInterface ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenFormation_SE_Uniform ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenPlayerDetails_SE_PlayerDetails ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenAML_SE_AML ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenMarket_SE_Market ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenSelectCountryTeam_SE_CountryTeam ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenSpectator_SE_Spectator ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenWaitingLive_SE_Loading ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenLive_SE_Skills ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );

      procedure ScreenLive_SE_GameOver ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenSpectator_SE_GameOver ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );

      procedure ScreenLive_SE_Green ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenLive_SE_Players ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenLive_SE_FieldPoints ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );

      procedure ScreenLive_SE_LIVE ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenTacticsSubs_SE_TacticsSubs ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
      procedure ScreenTacticsSubs_SE_Players ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );

      procedure ScreenFreeKick_SE_Players ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );

    procedure SE_Theater1SpriteMouseUp(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton; Shift: TShiftState);
    procedure SE_Theater1TheaterMouseMove(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Shift: TShiftState);
    procedure SE_ballSpriteDestinationReached(ASprite: SE_Sprite);
    procedure SE_Theater1TheaterMouseUp(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Button: TMouseButton; Shift: TShiftState);

// Mouse movement sulla SE_GridSkill
    procedure PrsMouseEnter;
    procedure PosMouseEnter;

    Function Translate ( aString : string  ): String;
    procedure ShowLevelUpT ( TS: string);
    procedure ShowLevelUpA ( TS: string );
    procedure ShowError ( AString: string);
    procedure ShowInfo ( AString: string);
    procedure ShowGameOver( MoneyStarVisible: Boolean ) ;
    procedure FocusMarketPlayer ( aSprite: SE_Sprite);

    procedure SetBallRotation ( X1,Y1,X2,Y2: integer ) ;
// replay
    procedure btnReplayClick(Sender: TObject);
    procedure ToolSpinChange(Sender: TObject);
    procedure toolSpinKeyPress(Sender: TObject; var Key: Char);


// Combat Log
    procedure ClearInterface;

    procedure RenewUniform ( ha: Integer );
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Button5Click(Sender: TObject);
    procedure btnConfirmSellClick(Sender: TObject);
    procedure BtnBackSellClick(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure BtnConfirmDismissClick(Sender: TObject);
    procedure BtnBackDismissClick(Sender: TObject);
    procedure BtnBackBuyClick(Sender: TObject);
    procedure btnConfirmBuyClick(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure CheckBox5Click(Sender: TObject);
    procedure CheckBox6Click(Sender: TObject);
    procedure CheckBox7Click(Sender: TObject);
    procedure CheckBox8Click(Sender: TObject);
    procedure CheckBox9Click(Sender: TObject);
    procedure SE_ballSpritePartialMove(ASprite: SE_Sprite; Partial: Byte);
    procedure Button9Click(Sender: TObject);

  private
    { Private declarations }
    fSelectedPlayer : TSoccerPlayer;
    procedure ShowFace ( aPlayer: TSoccerPlayer );
    procedure AddFace ( aPlayer: TSoccerPlayer );
    procedure SetSelectedPlayer ( aPlayer: TSoccerPlayer);
    function FieldGuid2Cell (guid:string): Tpoint;

    procedure ArrowShowShpIntercept( CellX, CellY : Integer; ToEmptyCell: boolean);
    procedure ArrowShowMoveAutoTackle( CellX, CellY : Integer);
    procedure ArrowShowLopheading(CellX, CellY : Integer; ToEmptyCell: boolean);
    procedure ArrowShowCrossingHeading( CellX, CellY : Integer) ;
    procedure ArrowShowDribbling( anOpponent: TSoccerPlayer; CellX, CellY : Integer);
    procedure hidechances ;
    procedure ShowGreen ( CellX,CellY:Integer);
    // Score
    procedure i_Tml ( MovesLeft,team: string );  // animazione internal mosse rimaste
    procedure i_tuc ( team: string );          // animazione internal turn change
    procedure RefreshTML;
    procedure RefreshTML_direct (TeamMovesLeft, Team, ShpFree : integer ) ;
    procedure Refresh_teamnames;
    procedure SetTmlAlpha;
    procedure i_red ( ids: string );           // animazione internal red card (espulsione)
    procedure i_Yellow ( ids: string );        // animazione internal yellow card (ammonizione)
    procedure i_Injured ( ids: string );       // animazione internal infortunio

    // interface
    procedure CreateSplash (x,y,w,h: Integer; aString: string; msLifespan, FontSize: integer; FontColor,BackColor: TColor; Transparent: boolean) ;
    procedure RemoveChancesAndInfo  ;
    procedure CornerSetBall;
    procedure PenaltySetBall;
    procedure CornerSetPlayer ( aPlayer: TsoccerPlayer);
    procedure PenaltySetPlayer ( aPlayer: TsoccerPlayer);
    procedure Logmemo ( ScriptLine : string );

    // highlight field cell
    procedure HHFP_GK;
    procedure HideFP_GK;
    procedure HHFP_Special (CellX, CellY, LifeSpan : integer  );
    procedure HHFP ( CellX, CellY, LifeSpan : integer );
    procedure HHFP_Friendly ( aPlayer: TSoccerPlayer; cells: char );
    procedure HideFP_Friendly;
    procedure HideFP_Special;
    procedure HHFP_Reserve ( aPlayer: TSoccerPlayer );
    procedure HideFP_Reserve;
    procedure HideFP_Friendly_ALL;

    // Animation
    procedure ClientLoadBrainMM ( incMove: Byte) ;  // carica il brain e lo script
    function ClientLoadScript ( incMove: Byte) : Integer;               // riempe TAnimationScript
    procedure Anim ( Script: string );                                  // esegue TAnimationScript
      procedure AnimCommon ( Cmd:string);
    procedure PrepareAnim;
    procedure SpriteReset ;
    procedure UpdateSubSprites;
    procedure MoveInReserves ( aPlayer: TSoccerPlayer );             // mette uno sprite player nelle riserve
    procedure MoveInField ( aPlayer: TSoccerPlayer );                // mette uno sprite player in campo

    procedure CancelDrag(aPlayer: TsoccerPlayer; ResetCellX, ResetCellY: integer ); // anulla il dragdrop dello sprite
    procedure FirstShowRoll;

    procedure SelectedPlayerPopupSkill ( CellX, CellY: integer);
    procedure HideHH_Skill ;
    procedure HH_Skill ( SkillMouseMove: string );

    procedure RoundBorder (bmp: TBitmap);

    // check ball position
    function inGolPosition ( PixelPosition: Tpoint ): Boolean;
    function inCrossBarPosition ( PixelPosition: Tpoint ): Boolean;
    function inGKCenterPosition ( PixelPosition: Tpoint ): Boolean;

    function isTvCellFormation ( Team, CellX, CellY: integer ): boolean;
    procedure LoadTranslations ;

    function Capitalize ( aString : string  ): String;

    procedure CreatePopupSkill; // obsolete
    // Screen init
    procedure LoadAllGraphic;
      procedure LoadBackgrounds;
      procedure LoadDoors;
      procedure LoadCountryTeam;
      procedure LoadMainInterface;
      procedure LoadMainStats;
      procedure LoadPlayerDetails;
      procedure LoadLogin;
      procedure LoadUniform;
      procedure LoadMarket;
      procedure LoadAml;
      procedure LoadSpectator;
      procedure LoadScore;
      procedure LoadLive;
      procedure LoadGreen;
      procedure LoadTacticsSubs;


      procedure ClientLoadMarket;
      procedure ClientLoadAML;
      procedure ClientLoadCountries ( index: Integer);
      procedure ClientLoadTeams ( index: Integer);
      procedure ClientLoadMatchInfo;  // dinamico. rimuove e ricrea sprites. Troppe informazioni. Fa uso di SE_score
      procedure ShowLoading;

    procedure CreateFieldPoints;
    procedure ShowMainStats( aPlayer: TSoccerPlayer );
    procedure ShowPlayerDetails ( aPlayer: TSoccerPlayer );
    procedure HideStadiumAndPlayers;
    procedure ShowStadiumAndPlayers( Stadium : integer )  ;



    procedure ClientLoadFormation ;
      procedure PreloadUniform(ha:Byte;   UniformSchemaIndex: integer);
      procedure PreloadUniformGK(ha:Byte;  UniformSchemaIndex: integer);
      function DarkColor(aColor: TColor): TColor;
      function softlight(aColor: TColor): TColor;
      function i_softlight(ib, ia: integer): integer;

    function GetAttributeColor ( value: integer  ): TColor;
    function GetAttributeColorSpeed ( value: integer  ): TColor;
    function GetXLabel ( bmp: TBitmap; aString: String; FrameWidth: integer; StringAlignment : TStringAlignment ): Integer;

      procedure ColorizeFault( Team:Byte;  var FaultBitmap: SE_Bitmap);
      procedure ColorizeArrowCircle( Team:Byte;   ShapeBitmap: SE_Bitmap);

    function RndGenerate( Upper: integer ): integer;
    function RndGenerate0( Upper: integer ): integer;
    function RndGenerateRange( Lower, Upper: integer ): integer;

    function findlstSkill (SkillName: string ): integer;
    function findPlayerMyBrainFormation ( guid: string ): TSoccerPlayer;
    function CheckFormationTeamMemory : Boolean; // in memoria mybrainformation lstsoccerplayer.formationcellX
      procedure RefreshCheckFormationMemory;
      procedure FixDuplicateFormationMemory;

    procedure SetGlobalCursor ( aCursor: Tcursor);

    procedure CreateArrowDirection ( Player1 , Player2: TSoccerPlayer ); overload;
    procedure CreateArrowDirection ( Player1 : TSoccerPlayer;  CellX, CellY: integer ); overload;
    procedure CreateCircle(  Player : TSoccerPlayer  ); overload;
    procedure CreateCircle(  Team,  CellX, CellY: integer  );overload;
    procedure CreateBaseAttribute ( CellX, CellY, Value: Integer );

    procedure SetGameScreen (const aGameScreen:TGameScreen);

    procedure GetTooltipStrings ( bmp: TBitmap; aString: string; var ts: Tstringlist );

  public
    { Public declarations }
    aInfoPlayer: TSoccerPlayer;
    fGameScreen: TGameScreen;
    MouseWaitFor : TMouseWaitFor;
    SendString: string;
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
  MutexAnimation : Cardinal;
  oldCellXMouseMove, oldCellYMouseMove: Integer;
  MyBrain: TSoccerBrain;
  MyBrainFormation: TSoccerBrain;
  RandGen: TtdBasePRNG;
  GCD: Integer; // global cooldown temporaneo per braininput
  dir_log, dir_tmp, dir_stadium, dir_ball, dir_player, dir_interface, dir_skill, dir_data, dir_sound, dir_attributes, dir_help, dir_talent: string;
  LastSpriteMouseMoveGuid,Language:string;
  lastMouseMovePlayer:TSoccerPlayer;
  WAITING_GETFORMATION, WAITING_STOREFORMATION: boolean;

  // il client si mette in attesa di una rispoosta dal server:



  DontDoPlayers: Boolean; // non accetta click sui player
  oldVisualCmd: string;

  TranslateMessages : TStringList;
  TalentEditing : boolean;
  AnimationScript : TAnimationScript;
  BIndex: Integer;
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
  MyActiveGender : string;
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



  FieldPoints : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsReserve : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsCorner : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsPenalty : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsCrossBar : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsGol : TObjectList<TFieldPoint>; // 8 risoluzioni video
  FieldPointsOut : TObjectList<TFieldPoint>; // 8 risoluzioni video



  // coordinate subsprites e labels del mainstats.bmp
  CoordsMainStatsNameCenterX: Integer;
  CoordsMainStatsName,CoordsMainStatsFace : TPoint;
  CoordsMainStatsSpeedlbl,CoordsMainStatsDefenselbl,CoordsMainStatsPassinglbl, CoordsMainStatsBallControllbl, CoordsMainStatsShotlbl, CoordsMainStatsHeadinglbl: TPoint;
  CoordsMainStatsSpeed,CoordsMainStatsDefense,CoordsMainStatsPassing, CoordsMainStatsBallControl, CoordsMainStatsShot, CoordsMainStatsHeading: TPoint;
  CoordsMainStatsTalent1Spr,CoordsMainStatsTalent2Spr,CoordsMainStatsStaminaSpr,CoordsMainStatsStaminaBar : TPoint;


  CoordsBtnMenu, CoordsBtnTactics : TPoint;

  CoordsBtnSellMarket: TPoint;

  IndexCT : Integer;
  TsColors : TStringList;
  CrossBarN : array [0..2] of Integer;
  FormationChanged: Boolean;
  overridecolor: Boolean;

  BarrierPosition : array [0..3] of TPoint;
  GBIndex : integer;
  SwapPlayerBarrierDone: Boolean;

  PopupSkill : array [0..1,0..8] of TPoint; // menu skill a comparsa round attorno al player    // obsolete
  StarFontColor : array [1..6] of TColor;

  procedure RoundCornerOf(Control: TWinControl) ;
implementation

{$R *.dfm}

uses Unit3;
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

procedure TForm1.BtnExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.BtnLoginClick(Sender: TObject);
var
  ini : TIniFile;
begin
  if GCD <= 0 then begin
    PanelLogin.Visible := False;
    ShowLoading;
    tcp.SendStr( 'login,'+Edit1.text +',' + Edit2.text + EndofLine);
    ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'client.ini');
    ini.WriteString('lastlogin', 'username', Edit1.text);
    ini.WriteString('lastlogin', 'pwd',Edit2.text);
    ini.Free;

    GCD := GCD_DEFAULT;
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
      MyActiveGender :=  'f';   { TODO : fix }

      SE_players.RemoveAllSprites;
      GameScreen := ScreenSpectator ;
      MM3[0].LoadFromFile( FolderDialog1.Directory   + '\' + sf.ListFiles[0]);
      CopyMemory( @Buf3[0], MM3[0].Memory, MM3[0].size  );
      ClientLoadBrainMM ( 0 ); // sempre true durante replay
      SE_players.ProcessSprites(2000); //<-- forza l'inserimento in lstsprites da lstnewsprite o dopo il remove non li troverà
      CurrentIncMove :=  0;
      ClientLoadScript( 0 );
      if Mybrain.tsScript.Count = 0 then begin
        ClientLoadBrainMM ( 0  ); // sempre true durante replay
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
   ClientLoadBrainMM ( trunc( CnSpinEdit1.Value - 1) );
  CurrentIncMove :=  trunc( CnSpinEdit1.Value);
  ClientLoadScript( trunc( CnSpinEdit1.Value)  );
  if Mybrain.tsScript.Count = 0 then begin
    ClientLoadBrainMM ( trunc( CnSpinEdit1.Value) );
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
  aPoint : TPoint;
  bmp: SE_Bitmap;
  aSprite,aFieldPoint: SE_Sprite;
begin
  {$ifdef tools}

  if GameScreen <> ScreenLive  then Exit;


    SE_ShotCells.RemoveAllSprites;

    bmp:= SE_Bitmap.Create (32,32);
    bmp.Bitmap.Canvas.Brush.Color := clRed;
    bmp.Bitmap.Canvas.Ellipse(0,0,32,32);
    for i:= 0 to ShotCells.Count -1 do begin
          if (ShotCells[i].DoorTeam <> SelectedPlayer.Team) and
            (ShotCells[i].CellX = SelectedPlayer.CellX) and (ShotCells[i].CellY = SelectedPlayer.CellY) then begin
          // sono sopra questa shotcell
          // tra le celle adiacenti, solo la X attuale e ciclo per le Y
           //   aShotCell := brain.ShotCells[I];

          for c := 0 to  ShotCells[i].subCell.Count -1 do begin
            aPoint := ShotCells[i].subCell.Items [c];
            aFieldPoint := SE_FieldPoints.FindSprite(IntToStr (aPoint.X ) + '.' + IntToStr (aPoint.Y ));

            aSprite := SE_ShotCells.CreateSprite  ( bmp.Bitmap , 'shotcell'+inttostr(c),1,1,100, aFieldPoint.Position.X ,aFieldPoint.Position.Y,true);
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
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr(  'setturn,' + EditN2.Text +  EndofLine  );
    GCD := GCD_DEFAULT;
  end;
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
  apoint :TPoint;
  aShortPoint :TShortPoint;
begin

{  apoint.X:=8;
  apoint.Y:=9;

  ashortpoint.X:=8;
  ashortpoint.Y:=9;

  if apoint.x < 0 then
    caption:='ciao';
  if aShortpoint.x < 0 then
    caption:='ciao';   }

  BarrierPosition [0] := Point(-24,-24 );
  BarrierPosition [1] := Point(-24,+24 );
  BarrierPosition [2] := Point(+24,-24 );
  BarrierPosition [3] := Point(+24,+24 );

  FormatSettings.CurrencyString := '';
  FormatSettings.ThousandSeparator := '.';

  TsColors := TStringList.create;
  TsColors.CommaText := '16777214,1,8421503,254,4227325,65535,32768,65281,16776960,16711681,16711808,16744703,128';

  // deve essere ubgual a quella del server formcreate
  Createshotcells;
	TVCreateCrossingAreaCells;
	AICreateCrossingAreaCells;

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
  MyBrain := TSoccerBrain.Create('m') ;
  createAIfield; // serve per i cross ad esempio inshotcell
  MyBrain.incMove := 0; // +1 nella ricerca .ini

  MutexAnimation:=CreateMutex(nil,false,'tsscript');

  //SE_GridCountryTeam.Active := false;


  Panel1.Visible := False;

  {$ifdef tools}
  btnReplay.Visible := True;
  //ToolSpin.Visible := True;

  Panel1.Visible := False;
  Panel1.BringToFront;

  {$endif tools}
  TsUniforms[0]:= Tstringlist.create;
  TsUniforms[1]:= Tstringlist.create;

  for I := 0 to 255 do begin
    MM3[i]:= TMemoryStream.Create;
  end;

  CurrentIncMove := 0;
  lstInteractivePlayers:= TList<TInteractivePlayer>.create;

  FormatSettings.DecimalSeparator := '.';
  RandGen := TtdCombinedPRNG.Create(0, 0);
  //MyBrainFormation:= TSoccerBrain.Create ('m');

  GCD:= 0;


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

  btnConfirmSell.Caption := Translate('lbl_Confirm');
  btnBackSell.Caption := Translate('lbl_Back');
  btnConfirmDismiss.Caption := Translate('lbl_Confirm');
  btnBackDismiss.Caption := Translate('lbl_Back');
  lbl_Dismiss.Caption := Translate('lbl_ConfirmDismiss');
  btnConfirmBuy.Caption := Translate('lbl_Confirm');
  btnBackBuy.Caption := Translate('lbl_Back');
  lbl_ConfirmBuy.Caption := Translate('lbl_ConfirmBuy');

  btnLogin.Caption := Translate('lbl_Login');
  btnExit.Caption := Translate('lbl_Exit');


  UniformBitmapBW := SE_Bitmap.Create (dir_player + 'bw.bmp');
  InOutBitmap := SE_Bitmap.Create (dir_interface + 'inout.bmp');
  InOutBitmap.Stretch( 40,40 );


  TsWorldCountries:= TStringList.Create;
  TsNationTeams:= TStringList.Create;
  TsWorldCountries.StrictDelimiter := True;
  TsNationTeams.StrictDelimiter := True;


  DeleteDirData;

  CreatePopupSkill;

  Timer1Timer(Timer1);
  Timer1.Enabled := True;
  LoadAllGraphic;
  GameScreen := ScreenLogin;



  RoundCornerOf ( PanelLogin );
  RoundCornerOf ( PanelError );
  RoundCornerOf ( PanelGameOver );

  Panel1.Left := 0;

end;
procedure TForm1.FormDestroy(Sender: TObject);
var
  i: integer;
begin
  for I := 255 downto 0 do begin
    MM3[i].Free;
  end;

  //ShotCells.free;
  if Mybrain <> nil then begin
    MyBrain.free;
  end;
  MybrainFormation := nil ;
  TsColors.Free;
  FieldPoints.Free;
  FieldPointsReserve.Free;
  FieldPointsCorner.Free;
  FieldPointsPenalty.Free;
  FieldPointsCrossBar.Free;
  FieldPointsGol.Free;
  FieldPointsOut.Free;

  FaultBitmapBW.Free;
  UniformBitmapBW.Free;
  tsUniforms[1].Free;
  tsUniforms[0].Free;

  lstInteractivePlayers.Free;
  RandGen.free;

  se_players.RemoveAllSprites ;
  se_ball.RemoveAllSprites ;
  se_interface.RemoveAllSprites ;
  se_ShotCells.RemoveAllSprites ;
  se_numbers.RemoveAllSprites ;
  se_FieldPoints.RemoveAllSprites ;

  TsCoa.free;
  TsCod.free;

  AnimAtionScript.Reset;
  AnimationScript.Ts.Free;
  AnimationScript.Free;
  TranslateMessages.Free;
  TsWorldCountries.Free;
  TsNationTeams.Free;

  CloseHandle(MutexAnimation);
//  If MyBrainFormation <> nil then MyBrainFormation.free;
end;
procedure TForm1.CreatePopupSkill;
begin
  PopupSkill[0,0] := Point(32,26);
  PopupSkill[0,1] := Point(4,40);
  PopupSkill[0,2] := Point(-24,40);
  PopupSkill[0,3] := Point(-52,26);
  PopupSkill[0,4] := Point(-52,0);
  PopupSkill[0,5] := Point(-52,-26);
  PopupSkill[0,6] := Point(-24,-40);
  PopupSkill[0,7] := Point(4,-40);
  PopupSkill[0,8] := Point(32,-26);

  PopupSkill[1,0] := Point(32,12);
  PopupSkill[1,1] := Point(24,18);
  PopupSkill[1,2] := Point(18,24);
  PopupSkill[1,3] := Point(12,0);
  PopupSkill[1,4] := Point(-12,0);
  PopupSkill[1,5] := Point(-18,-24);
  PopupSkill[1,6] := Point(-24,-18);
  PopupSkill[1,7] := Point(-32,-12);
  PopupSkill[1,8] := Point(-32,-12);

end;

procedure TForm1.LoadLogin;
begin

  PanelLogin.Left := (SE_Theater1.Width div 2) - (PanelLogin.Width div 2);
  PanelLogin.Top := (SE_Theater1.Height div 2) - (PanelLogin.Height div 2);
end;
procedure TForm1.LoadAml;
var
  bmp: SE_Bitmap;
  aSprite,aTvSprite, aBtnSprite: SE_Sprite;
  aSpriteLabel: SE_SpriteLabel;
  i,BaseY: Integer;
  const YOffset = 34; FontSize = 14; W=32; H=32;
begin
  aSprite:= SE_BackGround.FindSprite('backgroundaml');
  aSprite.Visible := True;
  // Vengono mostrate 20 partite circa con un pulsante Refresh
  // la bandiere sono subsprites.
  // l'icone Tv è l'unico sprite vero indipendente che riceve un click
  BaseY := 100;
  for I := 0 to 19 do begin
    bmp := SE_Bitmap.Create ( 1300,H );
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
    aSprite:=SE_Aml.CreateSprite(bmp.Bitmap ,'match'+IntToStr(i) ,1,1,1000,720,BaseY,false );
    aSprite.Priority := 2;
    bmp.Free;
    aSprite.Alpha := 230;
    aSprite.BlendMode := SE_BlendAlpha;

    aSpriteLabel := SE_SpriteLabel.create( XUsername0,LY,'Calibri',clBlack,clBlack,FontSize,'',True  ); // username 0
    aSprite.Labels.Add(aSpriteLabel);
    // qui bandiera sprite 0

    bmp := SE_Bitmap.Create ( 40,H ); // la bandiere sono stretchate 40 x 32
    aSprite.AddSubSprite( bmp,'f0',XFlag0,0,false );
    bmp.Free;

    aSpriteLabel := SE_SpriteLabel.create( XTeamName0,LY,'Calibri',clBlack,clBlack,FontSize,'',True  ); // teamname 0
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XScore,LY,'Calibri',clBlack,clBlack,FontSize,'',True  ); // risultato gol-gol
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XTeamName1,LY,'Calibri',clBlack,clBlack,FontSize,'',True  ); // teamname 1
    aSprite.Labels.Add(aSpriteLabel);
    // qui bandiera sprite 1
    bmp := SE_Bitmap.Create ( 40,H ); // la bandiere sono 30 x 22
    aSprite.AddSubSprite(bmp,'f1',XFlag1,0,false);
    bmp.Free;

    aSpriteLabel := SE_SpriteLabel.create( XUsername1,LY,'Calibri',clBlack,clBlack,FontSize,'',True  ); // username 1
    aSprite.Labels.Add(aSpriteLabel);
    // qui icona tv
    aTvSprite := SE_Aml.CreateSprite(dir_interface + 'tv.bmp' ,'tv'+IntToStr(i) ,1,1,1000,XTv,BaseY,false );
    aTvSprite.Priority := 3;

    aSpriteLabel := SE_SpriteLabel.create( XMinute,LY,'Calibri',clBlack,clBlack,FontSize,'',True  ); // minuto
    aSprite.Labels.Add(aSpriteLabel);
    BaseY := BaseY + YOffset;
  end;

// menu button
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp');
  aBtnSprite:=SE_AML.CreateSprite(bmp.Bitmap ,'btnmenu_back',1,1,1000,100,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Back') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'arrowl.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_AML.CreateSprite(bmp.Bitmap ,'btnmenu_refresh',1,1,1000,720,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Refresh') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'refresh.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  bmp.Free;
end;
procedure TForm1.LoadMarket;
var
  bmp: SE_Bitmap;
  aSprite, aBuySprite, aBtnSprite : SE_Sprite;
  aSpriteLabel: SE_SpriteLabel;
  i,BaseY,X: Integer;
  const YOffset = 34; FontSize = 14; W=32; H=32;
begin
//format('Number           = %n', [12345.678]));
  aSprite:= SE_BackGround.FindSprite('backgroundmarket');
  aSprite.Visible := True;
  // Vengono mostrate 20 player sul mercato circa con un pulsante Refresh
  // i talenti sono subsprites.
  // il pulante BUY l'unico sprite vero indipendente che riceve un click
  // qui c'è uno sprite di lableColumns
  BaseY := 100;
  bmp := SE_Bitmap.Create ( 1364,H );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlue;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aSprite:=SE_Market.CreateSprite(bmp.Bitmap ,'columns',1,1,1000,720,BaseY-h,false );
  aSprite.Priority := 2;
  aSprite.Alpha := 230;
  aSprite.BlendMode := SE_BlendAlpha;


  aSprite.BMP.Canvas.Font.Name := 'Calibri';
  aSprite.BMP.Canvas.Font.Size := FontSizeMArket;

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('lbl_Surname')),WSurname, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XSurname+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('lbl_Surname')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('lbl_Price')),WPrice, TStringRight );
  aSpriteLabel := SE_SpriteLabel.create( XPrice+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('lbl_Price')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('attribute_Fitness')),WFitness, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XFitness+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('attribute_Fitness')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('attribute_Speed')),WSpeed, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XSpeed+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('attribute_Speed')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('attribute_Defense')),WDefense, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XDefense+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('attribute_Defense')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('attribute_Passing')),WPassing, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XPassing+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('attribute_Passing')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('attribute_Ball.Control')),WBallControl, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XBallControl+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('attribute_Ball.Control')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('attribute_Shot')),WShot, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XShot+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('attribute_Shot')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('attribute_Heading')),WHeading, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XHeading+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('attribute_Heading')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('lbl_Talents')),WPrice, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XTalents+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('lbl_Talents')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('lbl_Age')),WAge, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XAge+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('lbl_Age')),True  );
  aSprite.Labels.Add(aSpriteLabel);

  X :=GetXLabel ( aSprite.BMP.bitmap,Capitalize(Translate('lbl_MatchesLeft2')),WMatchsLeft, TStringCenter );
  aSpriteLabel := SE_SpriteLabel.create( XMatchsLeft+X,LY,'Calibri',clWhite,clBlack,FontSize,Capitalize(Translate('lbl_MatchesLeft2')),True  );
  aSprite.Labels.Add(aSpriteLabel);
  bmp.Free;

  // Lx è dinamico, settato in ClientLoadMarket
  BaseY := BaseY +2;
  for I := 0 to 19 do begin
    bmp := SE_Bitmap.Create ( 1364,H );
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
    aSprite:=SE_Market.CreateSprite(bmp.Bitmap ,'market'+IntToStr(i) ,1,1,1000,720,BaseY,false );
    aSprite.Priority := 2;
    bmp.Free;
    aSprite.Alpha := 230;
    aSprite.BlendMode := SE_BlendAlpha;

    aSpriteLabel := SE_SpriteLabel.create( XSurname,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XPrice,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XSpeed,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XDefense,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XPassing,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XBallControl,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XShot,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XHeading,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XAge,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);
    aSpriteLabel := SE_SpriteLabel.create( XMatchsLeft,LY,'Calibri',clWhite,clBlack,FontSize,'',True  );
    aSprite.Labels.Add(aSpriteLabel);

    // li creo dinamicamente in clientloadmarket
    // country nazionalità
    // face
    // fitness
    // i 2 talenti subsprites li creo dinamicamente

    BaseY := BaseY + YOffset;
  end;

// menu button
  aBtnSprite:=SE_Market.CreateSprite(dir_interface + 'button.bmp' ,'btnmenu_back',1,1,1000,90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Back') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'arrowl.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_Market.CreateSprite(dir_interface + 'button.bmp' ,'btnmenu_refresh',1,1,1000,720,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Refresh') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite( dir_interface +'refresh.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  aSprite := SE_Market.CreateSprite(dir_interface + 'money.bmp','gold', 1,1,1000,260,YMAINBUTTON,true);
  bmp := SE_Bitmap.Create (300,22);
  bmp.Bitmap.Canvas.Brush.Color :=  clGray;
  bmp.Bitmap.Canvas.FillRect(Rect( 0,0,bmp.Width,bmp.Height));
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,14,FloatToStrF(Money, ffCurrency, 10, 0) ,True  );// money qui è 0.
  aSprite := SE_Market.CreateSprite(bmp.bitmap,'money', 1,1,1000,450,YMAINBUTTON,true);
  aSprite.Labels.Add(aSpriteLabel);
  bmp.Free;



end;
procedure TForm1.LoadUniform;
var
  i,BaseX,BaseY: Integer;
  bmp: SE_Bitmap;
  aSprite, aBtnSprite,aBarSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
  Const FontSize = 14;
begin
  aSprite:=SE_Uniform.CreateSprite(dir_interface + 'bguniform.bmp' ,'frameback',1,1,1000,300,0 ,false );
  aSprite.PositionY := 900-(112+(aSprite.bmp.Height div 2));
  aSprite.Priority := 1;

  aBtnSprite:=SE_Uniform.CreateSprite(dir_interface + 'home2.bmp' ,'btn_uniformhome',1,1,1000,145,620,true );
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 255;
  aBtnSprite.Priority := 2;
//  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Home'),True  );
//  aBtnSprite.Labels.Add(aSpriteLabel);

  aBtnSprite:=SE_Uniform.CreateSprite(dir_interface + 'away.bmp' ,'btn_uniformaway',1,1,1000,225,620,true );
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 80;
  aBtnSprite.Priority := 2;
//  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Away'),true  );
// aBtnSprite.Labels.Add(aSpriteLabel);

  aBtnSprite:=SE_Uniform.CreateSprite(dir_interface + 'jersey1.bmp' ,'btn_Jersey1',1,1,1000,340,620,true );
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 255;
  aBtnSprite.Priority := 2;
//  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Jersey')+' 1',True  );
//  aBtnSprite.Labels.Add(aSpriteLabel);

  aBtnSprite:=SE_Uniform.CreateSprite(dir_interface + 'jersey2.bmp' ,'btn_Jersey2',1,1,1000,400,620,true );
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 80;
  aBtnSprite.Priority := 2;
//  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Jersey')+' 2',True  );
//  aBtnSprite.Labels.Add(aSpriteLabel);

  aBtnSprite:=SE_Uniform.CreateSprite(dir_interface + 'shorts.bmp' ,'btn_Shorts',1,1,1000,460,625,true );
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 80;
  aBtnSprite.Priority := 2;
//  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Shorts'),True  );
//  aBtnSprite.Labels.Add(aSpriteLabel);

  aBtnSprite:=SE_Uniform.CreateSprite(dir_player + 'schema0.bmp' ,'btn_schema0',1,1,1000,170,746,true );
  aBtnSprite.sTag := '0';
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 80;
  aBtnSprite.Priority := 2;

  aBtnSprite:=SE_Uniform.CreateSprite(dir_player + 'schema1.bmp' ,'btn_schema1',1,1,1000,250,746,true );
  aBtnSprite.sTag := '1';
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 80;
  aBtnSprite.Priority := 2;

  aBtnSprite:=SE_Uniform.CreateSprite(dir_player + 'schema2.bmp' ,'btn_schema2',1,1,1000,330,746,true );
  aBtnSprite.sTag := '2';
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 80;
  aBtnSprite.Priority := 2;

  aBtnSprite:=SE_Uniform.CreateSprite(dir_player + 'schema3.bmp' ,'btn_schema3',1,1,1000,410,746,true );
  aBtnSprite.sTag := '3';
  aBtnSprite.BlendMode := SE_BlendAlpha;
  aBtnSprite.Alpha := 80;
  aBtnSprite.Priority := 2;

  BaseX := 150; BaseY:= 680;
  for I := 0 to TsColors.Count -1 do begin
    bmp := SE_Bitmap.Create ( 24, 24 );
    bmp.Bitmap.Canvas.Brush.Color :=  StrToInt( TsColors[i] ) ;
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
    aSprite:=SE_Uniform.CreateSprite(bmp.Bitmap ,'color' + IntToStr(i),1,1,1000,BaseX,BaseY,false );
    aSprite.Priority := 2;
    aSprite.sTag := IntToStr(i);
    bmp.Free;
    BaseX := BaseX + 24;
  end;




  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp');
  aBtnSprite:=SE_Uniform.CreateSprite(bmp.Bitmap ,'btn_uniformclose',1,1,1000,180+90,YMAINBUTTON,true );
  //aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Close') ,true  );
  //aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'arrowl.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 2;
  bmp.Free;


end;
procedure TForm1.LoadScore;
var
  bmp: SE_Bitmap;
  aBtnSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
  pbSprite : SE_SpriteProgressBar;
  Const FontSize = 14;
begin
  bmp := SE_Bitmap.Create ( 46, 22 );
  bmp.Bitmap.Canvas.Brush.Color :=  $800000;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_Score.CreateSprite(bmp.Bitmap ,'scoreminute',1,1,1000,23,11,false );
  aBtnSprite.Priority := 2;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clYellow,clBlack,FontSize,'',True  );
  aBtnSprite.Labels.Add(aSpriteLabel);


  bmp := SE_Bitmap.Create ( 236, 22 );
  bmp.Bitmap.Canvas.Brush.Color :=  $800000;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_Score.CreateSprite(bmp.Bitmap ,'scorenick0',1,1,1000,46+118,11,false );
  aBtnSprite.Priority := 2;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  bmp := SE_Bitmap.Create ( 46, 22 );  // deve essere uno sprite per il mouseover
  bmp.Bitmap.Canvas.Brush.Color :=  $800000;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_Score.CreateSprite(bmp.Bitmap ,'scorescore',1,1,1000,46+236+23,11,false );
  aBtnSprite.Priority := 2;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  bmp := SE_Bitmap.Create ( 236, 22 );
  bmp.Bitmap.Canvas.Brush.Color :=  $800000;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_Score.CreateSprite(bmp.Bitmap ,'scorenick1',1,1,1000,564-118,11,false );
  aBtnSprite.Priority := 2;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  // la progressbar che indica i secondi rimanenti alla fine del turno
  pbSprite := SE_Score.CreateSpriteProgressBar( 'scorebartime',720,830,16+( 44*5) ,22,'Calibri',clWhite,clBlue,clBlack,FontSize,'',0,false );
  pbSprite.Visible := true;
  pbSprite.Priority := 1001;

  // le 2 Spritelabel che indicano il team del turno attuale. In alto e in basso vicino alla progressbar
  bmp := SE_Bitmap.Create ( 236, 22 );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlack;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_Score.CreateSprite(bmp.Bitmap ,'teamname0',1,1,1000,720,830-22,false );
  aBtnSprite.Priority := 2;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  bmp := SE_Bitmap.Create ( 236, 22 );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlack;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_Score.CreateSprite(bmp.Bitmap ,'teamname1',1,1,1000,720,830-22,false );
  aBtnSprite.Priority := 2;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aBtnSprite.Labels.Add(aSpriteLabel);
end;
procedure TForm1.LoadCountryTeam;
var
  bmp: SE_Bitmap;
  aSprite, aBtnSprite: SE_Sprite;
  aSpriteLabel: SE_SpriteLabel;
  i,BaseY: Integer;
  const YOffset = 25; FontSize = 14;
begin
  aSprite:= SE_BackGround.FindSprite('backgroundlogin');
  aSprite.Visible := True;
  // Vengono mostrate 20 nazioni e team circa con un pulsante Refresh
  BaseY := 100;
  for I := 0 to 19 do begin
    bmp := SE_Bitmap.Create ( 1300,22 );
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
    aSprite:=SE_CountryTeam.CreateSprite(bmp.Bitmap ,'countryteam'+IntToStr(i) ,1,1,1000,705,BaseY,false );
    aSprite.Priority := 2;
    bmp.Free;
    aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,'',True  ); // country o team
    aSprite.Labels.Add(aSpriteLabel);

    aSprite:=SE_CountryTeam.CreateSprite( dir_interface + 'select.bmp' ,'ctselect'+IntToStr(i) ,1,1,1000,1260,BaseY,true );
    aSprite.Priority := 3;
    BaseY := BaseY + YOffset;
  end;

// menu button
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp');
  aBtnSprite:=SE_CountryTeam.CreateSprite(bmp.Bitmap ,'btnmenu_back',1,1,1000,100,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Back') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_CountryTeam.CreateSprite(bmp.Bitmap ,'btnmenu_back2',1,1,1000,300,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, '<<' ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_CountryTeam.CreateSprite(bmp.Bitmap ,'btnmenu_back1',1,1,1000,500,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, '<',true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_CountryTeam.CreateSprite(bmp.Bitmap ,'btnmenu_forward1',1,1,1000,700,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, '>', true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_CountryTeam.CreateSprite(bmp.Bitmap ,'btnmenu_forward2',1,1,1000,900,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, '>>' ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;

  bmp.Free;

end;
procedure TForm1.LoadPlayerDetails;
var
  bmp: SE_Bitmap;
  aSprite, aBtnSprite,aBarSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
  pbSprite : SE_SpriteProgressBar;
  BaseY,i : Integer;
  const WGenericInfo = 366;LabelpointsX = 470 ; BarYOffset = 5;  BarYOffsetTalent = 12; LabelX = 280; BarX = 500; BarAttributesW = 300; BarAttributesH=20; BarTalentH= 16; YOffset = 25;
  const  YOffsetTalent = 18;FontSize = 14; FontSizeTalent = 10; AttributeValuesX = 670;
begin

  bmp := SE_Bitmap.Create ( 1010,50 );
  bmp.Bitmap.Canvas.Brush.Color :=  clAqua;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailssurname',1,1,1000,720,140,false );
  aSprite.BlendMode := SE_BlendAverage;
  aSprite.Priority := 2;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( -1,8,'Calibri',clBlack,clBlack,18,'',True  );
  aSprite.Labels.Add(aSpriteLabel);

  bmp := SE_Bitmap.Create ( 1010,80 );
  bmp.Bitmap.Canvas.Brush.Color :=  clgray;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailstooltip',1,1,1000,705,40,true );
  aSprite.Priority := 1;
  bmp.Free;

  bmp := SE_Bitmap.Create ( 100,100 );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailsportrait',1,1,1000,1100,140,true );
  aSprite.Priority := 3;
  bmp.Free;

  // Attributi base  Btn, Progress bar e Text
  BaseY := 185;
 //speed
  bmp := SE_Bitmap.Create ( 120,20 );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlue;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_speed',1,1,1000,LabelX,BaseY,true );
  aBtnSprite.BlendMode := SE_BlendAverage;
  aBtnSprite.Priority := 1000;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('attribute_Speed'),True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  pbSprite := SE_PlayerDetails.CreateSpriteProgressBar( 'bar_speed',BarX,BaseY, BarAttributesW,BarAttributesH,'Calibri',clWhite,clBlue,clBlack,FontSize,'',0,false );
  pbSprite.Visible := False;
  pbSprite.Priority := 1001;

  bmp := SE_Bitmap.Create ( 20,BarAttributesH );
  bmp.Canvas.Brush.Color := clBlack;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailsspeed',1,1,1000,AttributeValuesX ,BaseY,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.Priority := 3;
  bmp.Free;
  BaseY := BaseY + YOffset;

//Defense
  bmp := SE_Bitmap.Create ( 120,20 );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlue;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_defense',1,1,1000,LabelX,BaseY,true );
  aBtnSprite.BlendMode := SE_BlendAverage;
  aBtnSprite.Priority := 1002;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('attribute_Defense'),True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  pbSprite := SE_PlayerDetails.CreateSpriteProgressBar( 'bar_defense',BarX,BaseY, BarAttributesW,BarAttributesH,'Calibri',clWhite,clBlue,clBlack,FontSize,'',0,false );
  pbSprite.Visible := False;
  pbSprite.Priority := 1003;

  bmp := SE_Bitmap.Create ( 20,BarAttributesH );
  bmp.Canvas.Brush.Color := clBlack;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailsdefense',1,1,1000,AttributeValuesX ,BaseY,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.Priority := 3;
  bmp.Free;
  BaseY := BaseY + YOffset;

 //passing
  bmp := SE_Bitmap.Create ( 120,20 );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlue;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_passing',1,1,1000,LabelX,BaseY,true );
  aBtnSprite.BlendMode := SE_BlendAverage;
  aBtnSprite.Priority := 1004;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('attribute_Passing'),True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  pbSprite := SE_PlayerDetails.CreateSpriteProgressBar( 'bar_passing',BarX,BaseY, BarAttributesW,BarAttributesH,'Calibri',clWhite,clBlue,clBlack,FontSize,'',0,false );
  pbSprite.Visible := False;
  pbSprite.Priority := 1005;

  bmp := SE_Bitmap.Create ( 20,BarAttributesH );
  bmp.Canvas.Brush.Color := clBlack;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailspassing',1,1,1000,AttributeValuesX ,BaseY,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.Priority := 3;
  bmp.Free;
  BaseY := BaseY + YOffset;

//ballcontrol
  bmp := SE_Bitmap.Create ( 120,20 );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlue;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_ballcontrol',1,1,1000,LabelX,BaseY,true );
  aBtnSprite.BlendMode := SE_BlendAverage;
  aBtnSprite.Priority := 1006;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('attribute_Ball.Control'),True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  pbSprite := SE_PlayerDetails.CreateSpriteProgressBar( 'bar_ballcontrol',BarX,BaseY, BarAttributesW,BarAttributesH,'Calibri',clWhite,clBlue,clBlack,FontSize,'',0,false );
  pbSprite.Visible := False;
  pbSprite.Priority := 1007;

  bmp := SE_Bitmap.Create ( 20,BarAttributesH );
  bmp.Canvas.Brush.Color := clBlack;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailsballcontrol',1,1,1000,AttributeValuesX ,BaseY,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.Priority := 3;
  bmp.Free;
  BaseY := BaseY + YOffset;

//shot
  bmp := SE_Bitmap.Create ( 120,20 );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlue;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_shot',1,1,1000,LabelX,BaseY,true );
  aBtnSprite.BlendMode := SE_BlendAverage;
  aBtnSprite.Priority := 1008;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('attribute_Shot'),True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  pbSprite := SE_PlayerDetails.CreateSpriteProgressBar( 'bar_shot',BarX,BaseY, BarAttributesW,BarAttributesH,'Calibri',clWhite,clBlue,clBlack,FontSize,'',0,false );
  pbSprite.Visible := False;
  pbSprite.Priority := 1009;

  bmp := SE_Bitmap.Create ( 20,BarAttributesH );
  bmp.Canvas.Brush.Color := clBlack;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailsshot',1,1,1000,AttributeValuesX ,BaseY,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.Priority := 3;
  bmp.Free;
  BaseY := BaseY + YOffset;

//heading
  bmp := SE_Bitmap.Create ( 120,20 );
  bmp.Bitmap.Canvas.Brush.Color :=  clBlue;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_heading',1,1,1000,LabelX,BaseY,true );
  aBtnSprite.BlendMode := SE_BlendAverage;
  aBtnSprite.Priority := 1010;
  bmp.Free;
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('attribute_Heading'),True  );
  aBtnSprite.Labels.Add(aSpriteLabel);

  pbSprite := SE_PlayerDetails.CreateSpriteProgressBar( 'bar_heading',BarX,BaseY, BarAttributesW,BarAttributesH,'Calibri',clWhite,clBlue,clBlack,FontSize,'',0,false );
  pbSprite.Visible := False;
  pbSprite.Priority := 1011;

  bmp := SE_Bitmap.Create ( 20,BarAttributesH );
  bmp.Canvas.Brush.Color := clBlack;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailsheading',1,1,1000,AttributeValuesX ,BaseY,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,0,'Calibri',clWhite,clBlack,FontSize,'',True  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.Priority := 3;
  bmp.Free;
  BaseY := BaseY + YOffset;

  // Talenti
  BaseY := BaseY + YOffsetTalent;

  for I := 1 to NUM_TALENT do begin

    bmp := SE_Bitmap.Create ( 120,BarTalentH );//uguale a NartalentH
    bmp.Bitmap.Canvas.Brush.Style := bsSolid;
    bmp.Bitmap.Canvas.Brush.Color :=  clBlue;// clyellow tutto ok ma con giallino , modifica la bar dopo
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
    aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btntalent_'+ stringTalents[i],1,1,1000,LabelX,BaseY,true );
    aBtnSprite.sTag := IntToStr(I);
    aBtnSprite.BlendMode := SE_BlendAverage;
    aBtnSprite.Priority := 500+i;
    bmp.Free;

    aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSizeTalent,Translate(Capitalize('talent_'+stringTalents[i])),True  );
    aBtnSprite.Labels.Add(aSpriteLabel);


    pbSprite := SE_PlayerDetails.CreateSpriteProgressBar( 'bartalent_'+stringTalents[i],BarX,BaseY, 300,BarTalentH,'Calibri',clWhite,clBlue,clBlack,FontSizeTalent,'',0,false );
    pbSprite.sTag := IntToStr(i);
    pbSprite.Visible := False;
    pbSprite.Priority := 2000+i;


    BaseY := BaseY + YOffsetTalent;
  end;

//Menu button
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp' );
  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btnmenu_back',1,1,1000,90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Back') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'arrowl.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btnmenu_sell',1,1,1000,180+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Sell'),true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.Priority := 1200;
  // Panel Sell e Dismiss
  PanelSell.left := aBtnSprite.Position.X + (aBtnSprite.BMPCurrentFrame.Width div 2);
  PanelSell.Top := aBtnSprite.Position.Y - (aBtnSprite.BMPCurrentFrame.Height div 2);

  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btnmenu_cancelsell',1,1,1000,(180*2)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_CancelSell'),true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btnmenu_dismiss',1,1,1000,(180*3)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Dismiss'),true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.Priority := 1200;
  // Panel Sell e Dismiss
  PanelDismiss.left := aBtnSprite.Position.X + (aBtnSprite.BMPCurrentFrame.Width div 2);
  PanelDismiss.Top := aBtnSprite.Position.Y - (aBtnSprite.BMPCurrentFrame.Height div 2);

// informative age e marketvalue , forma, morale nazionalità
  bmp := SE_Bitmap.Create ( WGenericInfo,22 );
  bmp.Canvas.Brush.Color := clBlue;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_country',1,1,1000,1040,200,true );
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Country'),true  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.BlendMode := SE_BlendAverage;
  aSprite.Priority := 1200;
  bmp.Free;

  bmp := SE_Bitmap.Create ( WGenericInfo,22 );
  bmp.Canvas.Brush.Color := clBlue;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_age',1,1,1000,1040,232,true );
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Age'),true  );
  aSprite.Labels.Add( aSpriteLabel);
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,'',true  );   // il valore
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.BlendMode := SE_BlendAverage;
  aSprite.Priority := 1200;
  bmp.Free;

  bmp := SE_Bitmap.Create ( WGenericInfo,22 );
  bmp.Canvas.Brush.Color := clBlue;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_matchesleft',1,1,1000,1040,264,true );
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_MatchesLeft'),true  );
  aSprite.Labels.Add( aSpriteLabel);
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,'',true  );   // il valore
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.BlendMode := SE_BlendAverage;
  aSprite.Priority := 1200;
  bmp.Free;

  bmp := SE_Bitmap.Create ( WGenericInfo,22 );
  bmp.Canvas.Brush.Color := clBlue;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_marketvalue',1,1,1000,1040,296,true );
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_MarketValue'),true  );
  aSprite.Labels.Add( aSpriteLabel);
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,'',true  );   // il valore
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.BlendMode := SE_BlendAverage;
  aSprite.Priority := 1200;
  bmp.Free;

  bmp := SE_Bitmap.Create ( WGenericInfo,22 );
  bmp.Canvas.Brush.Color := clBlue;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_fitness',1,1,1000,1040,328,true );
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('attribute_Fitness'),true  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.BlendMode := SE_BlendAverage;
  aSprite.Priority := 1200;
  bmp.Free;

  bmp := SE_Bitmap.Create ( WGenericInfo,22 );
  bmp.Canvas.Brush.Color := clBlue;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_morale',1,1,1000,1040,360,true );
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('attribute_Morale'),true  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.BlendMode := SE_BlendAverage;
  aSprite.Priority := 1200;
  bmp.Free;

  bmp := SE_Bitmap.Create ( WGenericInfo,22 );
  bmp.Canvas.Brush.Color := clBlue;
  bmp.Canvas.FillRect( Rect(0,0,bmp.Width,bmp.Height) );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'btn_talents',1,1,1000,1040,392,true );
  aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Talents'),true  );
  aSprite.Labels.Add( aSpriteLabel);
  aSprite.BlendMode := SE_BlendAverage;
  aSprite.Priority := 1200;
  bmp.Free;

  // i 2 talenti
  bmp := SE_Bitmap.Create ( 32,32 );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailstalent1',1,1,1000,(1440-(1440-1010) div 2)-16,392,true );
  aSprite.Priority := 3;
  bmp.Free;
  bmp := SE_Bitmap.Create ( 32,32 );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailstalent2',1,1,1000,(1440-(1440-1010) div 2 )-64,392,true );
  aSprite.Priority := 3;
  bmp.Free;

  // fitness e morale
  bmp := SE_Bitmap.Create ( 32,32 );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailsfitness',1,1,1000,(1440-(1440-1010) div 2 )-16,328,true );
  aSprite.Priority := 3;
  bmp.Free;
  bmp := SE_Bitmap.Create ( 32,32 );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailsmorale',1,1,1000,(1440-(1440-1010) div 2 )-16,360,true );
  aSprite.Priority := 3;
  bmp.Free;


  bmp := SE_Bitmap.Create ( 40,32 );
  aSprite:=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'playerdetailscountry',1,1,1000,(1440-(1440-1010) div 2 )-20,200,true );
  aSprite.Priority := 3;
  bmp.Free;


  // in futuro e forse anche history

  {

    GridAT.Cells[0,6].text:= Translate('lbl_Age');
    GridAT.Cells[0,7].text:= Translate('lbl_MarketValue');
    GridAT.Cells[0,8].text:= Translate('attribute_Stamina');

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



}
end;
procedure TForm1.LoadTacticsSubs;
var
  bmp: SE_Bitmap;
  aBtnSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
const FontSize = 14;
begin
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp' );
  aBtnSprite:=SE_TacticsSubs.CreateSprite(bmp.Bitmap ,'btnmenu_back',1,1,1000,100,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Back') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;
  bmp.Free;

end;
procedure TForm1.LoadGreen;
var
  aSprite: SE_Sprite;
begin
   aSprite := SE_Green.CreateSprite( dir_interface + 'GreenCheckMark.bmp', 'green',1,1,1000,0,0 ,true);
   aSprite.Alpha := 200;
   aSprite.BlendMode := SE_BlendAlpha;

end;

procedure TForm1.LoadLive;
var
  bmp: SE_Bitmap;
  aBtnSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
const FontSize = 14;
begin
// menu button
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp' );

  aBtnSprite:=SE_Live.CreateSprite(bmp.Bitmap ,'btnmenu_tactics',1,1,1000,90,YMAINBUTTON,true );
//  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Tactics') ,true  );
//  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'tactics.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;


  aBtnSprite:=SE_Live.CreateSprite(bmp.Bitmap ,'btnmenu_subs',1,1,1000,(180)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Substitutions') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_LIVE.CreateSprite(dir_interface + 'button.bmp' , 'btnmenu_skillpass',1,1,1000,(180*2)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('skill_Pass')  ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;


  aBtnSprite:=SE_Live.CreateSprite(bmp.Bitmap ,'btnmenu_overridecolor',1,1,1000,(180*6)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Uniform1')  ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_Live.CreateSprite(bmp.Bitmap ,'btnmenu_overridecolornormal',1,1,1000,(180*7)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_UniformNormal')  ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;

  bmp.free;

end;

procedure TForm1.LoadSpectator;
var
  bmp: SE_Bitmap;
  aBtnSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
const FontSize = 14;
begin
// menu button
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp' );
  aBtnSprite:=SE_Spectator.CreateSprite(bmp.Bitmap ,'btnmenu_exit',1,1,1000,90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Exit') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'arrowl.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_Spectator.CreateSprite(bmp.Bitmap ,'btnmenu_overridecolor',1,1,1000,(180*6)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Uniform1') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_Spectator.CreateSprite(bmp.Bitmap ,'btnmenu_overridecolornormal',1,1,1000,(180*7)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_UniformNormal') ,true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := true;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.Priority := 1200;

  bmp.free;

end;
procedure TForm1.LoadDoors;
var
  aSprite: SE_Sprite;
begin
  aSprite := SE_Ball.CreateSprite( dir_interface + 'door2.bmp' , 'door0',1,1,1000,255 ,444, true );
  aSprite.Priority := 2;// la palla priority 1
  aSprite := SE_Ball.CreateSprite( dir_interface + 'door2.bmp' , 'door1',1,1,1000,1176 ,444, true );
  aSprite.Priority := 2;
  aSprite.Flipped := True;
  CrossBarN[0] := -18;
  CrossBarN[1] := 0;
  CrossBarN[2] := 18;
end;
procedure TForm1.LoadBackGrounds;
var
  bmp:SE_Bitmap;
begin

  bmp := SE_Bitmap.Create ( dir_interface + 'bgmanager.bmp' );
  bmp.Stretch(  1440, 900);
  SE_BackGround.CreateSprite(bmp.Bitmap ,'backgroundlogin',1,1,1000,SE_Theater1.Width div 2, SE_Theater1.Height div 2,false );
  bmp.Free;

  bmp := SE_Bitmap.Create ( dir_interface + 'bgmanager.bmp' );
  bmp.Stretch(  1440, 900);
  SE_BackGround.CreateSprite(bmp.Bitmap ,'backgroundplayerdetails',1,1,1000,SE_Theater1.Width div 2, SE_Theater1.Height div 2,false );
  bmp.Free;

  // 1440x900
  bmp := SE_Bitmap.Create ( dir_interface + 'field.bmp' );
  bmp.Stretch(  1440, 900);
  SE_BackGround.CreateSprite( bmp.Bitmap , 'field',1,1,1000, SE_Theater1.Width div 2, SE_Theater1.Height div 2, false );
  bmp.Free;

  bmp := SE_Bitmap.Create ( dir_interface + 'fieldf.bmp' );
  bmp.Stretch(  1440, 900);
  SE_BackGround.CreateSprite( bmp.Bitmap , 'fieldf',1,1,1000, SE_Theater1.Width div 2, SE_Theater1.Height div 2, false );
  bmp.Free;

  // 1440x900
  bmp := SE_Bitmap.Create ( dir_interface + 'bgmanager.bmp' );
  bmp.Stretch(  1440, 900);
  SE_BackGround.CreateSprite( bmp.Bitmap , 'backgroundmarket',1,1,1000, SE_Theater1.Width div 2, SE_Theater1.Height div 2, false );
  bmp.Free;

  // 1440x900
  bmp := SE_Bitmap.Create ( dir_interface + 'bgmanager.bmp' );
  bmp.Stretch(  1440, 900);
  SE_BackGround.CreateSprite( bmp.Bitmap , 'backgroundaml',1,1,1000, SE_Theater1.Width div 2, SE_Theater1.Height div 2, false );
  bmp.Free;

  SE_BackGround.HideAllSprites;
  SE_BackGround.ProcessSprites(2000);
end;
procedure TForm1.LoadMainStats;
var
  bmp: SE_Bitmap;
  pbSprite: SE_SpriteProgressBar;
  FaceSprite :SE_Sprite;
  const FontSize = 14;
begin
  bmp := SE_Bitmap.Create ( dir_interface + 'mainstats.bmp' );
  // 1440x900
  SE_MainStats.CreateSprite(bmp.Bitmap ,'mainstats',1,1,1000,0,0,false );
  bmp.Free;

  SE_MainStats.CreateSprite(dir_interface + 'mainstats2.bmp' ,'mainstats2',1,1,1000,0,0 ,false );

  CoordsMainStatsTalent1Spr := Point (8,8);
  CoordsMainStatsTalent2Spr := Point (60,8);
  CoordsMainStatsFace:= Point (132,0);

  CoordsMainStatsNameCenterX := 210;
  CoordsMainStatsName := Point ( 100, 0 ); // -1 centerX

  // Anche le labels degli attibuti sono tutti implicitamente CenterX
  CoordsMainStatsSpeedlbl := Point ( 360,0 );
  CoordsMainStatsDefenselbl := Point ( 460,0 );
  CoordsMainStatsPassinglbl := Point ( 560,0 );
  CoordsMainStatsBallControllbl := Point ( 650,0 );
  CoordsMainStatsShotlbl := Point ( 740,0 );
  CoordsMainStatsHeadinglbl := Point ( 830,0 );

  CoordsMainStatsSpeed := Point ( 360,18 );
  CoordsMainStatsDefense := Point ( 460,18 );
  CoordsMainStatsPassing := Point ( 560,18 );
  CoordsMainStatsBallControl := Point ( 650,18 );
  CoordsMainStatsShot := Point ( 740,18 );
  CoordsMainStatsHeading := Point ( 830,18 );

  CoordsMainStatsStaminaSpr := Point (100,24);
  CoordsMainStatsStaminaBar := Point (800,40);

  pbSprite := SE_MainStats.CreateSpriteProgressBar( 'staminabar',CoordsMainStatsStaminaBar.X,CoordsMainStatsStaminaBar.Y, 180,12,'Calibri',clWhite,clBlue,clBlack,0,'',0,false );
  pbSprite.Priority := 1200;


end;
procedure TForm1.LoadMainInterface;
var
  i: Integer;
  bmp: SE_Bitmap;
  aBtnSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
  pbSprite: SE_SpriteProgressBar;
  const FontSize = 14;
begin
//Menu button
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp');
  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_exit',1,1,1000,90,YMAINBUTTON,true );
  //aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Exit') ,true  );
  //aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'exit.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;
  bmp.Free;

  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp');
  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_uniform',1,1,1000,(180)+90,YMAINBUTTON,true );
//  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Uniform'),true  );
//  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_reset',1,1,1000,(180*2)+90,YMAINBUTTON,true );
//  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Reset'),true  );
//  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite( dir_interface +'reset.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;



  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_market',1,1,1000,(180*3)+90,YMAINBUTTON,true );
//  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Market'),true  );
//  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite ( dir_interface +'market.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_watchlive',1,1,1000,(180*4)+90,YMAINBUTTON,true );
  //aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_watchlive'),true  );
  //aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite( dir_interface +'watchlive.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_standings',1,1,1000,(180*5)+90,YMAINBUTTON,true );
//  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Standings'),true  );
//  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'standings.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;

  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_info',1,1,1000,(180*6)+90,YMAINBUTTON,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Info'),true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.Priority := 1200;
  bmp.Free;

  // btn_play e btn_confirmformation
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp');
  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_play',1,1,1000,(180*7)+90,YMAINBUTTON,true );
 // aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Play'),true  );
 // aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'play.bmp', 'sub',90-40,56-40,true );
  aBtnSprite.Priority := 1200;
  bmp.Free;

  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp');
  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_confirmformation',1,1,1000,(180*7)+90,YMAINBUTTON,true );
 // aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize,Translate('lbl_Confirm'),true  );
 // aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite(dir_interface +'GreenCheckMark.bmp', 'sub',90-32,56-32,true );
  aBtnSprite.Priority := 1200;
  bmp.Free;

  // male female un po' in alto
  bmp := SE_Bitmap.Create ( 120,44);
  bmp.Bitmap.Canvas.Brush.Color :=  $00FF8000;
  bmp.Bitmap.Canvas.RoundRect(0,0,bmp.Width,bmp.Height,5,5);

  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_m',1,1,1000,720-60,YMAINBUTTON-80,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,6,'Calibri',clWhite-1,clBlack,FontSize+6,Translate('lbl_M'),true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;
  aBtnSprite.Alpha := 255;
  aBtnSprite.BlendMode := SE_BlendAlpha;
  // male female un po' in alto
  bmp.Bitmap.Canvas.Brush.Color :=  $00FF80FF;
  bmp.Bitmap.Canvas.RoundRect(0,0,bmp.Width,bmp.Height,5,5);

  aBtnSprite:=SE_MainInterface.CreateSprite(bmp.Bitmap ,'btnmenu_f',1,1,1000,720+60,YMAINBUTTON-80,true );
  aSpriteLabel := SE_SpriteLabel.create( -1,6,'Calibri',clWhite-1,clBlack,FontSize+6,Translate('lbl_F'),true  );
  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.Priority := 1200;
  aBtnSprite.Alpha := 255;
  aBtnSprite.BlendMode := SE_BlendAlpha;

  bmp.Free;


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


{  if Key = 84 then begin
    if not SE_TheaterPassive.visible then
      ShowTheaterPassive
  end;}
end;
procedure TForm1.LoadAllGraphic ;
begin
  se_theater1.Visible:= False;
  se_theater1.Active := false;
  form1.Width := 1440;//1366;
  Form1.Height := 900;//738;
  se_theater1.Width := 1440;//se_theater1.VirtualWidth ;
  se_theater1.Height  := 900;//se_theater1.Virtualheight ;//960 ;
  se_theater1.VirtualWidth :=  1440;// FieldCellW*16; // 12 + 4 per le riserve a sinistra e destra
  se_theater1.Virtualheight := 900; // FieldCellH*7;
  se_theater1.Left := 0;// 320;//(form1.Width div 2) - (SE_Theater1.Width div 2);
  se_theater1.Top := 0;// 56;//(form1.Height div 2) - (SE_Theater1.Height div 2);

  se_theater1.Active := True;
  se_theater1.Visible:= True;

  LoadBackgrounds;
  LoadLogin;
  LoadUniform;
  LoadCountryTeam;
  LoadMainInterface;
  LoadMainStats;
  CreateFieldPoints;
  LoadDoors;
  LoadPlayerDetails;
  LoadAml;
  LoadMarket;
  LoadSpectator;
  LoadLive;
  LoadGreen;
  LoadTacticsSubs;
  LoadScore;

end;


procedure TForm1.SE_ballSpriteDestinationReached(ASprite: SE_Sprite);
var
  bmp: SE_Bitmap;
begin
//  MyBrain.Ball.Moving := False;
 //se è dentro la porta playsound gol e stadio
// ASprite.FrameX:=0;
// ASprite.StopAtEndX := True;
  bmp := SE_Bitmap.Create (dir_ball + 'animball.bmp');
  bmp.Stretch(40*6,40);
  ASprite.ChangeBitmap( bmp.Bitmap ,6,1, 40);
  bmp.Free;
 if aSprite.sTag = 'soundbounce' then begin
   playsound ( pchar (dir_sound +  'bounce.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
   aSprite.sTag := '';
 end
 else if aSprite.sTag = 'soundreceive' then begin
   playsound ( pchar (dir_sound +  'receive.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
   aSprite.sTag := '';
 end;


 if inGolPosition (ASprite.Position ) then  begin

   playsound ( pchar (dir_sound +  'net.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
   ASprite.PositionY:= ASprite.Position.Y +1; // fix sound net 2 volte
   ASprite.MoverData.Destination := Point( ASprite.Position.X, ASprite.Position.Y +1); // fix sound net 2 volte
   Sleep(300);
   playsound ( pchar (dir_sound +  'gol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
 end
 else if inCrossBarPosition (ASprite.Position ) then begin
   playsound ( pchar (dir_sound +  'crossbar.wav' ) , 0, SND_FILENAME OR SND_ASYNC);

   ASprite.PositionY:= ASprite.Position.Y +1; // fix sound crossbar 2 volte
   ASprite.MoverData.Destination := Point( ASprite.Position.X, ASprite.Position.Y +1); // fix sound net 2 volte
   Sleep(300);

   playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
 end
 else if inGKCenterPosition (ASprite.Position ) then begin
   playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
 end;
end;

procedure TForm1.SE_ballSpritePartialMove(ASprite: SE_Sprite; Partial: Byte);
var
  bmp : SE_Bitmap;
begin
//  Memo1.Lines.add (IntToStr(Partial));
  bmp := SE_Bitmap.Create (dir_ball + 'animball.bmp');

  case Partial of
    10: bmp.Stretch(45*6,45);
    20: bmp.Stretch(50*6,50);
    30: bmp.Stretch(55*6,55);
    40: bmp.Stretch(60*6,60);
    50: bmp.Stretch(64*6,64);
    60: bmp.Stretch(60*6,60);
    70: bmp.Stretch(55*6,55);
    80: bmp.Stretch(50*6,50);
    90: bmp.Stretch(45*6,45);

  end;
  ASprite.ChangeBitmap( bmp.Bitmap ,6,1, 40);
  bmp.Free;

end;

procedure TForm1.ShowMainStats  ( aPlayer: TSoccerPlayer );
var
  MainStatsSpr,MainStatsSpr2,aBtnSprite,faceSprite : SE_Sprite;
  pbSprite : SE_SpriteProgressBar;
  bmp : SE_Bitmap;
  aSpriteLabel: SE_SpriteLabel;
  cx,cy,w,NewX: Integer;
begin
  SE_MainStats.Visible := True;
  MainStatsSpr:= SE_MainStats.FindSprite('mainstats');
  MainStatsSpr.Position := Point ( SE_Theater1.Width - MainStatsSpr.BMP.Width div 2, MainStatsSpr.BMP.Height div 2);
  MainStatsSpr.Visible := True; // lo diventa durante il mousemove sui player

  MainStatsSpr.RemoveAllSubSprites;
  MainStatsSpr.Labels.Clear;

  MainStatsSpr2:= SE_MainStats.FindSprite('mainstats2');
  MainStatsSpr2.RemoveAllSubSprites;
  MainStatsSpr2.Position := Point ( 1440-16,MainStatsSpr.Position.Y+MainStatsSpr.BMP.Height + (MainStatsSpr2.BMP.Height div 2) );
  SE_MainStats.ProcessSprites(2000);

  if aPlayer.TalentId1 <> 0 then begin
    bmp := SE_Bitmap.Create ( dir_talent + IntToStr(aplayer.TalentId1) + '.bmp');
    //bmp.Stretch(32,32 );
    MainStatsSpr.AddSubSprite( bmp, 'talent1',CoordsMainStatsTalent1Spr.X,CoordsMainStatsTalent1Spr.Y,true );
    bmp.Free;
  end;
  if aPlayer.TalentId2 <> 0 then begin
    bmp := SE_Bitmap.Create ( dir_talent + IntToStr(aplayer.TalentId2) + '.bmp');
    //bmp.Stretch(32,32 );
    MainStatsSpr.AddSubSprite( bmp, 'talent1',CoordsMainStatsTalent2Spr.X,CoordsMainStatsTalent2Spr.Y,true );
    bmp.Free;
  end;


  bmp := SE_Bitmap.Create ( dir_player + '\' + MyActiveGender + '\'+IntTostr(aPlayer.Country) +'\'+IntTostr(aPlayer.face) +'.bmp');
  bmp.Stretch(32,32 );
  MainStatsSpr.AddSubSprite( bmp, 'face',CoordsMainStatsFace.X,CoordsMainStatsFace.Y,true );
  bmp.Free;

  MainStatsSpr.BMP.Canvas.Font.Name := 'Calibri';
  MainStatsSpr.BMP.Canvas.Font.Size := 14;

  if CheckBox1.Checked then
  w:= MainStatsSpr.BMP.Canvas.TextWidth( aPlayer.ids + ' ' +  aPlayer.SurName)
  else w:= MainStatsSpr.BMP.Canvas.TextWidth(  aPlayer.SurName);
  NewX := CoordsMainStatsNameCenterX - (w div 2);

  if CheckBox1.Checked then
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsName.Y,'Calibri',clWhite,clBlack,14,aPlayer.ids + ' ' + aPlayer.SurName,True )
  else aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsName.Y,'Calibri',clWhite,clBlack,14, aPlayer.SurName,True );

  MainStatsSpr.Labels.Add(aSpriteLabel);


  w:= MainStatsSpr.BMP.Canvas.TextWidth(Translate('attribute_Speed'));
  NewX := CoordsMainStatsSpeedlbl.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsSpeedlbl.Y,'Calibri',clWhite,clBlack,14,Translate('attribute_Speed'),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(Translate('attribute_Defense'));
  NewX := CoordsMainStatsDefenselbl.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsDefenselbl.Y,'Calibri',clWhite,clBlack,14,Translate('attribute_Defense'),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(Translate('attribute_Passing'));
  NewX := CoordsMainStatsPassinglbl.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsPassinglbl.Y,'Calibri',clWhite,clBlack,14,Translate('attribute_Passing'),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(Translate('attribute_Ball.Control'));
  NewX := CoordsMainStatsBallControllbl.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsBallControllbl.Y,'Calibri',clWhite,clBlack,14,Translate('attribute_Ball.Control'),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(Translate('attribute_Shot'));
  NewX := CoordsMainStatsShotlbl.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsShotlbl.Y,'Calibri',clWhite,clBlack,14,Translate('attribute_Shot'),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(Translate('attribute_Heading'));
  NewX := CoordsMainStatsHeadinglbl.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsHeadinglbl.Y,'Calibri',clWhite,clBlack,14,Translate('attribute_Heading'),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(IntToStr(aPlayer.Speed));
  NewX := CoordsMainStatsSpeed.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsSpeed.Y,'Calibri',clWhite,clBlack,18,IntToStr(aPlayer.Speed),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(IntToStr(aPlayer.Defense));
  NewX := CoordsMainStatsDefense.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsDefense.Y,'Calibri',clWhite,clBlack,18,IntToStr(aPlayer.Defense),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(IntToStr(aPlayer.Passing));
  NewX := CoordsMainStatsPassing.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsPassing.Y,'Calibri',clWhite,clBlack,18,IntToStr(aPlayer.Passing),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(IntToStr(aPlayer.BallControl));
  NewX := CoordsMainStatsBallControl.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsBallControl.Y,'Calibri',clWhite,clBlack,18,IntToStr(aPlayer.BallControl),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(IntToStr(aPlayer.Shot));
  NewX := CoordsMainStatsShot.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsShot.Y,'Calibri',clWhite,clBlack,18,IntToStr(aPlayer.Shot),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  w:= MainStatsSpr.BMP.Canvas.TextWidth(IntToStr(aPlayer.Heading));
  NewX := CoordsMainStatsHeading.X - (w div 2);
  aSpriteLabel := SE_SpriteLabel.create(NewX,CoordsMainStatsHeading.Y,'Calibri',clWhite,clBlack,18,IntToStr(aPlayer.Heading),True );
  MainStatsSpr.Labels.Add(aSpriteLabel);

  bmp := SE_Bitmap.Create ( dir_interface + 'stamina.bmp' );
  bmp.Stretch(28,28);
  MainStatsSpr.AddSubSprite (bmp ,'staminaspr',CoordsMainStatsStaminaSpr.X,CoordsMainStatsStaminaSpr.Y,true );

  pbSprite := SE_SpriteProgressBar( SE_MainStats.FindSprite('staminabar'));
  pbSprite.Value := (aPlayer.Stamina * 100 ) div 120;
  case aPlayer.Stamina of
    60..120:pbSprite.BarColor := clLime;
    41..59 :pbSprite.BarColor := $0080FF;
    21..40 :pbSprite.BarColor := clred;
    0..20  :pbSprite.BarColor := $800080;
  end;
  pbSprite.Visible := True;

  // 5 tipi diversi di buff / debuff . non in screenformation
  if GameScreen = ScreenFormation then begin

    if (aPlayer.BuffHome <> 0) or (aPlayer.BuffMorale <> 0) or (aPlayer.BonusbuffD <> 0) or (aPlayer.BonusbuffM <> 0)  or (aPlayer.BonusbuffF <> 0)
    then begin

      MainStatsSpr2.Visible := True; // lo diventa durante il mousemove sui player

      // debug
  //    aPlayer.BuffHome := 1;
  //    aPlayer.BuffMorale := -1;
  //   aPlayer.BonusbuffD := 1;

      if aPlayer.BuffHome > 0 then begin
        bmp := SE_Bitmap.Create ( dir_interface + 'hearth.bmp');
        //bmp.Stretch(32,32 );
        MainStatsSpr2.AddSubSprite( bmp, 'buffhome', 0,0 ,true );
        bmp.Free;
      end;
      if aPlayer.BuffMorale > 0 then begin
        bmp := SE_Bitmap.Create ( dir_interface + 'moraleup.bmp');
        //bmp.Stretch(32,32 );
        MainStatsSpr2.AddSubSprite( bmp, 'buffmoraleup',0,32,true );
        bmp.Free;
      end
      else if aPlayer.BuffMorale < 0 then begin
        bmp := SE_Bitmap.Create ( dir_interface + 'moraledown.bmp');
        //bmp.Stretch(32,32 );
        MainStatsSpr2.AddSubSprite( bmp, 'buffmoraledown',0,32,true );
        bmp.Free;
      end;

      if aPlayer.BonusbuffD > 0   then begin
        bmp := SE_Bitmap.Create ( dir_talent + '139.bmp');
        //bmp.Stretch(32,32 );
        MainStatsSpr2.AddSubSprite( bmp, '139.bmp',0,64,true );
        bmp.Free;
      end;
      if (aPlayer.BonusbuffM > 0 )  then begin
        bmp := SE_Bitmap.Create ( dir_talent + '140.bmp');
        //bmp.Stretch(32,32 );
        MainStatsSpr2.AddSubSprite( bmp, '140.bmp',0,64,true );
        bmp.Free;
      end;
      if (aPlayer.BonusbuffF > 0 )  then begin
        bmp := SE_Bitmap.Create ( dir_talent + '141.bmp');
        //bmp.Stretch(32,32 );
        MainStatsSpr2.AddSubSprite( bmp, '141.bmp',0,64,true );
        bmp.Free;
      end;
    end
    else MainStatsSpr2.Visible := false;
  end;

end;
procedure TForm1.ShowPlayerdetails ( aPlayer: TSoccerPlayer );
var
  i,Diff: Integer;
  aSprite, aBtnSprite,AnimBallSprite: SE_Sprite;
  bmpflags, cBitmap,bmp : SE_Bitmap;
  aSpriteLabel : SE_SpriteLabel;
  pbSprite: SE_SpriteProgressBar;
  const BarFontSize = 14; BarFontSizeTalent = 10;
  const FontSize = 14;

  label skipforGK, skipforGK2;
begin
  // il contenuto è molto dinamico . uso changebitmap e visible
  SE_BackGround.Tag := StrToInt(aPlayer.ids);  // per levelup, dismiss ecc...
  SE_BackGround.HideAllSprites;
  aSprite := SE_Background.FindSprite('backgroundplayerdetails');
  aSprite.Visible := True;

  // Rimuovo eventuali levelup o talentup per ricrearli di nuovo
  for I := SE_PlayerDetails.SpriteCount -1 downto 0 do begin
    aSprite := SE_PlayerDetails.Sprites[i];
    if (LeftStr(aSprite.Guid,7) = 'levelup') or (LeftStr(aSprite.Guid,8) = 'talentup') then
      SE_PlayerDetails.RemoveSprite(aSprite);
  end;
  SE_PlayerDetails.Visible := True;
  //contenuto dinamico
  for I := 0 to SE_PlayerDetails.SpriteCount -1 do begin
    SE_PlayerDetails.Sprites[i].Visible := False;
  end;
  // mostro i btnmenu
  for I := 0 to SE_PlayerDetails.SpriteCount -1 do begin
    if LeftStr(SE_PlayerDetails.Sprites[i].Guid,8) = 'btnmenu_' then
      SE_PlayerDetails.Sprites[i].Visible := true;
  end;

  if MyBrain.Gender = 'f' then
    Diff := 3
    else Diff := 4;

  aSprite := SE_PlayerDetails.FindSprite('playerdetailssurname');
  aSprite.Visible := True;
  aSprite.Labels[0].lText := aPlayer.SurName;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailstooltip');
  aSprite.Visible := True;

  aSprite := SE_PlayerDetails.FindSprite('playerdetailsportrait');
  aSprite.ChangeBitmap( dir_player + '\' + MyActiveGender + '\'+IntTostr(aPlayer.Country) +'\'+   IntToStr(aPlayer.face) + '.bmp',1,1,1000 );
  aSprite.Visible := True;

  if aPlayer.TalentId1 <> 0 then begin
    aSprite := SE_PlayerDetails.FindSprite('playerdetailstalent1');
    aSprite.ChangeBitmap( dir_talent + IntToStr(aPlayer.TalentId1 ) + '.bmp',1,1,1000 );
    aSprite.sTag := IntToStr(aPlayer.TalentId1 ); // per il mousemove sul tooltip
    aSprite.Visible := True;
    if aPlayer.TalentId2 <> 0 then begin
      aSprite := SE_PlayerDetails.FindSprite('playerdetailstalent2');
      aSprite.ChangeBitmap( dir_talent + IntToStr(aPlayer.TalentId2 ) + '.bmp',1,1,1000 );
      aSprite.sTag := IntToStr(aPlayer.TalentId2 ); // per il mousemove sul tooltip
      aSprite.Visible := True;
    end;
  end;

  if aPlayer.TalentId1 = TALENT_ID_GOALKEEPER then goto skipforGK;
  bmp:= SE_Bitmap.Create (dir_interface + 'animball.bmp');
  bmp.Stretch(32*6,32);

  if not ((aPlayer.DefaultSpeed >= MyBrainFormation.MAX_DEFAULT_SPEED) or (aPlayer.Age > 24) or (aPlayer.History_Speed > 0) or (aPlayer.TalentId1=TALENT_ID_GOALKEEPER))  then begin
     // dopo i 24 anni non incrementa più in speed.speed incrementa solo una volta e al amssimo a 4
    pbSprite :=  SE_SpriteProgressBar ( SE_PlayerDetails.FindSprite('bar_speed'));
    pbSprite.Text :=  IntToStr( aPlayer.xp_Speed) + ' / ' + IntToStr(xp_SPEED_POINTS) ;
    pbSprite.Value := trunc (aPlayer.xp_Speed * 100) div  xp_SPEED_POINTS;
    pbSprite.Visible := true;
  end;
  aSprite := SE_PlayerDetails.FindSprite('btn_speed');
  aSprite.Visible := True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailsspeed');
  aSprite.Visible := True;
  aSprite.Labels[0].lFontColor := GetAttributeColorSpeed ( aPlayer.Speed );
  aSprite.Labels[0].lText := IntToStr(aPlayer.Speed);
  { button levelup talent e stat }
  if aPlayer.xp_Speed >= xp_SPEED_POINTS then begin
    AnimBallSprite :=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'levelup_speed',6,1,40,pbSprite.Position.X + (pbSprite.BMP.Width div 2) ,pbSprite.Position.Y,true );
    AnimBallSprite.sTag := '0';
    AnimBallSprite.Priority := 4000;
  end;

 skipforGK:
  if aPlayer.DefaultDefense < MyBrainFormation.MAX_DEFAULT_DEFENSE then begin

    if Not (aPlayer.DefaultShot >= Diff ) then begin // difesa / shot  // 3 oppure 4 nel caso male
      pbSprite :=  SE_SpriteProgressBar (  SE_PlayerDetails.FindSprite('bar_defense'));
      pbSprite.Text :=  IntToStr( aPlayer.xp_defense) + ' / ' + IntToStr(xp_DEFENSE_POINTS) ;
      pbSprite.Value := trunc (aPlayer.xp_defense * 100) div xp_DEFENSE_POINTS;
      pbSprite.Visible := true;
    end;
  end;
  aSprite := SE_PlayerDetails.FindSprite('btn_defense');
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailsdefense');
  aSprite.Visible := True;
  aSprite.Labels[0].lFontColor := GetAttributeColor ( aPlayer.Defense );
  aSprite.Labels[0].lText := IntToStr(aPlayer.Defense);
  if aPlayer.xp_Defense >= xp_DEFENSE_POINTS then begin
    AnimBallSprite :=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'levelup_defense',6,1,40,pbSprite.Position.X + (pbSprite.BMP.Width div 2) ,pbSprite.Position.Y,true );
    AnimBallSprite.sTag := '1';
    AnimBallSprite.Priority := 4000;
  end;


  if aPlayer.DefaultPassing < MyBrainFormation.MAX_DEFAULT_PASSING then begin
    pbSprite :=  SE_SpriteProgressBar (  SE_PlayerDetails.FindSprite('bar_passing'));
    pbSprite.Text :=  IntToStr( aPlayer.xp_passing) + ' / ' + IntToStr(xp_PASSING_POINTS) ;
    pbSprite.Value := trunc (aPlayer.xp_passing * 100) div xp_PASSING_POINTS;
    pbSprite.Visible := true;
  end;
  aSprite := SE_PlayerDetails.FindSprite('btn_passing');
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailspassing');
  aSprite.Visible := True;
  aSprite.Labels[0].lFontColor := GetAttributeColor ( aPlayer.Passing );
  aSprite.Labels[0].lText := IntToStr(aPlayer.Passing);
  if aPlayer.xp_passing >= xp_PASSING_POINTS then begin
    AnimBallSprite :=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'levelup_passing',6,1,40,pbSprite.Position.X + (pbSprite.BMP.Width div 2) ,pbSprite.Position.Y,true );
    AnimBallSprite.sTag := '2';
    AnimBallSprite.Priority := 4000;
  end;

  if aPlayer.TalentId1 = TALENT_ID_GOALKEEPER then goto skipforGK2;

  if aPlayer.DefaultBallControl < MyBrainFormation.MAX_DEFAULT_BALLCONTROL then begin
    if (aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) then begin
      pbSprite :=  SE_SpriteProgressBar (  SE_PlayerDetails.FindSprite('bar_ballcontrol'));
      pbSprite.Text :=  IntToStr( aPlayer.xp_BallControl) + ' / ' + IntToStr(xp_BALLCONTROL_POINTS) ;
      pbSprite.Value := trunc (aPlayer.xp_BallControl * 100) div xp_BALLCONTROL_POINTS;
      pbSprite.Visible := true;
    end
  end;
  aSprite := SE_PlayerDetails.FindSprite('btn_ballcontrol');
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailsballcontrol');
  aSprite.Visible := True;
  aSprite.Labels[0].lFontColor := GetAttributeColor ( aPlayer.Ballcontrol );
  aSprite.Labels[0].lText := IntToStr(aPlayer.Ballcontrol);
  if aPlayer.xp_BallControl >= xp_BALLCONTROL_POINTS then begin
    AnimBallSprite :=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'levelup_ballcontrol',6,1,40,pbSprite.Position.X + (pbSprite.BMP.Width div 2) ,pbSprite.Position.Y,true );
    AnimBallSprite.sTag := '3';
    AnimBallSprite.Priority := 4000;
  end;

  if aPlayer.DefaultShot < MyBrainFormation.MAX_DEFAULT_SHOT then begin
    if not( (aPlayer.DefaultDefense >= Diff) or (aPlayer.TalentId1=TALENT_ID_GOALKEEPER)) then begin // difesa / shot
      pbSprite :=  SE_SpriteProgressBar (  SE_PlayerDetails.FindSprite('bar_shot'));
      pbSprite.Text :=  IntToStr( aPlayer.xp_shot) + ' / ' + IntToStr(xp_SHOT_POINTS) ;
      pbSprite.Value := trunc (aPlayer.xp_shot * 100 ) div xp_SHOT_POINTS;
      pbSprite.Visible := true;
    end;
  end;
  aSprite := SE_PlayerDetails.FindSprite('btn_shot');
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailsshot');
  aSprite.Visible := True;
  aSprite.Labels[0].lFontColor := GetAttributeColor ( aPlayer.Shot );
  aSprite.Labels[0].lText := IntToStr(aPlayer.Shot);
  if aPlayer.xp_Shot >= xp_SHOT_POINTS then begin
    AnimBallSprite :=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'levelup_shot',6,1,40,pbSprite.Position.X + (pbSprite.BMP.Width div 2) ,pbSprite.Position.Y,true );
    AnimBallSprite.sTag := '4';
    AnimBallSprite.Priority := 4000;
  end;

//  aPlayer.xp_Heading := 25; // debug
  if aPlayer.DefaultHeading < MyBrainFormation.MAX_DEFAULT_HEADING then begin
    // Heading incrementa solo una volta
    if Not ((aPlayer.History_Heading > 0) or (aPlayer.TalentId1=TALENT_ID_GOALKEEPER)) then begin
      pbSprite :=  SE_SpriteProgressBar (  SE_PlayerDetails.FindSprite('bar_heading'));
      pbSprite.Text :=  IntToStr( aPlayer.xp_heading) + ' / ' + IntToStr(xp_HEADING_POINTS) ;
      pbSprite.Value := trunc (aPlayer.xp_heading * 100) div xp_HEADING_POINTS;
      pbSprite.Visible := true;
    end;
  end;
  aSprite := SE_PlayerDetails.FindSprite('btn_heading');
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailsheading');
  aSprite.Visible := True;
  aSprite.Labels[0].lFontColor := GetAttributeColor ( aPlayer.Heading );
  aSprite.Labels[0].lText := IntToStr(aPlayer.Heading);
  if aPlayer.xp_Heading >= xp_HEADING_POINTS then begin
    AnimBallSprite :=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'levelup_heading',6,1,40,pbSprite.Position.X + (pbSprite.BMP.Width div 2) ,pbSprite.Position.Y,true );
    AnimBallSprite.sTag := '5';
    AnimBallSprite.Priority := 4000;
  end;


  // rispetto l'esatto ordine dei talenti sul DB
skipforGK2:

  if aPlayer.TalentId1 = 0 then begin

    for I := 1 to NUM_TALENT do begin
//      aPlayer.xpTal[i] := 250; // debug
      aSprite := SE_PlayerDetails.FindSprite('btntalent_' + stringTalents[i]);
      aSprite.Visible:= True;
      pbSprite := SE_SpriteProgressBar ( SE_PlayerDetails.FindSprite('bartalent_' + stringTalents[i]));
      pbSprite.Text := IntToStr(aPlayer.xpTal[I]) + ' / ' + IntToStr(xpNeedTal[I]);
      pbSprite.Value := Trunc (aPlayer.xpTal[I] * 100 ) div xpNeedTal[I] ;
      pbSprite.Visible:= True;

      { button levelup talent e stat }
      if aPlayer.xpTal[I] >= xpNeedTal[I] then begin
        AnimBallSprite :=SE_PlayerDetails.CreateSprite(bmp.Bitmap ,'talentup'+ stringTalents[i],6,1,40,pbSprite.Position.X + (pbSprite.BMP.Width div 2) ,pbSprite.Position.Y,true );
        AnimBallSprite.sTag := IntToStr(i);
        AnimBallSprite.Priority := 4000;
      end;

    end
  end;

  bmp.Free;

  if aPlayer.OnMarket then begin
    aSprite := SE_PlayerDetails.FindSprite('btnmenu_sell' );
    aSprite.Visible:= false;
    aSprite := SE_PlayerDetails.FindSprite('btnmenu_cancelsell' );
    aSprite.Visible:= True;
  end
  else begin
    aSprite := SE_PlayerDetails.FindSprite('btnmenu_cancelsell' );
    aSprite.Visible:= False;
    aSprite := SE_PlayerDetails.FindSprite('btnmenu_sell' );
    aSprite.Visible:= True;
    aSprite := SE_PlayerDetails.FindSprite('btnmenu_dismiss' );
    aSprite.Visible:= True;
  end;

  // age e marketvalue sono Trightstring. le altre sono bmp fisse  a parte nazionalità che usa bmpflags

  bmpflags := SE_Bitmap.Create ( dir_interface + 'flags.bmp');
  aSprite := SE_PlayerDetails.FindSprite('btn_country' );
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailscountry' );
  cBitmap := SE_Bitmap.Create (60,40);

  case aPlayer.Country  of
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
  cBitmap.Stretch(40,32);
  aSprite.ChangeBitmap( cBitmap.Bitmap ,1,1,1000 );
  cBitmap.Free;
  bmpflags.free;

  aSprite.Visible:= True;

  aSprite := SE_PlayerDetails.FindSprite('btn_age' );
  aSprite.BMP.Bitmap.Canvas.Font.Name := 'Calibri';
  aSprite.BMP.Bitmap.Canvas.Font.Size := FontSize;
  aSprite.Labels[1].lText :=  IntToStr(aPlayer.age) ;         // [1] contiene il valore [0] età
  aSprite.Labels[1].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[1].lText , aSprite.BMP.Width, TStringRight);
  aSprite.Visible:= True;

  aSprite := SE_PlayerDetails.FindSprite('btn_matchesleft' );
  aSprite.BMP.Bitmap.Canvas.Font.Name := 'Calibri';
  aSprite.BMP.Bitmap.Canvas.Font.Size := FontSize;
  aSprite.Labels[1].lText :=  IntToStr(aPlayer.MatchesLeft) ;         // [1] contiene il valore [0] età
  aSprite.Labels[1].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[1].lText , aSprite.BMP.Width, TStringRight);
  aSprite.Visible:= True;

  aSprite := SE_PlayerDetails.FindSprite('btn_marketvalue' );
  aSprite.BMP.Bitmap.Canvas.Font.Name := 'Calibri';
  aSprite.BMP.Bitmap.Canvas.Font.Size := FontSize;
  aSprite.Labels[1].lText :=  FloatToStrF(aPlayer.MarketValue, ffCurrency, 10, 0);        // [1] contiene il valore
  aSprite.Labels[1].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[1].lText , aSprite.BMP.Width, TStringRight);
  aSprite.Visible:= True;

  aSprite := SE_PlayerDetails.FindSprite('btn_fitness' );
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('btn_morale' );
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailsfitness' );
  aSprite.ChangeBitmap( dir_interface + IntToStr(aPlayer.Fitness) + '.bmp',1,1,1000 );
  aSprite.Visible:= True;
  aSprite := SE_PlayerDetails.FindSprite('playerdetailsmorale' );
  if aPlayer.Morale > 0 then
    aSprite.ChangeBitmap( dir_interface + 'moraleup.bmp',1,1,1000 )
    else if aPlayer.Morale < 0 then
        aSprite.ChangeBitmap( dir_interface + 'moraledown.bmp',1,1,1000 )
          else if aPlayer.Morale = 0 then
            aSprite.ChangeBitmap( dir_interface + 'moraleneutral.bmp',1,1,1000 );

  aSprite.Visible:= True;

  aSprite := SE_PlayerDetails.FindSprite('btn_talents' );
  aSprite.Visible:= True;



end;
procedure TForm1.HideStadiumAndPlayers;
var
  aBallSprite: SE_Sprite;
  i: Integer;
begin
  SE_players.Visible := False;
  SE_MainInterface.Visible := False;
  SE_FieldPoints.HiddenSpritesMouseMove := false;
  SE_FieldPointsReserve.HiddenSpritesMouseMove := false;
  SE_MainStats.Visible := False;
  SE_ball.Visible := False;
end;
procedure TForm1.ShowStadiumAndPlayers ( Stadium : integer )  ;
var
  aStadium: SE_Sprite;
  i: Integer;
begin
  SE_BackGround.HideAllSprites;
  if Stadium = 0 then begin
    aStadium := SE_background.FindSprite('fieldf');
    aStadium.Visible := True;
  end
  else if Stadium = 1 then begin
    aStadium := SE_background.FindSprite('field');
    aStadium.Visible := True;
  end;


  SE_players.Visible := true;
  SE_ball.Visible := True;
  SE_FieldPoints.HiddenSpritesMouseMove := True;
  SE_FieldPointsReserve.HiddenSpritesMouseMove := True;

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
  aSprite: SE_Sprite;
begin
  tmpSchema := SE_Bitmap.Create;

  for s := 0 to Schemas -1 do begin
    tmpSchema.LoadFromFileBMP( dir_player + 'schema' + IntToStr(s) + '.bmp' );
    for x := 0 to tmpSchema.Width-1 do begin
      for y := 0 to tmpSchema.height-1 do begin
        if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clRed then
          tmpSchema.Bitmap.Canvas.Pixels [x,y] := StrToInt ( TsColors [  StrToInt(TsUniforms[ha][0])])  //<-- se fuori casa prende la maglia giusta
        else if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clBlue then
          tmpSchema.Bitmap.Canvas.Pixels [x,y] := StrToInt ( TsColors [  StrToInt(TsUniforms[ha][1])])  //<-- se fuori casa prende la maglia giusta
        else if tmpSchema.Bitmap.Canvas.Pixels[x,y] = clBlack then
          tmpSchema.Bitmap.Canvas.Pixels [x,y] := StrToInt ( TsColors [  StrToInt(TsUniforms[ha][2])]);  //<-- se fuori casa prende la maglia giusta
      end;
    end;

    if s = UniformSchemaIndex then begin
      tmpSchema.Bitmap.SaveToFile(dir_tmp + 'color' + IntToStr(ha) + '.bmp');
    end;

    tmpSchema.Bitmap.SaveToFile(dir_tmp + 'schema' + IntToStr(s) + '.bmp'); // salvo i 4 o più schemi
    aSprite := SE_Uniform.FindSprite('btn_schema' + IntToStr(s) );
    aSprite.ChangeBitmap(dir_tmp + 'schema' + IntToStr(s) + '.bmp',1,1,1000);
  end;

  tmpSchema.Free;
end;
procedure TForm1.PreloadUniformGK( ha:Byte;   UniformSchemaIndex: Integer);
var
  s,x,y: Integer;
  tmpSchema : SE_Bitmap;
  aSprite: SE_Sprite;
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
        tmpSchema.Bitmap.SaveToFile(dir_tmp + 'colorgk.bmp');
      end;
      // stretch in base a ScaleSprites e width e Height del TcnButton
     // tmpSchema.Stretch (    (ScaleSprites * btn_Schema[s].Width ) div 100, (ScaleSprites * btn_Schema[s].Height ) div 100);
      tmpSchema.Bitmap.SaveToFile(dir_tmp +  'schemagk' + IntToStr(s) + '.bmp'); // salvo i 4 o più schemi
      aSprite := SE_Uniform.FindSprite('btn_schema' + IntToStr(s) );
      aSprite.ChangeBitmap(dir_tmp + 'schema' + IntToStr(s) + '.bmp',1,1,1000);

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
              FaultBitmap.Bitmap.Canvas.Pixels [x,y] := StringToColor (  TsColors [  StrToInt(TsUniforms[Team][0])]);


        end

        else begin  // schiarisco

             // maglia 2
            if FaultBitmapBW.Bitmap.Canvas.Pixels[x,y] = clBlack then
              FaultBitmap.Bitmap.Canvas.Pixels [x,y] := StringToColor (  TsColors [  StrToInt(TsUniforms[Team][1])]);

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
              ShapeBitmap.Bitmap.Canvas.Pixels [x,y] := StringToColor (  TsColors [  StrToInt(TsUniforms[Team][0])]);
              if ShapeBitmap.Bitmap.Canvas.Pixels [x,y] = clWhite then  // fix maglia bianca non trasparente
                ShapeBitmap.Bitmap.Canvas.Pixels [x,y] := clwhite -1

            end;

        end

        else begin

             // maglia 2
            if ShapeBitmap.Bitmap.Canvas.Pixels[x,y] = clBlack then begin
              ShapeBitmap.Bitmap.Canvas.Pixels [x,y] := StringToColor (  TsColors [  StrToInt(TsUniforms[Team][1])]);
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
  country: smallint;
  rank,fitness,morale: Byte;
  AIFormation_x,AIFormation_y: ShortInt;
  lenteamName, lenUniformH,lenUniformA : Integer;
  Surname, talent : string;
  aMirror: TPoint;
  FC: TFormationCell;
  TvCell,TvReserveCell: TPoint;
//  aCell: TSoccerCell;
  bmp,bmp2: SE_BITMAP;
  aSpriteLabel : SE_SpriteLabel;
  aSprite : SE_Sprite;
  aSubSprite: SE_SubSprite;
  aFieldPointSpr, aFieldPoint : SE_Sprite;
  SS: TStringStream;
  dataStr, Attributes,tmps : string;
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


  GameScreen := ScreenFormation;
  SE_players.RemoveAllSprites;
  SE_players.ProcessSprites(2000);

  MyBrainFormation.ClearReserveSlot;
  MyBrainFormation.lstSoccerPlayer.Clear;
  MyBrainFormation.lstSoccerReserve.Clear;
  MyBrainFormation.lstSoccerPlayerALL.Clear;

  // MM3 e buf3 contengono il buffer del team
  TotMarket := 0;


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
  MyBrain.gender :=  Char( buf3[0] [ cur ]);     // Gender del team
  Cur := Cur + 1;


  PreLoadUniform(0, StrToInt( tsUniforms[0][3] ));  // crea 4 schemas bmp ma salva come color quello selezionato
  PreLoadUniformGK(0,  StrToInt( tsUniforms[ 0  ][3]));
  UniformBitmap := SE_Bitmap.Create (dir_tmp + 'color0.bmp');
  UniformBitmapGK := SE_Bitmap.Create (dir_tmp + 'colorgk.bmp');

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
      fitness:= Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      morale:=Ord( buf3[0] [ cur ]);
      Cur := Cur + 1;
      country:= PWORD(@buf3[0] [ cur ])^;
      Cur := Cur + 2;


      aPlayer:= TSoccerPlayer.create(0,MyGuidTeam,Matches_Played,IntToStr(guid),'',surname,Attributes,TalentID1,TalentID2);
      aPlayer.TalentId1 := TalentID1;
      aPlayer.TalentId2 := TalentID2;
      aPlayer.GuidTeam := MyguidTeam;
      aPlayer.Stamina := Stamina;
      aPlayer.AIFormationCellX := AIFormation_x;
      aPlayer.AIFormationCellY := AIFormation_y;

      if not IsOutSideAI(AIFormation_x,AIFormation_y) then begin
        if isValidFormationCell (AIFormation_x,AIFormation_y) then begin
          if (aPlayer.TalentId1 = TALENT_ID_GOALKEEPER) and ((AIFormation_x <> 3) or (AIFormation_y <> 11 )) then begin // se c'è un gk in campo fuori posto
            MyBrainFormation.PutInReserveSlot(aPlayer) ;
            AIFormation_x := aPlayer.AIFormationCellX;
            AIFormation_y := aPlayer.AIFormationCellY;
          end
          else
          aPlayer.Cells := MyBrainFormation.AIField2tv (0,AIFormation_x,AIFormation_y);
        end
        else begin
          MyBrainFormation.PutInReserveSlot(aPlayer) ;
          AIFormation_x := aPlayer.AIFormationCellX;
          AIFormation_y := aPlayer.AIFormationCellY;
        end;
      end
      else begin
        MyBrainFormation.PutInReserveSlot(aPlayer) ;  // ogni volta resetta in ordine per evitare e correggere ewrrori sul db
        AIFormation_x := aPlayer.AIFormationCellX;
        AIFormation_y := aPlayer.AIFormationCellY;
      end;

      aPlayer.DefaultCells := aPlayer.Cells;

      aPlayer.Injured := injured;
      aPlayer.yellowcard := yellowcard;
      aPlayer.Disqualified := Disqualified;
      aPlayer.onmarket := Boolean( onmarket);
      TotMarket := TotMarket + onmarket;
      aPlayer.face := face;
      aPlayer.Fitness := fitness;
      aPlayer.morale := morale;
      aPlayer.Country := country;

      if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
        aPlayer.SE_Sprite := se_Players.CreateSprite(UniformBitmap.Bitmap , aPlayer.Ids,1,1,1000,0,0,true)
      else
        aPlayer.SE_Sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , aPlayer.Ids,1,1,1000,0,0,true);

      aPlayer.SE_Sprite.Scale := ScaleSprites;
      aPlayer.SE_Sprite.MoverData.Speed := DEFAULT_SPEED_PLAYER_FORMATION;
      AddFace ( aPlayer );
      aPlayer.se_sprite.Priority := StrToInt(aPlayer.ids);

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


      MyBrainFormation.lstSoccerPlayerALL.add(aPlayer); // uso anche questa lista per trovare gli sprite inKeyDown
      MyBrainFormation.AddSoccerPlayer(aPlayer); // uso anche questa lista per trovare gli sprite inKeyDown
      if AIFormation_y < 0 then begin // le riserve tutte in alto

        aFieldPoint := SE_FieldPointsReserve.FindSprite(IntToStr (aPlayer.CellX ) + '.-1');
        aPlayer.se_Sprite.Position := aFieldPoint.Position;

      end
      else begin // player normali

        aFieldPoint := SE_FieldPoints.FindSprite(IntToStr (aPlayer.CellX ) + '.' + IntToStr (aPlayer.CellY ));
        aPlayer.se_Sprite.Position := aFieldPoint.Position;

      end;


      if aPlayer.YellowCard > 0  then begin
        aPlayer.SE_Sprite.AddSubSprite (dir_interface + 'yellow.bmp','yellow', 0,0,true);
        aSubSprite := aPlayer.SE_Sprite.FindSubSprite('yellow');
        setupBMp (aSubSprite.lBmp.Bitmap , clBlack );
        aSubSprite.lBmp.Bitmap.Canvas.TextOut(3,0, IntToStr(aPlayer.YellowCard));
        aPlayer.SE_Sprite.SubSprites.Add( aSubSprite ) ;
      end;
      if aPlayer.disqualified > 0 then begin
        aPlayer.SE_Sprite.AddSubSprite ( dir_interface + 'disqualified.bmp','disqualified', 0,0,true);
        aSubSprite := aPlayer.SE_Sprite.FindSubSprite('disqualified');
        setupBMp (aSubSprite.lBmp.Bitmap , clBlack );
        aSubSprite.lBmp.Bitmap.Canvas.TextOut(3,0, IntToStr(aPlayer.disqualified));
      end;
      if aPlayer.injured > 0  then begin
        aPlayer.SE_Sprite.AddSubSprite  (dir_interface + 'injured.bmp','injured', 0,0,true);
        aSubSprite := aPlayer.SE_Sprite.FindSubSprite('injured');
        setupBMp (aSubSprite.lBmp.Bitmap , clBlack );
        aSubSprite.lBmp.Bitmap.Canvas.TextOut(3,0, IntToStr(aPlayer.Injured));
      end;
    end;

    UniformBitmap.Free;

    RefreshCheckFormationMemory;
    // da qui in poi sol oparte grafica
    aSprite:=SE_MainInterface.FindSprite ('btnmenu_uniform' );
    aSprite.AddSubSprite(dir_tmp + 'color0.bmp','sub',90-32,56-32,true);   // sono 64x64, non 80x80

    // qui GuidTeam e rank. SE_Rank contiene solo questi 2 sprites e non è cliccabile. non ci sono mousedown o mousemove
    SE_RANK.removeallSprites;
    SE_RANK.ProcessSprites(2000);
    bmp := SE_Bitmap.Create (440,32);
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect( 0,0,bmp.Width,bmp.Height));
    aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,24,Capitalize(MyGuidteamName ),True  );

    aSprite := SE_RANK.CreateSprite(bmp.bitmap,'teamname', 1,1,1000,500,128,true);
    aSprite.Labels.Add(aSpriteLabel);
    bmp.Free;

    bmp2:= SE_Bitmap.Create ( dir_interface + 'starg.bmp');
    bmp := SE_Bitmap.Create (bmp2.Width*15,bmp2.Height);
    for i := 0 to 14 do begin
      bmp2.CopyRectTo(bmp,0,0,i*bmp2.Width,0,bmp2.Width-1,bmp2.Height,False,0);
    end;
    aSprite := SE_RANK.CreateSprite(bmp.bitmap,'starsg', 1,1,1000,720 + (bmp.Width div 2),134,true);
    bmp2.Free;

    bmp2:= SE_Bitmap.Create ( dir_interface + 'stary.bmp');
    for i := 0 to mi do begin
      bmp2.CopyRectTo(aSprite.bmp,0,0,i*bmp2.Width,0,bmp2.Width-1,bmp2.Height,False,0);
    end;

    bmp2.Free;
    bmp.Free;

    bmp := SE_Bitmap.Create (112,22);
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect( 0,0,bmp.Width,bmp.Height));
    aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,14,Capitalize(Translate('lbl_rank' ) ) + ' ' + IntToStr(rank) ,True  );

    aSprite := SE_RANK.CreateSprite(bmp.bitmap,'rank', 1,1,1000,aSprite.Position.X  + (aSprite.BMP.Width div 2)+(bmp.Width div 2)+4 ,137,False);
    aSprite.Labels.Add(aSpriteLabel);
    bmp.Free;
    //debug
   // rank := 3;
   // mi:=210;
    if (rank = 1) and (mi > 15 ) then
    aSprite.Labels[0].lText := aSprite.Labels[0].lText + '  +' + IntTostr ( mi -15 );
    case rank of
      6: aSprite.Labels[0].lFontColor := clWhite;
      5: aSprite.Labels[0].lFontColor := clLime;
      4: aSprite.Labels[0].lFontColor := clblue;//$00FF8000;
      3: aSprite.Labels[0].lFontColor := clPurple;
      2: aSprite.Labels[0].lFontColor := clYellow;
      1: aSprite.Labels[0].lFontColor := clRed;
    end;

    // Money e nextha
    aSprite := SE_RANK.CreateSprite(dir_interface + 'money.bmp','gold', 1,1,1000,305,40,true);
    bmp := SE_Bitmap.Create (300,22);
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect( 0,0,bmp.Width,bmp.Height));
    aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clWhite,clBlack,14,FloatToStrF(Money, ffCurrency, 10, 0) ,True  );
    aSprite := SE_RANK.CreateSprite(bmp.bitmap,'money', 1,1,1000,490,40,true);
    aSprite.Labels.Add(aSpriteLabel);
    bmp.Free;

    if NextHa = 0 then
      aSprite := SE_RANK.CreateSprite(dir_interface + 'home.bmp','nextturn', 1,1,1000,320,90,true)
      else
        aSprite := SE_RANK.CreateSprite(dir_interface + 'away.bmp','nextturn', 1,1,1000,325,95,true);


end;
procedure TForm1.ShowLoading;
var
  bmp:SE_Bitmap;
  aSprite,aBtnSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
  const FontSize = 14;
begin
  SE_Loading.RemoveAllSprites;
  SE_Loading.ProcessSprites(2000);
  SE_Loading.Visible := true;

  bmp:=SE_Bitmap.Create (1440,900);
  bmp.Bitmap.Canvas.Brush.Color :=  clGray;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));

  aSprite:=SE_Loading.CreateSprite( bmp.Bitmap , 'loading' ,1,1, 1000, (SE_Theater1.VirtualWidth div 2), (SE_Theater1.Virtualheight div 2) ,false );
  aSpriteLabel := SE_SpriteLabel.create( -1,SE_Theater1.Virtualheight div 2,'Calibri',clYellow,clBlack,14,Capitalize(Translate( 'lbl_loading')),True  );
  aSprite.Labels.Add(aSpriteLabel);
  bmp.Free;

  if (GameScreen = ScreenWaitingLive) or (GameScreen = ScreenWaitingLive) then begin
    aBtnSprite:=SE_Loading.CreateSprite(dir_interface + 'button.bmp' ,'btnmenu_cancelqueue',1,1,1000,720,YMAINBUTTON,true );
    aBtnSprite.TransparentForced := True;
    aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
    aBtnSprite.AddSubSprite( dir_interface +'arrowl.bmp', 'sub',90-40,56-40,true );
    aBtnSprite.Priority := 1200;
  end;

end;
procedure TForm1.CreateFieldPoints;
var
  AFieldPoint: TFieldPoint;
  bmp: se_bitmap;
  AFieldSprite: SE_Sprite;
  i: integer;
  aTrgb: TRGB;
begin
  // le 2 porte devono essere oggetti a parte. il gk deve stare sotto la traversa. Oppure il gk davanti alla porta
  // effetti speciali: i guanti del portiere. il calcio dei cerchi

  FieldPoints := TObjectList<TFieldPoint>.Create(True);
  FieldPointsReserve := TObjectList<TFieldPoint>.Create(True);
  FieldPointsCorner := TObjectList<TFieldPoint>.Create(True);
  FieldPointsPenalty := TObjectList<TFieldPoint>.Create(True);
  FieldPointsCrossBar := TObjectList<TFieldPoint>.Create(True);
  FieldPointsGol := TObjectList<TFieldPoint>.Create(True);
  FieldPointsOut := TObjectList<TFieldPoint>.Create(True);

  // i 2 gk
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,3);   AFieldPoint.Pixel := Point  (264,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,3);  AFieldPoint.Pixel := Point  (1174,448); FieldPoints.Add( AFieldPoint);

  // Le celle del campo in gioco normali
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,0);  AFieldPoint.Pixel := Point  (315,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,0);  AFieldPoint.Pixel := Point  (397,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,0);  AFieldPoint.Pixel := Point  (488,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,0);  AFieldPoint.Pixel := Point  (577,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,0);  AFieldPoint.Pixel := Point  (670,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,0);  AFieldPoint.Pixel := Point  (764,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,0);  AFieldPoint.Pixel := Point  (856,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,0);  AFieldPoint.Pixel := Point  (942,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,0);  AFieldPoint.Pixel := Point  (1028,200); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,0);  AFieldPoint.Pixel := Point  (1112,200); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,1);  AFieldPoint.Pixel := Point  (315,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,1);  AFieldPoint.Pixel := Point  (397,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,1);  AFieldPoint.Pixel := Point  (488,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,1);  AFieldPoint.Pixel := Point  (577,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,1);  AFieldPoint.Pixel := Point  (670,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,1);  AFieldPoint.Pixel := Point  (764,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,1);  AFieldPoint.Pixel := Point  (856,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,1);  AFieldPoint.Pixel := Point  (942,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,1);  AFieldPoint.Pixel := Point  (1028,280); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,1);  AFieldPoint.Pixel := Point  (1112,280); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,2);  AFieldPoint.Pixel := Point  (315,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,2);  AFieldPoint.Pixel := Point  (397,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,2);  AFieldPoint.Pixel := Point  (488,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,2);  AFieldPoint.Pixel := Point  (577,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,2);  AFieldPoint.Pixel := Point  (670,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,2);  AFieldPoint.Pixel := Point  (764,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,2);  AFieldPoint.Pixel := Point  (856,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,2);  AFieldPoint.Pixel := Point  (942,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,2);  AFieldPoint.Pixel := Point  (1028,360); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,2);  AFieldPoint.Pixel := Point  (1112,360); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,3);  AFieldPoint.Pixel := Point  (315,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,3);  AFieldPoint.Pixel := Point  (397,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,3);  AFieldPoint.Pixel := Point  (488,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,3);  AFieldPoint.Pixel := Point  (577,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,3);  AFieldPoint.Pixel := Point  (670,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,3);  AFieldPoint.Pixel := Point  (764,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,3);  AFieldPoint.Pixel := Point  (856,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,3);  AFieldPoint.Pixel := Point  (942,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,3);  AFieldPoint.Pixel := Point  (1028,448); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,3);  AFieldPoint.Pixel := Point  (1112,448); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,4);  AFieldPoint.Pixel := Point  (315,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,4);  AFieldPoint.Pixel := Point  (397,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,4);  AFieldPoint.Pixel := Point  (488,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,4);  AFieldPoint.Pixel := Point  (577,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,4);  AFieldPoint.Pixel := Point  (670,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,4);  AFieldPoint.Pixel := Point  (764,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,4);  AFieldPoint.Pixel := Point  (856,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,4);  AFieldPoint.Pixel := Point  (942,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,4);  AFieldPoint.Pixel := Point  (1028,534); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,4);  AFieldPoint.Pixel := Point  (1112,534); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,5);  AFieldPoint.Pixel := Point  (315,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,5);  AFieldPoint.Pixel := Point  (397,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,5);  AFieldPoint.Pixel := Point  (488,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,5);  AFieldPoint.Pixel := Point  (577,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,5);  AFieldPoint.Pixel := Point  (670,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,5);  AFieldPoint.Pixel := Point  (764,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,5);  AFieldPoint.Pixel := Point  (856,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,5);  AFieldPoint.Pixel := Point  (942,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,5);  AFieldPoint.Pixel := Point  (1028,614); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,5);  AFieldPoint.Pixel := Point  (1112,614); FieldPoints.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,6);  AFieldPoint.Pixel := Point  (315,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,6);  AFieldPoint.Pixel := Point  (397,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,6);  AFieldPoint.Pixel := Point  (488,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,6);  AFieldPoint.Pixel := Point  (577,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,6);  AFieldPoint.Pixel := Point  (670,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,6);  AFieldPoint.Pixel := Point  (764,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,6);  AFieldPoint.Pixel := Point  (856,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,6);  AFieldPoint.Pixel := Point  (942,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,6);  AFieldPoint.Pixel := Point  (1028,696); FieldPoints.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,6);  AFieldPoint.Pixel := Point  (1112,696); FieldPoints.Add( AFieldPoint);

  // out
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,0);  AFieldPoint.Pixel := Point  (241,198); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,1);  AFieldPoint.Pixel := Point  (241,272); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,2);  AFieldPoint.Pixel := Point  (248,336); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,4);  AFieldPoint.Pixel := Point  (248,550); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,5);  AFieldPoint.Pixel := Point  (241,620); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,6);  AFieldPoint.Pixel := Point  (241,704); FieldPointsOut.Add( AFieldPoint);

  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,0);  AFieldPoint.Pixel := Point  (1190,198); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,1);  AFieldPoint.Pixel := Point  (1190,275); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,2);  AFieldPoint.Pixel := Point  (1183,336); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,4);  AFieldPoint.Pixel := Point  (1183,550); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,5);  AFieldPoint.Pixel := Point  (1190,620); FieldPointsOut.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,6);  AFieldPoint.Pixel := Point  (1190,704); FieldPointsOut.Add( AFieldPoint);

  // Penalty                                                     // in realtà a video sarebbero 9,3 2,3 ma uso GetPenaltyCell
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,3);  AFieldPoint.Pixel := Point  (1048,448); FieldPointsPenalty.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,3);  AFieldPoint.Pixel := Point  (384,448); FieldPointsPenalty.Add( AFieldPoint);

  // Corner
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,0);  AFieldPoint.Pixel := Point  (1160,156); AFieldPoint.Team :=0;FieldPointsCorner.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,6);  AFieldPoint.Pixel := Point  (1160,739); AFieldPoint.Team :=0;FieldPointsCorner.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,0);  AFieldPoint.Pixel := Point  (271,156); AFieldPoint.Team :=1; FieldPointsCorner.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,6);  AFieldPoint.Pixel := Point  (271,739); AFieldPoint.Team :=1;FieldPointsCorner.Add( AFieldPoint);

  // le riserve :array 0..21
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (0,-1);  AFieldPoint.Pixel := Point  (41,82); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (1,-1);  AFieldPoint.Pixel := Point  (41,164); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (2,-1);  AFieldPoint.Pixel := Point  (41,246); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (3,-1);  AFieldPoint.Pixel := Point  (41,328); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (4,-1);  AFieldPoint.Pixel := Point  (41,410); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (5,-1);  AFieldPoint.Pixel := Point  (41,492); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (6,-1);  AFieldPoint.Pixel := Point  (41,574); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (7,-1);  AFieldPoint.Pixel := Point  (41,656); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (8,-1);  AFieldPoint.Pixel := Point  (41,738); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (9,-1);  AFieldPoint.Pixel := Point  (123,656); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (10,-1);  AFieldPoint.Pixel := Point  (123,738); AFieldPoint.Team:=0; FieldPointsReserve.Add( AFieldPoint);


  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (11,-1);  AFieldPoint.Pixel := Point  (1399,82); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (12,-1);  AFieldPoint.Pixel := Point  (1399,164); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (13,-1);  AFieldPoint.Pixel := Point  (1399,246); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (14,-1);  AFieldPoint.Pixel := Point  (1399,328); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (15,-1);  AFieldPoint.Pixel := Point  (1399,410); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (16,-1);  AFieldPoint.Pixel := Point  (1399,492); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (17,-1);  AFieldPoint.Pixel := Point  (1399,574); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (18,-1);  AFieldPoint.Pixel := Point  (1399,656); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (19,-1);  AFieldPoint.Pixel := Point  (1399,738); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (20,-1);  AFieldPoint.Pixel := Point  (1317,656); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);
  AFieldPoint:= TFieldPoint.Create;  AFieldPoint.Cell := Point  (21,-1);  AFieldPoint.Pixel := Point  (1317,738); AFieldPoint.Team:=1; FieldPointsReserve.Add( AFieldPoint);

 // FieldPointsSprite  per celle del campo. per formazione
 // bmp:= se_bitmap.Create(dir_interface + 'sniper.bmp');
  bmp:= se_bitmap.Create(80*24,80);
  bmp.Bitmap.Canvas.Brush.Color :=  clBlack;//$3E906E;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  //bmp.Bitmap.Canvas.Brush.Color :=  clGreen;
  aTrgb := TColor2TRGB(clGreen);
  for i := 0 to 11 do begin     // red incremente.
    bmp.Bitmap.Canvas.Brush.Color :=  TRGB2TColor(aTrgb);
    aTrgb.r := aTrgb.r + (255 div 12);
    bmp.Bitmap.Canvas.Ellipse(80*i,0,(80*(i+1)),80);
  end;
  for i := 12 to 24 do begin     // red decrementa
    bmp.Bitmap.Canvas.Brush.Color :=  TRGB2TColor(aTrgb);
    aTrgb.r := aTrgb.r - (255 div 12);
    bmp.Bitmap.Canvas.Ellipse(80*i,0,(80*(i+1)),80);
  end;

  for I := 0 to FieldPoints.Count -1 do begin
    AFieldSprite := se_FieldPoints.CreateSprite( bmp.Bitmap, IntToStr(FieldPoints[i].cell.X )+ '.'+IntToStr(FieldPoints[i].cell.Y )  , 24,1 ,50, FieldPoints[i].Pixel.X, FieldPoints[i].Pixel.Y, true );
    AFieldSprite.BlendMode := SE_BlendAverage;
    AFieldSprite.Visible := false;
  end;

  for I := 0 to FieldPointsReserve.Count -1 do begin
    AFieldSprite := SE_FieldPointsReserve.CreateSprite( bmp.Bitmap, IntToStr(FieldPointsReserve[i].cell.X )+'.-1', 24,1 ,50, FieldPointsReserve[i].Pixel.X, FieldPointsReserve[i].Pixel.Y, true );
    AFieldSprite.BlendMode := SE_BlendAverage;
    AFieldSprite.Visible := false;
  end;
//  FieldPointsSpriteSpecial si usa durante i corner, calci di punizione
  for I := 0 to FieldPointsPenalty.Count -1 do begin
    AFieldSprite := SE_FieldPointsSpecial.CreateSprite( bmp.Bitmap, IntToStr(FieldPointsPenalty[i].cell.X )+'.' + IntToStr(FieldPointsPenalty[i].cell.Y ),
       24,1 ,50, FieldPointsPenalty[i].Pixel.X, FieldPointsPenalty[i].Pixel.Y, true );
    AFieldSprite.BlendMode := SE_BlendAverage;
    AFieldSprite.Visible := false;
  end;
  for I := 0 to FieldPointsCorner.Count -1 do begin
    AFieldSprite := SE_FieldPointsSpecial.CreateSprite( bmp.Bitmap, IntToStr(FieldPointsCorner[i].cell.X )+'.' + IntToStr(FieldPointsCorner[i].cell.Y ),
       24,1 ,50, FieldPointsCorner[i].Pixel.X, FieldPointsCorner[i].Pixel.Y, true );
    AFieldSprite.BlendMode := SE_BlendAverage;
    AFieldSprite.Visible := false;
  end;
  for I := 0 to FieldPointsOut.Count -1 do begin
    AFieldSprite := SE_FieldPointsOut.CreateSprite( bmp.Bitmap, IntToStr(FieldPointsOut[i].cell.X )+'.' + IntToStr(FieldPointsOut[i].cell.Y ),
       24,1 ,50, FieldPointsOut[i].Pixel.X, FieldPointsOut[i].Pixel.Y, true );
    AFieldSprite.BlendMode := SE_BlendAverage;
    AFieldSprite.Visible := false;
  end;

  bmp.Free;
end;
procedure TForm1.RefreshCheckFormationMemory;
var
  aSpritePlay, aSpriteConfirmFormation : SE_Sprite;
begin

  aSpritePlay := SE_MainInterface.FindSprite ('btnmenu_play');
  aSpritePlay.Visible := false;
  aSpriteConfirmFormation := SE_MainInterface.FindSprite ('btnmenu_confirmformation');
  aSpriteConfirmFormation.Visible := False;
  if FormationChanged then begin  // click btnmenu_confirmformation lo pone a falso
    aSpritePlay.Visible := false;
    aSpriteConfirmFormation.Visible := true;
    Exit;
  end;

  if CheckFormationTeamMemory then begin
    aSpritePlay.Visible := true;
    aSpriteConfirmFormation.Visible := false;
  end
  else begin
    aSpritePlay.Visible := false;
    aSpriteConfirmFormation.Visible := true;
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

procedure TForm1.RoundBorder (bmp: TBitmap);
var
x,y,w,h: Integer;
begin
  w := bmp.Width;
  h := bmp.Height;

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
  aFieldPointSpr: SE_Sprite;
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


    aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr(CellX) + '.' + IntToStr(CellY) );
    posX := aFieldPointSpr.Position.X + ArrowDirection.offset.X;
    posY := aFieldPointSpr.Position.Y + ArrowDirection.offset.Y;
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

  if (X1=X2) and (Y1=Y2) then
    Exit;

  fileName := dir_interface + 'arrow.bmp';

  ArrowDirection.angle :=   AngleOfLine ( Player1.se_sprite.Position , Player2.se_sprite.Position );

  if (X2 = X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := -40;
  end
  else if (X2 = X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := +40;
  end
  else if (X2 < X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := -30;
   ArrowDirection.offset.Y  := -30;
  end
  else if (X2 > X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := +30;
   ArrowDirection.offset.Y  := -30;
  end
  else if (X2 > X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := +30;
   ArrowDirection.offset.Y  := +30;
  end
  else if (X2 < X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := -30;
   ArrowDirection.offset.Y  := +30;
  end
  else if (X2 > X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := +40;
   ArrowDirection.offset.Y  := 0;
  end
  else if (X2 < X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := -40;
   ArrowDirection.offset.Y  := 0;
  end;

  posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
  posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;


  Arrow := SE_interface.CreateSprite(filename,'arrow', 1,1,1000,  posX,posY, true);
  ColorizeArrowCircle ( Player1.team,   Arrow.BMP );
  Arrow.Scale := 72;
  Arrow.Angle := ArrowDirection.angle ;

end;
procedure TForm1.CreateArrowDirection ( Player1 : TSoccerPlayer; CellX, CellY: integer );
var
  X1,X2,Y1,Y2,posX,posY: Integer;
  ArrowDirection : TSpriteArrowDirection;
  Arrow : SE_Sprite;
begin
  X1:= Player1.CellX;
  Y1:= Player1.CellY;
  X2:= CellX;
  Y2:= CellY;

  if (X1=X2) and (Y1=Y2) then
    Exit;

  ArrowDirection.angle :=   AngleOfLine ( Point(Player1.CellX,Player1.CellY) , Point ( CellX, CellY));

  if (X2 = X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := -40;
  end
  else if (X2 = X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := 0;
   ArrowDirection.offset.Y  := +40;
  end
  else if (X2 < X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := -30;
   ArrowDirection.offset.Y  := -30;
  end
  else if (X2 > X1) and (Y2 < Y1) then begin
   ArrowDirection.offset.X  := +30;
   ArrowDirection.offset.Y  := -30;
  end
  else if (X2 > X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := +30;
   ArrowDirection.offset.Y  := +30;
  end
  else if (X2 < X1) and (Y2 > Y1) then begin
   ArrowDirection.offset.X  := -30;
   ArrowDirection.offset.Y  := +30;
  end
  else if (X2 > X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := +40;
   ArrowDirection.offset.Y  := 0;
  end
  else if (X2 < X1) and (Y2 = Y1) then begin
   ArrowDirection.offset.X  := -40;
   ArrowDirection.offset.Y  := 0;
  end;

  posX := Player1.se_sprite.Position.X + ArrowDirection.offset.X;
  posY := Player1.se_sprite.Position.Y + ArrowDirection.offset.Y;

  Arrow := SE_interface.CreateSprite(dir_interface + 'arrow.bmp','arrow', 1,1,1000,  posX,posY, true);
  ColorizeArrowCircle ( Player1.team,   Arrow.BMP );
  Arrow.Scale := 72;
  Arrow.Angle := ArrowDirection.angle ;

end;

procedure TForm1.PrsMouseEnter;
var
  i,ii,c : Integer;
  anOpponent,aGK: TSoccerPlayer;
  aPoint : TPoint;
  Modifier,BaseShot: Integer;
  aDoor, BarrierCell: TPoint;
  aFieldPointSpr: SE_Sprite;
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
    //CreateBaseAttribute (  selectedPlayer.CellX, SelectedPlayer.CellY, BaseShot) ;
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
//    CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;


  end
  else if MyBrain.w_FreeKick4 then begin
//    BaseShot :=  SelectedPlayer.DefaultShot + modifier_penaltyPOS +1 +Abs(Integer(  (SelectedPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (SelectedPlayer.TalentId2 = TALENT_ID_FREEKICKS) ));  // . il +1 è importante al shot. è una freekick4
//    CreateBaseAttribute (  selectedPlayer.CellX, SelectedPlayer.CellY, BaseShot) ;

    // il pos non ha quel +1 ma ha la respinta
    if BaseShot <= 0 then BaseShot := 1;
  // mostro la chance el portiere e la mia
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
//    CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end
  else begin
    BaseShot :=  SelectedPlayer.Shot + Mybrain.MalusPrecisionShot[SelectedPlayer.CellX];
    if BaseShot <= 0 then BaseShot := 1;
  //  CreateBaseAttribute (  selectedPlayer.CellX, SelectedPlayer.CellY, BaseShot) ;

    for Ii := 0 to ShotCells.Count -1 do begin

      if (ShotCells[ii].DoorTeam <> SelectedPlayer.Team) and
      (ShotCells[ii].CellX = SelectedPlayer.CellX) and (ShotCells[ii].CellY = SelectedPlayer.CellY) then begin

        for c := 0 to  ShotCells[ii].subCell.Count -1 do begin
          aPoint :=  ShotCells[ii].subCell.Items [c];
          anOpponent := MyBrain.GetSoccerPlayer(aPoint.X ,aPoint.Y );
          if  anOpponent = nil then continue;
          if Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y ).Team <> SelectedPlayer.Team then begin
            if SelectedPlayer.CellX = anOpponent.cellX then Modifier := MyBrain.modifier_defenseShot else Modifier :=0;
            CreateArrowDirection( anOpponent, SelectedPlayer );
            //CreateBaseAttribute (  aPoint.x, aPoint.y, anOpponent.Defense) ;
          end;
        end;
      end;
    end;

    // mostro la chance el portiere
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
   // CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end;

end;
procedure TForm1.CreateBaseAttribute ( CellX, CellY, value: integer );
var
  aFieldPointSpr: SE_Sprite;
  sebmp: SE_Bitmap;

begin

  // la skill usata e i punteggi
  aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr(CellX) + '.' + IntToStr(CellY) );

  sebmp:= Se_bitmap.Create (64,64);
  sebmp.Bitmap.Canvas.Brush.color := clGray;

  sebmp.Bitmap.Canvas.Ellipse(0,0,64,64);
  sebmp.Bitmap.Canvas.Font.Name := 'Calibri';
  sebmp.Bitmap.Canvas.Font.Size := 18;
  sebmp.Bitmap.Canvas.Font.Style := [fsbold];
  sebmp.Bitmap.Canvas.Font.Color := clYellow;
  if length(  IntToStr(Value)) = 1 then
    sebmp.Bitmap.Canvas.TextOut( 26,18, IntToStr(Value))
    else sebmp.Bitmap.Canvas.TextOut( 22,18, IntToStr(Value));


  se_interface.CreateSprite( sebmp.bitmap, 'numbers', 1, 1, 100, aFieldPointSpr.Position.X  , aFieldPointSpr.Position.Y , true );
  sebmp.Free;

end;
procedure TForm1.mainThreadTimer(Sender: TObject);
var
  FirstTickCount: longint;
  aSprite: SE_Sprite;
begin

  WaitForSingleObject ( MutexAnimation, INFINITE );

  GCD := GCD - SE_ThreadTimer ( Sender).Interval;
  if (GameScreen = ScreenLive) or (GameScreen = ScreenSpectator ) then Begin

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
      se_ball.ProcessSprites( mainThread.Interval );
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      Application.ProcessMessages ;
      ReleaseMutex ( MutexAnimation );
      exit;
    end;


    if (AnimationScript.waitMovingPlayers) then begin // se devo apsettare i players

       if se_players.IsAnySpriteMoving  then  begin
          se_ball.ProcessSprites( mainThread.Interval );
          se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
          Application.ProcessMessages ;
          ReleaseMutex ( MutexAnimation );
          exit;
       end;
    end;


    if AnimationScript.Index <= AnimationScript.Ts.Count -1  then begin

      if AnimationScript.Index = 0  then
      if se_ball.IsAnySpriteMoving then begin
       ReleaseMutex ( MutexAnimation );
       exit;
      end;


    {$ifdef tools}
      toolSpin.Visible := false;
    {$endif tools}
      Animating:= True;
      if GameScreen = ScreenLive then begin
        SE_TacticsSubs.visible := False;
        aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
        aSprite.Visible := False;
        aSprite := SE_LIVE.FindSprite('btnmenu_subs');
        aSprite.Visible := False;
        aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
        aSprite.Visible := False;
      end;
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
      if GameScreen = ScreenLive then begin
        SE_TacticsSubs.visible := False;
        aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
        aSprite.Visible := True;
        aSprite := SE_LIVE.FindSprite('btnmenu_subs');
        aSprite.Visible := True;
        aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
        aSprite.Visible := true;
      end;

      //      FirstTickCount := GetTickCount;   // margine di sicurezza o il successivo ClientLoadBrainMM svuota la lstSoccerPlayer
//       repeat
//         Application.ProcessMessages;
//       until ((GetTickCount-FirstTickCount) >= Longint(2000));

//      ClientLoadBrainMM ( CurrentIncMove, false ) ; // <-- false, gli sprite e le liste non saranno mai svuotate
      ClientLoadBrainMM ( CurrentIncMove ) ; // <-- false, gli sprite e le liste non saranno mai svuotate
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
    SE_Theater1.Cursor := aCursor;

end;

procedure TForm1.PosMouseEnter ;
var
  ii,c : Integer;
  anOpponent,aGK: TSoccerPlayer;
  aPoint : TPoint;
  Modifier,BaseShot: Integer;
  BarrierCell: TPoint;
  aDoor: TPoint;

begin
  hidechances ;
  if SelectedPlayer = nil then Exit;
  Modifier := 0;
  aDoor := Mybrain.GetOpponentDoor ( SelectedPlayer );
  if absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, adoor.X, adoor.Y  ) > PowerShotRange then exit;

  if MyBrain.w_FreeKick3 then begin
    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    BaseShot :=  SelectedPlayer.DefaultShot + Mybrain.MalusPrecisionShot[SelectedPlayer.CellX] +1 +
                  Abs(Integer(  (SelectedPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (SelectedPlayer.TalentId2 = TALENT_ID_FREEKICKS) ));  // . il +1 è importante al shot. è una freekick3    if BaseShot <= 0 then BaseShot := 1;
   // CreateBaseAttribute (  SelectedPlayer.CellX,SelectedPlayer.CellY, BaseShot) ;
  // mostro le 4 chance in barriera
    BarrierCell := MyBrain.GetBarrierCell( MyBrain.TeamFreeKick , MyBrain.Ball.CellX, MyBrain.Ball.CellY  ) ;
    CreateCircle( aGK.Team, BarrierCell.X, BarrierCell.Y );

    CreateCircle( aGK );
   // CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end
  else if MyBrain.w_FreeKick4 then begin
  //  BaseShot :=  SelectedPlayer.DefaultShot + modifier_penalty +
  //                Abs(Integer(  (SelectedPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (SelectedPlayer.TalentId2 = TALENT_ID_FREEKICKS) ));
       // . il +2 è importante al shot. è una freekick4
  //  if BaseShot <= 0 then BaseShot := 1;
   // CreateBaseAttribute (  SelectedPlayer.CellX,SelectedPlayer.CellY, BaseShot) ;

    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
   // CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
  end
  else begin
    BaseShot :=  SelectedPlayer.Shot + Mybrain.MalusPowerShot[SelectedPlayer.CellX]  ;
    if BaseShot <= 0 then BaseShot := 1;
   // CreateBaseAttribute (  SelectedPlayer.CellX,SelectedPlayer.CellY, BaseShot) ;

    for Ii := 0 to ShotCells.Count -1 do begin

      if (ShotCells[ii].DoorTeam <> SelectedPlayer.Team) and
      (ShotCells[ii].CellX = SelectedPlayer.CellX) and (ShotCells[ii].CellY = SelectedPlayer.CellY) then begin

        for c := 0 to  ShotCells[ii].subCell.Count -1 do begin
          aPoint := ShotCells[ii].subCell.Items [c];
          anOpponent := Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y );
          if  anOpponent = nil then continue;
          if Mybrain.GetSoccerPlayer(aPoint.X ,aPoint.Y ).Team <> SelectedPlayer.Team then begin
            if SelectedPlayer.CellX = anOpponent.cellX then Modifier := MyBrain.modifier_defenseShot else Modifier :=0;
            CreateArrowDirection( anOpponent, SelectedPlayer );
           // CreateBaseAttribute (  aPoint.x, aPoint.y, anOpponent.defense );

          end;
        end;
      end;
    end;

    aGK := Mybrain.GetOpponentGK ( SelectedPlayer.Team );
    CreateCircle( aGK );
  //  CreateBaseAttribute (  aGK.CellX,aGK.CellY, aGK.Defense) ;
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
procedure TForm1.CheckBox5Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'debug_setfault,' + BoolTostr (CheckBox5.Checked ) + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}

end;

procedure TForm1.CheckBox6Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'debug_setred,' + BoolTostr (CheckBox6.Checked ) + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}

end;

procedure TForm1.CheckBox7Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'debug_setslwaysgol,' + BoolTostr (CheckBox7.Checked ) + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}

end;

procedure TForm1.CheckBox8Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'debug_setposcrosscorner,' + BoolTostr (CheckBox8.Checked ) + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}

end;

procedure TForm1.CheckBox9Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'debug_buff100,' + BoolTostr (CheckBox9.Checked ) + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}


end;

procedure TForm1.CheckBox4Click(Sender: TObject);
begin
{$ifdef tools}
  if GCD <= 0 then begin
    tcp.SendStr( 'debug_tackle_failed,' + BoolTostr (CheckBox4.Checked ) + EndOfLine ) ;
    GCD := GCD_DEFAULT;
  end;
 {$endif tools}

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
begin
  (* controlla in locale memoria *)
  // controlla se sono schierati 11 giocatori a parte i disqualified. se può farlo deve giocare col massimo dei giocatori

  FixDuplicateFormationMemory;
  Result:= False;

  pcount:=0;
  pdisq:=0;

  // non leggo la situazione direttamente dagli sprite, ma dal file ini così leggo tutte le formazioni di tutte le squadre
  for i := 0 to  MyBrainFormation.lstSoccerPlayer.count -1 do begin
    aPlayer := MyBrainFormation.lstSoccerPlayer[i];
    if isOutSideAI (aPlayer.AIformationCellX,aPlayer.AIFormationCellY)  or (aPlayer.disqualified  > 0)  then continue;

    if isValidFormationCell(aPlayer.AIFormationCellX, aPlayer.AIFormationCellY  ) then
      Inc(pCount);

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

end;
procedure TForm1.FixDuplicateFormationMemory;
var
  i,i2,pcount,pdisq: Integer;
  CellPoint : TPointBoolean;
  lstCellPoint: TList<TPointBoolean>;
  DupFound: Boolean;
  aPoint : TPointBoolean;
  apPointB: pPointBoolean;
  label retry;
begin
  (* controlla in locale memoria *)

  lstCellPoint:= TList<TPointBoolean>.Create;
Retry:

  lstCellPoint.Clear;
  for i := 0 to  MyBrainFormation.lstSoccerPlayer.count -1 do begin
    CellPoint.X := MyBrainFormation.lstSoccerPlayer[i].AIformationCellX;
    CellPoint.Y := MyBrainFormation.lstSoccerPlayer[i].AIformationCellY;
    CellPoint.value := False;
    lstCellPoint.Add (CellPoint);
  end;

  for i := 0 to  MyBrainFormation.lstSoccerPlayer.count -1 do begin
    aPoint.X  :=MyBrainFormation.lstSoccerPlayer[i].AIFormationCellX;
    aPoint.Y  :=MyBrainFormation.lstSoccerPlayer[i].AIFormationCellY;

    for i2 := 0 to lstCellPoint.Count -1 do begin

      if (lstCellPoint.Items[i2].X = aPoint.X) and ( lstCellPoint.Items[i2].Y = aPoint.Y) then begin
        if lstCellPoint.Items[i2].value then begin
          MyBrainFormation.PutInReserveSlot(MyBrainFormation.lstSoccerPlayer[i]);
          MoveInReserves(MyBrainFormation.lstSoccerPlayer[i]);
          goto Retry;
        end
        else begin
          aPoint.value := True;
          lstCellPoint.Items[i2] :=  aPoint;

          Break;
        end;
      end;
    end;
  end;

  lstCellPoint.Free;
end;
function TForm1.inGolPosition ( PixelPosition: Tpoint ): boolean;
var
  aFieldPointSpr: SE_Sprite;
begin

  Result := False;
  aFieldPointSpr := SE_FieldPoints.FindSprite('0.3');
  if (PixelPosition.X = aFieldPointSpr.Position.X - PixelsGolDeep) and (PixelPosition.Y = aFieldPointSpr.Position.Y) then
    result := True;
  aFieldPointSpr := SE_FieldPoints.FindSprite('11.3');
  if (PixelPosition.X = aFieldPointSpr.Position.X + PixelsGolDeep) and (PixelPosition.Y = aFieldPointSpr.Position.Y) then
    result := True;

end;
function TForm1.inCrossBarPosition ( PixelPosition: Tpoint ): Boolean;
var
  aFieldPointSpr: SE_Sprite;
begin

  Result := False;
  aFieldPointSpr := SE_ball.FindSprite('door0');
  if (PixelPosition.X = aFieldPointSpr.Position.X ) and
   ( (PixelPosition.Y = aFieldPointSpr.Position.Y -- PixelsCrossbarY ) or (PixelPosition.Y = aFieldPointSpr.Position.Y + PixelsCrossbarY ))  then
    result := True;
  aFieldPointSpr := SE_ball.FindSprite('door1');
  if (PixelPosition.X = aFieldPointSpr.Position.X ) and
   ( (PixelPosition.Y = aFieldPointSpr.Position.Y -- PixelsCrossbarY ) or (PixelPosition.Y = aFieldPointSpr.Position.Y + PixelsCrossbarY ))  then
    result := True;

end;
function TForm1.inGKCenterPosition ( PixelPosition: Tpoint ): boolean;
var
  aFieldPointSpr: SE_Sprite;
begin
  // sia che la trattiene sia che la respinge
  Result := False;
  aFieldPointSpr := SE_Fieldpoints.FindSprite('0.3');
  if (PixelPosition.X = aFieldPointSpr.Position.X -PixelsGKBounce ) and (PixelPosition.Y = aFieldPointSpr.Position.Y) then
    result := True;
  aFieldPointSpr := SE_Fieldpoints.FindSprite('11.3');
  if (PixelPosition.X = aFieldPointSpr.Position.X +PixelsGKBounce ) and (PixelPosition.Y = aFieldPointSpr.Position.Y) then
    result := True;
  if (PixelPosition.X = aFieldPointSpr.Position.X -PixelsGKTake ) and (PixelPosition.Y = aFieldPointSpr.Position.Y) then
    result := True;
  aFieldPointSpr := SE_Fieldpoints.FindSprite('11.3');
  if (PixelPosition.X = aFieldPointSpr.Position.X +PixelsGKTake ) and (PixelPosition.Y = aFieldPointSpr.Position.Y) then
    result := True;

end;
procedure Tform1.SpriteReset ;
var
  i: integer;
  aPlayer: TsoccerPlayer;
  aFieldPointSpr: SE_Sprite;
  BIndex: Integer;
  ACellBarrier: TPoint;

begin
// la palla
  aFieldPointSpr := SE_Fieldpoints.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));
  //Mybrain.Ball.SE_Sprite.PositionX  := aFieldPointSpr.PositionX;
//  Mybrain.Ball.SE_Sprite.PositionY := Mybrain.Ball.SE_Sprite.Position.Y + BallZ0Y;
 // Mybrain.Ball.SE_Sprite.FrameXmax := 0 ; // palla ferma

  if Mybrain.Ball.Player <> nil then begin
    Mybrain.Ball.SE_Sprite.MoverData.Speed := DEFAULT_SPEED_BALL_LOW;
//    Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.SE_Sprite.Position;
    case Mybrain.Ball.Player.team of
      0: begin
        Mybrain.Ball.SE_Sprite.MoverData.Destination :=  Point(aFieldPointSpr.Position.X + abs(Ball0X),aFieldPointSpr.Position.Y);
      end;
      1: begin
        Mybrain.Ball.SE_Sprite.MoverData.Destination := Point(aFieldPointSpr.Position.X - abs(Ball0X),aFieldPointSpr.Position.Y);
      end;
    end;

  end;


  Mybrain.Ball.SE_Sprite.BlendMode := se_BlendNormal;
  Mybrain.Ball.SE_Sprite.Visible := True;

  if Mybrain.w_CornerSetup then begin//   (brain.w_Coa) or (brain.w_Cod)  then begin
    CornerSetBall;
  end
  else if Mybrain.w_FreeKickSetup4 then begin
    PenaltySetBall;
  end;

  // i player
  BIndex := 0;
  for I := 0 to Mybrain.lstSoccerPlayer.Count -1 do begin
    aPlayer := Mybrain.lstSoccerPlayer [i];


    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (aPlayer.CellX ) + '.' + IntToStr (aPlayer.CellY ));
    aPlayer.se_Sprite.Position := aFieldPointSpr.position  ;
    aPlayer.se_sprite.MoverData.Destination := aFieldPointSpr.Position;
    aPlayer.se_sprite.Scale := ScaleSprites;
    aPlayer.SE_Sprite.Visible := True;



    if MyBrain.w_FreeKick3  then begin
      if aPlayer.isFKD3 then begin
        ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
        aFieldPointSpr := SE_FieldPoints.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));
        aPlayer.se_sprite.Scale := ScaleSpritesBarrier;
        aPlayer.se_Sprite.Position := Point (aFieldPointSpr.Position.X + BarrierPosition[BIndex].X , aFieldPointSpr.Position.Y + BarrierPosition[BIndex].Y );
        aPlayer.SE_Sprite.MoverData.Destination := Point (aFieldPointSpr.Position.X +BarrierPosition[BIndex].X, aFieldPointSpr.Position.Y + BarrierPosition[BIndex].Y);
        inc (BIndex);
      end;
    end;

    if Mybrain.w_CornerSetup and aPlayer.isCOF then begin//   (brain.w_Coa) or (brain.w_Cod)  then begin
      CornerSetPlayer ( aPlayer );
    end
    else if Mybrain.w_FreeKick4 and aPlayer.isFK4 then begin//   (brain.w_Coa) or (brain.w_Cod)  then begin
      PenaltySetPlayer ( aPlayer );
    end;

    if (GameScreen = ScreenLive) and (aPlayer.GuidTeam = MyGuidTeam) then // dopo la scelta di cof , coa ecc....
     aPlayer.SE_Sprite.GrayScaled := false;

    if (overridecolor) and (aPlayer.Team = 1) then begin
     aPlayer.se_sprite.BlendMode := SE_BlendAverage;
    end;

  end;

  // le riserve
  for I := 0 to Mybrain.lstSoccerReserve.Count -1 do begin
    aPlayer := Mybrain.lstSoccerReserve [i];

    // le riserve tutte a sinistra e tutte a destra

    MyBrain.ReserveSlot [aPlayer.Team, aPlayer.cellx]:= aPlayer.Ids;

    if aPlayer.Team = 0 then
      aFieldPointSpr := SE_FieldpointsReserve.FindSprite(IntToStr (aPlayer.AIFormationCellX)+ '.-1')
    else aFieldPointSpr := SE_FieldpointsReserve.FindSprite(IntToStr (aPlayer.AIFormationCellX+11)+ '.-1') ;

    aPlayer.se_Sprite.Position := aFieldPointSpr.Position;
    aPlayer.se_sprite.MoverData.Destination := aFieldPointSpr.Position;
    aPlayer.se_sprite.Scale := ScaleSprites;

    if GameScreen = ScreenSubs then
      aPlayer.se_Sprite.Visible := True
      else aPlayer.se_Sprite.Visible := false;

    if (overridecolor) and (aPlayer.Team = 1) then begin
     aPlayer.se_sprite.BlendMode := SE_BlendAverage;
    end;

  end;


  Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;

  UpdateSubSprites;
  if not (  (MyBrain.w_Fka1) or (MyBrain.w_Fka2) or (MyBrain.w_Fka3) or (MyBrain.w_Fka4) or (MyBrain.w_Fkd2)  or (MyBrain.w_Fkd3) ) then begin

    HideFP_Friendly; // qualsiasi evidenziazione scompare
  end;
  HideFP_Reserve; // qualsiasi evidenziazione scompare
  //  application.ProcessMessages ;

//  SetGlobalCursor( crHandPoint);
    Mybrain.Ball.SE_Sprite.AnimationInterval := ANIMATION_BALL_LOW ;


end;
procedure TForm1.CornerSetBall;
var
  aFieldPointSpr: SE_Sprite;
begin
  // la posizione della palla indica quale
  aFieldPointSpr := SE_FieldPointsSpecial.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));

  Mybrain.Ball.SE_Sprite.Position :=  point ( aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y );
  Mybrain.Ball.SE_Sprite.MoverData.Destination :=  point ( aFieldPointSpr.Position.X  , aFieldPointSpr.Position.Y );

end;
procedure TForm1.CornerSetPlayer ( aPlayer: TsoccerPlayer);
var
  aFieldPointSpr: SE_Sprite;
begin
  aFieldPointSpr := SE_FieldPointsSpecial.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));

  aPlayer.SE_Sprite.Position :=  Point( aFieldPointSpr.Position.X  , aFieldPointSpr.Position.Y );
  aPlayer.SE_Sprite.MoverData.Destination  :=  Point( aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y );

end;
procedure TForm1.PenaltySetPlayer ( aPlayer: TsoccerPlayer);
var
  aFieldPointSpr: SE_Sprite;
  aPenaltyCell: TPoint;
begin
  APenaltyCell := MyBrain.GetPenaltyCell ( MyBrain.TeamFreeKick );
  aFieldPointSpr := SE_FieldPointsSpecial.FindSprite(IntToStr (APenaltyCell.X ) + '.' + IntToStr (APenaltyCell.Y ));

  aPlayer.SE_Sprite.Position :=  Point( aFieldPointSpr.Position.X  , aFieldPointSpr.Position.Y );
  aPlayer.SE_Sprite.MoverData.Destination  :=  Point( aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y );

end;
procedure TForm1.PenaltySetBall;
var
  aFieldPointSpr: SE_Sprite;
  aPenaltyCell: TPoint;
begin
  // la posizione della palla indica quale
  APenaltyCell := MyBrain.GetPenaltyCell ( MyBrain.TeamFreeKick );
  aFieldPointSpr := SE_FieldPointsSpecial.FindSprite(IntToStr (APenaltyCell.X ) + '.' + IntToStr (APenaltyCell.Y ));

  Mybrain.Ball.SE_Sprite.Position :=  point ( aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y );
  Mybrain.Ball.SE_Sprite.MoverData.Destination :=  point ( aFieldPointSpr.Position.X  , aFieldPointSpr.Position.Y );

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
  HideChances;
  AnimationScript.Reset ;
end;
procedure Tform1.CreateSplash (x,y,w,h: Integer; aString: string; msLifespan,FontSize: integer; FontColor,BackColor: TColor; Transparent: boolean) ;
var
  TextSize : TSize;
  bmp: SE_Bitmap;
  aSprite: SE_Sprite;
begin

 // SE_LifeSpan.RemoveAllSprites;
  HideFP_Friendly_ALL;

  bmp:= SE_Bitmap.Create(w,h);
  bmp.Bitmap.Canvas.Brush.color := BackColor;
  bmp.Bitmap.Canvas.FillRect(rect(0,0,bmp.Width ,bmp.Height ));
  bmp.Bitmap.Canvas.Font.Name := 'Calibri';
  bmp.Bitmap.Canvas.Font.Quality := fqNonAntialiased;
  bmp.Bitmap.Canvas.font.Size := FontSize;
  bmp.Bitmap.Canvas.Font.Style := [fsBold];
  bmp.Bitmap.Canvas.font.Color := FontColor;
  TextSize:= bmp.Bitmap.Canvas.TextExtent (aString);
  bmp.Bitmap.Canvas.TextOut( (bmp.Bitmap.Width div 2)  - (TextSize.cx div 2), (bmp.Bitmap.Height div 2)  - (TextSize.cy div 2)    ,aString );

  aSprite := SE_LifeSpan.CreateSprite(bmp.Bitmap, aString, 1,1, 20,x,y, Transparent  );
  aSprite.LifeSpan := msLifespan;
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
  BIndex := 0;
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

procedure Tform1.ClientLoadBrainMM  ( incMove: Byte  );
var
  SS : TStringStream;
  lenuser0,lenuser1,lenteamname0,lenteamname1,lenuniform0,lenuniform1,lenSurname: byte;
  lenMatchInfo: word;
  dataStr,tmpStr: string;
  Cur: Integer;
  TotPlayer,TotReserve,TotGameOver: byte;
  aFieldPointSpr, aSprite: se_Sprite;
  i,ii , aAge,aCellX,aCellY,aTeam,aGuidTeam,nMatchesPlayed,nMatchesLeft,pcount,BIndex,aStamina: integer;
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
  ACellBarrier,TvReserveCell,aPenaltyCell: TPoint;
  DefaultSpeed, DefaultDefense , DefaultPassing, DefaultBallControl, DefaultShot, DefaultHeading: Byte;
  Speed, Defense , Passing, BallControl, Shot, Heading: ShortInt;
  UniformBitmap : array[0..1] of SE_Bitmap;
  UniformBitmapGK: SE_bitmap;
  aBallSprite: SE_Sprite;
begin
  SE_Skills.Visible := False;
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
    MyBrain.lstSoccerGameOver.Clear ;
    MyBrain.lstSoccerPlayer.Clear ;
    MyBrain.lstSoccerReserve.Clear;
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

  MyBrain.Score.Rank [0] :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.Rank [1] :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;

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
  MyBrain.Score.DominantColor[0]:=  StringToColor( TsColors [ StrToInt( TsUniforms[0][0] )]);

  MyBrain.Score.DominantColor[1]:= StringToColor( TsColors [ StrToInt( TsUniforms[1][0] ) ]);

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

  MyBrain.Gender :=  Char( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Minute :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;

  LocalSeconds  :=  Ord( buf3[incMove][ cur ]);
  MyBrain.fmilliseconds :=  (PWORD(@buf3[incMove][ cur ])^ ) * 1000;
  cur := cur + 2 ;
  MyBrain.TeamTurn :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;

  Refresh_teamnames;

  MyBrain.FTeamMovesLeft :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.GameStarted :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.FlagEndGame :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.Finished :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.Shpbuff :=  Boolean(  Ord( buf3[incMove][ cur ]));
  cur := cur + 1 ;
  MyBrain.ShpFree :=    Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.incMove :=    Ord( buf3[incMove][ cur ]);   // supplementari, rigori, può sforare 255 ?
  cur := cur + 1 ;
  i_tml ( IntToStr( MyBrain.FTeamMovesLeft ) ,  IntToStr( MyBrain.TeamTurn ) )  ;

  // aggiungo la palla
  if MyBrain.Ball <> nil then
    MyBrain.Ball.Free;


  MyBrain.Ball := Tball.create(MyBrain);
  MyBrain.Ball.CellX :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;
  MyBrain.Ball.CellY :=  Ord( buf3[incMove][ cur ]);
  cur := cur + 1 ;



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

  aSprite := SE_Score.FindSprite('scorenick0');
  aSprite.Labels[0].lText :=  UpperCase( MyBrain.Score.Team [0]);
  aSprite.Labels[0].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[0].lText , aSprite.BMP.Width, TStringCenter);
  aSprite := SE_Score.FindSprite('scorenick1');
  aSprite.Labels[0].lText :=  UpperCase( MyBrain.Score.Team [1]);
  aSprite.Labels[0].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[0].lText , aSprite.BMP.Width, TStringCenter);
  aSprite := SE_Score.FindSprite('scorescore');
  aSprite.Labels[0].lText := IntToStr(Mybrain.Score.gol [0]) +'-'+ IntToStr(Mybrain.Score.gol [1]);
  aSprite.Labels[0].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[0].lText , aSprite.BMP.Width, TStringCenter);
  aSprite := SE_Score.FindSprite('scoreminute');
  aSprite.Labels[0].lText := IntToStr(MyBrain.Minute) +'''';
  aSprite.Labels[0].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[0].lText , aSprite.BMP.Width, TStringCenter);


  totPlayer :=  Ord( buf3[incMove][ cur ]);
  Cur := Cur + 1;
  // cursore posizionato sul primo player
  BIndex := 0;
  for I := 0 to totPlayer -1 do begin

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

      aPlayer:= TSoccerPlayer.Create( aTeam,
                                 MyBrain.Score.TeamGuid [aTeam] ,
                                 nMatchesPlayed,
                                 aIds,
                                 aName,
                                 aSurname,
                                 Attributes,
                                 TalentID1,TalentID2  );     // attributes e defaultAttrributes sono uguali
      MyBrain.AddSoccerPlayer(aPlayer);       // lo aggiune per la prima ed unica volta
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
    //if not IsOutSideAI(aPlayer.AIFormationCellX,aPlayer.AIFormationCellY) then
      aPlayer.Cells := MyBrain.AIField2TV (0,aPlayer.AIFormationCellX,aPlayer.AIFormationCellY);
   // else begin
   //   if MyBrain.isReserveSlot (aPlayer.AIFormationCellX,aPlayer.AIFormationCellY)then begin
   //     aPlayer.CellX := aPlayer.AIFormationCellX;
   //     aPlayer.CellY := aPlayer.AIFormationCellY;
   //   end
   //   else begin  // non è una cella di riserva valida
   //      MyBrain.PutInReserveSlot(aPlayer) ;
   //   end;
   // end;

    aPlayer.DefaultCells := aPlayer.Cells;


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
    aPlayer.country := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2;
    aPlayer.BonusBuffD := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusBuffM := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusBuffF := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BuffHome := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;
    aPlayer.BuffMorale := Ord( buf3[incMove][ cur ]);
    Cur := Cur + 1;


    if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
      aPlayer.Se_Sprite := se_players.CreateSprite( UniformBitmap[aTeam].bitmap ,aPlayer.Ids,1,1,100,0,0,true)
    else
      aPlayer.Se_Sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , aPlayer.Ids,1,1,1000,0,0,true);
    aPlayer.Se_Sprite.Scale:= ScaleSprites;
    AddFace ( aPlayer );
    aPlayer.Se_Sprite.Priority :=  StrToInt(aPlayer.ids) ;
    aPlayer.Se_Sprite.MoverData.Speed := DEFAULT_SPEED_PLAYER;

    if (overridecolor) and (aPlayer.Team = 1)  then  begin
      aPlayer.se_sprite.BlendMode := SE_BlendAverage;
    end;

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (aPlayer.CellX ) + '.' + IntToStr (aPlayer.CellY ));
    aPlayer.Se_Sprite.Position := aFieldPointSpr.position  ;
    aPlayer.Se_Sprite.MoverData.Destination := aFieldPointSpr.Position;

    if GameScreen = ScreenSubs then
      aPlayer.Se_Sprite.Visible := True
      else aPlayer.Se_Sprite.Visible := false;


    if MyBrain.w_FreeKick3  then begin
      if aPlayer.isFKD3 then begin
        ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
        aFieldPointSpr := SE_FieldPoints.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));
        aPlayer.se_sprite.Scale := ScaleSpritesBarrier;
        aPlayer.SE_Sprite.MoverData.Destination := Point (aFieldPointSpr.Position.X + BarrierPosition[BIndex].X, aFieldPointSpr.Position.Y + BarrierPosition[BIndex].Y);
        inc( BIndex) ;
      end;
    end

    else if MyBrain.w_FreeKick4  then begin
      if aPlayer.isFK4 then begin
        PenaltySetPlayer(aPlayer);
      end;
    end

    else if MyBrain.w_CornerSetup then begin
      if aPlayer.isCOF then begin
        CornerSetPlayer( aPlayer );
      end;
    end;

    aPlayer.SE_Sprite.Visible := True;




  end;

    // aggiungo la palla graficamente DOPO avere caricato i player o Mybrain.Ball.Player = nil sempre
    SE_ball.RemoveAllSprites ('ball');
    se_ball.ProcessSprites(2000);
    aFieldPointSpr := SE_Fieldpoints.FindSprite(IntToStr (MyBrain.Ball.CellX ) + '.' + IntToStr (MyBrain.Ball.CellY ));
    // la palla potrebbe essere anche fuori, quindi in FieldPointsOut o FieldPointsSpecial
    bmp:= SE_Bitmap.Create (dir_interface + 'animball.bmp');
    bmp.Stretch(40*6,40);

    if Mybrain.Ball.Player <> nil then begin
      case Mybrain.Ball.Player.team of
        0: Mybrain.Ball.SE_Sprite := se_Ball.CreateSprite(bmp.Bitmap,'ball',6,1,40, aFieldPointSpr.Position.X+ abs(Ball0X), aFieldPointSpr.Position.Y , true);
        1: Mybrain.Ball.SE_Sprite := se_Ball.CreateSprite(bmp.Bitmap,'ball',6,1,40, aFieldPointSpr.Position.X- abs(Ball0X), aFieldPointSpr.Position.Y , true);
      end;
    end
    else Mybrain.Ball.SE_Sprite := se_Ball.CreateSprite(bmp.Bitmap,'ball',6,1,40,
                                       aFieldPointSpr.Position.X   , aFieldPointSpr.Position.Y , true);


    Mybrain.Ball.SE_Sprite.MoverData.Speed:= DEFAULT_SPEED_BALL;
    Mybrain.Ball.SE_Sprite.PositionY := Mybrain.Ball.SE_Sprite.Position.Y ;
    Mybrain.Ball.SE_Sprite.MoverData.Destination := Mybrain.Ball.Se_sprite.Position;
    Mybrain.Ball.SE_Sprite.Priority := 1;
    bmp.Free;

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

      aPlayer:= TSoccerPlayer.Create( aTeam,
                                 MyBrain.Score.TeamGuid [aTeam] ,
                                 nMatchesPlayed,
                                 aIds,
                                 aName,
                                 aSurname,
                                 Attributes,
                                 TalentID1,TalentID2  );     // attributes e defaultAttrributes sono uguali
      MyBrain.AddSoccerReserve(aPlayer);

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
    aPlayer.country := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2;


                    // fare preloadBrain, diverso da formation

      if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
        aPlayer.SE_sprite := se_players.CreateSprite( UniformBitmap[aTeam].bitmap ,aPlayer.Ids,1,1,100,0,0,true)
      else
        aPlayer.SE_sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , aPlayer.Ids,1,1,1000,0,0,true);
      aPlayer.SE_sprite.Scale:= ScaleSprites;
      AddFace ( aPlayer );
      aPlayer.SE_sprite.Priority := StrToInt(aPlayer.ids) ;
      aPlayer.SE_sprite.MoverData.Speed := DEFAULT_SPEED_PLAYER;
      if (overridecolor) and (aPlayer.Team = 1)  then  begin
        aPlayer.se_sprite.BlendMode := SE_BlendAverage;
      end;


      MyBrain.ReserveSlot [aPlayer.Team, aPlayer.AIFormationCellX]:= aPlayer.Ids;

      if aPlayer.Team = 0 then
        aFieldPointSpr := SE_FieldPointsReserve.FindSprite(IntToStr (aPlayer.CellX ) + '.-1')
        else aFieldPointSpr := SE_FieldPointsReserve.FindSprite(IntToStr (aPlayer.CellX +11 ) + '.-1'); // graficamente a destra
      aPlayer.Se_Sprite.Position := aFieldPointSpr.Position;
      aPlayer.Se_Sprite.MoverData.Destination := aFieldPointSpr.Position;

      if GameScreen = ScreenSubs then
        aPlayer.SE_sprite.Visible := True
        else aPlayer.SE_sprite.Visible := false;


  end;

  totGameOver :=  Ord( buf3[incMove][ cur ]);
  Cur := Cur + 1;

  for I := 0 to totGameOver -1 do begin

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

      aPlayer:= TSoccerPlayer.Create( aTeam,
                                 MyBrain.Score.TeamGuid [aTeam] ,
                                 nMatchesPlayed,
                                 aIds,
                                 aName,
                                 aSurname,
                                 Attributes,
                                 TalentID1,TalentID2  );     // attributes e defaultAttrributes sono uguali
      MyBrain.AddSoccerGameOver(aPlayer);

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
    aPlayer.country := PWORD(@buf3[incMove][ cur ])^;
    Cur := Cur + 2;


                    // fare preloadBrain, diverso da formation

      if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
        aPlayer.SE_sprite := se_players.CreateSprite( UniformBitmap[aTeam].bitmap ,aPlayer.Ids,1,1,100,0,0,true)
      else
        aPlayer.SE_sprite := se_Players.CreateSprite(UniformBitmapGK.Bitmap , aPlayer.Ids,1,1,1000,0,0,true);
      aPlayer.SE_sprite.Scale:= ScaleSprites;
      AddFace ( aPlayer );
      aPlayer.SE_sprite.Priority := StrToInt(aPlayer.ids) ;
      aPlayer.SE_sprite.MoverData.Speed := DEFAULT_SPEED_PLAYER;
      if (overridecolor) and (aPlayer.Team = 1)  then  begin
        aPlayer.se_sprite.BlendMode := SE_BlendAverage;
      end;


      MyBrain.ReserveSlot [aPlayer.Team, aPlayer.AIFormationCellX]:= aPlayer.Ids;

      if aPlayer.Team = 0 then
        aFieldPointSpr := SE_FieldPointsReserve.FindSprite(IntToStr (aPlayer.CellX ) + '.-1')
        else aFieldPointSpr := SE_FieldPointsReserve.FindSprite(IntToStr (aPlayer.CellX +11 ) + '.-1'); // graficamente a destra
      aPlayer.Se_Sprite.Position := aFieldPointSpr.Position;
      aPlayer.Se_Sprite.MoverData.Destination := aFieldPointSpr.Position;

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
        HHFP ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        MouseWaitFor :=  WaitForXY_FKF1; //'Scegli chi batterà il fk1';
        GameScreen := ScreenFreeKick;
        MyBrain.GetGK(MyBrain.TeamTurn).se_sprite.GrayScaled := True; // i gk non possono battere freekick1

    end;
  end
  else if MyBrain.w_FreeKick1  then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkill( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Fka2 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        HHFP ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
        MouseWaitFor := WaitForXY_FKF2; //'Scegli chi batterà il fk2';
        GameScreen := ScreenFreeKick;
        MyBrain.GetGK(MyBrain.TeamTurn).se_sprite.GrayScaled := True; // i gk non possono battere freekick2
    end;
  end
  else if MyBrain.w_Fkd2 then begin

    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      CornerMap := MyBrain.GetCorner (MyBrain.TeamTurn , Mybrain.Ball.CellY, FriendlyCorner );
      HHFP( CornerMap.HeadingCellD [0].X,CornerMap.HeadingCellD [0].Y,0);
      MouseWaitFor := WaitForXY_FKD2;
      GameScreen := ScreenFreeKick;
      MyBrain.GetGK(MyBrain.TeamTurn).se_sprite.GrayScaled := True; // i gk non possono essere cod2
    end;
  end
  else if MyBrain.w_FreeKick2  then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      tcp.SendStr( 'CRO2' + endofline);
    end;
  end
  else if MyBrain.w_Fka3 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      HHFP ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
      MouseWaitFor := WaitForXY_FKF3; //'Scegli chi batterà il fk3';
      GameScreen := ScreenFreeKick;
      MyBrain.GetGK(MyBrain.TeamTurn).se_sprite.GrayScaled := True; // i gk non possono battere freekick3
    end;
  end
  else if MyBrain.w_Fkd3 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      ACellBarrier :=  MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
      HHFP( aCellBarrier.X,  aCellBarrier.Y,0 );
      MouseWaitFor := WaitForXY_FKD3;
      GBIndex := 0;
      GameScreen := ScreenFreeKick;
      MyBrain.GetGK(MyBrain.TeamTurn).se_sprite.GrayScaled := True; // i gk non possono essere barriera
    end;

  end
  else if MyBrain.w_FreeKick3  then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkill( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Fka4 then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      PenaltyCell := MyBrain.GetPenaltyCell ( MyBrain.TeamTurn );
      PenaltySetBall  ;// la ball è già settata su 10,3 o 1,3
      HHFP_Special( PenaltyCell.x,PenaltyCell.Y  ,0 );
      MouseWaitFor := WaitForXY_FKF4; //'Scegli chi batterà il fk4';
      GameScreen := ScreenFreeKick;
      MyBrain.GetGK(MyBrain.TeamTurn).se_sprite.GrayScaled := True; // i gk non possono battere i penalty
    end;
  end
  else if MyBrain.w_FreeKick4  then begin
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      SelectedPlayerPopupSkill( MyBrain.Ball.CellX, MyBrain.Ball.cellY );
    end;
  end
  else if MyBrain.w_Coa then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      aFieldPointSpr := SE_FieldPointsSpecial.FindSprite(IntToStr (MyBrain.Ball.CellX ) + '.' + IntToStr (MyBrain.Ball.CellY ));
      aFieldPointSpr.Visible := True;
      HHFP_Special ( MyBrain.ball.cellx,MyBrain.ball.cellY  ,0 );
      MouseWaitFor := WaitForXY_CornerCOF;
      GameScreen := ScreenFreeKick;
      MyBrain.GetGK(MyBrain.TeamTurn).se_sprite.GrayScaled := True; // i gk non possono battere i corner
    end;
  end
  else if MyBrain.w_Cod then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      CornerMap := MyBrain.GetCorner (MyBrain.TeamTurn , Mybrain.Ball.CellY, FriendlyCorner );
      HHFP( CornerMap.HeadingCellD [0].X,CornerMap.HeadingCellD [0].Y,0);
      MouseWaitFor := WaitForXY_CornerCOD;
      GameScreen := ScreenFreeKick;
      MyBrain.GetGK(MyBrain.TeamTurn).se_sprite.GrayScaled := True; // i gk non possono essere cod sui corner
    end;

  end
  else if MyBrain.w_CornerKick  then begin
    CornerSetBall;
    if MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        tcp.SendStr( 'COR' + endofline);
    end;
  end;

  //devo farlo qui

  if GameScreen = ScreenLive  then begin
    aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
    aSprite.Visible := Mybrain.Score.TeamGuid [  MyBrain.TeamTurn  ]  = MyGuidTeam;
  end;

  if MyBrain.w_CornerSetup or MyBrain.w_CornerKick or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or
    MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4  or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam)  then begin
    SE_TacticsSubs.Visible := False;
    aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
    aSprite.Visible := False;
    aSprite := SE_LIVE.FindSprite('btnmenu_subs');
    aSprite.Visible := False;
    aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
    aSprite.Visible := false;
  end;

  SetGlobalCursor(crHandPoint );

     //if (not AudioCrowd.Playing) and ( not btnAudioStadium.Down) then begin
     // AudioCrowd.Play;
     //end;

end;

procedure  Tform1.SetSelectedPlayer ( aPlayer: TSoccerPlayer);
//var
//  i,L: Integer;
//  aSubSprite : SE_SubSprite;
begin
  fSelectedPlayer := aPlayer;
  HideFP_Friendly_ALL;

{  for i := 0 to se_players.SpriteCount -1 do begin
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
  end;   }

end;
procedure TForm1.RefreshTML;
var
  i: integer;
begin

  SE_Score.RemoveAllSprites('tml');
  SE_Score.ProcessSprites(2000);
  for i := 1 to MyBrain.TeamMovesLeft do begin
    SE_Score.CreateSprite( dir_ball + 'ball2.bmp','tml'+IntToStr(i),1,1,1000,(620+(i-1)*44),YTML,true );
  end;
  if MyBrain.ShpFree > 0 then
    SE_Score.CreateSprite( dir_interface + 'shpfree.bmp','tmlshpfree',1,1,1000,(620+(4*44)),YTML,true );
  SetTmlAlpha;
end;
procedure TForm1.RefreshTML_direct ( TeamMovesLeft, Team, ShpFree : integer ) ;
var
  i: integer;
begin

  SE_Score.RemoveAllSprites('tml');
  SE_Score.ProcessSprites(2000);
  for i := 1 to TeamMovesLeft do begin
    SE_Score.CreateSprite( dir_ball + 'ball2.bmp','tml'+IntToStr(i),1,1,1000,(620+(i-1)*44),YTML,true );
  end;
  if ShpFree > 0 then
    SE_Score.CreateSprite( dir_interface + 'shpfree.bmp','tmlshpfree',1,1,1000,(620+(4*44)),YTML,true );

  SetTmlAlpha;

end;

procedure Tform1.i_tml ( MovesLeft,team: string );
var
  aSprite:  SE_Sprite;
begin

  DontDoPlayers:= False;
  aSprite := SE_Score.FindSprite('scoreminute');
  aSprite.Labels[0].lText := IntToStr(MyBrain.Minute) +'''';
  aSprite.Labels[0].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[0].lText , aSprite.BMP.Width, TStringCenter);
  RefreshTML;

end;
procedure Tform1.refresh_teamnames;
var
  aSprite : SE_Sprite;
  pbSprite : SE_SpriteProgressBar;
begin
  if MyBrain.TeamTurn = 0 then begin
    aSprite := SE_Score.FindSprite('teamname0');
    aSprite.BMP.Canvas.Brush.Color := GetDominantColor(0);
    aSprite.BMP.Canvas.FillRect(Rect(0,0,aSprite.BMP.Width,aSprite.BMP.Height));
    aSprite.Labels[0].lFontColor := GetContrastColor( aSprite.BMP.Canvas.Brush.Color ) ;
    aSprite.Labels[0].lText :=  MyBrain.Score.Team [0];
    aSprite.Visible := True;
    aSprite := SE_Score.FindSprite('teamname1');
    aSprite.Visible := False;
  end
  else begin
    aSprite := SE_Score.FindSprite('teamname1');
    aSprite.BMP.Canvas.Brush.Color := GetDominantColor(1);
    aSprite.BMP.Canvas.FillRect(Rect(0,0,aSprite.BMP.Width,aSprite.BMP.Height));
    aSprite.Labels[0].lFontColor := GetContrastColor( aSprite.BMP.Canvas.Brush.Color ) ;
    aSprite.Labels[0].lText :=  MyBrain.Score.Team [1];
    aSprite.Visible := True;
    aSprite := SE_Score.FindSprite('teamname0');
    aSprite.Visible := False;

  end;
  pbSprite :=  SE_SpriteProgressBar ( SE_Score.FindSprite('scorebartime'));
  pbSprite.BackColor := MyBrain.Score.DominantColor[MyBrain.TeamTurn];
  pbSprite.BarColor := GetContrastColor(MyBrain.Score.DominantColor[MyBrain.TeamTurn]);

  SetTmlAlpha;
end;
procedure Tform1.i_tuc ( team: string );
var
  pbSprite: SE_SpriteProgressBar;
  aSprite: SE_Sprite;
  BackColor, FontColor: TColor;
begin

  while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
    se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
    application.ProcessMessages ;
  end;

  pbSprite :=  SE_SpriteProgressBar ( SE_Score.FindSprite('scorebartime'));
  pbSprite.value := 100;


  Refresh_teamnames;

  RefreshTML;

  SE_TacticsSubs.visible := False;
  aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
  aSprite.Visible :=  Mybrain.Score.TeamGuid [ StrToInt(team) ]  = MyGuidTeam;// Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam;
  aSprite := SE_LIVE.FindSprite('btnmenu_subs');
  aSprite.Visible := Mybrain.Score.TeamGuid [ StrToInt(team) ]  = MyGuidTeam;// Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam;
  aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
  aSprite.Visible := Mybrain.Score.TeamGuid [ StrToInt(team) ]  = MyGuidTeam;// Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  = MyGuidTeam;

  //  if Mybrain.Score.TeamGuid [ StrToInt(team) ] = MyGuidTeam then begin
//    BackColor := GetDominantColor (StrToInt(team));
//    FontColor := GetContrastColor(BackColor);              //UpperCase(Translate('lbl_yourturn'))
 //   CreateSplash (se_theater1.VirtualBitmap.Width div 2,se_theater1.VirtualBitmap.Height div 2,300,32,, 1300,22, FontColor,BackColor, false) ;
//    Sleep(1000);
 // end
 // else begin // avversario
    if not SE_LifeSpan.IsAnySpriteVisible then begin   // SE C'è GIà AD ESEMPIO gol !!!! non mostro finito.
      BackColor := GetDominantColor (StrToInt(team));
      FontColor := GetContrastColor(BackColor);             //UpperCase(Translate('lbl_yourturn'))
      CreateSplash (se_theater1.VirtualBitmap.Width div 2,se_theater1.VirtualBitmap.Height div 2,340,32,MyBrain.Score.Team[StrToInt(team)] , 1300,22, FontColor,BackColor, false) ;
    end;
//  end;
                                                          //UpperCase(Translate('lbl_endturn'))
  if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4 then begin
    SE_TacticsSubs.visible := False;
    aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
    aSprite.Visible := false;
    aSprite := SE_LIVE.FindSprite('btnmenu_subs');
    aSprite.Visible := false;
    aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
    aSprite.Visible := false;
  end;


end;
procedure TForm1.SetTmlAlpha;
var
  pbSprite: SE_SpriteProgressBar;
  aSprite: SE_Sprite;
  i: Integer;
begin
  if (GameScreen = ScreenSpectator) or ((GameScreen = ScreenLive) and ( MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] <> MyGuidTeam )) then begin
    pbSprite :=  SE_SpriteProgressBar ( SE_Score.FindSprite('scorebartime'));
    pbSprite.Alpha := 100;
    pbSprite.BlendMode := SE_BlendAlpha;

    aSprite := SE_Score.FindSprite('teamname0');
    aSprite.Alpha := 100;
    aSprite.BlendMode := SE_BlendAlpha;

    aSprite := SE_Score.FindSprite('teamname1');
    aSprite.Alpha := 100;
    aSprite.BlendMode := SE_BlendAlpha;

    for I := 1 to 4 do begin
      aSprite := SE_Score.FindSprite('tml'+IntToStr(i));
      if aSprite <> nil then begin
        aSprite.Alpha := 100;
        aSprite.BlendMode := SE_BlendAlpha;
      end;
    end;
    aSprite := SE_Score.FindSprite('tmlshpfree');
    if aSprite <> nil then begin
      aSprite.Alpha := 100;
      aSprite.BlendMode := SE_BlendAlpha;
    end;
  end
  else if (GameScreen = ScreenLive) and  ( MyBrain.Score.TeamGuid [ MyBrain.TeamTurn ] = MyGuidTeam ) then begin
    pbSprite :=  SE_SpriteProgressBar ( SE_Score.FindSprite('scorebartime'));
    pbSprite.BlendMode := SE_BlendNormal;

    aSprite := SE_Score.FindSprite('teamname0');
    aSprite.BlendMode := SE_BlendNormal;

    aSprite := SE_Score.FindSprite('teamname1');
    aSprite.BlendMode := SE_BlendNormal;

    for I := 1 to 4 do begin
      aSprite := SE_Score.FindSprite('tml'+IntToStr(i));
      if aSprite <> nil then begin
        aSprite.BlendMode := SE_BlendNormal;
      end;
    end;
    aSprite := SE_Score.FindSprite('tmlshpfree');
    if aSprite <> nil then begin
      aSprite.BlendMode := SE_BlendNormal;
    end;

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
    aPlayer:= MyBrain.GetSoccerPlayerALL(ids);
    MyBrain.PutInReserveSlot(aPlayer); // anticipa quello che farà il server
    MoveInReserves (aPlayer);

end;
procedure Tform1.i_yellow ( ids: string );
begin

    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
//    aPlayer:= MyBrain.GetSoccerPlayer2(ids);

end;
procedure TForm1.ClientLoadMatchInfo;
var
  y: Integer;
  tmp: TStringList;
  bmp: SE_Bitmap;
  aSprite : SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
  BaseY,XScoreFrame,YScoreFrame : integer;
  const Xbmp = 30; XDescr = 60;
begin
  if MyBrain.Finished then begin
    if (MyBrain.Score.TeamGuid[0] = MyGuidTeam) or (MyBrain.Score.TeamGuid[1] = MyGuidTeam) then
      ShowGameOver ( true )
      else ShowGameOver ( false );
  end;
  if MyBrain.MatchInfo.Count = 0 then
    Exit;

  SE_Score.RemoveAllSprites('scoreframemf');
  SE_Score.ProcessSprites(2000);

  aSprite := SE_Score.FindSprite('scorescore');
  XScoreFrame := aSprite.Position.X;
  YScoreFrame := aSprite.Position.Y + aSprite.bmp.Height;

  bmp := SE_Bitmap.Create ( 250, MyBrain.MatchInfo.Count * 22 );// dinamico con aggiunta di spritelabels
  bmp.Bitmap.Canvas.Brush.Color :=  clBlack;
  bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
  aSprite:=SE_Score.CreateSprite(bmp.Bitmap ,'scoreframemf',1,1,1000, XScoreFrame ,YScoreFrame+ (bmp.Height div 2),false );
  aSprite.Priority := 2;
  bmp.Free;

  { parsing della matchinfo }
  tmp := TStringList.Create;
  tmp.Delimiter := '.';
  tmp.StrictDelimiter := True;
  BaseY :=0;
  for y:= 0 to MyBrain.MatchInfo.Count -1 do begin         // es. MyBrain.MatchInfo[y] 19.golprs.454  45.sub.126.138
    tmp.DelimitedText := MyBrain.MatchInfo[y];

    aSpriteLabel := SE_SpriteLabel.create(0,BaseY,'Calibri',clWhite,clblack, 12,tmp[0] + '''',true );
    aSprite.Labels.Add(aSpriteLabel);

    if tmp[1] = 'sub' then begin
      aSprite.AddSubSprite(dir_interface + 'infoinout.bmp','infoinout'+IntToStr(y),Xbmp,BaseY,True );
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, MyBrain.GetSoccerPlayerALL( tmp[2] ).SurName + '--->'+ MyBrain.GetSoccerPlayerALL( tmp[3] ).SurName,true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    else if ( pos ('gol', tmp[1], 1 ) <> 0) and  (  pos ('4', tmp[1], 1 )  = 0)  then begin // gol normali, prs,pos,prs3pos3,gol.volley,gol.crossing
      aSprite.AddSubSprite(dir_interface + 'infogolball.bmp','infogolball'+IntToStr(y),Xbmp,BaseY,True );
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, MyBrain.GetSoccerPlayerALL( tmp[2] ).SurName,true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    else if ( pos ('gol', tmp[1], 1 ) <> 0) and  (  pos ('4', tmp[1], 1 ) <> 0)  then begin // gol su rigore
      aSprite.AddSubSprite(dir_interface + 'infopenaltygol.bmp','infopenaltygol'+IntToStr(y),Xbmp,BaseY,True );
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, MyBrain.GetSoccerPlayerALL( tmp[2] ).SurName,true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    else if ( pos ('4fail', tmp[1], 1 ) <> 0) then begin // rigore fallito
      aSprite.AddSubSprite(dir_interface + 'infopenaltyfail.bmp','infopenaltyfail'+IntToStr(y),Xbmp,BaseY,True );
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, MyBrain.GetSoccerPlayerALL( tmp[2] ).SurName,true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    else if ( pos ('yc', tmp[1], 1 ) <> 0) then begin
      aSprite.AddSubSprite(dir_interface + 'infoyellow.bmp','infoyellow'+IntToStr(y),Xbmp,BaseY,True );
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, MyBrain.GetSoccerPlayerALL( tmp[2] ).SurName,true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    {$IFDEF  TOOLS}
    else if ( pos ('crossbar', tmp[1], 1 ) <> 0) then begin
      aSprite.AddSubSprite(dir_interface + 'infocrossbar.bmp','infocrossbar'+IntToStr(y),Xbmp,BaseY,True);
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12,'', true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    else if ( pos ('corner', tmp[1], 1 ) <> 0) then begin
      aSprite.AddSubSprite(dir_interface + 'infocorner.bmp','infocorner'+IntToStr(y),Xbmp,BaseY,True);
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12,'', true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    else if ( pos ('freekick3', tmp[1], 1 ) <> 0) then begin
      aSprite.AddSubSprite(dir_interface + 'infofreekick3.bmp','infofreekick3'+IntToStr(y),Xbmp,BaseY,True);
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, '' ,true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    else if ( pos ('freekick4', tmp[1], 1 ) <> 0) then begin
      aSprite.AddSubSprite(dir_interface + 'infofreekick4.bmp','infofreekick4'+IntToStr(y),Xbmp,BaseY,True);
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, '' ,true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    else if ( pos ('lastman', tmp[1], 1 ) <> 0) then begin
      aSprite.AddSubSprite(dir_interface + 'infolastman.bmp','infolastman'+IntToStr(y),Xbmp,BaseY,True);
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, '',true );
      aSprite.Labels.Add(aSpriteLabel);
    end
    {$ENDIF TOOLS}
    else if ( pos ('rc', tmp[1], 1 ) <> 0) then begin
      aSprite.AddSubSprite(dir_interface + 'infored.bmp','infored'+IntToStr(y),Xbmp,BaseY,True);
      aSpriteLabel := SE_SpriteLabel.create(XDescr,BaseY,'Calibri',clWhite,clblack, 12, MyBrain.GetSoccerPlayerALL( tmp[2] ).SurName,true );
      aSprite.Labels.Add(aSpriteLabel);
    end;



    BaseY := BaseY + 22;

  end;

  tmp.Free;

end;

procedure Tform1.i_injured ( ids: string );
//var
//  aPlayer: TSoccerPlayer;
begin
    while (MyBrain.GameStarted ) and  (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
//     aPlayer:= MyBrain.GetSoccerPlayer2(ids);
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

  if (tsCmd[0]= 'sc_player')   then begin
    // il player è già posizionato
    AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
  end
  else if (tsCmd[0]='sc_pa') then begin
    AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
   // AnimationScript.Tsadd (  'cl_wait.moving.players' );
  end
  else if tsCmd[0]= 'sc_DICE' then begin
//    TsScript.add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +','+
//    IntTostr(aPlayer.Passing)+',Short.Passing,'+ aPlayer.ids+','+IntTostr(Roll.value) + ',' + Roll.fatigue + '.'+AC+ ',0');
    aPlayer :=  MyBrain.GetSoccerPlayer (  tsCmd[6] );
//    if aPlayer = nil then  asm int 3 ; end;

    AnimationScript.Tsadd ('cl_showroll,' + aPlayer.Ids + ',' + tsCmd[3]  + ',' + tsCmd[5] + ',' + tsCmd[8] );
   // AnimationScript.Tsadd ('cl_wait,' +  IntToStr(ShowRollLifeSpan)); lo aggiungo dopo ogni showroll in firstshowroll
  end
  else if (tsCmd[0]= 'sc_fault')  then begin
    AnimationScript.Tsadd ('cl_fault,' + tsCmd[1]+','+tsCmd[2]+','+tsCmd[3]  );
    AnimationScript.Tsadd ('cl_wait,' +  IntToStr(ShowFaultLifeSpan));
  end
  else if tsCmd[0]= 'sc_ai.movetoball' then begin   // movetoball prima di aimoveall
    AnimationScript.Tsadd ('cl_wait,2000');
  end
  else if tsCmd[0]= 'sc_mtbDICE' then begin
    aPlayer :=  MyBrain.GetSoccerPlayer (  tsCmd[6] );
//    if aPlayer = nil then asm int 3 ; end;
    AnimationScript.Tsadd ('cl_mtbshowroll,' + aPlayer.Ids + ',' + tsCmd[3]  + ',' + tsCmd[5] +',' + tsCmd[8]); // 8= F N , nessun talentid
    AnimationScript.Tsadd ('cl_wait,' +  IntToStr(ShowRollLifeSpan));
  end
  else if tsCmd[0]= 'sc_TML' then begin
    AnimationScript.TsAdd  ( 'cl_tml,' + tsCmd[1] + ','+ tsCmd[2] + ',' + tsCmd[3] );
  end
  else if tsCmd[0]= 'sc_TUC' then begin
    AnimationScript.TsAdd  ( 'cl_tuc,' + tsCmd[1]);
  end
  else if tsCmd[0]= 'sc_fault.cheatballgk' then begin
   AnimationScript.TsAdd  ( 'cl_fault.cheatballgk,' + tsCmd[1] + ',' + tsCmd[2] +',' +tsCmd[3] ); // teamFavour Cellx, celly
    AnimationScript.Tsadd ('cl_wait,' +  IntToStr(ShowFaultLifeSpan));
  end
  else if tsCmd[0]= 'sc_fault.cheatball' then begin
   AnimationScript.TsAdd  ( 'cl_fault.cheatball,' + tsCmd[1] + ',' + tsCmd[2] +',' + tsCmd[3] ); // teamFavour Cellx, celly
    AnimationScript.Tsadd ('cl_wait,'+  IntToStr(ShowFaultLifeSpan));
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


        if tsCmd[0]='sc_ball.move' then begin
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]+','+tsCmd[0]   );
        end
        else if tsCmd[0]='sc_ball.move.offsetx' then begin
          AnimationScript.Tsadd (  'cl_ball.move.offsetx,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_bounce' then begin
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+',0,'+tsCmd[0]);
        end
        else if tsCmd[0]= 'sc_player.move' then begin
          AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
         // AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
         // AnimationScript.Tsadd ('cl_sound,soundtackle');
        end
        else if tsCmd[0]= 'sc_ai.moveall' then begin
          //AnimationScript.Tsadd ('cl_ball.stop' );
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

      PrepareAnim;
      AnimationScript.Tsadd ( 'cl_mainskillused,Short.Passing,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3] + ',' + tsCmd[4] + ',' + tsCmd[5]) ;

      i:=1;
      while tsCmd[0] <> 'E' do begin
          tsCmd.CommaText := Mybrain.tsScript [i];
          LogMemo ( tsCmd.CommaText );

        if tsCmd[0]='sc_ball.move' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(SPEED_BALL_SHP) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6]+','+tsCmd[0]  );

        end
        else if tsCmd[0]='sc_ball.move.offsetx' then begin
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move.offsetx,' + IntTostr(SPEED_BALL_SHP) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]= 'sc_player.move' then begin
          AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
        end
        else if tsCmd[0]='sc_bounce' then begin  // rimbalzo nel caso venga intercettato
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(SPEED_BALL_SHP) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+',0,'+tsCmd[0]);
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

          AnimationScript.Tsadd ('cl_player.priority,'  +  aTackle.ids + ',min');
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] ); // va sulla cella della palla
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));  // aspetto un po'
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );  // torna alla cella di partenza
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell )));
          AnimationScript.Tsadd ('cl_player.priority,'      +  aTackle.ids + ',reset');

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

          AnimationScript.Tsadd ('cl_player.priority,'      +  tsCmd[2] + ',min');
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');

          AnimationScript.Tsadd ('cl_player.move,'      +  exBallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell )));
          AnimationScript.Tsadd ('cl_player.priority,'      +  tsCmd[2] + ',reset');

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
//          exBallPlayer := Mybrain.GetSoccerPlayer(tsCmd[2]); // il player che aveva la palla ma l'ha persa
          AnimationScript.Tsadd ('cl_player.priority,'      +  tsCmd[2] + ',min');
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');

          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] +',' + tsCmd[1]+ ',0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell )));
          AnimationScript.Tsadd ('cl_player.priority,'      +  tsCmd[2] + ',reset');


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

          AnimationScript.Tsadd ('cl_player.priority,'  +  BallPlayer.ids + ',min');
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[3] + ','+tsCmd[4] + ',' + tsCmd[1]+ ',0,'+tsCmd[0] );
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell )));
          AnimationScript.Tsadd ('cl_player.priority,'      +  BallPlayer.ids + ',reset');
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

          AnimationScript.Tsadd ('cl_player.priority,'      +  tsCmd[2] + ',min');
          AnimationScript.Tsadd ('cl_player.move,'   +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell )));
          AnimationScript.Tsadd ('cl_player.priority,'  +  tsCmd[2] + ',reset');
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

          AnimationScript.Tsadd ('cl_player.priority,'      +  tsCmd[2] + ',min');
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell )));
          AnimationScript.Tsadd ('cl_player.priority,'      +  tsCmd[2] + ',reset');
        end


        else if tsCmd[0]= 'sc_yellow' then begin

          AnimationScript.TsAdd  ( 'cl_yellow,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3]);
        end
        else if tsCmd[0]= 'sc_red' then begin
          AnimationScript.TsAdd  ( 'cl_red,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3]);
        end
        else if tsCmd[0]= 'sc_yellowred' then begin
          AnimationScript.TsAdd  ( 'cl_yellowred,' + tsCmd[1] + ',' + tsCmd[2] + ',' + tsCmd[3]);;
        end
        else if tsCmd[0]= 'sc_injured' then begin
          AnimationScript.TsAdd  ( 'cl_injured,' + tsCmd[1]+ ',' + tsCmd[2] + ',' + tsCmd[3]);;
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
        else if tsCmd[0]='sc_ball.move' then begin
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6]+','+tsCmd[0]   );
         // AnimationScript.Tsadd ('cl_wait,' + IntTostr(( 1200)));
        end
        else if tsCmd[0]='sc_ball.move.offsetx' then begin
          AnimationScript.Tsadd (  'cl_ball.move.offsetx,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]='sc_bounce' then begin
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+',0,'+tsCmd[0]);
        end
        else if tsCmd[0]= 'sc_player.move' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
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

        if tsCmd[0]='sc_ball.move' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] + ','+tsCmd[6] +','+tsCmd[0] );
        end
        else if tsCmd[0]='sc_ball.move.offsetx' then begin
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd (  'cl_ball.move.offsetx,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
        end
        else if tsCmd[0]= 'sc_player.move' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
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
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[1]+ ','+tsCmd[0] );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[1]+ ','+tsCmd[0] );

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

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );
        end
        else if tsCmd[0] = 'sc_lop.ballcontrol.bounce.playertoball' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx aFriend
          // 6 celly aFriend
          // 7 cellx  Ball.cellx
          // 8 celly Ball.cellx

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );
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

          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );

        end
        else if tsCmd[0] = 'sc_lop.no' then begin
//             TsScript.add ('sc_lop.no,' + aPlayer.Ids {Lop} + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
//                                                             + ',' + IntTostr(aCell.x)+',' + IntTostr(aCell.y));
          // 1 ids aPlayer
          // 2 cellx aPlayer
          // 3 celly aPlayer
          // 4 cellx  Ball.cellx
          // 5 celly Ball.cellx
          AnimationScript.Tsadd ('cl_sound,soundishot');
          if ((tsCmd[4] = '0') and  (tsCmd[5]='3' )) or ( (tsCmd[4] = '11') and  (tsCmd[5]='3' )) then
            AnimationScript.Tsadd ('cl_ball.move.gk,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[2] + ','+tsCmd[3]+ ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[1]+ ',0' )
          else
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[2] + ','+tsCmd[3]+ ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );
        end
        else if tsCmd[0] = 'sc_lop.ok10' then begin
          // 1 ids aPlayer
          // 2 ids aFriend
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 cellx  Ball.cellx
          // 6 celly Ball.cellx
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );

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

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0,'+tsCmd[0] );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0,'+tsCmd[0]  );
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
          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ','+tsCmd[0] );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0,'+tsCmd[0]  );
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

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,'+tsCmd[0]  );
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

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move.bounce.gk,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,'+tsCmd[9]  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+   ','+tsCmd[3] + ','+ tsCmd[4]  );
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
          // 9 index ccrossbar

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_ball.move.bounce.crossbar,' + IntTostr(DEFAULT_SPEEDMAX_BALL)  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[9]  );
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
          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,volley,'+tsCmd[0]  );

          AnimationScript.Tsadd ('cl_lop.gol,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ','  + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol,'+tsCmd[0]  );
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
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0,'+tsCmd[0]  );
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
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0,'+tsCmd[0]  );
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

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_player.move.half,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));

          AnimationScript.Tsadd ('cl_ball.move.half,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');

          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0,'+tsCmd[0]  );
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
          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move.bounce.gk,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+',0'  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
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
          // 9 index crossbar

          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move.bounce.crossbar,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[9] );
          AnimationScript.Tsadd ('cl_ball.bounce.crossbar,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,'+tsCmd[0]  );
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

          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0,'+tsCmd[0]  );
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

          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_player.move.half,'      +  tsCmd[2] + ',' + tsCmd[5] + ','+tsCmd[6]  +',' + tsCmd[3] + ','+tsCmd[4] );
          AnimationScript.Tsadd ('cl_ball.move.half,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_player.move,'      +  tsCmd[2] + ',' + tsCmd[7] + ','+tsCmd[8]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0,'+tsCmd[0]  );
        end
        else if tsCmd[0] = 'sc_prs.gk' then begin
//                TsScript.add ('sc_prs.gk,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
//                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
//                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  + ','
//                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) );
          // 1 ids aPlayer
          // 2 aGK anOpponent
          // 3 cellx aPlayer
          // 4 celly aPlayer
          // 5 aGK anOpponent
          // 6 aGK anOpponent
          // 7 cellx Ball
          // 8 celly Ball
          // 9 1 or 2 = left right random animation (data for real match)
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move.gk,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,'+tsCmd[0]  );
        end



        else if tsCmd[0]='sc_bounce.heading' then begin  // ids , cellx, celly , dstcellx, dstcelly

//          aPlayer:= Mybrain.GetSoccerPlayer(tsCmd[1]);

          AnimationScript.Tsadd (  'cl_ball.bounce.heading,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]='sc_bounce.gk' then begin
//          aGK := Mybrain.GetSoccerPlayer  ( StrToInt(tsCmd[1]),StrToInt(tsCmd[2]));
          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd (  'cl_ball.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]='sc_bounce.crossbar' then begin
//          aGK := Mybrain.GetSoccerPlayer  ( StrToInt(tsCmd[1]),StrToInt(tsCmd[2]));
          AnimationScript.Tsadd (  'cl_ball.bounce.crossbar,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]);
        end
        else if tsCmd[0]= 'sc_player.move' then begin
          // il player è già posizionato
          AnimationScript.Tsadd (  'cl_player.move,'  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5] );
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

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0,'+tsCmd[0]  );

          AnimationScript.Tsadd ('cl_nextsound,soundreceive');

          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[10] + ','+tsCmd[11]+ ',' + tsCmd[12] + ','+tsCmd[13]+',0,0,'+tsCmd[0]  );

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


          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0,'+tsCmd[0]  );

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
          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_ball.move.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[8]+ ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0'  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
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
          // 14 index crossbar

                 {  TsScript.add ('sc_pos.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) );   }

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_ball.move.bounce.crossbar,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[8]+ ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',' + tsCmd[14] );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
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

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,0,'+tsCmd[0]  );

          if (tsCmd[0] = 'sc_corner.gol') then
            AnimationScript.Tsadd ('cl_corner.gol,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol,'+tsCmd[0]  )
          else if (tsCmd[0] = 'sc_cro2.gol') then
            AnimationScript.Tsadd ('cl_cro2.gol,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,gol,'+tsCmd[0]  );



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
          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ',' + tsCmd[7]+',0,gol,'+tsCmd[0]  );

          AnimationScript.Tsadd ('cl_cross.gol,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[6] + ','+tsCmd[7]+ ',' + tsCmd[10] + ','+ tsCmd[11]+',0,gol,'+tsCmd[0]  );
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
          // 12 CrossBar Index
                 {  TsScript.add ('sc_cross.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) +','+ IntToStr(CrossBarN) );}

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_ball.move.bounce.crossbar,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[6]+ ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+ ','+tsCmd[12]  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
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


          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[6] + ','+tsCmd[7]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_ball.move.bounce.gk,' + IntTostr(DEFAULT_SPEED_BALL) + ',' + tsCmd[6]+ ','+tsCmd[7]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
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

          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[4] + ','+tsCmd[5]+ ',' + tsCmd[8] + ','+tsCmd[9]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');


          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[8] + ','+tsCmd[9]+ ',' + tsCmd[10] + ','+tsCmd[11]+',0,0,'+tsCmd[0]  );

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


          AnimationScript.Tsadd ('cl_nextsound,soundbounce');
          AnimationScript.Tsadd ('cl_sound,soundishot');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+',0,0,'+tsCmd[0]  );
          AnimationScript.Tsadd ('cl_nextsound,soundreceive');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[7] + ','+tsCmd[8]+',0,0,'+tsCmd[0]  );

        end





        else if tsCmd[0]='sc_ball.move' then begin
//     TsScript.add ('sc_ball.move,'+ IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+  IntTostr(aPath[i].X)+','+ IntTostr(aPath[i].Y)
//     +','+anIntercept.Ids+',intercept' ) ;
          AnimationScript.Tsadd ('cl_sound,soundishot');
          if ((tsCmd[1] = '0') and  (tsCmd[2]='3' )) or ( (tsCmd[1] = '11') and  (tsCmd[2]='3' )) then
            AnimationScript.Tsadd ('cl_ball.move.gk,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[1] + ','+tsCmd[2]+ ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5]+ ',0' )
          else
          AnimationScript.Tsadd (  'cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ',' +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]+ ',0,'+tsCmd[0]  );
        end
        else if tsCmd[0]='sc_ball.move.offsetx' then begin
 //        TsScript.add ('sc_ball.move.offsetx,'+ IntTostr(OldBall.X)+','+ IntTostr(OldBall.Y)+','+  IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)
 //        +','+anOpponent.Ids+',stop' ) ;
          AnimationScript.Tsadd ('cl_sound,soundishot');
          if ((tsCmd[1] = '0') and  (tsCmd[2]='3' )) or ( (tsCmd[1] = '11') and  (tsCmd[2]='3' )) then
            AnimationScript.Tsadd ('cl_ball.move.gk,' + IntTostr(DEFAULT_SPEEDMAX_BALL) + ',' + tsCmd[1] + ','+tsCmd[2]+ ',' + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5]+ ',0' )
          else
          AnimationScript.Tsadd (  'cl_ball.move.offsetx,' + IntTostr(DEFAULT_SPEED_BALL) + ','  +  tsCmd[1] + ','+tsCmd[2]+ ','+tsCmd[3] + ','+tsCmd[4]+','+tsCmd[5]+ ','+tsCmd[6]   );
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
          AnimationScript.Tsadd ('cl_fkd2.is,' + tsCmd.CommaText );  // team, fkd2 + swapstring
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
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(1300)); // spritereset arriva troppo presto. devo forzare una pausa
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
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(1300));
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
      AnimationScript.Tsadd ('cl_wait,' + IntTostr(1300));
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
      AnimationScript.Tsadd ('cl_wait,' + IntTostr(1300));
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

          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ',' + tsCmd[3] + ','+tsCmd[4]  +',' + tsCmd[5] + ','+tsCmd[6] );
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[3] + ','+tsCmd[4]+ ',' + tsCmd[5] + ','+tsCmd[6]+ ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  aTackle.ids + ','  + tsCmd[5] + ','+tsCmd[6] +',' + tsCmd[3] + ','+tsCmd[4]  );
          AnimationScript.Tsadd ('cl_wait,' + IntTostr(( sprite1cell)));
          AnimationScript.Tsadd ('cl_sound,soundtackle');
          AnimationScript.Tsadd ('cl_ball.move,' + IntTostr(DEFAULT_SPEED_BALL) + ','  + tsCmd[5] + ','+tsCmd[6] + ',' + tsCmd[7] + ','+tsCmd[8] + ',' + tsCmd[1]+ ',0' );
          AnimationScript.Tsadd ('cl_player.move,'      +  BallPlayer.ids + ','  + tsCmd[5] + ','+tsCmd[6] +','+tsCmd[7] + ','+tsCmd[8]  );
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
  ts : TstringList;
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

 // Imparo subito da cl_tml le mosse rimaste e le metto graficamente a video subito.
  ts := TstringList.Create ;
  for i := AnimationScript.Ts.Count -1 downto 1 do begin
    if LeftStr ( AnimationScript.Ts[i],6) = 'cl_tml' then begin
      ts.CommaText := AnimationScript.Ts[i];
      RefreshTML_direct (  StrToInt( Ts[1]), StrToInt(Ts[2]), StrToInt(Ts[3]) );
      Break;
    end;
  end;
  ts.Free;

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
        AnimationScript.Ts.Insert ( i+1,'cl_wait,' + IntToStr(ShowRollLifeSpan));
        goto retry;
      end;
    end
    else if LeftStr (AnimationScript.Ts[i],16) = 'cl_mainskillused' then begin
      if pos ( 'cl_wait' , AnimationScript.Ts[i+1],1) = 0 then begin
        AnimationScript.Ts.Insert ( i+1,'cl_wait,'+ IntToStr( ShowRollLifeSpan));
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

         // stay non lo mostro, al limite metto una catena
{         if (aPlayer.stay  )  then begin
            if aPlayer.GuidTeam = MyGuidTeam then begin
              SeSprite := se_SubSprite.create ( dir_interface + 'stay.bmp','stay', 0,50,true,true);
              aPlayer.SE_Sprite.SubSprites.Add(SeSprite);
            end;
         end; }

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
        aPlayer.SE_Sprite.DeleteSubSprite('free' );    // lascio FACE
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


procedure TForm1.Anim ( Script: string );
var
  i,rndY,posY: Integer;
  ts: TstringList;
  aPoint: TPoint;
  netgol,head,halfY: Integer;
  aPath: dse_pathPlanner.Tpath;
  aStep: dse_pathPlanner.TpathStep ;
//  aCell,aCell2: TSoccerCell;
  aPlayer,aPlayer2, aTackle, aGK, aBarrierPlayer : TSoccerPlayer;
  aSubSprite: SE_SubSprite;
  srcCellX, srcCellY, dstCellX, dstCellY,Z : integer; // Source e destination Cells
  Dst, TmpX,tmpY: integer;
  CornerMap: TCornerMap;
  aCellBarrier,dstPixel: TPoint;
  sebmp,bmp: SE_Bitmap;
  seSprite: SE_Sprite;
//  ASoccerCellFK, ASoccerCell: TSoccerCell;
  modifierX,ModifierY,visX,visY: integer;
  aFieldPointSpr: SE_Sprite;
  ts8: string;
  aSize:TSize;
  flags: Tstringlist;
  aText : string;
  FontColor,BackColor : TColor; // usate per CreateSplashSscreen
  aString: string;
begin


  ts := TstringList.Create ;
  ts.CommaText := Script;

  if ts[0] = 'cl_showroll' then begin
    //1 aPlayer.ids
    //2 Roll Totale
    //3 Skill used
    //4 N o F e talentid
    MyBrain.Ball.Se_sprite.AnimationInterval := ANIMATION_BALL;
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    flags:= Tstringlist.Create;
    flags.Delimiter :='.';
    flags.DelimitedText := ts[4];
    // i punteggi
    bmp:= Se_bitmap.Create (32,32);
    bmp.Bitmap.Canvas.Brush.color := clRed+1;
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,32,32));
    bmp.Bitmap.Canvas.Brush.color  := GetDominantColor (aPlayer.team);
    bmp.Bitmap.Canvas.Ellipse(0,0,32,32);
    bmp.Bitmap.Canvas.Font.Name := 'Calibri';
    bmp.Bitmap.Canvas.Font.Color := GetContrastColor (bmp.Bitmap.Canvas.Brush.color);
    bmp.Bitmap.Canvas.Font.Size := 12;
//    bmp.Bitmap.Canvas.Brush.Style := bsClear;
    bmp.Bitmap.Canvas.Font.Style := [fsbold];
    bmp.Bitmap.Canvas.Font.Quality := fqAntialiased;

  //  if flags[0] = 'F' then
  //  else        //  'N'
      //bmp.Bitmap.Canvas.Font.color := clWhite-1;
  //    aText := ts[2];


    aText := ts[2];
    case length(  ts[2] ) of
      1: bmp.Bitmap.Canvas.TextOut( 12,8, aText);
      2: bmp.Bitmap.Canvas.TextOut( 10,8, aText);
      3: bmp.Bitmap.Canvas.TextOut( 8,8, aText);
    end;


    if aPlayer.Team = 1 then
      aPlayer.se_sprite.AddSubSprite( bmp,'cl_showroll',32,20, True )
      else aPlayer.se_sprite.AddSubSprite( bmp,'cl_showroll',0,20, True );

    aSubSprite := aPlayer.se_sprite.FindSubSprite('cl_showroll');
    aSubSprite.LifeSpan := ShowRollLifeSpan ;
    bmp.Free;

    if flags[0] = 'F' then begin
      aPlayer.se_sprite.AddSubSprite( dir_interface + 'fatigue.bmp'  ,'fatigue', 16, 16 , true ) ;
      aSubSprite := aPlayer.se_sprite.FindSubSprite('fatigue');
      aSubSprite.LifeSpan := ShowRollLifeSpan ;

    end;
    if flags[1] <> '0' then begin                       // si attiva il talento
      aPlayer.se_sprite.AddSubSprite( dir_talent + flags[1]   +'.bmp'  ,'acl',16,32, true ) ;
      aSubSprite := aPlayer.se_sprite.FindSubSprite('acl');
      aSubSprite.LifeSpan := ShowRollLifeSpan ;
    end;
    flags.Free;

  end
  else if ts[0] = 'cl_mtbshowroll' then begin
    //1 aPlayer.ids
    //2 Roll Totale
    //3 Skill used
    //4 N o F e talentid
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    flags:= Tstringlist.Create;
    flags.Delimiter :='.';
    flags.DelimitedText := ts[4];


    // i punteggi
    bmp:= Se_bitmap.Create (32,32);
    bmp.Bitmap.Canvas.Brush.color := clRed+1;
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,32,32));
    bmp.Bitmap.Canvas.Brush.color  := GetDominantColor (aPlayer.team);
    bmp.Bitmap.Canvas.Ellipse(0,0,32,32);
    bmp.Bitmap.Canvas.Font.Name := 'Calibri';
    bmp.Bitmap.Canvas.Font.Color := GetContrastColor (bmp.Bitmap.Canvas.Brush.color);
    bmp.Bitmap.Canvas.Font.Size := 12;
    bmp.Bitmap.Canvas.Font.Style := [fsbold];
//    bmp.Bitmap.Canvas.Brush.Style := bsClear;
    bmp.Bitmap.Canvas.Font.Quality := fqAntialiased;
    if flags[1] <> '0' then                        // si attiva il talento
      aText := ts[2]+' F'
    else        //  'N'
      aText := ts[2];
    flags.Free;

    case length(  ts[2] ) of
      1: bmp.Bitmap.Canvas.TextOut( 12,8, aText);
      2: bmp.Bitmap.Canvas.TextOut( 10,8, aText);
      3: bmp.Bitmap.Canvas.TextOut( 8,8, aText);
    end;

    if aPlayer.Team = 1 then
      aPlayer.se_sprite.AddSubSprite( bmp,'cl_mtbshowroll',32,20, True )
      else aPlayer.se_sprite.AddSubSprite( bmp,'cl_mtbshowroll',0,20, True );

    aSubSprite := aPlayer.se_sprite.FindSubSprite('cl_mtbshowroll');
    aSubSprite.LifeSpan := ShowRollLifeSpan ;
    bmp.Free;

  end
  else if ts[0] = 'cl_mainskillused' then begin
    //1 skill
    //2 aPlayer.ids
    //3 aPlayer.cellx
    //4 aPlayer.cellY
    //5 cellx         // non sempre
    //6 cellY         // non sempre
    aPlayer := MyBrain.GetSoccerPlayer(ts[2]);
{
    bmp:= Se_bitmap.Create ( aPlayer.se_sprite.BmpCurrentFrame.Width ,14);
    bmp.Bitmap.Canvas.Brush.color := clGray;
    bmp.FillRect(0,0,bmp.Width,bmp.Height,clGray);
    bmp.Bitmap.Canvas.Font.Name := 'Calibri';
    bmp.Bitmap.Canvas.Font.Size := 10;
    bmp.Bitmap.Canvas.Font.Color := clWhite;
    bmp.Bitmap.Canvas.Font.Quality := fqAntialiased;
    bmp.Bitmap.Canvas.Brush.Style := bsSolid;
    bmp.Bitmap.Canvas.TextOut( 1,0, Capitalize(Translate( 'skill_' + ts[1])));
  }


    // la skill usata è un subsprite che si muove con il player in caso di move o tackle
//    aPlayer := MyBrain.GetSoccerPlayer ( Ts[2] );
//    aMainSkillSubSprite := SE_SubSprite.create( bmp,'mainskill',
//      (aPlayer.se_sprite.BmpCurrentFrame.Width div 2) - (bmp.Width div 2) , (aPlayer.se_sprite.BmpCurrentFrame.Height div 2), true,false );
//    aMainSkillSubSprite.LifeSpan := ShowRollLifeSpan + 400;
//    aPlayer.se_sprite.AddSubSprite( aMainSkillSubSprite );
//    bmp.Free;

   // bmp:= Se_bitmap.Create ( dir_skill + Ts[1]+'.bmp');
    //bmp.Stretch(24,24);
    //RoundBorder ( bmp.Bitmap );
   // if aPlayer.Team = 1 then
    aPlayer.se_sprite.AddSubSprite( dir_skill + Ts[1]+'.bmp'  ,'mainskill',
      (aPlayer.se_sprite.BmpCurrentFrame.Width div 2) - 16 , (aPlayer.se_sprite.BmpCurrentFrame.Height div 2), true ) ;
  //  else
  //  aMainSkillSubSprite := SE_SubSprite.create( bmp  ,'mainskill',
   //   (aPlayer.se_sprite.BmpCurrentFrame.Width div 2) - (bmp.Width div 2) , (aPlayer.se_sprite.BmpCurrentFrame.Height div 2), true,true );


  //  bmp.Free;


   // HHFP( StrToInt(Ts[3]), StrToInt(Ts[4]) , ShowRollLifeSpan * 2);
   // HHFP( StrToInt(Ts[5]), StrToInt(Ts[6]) , ShowRollLifeSpan * 2);


   // aFieldPointSpr := SE_FieldPoints.FindSprite( Ts[5] + '.' + Ts[6] );
   // posY := aFieldPointSpr.Position.Y;// - 40;
   // SeSprite := se_numbers.CreateSprite( dir_interface + 'selected.bmp', 'cone', 1, 1, 1000, aFieldPointSpr.Position.X  ,posY , true );
   // SeSprite.LifeSpan := ShowRollDestination;

  end
  else if ts[0] = 'cl_player.priority' then begin
    //1 aPlayer.ids
    //2 min  oppure reset
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    if ts[2] = 'min' then
      aPlayer.se_sprite.Priority := 0
    else if ts[2] = 'reset' then
      aPlayer.se_sprite.Priority := StrToInt( aPlayer.Ids );

   // SE_players.ProcessSprites(2000);
  end
  else if ts[0] = 'cl_pressing' then begin
    //1 aPlayer.ids chi fa il pressing
//    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);

  end
  else if ts[0] = 'cl_protection' then begin
  end

  else if ts[0] = 'cl_sub' then begin

   // sono veramente già swappati sul brain , ma qui ancora no perchè il clientloadbrain ciene caricato dopo questo scritp
    aPlayer:= MyBrain.GetSoccerPlayer2(ts[1]);
    aPlayer2:= MyBrain.GetSoccerPlayer2(ts[2]);
   // sono veramente già swappati quindi la sefield è di aplayer2 , quello che verrà sostituito

    aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr(aPlayer2.CellX )+ '.' + IntToStr(aPlayer2.CellY ) );
    seSprite:= SE_interface.CreateSprite(InOutBitmap.BITMAP ,'inout',1,1,10,aFieldPointSpr.Position.X, aFieldPointSpr.Position.Y,true  );
    seSprite.LifeSpan := ShowFaultLifeSpan;

    BackColor := MyBrain.Score.DominantColor[aPlayer.team];
    FontColor := GetContrastColor(MyBrain.Score.DominantColor[aPlayer.team]);
    CreateSplash (se_theater1.VirtualBitmap.Width div 2,780,260,50, Uppercase(Translate('lbl_Substitution')) , 1300,14, FontColor,BackColor, false) ;

  end
  else if ts[0] = 'cl_tactic' then begin
    aPlayer:= MyBrain.GetSoccerPlayer2(ts[1]);
    BackColor := MyBrain.Score.DominantColor[aPlayer.team];
    FontColor := GetContrastColor(MyBrain.Score.DominantColor[aPlayer.team]);
    CreateSplash (se_theater1.VirtualBitmap.Width div 2,780,260,50, Uppercase(Translate('lbl_Tactic')) , 1300,14, FontColor,BackColor, false) ;

  end
  else if (ts[0] = 'cl_buffd') or (ts[0] = 'cl_buffm') or (ts[0] = 'cl_bufff') then begin
    aPlayer:= MyBrain.GetSoccerPlayer2(ts[1]);
    BackColor := MyBrain.Score.DominantColor[aPlayer.team];
    FontColor := GetContrastColor(MyBrain.Score.DominantColor[aPlayer.team]);
    if ts[0] = 'cl_buffd' then aString := Translate('skill_BuffD')
    else if ts[0] = 'cl_buffm' then aString := Translate('skill_BuffM')
    else if ts[0] = 'cl_bufff' then aString := Translate('skill_BuffF');

    CreateSplash (se_theater1.VirtualBitmap.Width div 2,780,260,50, UpperCase(aString) , 1300,14, FontColor,BackColor, false) ;
  end
  else if ts[0] = 'cl_sound' then begin
    if ts[1]='soundishot' then begin
      playsound ( pchar (dir_sound +  'shot.wav' ) , 0, SND_FILENAME OR SND_ASYNC)
    end
    else if ts[1]='soundtackle' then begin
       playsound ( pchar (dir_sound +  MyBrain.Gender + '_tackle.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
    end;
  end
  else if ts[0]= 'cl_fault' then begin    //  team a favore, cellx, celly
// TsScript.add ('sc_fault,' + aPlayer.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
    aFieldPointSpr := SE_FieldPoints.FindSprite( ts[2]+'.'+ts[3] );
    seSprite:= SE_LifeSpan.CreateSprite(dir_interface + 'faul.bmp' ,'fault',1,1,10,aFieldPointSpr.Position.X, aFieldPointSpr.Position.Y,true  );
    seSprite.LifeSpan := ShowFaultLifeSpan;
    playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);

  end
  else if ts[0]= 'cl_fault.cheatballgk' then begin   // TeamFavour, cerco il portiere avversario
    aFieldPointSpr := SE_FieldPoints.FindSprite( ts[2]+'.'+ts[3] );
    seSprite:= SE_LifeSpan.CreateSprite(dir_interface + 'faulred.bmp' ,'fault',1,1,10,aFieldPointSpr.Position.X, aFieldPointSpr.Position.Y,true  );
    seSprite.LifeSpan := ShowFaultLifeSpan;
    playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);

     // sul server: TsScript.add ('sc_fault.cheatballgk,' + intTostr(TeamFaultFavour) +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo

  end
  else if ts[0]= 'cl_fault.cheatball' then begin  // TeamFavour, cerco la cella della palla
    aFieldPointSpr := SE_FieldPoints.FindSprite( ts[2]+'.'+ts[3] );
    seSprite:= SE_LifeSpan.CreateSprite(dir_interface + 'faulred.bmp' ,'fault',1,1,10,aFieldPointSpr.Position.X, aFieldPointSpr.Position.Y,true  );
    seSprite.LifeSpan := ShowFaultLifeSpan;
    playsound ( pchar (dir_sound +  'faul.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
// sul server:  TsScript.add ('sc_fault.cheatball,' + intTostr(TeamFaultFavour) + ',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo


  end
  else if ts[0] = 'cl_red' then begin

    aFieldPointSpr := SE_FieldPoints.FindSprite( ts[2]+'.'+ts[3] );
    seSprite:= SE_LifeSpan.CreateSprite(dir_interface + 'faulred.bmp' ,'fault',1,1,10,aFieldPointSpr.Position.X, aFieldPointSpr.Position.Y,true  );
    seSprite.LifeSpan := ShowFaultLifeSpan;
    i_red(ts[1]);

  end
  else if ts[0] = 'cl_injured' then begin

    i_injured(ts[1]);
  end
  else if ts[0] = 'cl_yellow' then begin
    aFieldPointSpr := SE_FieldPoints.FindSprite( ts[2]+'.'+ts[3] );
    seSprite:= SE_LifeSpan.CreateSprite(dir_interface + 'faulyellow.bmp' ,'fault',1,1,10,aFieldPointSpr.Position.X, aFieldPointSpr.Position.Y,true  );
    seSprite.LifeSpan := ShowFaultLifeSpan;
    i_Yellow(ts[1]);
  end
  else if ts[0] = 'cl_yellowred' then begin
    // qui doppio cartellino sprite
    aFieldPointSpr := SE_FieldPoints.FindSprite( ts[2]+'.'+ts[3] );
    seSprite:= SE_LifeSpan.CreateSprite(dir_interface + 'faulyellowred.bmp' ,'fault',1,1,10,aFieldPointSpr.Position.X, aFieldPointSpr.Position.Y,true  );
    seSprite.LifeSpan := ShowFaultLifeSpan;
    i_red(ts[1]);

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
     // i_tml ( ts[1], ts[2]); gestita in firstshowroll
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

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aFieldPointSpr.Position;
//    aPlayer.Sprite.NotifyDestinationReached := true;

  end
  else if ts[0] = 'cl_player.speed' then begin
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    aPlayer.Se_Sprite.MoverData.Speed := strToFloat(ts[2]);
  end
  else if ts[0] = 'cl_ball.stop' then begin
 //   MyBrain.Ball.Se_sprite.FrameX :=0;
//    MyBrain.Ball.Se_sprite.FrameXmax :=0;
  end
  else if ts[0] = 'cl_player.move.barrier' then begin

    ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick, MyBrain.Ball.CellX, MyBrain.Ball.cellY)  ; // la cella barriera !!!!
    aFieldPointSpr := SE_FieldPoints.FindSprite(  IntToStr(ACellBarrier.X ) + '.' + IntToStr(ACellBarrier.Y ));

    aBarrierPlayer := MyBrain.GetSoccerPlayer(ts[1]);
    aBarrierPlayer.SE_Sprite.Scale := ScaleSpritesBarrier;
    aBarrierPlayer.SE_Sprite.MoverData.Destination := Point (aFieldPointSpr.Position.X + BarrierPosition[BIndex].X , aFieldPointSpr.Position.Y + BarrierPosition[BIndex].Y);
    inc (BIndex);
    //    aBarrierPlayer.SE_Sprite.Position := Point (aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y + rndY);
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

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aFieldPointSpr.Position;
//    aPlayer.Sprite.NotifyDestinationReached := true;
  end
  else if ts[0] = 'cl_player.move.half' then begin
    //1 aList[i].Ids
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    srcCellX :=  StrToInt(Ts[2]);
    srcCellY :=  StrToInt(Ts[3]);
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(ts[1]);
      {  fare half verso il centro. se team 0 difende +32 altriemnti -32. verso la cella di chi calcia }
    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (srcCellX ) + '.' + IntToStr (srcCellY));
    if srcCellY > dstCellY then halfY := -32
    else if srcCellY < dstCellY then halfY := +32
    else halfY :=0;

    if aPlayer.Team = 0 then begin

      aPlayer.se_sprite.MoverData.Destination := Point(aFieldPointSpr.Position.X +32, aFieldPointSpr.Position.Y+halfy);
    end
    else begin
      aPlayer.se_sprite.MoverData.Destination := Point(aFieldPointSpr.Position.X -32, aFieldPointSpr.Position.Y+halfy);
    end;

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

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aFieldPointSpr.Position;

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

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    aPlayer.se_sprite.MoverData.Destination := aFieldPointSpr.Position;

  end
  else if ts[0] = 'cl_ball.move.bounce.crossbar' then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 numero per dire quale angolo
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer( dstCellX, dstCellY ); // è un GK

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    SetBallRotation ( StrToInt(ts[2]),StrToInt(ts[3]),StrToInt(ts[4]),StrToInt(ts[5]) ) ;


    aFieldPointSpr := SE_ball.FindSprite( 'door' + IntTostr(aPlayer.Team) );
    dstPixel := Point (aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y );
    // arriva per forza a un gk. x va bene. faccio riferimento allo sprite door0 o 1
    dstPixel.Y := dstPixel.Y + CrossBarN [StrToInt(Ts[6])]; // riferimento relativo allo sprite door


    Mybrain.Ball.se_sprite.MoverData.Destination := dstPixel;

  end
  else if ts[0] = 'cl_nextsound' then begin
    Mybrain.Ball.Se_sprite.sTag := ts[1];
  end
  else if ts[0] = 'cl_ball.move.half' then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY

    srcCellX :=  StrToInt(Ts[2]);
    srcCellY :=  StrToInt(Ts[3]);
    if srcCellY > dstCellY then halfY := +32
    else if srcCellY < dstCellY then halfY := -32
    else halfY :=0;
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);
    aPlayer := MyBrain.GetSoccerPlayer(dstCellX,dstCellY); // è un difensore

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    SetBallRotation ( StrToInt(ts[2]),StrToInt(ts[3]),StrToInt(ts[4]),StrToInt(ts[5]) ) ;

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    if aPlayer.Team = 0 then
      Mybrain.Ball.se_sprite.MoverData.Destination := Point(aFieldPointSpr.Position.X +32, aFieldPointSpr.Position.Y+halfy)
    else Mybrain.Ball.se_sprite.MoverData.Destination := Point(aFieldPointSpr.Position.X -32, aFieldPointSpr.Position.Y+halfy)


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
    SetBallRotation ( StrToInt(ts[2]),StrToInt(ts[3]),StrToInt(ts[4]),StrToInt(ts[5]) ) ;

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    ts8 := ts[8];
    if ContainsText ( ts8 ,'gol') then begin
      case dstCellX of
        0: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aFieldPointSpr.Position.X -PixelsGolDeep , aFieldPointSpr.Position.Y ) ; // forza il calculateVectors
        end;
        11: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point( aFieldPointSpr.Position.X +PixelsGolDeep , aFieldPointSpr.Position.Y ) ; // forza il calculateVectors
        end;
      end;
    end;
    Mybrain.Ball.se_sprite.MoverData.Destination := aFieldPointSpr.Position;
    if (ContainsText ( ts8,'sc_corner') ) or ( ContainsText ( ts8,'sc_cross') ) then begin
      Mybrain.Ball.se_sprite.MoverData.PartialList := '10,20,30,40,50,60,70,80,90';
    end;

  end
  else if  ts[0] = 'cl_ball.move.gk' then begin // diretta sul Gk
          // 1 Speed
          // 2 cellx aPlayer
          // 3 celly aPlayer
          // 4 cellx aGK
          // 5 celly aGK
          // 7 ..
          // 8 ...
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    SetBallRotation ( StrToInt(ts[2]),StrToInt(ts[3]),StrToInt(ts[4]),StrToInt(ts[5]) ) ;
      { TODO : bug qui }
    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    dstPixel := Point (aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y );

    if dstCellX = 0 then // arriva per forza a un gk
      dstPixel.X := dstPixel.X + PixelsGKTake
      else if dstCellX = 11 then
      dstPixel.X := dstPixel.X - PixelsGKTake;
    Mybrain.Ball.se_sprite.MoverData.Destination := dstPixel;
  end
  else if  ts[0] = 'cl_ball.move.bounce.gk' then begin
          // 1 Speed
          // 2 cellx aPlayer
          // 3 celly aPlayer
          // 4 cellx aGK
          // 5 celly aGK
          // 7 ..
          // 8 ...
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    SetBallRotation ( StrToInt(ts[2]),StrToInt(ts[3]),StrToInt(ts[4]),StrToInt(ts[5]) ) ;

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    dstPixel := Point (aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y );
    if dstCellX = 0 then // arriva per forza a un gk
      dstPixel.X := dstPixel.X + 32
      else if dstCellX = 11 then
      dstPixel.X := dstPixel.X - 32;
    Mybrain.Ball.se_sprite.MoverData.Destination := dstPixel;

  end
  else if  (ts[0] = 'cl_ball.bounce') or (ts[0] = 'cl_ball.bounce.heading') or (ts[0] = 'cl_ball.bounce.back')
     or (ts[0] = 'cl_ball.bounce.crossbar') or (ts[0] = 'cl_ball.bounce.gk')
    then begin
    //1 Speed
    //2 aList[i].CellX     // cella di partenza
    //3 aList[i].CellY
    //4 CellX              // cella di arrivo
    //5 CellY
    //6 Player CellX
    //7 Player CellY

   //QUI tsCmd [4] e tsCmd [5] indicano la cella di uscita - MyBrain.,ball è già sulla cella del corner

    if (ts[0] = 'cl_ball.bounce') or (ts[0] = 'cl_ball.bounce.heading') or (ts[0] = 'cl_ball.bounce.back') then begin
      playsound ( pchar (dir_sound +  'bounce.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
    end

    else if (ts[0] = 'cl_ball.bounce.gk') or (ts[0] = 'cl_ball.bounce.crossbar') then  begin
      playsound ( pchar (dir_sound +  'nogol.wav' ) , 0, SND_FILENAME OR SND_ASYNC);
    end;

//    (ts[0] = 'cl_ball.bounce.crossbar') <-- gestita in se_ball.destinationreached
    dstCellX :=  StrToInt(Ts[4]);
    dstCellY :=  StrToInt(Ts[5]);

//    CornerMap := MyBrain.GetCorner ( MyBrain.TeamCorner ,  dstCellY, OpponentCorner );

    Mybrain.Ball.SE_Sprite.MoverData.Speed := StrToFloat (Ts[1]);
    SetBallRotation ( StrToInt(ts[2]),StrToInt(ts[3]),StrToInt(ts[4]),StrToInt(ts[5]) ) ;

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
    if aFieldPointSpr = nil then  // se non rimbalza in campo , è una cella fuori dal campo
    aFieldPointSpr := SE_FieldPointsOut.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));

    dstPixel := Point (aFieldPointSpr.Position.X , aFieldPointSpr.Position.Y );
    Mybrain.Ball.se_sprite.MoverData.Destination := dstPixel;


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

    aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (dstCellX ) + '.' + IntToStr (dstCellY ));
      case dstCellX of
        0: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point(  aFieldPointSpr.Position.X - PixelsGolDeep , aFieldPointSpr.Position.Y);
          BackColor := MyBrain.Score.DominantColor[0];
          FontColor := GetContrastColor(MyBrain.Score.DominantColor[0]);
        end;
        11: begin
          Mybrain.Ball.se_sprite.MoverData.Destination := Point(  aFieldPointSpr.Position.X + PixelsGolDeep, aFieldPointSpr.Position.Y);
          BackColor := MyBrain.Score.DominantColor[1];
          FontColor := GetContrastColor(MyBrain.Score.DominantColor[1]);
        end;
      end;
      CreateSplash (se_theater1.VirtualBitmap.Width div 2,se_theater1.VirtualBitmap.Height div 2,400,200, 'GOL !!!', 2000,24, FontColor,BackColor, false) ;

  end
  else if ts[0]= 'cl_splash.gameover' then begin
    ClientLoadMatchInfo;
    Sleep(2000);
    AnimationScript.Reset ;
    if LiveMatch then begin
      ShowGameOver ( true );
      LiveMatch := False;
    end
    else if ViewMatch then begin
      ShowGameOver ( false );
    end;

  end
// da qui in poi carico prima il brain
  else if ts[0]= 'cl_corner.coa' then begin   // richiede un coa , mostro lo splash corner
      // teamturn e corner , cornerx cornery

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
    SE_Skills.Visible := False;
     // Cl_BrainLoaded := true;
     // ClientLoadBrainSE(dir_data + Format('%.*d',[3, MyBrain.incMove+1]) + '.ini'); // forzo la lettura del brain, devo sapere adesso

      tscoa.Clear;
      //CreateSplash ('Corner',msSplashTurn);


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


  end
  else if ts[0]= 'cl_freekick2.fka2' then begin   // richiede un fka2 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;


  end

  else if ts[0]= 'cl_freekick3.fka3' then begin   // richiede un fka3 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;


  end

  else if ts[0]= 'cl_freekick4.fka4' then begin   // richiede un fka4 , mostro lo splash corner

    while (MyBrain.GameStarted ) and (se_players.IsAnySpriteMoving ) do begin
      se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
      application.ProcessMessages ;
    end;
      tscoa.Clear;
      tscod.clear;

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


  end;

  ts.free;
  Application.ProcessMessages ;



end;
procedure TForm1.SetBallRotation ( X1,Y1,X2,Y2: integer ) ;
begin
  Mybrain.Ball.SE_Sprite.Destinationreached:= false;
  Mybrain.Ball.SE_Sprite.NotifyDestinationReached := true;
  Mybrain.Ball.SE_Sprite.AnimationInterval := ANIMATION_BALL;

  if X1 < X2 then begin
    Mybrain.Ball.SE_Sprite.AnimationDirection := dirForward;
  end
  else if X1 > X2 then begin
//    Mybrain.Ball.SE_Sprite.FrameXmax := 0 ;
    Mybrain.Ball.SE_Sprite.AnimationDirection := dirBackward;
  end
  else if X1 = X2 then begin
    Mybrain.Ball.SE_Sprite.FrameXmax := 0 ;
  end;


end;
procedure TForm1.btnConfirmSellClick(Sender: TObject);
  var
  i,tGK: Integer;
  aPlayer: TSoccerPlayer;
begin
  if GCD <= 0 then begin
    aPlayer:=  MyBrainformation.GetSoccerPlayerALL (IntToStr(SE_BackGround.Tag));
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
      tcp.SendStr( 'sell,'+ IntToStr(SE_BackGround.Tag)  + ',' + edtSell.Text + EndofLine); // solo a sinistra in formation
  end;


end;

procedure TForm1.btnErrorOKClick(Sender: TObject);
begin
  PanelError.Visible := False;
  PanelBuy.Visible := False;
  PanelSell.Visible := False;
  PanelDismiss.Visible := False;
  if lastStrError = 'errorlogin' then
    PanelLogin.Visible := True
    else if lastStrError = 'marketbuy_player_not_found' then
      tcp.SendStr( 'market,' +  IntToStr(MaxInt)  + EndofLine)
      else tcp.SendStr( 'getformation' + EndofLine);

 // if lbl_Error.Caption = ( Uppercase (Translate('lbl_endgame'))) then
 //   GameScreen := ScreenFormation;

end;


function TForm1.isTvCellFormation ( Team, CellX, CellY: integer ): boolean;
begin
  Result := False;
  case team of
    0: if ((CellX = 0) and (CellY=3)) or ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) then Result:= True;
    1: if ((CellX = 11) and (CellY=3)) or ((CellX = 9)  or  (CellX = 6) or (CellX = 3))  then Result:= True;
  end;

end;
procedure TForm1.MoveInField ( aPlayer: TSoccerPlayer );
var
  aFieldPoint: SE_Sprite;
begin

   aFieldPoint := SE_FieldPoints.FindSprite(IntToStr (aPlayer.Cellx ) + '.' + IntToStr (aPlayer.Celly ));
   aPlayer.se_sprite.MoverData.speed:=20;
   aPlayer.se_sprite.MoverData.Destination := aFieldPoint.Position;

end;
procedure TForm1.MoveInReserves ( aPlayer: TSoccerPlayer );
var
  aFieldPoint: SE_Sprite;
begin
   if aPlayer.Team = 0 then begin
     aFieldPoint := SE_FieldPointsReserve.FindSprite(IntToStr (aPlayer.Cellx ) + '.' + IntToStr (aPlayer.Celly ));
     aPlayer.se_sprite.MoverData.speed:=20;
     aPlayer.se_sprite.MoverData.Destination := aFieldPoint.Position;
   end
   else begin
     aFieldPoint := SE_FieldPointsReserve.FindSprite(IntToStr (aPlayer.Cellx+11 ) + '.' + IntToStr (aPlayer.Celly ));
     aPlayer.se_sprite.MoverData.speed:=20;
     aPlayer.se_sprite.MoverData.Destination := aFieldPoint.Position;

   end;

end;
procedure TForm1.CancelDrag ( aPlayer: TsoccerPlayer; ResetCellX, ResetCellY: integer );
var
  aFieldPointSpr : SE_Sprite;
begin
  if SE_DragGuid <> nil then begin
    if ResetCellY < 0 then begin
      if ( GameScreen = ScreenLive ) and  (aPlayer.Team = 1) then // se gioco a destra
        aFieldPointSpr := SE_FieldPointsReserve.FindSprite(IntToStr (ResetCellX+11 ) + '.' + IntToStr (ResetCellY ))
        else aFieldPointSpr := SE_FieldPointsReserve.FindSprite(IntToStr (ResetCellX ) + '.' + IntToStr (ResetCellY ));
    end
    else
      aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (ResetCellX ) + '.' + IntToStr (ResetCellY ));


    aPlayer.se_sprite.MoverData.speed:=20;
    aPlayer.SE_Sprite.MoverData.Destination := aFieldPointSpr.Position ;
    se_dragGuid.DeleteSubSprite('surname');
    SE_DragGuid := nil;

  end;
  SE_interface.RemoveAllSprites;

end;
procedure Tform1.HideFP_Friendly_ALL;
begin
  HideFP_Friendly;
  HideFP_Reserve;
  HideFP_GK;
end;
procedure Tform1.HHFP ( CellX, CellY, LifeSpan : integer);
var
  aFieldPoint : SE_Sprite;
begin
  if not IsOutSide(CellX,CellY) then begin
    aFieldPoint := SE_FieldPoints.FindSprite(IntToStr (CellX ) + '.' + IntToStr (CellY ));
    aFieldPoint.Visible := True;
  end;
end;
procedure Tform1.HHFP_Special ( CellX, CellY, LifeSpan : integer);
var
  aFieldPoint : SE_Sprite;
begin
  aFieldPoint := SE_FieldPointsSpecial.FindSprite(IntToStr (CellX ) + '.' + IntToStr (CellY ));
  aFieldPoint.Visible := True;
end;
procedure Tform1.HHFP_Reserve ( aPlayer: TSoccerPlayer );
var
  i: Integer;
begin
  for I := 0 to SE_fieldPointsReserve.SpriteCount -1 do begin
    SE_fieldPointsReserve.Sprites [i].Visible := false;
  end;
end;

procedure Tform1.HHFP_GK ;
var
  aFieldPoint : SE_Sprite;
begin
  aFieldPoint := SE_FieldPoints.FindSprite('0.3');
  aFieldPoint.Visible := True;
end;
procedure Tform1.HideFP_GK ;
var
  aFieldPoint : SE_Sprite;
begin
  aFieldPoint := SE_FieldPoints.FindSprite('0.3');
  aFieldPoint.Visible := false;
end;
procedure Tform1.HHFP_Friendly ( aPlayer: TSoccerPlayer; cells: char );
var
  i,Y,CellX: integer;
  aFieldPointSpr : SE_Sprite;
  bmp: SE_Bitmap;
  aPlayer2: TSoccerPlayer;
begin

  // mostro il subsprite di un colore verde più chiaro

  if cells= 'b' then begin // solo sostituzioni , illumino solo possibili compagni da sostituire tenendo conto del GK
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
      aPlayer2 := MyBrain.lstSoccerPlayer[i];
      if aPlayer2.Team = aPlayer.Team  then begin
        if (aPlayer.TalentID1 = TALENT_ID_GOALKEEPER) and (aPlayer2.TalentID1 = TALENT_ID_GOALKEEPER) then begin
          aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
          aFieldPointSpr.Visible := true;
        end
        else if (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER) and (aPlayer2.TalentID1 <> TALENT_ID_GOALKEEPER) then begin
          aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
          aFieldPointSpr.Visible := true;
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
            aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
            aFieldPointSpr.Visible := true;
          end
          else if (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER ) and (aPlayer2.TalentId1 <> TALENT_ID_GOALKEEPER) then begin

            aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr ( aPlayer2.CellX ) + '.' + IntToStr (aPlayer2.CellY ));
            aFieldPointSpr.Visible := true;
          end
        end;
      end;
    end;
  end

  else if cells = 'f' then begin // solo celle libere e del proprio team formation
    for CellX := 1 to 10 do begin
      for Y := 0 to 6 do begin
        aPlayer2 := MyBrain.GetSoccerPlayerDefault( CellX, Y );
        if aPlayer2 <> nil then Continue; // skip cella occupata da player
        if ((CellX = 0)  and (Y = 3)) or ((CellX = 11)  and (Y = 3)) then Continue; // tactic non permessa sulla cella portiere

        aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr ( CellX ) + '.' + IntToStr (Y ));


        if ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team = 0) then begin

            aFieldPointSpr.Visible := true;
        end
        else if ( (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team = 1) then begin

            aFieldPointSpr.Visible := true;

        end;

      end;

    end;
  end

  else if cells = 't' then begin // celle libere o occupate del proprio team formation
    for CellX := 1 to 10 do begin
      for Y := 0 to 6 do begin
        //aPlayer2 := MyBrain.GetSoccerPlayerDefault( CellX, Y );
        //if aPlayer2 <> nil then Continue; // skip cella occupata da player

        if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin   // non è un  goalkeeper

          if ((CellX = 0)  and (Y = 3)) or ((CellX = 11)  and (Y = 3)) then Continue; // tactic non permessa sulla cella portiere

          aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr ( CellX ) + '.' + IntToStr (Y ));


          if ((CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team = 0) then begin
            aFieldPointSpr.Visible := true;
          end
          else if ( (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team = 1) then begin
            aFieldPointSpr.Visible := true;

          end;

        end
        else begin  //  è un  goalkeeper

          if aPlayer.Team = 0 then begin
            aFieldPointSpr := SE_FieldPoints.FindSprite( '0.3');
          end
          else begin
            aFieldPointSpr := SE_FieldPoints.FindSprite( '11.3');
          end;

            aFieldPointSpr.Visible := true;

        end;

      end;

    end;
  end
  else if cells = 'r' then begin // celle libere o occupate del proprio team formation
    for CellX := 0 to 21 do begin
      aFieldPointSpr := SE_FieldPointsReserve.FindSprite(IntToStr ( CellX ) + '.-1');
      aFieldPointSpr.Visible := true;
    end;
  end;

  bmp.Free;
end;
procedure Tform1.HideFP_Special;
var
  i: Integer;
begin
  for I := 0 to SE_fieldPointsSpecial.SpriteCount -1 do begin
    SE_fieldpointsSpecial.Sprites [i].Visible := false;
  end;
end;
procedure Tform1.HideFP_Friendly;
var
  i: Integer;
begin
  for I := 0 to SE_fieldPoints.SpriteCount -1 do begin
    SE_fieldpoints.Sprites [i].Visible := false;
  end;
end;
procedure Tform1.HideFP_Reserve;
var
  i: Integer;
begin
  for I := 0 to SE_fieldPointsReserve.SpriteCount -1 do begin
    SE_fieldPointsReserve.Sprites [i].Visible := false;
  end;
end;

procedure TForm1.hidechances;
begin
   //for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
   // MyBrain.lstSoccerPlayer [i].SE_Sprite.Labels.Clear;
   //end;

   SE_interface.removeallSprites;
   SE_interface.ProcessSprites(2000);
   HideFP_Friendly_ALL;


end;
procedure TForm1.ShowGreen ( CellX,CellY:Integer);
var
  aFieldPoint,aGreen: SE_Sprite;
begin
   aFieldPoint:= SE_FieldPoints.FindSprite(IntToStr (CellX ) + '.' + IntToStr (CellY ));
   aGreen := SE_Green.FindSprite('green');
   aGreen.Position := aFieldPoint.Position;
   aGreen.Visible := True;
   SE_Green.Visible := True;
   MouseWaitFor := WaitForGreen;

end;
procedure Tform1.SelectedPlayerPopupSkill ( CellX, CellY: integer);
var
  i,BaseY,BaseX,TotalWidth,visX,visY: integer;
  tmp: integer;
  aList : TObjectList<TSoccerPlayer>;
  aSprite: SE_Sprite;
  aSpriteLabel : SE_SpriteLabel;
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
    WaitForXY_SetPlayer: exit;
  end;


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
//  SelectedPlayer.ActiveSkills.Add('Pass=0');
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

  // vecchia versione
  BaseY := 0;
  SE_Skills.RemoveAllSprites;
  SE_Skills.ProcessSprites(2000);
 { for I := 0 to SelectedPlayer.ActiveSkills.count -1 do begin
    bmp := SE_Bitmap.Create ( 140,22 );
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect(0,0,bmp.Width,bmp.Height));
    aSprite := SE_Skills.CreateSprite ( Bmp.Bitmap,SelectedPlayer.ActiveSkills.Names [i],1,1,1000,
                SelectedPlayer.SE_Sprite.Position.X,SelectedPlayer.SE_Sprite.Position.Y + (SelectedPlayer.SE_Sprite.BMP.Height div 2 )+10+BaseY,False); // IDS contiene il nome della skill originale (English)
    aSprite.BlendMode := SE_BlendAlpha;
    aSprite.Alpha := 200;
    bmp.Free;
    //Qui 2 spriteLabel , una con il Translate della Skill, l'altra con il valore . left 0 e un altro fisso
    aSpriteLabel := SE_SpriteLabel.create(0,0,'Calibri',clWhite,clBlack,12,Translate( 'skill_' + SelectedPlayer.ActiveSkills.Names [i]),True );// tradotta
    aSprite.Labels.add(aSpriteLabel);
    if SelectedPlayer.ActiveSkills.ValueFromIndex [i] <> '0' then begin
      aSpriteLabel := SE_SpriteLabel.create(120,0,'Calibri',clWhite,clBlack,12,SelectedPlayer.ActiveSkills.ValueFromIndex [i],True );// il valore
      aSprite.Labels.add(aSpriteLabel);
    end;

    if (aSprite.Guid = 'Stay') or (aSprite.Guid = 'Free') then begin
      aSprite.Labels[0].lFontColor := clSilver;
     // aSprite.Labels[1].lFont.Color := clSilver;
    end;
    BaseY := BaseY + 22;
  end;  }
  SE_Skills.RemoveAllSprites;
  SE_Skills.ProcessSprites(2000);
  BaseY := 764;
  BaseX := 1440 div 2;//720

  TotalWidth := 32 * SelectedPlayer.ActiveSkills.count;
  BaseX := BaseX  - (TotalWidth Div 2) + 16;


  for I := 0 to SelectedPlayer.ActiveSkills.count -1 do begin

    aSprite := SE_Skills.CreateSprite ( dir_skill + SelectedPlayer.ActiveSkills.Names [i]+'.bmp',SelectedPlayer.ActiveSkills.Names [i],1,1,1000,
                BaseX,BaseY,true); // IDS contiene il nome della skill originale (English)

    BaseX := BaseX + 32;//26
  end;
  SE_Skills.Visible := True;

  {$IFDEF  tools}
    aSprite := SE_Skills.CreateSprite (  dir_skill + 'setplayer.bmp','setplayer',1,1,1000, BaseX,BaseY,true);
  {$endif}

end;

procedure TForm1.SE_Theater1TheaterMouseDown(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Button: TMouseButton;
  Shift: TShiftState);
begin
  if GameScreen = ScreenLive then begin
    if Button = MbRight then begin

      if SE_DragGuid <> nil then begin
        se_dragGuid.DeleteSubSprite('surname');
        SE_DragGuid := nil;
      end;
      HideFP_Friendly_ALL;
      MouseWaitFor := WaitForNone;
      hidechances ;
      SE_Green.Visible := false;
      SE_Skills.Visible := False;

      if SelectedPlayer <> nil then
        SelectedPlayer.se_sprite.DeleteSubSprite('mainskill' );

      Exit;
    end;
  end;

end;

procedure TForm1.SE_Theater1TheaterMouseMove(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Shift: TShiftState);
begin
  if (se_dragGuid <> nil) then begin
    se_dragGuid.MoverData.Destination := Point(VirtualX,VirtualY);
    se_dragGuid.Position := Point (VirtualX,VirtualY);
  end;
end;

procedure TForm1.SE_Theater1TheaterMouseUp(Sender: TObject; VisibleX, VisibleY, VirtualX, VirtualY: Integer; Button: TMouseButton;  Shift: TShiftState);
var
  i: integer;
  GlobalFieldPointsSpr: TObjectList<SE_Sprite>;
  aPlayer,aPlayer2: TSoccerPlayer;
  aFieldPointSpr: SE_Sprite;
  AICell,aCell,aCell2,OldReserveCell: TPoint;
  label reserve;
begin
// qui passano solo mouseup da screenformation. è gestita conm proximity. altri mouseup passano da spritemouseup ( tactics e subs )

  if (GameScreen = ScreenFormation) and ( Button = mbLeft) then begin
  // se drag non è nil cerco la cella più vicina tra celle di campo e riserve. le ordino per distance dalla position. e lo assegno.
  // se è una cella non della propria formazione non faccio nulla.
    if Se_DragGuid = nil then Exit;

    aPlayer := findPlayerMyBrainFormation (Se_DragGuid.Guid);
    GlobalFieldPointsSpr:= TObjectList<SE_Sprite>.Create(false);
    for I := 0 to SE_FieldPoints.SpriteCount -1 do begin
    // se non è il GK escludo quella cella.
      if aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER then Begin
        if (SE_FieldPoints.Sprites[i].Guid = '0.3') or (SE_FieldPoints.Sprites[i].Guid = '0.11') then Continue;

        // solo del mio team , sono in screenformation
        aCell := FieldGuid2Cell ( SE_FieldPoints.Sprites[i].guid);
        if (aCell.X = 0) or (aCell.X = 2)  or  (aCell.X = 5) or (aCell.X = 8) then
        GlobalFieldPointsSpr.Add( SE_FieldPoints.Sprites[i] );

      end
      else begin
    // se è il GK aggiungo solo quella celle e le riserve.
        if (SE_FieldPoints.Sprites[i].Guid = '0.3') then begin
          GlobalFieldPointsSpr.Add( SE_FieldPoints.Sprites[i] );
          Break;
        end;
      end;

    end;
    // aggiungo tutte le riserve
    for I := 0 to SE_FieldPointsReserve.SpriteCount -1 do begin
      GlobalFieldPointsSpr.Add( SE_FieldPointsReserve.Sprites[i] );
    end;
    // ScreenFormation, tutte le celle di campo del proprio team , gestione portiere, e tutte le riserve. Ordino GlobalFieldPointsSpr
    // in base alla distanza dalle coords del mouse. La distanza deve essere minore di sprite.width, altrimenti sono lontano da tutto
    // e lo rimetto nelle riserve nel primo posto libero
    GlobalFieldPointsSpr.sort(TComparer<SE_Sprite>.Construct(
    function (const L, R: SE_Sprite): integer
    begin
      Result := AbsDistance( VirtualX, VirtualY, L.Position.X, L.Position.Y )  -  AbsDistance( VirtualX, VirtualY, R.Position.X, R.Position.Y )
    end
       ));
    aCell2 := FieldGuid2Cell ( GlobalFieldPointsSpr[0].guid);

    if AbsDistance( VirtualX, VirtualY, GlobalFieldPointsSpr[0].Position.X, GlobalFieldPointsSpr[0].Position.Y ) <= ProximityMouse then begin
      // muovo lo sprite nella nuova cella
      SE_DragGuid.MoverData.Destination := GlobalFieldPointsSpr[0].Position;
      SE_DragGuid.Position := GlobalFieldPointsSpr[0].Position;


      // Può essere da riserva a riserva. da riserva a cella libera.
      // da riserva a player. da player a player. da player a riserva. da player a cella libera.
//       se c'è un player in quella posizione lo sposto nelle riserve.
       aPlayer2 := MyBrainFormation.GetSoccerPlayerALL ( aCell2.X, aCell2.Y);

       // qui arrivo a dal campo o dalle riserve e trovo un player (sul campo o nelle riserve )
       if aPlayer2 <> nil then begin
         if aPlayer2.ids <> se_DragGuid.guid then begin // se non è trascinato e rilasciato su sè stesso
          if MyBrainformation.isReserveSlot( aPlayer.CellX, aPlayer.CellY) then begin // se arriva dalle riserve. se se_draguid è un panchinaro
            if MyBrainformation.isReserveSlot( aPlayer2.CellX, aPlayer2.CellY)  then begin// se la destinazione è una riserva
              MyBrainFormation.SwapPlayers( aPlayer,aPlayer2 );
              MyBrainFormation.SwapDefaultPlayers( aPlayer,aPlayer2 );
              MyBrainFormation.SwapformationPlayers( aPlayer,aPlayer2 );
              MyBrainFormation.ReserveSlot [aPlayer.team,aPlayer.cellx]:=aPlayer.ids; // setto la reserveslot
              MyBrainFormation.ReserveSlot [aPlayer2.team,aPlayer.cellx]:=aPlayer2.ids; // setto la reserveslot
              MoveInReserves(aPlayer);
              MoveInReserves(aPlayer2);
            end
            else begin // da riserva a player campo
              if (aPlayer2.Cells = Point(0,3)) and (aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) then begin
                MyBrainFormation.PutInReserveSlot( aPlayer, Point(aPlayer.CellX, aPlayer.CellX) );
                MoveInReserves(aPlayer);
              end
              else begin
                MyBrainFormation.ReserveSlot [aPlayer.team,aPlayer.cellx]:=''; // svuoto QUI la reserveslot e dopo updateformation setta la nuova posizione
                MyBrainFormation.PutInReserveSlot( aPlayer2 ); // la reserveslot è già libera da sopra
                MoveInReserves(aPlayer2);
              end;
            end;
          end
          else begin  // se_dragGuid (player) è un player del campo
            if MyBrainformation.isReserveSlot( aPlayer2.CellX, aPlayer2.CellY)  then begin// se la destinazione è una riserva
              if aPlayer2.disqualified > 0 then begin
                  MoveInField(aPlayer);
                  SE_DragGuid.DeleteSubSprite('surname');
                  se_DragGuid := nil;
                  HideFP_Friendly_ALL;
                  GlobalFieldPointsSpr.Free;
                  Exit;
              end;

              if aPlayer.Cells <> Point(0,3) then begin
                if (aPlayer2.TalentId1 <> TALENT_ID_GOALKEEPER) then begin // non m i porti in campo un portiere
                  MyBrainFormation.SwapPlayers( aPlayer,aPlayer2 );
                  MyBrainFormation.SwapDefaultPlayers( aPlayer,aPlayer2 );
                  MyBrainFormation.SwapformationPlayers( aPlayer,aPlayer2 );
                  MoveInReserves(aPlayer);
                  MoveInField(aPlayer2);
                end
                else if (aPlayer.Cells = Point(0,3)) and (aPlayer.TalentId1 = TALENT_ID_GOALKEEPER) then begin  // 2 gk swap
                  MyBrainFormation.SwapPlayers( aPlayer,aPlayer2 );
                  MyBrainFormation.SwapDefaultPlayers( aPlayer,aPlayer2 );
                  MyBrainFormation.SwapformationPlayers( aPlayer,aPlayer2 );
                  MoveInReserves(aPlayer);
                  MoveInField(aPlayer2);
                end
                else begin
                  MoveInField(aPlayer);
                  SE_DragGuid.DeleteSubSprite('surname');
                  se_DragGuid := nil;
                  HideFP_Friendly_ALL;
                  GlobalFieldPointsSpr.Free;
                  Exit;
                end;
              end
              else begin  // la cella è 0,3  ma aPlayer non è un gk
                MyBrainFormation.PutInReserveSlot( aPlayer, Point(aPlayer.CellX, aPlayer.CellX) );
                MoveInReserves(aPlayer);

              end;
            end
            else begin  // se la destinazione è una player del campo
                MyBrainFormation.SwapPlayers( aPlayer,aPlayer2 );
                MyBrainFormation.SwapDefaultPlayers( aPlayer,aPlayer2 );
                MyBrainFormation.SwapformationPlayers( aPlayer,aPlayer2 );
                MoveInField(aPlayer);
                MoveInField(aPlayer2);
            end;

          end;


         end;
       end;

       // e dopo storo il nuovo player
       AICell:=  MybrainFormation.Tv2AiField ( 0, aCell2.X, aCell2.Y );
       aPlayer.DefaultCellS := Point  (aCell2.X, aCell2.Y );
       aPlayer.AIFormationCellX  := AICell.X ;
       aPlayer.AIFormationCellY  := AICell.Y ;
       aPlayer.CellS :=  Point(aCell2.X, aCell2.Y);

       FormationChanged := True;
       RefreshCheckFormationMemory;
       SE_DragGuid.DeleteSubSprite('surname');
       se_DragGuid := nil;

    end
    else begin // se mollo e non è vicino a nessuna cella utile, lo rimetto dove era
      aPlayer := findPlayerMyBrainFormation (Se_DragGuid.Guid); // ritrovo il player originale che sto spostando
      for I := 0 to GlobalFieldPointsSpr.Count -1 do begin
        if GlobalFieldPointsSpr[i].Guid = IntToStr(aPlayer.CellX) + '.' + IntToStr(aPlayer.CellY) then begin// ritrovo cella e coordinate originali
          aFieldPointSpr := GlobalFieldPointsSpr[i];
          SE_DragGuid.MoverData.Destination := aFieldPointSpr.Position;
          //SE_DragGuid.Position := aFieldPointSpr.Position;
          SE_DragGuid.DeleteSubSprite('surname');
          se_DragGuid := nil;
          Break;
        end;
      end;


    end;
    HideFP_Friendly_ALL;
    GlobalFieldPointsSpr.Free;
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
function TForm1.GetDominantColor ( Team: integer  ): TColor;
var
  Ts: TStringList;
begin
  Ts:= TStringList.Create;
  Ts.CommaText :=  MyBrain.Score.Uniform[Team];
  Result :=  StrToInt( TsColors[ StrToInt(  ts[0]  ) ]);      // index che punta a colorgrid
  Ts.Free;
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
procedure TForm1.ScreenFormation_SE_Players ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
 aPlayer : TSoccerPlayer;
 bmp: SE_Bitmap;
begin
  if Button = mbRight then begin
    GameScreen := ScreenPlayerDetails;
    aPlayer := findPlayerMyBrainFormation (aSpriteClicked.guid);
    ShowPlayerdetails ( aPlayer );
  end
  else if Button = mbLeft then begin
    aPlayer := findPlayerMyBrainFormation (aSpriteClicked.guid);

    if (aPlayer.GuidTeam = MyGuidTeam) and ( (aPlayer.disqualified = 0) or ((aPlayer.disqualified <> 0) and (not IsOutSide(aPlayer.CellX,aPlayer.CellY)))  ) then begin
      se_dragGuid := aSpriteClicked;
      HHFP_Friendly ( aPlayer, 't' ); // team e talent goalkeeper  , illumina celle di formazione libere o occupate
      HHFP_Friendly ( aPlayer, 'r' ); // illumina celle di riserva libere o occupate

      bmp := CreateSurnameSubSprite (aPlayer);
      se_dragGuid.AddSubSprite(  bmp,'surname',0,28,false );
      bmp.Free;
    end;
//    else begin
//      se_dragGuid.DeleteSubSprite('surname');
//      SE_DragGuid := nil;
//    end;
  end;
end;
function TForm1.CreateSurnameSubSprite (aPlayer: TSoccerPlayer): SE_Bitmap;
var
  bmp: Se_bitmap;
  w: Integer;
begin
  bmp:= Se_bitmap.Create ( se_dragGuid.BmpCurrentFrame.Width ,14);
  bmp.Bitmap.Canvas.Brush.color := clGray;
  bmp.FillRect(0,0,bmp.Width,bmp.Height,clGray);
  bmp.Bitmap.Canvas.Font.Name := 'Calibri';
  bmp.Bitmap.Canvas.Font.Size := 8;
  bmp.Bitmap.Canvas.Font.Color := clWhite;
  bmp.Bitmap.Canvas.Font.Quality := fqAntialiased;
  bmp.Bitmap.Canvas.Brush.Style := bsSolid;
  w := bmp.Canvas.TextWidth( aPlayer.SurName );
  bmp.Bitmap.Canvas.TextOut( ( bmp.Bitmap.Width div 2) - (w div 2)   ,0, aPlayer.surname);
  Result := bmp ;//   SE_SubSprite.create(bmp,'surname',0,28,True,false);
//  bmp.free;

end;

procedure TForm1.ScreenFormation_SE_MainInterface ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
 bmp: Se_bitmap;
 aSprite : SE_Sprite;
 I: integer;
begin

  if aSpriteClicked.Guid = 'btnmenu_exit' then begin
    Application.Terminate;
  end
  else if aSpriteClicked.Guid = 'btnmenu_m' then begin
    if SE_Uniform.Visible then Exit;
    if aSpriteClicked.Alpha = 255 then Exit;
    GameScreen := ScreenWaitingFormation;
    aSpriteClicked.Alpha := 255;
    aSprite := SE_MainInterface.FindSprite('btnmenu_f');
    aSprite.Alpha  := 80;
    tcp.SendStr( 'switch' + Endofline );
  end
  else if aSpriteClicked.Guid = 'btnmenu_f' then begin
    if SE_Uniform.Visible then Exit;
    if aSpriteClicked.Alpha = 255 then Exit;
    GameScreen := ScreenWaitingFormation;
    aSpriteClicked.Alpha := 255;
    aSprite := SE_MainInterface.FindSprite('btnmenu_m');
    aSprite.Alpha  := 80;
    tcp.SendStr( 'switch'+ Endofline );
  end
  else if aSpriteClicked.Guid = 'btnmenu_uniform' then begin
   // PanelUniform.Visible:= True;
    SE_Uniform.Visible := true;
    SE_players.ClickSprites := False;
    // mostro subito in casa lo schema scelto
    aSprite := SE_Uniform.FindSprite('btn_uniformhome');
    aSprite.Alpha := 255;
    aSprite := SE_Uniform.FindSprite('btn_uniformaway');
    aSprite.Alpha := 80;

    aSprite := SE_Uniform.FindSprite('btn_Jersey1');
    aSprite.Alpha := 255;
    aSprite := SE_Uniform.FindSprite('btn_Jersey2');
    aSprite.Alpha := 80;
    aSprite := SE_Uniform.FindSprite('btn_Shorts');
    aSprite.Alpha := 80;

    for I := 0 to 3 do begin  // i 4 schemi
      aSprite := SE_Uniform.FindSprite('btn_schema' + IntToStr(i) );
      aSprite.Alpha := 80;
    end;
    aSprite := SE_Uniform.FindSprite('btn_schema'+  TSUniforms[0][3]   );
    aSprite.Alpha := 255;
    PreLoadUniform( 0,  StrToInt( tsUniforms[0][3]) );

    RenewUniform(0);   // ricarico le uniform

    aSprite := SE_MainInterface.FindSprite('btnmenu_uniform' ); // tornano visible con CLose su Uniform
    aSprite.visible := False;
    aSprite := SE_MainInterface.FindSprite('btnmenu_market' ); // tornano visible con CLose su Uniform
    aSprite.visible := False;
    aSprite := SE_MainInterface.FindSprite('btnmenu_standings' ); // tornano visible con CLose su Uniform
    aSprite.visible := False;
    aSprite := SE_MainInterface.FindSprite('btnmenu_info' ); // tornano visible con CLose su Uniform
    aSprite.visible := False;
    aSprite := SE_MainInterface.FindSprite('btnmenu_play' ); // tornano visible con CLose su Uniform
    aSprite.visible := False;
    aSprite := SE_MainInterface.FindSprite('btnmenu_confirmformation' ); // tornano visible con CLose su Uniform
    aSprite.visible := False;
    aSprite := SE_MainInterface.FindSprite('btnmenu_watchlive' ); // tornano visible con CLose su Uniform
    aSprite.visible := False;
    aSprite := SE_MainInterface.FindSprite('btnmenu_reset' ); // tornano visible con CLose su Uniform
    aSprite.visible := False;

  end
  else if aSpriteClicked.Guid = 'btnmenu_play' then begin
    WaitForSingleObject ( MutexAnimation, INFINITE );
    AnimationScript.Reset;
    FirstLoadOK:= False;
    ReleaseMutex(MutexAnimation );

    if GCD <= 0 then begin
      if CheckFormationTeamMemory then begin
       gameScreen := ScreenWaitingLive;
       LiveMatch := True;
       tcp.SendStr( 'queue' + endofline);
      end
      else begin
        SE_MainInterface.Visible := True;
      end;
     GCD := GCD_DEFAULT;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_confirmformation' then begin
    if GCD <= 0 then begin
      FormationChanged:= False;
      settcpformation;
      GCD := GCD_DEFAULT;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_market' then begin
    if GCD <= 0 then begin
      MemoC.Lines.Add('--->Tcp : market'  );
      tcp.SendStr( 'market,' +  IntToStr(MaxInt)  + EndofLine);
      GCD := GCD_DEFAULT;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_watchlive' then begin
    if GCD <= 0 then begin
      MemoC.Lines.Add('--->Tcp : listmatch'  );
      tcp.SendStr( 'listmatch' + EndofLine );
      GCD := GCD_DEFAULT;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_standings' then begin
    if GCD <= 0 then begin
      MemoC.Lines.Add('--->Tcp : standings'  );
      tcp.SendStr( 'standings' + EndofLine );
      GCD := GCD_DEFAULT;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_reset' then begin
    if GCD <= 0 then begin
      GCD := GCD_DEFAULT;
      WAITING_GETFORMATION:=true;
      tcp.SendStr(  'resetformation' + endofline);
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_info' then begin
    { TODO : diventa standings }
  end;
end;

procedure TForm1.ScreenFormation_SE_Uniform ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  i: Integer;
  ASprite,aSpriteJS: SE_Sprite;
begin
  if aSpriteClicked.Guid = 'btn_uniformhome' then begin
    aSpriteClicked.Alpha := 255;
    aSprite := SE_Uniform.FindSprite('btn_uniformaway');
    aSprite.Alpha := 80;

    for I := 0 to 3 do begin  // i 4 schemi
      aSprite := SE_Uniform.FindSprite('btn_schema' + IntToStr(i) );
      aSprite.Alpha := 80;
    end;
    aSprite := SE_Uniform.FindSprite('btn_schema' + TSUniforms[0][3] );
    aSprite.Alpha := 255;


    PreloadUniform(0,StrToInt(TSUniforms[0][3]));
    RenewUniform(0);
  end
  else if aSpriteClicked.Guid = 'btn_uniformaway' then begin
    aSpriteClicked.alpha := 255;
    aSprite := SE_Uniform.FindSprite('btn_uniformhome');
    aSprite.Alpha := 80;

    for I := 0 to 3 do begin  // i 4 schemi
      aSprite := SE_Uniform.FindSprite('btn_schema' + IntToStr(i) );
      aSprite.Alpha := 80;
    end;
    aSprite := SE_Uniform.FindSprite('btn_schema' + TSUniforms[1][3] );
    aSprite.Alpha := 255;

    PreloadUniform(1,StrToInt(TSUniforms[1][3]));
    RenewUniform(1);
  end
  else if aSpriteClicked.Guid = 'btn_Jersey1' then begin
    aSpriteClicked.Alpha := 255;
    aSprite := SE_Uniform.FindSprite('btn_Jersey2');
    aSprite.Alpha := 80;
    aSprite := SE_Uniform.FindSprite('btn_Shorts');
    aSprite.Alpha := 80;
  end
  else if aSpriteClicked.Guid = 'btn_Jersey2' then begin
    aSpriteClicked.Alpha := 255;
    aSprite := SE_Uniform.FindSprite('btn_Jersey1');
    aSprite.Alpha := 80;
    aSprite := SE_Uniform.FindSprite('btn_Shorts');
    aSprite.Alpha := 80;
  end
  else if aSpriteClicked.Guid = 'btn_Shorts' then begin
    aSpriteClicked.Alpha := 255;
    aSprite := SE_Uniform.FindSprite('btn_Jersey2');
    aSprite.Alpha := 80;
    aSprite := SE_Uniform.FindSprite('btn_Jersey1');
    aSprite.Alpha := 80;
  end
  else if LeftStr( aSpriteClicked.Guid ,10) = 'btn_schema' then begin
    aSprite := SE_Uniform.FindSprite('btn_uniformhome');
    if aSprite.Alpha = 255 then begin
      TSUniforms[0][3]:= aSpriteClicked.sTag;
      PreloadUniform(0, StrToInt(  TSUniforms[0][3]));
      RenewUniform(0);
    end
    else begin
      TSUniforms[1][3]:= aSpriteClicked.sTag;
      PreloadUniform(1,StrToInt(TSUniforms[1][3]));
      RenewUniform(1);
    end;

    for I := 0 to 3 do begin  // i 4 schemi
      aSprite := SE_Uniform.FindSprite('btn_schema' + IntToStr(i) );
      aSprite.Transparent := True;
    end;
    aSpriteClicked.Transparent := False;

  end
  else if LeftStr(aSpriteClicked.Guid,5) = 'color' then begin  // anche qui aSpriteClicked è l'index di tsColors

    aSprite := SE_Uniform.FindSprite('btn_uniformhome');
    if aSprite.Alpha = 255 then begin
      aSpriteJS := SE_Uniform.FindSprite('btn_Jersey1');
      if aSpriteJS.Alpha = 255 then
        TSUniforms[0][0] := aSpriteClicked.sTag;
      aSpriteJS := SE_Uniform.FindSprite('btn_Jersey2');
      if aSpriteJS.Alpha = 255 then
        TSUniforms[0][1] := aSpriteClicked.sTag;
      aSpriteJS := SE_Uniform.FindSprite('btn_Shorts');
      if aSpriteJS.Alpha = 255 then
        TSUniforms[0][2] := aSpriteClicked.sTag;

      PreloadUniform(0, StrToInt(  TSUniforms[0][3]));
      RenewUniform(0);
    end
    else begin
      aSpriteJS := SE_Uniform.FindSprite('btn_Jersey1');
      if aSpriteJS.Alpha = 255 then
        TSUniforms[1][0] := aSpriteClicked.sTag;
      aSpriteJS := SE_Uniform.FindSprite('btn_Jersey2');
      if aSpriteJS.Alpha = 255 then
        TSUniforms[1][1] := aSpriteClicked.sTag;
      aSpriteJS := SE_Uniform.FindSprite('btn_Shorts');
      if aSpriteJS.Alpha = 255 then
        TSUniforms[1][2] := aSpriteClicked.sTag;
      PreloadUniform(1,StrToInt(TSUniforms[1][3]));
      RenewUniform(1);
    end;
  end
  else if aSpriteClicked.Guid = 'btn_uniformclose' then begin
    if GCD <= 0 then begin
      aSprite := SE_MainInterface.FindSprite('btnmenu_uniform' ); // tornano visible con CLose su Uniform
      aSprite.visible := True;
      aSprite := SE_MainInterface.FindSprite('btnmenu_market' ); // tornano visible con CLose su Uniform
      aSprite.visible := True;
      aSprite := SE_MainInterface.FindSprite('btnmenu_standings' ); // tornano visible con CLose su Uniform
      aSprite.visible := True;
      aSprite := SE_MainInterface.FindSprite('btnmenu_info' ); // tornano visible con CLose su Uniform
      aSprite.visible := True;
      aSprite := SE_MainInterface.FindSprite('btnmenu_play' ); // tornano visible con CLose su Uniform
      aSprite.visible := True;
      aSprite := SE_MainInterface.FindSprite('btnmenu_watchlive' ); // tornano visible con CLose su Uniform
      aSprite.visible := True;
      aSprite := SE_MainInterface.FindSprite('btnmenu_reset' ); // tornano visible con CLose su Uniform
      aSprite.visible := True;
      CheckFormationTeamMemory;  // play / conferma visibilità
      SE_players.ClickSprites := True;
      ShowLoading;
      WAITING_GETFORMATION:= True;
      tcp.SendStr(  'setuniform,' +  TSUniforms[0].CommaText + ',' + TSUniforms[1].CommaText + endofline);
      GCD := GCD_DEFAULT;
    end;
  end



end;
procedure TForm1.ScreenPlayerDetails_SE_PlayerDetails ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  aPlayer : TSoccerPlayer;
begin
  if aSpriteClicked.Guid = 'btnmenu_back' then begin
    GameScreen := ScreenFormation;
    se_PlayerDetails.Visible := False;
    SE_MainInterface.Visible := True;
  end
  else if aSpriteClicked.Guid = 'btnmenu_sell' then begin
    aPlayer := findPlayerMyBrainFormation (IntToStr(SE_BackGround.tag));
    case aPlayer.OnMarket of  // onMarket
      False: begin
        if TotMarket < 3 then begin
          PanelSell.Visible := True;
          PanelSell.BringToFront;
          PanelDismiss.Visible := False;
          edtSell.Text  := IntToStr(aPlayer.MarketValue);
        end
        else begin
          lastStrError:= 'lbl_ErrorMarketMax';
          ShowError( Translate('lbl_ErrorMarketMax'));
        end;
      end;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_cancelsell' then begin
    aPlayer := findPlayerMyBrainFormation (IntToStr(SE_BackGround.tag));
    case aPlayer.OnMarket of  // onMarket
      True: begin
        WAITING_GETFORMATION:= True;
        aPlayer.OnMarket:=false;
        tcp.SendStr( 'cancelsell,'+ IntToStr(SE_BackGround.tag)  + EndofLine); // solo a sinistra in formation
      end;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_dismiss' then begin
    PanelDismiss.Visible := True;
    PanelDismiss.BringToFront;
    PanelSell.Visible := False;
  end
  else if LeftStr(aSpriteClicked.Guid,7) = 'levelup' then begin
    tcp.SendStr( 'levelupattribute,'+ IntToStr(SE_BackGround.tag) + ',' + aSpriteClicked.stag  + EndofLine);
  end
  else if LeftStr(aSpriteClicked.Guid,8) = 'talentup' then begin
    tcp.SendStr( 'leveluptalent,'+ IntToStr(SE_BackGround.tag) + ',' + aSpriteClicked.stag + EndofLine);
  end;

end;
procedure TForm1.ScreenAML_SE_AML ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
begin
  if aSpriteClicked.guid = 'btnmenu_back' then begin
    GameScreen := ScreenFormation;
  end
  else if aSpriteClicked.guid = 'btnmenu_refresh' then begin
    if GCD <= 0 then begin
      MemoC.Lines.Add('--->Tcp : listmatch'  );
      tcp.SendStr( 'listmatch' + EndofLine );
      GCD := GCD_DEFAULT;
    end;
  end
  else if LeftStr(aSpriteClicked.guid,2) = 'tv' then begin

    if GCD <= 0 then begin

      if (not viewMatch)  then begin
        gameScreen := ScreenWaitingSpectator ;
        MemoC.Lines.Add('--->Tcp : viewmatch,' + aSpriteClicked.stag ); // brainIds
        tcp.SendStr(  'viewmatch,' + aSpriteClicked.stag + EndofLine );
        viewMatch := True;
        SetGlobalCursor( crHourGlass);
      end;
      GCD := GCD_DEFAULT;
    end;
  end;

end;
procedure TForm1.ScreenMarket_SE_Market ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
begin
  if LeftStr(aSpriteClicked.Guid,6) = 'market' then begin
    PanelBuy.Tag :=  StrToIntDef (aSpriteClicked.stag,0);
    if PanelBuy.Tag = 0 then exit;
    lbl_ConfirmBuy.Caption :=  Translate('lbl_ConfirmBuy') +' ' +aSpriteClicked.Labels[0].lText; {cognome}
    PanelBuy.Left := (Form1.Width div 2) - (PanelBuy.Width div 2);
    PanelBuy.Top := aSpriteClicked.Position.Y + (aSpriteClicked.BMP.Height div 2);
    PanelBuy.Visible := True;
    PanelBuy.BringToFront;
    FocusMarketPlayer ( aSpriteClicked );
//    SE_Market.Visible := False;
  end
  else if aSpriteClicked.Guid = 'btnmenu_back' then begin
    GameScreen := ScreenFormation;
  end
  else if aSpriteClicked.Guid = 'btnmenu_refresh' then begin
    if GCD <= 0 then begin
      MemoC.Lines.Add('--->Tcp : market'  );
      tcp.SendStr( 'market,'  +  IntToStr(MaxInt)  + EndofLine );
      GCD := GCD_DEFAULT;
    end;
  end;
end;
procedure TForm1.ScreenSelectCountryTeam_SE_CountryTeam ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
begin
  if aSpriteClicked.Guid = 'btnmenu_back' then begin
    if GameScreen  = ScreenSelectTeam then
      GameScreen := ScreenSelectCountry
      else GameScreen := ScreenLogin;
  end
  else if aSpriteClicked.Guid = 'btnmenu_back2' then begin
    IndexCT := IndexCT - 40;
    if GameScreen  = ScreenSelectTeam then
      ClientLoadTeams( IndexCT )
      else ClientLoadCountries( IndexCT );

  end
  else if aSpriteClicked.Guid = 'btnmenu_back1' then begin
    IndexCT := IndexCT - 20;
    if GameScreen  = ScreenSelectTeam then
      ClientLoadTeams( IndexCT )
      else ClientLoadCountries( IndexCT );
  end
  else if aSpriteClicked.Guid = 'btnmenu_forward1' then begin
    IndexCT := IndexCT + 20;
    if GameScreen  = ScreenSelectTeam then
      ClientLoadTeams( IndexCT )
      else ClientLoadCountries( IndexCT );
  end
  else if aSpriteClicked.Guid = 'btnmenu_forward2' then begin
    IndexCT := IndexCT + 40;
    if GameScreen  = ScreenSelectTeam then
      ClientLoadTeams( IndexCT )
      else ClientLoadCountries( IndexCT );
  end
  else if LeftStr(aSpriteClicked.Guid,8) = 'ctselect' then begin
    // una volta all'inizio del gioco
    if GCD <= 0 then begin
      if GameScreen =  ScreenSelectCountry then
      tcp.SendStr( 'selectedcountry,' + aSpriteClicked.sTag + EndofLine)
      else if GameScreen =  ScreenSelectTeam then begin
        if (Application.MessageBox  ( PChar(Translate('lbl_ConfirmTeam') + ' : ' + TsNationTeams.Values [aSpriteClicked.sTag] ) , pChar(Translate('lbl_ConfirmTeam')),  MB_YESNO )) = IDYES then begin
          WAITING_GETFORMATION:= True;
          tcp.SendStr(  'selectedteam,' + aSpriteClicked.sTag + EndofLine);
        end
        else GameScreen :=  ScreenSelectCountry;
      end;
      GCD := GCD_DEFAULT;
    end;
  end;

end;
procedure TForm1.ScreenSpectator_SE_Spectator ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  i: Integer;
  aBallSprite: SE_Sprite;
begin
  if aSpriteClicked.Guid = 'btnmenu_exit' then begin
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
        SE_players.RemoveAllSprites;
        ReleaseMutex(MutexAnimation);
        aBallSprite := SE_ball.FindSprite('ball');
        SE_ball.RemoveSprite(aBallSprite);
        SE_interface.RemoveAllSprites;
        SE_Numbers.RemoveAllSprites;
        GameScreen := ScreenLogin;
      end
      else if viewMatch then begin
        //AudioCrowd.Stop;
        tcp.SendStr( 'closeviewmatch' + EndofLine);
        ShowLoading;
        viewMatch := False;
        WaitForSingleObject(MutexAnimation,INFINITE);
        while (se_ball.IsAnySpriteMoving ) or (se_players.IsAnySpriteMoving ) do begin
          se_Theater1.thrdAnimate.OnTimer (se_Theater1.thrdAnimate);
          application.ProcessMessages ;
        end;
        ReleaseMutex(MutexAnimation);
        GameScreen := ScreenWaitingFormation;
        SE_interface.RemoveAllSprites;
        SE_Numbers.RemoveAllSprites;

        Sleep(1000);
        WAITING_GETFORMATION:= true;
        tcp.SendStr( 'getformation' + EndofLine);

      end;

      GCD := GCD_DEFAULT;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_overridecolor' then begin
    overridecolor := true;
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      if MyBrain.lstSoccerPlayer[i].Team = 1 then begin
        MyBrain.lstSoccerPlayer[i].SE_Sprite.BlendMode := SE_BlendAverage;
      end;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_overridecolornormal' then begin
    overridecolor := false;
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      if MyBrain.lstSoccerPlayer[i].Team = 1 then begin
        MyBrain.lstSoccerPlayer[i].SE_Sprite.BlendMode := SE_BlendNormal;
      end;
    end;
  end;
end;
procedure TForm1.ScreenWaitingLive_SE_Loading ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
begin
  if aSpriteClicked.Guid = 'btnmenu_cancelqueue' then begin
    if GCD <= 0 then begin
      tcp.SendStr( 'cancelqueue' + EndofLine);
      GCD := GCD_DEFAULT;
    end;
    GameScreen := ScreenFormation;
  end
  else if aSpriteClicked.Guid = 'btnmenu_cancelspectatorqueue' then begin
    if GCD <= 0 then begin
      tcp.SendStr( 'cancelspectatorqueue' + EndofLine);
      GCD := GCD_DEFAULT;
    end;
    GameScreen := ScreenFormation;
  end;
end;
procedure TForm1.ScreenFreeKick_SE_Players ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  CornerMap: TCornerMap;
  aCell2,ACellBarrier: TPoint;
  aPlayerClicked, SwapPlayer: TSoccerPlayer;
  aFieldPointSpr: SE_Sprite;
begin
  // lo swapping ci vuole per selezionare quei players. Nel corner cof invece di mybrain.findswapcoad affianco semplicemente gli sprites
  // in fk1 non faccio nulla. lo spriteReset mi presenta la posizione dello swapPlayer
  // in fk2 li metto a fianco. sono comunque cliccabili
  aPlayerClicked :=  MyBrain.GetSoccerPlayer(aSpriteClicked.Guid  );
  if aPlayerClicked.GuidTeam <> MyGuidTeam then
    Exit;

  case MouseWaitFor of

    WaitForXY_FKF1:begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick
      TsCoa.add (aSpriteClicked.guid) ; // ids
      fGameScreen := ScreenLive;
      tcp.SendStr( 'FREEKICK1_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
      MouseWaitFor := WaitForNone;
    end;

    WaitForXY_FKF2: begin  // chi batte il freekick con cross
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick
      aSpriteClicked.GrayScaled := true;
      CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
      aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (Mybrain.Ball.CellX) + '.' + IntToStr (Mybrain.Ball.CellY));
      aSpriteClicked.MoverData.Destination := aFieldPointSpr.Position ;

      SwapPlayer := MyBrain.GetSoccerPlayer( MyBrain.Ball.CellX,MyBrain.Ball.CellY );
      if SwapPlayer.Ids <> aPlayerClicked.ids then begin
        SwapPlayer.se_sprite.MoverData.Destination := Point(  Trunc(SwapPlayer.se_sprite.PositionX - 32), Trunc(SwapPlayer.se_sprite.PositionY)  - 32);
      end;

      HideFP_Friendly_ALL;
      HHFP ( CornerMap.HeadingCellA [0].X,CornerMap.HeadingCellA [0].Y,0);
      TsCoa.add (aSpriteClicked.guid) ; // ids
      MouseWaitFor := WaitForXY_FKA2;
    end;
    WaitForXY_FKA2: begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick
      aSpriteClicked.GrayScaled := true;

      CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
      aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (CornerMap.HeadingCellA [TsCoa.count-1].X ) + '.' + IntToStr (CornerMap.HeadingCellA [TsCoa.count-1].Y ));
      aSpriteClicked.MoverData.Destination := aFieldPointSpr.Position ;


      SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellA [TsCoa.count-1].X,CornerMap.HeadingCellA [TsCoa.count-1].Y );
      if SwapPlayer <> nil then begin
        if SwapPlayer.Ids <> aPlayerClicked.ids then begin
          SwapPlayer.se_sprite.MoverData.Destination := Point(  Trunc(SwapPlayer.se_sprite.PositionX - 32), Trunc(SwapPlayer.se_sprite.PositionY)  - 32);
        end;
      end;

      HideFP_Friendly_ALL;
      TsCoa.add (aSpriteClicked.Guid);
      if tsCoa.Count = 4 then begin   // cof + 3 coa
        fGameScreen := ScreenLive;
        tcp.SendStr(  'FREEKICK2_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
        MouseWaitFor := WaitForNone;
      end
      else begin
        HHFP( CornerMap.HeadingCellA [TsCoa.count-1].X,CornerMap.HeadingCellA [TsCoa.count-1].Y,0 );
      end;
    end;
    WaitForXY_FKD2: begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick
      aSpriteClicked.GrayScaled := true;
      CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
      aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (CornerMap.HeadingCellD [TsCod.count].X ) + '.' + IntToStr (CornerMap.HeadingCellD [TsCod.count].Y ));
      aSpriteClicked.MoverData.Destination := aFieldPointSpr.Position ;

      SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellA [TsCod.count].X,CornerMap.HeadingCellA [TsCod.count].Y );
      if SwapPlayer <> nil then begin
        if SwapPlayer.Ids <> aPlayerClicked.ids then begin
          SwapPlayer.se_sprite.MoverData.Destination := Point(  Trunc(SwapPlayer.se_sprite.PositionX - 32), Trunc(SwapPlayer.se_sprite.PositionY)  - 32);
        end;
      end;
      HideFP_Friendly_ALL;
      TsCod.add (aSpriteClicked.guid);// in barriera swappo solo il primo
      if tsCod.Count = 3 then begin  // 3 cod
        fGameScreen := ScreenLive;
        tcp.SendStr( 'FREEKICK2_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
        MouseWaitFor := WaitForNone;
      end
      else begin
        HHFP( CornerMap.HeadingCellD [TsCod.count].X,CornerMap.HeadingCellD [TsCod.count].Y,0 );
      end;
    end;
    WaitForXY_FKF3: begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick
      aSpriteClicked.GrayScaled := true;

      CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;
      aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (Mybrain.Ball.CellX ) + '.' + IntToStr (Mybrain.Ball.CellY ));
      aSpriteClicked.MoverData.Destination := aFieldPointSpr.Position ;

      SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellA [TsCod.count-1].X,CornerMap.HeadingCellA [TsCod.count-1].Y );
      if SwapPlayer <> nil then begin
        if SwapPlayer.Ids <> aPlayerClicked.ids then begin
          SwapPlayer.se_sprite.MoverData.Destination := Point(  Trunc(SwapPlayer.se_sprite.PositionX - 32), Trunc(SwapPlayer.se_sprite.PositionY)  - 32);
        end;
      end;

      TsCoa.add (aSpriteClicked.Guid);
      fGameScreen := ScreenLive;
      tcp.SendStr( 'FREEKICK3_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
      MouseWaitFor := WaitForNone;
    end;
    WaitForXY_FKD3: begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick
      aSpriteClicked.GrayScaled := true;
      CornerMap := MyBrain.GetCorner ( MyBrain.TeamFreeKick , Mybrain.Ball.CellY,OpponentCorner) ;

      ACellBarrier := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.CellY)  ; // la cella barriera !!!!
      aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr(ACellBarrier.X) +'.' + IntToStr(ACellBarrier.Y));
      aSpriteClicked.MoverData.Destination := point (aFieldPointSpr.Position.X + BarrierPosition[GBIndex].X  ,aFieldPointSpr.Position.Y + BarrierPosition[GBIndex].Y)  ;
      aSpriteClicked.Scale := ScaleSpritesBarrier;
      inc(GBIndex);

      SwapPlayer := MyBrain.GetSoccerPlayer( ACellBarrier.X,ACellBarrier.Y );
      if not SwapPlayerBarrierDone then begin  // lo sprite si sposta una sola volta di 32
        if SwapPlayer <> nil then begin
          if SwapPlayer.Ids <> aPlayerClicked.ids then begin
            SwapPlayer.se_sprite.MoverData.Destination := Point(  Trunc(SwapPlayer.se_sprite.PositionX - 32), Trunc(SwapPlayer.se_sprite.PositionY)  - 32);
            SwapPlayerBarrierDone := True;
          end;
        end;
      end;

      HideFP_Friendly_ALL;
      TsCod.add (aSpriteClicked.guid);// in barriera swappo solo il primo
      if tsCod.Count = 4 then begin// 4 in barriera
        fGameScreen := ScreenLive;
        tcp.SendStr( 'FREEKICK3_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
        SwapPlayerBarrierDone:= False;
        MouseWaitFor := WaitForNone;
      end
      else begin
       // ACellBarrier  := MyBrain.GetBarrierCell ( MyBrain.TeamFreeKick,MyBrain.Ball.CellX, MyBrain.Ball.CellY)  ; // la cella barriera !!!!
        HHFP( ACellBarrier.X, ACellBarrier.Y,0 );
      end;
    end;
    WaitForXY_FKF4: begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick

      TsCoa.add (aSpriteClicked.Guid) ; // ids
      fGameScreen := ScreenLive;
      tcp.SendStr( 'FREEKICK4_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
      MouseWaitFor := WaitForNone;
      HideFP_Special;
    end;

    WaitForXY_CornerCOF: begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick
      MouseWaitFor := WaitForXY_CornerCOA;
      CornerMap := MyBrain.GetCorner ( MyBrain.TeamCorner , Mybrain.Ball.CellY,OpponentCorner) ;
      CornerSetPlayer(MyBrain.GetSoccerPlayer(aSpriteClicked.Guid  )); // non devo swappare nulla, i pixel sono già distanti

      HideFP_Special;
      HHFP( CornerMap.HeadingCellA [0].X,CornerMap.HeadingCellA [0].Y,0 );
      TsCoa.add (aSpriteClicked.guid) ; // ids
    end;

    WaitForXY_CornerCOA: begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick
      CornerMap := MyBrain.GetCorner ( MyBrain.TeamCorner , Mybrain.Ball.CellY,OpponentCorner) ;

      aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (CornerMap.HeadingCellA [TsCoa.count-1].X ) + '.' + IntToStr (CornerMap.HeadingCellA [TsCoa.count-1].Y ));
      aSpriteClicked.MoverData.Destination := aFieldPointSpr.Position ;

      SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellA [TsCoa.count-1].X,CornerMap.HeadingCellA [TsCoa.count-1].Y );
      // SwapPlayer può essere friendly o avversario
      if SwapPlayer <> nil then begin
        if SwapPlayer.Ids <> aPlayerClicked.ids then begin // lo metto in un angolo
          SwapPlayer.se_sprite.MoverData.Destination := Point(  Trunc(SwapPlayer.se_sprite.PositionX - 32), Trunc(SwapPlayer.se_sprite.PositionY)  - 32);
        end;
      end;

      HideFP_Friendly_ALL;
      TsCoa.add (aSpriteClicked.Guid);
      if tsCoa.Count = 4 then begin   // cof + 3 coa
        fGameScreen := ScreenLive;
        tcp.SendStr(  'CORNER_ATTACK.SETUP,' + tsCoa.commatext + EndofLine);
        MouseWaitFor := WaitForNone;
      end
      else HHFP( CornerMap.HeadingCellA [TsCoa.count-1].X,CornerMap.HeadingCellA [TsCoa.count-1].Y,0 );
    end;

    WaitForXY_CornerCOD: begin
      if aSpriteClicked.GrayScaled then Exit; // GK o già selezionati in caso di corner o freekick

      CornerMap := MyBrain.GetCorner ( MyBrain.TeamCorner , Mybrain.Ball.CellY,OpponentCorner) ;
      aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (CornerMap.HeadingCellD [TsCod.count-1].X ) + '.' + IntToStr (CornerMap.HeadingCellD [TsCod.count-1].Y ));
      aSpriteClicked.MoverData.Destination := aFieldPointSpr.Position ;


      SwapPlayer := MyBrain.GetSoccerPlayer( CornerMap.HeadingCellD [TsCod.count-1].X,CornerMap.HeadingCellD [TsCod.count-1].Y );
      if SwapPlayer <> nil then begin
        if SwapPlayer.Ids <> aPlayerClicked.ids then begin
          SwapPlayer.se_sprite.Position := aFieldPointSpr.Position;                                   // sposto solo lo sprite che rimane cliccabile in se_players
        end;
      end;

      HideFP_Friendly_ALL;
      TsCod.add (aSpriteClicked.guid) ; // ids
      if tsCod.Count = 3 then begin  // 3 cod
        fGameScreen := ScreenLive;
        tcp.SendStr( 'CORNER_DEFENSE.SETUP,' + tsCod.commatext + EndofLine);
        MouseWaitFor := WaitForNone;
      end
      else begin
        HHFP( CornerMap.HeadingCellD [TsCod.count-1].X,CornerMap.HeadingCellD [TsCod.count-1].Y,0 );
      end;
    end;
  end;
end;
procedure TForm1.ScreenLive_SE_Green ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
begin
  if MouseWaitFor = WaitForGreen then begin
    MouseWaitFor := WaitForNone;
    hidechances;
    tcp.SendStr( SendString + EndOfline );
    SE_Green.Visible := False;
  end;

end;
procedure TForm1.ScreenLive_SE_Players ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
begin

  if DontDoPlayers then Exit;
  if MouseWaitFor = WaitForNone then begin

    fSelectedPlayer := MyBrain.GetSoccerPlayer (aSpriteClicked.guid);
    if SelectedPlayer.GuidTeam = MyGuidTeam then begin

      if not IsOutside ( SelectedPlayer.CellX, SelectedPlayer.CellY) then begin
        SelectedPlayerPopupSkill( SelectedPlayer.CellX, SelectedPlayer.CellY );
        Exit;
      end;
    end;
  end;
end;
procedure TForm1.ScreenLive_SE_FieldPoints ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  aPlayer: TSoccerPlayer;
  FriendlyWall,OpponentWall,FinalWall: boolean;
  MoveValue: Integer;
  aHeadingFriend,aFriend: TSoccerPlayer;
  aPoint: TPoint;
  CellX,CellY: integer;
  aPath: dse_pathPlanner.Tpath;
  aFieldPointSpr: SE_Sprite;
begin

  aPoint:= FieldGuid2Cell (aSpriteClicked.guid);
  CellX := aPoint.X;
  CellY := aPoint.Y;

  if MouseWaitFor = WaitForXY_Move  then begin
    if  SelectedPlayer = nil then Exit;
    if  not SelectedPlayer.CanSkill  then Exit;
    if  not SelectedPlayer.CanMove then Exit;

    // trick, se non è visibile il subsprite highlight non posso muovermi li'
    aFieldPointSpr := SE_FieldPoints.FindSprite( IntToStr(CellX)+'.' + IntToStr(CellY) )  ;
//      if not aFieldPointSpr.SubSprites[0].lVisible  then
    if not aFieldPointSpr.Visible  then
      Exit;

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
    if (SelectedPlayer.CellX = CellX) and (SelectedPlayer.CellY = CellY) then exit;
        MyBrain.GetPath (SelectedPlayer.Team , SelectedPlayer.CellX , SelectedPlayer.Celly, CellX, CellY,
                              MoveValue{Limit},false{useFlank},FriendlyWall{FriendlyWall},
                              OpponentWall{OpponentWall},FinalWall{FinalWall},TruncOneDir{OneDir}, SelectedPlayer.MovePath );

    if (SelectedPlayer.MovePath.Count > 0) then begin
      if GCD > 0 then Exit;
      MouseWaitFor := WaitForNone;
      DontDoPlayers := true;
      if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        hidechances;
        ShowGreen ( CellX, CellY );
        SendString := 'PLM' + ',' + SelectedPlayer.Ids   + ',' +
        IntToStr(SelectedPlayer.MovePath[ SelectedPlayer.MovePath.Count -1].X ) +  ',' +
        IntToStr(SelectedPlayer.MovePath[ SelectedPlayer.MovePath.Count -1].Y ) ;   // mando l'ultima cella del path
      end;
    end;
  end
  else if (SelectedPlayer = Mybrain.Ball.Player) and (MouseWaitFor = WaitForXY_Shortpass) then begin
    if GCD > 0 then Exit;

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
      if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        hidechances;
        ShowGreen ( CellX, CellY );
        DontDoPlayers := true;
        SendString := 'SHP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) ;
      end;

    end;

    aPath.Free;
  end
  else if MouseWaitFor = WaitForXY_SetPlayer then begin
{$ifdef tools}
    hidechances  ;
    ShowGreen (CellX,CellY);
    DontDoPlayers := true;
    SendString := 'setplayer,' +  SelectedPlayer.ids + ',' +  IntToStr(CellX) + ',' +  IntToStr(CellY);
    SE_FieldPoints.HideAllSprites;
{$endif tools}
  end

  else if (SelectedPlayer = Mybrain.Ball.Player) and (MouseWaitFor = WaitForXY_Loftedpass)  then begin
    if GCD > 0 then Exit;
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
      if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        hidechances ;
        ShowGreen ( CellX, CellY );
        SendString :=  'LOP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + ',N';
      end;
    end
    else begin
      if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        hidechances ;
        ShowGreen ( CellX, CellY );
        DontDoPlayers := true;
        SendString := 'LOP' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY ) + ',GKLOP';
      end;
    end;


  end
  else if (SelectedPlayer = Mybrain.Ball.Player) and (MouseWaitFor = WaitForXY_Crossing)  then begin
    if GCD > 0 then Exit;
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

    if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then begin
      hidechances  ;
      ShowGreen ( CellX, CellY );
      DontDoPlayers := true;
      SendString := 'CRO' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY );
    end;



  end
  else if (SelectedPlayer = Mybrain.Ball.Player) and (MouseWaitFor =WaitForXY_Dribbling)  then begin
    if GCD > 0 then Exit;
    // controllo lato client. il server lo ripete

    if (absDistance (SelectedPlayer.CellX , SelectedPlayer.CellY, Cellx, Celly  ) = 1) and (SelectedPlayer.CanDribbling ) then begin

      aPlayer := MyBrain.GetSoccerPlayer(CellX,CellY);
      if aPlayer = nil then exit;
      if (aPlayer.Team = SelectedPlayer.Team) or ( aPlayer = SelectedPlayer) then exit;

      if MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam then begin
        hidechances  ;
        ShowGreen (CellX,CellY);
        DontDoPlayers := false;
        SendString := 'DRI' + ',' + IntToStr(CellX) +  ',' + IntToStr(CellY );
      end;
    end;
  end;
end;
procedure TForm1.ScreenLive_SE_GameOver ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
begin
  if aSpriteClicked.Guid = 'btnmenu_back' then begin
    SE_GameOver.Visible := False;
    tcp.SendStr( 'getformation' + EndofLine);
  end;
end;
procedure TForm1.ScreenSpectator_SE_GameOver ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
begin
  if aSpriteClicked.Guid = 'btnmenu_back' then begin
    SE_GameOver.Visible := False;
    tcp.SendStr( 'getformation' + EndofLine);
  end;
end;
procedure TForm1.ScreenLive_SE_Skills ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  aDoor: TPoint;
begin
  //  SelectedPlayerPopupSkill compare solo se può comparire. se c'è un waitfor non agisce

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
    WaitForXY_SetPlayer: exit;

  {            WaitForNone: ;
    WaitForAuth: ;
    WaitForXY_PowerShot: ;
    WaitForXY_PrecisionShot: ; }
  end;

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
  SE_Skills.Visible := False;

  SelectedPlayer.se_sprite.DeleteSubSprite('mainskill' );
  SelectedPlayer.se_sprite.AddSubSprite( dir_skill + aSpriteClicked.Guid+'.bmp'  ,'mainskill',
    (SelectedPlayer.se_sprite.BmpCurrentFrame.Width div 2) - 16 , (SelectedPlayer.se_sprite.BmpCurrentFrame.Height div 2), true ) ;
  SE_Skills.ProcessSprites(2000);

  if aSpriteClicked.Guid = 'Move' then begin
    MouseWaitFor  :=  WaitForXY_Move;
  end
  else if aSpriteClicked.Guid = 'Short.Passing' then begin
    MouseWaitFor  :=  WaitForXY_ShortPass;
  end
  else if  aSpriteClicked.Guid = 'setplayer' then begin
    MouseWaitFor  :=  WaitForXY_SetPlayer;
    SE_FieldPoints.ShowAllSprites;

  end
  else if aSpriteClicked.Guid = 'Lofted.Pass' then begin
    MouseWaitFor  :=  WaitForXY_LoftedPass;
  end
  else if aSpriteClicked.Guid = 'Crossing' then begin
  if GCD <= 0 then begin
    MouseWaitFor  :=  WaitForXY_Crossing;

    if MyBrain.w_FreeKick2 then begin   // in caso di freeKick2 il cross è automatico
      MouseWaitFor := WaitForNone;
      if  (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'CRO2' + EndofLine);
      hidechances ;
    end;
    GCD := GCD_DEFAULT;
  end;
  end
  else if aSpriteClicked.Guid = 'Precision.Shot' then begin
    if GCD <= 0 then begin
      aDoor:= MyBrain.GetOpponentDoor (SelectedPlayer );
      if (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then begin
        hidechances;
        ShowGreen (aDoor.X,aDoor.Y);
        SendString := 'PRS';
      end;
    end;
  end
  else if aSpriteClicked.Guid = 'Power.Shot' then begin
    if GCD <= 0 then begin
      aDoor:= MyBrain.GetOpponentDoor (SelectedPlayer );
      if (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then begin
        hidechances;
        ShowGreen (aDoor.X,aDoor.Y);
        SendString := 'POS';
      end;
    end;
  end
  else if aSpriteClicked.Guid = 'Dribbling' then begin
    MouseWaitFor := WaitForXY_Dribbling;
  end
  else if aSpriteClicked.Guid = 'Protection' then begin
    if GCD <= 0 then begin
      if Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam then begin
        hidechances;
        ShowGreen (MyBrain.Ball.Cx,MyBrain.Ball.Cy);
        SendString := 'PRO';
      end;
    end;
  end
  else if  aSpriteClicked.Guid = 'Tackle' then begin
    if GCD <= 0 then begin
      MouseWaitFor := WaitForNone;
      if Mybrain.Ball.Player <> nil then begin
        if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin
          // Tackle può portare anche ai falli e relativi infortuni e cartellini. Un tackle da dietro ha alte possibilità di generare un fallo
          if  Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam then begin
            hidechances;
            ShowGreen (MyBrain.Ball.Cx,MyBrain.Ball.Cy);
            SendString :=  'TAC' + ',' + SelectedPlayer.Ids ;
          end;
        end;
      end;
    end;
  end
  else if  aSpriteClicked.Guid = 'Pressing' then begin
    if GCD <= 0 then begin
      if Mybrain.Ball.Player <> nil then begin
        if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin
        if (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then begin
          hidechances;
          ShowGreen (MyBrain.Ball.Cx,MyBrain.Ball.Cy);
          SendString :=  'PRE' + ',' + SelectedPlayer.Ids ;
        end;
      end;
      end;
    end;
  end
  else if  aSpriteClicked.Guid = 'Corner.Kick' then begin
         // non più usata
    if GCD <= 0 then begin
      MouseWaitFor := WaitForNone;
      // sul brain iscof batterà il corner
      if (Mybrain.Score.TeamGuid  [ Mybrain.TeamTurn ] = MyGuidTeam) then tcp.SendStr( 'COR' + EndofLine);
      GCD := GCD_DEFAULT;
      hidechances  ;
    end;
  end
  else if  aSpriteClicked.Guid = 'Stay' then begin
    if GCD <= 0 then begin
      if (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) and  ( not SelectedPlayer.stay) then begin
        hidechances;
        ShowGreen (SelectedPlayer.CellX, SelectedPlayer.CellY);
        SendString :=  'STAY,' + SelectedPlayer.Ids;
      end;
    end;
  end
  else if  aSpriteClicked.Guid = 'Free' then begin
    if GCD <= 0 then begin
      if (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) and  ( SelectedPlayer.stay) then begin
        hidechances;
        ShowGreen (SelectedPlayer.CellX, SelectedPlayer.CellY);
        SendString :=  'FREE,' + SelectedPlayer.Ids;
      end;
    end;
  end
  else if  aSpriteClicked.Guid = 'BuffD' then begin
    if GCD <= 0 then begin
      if (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then begin
        hidechances;
        ShowGreen (SelectedPlayer.CellX, SelectedPlayer.CellY);
        SendString :=  'BUFFD,' + SelectedPlayer.Ids;
      end;
    end;
  end
  else if  aSpriteClicked.Guid = 'BuffM' then begin
    if GCD <= 0 then begin
      if (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then begin
        hidechances;
        ShowGreen (SelectedPlayer.CellX, SelectedPlayer.CellY);
        SendString :=  'BUFFM,' + SelectedPlayer.Ids;
      end;
    end;
  end
  else if  aSpriteClicked.Guid = 'BuffF' then begin
    if GCD <= 0 then begin
      if (MyBrain.Score.TeamGuid  [ MyBrain.TeamTurn ] = MyGuidTeam) then begin
        hidechances;
        ShowGreen (SelectedPlayer.CellX, SelectedPlayer.CellY);
        SendString :=  'BUFFF,' + SelectedPlayer.Ids;
      end;
    end;
  end;

end;

procedure TForm1.ScreenTacticsSubs_SE_Players ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  aPlayer: TSoccerPlayer;
  bmp : SE_Bitmap;
begin
  if GameScreen = ScreenTactics then begin

    if Button = MbRight then begin
      if SE_DragGuid <> nil then begin
        SE_DragGuid.DeleteSubSprite('surname');
        aPlayer := MyBrain.GetSoccerPlayer2 (Se_dragGuid.guid); // trova tutti  comunque
        if aPlayer <> nil then
          CancelDrag (aPlayer, aPlayer.defaultcellX, aPlayer.defaultCellY);

        SE_DragGuid.DeleteSubSprite('surname');
        SE_DragGuid := nil;
      end;
      HideFP_Friendly_ALL;
      GameScreen := ScreenTactics ;
      Exit;
    end;

    // mbleft
    aPlayer := MyBrain.GetSoccerPlayer2 (aSpriteClicked.guid); // trova tutti  comunque

    if (aPlayer.GuidTeam = MyGuidTeam) and (aPlayer.disqualified = 0)  then begin
      SE_dragGuid := aSpriteClicked;
      bmp := CreateSurnameSubSprite (aPlayer);
      se_dragGuid.AddSubSprite(  bmp,'surname',0,28,false );
      bmp.Free;

      HHFP_Friendly ( aPlayer, 'f' ); // team e talent goalkeeper  , illumina celle di formazione libere
      Exit;
    end;
  end
  else if GameScreen = ScreenSubs then begin

    if Button = MbRight then begin
      se_dragGuid.DeleteSubSprite('surname');
      SE_DragGuid := nil;
      HideFP_Friendly_ALL;
      GameScreen := ScreenSubs ;
      Exit;
    end;

    // voglio fare una sostituzione

    aPlayer := MyBrain.GetSoccerPlayerReserve (aSpriteClicked.guid); // trova tutti  comunque
    if aPlayer = nil then                                            // ha cliccato un player in campo
      Exit;

    if MyBrain.Score.TeamSubs [ aPlayer.team ] >= 3 then begin
      CancelDrag ( aPlayer, aPlayer.CellX, aPlayer.CellY  );
      Exit;
    end;

    if aPlayer.GuidTeam  <> MyGuidTeam then
      Exit;   // sposto solo i miei   e solo quelli della panchina

    if (aPlayer.disqualified = 0) and (MyBrain.isReserveSlot ( aPlayer.CellX, aPlayer.CellY)) then begin
      SE_dragGuid := aSpriteClicked;
      bmp := CreateSurnameSubSprite (aPlayer);
      se_dragGuid.AddSubSprite(  bmp,'surname',0,28,false );
      bmp.Free;

      HHFP_Friendly ( aPlayer , 's' ); // team e talent goalkeeper a distanza < 4 , illumina celle di formazione occupate da compagni
    end;
  end;
end;
procedure TForm1.ScreenTacticsSubs_SE_TacticsSubs ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  i:Integer;
  aSprite: SE_Sprite;
begin

  if aSpriteClicked.Guid = 'btnmenu_back' then begin

    SE_TacticsSubs.Visible := False;
    aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
    aSprite.Visible := true;
    aSprite := SE_LIVE.FindSprite('btnmenu_subs');
    aSprite.Visible := True;
    aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
    aSprite.Visible := True;


    MyBrain.Ball.SE_Sprite.Visible := true;
    for I := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin     // player visibili
      MyBrain.lstSoccerPlayer [i].se_sprite.Visible := True;
    end;

    for I := 0 to MyBrain.lstSoccerReserve.Count -1  do begin    // panchina non visibile
      MyBrain.lstSoccerReserve [i].se_sprite.Visible := False;
    end;

    for I := 0 to MyBrain.lstSoccerGameOver.Count -1  do begin  // espulsi o già sostituiti o  avversari  SONO VISIBILI
      MyBrain.lstSoccerGameOver [i].se_sprite.Visible := true;
    end;

    SpriteReset;
    fGameScreen := ScreenLive;    // attenzione alla f, non innescare

  end;

end;
procedure TForm1.ScreenLive_SE_LIVE ( aSpriteClicked: SE_Sprite; Button: TMouseButton  );
var
  i:Integer;
  aSprite: SE_Sprite;
begin
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

  if aSpriteClicked.Guid = 'btnmenu_overridecolor' then begin
    overridecolor := true;
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      if MyBrain.lstSoccerPlayer[i].Team = 1 then begin
        MyBrain.lstSoccerPlayer[i].SE_Sprite.BlendMode := SE_BlendAverage;
      end;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_overridecolornormal' then begin
    overridecolor := false;
    for i := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      if MyBrain.lstSoccerPlayer[i].Team = 1 then begin
        MyBrain.lstSoccerPlayer[i].SE_Sprite.BlendMode := SE_BlendNormal;
      end;
    end;
  end
  else if aSpriteClicked.Guid = 'btnmenu_skillpass' then begin
    tcp.SendStr(  'PASS' + EndOfline );
  end
  else if aSpriteClicked.Guid = 'btnmenu_tactics' then begin

  (* Premuto durante la partita  mostra anche la formazione avversaria , premuto solo nel mio turno *)
  // posso cliccare quando è tuto fermo e quando sta a me. Se termina il tempo a disposizione , torna automaticamente in livemode con gamescreen = live
    SE_TacticsSubs.visible := True;
    aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
    aSprite.Visible := False;
    aSprite := SE_LIVE.FindSprite('btnmenu_subs');
    aSprite.Visible := False;
    aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
    aSprite.Visible := false;

    MyBrain.Ball.SE_Sprite.Visible := False;
    SE_Skills.Visible := False;
    MouseWaitFor := WaitForNone;
    hidechances ;
    GameScreen := ScreenTactics ;

  end
  else if aSpriteClicked.Guid = 'btnmenu_subs' then begin
  (* Premuto durante la partita , premuto solo nel mio turno *)
    SE_TacticsSubs.visible := True;
    aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
    aSprite.Visible := False;
    aSprite := SE_LIVE.FindSprite('btnmenu_subs');
    aSprite.Visible := False;
    aSprite:=SE_LIVE.FindSprite('btnmenu_skillpass' );
    aSprite.Visible := false;

    MyBrain.Ball.SE_Sprite.Visible := False;
    SE_Skills.Visible := False;
    MouseWaitFor := WaitForNone;
    hidechances ;
    GameScreen := ScreenSubs;
  end

end;
procedure TForm1.SE_Theater1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

  if (GameScreen = ScreenLive ) and ( Button = MbRight) then begin
    if SelectedPlayer <> nil then
      SelectedPlayer.se_sprite.DeleteSubSprite('mainskill' );
  end;
end;

procedure TForm1.SE_Theater1SpriteMouseDown(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Button: TMouseButton;
  Shift: TShiftState);
var
  i: integer;
begin

  if not se_Theater1.Active  then Exit;
  if (GameScreen = ScreenLive ) and ( Button = MbRight) then begin

    if SE_DragGuid <> nil then begin
      se_dragGuid.DeleteSubSprite('surname');
      SE_DragGuid := nil;
    end;
    HideFP_Friendly_ALL;
    MouseWaitFor := WaitForNone;
    hidechances ;
    SE_Green.Visible := false;
    SE_Skills.Visible := False;

    if SelectedPlayer <> nil then
      SelectedPlayer.se_sprite.DeleteSubSprite('mainskill' );

    Exit;
  end;

  for I := 0 to lstSprite.Count -1 do begin

    if GameScreen = ScreenFormation then begin
      if lstSprite[i].Engine = se_Players then begin   // sposto solo players , non altri sprites
        ScreenFormation_SE_Players ( lstSprite[i], Button );
        Exit;
      end
      else if  lstSprite[i].Engine = se_MainInterface then begin
        ScreenFormation_SE_MainInterface ( lstSprite[i], Button );
        Exit;

      end
      else if  lstSprite[i].Engine = se_Uniform then begin
        ScreenFormation_SE_Uniform ( lstSprite[i], Button );
       // c'è frameback, nessun exit

      end
    end
    else if GameScreen  = ScreenPlayerDetails then begin
      ScreenPlayerDetails_SE_PlayerDetails ( lstSprite[i], Button );
      Exit;
    end
    else if GameScreen  = ScreenAMl then begin
      ScreenAML_SE_AML ( lstSprite[i], Button );
      //Exit;
    end
    else if GameScreen  = ScreenMarket then begin
      ScreenMarket_SE_Market ( lstSprite[i], Button );
      //Exit;
    end
    else if (GameScreen  = ScreenSelectCountry) or (GameScreen  = ScreenSelectTeam) then begin
      ScreenSelectCountryTeam_SE_CountryTeam ( lstSprite[i], Button );
      //Exit;
    end

    else if (GameScreen  = ScreenSpectator) then begin
      if  lstSprite[i].Engine = se_GameOver then begin
        ScreenLive_SE_Gameover ( lstSprite[i], Button );// click che seleziona se_dragGuid . segue mouseup
        exit;
      end
      else if  lstSprite[i].Engine = SE_Spectator then begin
        ScreenSpectator_SE_Spectator ( lstSprite[i], Button );
        Exit;
      end;
    end
    else if (GameScreen  = ScreenWaitingLive) or (GameScreen  = ScreenWaitingSpectator) then begin
      ScreenWaitingLive_SE_Loading ( lstSprite[i], Button );
      Exit;
    end
    else if GameScreen = ScreenTactics then begin
      if lstSprite[i].Engine = se_TacticsSubs then begin
        ScreenTacticsSubs_SE_TacticsSubs ( lstSprite[i], Button );
        Exit;
      end
      else if  lstSprite[i].Engine = se_Players then begin
        ScreenTacticsSubs_SE_Players ( lstSprite[i], Button );// click che seleziona se_dragGuid . segue mouseup
        Exit;
      end;
    end
    else if GameScreen = ScreenSubs then begin
      if lstSprite[i].Engine = se_TacticsSubs then begin
        ScreenTacticsSubs_SE_TacticsSubs ( lstSprite[i], Button );
        Exit;
      end
      else if  lstSprite[i].Engine = se_Players then begin
        ScreenTacticsSubs_SE_Players ( lstSprite[i], Button );// click che seleziona se_dragGuid . segue mouseup
        Exit;
      end;
    end

    else if GameScreen = ScreenLive then begin
    // qui comincia il live. può cliccare l'engine SE_skills o l'engine SE_Live per accedere a sub e tactis. Anche SE_players e SE_fieldPoints
      if lstSprite[i].Engine = SE_Skills then begin
        if se_players.IsAnySpriteMoving or se_ball.IsAnySpriteMoving  or Animating then  exit;
        ScreenLive_SE_Skills ( lstSprite[i], Button );
        Exit;
      end
      else if lstSprite[i].Engine = SE_LIVE then begin
        ScreenLive_SE_LIVE ( lstSprite[i], Button );
        Exit;
      end
      else if lstSprite[i].Engine = SE_Green then begin  //se_Green arriva prima di tutti
        ScreenLive_SE_Green ( lstSprite[i], Button );
        Exit;
      end
      else if lstSprite[i].Engine = SE_Players then begin  //se_players arriva prima di fieldpoints
        if se_players.IsAnySpriteMoving or se_ball.IsAnySpriteMoving  or Animating then  exit;
        ScreenLive_SE_Players ( lstSprite[i], Button ); // no exit. gli spritesClicked devono passare tutti da qui. SE_fieldPoints. SE_players è ignorato
        continue;   // deve processare anche  SE_FieldPoints
      end
      else if lstSprite[i].Engine = SE_FieldPoints then begin
        if se_players.IsAnySpriteMoving or se_ball.IsAnySpriteMoving  or Animating then  exit;
        ScreenLive_SE_FieldPoints ( lstSprite[i], Button ); // no exit. gli spritesClicked devono passare tutti da qui. SE_fieldPoints. SE_players è ignorato
      end
      else if  lstSprite[i].Engine = se_GameOver then begin
        ScreenLive_SE_Gameover ( lstSprite[i], Button );// click che seleziona se_dragGuid . segue mouseup
        exit;
      end;
    end
    else if GameScreen = ScreenFreeKick then begin
      if lstSprite[i].Engine = SE_players then ScreenFreeKick_SE_Players(lstSprite[i], Button );
    end

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
  aPlayer.se_sprite.AddSubSprite( dir_player + '\' + MyActiveGender + '\'+IntTostr(aPlayer.Country) +'\'+IntTostr(aPlayer.face) +'.bmp' , 'face', 0  ,0,  true );
  aSubSprite := aPlayer.se_sprite.FindSubSprite('face' );
  aSubSprite.lBmp.Stretch (trunc (( aSubSprite.lBmp.Width * ScaleSpritesFace ) / 100), trunc (( aSubSprite.lBmp.Height * ScaleSpritesFace ) / 100)  );
  // qui non viene calcolato lo scale dello sprite.
  aPlayer.se_sprite.DrawFrame( SE_Theater1.AnimationInterval  ); // forza lo scale per cambiare position.xy
  aSubSprite.lX := (aPlayer.se_sprite.BMPCurrentFrame.Width div 2) - (aSubSprite.lBmp.Width div 2);  // center
  aSubSprite.ly := 0;  // center
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
  aPlayer.se_sprite.AddSubSprite( dir_player + IntTostr(aPlayer.face) +'.bmp' , 'face', 0  ,0, true  );
  aSubSprite :=aPlayer.se_sprite.FindSubSprite( 'face');
  aSubSprite.lBmp.Stretch (trunc (( aSubSprite.lBmp.Width * ScaleSpritesFace ) / 100), trunc (( aSubSprite.lBmp.Height * ScaleSpritesFace ) / 100)  );
  aSubSprite.lX := (aPlayer.se_sprite.BMPCurrentFrame.Width div 2) - (aSubSprite.lBmp.Width div 2);  // center
  aSubSprite.ly := 0;  // center
//  aPlayer.se_sprite.Scale := ScaleSpritesShow;
  ReleaseMutex(MutexAnimation);

  //aSprite.ChangeBitmap( IntTostr(aPlayer.face) +'.bmp',1,1,1000 );

end;

procedure TForm1.SE_Theater1SpriteMouseMove(Sender: TObject; lstSprite: TObjectList<DSE_theater.SE_Sprite>; Shift: TShiftState; Var Handled: boolean);
var
  aPlayer,aFriend,anOpponent: TSoccerPlayer;
  I,b,MoveValue, CellX, CellY, TalentId, st : Integer;
  aPoint: TPoint;
  anInteractivePlayer: TInteractivePlayer;
  ToEmptyCell, FriendlyWall, OpponentWall,FinalWall: Boolean;
  aSprite: SE_Sprite;
  aSpriteLabel: SE_SpriteLabel;
  ts : TStringList;
  BtnMenu,BtnLevelUp,Player,BtnTv,SkillMouseMove,UniformMouseMove: string;
  ScoreMouseMove,ScoreNick,UniformMouseMoveTF: boolean;
begin
  // una volta processati gli sprite settare  Handled:= TRUE o la SE:Theater non manderà più la lista degli sprite.

  if (not Se_Theater1.Active) then Exit;
  if SE_DragGuid <> nil then begin
    Handled := True;
    Exit;
  end;
  ScoreNick := False;
  ScoreMouseMove := False;
  BtnMenu := '';
  Player := '';
  BtnTv := '';
  SkillMouseMove := '';
  UniformMouseMove := '';
  UniformMouseMoveTF := False;
  TalentId := 0;
  for I := lstSprite.Count -1 downto 0 do begin   // lstSprite è protetta fino a quando handled è false

      // non usare EXIt ma continue
    if lstSprite[i].Engine = SE_Score  then begin
      if lstSprite[i].Guid = 'scorescore' then begin
          ScoreMouseMove := True;
          ClientLoadMatchInfo;
      end
      else if lstSprite[i].Guid = 'scorenick0' then begin
         ScoreNick := True;
         lstSprite[i].Labels[0].lText := MyBrain.Score.UserName[0];
         lstSprite[i].Labels[0].lX := GetXLabel (lstSprite[i].BMP.Bitmap,lstSprite[i].Labels[0].lText , lstSprite[i].BMP.Width, TStringCenter);
      end
      else if lstSprite[i].Guid = 'scorenick1' then begin
         ScoreNick := True;
         lstSprite[i].Labels[0].lText := MyBrain.Score.UserName[1];
         lstSprite[i].Labels[0].lX := GetXLabel (lstSprite[i].BMP.Bitmap,lstSprite[i].Labels[0].lText , lstSprite[i].BMP.Width, TStringCenter);
      end;
    end

    else if (lstSprite[i].Engine = SE_FieldPoints) or (lstSprite[i].Engine = SE_FieldPointsReserve) then  begin
      aPoint:= FieldGuid2Cell (lstSprite[i].guid);


     { if GameScreen = ScreenTactics then
        aPlayer:= MyBrain.GetSoccerPlayerDefault(aPoint.X, aPoint.Y  )
        else aPlayer:= MyBrain.GetSoccerPlayer2( aPoint.X, aPoint.Y );

      if ( GameScreen = ScreenLive) or ( GameScreen = ScreenSpectator) or ( GameScreen = ScreenSubs) or ( GameScreen = ScreenTactics)
      or ( GameScreen = ScreenCorner) or ( GameScreen = ScreenFreeKick) or ( GameScreen = ScreenPenalty)
       then begin
        if (aPlayer = nil) and ( Mouse.CursorPos.x > 1440-128) then begin
            aPlayer:= MyBrain.GetSoccerPlayer2( aPoint.X-11, aPoint.Y, 1 );
        end
        else if Mouse.CursorPos.x < 125 then begin
            aPlayer:= MyBrain.GetSoccerPlayer2( aPoint.X, aPoint.Y , 0);
        end;

      end;

      if aPlayer <> nil then begin
        player := aPlayer.Ids ;
      end; }

      CellX := aPoint.X;
      CellY := aPoint.Y;

      if GameScreen = ScreenLive then begin

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
         // CreateBaseAttribute (  CellX, CellY, SelectedPlayer.Passing );
          ArrowShowShpIntercept ( CellX, CellY, ToEmptyCell) ;
          HHFP( CellX, CellY, 0);
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
            HHFP (SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y, 0 );
            if  SelectedPlayer.HasBall then begin
              //CreateBaseAttribute (  CellX, CellY, SelectedPlayer.BallControl );
              ArrowShowMoveAutoTackle  ( SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y) ;
              HHFP (SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].X , SelectedPlayer.MovePath[SelectedPlayer.MovePath.count-1].Y, 0 );
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

          //CreateBaseAttribute (  CellX, CellY, SelectedPlayer.Passing );
          ArrowShowLopHeading( CellX, CellY, ToEmptyCell) ;
          HHFP( CellX, CellY, 0);
          if aFriend <> nil then begin
          //  CreateBaseAttribute (  CellX, CellY, aFriend.BallControl );
           // if aFriend.InCrossingArea then
           //   CreateBaseAttribute (  CellX, CellY, aFriend.Shot );
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
              //CreateBaseAttribute (  CellX, CellY, SelectedPlayer.Passing );
              ArrowShowCrossingHeading( CellX, CellY) ;
              //CreateBaseAttribute (  CellX, CellY, aFriend.heading );
              HHFP( CellX, CellY, 0);
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
          HHFP( CellX, CellY, 0);

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
    end
    else if (lstSprite[i].Engine = SE_PlayerDetails) then  begin // MouseMove su PlayerDetails Talents
      if (LeftStr(lstSprite[i].Guid,10) = 'btntalent_') or (LeftStr(lstSprite[i].Guid,10) = 'bartalent_') or (LeftStr(lstSprite[i].Guid,19) = 'playerdetailstalent')  then begin
        TalentId := StrToInt(lstSprite[i].stag);
        // talenttooltip
        aSprite:=SE_PlayerDetails.FindSprite('playerdetailstooltip' );
        aSprite.Labels.Clear;
        ts:= TStringlist.Create; ts.Delimiter := '|'; ts.StrictDelimiter := True;

        GetTooltipStrings ( lstSprite[i].BMP.Bitmap, Translate('descr_talent_' + StringTalents[TalentId]), ts );
        aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clYellow,clBlack,16,Capitalize(Translate( 'talent_' + StringTalents[TalentId]))+':',True  );
        aSprite.Labels.Add(aSpriteLabel);
        for st := 0 to ts.Count -1 do begin
          aSpriteLabel := SE_SpriteLabel.create( 0, (st+1)*18, 'Calibri',clWhite,clBlack,14,ts[st],True  );
          aSprite.Labels.Add(aSpriteLabel);
        end;
        ts.free;
        aSprite.Visible := True;
      end
      else if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then
        BtnMenu := lstSprite[i].Guid
      else if (LeftStr(lstSprite[i].Guid,7) = 'levelup') then
        BtnLevelUp := lstSprite[i].Guid
      else if (LeftStr(lstSprite[i].Guid,8) = 'talentup') then
        BtnLevelUp := lstSprite[i].Guid;


    end
    else if (lstSprite[i].Engine = SE_Maininterface)  then begin
      if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then
        BtnMenu := lstSprite[i].Guid;
      //  lstSprite[i].useBmpDimension := True;
      //  lstSprite[i].Scale := 120;
       // lstSprite[i].BlendMode := SE_BlendReflect;
    end
    else if (lstSprite[i].Engine = SE_AML)  then begin
      if (LeftStr(lstSprite[i].Guid,2) = 'tv') then begin
        BtnTv := lstSprite[i].Guid;
      end
      else if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then begin
        BtnMenu := lstSprite[i].Guid;
      end;
    end
    else if (lstSprite[i].Engine = SE_Market)  then begin
      if (LeftStr(lstSprite[i].Guid,6) = 'market') then begin
        BtnTv := lstSprite[i].Guid;
      end
      else if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then begin
        BtnMenu := lstSprite[i].Guid;
      end
      else if (LeftStr(lstSprite[i].Guid,3) = 'buy') then begin
        BtnMenu := lstSprite[i].Guid;
      end;
    end
    else if (lstSprite[i].Engine = SE_CountryTeam)  then begin
      if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then begin
        BtnMenu := lstSprite[i].Guid;
      end
      else if (LeftStr(lstSprite[i].Guid,8) = 'ctselect') then begin
        BtnMenu := lstSprite[i].Guid;
      end;
    end
    else if (lstSprite[i].Engine = SE_Spectator)  then begin
      if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then begin
        BtnMenu := lstSprite[i].Guid;
      end;
    end
    else if (lstSprite[i].Engine = SE_Live)  then begin
      if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then begin
        BtnMenu := lstSprite[i].Guid;
      end;
    end
    else if (lstSprite[i].Engine = SE_TacticsSubs)  then begin
      if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then begin
        BtnMenu := lstSprite[i].Guid;
      end;
    end
    else if (lstSprite[i].Engine = SE_Skills)  then begin
      SkillMouseMove := lstSprite[i].Guid;
    end
    else if (lstSprite[i].Engine = SE_Uniform)  then begin
      UniformMouseMove := lstSprite[i].Guid;
      if UniformMouseMove <> 'frameback' then
        UniformMouseMoveTF := True;
    end
    else if (lstSprite[i].Engine = SE_Loading)  then begin
      if (LeftStr(lstSprite[i].Guid,8) = 'btnmenu_') then begin
        BtnMenu := lstSprite[i].Guid;
      end;
    end
    else if (lstSprite[i].Engine = SE_Players) then begin
      Player := lstSprite[i].Guid;
    end;
  end;

  handled := True;
  if TalentId = 0 then begin
    aSprite:=SE_PlayerDetails.FindSprite('playerdetailstooltip' );
    aSprite.Visible := false;
  end;

  if UniformMouseMoveTF then begin
    SetGlobalCursor (crHandPoint);
    exit;
  end;

  if SkillMouseMove = '' then begin
    SE_interface.removeallSprites; // rimuovo le frecce
    SE_interface.ProcessSprites(2000);
    HideHH_Skill ;
    SetGlobalCursor (crDefault);
  end
  else begin
    SE_interface.removeallSprites; // rimuovo le frecce
    SE_interface.ProcessSprites(2000);
    HH_Skill ( SkillMouseMove );
    SetGlobalCursor (crHandPoint);
    if SkillMouseMove = 'Precision.Shot' then
     PrsMouseEnter
    else if SkillMouseMove = 'Power.Shot' then
     PosMouseEnter;

    Exit;
  end;

  if not ScoreMouseMove  then begin
    SE_Score.RemoveAllSprites('scoreframemf');
    SE_Score.ProcessSprites(2000);
    SetGlobalCursor (crDefault);
  end
  else begin
    SE_MainStats.Visible := False;
    SetGlobalCursor (crHandPoint);
    Exit;
  end;
  if not ScoreNick then begin
    aSprite := SE_Score.FindSprite('scorenick0');
    aSprite.Labels[0].lText := UpperCase( MyBrain.Score.Team [0]);
    aSprite.Labels[0].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[0].lText , aSprite.BMP.Width, TStringCenter);
    aSprite := SE_Score.FindSprite('scorenick1');
    aSprite.Labels[0].lText := UpperCase( MyBrain.Score.Team [1]);
    aSprite.Labels[0].lX := GetXLabel (aSprite.BMP.Bitmap,aSprite.Labels[0].lText , aSprite.BMP.Width, TStringCenter);
  end;


  if (BtnMenu <> '') or (BtnLevelup <> '') or (Player <> '')  or (BtnTv <> '')  then begin
    SetGlobalCursor (crHandPoint);
    if Player <> '' then begin
      aPlayer := MyBrain.GetSoccerPlayer2 (Player);
      ShowMainStats ( aPlayer );
    end
    else begin
      SE_MainStats.Visible := False;
      Player:='';
    end;
    Exit;
  end
  else begin
    SetGlobalCursor (crDefault);
    SE_MainStats.Visible := False;
    Exit;
  end;

end;
procedure TForm1.HideHH_Skill ;
var
  i,l: Integer;
begin
  for I := 0 to SE_Skills.SpriteCount -1 do begin
    for l := 0 to SE_Skills.Sprites[i].Labels.Count -1 do begin
      SE_Skills.Sprites[i].Labels[l].lFontColor := clWhite;
    end;
  end;
  SE_Skills.ProcessSprites(2000);

end;
procedure TForm1.HH_Skill ( SkillMouseMove: string );
var
  i,l: Integer;
begin
  for I := 0 to SE_Skills.SpriteCount -1 do begin
    for l := 0 to SE_Skills.Sprites[i].Labels.Count -1 do begin
      SE_Skills.Sprites[i].Labels[l].lFontColor := clWhite;
      if SE_Skills.Sprites[i].Guid = SkillMouseMove then
        SE_Skills.Sprites[i].Labels[l].lFontColor := clYellow;
    end;

  end;
  SE_Skills.ProcessSprites(2000);
end;

procedure TForm1.ClearInterface;
begin
  SE_interface.removeallSprites; // rimuovo le frecce
  SE_interface.ProcessSprites(2000);
  HideFP_Friendly_ALL;
end;
procedure TForm1.ArrowShowMoveAutoTackle ( CellX, CellY : Integer);
var
  i,au,MoveValue: Integer;
  aCellList: TList<TPoint>;
  label Myexit;
begin
  hidechances;
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
       // CreateBaseAttribute (  lstInteractivePlayers[au].Player.CellX, lstInteractivePlayers[au].Player.CellY, lstInteractivePlayers[au].Player.Defense );
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
  anIntercept, anOpponent: TSoccerPlayer;
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
           // CreateBaseAttribute (  aPath[i].X,aPath[i].Y, anOpponent.Defense );
          end;
      end

      else begin // no opponent ma possibile intercept su cella vuota

        for Y := 0 to lstInteractivePlayers.count -1 do begin
          anIntercept := lstInteractivePlayers[Y].Player;
          if ( lstInteractivePlayers[Y].Cell.X = aPath[i].X) and (lstInteractivePlayers[Y].Cell.Y = aPath[i].Y) then begin  // se questa cella
            lstInteractivePlayers[Y].Attribute := atDefense;  { TODO -csviluppo : intercept potrebbe usare atBallControl? }
            CreateArrowDirection( anIntercept, aPath[i].X,aPath[i].Y );
           // aFriend := MyBrain.GetSoccerPlayer ( CellX , CellY);
          //  if aFriend = nil then
   { toemptycells lo devo riportare adesso }
           // CreateBaseAttribute (  anIntercept.CellX, anIntercept.Celly, anIntercept.Defense )
           // else  CreateBaseAttribute (  anIntercept.CellX, anIntercept.Celly, anIntercept.Defense );

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
      //CreateArrowDirection( LstMoving[Y].Player, CellX,CellY );
      //CreateBaseAttribute (  CellX,CellY,  LstMoving[Y].Player.Speed );
    end;

    LstMoving.Free;
  end;


  aPath.Free;
end;
procedure TForm1.BtnBackBuyClick(Sender: TObject);
begin
  PanelBuy.Visible := false;
  SE_Market.ShowAllSprites;
end;

procedure TForm1.BtnBackDismissClick(Sender: TObject);
begin
  PanelDismiss.Visible:= False;
end;

procedure TForm1.BtnBackSellClick(Sender: TObject);
begin
  PanelSell.Visible := false;
end;

procedure TForm1.btnConfirmBuyClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    if MyBrainFormation.lstSoccerPlayer.Count < 22 then begin
      SE_Market.Visible := true;
      WAITING_GETFORMATION:= True;
      tcp.SendStr( 'buy,'+ IntToStr(PanelBuy.Tag) + EndofLine) // tag contiene 3625
    end
      else begin
      ShowError(Translate('warning_max18'));
      SE_Market.Visible := True;
    end;
    GCD := GCD_DEFAULT;
  end;

end;

procedure TForm1.BtnConfirmDismissClick(Sender: TObject);
begin
  if GCD <= 0 then begin
    WAITING_GETFORMATION:= True;
    PanelDismiss.Visible := false;
    tcp.SendStr( 'dismiss,'+ IntToStr(SE_BackGround.tag) + EndofLine); // solo a sinistra in formation
    GCD := GCD_DEFAULT;
  end;

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
       // CreateBaseAttribute (  aHeading.CellX, aHeading.CellY, aHeading.Heading );

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
      // CreateBaseAttribute (  LstMoving[Y].Player.CellX, LstMoving[Y].Player.CellY, LstMoving[Y].Player.Speed );
    end;

    LstMoving.Free;
  end;

end;

procedure TForm1.ArrowShowCrossingHeading ( CellX, CellY : Integer);
var
  y,BonusDefenseHeading: integer;
  aheading: TSoccerPlayer;
  aInteractivePlayer: TInteractivePlayer;
  ToEmptyCellMalus: integer;
//  LstMoving: TList<TInteractivePlayer>;

begin

  HHFP (CellX ,CellY,0);

  BonusDefenseHeading := MyBrain.GetCrossDefenseBonus (SelectedPlayer, CellX, CellY );
  // CRO Precompilo la lista di possibili Heading perchè non si ripetano
  MyBrain.CompileHeadingList (SelectedPlayer.Team{avversari di}, 1{MaxDistance}, CellX, CellY, lstInteractivePlayers  );
  for Y := 0 to lstInteractivePlayers.count -1 do begin
//    aHeading := lstInteractivePlayers[Y].Player;
       // cella per cella o trovo un opponent o trovo un intercept
    if ( lstInteractivePlayers[Y].Cell.X = CellX) and (lstInteractivePlayers[Y].Cell.Y = CellY) then begin  // se questa cella
     //     CalculateChance  ( aFriend.heading, aHeading.Heading + BonusDefenseHeading  , chanceA,chanceB,chanceColorA,chanceColorB);
     //     BaseHeading :=  LstHeading[Y].Player.Heading + BonusDefenseHeading;
     //     if Baseheading <= 0 then Baseheading :=1;
      CreateArrowDirection( lstInteractivePlayers[Y].Player, CellX,CellY );
     // CreateBaseAttribute (  lstInteractivePlayers[Y].Player.CellX,lstInteractivePlayers[Y].Player.CellY, lstInteractivePlayers[Y].Player.heading );

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
  //CreateBaseAttribute (  SelectedPlayer.CellX,SelectedPlayer.CellY, SelectedPlayer.BallControl +
  //    Abs(Integer(   (SelectedPlayer.TalentId1 = TALENT_ID_DRIBBLING) or (SelectedPlayer.TalentId2 = TALENT_ID_DRIBBLING)   ))  );
  //CreateBaseAttribute (  CellX,CellY, anOpponent.Defense  );

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
  Acell: TPoint;
  label reserve;
  label exitScreenSubs;
begin
  // corner / penalty / freekick usano semplici click in mousedown
  // MouseUp viene usata durante tactics e subs. Qui vengono gestite tactics e sub.
  if Se_DragGuid = nil then Exit;
  CellX := -1;
  CellY := -1;
  // imparo CellX e CellY .

  for I := 0 to lstSprite.Count -1 do begin
    if lstSprite[i].Engine = SE_FieldPoints then begin
   //   aFieldPointSpr := SE_FieldPoints.FindSprite(lstSprite[i].guid );
      Acell := FieldGuid2Cell ( lstSprite[i].guid);
      CellX := Acell.X;
      Celly := acell.Y;
      Break;
    end;
  end;

  aPlayer := MyBrain.GetSoccerPlayer2 (SE_DragGuid.Guid); // mouseup su qualsiasi cella
  //cellX e CellY devono essere in campo, mai fuori , sia in tactics che sub
  if CellX < 0 then begin      // test outside
    CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
    HideFP_Friendly_ALL;
    Exit;
  end;

  if GCD > 0 then begin
    CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
    se_dragGuid.DeleteSubSprite('surname');
    Se_DragGuid := nil;
    HideFP_Friendly_ALL;
    Exit;
  end;


  if GameScreen = ScreenTactics then begin


    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = SE_FieldPoints then begin   // sposto solo players , non altri sprites

        // il mouseup è solo in campo, mai click fuori dal campo
        aPlayer2 := MyBrain.GetSoccerPlayerDefault (CellX, CellY); // mouseup su qualsiasi cella
        if aPlayer2 <> nil then begin
          CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
          HideFP_Friendly_ALL;
         Exit; // deve essere una cella vuota non ocupata da player
        end;

        if (aPlayer.Team  = 0)
        and ( (CellX = 1) or (CellX = 3)  or (CellX = 4) or (CellX = 6) or (CellX = 7) or (CellX = 9) or (CellX = 10) or (CellX = 11) ) then Begin
          CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
          HideFP_Friendly_ALL;
          Exit;
        end;

        if (aPlayer.Team  = 1)
        and ( (CellX = 0) or (CellX = 1)  or (CellX = 2) or (CellX = 4) or (CellX = 5) or (CellX = 7) or (CellX = 8) or (CellX = 10) ) then Begin
          CancelDrag ( aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
          HideFP_Friendly_ALL;
          Exit;
        end;

          // se_dragguid deve essere uno già in campo
//        if MyBrain.isReserveSlot ( aPlayer.CellX , aPlayer.CellY ) then Exit;   //

        // gk solo nel posto del gk
        if (isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER) then  begin
          CancelDrag ( aPlayer,aPlayer.DefaultCellX , aPlayer.DefaultCellY );
          HideFP_Friendly_ALL;
          exit;    // un goalkeeper può essere schierato solo in porta
        end;
        if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.TalentId1 = TALENT_ID_GOALKEEPER) then begin    // un goalkeeper può essere schierato solo in porta
          CancelDrag (aPlayer, aPlayer.DefaultCellX , aPlayer.DefaultCellY );
          HideFP_Friendly_ALL;
          Exit;
        end;
        se_dragGuid.DeleteSubSprite('surname');
        SE_DragGuid := nil;
        tcp.SendStr( 'TACTIC,' + aPlayer.ids + ',' + IntToStr(CellX) + ',' + IntToStr(CellY) + EndOfLine );// il server risponde con clientLoadbrain
        HideFP_Friendly_ALL;
        fGameScreen := ScreenLive;
        Exit;


      end;


    end;
  end
  else if GameScreen = ScreenSubs then begin

    // le subs devono puntare celle in campo e occupate da player friendly
    for I := 0 to lstSprite.Count -1 do begin

      if lstSprite[i].Engine = SE_FieldPoints then begin   // sposto solo players , non altri sprites

        if MyBrain.Score.TeamSubs [ aPlayer.team ] >= 3 then goto exitScreenSubs;
        //cellX e CellY devono essere in campo, mai fuori
        if IsOutSide( CellX, CellY) then goto exitScreenSubs;
        if SE_DragGuid = nil then goto exitScreenSubs;


        // il mouseup è solo in campo, mai click fuori dal campo
        aPlayer2 := MyBrain.GetSoccerPlayer (CellX, CellY, aPlayer.Team); // mouseup su qualsiasi cella
        if aPlayer2 <> nil then begin
          // se_dragguid deve essere uno che proviene dalla panchina
          // gk solo nel posto del gk
          if MyBrain.w_CornerSetup or MyBrain.w_FreeKickSetup1 or MyBrain.w_FreeKickSetup2 or MyBrain.w_FreeKickSetup3 or MyBrain.w_FreeKickSetup4
          or (Mybrain.Score.TeamGuid [ Mybrain.TeamTurn ]  <> MyGuidTeam) then goto exitScreenSubs;
          if aPlayer.Ids = aPlayer2.Ids then goto exitScreenSubs;
          if (isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER) then goto exitScreenSubs;;    // un goalkeeper può essere schierato solo in porta
          if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 = TALENT_ID_GOALKEEPER) then goto exitScreenSubs;;    // un goalkeeper può essere schierato solo in porta
          if aPlayer.Team <>  MyBrain.TeamTurn  then goto exitScreenSubs;;  // sposto solo i miei
          if aPlayer.disqualified > 0 then goto exitScreenSubs;;  // non squalificati
          if not MyBrain.isReserveSlot ( aPlayer.CellX, aPlayer.cellY) then goto exitScreenSubs;; // solo uno dalla panchina su una cella già occupata
          if AbsDistance(aPlayer2.CellX, aPlayer2.CellY, MyBrain.Ball.CellX ,MyBrain.Ball.celly) < 4 then goto exitScreenSubs;;

          se_dragGuid.DeleteSubSprite('surname');
          SE_DragGuid := nil;
          HideFP_Friendly_ALL;
          tcp.SendStr( 'SUB,' + aPlayer.ids + ',' + aPlayer2.ids + EndOfLine );// il server risponde con clientLoadbrain
          fGameScreen := ScreenLive;
          Exit;
        end
        else begin // aplayer2 ! non esiste, metto via tutto
exitScreenSubs:
          se_dragGuid.DeleteSubSprite('surname');
          SE_DragGuid := nil;
          HideFP_Friendly_ALL;
          MoveInReserves(aPlayer);
          Exit;
        end;
      end;
    end;

  end;

end;

procedure TForm1.SetTcpFormation;
var
  i: Integer;
  TcpForm: TStringList;
  aPlayer: TSoccerPlayer;
begin
  if GCD <= 0 then begin
    TcpForm:= TStringList.Create ;
    FixDuplicateFormationMemory;
    for i := 0 to MyBrainFormation.lstSoccerPlayer.Count -1 do begin
      aPlayer := MyBrainFormation.lstSoccerPlayer[i];
  // il server valida anche gli Ids, qui il client non può perchè non conosce gli id
           TcpForm.Add( aPlayer.ids  + '=' +
           IntToStr(aPlayer.AIFormationCellX ) + ':' +
           IntToStr(aPlayer.AIFormationCellY ));
    end;

    WAITING_STOREFORMATION := True;
    tcp.SendStr(  'setformation,' +  TcpForm.CommaText + endofline);
    TcpForm.Free;
    GCD := GCD_DEFAULT;
  end;
end;

procedure TForm1.tcpDataAvailable(Sender: TObject; ErrCode: Word);
var
  I, LEN, totalString: Integer;
  Buf     : array [0..8191] of AnsiChar;
  Ts: TstringList;
  filename,tmpStr: string;
  MMbraindata: TMemoryStream;
  MMbraindataZIP: TMemoryStream;
  SignaturePK : string;
  SignatureBEGINBRAIN: string ;
  DeCompressedStream: TZDecompressionStream;
  s1,s2,s3,s4,s5,InBuffer: string;
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
//          Cli.SendStr( 'GUID,'+Cli.ActiveGender+',' + IntToStr(Cli.GuidTeams[2] ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + ',' +
//          'BEGINBRAIN' +  AnsiChar ( abrain.incMove )   +  brainManager.GetBrainStream ( abrain ) + EndofLine);

      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );
      viewMatch := false;
      LiveMatch := true;
      s1 := ExtractWordL (2, tmpStr, ',');
      s2 := ExtractWordL (3, tmpStr, ',');
      s3 := ExtractWordL (4, tmpStr, ',');
      s4 := ExtractWordL (5, tmpStr, ',');
      s5 := ExtractWordL (6, tmpStr, ',');
      MyGuidTeam :=  StrToInt(s2);
      MyGuidTeamName :=  s3;


      TotalString := 4 + 6 + Length (s1) + Length (s2) +Length (s3) +Length (s4)+ Length (s5) ; //4 è la lunghezza di 'GUID' e 6 sono le virgole
      LastTcpIncMove := ord (buf [TotalString + 10 ]); // 10 è lunghezza di BEGINBRAIN. mi posiziono sul primo byte che indica IncMove
      MemoC.Lines.Add('BEGINBRAIN '+  IntToStr(LastTcpIncMove) );
      MyActiveGender := s1;

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
        SE_players.RemoveAllSprites;
        SE_interface.RemoveAllSprites;
        GameScreen:= ScreenLive; // initializetheatermAtch
        CurrentIncMove := LastTcpIncMove;
        ClientLoadBrainMM (CurrentIncMove) ;   // (incmove)
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
          ClientLoadMatchInfo;
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
            SE_players.RemoveAllSprites;
            if viewMatch then
              GameScreen:= ScreenSpectator
            else if LiveMatch then
              GameScreen:= ScreenLive;
            CurrentIncMove := LastTcpIncMove;
            ClientLoadBrainMM (CurrentIncMove) ;   // (incmove)
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
     // GameScreen := ScreenFormation;

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
    else if MidStr(tmpStr,1,8 )= 'BEGINAML' then begin
      ThreadCurMove.Enabled := false; // parte solo in beginbrain
      MemoC.Lines.Add( 'Compressed size: ' + IntToStr(Len) );

      // elimino beginbrain
      MM2:= TMemoryStream.Create;
      MM2.Write( buf[8] , len - 8 ); // elimino beginAML

      // su mm3 ho 9c78 compressed
      DeCompressedStream:= TZDeCompressionStream.Create( MM2  );
      MM3[0].Clear;
//       DeCompressedStream.Position := 0;
      MM3[0].CopyFrom ( DeCompressedStream, 0);
      MM2.free;     // endsoccer si perde da solo decomprimendo
      DeCompressedStream.Free;
      CopyMemory( @Buf3[0][0], mm3[0].Memory , mm3[0].size  ); // copia del buf per non essere sovrascritti
      ClientLoadAML;
      GameScreen := ScreenAml;
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
      MyActiveGender :=ts[1];
      MyGuidTeam := StrToInt(ts[2]);
      MyGuidTeamName := ts[3];
      Caption := Edit1.Text + '-' + MyGuidTeamName;
      Sleep(1500); // GCD
      tcp.SendStr( 'getformation' + EndofLine);
      WAITING_GETFORMATION := True;
      //GameScreen := ScreenFormation;
    end
    else if  ts[0] = 'BEGINWT' then begin  // lista team della country selezionata

      ts.Delete(0); // BEGINWT
      TsNationTeams.CommaText := ts.CommaText;
      GameScreen := ScreenSelectTeam;

    end
    else if  ts[0] = 'BEGINWC' then begin // lista country
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
    end
    else if ts[0] = 'info' then begin
      lastStrError:= ts[1];
      ShowError( Translate( 'lbl_' + ts[1]));
      if lastStrError = 'errorlogin' then
        PanelLogin.Visible := true;
    end
    else if ts[0] = 'errorformation' then begin
      lastStrError:= ts[0];
      ShowError( Translate(ts[0]));
    end
    else if ts[0] = 'la' then begin  // level up attribute : guid, value
      ShowLevelUpA ( ts.commatext );
    end
    else if ts[0] = 'lt' then begin  // level up talent : guid, value
      ShowLevelUpT ( ts.commatext );
    end;
    // risponde con guid a cancelqueue
    //else if (ts[0] = 'cancelqueueok') or (ts[0] = 'cancelspectatorqueueok') or (ts[0] = 'closeviewmatchok') then begin
    //  GameScreen := ScreenFormation;
    //end;

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
      MyBrain.lstSoccerPlayer.Clear;
      MyBrain.lstSoccerReserve.Clear;
      MyBrain.lstSoccerPlayerALL.Clear;
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
          ClientLoadBrainMM ( CurrentIncMove);      //era false oppure se non c'è stringa commatext
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
  pbSprite: SE_SpriteProgressBar;
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
    pbSprite := SE_SpriteProgressBar( SE_Score.FindSprite('scorebartime'));
    pbSprite.Value := (localseconds * 100) div 120;
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
        ClientLoadBrainMM ( Trunc(toolSpin.Value)-1 );
      end;

      CurrentIncMove :=  Trunc(toolSpin.Value);
      ClientLoadScript( Trunc(toolSpin.Value) );
      if Mybrain.tsScript.Count = 0 then begin
        ClientLoadBrainMM ( Trunc(toolSpin.Value) );
      end
      else
        LoadAnimationScript; // if ts[0] = server_Plm CL_ ecc..... il vecchio ClientLoadbrain . alla fine il thread chiama  ClientLoadBrainMM
    end;
    //else begin
    //  ShowMessage('file missing');
    //end;

  end;
  {$endif tools}
end;
procedure TForm1.GetTooltipStrings ( bmp: TBitmap; aString: string; var ts: Tstringlist );
var
  i, x, nLines,Start : integer;
begin
  ts.Clear;
  if Length(aString)  <= 104 then begin
    ts.DelimitedText := aString;
    Exit;
  end;

  nLines := (Length(aString)  div 104) +1;
  Start := 0;
  for I := 0 to nLines -1 do begin
    if (aString[Start+104] <> ' ' ) or (aString[Start+104] <> ',' ) or (aString[Start+104] <> '.' )then begin
      for x := Start+104 -1 downto 1 do begin // cerco il primo spazio
        if aString[x] = ' ' then begin
          ts.DelimitedText :=ts.DelimitedText +  ( MidStr(aString,start,x)) + '|';
          Start := Start + x;
        end;
      end;

    end;
  end;
end;

procedure TForm1.SetGameScreen (const aGameScreen:TGameScreen);
var
  i: Integer;
  aPlayer: TSoccerPlayer;
  aFieldPointSpr: SE_Sprite;
  aSprite : SE_Sprite;

begin

  fGameScreen:= aGameScreen;

  if fGameScreen = ScreenLogin then begin
    //AudioCrowd.Stop;
    IndexCT :=0;

    SE_BackGround.HideAllSprites;
    aSprite := SE_Background.FindSprite('backgroundlogin');
    aSprite.Visible := True;

    WaitForSingleObject ( MutexAnimation, INFINITE );
    AnimationScript.Reset;
    FirstLoadOK:= False;
    Animating := false;
    ReleaseMutex(MutexAnimation );
    LastTcpIncMove := 0;
    CurrentIncMove := 0;

    viewMatch := False;

    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    SE_Uniform.Visible := False;
    HideStadiumAndPlayers;
    SE_PlayerDetails.Visible := False;
    SE_Aml.Visible := False;
    SE_Market.Visible := False;
    SE_Spectator.Visible := False;
    SE_Live.Visible := False;
    SE_Green.Visible:= False;
    SE_TacticsSubs.Visible := False;
    SE_Score.Visible := False;
    SE_CountryTeam.Visible := false;
    PanelSell.Visible := False;
    PanelDismiss.Visible := False;
    SE_Skills.Visible := False;


    PanelLogin.Visible := True;
    PanelLogin.BringToFront;
    overrideColor := false;

  end
  else if (fGameScreen = ScreenSelectCountry) or (fGameScreen = ScreenSelectTeam )then begin
    //AudioCrowd.Stop;
    aSprite := SE_Background.FindSprite('backgroundlogin');
    aSprite.Visible := True;

    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    PanelLogin.Visible := false;
    SE_Uniform.Visible := False;
    SE_MainInterface.Visible := False;
    SE_MainStats.Visible := False;
    SE_PlayerDetails.Visible := False;
    HideStadiumAndPlayers;
    SE_Aml.Visible := False;
    SE_Market.Visible := False;
    SE_Spectator.Visible := False;
    SE_Live.Visible := False;
    SE_Green.Visible:= False;
    SE_TacticsSubs.Visible := False;
    SE_Score.Visible := False;
    SE_CountryTeam.Visible := True;

    if fGameScreen = ScreenSelectCountry then begin
      SE_CountryTeam.Tag := 0;
      ClientLoadCountries (0); // indexCT

    end
    else if fGameScreen = ScreenSelectTeam then begin

      SE_CountryTeam.Tag := 1;
      ClientLoadTeams (0); // indexCT
    end;

  end
  else if fGameScreen = ScreenWaitingFormation then begin // si accede cliccando back - settcpformation, in attesa
    //AudioCrowd.Stop;

    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    PanelLogin.Visible := false;
    SE_Uniform.Visible := False;
    SE_MainStats.Visible := False;
    SE_PlayerDetails.Visible := False;
    SE_Aml.Visible := False;
    SE_Market.Visible := False;
    SE_Spectator.Visible := False;
    SE_Live.Visible := False;
    SE_Green.Visible:= False;
    SE_Score.Visible := False;
    SE_CountryTeam.Visible := False;
    aSprite := SE_ball.FindSprite('ball');
    if aSprite <> nil then
      aSprite.Visible := false;

    //SE_players.Visible := False;  SE_MainInterface.Visible := False;  SE_FieldPoints.HiddenSpritesMouseMove := false;  SE_FieldPointsReserve.HiddenSpritesMouseMove := false;>SE_MainStats.Visible := False;
    HideStadiumAndPlayers;

    LiveMatch := False;
    viewMatch := False;
 // MyBrainFormation.lstSoccerPlayer.clear;  //<-- rimuove gli sprite
//    MyBrain:= MyBrainFormation; // <--- assegno MyBrain.
    MyBrainFormation := MyBrain; // <--- assegno MyBrain.



    SE_players.RemoveAllSprites;
    SE_players.ProcessSprites(2000);
    PanelError.Visible := False;

    ShowLoading;
    MouseWaitFor := WaitForNone;
  end
  else if fGameScreen = ScreenFormation then begin    // diversa da ScreenLiveFormations che prende i dati dal brain
    SE_DragGuid := nil; //<-- nel caso mi trovi in Sub o Tactics.

//    MyBrain:= MyBrainFormation; // <--- assegno MyBrain.
    SE_GameOver.visible := False;
    SE_RANK.Visible:= True;

    MyBrainFormation := MyBrain; // <--- assegno MyBrain.
    SE_Uniform.Visible := False;
    SE_Loading.Visible := False;
    SE_MainInterface.Visible := true;
    SE_MainStats.Visible := False;
    PanelLogin.Visible := false;
    SE_Aml.Visible := False;
    SE_Market.Visible := False;
    SE_Spectator.Visible := False;
    SE_Live.Visible := False;
    SE_Green.Visible:= False;
    SE_Score.Visible := False;
    SE_CountryTeam.Visible := False;
    SE_PlayerDetails.Visible := False;
    //AudioCrowd.Stop;
    PanelSell.Visible := False;
    PanelDismiss.Visible := False;

    ShowStadiumAndPlayers (0);

    SE_interface.ClickSprites := false;
    ThreadCurMove.Enabled := false; // parte solo in beginbrain
    WaitForSingleObject ( MutexAnimation, INFINITE );
    AnimationScript.Reset;
    FirstLoadOK:= False;
    Animating := false;
    ReleaseMutex(MutexAnimation );
    LastTcpIncMove := 0;
    CurrentIncMove := 0;

    LiveMatch := False;
    viewMatch := False;
    PanelError.Visible := False;

    MouseWaitFor := WaitForNone;
    overrideColor := false;
    if MyActiveGender = 'f' then begin
      aSprite := SE_MainInterface.FindSprite('btnmenu_f');
      aSprite.Alpha := 255;
      aSprite := SE_MainInterface.FindSprite('btnmenu_m');
      aSprite.Alpha := 80;
    end
    else begin
      aSprite := SE_MainInterface.FindSprite('btnmenu_f');
      aSprite.Alpha := 80;
      aSprite := SE_MainInterface.FindSprite('btnmenu_m');
      aSprite.Alpha := 255;
    end;

  end
  else if fGameScreen = ScreenPlayerDetails then begin
    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    SE_Uniform.Visible := False;
    HideStadiumAndPlayers;
    LiveMatch := False;
    viewMatch := False;
    MouseWaitFor := WaitForNone;

  end
  else if fGameScreen = ScreenTactics then begin    // btnTACTICS prende i dati dal brain

    SE_Green.Visible:= False;
    // passo da cells a defaultcell. Non è' visibile anche l'avversario

    for I := 0 to MyBrain.lstSoccerPlayer.Count -1 do begin
      aPlayer := MyBrain.lstSoccerPlayer [i];
      if aPlayer.GuidTeam <> MyGuidTeam then begin
        aPlayer.se_sprite.Visible := False;
        Continue;    // espulsi o già sostituiti o  avversari
      end;

      aFieldPointSpr := SE_FieldPoints.FindSprite(IntToStr (aPlayer.DefaultCellX ) + '.' + IntToStr (aPlayer.DefaultCellY ));
      aPlayer.se_Sprite.Position := aFieldPointSpr.position  ;
      aPlayer.se_sprite.MoverData.Destination := aFieldPointSpr.Position;
      aPlayer.se_sprite.Visible := True;

    end;
    for I := 0 to MyBrain.lstSoccerReserve.Count -1  do begin
      MyBrain.lstSoccerReserve [i].se_sprite.Visible := False;
    end;
    for I := 0 to MyBrain.lstSoccerGameOver.Count -1  do begin
       // qui vedo la panchina avversaria ma nel ousedown non posso selezionarli
      MyBrain.lstSoccerGameOver [i].se_sprite.Visible := false;
    end;
    MouseWaitFor := WaitForNone;
    SE_FieldPointsReserve.HiddenSpritesMouseMove := true;


  end
  else if fGameScreen = ScreenSubs then begin    // btnSubs

    SE_Green.Visible:= False;

    for I := 0 to MyBrain.lstSoccerPlayer.Count -1  do begin
      aPlayer := MyBrain.lstSoccerPlayer [i];
        // rendo invisibili i player espulsi o già sostituiti e tutti i player hostile
      if aPlayer.GuidTeam <> MyGuidTeam  then begin
        aPlayer.se_sprite.Visible := False;
        Continue;    // espulsi o già sostituiti o  avversari
      end;

      // rendo invisibili i player friendly IN CAMPO distanti >= 4
      if AbsDistance(aPlayer.CellX, aPlayer .CellY, MyBrain.Ball.CellX ,MyBrain.Ball.celly) < 4 then
        aPlayer.se_sprite.Visible := False;
    end;

    for I := 0 to MyBrain.lstSoccerReserve.Count -1  do begin
       // qui vedo la panchina avversaria ma nel ousedown non posso selezionarli
      MyBrain.lstSoccerReserve [i].se_sprite.Visible := true;
    end;

    for I := 0 to MyBrain.lstSoccerGameOver.Count -1  do begin
       // qui vedo la panchina avversaria ma nel ousedown non posso selezionarli
      MyBrain.lstSoccerGameOver [i].se_sprite.Visible := false;
    end;

    MouseWaitFor := WaitForNone;
    SE_FieldPointsReserve.HiddenSpritesMouseMove := true;


  end


  else if fGameScreen = ScreenWaitingLive then begin // si accede cliccando queue
    //AudioCrowd.Stop;
    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;

    PanelLogin.Visible := false;
    SE_Uniform.Visible := False;
    SE_CountryTeam.Visible := False;
    SE_PlayerDetails.Visible := False;
    SE_Aml.Visible := False;
    SE_Market.Visible := False;
    SE_Spectator.Visible := False;
    SE_Live.Visible := False;
    SE_Green.Visible:= False;
    SE_Score.Visible := False;

    HideStadiumAndPlayers;
    SE_players.RemoveAllSprites;
    ShowLoading;
    LiveMatch := True;
    viewMatch := False;
    MouseWaitFor := WaitForNone;
    overrideColor := false;

  end
  else if fGameScreen = ScreenLive  then begin

    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    SE_Loading.Visible := False;
    SE_Uniform.Visible := False;
    PanelLogin.Visible := false;
    SE_CountryTeam.Visible := False;
    SE_MainInterface.Visible := False;
    SE_MainStats.Visible := False;
    SE_PlayerDetails.Visible := False;
    SE_Players.Visible := False;
    SE_Aml.Visible := False;
    SE_Spectator.Visible := False;
    SE_CountryTeam.Visible := false;
    SE_Score.Visible := True;
    SE_Green.Visible:= False;

    ShowStadiumAndPlayers(1);

    // annulla tutto in tactics e subs
    if SE_DragGuid <> nil then begin
      SE_DragGuid.DeleteSubSprite('surname');
      SE_DragGuid := nil;
    end;

    SE_TacticsSubs.Visible := false;
    aSprite := SE_LIVE.FindSprite('btnmenu_tactics');
    aSprite.Visible := true;
    aSprite := SE_LIVE.FindSprite('btnmenu_subs');
    aSprite.Visible := True;

    SE_Live.Visible := true;

    PanelError.Visible := False;
    LiveMatch := True;
    viewMatch := False;
    MouseWaitFor := WaitForNone;

  end
  else if  fGameScreen = ScreenSpectator then begin

    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    SE_Loading.Visible := False;
    PanelLogin.Visible := false;
    SE_Uniform.Visible := False;
    SE_CountryTeam.Visible := False;

    SE_MainInterface.Visible := False;
    SE_MainStats.Visible := False;
    SE_PlayerDetails.Visible := False;
    SE_Players.Visible := False;
    SE_Aml.Visible := False;
    SE_Market.Visible := false;
    SE_Spectator.Visible := True;
    SE_Live.Visible := false;
    SE_Green.Visible:= False;
    SE_Score.Visible := True;
    ShowStadiumAndPlayers(1);

    LiveMatch := False;
    viewMatch := True;
    MouseWaitFor := WaitForNone;
    SE_FieldPointsReserve.HiddenSpritesMouseMove := false;

  end
  else if fGameScreen = ScreenWaitingSpectator then begin // si accede cliccando l'icona TV
    //AudioCrowd.Stop;


    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    PanelLogin.Visible := false;
    SE_Uniform.Visible := False;
    SE_CountryTeam.Visible := False;
    SE_PlayerDetails.Visible := False;
    SE_Aml.Visible := False;
    SE_Market.Visible := false;
    SE_Spectator.Visible := false;
    SE_Live.Visible := false;
    SE_Green.Visible:= False;
    SE_TacticsSubs.Visible := False;
    SE_Score.Visible := false;
    SE_CountryTeam.Visible := false;

    HideStadiumAndPlayers;
    SE_players.RemoveAllSprites;
    SE_PlayerDetails.HideAllSprites;
    LiveMatch := False;
    viewMatch := True;


    ShowLoading;
    MouseWaitFor := WaitForNone;
    overrideColor := false;

  end
  else if fGameScreen = ScreenAML then begin
    //AudioCrowd.Stop;
    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    SE_BackGround.HideAllSprites;
    aSprite := SE_Background.FindSprite('backgroundaml');
    aSprite.Visible := True;
    HideStadiumAndPlayers;
    PanelLogin.Visible := false;
    SE_Uniform.Visible := False;
    SE_CountryTeam.Visible := False;
    SE_PlayerDetails.Visible := False;
    SE_Market.Visible := false;
    SE_Spectator.Visible := False;
    SE_Live.Visible := False;
    SE_Green.Visible:= False;
    SE_TacticsSubs.Visible := False;
    SE_Score.Visible := False;
    SE_CountryTeam.Visible := false;

    SE_Aml.Visible := True;

    LiveMatch := False;
    viewMatch := False;
    MouseWaitFor := WaitForNone;



  end
  else if fGameScreen = ScreenMarket then begin
    //AudioCrowd.Stop;
    SE_BackGround.HideAllSprites;
    aSprite := SE_Background.FindSprite('backgroundmarket');
    aSprite.Visible := True;


    SE_GameOver.visible := False;
    SE_RANK.Visible:= False;
    PanelLogin.Visible := false;
    SE_Uniform.Visible := False;
    SE_CountryTeam.Visible := false;
    SE_PlayerDetails.Visible := False;
    SE_Aml.Visible := False;
    SE_Market.Visible := False;
    SE_Spectator.Visible := False;
    SE_Live.Visible := False;
    SE_Green.Visible:= False;
    SE_Score.Visible := False;
    SE_TacticsSubs.Visible := False;
    SE_Aml.Visible := False;
    SE_Market.Visible := True;

    HideStadiumAndPlayers;

    LiveMatch := False;
    viewMatch := False;
    MouseWaitFor := WaitForNone;

  end;


end;
procedure TForm1.ClientLoadCountries ( index: Integer);
var
  i: Integer;
  aSprite: SE_Sprite;
begin
  SE_CountryTeam.HideAllSprites ('ctselect');
  SE_CountryTeam.HideAllSprites ('countryteam');

  if IndexCT > TsWorldCountries.Count -1 then
    IndexCT := (TsWorldCountries.Count ) - 20;
  if IndexCT < 0 then
    IndexCT := 0;

  for i := 0 to 19 do begin
    if IndexCT+i < TsWorldCountries.count then begin
      aSprite :=  SE_CountryTeam.FindSprite('countryteam'+IntToStr(i));
      aSprite.Labels[0].lText := TsWorldCountries.ValueFromIndex[indexCT+i];
      aSprite.Labels[0].lX := GetXLabel( aSprite.BMP.Bitmap, aSprite.Labels[0].lText,aSprite.BMP.Width, tStringCenter );
      aSprite.Visible := True;
      aSprite :=  SE_CountryTeam.FindSprite('ctselect'+IntToStr(i));
      aSprite.sTag := TsWorldCountries.Names[indexCT+i];
      aSprite.Visible := True;
    end
    else Exit;
  end;
end;
procedure TForm1.ClientLoadTeams ( index: Integer);
var
  i: Integer;
  aSprite: SE_Sprite;
begin
  SE_CountryTeam.HideAllSprites ('ctselect');
  SE_CountryTeam.HideAllSprites ('countryteam');

  if IndexCT > TsNationTeams.Count -1 then
    IndexCT := (TsNationTeams.Count ) - 20;
  if IndexCT < 0 then
    IndexCT := 0;

  for i := 0 to 19 do begin
    if indexCT+i < TsNationTeams.count then begin
      aSprite :=  SE_CountryTeam.FindSprite('countryteam'+IntToStr(i));
      aSprite.Labels[0].lText := TsNationTeams.ValueFromIndex[indexCT+i];
      aSprite.Labels[0].lX := GetXLabel( aSprite.BMP.Bitmap, aSprite.Labels[0].lText,aSprite.BMP.Width, tStringCenter );
      aSprite.Visible := True;
      aSprite :=  SE_CountryTeam.FindSprite('ctselect'+IntToStr(i));
      aSprite.sTag := TsNationTeams.Names[indexCT+i];
      aSprite.Visible := True;
    end
    else Exit;
  end;
end;
procedure TForm1.ClientLoadAML ;
var
  i,count,Country0,Country1,ActiveMatchesCount,Cur,LBrainIds,LUserName0,LUserName1,LTeamName0,LTeamName1: Integer;
  bmpflags, cBitmap: SE_Bitmap;
  SS : TStringStream;
  aSprite, aTvSprite: SE_Sprite;
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


  // a 0 c'è la word che indica dove comincia
  cur := 0;
  ActiveMatchesCount:=   PWORD(@buf3[0][ cur ])^;                // ragiona in base 0
  Cur := Cur + 2; // è una word


//label 0  LUserName0
//label 1  team0
//label 2  gol
//label 3  team1
//label 4  LUserName1
//label 5  minute
  SE_Aml.HideAllSprites ('match')  ;
  SE_Aml.HideAllSprites ('tv')  ;
  for I := 0 to ActiveMatchesCount -1 do begin
    aSprite :=  SE_Aml.FindSprite('match'+IntToStr(i));

    LBrainIds :=  Ord( buf3[0][ cur ]);                 // assegno lbrainIds
    aTvSprite :=  SE_Aml.FindSprite('tv'+IntToStr(i));
    aTvSprite.sTag :=  MidStr( dataStr, cur + 2  , LBrainIds );
    aTvSprite.Visible := True;
    cur  := cur + LBrainIds + 1;

    LuserName0 :=  Ord( buf3[0][ cur ]);
    aSprite.Labels[0].lText :=  MidStr( dataStr, cur + 2  , LuserName0);
    aSprite.Labels[0].lX := XUsername0 + GetXLabel ( aSprite.bmp.Bitmap,Capitalize(aSprite.Labels[0].lText),WUsername, TStringCenter );
    cur  := cur + LuserName0 + 1;

    LuserName1 :=  Ord( buf3[0][ cur ]);
    aSprite.Labels[4].lText :=  MidStr( dataStr, cur + 2  , LuserName1);
    aSprite.Labels[4].lX := XUsername1 + GetXLabel ( aSprite.bmp.Bitmap,Capitalize(aSprite.Labels[4].lText),WUsername, TStringCenter );
    cur  := cur + LuserName1 + 1;

    LTeamName0 :=  Ord( buf3[0][ cur ]);
    aSprite.Labels[1].lText :=  MidStr( dataStr, cur + 2  , LTeamName0 ) ;//+ ' - ';
    aSprite.Labels[1].lX := XTeamName0 + GetXLabel ( aSprite.bmp.Bitmap,Capitalize(aSprite.Labels[1].lText ),WTeamName, TStringCenter );
    cur  := cur + LTeamName0 + 1;

    LTeamName1 :=  Ord( buf3[0][ cur ]);
    aSprite.Labels[3].lText := MidStr( dataStr, cur + 2  , LTeamName1 ) ;
    aSprite.Labels[3].lX := XTeamName1 + GetXLabel ( aSprite.bmp.Bitmap,Capitalize(aSprite.Labels[3].lText ),WTeamName, TStringCenter );
    cur  := cur + LTeamName1 + 1;
//    aSprite.Labels[1].lText :=  MidStr( dataStr, cur + 2  , LTeamName0 ) + + ' - ' + LTeamName1;


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
    cBitmap.Stretch(40,32);
    cBitmap.CopyRectTo( aSprite.SubSprites[0].lBmp, 0,0,0,0,40,32,False,0 );
    cBitmap.Free;
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
    cBitmap.Stretch(40,32);
    cBitmap.CopyRectTo( aSprite.SubSprites[1].lBmp, 0,0,0,0,40,32,False,0 );
    cBitmap.Free;
    Cur := Cur + 2;


    aSprite.Labels[2].lText :=  IntToStr( ord ( buf3[0][ cur ]));   // gol 0
    aSprite.Labels[2].lX := XScore;
    Cur := Cur + 1;
    aSprite.Labels[2].lText := aSprite.Labels[2].lText +'-'+ IntToStr( ord ( buf3[0][ cur ]));   // gol 1
    Cur := Cur + 1;

    aSprite.Labels[5].lText :=  IntToStr ( ord ( buf3[0][ cur ])) +'''' ;
    aSprite.Labels[5].lX := XMinute + GetXLabel ( aSprite.bmp.Bitmap,Capitalize(aSprite.Labels[5].lText ),WMinute, TStringCenter );
    Cur := Cur + 1;

    aSprite.Visible := true;
  end;

  bmpflags.Free;
end;
procedure TForm1.ClientLoadMarket ;
var
  i,L,RecordCount,Cur,LSurName,Age,face,country,fitness,morale : Integer;
  talentID1, talentId2 : byte;
  cBitmap: SE_Bitmap;
  SS : TStringStream;
  aSprite, aBuySprite: SE_Sprite;
  aSubSprite : SE_SubSprite;
  dataStr,SellPrice: string;
  MatchesPlayed,MatchesLeft: Word;
  x,y: Integer;
  bmpflags,bmp : SE_Bitmap;
  const W=32;H=32;
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
      MM.Write( @face, sizeof ( word ) );
      MM.Write( @country, sizeof ( word ) );
      MM.Write( @fitness, sizeof ( byte ) );
}
  // su MM3 globale c'è la lista
  bmpflags := SE_Bitmap.Create ( dir_interface + 'flags.bmp');

  SS := TStringStream.Create;
  SS.Size := MM3[0].Size;
  MM3[0].Position := 0;
  ss.CopyFrom( MM3[0], MM3[0].size );
  //    dataStr := RemoveEndOfLine(string(buf));
  dataStr := SS.DataString;
  SS.Free;

  // a 0 c'è la word che indica dove comincia
  cur := 0;
  RecordCount:=   PWORD(@buf3[0][ cur ])^;                // ragiona in base 0

  Cur := Cur + 2; // è una word

  // svuoto i dati di prima, per esempio se sono di più di prima o swicth m f rimangono in memroia nelle labels
  for I := 0 to 19 do begin
    aSprite :=  SE_Market.FindSprite('market'+IntToStr(i));
    aSprite.sTag := ''; // ids servirà per comprare
    aSprite.RemoveAllSubSprites;
    for L := aSprite.Labels.Count -1 downto 0 do begin
      aSprite.Labels[L].lText := '';
    end;

  end;
  SE_Market.ProcessSprites(2000);

  SE_Market.HideAllSprites ('market');
  SE_Market.HideAllSprites ('buy');
  aSprite :=  SE_Market.FindSprite('columns');
  aSprite.Visible := True;

  SE_Market.ShowAllSprites;
  for I := 0 to RecordCount -1 do begin
    aSprite :=  SE_Market.FindSprite('market'+IntToStr(i));
    //aSprite.Visible := True;
    aSprite.sTag := IntToStr( PDWORD(@buf3[0][ cur ])^); // ids servirà per comprare
    aSprite.Bmp.Canvas.Font.Size := FontSizeMarket;
    aSprite.Bmp.Canvas.Font.Name := 'Calibri';

    Cur := Cur + 4;

    LSurname :=  Ord( buf3[0][ cur ]);
    aSprite.Labels[0].lText  := MidStr( dataStr, cur + 2  , LSurname );// ragiona in base 1
    aSprite.Labels[0].lX :=  64; //appena più a destra del face
    cur  := cur + LSurname + 1;

    SellPrice :=  IntToStr( PDWORD(@buf3[0][ cur ])^); // sellprice
    aSprite.Labels[1].lText   :=  FloatToStrF(StrToInt(SellPrice), ffCurrency, 10, 0);
    aSprite.Labels[1].lX :=   1364 - aSprite.Bmp.Canvas.TextWidth (aSprite.Labels[1].lText); // XPrice + GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[1].lText,WPrice,TStringRight );
    Cur := Cur + 4;

    aSprite.Labels[2].lText  :=  IntToStr( Ord( buf3[0][ cur ]));  // speed
    aSprite.Labels[2].lX :=   XSpeed + GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[2].lText,WSpeed,TStringCenter );
    Cur := Cur + 1;
    aSprite.Labels[3].lText   :=  IntToStr( Ord( buf3[0][ cur ]));  //
    aSprite.Labels[3].lX :=   XDefense + GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[3].lText,WDefense,TStringCenter );
    Cur := Cur + 1;
    aSprite.Labels[4].lText   :=  IntToStr( Ord( buf3[0][ cur ]));  //
    aSprite.Labels[4].lX :=   XPassing + GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[4].lText,WPassing,TStringCenter );
    Cur := Cur + 1;
    aSprite.Labels[5].lText   :=  IntToStr( Ord( buf3[0][ cur ]));  //
    aSprite.Labels[5].lX :=   XBallControl + GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[5].lText,WBallControl,TStringCenter );
    Cur := Cur + 1;
    aSprite.Labels[6].lText   :=  IntToStr( Ord( buf3[0][ cur ]));  //
    aSprite.Labels[6].lX :=   XShot + GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[6].lText,WShot,TStringCenter );
    Cur := Cur + 1;
    aSprite.Labels[7].lText   :=  IntToStr( Ord( buf3[0][ cur ]));  // heading
    aSprite.Labels[7].lX :=   XHeading + GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[7].lText,WHeading,TStringCenter );
    Cur := Cur + 1;

    talentID1 :=  Ord( buf3[0][ cur ]);
    Cur := Cur + 1;
    talentID2:=  Ord( buf3[0][ cur ]);
    Cur := Cur + 1;

    //aSprite.DeleteSubSprite('t1'); sopra c'è removeallsubsprites
    //aSprite.DeleteSubSprite('t2');
    if talentID1 <> 0 then begin    // i talenti li devo creare dinamicamente o rimangono a video
      aSprite.AddSubSprite(dir_talent + IntToStr( talentID1 )+'.bmp','t1',XTalents ,0,true);
    end;
    if talentID2 <> 0 then begin
      aSprite.AddSubSprite(dir_talent + IntToStr( talentID2 )+'.bmp','t2',XTalents + W + 12,0,true); //
    end;

    MatchesPlayed :=  PWORD(@buf3[0][ cur ])^;
    Cur := Cur + 2;


    Age:= Trunc(  MatchesPlayed  div SEASON_MATCHES) + 18 ;

    MatchesLeft :=  PWORD(@buf3[0][ cur ])^;
    Cur := Cur + 2;
    face :=  PWORD(@buf3[0][ cur ])^;
    Cur := Cur + 2;



    aSprite.Labels[8].lText  :=  IntToStr( age );
    aSprite.Labels[8].lX :=   XAge +  GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[8].lText,WAge,TStringCenter );
    aSprite.Labels[9].lText  :=  IntToStr( MatchesLeft );
    aSprite.Labels[9].lX :=   XMatchsLeft + GetXLabel(aSprite.BMP.Bitmap,aSprite.Labels[9].lText,WMatchsLeft,TStringCenter );

    country :=  PWORD(@buf3[0][ cur ])^;
    Cur := Cur + 2;

    // country        sub   0
    bmp := SE_Bitmap.Create ( 40,H ); // flags bandiere sono stretchate 40 x 32
    aSprite.AddSubSprite(bmp,'country',0 ,0,True);
    bmp.free;

    // face           sub    1
    bmp := SE_Bitmap.Create ( W,H ); // face W x H
    aSprite.AddSubSprite(bmp,'face',32,0,true); // 32 si sovrappone ma sopra alla bandiera. va bene
    bmp.free;

    // fitness        sub     2
    bmp := SE_Bitmap.Create ( W,H ); // face W x H
    aSprite.AddSubSprite(bmp,'fitness',XFitness+20,0,true); // 32 si sovrappone ma sopra alla bandiera. va bene
    bmp.free;

    cBitmap := SE_Bitmap.Create ( dir_player + '\' + MyActiveGender + '\'+IntTostr(Country) +'\'+IntTostr(face) +'.bmp');
    cBitmap.Stretch(W,H);
    aSubSprite :=  aSprite.FindSubSprite('face');
    cBitmap.CopyRectTo( aSubSprite.lBmp, 0,0,0,0,W,H,True,0 );
    cBitmap.Free;


    cBitmap := SE_Bitmap.Create (60,40);



    case Country  of
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
    cBitmap.Stretch(40,32);
    aSubSprite :=  aSprite.FindSubSprite('country');
    cBitmap.CopyRectTo( aSubSprite.lBmp, 0,0,0,0,40,32,False,0 );
    cBitmap.Free;




    Fitness :=  Ord( buf3[0] [ cur ]);
    Cur := Cur + 1;


    cBitmap := SE_Bitmap.Create ( dir_interface + IntToStr (Fitness)+'.bmp' ) ;
    aSubSprite :=  aSprite.FindSubSprite('fitness');
    cBitmap.CopyRectTo( aSubSprite.lBmp, 0,0,0,0,W,H,True,0 );
    cBitmap.Free;

    // morale non  lo mostro

  end;

  bmpflags.Free;
  aSprite := SE_Market.FindSprite('money');
  aSprite.Labels[0].lText := FloatToStrF(Money, ffCurrency, 10, 0);

end;
function TForm1.GetAttributeColor ( value: integer ): TColor;
begin
  if MyBrain.Gender = 'f' then begin

    case value  of
      1..2: Result := clRed;
      3..4: Result := $0080ff;
      5..6: Result := clLime;
    end;
  end
  else begin
    case value  of
      1..3: Result := clRed;
      4..6: Result := $0080ff;
      7..10: Result := clLime;
    end;
  end;
end;
function TForm1.GetAttributeColorSpeed ( value: integer ): TColor;
begin

  case value  of
    1: Result := clRed;
    2: Result := $0080ff;
    3..4: Result := clLime;
  end;


end;
function TForm1.GetXLabel ( bmp: TBitmap; aString: String; FrameWidth: integer; StringAlignment : TStringAlignment ): Integer;
var
  w: Integer;
begin
  w:= BMP.Canvas.TextWidth(aString) ;
  if StringAlignment = TStringCenter then begin
    Result := (FrameWidth - w) div 2;
  end
  else if StringAlignment = TStringRight then begin
    Result := FrameWidth - w ;
  end;

end;
procedure TForm1.RenewUniform ( ha: Integer );
var
  i: Integer;
  aPlayer: TSoccerPlayer;
begin
  for I := 0 to SE_players.SpriteCount -1 do  begin

    aPlayer := MyBrainFormation.GetSoccerPlayer( SE_players.Sprites[i].guid );
    if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
      SE_players.Sprites[i].ChangeBitmap(  dir_tmp + 'color' + IntTostr(ha)+ '.bmp' , 1,1,1000)    // non cambia le face che sono subsprites
    else
      SE_players.Sprites[i].ChangeBitmap(  dir_tmp + 'colorgk.bmp' , 1,1,1000);

  end;
end;
Function TForm1.Translate ( aString : string  ): String;
begin
   Result :=  TranslateMessages.Values [aString];
end;
procedure TForm1.ShowError ( AString: string);
begin
  lbl_Error.Font.Color := clwhite;
  lbl_Error.Caption := AString;
  PanelError.Visible:= true;
  PanelError.Left := (Form1.Width div 2) - (PanelError.Width div 2);
  PanelError.Top := (Form1.Height div 2) - (PanelError.Height div 2);
  BtnErrorOK.Caption := 'OK';
  PanelError.BringToFront;

end;
procedure TForm1.ShowInfo ( AString: string);
begin
  lbl_Error.Font.Color := clwhite;
  lbl_Error.Caption := AString;
  PanelError.Visible:= true;
  PanelError.Left := (Form1.Width div 2) - (PanelError.Width div 2);
  PanelError.Top := (Form1.Height div 2) - (PanelError.Height div 2);
  BtnErrorOK.Caption := Capitalize(Translate ('lbl_Close'));
  PanelError.BringToFront;

end;
procedure TForm1.ShowGameOver ( MoneyStarVisible: boolean);
var
  bmp: SE_Bitmap;
  aBtnSprite,aSprite: SE_Sprite;
  aSubSprite: SE_SubSprite;
  aSpriteLabel : SE_SpriteLabel;
  index,MoneyGain, miGain:Integer;
  MoneyGainS,miGainS: string;
begin
  // è tutto dinamico. il button elimina tutti gli sprites
  // 3 label: endgame, team e risultato , icona + money, e le star con il rank . le creo qui in showGameOver e le distruggo sul button
        { TODO : continuare qui }

  SE_GameOver.RemoveAllSprites;
  SE_GameOver.ProcessSprites(2000);
  // copiata e incollata dal server
  if MyBrain.Score.TeamGuid[0]= MyGuidTeam then begin
    index := 0;
    if MyBrain.Score.gol[0] > MyBrain.Score.gol[1] then
      miGain := 2
    else if MyBrain.Score.gol[0] = MyBrain.Score.gol[1] then
      miGain := 0
    else if MyBrain.Score.gol[0] < MyBrain.Score.gol[1] then
      miGain := -3;

  end
  else if MyBrain.Score.TeamGuid[1]= MyGuidTeam then begin
    index := 1;
    if MyBrain.Score.gol[1] > MyBrain.Score.gol[0] then
      miGain := 3
    else if MyBrain.Score.gol[1] = MyBrain.Score.gol[0] then
      miGain := 1
    else if MyBrain.Score.gol[1] < MyBrain.Score.gol[0] then
      miGain := -2;
  end;

  if Mybrain.Gender='m' then begin
    case MyBrain.Score.rank[index] of
      1:MoneyGain := (1000 * miGain);
      2:MoneyGain := (800 * miGain);
      3:MoneyGain := (600 * miGain);
      4:MoneyGain := (400 * miGain);
      5:MoneyGain := (200 * miGain);
      6:MoneyGain := (100 * miGain);
    end;

  end
  else begin // female
    case MyBrain.Score.rank[index] of
      1:MoneyGain := (600 * miGain);
      2:MoneyGain := (480 * miGain);
      3:MoneyGain := (460 * miGain);
      4:MoneyGain := (340 * miGain);
      5:MoneyGain := (220 * miGain);
      6:MoneyGain := (100 * miGain);
    end;

    ViewMatch := True;
  end;

  // è tutto dinamico. il button elimina tutti gli sprites
  // 3 label: endgame, team e risultato , icona + money, e le star con il rank . le creo qui in showGameOver e le distruggo sul button

  // backframe
  aSprite:=SE_Uniform.CreateSprite(dir_interface + 'bgmanagergo.bmp' ,'frameback',1,1,1000,SE_Theater1.VirtualWidth div 2  ,SE_Theater1.Virtualheight div 2 ,false );
  aSprite.Priority := 1;
//close
  bmp := SE_Bitmap.Create ( dir_interface + 'button.bmp' );
  aBtnSprite:=SE_GameOver.CreateSprite(bmp.Bitmap ,'btnmenu_back',1,1,1000,90,280,true );
//  aSpriteLabel := SE_SpriteLabel.create( -1,YLBLMAINBUTTON,'Calibri',clWhite,clBlack,FontSize, Translate('lbl_Tactics') ,true  );
//  aBtnSprite.Labels.Add( aSpriteLabel);
  aBtnSprite.TransparentForced := True;
  aBtnSprite.TransparentColor := aBtnSprite.BMP.Canvas.Pixels[5,5];
  aBtnSprite.AddSubSprite( dir_interface +'arrowl.bmp', 'sub',90-40,56-40,True );
  aBtnSprite.Priority := 1200;
  bmp.Free;

  // label End_Game
  // label teamName and Score

  // money
  if MoneyStarVisible then begin
                                                                            { TODO : centrare bene }
    aSprite := SE_RANK.CreateSprite(dir_interface + 'money.bmp','gold', 1,1,1000,305,40,true);
    aSprite.Priority := 1200;

    bmp := SE_Bitmap.Create (300,22);
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect( 0,0,bmp.Width,bmp.Height));
    if MoneyGain > 0 then
      MoneyGainS := '+ ' + IntToStr(MoneyGain)
        else if MoneyGain < 0 then
          MoneyGainS := '- ' + IntToStr(MoneyGain);

    aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clYellow,clBlack,16, MoneyGainS ,True  );
    aSprite := SE_RANK.CreateSprite(bmp.bitmap,'money', 1,1,1000,490,40,true);
    aSprite.Labels.Add(aSpriteLabel);
    aSprite.Priority := 1200;
    bmp.Free;

    // star
    aSprite := SE_RANK.CreateSprite(dir_interface + 'stary.bmp','stary', 1,1,1000,305,40,true);
    aSprite.Priority := 1200;

    bmp := SE_Bitmap.Create (300,22);
    bmp.Bitmap.Canvas.Brush.Color :=  clGray;
    bmp.Bitmap.Canvas.FillRect(Rect( 0,0,bmp.Width,bmp.Height));
    if MiGain > 0 then
      MiGainS := '+ ' + IntToStr(MoneyGain)
        else if MiGain < 0 then
          MiGainS := '- ' + IntToStr(MiGain);

    aSpriteLabel := SE_SpriteLabel.create( 0,0,'Calibri',clYellow,clBlack,16, MiGainS ,True  );
    aSprite := SE_RANK.CreateSprite(bmp.bitmap,'money', 1,1,1000,490,40,true);
    aSprite.Labels.Add(aSpriteLabel);
    aSprite.Priority := 1200;
    bmp.Free;

  end;

  SE_GameOver.Visible := True;

end;

procedure TForm1.ShowLevelUpA ( TS: string );
var
  aPlayer: TSoccerPlayer;
  tslocal : TStringList;
begin
//  TS[0]  la
//  TS[1]  guid player
//  TS[2] value succes or not
//  TS[3],3,4,5,6,7.....  xpstring
  tslocal := TStringList.Create;
  tslocal.CommaText := TS;

  GameScreen := ScreenFormation;
  aPlayer := MyBrainFormation.GetSoccerPlayerALL ( tslocal[1] );
  PanelError.Left := (Form1.Width div 2) - (PanelError.Width div 2);
  PanelError.Top := (Form1.Height div 2) - (PanelError.Height div 2);
  BtnErrorOK.Caption := 'OK';

  if tslocal[2] <> '0' then begin
    lbl_Error.Caption := aPlayer.SurName + ' è appena migliorato!';
    lbl_error.color := clLime;
    PanelError.Color := clLime;
  end
  else begin
    lbl_Error.Caption := 'Purtroppo ' + aPlayer.SurName + ' non è riuscito a migliorare.';
    lbl_error.color := clRed;
    PanelError.Color := clRed;
  end;
  PanelError.Visible:= true;
  PanelError.BringToFront;

  tslocal.Delete(0); // elimino guid e value già usati
  tslocal.Delete(0); // rimane la xpString
  tslocal.Delete(0); // rimane la xpString
  aPlayer.xp_Speed         := StrToInt( tslocal[0]);
  aPlayer.xp_Defense       := StrToInt( tslocal[1]);
  aPlayer.xp_Passing       := StrToInt( tslocal[2]);
  aPlayer.xp_BallControl   := StrToInt( tslocal[3]);
  aPlayer.xp_Shot          := StrToInt( tslocal[4]);
  aPlayer.xp_Heading       := StrToInt( tslocal[5]);
  tslocal.Free;

end;
procedure TForm1.ShowLevelUpT ( TS: string);
var
  aPlayer: TSoccerPlayer;
  i: Integer;
  tslocal : TStringList;
begin
//  TS[0]  lt
//  TS[1]  guid player
//  TS[2] value succes or not
//  TS[3],3,4,5,6,7.....  xpstring

  tslocal := TStringList.Create;
  tslocal.CommaText := TS;

  GameScreen := ScreenFormation;
  aPlayer := MyBrainFormation.GetSoccerPlayerALL ( tslocal[1] );
  PanelError.Left := (Form1.Width div 2) - (PanelError.Width div 2);
  PanelError.Top := (Form1.Height div 2) - (PanelError.Height div 2);
  BtnErrorOK.Caption := 'OK';

  if tslocal[2] <> '0' then begin
    lbl_Error.Caption := aPlayer.SurName + ' ha nuovi talenti!';
    lbl_error.color := clLime;
    PanelError.Color := clLime;
  end
  else begin
    lbl_Error.Caption := 'Purtroppo ' + aPlayer.SurName + ' non è riuscito a sviluppare il talento.';
    lbl_error.color := clRed;
    PanelError.Color := clRed;
  end;

  PanelError.Visible:= true;
  PanelError.BringToFront;

  tslocal.Delete(0); // elimino la o lt ,guid e value già usati
  tslocal.Delete(0); // rimane la xpString
  tslocal.Delete(0); // rimane la xpString
  for I := 1 to NUM_TALENT do begin
    aPlayer.XpTal[i] := StrToInt( tslocal[i+5]);
  end;
  tslocal.Free;


end;
procedure TForm1.FocusMarketPlayer ( aSprite: SE_Sprite);
begin
  SE_Market.HideAllSprites;
  aSprite.Visible := True;
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

  if Mybrain.Ball.Player <> nil then begin
    if  AbsDistance (Mybrain.Ball.Player.CellX ,Mybrain.Ball.Player.CellY, SelectedPlayer.CellX, SelectedPlayer.CellY ) = 1 then begin

      CreateArrowDirection ( SelectedPlayer , Mybrain.Ball.Player );
        SelectedPlayer.SurName, SelectedPlayer.Ids, 'VS',IntToStr(SelectedPlayer.Defense + SelectedPlayer.Tal_Toughness));
        Mybrain.Ball.Player.SurName, Mybrain.Ball.Player.Ids, 'VS',IntToStr(Mybrain.Ball.Player.BallControl + Mybrain.Ball.Player.Tal_Power));
     // CreateTextChanceValueSE ( Mybrain.Ball.Player.ids, Mybrain.Ball.Player.BallControl + Mybrain.Ball.Player.tal_Power   , 0,0,0,0 );
     // CreateTextChanceValueSE ( SelectedPlayer.ids, SelectedPlayer.Defense + SelectedPlayer.tal_toughness  , 0,0,0,0);
    end;
  end;

end;


}
end.


