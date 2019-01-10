unit Server;
// routine principali:
// procedure TcpserverDataAvailable <-- tutti gli input del client passano da qui
// procedure QueueThreadTimer <-- crea le partite(brain) in base agli utenti in coda di attesa
// procedure MatchThreadTimer <-- in caso di bot o disconessione, esegue l'intelligenza artificiale TSoccerBrain.AI_think
// procedure CreateAndLoadMatch <-- crea una partita (brain)

{$DEFINE BOTS}     // se uso i bot o solo partite di player reali
{$DEFINE useMemo}  // se uso il debug a video delle informazioni importanti
interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.Hash , DateUtils, ZLIBEX,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Strutils,generics.collections, generics.defaults, Data.DB,
  Vcl.ExtCtrls, Vcl.Mask, Vcl.Grids, inifiles,

  Soccerbrainv3,

  DSE_SearchFiles,
  DSE_Random,
  DSE_ThreadTimer,
  DSE_theater,
  DSE_GRID,

  MyAccess, DBAccess,

  OverbyteIcsWndControl, OverbyteIcsWSocket, OverbyteIcsWSocketS, OverbyteIcsWSocketTS;


type
  TTheArray = array[-4..-1, 0..6] of string;    // le celle a sinistra della porta dove vengono posizionate le riserve

type TAuthInfo = record                         // usato durante il login in TFormServer.TcpserverDataAvailable
  GmLevel: Integer;                             // gm=1 il client pu� mandare comandi di utilit� come spostare manualmente la palla
  Account: Integer;                             // DB realmd.account.id
  AccountStatus : Integer;                      // 0=login errore, 1=ok login, ma ancora senza team--> selezione team, 2=tutto ok
  GuidTeam: Integer;                            // DB game.teams.guid
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
type TFinalFormation = record
  Guid : String;
  Cells: TPoint;
  Stamina: Integer;
  Role: string;
end;
  type TAttributeName = ( atSpeed , atDefense, atBallControl, atPassing, atShot, atHeading);
  type TLevelUp = record
    ids : string;
    attrortalentid: string;
    value: boolean;
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
    procedure calc_injured (aPlayer: TSoccerPlayer);
    procedure calc_xp (aPlayer: TSoccerPlayer);
      function RndGenerate( Upper: integer ): integer;
      function RndGenerate0( Upper: integer ): integer;
      function RndGenerateRange( Lower, Upper: integer ): integer;
        procedure can6 (aPlayer: TSoccerPlayer; at : TAttributeName);


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
    SE_GridLiveMatches: SE_Grid;
    CheckBoxActiveMacthes: TCheckBox;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    edit4: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;

    procedure FormCreate(Sender: TObject);
      procedure CleanDirectory(dir:string);
    procedure FormDestroy(Sender: TObject);

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
    function CreateGameTeam ( cli: TWSocketThrdClient;  WorldTeamGuid: string): Integer;


    function GetQueueOpponent ( WorldTeam : integer; Rank, NextHA: byte ): TWSocketThrdClient;
    procedure GetGuidTeamOpponentBOT ( WorldTeam : integer; Rank, NextHA: byte; var BotGuidTeam: Integer; var BotUserName: string );
    function GetTCPClient ( CliId: integer): TWSocketClient;
    function GetTCPClientQueue ( CliId: integer): TWSocketClient;
    procedure QueueThreadTimer(Sender: TObject);
      function GetbrainIds ( GuidTeam0, GuidTeam1: string ) : string;
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
  private
    { Private declarations }
    procedure Display(Msg : String);

    (* validazione input dal client di gioco*)
    procedure validate_login ( const CommaText: string; Cli:TWSocketThrdClient );
      function LastIncMoveIni ( directory: string ): string;
    procedure validate_getteamsbycountry ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_clientcreateteam  ( const CommaText: string;  Cli:TWSocketThrdClient) ;
    procedure validate_viewMatch  ( const CommaText: string;  Cli:TWSocketThrdClient) ;
    procedure validate_levelup ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMDlop ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD4 ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD3 ( const CommaText: string; Cli:TWSocketThrdClient );
    procedure validate_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient );
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
    procedure validate_player ( const guid: integer; Cli:TWSocketThrdClient; var s,d,p,b,sh,h, disqualified, chancelvlUp, chancetalentlvlUp,talentID,age: integer;var history,xp:string );
    procedure validate_sell ( commatext: string; Cli:TWSocketThrdClient  );
    procedure validate_cancelsell ( commatext: string; Cli:TWSocketThrdClient  );
    procedure validate_buy ( commatext: string; Cli:TWSocketThrdClient  );
    procedure validate_market ( commatext: string; Cli:TWSocketThrdClient  );
    procedure validate_dismiss ( commatext: string; Cli:TWSocketThrdClient  );
    procedure reset_formation ( Cli:TWSocketThrdClient );

    function checkformation ( Cli:TWSocketThrdClient ): Boolean;
    procedure store_formation (  CommaText: string );
    procedure store_Uniform ( Guidteam: integer; CommaText: string );


    // mercato player
    procedure MarketSell ( Cli: TWSocketThrdClient; CommaText: string  );
    procedure MarketCancelSell ( Cli: TWSocketThrdClient; CommaText: string  );
    procedure DismissPlayer ( Cli: TWSocketThrdClient; CommaText: string  );
    procedure MarketBuy ( Cli: TWSocketThrdClient; CommaText: string  );
    function GetMarketValueTeam ( Guidteam: Integer ) : Integer;

    function RandomPassword(PLen: Integer): string; // deprecated
    function RndGenerate( Upper: integer ): integer;
    function RndGenerate0( Upper: integer ): integer;
    function RndGenerateRange( Lower, Upper: integer ): integer;


    function inQueue(Cliid: integer ): Boolean;
    function inSpectator(Cliid: integer ): Boolean;
    function inLiveMatchCliid(Cliid: integer ): Boolean;
    function inLivematchGuidTeam(GuidTeam: integer ): TSoccerBrain;

    procedure CreateAndLoadMatch (  brain: TSoccerBrain; GuidTeam0, GuidTeam1: integer; Username0, UserName1: string  );
    procedure CreateMatchBOTvsBOT (   GuidTeam0, GuidTeam1: integer; Username0, UserName1: string );
    procedure CreateFormationTeam ( Guidteam: integer ); // la elabora e la stora nel db
      function NextReserveSlot ( ReserveSlot: TTheArray ) : Tpoint;// per il create_formation e reset_formation. il brain ha il proprio reservesl�ot t,x,y
      procedure CleanReserveSlot ( ReserveSlot: TTheArray );
    procedure CreateFormationsPreset;

    procedure CreateRandomBotMatch;


  public

    procedure SetupRefreshGrid;
    (* procedure che si attivano solo al primo login o comunque se l'account non ha ancora scelto la sua squadra del cuore *)
    procedure PrepareWorldCountries ( directory: string ); overload;
    procedure PrepareWorldCountries ; overload;
    procedure PrepareWorldTeams( directory, CountryID: string );overload;
    procedure PrepareNationTeams( CountryID: integer; var TsNationTeam: TStringList  );
    procedure PrepareWorldTeams( CountryID: integer ); overload;


    function GetTeamStream ( GuidTeam: Integer): string; // dati compressi del proprio team
    function GetListActiveBrainStream: string;
    function GetMarketPlayers ( Myteam, Maxvalue: Integer): string;
    function TrylevelUp ( ids, attrortalentid: string; s,d,p,b,sh,h,  chanceA,chanceT,talentID,Age: integer; history,xp:string ): TLevelUp;
      function can6 (aPlayer: TSoccerPlayer; at : TAttributeName): boolean;

      function isReserveSlot (CellX, CellY: integer): boolean;
  end;

const EndofLine = 'ENDSOCCER';
const GLOBAL_COOLDOWN = 200;  // 200 misslisecondi tra un input e l'altro del client, altrimenti � spam/cheating
const FaceCount = 19;
var
  FormServer: TFormServer;
  BrainManager: TBrainManager;
  TsWorldCountries: TStringList;
  TsWorldTeams: array [1..5] of TStringList; // le nazioni del DB world

  tsTalents: TStringList;
  Queue: TObjectList<TWSocketThrdClient>;
  RandGen: TtdBasePRNG;
  FormationsPreset: TList<TFormation>;
  Mutex: cardinal;
  dir_log: string;
  MySqlServerGame,  MySqlServerWorld,  MySqlServerAccount: string; // le 3 tabelle del DB: account, world e Game
                                                                   // world contiene le definizioni come i nomi delle squadre e i cognomi dei player

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
//  WaitForSingleObject(Mutex,INFINITE);
  for I := brainManager.lstBrain.Count -1 downto 0 do begin
    brainManager.RemoveBrain ( BrainManager.lstBrain[i].BrainIDS );
  end;
//  ReleaseMutex(Mutex);

end;

procedure TFormServer.SetupRefreshGrid;
var
  i,y: Integer;
begin


  SE_GridLiveMatches.ClearData;   // importante anche pr memoryleak
  SE_GridLiveMatches.DefaultColWidth := 16;
  SE_GridLiveMatches.DefaultRowHeight := 16;
  SE_GridLiveMatches.ColCount := 7;
  SE_GridLiveMatches.RowCount := BrainManager.lstBrain.Count + 1; // header
  SE_GridLiveMatches.Columns[0].Width := 220;
  SE_GridLiveMatches.Columns[1].Width := 220;
  SE_GridLiveMatches.Columns[2].Width := 50;
  SE_GridLiveMatches.Columns[3].Width := 50;
  SE_GridLiveMatches.Columns[4].Width := 60;
  SE_GridLiveMatches.Columns[5].Width := 60;
  SE_GridLiveMatches.Columns[6].Width := 50;
  SE_GridLiveMatches.Width := SE_GridLiveMatches.VirtualWidth;


  for y := 0 to SE_GridLiveMatches.RowCount -1 do begin
    SE_GridLiveMatches.Rows[y].Height := 16;
    SE_GridLiveMatches.Cells[0,y].FontColor := clWhite;
    SE_GridLiveMatches.Cells[1,y].FontColor  := clWhite;
    SE_GridLiveMatches.Cells[2,y].FontColor  := clWhite;
    SE_GridLiveMatches.Cells[2,y].CellAlignmentH := hCenter;
    SE_GridLiveMatches.Cells[3,y].FontColor  := clWhite;
    SE_GridLiveMatches.Cells[3,y].CellAlignmentH := hCenter;
    SE_GridLiveMatches.Cells[4,y].FontColor  := clWhite;
    SE_GridLiveMatches.Cells[4,y].CellAlignmentH := hCenter;
    SE_GridLiveMatches.Cells[5,y].FontColor  := clWhite;
    SE_GridLiveMatches.Cells[5,y].CellAlignmentH := hCenter;
    SE_GridLiveMatches.Cells[6,y].FontColor  := clWhite;
    SE_GridLiveMatches.Cells[6,y].CellAlignmentH := hCenter;
  end;

  SE_GridLiveMatches.Cells[0,0].Text := 'Guid/Team/Account0';
  SE_GridLiveMatches.Cells[1,0].Text := 'Guid/Team/Account1';
  SE_GridLiveMatches.Cells[2,0].Text := 'Turn';
  SE_GridLiveMatches.Cells[3,0].Text := 'Seconds';
  SE_GridLiveMatches.Cells[4,0].Text := 'AI0';
  SE_GridLiveMatches.Cells[5,0].Text := 'AI1';
  SE_GridLiveMatches.Cells[6,0].Text := 'Minute';


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

procedure TFormServer.Button1Click(Sender: TObject);
var
  MyQueryAccount,MyQueryWT: TMyQuery;
  sha_pass_hash: string;
  i,arnd: Integer;
  UserName,password, THEWORLDTEAM : string;
  cli: TWSocketThrdClient;
  ConnAccount : TMyConnection;
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
  for I := 1 to 100 do begin

    username :=  Uppercase('TEST' + IntTostr(i));
    password := UserName;
    sha_pass_hash := GetStrHashSHA1 ( username + ':' + Password );
    MyQueryAccount.SQL.Text := 'insert into realmd.account (username, sha_pass_hash, email)  values (' +
                                 '"' + username + '","' +  sha_pass_hash  + '","' +  UserName +'.GMAIL.COM")';

    MyQueryAccount.Execute;

  end;

    MyQueryAccount.free;
    ConnAccount.Connected:= False;
    ConnAccount.Free;


end;

Function TFormServer.CheckAuth ( UserName, Password: string): TAuthInfo;
var
  MyQueryAccount,MyQueryTeam: TMyQuery;
  sha_pass_hash: string;
  AccountID: string;
  GmLevel: Integer;
  ConnAccount,ConnGame : TMyConnection;
begin
  sha_pass_hash := GetStrHashSHA1 ( Uppercase(UserName) + ':' + Uppercase(Password));
  ConnAccount := TMyConnection.Create(nil);
  ConnAccount.Server := MySqlServerAccount;
  ConnAccount.Username:='root';
  ConnAccount.Password:='root';
  ConnAccount.Database:='realmd';
  ConnAccount.Connected := True;

  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

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

    MyQueryTeam.SQL.Text := 'SELECT  guid, worldteam, teamname, nextha, mi FROM game.teams where account = ' + AccountID ;  // teamid punta a world.team (e country in join)
    MyQueryTeam.Execute;
    if MyQueryTeam.RecordCount = 1 then begin       // ho gi� il team
      Result.Account := StrToInt(AccountId);
      Result.AccountStatus  := 2;
      Result.GuidTeam  := MyQueryTeam.FieldByName ('guid').AsInteger ;
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
      Result.GuidTeam  := 0;
      Result.Password := Password;
      Result.username  := MyQueryAccount.FieldByName ('username').AsString ;
      Result.flags  := MyQueryAccount.FieldByName ('flags').AsInteger ;
      Result.GmLevel := GmLevel;
    end;
    MyQueryTeam.Free;
  end
  else if MyQueryAccount.RecordCount = 0 then begin   // login incorrect
      Result.Account := 0;
      Result.GuidTeam := 0;
      Result.AccountStatus := 0;
      Result.Password := '';
      Result.username  := '';
      Result.GmLevel := 0;
  end;

  MyQueryAccount.Free;
  ConnAccount.Connected:= False;
  ConnAccount.Free;
  ConnGame.Connected:= False;
  ConnGame.Free;

end;

constructor TBrainManager.Create( Server: TWSocketThrdServer );
begin
  lstBrain:= TObjectList<TSoccerBrain>.Create(true);
end;
destructor TBrainManager.Destroy;
begin
  lstbrain.free;
  inherited;
end;

procedure TBrainManager.input ( brain: TSoccerBrain; data: string );
var
  i,ii,SpectatorCliId: Integer;
  NewData: string;
  MyQueryCheat: TMyQuery;
  tmp: Integer;
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
          MyQueryCheat.SQL.Text := ' INSERT into cheat_detected (reason,minute,brainids) values ("' + data + '","' +
                                     IntToStr(brain.Minute )+'","' + brain.brainIds +'")'  ;
          MyQueryCheat.Execute ;
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
              NewData := 'BEGINBRAIN' + Chr( StrToInt(data)  ) + GetBrainStream ( brain );
              FormServer.TcpServer.Client [i].SendStr ( NewData + EndofLine);
              FormServer.Memo1.Lines.Add( '> BEGINBRAIN ' +IntToStr(brain.incMove)  );
          end
          else if FormServer.TcpServer.Client [i].CliId = brain.Score.CliId [1] then begin
              NewData := 'BEGINBRAIN' + Chr( StrToInt(data)  ) + GetBrainStream ( brain );
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
              NewData := 'BEGINBRAIN' + Chr( StrToInt(data)  ) + GetBrainStream ( brain );
                FormServer.TcpServer.Client [ii].SendStr ( NewData + EndofLine);
              end;

            end;
        end;
      except
          on E: Exception do Begin
          //  brain.RemoveSpectator  ( TcpServer.Client [ii].CliId ); { TODO -cverifica : sar� dura debuggare qui }
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

// cos� lo creo:
//    BrainIDS:= IntToStr(myYear)  + Format('%.*d',[2, myMonth]) + Format('%.*d',[2, myDay]) + '_' +
//    Format('%.*d',[2, myHour])  + '.' + Format('%.*d',[2, myMin]) + '.' +  Format('%.*d',[2, mySec])+  '_' +
//    GuidTeam0  + '.' + GuidTeam1  ;
  MyYear := LeftStr(  brainIds, 4 );
  myMonth := MidStr(  brainIds, 5, 2 );
  myDay := MidStr(  brainIds, 7, 2 );
  myHour := MidStr(  brainIds, 10, 2 ); // a 9 _
  myMin := MidStr(  brainIds, 13, 2 ); // a 12 .
  mySec := MidStr(  brainIds, 16, 2 ); // a 15 .

end;
procedure TBrainManager.FinalizeBrain ( brain: TSoccerBrain);
var
  i,T,tmp,p,aGuidTeam,matches_Played,matches_Left, disqualified, injured,TotYellowCard,aRnd,newStamina,MatchesplayedTeam,Points: Integer;
  TextHistory,TextXP: string;
  MyQueryGameTeams,MyQueryGamePlayers, MyQueryUpdate, MyQueryArchive: TMyQuery;
  aPlayer: TSoccerPlayer;
  tsXP, tsHistory: TStringList;
  TotMarketValue: array [0..1] of Integer;
  myYear, myMonth, myDay, myHour, myMin, mySec : string;
  ConnGame : TMyConnection;
begin
    // adesso il match + finito
    // XP nell'esatto ordine + match_played ecc...
{    xp_Speed: integer;
    xp_Defense: integer;
    xp_BallControl: integer;
    xp_Passing: integer;
    xp_Shot: integer;
    xp_Heading: integer;

    xpTal_GoalKeeper: integer;
    xpTal_Challenge: integer;  // lottatore
    xpTal_Toughness: integer;
    xpTal_Power : integer;   // toughness
    xpTal_Crossing : integer;
    xptal_longpass: integer;  // solo distanza
    xpTal_Experience: integer;
    xpTal_Dribbling: integer;
    xpTal_Bulldog: Integer; // mastino +1 anticipo
    xpTal_midOffensive: Integer;
    xpTal_midDefensive: Integer;
    xpTal_Bomb: Integer;
}
  // prima aggiorno i disqualified e gli injured ( tutti i giocatori delle due squadre ). anche Mathcheslayed riguarda tutti.

  // Singoli players

    ConnGame := TMyConnection.Create(nil);
    ConnGame.Server := MySqlServerGame;
    ConnGame.Username:='root';
    Conngame.Password:='root';
    ConnGame.Database:='game';
    ConnGame.Connected := True;

    MyQueryGamePlayers := TMyQuery.Create(nil);
    MyQueryGamePlayers.Connection := ConnGame;   // game

    MyQueryUpdate := TMyQuery.Create(nil);
    MyQueryUpdate.Connection := ConnGame;   // game

  for T := 0 to 1 do begin
    TotMarketValue[T] := 0;
    MyQueryGamePlayers.SQL.text := 'SELECT * from game.players WHERE team =' + IntToStr(brain.Score.TeamGuid [T] );
    MyQueryGamePlayers.Execute ;

    for I := 0 to MyQueryGamePlayers.RecordCount -1 do begin

      aGuidTeam := MyQueryGamePlayers.FieldByName('team').asinteger;
      matches_Played := MyQueryGamePlayers.FieldByName('matches_played').asinteger;
      matches_left := MyQueryGamePlayers.FieldByName('matches_left').asinteger;
      Inc(matches_Played);
      Dec(matches_left);
      if matches_left <= 0 then  // fine carriera
        aGuidTeam := 0;


      disqualified  :=  MyQueryGamePlayers.FieldByName('disqualified').asinteger;
      if disqualified > 0 then
        Dec( disqualified );
      injured  :=  MyQueryGamePlayers.FieldByName('injured').asinteger;
      if injured > 0 then
        Dec( injured );

      // da qui in poi le variabili del brain possono modificare anche disqualified e injured ecc...
      // gestione cartellini       2 gialli 1 rosso. slo 1 rosso. se rosso 1,2,3 turni
      // dopo disqualified e injured vengono aggiornati solo da chi ha giocato in lstSoccerPlayer
      // lstSoccerPlayer contiene tutti i giocatori che hanno giocato (espulsi , infortunati, sostituiti ecc..) la lstReserve non mi serve

      TotYellowCard  :=  MyQueryGamePlayers.FieldByName('totyellowcard').asinteger;
      aPlayer := brain.GetSoccerPlayer2 ( MyQueryGamePlayers.FieldByName('guid').asstring ); // tutti! ...
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

                // ristrutturo il Player del brain con i dati del db
                aPlayer.Age:= Trunc(  matches_Played  div SEASON_MATCHES) + 18 ;
                aPlayer.Injured_Penalty [0] := MyQueryGamePlayers.FieldByName('injured_penalty1').asinteger;
                aPlayer.Injured_Penalty [1] := MyQueryGamePlayers.FieldByName('injured_penalty2').asinteger;
                aPlayer.Injured_Penalty [2] := MyQueryGamePlayers.FieldByName('injured_penalty3').asinteger;
                aPlayer.GrowthAttribute [0] := MyQueryGamePlayers.FieldByName('growth1').asinteger;
                aPlayer.GrowthAttribute [1] := MyQueryGamePlayers.FieldByName('growth2').asinteger;
                aPlayer.GrowthAttribute [2] := MyQueryGamePlayers.FieldByName('growth3').asinteger;
                aPlayer.GrowthTalent [0] := MyQueryGamePlayers.FieldByName('talent1').asinteger;
                aPlayer.GrowthTalent [1] := MyQueryGamePlayers.FieldByName('talent2').asinteger;
                aPlayer.GrowthTalent [2] := MyQueryGamePlayers.FieldByName('talent3').asinteger;
                aPlayer.DefaultSpeed := MyQueryGamePlayers.FieldByName('Speed').asinteger;
                aPlayer.DefaultDefense :=  MyQueryGamePlayers.FieldByName('Defense').AsInteger;
                aPlayer.DefaultPassing :=  MyQueryGamePlayers.FieldByName('Passing').AsInteger;
                aPlayer.DefaultBallControl :=  MyQueryGamePlayers.FieldByName('BallControl').AsInteger;
                aPlayer.DefaultShot :=  MyQueryGamePlayers.FieldByName('Shot').AsInteger;
                aPlayer.DefaultHeading :=  MyQueryGamePlayers.FieldByName('Heading').AsInteger;
             //   aPlayer.Talents :=  MyQueryGamePlayers.FieldByName('Talent').asstring;
                aPlayer.TalentID :=  MyQueryGamePlayers.FieldByName('Talent').asInteger;

                tsHistory := TStringList.Create;
                tsHistory.commaText := MyQueryGamePlayers.FieldByName('history').asString; // <-- 6 attributes
                aPlayer.History_Speed         := StrToInt( tsHistory[0]);
                aPlayer.History_Defense       := StrToInt( tsHistory[1]);
                aPlayer.History_BallControl   := StrToInt( tsHistory[2]);
                aPlayer.History_Passing       := StrToInt( tsHistory[3]);
                aPlayer.History_Shot          := StrToInt( tsHistory[4]);
                aPlayer.History_Heading       := StrToInt( tsHistory[5]);
                tsHistory.Free;


      // invece Injured si aggiorna qui perch� guadagnata in lastgame , quindi questo � un player injured adesso
      if (aPlayer.Injured > 0) and ( injured = 0 ) then begin // evita di caricare dal db player gi� injured. aplayer.injured � diverso da Injured

        aRnd := RndGenerate(100);
        case aRnd of
          1..70: injured := brain.RndGenerateRange( 1,2 ) ;
          71..90: injured := brain.RndGenerateRange( 3,10 );
          91..99: injured := brain.RndGenerateRange( 11,17 );
          100:begin // possibile perdita attributo
                injured := brain.RndGenerateRange( 18, 38 );
                calc_injured( aPlayer); // � calc_xp ma in perdita di 1    . Modifica default e history
              end;
        end;

      end;


        // xp qui sommo al db la xp guadagnata in partita
        tsXP := TStringList.Create;
        tsXP.commaText := MyQueryGamePlayers.FieldByName('xp').asstring; // <-- 6 attributes , 12 talenti

        // rispettare esatto ordine
        aPlayer.xp_Speed         := aPlayer.xp_Speed + StrToInt( tsXP[0]);
        aPlayer.xp_Defense       := aPlayer.xp_Defense + StrToInt( tsXP[1]);
        aPlayer.xp_BallControl   := aPlayer.xp_BallControl + StrToInt( tsXP[2]);
        aPlayer.xp_Passing       := aPlayer.xp_Passing + StrToInt( tsXP[3]);
        aPlayer.xp_Shot          := aPlayer.xp_Shot + StrToInt( tsXP[4]);
        aPlayer.xp_Heading       := aPlayer.xp_Heading + StrToInt( tsXP[5]);

        aPlayer.xpTal_GoalKeeper       := aPlayer.xpTal_GoalKeeper + StrToInt( tsXP[6]);
        aPlayer.xpTal_Challenge        := aPlayer.xpTal_Challenge + StrToInt( tsXP[7]);
        aPlayer.xpTal_Toughness        := aPlayer.xpTal_Toughness + StrToInt( tsXP[8]);
        aPlayer.xpTal_Power            := aPlayer.xpTal_Power + StrToInt( tsXP[9]);
        aPlayer.xpTal_Crossing         := aPlayer.xpTal_Crossing + StrToInt( tsXP[10]);
        aPlayer.xptal_longpass         := aPlayer.xptal_longpass + StrToInt( tsXP[11]);
        aPlayer.xpTal_Experience       := aPlayer.xpTal_Experience + StrToInt( tsXP[12]);
        aPlayer.xpTal_Dribbling        := aPlayer.xpTal_Dribbling + StrToInt( tsXP[13]);
        aPlayer.xpTal_Bulldog          := aPlayer.xpTal_Bulldog + StrToInt( tsXP[14]);
        aPlayer.xpTal_midOffensive     := aPlayer.xpTal_midOffensive + StrToInt( tsXP[15]);
        aPlayer.xpTal_midDefensive     := aPlayer.xpTal_midDefensive + StrToInt( tsXP[16]);
        aPlayer.xpTal_Bomb             := aPlayer.xpTal_Bomb + StrToInt( tsXP[17]);
        aPlayer.xpTal_PlayMaker        := aPlayer.xpTal_PlayMaker + StrToInt( tsXP[17]);
        aPlayer.xpTal_faul             := aPlayer.xpTal_faul + StrToInt( tsXP[17]);
        aPlayer.xpTal_marking          := aPlayer.xpTal_marking + StrToInt( tsXP[17]);
        aPlayer.xpTal_Positioning      := aPlayer.xpTal_Positioning + StrToInt( tsXP[17]);
        aPlayer.xpTal_freekicks        := aPlayer.xpTal_freekicks + StrToInt( tsXP[17]);
        tsXP.Free;
        calc_xp (aPlayer);  // modifica default history e attrbutes qui sotto
        // in uscita alcune xp sono ridimensionate perch� 'i punti sonon stati giocati'
        // in uscita pu� essere generato un talento

      TotMarketValue[T] := TotMarketValue[T]  +  aPlayer.MarketValue;
      // l'update riguarda tutti
      TextHistory := IntToStr(aPlayer.history_Speed) + ',' + IntToStr(aPlayer.history_Defense) + ',' + IntToStr(aPlayer.history_BallControl) + ',' +
      IntToStr(aPlayer.history_Passing) + ',' + IntToStr(aPlayer.history_Shot) + ',' + IntToStr(aPlayer.history_Heading);

      TextXP := IntToStr(aPlayer.xp_Speed) + ',' + IntToStr(aPlayer.xp_Defense) + ',' + IntToStr(aPlayer.xp_BallControl) + ',' +
      IntToStr(aPlayer.xp_Passing) + ',' + IntToStr(aPlayer.xp_Shot) + ',' + IntToStr(aPlayer.xp_Heading) + ',' +
      IntToStr(aPlayer.xpTal_GoalKeeper) + ',' + IntToStr(aPlayer.xpTal_Challenge) + ',' + IntToStr(aPlayer.xpTal_Toughness) + ',' +
      IntToStr(aPlayer.xpTal_Power) + ',' + IntToStr(aPlayer.xpTal_Crossing) + ',' + IntToStr(aPlayer.xptal_longpass) + ',' +
      IntToStr(aPlayer.xpTal_Experience) + ',' + IntToStr(aPlayer.xpTal_Dribbling) + ',' + IntToStr(aPlayer.xpTal_Bulldog) + ',' +
      IntToStr(aPlayer.xpTal_midOffensive) + ',' + IntToStr(aPlayer.xpTal_midDefensive) + ',' + IntToStr(aPlayer.xpTal_Bomb) + ',' +
      IntToStr(aPlayer.xpTal_PlayMaker) + ',' + IntToStr(aPlayer.xpTal_faul) + ',' + IntToStr(aPlayer.xpTal_Marking) + ',' +
      IntToStr(aPlayer.xpTal_Positioning) + ',' + IntToStr(aPlayer.xpTal_Freekicks) ;

      // solo ora aggiorno la stamina di tutti
      NewStamina :=  aPlayer.Stamina ;
      if (injured <= 0) and (aPlayer.Injured <= 0)then begin
        NewStamina := NewStamina + REGEN_STAMINA;
        if NewStamina > 120 then NewStamina := 120;
      end;
      if aPlayer.Injured > 0 then  // injured in questa partita
        newStamina:=0;

      MyQueryUpdate.SQL.text := 'UPDATE game.players SET matches_played = ' + IntTostr(matches_played) +
                                                      ', matches_left = ' + IntTostr(matches_Left) +
                                                      ', team = ' + IntTostr(aGuidTeam) +
                                                      ', disqualified = ' + IntTostr(disqualified) +
                                                      ', injured = ' + IntTostr(injured) +
                                                      ', Speed = ' + IntTostr(aPlayer.DefaultSpeed ) +
                                                      ', Defense = ' + IntTostr(aPlayer.DefaultDefense) +
                                                      ', Passing = ' + IntTostr(aPlayer.DefaultPassing) +
                                                      ', BallControl = ' + IntTostr(aPlayer.DefaultBallControl) +
                                                      ', Shot = ' + IntTostr(aPlayer.DefaultShot) +
                                                      ', Heading = ' + IntTostr(aPlayer.DefaultHeading) +
                                                      ', History = ''' + TextHistory + '''' +
                                                      ', Xp = ''' + TextXP + '''' +
                                                      ', Talent = ' + IntToStr(aPlayer.TalentID) + // usato come id numerico
                                                      ', Stamina = ' + IntToStr (NewStamina) +
                                                      ' WHERE guid = ' + MyQueryGamePlayers.FieldByName('guid').asstring ;
      MyQueryUpdate.Execute ;

      MyQueryGamePlayers.Next ;

    end;

  end;
  // la MI � gi� aggiornata e devo solo storarla. Nexha la devo cambiare e qui so gi� per forza come
  // Team
  MyQueryGameTeams := TMyQuery.Create(nil);
  MyQueryGameTeams.Connection := ConnGame;  // game

  MyQueryGameTeams.SQL.text := 'SELECT matchesplayed, points from game.teams WHERE guid = ' + IntToStr( brain.Score.TeamGuid [0]);
  MyQueryGameTeams.Execute;
  MatchesplayedTeam := MyQueryGameTeams.FieldByName('matchesplayed').AsInteger + 1;
  Points := MyQueryGameTeams.FieldByName('points').AsInteger + brain.Score.Points[0];

  MyQueryGameTeams.SQL.text := 'UPDATE game.teams SET nextha = 1, mi = ' + IntToStr(brain.Score.TeamMI [0]) + ', MarketValue = ' +
  IntToStr( TotMarketValue[0]) + ',matchesplayed=' + IntToStr(MatchesplayedTeam) + ' WHERE Guid = ' + IntToStr( brain.Score.TeamGuid [0]);
  MyQueryGameTeams.Execute;


  MyQueryGameTeams.SQL.text := 'SELECT matchesplayed,points from game.teams WHERE guid = ' + IntToStr( brain.Score.TeamGuid [1]);
  MyQueryGameTeams.Execute;
  MatchesplayedTeam := MyQueryGameTeams.FieldByName('matchesplayed').AsInteger + 1;
  Points := MyQueryGameTeams.FieldByName('points').AsInteger + brain.Score.Points[1];

  MyQueryGameTeams.SQL.text := 'UPDATE game.teams SET nextha = 0, mi = ' + IntToStr(brain.Score.TeamMI [1]) + ', MarketValue = ' +
  IntToStr( TotMarketValue[1]) + ',matchesplayed=' + IntToStr(MatchesplayedTeam) + ',points=' + IntToStr(Points) + ' WHERE Guid = ' + IntToStr( brain.Score.TeamGuid [1]);
  MyQueryGameTeams.Execute;


  MyQueryGameTeams.Free;
  MyQueryUpdate.Free;
  MyQueryGamePlayers.Free;

  // Aggiorno archive con tutti i dati e matchinfo
  DecodeBrainIds ( brain.brainIds, myYear, myMonth, myDay, myHour, myMin, mySec );
  MyQueryArchive := TMyQuery.Create(nil);
  MyQueryArchive.Connection := ConnGame;   // game
  MyQueryArchive.SQL.text := 'INSERT INTO game.archive SET year = ' + myYear + ', month = ' + myMonth + ',day = ' + myDay +
                             ',hour = ' + MyHour + ',minute = ' + MyMin + ',second = ' + MySec +
                             ',guidteam0 = ' + IntToStr(brain.Score.TeamGuid [0]) + ',guidteam1 = ' + IntToStr(brain.Score.TeamGuid [1]) +
                             ',gol0 = ' + IntToStr(brain.Score.gol [0]) + ',gol1 = ' + IntToStr(brain.Score.gol [1]) +
                             ',matchinfo = "' + brain.MatchInfo.CommaText + '"';
  MyQueryArchive.Execute;
  MyQueryArchive.Free;
  ConnGame.Connected := false;
  ConnGame.Free;

    // Aggiorno classifica cannonieri
  //
   { TODO -con the road : finalize ogni 38 partite +2 arrivi tra 18 e 21+ gestione denaro e nuovi arrivi giovani. max 3 sul mercato.  }


end;
procedure TBrainManager.calc_xp (aPlayer: TSoccerPlayer);
var
  aRnd,percA,percT: Integer;
begin
  case aPlayer.Age of
    18..24: begin
      percA := aPlayer.GrowthAttribute [0];
      percT := aPlayer.GrowthTalent [0];
    end;
    25..30: begin
      percA := aPlayer.GrowthAttribute [1];
      percT := aPlayer.GrowthTalent [1];
    end;
    31..33: begin
      percA := aPlayer.GrowthAttribute [2];
      percT := aPlayer.GrowthTalent [2];
    end;
  end;

  aRnd := RndGenerate( 100 );
//Scelta direzione  Difesa esclude tiro e viceversa
//ultimo valore 6 1% . calcolare numero calciatori reali a 6 su 500 calciatori

//Speed e heading incrementano al massimo di 1 e mai pi�

//CR7  deve nascere con speed 4 o anche 3, se incrementa di 1 prima dei 24 anni . sono 14 chances (al 30% nel migliore dei casi) sestina roulette
{
        x
        x x
x     x x x
x   x x x x
x   x x x x
o o o o o o
}

  if aPlayer.xp_Speed >= xp_SPEED_POINTS then begin
    aPlayer.xp_Speed := aPlayer.xp_Speed - xp_SPEED_POINTS;
    if aPlayer.Age > 24 then Exit; // dopo i 24 anni non incrementa pi� in speed

    if aRnd <= PercA then begin
      if (aPlayer.History_Speed = 0) and (aPlayer.DefaultSpeed < 4) then begin // speed incrementa solo una volta e al amssimo a 4
        aPlayer.DefaultSpeed := aPlayer.DefaultSpeed + 1;
        aPlayer.History_Speed := aPlayer.History_Speed + 1;
      end;
    end;
  end;
  if aPlayer.xp_Defense >= xp_DEFENSE_POINTS then begin
    aPlayer.xp_Defense := aPlayer.xp_Defense - xp_DEFENSE_POINTS;
    if aRnd <= PercA then begin
      if aPlayer.DefaultDefense < 6 then begin
        if aPlayer.DefaultDefense +1 = 6 then Can6 ( aPlayer, atDefense )
        else begin
          aPlayer.DefaultDefense := aPlayer.DefaultDefense + 1;
          aPlayer.History_Defense := aPlayer.History_Defense + 1;
        end;
      end;
    end;

  end;
  if aPlayer.xp_BallControl  >= xp_BALLCONTROL_POINTS then begin
    aPlayer.xp_BallControl := aPlayer.xp_BallControl - xp_BallControl_POINTS;
    if aRnd <= PercA then begin
      if aPlayer.DefaultBallControl < 6 then begin
        if aPlayer.DefaultBallControl +1 = 6 then Can6 ( aPlayer, atBallControl )
        else begin
          aPlayer.DefaultBallControl := aPlayer.DefaultBallControl + 1;
          aPlayer.History_BallControl := aPlayer.History_BallControl + 1;
        end;
      end;
    end;

  end;
  if aPlayer.xp_Passing >= xp_PASSING_POINTS then begin
    aPlayer.xp_Passing := aPlayer.xp_Passing - xp_Passing_POINTS;
    if aRnd <= PercA then begin
      if aPlayer.DefaultPassing < 6 then begin
        if aPlayer.DefaultPassing +1 = 6 then Can6 ( aPlayer, atPassing )
        else begin
          aPlayer.DefaultPassing := aPlayer.DefaultPassing + 1;
          aPlayer.History_Passing := aPlayer.History_Passing + 1;
        end;
      end;
    end;

  end;
  if aPlayer.xp_Shot >= xp_SHOT_POINTS then begin
    aPlayer.xp_Shot := aPlayer.xp_Shot - xp_Shot_POINTS;
    if aRnd <= PercA then begin
      if aPlayer.DefaultShot < 6 then begin
        if aPlayer.DefaultShot +1 = 6 then Can6 ( aPlayer, atShot )
        else begin
          aPlayer.DefaultShot := aPlayer.DefaultShot + 1;
          aPlayer.History_Shot := aPlayer.History_Shot + 1;
        end;
      end;
    end;

  end;
  if aPlayer.xp_Heading >= xp_HEADING_POINTS then begin
    aPlayer.xp_Heading := aPlayer.xp_Heading - xp_Heading_POINTS;
    if aRnd <= PercA then begin
      if aPlayer.History_Heading = 0  then begin // Heading incrementa solo una volta
        if aPlayer.DefaultHeading < 6 then begin
          if aPlayer.DefaultHeading + 1 = 6 then Can6 ( aPlayer, atHeading )
          else begin
            aPlayer.DefaultHeading := aPlayer.DefaultHeading + 1;
            aPlayer.History_Heading := aPlayer.History_Heading + 1;
          end;
        end;
      end;
    end;
  end;

  if aPlayer.xpTal_GoalKeeper >= xp_TAL_GOALKEEPER_POINTS then begin
    aPlayer.xpTal_GoalKeeper  := aPlayer.xpTal_GoalKeeper - xp_TAL_GOALKEEPER_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'goalkeeper';
        aPlayer.TalentID := 1;
      end;
    end;
  end;
  if aPlayer.xpTal_Challenge >= xp_TAL_CHALLENGE_POINTS then begin
    aPlayer.xpTal_challenge  := aPlayer.xpTal_challenge - xp_TAL_GOALKEEPER_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'challenge';
        aPlayer.TalentID := 2;
      end;
    end;

  end;
  if aPlayer.xpTal_Toughness >= xp_TAL_TOUGHNESS_POINTS then begin
    aPlayer.xpTal_toughness  := aPlayer.xpTal_toughness - xp_TAL_TOUGHNESS_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'toughness';
        aPlayer.TalentID := 3;
      end;
    end;

  end;
  if aPlayer.xpTal_Power >= xp_TAL_POWER_POINTS then begin
    aPlayer.xpTal_power  := aPlayer.xpTal_power - xp_TAL_POWER_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'power';
        aPlayer.TalentID := 4;
      end;
    end;

  end;
  if aPlayer.xpTal_Crossing >= xp_TAL_CROSSING_POINTS then begin
    aPlayer.xpTal_crossing  := aPlayer.xpTal_crossing - xp_TAL_CROSSING_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'crossing';
        aPlayer.TalentID := 5;
      end;
    end;

  end;
  if aPlayer.xptal_longpass >= xp_TAL_LONGPASS_POINTS then begin
    aPlayer.xpTal_longpass  := aPlayer.xpTal_longpass - xp_TAL_LONGPASS_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'longpass';
        aPlayer.TalentID := 6;
      end;
    end;

  end;
  if aPlayer.xpTal_Experience >= xp_TAL_EXPERIENCE_POINTS then begin
    aPlayer.xpTal_experience  := aPlayer.xpTal_experience - xp_TAL_EXPERIENCE_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'experience';
        aPlayer.TalentID := 7;
      end;
    end;

  end;
  if aPlayer.xpTal_Dribbling >= xp_TAL_DRIBBLING_POINTS then begin
    aPlayer.xpTal_dribbling  := aPlayer.xpTal_dribbling - xp_TAL_DRIBBLING_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'dribbling';
        aPlayer.TalentID := 8;
      end;
    end;

  end;
  if aPlayer.xpTal_Bulldog >= xp_TAL_BULLDOG_POINTS then begin
    aPlayer.xpTal_bulldog  := aPlayer.xpTal_bulldog - xp_TAL_BULLDOG_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'bulldog';
        aPlayer.TalentID := 9;
      end;
    end;

  end;
  if aPlayer.xpTal_midOffensive >= xp_TAL_MIDOFFENSIVE_POINTS then begin
    aPlayer.xpTal_midoffensive  := aPlayer.xpTal_midoffensive - xp_TAL_MIDOFFENSIVE_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'offensive';
        aPlayer.TalentID := 10;
      end;
    end;

  end;
  if aPlayer.xpTal_midDefensive >= xp_TAL_MIDDEFENSIVE_POINTS then begin
    aPlayer.xpTal_middefensive  := aPlayer.xpTal_middefensive - xp_TAL_MIDDEFENSIVE_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'defensive';
        aPlayer.TalentID := 11;
      end;
    end;

  end;
  if aPlayer.xpTal_Bomb >= xp_TAL_BOMB_POINTS then begin
    aPlayer.xpTal_bomb  := aPlayer.xpTal_bomb - xp_TAL_BOMB_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'bomb';
        aPlayer.TalentID := 12;
      end;
    end;

  end;
  if aPlayer.xpTal_PlayMaker >= xp_TAL_PLAYMAKER_POINTS then begin
    aPlayer.xpTal_PlayMaker  := aPlayer.xpTal_PlayMaker - xp_TAL_PLAYMAKER_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'playmaker';
        aPlayer.TalentID := 13;
      end;
    end;

  end;
  if aPlayer.xpTal_faul >= xp_TAL_faul_POINTS then begin
    aPlayer.xpTal_faul  := aPlayer.xpTal_faul - xp_TAL_faul_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'faul';
        aPlayer.TalentID := 14;
      end;
    end;

  end;
  if aPlayer.xpTal_marking >= xp_TAL_marking_POINTS then begin
    aPlayer.xpTal_marking  := aPlayer.xpTal_marking - xp_TAL_marking_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'marking';
        aPlayer.TalentID := 15;
      end;
    end;

  end;
  if aPlayer.xpTal_Positioning >= xp_TAL_Positioning_POINTS then begin
    aPlayer.xpTal_Positioning  := aPlayer.xpTal_Positioning - xp_TAL_Positioning_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'Positioning';
        aPlayer.TalentID := 16;
      end;
    end;

  end;
  if aPlayer.xpTal_freekicks >= xp_TAL_freekicks_POINTS then begin
    aPlayer.xpTal_freekicks  := aPlayer.xpTal_freekicks - xp_TAL_freekicks_POINTS;
    if aPlayer.Talents = '' then begin
      if aRnd <= PercT then begin
        aPlayer.Talents := 'freekicks';
        aPlayer.TalentID := 17;
      end;
    end;

  end;

end;
procedure TBrainManager.calc_injured (aPlayer: TSoccerPlayer);
var
  aRnd,percA: Integer;
begin
  case aPlayer.Age of
    18..24: begin
      percA := aPlayer.Injured_Penalty [0];
    end;
    25..30: begin
      percA := aPlayer.Injured_Penalty [1];
    end;
    31..33: begin
      percA := aPlayer.Injured_Penalty [2];
    end;
  end;

  aRnd := RndGenerate( 100 );
  if aRnd <= PercA then begin
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
procedure TBrainManager.can6 (aPlayer: TSoccerPlayer; at : TAttributeName);
var
  aRnd: Integer;
begin
  // qui � gi� passato dal normale percA... 1 su 1000 ce la fa....
  aRnd := RndGenerate(1000);
  if aPlayer.Tal_GoalKeeper > 0 then aRnd := 2;  // porieri a 6 non esistono per ora
  if aRnd = 1 then begin

    if at = AtDefense then begin
      aPlayer.DefaultDefense := 6;
      aPlayer.History_Defense := aPlayer.History_Defense + 1;
    end
    else if at = atBallControl then begin
      aPlayer.DefaultBallControl := 6;
      aPlayer.History_BallControl := aPlayer.History_BallControl + 1;
    end
    else if at = atPassing then begin
      aPlayer.DefaultPassing := 6;
      aPlayer.History_Passing := aPlayer.History_Passing + 1;
    end
    else if at = atShot then begin
      aPlayer.DefaultShot := 6;
      aPlayer.History_Shot := aPlayer.History_Shot + 1;
    end
    else if at = atHeading then begin
      aPlayer.DefaultHeading := 6;
      aPlayer.History_Heading := aPlayer.History_Heading + 1;
    end
  end;

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

  WaitForSingleObject(Mutex,INFINITE);
  for I := 0 to lstbrain.count -1 do begin
    if lstbrain[i].BrainIDS  = ids then begin // esiste gi� una partita con quel client
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

  WaitForSingleObject(Mutex,INFINITE);
  for I := lstbrain.count -1 downto 0 do begin
    for S := lstbrain[i].lstSpectator.count -1 downto 0 do begin
      if lstbrain[i].lstSpectator[s] = Cliid then begin // esiste gi� una partita con quel client in spectator
        Result:= lstbrain[i];
        ReleaseMutex(Mutex);
        exit;
      end;
    end;
  end;
  ReleaseMutex(Mutex);

end;
procedure TBrainManager.AddBrain ( brain: TSoccerbrain );
var
  i: Integer;
  found: Boolean;
label addbot;
begin
//  if  brain.Score.cliid[0] = 0 then goto AddBot;

//  for I := 0 to lstbrain.count -1 do begin
//    if (lstbrain[i].Score.CliId[0] = brain.Score.cliid[0]) or
//       (lstbrain[i].Score.CliId[0] = brain.Score.cliid[1]) or
//       (lstbrain[i].Score.CliId[1] = brain.Score.cliid[1]) or
//       (lstbrain[i].Score.CliId[1] = brain.Score.cliid[0])  then begin // esiste gi� una partita con quel client
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
  MyQueryTalents: TMyQuery;
  i: integer;
  ConnGame : TMyConnection;
begin

  Mutex:=CreateMutex(nil,false,'list');
  RandGen := TtdCombinedPRNG.Create(0, 0);

  FormationsPreset := TList<TFormation>.Create;
  CreateFormationsPreset;

  ini := TIniFile.Create  ( ExtractFilePath(Application.ExeName) + 'server.ini');
  dir_log := ini.ReadString('setup','dir_log','');

  MySqlServerGame := ini.ReadString('Tcp','Address','localhost');
  MySqlServerWorld := ini.ReadString('Tcp','Address','localhost');
  MySqlServerAccount := ini.ReadString('Tcp','Address','localhost');

  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryTalents := TMyQuery.Create(nil);
  MyQueryTalents.Connection := ConnGame;   // game
  MyQueryTalents.SQL.Text := 'SELECT name FROM game.talents order by guid';
  MyQueryTalents.Execute;

  tsTalents:= TStringList.Create ;
  for I := 0 to MyQueryTalents.RecordCount -1 do begin
    tsTalents.Add(MyQueryTalents.FieldByName('name').AsString  ) ;
    MyQueryTalents.Next ;
  end;
  MyQueryTalents.Free;

  ConnGame.Connected := False;
  ConnGame.Free;

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

  SE_GridLiveMatches.thrdAnimate.Priority := tpLowest;

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
  FormationsPreset.Free;
  RandGen.Free;
  Queue.Free;
  BrainManager.Free;
  tsTalents.Free;
  for I := TsWorldCountries.Count downto 1 do begin
    TsWorldteams[i].free;
  end;
  TsWorldCountries.Free;
  CloseHandle(Mutex);

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
          if brainManager.lstBrain[i].Score.TeamGuid [0] = Client.GuidTeam then begin
            brainManager.lstBrain[i].Score.AI[0]:= true;
            brainManager.lstBrain[i].Score.CliId [0] := 0;
          end
          else if brainManager.lstBrain[i].Score.TeamGuid [1] = Client.GuidTeam then begin
            brainManager.lstBrain[i].Score.AI[1] := true;
            brainManager.lstBrain[i].Score.CliId [1] := 0;
          end;
        end;
      end;
    end;

    for I := 0 to brainManager.lstBrain.Count -1 do begin
      brainManager.lstBrain [i].RemoveSpectator (Client.CliId);
    end;


  ReleaseMutex(Mutex);
   Label1.caption :=  'Client Count: ' + intTostr(Tcpserver.ClientCount );

end;

procedure TFormServer.TcpserverDataAvailable(Sender: TObject; ErrCode: Word);
var
    Cli: TWSocketThrdClient;
    RcvdLine,NewData,history,xp: string;
    aBrain: TSoccerBrain;
    ts: TStringList;
    s,d,p,b,sh,h: integer;
    i,Start,aValue, chanceG,chanceT, talentID,Age: Integer;
    anAuth: TAuthInfo;
    MyQueryCheat,MyQueryTeam: TMyQuery;
    tsNationTeam: TStringList;
    alvlUp: TLevelUp;
    ConnGame,ConnAccount : TMyConnection;
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
            Cli.SendStr( 'errorlogin' + EndOfline);

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
            Cli.GuidTeam := anAuth.GuidTeam;
            Cli.WorldTeam := anAuth.WorldTeam;
            Cli.teamName  := anAuth.TeamName ;
            Cli.nextHA := anAuth.nextha;
            Cli.mi := anAuth.mi;
            aBrain :=  inLiveMatchGuidTeam ( Cli.GuidTeam );
//            Cli.SendStr( 'guid,' + IntToStr(Cli.GuidTeam ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + EndofLine);
            if aBrain = nil then begin
//              PrepareGameTeam ( Cli.GuidTeam ); // Cliid(account), squadra. una cliid(account) pu� vedere anche un'altra squadra
              Cli.SendStr( 'guid,' + IntToStr(Cli.GuidTeam ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + EndofLine);


            end
            else begin // reconnect
              if aBrain.Score.TeamGuid [0] = Cli.GuidTeam then begin
                aBrain.Score.CliId[0]:= Cli.CliId ;
                aBrain.Score.AI [0] := False;                            // annulla la AI
              end
              else  if aBrain.Score.TeamGuid [1] = Cli.GuidTeam then  begin
                aBrain.Score.CliId[1]:= Cli.CliId ;
                aBrain.Score.AI [1] := False;  // annulla la AI
              end;
              cli.Brain := TObject(aBrain);

              Cli.SendStr( 'GUID,' + IntToStr(Cli.GuidTeam ) + ',' + Cli.teamName  + ',' + intToStr(Cli.nextHA) +',' + intToStr(Cli.mi) + ',' +
              'BEGINBRAIN' +  chr ( abrain.incMove )   +  brainManager.GetBrainStream ( abrain ) + EndofLine);
          //    Cli.SendStr ( 'BEGINBRAIN' +  chr ( abrain.incMove )   +  brainManager.GetBrainStream ( abrain ) + EndofLine);
            end;
          end;
        end;
      end

      (* da quin in poi Cli.pwdTicket � gi� settata *)
      else if ts[0] ='selectedteam' then begin
            validate_clientcreateteam (ts.CommaText , cli) ;
            if cli.sReason <> ''  then goto cheat;
        // Creo il team, creo i players, mando al client il team
            Cli.GuidTeam := CreateGameTeam ( Cli, ts[1]);  // ts[1] � guid world.teams, non la Guidteam
            if cli.sReason <> ''  then goto cheat;
            // Preparo il file da venire a prendere in Ftp
          reset_formation (cli);
          Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeam ) + EndofLine);
      end
     (* FINE UNA VOLTA ALL'INIZIO DEL GAME *)

      else if ts[0]= 'getformation' then  begin
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;

            Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeam ) + EndofLine);
      end
      else if ts[0]= 'setformation' then  begin
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;
         (* Valida solo il formmato. non � la checkformation *)
          validate_setformation  (ts.CommaText , cli) ;
//          if cli.sReason <> ''  then goto cheat;

        // STORE nel DB della formation diretta della commatext
            store_formation (ts.CommaText );
            Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeam ) + EndofLine);
      end
      else if ts[0]= 'resetformation' then  begin
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;
         (* Valida solo il formmato. non � la checkformation *)
          reset_formation (cli);
  //        if cli.sReason <> ''  then goto cheat;

          Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeam ) + EndofLine);
      end
      else if ts[0]= 'setuniform' then  begin
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;

          validate_setuniform  (ts.CommaText , cli) ;
          if cli.sReason <> ''  then goto cheat;

        // STORE nel DB delle uniform
            store_uniform ( Cli.GuidTeam, ts.CommaText );
            Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeam ) + EndofLine);
      end
      else if ts[0]= 'levelup' then  begin  // ids attr or talent
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;
          validate_levelup (ts.CommaText, Cli); // levelup, ids, attr or talentID  // qui controlla sql injection
          if cli.sReason <> '' then  goto cheat;
          TryDecimalStrToInt( ts[1], aValue); // ids � numerico passato da validate_levelup
          validate_player( aValue, cli, aValue,s,d,p,b,sh,h, chanceG, chanceT, talentID, age, history,xp  ); // disqualified ora non ci interessa , mi interessa la chance in base all'et�
          if cli.sReason <> '' then  goto cheat;
          if TryDecimalStrToInt( ts[2], aValue )  and (talentID <> 0) then begin
            cli.sreason := 'player with talent tryLevelup talent';
            goto cheat;
          end;

          alvlUp:=  TrylevelUp ( ts[1], ts[2], s,d,p,b,sh,h, chanceG, chanceT,talentID,age, history,xp  ); // il client aggiorna in mybrainformation e resetta le infoxp
          Cli.SendStr ( 'BEGINTEAM' + GetTeamStream ( Cli.GuidTeam ) + EndofLine);
      end
      else if ts[0]= 'sell' then  begin  // ids value
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;

          validate_Sell (ts.CommaText, Cli);
          if cli.sReason <> '' then  goto cheat;
          MarketSell ( Cli, ts.CommaText ); //<-- va sul db game.players ---> game.market  // deve essere un player di quel guidteam. faccio tutto qui per economia
          if cli.sReason <> '' then  goto cheat;
          Cli.SendStr ( 'BEGINTEAM'  + GetTeamStream ( Cli.GuidTeam ) + EndofLine);  // aggiorna completamente il client

      end
      else if ts[0]= 'cancelsell' then  begin  // ids value
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;

          validate_CancelSell (ts.CommaText, Cli);
          if cli.sReason <> '' then  goto cheat;
          MarketCancelSell ( Cli, ts.CommaText ); //<-- va sul db game.players ---> game.market  // deve essere un player di quel guidteam. faccio tutto qui per economia
          if cli.sReason <> '' then  goto cheat;
          Cli.SendStr ( 'BEGINTEAM'  + GetTeamStream ( Cli.GuidTeam ) + EndofLine);  // aggiorna completamente il client

      end
      else if ts[0]= 'buy' then  begin  // ids
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;

          validate_Buy (ts.CommaText, Cli);
          if cli.sReason <> '' then  goto cheat;
          MarketBuy ( Cli, ts.CommaText );
          if cli.sReason <> '' then  goto cheat;
          Cli.SendStr ( 'BEGINTEAM'  + GetTeamStream ( Cli.GuidTeam ) + EndofLine);  // aggiorna completamente il client

      end
      else if ts[0]= 'market' then begin  // maxvalue
          if inQueue (Cli.Cliid) or inLiveMatchCliid(Cli.Cliid) or inSpectator(Cli.Cliid)  then begin
            cli.sReason := 'InQueue,InliveMatch,inSpectator: ' + ts.CommaText;
            if cli.sReason <> '' then  goto cheat;
          end;

          validate_market (ts.CommaText, Cli);
          if cli.sReason <> '' then  goto cheat;
          Cli.SendStr ( 'BEGINMARKET'  + GetMarketPlayers ( Cli.GuidTeam, StrToInt(ts[1]) ) + EndofLine);  // aggiorna completamente il client

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
          Cli.SendStr ( 'BEGINTEAM'  + GetTeamStream ( Cli.GuidTeam ) + EndofLine);  // aggiorna completamente il client

      end
      else if ts[0] ='queue' then begin
          // mi rimuovo da ogni lstSpectator come nel Disconnect
      //QUI valutare se ci sono problemi nel disconnect
      //  for I := 0 to Tcpserver.ClientCount -1 do begin
      //    TSoccerBrain(Tcpserver.Client [i].Brain).RemoveSpectator (Cli.CliId); // rimuovo me stesso da ogni brain
      //  end;
          if checkformation (cli) and not InQueue(Cli.CliId ) then begin
            //Cli.MarketValueTeam := GetMarketValueTeam ( Cli.GuidTeam );

            ConnGame := TMyConnection.Create(nil);
            ConnGame.Server := MySqlServerGame;
            ConnGame.Username:='root';
            Conngame.Password:='root';
            ConnGame.Database:='game';
            ConnGame.Connected := True;

            MyQueryTeam := TMyQuery.Create(nil);
            MyQueryTeam.Connection := ConnGame;   // game
            MyQueryTeam.SQL.text :=  'select nextha, rank from game.teams where guid=' + IntToStr(Cli.GuidTeam);
            MyQueryTeam.Execute ;
            Cli.nextHA := MyQueryTeam.FieldByName('nextha').AsInteger ;
            Cli.rank := MyQueryTeam.FieldByName('rank').AsInteger ;
            MyQueryTeam.Free;

            ConnGame.connected := False;
            ConnGame.free;
            Cli.TimeStartQueue := GetTickCount; // dopo di che parte il bot
            Queue.Add (Cli);
            Cli.SendStr('avg' + EndOfline);
          end
          else Cli.SendStr( 'errorformation' + EndOfline);

  // in coda
      end
      else if  ts[0] ='listmatch' then begin
          { ottiene la lista di matches. risponde in ftp }
          // 0=listmatch
          newData :=  GetListActiveBrainStream ;
          if Length(NewData) > 0 then
            Cli.SendStr ( 'BEGINLAB' + newData + EndofLine);  // diretto

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
      else if  ts[0] ='closeviewmatch' then begin
          { smette di guardare la partita di un altro giocatore o della AI }
          aBrain := BrainManager.FindBrain ( cli.CliId );// cerca in brainManager il cliId del client
          if aBrain <> nil then begin
            aBrain.RemoveSpectator (Cli.CliId); // rimuovo me stesso client al brain di un altro wSocket
            Cli.Brain := Nil;
          end;
      end




      // il comando va direttamente al brain del client, quello su cui sta giocando.
      // se desidero input da altri client devo assegnare il brain dell'altro client ( TSoccerBrain(Cli.Brain):= altrobrain
      else if (ts[0] ='PLM')  or (ts[0] ='TACTIC')then begin
            validate_CMD4 (ts.CommaText, Cli); // cli.pwd cli.guidteam, cli.brain cli.team, cli.brain.teamturn
            if cli.sReason <> '' then  goto cheat;

          // 0=PLM o TACTIC 1=ids 2=cellX 3=CellY
           TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) +',' + ts[0]  + ',' + ts[1] + ',' + ts[2] +  ',' + ts[3]  );
      end
      else if (ts[0] ='SUB') then begin
            validate_CMD_subs (ts.CommaText, Cli); // cli.pwd cli.guidteam, cli.brain cli.team, cli.brain.teamturn
            if cli.sReason <> '' then  goto cheat;
          // 0=SUBS 1=ids 2=is
           TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2]   );
      end
      else if (ts[0] ='PASS') or (ts[0] ='COR')or (ts[0] ='CRO2')  then begin  // sul brain iscof batter� il corner
            validate_CMD1 (ts.CommaText,Cli);
            if cli.sReason <> '' then   goto cheat;
          // 0=PASS
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] );
      end
      else if (ts[0] ='PRS') or (ts[0] ='POS') or (ts[0] ='PRO')  then begin
            validate_CMD1 (ts.CommaText, Cli);
            if cli.sReason <> '' then   goto cheat;
          // 0=PRS...
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0]);
      end
      else if (ts[0] ='PRE') or (ts[0] ='TAC') or (ts[0] ='STAY') or (ts[0] ='FREE') then begin
            validate_CMD2 (ts.CommaText, Cli);
            if cli.sReason <> '' then   goto cheat;
          // 0=PRE... 1=ids di chi fa il tackle o il pressing
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] );
      end
      else if (ts[0] ='CRO') or (ts[0] ='SHP') or (ts[0] ='DRI')  then begin
            validate_CMD3 (ts.CommaText, cli);
            if cli.sReason <> '' then   goto cheat;
          // 0=CRO... 1=cellX 2=CellY
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] );
      end
      else if ts[0] ='LOP' then begin
            validate_CMDlop (ts.CommaText, cli);
            if cli.sReason <> '' then   goto cheat;
          // 0=LOP... 1=cellX 2=CellY 3=N o GKLOP
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3] );
      end
      else if (ts[0] ='CORNER_ATTACK.SETUP') or (ts[0] ='FREEKICK2_ATTACK.SETUP') then begin
            validate_CMD_coa(ts.CommaText, cli);
            if cli.sReason <> '' then  goto cheat;
          // 0=CORNER_ATTACK.SETUP 1=cof 2=coa1 3=coa2 4=coa3
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3] + ',' + ts[4]);
      end
      else if (ts[0] ='CORNER_DEFENSE.SETUP') or (ts[0] ='FREEKICK2_DEFENSE.SETUP')  then begin
            validate_CMD_cod(ts.CommaText, Cli);
            if cli.sReason <> '' then  goto cheat;
          // 0=CORNER_DEFENSE.SETUP 1=cod1 2=cod2 3=cod3
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3] );
      end
      else if ts[0] ='FREEKICK3_DEFENSE.SETUP' then begin
            validate_CMD_bar(ts.CommaText, Cli);
            if cli.sReason <> '' then  goto cheat;
          // 0=FREEKICK3_DEFENSE.SETUP 1=bar1 2=bar2 3=bar3 4=bar4
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3]+ ',' + ts[4] );
      end
      else if (ts[0] ='FREEKICK1_ATTACK.SETUP') or (ts[0] ='FREEKICK3_ATTACK.SETUP') or (ts[0] ='FREEKICK4_ATTACK.SETUP')  then begin
            validate_CMD2(ts.CommaText, Cli);
            if cli.sReason <> '' then  goto cheat;
          // 0=FREEKICK1_ATTACK.SETUP 1=fkf1 o3o4
            TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] +  ',' + ts[1]);
      end


  (* GM COMMANDS *)

      else if ts[0] ='setball'  then begin
            validate_CMD3 (ts.CommaText, cli);
            if cli.sReason <> '' then  goto cheat;
            if Cli.GmLevel > 0 then begin
              TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2]  )
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
              TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1]   )
            end
            else begin
              cli.sReason := 'no GmLevel';
              goto cheat;
            end;

      end
      else if ts[0] ='randomstamina'  then begin
            if Cli.GmLevel > 0 then begin
              TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0]  )
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
              TSoccerBrain(Cli.Brain).BrainInput ( IntToStr(Cli.GuidTeam) + ',' + ts[0] + ',' + ts[1] + ',' + ts[2] + ',' + ts[3] )
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
          MyQueryCheat.SQL.Text := ' INSERT into cheat_detected (reason) values ("' + cli.sReason + '")';
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
        MyQueryCheat.SQL.Text := ' INSERT into cheat_detected (reason) values ("' + E.ToString + ' TFormServer.TcpserverDataAvailable ' + '")';
        MyQueryCheat.Execute ;
        MyQueryCheat.Free;
        ConnAccount.Connected := false;
        ConnAccount.free;
        Exit;
      End;
  end;
end;
function TFormServer.TrylevelUp ( ids, attrortalentid: string; s,d,p,b,sh,h,  chanceA,chanceT,talentID,Age: integer; history,xp:string ): TLevelUp;
var
  MyQueryGamePlayers: TMyQuery;
  arnd: Integer;
  aPlayer: TSoccerPlayer;
  tsXP,tsXPHistory: TStringList;
  ConnGame : TMyConnection;
  label myexit;
begin
  // il player � gi� validato e conosco le chance e le altre info che mi servono
  Result.ids := ids;
  result.attrortalentid := attrortalentid;
  Result.value := false;
  aRnd := RndGenerate( 100 );
//ultimo valore 6 1% . calcolare numero calciatori reali a 6 su 500 calciatori
//Speed e heading incrementano al massimo di 1 e mai pi�
//Scelta direzione  Difesa esclude tiro e viceversa


  // creo un player virtuale
  aPlayer:= TSoccerPlayer.create(0,0,0,ids,'virtual','virtual','','1,1,1,1,1,1' );
  aPlayer.DefaultSpeed := s;
  aPlayer.Defaultdefense := d;
  aPlayer.DefaultPassing := p;
  aPlayer.DefaultBallControl := b;
  aPlayer.DefaultShot := sh;
  aPlayer.DefaultHeading := h;
  aplayer.Age := age;

  tsXP := TStringList.Create;
  tsXP.commaText := xp; // <-- init importante 17 talenti
  // rispettare esatto ordine

  aPlayer.xp_Speed         := StrToInt( tsXP[0]);
  aPlayer.xp_Defense       := StrToInt( tsXP[1]);
  aPlayer.xp_BallControl   := StrToInt( tsXP[2]);
  aPlayer.xp_Passing       := StrToInt( tsXP[3]);
  aPlayer.xp_Shot          := StrToInt( tsXP[4]);
  aPlayer.xp_Heading       := StrToInt( tsXP[5]);

  aPlayer.xpTal_GoalKeeper       := StrToInt( tsXP[6]);
  aPlayer.xpTal_Challenge        := StrToInt( tsXP[7]);
  aPlayer.xpTal_Toughness        := StrToInt( tsXP[8]);
  aPlayer.xpTal_Power            := StrToInt( tsXP[9]);
  aPlayer.xpTal_Crossing         := StrToInt( tsXP[10]);
  aPlayer.xptal_longpass         := StrToInt( tsXP[11]);
  aPlayer.xpTal_Experience       := StrToInt( tsXP[12]);
  aPlayer.xpTal_Dribbling        := StrToInt( tsXP[13]);
  aPlayer.xpTal_Bulldog          := StrToInt( tsXP[14]);
  aPlayer.xpTal_midOffensive     := StrToInt( tsXP[15]);
  aPlayer.xpTal_midDefensive     := StrToInt( tsXP[16]);
  aPlayer.xpTal_Bomb             := StrToInt( tsXP[17]);
  aPlayer.xpTal_PlayMaker        := StrToInt( tsXP[18]);
  aPlayer.xpTal_faul             := StrToInt( tsXP[19]);
  aPlayer.xpTal_marking          := StrToInt( tsXP[20]);
  aPlayer.xpTal_Positioning           := StrToInt( tsXP[21]);
  aPlayer.xpTal_freekicks        := StrToInt( tsXP[22]);


  tsXPHistory := TStringList.Create;
  tsXPHistory.commaText := HISTORY;
  aPlayer.History_Speed         := StrToInt( tsXPHistory[0]);  // riguarda solo le 6 stats
  aPlayer.History_Defense       := StrToInt( tsXPHistory[1]);
  aPlayer.History_BallControl   := StrToInt( tsXPHistory[2]);
  aPlayer.History_Passing       := StrToInt( tsXPHistory[3]);
  aPlayer.History_Shot          := StrToInt( tsXPHistory[4]);
  aPlayer.History_Heading       := StrToInt( tsXPHistory[5]);


  if Uppercase (attrortalentid)  = 'SPEED' then begin
    if aPlayer.xp_Speed >= xp_SPEED_POINTS then begin
      aPlayer.xp_Speed := aPlayer.xp_Speed - xp_SPEED_POINTS;
      tsXP[0]:= IntToStr(aPlayer.xp_Speed );
      if aPlayer.Age > 24 then goto MyExit; // dopo i 24 anni non incrementa pi� in speed    . esce con result.value = false
      if aRnd <= chanceA then begin
        if (aPlayer.History_Speed = 0) and (aPlayer.DefaultSpeed < 4) then begin // speed incrementa solo una volta e al amssimo a 4
          aPlayer.DefaultSpeed := aPlayer.DefaultSpeed + 1;
          aPlayer.History_Speed := aPlayer.History_Speed + 1;
          tsXPHistory[0]:= IntToStr( aPlayer.History_Speed ) ;
          Result.value:= True;
        end;
      end;
    end;
  end

  else if Uppercase (attrortalentid)  = 'DEFENSE' then begin
    if aPlayer.xp_Defense >= xp_DEFENSE_POINTS then begin
      aPlayer.xp_Defense := aPlayer.xp_Defense - xp_DEFENSE_POINTS;
      tsXP[1]:= IntToStr(aPlayer.xp_Defense );
      if aPlayer.Shot >= 3 then goto MyExit; // difesa / shot        . esce con result.value = false
      if aRnd <= chanceA then begin
        if aPlayer.DefaultDefense < 6 then begin
          if aPlayer.DefaultDefense +1 = 6 then Result.value := Can6 ( aPlayer, atDefense )
          else begin
            aPlayer.DefaultDefense := aPlayer.DefaultDefense + 1;
            aPlayer.History_Defense := aPlayer.History_Defense + 1;
            tsXPHistory[1]:= IntToStr( aPlayer.History_Defense ) ;
            Result.value:= True;
          end;
        end;
      end;
    end;
  end

  else if Uppercase (attrortalentid)  = 'PASSING' then begin
    if aPlayer.xp_Passing >= xp_PASSING_POINTS then begin
      aPlayer.xp_Passing := aPlayer.xp_Passing - xp_Passing_POINTS;
      tsXP[2]:= IntToStr(aPlayer.xp_Passing );
      if aRnd <= chanceA then begin
        if aPlayer.DefaultPassing < 6 then begin
          if aPlayer.DefaultPassing +1 = 6 then Result.value := Can6 ( aPlayer, atPassing )
          else begin
            aPlayer.DefaultPassing := aPlayer.DefaultPassing + 1;
            aPlayer.History_Passing := aPlayer.History_Passing + 1;
            tsXPHistory[2]:= IntToStr( aPlayer.History_Passing ) ;
            Result.value:= True;
          end;
        end;
      end;
    end;
  end

  else if Uppercase (attrortalentid)  = 'BALLCONTROL' then begin
    if aPlayer.xp_BallControl  >= xp_BALLCONTROL_POINTS then begin
      aPlayer.xp_BallControl := aPlayer.xp_BallControl - xp_BallControl_POINTS;
      tsXP[3]:= IntToStr(aPlayer.xp_BallControl );
      if aRnd <= chanceA then begin
        if aPlayer.DefaultBallControl < 6 then begin
          if aPlayer.DefaultBallControl +1 = 6 then Result.value := Can6 ( aPlayer, atBallControl )
          else begin
            aPlayer.DefaultBallControl := aPlayer.DefaultBallControl + 1;
            aPlayer.History_BallControl := aPlayer.History_BallControl + 1;
            tsXPHistory[3]:= IntToStr( aPlayer.History_BallControl ) ;
            Result.value:= True;
          end;
        end;
      end;
    end;
  end

  else if Uppercase (attrortalentid)  = 'SHOT' then begin

    if aPlayer.xp_Shot >= xp_SHOT_POINTS then begin
      aPlayer.xp_Shot := aPlayer.xp_Shot - xp_Shot_POINTS;
      tsXP[4]:= IntToStr(aPlayer.xp_Shot );
        if aPlayer.Defense >= 3 then goto MyExit;; // difesa / shot
      if aRnd <= chanceA then begin
        if aPlayer.DefaultShot < 6 then begin
          if aPlayer.DefaultShot +1 = 6 then Result.value :=Can6 ( aPlayer, atShot )
          else begin
            aPlayer.DefaultShot := aPlayer.DefaultShot + 1;
            aPlayer.History_Shot := aPlayer.History_Shot + 1;
            tsXPHistory[4]:= IntToStr( aPlayer.History_Shot ) ;
            Result.value:= True;
          end;
        end;
      end;
    end;
  end

  else if Uppercase (attrortalentid)  = 'HEADING' then begin

    if aPlayer.xp_Heading >= xp_HEADING_POINTS then begin
      aPlayer.xp_Heading := aPlayer.xp_Heading - xp_Heading_POINTS;
      tsXP[5]:= IntToStr(aPlayer.xp_Heading );
      if aRnd <= chanceA then begin
        if aPlayer.History_Heading = 0  then begin // Heading incrementa solo una volta
          if aPlayer.DefaultHeading < 6 then begin
            if aPlayer.DefaultHeading + 1 = 6 then Result.value :=Can6 ( aPlayer, atHeading )
            else begin
              aPlayer.DefaultHeading := aPlayer.DefaultHeading + 1;
              aPlayer.History_Heading := aPlayer.History_Heading + 1;
              tsXPHistory[5]:= IntToStr( aPlayer.History_Heading ) ;
              Result.value:= True;
            end;
          end;
        end;
      end;
    end;
  end


  // in caso di numerico id talent
  else begin
    case StrToInt(attrortalentid) of
      1: begin
        if aPlayer.xpTal_GoalKeeper >= xp_TAL_GOALKEEPER_POINTS then begin
          aPlayer.xpTal_GoalKeeper  := aPlayer.xpTal_GoalKeeper - xp_TAL_GOALKEEPER_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 1;
              tsXP[6]:= IntToStr(aPlayer.xpTal_GoalKeeper );
              Result.value:= True;
            end;
          end;
        end;
      end;
      2: begin
        if aPlayer.xpTal_Challenge >= xp_TAL_CHALLENGE_POINTS then begin
          aPlayer.xpTal_challenge  := aPlayer.xpTal_challenge - xp_TAL_CHALLENGE_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 2;
              tsXP[7]:= IntToStr(aPlayer.xpTal_challenge );
              Result.value:= True;
            end;
          end;
        end;
      end;
      3: begin
        if aPlayer.xpTal_Toughness >= xp_TAL_TOUGHNESS_POINTS then begin
          aPlayer.xpTal_Toughness  := aPlayer.xpTal_Toughness - xp_TAL_TOUGHNESS_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 3;
              tsXP[8]:= IntToStr(aPlayer.xpTal_Toughness );
              Result.value:= True;
            end;
          end;
        end;

      end;

      4: begin
        if aPlayer.xpTal_power >= xp_TAL_POWER_POINTS then begin
          aPlayer.xpTal_power  := aPlayer.xpTal_power - xp_TAL_POWER_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 4;
              tsXP[9]:= IntToStr(aPlayer.xpTal_power );
              Result.value:= True;
            end;
          end;
        end;
      end;

      5: begin
        if aPlayer.xpTal_Crossing >= xp_TAL_CROSSING_POINTS then begin
          aPlayer.xpTal_Crossing  := aPlayer.xpTal_Crossing - xp_TAL_CROSSING_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 5;
              tsXP[10]:= IntToStr(aPlayer.xpTal_Crossing );
              Result.value:= True;
            end;
          end;
        end;
      end;

      6: begin
        if aPlayer.xptal_longpass >= xp_TAL_LONGPASS_POINTS then begin
          aPlayer.xptal_longpass  := aPlayer.xptal_longpass - xp_TAL_LONGPASS_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 6;
              tsXP[11]:= IntToStr(aPlayer.xptal_longpass );
              Result.value:= True;
            end;
          end;
        end;
      end;

      7: begin
        if aPlayer.xpTal_experience >= xp_TAL_EXPERIENCE_POINTS then begin
          aPlayer.xpTal_experience  := aPlayer.xpTal_experience - xp_TAL_EXPERIENCE_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 7;
              tsXP[12]:= IntToStr(aPlayer.xpTal_experience );
              Result.value:= True;
            end;
          end;
        end;
      end;

      8: begin
        if aPlayer.xpTal_dribbling >= xp_TAL_DRIBBLING_POINTS then begin
          aPlayer.xpTal_dribbling  := aPlayer.xpTal_dribbling - xp_TAL_DRIBBLING_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 8;
              tsXP[13]:= IntToStr(aPlayer.xpTal_dribbling );
              Result.value:= True;
            end;
          end;
        end;
      end;

      9: begin
        if aPlayer.xpTal_bulldog >= xp_TAL_BULLDOG_POINTS then begin
          aPlayer.xpTal_bulldog  := aPlayer.xpTal_bulldog - xp_TAL_BULLDOG_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 9;
              tsXP[14]:= IntToStr(aPlayer.xpTal_bulldog );
              Result.value:= True;
            end;
          end;
        end;
      end;

      10: begin
        if aPlayer.xpTal_midoffensive >= xp_TAL_MIDOFFENSIVE_POINTS then begin
          aPlayer.xpTal_midoffensive  := aPlayer.xpTal_midoffensive - xp_TAL_MIDOFFENSIVE_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 10;
              tsXP[15]:= IntToStr(aPlayer.xpTal_midoffensive );
              Result.value:= True;
            end;
          end;
        end;
      end;

      11: begin
        if aPlayer.xpTal_middefensive >= xp_TAL_MIDDEFENSIVE_POINTS then begin
          aPlayer.xpTal_middefensive  := aPlayer.xpTal_middefensive - xp_TAL_MIDDEFENSIVE_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 11;
              tsXP[16]:= IntToStr(aPlayer.xpTal_middefensive );
              Result.value:= True;
            end;
          end;
        end;
      end;

      12: begin
        if aPlayer.xpTal_bomb >= xp_TAL_BOMB_POINTS then begin
          aPlayer.xpTal_bomb  := aPlayer.xpTal_bomb - xp_TAL_BOMB_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 12;
              tsXP[17]:= IntToStr(aPlayer.xpTal_bomb );
              Result.value:= True;
            end;
          end;
        end;
      end;

      13: begin
        if aPlayer.xpTal_PlayMaker >= xp_TAL_PLAYMAKER_POINTS then begin
          aPlayer.xpTal_PlayMaker  := aPlayer.xpTal_PlayMaker - xp_TAL_PLAYMAKER_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 13;
              tsXP[18]:= IntToStr(aPlayer.xpTal_PlayMaker );
              Result.value:= True;
            end;
          end;
        end;
      end;

      14: begin
        if aPlayer.xpTal_Faul >= xp_TAL_FAUL_POINTS then begin
          aPlayer.xpTal_Faul  := aPlayer.xpTal_Faul - xp_TAL_FAUL_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 14;
              tsXP[19]:= IntToStr(aPlayer.xpTal_Faul );
              Result.value:= True;
            end;
          end;
        end;
      end;

      15: begin
        if aPlayer.xpTal_Marking >= xp_TAL_MARKING_POINTS then begin
          aPlayer.xpTal_Marking  := aPlayer.xpTal_Marking - xp_TAL_MARKING_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 15;
              tsXP[20]:= IntToStr(aPlayer.xpTal_Marking );
              Result.value:= True;
            end;
          end;
        end;
      end;

      16: begin
        if aPlayer.xpTal_Positioning >= xp_TAL_Positioning_POINTS then begin
          aPlayer.xpTal_Positioning  := aPlayer.xpTal_Positioning - xp_TAL_Positioning_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 16;
              tsXP[21]:= IntToStr(aPlayer.xpTal_Positioning );
              Result.value:= True;
            end;
          end;
        end;
      end;

      17: begin
        if aPlayer.xpTal_Positioning >= xp_TAL_FREEKICKS_POINTS then begin
          aPlayer.xpTal_freekicks  := aPlayer.xpTal_freekicks - xp_TAL_FREEKICKS_POINTS;
          if aPlayer.TalentID = 0 then begin
            if aRnd <= chanceT then begin
              aPlayer.TalentId := 17;
              tsXP[22]:= IntToStr(aPlayer.xpTal_freekicks );
              Result.value:= True;
            end;
          end;
        end;
      end;

    end;

  end;

//   le commatext sono gi� pronte per storarle
//  devo aggiornare anche in caso di false perch� ho speso i punti XP
    ConnGame := TMyConnection.Create(nil);
    ConnGame.Server := MySqlServerGame;
    ConnGame.Username:='root';
    Conngame.Password:='root';
    ConnGame.Database:='game';
    ConnGame.Connected := True;

  if Result.value then begin

    MyQueryGamePlayers := TMyQuery.Create(nil);
    MyQueryGamePlayers.Connection := ConnGame;   // game

    MyQueryGamePlayers.SQL.text := 'UPDATE game.players SET ' +
                                   'speed='+  IntToStr(aPlayer.DefaultSpeed) + ','+
                                   'defense='+IntToStr(aPlayer.Defaultdefense) + ','+
                                   'passing='+IntToStr(aPlayer.DefaultPassing) + ','+
                                   'ballcontrol='+IntToStr(aPlayer.DefaultBallControl) + ','+
                                   'shot='+IntToStr(aPlayer.DefaultShot)  + ','+
                                   'heading='+ IntToStr(aPlayer.DefaultHeading) + ','+
                                   'talent=' + IntToStr(aPlayer.TalentId) + ','+
                                   'xp="' + tsXP.CommaText + '",' +
                                   'history="' + tsXPhistory.CommaText + '" WHERE guid =' + ids;
    MyQueryGamePlayers.Execute ;
    MyQueryGamePlayers.Free;
  end
  else begin  // aggirno solo la perdita di xp
    MyQueryGamePlayers := TMyQuery.Create(nil);
    MyQueryGamePlayers.Connection := ConnGame;   // game

    MyQueryGamePlayers.SQL.text := 'UPDATE game.players SET ' +
                                   'xp="' + tsXP.CommaText + '" WHERE guid =' + ids;
    MyQueryGamePlayers.Execute ;
    MyQueryGamePlayers.Free;

  end;
    ConnGame.Connected := false;
    ConnGame.Free;
myexit:
  tsXP.Free;
  tsXPHistory.Free;
  aPlayer.free;

end;
function TFormServer.isReserveSlot (CellX, CellY: integer): boolean;
begin
  Result:= false;
  if (CellX = 0) and ( CellY = 3) then
    Exit;
  if (CellX = 11) and ( CellY = 3) then
    Exit;
  // qui ho gi� escluso i portieri
  if (CellX <= 0) or ( CellX  >= 11) then
    result := True;
end;

function TFormServer.can6 (aPlayer: TSoccerPlayer; at : TAttributeName): boolean;
var
  aRnd: Integer;
begin
  // qui � gi� passato dal normale percA... 1 su 1000 ce la fa....
  aRnd := RndGenerate(1000);
  if aPlayer.Tal_GoalKeeper > 0 then aRnd := 2;  // porieri a 6 non esistono per ora
  if aRnd = 1 then begin

    if at = AtDefense then begin
      aPlayer.DefaultDefense := 6;
      aPlayer.History_Defense := aPlayer.History_Defense + 1;
    end
    else if at = atBallControl then begin
      aPlayer.DefaultBallControl := 6;
      aPlayer.History_BallControl := aPlayer.History_BallControl + 1;
    end
    else if at = atPassing then begin
      aPlayer.DefaultPassing := 6;
      aPlayer.History_Passing := aPlayer.History_Passing + 1;
    end
    else if at = atShot then begin
      aPlayer.DefaultShot := 6;
      aPlayer.History_Shot := aPlayer.History_Shot + 1;
    end
    else if at = atHeading then begin
      aPlayer.DefaultHeading := 6;
      aPlayer.History_Heading := aPlayer.History_Heading + 1;
    end
  end;

end;

function TFormServer.GetTeamStream ( GuidTeam: integer ) : string;
var
  CompressedStream: TZCompressionStream;
  MM, MM2 : TMemoryStream;
  SS: TStringStream;
  MyQueryTeam: TMyQuery;
  MyQueryGamePlayers: TMyQuery;
  ini : TIniFile;
  i,age: Integer;
  AT: string;
  tmps: string[255];
  tmpi: Integer;
  tmpb: Byte;
  ConnGame : TMyConnection;
  face: integer;
begin

  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;
  // Team in generale
  MyQueryTeam := TMyQuery.Create(nil);
  MyQueryTeam.Connection := ConnGame;   // game
  MyQueryTeam.SQL.text := 'SELECT guid, worldteam, teamName, uniforma, uniformh, nextha, mi, points,matchesplayed,money,rank FROM game.teams where guid = ' + IntToStr(GuidTeam) ;

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

  MyQueryTeam.Free;


  // Singoli players
  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game
  MyQueryGamePlayers.SQL.text := 'SELECT guid,Team,Name,Matches_Played,Matches_Left,'+
                                                  'talent, speed,defense,passing,ballcontrol,heading,shot,stamina,'+
                                                  'formation_x,formation_y,injured,totyellowcard,disqualified,xp,history,onmarket,face'+
                                                  ' from game.players WHERE team =' + IntToStr(GuidTeam);

  MyQueryGamePlayers.Execute ;
  tmpi:= MyQueryGamePlayers.RecordCount;
  MM.Write( @tmpi , SizeOf(Byte) ) ;

  for I := MyQueryGamePlayers.RecordCount -1 downto 0  do begin
    tmpi:= MyQueryGamePlayers.FieldByName('guid').AsInteger;
    MM.Write( @tmpi, sizeof(integer) );

    tmps := MyQueryGamePlayers.FieldByName('name').AsString;
    MM.Write( @tmps[0] , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa

    tmpi := MyQueryGamePlayers.FieldByName('Matches_Played').AsInteger;
    MM.Write( @tmpi, sizeof(SmallInt) );

    tmpi := MyQueryGamePlayers.FieldByName('Matches_Left').AsInteger;
    MM.Write( @tmpi, sizeof(SmallInt) );

    Age:= Trunc(  MyQueryGamePlayers.FieldByName('Matches_Played').AsInteger  div Soccerbrainv3.SEASON_MATCHES) + 18 ;
    MM.Write( @Age, sizeof(byte) );

    tmpb := MyQueryGamePlayers.FieldByName('Talent').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpi := MyQueryGamePlayers.FieldByName('stamina').AsInteger;
    MM.Write( @tmpi, sizeof(ShortInt) );

    tmpb:= MyQueryGamePlayers.FieldByName('speed').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyQueryGamePlayers.FieldByName('defense').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyQueryGamePlayers.FieldByName('passing').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyQueryGamePlayers.FieldByName('ballcontrol').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyQueryGamePlayers.FieldByName('shot').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyQueryGamePlayers.FieldByName('heading').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );

    tmpb:= MyQueryGamePlayers.FieldByName('formation_x').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );
    tmpb:= MyQueryGamePlayers.FieldByName('formation_y').AsInteger;
    MM.Write( @tmpb , sizeof(ShortInt) );

    tmpb := MyQueryGamePlayers.FieldByName('injured').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := MyQueryGamePlayers.FieldByName('totyellowcard').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := MyQueryGamePlayers.FieldByName('disqualified').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );
    tmpb := MyQueryGamePlayers.FieldByName('onmarket').AsInteger;
    MM.Write( @tmpb, sizeof(byte) );

    face:= MyQueryGamePlayers.FieldByName('face').AsInteger;
    MM.Write( @face , sizeof(integer) );

    tmps := MyQueryGamePlayers.FieldByName('history').AsString;
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa
    tmps := MyQueryGamePlayers.FieldByName('xp').AsString;
    MM.Write( @tmps , length ( tmps ) +1 );      // +1 byte 0 indica lunghezza stringa


    MyQueryGamePlayers.Next;

  end;

  ini.Free;
  MyQueryGamePlayers.Free;
  ConnGame.Connected := false;
  ConnGame.Free;

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
function TFormServer.GetListActiveBrainStream  : string;
var
  CompressedStream: TZCompressionStream;
  SS: TStringStream;
  i: Integer;
  MM,MM2: TMemoryStream;

begin
            { TODO -cfuturismi : in futuro overload con nazione, team username ecc...una query in memoria }

  WaitForSingleObject(Mutex,INFINITE);
  if BrainManager.lstbrain.count > 0 then begin
    MM := TMemoryStream.Create;
    MM.Write( @BrainManager.lstbrain.count , SizeOf(word) );

    for i := BrainManager.lstbrain.count -1 downto 0 do begin

      MM.Write( @BrainManager.lstBrain[i].BrainIDS, Length (BrainManager.lstBrain[i].BrainIDS) +1 );
      MM.Write( @BrainManager.lstBrain[i].Score.UserName[0], Length (BrainManager.lstBrain[i].Score.UserName[0] ) +1 );
      MM.Write( @BrainManager.lstBrain[i].Score.UserName[1], Length (BrainManager.lstBrain[i].Score.UserName[1]) +1 );
      MM.Write( @BrainManager.lstBrain[i].Score.Team[0], Length (BrainManager.lstBrain[i].Score.Team[0]) +1 );
      MM.Write( @BrainManager.lstBrain[i].Score.Team[1], Length (BrainManager.lstBrain[i].Score.Team[1]) +1 );
      MM.Write( @BrainManager.lstBrain[i].Score.Country[0], sizeof (word ) );
      MM.Write( @BrainManager.lstBrain[i].Score.Country[1], sizeof (word ) );
      MM.Write( @BrainManager.lstBrain[i].Score.Gol[0], sizeof (byte ) );
      MM.Write( @BrainManager.lstBrain[i].Score.Gol[1], sizeof (byte ) );
      MM.Write( @BrainManager.lstBrain[i].minute, sizeof (byte ) );

    end;
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
function TFormServer.GetMarketPlayers ( MyTeam, Maxvalue: Integer) : string;
var
  CompressedStream: TZCompressionStream;
  SS: TStringStream;
  i: Integer;
  MM,MM2: TMemoryStream;
  MyQueryGamePlayers,MyQuerymarket,MyQueryGameTeams: TMyQuery;
  aPlayer: TSoccerPlayer;
  mValue : Integer;
  price,MoneyA,MoneyB,GuidTeamSell: Integer;
  ts: TStringList;

  name,history,xp : Shortstring;
  guidplayer, sellprice ,  guidteam,  speed ,  defense,  passing, ballcontrol, shot, heading, talent,matches_played,matches_left : Integer;
  Count: Integer;
  ConnGame : TMyConnection;
begin
// MyTeam � except , non trova i suoi giocatori in vendita
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;


  MyQuerymarket := TMyQuery.Create(nil);
  MyQuerymarket.Connection := ConnGame;   // game

  MyQuerymarket.SQL.text := 'SELECT *  FROM game.market where sellprice <=' + IntToStr(Maxvalue) + ' and guidteam <> ' +
                             IntToStr( MyTeam)  +' limit 40';
  MyQuerymarket.Execute ;

  Count := MyQuerymarket.RecordCount;

    MM := TMemoryStream.Create;
    MM.Write( @Count , SizeOf(word) );

    for i := MyQuerymarket.RecordCount -1 downto 0 do begin
      guidplayer:= MyQuerymarket.FieldByName('guidplayer').asInteger;
      name := MyQuerymarket.FieldByName('name').AsString;
      sellprice:= MyQuerymarket.FieldByName('sellprice').asInteger;
//      guidteam:= MyQuerymarket.FieldByName('guidteam').asInteger;
      speed:= MyQuerymarket.FieldByName('speed').asInteger;
      defense:= MyQuerymarket.FieldByName('defense').asInteger;
      passing:= MyQuerymarket.FieldByName('passing').asInteger;
      ballcontrol:= MyQuerymarket.FieldByName('ballcontrol').asInteger;
      shot:= MyQuerymarket.FieldByName('shot').asInteger;
      heading:= MyQuerymarket.FieldByName('heading').asInteger;
      talent:= MyQuerymarket.FieldByName('talent').asInteger;
//      history := MyQuerymarket.FieldByName('history').AsString;
//      xp := MyQuerymarket.FieldByName('xp').AsString;
      matches_played:= MyQuerymarket.FieldByName('matches_played').asInteger;
      matches_left:= MyQuerymarket.FieldByName('matches_left').asInteger;

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
      MM.Write( @talent, sizeof ( byte ) );

//      MM.Write( @history[0], Length (history) +1 );
//      MM.Write( @xp[0], Length (xp) +1 );

      MM.Write( @matches_played, sizeof ( word ) );
      MM.Write( @matches_left, sizeof ( word ) );

      MyQuerymarket.Next;
    end;

    MyQuerymarket.Free;
    ConnGame.Connected := false;
    ConnGame.Free;

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

function TFormServer.GetMarketValueTeam ( Guidteam: Integer ) : Integer;
var
  MyQueryGamePlayers: TMyQuery;
  i,pTot: Integer;
  ConnGame : TMyConnection;
begin
  Result := 0;
  // Singoli players   . uguale a getmarketvalue
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;


  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game
  MyQueryGamePlayers.SQL.text := 'SELECT talent, speed,defense,passing,ballcontrol,heading,shot,matches_left from game.players WHERE team =' + IntToStr(GuidTeam);

  MyQueryGamePlayers.Execute ;
  for I := 0 to MyQueryGamePlayers.RecordCount -1 do begin
    if MyQueryGamePlayers.FieldByName('talent').AsString <> 'goalkeeper' then

    pTot :=  Trunc ( MyQueryGamePlayers.FieldByName('Speed').AsInteger  *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('Speed').AsInteger] +
               MyQueryGamePlayers.FieldByName('Defense').AsInteger *   MARKET_VALUE_ATTRIBUTE [ MyQueryGamePlayers.FieldByName('Defense').AsInteger] +
               MyQueryGamePlayers.FieldByName('Passing').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('Passing').AsInteger] +
               MyQueryGamePlayers.FieldByName('BallControl').AsInteger *   MARKET_VALUE_ATTRIBUTE [ MyQueryGamePlayers.FieldByName('BallControl').AsInteger] +
               MyQueryGamePlayers.FieldByName('Shot').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('Shot').AsInteger] +
               MyQueryGamePlayers.FieldByName('Heading').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('Heading').AsInteger])
    else
    pTot :=  Trunc ((MyQueryGamePlayers.FieldByName('Defense').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('Defense').AsInteger]
               * MARKET_VALUE_ATTRIBUTE_DEFENSE_GK) +
               MyQueryGamePlayers.FieldByName('Passing').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('Passing').AsInteger]  );

    if MyQueryGamePlayers.FieldByName('talent').AsString <> '' then pTot := Trunc(pTot * MARKET_VALUE_TALENT) ;
    Result := Result + pTot;
    MyQueryGamePlayers.Next ;
  end;

  MyQueryGamePlayers.Free;
  ConnGame.Connected := false;
  ConnGame.Free;

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
    if BrainManager.lstBrain.Count <  StrToInt( Edit1.Text ) then
      CreateRandomBotMatch;
  end;
  // ore 20.24 900-1000 partite
  // ora 16 19.59 400-500

  // al momento ne fa 50 al massimo

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
  MyQueryWC.Connection := ConnWorld;   // world
  MyQueryWC.SQL.Text := 'SELECT guid, name FROM world.countries order by guid';
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
  ConnWorld.Database:='World';
  ConnWorld.Connected := True;

  TsWorldCountries.Clear;
  TsWorldCountries.StrictDelimiter := True;
  MyQueryWC := TMyQuery.Create(nil);
  MyQueryWC.Connection := ConnWorld;   // world
  MyQueryWC.SQL.Text := 'SELECT guid, name FROM world.countries order by guid';
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
  MyQueryWT: TMyQuery;
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

  MyQueryWT := TMyQuery.Create(nil);
  MyQueryWT.Connection := ConnWorld;   // world
  MyQueryWT.SQL.Text := 'SELECT guid, name FROM world.teams where country = ' + CountryID + ' order by name';
  MyQueryWT.Execute;

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
  ConnWorld.Database:='World';
  ConnWorld.Connected := True;

  MyQueryWT := TMyQuery.Create(nil);
  MyQueryWT.Connection := ConnWorld;   // world
  MyQueryWT.SQL.Text := 'SELECT guid, name FROM world.teams where country = ' + IntToStr(CountryID) + ' order by name';
  MyQueryWT.Execute;

  for I := 0 to MyQueryWT.RecordCount -1 do begin
    TsWorldTeams[CountryId].Add( MyQueryWT.FieldByName ('guid').AsString + '=' + MyQueryWT.FieldByName ('name').AsString );
    MyQueryWT.Next;
  end;

  MyQueryWT.Free;
  ConnWorld.Connected := false;
  ConnWorld.Free;

end;
function TFormServer.GetQueueOpponent (WorldTeam : integer; Rank, NextHA: byte ): TWSocketThrdClient;
var
  i: Integer;
begin
  // WorldTeam esclude automaticamente anche se stessi
  Result := nil;
{  for I := 0 to Queue.Count -1 do begin
    if (Queue[i].WorldTeam <> WorldTeam) and (abs (Queue[i].MarketValueTeam - MarketValueTeam ) <= GAP_QUEUE)
      and ( Queue[i].nextHA <> nextHA ) and not (queue[i].Marked) // non marcato, cio� non gi� in gioco
    then begin
      result := Queue[i] ;
      Exit;
    end;
  end;      }
  for I := 0 to Queue.Count -1 do begin
    if (Queue[i].WorldTeam <> WorldTeam) and (Queue[i].rank = Rank )
      and ( Queue[i].nextHA <> nextHA ) and not (queue[i].Marked) // non marcato, cio� non gi� in gioco
    then begin
      result := Queue[i] ;
      Exit;
    end;
  end;

end;
procedure TFormServer.GetGuidTeamOpponentBOT ( WorldTeam: integer; Rank, NextHA: byte; var BotGuidTeam: Integer; var BotUserName: string );
var
  MyQueryGameTeams: TMyQuery;
  i,MinGap,MaxGap: Integer;
  ConnGame : TMyConnection;
begin
    BotGuidTeam := 0;
    BotUserName := '';
 //   MinGap := MarketValueTeam - GAP_QUEUE;
 //   MaxGap := MarketValueTeam + GAP_QUEUE;
  // WorldTeam esclude automaticamente anche se stessi. Qui cerco sul db un bot
    ConnGame := TMyConnection.Create(nil);
    ConnGame.Server := MySqlServerGame;
    ConnGame.Username:='root';
    Conngame.Password:='root';
    ConnGame.Database:='game';
    ConnGame.Connected := True;


    MyQueryGameTeams := TMyQuery.Create(nil);
    MyQueryGameTeams.Connection := ConnGame;   // game
{    MyQueryGameTeams.SQL.text := 'SELECT guid, username from game.teams INNER JOIN realmd.account ON realmd.account.id = game.teams.account WHERE (MarketValue between ' +
                                  IntToStr(MinGap) + ' and ' + IntToStr(MaxGap) + ') and (WorldTeam <> ' + IntTostr(WorldTeam) +
                                  ') and (bot <> 0' +
                                  ') and (nextha <> ' + IntToStr(nextha) +
                                  ') order by rand() limit 1';  }
    MyQueryGameTeams.SQL.text := 'SELECT guid, username from game.teams INNER JOIN realmd.account ON realmd.account.id = game.teams.account WHERE (rank=' +
                                  IntToStr(Rank) + ') and (WorldTeam <> ' + IntTostr(WorldTeam) +
                                  ') and (bot <> 0' +
                                  ') and (nextha <> ' + IntToStr(nextha) +
                                  ') order by rand() limit 1';
    MyQueryGameTeams.Execute;
{SELECT
  guid, username
FROM
  game.teams
  INNER JOIN realmd.account ON realmd.account.id = game.teams.account
WHERE
  guid = 41;  }
    if MyQueryGameTeams.RecordCount > 0 then begin
      BotGuidTeam := MyQueryGameTeams.FieldByName('Guid').AsInteger;
      BotUserName := MyQueryGameTeams.FieldByName('username').AsString;
    end;
    MyQueryGameTeams.Free;
    ConnGame.Connected := false;
    ConnGame.Free;

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
  i,i2,i3: Integer;
  CliOpponentGuidTeam : TWSocketThrdClient;
  ServerOpponent: array [0..1] of TServerOpponent;
  aBrain: TSoccerBrain;
  MyQueryGamePlayers : TMyQuery;
  OpponentBOT: TServerOpponent;
  BrainIDS,UserName0,UserName1: string;
  Cli: TWSocketClient;
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

    CliOpponentGuidTeam := GetQueueOpponent ( Queue[i].WorldTeam , Queue[i].rank, queue[i].nextHA ); // worldteam diversa in opponent, no Bologna vs Bologna
    if CliOpponentGuidTeam <> nil then  begin   // ho trovato un opponent normale
      if queue[i].nextHA = 0 then begin
        ServerOpponent[0].GuidTeam := Queue[i].GuidTeam;
        ServerOpponent[0].UserName := Queue[i].UserName;
        ServerOpponent[0].CliID := Queue[i].CliId;
        ServerOpponent[1].GuidTeam := CliOpponentGuidTeam.GuidTeam ;
        ServerOpponent[1].UserName := CliOpponentGuidTeam.UserName ;
        ServerOpponent[1].CliID := CliOpponentGuidTeam.CliId;
      end
      else begin
        ServerOpponent[1].GuidTeam := Queue[i].GuidTeam;
        ServerOpponent[1].UserName := Queue[i].UserName;
        ServerOpponent[1].CliID := Queue[i].CliId;
        ServerOpponent[0].GuidTeam := CliOpponentGuidTeam.GuidTeam ;
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
      GetGuidTeamOpponentBOT ( Queue[i].WorldTeam , Queue[i].rank, queue[i].nextHA, OpponentBOT.GuidTeam,OpponentBOT.UserName   ); // worldteam diversa in opponent, no Bologna vs Bologna
      if OpponentBOT.GuidTeam <> 0 then  begin   // ho trovato un opponent BOT
        if queue[i].nextHA = 0 then begin
          ServerOpponent[0].GuidTeam := Queue[i].GuidTeam;
          ServerOpponent[0].UserName := Queue[i].UserName;
          ServerOpponent[0].CliID := Queue[i].CliId;
          ServerOpponent[1].GuidTeam := OpponentBOT.GuidTeam ;
          ServerOpponent[1].UserName := OpponentBOT.UserName ;
          ServerOpponent[1].bot := True;
          ServerOpponent[1].CliId := 0;
        end
        else begin
          ServerOpponent[1].GuidTeam := Queue[i].GuidTeam;
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
    BrainIDS :=  GetBrainIds ( IntToStr(ServerOpponent[0].GuidTeam ) , IntToStr(ServerOpponent[1].GuidTeam )) ;

    // creo un brain che lavori in una data cartella
    aBrain := TSoccerBrain.create ( Brainids );


    // se � un bot preparo la formazione direttamente sul db
    if ServerOpponent[0].bot then CreateFormationTeam  (ServerOpponent[0].GuidTeam);
    if ServerOpponent[1].bot then CreateFormationTeam  (ServerOpponent[1].GuidTeam);
    // creo in quella data cartella match.ini
    //LI LEGO PER SEMPRE

    // <--SaveData 000 appen a fatto
      if not ServerOpponent[0].bot  then begin
        aBrain.Score.CliId[0] := ServerOpponent[0].CliID ;   //se non � un bot riceve i messaggi TCP
        Cli :=  GetTCPClient  (  ServerOpponent[0].CliID );
        if Cli <> nil then begin
          Cli.Brain := TObject(aBrain);   // tcpserver[i].brain
          Cli :=  GetTCPClientQueue  (  ServerOpponent[0].CliID );
          Cli.Marked := True; // dopo lo rimuove da queue  . � uno dei 2 serveropponent. devo trovare anche l'altro
          aBrain.dir_log := dir_log  ;
          aBrain.LogUser [0] := Cli.Flags;
        end;
      end;
      if not ServerOpponent[1].bot  then begin
        aBrain.Score.CliId[1] := ServerOpponent[1].CliID ;  ; //se non � un bot riceve i messaggi TCP
        Cli :=  GetTCPClient  (  ServerOpponent[1].CliID );
        if Cli <> nil then begin
          Cli.Brain := TObject(aBrain);   // tcpserver[i].brain
          Cli :=  GetTCPClientQueue  (  ServerOpponent[1].CliID );
          Cli.Marked := True; // dopo lo rimuove da queue  . � uno dei 2 serveropponent. devo trovare anche l'altro
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
      CreateAndLoadMatch(  aBrain, ServerOpponent[0].GuidTeam , ServerOpponent[1].GuidTeam, ServerOpponent[0].Username,  ServerOpponent[1].Username );
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
function TFormServer.GetbrainIds ( GuidTeam0, GuidTeam1: string ) : string;
var
  myDate : TDateTime;
  myYear, myMonth, myDay : word;
  myHour, myMin, mySec, myMilli : word;
  brainIds: string;
  i: Integer;
begin

    DecodeDateTime(Now, myYear, myMonth, myDay,
                   myHour, myMin, mySec, myMilli);
    BrainIDS:= IntToStr(myYear)  + Format('%.*d',[2, myMonth]) + Format('%.*d',[2, myDay]) + '_' +
    Format('%.*d',[2, myHour])  + '.' + Format('%.*d',[2, myMin]) + '.' +  Format('%.*d',[2, mySec])+  '_' +
    GuidTeam0  + '.' + GuidTeam1  ;

    Result := brainIds;
end;
procedure TFormServer.CreateMatchBOTvsBOT (   GuidTeam0, GuidTeam1: integer; Username0, UserName1: string );
var
  abrain: TSoccerBrain;
  BrainIDS: string;
begin
    // creo e svuoto la dir_data.brainIds  e la relativa ftp
    // qui creo effettivamente il match anche tra bot
//    GuidTeam0:=9;
//    GuidTeam1:=33;
    BrainIDS := getBrainIds ( IntToStr(GuidTeam0 ) , IntToStr(GuidTeam1 )) ;
    // creo un brain che lavori in una data cartella
    aBrain := TSoccerBrain.create ( Brainids);
    //  � un bot preparo la formazione direttamente sul db
      CreateFormationTeam  (GuidTeam0);
      CreateFormationTeam  (GuidTeam1);
      aBrain.dir_log := dir_log  ;
      if CheckBox2.Checked then begin
         // aBrain.dir_log := dir_log;
          aBrain.LogUser [0] := 1;
          aBrain.LogUser [1] := 1;
      end;

      WaitForSingleObject(Mutex,INFINITE);
      CreateAndLoadMatch(  aBrain, GuidTeam0 , GuidTeam1, UserName0, UserName1 );
      BrainManager.AddBrain(aBrain );
      ReleaseMutex(Mutex);

      brainManager.Input ( aBrain,   BrainIDS + '000' ) ;
      aBrain.Score.AI[0]:= True;
      aBrain.Score.AI[1]:= True;

end;
procedure TFormServer.CreateAndLoadMatch (  brain: TSoccerBrain; GuidTeam0, GuidTeam1: integer; Username0, UserName1: string );
var
  ini000: TIniFile;
  TT,age: Integer;
  i,pcount,nMatchesplayed,nMatchesLeft,aCellX,aCellY,aTeam: integer;
  TvCell,TvReserveCell,aPoint: TPoint;
  FC: TFormationCell;
  GuidTeam: array[0..1] of Integer;
  UserName: array[0..1] of string;
  MyQueryGameTeams,MyQueryGamePlayers,MyQueryWT : TMyQuery;
  AT,aRole: string;
  Dummy: word;
  Sp: TSoccerPlayer;
  aName, aSurname,  aTalents,Attributes,aIds: string;
  Injured: Integer;
  ConnGame : TMyConnection;
begin

  GuidTeam[0]:= Guidteam0;
  GuidTeam[1]:= Guidteam1;
  UserName[0]:= Username0;
  UserName[1]:= Username1;
  // leggo dal db, scrivo su dir_data

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
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  for I := 0 to 1 do begin

    MyQueryGameTeams := TMyQuery.Create(nil);
    MyQueryGameTeams.Connection := ConnGame;   // game
    MyQueryGameTeams.SQL.text := 'SELECT guid,worldteam,uniforma,uniformh,mi from game.teams WHERE guid = ' + IntToStr(GuidTeam[i]);
    MyQueryGameTeams.Execute;

    MyQueryWT := TMyQuery.Create(nil);
    MyQueryWT.Connection := ConnGame;   // world
    MyQueryWT.SQL.text := 'SELECT name, country from world.teams WHERE guid = ' + MyQueryGameTeams.FieldByName('worldteam').AsString ;
    MyQueryWT.Execute;


    brain.Score.UserName [i] := Username [I];
    brain.Score.Team [i] :=  MyQueryWT.fieldbyname ('name').asstring;
    brain.Score.TeamGuid [i] := MyQueryGameTeams.fieldbyname ('guid').AsInteger  ;
    brain.Score.Country [i] := MyQueryWT.fieldbyname ('country').AsInteger  ;
    brain.Score.TeamMI [i] := MyQueryGameTeams.fieldbyname ('mi').AsInteger;

    if i = 0 then
      brain.Score.Uniform [i] :=  MyQueryGameTeams.fieldbyname ('uniformh').asstring
    else
      brain.Score.Uniform [i] :=  MyQueryGameTeams.fieldbyname ('uniforma').asstring;


    brain.Score.Gol [i] := 0;


    MyQueryWT.Free;
    MyQueryGameTeams.Free;
  end;

  pCount:=0;

  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game

  for TT := 0 to 1 do begin

    MyQueryGamePlayers.SQL.text := 'SELECT guid,Team,Name,Matches_Played,Matches_Left,'+
                                                    'talent, speed,defense,passing,ballcontrol,heading,shot,stamina,'+
                                                    'formation_x,formation_y,injured,totyellowcard,disqualified,face'+
                                                    ' from game.players WHERE team =' + IntToStr(GuidTeam[TT]);

    MyQueryGamePlayers.Execute ;


    for I := 0 to MyQueryGamePlayers.RecordCount -1 do begin
      aSurname := MyQueryGamePlayers.FieldByName('name').AsString ;
      nMatchesplayed := MyQueryGamePlayers.FieldByName('Matches_Played').AsInteger;
      nMatchesLeft := MyQueryGamePlayers.FieldByName('Matches_Left').AsInteger;

      if MyQueryGamePlayers.FieldByName('Talent').AsInteger > 0 then
        aTalents := tsTalents[MyQueryGamePlayers.FieldByName('Talent').AsInteger-1]   // -1 ok
      else begin
        aTalents := '';
      end;

      Attributes := MyQueryGamePlayers.FieldByName('speed').Asstring + ',' + MyQueryGamePlayers.FieldByName('defense').Asstring +
            ',' + MyQueryGamePlayers.FieldByName('passing').Asstring + ',' + MyQueryGamePlayers.FieldByName('ballcontrol').Asstring  +
            ',' + MyQueryGamePlayers.FieldByName('shot').Asstring + ',' + MyQueryGamePlayers.FieldByName('heading').Asstring;

      aIds :=   MyQueryGamePlayers.FieldByName('guid').AsString;

      aTeam := TT;

      // la formationcells determina il role
      aPoint.X := MyQueryGamePlayers.FieldByName('formation_x').AsInteger ;
      aPoint.Y := MyQueryGamePlayers.FieldByName('formation_y').AsInteger ;
      Sp:= TSoccerPlayer.Create( aTeam,
                                 GuidTeam[TT] ,
                                 nMatchesplayed,
                                 aIds,
                                 aName,
                                 aSurname,
                                 aTalents,
                                 Attributes  );
      Sp.Age:= Trunc(  MyQueryGamePlayers.FieldByName('Matches_Played').AsInteger  div Soccerbrainv3.SEASON_MATCHES) + 18 ;
      Sp.TalentId := MyQueryGamePlayers.FieldByName('Talent').AsInteger;

      if isReserveSlot( aPoint.X,aPoint.Y  ) then begin
          TvReserveCell:= brain.ReserveSlotTV [0,aPoint.X,aPoint.Y  ]; // sempre 0 qui, il client lo metter� a 1 (aplayer.team)
          Sp.DefaultCells :=  Point(TvReserveCell.X ,TvReserveCell.Y );
          Sp.CellS := TvReserveCell;
      end
      else begin
        TvCell := brain.AiField2TV ( TT,  aPoint.X,aPoint.Y);
        Sp.DefaultCells :=  Point(TvCell.X ,TvCell.Y );
        Sp.Cells := TvCell;

      end;

//      if isoutSideAI (MyQueryGamePlayers.FieldByName('formation_x').AsInteger ,MyQueryGamePlayers.FieldByName('formation_y').AsInteger ) then begin
//        TvCell.X := MyQueryGamePlayers.FieldByName('formation_x').AsInteger;
//        TvCell.Y := MyQueryGamePlayers.FieldByName('formation_y').AsInteger;
//      end
//      else
//        TvCell := brain.AiField2TV ( TT,  MyQueryGamePlayers.FieldByName('formation_x').AsInteger, MyQueryGamePlayers.FieldByName('formation_y').AsInteger);

      // role
      // posizioni reali, non determinano il ruolo


      Sp.Injured:= MyQueryGamePlayers.FieldByName('injured').AsInteger;
      if Injured > 0 then begin
        Sp.Speed :=1;
        Sp.Defense :=1;
        Sp.Passing :=1;
        Sp.BallControl :=1;
        Sp.Shot :=1;
        Sp.Heading :=1;
      end;


      SP.YellowCard := 0;
      SP.disqualified := MyQueryGamePlayers.FieldByName('disqualified').AsInteger;
      Sp.GameOver  := False;
      if SP.disqualified > 0 then Sp.GameOver := True;

      Sp.Stamina := MyQueryGamePlayers.FieldByName('stamina').AsInteger;

        (* variabili di gioco *)
      Sp.CanMove  := true;
      Sp.CanSkill := true;
      sp.CanDribbling := true;
      Sp.PressingDone  := False;
      sp.BonusTackleTurn  := 0;
      sp.BonusLopBallControlTurn  := 0;
      sp.BonusProtectionTurn  := 0;
      sp.UnderPressureTurn := 0;
      sp.BonusSHPturn := 0;
      sp.BonusSHPAREAturn := 0;
      Sp.BonusPLMturn := 0;
      Sp.isCOF := False;
      Sp.isFK1 := False;
      Sp.isFK2 := False;
      Sp.isFK3 := False;
      Sp.isFK4 := False;
      Sp.face := MyQueryGamePlayers.FieldByName('face').AsInteger;

      if isOutside ( Sp.CellX, Sp.CellY ) then
        brain.AddSoccerReserve(Sp)    // <--- riempe reserveSlot
      else  brain.AddSoccerPlayer(Sp);


      MyQueryGamePlayers.Next;
    end;
  end;


  MyQueryGamePlayers.Free;
  ConnGame.Connected := false;
  ConnGame.Free;

  brain.Start;  // <-- teammoveleft, seconds ecc...
  brain.SaveData(brain.incMove  );
  //inc (brain.incMove);


end;
function TFormServer.CreateGameTeam ( cli: TWSocketThrdClient;  WorldTeamGuid: string ): Integer;
//  cli.cliid=account: integer;
var
  MyQuerySU,MyQueryGamePlayers,MyQueryGameTeams,MyQueryWT: TMyQuery;
  i,MatchesPlayed,MatchesLeft,stat,Speed2,GuidTalent,face: Integer;
  aPlayer: TSoccerPlayer;
  mp_template: array [0..13] of Integer;
  ts,AT: TStringList;

  injured_penalty, Growth, Talent: array [1..3] of Integer;
  Injured_Penalty1,Injured_Penalty2,Injured_Penalty3,Growth1, Growth2, Growth3, Talent1,Talent2,Talent3: Integer;
  GuidGameTeam,MarketValue: integer;
  UniformA,UniformH,TeamName: string;
  ConnWorld,ConnGame : TMyConnection;
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
  MyQueryWT.SQL.Text := 'SELECT guid, name, uniformh, uniforma FROM world.teams where guid = ' + WorldTeamGuid;
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
  MyQueryWT.Free;


  (* CREO IL TEAM *)
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGameTeams := TMyQuery.Create(nil);
  MyQueryGameTeams.Connection := ConnGame;   // game

  MyQueryGameTeams.SQL.text := 'SELECT guid,uniforma,uniformh from game.teams WHERE account = ' + IntToStr(cli.cliid);// account
  MyQueryGameTeams.Execute;
  if MyQueryGameTeams.RecordCount > 0 then begin
    cli.sReason:= 'creategameteam team exist';
    Result := 0;
    MyQueryGameTeams.Free;
    ConnWorld.Connected := false;
    ConnWorld.Free;
    ConnGame.Connected := false;
    ConnGame.Free;
    Exit;
  end;

  MyQueryGameTeams.SQL.clear;
  MyQueryGameTeams.SQL.text := 'INSERT into game.teams (account,WorldTeam,teamname, nextha,uniformh,uniforma)'+
                                                  ' VALUES ('+ IntToStr(cli.cliid) + ',' + WorldTeamGuid + ',"' + TeamName +
                                                   '",0,"' + Uniformh +'","'+ Uniforma + '")';
  MyQueryGameTeams.Execute;

  // lo riprendo su e setto Home Away
  MyQueryGameTeams.SQL.Clear ;
  MyQueryGameTeams.SQL.text := 'SELECT guid from game.teams where account = ' + IntToStr(cli.cliid);
  MyQueryGameTeams.Execute;

  if MyQueryGameTeams.RecordCount = 1 then
    GuidGameTeam := MyQueryGameTeams.FieldByName('guid').asInteger;

    Result := GuidGameTeam;
  if GuidGameTeam = 0 then begin
    cli.sReason:= 'creategameteam failed db';
    MyQueryGameTeams.Free;
    ConnWorld.Connected := false;
    ConnWorld.Free;
    ConnGame.Connected := false;
    ConnGame.Free;
    Exit;
  end;
  // update iniziale HOME AWAY pari dispari
  MyQueryGameTeams.SQL.Clear;
  if Odd(GuidGameTeam) then MyQueryGameTeams.SQL.text:= 'UPDATE game.teams set nextha = 1 WHERE guid =' + IntToStr(GuidGameTeam)
    else MyQueryGameTeams.SQL.text:= 'UPDATE game.teams set nextha = 0 WHERE guid =' + IntToStr(GuidGameTeam);
    MyQueryGameTeams.Execute ;

//    MyQueryGameTeams.free ;

  (* CREO I PLAYER *)


  mp_template[0]:= 13; // stagioni giocate
  mp_template[1]:= 12;
  mp_template[2]:= 11;
  mp_template[3]:= 10;
  mp_template[4]:= 9;
  mp_template[5]:= 8;
  mp_template[6]:= 8;
  mp_template[7]:= 7;
  mp_template[8]:= 7;
  mp_template[9]:= 6;
  mp_template[10]:= 5;
  mp_template[11]:= 4;
  mp_template[12]:= 3;
  mp_template[13]:= 2;
  // genero i player con surnames e stat , matchesplayed stabiliscono l'et�. l'et� stabilisce injured e growth
{SELECT Name FROM  world.surnames WHERE
  country = (SELECT
              country
            FROM
              world.teams
            WHERE
              world.teams.guid = 467)
  order by rand() limit 14 }
  MyQuerySU := TMyQuery.Create(nil);
  MyQuerySU.Connection := ConnWorld;   // world
  MyQuerySU.SQL.Text :=' SELECT Name FROM  world.surnames WHERE country = (SELECT country FROM world.teams WHERE world.teams.guid =' + WorldTeamGuid + ') order by rand() limit 14';
  MyQuerySU.Execute;

  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game

  for I := 0 to MyQuerySU.RecordCount -1 do begin
    //constructor TSoccerPlayer.create ( const aTeam, aGuidTeam, aMatchesPlayed : integer; const aIds, aName, aSurname, aTalents, AT: string );

    // ids adesso non importa. MatchesPlayed � random secondo un template
    // 1 31 anni
    // 1 30  anni
    // 1 29
    // 1 28
    // 2 27
    // 2 26
    // 1 25
    // 2 24
    // 1 23
    // 1 22
    // 1 21

    MatchesPlayed := 38 * mp_template[i];     // 13  ; // 31 anni

    // AT devo distribuire Tot Punti secondo un totale punti di 3 per ogni giocatore pi� 1 base. al massimo si trova un 1-1-1-4-1-1  2-1-3-1-1-1  2-2-2-1-3-1
    Ts := TStringList.Create ;

    Speed2 := rndGenerate ( 100  ); // 50% giocatori speed 2, se i 3 random vanno li' diventa 5, quindi massimo 4
    if Speed2 <= 50 then begin
      Ts.commatext := '2,1,1,1,1,1'
    end
    else  Ts.commatext := '1,1,1,1,1,1';

      stat := rndGenerate ( 6  );
      ts [ stat -1] := IntToStr( StrToInt(ts [ stat -1]) + 1) ; // quale stat  1

      stat := rndGenerate ( 6  );
      ts [ stat -1] := IntToStr( StrToInt(ts [ stat -1]) + 1) ; // quale stat 2

      if  StrToInt( ts [ 0 ]) < 4 then //speed � 4, fortunato!
        stat := rndGenerate ( 6  )
        else
        stat := RndGenerateRange( 2,6 ); // altrimenti normale

        ts [ stat -1] := IntToStr( StrToInt(ts [ stat -1]) + 1) ; // quale stat 3


    // injured_penalty
   // case MatchesPlayed of
  //    0..38*6:begin    // 18..24 anni
        injured_penalty[1]:=1;
        injured_penalty[2]:=3;
        injured_penalty[3]:=6;
        Injured_Penalty1 := injured_penalty [rndGenerate (3)];
  //    end;
 //     38*7..38*12:begin    // 25..30
        injured_penalty[1]:=2;
        injured_penalty[2]:=4;
        injured_penalty[3]:=8;
        Injured_Penalty2 := injured_penalty [rndGenerate (3)];

   //   end;
   //   38*13..38*15:begin    // 31..33
        injured_penalty[1]:=4;
        injured_penalty[2]:=8;
        injured_penalty[3]:=12;
        Injured_Penalty3 := injured_penalty [rndGenerate (3)];

    //  end;
  //  end;
    // growth
   // case MatchesPlayed of
   //   0..38*6:begin    // 18..24 anni
        Growth[1]:=5;
        Growth[2]:=15;
        Growth[3]:=30;
        Growth1 := Growth [rndGenerate (3)];
    //  end;
   //   38*7..38*12:begin    // 25..30
        Growth[1]:=5;
        Growth[2]:=10;
        Growth[3]:=20;
        Growth2 := Growth [rndGenerate (3)];

    //  end;
   //   38*13..38*15:begin    // 31..33
        Growth[1]:=1;
        Growth[2]:=5;
        Growth[3]:=10;
        Growth3 := Growth [rndGenerate (3)];

    //  end;
  //  end;

        Talent[1]:=4;
        Talent[2]:=8;
        Talent[3]:=12;
        Talent1 := Talent [rndGenerate (3)];
    //  end;
   //   38*7..38*12:begin    // 25..30
        Talent[1]:=2;
        Talent[2]:=4;
        Talent[3]:=8;
        Talent2 := Talent [rndGenerate (3)];

    //  end;
   //   38*13..38*15:begin    // 31..33
        Talent[1]:=1;
        Talent[2]:=1;
        Talent[3]:=1;
        Talent3 := Talent [rndGenerate (3)];

      MatchesLeft := (38*15) - MatchesPlayed;


     // il growth cerca la stat pi� usata nelle azioni personali !!!!!!!!!!!!!!!!!!!!
    // Distribuzione Talenti  11 TALENTI
    // Atalent 2 player con 2 talenti + 1 Minimo talento GoalKeeper
{    ts.Clear;
      tsTalents.add ('challenge'); // lottatore
      ts.add ('toughness'); // durezza
      ts.add ('power');      // potenza
      ts.add  ('crossing');
      ts.add  ('longpass');  // solo distanza
      ts.add  ('experience');  // pressing gratis
      ts.add  ('dribbling');
      ts.add  ('offensive');
      ts.add  ('defensive');
      ts.add  ('bulldog');
      ts.add  ('goalkeeper');   }

    // il primo player ha il talento GoalKeeper. i seguenti 2 hanno 2 talkenti casuali
    GuidTalent:=0;
    if i =0 then begin
   //   ATALENT := 'goalkeeper';
      GuidTalent := 1;
    end
    else if (i = 1) or (i = 2) then begin
      GuidTalent := rndgenerate(tsTalents.count-1);
   //   ATALENT :=  tsTalents [ GuidTalent ] ;
    end;
   // aPlayer:= TSoccerPlayer.create( -1, StrToInt(WorldTeamGuid), MatchesPlayed, '','',MyQuerySU.FieldByName('name').AsString, Atalent,AT );
//constructor TSoccerPlayer.create ( const aTeam, aGuidTeam, aMatchesPlayed : integer; const aIds, aName, aSurname, aTalents, AT: string );

    //face casuale
    face := rndGenerate ( 1 );
    // li salvo nel DB e ottengono un guid ids. La successiva lettura contenie ids (game.players.guid)
    MyQueryGamePlayers.SQL.text := 'INSERT into game.players (Team,Name,Matches_Played,Matches_Left,'+
                                                  'injured_penalty1,injured_penalty2,injured_penalty3,'+
                                                  'growth1,growth2,growth3,talent1,talent2,talent3,'+
                                                  'talent, speed,defense,passing,ballcontrol,heading,shot,injured,totyellowcard,disqualified,face)'+
                                                  ' VALUES ('+
                                                  IntToStr(GuidGameTeam) +',"'+ MyQuerySU.FieldByName('name').AsString+'",'+ IntToStr(MatchesPlayed)+','+ IntToStr(MatchesLeft)+','+
                                                  IntToStr(Injured_Penalty1)+','+IntToStr(Injured_Penalty2)+','+IntToStr(Injured_Penalty3)+','+
                                                  IntToStr(Growth1)+','+IntToStr(Growth2)+','+IntToStr(Growth3)+','+
                                                  IntToStr(talent1)+','+IntToStr(talent2)+','+IntToStr(talent3)+','+
                                                  IntToStr(GuidTalent) + ',' + ts[0]+','+ts[1]+','+ts[2]+','+
                                                  ts[3]+','+ts[4]+','+ts[5] +','+
                                                  '0,0,0,' + IntToStr(face) //injured,totyellowcard,disqualified
                                                  +')';

    MyQueryGamePlayers.Execute;
    MyQuerySU.Next;
    ts.Free;
  //  aPlayer.Free;
  end;


  MyQueryGamePlayers.Free;
  MyQuerySU.Free;

  MarketValue := GetMarketValueTeam ( GuidGameTeam );
  MyQueryGameTeams.SQL.clear;
  MyQueryGameTeams.SQL.text := 'UPDATE game.teams set MarketValue='+IntTostr(MarketValue) + ' where Guid =' + IntTostr(GuidGameTeam);
  MyQueryGameTeams.Execute;
  MyQueryGameTeams.Free;

  ConnWorld.Connected := false;
  ConnWorld.Free;
  ConnGame.Connected := false;
  ConnGame.Free;



end;
procedure TFormServer.CreateFormationTeam ( Guidteam: integer );
var
  i,x,y,T,ii, pcount,pdisq,Formation_x,formation_y,D,M,F,talentN: Integer;
  ini : TInifile;
  aPlayer,aGK: TSoccerPlayer;
  lstPlayers,lstPlayersDB: TObjectList<TSoccerPlayer>;
  FinalFormation : array[1..11] of TFinalFormation;
  lstGK: TObjectList<TSoccerPlayer>;
  talent,AT: string;
  MyQueryGamePlayers : TMyQuery;
  aF: TFormation;
  ts : TStringList;
  ReserveSlot : TTheArray;
  aReserveSlot: TPoint;
  found: Boolean;
  OldfinalFormation: string;
  ConnGame : TMyConnection;
  label nextplayer,NoFormation;

begin


  CleanReserveSlot ( ReserveSlot );
  (* la stora nel db *)
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;
  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game

  // azzero tutto
//  MyQueryGamePlayers.SQL.text := 'UPDATE game.players set formation_x = 0, formation_Y = 0 WHERE team =' + IntToStr(GuidTeam);
//  MyQueryGamePlayers.Execute ;

//  MyQueryGamePlayers.SQL.Clear;
  MyQueryGamePlayers.SQL.text := 'SELECT guid,Team,Name,Matches_Played,Matches_Left,'+
                                                  'talent, speed,defense,passing,ballcontrol,heading,shot,stamina,'+
                                                  'formation_x,formation_y,injured,totyellowcard,disqualified'+
                                                  ' from game.players WHERE team =' + IntToStr(GuidTeam);

  MyQueryGamePlayers.Execute ;


  lstPlayers:= TObjectList<TSoccerPlayer>.Create(false); // lista locale
  lstPlayersDB:= TObjectList<TSoccerPlayer>.Create(true); // lista locale  che elimina tutti gli oggetti
  for I := 0 to MyQueryGamePlayers.RecordCount -1 do begin

//    if MyQueryGamePlayers.FieldByName ( 'disqualified').AsInteger > 0 then goto NoFormation;
//    if MyQueryGamePlayers.FieldByName ( 'injured').AsInteger > 0 then goto NoFormation;

      AT := MyQueryGamePlayers.FieldByName('speed').Asstring + ',' + MyQueryGamePlayers.FieldByName('defense').Asstring +
            ',' + MyQueryGamePlayers.FieldByName('passing').Asstring + ',' + MyQueryGamePlayers.FieldByName('ballcontrol').Asstring  +
            ',' + MyQueryGamePlayers.FieldByName('shot').Asstring + ',' + MyQueryGamePlayers.FieldByName('heading').Asstring;


    talentN := MyQueryGamePlayers.FieldByName('Talent').AsInteger;
    if talentN > 0 then
      talent := tsTalents[MyQueryGamePlayers.FieldByName('Talent').AsInteger-1]
      else talent := '';

    aPlayer := TSoccerPlayer.create(0,0,0,MyQueryGamePlayers.FieldByName ( 'guid').AsString,'','',talent ,AT);//0,0,0 non hanno importanza qui
    aPlayer.disqualified :=  MyQueryGamePlayers.FieldByName ( 'disqualified').AsInteger;
    aPlayer.Injured :=  MyQueryGamePlayers.FieldByName ( 'injured').AsInteger;
    if aPlayer.Injured > 0 then  begin
      aPlayer.Stamina:=0;
      aPlayer.Speed:=1;
      aPlayer.Defense:=1;
      aPlayer.Passing:=1;
      aPlayer.Ballcontrol:=1;
      aPlayer.Shot:=1;
      aPlayer.Heading:=1;
    end
    else aPlayer.Stamina := MyQueryGamePlayers.FieldByName ( 'stamina').AsInteger;


    //constructor TSoccerPlayer.create ( const aTeam, aGuidTeam, aMatchesPlayed : integer; const aIds, aName, aSurname, aTalents, AT: string );

    lstPlayers.add ( aPlayer);
    lstPlayersDB.add ( aPlayer);
    aPlayer.AIFormationCellX :=  0;   // azzero tutto
    aPlayer.AIFormationCellY :=  0;


    MyQueryGamePlayers.next;
  end;

  // lstPlayers contiene il db ma non squalificati o infortunati
  // FinalFormation i dati finali da storare nel db

  // Metto il portiere. il portiere � sempre presente. non pu� essere venduto se solo 1. viene generato un giovane gk se manca dalla rosa perch�
  // il gk originale raggiunge una certa et�

  // storo tutto nel db
    ts := TStringList.Create;
    ts.Add('setformation');

    lstGK:= TObjectList<TSoccerPlayer>.Create(false);
    for I := 0 to lstPlayers.Count -1 do begin
      if lstPlayers[i].Tal_GoalKeeper > 0 then begin
        aGK:= lstPlayers[i];
        lstGk.Add (aGK);
      end;
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


    for I := lstPlayers.Count -1 downto 0 do begin
    // gli altri GK sono per forza tutti panchinari
      if (lstPlayers[i].Tal_GoalKeeper > 0)  then begin
        lstPlayers.Delete(i);  // elimino il gk regolare e anche gli altri. lstPlayerDB li rimette in panchina
//        aReserveSlot := NextReserveSlot ( ReserveSlot );
//        Ts.Add( lstPlayers[i].ids  + '=' + IntToStr(aReserveSlot.X) + ':' + IntToStr(aReserveSlot.Y ));
//        ReserveSlot [aReserveSlot.x,aReserveSlot.y] :=  lstPlayers[i].Ids;
//        lstPlayers.Delete(i);  // elimino tutti gli altri gk dalla VERA lista
//      end
//      if lstPlayers[i].Ids = FinalFormation [1].Guid then begin
//        lstPlayers.Delete(i);  // elimino il gk regolare
      end;
    end;

    lstGK.Free;

 //  elimino da lstPlayers i disqialified  , gli injured hanno stamina 0 . lielimino comunque qui
    for I := lstPlayers.Count -1 downto 0 do begin
      if (lstPlayers[i].disqualified > 0) or (lstPlayers[i].injured > 0) then begin
        lstPlayers.Delete(i);
      end;
    end;


  // prendo una formazione da una lista di preset
  // DIF - MID - FOR
    pcount := 2; // dopo il gk
    af:= FormationsPreset[ RndGenerate0( FormationsPreset.Count -1 )];

    lstPlayers.sort(TComparer<TSoccerPlayer>.Construct(
    function (const L, R: TSoccerPlayer): integer
    begin
      Result := R.defense - L.defense;
    end
    ));

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

  // a questo punto devo eliminare un giocatore goalkeeper tra i presenti. poi elimino quelli con stamina bassa 60. Riprovo a
  // sostituirli con stamina > 60. mi sono rimasti i player nella lstPlayers, li ordino in base al ruolo da ricoprire

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
          // qui � quello ordinato in base a difesa, passaggio o tiro e quello che entra non pu� avere stamina bassa -60 (rimossi sopra)

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
        if FinalFormation [ii].Guid = lstPlayersDB[i].Ids  then begin // � presente nei 11 titolari
          found := True;
          Break;
        end;
      end;

      if not found then begin   // se nopn � prsente nei 11 titolati lo metto in panchina e lo aggiungo in coda alla ts
        aReserveSlot := NextReserveSlot ( ReserveSlot );
        ReserveSlot [aReserveSlot.x,aReserveSlot.y] :=  lstPlayersDB[i].Ids;
        lstPlayersDB[i].AIFormationCellX := aReserveSlot.x;
        lstPlayersDB[i].AIFormationCellY := aReserveSlot.Y;

        Ts.Add( lstPlayersDB[i].ids  + '=' +
        IntToStr(lstPlayersDB[i].AIFormationCellX  ) + ':' +
        IntToStr(lstPlayersDB[i].AIFormationCellY ));
      end;
      
    end;

    lstPlayers.Free;
    lstPlayersDB.Free;

  //  for i := 1 to 11 do begin
  //      Ts.Add( FinalFormation [i].Guid  + '=' +
  //      IntToStr(FinalFormation [i].Cells.X  ) + ':' +
  //      IntToStr(FinalFormation [i].Cells.Y ));
  //  end;

     store_formation( Ts.CommaText );
     ts.Free;
    { si pu� giocare anche in meno di 7 giocatori }
    MyQueryGamePlayers.free;
    ConnGame.Connected:= False;
    ConnGame.Free;

end;

function TFormServer.NextReserveSlot ( ReserveSlot: TTheArray ): Tpoint;
var
  t,x,y: Integer;
begin

    for x := -4 to -1 do begin
      for y := 0 to 6 do begin
        if ReserveSlot [x,y] = '' then begin
          Result := Point(x,y);
          Exit;
        end;
      end;
    end;
end;
procedure TFormServer.CleanReserveSlot ( ReserveSlot: TTheArray );
var
  t,x,y: Integer;
begin
    for x := -4 to -1 do begin
      for y := 0 to 6 do begin
          ReserveSlot [x,y] := '';
      end;
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
var
  ts: TStringList;
  value: Integer;
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
  aPlayer: TSoccerPlayer;
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
  aPlayer: TSoccerPlayer;
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
  aPlayer: TSoccerPlayer;
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
    ts.Free;
    Exit;
  end;

  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
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
  if aPlayer.GuidTeam <> Cli.GuidTeam  then begin
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
    if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
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
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
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
//    else if (ts[1] ='PASS') or (ts[1] ='COR')  then begin  // sul brain iscof batter� il corner
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
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
    cli.sReason:= 'GuidTeam Turn mismatch';
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
  if TSoccerBrain(Cli.brain).Score.CliId [TSoccerBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    ts.Free;
    Exit;
  end;

  // coerenza guidTeam e teamTurn
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
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
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
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
    if aPlayer.GuidTeam <> Cli.GuidTeam  then begin
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
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
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
    if aPlayer.GuidTeam <> Cli.GuidTeam  then begin
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
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
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
    if aPlayer.GuidTeam <> Cli.GuidTeam  then begin
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
  if TSoccerBrain(Cli.brain).Score.TeamGuid  [TSoccerBrain(Cli.brain).TeamTurn] <> cli.GuidTeam then begin
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
    if aPlayer.GuidTeam <> Cli.GuidTeam  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

    ts.Free;

end;
procedure TFormServer.validate_levelup ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TSoccerPlayer;
  ts: TStringList;
  aValue: Integer;
begin
  // 0=levelup 1=ids 2=attr or talentID
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
    cli.sReason:= 'ids not numeric';
    ts.Free;
    Exit;
  end;

  ts.Free;

end;
procedure TFormServer.MarketBuy ( Cli: TWSocketThrdClient; CommaText: string  );
var
  MyQueryGamePlayers,MyQuerymarket,MyQueryGameTeams: TMyQuery;
  aPlayer: TSoccerPlayer;
  mValue,i : Integer;
  price,MoneyA,MoneyB,GuidTeamSell: Integer;
  ts: TStringList;
  ConnGame : TMyConnection;
  ReserveSlot : TTheArray;
  aReserveSlot: TPoint;
begin
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  // check e spostamento denaro
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGameTeams := TMyQuery.Create(nil);
  MyQueryGameTeams.Connection := ConnGame;   // game
  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game
  MyQuerymarket := TMyQuery.Create(nil);
  MyQuerymarket.Connection := ConnGame;   // game

  MyQueryGamePlayers.SQL.text := 'SELECT count(guid) FROM game.players where team=' + IntToStr(Cli.GuidTeam);
  MyQueryGamePlayers.Execute ;
  if MyQueryGamePlayers.RecordCount >= 18 then  begin
    Cli.sreason := 'marketbuy linit 18 player';
    MyQueryGameTeams.Free;
    MyQueryGamePlayers.Free;
    MyQuerymarket.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    ts.Free;
    Exit;

  end;


  MyQueryGameTeams.SQL.text := 'SELECT money FROM game.teams where guid=' + IntToStr(Cli.GuidTeam);
  MyQueryGameTeams.Execute ;
                                                                                                              // non i suoi
  MyQuerymarket.SQL.text := 'SELECT sellprice,guidteam FROM game.market where guidplayer=' + ts[1] + ' and guidteam <> ' + IntToStr(Cli.GuidTeam);
  MyQuerymarket.Execute ;
  if MyQuerymarket.RecordCount = 0 then begin
    Cli.sreason := 'marketbuy player not found';
    MyQueryGameTeams.Free;
    MyQueryGamePlayers.Free;
    MyQuerymarket.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    ts.Free;
    Exit;

  end;

  GuidTeamSell:=  MyQuerymarket.FieldByName('guidteam').AsInteger;
  MoneyA := MyQueryGameTeams.FieldByName('money').AsInteger;
  price :=  MyQuerymarket.FieldByName('sellprice').AsInteger;

  if MoneyA < price then begin
    Cli.sreason := 'marketbuy no funds!';
    MyQueryGameTeams.Free;
    MyQueryGamePlayers.Free;
    MyQuerymarket.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    ts.Free;
    Exit;

  end;

  // qui lo pu� comprare
  MoneyA := MoneyA - price;
  MyQueryGameTeams.SQL.text := 'UPDATE game.teams set money=' + IntToStr(MoneyA) + ' WHERE guid =' + IntToStr(cli.GuidTeam);
  MyQueryGameTeams.Execute ;
  MyQueryGameTeams.SQL.text := 'SELECT money FROM game.teams where guid=' +  IntToStr (GuidTeamSell);
  MyQueryGameTeams.Execute ;
  if MyQuerymarket.RecordCount = 0 then begin
    Cli.sreason := 'marketbuy no vendor team';
    MyQueryGameTeams.Free;
    MyQueryGamePlayers.Free;
    MyQuerymarket.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    ts.Free;
    Exit;

  end;


  MoneyB := MyQueryGameTeams.FieldByName('money').AsInteger; // chi vende
  MoneyB := MoneyB + price;
  MyQueryGameTeams.SQL.text := 'UPDATE game.teams set money=' + IntToStr(MoneyB) + ' WHERE guid =' + IntToStr (GuidTeamSell);
  MyQueryGameTeams.Execute ;



  // game.players mettere onmarket=0
  // update game.players onmarket e delete market con tutti i dati attuali e congelati qui
  MyQuerymarket.SQL.text := 'DELETE FROM game.market where guidplayer=' + ts[1];
  MyQuerymarket.Execute ;


  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game

  // ottengo il prossimo slot delle riserve
  CleanReserveSlot ( ReserveSlot );
  MyQueryGamePlayers.SQL.text := 'SELECT guid,formation_x,formation_y from game.players WHERE  team=' + IntToStr(Cli.GuidTeam);
  MyQueryGamePlayers.Execute ;
  for i := MyQueryGamePlayers.RecordCount -1 downto 0 do begin

    if isReserveSlot ( MyQueryGamePlayers.FieldByName('formation_x').AsInteger, MyQueryGamePlayers.FieldByName('formation_y').AsInteger) then
    ReserveSlot[MyQueryGamePlayers.FieldByName('formation_x').AsInteger, MyQueryGamePlayers.FieldByName('formation_y').AsInteger]:=
                              MyQueryGamePlayers.FieldByName('guid').AsString;

  end;
  aReserveSlot := NextReserveSlot ( ReserveSlot ); //<--- la prossima libera



  MyQueryGamePlayers.SQL.text := 'UPDATE game.players set onmarket=0,team='+IntToStr(Cli.GuidTeam) +  // cambio team
                              ',formation_x=' + IntToStr(aReserveSlot.X) +',formation_y=' + IntToStr(aReserveSlot.Y) +' WHERE guid =' + ts[1];

  MyQueryGamePlayers.Execute ;

  MyQueryGameTeams.Free;
  MyQueryGamePlayers.Free;
  MyQuerymarket.Free;

  ConnGame.Connected := False;
  ConnGame.Free;

  ts.Free;


end;
procedure TFormServer.MarketSell ( Cli: TWSocketThrdClient; CommaText: string ); // mette un player sul mercato
var
  MyQueryGamePlayers,MyQuerymarket,MyQueryGamePlayersGK: TMyQuery;
  aPlayer: TSoccerPlayer;
  mValue : Integer;
  price: Integer;
  ts: TStringList;
  ConnGame : TMyConnection;
begin
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  price := StrToInt ( ts[2] );

  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game
  MyQueryGamePlayers.SQL.text := 'SELECT guid,team,name,matches_played,matches_left,speed,defense,passing,ballcontrol,shot,heading,talent,history,xp,onmarket' +
                                ' from game.players WHERE onmarket=0 and guid =' + ts[1] + ' and team=' + IntToStr(Cli.GuidTeam); // per essere sicuri anche cli.guidteam
  MyQueryGamePlayers.Execute ;

  if MyQueryGamePlayers.RecordCount = 0 then begin
    Cli.sreason := 'marketsell player not found';
    MyQueryGamePlayers.Free;
    ts.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    Exit;
  end;
  // check value < minimo. non si pu� vendere un player a basso costo
  if MyQueryGamePlayers.FieldByName('talent').AsInteger <> 1 then  // non un goalkeeper (portiere) o senza talento o con talento

  mValue :=  Trunc ( MyQueryGamePlayers.FieldByName('speed').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('speed').AsInteger] +
             MyQueryGamePlayers.FieldByName('defense').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('defense').AsInteger] +
             MyQueryGamePlayers.FieldByName('passing').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('passing').AsInteger] +
             MyQueryGamePlayers.FieldByName('ballcontrol').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('ballcontrol').AsInteger] +
             MyQueryGamePlayers.FieldByName('shot').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('shot').AsInteger] +
             MyQueryGamePlayers.FieldByName('heading').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('heading').AsInteger])

  else if MyQueryGamePlayers.FieldByName('talent').AsInteger = 1 then begin  // un portiere

  mValue :=  Trunc ((MyQueryGamePlayers.FieldByName('defense').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('defense').AsInteger] * MARKET_VALUE_ATTRIBUTE_DEFENSE_GK) +
             MyQueryGamePlayers.FieldByName('passing').AsInteger *   MARKET_VALUE_ATTRIBUTE [MyQueryGamePlayers.FieldByName('passing').AsInteger]  );


    // � un goalkeeper, se � l'unico non posso venderlo
    MyQueryGamePlayersGK := TMyQuery.Create(nil);
    MyQueryGamePlayersGK.Connection := ConnGame;   // game
    MyQueryGamePlayersGK.SQL.text := 'SELECT guid from game.players WHERE talent=1 and guid <>' + ts[1] +' and team=' + IntToStr(Cli.GuidTeam);
    MyQueryGamePlayersGK.Execute ;
    if MyQueryGamePlayersGK.RecordCount = 0 then begin
      Cli.sreason := 'marketsell only 1 goalkeeper';
      MyQueryGamePlayers.Free;
      MyQueryGamePlayersGK.Free;
      ts.Free;
      ConnGame.Connected := False;
      ConnGame.Free;
      Exit;
    end;
    MyQueryGamePlayersGK.Free;
  end;

  if MyQueryGamePlayers.FieldByName('talent').AsInteger  <> 0 then mValue := Trunc (mValue  *  MARKET_VALUE_TALENT) ; //se c'� un talento, anche goalkeeper


  if price < mValue then begin
    Cli.sreason := 'marketsell price low';
    MyQueryGamePlayers.Free;
    ts.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    Exit;
  end;

  // non deve essere presente sul mercato
  MyQuerymarket := TMyQuery.Create(nil);
  MyQuerymarket.Connection := ConnGame;   // game
  MyQuerymarket.SQL.text := 'SELECT guid from game.market WHERE guid =' + ts[1];
  MyQuerymarket.Execute ;
  if MyQuerymarket.RecordCount > 0 then begin
    Cli.sreason := 'marketsell player already on market';
    MyQueryGamePlayers.Free;
    MyQuerymarket.Free;
    ts.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    Exit;
  end;

  // sul mercato massimo 3 player
  MyQuerymarket.SQL.text := 'SELECT guid from game.market WHERE guidteam =' + IntToStr(Cli.GuidTeam);
  MyQuerymarket.Execute ;
  if MyQuerymarket.RecordCount >= 3 then begin
    Cli.sreason := 'marketsell max 3 player';
    MyQueryGamePlayers.Free;
    MyQuerymarket.Free;
    ts.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    Exit;
  end;
  // update game.players onmarket e market con tutti i dati attuali e congelati qui

  MyQuerymarket.SQL.text := 'INSERT INTO game.market (speed,defense,passing,ballcontrol,shot,heading,talent,'+
                            'matches_played,matches_left,name,guidteam,guidplayer,sellprice,history,xp) VALUES ('+
                             MyQueryGamePlayers.FieldByName('speed').AsString +
                            ',' + MyQueryGamePlayers.FieldByName('defense').AsString +
                            ',' + MyQueryGamePlayers.FieldByName('passing').AsString +
                            ',' + MyQueryGamePlayers.FieldByName('ballcontrol').AsString +
                            ',' + MyQueryGamePlayers.FieldByName('shot').AsString +
                            ',' + MyQueryGamePlayers.FieldByName('heading').AsString +
                            ',' + MyQueryGamePlayers.FieldByName('talent').AsString +
                            ',' + MyQueryGamePlayers.FieldByName('matches_played').AsString +
                            ',' + MyQueryGamePlayers.FieldByName('matches_left').AsString +
                            ',"' + MyQueryGamePlayers.FieldByName('name').AsString + '"'+
                            ',' + MyQueryGamePlayers.FieldByName('team').AsString + // guidteam
                            ',' + MyQueryGamePlayers.FieldByName('guid').AsString + // guidplayer
                            ',' + ts[2] + // price
                            ',"' + MyQueryGamePlayers.FieldByName('history').AsString + '"'+
                            ',"' + MyQueryGamePlayers.FieldByName('xp').AsString + '")';
  MyQuerymarket.Execute ;

  MyQueryGamePlayers.SQL.text := 'UPDATE game.players set onmarket=1 WHERE guid =' + ts[1] + ' and team=' + IntToStr(Cli.GuidTeam); // per essere sicuri anche cli.guidteam
  MyQueryGamePlayers.Execute ;

  MyQueryGamePlayers.Free;
  MyQuerymarket.Free;
  ConnGame.Connected := False;
  ConnGame.Free;
  ts.Free;

end;
procedure TFormServer.MarketCancelSell ( Cli: TWSocketThrdClient; CommaText: string );
var
  MyQueryGamePlayers,MyQuerymarket: TMyQuery;
  aPlayer: TSoccerPlayer;
  mValue : Integer;
  ts: TStringList;
  ConnGame : TMyConnection;
begin
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;


  //  deve essere presente sul mercato
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQuerymarket := TMyQuery.Create(nil);
  MyQuerymarket.Connection :=  ConnGame;

  MyQuerymarket.SQL.text := 'SELECT guid from game.market WHERE guidplayer =' + ts[1] + ' and guidteam=' + IntToStr(Cli.GuidTeam); // per essere sicuri anche cli.guidteam
  MyQuerymarket.Execute ;
  if MyQuerymarket.RecordCount = 0 then begin
    Cli.sreason := 'marketcancelsell player not on market';
    MyQuerymarket.Free;
    ts.Free;
    ConnGame.Connected := False;
    ConnGame.Free;
    Exit;
  end;

  // update game.players onmarket e delete market con tutti i dati attuali e congelati qui
  MyQuerymarket.SQL.text := 'DELETE FROM game.market where guidplayer=' + ts[1] + ' and guidteam=' + IntToStr(Cli.GuidTeam);
  MyQuerymarket.Execute ;

  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game
  MyQueryGamePlayers.SQL.text := 'UPDATE game.players set onmarket=0 WHERE guid =' + ts[1] + ' and team=' + IntToStr(Cli.GuidTeam); // per essere sicuri anche cli.guidteam
  MyQueryGamePlayers.Execute ;

  MyQueryGamePlayers.Free;
  MyQuerymarket.Free;
  ConnGame.Connected := False;
  ConnGame.Free;
  ts.Free;

end;
procedure TFormServer.DismissPlayer ( Cli: TWSocketThrdClient; CommaText: string );
var
  MyQueryGamePlayers,MyQuerymarket: TMyQuery;
  aPlayer: TSoccerPlayer;
  mValue : Integer;
  ts: TStringList;
  ConnGame : TMyConnection;
begin
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;


  //  deve essere presente sul mercato
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQuerymarket := TMyQuery.Create(nil);
  MyQuerymarket.Connection :=  ConnGame;

  // se presente sul mercato lo elimino
  MyQuerymarket.SQL.text := 'SELECT guid from game.market WHERE guidplayer =' + ts[1] + ' and guidteam=' + IntToStr(Cli.GuidTeam); // per essere sicuri anche cli.guidteam
  MyQuerymarket.Execute ;
  if MyQuerymarket.RecordCount = 1 then begin
    MyQuerymarket.SQL.text := 'DELETE FROM game.market where guidplayer=' + ts[1] + ' and guidteam=' + IntToStr(Cli.GuidTeam);
    MyQuerymarket.Execute ;
  end;

  // team = 0 significa di nessun team , licenziato
  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game
  MyQueryGamePlayers.SQL.text := 'UPDATE game.players set team=0 WHERE guid =' + ts[1] + ' and team=' + IntToStr(Cli.GuidTeam); // per essere sicuri anche cli.guidteam
  MyQueryGamePlayers.Execute ;

  MyQueryGamePlayers.Free;
  MyQuerymarket.Free;
  ConnGame.Connected := False;
  ConnGame.Free;
  ts.Free;

end;
procedure TFormServer.store_Uniform ( Guidteam: integer; CommaText: string );
var
  ts,UniformH,UniformA: TStringList;
  i: Integer;
  MyQueryGameTeams: TMyQuery;
  ConnGame : TMyConnection;
begin
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  ts.Delete(0); // SetUniform

  UniformH:= TStringList.Create ;
  UniformA:= TStringList.Create ;

  for I := 0 to 4 do begin
    UniformH.Add(ts[i]);
  end;
  for I := 5 to 9 do begin
    UniformA.Add(ts[i]);
  end;


  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGameTeams := TMyQuery.Create(nil);
  MyQueryGameTeams.Connection := ConnGame;   // game

  MyQueryGameTeams.SQL.text := 'UPDATE game.teams set uniformh="' + UniformH.CommaText + '",uniforma="' +
                                UniformA.CommaText + '" WHERE guid =' + IntToStr(Guidteam);
  MyQueryGameTeams.Execute ;

  MyQueryGameTeams.Free;
  ConnGame.Connected := false;
  ConnGame.Free;
  UniformH.Free;
  UniformA.Free;
  ts.Free;

end;

procedure TFormServer.store_formation ( CommaText: string );
var
  i: Integer;
  ts: TStringList;
  strCells: string;
  tscells: TStringList;
  MyQueryGamePlayers: TMyQuery;
  ConnGame : TMyConnection;
begin

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  ts.Delete(0); // SetFormation

  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game



  for I := 0 to ts.Count - 1 do begin
    strCells:= ts.ValueFromIndex [i];
    tscells:= TStringList.Create ;
    tscells.StrictDelimiter := True;
    tscells.Delimiter := ':';
    tscells.DelimitedText := strCells;
    MyQueryGamePlayers.SQL.text := 'UPDATE game.players set formation_x ="' + tscells [0] + '", formation_y ="' +  tscells [1] + '" WHERE guid =' + ts.Names [i];
    MyQueryGamePlayers.Execute ;

    tsCells.Free;
  end;

  MyQueryGamePlayers.Free;
  ConnGame.Connected:= False;
  ConnGame.Free;
  ts.Free;

end;
procedure TFormServer.Reset_Formation ( Cli:TWSocketThrdClient  );
var
  i: Integer;
  aReserveSlot: TPoint;
  MyQueryGamePlayers, MyQueryUpdate : TMyQuery;
  ReserveSlot : TTheArray;
  ConnGame : TMyConnection;
begin
  CleanReserveSlot ( ReserveSlot );
  // Singoli players
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game
  MyQueryGamePlayers.SQL.text := 'SELECT guid,formation_x,formation_y from game.players WHERE team =' + IntToStr(Cli.GuidTeam);
  MyQueryGamePlayers.Execute ;

  MyQueryUpdate := TMyQuery.Create(nil);
  MyQueryUpdate.Connection := ConnGame;   // game

  for I := 0 to MyQueryGamePlayers.RecordCount -1 do begin
    aReserveSlot := NextReserveSlot ( ReserveSlot );

    ReserveSlot[aReserveSlot.X, aReserveSlot.Y]:= MyQueryGamePlayers.FieldByName('guid').AsString;
    MyQueryUpdate.SQL.text := 'UPDATE game.players set formation_x =' + IntToStr(aReserveSlot.X) + ', formation_y =' +
                                                  IntToStr(aReserveSlot.Y) +' WHERE guid =' + MyQueryGamePlayers.FieldByName('guid').AsString;
    MyQueryUpdate.Execute ;
    MyQueryGamePlayers.Next;
  end;

  MyQueryGamePlayers.Free;
  MyQueryUpdate.Free;
  ConnGame.Connected := false;
  ConnGame.free;


end;
procedure TFormServer.validate_setuniform ( CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  i,aValue: Integer;
begin

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  ts.Delete(0); //setformation

  if ts.Count < 10 then begin
      cli.sReason := 'validate_setuniform Invalid ts count ' ;
      ts.Free;
      Exit;
  end;

  for I := 0 to 9 do begin
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
  i,i2,guid,disqualified,chanceA,chanceT: Integer;
  ts: TStringList;
  strCells: string;
  tscells: TStringList;
  PositionCellX,PositionCellY: Integer;
  CellPoint : TPoint;
  lstCellPoint: TList<TPoint>;
  s,d,p,b,sh,h: Integer;
  talentID,age,aValue: Integer;
  history,xp: string;
begin

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  ts.Delete(0); //setformation
  lstCellPoint:= TList<TPoint>.Create;


  for I := 0 to ts.Count - 1 do begin
    Guid := StrToIntDef(  ts.Names [i] , 0  );
    // validate player. dal cli risale al guidteam (cli.guidteam)
    disqualified:=0;
    validate_player (guid,Cli,s,d,p,b,sh,h,disqualified, chanceA, chanceT,talentID,age,history,xp);
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


      if (PositionCellX < -2 ) or (PositionCellX > 6 ) then begin  // coincidenza 6    -2 -1
        cli.sReason := 'Invalid Cell formation <-2 or >6' + IntToStr( guid) + ' ' + strCells;
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


    if (PositionCellX > 0) and  (PositionCellY > -1)  and (disqualified > 0) then begin
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


    // qui � per forza in campo oppure � a -2 o -1
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
procedure TFormServer.validate_player ( const guid: integer; Cli:TWSocketThrdClient;  var s,d,p,b,sh,h, disqualified, chancelvlUp, chancetalentlvlUp,talentID,age : integer;var history,xp:string );
var
  MyQueryGamePlayers: TMyQuery;
  ConnGame : TMyConnection;
begin
  (* Valido il player, disqualified � solo una info aggiuntiva che chi chiama gestisce*)
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game


  MyQueryGamePlayers.SQL.text := 'SELECT guid, disqualified, Matches_Played,growth1,growth2,growth3,talent1,talent2,talent3,history,xp,' +
                                  'speed,defense,passing,ballcontrol,shot,heading,talent '+
                                  'from game.players WHERE team =' + IntToStr(Cli.GuidTeam) + ' and guid = ' + IntToStr(guid);
  MyQueryGamePlayers.Execute ;

  if MyQueryGamePlayers.RecordCount <= 0 then begin
    cli.sReason:= 'Player not found ' + IntToStr(guid);
    MyQueryGamePlayers.Free;
    ConnGame.Connected := false;
    ConnGame.Free;
    Exit;
  end
  else begin

    disqualified := MyQueryGamePlayers.FieldByName ('disqualified').AsInteger;
    Age:= Trunc(  MyQueryGamePlayers.FieldByName ('Matches_Played').AsInteger  div SEASON_MATCHES) + 18 ;
    talentID := MyQueryGamePlayers.FieldByName ('talent').AsInteger;
    s :=  MyQueryGamePlayers.FieldByName ('speed').AsInteger;
    d :=  MyQueryGamePlayers.FieldByName ('defense').AsInteger;
    p :=  MyQueryGamePlayers.FieldByName ('passing').AsInteger;
    b :=  MyQueryGamePlayers.FieldByName ('ballcontrol').AsInteger;
    sh :=  MyQueryGamePlayers.FieldByName ('shot').AsInteger;
    h :=  MyQueryGamePlayers.FieldByName ('heading').AsInteger;
    history := MyQueryGamePlayers.FieldByName ('history').AsString;
    xp := MyQueryGamePlayers.FieldByName ('xp').AsString;

    case Age of
      18..24: begin
        chancelvlUp := MyQueryGamePlayers.FieldByName ('growth1').AsInteger;
        chancetalentlvlUp :=  MyQueryGamePlayers.FieldByName ('talent1').AsInteger;
      end;
      25..30: begin
        chancelvlUp := MyQueryGamePlayers.FieldByName ('growth2').AsInteger;
        chancetalentlvlUp :=  MyQueryGamePlayers.FieldByName ('talent2').AsInteger;
      end;
      31..33: begin
        chancelvlUp := MyQueryGamePlayers.FieldByName ('growth3').AsInteger;
        chancetalentlvlUp :=  MyQueryGamePlayers.FieldByName ('talent3').AsInteger;
      end;
    end;

  end;

  MyQueryGamePlayers.Free;
  ConnGame.Connected := false;
  ConnGame.Free;

end;
function TFormServer.checkformation ( Cli:TWSocketThrdClient ): Boolean;
var
  i,pdisq,pcount: Integer;
  MyQueryGamePlayers: TMyQuery;
  ConnGame : TMyConnection;
  label skip;
begin
  // controlla se sono schierati 11 giocatori a parte i disqualified. se pu� farlo deve giocare col massimo dei giocatori
  Result:= False;
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGamePlayers := TMyQuery.Create(nil);
  MyQueryGamePlayers.Connection := ConnGame;   // game

  MyQueryGamePlayers.SQL.text := 'SELECT guid, formation_x,formation_y,disqualified from game.players WHERE team =' + IntToStr(Cli.GuidTeam);
  MyQueryGamePlayers.Execute ;

  pcount:=0;
  pdisq:=0;

  for i := 0 to MyQueryGamePlayers.RecordCount -1 do begin
    if IsOutSideAI( MyQueryGamePlayers.FieldByName ('formation_x').AsInteger,  MyQueryGamePlayers.FieldByName ('formation_y').AsInteger ) or
    (MyQueryGamePlayers.FieldByName ('disqualified').AsInteger > 0) then goto skip;

    if ( MyQueryGamePlayers.FieldByName ('formation_y').AsInteger = 6) or
       (MyQueryGamePlayers.FieldByName ('formation_y').AsInteger = 3) or
       (MyQueryGamePlayers.FieldByName ('formation_y').AsInteger = 9) or
       (MyQueryGamePlayers.FieldByName ('formation_y').AsInteger = 11)  then begin
         Inc(pCount);
       end;
skip:
    MyQueryGamePlayers.Next;
  end;

  for i := 0 to MyQueryGamePlayers.RecordCount -1 do begin
    if MyQueryGamePlayers.FieldByName ('disqualified').AsInteger > 0 then Inc(pDisq);
    MyQueryGamePlayers.Next;
  end;

  // se sono 11 non sqlificati altrimenti...
  if pcount = 11 then begin
    result := True;
  end;

  // qui result � false perch� maggiore o inferiore a 11
  if pcount > 11 then begin
    result := false;
  end;

  // ... ti perdono il fatto che non puoi scherarne 11
  if result = false then begin
    if (MyQueryGamePlayers.RecordCount - pdisq) < 11 then begin
      Result:= True; // formazione valida con quello che � disponibile
    end;

  end;
   MyQueryGamePlayers.Free;
  ConnGame.Connected := false;
  ConnGame.Free;


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
    if  (BrainManager.lstBrain [i].Score.CliId [0] = CliId) or (BrainManager.lstBrain [i].Score.CliId [1] = CliId) then begin
      result := True;
      ReleaseMutex(Mutex);
      Exit;
    end;

  end;
  ReleaseMutex(Mutex);
end;
function TFormServer.inLivematchGuidTeam(GuidTeam: integer ): TSoccerBrain;
var
  i: Integer;
begin
  WaitForSingleObject(Mutex,INFINITE);
  Result := nil;
  for I := BrainManager.lstBrain.Count - 1  downto 0 do begin
    if  (BrainManager.lstBrain [i].Score.TeamGuid [0] = GuidTeam) or (BrainManager.lstBrain [i].Score.TeamGuid  [1] = GuidTeam) then begin
      result := BrainManager.lstBrain [i];
      ReleaseMutex(Mutex);
      Exit;
    end;

  end;
  ReleaseMutex(Mutex);
end;
function TFormServer.inSpectator(Cliid: integer ): Boolean;
var
  i,y: Integer;
begin
  Result := False;
  WaitForSingleObject(Mutex,INFINITE);
  for I := BrainManager.lstBrain.Count - 1  downto 0 do begin
    for Y := 0 to BrainManager.lstBrain [i].lstSpectator.Count - 1 do begin
      if  BrainManager.lstBrain [i].lstSpectator[y]  = CliId then begin
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
      SE_GridLiveMatches.RowCount := BrainManager.lstBrain.Count + 1;  // <-- necessario o bug
      SE_GridLiveMatches.Cells[0,i+1].Text := IntToStr(BrainManager.lstBrain [i].Score.TeamGuid [0]) + '/'+ BrainManager.lstBrain [i].Score.Team [0] + '/' + IntToStr(BrainManager.lstBrain [i].Score.cliId [0]);
      SE_GridLiveMatches.Cells[1,i+1].Text := IntToStr( BrainManager.lstBrain [i].Score.TeamGuid [1]) + '/'+ BrainManager.lstBrain [i].Score.Team [1] + '/' + IntToStr(BrainManager.lstBrain [i].Score.CliId [1]);
      SE_GridLiveMatches.Cells[2,i+1].Text := IntToStr(BrainManager.lstBrain [i].TeamTurn );
      SE_GridLiveMatches.Cells[3,i+1].Text := IntToStr((BrainManager.lstBrain [i].fMilliseconds div 1000) );
      if BrainManager.lstBrain [i].Score.AI[0]  then
        SE_GridLiveMatches.Cells[4,i+1].Text:= 'Active' else  SE_GridLiveMatches.Cells[4,i+1].text:= '';
      if BrainManager.lstBrain [i].Score.AI[1]  then
        SE_GridLiveMatches.Cells[5,i+1].Text:= 'Active' else  SE_GridLiveMatches.Cells[5,i+1].text:= '';

      SE_GridLiveMatches.Cells[6,i+1].Text:= IntToStr(BrainManager.lstBrain [i].Minute );
    end;

    if BrainManager.lstBrain [i].paused or BrainManager.lstBrain[i].Finished then Continue;

    BrainManager.lstBrain [i].milliseconds := BrainManager.lstBrain [i].milliseconds - MatchThread.Interval;

    // aistart
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
  end;


  for I := BrainManager.lstBrain.Count -1 downto 0 do begin
    if BrainManager.lstBrain [i].paused then Continue;
    if BrainManager.lstBrain[i].Finished then // 30 secondi poi cancella il brain
      if GetTickCount - BrainManager.lstBrain[i].FinishedTime > 30000 then
        BrainManager.lstBrain.Delete(i); // libera anche gli spettatori
  end;
  ReleaseMutex(Mutex);


  Application.ProcessMessages;

end;

procedure TFormServer.CreateFormationsPreset;
var
  aF: TFormation;

begin
  aF.d := 5; af.m:=4; aF.f:=1;

  af.cells[2]:= Point (0,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);
  af.cells[6]:= Point (6,9);

  af.cells[7]:= Point (0,6);
  af.cells[8]:= Point (3,6); // cella obbligata
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
  af.cells[8]:= Point (3,6); // cella obbligata
  af.cells[9]:= Point (4,6);
  af.cells[10]:= Point (6,6);

  af.cells[11]:= Point (3,3);
  FormationsPreset.add(af);


  aF.d := 5; af.m:=3; aF.f:=2;
  af.cells[2]:= Point (0,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);
  af.cells[6]:= Point (6,9);

  af.cells[7]:= Point (1,6);
  af.cells[8]:= Point (3,6); // cella obbligata
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
  af.cells[8]:= Point (3,6); // cella obbligata
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
  af.cells[7]:= Point (1,6);
  af.cells[8]:= Point (3,6); // cella obbligata
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
  af.cells[8]:= Point (3,6); // cella obbligata
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
  af.cells[8]:= Point (3,6); // cella obbligata
  af.cells[9]:= Point (6,6);

  af.cells[10]:= Point (1,3);
  af.cells[11]:= Point (5,3);

  FormationsPreset.add(af);

  aF.d := 4; af.m:=3; aF.f:=3;
  af.cells[2]:= Point (1,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);
  af.cells[5]:= Point (4,9);

  af.cells[6]:= Point (0,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6); // cella obbligata

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
  af.cells[8]:= Point (3,6); // cella obbligata

  af.cells[9]:= Point (3,3);
  af.cells[10]:= Point (0,3);
  af.cells[11]:= Point (6,3);

  FormationsPreset.add(af);

  aF.d := 3; af.m:=4; aF.f:=3;
  af.cells[2]:= Point (4,9);
  af.cells[3]:= Point (2,9);
  af.cells[4]:= Point (3,9);

  af.cells[5]:= Point (0,6);
  af.cells[6]:= Point (6,6);
  af.cells[7]:= Point (2,6);
  af.cells[8]:= Point (3,6); // cella obbligata

  af.cells[9]:= Point (3,3);
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
  af.cells[8]:= Point (3,6); // cella obbligata
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
  af.cells[8]:= Point (3,6); // cella obbligata
  af.cells[9]:= Point (4,6);

  af.cells[10]:= Point (2,3);
  af.cells[11]:= Point (4,3);

  FormationsPreset.add(af);

end;

procedure TFormServer.Button2Click(Sender: TObject);
var
  MyQueryAccount,MyQueryWT: TMyQuery;
  sha_pass_hash: string;
  i,arnd: Integer;
  UserName,password, THEWORLDTEAM : string;
  cli: TWSocketThrdClient;
  ConnAccount,ConnWorld : TMyConnection;
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
  ConnWorld.Database:='World';
  ConnWorld.Connected := True;

  MyQueryAccount := TMyQuery.Create(nil);
  MyQueryAccount.Connection := ConnAccount;   // realmd
  MyQueryWT := TMyQuery.Create(nil);
  MyQueryWT.Connection := ConnWorld;   // world

  cli:= TWSocketThrdClient.Create(nil);

  for I := 1 to 100 do begin
    MyQueryAccount.SQL.Text := 'select id from realmd.account where username=' + '"TEST' + IntToStr(i) + '"';
    MyQueryAccount.Execute;
    cli.CliId := MyQueryAccount.FieldByName('id').AsInteger;
    MyQueryWT.SQL.Text := 'select guid from world.teams where serie=1 and rank=1 order by rand() limit 1';
    MyQueryWT.Execute;
    THEWORLDTEAM :=  MyQueryWT.FieldByName('guid').AsString;
    CreateGameTeam ( Cli, THEWORLDTEAM );  // ts[1] � guid world.teams, non la Guidteam
  end;


  cli.Free;
  ConnAccount.Connected := false;
  ConnAccount.Free;
  ConnWorld.Connected:= False;
  ConnWorld.Free;


end;
procedure TFormServer.Button3Click(Sender: TObject);
var
  MyQueryGameTeams,MyQueryWT: TMyQuery;
  i,arnd: Integer;
  ConnGame,ConnWorld : TMyConnection;
begin
// Prende i colori del team reale db.world e lo trasmette a tutti i team eisstenti in db.game
// in questo modo aggiornando solo le maglie di tutte le squadre reali, si aggiornano tutti i team dei giocatori
// eventualmente un oggetto cosmetico pu� essere quello di una uniforme personalizzata

  ConnWorld := TMyConnection.Create(nil);
  ConnWorld.Server := MySqlServerWorld;
  ConnWorld.Username:='root';
  ConnWorld.Password:='root';
  ConnWorld.Database:='World';
  ConnWorld.Connected := True;

  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGameTeams := TMyQuery.Create(nil);
  MyQueryGameTeams.Connection := ConnGame;   // game
  MyQueryWT := TMyQuery.Create(nil);
  MyQueryWT.Connection := ConnWorld;   // world

  MyQueryWT.SQL.Text := 'select guid, uniformh,uniforma from world.teams';
  MyQueryWT.Execute;
  for I := 0 to MyQueryWT.RecordCount -1 do begin
    MyQueryGameTeams.SQL.Text := 'UPDATE game.teams set uniformh="' +
                                  MyQueryWT.FieldByName('uniformh').AsString + '",uniforma="' +
                                  MyQueryWT.FieldByName('uniforma').AsString + '" WHERE worldteam =' + MyQueryWT.FieldByName('guid').AsString;
    MyQueryGameTeams.Execute;
    MyQueryWT.Next;
  end;

  MyQueryGameTeams.Free;
  MyQueryWT.Free;

  ConnGame.Connected:= False;
  ConnGame.Free;
  ConnWorld.Connected:= False;
  ConnWorld.Free;

end;


procedure TFormServer.CreateRandomBotMatch;
var
  i, aRnd : Integer;
  MyQueryGameTeams: TMyQuery;
  OpponentBOT: TServerOpponent;
  ConnGame : TMyConnection;
  label retry1, retry2;
begin
  ConnGame := TMyConnection.Create(nil);
  ConnGame.Server := MySqlServerGame;
  ConnGame.Username:='root';
  Conngame.Password:='root';
  ConnGame.Database:='game';
  ConnGame.Connected := True;

  MyQueryGameTeams := TMyQuery.Create(nil);
  MyQueryGameTeams.Connection := ConnGame;   // game

//  while BrainManager.lstBrain.Count < 10 do begin
    // prendo dal db un test a caso che non sia gi� in lstbrain  ( entercriticalSession
    // WorldTeam esclude automaticamente anche se stessi. Qui cerco sul db un bot

retry1:
      aRnd := RndGenerate (100);
      MyQueryGameTeams.SQL.text := 'SELECT username, guid, worldTeam, rank, nextha, bot from realmd.account INNER JOIN game.teams ON realmd.account.id = game.teams.account WHERE ' +
                                    'username = "TEST' + IntTostr(aRnd) + '" and bot <> 0 and nextha = 0'; // parto dal team0

      MyQueryGameTeams.Execute ;

      if MyQueryGameTeams.RecordCount = 0 then goto retry1; // non nextha
     // if MyQueryGameTeams.RecordCount > 0 then begin
        if inLiveMatchGuidTeam( MyQueryGameTeams.FieldByName('guid').AsInteger ) <> nil then goto retry1;   // gi� in gioco
retry2:
        GetGuidTeamOpponentBOT (  MyQueryGameTeams.FieldByName('worldteam').AsInteger  ,
                                  MyQueryGameTeams.FieldByName('rank').AsInteger  , // marketTeam
                                  MyQueryGameTeams.FieldByName('nextha').AsInteger,
                                  OpponentBOT.GuidTeam,OpponentBOT.UserName   ); // worldteam diversa in opponent, no Bologna vs Bologna
        if inLiveMatchGuidTeam( OpponentBOT.GuidTeam ) <> nil then goto retry2;    // gi� in gioco il secondo

        CreateMatchBOTvsBOT (  MyQueryGameTeams.FieldByName('guid').AsInteger  , OpponentBOT.GuidTeam,
                                MyQueryGameTeams.FieldByName('username').AsString,  OpponentBOT.Username );

     // end;

//  end;
  MyQueryGameTeams.free;
  ConnGame.Connected:= False;
  ConnGame.Free;

end;

end.