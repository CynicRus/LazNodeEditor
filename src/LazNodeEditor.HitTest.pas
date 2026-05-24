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
unit LazNodeEditor.HitTest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Viewport;

type
  THitKind = (htNone, htNode, htPin, htLink, htResizeHandle);

  THitTestResult = record
    HitType: THitKind;
    Node: TCustomNode;
    Pin: TNodePin;
    Link: TNodeLink;
    ResizeNode: TCustomNode;
    WorldPos: TPointF;
    ScreenPos: TPoint;
  end;

  { IHitTestStrategy }

  IHitTestStrategy = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function HitTest(const WorldPos: TPointF; const ScreenPos: TPoint;
      AViewport: TNodeViewport; AGraph: TNodeGraph): THitTestResult;
    function GetPriority: integer;
  end;

  { TBaseHitTestStrategy }

  TBaseHitTestStrategy = class(TInterfacedObject, IHitTestStrategy)
  private
    FPriority: integer;
  public
    constructor Create(APriority: integer);
    function HitTest(const WorldPos: TPointF; const ScreenPos: TPoint;
      AViewport: TNodeViewport; AGraph: TNodeGraph): THitTestResult; virtual; abstract;
    function GetPriority: integer;
  end;

  { TResizeHandleHitTestStrategy }

  TResizeHandleHitTestStrategy = class(TBaseHitTestStrategy)
  private
    FHandleSizeScreen: integer;
  public
    constructor Create(AHandleSizeScreen: integer = 12);
    function HitTest(const WorldPos: TPointF; const ScreenPos: TPoint;
      AViewport: TNodeViewport; AGraph: TNodeGraph): THitTestResult; override;
  end;

  { TPinHitTestStrategy }

  TPinHitTestStrategy = class(TBaseHitTestStrategy)
  public
    constructor Create;
    function HitTest(const WorldPos: TPointF; const ScreenPos: TPoint;
      AViewport: TNodeViewport; AGraph: TNodeGraph): THitTestResult; override;
  end;

  { TLinkHitTestStrategy }

  TLinkHitTestStrategy = class(TBaseHitTestStrategy)
  public
    constructor Create;
    function HitTest(const WorldPos: TPointF; const ScreenPos: TPoint;
      AViewport: TNodeViewport; AGraph: TNodeGraph): THitTestResult; override;
  end;

  { TNodeHitTestStrategy }

  TNodeHitTestStrategy = class(TBaseHitTestStrategy)
  public
    constructor Create;
    function HitTest(const WorldPos: TPointF; const ScreenPos: TPoint;
      AViewport: TNodeViewport; AGraph: TNodeGraph): THitTestResult; override;
  end;

  { THitTestManager }

  THitTestManager = class
  private
    FStrategies: TInterfaceList;
    FViewport: TNodeViewport;
    FGraph: TNodeGraph;
  public
    constructor Create(AGraph: TNodeGraph; AViewport: TNodeViewport);
    destructor Destroy; override;

    function HitTest(ScreenX, ScreenY: integer): THitTestResult;

    function GetNodeUnderMouse(SX, SY: integer): TCustomNode;
    function GetPinUnderMouse(SX, SY: integer; out ANode: TCustomNode;
      out APin: TNodePin): boolean;
    function GetLinkUnderMouse(SX, SY: integer; out ALink: TNodeLink): boolean;
    function GetResizeHandleUnderMouse(SX, SY: integer): TCustomNode;
  end;

{ Geometry helpers }
function CubicBezierPointF(const P0, P1, P2, P3: TPointF; T: single): TPointF;
function DistancePointToSegment(const M, A, B: TPointF): double;
function RectFContains(const R: TRectF; const P: TPointF): boolean; inline;
function RectFIntersects(const R1, R2: TRectF): boolean; inline;

implementation

{ --- Geometry helpers ---------------------------------------------------- }

function CubicBezierPointF(const P0, P1, P2, P3: TPointF; T: single): TPointF;
var
  U, UU, UUU, TT, TTT: single;
begin
  U := 1 - T;
  UU := U * U;
  UUU := UU * U;
  TT := T * T;
  TTT := TT * T;
  Result.X := UUU * P0.X + 3 * UU * T * P1.X + 3 * U * TT * P2.X + TTT * P3.X;
  Result.Y := UUU * P0.Y + 3 * UU * T * P1.Y + 3 * U * TT * P2.Y + TTT * P3.Y;
end;

function DistancePointToSegment(const M, A, B: TPointF): double;
var
  Dx, Dy, T: double;
  LenSq: double;
  PX, PY: double;
begin
  Dx := B.X - A.X;
  Dy := B.Y - A.Y;
  LenSq := Dx * Dx + Dy * Dy;
  if LenSq < 1e-10 then
  begin
    Result := Hypot(M.X - A.X, M.Y - A.Y);
    Exit;
  end;
  T := ((M.X - A.X) * Dx + (M.Y - A.Y) * Dy) / LenSq;
  T := EnsureRange(T, 0, 1);
  PX := A.X + T * Dx;
  PY := A.Y + T * Dy;
  Result := Hypot(M.X - PX, M.Y - PY);
end;

function RectFContains(const R: TRectF; const P: TPointF): boolean;
begin
  Result := (P.X >= R.Left) and (P.X <= R.Right) and (P.Y >= R.Top) and
    (P.Y <= R.Bottom);
end;

function RectFIntersects(const R1, R2: TRectF): boolean;
begin
  Result := not ((R1.Right < R2.Left) or (R1.Left > R2.Right) or
    (R1.Bottom < R2.Top) or (R1.Top > R2.Bottom));
end;

{ --- TBaseHitTestStrategy ------------------------------------------------ }

constructor TBaseHitTestStrategy.Create(APriority: integer);
begin
  inherited Create;
  FPriority := APriority;
end;

function TBaseHitTestStrategy.GetPriority: integer;
begin
  Result := FPriority;
end;

{ --- TResizeHandleHitTestStrategy ---------------------------------------- }

constructor TResizeHandleHitTestStrategy.Create(AHandleSizeScreen: integer);
begin
  inherited Create(30);
  FHandleSizeScreen := AHandleSizeScreen;
end;

function TResizeHandleHitTestStrategy.HitTest(const WorldPos: TPointF;
  const ScreenPos: TPoint; AViewport: TNodeViewport;
  AGraph: TNodeGraph): THitTestResult;
var
  i: integer;
  N: TCustomNode;
  HandleSizeWorld: single;
  NR, HR: TRectF;
begin
  Result.HitType := htNone;
  Result.ResizeNode := nil;

  HandleSizeWorld := FHandleSizeScreen / AViewport.Zoom;

  for i := AGraph.Nodes.Count - 1 downto 0 do
  begin
    N := TCustomNode(AGraph.Nodes[i]);
    if (N = nil) or (N.VisualKind = nvReroute) then
      Continue;

    NR := RectF(N.X, N.Y, N.X + N.Width, N.Y + N.Height);

    HR := RectF(NR.Right - HandleSizeWorld, NR.Bottom - HandleSizeWorld,
      NR.Right + 2 / AViewport.Zoom, NR.Bottom + 2 / AViewport.Zoom);

    if RectFContains(HR, WorldPos) then
    begin
      Result.HitType := htResizeHandle;
      Result.ResizeNode := N;
      Exit;
    end;
  end;
end;

{ --- TPinHitTestStrategy ------------------------------------------------- }

constructor TPinHitTestStrategy.Create;
begin
  inherited Create(20);
end;

function TPinHitTestStrategy.HitTest(const WorldPos: TPointF;
  const ScreenPos: TPoint; AViewport: TNodeViewport;
  AGraph: TNodeGraph): THitTestResult;
var
  i, j: integer;
  N: TCustomNode;
  P: TNodePin;
  PW: TPointF;
  HitRadiusWorld: single;
  BestPrio, Prio: integer;
begin
  Result.HitType := htNone;
  Result.Pin := nil;
  Result.Node := nil;
  BestPrio := -1;

  for i := AGraph.Nodes.Count - 1 downto 0 do
  begin
    N := TCustomNode(AGraph.Nodes[i]);
    if (N = nil) or (N.VisualKind = nvComment) then
      Continue;

    Prio := Ord(N.Selected);
    if Prio <= BestPrio then
      Continue;

    if N.VisualKind = nvReroute then
      HitRadiusWorld := 9 / AViewport.Zoom
    else
      HitRadiusWorld := 10 / AViewport.Zoom;

    for j := 0 to N.InputCount - 1 do
    begin
      P := N.GetInput(j);
      if (P = nil) or P.Hidden then Continue;
      PW := AViewport.GetPinWorldPosition(P);
      if Hypot(WorldPos.X - PW.X, WorldPos.Y - PW.Y) <= HitRadiusWorld then
      begin
        BestPrio := Prio;
        Result.Pin := P;
        Result.Node := N;
        Result.HitType := htPin;
        if BestPrio = 1 then Exit;
      end;
    end;

    for j := 0 to N.OutputCount - 1 do
    begin
      P := N.GetOutput(j);
      if (P = nil) or P.Hidden then Continue;
      PW := AViewport.GetPinWorldPosition(P);
      if Hypot(WorldPos.X - PW.X, WorldPos.Y - PW.Y) <= HitRadiusWorld then
      begin
        BestPrio := Prio;
        Result.Pin := P;
        Result.Node := N;
        Result.HitType := htPin;
        if BestPrio = 1 then Exit;
      end;
    end;
  end;
end;

{ --- TLinkHitTestStrategy ------------------------------------------------ }

constructor TLinkHitTestStrategy.Create;
begin
  inherited Create(15);
end;

function TLinkHitTestStrategy.HitTest(const WorldPos: TPointF;
  const ScreenPos: TPoint; AViewport: TNodeViewport;
  AGraph: TNodeGraph): THitTestResult;
var
  i, k: integer;
  L: TNodeLink;
  P0, P1, P2, P3: TPointF;
  Prev, Cur: TPointF;
  Dist, TolWorld: double;
  MinX, MaxX, MinY, MaxY: single;
begin
  Result.HitType := htNone;
  Result.Link := nil;

  TolWorld := 8 / AViewport.Zoom;

  for i := AGraph.Links.Count - 1 downto 0 do
  begin
    L := TNodeLink(AGraph.Links[i]);
    if (L = nil) or (L.FromPin = nil) or (L.ToPin = nil) then Continue;
    if (L.FromPin.OwnerNode = nil) or (L.ToPin.OwnerNode = nil) then Continue;


    AViewport.GetLinkBezierWorldPoints(L, P0, P1, P2, P3);


    MinX := Min(Min(P0.X, P1.X), Min(P2.X, P3.X)) - TolWorld;
    MaxX := Max(Max(P0.X, P1.X), Max(P2.X, P3.X)) + TolWorld;
    MinY := Min(Min(P0.Y, P1.Y), Min(P2.Y, P3.Y)) - TolWorld;
    MaxY := Max(Max(P0.Y, P1.Y), Max(P2.Y, P3.Y)) + TolWorld;

    if (WorldPos.X < MinX) or (WorldPos.X > MaxX) or (WorldPos.Y < MinY) or
      (WorldPos.Y > MaxY) then
      Continue;

    Prev := P0;
    for k := 1 to 20 do
    begin
      Cur := CubicBezierPointF(P0, P1, P2, P3, k / 20);
      Dist := DistancePointToSegment(WorldPos, Prev, Cur);
      if Dist <= TolWorld then
      begin
        Result.Link := L;
        Result.HitType := htLink;
        Exit;
      end;
      Prev := Cur;
    end;
  end;
end;

{ --- TNodeHitTestStrategy ------------------------------------------------ }

constructor TNodeHitTestStrategy.Create;
begin
  inherited Create(10);
end;

function TNodeHitTestStrategy.HitTest(const WorldPos: TPointF;
  const ScreenPos: TPoint; AViewport: TNodeViewport;
  AGraph: TNodeGraph): THitTestResult;
var
  i: integer;
  N: TCustomNode;
  BestPrio, Prio: integer;
begin
  Result.HitType := htNone;
  Result.Node := nil;
  BestPrio := -1;

  for i := AGraph.Nodes.Count - 1 downto 0 do
  begin
    N := TCustomNode(AGraph.Nodes[i]);
    if (N = nil) or not N.HitTest(WorldPos.X, WorldPos.Y) then Continue;

    Prio := Ord(N.VisualKind <> nvComment) * 2 + Ord(N.Selected);
    if Prio > BestPrio then
    begin
      BestPrio := Prio;
      Result.Node := N;
      Result.HitType := htNode;
      if BestPrio = 3 then Break;
    end;
  end;
end;

{ --- THitTestManager ----------------------------------------------------- }

constructor THitTestManager.Create(AGraph: TNodeGraph; AViewport: TNodeViewport);
begin
  inherited Create;
  FGraph := AGraph;
  FViewport := AViewport;
  FStrategies := TInterfaceList.Create;

  FStrategies.Add(TResizeHandleHitTestStrategy.Create);
  FStrategies.Add(TPinHitTestStrategy.Create);
  FStrategies.Add(TLinkHitTestStrategy.Create);
  FStrategies.Add(TNodeHitTestStrategy.Create);
end;

destructor THitTestManager.Destroy;
begin
  FStrategies.Free;
  inherited Destroy;
end;

function THitTestManager.HitTest(ScreenX, ScreenY: integer): THitTestResult;
var
  i: integer;
  Strategy: IHitTestStrategy;
  WorldPos: TPointF;
  CurResult: THitTestResult;
  BestPriority: integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.HitType := htNone;

  if (FGraph = nil) or (FViewport = nil) then Exit;

  WorldPos := FViewport.ScreenToWorld(ScreenX, ScreenY);
  BestPriority := -1;

  for i := 0 to FStrategies.Count - 1 do
  begin
    Strategy := FStrategies[i] as IHitTestStrategy;
    CurResult := Strategy.HitTest(WorldPos, Point(ScreenX, ScreenY),
      FViewport, FGraph);

    if (CurResult.HitType <> htNone) and (Strategy.GetPriority > BestPriority) then
    begin
      Result := CurResult;
      BestPriority := Strategy.GetPriority;
    end;
  end;

  Result.WorldPos := WorldPos;
  Result.ScreenPos := Point(ScreenX, ScreenY);
end;

function THitTestManager.GetNodeUnderMouse(SX, SY: integer): TCustomNode;
var
  R: THitTestResult;
begin
  R := HitTest(SX, SY);
  if R.HitType = htNode then Result := R.Node
  else
    Result := nil;
end;

function THitTestManager.GetPinUnderMouse(SX, SY: integer; out ANode: TCustomNode;
  out APin: TNodePin): boolean;
var
  R: THitTestResult;
begin
  R := HitTest(SX, SY);
  Result := R.HitType = htPin;
  if Result then
  begin
    ANode := R.Node;
    APin := R.Pin;
  end
  else
  begin
    ANode := nil;
    APin := nil;
  end;
end;

function THitTestManager.GetLinkUnderMouse(SX, SY: integer;
  out ALink: TNodeLink): boolean;
var
  R: THitTestResult;
begin
  R := HitTest(SX, SY);
  Result := R.HitType = htLink;
  if Result then ALink := R.Link
  else
    ALink := nil;
end;

function THitTestManager.GetResizeHandleUnderMouse(SX, SY: integer): TCustomNode;
var
  R: THitTestResult;
begin
  R := HitTest(SX, SY);
  if R.HitType = htResizeHandle then Result := R.ResizeNode
  else
    Result := nil;
end;

end.
