unit Unit3;
interface
uses Vcl.Graphics, System.Types, System.SysUtils,  generics.collections, generics.defaults,math,iraSearchFiles,vcl.forms;
procedure CreateFormationsPreset;

procedure DeleteDirData;
procedure CreateRewards;

implementation
uses unit1,soccerbrainv3;
FUNCTION PolygonCentroid(CONST Polygon:  TpointArray4; VAR Area:  DOUBLE):  TPoint;

    VAR
      aSum:  DOUBLE;
      i   :  INTEGER;
      j   :  INTEGER;
      Term:  DOUBLE;
      xSum:  DOUBLE;
      ySum:  DOUBLE;
      Polygon2: array[0..4] of TPoint;
  BEGIN
//    IF   High(Polygon) < 3
//    THEN RAISE EPolygonError.Create('PolygonCentroid:  Polygon is degenerate');

    for i := 0 to 3 do begin
      Polygon2[i] := Polygon[i];
    end;
    Polygon2[4] := Polygon[0];

    aSum := 0.0;
    xSum := 0.0;
    ySum := 0.0;
//    FOR i := 0 TO High(Polygon)-1 DO
    FOR i := 0 TO High(Polygon2)-1 DO
    BEGIN
      j := i + 1;
      //Term := Polygon[i].X * Polygon[j].Y  -  Polygon[j].X * Polygon[i].Y;
      //aSum := aSum + Term;
      //xSum := xSum + (Polygon[j].X + Polygon[i].X) * Term;
      //ySum := ySum + (Polygon[j].Y + Polygon[i].Y) * Term
      Term := Polygon2[i].X * Polygon2[j].Y  -  Polygon2[j].X * Polygon2[i].Y;
      aSum := aSum + Term;
      xSum := xSum + (Polygon2[j].X + Polygon2[i].X) * Term;
      ySum := ySum + (Polygon2[j].Y + Polygon2[i].Y) * Term
    END;

    Area := 0.5 * aSum;

  //  TRY
      RESULT.X := Trunc (xSum / (3.0 * aSum));
      RESULT.Y := Trunc (ySum / (3.0 * aSum));
    //EXCEPT
     // ON EZeroDivide DO RAISE EPolygonError.Create('PolygonCentroid:  Zero Area.')
    //END;

  END {PolygonCentroid};

procedure CreateRewards;
begin
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

procedure DeleteDirData;
var
  i: Integer;
  sf : TiraSearchFiles;
begin
  sf :=  TiraSearchFiles.Create(nil);

  sf.MaskInclude.add ('*.is');
  sf.FromPath := dir_data;
  sf.SubDirectories := False;
  sf.Execute ;

  while Sf.SearchState <> ssIdle do begin
    Application.ProcessMessages ;
  end;

  for I := 0 to sf.ListFiles.Count -1 do begin
    if FileExists  ( PChar(Dir_data +  sf.ListFiles[i]))  then
        Deletefile ( PChar(Dir_data + sf.ListFiles[i]));

  end;

  sf.Free;

end;

procedure CreateFormationsPreset;
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






// in futuro per traiettorie della palla ad arco:
(*
procedure TForm1.DrawArc(x1, y1, x2, y2: Integer; AngleBegin, AngleEnd: Single; ArcDirection: TArcDirection; var aPath: dse_pathPlanner.Tpath);
var
  Xc, Yc, Rx, Ry, x, y, s, c: Single;
  AngleCurrent, AngleDiff, AngleStep: Single;
  aStep: TPathStep;
begin
  // check that our box is well set (as the original Arc function do)
  aPath.Clear ;
  if x1 > x2 then
    SwapInteger(@x1, @x2);
  if y1 > y2 then
    SwapInteger(@y1, @y2);

  if (x1 = x2) or (y1 = y2) then
    exit;

  Xc := (x1 + x2) * 0.5;
  Yc := (y1 + y2) * 0.5;

  Rx := Abs(x2 - x1) * 0.5;
  Ry := Abs(y2 - y1) * 0.5;

  // if ClockWise then swap AngleBegin and AngleEnd to simulate it.
  if ArcDirection = adClockWise then
  begin
    AngleCurrent := AngleBegin;
    AngleBegin := AngleEnd;
    AngleEnd := AngleCurrent;
  end;

  if (AngleEnd >= AngleBegin) then
  begin // if end sup to begin, remove 2*Pi (360°)
    AngleEnd := AngleEnd - 2 * Pi;
  end;

  AngleDiff := Abs(AngleEnd - AngleBegin); // the amount radian to travel
  AngleStep := AngleDiff / Round(MaxFloat(Rx, Ry) * 0.1 + 5); // granulity of drawing, not too much, not too less

  AngleCurrent := AngleBegin;

  while AngleCurrent >= AngleBegin - AngleDiff do
  begin
    SinCosine(AngleCurrent, s, c);
    x := Xc + (Rx * c);
    y := Yc + (Ry * s);

    aStep := TPathStep.Create();
    aStep.X := Trunc(X);
    aStep.Y := Trunc(Y);
    aPath.Add(aStep);
//     GL.Vertex2f(x, y);

    AngleCurrent := AngleCurrent - AngleStep; // always step down, rotate only one way to draw it
  end;

  SinCosine(AngleEnd, s, c);
  x := Xc + (Rx * c);
  y := Yc + (Ry * s);

    aStep := TPathStep.Create();
    aStep.X := Trunc(X);
    aStep.Y := Trunc(Y);
    aPath.Add(aStep);
//  GL.Vertex2f(x, y);



end;
procedure TForm1.DrawArc(x1, y1, x2, y2, x3, y3, x4, y4: Single; ArcDirection: TArcDirection);
var
  x, y: Single;
  AngleBegin, AngleEnd: Single;
begin
  if x1 > x2 then
    SwapSingle(@x1, @x2);
  if y1 > y2 then
    SwapSingle(@y1, @y2);

  if x2 - x1 <=0 then Exit;
  if y2 - y1 <=0 then Exit;

  NormalizePoint(x1, y1, x2, y2, x3, y3, @x, @y);
  AngleBegin := ArcTan2(y, x);

  NormalizePoint(x1, y1, x2, y2, x4, y4, @x, @y);
  AngleEnd := ArcTan2(y, x);

//  DrawArc( Trunc(x1), Trunc(y1), Trunc(x2), Trunc(y2), AngleBegin, AngleEnd, ArcDirection ,aPathARC);
end;

procedure SinCosine(const Theta: Extended; out Sin, Cos: Extended); overload;
procedure SinCosine(const Theta: Double; out Sin, Cos: Double); overload;
procedure SinCosine(const Theta: Single; out Sin, Cos: Single); overload;
procedure SinCosine(const Theta, radius: Double; out Sin, Cos: Extended); overload;
procedure SinCosine(const Theta, radius: Double; out Sin, Cos: Double); overload;
procedure SinCosine(const Theta, radius: Single; out Sin, Cos: Single); overload;
function MaxFloat(F1, F2: extended): extended;

procedure SinCosine(const Theta: Extended; out Sin, Cos: Extended);
asm
  FLD  Theta
  FSinCos
  FSTP TBYTE PTR [EDX]    // cosine
  FSTP TBYTE PTR [EAX]    // sine
end;

procedure SinCosine(const Theta: Double; out Sin, Cos: Double);
var
  S, c: Extended;
begin
  SinCos(Theta, S, c);
{$HINTS OFF}
  Sin := S;
  Cos := c;
{$HINTS ON}
end;

procedure SinCosine(const Theta: Single; out Sin, Cos: Single);
var
  S, c: Extended;
begin
  SinCos(Theta, S, c);
//{$HINTS OFF}
  Sin := S;
  Cos := c;
//{$HINTS ON}
end;


procedure SinCosine(const Theta, radius: Double; out Sin, Cos: Extended);
var
  S, c: Extended;
begin
  Math.SinCos(Theta, S, c);
  Sin := S * radius;
  Cos := c * radius;
end;


procedure SinCosine(const Theta, radius: Double; out Sin, Cos: Double);
var
  S, c: Extended;
begin
  SinCos(Theta, S, c);
  Sin := S * radius;
  Cos := c * radius;
end;

procedure SinCosine(const Theta, radius: Single; out Sin, Cos: Single);
var
  S, c: Extended;
begin
  SinCos(Theta, S, c);
  Sin := S * radius;
  Cos := c * radius;
end;
function MaxFloat(F1, F2: extended): extended;
begin
  if F1 > F2 then
    Result := F1
  else
    Result := F2;
end;
*)


(*
procedure TForm1.SwapInteger(pX, pY: PInteger);
var
  tmp: Integer;
begin
  tmp := pX^;
  pX^ := pY^;
  pY^ := tmp;
end;
procedure TForm1.SwapSingle(pX, pY: PSingle);
var
  tmp: Single;
begin
  tmp := pX^;
  pX^ := pY^;
  pY^ := tmp;
end;
procedure TForm1.NormalizePoint(const x1, y1, x2, y2: Single; const x, y: Single; pX, pY: PSingle);
begin
  pX^ := (x - x1) / (x2 - x1) * 2.0 - 1.0;
  pY^ := (y - y1) / (y2 - y1) * 2.0 - 1.0;
end;
*)
end.
