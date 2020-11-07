unit Server;
// routine principali:
// procedure TcpserverDataAvailable <-- tutti gli input del client passano da qui
// procedure QueueThreadTimer <-- crea le partite(brain) in base agli utenti in coda di attesa
// procedure MatchThreadTimer <-- in caso di bot o disconessione, esegue l'intelligenza artificiale TSoccerBrain.AI_think
// procedure CreateAndLoadMatch <-- crea una partita (brain)
{$R-}

{$DEFINE BOTS}     // se uso i bot o solo partite di player reali
{$DEFINE useMemo}  // se uso il debug a video delle informazioni importanti
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Hash , DateUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Strutils,generics.collections, generics.defaults,
  Vcl.ExtCtrls, Vcl.Mask, Vcl.Grids, inifiles, System.Types, FolderDialog,

  ZLIBEX,
  Soccerbrainv3,
  utilities,
  //  shotcellsv1,
//  AIFieldv1,
//  TVAICrossingAreaCellsv1,

  DSE_theater,
  DSE_SearchFiles,
  DSE_Random,
  DSE_ThreadTimer,
  DSE_GRID,
  DSE_Misc,

  MyAccess, DBAccess, Data.DB,

  OverbyteIcsWndControl, OverbyteIcsWSocket, OverbyteIcsWSocketS, OverbyteIcsWSocketTS, Vcl.ComCtrls ;

const gender ='fm';
const PlayerCountStart = 15;

type TAuthInfo = record                         // usato durante il login in TFormServer.TcpserverDataAvailable
  GmLevel: Integer;                             // gm=1 il client può mandare comandi di utilità come spostare manualmente la palla
  Account: Integer;                             // DB realmd.account.id
  AccountStatus : Integer;                      // 0=login errore, 1=ok login, ma ancora senza team--> selezione team, 2=tutto ok
  GuidTeams: TguidTeams;                            // DB f_game.teams.guid
  TeamName: string;
  WorldTeam: Integer;
  PassWord: string;
  UserName: string;
  Flags: Integer;                               // se devo loggare la partita o no
  nextha: integer;                              // prossima partita in casa o fuori (Home,Away)
  mi : Integer;                                 // media inglese
end;
type TServerOpponent = record
  GuidTeam : integer;
  UserName: string;
  bot : Boolean;
  CliId : Integer;
end;


type TBrainManager = class
  public
  lstBrain: TObjectList<TSoccerBrain>;

  constructor Create( Server: TWSocketThrdServer );
  destructor Destroy;override;
  procedure input (brain: TSoccerBrain; data: string );
    function GetbrainStream ( brain: TSoccerBrain) : string;
  procedure FinalizeBrain (brain: TSoccerBrain );
    procedure DecodeBrainIds ( brainIds: string; var MyYear, MyMonth, MyDay, MyHour, MyMin, MySec: string );
      function RndGenerate( Upper: integer ): integer;
      function RndGenerate0( Upper: integer ): integer;
      function RndGenerateRange( Lower, Upper: integer ): integer;

  function FindBrain ( ids: string  ): TSoccerbrain;  overload;
  function FindBrain ( CliId: integer ): TSoccerbrain; overload;
  procedure AddBrain ( brain: TSoccerbrain );
  procedure RemoveBrain ( brainIds: string);
end;
type
  TFormServer = class(TForm)
    Tcpserver: TWSocketThrdServer;
    Memo1: TMemo;
    Label1: TLabel;
    btnKillAllBrain: TButton;
    btnStopAllBrain: TButton;
    btnStartAllBrain: TButton;
    Button1: TButton;
    QueueThread: SE_ThreadTimer;
    MatchThread: SE_ThreadTimer;
    Button2: TButton;
    threadBot: SE_ThreadTimer;
    Button3: TButton;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Label3: TLabel;
    CheckBox2: TCheckBox;
    CheckBoxActiveMacthes: TCheckBox;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    edit4: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Panel1: TPanel;
    Button5: TButton;
    Edit5: TEdit;
    Edit6: TEdit;
    Button6: TButton;
    FolderDialog1: TFolderDialog;
    Button7: TButton;
    Button8: TButton;
    StringGrid1: TStringGrid;
    Button4: TButton;
    Button9: TButton;
    Edit7: TEdit;
    Edit8: TEdit;
    Button10: TButton;
    ProgressBar1: TProgressBar;
    Memo2: TMemo;
    Button11: TButton;
    Button12: TButton;

    procedure FormCreate(Sender: TObject);
      procedure CleanDirectory(dir:string);
    procedure FormDestroy(Sender: TObject);
    procedure LoadPreset;
    // tcp
    procedure TcpserverBgException(Sender: TObject; E: Exception; var CanClose: Boolean);
    procedure TcpserverClientConnect(Sender: TObject; Client: TWSocketClient; Error: Word);
    procedure TcpserverClientDisconnect(Sender: TObject; Client: TWSocketClient; Error: Word);
    procedure TcpserverDataAvailable(Sender: TObject; ErrCode: Word);
    procedure TcpserverException(Sender: TObject; SocExcept: ESocketException);
    procedure TcpserverLineLimitExceeded(Sender: TObject; RcvdLength: Integer; var ClearData: Boolean);
    procedure TcpserverThreadException(Sender: TObject; AThread: TWsClientThread; const AErrMsg: string);
    procedure TcpserverError(Sender: TObject);
    procedure TcpserverSocksError(Sender: TObject; Error: Integer; Msg: string);

    Function CheckAuth ( UserName, Password: string): TAuthInfo;
    function CreateGameTeam ( fm :char; cli: TWSocketThrdClient;  WorldTeamGuid: string): integer;


    function GetQueueOpponent ( fm : Char; WorldTeam : integer; Rank, NextHA: byte ): TWSocketThrdClient;  // rank < > 1 = tolleranza
    procedure GetGuidTeamOpponentBOT (fm :Char; WorldTeam : integer; Rank, NextHA: byte; var BotGuidTeam: Integer; var BotUserName: string ); // rank < > 1 = tolleranza
    function GetTCPClient ( CliId: integer): TWSocketClient;
    function GetTCPClientQueue ( CliId: integer): TWSocketClient;
    procedure QueueThreadTimer(Sender: TObject);
      function GetbrainIds ( fm :Char; GuidTeam0, GuidTeam1: string ) : string;
    procedure MatchThreadTimer(Sender: TObject);
    procedure btnKillAllBrainClick(Sender: TObject);
    procedure btnStopAllBrainClick(Sender: TObject);
    procedure btnStartAllBrainClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure threadBotTimer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
  private
    { Private declarations }
    procedure Display(Msg : String);

    (* validazione input dal client di gioco*)
    procedure validate_login ( const CommaText: string; Cli:TWSocketThrdClient );
      function LastIncMoveIni ( directory: string ): string;
    procedure validate_getteamsbycountry ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_clientcreateteam  ( const CommaText: string;  Cli:TWSocketThrdClient) ;
    procedure validate_viewMatch  ( const CommaText: string;  Cli:TWSocketThrdClient) ;
    procedure validate_levelupAttribute ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_levelupTalent ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMDlop ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD4 ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD3 ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_debug_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient );

    procedure validate_CMD1 ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD_coa ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD_cod ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD_bar ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD_subs ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_aiteam ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_setplayer ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_pause ( const CommaText: string; Cli:TWSocketThrdClient );

    procedure validate_setformation ( CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_setuniform ( CommaText: string; Cli:TWSocketThrdClient );
    function validate_player ( const guid: integer; Cli:TWSocketThrdClient): TValidPlayer;
    procedure validate_sell ( commatext: string; Cli:TWSocketThrdClient  );
    procedure validate_cancelsell ( commatext: string; Cli:TWSocketThrdClient  );
    procedure validate_buy ( commatext: string; Cli:TWSocketThrdClient  );
    procedure validate_market ( commatext: string; Cli:TWSocketThrdClient  );
    procedure validate_dismiss ( commatext: string; Cli:TWSocketThrdClient  );
    procedure reset_formation ( Cli:TWSocketThrdClient ); overload;
    procedure reset_formation ( fm : Char;GuidTeam: integer ); overload;

    function checkformation ( Cli:TWSocketThrdClient ): Boolean;
    procedure store_formation ( fm : Char; CommaText: string );
    procedure store_Uniform ( Guidteam: integer; CommaText: string );


    // mercato player
    procedure MarketSell ( Cli: TWSocketThrdClient; CommaText: string  );
    procedure MarketCancelSell ( Cli: TWSocketThrdClient; CommaText: string  );
    procedure DismissPlayer ( Cli: TWSocketThrdClient; CommaText: string  );
    procedure MarketBuy ( Cli: TWSocketThrdClient; CommaText: string  );
    function TryAddYoung ( fm :Char; GuidTeam: Integer): Boolean;

    function CalculateRank ( mi : integer): Integer;

    function RandomPassword(PLen: Integer): string; // deprecated
    function RndGenerate( Upper: integer ): integer;
    function RndGenerate0( Upper: integer ): integer;
    function RndGenerateRange( Lower, Upper: integer ): integer;

    function RemoveFromQueue(Cliid: integer ): Boolean;
    function inQueue(Cliid: integer ): Boolean;
    function inSpectator(Cliid: integer ): boolean;
    function inLiveMatchCliid(Cliid: integer ): Boolean;
    function inLivematchGuidTeam(fm : char;GuidTeam: integer ): TSoccerBrain;
    function inSpectatorGetBrain(Cliid: integer ): TSoccerBrain;
    function RemoveFromSpectator(Cliid: integer ): boolean;

    procedure CreateAndLoadMatch ( fm:Char; brain: TSoccerBrain; GuidTeam0, GuidTeam1: integer; Username0, UserName1: string  );
    procedure CreateMatchBOTvsBOT ( fm:Char;  GuidTeam0, GuidTeam1: integer; Username0, UserName1: string );
      function CreateRandomPlayer ( fm :Char; Country: integer; EnableTalent2: boolean ) : TBasePlayer;
      function CreatePresetPlayer ( fm :Char; Country, index: integer ) : TBasePlayer;
      function CreateSurname ( fm : Char; Country: Integer ): string;

    procedure CreateRandomBotMatch ( fm :char) ;
    procedure CreateRewards;


  public

    procedure SetupRefreshGrid;
    (* procedure che si attivano solo al primo login o comunque se l'account non ha ancora scelto la sua squadra del cuore *)
    procedure PrepareWorldCountries ( directory: string ); overload;
    procedure PrepareWorldCountries ; overload;
    procedure PrepareWorldTeams( directory, CountryID: string );overload;
    procedure PrepareNationTeams( CountryID: integer; var TsNationTeam: TStringList  );
    procedure PrepareWorldTeams( CountryID: integer ); overload;


    function GetTeamStream ( GuidTeam: Integer; fm :char): string; // dati compressi del proprio team
    function GetListActiveBrainStream (fm : Char) : string;
    function GetMarketPlayers (fm: Char; Myteam, Maxvalue: Integer): string;
  end;

const EndofLine = 'ENDSOCCER';
const GLOBAL_COOLDOWN = 200;  // 200 misslisecondi tra un input e l'altro del client, altrimenti è spam/cheating
const MIN_DEVA=5; MIN_DEVT = 5; MIN_DEVI =1; MAX_DEVA=30; MAX_DEVT=30; MAX_DEVI=20;

var
  FormServer: TFormServer;
  BrainManager: TBrainManager;
  TsWorldCountries: TStringList;
  TsWorldTeams: array [1..5] of TStringList; // le nazioni del DB world

  Queue: TObjectList<TWSocketThrdClient>;
  RandGen: TtdBasePRNG;
  Mutex,MutexMarket,MutexLockbrain: cardinal;
  dir_log: string;
  MySqlServerGame,  MySqlServerWorld,  MySqlServerAccount: string; // le 3 tabelle del DB: account, world e Game
                                                                   // world contiene le definizioni come i nomi delle squadre e i cognomi dei player
  Rewards : array [1..4, 1..20] of Integer;
  mfaces : array[1..6] of Integer;
  ffaces : array[1..6] of Integer;

  mp_template: array [0..PlayerCountStart-1] of Integer;
  PresetF : array[0..PlayerCountStart-1] of string;
  PresetM : array[0..PlayerCountStart-1] of string;
  PresetFT : array[0..PlayerCountStart-1] of byte;
  PresetMT : array[0..PlayerCountStart-1] of byte;


implementation

{$R *.dfm}

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
function IsStandardText(const aValue: string): Boolean; // accetta solo certi caratteri in input dal client
const
  CHARS = ['0'..'9', 'a'..'z', 'A'..'Z', ',', ':','=','.','_' ,'-' ];
var
  i: Integer;
  aString: string;
begin
  aString := aValue.Trim;
  for i := 1 to Length(aString) do begin
    if not (aString[i] in CHARS) then begin
      Result := False;
      Exit;
    end;
  end;
  Result := true;
end;
function GetStrHashSHA1(Str: String): String;  // decodifica password DB
var
  HashSHA: THashSHA1;
begin
    HashSHA := THashSHA1.Create;
    HashSHA.GetHashString(Str);
    result := HashSHA.GetHashString(Str);
end;
function TryDecimalStrToInt( const S: string; out Value: Integer): Boolean;
begin
   result := ( pos( '$', S ) = 0 ) and TryStrToInt( S, Value );
end;
procedure TFormServer.RadioButton1Click(Sender: TObject);
begin
  if RadioButton1.Checked then
    edit3.Visible := False
    else edit3.Visible := True;
end;

procedure TFormServer.RadioButton2Click(Sender: TObject);
begin
  if RadioButton2.Checked then begin
    edit2.Visible := true;
    edit3.Visible := True;
  end
  else edit3.visible := False;

end;

function TFormServer.RandomPassword(PLen: Integer): string;
var
  str: string;
begin
  Randomize;
  //string with all possible chars
  str    := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  Result := '';
  repeat
    Result := Result + str[RndGenerate(Length(str)) ];
  until (Length(Result) = PLen)
end;
procedure TFormServer.btnKillAllBrainClick(Sender: TObject);
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  for I := brainManager.lstBrain.Count -1 downto 0 do begin
    brainManager.RemoveBrain ( BrainManager.lstBrain[i].BrainIDS );
  end;
  ReleaseMutex(Mutex);

end;

procedure TFormServer.SetupRefreshGrid;
var
  y: Integer;
begin
  StringGrid1.RowCount := 1;
  StringGrid1.RowCount := BrainManager.lstBrain.Count;
  StringGrid1.ColCount := 10;
  StringGrid1.ColWidths[0] := 220;
  StringGrid1.ColWidths[1] := 220;
  StringGrid1.ColWidths[2] := 50;
  StringGrid1.ColWidths[3] := 50;
  StringGrid1.ColWidths[4] := 60;
  StringGrid1.ColWidths[5] := 60;
  StringGrid1.ColWidths[6] := 50;
  StringGrid1.ColWidths[7] := 50;
  StringGrid1.ColWidths[8] := 70;
  StringGrid1.ColWidths[9] := 20;
end;

procedure TFormServer.btnStartAllBrainClick(Sender: TObject);
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  for I := brainManager.lstBrain.Count -1 downto 0 do  begin
    brainManager.lstBrain[i].Paused := false;
  end;
  ReleaseMutex(Mutex);
end;

procedure TFormServer.btnStopAllBrainClick(Sender: TObject);
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  for I := brainManager.lstBrain.Count -1 downto 0 do  begin
    brainManager.lstBrain[i].Paused := True;
  end;
  ReleaseMutex(Mutex);

end;

procedure TFormServer.Button10Click(Sender: TObject);
var
  mValue,T,G : Integer;
  price: Integer;
  ConnGame : TMyConnection ;
  qTeams, qPlayers,qMarket,qPlayersGK: TMyQuery ;
  label NextTeam;
begin

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= 'f_game';
  Conngame.Connected := True;

  qTeams := TMyQuery.Create(nil);
  qTeams.Connection := ConnGame;   // game

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayersGK := TMyQuery.Create(nil);
  qPlayersGK.Connection := ConnGame;   // game
  qMarket := TMyQuery.Create(nil);
  qMarket.Connection := ConnGame;   // game

  ProgressBar1.Position := 0 ;

  for G := 1 to 2 do begin

    qTeams.SQL.text := 'SELECT guid from ' + Gender[G]+ '_game.teams';
    qTeams.Execute ;

    for T := 0 to qTeams.RecordCount -1 do begin

      qPlayers.SQL.text := 'SELECT * from ' + Gender[G]+ '_game.players WHERE onmarket=0 and team=' +
                                    qTeams.FieldByName('guid').AsString +' and young=0 order by rand() limit 1';
      qPlayers.Execute ;

    // non deve essere presente sul mercato
      qMarket.SQL.text := 'SELECT guid from '+Gender[G]+'_game.market WHERE guid =' + qPlayers.FieldByName('guid').AsString ;
      qMarket.Execute ;
      if qMarket.RecordCount > 0 then goto NextTeam;  // non posso venderlo, non faccio nulla

    // sul mercato massimo 3 player

      qMarket.SQL.text := 'SELECT guid from '+Gender[G]+'_game.market WHERE guidteam =' + qTeams.FieldByName('guid').AsString;
      qMarket.Execute ;
      if qMarket.RecordCount >= 3 then goto NextTeam;  // non posso venderlo, non faccio nulla

      if qPlayers.FieldByName('talentid1').AsInteger <> TALENT_ID_GOALKEEPER then  // non un goalkeeper (portiere) o senza talento o con talento

      mValue :=  Trunc ( qPlayers.FieldByName('speed').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('speed').AsInteger] +
                 qPlayers.FieldByName('defense').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('defense').AsInteger] +
                 qPlayers.FieldByName('passing').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('passing').AsInteger] +
                 qPlayers.FieldByName('ballcontrol').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('ballcontrol').AsInteger] +
                 qPlayers.FieldByName('shot').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('shot').AsInteger] +
                 qPlayers.FieldByName('heading').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('heading').AsInteger])

      else if qPlayers.FieldByName('talentid1').AsInteger = TALENT_ID_GOALKEEPER then begin  // un portiere

      mValue :=  Trunc ((qPlayers.FieldByName('defense').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('defense').AsInteger] * MARKET_VALUE_ATTRIBUTE_DEFENSE_GK) +
                 qPlayers.FieldByName('passing').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('passing').AsInteger]  );


        // è un goalkeeper, se è l'unico non posso venderlo . se ce nes sono di più, ce ne deve essere almeno 1 non sul mercato
        qPlayersGK.SQL.text := 'SELECT * from ' + Gender[G]+'_game.players WHERE talentid1=1 ' +
                               'and guid <>' + qPlayers.FieldByName('guid').AsString +
                                           ' and onmarket=0 and team=' + qTeams.FieldByName('guid').AsString + ' and young=0';
        qPlayersGK.Execute ;

        if qPlayersGK.RecordCount = 0 then goto NextTeam;  // non posso venderlo, non faccio nulla


      end;

      if qPlayers.FieldByName('talentid1').AsInteger  <> 0 then mValue := Trunc (mValue  *  MARKET_VALUE_TALENT1) ; //se c'è un talento, anche goalkeeper
      if qPlayers.FieldByName('talentid2').AsInteger  <> 0 then mValue := mValue + Trunc (mValue  *  MARKET_VALUE_TALENT2) ;


      // update f_game.players onmarket e market con tutti i dati attuali e congelati qui
      qMarket.SQL.text := 'INSERT INTO '+Gender[G]+'_game.market (speed,defense,passing,ballcontrol,shot,heading,talentid1,talentid2,'+
                                'matches_played,matches_left,name,guidteam,guidplayer,face,sellprice,history,xp,country,fitness,morale) VALUES ('+
                                 qPlayers.FieldByName('speed').AsString +
                                ',' + qPlayers.FieldByName('defense').AsString +
                                ',' + qPlayers.FieldByName('passing').AsString +
                                ',' + qPlayers.FieldByName('ballcontrol').AsString +
                                ',' + qPlayers.FieldByName('shot').AsString +
                                ',' + qPlayers.FieldByName('heading').AsString +
                                ',' + qPlayers.FieldByName('talentid1').AsString +
                                ',' + qPlayers.FieldByName('talentid2').AsString +
                                ',' + qPlayers.FieldByName('matches_played').AsString +
                                ',' + qPlayers.FieldByName('matches_left').AsString +
                                ',"' + qPlayers.FieldByName('name').AsString + '"'+
                                ',' + qPlayers.FieldByName('team').AsString + // guidteam
                                ',' + qPlayers.FieldByName('guid').AsString + // guidplayer
                                ',' + qPlayers.FieldByName('face').AsString + // face
                                ',' + IntToStr(mValue) + // price
                                ',"' + qPlayers.FieldByName('history').AsString + '"'+
                                ',"' + qPlayers.FieldByName('xp').AsString + '"'+
                                ',' + qPlayers.FieldByName('country').AsString +
                                ',' + qPlayers.FieldByName('fitness').AsString +
                                ',' + qPlayers.FieldByName('morale').AsString
                                + ')';
      qMarket.Execute ;

      qPlayers.SQL.text := 'UPDATE '+Gender[G]+'_game.players set onmarket=1 WHERE guid =' +  qPlayers.FieldByName('guid').AsString +
                            ' and team=' + qTeams.FieldByName('guid').AsString ; // per essere sicuri anche cli.guidteam
      qPlayers.Execute ;

NextTeam:
      qTeams.Next;
      ProgressBar1.Position := (100* t) div qTeams.RecordCount ;

    end;
  end;
  qTeams.Free;
  qPlayers.Free;
  qPlayersGK.Free;
  qMarket.Free;


  Conngame.Connected := False;
  Conngame.Free;

  ProgressBar1.Position := 0 ;
  ShowMessage ('Done!');

end;

procedure TFormServer.Button1Click(Sender: TObject);
var
  MyQueryAccount: TMyQuery ;
  sha_pass_hash: string;
  i: Integer;
  UserName,password : string;
  cli: TWSocketThrdClient;
  ConnAccount : TMyConnection ;
  label createteam;
begin

  ConnAccount := TMyConnection.Create(nil);
  ConnAccount.Server := MySqlServerAccount;
  ConnAccount.Username:='root';
  ConnAccount.Password:='root';
  ConnAccount.Database:='realmd';
  ConnAccount.Connected := True;

  MyQueryAccount := TMyQuery.Create(nil);
  MyQueryAccount.Connection := ConnAccount;   // realmd

  // genero test1, test2, test3 ecc....
  for I := 1 to 300 do begin

    username :=  Uppercase('TEST' + IntTostr(i));
    password := UserName;
    sha_pass_hash := GetStrHashSHA1 ( username + ':' + Password );
    MyQueryAccount.SQL.Text := 'insert into realmd.account (username, sha_pass_hash, email)  values (' +
                                 '"' + username + '","' +  sha_pass_hash  + '","' +  UserName +'.GMAIL.COM")';

    MyQueryAccount.Execute;
    ProgressBar1.Position := (100* i) div 300 ;
    application.ProcessMessages;
  end;

  MyQueryAccount.free;
  ConnAccount.Connected:= False;
  ConnAccount.Free;
  ShowMessage ('Done!');
  ProgressBar1.Position := 0;


end;

Function TFormServer.CheckAuth ( UserName, Password: string): TAuthInfo;
var
  MyQueryAccount,MyQueryTeam:  TMyQuery ;
  sha_pass_hash: string;
  AccountID: string;
  GmLevel: Integer;
  ConnAccount,ConnGame : TMyConnection  ;
begin
  sha_pass_hash := GetStrHashSHA1 ( Uppercase(UserName) + ':' + Uppercase(Password));


  ConnAccount := TMyConnection.Create(nil);
  ConnAccount.Server := MySqlServerAccount;
  ConnAccount.Username:='root';
  ConnAccount.Password:='root';
  ConnAccount.Database:='realmd';
  ConnAccount.Connected := True;

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='f_game';
  Conngame.Connected := True;

  MyQueryAccount := TMyQuery.Create(nil);
  MyQueryAccount.Connection := ConnAccount;   // realmd
  MyQueryAccount.SQL.Text := 'SELECT id, username, gmlevel, flags FROM realmd.account where username = "' + UserName +
                                                  '" AND sha_pass_hash = "' + sha_pass_hash +'"';
  MyQueryAccount.Execute;



  if MyQueryAccount.RecordCount = 1 then begin
    AccountID := MyQueryAccount.FieldByName('id').AsString ;
    GmLevel:= MyQueryAccount.FieldByName('gmLevel').AsInteger;

    MyQueryTeam := TMyQuery.Create(nil);
    MyQueryTeam.Connection := Conngame;   // game
    MyQueryTeam.SQL.Text := 'SELECT  guid, worldteam, teamname, nextha, mi FROM f_game.teams where account = ' + AccountID ;  // teamid punta a world.team (e country in join)
    MyQueryTeam.Execute;


    if MyQueryTeam.RecordCount = 1 then begin       // ho già il team
      Result.Account := StrToInt(AccountId);
      Result.AccountStatus  := 2;
      Result.GuidTeams[1]  := MyQueryTeam.FieldByName ('guid').AsInteger ;
      Result.WorldTeam  := MyQueryTeam.FieldByName ('worldteam').AsInteger ;
      Result.TeamName  := MyQueryTeam.FieldByName ('teamname').AsString ;
      Result.username  := MyQueryAccount.FieldByName ('username').AsString ;
      Result.flags  := MyQueryAccount.FieldByName ('flags').AsInteger ;
      Result.nextha  := MyQueryTeam.FieldByName ('nextha').AsInteger ;
      Result.mi  := MyQueryTeam.FieldByName ('mi').AsInteger ;
      Result.Password := Password;
      Result.GmLevel := GmLevel;
    end
    else if MyQueryTeam.RecordCount = 0 then begin   // ok login, ma senza team --> selezione team
      Result.Account := StrToInt(AccountId);
      Result.AccountStatus  := 1;
      Result.GuidTeams[1]  := 0;
      Result.Password := Password;
      Result.username  := MyQueryAccount.FieldByName ('username').AsString ;
      Result.flags  := MyQueryAccount.FieldByName ('flags').AsInteger ;
      Result.GmLevel := GmLevel;
    end;
    MyQueryTeam.Free;
  end
  else if MyQueryAccount.RecordCount = 0 then begin   // login incorrect
      Result.Account := 0;
      Result.GuidTeams[1] := 0;
      Result.AccountStatus := 0;
      Result.Password := '';
      Result.username  := '';
      Result.GmLevel := 0;
  end;

  // ripero per reparto maschile


  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='m_game';
  Conngame.Connected := True;


  if MyQueryAccount.RecordCount = 1 then begin
    AccountID := MyQueryAccount.FieldByName('id').AsString ;
    GmLevel:= MyQueryAccount.FieldByName('gmLevel').AsInteger;

    MyQueryTeam := TMyQuery.Create(nil);
    MyQueryTeam.Connection := Conngame;   // game
    MyQueryTeam.SQL.Text := 'SELECT  guid, worldteam, teamname, nextha, mi FROM m_game.teams where account = ' + AccountID ;  // teamid punta a world.team (e country in join)
    MyQueryTeam.Execute;

    if MyQueryTeam.RecordCount = 1 then begin       // ho già il team
      Result.Account := StrToInt(AccountId);
      Result.AccountStatus  := 2;
      Result.GuidTeams[2]  := MyQueryTeam.FieldByName ('guid').AsInteger ;
      Result.WorldTeam  := MyQueryTeam.FieldByName ('worldteam').AsInteger ;
      Result.TeamName  := MyQueryTeam.FieldByName ('teamname').AsString ;
      Result.username  := MyQueryAccount.FieldByName ('username').AsString ;
      Result.flags  := MyQueryAccount.FieldByName ('flags').AsInteger ;
      Result.nextha  := MyQueryTeam.FieldByName ('nextha').AsInteger ;
      Result.mi  := MyQueryTeam.FieldByName ('mi').AsInteger ;
      Result.Password := Password;
      Result.GmLevel := GmLevel;
    end
    else if MyQueryTeam.RecordCount = 0 then begin   // ok login, ma senza team --> selezione team
      Result.Account := StrToInt(AccountId);
      Result.AccountStatus  := 1;
      Result.GuidTeams[2]  := 0;
      Result.Password := Password;
      Result.username  := MyQueryAccount.FieldByName ('username').AsString ;
      Result.flags  := MyQueryAccount.FieldByName ('flags').AsInteger ;
      Result.GmLevel := GmLevel;
    end;
    MyQueryTeam.Free;
  end
  else if MyQueryAccount.RecordCount = 0 then begin   // login incorrect
      Result.Account := 0;
      Result.GuidTeams[2] := 0;
      Result.AccountStatus := 0;
      Result.Password := '';
      Result.username  := '';
      Result.GmLevel := 0;
  end;

  MyQueryAccount.Free;
  ConnAccount.Connected:= False;
  ConnAccount.Free;
  Conngame.Connected:= False;
  Conngame.Free;

end;

procedure TFormServer.CheckBox2Click(Sender: TObject);
var
  I: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  for I := brainManager.lstBrain.Count -1 downto 0 do  begin
    brainManager.lstBrain[i].LogUser [0]:= 1;
    brainManager.lstBrain[i].LogUser [1]:= 1;
  end;
  ReleaseMutex(Mutex);

end;

constructor TBrainManager.Create( Server: TWSocketThrdServer );
begin
  lstBrain:= TObjectList<TSoccerBrain>.Create(true);
{  ShotCells := CreateShotCells;
  AIField := createAIfield;
	TVCrossingAreaCells:= TVCreateCrossingAreaCells;
	AICrossingAreaCells:= AICreateCrossingAreaCells; }

//  CreateShotCells;
//  createAIfield;
//	TVCreateCrossingAreaCells;
//	AICreateCrossingAreaCells;

end;
destructor TBrainManager.Destroy;
begin
//  ShotCells.Free;
  lstbrain.free;
  inherited;
end;

procedure TBrainManager.input ( brain: TSoccerBrain; data: string );
var
  i,ii,SpectatorCliId: Integer;
  NewData: string;
  MyQueryCheat: TMyQuery;
  ConnAccount : TMyConnection;
begin

  if LeftStr(Data,6) = 'cheat:' then begin
          // uguale al primo check validate

    ConnAccount := TMyConnection.Create(nil);
    ConnAccount.Server := MySqlServerAccount;
    ConnAccount.Username:='root';
    ConnAccount.Password:='root';
    ConnAccount.Database:='realmd';
    ConnAccount.Connected := True;

    MyQueryCheat := TMyQuery.Create(nil);

    MyQueryCheat.Connection := ConnAccount;
    MyQueryCheat.SQL.Text :='INSERT into cheat_detected (reason,minute,brainids) values ("' + data + '","' +
                               IntToStr(brain.Minute )+'","' + brain.brainIds +'")'  ;
    MyQueryCheat.Execute;
    MyQueryCheat.Free;
    ConnAccount.Connected:= False;
    ConnAccount.Free;
  end
  else if  Data = 'FINALIZE' then begin
      Finalizebrain ( brain );
     // RemoveBrain( brain.brainIds );   { se lo faccio bug, c'era PASS o altri comandi in essere. il brain esegue ancora tsscript, lo faccio dopo 30 secondi }
  end                                 // lo marco per il delete successivo
  else begin
      // prima i client che giocano
      try
        for I := 0 to FormServer.Tcpserver.ClientCount -1 do begin
          if FormServer.TcpServer.Client [i].CliId = brain.Score.CliId [0] then begin
              NewData := 'BEGINBRAIN' + AnsiChar( StrToInt(data)  ) + GetBrainStream ( brain );
              FormServer.TcpServer.Client [i].SendStr ( NewData + EndofLine);
              FormServer.Memo1.Lines.Add( '> BEGINBRAIN ' +IntToStr(brain.incMove)  );
          end
          else if FormServer.TcpServer.Client [i].CliId = brain.Score.CliId [1] then begin
              NewData := 'BEGINBRAIN' + AnsiChar( StrToInt(data)  ) + GetBrainStream ( brain );
              FormServer.TcpServer.Client [i].SendStr ( NewData + EndofLine);
              FormServer.Memo1.Lines.Add( '> BEGINBRAIN ' +IntToStr(brain.incMove)  );
          end;
        end;

        // poi gli spettatori
        for I := 0 to brain.lstSpectator.Count -1  do begin
           (* Per ogni spettatore ricerco nei TcpClient lo stesso CliID*)
            SpectatorCliId := brain.lstSpectator[i];
            for ii := 0 to FormServer.Tcpserver.ClientCount -1 do begin

              if FormServer.TcpServer.Client [ii].CliId = SpectatorCliId then begin
              NewData := 'BEGINBRAIN' + AnsiChar( StrToInt(data)  ) + GetBrainStream ( brain );
                FormServer.TcpServer.Client [ii].SendStr ( NewData + EndofLine);
              end;

            end;
        end;
      except
          on E: Exception do Begin
          //  brain.RemoveSpectator  ( TcpServer.Client [ii].CliId ); { TODO -cverifica : sarà dura debuggare qui }

            ConnAccount := TMyConnection.Create(nil);
            ConnAccount.Server := MySqlServerAccount;
            ConnAccount.Username:='root';
            ConnAccount.Password:='root';
            ConnAccount.Database:='realmd';
            ConnAccount.Connected := True;

            MyQueryCheat := TMyQuery.Create(nil);
            MyQueryCheat.Connection :=  ConnAccount ;
            MyQueryCheat.SQL.Text := ' INSERT into cheat_detected (reason) values ("' + E.ToString + ' TBrainManager.input ' + '")';
            MyQueryCheat.Execute ;
            MyQueryCheat.Free;
            ConnAccount.Connected:= False;
            ConnAccount.Free;
            Exit;
          end;
      end;
  end;
end;
function TBrainmanager.GetbrainStream ( brain: TSoccerBrain) : string;
var
  CompressedStream: TZCompressionStream;
  SS: TStringStream;
begin
              // senza compressione
  {SS := TStringStream.Create('');
  SS.CopyFrom( brain.MMbraindata, 0);
  NewData := SS.DataString;
  SS.Free;   }

  // con compressione
  CompressedStream := TZCompressionStream.Create(brain.MMbraindataZIP, zcDefault); // create the compression stream
  CompressedStream.Write( brain.MMbraindata.Memory , brain.MMbraindata.size); // move and compress the InBuffer string -> destination stream  (MyStream)
  CompressedStream.Free;
  SS := TStringStream.Create('');
  SS.CopyFrom( brain.MMbraindataZIP, 0);
  Result := SS.DataString;
  SS.Free;
end;

{ brain Manager }
procedure TBrainManager.DecodeBrainIds ( brainIds: string; var MyYear, MyMonth, MyDay, MyHour, MyMin, MySec: string );
begin

// così lo creo:    f o m
//    BrainIDS:= 'f_' + IntToStr(myYear)  + Format('%.*d',[2, myMonth]) + Format('%.*d',[2, myDay]) + '_' +
//    Format('%.*d',[2, myHour])  + '.' + Format('%.*d',[2, myMin]) + '.' +  Format('%.*d',[2, mySec])+  '_' +
//    GuidTeam0  + '.' + GuidTeam1  ;
  brainIds := RightStr(brainIds, Length(BrainIds)-2); // elimino f_ o m_
  MyYear := LeftStr(  brainIds, 4 );
  myMonth := MidStr(  brainIds, 5, 2 );
  myDay := MidStr(  brainIds, 7, 2 );
  myHour := MidStr(  brainIds, 10, 2 ); // a 9 _
  myMin := MidStr(  brainIds, 13, 2 ); // a 12 .
  mySec := MidStr(  brainIds, 16, 2 ); // a 15 .

end;
procedure TBrainManager.FinalizeBrain ( brain: TSoccerBrain);
var
  i,indexTal,T,P,aGuidTeam,matches_Played,matches_Left, disqualified, injured,TotYellowCard,aRnd,newStamina,FreeSlot,n,NewMorale: Integer;
  TextHistory,TextXP: string;
  aPlayer: TSoccerPlayer;
  tsXP, tsHistory: TStringList;
  MatchesplayedTeam,Points,Season,SeasonRound,Money,Rank,WorldTeam,Protect,Nextha: array [0..1] of Integer;
  myYear, myMonth, myDay, myHour, myMin, mySec, young : string;
  aBasePlayer: TBasePlayer;
  MatchesPlayed,MatchesLeft: Integer;
  GKpresent: Boolean;
  aReserveSlot: TPoint;
  ValidPlayer: TValidPlayer;
  ConnGame :  TMyConnection;
  qTeams,qPlayers, MyQueryUpdate, MyQueryArchive,qTransfers,qlast:  TMyQuery;
  Start: Integer;
  label skip,MyStoreDone;
begin
    // adesso il match è finito
  // prima aggiorno i disqualified e gli injured ( tutti i giocatori delle due squadre ). anche Mathcheslayed riguarda tutti.

  // Singoli players
//fine partita
  WaitforSingleObject ( MutexMarket, INFINITE ); // devo bloccare il mercato
  WaitForSingleObject(Mutex,INFINITE);
  WaitForSingleObject(MutexLockBrain,INFINITE);


    ConnGame := TMyConnection.Create(nil);
    Conngame.Server := MySqlServerGame;
    Conngame.Username:='root';
    Conngame.Password:='root';
    Conngame.Database:= brain.Gender + '_game';
    Conngame.Connected := True;

    qPlayers := TMyQuery.Create(nil);
    MyQueryUpdate := TMyQuery.Create(nil);

    qPlayers.Connection := ConnGame;   // game
    MyQueryUpdate.Connection := ConnGame;   // game

  for T := 0 to 1 do begin

    qPlayers.SQL.Text := 'SELECT * from ' +brain.Gender + '_game.players WHERE team =' + IntToStr(brain.Score.TeamGuid [T] ) + ' and young =0' ;
    qPlayers.Execute ;


    for I := 0 to qPlayers.RecordCount -1 do begin
      // nota: se un player è stato comprato sul mercato non crea problemi se non al valore di mercato
      aGuidTeam := qPlayers.FieldByName('team').asinteger;
      matches_Played := qPlayers.FieldByName('matches_played').asinteger;   // il tempo passa per tutti. invecchiano tutti.
      matches_left := qPlayers.FieldByName('matches_left').asinteger;
      Inc(matches_Played);
      Dec(matches_left);

          //
          // CASO FINE CARRIERA
          //
          if matches_left <= 0 then begin // fine carriera
            aGuidTeam := 0; // i player con Guidteam 0 sono da gestire poi sul DB
            MyQueryUpdate.SQL.text := 'UPDATE ' +brain.Gender + '_game.players SET team = 0'+ // 0 se a fine carriera
                                                            ' WHERE guid = ' + qPlayers.FieldByName('guid').asstring ;
            MyQueryUpdate.Execute;

            // questo è il LOG
            qTransfers := TMyQuery.Create(nil);
            qTransfers.Connection := ConnGame;   // game
            qTransfers.SQL.text := 'INSERT INTO '+brain.Gender +'_game.transfers SET action="e", seller=' +  IntToStr(brain.Score.TeamGuid [T]) +
                                                                ' , buyer=' + IntToStr(brain.Score.TeamGuid [T]) +
                                                                ' , playerguid=' + qPlayers.FieldByName('guid').asstring + ' , price=0';
            qTransfers.Execute;
            goto MyStoreDone;
          end;
          //
          //

      disqualified  :=  qPlayers.FieldByName('disqualified').asinteger;
      if disqualified > 0 then
        Dec( disqualified );
      injured  :=  qPlayers.FieldByName('injured').asinteger;
      if injured > 0 then
        Dec( injured );

      if qPlayers.FieldByName('disqualified').asinteger > 0 then begin // se sul db è diqualified non lo posso trovare in getsoccerALL
        if (injured <= 0) then begin
          NewStamina := NewStamina + REGEN_STAMINA + GetFitnessModifier (qPlayers.FieldByName('fitness').asinteger  );
          if NewStamina > 120 then NewStamina := 120;
        end;
        if Injured > 0 then
          newStamina:=0;
        MyQueryUpdate.SQL.text := 'UPDATE ' +brain.Gender + '_game.players SET matches_played = ' + IntTostr(matches_played) +
                                                        ', matches_left = ' + IntTostr(matches_Left) +
                                                        ', team = ' + IntTostr(aGuidTeam) +             // 0 se a fine carriera ma non è stato calcolato sopra nem valore market
                                                        ', disqualified = ' + IntTostr(disqualified) +
                                                        ', Stamina = ' + IntToStr (NewStamina) +
                                                        ' WHERE guid = ' + qPlayers.FieldByName('guid').asstring ;
        MyQueryUpdate.Execute ;

        goto MyStoreDone;
      end;

      NewMorale := 0;
      if qPlayers.FieldByName('talentid1').AsInteger <> 1 then begin // il morale non funziona sui GK
        if brain.GetSoccerPlayer3(qPlayers.FieldByName('guid').AsString ) <> nil then begin // HA GIOCATO LA PARTITA
          if RndGenerate(100) <= 25 then
            NewMorale := +1;
        end
        else begin // NON HA GIOCATO LA PARTITA
          if RndGenerate(100) <= 33 then
            NewMorale := -1;
        end;
      end;
      // da qui in poi le variabili del brain possono modificare anche disqualified e injured ecc...
      // gestione cartellini       2 gialli 1 rosso. slo 1 rosso. se rosso 1,2,3 turni
      // dopo disqualified e injured vengono aggiornati solo da chi ha giocato in lstSoccerPlayer
      // lstSoccerPlayer contiene tutti i giocatori che hanno giocato (espulsi , infortunati, sostituiti ecc..) la lstReserve non mi serve

      TotYellowCard  :=  qPlayers.FieldByName('totyellowcard').asinteger;
      aPlayer := brain.GetSoccerPlayerALL ( qPlayers.FieldByName('guid').asstring ); // tutti! ... player, reserve e gameover

      TotYellowCard := TotYellowCard + aPlayer.YellowCard;
      if TotYellowCard >= YELLOW_DISQUALIFIED then begin
        // genero 1 turno di squalifica
        disqualified := 1;
        // azzero il totYellowCard
        TotYellowCard := 0;
      end
      else if aPlayer.RedCard > 0 then begin
        aRnd := RndGenerate(100);
        case aRnd of
          1..70: disqualified := 1;
          71..90: disqualified := 2;
          91..100: disqualified := 3;
        end;

      end;
  // MORALE se gioca 50% incrementa, se non gioca 50% decrementa. Nella CreateAndLoadMatch gestione del morale e buff casalingo

                // ristrutturo il Player del brain con i dati del db
                aPlayer.Age:= Trunc(  matches_Played  div SEASON_MATCHES) + 18 ;
                aPlayer.devA := qPlayers.FieldByName('deva').asinteger;  // chance di sviluppare un attributo per  età
                aPlayer.devT := qPlayers.FieldByName('devt').asinteger;
                aPlayer.devI := qPlayers.FieldByName('devi').asinteger;
                aPlayer.xpDevA := qPlayers.FieldByName('xpdeva').asinteger;  // xp dev
                aPlayer.xpDevT := qPlayers.FieldByName('xpdevt').asinteger;
                aPlayer.xpDevI := qPlayers.FieldByName('xpdevi').asinteger;
                aPlayer.DefaultSpeed := qPlayers.FieldByName('Speed').asinteger;
                aPlayer.DefaultDefense :=  qPlayers.FieldByName('Defense').AsInteger;
                aPlayer.DefaultPassing :=  qPlayers.FieldByName('Passing').AsInteger;
                aPlayer.DefaultBallControl :=  qPlayers.FieldByName('BallControl').AsInteger;
                aPlayer.DefaultShot :=  qPlayers.FieldByName('Shot').AsInteger;
                aPlayer.DefaultHeading :=  qPlayers.FieldByName('Heading').AsInteger;
                aPlayer.TalentID1 :=  qPlayers.FieldByName('talentid1').asInteger;
                aPlayer.TalentID2 :=  qPlayers.FieldByName('talentid2').asInteger;
                aPlayer.Fitness :=  qPlayers.FieldByName('fitness').asInteger;
                aPlayer.Morale :=  qPlayers.FieldByName('morale').asInteger;

                aPlayer.Morale := aPlayer.Morale + NewMorale; // setto il nuovo morale se ha giocato o no
                if aPlayer.Morale < 0 then
                  aPlayer.Morale :=0
                  else if aPlayer.Morale > 2 then
                    aPlayer.Morale :=2;

                if Matches_Played = 456 then begin // allo scoccare dei 30 anni può perdere 1 punto di fitness
                  if aPlayer.fitness > 0 then begin
                    if RndGenerate(100) <= 50 then begin
                      aPlayer.fitness := aPlayer.fitness  - 1;
                    end;
                  end;
                end;


                tsHistory := TStringList.Create;
                tsHistory.commaText := qPlayers.FieldByName('history').asString; // <-- 6 attributes
                aPlayer.History_Speed         := StrToInt( tsHistory[0]);
                aPlayer.History_Defense       := StrToInt( tsHistory[1]);
                aPlayer.History_Passing       := StrToInt( tsHistory[2]);
                aPlayer.History_BallControl   := StrToInt( tsHistory[3]);
                aPlayer.History_Shot          := StrToInt( tsHistory[4]);
                aPlayer.History_Heading       := StrToInt( tsHistory[5]);
                tsHistory.Free;


      // invece Injured si aggiorna qui perchè guadagnata in lastgame , quindi questo è un player injured adesso
      if (aPlayer.Injured > 0) and ( injured = 0 ) then begin // evita di caricare dal db player già injured. aplayer.injured è diverso da Injured

        aRnd := RndGenerate(100);
        case aRnd of
          1..70: injured := brain.RndGenerateRange( 1,2 ) ;
          71..90: injured := brain.RndGenerateRange( 3,10 );
          91..99: injured := brain.RndGenerateRange( 11,17 );
          100:begin // possibile perdita attributo
                injured := brain.RndGenerateRange( 18, 38 );
                calc_injured_attribute_lost( aPlayer); // è calc_xp ma in perdita di 1    . Modifica default e history
              end;
        end;

      end;


        // xp qui sommo al db la xp guadagnata in partita
        tsXP := TStringList.Create;
        tsXP.commaText := qPlayers.FieldByName('xp').asstring; // <-- 6 attributes , NUM_TALENT talenti

        // rispettare esatto ordine
        aPlayer.xp_Speed         := aPlayer.xp_Speed + StrToInt( tsXP[0]);
        aPlayer.xp_Defense       := aPlayer.xp_Defense + StrToInt( tsXP[1]);
        aPlayer.xp_Passing       := aPlayer.xp_Passing + StrToInt( tsXP[2]);
        aPlayer.xp_BallControl   := aPlayer.xp_BallControl + StrToInt( tsXP[3]);
        aPlayer.xp_Shot          := aPlayer.xp_Shot + StrToInt( tsXP[4]);
        aPlayer.xp_Heading       := aPlayer.xp_Heading + StrToInt( tsXP[5]);

        // rispettare esatto ordine f_game.talents
        for indexTal := 1 to NUM_TALENT do begin
          aPlayer.xpTal[indexTal]  := aPlayer.xpTal[indexTal] + StrToInt( tsXP[indexTal+5]); // xpTal array [1..NUM_TALENT] come f_game.talents quindi 5 perchè base 1
        end;
        tsXP.Free;

      if aGuidTeam <> 0 then   // sopra potrebbe essere giunto a fine carriera
      // l'update riguarda tutti
      TextHistory := IntToStr(aPlayer.history_Speed) + ',' + IntToStr(aPlayer.history_Defense) + ',' + IntToStr(aPlayer.history_Passing) + ',' +
      IntToStr(aPlayer.history_BallControl) + ',' + IntToStr(aPlayer.history_Shot) + ',' + IntToStr(aPlayer.history_Heading);

      TextXP := IntToStr(aPlayer.xp_Speed) + ',' + IntToStr(aPlayer.xp_Defense) + ',' + IntToStr(aPlayer.xp_Passing) + ',' +
      IntToStr(aPlayer.xp_BallControl) + ',' + IntToStr(aPlayer.xp_Shot) + ',' + IntToStr(aPlayer.xp_Heading) +',';
      for indexTal := 1 to NUM_TALENT do begin // f_game.talents
        TextXP := TextXP + IntToStr(aPlayer.xpTal[indexTal]) + ',';
      end;
      TextXP := LeftStr( TextXP, Length(TextXP)-1); // elimino l'ultima virgola
      // solo ora aggiorno la stamina di tutti
      NewStamina :=  aPlayer.Stamina ;
      if (injured <= 0) and (aPlayer.Injured <= 0)then begin
        NewStamina := NewStamina + REGEN_STAMINA + GetFitnessModifier (aPlayer.fitness  ); ;
        if NewStamina > 120 then NewStamina := 120;
      end;
      if aPlayer.Injured > 0 then  // injured in questa partita
        newStamina:=0;
      MyQueryUpdate.SQL.text := 'UPDATE ' +brain.Gender + '_game.players SET matches_played = ' + IntTostr(matches_played) +
                                                      ', matches_left = ' + IntTostr(matches_Left) +
                                                      ', fitness = ' + IntTostr(aPlayer.Fitness) +
                                                      ', team = ' + IntTostr(aGuidTeam) +             // 0 se a fine carriera ma non è stato calcolato sopra nem valore market
                                                      ', disqualified = ' + IntTostr(disqualified) +
                                                      ', totyellowcard = ' + IntTostr(TotYellowCard) +
                                                      ', injured = ' + IntTostr(injured) +
                                                      ', Speed = ' + IntTostr(aPlayer.DefaultSpeed ) +
                                                      ', Defense = ' + IntTostr(aPlayer.DefaultDefense) +
                                                      ', Passing = ' + IntTostr(aPlayer.DefaultPassing) +
                                                      ', BallControl = ' + IntTostr(aPlayer.DefaultBallControl) +
                                                      ', Shot = ' + IntTostr(aPlayer.DefaultShot) +
                                                      ', Heading = ' + IntTostr(aPlayer.DefaultHeading) +
                                                      ', History = ''' + TextHistory + '''' +
                                                      ', Xp = ''' + TextXP + '''' +
//                                                      ', Talentid1 = ' + IntToStr(aPlayer.TalentID1) + // usato come id numerico
                                                      ', Stamina = ' + IntToStr (NewStamina) +
                                                      ', Morale = ' + IntToStr (aPlayer.Morale) +
                                                      ' WHERE guid = ' + qPlayers.FieldByName('guid').asstring ;
      MyQueryUpdate.Execute ;

MyStoreDone:
      qPlayers.Next ;

    end;

  end;
  // la MI è già aggiornata e devo solo storarla. Nexha la devo cambiare e qui so giò per forza come
  // Team

  qTeams := TMyQuery.Create(nil);
  qTeams.Connection := ConnGame;  // game
  qTeams.SQL.Text:= 'SELECT worldteam, season,matchesplayed,money, rank,points,protect,nextha from ' +brain.Gender + '_game.teams WHERE guid = ' + IntToStr( brain.Score.TeamGuid [0]);
  qTeams.Execute;

  MatchesplayedTeam[0] := qTeams.FieldByName('matchesplayed').AsInteger + 1;  // praticamente seasonRound
  Money[0] := qTeams.FieldByName('money').AsInteger;
  SeasonRound[0] := MatchesplayedTeam[0] ;
  WorldTeam[0] := qTeams.FieldByName('worldteam').AsInteger;
  Rank[0]  := qTeams.FieldByName('rank').AsInteger;
  Points[0]  := qTeams.FieldByName('points').AsInteger + brain.Score.Points[0];
  Season[0]  := qTeams.FieldByName('season').AsInteger;
  Protect[0]  := qTeams.FieldByName('protect').AsInteger;
  Nextha[0]  := qTeams.FieldByName('nextha').AsInteger;

    if Nextha[0] = 1 then
      Nextha[0] := 0
      else Nextha[0] := 1;

    if brain.Gender='m' then begin
      case Rank[0] of
        1:Money[0]:= Money[0] + (1000 * brain.Score.Points[0]);
        2:Money[0]:= Money[0] + (800 * brain.Score.Points[0]);
        3:Money[0]:= Money[0] + (600 * brain.Score.Points[0]);
        4:Money[0]:= Money[0] + (400 * brain.Score.Points[0]);
        5:Money[0]:= Money[0] + (200 * brain.Score.Points[0]);
        6:Money[0]:= Money[0] + (100 * brain.Score.Points[0]);
      end;
    end
    else begin // female
      case Rank[0] of
        1:Money[0]:= Money[0] + (600 * brain.Score.Points[0]);
        2:Money[0]:= Money[0] + (450 * brain.Score.Points[0]);
        3:Money[0]:= Money[0] + (320 * brain.Score.Points[0]);
        4:Money[0]:= Money[0] + (200 * brain.Score.Points[0]);
        5:Money[0]:= Money[0] + (100 * brain.Score.Points[0]);
        6:Money[0]:= Money[0] + (60 * brain.Score.Points[0]);
      end;
    end;

  // in Questo momento potrebbe essere fine season con MatchesplayedTeam = 38
  // passaggio rank . sopra i 15
//  Rank[0] := Trunc(brain.Score.TeamMI [0] / 15); // passaggio rank qui e sotto



  Rank [0] := Formserver.Calculaterank (brain.Score.TeamMI [0]);
  qTeams.SQL.text := 'UPDATE ' +brain.Gender + '_game.teams SET nextha = '+ IntTostr( Nextha[0]) +', mi = ' + IntToStr(brain.Score.TeamMI [0])  +
  ',matchesplayed=' + IntToStr(MatchesplayedTeam[0])+ ',rank=' + IntToStr(Rank[0]) +  ',points=' + IntToStr(Points[0]) +
  ',money='+ IntToStr (Money[0]) +
  ' WHERE Guid = ' + IntToStr( brain.Score.TeamGuid [0]);
  qTeams.Execute;



  qTeams.SQL.text := 'SELECT worldteam,season,matchesplayed,money,rank,points,protect,nextha from ' +brain.Gender + '_game.teams WHERE guid = ' + IntToStr( brain.Score.TeamGuid [1]);
  qTeams.Execute;


  MatchesplayedTeam[1] := qTeams.FieldByName('matchesplayed').AsInteger + 1;
  SeasonRound[1] := MatchesplayedTeam[1] ;
  WorldTeam[1] := qTeams.FieldByName('worldteam').AsInteger;
  Money[1] := qTeams.FieldByName('money').AsInteger;
  Rank[1]  := qTeams.FieldByName('rank').AsInteger;
  Points[1] := qTeams.FieldByName('points').AsInteger + brain.Score.Points[1];
  Season[1]  := qTeams.FieldByName('season').AsInteger;
  Protect[1]  := qTeams.FieldByName('protect').AsInteger;
  Nextha[1]  := qTeams.FieldByName('nextha').AsInteger;

    if Nextha[1] = 1 then
      Nextha[1] := 0
      else Nextha[1] := 1;


    if brain.Gender='m' then begin
      case Rank[1] of
        1:Money[1]:= Money[1] + (1000 * brain.Score.Points[1]);
        2:Money[1]:= Money[1] + (800 * brain.Score.Points[1]);
        3:Money[1]:= Money[1] + (600 * brain.Score.Points[1]);
        4:Money[1]:= Money[1] + (400 * brain.Score.Points[1]);
        5:Money[1]:= Money[1] + (200 * brain.Score.Points[1]);
        6:Money[1]:= Money[1] + (100 * brain.Score.Points[1]);
      end;
    end
    else begin // female
      case Rank[1] of
        1:Money[1]:= Money[1] + (600 * brain.Score.Points[1]);
        2:Money[1]:= Money[1] + (480 * brain.Score.Points[1]);
        3:Money[1]:= Money[1] + (460 * brain.Score.Points[1]);
        4:Money[1]:= Money[1] + (340 * brain.Score.Points[1]);
        5:Money[1]:= Money[1] + (220 * brain.Score.Points[1]);
        6:Money[1]:= Money[1] + (100 * brain.Score.Points[1]);
      end;
    end;

  Rank [1] := Formserver.Calculaterank (brain.Score.TeamMI [1]);
  qTeams.SQL.text := 'UPDATE ' +brain.Gender + '_game.teams SET nextha = '+ IntTostr( Nextha[1]) +', mi = ' + IntToStr(brain.Score.TeamMI [1])  +
  ',matchesplayed=' + IntToStr(MatchesplayedTeam[1]) + ',rank=' + IntToStr(Rank[1]) + ',points=' + IntToStr(Points[1]) +
  ',money='+ IntToStr (Money[1]) +
  ' WHERE Guid = ' + IntToStr( brain.Score.TeamGuid [1]);
  qTeams.Execute;

  // Aggiorno archive con tutti i dati e matchinfo
  DecodeBrainIds ( brain.brainIds, myYear, myMonth, myDay, myHour, myMin, mySec );

  MyQueryArchive := TMyQuery.Create(nil);

  MyQueryArchive.Connection := ConnGame;   // game
//  brain.Score.
  MyQueryArchive.SQL.text := 'INSERT INTO ' +brain.Gender + '_game.archive SET season0 = ' + IntToStr(Season[0]) + ',seasonround0 = ' + IntToStr(MatchesplayedTeam[0]) + // -1 perchè appena sopra l'ho aggiunto
                             ',season1 = '+  IntToStr(Season[1]) + ',seasonround1 = ' + IntToStr(MatchesplayedTeam[1]) + // -1 perchè appena sopra l'ho aggiunto
                             ',year = ' + myYear + ', month = ' + myMonth + ',day = ' + myDay +
                             ',hour = ' + MyHour + ',minute = ' + MyMin + ',second = ' + MySec +
                             ',guidteam0 = ' + IntToStr(brain.Score.TeamGuid [0]) + ',guidteam1 = ' + IntToStr(brain.Score.TeamGuid [1]) +
                             ',gol0 = ' + IntToStr(brain.Score.gol [0]) + ',gol1 = ' + IntToStr(brain.Score.gol [1]) +
                             ',matchinfo = "' + brain.MatchInfo.CommaText + '"';
  MyQueryArchive.Execute;
  MyQueryArchive.Free;

  // rimagonono N posti liberi. genero 2 giovani. Se posso li metto in squadra, altrimenti userò la tabella youngqueue

   // solo per test qTeams.SQL.text := 'UPDATE ' +brain.Gender + '_game.teams SET bot=0 WHERE Guid = ' + IntToStr( brain.Score.TeamGuid [T]);
   // qTeams.Execute;

    // devo rifare la query per via dei player oltre i 33 anni
    qPlayers.SQL.Text := 'SELECT * FROM ' +brain.Gender + '_game.players WHERE team =' + IntToStr(brain.Score.TeamGuid [T] );
    qPlayers.Execute ;

//     talentid2 può essere generato ogni 20 partite. solo per chi ha già talentid1
//
  for T := 0 to 1 do begin

    if frac ( MatchesplayedTeam[T] / 20 )= 0 then begin

      for p := qPlayers.RecordCount -1 downto 0 do begin

        ValidPlayer.talentID1 := qPlayers.FieldByName ('talentid1').AsInteger;
        if ValidPlayer.talentID1 = 0 then
          goto skip;

        ValidPlayer.Age:= Trunc(  qPlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
        ValidPlayer.talentID2 := qPlayers.FieldByName ('talentid2').AsInteger;
        ValidPlayer.speed :=  qPlayers.FieldByName ('speed').AsInteger;
        ValidPlayer.defense :=  qPlayers.FieldByName ('defense').AsInteger;
        ValidPlayer.passing :=  qPlayers.FieldByName ('passing').AsInteger;
        ValidPlayer.ballcontrol :=  qPlayers.FieldByName ('ballcontrol').AsInteger;
        ValidPlayer.shot :=  qPlayers.FieldByName ('shot').AsInteger;
        ValidPlayer.heading :=  qPlayers.FieldByName ('heading').AsInteger;
        ValidPlayer.history := qPlayers.FieldByName ('history').AsString;
        ValidPlayer.xp := qPlayers.FieldByName ('xp').AsString;

        ValidPlayer.chancelvlUp := qPlayers.FieldByName ('deva').AsInteger;
        ValidPlayer.chancetalentlvlUp :=  qPlayers.FieldByName ('devt').AsInteger;


        pvpTrylevelUpTalent(MySqlServerGame, 'f', qPlayers.FieldByName('guid').AsInteger,ValidPlayer.talentID1, ValidPlayer  );
Skip:
        qPlayers.Next;

      end;
      //
      // aggiungo eventuali nuovi giovani
      // qui devo generare 1 giovine  :)
      //

      FreeSlot := 22 - qPlayers.RecordCount;
      // o lo mette direttamente in squadra o lo mette nella tabella youngplayers
      if FreeSlot = 0 then
        young := '1'
        else young := '0';

      GKpresent := false;
      brain.CleanReserveSlot ( T );
      for I := 0 to qPlayers.RecordCount -1 do begin
        if qPlayers.fieldByName('talentid1').AsInteger = TALENT_ID_GOALKEEPER then begin
          GKpresent := true;
        end;

        if isReserveSlotFormation ( qPlayers.FieldByName('formation_x').AsInteger, qPlayers.FieldByName('formation_y').AsInteger) then
        brain.ReserveSlot [ T, qPlayers.FieldByName('formation_x').AsInteger] := qPlayers.FieldByName('guid').AsString;
        qPlayers.Next;
      end;

      // ottengo il prossimo slot delle riserve
      aReserveSlot.X := brain.NextReserveSlot ( T ); //<--- la prossima libera
    //  aReserveSlot.Y := -1;

      {$ifdef debug}
      Start := GettickCount;
      {$endif debug}
      aBasePlayer := FormServer.CreateRandomPlayer ( brain.Gender, brain.Score.Country[T], true );
      {$ifdef debug}
      FormServer.memo2.lines.Add( IntToStr( GetTickCount - Start));
      {$endif debug}


      MatchesPlayed := 0; //38 * 18  ; // 18 anni
      MatchesLeft := (38*15) - MatchesPlayed;
      if not GKpresent then begin
        aBasePlayer.TalentId1 := TALENT_ID_GOALKEEPER; // sovrascrivo
          if RndGenerate(100) <= aBasePlayer.devT then        // creo il secondo talento
            aBasePlayer.TalentId2 := CreateTalentLevel2 ( brain.Gender, aBasePlayer ); // ottiene un talent2 per GK
      end;

      qPlayers.SQL.text := 'INSERT into ' +brain.Gender + '_game.players'+' (Team,Name,Matches_Played,Matches_Left,'+
                                    'deva,devt,devi,xpdeva,xpdevt,xpdevi,'+
                                    'talentid1, talentid2, speed,defense,passing,ballcontrol,heading,shot,injured,totyellowcard,disqualified,country,face,'+
                                    'formation_x, formation_y,young)'+
                                    ' VALUES ('+
                                    IntToStr(brain.Score.TeamGuid [T]) +',"'+ aBasePlayer.Surname +'",'+ IntToStr(MatchesPlayed)+','+ IntToStr(MatchesLeft)+','+
                                    IntToStr(aBasePlayer.deva)+','+IntToStr(aBasePlayer.devt)+','+IntToStr(aBasePlayer.devi)+','+
                                    IntToStr(aBasePlayer.xpdeva)+','+IntToStr(aBasePlayer.xpdevt)+','+IntToStr(aBasePlayer.xpdevi)+','+
                                    IntToStr(aBasePlayer.TalentId1) + ',' + IntToStr(aBasePlayer.TalentId2) + ','  +  aBasePlayer.Attributes +','+
                                    '0,0,0,'+IntToStr( brain.Score.Country[T]) +','+ IntToStr(aBasePlayer.Face) +','+ //injured,totyellowcard,disqualified, face
                                     IntToStr(aReserveSlot.X)+ ',-1,'+young+')';

      qPlayers.Execute;
        // questo è il LOG . il player va direttamente in squadra
      if young = '0' then begin  { SOLO Se la tabella è players e non youngplayers }
        qlast := TMyQuery.Create(nil);
        qlast.Connection := ConnGame;   // game
        qlast.SQL.text := 'SELECT LAST_INSERT_ID()'; // il problema è che lo devo riprendere su per conoscere il guid
        qlast.Execute;
        qTransfers := TMyQuery.Create(nil);
        qTransfers.Connection := ConnGame;   // game
        qTransfers.SQL.text := 'INSERT INTO '+brain.Gender +'_game.transfers SET action="a", seller=' +  IntToStr(brain.Score.TeamGuid [T]) +
                                                                     ' , buyer=' + IntToStr(brain.Score.TeamGuid [T]) +
                                                                     ' , playerguid=' + qlast.FieldByName('LAST_INSERT_ID()').asstring + ' , price=0';
        qTransfers.Execute;
        qlast.Free;

      end;


    end;
  end;

  ReleaseMutex ( MutexMarket); // sblocco il mercato
  ReleaseMutex ( Mutex); // sblocco il thread delle partite
  ReleaseMutex ( MutexLockBrain); // sblocco il thread per permettere l'eliminazione del brain

  qTeams.Free;
  MyQueryUpdate.Free;
  qPlayers.Free;
  Conngame.Connected := false;
  Conngame.Free;

end;

function TBrainManager.RndGenerate( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (1, Upper + 1));
end;
function TBrainManager.RndGenerate0( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (0, Upper + 1));
end;
function TBrainManager.RndGenerateRange( Lower, Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (Lower, Upper + 1));
end;

function TBrainManager.Findbrain ( ids: string ): TSoccerbrain;
var
  i: Integer;
begin
  result := nil;
  WaitForSingleObject(Mutex,INFINITE);
  for I := 0 to lstbrain.count -1 do begin
    if lstbrain[i].BrainIDS  = ids then begin // esiste già una partita con quel client
      Result:= lstbrain[i];
      ReleaseMutex(Mutex);
      Break;
    end;
  end;
  ReleaseMutex(Mutex);

end;
function TBrainManager.Findbrain ( CliId: integer ): TSoccerbrain;
var
  i,s: Integer;
begin
  Result := nil;
  WaitForSingleObject(Mutex,INFINITE);
  for I := lstbrain.count -1 downto 0 do begin
    for S := lstbrain[i].lstSpectator.count -1 downto 0 do begin
      if lstbrain[i].lstSpectator[s] = Cliid then begin // esiste già una partita con quel client in spectator
        Result:= lstbrain[i];
        ReleaseMutex(Mutex);
        exit;
      end;
    end;
  end;
  ReleaseMutex(Mutex);

end;
procedure TBrainManager.AddBrain ( brain: TSoccerbrain );
//var
//  i: Integer;
//  found: Boolean;
label addbot;
begin
//  if  brain.Score.cliid[0] = 0 then goto AddBot;

//  for I := 0 to lstbrain.count -1 do begin
//    if (lstbrain[i].Score.CliId[0] = brain.Score.cliid[0]) or
//       (lstbrain[i].Score.CliId[0] = brain.Score.cliid[1]) or
//       (lstbrain[i].Score.CliId[1] = brain.Score.cliid[1]) or
//       (lstbrain[i].Score.CliId[1] = brain.Score.cliid[0])  then begin // esiste già una partita con quel client
//      found:= True;
//      Break;
//    end;
//  end;

//  if not found then begin
addbot:
    brain.brainManager := TObject (self);
    lstbrain.Add( brain);
//  end;
end;
procedure TBrainManager.RemoveBrain ( brainIds: string );
var
  i: Integer;
begin

  WaitForSingleObject(Mutex,INFINITE);
  for I := lstbrain.count -1 downto 0 do begin
      if lstbrain[i].BrainIDS  = brainIds then begin // esiste la partita con quel BrainIds
       // ShowMessage(IntToStr( lstBrain[i].ShotCells.count));
        lstBrain.Delete(i); // libera anche gli spettatori
        ReleaseMutex(Mutex);
        Exit;
      end;
  end;
  ReleaseMutex(Mutex);



end;
procedure TFormServer.Display(Msg : String);
var
msg2: string;
MyQueryWC : TMyQuery;
begin
  //ReplaceS(Msg2,'|', '    ' );
  if memo1.Lines.Count  > 1000 then begin  { Prevent TMemo overflow }
        memo1.Lines.Clear ;
  end;
  memo1.Lines.add (msg);
end;
procedure TFormServer.FormCreate(Sender: TObject);
var
  ini: TIniFile;
  i: Integer;
  ConnWorld : TMyConnection ;
  MyQueryWC: TMyQuery;
begin
  debug_TryTalentNoXp :=false;
  CreateShotCells;
  createAIfield;
	TVCreateCrossingAreaCells;
	AICreateCrossingAreaCells;

  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='world';
  ConnWorld.Connected := True;

  MyQueryWC := TMyQuery.Create(nil);
  MyQueryWC.Connection := ConnWorld;   // world
  MyQueryWC.SQL.Text:= 'SELECT * FROM world.countries order by guid';
  MyQueryWC.execute;


  for I := 0 to MyQueryWC.RecordCount -1 do begin
    mfaces [ MyQueryWC.FieldByName('guid').AsInteger ] :=MyQueryWC.FieldByName('mfaces').AsInteger;
    ffaces [ MyQueryWC.FieldByName('guid').AsInteger ] :=MyQueryWC.FieldByName('ffaces').AsInteger;
    MyQueryWC.Next;
  end;

  MyQueryWC.Free;

  Mutex:=CreateMutex(nil,false,'list');
  MutexMarket:=CreateMutex(nil,false,'market');
  MutexLockBrain:=CreateMutex(nil,false,'lockbrain');
  RandGen := TtdCombinedPRNG.Create(0, 0);

  CreateFormationsPreset;

  ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'server.ini');
  dir_log := ini.ReadString('setup','dir_log','');
  CheckBox2.Caption := 'Log All: ' + dir_log;

  MySqlServerGame := ini.ReadString('Tcp','Address','localhost');
  MySqlServerWorld := ini.ReadString('Tcp','Address','localhost');
  MySqlServerAccount := ini.ReadString('Tcp','Address','localhost');

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
  // modificare anche client formcreate

  LoadPreset;

  TsWorldCountries:= TStringList.Create ;
  PrepareWorldCountries;
  for i := 1 to TsWorldCountries.Count do begin
    TsWorldteams[i]:= TStringList.Create ;
    PrepareWorldTeams (i);
  end;


  BrainManager:= TbrainManager.Create (Tcpserver);
  TcpServer.Port := ini.ReadString('tcp','port','2018');
  ini.Free;

  Queue:= TObjectList<TWSocketThrdClient>.Create(false);
  QueueThread.Enabled := True;
  MatchThread.Enabled := True;


  TcpServer.LineMode            := true;
  TcpServer.LineEdit            := false;
  TcpServer.LineEnd             := EndOfLine;
  TcpServer.LineLimit           := 1024;
  TcpServer.Addr                := '0.0.0.0';
  TcpServer.MaxClients          := 2000;
  TcpServer.Listen ;

  ConnWorld.free;

  //  CreateRewards;
end;
procedure TFormServer.LoadPreset;
var
  ini: TIniFile;
  i: integer;
begin

  ini:= TIniFile.Create( ExtractFilePath(Application.ExeName) +  'preset.ini' );
  for I := 0 to PlayerCountStart -1 do begin
    PresetF [i]:= ini.ReadString('f','p'+IntToStr(i),'' );
    PresetM [i]:= ini.ReadString('m','p'+IntToStr(i),'' );
    PresetFT [i]:= ini.ReadInteger('f','t'+IntToStr(i),0 );
    PresetMT [i]:= ini.ReadInteger('m','t'+IntToStr(i),0 );
  end;

  ini.Free;


  // mathes played preset
  mp_template[0]:= 7; // stagioni giocate
  mp_template[1]:= 3;
  mp_template[2]:= 5;
  mp_template[3]:= 10;
  mp_template[4]:= 9;
  mp_template[5]:= 8;
  mp_template[6]:= 8;
  mp_template[7]:= 13;
  mp_template[8]:= 7;
  mp_template[9]:= 6;
  mp_template[10]:= 11;
  mp_template[11]:= 4;
  mp_template[12]:= 12;
  mp_template[13]:= 2;
  mp_template[14]:= 1;


end;
procedure TFormServer.CleanDirectory(dir:string);
var
  sf : SE_SearchFiles;
  i,i2: Integer;
begin
  //  svuoto la dir_data dalle subdiretory
  sf :=  SE_SearchFiles.Create(nil);
  sf.FromPath := dir;
  sf.MaskInclude.Add('*.*');
  sf.SubDirectories := true;
  sf.Options := [soOnlyDirs];
  sf.Execute ;
  for I2 := 0 to sf.ListFiles.Count -1 do begin         // dirctoryListing
    i:=0;
    while FileExists  ( PChar(dir + sf.ListFiles[i2] +'\' +  Format('%.*d',[3, i]) + '.ini'))  do begin
      Deletefile ( PChar(dir + sf.ListFiles[i2] +'\' +  Format('%.*d',[3, i]) + '.ini'));
      Inc(i);
    end;
    if FileExists  ( PChar(dir + sf.ListFiles[i2] + '\' +   'team.ini'))  then
        Deletefile ( PChar(dir + sf.ListFiles[i2] + '\' +   'team.ini'));
    if FileExists  ( PChar(dir + sf.ListFiles[i2] + '\' +   'listmatch.ini'))  then
        Deletefile ( PChar(dir + sf.ListFiles[i2] + '\' +   'listmatch.ini'));
    if FileExists  ( PChar(dir + sf.ListFiles[i2] + '\' +   'xp.txt'))  then
        Deletefile ( PChar(dir + sf.ListFiles[i2] + '\' +   'xp.txt'));
    if FileExists  ( PChar(dir + sf.ListFiles[i2] + '\' +   'MM.txt'))  then
        Deletefile ( PChar(dir + sf.ListFiles[i2] + '\' +   'MM.txt'));

    RemoveDir(dir + sf.ListFiles[i2]);
  end;

end;
procedure TFormServer.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  RandGen.Free;
  Queue.Free;
  BrainManager.Free;
  for I := TsWorldCountries.Count downto 1 do begin
    TsWorldteams[i].free;
  end;
  TsWorldCountries.Free;
  CloseHandle(Mutex);
  CloseHandle(MutexMarket);
  CloseHandle(MutexLockbrain);

end;



procedure TFormServer.TcpserverBgException(Sender: TObject; E: Exception;
  var CanClose: Boolean);
begin
    Display('Server exception occured: '  +  E.ClassName + ': ' + E.Message);

    CanClose := FALSE;

end;

procedure TFormServer.TcpserverClientConnect(Sender: TObject;  Client: TWSocketClient; Error: Word);
begin
    if TcpServer.ClientCount >= TcpServer.MaxClients then begin
     Client.CloseDelayed ;
     Exit;
    end;


      Client.LastTickCount       := 0;  // a mezzanotte ....bug
      Client.LineMode            := TRUE;
      Client.LineEnd             := EndOfLine;
      Client.LineEdit            := false;
      Client.LineLimit           := 1024;
      Client.OnDataAvailable     := TcpServerDataAvailable;
      Client.OnLineLimitExceeded := TcpServerLineLimitExceeded;
      Client.OnBgException       := TcpServerBgException;

      //Client.CliId := TcpServer.ClientCount;
      Display( 'Server client connected: ' + Client.peerAddr  );
//  Client.SendStr('ftppwd' + ',' + IntToStr( Client.tag )  + EndofLine  );

      Label1.caption := 'Client Count: ' + intTostr(Tcpserver.ClientCount );
end;

procedure TFormServer.TcpserverClientDisconnect(Sender: TObject;  Client: TWSocketClient; Error: Word);
var
  i: Integer;
begin
    // rimuovo me stesso da ogni brain

  WaitForSingleObject(Mutex,INFINITE);
    if Client.Brain <> nil then begin
      for I := 0 to brainManager.lstBrain.Count -1 do begin
        if brainManager.lstBrain[i].BrainIDS  = TSoccerBrain(Client.Brain).BrainIDS then begin
          if brainManager.lstBrain[i].Score.TeamGuid [0] = Client.GuidTeams[brainManager.lstBrain[i].gendern] then begin
            brainManager.lstBrain[i].Score.AI[0]:= true;
            brainManager.lstBrain[i].Score.CliId [0] := 0;
          end
          else if brainManager.lstBrain[i].Score.TeamGuid [1] = Client.GuidTeams[brainManager.lstBrain[i].gendern] then begin
            brainManager.lstBrain[i].Score.AI[1] := true;
            brainManager.lstBrain[i].Score.CliId [1] := 0;
          end;
        end;
      end;
    end;

    for I := 0 to brainManager.lstBrain.Count -1 do begin
      brainManager.lstBrain [i].RemoveSpectator (Client.CliId);
    end;

  RemoveFromQueue( Client.cliID);

  ReleaseMutex(Mutex);
  Label1.caption :=  'Client Count: ' + intTostr(Tcpserver.ClientCount );

end;

procedure TFormServer.TcpserverDataAvailable(Sender: TObject; ErrCode: Word);
var
    Cli: TWSocketThrdClient;
    RcvdLine,NewData,history: string;
    aBrain: TSoccerBrain;
    oldGender: Char;
    ts: TStringList;
    i,aValue: Integer;
    anAuth: TAuthInfo;
    tsNationTeam: TStringList;
    aValidPlayer: TValidPlayer;
    alvlUp: TLevelUp;
    ConnGame,ConnAccount : TMyConnection;
    MyQueryCheat,MyQueryTeam:  TMyQuery;
    label cheat;
begin
  try
    Cli := Sender as TWSocketThrdClient;
    RcvdLine :=  RemoveEndOfLine  (Cli.ReceiveStr);
    Cli.Processing := True;
    ts:= TStringList.Create;
    ts.StrictDelimiter := True;
    ts.CommaText := RcvdLine;

    if (( GetTickCount - Cli.lastTickCount ) < GLOBAL_COOLDOWN )   then begin
      cli.sReason:= 'GLOBAL COOLDOWN: ' + RcvdLine;
      cli.sreason := LeftStr( cli.sreason , 255);
      goto cheat;
    end;
    Cli.lastTickCount := GetTickCount;

    {$IFDEF  useMemo}
    if memo1.Lines.Count > 300 then
      memo1.Lines.Clear;
    if Length(RcvdLine) = 0 then  Exit;
    Display('Received from ' + Cli.GetPeerAddr  + ': ''' + RcvdLine + '''');
    {$ENDIF  useMemo}





    if not IsStandardText ( RcvdLine ) then begin
      cli.sReason:= 'Not Standard Text';
      goto cheat;
    end;

    if ts.Count < 1 then begin
      cli.sReason:= 'Missing paramenter';
      goto Cheat;
    end;



      // quando la partita termina la lista degli spettatori viene eliminata nel destroy del brain
    if ts[0] ='login' then begin
      validate_login (ts.CommaText, cli);
      if cli.sReason <> '' then goto cheat;

      anAuth := CheckAuth (ts[1],ts[2]);
      case anAuth.AccountStatus  of
        0: begin  // login incorrect
          Cli.SendStr( 'info,errorlogin' + EndOfline);

        end;
        1: begin  // ok login, but no team
          (* Mando la pwdTicket *)
          cli.GmLevel := anAuth.GmLevel;
          Cli.CliId := anAuth.account;
          Cli.sPassWord  := anAuth.password;
          Cli.Username := anAuth.UserName;
          Cli.Flags :=  anAuth.Flags;


          // preparo world.countries.ini direttamente nell'FTP
          Cli.SendStr ( 'BEGINWC,' + tsWorldCountries.commatext + EndofLine);  // diretto

        end;
        2: begin  // all ok
          Cli.CliId := anAuth.account;
          Cli.sPassWord  := anAuth.password;
          Cli.Username := anAuth.UserName;
          Cli.Flags :=  anAuth.Flags;


          cli.GmLevel := anAuth.GmLevel;
          Cli.GuidTeams := anAuth.GuidTeams;
          Cli.WorldTeam := anAuth.WorldTeam;
          Cli.teamName  := anAuth.TeamName ;
          Cli.nextHA := anAuth.nextha;
          Cli.mi := anAuth.mi;
          aBrain :=  inLiveMatchGuidTeam ( 'f', Cli.GuidTeams[1] );
          if aBrain = nil then
            aBrain :=  inLiveMatchGuidTeam ( 'm',Cli.GuidTeams[2] );

          if aBrain = nil then begin
            Cli.ActiveGender := 'm';
            Cli.ActiveGenderN := 2;
            Cli.SendStr( 'guid,' + Cli.ActiveGender + ','+ IntToStr(Cli.GuidTeams[2] ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + EndofLine);
          end
          else begin // reconnect
           // if GetTickCount - aBrain.FinishedTime < 25000 then  begin // a 30 secondi lo cancello
            if ( not aBrain.Finished ) or (  (aBrain.Finished ) and ((GetTickCount - aBrain.FinishedTime) < 10000 )) then begin  // 10 secondi

              if aBrain.Score.TeamGuid [0] = Cli.GuidTeams[1] then begin
                aBrain.Score.CliId[0]:= Cli.CliId ;
                aBrain.Score.AI [0] := False;                            // annulla la AI
              end
              else  if aBrain.Score.TeamGuid [1] = Cli.GuidTeams[1] then  begin
                aBrain.Score.CliId[1]:= Cli.CliId ;
                aBrain.Score.AI [1] := False;  // annulla la AI
              end
              else if aBrain.Score.TeamGuid [0] = Cli.GuidTeams[2] then begin
                aBrain.Score.CliId[0]:= Cli.CliId ;
                aBrain.Score.AI [0] := False;                            // annulla la AI
              end
              else  if aBrain.Score.TeamGuid [1] = Cli.GuidTeams[2] then  begin
                aBrain.Score.CliId[1]:= Cli.CliId ;
                aBrain.Score.AI [1] := False;  // annulla la AI
              end;
              cli.Brain := TObject(aBrain);
              Cli.ActiveGender := TSoccerBrain( Cli.Brain).Gender;
              Cli.ActiveGenderN :=  TSoccerBrain( Cli.Brain).GenderN;

              Cli.SendStr( 'GUID,'+Cli.ActiveGender+',' + IntToStr(Cli.GuidTeams[2] ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + ',' +
              'BEGINBRAIN' +  AnsiChar ( abrain.incMove )   +  brainManager.GetBrainStream ( abrain ) + EndofLine);
            end
            else begin  // spedisco la formazione
              Cli.ActiveGender := 'm';
              Cli.ActiveGenderN := 2;
              Cli.SendStr( 'guid,' + Cli.ActiveGender +',' +IntToStr(Cli.GuidTeams[2] ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + EndofLine);
            end;
          end;

        end;
      end;
    end
    else if  ts[0] ='switch' then begin
      oldGender := Cli.ActiveGender;
      if Cli.ActiveGender = 'f' then begin
        Cli.ActiveGender := 'm';
        Cli.ActiveGenderN := 2;
        if oldGender <> Cli.ActiveGender then
          Cli.SendStr( 'guid,' + Cli.ActiveGender +',' +IntToStr(Cli.GuidTeams[2] ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + EndofLine);
      end
      else if Cli.ActiveGender = 'm' then begin
        Cli.ActiveGender := 'f';
        Cli.ActiveGenderN := 1;
        if oldGender <> Cli.ActiveGender then
          Cli.SendStr( 'guid,' + Cli.ActiveGender +',' +IntToStr(Cli.GuidTeams[1] ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + EndofLine);
      end;
    end

    else if ts[0] ='selectedteam' then begin
        validate_clientcreateteam (ts.CommaText , cli) ;
        if cli.sReason <> ''  then goto cheat;
      // Creo il team, creo i players, mando al client il team
        Cli.ActiveGender := 'f';
        Cli.ActiveGenderN := 1;
        Cli.GuidTeams[1] := CreateGameTeam ( Cli.ActiveGender, Cli, ts[1]);  // ts[1] è guid world.teams, non la Guidteam
        if cli.sReason <> ''  then goto cheat;
        reset_formation (cli);
        Cli.GuidTeams[2] := CreateGameTeam ( Cli.ActiveGender, Cli, ts[1]);  // ts[1] è guid world.teams, non la Guidteam
        if cli.sReason <> ''  then goto cheat;
        Cli.ActiveGender := 'm';
        Cli.ActiveGenderN := 2;
        reset_formation (cli);
        Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeams[ Cli.ActiveGenderN  ],Cli.ActiveGender ) + EndofLine);
    end

    else if ts[0]= 'getformation' then  begin
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;

        Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);
    end
    else if ts[0]= 'setformation' then  begin
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;
       (* Valida solo il formmato. non è la checkformation *)
        validate_setformation  (  ts.CommaText , cli) ;
//          if cli.sReason <> ''  then goto cheat;

      // STORE nel DB della formation diretta della commatext
          store_formation (Cli.ActiveGender,ts.CommaText );
          Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);
    end
    else if ts[0]= 'resetformation' then  begin
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;
       (* Valida solo il formmato. non è la checkformation *)
        reset_formation (cli);
//        if cli.sReason <> ''  then goto cheat;

        Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);
    end
    else if ts[0]= 'setuniform' then  begin
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;

        validate_setuniform  (ts.CommaText , cli) ;
        if cli.sReason <> ''  then goto cheat;

      // STORE nel DB delle uniform
          store_uniform (  Cli.GuidTeams[Cli.ActiveGenderN] , ts.CommaText );
          Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);
    end
    else if ts[0]= 'levelupattribute' then  begin  // guid attr
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;
        validate_levelupAttribute (ts.CommaText, Cli); // levelup, ids, attr or talentID  // qui controlla sql injection
        if cli.sReason <> '' then  goto cheat;
        TryDecimalStrToInt( ts[1], aValue); // ids è numerico passato da validate_levelup
        aValidPlayer := validate_player(  aValue, cli ); // disqualified ora non ci interessa , mi interessa la chance in base all'età

        alvlUp:=  pvpTrylevelUpAttribute (MySqlServerGame,Cli.ActiveGender,  StrToInt(ts[1]),  StrToInt( ts[2]), aValidPlayer ); // il client aggiorna in mybrainformation e resetta le infoxp
        Cli.SendStr ( 'la,' + IntToStr(alvlup.Guid) + ',' + IntToStr(Integer(alvlup.value)) + ',' + alvlUp.xpString +  EndofLine);
        //Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeam ) + EndofLine);
    end
    else if ts[0]= 'leveluptalent' then  begin  // guid attr
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;
        validate_levelupTalent (ts.CommaText, Cli); // levelup, ids, attr or talentID  // qui controlla sql injection
        if cli.sReason <> '' then  goto cheat;
        TryDecimalStrToInt( ts[1], aValue); // ids è numerico passato da validate_levelup
        aValidPlayer:= validate_player(aValue, cli  ); // disqualified ora non ci interessa , mi interessa la chance in base all'età
        if cli.sReason <> '' then  goto cheat;
        if aValidPlayer.talentID1 <> 0 then begin
          cli.sreason := 'player with talent tryLevelup talent';
          goto cheat;
        end;

        WaitForSingleObject(Mutex,INFINITE);
        alvlUp:=  pvpTrylevelUpTalent (MySqlServerGame, Cli.ActiveGender, StrToInt(ts[1]),  StrToInt( ts[2]), aValidPlayer  ); // il client aggiorna in mybrainformation e resetta le infoxp
        ReleaseMutex(Mutex);
//          Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeam ) + EndofLine);
        Cli.SendStr ( 'lt,' + IntToStr(alvlup.Guid) + ',' + IntToStr(Integer(alvlup.value)) + ',' + alvlUp.xpString + EndofLine);
    end
    else if ts[0]= 'sell' then  begin  // ids value
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;

        validate_Sell (ts.CommaText, Cli);
        if cli.sReason <> '' then  goto cheat;
        MarketSell (  Cli, ts.CommaText ); //<-- va sul db f_game.players ---> f_game.market  // deve essere un player di quel guidteam. faccio tutto qui per economia
        if cli.sReason <> '' then  goto cheat;
        Cli.SendStr ( 'BEGINTEAM'  + GetTeamStream ( Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);  // aggiorna completamente il client

    end
    else if ts[0]= 'cancelsell' then  begin  // ids value
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;

        validate_CancelSell (ts.CommaText, Cli);
        if cli.sReason <> '' then  goto cheat;
        MarketCancelSell (  Cli, ts.CommaText ); //<-- va sul db f_game.players ---> f_game.market  // deve essere un player di quel guidteam. faccio tutto qui per economia
        if cli.sReason <> '' then  goto cheat;
        Cli.SendStr ( 'BEGINTEAM'  + GetTeamStream (Cli.GuidTeams[Cli.ActiveGenderN] ,Cli.ActiveGender) + EndofLine);  // aggiorna completamente il client

    end
    else if ts[0]= 'buy' then  begin  // ids
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;

        validate_Buy (ts.CommaText, Cli);
        if cli.sReason <> '' then  goto cheat;
        MarketBuy ( Cli, ts.CommaText );
        if cli.sReason = 'marketbuy_player_not_found' then begin
          Cli.SendStr ( 'info,'  + cli.sReason + EndofLine);
          cli.Processing := False;
          ts.free;
          Exit;
        end
        else if cli.sReason <> '' then  goto cheat;
        Cli.SendStr ( 'BEGINTEAM'  + GetTeamStream ( Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);  // aggiorna completamente il client

    end
    else if ts[0]= 'market' then begin  // maxvalue
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;

        validate_market (ts.CommaText, Cli);
        if cli.sReason <> '' then  goto cheat;
        Cli.SendStr ( 'BEGINMARKET'  + GetMarketPlayers ( Cli.ActiveGender,Cli.GuidTeams[Cli.ActiveGenderN], StrToInt(ts[1]) ) + EndofLine);  // aggiorna completamente il client

    end
    else if ts[0]= 'dismiss' then  begin  // ids
        if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
          cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
          if cli.sReason <> '' then  goto cheat;
        end;

        validate_dismiss (ts.CommaText, Cli);
        if cli.sReason <> '' then  goto cheat;
        DismissPlayer ( Cli, ts.CommaText );
        if cli.sReason <> '' then  goto cheat;
        Cli.SendStr ( 'BEGINTEAM'  + GetTeamStream (Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);  // aggiorna completamente il client

    end
    else if ts[0] ='cancelqueue' then begin
      if not inLiveMatchCliid(Cli.cliId) then begin
        RemoveFromQueue( Cli.cliId );
        //Cli.SendStr ( 'cancelqueueok' + EndofLine );  // rispedisco la formazione
        // rispedisco la formazione, ma potrebbe essere che la partita è stata creata. sta a team 0 e non riceve brain quindi il client si è perso
        if not inLiveMatchCliid( Cli.CliId ) then
          Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);
          // altriemtni aspetta il beginbrain
      end;
    end
    else if ts[0] ='cancelspectatorqueue' then begin
      if not inSpectator(Cli.cliId) then begin
        //RemoveFromSpectator ( Cli.cliId );
//        Cli.SendStr ( 'cancelspectatorqueueok' + EndofLine );
        Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeams[Cli.ActiveGenderN],Cli.ActiveGender ) + EndofLine);
      end
      else begin
        RemoveFromSpectator ( Cli.cliId );
//        aBrain := BrainManager.FindBrain ( cli.CliId );// cerca in brainManager il cliId del client
//        if aBrain <> nil then begin
//          aBrain.RemoveSpectator (Cli.CliId); // rimuovo me stesso client al brain di un altro wSocket
          Cli.Brain := Nil;
          Cli.SendStr ( 'closeviewmatchok' + EndofLine );
//        end;

      end;
    end
    else if  ts[0] ='closeviewmatch' then begin
        { smette di guardare la partita di un altro giocatore o della AI }
        aBrain := BrainManager.FindBrain ( cli.CliId );// cerca in brainManager il cliId del client
      if aBrain <> nil then begin
        aBrain.RemoveSpectator (Cli.CliId); // rimuovo me stesso client al brain di un altro wSocket
        Cli.Brain := Nil;
      end;
      Cli.SendStr ( 'closeviewmatchok' + EndofLine );

    end
    else if ts[0] ='queue' then begin
        if checkformation (cli) and not InQueue(Cli.CliId ) and not inLivematchCliId(Cli.CliId) and not inSpectator(Cli.CliId) then begin
          //Cli.MarketValueTeam := GetMarketValueTeam ( Cli.GuidTeam );


          ConnGame := TMyConnection.Create(nil);
          Conngame.Server := MySqlServerGame;
          Conngame.Username:='root';
          Conngame.Password:='root';
          Conngame.Database:= Cli.ActiveGender +'_game';
          Conngame.Connected := True;


          MyQueryTeam := TMyQuery.Create(nil);
          MyQueryTeam.Connection := ConnGame;   // game
          MyQueryTeam.SQL.Text :=  'select nextha, rank from ' + Cli.ActiveGender +'_game.teams where guid=' + IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]);
          MyQueryTeam.Execute;

          Cli.nextHA := MyQueryTeam.FieldByName('nextha').AsInteger ;
          Cli.rank := MyQueryTeam.FieldByName('rank').AsInteger ;
          MyQueryTeam.Free;

          Conngame.connected := False;
          Conngame.free;
          Cli.TimeStartQueue := GetTickCount; // dopo di che parte il bot
          Queue.Add (Cli);
          Cli.SendStr('avg' + EndOfline);
        end
        else begin
          cli.sreason := ' checkformation InQueue,InliveMatch,inSpectator: ';
          goto cheat;

        end
      end
      else if  ts[0] ='listmatch' then begin
          { ottiene la lista di matches }
          // 0=listmatch
          newData :=  GetListActiveBrainStream ( Cli.ActiveGender ) ;
          if Length(NewData) > 0 then
            Cli.SendStr ( 'BEGINAML' + newData + EndofLine);  // diretto

      end
      else if  ts[0] ='viewmatch' then begin
        validate_viewmatch (ts.CommaText, Cli);
        if cli.sReason <> '' then  goto cheat;
          // guarda la partita di un altro giocatore o della AI
          // 0viewmatch 1=idMatch   ( date,time e team)
          // trovare il turno corrente incMove
          aBrain := BrainManager.FindBrain ( ts[1] );// cerca in brainManager il BrainIds di una partita
          if aBrain <> nil then begin
            if aBrain.GameStarted then begin
              aBrain.lstSpectator.Add(Cli.CliId); // aggiungo me stesso client al brain di un altro wSocket
              Cli.Brain := aBrain;
            end;
          end;
      end

  // in coda
    // cli.activegender e cli.activegenderN sono settate al login o con switch
    // il comando va direttamente al brain del client, quello su cui sta giocando.
    // se desidero input da altri client devo assegnare il brain dell'altro client ( TSoccerBrain(Cli.Brain):= altrobrain
      else if (ts[0] ='PLM')  or (ts[0] ='TACTIC')then begin
          validate_CMD4 (ts.CommaText, Cli); // cli.pwd cli.guidteam, cli.brain cli.team, cli.brain.teamturn
          if cli.sReason <> '' then  goto cheat;

        // 0=PLM o TACTIC 1=ids 2=cellX 3=CellY
         TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) +',' + ts[0]  + ',' + ts[1] + ',' + ts[2] +  ',' + ts[3]  );
      end
      else if (ts[0] ='SUB') then begin
          validate_CMD_subs (ts.CommaText, Cli); // cli.pwd cli.guidteam, cli.brain cli.team, cli.brain.teamturn
          if cli.sReason <> '' then  goto cheat;
        // 0=SUBS 1=ids 2=is
         TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2]   );
      end
      else if (ts[0] ='PASS') or (ts[0] ='COR')or (ts[0] ='CRO2')  then begin  // sul brain iscof batterà il corner
          validate_CMD1 (ts.CommaText,Cli);
          if cli.sReason <> '' then   goto cheat;
        // 0=PASS
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] );
      end
      else if (ts[0] ='PRS') or (ts[0] ='POS') or (ts[0] ='PRO')  then begin
          validate_CMD1 (ts.CommaText, Cli);
          if cli.sReason <> '' then   goto cheat;
        // 0=PRS...
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0]);
      end
      else if (ts[0] ='PRE') or (ts[0] ='TAC') or (ts[0] ='STAY') or (ts[0] ='FREE') then begin
          validate_CMD2 (ts.CommaText, Cli);
          if cli.sReason <> '' then   goto cheat;
        // 0=BUFF DMF... 1=ids di chi fa il buff
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] );
      end
      else if (ts[0] ='BUFFD') or (ts[0] ='BUFFM') or (ts[0] ='BUFFF') then begin
          validate_CMD2 (ts.CommaText, Cli);
          if cli.sReason <> '' then   goto cheat;
        // 0=PRE... 1=ids di chi fa il tackle o il pressing
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] );
      end
      else if (ts[0] ='CRO') or (ts[0] ='SHP') or (ts[0] ='DRI')  then begin
          validate_CMD3 (ts.CommaText, cli);
          if cli.sReason <> '' then   goto cheat;
        // 0=CRO... 1=cellX 2=CellY
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] );
      end
        else if ts[0] ='LOP' then begin
          validate_CMDlop (ts.CommaText, cli);
          if cli.sReason <> '' then   goto cheat;
        // 0=LOP... 1=cellX 2=CellY 3=N o GKLOP
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3] );
      end
      else if (ts[0] ='CORNER_ATTACK.SETUP') or (ts[0] ='FREEKICK2_ATTACK.SETUP') then begin
          validate_CMD_coa(ts.CommaText, cli);
          if cli.sReason <> '' then  goto cheat;
        // 0=CORNER_ATTACK.SETUP 1=cof 2=coa1 3=coa2 4=coa3
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3] + ',' + ts[4]);
      end
      else if (ts[0] ='CORNER_DEFENSE.SETUP') or (ts[0] ='FREEKICK2_DEFENSE.SETUP')  then begin
          validate_CMD_cod(ts.CommaText, Cli);
          if cli.sReason <> '' then  goto cheat;
        // 0=CORNER_DEFENSE.SETUP 1=cod1 2=cod2 3=cod3
          TSoccerBrain(Cli.Brain).BrainInput (IntToStr(Cli.GuidTeams[Cli.ActiveGenderN])+ ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3] );
      end
      else if ts[0] ='FREEKICK3_DEFENSE.SETUP' then begin
          validate_CMD_bar(ts.CommaText, Cli);
          if cli.sReason <> '' then  goto cheat;
        // 0=FREEKICK3_DEFENSE.SETUP 1=bar1 2=bar2 3=bar3 4=bar4
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3]+ ',' + ts[4] );
      end
      else if (ts[0] ='FREEKICK1_ATTACK.SETUP') or (ts[0] ='FREEKICK3_ATTACK.SETUP') or (ts[0] ='FREEKICK4_ATTACK.SETUP')  then begin
          validate_CMD2(ts.CommaText, Cli);
          if cli.sReason <> '' then  goto cheat;
        // 0=FREEKICK1_ATTACK.SETUP 1=fkf1 o3o4
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] +  ',' + ts[1]);
      end
      else if ts[0] ='AUTO'  then begin
//          validate_aiteam (ts.CommaText, cli);
//          if cli.sReason <> '' then  goto cheat;
        if TSoccerBrain(Cli.Brain).Score.TeamGuid[0] = Cli.GuidTeams[Cli.ActiveGenderN] then
          TSoccerBrain(Cli.Brain).Score.AI[0]:= not TSoccerBrain(Cli.Brain).Score.AI[0]
        else if TSoccerBrain(Cli.Brain).Score.TeamGuid[1] = Cli.GuidTeams[Cli.ActiveGenderN] then
          TSoccerBrain(Cli.Brain).Score.AI[1]:= not TSoccerBrain(Cli.Brain).Score.AI[1];

      end


(* GM COMMANDS *)

  else if ts[0] ='setball'  then begin
        validate_CMD3 (ts.CommaText, cli);
        if cli.sReason <> '' then  goto cheat;
        if Cli.GmLevel > 0 then begin
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2]  );
        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;
  end
  else if ts[0] ='utime'   then begin
        validate_CMD1 (ts.CommaText, cli);
        if cli.sReason <> '' then  goto cheat;
        if Cli.GmLevel > 0 then begin
          TSoccerBrain(Cli.Brain).utime := True;
        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;
  end
  else if ts[0] ='setturn'   then begin
        validate_CMD2 (ts.CommaText, cli);
        if cli.sReason <> '' then  goto cheat;
        if Cli.GmLevel > 0 then begin
          TSoccerBrain(Cli.Brain).Minute := StrToInt(ts[1]);
          if StrToInt(ts[1]) < 120 then
            TSoccerBrain(Cli.Brain).FlagEndGame := False;

        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;
  end
  else if (ts[0] ='debug_tackle_failed') or ( ts[0] = 'debug_setfault' ) or ( ts[0] = 'debug_setred' ) or
          (ts[0] ='debug_setalwaysgol') or ( ts[0] = 'debug_setposcrosscorner' )  or ( ts[0] = 'debug_buff100' ) then begin
        validate_debug_CMD2 (ts.CommaText, cli);
        if cli.sReason <> '' then  goto cheat;
        if Cli.GmLevel > 0 then begin
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1]   )
        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;
  end
  else if ts[0] ='testcorner'  then begin
     validate_CMD2 (ts.CommaText, cli);
        if cli.sReason <> '' then  goto cheat;
        if Cli.GmLevel > 0 then begin
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1]   )
        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;

  end
  else if ts[0] ='randomstamina'  then begin
        if Cli.GmLevel > 0 then begin
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0]  )
        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;

  end
  else if ts[0] ='setplayer'  then begin
        if Cli.GmLevel > 0 then begin
        validate_setplayer (ts.CommaText, cli);
        if cli.sReason <> '' then  goto cheat;
          TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3] )
        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;
  end
  else if ts[0] ='aiteam'  then begin
        if Cli.GmLevel > 0 then begin
          validate_aiteam (ts.CommaText, cli);
          if cli.sReason <> '' then  goto cheat;
          TSoccerBrain(Cli.Brain).Score.AI[ StrToInt(ts[1])  ]:= StrToBool(ts[2]);
        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;
  end
  else if ts[0] ='pause'  then begin
        if Cli.GmLevel > 0 then begin
          validate_pause (ts.CommaText, cli);
          if cli.sReason <> '' then  goto cheat;
          TSoccerBrain(Cli.Brain).paused := StrToBool(ts[1]);
        end
        else begin
          cli.sReason := 'no GmLevel';
          goto cheat;
        end;
  end

   (* UNA VOLTA ALL'INIZIO DEL GAME *)
  else if ts[0] ='selectedcountry' then begin

        validate_getteamsbycountry (ts.CommaText, Cli );
        if cli.sReason <> ''  then goto cheat;



        tsNationTeam:= TStringList.Create;
        PrepareNationTeams ( StrToIntDef(ts[1],1), tsNationTeam );
        Cli.SendStr ( 'BEGINWT,' + tsNationTeam.commatext + EndofLine);  // diretto
//            ShowMessage(  IntToStr( Length(tsNationTeam.CommaText) ) );

//              SS := TStringStream.Create('');
//              SS.CopyFrom(bMMworld.teams, 0);  // caricata all'avvio del server 1 volta
//              NewData := SS.DataString;
//              FormServer.TcpServer.Client [i].SendStr ( NewData + EndofLine);
//              SS.Free;
  end



  else begin
    // input non valido
cheat:

      ConnAccount := TMyConnection.Create(nil);
      ConnAccount.Server := MySqlServerAccount;
      ConnAccount.Username:='root';
      ConnAccount.Password:='root';
      ConnAccount.Database:='realmd';
      ConnAccount.Connected := True;


      MyQueryCheat := TMyQuery.Create(nil);

      MyQueryCheat.Connection := ConnAccount;
      cli.sReason  := cli.sReason + ': ' + ts.commatext;
      cli.sreason := LeftStr( cli.sreason , 255);
      Memo1.Lines.Add(cli.sReason + ':' + ts.commatext );
      MyQueryCheat.SQL.Text := 'INSERT into cheat_detected (reason) values ("' + cli.sReason + '")';
      MyQueryCheat.Execute ;
      MyQueryCheat.Free;
      ConnAccount.Connected := false;
      ConnAccount.free;

      Cli.sreason :='';
      cli.Processing := False;
  end;

   // Application.ProcessMessages;
    cli.Processing := False;
    ts.free;
    if tsNationTeam <> nil then tsNationTeam.Free;
  except
      on E: Exception do Begin
        Cli.sreason :='';
        cli.Processing := False;
        ts.free;
        if tsNationTeam <> nil then tsNationTeam.Free;


        ConnAccount := TMyConnection.Create(nil);
        ConnAccount.Server := MySqlServerAccount;
        ConnAccount.Username:='root';
        ConnAccount.Password:='root';
        ConnAccount.Database:='realmd';
        ConnAccount.Connected := True;


        MyQueryCheat := TMyQuery.Create(nil);

        MyQueryCheat.Connection :=  ConnAccount ;
        MyQueryCheat.SQL.Text := 'INSERT into cheat_detected (reason) values ("' + E.ToString + ' TFormServer.TcpserverDataAvailable ' + '")';
        MyQueryCheat.Execute ;
        MyQueryCheat.Free;
        ConnAccount.Connected := false;
        ConnAccount.free;
        Exit;
      End;
  end;
end;

function TFormServer.GetTeamStream ( GuidTeam: integer; fm :char) : string;
var
  CompressedStream: TZCompressionStream;
  MM, MM2 : TMemoryStream;
  SS: TStringStream;
  i,age: Integer;
  tmps: string[255];
  tmpi: Integer;
  tmpb: Byte;
  ConnGame : TMyConnection;
  MyQueryTeam, qPlayers: TMyQuery;
  country: Word;
  face,fitness,morale: integer;
begin


  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=fm+ '_game';
  Conngame.Connected := True;

  // Team in generale

  MyQueryTeam := TMyQuery.Create(nil);
  MyQueryTeam.Connection := ConnGame;   // game
  MyQueryTeam.SQL.text := 'SELECT guid, worldteam, teamName, uniforma, uniformh, nextha, mi, points,matchesplayed,money,rank FROM '+fm
                +'_game.teams where guid = ' + IntToStr(GuidTeam) ;
  MyQueryTeam.Execute ;



  MM := TMemoryStream.Create;
  MM.Size:=0;

  tmpi:=MyQueryTeam.FieldByName('guid').AsInteger;
  MM.Write( @tmpi, SizeOf(Integer) ) ;
  tmps:=MyQueryTeam.FieldByName('teamname').asString;
  MM.Write( @tmps, Length(tmps) +1 ) ;
  tmps:=MyQueryTeam.FieldByName('uniformh').asString;
  MM.Write( @tmps, Length(tmps) +1 ) ;
  tmps:=MyQueryTeam.FieldByName('uniforma').asString;
  MM.Write( @tmps, Length(tmps) +1 ) ;
  tmpi:=MyQueryTeam.FieldByName('nextha').AsInteger;
  MM.Write( @tmpi, SizeOf(byte) ) ;
  tmpi:=MyQueryTeam.FieldByName('mi').AsInteger;
  MM.Write( @tmpi, SizeOf(integer) ) ;
  tmpi:=MyQueryTeam.FieldByName('points').AsInteger;
  MM.Write( @tmpi, SizeOf(integer) ) ;
  tmpi:=MyQueryTeam.FieldByName('matchesplayed').AsInteger;
  MM.Write( @tmpi, SizeOf(integer) ) ;
  tmpi:=MyQueryTeam.FieldByName('money').AsInteger;
  MM.Write( @tmpi, SizeOf(integer) ) ;
  tmpb:=MyQueryTeam.FieldByName('rank').AsInteger;
  MM.Write( @tmpb, SizeOf(byte) ) ;

  MM.Write( @fm, SizeOf(byte) ) ;

  MyQueryTeam.Free;


  // Singoli players

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'SELECT * from '+fm+'_game.players WHERE team =' + IntToStr(GuidTeam)+' and young=0' ;

  qPlayers.Execute ;


  tmpi:= qPlayers.RecordCount;
  MM.Write( @tmpi , SizeOf(Byte) ) ;

  for I := qPlayers.RecordCount -1 downto 0  do begin
    tmpi:= qPlayers.FieldByName('guid').AsInteger;
    MM.Write( @tmpi, sizeof(integer) );

    tmps := qPlayers.FieldByName('name').AsString;
    MM.Write( @tmps[0] , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    tmpi := qPlayers.FieldByName('Matches_Played').AsInteger;
    MM.Write( @tmpi, sizeof(SmallInt) );

    tmpi := qPlayers.FieldByName('Matches_Left').AsInteger;
    MM.Write( @tmpi, sizeof(SmallInt) );

    Age:= Trunc(  qPlayers.FieldByName('Matches_Played').AsInteger  div Soccerbrainv3.SEASON_MATCHES) + 18 ;
    MM.Write( @Age, sizeof(byte) );

    tmpb := qPlayers.FieldByName('talentid1').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := qPlayers.FieldByName('talentid2').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpi := qPlayers.FieldByName('stamina').AsInteger;
    MM.Write( @tmpi, sizeof(SmallInt) );

    tmpb:= qPlayers.FieldByName('speed').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= qPlayers.FieldByName('defense').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= qPlayers.FieldByName('passing').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= qPlayers.FieldByName('ballcontrol').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= qPlayers.FieldByName('shot').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= qPlayers.FieldByName('heading').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );

    tmpb:= qPlayers.FieldByName('formation_x').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= qPlayers.FieldByName('formation_y').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );

    tmpb := qPlayers.FieldByName('injured').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := qPlayers.FieldByName('totyellowcard').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := qPlayers.FieldByName('disqualified').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := qPlayers.FieldByName('onmarket').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );

    face:= qPlayers.FieldByName('face').AsInteger;
    MM.Write( @face , sizeof(integer) );

    fitness:= qPlayers.FieldByName('fitness').AsInteger;
    MM.Write( @fitness , sizeof(byte) );

    morale:= qPlayers.FieldByName('morale').AsInteger;
    MM.Write( @morale , sizeof(byte) );

    country:= qPlayers.FieldByName('country').AsInteger;
    MM.Write( @country , sizeof(word) );

    tmpi := qPlayers.FieldByName('DevA').asinteger;
    MM.Write( @tmpi , sizeof(word) );
    tmpi := qPlayers.FieldByName('DevT').asinteger;
    MM.Write( @tmpi , sizeof(word) );
    tmpi := qPlayers.FieldByName('DevI').asinteger;
    MM.Write( @tmpi , sizeof(word) );

    tmps := qPlayers.FieldByName('history').AsString;
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa
    tmps := qPlayers.FieldByName('xp').AsString;
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    tmpi := qPlayers.FieldByName('xpDevA').asinteger;
    MM.Write( @tmpi , sizeof(word) );
    tmpi := qPlayers.FieldByName('xpDevT').asinteger;
    MM.Write( @tmpi , sizeof(word) );
    tmpi := qPlayers.FieldByName('xpDevI').asinteger;
    MM.Write( @tmpi , sizeof(word) );

    qPlayers.Next;

  end;

  qPlayers.Free;
  Conngame.Connected := false;
  Conngame.Free;

              // senza compressione
  {SS := TStringStream.Create('');
  SS.CopyFrom( brain.MMbraindata, 0);
  NewData := SS.DataString;
  SS.Free;   }

  MM2:= TMemoryStream.Create;
  // con compressione
  CompressedStream := TZCompressionStream.Create(MM2, zcDefault); // create the compression stream
  CompressedStream.Write( MM.Memory , MM.size); // move and compress the InBuffer string -> destination stream  (MyStream)
  CompressedStream.Free;
  SS := TStringStream.Create('');
  MM2.Position :=0;
  SS.CopyFrom( MM2, 0);
  Result := SS.DataString;
  MM2.Free;
  SS.Free;
  MM.Free;
end;
function TFormServer.GetListActiveBrainStream  (fm : char): string;
var
  CompressedStream: TZCompressionStream;
  SS: TStringStream;
  i: Integer;
  MM,MM2: TMemoryStream;
  lstBrainTmp: TObjectList<TSoccerBrain>;
begin

  WaitForSingleObject(Mutex,INFINITE);
  if BrainManager.lstbrain.count > 0 then begin
    // ne prendo 20 random
    lstBrainTmp:= TObjectList<TSoccerBrain>.Create(False);
    for i := BrainManager.lstbrain.count -1 downto 0 do begin // ne faccio una copia in una tmp
      if BrainManager.lstBrain[i].Gender = fm then
      lstBrainTmp.Add(BrainManager.lstBrain[i]);
    end;


    if lstBrainTmp.count > 20 then begin
      while lstBrainTmp.count > 20 do begin
        lstBrainTmp.Delete( RndGenerate0(lstBrainTmp.count-1 ) );
      end;
    end;

    MM := TMemoryStream.Create;
    MM.Write( @lstBrainTmp.count , SizeOf(word) );

    for i := lstBrainTmp.count -1 downto 0 do begin

      MM.Write( @lstBrainTmp[i].BrainIDS, Length (lstBrainTmp[i].BrainIDS) +1 );
      MM.Write( @lstBrainTmp[i].Score.UserName[0], Length (lstBrainTmp[i].Score.UserName[0] ) +1 );
      MM.Write( @lstBrainTmp[i].Score.UserName[1], Length (lstBrainTmp[i].Score.UserName[1]) +1 );
      MM.Write( @lstBrainTmp[i].Score.Team[0], Length (lstBrainTmp[i].Score.Team[0]) +1 );
      MM.Write( @lstBrainTmp[i].Score.Team[1], Length (lstBrainTmp[i].Score.Team[1]) +1 );
      MM.Write( @lstBrainTmp[i].Score.Country[0], sizeof (word ) );
      MM.Write( @lstBrainTmp[i].Score.Country[1], sizeof (word ) );
      MM.Write( @lstBrainTmp[i].Score.Gol[0], sizeof (byte ) );
      MM.Write( @lstBrainTmp[i].Score.Gol[1], sizeof (byte ) );
      MM.Write( @lstBrainTmp[i].minute, sizeof (byte ) );

    end;


    lstBrainTmp.Free;
    ReleaseMutex(Mutex);

                // senza compressione
  {  SS := TStringStream.Create('');
    MM.Position :=0;
    SS.CopyFrom( MM, 0);
    Result := SS.DataString;
    SS.Free;  }
  //  MM.SaveToFile (  dir_log  + 'LAB.iS' ) ;
    MM2:= TMemoryStream.Create;
    // con compressione
    CompressedStream := TZCompressionStream.Create(MM2, zcDefault); // create the compression stream
    CompressedStream.Write( MM.Memory , MM.size); // move and compress the InBuffer string -> destination stream  (MyStream)
    CompressedStream.Free;
    SS := TStringStream.Create('');
    MM2.Position :=0;
    SS.CopyFrom( MM2, 0);
    Result := SS.DataString;
    MM2.Free;
    SS.Free;
    MM.Free;
  end
  else begin
    ReleaseMutex(Mutex);
    Result := '';
  end;

end;
function TFormServer.GetMarketPlayers ( fm :Char; MyTeam, Maxvalue: Integer) : string;
var
  CompressedStream: TZCompressionStream;
  SS: TStringStream;
  i: Integer;
  MM,MM2: TMemoryStream;
  name : Shortstring;
  guidplayer, sellprice ,  speed ,  defense,  passing, ballcontrol, shot, heading, talentid1,talentid2,matches_played,matches_left,face, country,fitness,morale : Integer;
  Count: Integer;
  ConnGame : TMyConnection;
  qMarket: TMyQuery;
begin
// MyTeam è except , non trova i suoi giocatori in vendita

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= fm +'_game';
  Conngame.Connected := True;


  qMarket := TMyQuery.Create(nil);
  qMarket.Connection := ConnGame;   // game
  qMarket.SQL.text := 'SELECT *  FROM ' + fm + '_game.market where sellprice <=' + IntToStr(Maxvalue) + ' and guidteam <> ' +
                             IntToStr( MyTeam)  +' order by rand() limit 20';
  qMarket.Execute ;



  Count := qMarket.RecordCount;

    MM := TMemoryStream.Create;
    MM.Write( @Count , SizeOf(word) );

    for i := qMarket.RecordCount -1 downto 0 do begin
      guidplayer:= qMarket.FieldByName('guidplayer').asInteger;
      name := qMarket.FieldByName('name').AsString;
      sellprice:= qMarket.FieldByName('sellprice').asInteger;
//      guidteam:= qMarket.FieldByName('guidteam').asInteger;
      speed:= qMarket.FieldByName('speed').asInteger;
      defense:= qMarket.FieldByName('defense').asInteger;
      passing:= qMarket.FieldByName('passing').asInteger;
      ballcontrol:= qMarket.FieldByName('ballcontrol').asInteger;
      shot:= qMarket.FieldByName('shot').asInteger;
      heading:= qMarket.FieldByName('heading').asInteger;
      talentID1:= qMarket.FieldByName('talentid1').asInteger;
      talentID2:= qMarket.FieldByName('talentid2').asInteger;
//      history := qMarket.FieldByName('history').AsString;
//      xp := qMarket.FieldByName('xp').AsString;
      matches_played:= qMarket.FieldByName('matches_played').asInteger;
      matches_left:= qMarket.FieldByName('matches_left').asInteger;
      face:= qMarket.FieldByName('face').asInteger;
      country:= qMarket.FieldByName('country').asInteger;
      fitness:= qMarket.FieldByName('fitness').asInteger;
      //morale:= qMarket.FieldByName('morale').asInteger;

      MM.Write( @guidplayer, sizeof ( integer ) );
      MM.Write( @name[0], Length (name) +1 );
      MM.Write( @sellprice, sizeof ( integer ) );
//      MM.Write( @guidteam, sizeof ( integer ) );

      MM.Write( @speed, sizeof ( byte ) );
      MM.Write( @defense, sizeof ( byte ) );
      MM.Write( @passing, sizeof ( byte ) );
      MM.Write( @ballcontrol, sizeof ( byte ) );
      MM.Write( @shot, sizeof ( byte ) );
      MM.Write( @heading, sizeof ( byte ) );
      MM.Write( @talentID1, sizeof ( byte ) );
      MM.Write( @talentID2, sizeof ( byte ) );

//      MM.Write( @history[0], Length (history) +1 );
//      MM.Write( @xp[0], Length (xp) +1 );

      MM.Write( @matches_played, sizeof ( word ) );
      MM.Write( @matches_left, sizeof ( word ) );
      MM.Write( @face, sizeof ( word ) );
      MM.Write( @country, sizeof ( word ) );
      MM.Write( @fitness, sizeof ( byte ) );
     // MM.Write( @morale, sizeof ( byte ) );

      qMarket.Next;
    end;

    qMarket.Free;
    Conngame.Connected := false;
    Conngame.Free;

    MM2:= TMemoryStream.Create;
    // con compressione
    CompressedStream := TZCompressionStream.Create(MM2, zcDefault); // create the compression stream
    CompressedStream.Write( MM.Memory , MM.size); // move and compress the InBuffer string -> destination stream  (MyStream)
    CompressedStream.Free;
    SS := TStringStream.Create('');
    MM2.Position :=0;
    SS.CopyFrom( MM2, 0);
    Result := SS.DataString;
    MM2.Free;
    SS.Free;
    MM.Free;
end;


procedure TFormServer.TcpserverLineLimitExceeded(Sender: TObject;
  RcvdLength: Integer; var ClearData: Boolean);
begin
    with Sender as TWSocketClient do begin
        Display('Line limit exceeded from ' + GetPeerAddr + '. Closing.');
        ClearData := TRUE;
        Close;
    end;

end;

procedure TFormServer.TcpserverSocksError(Sender: TObject; Error: Integer; Msg: string);
begin
        Memo1.Lines.add('on sockserror '+ Msg );

end;

procedure TFormServer.TcpserverThreadException(Sender: TObject;  AThread: TWsClientThread; const AErrMsg: string);
begin
    Display(TWsocketThrdServer(Sender).Name +   AErrMsg);

end;

procedure TFormServer.threadBotTimer(Sender: TObject);
begin

  if CheckBox1.Checked then begin
    if BrainManager.lstBrain.Count <  StrToIntDef( Edit1.Text,0 ) then begin
      if RndGenerate(100) <= 50 then
        CreateRandomBotMatch ( 'f' )
        else CreateRandomBotMatch ( 'm' );
    end;
  end;
  // ore 20.24 900-1000 partite
  // ora 16 19.59 400-500

  // al momento ne fa 50 al massimo con 100 utenti dentro

end;

procedure TFormServer.PrepareWorldCountries ( directory: string );
var
  MyQueryWC: TMyQuery;
  ini: TIniFile;
  i: Integer;
  ConnWorld : TMyConnection;
begin



  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='World';
  ConnWorld.Connected := True;

  MyQueryWC := TMyQuery.Create(nil);
  MyQueryWC.Connection := ConnWorld;
  MyQueryWC.SQL.Text :='SELECT guid, name FROM world.countries order by guid';
  MyQueryWC.Execute;


  ini:= TIniFile.Create( directory + 'world.countries.ini');
  ini.WriteInteger('setup','count', MyQueryWC.RecordCount );
  for I := 0 to MyQueryWC.RecordCount -1 do begin
    ini.WriteString('country' + IntToStr(i), 'guid', MyQueryWC.FieldByName ('guid').AsString );
    ini.WriteString('country' + IntToStr(i), 'name', MyQueryWC.FieldByName ('name').AsString );
    MyQueryWC.Next;
  end;
  ini.Free;

  MyQueryWC.Free;
  ConnWorld.Connected := false;
  ConnWorld.Free;

end;
procedure TFormServer.PrepareWorldCountries ;
var
  MyQueryWC: TMyQuery;
  i: Integer;
  ConnWorld : TMyConnection;
begin

  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='world';
  ConnWorld.Connected := True;


  TsWorldCountries.Clear;
  TsWorldCountries.StrictDelimiter := True;

  MyQueryWC := TMyQuery.Create(nil);
  MyQueryWC.Connection := ConnWorld;   // world
  MyQueryWC.SQL.Text :='SELECT guid, name FROM world.countries order by guid';
  MyQueryWC.Execute;


  for I := 0 to MyQueryWC.RecordCount -1 do begin
    TsWorldCountries.Add( MyQueryWC.FieldByName ('guid').AsString + '=' + MyQueryWC.FieldByName ('name').AsString );
    MyQueryWC.Next;
  end;

  MyQueryWC.Free;
  ConnWorld.Connected := false;
  ConnWorld.Free;

end;

procedure TFormServer.PrepareWorldTeams( directory, CountryID: string );
var
  ini: TIniFile;
  i: Integer;
  ConnWorld : TMyConnection ;
  MyQueryWT: TMyQuery;
begin

  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='world';
  ConnWorld.Connected := True;


  MyQueryWT := TMyQuery.Create(nil);
  MyQueryWT.Connection := ConnWorld;   // world
  MyQueryWT.SQL.Text:= 'SELECT guid, name FROM world.teams where country = ' + CountryID + ' order by name';
  MyQueryWT.execute;


  ini:= TIniFile.Create( directory + 'world.teams.ini');
  ini.WriteInteger('setup','count', MyQueryWT.RecordCount );
  for I := 0 to MyQueryWT.RecordCount -1 do begin
    ini.WriteString('team' + IntToStr(i), 'guid', MyQueryWT.FieldByName ('guid').AsString );
    ini.WriteString('team' + IntToStr(i), 'name', MyQueryWT.FieldByName ('name').AsString );
    MyQueryWT.Next;
  end;
  ini.Free;

  MyQueryWT.Free;
  ConnWorld.Connected := false;
  ConnWorld.Free;

end;
procedure TFormServer.PrepareNationTeams( CountryID: integer; var TsNationTeam: TStringList  );
var
  i: Integer;
begin
  TsNationTeam.Clear;
  for I := 0 to TsWorldTeams[CountryId].Count -1 do begin
    TsNationTeam.Add( TsWorldTeams[CountryId].Strings [I] );
  end;

end;
procedure TFormServer.PrepareWorldTeams( CountryID: integer );
var
  MyQueryWT: TMyQuery;
  i: Integer;
  ConnWorld : TMyConnection;
begin

  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='world';
  ConnWorld.Connected := True;


  MyQueryWT := TMyQuery.Create(nil);
  MyQueryWT.Connection := ConnWorld;   // world
  MyQueryWT.SQL.Text  := 'SELECT guid, name FROM world.teams where country = ' + IntToStr(CountryID) + ' order by name';
  MyQueryWT.Execute;


  for I := 0 to MyQueryWT.RecordCount -1 do begin
    TsWorldTeams[CountryId].Add( MyQueryWT.FieldByName ('guid').AsString + '=' + MyQueryWT.FieldByName ('name').AsString );
    MyQueryWT.Next;
  end;

  MyQueryWT.Free;
  ConnWorld.Connected := false;
  ConnWorld.Free;

end;
function TFormServer.GetQueueOpponent ( fm : Char; WorldTeam : integer; Rank, NextHA: byte ): TWSocketThrdClient;
var
  i: Integer;
begin
  // WorldTeam esclude automaticamente anche se stessi
  Result := nil;
{  for I := 0 to Queue.Count -1 do begin
    if (Queue[i].WorldTeam <> WorldTeam) and (abs (Queue[i].MarketValueTeam - MarketValueTeam ) <= GAP_QUEUE)
      and ( Queue[i].nextHA <> nextHA ) and not (queue[i].Marked) // non marcato, cioè non già in gioco
    then begin
      result := Queue[i] ;
      Exit;
    end;
  end;      }
  for I := 0 to Queue.Count -1 do begin
    if (Queue[i].WorldTeam <> WorldTeam) and ( (Queue[i].rank = Rank ) or (Queue[i].rank = Rank -1)  or (Queue[i].rank = Rank +1) )
      and ( Queue[i].nextHA <> nextHA ) and (queue[i].ActiveGender = fm )  and not (queue[i].Marked) // non marcato, cioè non già in gioco
    then begin
      result := Queue[i] ;
      Exit;
    end;
  end;

end;
procedure TFormServer.GetGuidTeamOpponentBOT (fm :Char; WorldTeam: integer; Rank, NextHA: byte; var BotGuidTeam: Integer; var BotUserName: string );
var
  qTeams: TMyQuery;
//  MinGap,MaxGap: Integer;
  ConnGame : TMyConnection;
begin
    BotGuidTeam := 0;
    BotUserName := '';
 //   MinGap := MarketValueTeam - GAP_QUEUE;
 //   MaxGap := MarketValueTeam + GAP_QUEUE;
  // WorldTeam esclude automaticamente anche se stessi. Qui cerco sul db un bot

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=fm+ '_game';
  Conngame.Connected := True;


    qTeams := TMyQuery.Create(nil);
    qTeams.Connection := ConnGame;   // game
{    qTeams.SQL.text := 'SELECT guid, username from f_game.teams INNER JOIN realmd.account ON realmd.account.id = f_game.teams.account WHERE (MarketValue between ' +
                                  IntToStr(MinGap) + ' and ' + IntToStr(MaxGap) + ') and (WorldTeam <> ' + IntTostr(WorldTeam) +
                                  ') and (bot <> 0' +
                                  ') and (nextha <> ' + IntToStr(nextha) +
                                  ') order by rand() limit 1';  }
    qTeams.SQL.text := 'SELECT guid, username from '+fm+'_game.teams INNER JOIN realmd.account ON realmd.account.id = '+fm+'_game.teams.account WHERE ' +
                                  '( (rank=' + IntToStr(Rank) + ') or (rank='+IntToStr(Rank-1) + ') or (rank='+IntToStr(Rank+1) + ') ' +
                                  ') and (WorldTeam <> ' + IntTostr(WorldTeam) +
                                  ') and (bot <> 0' +
                                  ') and (nextha <> ' + IntToStr(nextha) +
                                  ') order by rand() limit 1';
    qTeams.Execute;


    if qTeams.RecordCount > 0 then begin
      BotGuidTeam := qTeams.FieldByName('Guid').AsInteger;
      BotUserName := qTeams.FieldByName('username').AsString;
    end;
    qTeams.Free;
    Conngame.Connected := false;
    Conngame.Free;

end;
function TFormServer.GetTCPClient ( CliId: integer): TWSocketClient;
var
  i: Integer;
begin
  Result := nil;
  for I := TcpServer.ClientCount -1 downto 0 do begin
    if TcpServer.Client [i].CliId = CliId then begin
      result := TcpServer.Client [i];
      Exit;
    end;

  end;

end;
function TFormServer.GetTCPClientQueue ( CliId: integer): TWSocketClient;
var
  i: Integer;
begin
  Result := nil;
  for I := queue.Count -1 downto 0 do begin
    if queue [i].CliId = CliId then begin
      result := queue [i];
      Exit;
    end;

  end;

end;
procedure TFormServer.QueueThreadTimer(Sender: TObject);
var
  i: Integer;
  CliOpponentGuidTeam : TWSocketThrdClient;
  ServerOpponent: array [0..1] of TServerOpponent;
  aBrain: TSoccerBrain;
  OpponentBOT: TServerOpponent;
  BrainIDS, aCommaText: string;
  cli :TWSocketClient;
  label vsBots;
begin
  //  Queue.sort(TComparer<TWSocketThrdClient>.Construct(
  //  function (const L, R: TWSocketThrdClient): integer
  //  begin
  //    Result := R.nextHA - L.nextHA ;  // e dowonto sotto
  //  end
  // ));

  for I := Queue.Count -1 downto 0 do begin
    (* lo cerco in queue in utenti reali *)
    

    ServerOpponent[0].bot := False;
    ServerOpponent[1].bot := False;
    if (GetTickCount - Queue[i].TimeStartQueue) > StrToInt(Edit4.Text) then goto vsbots; // se ho superato il tempo massimo in coda in attesa di uno sfidante
    ServerOpponent[0].GuidTeam := 0;
    ServerOpponent[1].GuidTeam := 0;
      // qui potrebbe essersi disconnesso. f o m mi indicano se è vivo
      if not ((Queue[i].ActiveGender = 'f' ) or (Queue[i].ActiveGender = 'm' )) then Continue;
    CliOpponentGuidTeam := GetQueueOpponent ( Queue[i].ActiveGender, Queue[i].WorldTeam , Queue[i].rank, queue[i].nextHA ); // worldteam diversa in opponent, no Bologna vs Bologna
    if CliOpponentGuidTeam <> nil then  begin   // ho trovato un opponent normale
      if queue[i].nextHA = 0 then begin
        ServerOpponent[0].GuidTeam := Queue[i].GuidTeams[ Queue[i].ActiveGenderN];
        ServerOpponent[0].UserName := Queue[i].UserName;
        ServerOpponent[0].CliID := Queue[i].CliId;
        ServerOpponent[1].GuidTeam := CliOpponentGuidTeam.GuidTeams[ Queue[i].ActiveGenderN];
        ServerOpponent[1].UserName := CliOpponentGuidTeam.UserName ;
        ServerOpponent[1].CliID := CliOpponentGuidTeam.CliId;
      end
      else begin
        ServerOpponent[1].GuidTeam := Queue[i].GuidTeams[ Queue[i].ActiveGenderN];
        ServerOpponent[1].UserName := Queue[i].UserName;
        ServerOpponent[1].CliID := Queue[i].CliId;
        ServerOpponent[0].GuidTeam := CliOpponentGuidTeam.GuidTeams[ Queue[i].ActiveGenderN];
        ServerOpponent[0].UserName := CliOpponentGuidTeam.UserName ;
        ServerOpponent[0].CliID := CliOpponentGuidTeam.CliId;
      end;

      ServerOpponent[0].bot := False;
      ServerOpponent[1].bot := False;
    end;
    //else begin // trovo un bot
    (* lo cerco in db utenti bot *)
 //   end;
    if ( ServerOpponent[0].GuidTeam = 0) or ( ServerOpponent[1].GuidTeam = 0) then Continue;

      {$IFDEF BOTS}
vsBots:
      if (GetTickCount - Queue[i].TimeStartQueue) <= StrToInt(Edit4.Text) then Continue;
      // qui potrebbe essersi disconnesso. f o m mi indicano se è vivo
      if not ((Queue[i].ActiveGender = 'f' ) or (Queue[i].ActiveGender = 'm' )) then Continue;
      GetGuidTeamOpponentBOT ( Queue[i].ActiveGender,  Queue[i].WorldTeam , Queue[i].rank, queue[i].nextHA, OpponentBOT.GuidTeam,OpponentBOT.UserName   ); // worldteam diversa in opponent, no Bologna vs Bologna
      if OpponentBOT.GuidTeam <> 0 then  begin   // ho trovato un opponent BOT
        if queue[i].nextHA = 0 then begin
          ServerOpponent[0].GuidTeam := Queue[i].GuidTeams[ Queue[i].ActiveGenderN];
          ServerOpponent[0].UserName := Queue[i].UserName;
          ServerOpponent[0].CliID := Queue[i].CliId;
          ServerOpponent[1].GuidTeam := OpponentBOT.GuidTeam ;
          ServerOpponent[1].UserName := OpponentBOT.UserName ;
          ServerOpponent[1].bot := True;
          ServerOpponent[1].CliId := 0;
        end
        else begin
          ServerOpponent[1].GuidTeam := Queue[i].GuidTeams[ Queue[i].ActiveGenderN];
          ServerOpponent[1].UserName := Queue[i].UserName;
          ServerOpponent[1].CliID := Queue[i].CliId;
          ServerOpponent[0].GuidTeam := OpponentBOT.GuidTeam ;
          ServerOpponent[0].UserName := OpponentBOT.UserName ;
          ServerOpponent[0].bot := True;
          ServerOpponent[0].CliId := 0;
        end;
      end;
      {$ENDIF BOTS}

    // creo e svuoto la dir_data.brainIds  e la relativa ftp
    // qui creo effettivamente il match anche tra bot
    BrainIDS :=  GetBrainIds ( Queue[i].ActiveGender, IntToStr(ServerOpponent[0].GuidTeam ) , IntToStr(ServerOpponent[1].GuidTeam )) ;

    // creo un brain che lavori in una data cartella
    aBrain := TSoccerBrain.create ( Brainids, Queue[i].ActiveGender, 0,0,0,0);
    aBrain.GameMode := pvp;
    // se è un bot preparo la formazione direttamente sul db
    if ServerOpponent[0].bot then begin
      aCommaText := pvpCreateFormationTeam  ( MySqlServerGame, Queue[i].ActiveGender, ServerOpponent[0].GuidTeam);
      if aCommaText  = '' then
        Exit
      else store_formation( Queue[i].ActiveGender , aCommaText );

    end;
    if ServerOpponent[1].bot then begin
      aCommaText := pvpCreateFormationTeam  ( MySqlServerGame, Queue[i].ActiveGender, ServerOpponent[1].GuidTeam);
      if aCommaText  = '' then
        Exit
      else store_formation( Queue[i].ActiveGender , aCommaText );

    end;
    // creo in quella data cartella match.ini
    //LI LEGO PER SEMPRE

    // <--SaveData 000 appen a fatto
      if not ServerOpponent[0].bot  then begin
        aBrain.Score.CliId[0] := ServerOpponent[0].CliID ;   //se non è un bot riceve i messaggi TCP
        Cli :=  GetTCPClient  (  ServerOpponent[0].CliID );
        if Cli <> nil then begin
          Cli.Brain := TObject(aBrain);   // tcpserver[i].brain
          Cli :=  GetTCPClientQueue  (  ServerOpponent[0].CliID );
          Cli.Marked := True; // dopo lo rimuove da queue  . è uno dei 2 serveropponent. devo trovare anche l'altro
          aBrain.dir_log := dir_log  ;
          aBrain.LogUser [0] := Cli.Flags;
        end;
      end;
      if not ServerOpponent[1].bot  then begin
        aBrain.Score.CliId[1] := ServerOpponent[1].CliID ;  ; //se non è un bot riceve i messaggi TCP
        Cli :=  GetTCPClient  (  ServerOpponent[1].CliID );
        if Cli <> nil then begin
          Cli.Brain := TObject(aBrain);   // tcpserver[i].brain
          Cli :=  GetTCPClientQueue  (  ServerOpponent[1].CliID );
          Cli.Marked := True; // dopo lo rimuove da queue  . è uno dei 2 serveropponent. devo trovare anche l'altro
          aBrain.dir_log := dir_log;
          aBrain.LogUser [1] := Cli.Flags;
        end;

      end;

      if CheckBox2.Checked then begin
          aBrain.dir_log := dir_log;
          aBrain.LogUser [0] := 1;
          aBrain.LogUser [1] := 1;
      end;

      WaitForSingleObject(Mutex,INFINITE);
      CreateAndLoadMatch( cli.ActiveGender, aBrain, ServerOpponent[0].GuidTeam , ServerOpponent[1].GuidTeam, ServerOpponent[0].Username,  ServerOpponent[1].Username );
      BrainManager.AddBrain(aBrain );  //
      ReleaseMutex(Mutex);

      //Caption := IntToStr(BrainManager.lstBrain.count);
      if ServerOpponent[0].bot then aBrain.Score.AI[0]:= True;
      if ServerOpponent[1].bot then aBrain.Score.AI[1]:= True;

      brainManager.Input ( aBrain,   '0' ) ; //


  end;
  // altro ciclo totale delle queue e rimuovo dalla coda quelle segnate come partite create

  WaitForSingleObject(Mutex,INFINITE);
  for I := Queue.Count -1 downto 0 do begin
    if Queue[i].Marked then
      Queue.Delete(i);
  end;

  ReleaseMutex(Mutex);

end;
function TFormServer.GetbrainIds (fm :Char;  GuidTeam0, GuidTeam1: string ) : string;
var
  myYear, myMonth, myDay : word;
  myHour, myMin, mySec, myMilli : word;
  brainIds: string;
begin

    DecodeDateTime(Now, myYear, myMonth, myDay,
                   myHour, myMin, mySec, myMilli);
    BrainIDS:= fm +'_'+ IntToStr(myYear)  + Format('%.*d',[2, myMonth]) + Format('%.*d',[2, myDay]) + '_' +
    Format('%.*d',[2, myHour])  + '.' + Format('%.*d',[2, myMin]) + '.' +  Format('%.*d',[2, mySec])+  '_' +
    GuidTeam0  + '.' + GuidTeam1  ;

    Result := brainIds;
end;
procedure TFormServer.CreateMatchBOTvsBOT (  fm : Char; GuidTeam0, GuidTeam1: integer; Username0, UserName1: string );
var
  abrain: TSoccerBrain;
  BrainIDS,aCommaText: string;
begin
    // creo e svuoto la dir_data.brainIds  e la relativa ftp
    // qui creo effettivamente il match anche tra bot
//    GuidTeam0:=65;
//    Username0:='TEST63';
    //    GuidTeam1:=33;
    BrainIDS := getBrainIds ( fm ,IntToStr(GuidTeam0 ) , IntToStr(GuidTeam1 )) ;
    // creo un brain che lavori in una data cartella
    aBrain := TSoccerBrain.create ( Brainids, fm,0 ,0,0,0);
    aBrain.GameMode := pvp;

  //  aBrain.ShotCells := BrainManager.ShotCells; // Assegno le shotCells
  //  abrain.aiField := BrainManager.AIField;

    //  è un bot preparo la formazione direttamente sul db
      aCommaText := pvpCreateFormationTeam  (  MySqlServerGame, fm, GuidTeam0);
      store_formation( fm , aCommaText );
      aCommaText := pvpCreateFormationTeam  ( MySqlServerGame, fm, GuidTeam1);
      store_formation( fm , aCommaText );

      aBrain.dir_log := dir_log  ;
      if CheckBox2.Checked then begin
         // aBrain.dir_log := dir_log;
          aBrain.LogUser [0] := 1;
          aBrain.LogUser [1] := 1;
      end;

      WaitForSingleObject(Mutex,INFINITE);
      CreateAndLoadMatch( fm, aBrain, GuidTeam0 , GuidTeam1, UserName0, UserName1 );
      BrainManager.AddBrain(aBrain );
      ReleaseMutex(Mutex);

      brainManager.Input ( aBrain,   BrainIDS + '000' ) ;
      aBrain.Score.AI[0]:= True;
      aBrain.Score.AI[1]:= True;

end;
procedure TFormServer.CreateAndLoadMatch ( fm:Char;  brain: TSoccerBrain; GuidTeam0, GuidTeam1: integer; Username0, UserName1: string );
var
  TT: Integer;
  i,pcount,nMatchesplayed,nMatchesLeft,aTeam: integer;
  TvCell,TvReserveCell,aPoint: TPoint;
  GuidTeam: array[0..1] of Integer;
  UserName: array[0..1] of string;
  aPlayer: TSoccerPlayer;
  aName, aSurname, Attributes,aIds: string;
  ConnGame : TMyConnection;
  qTeams,qPlayers,MyQueryWT : TMyQuery;
  label MyContinue;
begin

  GuidTeam[0]:= Guidteam0;
  GuidTeam[1]:= Guidteam1;
  UserName[0]:= Username0;
  UserName[1]:= Username1;
  // leggo dal db, scrivo su dir_data

  brain.Gender := fm;
  if brain.Gender ='f' then
    brain.GenderN := 1
  else if brain.Gender ='m' then
    brain.GenderN := 2;

  brain.Minute := 1;

    brain.GameStarted := True;
  brain.FlagEndGame := False;
  brain.ShpBuff :=  false;
  brain.incMove :=  0;
  brain.TeamCorner :=  -1;
  brain.w_CornerSetup := false;
  brain.w_Coa := False;
  brain.w_Cod :=  False;
  brain.w_CornerKick  := False;

  brain.TeamFreeKick := -1;
  brain.w_FreeKickSetup1 := False;
  brain.w_fka1 :=False;
  brain.w_FreeKick1  := False;

  brain.w_FreeKickSetup2 := False;
  brain.w_fka2 := False;
  brain.w_fkd2 := False;
  brain.w_FreeKick2  := False;

  brain.w_FreeKickSetup3 := False;
  brain.w_fka3 :=False;
  brain.w_fkd3 := False;
  brain.w_FreeKick3  := False;

  brain.w_FreeKickSetup4 := False;
  brain.w_fka4 := False;
  brain.w_FreeKick4  := False;

  brain.TeamTurn := 0 ;

  if brain.Ball <> nil then brain.Ball.Free;
  brain.Ball := Tball.create(brain);
  brain.Ball.CellX := 5;
  brain.Ball.CellY := 3;



  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= fm + '_game';
  Conngame.Connected := True;

{  brain.lstSoccerGameOver.Clear;
  brain.lstSoccerReserve.Clear;
  brain.lstSoccerPlayer.Clear;
  brain.lstSoccerPlayerALL.Clear; }

  for I := 0 to 1 do begin


    qTeams := TMyQuery.Create(nil);
    qTeams.Connection := ConnGame;   // game
    qTeams.SQL.text := 'SELECT * from ' +fm+'_game.teams WHERE guid = ' + IntToStr(GuidTeam[i]);
    qTeams.Execute;



    MyQueryWT := TMyQuery.Create(nil);
    MyQueryWT.Connection := ConnGame;   // world
    MyQueryWT.SQL.text := 'SELECT * from world.teams WHERE guid = ' + qTeams.FieldByName('worldteam').AsString ;
    MyQueryWT.Execute;



    brain.Score.UserName [i] := Username [I];
    brain.Score.Team [i] :=  MyQueryWT.fieldbyname ('name').asstring;  // lo prendo da qui se cambio il nome del team es. ac milan in milan
    brain.Score.TeamGuid [i] := qTeams.fieldbyname ('guid').AsInteger  ;
    brain.Score.Country [i] := qTeams.fieldbyname ('country').AsInteger  ;
    brain.Score.Rank [i] := qTeams.fieldbyname ('rank').AsInteger;
    brain.Score.TeamMI [i] := qTeams.fieldbyname ('mi').AsInteger;
    brain.Score.Season [i] := qTeams.fieldbyname ('season').AsInteger;
    brain.Score.SeasonRound [i] := qTeams.fieldbyname ('matchesplayed').AsInteger + 1;
    brain.Score.TeamSubs [i] := 0;

    if i = 0 then
      brain.Score.Uniform [i] :=  qTeams.fieldbyname ('uniformh').asstring
    else
      brain.Score.Uniform [i] :=  qTeams.fieldbyname ('uniforma').asstring;


    brain.Score.Gol [i] := 0;


    MyQueryWT.Free;
    qTeams.Free;
  end;

  pCount:=0;


  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game

  for TT := 0 to 1 do begin


    qPlayers.SQL.text := 'SELECT * from ' +fm+'_game.players WHERE team =' + IntToStr(GuidTeam[TT]) + ' and young=0';

    qPlayers.Execute ;



    for I := 0 to qPlayers.RecordCount -1 do begin
      aSurname := qPlayers.FieldByName('name').AsString ;
      nMatchesplayed := qPlayers.FieldByName('Matches_Played').AsInteger;
      nMatchesLeft := qPlayers.FieldByName('Matches_Left').AsInteger;

      Attributes := qPlayers.FieldByName('speed').Asstring + ',' + qPlayers.FieldByName('defense').Asstring +
            ',' + qPlayers.FieldByName('passing').Asstring + ',' + qPlayers.FieldByName('ballcontrol').Asstring  +
            ',' + qPlayers.FieldByName('shot').Asstring + ',' + qPlayers.FieldByName('heading').Asstring;

      aIds :=   qPlayers.FieldByName('guid').AsString;

      aTeam := TT;

      if qPlayers.FieldByName('disqualified').AsInteger > 0 then goto  // gli squalificati vengono lasciati a casa
        MyContinue;

      // la formationcells determina il role
      aPoint.X := qPlayers.FieldByName('formation_x').AsInteger ;
      aPoint.Y := qPlayers.FieldByName('formation_y').AsInteger ;
      aPlayer:= TSoccerPlayer.Create( aTeam,
                                 GuidTeam[TT] ,
                                 nMatchesplayed,
                                 aIds,
                                 aName,
                                 aSurname,
                                 Attributes,
                                 qPlayers.FieldByName('talentid1').AsInteger,
                                 qPlayers.FieldByName('talentid2').AsInteger );

      aPlayer.Age:= Trunc(  qPlayers.FieldByName('matches_played').AsInteger  div Soccerbrainv3.SEASON_MATCHES) + 18 ;
      aPlayer.TalentId1 := qPlayers.FieldByName('talentid1').AsInteger;
      aPlayer.TalentId2 := qPlayers.FieldByName('talentid2').AsInteger;

      if isReserveSlotFormation( aPoint.X,aPoint.Y  ) then begin
//          TvReserveCell:= brain.ReserveSlotTV [0,aPoint.X,aPoint.Y  ]; // sempre 0 qui, il client lo metterà a 1 (aplayer.team)
          aPlayer.DefaultCells :=  Point(aPoint.X ,aPoint.Y ); //
          aPlayer.CellS := aPlayer.DefaultCells;
      end
      else begin
        TvCell := brain.AiField2TV ( TT,  aPoint.X,aPoint.Y);
        aPlayer.DefaultCells :=  Point(TvCell.X ,TvCell.Y );
        aPlayer.Cells := TvCell;

      end;

//      if isoutSideAI (qPlayers.FieldByName('formation_x').AsInteger ,qPlayers.FieldByName('formation_y').AsInteger ) then begin
//        TvCell.X := qPlayers.FieldByName('formation_x').AsInteger;
//        TvCell.Y := qPlayers.FieldByName('formation_y').AsInteger;
//      end
//      else
//        TvCell := brain.AiField2TV ( TT,  qPlayers.FieldByName('formation_x').AsInteger, qPlayers.FieldByName('formation_y').AsInteger);

      // role
      // posizioni reali, non determinano il ruolo


      aPlayer.Injured:= qPlayers.FieldByName('injured').AsInteger;
      if aPlayer.Injured > 0 then begin
        aPlayer.Speed :=1;
        aPlayer.Defense :=1;
        aPlayer.Passing :=1;
        aPlayer.BallControl :=1;
        aPlayer.Shot :=1;
        aPlayer.Heading :=1;
      end;


      aPlayer.YellowCard := 0;
      //aPlayer.disqualified := qPlayers.FieldByName('disqualified').AsInteger;
      aPlayer.GameOver  := False;

      aPlayer.Stamina := qPlayers.FieldByName('stamina').AsInteger;

        (* variabili di gioco *)
      aPlayer.CanMove  := true;
      aPlayer.CanSkill := true;
      aPlayer.CanDribbling := true;
      aPlayer.PressingDone  := False;
      aPlayer.BonusTackleTurn  := 0;
      aPlayer.BonusLopBallControlTurn  := 0;
      aPlayer.BonusProtectionTurn  := 0;
      aPlayer.UnderPressureTurn := 0;
      aPlayer.BonusSHPturn := 0;
      aPlayer.BonusSHPAREAturn := 0;
      aPlayer.BonusPLMturn := 0;
      aPlayer.isCOF := False;
      aPlayer.isFK1 := False;
      aPlayer.isFK2 := False;
      aPlayer.isFK3 := False;
      aPlayer.isFK4 := False;
      aPlayer.face := qPlayers.FieldByName('face').AsInteger;
      aPlayer.Country := qPlayers.FieldByName('country').AsInteger;

      brain.lstSoccerPlayerALL.Add(aPlayer);
      if isReserveSlot( aPlayer.CellX, aPlayer.CellY ) then
        brain.AddSoccerReserve(aPlayer)    // <--- riempe reserveSlot
      else  brain.AddSoccerPlayer(aPlayer);

MyContinue:
      qPlayers.Next;
    end;
  end;
 { buff casalingo e morale }
  for I := 0 to 3 do begin // buff casalingo ti ASSICURA 3 player con attributi incrementati  +1 sia per f che per m
    aPlayer := brain.GetSoccerPlayerRandom (0,false); // non il gk
    if Buff_or_Debuff_4 ( aPlayer, 1, brain.MAX_STAT) then // potrebbe trovare un player già maximizzato
      aPlayer.BuffHome := 1;
  end;

  // morale  i GK sono esenti dal morale
  for i := brain.lstSoccerPlayer.Count -1 downto 0 do begin
    aPlayer := brain.lstSoccerPlayer[i];
    if aPlayer.TalentId1 <> 1 then begin // non GK
      if aPlayer.Team = 0 then begin // solo Home players
        if aPlayer.Morale = 2 then begin // su di morale   // se morale 2 20% ottenere +1
          if RndGenerate(100) <= 20 then begin
            if Buff_or_Debuff_4 ( aPlayer, 1 , brain.MAX_STAT ) then  // f e m
              aPlayer.BuffMorale := 1;
          end;
        end
        else if aPlayer.Morale = 0 then begin  // giù di morale  // se morale 0 20% ottenere -1
          if RndGenerate(100) <= 20 then begin
            Buff_or_Debuff_4 ( aPlayer, -1, brain.MAX_STAT );  // f e m
              aPlayer.BuffMorale := -1;
          end;
        end;

      end;
    end;
  end;




  qPlayers.Free;
  Conngame.Connected := false;
  Conngame.Free;

  brain.Start;  // <-- teammoveleft, seconds ecc...
  brain.SaveData(brain.incMove  );
  //inc (brain.incMove);


end;
function TFormServer.CreateGameTeam ( fm :char;  cli: TWSocketThrdClient;  WorldTeamGuid: string ): integer;
//  cli.cliid=account: integer;
var
  i: Integer;
  aPlayer: TSoccerPlayer;
  aBasePlayer: TBasePlayer;
  GuidGameTeam,Fitness0,Fitness: Integer;
  UniformA,UniformH,TeamName,Country,Morale: string;
  aStrColor : string;
  ts : TStringList;
  ConnWorld,ConnGame : TMyConnection ;
  qPlayers,qTeams,MyQueryWT: TMyQuery;
  label retry;
begin

  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='World';
  ConnWorld.Connected := True;

  MyQueryWT := TMyQuery.Create(nil);
  MyQueryWT.Connection := ConnWorld;   // world
  MyQueryWT.SQL.Text := 'SELECT guid, country, name, uniformh, uniforma FROM world.teams where guid = ' + WorldTeamGuid;
  MyQueryWT.Execute;


  Result := MyQueryWT.RecordCount ;
  if Result = 0 then begin
    cli.sReason:= 'creategameteam Guid World not found';
    MyQueryWT.Free;
    ConnWorld.Connected := false;
    ConnWorld.Free;
    Exit;
  end;
  UniformA:= MyQueryWT.fieldbyname ('uniforma').asstring;
  UniformH:= MyQueryWT.fieldbyname ('uniformh').asstring;
  TeamName:= MyQueryWT.fieldbyname ('name').asstring;
  Country:= MyQueryWT.fieldbyname ('country').asstring;
  MyQueryWT.Free;


  (* CREO IL TEAM *)

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= fm +'_game';
  Conngame.Connected := True;



    qTeams := TMyQuery.Create(nil);
    qTeams.Connection := ConnGame;   // game
    qTeams.SQL.Text := 'SELECT guid,country,uniforma,uniformh from ' + fm + '_game.teams WHERE account = ' + IntToStr(cli.cliid);// account
    qTeams.Execute;


    if qTeams.RecordCount > 0 then begin
      cli.sReason:= 'creategameteam team exist';
      Result := 0;
      qTeams.Free;
      ConnWorld.Connected := false;
      ConnWorld.Free;
      Conngame.Connected := false;
      Conngame.Free;
      Exit;
    end;
  // genero colori uniformi casuali Home e Away,schema e colori

  ts := TStringList.Create;
    ts.Add('0');
    ts.Add('0');
    ts.Add('0');
    ts.Add('0');

  if RndGenerate(100) <= 50 then begin //1 o 2 colori
    aStrColor :=  IntToStr( rndGenerate0 ( 12 ) ); // 13 sono i colori
    ts[0] := aStrColor;
    ts[1] := aStrColor;
    ts[2] := aStrColor;
  end
  else begin
    aStrColor :=  IntToStr( rndGenerate0 ( 12 ) ); // 13 sono i colori
    ts[0] := aStrColor;
    aStrColor :=  IntToStr( rndGenerate0 ( 12 ) ); // 13 sono i colori
    ts[1] := aStrColor;
    ts[2] := aStrColor;

  end;
  ts[3]  := IntTostr (RndGenerate0(schemas-1));
  Uniformh := ts.CommaText;

  if RndGenerate(100) <= 50 then begin //1 o 2 colori
    aStrColor :=  IntToStr( rndGenerate0 ( 12 ) ); // 12 sono i colori
    ts[0] := aStrColor;
    ts[1] := aStrColor;
    ts[2] := aStrColor;
  end
  else begin
    aStrColor :=  IntToStr( rndGenerate0 ( 12 ) ); // 12 sono i colori
    ts[0] := aStrColor;
    aStrColor :=  IntToStr( rndGenerate0 ( 12 ) ); // 12 sono i colori
    ts[1] := aStrColor;
    ts[2] := aStrColor;

  end;
  ts[3]  := IntTostr (RndGenerate0(schemas-1));
  UniformA := ts.CommaText;

  ts.Free;

    qTeams.SQL.clear;
    qTeams.SQL.text := 'INSERT into ' + fm +'_game.teams (account,country,WorldTeam,teamname, nextha,uniformh,uniforma)'+
                                                    ' VALUES ('+ IntToStr(cli.cliid) + ',' + Country +',' + WorldTeamGuid + ',"' + TeamName +
                                                     '",0,"' + Uniformh +'","'+ Uniforma + '")';
  qTeams.Execute;
  // li riprendo su e setto Home Away


  qTeams.SQL.Text := 'SELECT guid from ' + fm +'_game.teams where account = ' + IntToStr(cli.cliid);
  qTeams.Execute;


  if qTeams.RecordCount = 1 then
    GuidGameTeam := qTeams.FieldByName('guid').asInteger;


  Result := GuidGameTeam;
  if (GuidGameTeam = 0)   then begin
    cli.sReason:= 'creategameteam failed db';
    qTeams.Free;
    ConnWorld.Connected := false;
    ConnWorld.Free;
    Conngame.Connected := false;
    Conngame.Free;
    Exit;
  end;
  // update iniziale HOME AWAY pari dispari
  qTeams.SQL.Clear;
    if Odd(GuidGameTeam) then qTeams.SQL.text:= 'UPDATE ' + fm +'_game.teams set bot=1, nextha = 1 WHERE guid =' + IntToStr(GuidGameTeam)
      else qTeams.SQL.text:= 'UPDATE ' + fm +'_game.teams set bot=1, nextha = 0 WHERE guid =' + IntToStr(GuidGameTeam);
      qTeams.Execute ;
//    qTeams.free ;

  (* CREO I PLAYER *)


  // genero i player con surnames e stat , matchesplayed stabiliscono l'età. l'età stabilisce injured e growth


  qPlayers := TMyQuery.Create(nil);

  qPlayers.Connection := ConnGame;   // game
    Fitness0 := 0;
    for I := 0 to PlayerCountStart-1 do begin // 15 player all'inizio

      // guid adesso non importa. MatchesPlayed è random secondo un template
      // 1 31 anni
      // 1 30  anni
      // 1 29
      // 1 28
      // 2 27        mp_template
      // 2 26
      // 1 25
      // 2 24
      // 1 23
      // 1 22
      // 1 21

      aBasePlayer := CreatePresetPlayer ( fm, StrToInt( Country ), i ); // i talenti all'inizio del gioc non sono random

      Fitness := Rndgenerate0(2);   // massimo 4 player con fitness 0 alla partenza
      if Fitness = 0 then
        Fitness0 := Fitness0 + 1;
      if Fitness0 > 4 then
        Fitness := rndgeneraterange (1,2);

      morale := '1'; // morale medio

      // li salvo nel DB e ottengono un guid ids. La successiva lettura contenie ids (f_game.players.guid)
      qPlayers.SQL.text := 'INSERT into ' + fm  + '_game.players (Team,Name,Matches_Played,Matches_Left,'+
                                    'deva,devt,devi,xpdeva,xpdevt,xpdevi,'+
                                    'talentid1, speed,defense,passing,ballcontrol,heading,shot,injured,totyellowcard,disqualified,face,country,fitness,morale)'+
                                    ' VALUES ('+
                                    IntToStr(GuidGameTeam) +',"'+ aBasePlayer.Surname +'",'+ IntToStr(aBasePlayer.MatchesPlayed)+','+ IntToStr(aBasePlayer.MatchesLeft)+','+
                                    IntToStr(aBasePlayer.deva)+','+IntToStr(aBasePlayer.devt)+','+IntToStr(aBasePlayer.devi)+','+
                                    IntToStr(aBasePlayer.xpdeva)+','+IntToStr(aBasePlayer.xpdevt)+','+IntToStr(aBasePlayer.xpdevi)+','+
                                    IntToStr(aBasePlayer.TalentId1) + ',' + aBasePlayer.Attributes +','+
                                    '0,0,0,' + IntToStr(aBasePlayer.Face) +','+ country +','+IntTostr(fitness)+','+morale //injured,totyellowcard,disqualified
                                    +')';

      qPlayers.Execute;
    end;

  qPlayers.Free;

//  MarketValue := GetMarketValueTeam ( GuidGameTeam );

  ConnWorld.Connected := false;
  ConnWorld.Free;
  Conngame.Connected := false;
  Conngame.Free;


  Reset_formation  (fm,  GuidGameTeam );



end;
Function TFormServer.CreateSurname ( fm : Char; Country:integer ) : String;
var
  ConnWorld : TMyConnection ;
  MyQuerySU: TMyQuery;
  tmp: string;
begin

  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='World';
  ConnWorld.Connected := True;

  MyQuerySU := TMyQuery.Create(nil);
  MyQuerySU.Connection := ConnWorld;   // world
  MyQuerySU.SQL.Text :=' SELECT name FROM  world.surnames WHERE country = ' + IntToStr(country) + ' order by rand() limit 1';
  MyQuerySU.Execute;



  if (Country =6) and (fm ='f') then begin // solo russia cognomi femminili / maschili
    tmp := MyQuerySU.FieldByName('name').AsString;
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
  else Result :=  MyQuerySU.FieldByName('name').AsString;


  MyQuerySU.Free;
  ConnWorld.Connected := false;
  ConnWorld.Free;

end;
Function TFormServer.CreatePresetPlayer ( fm :Char; Country, index:integer ) : TBasePlayer;
var
  ts: TStringList;
begin
  Result.Surname :=  CreateSurname ( fm , Country );
  if fm ='f' then
    Result.face := rndGenerate ( ffaces[country])
  else  Result.face := rndGenerate ( mfaces[country]);

  Ts := TStringList.Create ;

  if fm = 'f' then
    Result.Attributes :=  PresetF[index]
  else Result.Attributes :=  PresetM[index];

  Ts.CommaText := Result.Attributes;

  Result.DefaultSpeed := StrToInt( ts[0] );
  Result.DefaultDefense := StrToInt( ts[1] );
  Result.DefaultPassing := StrToInt( ts[2] );
  Result.DefaultBallControl := StrToInt( ts[3] );
  Result.DefaultShot := StrToInt( ts[4] );
  Result.DefaultHeading := StrToInt( ts[5] );

  Result.MatchesPlayed := SEASON_MATCHES * mp_template[index];     // 13  ; // 31 anni
  Result.MatchesLeft := (SEASON_MATCHES*15) - Result.MatchesPlayed;

  if fm = 'f' then
    Result.TalentId1 :=  PresetFT[index]
  else Result.TalentId1 :=  PresetMT[index];


  Result.deva := 5;
  Result.devt := 5;
  Result.devi := 1;

  Result.xpdeva := 0;
  Result.xpdevt := 0;
  Result.xpdevi := 0;

end;
Function TFormServer.CreateRandomPlayer ( fm :Char; Country : integer;  EnableTalent2: boolean ) : TBasePlayer;
var
  ts: TStringList;
  Speed2, stat, i : Integer;
  BaseStat: string;
  label retryf,retrym;
begin
  // usata per creare un giovane . usa devt chance per i tlaneti
  Result.Surname :=  CreateSurname ( fm, Country );
  if fm ='f' then
    Result.face := rndGenerate ( ffaces[country])
  else  Result.face := rndGenerate ( mfaces[country]);

  Ts := TStringList.Create ;

  Speed2 := rndGenerate ( 100  ); // 50% giocatori speed 2, 5% speed 4
  if Speed2 <= 50 then
    Ts.commatext := '2,1,1,1,1,1'        // 50% speed 2 che diventa al massimo 3
  else if Speed2 >= 95 then
    Ts.commatext := '4,1,1,1,1,1'        // 10% speed 4
  else  Ts.commatext := '1,1,1,1,1,1';   // 40% speed 1 che diventa al massimo 2

  BaseStat := Ts.commatext;

  if fm = 'f' then begin
retryf:
    // distribuisco 3 punti nella versione f , in m qui ne distribuisco 7
    Ts.commatext := BaseStat;
    for I := 0 to 2 do begin
      stat := rndGenerate0 ( 5  );
      ts [ stat ] := IntToStr( StrToInt(ts [ stat ]) + 1) ; // quale stat  1
    end;

    if  StrToInt( ts [ 0 ]) > 4 then //speed è più di 4
      goto retryf;

    Result.Attributes := ts.CommaText;

    Result.DefaultSpeed := StrToInt( ts[0] );
    Result.DefaultDefense := StrToInt( ts[1] );
    Result.DefaultPassing := StrToInt( ts[2] );
    Result.DefaultBallControl := StrToInt( ts[3] );
    Result.DefaultShot := StrToInt( ts[4] );
    Result.DefaultHeading := StrToInt( ts[5] );
//    ts.Free;

    Result.deva := 5;
    Result.devt := 5;
    Result.devi := 1;

    Result.xpdeva := 0;
    Result.xpdevt := 0;
    Result.xpdevi := 0;


    Result.TalentId1 := 0;
    Result.TalentId2 := 0;

    if RndGenerate(100) <= Result.devt then begin    // se talentChance > 0
      Result.TalentId1 := rndgenerate(NUM_TALENT);    // creo un talento
      if Result.TalentId1 = TALENT_ID_GOALKEEPER then begin
        Result.DefaultShot := 1; // al minimo per non impacciare defense
        ts.CommaText :=  Result.Attributes;
        ts[4] := '1';
        Result.Attributes := ts.CommaText;
      end;
        if EnableTalent2 then begin
          if RndGenerate(100) <= Result.devt then        // creo il secondo talento
            Result.TalentId2 := CreateTalentLevel2 ( fm,Result );
        end;
    end;
    ts.Free;
  end
  else if fm = 'm' then begin
retrym:
    Ts.commatext := BaseStat;
    for I := 0 to 7 do begin
      stat := rndGenerate0 ( 5  );
      ts [ stat ] := IntToStr( StrToInt(ts [ stat ]) + 1) ; // quale stat  1
    end;
    if  StrToInt( ts [ 0 ]) > 4 then //speed è più di 4
      goto retrym;

    // solo nella versione maschile aggiungo molti punti stat all'inizio, per questo devo chackare difesa/attacco.
    if (StrToInt (ts [1]) >= 4) and (StrToInt (ts [4]) >= 4) then   // 4 e non 5, la metà
    goto retrym;

    Result.Attributes := ts.CommaText;

    Result.DefaultSpeed := StrToInt( ts[0] );
    Result.DefaultDefense := StrToInt( ts[1] );
    Result.DefaultPassing := StrToInt( ts[2] );
    Result.DefaultBallControl := StrToInt( ts[3] );
    Result.DefaultShot := StrToInt( ts[4] );
    Result.DefaultHeading := StrToInt( ts[5] );
    //ts.Free;

    Result.deva := 5;
    Result.devt := 5;
    Result.devi := 1;

    Result.xpdeva := 0;
    Result.xpdevt := 0;
    Result.xpdevi := 0;

    Result.TalentId1 := 0;
    Result.TalentId2 := 0;

    if RndGenerate(100) <= Result.devt then begin    // se talentChance > 0
      Result.TalentId1 := rndgenerate(NUM_TALENT);    // creo un talento
      if Result.TalentId1 = TALENT_ID_GOALKEEPER then begin
        Result.DefaultShot := 1; // al minimo per non impacciare defense
        ts.CommaText :=  Result.Attributes;
        ts[4] := '1';
        Result.Attributes := ts.CommaText;
      end;
        if EnableTalent2 then begin
          if RndGenerate(100) <= Result.devt then        // creo il secondo talento
            Result.TalentId2 := CreateTalentLevel2 ( fm, Result );
        end;
    end;
    ts.Free;
  end;


end;
procedure TFormServer.validate_getteamsbycountry ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  value: Integer;
begin
  // 0=cmd 1=idcountry

  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if not TryDecimalStrToInt( ts[1], Value) then begin
    cli.sReason:= 'id World.Country not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure TFormServer.validate_clientcreateteam ( const CommaText: string; Cli:TWSocketThrdClient  ) ;
var
  ts: TStringList;
  value: Integer;
begin
  // 0=cmd 1=idWorldTeam
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if not TryDecimalStrToInt( ts[1], Value) then begin
    cli.sReason:= 'id World.Teams not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure TFormServer.validate_viewMatch ( const CommaText: string; Cli:TWSocketThrdClient  ) ;
//var
//  ts: TStringList;
//  value: Integer;
begin
  // 0=cmd 1=id match
  cli.sReason:='';
 // ts:= TStringList.Create ;
 // ts.CommaText := CommaText;
 // if not TryDecimalStrToInt( ts[1], Value) then begin
 //   cli.sReason:= 'id Match not numeric';
 //   ts.Free;
 //   Exit;
 // end;
 // ts.Free;

end;

procedure TFormServer.validate_login ( const CommaText: string; Cli:TWSocketThrdClient );
begin
  // 0=login 1=user 2=password
  cli.sReason:='';

  //check sql injection
  if (Pos ( 'SELECT', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'UPDATE', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'DROP', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'ALTER', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'INSERT', UpperCase(CommaText),1 ) <> 0) then begin
    cli.sReason:= 'SQL injection?';
    Exit;
  end;
end;
function TFormServer.LastIncMoveIni ( directory: string ): string;
var
  sf : SE_SearchFiles;
begin
  sf :=  SE_SearchFiles.Create(nil);

  sf.MaskInclude.add ('*.ini');
  sf.FromPath := directory;
  sf.SubDirectories := False;
  sf.Execute ;

  while Sf.SearchState <> ssIdle do begin
    Application.ProcessMessages ;
  end;

  if sf.ListFiles.Count > 0 then begin
    sf.ListFiles.Sort ;
    result := sf.ListFiles [sf.ListFiles.Count-1 ];
  end;
  sf.Free;

end;
procedure TFormServer.validate_aiteam ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;
begin
  // 0=aiteam 1=team 2=0 o -1
  cli.sReason:='';
  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;


  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  // team
  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'Team not numeric';
    ts.Free;
    Exit;
  end;
  if not TryDecimalStrToInt( ts[2], AValue) then begin
    cli.sReason:= 'AI true/false not numeric';
    ts.Free;
    Exit;
  end;


  ts.Free;

end;
procedure TFormServer.validate_pause ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;
begin
  // 0=pause 1=0 o -1
  cli.sReason:='';
  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;


  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  // true or false
  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'Team not numeric';
    ts.Free;
    Exit;
  end;


  ts.Free;

end;
procedure TFormServer.validate_setplayer ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;
begin
  // 0=setplayer 1=guid/ids 2=cellx 3=celly
  cli.sReason:='';
  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;


  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 4 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  // player, cellx, celly
  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'Player not numeric';
    ts.Free;
    Exit;
  end;
  if not TryDecimalStrToInt( ts[2], AValue) then begin
    cli.sReason:= 'Cellx not numeric';
    ts.Free;
    Exit;
  end;
  if not TryDecimalStrToInt( ts[3], AValue) then begin
    cli.sReason:= 'CellY not numeric';
    ts.Free;
    Exit;
  end;


  ts.Free;

end;

procedure TFormServer.validate_CMD4 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TSoccerPlayer;
  ts: TStringList;
  aValue: Integer;
begin
  // 0=PLM 1=ids 2=cellX 3=CellY
  cli.sReason:='';
  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;
  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    Exit;
  end;

  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 4 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  // Coerenza Ids
  aPlayer := TSoccerBrain(Cli.brain).GetSoccerPlayer  (ts[1])   ;
  if aPlayer = nil then begin
    cli.sReason:= 'Player not found';
    ts.Free;
    Exit;
  end;
  if aPlayer.GuidTeam <> Cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'Player GuidTeam mismatch';
    ts.Free;
    Exit;
  end;

  // cellx e Celly
  if not TryDecimalStrToInt( ts[2], AValue) then begin
    cli.sReason:= 'Cellx not numeric';
    ts.Free;
    Exit;
  end;
  if not TryDecimalStrToInt( ts[3], AValue) then begin
    cli.sReason:= 'CellY not numeric';
    ts.Free;
    Exit;
  end;

  if (StrToInt( ts[2]) < 0) or (StrToInt( ts[2]) > 11) or (StrToInt( ts[3]) < 0) or (StrToInt( ts[3]) > 6) then begin
    cli.sReason:= 'CellX or CellY outside field';
    ts.Free;
    Exit;
  end;

  ts.Free;

end;
Procedure TFormServer.validate_CMD3 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;

begin
//    else if (ts[1] ='CRO') or (ts[1] ='SHP') or (ts[1] ='LOP') or (ts[1] ='DRI') then begin
  // 0=CRO 1=cellX 2=CellY
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if ts[0] <> 'setball' then begin

    if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
      cli.sReason:= 'Turn/CliId mismatch';
      ts.Free;
      Exit;
    end;

    // coerenza guidTeam e teamTurn
    if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
      cli.sReason:= 'GuidTeam Turn mismatch';
      ts.Free;
      Exit;
    end;
  end;
  // cellx e Celly
  if not TryDecimalStrToInt( ts[1],aValue) then begin
    cli.sReason:= 'CellX not numeric';
    ts.Free;
    Exit;
  end;
  if not TryDecimalStrToInt( ts[2], aValue) then begin
    cli.sReason:= 'CellY not numeric';
    ts.Free;
    Exit;
  end;

  if (StrToInt( ts[1]) < 0) or (StrToInt( ts[1]) > 11) or (StrToInt( ts[2]) < 0) or (StrToInt( ts[2]) > 6) then begin
    cli.sReason:= 'CellX or CellY outside field';
    ts.Free;
    Exit;
  end;
  ts.Free;
end;
Procedure TFormServer.validate_CMDlop ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;

begin
  // 0=LOP 1=cellX 2=CellY 3=N or GKLOP
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 4 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    ts.Free;
    Exit;
  end;

  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
    ts.Free;
    Exit;
  end;

  // cellx e Celly
  if not TryDecimalStrToInt( ts[1],aValue) then begin
    cli.sReason:= 'CellX not numeric';
    ts.Free;
    Exit;
  end;
  if not TryDecimalStrToInt( ts[2], aValue) then begin
    cli.sReason:= 'CellY not numeric';
    ts.Free;
    Exit;
  end;

  if (StrToInt( ts[1]) < 0) or (StrToInt( ts[1]) > 11) or (StrToInt( ts[2]) < 0) or (StrToInt( ts[2]) > 6) then begin
    cli.sReason:= 'CellX or CellY outside field';
    ts.Free;
    Exit;
  end;
  ts.Free;
end;
procedure TFormServer.validate_CMD1 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
begin
//    else if (ts[1] ='PRS') or (ts[1] ='POS') or (ts[1] ='PRO')  then begin
//    else if (ts[1] ='PASS') or (ts[1] ='COR')  then begin  // sul brain iscof batterà il corner
// PRE TAC
  // 0=PRS
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 1 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    ts.Free;
    Exit;
  end;
  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
    ts.Free;
    Exit;
  end;

    ts.Free;

end;
procedure TFormServer.validate_debug_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: integer;
begin
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1],aValue) then begin
    cli.sReason:= CommaText + ' not numeric';
    ts.Free;
    Exit;
  end;

  ts.Free;

end;
procedure TFormServer.validate_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
begin
//    else if (ts[1] ='TAC') or (ts[1] ='PRE  then begin
  // 0=PRE o TAC  1=ids
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    ts.Free;
    Exit;
  end;

  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
    ts.Free;
    Exit;
  end;

    ts.Free;

end;

procedure TFormServer.validate_CMD_coa ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TSoccerPlayer;
  ts: TStringList;
  i: Integer;
begin
  // 0=CORNER_ATTACK.SETUP 1=cop 2=coa 3=coa 4=coa
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 5 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    ts.Free;
    Exit;
  end;
  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
    ts.Free;
    Exit;
  end;

  // Coerenza Ids
  for I := 1 to 4 do begin
    aPlayer := TSoccerBrain(Cli.brain).GetSoccerPlayer(ts[i]);
    if aPlayer = nil then begin
      cli.sReason:= 'Player not found';
      ts.Free;
      Exit;
    end;
    if aPlayer.GuidTeam <> Cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN]  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

    ts.Free;

end;
procedure TFormServer.validate_CMD_cod ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TSoccerPlayer;
  ts: TStringList;
  i: Integer;
begin
  // 0='CORNER_DEFENSE.SETUP 1=cod 2=cod 3=cod
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 4 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    ts.Free;
    Exit;
  end;
  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
    Exit;
  end;

  // Coerenza Ids
  for I := 1 to 3 do begin
    aPlayer := TSoccerBrain(Cli.brain).GetSoccerPlayer(ts[i]);
    if aPlayer = nil then begin
      cli.sReason:= 'Player not found';
      ts.Free;
      Exit;
    end;
    if aPlayer.GuidTeam <> Cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN]  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

    ts.Free;

end;
procedure TFormServer.validate_CMD_bar ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TSoccerPlayer;
  ts: TStringList;
  i: Integer;
begin
  // 0='CORNER_DEFENSE.SETUP 1=cod 2=cod 3=cod
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 5 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    ts.Free;
    Exit;
  end;
  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
    Exit;
  end;

  // Coerenza Ids
  for I := 1 to 4 do begin
    aPlayer := TSoccerBrain(Cli.brain).GetSoccerPlayer(ts[i]);
    if aPlayer = nil then begin
      cli.sReason:= 'Player not found';
      ts.Free;
      Exit;
    end;
    if aPlayer.GuidTeam <> Cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN]  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

    ts.Free;

end;
procedure TFormServer.validate_CMD_subs ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TSoccerPlayer;
  ts: TStringList;
  i: Integer;
begin
  // 0='SUBS 1=ids 2=ids
  cli.sReason:='';

  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    ts.Free;
    Exit;
  end;
  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
    Exit;
  end;

  // Coerenza Ids
  for I := 1 to 2 do begin
    aPlayer := TSoccerBrain(Cli.brain).GetSoccerPlayer2(ts[i]);
    if aPlayer = nil then begin
      cli.sReason:= 'Player not found';
      ts.Free;
      Exit;
    end;
    if aPlayer.GuidTeam <> Cli.GuidTeams[TSoccerBrain(Cli.brain).GenderN]  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

    ts.Free;

end;
procedure TFormServer.validate_levelupAttribute ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;
begin
  // 0=levelup 1=Guid 2=attr
  cli.sReason:='';
  //check sql injection
  if (Pos ( 'SELECT', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'UPDATE', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'DROP', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'ALTER', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'INSERT', UpperCase(CommaText),1 ) <> 0) then begin
    cli.sReason:= 'SQL injection?';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1], aValue) then begin
    cli.sReason:= 'guid Player not numeric';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[2], aValue) then begin
    cli.sReason:= 'Attribute not numeric';
    ts.Free;
    Exit;
  end;

  if (aValue < 0)  or (aValue > 5)  then begin //
    cli.sReason:= 'Attribute: ' + intTostr(aValue) +'. Expected 0..5';
    ts.Free;
    Exit;
  end;


  ts.Free;

end;
procedure TFormServer.validate_levelupTalent ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;
begin
  // 0=levelup 1=Guid 2=talentID
  cli.sReason:='';
  //check sql injection
  if (Pos ( 'SELECT', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'UPDATE', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'DROP', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'ALTER', UpperCase(CommaText),1 ) <> 0) or
  (Pos ( 'INSERT', UpperCase(CommaText),1 ) <> 0) then begin
    cli.sReason:= 'SQL injection?';
    Exit;
  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1], aValue) then begin
    cli.sReason:= 'guid Player not numeric';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[2], aValue) then begin
    cli.sReason:= 'TalentId not numeric';
    ts.Free;
    Exit;
  end;

  if (aValue < 1)  or (aValue > NUM_TALENT)  then begin // nota: può essere 0 cioè speed
    cli.sReason:= 'TalentId: ' + intTostr(aValue) +'. Expected 1..' + IntTostr(NUM_TALENT);
    ts.Free;
    Exit;
  end;


  ts.Free;

end;

procedure TFormServer.MarketBuy ( Cli: TWSocketThrdClient; CommaText: string  );
var
  i : Integer;
  price,MoneyA,MoneyB,GuidTeamSell: Integer;
  ts: TStringList;
  ReserveSlot : TTheArray;
  aReserveSlot: Integer;
  ConnGame : TMyConnection;
  qPlayers,qMarket,qTeams,qTransfers: TMyQuery;
begin
  WaitforSingleObject ( MutexMarket, INFINITE ); // devo bloccare il finalizeGame
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  // check e spostamento denaro

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= Cli.ActiveGender + '_game';
  Conngame.Connected := True;


  qTeams := TMyQuery.Create(nil);
  qTeams.Connection := ConnGame;   // game
  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qMarket := TMyQuery.Create(nil);
  qMarket.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'SELECT count(guid) FROM '+Cli.ActiveGender+'_game.players where team=' + IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ' and young=0';
  qPlayers.Execute ;

  if qPlayers.RecordCount >= 22 then  begin
    Cli.sreason := 'marketbuy linit 22 player';
    qTeams.Free;
    qPlayers.Free;
    qMarket.Free;
    Conngame.Connected := False;
    Conngame.Free;
    ts.Free;
    ReleaseMutex ( MutexMarket );
    Exit;

  end;



  qTeams.SQL.text := 'SELECT money FROM '+Cli.ActiveGender+'_game.teams where guid=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN] );
  qTeams.Execute ;
                                                                                                             // non i suoi
  qMarket.SQL.text := 'SELECT sellprice,guidteam FROM '+Cli.ActiveGender+'_game.market where guidplayer=' + ts[1] + ' and guidteam <> ' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]);
  qMarket.Execute ;

  if qMarket.RecordCount = 0 then begin
    Cli.sreason := 'marketbuy_player_not_found';
    qTeams.Free;
    qPlayers.Free;
    qMarket.Free;
    Conngame.Connected := False;
    Conngame.Free;
    ts.Free;
    ReleaseMutex ( MutexMarket );
    Exit;

  end;

  GuidTeamSell:=  qMarket.FieldByName('guidteam').AsInteger;
  MoneyA := qTeams.FieldByName('money').AsInteger;
  price :=  qMarket.FieldByName('sellprice').AsInteger;

  if MoneyA < price then begin
    Cli.sreason := 'marketbuy no funds!';
    qTeams.Free;
    qPlayers.Free;
    qMarket.Free;
    Conngame.Connected := False;
    Conngame.Free;
    ts.Free;
    ReleaseMutex ( MutexMarket );
    Exit;

  end;

  // qui lo può comprare
  MoneyA := MoneyA - price;
  qTeams.SQL.text := 'UPDATE '+Cli.ActiveGender+'_game.teams set money=' + IntToStr(MoneyA) + ' WHERE guid =' + IntToStr(cli.GuidTeams [Cli.ActiveGenderN]);
  qTeams.Execute ;

  qTeams.SQL.text := 'SELECT money FROM '+Cli.ActiveGender+'_game.teams where guid=' +  IntToStr (GuidTeamSell);
  qTeams.Execute ;


  if qMarket.RecordCount = 0 then begin
    Cli.sreason := 'marketbuy no vendor team';
    qTeams.Free;
    qPlayers.Free;
    qMarket.Free;
    Conngame.Connected := False;
    Conngame.Free;
    ts.Free;
    ReleaseMutex ( MutexMarket );
    Exit;

  end;


  MoneyB := qTeams.FieldByName('money').AsInteger; // chi vende
  MoneyB := MoneyB + price;

  qTeams.SQL.text := 'UPDATE '+Cli.ActiveGender+'_game.teams set money=' + IntToStr(MoneyB) + ' WHERE guid =' + IntToStr (GuidTeamSell);
  qTeams.Execute ;


  // f_game.players mettere onmarket=0
  // update f_game.players onmarket e delete market con tutti i dati attuali e congelati qui

  qMarket.SQL.text := 'DELETE FROM '+Cli.ActiveGender+'_game.market where guidplayer=' + ts[1];
  qMarket.Execute ;

  qTransfers := TMyQuery.Create(nil);
  qTransfers.Connection := ConnGame;   // game
  qTransfers.SQL.text := 'INSERT INTO '+Cli.ActiveGender+'_game.transfers SET action="t", ' +  'seller=' +  IntToStr(GuidTeamSell) +
                                                                    ' , buyer=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]) +
                                                                    ' , playerguid=' + ts[1] + ' , price=' + IntToStr(price);
  qTransfers.Execute;
  { testare anche qui, per il SELLER, fare tryaddyoung. non mi devo preoccupare per il gk }
  Tryaddyoung ( Cli.ActiveGender, GuidTeamSell);

  // ottengo il prossimo slot delle riserve  e riordino tutti
  CleanReserveSlot ( ReserveSlot );

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'SELECT guid,formation_x,formation_y from '+Cli.ActiveGender+'_game.players WHERE  team=' +
                        IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]) + ' and young=0';
  qPlayers.Execute ;

  for i := qPlayers.RecordCount -1 downto 0 do begin

    if isReserveSlot ( qPlayers.FieldByName('formation_x').AsInteger, qPlayers.FieldByName('formation_y').AsInteger) then
    ReserveSlot[qPlayers.FieldByName('formation_x').AsInteger]:= qPlayers.FieldByName('guid').AsString;

  end;
  aReserveSlot := NextReserveSlot ( ReserveSlot ); //<--- la prossima libera



  qPlayers.SQL.text := 'UPDATE '+Cli.ActiveGender+'_game.players set onmarket=0,team='+IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]) +  // cambio team
                              ',formation_x=' + IntToStr(aReserveSlot) +',formation_y=-1 WHERE guid =' + ts[1];

  qPlayers.Execute ;

  qTeams.Free;
  qPlayers.Free;
  qMarket.Free;
  qTransfers.Free;
  Conngame.Connected := False;
  Conngame.Free;

  ts.Free;
  ReleaseMutex ( MutexMarket );


end;
procedure TFormServer.MarketSell ( Cli: TWSocketThrdClient; CommaText: string ); // mette un player sul mercato
var
  mValue : Integer;
  price: Integer;
  ts: TStringList;
  ConnGame : TMyConnection ;
  qPlayers,qMarket,qPlayersGK: TMyQuery ;
begin
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  price := StrToInt ( ts[2] );

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= Cli.ActiveGender+'_game';
  Conngame.Connected := True;


  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'SELECT country,fitness,morale,guid,team,name,matches_played,matches_left,speed,defense,passing,ballcontrol,shot,heading,talentid1,talentid2,history,xp,onmarket,face' +
                                ' from '+Cli.ActiveGender+'_game.players WHERE onmarket=0 and guid =' + ts[1] + ' and team=' +
                                IntToStr(Cli.GuidTeams [Cli.ActiveGenderN])+ ' and young=0'; // per essere sicuri anche cli.guidteam
  qPlayers.Execute ;


  if qPlayers.RecordCount = 0 then begin
    Cli.sreason := 'marketsell player not found';
    qPlayers.Free;
    ts.Free;
    Conngame.Connected := False;
    Conngame.Free;
    Exit;
  end;
  // check value < minimo. non si può vendere un player a basso costo
  if qPlayers.FieldByName('talentid1').AsInteger <> TALENT_ID_GOALKEEPER then  // non un goalkeeper (portiere) o senza talento o con talento

  mValue :=  Trunc ( qPlayers.FieldByName('speed').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('speed').AsInteger] +
             qPlayers.FieldByName('defense').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('defense').AsInteger] +
             qPlayers.FieldByName('passing').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('passing').AsInteger] +
             qPlayers.FieldByName('ballcontrol').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('ballcontrol').AsInteger] +
             qPlayers.FieldByName('shot').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('shot').AsInteger] +
             qPlayers.FieldByName('heading').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('heading').AsInteger])

  else if qPlayers.FieldByName('talentid1').AsInteger = TALENT_ID_GOALKEEPER then begin  // un portiere

  mValue :=  Trunc ((qPlayers.FieldByName('defense').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('defense').AsInteger] * MARKET_VALUE_ATTRIBUTE_DEFENSE_GK) +
             qPlayers.FieldByName('passing').AsInteger *   MARKET_VALUE_ATTRIBUTE [qPlayers.FieldByName('passing').AsInteger]  );


    // è un goalkeeper, se è l'unico non posso venderlo . se ce nes sono di più, ce ne deve essere almeno 1 non sul mercato
    qPlayersGK := TMyQuery.Create(nil);
    qPlayersGK.Connection := ConnGame;   // game
    qPlayersGK.SQL.text := 'SELECT country,fitness,morale,guid,talentid1,talentid2 from '+Cli.ActiveGender+'_game.players WHERE talentid1=1 and guid <>' + ts[1] +
                                       ' and onmarket=0 and team=' + IntToStr(Cli.GuidTeams[Cli.ActiveGenderN]) + ' and young=0';
    qPlayersGK.Execute ;

    if qPlayersGK.RecordCount = 0 then begin
      Cli.sreason := 'marketsell only 1 goalkeeper';
      qPlayers.Free;
      qPlayersGK.Free;
      ts.Free;
      Conngame.Connected := False;
      Conngame.Free;
      Exit;
    end;
    qPlayersGK.Free;
  end;

  if qPlayers.FieldByName('talentid1').AsInteger  <> 0 then mValue := Trunc (mValue  *  MARKET_VALUE_TALENT1) ; //se c'è un talento, anche goalkeeper
  if qPlayers.FieldByName('talentid2').AsInteger  <> 0 then mValue := mValue + Trunc (mValue  *  MARKET_VALUE_TALENT2) ;


  if price < mValue then begin
    Cli.sreason := 'marketsell price low';
    qPlayers.Free;
    ts.Free;
    Conngame.Connected := False;
    Conngame.Free;
    Exit;
  end;

  // non deve essere presente sul mercato

  qMarket := TMyQuery.Create(nil);
  qMarket.Connection := ConnGame;   // game
  qMarket.SQL.text := 'SELECT guid from '+Cli.ActiveGender+'_game.market WHERE guid =' + ts[1];
  qMarket.Execute ;

  if qMarket.RecordCount > 0 then begin
    Cli.sreason := 'marketsell player already on market';
    qPlayers.Free;
    qMarket.Free;
    ts.Free;
    Conngame.Connected := False;
    Conngame.Free;
    Exit;
  end;

  // sul mercato massimo 3 player

  qMarket.SQL.text := 'SELECT guid from '+Cli.ActiveGender+'_game.market WHERE guidteam =' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]);
  qMarket.Execute ;

  if qMarket.RecordCount >= 3 then begin
    Cli.sreason := 'marketsell max 3 player';
    qPlayers.Free;
    qMarket.Free;
    ts.Free;
    Conngame.Connected := False;
    Conngame.Free;
    Exit;
  end;
  // update f_game.players onmarket e market con tutti i dati attuali e congelati qui

  qMarket.SQL.text := 'INSERT INTO '+Cli.ActiveGender+'_game.market (speed,defense,passing,ballcontrol,shot,heading,talentid1,talentid2,'+
                            'matches_played,matches_left,name,guidteam,guidplayer,face,sellprice,history,xp,country,fitness,morale) VALUES ('+
                             qPlayers.FieldByName('speed').AsString +
                            ',' + qPlayers.FieldByName('defense').AsString +
                            ',' + qPlayers.FieldByName('passing').AsString +
                            ',' + qPlayers.FieldByName('ballcontrol').AsString +
                            ',' + qPlayers.FieldByName('shot').AsString +
                            ',' + qPlayers.FieldByName('heading').AsString +
                            ',' + qPlayers.FieldByName('talentid1').AsString +
                            ',' + qPlayers.FieldByName('talentid2').AsString +
                            ',' + qPlayers.FieldByName('matches_played').AsString +
                            ',' + qPlayers.FieldByName('matches_left').AsString +
                            ',"' + qPlayers.FieldByName('name').AsString + '"'+
                            ',' + qPlayers.FieldByName('team').AsString + // guidteam
                            ',' + qPlayers.FieldByName('guid').AsString + // guidplayer
                            ',' + qPlayers.FieldByName('face').AsString + // face
                            ',' + ts[2] + // price
                            ',"' + qPlayers.FieldByName('history').AsString + '"'+
                            ',"' + qPlayers.FieldByName('xp').AsString + '"'+
                            ',' + qPlayers.FieldByName('country').AsString +
                            ',' + qPlayers.FieldByName('fitness').AsString +
                            ',' + qPlayers.FieldByName('morale').AsString
                            + ')';
  qMarket.Execute ;

  qPlayers.SQL.text := 'UPDATE '+Cli.ActiveGender+'_game.players set onmarket=1 WHERE guid =' + ts[1] + ' and team=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]); // per essere sicuri anche cli.guidteam
  qPlayers.Execute ;

  qPlayers.Free;
  qMarket.Free;
  Conngame.Connected := False;
  Conngame.Free;
  ts.Free;

end;
procedure TFormServer.MarketCancelSell ( Cli: TWSocketThrdClient; CommaText: string );
var
  qPlayers,qMarket: TMyQuery;
  ts: TStringList;
  ConnGame : TMyConnection;
begin
  WaitforSingleObject ( MutexMarket, INFINITE ); // devo bloccare il finalizeGame

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;


  //  deve essere presente sul mercato

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= Cli.ActiveGender + '_game';
  Conngame.Connected := True;

  qMarket := TMyQuery.Create(nil);
  qMarket.Connection :=  ConnGame;
  qMarket.SQL.text := 'SELECT guid from '+Cli.ActiveGender+'_game.market WHERE guidplayer =' + ts[1] + ' and guidteam=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]); // per essere sicuri anche cli.guidteam
  qMarket.Execute ;

  if qMarket.RecordCount = 0 then begin
    Cli.sreason := 'marketcancelsell player not on market';
    qMarket.Free;
    ts.Free;
    Conngame.Connected := False;
    Conngame.Free;
    Exit;
  end;

  // update f_game.players onmarket e delete market con tutti i dati attuali e congelati qui
  qMarket.SQL.text := 'DELETE FROM '+Cli.ActiveGender+'_game.market where guidplayer=' + ts[1] + ' and guidteam=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]);
  qMarket.Execute ;


  qPlayers := TMyQuery.Create(nil);


  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'UPDATE '+Cli.ActiveGender+'_game.players set onmarket=0 WHERE guid =' + ts[1] + ' and team=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]); // per essere sicuri anche cli.guidteam
  qPlayers.Execute ;

  qPlayers.Free;
  qMarket.Free;
  Conngame.Connected := False;
  Conngame.Free;
  ts.Free;
  ReleaseMutex ( MutexMarket );

end;
procedure TFormServer.DismissPlayer ( Cli: TWSocketThrdClient; CommaText: string );
var
  qPlayers,qMarket,qTransfers: TMyQuery;
  ts: TStringList;
  ConnGame : TMyConnection;
begin
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;

  //  deve essere presente sul mercato

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=Cli.ActiveGender+ '_game';
  Conngame.Connected := True;

  // se presente sul mercato lo elimino

  qMarket := TMyQuery.Create(nil);
  qMarket.Connection :=  ConnGame;
  qMarket.SQL.text := 'SELECT guid from '+Cli.ActiveGender+'_game.market WHERE guidplayer =' + ts[1] +
                     ' and guidteam=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]); // per essere sicuri anche cli.guidteam
  qMarket.Execute ;

  if qMarket.RecordCount = 1 then begin
    qMarket.SQL.text := 'DELETE FROM '+Cli.ActiveGender+'_game.market where guidplayer=' + ts[1] + ' and guidteam=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]);
    qMarket.Execute ;
  end;

  // team = 0 significa di nessun team , licenziato

  qPlayers := TMyQuery.Create(nil);


  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'UPDATE '+Cli.ActiveGender+'_game.players set team=0 WHERE guid =' + ts[1] + ' and team=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]); // per essere sicuri anche cli.guidteam
  qPlayers.Execute ;


  qTransfers := TMyQuery.Create(nil);
  qTransfers.Connection := ConnGame;   // game
  qTransfers.SQL.text := 'INSERT INTO '+Cli.ActiveGender+'_game.transfers SET action="d", ' +  'seller=' +   IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]) +
                                                                    ' , buyer=' + IntToStr(Cli.GuidTeams [Cli.ActiveGenderN]) +
                                                                    ' , playerguid=' + ts[1] + ' , price=0';
  qTransfers.Execute;

  TryAddYoung ( Cli.ActiveGender,Cli.GuidTeams [Cli.ActiveGenderN]);// devo copiare tutti i dati da young a players, poi devo fare un INSERT e un DELETE



  qTransfers.free;
  qPlayers.Free;
  qMarket.Free;


  Conngame.Connected := False;
  Conngame.Free;
  ts.Free;


end;
function TFormServer.TryAddYoung ( fm :Char; GuidTeam: Integer): Boolean;
var
  ConnGame : TMyConnection;
  qPlayers,qTransfers,qYoungPlayers : TMyQuery;
begin
  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=fm+ '_game';
  Conngame.Connected := True;

  qYoungPlayers := TMyQuery.Create(nil);
  qYoungPlayers.Connection := ConnGame;   // game
  qYoungPlayers.SQL.text := 'SELECT * from '+fm+'_game.players WHERE team =' + IntToStr(GuidTeam) + ' and young <> 0';
  qYoungPlayers.Execute ; // limit 1 , ne prendo uno
  if qYoungPlayers.RecordCount > 0 then begin
    qPlayers := TMyQuery.Create(nil);
    qPlayers.Connection := ConnGame;   // game
    qPlayers.SQL.Text := 'UPDATE ' + fm + '_game.players set young=0 where guid=' + qYoungPlayers.FieldByName('guid').AsString;
    qPlayers.Execute;
    qPlayers.Free;
    // Questo è il LOG

    qTransfers := TMyQuery.Create(nil);
    qTransfers.Connection := ConnGame;   // game
    qTransfers.SQL.text := 'INSERT INTO '+fm +'_game.transfers SET action="a", seller=' +  IntToStr(GuidTeam) +
                                                                 ' , buyer=' + IntToStr(GuidTeam) +
                                                                 ' , playerguid=' +qYoungPlayers.FieldByName('guid').AsString + ' , price=0';
    qTransfers.Execute;

  end;

  qYoungPlayers.Free;

end;
function TFormServer.CalculateRank ( mi : integer): Integer;
begin
  case mi of
    0..15: Result := 6;
    16..30: Result := 5;
    31..45: Result := 4;
    46..60: Result := 3;
    61..75: Result := 2;
    76..MaxInt: Result := 1;

  end;

end;
procedure TFormServer.store_Uniform ( Guidteam: integer; CommaText: string );
var
  ts,UniformH,UniformA: TStringList;
  i: Integer;
  qTeams: TMyQuery;
  ConnGame : TMyConnection;
begin
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  ts.Delete(0); // SetUniform

  UniformH:= TStringList.Create ;
  UniformA:= TStringList.Create ;

  for I := 0 to 3 do begin
    UniformH.Add(ts[i]);
  end;
  for I := 4 to 7 do begin
    UniformA.Add(ts[i]);
  end;



  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='f_game';
  Conngame.Connected := True;

  qTeams := TMyQuery.Create(nil);


  qTeams.Connection := ConnGame;   // game

  qTeams.SQL.text := 'UPDATE f_game.teams set uniformh="' + UniformH.CommaText + '",uniforma="' +
                                UniformA.CommaText + '" WHERE guid =' + IntToStr(Guidteam);
  qTeams.Execute ;
  qTeams.SQL.text := 'UPDATE m_game.teams set uniformh="' + UniformH.CommaText + '",uniforma="' +
                                UniformA.CommaText + '" WHERE guid =' + IntToStr(Guidteam);
  qTeams.Execute ;

  qTeams.Free;
  Conngame.Connected := false;
  Conngame.Free;
  UniformH.Free;
  UniformA.Free;
  ts.Free;

end;

procedure TFormServer.store_formation (fm : Char; CommaText: string );
var
  i: Integer;
  ts: TStringList;
  strCells: string;
  tscells: TStringList;
  qPlayers: TMyQuery;
  ConnGame : TMyConnection;
begin

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  ts.Delete(0); // SetFormation


  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=fm + '_game';
  Conngame.Connected := True;


  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game

  for I := 0 to ts.Count - 1 do begin
    strCells:= ts.ValueFromIndex [i];
    tscells:= TStringList.Create ;
    tscells.StrictDelimiter := True;
    tscells.Delimiter := ':';
    tscells.DelimitedText := strCells;
    qPlayers.SQL.text := 'UPDATE '+fm+'_game.players set formation_x ="' + tscells [0] + '", formation_y ="' +  tscells [1] + '" WHERE guid =' + ts.Names [i];
    qPlayers.Execute ;

    tsCells.Free;
  end;

  qPlayers.Free;
  Conngame.Connected:= False;
  Conngame.Free;
  ts.Free;

end;
procedure TFormServer.Reset_Formation ( Cli:TWSocketThrdClient  );
var
  i: Integer;
  aReserveSlot: Integer;
  qPlayers, MyQueryUpdate : TMyQuery;
  ReserveSlot : TTheArray;
  ConnGame : TMyConnection;
begin
  CleanReserveSlot ( ReserveSlot );
  // Singoli players

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=Cli.ActiveGender+ '_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'SELECT guid,formation_x,formation_y from '+Cli.ActiveGender+'_game.players WHERE team =' +
                        IntToStr(Cli.GuidTeams[Cli.ActiveGenderN])+ ' and young=0';
  qPlayers.Execute ;

  MyQueryUpdate := TMyQuery.Create(nil);
  MyQueryUpdate.Connection := ConnGame;   // game

  for I := 0 to qPlayers.RecordCount -1 do begin
    aReserveSlot := NextReserveSlot ( ReserveSlot );

    ReserveSlot[aReserveSlot]:= qPlayers.FieldByName('guid').AsString;
    MyQueryUpdate.SQL.text := 'UPDATE '+Cli.ActiveGender+'_game.players set formation_x =' + IntToStr(aReserveSlot) + ', formation_y =-1 WHERE guid =' + qPlayers.FieldByName('guid').AsString;
    MyQueryUpdate.Execute ;
    qPlayers.Next;
  end;

  qPlayers.Free;
  MyQueryUpdate.Free;
  Conngame.Connected := false;
  Conngame.free;


end;
procedure TFormServer.Reset_Formation ( fm : Char; GuidTeam: Integer );
var
  i: Integer;
  aReserveSlot: Integer;
  qPlayers, MyQueryUpdate : TMyQuery;
  ReserveSlot : TTheArray;
  ConnGame : TMyConnection;
begin
  CleanReserveSlot ( ReserveSlot );
  // Singoli players

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= fm +'_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'SELECT guid,formation_x,formation_y from '+fm+'_game.players WHERE team =' + IntToStr(GuidTeam)+ ' and young=0';
  qPlayers.Execute ;

  MyQueryUpdate := TMyQuery.Create(nil);
  MyQueryUpdate.Connection := ConnGame;   // game

  for I := 0 to qPlayers.RecordCount -1 do begin
    aReserveSlot := NextReserveSlot ( ReserveSlot );

    ReserveSlot[aReserveSlot]:= qPlayers.FieldByName('guid').AsString;
    MyQueryUpdate.SQL.text := 'UPDATE '+fm+'_game.players set formation_x =' + IntToStr(aReserveSlot) + ', formation_y =-1 WHERE guid =' + qPlayers.FieldByName('guid').AsString;
    MyQueryUpdate.Execute ;
    qPlayers.Next;
  end;

  qPlayers.Free;
  MyQueryUpdate.Free;
  Conngame.Connected := false;
  Conngame.free;


end;
procedure TFormServer.validate_setuniform ( CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  i,aValue: Integer;
begin

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  ts.Delete(0); //setformation

  if ts.Count <> 8 then begin        // 2 jersey, 1 shorts , 1 schema
      cli.sReason := 'validate_setuniform Invalid ts count ' ;
      ts.Free;
      Exit;
  end;

  for I := 0 to 7 do begin
    if not TryDecimalStrToInt(ts[i], aValue) then begin
      cli.sReason := 'validate_setuniform Invalid uniform  ' ;
      ts.Free;
      Exit;

    end
    else begin
      if (aValue < 0) or (aValue > 12) then begin
        cli.sReason := 'validate_setuniform uniform Invalid color index  ' ;
        ts.Free;
        Exit;
      end;
    end;

  end;

  ts.Free;


end;
procedure TFormServer.validate_setformation ( CommaText: string; Cli:TWSocketThrdClient  );
var
  i,i2,guid: Integer;
  ts: TStringList;
  strCells: string;
  tscells: TStringList;
  PositionCellX,PositionCellY: Integer;
  CellPoint : TPoint;
  lstCellPoint: TList<TPoint>;
  aValidPlayer: TValidPlayer;
begin

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  ts.Delete(0); //setformation
  lstCellPoint:= TList<TPoint>.Create;


  for I := 0 to ts.Count - 1 do begin
    Guid := StrToIntDef(  ts.Names [i] , 0  );
    // validate player. dal cli risale al guidteam (cli.guidteam)
    aValidPlayer:= validate_player (  guid,Cli);

    if cli.sReason <> '' then Exit;
    strCells:= ts.ValueFromIndex [i];
    tscells:= TStringList.Create ;
    tscells.StrictDelimiter := True;
    tscells.Delimiter := ':';
    tscells.delimitedText := strCells;
    if tscells.Count <> 2 then begin
      cli.sReason := 'Invalid Cell formation count ' ;
      tscells.Free;
      ts.Free;
      lstCellPoint.Free;
      Exit;
    end;

    PositionCellX:= StrToIntDef(  tscells [0] , 0  );
    PositionCellY:= StrToIntDef(  tscells [1] , 0  );


      if (PositionCellX < -1 ) or (PositionCellX > 6 ) then begin  // coincidenza 6    -1
        cli.sReason := 'Invalid Cell formation <-1 or >6 ' + IntToStr( guid) + ' ' + strCells;
        tscells.Free;
        ts.Free;
        lstCellPoint.Free;
        Exit;
      end;

    case PositionCellY  of
      1,2,4,5,7,8,10: begin
        if PositionCellX > 0 then begin
          cli.sReason := 'Invalid Cell formation Y36911 ' + IntToStr( guid) + ' ' + strCells;
          tscells.Free;
          ts.Free;
          lstCellPoint.Free;
          Exit;
        end;
      end;
    end;


    if (PositionCellX > 0) and  (PositionCellY > -1)  and ( aValidPlayer.disqualified > 0) then begin
      cli.sReason := 'Player disqualified ' + IntToStr( guid) + ' ' + strCells;
      tscells.Free;
      ts.Free;
      lstCellPoint.Free;
      Exit;
    end;

    if (PositionCellX < 0) and (PositionCellY > 6) then begin
      cli.sReason := 'Invalid reserve cell ' + IntToStr( guid) + ' ' + strCells;
      tscells.Free;
      ts.Free;
      lstCellPoint.Free;
      Exit;
    end;


    // qui è per forza in campo oppure è a -1
    // cerco celle duplicate
      for i2 := 0 to lstCellPoint.Count -1 do begin
        if (lstCellPoint[i2].X = PositionCellX) and (lstCellPoint[i2].Y = PositionCellY) then  begin
          cli.sReason := 'Duplicated cells formation ' + IntToStr( guid) + ' ' + strCells;
          tscells.Free;
          ts.Free;
          lstCellPoint.Free;
          Exit;
        end;
      end;

      CellPoint.X :=  PositionCellX;
      CellPoint.Y :=  PositionCellY;
      lstCellPoint.Add (CellPoint);



    tscells.Free;

  end;


  ts.Free;
  lstCellPoint.Free;

end;
procedure TFormServer.validate_sell ( commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer,sellprice
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'validate_sell Player not numeric';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[2], AValue) then begin
    cli.sReason:= 'validate_sell sell price not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure TFormServer.validate_cancelsell ( commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'validate_sell Player not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;


end;
procedure TFormServer.validate_buy ( commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'validate_sell Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'validate_sell Player not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure TFormServer.validate_dismiss ( commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'validate_dismiss Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'validate_dismiss Player not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure TFormServer.validate_market ( commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'validate_market Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'validate_market Maxvalue not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
function TFormServer.validate_player ( const guid: integer; Cli:TWSocketThrdClient): TValidPlayer;
var
  qPlayers: TMyQuery;
  ConnGame : TMyConnection;
begin
  (* Valido il player, disqualified è solo una info aggiuntiva che chi chiama gestisce*)

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=Cli.ActiveGender + '_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'SELECT * from ' +cli.ActiveGender  +'_game.players WHERE team =' +
                                  IntToStr(Cli.GuidTeams[Cli.ActiveGenderN] ) + ' and guid = ' + IntToStr(guid)+' and young=0';
  qPlayers.Execute ;

  if qPlayers.RecordCount <= 0 then begin
    cli.sReason:= 'Player not found ' + IntToStr(guid);
    qPlayers.Free;
    Conngame.Connected := false;
    Conngame.Free;
    Exit;
  end
  else begin

    Result.disqualified := qPlayers.FieldByName ('disqualified').AsInteger;
    Result.Age:= Trunc(  qPlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
    Result.talentID1 := qPlayers.FieldByName ('talentid1').AsInteger;
    Result.talentID2 := qPlayers.FieldByName ('talentid2').AsInteger;
    Result.speed :=  qPlayers.FieldByName ('speed').AsInteger;
    Result.defense :=  qPlayers.FieldByName ('defense').AsInteger;
    Result.passing :=  qPlayers.FieldByName ('passing').AsInteger;
    Result.ballcontrol :=  qPlayers.FieldByName ('ballcontrol').AsInteger;
    Result.shot :=  qPlayers.FieldByName ('shot').AsInteger;
    Result.heading :=  qPlayers.FieldByName ('heading').AsInteger;
    Result.history := qPlayers.FieldByName ('history').AsString;
    Result.xp := qPlayers.FieldByName ('xp').AsString;

    Result.chancelvlUp := qPlayers.FieldByName ('deva').AsInteger;
    Result.chancetalentlvlUp :=  qPlayers.FieldByName ('devt').AsInteger;

  end;

  qPlayers.Free;
  Conngame.Connected := false;
  Conngame.Free;

end;
function TFormServer.checkformation ( Cli:TWSocketThrdClient ): Boolean;
var
  i,pdisq,pcount: Integer;
  qPlayers: TMyQuery;
  ConnGame : TMyConnection;
  label skip;
begin
  // controlla se sono schierati 11 giocatori a parte i disqualified. se può farlo deve giocare col massimo dei giocatori
  Result:= False;

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=Cli.ActiveGender + '_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.text := 'SELECT guid, formation_x,formation_y,disqualified from '+Cli.ActiveGender+'_game.players WHERE team =' +
                        IntToStr(Cli.GuidTeams[Cli.ActiveGenderN] )+ ' and young=0';
  qPlayers.Execute ;

  pcount:=0;
  pdisq:=0;

  for i := 0 to qPlayers.RecordCount -1 do begin
    if IsOutSideAI( qPlayers.FieldByName ('formation_x').AsInteger,  qPlayers.FieldByName ('formation_y').AsInteger ) or
    (qPlayers.FieldByName ('disqualified').AsInteger > 0) then goto skip;

    if ( qPlayers.FieldByName ('formation_y').AsInteger = 6) or
       (qPlayers.FieldByName ('formation_y').AsInteger = 3) or
       (qPlayers.FieldByName ('formation_y').AsInteger = 9) or
       (qPlayers.FieldByName ('formation_y').AsInteger = 11)  then begin
         Inc(pCount);
       end;
skip:
    qPlayers.Next;
  end;

  for i := 0 to qPlayers.RecordCount -1 do begin
    if qPlayers.FieldByName ('disqualified').AsInteger > 0 then Inc(pDisq);
    qPlayers.Next;
  end;

  // se sono 11 non sqlificati altrimenti...
  if pcount = 11 then begin
    result := True;
  end;

  // qui result è false perchè maggiore o inferiore a 11
  if pcount > 11 then begin
    result := false;
  end;

  // ... ti perdono il fatto che non puoi scherarne 11
  if result = false then begin
    if (qPlayers.RecordCount - pdisq) < 11 then begin
      Result:= True; // formazione valida con quello che è disponibile
    end;

  end;
   qPlayers.Free;
  Conngame.Connected := false;
  Conngame.Free;


end;

procedure TFormServer.TcpserverError(Sender: TObject);
begin
      Memo1.Lines.add('on error ' );

end;

procedure TFormServer.TcpserverException(Sender: TObject; SocExcept: ESocketException);
begin
      Memo1.Lines.add('Can''t connect, error ' + SocExcept.ErrorMessage);

end;

function TFormServer.RndGenerate( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (1, Upper + 1));
end;
function TFormServer.RndGenerate0( Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (0, Upper + 1));
end;
function TFormServer.RndGenerateRange( Lower, Upper: integer ): integer;
begin
  Result := Trunc(RandGen.AsLimitedDouble (Lower, Upper + 1));
end;

function TFormServer.RemoveFromQueue(Cliid: integer ): Boolean;
var
  i: Integer;
begin
  Result := False;
  WaitForSingleObject(Mutex,INFINITE);
  for I := Queue.Count - 1 downto 0 do begin
    if Queue[i].CliId = CliId then begin
      result := True;
      Queue.Delete(i);
      ReleaseMutex(Mutex);
      Exit;
    end;

  end;
  ReleaseMutex(Mutex);
end;

function TFormServer.inQueue(Cliid: integer ): Boolean;
var
  i: Integer;
begin
  Result := False;
  WaitForSingleObject(Mutex,INFINITE);
  for I := 0 to Queue.Count - 1 do begin
    if Queue[i].CliId = CliId then begin
      result := True;
      ReleaseMutex(Mutex);
      Exit;
    end;

  end;
  ReleaseMutex(Mutex);
end;
function TFormServer.inLivematchCliId(Cliid: integer ): Boolean;
var
  i: Integer;
begin
  Result := False;
  WaitForSingleObject(Mutex,INFINITE);
  for I := BrainManager.lstBrain.Count - 1 downto 0  do begin
    if  (BrainManager.lstBrain [i].Score.CliId [0] = CliId) or (BrainManager.lstBrain [i].Score.CliId [1] = CliId)  and (not BrainManager.lstBrain [i].Finished ) then begin
      result := True;
      ReleaseMutex(Mutex);
      Exit;
    end;

  end;
  ReleaseMutex(Mutex);
end;
function TFormServer.inLivematchGuidTeam(fm : char; GuidTeam: integer ): TSoccerBrain;
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  Result := nil;
  for I := BrainManager.lstBrain.Count - 1  downto 0 do begin
    if  (BrainManager.lstBrain [i].Score.TeamGuid [0] = GuidTeam) or (BrainManager.lstBrain [i].Score.TeamGuid  [1] = GuidTeam)
    and ((BrainManager.lstBrain [i].Gender = fm )) and (not BrainManager.lstBrain [i].Finished )
    then begin
      result := BrainManager.lstBrain [i];
      ReleaseMutex(Mutex);
      Exit;
    end;

  end;
  ReleaseMutex(Mutex);
end;
function TFormServer.inSpectator(Cliid: integer ): boolean;
var
  i,y: Integer;
begin
  Result := False;
  WaitForSingleObject(Mutex,INFINITE);
  for I := BrainManager.lstBrain.Count - 1  downto 0 do begin
    for Y := 0 to BrainManager.lstBrain [i].lstSpectator.Count - 1 do begin
      if  BrainManager.lstBrain [i].lstSpectator[y]  = CliId then begin
        result := true;
        ReleaseMutex(Mutex);
        Exit;
      end;
    end;
  end;
  ReleaseMutex(Mutex);
end;

function TFormServer.inSpectatorGetBrain(Cliid: integer ): TSoccerBrain;
var
  i,y: Integer;
begin
  Result := nil;
  WaitForSingleObject(Mutex,INFINITE);
  for I := BrainManager.lstBrain.Count - 1  downto 0 do begin
    for Y := 0 to BrainManager.lstBrain [i].lstSpectator.Count - 1 do begin
      if  BrainManager.lstBrain [i].lstSpectator[y]  = CliId then begin
        result := BrainManager.lstBrain [i];
        ReleaseMutex(Mutex);
        Exit;
      end;
    end;
  end;
  ReleaseMutex(Mutex);
end;
function TFormServer.RemoveFromSpectator(Cliid: integer ): boolean;
var
  i,y: Integer;
begin
  Result := false;
  WaitForSingleObject(Mutex,INFINITE);
  for I := BrainManager.lstBrain.Count - 1  downto 0 do begin
    for Y := BrainManager.lstBrain [i].lstSpectator.Count - 1 downto 0 do begin
      if BrainManager.lstBrain [i].lstSpectator[y]  = CliId then begin
        BrainManager.lstBrain [i].lstSpectator.Delete (y);
        result := True;
        ReleaseMutex(Mutex);
        Exit;
      end;
    end;
  end;
  ReleaseMutex(Mutex);
end;


procedure TFormServer.MatchThreadTimer(Sender: TObject);
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  if CheckBoxActiveMacthes.Checked then
    SetupRefreshGrid;

  for I := BrainManager.lstBrain.Count -1 downto 0 do begin
    if CheckBoxActiveMacthes.Checked then begin
      Stringgrid1.RowCount := BrainManager.lstBrain.Count + 1;  // <-- necessario o bug
      Stringgrid1.Cells[0,i+1] := IntToStr(BrainManager.lstBrain [i].Score.TeamGuid [0]) + '/'+ BrainManager.lstBrain [i].Score.Team [0] + '/' + IntToStr(BrainManager.lstBrain [i].Score.cliId [0]);
      Stringgrid1.Cells[1,i+1] := IntToStr( BrainManager.lstBrain [i].Score.TeamGuid [1]) + '/'+ BrainManager.lstBrain [i].Score.Team [1] + '/' + IntToStr(BrainManager.lstBrain [i].Score.CliId [1]);
      Stringgrid1.Cells[2,i+1] := IntToStr(BrainManager.lstBrain [i].TeamTurn );
      Stringgrid1.Cells[3,i+1] := IntToStr((BrainManager.lstBrain [i].fMilliseconds div 1000) );
      if BrainManager.lstBrain [i].Score.AI[0]  then
        Stringgrid1.Cells[4,i+1]:= 'Active' else  Stringgrid1.Cells[4,i+1]:= '';
      if BrainManager.lstBrain [i].Score.AI[1]  then
        Stringgrid1.Cells[5,i+1]:= 'Active' else  Stringgrid1.Cells[5,i+1]:= '';

      Stringgrid1.Cells[6,i+1]:= IntToStr(BrainManager.lstBrain [i].Minute );
      Stringgrid1.Cells[7,i+1]:= IntToStr(BrainManager.lstBrain [i].Score.Gol[0])+'-'+IntToStr(BrainManager.lstBrain [i].Score.Gol[1]) ;
      Stringgrid1.Cells[8,i+1]:= IntToStr(BrainManager.lstBrain [i].lstSoccerPlayer.count)+'/'+
                                                                    IntToStr(BrainManager.lstBrain [i].lstSoccerReserve.count) + '/' +
                                                                    IntToStr(BrainManager.lstBrain [i].lstSoccerGameover.count);
      Stringgrid1.Cells[9,i+1]:= BrainManager.lstBrain [i].Gender ;
    end;
    if BrainManager.lstBrain [i].paused or BrainManager.lstBrain[i].Finished then Continue;

    if not BrainManager.lstBrain [i].utime then
       BrainManager.lstBrain [i].milliseconds := BrainManager.lstBrain [i].milliseconds - MatchThread.Interval; // viene eseguita AI freekick

      // aistart   se un player si disconnette o se è una ver AI
       if (BrainManager.lstBrain [i].milliseconds <= 0) or (BrainManager.lstBrain [i].Score.AI [BrainManager.lstBrain [i].TeamTurn]) then Begin
          BrainManager.lstBrain [i].AI_GCD := BrainManager.lstBrain [i].AI_GCD - MatchThread.Interval  ;
        if BrainManager.lstBrain [i].AI_GCD <= 0 then begin
          BrainManager.lstBrain [i].AI_Think(BrainManager.lstBrain [i].TeamTurn);
          if BrainManager.lstBrain [i].milliseconds > 4000 then begin
            if RadioButton1.Checked then
              BrainManager.lstBrain [i].AI_GCD := StrToInt(Edit2.Text) // {8000} BrainManager.RndGenerateRange( 3000, 12000 )
            else
              BrainManager.lstBrain [i].AI_GCD := BrainManager.RndGenerateRange( StrToInt(Edit2.Text), StrToInt(Edit3.Text) );
          end
          else
          BrainManager.lstBrain [i].AI_GCD := StrToInt(Edit2.Text) ;

          Application.ProcessMessages;
        end;
       end;

  //  end;
  end;


  for I := BrainManager.lstBrain.Count -1 downto 0 do begin
    if BrainManager.lstBrain [i].paused then Continue;
    if BrainManager.lstBrain[i].Finished then // 30 secondi poi cancella il brain
      if GetTickCount - BrainManager.lstBrain[i].FinishedTime > 30000 then begin
         WaitForSingleObject(MutexLockBrain,INFINITE);
         BrainManager.lstBrain.Delete(i); // libera anche gli spettatori
         ReleaseMutex(MutexLockBrain);
   //      Break;
      end;
  end;
  ReleaseMutex(Mutex);


  Application.ProcessMessages;

end;


procedure TFormServer.Button2Click(Sender: TObject);
var
  i: Integer;
  THEWORLDTEAM : string;
  cli: TWSocketThrdClient;
  ConnAccount,ConnWorld : TMyConnection;
  MyQueryAccount,MyQueryWT: TMyQuery;
begin

  ConnAccount := TMyConnection.Create(nil);
  ConnAccount.Server := MySqlServerAccount;
  ConnAccount.Username:='root';
  ConnAccount.Password:='root';
  ConnAccount.Database:='realmd';
  ConnAccount.Connected := True;

  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='world';
  ConnWorld.Connected := True;

  MyQueryAccount := TMyQuery.Create(nil);
  MyQueryWT := TMyQuery.Create(nil);
  MyQueryAccount.Connection := ConnAccount;   // realmd
  MyQueryWT.Connection := ConnWorld;   // world

  cli:= TWSocketThrdClient.Create(nil);

  for I := 1 to 300 do begin

    MyQueryAccount.SQL.Text := 'select id from realmd.account where username=' + '"TEST' + IntToStr(i) + '"';
    MyQueryAccount.Execute;

    cli.CliId := MyQueryAccount.FieldByName('id').AsInteger;

    MyQueryWT.SQL.Text := 'select guid from world.teams order by rand() limit 1';
    MyQueryWT.Execute;

    THEWORLDTEAM :=  MyQueryWT.FieldByName('guid').AsString;
    CreateGameTeam (  'f', Cli, THEWORLDTEAM );  // ts[1] è guid world.teams, non la Guidteam
    CreateGameTeam (  'm', Cli, THEWORLDTEAM );  // ts[1] è guid world.teams, non la Guidteam
    ProgressBar1.Position := (100* i) div 300 ;
    application.ProcessMessages;

  end;
  ProgressBar1.Position := 0;


  cli.Free;
  MyQueryWT.Free;
  MyQueryAccount.Free;
  ConnAccount.Connected := false;
  ConnAccount.Free;
  ConnWorld.Connected:= False;
  ConnWorld.Free;

  ShowMessage ('Done!');

end;
procedure TFormServer.Button3Click(Sender: TObject);
var
  i: Integer;
  MyQueryWT ,qTeams: TMyQuery;
  ConnWorld, ConnGame : TMyConnection;
begin
// Prende i colori del team reale db.world e lo trasmette a tutti i team eisstenti in db.game
// in questo modo aggiornando solo le maglie di tutte le squadre reali, si aggiornano tutti i team dei giocatori
// eventualmente un oggetto cosmetico può essere quello di una uniforme personalizzata


  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='world';
  ConnWorld.Connected := True;

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='f_game';
  Conngame.Connected := True;

  qTeams := TMyQuery.Create(nil);
  MyQueryWT := TMyQuery.Create(nil);
  qTeams.Connection := ConnGame;   // game
  MyQueryWT.Connection := ConnWorld;   // world
  MyQueryWT.SQL.Text := 'select guid, name, uniformh,uniforma from world.teams';
  MyQueryWT.Execute;

  for I := 0 to MyQueryWT.RecordCount -1 do begin
    qTeams.SQL.Text := 'UPDATE f_game.teams set name="'+MyQueryWT.FieldByName('name').AsString + '",uniformh="' +
                                  MyQueryWT.FieldByName('uniformh').AsString + '",uniforma="' +
                                  MyQueryWT.FieldByName('uniforma').AsString + '" WHERE worldteam =' + MyQueryWT.FieldByName('guid').AsString;
    qTeams.Execute;
    qTeams.SQL.Text := 'UPDATE m_game.teams set name="'+MyQueryWT.FieldByName('name').AsString + '",uniformh="' +
                                  MyQueryWT.FieldByName('uniformh').AsString + '",uniforma="' +
                                  MyQueryWT.FieldByName('uniforma').AsString + '" WHERE worldteam =' + MyQueryWT.FieldByName('guid').AsString;
    qTeams.Execute;
    MyQueryWT.Next;
  end;

  qTeams.Free;
  MyQueryWT.Free;

  Conngame.Connected:= False;
  Conngame.Free;
  ConnWorld.Connected:= False;
  ConnWorld.Free;
  ShowMessage ('Done!');

end;


procedure TFormServer.Button4Click(Sender: TObject);
var
  ConnGame : TMyConnection;
  qVarious: TMyQuery;
begin
//

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= 'f_game';
  Conngame.Connected := True;


  qVarious := TMyQuery.Create(nil);
  qVarious.Connection := ConnGame;   // game
  qVarious.SQL.text := 'DELETE FROM f_game.market WHERE guidteam =0';
  qVarious.Execute ;
  qVarious.SQL.text := 'DELETE FROM m_game.market WHERE guidteam =0';
  qVarious.Execute ;
  qVarious.SQL.text := 'DELETE FROM f_game.players WHERE team =0';
  qVarious.Execute ;
  qVarious.SQL.text := 'DELETE FROM m_game.players WHERE team =0';
  qVarious.Execute ;

  qVarious.Free;
  ConnGame.Free;


end;

procedure TFormServer.Button5Click(Sender: TObject);
var
  MyQueryAccount: TMyQuery ;
  sha_pass_hash: string;
  UserName,password : string;
  ConnAccount : TMyConnection ;
  label createteam;
begin

  ConnAccount := TMyConnection.Create(nil);
  ConnAccount.Server := MySqlServerAccount;
  ConnAccount.Username:='root';
  ConnAccount.Password:='root';
  ConnAccount.Database:='realmd';
  ConnAccount.Connected := True;

  MyQueryAccount := TMyQuery.Create(nil);
  MyQueryAccount.Connection := ConnAccount;   // realmd

  // genero test1, test2, test3 ecc....

    username :=  Uppercase(Edit5.Text);
    password := Uppercase(Edit6.Text);
    sha_pass_hash := GetStrHashSHA1 ( username + ':' + Password );
    MyQueryAccount.SQL.Text := 'insert into realmd.account (username, sha_pass_hash, email)  values (' +
                                 '"' + username + '","' +  sha_pass_hash  + '","' +  UserName +'.GMAIL.COM")';

    MyQueryAccount.Execute;


  MyQueryAccount.free;
  ConnAccount.Connected:= False;
  ConnAccount.Free;

  ShowMessage ('Done!');


end;

procedure TFormServer.CreateRandomBotMatch (fm :Char);
var
  aRnd : Integer;
  OpponentBOT: TServerOpponent;
  qTeams: TMyQuery;
  ConnGame : TMyConnection;
  label retry1, retry2, MyExit;
begin

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:=fm+ '_game';
  Conngame.Connected := True;

  qTeams := TMyQuery.Create(nil);
  qTeams.Connection := ConnGame;   // game

//  while BrainManager.lstBrain.Count < 10 do begin
    // prendo dal db un test a caso che non sia già in lstbrain  ( entercriticalSession
    // WorldTeam esclude automaticamente anche se stessi. Qui cerco sul db un bot

retry1:
      Application.ProcessMessages;
      aRnd := RndGenerate (300);   // numero di bot account test

      qTeams.SQL.text := 'SELECT username, guid, worldTeam, rank, nextha, bot from realmd.account INNER JOIN '+fm+'_game.teams ON realmd.account.id = '+fm+'_game.teams.account WHERE ' +
                                    'username = "TEST' + IntTostr(aRnd) + '" and bot <> 0 and nextha = 0'; // parto dal team0
      qTeams.Execute ;

      if qTeams.RecordCount = 0 then goto retry1; // non nextha
     // if qTeams.RecordCount > 0 then begin
       if inLiveMatchGuidTeam( fm, qTeams.FieldByName('guid').AsInteger ) <> nil then goto MyExit;// retry1;   // già in gioco
retry2:
      Application.ProcessMessages;
        GetGuidTeamOpponentBOT ( fm, qTeams.FieldByName('worldteam').AsInteger  ,
                                  qTeams.FieldByName('rank').AsInteger  , // marketTeam
                                  qTeams.FieldByName('nextha').AsInteger,
                                  OpponentBOT.GuidTeam,OpponentBOT.UserName   ); // worldteam diversa in opponent, no Bologna vs Bologna
        if inLiveMatchGuidTeam( fm, OpponentBOT.GuidTeam ) <> nil then goto MyExit;// retry2;    // già in gioco il secondo

        CreateMatchBOTvsBOT (fm,  qTeams.FieldByName('guid').AsInteger  , OpponentBOT.GuidTeam,
                                qTeams.FieldByName('username').AsString,  OpponentBOT.Username );

     // end;

//  end;
MyExit:
  qTeams.free;
  Conngame.Connected:= False;
  Conngame.Free;

end;
procedure TFormServer.CreateRewards; // uguale a quella del client
begin
//  Rewards[1,114]:= 15000; Rewards[1,97]:= 97000; Rewards[1,90]:= 9000;  Rewards[1,4]:= 7600;  Rewards[1,5]:= 7200;
//  Rewards[1,16]:= 4000; Rewards[1,17]:= 3800; Rewards[1,18]:= 3600;  Rewards[1,19]:= 3400;  Rewards[1,20]:= 2000;
//  Rewards[1,16]:= 4000; Rewards[1,17]:= 3800; Rewards[1,18]:= 3600;  Rewards[1,1]:= 100;  Rewards[1,0]:= 0;

//  Rewards[1,16]:= 1600 div 4; Rewards[1,17]:= 3800; Rewards[1,18]:= 3600;  Rewards[1,1]:= 100;  Rewards[1,0]:= 0;

  Rewards[1,1]:= 15000; Rewards[1,2]:= 10000; Rewards[1,3]:= 8000;  Rewards[1,4]:= 7600;  Rewards[1,5]:= 7200;
  Rewards[1,6]:= 6800; Rewards[1,7]:= 6700; Rewards[1,8]:= 6600;  Rewards[1,9]:= 6500;  Rewards[1,10]:= 6400;
  Rewards[1,11]:= 5000; Rewards[1,12]:= 4800; Rewards[1,13]:= 4700;  Rewards[1,14]:= 4600;  Rewards[1,15]:= 4500;
  Rewards[1,16]:= 4000; Rewards[1,17]:= 3800; Rewards[1,18]:= 3600;  Rewards[1,19]:= 3400;  Rewards[1,20]:= 3200;

  Rewards[2,1]:= 6400; Rewards[2,2]:= 5800; Rewards[2,3]:= 5500;  Rewards[2,4]:= 5000;  Rewards[2,5]:= 4800;
  Rewards[2,6]:= 4200; Rewards[2,7]:= 4000; Rewards[2,8]:= 3800;  Rewards[2,9]:= 3600;  Rewards[2,10]:= 3200;
  Rewards[2,11]:= 3000; Rewards[2,12]:= 2800; Rewards[2,13]:= 2600;  Rewards[2,14]:= 2400;  Rewards[2,15]:= 2200;
  Rewards[2,16]:= 2000; Rewards[2,17]:= 1900; Rewards[2,18]:= 1800;  Rewards[2,19]:= 1700;  Rewards[2,20]:= 1600;

  Rewards[3,1]:= 3200; Rewards[3,2]:= 2800; Rewards[3,3]:= 2600;  Rewards[3,4]:= 2400;  Rewards[3,5]:= 2200;
  Rewards[3,6]:= 2000; Rewards[3,7]:= 1900; Rewards[3,8]:= 1800;  Rewards[3,9]:= 1700;  Rewards[3,10]:= 1600;
  Rewards[3,11]:= 1200; Rewards[3,12]:= 1100; Rewards[3,13]:= 1000;  Rewards[3,14]:= 750;  Rewards[3,15]:= 700;
  Rewards[3,16]:= 600; Rewards[3,17]:= 575; Rewards[3,18]:= 550;  Rewards[3,19]:= 525;  Rewards[3,20]:= 500;

  Rewards[4,1]:= 1600; Rewards[4,2]:= 1200; Rewards[4,3]:= 1000;  Rewards[4,4]:= 750;  Rewards[4,5]:= 700;
  Rewards[4,6]:= 600; Rewards[4,7]:= 575; Rewards[4,8]:= 550;  Rewards[4,9]:= 525;  Rewards[4,10]:= 500;
  Rewards[4,11]:= 350; Rewards[4,12]:= 325; Rewards[4,13]:= 300;  Rewards[4,14]:= 275;  Rewards[4,15]:= 250;
  Rewards[4,16]:= 200; Rewards[4,17]:= 175; Rewards[4,18]:= 150;  Rewards[4,19]:= 125;  Rewards[4,20]:= 100;
end;

procedure TFormServer.Button6Click(Sender: TObject);
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
  aName, aSurname,  Attributes,aIds: string;
  PenaltyCell: TPoint;
  Injured: Integer;
  CornerMap: TCornerMap;
  ACellBarrier,TvReserveCell: TPoint;
  DefaultSpeed, DefaultDefense , DefaultPassing, DefaultBallControl, DefaultShot, DefaultHeading: Byte;
  Speed, Defense , Passing, BallControl, Shot, Heading: ShortInt;
  sf :  SE_SearchFiles;
  MyBrain: TSoccerBrain;
  Buf3 : array [0..8191] of AnsiChar;
  MM : TMemoryStream;
  ids :string;

begin
  FolderDialog1.Directory := dir_log;

  if not FolderDialog1.Execute then begin
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

  if sf.ListFiles.Count < 0 then begin
    sf.Free;
    Exit;
  end;

  MM:= TMemoryStream.Create;
  if not FileExists( FolderDialog1.Directory  + '\' + sf.ListFiles[sf.ListFiles.Count-1] ) then begin
    MM.Free;
    sf.Free;
    Exit;
  end;
  ids := JustFileNameL (FolderDialog1.Directory);
  MyBrain := TSoccerBrain.create (  ids, ids[1],0 ,0,0,0);
  MM.LoadFromFile( FolderDialog1.Directory   + '\' + sf.ListFiles[sf.ListFiles.Count-1]);
  CopyMemory( @Buf3[0], MM.Memory, MM.size );

  SS := TStringStream.Create;
  SS.Size := MM.Size;
  MM.Position := 0;
  ss.CopyFrom( MM, MM.size );
  //    dataStr := RemoveEndOfLine(string(buf));
  dataStr := SS.DataString;
  SS.Free;

  if RightStr(dataStr,2) <> 'IS' then Exit;


  // a 0 c'è la word che indica dove comincia tsScript
  cur := 2;
  lenuser0:=  Ord( buf3 [ cur ]);                 // ragiona in base 0
  MyBrain.Score.Username [0] := MidStr( dataStr, cur +2  , lenUser0 );// ragiona in base 1
  cur  := cur + lenuser0 + 1;
  lenuser1:=  Ord( buf3[Cur]);                 // ragiona in base 0
  MyBrain.Score.Username [1] := MidStr( dataStr, Cur + 2, lenUser1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenUser1 + 1;

  lenteamname0 :=  Ord( buf3[ cur ]);
  MyBrain.Score.Team [0]  := MidStr( dataStr, cur + 2  , lenteamname0 );// ragiona in base 1
  cur  := cur + lenteamname0 + 1;
  lenteamname1:=  Ord( buf3[Cur]);                 // ragiona in base 0
  MyBrain.Score.Team [1] := MidStr( dataStr, Cur + 2, lenteamname1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenteamname1 + 1;

  MyBrain.Score.TeamGuid [0] :=  PDWORD(@buf3[ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.TeamGuid [1] :=  PDWORD(@buf3[ cur ])^;
  cur := cur + 4 ;

  MyBrain.Score.Rank [0] :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.Rank [1] :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;

  MyBrain.Score.TeamMI [0] :=  PDWORD(@buf3[ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.TeamMI [1] :=  PDWORD(@buf3[ cur ])^;
  cur := cur + 4 ;

  MyBrain.Score.Country [0] :=  PWORD(@buf3[ cur ])^;
  cur := cur + 2 ;
  MyBrain.Score.Country [1] :=  PWORD(@buf3[ cur ])^;
  cur := cur + 2 ;

  lenUniform0 :=  Ord( buf3[ cur ]);
  MyBrain.Score.Uniform [0]  := MidStr( dataStr, cur + 2  , lenUniform0 );// ragiona in base 1
  cur  := cur + lenUniform0 + 1;
  lenUniform1:=  Ord( buf3[Cur]);                 // ragiona in base 0
  MyBrain.Score.Uniform [1] := MidStr( dataStr, Cur + 2, lenUniform1 );// ragiona in base 1   uso solo SS
  cur := Cur + lenUniform1 + 1;


  MyBrain.Score.Gol [0] :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.Gol [1] :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;

  MyBrain.Score.BuffD[0]:= Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffD[1]:= Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffM[0]:= Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffM[1]:= Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffF[0]:= Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.BuffF[1]:= Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.TeamSubs[0]:= Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.TeamSubs[1]:= Ord( buf3[ cur ]);
  cur := cur + 1 ;

  // season e seasonRound
  MyBrain.Score.Season [0] :=  PDWORD(@buf3[ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.Season [1] :=  PDWORD(@buf3[ cur ])^;
  cur := cur + 4 ;
  MyBrain.Score.SeasonRound [0] :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Score.SeasonRound [1] :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;

    MyBrain.Gender :=  Char( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Minute :=  PWORD(@buf3[ cur ])^;
  cur := cur + 2 ;

MyBrain.fmilliseconds :=  (PWORD(@buf3[ cur ])^ ) * 1000;
  cur := cur + 2 ;
  MyBrain.TeamTurn :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;


  MyBrain.FTeamMovesLeft :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.GameStarted :=  Boolean(  Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.FlagEndGame :=  Boolean(  Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.Finished :=  Boolean(  Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.Shpbuff :=  Boolean(  Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.ShpFree :=    Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.incMove :=    PWORD(@buf3[ cur ])^;
  cur := cur + 2 ;

  // aggiungo la palla

  MyBrain.Ball := Tball.create(MyBrain);
  MyBrain.Ball.CellX :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.Ball.CellY :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;



MyBrain.TeamCorner :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.w_CornerSetup :=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Coa:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Cod:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_CornerKick:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;

  MyBrain.TeamfreeKick :=  Ord( buf3[ cur ]);
  cur := cur + 1 ;
  MyBrain.w_FreeKickSetup1 :=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka1:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick1:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup2 :=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka2:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fkd2:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick2:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup3 :=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka3:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fkd3:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick3:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;

  MyBrain.w_FreeKickSetup4 :=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_Fka4:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;
  MyBrain.w_FreeKick4:=  Boolean( Ord( buf3[ cur ]));
  cur := cur + 1 ;

  lenMatchInfo:=  PWORD(@buf3[Cur] )^; // punta ai 2 byte word che indicano la lunghezza della stringa
  // non carico tsscript
  if lenMatchInfo > 0 then
    MyBrain.MatchInfo.CommaText :=  midStr ( DataStr , Cur +1+2, lenMatchInfo ); //+1 ragiona in base 1  +2 per len della stringa

  cur := Cur + lenMatchInfo + 2;


  totPlayer :=  Ord( buf3[ cur ]);
  Cur := Cur + 1;
  // cursore posizionato sul primo player
  for I := 0 to totPlayer -1 do begin

//    PlayerGuid := StrToInt(spManager.lstSoccerPlayer[i].Ids); // dipende dalla gestione players, se divido per nazioni?
    aIds := IntToStr( PDWORD(@buf3[ cur ])^);
    Cur := Cur + 4;
    aGuidTeam := PDWORD(@buf3[ cur ])^;
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[ cur ]);
    aSurname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;
    aTeam := Ord( buf3[ cur ]);
    Cur := Cur + 1 ;
    aAge :=  Ord( buf3[ cur ]);
    Cur := Cur + 1 ;

    nMatchesplayed := PWORD(@buf3[ cur ])^;
    Cur := Cur + 2 ;
    nMatchesLeft := PWORD(@buf3[ cur ])^;
    Cur := Cur + 2 ;
    TalentID1 := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    TalentID2 := Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aStamina := PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    DefaultSpeed := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultDefense := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultPassing := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultBallControl := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultShot := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultHeading := Ord( buf3[ cur ]);
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
                                 TalentID1, TalentID2  );     // attributes e defaultAttrributes sono uguali
      MyBrain.AddSoccerPlayer(aPlayer);       // lo aggiune per la prima ed unica volta

    aPlayer.Stamina := aStamina;
    aPlayer.TalentId1:= TalentID1;
    aPlayer.TalentId2:= TalentID2;

    aPlayer.Speed := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.Defense := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.Passing := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.BallControl := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.Shot := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.Heading := Ord( buf3[ cur ]);
    Cur := Cur + 1;

    Injured:= Ord( buf3[ cur ]);
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


    aPlayer.YellowCard :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.redcard :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.disqualified :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.gameover :=  Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;

    aPlayer.AIFormationCellX := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.AIFormationCellY  := Ord( buf3[ cur ]);
    Cur := Cur + 1;

    DefaultCellX := Ord( buf3[ cur ]);;
    Cur := Cur + 1;
    DefaultCellY := Ord( buf3[ cur ]);;
    Cur := Cur + 1;
    aPlayer.DefaultCellS :=  Point( DefaultCellX, DefaultCellY); // innesca e setta il role

    aPlayer.CellX := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.CellY := Ord( buf3[ cur ]);
    Cur := Cur + 1;

      (* variabili di gioco *)
    aPlayer.Stay  := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.CanMove  := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.CanSkill := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.CanDribbling := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.PressingDone  := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.BonusTackleTurn  := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusLopBallControlTurn  := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusProtectionTurn  := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.UnderPressureTurn := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusSHPturn := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusSHPAREAturn := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.BonuSPLMturn := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.BonusFinishingTurn:= Ord( buf3[ cur ]);
Cur := Cur + 1;
aPlayer.isCOF := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.isFK1 := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.isFK2 := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.isFK3 := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.isFK4 := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.isFKD3 := Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;
    aPlayer.face := PDWORD(@buf3[ cur ])^;
    Cur := Cur + 4;



  end;

  totReserve :=  Ord( buf3[ cur ]);
  Cur := Cur + 1;
  // cursore posizionato sul primo Reserve
  for I := 0 to totReserve -1 do begin

//    PlayerGuid := StrToInt(aPlayerManager.lstSoccerPlayer[i].Ids); // dipende dalla gestione players, se divido per nazioni?
    aIds := IntToStr( PDWORD(@buf3[ cur ])^);
    Cur := Cur + 4;
    aGuidTeam := PDWORD(@buf3[ cur ])^;
    Cur := Cur + 4;
    lenSurname :=  Ord( buf3[ cur ]);
    aSurname := MidStr( dataStr, cur + 2  , lenSurname );// ragiona in base 1  e l'elemento 0 è la len della stringa quindi + 2
    cur  := cur + lenSurname + 1;
    aTeam := Ord( buf3[ cur ]);
    Cur := Cur + 1 ;
    aAge :=  Ord( buf3[ cur ]);
    Cur := Cur + 1 ;

    nMatchesPlayed := PWORD(@buf3[ cur ])^;
    Cur := Cur + 2 ;
    nMatchesLeft := PWORD(@buf3[ cur ])^;
    Cur := Cur + 2 ;
    TalentID1 := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    TalentID2 := Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aStamina := PWORD(@buf3 [ cur ])^;
    Cur := Cur + 2;

    DefaultSpeed := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultDefense := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultPassing := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultBallControl := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultShot := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    DefaultHeading := Ord( buf3[ cur ]);
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

    aPlayer.Speed := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.Defense := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.Passing := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.BallControl := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.Shot := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.Heading := Ord( buf3[ cur ]);
    Cur := Cur + 1;

    Injured:= Ord( buf3[ cur ]);
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


    aPlayer.YellowCard :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.redcard :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.disqualified :=  Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.gameover :=  Boolean( Ord( buf3[ cur ]));
    Cur := Cur + 1;

    aPlayer.AIFormationCellX := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.AIFormationCellY  := Ord( buf3[ cur ]);
    Cur := Cur + 1;

    DefaultCellX := Ord( buf3[ cur ]);;
    Cur := Cur + 1;
    DefaultCellY := Ord( buf3[ cur ]);;
    Cur := Cur + 1;
    aPlayer.DefaultCellS :=  Point( DefaultCellX, DefaultCellY); // innesca e setta il role

    aPlayer.CellX := Ord( buf3[ cur ]);
    Cur := Cur + 1;
    aPlayer.CellY := Ord( buf3[ cur ]);
    Cur := Cur + 1;

    aPlayer.face := PDWORD(@buf3[ cur ])^;
    Cur := Cur + 4;




  end;

    MM.Free;
    sf.Free;



    MyBrain.Score.AI[0]:=True;
    MyBrain.Score.AI[1]:=True;
    MyBrain.dir_log := dir_log;
    MyBrain.LogUser[0] := 1;
    MyBrain.LogUser[1] := 1;
    MyBrain.SaveData (MyBrain.incMove);//<-- riempe mmbraindata che zippata in mmbraindatazip viene inviata al client
    BrainManager.AddBrain(MyBrain );
    MM.Free;
    sf.Free;



    MyBrain.Score.AI[0]:=True;
    MyBrain.Score.AI[1]:=True;
    MyBrain.dir_log := dir_log;
    MyBrain.LogUser[0] := 1;
    MyBrain.LogUser[1] := 1;
    MyBrain.SaveData (MyBrain.incMove);//<-- riempe mmbraindata che zippata in mmbraindatazip viene inviata al client
    BrainManager.AddBrain(MyBrain );



end;

procedure TFormServer.Button7Click(Sender: TObject);
var
  i: Integer;
  ConnGame : TMyConnection ;
  qPlayers :  TMyQuery;
  ValidPlayer: TValidPlayer;
  alvlUp: TLevelUp;
begin
// cicla per tutti i player del db e prova anche senza punti xp necessari a livellare un talento random
// copia e incolla F e poi M
  debug_trytalentnoxp := True;

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='f_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.Text := 'SELECT * from f_game.players where talentid1 = 0';  // solo chi non ha talento
  qPlayers.Execute ;


  for I := 0 to qPlayers.RecordCount -1 do begin

    ValidPlayer.Age:= Trunc(  qPlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
    ValidPlayer.talentID1 := qPlayers.FieldByName ('talentid1').AsInteger;


    ValidPlayer.talentID2 := qPlayers.FieldByName ('talentid2').AsInteger;
    ValidPlayer.speed :=  qPlayers.FieldByName ('speed').AsInteger;
    ValidPlayer.defense :=  qPlayers.FieldByName ('defense').AsInteger;
    ValidPlayer.passing :=  qPlayers.FieldByName ('passing').AsInteger;
    ValidPlayer.ballcontrol :=  qPlayers.FieldByName ('ballcontrol').AsInteger;
    ValidPlayer.shot :=  qPlayers.FieldByName ('shot').AsInteger;
    ValidPlayer.heading :=  qPlayers.FieldByName ('heading').AsInteger;
    ValidPlayer.history := qPlayers.FieldByName ('history').AsString;
    ValidPlayer.xp := qPlayers.FieldByName ('xp').AsString;

    ValidPlayer.chancelvlUp := qPlayers.FieldByName ('deva').AsInteger;
    ValidPlayer.chancetalentlvlUp :=  qPlayers.FieldByName ('devt').AsInteger;


    alvlUp := pvpTrylevelUpTalent(MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, RndGenerate(NUM_TALENT), ValidPlayer  );
   // if alvlUp.value then
   //   Memo1.Lines.Add('lvlup!');
    ProgressBar1.Position :=  (((i * 100 ) div qPlayers.RecordCount) div 2) ;

    qPlayers.Next;

  end;


  qPlayers.Free;
  Conngame.Connected:= False;
  Conngame.Free;



  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='m_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);

  qPlayers.Connection := ConnGame;   // game


  qPlayers.SQL.Text := 'SELECT * from m_game.players where talentid1 = 0';  // solo chi non ha talento
  qPlayers.Execute ;


  for I := 0 to qPlayers.RecordCount -1 do begin

    ValidPlayer.Age:= Trunc(  qPlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
    ValidPlayer.talentID1 := qPlayers.FieldByName ('talentid1').AsInteger;


    ValidPlayer.talentID2 := qPlayers.FieldByName ('talentid2').AsInteger;
    ValidPlayer.speed :=  qPlayers.FieldByName ('speed').AsInteger;
    ValidPlayer.defense :=  qPlayers.FieldByName ('defense').AsInteger;
    ValidPlayer.passing :=  qPlayers.FieldByName ('passing').AsInteger;
    ValidPlayer.ballcontrol :=  qPlayers.FieldByName ('ballcontrol').AsInteger;
    ValidPlayer.shot :=  qPlayers.FieldByName ('shot').AsInteger;
    ValidPlayer.heading :=  qPlayers.FieldByName ('heading').AsInteger;
    ValidPlayer.history := qPlayers.FieldByName ('history').AsString;
    ValidPlayer.xp := qPlayers.FieldByName ('xp').AsString;

    ValidPlayer.chancelvlUp := qPlayers.FieldByName ('deva').AsInteger;
    ValidPlayer.chancetalentlvlUp :=  qPlayers.FieldByName ('devt').AsInteger;

    alvlUp := pvpTrylevelUpTalent(MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, RndGenerate(NUM_TALENT), ValidPlayer  );
  //  if alvlUp.value then
   //   Memo1.Lines.Add('lvlup!');

    ProgressBar1.Position :=  (i * 100 ) div qPlayers.RecordCount;
    qPlayers.Next;
  end;

  ProgressBar1.Position :=  0;
  qPlayers.Free;
  Conngame.Connected:= False;
  Conngame.Free;

  debug_trytalentnoxp := False;
  ShowMessage ('Done!');

end;

procedure TFormServer.Button8Click(Sender: TObject);
var
  i: Integer;
  ConnGame : TMyConnection ;
  qPlayers :  TMyQuery;
  ValidPlayer: TValidPlayer;
  alvlUp: TLevelUp;
  label retry;
begin
// cicla per tutti i player del db che hanno il talento1 e cerca di ottenere un talent 2
  debug_trytalentnoxp := True;

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='f_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);

  qPlayers.Connection := ConnGame;   // game

  qPlayers.SQL.Text := 'SELECT * from f_game.players where talentid1 <> 0'; // chi ha già il talento1
  qPlayers.Execute ;


  for I := 0 to qPlayers.RecordCount -1 do begin

    ValidPlayer.Age:= Trunc(  qPlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
    ValidPlayer.talentID1 := qPlayers.FieldByName ('talentid1').AsInteger;


    ValidPlayer.talentID2 := qPlayers.FieldByName ('talentid2').AsInteger;
    ValidPlayer.speed :=  qPlayers.FieldByName ('speed').AsInteger;
    ValidPlayer.defense :=  qPlayers.FieldByName ('defense').AsInteger;
    ValidPlayer.passing :=  qPlayers.FieldByName ('passing').AsInteger;
    ValidPlayer.ballcontrol :=  qPlayers.FieldByName ('ballcontrol').AsInteger;
    ValidPlayer.shot :=  qPlayers.FieldByName ('shot').AsInteger;
    ValidPlayer.heading :=  qPlayers.FieldByName ('heading').AsInteger;
    ValidPlayer.history := qPlayers.FieldByName ('history').AsString;
    ValidPlayer.xp := qPlayers.FieldByName ('xp').AsString;

    ValidPlayer.chancelvlUp := qPlayers.FieldByName ('deva').AsInteger;
    ValidPlayer.chancetalentlvlUp :=  qPlayers.FieldByName ('devt').AsInteger;


    alvlUp := pvpTrylevelUpTalent(MySqlServerGame, 'f', qPlayers.FieldByName('guid').AsInteger, ValidPlayer.talentID1 , ValidPlayer  );
   // if alvlUp.value then
   //   Memo1.Lines.Add('lvlup2!');

    ProgressBar1.Position :=  (((i * 100 ) div qPlayers.RecordCount) div 2);
    qPlayers.Next;
  end;


  qPlayers.SQL.Text := 'SELECT * from m_game.players where talentid1 <> 0'; // chi ha già il talento1
  qPlayers.Execute ;

  for I := 0 to qPlayers.RecordCount -1 do begin

    ValidPlayer.Age:= Trunc(  qPlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
    ValidPlayer.talentID1 := qPlayers.FieldByName ('talentid1').AsInteger;


    ValidPlayer.talentID2 := qPlayers.FieldByName ('talentid2').AsInteger;
    ValidPlayer.speed :=  qPlayers.FieldByName ('speed').AsInteger;
    ValidPlayer.defense :=  qPlayers.FieldByName ('defense').AsInteger;
    ValidPlayer.passing :=  qPlayers.FieldByName ('passing').AsInteger;
    ValidPlayer.ballcontrol :=  qPlayers.FieldByName ('ballcontrol').AsInteger;
    ValidPlayer.shot :=  qPlayers.FieldByName ('shot').AsInteger;
    ValidPlayer.heading :=  qPlayers.FieldByName ('heading').AsInteger;
    ValidPlayer.history := qPlayers.FieldByName ('history').AsString;
    ValidPlayer.xp := qPlayers.FieldByName ('xp').AsString;

    ValidPlayer.chancelvlUp := qPlayers.FieldByName ('deva').AsInteger;
    ValidPlayer.chancetalentlvlUp :=  qPlayers.FieldByName ('devt').AsInteger;


    alvlUp:= pvpTrylevelUpTalent(MySqlServerGame, 'm', qPlayers.FieldByName('guid').AsInteger, ValidPlayer.talentID1 , ValidPlayer  );
  //  if alvlUp.value then
   //   Memo1.Lines.Add('lvlup2!');

    ProgressBar1.Position :=  ((i * 100 ) div qPlayers.RecordCount);
    qPlayers.Next;
  end;


  ProgressBar1.Position :=  0;
  qPlayers.Free;
  Conngame.Connected:= False;
  Conngame.Free;
  debug_trytalentnoxp := False;
  ShowMessage ('Done!');


end;



 // Possibili combinazioni talenti
//  TALENT_ID_GOALKEEPER     = 1;  // può giocare in porta

//  TALENT_ID_CHALLENGE      = 2;  // lottatore + 1 autotackle    note: +TALENT_ID_TOUGHNESS      = 3;  // +1 tackle          --> ruba sempre palla
//  TALENT_ID_CHALLENGE      = 2;  // lottatore + 1 autotackle    note: +TALENT_ID_POWER          = 4;  // +1 resist tackle   --> da centrocampo puro
//  TALENT_ID_CHALLENGE      = 2;  // lottatore + 1 autotackle   note:  +TALENT_ID_MARKING        = 15; // ottima combo  DIF=Marca l'attaccante con il Tiro piu' alto. Cen=Marca il Centrocampista con il passaggio piu' alto. ATT=Marca il difensore con il Controllo piu' basso.
// + mastino  e ralativi mirror

//  TALENT_ID_TOUGHNESS      = 3;  // +1 tackle
//  TALENT_ID_POWER          = 4;  // +1 resist tackle
//  TALENT_ID_CROSSING       = 5;  // +1 crossing


//  TALENT_ID_LONGPASS       = 6;  // +1 distanza passaggi      note  TALENT_ID_PLAYMAKER = 13; // vero playmaker per lanci lunghi. + agility fa passaggi corti più lunghi che non possono essere fermati
//  TALENT_ID_EXPERIENCE     = 7;  // pressing non costa mosse

//  TALENT_ID_DRIBBLING      = 8;  // +1 dribbling             note      TALENT_ID_BOMB           = 12;  // cpmbo dribbling+tiro!


//  TALENT_ID_BULLDOG        = 9;  // mastino +1 intercept

//  TALENT_ID_OFFENSIVE      = 10; // durante ai_moveall tende ad attaccare  TALENT_ID_POSITIONING    = 16; si allarga o stringe
      // incompatibile con  TALENT_ID_DEFENSIVE  TALENT_ID_MARKING  TALENT_ID_PLAYMAKER TALENT_ID_AGGRESSION

//  TALENT_ID_DEFENSIVE      = 11; // durante ai_moveall tende ad attaccare  TALENT_ID_POSITIONING    = 16; si allarga o stringe
      // incompatibile con  TALENT_ID_OFFENSIVE  TALENT_ID_MARKING  TALENT_ID_PLAYMAKER TALENT_ID_AGGRESSION

//  TALENT_ID_PLAYMAKER      = 13; // Cerca di avvicinarsi al proprio portatore di palla. Inoltre i suoi passaggi corti terminanti in area avversaria conferiscono un bonus al ricevente.
      // incompatibile con  TALENT_ID_OFFENSIVE  TALENT_ID_MARKING  TALENT_ID_DEFENSIVE  TALENT_ID_POSITIONING TALENT_ID_AGGRESSION

//  TALENT_ID_MARKING        = 15; // DIF=Marca l'attaccante con il Tiro piu' alto. Cen=Marca il Centrocampista con il passaggio piu' alto. ATT=Marca il difensore con il Controllo piu' basso.
      // incompatibile con  TALENT_ID_OFFENSIVE  TALENT_ID_PLAYMAKER  TALENT_ID_DEFENSIVE  TALENT_ID_POSITIONING  TALENT_ID_AGGRESSION

//   TALENT_ID_POSITIONING    = 16; // Cerca di tornare verso la propria zona di campo. talent2 offensive=ala o centravanti talent2 defensive=chiude le fascie o il centro
      // incompatibile con    TALENT_ID_PLAYMAKER TALENT_ID_MARKING  TALENT_ID_AGGRESSION

//  TALENT_ID_BOMB           = 12; //  TALENT_ID_BOMB ( +1 Shot quando vince un tackle, riceve un short.passing da un player con talento PLAYMAKER in area avversaria,
//                                 corre con la palla per lameno 2 cella o vince un dribling.

//   TALENT_ID_FAUL           = 14; // +15% chance di commettere un fallo. -30% cartellino.


//   TALENT_ID_FREEKICKS      = 17; // +1 Tiro sui Calci di punizione.
//   TALENT_ID_AGILITY        = 18; // Quando riceve un passaggio corto distante almeno 2 celle, non costa mosse. }
//   TALENT_ID_RAPIDPASSING   = 19; // Ha il 33% chance di effettuare un passaggio verso un compagno. non può essere intercettato

//   TALENT_ID_AGGRESSION     = 20; // cerca il portatore di palla
      // incompatibile con  TALENT_ID_OFFENSIVE  TALENT_ID_PLAYMAKER  TALENT_ID_DEFENSIVE  TALENT_ID_POSITIONING  TALENT_ID_MARKING

//   TALENT_ID_ACE            = 21; // Ha il 33% chance di effettuare un dribbling vincente quando subisce pressing
//const TALENT_ID_HEADING        = 22; // Ha una chance del 5% di ottenere +1 durante i colpi di testa.
//const TALENT_ID_FINISHING      = 23; // Quando ottiene la palla dopo un rimbalzo ha +1 Tiro.
//const TALENT_ID_DIVING         = 24; // +10% chance di subire un fallo durante i tackle.

//   Talent2
     // done. TALENT_ID_ADVANCED_CHALLENGE = 128 // prereq difesa 3 TALENT_ID_CHALLENGE  --> 5% chance +1 autotackle
     // done. TALENT_ID_ADVANCED_TOUGHNESS = 129 // prereq difesa 3 TALENT_ID_TOUGHNESS  --> 5% chance +1 tackle
     // done. TALENT_ID_ADVANCED_POWER = 130    // prereq ballcontrol 3 TALENT_ID_POWER  --> 5% chance +1 resist every tackle
     // TALENT_ID_ADVANCED_CROSSING = 131 // prereq TALENT_ID_CROSSING  -->  5% chance +2 crossing
     // TALENT_ID_ADVANCED_LONGPASS . no talent 2
     // TALENT_ID_ADVANCED_EXPERIENCE = 132 // prereq TALENT_ID_EXPERIENCE  --> pressing costa cost_pre - 1
     // TALENT_ID_ADVANCED_DRIBBLING = 133 // prereq TALENT_ID_DRIBBLING --> +2 totale dribbling  . strutture alzano questa chance
     // TALENT_ID_ADVANCED_BULLDOG    = 134;  // prereq TALENT_ID_BULLDOG mastino +2 intercept
     // TALENT_ID_OFFENSIVE . no talent 2
     // TALENT_ID_DEFENSIVE . no talent 2
     // TALENT_ID_PLAYMAKER . no talent 2
     // TALENT_ID_ADVANCED_AGGRESSION = 135 // prereq TALENT_ID_MARKING fa pressing automatico sul portatore di palla se lo raggiunge. 25% chance.
     // TALENT_ID_ADVANCED_BOMB          = 136 //  prereq tiro 3 talent bomb --> 5% chance che si attivi da solo tiro +2 su powershot, non precision.shot
     // TALENT_ID_FAUL2 . no talent 2
     // TALENT_ID_POSITIONING2 . no talent 2
     // TALENT_ID_FREEKICKS2 . no talent 2
     // TALENT_ID_AGILITY2 . no talent 2
     // TALENT_ID_RAPIDPASSING2   = 19; // no talent 2
     // TALENT_ID_AGGRESSION2     = 20; // no talent 2
     // TALENT_ID_ACE2            = 21; // no talent 2

     // ecc... tutti i rank 2 di solito a base 5% che potranno

     // TALENT_ID_PRECISE_CROSSING = 137 // prereq  TALENT_ID_CROSSING  --> +1 crossing dal fondo
    //  TALENT_ID_SUPER_DRIBBLING = 138 // prereq talent dribbling --> dribbling +3 chance 15%  ( dribbling2 è +1 fisso )

    // buff reparto. la skill o il tentativo di skill costa 1 mossa del turno.

    // TALENT_ID_BUFF_DEFENSE = 139 prereq almeno 3 Defense, 1 talento qualsiasi --> skill 2x buff reparto (5% chance) dif 20 turni + def,ballcontrol,passing +1
   //  TALENT_ID_BUFF_MIDDLE = 140 prereq almeno 3 passing, 1 talento qualsiasi --> skill 2x buff reparto (5% chance) cen  20 turni + speed max 4,ballcontrol,passing, shot +1
   //  TALENT_ID_BUFF_FORWARD = 141 prereq almeno 3 Shot , 1 talento qualsiasi --> skill 2x buff reparto (5% chance) att 20 turni + ballcontrol,passing, shot +1


    // TALENT_ID_GKMIRACLE = 250 solo GK  5% chance di fare un miracolo : + 1 defense sui tiri precisi.
    // TALENT_ID_GKPENALTY = 251 specialista para rigori. ottiene +1 10% chance .

procedure TFormServer.Button9Click(Sender: TObject);
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  for I := brainManager.lstBrain.Count -1 downto 0 do  begin
    if (brainManager.lstBrain[i].Score.TeamGuid[0] <> StrToInt(Edit7.Text) ) and (brainManager.lstBrain[i].Score.TeamGuid[1] <> StrToInt(Edit8.Text)) then
    brainManager.lstBrain[i].Paused := True;
  end;
  ReleaseMutex(Mutex);

end;

procedure TFormServer.Button11Click(Sender: TObject);
var
  i,aRnd: Integer;
  ConnGame : TMyConnection ;
  qPlayers :  TMyQuery;
  ValidPlayer: TValidPlayer;
  alvlUp: TLevelUp;
  tsXP : TStringList;
begin
// cicla per tutti i player del db e prova , se ci sono gli xp necessari a livellare un attributo disponibile. checkdefense/shot
// copia e incolla F e poi M

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='f_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qPlayers.SQL.Text := 'SELECT * from f_game.players';
  qPlayers.Execute ;


  for I := 0 to qPlayers.RecordCount -1 do begin

    ValidPlayer.Age:= Trunc(  qPlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
    ValidPlayer.talentID1 := qPlayers.FieldByName ('talentid1').AsInteger;


    ValidPlayer.talentID2 := qPlayers.FieldByName ('talentid2').AsInteger;
    ValidPlayer.speed :=  qPlayers.FieldByName ('speed').AsInteger;
    ValidPlayer.defense :=  qPlayers.FieldByName ('defense').AsInteger;
    ValidPlayer.passing :=  qPlayers.FieldByName ('passing').AsInteger;
    ValidPlayer.ballcontrol :=  qPlayers.FieldByName ('ballcontrol').AsInteger;
    ValidPlayer.shot :=  qPlayers.FieldByName ('shot').AsInteger;
    ValidPlayer.heading :=  qPlayers.FieldByName ('heading').AsInteger;
    ValidPlayer.history := qPlayers.FieldByName ('history').AsString;
    ValidPlayer.xp := qPlayers.FieldByName ('xp').AsString;

    ValidPlayer.chancelvlUp := qPlayers.FieldByName ('deva').AsInteger;
    ValidPlayer.chancetalentlvlUp :=  qPlayers.FieldByName ('devt').AsInteger;

    tsXP := TStringList.Create;
    tsXP.commaText := ValidPlayer.xp; // <-- init importante 18 talenti
    // rispettare esatto ordine
    ValidPlayer.xp_Speed         := StrToInt( tsXP[0]);
    ValidPlayer.xp_Defense       := StrToInt( tsXP[1]);
    ValidPlayer.xp_Passing       := StrToInt( tsXP[2]);
    ValidPlayer.xp_BallControl   := StrToInt( tsXP[3]);
    ValidPlayer.xp_Shot          := StrToInt( tsXP[4]);
    ValidPlayer.xp_Heading       := StrToInt( tsXP[5]);

    // da qui in poi la function non passa dal validate. le richieste errate vengono semplicemente scartate con MyExit
    if ValidPlayer.xp_Speed >= xp_SPEED_POINTS then
      alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, 0, ValidPlayer  );
    if ValidPlayer.xp_Passing >= xp_PASSING_POINTS then
      alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, 2, ValidPlayer  );
    if ValidPlayer.xp_BallControl >= xp_BALLCONTROL_POINTS then
      alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, 3, ValidPlayer  );
    if ValidPlayer.xp_Heading >= xp_HEADING_POINTS then
      alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, 5, ValidPlayer  );

    // per defense e shot scelgo chi è già in vantaggio, altrimenti random
    if ValidPlayer.shot >  ValidPlayer.defense then begin
      if ValidPlayer.xp_Shot >= xp_SHOT_POINTS then
        alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, 4, ValidPlayer  );

    end
    else if ValidPlayer.shot <  ValidPlayer.defense then begin
      if ValidPlayer.xp_Defense >= xp_DEFENSE_POINTS then
        alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, 1, ValidPlayer  );

    end
    else if ValidPlayer.shot =  ValidPlayer.defense then begin
      aRnd := rndgenerate (100);
      if aRnd <= 50 then begin
      if ValidPlayer.xp_Defense >= xp_DEFENSE_POINTS then
        alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, 1, ValidPlayer  );
      end
      else begin
      if ValidPlayer.xp_Shot >= xp_SHOT_POINTS then
        alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'f', qPlayers.FieldByName('guid').AsInteger, 4, ValidPlayer  );

      end;
    end;


    tsXP.free;
   // if alvlUp.value then

   //   Memo1.Lines.Add('lvlup!');
    ProgressBar1.Position :=  (((i * 100 ) div qPlayers.RecordCount) div 2) ;

    qPlayers.Next;

  end;


  qPlayers.Free;
  Conngame.Connected:= False;
  Conngame.Free;



  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:='m_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);

  qPlayers.Connection := ConnGame;   // game


  qPlayers.SQL.Text := 'SELECT * from m_game.players';
  qPlayers.Execute ;


  for I := 0 to qPlayers.RecordCount -1 do begin

    ValidPlayer.Age:= Trunc(  qPlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
    ValidPlayer.talentID1 := qPlayers.FieldByName ('talentid1').AsInteger;


    ValidPlayer.talentID2 := qPlayers.FieldByName ('talentid2').AsInteger;
    ValidPlayer.speed :=  qPlayers.FieldByName ('speed').AsInteger;
    ValidPlayer.defense :=  qPlayers.FieldByName ('defense').AsInteger;
    ValidPlayer.passing :=  qPlayers.FieldByName ('passing').AsInteger;
    ValidPlayer.ballcontrol :=  qPlayers.FieldByName ('ballcontrol').AsInteger;
    ValidPlayer.shot :=  qPlayers.FieldByName ('shot').AsInteger;
    ValidPlayer.heading :=  qPlayers.FieldByName ('heading').AsInteger;
    ValidPlayer.history := qPlayers.FieldByName ('history').AsString;
    ValidPlayer.xp := qPlayers.FieldByName ('xp').AsString;

    ValidPlayer.chancelvlUp := qPlayers.FieldByName ('deva').AsInteger;
    ValidPlayer.chancetalentlvlUp :=  qPlayers.FieldByName ('devt').AsInteger;

    tsXP := TStringList.Create;
    tsXP.commaText := ValidPlayer.xp; // <-- init importante 18 talenti
    // rispettare esatto ordine
    ValidPlayer.xp_Speed         := StrToInt( tsXP[0]);
    ValidPlayer.xp_Defense       := StrToInt( tsXP[1]);
    ValidPlayer.xp_Passing       := StrToInt( tsXP[2]);
    ValidPlayer.xp_BallControl   := StrToInt( tsXP[3]);
    ValidPlayer.xp_Shot          := StrToInt( tsXP[4]);
    ValidPlayer.xp_Heading       := StrToInt( tsXP[5]);

    // da qui in poi la function non passa dal validate. le richieste errate vengono semplicemente scartate con MyExit
    if ValidPlayer.xp_Speed >= xp_SPEED_POINTS then
      alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, 0, ValidPlayer  );
    if ValidPlayer.xp_Passing >= xp_PASSING_POINTS then
      alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, 2, ValidPlayer  );
    if ValidPlayer.xp_BallControl >= xp_BALLCONTROL_POINTS then
      alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, 3, ValidPlayer  );
    if ValidPlayer.xp_Heading >= xp_HEADING_POINTS then
      alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, 5, ValidPlayer  );

    // per defense e shot scelgo chi è già in vantaggio, altrimenti random
    if ValidPlayer.shot >  ValidPlayer.defense then begin
      if ValidPlayer.xp_Shot >= xp_SHOT_POINTS then
        alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, 4, ValidPlayer  );

    end
    else if ValidPlayer.shot <  ValidPlayer.defense then begin
      if ValidPlayer.xp_Defense >= xp_DEFENSE_POINTS then
        alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, 1, ValidPlayer  );

    end
    else if ValidPlayer.shot =  ValidPlayer.defense then begin
      aRnd := rndgenerate (100);
      if aRnd <= 50 then begin
      if ValidPlayer.xp_Defense >= xp_DEFENSE_POINTS then
        alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, 1, ValidPlayer  );
      end
      else begin
      if ValidPlayer.xp_Shot >= xp_SHOT_POINTS then
        alvlUp := pvpTrylevelUpAttribute (MySqlServerGame,'m', qPlayers.FieldByName('guid').AsInteger, 4, ValidPlayer  );

      end;
    end;


    tsXP.free;

  //  if alvlUp.value then
   //   Memo1.Lines.Add('lvlup!');

    ProgressBar1.Position :=  (i * 100 ) div qPlayers.RecordCount;
    qPlayers.Next;
  end;

  ProgressBar1.Position :=  0;
  qPlayers.Free;
  Conngame.Connected:= False;
  Conngame.Free;

  ShowMessage ('Done!');
end;

procedure TFormServer.Button12Click(Sender: TObject);
var
  ConnGame : TMyConnection ;
  qPlayers,qMarket: TMyQuery ;
begin

  ConnGame := TMyConnection.Create(nil);
  Conngame.Server := MySqlServerGame;
  Conngame.Username:='root';
  Conngame.Password:='root';
  Conngame.Database:= 'f_game';
  Conngame.Connected := True;

  qPlayers := TMyQuery.Create(nil);
  qPlayers.Connection := ConnGame;   // game
  qMarket := TMyQuery.Create(nil);
  qMarket.Connection := ConnGame;   // game

  qPlayers.SQL.text := 'UPDATE f_game.players SET onmarket =0' ;
  qPlayers.Execute ;

  qPlayers.SQL.text := 'UPDATE m_game.players SET onmarket =0' ;
  qPlayers.Execute ;

  qMarket.SQL.text := 'DELETE from f_game.market' ;
  qMarket.Execute ;

  qMarket.SQL.text := 'DELETE from m_game.market' ;
  qMarket.Execute ;
  qPlayers.Free;
  qMarket.Free;


  Conngame.Connected := False;
  Conngame.Free;

  ShowMessage ('Done!');

end;



end.
