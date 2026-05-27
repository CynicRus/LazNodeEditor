{
  Copyright (c) 2026 Aleksandr Vorobev aka CynicRus (CynicRus@gmail.com)

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
}
unit LazNodeEditor.LinkRouter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Graphics,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.GraphIntf;

type
  TLinkPathKind = (lpkPolyline, lpkBezier);

  TLinkPath = record
    Kind: TLinkPathKind;
    Points: TPointFArray;
  end;

  TSingleArray = array of single;

  TLinkPathCacheEntry = record
    LinkID: Pointer;
    Serial: cardinal;
    Path: TLinkPath;
  end;

  TNodeLinkRouter = class
  private
    FGraph: INodeGraphView;
    FCache: array of TLinkPathCacheEntry;
    FCacheCount: integer;
    FSerial: cardinal;
    function SideNormal(ASide: TPinSide): TPointF; inline;
    function GetPinWorldPos(APin: TNodePin): TPointF;
    function GetNodeBounds(ANode: TCustomNode): TRectF;
    function ExpandRect(const R: TRectF; D: single): TRectF; inline;
    function PointInRectF(const P: TPointF; const R: TRectF): boolean; inline;
    function RectIntersectsRectF(const A, B: TRectF): boolean; inline;
    function SegToRectIntersect(const A, B: TPointF; const R: TRectF): boolean;
    function IsAxisCompatibleToSide(const A, B: TPointF; ASide: TPinSide): boolean;
    function CanConnectToEndStub(const Prev, EndStub: TPointF; EndSide: TPinSide;
      const Ig1, Ig2: TCustomNode; Margin: single): boolean;

    function SegmentBlockedByNodes(const A, B: TPointF; const Ig1, Ig2: TCustomNode;
      Margin: single): boolean;

    function SegmentBlockedByNodesEx(const A, B: TPointF; const Ig1, Ig2: TCustomNode;
      Margin: single; IgnoreComments: boolean = True): boolean;

    function BuildBezierPath(ALink: TNodeLink): TLinkPath;
    function BuildBezierTempPath(AFromPin: TNodePin; const AToWorld: TPointF): TLinkPath;

    function BuildOrthogonalPath(ALink: TNodeLink): TLinkPath;
    function BuildOrthogonalTempPath(AFromPin: TNodePin;
      const AToWorld: TPointF): TLinkPath;

    function BuildStraightPath(ALink: TNodeLink): TLinkPath;
    function BuildStraightTempPath(AFromPin: TNodePin; const AToWorld: TPointF): TLinkPath;

    function OrthoRoute(const P0, P3: TPointF; Side0, Side3: TPinSide;
      const Ig1, Ig2: TCustomNode; Margin: single): TLinkPath;

    function CompressPolyline(const Pts: TPointFArray): TPointFArray;

    function PointHitsPolyline(const P: TPointF; const Pts: TPointFArray;
      Tol: single): boolean;
    function PolylineIntersectsRect(const Pts: TPointFArray; const R: TRectF): boolean;

    function GetLinkStyle(ALink: TNodeLink): TLinkDrawStyle;

    function FindCache(ALink: TNodeLink): integer;
    function GetOrBuildPath(ALink: TNodeLink): TLinkPath;

  public
    constructor Create(const AGraph: INodeGraphView);
    procedure InvalidateCache;

    function BuildLinkPath(ALink: TNodeLink): TLinkPath;
    function BuildTempPath(AFromPin: TNodePin; const AToWorld: TPointF): TLinkPath;
    function GetPaintPath(ALink: TNodeLink): TLinkPath;

    function HitTest(ALink: TNodeLink; const WorldPos: TPointF;
      ToleranceWorld: single = 8): boolean;
    function IsInsideRect(ALink: TNodeLink; const R: TRectF): boolean;

    procedure Paint(Canvas: TCanvas; ALink: TNodeLink; const AState: TNodeRenderState;
      ASelected, AHovered: boolean);

    procedure PaintTemporary(Canvas: TCanvas; AFromPin: TNodePin;
      const AToScreen: TPoint; Zoom, OffsetX, OffsetY: double);

    procedure GetLinkScreenGeometry(ALink: TNodeLink; Zoom, OffsetX, OffsetY: double;
      out P0, P1, P2, P3: TPoint);

  end;

implementation

function WorldToScreenPoint(const P: TPointF;
  Zoom, OffsetX, OffsetY: double): TPoint; inline;
begin
  Result.X := Round(P.X * Zoom + OffsetX);
  Result.Y := Round(P.Y * Zoom + OffsetY);
end;

function DistPtSeg(const P, A, B: TPointF): single;
var
  ABx, ABy, t: single;
begin
  ABx := B.X - A.X;
  ABy := B.Y - A.Y;
  if (Abs(ABx) < 1e-6) and (Abs(ABy) < 1e-6) then
    Exit(Hypot(P.X - A.X, P.Y - A.Y));
  t := ((P.X - A.X) * ABx + (P.Y - A.Y) * ABy) / (ABx * ABx + ABy * ABy);
  t := EnsureRange(t, 0, 1);
  Result := Hypot(P.X - (A.X + t * ABx), P.Y - (A.Y + t * ABy));
end;

function SameCoord(A, B: single): boolean; inline;
begin
  Result := Abs(A - B) < 0.5;
end;

constructor TNodeLinkRouter.Create(const AGraph: INodeGraphView);
begin
  inherited Create;
  FGraph := AGraph;
  FCacheCount := 0;
  FSerial := 1;
end;

procedure TNodeLinkRouter.InvalidateCache;
begin
  Inc(FSerial);
  FCacheCount := 0;
end;

function TNodeLinkRouter.SideNormal(ASide: TPinSide): TPointF;
begin
  case ASide of
    psLeft: Result := PointF(-1, 0);
    psRight: Result := PointF(1, 0);
    psTop: Result := PointF(0, -1);
    psBottom: Result := PointF(0, 1);
    else
      Result := PointF(1, 0);
  end;
end;

function TNodeLinkRouter.GetPinWorldPos(APin: TNodePin): TPointF;
begin
  if (APin <> nil) and (APin.OwnerNode is TCustomNode) then
    Result := TCustomNode(APin.OwnerNode).GetPinWorldPosition(APin)
  else
    Result := PointF(0, 0);
end;

function TNodeLinkRouter.GetNodeBounds(ANode: TCustomNode): TRectF;
begin
  if ANode = nil then
    Result := RectF(0, 0, 0, 0)
  else
    Result := RectF(ANode.X, ANode.Y, ANode.X + ANode.Width, ANode.Y +
      ANode.Height);
end;

function TNodeLinkRouter.ExpandRect(const R: TRectF; D: single): TRectF;
begin
  Result := RectF(R.Left - D, R.Top - D, R.Right + D, R.Bottom + D);
end;

function TNodeLinkRouter.PointInRectF(const P: TPointF; const R: TRectF): boolean;
begin
  Result := (P.X >= R.Left) and (P.X <= R.Right) and (P.Y >= R.Top) and
    (P.Y <= R.Bottom);
end;

function TNodeLinkRouter.RectIntersectsRectF(const A, B: TRectF): boolean;
begin
  Result := not ((A.Right < B.Left) or (A.Left > B.Right) or
    (A.Bottom < B.Top) or (A.Top > B.Bottom));
end;

function TNodeLinkRouter.SegToRectIntersect(const A, B: TPointF;
  const R: TRectF): boolean;
const
  LEFT = 1;
  RIGHT = 2;
  BOTTOM = 4;
  TOP = 8;

  function Code(const P: TPointF): integer;
  begin
    Result := 0;
    if P.X < R.Left then Result := Result or LEFT;
    if P.X > R.Right then Result := Result or RIGHT;
    if P.Y < R.Top then Result := Result or TOP;
    if P.Y > R.Bottom then Result := Result or BOTTOM;
  end;

var
  C1, C2: integer;
  ax, ay, bx, by, x, y: single;
begin
  C1 := Code(A);
  C2 := Code(B);
  ax := A.X;
  ay := A.Y;
  bx := B.X;
  by := B.Y;
  repeat
    if (C1 and C2) <> 0 then Exit(False);
    if (C1 or C2) = 0 then Exit(True);
    if C1 = 0 then
    begin
      x := ax;
      ax := bx;
      bx := x;
      y := ay;
      ay := by;
      by := y;
      x := C1;
      C1 := C2;
      C2 := Round(x);
    end;
    if (C1 and LEFT) <> 0 then
    begin
      y := ay + (by - ay) * (R.Left - ax) / (bx - ax);
      x := R.Left;
    end
    else if (C1 and RIGHT) <> 0 then
    begin
      y := ay + (by - ay) * (R.Right - ax) / (bx - ax);
      x := R.Right;
    end
    else if (C1 and TOP) <> 0 then
    begin
      x := ax + (bx - ax) * (R.Top - ay) / (by - ay);
      y := R.Top;
    end
    else
    begin
      x := ax + (bx - ax) * (R.Bottom - ay) / (by - ay);
      y := R.Bottom;
    end;
    ax := x;
    ay := y;
    C1 := Code(PointF(ax, ay));
  until False;
end;

function TNodeLinkRouter.IsAxisCompatibleToSide(const A, B: TPointF;
  ASide: TPinSide): boolean;
begin
  case ASide of
    psLeft, psRight:
      Result := SameCoord(A.Y, B.Y);
    psTop, psBottom:
      Result := SameCoord(A.X, B.X);
    else
      Result := False;
  end;
end;

function TNodeLinkRouter.CanConnectToEndStub(const Prev, EndStub: TPointF;
  EndSide: TPinSide; const Ig1, Ig2: TCustomNode; Margin: single): boolean;
begin
  Result :=
    IsAxisCompatibleToSide(Prev, EndStub, EndSide) and not
    SegmentBlockedByNodes(Prev, EndStub, Ig1, Ig2, Margin);
end;

function TNodeLinkRouter.SegmentBlockedByNodes(const A, B: TPointF;
  const Ig1, Ig2: TCustomNode; Margin: single): boolean;
begin
  Result := SegmentBlockedByNodesEx(A, B, Ig1, Ig2, Margin, True);
end;

function TNodeLinkRouter.SegmentBlockedByNodesEx(const A, B: TPointF;
  const Ig1, Ig2: TCustomNode; Margin: single; IgnoreComments: boolean): boolean;
var
  i: integer;
  N: TCustomNode;
begin
  Result := False;
  if FGraph = nil then Exit;

  for i := 0 to FGraph.NodeCount - 1 do
  begin
    N := FGraph.Nodes[i];
    if N = nil then
      Continue;

    if (N = Ig1) or (N = Ig2) then
      Continue;

    if IgnoreComments and (N.VisualKind = nvComment) then
      Continue;

    if SegToRectIntersect(A, B, ExpandRect(GetNodeBounds(N), Margin)) then
      Exit(True);

  end;
end;

function TNodeLinkRouter.BuildBezierPath(ALink: TNodeLink): TLinkPath;
var
  P0, P1, P2, P3, V0, V1: TPointF;
  Dist, D: single;
begin
  Result.Kind := lpkBezier;
  SetLength(Result.Points, 4);
  P0 := GetPinWorldPos(ALink.FromPin);
  P3 := GetPinWorldPos(ALink.ToPin);
  Dist := Hypot(P3.X - P0.X, P3.Y - P0.Y);
  D := EnsureRange(Dist * 0.35, 30, 160);
  V0 := SideNormal(ALink.FromPin.Side);
  V1 := SideNormal(ALink.ToPin.Side);
  P1 := PointF(P0.X + V0.X * D, P0.Y + V0.Y * D);
  P2 := PointF(P3.X + V1.X * D, P3.Y + V1.Y * D);
  Result.Points[0] := P0;
  Result.Points[1] := P1;
  Result.Points[2] := P2;
  Result.Points[3] := P3;
end;

function TNodeLinkRouter.BuildBezierTempPath(AFromPin: TNodePin;
  const AToWorld: TPointF): TLinkPath;
var
  P0, P1, P2, P3, V0, V1: TPointF;
  Dist, D: single;
begin
  Result.Kind := lpkBezier;
  SetLength(Result.Points, 4);
  P0 := GetPinWorldPos(AFromPin);
  P3 := AToWorld;
  Dist := Hypot(P3.X - P0.X, P3.Y - P0.Y);
  D := EnsureRange(Dist * 0.35, 30, 160);
  V0 := SideNormal(AFromPin.Side);
  V1 := PointF(-V0.X, -V0.Y);
  P1 := PointF(P0.X + V0.X * D, P0.Y + V0.Y * D);
  P2 := PointF(P3.X + V1.X * D, P3.Y + V1.Y * D);
  Result.Points[0] := P0;
  Result.Points[1] := P1;
  Result.Points[2] := P2;
  Result.Points[3] := P3;
end;

function TNodeLinkRouter.BuildStraightPath(ALink: TNodeLink): TLinkPath;
var
  P0, P3, E0, E3, V0, V1: TPointF;
  Lead: single;
begin
  Result.Kind := lpkPolyline;
  P0 := GetPinWorldPos(ALink.FromPin);
  P3 := GetPinWorldPos(ALink.ToPin);
  V0 := SideNormal(ALink.FromPin.Side);
  V1 := SideNormal(ALink.ToPin.Side);
  Lead := 20;
  E0 := PointF(P0.X + V0.X * Lead, P0.Y + V0.Y * Lead);
  E3 := PointF(P3.X + V1.X * Lead, P3.Y + V1.Y * Lead);
  SetLength(Result.Points, 4);
  Result.Points[0] := P0;
  Result.Points[1] := E0;
  Result.Points[2] := E3;
  Result.Points[3] := P3;
  Result.Points := CompressPolyline(Result.Points);
end;

function TNodeLinkRouter.BuildStraightTempPath(AFromPin: TNodePin;
  const AToWorld: TPointF): TLinkPath;
var
  P0, E0, V0: TPointF;
  Lead: single;
begin
  Result.Kind := lpkPolyline;
  P0 := GetPinWorldPos(AFromPin);
  V0 := SideNormal(AFromPin.Side);
  Lead := 20;
  E0 := PointF(P0.X + V0.X * Lead, P0.Y + V0.Y * Lead);
  SetLength(Result.Points, 3);
  Result.Points[0] := P0;
  Result.Points[1] := E0;
  Result.Points[2] := AToWorld;
end;

function TNodeLinkRouter.CompressPolyline(const Pts: TPointFArray): TPointFArray;
var
  i, N: integer;
  Prev, Cur, Next: TPointF;
begin
  SetLength(Result, 0);
  N := Length(Pts);
  if N = 0 then Exit;
  SetLength(Result, 1);
  Result[0] := Pts[0];
  for i := 1 to N - 2 do
  begin
    Prev := Result[High(Result)];
    Cur := Pts[i];
    Next := Pts[i + 1];
    if (SameCoord(Prev.X, Cur.X) and SameCoord(Cur.X, Next.X)) or
      (SameCoord(Prev.Y, Cur.Y) and SameCoord(Cur.Y, Next.Y)) then
      Continue;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Cur;
  end;
  if N > 1 then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Pts[N - 1];
  end;
end;

function MakePoly(const Arr: array of TPointF): TPointFArray;
var
  i: integer;
begin
  SetLength(Result, Length(Arr));
  for i := 0 to High(Arr) do Result[i] := Arr[i];
end;

function TNodeLinkRouter.OrthoRoute(const P0, P3: TPointF; Side0, Side3: TPinSide;
  const Ig1, Ig2: TCustomNode; Margin: single): TLinkPath;
var
  V0, V3: TPointF;
  Lead: single;
  E0, E3: TPointF;
  K1, K2: TPointF;
  B1, B2, BCombined: TRectF;
  BX1, BY1, BX2, BY2: single;
  MidX, MidY: single;
  i: integer;
  Corners: array[0..3] of TPointF;
  ci, cj: integer;
  C1, C2, C3, C4: TPointF;

  procedure Emit(const Arr: array of TPointF);
  begin
    Result.Kind := lpkPolyline;
    Result.Points := CompressPolyline(MakePoly(Arr));
  end;

  function SegFreeAll(const A, B: TPointF): boolean;
  begin
    Result := not SegmentBlockedByNodesEx(A, B, nil, nil, Margin);
  end;

  function SegFreeFromStub(const A, B: TPointF): boolean;
  begin
    Result := not SegmentBlockedByNodesEx(A, B, Ig1, nil, Margin);
  end;

  function SegFreeToStub(const A, B: TPointF): boolean;
  begin
    Result := not SegmentBlockedByNodesEx(A, B, nil, Ig2, Margin);
  end;

  function RouteSegmentFree(const A, B: TPointF): boolean;
  begin
    Result := SegFreeAll(A, B);
  end;

  function RouteValid5(const aK1, aK2: TPointF): boolean;
  begin
    Result :=
      SegFreeFromStub(P0, E0) and SegFreeAll(E0, aK1) and
      SegFreeAll(aK1, aK2) and SegFreeAll(aK2, E3) and SegFreeToStub(E3, P3) and
      IsAxisCompatibleToSide(aK2, E3, Side3);
  end;

  function RouteValid3(const aK1: TPointF): boolean;
  begin
    Result :=
      (SegFreeFromStub(P0, E0) and SegFreeAll(E0, aK1) and
      SegFreeAll(aK1, E3) and SegFreeToStub(E3, P3) and
      IsAxisCompatibleToSide(E0, aK1, Side0)) or
      (SegFreeFromStub(P0, E0) and SegFreeAll(E0, aK1) and
      SegFreeAll(aK1, E3) and SegFreeToStub(E3, P3) and
      IsAxisCompatibleToSide(aK1, E3, Side3));
  end;

begin
  Result.Kind := lpkPolyline;
  SetLength(Result.Points, 0);

  V0 := SideNormal(Side0);
  V3 := SideNormal(Side3);
  Lead := 28;

  E0 := PointF(P0.X + V0.X * Lead, P0.Y + V0.Y * Lead);
  E3 := PointF(P3.X + V3.X * Lead, P3.Y + V3.Y * Lead);

  K1 := PointF(E3.X, E0.Y);
  if SegFreeFromStub(P0, E0) and SegFreeAll(E0, K1) and SegFreeAll(K1, E3) and
    SegFreeToStub(E3, P3) then
  begin
    Emit([P0, E0, K1, E3, P3]);
    Exit;
  end;

  K1 := PointF(E0.X, E3.Y);
  if SegFreeFromStub(P0, E0) and SegFreeAll(E0, K1) and SegFreeAll(K1, E3) and
    SegFreeToStub(E3, P3) then
  begin
    Emit([P0, E0, K1, E3, P3]);
    Exit;
  end;

  MidX := (E0.X + E3.X) * 0.5;
  K1 := PointF(MidX, E0.Y);
  K2 := PointF(MidX, E3.Y);
  if RouteValid5(K1, K2) then
  begin
    Emit([P0, E0, K1, K2, E3, P3]);
    Exit;
  end;

  MidY := (E0.Y + E3.Y) * 0.5;
  K1 := PointF(E0.X, MidY);
  K2 := PointF(E3.X, MidY);
  if RouteValid5(K1, K2) then
  begin
    Emit([P0, E0, K1, K2, E3, P3]);
    Exit;
  end;

  if (Ig1 <> nil) and (Ig2 <> nil) then
  begin
    B1 := ExpandRect(GetNodeBounds(Ig1), Margin + 16);
    B2 := ExpandRect(GetNodeBounds(Ig2), Margin + 16);
  end
  else if Ig1 <> nil then
  begin
    B1 := ExpandRect(GetNodeBounds(Ig1), Margin + 16);
    B2 := B1;
  end
  else if Ig2 <> nil then
  begin
    B1 := ExpandRect(GetNodeBounds(Ig2), Margin + 16);
    B2 := B1;
  end
  else
  begin
    B1 := RectF(Min(P0.X, P3.X) - 20, Min(P0.Y, P3.Y) - 20,
      Max(P0.X, P3.X) + 20, Max(P0.Y, P3.Y) + 20);
    B2 := B1;
  end;

  BX1 := Min(Min(B1.Left, B2.Left), Min(E0.X, E3.X)) - 24;
  BY1 := Min(Min(B1.Top, B2.Top), Min(E0.Y, E3.Y)) - 24;
  BX2 := Max(Max(B1.Right, B2.Right), Max(E0.X, E3.X)) + 24;
  BY2 := Max(Max(B1.Bottom, B2.Bottom), Max(E0.Y, E3.Y)) + 24;

  for i := 0 to 3 do
  begin
    case i of
      0: begin
        K1 := PointF(BX1, E0.Y);
        K2 := PointF(BX1, E3.Y);
      end;
      1: begin
        K1 := PointF(BX2, E0.Y);
        K2 := PointF(BX2, E3.Y);
      end;
      2: begin
        K1 := PointF(E0.X, BY1);
        K2 := PointF(E3.X, BY1);
      end;
      3: begin
        K1 := PointF(E0.X, BY2);
        K2 := PointF(E3.X, BY2);
      end;
    end;
    if RouteValid5(K1, K2) then
    begin
      Emit([P0, E0, K1, K2, E3, P3]);
      Exit;
    end;

  end;

  begin
    Corners[0] := PointF(BX1, BY1);
    Corners[1] := PointF(BX2, BY1);
    Corners[2] := PointF(BX1, BY2);
    Corners[3] := PointF(BX2, BY2);
    for ci := 0 to 3 do
    begin
      C1 := Corners[ci];
      C2 := PointF(C1.X, E0.Y);
      C3 := PointF(C1.X, E3.Y);
      if SegFreeFromStub(P0, E0) and SegFreeAll(E0, C2) and SegFreeAll(C2, C3) and
        SegFreeAll(C3, E3) and SegFreeToStub(E3, P3) then
      begin
        Emit([P0, E0, C2, C3, E3, P3]);
        Exit;
      end;

      C2 := PointF(E0.X, C1.Y);
      C3 := PointF(E3.X, C1.Y);
      if SegFreeFromStub(P0, E0) and SegFreeAll(E0, C2) and SegFreeAll(C2, C3) and
        SegFreeAll(C3, E3) and SegFreeToStub(E3, P3) then
      begin
        Emit([P0, E0, C2, C3, E3, P3]);
        Exit;
      end;
    end;

    for ci := 0 to 3 do
      for cj := 0 to 3 do
      begin
        if ci = cj then Continue;
        C1 := PointF(Corners[ci].X, E0.Y);
        C2 := Corners[ci];
        C3 := PointF(Corners[ci].X, Corners[cj].Y);
        C4 := PointF(E3.X, Corners[cj].Y);
        if SegFreeFromStub(P0, E0) and SegFreeAll(E0, C1) and
          SegFreeAll(C1, C2) and SegFreeAll(C2, C3) and SegFreeAll(C3, C4) and
          SegFreeAll(C4, E3) and SegFreeToStub(E3, P3) then
        begin
          Emit([P0, E0, C1, C2, C3, C4, E3, P3]);
          Exit;
        end;
      end;

  end;

  Emit([P0, E0, E3, P3]);
end;

function TNodeLinkRouter.BuildOrthogonalPath(ALink: TNodeLink): TLinkPath;
var
  N0, N1: TCustomNode;
begin
  if (ALink = nil) or (ALink.FromPin = nil) or (ALink.ToPin = nil) then
  begin
    Result.Kind := lpkPolyline;
    SetLength(Result.Points, 0);
    Exit;
  end;
  N0 := TCustomNode(ALink.FromPin.OwnerNode);
  N1 := TCustomNode(ALink.ToPin.OwnerNode);
  Result := OrthoRoute(GetPinWorldPos(ALink.FromPin), GetPinWorldPos(ALink.ToPin),
    ALink.FromPin.Side, ALink.ToPin.Side, N0, N1, 10);
end;

function TNodeLinkRouter.BuildOrthogonalTempPath(AFromPin: TNodePin;
  const AToWorld: TPointF): TLinkPath;
var
  P0, E0, V0: TPointF;
  Lead: single;
  DstSide: TPinSide;
begin
  Result.Kind := lpkPolyline;
  P0 := GetPinWorldPos(AFromPin);
  V0 := SideNormal(AFromPin.Side);
  Lead := 28;
  E0 := PointF(P0.X + V0.X * Lead, P0.Y + V0.Y * Lead);

  case AFromPin.Side of
    psRight: DstSide := psLeft;
    psLeft: DstSide := psRight;
    psBottom: DstSide := psTop;
    else
      DstSide := psBottom;
  end;

  Result := OrthoRoute(P0, AToWorld, AFromPin.Side, DstSide, nil, nil, 6);
end;

function TNodeLinkRouter.FindCache(ALink: TNodeLink): integer;
var
  i: integer;
begin
  for i := 0 to FCacheCount - 1 do
    if (FCache[i].LinkID = Pointer(ALink)) and (FCache[i].Serial = FSerial) then
      Exit(i);
  Result := -1;
end;

function TNodeLinkRouter.GetOrBuildPath(ALink: TNodeLink): TLinkPath;
var
  Idx: integer;
begin
  Idx := FindCache(ALink);
  if Idx >= 0 then
    Exit(FCache[Idx].Path);

  Result := BuildLinkPath(ALink);

  if FCacheCount >= Length(FCache) then
    SetLength(FCache, Max(16, FCacheCount * 2));
  FCache[FCacheCount].LinkID := Pointer(ALink);
  FCache[FCacheCount].Serial := FSerial;
  FCache[FCacheCount].Path := Result;
  Inc(FCacheCount);
end;

function TNodeLinkRouter.GetLinkStyle(ALink: TNodeLink): TLinkDrawStyle;
begin
  if FGraph <> nil then
    Result := FGraph.DefaultLinkDrawStyle
  else
    Result := ldsBezier;
end;

function TNodeLinkRouter.BuildLinkPath(ALink: TNodeLink): TLinkPath;
begin
  case GetLinkStyle(ALink) of
    ldsStraight: Result := BuildStraightPath(ALink);
    ldsOrthogonal: Result := BuildOrthogonalPath(ALink);
    else
      Result := BuildBezierPath(ALink);
  end;
end;

function TNodeLinkRouter.BuildTempPath(AFromPin: TNodePin;
  const AToWorld: TPointF): TLinkPath;
begin
  if FGraph = nil then
    Exit(BuildBezierTempPath(AFromPin, AToWorld));
  case FGraph.DefaultLinkDrawStyle of
    ldsStraight: Result := BuildStraightTempPath(AFromPin, AToWorld);
    ldsOrthogonal: Result := BuildOrthogonalTempPath(AFromPin, AToWorld);
    else
      Result := BuildBezierTempPath(AFromPin, AToWorld);
  end;
end;

function TNodeLinkRouter.GetPaintPath(ALink: TNodeLink): TLinkPath;
begin
  Result := GetOrBuildPath(ALink);
end;

function TNodeLinkRouter.PointHitsPolyline(const P: TPointF;
  const Pts: TPointFArray; Tol: single): boolean;
var
  i: integer;
begin
  for i := 0 to High(Pts) - 1 do
    if DistPtSeg(P, Pts[i], Pts[i + 1]) <= Tol then
      Exit(True);
  Result := False;
end;

function TNodeLinkRouter.PolylineIntersectsRect(const Pts: TPointFArray;
  const R: TRectF): boolean;
var
  i: integer;
begin
  for i := 0 to High(Pts) do
    if PointInRectF(Pts[i], R) then Exit(True);
  for i := 0 to High(Pts) - 1 do
    if SegToRectIntersect(Pts[i], Pts[i + 1], R) then Exit(True);
  Result := False;
end;

function TNodeLinkRouter.HitTest(ALink: TNodeLink; const WorldPos: TPointF;
  ToleranceWorld: single): boolean;
var
  Path: TLinkPath;
  Prev, Cur: TPointF;
  k: integer;
begin
  Path := GetOrBuildPath(ALink);
  case Path.Kind of
    lpkPolyline:
      Result := PointHitsPolyline(WorldPos, Path.Points, ToleranceWorld);
    lpkBezier:
    begin
      if Length(Path.Points) < 4 then Exit(False);
      Result := False;
      Prev := Path.Points[0];
      for k := 1 to 24 do
      begin
        Cur := CubicBezierPointF(Path.Points[0], Path.Points[1],
          Path.Points[2], Path.Points[3], k / 24);
        if DistPtSeg(WorldPos, Prev, Cur) <= ToleranceWorld then
          Exit(True);
        Prev := Cur;
      end;
    end;
  end;
end;

function TNodeLinkRouter.IsInsideRect(ALink: TNodeLink; const R: TRectF): boolean;
var
  Path: TLinkPath;
  Prev, Cur: TPointF;
  BR: TRectF;
  k: integer;
begin
  Path := GetOrBuildPath(ALink);
  case Path.Kind of
    lpkPolyline:
      Result := PolylineIntersectsRect(Path.Points, R);
    lpkBezier:
    begin
      if Length(Path.Points) < 4 then Exit(False);
      BR := RectF(Min(Min(Path.Points[0].X, Path.Points[1].X),
        Min(Path.Points[2].X, Path.Points[3].X)),
        Min(Min(Path.Points[0].Y, Path.Points[1].Y), Min(
        Path.Points[2].Y, Path.Points[3].Y)),
        Max(Max(Path.Points[0].X, Path.Points[1].X), Max(
        Path.Points[2].X, Path.Points[3].X)),
        Max(Max(Path.Points[0].Y, Path.Points[1].Y), Max(
        Path.Points[2].Y, Path.Points[3].Y)));
      if not RectIntersectsRectF(BR, R) then Exit(False);
      Result := False;
      Prev := Path.Points[0];
      for k := 1 to 24 do
      begin
        Cur := CubicBezierPointF(Path.Points[0], Path.Points[1],
          Path.Points[2], Path.Points[3], k / 24);
        if PointInRectF(Cur, R) or SegToRectIntersect(Prev, Cur, R) then
          Exit(True);
        Prev := Cur;
      end;
    end;
  end;
end;

procedure TNodeLinkRouter.Paint(Canvas: TCanvas; ALink: TNodeLink;
  const AState: TNodeRenderState; ASelected, AHovered: boolean);
var
  Path: TLinkPath;
  C: TColor;
  W: integer;
  i: integer;
  P: TPoint;
begin
  if Canvas = nil then Exit;

  Path := GetOrBuildPath(ALink);

  if ASelected then
  begin
    C := clRed;
    W := 5;
  end
  else if AHovered then
  begin
    C := clAqua;
    W := 5;
  end
  else
  begin
    C := clYellow;
    W := 4;
  end;

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := C;
  Canvas.Pen.Width := Max(1, Round(W * AState.Zoom));

  case Path.Kind of
    lpkPolyline:
      if Length(Path.Points) >= 2 then
      begin
        P := WorldToScreenPoint(Path.Points[0], AState.Zoom, AState.OffsetX,
          AState.OffsetY);
        Canvas.MoveTo(P.X, P.Y);
        for i := 1 to High(Path.Points) do
        begin
          P := WorldToScreenPoint(Path.Points[i], AState.Zoom,
            AState.OffsetX, AState.OffsetY);
          Canvas.LineTo(P.X, P.Y);
        end;
      end;
    lpkBezier:
      if Length(Path.Points) >= 4 then
        DrawCubicBezier(Canvas,
          WorldToScreenPoint(Path.Points[0], AState.Zoom, AState.OffsetX,
          AState.OffsetY),
          WorldToScreenPoint(Path.Points[1], AState.Zoom, AState.OffsetX,
          AState.OffsetY),
          WorldToScreenPoint(Path.Points[2], AState.Zoom, AState.OffsetX,
          AState.OffsetY),
          WorldToScreenPoint(Path.Points[3], AState.Zoom, AState.OffsetX,
          AState.OffsetY),
          24);
  end;

  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Style := bsSolid;
end;

procedure TNodeLinkRouter.PaintTemporary(Canvas: TCanvas; AFromPin: TNodePin;
  const AToScreen: TPoint; Zoom, OffsetX, OffsetY: double);
var
  Path: TLinkPath;
  ToWorld: TPointF;
  i: integer;
  P: TPoint;
begin
  if (Canvas = nil) or (AFromPin = nil) then Exit;

  ToWorld := PointF((AToScreen.X - OffsetX) / Zoom, (AToScreen.Y - OffsetY) / Zoom);
  Path := BuildTempPath(AFromPin, ToWorld);

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psDash;
  Canvas.Pen.Color := clAqua;
  Canvas.Pen.Width := Max(1, Round(3 * Zoom));

  case Path.Kind of
    lpkPolyline:
      if Length(Path.Points) >= 2 then
      begin
        P := WorldToScreenPoint(Path.Points[0], Zoom, OffsetX, OffsetY);
        Canvas.MoveTo(P.X, P.Y);
        for i := 1 to High(Path.Points) do
        begin
          P := WorldToScreenPoint(Path.Points[i], Zoom, OffsetX, OffsetY);
          Canvas.LineTo(P.X, P.Y);
        end;
      end;
    lpkBezier:
      if Length(Path.Points) >= 4 then
        DrawCubicBezier(Canvas,
          WorldToScreenPoint(Path.Points[0], Zoom, OffsetX, OffsetY),
          WorldToScreenPoint(Path.Points[1], Zoom, OffsetX, OffsetY),
          WorldToScreenPoint(Path.Points[2], Zoom, OffsetX, OffsetY),
          WorldToScreenPoint(Path.Points[3], Zoom, OffsetX, OffsetY),
          24);
  end;

  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsSolid;
end;

procedure TNodeLinkRouter.GetLinkScreenGeometry(ALink: TNodeLink;
  Zoom, OffsetX, OffsetY: double; out P0, P1, P2, P3: TPoint);
var
  Path: TLinkPath;
begin
  Path := GetOrBuildPath(ALink);
  P0 := Point(0, 0);
  P1 := Point(0, 0);
  P2 := Point(0, 0);
  P3 := Point(0, 0);

  if Path.Kind = lpkBezier then
  begin
    if Length(Path.Points) >= 4 then
    begin
      P0 := WorldToScreenPoint(Path.Points[0], Zoom, OffsetX, OffsetY);
      P1 := WorldToScreenPoint(Path.Points[1], Zoom, OffsetX, OffsetY);
      P2 := WorldToScreenPoint(Path.Points[2], Zoom, OffsetX, OffsetY);
      P3 := WorldToScreenPoint(Path.Points[3], Zoom, OffsetX, OffsetY);
    end;
  end
  else
  begin
    if Length(Path.Points) >= 2 then
    begin
      P0 := WorldToScreenPoint(Path.Points[0], Zoom, OffsetX, OffsetY);
      P3 := WorldToScreenPoint(Path.Points[High(Path.Points)], Zoom, OffsetX, OffsetY);
      if Length(Path.Points) > 2 then
      begin
        P1 := WorldToScreenPoint(Path.Points[1], Zoom, OffsetX, OffsetY);
        P2 := WorldToScreenPoint(Path.Points[High(Path.Points) - 1],
          Zoom, OffsetX, OffsetY);
      end
      else
      begin
        P1 := P0;
        P2 := P3;
      end;
    end;
  end;
end;

end.
