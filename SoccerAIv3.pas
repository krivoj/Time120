{$R-}

//{$DEFINE ADDITIONAL_MATCHINFO}
unit SoccerAIv3;


interface
uses generics.collections, generics.defaults, system.classes, System.SysUtils, System.Types, strutils, Soccertypes,dse_pathplanner ;


type
  TSoccerAI = Class
  public
	brain: TObject;
  constructor create ( aBrain: TObject ) ;
  destructor destroy; override;
	procedure xxx ( x: integer );
      procedure AI_Think (Team: integer);   // !! AI intelligenza artificiale
        function AI_Injured_sub_tactic_stay (Team: integer): TBetterSolution; // // ai pensa a sostituzioni/tattiche/muovere,non muovere certi player, spostare il loro defaultcell
        function AI_Think_sub (Team: Integer;anOutPlayer:TObject; SubType: TSubType ): TBetterSolution; // ai pensa a sostituzioni


        function AI_Think_Tactic (Team, cks:integer ): TBetterSolution;   // ai pensa a tattiche
        function AI_Think_StayFree ( team, Cks:integer ): TbetterSolution;  // ai pensa a muovere,non muovere certi player
        function AI_Think_CleanSomeRows (team:Integer): TBetterSolution;    // ai pensa di spostare qualche player
        function AI_ForceRandomMove ( team : Integer ): Boolean;
        function AI_TrySomeBuff ( team: integer ): Boolean;
          function GetDummyTalentInRole ( team, TalentId: integer ): TObject;

      procedure AI_Think_myball_iDefend ( Team: integer );
      procedure AI_Think_myball_middle ( Team: integer  );
      procedure AI_Think_myball_iAttack ( Team: integer );
        function DummyAheadPass( Team: integer ): Boolean;
          function GetDummyAheadPass( Team: integer ): TObject; // in PlayMaker
          function DummyTryCross( Team: integer ): Boolean;
          function DummyReachTheCrossinArea1Moves( aPlayer: TObject; bestAttribute:TAttributeName) : boolean;
          function DummyReachTheCrossinArea2Moves( aPlayer: TObject; bestAttribute:TAttributeName) : boolean;
          function GetDummyCrossFriend ( aPlayer: TObject ): TObject;
          function GetDummyVolleyFriend ( aPlayer: TObject ): TObject;

          procedure DummyFindaWay( Team: integer );
          procedure PosOrPrs (  Team, PosChance: integer );
        // Dummy AI
        function GetDummyGoAheadCell : TPoint;  // il player con la palla cerca di avanzare
        function GetDummyMaxAcceleration(AccelerationMode: TAccelerationMode): TPoint;
        function GetDummyMaxAccelerationShotCells ( OnlyBuffed: boolean ): TPoint; // cerca di raggiungere una shotCell
        function GetDummyMaxAccelerationBottom: TPoint; // cerca il fondo, l'ultima cella
        function GetDummyShpCellXY : TPoint;
          function DummyGetAnyFriendToBall (  dist, team: Integer; meIds:string; CellX, CellY: integer): TObject;
        function GetDummyLopCellXY : Tpoint;
        function GetDummyLopCellXYInfinite : Tpoint;
        function GetDummyLopCellXYfriend : Tpoint; // utile per volley


      procedure AI_Think_oppball_iDefend ( Team: integer  );
      procedure AI_Think_oppball_middle ( Team: integer  );
      procedure AI_Think_oppball_iAttack ( Team: integer  );
          procedure AiDummyTakeTheBall ( Team: integer  );
        function GetdummyTackle (team: Integer): TObject;
        function GetdummyPressing (team: Integer): TObject;

      procedure AI_Think_neutralball_iDefend ( Team: integer );
      procedure AI_Think_neutralball_middle ( Team: integer  );
      procedure AI_Think_neutralball_iAttack ( Team: integer );
        function DummyReachTheBall (  team: Integer): TObject;

    function GetBestGKReserve ( Team,MinStamina: integer ): string;
    function GetBestDefenseReserve ( Team,MinStamina: integer  ): string;
    function GetBestPassingReserve  ( Team,MinStamina: integer ): string;
    function GetBestShotReserve  ( Team,MinStamina: integer ): string;
    function GetWorstStamina ( Team: integer ): TObject;

    function GetPlayerForOUT (team: Integer;  PlayerOUT: TSubOUT ):TObject;
    function GetBestCrossing ( Team: integer ): string;
    function GetBestHeading ( Team: integer; excludeIds: string ): string;
    function GetBestPassing ( Team: integer ): string;
    function GetBestShot ( Team: integer ): string;
    function GetBestBarrier ( Team: integer ): string;

    function GetRandomDefaultMidFieldCellFree ( team:Integer ): TPoint;
    function GetRandomDefaultDefenseCellFree ( team:Integer ): TPoint;
    function GetRandomDefaultForwardCellFree ( team:Integer ): TPoint;

  end;
//  procedure AllocateExpandedPixelBuffer(var ABuffer: TExpandedPixelBuffer; ASize: integer);
//  procedure AllocateExpandedPixelBuffer(var ABuffer: TExpandedPixelBuffer; ASize: integer);
implementation
uses Soccerbrainv3, utilities;
constructor TSoccerAI.create ( aBrain: TObject ) ;
begin
  brain := aBrain;
end;
destructor TSoccerAI.destroy;
begin
  inherited;
end;

procedure TSoccerAI.xxx ( x: integer );
begin
  TBrain(brain).finished := false;
end;
function TSoccerAI.AI_Think_sub ( team: Integer; anOutPlayer:TObject; SubType: TSubType ):TBetterSolution;
var
  ids: string;
  outPlayer : TPlayer;
begin
  OutPlayer := TPlayer ( anOutPlayer );
  // si fanno sempre anche oltre 120+
  if TBrain(brain).CanDoSub ( Team ) then begin  //not gk

    if( AbsDistance(OutPlayer.CellX, OutPlayer.CellY, TBrain(brain).Ball.CellX ,TBrain(brain).Ball.celly) < 4) then begin
      Result := SubAbs4;
      Exit;
    end;

    //same role. in base a D M F  bestdefense, bestshot, bestpassing not gk , ma non al di sotto di 60 (giò checkato in candosub )
    if SubType = PossiblysameRole then begin // arriva da injured o da stamina < 60
      if OutPlayer.Role = 'G' then begin
        ids := GetBestGKReserve( team,61);
        if ids <> '0' then
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SUB)+',' + ids + ',' + OutPlayer.ids  )// potrebe non esserci quindi candosub
        else begin
          Result := SubCant;
          Exit;
        end;
      end
      else if OutPlayer.Role = 'D' then begin
        ids := GetBestDefenseReserve( team,61);
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SUB)+',' + ids + ',' + OutPlayer.ids  );// 1 c'è per forza altrimenti no candosub
      end
      else if OutPlayer.Role = 'M' then begin
        ids := GetBestPassingReserve( team,61);
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SUB)+',' + ids  + ',' + OutPlayer.ids  );// 1 c'è per forza altrimenti no candosub
      end
      else if OutPlayer.Role = 'F' then begin
        ids := GetBestShotReserve( team,61);
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SUB)+',' + ids + ',' + OutPlayer.ids  );// 1 c'è per forza altrimenti no candosub
      end;


    end
    else if SubType = BestShot then begin // arriva da checkTBrain(brain).Score
        ids := GetBestShotReserve( team,61);
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SUB)+',' + ids + ',' + OutPlayer.ids  );// 1 c'è per forza altrimenti no candosub
    end
    else if SubType = BestDefense then begin // arriva da checkTBrain(brain).Score
        ids := GetBestDefenseReserve( team,61);
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SUB)+',' + ids + ',' + OutPlayer.ids  );// 1 c'è per forza altrimenti no candosub
    end
    else if SubType = BestPassing then begin // arriva da checkTBrain(brain).Score
        ids := GetBestPassingReserve( team,61);
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SUB)+',' + ids + ',' + OutPlayer.ids  );// 1 c'è per forza altrimenti no candosub
    end;

    Result := subDone;
  end
  else Result := SubCant;


end;
function TSoccerAI.AI_Think_Tactic ( team , cks: integer):TBetterSolution;
var
  i,D,M,F: integer;
  lstDefense: TObjectList<TPlayer>;
  lstMidfield: TObjectList<TPlayer>;
  lstForward: TObjectList<TPlayer>;
  Newcell:TPoint;
  ids:string;
begin
// Tactic costa mosse com sub
  result := None;
  lstDefense:= TObjectList<TPlayer>.Create(false);
  lstMidfield:= TObjectList<TPlayer>.Create(false);
  lstForward:= TObjectList<TPlayer>.Create(false);

  D:=0; M:=0; F:=0;
  if team = 0 then begin
    for i := 0 to TBrain(brain).Players.Count -1 do begin
      if (TBrain(brain).Players[i].DefaultCellX = 2) then begin
        inc (D);
        lstDefense.Add(TBrain(brain).Players[i]);
      end
      else if (TBrain(brain).Players[i].DefaultCellX = 5) then begin
        inc (M);
        lstMidfield.Add(TBrain(brain).Players[i]);
      end
      else if (TBrain(brain).Players[i].DefaultCellX = 8) then begin
        inc (F);
        lstForward.Add(TBrain(brain).Players[i]);
      end
    end;
  end
  else begin
    for i := 0 to TBrain(brain).Players.Count -1 do begin
      if (TBrain(brain).Players[i].DefaultCellX = 9) then begin
        inc (D);
        lstDefense.Add(TBrain(brain).Players[i]);
      end
      else if (TBrain(brain).Players[i].DefaultCellX = 6) then begin
        inc (M);
        lstMidfield.Add(TBrain(brain).Players[i]);
      end
      else if (TBrain(brain).Players[i].DefaultCellX = 3) then begin
        inc (F);
        lstForward.Add(TBrain(brain).Players[i]);
      end
    end;
  end;

  // ho la fomrazione 4-3-3 5-4-1 ecc...  e le liste per ruolo
  // fatte in modo che sposta prima la difesa verso il centrocampo o il centrocampo verso la difesa gradualemente
  if Cks <= -1  then begin // perdo e basta
    if D >= 4 then begin  // se almeno 4 dif , uno random diventa un midfield
      ids :=  lstDefense[ TBrain(brain).RndGenerate0(lstDefense.Count-1)].Ids ;
      newCell := GetRandomDefaultMidFieldCellFree ( team );
      lstDefense.Free;
      lstMidfield.Free;
      lstForward.Free;
      if Newcell.X <> -1 then begin
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_TACTIC) + ',' + ids + ',' + IntToStr(Newcell.X)+ ',' + IntToStr(Newcell.Y)  );// 1 c'è per forza altrimenti no candosub
        Result := TacticDone;
      end;
      exit;
    end
    else if M >=3 then begin  // se almeno 3 midfield , uno random diventa un forward
      ids :=  lstMidfield[ TBrain(brain).RndGenerate0(lstMidfield.Count-1)].Ids ;
      newCell:= GetRandomDefaultForwardCellFree ( team );
      lstDefense.Free;
      lstMidfield.Free;
      lstForward.Free;
      if Newcell.X <> -1 then begin
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_TACTIC) + ',' + ids + ',' + IntToStr(Newcell.X)+ ',' + IntToStr(Newcell.Y)  );// 1 c'è per forza altrimenti no candosub
        Result := TacticDone;
      end;
      exit;
    end;

  end
  else if Cks >= 1  then begin // vinco e basta
    if M >= 3 then begin// se almeno 3 midfield uno random diventa Ddfender
      ids :=  lstMidfield[ TBrain(brain).RndGenerate0(lstMidfield.Count-1)].Ids ;
      newCell:= GetRandomDefaultDefenseCellFree ( team );
      lstDefense.Free;
      lstMidfield.Free;
      lstForward.Free;
      if Newcell.X <> -1 then begin
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_TACTIC) + ',' + ids + ',' + IntToStr(Newcell.X)+ ',' + IntToStr(Newcell.Y)  );// 1 c'è per forza altrimenti no candosub
        Result := TacticDone;
      end;
      exit;
    end
    else if F >= 2 then begin// se almeno 2 Attaccanti , uno random diventa midfield
      ids :=  lstForward[ TBrain(brain).RndGenerate0(lstForward.Count-1)].Ids ;
      newCell:= GetRandomDefaultMidFieldCellFree ( team );
      lstDefense.Free;
      lstMidfield.Free;
      lstForward.Free;
      if Newcell.X <> -1 then begin
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_TACTIC) + ',' + ids + ',' + IntToStr(Newcell.X)+ ',' + IntToStr(Newcell.Y)  );// 1 c'è per forza altrimenti no candosub
        Result := TacticDone;
      end;
      exit;
    end

  end
  else begin // 0-0
      lstDefense.Free;
      lstMidfield.Free;
      lstForward.Free;
  end;

end;
function TSoccerAI.AI_Think_StayFree ( team, Cks : integer): TbetterSolution;
var
  i:integer;
  aPlayer: TPlayer;
begin
 // se F o M stanno oltre
 // SE M o d stanno più bassi
  Result := none;
  if TBrain(brain).Minute >= 120 then // oltre 120 non lo puo' fare
    Exit;

  if Cks <= -1  then begin // perdo e basta
    if team = 0 then begin
      for I := 0 to TBrain(brain).Players.count -1 do begin
        aPlayer :=TBrain(brain).Players[i];   // attenzione, se non è giò settato STAY
        if (aPlayer.role='F') and (aPlayer.Team=team) and (aPlayer.cellX > aPlayer.DefaultCellX) and (not aPlayer.stay ) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_STAY) + ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end
        else if (aPlayer.role='M') and (aPlayer.Team=team) and (aPlayer.cellX > aPlayer.DefaultCellX) and (not aPlayer.stay ) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_STAY) + ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end;
      end;
    end
    else if team = 1 then begin
      for I := 0 to TBrain(brain).Players.count -1 do begin
        aPlayer :=TBrain(brain).Players[i];   // attenzione, se non è giò settato STAY
        if (aPlayer.role='F') and (aPlayer.Team=team) and (aPlayer.cellX < aPlayer.DefaultCellX) and (not aPlayer.stay ) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_STAY) + ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end
        else if (aPlayer.role='M') and (aPlayer.Team=team) and (aPlayer.cellX < aPlayer.DefaultCellX) and (not aPlayer.stay ) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_STAY) + ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end;
      end;

    end;

  end
  else if Cks = 0 then begin // pareggio, applico i free , non importa il team
      for I := 0 to TBrain(brain).Players.count -1 do begin
        aPlayer :=TBrain(brain).Players[i];   // attenzione, se non è giò settato STAY
        if (aPlayer.stay) and (aPlayer.Team=team) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_FREE)+ ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end
      end;
  end
  else if  Cks >= -1  then begin // vinco e basta        // va bene < e > diversi da sopra.
    if team = 0 then begin
      for I := 0 to TBrain(brain).Players.count -1 do begin
        aPlayer :=TBrain(brain).Players[i];   // attenzione, se non è giò settato STAY
        if (aPlayer.role='F') and (aPlayer.Team=team) and (aPlayer.cellX < aPlayer.DefaultCellX) and (not aPlayer.stay ) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_STAY) + ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end
        else if (aPlayer.role='M') and (aPlayer.Team=team) and (aPlayer.cellX < aPlayer.DefaultCellX) and (not aPlayer.stay ) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_STAY) + ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end;
      end;
    end
    else if team = 1 then begin
      for I := 0 to TBrain(brain).Players.count -1 do begin
        aPlayer :=TBrain(brain).Players[i];   // attenzione, se non è giò settato STAY
        if (aPlayer.role='F') and (aPlayer.Team=team) and (aPlayer.cellX > aPlayer.DefaultCellX) and (not aPlayer.stay ) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_STAY) + ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end
        else if (aPlayer.role='M') and (aPlayer.Team=team) and (aPlayer.cellX > aPlayer.DefaultCellX) and (not aPlayer.stay ) then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_STAY) + ',' + aPlayer.ids);
          Result := StayFreeDone;
          Exit;
        end;
      end;

    end;

  end;

end;
function TSoccerAI.AI_Think_CleanSomeRows ( team:Integer): TBetterSolution;
var
  x: integer;
  aPlayer: TPlayer;
  lstSameRow: TObjectlist<TPlayer>;
  aplmcell: TPoint;
  ids:string;
begin
  // solo roga 0 e 6 . Le fascie tendono a popolarsi
  result := none;
  lstSameRow:= TObjectlist<TPlayer>.create(false);
  for x := 1 to 10 do begin // not gk, sono esclusi
      aPlayer:= TBrain(brain).GeTPlayer ( x, 0 );
      if aPlayer = nil then continue;
      if (aPlayer.team = team) and ( not aPlayer.hasBall) and (aPlayer.canMove) then
        lstSameRow.add(aPlayer);
  end;

  if lstSameRow.count >= 3 then begin
      aPlayer:= lstSameRow[ TBrain(brain).RndGenerate0 (lstSameRow.Count-1)];
      ids:= aPlayer.Ids; //lstSameRow[ RndGenerate0 (lstSameRow.Count-1)].Ids ;
      aplmCell:= TBrain(brain).GetRandomCellNO06 ( aPlayer.CellX, aPlayer.CellY, aPlayer.Speed  );
      if aplmCell.X <> -1 then begin
        TBrain(brain).GetPath (aPlayer.Team , aPlayer.CellX , aPlayer.CellY, aplmcell.x, aplmcell.y, aPlayer.speed{Limit},false{useFlank},false{FriendlyWall},
                         false{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, aPlayer.MovePath );
          if aPlayer.MovePath.Count > 0 then begin
            TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + Ids +',' +
                        IntToStr(aPlayer.MovePath[aPlayer.MovePath.Count-1].X) +','+ IntToStr(aPlayer.MovePath[aPlayer.MovePath.Count-1].Y));
            Result := CleanRowDone;
          end;
      end;
      lstSameRow.free;
      Exit;
  end;

  lstSameRow.clear;  // le righe 0
  for x := 1 to 10 do begin // not gk, sono esclusi
      aPlayer:=TBrain(brain).GeTPlayer ( x, 6 );   // riga 6
      if aPlayer = nil then continue;
      if (aPlayer.team = team) and ( not aPlayer.hasBall) and (aPlayer.canMove) then
        lstSameRow.add(aPlayer);
  end;

  if lstSameRow.count >= 3 then begin
      aPlayer:= lstSameRow[ TBrain(brain).RndGenerate0 (lstSameRow.Count-1)];
      ids:= aPlayer.Ids; //lstSameRow[ RndGenerate0 (lstSameRow.Count-1)].Ids ;
      aplmCell:= TBrain(brain).GetRandomCellNO06 ( aPlayer.CellX, aPlayer.CellY, aPlayer.Speed  );
      if aplmCell.X <> -1 then begin
        TBrain(brain).GetPath (aPlayer.Team , aPlayer.CellX , aPlayer.CellY, aplmcell.x, aplmcell.y, aPlayer.speed{Limit},false{useFlank},false{FriendlyWall},
                         false{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, aPlayer.MovePath );
          if aPlayer.MovePath.Count > 0 then begin
            TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + Ids +',' +
                        IntToStr(aPlayer.MovePath[aPlayer.MovePath.Count-1].X) +','+ IntToStr(aPlayer.MovePath[aPlayer.MovePath.Count-1].Y));
            Result := CleanRowDone;
          end;
      end;
      lstSameRow.free;
      Exit;
  end;

  lstSameRow.free;

end;
function TSoccerAI.AI_ForceRandomMove ( team : Integer ): Boolean;
var
  i: Integer;
  aPlayer : TPlayer;
  aplmcell: TPoint;
begin
  Result := false;
  for i := TBrain(brain).Players.Count -1 downto 0 do begin // not gk, sono esclusi
      aPlayer:= TBrain(brain).Players[i];
      if aPlayer.Team  <> team then continue;
      if (aPlayer.team = team) and ( not aPlayer.hasBall) and (aPlayer.canMove) and (aPlayer.TalentId1 <> TALENT_ID_GOALKEEPER) then begin

        aplmCell:= TBrain(brain).GetRandomCellNOplayer ( aPlayer.CellX, aPlayer.CellY, aPlayer.Speed  );
        if aplmCell.X <> -1 then begin
          TBrain(brain).GetPath (aPlayer.Team , aPlayer.CellX , aPlayer.CellY, aplmcell.x, aplmcell.y, aPlayer.speed{Limit},false{useFlank},false{FriendlyWall},
                           false{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, aPlayer.MovePath );
            if aPlayer.MovePath.Count > 0 then begin
              TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + aPlayer.Ids +',' +
                          IntToStr(aPlayer.MovePath[aPlayer.MovePath.Count-1].X) +','+ IntToStr(aPlayer.MovePath[aPlayer.MovePath.Count-1].Y));
              Result := true;
              Exit; // importante o ripete sempre.
            end;
        end;
      end;
  end;

end;
function TSoccerAI.AI_Injured_sub_tactic_stay (Team: integer): TBetterSolution;
var
  anInjured,aWorstStamina,OutPlayer: TPlayer;
//  aSol :TBetterSolution;
  aRnd,Cks:integer;
  label Tryrows;
begin
  // ci deve sempre essere EXIT.

  if TBrain(brain).CanDoSub ( Team ) then begin  //not gk
    // check injured player
    anInjured := TBrain(brain).GetInjuredPlayer ( team );
    if anInjured <> nil then begin
      Result := AI_Think_sub ( team, anInjured, possiblysamerole ); //result = abs4, SubDone, None
        if (Result = SubAbs4)  or (result = SubCant) then
          goto Tryrows
          else if (Result = SubDone) then
            Exit;
    end;
    // semplice sostituzione in base alla stamina quando cala c'è più probabilità
    aWorstStamina:= TPlayer( GetWorstStamina (team));   // può ancxhe essere uno appena entrato
    if aWorstStamina.Stamina <= 60 then begin
      aRnd := TBrain(brain).RndGenerate(120);
      if aRnd >= aWorstStamina.Stamina then begin   // la stamina cala, quindi la chance aumenta
        Result := AI_Think_sub ( team, aWorstStamina, possiblysamerole ); //result = abs4, SubDone, None
        if (Result = SubAbs4)  or (result = SubCant) then
          goto Tryrows
          else if (Result = SubDone) then
            Exit;
      end;
    end;

    // checkTBrain(brain).Score e secondo tempo fminute --> sub tactic stay/free
    if TBrain(brain).fMinute >= 80 then begin   // 80 su 120

        Cks := TBrain(brain).CheckScore (team);
        if Cks <= -2  then begin // perdo di 2 gol o più
          OutPlayer := TPlayer( GetPlayerForOUT (team,  DefenderOUT )); // un midfield può uscire al posto di un defender, dipende
          if OutPlayer <> nil then begin
            aRnd := TBrain(brain).RndGenerate(120);
            if aRnd <= TBrain(brain).fminute  then begin   // fminute incrementa, la chance si alza
            Result := AI_Think_sub ( team, OutPlayer, BestShot ); //result = abs4, SubDone, None
              if (Result = SubAbs4)  or (result = SubCant) then
                goto Tryrows
                else if (Result = SubDone) then
                  Exit;
            end;
          end;
          // seguirà tactics
        end
        else if Cks = -1  then begin  // perdo di 1 gol
          OutPlayer := TPlayer(GetPlayerForOUT (team,  DefenderOUT )); // un midfield può uscire al posto di un defender, dipende
          if OutPlayer <> nil then begin
            aRnd := TBrain(brain).RndGenerate(120);
            if aRnd <= TBrain(brain).fminute  then begin   // fminute incrementa, la chance si alza
            Result := AI_Think_sub ( team, OutPlayer, BestShot ); //result = abs4, SubDone, None
              if (Result = SubAbs4)  or (result = SubCant) then
                goto Tryrows
                else if (Result = SubDone) then
                  Exit;
            end;
          end;
          // seguirà tactics
        end
    //    else if Cks = 0  then begin  // pareggio
    //    end
        else if Cks = 1  then begin  // vinco di 1 gol
          OutPlayer := TPlayer(GetPlayerForOUT (team,  forwardOUT )); // un midfield può uscire al posto di un defender, dipende
          if OutPlayer <> nil then begin
            aRnd := TBrain(brain).RndGenerate(120);
            if aRnd <= TBrain(brain).fminute  then begin   // fminute incrementa, la chance si alza
            Result := AI_Think_sub ( team, OutPlayer, BestDefense ); //result = abs4, SubDone, None
              if (Result = SubAbs4)  or (result = SubCant) then
                goto Tryrows
                else if (Result = SubDone) then
                  Exit;
            end;
          end;
          // seguirà tactics
        end
        else if Cks >= 2  then begin  // vinco di 2 gol o più
          OutPlayer := TPlayer(GetPlayerForOUT (team,  forwardOUT )); // un midfield può uscire al posto di un forward, dipende
          if OutPlayer <> nil then begin
            aRnd := TBrain(brain).RndGenerate(120);
            if aRnd <= TBrain(brain).fminute  then begin   // fminute incrementa, la chance si alza
            Result := AI_Think_sub ( team, OutPlayer, BestDefense ); //result = abs4, SubDone, None
              if (Result = SubAbs4)  or (result = SubCant) then
                goto Tryrows
                else if (Result = SubDone) then
                  Exit;
            end;
          end;
          // seguirà tactics
        end;
    end;  // minute 80
  end; // candosub

  // TACTICS
  // qui Result = SubCant oppure semplicemente nil oppure candosub = false;  oppure pareggio quindi no sub
  if TBrain(brain).fMinute >= 120 then begin   // 120+
    // non puo' fare tactics
    goto Tryrows;
  end;
  if TBrain(brain).fMinute >= 80 then begin   // 80 su 120
      // Tactic sempre dentro >= 80
      Cks := TBrain(brain).CheckScore (team);
      Result := AI_Think_Tactic ( team, Cks );
      if Result = TacticDone then
        Exit;
  end;
  if TBrain(brain).fMinute >= 85 then begin   // 85 su 120
      // Stay/Free sempre dentro >= 100 ultimi 20
      Cks := TBrain(brain).CheckScore (team);
      Result := AI_Think_StayFree ( team, Cks ); // in caso di pareggio elimino gli stay con i free
      if Result = StayFreeDone then
        Exit;
      // se F +1 M +2
  end;


  // in ultimo pulisoc le righe
Tryrows:
  Result := AI_Think_CleanSomeRows ( team );

end;
procedure TSoccerAI.AI_Think (team: integer);
var
  tmp: TStringList;
  cof,fkf2,fkf3,fkf4: string;
  ShpOrLop: Integer;
  dstCell: TPoint;
  CornerMap: TCornerMap;
  aHeadingFriend: TPlayer;
  aSol:TBetterSolution;
  label lopfkf1;
begin
  if (not TBrain(brain).GameStarted) or (TBrain(brain).Finished) then Exit;

  // Prima vengono processate le palle inattive, corner, punizioni ecc..

  if TBrain(brain).w_Coa  then begin
    cof := GetBestCrossing ( Team );
    tmp:= TstringList.Create;
    tmp.commatext :=  GetBestHeading ( Team, cof );
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_CORNER_ATTACK_SETUP) + ',' + cof + ',' + tmp[0] + ',' + tmp[1] + ',' + tmp[2]  );
    tmp.free;
    Exit;
  end
  else if TBrain(brain).w_Cod then begin
   (* COD1 COD2 COD3 *)
    tmp:= TstringList.Create;
    tmp.commatext :=  GetBestHeading ( Team, '' );
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_CORNER_DEFENSE_SETUP) + ',' + tmp[0] + ',' + tmp[1] + ',' + tmp[2]   );
    tmp.Free;
    Exit;
  end
  else if TBrain(brain).w_CornerKick then begin
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_COR)  );
    Exit;
  end

  (*------------------------------------------------------------------------*)
  else if TBrain(brain).w_Fka1 then begin
    cof := GetBestPassing ( Team );
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_FREEKICK1_ATTACK_SETUP) + ',' + cof   );
    Exit;
  end
  else if TBrain(brain).w_FreeKick1 then begin
    ShpOrLop := TBrain(brain).RndGenerate(100);

    case ShpOrLop of
      65..100: begin
        dstCell:= GetDummyShpCellXY;
        if dstCell.X <> -1 then
            TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SHP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y) ) else goto lopfkf1;
        end;
      1..64: begin
lopfkf1:
        dstCell:= GetDummyLopCellXYFriend;
        if dstCell.X <> -1 then begin
            TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',N' );
        end
        else begin
          dstCell:= GetDummyLopCellXY;
          if dstCell.X <> -1 then  begin
            TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',N' );
          end
          else  begin   // un portiere che non può fare nulla, nel lop, ne shp --> speciale maxrangeLop fino a 11 o 0
              dstCell:= GetDummyLopCellXYinfinite;
              TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP) +','  + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',GKLOP' )  // vale anche per FKF1 ok bug no celle libere
          end;
        end;

      end;
    end;

    Exit;

  end
  (*------------------------------------------------------------------------*)

  else if TBrain(brain).w_fka2 then begin   // chi tira punizione/cross e saltatori attacco
    fkf2 := GetBestCrossing ( Team );
    tmp:= TstringList.Create;
    tmp.commatext :=  GetBestHeading ( Team, fkf2 );
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_FREEKICK2_ATTACK_SETUP) + ',' + fkf2 + ',' + tmp[0] + ',' + tmp[1] + ',' + tmp[2]  );
    tmp.free;
    Exit;
  end
  else if TBrain(brain).w_fkd2 then begin   // saltatori difesa
    tmp:= TstringList.Create;
    tmp.commatext :=  GetBestHeading ( Team, '' );
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_FREEKICK2_DEFENSE_SETUP) + ',' +  tmp[0] + ',' + tmp[1] + ',' + tmp[2]  );
    tmp.free;
    Exit;
  end
  else if TBrain(brain).w_FreeKick2 then begin
    CornerMap := TBrain(brain).GetCorner ( TBrain(brain).TeamTurn , TBrain(brain).Ball.CellY, OpponentCorner );

    // cerco il saltatore centrale, di solito quello più forte
    aHeadingFriend := TBrain(brain).GeTPlayer ( CornerMap.HeadingCellA [0].X , CornerMap.HeadingCellA [0].Y  );

    TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_CRO2) + ','  + IntToStr(aHeadingFriend.CellX) + ',' + IntToStr( aHeadingFriend.CellY)  );
    Exit;
  end
  (*------------------------------------------------------------------------*)

  else if TBrain(brain).w_fka3 then begin  // singolo tiratore
    fkf3 := GetBestShot ( Team );
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_FREEKICK3_ATTACK_SETUP) + ',' + fkf3   );
    Exit;
  end
  else if TBrain(brain).w_fkd3 then begin // barriera
    tmp:= TstringList.Create;
    tmp.commatext :=  GetBestBarrier ( Team );
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_FREEKICK3_DEFENSE_SETUP) + ',' +  tmp[0] + ',' + tmp[1] + ',' + tmp[2] + ',' + tmp[3] );
    tmp.free;
    Exit;
  end
  else if TBrain(brain).w_FreeKick3 then begin   // la punizione shot
   // o pos o prs. se ho uomini in area posso provare pos perchè ottengono il rimbalzo
   if TBrain(brain).GetFriendInCrossingArea ( TBrain(brain).Ball.Player )  then begin // absdistance è sempre ok
     PosOrPrs ( TBrain(brain).Score.TeamGuid [team], 30 )
   end
   else PosOrPrs ( TBrain(brain).Score.TeamGuid [team], 1 ); // comunque 1%
   Exit;
  end
  (*------------------------------------------------------------------------*)
  else if TBrain(brain).w_fka4 then begin // rigorista
    fkf4 := GetBestShot ( Team );
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_FREEKICK4_ATTACK_SETUP) + ',' + fkf4   );
    Exit;
  end
  else if TBrain(brain).w_FreeKick4 then begin // il rigore
   // o pos o prs. con pos e parata il corner è 100%
    PosOrPrs ( TBrain(brain).Score.TeamGuid [team], 10 );
    Exit;
  end;

    { ai sostituzioni stamina e tattiche }

  ASol := AI_Injured_sub_tactic_stay ( team );
  if (ASol = subDone ) or (ASol = tacticDone )  or (ASol = StayfreeDone ) or (aSol = CleanRowDone ) //or (aSol = SubAbs4) // bug risolto
    then Exit; // se abs4 passo al giro dop ma proseguo qui sotto, se stay/free per il momento nulla


  if TBrain(brain).Ball.Player <> nil then begin
    if TBrain(brain).Ball.Player.Team = team  then begin    // palla mio turno sempre mio
      case TBrain(brain).Ball.Zone  of     // TBrain(brain).Ball.Zone  0 2 1
        0: begin
          if  team = 0 then begin             // mio turno ho la palla in difesa
            AI_Think_myBall_iDefend ( team ); // ----> converte output in reale
          end
          else if  team = 1 then begin        // mio turno ho la palla in attacco
            AI_Think_myBall_iAttack ( team);
          end;
        end;
        1: begin
          if  team = 0 then begin             // mio turno ho la palla in attacco
            AI_Think_myBall_iAttack ( team);

          end
          else if  team = 1 then begin        // mio turno ho la palla in difesa
            AI_Think_myBall_iDefend ( team);
          end;

        end;
        2: begin
            AI_Think_myBall_middle ( team );

        end;
      end;
    end
    else begin                                    // palla loro
      case TBrain(brain).Ball.Zone  of
        0: begin
          if  team = 0 then begin             // sono blu Loro hanno la palla in difesa
            AI_Think_oppBall_iDefend ( team );

          end
          else if  team = 1 then begin        // sono 0 Loro hanno la palla in attacco
            AI_Think_oppBall_iAttack ( team );
            //
          end;

        end;
        1: begin
          if  team = 0 then begin             // sono 1 Loro hanno la palla in attacco
            AI_Think_oppBall_iAttack ( team );

          end
          else if  team = 1 then begin        // sono 0 Loro hanno la palla in difesa
            AI_Think_oppBall_iDefend ( team );

          end;

        end;
        2: begin
            AI_Think_oppBall_middle ( team );
        end;
      end;

    end;
  end                                           // palla neutra  Dummy reachtheTBrain(brain).Ball
  else begin
      case TBrain(brain).Ball.Zone  of
        0: begin
          if  team = 0 then begin             // mio turno palla neutra nella mia difesa
            AI_Think_neutralBall_iDefend ( team );
          end
          else if  team = 1 then begin             // sono 1 palla neutra in attacco
            AI_Think_neutralBall_iAttack ( team );
          end;

        end;
        1: begin
          if  team = 0 then begin             // sono 1 palla neutra nella mia difesa
            AI_Think_neutralBall_iAttack ( team );
          end
          else if  team = 1 then begin             // sono 0 palla neutra in attacco
            AI_Think_neutralBall_idefend ( team );
          end;


        end;
        2: begin
          AI_Think_neutralBall_middle ( team  );  // palla neutra centrocampo
        end;
      end;

  end;
end;
procedure TSoccerAI.AI_Think_myBall_iDefend ( Team: integer );
var
  ShpOrLopOrPlm: Integer;
//  aList: TList<TAimidChance>;
  dstCell: TPoint;
  aDoor,aPlmCell: TPoint;
  aSol : TBetterSolution;
  label lopdef;
begin
(*  MidChances := Tlist<TAIMidChance>.Create;*)
      // Dummy AI
// COPIATA SEMPRE DA AI_Think_myTBrain(brain).Ball_middle ma il GK non può fare short.passing

  if not TBrain(brain).Ball.Player.CanSkill  then begin
    aSol := AI_Injured_sub_tactic_stay(team);
    if  (aSol = none) or (aSol = SubAbs4) or (aSol = SubCant) then begin // subCant non arriva mai. candosub è chechata prima
      if TBrain(brain).Minute < 120 then
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_PASS)  ) // o ha fatto qualcosa o passo
        else AI_ForceRandomMove ( Team );
    end;
      Exit;
  end;


  if TBrain(brain).Ball.Player.TalentId1 = TALENT_ID_GOALKEEPER then begin  // problema getlinepoints per short.passing
    dstCell:= GetDummyLopCellXYinfinite;
    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP)+','  + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y) + ',GKLOP');
    Exit;
  end;

  if DummyAheadPass ( team ) then Exit;


 // mia metacampo in difesa AI SHP or LOP

  ShpOrLopOrPlm := TBrain(brain).RndGenerate(100);
  case ShpOrLopOrPlm of
    81..100: begin
      dstCell:= GetDummyShpCellXY;
      if dstCell.X <> -1 then begin
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SHP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y) );
        exit;
      end
      else goto lopdef;
    end;
    21..80: begin  // punto la porta
      if (not TBrain(brain).Ball.Player.canMove) or ( TBrain(brain).Ball.Player.Role = 'G' ) then goto lopdef;

      aDoor:= TBrain(brain).GetOpponentDoor(TBrain(brain).Ball.Player);
      if aDoor.X = 0 then aDoor.X:= 1 else // il fondo
      if aDoor.X = 11 then aDoor.X:= 10; // il fondo
          // MoveValue := TBrain(brain).Ball.player.speed-1;
          // if MoveValue <=0 then MoveValue := 1;
      aplmCell:= GetDummyMaxAcceleration (AccSelfY );
      if aplmCell.X <> -1 then begin
          TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
          exit;
      end;
      aplmCell:= GetDummyMaxAcceleration (AccBestDistance);
      if aplmCell.X <> -1 then begin
          TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM) +',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
          exit;
      end
      else begin  // se non c'è maxacceleration cerco un path verso la porta. se è tutto chiuso mi muovo in avanti di 1
          // provo a puntare la porta anche in diagonale di 1 o anche speed
          aplmCell:= GetDummyGoAheadCell;   // si muove solo di 2 in su??????
          if aplmCell.X <> -1 then begin
            TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
            exit;
          end
          else goto lopdef; // se proprio non c'è path provo lop
      end
    end;
    1..20: begin
  lopdef:
      dstCell:= GetDummyLopCellXYFriend;  // prima cerca un compagno
      if dstCell.X <> -1 then begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',N' );
          Exit;
      end
      else begin
        dstCell:= GetDummyLopCellXY;
        if dstCell.X <> -1 then  begin
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',N' );
          Exit;
        end
        else if TBrain(brain).Ball.Player.TalentId1 <> TALENT_ID_GOALKEEPER then begin
          if AI_Think_CleanSomeRows ( team ) = None then begin   // se non riesco a pulire le row e col
            if not AI_TrySomeBuff ( team )then begin                        // provo un buff, se non ho buffato, nel senso non ho la skill nei 3 reparti
              TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PRO));
              Exit;
            end;
          end;

        end
        else  begin   // un portiere che non può fare nulla, nel lop, ne shp --> speciale maxrangeLop fino a 11 o 0
          dstCell:= GetDummyLopCellXYinfinite;
          TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP)+','  + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y) + ',GKLOP');
          Exit;
        end;
      end;

    end;
  end;
  // 2-4 mosse. check lop su friend per volley. valuto rischio


      Exit;
  case TBrain(brain).fTeamMovesLeft of
    2..4:begin
      // non calcolo shp free o non free

      // 2-4 mosse. check plmTBrain(brain).Ball speed. valuto rischio
      // 2-4 mosse. check shp a seguire.  valuto rischio
      // 2-4 mosse. check shp diretto . valuto rischio
      // 2-4 mosse. check plm a seguire e poi shp. valuto rischio
      // 2-4 mosse. check plm e poi shp diretto. valuto rischio
      // 2-4 mosse. check lop a seguire. valuto rischio
      // 2-4 mosse. check lop su friend. valuto rischio
      // 2-4 mosse. check plm e Lop a seguire. valuto rischio
      // 2-4 mosse. check plm e lop su friend. valuto rischio
      // ultima: 4 mosse. check plMove. se può farlo  sulle celledefaultX i difensori offensivi o difensivi se fuori celladefaultX

      (*      MidChance := ai_check_plmTBrain(brain).BallSpeed ( Team );
      if MidChance.Chance >= 0 then MidChances.Add(MidChance);
      MidChance := ai_check_shpCell ( Team );
      if MidChance.Chance >= 0 then MidChances.Add(MidChance); QUESTA ANDAVA BENE*)
      {
      MidChance := ai_check_shpFriend ( Team );
      MidChances.Add(MidChance);
      MidChance := ai_check_plmMove_shp ( Team );
      MidChances.Add(MidChance);
      MidChance := ai_check_plmMove_shpFriend ( Team );
      MidChances.Add(MidChance);
      MidChance := ai_check_lopCell ( Team );
      MidChances.Add(MidChance);
      MidChance := ai_check_lopFriend ( Team );
      MidChances.Add(MidChance);
      MidChance := ai_check_plmMove_lopCell ( Team );
      MidChances.Add(MidChance);
      MidChance := ai_check_plmMove_lopFriend ( Team );
      MidChances.Add(MidChance); x

      if MidChance <= 50 then begin
       if ai_plmTBrain(brain).BallMove (1) = 0 then begin
         // non mi posso muovere. prendo la migliore MidChance
       end;

      end
      else begin

      end; }
    end;
    1:begin
      // 1 mossa. check protection. valuto rischio
      // 1 mosse. check lop a seguire. valuto rischio
      // 1 mosse. check lop su friend. valuto rischio

    end;

  end;

  (*if MidChances.Count > 0 then TBrain(brain).BrainInput(  MidChances[0].inputAI );
  MidChances.Free;*)
end;

procedure TSoccerAI.AI_Think_myBall_middle ( Team: integer  );
var
  dstCell: TPoint;
  ShpOrLopOrPlm,ShotCellsOrBottom,aRnd: Integer;
  aDoor,aPlmCell,aplmCell2: TPoint;
  aSol: TBetterSolution;
  label lopdef,lopatt,plmmoveatt,normalversion;
begin

  if not TBrain(brain).Ball.Player.CanSkill  then begin
    aSol := AI_Injured_sub_tactic_stay(team);
    if  (aSol = none) or (aSol = SubAbs4) or (aSol = SubCant) then begin // subCant non arriva mai. candosub è chechata prima
      if TBrain(brain).Minute < 120 then
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_PASS)  ) // o ha fatto qualcosa o passo
        else AI_ForceRandomMove ( team );
    end;
      Exit;
  end;
  // se il TBrain(brain).Ball.player ha una speed > 2 penso in un modo, altrimenti posso pensare in un un altro.
  aRnd := TBrain(brain).RndGenerate(100);
  if aRnd > 70 then goto normalversion;// 70% speed version  30% normal version


      {  provo a puntare una shotcell > 2 se speed > 2}
  if (TBrain(brain).Ball.Player.canMove) and (TBrain(brain).Ball.Player.Speed > 2) then begin // quindi minimo 3 che diventa 2 con la palla
    aplmCell.X := -1;
    aplmCell2.X := -1;
    ShotCellsOrBottom :=0;
    // vedo se è possibile raggiungere una shotcell con buff
    aplmCell:= GetDummyMaxAccelerationSHotCells( True {OnlyBuffed} ) ;
    // se sono sulle fascie posso cercare il fondo per un cross se ho almeno 1 friendly in area o sulla celly dell'area per eventuale inserimento
    if (TBrain(brain).Ball.Player.CellY = 0) or (TBrain(brain).Ball.Player.CellY = 1) or (TBrain(brain).Ball.Player.CellY = 5) or (TBrain(brain).Ball.Player.CellY = 6) then begin // se sono sulle fascie
      aplmCell2:= GetDummyMaxAccelerationBottom ; // GetDummyMaxAcceleration (AccSelfY ) + check è sul fondo (ultima o penultima cella)
    end;

    // o ho 2 possibilità (fondo o shotcell o solo una delle 2 o nessuna delle 2
    if (aplmCell.X <> -1) and (aplmCell2.X <> -1)
      then  ShotCellsOrBottom := 50
        else if aplmCell.X <> -1 then begin
          TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
          exit;
        end
        else if aplmCell2.X <> -1 then begin
          TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell2.X) +','+ IntToStr(aplmCell2.Y));
          exit;
        end;

    // se arrivo qui significa che ho tutte e le possibilità

    if  ShotCellsOrBottom = 50 then begin
     aRnd :=TBrain(brain).RndGenerate (100);
     case aRnd of
          1..50: begin
            TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
            exit;
          end;
          51..100: begin
            TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell2.X) +','+ IntToStr(aplmCell2.Y));
            exit;
          end;
     end;
    end;
  end;
normalversion:
    // qui nel caso la speed di TBrain(brain).Ball.player sia inferiore a 3
    if DummyAheadPass ( team ) then Exit;  // provo un shp dritto

      // la palla si sposta , devo sempre usare exit
      // mia metacampo AI SHP or LOP
      if ((Team = 0) and (TBrain(brain).Ball.Player.CellX < 6)) or ((Team = 1) and (TBrain(brain).Ball.Player.CellX > 5)) then begin
        ShpOrLopOrPlm := TBrain(brain).RndGenerate(100);

//        ShpOrLopOrPlm:= 33;
        case ShpOrLopOrPlm of
          81..100: begin
            dstCell:= GetDummyShpCellXY;
            if dstCell.X <> -1 then begin
              TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SHP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y) );
              Exit;
            end
            else goto lopdef;
          end;
          21..80: begin  // punto la porta
            if not TBrain(brain).Ball.Player.canMove then goto lopdef;

            aDoor:= TBrain(brain).GetOpponentDoor(TBrain(brain).Ball.Player);
            if aDoor.X = 0 then aDoor.X:= 1 else // il fondo
            if aDoor.X = 11 then aDoor.X:= 10; // il fondo

//                 MoveValue := TBrain(brain).Ball.player.speed-1;
//                 if MoveValue <=0 then MoveValue := 1;
            // cerco una massima accelerazione. se non la trovo cerco un path verso la porta
            aplmCell:= GetDummyMaxAcceleration (AccSelfY );
            if aplmCell.X <> -1 then begin
                TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
                exit;
            end;
            aplmCell:= GetDummyMaxAcceleration (AccBestDistance );
            if aplmCell.X <> -1 then begin
                TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
                Exit;
            end
            else begin  // se non c'è maxacceleration cerco un path verso la porta. se è tutto chiuso mi muovo in avanti di 1

                // provo a puntare la porta anche in diagonale di 1 o anche speed
                aplmCell:= GetDummyGoAheadCell;   // si muove solo di 2 in su??????
                if aplmCell.X <> -1 then begin
                  TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
                 Exit;
                end
                else goto lopdef; // se proprio non c'è path provo lop
            end;
          end;

          1..20: begin
lopdef:
            dstCell:= GetDummyLopCellXYFriend;
            if dstCell.X <> -1 then begin
                TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',N' );
                Exit;
            end
            else begin
              dstCell:= GetDummyLopCellXY;
              if dstCell.X <> -1 then  begin
                TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',N' );
                Exit;
              end
              else if TBrain(brain).Ball.Player.TalentId1 <> TALENT_ID_GOALKEEPER then begin
                if AI_Think_CleanSomeRows ( team ) = None then begin   // se non riesco a pulire le row e col
                  if not AI_TrySomeBuff (team) then begin                        // provo un buff, se non ho buffato, nel senso non ho la skill nei 3 reparti
                    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PRO));
                    Exit;
                  end;
                end;

              end
              else  begin   // un portiere che non può fare nulla, nel lop, ne shp --> speciale maxrangeLop fino a 11 o 0
                dstCell:= GetDummyLopCellXYinfinite;
                TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_LOP)+','  + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',GKLOP' );
                exit;
              end;
            end;

          end;
        end;
      end
      // loro metacampo AI SHP or PRO or Puntolaporta in cellX (niente lop a vuoto)
      else if ((Team = 0) and (TBrain(brain).Ball.Player.CellX > 5)) or ((Team = 1) and (TBrain(brain).Ball.Player.CellX < 6)) then begin
        ShpOrLopOrPlm := TBrain(brain).RndGenerate(100);
        case ShpOrLopOrPlm of
          60..100: begin
            dstCell:= GetDummyShpCellXY;
            if dstCell.X <> -1 then begin
              TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_SHP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y) );
              exit;
            end
            else goto plmmoveatt;
          end;
          16..59: begin  // 43% punto la porta
plmmoveatt:
            if not TBrain(brain).Ball.Player.canMove then goto lopatt;
            aDoor:= TBrain(brain).GetOpponentDoor(TBrain(brain).Ball.Player);
            if aDoor.X = 0 then aDoor.X:= 1 else // il fondo
            if aDoor.X = 11 then aDoor.X:= 10; // il fondo
              //   MoveValue := TBrain(brain).Ball.player.speed-1;
              //   if MoveValue <=0 then MoveValue := 1;

            // cerco una massima accelerazione. se non la trovo cerco un path verso la porta
            aplmCell:= GetDummyMaxAcceleration(AccSelfY );
              if aplmCell.X <> -1 then begin
                  TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y)) ;
                  Exit;
              end;
              aplmCell:= GetDummyMaxAcceleration(AccDoor );
              if aplmCell.X <> -1 then begin
                  TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
                  Exit;
              end;
                // se non c'è maxacceleration cerco un path verso la porta. se è tutto chiuso mi muovo in avanti di 1
                // provo a puntare la porta anche in diagonale di 1 o anche speed
                aplmCell:= GetDummyGoAheadCell;   // si muove solo di 2 in su??????
                if aplmCell.X <> -1 then begin
                  TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y));
                  exit;
                end
                else goto lopatt; // se proprio non c'è path provo lop
          end;

          1..15: begin  // non innesca volley
lopatt:
            dstCell:= GetDummyLopCellXYFriend;
            if dstCell.X <> -1 then begin
                TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_LOP) +',' + IntToStr(dstCell.X) + ',' + IntToStr(dstCell.Y)+ ',N' );
                Exit;
            end
            else begin
                //PRO or Something
                if AI_Think_CleanSomeRows ( team ) = None then begin   // se non riesco a pulire le row e col
                  if not AI_TrySomeBuff (team) then begin                        // provo un buff, se non ho buffato, nel senso non ho la skill nei 3 reparti
                    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +'PRO');
                    Exit;
                  end;
                end;
            end;

          end;
        end;
      end;

      // 2-4 mosse. check lop su friend per volley. valuto rischio

end;
procedure TSoccerAI.AI_Think_myBall_iAttack ( Team: integer );
var
  ShotOrPlm: Integer;
  aplmCell: TPoint;
  aSol: TBetterSolution;
  label todoor,shot,shot2,tobottomfield,cantcross;
begin
      // Dummy AI
      // se può tirare cerca il tiro o potente o preciso, se non può fa un lop in X (non Y)
  if not TBrain(brain).Ball.Player.CanSkill  then begin
    aSol := AI_Injured_sub_tactic_stay(team);
    if  (aSol = none) or (aSol = SubAbs4) or (aSol = SubCant) then begin // subCant non arriva mai. candosub è chechata prima
      if TBrain(brain).Minute < 120 then
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_PASS)  ) // o ha fatto qualcosa o passo
        else AI_ForceRandomMove (team);
    end;
      Exit;
  end;


  case TBrain(brain).Ball.Player.onBottom of
    NearCornerCell,BottomNoShot: begin  // la cella pari al corner sul fondo o quella isolata. non posso tirare
      // cerco un cross o volley. se non c'è e se mancano almeno 2 mosse metto un uomo in CrossingArea
      // o dribbling o pass o move. come sotto
      // è possibile avere un headingFriend ma non un volleyfriend oppure tutti e due
      if DummyTryCross ( team ) then Exit;
      if TBrain(brain).FTeamMovesLeft >=2 then begin
        if TBrain(brain).Ball.Player.Passing >= 6 then begin // se posso fare 10
          if DummyReachTheCrossinArea1Moves (TBrain(brain).Ball.Player, atShot) = true then Exit;   // ripassa di qui e farà DummyTryCross
        end
        else begin
          if DummyReachTheCrossinArea1Moves (TBrain(brain).Ball.Player, atHeading) = true then Exit;   // ripassa di qui e farà DummyTryCross
        end;
      end;
      if TBrain(brain).FTeamMovesLeft >=3 then begin
        if TBrain(brain).Ball.Player.Passing >= 6 then begin // se posso fare 10
          if DummyReachTheCrossinArea2Moves (TBrain(brain).Ball.Player, atShot) = true then Exit;   // ripassa di qui e farà DummyTryCross
        end
        else begin
          if DummyReachTheCrossinArea2Moves (TBrain(brain).Ball.Player, atHeading) = true then Exit;   // ripassa di qui e farà DummyTryCross
        end;

      end;

      DummyFindaWay( team ); // o dribbling o pass o move, dipende cos trovo puntanto la porta, altrimenti Protection
    end;
    BottomShot: begin     // posizione centrale di tiro ravvicinato
      // se teammovleft minimo 2 se posso avanzare maxdirection o anche solo di 1 lo faccio
      // altrimenti tiro
  shot:
        PosOrPrs ( Team, 50 );
    end;
    BottomNone: begin // non sono sul fondo ma comunque sono in Shotcell linee 2,3
      case TBrain(brain).Ball.Player.CellY of
        2..4: begin  // Posizione centrale linee 2,3 check uno davanti

          if TBrain(brain).FTeamMovesLeft >=2 then begin
            if TBrain(brain).Ball.Player.BonusLopBallControlTurn  > 0 then begin // ne approfitto
  toDoor:
              if not TBrain(brain).Ball.Player.canmove then goto shot;
              aplmCell:= GetDummyMaxAcceleration (AccDoor);
              if aplmCell.X <> -1 then
                  TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y))
              else begin  // se non c'è maxacceleration cerco un path verso la porta. se è tutto chiuso mi muovo in avanti di 1
                  // provo a puntare la porta anche in diagonale di 1 o anche speed
                  aplmCell:= GetDummyGoAheadCell;   // si muove solo di 2 in su??????
                  if aplmCell.X <> -1 then
                    TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y))
                    else begin
                      // forse ho un friend davanti
                      if not DummyAheadPass ( team ) then
                        goto shot;
                    end;
              end;
           end
            else begin //come sopra ma 50%
               ShotOrPlm := TBrain(brain).RndGenerate(100);
               case ShotOrPlm of
                1..50:PosOrPrs ( team, 50 );
                51..100: goto toDoor;
               end;
           end;
          end
          else goto shot; // solo 1 mossa rimasta. tiro.

        end
        else begin // sono sulle fascie linee 2,3 check uno davanti  non posso tirare   ma posso crossare (se possibile) o avanzare verso il fondo
  toBottomfield:
      { se rimane 1 mossa cerca il fondo invece di provare il cross . o crossa o cerca il fondo o tira}
       //   if TBrain(brain).Ball.Player.passing > TBrain(brain).Ball.Player.TBrain(brain).BallControl then begin   // meglio il cross che cercare il rigore
            if DummyTryCross ( team ) then Exit;
            if TBrain(brain).FTeamMovesLeft >=2 then begin
              if TBrain(brain).Ball.Player.Passing >= TBrain(brain).MAX_STAT then begin // se posso fare MAX_LEVEL
                if DummyReachTheCrossinArea1Moves (TBrain(brain).Ball.Player, atShot) = true then Exit;   // ripassa di qui e farà DummyTryCross
              end
              else begin
                if DummyReachTheCrossinArea1Moves (TBrain(brain).Ball.Player, atHeading) = true then Exit;   // ripassa di qui e farà DummyTryCross
              end;
            end;
            if TBrain(brain).FTeamMovesLeft >=3 then begin
              if TBrain(brain).Ball.Player.Passing >= TBrain(brain).MAX_STAT then begin // se posso fare 10
                if DummyReachTheCrossinArea2Moves (TBrain(brain).Ball.Player, atShot) = true then Exit;   // ripassa di qui e farà DummyTryCross
              end
              else begin
                if DummyReachTheCrossinArea2Moves (TBrain(brain).Ball.Player, atHeading) = true then Exit;   // ripassa di qui e farà DummyTryCross
              end;

            end;

            goto cantcross;
       //   end
        //  else begin
  cantcross:
              if not TBrain(brain).Ball.Player.canmove then goto shot;
          aplmCell:= GetDummyMaxAcceleration (AccSelfY);
              if aplmCell.X <> -1 then
                  TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(aplmCell.X) +','+ IntToStr(aplmCell.Y))
              else begin  // se non c'è maxacceleration cerco un path verso la porta. se è tutto chiuso mi muovo in avanti di 1
                      if not DummyAheadPass ( team ) then
                        goto shot;
              end;
        end;
      //  end;
      end;
    end;
  end;
            // inshotcell o no?
            // vedo se tiro facile
            // vedo se tiro buffato
            // vedo se tiro buffato con shp
            // vedo come andare al tiro
            // cerco le fascie
            // valuto cross
end;
function TSoccerAI.AI_TrySomeBuff ( team: integer ): Boolean;
var
  OpponentTeam: integer;
  aPlayer: TPlayer;
begin
  result := false;
  // Devo sapere Se sto perdendo, pareggiando o vincendo.
  // Devo sapere se c'è qualche buff già attivo. Nel caso evito perchè non stacka
  // Cerco un player che possa buffare il reparto, quindi che abbia qul specifico talento e provo il buff.
  if team = 0 then
    OpponentTeam := 1
    else OpponentTeam := 0;
  if TBrain(brain).Score.Gol[Team] = TBrain(brain).Score.Gol[ OpponentTeam ] then begin // se pareggio cerco un buff per cen-att-dif, se perdo att-cen-dif, se vinco def,cen,att
    if TBrain(brain).Score.buffM[team] = 0 then begin
       aPlayer := TPlayer( GetDummyTalentInRole ( Team, TALENT_ID_BUFF_MIDDLE ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFM' + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;
    if TBrain(brain).Score.buffF[team] = 0 then begin
      aPlayer := TPlayer(GetDummyTalentInRole ( Team, TALENT_ID_BUFF_FORWARD ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFF' + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;
    if TBrain(brain).Score.buffD[team] = 0 then begin
      aPlayer := TPlayer(GetDummyTalentInRole ( Team, TALENT_ID_BUFF_DEFENSE ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFD' + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;

  end
  else if TBrain(brain).Score.Gol[Team] < TBrain(brain).Score.Gol[OpponentTeam] then begin // se pareggio cerco un buff per cen-att-dif, se perdo att-cen-dif, se vinco def,cen,att
    if TBrain(brain).Score.buffF[team] = 0 then begin
      aPlayer := TPlayer(GetDummyTalentInRole ( Team, TALENT_ID_BUFF_FORWARD ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFF'  + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;
    if TBrain(brain).Score.buffM[team] = 0 then begin
      aPlayer := TPlayer(GetDummyTalentInRole ( Team, TALENT_ID_BUFF_MIDDLE ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFM' + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;
    if TBrain(brain).Score.buffD[team] = 0 then begin
      aPlayer := TPlayer( GetDummyTalentInRole ( Team, TALENT_ID_BUFF_DEFENSE ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFD'  + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;
  end
  else if TBrain(brain).Score.Gol[Team] > TBrain(brain).Score.Gol[OpponentTeam] then begin // se pareggio cerco un buff per cen-att-dif, se perdo att-cen-dif, se vinco def,cen,att
    if TBrain(brain).Score.buffD[team] = 0 then begin
      aPlayer := TPlayer(GetDummyTalentInRole ( Team, TALENT_ID_BUFF_DEFENSE ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFD' + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;
    if TBrain(brain).Score.buffM[team] = 0 then begin
      aPlayer := TPlayer(GetDummyTalentInRole ( Team, TALENT_ID_BUFF_MIDDLE ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFM' + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;
    if TBrain(brain).Score.buffF[team] = 0 then begin
      aPlayer := TPlayer(GetDummyTalentInRole ( Team, TALENT_ID_BUFF_FORWARD ));
       if aPlayer <> nil then begin
         TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'BUFFF' + ',' + aPlayer.ids );
         Result := True;
         exit;
       end;
    end;
  end;

end;
function TSoccerAI.GetDummyTalentInRole ( team, TalentId: integer ): TObject;
var
  P: Integer;
  aPlayer: TPlayer;
begin
  Result := nil;
  for P := TBrain(brain).Players.Count -1 downto 0 do begin
    aPlayer := TPlayer( TBrain(brain).Players[p]);
    if IsOutSide( aPlayer.CellX, aPlayer.CellY) then continue;
    if ( aPlayer.Team = team ) and ( aPlayer.TalentId2 = talentid  ) then begin
      if TalentId = 139 then begin
        if aPlayer.Role = 'D' then begin
          Result := aPlayer;
          Exit;
        end;
      end
      else if TalentId = 140 then begin
        if aPlayer.Role = 'M' then begin
          Result := aPlayer;
          Exit;
        end;
      end
      else if TalentId = 141 then begin
        if aPlayer.Role = 'F' then begin
          Result := TObject(aPlayer);
          Exit;
        end;
      end;
    end;
  end;



end;

function TSoccerAI.GetDummyAheadPass( Team: integer ): TObject;
var
  x: integer;
  aPlayer: TPlayer;
begin
  { TODO : controllo offside }
  Result := nil;
   if Team = 1 then begin
     for x := 1 to TBrain(brain).Ball.Player.CellX -1 do begin
       aPlayer := TPlayer( TBrain(Brain).GeTPlayer (X, TBrain(brain).Ball.Player.CellY, TBrain(brain).Ball.Player.team ));
       if aPlayer = nil then Continue;

       if AbsDistance(aPlayer.cellX, aPlayer.CellX, TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.cellY)  <= ShortPassRange then begin
          Result := aPlayer;
          Exit;
       end;
      end;
   end
   else if Team = 0 then begin
     for x := 10 downto TBrain(brain).Ball.Player.CellX +1 do begin
       aPlayer := TBrain(Brain).GeTPlayer (X, TBrain(brain).Ball.Player.CellY, TBrain(brain).Ball.Player.team );
       if aPlayer = nil then Continue;

       if AbsDistance(aPlayer.cellX, aPlayer.CellX, TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.cellY)  <= ShortPassRange then begin
          Result := aPlayer;
          Exit;
       end;
     end;

   end;


end;
function TSoccerAI.DummyAheadPass( Team: integer ): Boolean;
var
  x: integer;
  aPlayer: TPlayer;
begin
  Result := False;
   if TBrain(brain).Ball.Player.Team = 1 then begin
     for x := 1 to TBrain(brain).Ball.Player.CellX -1 do begin
       aPlayer := TBrain(Brain).GeTPlayer (X, TBrain(brain).Ball.Player.CellY, TBrain(brain).Ball.Player.team );
       if aPlayer = nil then Continue;
       if TBrain(Brain).IsOffSide(TBrain(brain).Ball.Player,aPlayer) then continue;


       if AbsDistance(aPlayer.cellX, aPlayer.CellX, TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.cellY)  <= ShortPassRange then begin

          TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +'SHP' +',' + IntToStr(aPlayer.cellX) + ',' + IntToStr(aPlayer.cellY) );
          Result := true;
          Exit;
       end;
     end;
   end
   else if TBrain(brain).Ball.Player.Team = 0 then begin
     for x := 10 downto TBrain(brain).Ball.Player.CellX +1 do begin
       aPlayer :=   TBrain(Brain).GeTPlayer (X, TBrain(brain).Ball.Player.CellY, TBrain(brain).Ball.Player.team );
       if aPlayer = nil then Continue;
       if TBrain(Brain).IsOffSide(TBrain(brain).Ball.Player,aPlayer) then Exit;

       if AbsDistance(aPlayer.cellX, aPlayer.CellX, TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.cellY)  <= ShortPassRange then begin
          TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +'SHP' +',' + IntToStr(aPlayer.cellX) + ',' + IntToStr(aPlayer.cellY) );
          Result := true;
          Exit;
       end;
     end;

   end;


end;

procedure TSoccerAI.PosOrPrs ( Team, PosChance: integer );
var
  r: Integer;
begin
  r := TBrain(brain).RndGenerate(100);
  if r <= PosChance then TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [ team]) + ',' + 'POS' )
  else TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [ team]) + ',' + 'PRS' );

end;
procedure TSoccerAI.DummyFindaWay;
var
  anOpponent: TPlayer;
  aDoor: TPoint;
begin
    //Getpath FALSE ! poi cella per cella vede cosa è
  aDoor:= TBrain(brain).GetOpponentDoor(TBrain(brain).Ball.Player);
          if aDoor.X = 0 then aDoor.X := 1 else // il dischetto dl rigore
            if aDoor.X = 11 then aDoor.X := 10; // il dischetto dl rigore
   TBrain(brain).GetPath ( TBrain(brain).Ball.Player.Team, TBrain(brain).Ball.Player.CellX, TBrain(brain).Ball.Player.CellY, aDoor.X, aDoor.Y,12,False,False,False,false,EveryDirection, TBrain(brain).Ball.Player.MovePath  );
          anOpponent := TBrain(brain).GeTPlayer(TBrain(brain).Ball.Player.MovePath[0].X , TBrain(brain).Ball.Player.MovePath[0].Y );
          if anOpponent = nil then begin
            if TBrain(brain).Ball.Player.canMove then begin
              TBrain(brain).BrainInput  (IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_PLM)+',' + TBrain(brain).Ball.Player.Ids +',' + IntToStr(TBrain(brain).Ball.Player.MovePath[0].X) +','+ IntToStr(TBrain(brain).Ball.Player.MovePath[0].Y));
              Exit;
            end
            else begin
              // prima provo a spostare qualcosa
              if AI_Think_CleanSomeRows ( team ) = None then
                TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'PRO');
            end;
          end
          else begin
            if (anOpponent.Team <> TBrain(brain).Ball.Player.Team)   then begin
              if TBrain(brain).Ball.Player.CanDribbling then
                  TBrain(brain).BrainInput  (IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'DRI,' + IntToStr(TBrain(brain).Ball.Player.MovePath[0].X) +','+ IntToStr(TBrain(brain).Ball.Player.MovePath[0].Y))
                  else begin
                    if AI_Think_CleanSomeRows ( team ) = None then
                    TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'PRO');
                  end;
              Exit;
            end
            else if anOpponent.Team = TBrain(brain).Ball.Player.Team  then begin // un compagno mi ostruisce
                  TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'SHP,' + IntToStr(TBrain(brain).Ball.Player.MovePath[0].X) +','+ IntToStr(TBrain(brain).Ball.Player.MovePath[0].Y));
              Exit;
            end;

          end
end;
function TSoccerAI.DummyTryCross( Team: integer ): Boolean;
var
  aVolleyFriend,aHeadingfriend: TPlayer;

begin
  result := false;
  aHeadingFriend:= TPlayer( GetDummyCrossFriend (TBrain(brain).Ball.Player));
  aVolleyFriend:= TPlayer( GetDummyVolleyFriend (TBrain(brain).Ball.Player));

  if ( aHeadingfriend <> nil ) and ( aVolleyFriend = nil ) then begin
    if TBrain(brain).IsOffside(TBrain(brain).Ball.Player,aHeadingFriend) then Exit;

    TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +'CRO,'  + IntToStr(aHeadingFriend.cellX) + ',' + IntToStr(aHeadingFriend.cellY) );
    result := True;
  end

  // non può esistere che ho un volley ma non un heading
  // qui hho tutti e 2 disponibili
  else if ( aHeadingfriend <> nil ) and ( aVolleyFriend <> nil ) then begin
    if TBrain(brain).IsOffside(TBrain(brain).Ball.Player,aVolleyFriend) then Exit;
    if TBrain(brain).IsOffside(TBrain(brain).Ball.Player,aHeadingFriend) then Exit;

    if TBrain(brain).Ball.Player.Passing >=  TBrain(brain).MAX_STAT then  // se posso fare 10f o 16m
        TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +'LOP,'  + IntToStr(aVolleyFriend.cellX) + ',' + IntToStr(aVolleyFriend.cellY) + ',N' )
    else
        TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +'CRO,'  + IntToStr(aHeadingFriend.cellX) + ',' + IntToStr(aHeadingFriend.cellY) );
    result := True;
  end
end;
function TSoccerAI.DummyReachTheCrossinArea1Moves ( aPlayer: TObject; bestAttribute:TAttributeName) : boolean;
var
  i,p: Integer;
  aCrossCell: TTvCrossAreaCell;
  tmpCrossCells : Tlist<TTVCrossAreaCell>;
  Listfriends: TList<TCellAndPlayer>;
  aFriend: TPlayer;
  aCellandPlayer: TCellAndPlayer;
begin
  (* Tra tutti quelli che possono un random raggiunge l'aera avversaria*)
  // ciclo per tutte le celle della corossing e ottengo quelle libere
  result := false;
  tmpCrossCells := Tlist<TTVCrossAreaCell>.Create;
  Listfriends:= TList<TCellAndPlayer>.Create;

    TBrain(brain).Ball.Player.tmp := CrossingRangeMax;
    if (TBrain(brain).Ball.Player.TalentId1 = TALENT_ID_LONGPASS)or (TBrain(brain).Ball.Player.TalentId2 = TALENT_ID_LONGPASS)  then
      TBrain(brain).Ball.Player.tmp := TBrain(brain).Ball.Player.tmp + 1 ;

  for I := 0 to TVCrossingAreaCells.Count -1 do begin
    aCrossCell :=  TvCrossingAreaCells[i];

    if aCrossCell.DoorTeam <> TPlayer(aPlayer).Team then begin // <> opponent
      if (TBrain(brain).GeTPlayer ( aCrossCell.cellX, aCrossCell.CellY) = nil) and // la distanza minima e massima crossing
      ( AbsDistance( TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY, aCrossCell.CellX , aCrossCell.cellY ) >= CrossingRangeMin )
      and  ( AbsDistance( TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY, aCrossCell.CellX , aCrossCell.cellY ) <= (TBrain(brain).Ball.Player.tmp ) )
      then begin
        // la aggiungo alla lista di celle cross libere in versione AIfield
        tmpCrossCells.Add ( aCrossCell );
      end;
    end;
  end;
  // ho la lista delle crosscell libere. devo trovare i possibili friend che le raggiungano
  for i := 0 to tmpCrossCells.Count -1 do begin
    aCrossCell:= tmpCrossCells[i];
    for p := TBrain(brain).Players.Count -1 downto 0 do begin
      aFriend := TBrain(brain).Players[p];
      if (aFriend.TalentId1 = TALENT_ID_GOALKEEPER ) or (aFriend.Team <> TPlayer(aPlayer).Team) or ( not aFriend.CanMove ) or ( TPlayer(aPlayer).Ids = aFriend.Ids ) then Continue;
      // un mio friend

      TBrain(brain).GetPath (aFriend.Team, aFriend.CellX ,aFriend.Celly,
      aCrossCell.CellX, aCrossCell.CellY, aFriend.Speed{Limit},
      aFriend.Flank <> 0{useFlank}, false, false,true ,TruncOneDir{OneDir}, aFriend.MovePath );

      if (afriend.MovePath.Count > 0) then begin // il path potrebbe essere parziale. meglio se l'ultimp step E' una cella cross
        if (afriend.MovePath[afriend.MovePath.Count-1].X = aCrossCell.cellX) and (afriend.MovePath[afriend.MovePath.Count-1].Y = aCrossCell.cellY) then begin
          // raggiunge la cross area
          aCellandPlayer.CellX :=  aCrossCell.CellX;
          aCellandPlayer.CellY :=  aCrossCell.CellY;
          aCellandPlayer.Player := aFriend.ids;
          if bestAttribute = atShot then
            aCellandPlayer.chance := aFriend.Shot
          else if bestAttribute = atheading then
            aCellandPlayer.chance := aFriend.heading ;
          ListFriends.Add(aCellandPlayer);
        end;
      end;

    end;
  end;

  // il result è il player con il suo MovePath pronto per l'input
  // ritorno il puntatore alla lista orginale, questa viene distrutta

  if Listfriends.count > 0 then begin
      Listfriends.sort(TComparer<TCellAndPlayer>.Construct(
      function (const L, R: TCellAndPlayer): integer
      begin
        Result := R.chance - L.chance;
      end
     ));

    TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [ TPlayer(aPlayer).team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + Listfriends[0].Player  + ',' +
                            IntToStr(Listfriends[0].cellX) +','+ IntToStr(Listfriends[0].cellY));  // è la cella finale del path
    Result :=  True;
  end;


  Listfriends.Free;
  tmpCrossCells.Free;
end;
function TSoccerAI.DummyReachTheCrossinArea2Moves ( aPlayer: TObject; bestAttribute:TAttributeName) : boolean;
var
  i,p: Integer;
  aCrossCell: TTvCrossAreaCell;
  tmpCrossCells : Tlist<TTVCrossAreaCell>;
  Listfriends: TList<TCellAndPlayer>;
  aFriend: TPlayer;
  aCellandPlayer: TCellAndPlayer;
  AVirtualPlayer: TVirtualPlayer;
  lstVirtualSoccer: TList<TVirtualPlayer>;
  aPlayerR: TPlayer;
begin
  (* Tra tutti quelli che possono un random raggiunge l'aera avversaria in 2 mosse quindi 2 TBrain(brain).GetPath virtuali/teoriche. solo il primo PLM path è effettuato*)
  // ciclo per tutte le celle della corossing e ottengo quelle libere
  result := false;
  tmpCrossCells := Tlist<TTVCrossAreaCell>.Create;
  Listfriends:= TList<TCellAndPlayer>.Create;

    TBrain(brain).Ball.Player.tmp := CrossingRangeMax;
    if (TBrain(brain).Ball.Player.TalentId1 = TALENT_ID_LONGPASS)or (TBrain(brain).Ball.Player.TalentId2 = TALENT_ID_LONGPASS)  then
      TBrain(brain).Ball.Player.tmp := TBrain(brain).Ball.Player.tmp + 1 ;


  for I := 0 to TVCrossingAreaCells.Count -1 do begin
    aCrossCell :=  TvCrossingAreaCells[i];

    if aCrossCell.DoorTeam <> TPlayer(aPlayer).Team then begin // <> opponent
      if (TBrain(brain).GeTPlayer ( aCrossCell.cellX, aCrossCell.CellY) = nil) and // la distanza minima e massima crossing
      ( AbsDistance( TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY, aCrossCell.CellX , aCrossCell.cellY ) >= CrossingRangeMin )
      and  ( AbsDistance( TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY, aCrossCell.CellX , aCrossCell.cellY ) <= (TBrain(brain).Ball.Player.tmp) )
      then begin
        // la aggiungo alla lista di celle cross libere in versione AIfield
        tmpCrossCells.Add ( aCrossCell );
      end;
    end;
  end;
  // ho la lista delle crosscell libere. devo trovare i possibili friend che le raggiungano in 2 mosse ( 2 TBrain(brain).GetPath consecutivi !!! )

  // fill virtualSoccer
  lstVirtualSoccer:= TList<TVirtualPlayer>.Create;
  for p := 0 to TBrain(brain).Players.Count -1 do begin  // parte da 0 per synch
    aPlayerR:= TBrain(brain).Players[p];
    AVirtualPlayer.ids := aPlayerR.Ids;
    AVirtualPlayer.VirtualCellX := aPlayerR.CellX;
    AVirtualPlayer.VirtualCellY := aPlayerR.CellY;
    AVirtualPlayer.Team := aPlayerR.Team;
    AVirtualPlayer.canMove := aPlayerR.CanMove;
    AVirtualPlayer.Role := aPlayerR.Role;
    lstVirtualSoccer.add ( AVirtualPlayer);
  end;
  for i := 0 to tmpCrossCells.Count -1 do begin
    aCrossCell:= tmpCrossCells[i];
    for p := TBrain(brain).Players.Count -1 downto 0 do begin
      aFriend := TBrain(brain).Players[p];
      if (aFriend.Role = 'G') or (aFriend.Team <> TPlayer(aPlayer).Team) or ( not aFriend.CanMove ) or ( TPlayer(aPlayer).Ids = aFriend.Ids ) then Continue;
      // un mio friend

      TBrain(brain).GetPath (aFriend.Team, aFriend.CellX ,aFriend.Celly,
      aCrossCell.CellX, aCrossCell.CellY, aFriend.Speed{Limit},
      aFriend.Flank <> 0{useFlank}, false, false,true ,TruncOneDir{OneDir}, aFriend.MovePath );


      // in teoria non dovrebbe trovare nessuno qui da dove è chiamata.
      if (afriend.MovePath.Count > 0) then begin // il path potrebbe essere parziale. meglio se l'ultimp step E' una cella cross
          // aggiorno virtualX e VirtualY
      // non uso find, sono liste sincronizzate
        AVirtualPlayer := lstVirtualSoccer[p];
        AVirtualPlayer.VirtualCellX:= afriend.MovePath[afriend.MovePath.Count-1].X; // <-- la lista è per forza sincronizzata. il ciclo parte da 0
        AVirtualPlayer.VirtualCellY:= afriend.MovePath[afriend.MovePath.Count-1].Y; // <-- la lista è per forza sincronizzata. il ciclo parte da 0
        if (afriend.MovePath[afriend.MovePath.Count-1].X = aCrossCell.cellX) and (afriend.MovePath[afriend.MovePath.Count-1].Y = aCrossCell.cellY) then begin
          // raggiunge la cross area
          aCellandPlayer.CellX :=  aCrossCell.CellX;
          aCellandPlayer.CellY :=  aCrossCell.CellY;
          aCellandPlayer.Player := aFriend.ids;
          if bestAttribute = atShot then
            aCellandPlayer.chance := aFriend.Shot
          else if bestAttribute = atheading then
            aCellandPlayer.chance := aFriend.heading ;
          ListFriends.Add(aCellandPlayer);
        end;
      end;


    end;
  end;

  for i := 0 to tmpCrossCells.Count -1 do begin
    aCrossCell:= tmpCrossCells[i];
    for p := lstVirtualSoccer.Count -1 downto 0 do begin

        // il nuovo TBrain(brain).GetPath riparte dalla cella virtuale raggiunta sopra al primo tentativo
        aFriend := TBrain(brain).Players[p];  //<-- synch
        AVirtualPlayer := lstVirtualSoccer [p];   //<-- synch

        if (aFriend.Role = 'G') or (aFriend.Team <> TPlayer(aPlayer).Team) or ( not aFriend.CanMove ) or ( TPlayer(aPlayer).Ids = aFriend.Ids ) then Continue;

        // il TBrain(brain).GetPath dovrebbe lavorare su virtualSoccer
        TBrain(brain).GetPath (AVirtualPlayer.Team, AVirtualPlayer.VirtualCellX , AVirtualPlayer.VirtualCellY,
        aCrossCell.CellX, aCrossCell.CellY, aFriend.Speed{Limit},
        aFriend.Flank <> 0{useFlank}, false, false,true ,TruncOneDir{OneDir}, aFriend.MovePath );

        if (afriend.MovePath.Count > 0) then begin // il path potrebbe essere parziale. meglio se l'ultimp step E' una cella cross
          if (afriend.MovePath[afriend.MovePath.Count-1].X = aCrossCell.cellX) and (afriend.MovePath[afriend.MovePath.Count-1].Y = aCrossCell.cellY) then begin
            // raggiunge la cross area
            aCellandPlayer.CellX :=  aCrossCell.CellX;
            aCellandPlayer.CellY :=  aCrossCell.CellY;
            aCellandPlayer.Player := aFriend.ids;
            if bestAttribute = atShot then
              aCellandPlayer.chance := aFriend.Shot
            else if bestAttribute = atheading then
              aCellandPlayer.chance := aFriend.heading ;
            ListFriends.Add(aCellandPlayer);
          end;
        end;
    end;
  end;
  // il result è il player con il suo MovePath pronto per l'input
  // ritorno il puntatore alla lista orginale, questa viene distrutta

  if Listfriends.count > 0 then begin
      Listfriends.sort(TComparer<TCellAndPlayer>.Construct(
      function (const L, R: TCellAndPlayer): integer
      begin
        Result := R.chance - L.chance;
      end
     ));

    TBrain(brain).BrainInput  ( IntTostr(TBrain(brain).Score.TeamGuid [ TPlayer(aPlayer).team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + Listfriends[0].Player  + ',' +
                            IntToStr(Listfriends[0].cellX) +','+ IntToStr(Listfriends[0].cellY));  // è la cella finale del path
    Result :=  true;
  end;

  lstVirtualSoccer.Free;
  Listfriends.Free;
  tmpCrossCells.Free;
end;
procedure TSoccerAI.AI_Think_oppBall_iDefend ( Team: integer  );
begin
      AiDummyTakeTheBall ( Team );

            //cerco un path per fare un tackle o un pressing + tackle
            //cerco un aiuto pressing
end;
procedure TSoccerAI.AiDummyTakeTheBall ( Team: integer  );
var
  aPlayer: TPlayer;
  TacOrPre: Integer;
begin
      // Dummy AI
      // provo sempre il tackle se mi trovo a distanza 1 altrimenti passo
      if TBrain(brain).Ball.Player.TalentId1 <> TALENT_ID_GOALKEEPER then begin // se non è un portiere

        aPlayer := TPlayer(GetdummyPressing(Team)); // vede se c'è a distanza 1 un player con talento experience
        if aPlayer <> nil then begin
            TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +'PRE,' + aPlayer.ids  )
        end
        else begin
          aPlayer := TPlayer(GetdummyTackle (Team)); // vale anche per pressing perchè è per forza a distanza 1
          if aPlayer <> nil then begin
            if TBrain(brain).Ball.Player.UnderPressureTurn > 0  then begin   // se è già sotto pressing non lo ripeto, faccio il tackle
                TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +'TAC,' + aPlayer.ids  );   // subito il tackle
            end
            else begin
            TacOrPre:= TBrain(brain).RndGenerate(100);
            case TacOrPre of
              1..50: TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'PRE,' + aPlayer.ids  );    // faccio sempre prima pressing oppure no al 50%
              51..100: TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + 'TAC,' + aPlayer.ids  );   // rischio subito il tackle
              end;
            end;
          end
          else DummyReachTheBall ( Team );
        end
      end
      else begin  // se il gk avversario ha la palla
        if AI_Injured_sub_tactic_stay(team) = none then begin
          if TBrain(brain).Minute < 120 then
            TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_PASS)  ) // o ha fatto qualcosa o passo
          else AI_ForceRandomMove(team);
        end;
      end;
end;
procedure TSoccerAI.AI_Think_oppBall_middle ( Team: integer  );
begin
      AiDummyTakeTheBall ( Team );
end;
procedure TSoccerAI.AI_Think_oppBall_iAttack ( Team: integer  );
begin
      AiDummyTakeTheBall ( Team );
            //cerco un path per fare un tackle o un pressing + tackle
            //cerco un aiuto pressing
            // mi copro, abilito il rientro agevole
end;
procedure TSoccerAI.AI_Think_neutralBall_iDefend ( Team: integer );
begin
      // Dummy AI
      // provo sempre a raggiungere la palla
      DummyReachTheBall (Team);
   // cerco solo come raggiungere la palla
end;
procedure TSoccerAI.AI_Think_neutralBall_middle ( Team: integer  );
begin
      // Dummy AI
      // provo sempre a raggiungere la palla
      DummyReachTheBall (Team);
end;
procedure TSoccerAI.AI_Think_neutralBall_iAttack ( Team: integer );
begin
      // Dummy AI
      // provo sempre a raggiungere la palla
      DummyReachTheBall (Team);
end;




function TSoccerAI.GetDummyLopCellXY : Tpoint;
var
  AICell,TvCell,dstCell: TPoint;
  aList: TList<TPoint>;
  x,y,MaxDistance: integer;
  DummyFriend: TPlayer;
begin
    Result.X := -1;   // errore, nessuna cella libera
    Result.Y := -1;
    // butto la palla in avanti a caso il più lontano
    AICell := TBrain(brain).Tv2AiField (TBrain(brain).Ball.player.Team, TBrain(brain).Ball.player.CellX,TBrain(brain).Ball.player.CellY ) ;
    MaxDistance := LoftedPassRangeMax ;
    if (TBrain(brain).Ball.Player.TalentId1 = TALENT_ID_LONGPASS)or (TBrain(brain).Ball.Player.TalentId2 = TALENT_ID_LONGPASS)  then
      MaxDistance :=  MaxDistance + 1;
    aList:= Tlist<TPoint>.Create;


    // ragioni in AIfield
    for Y := MaxDistance downto MaxDistance-1 do begin // fino a lop max -1 (abbastanza lontano in avanti)
      for X := 0 to 6 do begin // tutta la linea possibile X
        DstCell.Y := AICell.Y  - Y;
        DstCell.X := X;

        (*absdistance è diversa dal rangeMAx, va checkata ora*)
        TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, dstCell.X,dstCell.Y );
        if AbsDistance( TBrain(brain).Ball.player.CellX,TBrain(brain).Ball.player.CellY,TvCell.X,TvCell.Y) > (MaxDistance) then Continue;
        if IsOutSide(TvCell.X, TvCell.Y ) then Continue;

        TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, dstCell.X,dstCell.Y );
        DummyFriend := TBrain(brain).GeTPlayer (TvCell.X,TvCell.Y) ;
        if DummyFriend = nil then begin
          aList.Add(dstCell);
          continue;
        end;
        if (DummyFriend.Team = TBrain(brain).Ball.player.Team) and ( DummyFriend.Ids <>  TBrain(brain).Ball.Player.ids  ) and (not TBrain(brain).IsOffside(TBrain(brain).Ball.Player,DummyFriend)) then begin // se è un compagno
          aList.Add(dstCell);
          continue;
        end;
      end;
    end;

    if aList.Count > 0 then begin
      Result := aList[TBrain(brain).RndGenerate0(aList.Count-1)];
      TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, Result.X, Result.Y );
      Result := TvCell;
    end;
    aList.Free;

end;
function TSoccerAI.GetDummyLopCellXYInfinite : Tpoint;
var
  AICell,TvCell,dstCell: TPoint;
  aList: TList<TPoint>;
  x,y: integer;
  DummyFriend: TPlayer;
begin
//    Result.X := -1;   // una cella libera esiste per forza
    // butto la palla in avanti a caso il più lontano
    AICell := TBrain(brain).Tv2AiField (TBrain(brain).Ball.player.Team, TBrain(brain).Ball.player.CellX,TBrain(brain).Ball.player.CellY ) ;
   // MaxDistance := 10;
    aList:= Tlist<TPoint>.Create;


    // ragioni in AIfield
    for Y := 1 to 5 do begin // fino a lop 1 una cella libra la trovo per forza
      for X := 0 to 6 do begin // tutta la linea possibile X
        DstCell.Y := AICell.Y  - Y;
        DstCell.X := X;

        (*absdistance è diversa dal rangeMAx, va checkata ora*)
        TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, dstCell.X,dstCell.Y );
        if AbsDistance( TBrain(brain).Ball.player.CellX,TBrain(brain).Ball.player.CellY,TvCell.X,TvCell.Y) < (LoftedPassRangeMin) then Continue;
        if IsOutSide(TvCell.X, TvCell.Y ) then Continue;


        if not IsOutSide( TvCell.X, TvCell.Y )  then begin // se è dentro il campo e se è friendly/vuota
          TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, dstCell.X,dstCell.Y );
          DummyFriend := TBrain(brain).GeTPlayer (TvCell.X,TvCell.Y);
          if DummyFriend = nil then begin
            aList.Add(dstCell);
          end
          else if (DummyFriend.Ids <>  TBrain(brain).Ball.Player.ids) and not (TBrain(brain).IsOffside(TBrain(brain).Ball.Player,DummyFriend))   then begin // se è un compagno
            aList.Add(dstCell);
//            continue;
          end;
        end;
      end;
    end;

    if aList.Count > 0 then begin
      Result := aList[TBrain(brain).RndGenerate0(aList.Count-1)];
      TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, Result.X, Result.Y );
      Result := TvCell;
    end;
    aList.Free;

end;
function TSoccerAI.GetDummyLopCellXYfriend : Tpoint;
var
  AICell,TvCell,dstCell: TPoint;
  aList: TList<TPoint>;
  x,y,MaxDistance: integer;
  DummyFriend: TPlayer;
begin
    Result.X := -1;   // errore, nessuna cella con compagno
    Result.Y := -1;

    AICell := TBrain(brain).Tv2AiField (TBrain(brain).Ball.player.Team, TBrain(brain).Ball.player.CellX,TBrain(brain).Ball.player.CellY ) ;
    MaxDistance := LoftedPassRangeMax ;
    if (TBrain(brain).Ball.Player.TalentId1 = TALENT_ID_LONGPASS) or (TBrain(brain).Ball.Player.TalentId2 = TALENT_ID_LONGPASS)  then
      MaxDistance :=  MaxDistance + 1;
    aList:= Tlist<TPoint>.Create;


    // ragiono in AIfield
    for Y := MaxDistance downto MaxDistance-1 do begin // fino a lop max -1 (abbastanza lontano in avanti)
      for X := 0 to 6 do begin // tutta la linea possibile X
        DstCell.Y := AICell.Y  - Y;
        DstCell.X := X;

        (*absdistance è diversa dal rangeMAx, va checkata ora*)
        TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, dstCell.X,dstCell.Y );
        if AbsDistance( TBrain(brain).Ball.player.CellX,TBrain(brain).Ball.player.CellY,TvCell.X,TvCell.Y) > (MaxDistance) then Continue;
        if IsOutSide(TvCell.X, TvCell.Y ) then Continue;

          TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, dstCell.X,dstCell.Y );
          DummyFriend := TBrain(brain).GeTPlayer (TvCell.X,TvCell.Y,TBrain(brain).Ball.Player.team);
          if DummyFriend = nil then continue;
          if TBrain(brain).IsOffside(TBrain(brain).Ball.Player,DummyFriend) then continue;

          if DummyFriend.Ids <>  TBrain(brain).Ball.Player.ids  then begin // se è un compagno
            aList.Add(dstCell);
            continue;
          end;
      end;
    end;

    if aList.Count > 0 then begin
      Result := aList[TBrain(brain).RndGenerate0(aList.Count-1)];
      TvCell := TBrain(brain).AiField2TV (TBrain(brain).Ball.player.Team, Result.X, Result.Y );
      Result := TvCell;
    end;
    aList.Free;

end;

function TSoccerAI.GetDummyCrossFriend ( aPlayer: TObject ): TObject;
var
  p,MaxDistance: integer;
  aFriend: TPlayer;
  aList: TObjectList<TPlayer>;

begin
  Result := nil;

    MaxDistance := CrossingRangeMax ;
    if (TPlayer( aPlayer).TalentId1 = TALENT_ID_LONGPASS ) or (TPlayer( aPlayer).TalentId2 = TALENT_ID_LONGPASS ) then
      MaxDistance :=  MaxDistance + 1;

  aList:= TObjectList<TPlayer>.Create(false);

  for P := TBrain(brain).Players.Count -1 downto 0 do begin
    aFriend := TBrain(brain).Players[p];
    if IsOutSide( aFriend.CellX ,aFriend.CellY )  then Continue;
    if (absDistance( TPlayer( aPlayer).CellX ,TPlayer( aPlayer).CellY,  aFriend.CellX, aFriend.CellY ) > ( MaxDistance ))
    or (absDistance( TPlayer( aPlayer).CellX ,TPlayer( aPlayer).CellY,  aFriend.CellX, aFriend.CellY ) < CrossingRangeMin)  then begin
      continue;
    end;

    if  ( aFriend.Team = TPlayer( aPlayer).Team ) and (aFriend.InCrossingArea) then
      aList.add (aFriend);

  end;

  // quello con heading più alta
  if aList.Count > 0 then begin
      aList.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := R.heading - L.heading;
      end
     ));

    Result :=  TBrain(brain).GeTPlayer ( aList[0].ids );  // lo prendo dalla lista principale, questa viene distrutta
  end;
  aList.Free;


end;
function TSoccerAI.GetDummyVolleyFriend ( aPlayer: TObject ): TObject;
var
  p,MaxDistance: integer;
  aFriend: TPlayer;
  aList: TObjectList<TPlayer>;

begin
   Result := nil;
   MaxDistance := CrossingRangeMax ;
   if (TPlayer( aPlayer).TalentId1 = TALENT_ID_LONGPASS ) or (TPlayer( aPlayer).TalentId2 = TALENT_ID_LONGPASS ) then
     MaxDistance :=  MaxDistance + 1;

  aList:= TObjectList<TPlayer>.Create(false);

  for P := TBrain(brain).Players.Count -1 downto 0 do begin
    aFriend := TBrain(brain).Players[p];
    if IsOutSide( aFriend.CellX ,aFriend.CellY )  then Continue;
    if (absDistance( TPlayer( aPlayer).CellX ,TPlayer( aPlayer).CellY,  aFriend.CellX, aFriend.CellY ) > ( MaxDistance ))
    or (absDistance( TPlayer( aPlayer).CellX ,TPlayer( aPlayer).CellY,  aFriend.CellX, aFriend.CellY ) < CrossingRangeMin)  then begin
      continue;
    end;

    if absDistance( TPlayer( aPlayer).CellX ,TPlayer( aPlayer).CellY,  aFriend.CellX, aFriend.CellY ) < VolleyRangeMin then
      Continue;

    if  ( (TPlayer( aPlayer).Team = 0) and (TPlayer( aPlayer).CellX < aFriend.CellX) )  or  ( (TPlayer( aPlayer).Team = 1) and (TPlayer( aPlayer).CellX > aFriend.CellX) ) then
    Continue;
    if  ( aFriend.Team = TPlayer( aPlayer).Team ) and (aFriend.InCrossingArea) then
      aList.add (aFriend);

  end;

  // quello con shot più alta
  if aList.Count > 0 then begin
      aList.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := R.shot - L.shot;
      end
     ));

    Result :=  TBrain(brain).GeTPlayer ( aList[0].ids );  // lo prendo dalla lista principale, questa viene distrutta
  end;
  aList.Free;


end;
function TSoccerAI.GetDummyShpCellXY : Tpoint;
var
  AICell,TvCell,dstCell: TPoint;
  aList: TList<TPoint>;
  x,y,MaxDistance: integer;
  DummyFriend: TPlayer;
begin
    Result.X := -1;   // errore, nessuna cella libera
    Result.Y := -1;
    // cerco un compagno o una cella vuota alla quale può accedere a minimo distanza 2 un compagno  ( il compagno deve avere speed  >= 2)
    // il compagno deve avere un path libero
    // la cella è davanti o in linea, preferendo davanti
    AICell := TBrain(brain).Tv2AiField (TBrain(brain).Ball.player.Team, TBrain(brain).Ball.player.CellX,TBrain(brain).Ball.player.CellY ) ;
    MaxDistance := ShortPassRange ;
    if (TBrain(brain).Ball.Player.TalentId1 = TALENT_ID_LONGPASS) or (TBrain(brain).Ball.Player.TalentId2 = TALENT_ID_LONGPASS) then
    MaxDistance :=  MaxDistance + 1;


    aList:= Tlist<TPoint>.Create;


    // ragioni in AIfield
    for Y := MaxDistance downto 1 do begin // fino a lop max -1 (abbastanza lontano in avanti)
      for X := 0 to 6 do begin // tutta la linea possibile X
        DstCell.Y := AICell.Y  - Y;
        DstCell.X := X;

        (*absdistance è diversa dal rangeMAx, va checkata ora*)
        TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, dstCell.X,dstCell.Y );
        if AbsDistance( TBrain(brain).Ball.player.CellX,TBrain(brain).Ball.player.CellY,TvCell.X,TvCell.Y) > (MaxDistance) then Continue;
        if IsOutSide(TvCell.X, TvCell.Y ) then Continue;

        TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, dstCell.X,dstCell.Y );
        // passaggio a seguire
        DummyFriend := TBrain(brain).GeTPlayer (TvCell.X,TvCell.Y , TBrain(brain).Ball.player.Team ) ; // cerco solo compagni
        if DummyFriend = nil then begin
          // un compagno deve essere a distanza 1    //         e deve potere raggiungere la palla in onedir
          if DummyGetAnyFriendToBall ( 1, TBrain(brain).Ball.player.Team, TBrain(brain).Ball.player.Ids, TvCell.X, TvCell.Y ) <> nil then   // non gk, non sè stesso
            aList.Add(dstCell);
        end
          // passaggio su compagno
        else if (DummyFriend.Ids <>  TBrain(brain).Ball.Player.ids) and (Dummyfriend.Role <> 'G') and (not TBrain(brain).IsOffside(TBrain(brain).Ball.Player,DummyFriend))  then begin // se è un compagno
          aList.Add(dstCell);
          continue;
        end;
      end;
    end;

    if aList.Count > 0 then begin
      Result := aList[TBrain(brain).RndGenerate0(aList.Count-1)];
      TvCell := TBrain(brain).AiField2TV ( TBrain(brain).Ball.player.Team, Result.X, Result.Y );
      Result := TvCell;
    end;
    aList.Free;

end;
function TSoccerAI.DummyGetAnyFriendToBall ( dist, team: Integer; meIds:string; CellX, CellY: integer): TObject;
var
  i: Integer;
  aFriend: TPlayer;
  aPath: dse_pathplanner.Tpath;
begin
    result := nil;
    aPath:= dse_pathplanner.Tpath.Create ;
  for I := TBrain(brain).Players.Count -1 downto 0 do begin
    aFriend:= TBrain(brain).Players[i];
    if (aFriend.Team <> team) or (aFriend.Role = 'G') or (aFriend.Ids = meIds) or ( not aFriend.CanMove )
    or ( aFriend.Speed < dist)  then continue;

    aPath.Clear ;
    TBrain(brain).GetPath (aFriend.Team, aFriend.CellX ,aFriend.Celly, CellX, CellY, dist{Limit},
    false{useFlank}, false, false,true ,TruncOneDir{OneDir},aPath );

    if (aPath.Count > 0) then begin
      if (aPath[aPath.Count-1].X = CellX) and (aPath[aPath.Count-1].Y = CellY) then begin    // solo se  la raggiunge subito dopo
      Result := aFriend;
        Break;
      end;
    end;

  end;
    aPath.Free;
end;
function TSoccerAI.GetdummyTackle ( team: Integer): TObject;
var
  i: Integer;
begin
    Result:= nil;
    for I := TBrain(brain).Players.Count -1 downto 0 do begin
      if ( not TBrain(brain).Players[i].PressingDone ) and (TBrain(brain).Players[i].canSkill) and (TBrain(brain).Players[i].Role <> 'G') and
          (AbsDistance(TBrain(brain).Players[i].CellX, TBrain(brain).Players[i].CellY, TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY )=1) and
           (TBrain(brain).Players[i].Team = team)
        then begin
          Result := TBrain(brain).Players[i];
          Exit;
        end;

    end;

end;
function TSoccerAI.GetdummyPressing ( team: Integer): TObject;
var
  i: Integer;
begin
    Result:= nil;
    for I := TBrain(brain).Players.Count -1 downto 0 do begin
      if ( not TBrain(brain).Players[i].PressingDone ) and (TBrain(brain).Players[i].canSkill) and (TBrain(brain).Players[i].Role <> 'G') and
          (AbsDistance(TBrain(brain).Players[i].CellX, TBrain(brain).Players[i].CellY, TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY )=1)  and
           (TBrain(brain).Players[i].Team = team) and ( (TBrain(brain).Players[i].TalentId1 = TALENT_ID_EXPERIENCE) or (TBrain(brain).Players[i].TalentId2 = TALENT_ID_EXPERIENCE) )
        then begin
          Result := TBrain(brain).Players[i];
          Exit;
        end;

    end;

end;
function TSoccerAI.DummyReachTheBall ( team: Integer): TObject;
var
  i,MinDist,aRnd,p: Integer;
  aPlayer: TPlayer;
  aListToBall: TObjectList<TPlayer>;
  aListToBalldist1: TObjectList<TPlayer>;
begin
    Result:= nil;

     aListToBall:= TObjectList<TPlayer>.Create(false);
     aListToBalldist1:= TObjectList<TPlayer>.Create(false);

          //prima provo un path alla massima speed che possa raggiungere effettivamente la palla o almeno una distanza 1
      for I := TBrain(brain).Players.Count -1 downto 0 do begin
        aPlayer :=  TBrain(brain).Players[i];
        if ( not aPlayer.canSkill ) or ( not aPlayer.canMove ) or (aPlayer.TalentId1 = TALENT_ID_GOALKEEPER)  then continue;

        if ( not aPlayer.HasBall) and ( aPlayer.Team = team ) then begin


            // se la palla è libera FinalWall è false quindi uso la massima speed  .
          if (TBrain(brain).Ball.Player = nil) then begin
            TBrain(brain).GetPath (aPlayer.Team, aPlayer.CellX ,aPlayer.Celly,
            TBrain(brain).Ball.CellX, TBrain(brain).Ball.CellY, aPlayer.Speed{Limit},
            aPlayer.Flank <> 0{useFlank}, false, false,false ,AbortMultipleDirection{OneDir},aPlayer.MovePath  );
            if aPlayer.MovePath.Count > 0 then begin
               // se ha raggiunto la palla
               if (aPlayer.MovePath[aPlayer.MovePath.Count-1].X = TBrain(brain).Ball.CellX)and (aPlayer.MovePath[aPlayer.MovePath.Count-1].Y = TBrain(brain).Ball.CellY) then begin // raggiunge la palla
                aListToBall.Add(aPlayer);
               end;
            end;
            if aListToBall.Count = 0 then begin // se i player sono lontani e nessuno può raggiungere la palla
              TBrain(brain).GetAggressionCellPath ( aPlayer, TBrain(brain).Ball.CellX, TBrain(brain).Ball.CellY );

              if aPlayer.MovePath.Count > 0 then begin
                  aListToBalldist1.Add(aPlayer);
              end;

            end;

          end
          else if TBrain(brain).Ball.Player <> nil then begin // se c'è un player provo ad arrivare a distanza 1  quindi onedir TruncNotOneDir
            TBrain(brain).GetAggressionCellPath ( aPlayer, TBrain(brain).Ball.CellX, TBrain(brain).Ball.CellY );

            if aPlayer.MovePath.Count > 0 then begin
                aListToBalldist1.Add(aPlayer);
            end;
          end;
        end;
      end;

      if aListToBall.Count > 0  then begin   // ogni player ha il suo MovePath
        aRnd := TBrain(brain).RndGenerate0(aListToBall.Count -1);
        TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [ team ]) + ',' + IntToStr(CMD_PLAY_PLM)+',' + aListToBall[aRnd].ids + ',' + IntToStr(aListToBall[aRnd].MovePath[aListToBall[aRnd].MovePath.Count-1].X) +
         ',' + IntToStr(aListToBall[aRnd].MovePath[aListToBall[aRnd].MovePath.Count-1].Y  ) );
      end
      else if aListToBalldist1.Count > 0 then begin
        // prendo uno fra quelli che ha raggiunto absdistance 1 dalla palla
        aListToBalldist1.sort(TComparer<TPlayer>.Construct(
        function (const L, R: TPlayer): integer
        begin
          Result := AbsDistance( TBrain(brain).Ball.CellX, TBrain(brain).Ball.CellY, L.MovePath [L.MovePath.Count-1 ].X, L.MovePath [L.MovePath.Count-1 ].Y )  -
          AbsDistance( TBrain(brain).Ball.CellX, TBrain(brain).Ball.CellY, R.MovePath [R.MovePath.Count-1 ].X, R.MovePath [R.MovePath.Count-1 ].Y )
        end
       ));

        // L - R  distanza 1 è a elemento 0
        MinDist := AbsDistance( TBrain(brain).Ball.CellX, TBrain(brain).Ball.CellY,
        aListToBalldist1[0].MovePath [aListToBalldist1[0].MovePath.Count-1 ].X,
        aListToBalldist1[0].MovePath [aListToBalldist1[0].MovePath.Count-1 ].Y);

        for P := aListToBalldist1.Count -1 downto 0 do begin
          if AbsDistance( TBrain(brain).Ball.CellX, TBrain(brain).Ball.CellY,
          aListToBalldist1[p].MovePath [aListToBalldist1[p].MovePath.Count-1 ].X,
          aListToBalldist1[p].MovePath [aListToBalldist1[p].MovePath.Count-1 ].Y)
          > MinDist then
            aListToBalldist1.Delete(p);
        end;

        aRnd := TBrain(brain).RndGenerate0(aListToBallDist1.Count -1);
        TBrain(brain).BrainInput(  IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' +IntToStr(CMD_PLAY_PLM)+',' + aListToBalldist1[aRnd].ids  + ',' + IntToStr(aListToBalldist1[aRnd].MovePath[aListToBalldist1[aRnd].MovePath.Count-1].X) +
         ',' + IntToStr(aListToBalldist1[aRnd].MovePath[aListToBalldist1[aRnd].MovePath.Count-1].Y  ) );
      end
      else  begin
        if AI_Injured_sub_tactic_stay(team) = none then begin
          if TBrain(brain).Minute < 120 then
            TBrain(brain).BrainInput( IntTostr(TBrain(brain).Score.TeamGuid [team]) + ',' + IntToStr(CMD_PLAY_PASS)  ) // o ha fatto qualcosa o passo
          else AI_ForceRandomMove (team);
        end;
      end;
      aListToBall.Free;
      aListToBalldist1.Free;
end;


function TSoccerAI.GetDummyMaxAcceleration ( AccelerationMode: TAccelerationMode): TPoint;
var
  P: Integer;
  aList: TList<TAICells>;
  aRnd,iSpeed,MaxSpeed:Integer;
  x,y: Integer;
  AICell: TAICells;
  aDoor: TPoint;
begin
//AccBestDistance, AccSelfY, AccDoor
  result.X := -1;
  if not TBrain(brain).Ball.Player.CanMove then Exit;
  aList:= TList<TAICells>.create;

  iSpeed := TBrain(brain).Ball.player.speed -1;
  if iSpeed < 1 then iSpeed := 1;

  for x:= 1 to 10 do begin       // 0 è portiere // 11 è portiere
    for y:= 0 to 6 do begin
      if AbsDistance(TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY,X,Y) <= iSpeed then begin   // cella nel raggio di speed
        if TBrain(brain).GeTPlayer (X,Y) = nil then begin                          // cella libera
          // la cerco solo in offensiva verso il portiere avversario
          if ((x > TBrain(brain).Ball.Player.CellX) and (TBrain(brain).Ball.Player.Team=0) ) or ((x < TBrain(brain).Ball.Player.CellX) and (TBrain(brain).Ball.Player.Team=1) )  then  begin

          TBrain(brain).GetPath (TBrain(brain).Ball.Player.Team , TBrain(brain).Ball.Player.CellX , TBrain(brain).Ball.Player.CellY, X, Y,iSpeed{Limit},false{useFlank},true{FriendlyWall},
                         true{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, TBrain(brain).Ball.Player.MovePath );
            if TBrain(brain).Ball.Player.MovePath.Count > 0 then begin
              AICell.Cells.X := x;
              AICell.Cells.Y := y;
              AICell.chance := TBrain(brain).Ball.Player.MovePath.Count; // prendo in prestito 'chance' per il sort dopo, ma non è una chance, è il numero di celle di cui si muove
              aList.Add(aICell);
            end;
          end;
        end;

      end;
    end;
  end;

  if aList.Count > 0 then begin

      //AccBestDistance= maggiore numero di celle di cui muoversi, AccSelfY= corre dritto verso il fondo avversario, AccDoor= punta la porta
      // chance non è una probabilità, ma il numero di celle di cui si muove
      if AccelerationMode = AccBestDistance then begin

        aList.sort(TComparer<TAICells>.Construct(
        function (const L, R: TAICells): integer
        begin
          Result := R.chance - L.chance;
        end
       ));
        MaxSpeed := aList[0].chance ;

        for P := aList.Count -1 downto 0 do begin
          if aList[p].chance < MaxSpeed then
            aList.Delete(p);
        end;
        aRnd := TBrain(brain).RndGenerate0(aList.Count -1);   // estraggo solo tra movimenti di Maxspeed ecc...
//        Result := Point (aList[aRnd].cells.X, aList[aRnd].cells.Y);
        TBrain(brain).GetPath (TBrain(brain).Ball.Player.Team , TBrain(brain).Ball.Player.CellX , TBrain(brain).Ball.Player.CellY, aList[aRnd].cells.X, aList[aRnd].cells.Y,iSpeed{Limit},false{useFlank},true{FriendlyWall},
                         true{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, TBrain(brain).Ball.Player.MovePath );
        Result := Point (TBrain(brain).Ball.Player.MovePath [TBrain(brain).Ball.Player.MovePath.Count-1].X, TBrain(brain).Ball.Player.MovePath [TBrain(brain).Ball.Player.MovePath.Count-1].Y);

      end
      else if AccelerationMode = AccSelfY then begin
        aList.sort(TComparer<TAICells>.Construct(
        function (const L, R: TAICells): integer
        begin
          Result := R.chance - L.chance;
        end
       ));
        MaxSpeed := aList[0].chance ;

        for P := aList.Count -1 downto 0 do begin
          if aList[p].chance < MaxSpeed then
            aList.Delete(p);
        end;

        for P := aList.Count -1 downto 0 do begin
          if aList[p].Cells.Y  <> TBrain(brain).Ball.Player.CellY then
            aList.Delete(p);
        end;
        if aList.Count = 0 then begin
          aList.Free;
          Exit;
        end
        else
        TBrain(brain).GetPath (TBrain(brain).Ball.Player.Team , TBrain(brain).Ball.Player.CellX , TBrain(brain).Ball.Player.CellY, aList[0].cells.X, aList[0].cells.Y,iSpeed{Limit},false{useFlank},true{FriendlyWall},
                         true{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, TBrain(brain).Ball.Player.MovePath );
       // Result := Point (aList[0].cells.X, aList[0].cells.Y);
        Result := Point (TBrain(brain).Ball.Player.MovePath [TBrain(brain).Ball.Player.MovePath.Count-1].X, TBrain(brain).Ball.Player.MovePath [TBrain(brain).Ball.Player.MovePath.Count-1].Y);


      end
      else if AccelerationMode = AccDoor then begin

        aDoor:= TBrain(brain).GetOpponentDoor (TBrain(brain).Ball.Player );

        aList.sort(TComparer<TAICells>.Construct(
        function (const L, R: TAICells): integer
        begin
          Result := AbsDistance( aDoor.X, aDoor.Y, L.Cells.X, L.Cells.Y  )  -
          AbsDistance( aDoor.X, aDoor.Y, R.Cells.X, R.Cells.Y  )
        end
       ));

        TBrain(brain).GetPath (TBrain(brain).Ball.Player.Team , TBrain(brain).Ball.Player.CellX , TBrain(brain).Ball.Player.CellY, aList[0].cells.X, aList[0].cells.Y,iSpeed{Limit},false{useFlank},true{FriendlyWall},
                         true{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, TBrain(brain).Ball.Player.MovePath );
       // Result := Point (aList[0].cells.X, aList[0].cells.Y);
        Result := Point (TBrain(brain).Ball.Player.MovePath [TBrain(brain).Ball.Player.MovePath.Count-1].X, TBrain(brain).Ball.Player.MovePath [TBrain(brain).Ball.Player.MovePath.Count-1].Y);

      end;
  end;
  aList.free;

end;
function TSoccerAI.GetDummyMaxAccelerationShotCells ( OnlyBuffed: boolean ): TPoint;
var
  aList: TList<TPoint>;
  aRnd,iSpeed:Integer;
  i,dist: Integer;
  TvShotCell: TPoint;
begin

  result.X := -1;
  if not TBrain(brain).Ball.Player.CanMove then Exit;
  aList:= TList<TPoint>.create;

  iSpeed := TBrain(brain).Ball.player.speed -1;
  if iSpeed < 1 then iSpeed := 1;
  // riempo una lista di ShotCells (dipende dal team) e per ognuna valuto se posso raggiungerla
  for I := 0 to ShotCells.Count -1 do begin
    if ShotCells[i].doorTeam = TBrain(brain).Ball.Player.Team then Continue; // solo shotCell Avversarie
    TvShotCell :=  Point(ShotCells[i].CellX, ShotCells[i].CellY) ;
    if TBrain(brain).GeTPlayer (TvShotCell.X,TvShotCell.Y) <> nil then Continue;  // cerco una cella libera
    dist :=  AbsDistance(TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY,TvShotCell.X,TvShotCell.Y);
    if dist <= iSpeed then begin   // cella nel raggio di speed

      if not OnlyBuffed then
      TBrain(brain).GetPath (TBrain(brain).Ball.Player.Team , TBrain(brain).Ball.Player.CellX , TBrain(brain).Ball.Player.CellY, TvShotCell.X,TvShotCell.Y,iSpeed{Limit},false{useFlank},true{FriendlyWall},
                         true{OpponentWall},true{FinalWall},AbortMultipleDirection{OneDir}, TBrain(brain).Ball.Player.MovePath )
      else if dist > 1 then begin  // minimo 2 celle per buff
      TBrain(brain).GetPath (TBrain(brain).Ball.Player.Team , TBrain(brain).Ball.Player.CellX , TBrain(brain).Ball.Player.CellY, TvShotCell.X,TvShotCell.Y,iSpeed{Limit},false{useFlank},true{FriendlyWall},
                         true{OpponentWall},true{FinalWall},AbortMultipleDirection{OneDir}, TBrain(brain).Ball.Player.MovePath )

      end;

      if TBrain(brain).Ball.Player.MovePath.Count > 0 then
        aList.Add(TvShotCell);
    end;
  end;



  if aList.Count > 0 then begin

      aRnd := TBrain(brain).RndGenerate0(aList.Count -1);
      Result.X := aList[aRnd].X;
      Result.Y := aList[aRnd].Y;
  end;

  aList.Free;

end;
function TSoccerAI.GetDummyMaxAccelerationBottom: TPoint;
var
  aplmCell: TPoint;
begin
  result.X := -1;
  aplmCell := GetDummyMaxAcceleration( AccSelfY );
  if aplmCell.X <> -1 then begin
    if (aplmCell.X = 1) or (aplmCell.X = 10) then begin
      Result.X := aplmCell.X;
      Result.Y := aplmCell.Y;
    end;
  end;

end;
function TSoccerAI.GetDummyGoAheadCell : Tpoint; // il player con la palla cerca di avanzare
var
  aList: TList<TAICells>;
  aRnd,iSpeed:Integer;
  x,y: Integer;
  AICell: TAICells;
begin
  // uguale a GetDummyMaxAcceleration ma nienete Sort per speed e estrazione random tra tutte
  // o dritto o in diagonale
  result.X := -1;
  aList:= TList<TAICells>.create;

  iSpeed := TBrain(brain).Ball.player.speed -1;
  if iSpeed < 1 then iSpeed := 1;

  for x:= 1 to 10 do begin       // 0 è portiere // 11 è portiere
    for y:= 0 to 6 do begin
      if AbsDistance(TBrain(brain).Ball.Player.CellX,TBrain(brain).Ball.Player.CellY,X,Y) <= iSpeed then begin   // cella nel raggio di speed
        if TBrain(brain).GeTPlayer (X,Y) = nil then begin                          // cella libera
          // la cerco solo in offensiva verso il portiere avversario
          if ((x > TBrain(brain).Ball.Player.CellX) and (TBrain(brain).Ball.Player.Team=0) ) or ((x < TBrain(brain).Ball.Player.CellX) and (TBrain(brain).Ball.Player.Team=1) )  then  begin

          TBrain(brain).GetPath (TBrain(brain).Ball.Player.Team , TBrain(brain).Ball.Player.CellX , TBrain(brain).Ball.Player.CellY, X, Y,iSpeed{Limit},false{useFlank},true{FriendlyWall},
                         true{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, TBrain(brain).Ball.Player.MovePath );
            if TBrain(brain).Ball.Player.MovePath.Count > 0 then begin
              AICell.Cells.X := x;
              AICell.Cells.Y := y;
//              AICell.chance :=TBrain(brain).Ball.Player.MovePath.Count;
              aList.Add(aICell);
            end;
          end;
        end;

      end;
    end;
  end;

  if aList.Count > 0 then begin

      aRnd := TBrain(brain).RndGenerate0(aList.Count -1);   // estraggo solo tra movimenti di 1,2,3,4... speed ecc...
      // mando l'ultima cella
      TBrain(brain).GetPath (TBrain(brain).Ball.Player.Team , TBrain(brain).Ball.Player.CellX , TBrain(brain).Ball.Player.CellY, aList[aRnd].cells.X, aList[aRnd].cells.Y,iSpeed{Limit},false{useFlank},true{FriendlyWall},
                         true{OpponentWall},true{FinalWall},TruncOneDir{OneDir}, TBrain(brain).Ball.Player.MovePath );

      if TBrain(brain).Ball.Player.MovePath.Count > 0 then
        Result := Point (  TBrain(brain).Ball.Player.MovePath[TBrain(brain).Ball.Player.MovePath.Count-1].X, TBrain(brain).Ball.Player.MovePath[TBrain(brain).Ball.Player.MovePath.Count-1].Y  );

  end;

  aList.free;
end;
function TSoccerAI.GetBestDefenseReserve ( Team,MinStamina: integer ): string;
var
  i,p,MaxDefense: Integer;
  lstBestDefense: TObjectList<TPlayer>;
begin
// talentId <> 1 non .rol <> 'G' in quanto il role è N in panchina
    lstBestDefense:= TObjectList<TPlayer>.Create(False);

    for I := TBrain(brain).Reserves.Count -1 downto 0 do begin
      if TBrain(brain).Reserves[i].Team = Team then begin
        if (TBrain(brain).Reserves[i].talentid1 <> TALENT_ID_GOALKEEPER) and (TBrain(brain).Reserves[i].Stamina >= MinStamina)  then begin
          lstBestDefense.Add(TBrain(brain).Reserves[i]);
        end;
      end;
    end;

    lstBestDefense.sort(TComparer<TPlayer>.Construct(
    function (const L, R: TPlayer): integer
    begin
      Result := (R.Defense )- (L.Defense  );
    end
   ));
    MaxDefense := lstBestDefense[0].Defense   ;

    for P := lstBestDefense.Count -1 downto 0 do begin
      if lstBestDefense[p].Defense  < MaxDefense then
        lstBestDefense.Delete(p);
    end;

    Result :=  lstBestDefense[ TBrain(brain).RndGenerate0(lstBestDefense.Count-1)].Ids ;
    lstBestDefense.Free;

end;
function TSoccerAI.GetBestGKReserve ( Team,MinStamina: integer ): string;
var
  i,p,MaxDefense: Integer;
  lstBestDefense: TObjectList<TPlayer>;
begin
// talentId <> 1 non .rol <> 'G' in quanto il role è N in panchina
    lstBestDefense:= TObjectList<TPlayer>.Create(False);

    for I := TBrain(brain).Reserves.Count -1 downto 0 do begin
      if (TBrain(brain).Reserves[i].Team = Team) and (TBrain(brain).Reserves[i].talentid1 = TALENT_ID_GOALKEEPER) then begin
        if (TBrain(brain).Reserves[i].Stamina >= MinStamina)  then begin
          lstBestDefense.Add(TBrain(brain).Reserves[i]);   // es. potrebbe avere 4 portieri
        end;
      end;
    end;


    if lstBestDefense.Count = 0 then begin                                   // es. non ha Gk di rriserva
      Result :=  '0';
      lstBestDefense.Free;
      exit;
    end;

    lstBestDefense.sort(TComparer<TPlayer>.Construct(
    function (const L, R: TPlayer): integer
    begin
      Result := (R.Defense )- (L.Defense  );
    end
   ));
    MaxDefense := lstBestDefense[0].Defense   ;

    for P := lstBestDefense.Count -1 downto 0 do begin
      if lstBestDefense[p].Defense  < MaxDefense then
        lstBestDefense.Delete(p);
    end;

    Result :=  lstBestDefense[ TBrain(brain).RndGenerate0(lstBestDefense.Count-1)].Ids ;
    lstBestDefense.Free;

end;
function TSoccerAI.GetBestPassingReserve ( Team,MinStamina: integer  ): string;
var
  i,p,MaxPassing: Integer;
  lstBestPassing: TObjectList<TPlayer>;
begin
// talentId <> 1 non .rol <> 'G' in quanto il role è N in panchina
    lstBestPassing:= TObjectList<TPlayer>.Create(False);

    for I := TBrain(brain).Reserves.Count -1 downto 0 do begin
      if TBrain(brain).Reserves[i].Team = Team then begin
        if (TBrain(brain).Reserves[i].TalentId1 <> TALENT_ID_GOALKEEPER) and (TBrain(brain).Reserves[i].Stamina >= MinStamina) then begin
          lstBestPassing.Add(TBrain(brain).Reserves[i]);
        end;
      end;
    end;

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

    Result :=  lstBestPassing[ TBrain(brain).RndGenerate0(lstBestPassing.Count-1)].Ids ;
    lstBestPassing.Free;

end;
function TSoccerAI.GetBestShotReserve ( Team,MinStamina: integer   ): string;
var
  i,p,MaxShot: Integer;
  lstBestShot: TObjectList<TPlayer>;
begin
// talentId <> 1 non .rol <> 'G' in quanto il role è N in panchina
    lstBestShot:= TObjectList<TPlayer>.Create(False);

    for I := TBrain(brain).Reserves.Count -1 downto 0 do begin
      if TBrain(brain).Reserves[i].Team = Team then begin
        if (TBrain(brain).Reserves[i].TalentId1 <> TALENT_ID_GOALKEEPER) and (TBrain(brain).Reserves[i].Stamina >= MinStamina)  then begin
          lstBestShot.Add(TBrain(brain).Reserves[i]);
        end;
      end;
    end;

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

    Result :=  lstBestShot[ TBrain(brain).RndGenerate0(lstBestShot.Count-1)].Ids ;
    lstBestShot.Free;

end;
function TSoccerAI.GetWorstStamina ( Team: integer ): TObject;
var
  i,p,MinStamina: Integer;
  lstWorstStamina: TObjectList<TPlayer>;
begin
    // il result può essere nil se in zona non c'è nessuno
    lstWorstStamina:= TObjectList<TPlayer>.Create(False);

    for I := TBrain(brain).Players.Count -1 downto 0 do begin
// nin cerca un ruolo, cerca quelli che in quella zona hanno il BallControl forte
      if TBrain(brain).Players[i].Team = Team then
          lstWorstStamina.Add(TBrain(brain).Players[i]);
    end;

    if lstWorstStamina.count > 0 then begin

      lstWorstStamina.sort(TComparer<TPlayer>.Construct(
      function (const L, R: TPlayer): integer
      begin
        Result := (L.Stamina )- (R.Stamina  );     // <--- il più basso
      end
     ));
      MinStamina := lstWorstStamina[0].Stamina   ;

      for P := lstWorstStamina.Count -1 downto 0 do begin
        if lstWorstStamina[p].Stamina  > MinStamina then     // il più basso
          lstWorstStamina.Delete(p);
      end;
//      Result :=  lstWorstBallControl[ brain.TBrain(brain).RndGenerate0(lstWorstBallControl.Count-1)].Ids ;
      // dato che questa lista scompare passo il puntatore al player originale
      result := TBrain(brain).GeTPlayer( lstWorstStamina[ TBrain(brain).RndGenerate0(lstWorstStamina.Count-1)].Ids) ;
    end
    else Result := nil;
    lstWorstStamina.Free;
end;
function TSoccerAI.GetPlayerForOUT (team: Integer; PlayerOUT: TSubOUT ):TObject;//type TSubINOUT = (DefenderOUT,forwardOUT);
var
  i,D,M,F: integer;
begin
  // Può tornare una alternativa, non proprio il ruolo richiesto ma quello vicino
  // calcolo formazione base
  Result := nil;
  D:=0; M:=0; F:=0;
  if team = 0 then begin
    for i := 0 to TBrain(brain).Players.Count -1 do begin
      if (TBrain(brain).Players[i].Team <> Team )  or ( TBrain(brain).Players[i].TalentId1 = TALENT_ID_GOALKEEPER)  then
        Continue;

      if (TBrain(brain).Players[i].DefaultCellX = 2) then
        inc (D)
      else if (TBrain(brain).Players[i].DefaultCellX = 5) then
        inc (M)
      else if (TBrain(brain).Players[i].DefaultCellX = 8) then
        inc (F);
    end;
  end
  else begin
    for i := 0 to TBrain(brain).Players.Count -1 do begin
      if (TBrain(brain).Players[i].Team <> Team ) or ( TBrain(brain).Players[i].TalentId1 = TALENT_ID_GOALKEEPER) then
        Continue;
      if (TBrain(brain).Players[i].DefaultCellX = 9) then
        inc (D)
      else if (TBrain(brain).Players[i].DefaultCellX = 6) then
        inc (M)
      else if (TBrain(brain).Players[i].DefaultCellX = 3) then
        inc (F);
    end;
  end;

  // ho la fomrazione 4-3-3 5-4-1 ecc...
  if PlayerOUT = DefenderOut then begin    // entra un attaccante o un centrocampista
    if D >= 4 then begin// se almeno 4 difensori ne esce 1
    //esce il peggior difensore
      Result := TBrain(brain).GetWorstDefense(team);
    end
    else if M >= 3 then begin// se almeno 3 midfield ne esce 1
    //esce il peggior centrocapista
      Result := TBrain(brain).GetWorstPassing(team);
    end;
  end
  else if PlayerOUT = ForwardOut then begin   // entra un difensore o un centrocampista
    if F >= 2 then begin// se almeno 2 Attaccanti ne esce 1
    //esce il peggior attaccante
      Result := TBrain(brain).GetWorstShot(team);
    end
    else if M >= 3 then begin// se almeno 3 midfield ne esce 1
    //esce il peggior centrocapista
      Result := TBrain(brain).GetWorstPassing(team);
    end;

  end;

  // result può essere nil in caso di molti espulsi
end;
function TSoccerAI.GetBestCrossing ( Team: integer  ): string;
var
  i,p,MaxCrossing: Integer;
  lstBestCross: TObjectList<TPlayer>;
begin
    lstBestCross:= TObjectList<TPlayer>.Create(False);

   (* COF, FKF2 *)

    for I := TBrain(brain).Players.Count -1 downto 0  do begin

      if TBrain(brain).Players[i].Team = Team then begin
        if TBrain(brain).Players[i].Role <> 'G'  then begin
          lstBestCross.Add(TBrain(brain).Players[i]);
        end;
      end;
    end;

    lstBestCross.sort(TComparer<TPlayer>.Construct(
    function (const L, R: TPlayer): integer
    begin
      R.tmp := R.Passing;
      L.tmp := L.Passing;
      if R.TalentId1 = TALENT_ID_CROSSING then
        R.tmp := R.tmp + 1;
      if L.TalentId1 = TALENT_ID_CROSSING then
        L.tmp := L.tmp + 1;
      Result := (R.tmp )- (L.tmp );
    end
   ));
    MaxCrossing := lstBestCross[0].tmp ;

    for P := lstBestCross.Count -1 downto 0 do begin
      if (lstBestCross[p].tmp ) < MaxCrossing then
        lstBestCross.Delete(p);
    end;

    Result :=  lstBestCross[ TBrain(brain).RndGenerate0(lstBestCross.Count-1)].Ids ;
    lstBestCross.Free;

end;
function TSoccerAI.GetBestHeading ( Team: integer; excludeIds: string  ): string;
var
  i,p,MaxHeading: Integer;
  lstBestHeading: TObjectList<TPlayer>;
begin
    lstBestHeading:= TObjectList<TPlayer>.Create(False);
   (* COA1 COA2 COA3, COD1, COD2, COD3 *)
    for I := TBrain(brain).Players.Count -1 downto 0 do begin

      if TBrain(brain).Players[i].Team = Team then begin
        if (TBrain(brain).Players[i].talentid1 <> TALENT_ID_GOALKEEPER ) and (TBrain(brain).Players[i].ids <> excludeIds)  then begin  // iscof feve essere ancora settato
          lstBestHeading.Add(TBrain(brain).Players[i]);
        end;
      end;
    end;

    lstBestHeading.sort(TComparer<TPlayer>.Construct(
    function (const L, R: TPlayer): integer
    begin
      Result := (R.heading  )- (L.Heading );
    end
   ));
    MaxHeading := lstBestHeading[0].heading  ;

    for P := lstBestHeading.Count -1 downto 0 do begin
      if lstBestHeading.Count = 3 then Break; // minimo 3 saltatori

      if lstBestHeading[p].heading < MaxHeading then
        lstBestHeading.Delete(p);
    end;
    Result := lstBestHeading[0].Ids + ',' + lstBestHeading[1].Ids + ',' + lstBestHeading[2].Ids ;
    lstBestHeading.Free;

end;
function TSoccerAI.GetBestPassing ( Team: integer  ): string;
var
  i,p,MaxPassing: Integer;
  lstBestPassing: TObjectList<TPlayer>;
begin
    lstBestPassing:= TObjectList<TPlayer>.Create(False);

   (*  FKF1 *)

    for I := TBrain(brain).Players.Count -1 downto 0 do begin
      if TBrain(brain).Players[i].Team = Team then begin
        if TBrain(brain).Players[i].TalentId1 <> TALENT_ID_GOALKEEPER  then begin
          lstBestPassing.Add(TBrain(brain).Players[i]);
        end;
      end;
    end;

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

    Result :=  lstBestPassing[ TBrain(brain).RndGenerate0(lstBestPassing.Count-1)].Ids ;
    lstBestPassing.Free;

end;
function TSoccerAI.GetBestShot ( Team: integer  ): string;
var
  i,p,MaxShot: Integer;
  lstBestShot: TObjectList<TPlayer>;
begin
    lstBestShot:= TObjectList<TPlayer>.Create(False);

   (*  FKF3, FKF4 *)

    for I := TBrain(brain).Players.Count -1 downto 0 do begin
      if IsOutSide( TBrain(brain).Players[i].CellX ,TBrain(brain).Players[i].CellY ) then Continue;
      if TBrain(brain).Players[i].Team = Team then begin
        if TBrain(brain).Players[i].TalentId1 <> TALENT_ID_GOALKEEPER  then begin
          lstBestShot.Add(TBrain(brain).Players[i]);
        end;
      end;
    end;

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

    Result :=  lstBestShot[ TBrain(brain).RndGenerate0(lstBestShot.Count-1)].Ids ;
    lstBestShot.Free;

end;
function TSoccerAI.GetBestBarrier ( Team: integer  ): string;
var
  i,p,MaxDefense: Integer;
  lstBestDefense: TObjectList<TPlayer>;
begin
    lstBestDefense:= TObjectList<TPlayer>.Create(False);

   (*  FKD3 *)

    for I := TBrain(brain).Players.Count -1 downto 0 do begin
      if IsOutSide( TBrain(brain).Players[i].CellX ,TBrain(brain).Players[i].CellY ) then Continue;
      if TBrain(brain).Players[i].Team = Team then begin
        if TBrain(brain).Players[i].TalentId1 <> TALENT_ID_GOALKEEPER  then begin
          lstBestDefense.Add(TBrain(brain).Players[i]);
        end;
      end;
    end;

    lstBestDefense.sort(TComparer<TPlayer>.Construct(
    function (const L, R: TPlayer): integer
    begin
      Result := (R.Defense )- (L.Defense  );
    end
   ));
    MaxDefense := lstBestDefense[0].Defense   ;

    for P := lstBestDefense.Count -1 downto 0 do begin
      if lstBestDefense.Count = 4 then Break; // minimo 4 in barriera
      if lstBestDefense[p].Defense  < MaxDefense then
        lstBestDefense.Delete(p);
    end;

    Result := lstBestDefense[0].Ids + ',' + lstBestDefense[1].Ids + ',' + lstBestDefense[2].Ids + ',' + lstBestDefense[3].Ids;
    lstBestDefense.Free;

end;
function TSoccerAI.GetRandomDefaultMidFieldCellFree ( team:Integer ): TPoint;
var
  y: Integer;
  lstCellY : Tlist<Integer>;
begin
  Result.X := -1;
  lstCellY := Tlist<Integer>.create;

  if team = 0 then begin
    for y := 0 to 6 do begin
      if TBrain(brain).GeTPlayerDefault(5,y) = nil then
        lstCellY.Add(y);
    end;
  end
  else begin
    for y := 0 to 6 do begin
      if TBrain(brain).GeTPlayerDefault(6,y) = nil then
        lstCellY.Add(y);
    end;
  end;

  if lstCellY.Count > 0 then begin
    if team = 0 then
      Result := Point (5, lstCellY[ TBrain(brain).RndGenerate0(lstCellY.Count-1)])
      else Result := Point (6, lstCellY[ TBrain(brain).RndGenerate0(lstCellY.Count-1)]);
  end;

  lstCellY.Free;

end;
function TSoccerAI.GetRandomDefaultDefenseCellFree ( team:Integer ): TPoint;
var
  y: Integer;
  lstCellY : Tlist<Integer>;
begin
  Result.X := -1;
  lstCellY := Tlist<Integer>.create;

  if team = 0 then begin
    for y := 0 to 6 do begin
      if TBrain(brain).GeTPlayerDefault(2,y) = nil then
        lstCellY.Add(y);
    end;
  end
  else begin
    for y := 0 to 6 do begin
      if TBrain(brain).GeTPlayerDefault(9,y) = nil then
        lstCellY.Add(y);
    end;
  end;

  if lstCellY.Count > 0 then begin
    if team = 0 then
      Result := Point (2, lstCellY[ TBrain(brain).RndGenerate0(lstCellY.Count-1)])
      else Result := Point (9, lstCellY[ TBrain(brain).RndGenerate0(lstCellY.Count-1)]);
  end;

  lstCellY.Free;

end;
function TSoccerAI.GetRandomDefaultForwardCellFree ( team:Integer ): TPoint;
var
  y: Integer;
  lstCellY : Tlist<Integer>;
begin
  Result.X := -1;
  lstCellY := Tlist<Integer>.create;

  if team = 0 then begin
    for y := 0 to 6 do begin
      if TBrain(brain).GeTPlayerDefault(8,y) = nil then
        lstCellY.Add(y);
    end;
  end
  else begin
    for y := 0 to 6 do begin
      if TBrain(brain).GeTPlayerDefault(3,y) = nil then
        lstCellY.Add(y);
    end;
  end;

  if lstCellY.Count > 0 then begin
    if team = 0 then
      Result := Point (8, lstCellY[ TBrain(brain).RndGenerate0(lstCellY.Count-1)])
      else Result := Point (3, lstCellY[ TBrain(brain).RndGenerate0(lstCellY.Count-1)]);
  end;

  lstCellY.Free;

end;

end.
