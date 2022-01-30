unit SoccerTypes;

interface
uses dse_pathplanner, system.types ;
type TBetterSolution = ( SubAbs4, subDone, SubCant, TacticDone, StayFreeDone, CleanRowDone,  None );
type TSubType = ( PossiblysameRole, BestShot, bestDefense, bestPassing );
type TAccelerationMode = ( AccBestDistance, AccSelfY, AccDoor );
type TAttributeName = ( atSpeed , atDefense, atBallControl, atPassing, atShot, atHeading);
type TSubOUT = ( DefenderOUT,forwardOUT);


procedure GetLinePoints(X1, Y1, X2, Y2 : Integer; var PathPoints: dse_pathplanner.TPath);
function ReversePointOrder(LinePointList : dse_pathplanner.TPath) : dse_pathplanner.TPath;
function inLinePath ( StartX, StartY, EndX, EndY, Cellx, CellY: integer): boolean;
function DistanceSqr(const X1, Y1, X2, Y2: Integer): Integer;
function AbsDistance( const X1, Y1, X2, Y2: Integer ): Integer;

implementation
function DistanceSqr(const X1, Y1, X2, Y2: Integer): Integer;
begin
     result := Sqr( X2-X1 ) + Sqr( Y2-Y1 );
end;
function AbsDistance( const X1, Y1, X2, Y2: Integer ): Integer;
var
   d1, d2: Integer;
begin
     d1 := abs(x2-x1);
     d2 := abs(y2-y1);
     if d1 < d2 then
        result := d2
     else
         result := d1;
end;
function inLinePath ( StartX, StartY, EndX, EndY, Cellx, CellY: integer): boolean;
var
  aPath: dse_pathplanner.TPath;
  i: integer;
begin
  Result:= False;
  aPath := dse_pathplanner.TPath.Create;
  GetLinePoints ( StartX, StartY, EndX, EndY, aPath );
  for I := 0 to aPath.Count -1 do begin
    if (aPath[i].X = cellX) and (aPath[i].Y = cellY) then begin
      Result := true;
      aPath.Free;
      exit;
    end;
  end;
  aPath.Free;

end;

// ----------------------------------------------------------------------------
// GetLinePoints
// ----------------------------------------------------------------------------
function ReversePointOrder(LinePointList : dse_pathplanner.TPath) : dse_pathplanner.TPath;
var
  NewPointList : dse_pathplanner.TPath;
begin
  NewPointList := dse_pathplanner.TPath.Create;
  NewPointList:=LinePointList;
  NewPointList.Reverse ;
  Result := NewPointList;
end;

procedure GetLinePoints(X1, Y1, X2, Y2 : Integer; var PathPoints: dse_pathplanner.TPath);
var
ChangeInX, ChangeInY, i, MinX, MinY, MaxX, MaxY, LineLength : Integer;
ChangingX : Boolean;
Point : TPoint;
//ReturnList, ReversedList : pathplanner.TPath;
begin
  PathPoints.Clear;
//  ReturnList := pathplanner.TPath.Create;
 // ReversedList := pathplanner.TPath.Create;


  if X1 > X2 then  begin
    ChangeInX := X1 - X2;
    MaxX := X1;
    MinX := X2;
  end
  else begin
    ChangeInX := X2 - X1;
    MaxX := X2;
    MinX := X1;
  end;

  // Get the change in the Y axis and the Max & Min Y values
  if Y1 > Y2 then  begin
    ChangeInY := Y1 - Y2;
    MaxY := Y1;
    MinY := Y2;
  end
  else  begin
    ChangeInY := Y2 - Y1;
    MaxY := Y2;
    MinY := Y1;
  end;

  // Find out which axis has the greatest change
  if ChangeInX > ChangeInY then  begin
    LineLength := ChangeInX;
    ChangingX := True;
  end
  else begin
    LineLength := ChangeInY;
    ChangingX := false;
  end;


  if X1 = X2 then  begin
    for i := MinY to MaxY do begin
      Point.X := X1;
      Point.Y := i;
      PathPoints.Add(Point.X,Point.y);
    end;

    if Y1 > Y2 then  begin
  //  ReversedList := ReversePointOrder(ReturnList);  { ReturnList.reverse e basta }
  // ReturnList := ReversedList;
      PathPoints.reverse;
    end;
  end

  else if Y1 = Y2 then  begin
    for i := MinX to MaxX do begin
      Point.X := i;
      Point.Y := Y1;
      PathPoints.Add(Point.x,Point.Y );
    end;


    if X1 > X2 then begin
//      ReversedList := ReversePointOrder(ReturnList);
//      ReturnList := ReversedList;
      PathPoints.reverse;
    end;
  end
  else begin
    Point.X := X1;
    Point.Y := Y1;
    PathPoints.Add(Point.x,Point.y);

    for i := 1 to (LineLength - 1) do  begin
      if ChangingX then  begin
        Point.y := Round((ChangeInY * i)/ChangeInX);
        Point.x := i;
      end

      else  begin
        Point.y := i;
        Point.x := Round((ChangeInX * i)/ChangeInY);
      end;

      if Y1 < Y2 then  Point.y := Point.Y + Y1
      else   Point.Y := Y1 - Point.Y;

      if X1 < X2 then  Point.X := Point.X + X1
      else   Point.X := X1 - Point.X;

      PathPoints.Add(Point.X,Point.y);
    end;
  // Add the second point to the list.
    Point.X := X2;
    Point.Y := Y2;
    PathPoints.Add(Point.X,Point.y);
  end;
//Result := ReturnList;
end;

end.
