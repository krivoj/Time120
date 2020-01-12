unit Unit2;
// unit che si occupa solo dei vari ShowForm1.Panel in base a GameScreen

interface
Function Translate ( aString : string  ): String;
procedure ShowPanelBack;
procedure ShowMain;
procedure ShowFormations;
procedure ShowCornerFreeKickGrid;
procedure ShowError ( AString: string);
procedure ShowLevelUpA ( Guid,value: string );
procedure ShowLevelUpT ( Guid,value: string );
procedure ShowStandings;
procedure ShowLogin;
procedure ShowScore;

implementation
uses unit1, SoccerBrainv3, vcl.graphics, vcl.controls, dse_bitmap;


Function Translate ( aString : string  ): String;
begin
   Result :=  TranslateMessages.Values [aString];
end;


procedure ShowPanelBack;
begin
  Form1.PanelBack.Left:=0;
  Form1.PanelBack.Top := 0;
  Form1.PanelBack.width := form1.Width;
  Form1.PanelBack.height := form1.height;
  Form1.PanelCountryTeam.Left := (Form1.PanelBack.Width div 2 ) - (Form1.PanelCountryTeam.Width div 2 );
  Form1.PanelCountryTeam.Top := (Form1.PanelBack.Height div 2 ) - (Form1.PanelCountryTeam.height div 2 );
  Form1.PanelMain.Left := (Form1.PanelBack.Width div 2 ) - (Form1.PanelMain.Width div 2 );
  Form1.PanelMain.Top := (Form1.PanelBack.Height div 2 ) - (Form1.PanelMain.height div 2 );
  Form1.PanelLogin.Left := (Form1.PanelBack.Width div 2 ) - (Form1.PanelLogin.Width div 2 );
  Form1.PanelLogin.Top := (Form1.PanelBack.Height div 2 ) - (Form1.PanelLogin.height div 2 );
  Form1.PanelError.left := (Form1.PanelBack.Width div 2 ) - (Form1.PanelError.Width div 2 );
  Form1.PanelError.Top := (Form1.PanelBack.Height div 2 ) - (Form1.PanelError.height div 2 );
  Form1.PanelListMatches.Left := (Form1.PanelBack.Width div 2 ) - (Form1.PanelListMatches.Width div 2 );
  Form1.PanelListMatches.Top := (Form1.PanelBack.Height div 2 ) - (Form1.PanelListMatches.height div 2 );
  Form1.PanelMarket.Left := (Form1.PanelBack.Width div 2 ) - (Form1.PanelMarket.Width div 2 );
  Form1.PanelMarket.Top := (Form1.PanelBack.Height div 2 ) - (Form1.PanelMarket.height div 2 );

  Form1.PanelScore.Left := (Form1.PanelBack.Width div 2 ) - (Form1.PanelScore.Width div 2 );
  Form1.PanelScore.Top := Form1.SE_Theater1.top - Form1.PanelScore.Height;;
  Form1.PanelSkill.Top := Form1.SE_Theater1.Top + Form1.SE_Theater1.Height ;

  Form1.lbl_maxvalue.left := Form1.edtsearchprice.Left;
  Form1.lbl_maxvalue.width := Form1.edtsearchprice.width;
  Form1.lbl_maxvalue.Top := Form1.edtsearchprice.top - Form1.lbl_maxvalue.height ;
  Form1.lbl_maxvalue.Caption := Translate('lbl_MaxValue');

  Form1.btnxp0.Left := Form1.Portrait0.Left;
  Form1.btnxp0.Top := Form1.Portrait0.top + Form1.Portrait0.Height;
  Form1.btnxp0.Width := Form1.Portrait0.Width;

  Form1.btnsell0.Left:= Form1.Portrait0.Left;
  Form1.btnsell0.Top := Form1.btnxp0.top + Form1.btnxp0.Height;
  Form1.btnsell0.Width := Form1.Portrait0.Width;

  Form1.btnDismiss0.Left := Form1.Portrait0.Left;
  Form1.btnDismiss0.Top := Form1.btnsell0.top + Form1.btnsell0.Height;
  Form1.btnDismiss0.Width := Form1.Portrait0.Width;

  Form1.SE_grid0.Left := Form1.Portrait0.Left + Form1.Portrait0.Width + 4;
  Form1.SE_grid0.Top := Form1.Portrait0.Top;


  Form1.PanelInfoPlayer0.Left := Form1.SE_Theater1.Left - Form1.PanelInfoPlayer0.Width - 2   ;
  Form1.PanelInfoPlayer0.top := Form1.SE_Theater1.top;
 // Form1.PanelInfoPlayer0.Height := Form1.SE_Theater1.Height ;


  // sovrapposto
  Form1.SE_gridXP0.Left := 4 ;
  Form1.SE_gridXP0.Top := 4;

  Form1.PanelXPPlayer0.Left := Form1.PanelInfoPlayer0.Left;
  Form1.PanelXPPlayer0.Height := 340;
  Form1.PanelXPPlayer0.top := Form1.PanelInfoPlayer0.top + Form1.PanelInfoPlayer0.Height;
  Form1.SE_GridXP0.Height := 338;

  Form1.PanelSell.Top := Form1.PanelInfoPlayer0.Top + Form1.PanelInfoPlayer0.height;
  Form1.Panelsell.Left:= Form1.PanelInfoPlayer0.left ;

  Form1.PanelDismiss.Top := Form1.PanelInfoPlayer0.Top + Form1.PanelInfoPlayer0.height;
  Form1.PanelDismiss.Left:= Form1.PanelInfoPlayer0.left ;

  Form1.PanelCombatLog.Left := Form1.SE_Theater1.Left; //PanelSkill.Left + PanelSkill.Width;
  Form1.PanelCombatLog.Top := Form1.se_theater1.top + Form1.se_theater1.height + 3;


  Form1.lbl_Surname0.Caption := '';
  Form1.lbl_Talent01.Caption := '';
  Form1.lbl_descrtalent01.Caption :='';


  Form1.btn_uniformHome.Top := 3;
  Form1.Btn_uniformHome.Left := (Form1.PanelUniform.Width div 2) - (Form1.btn_UniformHome.Width div 2 );
  Form1.Btn_uniformAway.Top := Form1.Btn_uniformHome.Top + Form1.Btn_uniformHome.Height;
  Form1.Btn_uniformAway.Left := (Form1.PanelUniform.Width div 2) - (Form1.btn_UniformAway.Width div 2 );
  Form1.ck_Shorts.Left :=  (Form1.PanelUniform.Width div 2) - (Form1.ck_Shorts.Width div 2 );


  Form1.CnColorGrid1.Left := (Form1.PanelUniform.Width div 2) - (Form1.CnColorGrid1.Width div 2 );
//  Form1.CnColorGrid1.top := Form1.ck_Socks1.Top +  Form1.ck_Socks1.Height + 20;


  if Form1.PanelBack.Background = nil  then Form1.PanelBack.Background := SE_Bitmap.create ( dir_stadium + 'background.bmp');
  Form1.PanelBack.visible := True;


  RoundCornerOf ( Form1.PanelInfoPlayer0 );
  RoundCornerOf ( Form1.PanelXPplayer0 );
  RoundCornerOf ( Form1.PanelScore );
  RoundCornerOf ( Form1.PanelSell );
  RoundCornerOf ( Form1.PanelMain );
  RoundCornerOf ( Form1.PanelCountryTeam );
  RoundCornerOf ( Form1.PanelListMatches );
  RoundCornerOf ( Form1.PanelCorner );
  RoundCornerOf ( Form1.PanelLogin );
  RoundCornerOf ( Form1.Panelformation );
  RoundCornerOf ( Form1.PanelSkill );
  RoundCornerOf ( Form1.PanelUniform );
  RoundCornerOf ( Form1.PanelMarket );
  RoundCornerOf ( Form1.PanelDismiss );
  RoundCornerOf ( Form1.PanelMatchInfo );


end;
procedure ShowStandings;
begin
  Form1.SE_Theater1.Visible := false;
  Form1.PanelLogin.Visible:= true;
  Form1.PanelCountryTeam.Visible := false;
  Form1.PanelMain.Visible:= false;
  Form1.PanelScore.Visible := false;
  Form1.PanelCombatLog.Visible := false;
  Form1.PanelInfoPlayer0.Visible := false;
  Form1.PanelXPPlayer0.Visible := false;
  Form1.PanelCorner.Visible := False;
//  ShowPanelBack;

end;
procedure ShowError ( AString: string);
begin

//  SE_Theater1.Visible := false;
  Form1.lbl_Error.Caption := AString;
  Form1.PanelError.Visible:= true;
  Form1.PanelError.BringToFront;
 // PanelCountryTeam.Visible := false;
 // PanelLogin.Visible:= false;
 // PanelMain.Visible:= false;
 // PanelFormation.Visible:= false;
 // PanelScore.Visible := false;
 // PanelCombatLog.Visible := false;
 // PanelSkill.Visible := false;
 // PanelInfoPlayer.Visible := false;
 // PanelCorner.Visible := False;
//  ShowPanelBack;

end;
procedure ShowLevelUpA ( Guid,value: string );
var
  aPlayer: TSoccerPlayer;
begin
  Form1.GameScreen := ScreenMain;
  aPlayer := MyBrainFormation.GetSoccerPlayer2 ( Guid );

  if value <> '0' then begin
    Form1.lbl_Error.Caption := aPlayer.SurName + ' � appena migliorato!';
    form1.lbl_error.color := clGreen;
    form1.PanelError.Color := clGreen;
  end
  else begin
    Form1.lbl_Error.Caption := 'Purtroppo ' + aPlayer.SurName + ' non � riuscito a migliorare.';
    form1.lbl_error.color := clRed;
    form1.PanelError.Color := clRed;
  end;
  Form1.PanelError.Visible:= true;
  Form1.PanelError.BringToFront;

end;
procedure ShowLevelUpT ( Guid,value: string);
var
  aPlayer: TSoccerPlayer;
begin
  Form1.GameScreen := ScreenMain;
  aPlayer := MyBrainFormation.GetSoccerPlayer2 ( Guid );

  if value <> '0' then begin
    Form1.lbl_Error.Caption := aPlayer.SurName + ' ha nuovi talenti!';
    form1.lbl_error.color := clGreen;
    form1.PanelError.Color := clGreen;
  end
  else begin
    Form1.lbl_Error.Caption := 'Purtroppo ' + aPlayer.SurName + ' non � riuscito a sviluppare il talento.';
    form1.lbl_error.color := clRed;
    form1.PanelError.Color := clRed;
  end;

  Form1.PanelError.Visible:= true;
  Form1.PanelError.BringToFront;

end;

procedure ShowMain;
begin
  FirstLoadOK := False;


  Form1.SE_Theater1.Visible := false;
  Form1.SE_GridMatchInfo.Visible := False;

  Form1.PanelLogin.Visible := false;
  Form1.PanelMain.Visible := true;

  Form1.PanelFormation.Visible := false;

  Form1.PanelListMatches.Visible := false;
  Form1.SE_GridAllBrain.Active := False;
  Form1.PanelError.Visible:= false;
  Form1.PanelCountryTeam.Visible := false;
  Form1.PanelScore.Visible := false;
  Form1.PanelCombatLog.Visible := false;
  Form1.PanelInfoPlayer0.Visible := false;
  Form1.PanelXPPlayer0.Visible := false;
  Form1.PanelSkill.Visible := false;


end;
procedure ShowCornerFreeKickGrid;
begin

  Form1.PanelCombatLog.Visible := False;
  Form1.PanelSkill.Visible := False;
  Form1.PanelCorner.Left := (form1.Width div 2) - (Form1.PanelCorner.Width div 2 ) ;
  Form1.PanelCorner.Top := Form1.SE_Theater1.Top +  Form1.SE_Theater1.Height ;
  Form1.PanelCorner.Visible := True;
  Form1.PanelCorner.BringToFront ;
  Form1.SE_GridFreeKick.CellsEngine.ProcessSprites(20);
  Form1.SE_GridFreeKick.refreshSurface (Form1.SE_GridFreeKick);

end;
procedure ShowFormations;
begin
//  Form1.PanelError.Visible:= false;
  LiveMatch := False;

  Form1.PanelCountryTeam.Visible := false;
  Form1.PanelLogin.Visible:= false;
  Form1.PanelMain.Visible:= false;


  Form1.PanelFormation.Visible := true;
  Form1.PanelFormation.left := Form1.PanelInfoPlayer0.Left;//(Form1.PanelBack.Width div 2 ) - (Form1.PanelFormationSE.Width div 2);
  Form1.PanelFormation.Top :=  Form1.se_Theater1.Top - Form1.PanelFormation.Height ;

  MyBrainFormation.lstSoccerPlayer.clear;  //<-- rimuove gli sprite


  MyBrain:= MyBrainFormation; // <--- assegno MyBrain.



end;
procedure ShowLogin;
begin
  Form1.Panelformation.Visible := False;
  Form1.SE_Theater1.Visible := false;
  Form1.PanelCountryTeam.Visible := false;
  Form1.PanelMain.Visible:= false;
  Form1.PanelScore.Visible := false;
  Form1.PanelCombatLog.Visible := false;
  Form1.PanelInfoPlayer0.Visible := false;
  Form1.PanelXPPlayer0.Visible := false;
  Form1.PanelCorner.Visible := False;
  Form1.PanelListMatches.Visible := false;
  Form1.SE_GridAllBrain.Active := False;
  Form1.PanelMarket.Visible:= False;

  Form1.PanelLogin.Visible := True;
  Form1.SE_GridTime.Active := False;
  Form1.SE_GridTime.Visible:= False;

  Form1.PanelSkill.Visible := False;
  Form1.PanelCombatLog.Visible := False;


end;
procedure ShowScore;
begin
  Form1.SE_Theater1.Visible := true;
  Form1.PanelScore.Visible := True;
  Form1.PanelScore.BringToFront ;
  Form1.PanelCombatLog.Visible := True;
  Form1.PanelCombatLog.BringToFront ;

  Form1.SE_GridTime.Active := True;
  Form1.SE_GridTime.Visible := true;

  Form1.PanelListMatches.Visible := false;
  Form1.PanelCountryTeam.Visible := false;
  Form1.PanelLogin.Visible:= false;
  Form1.PanelMain.Visible:= false;

  Form1.Panel1.Top := 0;
  Form1.Panel1.Visible := True;
  Form1.Panel1.BringToFront;

end;

end.
