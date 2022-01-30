{$R-}

//{$DEFINE ADDITIONAL_MATCHINFO}
unit SoccerBrainv3;


interface
uses DSE_theater, DSE_Random, DSE_PathPlanner,  DSE_MISC,
  generics.collections, generics.defaults, system.classes, ZLIBEX,
  System.SysUtils, System.Types, strutils, Inifiles, IOUtils, winapi.windows , forms, SoccerAIv3, SoccerTypes ;


const Schemas = 4;           // numero di schema delle uniformi

const MAX_LEVEL = 30;
const modifier_autotackle = 0;
const TurnMoves = 4;              // Numero di mosse per turno
const TurnMovesStart = 2;         // il calcio d'inizio ha solo 2 mosse
const SEASON_MATCHES = 38;        // numero di partite a stagione
const REGEN_STAMINA = 10;         // rigenerazione stamina dopo 1 partita
const YELLOW_DISQUALIFIED = 3;
const GKXP_REDUCTION = 20; // 20% di fare xp
const xp_SPEED_POINTS = 120;
const xp_DEFENSE_POINTS = 120;
const xp_PASSING_POINTS = 120;
const xp_BALLCONTROL_POINTS = 120;
const xp_SHOT_POINTS = 80;
const xp_HEADING_POINTS = 80;

const F_DEFENSESHOT = 3;
const M_DEFENSESHOT = 5;

// Queste costanti sono uguali al DB game.talents . Gli ID devono corrispondere
const NUM_TALENT               = 24; // totale talenti di livelo 1
const TALENT_ID_GOALKEEPER     = 1;  // può giocare in porta
const TALENT_ID_CHALLENGE      = 2;  // lottatore + 1 autotackle
const TALENT_ID_TOUGHNESS      = 3;  // +1 tackle
const TALENT_ID_POWER          = 4;  // +1 resist tackle
const TALENT_ID_CROSSING       = 5;  // +1 crossing
const TALENT_ID_LONGPASS       = 6;  // +1 distanza passaggi
const TALENT_ID_EXPERIENCE     = 7;  // pressing non costa mosse
const TALENT_ID_DRIBBLING      = 8;  // +1 dribbling
const TALENT_ID_BULLDOG        = 9;  // mastino +1 intercept
const TALENT_ID_OFFENSIVE      = 10; // durante ai_moveall tende ad attaccare
const TALENT_ID_DEFENSIVE      = 11; // durante ai_moveall tende a difendere
const TALENT_ID_BOMB           = 12; // tal_bomb è un +1 quando si buffa con corsa o riceve shp o vince tackle o vince dribbling
const TALENT_ID_PLAYMAKER      = 13; // Cerca di avvicinarsi al proprio portatore di palla. Inoltre i suoi passaggi corti terminanti in area avversaria conferiscono un bonus al ricevente.
const TALENT_ID_FAUL           = 14; // +15% chance di commettere un fallo. -30% chance di subire sanzioni.
const TALENT_ID_MARKING        = 15; // DIF=Marca l'attaccante con il Tiro piu' alto. Cen=Marca il Centrocampista con il passaggio piu' alto. ATT=Marca il difensore con il Controllo piu' basso.
const TALENT_ID_POSITIONING    = 16; // Cerca di tornare verso la propria zona di campo. talent2 offensive=ala o centravanti talent2 defensive=chiude le fascie o il centro
const TALENT_ID_FREEKICKS      = 17; // +1 Tiro sui Calci di punizione e rigori.
const TALENT_ID_AGILITY        = 18; // Quando riceve un passaggio corto distante almeno 2 celle, non costa mosse.
const TALENT_ID_RAPIDPASSING   = 19; // Ha il 33% chance di effettuare un passaggio verso un compagno. non può essere intercettato
const TALENT_ID_AGGRESSION     = 20; // cerca il portatore di palla
const TALENT_ID_ACE            = 21; // Ha il 33% chance di effettuare un dribbling vincente quando subisce pressing
const TALENT_ID_HEADING        = 22; // Ha una chance del 5% di ottenere +1 durante i colpi di testa.
const TALENT_ID_FINISHING      = 23; // Quando ottiene la palla dopo un rimbalzo ha +1 Tiro.
const TALENT_ID_DIVING         = 24; // +10% chance di subire un fallo durante i tackle.
//------------------------------------------------------------------
 { nel server c'è array xpNeedTAL[I] e si puntano così xpTAL[TALENT_ID_EXPERIENCE]. da modificare se si modifica qui}
const LOW_TALENT2              = 128; // id basso talenti di livelo 2
const HIGH_TALENT2             = 141; // id alto talenti di livelo 2
const LOW_TALENT2_GK           = 250; // id basso talenti di livelo 2 solo del portiere (GK)
const HIGH_TALENT2_GK          = 251; // id alto talenti di livelo 2 solo del portiere (GK)

const TALENT_ID_ADVANCED_CHALLENGE  = 128; // prereq difesa 3/5 TALENT_ID_CHALLENGE  --> 5% chance +1 autotackle
const TALENT_ID_ADVANCED_TOUGHNESS  = 129; // prereq difesa 3/5 TALENT_ID_TOUGHNESS  --> 5% chance +1 tackle
const TALENT_ID_ADVANCED_POWER      = 130;    // prereq ballcontrol 3 TALENT_ID_POWER  --> 5% chance +1 resist tackle
const TALENT_ID_ADVANCED_CROSSING   = 131; // prereq passing 3/5 TALENT_ID_CROSSING  -->  5% chance +2 crossing
const TALENT_ID_ADVANCED_EXPERIENCE = 132; // prereq TALENT_ID_EXPERIENCE  --> pressing costa cpst_pre - 1
const TALENT_ID_ADVANCED_DRIBBLING  = 133; // prereq TALENT_ID_DRIBBLING --> +2 totale dribbling  . strutture alzano questa chance
const TALENT_ID_ADVANCED_BULLDOG    = 134;  // prereq TALENT_ID_BULLDOG mastino +2 intercept
const TALENT_ID_ADVANCED_AGGRESSION = 135; // prereq TALENT_ID_AGGRESSION fa pressing automatico sul portatore di palla se lo raggiunge. 25% chance. no sistema di cariche qui.
const TALENT_ID_ADVANCED_BOMB       = 136; //  prereq tiro 3/5 talent bomb --> 5% chance che si attivi da solo tiro +2 su powershot, non precision.shot

const TALENT_ID_PRECISE_CROSSING = 137; // prereq passing 3 TALENT_ID_CROSSING  --> +1 crossing dal fondo
const  TALENT_ID_SUPER_DRIBBLING = 138; // prereq almeno 3 ball.control, talent dribbling --> dribbling +3 chance 15%  ( dribbling2 è +1 fisso )

const TALENT_ID_BUFF_DEFENSE = 139; //prereq almeno 3/5 Defense, 1 talento qualsiasi --> skill 2x buff reparto (5% chance) dif 20 turni + defense ballcontrol passing  +1
const  TALENT_ID_BUFF_MIDDLE = 140; //prereq almeno 3/5 passing, 1 talento qualsiasi --> skill 2x buff reparto (5% chance) cen  20 turni + speed max 4,ballcontrol,passing ,shot +1
const  TALENT_ID_BUFF_FORWARD = 141; //prereq almeno 3/5 Shot , 1 talento qualsiasi --> skill 2x buff reparto (5% chance) att 20 turni + ballcontrol, passing,shot +1

const TALENT_ID_GKMIRACLE = 250; //solo GK  Ha una chance del 10% di ottenere +2 Difesa sui tiri precisi a distanza 1. Non valido sui rigori.
const TALENT_ID_GKPENALTY = 251; //specialista para rigori. ottiene +1 10% chance .



const Turnmilliseconds = 120 * 1000;// 120 secondi per turno giocatore;

// costi in stamina delle singole skill
const cost_bac = 1; // ball control su lop
const cost_plm = 1;
const cost_mov = 0;  // ai_moveAll
const cost_shp = 0;
const cost_lop = 1;
const cost_pre = 3;
const cost_pro = 2;
const cost_dri = 1;
const cost_cro = 2;
const cost_prs = 2;
const cost_pos = 2;
const cost_hea = 2;
const cost_tac = 3;
const cost_autotac = 2;
const cost_cor = 1;
const cost_defshot = 1;
const cost_defdrib = 3;
const cost_GKprs = 6;
const cost_GKHeading = 8;
const cost_GKpos = 10;


   const ShortPassRange       = 2;
   const LoftedPassRangeMin   = 2;
   const LoftedPassRangeMax   = 4;
   const CrossingRangeMin     = 2;
   const CrossingRangeMax     = 5;
   const PowerShotRange       = 3;
   const PrecisionShotRange   = 3;
   const TackleDiff           = 2;
   const VolleyRangeMin       = 3;

const MARKET_VALUE_ATTRIBUTE_DEFENSE_GK = 3; // i portieri valgono il doppio attributo difesa
const MARKET_VALUE_ATTRIBUTE : array[1..10] of Single = (1, 2, 16, 64, 256, 512, 1024, 2048, 4096, 8192 ) ;
const MARKET_VALUE_TALENT1 = 1.4 ;
const MARKET_VALUE_TALENT2 = 1.2 ;
const GOLD_START = 210 ;

type TDecMovesLeft = ( DecNone, DecNormal, DecNoResetPlayer);
//--------------------------------------------------------
Type TShotCell = Class
  DoorTeam: integer;
  CellX: integer;
  CellY: integer;
  subCell : TList<Tpoint>;
  Constructor Create;
  Destructor Destroy;override;
end;
type TChance = record
  Value : integer;
  Modifier: Integer;
  Modifier2: Integer; // es. 5% +1 autotackle. è una chance da mostare con un trattino
  aString : string;
  aString2 : string;
end;
type TDoorTeam = ( DoorFriendly, DoorOpponent);
type TGameMode =(pvnull,pve,pvp);
type TTVCrossAreaCell = record
  DoorTeam: integer;
  CellX: integer;
  CellY: integer;
end;
type TAICrossAreaCell = record
  DoorTeam: TDoorTeam;
  CellX: integer;
  CellY: integer;
end;
type TFieldCell = record
  Team: byte;
  AI,TV: Tpoint;
end;

//--------------------------------------------------------

//TYPE  TAIProcedure    = procedure of object;
type TShortPoint = record
  X,Y: ShortInt;
end;
type TTacticType = ( D4M, D4F, M4D, M4F, F4d,F4M );
type TTackleDirection = ( TackleBack, TackleSide, TackleAhead );
type TBottomPosition = ( NearCornerCell, BottomNoShot, BottomShot, BottomNone, BottomNoneCanCross);
TYPE TNotifyFileData    = procedure (filename: string ) of object;
type TMoveModeX = ( LeftToRight, RightToLeft, Xnone);
type TMoveModeY= ( UpToDown, DownToUp, Ynone);
type TOneDir= ( TruncOneDir, AbortMultipleDirection, EveryDirection);
type TTrueFalse = array[Boolean] of String;
type TCornerMode = ( OpponentCorner, FriendlyCorner );
type TFormationCell = record  // conversione per AI e formations
  CellX, CellY : Integer;
  Team: array[0..1] of TPoint;
  Role: char;
end;
type Tscore = record
  CliId: array[0..1] of integer; // cliId o account
  UserName : array [0..1] of string[32];
  Team: array[0..1] of string  [35];   // name
  Country: array[0..1] of word;
  TeamGuid: array[0..1] of integer;
  TeamSubs: array[0..1] of ShortInt;
  Rank : array[0..1] of Byte;
  TeamMI: array[0..1] of integer;
  Season: array[0..1] of integer;
  SeasonRound: array[0..1] of byte;
  Points: array[0..1] of byte;       // non sono i points del db. queste partono a 0 e serve al finalizeBrain
  Uniform: array[0..1] of string [12];
  DominantColor: array[0..1] of Integer;
  FontColor: array[0..1] of Integer;
  gol : array[0..1] of Byte;
  BuffD : array[0..1] of ShortInt;
  BuffM : array[0..1] of ShortInt;
  BuffF : array[0..1] of ShortInt;
  Minute : SmallInt;
  AI: array[0..1] of boolean;
  lstGol : string; //2=2434,6=1274 .... poi gestista come Tstringlist
end;

type TRoll = record
  value: ShortInt; // può andare a -1 poi essere corretto
  fatigue: char;
end;
type TFormation = record          // formazioni es. 4-4-2
  d,m,f: Integer;                 // Defend,Mddle,Forward  = difensori, centrocampisti, attaccanti
  Cells: array [2..11] of TPoint; // parte in base 2. il GK (portiere) è escluso perchè è sempre presente.
end;

type TAIMidChance = record
  X: Integer;
  Y: Integer;
  Chance: Integer;
  inputAI: string;
  //AiProc : TAIProcedure;
end;
type TAICells = record
  chance: Integer;
  Cells: TPoint;
end;
type TCellAndPlayer = record
  Player : string;
  chance: integer;
  CellX: integer;
  CellY: integer;
end;
type TVirtualPlayer = record
  ids : string;
  Team : byte;
  VirtualCellX: integer;
  VirtualCellY: integer;
  canMove: Boolean;
  Role: char;
end;

Type  TCornerMap = record
  Team : integer;           // corner a favore di questo team
  GK: TPoint;               // Portiere avversario al corner
  CornerCell: TPoint;
  HeadingCellA: array [0..2] of Tpoint;  // 3 coa
  HeadingCellD: array [0..2] of Tpoint;  // 3 cod
end;

Type
  TBrain = class;
  TPlayer = class ;
  TBall = Class;

TBall = Class
  private
    function GetCells : TPoint ;
    procedure SetCells ( v: TPoint );
    procedure SetCellX ( v: ShortInt );
    procedure SetCellY ( v: ShortInt );
    procedure SetPlayer ( v: TPlayer );
    Function GetPlayer : TPlayer ;
    Function GetZone : Byte ; // 0 2 1
  protected
  public
    Se_sprite: Se_sprite;
    Cx : ShortInt;
    Cy : ShortInt;
    fZone: byte;
    brain : TBrain;
    PathBall: dse_pathplanner.TPath;
    Speed: Integer;
    constructor create( aBrain: TBrain );
    destructor Destroy; override;
    Function BallIsOutSide : boolean;
    property CellX : ShortInt read cx write SetCellX;
    property CellY : ShortInt read cy write SetCellY;
    property Zone: Byte read GetZone;
    Property Player: TPlayer read GetPlayer write SetPlayer ;
    property Cells : Tpoint read GetCells write SetCells;

 end;

TPlayer = class
  private
    brain: TBrain;
    fAttributes: Shortstring;
    fDefaultAttributes: Shortstring;
    fGameOver: boolean;
    function GetCells : TPoint ;
    procedure SetCells ( v: TPoint );
    function GetDefaultCells : TPoint ;
    procedure SetDefaultCells ( v: TPoint );
    procedure SetCellX ( v: ShortInt );
    procedure SetCellY ( v: ShortInt );
    procedure LoadDefaultAttributes ( v: shortstring );
    procedure LoadAttributes ( v: ShortString );

    procedure SetGameOver( const value: Boolean);
    procedure SetSpeed( v: ShortInt );
    procedure SetStamina( v: SmallInt );
    procedure SetDefense( v: ShortInt );
    procedure SetBallControl( v: ShortInt );
    procedure SetPassing( v: ShortInt );
    procedure SetShot( v: ShortInt );
    procedure SetHeading( v: ShortInt );

    function GetMarketValue: Integer;
    function GetActiveAttrTalValue: Integer;
  protected
  public
    itag: Integer;
    grouped : boolean; // utile per compileList sia al client che al server
    stay: Boolean; // non si muove durante ai_moveall

    // generali
    MatchCost : integer;
    MatchesPlayed: SmallInt;
    Age: byte;
    MatchesLeft: SmallInt;
    Team: byte;
    GuidTeam : Integer;
    Ids: string;
    SurName: string [25];
    Role: char;
    se_sprite: Se_sprite; // usato solo nel client

    // le celle differiscono tra normale (chiamate TVcell a volte per la visuale del campo televisiva) e AIcell, celle che usa
    // la AI e la formazione. il campo è ruotato di 90 gradi. la AI attacca sempre verso l'alto, la tv mostra il da sinistra a destra e viceversa
    cx,cy: ShortInt;  // coordinate celle
    AIFormationCellX,AIFormationCellY: ShortInt;
    DefaultCellX, DefaultCellY: ShortInt;    //

    // buff e debuff
    CanMove, CanSkill, CanDribbling: boolean;  // in base a certi debuff il player potrebbe non potere compiere certe azioni
    PressingDone: Boolean;                     // ogni player fa pressing solo una volta in un turno e solo sul portatore di palla
    TackleDone: Boolean;                       // un player fa solo un tackle alla volta per turno

    BuffMorale : Shortint; // possono andare in negativo
    BuffHome : Shortint;

    BonusTackleTurn : ShortInt;
    BonusLopBallControlTurn: ShortInt;
    BonusProtectionTurn : ShortInt; // n turni Protection BonusProtection attivo //< Protection vs Pressing
    UnderPressureTurn : ShortInt; // valore di difesa decrementato// n turni Pressing attivo
    BonusSHPturn: ShortInt;
    BonusSHPAREAturn: ShortInt;
    BonusPLMturn: ShortInt;
    BonusBuffD: ShortInt;
    BonusBuffM: ShortInt;
    BonusBuffF: ShortInt;
    BonusFinishingTurn: ShortInt;
    BonusFinishing: ShortInt;

    isCOF: boolean;    // chi batte il corner
    isFK1: boolean;    // chi batte un fallo a favore nella propria metacampo
    isFK2: boolean;    // chi batte un cross
    isFK3: boolean;    // chi batte una punizione con barriera
    isFK4: boolean;    // il rigorista
    isFKD3 : Boolean;  // se fa parte della barriera

    face: integer;     // id del bmp del viso

    // comuni
    fSpeed: ShortInt;
    fStamina: SmallInt;
    fDefense: ShortInt;
    fBallControl: ShortInt;
    fPassing: ShortInt;
    fShot: ShortInt;
    fHeading: ShortInt;

    ActiveSkills: TstringList;
    MovePath: dse_pathplanner.TPath;
    MoveValue: byte;

    // l'xp è nell'esatto ordine: 34,23,12,1,2,ecc....   6 attributes base e a seguire i talenti
    xp_Speed: integer;
    xp_Defense: integer;
    xp_BallControl: integer;
    xp_Passing: integer;
    xp_Shot: integer;
    xp_Heading: integer;

    history_Speed: ShortInt;      // storia del player. se è migliorato o peggiorato
    history_Defense: ShortInt;
    history_BallControl: ShortInt;
    history_Passing: ShortInt;
    history_Shot: ShortInt;
    history_Heading: ShortInt;

    Flank: Integer;
    InterceptModifier: integer;

    XpTal: array [1..NUM_TALENT] of Integer;  // come i talenti sul db game.talents. xp guadagnata in questa partita(brain) per futuro trylevelup del talento

    PlayerOut : Boolean; // sostituito
    Injured: ShortInt; // giornate di infortunio rimaste
    YellowCard: ShortInt; // ammonizioni accumulate
    RedCard: ShortInt; // espulsione diretta o con somma di gialli
    disqualified: ShortInt; // giornate di squalifica

    devA: Integer; // chance dopo N azioni di guadagnare 1 punto stat
    devT: Integer; // chance dopo N azioni di guadagnare 1 talento
    devI: Integer; // // chance dopo un infortunio (lungo) di perdere una stat

    xpDevA : Integer;
    xpDevT : Integer;
    xpDevI : Integer;

    DefaultSpeed: ShortInt;
    DefaultStamina: ShortInt;
    DefaultDefense: ShortInt;
    DefaultBallControl: ShortInt;
    DefaultPassing : ShortInt;
    DefaultShot : ShortInt;
    DefaultHeading : ShortInt;


    DefaultShortPassing: ShortInt;
    DefaultLoftedPass: ShortInt;
    DefaultPressing: ShortInt;
    DefaultPrecisionShot: ShortInt;
    DefaultPowerShot: ShortInt;
    DefaultCrossing: ShortInt;

    Fitness: ShortInt;
    Morale: ShortInt;
    Country: SmallInt;

    TalentId1: byte;
    TalentId2: byte;
    tmp: ShortInt;
    OnMarket : Boolean;

    constructor create ( const aTeam, aGuidTeam, aMatchesPlayed : integer; const aIds, aName, aSurname, AT: string; Talent1,Talent2: integer );
    destructor Destroy; override;
    function HasBall: boolean;
    function InCrossingArea : boolean;
    function InCrossingCell: boolean;
    function InShotCell : boolean;
    function onBottom : TBottomPosition; // 1 NearCornerCell 2 BottomNoShot 3 BottomShot
    function GetField : byte;
    function GetZoneRole : char;

    property CellX : ShortInt read cx write SetCellX;
    property CellY : ShortInt read cy write SetCellY;
    property Attributes : ShortString read fAttributes write LoadAttributes;
    property DefaultAttributes : ShortString read fDefaultAttributes write LoadDefaultAttributes;

    property Speed : ShortInt read fSpeed write SetSpeed;
    property Stamina : SmallInt read fStamina write SetStamina;
    property Defense : ShortInt read fDefense write SetDefense;
    property BallControl : ShortInt read fBallControl write SetBallControl;
    property Passing : ShortInt read fPassing write SetPassing;
    property Heading : ShortInt read fHeading write SetHeading;
    property Shot : ShortInt read fShot write SetShot;
    property Cells : Tpoint read GetCells write SetCells;
    property DefaultCells : Tpoint read GetDefaultCells write SetDefaultCells;
    property MarketValue : Integer read GetMarketValue;
    property ActiveAttrTalValue : Integer read GetActiveAttrTalValue;
    property field : byte read Getfield;
    property ZoneRole: char read GetZoneRole;

    property  Gameover: Boolean read fGameOver Write SetGameOver;

    procedure resetALL;
    procedure resetTAC;
    procedure resetLBC;
    procedure resetPRO;
    procedure resetPRE;
    procedure resetSHP;
    procedure resetSHPAREA;
    procedure resetPLM;
    procedure resetFIN;
end;
  pSoccerPlayer = ^TPlayer;



  TInteractivePlayer = class // Player che puòpublic interagire durante il turno dell'avversario. ad esempio Intercept su Short.passing dell'avversario
    Player : TPlayer;  // il player che interagisce
    Cell: Tpoint;            // la cella su cui interagisce
    Attribute : TAttributeName;// TSoccerAttribute;  // con quale attributo interagisce. per esempio heading su lofted.pass
  end;


  TBrain = class( TObject )   // l'oggetto principale del singolo match. contine tutta la partita in memoria
  private

    aStar: TAStarPathPlanner;
    fdir_log: string;

    function GetW_Something: Boolean;
    procedure SetTeamMovesLeft ( const Value: ShortInt );
    procedure SetMinute ( const Value: SmallInt );
    procedure SetDirLog ( value: string );

  protected
    public
      SoccerAI : TSoccerAI;
      GameMode : TGameMode;
      pvePostMessage: boolean;

      debug_TACKLE_FAILED : Boolean; // sempre tackle fallito
      debug_SETFAULT : Boolean;  // sempre fallo
      debug_SETRED : boolean; // sempre espulsione dopo fallo
      debug_SetAlwaysGol : Boolean;
      debug_Setposcrosscorner : Boolean;
      debug_Buff100 : Boolean;


      Season: integer;
      Country : integer;
      Division : integer;
      Round : Integer;
      fGender: Char;
      GenderN: integer;

      //Dice : Integer;
      MAX_STAT : Integer;

      MAX_DEFAULT_SPEED : Integer;
      MAX_DEFAULT_DEFENSE : Integer;
      MAX_DEFAULT_PASSING : Integer;
      MAX_DEFAULT_BALLCONTROL :Integer;
      MAX_DEFAULT_SHOT      :Integer;
      MAX_DEFAULT_HEADING :Integer;

      PRE_VALUE : Integer;
      PRO_VALUE : Integer;

      CRO_MIN1    :Integer;
      CRO_MIN2    :Integer;
      CRO_MID1    :Integer;
      CRO_MID2    :Integer;
      CRO_MAX1    :Integer;

      LOP_MIN1    :Integer;
      LOP_MIN2    :Integer;
      LOP_MID1    :Integer;
      LOP_MID2    :Integer;
      LOP_MAX1    :Integer;

      LOP_BC_MIN1 :Integer;
      LOP_BC_MIN2 :Integer;
      LOP_BC_MID1 :Integer;
      LOP_BC_MID2 :Integer;
      LOP_BC_MAX1 :Integer;

      DRIBBLING_MALUS: Integer;
      DRIBBLING_DIFF: Integer;// buff

      modifier_defenseShot: Integer;
      modifier_penaltyPOS :Integer;
      modifier_penaltyPRS :Integer;

      CRO2_D2_MIN :Integer;
      CRO2_D2_MAX :Integer;
      CRO2_D1_MIN :Integer;
      CRO2_D1_MAX :Integer;
      CRO2_D0_MIN :Integer;
      CRO2_D0_MAX :Integer;
      CRO2_A2_MIN :Integer;
      CRO2_A2_MAX :Integer;
      CRO2_A1_MIN :Integer;
      CRO2_A1_MAX :Integer;
      CRO2_A0_MIN :Integer;

      COR_D2_MIN :Integer;
      COR_D2_MAX :Integer;
      COR_D1_MIN :Integer;
      COR_D1_MAX :Integer;
      COR_D0_MIN :Integer;
      COR_D0_MAX :Integer;
      COR_A2_MIN :Integer;
      COR_A2_MAX :Integer;
      COR_A1_MIN :Integer;
      COR_A1_MAX :Integer;
      COR_A0_MIN :Integer;

      PlayersALL : TObjectList<TPlayer>;
      Players : TObjectList<TPlayer>;
      Reserves : TObjectList<TPlayer>;
      Gameover : TObjectList<TPlayer>;

     // AICrossingAreaCells: TList<TAICrossAreaCell>;
    //  TVCrossingAreaCells: TList<TTVCrossAreaCell>;

      LogUser: array [0..1] of integer;
      MMbraindata,MMbraindataZIP: TMemoryStream;
      MatchInfo: TStringList; // Il tabellino della partita: gol, minuti, e cognomi. Tipologia se pos3 punizioni o pos4 rigore. cartellini. sostituzioni.

      ReserveSlot,GameOverSlot : array [0..1, 0..21] of string;
      Working: Boolean;           // se true, sta elaborando un input e non può accettare input del client
      brainIds: string[50];       // Identificativo globale del brain
      brainSerie: string;
      Paused: Boolean;
      RandGen: TtdBasePRNG;
      AI_GCD, LastTickCount: Integer;

      utime: Boolean;
      fmilliseconds: integer;
      lstSpectator : TList<Integer>;
      brainManager: TObject;
      Score: TScore;
      incMove : SmallInt;

      BonusPowerShotGK: array [1..10] of integer;           // pos modificatori al tiro in porta
      BonusPrecisionShotGK: array [1..10] of integer;       // prs modificatori al tiro in porta

      ToEmptyCellBonusDefending: integer;                          // definizioni

      Ball: Tball;

      ShpFree: ShortInt; // può andare in negativo
      fMinute: smallint;
      TeamTurn: byte;
      FTeamMovesLeft : ShortInt;

      GameStarted: boolean;
      FlagEndGame : boolean;
      Finished: boolean;
      FinishedTime: integer;

      TeamCorner: ShortInt;
      TeamFreeKick: ShortInt;

      w_CornerSetup: boolean;          // il brain è in fase di setup del corner
      w_Coa : boolean;                 // il brain è in fase di setup del corner e aspetta chi lo batte e i 3 attaccanti schierati in area di rigore
      w_Cod: boolean;                  // il brain è in fase di setup del corner e aspetta i 3 difensori schierati in area di rigore
      w_CornerKick: boolean;           // il brain aspetta che il corner sia battuto ( brain.exec_Corner )

      w_FreeKickSetup1: boolean;
      w_Fka1 : boolean;  // normale
      w_FreeKick1: boolean;

      w_FreeKickSetup2: boolean;
      w_Fka2 : boolean;
      w_Fkd2: boolean; // 3 saltatori di testa
      w_FreeKick2: boolean;

      w_FreeKickSetup3: boolean;
      w_Fka3 : boolean;
      w_Fkd3: boolean; // 4  o 1 1 1 barriere
      w_FreeKick3: boolean;

      w_FreeKickSetup4: boolean;
      w_Fka4 : boolean;   // rigorista
      w_FreeKick4: boolean;

      tsSpeaker: TstringList;
      tsScript: array [0..255] of TstringList;   // la lista di ciò che accade sul server viene spedita al client
      TsErrorLog: TStringList;

      ExceptPlayers: TObjectList<TPlayer>; // lista di player che non si muoveranno durante la Ai_moveAll
      ShpBuff: Boolean;
      function findSpectator (Cliid: Integer): Boolean;
      function RemoveSpectator (Cliid: Integer): Boolean;
      constructor Create  ( ids: string; AGender: Char; aSeason, aCountry, aDivision, aRound: integer);
      destructor Destroy; override;

//      procedure CreateFormationCells;
//      procedure FormationCellCompleteInfo (  team, Fcx, Fcy: Integer; var CellX, CellY: Integer; var Role:string );
//      function FieldCellToFormationCell ( CellX, CellY : integer ): TFormationCell;

      function AdjustFatigue ( const Stamina , Roll: integer ): TRoll;
      function RndGenerate( Upper: integer ): integer;
      function RndGenerate0( Upper: integer ): integer;
      function RndGenerateRange( Lower, Upper: integer ): integer;


      procedure CornerSetup ( const aPlayer: TPlayer );     // Corner
      procedure FreeKickSetup1 ( team : Integer );   // normale nella propria metacampo
      procedure FreeKickSetup2 ( team : Integer  );  // cross

      procedure FreeKickSetup3 ( team : Integer  );  // barriera
        function GetBarrierCell (Team: Integer; CellX,CellY: integer ): TPoint;
        procedure DeflateBarrier ( aCell: Tpoint; ExceptPlayer: TPlayer );
        function FindDefensiveCellFree ( team: integer ): Tpoint;
      procedure FreeKickSetup4 ( team : Integer  );  // rigore
        function GetPenaltyCell (Team: Integer ): TPoint;
        procedure FreePenaltyArea ( team : Integer  );
        function FindDefensiveCellFreePenalty (  team: integer ): Tpoint;

      procedure Start;
      procedure LoadDefaultTeamPos ( aTeam: integer);
      procedure BrainInput ( aCmd: string );
        procedure InputSecureExit ( DoAiMoveAll: Boolean; DoTeamMovesLeft: TDecMovesLeft);
        function CheckInputShp (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
        function CheckInputLop (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
        function CheckInputCro (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
        function CheckInputDri (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
        function CheckInputPos (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
        function CheckInputPrs (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
        function CheckInputPre (aPlayer: TPlayer; tsCmd: Tstringlist): string;
        function CheckInputPro (aPlayer: TPlayer; tsCmd: Tstringlist): string;
        function CheckInputTac (aPlayer: TPlayer; tsCmd: Tstringlist): string;
        function CheckInputPlm (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;

        function CheckInputStay (aPlayer: TPlayer; tsCmd: Tstringlist): string;
        function CheckInputFree (aPlayer: TPlayer; tsCmd: Tstringlist): string;

        function CheckInputTactic (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
        function CheckInputSub (aPlayer,aPlayer2: TPlayer; tsCmd: Tstringlist): string;

        function CheckOffside ( FromPlayer, aPossibleoffside: TPlayer ): boolean;

      function GetOpponentDoor (SelectedPlayer: TPlayer ): TPoint;
      function GetCorner (Team: integer; Y: integer; CornerMode: TCornerMode ): TCornerMap;

      function IsCheatingBall ( TeamFault: Integer ) : boolean;
      function IsCheatingBallGK ( OldTeamTurn: Integer ) : boolean;

      function GetOpponentStart (SelectedPlayer: TPlayer ): TPoint;

      property TeamMovesLeft : ShortInt read fTeamMovesLeft write SetTeamMovesLeft;
      property Minute : SmallInt read fMinute write SetMinute;
      function FindSwapCOAD (   SwapPlayer: TPlayer; CornerMap: TCornerMap ): Tpoint;

      function exec_tackle ( ids: string):integer;
      function exec_autotackle ( ids: string; LastPath: boolean ):boolean; // non c'è fallo
      Function GetFault ( Team, CellX, CellY : integer): Integer;

      procedure exec_corner ;
      procedure exec_freekick2 ;
      procedure TurnChange( MovesLeft: integer);
      procedure Setmilliseconds ( value: integer);
      procedure SetGender ( fm: char);

      function inExceptPlayers ( aPlayer: TPlayer ) : Boolean;
      procedure AI_MoveAll ;   // !! movimento automatico dei player a fine turno
        procedure AI_MovePlayer_DefaultX_minus_1 ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_DefaultX_minus_2 ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_DefaultX_plus_1 ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_DefaultX_plus_2 ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_DefaultX ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_DefaultY ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_Ball_equal ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_Ball_plus_1 ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_Ball_plus_2 ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_Ball_minus_1 ( aPlayer: TPlayer  ) ;
        procedure AI_MovePlayer_Ball_minus_2 ( aPlayer: TPlayer  ) ;
          function Tv2AiField ( Team, tvX,tvY: integer ): TPoint;
          function AiField2TV ( Team, aiX,aiY: integer ): TPoint;


      // AI battle
      function MirrorAIfield (  CellX,CellY: integer) : TPoint;


    function GetBestShotZone ( Team: integer; Zonerole:Char ): TPlayer;
    function GetBestPassingZone ( Team: integer; Zonerole:Char ): TPlayer;
    function GetWorstPassing ( Team: integer ): TPlayer;
    function GetWorstDefense ( Team: integer ): TPlayer;
    function GetWorstShot ( Team: integer ): TPlayer;
    function GetWorstBallControlZone ( Team: integer; Zonerole:Char ): TPlayer;



      procedure CalculateChance  ( A, B: integer; var chanceA, chanceB: integer);

      procedure SaveData ( CurMove: Integer ); // !!  salva i dati in memoria da spedire al client


      function GetCrossDefenseBonus (aPlayer: TPlayer; CellX, CellY: integer ): integer;
      function GetTeamBall: integer;

      function NextReserveSlot ( aPlayer: TPlayer): Integer; overload;
      function NextReserveSlot ( team: Integer): Integer; overload;
      procedure PutInReserveSlot ( aPlayer: TPlayer ); overload;
      procedure PutInReserveSlot ( aPlayer: TPlayer; ReserveCell: TPoint );overload;  // mette il player nella cella indicata
      procedure ClearReserveSlot;
      function isReserveSlot (CellX, CellY: integer): boolean;
      procedure CleanReserveSlot ( team: integer );


      function NextGameOverSlot ( aPlayer: TPlayer): Integer; overload;
      function NextGameOverSlot ( team: Integer): Integer; overload;
      procedure PutInGameOverSlot ( aPlayer: TPlayer ); overload;
      procedure PutInGameOverSlot ( aPlayer: TPlayer; GameOverCell: TPoint );overload;  // mette il player nella cella indicata
      procedure ClearGameOverSlot;
      function isGameOverSlot (CellX, CellY: integer): boolean;
      procedure CleanGameOverSlot ( team: integer );

      procedure UpdateDevi; // sia team 0 che 1


    procedure AddSoccerPlayer (aSoccerPlayer: TPlayer );
    procedure AddSoccerReserve (aSoccerPlayer: TPlayer );
    procedure AddSoccerGameOver (aSoccerPlayer: TPlayer );

    procedure RemoveSoccerPlayer (aSoccerPlayer: TPlayer );
    procedure RemoveSoccerReserve (aSoccerPlayer: TPlayer );
    procedure RemoveSoccerGameOver (aSoccerPlayer: TPlayer );


    procedure GetPath ( Team, X1, Y1, X2, Y2, Limit: integer; useFlank,FriendlyWall,OpponentWall,FinalWall: Boolean;OneDir: TOneDir; var aPath: dse_pathplanner.TPath );
    procedure GetPath1dir ( Team, X1, Y1, X2, Y2, Limit: integer; useFlank,FriendlyWall,OpponentWall,FinalWall,OneDir: boolean; var aPath: dse_pathplanner.TPath );
    procedure GetPathX ( Team, X1, Y1, X2, Y2, Limit: integer; useFlank,FriendlyWall,OpponentWall,FinalWall,OneDir: Boolean; var aPath: dse_pathplanner.TPath );
    procedure GetPathY ( Team, X1, Y1, X2, Y2, Limit: integer; useFlank,FriendlyWall,OpponentWall,FinalWall,OneDir: Boolean; var aPath: dse_pathplanner.TPath );
    procedure GetNeighbournsOpponent ( X, Y, Team: integer; var aList : TObjectList<TPlayer> );

    function GetBounceCell ( StartX, StartY, ToX, ToY, Speed: integer; favourTeam: integer): TPoint;


    function GetFriendAhead ( const aPlayer: TPlayer ) : TPlayer;
    // SHP intercepts
    procedure CompileInterceptList (ShpTeam, MaxDistance: integer; aPath : dse_pathplanner.TPath; var lstIntercepts: TList<TInteractivePlayer> );
    // LOP heading
    procedure CompileHeadingList (LopTeam, MaxDistance, CellX,CellY: integer; var lstHeading: TList<TInteractivePlayer> );
    // LOP Speed
    procedure CompileMovingList (MaxDistance, CellX,CellY: integer; var lstMoving: TList<TInteractivePlayer> );

    // PLM autotackle
    procedure CompileAutoTackleList (PlmTeam, MaxDistance: integer; aPath : dse_pathplanner.TPath; var lstAutoTackle: TList<TInteractivePlayer> );

    // per i taleni buff
    procedure CompileRoleList (team: Integer; role: Char; var lstRole: TObjectList<TPlayer> );
    procedure CompileBuffedList (team: Integer; buff: Char; var lstRole: TObjectList<TPlayer> );

    // CROSS
    function GetFriendInCrossingArea ( const aPlayer: TPlayer ) : boolean;
    function GetCrossOpponent ( aPlayer:TPlayer ): TPlayer;


    function GetTotalReserve ( Team: integer; GK:boolean): integer;
    function GetReservePlayerRandom ( Team: integer; GK:boolean): TPlayer;
    function GetPlayerRandom ( Team: integer; GK:boolean): TPlayer;overload;
    function GetPlayer (X,Y: integer): TPlayer;overload;
    function GetPlayer (ids: string): TPlayer;overload;
    function GetPlayer (ids: string; team: integer): TPlayer;overload;
    function GetPlayer (X,Y, Team: integer): TPlayer;overload;
    function GetPlayerOpponent (X,Y: Integer; Team: integer): TPlayer;overload;
    function GetPlayerOpponent (ids: string; Team: integer): TPlayer;overload;

    function GetPlayerDefault (X,Y: integer): TPlayer;
    function GetPlayerDefault2 (X,Y: integer): TPlayer;

    function GetPlayerReserve (ids : string): TPlayer;
    function GetPlayerRandom3 : TPlayer; // cerca chi ha giocato in una partita ma non un GK

    function GetPlayer2 (X,Y: integer): TPlayer;overload;
    function GetPlayer2 (ids: string): TPlayer;overload;
    function GetPlayer2 (X,Y, Team: integer): TPlayer;overload;
    function GetPlayer2 (ids: string;Team: integer): TPlayer;overload;
    function GetPlayerALL (ids: string): TPlayer;overload;
    function GetPlayerALL (X,Y: integer): TPlayer;overload;
    function GetPlayer3 ( ids: string ): TPlayer; // cerca chi ha giocato in una partita



    procedure ResetPassiveSkills;



    function CheckScore ( team: Integer): integer;
    // crossing

    // intercept
    // respinte portiere
    function GetGKBounceCell ( GoalKeeper: TPlayer; GKX, GKY, Speed: integer; AllowCorner: boolean ): Tpoint;

    Procedure CopyPath ( Path1, Path2 : dse_pathplanner.TPath );

    procedure GetMarkingPath ( aPlayer: TPlayer );
    procedure GetAggressionCellPath ( aSoccerPlayer: TPlayer;  X2, Y2: integer );
    procedure GetFavourCellPath ( aSoccerPlayer: TPlayer; X2, Y2: integer );
    function GetRandomCell ( CellX, CellY, Speed: integer; noPlayer,noOutside: boolean ): Tpoint;
    function GetRandomCellNO06 ( CellX, CellY, Speed: integer  ): Tpoint;
    function GetRandomCellNOPlayer ( CellX, CellY, Speed: integer  ): Tpoint;

    procedure GetNeighbournsCells ( CellX, CellY, Speed: integer; NoPlayer,noOutside,noGK: boolean; var aCellList:Tlist<TPoint> );
    function GetZone ( Team, CellX, CellY: integer ): String;
    function GetTackleDirection ( Team, StartX, StartY, ToX, ToY: Integer): TTackleDirection;
    procedure GetNextDirectionCell ( StartX, StartY, ToX, ToY, Speed,Team: integer; FriendlyWall,OpponentWall: boolean;  var aPath: dse_pathplanner.TPath  );

    procedure SwapPlayers (PlayerA, PlayerB: TPlayer);
    procedure SwapDefaultPlayers (PlayerA, PlayerB: TPlayer);
    procedure SwapformationPlayers (PlayerA, PlayerB: TPlayer);

    function GetOpponentGK ( Team: integer): TPlayer;
    function GetGK ( team: integer ): TPlayer;
    function GetCof: TPlayer;
    function GetFK1: TPlayer;
    function GetFK2: TPlayer;
    function GetFK3: TPlayer;
    function GetFK4: TPlayer;
    function GetInjuredPlayer( Team: integer ): TPlayer;

    function IsOffSide ( FromPlayer, ToPlayer : TPlayer ): Boolean;
    function IsLastMan ( aPlayer, BallPlayer : TPlayer ): Boolean;

    function AllowCount ( team: Integer ): Integer;
    function CurrentCount ( team: Integer ): Integer;
    function CanDoSub ( team: Integer ): boolean;

    function CalculateBasePrecisionShot (  aPlayer: TPlayer ): Tchance;
    function CalculateBasePowerShot (   aPlayer: TPlayer ): Tchance;
    function CalculateBasePrecisionShotGK (  aPlayer: TPlayer ): Tchance;
    function CalculateBasePowerShotGK (  aPlayer: TPlayer ): Tchance;

    // plm nove con autotackle
    function CalculateBasePlmBallControl (  aPlayer: TPlayer ): Tchance;
    function CalculateBasePlmBaseAutoTackle (  aPlayer: TPlayer ): Tchance;

    // ShortPassing con Intercept e Stopped
    function CalculateBaseShortPassing  (  aPlayer: TPlayer ): Tchance;
    function CalculateBaseShortPassingStopped (  aPlayer: TPlayer ): Tchance;
    function CalculateBaseShortPassingIntercept (  CellX, CellY: Integer; aPlayer: TPlayer ): Tchance;

    // LoftedPass
    function CalculateBaseLoftedPass ( aPlayer: TPlayer ): Tchance;
    function CalculateBaseLoftedPassBallControl ( aPlayer: TPlayer ): Tchance;
    function CalculateBaseLoftedPassHeadingDefense (  CellX, CellY: Integer; aPlayer: TPlayer ): Tchance; // cellx e celly opzionali
    function CalculateBaseLoftedPassEmptyPlmSpeed (  CellX, CellY: Integer; aPlayer: TPlayer ): Tchance; // cellx e celly opzionali


    // Crossing
    function CalculateBaseCrossing ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
    function CalculateBaseCrossingHeadingDefense ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
    function CalculateBaseCrossingHeadingFriend ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;

    //Dribbling
    function CalculateBaseDribblingChance ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
    function CalculatBaseDribblingDefense ( CellX, CellY: integer; anOpponent: TPlayer ): Tchance;


    property milliseconds: Integer read fmilliseconds write setmilliseconds;
    property Gender : char read fGender write SetGender;

    property Dir_log : string read fdir_log write SetDirLog;
    property W_SomeThing : Boolean read GetW_Something;

    end;

  procedure CreateShotCells;
  procedure TVCreateCrossingAreaCells ;
  procedure AICreateCrossingAreaCells;
  procedure createAIfield;

var
	ShotCells: TObjectList<TShotCell>;
	TVCrossingAreaCells: TList<TTVCrossAreaCell>;
	AICrossingAreaCells: TList<TAICrossAreaCell>;
 //	AIField: array [0..1,0..6,-1..11] of TPoint;
 	AIField: TList<TFieldCell>;

implementation
uses Server, utilities;
//--------------------------------------------------------
constructor TShotCell.Create;
begin
  subCell := TList<Tpoint>.Create;
  inherited;
end;
destructor TShotCell.Destroy;
begin
  subCell.Free ;
  inherited;
end;
procedure CreateShotCells;
var
  aShotCell : TShotCell;
  aPoint,aPoint2: TPoint;
  i,ii: integer;
begin
   // devono essere in ordine di X
   ShotCells:= TObjectList<TShotCell>.create ( true );

//--------------------------------------
    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 3;
    aShotCell.CellY  := 0;

    aPoint.X := 2;
    aPoint.Y := 1;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
//    aPoint.X := 1;
//    aPoint.Y := 4;
//    aShotCell.subCell.Add(aPoint);
    ShotCells.Add(aShotCell);
//--------------------------------------

    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 3;
    aShotCell.CellY  := 1;

    aPoint.X := 2;
    aPoint.Y := 1;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
//    aPoint.X := 1;
//    aPoint.Y := 4;
//    aShotCell.subCell.Add(aPoint);
    ShotCells.Add(aShotCell);

//--------------------------------------

    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 3;
    aShotCell.CellY  := 2;

    aPoint.X := 2;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
//    aPoint.X := 1;
//    aPoint.Y := 4;
//    aShotCell.subCell.Add(aPoint);

    ShotCells.Add(aShotCell);

//--------------------------------------


    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 3;
    aShotCell.CellY  := 3;

    aPoint.X := 2;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);

    ShotCells.Add(aShotCell);
//--------------------------------------


    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 3;
    aShotCell.CellY  := 4;

    aPoint.X := 2;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);
//    aPoint.X := 2;
//    aPoint.Y := 5;
//    aShotCell.subCell.Add(aPoint);
//    aPoint.X := 1;
//    aPoint.Y := 2;
 //   aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);

    ShotCells.Add(aShotCell);
//--------------------------------------



    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 3;        // qui come nella 3.1 forse aggiungere un difensore
    aShotCell.CellY  := 5;

    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 5;
    aShotCell.subCell.Add(aPoint);
//    aPoint.X := 1;
//    aPoint.Y := 2;
//    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 4;
    ShotCells.Add(aShotCell);
//--------------------------------------

    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 3;
    aShotCell.CellY  := 6;

    aPoint.X := 2;
    aPoint.Y := 5;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 2;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);
//    aPoint.X := 1;
//   aPoint.Y := 2;
//    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);
    aPoint.X := 1;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);

    ShotCells.Add(aShotCell);

//--------------------------------------
// X = 2

// 2,6
    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 2;
    aShotCell.CellY  := 0;

    aPoint.X := 2;
    aPoint.Y := 1;
    aShotCell.subCell.Add(aPoint);
    ShotCells.Add(aShotCell);

    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

//    aPoint.X := 1;
//    aPoint.Y := 4;
//    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 1;
    aShotCell.subCell.Add(aPoint);



    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 2;
    aShotCell.CellY  := 1;

//    aPoint.X := 2;
//    aPoint.Y := 0;
//    aShotCell.subCell.Add(aPoint);

    aPoint.X := 2;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

//    aPoint.X := 1;
//    aPoint.Y := 4;
//    aShotCell.subCell.Add(aPoint);




    ShotCells.Add(aShotCell);

//--------------------------------------


    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 2;
    aShotCell.CellY  := 2;

    aPoint.X := 2;
    aPoint.Y := 1;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 2;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

//    aPoint.X := 1;
//    aPoint.Y := 4;
//    aShotCell.subCell.Add(aPoint);


    ShotCells.Add(aShotCell);


//--------------------------------------

    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 2;
    aShotCell.CellY  := 3;

    aPoint.X := 2;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 2;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);


    ShotCells.Add(aShotCell);

//--------------------------------------

    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 2;
    aShotCell.CellY  := 4;

    aPoint.X := 2;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 2;
    aPoint.Y := 5;
    aShotCell.subCell.Add(aPoint);


    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);


    ShotCells.Add(aShotCell);
//--------------------------------------

    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 2;
    aShotCell.CellY  := 5;

    aPoint.X := 2;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);


    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);


    ShotCells.Add(aShotCell);

// 2,6
    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 2;
    aShotCell.CellY  := 6;

    aPoint.X := 2;
    aPoint.Y := 5;
    aShotCell.subCell.Add(aPoint);
    ShotCells.Add(aShotCell);

//    aPoint.X := 1;
//    aPoint.Y := 2;
//    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 5;
    aShotCell.subCell.Add(aPoint);




    // X 1

    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 1;
    aShotCell.CellY  := 2;

    aPoint.X := 1;
    aPoint.Y := 1;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

    ShotCells.Add(aShotCell);

    //
    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 1;
    aShotCell.CellY  := 3;

    aPoint.X := 1;
    aPoint.Y := 2;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 4;
    aShotCell.subCell.Add(aPoint);


    ShotCells.Add(aShotCell);

    aShotCell:= TShotCell.Create ;
    aShotCell.DoorTeam := 0;
    aShotCell.CellX  := 1;
    aShotCell.CellY  := 4;

    aPoint.X := 1;
    aPoint.Y := 5;
    aShotCell.subCell.Add(aPoint);

    aPoint.X := 1;
    aPoint.Y := 3;
    aShotCell.subCell.Add(aPoint);

    ShotCells.Add(aShotCell);
    //--------------------------------------

    // Replica a specchio

    for i :=  ShotCells.count -1 downto 0  do begin


      aShotCell:= TShotCell.Create ;
      aShotCell.DoorTeam := 1;

      case ShotCells[i].CellX of
        0: aShotCell.CellX := 11;
        1: aShotCell.CellX := 10;
        2: aShotCell.CellX := 9;
        3: aShotCell.CellX := 8;
      end;

      aShotCell.CellY := ShotCells[i].CellY;

      for ii := 0 to ShotCells[i].subCell.Count -1 do begin

        aPoint2 := ShotCells[i].subCell[ii];
        case aPoint2.X of
          0: aPoint.X := 11;
          1: aPoint.X := 10;
          2: aPoint.X := 9;
          3: aPoint.X := 8;
        end;
        aPoint.Y := aPoint2.y ;
        aShotCell.subCell.Add(aPoint);
      end;

      ShotCells.Add(aShotCell);


    end;

end;
procedure TVCreateCrossingAreaCells;
var
  aCell: TTVCrossAreaCell;
begin

    (*serve anche per rientrare in difesa avendo la doorteam *)
    // ragiono in AIfield
    TVCrossingAreaCells:= TList<TTVCrossAreaCell>.create;
    aCell.cellX := 1;
    aCell.CellY := 2;
    aCell.DoorTeam := 0;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 1;
    aCell.CellY := 3;
    aCell.DoorTeam := 0;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 1;
    aCell.CellY := 4;
    aCell.DoorTeam := 0;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 2;
    aCell.CellY := 2;
    aCell.DoorTeam := 0;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 2;
    aCell.CellY := 3;
    aCell.DoorTeam := 0;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 2;
    aCell.CellY := 4;
    aCell.DoorTeam := 0;
    TVCrossingAreaCells.Add(aCell);


    aCell.CellX := 10;
    aCell.CellY := 2;
    aCell.DoorTeam := 1;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 10;
    aCell.CellY := 3;
    aCell.DoorTeam := 1;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 10;
    aCell.CellY := 4;
    aCell.DoorTeam := 1;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 10;
    aCell.CellY := 2;
    aCell.DoorTeam := 1;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 10;
    aCell.CellY := 3;
    aCell.DoorTeam := 1;
    TVCrossingAreaCells.Add(aCell);

    aCell.CellX := 10;
    aCell.CellY := 4;
    aCell.DoorTeam := 1;
    TVCrossingAreaCells.Add(aCell);

end;
procedure AICreateCrossingAreaCells;
var
  aCell: TAICrossAreaCell;
begin

    (*serve anche per rientrare in difesa avend la doorteam *)
    // ragiono in AIfield
    AICrossingAreaCells:= TList<TAICrossAreaCell>.create;

    aCell.cellX := 2;
    aCell.CellY := 1;
    aCell.DoorTeam := DoorOpponent;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 3;
    aCell.CellY := 1;
    aCell.DoorTeam := DoorOpponent;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 4;
    aCell.CellY := 1;
    aCell.DoorTeam := DoorOpponent;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 2;
    aCell.CellY := 2;
    aCell.DoorTeam := DoorOpponent;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 3;
    aCell.CellY := 2;
    aCell.DoorTeam := DoorOpponent;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 4;
    aCell.CellY := 2;
    aCell.DoorTeam := DoorOpponent;
    AICrossingAreaCells.Add(aCell);


    aCell.CellX := 2;
    aCell.CellY := 10;
    aCell.DoorTeam := DoorFriendly;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 3;
    aCell.CellY := 10;
    aCell.DoorTeam := DoorFriendly;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 4;
    aCell.CellY := 10;
    aCell.DoorTeam := DoorFriendly;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 2;
    aCell.CellY := 9;
    aCell.DoorTeam := DoorFriendly;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 3;
    aCell.CellY := 9;
    aCell.DoorTeam := DoorFriendly;
    AICrossingAreaCells.Add(aCell);

    aCell.CellX := 4;
    aCell.CellY := 9;
    aCell.DoorTeam := DoorFriendly;
    AICrossingAreaCells.Add(aCell);

end;
procedure createAIfield;
var
  I,x,y,XX: Integer;
  aFieldCell: TFieldCell;
begin
  AIField := TList<TFieldCell>.Create;
//team 0
  for XX := 0 to 6 do begin
    x:=0; y:=11;
    for I := 11 downto 0 do begin
      aFieldCell.Team := 0;
      aFieldCell.AI := Point (XX,I);
      aFieldCell.TV := Point (x,XX);
      AIField.Add(aFieldCell);
      Dec(y);
      inc(x);
    end;
  end;
//team 1
 y:=0;
  for XX := 6 downto 0 do begin
    x:=0;
    for I := 0 to 11 do begin
      aFieldCell.Team := 1;
      aFieldCell.AI := Point (XX,I);
      aFieldCell.TV := Point (x,y);
      AIField.Add(aFieldCell);
      inc(x);
    end;
    inc(y);
  end;


  for I := 0 to 10 do begin
    aFieldCell.Team := 0;
    aFieldCell.AI := Point (I,-1);
    aFieldCell.TV := Point (I,-1);
    AIField.Add(aFieldCell);
  end;
  for I := 11 to 21 do begin
    aFieldCell.Team := 1;
    aFieldCell.AI := Point (I,-1);
    aFieldCell.TV := Point (I,-1);
    AIField.Add(aFieldCell);
  end;

{
    AIField[0,0,11] := Point(0,0);
    AIField[0,0,10] := Point(1,0);
    AIField[0,0,9] := Point(2,0);
    AIField[0,0,8] := Point(3,0);
    AIField[0,0,7] := Point(4,0);
    AIField[0,0,6] := Point(5,0);
    AIField[0,0,5] := Point(6,0);
    AIField[0,0,4] := Point(7,0);
    AIField[0,0,3] := Point(8,0);
    AIField[0,0,2] := Point(9,0);
    AIField[0,0,1] := Point(10,0);
    AIField[0,0,0] := Point(11,0);

    AIField[0,1,11] := Point(0,1);
    AIField[0,1,10] := Point(1,1);
    AIField[0,1,9] := Point(2,1);
    AIField[0,1,8] := Point(3,1);
    AIField[0,1,7] := Point(4,1);
    AIField[0,1,6] := Point(5,1);
    AIField[0,1,5] := Point(6,1);
    AIField[0,1,4] := Point(7,1);
    AIField[0,1,3] := Point(8,1);
    AIField[0,1,2] := Point(9,1);
    AIField[0,1,1] := Point(10,1);
    AIField[0,1,0] := Point(11,1);

    AIField[0,2,11] := Point(0,2);
    AIField[0,2,10] := Point(1,2);
    AIField[0,2,9] := Point(2,2);
    AIField[0,2,8] := Point(3,2);
    AIField[0,2,7] := Point(4,2);
    AIField[0,2,6] := Point(5,2);
    AIField[0,2,5] := Point(6,2);
    AIField[0,2,4] := Point(7,2);
    AIField[0,2,3] := Point(8,2);
    AIField[0,2,2] := Point(9,2);
    AIField[0,2,1] := Point(10,2);
    AIField[0,2,0] := Point(11,2);

    AIField[0,3,11] := Point(0,3);
    AIField[0,3,10] := Point(1,3);
    AIField[0,3,9] := Point(2,3);
    AIField[0,3,8] := Point(3,3);
    AIField[0,3,7] := Point(4,3);
    AIField[0,3,6] := Point(5,3);
    AIField[0,3,5] := Point(6,3);
    AIField[0,3,4] := Point(7,3);
    AIField[0,3,3] := Point(8,3);
    AIField[0,3,2] := Point(9,3);
    AIField[0,3,1] := Point(10,3);
    AIField[0,3,0] := Point(11,3);

    AIField[0,4,11] := Point(0,4);
    AIField[0,4,10] := Point(1,4);
    AIField[0,4,9] := Point(2,4);
    AIField[0,4,8] := Point(3,4);
    AIField[0,4,7] := Point(4,4);
    AIField[0,4,6] := Point(5,4);
    AIField[0,4,5] := Point(6,4);
    AIField[0,4,4] := Point(7,4);
    AIField[0,4,3] := Point(8,4);
    AIField[0,4,2] := Point(9,4);
    AIField[0,4,1] := Point(10,4);
    AIField[0,4,0] := Point(11,4);

    AIField[0,5,11] := Point(0,5);
    AIField[0,5,10] := Point(1,5);
    AIField[0,5,9] := Point(2,5);
    AIField[0,5,8] := Point(3,5);
    AIField[0,5,7] := Point(4,5);
    AIField[0,5,6] := Point(5,5);
    AIField[0,5,5] := Point(6,5);
    AIField[0,5,4] := Point(7,5);
    AIField[0,5,3] := Point(8,5);
    AIField[0,5,2] := Point(9,5);
    AIField[0,5,1] := Point(10,5);
    AIField[0,5,0] := Point(11,5);

    AIField[0,6,11] := Point(0,6);
    AIField[0,6,10] := Point(1,6);
    AIField[0,6,9] := Point(2,6);
    AIField[0,6,8] := Point(3,6);
    AIField[0,6,7] := Point(4,6);
    AIField[0,6,6] := Point(5,6);
    AIField[0,6,5] := Point(6,6);
    AIField[0,6,4] := Point(7,6);
    AIField[0,6,3] := Point(8,6);
    AIField[0,6,2] := Point(9,6);
    AIField[0,6,1] := Point(10,6);
    AIField[0,6,0] := Point(11,6);

// team 1
    AIField[1,6,0] := Point(0,0);
    AIField[1,6,1] := Point(1,0);
    AIField[1,6,2] := Point(2,0);
    AIField[1,6,3] := Point(3,0);
    AIField[1,6,4] := Point(4,0);
    AIField[1,6,5] := Point(5,0);
    AIField[1,6,6] := Point(6,0);
    AIField[1,6,7] := Point(7,0);
    AIField[1,6,8] := Point(8,0);
    AIField[1,6,9] := Point(9,0);
    AIField[1,6,10] := Point(10,0);
    AIField[1,6,11] := Point(11,0);

    AIField[1,5,0] := Point(0,1);
    AIField[1,5,1] := Point(1,1);
    AIField[1,5,2] := Point(2,1);
    AIField[1,5,3] := Point(3,1);
    AIField[1,5,4] := Point(4,1);
    AIField[1,5,5] := Point(5,1);
    AIField[1,5,6] := Point(6,1);
    AIField[1,5,7] := Point(7,1);
    AIField[1,5,8] := Point(8,1);
    AIField[1,5,9] := Point(9,1);
    AIField[1,5,10] := Point(10,1);
    AIField[1,5,11] := Point(11,1);

    AIField[1,4,0] := Point(0,2);
    AIField[1,4,1] := Point(1,2);
    AIField[1,4,2] := Point(2,2);
    AIField[1,4,3] := Point(3,2);
    AIField[1,4,4] := Point(4,2);
    AIField[1,4,5] := Point(5,2);
    AIField[1,4,6] := Point(6,2);
    AIField[1,4,7] := Point(7,2);
    AIField[1,4,8] := Point(8,2);
    AIField[1,4,9] := Point(9,2);
    AIField[1,4,10] := Point(10,2);
    AIField[1,4,11] := Point(11,2);

    AIField[1,3,0] := Point(0,3);
    AIField[1,3,1] := Point(1,3);
    AIField[1,3,2] := Point(2,3);
    AIField[1,3,3] := Point(3,3);
    AIField[1,3,4] := Point(4,3);
    AIField[1,3,5] := Point(5,3);
    AIField[1,3,6] := Point(6,3);
    AIField[1,3,7] := Point(7,3);
    AIField[1,3,8] := Point(8,3);
    AIField[1,3,9] := Point(9,3);
    AIField[1,3,10] := Point(10,3);
    AIField[1,3,11] := Point(11,3);

    AIField[1,2,0] := Point(0,4);
    AIField[1,2,1] := Point(1,4);
    AIField[1,2,2] := Point(2,4);
    AIField[1,2,3] := Point(3,4);
    AIField[1,2,4] := Point(4,4);
    AIField[1,2,5] := Point(5,4);
    AIField[1,2,6] := Point(6,4);
    AIField[1,2,7] := Point(7,4);
    AIField[1,2,8] := Point(8,4);
    AIField[1,2,9] := Point(9,4);
    AIField[1,2,10] := Point(10,4);
    AIField[1,2,11] := Point(11,4);

    AIField[1,1,0] := Point(0,5);
    AIField[1,1,1] := Point(1,5);
    AIField[1,1,2] := Point(2,5);
    AIField[1,1,3] := Point(3,5);
    AIField[1,1,4] := Point(4,5);
    AIField[1,1,5] := Point(5,5);
    AIField[1,1,6] := Point(6,5);
    AIField[1,1,7] := Point(7,5);
    AIField[1,1,8] := Point(8,5);
    AIField[1,1,9] := Point(9,5);
    AIField[1,1,10] := Point(10,5);
    AIField[1,1,11] := Point(11,5);

    AIField[1,0,0] := Point(0,6);
    AIField[1,0,1] := Point(1,6);
    AIField[1,0,2] := Point(2,6);
    AIField[1,0,3] := Point(3,6);
    AIField[1,0,4] := Point(4,6);
    AIField[1,0,5] := Point(5,6);
    AIField[1,0,6] := Point(6,6);
    AIField[1,0,7] := Point(7,6);
    AIField[1,0,8] := Point(8,6);
    AIField[1,0,9] := Point(9,6);
    AIField[1,0,10] := Point(10,6);
    AIField[1,0,11] := Point(11,6);


    for I := 0 to 10 do begin
      AIField[0,i,-1] := Point (i,-1);
    end;
    for I := 11 to 21 do begin
      AIField[1,i,-1] := Point (i,-1);
    end;
    }

end;

//--------------------------------------------------------


function TBrain.AdjustFatigue ( const Stamina , Roll: integer ): TRoll;
begin
    // 20st -3      30st-2      45st -1    a ogni Roll   possibilità 50% fissa di avere malus in base ai punti stamina rimanenti.
  case Stamina of
    60..120: begin
      Result.value := Roll;
      result.fatigue:= 'N';
    end;

    0..59: begin
      result.fatigue:= 'F';
        case RndGenerate(100) of
          0..50: begin
            result.value := Roll;
            result.fatigue:= 'N';//normal
          end;
          51..100: begin
            case Stamina of
              41..59: begin
                if Gender ='f' then
                Result.value := Roll -1
                else Result.value := -2;
              end;
              21..40: begin
                if Gender ='f' then
                Result.value := Roll -2
                else Result.value := -4;
              end;
              1..20: begin
                if Gender ='f' then
                Result.value := Roll -3
                else Result.value := -5;
              end;
              0: begin
                if Gender ='f' then
                Result.value := Roll -4
                else Result.value := -6;
              end;
            end;
          end;

        end;
    end;
  end;


  if Result.value <= 0 then Result.value := 1;

end;
function TBrain.RndGenerate( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (1, Upper + 1));
end;
function TBrain.RndGenerate0( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (0, Upper + 1));
end;
function TBrain.RndGenerateRange( Lower, Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (Lower, Upper + 1));
end;





{--------------------------------------------------------------------------------------------------------------------------------------------------

██████╗  █████╗ ██╗     ██╗
██╔══██╗██╔══██╗██║     ██║
██████╔╝███████║██║     ██║
██╔══██╗██╔══██║██║     ██║
██████╔╝██║  ██║███████╗███████╗
╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
---------------------------------------------------------------------------------------------------------------------------------------------------}
constructor TBall.create ( abrain: TBrain );
begin
  brain := aBrain;
  PathBall:= dse_pathplanner.TPath.Create ;
  Player := nil;
  CellX := 5;
  Celly := 3;
end;
destructor TBall.Destroy;
begin

  PathBall.clear;
  PathBall.free;

end;
function TBall.GetCells: Tpoint ;
begin
  Result := Point ( cx, cy );
end;
procedure TBall.SetCells ( v: Tpoint );
begin
  Cx := v.X;
  cy := v.Y;
end;

procedure TBall.SetCellX ( v: ShortInt );
var
  aPlayer: TPlayer;
begin
  Cx:= v;
 {  pro o pre mettono aplayer.canskill:= false. shp bounce mi ritorna la palla canskill=false. non posso più muovere la palla. lo stesso per ogni bounce }
  aPlayer := brain.GeTPlayer ( Cx, Cy);
  if aPlayer <> nil then
   aPlayer.CanSkill := True;
end;
procedure TBall.SetCellY ( v: ShortInt );
var
  aPlayer: TPlayer;
begin
  Cy:= v;
 {  pro o pre mettono aplayer.canskill:= false. shp bounce mi ritorna la palla canskill=false. non posso più muovere la palla. lo stesso per ogni bounce }
  aPlayer := brain.GeTPlayer ( Cx, Cy);
  if aPlayer <> nil then
   aPlayer.CanSkill := True;
end;
function Tball.GetZone : byte;
begin
  if Cx <=3 then Result :=0
    else if (Cx > 2) and ( Cx <=7) then
         Result:=2
         else if Cx > 7 then Result:=1;
end;
procedure TBall.SetPlayer ( v: TPlayer );
begin
  if v <> nil then begin
    CellX := v.CellX ;
    CellY := v.CellY ;
  end;
end;
function TBall.GetPlayer : TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := brain.Players.count -1 downto 0 do begin
    if (brain.Players[i].cx = CellX) and (brain.Players[i].cy = CellY) then begin
      Result := brain.Players[i];
      exit;
    end;

  end;

end;
Function TBall.BallIsOutSide : boolean;
begin
  result := IsOutSide (CellX, CellY);
end;

{--------------------------------------------------------------------------------------------------------------------------------------------------
██████╗ ██╗      █████╗ ██╗   ██╗███████╗██████╗
██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝██╔════╝██╔══██╗
██████╔╝██║     ███████║ ╚████╔╝ █████╗  ██████╔╝
██╔═══╝ ██║     ██╔══██║  ╚██╔╝  ██╔══╝  ██╔══██╗
██║     ███████╗██║  ██║   ██║   ███████╗██║  ██║
╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
---------------------------------------------------------------------------------------------------------------------------------------------------}
constructor TPlayer.create ( const aTeam, aGuidTeam, aMatchesPlayed : integer; const aIds, aName, aSurname, AT: string; Talent1,Talent2: integer );
begin
  Ids := aIds;
  Team := aTeam;

  GuidTeam:= aGuidTeam;

  //if  brain.GameMode = pvp then begin
    MatchesPlayed := aMatchesPlayed;
    MatchesLeft := (SEASON_MATCHES * 15) - MatchesPlayed;
    Age:= Trunc(  MatchesPlayed  div SEASON_MATCHES) + 18 ;
  //end;

  SurName := aSurname;
  iTag := 0;

  DefaultAttributes:= AT;
  Attributes:= AT;
  TalentId1 := Talent1;
  TalentId2 := Talent2;
  InterceptModifier := 0;
  ActiveSkills:= TstringList.Create;
  cx := 0;
  cy := 0;
  CanMove := true;
  CanSkill := true;
  CanDribbling := true;
  BonusSHPAREAturn :=0;
  BonusSHPturn :=0;
  BonusFinishingturn :=0;
  MovePath := dse_pathplanner.TPath.Create ;

  BonusBuffD := 0;
  BonusBuffM := 0;
  BonusBuffF := 0;

end;

destructor TPlayer.Destroy;
begin
  ActiveSkills.Free;
  MovePath.Free;
  inherited;
end;

function TPlayer.HasBall : boolean;
begin
  if ( CellX = Brain.Ball.CellX ) and ( CellY = Brain.Ball.CellY )  then
    result := true
    else result := false;
end;
// deprecated
function TPlayer.InCrossingCell : boolean;
begin
Result := false;
  case Team of
    0: begin
        if (CellX = 10 ) and ( (CellY <= 1) or (CellY >= 5) )  then begin
          Result := True;
        end;
       end;
    1: begin
        if (CellX = 1 ) and ( (CellY <= 1) or (CellY >= 5) )  then begin
          Result := True;
        end;
       end;
  end;

end;
function TPlayer.InShotCell : boolean;
var
  i: integer;
begin
  Result := false;
  for i := 0 to  ShotCells.Count -1 do begin
    if  (ShotCells[i].CellX = CellX) and (ShotCells[i].CellY = CellY)
    and (ShotCells[i].DoorTeam  <> Team) then begin// opposto, bene cosi'
      result := True;
      Exit;
    end;
  end;

end;
function TPlayer.onBottom : TBottomPosition; // 1 NearCornerCell 2 BottomNoShot 3 BottomShot
begin
  Result := BottomNone;
  case Team of
    0: begin
      if ( ( CellX = 10 ) and ( CellY = 0)  ) or ( ( CellX = 10 ) and ( CellY = 6)  ) then
        Result := NearCornerCell
        else if ( ( CellX = 10 ) and ( CellY = 1)  ) or ( ( CellX = 10 ) and ( CellY = 5)  )  then
          Result := BottomNoShot
          else if ( CellX = 10 ) then Result := BottomShot;


    end;
    1: begin
      if ( ( CellX = 1 ) and ( CellY = 0)  ) or ( ( CellX = 1 ) and ( CellY = 6)  ) then
        Result := NearCornerCell
        else if ( ( CellX = 1 ) and ( CellY = 1)  ) or ( ( CellX = 1 ) and ( CellY = 5)  )  then
          Result := BottomNoShot
          else if ( CellX = 1 ) then Result := BottomShot;
    end;
  end;
end;
function TPlayer.InCrossingArea : boolean;
begin
  Result := false;
  if Team = 0 then begin
    if (CellX = 10) or (CellX = 9) then begin
      if (CellY >= 2) and (CellY <=4) then begin
        Result := true;
        Exit;
      end;
    end;
  end
  else begin
    if (CellX = 1) or (CellX = (2)) then begin
      if (CellY >= 2) and (CellY <=4) then begin
        Result := true;
        Exit;
      end;
    end;
  end;

end;

function TPlayer.GetField : byte;
begin
    if Team = 0 then begin
      if (CellX < 6) then
        Result := 0
        else Result := 1;
    end
    else begin
      if (CellX > 5) then
        Result := 1
        else Result := 0;
    end;

end;
function TPlayer.GetZoneRole : char;
begin
  if Cx <=3 then begin
    if Team = 0 then
      Result := 'D'
      else Result := 'F';
  end
  else if (Cx > 2) and ( Cx <=7) then
      Result := 'M'
  else if Cx > 7 then begin
    if Team = 0 then
      Result := 'F'
      else Result := 'D';
  end;
  if CY < 0 then
    Result := 'N';

end;
function TPlayer.GetCells: Tpoint ;
begin
  Result := Point ( cx, cy );
end;
procedure TPlayer.SetCells ( v: Tpoint );
begin
  Cx := v.X;
  cy := v.Y;
end;
function TPlayer.GetDefaultCells: Tpoint ;
begin
  Result := Point ( DefaultCellX, DefaultCellY );
end;
procedure TPlayer.SetDefaultCells ( v: Tpoint );
begin
  DefaultCellX := v.X;
  DefaultCellY := v.Y;

  case team of
    0: if (DefaultCellX = 0) and (DefaultCellY=3) then Role := 'G'
        else if DefaultCellX = 2 then Role := 'D'
          else if DefaultCellX = 5 then Role := 'M'
            else if  DefaultCellX = 8 then Role := 'F'
            else Role := 'N';

    1: if (DefaultCellX = 11) and (DefaultCellY=3) then Role := 'G'
        else if DefaultCellX = 9 then Role := 'D'
          else if DefaultCellX = 6 then Role := 'M'
            else if  DefaultCellX = 3 then Role := 'F'
            else Role := 'N';
  end;


end;
procedure TPlayer.SetCellX ( v: ShortInt );
begin
  Cx:= v;
end;
procedure TPlayer.SetCellY ( v: ShortInt );
begin
  Cy:= v;
end;
function TPlayer.GetMarketValue: Integer;
var
  value: Integer;
begin
  if TalentID1 <> 1 then begin  // <> goalkeeper

  Value :=  Trunc ( DefaultSpeed *   MARKET_VALUE_ATTRIBUTE [DefaultSpeed] +
             DefaultDefense *   MARKET_VALUE_ATTRIBUTE [DefaultDefense] +
             DefaultPassing *   MARKET_VALUE_ATTRIBUTE [DefaultPassing] +
             DefaultBallControl *   MARKET_VALUE_ATTRIBUTE [DefaultBallControl] +
             DefaultShot *   MARKET_VALUE_ATTRIBUTE [DefaultShot] +
             DefaultHeading *   MARKET_VALUE_ATTRIBUTE [DefaultHeading])
  end
  else  begin // if TalentID1 = 1
  Value :=  Trunc ((DefaultDefense *   MARKET_VALUE_ATTRIBUTE [DefaultDefense] * MARKET_VALUE_ATTRIBUTE_DEFENSE_GK) +
             DefaultPassing *   MARKET_VALUE_ATTRIBUTE [DefaultPassing]  );
  end;

  if TalentID1 <> 0 then Value := Trunc (Value  *  MARKET_VALUE_TALENT1) ; //se c'è un talento, anche goalkeeper

  if TalentID2 <> 0 then Value :=  Trunc (Value  *  MARKET_VALUE_TALENT2) ; //se c'è un talento, anche goalkeeper
  Result := value;

  // age non influenza il marketvalue.

end;

function TPlayer.GetActiveAttrTalValue: Integer;
var
  value: Integer;
begin
// il brain ha già caricato in memoria eventuali buff casalinghi o di morale.
    Value :=  Speed + Defense + Passing + BallControl + Shot + Heading ;

  if TalentID1 <> 0 then Value := Value + 6 ; //se c'è un talento, anche goalkeeper    6 e 12 valori fissi al momento

  if TalentID2 <> 0 then Value :=  Value + 12; //se c'è un talento, anche goalkeeper
  Result := value;



end;
procedure TPlayer.resetALL;
begin
  BonusFinishing := 0;
  resetTAC;
  resetLBC;
  resetPRO;
  resetPRE;
  resetSHP;
  resetPLM;
//  resetSHPAREA;
end;
procedure TPlayer.resetFIN;
begin
  BonusFinishingTurn :=0;
  Shot      := DefaultShot;
end;
procedure TPlayer.resetTAC;
begin
  BonusTackleTurn :=0;
  Passing   := DefaultPassing;
  Shot      := DefaultShot;
end;
procedure TPlayer.resetLBC;
begin
  BonusLopBallControlTurn :=0;
  BallControl := DefaultBallControl;
end;
procedure TPlayer.resetPRO;
begin
  BonusProtectionTurn :=0;
  BallControl := DefaultBallControl;
end;
procedure TPlayer.resetPRE;
begin
  UnderPressureTurn := 0;
  if (injured = 0) and (Role <> 'G') then begin
   CanMove := True;
  end;
  Passing     := DefaultPassing;
  BallControl := DefaultBallControl;
  Shot        := DefaultShot;
end;
procedure TPlayer.resetSHP;
begin
  BonusSHPturn :=0;
  Passing     := DefaultPassing;
  BallControl := DefaultBallControl;
  Shot        := DefaultShot;
end;
procedure TPlayer.resetSHPAREA;
begin
  BonusSHPAREAturn :=0;
  Shot := DefaultShot;
end;
procedure TPlayer.resetPLM;
begin
  BonusPLMturn :=0;
  Shot    := DefaultShot;
  Passing := DefaultPassing;
end;
procedure TPlayer.LoadDefaultAttributes (  v: Shortstring );
var
  Ts: TstringList;
begin

  fDefaultAttributes := v;
  Ts:= tstringlist.Create ;
  Ts.CommaText := v;
  if Ts.Count > 0 then begin
    DefaultSpeed:= StrToIntDef(ts [0],1);
    DefaultDefense:= StrToIntDef(ts[1],1);
    DefaultPassing:= StrToIntDef(ts[2],1);
    DefaultBallControl:= StrToIntDef(ts[3],1);
    DefaultShot:= StrToIntDef(ts[4],1);
    DefaultHeading:= StrToIntDef(ts[5],1);
  end;
  Ts.Free;


  if role = 'G' then CanMove:= false;


end;
procedure TPlayer.LoadAttributes (  v: ShortString );
var
  Ts: TstringList;
begin

  fAttributes := v;
  Ts:= tstringlist.Create ;
  Ts.CommaText := v;
  if Ts.Count > 0 then begin
    Speed:= StrToIntDef(ts [0],1);
    Defense:= StrToIntDef(ts[1],1);
    Passing:= StrToIntDef(ts[2],1);
    BallControl:= StrToIntDef(ts[3],1);
    Shot:= StrToIntDef(ts[4],1);
    Heading:= StrToIntDef(ts[5],1);
  end;
  Ts.Free;


  if (role = 'G')  or (TalentID1=1) then  CanMove:= false;

end;
procedure TPlayer.SetGameOver ( const value: Boolean);
begin
  fGameOver := value;
  if fGameOver then
     resetALL;
end;
procedure TPlayer.SetSpeed( v: ShortInt );
begin
  fSpeed := v;
  if fSpeed <= 0 then fSpeed := 1;
end;
procedure TPlayer.SetStamina( v: SmallInt );
begin
  fStamina := v;
  if fStamina < 0 then fStamina := 0;
end;
procedure TPlayer.SetDefense( v: ShortInt );
begin
  fDefense := v;
  if fDefense < 0 then fDefense := 0;
end;
procedure TPlayer.SetBallControl( v: ShortInt );
begin
  fBallControl := v;
  if fBallControl < 0 then fBallControl := 0;
end;
procedure TPlayer.SetPassing( v: ShortInt );
begin
  fPassing := v;
  if fPassing < 0 then fPassing := 0;
end;
procedure TPlayer.SetShot( v: ShortInt );
begin
  fShot := v;
  if fShot < 0 then fShot := 0;

end;
procedure TPlayer.SetHeading( v: ShortInt );
begin
  fHeading := v;
  if fHeading < 0 then fHeading := 0;
end;

procedure TBrain.AddSoccerPlayer (aSoccerPlayer: TPlayer );
begin
  aSoccerPlayer.brain:=self;
  Players.add ( aSoccerPlayer );
end;
procedure TBrain.RemoveSoccerPlayer (aSoccerPlayer: TPlayer );
var
  i: Integer;
begin
  for I := Players.count -1 downto 0 do begin
    if Players[i].ids = aSoccerPlayer.ids then begin
      Players.Delete(i);
      Exit;
    end;
  end;

end;
procedure TBrain.AddSoccerReserve (aSoccerPlayer: TPlayer );
begin
  aSoccerPlayer.brain:=self;
  Reserves.add ( aSoccerPlayer );
  PutInReserveSlot( aSoccerPlayer );

end;
procedure TBrain.RemoveSoccerReserve (aSoccerPlayer: TPlayer );
var
  i: Integer;
begin
  for I := Reserves.count -1 downto 0 do begin
    if Reserves[i].ids = aSoccerPlayer.ids then begin
      Reserves.Delete(i);
      Exit;
    end;
  end;

end;
procedure TBrain.AddSoccerGameOver (aSoccerPlayer: TPlayer );
begin
  aSoccerPlayer.brain:=self;
  PutInGameOverSlot( aSoccerPlayer );
  Gameover.add ( aSoccerPlayer );

end;
procedure TBrain.RemoveSoccerGameOver (aSoccerPlayer: TPlayer );
var
  i: Integer;
begin
  for I := Gameover.count -1 downto 0 do begin
    if Gameover[i].ids = aSoccerPlayer.ids then begin
      Gameover.Delete(i);
      Exit;
    end;
  end;

end;

procedure TBrain.ResetPassiveSkills;
var
  t,p, OldPassing, OldBallControl, OldShot: integer;
  aPlayer : TPlayer;
  aList : TObjectList<TPlayer>;
begin

  for P := Players.Count -1  downto 0 do begin
    aPlayer := Players[p];

    if IsOutSide( aPlayer.CellX,aPlayer.CellY)  then Continue; // espulsi, sostituiti , injured sono not canmove e stamina 0 per sempre ma sono ancora in campo

    OldPassing := aPlayer.Passing;
    OldBallControl := aPlayer.BallControl;
    OldShot := aPlayer.Shot;

    aPlayer.PressingDone := False;
    aPlayer.TackleDone:= false;
    aPlayer.CanSkill := true;
    aPlayer.canDribbling := True;
    if (aPlayer.role <> 'G' ) and (aPlayer.UnderPressureTurn <= 0 )  then
      aPlayer.CanMove := true
      else  aPlayer.CanMove := False;


    if aPlayer.BonusProtectionTurn > 0 then begin
      aPlayer.BonusProtectionTurn := aPlayer.BonusProtectionTurn - 1;
      if aPlayer.BonusProtectionTurn <= 0 then begin
        aPlayer.BonusProtectionTurn := 0;
        aPlayer.resetPRO ;
      end;
    end;
    if aPlayer.BonusLopBallControlTurn > 0 then begin
      aPlayer.BonusLopBallControlTurn := aPlayer.BonusLopBallControlTurn - 1;
      if aPlayer.BonusLopBallControlTurn <= 0 then begin
        aPlayer.BonusProtectionTurn:=0;
        aPlayer.BonusLopBallControlTurn := 0;
        aPlayer.resetLBC ;
      end;
    end;
    if aPlayer.BonusTackleTurn > 0 then begin
      aPlayer.BonusTackleTurn := aPlayer.BonusTackleTurn - 1;
      if aPlayer.BonusTackleTurn <= 0 then begin
        aPlayer.BonusProtectionTurn:=0;
        aPlayer.BonusTackleTurn := 0;
        aPlayer.resetTAC ;
      end;
    end;
    if aPlayer.BonusSHPAREATurn > 0 then begin
      aPlayer.BonusSHPAREATurn := aPlayer.BonusSHPAREATurn - 1;
      if aPlayer.BonusSHPAREATurn <= 0 then begin
        aPlayer.BonusSHPAREATurn := 0;
        aPlayer.resetSHPAREA ;
      end;
    end;
    if aPlayer.BonusFinishingTurn > 0 then begin
      aPlayer.BonusFinishingTurn := aPlayer.BonusFinishingTurn - 1;
      if aPlayer.BonusFinishingTurn <= 0 then begin
        aPlayer.BonusFinishingTurn := 0;
        aPlayer.resetFin ;
      end;
    end;
//    if aPlayer.Team = Brain.TeamTurn then aPlayer.resetPRO ;  // inizio del mio turno perdo protection

    if aPlayer.UnderPressureTurn > 0 then begin

      aPlayer.UnderPressureTurn := aPlayer.UnderPressureTurn - 1;
      if aPlayer.UnderPressureTurn <= 0 then begin
        aPlayer.UnderPressureTurn := 0;
        aPlayer.resetPRE ;
      end;
    end;

    aPlayer.resetSHP ;  // resetta anche ballcontrol quindi ricalcolo protection e pressing  - resetta anche shpAREA
    aPlayer.resetPLM ;

    // dopo i reset devo manatenere pressing e protection durante il passaggio di turno
    if aPlayer.BonusProtectionTurn > 0 then
      aPlayer.BallControl :=  aPlayer.DefaultBallControl  + 2;
    if aPlayer.UnderPressureTurn > 0 then begin
      aPlayer.BallControl :=  oldBallControl;
      aPlayer.passing :=  OldPassing;
      aPlayer.Shot :=  OldShot;

    end;

      aPlayer.Speed := aPlayer.DefaultSpeed;
      aPlayer.Defense := aPlayer.DefaultDefense;
      aPlayer.BonusBuffD := 0;
      aPlayer.BonusBuffM := 0;
      aPlayer.BonusBuffF := 0;

      // aPlayer.heding non cambia mai
  end;
  // ora i singoli player sono stati resettati e eventuali bonus ridristibuiti. Se era presente un Buff potrebbe essere stato resettato
  // come no.

  // qui aggiungo i buff per i 3 reparti. tutti i player sono resettati sopra ed eventualmente hanno già i buff semplici
  for T := 0 to 1 do begin

    // TALENT_ID_BUFF_DEFENSE = 139 prereq almeno 3 Defense, 1 talento qualsiasi --> skill 2x buff reparto (5% chance) dif 20 turni + def,ballcontrol,passing +1

//    Il resetAll sopra ha resettato tutto, ma non il portatore di palla
    if Score.BuffD[T] > 0 then begin
      Score.BuffD[T]:= Score.BuffD[T] -1;
      if Score.BuffD[T] > 0 then begin    // metto il buff
        // cerco il reparto e buff
        aList := TObjectList<TPlayer>.create(false);
        CompileRoleList(T,'D', aList);
        for p := aList.Count -1 downto 0 do begin
          if aList[p].HasBall then continue;   // il portatore di palla non è stato resettato sopra
          aList[p].BonusBuffD := 1;
          aList[p].Defense := aList[p].Defense + 1;
          aList[p].BallControl := aList[p].BallControl + 1;
          aList[p].Passing := aList[p].Passing + 1;

        end;
        aList.Free;
      end;
    end;
   //  TALENT_ID_BUFF_MIDDLE = 140 prereq almeno 3 passing, 1 talento qualsiasi --> skill 2x buff reparto (5% chance) cen  20 turni + speed max 4,ballcontrol,passing, shot +1
    if Score.BuffM[T] > 0 then begin
      Score.BuffM[T]:= Score.BuffM[T] -1;
      if Score.BuffM[T] > 0 then begin
        // cerco il reparto e tolgo buff
        aList := TObjectList<TPlayer>.create(false);
        CompileRoleList(T,'M',aList);
        for p := aList.Count -1 downto 0 do begin
          if aList[p].HasBall then continue;   // il portatore di palla non è stato resettato sopra
          if aList[p].Speed < 4 then
            aList[p].Speed := aList[p].Speed + 1;

          aList[p].BonusBuffM := 1;
          aList[p].BallControl := aList[p].BallControl + 1;
          aList[p].Passing := aList[p].Passing + 1;
          aList[p].Shot := aList[p].Shot + 1;
        end;
        aList.Free;
      end;
    end;
   //  TALENT_ID_BUFF_FORWARD = 141 prereq almeno 3 Shot , 1 talento qualsiasi --> skill 2x buff reparto (5% chance) att 20 turni + ballcontrol,passing, shot +1
    if Score.BuffF[T] > 0 then begin
      Score.BuffF[T]:= Score.BuffF[T] -1;
      if Score.BuffF[T] > 0 then begin    // se è ancora maggiore di 0  // altrimenti evita il buff
        // cerco il reparto e tolgo buff
        aList := TObjectList<TPlayer>.create(false);
        CompileRoleList(T,'F',aList);
        for p := aList.Count -1 downto 0 do begin
          if aList[p].HasBall then continue;   // il portatore di palla non è stato resettato sopra
          aList[p].BonusBuffF := 1;
          aList[p].BallControl := aList[p].BallControl + 1;
          aList[p].Passing := aList[p].Passing + 1;
          aList[p].Shot := aList[p].Shot + 1;
        end;
        aList.Free;
      end;
    end;


  end;

end;
procedure TBrain.GetPath1dir ( Team, X1, Y1, X2, Y2, Limit: integer; useFlank,FriendlyWall,OpponentWall,FinalWall,OneDir: boolean; var aPath: dse_pathplanner.TPath );
var
  i,last: integer;
  aPlayer: TPlayer;
  MoveModeX,MoveModeX2: TMoveModeX;
  MoveModeY,MoveModeY2: TMoveModeY;
  label Nextfinal1dir;
begin

// flank non usato
  aPath.Clear;
  GetLinePoints  (  X1, Y1, X2, Y2 , aPath);

  // check se 1dir
  if aPath.Count > 1 then begin   // la partenza c'è ancora

    MoveModeX := Xnone;
    MoveModeY := Ynone;
    MoveModeX2 := Xnone;
    MoveModeY2 := Ynone;

    // se ho la prima direzione
    if aPath[0].X < aPath[1].X then
      MoveModeX := LeftToRight
      else if aPath[0].X > aPath[1].X then
        MoveModeX := RightToLeft
      else if aPath[0].X = aPath[1].X then
        MoveModeX := XNone;

    if aPath[0].Y < aPath[1].Y then
      MoveModeY := UpToDown
      else if aPath[0].Y > aPath[1].Y then
        MoveModeY := DownToUp
      else if aPath[0].Y = aPath[1].Y then
        MoveModeY := YNone;



    aPath.Reverse ;
    aPath.RemoveLast ;
    aPath.Reverse ;
    Last:=aPath.Count-1;
      if aPath.Count > 1 then begin

        for I := 0 to aPath.Count - 1 do begin
          if aPath.Count-1=i then Continue;

          if aPath[i].X < aPath[i+1].X then
            MoveModeX2 := LeftToRight
            else if aPath[i].X > aPath[i+1].X then
              MoveModeX2 := RightToLeft
            else if aPath[i].X = aPath[i+1].X then
              MoveModeX2 := XNone;

          if aPath[i].Y < aPath[i+1].Y then
            MoveModeY2 := UpToDown
            else if aPath[i].Y > aPath[i+1].Y then
              MoveModeY2 := DownToUp
            else if aPath[i].Y = aPath[i+1].Y then
              MoveModeY2 := YNone;

          Last := i;  //<---- se ha deviato non è per via di una wall
          if ( MoveModeX  <> MoveModeX2) or  ( MoveModeY  <> MoveModeY2) then  begin
            //Last := i-1;
            break;
          end;

        end;

      end;

      while aPath.Count > last +1 do begin
        aPath.RemoveLast ;
      end;




  // check wall  in fondo qui
//  last := aPath.Count;
  for i := 0 to aPath.Count -1 do begin
    aPlayer := GeTPlayer (aPath[i].X,aPath[i].Y);
    if aPlayer <> nil then begin
      if FriendlyWall then begin
        if aPlayer.Team = Team then begin
           last := i;
           break;
        end;
      end;
      if OpponentWall then begin
        if aPlayer.Team <> Team then begin
           last := i;
           break;
        end;
      end;
      if FinalWall then begin
           last := i;
           break;
      end;
    end;
  end;

    while aPath.Count > last +1 do begin
      aPath.RemoveLast ;
    end;
  end;
 // Elimino la FinalWall
NextFinal1dir:
  if (FinalWall) and (aPath.Count > 0) then begin
//    for I := aPath.Count-1 downto 0 do begin
//     if Y1 <> aPath[i].Y then asm Int 3 end;
      if GeTPlayer (aPath[aPath.Count-1].X,aPath[aPath.Count-1].Y) <> nil then begin
        //aPath.Steps.Delete(i);
        aPath.RemoveLast ;
        goto NextFinal1dir;
      end

  end;

end;

procedure TBrain.GetPathX ( Team, X1, Y1, X2, Y2, Limit: integer; useFlank,FriendlyWall,OpponentWall,FinalWall,OneDir: boolean; var aPath: dse_pathplanner.TPath );
var
  x, Flank: integer;
  aStep: dse_pathplanner.TPathStep;
  aPlayer: TPlayer;
  label NextFinal;
begin
 // y2 e onedir tenuta solo per compatibilità

  aPath.Clear;
  if (X1 = X2) and (Y1=Y2) then Exit;
  // flank bonus
  Flank :=0;
  if UseFlank then begin
    if (Y1 = 0) or (Y1 = 6) then
      Limit := Limit + 1;
  end;

  if X2 > X1 then begin

    while ( X2 - X1 ) > Limit do begin
      Dec (X2);
    end;


    for x:= X1+1 to X2 do begin
      aPlayer := GeTPlayer (x,Y1);
      if aPlayer <> nil then begin

        if FriendlyWall then begin
          if aPlayer.Team = Team then break;
        end;
        if OpponentWall then begin
          if aPlayer.Team <> Team then break;
        end;
        if (FinalWall) and (x=X2) then break;

        aStep:= dse_pathplanner.TPathStep.Create();
        aStep.X := x;
        aStep.Y := Y1;
        aPath.Add(aStep);
      end
      else begin  // Player = nil
        aStep:= dse_pathplanner.TPathStep.Create();
        aStep.X := x;
        aStep.Y := Y1;
        aPath.Add(aStep);
      end;
    end;

  end
  else if X2 < X1 then begin

    while ( X1 - X2 ) > Limit do begin
      inc (X2);
    end;

    for x:= X1-1 downto X2 do begin
      aPlayer := GeTPlayer (x,Y1);
      if aPlayer <> nil then begin

        if FriendlyWall then begin
          if aPlayer.Team = Team then break;
        end;
        if OpponentWall then begin
          if aPlayer.Team <> Team then break;
        end;
        if (FinalWall) and (x=X2) then break;

        aStep:= dse_pathplanner.TPathStep.Create();
        aStep.X := x;
        aStep.Y := Y1;
        aPath.Add(aStep);
      end
      else begin  // Player = nil
        aStep:= dse_pathplanner.TPathStep.Create();
        aStep.X := x;
        aStep.Y := Y1;
        aPath.Add(aStep);
      end;
    end;
  end;

 // Elimino la FinalWall
NextFinal:
  if (FinalWall) and (aPath.Count > 0) then begin
//    for I := aPath.Count-1 downto 0 do begin
//     if Y1 <> aPath[i].Y then asm Int 3 end;
      if GeTPlayer (aPath[aPath.Count-1].X,aPath[aPath.Count-1].Y) <> nil then begin
        //aPath.Steps.Delete(i);
        aPath.RemoveLast ;
        goto NextFinal;
      end

  end;




end;
procedure TBrain.GetPathY ( Team, X1, Y1, X2, Y2, Limit: integer; useFlank,FriendlyWall,OpponentWall,FinalWall,OneDir: boolean; var aPath: dse_pathplanner.TPath );
var
  y, Flank: integer;
  aStep: dse_pathplanner.TPathStep;
  aPlayer: TPlayer;
  label NextFinal;
begin
 // y2 e onedir tenuta solo per compatibilità

  aPath.Clear;
  if (X1 = X2) and (Y1=Y2) then Exit;
  // flank bonus
  Flank :=0;
  if UseFlank then begin
    if (Y1 = 0) or (Y1 = 6) then
      Limit := Limit + 1;
  end;

  if Y2 > Y1 then begin

    while ( Y2 - Y1 ) > Limit do begin
      Dec (Y2);
    end;


    for y:= Y1+1 to Y2 do begin
      aPlayer := GeTPlayer (X1,y);
      if aPlayer <> nil then begin

        if FriendlyWall then begin
          if aPlayer.Team = Team then break;
        end;
        if OpponentWall then begin
          if aPlayer.Team <> Team then break;
        end;
        if (FinalWall) and (y=Y2) then break;

        aStep:= dse_pathplanner.TPathStep.Create();
        aStep.X := X1;
        aStep.Y := Y;
        aPath.Add(aStep);
      end
      else begin  // Player = nil
        aStep:= dse_pathplanner.TPathStep.Create();
        aStep.X := X1;
        aStep.Y := y;
        aPath.Add(aStep);
      end;
    end;

  end
  else if Y2 < Y1 then begin

    while ( Y1 - Y2 ) > Limit do begin
      inc (Y2);
    end;

    for y:= Y1-1 downto Y2 do begin
      aPlayer := GeTPlayer (X1,y);
      if aPlayer <> nil then begin

        if FriendlyWall then begin
          if aPlayer.Team = Team then break;
        end;
        if OpponentWall then begin
          if aPlayer.Team <> Team then break;
        end;
        if (FinalWall) and (y=Y2) then break;

        aStep:= dse_pathplanner.TPathStep.Create();
        aStep.X := X1;
        aStep.Y := y;
        aPath.Add(aStep);
      end
      else begin  // Player = nil
        aStep:= dse_pathplanner.TPathStep.Create();
        aStep.X := X1;
        aStep.Y := y;
        aPath.Add(aStep);
      end;
    end;
  end;

 // Elimino la FinalWall
NextFinal:
  if (FinalWall) and (aPath.Count > 0) then begin
      if GeTPlayer (aPath[aPath.Count-1].X,aPath[aPath.Count-1].Y) <> nil then begin
        //aPath.Steps.Delete(i);
        aPath.RemoveLast ;
        goto NextFinal;
      end

  end;



end;
procedure TBrain.GetPath ( Team, X1, Y1, X2, Y2, Limit: integer; useFlank,FriendlyWall,OpponentWall,FinalWall: boolean;OneDir: TOneDir; var aPath: dse_pathplanner.TPath );
var
  aSearchMap : TSearchableMap;
  i,p,last,j,F0,F6, Flank: integer;
  aStep: dse_pathplanner.TPathStep;
  MoveModeX,MoveModeX2: TMoveModeX;
  MoveModeY,MoveModeY2: TMoveModeY;
  aBorted: boolean;
  label ExitPath,NextPath,ExitPath2;
begin
  Aborted:=False;
  aPath.Clear;
  if (IsOutSide( X1, Y1 )) or (IsOutSide( X2, Y2 ))  then exit; // espulsi

  aStar:= TAStarPathPlanner.Create(nil) ;
  aSearchMap := TSearchableMap.Create (nil);
  aSearchMap.Width := 12 ;
  aSearchMap.Height  := 7 ;
  aSearchMap.NoDiagonal := false;
  aStar.StateFactory := aSearchMap;
  // AStar.OnSearchState := AnEvent;
  aSearchMap.Clear;
  for i := 0 to asearchMap.Width - 1 do begin
     for j := 0 to asearchMap.height - 1 do begin
        aSearchMap[i,j].Terrain := 1  ;
        if (i= 0) or (i= 11) then aSearchMap[i,j].Terrain := 255;
     end;
  end;
  for i := Players.Count -1  downto 0 do begin
//    aSearchMap[Players[i].cellX ,Players[i].cellY].Terrain := 255  ;
    if isOutSide (Players[i].CellX, Players[i].CellY ) then Continue;

    if FriendlyWall then begin
      if Players[i].Team = Team then
         aSearchMap[Players[i].cellX ,Players[i].cellY].Terrain := 255;
    end;
    if OpponentWall then begin
      if Players[i].Team <> Team then
         aSearchMap[Players[i].cellX ,Players[i].cellY].Terrain := 255;
    end;
//    if FinalWall then begin
//    if (Players[i].CellX = X2) and (Players[i].CellY = Y2) then
 //        aSearchMap[Players[i].cellX ,Players[i].cellY].Terrain := 255;
 //   end;

  end;

  aSearchMap.Reset;
  j := AStar.FindPath( Point(X1,Y1), Point( X2,Y2) );
//  for I := AStar.Path.Count -1 downto 0 do begin
//    outputdebugstring  (pchar (  IntTostr(AStar.Path[i].X) +':' + IntTostr(AStar.Path[i].Y)   )  );

//  end;

  if j > 0 then begin
  // La cella finale non può mai essere un player
 //   if aSearchMap[aStar.Path[aStar.Path.Count-1].X  ,aStar.Path[aStar.Path.Count-1].Y].TerrainCost <> 255  then begin
   // if GeTPlayer (aStar.Path[aStar.Path.Count-1].X  ,aStar.Path[aStar.Path.Count-1].Y) = nil then begin

      // flank bonus
        Flank :=0;
        if UseFlank then begin
          F0:=0;
          F6:=0;
          for I := 0 to aStar.Path.count -1  do begin
            if aStar.Path[i].Y = 0 then inc (F0);
            if aStar.Path[i].Y = 6 then inc (F6);
          end;
          if (F0 = aStar.Path.count) or (F6 = aStar.Path.count) then
            Flank := 1;
        end;


        MoveModeX := Xnone;
        MoveModeY := Ynone;
        MoveModeX2 := Xnone;
        MoveModeY2 := Ynone;

        if (OneDir <> EveryDirection ) and (AStar.Path.Count > 1) then begin   // la partenza c'è ancora

          // se ho la prima direzione
          if AStar.Path[0].X < AStar.Path[1].X then
            MoveModeX := LeftToRight
            else if AStar.Path[0].X > AStar.Path[1].X then
              MoveModeX := RightToLeft
            else if AStar.Path[0].X = AStar.Path[1].X then
              MoveModeX := XNone;

          if AStar.Path[0].Y < AStar.Path[1].Y then
            MoveModeY := UpToDown
            else if AStar.Path[0].Y > AStar.Path[1].Y then
              MoveModeY := DownToUp
            else if AStar.Path[0].Y = AStar.Path[1].Y then
              MoveModeY := YNone;

          Last:=0;
          for I := 1 to AStar.Path.Count - 1 do begin
            if i = AStar.Path.Count -1 then begin
              last :=i;
              break;
            end;
            if AStar.Path[i].X < AStar.Path[i+1].X then
              MoveModeX2 := LeftToRight
              else if AStar.Path[i].X > AStar.Path[i+1].X then
                MoveModeX2 := RightToLeft
              else if AStar.Path[i].X = AStar.Path[i+1].X then
                MoveModeX2 := XNone;

            if AStar.Path[i].Y < AStar.Path[i+1].Y then
              MoveModeY2 := UpToDown
              else if AStar.Path[i].Y > AStar.Path[i+1].Y then
                MoveModeY2 := DownToUp
              else if AStar.Path[i].Y = AStar.Path[i+1].Y then
                MoveModeY2 := YNone;

            Last := i;
            if ( MoveModeX  <> MoveModeX2) or  ( MoveModeY  <> MoveModeY2) then  begin
              if OneDir = AbortMultipleDirection then  begin // non voglio pezzi di OneDir. la annullo
                Aborted := true;
                goto ExitPath2;
              end;

              if OneDir = TruncOneDir then
              break;
            end;

          end;

          while aStar.Path.Count <> Last+1 do begin
            aStar.Path.RemoveLast;
          end;



        end;

        // elimino la partenza
        aStar.Path.Reverse ;
        aStar.Path.RemoveLast;
        aStar.Path.Reverse ;
//  for I := AStar.Path.Count -1 downto 0 do begin
//    outputdebugstring  (pchar (  IntTostr(AStar.Path[i].X) +':' + IntTostr(AStar.Path[i].Y)   )  );
//  end;


        //
        if OneDir = EveryDirection then
          aStar.Path.Limit  := Limit + 1 + Flank
          else if (OneDir = TruncOneDir) or (OneDir = AbortMultipleDirection) then
            aStar.Path.Limit  := iMin ( aStar.Path.Count + 1, Limit + 1);


//  for I := AStar.Path.Count -1 downto 0 do begin
//    outputdebugstring  (pchar (  IntTostr(AStar.Path[i].X) +':' + IntTostr(AStar.Path[i].Y)   )  );

//  end;

        // può essere cambiato , elimino il finalplayer (tutti)
        if FinalWall then begin
  NextPath:
          for I := AStar.Path.Count -1 downto 0 do begin

              if geTPlayer ( aStar.Path[i].X,aStar.Path[i].Y ) <> nil then begin

//              for p := 0 to Players.Count -1 do begin
//              if (Players[p].CellX = aStar.Path[aStar.Path.Count-1].X ) and
//                  (Players[p].CellY = aStar.Path[aStar.Path.Count-1].Y)  then begin
                AStar.Path.Steps.Delete (i);
             //   found := true;
                goto NextPath;
              end
             // if found = true then goto ExitPath;
           // end;
          end;
        end;

ExitPath:
        for I := 0 to AStar.Path.Count -1 do begin
          aStep:= dse_pathplanner.TPathStep.Create();
          aStep.X := AStar.Path.Step [i].X;
          aStep.Y := AStar.Path.Step [i].Y;
          aPath.Add(aStep);
        end;

 //   end;
  end;

ExitPath2:
  if Aborted then
    aPath.Clear;

  aSearchMap.Free;
  aStar.free;
end;


procedure TBrain.SwapPlayers (PlayerA, PlayerB: TPlayer);
var
  tmp: TPoint;
  tmpCof,tmpFK1,tmpFK2,tmpFK3,tmpFK4: Boolean;
begin

  tmp := Point (PlayerA.CellX, PlayerA.CellY);
  PlayerA.CellX := PlayerB.CellX;
  PlayerA.CellY := PlayerB.CellY;

  PlayerB.CellX := tmp.X;
  PlayerB.CellY := tmp.Y;
  // swappo anche cof ,fk1, ecc...

  tmpCof :=  PlayerA.isCOF;
  tmpFK1 :=  PlayerA.isFK1;
  tmpFK2 :=  PlayerA.isFK2;
  tmpFK3 :=  PlayerA.isFK3;
  tmpFK4 :=  PlayerA.isFK4;

  PlayerA.isCOF := PlayerB.isCOF;
  PlayerA.isFK1 := PlayerB.isFK1;
  PlayerA.isFK2 := PlayerB.isFK2;
  PlayerA.isFK3 := PlayerB.isFK3;
  PlayerA.isFK4 := PlayerB.isFK4;


  PlayerB.isCOF := tmpCof;
  PlayerB.isFK1 := tmpFK1;
  PlayerB.isFK2 := tmpFK2;
  PlayerB.isFK3 := tmpFK3;
  PlayerB.isFK4 := tmpFK4;

end;
procedure TBrain.SwapformationPlayers (PlayerA, PlayerB: TPlayer);
var
  tmp,aPoint: TPoint;
begin
  //ricavo anche le formation_x e Y
  tmp := Point (PlayerA.AIFormationCellX, PlayerA.AIFormationCellY);

  aPoint:=Tv2AiField(PlayerA.team,PlayerA.DefaultCellX,PlayerA.DefaultCellY);
  PlayerA.AIFormationCellX := aPoint.X;
  PlayerA.AIFormationCellY  := aPoint.Y;;

  PlayerB.AIFormationCellX := tmp.X;
  PlayerB.AIFormationCellY := tmp.Y;


end;
procedure TBrain.SwapDefaultPlayers (PlayerA, PlayerB: TPlayer);
var
  tmp: TPoint;
begin
  //ricavo anche le formation_x e Y e role
  tmp := Point (PlayerA.DefaultCellX, PlayerA.DefaultCellY);
  PlayerA.DefaultCellS := PlayerB.DefaultCellS;

//  aPoint:=Brain.Tv2AiField(PlayerA.team,PlayerA.DefaultCellX,PlayerA.DefaultCellY);
//  PlayerA.FormationCellX := aPoint.X;
//  PlayerA.FormationCellY  := aPoint.X;;

  PlayerB.DefaultCells := tmp;

//  aPoint:=Brain.Tv2AiField(PlayerA.team,PlayerB.DefaultCellX,PlayerB.DefaultCellY);
//  PlayerB.FormationCellX := aPoint.X;
//  PlayerB.FormationCellY  := aPoint.X;;


end;
procedure TBrain.GetNeighbournsOpponent ( X, Y, Team: integer; var aList : TObjectList<TPlayer> );
var
  i: integer;
begin
  for I := Players.Count -1 downto 0 do begin
    if IsOutSide( Players[i].CellX ,Players[i].CellY ) then Continue;

    if (Players[i].Team <> Team) and  // solo avversari
    not (Players[i].Role='G' ) and    // non il portiere
    (absDistance ( X , Y , Players[i].CellX, Players[i].CellY ) = 1) // a distanza 1
    then begin
      aList.add (Players[i] );
    end;

  end;

end;

function TBrain.GetCrossOpponent ( aPlayer:TPlayer ): TPlayer;
begin
// ritorna il player che si oppone al cross
Result := nil;
    case aPlayer.cellY of
      0..1: begin
              Result := GeTPlayerOpponent ( aPlayer.cellX, aPlayer.CellY+1, aPlayer.team );

            end;
      5..6: begin
              Result := GeTPlayerOpponent ( aPlayer.cellX, aPlayer.CellY-1, aPlayer.team );
            end;
    end;

end;
function TBrain.CheckScore ( team: Integer): integer;
var
  adv : byte;
begin
  if team=0 then adv := 1
    else adv:=0;

  Result := Score.gol[team] -  Score.gol[adv];

end;

function TBrain.GeTPlayer ( X, Y, Team : integer): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].cx = X) and (Players[i].cy = Y) and (Players[i].team = Team)  then begin
      Result := Players[i];
      exit;
    end;

  end;
end;
function TBrain.GeTPlayer2 ( X, Y, Team : integer): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].cx = X) and (Players[i].cy = Y) and  (Players[i].team = Team)  then begin
      Result := Players[i];
      exit;
    end;

  end;
  for I := Reserves.Count -1 downto 0 do begin
    if (Reserves[i].CellX = X) and (Reserves[i].CellY = Y) and  (Reserves[i].team = Team)  then begin
      Result := Reserves[i];
      exit;
    end;
  end;

end;
function TBrain.GeTPlayerOpponent (X,Y: Integer; Team: integer): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].cx = X) and (Players[i].cy = Y) and (Players[i].team <> Team)  then begin
      Result := Players[i];
      exit;
    end;

  end;
end;
function TBrain.GeTPlayerOpponent (ids: string; Team: integer): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].ids = ids) and (Players[i].team <> Team)  then begin
      Result := Players[i];
      exit;
    end;

  end;
end;

function TBrain.GeTPlayer ( X, Y : integer): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].cx = X) and (Players[i].cy = Y) then begin
      Result := Players[i];
      exit;
    end;

  end;
end;
function TBrain.GeTPlayerRandom ( Team: integer; GK:boolean): TPlayer;
var
  aPlayer : TPlayer;
  arnd :Integer;
  label retry;
begin
retry:
  arnd := RndGenerate (Players.Count -1 );
  aPlayer := Players[aRnd];
  if ((aPlayer.TalentId1 = TALENT_ID_GOALKEEPER) and (GK = False))  or ( aPlayer.Team <> Team) then
    goto retry;
  Result := aPlayer;
end;
function TBrain.GetReservePlayerRandom ( Team: integer; GK:boolean): TPlayer;
var
  aPlayer : TPlayer;
  arnd :Integer;
  label retry;
begin
retry:
  arnd := RndGenerate0 (Reserves.Count -1 );
  aPlayer := Reserves[aRnd];
  if ((aPlayer.TalentId1 = TALENT_ID_GOALKEEPER) and (GK = False))  or ( aPlayer.Team <> Team) then
    goto retry;
  Result := aPlayer;
end;
function TBrain.GetTotalReserve ( Team: integer; GK:boolean): integer;
var
  aPlayer : TPlayer;
  i: Integer;
begin
  Result := 0;
  if Reserves.Count = 0 then
    Exit;

  for I := 0 to Reserves.Count -1 do begin
    aPlayer := Reserves[i];
    if aPlayer.Team = Team Then begin
      Result := Result + 1;
      if ((aPlayer.TalentId1 = TALENT_ID_GOALKEEPER) and (GK = False)) then
      Result := Result - 1;
    end;
  end;

end;
function TBrain.GeTPlayer2 ( X, Y : integer): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].cx = X) and (Players[i].cy = Y) then begin
      Result := Players[i];
      exit;
    end;
  end;
  for I := Reserves.Count -1 downto 0 do begin
    if (Reserves[i].cx = X) and (Reserves[i].cx = Y) then begin
      Result := Reserves[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayerReserve( ids : string ): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Reserves.Count -1 downto 0 do begin
    if (Reserves[i].ids = ids) then begin
      Result := Reserves[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayerDefault ( X, Y : integer): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].defaultCellX = X) and (Players[i].defaultCellY = Y) then begin
      Result := Players[i];
      exit;
    end;

  end;
end;
function TBrain.GeTPlayerDefault2 ( X, Y : integer): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].defaultCellX = X) and (Players[i].defaultCellY = Y) then begin
      Result := Players[i];
      exit;
    end;
  end;
  for I := Reserves.Count -1 downto 0 do begin
    if (Reserves[i].defaultCellX = X) and (Reserves[i].defaultCellY = Y) then begin
      Result := Reserves[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayer ( ids: string ): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].Ids = ids then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayer2 ( ids: string ): TPlayer; // cerca anche in reserve
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].Ids = ids then begin
      Result := Players[i];
      exit;
    end;
  end;
  for I := Reserves.Count -1 downto 0 do begin
    if Reserves[i].Ids = ids then begin
      Result := Reserves[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayer3 ( ids: string ): TPlayer; // cerca chi ha giocato in una partita
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].Ids = ids then begin
      Result := Players[i];
      exit;
    end;
  end;
  for I := Gameover.Count -1 downto 0 do begin
    if Gameover[i].Ids = ids then begin
      Result := Gameover[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayerRandom3 : TPlayer; // cerca chi ha giocato in una partita ma non un GK
var
  arnd :Integer;
  label retry,JustAplayer;
begin
  Result := nil;
retry:
  arnd := RndGenerate (100 );
  if arnd <= 50 then begin
JustaPlayer:
    arnd := RndGenerate0 (Players.Count -1 );
    Result := Players[aRnd];
  end
  else  begin
    if Gameover.Count <= 0 then
      goto JustaPlayer;
    arnd := RndGenerate0 (Gameover.Count -1 );
    Result := Gameover[aRnd];
  end;
  if (Result.TalentId1 = TALENT_ID_GOALKEEPER) then
    goto retry;

end;

function TBrain.GeTPlayerALL ( ids: string ): TPlayer; // cerca anche in reserve e gameOver
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].Ids = ids then begin
      Result := Players[i];
      exit;
    end;
  end;
  for I := Reserves.Count -1 downto 0 do begin
    if Reserves[i].Ids = ids then begin
      Result := Reserves[i];
      exit;
    end;
  end;
  for I := Gameover.Count -1 downto 0 do begin
    if Gameover[i].Ids = ids then begin
      Result := Gameover[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayerALL ( X, Y : Integer ): TPlayer; // cerca anche in reserve e gameOver
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].cx = X) and (Players[i].cy = Y)   then begin
      Result := Players[i];
      exit;
    end;
  end;
  for I := Reserves.Count -1 downto 0 do begin
    if (Reserves[i].cx = X) and (Reserves[i].cy = Y)   then begin
      Result := Reserves[i];
      exit;
    end;
  end;
  for I := Gameover.Count -1 downto 0 do begin
    if (Gameover[i].cx = X) and (Gameover[i].cy = Y)   then begin
      Result := Gameover[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayer ( ids: string; team:integer ): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].Ids = ids) and (Players[i].Team  = team)   then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GeTPlayer2 ( ids: string; team:integer ): TPlayer; // cerca anche in reserve
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].Ids = ids) and (Players[i].Team  = team)   then begin
      Result := Players[i];
      exit;
    end;
  end;
  for I := Reserves.Count -1 downto 0 do begin
    if (Reserves[i].Ids = ids) and (Reserves[i].team = team) then begin
      Result := Reserves[i];
      exit;
    end;
  end;
end;
function TBrain.GetGK ( team: integer ): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin

    if (Players[i].role ='G') and ( Players[i].team = team ) then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GetOpponentGK ( team: integer ): TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if IsOutSide( Players[i].CellX ,Players[i].CellY ) then Continue;

    if (Players[i].role ='G') and ( Players[i].team <> team ) then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GetCof: TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].isCOF then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GetFK1: TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].isFK1 then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GetFK2: TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].isFK2 then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GetFK3: TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].isFK3 then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GetFK4: TPlayer;
var
  i: integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0 do begin
    if Players[i].isFK4 then begin
      Result := Players[i];
      exit;
    end;
  end;
end;
function TBrain.GetInjuredPlayer ( Team: integer ): TPlayer;
var
  i: Integer;
begin
  Result := nil;
  for I := Players.Count -1 downto 0  do begin
    if (Players[i].Team = Team) and (Players[i].Injured > 0) then begin
      Result := Players[i];
      exit;
    end;
  end;

end;

function TBrain.GetFriendInCrossingArea ( const aPlayer: TPlayer ) : boolean;
var
  p: integer;
  aFriend: TPlayer;
  tmp: Integer;
begin
  Result := false;
  tmp := CrossingRangeMax;
  if (aPlayer.TalentId1 = TALENT_ID_LONGPASS) or (aPlayer.TalentId2 = TALENT_ID_LONGPASS) then
    tmp := tmp +1;
  for P := Players.Count -1 downto 0 do begin
    aFriend := Players[p];
    if IsOutSide( aFriend.CellX ,aFriend.CellY ) then Continue;

    if (absDistance( aPlayer.CellX ,aPlayer.CellY,  aFriend.CellX, aFriend.CellY ) > ( tmp ))
    or (absDistance( aPlayer.CellX ,aPlayer.CellY,  aFriend.CellX, aFriend.CellY ) < CrossingRangeMin)  then begin
      continue;
    end;

    if ( aFriend.ids = aPlayer.Ids )  then begin  // non sè stesso
      Continue;
    end;

    if  ( aFriend.Team = aPlayer.Team ) and (aFriend.InCrossingArea) then begin
      Result := true;
      exit;
    end;

  end;
end;
function TBrain.GetFriendAhead ( const aPlayer: TPlayer ) : TPlayer;
var
  p: integer;
  aFriend: TPlayer;
  tmp: Integer;
  lstFriendAhead: TObjectList<TPlayer>;
begin
  Result := nil;
  lstFriendAhead:= TObjectList<TPlayer>.Create(False);

  tmp := ShortPassRange;
  if (aPlayer.TalentId1 = TALENT_ID_LONGPASS) or (aPlayer.TalentId2 = TALENT_ID_LONGPASS) then
    tmp := tmp +1;
  // riempe una lista di friend a cui passare il pallone

  for P := Players.Count -1 downto 0 do begin
    aFriend := Players[p];
    if IsOutSide( aFriend.CellX, aFriend.CellY) then continue;

    if (absDistance( aPlayer.CellX ,aPlayer.CellY,  aFriend.CellX, aFriend.CellY ) > ( tmp )) then begin
      continue;
    end;
    if ( aFriend.ids = aPlayer.Ids )  then begin  // non sè stesso
      Continue;
    end;

    if  ( aFriend.Team = aPlayer.Team ) then begin

      if aPlayer.Team = 0 then begin
        if aFriend.CellX > aPlayer.CellX then begin  // solo davanti
          lstFriendAhead.Add( aFriend);
        end;
      end
      else if aPlayer.Team = 1 then begin
        if aFriend.CellX < aPlayer.CellX then begin  // solo davanti
          lstFriendAhead.Add( aFriend);
        end;
      end

    end;

  end;

  // in alcuni casi passo una string ( getbestcrossing eccc...) . verificare leperformance. qui uso il player
  if lstFriendAhead.count > 0 then
    result := GeTPlayer( lstFriendAhead[ RndGenerate0(lstFriendAhead.Count-1)].Ids ) ;

  lstFriendAhead.Free;
end;
procedure TBrain.CompileInterceptList (ShpTeam, MaxDistance: integer; aPath : dse_pathplanner.TPath; var lstIntercepts: TList<TInteractivePlayer> );
var
  i,p: integer;
  anIntercept: TPlayer;
  aInteractivePlayer: TInteractivePlayer;
begin
  lstIntercepts.Clear;
  for P := Players.Count -1 downto 0 do begin
    Players[p].grouped := false;
  end;
  for i := aPath.Count -1 downto 0 do begin
    for P := Players.Count -1 downto 0 do begin
      anIntercept := Players[p];

      if  ( anIntercept.Team <> ShpTeam ) and (anIntercept.Role <> 'G' )
      and ( AbsDistance ( anIntercept.CellX , anIntercept.cellY, aPath[i].X, aPath[i].Y ) <= MaxDistance)
      and ( GeTPlayer ( aPath[i].X, aPath[i].Y ) = nil ) // non occupata da player
      and (Not inLinePath ( aPath[0].X, aPath[0].Y, aPath[aPath.count-1].X, aPath[aPath.count-1].Y,  // non fa parte del normale defense
                            anIntercept.cellX, anIntercept.CellY  )) then begin
        if not anIntercept.grouped then begin
          anIntercept.grouped := true;
          //lstIntercepts.Add(anIntercept);

          aInteractivePlayer:= TInteractivePlayer.Create;
          aInteractivePlayer.Player  :=  anIntercept;
          aInteractivePlayer.Cell := Point ( aPath[i].X ,aPath[i].Y );
          LstIntercepts.add (aInteractivePlayer);
          break;
        end;
      end;
    end;
  end;
end;
procedure TBrain.CompileMovingList (MaxDistance, CellX,CellY: integer; var lstMoving: TList<TInteractivePlayer> );
var
  p: integer;
  aPlayer : TPlayer;
  aList: TObjectList<TPlayer>;
  aInteractivePlayer: TInteractivePlayer;
//  aList: TList<TPlayer>;

begin
    lstMoving.Clear;
  // a distanza 1 un giocatore random prende la palla
    aList:= TObjectList<TPlayer>.create(false);
//    aList:= TList<TPlayer>.create;
    for P := Players.Count -1 downto 0 do begin
      aPlayer := Players[p];
//      if  inExceptPlayers ( aPlayer ) then  continue;
//      aPlayer.grouped := false;
      if (not aPlayer.CanMove) or (aPlayer.Role='G') then continue;
      if (absdistance (  CellX, celly, aPlayer.CellX , aPlayer.CellY) = 1) then
        aList.add (aPlayer);
    end;

    {   i più veloci (speed) }
{    if aList.Count > 0 then begin
      aList.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := R.speed - L.speed;
      end
     ));
      MaxSpeed := aList[0].Speed ;

      for P := aList.Count -1 downto 0 do begin
        if aList[p].Speed < MaxSpeed then
          aList.Delete(p);
      end;
    end; }

    for P := aList.Count -1 downto 0 do begin
        aInteractivePlayer:= TInteractivePlayer.Create;
        aInteractivePlayer.Player  := aList[p];
        aInteractivePlayer.Cell := Point ( CellX , CellY );
        lstMoving.add (aInteractivePlayer);
    end;

    aList.Free;


end;

procedure TBrain.CompileHeadingList (LopTeam, MaxDistance, CellX,CellY: integer; var lstHeading: TList<TInteractivePlayer> );
var
  p: integer;
  aHeading: TPlayer;
  aInteractivePlayer: TInteractivePlayer;
begin
//  CompileHeadingList è molto diversa da CompileinterceptList
  lstHeading.Clear;
  for P := Players.Count -1 downto 0 do begin
    Players[p].grouped := false;
  end;

  for P := Players.Count -1 downto 0 do begin
    aHeading := Players[p];

    if  ( aHeading.Team <> LopTeam ) and (aHeading.Role <> 'G' )
    and ( AbsDistance ( aHeading.CellX , aHeading.cellY, CellX, CellY ) <= MaxDistance) then begin
    //and ( GeTPlayer ( CellX, CellY ) = nil )  then begin // non occupata da player

      if not aHeading.grouped then begin
        aHeading.grouped := true;

        aInteractivePlayer:= TInteractivePlayer.Create;
        aInteractivePlayer.Player  :=  aHeading;
        aInteractivePlayer.Cell := Point ( CellX , CellY );
        lstHeading.add (aInteractivePlayer);
        //break;
      end;
    end;
  end;

      {  prendo il più veloce (speed) }
      lstHeading.sort(TComparer<TInteractivePlayer>.Construct(
      function (const L, R: TInteractivePlayer): integer
      begin
        Result := R.Player.speed - L.Player.speed;
      end
     ));

end;
procedure TBrain.CompileAutoTackleList (PlmTeam, MaxDistance: integer; aPath : dse_pathplanner.TPath; var lstAutoTackle: TList<TInteractivePlayer> );
var
  i,p,FromPath: integer;
  anAutoTackle: TPlayer;
  aInteractivePlayer: TInteractivePlayer;
begin
  lstAutoTackle.Clear ;
  for P := Players.Count -1 downto 0 do begin
    Players[p].grouped := false;
  end;

  if aPath.Count = 1 then
    FromPath := aPath.Count - 1
  else if aPath.Count > 1 then
      FromPath := aPath.Count - 2;

 // for i := aPath.Count - 1 downto 0 do begin //  cella finale nel caso si sposti di 1
  for i := FromPath downto 0 do begin // non cella finale nel caso si sposti di 2 o più
    for P := Players.Count -1 downto 0 do begin
      anAutoTackle := Players[p];
      if  ( anAutoTackle.Team <> PlmTeam ) and (anAutoTackle.Role <> 'G' )
      and ( AbsDistance ( anAutoTackle.CellX , anAutoTackle.cellY, aPath[i].X, aPath[i].Y ) <= MaxDistance)
      and ( GeTPlayer ( aPath[i].X, aPath[i].Y ) = nil )  then begin // non occupata da player
        if not anAutoTackle.grouped then begin
          anAutoTackle.grouped := true;

          aInteractivePlayer:= TInteractivePlayer.Create;
          aInteractivePlayer.Player  :=  anAutoTackle;
          aInteractivePlayer.Cell := Point ( aPath[i].X ,aPath[i].Y );
          lstAutoTackle.add (aInteractivePlayer);
          break;
        end;
      end;
    end;
  end;


end;
procedure TBrain.CompileRoleList (team: Integer; role: Char; var lstRole: TObjectList<TPlayer> );
var
  p: integer;
  aPlayer : TPlayer;
//  aList: TList<TPlayer>;

begin
    lstRole.Clear;
    for P := Players.Count -1 downto 0 do begin
      aPlayer := Players[p];
      if (aPlayer.Team = team) and (aPlayer.Role = role ) then
      lstRole.add (aPlayer);
    end;

end;
procedure TBrain.CompileBuffedList (team: Integer; buff: Char; var lstRole: TObjectList<TPlayer> );
var
  p: integer;
  aPlayer : TPlayer;
  aList: TObjectList<TPlayer>;
  aInteractivePlayer: TInteractivePlayer;
//  aList: TList<TPlayer>;

begin
    lstRole.Clear;
    for P := Players.Count -1 downto 0 do begin
      aPlayer := Players[p];
      if buff ='D' then begin
        if (aPlayer.Team = team) and (aPlayer.BonusBuffD > 0 ) then
        lstRole.add (aPlayer);
      end;
    end;
    for P := Players.Count -1 downto 0 do begin
      aPlayer := Players[p];
      if buff ='M' then begin
        if (aPlayer.Team = team) and (aPlayer.BonusBuffM > 0 ) then
        lstRole.add (aPlayer);
      end;
    end;
    for P := Players.Count -1 downto 0 do begin
      aPlayer := Players[p];
      if buff ='F' then begin
        if (aPlayer.Team = team) and (aPlayer.BonusBuffF > 0 ) then
        lstRole.add (aPlayer);
      end;
    end;

end;
function TBrain.IsOffSide ( FromPlayer, ToPlayer : TPlayer ): Boolean;
var
  i: integer;
begin
  Result := True;
  // nella propria metacampo non è fuorigioco
  if (ToPlayer.Team = 0) and (ToPlayer.CellX <= 5) then begin
    Result := false;
    Exit;
  end
  else if (ToPlayer.Team = 1) and (ToPlayer.CellX >= 6) then  begin
    Result := false;
    Exit;
  end;

  // prima check del passaggio in sè. non è mai fuorigioco se il linea o da davanti
  if FromPlayer.Team = 0 then begin
    if FromPlayer.CellX >= ToPlayer.CellX then begin
      Result:= false;
      Exit;
    end;

  end
  else if FromPlayer.Team = 1 then begin
    if FromPlayer.CellX <= ToPlayer.CellX then begin
      Result:= false;
      Exit;
    end;

  end;


  // Cerco un avversario oltre la linea che non sia il GK
  for I := Players.Count -1 downto 0 do begin
    if IsOutSide( Players[i].CellX ,Players[i].CellY ) or (Players[i].Team  = ToPlayer.Team) then Continue;

    case ToPlayer.team of
      0: begin // qui ciclano team 1
        if (Players[i].Role  <> 'G') and (Players[i].CellX >= ToPlayer.cellX) then begin
          Result:= false;
          Exit;
        end;
      end;
      1: begin  // qui ciclano team 0
        if (Players[i].Role  <> 'G') and (Players[i].CellX <= ToPlayer.cellX)  then begin
          Result:= false;
          Exit;
        end;
      end;
    end;
  end;
end;
function TBrain.IsLastMan ( aPlayer, BallPlayer : TPlayer ): Boolean;
var
  AnotherPlayer : TPlayer;
  i: integer;
begin
  { TODO :     islastman da testare la nuova versione }
  // l'ultimo uomo è sempre oltre tutti a parte il portiere. anche in compagnia ma è l'ultima linea
  Result := True;

    if aPlayer.CellX = BallPlayer.CellX then begin // se il fallo è SIDE
      for I := Players.Count -1 downto 0 do begin
        AnotherPlayer:= Players[i];
        if (AnotherPlayer.ids = aPlayer.ids) or (AnotherPlayer.Team <> aPlayer.team ) and (AnotherPlayer.Role = 'G') then continue; // non calcolo chi fa il fallo e il team avversario
          case aPlayer.team of
            // in pratica: il fallo è di lato. Se ne trovo un altro di fianco o più arretrato non è ultimo uomo
            0: begin // qui ciclano team 0, il fallo è sel team 0
              if  AnotherPlayer.CellX <= aPlayer.cellX   then begin
                Result:= false;
                Exit;
              end;
            end;
            1: begin  // qui ciclano team 1, il fallo è sel team 1
              if AnotherPlayer.CellX >= aPlayer.cellX  then begin
                Result:= false;
                Exit;
              end;
            end;
          end;

        exit;

      end;
    end

    // se il fallo è da davanti o dietro
    else begin
      case aPlayer.team of
        0: begin // qui ciclano team 0, il fallo è sel team 0
          if aPlayer.CellX < Ball.Player.cellX then begin // fallo da davanti
            for I := Players.Count -1 downto 0 do begin
              AnotherPlayer:= Players[i];
              if (AnotherPlayer.ids = aPlayer.ids) or (AnotherPlayer.Team <> aPlayer.team ) and (AnotherPlayer.Role = 'G') then continue; // non calcolo chi fa il fallo e il team avversario
                if (AnotherPlayer.CellX <= aPlayer.cellX) or (AnotherPlayer.CellX = BallPlayer.cellX) then begin
                  Result:= false;
                  Exit;
                end;
            end;
          end
          else if aPlayer.CellX > Ball.Player.cellX then begin // fallo da dietro
            for I := Players.Count -1 downto 0 do begin
              AnotherPlayer:= Players[i];
              if (AnotherPlayer.ids = aPlayer.ids) or (AnotherPlayer.Team <> aPlayer.team ) and (AnotherPlayer.Role = 'G') then continue; // non calcolo chi fa il fallo e il team avversario
                if (AnotherPlayer.CellX <= BallPlayer.cellX) then begin
                  Result:= false;
                  Exit;
                end;
            end;

          end;
        end;
        1: begin  // qui ciclano team 1, il fallo è sel team 1
          if aPlayer.CellX > Ball.Player.cellX then begin // fallo da davanti
            for I := Players.Count -1 downto 0 do begin
              AnotherPlayer:= Players[i];
              if (AnotherPlayer.ids = aPlayer.ids) or (AnotherPlayer.Team <> aPlayer.team ) and (AnotherPlayer.Role = 'G') then continue; // non calcolo chi fa il fallo e il team avversario
                if (AnotherPlayer.CellX >= aPlayer.cellX) or (AnotherPlayer.CellX = BallPlayer.cellX) then begin
                  Result:= false;
                  Exit;
                end;
            end;
          end
          else if aPlayer.CellX < Ball.Player.cellX then begin // fallo da dietro
            for I := Players.Count -1 downto 0 do begin
              AnotherPlayer:= Players[i];
              if (AnotherPlayer.ids = aPlayer.ids) or (AnotherPlayer.Team <> aPlayer.team ) and (AnotherPlayer.Role = 'G') then continue; // non calcolo chi fa il fallo e il team avversario
                if (AnotherPlayer.CellX >= BallPlayer.cellX) then begin
                  Result:= false;
                  Exit;
                end;
            end;

          end;
        end;
      end;
    end;

end;
function TBrain.AllowCount ( team: Integer ): Integer;
var
  i: Integer;
  redcard: Integer;
begin
  redcard:=0;
  for I := Players.Count -1 downto 0 do begin
    if (Players[i].RedCard > 0 ) and  (Players[i].Team = team) then
      redcard := redcard +1;
  end;
  Result := 11 - redcard;

end;
function TBrain.CurrentCount ( team: Integer ): Integer;
var
  i: Integer;
  count: Integer;
begin
  count:=0;
  for I := Players.Count -1 downto 0 do begin
    if not IsOutSide( Players[i].cellx,Players[i].celly  ) and  (Players[i].Team = team) then
      count := count +1;
  end;
  Result := count;

end;
function TBrain.CanDoSub ( team: Integer ): boolean;
var
  i: Integer;
begin
  Result := false;
  if Score.TeamSubs[team] < 3 then begin
    for I := Reserves.Count -1 downto 0 do begin
      if (Reserves[i].Team = team) and ( Reserves[i].disqualified = 0) and ( Reserves[i].injured = 0)
      and (Reserves[i].TalentId1 <> TALENT_ID_GOALKEEPER) and (Reserves[i].Stamina > 60) then begin
        Result:= True;
        exit;
      end;
    end;
  end;
end;

function TBrain.GetTackleDirection ( Team, StartX, StartY, ToX, ToY: Integer): TTackleDirection;
begin
  case Team of
    0: begin
      if StartX > ToX then
        Result := TackleBack
        else if StartX < ToX then
             Result := TackleAhead
          else if StartX = ToX then
               Result := TackleSide;
    end;
    1: begin
      if StartX < ToX then
        Result := TackleBack
        else if StartX > ToX then
             Result := TackleAhead
          else if StartX = ToX then
               Result := TackleSide;
    end;
  end;
end;
procedure TBrain.GetNextDirectionCell ( StartX, StartY, ToX, ToY, Speed,Team: integer; FriendlyWall,OpponentWall: boolean;  var aPath: dse_pathplanner.TPath  );
var
  MoveModeX: TMoveModeX;
  MoveModeY: TMoveModeY;
  aStep: dse_pathplanner.TPathStep;
  i: integer;
  aPlayer: TPlayer;
begin
  aPath.Clear ;
  MoveModeX := xNone;
  MoveModeY := yNone;

  if StartX < Tox then
    MoveModeX := LeftToRight
    else if StartX > Tox then
      MoveModeX := RightToLeft
    else if StartX = Tox then
      MoveModeX := XNone;

  if StartY < ToY then
    MoveModeY := UpToDown
    else if StartY > ToY then
      MoveModeY := DownToUp
    else if StartY = ToY then
      MoveModeY := YNone;

  if (MoveModeX = LeftToRight) and ( MoveModeY  = YNone) then begin
    for I := 1 to Speed do begin
      aStep:= dse_pathplanner.TPathStep.Create(ToX+i, ToY);
      aPath.add(aStep);
    end;
  end
  else if (MoveModeX = LeftToRight) and ( MoveModeY  = UpToDown) then begin
    for I := 1 to Speed do begin
      aStep:= dse_pathplanner.TPathStep.Create(ToX +1, ToY + i);
      aPath.add(aStep);
    end;
  end
  else if (MoveModeX = LeftToRight) and ( MoveModeY  = DownToUp) then begin
    for I := 1 to Speed do begin
      aStep:= dse_pathplanner.TPathStep.Create(ToX +1, ToY - i);
      aPath.add(aStep);
    end;
  end
  else if (MoveModeX = RightToLeft) and ( MoveModeY  = YNone) then begin
    for I := 1 to Speed do begin
      aStep:= dse_pathplanner.TPathStep.Create(ToX-i, ToY);
      aPath.add(aStep);
    end;
  end
  else if (MoveModeX = RightToLeft) and ( MoveModeY  = UpToDown) then begin
    for I := 1 to Speed do begin
      aStep:= dse_pathplanner.TPathStep.Create(ToX - i, ToY + i);
      aPath.add(aStep);
    end;
  end
  else if (MoveModeX = RightToLeft) and ( MoveModeY  = DownToUp) then begin
    for I := 1 to Speed do begin
      aStep:= dse_pathplanner.TPathStep.Create(ToX -i , ToY - i);
      aPath.add(aStep);
    end;
  end
  else if (MoveModeX = Xnone) and ( MoveModeY  = UpToDown) then begin
    for I := 1 to Speed do begin
      aStep:= dse_pathplanner.TPathStep.Create(ToX , ToY + i);
      aPath.add(aStep);
    end;
  end
  else if (MoveModeX = Xnone) and ( MoveModeY  = DownToUp) then begin
    for I := 1 to Speed do begin
      aStep:= dse_pathplanner.TPathStep.Create(ToX , ToY - i);
      aPath.add(aStep);
    end;
  end;


  // elimino celle non nel campo e contenenti player
  for I := aPath.Count -1 downto 0 do begin
    if (aPath[i].X < 1) or  (aPath[i].X > 10) or (aPath[i].Y < 0) or  (aPath[i].Y > 6) then  begin
        aPath.Steps.Delete(i);
        continue;
    end;

    aPlayer := geTPlayer ( aPath[i].X, aPath[i].Y);
    if  aPlayer <> nil then begin

      if FriendlyWall then begin
        if aPlayer.Team = Team then begin
          aPath.Steps.Delete(i);
           continue;
        end;
      end;
      if OpponentWall then begin
        if aPlayer.Team <> Team then begin
          aPath.Steps.Delete(i);
           continue;
        end;
      end;

    end;
  end;

end;
function TBrain.GetGKBounceCell ( GoalKeeper: TPlayer; GKX, GKY, Speed: integer; AllowCorner: boolean ): Tpoint;
var
  acellList: Tlist<TPoint>;
  aPoint: Tpoint;
  i,aRnd: integer;
  label NoCorner0, noCorner1;
begin
  // procedura valida solo per parata nella DoorCell
  i:= Speed;

  if (GoalKeeper.Team = 0) and (GKX = 0) and (GKY=3) then begin

      acellList:= Tlist<TPoint>.Create;
      if AllowCorner = false then goto NoCorner0;

      aRnd := RndGenerate (100);
      if aRnd <= 75 then begin   // corner   75% corner

          aPoint.X := GKX; aPoint.Y:= GKY-1;
          AcellList.Add(aPoint);
          aPoint.X := GKX; aPoint.Y:= GKY+1;
          AcellList.Add(aPoint);
          aPoint.X := GKX; aPoint.Y:= GKY-2;
          AcellList.Add(aPoint);
          aPoint.X := GKX; aPoint.Y:= GKY+2;
          AcellList.Add(aPoint);
          aRnd := RndGenerate0 (aCellList.Count -1);
          Result.X := aCellList[aRnd].X;
          Result.Y := aCellList[aRnd].Y;
          aCellList.Free;
      end

      else Begin
NoCorner0:
        while I > 0 do begin    // rimbalzo

          aPoint.X := GKX+i; aPoint.Y:= GKY-i;
          AcellList.Add(aPoint);
          aPoint.X := GKX+i; aPoint.Y:= GKY;
          AcellList.Add(aPoint);
          aPoint.X := GKX+i; aPoint.Y:= GKY+i;
          AcellList.Add(aPoint);

          dec(i);
        end;

          aRnd := RndGenerate0 (aCellList.Count -1);
          Result.X := aCellList[aRnd].X;
          Result.Y := aCellList[aRnd].Y;
          aCellList.Free;

      end;

  end
  else if (GoalKeeper.Team = 1) and (GKX = 11) and (GKY=3) then begin


      acellList:= Tlist<TPoint>.Create;
      if AllowCorner = false then goto NoCorner1;
      aRnd := RndGenerate (100);
      if aRnd <= 50 then begin   // corner


          aPoint.X := GKX; aPoint.Y:= GKY-1;
          AcellList.Add(aPoint);
          aPoint.X := GKX; aPoint.Y:= GKY+1;
          AcellList.Add(aPoint);
          aPoint.X := GKX; aPoint.Y:= GKY-2;
          AcellList.Add(aPoint);
          aPoint.X := GKX; aPoint.Y:= GKY+2;
          AcellList.Add(aPoint);
          aRnd := RndGenerate0 (aCellList.Count -1);
          Result.X := aCellList[aRnd].X;
          Result.Y := aCellList[aRnd].Y;
          aCellList.Free;
      end

      else Begin
NoCorner1:

        while I > 0 do begin    // rimbalzo

          aPoint.X := GKX-i; aPoint.Y:= GKY-i;
          AcellList.Add(aPoint);
          aPoint.X := GKX-i; aPoint.Y:= GKY;
          AcellList.Add(aPoint);
          aPoint.X := GKX-i; aPoint.Y:= GKY+i;
          AcellList.Add(aPoint);

          dec(i);
        end;

          aRnd := RndGenerate0 (aCellList.Count -1);
          Result.X := aCellList[aRnd].X;
          Result.Y := aCellList[aRnd].Y;
          aCellList.Free;

      end;
  end;
end;
function TBrain.GetBounceCell ( StartX, StartY, ToX, ToY, Speed: integer; favourTeam : integer): TPoint;
var
  MoveModeX: TMoveModeX;
  MoveModeY: TMoveModeY;
  NewX, NewY: integer;
  label retryx1, retryx2,retryy1, retryy2;
begin

  if StartX < Tox then
    MoveModeX := LeftToRight
    else if StartX > Tox then
      MoveModeX := RightToLeft
    else if StartX = Tox then
      MoveModeX := XNone;

  if StartY < ToY then
    MoveModeY := UpToDown
    else if StartY > ToY then
      MoveModeY := DownToUp
    else if StartY = ToY then
      MoveModeY := YNone;



  retryy1:
          NewY := ToY + RndGenerate (3) -2 ;
          if (NewY < 0) or (NewY > 6) then goto retryy1;
    case FavourTeam of
      0: begin
          NewX :=  ToX + Speed;
          While NewX > 10 do begin    // se rimbalza a 11 è fuori o sul portiere. non permesso
            Dec (NewX);
          end;
          Result := Point(NewX, NewY);
         end;
      1: begin
          NewX :=  ToX - Speed;
          While NewX <= 0 do begin
            Inc (NewX);
          end;
          Result := Point(NewX, NewY);
         end;
    end;



end;
function TBrain.GetZone ( Team, CellX, CellY: integer ): String;
begin
  case CellX of
    0: begin
      if Team = 0 then Result := 'P' else result := 'A';
    end;
    1..3: begin
      if Team = 0 then Result := 'D' else result := 'A';
    end;
    4..7: begin
      result := 'M';
    end;
    8..10: begin
      if Team = 0 then Result := 'A' else result := 'D';
    end;
    11: begin
      if Team = 0 then Result := 'A' else result := 'P';
    end;
  end;

end;
procedure TBrain.GetNeighbournsCells ( CellX, CellY, Speed: integer; NoPlayer,noOutSide,noGK: boolean; var aCellList:Tlist<TPoint> );
var
  aPoint: Tpoint;
  i: integer;
  x,y: Integer;
begin

  for x := 0 to 11 do begin
    for y := 0 to 6 do begin
      if (AbsDistance(CellX,CellY,X,Y) <= Speed) and (Speed > 0)  then begin // non sè setsso
        aPoint.X := x; aPoint.Y:= y;
        AcellList.Add(aPoint);
      end;
    end;
  end;

  if aCellList.count > 0 then begin
  //elimino i fuori campo
    For I := aCellList.Count -1 downto 0 do begin
      // 1 w 10, la linea 0-11 è quella della porta
      if NoPlayer then begin   // elimino i player
      if geTPlayer ( aCellList[i].X, aCellList[i].Y) <> nil then
        begin
          aCellList.Delete(i);
          continue;
        end;
      end;
      if NoOutSide then begin   // elimino 0 e 11 non portiere.
      if IsOutSide( aCellList[i].X, aCellList[i].Y)  then
        begin
          aCellList.Delete(i);
          continue;
        end;
      end;
      if noGK then begin   // al portiere posso passare. il lop no però
      if IsGKCell( aCellList[i].X, aCellList[i].Y)  then
        begin
          aCellList.Delete(i);
          continue;
        end;
      end;

      if (aCellList[i].X = CellX) and (aCellList[i].Y = CellY) then   // non sè stessa
          aCellList.Delete(i);

    end;



  end

end;
function TBrain.GetRandomCell ( CellX, CellY, Speed: integer; NoPlayer, NoOutSide: boolean ): Tpoint;
var
  acellList: Tlist<TPoint>;
  aPoint: Tpoint;
  i,x,y,aRnd: integer;
begin

  result.x := -1;
  acellList:= Tlist<TPoint>.Create;


  for x := 0 to 11 do begin
    for y := 0 to 6 do begin
      if AbsDistance(CellX,CellY,X,Y) <= Speed then begin
        aPoint.X := x; aPoint.Y:= y;
    AcellList.Add(aPoint);
      end;
    end;
  end;

  if aCellList.count > 0 then begin
  //elimino i fuori campo
    For I := aCellList.Count -1 downto 0 do begin
      // 1 w 10, la linea 0-11 è quella della porta


      if NoPlayer then begin   // elimino i player
      if geTPlayer ( aCellList[i].X, aCellList[i].Y) <> nil then
        begin
          aCellList.Delete(i);
          continue;
        end;
      end;
      if NoOutSide then begin   // elimino 0 e 11 non portiere
      if IsOutSide( aCellList[i].X, aCellList[i].Y)  then
        begin
          aCellList.Delete(i);
          continue;
        end;
      end;

      if (aCellList[i].X = CellX) and ( aCellList[i].Y = CellY)  then  // elimino sè stessa
        aCellList.Delete(i);

    end;

  end
  else result.X := -1;

  if aCellList.count > 0 then begin
    aRnd := RndGenerate0 (aCellList.Count -1);
    Result.X := aCellList[aRnd].X;
    Result.Y := aCellList[aRnd].Y;
  end;

  aCellList.Free;
end;
function TBrain.GetRandomCellNO06 ( CellX, CellY, Speed: integer  ): Tpoint;
var
  acellList: Tlist<TPoint>;
  aPoint: Tpoint;
  x,y,aRnd: integer;
begin

  result.x := -1;
  acellList:= Tlist<TPoint>.Create;
  // noplayer per forza. per forza in campo, diversa da 0 e 6

  for x := 1 to 10 do begin   // in campo
    for y := 1 to 5 do begin  // 0 6
      if (CellX = X) and (CellY=Y) then continue; // non sè stessa

      if (AbsDistance(CellX,CellY,X,Y) <= Speed) and (geTPlayer(x,y)=nil) then begin
        aPoint.X := x; aPoint.Y:= y;
        AcellList.Add(aPoint);
      end;
    end;
  end;


  if aCellList.count > 0 then begin
    aRnd := RndGenerate0 (aCellList.Count -1);
    Result.X := aCellList[aRnd].X;
    Result.Y := aCellList[aRnd].Y;
  end;

  aCellList.Free;
end;
function TBrain.GetRandomCellNOPlayer ( CellX, CellY, Speed: integer  ): Tpoint;
var
  acellList: Tlist<TPoint>;
  aPoint: Tpoint;
  x,y,aRnd: integer;
begin

  result.x := -1;
  acellList:= Tlist<TPoint>.Create;
  // noplayer per forza. per forza in campo, diversa da 0 e 6

  for x := 1 to 10 do begin   // in campo
    for y := 0 to 6 do begin  // tutte
      if (CellX = X) and (CellY=Y) then continue; // non sè stessa

      if (AbsDistance(CellX,CellY,X,Y) <= Speed) and (geTPlayer(x,y)=nil) then begin
        aPoint.X := x; aPoint.Y:= y;
        AcellList.Add(aPoint);
      end;
    end;
  end;


  if aCellList.count > 0 then begin
    aRnd := RndGenerate0 (aCellList.Count -1);
    Result.X := aCellList[aRnd].X;
    Result.Y := aCellList[aRnd].Y;
  end;

  aCellList.Free;
end;
procedure TBrain.GetMarkingPath ( aPlayer: TPlayer );
var
  aMagnete: TPlayer;
begin
   { talento  MARKING MAGNETE  trova uno tra questi nella sua ZONE : se non ci è già vicino a 1 D=shot pià alto M=Passing+alto F=Defense+bassa
      getaggressionCell del best nella zone. spendono pià a correre speed
    }
  if aPlayer.ZoneRole = aPlayer.role then begin   // dove mi trovo ora e quale è il mio ruolo devono coincidere
    if aPlayer.Role = 'D' then begin // un D cerca un F avversario: il bestshot. lo cerca solo nella zone 0 o 1 (dipende dal team)
      if aPlayer.Team = 0 then
        aMagnete := getBestShotZone (1 , 'F' ) // team avversario, role zone
        else
        aMagnete := getBestShotZone (0 , 'F')
    end
    else if aPlayer.Role = 'M' then begin // un M cerca un M avversario: il bestPassing. lo cerca solo nella zone 2
      if aPlayer.Team = 0 then
        aMagnete := getBestPassingZone (1 , 'M') // team avversario, role zone
        else
        aMagnete := getBestPassingZone (0 , 'M')

    end
    else if aPlayer.Role = 'F' then begin // un D cerca un F avversario: il worst BallControl. lo cerca solo nella zone 0 o 1 (dipende dal team)
      if aPlayer.Team = 0 then
        aMagnete := GetWorstBallControlZone(1 , 'D') // team avversario, role zone
        else
        aMagnete := GetWorstBallControlZone (0 , 'D')
    end;

    if aMagnete <> nil then
      GetAggressionCellPath( aPlayer, aMagnete.CellX, aMagnete.CellY ); // cerco la cella di aggression
  end;
end;
procedure TBrain.GetAggressionCellPath ( aSoccerPlayer: TPlayer; X2, Y2: integer );
var
  acellList: Tlist<TPoint>;
  aPoint: Tpoint;
  label exitpath;
begin
  // cerca una cella adiacente a X2 Y2.
  aSoccerPlayer.MovePath.Clear;
  // una Nearest Cell è per forza una cella vuota
  // non aggiungo i fuoricampo
  acellList:= Tlist<TPoint>.Create;
  aPoint.X := X2-1; aPoint.Y:= Y2-1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2;   aPoint.Y:= Y2-1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2+1; aPoint.Y:= Y2-1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2-1; aPoint.Y:= Y2;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);
  //aPoint.X := X2;   aPoint.Y:= Y2;
  //AcellList.Add(aPoint);
  aPoint.X := X2+1; aPoint.Y:= Y2;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2-1; aPoint.Y:= Y2+1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2;   aPoint.Y:= Y2+1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2+1; aPoint.Y:= Y2+1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  if aCellList.Count > 0 then begin

  // A questo punto ho possibili nearest cells
  // quella con la X più bassa ( se team 0) o X più alta ( se team 1 ) è la migliore
    if aSoccerPlayer.Team = 0 then
      aCellList.sort(TComparer<TPoint>.Construct(
      function (const L, R: Tpoint): integer
      begin
        Result := L.X - R.X;
      end
     ))
    else
      aCellList.sort(TComparer<TPoint>.Construct(
      function (const L, R: Tpoint): integer
      begin
        Result := R.X - L.X;
      end
     ));

    GetPath (aSoccerPlayer.Team, aSoccerPlayer.CellX ,aSoccerPlayer.Celly,
    aCellList[0].X, aCellList[0].Y, aSoccerPlayer.Speed{Limit},
    aSoccerPlayer.Flank <> 0{useFlank}, false, false,true ,TruncOneDir{OneDir},aSoccerPlayer.MovePath ); // false FinalWall

  end;

  acellList.Free;


end;
procedure TBrain.GetFavourCellPath ( aSoccerPlayer: TPlayer; X2, Y2: integer );
var
  acellList: Tlist<TPoint>;
  aPoint: Tpoint;
  label exitpath;
begin

  aSoccerPlayer.MovePath.Clear;
  // una Nearest Cell è per forza una cella vuota
  // non aggiungo i fuoricampo
  acellList:= Tlist<TPoint>.Create;
  aPoint.X := X2-1; aPoint.Y:= Y2-1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2;   aPoint.Y:= Y2-1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2+1; aPoint.Y:= Y2-1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2-1; aPoint.Y:= Y2;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);
  //aPoint.X := X2;   aPoint.Y:= Y2;
  //AcellList.Add(aPoint);
  aPoint.X := X2+1; aPoint.Y:= Y2;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2-1; aPoint.Y:= Y2+1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2;   aPoint.Y:= Y2+1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  aPoint.X := X2+1; aPoint.Y:= Y2+1;
  if (aPoint.X > 0) and (aPoint.X <=10) and (GeTPlayer (aPoint.X, aPoint.Y ) = nil )
  and (aPoint.Y >= 0) and (aPoint.y <=6)
  then AcellList.Add(aPoint);

  if aCellList.Count > 0 then begin

  // A questo punto ho possibili nearest cells
  // quella con la X più alta ( se team 0) o X più bassa ( se team 1 ) è la migliore
    if aSoccerPlayer.Team = 0 then
      aCellList.sort(TComparer<TPoint>.Construct(
      function (const L, R: Tpoint): integer
      begin
        Result := R.X - L.X;
      end
     ))
    else
      aCellList.sort(TComparer<TPoint>.Construct(
      function (const L, R: Tpoint): integer
      begin
        Result := L.X - R.X;
      end
     ));

    GetPath (aSoccerPlayer.Team, aSoccerPlayer.CellX ,aSoccerPlayer.Celly,
    aCellList[0].X, aCellList[0].Y, aSoccerPlayer.Speed{Limit},
    aSoccerPlayer.Flank <> 0{useFlank}, false, false,true ,TruncOneDir{OneDir},aSoccerPlayer.MovePath ); // false FinalWall

  end;

  acellList.Free;


end;

procedure TBrain.CopyPath ( Path1, Path2 : dse_pathplanner.TPath );
var
  i: Integer;
  aStep : dse_pathplanner.TPathStep;
begin
  Path2.Clear;
  for I := 0 to Path1.Count -1 do begin
    aStep := TPathStep.Create( Path1.Step[i].X, Path1.Step[i].Y );
    Path2.Add( aStep );
  end;

end;


constructor TBrain.Create ( ids : string; AGender: Char; aSeason, aCountry, aDivision, aRound: integer);
var
  i: Integer;
begin
  // Roll random da 1 a 4. le stat dei player vanno da 1 a 6.
  // Roll random da 1 a 6. le stat dei player vanno da 1 a 10. max 4 speed

  debug_TACKLE_FAILED := false;
  debug_SETFAULT := false;
  debug_SETRED := false;
  debug_SetAlwaysGol := false;
  debug_Setposcrosscorner := false;
  debug_Buff100 := false;

  Season := ASeason;
  Gender := AGender;
  Division := aDivision;
  Country := aCountry;
  Round := aRound;

  PlayersALL := TObjectList<TPlayer>.create(True);
  Players := TObjectList<TPlayer>.create(false);
  Reserves:= TObjectList<TPlayer>.create(false);
  Gameover:= TObjectList<TPlayer>.create(false);
  Finished:= false;
  FinishedTime:=0;
  RandGen := TtdCombinedPRNG.Create(0, 0);
  MatchInfo:= TStringList.Create; // minuto, tipo evento (gol,card,subs), ids1, ids2 , opzional(freeKick,penalty)
  AI_GCD := 5000;// tanto per partire
  utime := False;
  LastTickCount := GetTickCount;
  lstSpectator:= TList<Integer>.Create ;
  //GetModuleFileName(HInstance, szDllName, SizeOf(szDllName)-1);
  //sDllName:= StrPas(szDllName) ;
  BrainIDS:= ids;
  incMove := 0;
  MMbraindata:= TMemoryStream.Create;
  MMbraindataZIP:= TMemoryStream.Create ;
//  MMbraindata.SetSize(300);
  ExceptPlayers:= TObjectList<TPlayer>.Create(false);
  ShpFree:=1;
  Minute:= 1;
  TeamTurn:=0;
  GameStarted:= false;
//  BonusDefenseShots := -1;
  ToEmptyCellBonusDefending := 1;

  TsErrorLog:= TstringList.Create ;


    tsSpeaker:= TstringList.Create ;
    for I := 0 to 255 do begin
      tsScript[i]:= TstringList.Create ;
    end;
    TeamMovesLeft := TurnMovesStart;

  SoccerAI := TSoccerAI.create(self);

  inherited Create;
end;
destructor TBrain.destroy;
var
      i: integer;
begin
    ball.free;
    randGen.free;
    //ShotCells := nil;
    TsErrorLog.free;

    //AICrossingAreaCells.Free;
    //TVCrossingAreaCells.Free;
    lstSpectator.free;
    tsSpeaker.free ;
    for I := 0 to 255 do begin
      tsScript[i].free ;
    end;
    ExceptPlayers.Free;
    MMbraindata.Free;
    MMbraindataZIP.Free;
    MatchInfo.Free;
    Gameover.Free;
    Players.Free;
    Reserves.Free;
    PlayersALL.Free;
    SoccerAI.Free;
  inherited ;
end;
procedure TBrain.SetDirLog ( value: string );
begin
  fDir_Log := value;
  //FileCreate( dir_log +  brainIds + '.ERR' );

end;
procedure TBrain.Start;
var
  i: integer;
begin
  for I := 0 to 255 do begin
    tsScript[i].Clear ;
  end;
  tsSpeaker.Clear ;
  FTeamMovesLeft := TurnMovesStart;
  GameStarted:= true;
  ExceptPlayers.Clear ;
  ShpFree:=1;
  Minute:= 1;
  TeamTurn:=0;
  FlagEndGame := false;
  fmilliseconds := Turnmilliseconds;
  Finished:= false;
  FinishedTime:=0;
end;
procedure TBrain.LoadDefaultTeamPos ( aTeam: integer);
var
  i: integer;
begin
  // Dopo un gol annullo anche tutti gli stay/free

  for I := Players.Count -1 downto 0 do begin
    Players[i].CellX := Players[i].DefaultCellX ;
    Players[i].CellY := Players[i].DefaultCellY ;
    Players[i].stay := False;
  end;
   case aTeam of
    0: begin
        ball.CellX := 5;
        ball.CellY := 3;
       end;
    1: begin
        ball.CellX := 6;
        ball.CellY := 3;
       end;
   end;

end;


procedure TBrain.CornerSetup ( const aPlayer: TPlayer );
var
  CornerMap: TCornerMap;
begin
//il corner lo rifaccio COF, COHA3 tutto un input minimo 1 cof r 1 coha
//poi i 3 COHD
  CornerMap := GetCorner ( aPlayer.Team , Ball.CellY, OpponentCorner );
  Ball.CellX := CornerMap.CornerCell.X;
  Ball.CellY := CornerMap.CornerCell.Y;

  {$IFDEF ADDITIONAL_MATCHINFO}
  if GameMode = pvp then
    MatchInfo.Add( IntToStr(fminute) + '.corner.' + aPlayer.ids)
    else MatchInfo.Add( IntToStr(fminute) + '.corner.' + aPlayer.ids+'.'+ aPlayer.SurName);
  {$ENDIF}

  // da settemamovesleft. qui deve essere piazzato chi calcia il corner
  TeamTurn := aPlayer.Team ;
  TeamCorner := CornerMap.Team;

  ResetPassiveSkills;

  fmilliseconds := Turnmilliseconds;
  TsScript[incMove].add ('sc_TUC,' + intTostr(TeamTurn) ) ;
  fTeamMovesLeft := 3; // il cof non utilizza teammovesleft
  TsScript[incMove].add ('sc_CORNER.COA,' + intTostr(TeamTurn) + ',' + IntTostr( CornerMap.CornerCell.X) +','+IntTostr( CornerMap.CornerCell.Y) ) ; // richiesta al client corner free kick
  TsScript[incMove].add ('E') ;

  // da settemamovesleft. qui deve essere piazzato chi calcia il corner
  w_CornerSetup:= true;
  w_coa :=true;
  w_cod :=false;
end;
procedure TBrain.FreeKickSetup1 ( team : Integer  );
var
  aCellList: TList<TPoint>;
  i,p,MinDist,aRnd: Integer;
  anOpponent: TPlayer;
begin
  w_FreeKickSetup1 := True;
  // allontano di 2 celle gli avversari
  ResetPassiveSkills;
  // prendo tutti i player avversari a distanza < 2 dalla palla, quindi quelli che devono spostarsi

  for p := Players.Count -1 downto 0 do begin
  // per ogni calciatore avversario che si trovano a distanza < 2 dalla palla, prendo tutte le celle libere in cui può andare
    anOpponent := Players[p] ;
    if (anOpponent.Team = team ) or (anOpponent.Role='G') then Continue;

    if AbsDistance(anOpponent.CellX, anOpponent.CellY, ball.CellX, ball.CellY ) < 2 then begin


      aCellList:= TList<TPoint>.Create;
      GetNeighbournsCells( Ball.CellX,Ball.cellX, 12,true,true , True,aCellList); // noplayer,noOutside

      // elimino le Celle a distanza < 2 dalla palla
      for I := aCellList.Count -1 downto 0 do begin
        if AbsDistance(Ball.CellX, Ball.CellY, aCellList[i].X, aCellList[i].Y ) < 2 then
          aCellList.Delete(i);
      end;
      // le celle rimaste sono quelle in cui può andare. Le ordino per distanza tra la palla a partire da quella più vicina (2 distanza)
      // si potrebbe anche fare a distanza 1 dal player attuale

      // L - R  minimo qui ho celle distanza 2,3,4,5,6  in quanto sono già state eliminate sopra . le ordino per distanza
      aCellList.sort(TComparer<TPoint>.Construct(
      function (const L, R: TPoint): integer
      begin
        Result := AbsDistance( Ball.CellX, Ball.CellY, L.X, L.Y )  -
        AbsDistance( Ball.CellX, Ball.CellY, R.X, R.Y )
      end
         ));
      //  tra tutte devo scegliere quelle verso la porta che difendo. Quindi prenso la MinDist , elimino le altre. di nuovo sort per cellX in base al team
      MinDist := AbsDistance( Ball.CellX, Ball.CellY, aCellList[0].X, aCellList[0].Y);

        for i := aCellList.Count -1 downto 0 do begin
          if AbsDistance( Ball.CellX, Ball.CellY, aCellList[i].X, aCellList[i].Y) > MinDist then
            aCellList.Delete(i);
        end;
      // a questo punto ho celle vuote tutte a presumibilmente distanza 2, o anche 3 se non erano libere (caso raro)
      // prendo quelle per convenienza difensiva usando CellX e Team    . il valore più alto : r-l , più basso l-r
      aCellList.sort(TComparer<TPoint>.Construct(
      function (const L, R: TPoint): integer
      begin
        Result := L.X - R.X;
      end
         ));
      // tra queste a distanza 2 presumnibile ne estraggo una random
      aRnd := RndGenerate0(aCellList.Count-1);
      TsScript[incMove].add ('sc_player,'+ anOpponent.Ids +','+IntTostr(anOpponent.CellX)+','+ IntTostr(anOpponent.CellY)+','+
      IntTostr(aCellList[aRnd].X)+','+ IntTostr(aCellList[aRnd].Y)  ) ;
      anOpponent.Cells := Point(aCellList[aRnd].X, aCellList[aRnd].Y);

      aCellList.free;
    end;
  end;

  // non faccio il turnchange perchè il fallo può essere anche durante la mia azione
  TeamTurn := Team ;
  TeamFreeKick := TeamTurn ;
  TsScript[incMove].add ('sc_TUC,' + intTostr(TeamTurn) ) ;
  fTeamMovesLeft := TurnMoves;
  fmilliseconds := Turnmilliseconds;
//  TurnChange(TurnMoves); // 4
  {$IFDEF ADDITIONAL_MATCHINFO}

    MatchInfo.Add( IntToStr(fminute) + '.freekick1.' + IntToStr(team));
  {$ENDIF}
  TsScript[incMove].add ('sc_FREEKICK1.FKA1,' + IntTostr(Team) + ',' +  IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client che si può proseguire
  TsScript[incMove].add ('E') ;

  // da settemamovesleft. qui deve essere piazzato chi calcia il corner
  w_FreeKickSetup1:= true;
  w_Fka1 :=true;
end;
procedure TBrain.FreeKickSetup2 ( team : Integer  );
begin

  ResetPassiveSkills;
  TeamTurn := Team ;
  TeamFreeKick := TeamTurn ;
  TsScript[incMove].add ('sc_TUC,' + intTostr(TeamTurn) ) ;
  fTeamMovesLeft := TurnMoves;
  fmilliseconds := Turnmilliseconds;

  {$IFDEF ADDITIONAL_MATCHINFO}  MatchInfo.Add( IntToStr(fminute) + '.freekick2.' + IntToStr( team));{$ENDIF}
  TsScript[incMove].add ('sc_FREEKICK2.FKA2,' + IntTostr(Team) + ',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // richiesta al client corner free kick
  TsScript[incMove].add ('E') ;

  // da settemamovesleft. qui deve essere piazzato chi calcia il corner
  w_FreeKickSetup2:= true;
  w_Fka2 :=true;
  w_Fkd2 :=false;
end;
procedure TBrain.FreeKickSetup3 ( team : Integer  );
begin
  // il prs o pos che seguirà mantiene le shotcell. il malus è minore. il difensore può mettere fino a 4 in barriera. esiste una cella
  // specifica di barriera per ogni shotCell. l'animazione prevede che dopo il pos o prs con flag freekick3 veda gli uomini in barriera
  // raggiungere celle libere. Qui nel setup non devo liberare nulla, ma devo farlo dopo.
  ResetPassiveSkills;
  TeamTurn := Team ;
  TeamFreeKick := TeamTurn ;
  TsScript[incMove].add ('sc_TUC,' + intTostr(TeamTurn) ) ;
  fmilliseconds := Turnmilliseconds;

  fTeamMovesLeft := 2; // il pos o prs utilizza teammovesleft
  {$IFDEF ADDITIONAL_MATCHINFO}  MatchInfo.Add( IntToStr(fminute) + '.freekick3.' + IntToStr( team));{$ENDIF}
  TsScript[incMove].add ('sc_FREEKICK3.FKA3,'  + IntTostr(Team) + ',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // richiesta al client corner free kick
  TsScript[incMove].add ('E') ;

  // da settemamovesleft. qui deve essere piazzato chi calcia il corner
  w_FreeKickSetup3:= true;
  w_Fka3 :=true;
  w_Fkd3 :=false;
end;
procedure TBrain.FreeKickSetup4 ( team : Integer  );
begin
  { devo mettere tutti fuori dall'area e dietro la palla }
  ResetPassiveSkills;
  FreePenaltyArea ( team );

  fmilliseconds := Turnmilliseconds;
  TeamTurn := Team ;
  TeamFreeKick := TeamTurn ;
  TsScript[incMove].add ('sc_TUC,' + intTostr(TeamTurn) ) ;
  fTeamMovesLeft := 2; // il pos o prs non utilizza teammovesleft
  {$IFDEF ADDITIONAL_MATCHINFO}  MatchInfo.Add( IntToStr(fminute) + '.freekick4.' + IntToStr( team));{$ENDIF}
  TsScript[incMove].add ('sc_FREEKICK4.FKA4,'  + IntTostr(Team) + ',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // richiesta al client corner free kick
  TsScript[incMove].add ('E') ;

  // da settemamovesleft. qui deve essere piazzato chi calcia il penalty
  w_FreeKickSetup4:= true;
  w_Fka4 :=true;
end;
function TBrain.GetW_SomeThing: boolean;
begin

  Result := w_CornerSetup or w_Coa or w_cod or w_CornerKick or w_Fka1 or w_Fka2 or w_FreeKickSetup2 or w_Fka2 or w_Fkd2 or w_FreeKick2
  or w_FreeKickSetup3 or w_Fka3 or w_Fkd3 or w_FreeKick3 or w_Fka4 or w_FreeKickSetup4 or w_FreeKick4;

end;

procedure TBrain.SetTeamMovesLeft ( const Value: ShortInt );
var
  P,T: integer;
  aList: TObjectList<TPlayer>;
  aPlayer: TPlayer;
  label noCheckCheat;
begin
   UpdateDevi;

   FTeamMovesLeft := value;
   if FTeamMovesLeft < 0 then
    FTeamMovesLeft := 0;

   if GameStarted then begin
      TsScript[incMove].add ('sc_TML,' + IntTostr(FTeamMovesLeft) + ',' + IntTostr(TeamTurn) + ',' + IntToStr(ShpFree) ) ;
      Minute := Minute + 1;


      if Minute >= 120 then begin
        if Not W_Something then  // potrebbe andare avanti all'infinito a forza di falli. forse minute e incmove vanno messi a smallint
          FlagEndGame := True // le sostituzioni non incrementano i minuti
          else FlagEndGame := false; // in caso di freekick non finisce la partita
      end
      else FlagEndGame := false;
   end;

   // solo se non ha la palla
   for P := Players.Count -1 downto 0 do begin
     aPlayer := Players[P];
     if IsOutSide( aPlayer.CellX ,aPlayer.CellY )  then Continue;
     if not aPlayer.HasBall  then begin
      aPlayer.resetAll;
      if aPlayer.PressingDone then begin
        aPlayer.CanMove:= False;
        aPlayer.CanSkill:= True;
      end;

      aPlayer.Speed := aPlayer.DefaultSpeed;
      aPlayer.Defense := aPlayer.DefaultDefense;
      aPlayer.BonusBuffD := 0;
      aPlayer.BonusBuffM := 0;
      aPlayer.BonusBuffF := 0;


     end;

   end;

  // qui aggiungo i buff per i 3 reparti. tutti i player sono resettati sopra ed eventualmente hanno già i buff semplici
  for T := 0 to 1 do begin

    // TALENT_ID_BUFF_DEFENSE = 139 prereq almeno 3 Defense, 1 talento qualsiasi --> skill 2x buff reparto (5% chance) dif 20 turni + def,ballcontrol,passing +1

//    Il resetAll sopra ha resettato tutto, ma non il portatore di palla
    // a differenza di quelli del morale, questi buff vanno oltre MAX_STAT
    if Score.BuffD[T] > 0 then begin
        // cerco il reparto e buff
        aList := TObjectList<TPlayer>.create(false);
        CompileRoleList(T,'D', aList);
        for p := aList.Count -1 downto 0 do begin
          if aList[p].HasBall then continue;   // il portatore di palla non è stato resettato sopra
          aList[p].BonusBuffD := 1;
          aList[p].Defense := aList[p].Defense + 1;
          aList[p].BallControl := aList[p].BallControl + 1;
          aList[p].Passing := aList[p].Passing + 1;

        end;
        aList.Free;
    end;
   //  TALENT_ID_BUFF_MIDDLE = 140 prereq almeno 3 passing, 1 talento qualsiasi --> skill 2x buff reparto (5% chance) cen  20 turni + speed max 4,ballcontrol,passing, shot +1
    if Score.BuffM[T] > 0 then begin
        // cerco il reparto e tolgo buff
        aList := TObjectList<TPlayer>.create(false);
        CompileRoleList(T,'M',aList);
        for p := aList.Count -1 downto 0 do begin
          if aList[p].HasBall then continue;   // il portatore di palla non è stato resettato sopra
          if aList[p].Speed < 4 then
            aList[p].Speed := aList[p].Speed + 1;

          aList[p].BonusBuffM := 1;
          aList[p].BallControl := aList[p].BallControl + 1;
          aList[p].Passing := aList[p].Passing + 1;
          aList[p].Shot := aList[p].Shot + 1;
        end;
        aList.Free;
    end;
   //  TALENT_ID_BUFF_FORWARD = 141 prereq almeno 3 Shot , 1 talento qualsiasi --> skill 2x buff reparto (5% chance) att 20 turni + ballcontrol,passing, shot +1
    if Score.BuffF[T] > 0 then begin
        // cerco il reparto e tolgo buff
        aList := TObjectList<TPlayer>.create(false);
        CompileRoleList(T,'F',aList);
        for p := aList.Count -1 downto 0 do begin
          if aList[p].HasBall then continue;   // il portatore di palla non è stato resettato sopra
          aList[p].BonusBuffF := 1;
          aList[p].BallControl := aList[p].BallControl + 1;
          aList[p].Passing := aList[p].Passing + 1;
          aList[p].Shot := aList[p].Shot + 1;
        end;
        aList.Free;
    end;


  end;


end;
procedure TBrain.SetMinute ( const Value: SmallInt );
begin

   FMinute := value;
//   if FMinute > 60 then begin
//
//   end;

end;
procedure TBrain.TurnChange ( MovesLeft: integer);
var
  p,i,TeamFaultFavour,Isfault: Integer;
begin
    { TODO -cbug : ischeatingball è tutta da rifare }
    TsSpeaker.Clear ;
    { TODO -cbug : nei 2 casi ,anche gk, se ultimo è un bounce non c'è cheating. devo usare un flag bounce o lop andato a vuoto. ma va bene anche cosi' }
   {
     if isCheatingBall ( TeamTurn ) then begin
       if TeamTurn = 0 then TeamFaultFavour := 1 else TeamFaultFavour :=0;
       TsScript[incMove].add ('sc_fault.cheatball,' + intTostr(TeamFaultFavour) + ',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo

       // cambio turno
       if TeamTurn = 0 then TeamTurn := 1 else TeamTurn :=0;

       Isfault := GetFault (TeamFaultFavour , Ball.CellX, Ball.CellY); // fallo a favore del team
        case Isfault of
          1:Begin    // normale nella propria metacampo
            // allontano i player avversari, batterà il ball.player che può essere anche injured. se viene sostituito? tutto ok, ci va sopra
            TsScript[incMove].add ('sc_fault.cheatball,' + intTostr(TeamFaultFavour) +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
            FreeKickSetup1(TeamFaultFavour); // aspetta short.passing o lofted.pass
          end;
          2:Begin    // cross offensivo
            TsScript[incMove].add ('sc_fault.cheatball,' + intTostr(TeamFaultFavour)  +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
            FreeKickSetup2(ball.Player.team); // aspetta crossing
          end;
          3:Begin    // barriera
            TsScript[incMove].add ('sc_fault.cheatball,' + intTostr(TeamFaultFavour) +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
            FreeKickSetup3(ball.Player.team);  // aspetta pos o prs
          end;
          4:Begin    // rigore
            TsScript[incMove].add ('sc_fault.cheatball,' + intTostr(TeamFaultFavour) + ',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
            FreeKickSetup4(ball.Player.team); // aspetta pos o prs
          end;
        end;

        Exit; // evito fine partita

     end;    }




    // il TeamTurn è ancora quello vecchio
    if isCheatingBallGK ( TeamTurn ) then begin // se quel portiere ha la palla. qui è dove sta per cambiare il turno ma ancora è il suo
      { fallo del GK, rigore }
      if TeamTurn = 0 then TeamFaultFavour := 1 else TeamFaultFavour :=0;
      TsScript[incMove].add ('sc_fault.cheatballgk,' + intTostr(TeamFaultFavour) +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
      if TeamTurn = 0 then TeamTurn := 1 else TeamTurn :=0;
      FreeKickSetup4(TeamTurn);
      FlagEndGame := false; // evito fine partita
      Exit;
    end;

    // qui cambia effettivamente il turno
    FTeamMovesLeft := MovesLeft;
    if TeamTurn = 0 then TeamTurn := 1 else TeamTurn :=0;
    TsScript[incMove].add ('sc_TUC,' + intTostr(TeamTurn) ) ;
    ResetPassiveSkills ;
    ShpFree:=  1;
    fmilliseconds := Turnmilliseconds;

    if Minute >= 120 then begin
      if Not W_Something then  // potrebbe andare avanti all'infinito a forza di falli. forse minute e incmove vanno messi a smallint
        FlagEndGame := True // le sostituzioni non incrementano i minuti
        else FlagEndGame := false; // in caso di freekick non finisce la partita
    end
    else FlagEndGame := false;


    if (GameStarted) and  (FlagEndGame)  then begin
      TsScript[incMove].add ('sc_GAMEOVER,' + intTostr(TeamTurn) ) ;
      GameStarted:= False;
      Finished:= True;
      FinishedTime := GetTickCount;  { TODO -con the road : pvp bug alle 23.59 }
      if Length(Score.lstGol) > 0 then // rimuovo la virgola finale
        Score.lstGol := LeftStr ( Score.lstGol , Length(Score.lstGol) - 1);

      // bonus di premi in xp per vittoria o pareggio  (no bonus ai talenti )
      if Score.gol [0] = Score.gol[1] then begin
//        Score.TeamMI [0] := Score.TeamMI [0] - 2;
       // Score.TeamMI [0] := Score.TeamMI [0] + 1;  // 0 se pareggi in casa
        Score.TeamMI [1] := Score.TeamMI [1] + 1;
        Score.points[0] := 1;
        Score.points[1] := 1;
        for I := Players.Count -1 downto 0 do begin
          Players[i].xp_Speed := Players[i].xp_Speed + 1;
          Players[i].xp_Defense := Players[i].xp_Defense + 1;
          Players[i].xp_Passing:= Players[i].xp_Passing + 1;
          Players[i].xp_BallControl := Players[i].xp_BallControl + 1;
          Players[i].xp_Shot := Players[i].xp_Shot + 1;
          Players[i].xp_Heading := Players[i].xp_Heading + 1;
        end;
      end
      else if Score.gol[0] > Score.gol[1] then begin
//        Score.TeamMI [1] := Score.TeamMI [1] - 1;
        Score.TeamMI [0] := Score.TeamMI [0] + 2;
        Score.TeamMI [1] := Score.TeamMI [1] - 2;
        if Score.TeamMI[1] < 0 then
         Score.TeamMI[1]:= 0;
        Score.points[0] := 3;
        Score.points[1] := 0;
        for I := Players.Count -1 downto 0 do begin
          if Players[i].Team = 0 then begin
            Players[i].xp_Speed := Players[i].xp_Speed + 3;
            Players[i].xp_Defense := Players[i].xp_Defense + 3;
            Players[i].xp_Passing:= Players[i].xp_Passing + 3;
            Players[i].xp_BallControl := Players[i].xp_BallControl + 3;
            Players[i].xp_Shot := Players[i].xp_Shot + 3;
            Players[i].xp_Heading := Players[i].xp_Heading + 3;
          end;
        end;
      end
      else if Score.gol[0] < Score.gol[1] then begin
//        Score.TeamMI [0] := Score.TeamMI [0] - 3;
//        Score.TeamMI [1] := Score.TeamMI [1] + 2;
        Score.TeamMI [0] := Score.TeamMI [0] - 3;
        if Score.TeamMI[0] < 0 then
         Score.TeamMI[0]:= 0;
        Score.TeamMI [1] := Score.TeamMI [1] + 3;
        Score.points[0] := 0;
        Score.points[1] := 3;
        for I := Players.Count -1 downto 0 do begin
          if Players[i].Team = 1 then begin
            Players[i].xp_Speed := Players[i].xp_Speed + 3;
            Players[i].xp_Defense := Players[i].xp_Defense + 3;
            Players[i].xp_Passing:= Players[i].xp_Passing + 3;
            Players[i].xp_BallControl := Players[i].xp_BallControl + 3;
            Players[i].xp_Shot := Players[i].xp_Shot + 3;
            Players[i].xp_Heading := Players[i].xp_Heading + 3;
          end;
        end;
      end;


      if GameMode = pvp then
        TBrainManager(brainManager).Input ( Self,   'FINALIZE' )
      else if pvePostMessage then
          postMessage ( Application.Handle , $2EEE,0,0);

    end;

end;
procedure TBrain.SetGender ( fm: char);
begin
  fGender := fm;
  If Gender = 'f' then
    GenderN := 1
  else GenderN := 2;


  if fGender = 'f' then begin
    MAX_STAT := 6;

    MAX_DEFAULT_SPEED := 4;
    MAX_DEFAULT_DEFENSE := 6;
    MAX_DEFAULT_PASSING := 6;
    MAX_DEFAULT_BALLCONTROL := 6;
    MAX_DEFAULT_SHOT := 6;
    MAX_DEFAULT_HEADING := 6;

    BonusPowerShotGK[1]:= 1;
    BonusPowerShotGK[2]:= 2;
    BonusPowerShotGK[3]:= 3;
    BonusPowerShotGK[4]:= 4;
    BonusPowerShotGK[5]:= 4;
    BonusPowerShotGK[6]:= 4;
    BonusPowerShotGK[7]:= 4;
    BonusPowerShotGK[8]:= 3;
    BonusPowerShotGK[9]:= 2;
    BonusPowerShotGK[10]:= 1;

    BonusPrecisionShotGK[1]:= 0;
    BonusPrecisionShotGK[2]:= 1;
    BonusPrecisionShotGK[3]:= 2;
    BonusPrecisionShotGK[4]:= 3;
    BonusPrecisionShotGK[5]:= 3;
    BonusPrecisionShotGK[6]:= 3;
    BonusPrecisionShotGK[7]:= 3;
    BonusPrecisionShotGK[8]:= 2;
    BonusPrecisionShotGK[9]:= 1;
    BonusPrecisionShotGK[10]:= 0;

    PRE_VALUE := 2;
    PRO_VALUE := 2;

    CRO_MIN1    := 1;
    CRO_MIN2    := 3;
    CRO_MID1    := 4;
    CRO_MID2    := 5;
    CRO_MAX1    := 6;

    LOP_MIN1    := 1;
    LOP_MIN2    := 3;
    LOP_MID1    := 4;
    LOP_MID2    := 5;
    LOP_MAX1    := 6;

    LOP_BC_MIN1    := 1;
    LOP_BC_MIN2    := 3;
    LOP_BC_MID1    := 4;
    LOP_BC_MID2    := 5;
    LOP_BC_MAX1    := 6;


    DRIBBLING_MALUS := 2;
    DRIBBLING_DIFF := 2;

    modifier_defenseShot := 1;
    modifier_penaltyPOS := 2;
    modifier_penaltyPRS := 3;

    CRO2_D2_MIN := 1;
    CRO2_D2_MAX := 1;
    CRO2_D1_MIN := 2;
    CRO2_D1_MAX := 2;
    CRO2_D0_MIN := 3;
    CRO2_D0_MAX := 3;
    CRO2_A2_MIN := 4;
    CRO2_A2_MAX := 4;
    CRO2_A1_MIN := 5;
    CRO2_A1_MAX := 5;
    CRO2_A0_MIN := 6;

    COR_D2_MIN := 1;
    COR_D2_MAX := 1;
    COR_D1_MIN := 2;
    COR_D1_MAX := 2;
    COR_D0_MIN := 3;
    COR_D0_MAX := 3;
    COR_A2_MIN := 4;
    COR_A2_MAX := 5;
    COR_A1_MIN := 5;
    COR_A1_MAX := 5;
    COR_A0_MIN := 6;

  end
  else begin
    MAX_STAT := 10;

    MAX_DEFAULT_SPEED := 4;
    MAX_DEFAULT_DEFENSE := 10;
    MAX_DEFAULT_PASSING := 10;
    MAX_DEFAULT_BALLCONTROL := 10;
    MAX_DEFAULT_SHOT := 10;
    MAX_DEFAULT_HEADING := 10;


    BonusPowerShotGK[1]:= 1;
    BonusPowerShotGK[2]:= 2;
    BonusPowerShotGK[3]:= 3;
    BonusPowerShotGK[4]:= 4;
    BonusPowerShotGK[5]:= 4;
    BonusPowerShotGK[6]:= 4;
    BonusPowerShotGK[7]:= 4;
    BonusPowerShotGK[8]:= 3;
    BonusPowerShotGK[9]:= 2;
    BonusPowerShotGK[10]:= 1;

    BonusPrecisionShotGK[1]:= 0;
    BonusPrecisionShotGK[2]:= 1;
    BonusPrecisionShotGK[3]:= 2;
    BonusPrecisionShotGK[4]:= 3;
    BonusPrecisionShotGK[5]:= 3;
    BonusPrecisionShotGK[6]:= 3;
    BonusPrecisionShotGK[7]:= 3;
    BonusPrecisionShotGK[8]:= 2;
    BonusPrecisionShotGK[9]:= 1;
    BonusPrecisionShotGK[10]:= 0;

    PRE_VALUE := 3;
    PRO_VALUE := 3;

    CRO_MIN1    := 1;
    CRO_MIN2    := 5;
    CRO_MID1    := 6;
    CRO_MID2    := 9;
    CRO_MAX1    := 10;

    LOP_MIN1    := 1;
    LOP_MIN2    := 5;
    LOP_MID1    := 6;
    LOP_MID2    := 9;
    LOP_MAX1    := 10;

    LOP_BC_MIN1    := 1;
    LOP_BC_MIN2    := 5;
    LOP_BC_MID1    := 6;
    LOP_BC_MID2    := 9;
    LOP_BC_MAX1    := 10;

    DRIBBLING_MALUS := 3;
    DRIBBLING_DIFF := 3;

    modifier_defenseShot := 2;
    modifier_penaltyPOS := 3;
    modifier_penaltyPRS := 4;

    CRO2_D2_MIN := 1;
    CRO2_D2_MAX := 2;
    CRO2_D1_MIN := 3;
    CRO2_D1_MAX := 4;
    CRO2_D0_MIN := 5;
    CRO2_D0_MAX := 6;
    CRO2_A2_MIN := 7;
    CRO2_A2_MAX := 8;
    CRO2_A1_MIN := 9;
    CRO2_A1_MAX := 10;
    CRO2_A0_MIN := 10;

    COR_D2_MIN := 1;
    COR_D2_MAX := 2;
    COR_D1_MIN := 3;
    COR_D1_MAX := 4;
    COR_D0_MIN := 5;
    COR_D0_MAX := 6;
    COR_A2_MIN := 7;
    COR_A2_MAX := 8;
    COR_A1_MIN := 9;
    COR_A1_MAX := 10;
    COR_A0_MIN := 10;

  end;

end;
procedure TBrain.Setmilliseconds ( value: Integer);
begin
  { in caso di wcod o simili subentra la AI automaticamente, altrimenti cambia turno da solo ma deve inviare un PASS }

  fmilliseconds:= value;
  if fmilliseconds < 0 then begin
//    if  w_Coa or w_Cod or w_CornerKick or w_Fka1 or w_FreeKick1 or w_Fka2 or w_Fkd2  or w_FreeKick2 or w_Fka3 or w_Fkd3 or w_FreeKick3 or
//     w_Fka4 or w_FreeKick4 then
      SoccerAI.AI_Think( teamTurn );
//    else

      //BrainInput ( IntTostr(score.TeamGuid [teamTurn]) + ',' + 'PASS'  ) ;  // PASS oltre 120+ non è permesso
      SaveData ( incMove );
//      TBrainManager(brainManager).Input ( Self,   brainIds + '\' + Format('%.*d',[3, incMove])  ) ;
      TBrainManager(brainManager).Input ( Self,  IntToStr(incMove)  ) ;
////      inc (incMove);
  end;
end;
function TBrain.findSpectator (Cliid: Integer): Boolean;
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  for i := 0 to lstSpectator.Count -1 do begin
    if lstSpectator[i]= CliId then begin
      result := True;
      ReleaseMutex(Mutex);
      Exit;
    end;
  end;
  ReleaseMutex(Mutex);
end;
function TBrain.RemoveSpectator (Cliid: Integer): Boolean;
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  for i := lstSpectator.Count -1 downto 0 do begin
    if lstSpectator[i]= CliId then begin
      lstSpectator.Delete(i);
      result := True;
      ReleaseMutex(Mutex);
      Exit;
    end;
  end;
  ReleaseMutex(Mutex);
end;
procedure TBrain.InputSecureExit ( DoAiMoveAll: Boolean; DoTeamMovesLeft: TDecMovesLeft);
begin

  if DoAiMoveAll  then
    AI_moveAll;

  if DoTeamMovesLeft = DecNormal then begin
    TeamMovesLeft := TeamMovesLeft - 1;
  end
  else if DoTeamMovesLeft = DecNoResetPlayer then begin
    fTeamMovesLeft := fTeamMovesLeft - 1;
  end;
  if TeamMovesLeft <= 0 then TurnChange  (TurnMoves);
  TsScript[incMove].add ('E');
end;
function TBrain.CheckOffside ( FromPlayer, aPossibleoffside: TPlayer ): boolean;
begin
  Result := False;
  if aPossibleoffside <> nil then begin
    if isOffside ( FromPlayer, aPossibleoffside )   then begin
      //come fallo freekick1
      TsScript[incMove].add ('sc_fault,' + aPossibleoffside.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
      if aPossibleoffside.team = 0 then
        FreeKickSetup1( 1 ) // aspetta short.passing o lofted.pass
      else
        FreeKickSetup1( 0 ); // aspetta short.passing o lofted.pass

      Result := True;
    end;

  end;

end;

function TBrain.CheckInputShp (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist ): string;
begin
  Result := '';
  if aPlayer = nil then begin
   Result := 'SHP,Ball.Player not found Ts:' + tsCmd.CommaText;
   Exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   Result := 'SHP,Player ' + aPlayer.SurName +' unable to use skill Ts:' + tsCmd.CommaText;
   Exit; // hack
  end;
  if  aPlayer.TalentId1 = TALENT_ID_GOALKEEPER then begin
   Result := 'SHP,GoalKeeper can not use skill short.passing Ts:' +tsCmd.CommaText ;
   Exit; // hack
  end;

  aPlayer.tmp := ShortPassRange;
  if (aPlayer.TalentId1 = TALENT_ID_LONGPASS) or (aPlayer.TalentId2 = TALENT_ID_LONGPASS) then
    aPlayer.tmp := aPlayer.tmp +1;

  if (absDistance( Ball.CellX ,Ball.CellY,  CellX, CellY ) > (aPlayer.tmp))
     or (absDistance (Ball.Player.CellX , Ball.Player.CellY, Cellx, Celly  ) = 0) then begin
    Result := 'SHP,Destination range Ts:' +tsCmd.CommaText ;
    Exit;
  end;

  if w_SomeThing  then begin
   Result := 'SHP, waiting freekick Ts:' +tsCmd.CommaText;
   Exit; // hack
  end;   // freekick1 concesso

end;
function TBrain.CheckInputLop (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist ): string;
var
  aFriend: TPlayer;
begin
  Result := '';
  if aPlayer = nil then begin
   Result := 'LOP,Ball.Player not found Ts:' +tsCmd.CommaText ;
   Exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   Result := 'LOP,Player unable to use skill Ts:' +tsCmd.CommaText ;
   Exit; // hack
  end;
  { lop su freekick1 può esistere. }
  if w_CornerSetup or w_Coa or w_cod or w_CornerKick {or w_FreeKickSetup1 or w_Fka1 or w_FreeKick1} or w_Fka2 or w_FreeKickSetup2 or w_Fka2 or w_Fkd2 or w_FreeKick2
  or w_FreeKickSetup3 or w_Fka3 or w_Fkd3 or w_FreeKick3 or w_Fka4 or w_FreeKickSetup4 or w_FreeKick4  then begin
   Result := 'LOP, waiting freekick Ts:' +tsCmd.CommaText ;
   Exit; // hack
  end;  // concesso nulla

  if tsCmd[3] <> 'GKLOP' then begin
    aPlayer.tmp := LoftedPassRangeMax;
    if (aPlayer.TalentId1 = TALENT_ID_LONGPASS) or (aPlayer.TalentId2 = TALENT_ID_LONGPASS) then
      aPlayer.tmp := aPlayer.tmp +1;

    if (absDistance( Ball.CellX ,Ball.CellY,  CellX, CellY ) > (aPlayer.tmp))
    or (absDistance( Ball.CellX ,Ball.CellY,  CellX, CellY ) < LoftedPassRangeMin)  then begin
      Result := 'LOP,Destination range ts: ' + tsCmd.CommaText ;
      Exit;
    end;
  end;

  aFriend := GeTPlayer ( CellX, CellY, aPlayer.Team );
  if aFriend <> nil then Begin
    if aFriend.Team <> aPlayer.team then begin
    Result := 'LOP,Destination Player unfriendly Ts:' +tsCmd.CommaText ;
    Exit;
  end;
  end;
  if IsGKCell(CellX,Celly) then begin
    Result := 'LOP,Destination is GK Ts:' +tsCmd.CommaText ;
    Exit;
  end;


end;
function TBrain.CheckInputCro (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist ): string;
var
  aHeadingFriend: TPlayer;
begin
  Result := '';
  if w_SomeThing  then begin
   Result := 'CRO, waiting freekick Ts:' + tsCmd.CommaText;
   Exit; // hack
  end;  // concesso nulla

  aPlayer := Ball.Player;
  if aPlayer = nil then begin
   Result := 'CRO,Ball.Player not found Ts:' + tsCmd.CommaText;
   Exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   Result := 'CRO,Player unable to use skill Ts:' + tsCmd.CommaText;
   Exit; // hack
  end;

  aPlayer.tmp := CrossingRangeMax;
  if (aPlayer.TalentId1 = TALENT_ID_LONGPASS) or (aPlayer.TalentId2 = TALENT_ID_LONGPASS) then
    aPlayer.tmp := aPlayer.tmp +1;

  if (absDistance( Ball.CellX ,Ball.CellY,  CellX, CellY ) > (aPlayer.tmp))
  or (absDistance( Ball.CellX ,Ball.CellY,  CellX, CellY ) < CrossingRangeMin)  then begin
    Result := 'CRO,Destination range ts: ' + tsCmd.CommaText + ' ball=' + IntToStr(Ball.CellX)+','+IntToStr(Ball.CellY );
    Exit;
  end;

  aHeadingFriend := GeTPlayer ( CellX, CellY,aPlayer.Team );

  if aHeadingFriend = nil then begin
    Result := 'CRO,Destination Player unfriendly or nil Ts:'+ tsCmd.CommaText;
    Exit;
  end;
end;
function TBrain.CheckInputDri (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist ): string;
var
  anOpponent: TPlayer;
begin
  Result := '';
  if w_SomeThing  then begin
   Result := 'DRI, waiting freekick Ts:'+ tsCmd.CommaText;
   Exit; // hack
  end;  // concesso nulla

  if aPlayer = nil then begin
   Result := 'DRI,Ball.Player not found Ts:'+ tsCmd.CommaText;
   Exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   Result := 'DRI,Player unable to use skillTs:'+ tsCmd.CommaText;
   Exit; // hack
  end;

  if absDistance( Ball.CellX ,Ball.CellY,  CellX, CellY ) > 1 then begin
    Result := 'DRI,Destination range ts: ' + tsCmd.CommaText ;
    Exit;
  end;
  if not aPlayer.canDribbling then begin
    Result := 'DRI,player unable to dribbling Ts:'+ tsCmd.CommaText;
    Exit;
  end;

  anOpponent := GeTPlayerOpponent ( CellX, CellY, aPlayer.team );
  if anOpponent = nil then begin
    Result := 'DRI,Destination Player missing Ts:'+ tsCmd.CommaText;
    Exit;

  end;
  if (anOpponent.Role ='G')  then Begin
    Result := 'DRI,Destination Player GK Ts:'+ tsCmd.CommaText;
    Exit;
  End;

end;
function TBrain.CheckInputPos (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist ): string;
begin
  Result := '';
  if w_CornerSetup or w_Coa or w_cod or w_CornerKick or w_FreeKickSetup1 or w_Fka1 or w_Fka2 or w_FreeKick1 or w_FreeKickSetup2 or w_Fka2 or w_Fkd2 or w_FreeKick2
  {or w_FreeKickSetup3 or w_Fka3 or w_Fkd3 or  w_Fka4 or w_FreeKickSetup4 }   then begin
   Result := 'POS, waiting freekick  Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;  // concessi i tiri

  if aPlayer = nil then begin
   Result := 'POS,Ball.Player not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   Result := 'POS,Player unable to use skill Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

  if (absDistance( Ball.CellX ,Ball.CellY,  CellX, CellY ) > ( PowerShotRange  )) then begin
    Result := 'POS,Shot range  Ts:'+ tsCmd.CommaText;
    exit;
  end;
  if (Not aPlayer.InShotCell) and (not w_FreeKick3) then begin // diventa una shot cell
    Result := 'POS,Not in shot cell Ts:'+ tsCmd.CommaText;
    exit;
  end;

end;
function TBrain.CheckInputPrs (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist ): string;
begin
  Result := '';
  if w_CornerSetup or w_Coa or w_cod or w_CornerKick or w_FreeKickSetup1 or w_FreeKick1 or  w_Fka1 or w_Fka2 or w_FreeKickSetup2 or w_Fka2 or w_Fkd2 or w_FreeKick2
  {or w_FreeKickSetup3 or w_Fka3 or w_Fkd3 or  w_Fka4 or w_FreeKickSetup4}    then begin
   result := 'PRS, waiting freekick  Ts:'+ tsCmd.CommaText;
   Exit; // hack
  end;  // concessi i tiri

  // non è uguale a pos. rimbalzo a e non a 2
  if aPlayer = nil then begin
   result := 'PRS,Ball.Player not found Ts:'+ tsCmd.CommaText;
   Exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   result := 'PRS,Player unable to use skill Ts:'+ tsCmd.CommaText;
   Exit; // hack
  end;

  if (absDistance( Ball.CellX ,Ball.CellY,  CellX, CellY ) > (PrecisionShotRange  )) then begin
    result := 'PRS,Shot range  Ts:'+ tsCmd.CommaText;
    Exit;
  end;
  if (Not aPlayer.InShotCell) and (not w_FreeKick3) then begin // diventa una shot cell
    result := 'PRS,Not in shot cell Ts:'+ tsCmd.CommaText;
    Exit;
  end;

end;
function TBrain.CheckInputPre (aPlayer: TPlayer; tsCmd: Tstringlist): string;
begin
  Result := '';
  if w_SomeThing  then begin
   result := 'PRE, waiting freekick Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;  // concesso nulla

  if aPlayer = nil then begin
   result := 'PRE,Player not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   result := 'PRE,Player unable to use skill Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if Ball.Player = nil then begin
   result := 'PRE,Ball.Player not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if Ball.Player.team = aPlayer.Team then Begin
   result := 'PRE,Ball.Player same team Ts:'+ tsCmd.CommaText;
   exit; // hack
  End;
  if Ball.Player.TalentId1 =  TALENT_ID_GOALKEEPER then begin
   result := 'PRE,Ball.Player is GK Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

end;
function TBrain.CheckInputPro (aPlayer: TPlayer; tsCmd: Tstringlist): string;
begin
  Result := '';
  if w_SomeThing  then begin
   result := 'PRO, waiting freekick Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;  // concesso nulla
  if aPlayer = nil then begin
   result := 'PRO,Player not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   result := 'PRO,Player unable to use skill Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if Ball.Player.Team <> teamTurn then begin
   result := 'PRO,turn mismatch Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
end;
function TBrain.CheckInputTac (aPlayer: TPlayer; tsCmd: Tstringlist): string;
begin
  Result := '';
  if w_SomeThing  then begin
   result := 'TAC, waiting freekick ';
   exit; // hack
  end;  // concesso nulla

  if aPlayer = nil then begin
   result := 'TAC,Player not found';
   exit; // hack
  end;
  if not aPlayer.CanSkill then begin
   result := 'TAC,Player unable to Skill';
   exit; // hack
  end;
  if Ball.player = nil then begin
   result := 'TAC,Ball.Player not found';
   exit; // hack
  end;
end;
function TBrain.CheckInputStay (aPlayer: TPlayer; tsCmd: Tstringlist): string;
begin
  Result := '';
  if w_SomeThing  then begin
   result := 'STAY, waiting freekick Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;  // concesso nulla
  if aPlayer = nil then begin
   result := 'STAY,Player not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if aPlayer.Team <> teamTurn then begin
   result := 'STAY,turn mismatch Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if aPlayer.TalentID1 = TALENT_ID_GOALKEEPER then begin
   result := 'STAY,GK Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if minute >= 120 then begin
   result := 'STAY, 120+ Ts:'+ tsCmd.CommaText;
   exit; // hack

  end;
end;
function TBrain.CheckInputFree (aPlayer: TPlayer; tsCmd: Tstringlist): string;
begin
  Result := '';
  if w_SomeThing  then begin
   result := 'FREE, waiting freekick Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;  // concesso nulla
  if aPlayer = nil then begin
   result := 'FREE,Player not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if aPlayer.Team <> teamTurn then begin
   result := 'FREE,turn mismatch Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if aPlayer.TalentID1 = TALENT_ID_GOALKEEPER then begin
   result := 'FREE,GK Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;
  if minute >= 120 then begin
   result := 'FREE, 120+  Ts:'+ tsCmd.CommaText;
   exit; // hack

  end;
end;
function TBrain.CheckInputTactic (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
var
  aPossiblePlayer2: TPlayer;
begin
  Result := '';
  if w_SomeThing  then begin
   result := 'TACTIC, waiting freekick Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;  // concesso nulla

  if aPlayer = nil then begin
   result := 'TACTIC,Player not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;


  if IsOutSide(  CellX, CellY) then Begin
   result := 'TACTIC,Cells outside Ts:'+ tsCmd.CommaText;
   exit; // hack

  End;

  if (isGKcell ( CellX, CellY ) ) and (aPlayer.talentID1 <> TALENT_ID_GOALKEEPER) then Begin
      // un goalkeeper può essere schierato solo in porta
   result := 'TACTIC,GK cell Ts:'+ tsCmd.CommaText;
   exit; // hack
  End;
  if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.talentID1 = TALENT_ID_GOALKEEPER) then begin
  // un goalkeeper può essere schierato solo in porta
   result := 'TACTIC, not GK cell Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

  if (aPlayer.Team  = 0)
    and ( (CellX = 1) or (CellX = 3)  or (CellX = 4) or (CellX = 6) or (CellX = 7) or (CellX = 9) or (CellX = 10) or (CellX = 11) ) then Begin
   result := 'TACTIC, Cell mismatch team Ts:'+ tsCmd.CommaText;
   exit; // hack
  End;

  if (aPlayer.Team  = 1)
    and ( (CellX = 0) or (CellX = 1)  or (CellX = 2) or (CellX = 4) or (CellX = 5) or (CellX = 7) or (CellX = 8) or (CellX = 10) ) then Begin
   result := 'TACTIC, Cell mismatch team  Ts:'+ tsCmd.CommaText;
   exit; // hack
  End;

  if isReserveSlot ( aPlayer.CellX , aPlayer.CellY ) then begin
   result := 'TACTIC, Player is outside ';
   exit; // hack
  End;

  aPossiblePlayer2 := GeTPlayerDefault ( CellX, CellY); // importante default
  if aPossiblePlayer2 <> nil then begin
   result := 'TACTIC, Cells occupied  Ts:'+ tsCmd.CommaText;
   exit; // hack
  End;

  if minute >= 120 then begin
   result := 'TACTIC, 120+ Ts:'+ tsCmd.CommaText;
   exit; // hack

  end;
end;
function TBrain.CheckInputSub (aPlayer, aPlayer2: TPlayer; tsCmd: Tstringlist): string;
var
  CellX, CellY: Integer;
begin
  Result := '';
  if w_SomeThing  then begin
   result := 'SUB, waiting freekick Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;  // concesso nulla

  if aPlayer = nil then begin
   result := 'SUB,Player not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

  if Score.TeamSubs [ aPlayer.Team ]  >= 3 then Begin
   result := 'SUB, Max 3 substitution Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

  if aPlayer2 = nil then begin
   result := 'SUB,Player2 not found Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

  if aPlayer2.Team <> aPlayer.Team then begin
   result := 'SUB, Players team mismatch Ts:'+ tsCmd.CommaText;
   exit; // hack
  End;

  if aPlayer2.ids = aPlayer.ids then begin
   result := 'SUB, same Players Ts:'+ tsCmd.CommaText;
   exit; // hack
  End;

  CellX := aPlayer2.cellX;
  CellY := aPlayer2.cellY;

  if IsOutSide(  CellX, CellY) then Begin
   result := 'SUB,Cells outside Ts:'+ tsCmd.CommaText;
   exit; // hack

  End;

  if (isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 <> TALENT_ID_GOALKEEPER) then Begin
      // un goalkeeper può essere schierato solo in porta
   result := 'SUB,GK cell Ts:'+ tsCmd.CommaText;
   exit; // hack
  End;
  if  ( not isGKcell ( CellX, CellY ) ) and (aPlayer.TalentID1 = TALENT_ID_GOALKEEPER) then begin
  // un goalkeeper può essere schierato solo in porta
   result := 'SUB, not GK cell Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

{    if ((CellX = 0) or (CellX = 2)  or  (CellX = 5) or (CellX = 8)) and (aPlayer.Team <> 0) then Begin
   result := 'SUB, Cell mismatch team ';
   exit; // hack
  End;

  if ((CellX = 11) or (CellX = 9)  or  (CellX = 6) or (CellX = 3)) and (aPlayer.Team <> 1) then begin
   result := 'SUB, Cell mismatch team ';
   exit; // hack
  End;  }

  if (aPlayer.RedCard > 0) or (aPlayer2.RedCard > 0) or (aPlayer.Gameover ) or (aPlayer2.Gameover ) then begin  // espulso o già sostituito o finite subs
   result := 'SUB, Player error Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

  if( AbsDistance(aPlayer2.CellX, aPlayer2.CellY,Ball.CellX ,Ball.celly) < 4) or
   ( w_CornerSetup ) or ( w_FreeKickSetup1 ) or ( w_FreeKickSetup2 ) or ( w_FreeKickSetup3 ) or ( w_FreeKickSetup4 ) then begin
   result := 'SUB, Distanza < 4 or freekicksetup  Ts:'+ tsCmd.CommaText;
   exit; // hack
  end;

end;
function TBrain.CheckInputPlm (aPlayer: TPlayer; CellX, CellY: integer; tsCmd: Tstringlist): string;
begin
  Result := '';
  if w_SomeThing  then begin
   result := 'PLM, waiting freekick Ts:'+ tsCmd.CommaText;
   Exit; // hack
  end;  // concesso nulla

  if aPlayer = nil then begin
   result := 'PLM,Player not found Ts:'+ tsCmd.CommaText;
   Exit; // cheat
  end;
  if not aPlayer.CanMove then begin
   result := 'PLM,Player unable to move Ts:'+ tsCmd.CommaText;
   Exit; // cheat
  end;
  if ( aPlayer.isCOF ) or ( aPlayer.isFK1 ) or ( aPlayer.isFK2 ) or ( aPlayer.isFK3 ) or ( aPlayer.isFK4 ) then begin
   result := 'PLM,Player is some FK Ts:'+ tsCmd.CommaText;;
   Exit; // cheat
  end;
end;
  // poi attack defense ecc....
procedure TBrain.BrainInput ( aCmd: string );
var
  MyFile: THandle;
  tsCmd: Tstringlist;
  BaseHeading,BaseHeadingFriend,BaseGK,aRnd,aRnd2,aRnd3,arnd4,preRoll, preRoll2,preRoll3,preRoll4,CellX,CellY,BonusDefenseHeading,BaseIntercept: integer;
  BaseShotChance : TChance;
  Roll,Roll2,Roll3,Roll4: TRoll;
  aPath: dse_pathplanner.Tpath;
  i,y,ii,c,MoveValue,P,tmpX,tmpY,ToEmptyCell,Diff: integer;
  anIntercept: TPlayer; // un avversario che intercetta un short.passing (passaggio corto)
  aPlayer: TPlayer;     // il player attuale che inizia questa azione
  aFriend, aHeadingFriend, aPlayer2,aFriend2: TPlayer; // un compagno che riceve la palla
  anOpponent, aSoccerPlayer,oldPlayerBall,aPlayerHeading, aPossiblePlayer2,aPossibleoffside: TPlayer; // altri puntatori ai player
  SwapPlayer,  aGhost, aGK, aHeadingOpponent: TPlayer;
  Gkxpr : Integer;
  ACT: string;

  penalty: boolean;
  CornerMap: TCornerMap;  // in caso di corner sono le informazioni del corner: area, porta ecc...
  Barrier: Boolean;       // in caso di freekick3 ( punizione dal limite )

  IsFault: Integer;       // Durante un 'TAC' (tackle) si può commettere fallo.
  tt : string;
  SwapString: TstringList;
  SwapDone: Boolean;
  aList: TobjectList<TPlayer>;
  lstAutoTackle,lstIntercepts,LstHeading: TList<TInteractivePlayer>;// si riempiranno di player avversari che interagiscono nell'azione corrente
  CrossBarN : integer;
  DefenseHeadingWin: boolean;
  aCell, aCell2, oldBall, oldPlayer,ACellFK,aCellBarrier: Tpoint;
  FriendlyWall,OpponentWall,FinalWall: boolean;
  aDoor : Tpoint;        // una delle due porte a cui fare riferimento in caso di tiro ( PRS, POS  ecc...)
  aPoint : TPoint;
  tmp : TPoint;
  Modifier: Integer;
  OldCell: TPoint;
  found: boolean;
  dstCell: TPoint;
  InputGuidTeam, CmdPlay: Integer;
  reason: string;
  FileError : TextFile;
  kind: string;
  label cor_crossbar, cro_crossbar, pos_crossbar, prs_crossbar, MyExit;
  label HVSH,afterPowerShot,afterPrecisionShot, crossing,plmautotackledone;
  label palo;
  label POSvsGK, PRSvsGK;
  label GK;
  label Normalpressing;
  label setCorner;
  label buffd, buffm,bufff;
begin
  // in linea di massima:
  //
  // anIntercept, , aPlayer2,anOpponent
  // lstAutoTackle,lstIntercepts,LstHeading
  inc (incMove);

  tsCmd:= TstringList.Create ;
  tsCmd.CommaText := aCmd;

 // if GameMode = pvp then begin
    InputGuidTeam := StrToInt(tsCmd[0]);
    tsCmd.Delete(0); // se serve lo uso
//  end;
  CmdPlay := StrTointDef ( tsCmd[0], 0 );

  if ((InputGuidTeam = Score.TeamGuid[0]) and ( TeamTurn = 1 ))
  or ((InputGuidTeam = Score.TeamGuid[1]) and ( TeamTurn = 0 ))
   then begin
   {
    OutputDebugString( PChar( 'w_coa ' + BoolToStr(w_coa)) );
    OutputDebugString( PChar( 'w_cod' + BoolToStr(w_cod)));
    OutputDebugString( PChar( 'w_CornerSetup ' + BoolToStr(w_CornerSetup)) );
    OutputDebugString( PChar( 'w_CornerKick ' + BoolToStr(w_CornerKick)) );

    OutputDebugString( PChar( 'w_FreeKickSetup1 ' + BoolToStr(w_FreeKickSetup1)) );
    OutputDebugString( PChar( 'w_Fka1 ' + BoolToStr(w_Fka1)) );
    OutputDebugString( PChar( 'w_FreeKick1 ' + BoolToStr(w_FreeKick1)) );

    OutputDebugString( PChar( 'w_FreeKickSetup2 ' + BoolToStr(w_FreeKickSetup2)) );
    OutputDebugString( PChar( 'w_Fka2 ' + BoolToStr(w_Fka2)) );
    OutputDebugString( PChar( 'w_Fkd2 ' + BoolToStr(w_Fkd2)) );
    OutputDebugString( PChar( 'w_FreeKick2 ' + BoolToStr(w_FreeKick2)) );

    OutputDebugString( PChar( 'w_FreeKickSetup3 ' + BoolToStr(w_FreeKickSetup3)) );
    OutputDebugString( PChar( 'w_Fka3 ' + BoolToStr(w_Fka3)) );
    OutputDebugString( PChar( 'w_Fkd3 ' + BoolToStr(w_Fkd3)) );
    OutputDebugString( PChar( 'w_FreeKick3 ' + BoolToStr(w_FreeKick3)) );

    OutputDebugString( PChar( 'w_FreeKickSetup4 ' + BoolToStr(w_FreeKickSetup4)) );
    OutputDebugString( PChar( 'w_Fka4 ' + BoolToStr(w_Fka4)) );
    OutputDebugString( PChar( 'w_FreeKick4 ' + BoolToStr(w_FreeKick4)) );
    }

    reason := 'TeamTurn Error ' + aCmd ;
    goto myexit; // hack
  end;

  if Working then begin
     reason := 'Brain working ' + aCmd ;
     goto myexit; // hack
  end;

  Working:= True;
  ExceptPlayers.Clear;


  // qualunque input arrivi se la palla è del portiere avversario all'inizio del mio turno è rigore
  // qualunque input arrivi se la palla non è raggiungibile aumenta flagchartingball. se arriva a 2 è fallo

//  case Cmdplay of

  if tsCmd[0] = 'SHP' then  begin
{
  talenti interessati:
  TALENT_ID_PLAYMAKER
  TALENT_ID_AGILITY
  TALENT_ID_BULLDOG        ( +1 intercept )
  TALENT_ID_ADVANCED_BULLDOG        ( +2 intercept )
}
     // 0=pwd 1=SHP... 2=cellX 3=CellY
//      TBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[1] + ',' + ts[2] + ',' + ts[3]  );
    // 0=GuidTeam 1=SHP 2=CELLY 3=CELLY
    Ball.Speed := 1;
    CellX := StrToIntDef (tsCmd[1],-1);
    CellY := StrToIntDef (tsCmd[2],-1);


    aPlayer := Ball.Player;//   GeTPlayer ( tsCmd[1]);
    reason := CheckInputShp (aPlayer, CellX, CellY, tsCmd);
    if reason <> '' then goto myexit; // hack



    // calcola il percorso della palla in linea retta e ottiene un path di celle interessate
    aPath:= dse_pathplanner.Tpath.Create;
    GetLinePoints ( Ball.CellX ,Ball.CellY,  CellX, CellY, aPath ); // il GK non fa short.passing perchè il linepoints va fuori dal campo
    aPath.Steps.Delete(0); // elimino la cella di partenza

    preRoll := RndGenerate (aPlayer.Passing);
    Roll := AdjustFatigue (aPlayer.Stamina , preRoll);
    aRnd:= Roll.value ;
    aPlayer.resetALL;

    aFriend := GeTPlayer ( CellX, CellY);
    ToEmptyCell:= 0;
    if aFriend = nil then ToEmptyCell := ToEmptyCellBonusDefending   // ToEmptyCellBonusDefending=1 in brain.create  // sarebbe un intercept bonus
    else begin
      if aFriend.Team <> aPlayer.team then begin
        reason := 'SHP,Destination Player unfriendly:' + 'SERVER_SHP,' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY)  + ',' +tsCmd[1] + ',' + tsCmd[2]  ;//  skillused  tentativo ) ;;
        goto MyExit;
      end;
    end;

    TsScript[incMove].add ('SERVER_SHP,' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY)  + ',' +tsCmd[1] + ',' + tsCmd[2] ) ;//  skillused  tentativo ) ;
    tsSpeaker.Add( aPlayer.Surname + ' cerca di passare la palla' );

    OldBall:= Point ( Ball.CellX , Ball.Celly );

    aPlayer.Stamina := aPlayer.Stamina - cost_shp;
    aPlayer.xp_passing := aPlayer.xp_passing + 1;
    aPlayer.xpTal[TALENT_ID_PLAYMAKER] := aPlayer.xpTal[TALENT_ID_PLAYMAKER] + 1;
    aPlayer.xpDeva := aPlayer.xpDeva + 1; // per il momento solo xpdevA. xpDevt solo shp va a buon fine

    if w_FreeKick1 then begin
      w_FreeKick1:= False;
      w_FreeKickSetup1:= False;
      TeamFreeKick := -1;
      aPlayer := GetFK1 ;
      aPlayer.isFK1  := false;
    end;

    TsScript[incMove].add ('ST,' + aPlayer.ids +',' + intTostr(cost_shp) ) ;  // shp è gratis. gli avversari e i compagni corrono
   // ExceptPlayers.Add(aPlayer);
    TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +','+
    IntTostr(aPlayer.Passing)+',Short.Passing,'+ aPlayer.ids+','+IntTostr(Roll.value) + ',' + Roll.fatigue +'.0' +',0');

    // SHP Precompilo la lista di possibili intercept perchè non si ripetano
    LstIntercepts:= TList<TInteractivePlayer>.create;
    CompileInterceptList (aPlayer.Team{avversari di}, 1{MaxDistance}, aPath, LstIntercepts  );

    for I := 0 to aPath.Count -1 do begin
       // cella per cella o trovo un opponente o trovo un intercept
      OldBall:= Point ( Ball.CellX , Ball.Celly );

      anOpponent:= GeTPlayerOpponent ( aPath[i].X,aPath[i].Y , aPlayer.team );
      if anOpponent <> nil then begin
            ExceptPlayers.Add(anOpponent);
            preRoll2 :=  RndGenerate (anOpponent.Defense + ToEmptyCell) ; // sarebbe un intercept bonus
            Roll2 := AdjustFatigue (anOpponent.Stamina , preRoll2);
            aRnd2:= Roll2.value ;
            TsScript[incMove].add ( 'sc_DICE,' + IntTostr(CellX) + ',' + Inttostr(CellY) +','+  IntTostr(aRnd2) + ','+
            IntTostr(anOpponent.Defense )+ ',Intercept,'+ anOpponent.ids+','+IntTostr(Roll2.value) + ',' + Roll2.fatigue +'.0,' + IntToStr(ToEmptyCell));
            anOpponent.xp_Defense:= anOpponent.xp_Defense + 1;
            anOpponent.xpdevA := anOpponent.xpdevA + 1;  // anche se non riesca a prendere la palla

              if aRnd2 > aRnd then begin // passaggio ---> avversario prende la palla

                  anOpponent.xpdevT := anOpponent.xpdevT + 1; // solo se riesce prende xpdevt
                  OldBall:= Point ( Ball.CellX , Ball.Celly );
                  Ball.Cells := anOpponent.Cells;
                  TsScript[incMove].add ('sc_ball.move,'+ IntTostr(OldBall.X)+','+ IntTostr(OldBall.Y)+','+  IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)
                  +','+anOpponent.Ids+',stop' ) ;

              if (AbsDistance(aPlayer.CellX,aPlayer.CellY, ball.cellX, Ball.CellY ) <=1) then // = 1) or (aPlayer.CellY = aCell.Y) or (aPlayer.CellX = aCell.X) then
//                  if (AbsDistance(aPlayer.CellX,aPlayer.CellY, Ball.CellX ,  Ball.CellY  ) = 1) or (aPlayer.CellY = Ball.CellY) or (aPlayer.CellX = Ball.CellX) then
                    ExceptPlayers.Add(aPlayer);

                  if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then Dec(ShpFree);
                  if (ShpFree < 0) and (aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER)then TeamMovesLeft := TeamMovesLeft - 1; //<--- esaurische shpfree se minore di 0, non uguale


                  reason:='';
                  InputSecureExit ( True, DecNormal );
                  goto MyExit;

              end;
      end

      else begin // no opponent ma possibile intercept su cella vuota

        for Y := 0 to lstIntercepts.count -1 do begin
          anIntercept := lstIntercepts[Y].Player;
                    ExceptPlayers.Add(anIntercept);

          if ( lstIntercepts[Y].Cell.X = aPath[i].X) and (lstIntercepts[Y].Cell.Y = aPath[i].Y) then begin  // se questa cella

            anIntercept.tmp := 0;
            if (anIntercept.TalentId1 = TALENT_ID_BULLDOG) or (anIntercept.TalentId2 = TALENT_ID_BULLDOG) then
              anIntercept.tmp := anIntercept.tmp +1;
            if (anIntercept.TalentId2 = TALENT_ID_ADVANCED_BULLDOG)  then
              anIntercept.tmp := anIntercept.tmp +1;

            BaseIntercept := anIntercept.Defense + anIntercept.tmp + ToEmptyCell -1;
            if BaseIntercept <= 0 then BaseIntercept := 1;
            preRoll2 := RndGenerate (BaseIntercept);
            Roll2 := AdjustFatigue (anIntercept.Stamina , preRoll2);
            aRnd2:=  Roll2.value  ;

            TsScript[incMove].add ( 'sc_DICE,' + IntTostr(CellX) + ',' + Inttostr(CellY) +','+ IntTostr(aRnd2) +',' + IntToStr(anIntercept.Defense )+
            ',Intercept,'+ anIntercept.ids+','+IntTostr(Roll2.value) + ',' + Roll2.fatigue +'.0' + ',' + IntToStr((anIntercept.tmp) + ToEmptyCell -1));
            anIntercept.xp_Defense:= anIntercept.xp_Defense + 1;
            anIntercept.xpTal[TALENT_ID_BULLDOG] := anIntercept.xpTal[TALENT_ID_BULLDOG] + 1;
            anIntercept.xpDeva := anIntercept.xpDeva + 1; // anche se non prende la palla

            //arnd2:=arnd+1;
            if aRnd2 > aRnd then begin // passaggio ---> intercpet prende la palla
              Diff := aRnd2 - aRnd;


              case (Diff)  of
              0..1: begin // prende la palla ma rimbalza in avanti di 1

                     anIntercept.Stamina := anIntercept.Stamina - 3;
                     anIntercept.xpDevT := anIntercept.xpDevT+ 1; // solo se prende la palla
                     oldPlayer := anIntercept.Cells;
                     anIntercept.Cells := Point (aPath[i].X,aPath[i].Y) ;       // il player si posiziona
                     Ball.Cells  := anIntercept.cells;  // posiziona la palla temporaneamente

                     TsScript[incMove].add ('sc_player.move.intercept,'+ anIntercept.Ids +','+IntTostr(oldPlayer.x)+','+ IntTostr(oldPlayer.Y)+','+ IntTostr(anIntercept.CellX)+','+ IntTostr(anIntercept.CellY) ) ;
                     tsSpeaker.Add(anIntercept.Surname +' anticipa ma non controlla');
                    // la palla, che ora è in possesso di chi ha effettuato l'anticipo, rimbalza e finisce in posizione random che calcolo adesso
                     Ball.Cells:= GetBounceCell ( aPlayer.cellX, aPlayer.cellY, Ball.CellX, Ball.CellY,  1, anIntercept.team );

                     // intercept, checkoffside sul bounce a centrocampo
                     aPossibleOffside := GeTPlayer(ball.CellX, Ball.cellY);
                     if checkOffside  ( anIntercept, aPossibleoffside ) then begin
                       reason := '';
                       goto MyExit;
                     end;


                     TsScript[incMove].add ('sc_ball.move,'+ IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+  IntTostr(aPath[i].X)+','+ IntTostr(aPath[i].Y)
                     +','+anIntercept.Ids+',intercept' ) ;
                     TsScript[incMove].add ('sc_bounce,'+ IntTostr(aPath[i].X)+','+ IntTostr(aPath[i].Y)+','+  IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY) +',0' ) ;

                    end;
              2..MAX_LEVEL: begin // si impossessa della palla
                     anIntercept.Stamina := anIntercept.Stamina - 2;
                     anIntercept.xpDevT := anIntercept.xpDevT+ 1; // solo se prende la palla
                     OldBall:= Point ( Ball.CellX , Ball.Celly );
                     oldPlayer := anIntercept.CellS;
                     anIntercept.Cells := point (aPath[i].X,apath[i].Y);   // il player si posiziona
                     Ball.Cells  := anIntercept.Cells; // posiziona la palla

                     TsScript[incMove].add ('sc_player.move.intercept,'+ anIntercept.Ids +','+IntTostr(oldPlayer.X)+','+ IntTostr(oldPlayer.Y)+','+
                                                    IntTostr(anIntercept.CellX)+','+ IntTostr(anIntercept.CellY)  ) ;
                     TsScript[incMove].add ('sc_ball.move,'+ IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+  IntTostr(aPath[i].X)+','+ IntTostr(aPath[i].Y)
                     +','+anIntercept.Ids+',stop' ) ;
                     tsSpeaker.Add(anIntercept.Surname +' anticipa tutti e recupera la palla ');

                    end;
              end;

              if (AbsDistance(aPlayer.CellX,aPlayer.CellY, ball.cellX, Ball.CellY ) <=1) then // = 1) or (aPlayer.CellY = aCell.Y) or (aPlayer.CellX = aCell.X) then
//                    if (AbsDistance(aPlayer.CellX,aPlayer.CellY, Ball.CellX ,  Ball.CellY  ) = 1) or (aPlayer.CellY = Ball.CellY) or (aPlayer.CellX = Ball.CellX) then
                    ExceptPlayers.Add(aPlayer);
                   // aPlayer.resetALL;
                    if aPlayer.Role <> 'G' then Dec(ShpFree);
                    if ShpFree < 0 then TeamMovesLeft := TeamMovesLeft - 1; //<--- esaurische shpfree se minore di 0, non uguale
                    reason := '';
                    InputSecureExit ( True, DecNormal );
                    goto MyExit;
            end;  // if arnd >0 arnd
          end; // if (anIntercept.Cell.X = aPath[i].X) and (anIntercept.Cell.Y = aPath[i].Y) then begin
        end; // Y Lstintercepts
      end; // no opponent ma possibile intercept su cella vuota

         // se arrivo qui significa che la palla SHP non è stata intercettata da nessun opponent o intercept
         // eventuali friend raggiungono la cella vuota, ma solo uno di loro occuperà la cella
         // oppure assegno la palla a chi è sulla cella
        if i = aPath.Count -1 then begin
           Ball.Cells  := Point ( aPath[i].X,aPath[i].Y) ;  // posiziona la palla
           TsScript[incMove].add ('sc_ball.move,'+ IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+  IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY) + ',0,0') ;

           aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
           if checkOffside  ( aPlayer, aPossibleoffside ) then begin
             reason := '';
             goto MyExit;
           end;


         { Playmaker if aplyaer.tal_playmaker shp in area avversaria +N lunghezza passaggio al shot }
//           aPath.count è la lunghezza del passaggio che qui non +è stato intercettato perchè sopra c'è exit sicura
           aFriend := GeTPlayer(ball.CellX, ball.celly);
           aPlayer.xpDevT := aPlayer.xpDevT + 1; // solo se shp riesce
           if aFriend <> nil then begin
              // se riceve la palla, anche in canskill=false perchè in precedenza aveva per es. provato un tackle fallito, ora si resetta.
              aFriend.resetALL;
              aFriend.XpTal [TALENT_ID_RAPIDPASSING] := aFriend.XpTal [TALENT_ID_RAPIDPASSING] + 1;
              aFriend.xpdevA := aFriend.xpdevA + 1;
//              aFriend.xpdevT := aFriend.xpdevT + 1; qui no

              if aPath.Count >= 2 then
                aFriend.XpTal [TALENT_ID_AGILITY] := aFriend.XpTal [TALENT_ID_AGILITY] + 1;

             if (aPlayer.TalentID1 = TALENT_ID_PLAYMAKER ) or (aPlayer.TalentID2 = TALENT_ID_PLAYMAKER ) then begin
             //  aFriend := GeTPlayer(ball.CellX, ball.celly);
             //  if aFriend <> nil then begin
                 if (aFriend.Team = aPlayer.team) and (aFriend.InCrossingArea) then begin

                   aFriend.BonusSHPAREAturn := 1;
                   aFriend.Shot   := aPlayer.Defaultshot + aPath.count + Abs(Integer( (aFriend.TalentId1 = TALENT_ID_BOMB) or (aFriend.TalentId2 = TALENT_ID_BOMB)  ));
                 end;

             //  end;
             end

             else if (aFriend.TalentID1 = TALENT_ID_AGILITY )  or (aFriend.TalentID2 = TALENT_ID_AGILITY ) then begin
                 Inc(fteamMovesleft);
             end
             else if (aFriend.TalentID1 = TALENT_ID_RAPIDPASSING ) or (aFriend.TalentID2 = TALENT_ID_RAPIDPASSING )  then begin
               // cerca un compagno che sia più avanti di lui (aFriend). Se lo trova gli passa la palla. non può essere intercettata
               if RndGenerate(100) <=33 then begin
                 aFriend2 :=  GetFriendAhead( aFriend ) ;
                 if aFriend2 <> nil then begin
                   Ball.Cells  := Point ( aFriend2.cellX,aFriend2.CellY) ;  // posiziona la palla
                   TsScript[incMove].add ('sc_ball.move,'+ IntTostr(aFriend.CellX)+','+ IntTostr(aFriend.CellY)+','+  IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY) + ',0,0') ;

                   if checkOffside  ( aFriend, aFriend2 ) then begin
                     reason := '';
                     goto MyExit;
                   end;

                 end;
               end;
             end;
           end;
           //aPlayer.resetALL;


            if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then
              Dec(ShpFree);
            if (ShpFree < 0) and (aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) then
              TeamMovesLeft := TeamMovesLeft - 1; //<--- esaurische shpfree se minore di 0, non uguale

              if (AbsDistance(aPlayer.CellX,aPlayer.CellY, Ball.cellx, Ball.celly ) <= 1) then // se la muove di 2 o più la può raggiungere e buffarsi
                ExceptPlayers.Add(aPlayer);

            shpBuff := true;  // chi raggiunge la palla ottiene il buff    { TODO : forse se afreind = nil. aggiustare tutto con nuovo talento }
            reason := '';
            InputSecureExit ( True, DecNormal );
            goto MyExit;
        end;

    end; // for  aPath ball
  end // 'SHP'


  // Cella random, Heading, rimbalzo
  else if tsCmd[0] = 'LOP' then  begin
  // Lofted.Pass = Passaggio alto
  //Passaggio alto viene effettuato dal portatore di palla verso un compagno di squadra che si trovi tra 2 e 5 celle di distanza.
  //Se sul percorso della palla sono presenti avversari, questi vengono ignorati. Passaggio alto può terminare su una cella adiacente al
  //compagno che riceve oppure direttamente sul compagno di squadra. Se termina sul compagno questi deve cercare di controllare la palla
  //con Controllo di palla. Prima di ciò eventuali avversari a distanza 1 dalla cella di destinazione innescano passivamente Colpo di testa.
  //Se gli avversari hanno successo la palla rimbalza da 1 a 2 celle di distanza in direzione casuale ma mai verso la propria porta.
  //Dettagli:
  //1 . 5   la palla termina in una cella adiacente e gli avversari possono prenderla ma senza guadagnare il turno
  //6 . 9   la palla termina nellacella giusta ma è soggetta a Colpo di testa difensivo e eventuale Controllo di palla del compagno.
  //Roll 10 la palla viene stoppata dal giocatore senza Colpo di testa difensivi e roll sul Controllo di palla.
  //Passaggio alto VS Colpo di testa

  // Passaggio alto può puntare anche una cella vuota. In questo caso:
  //Dettagli:
  //1 . 5   la palla termina in una cella adiacente ( o altro compagno e avversario o vuota )
    // --> nel caso cada in una cella di un avversario, ball.control +4 a questo avversario.
    //    nel caso ada in una cella di un compagno ball.control-1 e quindi forse bounce (rimbalzo).
    //    nel caso vuota ma sbagliata un avversario si posiziona sulla palla, se è abbastanza vicino.
  //6 . 9   la palla termina esattamente a cellx,celly
  //Roll 10 la palla termina esattamente a cellx,celly e un compagno vicino si posiziona sulla palla (lancio perfetto)


    CellX := StrToIntDef (tsCmd[1],-1);
    CellY := StrToIntDef (tsCmd[2],-1);

    aPlayer := Ball.Player;
    reason := CheckInputLop (aPlayer, CellX, CellY, tsCmd );
    if reason <> '' then goto myexit; // hack


    aFriend := GeTPlayer ( CellX, CellY, aPlayer.Team );
    ToEmptyCell:= 0;
    if aFriend = nil then ToEmptyCell := ToEmptyCellBonusDefending;


    if aFriend <> nil then tsSpeaker.Add( aPlayer.Surname +' cerca un passaggio alto per ' + aFriend.SurName   )
    else  tsSpeaker.Add( aPlayer.Surname +' cerca un passaggio alto'  );

    // aFriend <> nil è un lofted.pass a un compagno, aFriend=nil su cella vuota
  //  Ball.Player := nil;
    preRoll := RndGenerate (aPlayer.Passing );
    Roll := AdjustFatigue (aPlayer.Stamina , preRoll);
    aRnd:= Roll.value ;
    aPlayer.resetALL;
    if debug_SetAlwaysGol then arnd := 20;


    TsScript[incMove].add ('SERVER_LOP,' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY) + ',' +tsCmd[1] + ',' + tsCmd[2] ) ;//  skillused  tentativo
    aPlayer.Stamina := aPlayer.Stamina - cost_lop;
   // aPlayer.xp_passing := aPlayer.xp_passing + 1; giusto cosi'
    aPlayer.xpdevA := aPlayer.xpdevA + 1;
    aPlayer.xpTal[TALENT_ID_LONGPASS] := aPlayer.xpTal[TALENT_ID_LONGPASS] + 1;


    if aPlayer.Team = aPlayer.Field then
      aPlayer.xpTal[TALENT_ID_PLAYMAKER] := aPlayer.xpTal[TALENT_ID_PLAYMAKER] + 1; {  solo il lop nella propria metacampo }

    TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_lop) ) ;
    ExceptPlayers.Add(aPlayer);   //no  unico caso. lop segue l'azione
    if w_FreeKick1 then begin
      w_FreeKick1:= False; // nel caso
      w_FreeKickSetup1:= False;
      TeamFreeKick := -1;
      aPlayer := GetFK1 ;
      aPlayer.isFK1  := false;
    end;

    TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +  ','+
    IntToStr(aPlayer.Passing)+  ',Lofted.Pass,'+ aPlayer.ids+','+IntTostr(Roll.value)+ ','+ Roll.fatigue +'.0' + ',0' );
    if aFriend <> nil then begin
//Dettagli:
//1 . 5   la palla termina in una cella adiacente e gli avversari possono prenderla ma senza guadagnare il turno
//6 . 9   la palla termina nella cella giusta ma è soggetta a Colpo di testa difensivo e eventuale Controllo di palla del compagno.
//10      la palla viene stoppata dal giocatore senza Colpo di testa difensivi e roll sul Controllo di palla.
//Passaggio alto VS Colpo di testa
      ExceptPlayers.Add(aFriend);

      // LOP Precompilo la lista di possibili Heading perchè non si ripetano
      LstHeading:= TList<TInteractivePlayer>.create;
      if (aRnd >= LOP_MIN1) and (aRnd <= LOP_MIN2)   then begin // lop la palla cade in una cella adiacente casuale
        aCell:= GetRandomCell ( CellX, CellY, 1 , false ,true);

        Ball.Cells := aCell;

         aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY ); // verifica fuorigioco
         if checkOffside  ( aPlayer, aPossibleOffside ) then begin
           reason := '';
           goto MyExit;
         end;


        if (AbsDistance(aPlayer.CellX,aPlayer.CellY, aCell.X, aCell.Y ) <=1) then // = 1) or (aPlayer.CellY = aCell.Y) or (aPlayer.CellX = aCell.X) then
          ExceptPlayers.Add(aPlayer); // no ai_moveAll dopo per questo player

        tsSpeaker.Add( aPlayer.Surname +' effettua il passaggio alto sbagliato' );
             TsScript[incMove].add ('sc_lop.no,' + aPlayer.Ids {Lop} + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                            + ',' + IntTostr(aCell.x)+',' + IntTostr(aCell.y));

          // gli heading sono a distanza 1 e possono muoversi sul pallone automaticamente solo se la cella è vuota
          CompileHeadingList (aPlayer.Team{avversari di}, 1{MaxDistance}, aCell.X, aCell.Y, LstHeading  ); // chi può respingere di testa
          if (LstHeading.Count > 1) and  (GeTPlayer (Ball.cellx, ball.celly) = nil )then begin
            anOpponent := LstHeading[0].Player ;
            ExceptPlayers.Add(anOpponent);   // no ai_moveAll dopo per questo player
            oldPlayer.X := anOpponent.CellX ;
            oldPlayer.Y := anOpponent.CellY ;
            anOpponent.CellX := Ball.CellX;   // anOpponent raggiunge la palla
            anOpponent.CellY := Ball.CellY;
            anOpponent.xpDevA := anOpponent.xpDevA + 1;
            // informo il client che muovo il player
            TsScript[incMove].add ('sc_player,'+ anOpponent.Ids +','+IntTostr(oldPlayer.X)+','+ IntTostr(oldPlayer.Y)+','+
                                                IntTostr(anOpponent.CellX)+','+ IntTostr(anOpponent.CellY)  ) ;

          end;

          reason := '';
          InputSecureExit ( True, DecNormal );
          goto MyExit;


      end
      else if (aRnd >= LOP_MID1) and (aRnd <= LOP_MID2)   then begin // la palla cade nella cella del target, ma 1=soggetto a heading e rimbalzerà 2= se heading difensivo va a vuoto, si procede col ball.control del target
          // se non c'è nessuno solo ball.control del target
          tsSpeaker.Add( aPlayer.Surname +' effettua il passaggio alto ' );
          Ball.Cells := Point (CellX, CellY );
         // OldBall:= Point ( Ball.CellX , Ball.Celly );

         aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
         if checkOffside  ( aPlayer, aPossibleOffside ) then begin
           reason := '';
           goto MyExit;
         end;

          CompileHeadingList (aPlayer.Team{avversari di}, 1{MaxDistance}, CellX, CellY, LstHeading  );
          for I := 0 to LstHeading.Count -1 do begin
            aHeadingOpponent := LstHeading[i].Player;
            ExceptPlayers.Add(aHeadingOpponent);
            preRoll2 := RndGenerate (aHeadingOpponent.Heading );
            Roll2 := AdjustFatigue (aHeadingOpponent.Stamina , preRoll2);
            aRnd2:=  Roll2.value;
            tsSpeaker.Add(aHeadingOpponent.Surname +' cerca di colpire la palla per anticipare '+ aFriend.SurName );
            aHeadingOpponent.Stamina := aHeadingOpponent.Stamina - cost_hea;
            TsScript[incMove].add ('sc_ST,' + aHeadingOpponent.ids +',' + IntToStr(cost_hea) ) ;
            aHeadingOpponent.xp_heading := aHeadingOpponent.xp_heading + 1;
            aHeadingOpponent.Stamina := aHeadingOpponent.Stamina - cost_hea;
            aHeadingOpponent.xpDevA := aHeadingOpponent.xpDevA +1; // anche se non prende la palla
            TsScript[incMove].add ( 'sc_DICE,' + IntTostr(CellX) + ',' + Inttostr(CellY) +','+  IntTostr(aRnd2) + ',' +
            IntToStr(aHeadingOpponent.Heading)+  ',Heading,'+aHeadingOpponent.ids+','+IntTostr(Roll2.value) + ',' + Roll2.fatigue + '.0' + ',0' );
            if aRnd2 > aRnd then begin  // lop su friend, se heading difensivo riesce
               // passo la cella dove è avventu il colpo di testa o tentativo
               tsSpeaker.Add(aHeadingOpponent.Surname +' colpisce la palla');
               // swap
               aHeadingOpponent.xpDevT := aHeadingOpponent.xpDevT +1; // respinta di testa riuscita, prende xpdevt

               oldCell := aHeadingOpponent.Cells;
               Ball.CellS:=GetBounceCell ( aPlayer.cellX, aPlayer.cellY, CellX, CellY,  RndGenerate (2), aHeadingOpponent.team );
               TsScript[incMove].add ('sc_lop.heading.bounce,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella} + ',' + aHeadingOpponent.ids{Difesa}
                                                                   + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                                   + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY)
                                                                   + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly) {celle}
                                                                   + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}
               SwapPlayers (aHeadingOpponent,aFriend );
               //bounce
               tsSpeaker.Add('la palla rimbalza da ' + IntTostr(aHeadingOpponent.CellX)+':'+IntTostr(aHeadingOpponent.CellY) +' a ' +  IntTostr(Ball.CellX)+':'+IntTostr(Ball.CellY) );

               // aPlayer.resetALL;
            // se chi riceve il rimbalzo è dello stesso Team
              if Ball.Player <> nil then begin
                if Ball.Player.Team = aPlayer.Team then begin
                  Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                end;
                Ball.Player.Shot := Ball.Player.Shot + 1;
                Ball.Player.BonusFinishingTurn := 1;
                Ball.Player.xpDevA := Ball.Player.xpDevA + 1; // riceve il rimbalzo
              end;


                ExceptPlayers.Add(aPlayer);
                ExceptPlayers.Add(aFriend);
                ExceptPlayers.Add(aHeadingOpponent);
                reason := '';
                InputSecureExit ( True, DecNormal );
                goto MyExit;

            end
            else begin // lop su friend se heading difensivo NON riesce passo al prossimo I lstHeading
               // passo la cella dove è avvenuto il colpo di testa o tentativo
               tsSpeaker.Add(aHeadingOpponent.Surname +' manca la palla di testa');
            end;
          end;

              // se arrivo qui gli heading hanno fallito o non c'erano, quindi ball.control del friend
              // lop su friend --------->>>  BALL.CONTROL

              tsSpeaker.Add(aFriend.Surname +' prova a controllare la palla');
              preRoll3 := RndGenerate (aFriend.BallControl);
              Roll3 := AdjustFatigue (aFriend.Stamina , preRoll3);
              aRnd3 :=  Roll3.value  ;
              aFriend.xp_BallControl := aFriend.xp_BallControl + 1;
              TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aFriend.CellX) + ',' + Inttostr(aFriend.CellY) +','+  IntTostr(aRnd3) + ','+
              IntToStr(aFriend.BallControl)+ ',Ball.Control,'+ aFriend.ids+','+IntTostr(Roll3.value) + ',' + Roll3.fatigue + '.0' + ',0' );
              aFriend.Stamina := aFriend.Stamina - cost_bac;
              aFriend.xpDevA := aFriend.xpDevA + 1;
              aPlayer.xpDevT := aPlayer.xpDevT + 1; // il lop è riuscito
              TsScript[incMove].add ('sc_ST,' + aFriend.ids +',' + IntToStr(cost_hea) ) ;


              if (aRnd3 >= LOP_BC_MIN1) and (aRnd3 <= LOP_BC_MIN2)   then begin //freind non controlla la palla
                   aCell:= GetRandomCell  (  Ball.CellX, Ball.CellY , 1 , false ,true);
                   Ball.Cells := aCell;
                   aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
                   if checkOffside  ( aFriend, aPossibleOffside ) then begin
                     reason := '';
                     goto MyExit;
                   end;
                   tsSpeaker.Add(aFriend.Surname + ' controlla male');

                     TsScript[incMove].add ('sc_lop.ballcontrol.bounce,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                                                             + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                             + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY)
                                                             + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}
                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                    end;

                    reason := '';
                    InputSecureExit ( True, DecNormal );
                    goto MyExit;


              end
              else if (aRnd3 >= LOP_BC_MID1) and (aRnd3 <= LOP_BC_MID2)   then begin // non controlla ma finisce su eventuale cella vuota e la raggiunge
                 aCell:= GetRandomCell  ( Ball.CellX, Ball.CellY , 1, false ,true ); {  : possibile cell=nil }
                   Ball.CellS := aCell;
                   aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
                   if checkOffside  ( aFriend, aPossibleOffside ) then begin
                     reason := '';
                     goto MyExit;
                   end;

                   if GeTPlayer (ball.CellX , ball.celly) = nil then begin

                    TsScript[incMove].add ('sc_lop.ballcontrol.bounce.playertoball,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                             + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                             + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY)
                             + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}

                     aFriend.CellS:= aCell;
                     tsSpeaker.Add(aPlayer.Surname +' controlla e si sposta ');

                      reason := '';
                      InputSecureExit ( True, DecNormal );
                      goto MyExit;

                   end
                   else Begin
                     aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
                     if checkOffside  ( aFriend, aPossibleOffside ) then begin
                       reason := '';
                       goto MyExit;
                     end;
                     TsScript[incMove].add ('sc_lop.ballcontrol.bounce,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                                                           + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                           + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY)
                                                           + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}
                     aFriend.xpDevT := aFriend.xpDevT + 1;

                   End;
              end
              else if (aRnd3 >= LOP_BC_MAX1) and (aRnd3 <= MAX_LEVEL)   then begin // controlla perfettamente
                   TsScript[incMove].add ('sc_lop.ballcontrol.ok10,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                                                           + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                           + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY));
                   tsSpeaker.Add(aFriend.Surname +' controlla');
                   aFriend.xpDevT := aFriend.xpDevT + 2;

                   aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
                   if checkOffside  ( aFriend, aPossibleOffside ) then begin
                     reason := '';
                     goto MyExit;
                   end;

              end;
      end
      else if (aRnd >= LOP_MAX1) and (aRnd <= MAX_LEVEL)   then begin // il passaggio è perfetto, nessun Ball.Control del target e nessun heading difensivo ma, se in shotcell, VOLLEY (tiro al volo)

          // nel caso di non Volley, ma riceve a centrocampo ad esempio, ci sono i buff di ballcontrol+1

           TsScript[incMove].add ('sc_lop.ok10,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                               + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY));
           aPlayer.xpDevT := aPlayer.xpDevT + 1;
           aFriend.xpDevT := aFriend.xpDevT + 1;
           Ball.CellS := Point (CellX, CellY);

             aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
             if checkOffside  ( aPlayer, aPossibleOffside ) then begin
               reason := '';
               goto MyExit;
             end;


              if (AbsDistance(aPlayer.CellX,aPlayer.CellY, ball.cellX, Ball.CellY ) <=1) then
                ExceptPlayers.Add(aPlayer);
              tsSpeaker.Add( aPlayer.Surname +' effettua un passaggio alto perfetto' );

             // Volley  ABSDISTANCE LONTANA minimo 3 e proviene da linea palla o +1
               if (aFriend.InShotCell) and (AbsDistance(aPlayer.CellX ,aPlayer.CellY,  CellX, CellY ) >= VolleyRangeMin ) then Begin
                  if  ( (aPlayer.Team = 0) and (aPlayer.CellX >= CellX) )  or  ( (aPlayer.Team = 1) and (aPlayer.CellX <= CellX) ) then begin
                     // come pos ma +1 bonus tiro (in pratica un prs ma con respinta)
                     // non ci sono heading difensivi in exceptPlayers, quindi difendono come pos
                     // può finire in: sc_pos.bounce, sc_pos.bounce.gk, sc_pos.bounce.crossbar
                    tsSpeaker.Add(aFriend.Surname + ' tira al volo');
                    preRoll2 := RndGenerate (aFriend.Shot + 1); // +1 bonus volley
                    Roll2 := AdjustFatigue (aFriend.Stamina , preRoll2);
                    aRnd2:= Roll2.value;

                    if debug_SetAlwaysGol then arnd2 := 20;
                    aFriend.Stamina := aFriend.Stamina - cost_pos;
                    aFriend.XpdevT := aFriend.XpdevT + 1; // xpdeva gli è stata assegnata sopra durabte il ballcontrol , queso tè un bonus uleriore
                    TsScript[incMove].add ('sc_ST,' +aFriend.ids +',' + IntToStr(cost_pos) ) ;
                    TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aFriend.CellX) + ',' + Inttostr(aFriend.CellY) +','+  IntTostr(aRnd2) +','+
                    IntTostr ( aFriend.Shot + 1)+',Volley,'+ aFriend.ids+','+IntTostr(Roll2.value) + ',' + Roll2.fatigue + '.0' + ',1');
                    ExceptPlayers.Add(aFriend);

                    // qui copiata da SERVER_POS. modificati roll2,3,4 ...
                    // ShotCells
                    //
                      for ii := 0 to ShotCells.Count -1 do begin
                        // la direttiva principale
                        if (ShotCells[ii].DoorTeam <> aPlayer.Team) and
                          (ShotCells[ii].CellX = aPlayer.CellX) and (ShotCells[ii].CellY = aPlayer.CellY) then begin

                        // tra le celle adiacenti, solo la X attuale e ciclo per le Y
                        for c := 0 to  ShotCells[ii].subCell.Count -1 do begin
                          aPoint := ShotCells[ii].subCell[c];
                          anOpponent := GeTPlayerOpponent(aPoint.X ,aPoint.Y, aPlayer.team );

                          if  anOpponent = nil then continue;                                                 // non c'è player sulla cella adiacente
                          ExceptPlayers.Add(anOpponent);

                            if aPlayer.CellX = anOpponent.cellX then Modifier := modifier_defenseShot  else Modifier :=0;
                            preRoll3 := RndGenerate (anOpponent.Defense+Modifier);
                            Roll3 := AdjustFatigue (anOpponent.Stamina , preRoll3);
                            aRnd3:= roll3.value;
                            anOpponent.Stamina := anOpponent.Stamina - cost_defshot;
                            TsScript[incMove].add ( 'sc_DICE,' + IntTostr(anOpponent.CellX) + ',' + Inttostr(anOpponent.CellY) +','+  IntTostr(aRnd3) +','+
                            IntTostr ( anOpponent.Defense ) +',Defense,'+ anOpponent.ids+','+IntTostr(Roll3.value) + ',' + Roll3.fatigue+'.0' + ',' + IntToStr(Modifier));
                            anOpponent.xpDevA := anOpponent.xpDevA + 1; // anche se non prende la palla

                            if aRnd3 > aRnd2 then begin // lop heading ---> avversario prende la palla e c'è il rimbalzo

                              // back o path di tiro non prevede ballmove
                             oldball:= Point ( anOpponent.CellX, anOpponent.CellY);
                             Ball.Cells :=  GetBounceCell ( aPlayer.cellX, aPlayer.CellY, anOpponent.CellX, anOpponent.CellY,  RndGenerate (2),AnOpponent.team );
                             anOpponent.xpDevT := anOpponent.xpDevT + 1;

                              if Modifier <> 0 then begin
                              // un difensore raggiunge chi effettua il POS e fa lo swap
              //                TsScript[incMove].add ('sc_pos.back.bounce,' + aPlayer.ids + ',' + anOpponent.ids +','
              //                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
              //                                              + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
              //                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY ));
                              TsScript[incMove].add ('sc_lop.back.swap.bounce,' + aPlayer.ids + ',' + anOpponent.ids +','
                                                            + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                                            + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
                                                            + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY ));
                              SwapPlayers (aPlayer,anOpponent );
                              end
                              else begin
                              // il tiro raggiunge la cella e rimbalza
                              TsScript[incMove].add ('sc_lop.bounce,' + aPlayer.ids + ',' + anOpponent.ids +','
                                                            + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                                            + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
                                                            + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY ));

                                // se chi riceve il rimbalzo è dello stesso Team
                                if Ball.Player <> nil then begin
                                  if Ball.Player.Team = aPlayer.Team then begin
                                    Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                                  end;
                                  Ball.Player.Shot := Ball.Player.Shot + 1;
                                  Ball.Player.BonusFinishingTurn := 1;
                                  Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                                end;
                              end;
                              reason := '';
                              InputSecureExit ( True, DecNormal );
                              goto MyExit;

                            end;

                        end;
                       end;
                     end;


                      // Qui si arriva per forza al portiere
                        // anOpponent può essere o il portiere
                        // GK
                          aGK := GetOpponentGK ( aPlayer.team);
                          preRoll4 := RndGenerate (aGK.defense); // nessun bonus su volley
                          Roll4 := AdjustFatigue (aGK.Stamina , preRoll4);
                          aRnd4:= roll4.value ;
                          TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aGK.CellX) + ',' + Inttostr(aGK.CellY) +','+  IntTostr(aRnd4) +','+
                          IntTostr ( aGK.defense ) +',Defense,'+ aGK.ids+','+IntTostr(Roll4.value) + ',' + Roll4.fatigue + '.0' + ',0');
                          // o angolo o respinta o gol
                          aGK.Stamina := aGK.Stamina - cost_GKheading;

                          GKxpr:= RndGenerate(100);
                          if GKxpr <= GKXP_REDUCTION then begin
                            aGK.xp_Defense:= aGK.xp_Defense+1;
                            aGK.xpDevA := aGK.xpDevA + 1;
                          end;

              //            goto palo;
                          if aRnd4 > aRnd2 then begin // lop heading ---> il portiere para e c'è il rimbalzo
                             aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2), true );
                             Ball.Cells := aCell;
                            if GKxpr <= GKXP_REDUCTION then begin
                               aGK.xpDevT := aGK.xpDevT + 1;
                            end;

                            // la palla, che ora è in possesso del portiere , rimbalza e finisce in posizione random che calcolo adesso
                              TsScript[incMove].add ('sc_lop.bounce.gk,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
                                                            + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                                            + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                                            + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY)  );

                             tsSpeaker.Add(aGK.Surname +' para e respinge');

                               if Ball.BallisOutside then begin  // POS finisce con rimbalzo del portiere  in corner

                                //aPlayer.resetALL;
                                CornerSetup ( aPlayer );
                                reason :='';
                                goto MyExit;
                               end;
                              // se chi riceve il rimbalzo è dello stesso Team
                              if Ball.Player <> nil then begin
                                if Ball.Player.Team = aPlayer.Team then begin
                                  Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                                end;
                                Ball.Player.Shot := Ball.Player.Shot + 1;
                                Ball.Player.BonusFinishingTurn := 1;
                                Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                              end;

                              reason := '';
                              InputSecureExit ( True, DecNormal );
                              goto MyExit;


                          end

                               // POS finisce con in gol
                          else begin // gol

                                 aPlayer.xpDevT := aPlayer.xpDevT + 1; //come fosse gol , anche palo
                                // ma c'è sempre il palo.
                                if RndGenerate(12) = 12 then begin
              pos_crossbar:
              //aGK := GetOpponentGK ( aPlayer.team);
                                 CrossBarN :=  RndGenerate0 (2);
                                 aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY, RndGenerate (2),false );
                                 Ball.Cells := aCell;
                                 tsSpeaker.Add(' palo ');
                                  {$IFDEF ADDITIONAL_MATCHINFO}
                                    if gameMode = pvp then
                                      MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aFriend.ids)
                                      else MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aFriend.ids+'.'+aFriend.SurName);
                                  {$ENDIF}

                                  TsScript[incMove].add ('sc_lop.bounce.crossbar,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
                                                            + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                                            + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly )+','
                                                            + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' + IntToStr(CrossBarN) );

                                  // POS finisce con rimbalzo del portiere ma non in corner
                                 // aPlayer.resetALL;
                                  // se chi riceve il rimbalzo è dello stesso Team
                                  if Ball.Player <> nil then begin
                                    if Ball.Player.Team = aPlayer.Team then begin
                                      Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                                    end;
                                    Ball.Player.Shot := Ball.Player.Shot + 1;
                                    Ball.Player.BonusFinishingTurn := 1;
                                    Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                                  end;

                                  reason := '';
                                  InputSecureExit ( True, DecNormal );
                                  goto MyExit;
                                end
                                else begin

                                 TsScript[incMove].add ('sc_lop.gol,' + aPlayer.ids + ','+ aFriend.ids + ',' + aGK.ids +','
                                                            + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.celly) + ','
                                                            + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly) +','
                                                            + IntTostr(aGK.cellX)+',' + IntTostr(aGK.cellY)  );

                                  aPlayer.resetPRE ;  // eventuale pressing viene perso DOPO il tiro
                                  inc (Score.gol[aPlayer.team]);
                                  Score.lstGol:= Score.lstGol + IntTostr( Minute ) + '=' + aFriend.Ids + ',';

                                  if GameMode = pvp then
                                    MatchInfo.Add( IntToStr(fminute) + '.golvolley.' + aFriend.ids)
                                    else MatchInfo.Add( IntToStr(fminute) + '.golvolley.' + aFriend.ids+'.'+aFriend.SurName);

                                  LoadDefaultTeamPos ( aGK.Team ) ;
                                  TurnChange(TurnMovesStart);
                                  TsScript[incMove].add ('E') ;
                                  reason :='';
                                  goto MyExit;
                                End;
                          end;


                  end;
               end
               else begin
                //ballcontrol+1, non in shotcell
                  aFriend.BonuslopBallControlTurn := 1;
                  aFriend.BallControl := aFriend.DefaultBallControl + 2;
               end;

      end;

    end


    // --->>>>>   LOP su cella vuota
    else if aFriend = nil then begin
// Passaggio alto può puntare anche una cella vuota. In questo caso:
//Dettagli:
//1 . 5   la palla termina in una cella adiacente ( o altro compagno -2 e avversario +4 o vuota )
// --> avversario ball.control +4 e passa turno. compagno ball.control-2 e forse bouce. vuota ma sbagliata avversario si posiziona sulla palla
//6 . 9   la palla termina esattamente a cellx,celly
//Roll 10 la palla termina esattamente a cellx,celly e un compagno vicino si posiziona sulla palla (lancio perfetto)

       //      aFriend := GetReceiverPlayer ( aPath[i].X,  aPath[i].Y , 1, aPlayer{Tea, CellX, CellY}  );
      // gli heading sono gli intercepts
      LstHeading:= TList<TInteractivePlayer>.create;
//      CompileHeadingList (aPlayer.Team{avversari di}, 1{MaxDistance}, CellX, CellY, LstHeading  );

      if (aRnd >= LOP_MIN1) and (aRnd <= LOP_MIN2)   then begin // lop // la palla cade in una cella adiacente casuale la quale può contenere un avversario, una cella vuota o un compagno
          aCell:= GetRandomCell ( CellX, CellY, 1 , false ,true);

          Ball.Cells := aCell;
          if (AbsDistance(aPlayer.CellX,aPlayer.CellY, ball.cellX, Ball.CellY ) <=1) then
          ExceptPlayers.Add(aPlayer);
          tsSpeaker.Add( aPlayer.Surname +' effettua un passaggio alto a seguire' );

          aGhost := GeTPlayer (CellX, CellY) ;
            if aGhost = nil then begin
              // gli intercept sono a distanza 1 e possono muoversi sul pallone automaticamente
               TsScript[incMove].add ('sc_lop.no,' + aPlayer.Ids {Lop}     + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                                   + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.cellY));


              CompileHeadingList (aPlayer.Team{avversari di}, 1{MaxDistance}, aCell.X, aCell.Y, LstHeading  );
              if (LstHeading.Count > 1) and  (GeTPlayer (Ball.cellx, ball.celly) = nil )then begin
                anOpponent := LstHeading[0].Player ;
                ExceptPlayers.Add(anopponent);
                oldPlayer.X := anOpponent.CellX ;
                oldPlayer.Y := anOpponent.CellY ;
                anOpponent.CellX := Ball.CellX;
                anOpponent.CellY := Ball.CellY;

                TsScript[incMove].add ('sc_player,'+ anOpponent.Ids +','+IntTostr(oldPlayer.X)+','+ IntTostr(oldPlayer.Y)+','+
                                                    IntTostr(anOpponent.CellX)+','+ IntTostr(anOpponent.CellY)  ) ;
              end;
            end
            else if aGhost.Team =  aPlayer.Team then begin    // cella sbagliata compagno ball.control - 2
               aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
               if checkOffside  ( aPlayer, aPossibleOffside ) then begin
                 reason := '';
                 goto MyExit;
               end;

                aFriend := aGhost;
                ExceptPlayers.Add(aFriend);
                tsSpeaker.Add(aFriend.Surname +' prova a controllare la palla' );
                preRoll3 := RndGenerate (aFriend.BallControl);
                Roll3 := AdjustFatigue (aFriend.Stamina , preRoll3);
                aRnd3 := Roll3.value  - 2 ;
                if aRnd3 < 0  then aRnd3 := 1;
                TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aFriend.CellX) + ',' + Inttostr(aFriend.CellY) +','+  IntTostr(aRnd3) + ','+
                IntToStr(aFriend.BallControl )+ ',Ball.Control,'+ aFriend.ids+','+IntTostr(Roll3.value) + ',' + Roll3.fatigue + '.0' + ',-2' );
                 TsScript[incMove].add ('sc_ST,' + aFriend.ids +',' + IntToStr(cost_bac) ) ;
                 aFriend.xp_BallControl := aFriend.xp_BallControl + 1;
                 aFriend.Stamina := aFriend.Stamina - cost_bac;
                 aFriend.xpDevA := aFriend.xpDevA + 1;

                if (aRnd3 >= LOP_BC_MIN1) and (aRnd3 <= LOP_BC_MIN2)   then begin //friend non controlla la palla
                   aCell:= GetRandomCell  (  Ball.CellX, Ball.CellY , 1 , false ,true);
                   Ball.Cells := aCell;
                   aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
                   if checkOffside  ( aFriend, aPossibleOffside ) then begin
                     reason := '';
                     goto MyExit;
                   end;
                   tsSpeaker.Add(aFriend.Surname + ' controlla male ');

                    TsScript[incMove].add ('sc_lop.ballcontrol.bounce,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                                                           + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                           + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY)
                                                           + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}
                end
                else if (aRnd3 >= LOP_BC_MID1) and (aRnd3 <= LOP_BC_MID2)   then begin // controlla ma finisce su eventuale cella vuota e la raggiunge
                   aCell:= GetRandomCell  ( Ball.CellX, Ball.CellY , 1, false  ,true);
                     Ball.CellS := aCell;
                   aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
                   if checkOffside  ( aFriend, aPossibleOffside ) then begin
                     reason := '';
                     goto MyExit;
                   end;

                   if GeTPlayer (ball.CellX , ball.celly) = nil then begin

                     OldPlayer := aFriend.Cells;
                     aFriend.CellS:= aCell;
                     TsScript[incMove].add ('sc_lop.ballcontrol.bounce.playertoball,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                                                         + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                         + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY)
                                                         + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}
                     tsSpeaker.Add(aPlayer.Surname +' controlla e si sposta ');
                     aFriend.xpDevT := aFriend.xpDevT + 1;
                   end
                   else begin
                    TsScript[incMove].add ('sc_lop.ballcontrol.bounce,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                                                         + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                         + ',' + IntTostr(aFriend.cellx)+',' + IntTostr(aFriend.cellY)
                                                         + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}

                   end;
                end
                else if (aRnd3 >= LOP_BC_MAX1) and (aRnd3 <= MAXINT )   then begin // controlla perfettamente

                     aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );
                     if checkOffside  ( aPlayer, aPossibleOffside ) then begin
                       reason := '';
                       goto MyExit;
                     end;
                       TsScript[incMove].add ('sc_lop.ballcontrol.ok10,' + aPlayer.Ids {Lop} + ','+ aFriend.ids{cella}
                                                             + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                             + ',' + IntTostr(ball.cellx)+',' + IntTostr(ball.cellY));
                       tsSpeaker.Add(aFriend.Surname +' controlla');
                       aFriend.xpDevT := aFriend.xpDevT + 1;

                end;
            end
            else if aGhost.Team <> aPlayer.Team then begin        // cella sbagliata avversario ball.control + 4 ruba turno
                  anOpponent := aGhost;
                  ExceptPlayers.Add(anopponent);
                  tsSpeaker.Add(anOpponent.Surname +' prova a controllare la palla');
                  preRoll3 := RndGenerate (anOpponent.BallControl + 4);
                  Roll3 := AdjustFatigue (anOpponent.Stamina , preRoll3);
                  aRnd3 :=  Roll3.value;
                  if aRnd3 < 0  then aRnd3 := 1;
                  TsScript[incMove].add ( 'sc_DICE,' + IntTostr(anOpponent.CellX) + ',' + Inttostr(anOpponent.CellY) +','+  IntTostr(aRnd3) + ','+
                  IntToStr(anOpponent.BallControl)+',Ball.Control,'+ anOpponent.ids+','+IntTostr(Roll3.value)+','+Roll3.fatigue + '.0' + ',4' );
                  anOpponent.Stamina := anOpponent.Stamina - cost_bac;
                  anOpponent.xp_BallControl := anOpponent.xp_BallControl + 1;
                  anOpponent.xpDevA := anOpponent.xpDevA + 1;

                  TsScript[incMove].add ('sc_ST,' + anOpponent.ids +',' + IntToStr(cost_bac) ) ;
                  if (aRnd3 >= LOP_BC_MIN1) and (aRnd3 <= LOP_BC_MIN2) then begin //opponent non controlla la palla
                     aCell:= GetRandomCell  ( Ball.CellX, Ball.CellY , 1, false  ,true);
                     Ball.Cells := aCell;
                     TsScript[incMove].add ('sc_lop.ballcontrol.bounce,' + aPlayer.Ids {Lop} + ','+ anOpponent.ids{cella}
                                                             + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                             + ',' + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.cellY)
                                                             + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}
                     tsSpeaker.Add(anOpponent.Surname + 'controlla male ');
                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                      Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                    end;

                  end
                  else if (aRnd3 >= LOP_BC_MID1) and (aRnd3 <= LOP_BC_MID2) then begin  // controlla ma finisce su eventuale cella vuota e la raggiunge
                     aCell:= GetRandomCell  ( Ball.CellX, Ball.CellY , 1, false  ,true); {  possibile cell=nil }

                     Ball.CellS := aCell;
                     anOpponent.xpDevT := anOpponent.xpDevT + 1;

                     TsScript[incMove].add ('sc_bounce,'+ IntTostr(anOpponent.CellX)+','+ IntTostr(anOpponent.CellY)+','+ IntTostr(aCell.X)+','+ IntTostr(aCell.Y) +',0' ) ;
                     if GeTPlayer (ball.CellX , ball.celly) = nil then begin

                        OldPlayer := anOpponent.Cells;
                        anOpponent.CellS:= aCell;

                         TsScript[incMove].add ('sc_lop.ballcontrol.bounce.playertoball,' + aPlayer.Ids {Lop} + ','+ anOpponent.ids{cella}
                                                           + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                           + ',' + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.cellY)
                                                           + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}
                        tsSpeaker.Add(aPlayer.Surname +' controlla e si sposta a');
                     end
                     else begin
                      TsScript[incMove].add ('sc_lop.ballcontrol.bounce,' + aPlayer.Ids {Lop} + ','+ anOpponent.ids{cella}
                                                           + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                           + ',' + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.cellY)
                                                           + ',' + IntTostr(Ball.cellx)+',' + IntTostr(ball.celly)); {celle}

                      // se chi riceve il rimbalzo è dello stesso Team
                      if Ball.Player <> nil then begin
                        if Ball.Player.Team = aPlayer.Team then begin
                          Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                        end;
                        Ball.Player.Shot := Ball.Player.Shot + 1;
                        Ball.Player.BonusFinishingTurn := 1;
                        Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                      end;
                     end;
                  end
                  else if (aRnd3 >= LOP_BC_MAX1) and (aRnd3 <= MAXINT )   then begin // controlla perfettamente
                              TsScript[incMove].add ('sc_lop.ballcontrol.ok10,' + aPlayer.Ids {Lop} + ','+ anOpponent.ids{cella}
                                                                   + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                                   + ',' + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.cellY));
                             tsSpeaker.Add(anOpponent.Surname +' controlla');
                     anOpponent.xpDevT := anOpponent.xpDevT + 2;
                  end;
            end

      end
      else if (aRnd >= LOP_MID1) and (aRnd <= MAX_LEVEL)   then begin // lop // la palla cade nella cella scelta  e non succede nulla altro
          // se non c'è nessuno solo controllo del target
          TsScript[incMove].add ('sc_ball.move,'+ IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+  IntTostr(CellX)+','+ IntTostr(CellY) +',0,0' ) ;
          tsSpeaker.Add( aPlayer.Surname +' effettua un passaggio alto a seguire' );
          if (AbsDistance(aPlayer.CellX,aPlayer.CellY, ball.cellX, Ball.CellY ) <=1) then
           ExceptPlayers.Add(aPlayer);
          Ball.Cells := Point (CellX, CellY );
         aPossibleOffside := GeTPlayer(Ball.CellX , ball.cellY );

           if checkOffside  ( aPlayer, aPossibleOffside ) then begin
             reason := '';
             goto MyExit;
           end;
      end;

    end;
//      aPlayer.resetALL;
    reason := '';
    InputSecureExit ( True, DecNormal );
    goto MyExit;


  end // LOP



  // Cella random, Heading, rimbalzo , --->  parata, corner , gol
  else if tsCmd[0] = 'CRO'  then  begin
{ il cross è un passaggio alto che può essere interecettato solo di testa. Se il Cross avviene da una cella avanti rispetto alla cella di
  destinazione i colpitori di testa che difendono e il portiere hanno un malus di -2 nel colpire di testa o parare. Se proviene da una cella
  in linea questo modificatore diventa un +1. Se proviene da una cella dietro a quella di destinazione diventa +4.
  Il roll sul passing determina lo sviluppo dell'azione:
//1 . 5   la palla termina in una cella adiacente (
//        occupata da un compagno  --> ha un -1 heading sul confornto con l'avversario il quale può avere già altri bonus di cui sopra)
//        occupata da un avversario -->  l'avversario automaticamente respinge di testa con un bonus +2
//        vuota --> la palla va direttamente al portiere che ottiene il pallone )
//6 . 9   la palla termina esattamente sul compagno a cellx,celly . si va all' heading vs heading
//Roll 10 la palla termina esattamente sul friend a cellx,celly e il compagno ha +1 in heading (cross perfetto).
// La palla può venire respinta dai difensori oppure può viaggiare verso la porta. A quel punto il roll Del portiere determina se è gol o respinta.
// In ogni caso la palla non viene mai bloccata ma viene respinta a distaza massima di 2 celle. C'è anche la possibilità di colpire il palo.

I talenti interessati in questa azione sono:
TALENT_ID_CROSSING  ( +1 crossing )
TALENT_ID_ADVANCED_CROSSING  ( 5% chance di ottenere +2 crossing )
TALENT_ID_PRECISE_CROSSING ( +1 crossing solo dal fondo campo, l'ultima cella )

}

    CellX := StrToIntDef (tsCmd[1],-1);
    CellY := StrToIntDef (tsCmd[2],-1);
    aPlayer := Ball.Player;
    reason := CheckInputCro (aPlayer, CellX, CellY, tsCmd);
    if reason <> '' then goto myexit; // hack

      aPlayer.tmp := CrossingRangeMax;
      if (aPlayer.TalentId1 = TALENT_ID_LONGPASS) or (aPlayer.TalentId2 = TALENT_ID_LONGPASS) then
        aPlayer.tmp := aPlayer.tmp +1;

    aHeadingFriend := GeTPlayer ( CellX, CellY,aPlayer.Team );

    tsSpeaker.Add( aPlayer.Surname +' cerca un cross per ' + aHeadingFriend.SurName   );


    TsScript[incMove].add ('SERVER_CRO,' + aPlayer.Ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY) +',' +IntTostr(CellX)+','+IntToStr(CellY) ) ;
    aPlayer.Stamina := aPlayer.Stamina - cost_cro;
    aplayer.xpDevA := aplayer.xpDevA + 1;
    TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_cro) ) ;
    ExceptPlayers.Add(aPlayer);

    OldBall:= Point ( Ball.CellX , Ball.Celly );

    aPlayer.tmp := 0;
    ACT := '0';
    if (aPlayer.TalentId1 = TALENT_ID_CROSSING) or (aPlayer.TalentId2 = TALENT_ID_CROSSING) then
      aPlayer.tmp:= 1;

    if (aPlayer.TalentId2 = TALENT_ID_ADVANCED_CROSSING)  then
    if RndGenerate(100) <= 5 then begin
      aPlayer.tmp := aPlayer.tmp +2;
      ACT := IntTostr(TALENT_ID_ADVANCED_CROSSING);
    end;

    if aPlayer.TalentId2 = TALENT_ID_PRECISE_CROSSING then begin
      if (aPlayer.CellX = 1)  or (aPlayer.CellY = 10) then begin //cross dal fondo
        aPlayer.tmp:= aPlayer.tmp + 1;
      end;
    end;

    preRoll := RndGenerate (aPlayer.Passing+aPlayer.tmp);  // se undepressure minimo è 1  il talento gli conferisce 1
    Roll := AdjustFatigue (aPlayer.Stamina , preRoll);
    aRnd:= Roll.value ;

    aPlayer.resetALL;
    aPlayer.xpTal[TALENT_ID_CROSSING] :=  aPlayer.xpTal[TALENT_ID_CROSSING] + 1;

    TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) + ','+
    IntToStr(aPlayer.Passing )+',Crossing,'+ aPlayer.ids+','+IntTostr(Roll.value)+','+Roll.fatigue+ '.'+ACT +  ','+IntToStr(aPlayer.tmp)  );

    DefenseHeadingWin:= false;
    BonusDefenseHeading := GetCrossDefenseBonus (aPlayer, CellX, CellY );
    // CRO Precompilo la lista di possibili Heading perchè non si ripetano
    LstHeading:= TList<TInteractivePlayer>.create;
    CompileHeadingList (aPlayer.Team{avversari di}, 1{MaxDistance}, CellX, CellY, LstHeading  );
    if (aRnd >= CRO_MIN1) and (aRnd <= CRO_MIN2)   then begin
       // cross errore la palla cade in una cella adiacente casuale
        aCell:= GetRandomCell ( CellX, CellY, 1 , false ,true);
        Ball.Cells := aCell;

        // devo sapere subito se è su cella vuota perchè va diretta sul portiere
        aGhost := GeTPlayer (aCell.X, aCell.Y) ;
        if aGhost = nil then begin
GK:
          //  ---------->>>      vuota la palla diretta al portiere che blocca
          aGK := GetOpponentGK ( aPlayer.Team );
          Ball.Cells := aGK.Cells;
          TsScript[incMove].add ('sc_ball.move,'+ IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+  IntTostr(aGK.CellX)+','+ IntTostr(aGK.CellY )
          +','+aGK.Ids+',ball.control' ) ;
          tsSpeaker.Add( aPlayer.Surname +' la palla direttamente tra le braccia di ' + aGK.SurName  );
          //aPlayer.resetALL;
          aGK.Stamina := aGK.Stamina - cost_GKprs;// presa semplice
          GKxpr:= RndGenerate(100);
{ TODO :     test gkxpr su molti campionati }
          if GKxpr <= GKXP_REDUCTION then begin
            aGK.xp_Defense:= aGK.xp_Defense+1;
            aGK.xpDevA := aGK.xpDevA + 1;
          end;
          reason := '';
          InputSecureExit ( True, DecNormal );
          goto MyExit;

        end
        else if aGhost.Team =  aPlayer.Team then begin    // cella sbagliata compagno -1 heading friend e bonusdefense attivi
          //  ---------->>>      altro compagno    - 1 heading e avversario ( +altri bonus da posizione)
                 aPossibleOffside := GeTPlayer(aCell.X ,acell.Y );
                 if aPossibleoffside <> nil then begin
                  if isOffside ( aPlayer, aPossibleoffside )   then begin
                    //come fallo freekick1
                    TsScript[incMove].add ('sc_fault,' + aPossibleoffside.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
                    if aPossibleoffside.team = 0 then
                      FreeKickSetup1( 1 ) // aspetta short.passing o lofted.pass
                    else
                      FreeKickSetup1( 0 ); // aspetta short.passing o lofted.pass
                    reason := '';
                    goto MyExit;
                  end;
                 end;

          // HEADING vs HEADING
//HVSH:
          ExceptPlayers.Add(aGhost);
          aHeadingFriend := aGhost;
          Modifier := -1;
          BaseHeadingFriend:= aHeadingFriend.Heading + Modifier;
          if BaseheadingFriend <=0 then BaseHeadingFriend := 1;
          preRoll3 := RndGenerate (BaseHeadingFriend );
          Roll3 := AdjustFatigue (aGhost.Stamina , preRoll3);
          aRnd3 := Roll3.value ;//+ BaseHeadingFriend;
          //HVSH
          goto HVSH;



        end
        else if aGhost.Team  <>  aPlayer.Team then begin    // cella sbagliata avversario respinta diretta di 2
//  ---------->>>      avversario     heading automatico in respinta di 2
              aGK := GetOpponentGK ( aPlayer.Team );
              if aGK.ids = aGhost.Ids then goto GK;


              ExceptPlayers.Add(aGhost);
              Ball.Cells:= GetBounceCell  ( aPlayer.CellX,aPlayer.CellY, CellX, CellY, 2 , aGhost.team);

               TsScript[incMove].add ('sc_cross.headingdef.bounce,' + aPlayer.Ids +',' + aGhost.ids
                                                           + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly)
                                                           + ',' + IntTostr(aGhost.cellx)+',' + IntTostr(aGhost.celly)
                                                           + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));

          aGhost.Stamina := aGhost.Stamina - cost_hea;
          aGhost.xpDevA := aGhost.xpDevA + 1;
          aGhost.xp_Heading := aGhost.xp_Heading + 1;
          aGhost.xpTal[TALENT_ID_HEADING] :=  aGhost.xpTal[TALENT_ID_HEADING] + 1;
          if Ball.BallisOutside then begin
            //  aPlayer.resetALL;
              CornerSetup ( aPlayer );
                reason := '';
                goto MyExit;
          end;

            // se chi riceve il rimbalzo è dello stesso Team
            if Ball.Player <> nil then begin
              if Ball.Player.Team = aPlayer.Team then begin
                Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
              end;
              Ball.Player.Shot := Ball.Player.Shot + 1;
              Ball.Player.BonusFinishingTurn := 1;
              Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
            end;

        end;

        reason := '';
        InputSecureExit ( True, DecNormal );
        goto MyExit;
    end

    else if (aRnd >= CRO_MID1) and (aRnd <= CRO_MID2)   then begin
      //la palla termina esattamente sul friend a cellx,celly . ci sono i bonus della difesa che dipendono dalla posizione e heading vs heading
       //HVSH con certi bonus
         aPlayer.xpDevT := aPlayer.xpDevT + 1;  // cross sulla testa del friend
          aCell.X := CellX;
          aCell.Y := CellY;
          Ball.Cells := aCell;
         aPossibleOffside := GeTPlayer(aCell.X ,acell.Y );
         if aPossibleoffside <> nil then begin
          if isOffside ( aPlayer, aPossibleoffside )   then begin
            //come fallo freekick1
            TsScript[incMove].add ('sc_fault,' + aPossibleoffside.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
            if aPossibleoffside.team = 0 then
              FreeKickSetup1( 1 ) // aspetta short.passing o lofted.pass
            else
              FreeKickSetup1( 0 ); // aspetta short.passing o lofted.pass
            reason := '';
            goto MyExit;
          end;
         end;

          //2              TsScript[incMove].add ('sc_ball.move,'+ IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+  IntTostr(CellX )+','+ IntTostr(CellY) +',1' ) ;
          aHeadingFriend := GeTPlayer(CellX, CellY);
         // BaseHeadingFriend:= aHeadingFriend.Heading ;
          ACT := '0';
          aHeadingFriend.tmp := 0;

          if ( aHeadingFriend.TalentId1 = TALENT_ID_HEADING ) or ( aHeadingFriend.TalentId2 = TALENT_ID_HEADING ) then begin
            if RndGenerate(100) <= 5 then begin
              aHeadingFriend.tmp := aHeadingFriend.tmp +1;
              ACT := IntTostr(TALENT_ID_HEADING);
            end;
          end;
          preRoll3 := RndGenerate (aHeadingFriend.Heading +  aHeadingFriend.tmp); //Modifier := 0;
          Roll3 := AdjustFatigue (aHeadingFriend.Stamina , preRoll3);
          aRnd3 := Roll3.value + aHeadingFriend.tmp ;

          goto HVSH;
    end

    else if (aRnd >= CRO_MAX1) and (aRnd <= MAX_LEVEL)   then begin
      //Roll 10 la palla termina esattamente sul friend a cellx,celly e il compagno ha +1 in heading (lancio perfetto). la difesa ha comunque i suoi bonus
       //HVSH con certi bonus

         aPlayer.xpDevT := aPlayer.xpDevT + 2; // cross perfetto
          aCell.X := CellX;
          aCell.Y := CellY;
          Ball.Cells := aCell;
         aPossibleOffside := GeTPlayer(aCell.X ,acell.Y );
         if aPossibleoffside <> nil then begin
          if isOffside (  aPlayer, aPossibleoffside )   then begin
            //come fallo freekick1
            TsScript[incMove].add ('sc_fault,' + aPossibleoffside.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
            if aPossibleoffside.team = 0 then
              FreeKickSetup1( 1 ) // aspetta short.passing o lofted.pass
            else
              FreeKickSetup1( 0 ); // aspetta short.passing o lofted.pass
            reason := '';
            goto MyExit;
          end;
         end;
          aHeadingFriend := GeTPlayer(CellX, CellY);
          BaseHeadingFriend:= aHeadingFriend.Heading + 1;
          ACT := '0';
          aHeadingFriend.tmp := 0;

          if ( aHeadingFriend.TalentId1 = TALENT_ID_HEADING ) or ( aHeadingFriend.TalentId2 = TALENT_ID_HEADING ) then begin
            if RndGenerate(100) <= 5 then begin
              aHeadingFriend.tmp := aHeadingFriend.tmp +1;  { TODO : convertire in costanti }
              ACT := IntTostr(TALENT_ID_HEADING);
            end;
          end;

          Modifier := 1; { TODO : convertire in costanti }
          preRoll3 := RndGenerate (BaseheadingFriend + aHeadingFriend.tmp + Modifier );
          Roll3 := AdjustFatigue (aHeadingFriend.Stamina , preRoll3);
          aRnd3 := Roll3.value + aHeadingFriend.tmp ;
          goto HVSH;
    end;

     // la palla potrebbe essere uscita o tra le braccia del portiere


//     --> innesca heading vs Heading di tutti gli adiacenti. In caso un difensore vinca l'heading contro il valore fisso dell'attaccante in heading
//          che viene passato, la palla rimbalza in celle predefinite, ma se va in gol è proprietà del portiere ( parata ).
          //  Ball.Player := GeTPlayer (Ball.cellx,Ball.celly);

            // qui heading finale verso il portiere. aRnd è sempre il valore valido
// HEADING OFFENSIVO IN PORTA
HVSH:


            aHeadingFriend.Stamina := aHeadingFriend.Stamina - cost_hea;
            aHeadingFriend.xpDevA := aHeadingFriend.xpDevA + 1;
            TsScript[incMove].add ('sc_ST,' + aHeadingFriend.ids +',' + IntToStr(cost_hea) ) ;
            aHeadingFriend.xp_Heading := aHeadingFriend.xp_Heading + 1;
            aHeadingFriend.xpTal[TALENT_ID_HEADING] :=  aHeadingFriend.xpTal[TALENT_ID_HEADING] + 1;
            ExceptPlayers.Add(aHeadingfriend);
//            goto cro_crossbar;
            // prima i difensori di testa , se falliscono rimane il portiere.

            TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aHeadingFriend.cellx) + ',' + Inttostr(aHeadingFriend.cellY) +','+  IntTostr(aRnd3) + ','+
            IntToStr(aHeadingFriend.Heading)+',Heading,'+aHeadingFriend.ids+','+IntTostr(Roll3.value) + ',' + Roll3.fatigue + '.' + ACT + ',' + IntToStr(Modifier));
                ACT := '0';
              for I := 0 to LstHeading.Count -1 do begin
                aHeadingOpponent := LstHeading[i].Player;
                ExceptPlayers.Add(aHeadingOpponent);

                aHeadingOpponent.tmp := 0;
                ACT :='0';
                if ( aHeadingOpponent.TalentId1 = TALENT_ID_HEADING ) or ( aHeadingOpponent.TalentId2 = TALENT_ID_HEADING ) then begin
                  if RndGenerate(100) <= 5 then begin
                    aHeadingOpponent.tmp := aHeadingOpponent.tmp +1;
                    ACT := IntTostr(TALENT_ID_HEADING);
                  end;
                end;
                BaseHeading :=  aHeadingOpponent.Heading + BonusDefenseHeading;
                if Baseheading <= 0 then Baseheading :=1;

                preRoll2 := RndGenerate (BaseHeading );
                Roll2 := AdjustFatigue (aHeadingOpponent.Stamina , preRoll2);
                aRnd2:=  Roll2.value ;
                aHeadingOpponent.xp_Heading := aHeadingOpponent.xp_Heading + 1;
                aHeadingOpponent.xpTal[TALENT_ID_HEADING] :=  aHeadingOpponent.xpTal[TALENT_ID_HEADING] + 1;
                aHeadingOpponent.Stamina := aHeadingOpponent.Stamina - cost_hea;
                aHeadingOpponent.xpDevA := aHeadingOpponent.xpDevA + 1;

                TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aHeadingOpponent.cellx) + ',' + Inttostr(aHeadingOpponent.cellY) +','+  IntTostr(aRnd2) +','+
                IntToStr(aHeadingOpponent.Heading)+',Heading,'+aHeadingOpponent.ids+','+IntTostr(Roll2.value) + ',' + Roll2.fatigue + '.' +ACT + ','+ IntToStr(BonusDefenseHeading));
                aHeadingOpponent.Stamina := aHeadingOpponent.Stamina - 1;
                TsScript[incMove].add ('sc_ST,' + aHeadingOpponent.ids +',' + '1' ) ;


                if aRnd2 > Arnd3 then begin   //  heading difensivo vince
                  aHeadingOpponent.xpDevT := aHeadingOpponent.xpDevT + 1; // riesce a fare il meglio possibile
                  tsSpeaker.Add(aHeadingOpponent.Surname +' respinge di testa' );
                  SwapPlayers ( aHeadingOpponent, aHeadingFriend);
                   //bounce
                   Ball.Cells:= GetBounceCell  ( aPlayer.CellX,aPlayer.CellY, aHeadingOpponent.CellX, aHeadingOpponent.CellY, 2 , aHeadingOpponent.team);

                   DefenseHeadingWin := true;


                   TsScript[incMove].add ('sc_cross.headingdef.swap.bounce,' + aPlayer.Ids +',' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) {celle}
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));

                   break;
                end;
              //  else begin
              //     TsScript[incMove].add ('sc_ball.move,'+ IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+  IntTostr(aCell.X )+','+ IntTostr(aCell.Y) +',1' ) ;
              //  end;
              end;

              if Ball.BallisOutside then begin
             //   aPlayer.resetALL;
                CornerSetup ( aPlayer );
                reason := '';
                goto MyExit;
              end;

              // se chi riceve il rimbalzo è dello stesso Team
              if Ball.Player <> nil then begin
                if Ball.Player.Team = aPlayer.Team then begin
                  Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                end;
                Ball.Player.Shot := Ball.Player.Shot + 1;
                Ball.Player.BonusFinishingTurn := 1;
                Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
              end;

              if DefenseHeadingWin then begin
            //    aPlayer.resetALL;
                reason := '';
                InputSecureExit ( True, DecNormal );
                goto MyExit;
              end;

              // HEADING vs GK  ---> corner, gol, respinta
//                if Roll3 >= Roll2 then begin

              tsSpeaker.Add(aHeadingFriend.Surname +' colpisce di testa ');

              aGK := GetOpponentGK ( aHeadingFriend.Team );

                BaseGK :=  aGK.Defense + BonusDefenseHeading;
                if BaseGK <= 0 then Baseheading :=1;

              preRoll4 :=  RndGenerate (BaseGK);
              Roll4 := AdjustFatigue (aGK.Stamina , preRoll4);
              aRnd4 := Roll4.value  ;
              aGK.xpTal[TALENT_ID_GoalKeeper] := aGK.xpTal[TALENT_ID_GoalKeeper] + 1;
              //              TsScript[incMove].add ('gkdive,'+ anOpponent.Ids ) ;
              aGK.Stamina := aGK.Stamina - cost_GKheading;
              GKxpr:= RndGenerate(100);
              if GKxpr <= GKXP_REDUCTION then begin
                aGK.xp_Defense:= aGK.xp_Defense+1;
                aGK.xpdevA := aGK.xpdevA + 1;
              end;


              // o angolo o respinta o gol
              TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aGK.CellX) + ',' + Inttostr(aGK.CellY) +','+  IntTostr(aRnd4) +','+
              IntToStr(aGK.Defense)+',Defense,'+ aGK.ids+','+IntTostr(Roll4.value ) + ',' + Roll4.fatigue+ '.0' +',' + IntTostr(BonusDefenseHeading) );

              if aRnd4 > aRnd3 then begin // heading ---> il portiere para e c'è il rimbalzo
                // la palla, che ora è in possesso del portiere , rimbalza e finisce in posizione random che calcolo adesso
              if GKxpr <= GKXP_REDUCTION then begin
                 aGK.xpdevT := aGK.xpdevT + 1;
              end;
                 aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2),true );
                 Ball.Cells := aCell;

                  TsScript[incMove].add ('sc_cross.bounce.gk,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY)  );

                 tsSpeaker.Add(aGK.Surname +' para e respinge');

                 if Ball.BallisOutside then begin  // corner

               //   aPlayer.resetALL;
                  CornerSetup ( aPlayer );
                  reason := '';
                  goto MyExit;
                 end;
                  // se chi riceve il rimbalzo è dello stesso Team
                  if Ball.Player <> nil then begin
                    if Ball.Player.Team = aPlayer.Team then begin
                      Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                    end;
                    Ball.Player.Shot := Ball.Player.Shot + 1;
                    Ball.Player.BonusFinishingTurn := 1;
                    ball.Player.xpDevA := ball.Player.xpDevA + 1;
                  end;

                  reason := '';
                  InputSecureExit ( True, DecNormal );
                  goto MyExit;
              end

              else begin // cross finisce in gol
// GOL

                 // TsScript[incMove].add ('sc_bounce.heading,'+ aHeadingFriend.ids +',' +IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)+','+  IntTostr(aGK.CellX)+','+ IntTostr(aGK.CellY) +',1' ) ;

                  aHeadingFriend.xpDevT := aHeadingFriend.xpDevT + 2;  // sia gol che palo
                  // ma c'è sempre il palo.
                  if RndGenerate(12) = 12 then begin
cro_crossbar:
//aGK := GetOpponentGK ( aHeadingFriend.Team );
                   {$IFDEF ADDITIONAL_MATCHINFO}
                    if GameMode = Pvp then
                      MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aHeadingFriend.ids)
                      else MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aHeadingFriend.ids+'.'+aHeadingFriend.SurName);

                    {$ENDIF}
                   CrossBarN := RndGenerate0 (2);
                   aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2) ,false );
                  // se il portiere è fuori dai pali, la palla può rimbalzare in gol più sotto perchè il GK usa defense
                   Ball.Cells := aCell;
                   TsScript[incMove].add ('sc_cross.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) +','+ IntToStr(CrossBarN) );


                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                      ball.Player.xpDevA := ball.Player.xpDevA + 1;
                    end;

                    reason := '';
                    InputSecureExit ( True, DecNormal );
                    goto MyExit;
                  end;


                   TsScript[incMove].add ('sc_cross.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(aGK.cellX)+',' + IntTostr(aGK.cellY)  );

                  inc (Score.gol [aPlayer.team]);
                  Score.lstGol:= Score.lstGol + IntTostr(Minute) + '=' + aHeadingFriend.Ids + ',';
                  if GameMode = Pvp then
                    MatchInfo.Add( IntToStr(fminute) + '.golcrossing.' + aHeadingFriend.ids)
                    else MatchInfo.Add( IntToStr(fminute) + '.golcrossing.' + aHeadingFriend.ids+'.'+aHeadingFriend.SurName);

                  LoadDefaultTeamPos ( aGK.Team ) ;
                //  aPlayer.resetALL;
                  TurnChange(TurnMovesStart);
                  TsScript[incMove].add ('E') ;

              end;



  end
  // dribbling
  else if tsCmd[0] = 'DRI' then  begin
{  il Dribbling può essere effettuato verso un avversario adiacente. vengono messi a confronto il ballcontrol del portatore di palla contro
  la difesa di chi subisce il dribbling. Se il dribbling riesce con valore maggiore o uguale a DribblingDiff (2) il player avanza di una
  cella nella direzione del dribbling se tale cella è vuota. Il dribbling parte con un malus -2 su ballcontrol.

  Talenti interessati:
  TALENT_ID_DRIBBLING   ( +1 dribbling )
  TALENT_ID_ADVANCED_DRIBBLING  ( +2 totale dribbling )
  TALENT_ID_SUPER_DRIBBLING  ( 15% chance dribbling +3  )
}


    CellX := StrToIntDef (tsCmd[1],-1);
    CellY := StrToIntDef (tsCmd[2],-1);
    aPlayer := Ball.Player ;
    anOpponent := GeTPlayerOpponent ( CellX, CellY,  aPlayer.team );

    reason := CheckInputDri (aPlayer, CellX, CellY, tsCmd);
    if reason <> '' then goto myexit; // hack

      ExceptPlayers.Add(anOpponent);

      aPlayer.canDribbling := false;
       // cell per eventuale spostamento e calcolo direzione
      OldCell := aPlayer.Cells;

       aPath:= dse_pathplanner.TPath.create;
       dstCell.X  := -1;
       GetNextDirectionCell (aPlayer.CellX , aPlayer.CellY, Ball.Cellx, Ball.Celly,1,aPlayer.Team,true,true, aPath  ) ;
       if aPath.Count > 0 then begin
         dstCell.X := aPath[aPath.Count-1].X;
         dstCell.Y := aPath[aPath.Count-1].Y;
       end;


       TsScript[incMove].add ('SERVER_DRI,' + aPlayer.ids  + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY) + ',' +tsCmd[1] + ',' + tsCmd[2] ) ;//  skillused  tentativo) ;
       aPlayer.Stamina := aPlayer.Stamina - cost_dri;
       aPlayer.xpdevA := aPlayer.xpDevA + 1;
       TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_dri) ) ;
       aPlayer.xpTal[TALENT_ID_DRIBBLING] :=  aPlayer.xpTal[TALENT_ID_DRIBBLING] + 1;
       ExceptPlayers.Add(aPlayer);

      aPlayer.tmp := 0;
      ACT := '0';
      if (aPlayer.TalentId1 = TALENT_ID_DRIBBLING) or (aPlayer.TalentId2 = TALENT_ID_DRIBBLING) then
        aPlayer.tmp := aPlayer.tmp +1;
      if (aPlayer.TalentId2 = TALENT_ID_ADVANCED_DRIBBLING)  then
        aPlayer.tmp := aPlayer.tmp +1;
      if (aPlayer.TalentId2 = TALENT_ID_SUPER_DRIBBLING)  then begin
        if RndGenerate(100) <= 15 then begin
          aPlayer.tmp := aPlayer.tmp + 3;
          ACT := IntTostr (TALENT_ID_SUPER_DRIBBLING);
        end;
      end;

       preRoll := RndGenerate (aPlayer.BallControl + aPlayer.tmp);
       Roll := AdjustFatigue (aPlayer.Stamina , preRoll);
       aRnd:=  Roll.value  -DRIBBLING_MALUS ;
       if aRnd < 0 then aRnd := 0;

       aPlayer.resetALL;

       preRoll2 := RndGenerate (anOpponent.Defense);
       Roll2 := AdjustFatigue (anOpponent.Stamina , preRoll2);
       aRnd2:= Roll2.value ;
       anOpponent.xp_Defense :=  anOpponent.xp_Defense + 1;
       anOpponent.stamina :=  anOpponent.stamina - cost_defdrib;
       anOpponent.xpDevA := anOpponent.xpDevA + 1;
       if aRnd2 < 0 then aRnd2 :=0;
        TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +','+
        IntToStr(aPlayer.BallControl) +',Ball.Control,'+  aPlayer.ids+','+IntTostr(Roll.value) + ',' + Roll.fatigue+ '.'+ACT +',-2');

        TsScript[incMove].add ( 'sc_DICE,' + IntTostr(anOpponent.CellX) + ',' + Inttostr(anOpponent.CellY) +','+  IntTostr(aRnd2) +',' +
        IntToStr(anOpponent.Defense) +',Defense,'+ anOpponent.ids+','+IntTostr(Roll2.value) + ',' + Roll2.fatigue+ '.0' + ',0');


      if ( aRnd >= aRnd2 )  then begin // dribbling ---> player riesce nel dribbling

        //arnd:= 12;
            // guadagna 1 cella se il punteggio è alto
        if( (aRnd-aRnd2) >= DRIBBLING_DIFF ) and (dstCell.X <> -1)  then begin // si sposta in avanti

            aPlayer.xpdevT := aPlayer.xpdevT + 2; // premio massimo

            TsScript[incMove].add ('sc_dribbling.ok10,' + aPlayer.ids{sfidante} +',' + anOpponent.ids {cella}
                                              + ',' + IntTostr(aPlayer.CellX)+',' + IntTostr(aPlayer.CellY)
                                              + ',' + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.cellY)
                                              + ',' + IntTostr(dstCell.x)+',' + IntTostr(dstCell.Y)  ) ;
            aPlayer.Cells := dstCell;
            Ball.CellS := dstCell;

        end
        else begin

            aPlayer.xpdevT := aPlayer.xpdevT + 1; // premio normale
            TsScript[incMove].add ('sc_dribbling.ok,' + aPlayer.ids{sfidante} +',' + anOpponent.ids {cella}
                                              + ',' + IntTostr(aPlayer.CellX)+',' + IntTostr(aPlayer.CellY)
                                              + ',' + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.cellY)
                                              + ',' + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.cellY)  ) ;
          SwapPlayers ( aPlayer, anOpponent );
          Ball.Cells := aPlayer.Cells;
          tsSpeaker.Add( aPlayer.Surname +' (Dribbling) vince il dribbling su ' + anOpponent.Surname );
        end;

        if (aPlayer.TalentId1 = TALENT_ID_BOMB) or (aPlayer.TalentId2 = TALENT_ID_BOMB) then
         aPlayer.tmp := 1;

         aPlayer.Shot   := aPlayer.Defaultshot + 1 + aPlayer.tmp; // se vince dribbling +1 shot
         aPlayer.Passing   := aPlayer.DefaultPassing + 2 ;

      end

      else begin

        anOpponent.xpDevT := anOpponent.xpDevT + 1;
            TsScript[incMove].add ('sc_dribbling.no,' + aPlayer.ids{sfidante} +',' + anOpponent.ids {cella}
                                              + ',' + IntTostr(aPlayer.CellX)+',' + IntTostr(aPlayer.CellY)
                                              + ',' + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.cellY)
                                              + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.cellY)  ) ;
        tsSpeaker.Add( aPlayer.Surname +' (Dribbling) perde il dribbling su ' + anOpponent.Surname );
      end;

      reason := '';
      InputSecureExit ( True, DecNormal );
      goto MyExit;



  end

  // Power shot
  else if tsCmd[0] = 'POS' then  begin

    aPlayer:= Ball.Player;
    aDoor:= GetOpponentDoor (Ball.Player );
    CellX := aDoor.X;
    CellY := aDoor.Y;
    reason := CheckInputPos (aPlayer, CellX, CellY, tsCmd);
    if reason <> '' then goto myexit; // hack


    tsSpeaker.Add(  aPlayer.Surname +' tira in porta'   );
    BaseShotChance := CalculateBasePowerShot( aPlayer );
    preRoll := RndGenerate (BaseShotChance.Value);
    Roll := AdjustFatigue (aPlayer.Stamina , preRoll);
    Kind :=  BaseShotChance.aString;

    TsScript[incMove].add (BaseShotChance.aString2 + ',' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY) + ',' +
                                                                                    IntToStr( aDoor.X) +',' + IntToStr( aDoor.Y));

    Ball.Player.xpTal[TALENT_ID_BOMB] :=  Ball.Player.xpTal[TALENT_ID_BOMB] + 1;
    Ball.Player.xp_Shot  := Ball.Player.xp_Shot + 1;
    aRnd:= Roll.value;// + BaseShot  ;

    if debug_SetAlwaysGol then arnd := 20;

    aPlayer.Stamina := aPlayer.Stamina - cost_pos;
    aPlayer.xpDevA := aPlayer.xpDevA + 1;
    aPlayer.xpTal[TALENT_ID_FREEKICKS] :=  aPlayer.xpTal[TALENT_ID_FREEKICKS] + 1;

    TsScript[incMove].add ('sc_ST,' +aPlayer.ids +',' + IntToStr(cost_pos) ) ;
    TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +','+
    IntTostr ( BaseShotChance.Value)+',Power.Shot,'+ Ball.Player.ids+','+IntTostr(Roll.value ) + ',' + Roll.fatigue + '.0'+ ',' + IntToStr(BaseShotChance.Modifier) );
    ExceptPlayers.Add(aPlayer);
    aPlayer.resetALL;

      // ShotCells in caso di tiro normale, altrimenti o barriera o rigore
      //
    if w_FreeKick3 then begin
      Barrier := true;
      w_FreeKick3:= False;
      w_FreeKickSetup3:= False;
      TeamFreeKick := -1;
      aPlayer.isFK3  := false;
      aPlayer.xpTal[TALENT_ID_FREEKICKS] :=  aPlayer.xpTal[TALENT_ID_FREEKICKS] + 1; // 1 punto aggountivo a quello di default

     // le shotcells vensgono ignorate. la barriera respinge o il gk respinge o gol. può essere corner. la barriera viene rotta dopo il tiro
      (* il roll della barriera. Sono tutti i player presenti nella cella barriera *)
      aCellBarrier:= GetBarrierCell( TeamTurn, Ball.CellX, Ball.CellY);

      for I := Players.Count -1 downto 0 do begin
        anOpponent := Players[i];
        if (anOpponent.CellX = aCellBarrier.X)  and (anOpponent.CellY = aCellBarrier.Y) then begin
          preRoll2 := RndGenerate (anOpponent.Defense);
          Roll2 := AdjustFatigue (anOpponent.Stamina , preRoll2);
          aRnd2:= roll2.value ;
          anOpponent.xp_Defense := anOpponent.xp_Defense + 1;
          anOpponent.Stamina := anOpponent.Stamina - cost_defshot;
          TsScript[incMove].add ( 'sc_DICE,' + IntTostr(anOpponent.CellX) + ',' + Inttostr(anOpponent.CellY) +','+  IntTostr(aRnd2) +','+
          IntTostr ( anOpponent.Defense  ) +',Defense,'+ anOpponent.ids+','+IntTostr(Roll2.value) + ',' + Roll2.fatigue+ '.0' +',0');

         // oldball:= Point ( anOpponent.CellX, anOpponent.CellY);
          if aRnd2 > aRnd then begin  // la barriera respinge

            anOpponent.xpDevA := anOpponent.xpDevA + 1;
            anOpponent.xpDevT := anOpponent.xpDevT + 1;
            Ball.Cells :=  GetBounceCell ( aPlayer.cellX, aPlayer.CellY, anOpponent.CellX, anOpponent.CellY,  RndGenerate (2),AnOpponent.team );

            // il tiro raggiunge la cella e rimbalza
            TsScript[incMove].add ('sc_pos.bounce,' + aPlayer.ids + ',' + anOpponent.ids +','
                                            + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                            + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
                                            + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY ));

              (* Disfo la barriera *)
              Barrier := false;
              DeflateBarrier ( aCellBarrier, anOpponent );

              // se chi riceve il rimbalzo è dello stesso Team
              if Ball.Player <> nil then begin
                if Ball.Player.Team = aPlayer.Team then begin
                  Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                end;
                Ball.Player.Shot := Ball.Player.Shot + 1;
                Ball.Player.BonusFinishingTurn := 1;
              end;
            // POS3 finisce con rimbalzo della difesa grazie a intercept

            //if TeamMovesLeft <= 0 then TurnChange  (TurnMoves);  ??????????
            reason := '';
            InputSecureExit ( True, DecNormal );
            goto MyExit;
          end

        end;
      end;
         // Qui va per forza al portiere con server_pos, server_pos3, dopo dovrò svuotare la barriera
         Barrier := True;   // la barriera esiste ancora
         goto POSvsGK;

     // la barriera viene svuotata qui. i player trovano una cella libera e nel client spritereset (false) fa il resto
    end
    else if w_FreeKick4 then begin
      w_FreeKick4:= False; // nel caso
      w_FreeKickSetup4:= False;
      aPlayer.isFK4  := false;
      TeamFreeKick := -1;
      aGK := GetOpponentGK ( aPlayer.team);
      aGK.tmp := 0;
      ACT := '0';
      if (aGK.TalentId2 = TALENT_ID_GKPENALTY) then begin
        if RndGenerate(100) <= 10 then begin
          aGK.tmp := 1;
          ACT :=  IntTostr  ( TALENT_ID_GKPENALTY );
        end;
      end;
      penalty := true;

    // jump diretto al pos vs gk
      goto POSvsGK;
    end
    else begin
    // SE NON E' PRESENTE UN PLAYER, INTERVIENE DALLA CELLA ADIACENTE MA CON UN MALUS
    if debug_Setposcrosscorner then goto posvsgk;

        for ii := 0 to ShotCells.Count -1 do begin
          // la direttiva principale
          if (ShotCells[ii].DoorTeam <> aPlayer.Team) and
            (ShotCells[ii].CellX = aPlayer.CellX) and (ShotCells[ii].CellY = aPlayer.CellY) then begin

          // tra le celle adiacenti, solo la X attuale e ciclo per le Y
          for c := 0 to  ShotCells[ii].subCell.Count -1 do begin
            aPoint := ShotCells[ii].subCell.Items [c];
            anOpponent := GeTPlayerOpponent (aPoint.X ,aPoint.Y, aPlayer.Team);

            if  anOpponent = nil then continue;                                                 // non c'è player sulla cella adiacente
            ExceptPlayers.Add(anOpponent);

              if aPlayer.CellX = anOpponent.cellX then Modifier := modifier_defenseShot else Modifier :=0;
              preroll2 := RndGenerate (anOpponent.Defense);
              Roll2 := AdjustFatigue (anOpponent.Stamina , preRoll2);
              aRnd2:= roll2.value +  Modifier;
              anOpponent.xp_Defense := anOpponent.xp_Defense + 1;
              anOpponent.Stamina := anOpponent.Stamina - cost_defshot;
              TsScript[incMove].add ( 'sc_DICE,' + IntTostr(anOpponent.CellX) + ',' + Inttostr(anOpponent.CellY) +','+  IntTostr(aRnd2) +','+
              IntTostr ( anOpponent.Defense ) +',Defense,'+ anOpponent.ids+','+IntTostr(Roll2.value)+','+Roll2.fatigue+ '.0' +','+IntToStr(Modifier) );

              if aRnd2 > aRnd then begin // power.Shot ---> avversario prende la palla e c'è il rimbalzo

                // back o path di tiro non prevede ballmove
               anOpponent.xpDevA := anOpponent.xpDevA + 1;
               anOpponent.xpDevT := anOpponent.xpDevT + 1;
               oldball:= Point ( anOpponent.CellX, anOpponent.CellY);
               Ball.Cells :=  GetBounceCell ( aPlayer.cellX, aPlayer.CellY, anOpponent.CellX, anOpponent.CellY,  RndGenerate (2),AnOpponent.team );

                if Modifier <> 0 then begin
                // un difensore raggiunge chi effettua il POS e fa lo swap
//                TsScript[incMove].add ('sc_pos.back.bounce,' + aPlayer.ids + ',' + anOpponent.ids +','
//                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
//                                              + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
//                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY ));
                TsScript[incMove].add ('sc_pos.back.swap.bounce,' + aPlayer.ids + ',' + anOpponent.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY ));
                SwapPlayers (aPlayer,anOpponent );
                end
                else
                // il tiro raggiunge la cella e rimbalza
                TsScript[incMove].add ('sc_pos.bounce,' + aPlayer.ids + ',' + anOpponent.ids +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY ));

                // se chi riceve il rimbalzo è dello stesso Team
                if Ball.Player <> nil then begin
                  if Ball.Player.Team = aPlayer.Team then begin
                    Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                  end;
                  Ball.Player.Shot := Ball.Player.Shot + 1;
                  Ball.Player.BonusFinishingTurn := 1;
                  Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                end;

                  // POS finisce con rimbalzo della difesa grazie a intercept
                reason := '';
                InputSecureExit ( True, DecNormal );
                goto MyExit;

              end;

          end;
         end;
       end;
    end;
    (* --------------------------------------------------------------------------------------------------------------------  *)
        // Qui si arriva per forza al portiere con server_pos, server_pos3
          // anOpponent può essere o il portiere
          // GK
POSvsGK:
            aGK := GetOpponentGK ( aPlayer.team);
            preRoll2 := RndGenerate (aGK.defense + (BonusPowerShotGK[aPlayer.CellX]) );
            Roll2 := AdjustFatigue (aGK.Stamina , preRoll2);
            aRnd2:= roll2.value; // eventuale talento sui pos + aGK.tmp;
            if debug_Setposcrosscorner then aRnd2:=20;

            aGK.Stamina := aGK.Stamina - cost_GKpos;
            GKxpr:= RndGenerate(100);
            if GKxpr <= GKXP_REDUCTION then begin
              aGK.xpDevA := aGK.xpDevA + 1;
              aGK.xp_Defense := aGK.xp_Defense + 1;
            end;

            aGK.xpTal[TALENT_ID_GoalKeeper] := aGK.xpTal[TALENT_ID_GoalKeeper] + 1;
            TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aGK.CellX) + ',' + Inttostr(aGK.CellY) +','+  IntTostr(aRnd2) +','+
            IntTostr ( aGK.defense ) +',Defense,'+ aGK.ids+','+IntTostr(Roll2.value)+','+Roll2.fatigue+ '.0'+',0');
            // o angolo o respinta o gol
//            goto palo;
            if aRnd2 > aRnd then begin // power.Shot ---> il portiere para e c'è il rimbalzo
               if Kind = '.golpos4.' then begin
                 if GameMode = pvp then
                  MatchInfo.Add( IntToStr(fminute) + '.pos4fail.' + aPlayer.ids)
                  else MatchInfo.Add( IntToStr(fminute) + '.pos4fail.' + aPlayer.ids+'.'+aPlayer.SurName);

              if GKxpr <= GKXP_REDUCTION then begin
                 aGK.xpDevT := aGK.xpDevT + 2;
              end
               end
               else begin
              if GKxpr <= GKXP_REDUCTION then begin
                aGK.xpDevT := aGK.xpDevT + 1;
              end;
               end;

               aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2), true );

      if debug_Setposcrosscorner then begin
        if aGK.cellX = 0 then
          aCell := Point(0,1)
          else aCell := Point(11,1);
      end;

               Ball.Cells := aCell;
              // la palla, che ora è in possesso del portiere , rimbalza e finisce in posizione random che calcolo adesso
                TsScript[incMove].add ('sc_pos.bounce.gk,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) );

               tsSpeaker.Add(aGK.Surname +' para e respinge');
                 if debug_Setposcrosscorner then goto setCorner;
                 if Ball.BallisOutside then begin  // POS finisce con rimbalzo del portiere  in corner
setCorner:
//                  aPlayer.resetALL;
                   CornerSetup ( aPlayer );
                   reason:='';
                   goto MyExit;
                 end;
                  // se chi riceve il rimbalzo è dello stesso Team
                  if Ball.Player <> nil then begin
                    if Ball.Player.Team = aPlayer.Team then begin
                      Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                    end;
                    Ball.Player.Shot := Ball.Player.Shot + 1;
                    Ball.Player.BonusFinishingTurn := 1;
                    Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                  end;

                  reason := '';
                  InputSecureExit ( True, DecNormal );
                  goto MyExit;

            end

                 // POS finisce con in gol
            else begin // gol

                  aPlayer.xpDevT := aPlayer.xpDevT + 2;
                  // ma c'è sempre il palo.
                  if RndGenerate(12) = 12 then begin

//aGK := GetOpponentGK ( aPlayer.team);
                   CrossBarN := RndGenerate0(2);
                   aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2),false );
                   Ball.Cells := aCell;
                   tsSpeaker.Add(' palo ');
                                  {$IFDEF ADDITIONAL_MATCHINFO}
                                    if GameMode = pvp then
                                      MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aPlayer.ids)
                                      else MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aPlayer.ids+'.'+aPlayer.SurName);

                                    {$ENDIF}

                    TsScript[incMove].add ('sc_pos.bounce.crossbar,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly )+','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(CrossBarN) );

                    // POS finisce con rimbalzo del portiere ma non in corner
//                    aPlayer.resetALL;
                // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                      Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                    end;

                    reason := '';
                    InputSecureExit ( True, DecNormal );
                    goto MyExit;
                  end
                  else begin

                    TsScript[incMove].add ('sc_pos.gol,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly) +','
                                              + IntTostr(aGK.cellX)+',' + IntTostr(aGK.cellY) + ',' +IntTostr(RndGenerate(2)) );
                    aPlayer.resetPRE ;  // eventuale pressing viene perso DOPO il tiro
                    inc (Score.gol[aPlayer.team]);
                    Score.lstGol:= Score.lstGol + IntTostr(Minute) + '=' + aPlayer.Ids + ',';

                    if GameMode = pvp then
                      MatchInfo.Add( IntToStr(fminute) + kind + aPlayer.ids)
                      else MatchInfo.Add( IntToStr(fminute) + kind + aPlayer.ids+'.'+aPlayer.SurName);


                    LoadDefaultTeamPos ( aGK.Team ) ;
                    TurnChange(TurnMovesStart);
                    TsScript[incMove].add ('E') ;
                    reason:='';
                    goto MyExit;
                  End;
            end;


  end
  // Precision shot
  // è come Power.shot ma senza rimbalzi e qundi corner
  else if tsCmd[0] = 'PRS' then  begin

  // non è uguale a pos. rimbalzo a e non a 2
    aPlayer:= Ball.Player;
    penalty:= false;
    aDoor:= GetOpponentDoor (Ball.Player );
    CellX := aDoor.X;
    CellY := aDoor.Y;
    reason := CheckInputPrs(aPlayer, CellX, CellY, tsCmd);
    if reason <> '' then goto myexit; // hack

    tsSpeaker.Add(  aPlayer.Surname +' tira in porta'   );
    BaseShotChance := CalculateBasePrecisionShot (  aPlayer ); // punizione bonus +1 fisso  o rigore o normale
    Kind :=  BaseShotChance.aString;
    preRoll := RndGenerate (BaseShotChance.Value);
    Roll := AdjustFatigue (aPlayer.Stamina , preRoll);

    Ball.Player.xp_Shot  := Ball.Player.xp_Shot + 1;

    aRnd:= Roll.value ;//+ BaseShot  ;
    aPlayer.resetall;
    if debug_SetAlwaysGol then arnd := 20;

    TsScript[incMove].add (BaseShotChance.aString2 + ',' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY)+ ',' +
                                                                                  IntToStr( aDoor.X) +',' + IntToStr( aDoor.Y));
    aPlayer.Stamina := aPlayer.Stamina - cost_prs;
    aPlayer.xpDevA := aPlayer.xpDevA + 1;
    ExceptPlayers.Add(aPlayer);

    TsScript[incMove].add ('sc_ST,' +aPlayer.ids +',' + inttostr(cost_prs) ) ;
    TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +','
    + IntToStr(aPlayer.Shot)+',Precision.Shot,'+ Ball.Player.ids+','+IntTostr(Roll.value)+','+Roll.fatigue+ '.0'+','+IntToStr(BaseShotChance.Modifier));

    //    goto prs_crossbar;

    if w_FreeKick3 then begin
      Barrier := true;
      w_FreeKick3 := false;
      w_FreeKickSetup3:= False;
      TeamFreeKick := -1;
      //aPlayer := GetFK3 ;
      aPlayer.isFK3  := false;
      aPlayer.xpTal[TALENT_ID_FREEKICKS] :=  aPlayer.xpTal[TALENT_ID_FREEKICKS] + 1;
      Kind := '.golprs3.';
     // le shotcells vensgono ignorate. la barriera respinge o il gk respinge o gol. può essere corner. la barriera viene rotta dopo il tiro

      (* il roll della barriera. Sono tutti i player presenti nella cella barriera *)
      aCellBarrier:= GetBarrierCell( TeamTurn, Ball.CellX, Ball.CellY);

      for I := Players.Count -1 downto 0 do begin
        anOpponent := Players[i];
        if (anOpponent.CellX = aCellBarrier.X)  and (anOpponent.CellY = aCellBarrier.Y) then begin
          preRoll2 := RndGenerate ( anOpponent.Defense );
          Roll2 := AdjustFatigue (anOpponent.Stamina , preRoll2);
          aRnd2:= roll2.value ;
          anOpponent.xp_Defense := anOpponent.xp_Defense + 1;
          anOpponent.Stamina := anOpponent.Stamina - cost_defshot;
          TsScript[incMove].add ( 'sc_DICE,' + IntTostr(anOpponent.CellX) + ',' + Inttostr(anOpponent.CellY) +','+  IntTostr(aRnd2) +','+
          IntTostr ( anOpponent.Defense ) +',Defense,'+ anOpponent.ids+','+IntTostr(Roll2.value) + ',' + Roll2.fatigue+ '.0' + ','+IntToStr(BaseShotChance.Modifier));

          if aRnd2 > aRnd then begin

            anOpponent.xpDevA := anOpponent.xpDevA + 1;
            anOpponent.xpDevT := anOpponent.xpDevT + 1;
            Ball.cells:= Point ( anOpponent.CellX, anOpponent.CellY);

            // il tiro raggiunge la cella barriera e viene catturata
            TsScript[incMove].add ('sc_prs.stealball,' + aPlayer.ids + ',' + anOpponent.ids{sfidante} +','
                                          + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                          + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
                                          + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) );

            (* Disfo la barriera *)
            Barrier := false;
            DeflateBarrier ( aCellBarrier, anOpponent );


            // PRS3 finisce con rimbalzo della difesa grazie a intercept
            //if TeamMovesLeft <= 0 then TurnChange  (TurnMoves); ?????
            reason := '';
            InputSecureExit ( True, DecNormal );
            goto MyExit;
          end;
        end;
      end;
         // Qui va per forza al portiere con server_pos, server_pos3, dopo dovrò svuotare la barriera
         Barrier := True;   // la barriera esiste ancora
         goto PRSvsGK;

     // la barriera viene svuotata qui. i player trovano una cella libera e nel client spritereset (false) fa il resto
    end
    else if w_FreeKick4 then begin
    // jump diretto al pos vs gk
      w_FreeKickSetup4 := false; // comunque
      w_FreeKick4 := false; // comunque
      TeamFreeKick := -1;
//      aPlayer := GetFK4 ;
      aPlayer.isFK4  := false;
      aGK := GetOpponentGK ( aPlayer.team);
      aGK.tmp := 0;
      ACT := '0';
      if (aGK.TalentId2 = TALENT_ID_GKPENALTY) then begin
        if RndGenerate(100) <= 10 then begin
          aGK.tmp := 1;
          ACT :=  IntTostr  ( TALENT_ID_GKPENALTY );
        end;
      end;
      penalty := true;
      goto PRSvsGK;
    end
    else begin
      // ShotCells
      //
        for ii := 0 to ShotCells.Count -1 do begin
          // la direttiva principale
          if (ShotCells[ii].DoorTeam <> aPlayer.Team) and
            (ShotCells[ii].CellX = aPlayer.CellX) and (ShotCells[ii].CellY = aPlayer.CellY) then begin

          // tra le celle adiacenti, solo la X attuale e ciclo per le Y
          for c := 0 to  ShotCells[ii].subCell.Count -1 do begin
            aPoint := ShotCells[ii].subCell.Items [c];
            anOpponent := GeTPlayerOpponent(aPoint.X ,aPoint.Y ,  aPlayer.team );

            if  anOpponent = nil then continue;
            ExceptPlayers.Add(anOpponent);
              if aPlayer.CellX = anOpponent.cellX then Modifier := -1 else Modifier :=0;
              preRoll2 := RndGenerate (anOpponent.Defense );
              Roll2 := AdjustFatigue (anOpponent.Stamina , preRoll2);
              aRnd2:= roll2.value + Modifier;
              anOpponent.Stamina := anOpponent.Stamina - cost_defshot;
              anOpponent.xp_Defense := anOpponent.xp_Defense + 1;
              TsScript[incMove].add ( 'sc_DICE,' + IntTostr(anOpponent.CellX) + ',' + Inttostr(anOpponent.CellY) +','+  IntTostr(aRnd2) +','+
              IntTostr (anOpponent.Defense)+',Defense,'+ anOpponent.ids+','+IntTostr(Roll2.value)+','+Roll2.fatigue+ '.0' +','+IntToStr(Modifier));

              if aRnd2 > aRnd then begin // precision.Shot ---> avversario prende la palla

                anOpponent.xpDevA := anOpponent.xpDevA + 1;
                anOpponent.xpDevT := anOpponent.xpDevT + 1;

               // Assegno la nuova posizione  della palla
                Ball.cells:= Point ( anOpponent.CellX, anOpponent.CellY);

                if Modifier <> 0 then
                // un difensore raggiunge chi effettua il PRS
                TsScript[incMove].add ('sc_prs.back.stealball,' + aPlayer.ids + ',' + anOpponent.ids{sfidante} +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly)+','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) )
                else
                // il tiro raggiunge la cella e viene catturata
                TsScript[incMove].add ('sc_prs.stealball,' + aPlayer.ids + ',' + anOpponent.ids{sfidante} +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(anOpponent.cellx)+',' + IntTostr(anOpponent.celly) +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) );


                // PRS finisce con cattura della difesa
//                aPlayer.resetALL;
                reason := '';
                InputSecureExit ( True, DecNormal );
                goto MyExit;

              end;

          end;
         end;
       end;
    end;

        // Qui si arriva per forza al portiere
          // anOpponent può essere o il portiere
          // GK
PRSvsGK:
            ACT := '0';
            aGK := GetOpponentGK ( aPlayer.team); // se penalty forse tmp = 1
            if (AbsDistance( aGK.CellX, aGK.CellY, aPlayer.CellX,aPlayer.cellY) = 1)  and ( not penalty ) then begin   // prs ravvicinato (non rigore)
             // ACT := '0';
              if (aGK.TalentId2 = TALENT_ID_GKMIRACLE) then begin
                if RndGenerate(100) <= 10 then begin
                  aGK.tmp := 2;
                  ACT :=  IntTostr  ( TALENT_ID_GKMIRACLE );
                end;
              end;

            end;

            preRoll2 := RndGenerate (aGK.defense + BonusPrecisionShotGK[aPlayer.CellX]);
            Roll2 := AdjustFatigue (aGK.Stamina , preRoll2);
            aRnd2:= roll2.value + aGK.tmp; // talento
            aGK.xpTal[TALENT_ID_GoalKeeper] := aGK.xpTal[TALENT_ID_GoalKeeper] + 1;
            aGK.Stamina := aGK.Stamina - cost_GKprs;
            GKxpr:= RndGenerate(100);
            if GKxpr <= GKXP_REDUCTION then begin
            aGK.xp_Defense:= aGK.xp_Defense+1;
            aGK.xpDevA := aGK.xpDevA + 1;
            end;
            // o gol o presa
              TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aGK.CellX) + ',' + Inttostr(aGK.CellY) +','+  IntTostr(aRnd2) +','+
              IntTostr ( aGK.defense ) +',Defense,'+ aGK.ids+','+IntTostr(Roll2.value)+','+Roll2.fatigue+ '.' +ACT +',0');
            if aRnd2 > aRnd then begin // power.Shot ---> il portiere para


               if Kind = '.golprs4.' then begin
                 if GameMode = pvp then
                   MatchInfo.Add( IntToStr(fminute) + '.prs4fail.' + aPlayer.ids)
                     else MatchInfo.Add( IntToStr(fminute) + '.prs4fail.' + aPlayer.ids+'.'+aPlayer.SurName);

              if GKxpr <= GKXP_REDUCTION then begin
                 aGK.xpDevT := aGK.xpDevT + 2
              end;
               end
               else begin
              if GKxpr <= GKXP_REDUCTION then begin
               aGK.xpDevT := aGK.xpDevT + 1;
              end;
               end;
              // la palla,  ora è in possesso del portiere

               Ball.Cells := aGK.Cells;
               tsSpeaker.Add(aGK.Surname +' para');
                TsScript[incMove].add ('sc_prs.gk,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  + ','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) );

              // PRS finisce con palla al portiere
//              aPlayer.resetALL;
              reason := '';
              InputSecureExit ( True, DecNormal );
              goto MyExit;
            end

                 // PRS finisce con in gol
            else begin // gol

                  // ma c'è sempre il palo.
                  aPlayer.xpdevT := aPlayer.xpdevT + 1;
                  if RndGenerate(12) = 12 then begin
                   // non torna mai Corner
prs_crossbar:
//aGK := GetOpponentGK ( aPlayer.team);
                   {$IFDEF ADDITIONAL_MATCHINFO}
                   if GameMode = pvp then
                   MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aPlayer.ids)
                     else MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aPlayer.ids+'.'+aPlayer.SurName);

                    {$ENDIF}
                   CrossbarN := RndGenerate0(2);
                   aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  1 ,false);  //<--- prs 1 rimbalzo debole
                   Ball.Cells := aCell;
                   TsScript[incMove].add ('sc_prs.bounce.crossbar,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)+','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(CrossbarN) );

                    // PRS finisce col palo con rimbalzo
                 //   aPlayer.resetLBC ;      { TODO : strano }
                 //   aPlayer.resetPRE ;
                  //  aPlayer.resetPRO ;
                 //   aPlayer.resetSHP ;
                  //  aPlayer.resetPLM ;

                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                      Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                    end;

                    reason := '';
                    InputSecureExit ( True, DecNormal );
                    goto MyExit;
                  end
                  else begin

                    TsScript[incMove].add ('sc_prs.gol,' + aPlayer.ids + ',' + aGK.ids{sfidante} +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly) +','
                                              + IntTostr(aGK.cellX)+',' + IntTostr(aGK.cellY)+ ',' +IntTostr(RndGenerate(2)) );
                    aPlayer.resetPRE ;  // eventuale pressing viene perso DOPO il tiro
                    inc (Score.gol[aPlayer.team]);
                    Score.lstGol:= Score.lstGol + IntTostr(Minute) + '=' + aPlayer.Ids + ',';
                   if GameMode = pvp then
                   MatchInfo.Add( IntToStr(fminute) + kind + aPlayer.ids)
                     else MatchInfo.Add( IntToStr(fminute) + kind + aPlayer.ids+'.'+aPlayer.SurName);
                    LoadDefaultTeamPos ( aGK.Team ) ;
                    TurnChange(TurnMovesStart);
                    TsScript[incMove].add ('E') ;
                    reason:='';
                    goto MyExit;
                  End;
            end;



  end

  else if tsCmd[0] = 'PRE' then  begin
{ l'azione pressing può essere effettuata da un player adiacente al portatore di palla. Abbassa l'attributo ballcontrol di -2.
  Talenti interessati:
  TALENT_ID_EXPERIENCE   ( pressing non costa mosse durante il turno )
  TALENT_ID_ADVANCED_EXPERIENCE  ( pressing costa in stamina cost_pre - 1 )

}


    aPlayer := GeTPlayer ( tsCmd[1]);
    reason := CheckInputPre(aPlayer, tsCmd);
    if reason <> '' then goto MyExit;


    TsScript[incMove].add ('SERVER_PRE,' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY) + ',' + IntToStr(Ball.Player.CellX) + ',' + IntToStr(Ball.Player.CellY) ) ;
    TsScript[incMove].add ('ST,' + aPlayer.ids +',' + IntToStr(cost_pre) ) ; // pressing costa come tackle. molto.
    aPlayer.Stamina := aPlayer.Stamina - cost_pre;
    aPlayer.xpDevA := aPlayer.xpDevA + 1;
    if aPlayer.TalentId2 = TALENT_ID_ADVANCED_EXPERIENCE then
      aPlayer.Stamina := aPlayer.Stamina + 1;

    aPlayer.xpTal[TALENT_ID_EXPERIENCE] :=  aPlayer.xpTal[TALENT_ID_EXPERIENCE] + 1;
    aPlayer.xpTal[TALENT_ID_AGGRESSION] :=  aPlayer.xpTal[TALENT_ID_AGGRESSION] + 1;
   // if aPlayer.YellowCard > 0 then asm int 3; end;

    Ball.Player.xpTal[TALENT_ID_ACE] :=  aPlayer.xpTal[TALENT_ID_ACE] + 1;
    ExceptPlayers.Add(aPlayer);

    if (absDistance (aPlayer.CellX , aPlayer.CellY, Ball.Cellx, Ball.Celly  ) = 1) then begin
      aPlayer.canSkill := false;
      aPlayer.canMove := false;
      aPlayer.PressingDone:= True;


      if (Ball.Player.TalentId1 = TALENT_ID_ACE) or (Ball.Player.TalentId2 = TALENT_ID_ACE) then begin
        aRnd  :=  RndGenerate(100);
        if aRnd <= 33 then begin

            TsScript[incMove].add ('sc_dribbling.ok,' +  Ball.Player.ids{sfidante} +',' + aPlayer.ids {cella}
                                              + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)
                                              + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.cellY)
                                              + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.cellY)  ) ;
          // un po' diverso, non posso setballcell ball.player perchè è un getplayer
          aPlayer2 := Ball.Player;
          SwapPlayers ( aPlayer2 , aPlayer );
          Ball.Cells := aPlayer2.Cells;

          tsSpeaker.Add( Ball.Player.Surname +' (ACE Dribbling) vince il dribbling su ' + aPlayer.Surname );

        end
        else goto Normalpressing;
      end
      else begin
Normalpressing:
        Ball.Player.UnderPressureTurn := 2;
        Ball.Player.CanMove := False;  // NON PUO' MUOVERE , ma può dribblare con -2

        Ball.Player.BallControl  := Ball.Player.BallControl - PRE_VALUE;  //  MINIMO 1, mai in negativo
        if Ball.Player.BallControl <= 0 then  Ball.Player.BallControl := 1;

        Ball.Player.Passing  := Ball.Player.passing - PRE_VALUE;
        if Ball.Player.Passing <= 0 then  Ball.Player.Passing := 1;

        Ball.Player.Shot := Ball.Player.Shot - PRE_VALUE;
        if Ball.Player.Shot <= 0 then  Ball.Player.Shot := 1;

        Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
        tsSpeaker.Add( aPlayer.Surname +' (Pressing) fa pressing su ' + Ball.Player.ids {cella}  ) ;
      end;

        if (aPlayer.TalentId1 = TALENT_ID_EXPERIENCE) or (aPlayer.TalentId2 = TALENT_ID_EXPERIENCE) then begin // se non ga il talento Experience
          Minute := Minute + 1; // il minuto passa anche se non ha costo la skill
        end else TeamMovesLeft := TeamMovesLeft - 1;

      reason := '';
      InputSecureExit(True,DecNone ); // doaimoveall, TeamMovesLeft l'ha fatto sopra in base al talento
      goto MyExit;

    end;
  end
  else if tsCmd[0] = 'PRO' then  begin

    aPlayer := Ball.Player;
    reason := CheckInputPro(aPlayer, tsCmd);
    if reason <> '' then goto MyExit;


    TsScript[incMove].add ('SERVER_PRO,' + aPlayer.ids + ',' + IntToStr(aPlayer.cellX) + ',' + IntToStr(aPlayer.cellY)+ ',' + IntToStr(aPlayer.cellX) + ',' + IntToStr(aPlayer.cellY) ) ;
    aPlayer.Stamina := aPlayer.Stamina - cost_pro;
    aPlayer.xpDevA := aPlayer.xpDevA + 1;
    TsScript[incMove].add ('ST,' + aPlayer.ids +',' + IntToStr(cost_pro) ) ;
    aPlayer.xpTal[TALENT_ID_POWER] :=  aPlayer.xpTal[TALENT_ID_POWER] + 1;

    ExceptPlayers.Add(aPlayer);
    aPlayer.BonusProtectionTurn := 2;
    aPlayer.BallControl := aPlayer.BallControl + PRO_VALUE;
    aPlayer.CanMove := false;
    aPlayer.CanSkill := false;

    reason := '';
    InputSecureExit ( False, DecNormal );
    goto MyExit;
  end

  else if tsCmd[0] = 'STAY' then  begin
    aPlayer := GeTPlayer ( tsCmd[1]);
    reason := CheckInputStay (aPlayer, tsCmd);
    if reason <> '' then goto myexit; // hack


    TsScript[incMove].add ('SERVER_STAY,' + aPlayer.ids ) ;
    aPlayer.stay := True;
    reason := '';
    InputSecureExit ( False, DecNoResetPlayer );
    goto MyExit;
  end
  else if tsCmd[0] = 'FREE' then  begin
    aPlayer := GeTPlayer ( tsCmd[1]);
    reason := CheckInputFree (aPlayer, tsCmd);
    if reason <> '' then goto myexit; // hack

    TsScript[incMove].add ('SERVER_FREE,' + aPlayer.ids ) ;
    aPlayer.stay := false;
    reason := '';
    InputSecureExit ( False, DecNoResetPlayer );
    goto MyExit;
  end

  else if tsCmd[0] = 'TAC' then  begin

//Contrasto (1)
//Contrasto viene effettuato solo verso il giocatore avversario portatore di palla e quando questi si trova a 1 cella di distanza.
//Un giocatore può effettuare solo un Contrasto per turno. Il portatore di palla si difende con Difesa. In caso di successo il
//giocatore si impossessa della palla e scambia la propria posizione col portatore di palla. Nel caso Contrasto abbia successo e
//non sia stato preceduto da Pressing sul portatore di palla, il costo dell’abilità si riduce a 0. Nel caso il valore casuale di
//Contrasto sia superiore a Difesa di 2 o più, il giocatore vince il Contrasto e, se possibile, avanza di 1 cella nella direzione
// attuale. Effettuare un Contrasto da dietro alza moltissimo la probabilità di fare fallo con possibili infortuni e/o cartellini.
    aPlayer := GeTPlayer ( tsCmd[1] );
    reason := CheckInputTac (aPlayer, tsCmd);
    if reason <> '' then goto myexit; // hack

    TsScript[incMove].add('SERVER_TAC,' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY)+ ',' + IntToStr(Ball.Player.CellX) + ',' + IntToStr(Ball.Player.CellY) ) ;


    Isfault := exec_tackle ( tsCmd[1]) ;
    case Isfault of
      0:Begin   // non è fallo
        reason := '';
        InputSecureExit ( True, DecNormal );
        goto MyExit;
      end;
      1:Begin    // normale nella propria metacampo
        // allontano i player avversari, batterà il ball.player che può essere anche injured. se viene sostituito? tutto ok, ci va sopra

        TsScript[incMove].add ('sc_fault,' + aPlayer.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
        FreeKickSetup1(ball.Player.team); // aspetta short.passing o lofted.pass
        reason := '';
        goto MyExit;
      end;
      2:Begin    // cross offensivo
        TsScript[incMove].add ('sc_fault,' + aPlayer.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
        FreeKickSetup2(ball.Player.team); // aspetta crossing
        reason := '';
        goto MyExit;
      end;
      3:Begin    // barriera
        TsScript[incMove].add ('sc_fault,' + aPlayer.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
        FreeKickSetup3(ball.Player.team);  // aspetta pos o prs
        reason := '';
        goto MyExit;
      end;
      4:Begin    // rigore
        TsScript[incMove].add ('sc_fault,' + aPlayer.Ids +',' + IntTostr(Ball.CellX) +','+IntTostr(Ball.CellY) ) ; // informo il client del fallo
        FreeKickSetup4(ball.Player.team); // aspetta pos o prs
        reason := '';
        goto MyExit;
      end;
    end;

  end
  else if tsCmd[0] = 'TACTIC' then  begin

//        aPlayer.DefaultCellS  := point (CellX,CellY);
//        MoveInDefaultField(aPlayer);

    aPlayer := GeTPlayer ( tsCmd[1]);
    CellX := StrToIntDef (tsCmd[2],-1);
    CellY := StrToIntDef (tsCmd[3],-1);
    reason := CheckInputTactic (aPlayer, CellX, CellY, tsCmd);
    if reason <> '' then goto myexit; // hack

    TsScript[incMove].add ('SERVER_TACTIC,' + aPlayer.ids + ',' + IntToStr(aPlayer.defaultCellX) + ',' + IntToStr(aPlayer.defaultCellY) + ',' + tsCmd[2] + ',' + tsCmd[3]) ;
    aPlayer.DefaultCells := Point(CellX,CellY);

    TsScript[incMove].add ('sc_tactic,' + aPlayer.ids + ',' + IntToStr(aPlayer.defaultCellX) + ',' + IntToStr(aPlayer.defaultCellY) + ',' + tsCmd[2] + ',' + tsCmd[3]) ;
    TsScript[incMove].add ('sc_TML,' + IntTostr(FTeamMovesLeft) + ',' + IntTostr(TeamTurn)+ ',' + IntToStr(ShpFree) ) ;    // non incremento i minuti ma le mosse decrementano

    reason := '';
    InputSecureExit ( False, DecNoResetPlayer );
    goto MyExit;



  end
  else if tsCmd[0] = 'SUB' then  begin
  // si fanno sempre anche oltre 120+

//        aPlayer.DefaultCellS  := point (CellX,CellY);
//        MoveInDefaultField(aPlayer);
    aPlayer := GeTPlayerReserve ( tsCmd[1]);
    aPlayer2 := GeTPlayer ( tsCmd[2]);

    reason := CheckInputSub (aPlayer, aPlayer2, tsCmd);
    if reason <> '' then goto myexit; // hack

    CellX := aPlayer2.cellX;
    CellY := aPlayer2.cellY;



    TsScript[incMove].add ('SERVER_SUB,' + aPlayer.ids + ',' +  aPlayer2.ids);

    aPlayer.Role := aPlayer2.role;
    SwapPlayers  ( aPlayer, aPlayer2 );
    SwapDefaultPlayers  ( aPlayer, aPlayer2 );
    SwapFormationPlayers  ( aPlayer, aPlayer2 );

//          PutInReserveSlot(aPlayer2);
    aPlayer2.Role := 'N';
    aPlayer2.Gameover := true;
    aPlayer2.PlayerOut := true;
    AddSoccerPlayer(aPlayer);
    RemoveSoccerReserve(aPlayer);

    AddSoccerGameOver(aPlayer2);
    RemoveSoccerPlayer(aPlayer2);

    Score.TeamSubs[aPlayer2.Team]:= Score.TeamSubs[aPlayer2.Team] + 1;
    TsScript[incMove].add ('sc_sub,' + aPlayer.ids  + ',' + aPlayer2.ids) ;

    TsScript[incMove].add ('sc_TML,' + IntTostr(FTeamMovesLeft) + ',' + IntTostr(TeamTurn)+ ',' + IntToStr(ShpFree) ) ;    // non incremento i minuti
    reason := '';
    InputSecureExit ( False, DecNoResetPlayer );
    goto MyExit;

    if GameMode = pvp then
      MatchInfo.Add( IntToStr(fminute) + '.sub.' + aPlayer.ids + '.' + aPlayer2.ids  )
      else MatchInfo.Add( IntToStr(fminute) + '.sub.' + aPlayer.ids + '.' + aPlayer.SurName + '.' + aPlayer2.ids + '.' + aPlayer2.SurName);
    goto MyExit;



  end


  else if tsCmd[0] = 'PLM' then  begin
    aPlayer := GeTPlayer ( tsCmd[1]);
    CellX := StrToIntDef (tsCmd[2],-1);
    CellY := StrToIntDef (tsCmd[3],-1);
    reason := CheckInputPlm (aPlayer, CellX, CellY, tsCmd);
    if reason <> '' then goto myexit; // hack



    // controllo client del movimento
    aPlayer.Stamina := aPlayer.Stamina - cost_plm;
    ExceptPlayers.Add(aPlayer);
    TsScript[incMove].add ('SERVER_PLM,' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY) + ',' + tsCmd[2] + ',' + tsCmd[3]) ;
    TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;
    aPlayer.xp_speed := aPlayer.xp_speed + 1;

    if  aPlayer.HasBall then begin
      MoveValue := aPlayer.Speed -1;
      if MoveValue <=0 then MoveValue:=1;

      FriendlyWall := true;
      OpponentWall := true;
      FinalWall := true;
    end
    else begin
      aPlayer.xpTal[TALENT_ID_POSITIONING] :=  aPlayer.xpTal[TALENT_ID_POSITIONING] + 1; // solo senza palla
      MoveValue := aPlayer.Speed ;
      FriendlyWall := false;
      OpponentWall := false;
      FinalWall := true;
    end;

    // qui per via della fatigue il path potrebbe essere, in base al roll, non raggiungibile. check normale speed o speed-1
    // questo valida l'intenzione
      GetPath (aPlayer.Team , aPlayer.CellX , aPlayer.CellY, CellX, CellY,
                              MoveValue{Limit},false{useFlank},FriendlyWall{FriendlyWall},
                              OpponentWall{OpponentWall},FinalWall{FinalWall},TruncOneDir{OneDir}, aPlayer.MovePath );

    if aPlayer.MovePath.Count = 0 then begin // aggiuntivo , va bene qui e non in checinputplm
      TsScript[incMove].add ('E');
      reason := 'PLM,Path not found Ts:'+ tsCmd.CommaText;
      goto myexit; // hack
    end;

    Roll :=  AdjustFatigue(aPlayer.Stamina , MoveValue);// tips utile per 2 tipo di chiamata -1 -2 -3
    MoveValue := Roll.value;

    GetPath (aPlayer.Team , aPlayer.CellX , aPlayer.CellY, CellX, CellY,
                              MoveValue{Limit},false{useFlank},FriendlyWall{FriendlyWall},
                              OpponentWall{OpponentWall},FinalWall{FinalWall},TruncOneDir{OneDir}, aPlayer.MovePath );

    TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(Roll.value) +','+
    IntTostr ( aPlayer.Speed ) +',Speed,'+ aPlayer.ids+','+IntTostr(Roll.value)+','+Roll.fatigue+ '.0'+',0');

    if aPlayer.MovePath.Count = 0 then begin  // USCITA per via del roll con fatigue
      ExceptPlayers.Add(aPlayer);
      reason := '';
      InputSecureExit ( true, DecNormal );
      goto MyExit;
    end;



    // PLM Precompilo la lista di possibili autotackle perchè non si ripetano
    LstAutoTackle:= TList<TInteractivePlayer>.create;
    if( aPlayer.HasBall ) and (  aPlayer.MovePath.count > 0) then begin// solo se si muove di 2 o più ? > 1
      CompileAutoTackleList (aPlayer.Team{avversari di}, 1{MaxDistance},  aPlayer.MovePath, LstAutoTackle  );
    end;


    for I := 0 to aPlayer.MovePath.Count -1 do begin

       // se ha la palla, la palla si sposta con il player

       if aPlayer.HasBall then begin //aPlayer.HasBall then begin   se il player AVEVA la palla
          TsScript[incMove].add ('sc_ball.move,'+ IntTostr(Ball.CellX)+','+IntTostr(Ball.CellY) +','+
                                            IntTostr(aPlayer.MovePath [i].X)+','+IntTostr(aPlayer.MovePath [i].Y)+',0,0' );

          TsScript[incMove].add ('sc_player.move,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
          IntTostr(aPlayer.MovePath [i].X)+','+ IntTostr(aPlayer.MovePath [i].Y)  ) ;

          aPlayer.CellX :=  aPlayer.MovePath[i].X;
          aPlayer.CellY :=  aPlayer.MovePath[i].Y;
          tsSpeaker.Add(aPlayer.surname + ' porta palla' );


          Ball.Cells := aPlayer.Cells;// aPath [i];



       end
       // se NON ha la palla
       else begin
          TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
          IntTostr(aPlayer.MovePath [i].X)+','+ IntTostr(aPlayer.MovePath [i].Y)  ) ;

          aPlayer.CellX :=  aPlayer.MovePath[i].X;
          aPlayer.CellY :=  aPlayer.MovePath[i].Y;
          tsSpeaker.Add(aPlayer.surname + ' si muove' );
       end;

       for P := 0 to LstAutoTackle.Count -1 do begin
         if (LstAutoTackle[P].Cell.X = aPlayer.MovePath[i].X) and (LstAutoTackle[P].Cell.Y = aPlayer.MovePath[i].Y) then begin // se la cella lo riguarda. questo fa la giusta animazione

            if exec_autotackle ( LstAutoTackle[P].Player.ids,(i = aPlayer.MovePath.Count-1) ) then goto plmautotackledone;// ultimo path se i = aPlayer.MovePath.Count-1

         end;
       end;
    end;


  plmautotackledone:
      if LstAutoTackle <> nil then begin
        for I := LstAutoTackle.count -1 downto 0 do begin
          LstAutoTackle[i].free;
        end;
        LstAutoTackle.free;
      end;
    aPlayer.resetALL;
    if (aPlayer.MovePath.Count >= 2) and ( aPlayer.HasBall )  then begin
     aPlayer.BonusPLMTurn := 1;
     aPlayer.tmp:=0;
     if (aPlayer.TalentId1 = TALENT_ID_BOMB) or (aPlayer.TalentId2 = TALENT_ID_BOMB) then
      aPlayer.tmp:=1;
     aPlayer.Shot   := aPlayer.Defaultshot + 2 + aPlayer.tmp;   // sono differenti buff tra tackle, dribbling e movetoball
     aPlayer.Passing   := aPlayer.DefaultPassing + 2 ;
    end;

    case aPlayer.Team of
      0: begin
        if aPlayer.CellX <= 5 then
          aPlayer.xpTal[TALENT_ID_DEFENSIVE] := aPlayer.xpTal[TALENT_ID_DEFENSIVE] + 1
          else aPlayer.xpTal[TALENT_ID_OFFENSIVE] := aPlayer.xpTal[TALENT_ID_OFFENSIVE] + 1;
      end;
      1: begin
        if aPlayer.CellX >= 6 then
          aPlayer.xpTal[TALENT_ID_DEFENSIVE] := aPlayer.xpTal[TALENT_ID_DEFENSIVE] + 1
          else aPlayer.xpTal[TALENT_ID_OFFENSIVE] := aPlayer.xpTal[TALENT_ID_OFFENSIVE] + 1;
      end;
    end;

    //if aPlayer.HasBall and ( w_FreeKick1 ) then Ball.Player.isFK1 := True;

    ExceptPlayers.Add(aPlayer);
    reason := '';
    InputSecureExit ( true, DecNormal );
    goto MyExit;

  end
  // pass può trovarsi in mezzo a corner o punizioni
  else if tsCmd[0] = 'PASS' then  begin
    if w_SomeThing  then begin
     reason := 'PASS, waiting freekick ';
     goto myexit; // hack
    end;  // concesso nulla

    if (FlagEndGame) then begin
      reason := 'PASS, 120+ ';
      goto myexit; // hack
    end;

    TsScript[incMove].add ('SERVER_PASS,' + IntToStr(teamturn) ) ;

    TeamMovesLeft := 0;
    TurnChange (TurnMoves); // // PASS oltre 120+ non fa finire la partita ma fa giocare l'avversario

    TsScript[incMove].add ('E') ;
    reason:='';
    goto MyExit;

  end

// input dal client setto chi calcia il corner dopo la richiesta SERVER_COA del brain tutto da validare
  else if tsCmd[0] = 'CORNER_ATTACK.SETUP' then  begin  // cof coa coa coa
     // devo sapere di chi è il corner attuale
     //aPlayer := GeTPlayer(tsCmd[1]);
      if Not w_Coa  then begin
       reason := 'CORNER_ATTACK.SETUP, not waiting w_coa ';
       goto myexit; // hack
      end;
      for I := 1 to 4 do begin
        if GeTPlayer ( tsCmd[I], TeamTurn) = nil then begin
           reason := 'CORNER_ATTACK.SETUP, Guid/team error ';
           goto myexit; // hack
        end;
      End;

     TsScript[incMove].add ('SERVER_COA.IS');
     CornerMap := GetCorner ( TeamCorner , Ball.CellY,OpponentCorner);
     SwapString:= TstringList.Create;
     SwapString.Add('0');
     SwapString.Add('0');
     SwapString.Add('0');
     SwapString.Add('0');
      // molto importante la sequenza


       for I := 0 to 3 do begin

         if i= 0 then begin // cof
           aCell := CornerMap.CornerCell ;
           swapPlayer := GeTPlayer(aCell.x, aCell.Y  );  //<-- prima di tutti o prende sè stesso
           aPlayer := GeTPlayer(tsCmd[1]);  // cmd, cof, coa, coa, coa
           aPlayer.Cells := CornerMap.CornerCell;
           aPlayer.isCOF := true;
           TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                            IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)  ) ;
           ball.Cells:= aPlayer.Cells;
         end
         else begin
      // molto importante la sequenza
           aCell := CornerMap.HeadingCellA [I-1];
           swapPlayer := GeTPlayer(aCell.x, aCell.Y  );  //<-- prima di tutti o prende sè stesso
           aPlayer := GeTPlayer(tsCmd[I+1]);  // cmd, cof, coa, coa, coa
           TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                            IntTostr(aCell.X)+','+ IntTostr(aCell.Y)  ) ;
           aPlayer.Cells := aCell;
         end;

         if swapPlayer <> nil then begin
           if (swapPlayer.Team = aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin    // swap compagno
              SwapString[i]:= SwapPlayer.Ids;
              aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
              TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                          IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
              swapPlayer.Cells := aCell2;

           end
           else if (swapPlayer.Team <> aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin // swap avversario
              SwapString[i]:= SwapPlayer.Ids;
              aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
              TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                          IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
              swapPlayer.Cells := aCell2;

           end;
         end;

       end;

       if teamTurn = 0 then tt := '1' else tt :='0';
       TsScript[incMove].add ('COA.IS,'+  tt +','+ tsCmd[1]  +',' + tsCmd[2] +',' + tsCmd[3] +',' + tsCmd[4] + ',' + SwapString.CommaText );

       w_coa := false;
       w_cod := true;
       Turnchange(TurnMoves);
       SwapString.Free;
       TsScript[incMove].add ('E' ) ;
  end
  else if tsCmd[0] = 'CORNER_DEFENSE.SETUP' then  begin
      if not w_Cod  then begin
       reason := 'CORNER_DEFENSE.SETUP, not waiting w_cod ';
       goto myexit; // hack
      end;
      for I := 1 to 3 do begin
        if GeTPlayer ( tsCmd[I], TeamTurn) = nil then begin
           reason := 'CORNER_DEFENSE.SETUP, Guid/team error ';
           goto myexit; // hack
        end;
      End;
     TsScript[incMove].add ('SERVER_COD.IS' );
     CornerMap := GetCorner ( TeamCorner , Ball.CellY, OpponentCorner);// devo sapere di chi è il corner attuale
     SwapString:= TstringList.Create;
     SwapString.Add('0');
     SwapString.Add('0');
     SwapString.Add('0');

       for I := 0 to 2 do begin

         aCell := CornerMap.HeadingCellD [I];
         swapPlayer := GeTPlayer(aCell.x, aCell.Y  );  //<-- prima di tutti o prende sè stesso
         aPlayer := GeTPlayer(tsCmd[I+1]);  // cmd, cod, cod, cod

           if swapPlayer <> nil then begin

             if (swapPlayer.Team = aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin    // swap compagno
                SwapString[i]:= SwapPlayer.Ids;
                aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
                swapPlayer.Cells := aCell2;

             end
             else if (swapPlayer.Team <> aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin // swap avversario
                SwapString[i]:= SwapPlayer.Ids;
                aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
                swapPlayer.Cells := aCell2;

             end;

           end;

         TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                            IntTostr(aCell.X)+','+ IntTostr(aCell.Y)  ) ;
         aPlayer.Cells := aCell;
       end;

       if teamTurn = 0 then tt := '1' else tt :='0';
       TsScript[incMove].add ('COD.IS,' + tt + ',' + tsCmd[1] +',' + tsCmd[2] +',' + tsCmd[3]+','+SwapString.CommaText );
       w_coa := false;
       w_cod := false;
       w_CornerKick := True;
       Turnchange(TurnMoves);
       SwapString.Free;
       TsScript[incMove].add ('E' ) ;
       goto Myexit;
  end
  else if  tsCmd[0] = 'COR' then  begin
    if Not w_CornerKick  then begin
     reason := 'COR, not waiting cornerkick ';
     goto myexit; // hack
    end;
    w_CornerKick:= False;
    exec_corner;
    goto Myexit;
  end
  else if  tsCmd[0] = 'CRO2' then  begin
    if Not w_FreeKick2  then begin
     reason := 'CRO2, not waiting CRO2';
     goto myexit; // hack
    end;
    w_FreeKick2:= False;
    exec_freekick2;
    goto Myexit;
  end
  else if tsCmd[0] = 'FREEKICK1_ATTACK.SETUP' then  begin  // Fkf1 e basta
    if NOT w_Fka1  then begin
     reason := 'FREEKICK1_ATTACK.SETUP, not waiting fka1 ';
     goto myexit; // hack
    end;
    if GeTPlayer ( tsCmd[1], TeamTurn) = nil then begin
       reason := 'FREEKICK1_ATTACK.SETUP, Guid/team error ';
       goto myexit; // hack
    end;

     TsScript[incMove].add ('SERVER_FKA1.IS' );

     CornerMap := GetCorner ( TeamFreekick , Ball.CellY,OpponentCorner);
     SwapString:= TstringList.Create;
     SwapString.Add('0');
     swapPlayer := GeTPlayer( Ball.CellX, Ball.CellY  );  //<-- prima di tutti o prende sè stesso
     aPlayer := GeTPlayer(tsCmd[1]);  // cmd, Fk1

     TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                            IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)  ) ;

     aPlayer.Cells :=  Ball.Cells ; // freekick cell
     aPlayer.isFk1 := true;

     if swapPlayer <> nil then begin
       if (swapPlayer.Team = aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin    // swap compagno
          // il player è già posizionato
          SwapString[i]:= SwapPlayer.Ids;
          aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
          TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;

          swapPlayer.Cells := aCell2;

       end
       else if (swapPlayer.Team <> aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin // swap avversario
          SwapString[i]:= SwapPlayer.Ids;
          aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
          TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
          swapPlayer.Cells := aCell2;

       end;
     end;
       TsScript[incMove].add ('FKA1.IS,'+ IntToStr(teamTurn) + ',' +tsCmd[1]  + ',' + SwapString.CommaText );
       //Turnchange(TurnMoves);
       SwapString.Free;
       TsScript[incMove].add ('E' ) ;
       w_fka1 := false;
       w_FreeKick1 := True;
       goto Myexit;

  end
  else if tsCmd[0] = 'FREEKICK2_ATTACK.SETUP' then  begin  // Fk2 coa coa coa
    if not w_Fka2 then begin
     reason := 'FREEKICK2_ATTACK.SETUP, not waiting fka2 ';
     goto myexit; // hack                                                           { TODO  : fare come sopra e anche il corner }
    end;
    for I := 1 to 3 do begin
      if GeTPlayer ( tsCmd[I], TeamTurn) = nil then begin
         reason := 'FREEKICK2_ATTACK.SETUP, Guid/team error ';
         goto myexit; // hack
      end;
    End;
     // devo sapere di chi è la punizione attuale
     //aPlayer := GeTPlayer(tsCmd[1]);

     CornerMap := GetCorner ( TeamFreekick , Ball.CellY,OpponentCorner);
     SwapString:= TstringList.Create;
     SwapString.Add('0');
     SwapString.Add('0');
     SwapString.Add('0');
     SwapString.Add('0');
      // molto importante la sequenza
     TsScript[incMove].add ('SERVER_FKA2.IS' );

     aPlayer := GeTPlayer(tsCmd[1]);  // cmd, Fk2, coa, coa, coa
     TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                            IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)  ) ;

       for I := 0 to 3 do begin

         if i= 0 then begin // fk2
          // aCell :=   CornerMap.CornerCell ;
           swapPlayer := GeTPlayer( Ball.CellX, Ball.CellY  );  //<-- prima di tutti o prende sè stesso
           aPlayer := GeTPlayer(tsCmd[1]);  // cmd, Fk2, coa, coa, coa
           aPlayer.Cells :=  Ball.Cells ; // CornerMap.CornerCell;
           aPlayer.isFk2 := true;
           //ball.Cells:= aPlayer.Cells;
         end
         else begin  // qui è come il corner
      // molto importante la sequenza
           aCell := CornerMap.HeadingCellA [I-1];
           swapPlayer := GeTPlayer(aCell.x, aCell.Y  );  //<-- prima di tutti o prende sè stesso
           aPlayer := GeTPlayer(tsCmd[I+1]);  // cmd, cof, coa, coa, coa
           aPlayer.Cells := aCell;
         end;

           if swapPlayer <> nil then begin
             if (swapPlayer.Team = aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin    // swap compagno
                SwapString[i]:= SwapPlayer.Ids;
                aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
                swapPlayer.Cells := aCell2;

             end
             else if (swapPlayer.Team <> aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin // swap avversario
                SwapString[i]:= SwapPlayer.Ids;
                aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
                swapPlayer.Cells := aCell2;

             end;
           end;

       end;
       if teamTurn = 0 then tt := '1' else tt :='0';
       TsScript[incMove].add ('FKA2.IS,'+  tt + ',' + tsCmd[1]  +',' + tsCmd[2] +',' + tsCmd[3] +',' + tsCmd[4] + ',' + SwapString.CommaText );
       w_fka2 := false;
       w_fkd2 := true;
       Turnchange(TurnMoves);
       SwapString.Free;
       TsScript[incMove].add ('E' ) ;
  end
  else if tsCmd[0] = 'FREEKICK2_DEFENSE.SETUP' then  begin
    if NOT w_Fkd2  then begin
     reason := 'FREEKICK2_DEFENSE.SETUP, not waiting Fkd2 ';
     goto myexit; // hack
    end;
      for I := 1 to 3 do begin
        if GeTPlayer ( tsCmd[I], TeamTurn) = nil then begin
           reason := 'FREEKICK2_DEFENSE.SETUP, Guid/team error ';
           goto myexit; // hack
        end;
      End;

     // devo sapere di chi è il corner attuale
     CornerMap := GetCorner ( TeamFreekick , Ball.CellY, OpponentCorner);
     SwapString:= TstringList.Create;
     SwapString.Add('0');
     SwapString.Add('0');
     SwapString.Add('0');
     TsScript[incMove].add ('SERVER_FKD2.IS');

       for I := 0 to 2 do begin

         aCell := CornerMap.HeadingCellD [I];
         swapPlayer := GeTPlayer(aCell.x, aCell.Y  );  //<-- prima di tutti o prende sè stesso
         aPlayer := GeTPlayer(tsCmd[I+1]);  // cmd, cod, cod, cod
         TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                            IntTostr( aCell.X )+','+ IntTostr(aCell.Y )  ) ;

           if swapPlayer <> nil then begin

             if (swapPlayer.Team = aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin    // swap compagno
                SwapString[i]:= SwapPlayer.Ids;
                aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
                swapPlayer.Cells := aCell2;

             end
             else if (swapPlayer.Team <> aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin // swap avversario
                SwapString[i]:= SwapPlayer.Ids;
                aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
                swapPlayer.Cells := aCell2;

             end;

           end;

         aPlayer.Cells := aCell;
       end;

       if teamTurn = 0 then tt := '1' else tt :='0';
       TsScript[incMove].add ('FKD2.IS,' + tt + ',' + tsCmd[1] +',' + tsCmd[2] +',' + tsCmd[3]+','+SwapString.CommaText );
       SwapString.Free;
       w_FreeKick2 := True;
       w_fka2 := false;
       w_fkd2 := false;
       Turnchange(TurnMoves);
       TsScript[incMove].add ('E' ) ;
       goto Myexit;
  end
  else if tsCmd[0] = 'FREEKICK3_ATTACK.SETUP' then  begin  // Fkf3
    if NOT w_Fka3   then begin
     reason := 'FREEKICK3_ATTACK.SETUP, not waiting fka3 ';
     goto myexit; // hack
    end;
    if GeTPlayer ( tsCmd[1], TeamTurn) = nil then begin
       reason := 'FREEKICK3_ATTACK.SETUP, Guid/team error ';
       goto myexit; // hack
    end;
     TsScript[incMove].add ('SERVER_FKA3.IS' );

     CornerMap := GetCorner ( TeamFreekick , Ball.CellY,OpponentCorner);
     SwapString:= TstringList.Create;
     SwapString.Add('0');
     swapPlayer := GeTPlayer( Ball.CellX, Ball.CellY  );  //<-- prima di tutti o prende sè stesso
     aPlayer := GeTPlayer(tsCmd[1]);  // cmd, Fk2, coa, coa, coa
         TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                            IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)  ) ;
     aPlayer.Cells :=  Ball.Cells ; // CornerMap.CornerCell;
     aPlayer.isFk3 := true;

       if swapPlayer <> nil then begin
     //  if (swapPlayer.Team = aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin    // swap compagno
       if SwapPlayer.Ids <> aPlayer.ids then begin    // swap compagno
          SwapString[i]:= SwapPlayer.Ids;
          aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                           IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
          swapPlayer.Cells := aCell2;

     //  end
     //  else if (swapPlayer.Team <> aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin // swap avversario
     //     SwapString[i]:= SwapPlayer.Ids;
     //     aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
     //           TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
     //                                       IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
     //     swapPlayer.Cells := aCell2;

       end;
     end;

       if teamTurn = 0 then tt := '1' else tt :='0';
       TsScript[incMove].add ('FKA3.IS,'+ tt +',' +tsCmd[1]  + ',' + SwapString.CommaText );
       w_fka3 := false;
       w_fkd3 := true;
       w_FreeKick3 := false;
       Turnchange(TurnMoves);
       SwapString.Free;
       TsScript[incMove].add ('E' ) ;
       goto Myexit;
  end
  else if tsCmd[0] = 'FREEKICK3_DEFENSE.SETUP' then  begin
    if NOT w_Fkd3 then begin
     reason := 'FREEKICK3_DEFENSE.SETUP, not waiting fkd3 ';
     goto myexit; // hack
    end;
    for I := 1 to 4 do begin
      if GeTPlayer ( tsCmd[I], TeamTurn) = nil then begin
         reason := 'FREEKICK3_DEFENSE.SETUP, Guid/team error ';
         goto myexit; // hack
      end;
    End;
     // devo sapere di chi è il corner attuale
       TsScript[incMove].add ('SERVER_FKD3.IS' );
     CornerMap := GetCorner ( TeamFreekick , Ball.CellY, OpponentCorner);
     SwapString:= TstringList.Create;
     SwapString.Add('0');
     SwapString.Add('0');
     SwapString.Add('0');
     SwapString.Add('0');

     SwapDone := False;

       for I := 0 to 3 do begin // 4 in barriera

         ACellBarrier := GetBarrierCell( TeamFreeKick , Ball.CellX, Ball.CellY );  // dalla cella punizione shot ricavo la cella della barriera
         aPlayer := GeTPlayer(tsCmd[I+1]);  // cmd, bar1, bar2, bar3, bar4
         swapPlayer := GeTPlayer(ACellBarrier.x, ACellBarrier.Y  );  //<-- prima di tutti o prende sè stesso

         if (swapPlayer <> nil) and (Not SwapDone) and (i = 0) then begin   // evita swap del primo in barriera

             if SwapPlayer.Ids <> aPlayer.ids  then begin    // swap compagno
                  SwapString[i]:= SwapPlayer.Ids;
                  aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                  TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                              IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
                  swapPlayer.Cells := aCell2;
                  SwapDone := true; // 1 solo swap, dopo skippo gli atri 3 in barriera

             end;
         end;
           TsScript[incMove].add ('sc_player.barrier,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                              IntTostr(ACellBarrier.X)+','+ IntTostr(ACellBarrier.Y)  ) ;
           aPlayer.Cells := ACellBarrier;
           aPlayer.isFKD3 := True;

       end;
       if teamTurn = 0 then tt := '1' else tt :='0';
       TsScript[incMove].add ('FKD3.IS,' + tt +',' + tsCmd[1] +',' + tsCmd[2] +',' + tsCmd[3]+','+  tsCmd[4] + ',' + SwapString.CommaText );
       SwapString.Free;
       w_fka3 := false;
       w_fkd3 := false;
       w_FreeKick3 := True;
       Turnchange(TurnMoves);
       TsScript[incMove].add ('E' ) ;
       goto Myexit;
  end
  else if tsCmd[0] = 'FREEKICK4_ATTACK.SETUP' then  begin  // Fkf3
    if NOT w_Fka4 then begin
     reason := 'FREEKICK4_ATTACK.SETUP, not waiting fka4 ';
     goto myexit; // hack
    end;
    if GeTPlayer ( tsCmd[1], TeamTurn) = nil then begin
       reason := 'FREEKICK4_ATTACK.SETUP, Guid/team error ';
       goto myexit; // hack
    end;

     TsScript[incMove].add ('SERVER_FKA4.IS' );
     CornerMap := GetCorner ( TeamFreekick , Ball.CellY,OpponentCorner);
     SwapString:= TstringList.Create;
     SwapString.Add('0');

     aPlayer := GeTPlayer(tsCmd[1]);  // cmd, Fk2, coa, coa, coa
     Ball.Cells := GetPenaltyCell( aPlayer.team ) ;
     swapPlayer := GeTPlayer( Ball.CellX, Ball.CellY  );  //<-- prima di tutti o prende sè stesso
     //    TsScript[incMove].add ('sc_player,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
     //                                       IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)  ) ;

     aPlayer.Cells :=  Ball.Cells ;
     aPlayer.isFk4 := true;

     if swapPlayer <> nil then begin
       if SwapPlayer.Ids <> aPlayer.ids then begin    // swap compagno
          SwapString[i]:= SwapPlayer.Ids;
          aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
          swapPlayer.Cells := aCell2;

//       end
 //      else if (swapPlayer.Team <> aPlayer.Team) and (SwapPlayer.Ids <> aPlayer.ids) then begin // swap avversario
//          SwapString[i]:= SwapPlayer.Ids;
//          aCell2 := FindSwapCOAD (  swapPlayer, CornerMap  );
//                TsScript[incMove].add ('sc_player,'+ swapPlayer.Ids +','+IntTostr(swapPlayer.CellX)+','+ IntTostr(swapPlayer.CellY)+','+
//                                            IntTostr(aCell2.X)+','+ IntTostr(aCell2.Y)  ) ;
//          swapPlayer.Cells := aCell2;

       end;
     end;

       TsScript[incMove].add ('FKA4.IS,'+ intTostr(TeamTurn) +','+ tsCmd[1]  + ',' + SwapString.CommaText );
    //   Turnchange(TurnMoves);
       SwapString.Free;
       TsScript[incMove].add ('E' ) ;
       w_fka4 := false;
       w_FreeKick4 := true;
       goto Myexit;
  end

  else if tsCmd[0] = 'BUFFD' then  begin
    if w_SomeThing  then begin
     reason := 'BUFFD, waiting freekick ';
     goto myexit; // hack
    end;  // concesso nulla
    aPlayer := GeTPlayer ( tsCmd[1]);

    if aPlayer = nil then begin
     reason := 'BUFFD,Player not found';
     goto myexit; // hack
    end;
//    if not aPlayer.CanSkill then begin
//     reason := 'BUFFD,Player unable to use skill';
//     goto myexit; // hack
//    end;

    if aPlayer.TalentId2 <> TALENT_ID_BUFF_DEFENSE then begin // non ha quel talento e quindi la skill
     reason := 'BUFFD, Missing Talent';
     goto myexit; // hack
    end;

    if aPlayer.Role  <> 'D' then begin // se schierato dall'inizio o con stay , ma deve far parte del reparto
     reason := 'BUFFD, player is not a defender';
     goto myexit; // hack
    end;

    if Score.buffD[aPlayer.team] <> 0 then begin
     reason := 'BUFFD, buff defense is active';
     goto myexit; // hack
    end;



    if debug_Buff100 then begin
      goto buffd;
    end;
    if RndGenerate(100) <= 5 then begin
buffd:
      Score.BuffD[aPlayer.Team] := 20;
    // non costa stamina
    // non va in ExceptPlayer
    // cerco il reparto e lo buffo
      aList := TObjectList<TPlayer>.create(false);
      CompileRoleList(aPlayer.team,'D', aList);
      for p := aList.Count -1 downto 0 do begin

        aList[p].BonusBuffD := 1;
        aList[p].Defense := aList[p].Defense + 1;
        aList[p].BallControl := aList[p].BallControl + 1;
        aList[p].Passing := aList[p].Passing + 1;
      end;
      aList.Free;
    end;

    TsScript[incMove].add ('SERVER_BUFFD,' + aPlayer.ids ) ;


    reason := '';
    InputSecureExit ( true, DecNoResetPlayer );
    goto MyExit;
  end
  else if tsCmd[0] = 'BUFFM' then  begin
    if w_SomeThing  then begin
     reason := 'BUFFM, waiting freekick ';
     goto myexit; // hack
    end;  // concesso nulla
    aPlayer := GeTPlayer ( tsCmd[1]);

    if aPlayer = nil then begin
     reason := 'BUFFM,Player not found';
     goto myexit; // hack
    end;
//    if not aPlayer.CanSkill then begin
//     reason := 'BUFFM,Player unable to use skill';
//     goto myexit; // hack
//    end;

    if aPlayer.TalentId2 <> TALENT_ID_BUFF_MIDDLE then begin // non ha quel talento e quindi la skill
     reason := 'BUFFM, Missing Talent';
     goto myexit; // hack
    end;

    if aPlayer.Role  <> 'M' then begin // se schierato dall'inizio o con stay , ma deve far parte del reparto
     reason := 'BUFFM, player is not a Middle';
     goto myexit; // hack
    end;

    if Score.buffM[aPlayer.team] <> 0 then begin
     reason := 'BUFFM, buff middle is active';
     goto myexit; // hack
    end;

    TsScript[incMove].add ('SERVER_BUFFM,' + aPlayer.ids  ) ;
    // non costa stamina
    // non va in ExceptPlayer
    if debug_Buff100 then begin
      goto buffm;
    end;
    if RndGenerate(100) <= 5 then begin
buffm:
      Score.BuffM[aPlayer.Team] := 20;
      aList := TObjectList<TPlayer>.create(false);
      CompileRoleList(aPlayer.Team,'M',aList);
      for p := aList.Count -1 downto 0 do begin
        if aList[p].Speed < 4 then
          aList[p].Speed := aList[p].Speed + 1;

        aList[p].BonusBuffM := 1;
        aList[p].BallControl := aList[p].BallControl + 1;
        aList[p].Passing := aList[p].Passing + 1;
        aList[p].Shot := aList[p].Shot + 1;
      end;
      aList.Free;
    end;
    reason := '';
    InputSecureExit ( true, DecNoResetPlayer );
    goto MyExit;
  end
  else if tsCmd[0] = 'BUFFF' then  begin
    if w_SomeThing  then begin
     reason := 'BUFFF, waiting freekick ';
     goto myexit; // hack
    end;  // concesso nulla
    aPlayer := GeTPlayer ( tsCmd[1]);

    if aPlayer = nil then begin
     reason := 'BUFFF,Player not found';
     goto myexit; // hack
    end;
//    if not aPlayer.CanSkill then begin
//     reason := 'BUFFF,Player unable to use skill';
 //    goto myexit; // hack
 //   end;

    if aPlayer.TalentId2 <> TALENT_ID_BUFF_FORWARD then begin // non ha quel talento e quindi la skill
     reason := 'BUFFF, Missing Talent';
     goto myexit; // hack
    end;

    if aPlayer.Role  <> 'F' then begin // se schierato dall'inizio o con stay , ma deve far parte del reparto
     reason := 'BUFFF, player is not a forward';
     goto myexit; // hack
    end;

    if Score.buffF[aPlayer.team] <> 0 then begin
     reason := 'BUFFF, buff attack is active';
     goto myexit; // hack
    end;

    TsScript[incMove].add ('SERVER_BUFFF,' + aPlayer.ids ) ;

    if debug_Buff100 then begin
      goto bufff;
    end;
    if RndGenerate(100) <= 5 then begin
bufff:
      // non costa stamina
      // non va in ExceptPlayer
      Score.BuffF[aPlayer.Team] := 20;
      aList := TObjectList<TPlayer>.create(false);
      CompileRoleList(aPlayer.Team,'F',aList);
      for p := aList.Count -1 downto 0 do begin
        aList[p].BonusBuffF := 1;
        aList[p].BallControl := aList[p].BallControl + 1;
        aList[p].Passing := aList[p].Passing + 1;
        aList[p].Shot := aList[p].Shot + 1;
      end;
      aList.Free;
    end;

    reason := '';
    InputSecureExit ( true, DecNoResetPlayer );
    goto MyExit;
  end




  (* GM COMMANDS*)
  else if tsCmd[0] ='setball' then begin  // già verificato dal server GmLevel (account)

    Ball.CellX := StrToIntDef(tsCmd[1],5);
    Ball.CellY := StrToIntDef(tsCmd[2],3);
    tsScript[incMove].Clear;
//    SaveData (incMove -1);
{    SaveData (incMove );
    TBrainManager(brainManager).Input ( Self, IntToStr(incMove)  ) ; // -1
    Working:= false;
    Exit; //<-- non deve fare incMove sotto   }
    goto Myexit;

  end
  else if tsCmd[0] ='debug_tackle_failed' then begin  // già verificato dal server GmLevel (account)
    debug_TACKLE_FAILED := Boolean( StrToInt(tsCmd[1]))  ;
    goto Myexit;
  end
  else if tsCmd[0] ='debug_setfault' then begin  // già verificato dal server GmLevel (account)
    debug_SETFAULT := Boolean( StrToInt(tsCmd[1]))  ;
    goto Myexit;
  end
  else if tsCmd[0] ='debug_setred' then begin  // già verificato dal server GmLevel (account)
    debug_SETRED := Boolean( StrToInt(tsCmd[1]))  ;
    goto Myexit;
  end
  else if tsCmd[0] ='debug_setslwaysgol' then begin  // già verificato dal server GmLevel (account)
    debug_SetAlwaysGol := Boolean( StrToInt(tsCmd[1]))  ;
    goto Myexit;
  end
  else if tsCmd[0] ='debug_setposcrosscorner' then begin  // già verificato dal server GmLevel (account)
    debug_Setposcrosscorner := Boolean( StrToInt(tsCmd[1]))  ;
    goto Myexit;
  end
  else if tsCmd[0] ='debug_buff100' then begin  // già verificato dal server GmLevel (account)
    debug_Buff100 := Boolean( StrToInt(tsCmd[1]))  ;
    goto Myexit;
  end
  else if tsCmd[0] ='testcorner' then begin  // già verificato dal server GmLevel (account)

    aPlayer := GeTPlayer(tsCmd[1]);
    if aPlayer <> nil then begin
      aGK := GetOpponentGK ( aPlayer.team);
      TsScript[incMove].add ('SERVER_POS,' + aPlayer.ids + ',' + IntToStr(aPlayer.CellX) + ',' + IntToStr(aPlayer.CellY)+ ',' + IntToStr( aGK.CellX ) +',' + IntToStr(aGK.celly));
      CornerSetup ( aPlayer );
      goto Myexit;
//      Exit; //<-- non deve fare incMove sotto    invece lo deve fare in caso di azione
    end;
  end
  else if tsCmd[0] ='randomstamina' then begin  // già verificato dal server GmLevel (account)
    for P:= Players.Count -1 downto 0 do begin
     if  (RndGenerate(100) <= 20) and (Players[p].role <> 'G') then
     Players[p].Stamina := RndGenerate(50);
    end;
//    SaveData (incMove -1);
{    SaveData (incMove );
      TBrainManager(brainManager).Input ( Self, IntToStr(incMove)  ) ; // -1
      Working:= false;
      Exit; //<-- non deve fare incMove sotto  }
      goto Myexit;
  end
  else if tsCmd[0] ='pause' then begin  // già verificato dal server GmLevel (account)
      Paused:= StrToBool( tsCmd[1]);
//    SaveData (incMove -1);
  {  SaveData (incMove );
      TBrainManager(brainManager).Input ( Self, brainIds+'\' + Format('%.*d',[3, incMove])  ) ; // -1
      Working:= false;
      Exit; //<-- non deve fare incMove sotto  }
      goto Myexit;

  end
  else if tsCmd[0] ='setplayer' then begin  // già verificato dal server GmLevel (account)
    if GameMode =  pvp then begin
      aPlayer := GeTPlayer(tsCmd[1]);
      if aPlayer <> nil then begin
        aPlayer.CellX := StrToIntDef(tsCmd[2],5);
        aPlayer.CellY := StrToIntDef(tsCmd[3],3);
        tsScript[incMove].Clear;

       // TBrainManager(brainManager).Input ( Self, IntToStr(incMove) )  ; // -1
       // Working:= false;
        //<-- non deve fare incMove sopra  }
      End;
      goto Myexit;
    end;
  end;
Myexit:
    if reason <> '' then Begin
      // hacking
     // TsScript[incMove].add ('HACKING: ' + Reason ) ;
     // TsScript[incMove].add ('E' ) ;
      // informo il brainManager del Server del cheating
      if GameMode = pvp then
        TBrainManager(brainManager).Input ( Self, 'cheat: ' + reason + ':' + tsCmd.CommaText  )
      Else if GameMode = pve then begin
        //if (LogUser [0] > 0) or (LogUser[1] > 0) then begin

        TsErrorLog.Add(  IntToStr( Minute ) + ' ' + reason);
        TsErrorLog.SaveTofile ( dir_log + brainIds + '.ERR');

         // MMbraindata.SaveToFile( dir_log +  brainIds  + '\' + Format('%.*d',[3, incMove]) + '.ERR'  );
       // end;
      end;
      Working:= false;
      tsCmd.free;
      if aPath <> nil then aPath.Free; // shp
      if lstHeading <> nil then begin
        for I := lstHeading.count -1 downto 0 do begin
          lstHeading[i].free;
        end;
        LstHeading.free;
      end;
      if lstIntercepts <> nil then begin
        for I := lstIntercepts.count -1 downto 0 do begin
          lstIntercepts[i].free;
        end;
        lstIntercepts.free;
      end;
    end
    else begin
     // se un pos3 o prs finisce in corner o parata devo svuotare la barriera
     if Barrier then begin
       DeflateBarrier (aCellBarrier , nil); // nessun exceptplayer
       Barrier := false;
     end;
    // devo passare il brain in Tcp qui (saveini e mtptransfer)
    // così può usare spritereset su quel brain
//      inc (incMove);
      SaveData ( incMove );

      if GameMode = pvp then begin
        TBrainManager(brainManager).Input ( Self, IntToStr(incMove)  ) ; // -1
      End
      else if GameMode = pve  then begin
//        SendMessage (PveClientHandle, 50,0,0);
        if pvePostMessage then
          postMessage ( Application.Handle , $2CCC,0,0);
      end;

      tsCmd.free;
      if aPath <> nil then aPath.Free; // shp
      if lstHeading <> nil then begin
        for I := lstHeading.count -1 downto 0 do begin
          lstHeading[i].free;
        end;
        LstHeading.free;
      end;
      if lstIntercepts <> nil then begin
        for I := lstIntercepts.count -1 downto 0 do begin
          lstIntercepts[i].free;
        end;
        lstIntercepts.free;
      end;

//      inc (incMove);
      Working:= false;
    end;
end;
procedure TBrain.SaveData ( CurMove: Integer ) ;
var
  ISMARK : array [0..1] of ansichar;
  i,ii,pcount,s,aa,totPlayer, TotReserve,totGameOver,PlayerGuid,LentsScript,lenMatchInfo: integer;
  ini: TInifile;
  tmp: string;
  tmpShort: Shortstring;
  FKblock: Byte;
  BEGINBRAIN, ENDBRAIN: ShortString;
  tmpStream, MM : TMemoryStream;
  LInput, LOutput: TFileStream;
//  LZip: TZCompressionStream;
  InBuffer: string;
  OutBuffer: string;
  str : AnsiString;
  CompressedStream: TZCompressionStream;
  DeCompressedStream: TZDeCompressionStream;
  bytes : TBytes;
  Dummy: word;
  seconds: smallint;
begin
  // il formato dei dati è proprietario. byte per byte salvo in memoria ciò che serve.
  // MMbrainData contiene lo streaming
  // 2 bytes che indicano l'offset dell'inizio di tsScript
  // variabili globali
  // Players.count + Reservesr.count
  // lista Players e Reserves
  // infine ts.scripts  @ts.commatext
  ISMARK [0] := 'I';
  ISMARK [1] := 'S';
  MMbraindata.Clear;
  MMbraindataZIP.size := 0;


//  BEGINBRAIN := 'BEGINBRAIN';
//  MMbraindata.Write( @BEGINBRAIN[1], 10 );
  MMbraindata.Write( @dummy , SizeOf(word) );    // reserved: indica il byte dove comincia tsscript per caricare subito la ts
  MMbraindata.Write( @Score.UserName [0], Length(Score.UserName [0]) +1);    // +1 byte 0 indica lunghezza stringa
  MMbraindata.Write( @Score.UserName [1], Length(Score.UserName [1]) +1);
  MMbraindata.Write( @Score.Team [0], Length(Score.Team [0]) +1 );
  MMbraindata.Write( @Score.Team [1], Length(Score.Team [1]) +1 );
  MMbraindata.Write( @Score.Teamguid [0], SizeOf(Integer) );
  MMbraindata.Write( @Score.Teamguid [1], SizeOf(Integer) );
  MMbraindata.Write( @Score.Rank [0], SizeOf(byte) );
  MMbraindata.Write( @Score.Rank [1], SizeOf(byte) );
  MMbraindata.Write( @Score.TeamMI [0], SizeOf(integer) );                   // media inglese
  MMbraindata.Write( @Score.TeamMI [1], SizeOf(integer) );
  MMbraindata.Write( @Score.Country [0], SizeOf(word) );
  MMbraindata.Write( @Score.Country [1], SizeOf(word) );
  MMbraindata.Write( @Score.uniform [0], Length(Score.uniform [0]) +1); // 1,9,3,1,9
  MMbraindata.Write( @Score.uniform [1], Length(Score.uniform [1]) +1); // 1,9,0,1,9
  MMbraindata.Write( @Score.Gol [0], SizeOf(Byte) );
  MMbraindata.Write( @Score.Gol [1], SizeOf(Byte) );
  MMbraindata.Write( @Score.BuffD[0], sizeof(ShortInt) );
  MMbraindata.Write( @Score.BuffD[1], sizeof(ShortInt) );
  MMbraindata.Write( @Score.BuffM[0], sizeof(ShortInt) );
  MMbraindata.Write( @Score.BuffM[1], sizeof(ShortInt) );
  MMbraindata.Write( @Score.BuffF[0], sizeof(ShortInt) );
  MMbraindata.Write( @Score.BuffF[1], sizeof(ShortInt) );
  MMbraindata.Write( @Score.TeamSubs[0], sizeof(ShortInt) );
  MMbraindata.Write( @Score.TeamSubs[1], sizeof(ShortInt) );


  // season e seasonRound
  MMbraindata.Write( @Score.Season[0] , sizeof(Integer) );
  MMbraindata.Write( @Score.Season[1] , sizeof(Integer) );
  MMbraindata.Write( @Score.SeasonRound[0] , sizeof(byte) );  // è già stato settato +1 nel createandloadmatch
  MMbraindata.Write( @Score.SeasonRound[1] , sizeof(byte) );

  MMbraindata.Write( @fgender, sizeof(byte) );
  MMbraindata.Write( @fminute, sizeof(SmallInt) );

  seconds := (fmilliseconds div 1000);
  MMbraindata.Write( @seconds, sizeof(SmallInt) ); // può andare in negativo oltre 127 o -127 no ShortInt . è millimilliseconds div 1000
  MMbraindata.Write( @teamturn, sizeof(byte) );    // a chi sta giocare
  MMbraindata.Write( @FTeamMovesLeft, sizeof(ShortInt) );   // mosse rimastye
  MMbraindata.Write( @GameStarted, sizeof(byte) );          // il game è attivo
  MMbraindata.Write( @FlagEndGame, sizeof(byte) );          // oltre i 120 turni, in fase di 'recupero'
  MMbraindata.Write( @finished, sizeof(byte) ); // flag partita finita // oltre i 120 turni, finita
  MMbraindata.Write( @ShpBuff, sizeof(byte) );
  MMbraindata.Write( @ShpFree, sizeof(ShortInt) );
  MMbraindata.Write( @IncMove, sizeof(smallint) ); // supplementari, rigori, può sforare 255 ?
  MMbraindata.Write( @Ball.Cx, sizeof(ShortInt) );
  MMbraindata.Write( @Ball.cy, sizeof(ShortInt) );

  MMbraindata.Write( @TeamCorner, sizeof(shortint) );
  MMbraindata.Write( @w_CornerSetup, sizeof(byte) );
  MMbraindata.Write( @w_Coa, sizeof(byte) );
  MMbraindata.Write( @w_Cod, sizeof(byte) );
  MMbraindata.Write( @w_CornerKick, sizeof(byte) );

  MMbraindata.Write( @TeamFreeKick, sizeof(shortint) );

  MMbraindata.Write( @w_FreeKickSetup1, sizeof(byte) );
  MMbraindata.Write( @w_Fka1, sizeof(byte) );
  MMbraindata.Write( @w_FreeKick1, sizeof(byte) );

  MMbraindata.Write( @w_FreeKickSetup2, sizeof(byte) );
  MMbraindata.Write( @w_Fka2, sizeof(byte) );
  MMbraindata.Write( @w_Fkd2, sizeof(byte) );
  MMbraindata.Write( @w_FreeKick2, sizeof(byte) );

  MMbraindata.Write( @w_FreeKickSetup3, sizeof(byte) );
  MMbraindata.Write( @w_Fka3, sizeof(byte) );
  MMbraindata.Write( @w_Fkd3, sizeof(byte) );
  MMbraindata.Write( @w_FreeKick3, sizeof(byte) );

  MMbraindata.Write( @w_FreeKickSetup4, sizeof(byte) );
  MMbraindata.Write( @w_Fka4, sizeof(byte) );
  MMbraindata.Write( @w_FreeKick4, sizeof(byte) );


  // MatchInfo TstringList
  str:= AnsiString  ( MatchInfo.CommaText );
  lenMatchInfo := Length (str);
  MMbraindata.Write( @lenMatchInfo, sizeof(word) );
  MMbraindata.Write( @str[1] , Length(str) );


  totPlayer :=  Players.Count ;
  MMbraindata.Write( @totPlayer, sizeof(byte) );

  for i := 0 to Players.Count -1 do begin    // salvo tutti i player che stanno giocando
    PlayerGuid := StrToInt(Players[i].Ids);
    MMbraindata.Write( @PlayerGuid, sizeof(integer) );
    MMbraindata.Write( @Players[i].GuidTeam, sizeof(integer) );

    MMbraindata.Write( @Players[i].Surname [0], length ( Players[i].Surname) +1 );      // +1 byte 0 indica lunghezza stringa

    MMbraindata.Write( @Players[i].Team, sizeof(byte) );
    if GameMode = pvp then begin
      MMbraindata.Write( @Players[i].MatchesPlayed, sizeof(SmallInt) );
      MMbraindata.Write( @Players[i].MatchesLeft, sizeof(SmallInt) );
    end;
    MMbraindata.Write( @Players[i].Age, sizeof(byte) );
    MMbraindata.Write( @Players[i].TalentID1,  sizeof(byte) );
    MMbraindata.Write( @Players[i].TalentID2,  sizeof(byte) );
    MMbraindata.Write( @Players[i].Stamina, sizeof(SmallInt) );


    MMbraindata.Write( @Players[i].DefaultSpeed , sizeof(byte) );      // i valori di default senza buff o debuff (come underpressure)
    MMbraindata.Write( @Players[i].DefaultDefense , sizeof(byte) );
    MMbraindata.Write( @Players[i].DefaultPassing, sizeof(byte) );
    MMbraindata.Write( @Players[i].DefaultBallControl , sizeof(byte) );
    MMbraindata.Write( @Players[i].DefaultShot , sizeof(byte) );
    MMbraindata.Write( @Players[i].DefaultHeading , sizeof(byte) );

    MMbraindata.Write( @Players[i].Speed , sizeof(ShortInt) );        // gli attuali valori con eventuali buff e debuff (come underpressure)
    MMbraindata.Write( @Players[i].Defense , sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].Passing, sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].BallControl , sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].Shot , sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].Heading , sizeof(ShortInt) );

    MMbraindata.Write( @Players[i].injured, sizeof(byte) );          // infortunato: tutti i valori a 1 ma rimane in campo se vuole
    MMbraindata.Write( @Players[i].yellowcard, sizeof(byte) );       // ammonito
    MMbraindata.Write( @Players[i].redcard, sizeof(byte) );          // espulso
    MMbraindata.Write( @Players[i].disqualified, sizeof(byte) );     // squalificato prima del match, non poteva giocare
    MMbraindata.Write( @Players[i].gameover, sizeof(byte) );         // partita terminata per questo player (espulso o sostituito )

    MMbraindata.Write( @Players[i].AIFormationCellX, sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].AIFormationCellY, sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].DefaultCellX, sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].DefaultCellY, sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].CellX, sizeof(ShortInt) );
    MMbraindata.Write( @Players[i].CellY, sizeof(ShortInt) );

    MMbraindata.Write( @Players[i].Stay, sizeof(byte) );
    MMbraindata.Write( @Players[i].CanMove, sizeof(byte) );
    MMbraindata.Write( @Players[i].CanSkill, sizeof(byte) );
    MMbraindata.Write( @Players[i].CanDribbling, sizeof(byte) );
    MMbraindata.Write( @Players[i].PressingDone, sizeof(byte) );
    MMbraindata.Write( @Players[i].BonusTackleTurn, sizeof(byte) );
    MMbraindata.Write( @Players[i].BonusLopBallControlTurn, sizeof(byte) );
    MMbraindata.Write( @Players[i].BonusProtectionTurn, sizeof(byte) );
    MMbraindata.Write( @Players[i].UnderPressureTurn, sizeof(byte) );
    MMbraindata.Write( @Players[i].BonusSHPturn, sizeof(byte) );
    MMbraindata.Write( @Players[i].BonusSHPAREAturn, sizeof(byte) );
    MMbraindata.Write( @Players[i].BonusPLMturn, sizeof(byte) );
    MMbraindata.Write( @Players[i].BonusFinishingTurn, sizeof(byte) );

    MMbraindata.Write( @Players[i].isCOF, sizeof(byte) );
    MMbraindata.Write( @Players[i].isFK1, sizeof(byte) );
    MMbraindata.Write( @Players[i].isFK2, sizeof(byte) );
    MMbraindata.Write( @Players[i].isFK3, sizeof(byte) );
    MMbraindata.Write( @Players[i].isFK4, sizeof(byte) );
    MMbraindata.Write( @Players[i].isFKD3, sizeof(byte) );
    MMbraindata.Write( @Players[i].face, sizeof(integer) );
    MMbraindata.Write( @Players[i].country, sizeof(smallint) );

    MMbraindata.Write( @Players[i].BonusBuffD, sizeof(Byte) );
    MMbraindata.Write( @Players[i].BonusBuffM, sizeof(Byte) );
    MMbraindata.Write( @Players[i].BonusBuffF, sizeof(Byte) );
    MMbraindata.Write( @Players[i].buffhome, sizeof(Byte) );
    MMbraindata.Write( @Players[i].buffmorale, sizeof(ShortInt) );

    MMbraindata.Write( @Players[i].xpDevA, sizeof(smallint) );
    MMbraindata.Write( @Players[i].xpDevT, sizeof(smallint) );
    MMbraindata.Write( @Players[i].xpDevI, sizeof(smallint) );

  end;

  totReserve :=   Reserves.Count;
  MMbraindata.Write( @totReserve, sizeof(byte) );

  for i := 0 to Reserves.Count -1 do begin
    PlayerGuid := StrToInt(Reserves[i].Ids); // dipende dalla gestione players, se divido per nazioni?
    MMbraindata.Write( @PlayerGuid, sizeof(integer) );
    MMbraindata.Write( @Reserves[i].GuidTeam, sizeof(integer) );
    MMbraindata.Write( @Reserves[i].Surname[0], length ( Reserves[i].Surname) +1 );
    MMbraindata.Write( @Reserves[i].Team, sizeof(byte) );
    MMbraindata.Write( @Reserves[i].Age, sizeof(byte) );
    if GameMode = pvp then begin
      MMbraindata.Write( @Reserves[i].MatchesPlayed, sizeof(SmallInt) );
      MMbraindata.Write( @Reserves[i].MatchesLeft, sizeof(SmallInt) );
    end;
    MMbraindata.Write( @Reserves[i].TalentID1,  sizeof(byte) );
    MMbraindata.Write( @Reserves[i].TalentID2,  sizeof(byte) );
    MMbraindata.Write( @Reserves[i].Stamina, sizeof(SmallInt) );

    MMbraindata.Write( @Reserves[i].DefaultSpeed , sizeof(byte) );
    MMbraindata.Write( @Reserves[i].DefaultDefense , sizeof(byte) );
    MMbraindata.Write( @Reserves[i].DefaultPassing, sizeof(byte) );
    MMbraindata.Write( @Reserves[i].DefaultBallControl , sizeof(byte) );
    MMbraindata.Write( @Reserves[i].DefaultShot , sizeof(byte) );
    MMbraindata.Write( @Reserves[i].DefaultHeading , sizeof(byte) );

    MMbraindata.Write( @Reserves[i].Speed , sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].Defense , sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].Passing, sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].BallControl , sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].Shot , sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].Heading , sizeof(ShortInt) );

    MMbraindata.Write( @Reserves[i].injured, sizeof(byte) );
    MMbraindata.Write( @Reserves[i].yellowcard, sizeof(byte) );
    MMbraindata.Write( @Reserves[i].redcard, sizeof(byte) );
    MMbraindata.Write( @Reserves[i].disqualified, sizeof(byte) );
    MMbraindata.Write( @Reserves[i].gameover, sizeof(byte) );

    MMbraindata.Write( @Reserves[i].AIFormationCellX, sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].AIFormationCellY, sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].DefaultCellX, sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].DefaultCellY, sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].CellX, sizeof(ShortInt) );
    MMbraindata.Write( @Reserves[i].CellY, sizeof(ShortInt) );

    MMbraindata.Write( @Reserves[i].face, sizeof(integer) );
    MMbraindata.Write( @Reserves[i].country, sizeof(smallint) );

    MMbraindata.Write( @Reserves[i].xpDevA, sizeof(smallint) );
    MMbraindata.Write( @Reserves[i].xpDevT, sizeof(smallint) );
    MMbraindata.Write( @Reserves[i].xpDevI, sizeof(smallint) );

  end;

  totGameOver :=   Gameover.Count;
  MMbraindata.Write( @totGameOver, sizeof(byte) );

  for i := 0 to Gameover.Count -1 do begin
    PlayerGuid := StrToInt(Gameover[i].Ids); // dipende dalla gestione players, se divido per nazioni?
    MMbraindata.Write( @PlayerGuid, sizeof(integer) );
    MMbraindata.Write( @Gameover[i].GuidTeam, sizeof(integer) );
    MMbraindata.Write( @Gameover[i].Surname[0], length ( Gameover[i].Surname) +1 );
    MMbraindata.Write( @Gameover[i].Team, sizeof(byte) );
    if GameMode = pvp then begin
      MMbraindata.Write( @Gameover[i].MatchesPlayed, sizeof(SmallInt) );
      MMbraindata.Write( @Gameover[i].MatchesLeft, sizeof(SmallInt) );
    end;
    MMbraindata.Write( @Gameover[i].Age, sizeof(byte) );

    MMbraindata.Write( @Gameover[i].TalentID1,  sizeof(byte) );
    MMbraindata.Write( @Gameover[i].TalentID2,  sizeof(byte) );
    MMbraindata.Write( @Gameover[i].Stamina, sizeof(SmallInt) );

    MMbraindata.Write( @Gameover[i].DefaultSpeed , sizeof(byte) );
    MMbraindata.Write( @Gameover[i].DefaultDefense , sizeof(byte) );
    MMbraindata.Write( @Gameover[i].DefaultPassing, sizeof(byte) );
    MMbraindata.Write( @Gameover[i].DefaultBallControl , sizeof(byte) );
    MMbraindata.Write( @Gameover[i].DefaultShot , sizeof(byte) );
    MMbraindata.Write( @Gameover[i].DefaultHeading , sizeof(byte) );

    MMbraindata.Write( @Gameover[i].Speed , sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].Defense , sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].Passing, sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].BallControl , sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].Shot , sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].Heading , sizeof(ShortInt) );

    MMbraindata.Write( @Gameover[i].injured, sizeof(byte) );
    MMbraindata.Write( @Gameover[i].yellowcard, sizeof(byte) );
    MMbraindata.Write( @Gameover[i].redcard, sizeof(byte) );
    MMbraindata.Write( @Gameover[i].disqualified, sizeof(byte) );
    MMbraindata.Write( @Gameover[i].gameover, sizeof(byte) );

    MMbraindata.Write( @Gameover[i].AIFormationCellX, sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].AIFormationCellY, sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].DefaultCellX, sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].DefaultCellY, sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].CellX, sizeof(ShortInt) );
    MMbraindata.Write( @Gameover[i].CellY, sizeof(ShortInt) );

    MMbraindata.Write( @Gameover[i].face, sizeof(integer) );
    MMbraindata.Write( @Gameover[i].country, sizeof(smallint) );

    MMbraindata.Write( @Gameover[i].xpDevA, sizeof(smallint) );
    MMbraindata.Write( @Gameover[i].xpDevT, sizeof(smallint) );
    MMbraindata.Write( @Gameover[i].xpDevI, sizeof(smallint) );

  end;

  // save Tsscript fino a 'E' perchè savedata è chiamata alla fine della mossa, non del turno
  Dummy := MMbraindata.Position ;

  str:= AnsiString  ( tsScript[incMove].CommaText );
  LentsScript := Length (str);
  MMbraindata.Write( @LentsScript, sizeof(word) );
  MMbraindata.Write( @str[1] , Length(str) );
  MMbraindata.Position  := 0; // la prima word indica dove comincia tsScript
  MMbraindata.Write( @Dummy, sizeof(word) ); // setto nella integer riservato dove comincia tsscipt

  MMbraindata.Position := MMbraindata.size;
  MMbraindata.Write( @ISMARK[0], 2 );

  if (LogUser [0] > 0) or (LogUser[1] > 0) then begin
    if not DirectoryExists( dir_log + brainIds )  then
      MkDir( dir_log + brainIds );

    MMbraindata.SaveToFile( dir_log +  brainIds  + '\' + Format('%.*d',[3, incMove]) + '.IS'  );
  end;

{
  MMbraindata.SaveToFile( Dir_Data + 'MM.txt'  );

              CompressedStream := TZCompressionStream.Create(MMbraindataZIP, zcDefault); // create the compression stream
              CompressedStream.Write( MMbraindata.Memory , MMbraindata.size); // move and compress the InBuffer string -> destination stream  (MyStream)
              CompressedStream.Free;
              MMbraindataZIP.SaveToFile(Dir_Data + 'MM.zip'  );
  DeCompressedStream:= TZDeCompressionStream.Create( MMbraindataZIP  );
  MM:= TMemoryStream.Create;
  MM.CopyFrom ( DeCompressedStream, 0);
  MMbraindata.SaveToFile( Dir_Data + 'MM2.txt'  );
  MM.Free;   }



//  tsScript.Clear ; da quando è array non devo fare clear




end;


function TBrain.exec_tackle ( ids: string ): integer;
var
  TackleResult , aRnd,aRnd2,preRoll, preRoll2: integer;
  Roll,Roll2:TRoll;
  aPath: dse_pathplanner.Tpath;
  aPlayer, oldPlayerBall: TPlayer;
  dstCell: Tpoint;
  OldCell: TPoint;
  fault, Card , redCard , YellowCard, injured : Integer;
  ACT : string;
begin
{ Tackle è una skill che serve per rubare la palla all'avversario che può essere effettuata da un player adiacente al portatore di palla.
  Vengono messi a confronto l'attributo ballcontrol del portatore di palla contro l'attributo defense di chi cerca di rubare il pallone.
  Se il roll del tackle è minore del roll di ballcontrol, oltre a fallire, il tackle può generare un fallo secondo chance stabilite. A sua
  volta il fallo può generare un cartellino giallo o rosso. Vi sono maggiori probabilità di ricevere un cartellino se il fallo è eseguito da
  dietro il portatore di palla, meno chance di fallo se il tackle è eseguito dal fianco, molto meno chance se il tackle è eseguito da davanti
  il portatore di palla.
  Se il roll del tackle è maggiore o uguale a TackleDiff (2) rispetto al roll sul ballcontrol, oltre a vincere il contrasto e rubare palla,
  si ottiene un bonus +1 all'attributo Shot. Inoltre se la cella in direzione del tackel vincente è libera avanza in questa cella.

  i talenti che interessano questa azione sono:
  TALENT_ID_TOUGHNESS ( +1 Defense durante tackle )
  TALENT_ID_ADVANCED_TOUGHNESS ( 5% chance --> +1 a Defense durante tackle )
  TALENT_ID_POWER  ( +1 ballcontrol durante tutti i tackle )
  TALENT_ID_ADVANCED_POWER  ( 5% chance +1 ballcontrol tutti i tackle )
  TALENT_ID_FAUL  ( +15% chance di commettere un fallo. -30% chance di ricevere un cartellino giallo o rosso )
  TALENT_ID_BOMB ( +1 Shot quando vince un tackle, riceve un short.passing da un player con talento PLAYMAKER in area avversaria,
                    corre con la palla per lameno 2 cella o vince un dribling.
  i talenti sono ovviamente cumulabili durante l'azione.
}

    aPlayer := GeTPlayer (ids);
    if (absDistance (aPlayer.CellX , aPlayer.CellY, Ball.Cellx, Ball.Celly  ) = 1) and
    (Ball.Player.team <> aPlayer.Team ) and( Ball.Player.Role <> 'G') then begin
       // cell per eventuale spostamento e calcolo direzione per cartellini
      ExceptPlayers.Add(aPlayer);
      OldCell := aPlayer.Cells;

       aPath:= dse_pathplanner.TPath.create;
       dstCell.X  := -1;
       GetNextDirectionCell (aPlayer.CellX , aPlayer.CellY, Ball.Cellx, Ball.Celly,1,aPlayer.Team,true,true, aPath  ) ;
       if aPath.Count > 0 then begin
         dstCell.X := aPath[aPath.Count-1].X;
         dstCell.Y := aPath[aPath.Count-1].Y;
       end;
       aPath.Free;

       aPlayer.Stamina := aPlayer.Stamina - cost_tac;
       aPlayer.xpDevA := aPlayer.xpDevA + 1;
       TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_tac)) ;
       ACT := '0';
       aPlayer.tmp:=0;
       if (aPlayer.TalentId1 = TALENT_ID_TOUGHNESS) or (aPlayer.TalentId2 = TALENT_ID_TOUGHNESS) then
        aPlayer.tmp:=1;
       if (aPlayer.TalentId2 = TALENT_ID_ADVANCED_TOUGHNESS) then begin
        if RndGenerate(100) <= 5 then begin
          aPlayer.tmp := aPlayer.tmp + 1;
          ACT := intTostr ( TALENT_ID_ADVANCED_TOUGHNESS );
        end;
       end;

       preRoll := RndGenerate (aPlayer.Defense + aPlayer.tmp);  // durezza
       Roll := AdjustFatigue (aPlayer.Stamina , preRoll);
       aRnd:=  Roll.value;
       aPlayer.xp_defense := aPlayer.xp_Defense + 1;
       aPlayer.xpTal[TALENT_ID_TOUGHNESS] := aPlayer.xpTal[TALENT_ID_TOUGHNESS] + 1;
       aPlayer.xpTal[TALENT_ID_FAUL] := aPlayer.xpTal[TALENT_ID_FAUL] + 1;
       aPlayer.xpTal[TALENT_ID_MARKING] := aPlayer.xpTal[TALENT_ID_MARKING] + 1;

        TsScript[incMove].add ( 'sc_DICE,' +
                                  IntTostr(aPlayer.CellX) + ',' +
                                  Inttostr(aPlayer.CellY) + ',' +
                                  IntTostr(aRnd) + ',' +
                                  IntTostr (aPlayer.Defense) +
                                  ',Tackle,' +
                                  aPlayer.ids + ',' +
                                  IntTostr(Roll.value) + ',' +
                                  Roll.fatigue +
                                  '.0' + ',' +
                                  IntToStr(aPlayer.tmp));

       Ball.Player.tmp:=0;
       ACT := '0';
       if  (Ball.Player.TalentId1 = TALENT_ID_POWER) or (Ball.Player.TalentId2 = TALENT_ID_POWER) then
        Ball.Player.tmp:=1;
       if (Ball.Player.TalentId2 = TALENT_ID_ADVANCED_POWER) then begin
        if RndGenerate(100) <= 5 then begin
          Ball.Player.tmp := Ball.Player.tmp + 1;
          ACT := IntTostr (TALENT_ID_ADVANCED_POWER);
        end;
       end;
        // (Ball.Player.ballControl è minimo a 1 anche se underpressure, e il talento gli conferisce minimo 1 aggiuntivo
       preRoll2 := RndGenerate (Ball.Player.ballControl+ Ball.Player.tmp);
       Roll2 := AdjustFatigue (Ball.Player.Stamina , preRoll2);

       aRnd2:= Roll2.value  ;
       Ball.Player.xp_ballControl:= Ball.Player.xp_ballControl + 1;
       Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
       Ball.Player.xpTal[TALENT_ID_POWER] := Ball.Player.xpTal[TALENT_ID_POWER] + 1;
       if aRnd2 < 0 then aRnd2 :=0;
       ExceptPlayers.Add(ball.player);


        TsScript[incMove].add ( 'sc_DICE,' +
                                IntTostr(Ball.Player.CellX) + ',' +
                                Inttostr(Ball.Player.CellY) + ',' +
                                IntTostr(aRnd2) +',' +
                                IntTostr (  Ball.Player.ballControl ) +
                                ',Ball.Control,'+
                                Ball.Player.ids + ',' +
                                IntTostr(Roll2.value) + ',' +
                                Roll2.fatigue +
                                '.' + ACT + ',' +
                                IntTostr(Ball.Player.tmp));

       // Tackle ok normale ---> player prende la palla oppure tacle ok10 ma non cella dst libera
       //   if (( aRnd >= aRnd2 ) and ( (aRnd-aRnd2) < TackleDiff )) or (( (aRnd-aRnd2) >= TackleDiff ) and (dstCell.X = -1)) then begin

        TackleResult := aRnd-aRnd2;
        if debug_TACKLE_FAILED then TackleResult := -1;

        If ( TackleResult >= TackleDiff ) and (dstCell.X <> -1)  Then begin
          aPlayer.xpDevT := aPlayer.xpDevT + 2; // premio massimo
          oldPlayerBall := Ball.Player;
          // sostituzione
            // guadagna 1 cella anche se usato se il punteggio è alto anche con pressing precedente
          TsScript[incMove].add ('sc_tackle.ok10,' + aPlayer.ids{sfidante} +',' + oldPlayerBall.ids {cella}
                                      + ',' + IntTostr(aPlayer.CellX)+',' + IntTostr(aPlayer.CellY)
                                      + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)
                                      + ',' + IntTostr(dstCell.X)+',' + IntTostr(dstCell.Y)   ) ;

          if (oldPlayerBall.UnderPressureTurn = 0) then TeamMovesLeft := TeamMovesLeft + 1;
          oldPlayerBall.resetALL ;
          Ball.Cells := dstCell;
          aPlayer.Cells := dstCell;
          // bonus di tackle perfect
          aPlayer.BonusTackleTurn := 1 ;
          aPlayer.tmp:=0;
          if (aPlayer.TalentId1 = TALENT_ID_BOMB) or (aPlayer.TalentId2 = TALENT_ID_BOMB) then
            aPlayer.tmp := 1;
          aPLayer.Shot := aPlayer.DefaultShot + 1 + aPlayer.tmp;  // con tackle vinto prende solo +1, con movetoball +2 e dribbling +1
          aPLayer.Passing  := aPlayer.Defaultpassing + 2;
          tsSpeaker.Add( aPlayer.Surname +' (Tackle) vince il contrasto pefettamente su ' + oldPlayerBall.Surname );


        end
//        else If ( (aRnd-aRnd2) >= TackleDiff ) and (dstCell.X <> -1)  Then begin
        else if (( TackleResult >= 0 ) and ( TackleResult < TackleDiff )) or (( TackleResult >= TackleDiff ) and (dstCell.X = -1)) then begin
          if TackleResult < TackleDiff then
            aPlayer.xpDevT := aPlayer.xpDevT + 1 // premio normale
            else if TackleResult >= TackleDiff then
              aPlayer.xpDevT := aPlayer.xpDevT + 2; // premio massimo

          // posso anche vincere di 2 ma non avere spazio per muovere

          oldPlayerBall := Ball.Player;

          TsScript[incMove].add ('sc_tackle.ok,' + aPlayer.ids{sfidante} +',' + oldPlayerBall.ids {cella}
                                      + ',' + IntTostr(aPlayer.CellX)+',' + IntTostr(aPlayer.CellY)
                                      + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)
                                      + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)   ) ;
          SwapPlayers ( aPlayer, Ball.Player );
         // Ball.Player := aPlayer;
          // guadagna 1 punto azione solo se usato senza pressing precedente
          if (oldPlayerBall.UnderPressureTurn = 0) then TeamMovesLeft := TeamMovesLeft + 1;
          oldPlayerBall.resetALL ;
          Ball.Cells := Ball.Player.Cells;
          tsSpeaker.Add( aPlayer.Surname +' (Tackle) vince il contrasto su ' + oldPlayerBall.Surname );

        end
       // else if ( (aRnd-aRnd2) < TackleDiff ) then begin
        else if   TackleResult <= 0    then begin  // tackle fallito , non conta la tacklediff ma la direzione con chance di fallo
          Ball.Player.xpDevT := Ball.Player.xpDevT + 1;
       // non resetto PROPRE
          // perdo il tackle, valito da che direzione arriva
          case GetTackleDirection (aPlayer.Team,aPlayer.CellX,aPlayer.CellY,Ball.Player.CellX,Ball.Player.CellY) of
            TackleBack: begin
              fault := 40;



              Card := 100;
              redCard := 10;
              YellowCard := 90;
              injured:= 10;
              if ball.Player.Fitness = 0 then
                Injured := 15;
              if IsLastMan ( aPlayer, Ball.Player ) then begin
                {$IFDEF ADDITIONAL_MATCHINFO}
                if GameMode = pvp then
                  MatchInfo.Add( IntToStr(fminute) + '.lastman.' + aPlayer.ids)
                  else  MatchInfo.Add( IntToStr(fminute) + '.lastman.' + aPlayer.ids+'.'+aPlayer.SurName);
                  {$ENDIF}
                redCard := 100;
                YellowCard := 0;
              end;
            end;
            TackleSide: begin
              fault := 25;

              Card := 40;
              redCard := 5;
              YellowCard := 95;
              injured:= 5;
              if ball.Player.Fitness = 0 then
                Injured := 10;
              // se è l'ultimo uomo la chance di essere espulso è del 100%
              if IsLastMan ( aPlayer, Ball.Player ) then begin
                {$IFDEF ADDITIONAL_MATCHINFO}
                if GameMode = pvp then
                  MatchInfo.Add( IntToStr(fminute) + '.lastman.' + aPlayer.ids)
                  else  MatchInfo.Add( IntToStr(fminute) + '.lastman.' + aPlayer.ids+'.'+aPlayer.SurName);
                  {$ENDIF}

                redCard := 100;
                YellowCard := 0;
              end;
            end;
            TackleAhead: begin
              fault := 15;
              Card := 30;
              redCard := 1;
              YellowCard := 99;
              // se è l'ultimo uomo  la chance di essere espulso è del 100%
              if IsLastMan ( aPlayer, Ball.Player ) then begin
                {$IFDEF ADDITIONAL_MATCHINFO}
                if GameMode = pvp then
                  MatchInfo.Add( IntToStr(fminute) + '.lastman.' + aPlayer.ids)
                  else  MatchInfo.Add( IntToStr(fminute) + '.lastman.' + aPlayer.ids+'.'+aPlayer.SurName);
                  {$ENDIF}
                redCard := 100;
                YellowCard := 0;
              end;
            end;
          end;

          if (aPlayer.TalentId1 = TALENT_ID_FAUL) or (aPlayer.TalentId2 = TALENT_ID_FAUL) then
            fault := fault + 15;
          if (Ball.Player.TalentId1 = TALENT_ID_DIVING) or (Ball.Player.TalentId2 = TALENT_ID_DIVING) then
            fault := fault + 10;

          aPlayer.CanSkill := False;
          TsScript[incMove].add ('sc_tackle.no,' + aPlayer.ids{sfidante} +',' + Ball.Player.ids {cella}
                                      + ',' + IntTostr(aPlayer.CellX)+',' + IntTostr(aPlayer.CellY)
                                      + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)
                                      + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)   ) ;

          aRnd := RndGenerate(100);
          if debug_SETRED then begin
              fault := 100;
              Card := 100;
              redCard := 99;
              YellowCard := 1;
          end;
          if debug_SETFAULT then fault := 100;


          if aRnd <= fault then begin   // se è fallo
//            TsScript[incMove].add ('sc_tackle.fault,' + aPlayer.ids{sfidante} +',' + Ball.Player.ids {cella}
//                                        + ',' + IntTostr(aPlayer.CellX)+',' + IntTostr(aPlayer.CellY)
//                                        + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)
//                                        + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)   ) ;
            Ball.Player.XpTal[TALENT_ID_DIVING] := Ball.Player.XpTal[TALENT_ID_DIVING] + 1;
            if (aPlayer.TalentId1 = TALENT_ID_FAUL) or (aPlayer.TalentId2 = TALENT_ID_FAUL) then begin  // questo talento abbassa la chance di prendere un cartellino
              Card := Card -30;
              if Card < 0 then card := 0;
            end;
            aRnd := RndGenerate(100);
            if aRnd <= Card then begin // cartellino
              aRnd := RndGenerate(100);
              if aRnd <= redCard then begin // cartellino rosso
                  TsScript[incMove].add ('sc_red,' + aPlayer.ids + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)) ;
                  aPlayer.Role := 'N';
                  aPlayer.RedCard :=  1;
                  aPlayer.Gameover := true;
                  aPlayer.CanMove := False;
                  //PutInGameOverSlot ( aPlayer );
                if GameMode = pvp then
                  MatchInfo.Add( IntToStr(fminute) + '.rc.' + aPlayer.ids)
                  else  MatchInfo.Add( IntToStr(fminute) + '.rc.' + aPlayer.ids+'.'+aPlayer.SurName);

                  AddSoccerGameOver(aPlayer);
                  RemoveSoccerPlayer(aPlayer);
              end
              else  begin   // carsctellino giallo
              // calcolo doppia ammonizione
                  aPlayer.YellowCard :=  aPlayer.YellowCard + 1;
                if GameMode = pvp then
                  MatchInfo.Add( IntToStr(fminute) + '.yc.' + aPlayer.ids)
                  else  MatchInfo.Add( IntToStr(fminute) + '.yc.' + aPlayer.ids+'.'+aPlayer.SurName);

                  if aPlayer.YellowCard = 1 then
                    TsScript[incMove].add ('sc_yellow,' + aPlayer.ids + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY))

                  else if aPlayer.YellowCard = 2 then begin
                    TsScript[incMove].add ('sc_yellowred,' + aPlayer.ids +',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY) ) ;
                    aPlayer.Role := 'N';
                    aPlayer.Gameover := true;
                    //layer.RedCard :=  1;  no redcard diretto
                    aPlayer.CanMove := False;
                    //PutInReserveSlot(aPlayer);
                    AddSoccerGameOver(aPlayer);
                    RemoveSoccerPlayer(aPlayer);
                    if GameMode = pvp then
                      MatchInfo.Add( IntToStr(fminute) + '.rc.' + aPlayer.ids)
                      else  MatchInfo.Add( IntToStr(fminute) + '.rc.' + aPlayer.ids+'.'+aPlayer.SurName);
                  end;
              end;
            end;
            if aRnd <= injured then begin
                    TsScript[incMove].add ('sc_injured,' + Ball.Player.ids +',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY) ) ;
                    Ball.Player.CanMove := False;
//                    aPlayer.CanSkill := False;
                    Ball.Player.Injured := 1;
                    Ball.Player.Stamina := 0;
                  //  aPlayer.DefaultCells := Point(-92,-92);
                  //  aPlayer.Cells := Point(-92,-92);
            end;


          // quello che ha subito il fallo è ancora in possesso di palla. è injured, può calciare il freekick
            Result := GetFault ( Ball.Player.Team, Ball.CellX, Ball.CellY);
          end
          else Result := 0;

        end;

    end;
end;
Function TBrain.GetFault ( team, CellX, CellY : integer): Integer;
begin

  case team of
    0: begin
      if (CellX = 10) and ((CellY = 2) or (CellY = 3)  or (CellY = 4)) then begin
        Result := 4; // rigore
        Exit;
      end;
      if (CellX = 9) and ((CellY = 2) or (CellY = 3)  or (CellY = 4)) then begin
        Result := 4; // rigore
        Exit;
      end;
    end;
    1: begin
      if (CellX = 1) and ((CellY = 2) or (CellY = 3)  or (CellY = 4)) then begin
        Result := 4; // rigore
        Exit;
      end;
      if (CellX = 2) and ((CellY = 2) or (CellY = 3)  or (CellY = 4)) then begin
        Result := 4; // rigore
        Exit;
      end;
    end;
  end;

  // qui è scluso il rigore

  if (Team = 0) and (CellX > 5) then
     Result:= 2
  else if (Team = 0) and (CellX <= 5) then
    Result := 1
  else if (Team = 1) and (CellX < 6) then
    Result := 2
  else if (Team = 1) and (CellX >= 6) then
    Result := 1;

  if Result = 2 then begin // se nella metacampo avversaria o cross o barriera
    case team of
      0: begin
        if  (CellX = 9) or (CellX = 8)  then begin
          Result := 3;
        end
        else if  ( (CellY = 0) or (CellX = 6) ) and (CellX = 10)   then begin
          Result := 2; // cross
        end;

      end;
      1: begin
      if  (CellX = 3) or (CellX = 2)  then begin
        Result := 3;  // barriera
      end
      else if ( (CellY = 0) or (CellX = 6) ) and (CellX = 0)   then begin
        Result := 2; // cross
      end;

    end;
    end;
  end;
end;
function TBrain.exec_autotackle ( ids: string; LastPath: boolean ): boolean;
var
  aRnd,aRnd2,preRoll, preRoll2: integer;
  Roll,Roll2:TRoll;
  aPath: dse_pathplanner.TPath;
  aPlayer, oldPlayerBall: TPlayer;
  dstCell: Tpoint;
  OldCell: TPoint;
  ACT : string;
begin
{ autotackle viene eseguito nel turno dell'avversario da un player che può intercettare il portatore di palla mentre si muove. Vengono messi a
  confronto l'attributo ballcontrol del portatore di palla contro l'attributo defense di chi cerca di rubare il pallone. A differenza del tackle
  normale non viene mai generato un fallo. i talenti che interessano questa azione sono:
  TALENT_ID_CHALLENGE ( +1 Defense durante autotackle )
  TALENT_ID_ADVANCED_CHALLENGE ( 5% chance --> +1 a Defense durante autotackle )
  TALENT_ID_POWER  ( +1 ballcontrol durante tutti i tackle )
  TALENT_ID_ADVANCED_POWER  ( 5% chance +1 ballcontrol tutti i tackle )
  i talenti sono ovviamente cumulabili durante l'azione.
}
    result := false;
    aPlayer := GeTPlayer ( ids );
    if aPlayer = nil then exit; // hack
    if not aPlayer.CanSkill then  exit; // hack
    if (absDistance (aPlayer.CellX , aPlayer.CellY, Ball.Cellx, Ball.Celly  ) = 1) and
    (Ball.Player.team <> aPlayer.Team ) then begin
       // cell per eventuale spostamento e calcolo direzione per cartellini
      OldCell := aPlayer.Cells;
       ExceptPlayers.Add(Ball.player); // nel successivo AI_MoveAll non si potrà muovere

       aPath:= dse_pathplanner.TPath.create;
       dstCell.X  := -1;
       GetNextDirectionCell (aPlayer.CellX , aPlayer.CellY, Ball.Cellx, Ball.Celly,1,aPlayer.Team,true,true, aPath  ) ;
       if aPath.Count > 0 then begin
         dstCell.X := aPath[aPath.Count-1].X;
         dstCell.Y := aPath[aPath.Count-1].Y;
       end;
       aPath.Free;


       aPlayer.Stamina := aPlayer.Stamina - cost_autotac; // 3 tackle normale
       aPlayer.xpDevA := aPlayer.xpDevA + 1;
       TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_autotac) ) ;
       preRoll := RndGenerate (aPlayer.Defense);
       Roll := AdjustFatigue (aPlayer.Stamina , preRoll);


       // elaboro i talenti Challenge e advanced Challenge ( autotackle ) ed eseguo il roll
       aPlayer.tmp:=0;
       if (aPlayer.TalentId1 = TALENT_ID_CHALLENGE)  or (aPlayer.TalentId2 = TALENT_ID_CHALLENGE) then
        aPlayer.tmp := 1;
       if aPlayer.TalentId2 = TALENT_ID_ADVANCED_CHALLENGE then
        if RndGenerate(100) < 5 then aPlayer.tmp := aPlayer.tmp + 1;

       // roll autotackle di chi cerca di rubare palla con autotackle
       aRnd:=  Roll.value +  aPlayer.tmp ; // lottatore
       aPlayer.xp_defense := aPlayer.xp_Defense + 1;
       aPlayer.xpTal[TALENT_ID_CHALLENGE] :=  aPlayer.xpTal[TALENT_ID_CHALLENGE] +1;
       aPlayer.xpTal[TALENT_ID_MARKING] := aPlayer.xpTal[TALENT_ID_MARKING] + 1;

       preRoll2 := RndGenerate (Ball.Player.ballControl);
       Roll2 := AdjustFatigue (Ball.Player.Stamina , preRoll2);
       Ball.Player.tmp:=0;
       ACT := '0';
       // elaboro i talenti Challenge e advanced Power ( resist every tackle )  ed eseguo il roll
       if  (Ball.Player.TalentId1 = TALENT_ID_POWER)  or  (Ball.Player.TalentId2 = TALENT_ID_POWER) then
         Ball.Player.tmp := 1;
       if Ball.Player.TalentId2 = TALENT_ID_ADVANCED_POWER then begin
        if RndGenerate(100) <= 5 then begin
          Ball.Player.tmp := Ball.Player.tmp + 1;
          ACT := intTostr (TALENT_ID_ADVANCED_POWER);
        end;
       end;
       // roll autotackle di chi difende palla
       aRnd2:= Roll2.value + Ball.Player.tmp ; //  resiste aigli autotackle e ai tackle  toughness
       Ball.Player.xp_ballControl:= Ball.Player.xp_ballControl + 1;
       Ball.Player.xpTal[TALENT_ID_POWER] :=  Ball.Player.xpTal[TALENT_ID_POWER] +1;
       Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
       if aRnd2 < 0 then aRnd2 :=0;


      if ( aRnd > aRnd2 )  then begin // Tackle ---> player prende la palla
        {  malus da dietro, e 50% fallo e cartellino }
        aPlayer.xpdevT := aPlayer.xpdevT + 1;
        oldPlayerBall := Ball.Player;
        TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +','+
        IntTostr ( aPlayer.Defense )+',Tackle,'+ aPlayer.ids+','+IntTostr(Roll.value)+','+Roll.fatigue+'.0' + ','+IntToStr(aPlayer.tmp));

        TsScript[incMove].add ( 'sc_DICE,' + IntTostr(oldPlayerBall.CellX) + ',' + Inttostr(oldPlayerBall.CellY) +','+  IntTostr(aRnd2) +','+
        IntTostr(oldPlayerBall.ballControl) +',Ball.Control,'+  oldPlayerBall.ids+','+IntTostr(Roll2.value)+','+Roll2.fatigue+ '.' + ACT +','+IntToStr(oldPlayerBall.tmp));

        SwapPlayers ( aPlayer, Ball.Player );
        TsScript[incMove].add ('sc_swap,' + aPlayer.ids{sfidante} +',' + oldPlayerBall.ids {cella}
        + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY) {celle} + ',' + IntTostr(OldCell.x)+',' + IntTostr(OldCell.Y) {provenienza PlayerB}  ) ;
        Ball.Cells := Ball.Player.Cells;
          result := true;
        tsSpeaker.Add( aPlayer.Surname +' (Tackle) vince il contrasto su ' + oldPlayerBall.Surname );

        //arnd:= 12;
        if( (aRnd-aRnd2) >= TackleDiff ) and (dstCell.X <> -1)  then begin // si sposta in avanti
          // sostituzione
          aPlayer.xpdevT := aPlayer.xpdevT + 2; // premio massimo
          aPlayer.Cells := dstCell;
          TsScript[incMove].add ('sc_player.move,'+ aPlayer.Ids +','+IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)+','+  IntTostr(dstCell.X)+','+ IntTostr(dstCell.Y)  ) ;
          TsScript[incMove].add ('sc_ball.move,'+ IntTostr(Ball.CellX)+','+ IntTostr(Ball.CellY)+','+  IntTostr(dstCell.X)+','+ IntTostr(dstCell.Y)+',0,0'  ) ;
          Ball.CellS := dstCell;

        end;
      end
      else begin   // il player non prende la palla. comunque ci ha provato
        Ball.Player.xpDevT := Ball.Player.xpDevT + 1;


        oldPlayerBall := Ball.Player;
       // non resetto PROPRE

        TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aPlayer.CellX) + ',' + Inttostr(aPlayer.CellY) +','+  IntTostr(aRnd) +',' +
        IntTostr ( aPlayer.Defense )+',Tackle,'+ aPlayer.ids+','+IntTostr(Roll.value)+','+Roll.fatigue+'.0' + '.0'+','+IntToStr(aPlayer.tmp));
        TsScript[incMove].add ( 'sc_DICE,' + IntTostr(oldPlayerBall.CellX) + ',' + Inttostr(oldPlayerBall.CellY) +','+  IntTostr(aRnd2) +','+
        IntTostr(oldPlayerBall.ballControl ) +',Ball.Control,'+  oldPlayerBall.ids+','+IntTostr(Roll2.value)+','+Roll2.fatigue+ '.' + ACT+','+IntToStr(oldPlayerBall.tmp));
       // if not LastPath then begin
       //   TsScript[incMove].add ('sc_player.move,'+ aPlayer.Ids +','+IntTostr(OldCell.X)+','+ IntTostr(OldCell.Y)+','+  IntTostr(aPlayer.cellX)+','+ IntTostr(aPlayer.cellY)  );
       //   aPlayer.Cells := ball.Cells;
       // end
       // else
        TsScript[incMove].add ( 'sc_noswap,' + aPlayer.ids{sfidante} +',' + Ball.Player.ids {cella} + ',' + IntTostr(Ball.Player.CellX)+',' + IntTostr(Ball.Player.CellY)
         + ',' + IntTostr(OldCell.x)+',' + IntTostr(OldCell.Y) {provenienza PlayerB}   ) ;
      end;
    end;
end;

function TBrain.FindSwapCOAD (  SwapPlayer: TPlayer; CornerMap: TCornerMap ): Tpoint;
var
  x: integer;
  function inExceptCells ( aList:TList<Tpoint>;X,Y: integer): boolean;
  var
  i: integer;
  begin
    Result := false;
    if aList.Count = 0 then exit;      // bug delphi

    for I := 0 to aList.count do begin
      if (aList[i].X = X ) and (aList[i].X = Y )then begin
        result := true;
        exit;
      end;

    end;

  end;
begin
// swap coa e cod
// compagno e avversari vanno indietro ( una libera esiste per forza 21 celle - portieri e cof e 2 di swap attuale)
// SwapPlayer.CellY è per forza 2,3,4

(* favorisce il ritorno al centro *)

  case CornerMap.Team of
    1: begin
      for X := 3 to 10 do begin
        if GeTPlayer ( X, 3 ) = nil then begin
            Result := point (X, 3);
            exit;
        end;
        if GeTPlayer ( X, 2) = nil then begin
            Result := point (X, 2);
            exit;
        end;
        if GeTPlayer ( X, 4) = nil then begin
            Result := point (X, 4);
            exit;
        end;
        if GeTPlayer ( X, 5) = nil then begin
            Result := point (X, 5);
            exit;
        end;
        if GeTPlayer ( X, 1) = nil then begin
            Result := point (X, 1);
            exit;
          end;
        if GeTPlayer ( X, 6) = nil then begin
            Result := point (X, 6);
            exit;
        end;
        if GeTPlayer ( X, 0) = nil then begin
            Result := point (X, 0);
            exit;
        end;
      end;
    end;
    0: begin
      for X := 8 downto 1 do begin
        if GeTPlayer ( X, 3 ) = nil then begin
            Result := point (X, 3);
            exit;
        end;
        if GeTPlayer ( X, 2) = nil then begin
            Result := point (X, 2);
            exit;
        end;
        if GeTPlayer ( X, 4) = nil then begin
            Result := point (X, 4);
            exit;
        end;
        if GeTPlayer ( X, 5) = nil then begin
            Result := point (X, 5);
            exit;
        end;
        if GeTPlayer ( X, 1) = nil then begin
            Result := point (X, 1);
            exit;
        end;
        if GeTPlayer ( X, 6) = nil then begin
            Result := point (X, 6);
            exit;
        end;
        if GeTPlayer ( X, 0) = nil then begin
            Result := point (X, 0);
            exit;
        end;
      end;
    end;

  end;
end;

function TBrain.FindDefensiveCellFree (  team: integer ): Tpoint;
var
  X: Integer;
begin
(* simile a FindSwapCOAD .favorisce il ritorno al centro *)
  case Team of
    1: begin
      for X := 10 downto 1 do begin
        if GeTPlayer ( X, 3 ) = nil then begin
            Result := point (X, 3);
            exit;
        end;
        if GeTPlayer ( X, 2) = nil then begin
            Result := point (X, 2);
            exit;
        end;
        if GeTPlayer ( X, 4) = nil then begin
            Result := point (X, 4);
            exit;
        end;
        if GeTPlayer ( X, 5) = nil then begin
            Result := point (X, 5);
            exit;
        end;
        if GeTPlayer ( X, 1) = nil then begin
            Result := point (X, 1);
            exit;
          end;
        if GeTPlayer ( X, 6) = nil then begin
            Result := point (X, 6);
            exit;
        end;
        if GeTPlayer ( X, 0) = nil then begin
            Result := point (X, 0);
            exit;
        end;
      end;
    end;
    0: begin
      for X := 1 to 10 do begin
        if GeTPlayer ( X, 3 ) = nil then begin
            Result := point (X, 3);
            exit;
        end;
        if GeTPlayer ( X, 2) = nil then begin
            Result := point (X, 2);
            exit;
        end;
        if GeTPlayer ( X, 4) = nil then begin
            Result := point (X, 4);
            exit;
        end;
        if GeTPlayer ( X, 5) = nil then begin
            Result := point (X, 5);
            exit;
        end;
        if GeTPlayer ( X, 1) = nil then begin
            Result := point (X, 1);
            exit;
        end;
        if GeTPlayer ( X, 6) = nil then begin
            Result := point (X, 6);
            exit;
        end;
        if GeTPlayer ( X, 0) = nil then begin
            Result := point (X, 0);
            exit;
        end;
      end;
    end;

  end;
end;
function TBrain.FindDefensiveCellFreePenalty (  team: integer ): Tpoint;
var
  X: Integer;
begin
(* simile a FindSwapCOAD .favorisce il ritorno al centro *)
  case Team of
    0: begin
      for X := 8 downto 1 do begin
        if GeTPlayer ( X, 3 ) = nil then begin
            Result := point (X, 3);
            exit;
        end;
        if GeTPlayer ( X, 2) = nil then begin
            Result := point (X, 2);
            exit;
        end;
        if GeTPlayer ( X, 4) = nil then begin
            Result := point (X, 4);
            exit;
        end;
        if GeTPlayer ( X, 5) = nil then begin
            Result := point (X, 5);
            exit;
        end;
        if GeTPlayer ( X, 1) = nil then begin
            Result := point (X, 1);
            exit;
          end;
        if GeTPlayer ( X, 6) = nil then begin
            Result := point (X, 6);
            exit;
        end;
        if GeTPlayer ( X, 0) = nil then begin
            Result := point (X, 0);
            exit;
        end;
      end;
    end;
    1: begin
      for X := 3 to 10 do begin
        if GeTPlayer ( X, 3 ) = nil then begin
            Result := point (X, 3);
            exit;
        end;
        if GeTPlayer ( X, 2) = nil then begin
            Result := point (X, 2);
            exit;
        end;
        if GeTPlayer ( X, 4) = nil then begin
            Result := point (X, 4);
            exit;
        end;
        if GeTPlayer ( X, 5) = nil then begin
            Result := point (X, 5);
            exit;
        end;
        if GeTPlayer ( X, 1) = nil then begin
            Result := point (X, 1);
            exit;
        end;
        if GeTPlayer ( X, 6) = nil then begin
            Result := point (X, 6);
            exit;
        end;
        if GeTPlayer ( X, 0) = nil then begin
            Result := point (X, 0);
            exit;
        end;
      end;
    end;

  end;
end;
function TBrain.GetOpponentDoor (SelectedPlayer: TPlayer ): TPoint;
begin
   if SelectedPlayer.Team = 0 then begin
      Result.X :=11;
      Result.Y :=3;
   end
   else begin
      Result.X :=0;
      Result.Y :=3;
   end;
end;
function TBrain.GetCorner (Team: Integer; Y: integer; CornerMode: TCornerMode ): TCornerMap;
begin

   if CornerMode = FriendlyCorner then begin
     if Team = 0  then team := 1
      else if Team = 1 then Team:=0;
   end;


// nell'area l'elemento 0 è il centrale, 1 il più vicino al corner, 2 il più lontano
   case Team of
    0: begin
      if Y < 3 then begin
        Result.Team := 0;
        Result.GK.X := 11;
        Result.GK.Y := 3;
        Result.CornerCell.X :=10;
        Result.CornerCell.Y :=0;
        Result.HeadingCellA[0].X := 9;
        Result.HeadingCellA[0].Y := 3;
        Result.HeadingCellA[1].X := 9;
        Result.HeadingCellA[1].Y := 2;
        Result.HeadingCellA[2].X := 9;
        Result.HeadingCellA[2].Y := 4;
        Result.HeadingCellD[0].X := 10;
        Result.HeadingCellD[0].Y := 3;
        Result.HeadingCellD[1].X := 10;
        Result.HeadingCellD[1].Y := 2;
        Result.HeadingCellD[2].X := 10;
        Result.HeadingCellD[2].Y := 4;
      end
      else begin
        Result.Team := 0;
        Result.GK.X := 11;
        Result.GK.Y := 3;
        Result.CornerCell.X :=10;
        Result.CornerCell.Y :=6;
        Result.HeadingCellA[0].X := 9;
        Result.HeadingCellA[0].Y := 3;
        Result.HeadingCellA[1].X := 9;
        Result.HeadingCellA[1].Y := 2;
        Result.HeadingCellA[2].X := 9;
        Result.HeadingCellA[2].Y := 4;
        Result.HeadingCellD[0].X := 10;
        Result.HeadingCellD[0].Y := 3;
        Result.HeadingCellD[1].X := 10;
        Result.HeadingCellD[1].Y := 2;
        Result.HeadingCellD[2].X := 10;
        Result.HeadingCellD[2].Y := 4;
      end;
    end;
    1: begin
      if Y < 3 then begin
        Result.Team := 1;
        Result.GK.X := 0;
        Result.GK.Y := 3;
        Result.CornerCell.X :=1;
        Result.CornerCell.Y :=0;
        Result.HeadingCellA[0].X := 2;
        Result.HeadingCellA[0].Y := 3;
        Result.HeadingCellA[1].X := 2;
        Result.HeadingCellA[1].Y := 2;
        Result.HeadingCellA[2].X := 2;
        Result.HeadingCellA[2].Y := 4;
        Result.HeadingCellD[0].X := 1;
        Result.HeadingCellD[0].Y := 3;
        Result.HeadingCellD[1].X := 1;
        Result.HeadingCellD[1].Y := 2;
        Result.HeadingCellD[2].X := 1;
        Result.HeadingCellD[2].Y := 4;
      end
      else begin
        Result.Team := 1;
        Result.GK.X := 0;
        Result.GK.Y := 3;
        Result.CornerCell.X :=1;
        Result.CornerCell.Y :=6;
        Result.HeadingCellA[0].X := 2;
        Result.HeadingCellA[0].Y := 3;
        Result.HeadingCellA[1].X := 2;
        Result.HeadingCellA[1].Y := 2;
        Result.HeadingCellA[2].X := 2;
        Result.HeadingCellA[2].Y := 4;
        Result.HeadingCellD[0].X := 1;
        Result.HeadingCellD[0].Y := 3;
        Result.HeadingCellD[1].X := 1;
        Result.HeadingCellD[1].Y := 2;
        Result.HeadingCellD[2].X := 1;
        Result.HeadingCellD[2].Y := 4;
      end;
    end;

   end;

end;
function TBrain.GetBarrierCell (Team: Integer; CellX, CellY: integer ): TPoint; // in base alla cella della punizione, ottengo la cella barriera
begin
  case Team of
    0: begin
      case CellX of
        9: begin
          case CellY of
            0: begin
              Result := Point (10,2);
            end;
            1: begin
              Result := Point (10,2);
            end;
            2: begin
              Result := Point (10,3);
            end;
            3: begin
              Result := Point (10,3);
            end;
            4: begin
              Result := Point (10,3);
            end;
            5: begin
              Result := Point (10,4);
            end;
            6: begin
              Result := Point (10,4);
            end;
          end;

        end;
        8: begin
          case CellY of
            0: begin
              Result := Point (9,1);
            end;
            1: begin
              Result := Point (9,2);
            end;
            2: begin
              Result := Point (9,3);
            end;
            3: begin
              Result := Point (9,3);
            end;
            4: begin
              Result := Point (9,4);
            end;
            5: begin
              Result := Point (9,4);
            end;
            6: begin
              Result := Point (9,5);
            end;
          end;

        end;
      end;
    end;
    1: begin
      case CellX of
        2: begin
          case CellY of
            0: begin
              Result := Point (1,2);
            end;
            1: begin
              Result := Point (1,2);
            end;
            2: begin
              Result := Point (1,3);
            end;
            3: begin
              Result := Point (1,3);
            end;
            4: begin
              Result := Point (1,3);
            end;
            5: begin
              Result := Point (1,4);
            end;
            6: begin
              Result := Point (1,4);
            end;
          end;

        end;
        3: begin
          case CellY of
            0: begin
              Result := Point (2,1);
            end;
            1: begin
              Result := Point (2,2);
            end;
            2: begin
              Result := Point (2,3);
            end;
            3: begin
              Result := Point (2,3);
            end;
            4: begin
              Result := Point (2,4);
            end;
            5: begin
              Result := Point (2,4);
            end;
            6: begin
              Result := Point (2,5);
            end;
          end;
        end;
      end;

    end;
   end;

end;
function TBrain.GetPenaltyCell (Team: Integer ): TPoint;// in base al team (0 o 1) ottengo la cella del rigore
begin
  if team = 0  then
    Result := Point (10,3)
    else Result := Point (1,3);
end;
procedure TBrain.FreePenaltyArea ( team : Integer  ); // libero l'area di rigore da altri gioatory per il penalty
var
  p: Integer;
  aPlayer: TPlayer;
begin
  case team of
    0: begin   // il rigore a 10,3
      for p := Players.Count -1 downto 0 do begin
        aPlayer := Players[p];
        if  IsOutSide(aPlayer.CellX, aPlayer.CellY) then Continue;
        if (aPlayer.CellX >= 9) and (aPlayer.Role <> 'G') then begin
          aPlayer.cells := FindDefensiveCellFreePenalty ( team ); // lo sposto in una cella libera fuori dall'area di rigore
        end;
      end;
    end;
    1: begin   // il rigore a 1,3
      for p := Players.Count -1 downto 0 do begin
        aPlayer := Players[p];
        if  IsOutSide(aPlayer.CellX, aPlayer.CellY) then Continue;
        if (aPlayer.CellX <= 2) and (aPlayer.Role <> 'G') then begin
          aPlayer.cells := FindDefensiveCellFreePenalty ( team ); // lo sposto in una cella libera fuori dall'area di rigore
        end;
      end;
    end;
  end;
end;

function TBrain.IsCheatingBall ( TeamFault: Integer ) : boolean;
var
  aCellList: TList<TPoint>;
  i: integer;
  aPlayer: TPlayer;
begin
  { TODO : bug se all'inizio la palla è del gk non è raggiungibile }
  // TeamFault rende irragiungibile la palla
  Result := true;   // parte che è cheating
  aCellList:= TList<TPoint>.Create;
  GetNeighbournsCells( Ball.CellX, Ball.CellY,1,False,True,False,aCellList );  // prendo tutti i player, elimino i fuoricampo, si ai GK

  // ho le celle adiacenti. se sono tutte occupate da player del teamfault è cheating
  for I := 0 to aCellList.Count -1 do begin
    aPlayer:= GeTPlayer ( acellList[i].X, acellList[i].Y );
    if aPlayer = nil then begin   // se la cella è vuota la strada è libera verso la palla
      result := False;
      Break;
    end
    else Begin // c'è un player
      if aPlayer.Team <> TeamFault then begin // se è diverso la strada è libera verso la palla
        result := False;
        Break;
      end;
    End;

  end;


  acellList.free;
end;
function TBrain.IsCheatingBallGK ( OldTeamTurn: Integer ) : boolean;
begin
  result := False;
  if Ball.Player = nil then Exit;

  if GetGK ( OldTeamTurn ).Ids = Ball.Player.ids  then
    result := True;

end;
function TBrain.NextReserveSlot ( team: integer ): Integer;
var
  x: Integer;
begin
    Result := 0;
    for x := 0 to 10 do begin
        if ReserveSlot [team,x] = '' then begin
          Result := x;
          Exit;
      end;
    end;
end;
procedure TBrain.CleanReserveSlot ( team: integer );
var
  x: Integer;
begin
    for x := 0 to 10 do begin
          ReserveSlot [team, x] := '';
    end;
end;
function TBrain.NextGameOverSlot ( aPlayer: TPlayer): Integer;
var
  x: Integer;
begin
  for x := 0 to 21  do begin
    if GameOverSlot [aPlayer.team,x] = '' then begin
      Result := x;
      Exit;
    end;
  end;
end;
function TBrain.NextGameOverSlot ( team: integer ): Integer;
var
  x: Integer;
begin
    Result := 0;
    for x := 0 to 10 do begin
        if GameOverSlot [team,x] = '' then begin
          Result := x;
          Exit;
      end;
    end;
end;
procedure TBrain.CleanGameOverSlot ( team: integer );
var
  x: Integer;
begin
    for x := 0 to 10 do begin
          GameOverSlot [team, x] := '';
    end;
end;

function TBrain.GetOpponentStart (SelectedPlayer: TPlayer ): TPoint;
begin
   if SelectedPlayer.Team = 0 then begin
      Result.X :=6;
      Result.Y :=3;
   end
   else begin
      Result.X :=5;
      Result.Y :=3;
   end;
end;

procedure TBrain.exec_corner ;
var
  aRnd  , aRnd2, preRoll, preRoll2, preroll3, arnd3, preroll4, arnd4,GKxpr: integer;
  Roll, Roll2, roll3, roll4: TRoll;
  aPlayer, aheadingFriend, aHeadingOpponent, aGK : TPlayer;
  CornerMap: TCornerMap;
  aCell:Tpoint;
  oldCell: Tpoint;
  CrossBarN,BonusDefenseHeading : integer;
  ACT : string;
  label cor_crossbar;
begin
  // sono schierati 3 coa ( corner attaccanti ) contro 3 cod ( corner difensori). La palla cade in una di queste cell random
  // CornerMap.HeadingCellA e CornerMap.HeadingCellD sono le 3 celle di attacco e difesa

  w_CornerSetup:= false;                                              // il corner viene proprio eseguito
  CornerMap := GetCorner ( TeamTurn , Ball.CellY, OpponentCorner );   // ottengo la mappa delle celle di quel corner
  TeamCorner := -1;                                                   // non è più corner
  aPlayer := GetCof ;                                                 // trovo il player che batte il corner ( Corner Freekick )
  aPlayer.isCOF := false;                                             // non sarà più cof
  tsSpeaker.Add( aPlayer.Surname +' batte il corner '   );


  // informo il client
  TsScript[incMove].add ('SERVER_COR,' + aplayer.ids + ','+ IntTostr(aPlayer.CellX) +',' + inttostr(aPlayer.CellY) + ',' +
                                                IntTostr(CornerMap.HeadingCellA [0].X) + ',' + IntTostr(CornerMap.HeadingCellA [0].Y)) ;
  aPlayer.Stamina := aPlayer.Stamina - cost_cor;
  aPlayer.xpDevA := aPlayer.xpDevA + 1;
  TsScript[incMove].add ('ST,' + aPlayer.ids +',' + IntToStr(cost_cor) ) ;

  preRoll := RndGenerate (aPlayer.passing);
  Roll := AdjustFatigue(aPlayer.Stamina,PreRoll);
  aPlayer.tmp :=0;
  if (aPlayer.TalentId1 = TALENT_ID_CROSSING) or (aPlayer.TalentId2 = TALENT_ID_CROSSING) then
    aPlayer.tmp := 1;
     { TODO -csviluppo : valutare se fare valori m e f }
  aRnd:= Roll.value + aPlayer.tmp;
  if debug_SetAlwaysGol then arnd := 20;

  BonusDefenseHeading := 0;
        TsScript[incMove].add ( 'sc_DICE,' + IntTostr(CornerMap.CornerCell.X) + ',' + Inttostr(CornerMap.CornerCell.Y) +','+  IntTostr(aRnd) +',' +
        IntToStr(aPlayer.Passing ) +',Crossing,'+ aPlayer.ids+','+IntTostr(Roll.value)+','+Roll.fatigue+ '.0'+','+IntTostr(aPlayer.tmp));
      if (aRnd >= COR_D2_MIN) and (aRnd <= COR_D2_MAX) then begin  //  palla a headingD [2]
        Ball.Cells :=  Point (CornerMap.HeadingCellD [2].X , CornerMap.HeadingCellD [2].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [2].X , CornerMap.HeadingCellA [2].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [2].X , CornerMap.HeadingCellD [2].Y  );
        BonusDefenseHeading := 1;
      end
      else if (aRnd >= COR_D1_MIN) and (aRnd <= COR_D1_MAX) then begin  //  palla a headingD [1]
        Ball.Cells :=  Point (CornerMap.HeadingCellD [1].X , CornerMap.HeadingCellD [1].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [1].X , CornerMap.HeadingCellA [1].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [1].X , CornerMap.HeadingCellD [1].Y  );
        BonusDefenseHeading := 1;

      end
      else if (aRnd >= COR_D0_MIN) and (aRnd <= COR_D0_MAX) then begin  //  palla a headingD [0]
        Ball.Cells :=  Point (CornerMap.HeadingCellD [0].X , CornerMap.HeadingCellD [0].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [0].X , CornerMap.HeadingCellA [0].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [0].X , CornerMap.HeadingCellD [0].Y  );
        BonusDefenseHeading := 1;

      end
      else if (aRnd >= COR_A2_MIN) and (aRnd <= COR_A2_MAX) then begin  //  palla a headingA [2]
        Ball.Cells :=  Point (CornerMap.HeadingCellA [2].X , CornerMap.HeadingCellA [2].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [2].X , CornerMap.HeadingCellA [2].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [2].X , CornerMap.HeadingCellD [2].Y  );

      end
      else if (aRnd >= COR_A1_MIN) and (aRnd <= COR_A1_MAX) then begin  //  palla a headingA [1]
        Ball.Cells :=  Point (CornerMap.HeadingCellA [1].X , CornerMap.HeadingCellA [1].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [1].X , CornerMap.HeadingCellA [1].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [1].X , CornerMap.HeadingCellD [1].Y  );

      end
      else if (aRnd >= COR_A0_MIN) and (aRnd <= MAX_LEVEL) then begin  //  palla a headingA [0]
        Ball.Cells :=  Point (CornerMap.HeadingCellA [0].X , CornerMap.HeadingCellA [0].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [0].X , CornerMap.HeadingCellA [0].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [0].X , CornerMap.HeadingCellD [0].Y  );
      end;

  // esistono per forza 3 coa e 3 cod, per il momento swappo solo dove cade la palla.
  // ooa= 3 player corner attaccanti  ood= 3 player corner difensori

            aHeadingFriend.Stamina := aHeadingFriend.Stamina - cost_hea ;                // ogni mossa costa stamina
            aheadingFriend.xpDevA := aheadingFriend.xpDevA + 1;
            //aHeadingFriend.xp_Heading := aHeadingFriend.xp_Heading + 1;
            aHeadingFriend.xpTal[TALENT_ID_HEADING] :=  aHeadingFriend.xpTal[TALENT_ID_HEADING] + 1;

            aHeadingOpponent.Stamina := aHeadingOpponent.Stamina - cost_hea;             // ogni mossa costa stamina
            aHeadingOpponent.xpDevA := aHeadingOpponent.xpDevA + 1;
            aHeadingOpponent.xp_Heading := aHeadingOpponent.xp_Heading + 1;
            aHeadingOpponent.xpTal[TALENT_ID_HEADING] :=  aHeadingOpponent.xpTal[TALENT_ID_HEADING] + 1;

            TsScript[incMove].add ('sc_ST,' + aHeadingFriend.ids +',' + IntToStr(cost_hea) ) ;    // info per il client
            TsScript[incMove].add ('sc_ST,' + aHeadingOpponent.ids +',' + IntToStr(cost_hea) ) ;  // info per il client

            // prima provano i difensori di testa , se falliscono rimane il portiere.
              aHeadingFriend.tmp := aHeadingFriend.tmp +1;
              ACT := '0';
              if ( aHeadingFriend.TalentId1 = TALENT_ID_HEADING ) or ( aHeadingFriend.TalentId2 = TALENT_ID_HEADING ) then begin
                if RndGenerate(100) <= 5 then begin
                  aHeadingFriend.tmp := aHeadingFriend.tmp +1;
                  ACT := IntTostr(TALENT_ID_HEADING);
                end;
              end;

             preRoll3 := RndGenerate (aHeadingFriend.Heading);
             Roll3 := AdjustFatigue(aHeadingFriend.Stamina,preRoll3);
             aRnd3:=  Roll3.value;
             aHeadingFriend.xp_Heading :=  aHeadingFriend.xp_Heading + 1;// + aHeadingFriend.tmp;

             if debug_SetAlwaysGol then arnd3 := 20;

             TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aHeadingFriend.cellx) + ',' + Inttostr(aHeadingFriend.cellY) +','+  IntTostr(aRnd3) +','+
             IntToStr(aHeadingFriend.Heading)  + ',Heading,'+aHeadingFriend.ids+','+IntTostr(Roll3.value)+','+roll3.fatigue+'.'+ACT+ ',0');


              aHeadingOpponent.tmp := 0;
              ACT := '0';
              if ( aHeadingOpponent.TalentId1 = TALENT_ID_HEADING ) or ( aHeadingOpponent.TalentId2 = TALENT_ID_HEADING ) then begin
                if RndGenerate(100) <= 5 then begin
                  aHeadingOpponent.tmp := aHeadingOpponent.tmp +1;
                  ACT := IntTostr(TALENT_ID_HEADING);
                end;
              end;

             preRoll2 := RndGenerate (aHeadingOpponent.Heading);
             Roll2 := AdjustFatigue(aHeadingOpponent.Stamina,preRoll2);
             aRnd2:=  BonusDefenseHeading + Roll2.value + aHeadingOpponent.tmp ;


             TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aHeadingOpponent.cellx) + ',' + Inttostr(aHeadingOpponent.cellY) +','+  IntTostr(aRnd2) +',' +
             IntToStr(aHeadingOpponent.Heading)  + ',Heading,'+aHeadingOpponent.ids+','+IntTostr(Roll2.value)+','+roll2.fatigue+'.'+ACT+','+IntToStr(BonusDefenseHeading));

//             TsScript[incMove].add ('sc_player.move.coacod,' + aHeadingOpponent.ids{sfidante} +',' + aHeadingFriend.ids + ',' + IntTostr(ball.cellx)+',' + IntTostr(ball.celly));
//             goto cor_crossbar;

                if aRnd2 > Arnd3 then begin   //  se heading difensivo vince
                  tsSpeaker.Add(aHeadingOpponent.Surname +' respinge di testa' );

                   if (Ball.CellX = 2) or (ball.CellX = 9) then begin
                     aHeadingOpponent.xpDevT := aHeadingOpponent.xpDevT + 2; // premio massimo
                     OldCell := aHeadingOpponent.Cells ;
                     SwapPlayers ( aHeadingOpponent, aHeadingFriend);
                    //bounce
                     Ball.Cells:= GetBounceCell  ( aPlayer.CellX,aPlayer.CellY, aHeadingOpponent.CellX, aHeadingOpponent.CellY, 2 , aHeadingOpponent.team);
                     TsScript[incMove].add ('sc_corner.headingdef.swap.bounce,' + aPlayer.Ids +',' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) {celle}
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));

                   end
                   else begin
                     aHeadingOpponent.xpDevT := aHeadingOpponent.xpDevT + 1; // premio normale
                     Ball.Cells:= GetBounceCell  ( aPlayer.CellX,aPlayer.CellY, aHeadingOpponent.CellX, aHeadingOpponent.CellY, 2 , aHeadingOpponent.team);
                     TsScript[incMove].add ('sc_corner.headingdef.bounce,'  + aPlayer.Ids +',' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));
                   End;
                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                      Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                    end;
                  TeamMovesLeft := 1;
  //                AI_moveAll (aPlayer);
  //                if TeamMovesLeft <= 0 then TurnChange  (TurnMoves);
                  TsScript[incMove].add ('E');
                  exit;
                end;




// se si arriva qui heading offensivo corner vince

         if (Ball.CellX = 1) or (ball.CellX = 10) then begin
           OldCell := aHeadingFriend.Cells ;
           SwapPlayers ( aHeadingFriend,aHeadingOpponent );
                       TsScript[incMove].add ('sc_corner.headingatt.swap,' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly)
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly));

         end;


              // HEADING vs GK  ---> corner, gol, respinta
              tsSpeaker.Add(aHeadingFriend.Surname +' colpisce di testa ');
              aGK := GetOpponentGK ( aHeadingFriend.Team );
              preRoll4 :=  RndGenerate (aGK.Defense);
              Roll4 := AdjustFatigue(aGK.Stamina,preRoll4);
              aRnd4 := Roll4.value +  BonusDefenseHeading ;
              aGK.xpTal[TALENT_ID_GoalKeeper] := aGK.xpTal[TALENT_ID_GoalKeeper] + 1;
              aGK.Stamina := aGK.Stamina - cost_GKheading;
              GKxpr:= RndGenerate(100);
              if GKxpr <= GKXP_REDUCTION then begin
              aGK.xp_Defense:= aGK.xp_Defense+1;
              aGK.xpDevA := aGK.xpDevA + 1;
              end;
             // aRnd4:= 10;

                 TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aGK.CellX) + ',' + Inttostr(aGK.CellY) +','+  IntTostr(aRnd4) +','+
                 IntTostr(aGK.Defense) +',Defense,'+ aGK.ids+','+IntTostr(Roll4.value)+','+roll4.fatigue+'.0'+','+IntToStr(BonusDefenseHeading));

              // o angolo o respinta o gol
              if aRnd4 > aRnd3 then begin // heading ---> il portiere para e c'è il rimbalzo
                // la palla, che ora è in possesso del portiere , rimbalza e finisce in posizione random che calcolo adesso
              if GKxpr <= GKXP_REDUCTION then begin
                 aGK.xpDevT := aGK.xpDevT + 1;
              end;
                 aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2),true );

                 Ball.Cells := aCell;
                // Ball.CellS := Point(0,1);
                 tsSpeaker.Add(aGK.Surname +' para e respinge');
                 TsScript[incMove].add ('sc_corner.bounce.gk,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y) +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) );
                 if Ball.BallisOutside then begin  // corner

                  CornerSetup ( aPlayer );
                  exit;
                 end;
                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                      Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                    end;
                   TsScript[incMove].add ('E'); // semplice bounce GK
              end

              else begin // corner finisce in gol
// GOL

                  // ma c'è sempre il palo.
                  aheadingFriend.xpDevT := aheadingFriend.xpDevT + 1;
                  if RndGenerate(12) = 12 then begin
cor_crossbar:
//aGK := GetOpponentGK ( aHeadingFriend.Team );
                   CrossBarN := RndGenerate0(2);
                   aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2),false );
                  // se il portiere è fuori dai pali, la palla può rimbalzare in gol più sotto perchè il GK usa defense
                   Ball.Cells := aCell;
                   tsSpeaker.Add(' palo ');
                                  {$IFDEF ADDITIONAL_MATCHINFO}
                                      if GameMode = pvp then
                                        MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aHeadingFriend.ids)
                                        else MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aHeadingFriend.ids);
                                   {$ENDIF}

                   TsScript[incMove].add ('sc_corner.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y) +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(CrossBarN) );

                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                    end;
                   TeamMovesLeft := 1;
                   TsScript[incMove].add ('E'); // semplice bounce GK o palo
                   Exit;
                  end;
                   TsScript[incMove].add ('sc_corner.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)+','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(aGK.cellX)+',' + IntTostr(aGK.cellY) + ',' +IntTostr(RndGenerate(2)) );
                  inc (Score.gol[aPlayer.team]);
                  Score.lstGol:= Score.lstGol + IntTostr(Minute) + '=' + aHeadingFriend.Ids + ',';

                    if GameMode = pvp then

                      MatchInfo.Add( IntToStr(fminute) + '.golcorner.' + aHeadingFriend.ids)
                      else MatchInfo.Add( IntToStr(fminute) + '.golcorner.' + aHeadingFriend.ids +'.'+aHeadingFriend.SurName);

                  TeamMovesLeft := 1;
                  LoadDefaultTeamPos ( aGK.Team ) ;
                  TurnChange(TurnMovesStart);
                  TsScript[incMove].add ('E') ;

              end;


end;
procedure TBrain.exec_freekick2 ;
var
  aRnd  , aRnd2, preRoll, preRoll2, preroll3, arnd3, preroll4, arnd4,GKxpr: integer;
  Roll, Roll2, roll3, roll4: TRoll;
  aPlayer, aheadingFriend, aHeadingOpponent, aGK : TPlayer;
  CornerMap: TCornerMap;
  aCell:Tpoint;
  oldCell: Tpoint;
  CrossBarN,BonusDefenseHeading : integer;
  label cor_crossbar;
begin
  // uguale al corner. esce come cro in tsscript
  // il bonusdefense dipende dalla posizione del cross non è fisso come in corner
  w_FreeKickSetup2:= false;
  CornerMap := GetCorner ( TeamTurn , Ball.CellY, OpponentCorner );
  TeamFreeKick := -1;
  aPlayer := GetFK2 ;
  aPlayer.isFK2 := false;
  tsSpeaker.Add( aPlayer.Surname +' batte la punizione cross '   );
  // esc e come server_cro non cro2
  TsScript[incMove].add ('SERVER_CRO,' + aplayer.ids + ','+ IntTostr(aPlayer.CellX) +',' + inttostr(aPlayer.CellY) + ',' +
                                                IntTostr(CornerMap.HeadingCellA [0].X) + ',' + IntTostr(CornerMap.HeadingCellA [0].Y)) ;
  aPlayer.Stamina := aPlayer.Stamina - cost_cor;
  aPlayer.xpDevA := aPlayer.xpDevA + 1;
  TsScript[incMove].add ('ST,' + aPlayer.ids +',' + IntToStr(cost_cor) ) ;   // costa come il corner

  preRoll := RndGenerate (aPlayer.Passing );
  Roll := AdjustFatigue(aPlayer.Stamina,preRoll);
  aPlayer.tmp :=0;
  if (aPlayer.TalentId1 = TALENT_ID_CROSSING) or (aPlayer.TalentId2 = TALENT_ID_CROSSING) then
    aPlayer.tmp := 1;

  aRnd:= aPlayer.tmp  + Roll.value;
  {$ifdef SetCornergol}aRnd := 10;{$endif}

  //DefenseHeadingWin:= false;
  BonusDefenseHeading := GetCrossDefenseBonus (aPlayer, CornerMap.HeadingCellA [0].X, CornerMap.HeadingCellA [0].Y );
  // se la batto bene 10 il bonusdefense va a -2, quindi può esssere 2, -2 , -3
  // se la batto bene 8 o 9 il bonusdefense va a -1, quindi può esssere 3, -1 , -2
  // se la batto male il bonus +4, 0, -1 rimane invariato
  // in tutti i casi varia comuqnue la cella e quindi i player che si condfrontano
        TsScript[incMove].add ( 'sc_DICE,' + IntTostr(CornerMap.CornerCell.X) + ',' + Inttostr(CornerMap.CornerCell.Y) +','+  IntTostr(aRnd) +',' +
        IntToStr(aPlayer.Passing) +',Crossing,'+ aPlayer.ids+','+IntTostr(Roll.value)+','+Roll.fatigue+ '.0'+','+IntToStr(aPlayer.tmp));


      if (aRnd >= CRO2_D2_MIN) and (aRnd <= CRO2_D2_MAX) then begin  //  palla a headingD [2]
        Ball.Cells :=  Point (CornerMap.HeadingCellD [2].X , CornerMap.HeadingCellD [2].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [2].X , CornerMap.HeadingCellA [2].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [2].X , CornerMap.HeadingCellD [2].Y  );
//        BonusDefenseHeading := BonusDefenseHeading ;
      end
      else if (aRnd >= CRO2_D1_MIN) and (aRnd <= CRO2_D1_MAX) then begin  //  palla a headingD [1]
        Ball.Cells :=  Point (CornerMap.HeadingCellD [1].X , CornerMap.HeadingCellD [1].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [1].X , CornerMap.HeadingCellA [1].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [1].X , CornerMap.HeadingCellD [1].Y  );
      //  BonusDefenseHeading := 1;

      end
      else if (aRnd >= CRO2_D0_MIN) and (aRnd <= CRO2_D0_MAX) then begin  //  palla a headingD [0]
        Ball.Cells :=  Point (CornerMap.HeadingCellD [0].X , CornerMap.HeadingCellD [0].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [0].X , CornerMap.HeadingCellA [0].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [0].X , CornerMap.HeadingCellD [0].Y  );
      //  BonusDefenseHeading := 1;

      end
      else if (aRnd >= CRO2_A2_MIN) and (aRnd <= CRO2_A2_MAX) then begin  //  palla a headingA [2]
        aPlayer.xpDevT := aPlayer.xpDevT + 1; // premio normale

        Ball.Cells :=  Point (CornerMap.HeadingCellA [2].X , CornerMap.HeadingCellA [2].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [2].X , CornerMap.HeadingCellA [2].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [2].X , CornerMap.HeadingCellD [2].Y  );
        BonusDefenseHeading := BonusDefenseHeading -1;   //3 o anche -2 o -1
      end
      else if (aRnd >= CRO2_A1_MIN) and (aRnd <= CRO2_A1_MAX) then begin  //  palla a headingA [1]
        aPlayer.xpDevT := aPlayer.xpDevT + 1; // premio normale

        Ball.Cells :=  Point (CornerMap.HeadingCellA [1].X , CornerMap.HeadingCellA [1].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [1].X , CornerMap.HeadingCellA [1].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [1].X , CornerMap.HeadingCellD [1].Y  );
        BonusDefenseHeading := BonusDefenseHeading -1;  //3  -2 -1

      end
      else if (aRnd >= CRO2_A0_MIN) and (aRnd <= MAX_LEVEL) then begin  //  palla a headingA [0]
        aPlayer.xpDevT := aPlayer.xpDevT + 2; // premio massimo

        Ball.Cells :=  Point (CornerMap.HeadingCellA [0].X , CornerMap.HeadingCellA [0].Y);
        aHeadingFriend := GeTPlayer ( CornerMap.HeadingCellA [0].X , CornerMap.HeadingCellA [0].Y  );
        aHeadingOpponent := GeTPlayer ( CornerMap.HeadingCellD [0].X , CornerMap.HeadingCellD [0].Y  );
        BonusDefenseHeading := BonusDefenseHeading -2; //3 -2 -1
      end;

  // esistono per forza 3 coa e 3 cod, per il momento swappo solo dove cade la palla.

            aHeadingFriend.Stamina := aHeadingFriend.Stamina - cost_hea ;
            aHeadingFriend.xpDevA := aHeadingFriend.xpDevA + 1;
            TsScript[incMove].add ('sc_ST,' + aHeadingFriend.ids +',' + IntToStr(cost_hea) ) ;
            aHeadingOpponent.Stamina := aHeadingOpponent.Stamina - cost_hea;
            aHeadingOpponent.xpDevA := aHeadingOpponent.xpDevA + 1;
            TsScript[incMove].add ('sc_ST,' + aHeadingOpponent.ids +',' + IntToStr(cost_hea) ) ;

            // prima i difensori di testa , se falliscono rimane il portiere.

             preRoll3 := RndGenerate (aHeadingFriend.Heading);
             Roll3 := AdjustFatigue(aHeadingFriend.Stamina,preRoll3);
             aRnd3:=  Roll3.value;
             aHeadingFriend.xp_Heading :=  aHeadingFriend.xp_Heading + 1;
            {$ifdef SetCornergol}aRnd3 := 10;{$endif}

             preRoll2 := RndGenerate (aHeadingOpponent.Heading);
             Roll2 := AdjustFatigue(aHeadingOpponent.Stamina,preRoll2);
             aRnd2:=  BonusDefenseHeading + Roll2.value;
             aHeadingOpponent.xp_Heading :=  aHeadingOpponent.xp_Heading + 1;
             TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aHeadingOpponent.cellx) + ',' + Inttostr(aHeadingOpponent.cellY) +','+  IntTostr(aRnd2) +',' +
             IntToStr(aHeadingOpponent.Heading)  + ',Heading,'+aHeadingOpponent.ids+','+IntTostr(Roll2.value)+','+Roll2.fatigue+'.0'+','+Inttostr(BonusDefenseHeading));
             TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aHeadingFriend.cellx) + ',' + Inttostr(aHeadingFriend.cellY) +','+  IntTostr(aRnd3) +','+
             IntToStr(aHeadingFriend.Heading)  + ',Heading,'+aHeadingFriend.ids+','+IntTostr(Roll3.value)+','+roll3.fatigue+'.0'+',0');

//             TsScript[incMove].add ('sc_player.move.coacod,' + aHeadingOpponent.ids{sfidante} +',' + aHeadingFriend.ids + ',' + IntTostr(ball.cellx)+',' + IntTostr(ball.celly));
//             goto cor_crossbar;

                if aRnd2 > Arnd3 then begin   //  heading difensivo vince
                  tsSpeaker.Add(aHeadingOpponent.Surname +' respinge di testa' );

                   if (Ball.CellX = 2) or (ball.CellX = 9) then begin
                     aHeadingOpponent.xpDevT := aHeadingOpponent.xpDevT + 2; // premio massimo
                     OldCell := aHeadingOpponent.Cells ;
                     SwapPlayers ( aHeadingOpponent, aHeadingFriend);
                    //bounce
                     Ball.Cells:= GetBounceCell  ( aPlayer.CellX,aPlayer.CellY, aHeadingOpponent.CellX, aHeadingOpponent.CellY, 2 , aHeadingOpponent.team);
                     TsScript[incMove].add ('sc_cro2.headingdef.swap.bounce,' + aPlayer.Ids +',' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) {celle}
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));

                   end
                   else begin
                     aHeadingOpponent.xpDevT := aHeadingOpponent.xpDevT + 1; // premio normale
                     Ball.Cells:= GetBounceCell  ( aPlayer.CellX,aPlayer.CellY, aHeadingOpponent.CellX, aHeadingOpponent.CellY, 2 , aHeadingOpponent.team);
                     TsScript[incMove].add ('sc_cro2.headingdef.bounce,'  + aPlayer.Ids +',' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)
                                                               + ',' + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) {celle}
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly)
                                                               + ',' + IntTostr(Ball.cellx)+',' + IntTostr(Ball.celly));
                   End;
                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                      Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                    end;
                  TeamMovesLeft := 1;
  //                AI_moveAll (aPlayer);
  //                if TeamMovesLeft <= 0 then TurnChange  (TurnMoves);
                  TsScript[incMove].add ('E');
                  exit;
                end;




// se si arriva qui heading offensivo corner vince

         if (Ball.CellX = 1) or (ball.CellX = 10) then begin
           OldCell := aHeadingFriend.Cells ;
           SwapPlayers ( aHeadingFriend,aHeadingOpponent );
                       TsScript[incMove].add ('sc_cro2.headingatt.swap,' + aHeadingFriend.ids + ',' + aHeadingOpponent.ids
                                                               + ',' + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly)
                                                               + ',' + IntTostr(aHeadingOpponent.cellx)+',' + IntTostr(aHeadingOpponent.celly));

         end;


              // HEADING vs GK  ---> corner, gol, respinta
              tsSpeaker.Add(aHeadingFriend.Surname +' colpisce di testa ');
              aGK := GetOpponentGK ( aHeadingFriend.Team );
              preRoll4 :=  RndGenerate (aGK.Defense);
              Roll4 := AdjustFatigue(aGK.Stamina,preRoll4);
              aRnd4 := Roll4.value +  BonusDefenseHeading ;
              aGK.xpTal[TALENT_ID_GoalKeeper] := aGK.xpTal[TALENT_ID_GoalKeeper] + 1;
              aGK.Stamina := aGK.Stamina - cost_GKheading;
              GKxpr:= RndGenerate(100);
              if GKxpr <= GKXP_REDUCTION then begin
              aGK.xp_Defense:= aGK.xp_Defense+1;
              aGK.xpDevA := aGK.xpDevA + 1;
              end;
             // aRnd4:= 10;

                 TsScript[incMove].add ( 'sc_DICE,' + IntTostr(aGK.CellX) + ',' + Inttostr(aGK.CellY) +','+  IntTostr(aRnd4) +','+
                 IntTostr(aGK.Defense ) +',Defense,'+ aGK.ids+','+IntTostr(Roll4.value)+','+roll4.fatigue+'.0'+','+inttostr(BonusDefenseHeading));

              // o angolo o respinta o gol
              if aRnd4 > aRnd3 then begin // heading ---> il portiere para e c'è il rimbalzo
                // la palla, che ora è in possesso del portiere , rimbalza e finisce in posizione random che calcolo adesso
              if GKxpr <= GKXP_REDUCTION then begin
                 aGK.xpDevT := aGK.xpDevT + 1;
              end;

                 aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2),true );

                 Ball.Cells := aCell;
                // Ball.CellS := Point(0,1);
                 tsSpeaker.Add(aGK.Surname +' para e respinge');
                 TsScript[incMove].add ('sc_cro2.bounce.gk,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y) +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(RndGenerate(2)) );
                 if Ball.BallisOutside then begin  // corner

                  CornerSetup ( aPlayer );
                  exit;
                 end;
                    // se chi riceve il rimbalzo è dello stesso Team
                  if Ball.Player <> nil then begin
                    if Ball.Player.Team = aPlayer.Team then begin
                      Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                    end;
                    Ball.Player.Shot := Ball.Player.Shot + 1;
                    Ball.Player.BonusFinishingTurn := 1;
                    Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                  end;
                   TsScript[incMove].add ('E'); // semplice bounce GK
              end

              else begin // cro2 finisce in gol
// GOL
                  aheadingFriend.xpDevT := aheadingFriend.xpDevT + 1;
                  // ma c'è sempre il palo.
                  if RndGenerate(12) = 12 then begin
cor_crossbar:

                   CrossBarN := RndGenerate0(2);
                   aCell := GetGKBounceCell (aGK,  aGK.cellX, aGK.CellY,  RndGenerate (2),false );
                  // se il portiere è fuori dai pali, la palla può rimbalzare in gol più sotto perchè il GK usa defense
                   Ball.Cells := aCell;
                   tsSpeaker.Add(' palo ');

                    {$IFDEF ADDITIONAL_MATCHINFO}
                    if GameMode = pvp then
                      MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aHeadingFriend.ids)
                      else MatchInfo.Add( IntToStr(fminute) + '.crossbar.' + aHeadingFriend.ids);
                    {$ENDIF}

                   TsScript[incMove].add ('sc_cro2.bounce.crossbar,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y) +','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(Ball.cellX)+',' + IntTostr(Ball.cellY) + ',' +IntTostr(CrossBarN) );

                    // se chi riceve il rimbalzo è dello stesso Team
                    if Ball.Player <> nil then begin
                      if Ball.Player.Team = aPlayer.Team then begin
                        Ball.Player.xpTal[TALENT_ID_FINISHING] :=  Ball.Player.xpTal[TALENT_ID_FINISHING] + 1;
                      end;
                      Ball.Player.Shot := Ball.Player.Shot + 1;
                      Ball.Player.BonusFinishingTurn := 1;
                      Ball.Player.xpDevA := Ball.Player.xpDevA + 1;
                    end;
                   TeamMovesLeft := 1;
                   TsScript[incMove].add ('E'); // semplice bounce GK o palo
                   Exit;
                  end;
                   TsScript[incMove].add ('sc_cro2.gol,' + aPlayer.ids + ','+ aHeadingFriend.ids + ',' + aGK.ids +','
                                              + IntTostr(CornerMap.CornerCell.X)+','+ IntTostr(CornerMap.CornerCell.Y)+','
                                              + IntTostr(aPlayer.cellx)+',' + IntTostr(aPlayer.celly) + ','
                                              + IntTostr(aHeadingFriend.cellx)+',' + IntTostr(aHeadingFriend.celly) + ','
                                              + IntTostr(aGK.cellx)+',' + IntTostr(aGK.celly)  +','
                                              + IntTostr(aGK.cellX)+',' + IntTostr(aGK.cellY) + ',' +IntTostr(RndGenerate(2)) );
                  inc (Score.gol[aPlayer.team]);
                  Score.lstGol:= Score.lstGol + IntTostr(Minute) + '=' + aHeadingFriend.Ids + ',';
                    if GameMode = pvp then
                      MatchInfo.Add( IntToStr(fminute) + '.golcro2.' + aHeadingFriend.ids)
                      else MatchInfo.Add( IntToStr(fminute) + '.golcro2.' + aHeadingFriend.ids + '.' + aHeadingFriend.SurName);

                  TeamMovesLeft := 1;
                  LoadDefaultTeamPos ( aGK.Team ) ;
                  TurnChange(TurnMovesStart);
                  TsScript[incMove].add ('E') ;

              end;


end;


function TBrain.MirrorAIfield ( CellX,CellY: integer) : TPoint;
begin
  case CellY of
    0:Result.Y := 11;
    1:Result.Y := 10;
    2:Result.Y := 9;
    3:Result.Y := 8;
    4:Result.Y := 7;
    5:Result.Y := 6;
    6:Result.Y := 5;
    7:Result.Y := 4;
    8:Result.Y := 3;
    9:Result.Y := 2;
    10:Result.Y := 1;
    11:Result.Y := 0;
  end;
  case CellX of
    0:Result.X := 6;
    1:Result.X := 5;
    2:Result.X := 4;
    3:Result.X := 3;
    4:Result.X := 2;
    5:Result.X := 1;
    6:Result.X := 0;
  end;

end;

function TBrain.inExceptPlayers ( aPlayer: TPlayer ) : Boolean;
var
  i: integer;
begin
  for i := 0 to ExceptPlayers.Count -1 do begin
    if ExceptPlayers[i].Ids = aPlayer.ids then begin
      Result:= True;
      Exit;
    end;
  end;

  result := False;
end;

procedure TBrain.AI_MovePlayer_DefaultX ( aPlayer: TPlayer  ) ;
begin
  aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
  GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, aPlayer.DefaultCellX , aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
end;
procedure TBrain.AI_MovePlayer_DefaultY ( aPlayer: TPlayer  ) ;
begin
  aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
  GetPathY ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, aPlayer.CellX , aPlayer.DefaultCellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
end;
procedure TBrain.AI_MovePlayer_DefaultX_plus_1 ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin
  if aPlayer.Team = 0 then begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
    DstX :=  aPlayer.DefaultCellX +1;// Ball.CellX +1;
    if DstX > 10 then DstX:=10;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end
  else begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
    DstX :=  aPlayer.DefaultCellX -1;// Ball.CellX -1;
    if DstX < 1 then DstX:=1;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end;
end;
procedure TBrain.AI_MovePlayer_DefaultX_plus_2 ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin
  if aPlayer.Team = 0 then begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
    DstX :=  aPlayer.DefaultCellX +2;// Ball.CellX +2;
    if DstX > 10 then DstX:=10;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end
  else begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
    DstX :=  aPlayer.DefaultCellX -2;// Ball.CellX -2;
    if DstX < 1 then DstX:=1;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end;
end;
procedure TBrain.AI_MovePlayer_DefaultX_minus_1 ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin
  if aPlayer.Team = 0 then begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
    DstX :=  aPlayer.DefaultCellX -1;// Ball.CellX -1;
    if DstX < 1 then DstX:=1;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end
  else begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
    DstX :=  aPlayer.DefaultCellX +1;// Ball.CellX +1;
    if DstX > 10 then DstX:=10;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end;
end;
procedure TBrain.AI_MovePlayer_DefaultX_minus_2 ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin
  if aPlayer.Team = 0 then begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
    DstX :=  aPlayer.DefaultCellX -2;// Ball.CellX -2;
    if DstX < 1 then DstX:=1;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end
  else begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;
    DstX :=  aPlayer.DefaultCellX +2;// Ball.CellX +2;
    if DstX > 10 then DstX:=10;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end;
end;
procedure TBrain.AI_MovePlayer_Ball_equal ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3

    DstX := Ball.CellX ;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );

end;
procedure TBrain.AI_MovePlayer_Ball_plus_1 ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin

  if aPlayer.Team = 0 then begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3
    DstX := Ball.CellX +1;
    if DstX > 10 then DstX:=10;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end
  else begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3
    DstX := Ball.CellX -1;
    if DstX < 1 then DstX:=1;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end;

end;
procedure TBrain.AI_MovePlayer_Ball_plus_2 ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin

  if aPlayer.Team = 0 then begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3
    DstX := Ball.CellX +2;
    if DstX > 10 then DstX:=10;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end
  else begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3
    DstX := Ball.CellX -2;
    if DstX < 1 then DstX:=1;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end;

end;
procedure TBrain.AI_MovePlayer_Ball_minus_1 ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin

  if aPlayer.Team = 0 then begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3
    DstX := Ball.CellX -1;
    if DstX < 1 then DstX:=1;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end
  else begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3
    DstX := Ball.CellX +1;
    if DstX > 10 then DstX:=10;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end;

end;
procedure TBrain.AI_MovePlayer_Ball_minus_2 ( aPlayer: TPlayer  ) ;
var
  DstX: integer;
begin

  if aPlayer.Team = 0 then begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3
    DstX := Ball.CellX -2;
    if DstX < 1 then DstX:=1;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end
  else begin
    aPlayer.MoveValue := AdjustFatigue(aPlayer.Stamina , aPlayer.Speed).value;// tips utile per 2 tipo di chiamata -1 -2 -3
    DstX := Ball.CellX +2;
    if DstX > 10 then DstX:=10;
    GetPathX ( aPlayer.Team, aPlayer.CellX , aPlayer.CellY, DstX, aPlayer.CellY,
    aPlayer.MoveValue , false,false,false,true,true, aPlayer.MovePath );
  end;

end;

procedure TBrain.AI_MoveAll ; // movimento automatico dei player a fine turno
var
  p,x,y,i,Modifier_MoveAll: integer;
  aPlayer : TPlayer;
  aCell,dstCell: TPoint;
  Toball: Boolean;
  DstX: integer;
  aList: TObjectList<TPlayer>;
//  aList: TList<TPlayer>;
  preRoll, aRnd: integer;
  Roll:TRoll;
  MaxSpeed: integer;
  OriginalPath : dse_pathplanner.TPath;
  label dopo;
  label DoOriginalPath0, DoOriginalPath1;

begin

  TsScript[incMove].add ('sc_ai.movetoball');
  for P := Players.Count -1 downto 0 do begin
    aPlayer := Players[p];
    aPlayer.MovePath.Clear ;
  end;
  if GetTeamBall = -1 then begin

  // a distanza 1 un giocatore random prende la palla
    aList:= TObjectList<TPlayer>.create(false);
    for P := Players.Count -1 downto 0 do begin
      aPlayer := Players[p];
      if  inExceptPlayers ( aPlayer ) then  continue;
      if (not aPlayer.CanMove) or (aPlayer.Role='G') then continue;
      if (absdistance (ball.CellX, ball.celly, aPlayer.CellX , aPlayer.CellY) = 1) then
        aList.add (aPlayer);
    end;

    if aList.Count > 0 then begin

      // genero un aRnd
      for I := 0 to aList.Count -1 do begin
        preRoll := RndGenerate (aList[i].Speed);
        Roll := AdjustFatigue (aList[i].Stamina , preRoll);
        aRnd := Roll.value ;
        aList[i].itag := aRnd;
        TsScript[incMove].add ( 'sc_mtbDICE,' + IntTostr(aList[i].CellX) + ',' + Inttostr(aList[i].CellY) +','+  IntTostr(aRnd) +','+
        IntTostr(aList[i].Speed)+',Speed,'+ aList[i].ids+','+IntTostr(Roll.value)+','+ Roll.fatigue+'.0' );
      end;

      // prendo i roll più alti
      aList.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := R.iTag - L.iTag;
      end
     ));
      MaxSpeed := aList[0].iTag ;   // max rnd

      for P := aList.Count -1 downto 0 do begin
        if aList[p].iTag < MaxSpeed then          // max rnd
          aList.Delete(p);
      end;

      // se sono uguali è veramente random
      aRnd := RndGenerate0 (aList.Count -1);
      aPlayer := aList[aRnd];

      // cerco questo player nella lista originale
      TsScript[incMove].add ('sc_player.move,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                      IntTostr(ball.cellX   )+','+ IntTostr( Ball.cellY)  ) ;
      if shpBuff then begin
       aPlayer.BonusSHPTurn := 1;
       aPlayer.BallControl := aPlayer.DefaultBallControl + 2 ;
       aPlayer.Passing  := aPlayer.DefaultPassing + 2 ;
       aPlayer.tmp:=0;
       if (aPlayer.TalentId1 = TALENT_ID_BOMB) or (aPlayer.TalentId2 = TALENT_ID_BOMB) then
         aPlayer.tmp := 1;

       aPlayer.Shot   := aPlayer.Defaultshot + 2 + aPlayer.tmp ;
      end;
      //ExceptPlayers.Add(aPlayer); //<--- chi riceve un shp e lo raggiunge con movetoball non può rimanere senza canskill
    //  aPlayer.grouped := true;
      aPlayer.CellS :=  ball.cells;

    end;

    aList.Free;
  end;

  shpBuff:= False;
    for P := Players.Count -1 downto 0 do begin
      aPlayer := Players[p];
      aPlayer.MovePath.Clear ;
    end;

  // Pulisco comunque tutti i player.movepath . Chi non chiama i gepathplanner.TPath ha path vuoto e passa ai talenti comunque.
  OriginalPath := dse_pathplanner.TPath.Create; // decide tra originalPath e Talent che attivano altri path

  // meglio tenerla divisa, non è vera AI
  TsScript[incMove].add ('sc_ai.endmovetoball');
  TsScript[incMove].add ('sc_ai.moveall');


  case Ball.cellX of
      1..5: begin                           // team 0 defend team 1 attack
        for X := 1 to 10 do begin      //<--
          for Y := 0 to 6 do begin
            aPlayer := GeTPlayer ( X,Y);
            if aPlayer = nil then continue;
            //if (aPlayer.Ids='3634') then asm int 3 end;

            if not aPlayer.CanMove then continue;
            if aPlayer.HasBall then continue;
            if aPlayer.grouped  then Continue;

            if  inExceptPlayers ( aPlayer ) then  continue;
            if aPlayer.stay then Continue; // mtb moveto ball sopra lo fa ovviamente a distanza 1 cerca di raggiungere la palla


            // qui sotto: M=mio N=neutro L=loro   in base alla situazione i player si muovono
           // off= un player con talento offensivo ha un movimento automatico diverso
           // dif= un player con talento difensivo ha un movimento automatico diverso
           // nor= un player normale
           // dopo lo spostamento automatico altri talenti vengono valutati e il player si muove ulteriormente
            Toball := False;
                case TeamTurn of
                  0: begin
                              case aPlayer.Team of
                                0: begin

                                        case GetTeamBall of  // di quale team è la palla
                                          -1: begin  // palla neutra
                                            if aPlayer.Role ='D' then begin       // metacampo 0, teamturn 0, aPlayer.team 0, palla neutra
                                              //M M N
                                              //off	defaultX+1
                                              //nor	…
                                              //dif	defaultX-1

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                              end

                                            end
                                            else if aPlayer.Role ='M' then begin

                                            //off	ball= se palla davanti
                                            //nor	…..
                                            //dif	ball-1
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 if Ball.CellX > aPlayer.cellX then
                                                   AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end;


                                            end
                                            else if aPlayer.Role ='F' then begin
                                              //off	…
                                              //nor	…
                                              //dif	default-1 se oltre default
                                              if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 if aPlayer.CellX > aPlayer.DefaultCellX then begin
                                                 AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                                 end;
                                              end;

                                            end;
                                          end;
                                          0: begin                                // metacampo 0, teamturn 0, aPlayer.team 0, palla team 0
                                            if aPlayer.Role ='D' then begin
//                                              M M M
                                              //off	defaultX+1
                                              //nor	defaultX
                                              //dif	defaultX

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end
                                              // cerco la posizione default se la palla è davanti
                                              else begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end;
                                            end
                                            else if aPlayer.Role ='M' then begin

                                                //off	p+2palla
                                                //nor	p+1palla
                                                //dif	p=palla

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_Ball_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;

                                            end
                                            else if aPlayer.Role ='F' then begin

                                             // off	default se prima di default
                                             // nor	default
                                             // dif	default se oltre default

                                               if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 if aPlayer.CellX < aPlayer.DefaultCellX then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                 end;
                                               end
                                               else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                               end
                                               else begin
                                                 if aPlayer.CellX > aPlayer.DefaultCellX then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                 end;

                                               end;


                                            end;

                                          end;

                                          1: begin
                                            if aPlayer.Role ='D' then begin     // metacampo 0, teamturn 0, aPlayer.team 0, palla team 1
//                                                M M L
                                                  //off	defaultX
                                                  //nor	p-1  se palla <= o defaultX
                                                  //dif	defaultX-1

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   if Ball.CellX > aPlayer.cellX then
                                                     AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                     AI_MovePlayer_DefaultX_minus_1 ( aPlayer ) ;
                                              end
                                              // cerco la posizione default se la palla è davanti
                                              else begin
                                                     if Ball.cellX <= aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1( aPlayer )
                                                       else AI_MovePlayer_DefaultX ( aPlayer ) ;

                                              end;
                                            end
                                            else if aPlayer.Role ='M' then begin

                                              //off	p=palla se palla davanti
                                              //nor	…..
                                              //dif	p-1 palla

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   if Ball.CellX > aPlayer.cellX then
                                                     AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end;

                                            end
                                            else if aPlayer.Role ='F' then begin
                                              //  off	default se oltre default
                                              //  nor	default
                                              //  dif	default-1
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 if aPlayer.CellX > aPlayer.DefaultCellX then begin
                                                   AI_MovePlayer_DefaultX( aPlayer ) ;
                                                 end;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_minus_1( aPlayer ) ;
                                              end
                                              else begin
                                                   AI_MovePlayer_DefaultX( aPlayer ) ;
                                              end;

                                            end;

                                          end;
                                        end;
                                   end;  // team 0

                                  1: begin
                                    case GetTeamBall of
                                      -1: begin
                                        if aPlayer.Role ='D' then begin        // metacampo 0, teamturn 0, aPlayer.team 1, palla neutra
//                                          L L N
                                            //off	defaultX+1
                                            //nor	…..
                                            //dif	defaultX
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_1 ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX( aPlayer ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                          //off	…..
                                          //nor	…..
                                          //dif	p-1palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                               if aPlayer.CellX >= 9 then
                                                AI_MovePlayer_DefaultX ( aPlayer )
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                              else begin
                                               if aPlayer.CellX >= 9 then
                                                AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;


                                        end
                                        else if aPlayer.Role ='F' then begin
                                            //  off	p=palla
                                            //  nor	…..
                                            //  dif	default se oltre default
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                       AI_MovePlayer_Ball_equal ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end
                                                else begin
                                                if aPlayer.CellX > 5 then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end;
                                        end;

                                      end;
                                      0: begin                                 // metacampo 0, teamturn 0, aPlayer.team 1, palla team 0
                                        if aPlayer.Role ='D' then begin
//                                            L L L
//                                            off	defaultX
//                                            nor	…
//                                            dif	defaultX

                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                       AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end
                                                else begin
                                                if aPlayer.CellX > 5 then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end;

                                        end
                                        else if aPlayer.Role ='M' then begin
                                          //off	…..
                                          //nor	p-1palla se palla dietro
                                          //dif	p-1palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or  (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then Continue;

                                                if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX > aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  )
                                                       else if aPlayer.CellX >= 9 then
                                                       AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end;


                                        end
                                        else if aPlayer.Role ='F' then begin
                                                //    off	default se oltre default
                                                //    nor	…
                                                //    dif	default se oltre default
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                  if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_Ball_equal ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end;

                                        end;

                                      end;
                                      1: begin
                                        if aPlayer.Role ='D' then begin        // metacampo 0, teamturn 0, aPlayer.team 1, palla team 1
//                                          L L M
                                              //off	defaultX+1
                                              //nor	…
                                              //dif	defaultX
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                       AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                            //off	…
                                            //nor	p-1palla se palla dietro
                                            //dif	p-1palla
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                    if aPlayer.CellX >= 9 then
                                                      AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end

                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX > aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  )
                                                      else if aPlayer.CellX >= 9 then
                                                       AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end;

                                        end
                                        else if aPlayer.Role ='F' then begin
                                             // off	p+1palla
                                             // nor	…
                                             // dif	p-1palla
                                                if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX > aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  )
                                                    else if aPlayer.CellX > 5 then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end;
                                        end;

                                      end;
                                    end;
                                  end;
                              end;
                     end;  // teamturn 0

                  1: begin // team 0 defend , teamturn 1  attack
                        case aPlayer.Team of
                          0: begin
                                    case GetTeamBall of
                                      -1: begin                                  // metacampo 0, teamturn 1,  aPlayer.team 0, palla  neutra
                                        if aPlayer.Role ='D' then begin
                                          //M L N
                                          //off	defaultX
                                          //nor	…
                                          //dif	defaultX-1
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                                end;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                          //off	…..
                                          //nor	p-1palla se palla dietro
                                          //dif	p-1palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or  (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then Continue;

                                                if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX < aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                           // off	default
                                           // nor	…
                                           // dif	default-1
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                                end;


                                        end;

                                      end;
                                      0: begin                                   // metacampo 0, teamturn 1,  aPlayer.team 0, palla team team 0
                                        if aPlayer.Role ='D' then begin
                                              //M L M
                                              //off	defaultX+1
                                              //nor	p-2  se palla <= o defaultX
                                              //dif	defaultX-1
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                              end

                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end

                                              // cerco la posizione default se la palla è davanti
                                              else begin
                                                     if Ball.cellX <= aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_2( aPlayer )
                                                       else AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                           // off	….
                                           // nor	p-1palla se palla dietro
                                           // dif	p-1palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or  (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then Continue;

                                                if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX < aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end;

                                        end
                                        else if aPlayer.Role ='F' then begin
                                              //off	default +1
                                              //nor	…
                                              //dif	default -1
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or  (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE)  then begin
                                                   AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                                end;
                                        end;

                                      end;
                                      1: begin                                  // metacampo 0, teamturn 1,  aPlayer.team 0, palla team 1
                                        if aPlayer.Role ='D' then begin
                                            // M L L
                                            //off	defaultX
                                            //nor	defaultX
                                            //dif	defaultX-2

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                AI_MovePlayer_DefaultX_minus_2 ( aPlayer ) ;
                                              end
                                              // -1 palla difendo solo se la palla è alle mie spalle o in linea
                                              else begin
                                                     if Ball.cellX >= aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_2( aPlayer )
                                                       else AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                            //off	p=palla
                                            //nor	p-1palla se palla dietro
                                            //dif	p-2palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_minus_2 ( aPlayer  ) ;
                                              end
                                              else begin
                                                   if Ball.CellX < aPlayer.cellX then
                                                     AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end;

                                        end
                                        else if aPlayer.Role ='F' then begin

                                          //off	default se oltre default
                                          //nor	default se oltre default
                                         // dif	default-2
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                  AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  AI_MovePlayer_DefaultX_minus_2 ( aPlayer ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                  AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;


                                        end;

                                      end;
                                    end;

                          end;
                          1: begin
                                    case GetTeamBall of
                                      -1: begin                                  // metacampo 0, teamturn 1, aPlayer.team 1, palla  neutra
                                        if aPlayer.Role ='D' then begin          // uguale a palla team 1
                                              //L M N
                                              //off	defaultX+1
                                              //nor	…
                                              //dif	defaultX
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end;


                                        end
                                        else if aPlayer.Role ='M' then begin
                                              //off	p+1palla
                                              //nor	….
                                              //dif	p=se palla dietro
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                if Ball.CellX > aPlayer.cellX then
                                                   AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX >= 9 then
                                                  AI_MovePlayer_DefaultX ( aPlayer ) ;

                                              end;

                                        end
                                        else if aPlayer.Role ='F' then begin
                                              //  off	p+1palla
                                              //  nor	…
                                              //  dif	default

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                if Ball.CellX > aPlayer.cellX then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX > 5 then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                        end;

                                      end;
                                      0: begin                                   // metacampo 0, teamturn 1, aPlayer.team 1, palla team 0
                                        if aPlayer.Role ='D' then begin
                                               // L M L
                                              //off	defaultX
                                              //nor	defaultX
                                              //dif	defaultX
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                              //off	p=palla
                                              //nor	….
                                              //dif	p-1palla se palla dietro
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 if Ball.CellX > aPlayer.CellX then
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX >= 9 then
                                                  AI_MovePlayer_DefaultX ( aPlayer ) ;

                                              end;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                          //  off	default
                                          //  nor	…
                                         //   dif	default se oltre default
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 if aPlayer.CellX > aPlayer.defaultcellX then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX > 5 then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                        end;

                                      end;
                                      1: begin                                   // metacampo 0, teamturn 1, aPlayer.team 1, palla team 1
                                        if aPlayer.Role ='D' then begin
                                               // L M M
                                              //off	defaultX+2
                                              //nor	defaultX
                                              //dif	defaultX
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end

                                              // cerco la posizione default  -1 (avanzo) se la palla è davanti
                                              else begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                              //off	p+2palla
                                              //nor	p+1palla
                                              //dif	p=se palla dietro
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else begin
                                                 if aPlayer.CellX > Ball.cellx then
                                                    AI_MovePlayer_Ball_plus_1 ( aPlayer )
                                                  else if aPlayer.CellX < 5 then
                                                     AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                            //off	p+2
                                            //nor	p+1 se dietro palla
                                            //dif	p=palla


                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else begin
                                                 if aPlayer.CellX > Ball.cellx then
                                                    AI_MovePlayer_Ball_plus_1 ( aPlayer )
                                                  else if aPlayer.CellX < 6  then
                                                     AI_MovePlayer_DefaultX ( aPlayer ) ;

                                              end;
                                        end;

                                      end;
                                    end;

                          end;
                        end;
                      end;

                end;


             CopyPath ( aPlayer.MovePath , OriginalPath ); // i path devono esistere
             if (aPlayer.MovePath.Count > 0 ) {and not (aPlayer.grouped )} then begin
//             if (aCell.X <> -1) and not (aPlayer.grouped )then begin
               // se c'è spazio per rientrare
              ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                // controllo la presenza della palla libera sul percorso
                dstCell :=  Point (aPlayer.MovePath[aPlayer.MovePath.Count-1].X,aPlayer.MovePath[aPlayer.MovePath.Count-1].Y) ;
                for I := 0 to aPlayer.MovePath.Count -1 do begin
                  if  ( Ball.CellX = aPlayer.MovePath[i].X ) and ( Ball.CellY = aPlayer.MovePath[i].Y ) and (Ball.Player = nil) then begin
                     dstCell := Point (aPlayer.MovePath[i].X,aPlayer.MovePath[i].Y) ;
                     Toball := True;
                        // bonus al tiro anche per ai:moveALL
                        if (aPlayer.MovePath.Count >= 2) and ( aPlayer.HasBall )  then begin
                         aPlayer.BonusPLMTurn := 1;
                         aPlayer.Shot   := aPlayer.DefaultShot + 2 ;
                         aPlayer.Passing   := aPlayer.DefaultPassing + 2 ;
                        end;
                     break;

                  end;
                end;

             end;

                // se con il semplice aimoveall trovo la palla lo faccia, altrimenti valuto i talenti.
             if toball then

              TsScript[incMove].add ('sc_player.move,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                                         IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  )
             else begin

//                aPlayer.MovePath.Clear ;
//      in ai_moveall prima fa aimoveall poi cerca la cella Y precisa defaultcellY ,  . spende di più a correr . utile per chi deve stare sulle fascie
                if ( (aPlayer.TalentId1 = TALENT_ID_POSITIONING) or (aPlayer.TalentId2 = TALENT_ID_POSITIONING)    )  and ( not toball)  then begin  // o not aPlayer.hasball
                  AI_MovePlayer_DefaultY ( aPlayer ) ;
                  if aPlayer.MovePath.Count > 0 then begin   // se trova il path per marking
                    aPlayer.Stamina := aPlayer.Stamina - cost_plm;
                    TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;

                    dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                    TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                  IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                    aPlayer.CellS :=  dstCell;
                    ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                  end
                  else if OriginalPath.Count > 0 then begin  // se NON trova il path per marking ma ha un OriginalPath
                    goto DoOriginalPath0;
                  end;
                end

   { Playmaker GETFAVOURCELLPATH si avvicina al proprio compagno portatore di palla}

                else if ( (aPlayer.TalentId1 = TALENT_ID_PLAYMAKER)  or (aPlayer.TalentId2 = TALENT_ID_PLAYMAKER) )  and ( not toball)  then begin  // o not aPlayer.hasball
                  if Ball.Player <> nil then begin // se qualcuno ha la palla
                    if Ball.Player.Team = aPlayer.team then begin // se questo qualcuno che ha la palla è del mio stesso team
                       GetFavourCellPath( aPlayer, ball.CellX, ball.celly ); // cerfco la cella di favore
                        if aPlayer.MovePath.Count > 0 then begin
                          aPlayer.Stamina := aPlayer.Stamina - cost_plm;
                          TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;

                          dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                          TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                        IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                          aPlayer.CellS :=  dstCell;
                          ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                        end;

                    end;
                  end;
                end

                else if ( (aPlayer.TalentId1 = TALENT_ID_MARKING) or (aPlayer.TalentId2 = TALENT_ID_MARKING)  )  and ( not toball)  then begin  // o not aPlayer.hasball
                  GetMarkingPath ( aPlayer );
                  if aPlayer.MovePath.Count > 0 then begin
                      aPlayer.Stamina := aPlayer.Stamina - cost_plm;
                      TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;

                      dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                      TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                    IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                      aPlayer.CellS :=  dstCell;


                      ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                  end
                  else if OriginalPath.Count > 0 then begin  // se NON trova il path per marking ma ha un OriginalPath
                    goto DoOriginalPath0;
                  end;
                end
                else if ( (aPlayer.TalentId1 = TALENT_ID_AGGRESSION) or  (aPlayer.TalentId2 = TALENT_ID_AGGRESSION) )  and ( not toball)  then begin  // o not aPlayer.hasball
                  if Ball.Player <> nil then begin
                    if Ball.Player.Team <> aPlayer.Team then begin
                      GetAggressionCellPath( aPlayer, Ball.CellX, Ball.CellY ); // cerco la cella del portatore di palla
                      if aPlayer.MovePath.Count > 0 then begin
                        aPlayer.Stamina := aPlayer.Stamina - cost_plm;
                        TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;

                        dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                        TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                      IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                        aPlayer.CellS :=  dstCell;
                      // se fa pressing utomatico ed è a distanza 1 dal portatore di palla avversario
                      { TODO : fare particolare ACT qui per il talento TALENT_ID_ADVANCED_AGGRESSION}
                       // ACT := '0';
                        if (aPlayer.TalentId2 = TALENT_ID_ADVANCED_AGGRESSION) then begin
                          if absdistance ( aPlayer.CellX, aPlayer.CellX, ball.Player.CellX, ball.Player.celly) = 1 then begin
                            if rndgenerate(100) <= 25 then begin
                              aPlayer.Stamina := aPlayer.Stamina - cost_pre;
                              Ball.Player.UnderPressureTurn := 2;
                              Ball.Player.CanMove := False;  // NON PUO' MUOVERE , ma può dribblare con -2
                              Ball.Player.BallControl  := Ball.Player.BallControl - PRE_VALUE;  //  MINIMO 0, mai in negativo
                              Ball.Player.Passing  := Ball.Player.passing - PRE_VALUE;
                              Ball.Player.Shot := Ball.Player.Shot - PRE_VALUE;

                              if Ball.Player.BallControl <= 0 then Ball.Player.BallControl :=1;
                              if Ball.Player.Passing <= 0 then Ball.Player.Passing :=1;
                              if Ball.Player.Shot <= 0 then Ball.Player.Shot :=1;


                              tsSpeaker.Add( aPlayer.Surname +' (Pressing) fa pressing su ' + Ball.Player.ids {cella}  ) ;
                            end;
                          end;
                        end;

                        ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                      end
                      else if OriginalPath.Count > 0 then begin  // se NON trova il path per marking ma ha un OriginalPath
                          goto DoOriginalPath0;
                      end;
                    end;
                  end
                  else if OriginalPath.Count > 0 then begin  // se NON trova il path per marking ma ha un OriginalPath
                    goto DoOriginalPath0;
                  end;
                end
                else begin  // no toball e nessun talento ma un path normale(original), movimento off dif neutral
                  if aPlayer.MovePath.Count > 0 then begin
DoOriginalPath0:
                    CopyPath ( OriginalPath, aPlayer.MovePath   );
                    dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                    TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                    IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                    aPlayer.CellS :=  dstCell;
                  end;
                end;

             end;

         end; // Y
        end; // X
      end;   // metacampo 0 1..5

      // ALTRA METACAMPO

      6..10: begin
        for X := 10 downto 1 do begin      //<--
          for Y := 0 to 6 do begin
            aPlayer := GeTPlayer ( X,Y);
            if aPlayer = nil then continue;
            if not aPlayer.CanMove then continue;
            if aPlayer.HasBall then continue;
            if  inExceptPlayers ( aPlayer ) then  continue;
            if aPlayer.grouped  then Continue;     //<--- compilelistHeading (se non clear all'inizio qui )
            if aPlayer.stay then Continue; // mtb moveto ball sopra lo fa ovviamente a distanza 1 cerca di raggiungere la palla
            Toball := False;
//            if (aPlayer.Ids='p1004') or (aPlayer.Ids='p1006') then asm int 3 end;

                case TeamTurn of
                  0: begin
                              case aPlayer.Team of
                                0: begin
                                        case GetTeamBall of
                                          -1: begin
                                            if aPlayer.Role ='D' then begin       // metacampo 1, teamturn 0, aPlayer.team 0, palla neutra
                                                                                  // uguale palla team 0
                                              //L M N
                                              //off	defaultX+1
                                              //nor	…
                                              //dif	defaultX
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end;

                                            end
                                            else if aPlayer.Role ='M' then begin

                                              //off	p+1palla
                                              //nor	….
                                              //dif	p=se palla dietro
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                if Ball.CellX < aPlayer.cellX then
                                                   AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX <= 2 then
                                                  AI_MovePlayer_DefaultX ( aPlayer ) ;

                                              end;

                                            end
                                            else if aPlayer.Role ='F' then begin
                                              //  off	p+1palla
                                              //  nor	…
                                              //  dif	default

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                if Ball.CellX > aPlayer.cellX then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX < 6 then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                            end;
                                          end;
                                          0: begin                                // metacampo 1, teamturn 0, aPlayer.team 0, palla team 0
                                            if aPlayer.Role ='D' then begin
                                               // L M M
                                               // off	defaultX+2
                                              //  nor	defaultX
                                              //  dif	defaultX
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end

                                              // cerco la posizione default  -1 (avanzo) se la palla è davanti
                                              else begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end;

                                            end
                                            else if aPlayer.Role ='M' then begin
                                              //off	p+2palla
                                              //nor	p+1palla
                                              //dif	p=se palla dietro
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else begin
                                                 if aPlayer.CellX < Ball.cellx then
                                                    AI_MovePlayer_Ball_plus_1 ( aPlayer )
                                                  else if aPlayer.CellX < 5 then
                                                     AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;

                                            end
                                            else if aPlayer.Role ='F' then begin
                                            //off	p+2
                                            //nor	p+1 se dietro palla
                                            //dif	p=palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else begin
                                                 if aPlayer.CellX < Ball.cellx then
                                                    AI_MovePlayer_Ball_plus_1 ( aPlayer )
                                                  else if aPlayer.CellX < 6 then
                                                     AI_MovePlayer_DefaultX ( aPlayer ) ;

                                              end;
                                            end;

                                          end;

                                          1: begin
                                            if aPlayer.Role ='D' then begin     // metacampo 1, teamturn 0, aPlayer.team 0, palla team 1
                                               // L M L
                                               // off	defaultX
                                              //  nor	defaultX
                                              //  dif	defaultX
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;

                                            end
                                            else if aPlayer.Role ='M' then begin
                                              //off	p=palla
                                              //nor	….
                                              //dif	p-1palla se palla dietro
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 if Ball.CellX < aPlayer.CellX then
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX <= 2 then
                                                  AI_MovePlayer_DefaultX ( aPlayer ) ;

                                              end;
                                            end
                                            else if aPlayer.Role ='F' then begin
                                          //  off	default
                                          //  nor	…
                                         //   dif	default se oltre default
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 if aPlayer.CellX < aPlayer.defaultcellX then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX < 6 then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                            end;

                                          end;
                                        end;
                                   end;  // team 0

                                  1: begin
                                    case GetTeamBall of
                                      -1: begin
                                        if aPlayer.Role ='D' then begin        // metacampo 1, teamturn 0, aPlayer.team 1, palla neutra
                                          //M L N
                                          //off	defaultX
                                          //nor	…
                                          //dif	defaultX-1
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                                end
                                        end
                                        else if aPlayer.Role ='M' then begin
                                          //off	…..
                                          //nor	p-1palla se palla dietro
                                          //dif	p-1palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or  (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then Continue;

                                                if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX > aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                           // off	default
                                           // nor	…
                                           // dif	default-1
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                                end;
                                        end;

                                      end;
                                      0: begin                                 // metacampo 1, teamturn 0, aPlayer.team 1, palla team 0
                                        if aPlayer.Role ='D' then begin
                                            // M L L
                                            //off	defaultX
                                            //nor	defaultX
                                            //dif	defaultX-2

                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                AI_MovePlayer_DefaultX_minus_2 ( aPlayer ) ;
                                              end
                                              // -1 palla difendo solo se la palla è alle mie spalle o in linea
                                              else begin
                                                     if Ball.cellX >= aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_2( aPlayer )
                                                       else AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;

                                        end
                                        else if aPlayer.Role ='M' then begin
                                            //off	p=palla
                                            //nor	p-1palla se palla dietro
                                            //dif	p-2palla
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_minus_2 ( aPlayer  ) ;
                                              end
                                              else begin
                                                   if Ball.CellX > aPlayer.cellX then
                                                     AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                          //off	default se oltre default
                                          //nor	default se oltre default
                                         // dif	default-2
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                if aPlayer.CellX < aPlayer.DefaultCellX  then
                                                  AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  AI_MovePlayer_DefaultX_minus_2 ( aPlayer ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX < aPlayer.DefaultCellX  then
                                                  AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                        end;

                                      end;
                                      1: begin
                                        if aPlayer.Role ='D' then begin        // metacampo 1, teamturn 0, aPlayer.team 1, palla team 1
                                              //M L M
                                              //off	defaultX+1
                                              //nor	p-2  se palla <= o defaultX
                                              //dif	defaultX-1
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                              end

                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end

                                              // cerco la posizione default se la palla è davanti
                                              else begin
                                                     if Ball.cellX >= aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_2( aPlayer )
                                                       else AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='M' then begin

                                           // off	….
                                           // nor	p-1palla se palla dietro
                                           // dif	p-1palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or  (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then Continue;

                                                if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX > aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                          //off	default +1
                                          //nor	…
                                          //dif	default -1

                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or  (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE)  then begin
                                                   AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                                end;

                                        end;

                                      end;
                                    end;
                                  end;
                              end;
                     end;  // teamturn 0

                  1: begin // team 0 defend , teamturn 1  attack
                        case aPlayer.Team of
                          0: begin
                                    case GetTeamBall of
                                      -1: begin                                  // metacampo 1, teamturn 1,  aPlayer.team 0, palla  neutra
                                        if aPlayer.Role ='D' then begin
//                                          L L N
                                            //off	defaultX+1
                                            //nor	…..
                                            //dif	defaultX
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_plus_1 ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX( aPlayer ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                          //off	…..
                                          //nor	…..
                                          //dif	p-1palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                               if aPlayer.CellX <=2 then
                                                AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                              else begin
                                               if aPlayer.CellX <=2 then
                                                AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;

                                        end
                                        else if aPlayer.Role ='F' then begin
                                            //  off	p=palla
                                            //  nor	…..
                                            //  dif	default se oltre default
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                     AI_MovePlayer_Ball_equal ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                if aPlayer.CellX < aPlayer.DefaultCellX  then
                                                     AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end
                                              else begin
                                              if aPlayer.CellX < 6 then
                                                 AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;
                                      end;

                                      end;
                                      0: begin                                   // metacampo 1, teamturn 1,  aPlayer.team 0, palla team team 0
                                        if aPlayer.Role ='D' then begin
//                                          L L M
                                              //off	defaultX+1
                                              //nor	…
                                              //dif	defaultX
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                       AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end;
                                        end
                                        else if aPlayer.Role ='M' then begin
                                            //off	…
                                            //nor	p-1palla se palla dietro
                                            //dif	p-1palla
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                    if aPlayer.CellX <=2  then
                                                      AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX < aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  )
                                                      else if aPlayer.CellX <= 2 then
                                                       AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                             // off	p+1palla
                                             // nor	…
                                             // dif	p-1palla
                                                if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX > aPlayer.cellX then begin
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                     end
                                                     else begin
                                                      if aPlayer.CellX < 6 then
                                                      AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                     end;
                                                end;
                                        end;
                                      end;
                                      1: begin                                  // metacampo 1, teamturn 1,  aPlayer.team 0, palla team 1
                                        if aPlayer.Role ='D' then begin
                                               // L L L

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                     AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  if aPlayer.CellX > aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end
                                              else begin
                                                if aPlayer.CellX < 6 then
                                                   AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;

                                        end
                                        else if aPlayer.Role ='M' then begin
                                          //off	…..
                                          //nor	p-1palla se palla dietro
                                          //dif	p-1palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or  (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then Continue;

                                                if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                                end
                                                else begin
                                                     if Ball.CellX < aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1 ( aPlayer  )
                                                       else if aPlayer.CellX <= 2 then
                                                       AI_MovePlayer_DefaultX ( aPlayer ) ;
                                                end;





                                        end
                                        else if aPlayer.Role ='F' then begin
                                                //    off	default se oltre default
                                                //    nor	…
                                                //    dif	default se oltre default
                                                if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                  if aPlayer.CellX < aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_Ball_equal ( aPlayer  ) ;
                                                end
                                                else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                  if aPlayer.CellX < aPlayer.DefaultCellX  then
                                                       AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                end;
                                        end;

                                      end;
                                    end;

                          end;
                          1: begin
                                    case GetTeamBall of
                                      -1: begin                                  // metacampo 1, teamturn 1, aPlayer.team 1, palla  neutra
                                        if aPlayer.Role ='D' then begin
                                              //M M N
                                              //off	defaultX+1
                                              //nor	…
                                              //dif	defaultX-1

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                    AI_MovePlayer_DefaultX_plus_1 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                              end
                                        end
                                        else if aPlayer.Role ='M' then begin
//                                              p=palla se palla davanti
//                                              …..
//                                              p-1 palla
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 if Ball.CellX < aPlayer.cellX then
                                                   AI_MovePlayer_Ball_equal ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end;


                                        end
                                        else if aPlayer.Role ='F' then begin
                                              //off	…
                                              //nor	…
                                              //dif	default-1 se oltre default
                                              if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 if aPlayer.CellX < aPlayer.DefaultCellX then begin
                                                 AI_MovePlayer_DefaultX_minus_1 ( aPlayer  ) ;
                                                 end;
                                              end;
                                        end;

                                      end;
                                      0: begin                                   // metacampo 1, teamturn 1, aPlayer.team 1, palla team 0
                                        if aPlayer.Role ='D' then begin
//                                                M M L
                                                  //off	defaultX
                                                  //nor	p-1  se palla <= o defaultX
                                                  //dif	defaultX-1

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   if Ball.CellX > aPlayer.cellX then
                                                     AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                     AI_MovePlayer_DefaultX_minus_1 ( aPlayer ) ;
                                              end
                                              // cerco la posizione default se la palla è davanti
                                              else begin
                                                     if Ball.cellX >= aPlayer.cellX then
                                                       AI_MovePlayer_Ball_minus_1( aPlayer )
                                                       else AI_MovePlayer_DefaultX ( aPlayer ) ;
                                              end;

                                        end
                                        else if aPlayer.Role ='M' then begin
                                              //off	p=palla se palla davanti
                                              //nor	…..
                                              //dif	p-1 palla

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   if Ball.CellX < aPlayer.cellX then
                                                     AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_minus_1 ( aPlayer  ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                              //  off	default se oltre default
                                              //  nor	default
                                              //  dif	default-1
                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                 if aPlayer.CellX < aPlayer.DefaultCellX then begin
                                                   AI_MovePlayer_DefaultX( aPlayer ) ;
                                                 end;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX_minus_1( aPlayer ) ;
                                              end
                                              else begin
                                                   AI_MovePlayer_DefaultX( aPlayer ) ;
                                              end;
                                        end;

                                      end;
                                      1: begin                                   // metacampo 1, teamturn 1, aPlayer.team 1, palla team 1
                                        if aPlayer.Role ='D' then begin

//                                              M M M
//                                              off	p+2palla
//                                              nor	default
 //                                             dif	p=palla

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_Ball_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer ) ;
                                              end
                                              // cerco la posizione default se la palla è davanti
                                              else begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                              end;
                                        end
                                        else if aPlayer.Role ='M' then begin

                                                //off	p+2palla
                                                //nor	p+1palla
                                                //dif	p=palla

                                              if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin
                                                   AI_MovePlayer_Ball_plus_2 ( aPlayer  ) ;
                                              end
                                              else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                 AI_MovePlayer_Ball_equal ( aPlayer  ) ;
                                              end
                                              else AI_MovePlayer_Ball_plus_1 ( aPlayer  ) ;
                                        end
                                        else if aPlayer.Role ='F' then begin
                                             // off	default se prima di default
                                             // nor	default
                                             // dif	default se oltre default

                                               if (aPlayer.TalentID1 = TALENT_ID_OFFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_OFFENSIVE) then begin

                                                 if aPlayer.CellX > aPlayer.DefaultCellX then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                 end;
                                               end
                                               else if (aPlayer.TalentID1 = TALENT_ID_DEFENSIVE) or (aPlayer.TalentID2 = TALENT_ID_DEFENSIVE) then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                               end
                                               else begin
                                                 if aPlayer.CellX < aPlayer.DefaultCellX then begin
                                                   AI_MovePlayer_DefaultX ( aPlayer  ) ;
                                                 end;

                                               end;
                                        end;

                                      end;
                                    end;

                          end;
                        end;
                      end;

                end;


             CopyPath ( aPlayer.MovePath , OriginalPath ); // i path devono esistere
             if (aPlayer.MovePath.Count > 0 ) {and not (aPlayer.grouped )} then begin
//             if (aCell.X <> -1) and not (aPlayer.grouped )then begin
               // se c'è spazio per rientrare
              ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                // controllo la presenza della palla libera sul percorso
                dstCell :=  Point (aPlayer.MovePath[aPlayer.MovePath.Count-1].X,aPlayer.MovePath[aPlayer.MovePath.Count-1].Y) ;
                for I := 0 to aPlayer.MovePath.Count -1 do begin
                  if  ( Ball.CellX = aPlayer.MovePath[i].X ) and ( Ball.CellY = aPlayer.MovePath[i].Y ) and (Ball.Player = nil) then begin
                     dstCell := Point (aPlayer.MovePath[i].X,aPlayer.MovePath[i].Y) ;
                     Toball := True;
                        // bonus al tiro anche per ai:moveALL
                        if (aPlayer.MovePath.Count >= 2) and ( aPlayer.HasBall )  then begin
                         aPlayer.BonusPLMTurn := 1;
                         aPlayer.Shot   := aPlayer.DefaultShot + 2 ;
                         aPlayer.Passing   := aPlayer.DefaultPassing + 2 ;
                        end;
                     break;

                  end;
                end;

             end;

                // se con il semplice aimoveall trovo la palla lo faccia, altrimenti valuto i talenti.
             if toball then

              TsScript[incMove].add ('sc_player.move,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                                         IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  )
             else begin

//                aPlayer.MovePath.Clear ;
//      in ai_moveall prima fa aimoveall poi cerca la cella Y precisa defaultcellY ,  . spende di più a correr . utile per chi deve stare sulle fascie
                if ( (aPlayer.TalentId1 = TALENT_ID_POSITIONING) or (aPlayer.TalentId2 = TALENT_ID_POSITIONING) )  and ( not toball)  then begin  // o not aPlayer.hasball
                  AI_MovePlayer_DefaultY ( aPlayer ) ;
                  if aPlayer.MovePath.Count > 0 then begin   // se trova il path per marking
                    aPlayer.Stamina := aPlayer.Stamina - cost_plm;
                    TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;

                    dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                    TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                  IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                    aPlayer.CellS :=  dstCell;
                    ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                  end
                  else if OriginalPath.Count > 0 then begin  // se NON trova il path per marking ma ha un OriginalPath
                    goto DoOriginalPath1;
                  end;
                end

   { Playmaker GETFAVOURCELLPATH si avvicina al proprio compagno portatore di palla}

                else if ( (aPlayer.TalentId1 = TALENT_ID_PLAYMAKER)  or (aPlayer.TalentId2 = TALENT_ID_PLAYMAKER) )  and ( not toball)  then begin  // o not aPlayer.hasball
                  if Ball.Player <> nil then begin // se qualcuno ha la palla
                    if Ball.Player.Team = aPlayer.team then begin // se questo qualcuno che ha la palla è del mio stesso team
                       GetFavourCellPath( aPlayer, ball.CellX, ball.celly ); // cerfco la cella di favore
                        if aPlayer.MovePath.Count > 0 then begin
                          aPlayer.Stamina := aPlayer.Stamina - cost_plm;
                          TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;

                          dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                          TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                        IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                          aPlayer.CellS :=  dstCell;
                          ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                        end
                        else if OriginalPath.Count > 0 then begin  // se NON trova il path per marking ma ha un OriginalPath
                          goto DoOriginalPath1;
                        end;

                    end;
                  end;
                end

                else if ( (aPlayer.TalentId1 = TALENT_ID_MARKING)  or (aPlayer.TalentId2 = TALENT_ID_MARKING) )  and ( not toball)  then begin  // o not aPlayer.hasball
                  GetMarkingPath ( aPlayer );
                  if aPlayer.MovePath.Count > 0 then begin
                    aPlayer.Stamina := aPlayer.Stamina - cost_plm;
                    TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;

                    dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                    TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                  IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                    aPlayer.CellS :=  dstCell;
                    ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                  end
                  else if OriginalPath.Count > 0 then begin  // se NON trova il path per marking ma ha un OriginalPath
                    goto DoOriginalPath1;
                  end;
                end
                else if ( (aPlayer.TalentId1 = TALENT_ID_AGGRESSION) or (aPlayer.TalentId2 = TALENT_ID_AGGRESSION) )  and ( not toball)  then begin  // o not aPlayer.hasball
                  if Ball.Player <> nil then begin
                    if Ball.Player.Team <> aPlayer.Team then begin
                      GetAggressionCellPath( aPlayer, Ball.CellX, Ball.CellY ); // cerco la cella del portatore di palla
                      if aPlayer.MovePath.Count > 0 then begin
                        aPlayer.Stamina := aPlayer.Stamina - cost_plm;
                        TsScript[incMove].add ('sc_ST,' + aPlayer.ids +',' + IntToStr(cost_plm) ) ;

                        dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                        TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                      IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                        aPlayer.CellS :=  dstCell;
                        ExceptPlayers.Add(aPlayer); // o me lo ritrovo più avanti nel ciclo
                      end;
                    end;
                  end
                  else if OriginalPath.Count > 0 then begin  // se NON trova il path per marking ma ha un OriginalPath
                    goto DoOriginalPath1;
                  end;
                end
                else begin  // no toball e nessun talento ma un path normale(original), movimento off dif neutral
                  if aPlayer.MovePath.Count > 0 then begin
DoOriginalPath1:
                    CopyPath ( OriginalPath, aPlayer.MovePath   );
                    dstCell := Point (aPlayer.MovePath[aPlayer.MovePath.Count -1].X,aPlayer.MovePath[aPlayer.MovePath.Count -1].Y) ;
                    TsScript[incMove].add ('sc_pa,'+ aPlayer.Ids +','+IntTostr(aPlayer.CellX)+','+ IntTostr(aPlayer.CellY)+','+
                                    IntTostr(dstCell.X   )+','+ IntTostr( dstCell.Y)  ) ;
                    aPlayer.CellS :=  dstCell;
                  end;
                end;

             end;

         end; // Y
        end; // X
      end;
  end;










 OriginalPath.Free;

 ExceptPlayers.Clear ;
 TsScript[incMove].add ('sc_ai.endmoveall');

end;
procedure TBrain.DeflateBarrier ( aCell: Tpoint; ExceptPlayer: TPlayer ); // occhio al plurale! exceptplayers è una lista
var
  i: Integer;
  anOpponent: TPlayer;
begin
  //excpetPlayer è chi ha catturato la palla
  for I := Players.Count -1 downto 0 do begin
    anOpponent := Players[i];
    if (anOpponent.CellX = aCell.X)  and (anOpponent.CellY = aCell.Y) then begin

      if ExceptPlayer <> nil then
        if anOpponent.Ids = ExceptPlayer.ids then Continue;

      anOpponent.cells := FindDefensiveCellFree ( anOpponent.Team );
      anOpponent.isFKD3 := False;
      TsScript[incMove].add ('sc_player,'+ anOpponent.Ids +','+IntTostr(aCell.X)+','+ IntTostr(aCell.Y)+','+
      IntTostr(anOpponent.CellX)+','+ IntTostr(anOpponent.CellY)  ) ;
    end;
  end;
end;

function TBrain.GetTeamBall : integer;
var
  aPlayer: TPlayer;
begin
  aPlayer := GeTPlayer(ball.CellX, ball.CellY  );
  if aPlayer = nil then begin
    result := -1;
    exit;
  end;
  Result := aPlayer.Team;

end;
function TBrain.GetCrossDefenseBonus (aPlayer: TPlayer; CellX, CellY: integer ): integer;
begin

  if aPlayer.cellX = CellX then begin
    Result := -1;  {  era 0 }
    exit;
  end;

  case aPlayer.Team of
    0: begin
      if aPlayer.CellX < CellX then Result := 4
      else if aPlayer.CellX > CellX then Result := -2;  {  era 0 }
    end;
    1: begin
      if aPlayer.CellX > CellX then Result := 4
      else if aPlayer.CellX < CellX then Result := -2;  {  era 0 }
    end;
  end;
end;

procedure TBrain.CalculateChance  ( A, B: integer; var chanceA, chanceB: integer);
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

end;

function TBrain.NextReserveSlot ( aPlayer: TPlayer): Integer;
var
  x: Integer;
begin
  for x := 0 to 21  do begin
    if ReserveSlot [aPlayer.team,x] = '' then begin
      Result := x;
      Exit;
    end;
  end;
end;
procedure TBrain.PutInReserveSlot ( aPlayer: TPlayer );  // mette il player nella prima cella di riserva libera
var
  NextSlot: Integer;
begin
    NextSlot:= NextReserveSlot (aPlayer);
    ReserveSlot [aPlayer.Team, NextSlot]:= aPlayer.Ids;
    aPlayer.CellX := NextSlot;
    aPlayer.CellY := -1;
    aPlayer.DefaultCells := aPlayer.Cells;
    aPlayer.AIFormationCellX := aPlayer.CellX;
    aPlayer.AIFormationCellY := aPlayer.CellY;
    aPlayer.Role := 'N';
end;
procedure TBrain.PutInReserveSlot ( aPlayer: TPlayer; ReserveCell: TPoint );  // mette il player nella cella indicata
begin
    ReserveSlot [aPlayer.Team, ReserveCell.X]:= aPlayer.Ids;
    aPlayer.CellX := ReserveCell.X;
    aPlayer.CellY := -1;
    aPlayer.DefaultCells := aPlayer.Cells;
    aPlayer.AIFormationCellX := aPlayer.CellX;
    aPlayer.AIFormationCellY := aPlayer.CellY;
    aPlayer.Role := 'N';
end;
procedure TBrain.ClearReserveSlot;
var
  t,x: Integer;
begin
  for t := 0 to 1 do begin
    for x := 0 to 21 do begin
        ReserveSlot [t,x] := '';
    end;
  end;
end;

function TBrain.isReserveSlot (CellX, CellY: integer): boolean;
begin

  if (CellY = -1) and (( CellX > -1) and (CellX < 23)) then
    result := True
    else Result:= false;


end;
procedure TBrain.PutInGameOverSlot ( aPlayer: TPlayer );  // mette il player nella prima cella di GameOver libera
var
  NextSlot: Integer;
begin
    NextSlot:= NextGameOverSlot (aPlayer);
    GameOverSlot [aPlayer.Team, NextSlot]:= aPlayer.Ids;
    aPlayer.CellX := NextSlot;
    aPlayer.CellY := -2;
    aPlayer.DefaultCells := aPlayer.Cells;
    aPlayer.AIFormationCellX := aPlayer.CellX;
    aPlayer.AIFormationCellY := aPlayer.CellY;
    aPlayer.Role := 'N';
end;
procedure TBrain.PutInGameOverSlot ( aPlayer: TPlayer; GameOverCell: TPoint );  // mette il player nella cella indicata
begin
    GameOverSlot [aPlayer.Team, GameOverCell.X]:= aPlayer.Ids;
    aPlayer.CellX := GameOverCell.X;
    aPlayer.CellY := -2;
    aPlayer.DefaultCells := aPlayer.Cells;
    aPlayer.AIFormationCellX := aPlayer.CellX;
    aPlayer.AIFormationCellY := aPlayer.CellY;
    aPlayer.Role := 'N';
end;
procedure TBrain.ClearGameOverSlot;
var
  t,x: Integer;
begin
  for t := 0 to 1 do begin
    for x := 0 to 21 do begin
        GameOverSlot [t,x] := '';
    end;
  end;
end;

function TBrain.isGameOverSlot (CellX, CellY: integer): boolean;
begin

  if (CellY = -2) and (( CellX > -1) and (CellX < 23)) then
    result := True
    else Result:= false;


end;

procedure TBrain.UpdateDevi;
var
  i:integer;
begin
  // Tutti i panchinari. i gameover sono già salvi. Gli injured e i disqulified no
  for I := Reserves.Count -1 downto 1 do begin
    if (Reserves[i].Injured = 0) and (Reserves[i].disqualified = 0 ) then
      Reserves[i].xpDevI := Reserves[i].xpDevI + 1; // xpdevi quando raggiunge N es.20 stora a +1% devi. poi si resetta a 0 . tutto nel finalizebrain
  end;
  for I := Players.Count -1 downto 1 do begin
    if (Players[i].Injured = 0) then begin
      Players[i].xpDevI := Players[i].xpDevI - 1;
      if Players[i].xpDevI < 0 then
        Players[i].xpDevI := 0;  // xpdevi quando raggiunge 0 non fa nulla. ci pensa xpdeva a decrementare di 1 xpdevi
    end;
  end;
end;
function TBrain.CalculateBasePrecisionShot (  aPlayer: TPlayer ): TChance;
begin
  if w_FreeKick3 then begin
    aPlayer.tmp := 0;
    if (aPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (aPlayer.TalentId2 = TALENT_ID_FREEKICKS) then
      aPlayer.tmp:= 1;
    Result.Modifier :=  1 + aPlayer.tmp; // punizione bonus +1 fisso
    Result.Value := aPlayer.Shot + Result.Modifier ;
    if Result.Value  <= 0 then Result.Value  := 1;
    Result.aString := '.golprs3.';
    Result.aString2 := 'SERVER_PRS3';
  end
  else if w_FreeKick4 then begin
    Result.Modifier :=  modifier_penaltyPRS; // rigore prs
    Result.value :=  aPlayer.Shot + Result.Modifier ;
    if Result.Value  <= 0 then Result.Value  := 1;
    Result.aString := '.golprs4.';
    Result.aString2 := 'SERVER_PRS4';
  end
  else begin
    Result.Modifier :=  0;
    Result.value := aPlayer.Shot;
    if Result.Value  <= 0 then Result.Value  := 1;
    Result.aString := '.golprs.';
    Result.aString2 := 'SERVER_PRS';
  end;


end;
function TBrain.CalculateBasePowerShot (  aPlayer: TPlayer ): Tchance;
begin
  if w_FreeKick3 then begin
    aPlayer.tmp := 0;
    if (aPlayer.TalentId1 = TALENT_ID_FREEKICKS) or (aPlayer.TalentId2 = TALENT_ID_FREEKICKS) then
      aPlayer.tmp:= 1;               { TODO : convertire in costanti }

    Result.Modifier :=  + 1 + aPlayer.tmp ; // punizione bonus +1 fisso
    result.value := aPlayer.Shot + Result.Modifier  ; // punizione bonus +1 fisso
    if result.value <= 0 then result.value := 1;
    Result.aString := '.golpos3.';
    Result.aString2 := 'SERVER_POS3';
  end
  else if w_FreeKick4 then begin
    Result.Modifier :=  modifier_penaltyPRS;
    Result.value :=  aPlayer.Shot + Result.Modifier; // rigore prs
    if Result.value  <= 0 then Result.value  := 1;
    Result.aString := '.golpos4.';
    Result.aString2 := 'SERVER_POS4';
  end
  else begin
    Result.Modifier :=  0;
    Result.value  := aPlayer.Shot;
    if Result.value  <= 0 then Result.value  := 1;
    Result.aString := '.golpos.';
    Result.aString2 := 'SERVER_POS';
  end;


end;
function TBrain.CalculateBasePrecisionShotGK ( aPlayer: TPlayer ): Tchance;
begin
  Result.Modifier :=  BonusPrecisionShotGK [ Ball.Player.Cellx ];
  Result.value := aPlayer.Defense +  Result.Modifier;

end;
function TBrain.CalculateBasePowerShotGK ( aPlayer: TPlayer ): Tchance;
begin
  Result.Modifier :=  BonusPowerShotGK [ Ball.Player.Cellx ];
  Result.value := aPlayer.Defense +  Result.Modifier;

end;
function TBrain.CalculateBasePlmBallControl (  aPlayer: TPlayer ): Tchance;
begin
  // elaboro i talenti Challenge ma non advanced Challenge ( autotackle )
  Result.Modifier:=0;
  if (aPlayer.TalentId1 = TALENT_ID_CHALLENGE)  or (aPlayer.TalentId2 = TALENT_ID_CHALLENGE) then
  Result.Modifier := 1; { TODO : convertire in costanti }
  //if aPlayer.TalentId2 = TALENT_ID_ADVANCED_CHALLENGE then
  //if RndGenerate(100) < 5 then aPlayer.tmp := aPlayer.tmp + 1;

  Result.Value := aPlayer.BallControl + Result.Modifier;
  if aPlayer.TalentId2 = TALENT_ID_ADVANCED_CHALLENGE then
    Result.modifier2 := 1;
end;
function TBrain.CalculateBasePlmBaseAutoTackle (  aPlayer: TPlayer ): Tchance;
begin
  if  (aPlayer.TalentId1 = TALENT_ID_POWER)  or  (aPlayer.TalentId2 = TALENT_ID_POWER) then
   Result.Modifier := 1;
  if aPlayer.TalentId2 = TALENT_ID_ADVANCED_POWER then
    Result.modifier2 := 1;
  Result.Value := aPlayer.Defense + Result.Modifier;
end;
function TBrain.CalculateBaseShortPassing  (  aPlayer: TPlayer ): Tchance;
begin
  Result.Value := aPlayer.Passing;
end;
function TBrain.CalculateBaseShortPassingStopped (  aPlayer: TPlayer ): Tchance;
begin
  Result.Value := aPlayer.Defense;
end;
function TBrain.CalculateBaseShortPassingIntercept (  CellX, CellY: Integer; aPlayer: TPlayer ): Tchance;
var
  aFriend: TPlayer;
begin
  aFriend := GeTPlayer ( CellX , CellY);
  if aFriend = nil then
{ toemptycells lo devo riportare adesso }
    Result.Modifier := ToEmptyCellBonusDefending
  else

  Result.Modifier := 0;
  Result.Value := aPlayer.Defense + Result.Modifier ;

end;
function TBrain.CalculateBaseLoftedPass ( aPlayer: TPlayer ): Tchance;
begin
  Result.Value := aPlayer.Passing ;

end;
function TBrain.CalculateBaseLoftedPassBallControl ( aPlayer: TPlayer ): Tchance;
begin
  Result.Value := aPlayer.BallControl;

end;
function TBrain.CalculateBaseLoftedPassHeadingDefense ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
begin
  Result.Value := aPlayer.Heading;

end;
function TBrain.CalculateBaseLoftedPassEmptyPlmSpeed ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
begin
  Result.Value := aPlayer.Speed;

end;
function TBrain.CalculateBaseCrossing ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
begin
  Result.Modifier := 0;
  if (aPlayer.TalentId1 = TALENT_ID_CROSSING) or (aPlayer.TalentId2 = TALENT_ID_CROSSING) then
    Result.Modifier:= 1;                    { TODO : convertire in costanti }

  if aPlayer.TalentId2 = TALENT_ID_PRECISE_CROSSING then begin
    if (aPlayer.CellX = 1)  or (aPlayer.CellY = 10) then begin //cross dal fondo
      Result.Modifier := Result.Modifier + 1;
    end;
  end;

  if (aPlayer.TalentId2 = TALENT_ID_ADVANCED_CROSSING)  then
    Result.Modifier2 := 2;

  Result.Value := aPlayer.Passing + Result.Modifier;

end;
function TBrain.CalculateBaseCrossingHeadingDefense ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
begin

  Result.Value := aPlayer.Heading + GetCrossDefenseBonus (aPlayer, CellX, CellY );

end;
function TBrain.CalculateBaseCrossingHeadingFriend ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
begin

  Result.Value := aPlayer.Heading;

end;
function TBrain.CalculateBaseDribblingChance ( CellX, CellY: integer; aPlayer: TPlayer ): Tchance;
begin
  Result.Modifier := 0;

  Result.Value := aPlayer.BallControl -DRIBBLING_MALUS ;
  if (aPlayer.TalentId1 = TALENT_ID_DRIBBLING) or (aPlayer.TalentId2 = TALENT_ID_DRIBBLING) then
    Result.Modifier := 1;
  if (aPlayer.TalentId2 = TALENT_ID_ADVANCED_DRIBBLING)  then
    Result.Modifier := Result.Modifier + 1;          { TODO : convertire in costanti }

//      if (aPlayer.TalentId2 = TALENT_ID_SUPER_DRIBBLING)  then begin
//        if RndGenerate(100) <= 15 then begin
//          aPlayer.tmp := aPlayer.tmp + 3;
//          ACT := IntTostr (TALENT_ID_SUPER_DRIBBLING);
//        end;
//      end;
  Result.Value := aPlayer.BallControl + Result.Modifier -DRIBBLING_MALUS ;
  if Result.Value <= 0 then Result.Value := 1;

end;
function TBrain.CalculatBaseDribblingDefense ( CellX, CellY: integer; anOpponent: TPlayer ): Tchance;
begin
  Result.Value := anOpponent.Defense;
end;
function TBrain.Tv2AiField ( Team, tvX,tvY: integer ): TPoint;
var
  i: Integer;
begin
  // cerco in aifields
  for i := AIField.Count -1 downto 0 do begin
    if (Aifield[i].Team =Team) and (AIField[i].TV.X = tvX) and (AIField[i].TV.Y = tvY)then begin
      Result := AiField[i].AI;
      Exit;
    end;
  end;

end;
function TBrain.AiField2TV ( Team, aiX,aiY: integer ): TPoint;
var
  i: Integer;
begin
  for i := AIField.Count -1 downto 0 do begin
    if (Aifield[i].Team =Team) and (AIField[i].AI.X = aiX) and (AIField[i].AI.Y = aiY)then begin
      Result := AiField[i].TV;
      Exit;
    end;
  end;
end;
function TBrain.GetBestShotZone ( Team: integer; Zonerole:Char ): TPlayer;
var
  i,p,MaxShot: Integer;
  lstBestShot: TObjectList<TPlayer>;
begin
    // il result può essere nil se in zona non c'è nessuno
    lstBestShot:= TObjectList<TPlayer>.Create(False);

    for I := Players.Count -1 downto 0 do begin
// nin cerca un ruolo, cerca quelli che in quella zona hanno il Shot forte
      if (Players[i].Team = Team ) and ( Players[i].ZoneRole = Zonerole ) then
          lstBestShot.Add(Players[i]);
    end;

    if lstBestShot.count > 0 then begin

      lstBestShot.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := (R.Shot )- (L.Shot  );
      end
     ));
      MaxShot := lstBestShot[0].Shot   ;

      for P := lstBestShot.Count -1 downto 0 do begin
        if lstBestShot[p].Shot  < MaxShot then
          lstBestShot.Delete(p);
      end;
//      Result :=  lstBestShot[ brain.RndGenerate0(lstBestShot.Count-1)].Ids ;
      // dato che questa lista scompare passo il puntatore al player originale
      result := GeTPlayer( lstBestShot[ RndGenerate0(lstBestShot.Count-1)].Ids) ;
    end
    else Result := nil;
    lstBestShot.Free;
end;
function TBrain.GetBestPassingZone ( Team: integer; Zonerole:Char ): TPlayer;
var
  i,p,MaxPassing: Integer;
  lstBestPassing: TObjectList<TPlayer>;
begin
    // il result può essere nil se in zona non c'è nessuno
    lstBestPassing:= TObjectList<TPlayer>.Create(False);

    for I := Players.Count -1 downto 0 do begin
// nin cerca un ruolo, cerca quelli che in quella zona hanno il passing forte
      if (Players[i].Team = Team ) and ( Players[i].ZoneRole = Zonerole ) then
          lstBestPassing.Add(Players[i]);
    end;

    if lstBestPassing.count > 0 then begin

      lstBestPassing.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := (R.Passing )- (L.Passing  );
      end
     ));
      MaxPassing := lstBestPassing[0].Passing   ;

      for P := lstBestPassing.Count -1 downto 0 do begin
        if lstBestPassing[p].Passing  < MaxPassing then
          lstBestPassing.Delete(p);
      end;
//      Result :=  lstBestPassing[ brain.RndGenerate0(lstBestPassing.Count-1)].Ids ;
      // dato che questa lista scompare passo il puntatore al player originale
      result := GeTPlayer( lstBestPassing[ RndGenerate0(lstBestPassing.Count-1)].Ids ) ;
    end
    else Result := nil;
    lstBestPassing.Free;
end;
function TBrain.GetWorstBallControlZone ( Team: integer; Zonerole:Char ): TPlayer;
var
  i,p,MinBallControl: Integer;
  lstBestBallControl: TObjectList<TPlayer>;
begin
    // il result può essere nil se in zona non c'è nessuno
    lstBestBallControl:= TObjectList<TPlayer>.Create(False);

    for I := Players.Count -1 downto 0 do begin
// nin cerca un ruolo, cerca quelli che in quella zona hanno il BallControl forte
      if (Players[i].Team = Team ) and ( Players[i].ZoneRole = Zonerole ) then
          lstBestBallControl.Add(Players[i]);
    end;

    if lstBestBallControl.count > 0 then begin

      lstBestBallControl.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := (L.BallControl )- (R.BallControl  );     // <--- il più basso
      end
     ));
      MinBallControl := lstBestBallControl[0].BallControl   ;

      for P := lstBestBallControl.Count -1 downto 0 do begin
        if lstBestBallControl[p].BallControl  > MinBallControl then     // il più basso
          lstBestBallControl.Delete(p);
      end;
//      Result :=  lstBestBallControl[ brain.RndGenerate0(lstBestBallControl.Count-1)].Ids ;
      // dato che questa lista scompare passo il puntatore al player originale
      result := GeTPlayer( lstBestBallControl[ RndGenerate0(lstBestBallControl.Count-1)].Ids) ;
    end
    else Result := nil;
    lstBestBallControl.Free;
end;
function TBrain.GetWorstShot ( Team: integer ): TPlayer;
var
  i,p,MinShot: Integer;
  lstWorstShot: TObjectList<TPlayer>;
begin
    // il result può essere nil se in zona non c'è nessuno
    lstWorstShot:= TObjectList<TPlayer>.Create(False);

    for I := Players.Count -1 downto 0 do begin
// nin cerca un ruolo, cerca quelli che in quella zona hanno il BallControl forte

      if (Players[i].Team = Team ) and ( Players[i].TalentId1 <> TALENT_ID_GOALKEEPER) then
          lstWorstShot.Add(Players[i]);
    end;

    if lstWorstShot.count > 0 then begin

      lstWorstShot.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := (L.Shot )- (R.Shot  );     // <--- il più basso
      end
     ));
      MinShot := lstWorstShot[0].Shot   ;

      for P := lstWorstShot.Count -1 downto 0 do begin
        if lstWorstShot[p].Shot  > MinShot then     // il più basso
          lstWorstShot.Delete(p);
      end;
//      Result :=  lstWorstBallControl[ brain.RndGenerate0(lstWorstBallControl.Count-1)].Ids ;
      // dato che questa lista scompare passo il puntatore al player originale
      result := GeTPlayer( lstWorstShot[ RndGenerate0(lstWorstShot.Count-1)].Ids) ;
    end
    else Result := nil;
    lstWorstShot.Free;
end;
function TBrain.GetWorstDefense ( Team: integer ): TPlayer;
var
  i,p,MinDefense: Integer;
  lstWorstDefense: TObjectList<TPlayer>;
begin
    // il result può essere nil se in zona non c'è nessuno
    lstWorstDefense:= TObjectList<TPlayer>.Create(False);

    for I := Players.Count -1 downto 0 do begin
// nin cerca un ruolo, cerca quelli che in quella zona hanno il BallControl forte
      if (Players[i].Team = Team )  and ( Players[i].TalentId1 <> TALENT_ID_GOALKEEPER) then
          lstWorstDefense.Add(Players[i]);
    end;

    if lstWorstDefense.count > 0 then begin

      lstWorstDefense.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := (L.Defense )- (R.Defense  );     // <--- il più basso
      end
     ));
      MinDefense := lstWorstDefense[0].Defense   ;

      for P := lstWorstDefense.Count -1 downto 0 do begin
        if lstWorstDefense[p].Defense  > MinDefense then     // il più basso
          lstWorstDefense.Delete(p);
      end;
//      Result :=  lstWorstBallControl[ brain.RndGenerate0(lstWorstBallControl.Count-1)].Ids ;
      // dato che questa lista scompare passo il puntatore al player originale
      result := GeTPlayer( lstWorstDefense[ RndGenerate0(lstWorstDefense.Count-1)].Ids) ;
    end
    else Result := nil;
    lstWorstDefense.Free;
end;
function TBrain.GetWorstPassing ( Team: integer ): TPlayer;
var
  i,p,MinPassing: Integer;
  lstWorstPassing: TObjectList<TPlayer>;
begin
    // il result può essere nil se in zona non c'è nessuno
    lstWorstPassing:= TObjectList<TPlayer>.Create(False);

    for I := Players.Count -1 downto 0 do begin
// nin cerca un ruolo, cerca quelli che in quella zona hanno il BallControl forte
      if (Players[i].Team = Team )  and ( Players[i].TalentId1 <> TALENT_ID_GOALKEEPER) then
          lstWorstPassing.Add(Players[i]);
    end;

    if lstWorstPassing.count > 0 then begin

      lstWorstPassing.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := (L.Passing )- (R.Passing  );     // <--- il più basso
      end
     ));
      MinPassing := lstWorstPassing[0].Passing   ;

      for P := lstWorstPassing.Count -1 downto 0 do begin
        if lstWorstPassing[p].Passing  > MinPassing then     // il più basso
          lstWorstPassing.Delete(p);
      end;
//      Result :=  lstWorstBallControl[ brain.RndGenerate0(lstWorstBallControl.Count-1)].Ids ;
      // dato che questa lista scompare passo il puntatore al player originale
      result := GeTPlayer( lstWorstPassing[ RndGenerate0(lstWorstPassing.Count-1)].Ids) ;
    end
    else Result := nil;
    lstWorstPassing.Free;
end;


initialization

finalization
  ShotCells.Free;
  TVCrossingAreaCells.Free;
  AICrossingAreaCells.free;
  AIField.Free;

end.


