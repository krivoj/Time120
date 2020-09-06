unit utilities;
{$R-}
{$define tools}
interface
uses Winapi.Windows, Math, Inifiles, forms,Strutils, System.Classes, System.SysUtils,generics.collections, generics.defaults,
     MyAccess, DBAccess, Data.DB,
     SoccerBrainv3,dse_random,DSE_SearchFiles ,DSE_Misc, DSE_theater, dse_list ;

Type TeamStanding = class
  private
  public
    Guid : Integer;
    Name: string;
    Points ,GF,GS: Integer;
end;
type TopScorer = class
  private
  public
    Guid : string;
    Surname: string [25];
    Gol : Integer;
    GuidTeam: string;
end;
type TTeam = record
  guid : integer;
  money : integer;
  Division: Byte;
  YoungQueue: ShortInt;
end;
type TBasePlayer = record
  Guid : Integer;// in pve
  GuidTeam: Integer; // in pve viene assegnato il team
  Surname: string[25];
  Attributes : string[17]; // 01,02,03,04,05,06
  MatchesLeft : Integer;
  MatchesPlayed: Integer;
  Age : Byte;

  devA: Integer;
  devT: Integer;
  devI: Integer;
  xpdevA: Integer;
  xpdevT: Integer;
  xpdevI: Integer;

  TalentId1: byte;
  TalentId2: byte;
  Stamina: SmallInt;

  DefaultSpeed: ShortInt;
  DefaultDefense: ShortInt;
  DefaultPassing : ShortInt;
  DefaultBallControl: ShortInt;
  DefaultShot : ShortInt;
  DefaultHeading : ShortInt;

  Formation_X: ShortInt;
  Formation_Y: ShortInt;


  injured :ShortInt;
  yellowcard :Byte;
  disqualified :Byte;
  onmarket :Byte;
  face : Integer;
  fitness:Byte;
  morale:Byte;
  country:SmallInt;
  history:string[20];
  xp:string[255];

  History_Speed         :ShortInt;
  History_Defense       :ShortInt;
  History_Passing       :ShortInt;
  History_BallControl   :ShortInt;
  History_Shot          :ShortInt;
  History_Heading       :ShortInt;

  xp_Speed: integer;
  xp_Defense: integer;
  xp_BallControl: integer;
  xp_Passing: integer;
  xp_Shot: integer;
  xp_Heading: integer;


  XpTal: array [1..NUM_TALENT] of Integer;  // come i talenti sul db game.talents. xp guadagnata in questa partita(brain) per futuro trylevelup del talento

  Mark : byte;
  Price : Integer;
end;
  type TArray8192 = array [0..8191] of AnsiChar; // i buf[0..255] of  TArray8192 contengono il buffer Tcp in entrata
  type TArray32768 = array [0..32767] of AnsiChar; // per il market


  type TFinalFormation = record
    Guid : String;
    Cells: TPoint;
    Stamina: Integer;
    Role: string;
  end;

  type TTheArray = array[0..21] of string;    // le celle a sinistra della porta dove vengono posizionate le riserve

  type Array22 = array [0..21] of TBasePlayer;
  function CreateCalendars ( idCountry, Season, MyGuidTeam,MyGuidCountry: Integer; MyGuidTeamName, CountryName, dirData, dirSaves, dir_interface: string; var Engine:SE_Engine): string;
    procedure WriteCalendar ( season, idCountry, division,teamCount: Integer; var tsTHISrank: TStringList; dirData, dirSaves: string ); // rigenera anche i result
      procedure CreateResultsPreset(filename: string);// lo cra per ogni country e division

  procedure CreateTeams ( idCountry, Season, nFacesM,nFacesF: Integer; dirData, dirSaves: string);
    procedure GetMyGuidTeams ( Gender,dirsaves: string; idCountry, Season, D, TeamCount: Integer; var ArrayGuidTeams: SE_IntegerList ) ;
    function pveCreatePlayers ( fm : Char; GuidTeam,Season,idCountry,Division, level, nFacesM,nFacesF,lastInsertId: Integer; tsSurnames: TStringList; dirSaves: string): integer;
      procedure CreateCodeNamePlayer;
        procedure CodeNamePlayerF ( var MyTeam: Array22) ;
      function CreateSurname ( fm :Char; idCountry: Integer; tsSurnames:TStringList ): string;
      procedure SaveTeamStream ( fm :Char; GuidTeam: string; var MyTeam : array22; dirSaves: string); overload; // HELP_MyTeam22
      procedure SaveTeamStream ( fm :Char; GuidTeam: string; var lstPlayersDB : TObjectlist<TSoccerPlayer>; dirSaves: string); overload;
  procedure WriteTeamFormation ( fm :Char; GuidTeam, dirSaves, aCommaText: string );
  procedure pveLoadTeam ( Filename:string; fm : Char; Guidteam: integer;var lstPlayersDB : TObjectlist<TSoccerPlayer> );//uguale a ClientLoadFormation ma senza grafica

  function GetTeamRecord ( fm :Char; GuidTeam, dirSaves: string  ): TTeam;
  procedure UpdateCalendar ( aBrain: TsoccerBrain; dirSaves: string );

  procedure pveThinkMarket ( fm :Char; Division: Byte; GuidTeam , dirSaves: string); // effettua pvetransfermarket , dismiss, sell,
  function BuyPlayerFromMarket ( fm :Char; Budget,GuidTeam: Integer;  dirSaves: string): Integer; overload; // ritorna guid del player comprato
  function BuyPlayerFromMarket ( fm :Char; Budget,GuidTeam, TalentID: Integer;  dirSaves: string): Integer; overload; // ritorna guid del GK player comprato
  function pveGetTotalPlayersOnMarket ( fm :Char; GuidTeam: Integer; dirSaves: string ): Integer;

  function pveGetDBPlayer ( FileName, guid: string; var MyBasePlayer :TBasePlayer ): boolean;
  procedure pveAddToTeam (fm: Char; guid, FromGuidTeam, ToGuidTeam: integer; dirSaves: string );
  procedure pveDeleteFromTeam ( fm:Char; guid, GuidTeam : Integer; dirSaves:string); // riscrive es. f16.120

  procedure CreateFormationsPreset;
  function pvpCreateFormationTeam ( DbServer:string; fm : Char; Guidteam: integer; formation : string = ''): string; // uguali, cambia la parte sopra ( per overflow)
  function pveCreateFormationTeam ( Filename:string; fm : Char; Guidteam: integer; ForceYoung: boolean; formation : string = ''): string; // uguali, cambia la parte sopra ( per overflow)
  procedure CleanReserveSlot ( ReserveSlot: TTheArray );
  function NextReserveSlot ( ReserveSlot: TTheArray ): Integer;


  function Buff_or_Debuff_4 ( aPlayer: TSoccerPlayer; buff,Max_stat:Integer): Boolean;
  function isReserveSlot (CellX, CellY: integer): boolean;
  function isReserveSlotFormation (CellX, CellY: integer): boolean;


  procedure EmulationBrain ( aBrain: TSoccerBrain; dirSaves: string); // usa i file ad eliminazione es. mrC001D3.120
    function DeleteFromresults ( Index : Integer; var lstByte:TList<Byte> ): TPoint; // un risultato

  //  procedure OverWriteMyTeam (  MyGuidTeam , MyGuidCountry, ActiveSeason,MyDivision: Integer; MyTeamName,dirData, dirSaves: string);
  procedure PveAddToMarket (fm:char; Guid, GuidTeam, dirSaves: string; Price:Integer );
  function PveDeleteFromMarket (fm:char; Guid: string; dirSaves: string ): boolean;
  function pveOnMarket (fm: char; Guid: string; dirSaves: string): Boolean;
  function pveGetTotMarket (fm: char; GuidTeam, DirSaves: string): Integer;
  procedure pveTransferMarket ( fm: char; guid, ToGuidTeam: integer; DirSaves: string  ); // il fromTeam lo trova nel record. Accede al fromteam per eliminare il giocatore
  procedure pveTransferMoney (fm: Char; FromGuidTeam, ToGuidTeam, price: integer; dirSaves: string  );
  procedure pveAddTeamMoney (fm: Char; GuidTeam, Price : integer; dirSaves: string  );
  procedure pveSubtractTeamMoney ( fm: Char; GuidTeam, Price: Integer; DirSaves : string );// sfoglio tutte le divisioni alla ricerca dei 2 team
  procedure pveSetTeamMoney (fm: Char; GuidTeam, Total : integer; dirSaves: string  );
  function pveGetTeamInfo (fm: Char; GuidTeam: integer; dirSaves: string  ): TTeam;
  procedure MakeDelay ( interval: integer);

  procedure AllRainXp ( var aPlayer: TSoccerPlayer);


  procedure CreateNewSeason ( NewSeason , Country : Integer; dirData, dirSaves:string );

  procedure GetBuildInfo(var V1, V2, V3, V4: Word);
  function kfVersionInfo: String;

  function GetFitnessModifier ( fitness: integer ): integer;
  procedure calc_injured_attribute_lost ( var aPlayer: TSoccerPlayer);
  function GetSoccerPlayer (Guid : Integer; var lstPlayers: TObjectList<TSoccerPlayer>): TSoccerPlayer;

  procedure Calc_Standing ( fm :char; Season, Country, Division: integer; dirSaves : string; var lstTeam: TObjectList<TeamStanding>; var lstScorers: TobjectList<TopScorer>  );
//  procedure CreateTableResults; // crea la base 38*10 e la base 30*8
var
  FormationsPreset: TList<TFormation>;
  DivisionMatchCount : array[1..5] of Integer;
  DivisionRoundCount : array[1..5] of Integer;
  DivisionTeamCount : array[1..5] of Integer;

implementation
var
  CodeNamePlayer : array [0..21] of TBasePlayer;
  RandGen: TtdBasePRNG;
  MoneyBase : array [1..2,1..5,0..1] of Integer;  // fm, division, money
//nction RndGenerate( Upper: integer ): integer;
//function RndGenerateRange( Lower, Upper: integer ): integer;
//function RndGenerate0( Upper: integer ): integer;
function RndGenerate0( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (0, Upper + 1));
end;
function RndGenerate( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (1, Upper + 1));
end;
function RndGenerateRange( Lower, Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (Lower, Upper + 1));
end;


procedure CreateCodeNamePlayer;
begin

  // crea il team perfetto. f, a parte speed, è round(div 2)

  CodeNamePlayer[11].Surname := 'kolyvanov';
  CodeNamePlayer[11].TalentId1 := TALENT_ID_DRIBBLING;
  CodeNamePlayer[11].TalentId2 := TALENT_ID_ADVANCED_DRIBBLING;
  CodeNamePlayer[11].DefaultSpeed := 3;
  CodeNamePlayer[11].DefaultDefense := 2;
  CodeNamePlayer[11].DefaultBallControl := 9;
  CodeNamePlayer[11].DefaultPassing := 9;
  CodeNamePlayer[11].DefaultShot := 10;
  CodeNamePlayer[11].DefaultHeading := 7;
  CodeNamePlayer[11].Age := 26;

  CodeNamePlayer[12].Surname := 'cassano';
  CodeNamePlayer[12].TalentId1 := TALENT_ID_DRIBBLING;
  CodeNamePlayer[12].TalentId2 := TALENT_ID_SUPER_DRIBBLING;
  CodeNamePlayer[12].DefaultSpeed := 3;
  CodeNamePlayer[12].DefaultDefense := 2;
  CodeNamePlayer[12].DefaultBallControl := 8;
  CodeNamePlayer[12].DefaultPassing := 10;
  CodeNamePlayer[12].DefaultShot := 8;
  CodeNamePlayer[12].DefaultHeading := 3;
  CodeNamePlayer[12].Age := 26;

  CodeNamePlayer[2].Surname := 'cruz';
  CodeNamePlayer[2].TalentId1 := TALENT_ID_HEADING;
  CodeNamePlayer[2].TalentId2 := TALENT_ID_POSITIONING;
  CodeNamePlayer[2].DefaultSpeed := 3;
  CodeNamePlayer[2].DefaultDefense := 2;
  CodeNamePlayer[2].DefaultBallControl := 8;
  CodeNamePlayer[2].DefaultPassing := 7;
  CodeNamePlayer[2].DefaultShot := 8;
  CodeNamePlayer[2].DefaultHeading := 10;
  CodeNamePlayer[2].Age := 26;

  CodeNamePlayer[3].Surname := 'rabiot';
  CodeNamePlayer[3].TalentId1 := TALENT_ID_CROSSING;
  CodeNamePlayer[3].TalentId2 := TALENT_ID_PRECISE_CROSSING;
  CodeNamePlayer[3].DefaultSpeed := 4;
  CodeNamePlayer[3].DefaultDefense := 4;
  CodeNamePlayer[3].DefaultBallControl := 8;
  CodeNamePlayer[3].DefaultPassing := 9;
  CodeNamePlayer[3].DefaultShot := 8;
  CodeNamePlayer[3].DefaultHeading := 7;
  CodeNamePlayer[3].Age := 26;

  // centrocampisti

  CodeNamePlayer[4].Surname := 'pirlo';
  CodeNamePlayer[4].TalentId1 := TALENT_ID_LONGPASS;
  CodeNamePlayer[4].TalentId2 := TALENT_ID_ACE;
  CodeNamePlayer[4].DefaultSpeed := 3;
  CodeNamePlayer[4].DefaultDefense := 5;
  CodeNamePlayer[4].DefaultBallControl := 8;
  CodeNamePlayer[4].DefaultPassing := 9;
  CodeNamePlayer[4].DefaultShot := 9;
  CodeNamePlayer[4].DefaultHeading := 5;
  CodeNamePlayer[4].Age := 26;

  CodeNamePlayer[5].Surname := 'conti';
  CodeNamePlayer[5].TalentId1 := TALENT_ID_CROSSING;
  CodeNamePlayer[5].TalentId2 := TALENT_ID_ADVANCED_CROSSING;
  CodeNamePlayer[5].DefaultSpeed := 3;
  CodeNamePlayer[5].DefaultDefense := 5;
  CodeNamePlayer[5].DefaultBallControl := 8;
  CodeNamePlayer[5].DefaultPassing := 9;
  CodeNamePlayer[5].DefaultShot := 8;
  CodeNamePlayer[5].DefaultHeading := 5;
  CodeNamePlayer[5].Age := 26;

  CodeNamePlayer[6].Surname := 'oriali';
  CodeNamePlayer[6].TalentId1 := TALENT_ID_EXPERIENCE;
  CodeNamePlayer[6].TalentId2 := TALENT_ID_ADVANCED_EXPERIENCE;
  CodeNamePlayer[6].DefaultSpeed := 3;
  CodeNamePlayer[6].DefaultDefense := 5;
  CodeNamePlayer[6].DefaultBallControl := 7;
  CodeNamePlayer[6].DefaultPassing := 9;
  CodeNamePlayer[6].DefaultShot := 5;
  CodeNamePlayer[6].DefaultHeading := 8;
  CodeNamePlayer[6].Age := 26;

  CodeNamePlayer[7].Surname := 'oriali2';
  CodeNamePlayer[7].TalentId1 := TALENT_ID_EXPERIENCE;
  CodeNamePlayer[7].TalentId2 := TALENT_ID_RAPIDPASSING;
  CodeNamePlayer[7].DefaultSpeed := 3;
  CodeNamePlayer[7].DefaultDefense := 7;
  CodeNamePlayer[7].DefaultBallControl := 8;
  CodeNamePlayer[7].DefaultPassing := 8;
  CodeNamePlayer[7].DefaultShot := 5;
  CodeNamePlayer[7].DefaultHeading := 8;
  CodeNamePlayer[7].Age := 26;

  CodeNamePlayer[8].Surname := 'totti';
  CodeNamePlayer[8].TalentId1 := TALENT_ID_BOMB;
  CodeNamePlayer[8].TalentId2 := TALENT_ID_ADVANCED_BOMB;
  CodeNamePlayer[8].DefaultSpeed := 3;
  CodeNamePlayer[8].DefaultDefense := 3;
  CodeNamePlayer[8].DefaultBallControl := 9;
  CodeNamePlayer[8].DefaultPassing := 9;
  CodeNamePlayer[8].DefaultShot := 10;
  CodeNamePlayer[8].DefaultHeading := 9;
  CodeNamePlayer[8].Age := 26;

  CodeNamePlayer[9].Surname := 'gattuso';
  CodeNamePlayer[9].TalentId1 := TALENT_ID_BULLDOG;
  CodeNamePlayer[9].TalentId2 := TALENT_ID_MARKING;
  CodeNamePlayer[9].DefaultSpeed := 3;
  CodeNamePlayer[9].DefaultDefense := 8;
  CodeNamePlayer[9].DefaultBallControl := 7;
  CodeNamePlayer[9].DefaultPassing := 7;
  CodeNamePlayer[9].DefaultShot := 5;
  CodeNamePlayer[9].DefaultHeading := 5;
  CodeNamePlayer[9].Age := 26;

  CodeNamePlayer[10].Surname := 'iniesta';
  CodeNamePlayer[10].TalentId1 := TALENT_ID_PLAYMAKER;
  CodeNamePlayer[10].TalentId2 := TALENT_ID_RAPIDPASSING;
  CodeNamePlayer[10].DefaultSpeed := 3;
  CodeNamePlayer[10].DefaultDefense := 5;
  CodeNamePlayer[10].DefaultBallControl := 8;
  CodeNamePlayer[10].DefaultPassing := 9;
  CodeNamePlayer[10].DefaultShot := 8;
  CodeNamePlayer[10].DefaultHeading := 7;
  CodeNamePlayer[10].Age := 26;

  CodeNamePlayer[0].Surname := 'zoff';
  CodeNamePlayer[0].TalentId1 := TALENT_ID_GOALKEEPER;
  CodeNamePlayer[0].TalentId2 := TALENT_ID_RAPIDPASSING;
  CodeNamePlayer[0].DefaultSpeed := 1;
  CodeNamePlayer[0].DefaultDefense := 10;
  CodeNamePlayer[0].DefaultBallControl := 1;
  CodeNamePlayer[0].DefaultPassing := 10;
  CodeNamePlayer[0].DefaultShot := 1;
  CodeNamePlayer[0].DefaultHeading := 1;
  CodeNamePlayer[0].Age := 26;

  CodeNamePlayer[1].Surname := 'jascin';
  CodeNamePlayer[1].TalentId1 := TALENT_ID_GOALKEEPER;
  CodeNamePlayer[1].TalentId2 := TALENT_ID_GKPENALTY;
  CodeNamePlayer[1].DefaultSpeed := 1;
  CodeNamePlayer[1].DefaultDefense := 9;
  CodeNamePlayer[1].DefaultBallControl := 1;
  CodeNamePlayer[1].DefaultPassing := 9;
  CodeNamePlayer[1].DefaultShot := 1;
  CodeNamePlayer[1].DefaultHeading := 1;
  CodeNamePlayer[1].Age := 26;

  CodeNamePlayer[13].Surname := 'nesta';
  CodeNamePlayer[13].TalentId1 := TALENT_ID_TOUGHNESS;
  CodeNamePlayer[13].TalentId2 := TALENT_ID_ADVANCED_TOUGHNESS;
  CodeNamePlayer[13].DefaultSpeed := 3;
  CodeNamePlayer[13].DefaultDefense := 10;
  CodeNamePlayer[13].DefaultBallControl := 7;
  CodeNamePlayer[13].DefaultPassing := 5;
  CodeNamePlayer[13].DefaultShot := 2;
  CodeNamePlayer[13].DefaultHeading := 10;
  CodeNamePlayer[13].Age := 26;

  CodeNamePlayer[14].Surname := 'cannavaro';
  CodeNamePlayer[14].TalentId1 := TALENT_ID_DEFENSIVE;
  CodeNamePlayer[14].TalentId2 := TALENT_ID_MARKING;
  CodeNamePlayer[14].DefaultSpeed := 3;
  CodeNamePlayer[14].DefaultDefense := 9;
  CodeNamePlayer[14].DefaultBallControl := 7;
  CodeNamePlayer[14].DefaultPassing := 5;
  CodeNamePlayer[14].DefaultShot := 2;
  CodeNamePlayer[14].DefaultHeading := 9;
  CodeNamePlayer[14].Age := 26;

  CodeNamePlayer[15].Surname := 'lyanco';
  CodeNamePlayer[15].TalentId1 := TALENT_ID_POWER;
  CodeNamePlayer[15].TalentId2 := TALENT_ID_BUFF_DEFENSE;
  CodeNamePlayer[15].DefaultSpeed := 3;
  CodeNamePlayer[15].DefaultDefense := 8;
  CodeNamePlayer[15].DefaultBallControl := 8;
  CodeNamePlayer[15].DefaultPassing := 6;
  CodeNamePlayer[15].DefaultShot := 2;
  CodeNamePlayer[15].DefaultHeading := 8;
  CodeNamePlayer[15].Age := 26;

  CodeNamePlayer[16].Surname := 'zanetti';
  CodeNamePlayer[16].TalentId1 := TALENT_ID_DIVING;
  CodeNamePlayer[16].TalentId2 := TALENT_ID_BUFF_MIDDLE;
  CodeNamePlayer[16].DefaultSpeed := 3;
  CodeNamePlayer[16].DefaultDefense := 5;
  CodeNamePlayer[16].DefaultBallControl := 7;
  CodeNamePlayer[16].DefaultPassing := 9;
  CodeNamePlayer[16].DefaultShot := 5;
  CodeNamePlayer[16].DefaultHeading := 9;
  CodeNamePlayer[16].Age := 26;

  CodeNamePlayer[17].Surname := 'graziani';
  CodeNamePlayer[17].TalentId1 := TALENT_ID_FINISHING;
  CodeNamePlayer[17].TalentId2 := TALENT_ID_BUFF_FORWARD;
  CodeNamePlayer[17].DefaultSpeed := 3;
  CodeNamePlayer[17].DefaultDefense := 3;
  CodeNamePlayer[17].DefaultBallControl := 5;
  CodeNamePlayer[17].DefaultPassing := 6;
  CodeNamePlayer[17].DefaultShot := 8;
  CodeNamePlayer[17].DefaultHeading := 8;
  CodeNamePlayer[17].Age := 26;

  CodeNamePlayer[18].Surname := 'mbaye';
  CodeNamePlayer[18].TalentId1 := TALENT_ID_OFFENSIVE;
  CodeNamePlayer[18].TalentId2 := TALENT_ID_FAUL;
  CodeNamePlayer[18].DefaultSpeed := 4;
  CodeNamePlayer[18].DefaultDefense := 8;
  CodeNamePlayer[18].DefaultBallControl := 4;
  CodeNamePlayer[18].DefaultPassing := 7;
  CodeNamePlayer[18].DefaultShot := 2;
  CodeNamePlayer[18].DefaultHeading := 8;
  CodeNamePlayer[18].Age := 26;

  CodeNamePlayer[19].Surname := 'baresi';
  CodeNamePlayer[19].TalentId1 := TALENT_ID_AGGRESSION;
  CodeNamePlayer[19].TalentId2 := TALENT_ID_ADVANCED_AGGRESSION;
  CodeNamePlayer[19].DefaultSpeed := 3;
  CodeNamePlayer[19].DefaultDefense := 10;
  CodeNamePlayer[19].DefaultBallControl := 6;
  CodeNamePlayer[19].DefaultPassing := 7;
  CodeNamePlayer[19].DefaultShot := 2;
  CodeNamePlayer[19].DefaultHeading := 9;
  CodeNamePlayer[19].Age := 26;

  CodeNamePlayer[20].Surname := 'signori';
  CodeNamePlayer[20].TalentId1 := TALENT_ID_FREEKICKS;
  CodeNamePlayer[20].TalentId2 := TALENT_ID_AGILITY;
  CodeNamePlayer[20].DefaultSpeed := 3;
  CodeNamePlayer[20].DefaultDefense := 2;
  CodeNamePlayer[20].DefaultBallControl := 9;
  CodeNamePlayer[20].DefaultPassing := 8;
  CodeNamePlayer[20].DefaultShot := 10;
  CodeNamePlayer[20].DefaultHeading := 5;
  CodeNamePlayer[20].Age := 26;

  CodeNamePlayer[21].Surname := 'cabrini';
  CodeNamePlayer[21].TalentId1 := TALENT_ID_OFFENSIVE;
  CodeNamePlayer[21].TalentId2 := TALENT_ID_POSITIONING;
  CodeNamePlayer[21].DefaultSpeed := 4;
  CodeNamePlayer[21].DefaultDefense := 5;
  CodeNamePlayer[21].DefaultBallControl := 8;
  CodeNamePlayer[21].DefaultPassing := 8;
  CodeNamePlayer[21].DefaultShot := 7;
  CodeNamePlayer[21].DefaultHeading := 7;
  CodeNamePlayer[21].Age := 26;


end;

function PveCreatePlayers ( fm : Char; GuidTeam, Season,idCountry,Division, level, nFacesM,nFacesF,lastInsertId: Integer; tsSurnames: TStringList; dirSaves: string): Integer;

var
  i,aRnd,years,aValue,MarkCount,MarkCountMax,TCount: Integer;
  MyTeam : Array22;
  label MyExit;
begin

   // HEADING è libero
  // Level 1 (serie a).
    //  MF: Uno lo salva così come è.
    //  MF: Sui 22 player vengono cambiati gli anni in +5 -5 random.
  //  M: Sui 22 player a 11 vengono tolti 11 talentid2. a 11 vengono ridotti di -2 tutti i valori tranne speed.
    //  F: Sui 22 player a 11 vengono tolti 11 talentid2. a 11 vengono ridotti di -1 tutti i valori tranne speed.

  // level 2 (serie a forti ).
    //  M: Sui 22 player ai non marked vengono tolti 5 talentid1(non GK) e eventualmente il t2. a 10 ridotti di -2 tutti i valori tranne speed.
    //  F: Sui 22 player ai non marked vengono tolti 5 talentid1(non GK) e eventualmente il t2. a 5 ridotti di -1 tutti i valori tranne speed.

  // ora tutti e 22 sono marked

  // level 3 (serie a medio forti ).
    //  M: Sui 22 player a 11 vengono tolti 2 degli ultimi 5 talentid2 . a 11 ridotti di -1 tutti i valori tranne speed.
    //  F: Sui 22 player a 11 vengono tolti 2 degli ultimi 5 talentid2. a 5 ridotti di -1 tutti i valori tranne speed.

  // level 4 (serie a medie deboli).
    //  M: Sui 22 player vengono tolti tutti i talentid2. a 11 ridotti di -1 i valori tranne speed di 1.
    //  F: Sui 22 player vengono tolti tutti i talentid2. a 5 ridotti di -1 tutti i valori tranne speed di 1.

  // level 5 (serie a deboli / b).
    //  M: Sui 22 player vengono tolti 5 talentid1 (tranne GK). a 11 ridotti di -1 tutti i valori tranne speed di 1.
    //  F: Sui 22 player vengono tolti 5 talentid1 (tranne GK). a 5 ridotti di -1 tutti i valori tranne speed di 1.

  // level 6 (serie b / c).
    //  M: Sui 22 player vengono tolti 5 talentid1 (tranne GK). a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player vengono tolti 5 talentid1 (tranne GK). a 5 ridotti di -1 tutti i valori ANCHE speed di 1.

  // level 7 (serie b/c).
    //  M: Sui 22 player  a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player  a 5 ridotti di -1 tutti i valori ANCHE speed di 1.

  // level 8 (serie c/d).
    //  M: Sui 22 player  a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player  a 5 ridotti di -1 tutti i valori ANCHE speed di 1.

  // level 9 (serie d/e).
    //  M: Sui 22 player  a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player  a 5 ridotti di -1 tutti i valori ANCHE speed di 1.

  // level 10 (serie e).
    //  M: Sui 22 player  a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player  a 5 ridotti di -1 tutti i valori ANCHE speed di 1.

    // devo usare il mark per ridurre in modo omogeneo gli attributi. i talenti vengono eliminati direttamente
    // non vengono mai eliminati i talentid1 goal_keeper


  { lavoro in locale su myteam che è fisso a 22 player.Alla fine copio su DivisionPlayers.items[TeamMemoryIndex] che è un pointer }
  CreateCodeNamePlayer;
  CopyMemory(@MyTeam, @CodeNamePlayer[0], 22 * SizeOf(TBasePlayer));
  if fm = 'f' then
    CodeNamePlayerF ( MyTeam ); // riduco i valori di partenza
  //goto MyExit;

  MyTeam[ rndgenerate0 ( high(MyTeam) )].Mark := 1; // non lo tocco più a questo giro.

    //  MF: Sui 22 player vengono cambiati gli anni in +5 -5 random.
  for I := Low(MyTeam) to High(MyTeam) do begin
    years := rndgenerate (5);
    aRnd := RndGenerate(100);
    case aRnd of
      1..40: MyTeam[i].Age := MyTeam[i].Age - years;
      41..80: MyTeam[i].Age := MyTeam[i].Age + years;
    end;
//      case 81..20 of
        // 26 anni
  end;

  // Level 1
  //  M: Sui 22 player a 11 vengono tolti 11 talentid2. a 11 vengono ridotti di -2 tutti i valori tranne speed.
  //  F: Sui 22 player a 11 vengono tolti 11 talentid2. a 11 vengono ridotti di -1 tutti i valori tranne speed.
  if fm = 'm' then begin
    aValue := 2;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 11;
  end;

  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    if MyTeam [ aRnd ].Mark > 0 then Continue;
    MyTeam [ aRnd ].TalentId2 := 0;
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;

    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    MyTeam [ aRnd ].Mark := 1;
    inc (MarkCount);
  end;

  if Level <= 1 then
    goto MyExit;

  // Level 2
    //  M: Sui 22 player ai non marked vengono tolti 5 talentid1(non GK) e eventualmente il t2. a 10 ridotti di -2 tutti i valori tranne speed.
    //  F: Sui 22 player ai non marked vengono tolti 5 talentid1(non GK) e eventualmente il t2. a 5 ridotti di -1 tutti i valori tranne speed.
  // ora tutti e 22 sono marked

  TCount := 0;
  while TCount < 5 do begin
    aRnd := RndGenerate0(High(MyTeam));
    if (MyTeam [ aRnd ].Mark > 0) or  (MyTeam[aRnd].TalentId1=TALENT_ID_GOALKEEPER) then Continue;
    MyTeam [ aRnd ].TalentId2 := 0;
    MyTeam [ aRnd ].TalentId1 := 0;
    inc( TCount );
    // no mark qui
  end;

  if fm = 'm' then begin
    aValue := 2;
    MarkCountMax := 10;
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;

  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    if MyTeam [ aRnd ].Mark > 0 then Continue;
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;

    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    MyTeam [ aRnd ].Mark := 1;
    inc (MarkCount);
  end;

  if Level <= 2 then
    goto MyExit;

  // ora tutti e 22 sono marked. Non uso più il mark sugli attributi

  // Level 3
    //  M: Sui 22 player a 11 vengono tolti 2 degli ultimi 5 talentid2 (GK compreso per forza) . a 11 ridotti di -1 tutti i valori tranne speed.
    //  F: Sui 22 player a 11 vengono tolti 2 degli ultimi 5 talentid2 (GK compreso per forza). a 5 ridotti di -1 tutti i valori tranne speed.
  if fm = 'm' then begin
    aValue := 1;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;

  TCount := 0;
  for I := Low(MyTeam) to High(MyTeam) do begin
    // l'elemento 0 e 1 sono GK ai quali tolgo il talent2
    if MyTeam[i].TalentId2 <> 0 then begin
      MyTeam[i].TalentId2 := 0;
      Inc(tCount);
      if tCount = 2 then Break;
    end;
  end;

  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;

    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].Defaultheading <= 0 then MyTeam [ aRnd ].Defaultheading := 1;

    inc (MarkCount);
  end;

  if Level <= 3 then
    goto MyExit;

  // Level 4
    //  M: Sui 22 player vengono tolti tutti i talentid2. a 11 ridotti di -1 i valori tranne speed di 1.
    //  F: Sui 22 player vengono tolti tutti i talentid2. a 5 ridotti di -1 tutti i valori tranne speed di 1.
  if fm = 'm' then begin
    aValue := 1;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;

  for I := Low(MyTeam) to High(MyTeam) do begin
      MyTeam[i].TalentId2 := 0;
  end;

  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;

    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    inc (MarkCount);
  end;

  if Level <= 4 then
    goto MyExit;

  // Level 5
    //  M: Sui 22 player vengono tolti 5 talentid1 (tranne GK). a 11 ridotti di -1 tutti i valori tranne speed di 1.
    //  F: Sui 22 player vengono tolti 5 talentid1 (tranne GK). a 5 ridotti di -1 tutti i valori tranne speed di 1.
  if fm = 'm' then begin
    aValue := 1;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;

  TCount := 0;
  for I := Low(MyTeam) to High(MyTeam) do begin
    // l'elemento 0 e 1 sono GK ai quali tolgo il talent2
    if (MyTeam[i].TalentId1 <> 0) and (MyTeam[i].TalentId1 <> TALENT_ID_GOALKEEPER )  then begin
      MyTeam[i].TalentId1 := 0;
      Inc(tCount);
      if tCount = 5 then Break;
    end;
  end;

  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;


    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    inc (MarkCount);
  end;

  if Level <= 5 then
    goto MyExit;

  // Level 6
    //  M: Sui 22 player vengono tolti 5 talentid1 (tranne GK). a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player vengono tolti 5 talentid1 (tranne GK). a 5 ridotti di -1 tutti i valori ANCHE speed di 1.
               // uguale all'ultimo

  if fm = 'm' then begin
    aValue := 1;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;

  TCount := 0;
  for I := Low(MyTeam) to High(MyTeam) do begin
    // l'elemento 0 e 1 sono GK ai quali tolgo il talent2
    if (MyTeam[i].TalentId1 <> 0) and (MyTeam[i].TalentId1 <> TALENT_ID_GOALKEEPER )  then begin
      MyTeam[i].TalentId1 := 0;
      Inc(tCount);
      if tCount = 5 then Break;
    end;
  end;

  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    MyTeam [ aRnd ].DefaultSpeed := MyTeam [ aRnd ].DefaultSpeed - aValue;
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;

    if MyTeam [ aRnd ].DefaultSpeed <= 0 then MyTeam [ aRnd ].DefaultSpeed := 1;
    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    inc (MarkCount);
  end;
  if Level <= 6 then
    goto MyExit;

    //  M: Sui 22 player  a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player  a 5 ridotti di -1 tutti i valori ANCHE speed di 1.
  if fm = 'm' then begin
    aValue := 1;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;
  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    MyTeam [ aRnd ].DefaultSpeed := MyTeam [ aRnd ].DefaultSpeed - aValue;
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;

    if MyTeam [ aRnd ].DefaultSpeed <= 0 then MyTeam [ aRnd ].DefaultSpeed := 1;
    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    inc (MarkCount);
  end;
  if Level <= 7 then
    goto MyExit;


    //  M: Sui 22 player  a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player  a 5 ridotti di -1 tutti i valori ANCHE speed di 1.
  if fm = 'm' then begin
    aValue := 1;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;
  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    MyTeam [ aRnd ].DefaultSpeed := MyTeam [ aRnd ].DefaultSpeed - aValue;
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;


    if MyTeam [ aRnd ].DefaultSpeed <= 0 then MyTeam [ aRnd ].DefaultSpeed := 1;
    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    inc (MarkCount);
  end;
  if Level <= 8 then
    goto MyExit;

    //  M: Sui 22 player  a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player  a 5 ridotti di -1 tutti i valori ANCHE speed di 1.
  if fm = 'm' then begin
    aValue := 1;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;
  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    MyTeam [ aRnd ].DefaultSpeed := MyTeam [ aRnd ].DefaultSpeed - aValue;
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;

    if MyTeam [ aRnd ].DefaultSpeed <= 0 then MyTeam [ aRnd ].DefaultSpeed := 1;
    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    inc (MarkCount);
  end;
  if Level <= 10 then
    goto MyExit;

    //  M: Sui 22 player  a 11 ridotti di -1 tutti i valori ANCHE speed di 1.
    //  F: Sui 22 player  a 5 ridotti di -1 tutti i valori ANCHE speed di 1.
  if fm = 'm' then begin
    aValue := 1;
    MarkCountMax := 11
  end
  else begin
    aValue := 1;
    MarkCountMax := 5;
  end;
  MarkCount := 0;
  while MarkCount < MarkCountMax do begin
    aRnd := RndGenerate0(High(MyTeam));
    MyTeam [ aRnd ].DefaultSpeed := MyTeam [ aRnd ].DefaultSpeed - aValue;
    MyTeam [ aRnd ].DefaultDefense := MyTeam [ aRnd ].DefaultDefense - aValue;
    MyTeam [ aRnd ].DefaultPassing := MyTeam [ aRnd ].DefaultPassing - aValue;
    MyTeam [ aRnd ].DefaultBallControl := MyTeam [ aRnd ].DefaultBallControl - aValue;
    MyTeam [ aRnd ].DefaultShot := MyTeam [ aRnd ].DefaultShot - aValue;
    MyTeam [ aRnd ].DefaultHeading := MyTeam [ aRnd ].DefaultHeading - aValue;

    if MyTeam [ aRnd ].DefaultSpeed <= 0 then MyTeam [ aRnd ].DefaultSpeed := 1;
    if MyTeam [ aRnd ].DefaultDefense <= 0 then MyTeam [ aRnd ].DefaultDefense := 1;
    if MyTeam [ aRnd ].DefaultPassing <= 0 then MyTeam [ aRnd ].DefaultPassing := 1;
    if MyTeam [ aRnd ].DefaultBallControl <= 0 then MyTeam [ aRnd ].DefaultBallControl := 1;
    if MyTeam [ aRnd ].DefaultShot <= 0 then MyTeam [ aRnd ].DefaultShot := 1;
    if MyTeam [ aRnd ].DefaultHeading <= 0 then MyTeam [ aRnd ].DefaultHeading := 1;

    inc (MarkCount);
  end;


MyExit:

  for I := Low(MyTeam) to High(MyTeam) do begin
    LastInsertId := LastInsertId + 1;
    MyTeam[i].Guid := LastInsertId;
    MyTeam[i].GuidTeam := GuidTeam;
    MyTeam[i].country := idCountry;
    MyTeam[i].Stamina := 120;
    MyTeam[i].Surname := CreateSurname ( fm ,idCountry, Tssurnames  );
    MyTeam[i].formation_X := 0;
    MyTeam[i].formation_Y := -1;
    MyTeam[i].injured := 0;
    MyTeam[i].yellowcard := 0;
    MyTeam[i].disqualified := 0;
//    MyTeam[i].onmarket := 0;
    if fm ='f' then
      MyTeam[i].face := rndGenerate ( nFacesF )
    else  MyTeam[i].face := rndGenerate ( nFacesM );

    MyTeam[i].fitness := Rndgenerate0(2); // random
    MyTeam[i].morale := Rndgenerate0(2);

    MyTeam[i].devA := RndGenerate(30);
    MyTeam[i].devT := RndGenerate(30);
    MyTeam[i].devI := RndGenerate(20);

    MyTeam[i].xp := '0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0';
    MyTeam[i].history := '0,0,0,0,0,0';
    MyTeam[i].xpdevA := 0;
    MyTeam[i].xpdevT := 0;
    MyTeam[i].xpdevI := 0;
  end;


  // CopyMemory(ptrDivisionPlayers, @MyTeam[0], 22 * SizeOf(TBasePlayer));

  SaveTeamStream ( fm, IntToStr(GuidTeam), MyTeam, dirSaves );
  Result := LastInsertId;
end;
procedure CodeNamePlayerF( var MyTeam: Array22);
var
  i: Integer;
begin
  for I := Low(MyTeam) to High(MyTeam) do begin

    MyTeam [ i ].DefaultDefense := Ceil (MyTeam [ i ].DefaultDefense / 2);
    MyTeam [ i ].DefaultPassing := Ceil (MyTeam [ i ].DefaultPassing  / 2);
    MyTeam [ i ].DefaultBallControl := Ceil (MyTeam [ i ].DefaultBallControl  / 2);
    MyTeam [ i ].DefaultShot := Ceil (MyTeam [ i ].DefaultShot / 2);
    MyTeam [ i ].DefaultHeading := Ceil (MyTeam [ i ].DefaultHeading  / 2);

    if MyTeam [ i ].DefaultDefense <= 0 then MyTeam [ i ].DefaultDefense := 1;
    if MyTeam [ i ].DefaultPassing <= 0 then MyTeam [ i ].DefaultPassing := 1;
    if MyTeam [ i ].DefaultBallControl <= 0 then MyTeam [ i ].DefaultBallControl := 1;
    if MyTeam [ i ].DefaultShot <= 0 then MyTeam [ i ].DefaultShot := 1;
    if MyTeam [ i ].DefaultHeading <= 0 then MyTeam [ i ].DefaultHeading := 1;

  end;
end;
function CreateCalendars ( idCountry, Season, MyGuidTeam, MyGuidCountry: Integer; MyGuidTeamName, CountryName, dirData, dirSaves, dir_interface: string; var Engine:SE_Engine): string;
var
  OldRank : string;
  i,ii,aRnd: Integer;
  ini: TIniFile;
  tsCal,tsTeams,ts2,tsTHISrank : TStringList;
  aSprite: SE_Sprite;
  label from0to2,skip;

begin
  Result := '';
  // seleziono localmente i team solo di quella nazione idcountry
  tsTeams := TStringList.Create;
  tsTeams.Delimiter:=',';
  tsTeams.StrictDelimiter := True;
  tsTeams.LoadFromFile( dirdata + 'worldteams.csv' );

  ts2 := TStringList.Create ;
  for I := tsTeams.Count -1 downto 0 do begin
    ts2.CommaText := tsTeams[i];             // elimino i team di country diverse
    if ts2[2] <> intTostr (idCountry) then  // guid,name,country,avgrank,uniformh,uniforma
      tsTeams.Delete(i);
  end;

  // Vedo se MyGuidTeam è in questa country
  oldRank := '99';
  if MyGuidCountry <> idCountry then goto skip;
  for I := tsTeams.Count -1 downto 0 do begin
    ts2.CommaText := tsTeams[i];
    if ts2[0] = IntToStr(MyGuidTeam) then begin // guid,name,country,avgrank,uniformh,uniforma
      // elimino il mio team, tanto ce l'ho già in Myguidteam e MyGuidTeamName
      oldRank := ts2[3];
      Result := tsTeams[i];
      tsTeams.Delete(i);

      // vedo il rank se 1,2, o 0 . se 1 metto al suo posto un team avgrank2, poi da avgrank0 ne pongo 1 a avgrank2
      if oldRank = '1' then begin
        for ii := tsTeams.Count -1 downto 0 do begin
          ts2.CommaText := tsTeams[ii];
          if ts2[3]='2' then begin
            ts2[3]:='1'; // aggiungo il rank 1 preso dal rank 2
            tsTeams[ii]:= ts2.CommaText; // lo riassegno
            Break;
          end;
        end;

from0to2:
        // poi da avgrank0 ne pongo 1 a avgrank2
        for ii := tsTeams.Count -1 downto 0 do begin
          ts2.CommaText := tsTeams[ii];
          if ts2[3]='0' then begin
            ts2[3]:='2'; // aggiungo il rank 1 preso dal rank 2
            tsTeams[ii]:= ts2.CommaText; // lo riassegno
            Break;
          end;
        end;

      end
      // se 2 metto al suo posto un team avgrank0
      else if ts2[3]='2' then begin
        goto from0to2;
      end;
      // se 0 non faccio nulla
    end;
    if OldRank <> '99' then Break; // l'ho trovato il mio team ,inutile ciclare ancora
    

  end;

SKIP:
  // campionati a 20 squadre rank 1,2,3.
  // Infine prendo tutte le avgrank 0 rimaste ( devono essere eliminate quelle già prese ) e creo 3 campionati da 16 squadre.

  tsTHISrank := TStringList.Create; // i team del campionato che sto creando
  for I := tsTeams.Count -1 downto 0 do begin
    ts2.CommaText := tsTeams[i];
    if ts2[3] = '1' then begin  // avgrank rank 1
      tsTHISrank.Add( ts2[0]+','+ ts2[1] ); // in THIS guid e name del team  es. 25=barcelona
      if tsTHISrank.count = 20 then Break;
    end;
  end;

  aSprite := Engine.CreateSprite( dir_interface + 'circleon.bmp' , 'circleon1',1,1,1000,(1440 div 2)-(40*2), 720 div 2,true,2000 );
  Engine.Theater.thrdAnimate.OnTimer ( Engine.Theater.thrdAnimate);
  WriteCalendar ( season, idCountry, 1, 20, tsTHISrank, dirData, dirSaves );

  tsTHISrank.Clear;
  for I := tsTeams.Count -1 downto 0 do begin
    ts2.CommaText := tsTeams[i];
    if ts2[3] = '2' then begin  // avgrank rank 2 !!!
      tsTHISrank.Add( ts2[0]+','+ ts2[1] ); // in THIS guid e name del team  es. 25=barcelona
      if tsTHISrank.count = 20 then Break;
    end;
  end;
  aSprite := Engine.CreateSprite( dir_interface + 'circleon.bmp' , 'circleon2',1,1,1000,(1440 div 2)-(40), 720 div 2,true,2000 );
  Engine.Theater.thrdAnimate.OnTimer ( Engine.Theater.thrdAnimate);
  WriteCalendar ( season, idCountry, 2, 20, tsTHISrank, dirData, dirSaves );

  // avgrank rank 0 li prendo random per 3 campionati c,d,e da 16 team. Per ottimizzare elimino i rank 1 e 2
  for I := tsTeams.Count -1 downto 0 do begin
    ts2.CommaText := tsTeams[i];
    if (ts2[3] = '1') or (ts2[3] = '2')  then begin  // avgrank rank 1 e 2
      tsTeams.Delete(i);
    end;
  end;

  tsTHISrank.Clear;
  while tsTHISrank.count < 16 do begin
    aRnd := RndGenerate0( tsTeams.Count -1 );
    ts2.CommaText := tsTeams[aRnd];               // è per forza rank 0
    tsTHISrank.Add(ts2[0]+','+ ts2[1]);  // ne aggiungo fino a 20
    tsTeams.Delete(aRnd);                      // la elimino per non ripescarla
  end;

  aSprite := Engine.CreateSprite( dir_interface + 'circleon.bmp' , 'circleon3',1,1,1000,1440 div 2, 720 div 2,true,2000 );
  Engine.Theater.thrdAnimate.OnTimer ( Engine.Theater.thrdAnimate);
  WriteCalendar ( season, idCountry, 3, 16, tsTHISrank, dirData, dirSaves );

  tsTHISrank.Clear;
  while tsTHISrank.count < 16 do begin
    aRnd := RndGenerate0( tsTeams.Count -1 );
    ts2.CommaText := tsTeams[aRnd];               // è per forza rank 0
    tsTHISrank.Add(ts2[0]+','+ ts2[1]);  // ne aggiungo fino a 20
    tsTeams.Delete(aRnd);                      // la elimino per non ripescarla
  end;
  aSprite  := Engine.CreateSprite( dir_interface + 'circleon.bmp' , 'circleon4',1,1,1000,(1440 div 2)+(40), 720 div 2,true,2000 );
  Engine.Theater.thrdAnimate.OnTimer ( Engine.Theater.thrdAnimate);
  WriteCalendar ( season, idCountry, 4, 16, tsTHISrank, dirData, dirSaves );

  tsTHISrank.Clear;
  while tsTHISrank.count < 15 do begin  // nell'ultimo campionato aggiungiamo il mio team
    aRnd := RndGenerate0( tsTeams.Count -1 );
    ts2.CommaText := tsTeams[aRnd];               // è per forza rank 0
    tsTHISrank.Add(ts2[0]+','+ ts2[1]);  // ne aggiungo fino a 20
    tsTeams.Delete(aRnd);                      // la elimino per non ripescarla
  end;
  //solo se in questa country è presente il mio team
  if OldRank <> '99' then
    tsTHISrank.Add(IntToStr(MyGuidTeam)+','+ MyGuidTeamName)  // ne aggiungo fino a 16
  else begin // aggiungo un normale team avgrank0
    aRnd := RndGenerate0( tsTeams.Count -1 );
    ts2.CommaText := tsTeams[aRnd];               // è per forza rank 0
    tsTHISrank.Add(ts2[0]+','+ ts2[1]);  // ne aggiungo fino a 20
  end;
  aSprite := Engine.CreateSprite( dir_interface + 'circleon.bmp' , 'circleon5',1,1,1000,(1440 div 2)+(40*2), 720 div 2,true,2000 );
  Engine.Theater.thrdAnimate.OnTimer ( Engine.Theater.thrdAnimate);
  WriteCalendar ( season, idCountry, 5,16, tsTHISrank, dirData, dirSaves );

  ts2.Free;
  tsTeams.Free;


  tsTHISrank.Free;

end;
procedure WriteCalendar ( season, idCountry, division, teamCount : Integer; var tsTHISrank: TStringList;  dirData, dirSaves: string );
var
  BaseCal: TextFile;
  Text,GuidTeam0,GuidTeam1,fm : string;
  i,ii,s,x,R,T,m10: Integer;
  ini: TIniFile;
  tsCal : TStringList;
  label dof;

begin
  fm := 'm';
dof:

  AssignFile(BaseCal,  dirData + 'calendar' + IntToStr(TeamCount) +'.txt');
  Reset(BaseCal);


  ini:= TIniFile.Create(dirSaves + fm + 'S' + Format('%.3d', [season]) + 'C' + Format('%.3d', [idCountry]) + 'D' + Format('%.1d', [division] ) + '.ini') ;
  // creo subito i results.
  CreateResultsPreset ( dirSaves + fm + 'C' + Format('%.3d', [idCountry]) + 'D' + Format('%.1d', [division] )  ) ;

  tsCal:= TStringList.Create ;
  R := 1;
  for i:= 1 to TeamCount-1 do begin   // 19 o 15
    ReadLn(BaseCal, text);  // 19. round   lo rimappo io, non è importante quel numero, i miei file partono dal round 1
//      x:= pos ('.', Text, 1);
//      R := LeftStr (Text,x-1);
    T := 1;
    for ii := 1 to (TeamCount div 2) do begin // 20 team =10 16 team=8
      ReadLn(BaseCal, text);
      x:= pos ('-', Text, 1);
      GuidTeam0 := Trim(leftStr(Text,x-1));
      GuidTeam1 := Trim(RightStr(Text, Length(Text) - x ));
      //In fondo scivo la classifica
      ini.WriteString('Standing', IntToStr(T), tsTHISrank[StrToInt(guidteam0)-1] +',0' ); // Alla partenza 0 punti
      Inc(T);
      ini.WriteString('Standing', IntToStr(T), tsTHISrank[StrToInt(guidteam1)-1] +',0' ); // Alla partenza 0 punti
      Inc(T);

      ini.WriteString('Round' + IntToStr(R) , 'match' + IntToStr(ii),  tsTHISrank[StrToInt(guidteam0)-1] + ',' + tsTHISrank[StrToInt(guidteam1)-1] ) ;
      // in tscal entrano in ordine, di 10 in 10  o 8 e 8
      tsCal.add  (tsTHISrank[StrToInt(guidteam1)-1] + '-' + tsTHISrank[StrToInt(guidteam0)-1]); // solo per la gestione del girone di ritorno
    end;
    inc(R);
  end;

  CloseFile(BaseCal);
  // genero il girone di ritorno
  m10:=1;
  for ii := 0 to tsCal.Count -1 do begin
      text := tsCal[ii];
      x:= pos ('-', Text, 1);
      GuidTeam0 := Trim(leftStr(Text,x-1)); // qui userò la ts con valuefrom index es. 25=barcelona
      GuidTeam1 := Trim(RightStr(Text, Length(Text) - x ));
    ini.WriteString('Round' + IntToStr(R) , 'match' + IntToStr(m10),  guidteam0 + ',' + guidteam1 ) ;
    Inc(m10);
    if m10 > (TeamCount div 2) then begin // o 10 o 8
      inc(R);
      m10:=1;
    end;
  end;

  ini.Free;
  TsCal.free;



  if fm = 'm' then begin
    fm:='f';
    goto Dof;
  end;




end;
procedure UpdateCalendar ( aBrain: TsoccerBrain; dirSaves: string );
var
  ini : TIniFile;
  ts2 : Tstringlist;
  M: Integer;

begin
  ini:= TIniFile.Create(dirSaves + aBrain.Gender + 'S' + Format('%.3d', [aBrain.Season]) + 'C' + Format('%.3d', [aBrain.Country]) + 'D' + Format('%.1d', [aBrain.Division] ) + '.ini') ;

  ts2 := Tstringlist.create;
  ts2.StrictDelimiter := True;




  // Scrivo risultato e MatchInfo
  for M := 1 to DivisionMatchCount[aBrain.Division]  do begin
    ts2.commatext := ini.ReadString('round' + IntToStr(aBrain.Round), 'match' + IntToStr(M),''  );
    if (ts2[0] = IntToStr(aBrain.Score.TeamGuid[0])) and (ts2[2] = IntToStr(aBrain.Score.TeamGuid[1])) then begin

      if ts2.Count = 4 then begin // non c'è il risultato
        ini.WriteString('round' + IntToStr(aBrain.Round), 'match' + IntToStr(M),
        ts2.CommaText + ',' + IntToStr(aBrain.Score.gol[0])+'-'+ IntToStr(aBrain.Score.gol[1]) + ','+ aBrain.MatchInfo.CommaText );
        Continue;
      end;

      if ts2.Count > 4 then begin
        ts2[4] := IntToStr(aBrain.Score.gol[0])+'-'+ IntToStr(aBrain.Score.gol[1]) ;
        ini.WriteString('round' + IntToStr(aBrain.Round), 'match' + IntToStr(M), ts2.CommaText);
      end;
      if ts2.Count > 5 then begin
        ts2[5] := aBrain.MatchInfo.CommaText;
        ini.WriteString('round' + IntToStr(aBrain.Round), 'match' + IntToStr(M), ts2.CommaText);
      end
    end;

  end;
  // Le classifiche vengono calcolate in clientloadStandings . Anche la cannonieri viene elaborata al volo
  ini.Free;
end;

procedure CreateTeams ( idCountry, Season, nFacesM,nFacesF : Integer; dirData, dirSaves: string);  // usata solo all'inizio del gioco
var
  tsSurnames,ts2 : TStringList;
  i,D,G,TeamMemoryIndex : Integer;
  ArrayGuidTeams : SE_IntegerList;
  YQ,LastInsertId, GuidTeam, StartMoney: Integer;
  MMTeams, MM : TMemoryStream;
  ini : TIniFile;
  const GenderS = 'fm';
begin

  // seleziono localmente i cognomi solo di quella nazione idcountry
  tsSurnames := TStringList.Create;
  tsSurnames.LoadFromFile( dirdata + 'surnames.csv' );

  ts2 := TStringList.Create ;
  for I := tsSurnames.Count -1 downto 0 do begin
    ts2.CommaText := tsSurnames[i];             // elimino i cognomi di country diverse
    if ts2[2] <> intTostr (idCountry) then  // country,surname
      tsSurnames.Delete(i);
  end;

  ts2.Free;

  // Leggo i calendari mSCD.ini o fSCD.ini per ottenere le GUIDteam e creo i file mXXX.120 e fXXX.120 che contengono i players.
  // qui salvo in memoria MyTeam e poi lo storo in mXXX.120 . Inoltre creo fCDTeams.ini e mCDteams.ini

  ArrayGuidTeams:= SE_IntegerList.Create;  // è dinamico , uso se_recordlist
  LastInsertId := 0;
  YQ := 0;
  for G := 1 to 2 do begin
    MM := TMemoryStream.Create;
    Mm.Size := 0;
    for D := 1 to 5 do begin
      if D <= 2 then begin
        GetMyGuidTeams ( GenderS[G],dirSaves ,idCountry, Season, D, 20, ArrayGuidTeams );
        for I := 0 to ArrayGuidTeams.Count -1 do begin //creo teams.120
          GuidTeam :=ArrayGuidTeams.Items[i];
          StartMoney := RndGenerateRange(MoneyBase[G,D,0],MoneyBase[G,D,1] );
          MM.Write( @GuidTeam ,4 );
          MM.Write( @StartMoney,4 );
          MM.Write( @D,1 );
          MM.Write( @YQ,1 );
        end;

      end
      else begin
        GetMyGuidTeams ( GenderS[G],dirSaves, idCountry, Season, D, 16, ArrayGuidTeams );
        for I := 0 to ArrayGuidTeams.Count -1 do begin //creo teams.120
          GuidTeam :=ArrayGuidTeams.Items[i];
          StartMoney := RndGenerateRange(MoneyBase[G,D,0],MoneyBase[G,D,1] );
          MM.Write( @GuidTeam,4 );
          MM.Write( @StartMoney,4 );
          MM.Write( @D,1 );
          MM.Write( @YQ,1 );
        end;
      end;


      // Qui decido il level
      TeamMemoryIndex := 0;
      for I := 0 to 3 do begin

        LastInsertId := pveCreatePlayers ( GenderS[G], ArrayGuidTeams[TeamMemoryIndex] , Season,idCountry,D, 1+D-1, nFacesM,nFacesF, lastInsertId,tsSurnames,DirSaves);
        inc (TeamMemoryIndex ) ;
      end;
      for I := 0 to 5 do begin

        LastInsertId:= pveCreatePlayers ( GenderS[G], ArrayGuidTeams[TeamMemoryIndex] , Season,idCountry,D, 2+D-1,nFacesM,nFacesF,lastInsertId,tsSurnames,DirSaves);
        inc (TeamMemoryIndex ) ;
      end;
      for I := 0 to 5 do begin

        LastInsertId:= pveCreatePlayers ( GenderS[G], ArrayGuidTeams[TeamMemoryIndex] , Season,idCountry,D, 3+D-1, nFacesM,nFacesF,lastInsertId,tsSurnames,DirSaves);
        inc (TeamMemoryIndex ) ;
      end;
      //se Division 1 e 2 sono 20, faccio qui sotto
      if D <= 2 then begin
        for I := 0 to 3 do begin
          LastInsertId:= pveCreatePlayers ( GenderS[G], ArrayGuidTeams[TeamMemoryIndex] , Season,idCountry,D, 4+D-1,nFacesM,nFacesF, lastInsertId,tsSurnames, DirSaves);
          inc (TeamMemoryIndex ) ;
        end;
      end;

    end;

    // i team sono tutti in un unico file. Qui sto creadno le 5 divisioni ma di una sola country. Devo appendere al file xteams.120
    MMTeams := TMemoryStream.Create;
    if FileExists(dirSaves + GenderS[G] + 'teams.120') then
      MMTeams.LoadFromFile(dirSaves + GenderS[G] + 'teams.120' );

    MMTeams.Position := MMTeams.Size;
    MMTeams.Write ( MM.Memory, MM.size );
    MMTeams.SaveToFile( dirSaves + GenderS[G] + 'teams.120' );
    MMTeams.Free;
    MM.Free;

  end;



  ini := TIniFile.Create ( dirSaves + 'index.ini');
  ini.WriteInteger( 'setup','LastInsertId', LastInsertId ); // servirà alla nascita di nuovi player . è condiviso tra m e f
  ini.Free;
  tsSurnames.Free;

end;
procedure GetMyGuidTeams ( Gender, dirSaves: string; idCountry, Season, D, TeamCount: Integer; var ArrayGuidTeams: SE_IntegerList ) ;
var
  i: Integer;
  ini : Tinifile;
  ts2 : TStringList;
begin

  ArrayGuidTeams.Clear;
  ini:= TIniFile.Create(dirSaves + Gender + 'S' + Format('%.3d', [season]) + 'C' + Format('%.3d', [idCountry]) + 'D' + Format('%.1d', [D] ) + '.ini') ;
  // es. [Round1]
  // match1=560,Wolverhampton Wanderers,572,Norwich City
  ts2 := TStringList.create;

  for I:= 1 to (TeamCount div 2) do begin   // 19 o 15

    ts2.StrictDelimiter := True;
    ts2.CommaText := ini.ReadString( 'Round1','match'+ IntToStr(i),'' );
    ArrayGuidTeams.Add(StrToInt(ts2[0]));
    ArrayGuidTeams.Add(StrToInt(ts2[2]));
  end;

  ts2.Free;
  ini.Free;

end;
procedure SaveTeamStream ( fm :Char; GuidTeam: string; var MyTeam : array22; dirSaves: string );  // come formato è uguale a sotto (overload)
var
  i: Integer;
  MM : TMemoryStream;
  tmps: string[255];
  tmpi: Integer;
  tmpb: Byte;
  Age,face,fitness,morale: integer;
  Country, dev,Xpdev: SmallInt;
begin

  MM := TMemoryStream.Create;
  MM.Size:=0;

  tmpb := 22;
  MM.Write( @tmpb, sizeof(byte) );

  for I := Low(MyTeam) to High(MyTeam) do begin
    tmpi:=  MyTeam[i].guid;
    MM.Write( @tmpi, sizeof(integer) );

    tmps := MyTeam[i].Surname;
    MM.Write( @tmps[0] , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa


    Age:= MyTeam[i].Age;
    MM.Write( @Age, sizeof(byte) );

    tmpb := MyTeam[i].talentid1;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := MyTeam[i].talentid2;
    MM.Write( @tmpb, sizeof(byte) );
    tmpi := MyTeam[i].stamina;
    MM.Write( @tmpi, sizeof(SmallInt) );

    tmpb:=  MyTeam[i].DefaultSpeed;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyTeam[i].DefaultDefense;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyTeam[i].DefaultPassing;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyTeam[i].DefaultBallControl;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyTeam[i].DefaultShot;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyTeam[i].DefaultHeading;
    MM.Write( @tmpb , sizeof(ShortInt) );

    tmpb:= MyTeam[i].formation_X;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyTeam[i].formation_Y;
    MM.Write( @tmpb , sizeof(ShortInt) );


    tmpb := MyTeam[i].injured;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := MyTeam[i].yellowcard;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := MyTeam[i].disqualified;
    MM.Write( @tmpb, sizeof(byte) );
//    tmpb := MyTeam[i].onmarket;
//    MM.Write( @tmpb, sizeof(byte) );

    face:= MyTeam[i].face;
    MM.Write( @face , sizeof(integer) );

    fitness:= MyTeam[i].fitness;
    MM.Write( @fitness , sizeof(byte) );

    morale:= MyTeam[i].morale;
    MM.Write( @morale , sizeof(byte) );

    country:= MyTeam[i].country;
    MM.Write( @country , sizeof(word) );

    dev:= MyTeam[i].DevA;
    MM.Write( @dev , sizeof(word) );
    dev:= MyTeam[i].DevT;
    MM.Write( @dev , sizeof(word) );
    dev:= MyTeam[i].DevI;
    MM.Write( @dev , sizeof(word) );


    tmps := MyTeam[i].history;
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa
    tmps := MyTeam[i].xp;
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    Xpdev:= MyTeam[i].xpDeva;
    MM.Write( @Xpdev , sizeof(word) );
    Xpdev:= MyTeam[i].xpDevT;
    MM.Write( @Xpdev , sizeof(word) );
    Xpdev:= MyTeam[i].xpDevI;
    MM.Write( @Xpdev , sizeof(word) );

  end;

  MM.SaveToFile( dirSaves + fm + GuidTeam + '.120'  );
  MM.Free;
end;
procedure SaveTeamStream ( fm :Char; GuidTeam: string; var lstPlayersDB : TObjectlist<TSoccerPlayer>; dirSaves: string); overload; // come sopra
var
  i: Integer;
  MM : TMemoryStream;
  tmps: string[255];
  tmpi,indexTal: Integer;
  tmpb: Byte;
  Age,face,fitness,morale: integer;
  Country, dev,Xpdev: SmallInt;
  aPlayer: TSoccerPlayer;
begin
// Accede a Brain.LstSoccerAll e sovrascrivo tutto il file

  MM := TMemoryStream.Create;
  MM.Size:=0;

  tmpb := lstPlayersDB.Count;
  MM.Write( @tmpb, sizeof(byte) );

  for I := 0 to lstPlayersDB.Count -1  do begin
    aPlayer := lstPlayersDB[i];

    tmpi:=  StrToInt(aPlayer.Ids) ;
    MM.Write( @tmpi, sizeof(integer) );

    tmps := aPlayer.Surname;
    MM.Write( @tmps[0] , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    Age:= aPlayer.Age;
    MM.Write( @Age, sizeof(byte) );

    tmpb := aPlayer.talentid1;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := aPlayer.talentid2;
    MM.Write( @tmpb, sizeof(byte) );
    tmpi := aPlayer.stamina;
    MM.Write( @tmpi, sizeof(SmallInt) );

    tmpb:=  aPlayer.DefaultSpeed;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.DefaultDefense;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.DefaultPassing;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.DefaultBallControl;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.DefaultShot;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.DefaultHeading;
    MM.Write( @tmpb , sizeof(ShortInt) );

    tmpb:= aPlayer.AIFormationCellX;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.AIFormationCellY;
    MM.Write( @tmpb , sizeof(ShortInt) );


    tmpb := aPlayer.injured;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := aPlayer.yellowcard;
//    if aPlayer.YellowCard > 0 then asm Int 3; end;

    MM.Write( @tmpb, sizeof(byte) );
    tmpb := aPlayer.disqualified;
    MM.Write( @tmpb, sizeof(byte) );
//    tmpb := Integer( aPlayer.onmarket);
//    MM.Write( @tmpb, sizeof(byte) );

    face:= aPlayer.face;
    MM.Write( @face , sizeof(integer) );

    fitness:= aPlayer.fitness;
    MM.Write( @fitness , sizeof(byte) );

    morale:= aPlayer.morale;
    MM.Write( @morale , sizeof(byte) );

    country:= aPlayer.country;
    MM.Write( @country , sizeof(word) );

    dev:= aPlayer.DevA;
    MM.Write( @dev , sizeof(word) );
    dev:= aPlayer.DevT;
    MM.Write( @dev , sizeof(word) );
    dev:= aPlayer.DevI;
    MM.Write( @dev , sizeof(word) );


    tmps := IntToStr(aPlayer.history_Speed) + ',' + IntToStr(aPlayer.history_Defense) + ',' + IntToStr(aPlayer.history_Passing) + ',' +
    IntToStr(aPlayer.history_BallControl) + ',' + IntToStr(aPlayer.history_Shot) + ',' + IntToStr(aPlayer.history_Heading);
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    tmps := IntToStr(aPlayer.xp_Speed) + ',' + IntToStr(aPlayer.xp_Defense) + ',' + IntToStr(aPlayer.xp_Passing) + ',' +
    IntToStr(aPlayer.xp_BallControl) + ',' + IntToStr(aPlayer.xp_Shot) + ',' + IntToStr(aPlayer.xp_Heading);// +',';
    for indexTal := 1 to NUM_TALENT do begin // f_game.talents
      tmps := tmps + ',' + IntToStr(aPlayer.xpTal[indexTal]);// + ',';
    end;
   // tmps := LeftStr( tmps, Length(tmps)-1); // elimino l'ultima virgola
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa


    Xpdev:= aPlayer.xpDeva;
    MM.Write( @Xpdev , sizeof(word) );
    Xpdev:= aPlayer.xpDevT;
    MM.Write( @Xpdev , sizeof(word) );
    Xpdev:= aPlayer.xpDevI;
    MM.Write( @Xpdev , sizeof(word) );

  end;

  MM.SaveToFile( dirSaves + fm + GuidTeam + '.120'  );
  MM.Free;

end;
procedure WriteTeamFormation ( fm :Char; GuidTeam, dirSaves, aCommaText: string );
var
  i,y: Integer;
  MM : TMemoryStream;
  tmps: string[255];
  Age,morale,cur,count,lenSurname,IndexTal: integer;
  ts2,tscells : TStringList;
  SS :TStringStream;
  datastr : string;
  Buf3 : TArray8192;
  LenHistory,LenXP: Integer;
  tsXP, tsHistory : TStringList;
  aPlayer: TSoccerPlayer;
  lstPlayersDB : TObjectlist<TSoccerPlayer>;
begin
// Carico in memoria il file .120 (TUTTO, quindi come saveteamstream ) in un MyTeam il file, cambio le celle, salvo di nuovo

  ts2 := TStringList.Create;
  ts2.StrictDelimiter := True;
  ts2.CommaText := aCommaText;

  tscells:= TStringList.Create ;
  tscells.StrictDelimiter := True;
  tscells.Delimiter := ':';

  MM := TMemoryStream.Create;
  MM.Size:=0;
  MM.LoadFromFile( dirSaves  + fm + GuidTeam + '.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  lstPlayersDB := TObjectlist<TSoccerPlayer>.Create(True);
      // uguale a ClientLoadFormation ma senza grafica
  count := ord (buf3 [ cur ]);   // quanti player
  Cur := Cur + 1; //
  for I := 0 to Count -1 do begin
    aPlayer:= TSoccerPlayer.create(0, StrToInt(GuidTeam),0,'','','','',0,0);


    aPlayer.Ids :=  IntToStr(PDWORD(@buf3 [ cur ])^); // player identificativo globale
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3 [ cur ]);
    aPlayer.Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;

    aPlayer.Age :=  Ord( buf3 [ cur ]);
    Cur := Cur + 1 ;

    aPlayer.TalentID1 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;
    aPlayer.TalentID2 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aPlayer.Stamina := PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    aPlayer.DefaultSpeed := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultDefense := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultPassing := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultBallControl := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultShot := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultHeading := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aPlayer.AIFormationCellX := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.AIFormationCellX := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    // CHANGE CELLS ---------------------
    for y := 0 to ts2.Count -1 do begin
      if ts2.Names[y] = aPlayer.ids then begin            // es. 3609=0:-1,3610=3:11,3611=4:6,
        tscells.delimitedText := ts2.ValueFromIndex[y]; // già diviso da 2 punti :
        aPlayer.AIFormationCellX := StrToInt(tscells[0]);
        aPlayer.AIFormationCellY := StrToInt(tscells[1]);
        Break;
      end;
    end;

    // CHANGE CELLS ---------------------

    aPlayer.injured := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.yellowcard := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.disqualified := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
//    aPlayer.onmarket := Ord( buf3 [ cur ]);
//    Cur := Cur + 1;
    aPlayer.face :=  PDWORD(@buf3 [ cur ])^; // face bmp viso
    Cur := Cur + 4;
    aPlayer.fitness:= Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.morale:=Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.country:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;


    aPlayer.devA:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    aPlayer.devT:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    aPlayer.devI:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    // Qui devo leggere e salvare tutto, ance XP , quindi mi comporto come clientloadformation
    tsHistory := TStringList.Create;
    LenHistory :=  Ord( buf3 [ cur ]);
    tsHistory.commaText := MidStr( dataStr, cur + 2  , LenHistory );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + LenHistory + 1;
//      tsHistory.commaText := ini.readString('player' + IntToStr(i),'History','0,0,0,0,0,0' ); // <-- 6 attributes

//OutputDebugString(PChar( 'T:'+ Inttostr (Guidteam )+'  ts:' + tsHistory.commatext));
    aPlayer.History_Speed         := StrToInt( tsHistory[0]);
    aPlayer.History_Defense       := StrToInt( tsHistory[1]);
    aPlayer.History_Passing       := StrToInt( tsHistory[2]);
    aPlayer.History_BallControl   := StrToInt( tsHistory[3]);
    aPlayer.History_Shot          := StrToInt( tsHistory[4]);
    aPlayer.History_Heading       := StrToInt( tsHistory[5]);
    tsHistory.Free;

    tsXP := TStringList.Create;
    LenXP :=  Ord( buf3 [ cur ]);
//     tsXP.commaText := ini.readString('player' + IntToStr(i),'xp','0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0' ); // <-- 6 attributes , 17 talenti
    tsXP.commaText := MidStr( dataStr, cur + 2  , LenXP );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + LenXP + 1;

    // rispettare esatto ordine dei talenti sul db
    aPlayer.xp_Speed         := StrToInt( tsXP[0]);
    aPlayer.xp_Defense       := StrToInt( tsXP[1]);
    aPlayer.xp_Passing       := StrToInt( tsXP[2]);
    aPlayer.xp_BallControl   := StrToInt( tsXP[3]);
    aPlayer.xp_Shot          := StrToInt( tsXP[4]);
    aPlayer.xp_Heading       := StrToInt( tsXP[5]);

    for IndexTal := 1 to NUM_TALENT do begin
      aPlayer.xpTal[IndexTal]:= StrToInt( tsXP[IndexTal+5])
    end;

    tsXP.Free;

    aPlayer.xpDevA:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    aPlayer.xpDevT:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    aPlayer.xpDevI:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    lstPlayersDB.Add(aPlayer);
  end;

  tscells.Free;
  ts2.Free;


  SaveTeamStream( fm , GuidTeam, lstPlayersDB , dirSaves );
  //MM.SaveToFile( filename );
  MM.Free;
  lstPlayersDB.Free;

end;



{
procedure TForm1.PveSavePlayers;    // come formato deve essere uguale a utilities.SaveTeamStream
var
  tmpi,i,indexTal: Integer;
  MM: TMemoryStream;
  aPlayer : TSoccerPlayer;
  tmps: string[255];
  tmpb : Byte;
  Age : Integer;
  country,xpdev: Word;
  face,fitness,morale: integer;

begin
  MM := TMemoryStream.Create;
  tmpi:= MyBrainFormation.lstSoccerPlayerALL.count;
  MM.Write( @tmpi , SizeOf(Byte) ) ;

  for I := MyBrainFormation.lstSoccerPlayerALL.count -1 downto 0  do begin
    aPlayer := MyBrainFormation.lstSoccerPlayerALL[i];
    tmpi:= StrToInt( aPlayer.Ids );
    MM.Write( @tmpi, sizeof(integer) );

    tmps := aPlayer.surname;
    MM.Write( @tmps[0] , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    Age:= aPlayer.Age;
    MM.Write( @Age, sizeof(byte) );

    tmpb := aPlayer.talentid1;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := aPlayer.talentid2;
    MM.Write( @tmpb, sizeof(byte) );
    tmpi := aPlayer.stamina;
    MM.Write( @tmpi, sizeof(SmallInt) );

    tmpb:= aPlayer.speed;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.defense;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.passing;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.ballcontrol;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.shot;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.heading;
    MM.Write( @tmpb , sizeof(ShortInt) );

    tmpb:= aPlayer.AIFormationCellX;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= aPlayer.AIFormationCellY;
    MM.Write( @tmpb , sizeof(ShortInt) );

    tmpb := aPlayer.injured;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := aPlayer.yellowcard;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := aPlayer.disqualified;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := Integer (aPlayer.onmarket) ;
    MM.Write( @tmpb, sizeof(byte) );

    face:= aPlayer.face;
    MM.Write( @face , sizeof(integer) );

    fitness:= aPlayer.fitness;
    MM.Write( @fitness , sizeof(byte) );

    morale:= aPlayer.morale;
    MM.Write( @morale , sizeof(byte) );

    country:= aPlayer.country;
    MM.Write( @country , sizeof(word) );

    tmpi := aPlayer.devA;
    MM.Write( @tmpi , sizeof(word) );
    tmpi := aPlayer.devT;
    MM.Write( @tmpi , sizeof(word) );
    tmpi := aPlayer.devI;
    MM.Write( @tmpi , sizeof(word) );

    tmps := IntTostr(aPlayer.history_Speed) + ',' + IntTostr(aPlayer.history_Defense) + ',' +IntTostr(aPlayer.history_Passing) +
            IntToStr(aPlayer.history_BallControl) + ',' + IntToStr(aPlayer.history_Shot) + ',' + IntToStr(aPlayer.history_Heading);
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    tmps := IntToStr(aPlayer.xp_Speed) + ',' + IntToStr(aPlayer.xp_Defense) + ',' + IntToStr(aPlayer.xp_Passing) + ',' +
            IntToStr(aPlayer.xp_BallControl) + ',' + IntToStr(aPlayer.xp_Shot) + ',' + IntToStr(aPlayer.xp_Heading);

    for indexTal := 1 to NUM_TALENT do begin
      tmps := tmps + ',' + IntToStr( aPlayer.xpTal[indexTal]);
    end;
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    xpdev:= aPlayer.xpdevA;
    MM.Write( @xpdev , sizeof(word) );
    xpdev:= aPlayer.xpdevT;
    MM.Write( @xpdev , sizeof(word) );
    xpdev:= aPlayer.xpdevI;
    MM.Write( @xpdev , sizeof(word) );

  end;

  MM.SaveToFile( dir_Saves + MyActiveGender + IntToStr(MyGuidTeam) + '.120'  );
  MM.Free;

end;
}
function CreateSurname ( fm :Char; idCountry: Integer; tsSurnames:TStringList ): string;
var
  ts2: TStringList;
  tmp: string;
begin
  ts2:= TStringList.create;
  ts2.CommaText := tsSurnames[ RndGenerate0(tsSurnames.Count-1)];
  tmp := ts2[1];
  ts2.Free;

  if (idCountry =6) and (fm ='f') then begin // solo russia cognomi femminili / maschili

    // La maggior parte dei cognomi russi cambia al femminile con l'aggiunta della lettera "-a" (Ivanova, Sorokina);
    // si modificano in -skaja nel caso di terminazione in -skij (Moskovskaja) mentre rimangono invariati in caso di finale in "-ich" e "-ko".
    if RightStr(tmp,4)= 'skij' then begin
      tmp := LeftStr ( tmp, Length(tmp)-4);
      tmp := tmp + 'skaja';
      Result := tmp;
    end
    else if RightStr(tmp,3)= 'ich' then begin
      Result := tmp;
    end
    else if RightStr(tmp,2)= 'ko' then begin
      Result := tmp;
    end
    else begin
      Result := tmp + 'a';
    end;

  end
  else Result :=  tmp;

end;
procedure CreateResultsPreset ( filename: string); // crea i file dei result , il proprio country e division non sarà utilizzato
var                                                // nel caso di divisioni a 8 partite, attingerà comunque da quei file e ne rimarranno .non succede nulla
  MMW,MMN,MML : TMemoryStream;
  g0:Byte;
  g1:Byte;
  i: Integer;
begin
  // win - null - lost (win away)
  MMW := TMemoryStream.Create;
  MMN := TMemoryStream.Create;
  MML := TMemoryStream.Create;

  g0 := 1;
  g1 := 0;
  for I := 34 downto 0 do begin
    MMW.Write(@g0,1);
    MMW.Write(@g1,1);
  end;

  g0 := 2;
  g1 := 1;
  for I := 38 downto 0 do begin
    MMW.Write(@g0,1);
    MMW.Write(@g1,1);
  end;

  g0 := 2;
  g1 := 0;
  for I := 27 downto 0 do begin
    MMW.Write(@g0,1);
    MMW.Write(@g1,1);
  end;


  g0 := 3;
  g1 := 1;
  for I := 12 downto 0 do begin
    MMW.Write(@g0,1);
    MMW.Write(@g1,1);
  end;

  g0 := 3;
  g1 := 0;
  for I := 17 downto 0 do begin
    MMW.Write(@g0,1);
    MMW.Write(@g1,1);
  end;

  g0 := 4;
  g1 := 0;
  for I := 4 downto 0 do begin
    MMW.Write(@g0,1);
    MMW.Write(@g1,1);
  end;

  g0 := 4;
  g1 := 1;
  for I := 9 downto 0 do begin
    MMW.Write(@g0,1);
    MMW.Write(@g1,1);
  end;

  g0 := 4; // 1 solo
  g1 := 3;
  MMW.Write(@g0,1);
  MMW.Write(@g1,1);

  g0 := 4; // 1 solo
  g1 := 2;
  MMW.Write(@g0,1);
  MMW.Write(@g1,1);

  g0 := 6; // 1 solo
  g1 := 1;
  MMW.Write(@g0,1);
  MMW.Write(@g1,1);

  g0 := 5; // 1 solo
  g1 := 0;
  MMW.Write(@g0,1);
  MMW.Write(@g1,1);

  g0 := 5; // 1 solo
  g1 := 1;
  MMW.Write(@g0,1);
  MMW.Write(@g1,1);

  g0 := 5; // 1 solo
  g1 := 3;
  MMW.Write(@g0,1);
  MMW.Write(@g1,1);

  g0 := 3;
  g1 := 2;
  for I := 11 downto 0 do begin
    MMW.Write(@g0,1);
    MMW.Write(@g1,1);
  end;


  MMW.SaveToFile( filename + 'w.120');
   // 38*10 - 30*8   = tolgo 148 partite a caso

  g0 := 1;
  g1 := 1;
  for I := 43 downto 0 do begin
    MMN.Write(@g0,1);
    MMN.Write(@g1,1);
  end;

  g0 := 0;
  g1 := 0;
  for I := 33 downto 0 do begin
    MMN.Write(@g0,1);
    MMN.Write(@g1,1);
  end;

  g0 := 2;
  g1 := 2;
  for I := 19 downto 0 do begin
    MMN.Write(@g0,1);
    MMN.Write(@g1,1);
  end;

  g0 := 3;
  g1 := 3;
  for I := 9 downto 0 do begin
    MMN.Write(@g0,1);
    MMN.Write(@g1,1);
  end;

  MMN.SaveToFile( filename  + 'n.120');

  g0 := 2;
  g1 := 3;
  for I := 5 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 0;
  g1 := 2;
  for I := 14 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 0;
  g1 := 3;
  for I := 7 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 0;
  g1 := 1;
  for I := 26 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 0;
  g1 := 4;
  for I := 3 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 1;
  g1 := 4;
  for I := 3 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 2;
  g1 := 4;
  for I := 1 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 1;
  g1 := 3;
  for I := 9 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 1;
  g1 := 2;
  for I := 23 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 0;
  g1 := 5;
  for I := 1 downto 0 do begin
    MML.Write(@g0,1);
    MML.Write(@g1,1);
  end;

  g0 := 3;
  g1 := 5;
  MML.Write(@g0,1);
  MML.Write(@g1,1);

  g0 := 1;
  g1 := 5;
  MML.Write(@g0,1);
  MML.Write(@g1,1);

  g0 := 3;
  g1 := 4;
  MML.Write(@g0,1);
  MML.Write(@g1,1);

  g0 := 2;
  g1 := 6;
  MML.Write(@g0,1);
  MML.Write(@g1,1);

  MML.SaveToFile( filename  + 'l.120');

  MMW.Free;
  MMN.free;
  MML.free;

end;

procedure CreateFormationsPreset;
var
  aF: TFormation;

begin
//  5-4-1   2 formazioni

  aF.d := 5; af.m:=4; aF.f:=1;

  af.cells[2]:= Point (0,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);
  af.cells[6]:= Point (6,9);

  af.cells[7]:= Point (0,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (4,6);
  af.cells[10]:= Point (6,6);

  af.cells[11]:= Point (3,3);

  FormationsPreset.add(af);

  aF.d := 5; af.m:=4; aF.f:=1;

  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);
  af.cells[6]:= Point (5,9);

  af.cells[7]:= Point (0,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (4,6);
  af.cells[10]:= Point (6,6);

  af.cells[11]:= Point (3,3);
  FormationsPreset.add(af);

//  5-3-2   2 formazioni

  aF.d := 5; af.m:=3; aF.f:=2;
  af.cells[2]:= Point (0,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);
  af.cells[6]:= Point (6,9);

  af.cells[7]:= Point (1,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (5,6);

  af.cells[10]:= Point (2,3);
  af.cells[11]:= Point (4,3);
  FormationsPreset.add(af);

  aF.d := 5; af.m:=3; aF.f:=2;
  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);
  af.cells[6]:= Point (5,9);

  af.cells[7]:= Point (1,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (5,6);

  af.cells[10]:= Point (2,3);
  af.cells[11]:= Point (4,3);

  FormationsPreset.add(af);

//  4-4-2   3 formazioni

  aF.d := 4; af.m:=4; aF.f:=2;
  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);

  af.cells[6]:= Point (4,6);
  af.cells[7]:= Point (1,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (5,6);

  af.cells[10]:= Point (2,3);
  af.cells[11]:= Point (4,3);

  FormationsPreset.add(af);

  aF.d := 4; af.m:=4; aF.f:=2;
  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);

  af.cells[6]:= Point (4,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (5,6);

  af.cells[10]:= Point (2,3);
  af.cells[11]:= Point (4,3);

  FormationsPreset.add(af);

  aF.d := 4; af.m:=4; aF.f:=2;
  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);

  af.cells[6]:= Point (0,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (6,6);

  af.cells[10]:= Point (1,3);
  af.cells[11]:= Point (5,3);

  FormationsPreset.add(af);

//  4-3-3   3 formazioni

  aF.d := 4; af.m:=3; aF.f:=3;
  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);

  af.cells[6]:= Point (0,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);

  af.cells[9]:= Point (3,3);
  af.cells[10]:= Point (1,3);
  af.cells[11]:= Point (5,3);

  FormationsPreset.add(af);

  aF.d := 4; af.m:=3; aF.f:=3;
  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);

  af.cells[6]:= Point (4,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);

  af.cells[9]:= Point (3,3);
  af.cells[10]:= Point (0,3);
  af.cells[11]:= Point (6,3);

  FormationsPreset.add(af);

  aF.d := 4; af.m:=3; aF.f:=3;
  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);

  af.cells[6]:= Point (4,6);
  af.cells[7]:= Point (5,6);
  af.cells[8]:= Point (3,6);

  af.cells[9]:= Point (3,3);
  af.cells[10]:= Point (0,3);
  af.cells[11]:= Point (6,3);

  FormationsPreset.add(af);

//  3-4-3   2 formazioni

  aF.d := 3; af.m:=4; aF.f:=3;
  af.cells[2]:= Point (4,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);

  af.cells[5]:= Point (0,6);
  af.cells[6]:= Point (6,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);

  af.cells[9]:= Point (3,3);
  af.cells[10]:= Point (0,3);
  af.cells[11]:= Point (6,3);

  FormationsPreset.add(af);

  aF.d := 3; af.m:=4; aF.f:=3;
  af.cells[2]:= Point (4,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);

  af.cells[5]:= Point (0,6);
  af.cells[6]:= Point (5,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);

  af.cells[9]:= Point (3,3);
  af.cells[10]:= Point (1,3);
  af.cells[11]:= Point (5,3);

  FormationsPreset.add(af);

//  3-5-2   3 formazioni

  aF.d := 3; af.m:=5; aF.f:=2;
  af.cells[2]:= Point (4,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);

  af.cells[5]:= Point (0,6);
  af.cells[6]:= Point (6,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (4,6);

  af.cells[10]:= Point (0,3);
  af.cells[11]:= Point (6,3);

  FormationsPreset.add(af);

  aF.d := 3; af.m:=5; aF.f:=2;
  af.cells[2]:= Point (4,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);

  af.cells[5]:= Point (0,6);
  af.cells[6]:= Point (6,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (4,6);

  af.cells[10]:= Point (2,3);
  af.cells[11]:= Point (4,3);

  FormationsPreset.add(af);

  aF.d := 3; af.m:=5; aF.f:=2;
  af.cells[2]:= Point (4,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);

  af.cells[5]:= Point (0,6);
  af.cells[6]:= Point (6,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6);
  af.cells[9]:= Point (4,6);

  af.cells[10]:= Point (3,3);
  af.cells[11]:= Point (4,3);

  FormationsPreset.add(af);

end;

function pvpCreateFormationTeam ( DbServer: string; fm : Char; Guidteam: integer; formation : string = '' ): string;  // uguale a pve ma diversa sopra
var
  i,T,ii, pcount,D,M,F: Integer;
  ini : TInifile;
  aPlayer,aGK: TSoccerPlayer;
  lstPlayers,lstPlayersDB: TObjectList<TSoccerPlayer>;
  FinalFormation : array[1..11] of TFinalFormation;
  lstGK: TObjectList<TSoccerPlayer>;
  AT: string;
  aF: TFormation;
  ts : TStringList;
  ReserveSlot : TTheArray;
  aReserveSlot: Integer;
  found: Boolean;
  OldfinalFormation: string;
  ConnGame :  TMyConnection;
  qPlayers :  TMyQuery;
  AIFormation_x,AIFormation_y: ShortInt;
  FC: TFormationCell;
  TvCell,TvReserveCell: TPoint;

  label nextplayer,NoFormation,MyExit;

begin
  Result := '';
  CleanReserveSlot ( ReserveSlot );
  (* la stora nel db *)

    ConnGame := TMyConnection.Create(nil);
    Conngame.Server := DbServer;
    Conngame.Username:='root';
    Conngame.Password:='root';
    Conngame.Database:=fm + '_game';
    Conngame.Connected := True;

    qPlayers := TMyQuery.Create(nil);
    qPlayers.Connection := ConnGame;   // game
    qPlayers.SQL.Text :=  'SELECT * from ' +fm + '_game.players WHERE team =' + IntToStr(GuidTeam)+' and young =0';
    qPlayers.Execute;


    // azzero tutto
  //  qPlayers.SQL.text := 'UPDATE f_game.players set formation_x = 0, formation_Y = 0 WHERE team =' + IntToStr(GuidTeam);
  //  qPlayers.Execute ;



    lstPlayers:= TObjectList<TSoccerPlayer>.Create(false); // lista locale
    lstPlayersDB:= TObjectList<TSoccerPlayer>.Create(true); // lista locale  che elimina tutti gli oggetti
    for I := 0 to qPlayers.RecordCount -1 do begin

  //    if qPlayers.FieldByName ( 'disqualified').AsInteger > 0 then goto NoFormation;
  //    if qPlayers.FieldByName ( 'injured').AsInteger > 0 then goto NoFormation;

        AT := qPlayers.FieldByName('speed').Asstring + ',' + qPlayers.FieldByName('defense').Asstring +
              ',' + qPlayers.FieldByName('passing').Asstring + ',' + qPlayers.FieldByName('ballcontrol').Asstring  +
              ',' + qPlayers.FieldByName('shot').Asstring + ',' + qPlayers.FieldByName('heading').Asstring;


      aPlayer := TSoccerPlayer.create(0,0,0,qPlayers.FieldByName ( 'guid').AsString,'','',AT,
                                     qPlayers.FieldByName('talentid1').AsInteger,qPlayers.FieldByName('talentid2').AsInteger);//0,0,0 non hanno importanza qui
      aPlayer.disqualified :=  qPlayers.FieldByName ( 'disqualified').AsInteger;
      aPlayer.Injured :=  qPlayers.FieldByName ( 'injured').AsInteger;
      if aPlayer.Injured > 0 then  begin
        aPlayer.Stamina:=0;
        aPlayer.Speed:=1;
        aPlayer.Defense:=1;
        aPlayer.Passing:=1;
        aPlayer.Ballcontrol:=1;
        aPlayer.Shot:=1;
        aPlayer.Heading:=1;
      end
      else aPlayer.Stamina := qPlayers.FieldByName ( 'stamina').AsInteger;



      lstPlayers.add ( aPlayer);
      lstPlayersDB.add ( aPlayer);
      aPlayer.AIFormationCellX :=  i;   // azzero tutto
      aPlayer.AIFormationCellY :=  -1;


      qPlayers.next;
    end;

    qPlayers.free;
    Conngame.Connected:= False;
    Conngame.Free;


  // lstPlayers contiene il db ma non squalificati o infortunati
  // FinalFormation i dati finali da storare nel db

  // Metto il portiere. il portiere è sempre presente. non può essere venduto se solo 1. viene generato un giovane gk se manca dalla rosa perchè
  // il gk originale raggiunge una certa età

  // storo tutto nel db
    ts := TStringList.Create;
    ts.Add('setformation');

    lstGK:= TObjectList<TSoccerPlayer>.Create(false);
    for I := 0 to lstPlayers.Count -1 do begin
      if lstPlayers[i].TalentId1 = TALENT_ID_GOALKEEPER then begin
        aGK:= lstPlayers[i];
        lstGk.Add (aGK);
      end;
    end;

    if lstGK.Count <= 0 then begin
      lstGK.Free;
      goto MyExit;
    end;

    lstGK.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.defense - L.defense;
    end
    ));

    FinalFormation [1].Guid := lstGK[0].Ids;
    FinalFormation [1].cells := Point ( 3, 11 );
    FinalFormation [1].Stamina := lstGK[0].Stamina ;
    FinalFormation [1].role := 'G' ;
    Ts.Add(  FinalFormation [1].Guid  + '=3:11' );

    // a questo punto devo eliminare un giocatore goalkeeper tra i presenti.
    for I := lstPlayers.Count -1 downto 0 do begin
    // gli altri GK sono per forza tutti panchinari
      if (lstPlayers[i].TalentId1 = TALENT_ID_GOALKEEPER )  then begin
        lstPlayers.Delete(i);  // elimino il gk regolare e anche gli altri GK. lstPlayerDB li rimette in panchina
      end;
    end;

    lstGK.Free;

 //  elimino da lstPlayers i disqialified  , gli injured hanno stamina 0 . li elimino comunque qui
    for I := lstPlayers.Count -1 downto 0 do begin
      if (lstPlayers[i].disqualified > 0) or (lstPlayers[i].injured > 0) then begin
        lstPlayers.Delete(i);
      end;
    end;


  // prendo una formazione da una lista di preset
  // DIF - MID - FOR
    pcount := 2; // dopo il gk
    af:= FormationsPreset[ RndGenerate0( FormationsPreset.Count -1 )];
    if formation <> '' then begin
      aF.d := StrToInt(formation[1]);
      aF.m := StrToInt(formation[2]);
      aF.f := StrToInt(formation[3]);
      for I := 0 to FormationsPreset.Count -1 do begin  // devo caricare delle celle valide
        if (FormationsPreset[i].d = aF.d) and (FormationsPreset[i].m = aF.m) and (FormationsPreset[i].f = aF.f)  then  begin
          af := FormationsPreset[i];
          Break;
        end;
      end;
    end;

    lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.defense - L.defense;
    end
    ));


    // ordino prima in base al talento buff, poi in base al best defense, passing,shot
    for I :=  0 to lstPlayers.Count -1  do begin
      if lstPlayers[I].TalentId2 = TALENT_ID_BUFF_DEFENSE then begin
        if i > 0 then begin
          lstPlayers.Exchange( i, 0 );
          Break;
        end;
      end;

    end;

    for D := 1 to aF.D do begin
      if lstPlayers.Count > 0 then begin
        FinalFormation [pcount].Guid := lstPlayers[0].ids;
        FinalFormation [pcount].cells := Point ( aF.Cells[pcount].X , aF.Cells[pcount].Y );
        FinalFormation [pcount].Stamina := lstPlayers[0].Stamina ;
        FinalFormation [pcount].role := 'D' ;
        Ts.Add( lstPlayers[0].ids  + '=' + IntToStr(aF.Cells[pcount].X) + ':' + IntToStr(aF.Cells[pcount].Y ));
        lstPlayers.Delete(0);  // elimino il Difensore D dalla lista
        Inc(pcount);
      end;
    end;


    lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.passing - L.passing;
    end
    ));

    // ordino prima in base al talento buff, poi in base al best defense, passing,shot
    for I :=  0 to lstPlayers.Count -1  do begin
      if lstPlayers[I].TalentId2 = TALENT_ID_BUFF_MIDDLE then begin
        if i > 0 then begin
          lstPlayers.Exchange( i, 0 );
          Break;
        end;
      end;

    end;

    for M := 1 to aF.M do begin
      if lstPlayers.Count > 0 then begin
        FinalFormation [pcount].Guid := lstPlayers[0].ids;
        FinalFormation [pcount].cells := Point ( aF.Cells[pcount].X , aF.Cells[pcount].Y );
        FinalFormation [pcount].Stamina := lstPlayers[0].Stamina ;
        FinalFormation [pcount].role := 'M' ;
        Ts.Add( lstPlayers[0].ids  + '=' + IntToStr(aF.Cells[pcount].X) + ':' + IntToStr(aF.Cells[pcount].Y ));
        lstPlayers.Delete(0);  // elimino il Centrocampista M dalla lista
        Inc(pcount);
      end;
    end;

    lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.shot - L.shot;
     // Result := R.heading - L.heading;
    end
    ));

    // ordino prima in base al talento buff, poi in base al best defense, passing,shot
    for I :=  0 to lstPlayers.Count -1  do begin
      if lstPlayers[I].TalentId2 = TALENT_ID_BUFF_FORWARD then begin
        if i > 0 then begin
          lstPlayers.Exchange( i, 0 );
          Break;
        end;
      end;

    end;

    for F := 1 to aF.F do begin
      if lstPlayers.Count > 0 then begin
        FinalFormation [pcount].Guid := lstPlayers[0].ids;
        FinalFormation [pcount].cells := Point ( aF.Cells[pcount].X , aF.Cells[pcount].Y );
        FinalFormation [pcount].Stamina := lstPlayers[0].Stamina ;
        FinalFormation [pcount].role := 'F' ;
        Ts.Add( lstPlayers[0].ids  + '=' + IntToStr(aF.Cells[pcount].X) + ':' + IntToStr(aF.Cells[pcount].Y ));
        lstPlayers.Delete(0);  // elimino l'attccante F dalla lista
        Inc(pcount);
      end;
    end;

  // poi elimino quelli con stamina bassa 60. provo a sostituirli con stamina > 60.
  // mi sono rimasti i player nella lstPlayers, li ordino in base al ruolo da ricoprire

  // elimino a priori dai possibili sostituti
    for I := lstPlayers.Count -1 downto 0 do begin
      if lstPlayers[i].Stamina <= 60 then
        lstPlayers.Delete(i);
    end;


    for I := 2 to 11 do begin
      if lstPlayers.Count > 0 then begin
        if FinalFormation [i].Stamina <= 60 then begin

          if FinalFormation [i].Role = 'D' then begin
            lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
            function (const L, R: TSoccerPlayer): integer
            begin
              Result := R.defense - L.defense;
            end
            ));
          end
          else if FinalFormation [i].Role = 'M' then begin
            lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
            function (const L, R: TSoccerPlayer): integer
            begin
              Result := R.passing - L.passing;
            end
            ));
          end
          else if FinalFormation [i].Role = 'F' then begin
            lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
            function (const L, R: TSoccerPlayer): integer
            begin
              Result := R.shot - L.shot;
             // Result := R.heading - L.heading;
            end
            ));
          end;
          // qui è quello ordinato in base a difesa, passaggio o tiro e quello che entra non può avere stamina bassa -60 (rimossi sopra)

          // modifico la finalformation
          OldfinalFormation := FinalFormation [i].Guid;
          FinalFormation [i].Guid := lstPlayers[0].ids;
          FinalFormation [i].Stamina := lstPlayers[0].Stamina ;
          // modifico la TS
          for T := 0 to ts.Count -1 do begin
            if ts.Names[T] = OldfinalFormation then begin
              Ts[T]:= FinalFormation [i].Guid + '=' + IntToStr(FinalFormation[i].Cells.X  ) + ':' + IntToStr(FinalFormation[i].Cells.Y );
              Break;
            end;
          end;
          lstPlayers.Delete(0);  // elimino il player dalla lista

        end;

      end;

    end;

    // qui gli 11 titolari sono schierati correttamente. devo aggiungere a ts le riserve ovvero tutti coloro che sono player ma non in ts.commatext
    // creo la TS con gli 11 titolari di finalformation


    for I := lstPlayersDB.Count -1 downto 0 do begin  //  lstPlayersDB contiene tutti dal db
      // tutti gli ids che non sono presenti in FinalFormation vanno in panchina
      found := False;

      for ii := 1 to 11 do begin
        if FinalFormation [ii].Guid = lstPlayersDB[i].Ids  then begin // è presente nei 11 titolari
          found := True;
          Break;
        end;
      end;

      if not found then begin   // se nopn è prsente nei 11 titolati lo metto in panchina e lo aggiungo in coda alla ts
        aReserveSlot := NextReserveSlot ( ReserveSlot );
        ReserveSlot [aReserveSlot] :=  lstPlayersDB[i].Ids;
        lstPlayersDB[i].AIFormationCellX := aReserveSlot;
        lstPlayersDB[i].AIFormationCellY := -1; // fisso -1

        Ts.Add( lstPlayersDB[i].ids  + '=' +
        IntToStr(lstPlayersDB[i].AIFormationCellX  ) + ':' +
        IntToStr(lstPlayersDB[i].AIFormationCellY ));
      end;

    end;

    Result := Ts.CommaText ; // formazione + riserve
Myexit:
    lstPlayers.Free;
    lstPlayersDB.Free;
    ts.Free;
    { si può giocare anche in meno di 7 giocatori }
end;
function pveCreateFormationTeam (filename: string; fm : Char; Guidteam: integer ; ForceYoung: Boolean; formation : string = ''): string;
var
  i,T,ii, pcount,D,M,F: Integer;
  ini : TInifile;
  aPlayer,aGK: TSoccerPlayer;
  lstPlayers,lstPlayersDB: TObjectList<TSoccerPlayer>;
  FinalFormation : array[1..11] of TFinalFormation;
  lstGK: TObjectList<TSoccerPlayer>;
  AT: string;
  aF: TFormation;
  ts : TStringList;
  ReserveSlot : TTheArray;
  aReserveSlot,Cur,IndexTal: Integer;
  found: Boolean;
  OldfinalFormation,dataStr: string;
  MM : TMemoryStream;
  SS : TStringStream;
  Buf3 : TArray8192;
  count: Byte;
  guid,age,Matches_Played,Matches_Left,Injured, yellowcard, Disqualified,lenSurname,LenHistory,LenXP,face: Integer;
  DefaultSpeed,DefaultDefense,DefaultPassing,DefaultBallControl  ,DefaultShot,DefaultHeading: Byte;
  country: smallint;
  rank,fitness,morale: Byte;
  AIFormation_x,AIFormation_y: ShortInt;
  lenteamName, lenUniformH,lenUniformA,talentid1,talentid2 : Integer;
  Surname, talent , Attributes: string;
  aMirror: TPoint;
  FC: TFormationCell;
  TvCell,TvReserveCell: TPoint;
  TsHistory,tsXP: TStringList;

  label MyExit;
begin
  Result := '';
  CleanReserveSlot ( ReserveSlot );
  MM := TMemoryStream.Create;
  (* la stora nel db *)

    { come sopra ma legge dal file fm+guid+.120 }

  MM.LoadFromFile( filename );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  lstPlayers:= TObjectList<TSoccerPlayer>.Create(false); // lista locale
  lstPlayersDB:= TObjectList<TSoccerPlayer>.Create(true); // lista locale  che elimina tutti gli oggetti
// OutputDebugString(PChar(IntToStr(Guidteam)));
  pveLoadTeam ( Filename, fm , Guidteam, lstPlayersDB );

  for I := 0 to lstPlayersDB.Count -1 do begin
    aPlayer :=  lstPlayersDB[i];
    if aPlayer.Injured > 0 then  begin
      aPlayer.Stamina:=0;
      aPlayer.Speed:=1;
      aPlayer.Defense:=1;
      aPlayer.Passing:=1;
      aPlayer.Ballcontrol:=1;
      aPlayer.Shot:=1;
      aPlayer.Heading:=1;
    end;

    lstPlayers.add ( aPlayer);
    aPlayer.AIFormationCellX :=  i;   // azzero tutto
    aPlayer.AIFormationCellY :=  -1;

  end;

  // lstPlayers contiene il db ma non squalificati o infortunati. me li porto comunque dietro tutti perchè devo salvare tutti i giocatori
  // FinalFormation i dati finali da storare nel db

  // Metto il portiere. il portiere è sempre presente. non può essere venduto se solo 1. viene generato un giovane gk se manca dalla rosa perchè
  // il gk originale raggiunge una certa età

  // storo tutto nel db
    ts := TStringList.Create;
   // ts.Add('setformation');

    lstGK:= TObjectList<TSoccerPlayer>.Create(false);
    for I := 0 to lstPlayers.Count -1 do begin
      if lstPlayers[i].TalentId1 = TALENT_ID_GOALKEEPER then begin
        aGK:= lstPlayers[i];
        lstGk.Add (aGK);
      end;
    end;

    if lstGK.Count <= 0 then begin
      lstGK.Free;
      goto MyExit;
    end;

    lstGK.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.defense - L.defense;
    end
    ));

    FinalFormation [1].Guid := lstGK[0].Ids;
    FinalFormation [1].cells := Point ( 3, 11 );
    FinalFormation [1].Stamina := lstGK[0].Stamina ;
    FinalFormation [1].role := 'G' ;
    Ts.Add(  FinalFormation [1].Guid  + '=3:11' );

    // a questo punto devo eliminare un giocatore goalkeeper tra i presenti.
    for I := lstPlayers.Count -1 downto 0 do begin
    // gli altri GK sono per forza tutti panchinari
      if (lstPlayers[i].TalentId1 = TALENT_ID_GOALKEEPER )  then begin
        lstPlayers.Delete(i);  // elimino il gk regolare e anche gli altri GK. lstPlayerDB li rimette in panchina
      end;
    end;

    lstGK.Free;

 //  elimino da lstPlayers i disqialified  , gli injured hanno stamina 0 . li elimino comunque qui
    for I := lstPlayers.Count -1 downto 0 do begin
      if (lstPlayers[i].disqualified > 0) or (lstPlayers[i].injured > 0) then begin
        lstPlayers.Delete(i);
      end;
    end;


  // prendo una formazione da una lista di preset
  // DIF - MID - FOR
    pcount := 2; // dopo il gk
    af:= FormationsPreset[ RndGenerate0( FormationsPreset.Count -1 )];
    if formation <> '' then begin
      aF.d := StrToInt(formation[1]);
      aF.m := StrToInt(formation[2]);
      aF.f := StrToInt(formation[3]);
      for I := 0 to FormationsPreset.Count -1 do begin  // devo caricare delle celle valide
        if (FormationsPreset[i].d = aF.d) and (FormationsPreset[i].m = aF.m) and (FormationsPreset[i].f = aF.f)  then  begin
          af := FormationsPreset[i];
          Break;
        end;
      end;
    end;


    lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.defense - L.defense;
    end
    ));


    // ordino prima in base al talento buff, poi in base al best defense, passing,shot
    for I :=  0 to lstPlayers.Count -1  do begin
      if lstPlayers[I].TalentId2 = TALENT_ID_BUFF_DEFENSE then begin
        if i > 0 then begin
          lstPlayers.Exchange( i, 0 );
          Break;
        end;
      end;

    end;

    for D := 1 to aF.D do begin
      if lstPlayers.Count > 0 then begin
        FinalFormation [pcount].Guid := lstPlayers[0].ids;
        FinalFormation [pcount].cells := Point ( aF.Cells[pcount].X , aF.Cells[pcount].Y );
        FinalFormation [pcount].Stamina := lstPlayers[0].Stamina ;
        FinalFormation [pcount].role := 'D' ;
        Ts.Add( lstPlayers[0].ids  + '=' + IntToStr(aF.Cells[pcount].X) + ':' + IntToStr(aF.Cells[pcount].Y ));
        lstPlayers.Delete(0);  // elimino il Difensore D dalla lista
        Inc(pcount);
      end;
    end;


    lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.passing - L.passing;
    end
    ));

    // ordino prima in base al talento buff, poi in base al best defense, passing,shot
    for I :=  0 to lstPlayers.Count -1  do begin
      if lstPlayers[I].TalentId2 = TALENT_ID_BUFF_MIDDLE then begin
        if i > 0 then begin
          lstPlayers.Exchange( i, 0 );
          Break;
        end;
      end;

    end;

    for M := 1 to aF.M do begin
      if lstPlayers.Count > 0 then begin
        FinalFormation [pcount].Guid := lstPlayers[0].ids;
        FinalFormation [pcount].cells := Point ( aF.Cells[pcount].X , aF.Cells[pcount].Y );
        FinalFormation [pcount].Stamina := lstPlayers[0].Stamina ;
        FinalFormation [pcount].role := 'M' ;
        Ts.Add( lstPlayers[0].ids  + '=' + IntToStr(aF.Cells[pcount].X) + ':' + IntToStr(aF.Cells[pcount].Y ));
        lstPlayers.Delete(0);  // elimino il Centrocampista M dalla lista
        Inc(pcount);
      end;
    end;

    lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.shot - L.shot;
     // Result := R.heading - L.heading;
    end
    ));

    // ordino prima in base al talento buff, poi in base al best defense, passing,shot
    for I :=  0 to lstPlayers.Count -1  do begin
      if lstPlayers[I].TalentId2 = TALENT_ID_BUFF_FORWARD then begin
        if i > 0 then begin
          lstPlayers.Exchange( i, 0 );
          Break;
        end;
      end;

    end;

    for F := 1 to aF.F do begin
      if lstPlayers.Count > 0 then begin
        FinalFormation [pcount].Guid := lstPlayers[0].ids;
        FinalFormation [pcount].cells := Point ( aF.Cells[pcount].X , aF.Cells[pcount].Y );
        FinalFormation [pcount].Stamina := lstPlayers[0].Stamina ;
        FinalFormation [pcount].role := 'F' ;
        Ts.Add( lstPlayers[0].ids  + '=' + IntToStr(aF.Cells[pcount].X) + ':' + IntToStr(aF.Cells[pcount].Y ));
        lstPlayers.Delete(0);  // elimino l'attccante F dalla lista
        Inc(pcount);
      end;
    end;

  // poi elimino quelli con stamina bassa 60. provo a sostituirli con stamina > 60.
  // mi sono rimasti i player nella lstPlayers, li ordino in base al ruolo da ricoprire

  // elimino a priori dai possibili sostituti
    for I := lstPlayers.Count -1 downto 0 do begin
      if lstPlayers[i].Stamina <= 60 then
        lstPlayers.Delete(i);
    end;


    for I := 2 to 11 do begin
      if lstPlayers.Count > 0 then begin
        if FinalFormation [i].Stamina <= 60 then begin

          if FinalFormation [i].Role = 'D' then begin
            lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
            function (const L, R: TSoccerPlayer): integer
            begin
              Result := R.defense - L.defense;
            end
            ));
          end
          else if FinalFormation [i].Role = 'M' then begin
            lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
            function (const L, R: TSoccerPlayer): integer
            begin
              Result := R.passing - L.passing;
            end
            ));
          end
          else if FinalFormation [i].Role = 'F' then begin
            lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
            function (const L, R: TSoccerPlayer): integer
            begin
              Result := R.shot - L.shot;
             // Result := R.heading - L.heading;
            end
            ));
          end;
          // qui è quello ordinato in base a difesa, passaggio o tiro e quello che entra non può avere stamina bassa -60 (rimossi sopra)

          if ForceYoung then begin // forzo a far giocare i più giovani
            lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
            function (const L, R: TSoccerPlayer): integer
            begin
              Result := L.Age - R.Age; // L e R invertite qui, mi servono i più giovani
             // Result := R.heading - L.heading;
            end
            ));
          end;

          // modifico la finalformation
          OldfinalFormation := FinalFormation [i].Guid;
          FinalFormation [i].Guid := lstPlayers[0].ids;
          FinalFormation [i].Stamina := lstPlayers[0].Stamina ;
          // modifico la TS
          for T := 0 to ts.Count -1 do begin
            if ts.Names[T] = OldfinalFormation then begin
              Ts[T]:= FinalFormation [i].Guid + '=' + IntToStr(FinalFormation[i].Cells.X  ) + ':' + IntToStr(FinalFormation[i].Cells.Y );
              Break;
            end;
          end;
          lstPlayers.Delete(0);  // elimino il player dalla lista

        end;

      end;

    end;

    // qui gli 11 titolari sono schierati correttamente. devo aggiungere a ts le riserve ovvero tutti coloro che sono player ma non in ts.commatext
    // creo la TS con gli 11 titolari di finalformation


    for I := lstPlayersDB.Count -1 downto 0 do begin  //  lstPlayersDB contiene tutti dal db
      // tutti gli ids che non sono presenti in FinalFormation vanno in panchina
      found := False;

      for ii := 1 to 11 do begin
        if FinalFormation [ii].Guid = lstPlayersDB[i].Ids  then begin // è presente nei 11 titolari
          found := True;
          Break;
        end;
      end;

      if not found then begin   // se nopn è prsente nei 11 titolati lo metto in panchina e lo aggiungo in coda alla ts
        aReserveSlot := NextReserveSlot ( ReserveSlot );
        ReserveSlot [aReserveSlot] :=  lstPlayersDB[i].Ids;
        lstPlayersDB[i].AIFormationCellX := aReserveSlot;
        lstPlayersDB[i].AIFormationCellY := -1; // fisso -1

        Ts.Add( lstPlayersDB[i].ids  + '=' +
        IntToStr(lstPlayersDB[i].AIFormationCellX  ) + ':' +
        IntToStr(lstPlayersDB[i].AIFormationCellY ));
      end;

    end;

    Result := Ts.CommaText ; // formazione + riserve
Myexit:
    MM.free;
    lstPlayers.Free;
    lstPlayersDB.Free;
    ts.Free;
    { si può giocare anche in meno di 7 giocatori }
end;
procedure pveLoadTeam ( Filename:string; fm : Char; Guidteam: integer;var lstPlayersDB : TObjectlist<TSoccerPlayer> );
var
  i, pcount: Integer;
  aPlayer: TSoccerPlayer;
  ts : TStringList;
  Cur,IndexTal: Integer;
  dataStr: string;
  MM : TMemoryStream;
  SS : TStringStream;
  Buf3 : TArray8192;
  count: Byte;
  lenteamName, talentid1,talentid2,lenSurname,LenHistory,LenXP : Integer;
  TsHistory,tsXP: TStringList;
begin
//  uguale a ClientLoadFormation ma senza grafica
  MM := TMemoryStream.Create;
  MM.LoadFromFile( filename );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  lstPlayersDB.clear;
  // uguale a ClientLoadFormation ma senza grafica
  count := ord (buf3 [ cur ]);   // quanti player
  Cur := Cur + 1; //
  for I := 0 to Count -1 do begin
    aPlayer:= TSoccerPlayer.create(0, GuidTeam,0,'','','','',0,0);

    aPlayer.ids := IntToStr( PDWORD(@buf3 [ cur ])^); // player identificativo globale
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3 [ cur ]);
    aPlayer.Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;

    aPlayer.Age :=  Ord( buf3 [ cur ]);               // età
    Cur := Cur + 1 ;
    aPlayer.TalentID1 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;
    aPlayer.TalentID2 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aPlayer.Stamina := PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    aPlayer.DefaultSpeed := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultDefense := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultPassing := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultBallControl := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultShot := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.DefaultHeading := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.Attributes:= IntTostr( aPlayer.DefaultSpeed) + ',' + IntTostr( aPlayer.DefaultDefense) + ',' + IntTostr( aPlayer.DefaultPassing) + ',' + IntTostr( aPlayer.DefaultBallControl) + ',' +
                 IntTostr( aPlayer.DefaultShot) + ',' + IntTostr( aPlayer.DefaultHeading) ;

    aPlayer.AIFormationCellX := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.AIFormationCellY := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.injured := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.yellowcard := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.disqualified := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
//    onmarket := Ord( buf3 [ cur ]);
//    Cur := Cur + 1;
    aPlayer.face :=  PDWORD(@buf3 [ cur ])^; // face bmp viso
    Cur := Cur + 4;
    aPlayer.fitness:= Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.morale:=Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aPlayer.country:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;




    aPlayer.devA:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    aPlayer.devT:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    aPlayer.devI:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    aPlayer.DefaultCells := aPlayer.Cells;


    tsHistory := TStringList.Create;
    LenHistory :=  Ord( buf3 [ cur ]);
    tsHistory.commaText := MidStr( dataStr, cur + 2  , LenHistory );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + LenHistory + 1;
//      tsHistory.commaText := ini.readString('player' + IntToStr(i),'History','0,0,0,0,0,0' ); // <-- 6 attributes

//OutputDebugString(PChar( 'T:'+ Inttostr (Guidteam )+'  ts:' + tsHistory.commatext));
    aPlayer.History_Speed         := StrToInt( tsHistory[0]);
    aPlayer.History_Defense       := StrToInt( tsHistory[1]);
    aPlayer.History_Passing       := StrToInt( tsHistory[2]);
    aPlayer.History_BallControl   := StrToInt( tsHistory[3]);
    aPlayer.History_Shot          := StrToInt( tsHistory[4]);
    aPlayer.History_Heading       := StrToInt( tsHistory[5]);
    tsHistory.Free;

    tsXP := TStringList.Create;
    LenXP :=  Ord( buf3 [ cur ]);
//     tsXP.commaText := ini.readString('player' + IntToStr(i),'xp','0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0' ); // <-- 6 attributes , 17 talenti
    tsXP.commaText := MidStr( dataStr, cur + 2  , LenXP );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + LenXP + 1;

    // rispettare esatto ordine dei talenti sul db
    aPlayer.xp_Speed         := StrToInt( tsXP[0]);
    aPlayer.xp_Defense       := StrToInt( tsXP[1]);
    aPlayer.xp_Passing       := StrToInt( tsXP[2]);
    aPlayer.xp_BallControl   := StrToInt( tsXP[3]);
    aPlayer.xp_Shot          := StrToInt( tsXP[4]);
    aPlayer.xp_Heading       := StrToInt( tsXP[5]);

    for IndexTal := 1 to NUM_TALENT do begin
      aPlayer.xpTal[IndexTal]:= StrToInt( tsXP[IndexTal+5]);
//      if aPlayer.XpTal[TALENT_ID_AGGRESSION] = 65535 then asm int 3 ; end;
      
    end;

    tsXP.Free;
    aPlayer.xpDevA:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    aPlayer.xpDevT:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    aPlayer.xpDevI:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    lstPlayersDB.add ( aPlayer);

  end;

end;

function NextReserveSlot ( ReserveSlot: TTheArray ): Integer;
var
  x: Integer;
begin

    for x := 0 to 21 do begin
      if ReserveSlot [x] = '' then begin
        Result := x;
        Exit;
      end;
    end;
end;
procedure CleanReserveSlot ( ReserveSlot: TTheArray );
var
  x: Integer;
begin
    for x := 0 to 21 do begin
      ReserveSlot [x] := '';
    end;
end;
function Buff_or_Debuff_4 ( aPlayer: TSoccerPlayer; buff,Max_stat:Integer): Boolean;
var
  Ts:TStringList;
  aRnd,aValue:Integer;
begin
  Result := False;
  Ts:= TStringList.Create;
  Ts.CommaText :=  aPlayer.Attributes;// legge i default
  aRnd := RndGenerateRange(1,4) ; // difesa,passing,ballcontrol,shot
  aValue := StrToInt(Ts[aRnd]);
  if Buff > 0 then begin
    if aValue < Max_stat then begin  // F e M  se è già al massimo, non fa nulla
      aValue := aValue + 1;
      Ts[aRnd] := IntToStr ( aValue );
      aPlayer.Attributes := Ts.CommaText; // setta automaticamente i defaults
      Result := True;
    end;
  end
  else if Buff < 0 then begin // debuff morale
    if aValue > 1 then begin  // F e M  se è già al massimo, non fa nulla
      aValue := aValue - 1;
      Ts[aRnd] := IntToStr ( aValue );
      aPlayer.Attributes := Ts.CommaText; // setta automaticamente i defaults
      Result := True;
    end;
  end;
  Ts.Free;
end;
function isReserveSlot (CellX, CellY: integer): boolean;
begin
  Result:= false;
  if CellY < 0 then
    result := True;
end;
function isReserveSlotFormation (CellX, CellY: integer): boolean;
begin
  Result:= false;
  if (CellY < 0) then    // -1
    result := True;
end;
function pveGetDBPlayer ( FileName, guid: string; var MyBasePlayer: TBasePlayer ): Boolean;
var
  i,y: Integer;
  MM : TMemoryStream;
  tmps: string[255];
  IndexTal,cur,count,lenSurname: integer;
  ts2,tscells : TStringList;
  SS :TStringStream;
  datastr : string;
  Buf3 : TArray8192;
  LenHistory,LenXP: Integer;
begin
  { legge dal file fm+guid+.120 }
  Result := False;
  MM:= TMemoryStream.Create;
  MM.LoadFromFile( filename );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  ts2 := TStringList.Create;

  // uguale a ClientLoadFormation ma senza grafica
  count := ord (buf3 [ cur ]);   // quanti player
  Cur := Cur + 1; //
  for I := 0 to Count -1 do begin

    MyBasePlayer.guid :=  PDWORD(@buf3 [ cur ])^; // player identificativo globale
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3 [ cur ]);
    MyBasePlayer.Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;

    MyBasePlayer.Age :=  Ord( buf3 [ cur ]);               // età
    Cur := Cur + 1 ;
    MyBasePlayer.TalentID1 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;
    MyBasePlayer.TalentID2 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    MyBasePlayer.Stamina := PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    MyBasePlayer.DefaultSpeed := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.DefaultDefense := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.DefaultPassing := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.DefaultBallControl := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.DefaultShot := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.DefaultHeading := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    MyBasePlayer.Attributes:= IntTostr( MyBasePlayer.DefaultSpeed) + ',' + IntTostr( MyBasePlayer.DefaultDefense) + ',' + IntTostr( MyBasePlayer.DefaultPassing) + ',' + IntTostr( MyBasePlayer.DefaultBallControl) + ',' +
                 IntTostr( MyBasePlayer.DefaultShot) + ',' + IntTostr( MyBasePlayer.DefaultHeading) ;

    MyBasePlayer.Formation_X := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.Formation_y := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.injured := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.yellowcard := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.disqualified := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
//    MyBasePlayer.onmarket := Ord( buf3 [ cur ]);
//    Cur := Cur + 1;
    MyBasePlayer.face :=  PDWORD(@buf3 [ cur ])^; // face bmp viso
    Cur := Cur + 4;
    MyBasePlayer.fitness:= Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.morale:=Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    MyBasePlayer.country:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    MyBasePlayer.devA:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    MyBasePlayer.devT:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    MyBasePlayer.devI:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    LenHistory :=  Ord( buf3 [ cur ]);
    MyBasePlayer.history := MidStr( dataStr, cur + 2  , LenHistory );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + LenHistory + 1;
    ts2.CommaText := MyBasePlayer.history;
    MyBasePlayer.History_Speed         := StrToInt( ts2[0]);
    MyBasePlayer.History_Defense       := StrToInt( ts2[1]);
    MyBasePlayer.History_Passing       := StrToInt( ts2[2]);
    MyBasePlayer.History_BallControl   := StrToInt( ts2[3]);
    MyBasePlayer.History_Shot          := StrToInt( ts2[4]);
    MyBasePlayer.History_Heading       := StrToInt( ts2[5]);

    LenXP :=  Ord( buf3 [ cur ]);
    MyBasePlayer.Xp := MidStr( dataStr, cur + 2  , LenXP );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + LenXP + 1;
    ts2.CommaText := MyBasePlayer.Xp;

    MyBasePlayer.xp_Speed := StrToInt( ts2[0]);
    MyBasePlayer.xp_Defense := StrToInt( ts2[1]);
    MyBasePlayer.xp_Passing := StrToInt( ts2[2]);
    MyBasePlayer.xp_BallControl := StrToInt( ts2[3]);
    MyBasePlayer.xp_Shot := StrToInt( ts2[4]);
    MyBasePlayer.xp_Heading := StrToInt( ts2[5]);

    for IndexTal := 1 to NUM_TALENT do begin
      MyBasePlayer.xpTal[IndexTal]:=  StrToInt( ts2[IndexTal+5]);
    end;



    MyBasePlayer.xpDevA:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    MyBasePlayer.xpDevT:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;
    MyBasePlayer.xpDevI:= PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    if MyBasePlayer.Guid = StrToInt(Guid) then begin
      Result := True;
      Break;
    end;
  end;

  MM.Free;

end;
function pveOnMarket (fm: char; Guid: string; dirSaves: string): Boolean;
var
  i,count,cur,lenSurname: integer;
  aBasePlayer: TBasePlayer;
  buf3 : TArray32768;
  MM : TMemoryStream;
  SS : TStringStream;
  datastr : string;
begin
  Result := false;
  FillMemory(@buf3,SizeOf(Buf3),0);
  MM := TMemoryStream.Create;
  MM.Size:=0;
  MM.LoadFromFile( dirSaves  + fm + 'market.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  count := PWORD(@buf3)^;  // quanti player . solo in questo caso è smallint
  Cur := Cur + 2; //
  for I := 0 to Count -1 do begin
    aBasePlayer.Guid := PDWORD(@buf3[ cur ] )^; // player identificativo globale
    if aBasePlayer.Guid = StrToInt( Guid ) then begin
      result := True;
      MM.Free;
      Exit;
    end;


    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[ cur ]);
    aBasePlayer.Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;

    aBasePlayer.Age :=Ord( buf3[ cur ]); // solo age, non matchleseft
    Cur := Cur + 1;

    aBasePlayer.DefaultSpeed := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultDefense := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultPassing := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultBallControl := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultShot := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultHeading := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aBasePlayer.TalentID1 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;
    aBasePlayer.TalentID2 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.Country :=  PWORD(@buf3[ cur ] )^;
    Cur := Cur + 2;

    aBasePlayer.Fitness := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.GuidTeam := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;
    aBasePlayer.Face := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Price := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

  end;

  MM.Free;

end;
function pveGetTotMarket (fm: char; GuidTeam, DirSaves: string): Integer;
var
  i,count,cur,lenSurname: integer;
  aBasePlayer: TBasePlayer;
  buf3 : TArray32768;
  MM : TMemoryStream;
  SS : TStringStream;
  datastr : string;
  stored: Boolean;
  aPlayer: TSoccerPlayer;
begin
  Result := 0;
  FillMemory(@buf3,SizeOf(Buf3),0);
  MM := TMemoryStream.Create;
  MM.Size:=0;
  MM.LoadFromFile( dirSaves  + fm + 'market.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  count := PWORD(@buf3)^;  // quanti player . solo in questo caso è smallint
  Cur := Cur + 2; //
  for I := 0 to Count -1 do begin
    aBasePlayer.Guid := PDWORD(@buf3[ cur ] )^; // player identificativo globale

    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[ cur ]);
    aBasePlayer.Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;

    aBasePlayer.Age :=Ord( buf3[ cur ]); // solo age, non matchleseft
    Cur := Cur + 1;

    aBasePlayer.DefaultSpeed := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultDefense := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultPassing := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultBallControl := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultShot := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultHeading := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aBasePlayer.TalentID1 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;
    aBasePlayer.TalentID2 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.Country :=  PWORD(@buf3[ cur ] )^;
    Cur := Cur + 2;
    aBasePlayer.Fitness := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.GuidTeam := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;
    if aBasePlayer.GuidTeam = StrToInt( GuidTeam ) then begin
      result := result + 1;
    end;

    aBasePlayer.Face := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Price := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

  end;

  MM.Free;

end;
procedure pveAddToMarket (fm:char; Guid, GuidTeam, dirSaves: string; Price:Integer );
var
  i,count,cur,lenSurname: integer;
  lstMarketPlayer : TList<TBasePlayer>;
  aBasePlayer: TBasePlayer;
  buf3 : TArray32768;
  MM : TMemoryStream;
  SS : TStringStream;
  datastr : string;
  aPlayer: TSoccerPlayer;
  tmpb : Byte;
  tmpi: Integer;
  myFile:TextFile;
  tmps:string[255];
begin
  // DevA devT e DevI , tutte le xp e history non vengono salvate. Sono informazioni conosciute solo quando si ha acquistato il player
  // Quando un player si sviluppa o passa di età, se presente sul market, viene aggiornato
  // Sono al massimo 264*5 player sul mercato quindi e quando si libera uno slot, rimane a guid=0 per il prossimo inserimento.
  // Gestione binaria del file così lo posso caricare tutto in memoria. Il primo SMALLINT non è il recordcount effettivo, ma il numero di
  // slot. Se è necessario, si aggiunge uno slot e si aggiorna il recordcount. Uso lstMarketPlayer TList<TBasePlayer>

  // CARICO TUTTO IL MARKET
  // apro mmarket.120 o fmarket.120, aggiorno e lo salvo
  lstMarketPlayer := TList<TBasePlayer>.Create;
  FillMemory(@buf3,SizeOf(Buf3),0);
  MM := TMemoryStream.Create;
  MM.Size:=0;
  MM.LoadFromFile( dirSaves  + fm + 'market.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  count := PWORD(@buf3)^;  // quanti player . solo in questo caso è smallint
  Cur := Cur + 2; //
  for I := 0 to Count -1 do begin
    aBasePlayer.Guid := PDWORD(@buf3[ cur ] )^; // player identificativo globale
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[ cur ]);
    aBasePlayer.Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;

    aBasePlayer.Age :=Ord( buf3[ cur ]); // solo age, non matchleseft
    Cur := Cur + 1;

    aBasePlayer.DefaultSpeed := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultDefense := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultPassing := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultBallControl := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultShot := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultHeading := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aBasePlayer.TalentID1 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;
    aBasePlayer.TalentID2 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.Country :=  PWORD(@buf3[ cur ] )^;
    Cur := Cur + 2;

    aBasePlayer.Fitness := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.GuidTeam := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;
    aBasePlayer.Face := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Price := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    // Qui se ho cancellato dei player con cancelsell evito di riscriverli.
    if (aBasePlayer.Guid <> 0) or ( aBasePlayer.GuidTeam = 0 ) then
      lstMarketPlayer.Add(aBasePlayer); // lista ompleta del market
  end;


  // in questo momento ho in memoria nel brain il mio team.

  // lo devo aggiungere a lstMarketPlayer
  pveGetDBPlayer (dirSaves + fm + GuidTeam + '.120' , guid, aBasePlayer );
  aBasePlayer.GuidTeam := StrToInt(GuidTeam); // lo devo assegnare, nel file non c'è, nel market serve
  aBasePlayer.Price := Price;
  lstMarketPlayer.add ( aBasePlayer );

    {$ifdef tools}
  AssignFile(myFile, dirsaves + fm + 'logmarket.txt');
  Append(myFile);
  writeln(myFile, fm + ' ' + GuidTeam + ' ha messo in vendita A=' + (aBasePlayer.Attributes) +' age:' + IntToStr(aBasePlayer.Age) + ' T:' + IntToStr(aBasePlayer.TalentId1));
  CloseFile(myFile);
  {$endif tools}


  MM.Clear;
  MM.Size:=0;
  MM.Write( @lstMarketPlayer.Count, sizeof(smallint) );
  // infine ogni volta storo di nuovo tutto il market

  for I := 0 to lstMarketPlayer.Count -1 do begin  // simile a saveteamStream

    tmpi:=  lstMarketPlayer[i].Guid;
    MM.Write( @tmpi , sizeof(integer) );

    tmps := lstMarketPlayer[i].Surname;
    MM.Write( @tmps[0] , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    tmpb := lstMarketPlayer[i].Age;
    MM.Write( @tmpb, sizeof(Byte) );

    tmpb := lstMarketPlayer[i].DefaultSpeed;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultDefense;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultPassing;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultBallControl;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultShot;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultHeading;
    MM.Write( @tmpb, sizeof(Byte) );

    tmpb := lstMarketPlayer[i].TalentId1;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].TalentId2;
    MM.Write( @tmpb, sizeof(Byte) );

    tmpi := lstMarketPlayer[i].Country;
    MM.Write( @tmpi, sizeof(Word) );

    tmpb := lstMarketPlayer[i].Fitness;
    MM.Write( @tmpb, sizeof(Byte) );

    tmpi:=  lstMarketPlayer[i].GuidTeam;
    MM.Write( @tmpi , sizeof(integer) );
    tmpi:=  lstMarketPlayer[i].Face;
    MM.Write( @tmpi , sizeof(integer) );
    tmpi:=  lstMarketPlayer[i].Price;
    MM.Write( @tmpi , sizeof(integer) );

  end;


  MM.SaveToFile (dirSaves  + fm + 'market.120' );
  MM.Free;
  lstMarketPlayer.Free;


end;
function PveDeleteFromMarket (fm:char; Guid: string; dirSaves: string ): Boolean;
var
  i,count,cur,lenSurname: integer;
  lstMarketPlayer : TList<TBasePlayer>;
  aBasePlayer: TBasePlayer;
  buf3 : TArray32768;
  MM : TMemoryStream;
  SS : TStringStream;
  datastr : string;
  tmpb : Byte;
  tmpi: Integer;
  tmps:string[255];
  label Falseexit;
begin
  // DevA devT e DevI , tutte le xp e history non vengono salvate. Sono informazioni conosciute solo quando si ha acquistato il player
  // Quando un player si sviluppa o passa di età, se presente sul market, viene aggiornato
  // Sono al massimo 264*5 player sul mercato quindi e quando si libera uno slot, rimane a guid=0 per il prossimo inserimento.
  // Gestione binaria del file così lo posso caricare tutto in memoria. Il primo SMALLINT non è il recordcount effettivo, ma il numero di
  // slot. Se è necessario, si aggiunge uno slot e si aggiorna il recordcount. Uso lstMarketPlayer TList<TBasePlayer>

  // CARICO TUTTO IL MARKET
  // apro mmarket.120 o fmarket.120, aggiorno e lo salvo
  Result := False;
  lstMarketPlayer := TList<TBasePlayer>.Create;
  FillMemory(@buf3,SizeOf(Buf3),0);
  MM := TMemoryStream.Create;
  MM.Size:=0;
  MM.LoadFromFile( dirSaves  + fm + 'market.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  // praticamente leggo e salvo di nuovo l'intero market eliminado quesot player

  count := PWORD(@buf3)^;  // quanti player . solo in questo caso è smallint
  Cur := Cur + 2; //
  for I := 0 to Count -1 do begin
    aBasePlayer.Guid := PDWORD(@buf3[ cur ] )^; // player identificativo globale
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[ cur ]);
    aBasePlayer.Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;

    aBasePlayer.Age :=Ord( buf3[ cur ]); // solo age, non matchleseft
    Cur := Cur + 1;

    aBasePlayer.DefaultSpeed := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultDefense := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultPassing := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultBallControl := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultShot := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultHeading := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aBasePlayer.TalentID1 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;
    aBasePlayer.TalentID2 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.Country :=  PWORD(@buf3[ cur ] )^;
    Cur := Cur + 2;

    aBasePlayer.Fitness := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.GuidTeam := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    if aBasePlayer.Guid = StrToInt(Guid) then begin
      aBasePlayer.Guid := 0;
      aBasePlayer.GuidTeam := 0;
      Result := True;
    end;

    aBasePlayer.Face := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Price := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    if aBasePlayer.Guid <> 0 then
      lstMarketPlayer.Add(aBasePlayer); // lista ompleta del market
  end;

  if Result = False then  // nessuna modifica al file di mercato, quindi non devo riscriverlo
    goto Falseexit;

  MM.Clear;
  MM.Size:=0;
  MM.Write( @lstMarketPlayer.Count, sizeof(smallint) );
  // infine ogni volta storo di nuovo tutto il market

  for I := 0 to lstMarketPlayer.Count -1 do begin  // simile a saveteamStream

    tmpi:=  lstMarketPlayer[i].Guid;
    MM.Write( @tmpi , sizeof(integer) );

    tmps := lstMarketPlayer[i].Surname;
    MM.Write( @tmps[0] , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    tmpb := lstMarketPlayer[i].Age;
    MM.Write( @tmpb, sizeof(Byte) );

    tmpb := lstMarketPlayer[i].DefaultSpeed;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultDefense;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultPassing;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultBallControl;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultShot;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].DefaultHeading;
    MM.Write( @tmpb, sizeof(Byte) );

    tmpb := lstMarketPlayer[i].TalentId1;
    MM.Write( @tmpb, sizeof(Byte) );
    tmpb := lstMarketPlayer[i].TalentId2;
    MM.Write( @tmpb, sizeof(Byte) );

    tmpi := lstMarketPlayer[i].Country;
    MM.Write( @tmpi, sizeof(Word) );

    tmpb := lstMarketPlayer[i].Fitness;
    MM.Write( @tmpb, sizeof(Byte) );

    tmpi:=  lstMarketPlayer[i].GuidTeam;
    MM.Write( @tmpi , sizeof(integer) );
    tmpi:=  lstMarketPlayer[i].Face;
    MM.Write( @tmpi , sizeof(integer) );
    tmpi:=  lstMarketPlayer[i].Price;
    MM.Write( @tmpi , sizeof(integer) );

  end;


  MM.SaveToFile (dirSaves  + fm + 'market.120' );

Falseexit:
  MM.Free;
  lstMarketPlayer.Free;



end;
procedure pveTransferMarket ( fm: char; guid, ToGuidTeam: integer; DirSaves: string  ); // il fromTeam lo trova nel record. Accede al fromteam per eliminare il giocatore
var
  i,count,cur,lenSurname: integer;
  aBasePlayer: TBasePlayer;
  buf3 : TArray32768;
  MM : TMemoryStream;
  SS : TStringStream;
  datastr : string;
  aPlayer: TSoccerPlayer;
  myFile: TextFile;
begin

  // CARICO TUTTO IL MARKET
  // apro mmarket.120 o fmarket.120, aggiorno e lo salvo
  FillMemory(@buf3,SizeOf(Buf3),0);
  MM := TMemoryStream.Create;
  MM.Size:=0;
  MM.LoadFromFile( dirSaves  + fm + 'market.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  // praticamente leggo e salvo di nuovo l'intero market eliminado quesot player

  count := PWORD(@buf3)^;  // quanti player . solo in questo caso è smallint
  Cur := Cur + 2; //
  for I := 0 to Count -1 do begin
    aBasePlayer.Guid := PDWORD(@buf3[ cur ] )^; // player identificativo globale
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[ cur ]);
    aBasePlayer.Surname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;

    aBasePlayer.Age :=Ord( buf3[ cur ]); // solo age, non matchleseft
    Cur := Cur + 1;

    aBasePlayer.DefaultSpeed := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultDefense := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultPassing := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultBallControl := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultShot := Ord( buf3 [ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultHeading := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aBasePlayer.TalentID1 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;
    aBasePlayer.TalentID2 := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.Country :=  PWORD(@buf3[ cur ] )^;
    Cur := Cur + 2;

    aBasePlayer.Fitness := Ord( buf3 [ cur ]);           // identificativo talento
    Cur := Cur + 1;

    aBasePlayer.GuidTeam := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;


    aBasePlayer.Face := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Price := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    if aBasePlayer.Guid = Guid then begin // se è il guid pronto per il transfer aBasePlayer.GuidTeam mi dice dove eliminarlo
// lo aggiunge a es. f10.120 . riscrive il file. devo leggere tutti i dati, quelli del market non mi bastano. uso pveLoadTeam;
      pveAddToTeam ( fm, guid, aBasePlayer.GuidTeam, ToGuidTeam, DirSaves );
    // In questo momento c'è una copia in ogni team
      pveDeleteFromTeam ( fm, guid, aBasePlayer.GuidTeam ,DirSaves); // riscrive es. f16.120
      {$ifdef tools}
        AssignFile(myFile, dirsaves + fm + 'logmarket.txt');
        Append(myFile);
        writeln(myFile, fm + ' ' + IntToStr(ToGuidTeam) + ' ha comprato A=' + aBasePlayer.Attributes +' age:' + IntToStr(aBasePlayer.Age) + ' T:' + IntToStr(aBasePlayer.TalentId1));
        CloseFile(myFile);
      {$endif tools}

      pveTransferMoney ( fm , aBasePlayer.GuidTeam, ToGuidTeam, aBasePlayer.Price, DirSaves  );// sfoglio tutte le divisioni e le country alla ricerca dei 2 team
      break;
    end;

  end;

  // lo elimino dal market, è come fare cancelsell ( delete fromMarket)
  PveDeleteFromMarket (fm,  IntToStr(Guid), dirSaves ); // lo elimino dal market. Il record viene eliminato

  MM.Free;

end;
procedure pveTransferMoney (fm: Char; FromGuidTeam, ToGuidTeam, Price : integer; dirSaves: string  );
begin
  pveAddTeamMoney ( fm , FromGuidTeam, Price, DirSaves  );// sfoglio tutte le divisioni e le country alla ricerca dei 2 team
  pveSubtractTeamMoney ( fm , ToGuidTeam, Price, DirSaves  );// sfoglio tutte le divisioni alla ricerca dei 2 team
end;
procedure pveAddTeamMoney (fm: Char; GuidTeam, Price : integer; dirSaves: string  );
var
  Cur: Integer;
  I, Money: Integer;
  MM : TMemoryStream;
  aTeamRecord : TTeam;
  buf3: TArray8192;
begin
  MM := TMemoryStream.Create;
  MM.LoadFromFile( dirSaves + fm + 'teams.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  MM.Position := 0;

  Cur := 0;

  while Cur < MM.Size do begin

    aTeamRecord.guid := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;
    aTeamRecord.Money := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;

    if aTeamRecord.guid = GuidTeam then begin
      aTeamRecord.Money := aTeamRecord.Money + Price;
      MM.Position := Cur - 4;
      MM.Write(@aTeamRecord.money,4);
      MM.SaveToFile(dirSaves + fm + 'teams.120' );
      MM.Free;
      Exit;
    end;
    aTeamRecord.Division := ord ( buf3 [ cur ]);
    Cur := Cur + 1;
    aTeamRecord.YoungQueue := ord ( buf3 [ cur ]);
    Cur := Cur + 1;

  end;
end;
procedure pveSubtractTeamMoney ( fm: Char; GuidTeam, Price: Integer; DirSaves : string );// sfoglio tutte le divisioni alla ricerca dei 2 team
var
  Cur: Integer;
  I, Money: Integer;
  MM : TMemoryStream;
  aTeamRecord : TTeam;
  buf3: TArray8192;
begin
  MM := TMemoryStream.Create;
  MM.LoadFromFile( dirSaves + fm + 'teams.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  MM.Position := 0;

  Cur := 0;

  while Cur < MM.Size do begin

    aTeamRecord.guid := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;
    aTeamRecord.Money := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;
    if aTeamRecord.guid = GuidTeam then begin
      aTeamRecord.Money := aTeamRecord.Money - Price;
      MM.Position := Cur - 4;
      MM.Write(@aTeamRecord.money,4);
      MM.SaveToFile(dirSaves + fm + 'teams.120' );
      MM.Free;
      Exit;
    end;

    aTeamRecord.Division := ord ( buf3 [ cur ]);
    Cur := Cur + 1;
    aTeamRecord.YoungQueue := ord ( buf3 [ cur ]);
    Cur := Cur + 1;


  end;
end;
procedure pveSetTeamMoney (fm: Char; GuidTeam, Total : integer; dirSaves: string  );
var
  Cur: Integer;
  I, Money: Integer;
  MM : TMemoryStream;
  aTeamRecord : TTeam;
  buf3: TArray8192;
begin
  MM := TMemoryStream.Create;
  MM.LoadFromFile( dirSaves + fm + 'teams.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  MM.Position := 0;

  Cur := 0;

  while Cur < MM.Size do begin

    aTeamRecord.guid := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;
    aTeamRecord.Money := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;

    if aTeamRecord.guid = GuidTeam then begin
      MM.Position := Cur - 4;
      aTeamRecord.Money := Total;
      MM.Write(@aTeamRecord.money ,4);
      MM.SaveToFile(dirSaves + fm + 'teams.120' );
      MM.Free;
      Exit;
    end;

    aTeamRecord.Division := ord ( buf3 [ cur ]);
    Cur := Cur + 1;
    aTeamRecord.YoungQueue := ord ( buf3 [ cur ]);
    Cur := Cur + 1;

  end;
end;
function pveGetTeamInfo (fm: Char; GuidTeam: integer; dirSaves: string  ): TTeam;
var
  Cur: Integer;
  I, Money: Integer;
  MM : TMemoryStream;
  aTeamRecord : TTeam;
  buf3: TArray8192;
begin
  MM := TMemoryStream.Create;
  MM.LoadFromFile( dirSaves + fm + 'teams.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  MM.Position := 0;

  Cur := 0;

  while Cur < MM.size do begin

    Result.guid := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;
    Result.Money := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;
    Result.Division := ord ( buf3 [ cur ]);
    Cur := Cur + 1;
    Result.YoungQueue := ord ( buf3 [ cur ]);
    Cur := Cur + 1;
    if Result.guid = GuidTeam then begin
      MM.Free;
      Exit;
    end;
  end;
end;

procedure pveAddToTeam (fm: Char; guid, FromGuidTeam, ToGuidTeam: integer; dirSaves: string  );
var
  MyBasePlayer: TBasePlayer;
  lstPlayersDB: TObjectList<TSoccerPlayer>;
  aPlayer : TSoccerPlayer;
  IndexTal: Integer;
begin
  lstPlayersDB:= TObjectList<TSoccerPlayer>.Create(true); // lista locale  che elimina tutti gli oggetti

  pveGetDBPlayer ( dirSaves + fm + IntToStr(FromGuidTeam) + '.120', IntToStr(guid), MyBasePlayer ); // ottengo il giocatore
  makedelay (500);
  pveLoadTeam ( dirSaves + fm + IntToStr(ToGuidTeam) + '.120', fm , ToGuidTeam, lstPlayersDB ); // ottengo la squadra di destinazione
  // aggiungo il player e salvo la squadra intera

  aPlayer:= TSoccerPlayer.create(0, ToGuidTeam,0,'','','','',0,0);
  aPlayer.Ids := IntToStr(MyBasePlayer.Guid);
  aPlayer.GuidTeam := ToGuidTeam; // comunque non lo salvo come dato
  aPlayer.Surname := MyBasePlayer.Surname;
  aPlayer.Age :=  MyBasePlayer.Age;
  aPlayer.TalentID1 := MyBasePlayer.TalentId1;
  aPlayer.TalentID2 := MyBasePlayer.TalentId2;
  aPlayer.Stamina := MyBasePlayer.Stamina;

  aPlayer.DefaultSpeed := MyBasePlayer.DefaultSpeed;
  aPlayer.DefaultDefense := MyBasePlayer.DefaultDefense;
  aPlayer.DefaultPassing := MyBasePlayer.DefaultPassing;
  aPlayer.DefaultBallControl := MyBasePlayer.DefaultBallControl;
  aPlayer.DefaultShot := MyBasePlayer.DefaultShot;
  aPlayer.DefaultHeading := MyBasePlayer.DefaultHeading;
  aPlayer.Attributes:= IntTostr( aPlayer.DefaultSpeed) + ',' + IntTostr( aPlayer.DefaultDefense) + ',' + IntTostr( aPlayer.DefaultPassing) + ',' + IntTostr( aPlayer.DefaultBallControl) + ',' +
               IntTostr( aPlayer.DefaultShot) + ',' + IntTostr( aPlayer.DefaultHeading) ;

  aPlayer.AIFormationCellX := MyBasePlayer.Formation_X;
  aPlayer.AIFormationCellY := MyBasePlayer.Formation_Y;
  aPlayer.injured := MyBasePlayer.injured;
  aPlayer.yellowcard := MyBasePlayer.yellowcard;
  aPlayer.disqualified := MyBasePlayer.disqualified;
//    onmarket := MyBasePlayer.
//    Cur := Cur + 1;
  aPlayer.face :=  MyBasePlayer.face;
  aPlayer.fitness:= MyBasePlayer.fitness;
  aPlayer.morale:= MyBasePlayer.morale;
  aPlayer.country:= MyBasePlayer.Country;

  aPlayer.devA:= MyBasePlayer.devA;
  aPlayer.devT:= MyBasePlayer.devT;
  aPlayer.devI:= MyBasePlayer.devI;

  aPlayer.DefaultCells := aPlayer.Cells;

  aPlayer.History_Speed         := MyBasePlayer.History_Speed;
  aPlayer.History_Defense       := MyBasePlayer.History_Defense;
  aPlayer.History_Passing       := MyBasePlayer.History_Passing;
  aPlayer.History_BallControl   := MyBasePlayer.History_BallControl;
  aPlayer.History_Shot          := MyBasePlayer.History_Shot;
  aPlayer.History_Heading       := MyBasePlayer.History_Heading;

  // rispettare esatto ordine dei talenti sul db
  aPlayer.xp_Speed         := MyBasePlayer.xp_Speed;
  aPlayer.xp_Defense       := MyBasePlayer.xp_Defense;
  aPlayer.xp_Passing       := MyBasePlayer.xp_Passing;
  aPlayer.xp_BallControl   := MyBasePlayer.xp_BallControl;
  aPlayer.xp_Shot          := MyBasePlayer.xp_Shot;
  aPlayer.xp_Heading       := MyBasePlayer.xp_Heading;

  for IndexTal := 1 to NUM_TALENT do begin
    aPlayer.xpTal[IndexTal]:= aPlayer.xpTal[IndexTal];
  end;

  aPlayer.xpDevA:= MyBasePlayer.xpdevA;
  aPlayer.xpDevT:= MyBasePlayer.xpdevT;
  aPlayer.xpDevI:= MyBasePlayer.xpdevI;

//  Aggiungo e salvo
  lstPlayersDB.add ( aPlayer);
  SaveTeamStream( fm, IntToStr(ToGuidTeam),lstPlayersDB, dirSaves)  ;
  lstPlayersDB.Free;
end;
procedure pveDeleteFromTeam ( fm:Char; guid, GuidTeam : Integer; dirSaves:string); // riscrive es. f16.120
var
  lstPlayersDB: TObjectList<TSoccerPlayer>;
  i: Integer;
  myFile: TextFile;
begin
  lstPlayersDB:= TObjectList<TSoccerPlayer>.Create(true); // lista locale  che elimina tutti gli oggetti

  pveLoadTeam (dirSaves +  fm + IntToStr(GuidTeam) + '.120', fm , GuidTeam, lstPlayersDB ); // ottengo la squadra di destinazione
  // elimino il player e salvo la squadra intera

  for I := lstPlayersDB.count -1 downto 0 do begin
    if lstPlayersDB[i].Ids = IntToStr(guid) then begin
      {$ifdef tools}
        AssignFile(myFile, dirsaves + fm + 'logmarket.txt');
        Append(myFile);
        writeln(myFile, fm + ' ' + IntToStr(GuidTeam) + ' ha licenziato A=' + lstPlayersDB[i].Attributes +' age:' + IntToStr(lstPlayersDB[i].Age) + ' T:' + IntToStr(lstPlayersDB[i].TalentId1));
        CloseFile(myFile);
      {$endif tools}
      lstPlayersDB.Delete(i);
      Break;
    end;
  end;

//  Eliminato il player, salvo
  SaveTeamStream( fm, IntToStr(GuidTeam),lstPlayersDB, dirSaves)  ;
  lstPlayersDB.Free;
end;
procedure pveThinkMarket ( fm :Char; Division: Byte; GuidTeam, dirSaves: string); // effettua pvetransfermarket , dismiss, sell,
var
  lstPlayersDB,lstGK: TObjectList<TSoccerPlayer>;
  aRecordTeam : TTeam;
  i, GenderN,Price,aRnd,Perc,Budget: Integer;
  AHotPlayer: TSoccerPlayer;
  myFile :TextFile;
  label NextEntry,NextEntryGK,skip,skipGK,FINDGK;
begin
// devo usare es. fmarket.120 per visionare chi comprare
// devo usare es. f16.120 per valutare il mio team
  if fm='f' then GenderN :=1
    else GenderN :=2;

  lstPlayersDB:= TObjectList<TSoccerPlayer>.Create(true); // lista locale  che elimina tutti gli oggetti
  // Vedo quanti soldi ho
  aRecordTeam := pveGetTeamInfo (fm, StrToInt(GuidTeam), dirSaves  );
//if (fm = 'm') and (GuidTeam ='18') then
//asm int 3 end;


  // Gestiione GK a parte prima di ogni cosa.
  // se ho più di 2 gk gli altri li vendo tutti
  // se ho 2 gk oltre 30 anni ne cerco uno
  // se ho 1 solo gk ne cerco un altro
  lstGK:= TObjectList<TSoccerPlayer>.Create(false); // false non elimina gli oggetti. li elimino dopo quando ho finito. lsttplayersDb non tocca i file.
  for I := lstPlayersDB.Count -1 downto 0 do begin
    if lstPlayersDB[i].TalentId1 = TALENT_ID_GOALKEEPER then begin
      lstGK.Add(lstPlayersDB[i]);
    end;
  end;
  lstGK.sort(TComparer<TSoccerPlayer>.Construct(function (const L, R: TSoccerPlayer): integer begin Result := L.MarketValue - R.MarketValue; end  ));
  if lstGK.Count > 2 then begin // provo a vendere i piu' deboli ,tutti quelli in eccesso a 2 oppure li licenzio
    for I := 0 to 1 do begin
      pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB );

      AHotPlayer := lstGK[I];
      case lstPlayersDB.Count of
        21..22: begin           // se ho 21-22 player li licenzio
          // licenzio i 2 più devoli. li elimino, se presenti, dal mercato
    NextEntryGK:
            pveDeleteFromTeam(fm, StrToInt(AHotPlayer.ids), StrToInt(GuidTeam), DirSaves  );
            PveDeleteFromMarket (fm, AHotPlayer.ids, dirSaves );
          //  pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB );//ricarico
        end;
        0..20: begin // li metto sul mercato. se è già sul mercato ho il 15% di probabilità di eliminarlo dal mercato e lo licenzio
          if PveOnMarket( fm, AHotPlayer.ids, dirSaves  ) then  begin
            if RndGenerate(100) <= 15 then
              goto NextEntryGK
              else goto skipGK;
          end;

          Price := AHotPlayer.MarketValue;   // il prezzo è casuale in parte
          aRnd := RndGenerate(25); // variazioni tra 1 e 25%
          Perc := (Price * aRnd div 100);
          if RndGenerate(100) <= 50 then begin // - o +
            Price := Price - Perc;
          end
          else begin
            Price := Price + Perc;
          end;
          if pveGetTotalPlayersOnMarket ( fm, StrToInt(GuidTeam) , dirSaves ) < 3 then begin
            pveAddToMarket ( fm, AHotPlayer.ids , GuidTeam, dirSaves, Price );
          end;
        end;

      end;
skipGK:
    end;
  end
  else if lstGK.Count = 1 then begin  // se ho 1 solo gk ne cerco un altro
FindGK:
    if lstPlayersDB.Count = 22 then begin // se 22 player, vendo o licenzio comunque il più debole escludendo il GK
      lstPlayersDB.sort(TComparer<TSoccerPlayer>.Construct(function (const L, R: TSoccerPlayer): integer begin Result := L.MarketValue - R.MarketValue; end  ));

      for I := 0 to lstPlayersDB.Count -1 do begin  // lo licenzio direttamente, ho bisogno del GK
        AHotPlayer:= lstPlayersDB[i];
        if AHotPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin
          pveDeleteFromTeam(fm, StrToInt(AHotPlayer.ids), StrToInt(GuidTeam), DirSaves  );
          PveDeleteFromMarket (fm, AHotPlayer.ids, dirSaves );
         // pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB );//ricarico
          Break;
        end;

      end;

    end;

    Budget := aRecordTeam.money;
    BuyPlayerFromMarket  ( fm , Budget, StrToInt(GuidTeam), TALENT_ID_GOALKEEPER , dirsaves  );// potrebbe entrare anche un GK. nel caso avrò forse 3 gk. la gestione dei gk è sopra
    // potrebbe anche non averlo trovato
  end
  else if lstGK.Count = 2 then begin // se ho 2 gk oltre 30 anni ne cerco uno
    if (lstGK[0].Age >=30 ) and (lstGK[1].Age >=30 ) then
      goto FindGK;

  end;




  lstGK.Free;

  //
  // FINE GESTIONE GK
  // INIZIO GESTIONE PLAYER NORMALI
  //
  //


//  OutputDebugString(PChar(IntToStr(lstPlayersDB[0].MarketValue)));
//  OutputDebugString(PChar(IntToStr(lstPlayersDB[lstPlayersDB.Count-1].MarketValue)));

  // vendo o licenzio i 2 più deboli se ha più di 21 anni e non è un GK e se non è sul mercato
  // se ne ho già 2 sul mercato, li licenzio direttamente
  // se è già sul mercato, lo licenzio

  for I := 0 to 1 do begin
    pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB ); // ricarico il team dopo la gestione GK
    lstPlayersDB.sort(TComparer<TSoccerPlayer>.Construct(function (const L, R: TSoccerPlayer): integer begin Result := L.MarketValue - R.MarketValue; end  ));
    AHotPlayer := lstPlayersDB[I];
    case lstPlayersDB.Count of
      21..22: begin           // se ho 21-22 player li licenzio
        // licenzio i 2 più devoli. li elimino, se presenti, dal mercato
  NextEntry:
        if (AHotPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) and (AHotPlayer.Age >=21) then begin
          pveDeleteFromTeam(fm, StrToInt(AHotPlayer.ids), StrToInt(GuidTeam), DirSaves  );
          PveDeleteFromMarket (fm, AHotPlayer.ids, dirSaves );
          pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB );//ricarico lstPlayersDB.Count
          lstPlayersDB.sort(TComparer<TSoccerPlayer>.Construct(function (const L, R: TSoccerPlayer): integer begin Result := L.MarketValue - R.MarketValue; end  ));
        end;
      end;
      17..20: begin // li metto sul mercato. se è già sul mercato ho il 25% di probabilità di eliminarlo dal mercato e lo licenzio
        if PveOnMarket( fm, AHotPlayer.ids, dirSaves  ) then  begin
          if RndGenerate(100) <= 25 then
            goto NextEntry
            else goto skip; // continue al momento
        end;

        if (AHotPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) and (AHotPlayer.Age >=21) then begin
          Price := AHotPlayer.MarketValue;   // il prezzo è casuale in parte
          aRnd := RndGenerate(25); // variazioni tra 1 e 25%
          Perc := (Price * aRnd div 100);
          if RndGenerate(100) <= 50 then begin // - o +
            Price := Price - Perc;
          end
          else begin
            Price := Price + Perc;
          end;
          if pveGetTotalPlayersOnMarket ( fm, StrToInt(GuidTeam) , dirSaves ) < 3 then
            pveAddToMarket ( fm, AHotPlayer.ids , GuidTeam, dirSaves, Price );

        end;

      end;
      0..16: begin // non faccio nulla, mi concentro sul comprare
        if lstPlayersDB.Count <= 14 then begin // divido per 2 il badget e compro 2 player
          Budget := (aRecordTeam.money div 2)-1;
          BuyPlayerFromMarket  ( fm , Budget, StrToInt(GuidTeam), dirsaves  ) ;// potrebbe entrare anche un GK. nel caso avrò forse 3 gk. la gestione dei gk è sopra
          //pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB );//ricarico
          BuyPlayerFromMarket  ( fm , Budget, StrToInt(GuidTeam),dirsaves  ) ;// potrebbe entrare anche un GK. nel caso avrò forse 3 gk. la gestione dei gk è sopra
          pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB );//ricarico lstPlayersDB.Count
          lstPlayersDB.sort(TComparer<TSoccerPlayer>.Construct(function (const L, R: TSoccerPlayer): integer begin Result := L.MarketValue - R.MarketValue; end  ));
        end
        else begin   // compro 1 player al massimo del mio budget
          Budget := aRecordTeam.money;
          BuyPlayerFromMarket  ( fm , Budget, StrToInt(GuidTeam),dirsaves  );// potrebbe entrare anche un GK. nel caso avrò forse 3 gk. la gestione dei gk è sopra
          pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB );//ricarico lo devo fare lstPlayersDB.Count
          lstPlayersDB.sort(TComparer<TSoccerPlayer>.Construct(function (const L, R: TSoccerPlayer): integer begin Result := L.MarketValue - R.MarketValue; end  ));

        end;

      end;

    end;

skip:
  //  pveLoadTeam( dirSaves + fm + GuidTeam + '.120', fm, StrToInt(GuidTeam),lstPlayersDB ); // ricarico il team . lstPlayersDB.Coun cambia

  end;


end;
function BuyPlayerFromMarket ( fm :Char; Budget,GuidTeam: Integer;  dirSaves: string): Integer; // uguale a pveClientLoadMarket ma non lavora su globale
var
  i,Cur : Integer;
  count,lenSurname: integer;
  lstPLayerMarket: TList<TBasePlayer>;
  aBasePlayer: TBasePlayer;
  Buf3 : TArray32768;
  MM : TMemoryStream;
  datastr : string;
  SS : TStringStream;
begin
  Result := 0;
  FillMemory(@buf3,SizeOf(buf3),0);
  MM := TMemoryStream.Create;
  MM.LoadFromFile( dirSaves  + fm + 'market.120' );
  CopyMemory( @buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  lstPLayerMarket:= TList<TBasePlayer>.Create;

  count := PWORD(@buf3[0])^;  // quanti player . solo in questo caso è smallint
  Cur := Cur + 2; //

  for I:= 0 to Count -1 do begin  // in refresh 20 slot alla volta come countryteam gestita con frecce doppie
   // aBasePlayer.Guid := PDWORD(@buf3[ cur ] )^; // player identificativo globale
    aBasePlayer.Guid :=  PDWORD(@buf3[ cur ])^; // ids servirà per comprare;
    Cur := Cur + 4;

    lenSurname :=  Ord( buf3[ cur ]);
    aBasePlayer.Surname := MidStr( dataStr, cur + 2  , LenSurname );// ragiona in base 1
    cur  := cur + lenSurname + 1;

    aBasePlayer.Age :=   Ord( buf3[ cur ]); // solo age, non matchleseft
    Cur := Cur + 1;

    aBasePlayer.DefaultSpeed := Ord( buf3[ cur ]);  // speed
    Cur := Cur + 1;
    aBasePlayer.DefaultDefense :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultPassing :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultBallControl :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultShot :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultHeading :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aBasePlayer.talentID1 :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.talentID2:=  Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aBasePlayer.Country :=  PWORD(@buf3[ cur ] )^;
    Cur := Cur + 2;

    aBasePlayer.Fitness := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aBasePlayer.GuidTeam := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Face := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Price :=   PDWORD(@buf3[ cur ])^; // sellprice
    Cur := Cur + 4;

    lstPLayerMarket.add (aBasePlayer);
  end;

  lstPLayerMarket.sort(TComparer<TBasePlayer>.Construct(
      function (const L, R: TBasePlayer): integer
      begin
        Result := (L.Price )- (R.price  );
      end
     ));

  for I := lstPLayerMarket.Count -1 downto 0 do begin
    if lstPLayerMarket[i].Price <= Budget then begin
      pveTransferMarket(fm,  lstPLayerMarket[i].Guid, GuidTeam, dirSaves  ); // aggiorna anche money dei 2 team
      Result := lstPLayerMarket[i].Guid;
      lstPLayerMarket.Free;
      Exit;
    end;
  end;

  lstPLayerMarket.Free;

end;
function BuyPlayerFromMarket ( fm :Char; Budget,GuidTeam,TalentId: Integer;  dirSaves: string): Integer; // uguale a pveClientLoadMarket ma non lavora su globale
var
  i,Cur : Integer;
  count,lenSurname: integer;
  lstPLayerMarket: TList<TBasePlayer>;
  aBasePlayer: TBasePlayer;
  Buf3 : TArray32768;
  MM : TMemoryStream;
  datastr : string;
  SS : TStringStream;
begin
  Result := 0;
  MM := TMemoryStream.Create;
  FillMemory(@buf3,SizeOf(buf3),0);
  MM.LoadFromFile( dirSaves  + fm + 'market.120' );
  CopyMemory( @buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  lstPLayerMarket:= TList<TBasePlayer>.Create;

  count := PWORD(@buf3[0])^;  // quanti player . solo in questo caso è smallint
  Cur := Cur + 2; //

  for I:= 0 to Count -1 do begin  // in refresh 20 slot alla volta come countryteam gestita con frecce doppie
   // aBasePlayer.Guid := PDWORD(@buf3[ cur ] )^; // player identificativo globale
    aBasePlayer.Guid :=  PDWORD(@buf3[ cur ])^; // ids servirà per comprare;
    Cur := Cur + 4;

    lenSurname :=  Ord( buf3[ cur ]);
    aBasePlayer.Surname := MidStr( dataStr, cur + 2  , LenSurname );// ragiona in base 1
    cur  := cur + lenSurname + 1;

    aBasePlayer.Age :=   Ord( buf3[ cur ]); // solo age, non matchleseft
    Cur := Cur + 1;

    aBasePlayer.DefaultSpeed := Ord( buf3[ cur ]);  // speed
    Cur := Cur + 1;
    aBasePlayer.DefaultDefense :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultPassing :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultBallControl :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultShot :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultHeading :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aBasePlayer.talentID1 :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.talentID2:=  Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aBasePlayer.Country :=  PWORD(@buf3[ cur ] )^;
    Cur := Cur + 2;

    aBasePlayer.Fitness := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aBasePlayer.GuidTeam := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Face := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Price :=   PDWORD(@buf3[ cur ])^; // sellprice
    Cur := Cur + 4;

    if aBasePlayer.TalentId1 = TalentID then
       lstPLayerMarket.add (aBasePlayer);
  end;

  lstPLayerMarket.sort(TComparer<TBasePlayer>.Construct(
      function (const L, R: TBasePlayer): integer
      begin
        Result := (L.Price )- (R.price  );
      end
     ));

  for I := lstPLayerMarket.Count -1 downto 0 do begin
    if lstPLayerMarket[i].Price <= Budget then begin
      pveTransferMarket(fm,  lstPLayerMarket[i].Guid, GuidTeam, dirSaves  ); // aggiorna anche money dei 2 team
      Result := lstPLayerMarket[i].Guid;
      lstPLayerMarket.Free;
      Exit;
    end;
  end;

  lstPLayerMarket.Free;

end;
function pveGetTotalPlayersOnMarket ( fm :Char; GuidTeam: Integer; dirSaves: string ): Integer;
var
  i,Cur : Integer;
  count,lenSurname: integer;
  lstPLayerMarket: TList<TBasePlayer>;
  aBasePlayer: TBasePlayer;
  Buf3 : TArray32768;
  MM : TMemoryStream;
  datastr : string;
  SS : TStringStream;
begin
  Result := 0;
  FillMemory(@buf3,SizeOf(buf3),0);
  MM := TMemoryStream.Create;
  MM.LoadFromFile( dirSaves  + fm + 'market.120' );
  CopyMemory( @buf3, MM.Memory, MM.Size  ); // metto nel buffer per i comandi non compressi
  SS:= TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  SS.CopyFrom( MM, MM.size );
  dataStr := SS.DataString;
  SS.Free;
  Cur:= 0;

  lstPLayerMarket:= TList<TBasePlayer>.Create;

  count := PWORD(@buf3[0])^;  // quanti player . solo in questo caso è smallint
  Cur := Cur + 2; //

  for I:= 0 to Count -1 do begin  // in refresh 20 slot alla volta come countryteam gestita con frecce doppie
   // aBasePlayer.Guid := PDWORD(@buf3[ cur ] )^; // player identificativo globale
    aBasePlayer.Guid :=  PDWORD(@buf3[ cur ])^; // ids servirà per comprare;
    Cur := Cur + 4;

    lenSurname :=  Ord( buf3[ cur ]);
    aBasePlayer.Surname := MidStr( dataStr, cur + 2  , LenSurname );// ragiona in base 1
    cur  := cur + lenSurname + 1;

    aBasePlayer.Age :=   Ord( buf3[ cur ]); // solo age, non matchleseft
    Cur := Cur + 1;

    aBasePlayer.DefaultSpeed := Ord( buf3[ cur ]);  // speed
    Cur := Cur + 1;
    aBasePlayer.DefaultDefense :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultPassing :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultBallControl :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultShot :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.DefaultHeading :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aBasePlayer.talentID1 :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aBasePlayer.talentID2:=  Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aBasePlayer.Country :=  PWORD(@buf3[ cur ] )^;
    Cur := Cur + 2;

    aBasePlayer.Fitness := Ord( buf3 [ cur ]);
    Cur := Cur + 1;

    aBasePlayer.GuidTeam := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Face := PDWORD(@buf3[ cur ] )^;
    Cur := Cur + 4;

    aBasePlayer.Price :=   PDWORD(@buf3[ cur ])^; // sellprice
    Cur := Cur + 4;

    if aBasePlayer.GuidTeam = GuidTeam then
      result := Result + 1;

  end;

  lstPLayerMarket.Free;

end;
procedure GetBuildInfo(var V1, V2, V3, V4: Word);
var
   VerInfoSize, VerValueSize, Dummy : DWORD;
   VerInfo : Pointer;
   VerValue : PVSFixedFileInfo;
begin
VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
GetMem(VerInfo, VerInfoSize);
GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
With VerValue^ do
begin
  V1 := dwFileVersionMS shr 16;
  V2 := dwFileVersionMS and $FFFF;
  V3 := dwFileVersionLS shr 16;
  V4 := dwFileVersionLS and $FFFF;
end;
FreeMem(VerInfo, VerInfoSize);
end;

// -------------------------------------------------------------------------//

function kfVersionInfo: String;
var
  V1,       // Major Version
  V2,       // Minor Version
  V3,       // Release
  V4: Word; // Build Number
begin
  GetBuildInfo(V1, V2, V3, V4);
  Result := IntToStr(V1) + '.'
            + IntToStr(V2) + '.'
            + IntToStr(V3) + '.'
            + IntToStr(V4);
end;
function GetFitnessModifier ( fitness: integer ): integer;
begin
  case Fitness of
    0: if rndgenerate(50) <= 50 then
      Result := -REGEN_STAMINA;
    1: Result := 0;
    2: if rndgenerate(50) <= 50 then
      Result := +REGEN_STAMINA;
  end;
end;
procedure calc_injured_attribute_lost (var aPlayer: TSoccerPlayer);
var
  aRnd: Integer;
begin

  aRnd := RndGenerate( 100 );
  if aRnd <= aPlayer.devi then begin
    aRnd := RndGenerate0(5);
    case aRnd of
      0: begin
        if aPlayer.DefaultSpeed > 1 then begin
          aPlayer.DefaultSpeed := aPlayer.DefaultSpeed - 1;
          aPlayer.History_Speed := aPlayer.History_Speed - 1;
        end;
      end;
      1: begin
        if aPlayer.DefaultDefense > 1 then begin
          aPlayer.DefaultDefense := aPlayer.DefaultDefense - 1;
          aPlayer.History_Defense := aPlayer.History_Defense - 1;
        end;
      end;
      2: begin
        if aPlayer.DefaultBallControl > 1 then begin
          aPlayer.DefaultBallControl := aPlayer.DefaultBallControl - 1;
          aPlayer.History_BallControl := aPlayer.History_BallControl - 1;
        end;
      end;
      3: begin
        if aPlayer.DefaultPassing > 1 then begin
          aPlayer.DefaultPassing := aPlayer.DefaultPassing - 1;
          aPlayer.History_Passing := aPlayer.History_Passing - 1;
        end;
      end;
      4: begin
        if aPlayer.defaultShot > 1 then begin
          aPlayer.DefaultShot := aPlayer.DefaultShot - 1;
          aPlayer.History_Shot := aPlayer.History_Shot - 1;
        end;
      end;
      5: begin
        if aPlayer.DefaultHeading > 1 then begin
          aPlayer.DefaultHeading := aPlayer.DefaultHeading - 1;
          aPlayer.History_Heading := aPlayer.History_Heading - 1;
        end;
      end;
    end;
  end;


end;
function GetSoccerPlayer ( Guid : Integer; var lstPlayers: TObjectList<TSoccerPlayer>): TSoccerPlayer;
var
  i: Integer;
begin
  Result := nil;
  for I := lstPlayers.Count -1 downto 0 do begin
    if lstPlayers[i].Ids = IntToStr(Guid) then begin
      Result := lstPlayers[i];
      Exit;
    end;

  end;
end;
procedure Calc_Standing ( fm :char; Season, Country, Division: integer; dirSaves : string; var lstTeam: TobjectList<TeamStanding>; var lstScorers: TobjectList<TopScorer> ) ;
var
  ini : TIniFile;
  ts2,tsMatchInfo ,tsSingleMatchInfo: Tstringlist;
  M,R,T,I,ii,g0,g1: Integer;
  aTopScorer : TopScorer;
  found: Boolean;
  label NextRound,done,skiptopScorers;
begin
  lstScorers.Clear;
  ini:= TIniFile.Create(dirSaves + fm + 'S' + Format('%.3d', [Season]) + 'C' + Format('%.3d', [Country]) + 'D' + Format('%.1d', [Division] ) + '.ini') ;

  ts2 := Tstringlist.create;
  ts2.StrictDelimiter := True;

  tsMatchInfo := Tstringlist.create;

  tsSingleMatchInfo := Tstringlist.create;
  tsSingleMatchInfo.StrictDelimiter := True;
  tsSingleMatchInfo.Delimiter := '.';
  // Aggiorno classifica in memoria ts2[0] ts2[2] sono le guid. ts[4] è il risultato  ts[5] matchinfo
  R := 1;
NextRound:
  for M := 1 to DivisionMatchCount[Division] do begin
    ts2.CommaText := ini.ReadString('round' + IntToStr(R), 'match' + IntToStr(M),''  );
    if ts2.Count = 4 then // se non trova il tisultato il round è ancora da giocare. ho finito, esco
    //  goto Done;
    Continue; // mi permette di settare un round più alto per la fase di vebug
     g0 := StrToInt(ExtractWordL (1,ts2[4],'-' ));
     g1 := StrToInt(ExtractWordL (2,ts2[4],'-' ));

      // ts[5] contiene matchinfo  . prima il matchinfo che è unico
    if ts2.Count < 6 then goto skiptopScorers;  // tipico 0-0
    found := False;
    tsMatchInfo.Clear;
    for I := 5 to ts2.Count -1  do begin
      tsMatchInfo.Add( ts2[i] );
    end;

    for I := 0 to tsMatchInfo.Count -1 do begin
      tsSingleMatchInfo.DelimitedText := tsMatchInfo[i];

      if Length (tsSingleMatchInfo.DelimitedText) = 0 then
        Continue; // bug troppi annidamenti

      if Pos('gol',tsSingleMatchInfo[1],1) > 0 then begin
        aTopScorer := TopScorer.Create;
        aTopScorer.Guid := tsSingleMatchInfo[2];
        aTopScorer.Surname := tsSingleMatchInfo[3];
        for Ii := lstScorers.Count -1 downto 0 do begin
          if lstScorers[ii].Guid = aTopScorer.Guid then begin
            lstScorers[ii].Gol := lstScorers[ii].Gol + 1;
            aTopScorer.Free; // non lo aggiungo alla lista
            found := True;
            Break;
          end;
        end;

        if not Found then begin
          aTopScorer.Gol := 1;
          lstScorers.add ( aTopScorer );
        end;

      end;

    end;

skiptopScorers:
    for T := lstTeam.Count -1 downto 0 do begin
      if lstTeam[T].Guid =  StrToInt(ts2[0]) then begin
        if g0 > g1 then begin
          lstTeam[T].Points := lstTeam[T].Points + 3;
        end
        else if g0 = g1 then begin
          lstTeam[T].Points := lstTeam[T].Points + 1;
        end;
      end
      else if lstTeam[T].Guid = StrToInt(ts2[2]) then begin
        if g1 > g0 then begin
          lstTeam[T].Points := lstTeam[T].Points + 3;
        end
        else if g0 = g1 then begin
          lstTeam[T].Points := lstTeam[T].Points + 1;
        end;

      end;

    end;


  end;
  inc (R);
  if not (R = DivisionRoundCount[Division]) then  // se il round è 38 o 30 ho finito
    goto NextRound;

done:
  lstTeam.Sort(TComparer<TeamStanding>.Construct(
    function (const L, R: TeamStanding): integer
    begin
      if R.Points = L.Points then  begin
        if (R.GF-R.GS) = (L.GF-L.GS) then  begin
          if R.GF=L.GF then begin
            Result := CompareValue( L.GS , R.GS); // invertiti , meglio chi ha subito meno gol ( alla fine è sorteggio automatico )
          end
          else Result := CompareValue( R.GF , L.GF);
        end
        else Result := CompareValue((R.GF-R.GS) , (L.GF-L.GS));
      end
      else Result := CompareValue(R.Points, L.Points);

    end
   ));

   // non la salvo, la ricalcolo ogni volta
   //  for T := 1 to lstTeam.Count  do begin // 1 a 20 , no vase 0
//    ini.WriteString('standing' , IntToStr(T) , IntToStr(lstTeam[T-1].guid) + ',' + lstTeam[T-1].Name + ',' + IntToStr(lstTeam[T-1].Points));
//  end;

  lstScorers.Sort(TComparer<TopScorer>.Construct(
    function (const L, R: TopScorer): integer
    begin
      Result := (R.Gol )- (L.Gol  );
    end
   ));

  ts2.Free;
  ini.Free;

end;
procedure EmulationBrain ( aBrain: TSoccerBrain; dirSaves: string);
var
  i,T,aRnd,YellowCount,RedCount,InjuredCount,Injured,absGap,subLeft,subDone: Integer;
  TotMarketValue: array[0..1] of Integer;
  aPlayer,aPlayer2 : TSoccerPlayer;
  mm_W,mm_N,mm_L : TMemoryStream;
  tmpb : Byte;
  g0:Byte;
  g1:Byte;
  lst_W : TList<Byte>;
  lst_N : TList<Byte>;
  lst_L : TList<Byte>;
  lst_W2, lst_L2: TList<Byte>;
  Finalresult : TPoint;
  label retry,team2win,skipsub;
begin
  // il brain è appena formato dalle createformation ma non è partito
  // prendo i 22 titolari in lstsoccerplayer e aggiungo da lstsoccerReserve 6 player (se disponibile) a caso, anche il GK
  // calcolo il marketValue totale dei 2 team 22+6 vs 22+6 e ottengo un risultato base W N L
  // Pesco dalla lista relativa un risultato (se non disponibile lo pesco da un'altra lista, cambierà l'esito, ma siamo in fondo al campionato)
  // Assegno i gol, elimino il risultato dalla Tlist così non lo ripesco in futuro. Salvo la Tlist.

  // non devo assegnare i gol ai player, l'informazione non conta
  // Spargo yellow , red, injured secondo tabelle
  // Spargo xp , xptal, xpdev
  // non faccio altro, il brain verrà finalizzato e poi i team salvati
//  aBrain.lstSoccerReserve[i].itag

  TotMarketValue[0] := 0;
  TotMarketValue[1] := 0;
  //
  //--------------- YELLOW RED INHURED --------------------------------
  //

  for T := 0 to 1 do begin
{$IFDEF  tools}
//    OutputDebugString( PChar( string(aBrain.Score.Team[T])) );
//    OutputDebugString( PChar( IntToStr(aBrain.lstSoccerReserve.Count) ) );
{$endIF  tools}

    // faccio effettivamente la SUB come nel brain
    SubDone := 0;
    subLeft := aBrain.GetTotalReserve(T,true );
    if subLeft = 0 then goto skipsub;
    // o 3 sostituzioni per team o il massimo che si può fare . va bene anche un gk
    while ( SubLeft > 0) do begin
      if SubDone = 3 then
        Break;
      subLeft := aBrain.GetTotalReserve(T,true );  // lo devo aggiornare ogni volta perchè agisce sulle lst ufficiali del brain
      if subLeft = 0 then goto skipsub;


      aPlayer :=  aBrain.GetReservePlayerRandom ( T, true ); // anche GK. ci saranno 2 , è lo stesso, tanto la partita non si gioca
      aPlayer2 := aBrain.GetSoccerPlayerRandom( T, true );

      aBrain.AddSoccerPlayer(aPlayer);
      aBrain.RemoveSoccerReserve(aPlayer);

      aBrain.AddSoccerGameOver(aPlayer2);
      aBrain.RemoveSoccerPlayer(aPlayer2);
      inc ( SubDone );
    end;

  //
  //  ----------MARKETVALUE E SET RAINXP --------------------------------
  //
skipsub:
    for I := 0 to aBrain.lstSoccerPlayer.Count -1 do begin // gli 11 titolari
      if aBrain.lstSoccerPlayer[i].Team = T then begin
        aPlayer:= aBrain.lstSoccerPlayer[i];
        TotMarketValue [T] := TotMarketValue [T] + aBrain.lstSoccerPlayer[i].MarketValue;
        AllRainXp (aPlayer); // xp attributes 12 sparsi, xp_talent valuto, xpDeva+xpdevT 12 sparsi, devi fisso -120 ai panchinari
        if aPlayer.TalentId1 = TALENT_ID_GOALKEEPER then
          aPlayer.Stamina := aPlayer.Stamina - RndGenerate(15)
        else aPlayer.Stamina := aPlayer.Stamina - RndGenerate(30);
      end;
    end;
    for I := 0 to aBrain.lstSoccerGameOver.Count -1 do begin // i 6  o meno sostiutiti sono in gameover
      if aBrain.lstSoccerGameOver[i].Team = T then begin
        aPlayer:= aBrain.lstSoccerGameOver[i];
        TotMarketValue [T] := TotMarketValue [T] + aBrain.lstSoccerGameOver[i].MarketValue;
        AllRainXp (aPlayer); // xp attributes 12 sparsi, xp_talent valuto, xpDeva+xpdevT 12 sparsi, devi fisso -120 ai panchinari
        if aPlayer.TalentId1 = TALENT_ID_GOALKEEPER then
          aPlayer.Stamina := aPlayer.Stamina - RndGenerate(15)
        else aPlayer.Stamina := aPlayer.Stamina - RndGenerate(30);
      end;
    end;

  end;

  for I := 0 to aBrain.lstSoccerReserve.Count -1 do begin // i 6  o meno sostiutiti sono in gameover
    aBrain.lstSoccerReserve[i].xpDevI := aBrain.lstSoccerReserve[i].xpDevI + 120;
  end;

  YellowCount := RndGenerate(72); // 4.4 media a partita
  YellowCount := Trunc(YellowCount / 10);
  while YellowCount > 0 do begin
    OutputDebugString( PChar(aBrain.Score.Team[0] + IntToStr(aBrain.Division) ) );
    OutputDebugString( PChar(aBrain.Score.Team[1] + IntToStr(aBrain.Division) ) );
    aPlayer := aBrain.GetSoccerPlayerRandom3; // uno qualsisai che ha giocato ma non il GK
    aPlayer.YellowCard := aPlayer.YellowCard +1;  // può accadere che un pplayer sia espulso più volte, è lo stesso. oppure che un sostituito sia ammonito o espulso
    if aPlayer.YellowCard = 2 then
      aPlayer.RedCard := 1;
    Dec(YellowCount);
  end;
                                                      // 97 380 0.2.5 1
  aRnd := RndGenerate(100); // 97 a campionato
  if aRnd <= 98 then
    RedCount:=0
    else if aRnd =99 then
      RedCount :=1
    else if aRnd =100 then
      RedCount :=2;


  while RedCount > 0 do begin
    aPlayer := aBrain.GetSoccerPlayerRandom3; // uno qualsisai che ha giocato ma non il GK
    aPlayer.RedCard := 1;  // può accadere che un pplayer sia espulso più volte, è lo stesso. oppure che un sostituito sia ammonito o espulso
    Dec(RedCount);
  end;

  // il TotMarket l'ho preso prima di injured.
  { injured }
  aRnd := RndGenerate(100);
  if aRnd <= 98 then
    InjuredCount:=0
    else if aRnd =99 then
      InjuredCount :=1
    else if aRnd =100 then
      InjuredCount :=2;

  while InjuredCount > 0 do begin
    aPlayer := aBrain.GetSoccerPlayerRandom3; // uno qualsisai che ha giocato ma non il GK
    aRnd := RndGenerate(100); // copiata da finalizebrain
    case aRnd of
      1..70: injured := RndGenerateRange( 1,2 ) ;
      71..90: injured := RndGenerateRange( 3,10 );
      91..99: injured := RndGenerateRange( 11,17 );
      100:begin // possibile perdita attributo
            injured := RndGenerateRange( 18, 38 );
            calc_injured_attribute_lost( aPlayer); // è calc_xp ma in perdita di 1    . Modifica default e history
            // può accadere che un pplayer sia espulso più volte, è lo stesso. oppure che un sostituito sia ammonito o espulso
          end;
    end;

    Dec(InjuredCount);
  end;



  //
  //--------------- ESTRAPOLAZIONE RISULTATO --------------------------------
  //
  // il TotMarketValue l'ho preso prima di injured.
//    if abrain.Division = 1 then begin
//      OutputDebugString(PChar( IntToStr(TotMarketValue[0]) + ' vs ' + IntToStr(TotMarketValue[1]) + '  --> ' + IntToStr(Abs(TotMarketValue[0]-TotMarketValue[1]))  + ' D'+IntTostr(abrain.Division))  );
//      asm Int 3; end;
//    end;

  // Riempo le Tlist<byte>
  // win - null - lost (win away)
  mm_W := TMemoryStream.Create;
  mm_W.LoadFromFile( dirSaves + aBrain.Gender + 'C' + Format('%.3d', [abrain.Country]) + 'D' + Format('%.1d', [aBrain.Division] ) + 'w.120'  ) ;
  mm_N := TMemoryStream.Create;
  mm_N.LoadFromFile( dirSaves + aBrain.Gender + 'C' + Format('%.3d', [abrain.Country]) + 'D' + Format('%.1d', [aBrain.Division] ) + 'n.120'  ) ;
  mm_L := TMemoryStream.Create;
  mm_L.LoadFromFile( dirSaves + aBrain.Gender + 'C' + Format('%.3d', [abrain.Country]) + 'D' + Format('%.1d', [aBrain.Division] ) + 'l.120'  ) ;

  lst_W := TList<Byte>.Create;
  lst_N := TList<Byte>.Create;
  lst_L := TList<Byte>.Create;

  mm_W.Position :=0;
  for I := 0 to mm_W.Size -1 do begin
    mm_W.Read(tmpb,1);
    lst_W.Add( tmpb );
  end;

  mm_N.Position :=0;
  for I := 0 to mm_N.Size -1 do begin
    mm_N.Read(tmpb,1);
    lst_N.Add( tmpb );
  end;

  mm_L.Position :=0;
  for I := 0 to mm_L.Size -1 do begin
    mm_L.Read(tmpb,1);
    lst_L.Add( tmpb );
  end;

  absGap := TotMarketValue[0] - TotMarketValue[1];

  if TotMarketValue[0] >= TotMarketValue[1] then begin       // alla fine i conti devono tornare per i campionati a 20 squadre: 0 byte nei file es. w.120
    lst_W2 := lst_W; // sotto inverto i puntatori nel caso altra squadra vinca , qui li rimetto dritti
    lst_L2 := lst_L;
team2win:
    case absGap of
      0..60000: begin
        aRnd :=  RndGenerate(100);
          case aRnd of
            1..20: begin
              if lst_W2.Count = 0 then begin
                Finalresult.X := RndGenerateRange(2,4);
                Finalresult.Y := RndGenerate0(Finalresult.X-1);
              end
              else begin
                aRnd :=  RndGenerate0(lst_W2.Count -1);
                finalResult := DeleteFromResults ( aRnd, lst_W2);
              end;
            end;
            21..80: begin
              if lst_N.Count = 0 then begin
                Finalresult.X := RndGenerateRange(0,4);
                Finalresult.Y := Finalresult.X;
              end
              else begin
                aRnd :=  RndGenerate0(lst_N.Count -1); // 60% pareggo
                FinalResult := DeleteFromResults ( aRnd, lst_N );
              end;
            end;
            81..100: begin
              if lst_L2.Count = 0 then begin
                Finalresult.Y := RndGenerateRange(2,4);
                Finalresult.X := RndGenerate0(Finalresult.Y-1);
              end
              else begin
                aRnd :=  RndGenerate0(lst_L2.Count -1);
                FinalResult := DeleteFromResults ( aRnd, lst_L2 );
              end;
            end;
          end;
      end;
      60001..110000: begin
        aRnd :=  RndGenerate(100);
          case aRnd of
            1..60: begin
              if lst_W2.Count = 0 then begin
                Finalresult.X := RndGenerateRange(2,4);
                Finalresult.Y := RndGenerate0(Finalresult.X-1);
              end
              else begin
                aRnd :=  RndGenerate0(lst_W2.Count -1);
                finalResult := DeleteFromResults ( aRnd, lst_W2);
              end;
            end;
            61..80: begin
              if lst_N.Count = 0 then begin
                Finalresult.X := RndGenerateRange(0,4);
                Finalresult.Y := Finalresult.X;
              end
              else begin
                aRnd :=  RndGenerate0(lst_N.Count -1); // 60% pareggo
                FinalResult := DeleteFromResults ( aRnd, lst_N );
              end;
            end;
            81..100:begin
              if lst_L2.Count = 0 then begin
                Finalresult.Y := RndGenerateRange(2,4);
                Finalresult.X := RndGenerate0(Finalresult.Y-1);
              end
              else begin
                aRnd :=  RndGenerate0(lst_L2.Count -1);
                FinalResult := DeleteFromResults ( aRnd, lst_L2 );
              end;
            end;
          end;
      end
      else begin
        aRnd :=  RndGenerate(100);
          case aRnd of
            1..80: begin
              if lst_W2.Count = 0 then begin
                Finalresult.X := RndGenerateRange(2,4);
                Finalresult.Y := RndGenerate0(Finalresult.X-1);
              end
              else begin
                aRnd :=  RndGenerate0(lst_W2.Count -1);
                finalResult := DeleteFromResults ( aRnd, lst_W2);
              end;
            end;
            81..90: begin
              if lst_N.Count = 0 then begin
                Finalresult.X := RndGenerateRange(0,4);
                Finalresult.Y := Finalresult.X;
              end
              else begin
                aRnd :=  RndGenerate0(lst_N.Count -1); // 60% pareggo
                FinalResult := DeleteFromResults ( aRnd, lst_N );
              end;
            end;
            91..100: begin
              if lst_L2.Count = 0 then begin
                Finalresult.Y := RndGenerateRange(2,4);
                Finalresult.X := RndGenerate0(Finalresult.Y-1);
              end
              else begin
                aRnd :=  RndGenerate0(lst_L2.Count -1);
                FinalResult := DeleteFromResults ( aRnd, lst_L2 );
              end;
            end;
          end;


      end;
    end;


  end
  {  se è l'altra squadra a vincere , inverto le list W e L}
  else begin
    lst_W2 := lst_L; // inverto i puntatori
    lst_L2 := lst_W;
    goto team2win;
  end;

  // Assegno il risultato , la matchinfo non la creo . apro il file calendar in base a fm season, country, division
  aBrain.Score.gol[0] := Finalresult.X;
  aBrain.Score.gol[1] := Finalresult.Y;
//  UpdateCalendar ( aBrain, dirSaves); lo fa pvefinalizeBrain


  // save
  mm_W.Clear;
  for I := lst_W.Count -1 downto 0 do begin
    tmpb := lst_W[i];
    mm_W.write(@tmpb,1);
  end;
  mm_W.SavetoFile( dirSaves + aBrain.Gender + 'C' + Format('%.3d', [abrain.Country]) + 'D' + Format('%.1d', [aBrain.Division] ) + 'w.120'  ) ;

  mm_N.Clear;
  for I := lst_N.Count -1 downto 0 do begin
    tmpb := lst_N[i];
    mm_N.write(@tmpb,1);
  end;
  mm_N.SavetoFile( dirSaves + aBrain.Gender + 'C' + Format('%.3d', [abrain.Country]) + 'D' + Format('%.1d', [aBrain.Division] ) + 'n.120'  ) ;

  mm_L.Clear;
  for I := lst_L.Count -1 downto 0 do begin
    tmpb := lst_L[i];
    mm_L.write(@tmpb,1);
  end;
  mm_L.SavetoFile( dirSaves + aBrain.Gender + 'C' + Format('%.3d', [abrain.Country]) + 'D' + Format('%.1d', [aBrain.Division] ) + 'l.120'  ) ;




  lst_W.Free;
  lst_N.Free;
  lst_L.Free;

  mm_W.Free;
  mm_N.free;
  mm_L.Free;

end;
function DeleteFromresults ( Index : Integer; var lstByte:TList<Byte> ): TPoint;
begin
  // arnd deve essere pari, elimino 2 byte alla volta.
  if Odd(Index) then
    Index := Index -1; // non può andare a -1, altrimenti è pari cioè 0

  Result.X := lstByte[Index];
  Result.Y := lstByte[Index+1];
  lstByte.Delete(Index+1);
  lstByte.Delete(Index);

end;
procedure AllRainXp ( var aPlayer: TSoccerPlayer);
var
  Xp_Attributes, xpTalents,aRndTalent: Integer;
begin
  if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then  Xp_Attributes := 12
    else  Xp_Attributes := 8;

  while Xp_Attributes > 0 do begin
    if aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER then begin
      if RndGenerate(100) <= 50 then aPlayer.xp_Speed := aPlayer.xp_Speed + 1
      else if RndGenerate(100) <= 50 then aPlayer.xp_Defense := aPlayer.xp_Defense + 1
      else if RndGenerate(100) <= 50 then aPlayer.xp_Passing := aPlayer.xp_Passing + 1
      else if RndGenerate(100) <= 50 then aPlayer.xp_BallControl := aPlayer.xp_BallControl + 1
      else if RndGenerate(100) <= 50 then aPlayer.xp_Shot := aPlayer.xp_Speed + 1
      else if RndGenerate(100) <= 50 then aPlayer.xp_Heading := aPlayer.xp_Heading + 1;
    end
    else begin
      if RndGenerate(100) <= 50 then aPlayer.xp_Defense := aPlayer.xp_Defense + 1
      else if RndGenerate(100) <= 50 then aPlayer.xp_Passing := aPlayer.xp_Passing + 1;
    end;
    dec (Xp_Attributes);
  end;

  aPlayer.xpDevA := RndGenerate(12);
  aPlayer.xpDevT := 12 - aPlayer.xpDevA;

  XpTalents := RndGenerateRange(8,22);
  while XpTalents > 0 do begin
    if Aplayer.TalentId1 = 0 then begin
      aRndTalent := RndGenerateRange(2,24); // evito goalkeeper
      aPlayer.XpTal[ aRndTalent ] := aPlayer.XpTal[aRndTalent]+1;
    end;
    dec (XpTalents);
  end;


end;
procedure CreateNewSeason ( NewSeason , Country : Integer; dirData, dirSaves:string );
var
  I,G,D,T,L: Integer;
  lstTeam: array[1..5] of TobjectList<TeamStanding>;
  lstScorers: array[1..5] of TobjectList<TopScorer>;
  lstTeamTmp: array [1..5] of TobjectList<TeamStanding>;
  lstScorersTmp: array [1..5] of TobjectList<TopScorer>;
  ini : TIniFile;
  ts2 : TStringList;
  aTeamStanding : TeamStanding;
  aTopScorer : TopScorer;
  tsTHISrank: TStringList;
  const GenderS='fm';
begin
  tsTHISrank:= TStringList.create;

  ts2 := Tstringlist.create;
  ts2.StrictDelimiter := True;

  for G := 1 to 2 do begin
    for I := 1 to 5 do begin
      lstTeam[i] := TobjectList<TeamStanding>.Create(True);
      lstScorers[i] := TobjectList<TopScorer>.Create(True);
      lstTeamTmp[i]:= TobjectList<TeamStanding>.Create(false);  // FALSE perchè fa clear
      lstScorersTmp[i] := TobjectList<TopScorer>.Create(True);
    end;




    for D := 5 DownTo 1 do begin
      ini:= TIniFile.Create(dirSaves + genderS[G] + 'S' + Format('%.3d', [NewSeason-1]) + 'C' + Format('%.3d', [Country]) + 'D' + Format('%.1d', [D] ) + '.ini') ;
      for T := 1 to DivisionTeamCount[D] do begin
        ts2.commatext := ini.ReadString('standing' , IntToStr(T) ,''  );
        aTeamStanding:= TeamStanding.Create;
        aTeamStanding.Guid := StrToInt( ts2[0]);
        aTeamStanding.Name := ts2[1];
        aTeamStanding.Points := 0;// StrToInt (ts2[2]);
        lstTeam[D].add ( aTeamStanding );
      end;
      ini.Free;
      Calc_Standing ( genderS[G], NewSeason-1, Country, D, dirSaves, lstTeam[D], lstScorers[D] ) ;  // Classifiche caricate per ogni divisione
    end;

    // Classifiche caricate per ogni divisione

    for D := 5 DownTo 2 do begin // le divisioni vanno da 5 a 2 e si passano sempre le prime e le ultime 4

      //le prime 4 vanno in divisione 4. devo andare a prendere le ultime 4 della divisone 4

      for I := 0 to 3 do begin                    // i primi di ogni divisione in temp
        aTeamStanding:= TeamStanding.Create;
        aTeamStanding.Guid := lstTeam[D].Items[I].Guid;
        aTeamStanding.Name := lstTeam[D].Items[I].Name;
        lstTeamTmp[D].add (aTeamStanding );
      end;

      // gli ultimi della divsione 4 vanno in divisione 5
      L:= -1;
      for I := 0 to 3 do begin
        lstTeam[D].Items[I].guid := lstTeam[D-1].Items[lstTeam[D-1].count +l].guid;
        lstTeam[D].Items[I].name := lstTeam[D-1].Items[lstTeam[D-1].count +l].Name; // Point gd, gs non mi interessano perchè si azzerano
        Dec(l);
      end;


    // Salvo la nuova Division D. Creao i nuovi calendari di questa country (uguali per f e m), ma diversi dal preceente in quanto rimescolo prima la tsTHISrank


      // rimescolo per utilizzare di nuovo il file basecal in dirData
      lstTeam[D].sort(TComparer<TeamStanding>.Construct(
      function (const L, R: TeamStanding): integer
      begin
        if RndGenerate(100) <= 50 then
          Result := -1
          else result := 1;
      end
      ));

      tsTHISrank.Clear;
      for I := 0 to DivisionTeamCount[D] -1 do begin
        tsTHISrank.add ( IntToStr(lstTeam[D].Items[i].Guid) + ',' + lstTeam[D].Items[i].Name );
      end;
      WriteCalendar ( NewSeason, Country, D, DivisionTeamCount[D] ,  tsTHISrank,   dirData, dirSaves  );

      // es. i primi della divisione 5 ( tmp ) vanno in divisione 4
      // che verrà salvata al giro dopo, quando dalla 3 aggiunge alla 4 le retrocesse
      // devo salvare campo per campo , non posso assegnare un pointer di un pointer
      L:= -1;
      for I := 0 to 3 do begin
        lstTeam[D-1].Items[lstTeam[D-1].count +l].Guid := lstTeamTmp[D][I].Guid  ;
        lstTeam[D-1].Items[lstTeam[D-1].count +l].Name := lstTeamTmp[D][I].Name  ; // gf e gs non sono importanti
        Dec(l);
      end;

      // adesso la devo riordinare
      // rimescolo per utilizzare di nuovo il file basecal in dirData
      lstTeam[D].sort(TComparer<TeamStanding>.Construct(
      function (const L, R: TeamStanding): integer
      begin
        Result := R.Points - L.Points;
      end
      ));

    end;
    // fuori dal ciclo scrivo la division 1

      tsTHISrank.Clear;

      // rimescolo per utilizzare di nuovo il file basecal in dirData
      lstTeam[1].sort(TComparer<TeamStanding>.Construct(
      function (const L, R: TeamStanding): integer
      begin
        if RndGenerate(100) <= 50 then
          Result := -1
          else result := 1;
      end
      ));

      for I := 0 to 19 do begin
        tsTHISrank.add ( IntToStr(lstTeam[1].Items[i].Guid) + ',' + lstTeam[1].Items[i].Name );
      end;
      WriteCalendar ( NewSeason, Country, 1, 20 ,  tsTHISrank,   dirData, dirSaves  );

      // qui verranno calcolate le top dopo SORT di nuovo per points


    for I := 1 to 5 do begin   // passo da f a m
      lstTeamTmp[i].Free;
      lstTeam[i].Free;
      lstScorers[i].Free;
      lstScorersTmp[i].Free;
    end;

  end;


  ts2.free;
  tsTHISrank.free;

end;
function GetTeamRecord ( fm :Char; GuidTeam, dirSaves: string  ): TTeam;
var
  MM : TMemoryStream;
  Buf3 : TArray8192;
  Cur : Integer;
begin
      // getTeamrecord
  MM := TMemoryStream.Create;
  MM.LoadFromFile( dirSaves +fm + 'teams.120' );
  CopyMemory( @Buf3, MM.Memory, MM.Size  );
  MM.Free;

  Cur := 0;

  while Cur < MM.Size do begin

    Result.guid := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;
    Result.Money := PDWORD(@buf3 [ cur ])^;
    Cur := Cur + 4;
    Result.Division := ord ( buf3 [ cur ]);
    Cur := Cur + 1;
    Result.YoungQueue := ord ( buf3 [ cur ]);
    Cur := Cur + 1;

    if Result.guid = StrToInt(GuidTeam) then
      Exit;

  end;
end;

procedure MakeDelay ( interval: integer);
var
  start: Integer;
begin
  start := GetTickCount;
  while (GetTickCount - start) < interval do begin
    application.ProcessMessages;

  end;


end;

initialization
  RandGen := TtdCombinedPRNG.Create(0, 0);
  FormationsPreset := TList<TFormation>.Create;
// gender (G) cicla da 1 a 2
  //female
  MoneyBase [1,1,0]:= 1000000;   // minimo e massimo moneybase per divisione fm. (generati alla partenza)
  MoneyBase [1,1,1]:= 6000000;
  MoneyBase [1,2,0]:= 300000;
  MoneyBase [1,2,1]:= 600000;
  MoneyBase [1,3,0]:= 100000;
  MoneyBase [1,3,1]:= 700000;
  MoneyBase [1,4,0]:= 10000;
  MoneyBase [1,4,1]:= 70000;
  MoneyBase [1,5,0]:= 400;
  MoneyBase [1,5,1]:= 1000;

  // Male
  MoneyBase [2,1,0]:= 10000000;   // minimo e massimo moneybase per divisione fm. (generati alla partenza)
  MoneyBase [2,1,1]:= 12000000;
  MoneyBase [2,2,0]:= 1000000;
  MoneyBase [2,2,1]:= 5000000;
  MoneyBase [2,3,0]:= 300000;
  MoneyBase [2,3,1]:= 1200000;
  MoneyBase [2,4,0]:= 50000;
  MoneyBase [2,4,1]:= 120000;
  MoneyBase [2,5,0]:= 1000;
  MoneyBase [2,5,1]:= 5000;

  DivisionMatchCount[1] := 10;
  DivisionMatchCount[2] := 10;
  DivisionMatchCount[3] := 8;
  DivisionMatchCount[4] := 8;
  DivisionMatchCount[5] := 8;

  DivisionRoundCount[1] := 38;
  DivisionRoundCount[2] := 38;
  DivisionRoundCount[3] := 30;
  DivisionRoundCount[4] := 30;
  DivisionRoundCount[5] := 30;

  DivisionTeamCount[1] := 20;
  DivisionTeamCount[2] := 20;
  DivisionTeamCount[3] := 16;
  DivisionTeamCount[4] := 16;
  DivisionTeamCount[5] := 16;

finalization
  FormationsPreset.Free;
  RandGen.Free;
end.
