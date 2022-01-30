unit validate;

interface
uses classes, sysutils, utilities, OverbyteIcsWSocketTS ;

procedure validate_aiteam ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_pause ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_setplayer ( const CommaText: string; Cli:TWSocketThrdClient  );

procedure validate_CMD1 ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_CMD3 ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_CMD4 ( const CommaText: string; Cli:TWSocketThrdClient  );

procedure validate_CMDlop ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_debug_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_CMD_coa ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_CMD_cod ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_CMD_bar ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_CMD_subs ( const CommaText: string; Cli:TWSocketThrdClient  );

procedure validate_sell ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_CancelSell ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_Buy ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_Dismiss ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_Market ( const CommaText: string; Cli:TWSocketThrdClient );

procedure validate_Login ( const CommaText: string; Cli:TWSocketThrdClient );
procedure validate_GetTeamsByCountry ( const CommaText: string; Cli:TWSocketThrdClient  );
procedure validate_clientcreateteam ( const CommaText: string; Cli:TWSocketThrdClient  ) ;
procedure validate_viewMatch ( const CommaText: string; Cli:TWSocketThrdClient  ) ;

implementation
uses  SoccerBrainv3;
function validate_Brain ( Cli:TWSocketThrdClient  ): Boolean;
begin
  result := True;
  cli.sReason:= '';
  if Cli.Brain = nil then begin
    cli.sReason:= 'no Active Brain';
    Result := False;
  end;

end;
function validate_CliId_Turn_TeamGuid ( Cli:TWSocketThrdClient  ): Boolean;
begin
  result := True;
  if TBrain(Cli.brain).Score.CliId [TBrain(Cli.brain).TeamTurn] <> Cli.CliId then begin
    cli.sReason:= 'Turn/CliId mismatch';
    result := False;
    Exit;
  end;

  // coerenza guidTeam e teamTurn
  if TBrain(Cli.brain).Score.TeamGuid  [TBrain(Cli.brain).TeamTurn] <> cli.GuidTeams[TBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'TeamGuid mismatch';
    result := False;
    Exit;
  end;
end;
function validate_cells ( cx,cy: string; Cli:TWSocketThrdClient ): Boolean;
var
  aValue : Integer;
begin
  if not TryDecimalStrToInt( cx, AValue) then begin
    cli.sReason:= 'Cellx not numeric';
    Exit;
  end;
  if not TryDecimalStrToInt( cy, AValue) then begin
    cli.sReason:= 'CellY not numeric';
    Exit;
  end;
  if IsOutSide (StrToInt( cx), StrToInt( cy)) then begin
    cli.sReason:= 'CellX or CellY outside field';
    Exit;
  end;

end;



procedure validate_aiteam ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;
begin
  // 0=aiteam 1=team 2=0 o -1
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  // team
  if not TryDecimalStrToInt( ts[0], AValue) then begin
    cli.sReason:= 'Team not numeric';
    ts.Free;
    Exit;
  end;
  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'AI true/false not numeric';
    ts.Free;
    Exit;
  end;


  ts.Free;

end;
procedure validate_pause ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;
begin
  // 0=pause 1=0 o -1
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;


  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 1 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  // true or false
  if not TryDecimalStrToInt( ts[0], AValue) then begin
    cli.sReason:= 'pause not numeric';
    ts.Free;
    Exit;
  end;


  ts.Free;

end;
procedure validate_setplayer ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;
begin
  // 0=setplayer 1=guid/ids 2=cellx 3=celly
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;


  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  // player, cellx, celly
  if not TryDecimalStrToInt( ts[0], AValue) then begin
    cli.sReason:= 'Player not numeric';
    ts.Free;
    Exit;
  end;

  if not validate_cells ( ts[1], ts[2], cli ) then begin
    ts.free;
    Exit;
  end;
  ts.Free;

end;

procedure validate_CMD4 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TPlayer;
  ts: TStringList;
  aValue: Integer;
begin
  // 0=ids 1=cellX 2=CellY
  cli.sReason:='';
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  // Coerenza Ids
  aPlayer := TBrain(Cli.brain).GetPlayer  (ts[0])   ;
  if aPlayer = nil then begin
    cli.sReason:= 'Player not found';
    ts.Free;
    Exit;
  end;
  if aPlayer.GuidTeam <> Cli.GuidTeams[TBrain(Cli.brain).GenderN] then begin
    cli.sReason:= 'Player GuidTeam mismatch';
    ts.Free;
    Exit;
  end;

  if not validate_cells ( ts[1], ts[2], cli ) then begin
    ts.free;
    Exit;
  end;

  ts.Free;

end;
procedure validate_CMD3 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;

begin
//   CRO SHP LOP DRI 0=cellX 1=CellY
  if not validate_Brain ( Cli ) then Exit;
//  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

   { TODO : fare validate setball a parte}
  if ts[0] <> 'setball' then begin

    if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  end;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not validate_cells ( ts[1], ts[2], cli ) then begin
    ts.free;
    Exit;
  end;
  ts.Free;
end;
procedure validate_CMDlop ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: Integer;

begin
  // 0=cellX 1=CellY 2=N or GKLOP
  if not validate_Brain ( Cli ) then Exit;
//  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  if not validate_cells ( ts[1], ts[2], cli ) then begin
    ts.free;
    Exit;
  end;

  ts.Free;
end;
procedure validate_CMD1 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
begin
//    PRS POS PRO PASS COR PRE TAC
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 1 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  ts.Free;

end;
procedure validate_debug_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  aValue: integer;
begin

  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 1 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[0],aValue) then begin
    cli.sReason:= CommaText + ' not numeric';
    ts.Free;
    Exit;
  end;

  ts.Free;

end;
procedure validate_CMD2 ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
begin
//   cmd TAC PRE    0=ids
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  ts.Free;

end;

procedure validate_CMD_coa ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TPlayer;
  ts: TStringList;
  i: Integer;
begin
  // CORNER_ATTACK_SETUP 0=cop 1=coa 2=coa 3=coa
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 4 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  // Coerenza Ids
  for I := 0 to 3 do begin
    aPlayer := TBrain(Cli.brain).GeTPlayer(ts[i]);
    if aPlayer = nil then begin
      cli.sReason:= 'Player not found';
      ts.Free;
      Exit;
    end;
    if aPlayer.GuidTeam <> Cli.GuidTeams[TBrain(Cli.brain).GenderN]  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

  ts.Free;

end;
procedure validate_CMD_cod ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TPlayer;
  ts: TStringList;
  i: Integer;
begin
  // cmd CORNER_DEFENSE_SETUP 0=cod 1=cod 2=cod
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 3 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;


  // Coerenza Ids
  for I := 0 to 2 do begin
    aPlayer := TBrain(Cli.brain).GeTPlayer(ts[i]);
    if aPlayer = nil then begin
      cli.sReason:= 'Player not found';
      ts.Free;
      Exit;
    end;
    if aPlayer.GuidTeam <> Cli.GuidTeams[TBrain(Cli.brain).GenderN]  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

  ts.Free;

end;
procedure validate_CMD_bar ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TPlayer;
  ts: TStringList;
  i: Integer;
begin
  // cmd CORNER_DEFENSE_SETUP 0=cod 1=cod 2=cod 3=cod
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 4 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  // Coerenza Ids
  for I := 0 to 3 do begin
    aPlayer := TBrain(Cli.brain).GeTPlayer(ts[i]);
    if aPlayer = nil then begin
      cli.sReason:= 'Player not found';
      ts.Free;
      Exit;
    end;
    if aPlayer.GuidTeam <> Cli.GuidTeams[TBrain(Cli.brain).GenderN]  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

    ts.Free;

end;
procedure validate_CMD_subs ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  aPlayer: TPlayer;
  ts: TStringList;
  i: Integer;
begin
  // 0='SUBS 1=ids 2=ids
  if not validate_Brain ( Cli ) then Exit;
  if not validate_CliId_Turn_TeamGuid ( Cli ) then Exit;

  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  // Coerenza Ids
  for I := 0 to 1 do begin
    aPlayer := TBrain(Cli.brain).GeTPlayer2(ts[i]);
    if aPlayer = nil then begin
      cli.sReason:= 'Player not found';
      ts.Free;
      Exit;
    end;
    if aPlayer.GuidTeam <> Cli.GuidTeams[TBrain(Cli.brain).GenderN]  then begin
      cli.sReason:= 'Player GuidTeam mismatch';
      ts.Free;
      Exit;
    end;
  end;

  ts.Free;

end;

procedure validate_sell ( const commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer,sellprice
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 2 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[0], AValue) then begin
    cli.sReason:= 'validate_sell Player not numeric';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[1], AValue) then begin
    cli.sReason:= 'validate_sell sell price not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure validate_cancelsell ( const commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 1 then begin
    cli.sReason:= 'Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[0], AValue) then begin
    cli.sReason:= 'validate_sell Player not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;


end;
procedure validate_buy ( const commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 1 then begin
    cli.sReason:= 'validate_sell Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[0], AValue) then begin
    cli.sReason:= 'validate_sell Player not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure validate_dismiss ( const commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 1 then begin
    cli.sReason:= 'validate_dismiss Parameter count mismatch';
    ts.Free;
    Exit;
  end;

  if not TryDecimalStrToInt( ts[0], AValue) then begin
    cli.sReason:= 'validate_dismiss Player not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure validate_market ( const commatext: string; Cli:TWSocketThrdClient  );
var
  aValue: Integer;
  ts: TStringList;
begin
  // sell,guidplayer
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if ts.Count <> 1 then begin
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
procedure validate_login ( const CommaText: string; Cli:TWSocketThrdClient );
begin
  // 0=user 1=password
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
procedure validate_GetTeamsByCountry ( const CommaText: string; Cli:TWSocketThrdClient  );
var
  ts: TStringList;
  value: Integer;
begin
  // 0=idcountry

  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if not TryDecimalStrToInt( ts[0], Value) then begin
    cli.sReason:= 'id World.Country not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure validate_clientcreateteam ( const CommaText: string; Cli:TWSocketThrdClient  ) ;
var
  ts: TStringList;
  value: Integer;
begin
  // 0=cmd 1=idWorldTeam
  cli.sReason:='';
  ts:= TStringList.Create ;
  ts.CommaText := CommaText;
  if not TryDecimalStrToInt( ts[0], Value) then begin
    cli.sReason:= 'id World.Teams not numeric';
    ts.Free;
    Exit;
  end;
  ts.Free;

end;
procedure validate_viewMatch ( const CommaText: string; Cli:TWSocketThrdClient  ) ;
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

end.
