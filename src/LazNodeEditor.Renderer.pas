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
unit LazNodeEditor.Renderer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Graphics,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  GL2DCanvas,
  LazNodeEditor.GLCanvasProxy;

type
  TRendererBackend = (
    rbGDI,
    rbOpenGL2D
    );

  TRenderCanvasKind = (
    rckNone,
    rckGDI,
    rckGL2D
    );

  TRenderNodeDrawEvent = procedure(Sender: TObject; Canvas: TCanvas;
    ANode: TCustomNode; const ARect: TRect; Zoom: double;
    OffsetX, OffsetY: double; var AHandled: boolean) of object;

  TRenderPinDrawEvent = procedure(Sender: TObject; Canvas: TCanvas;
    APin: TNodePin; const ACenter: TPoint; ARadius: integer;
    ASelected, AHovered, AHighlighted: boolean; var AHandled: boolean) of object;

  TRenderLinkDrawEvent = procedure(Sender: TObject; Canvas: TCanvas;
    ALink: TNodeLink; const P0, P1, P2, P3: TPoint; ASelected, AHovered: boolean;
    var AHandled: boolean) of object;

  TRenderGridDrawEvent = procedure(Sender: TObject; Canvas: TCanvas;
    const VisibleWorldRect: TRectF; Zoom, OffsetX, OffsetY: double;
    var AHandled: boolean) of object;

  TRenderSnapGuidesDrawEvent = procedure(Sender: TObject; Canvas: TCanvas;
    GuideSnapXActive, GuideSnapYActive: boolean; GuideSnapX, GuideSnapY: single;
    Zoom, OffsetX, OffsetY: double; var AHandled: boolean) of object;

  TRenderStyle = class(TPersistent)
  private
    FBackgroundColor: TColor;

    FGridVisible: boolean;
    FGridSize: integer;
    FGridColor: TColor;
    FGridStyle: TPenStyle;
    FGridWidth: integer;

    FShowAxes: boolean;
    FAxesColor: TColor;
    FAxesThickness: integer;

    FGuideLineColor: TColor;
    FGuideLineStyle: TPenStyle;
    FGuideLineWidth: integer;

    FBoxSelectColor: TColor;
    FBoxSelectStyle: TPenStyle;
    FBoxSelectWidth: integer;

    FResizeHandleBrushColor: TColor;
    FResizeHandlePenColor: TColor;

    procedure SetDefaults;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
  published
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor;

    property GridVisible: boolean read FGridVisible write FGridVisible default True;
    property GridSize: integer read FGridSize write FGridSize default 40;
    property GridColor: TColor read FGridColor write FGridColor default $00E0E0E0;
    property GridStyle: TPenStyle read FGridStyle write FGridStyle default psSolid;
    property GridWidth: integer read FGridWidth write FGridWidth default 1;

    property ShowAxes: boolean read FShowAxes write FShowAxes default False;
    property AxesColor: TColor read FAxesColor write FAxesColor default clSilver;
    property AxesThickness: integer read FAxesThickness write FAxesThickness default 2;

    property GuideLineColor: TColor
      read FGuideLineColor write FGuideLineColor default clAqua;
    property GuideLineStyle: TPenStyle read FGuideLineStyle
      write FGuideLineStyle default psDash;
    property GuideLineWidth: integer read FGuideLineWidth
      write FGuideLineWidth default 1;

    property BoxSelectColor: TColor
      read FBoxSelectColor write FBoxSelectColor default clBlue;
    property BoxSelectStyle: TPenStyle read FBoxSelectStyle
      write FBoxSelectStyle default psDash;
    property BoxSelectWidth: integer read FBoxSelectWidth
      write FBoxSelectWidth default 1;

    property ResizeHandleBrushColor: TColor
      read FResizeHandleBrushColor write FResizeHandleBrushColor default clGray;
    property ResizeHandlePenColor: TColor read FResizeHandlePenColor
      write FResizeHandlePenColor default clBlack;
  end;

  TRenderContext = class
  public
    Sender: TObject;

    CanvasKind: TRenderCanvasKind;
    GDICanvas: TCanvas;
    GLCanvas: TGL2DCanvas;
    GLCanvasProxy: TGLCanvasProxy;

    ClientRect: TRect;
    ClientWidth: integer;
    ClientHeight: integer;

    Graph: TNodeGraph;
    PaintNodesSorted: TList;

    Zoom: double;
    OffsetX: double;
    OffsetY: double;
    VisibleWorldRect: TRectF;

    RenderState: TNodeRenderState;

    BoxSelecting: boolean;
    BoxSelectRect: TRect;

    ShowSnapGuides: boolean;
    GuideSnapXActive: boolean;
    GuideSnapYActive: boolean;
    GuideSnapX: single;
    GuideSnapY: single;

    DraggingNode: boolean;
    DrawResizeHandles: boolean;

    OnDrawNode: TRenderNodeDrawEvent;
    OnDrawPin: TRenderPinDrawEvent;
    OnDrawLink: TRenderLinkDrawEvent;
    OnDrawGrid: TRenderGridDrawEvent;
    OnDrawSnapGuides: TRenderSnapGuidesDrawEvent;

    function HasGDI: boolean; inline;
    function HasGL: boolean; inline;
    function EventCanvas: TCanvas; inline;
  end;

  INodeEditorRenderer = interface
    ['{78A5B326-4D99-4C84-B7B4-0A1D2F5A1D9A}']
    function GetBackend: TRendererBackend;
    function GetStyle: TRenderStyle;
    procedure SetStyle(AValue: TRenderStyle);

    procedure Render(const AContext: TRenderContext);

    function WorldToScreen(WX, WY: single; AZoom, AOffsetX, AOffsetY: double): TPoint;

    property Backend: TRendererBackend read GetBackend;
    property Style: TRenderStyle read GetStyle write SetStyle;
  end;

  { TAbstractNodeEditorRenderer }

  TAbstractNodeEditorRenderer = class(TInterfacedObject, INodeEditorRenderer)
  private
    FBackend: TRendererBackend;
    FStyle: TRenderStyle;
  protected
    function GetBackend: TRendererBackend;
    function GetStyle: TRenderStyle;
    procedure SetStyle(AValue: TRenderStyle);

    procedure BeginFrame(const AContext: TRenderContext); virtual; abstract;
    procedure EndFrame(const AContext: TRenderContext); virtual; abstract;

    procedure FillBackground(const AContext: TRenderContext); virtual;
    procedure DrawGrid(const AContext: TRenderContext); virtual;
    procedure DrawAxes(const AContext: TRenderContext); virtual;
    procedure DrawLinks(const AContext: TRenderContext); virtual;
    procedure DrawCommentNodes(const AContext: TRenderContext); virtual;
    procedure DrawRegularNodes(const AContext: TRenderContext); virtual;
    procedure DrawSingleNode(const AContext: TRenderContext;
      ANode: TCustomNode); virtual;
    procedure DrawTemporaryLink(const AContext: TRenderContext); virtual;
    procedure DrawNodes(const AContext: TRenderContext); virtual;
    procedure DrawPins(const AContext: TRenderContext); virtual;
    procedure DrawNodePins(const AContext: TRenderContext; ANode: TCustomNode); virtual;
    procedure DrawBoxSelect(const AContext: TRenderContext); virtual;
    procedure DrawSnapGuides(const AContext: TRenderContext); virtual;
    procedure DrawResizeHandles(const AContext: TRenderContext); virtual;

    procedure ResetCanvasState(const AContext: TRenderContext); virtual;

    procedure SetPen(const AContext: TRenderContext; AColor: TColor;
      AWidth: integer = 1; AStyle: TPenStyle = psSolid); inline;
    procedure SetBrush(const AContext: TRenderContext; AColor: TColor;
      AStyle: TBrushStyle = bsSolid); inline;
    procedure SetFont(const AContext: TRenderContext; AColor: TColor;
      ASize: integer); inline;

    procedure MoveToEx(const AContext: TRenderContext; X, Y: integer); inline;
    procedure LineToEx(const AContext: TRenderContext; X, Y: integer); inline;
    procedure RectangleEx(const AContext: TRenderContext; const R: TRect); inline;
    procedure FillRectEx(const AContext: TRenderContext; const R: TRect); inline;

    function GetResizeHandleRect(ANode: TCustomNode;
      const AContext: TRenderContext): TRect;
  public
    constructor Create(ABackend: TRendererBackend); virtual;
    destructor Destroy; override;

    procedure Render(const AContext: TRenderContext);
    function WorldToScreen(WX, WY: single; AZoom, AOffsetX, AOffsetY: double): TPoint;

    property Backend: TRendererBackend read GetBackend;
    property Style: TRenderStyle read GetStyle write SetStyle;
  end;

  TGDIRenderer = class(TAbstractNodeEditorRenderer)
  protected
    procedure BeginFrame(const AContext: TRenderContext); override;
    procedure EndFrame(const AContext: TRenderContext); override;
  public
    constructor Create; reintroduce;
  end;

  TOpenGLNodeEditorRenderer = class(TAbstractNodeEditorRenderer)
  protected
    procedure BeginFrame(const AContext: TRenderContext); override;
    procedure EndFrame(const AContext: TRenderContext); override;
  public
    constructor Create; reintroduce;
  end;

  TNodeEditorRendererFactory = class
  public
    class function CreateRenderer(ABackend: TRendererBackend): INodeEditorRenderer;
      static;
  end;

implementation

{ TRenderStyle }

constructor TRenderStyle.Create;
begin
  inherited Create;
  SetDefaults;
end;

procedure TRenderStyle.SetDefaults;
begin
  FBackgroundColor := $00F0F8FF;

  FGridVisible := True;
  FGridSize := 40;
  FGridColor := $00E0E0E0;
  FGridStyle := psSolid;
  FGridWidth := 1;

  FShowAxes := False;
  FAxesColor := clSilver;
  FAxesThickness := 2;

  FGuideLineColor := clAqua;
  FGuideLineStyle := psDash;
  FGuideLineWidth := 1;

  FBoxSelectColor := clBlue;
  FBoxSelectStyle := psDash;
  FBoxSelectWidth := 1;

  FResizeHandleBrushColor := clGray;
  FResizeHandlePenColor := clBlack;
end;

procedure TRenderStyle.Assign(Source: TPersistent);
var
  S: TRenderStyle;
begin
  if Source is TRenderStyle then
  begin
    S := TRenderStyle(Source);

    FBackgroundColor := S.FBackgroundColor;

    FGridVisible := S.FGridVisible;
    FGridSize := S.FGridSize;
    FGridColor := S.FGridColor;
    FGridStyle := S.FGridStyle;
    FGridWidth := S.FGridWidth;

    FShowAxes := S.FShowAxes;
    FAxesColor := S.FAxesColor;
    FAxesThickness := S.FAxesThickness;

    FGuideLineColor := S.FGuideLineColor;
    FGuideLineStyle := S.FGuideLineStyle;
    FGuideLineWidth := S.FGuideLineWidth;

    FBoxSelectColor := S.FBoxSelectColor;
    FBoxSelectStyle := S.FBoxSelectStyle;
    FBoxSelectWidth := S.FBoxSelectWidth;

    FResizeHandleBrushColor := S.FResizeHandleBrushColor;
    FResizeHandlePenColor := S.FResizeHandlePenColor;
  end;
end;

{ TRenderContext }

function TRenderContext.HasGDI: boolean; inline;
begin
  Result := CanvasKind = rckGDI;
end;

function TRenderContext.HasGL: boolean; inline;
begin
  Result := CanvasKind = rckGL2D;
end;

function TRenderContext.EventCanvas: TCanvas; inline;
begin
  if HasGDI then
    Result := GDICanvas
  else if HasGL then
    Result := GLCanvasProxy
  else
    Result := nil;
end;

{ TAbstractNodeEditorRenderer }

constructor TAbstractNodeEditorRenderer.Create(ABackend: TRendererBackend);
begin
  inherited Create;
  FBackend := ABackend;
  FStyle := TRenderStyle.Create;
end;

destructor TAbstractNodeEditorRenderer.Destroy;
begin
  FStyle.Free;
  inherited Destroy;
end;

function TAbstractNodeEditorRenderer.GetBackend: TRendererBackend;
begin
  Result := FBackend;
end;

function TAbstractNodeEditorRenderer.GetStyle: TRenderStyle;
begin
  Result := FStyle;
end;

procedure TAbstractNodeEditorRenderer.SetStyle(AValue: TRenderStyle);
begin
  if AValue <> nil then
    FStyle.Assign(AValue);
end;

procedure TAbstractNodeEditorRenderer.Render(const AContext: TRenderContext);
begin
  if AContext = nil then
    Exit;

  BeginFrame(AContext);
  try
    FillBackground(AContext);
    DrawGrid(AContext);
    DrawAxes(AContext);
    DrawCommentNodes(AContext);
    DrawLinks(AContext);
    DrawRegularNodes(AContext);
    DrawTemporaryLink(AContext);
    DrawPins(AContext);
    DrawResizeHandles(AContext);
    DrawSnapGuides(AContext);
    DrawBoxSelect(AContext);
  finally
    ResetCanvasState(AContext);
    EndFrame(AContext);
  end;
end;

procedure TAbstractNodeEditorRenderer.FillBackground(const AContext: TRenderContext);
begin
  SetBrush(AContext, FStyle.BackgroundColor, bsSolid);
  FillRectEx(AContext, AContext.ClientRect);
end;

procedure TAbstractNodeEditorRenderer.DrawGrid(const AContext: TRenderContext);
var
  GX, GY: single;
  SX, SY: integer;
  StartX, StartY: single;
  Handled: boolean;
begin
  if not FStyle.GridVisible then
    Exit;
  if FStyle.GridSize <= 0 then
    Exit;

  Handled := False;
  if Assigned(AContext.OnDrawGrid) then
    AContext.OnDrawGrid(AContext.Sender, AContext.EventCanvas, AContext.VisibleWorldRect,
      AContext.Zoom, AContext.OffsetX, AContext.OffsetY, Handled);

  if Handled then
    Exit;

  SetPen(AContext, FStyle.GridColor, FStyle.GridWidth, FStyle.GridStyle);

  StartX := Floor(AContext.VisibleWorldRect.Left / FStyle.GridSize) * FStyle.GridSize;
  GX := StartX;
  while GX <= AContext.VisibleWorldRect.Right do
  begin
    SX := WorldToScreen(GX, 0, AContext.Zoom, AContext.OffsetX, AContext.OffsetY).X;
    MoveToEx(AContext, SX, 0);
    LineToEx(AContext, SX, AContext.ClientHeight);
    GX := GX + FStyle.GridSize;
  end;

  StartY := Floor(AContext.VisibleWorldRect.Top / FStyle.GridSize) * FStyle.GridSize;
  GY := StartY;
  while GY <= AContext.VisibleWorldRect.Bottom do
  begin
    SY := WorldToScreen(0, GY, AContext.Zoom, AContext.OffsetX, AContext.OffsetY).Y;
    MoveToEx(AContext, 0, SY);
    LineToEx(AContext, AContext.ClientWidth, SY);
    GY := GY + FStyle.GridSize;
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawAxes(const AContext: TRenderContext);
var
  SX, SY: integer;
begin
  if not FStyle.ShowAxes then
    Exit;

  SetPen(AContext, FStyle.AxesColor, FStyle.AxesThickness, psSolid);

  if (AContext.VisibleWorldRect.Left <= 0) and
    (AContext.VisibleWorldRect.Right >= 0) then
  begin
    SX := WorldToScreen(0, 0, AContext.Zoom, AContext.OffsetX, AContext.OffsetY).X;
    MoveToEx(AContext, SX, 0);
    LineToEx(AContext, SX, AContext.ClientHeight);
  end;

  if (AContext.VisibleWorldRect.Top <= 0) and
    (AContext.VisibleWorldRect.Bottom >= 0) then
  begin
    SY := WorldToScreen(0, 0, AContext.Zoom, AContext.OffsetX, AContext.OffsetY).Y;
    MoveToEx(AContext, 0, SY);
    LineToEx(AContext, AContext.ClientWidth, SY);
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawLinks(const AContext: TRenderContext);
var
  i: integer;
  L: TNodeLink;
  Selected, Hovered: boolean;
  P0W, P1W, P2W, P3W: TPointF;
  P0, P1, P2, P3: TPoint;
  Handled: boolean;
begin
  if (AContext.Graph = nil) or (AContext.Graph.Links = nil) then
    Exit;

  for i := 0 to AContext.Graph.Links.Count - 1 do
  begin
    L := TNodeLink(AContext.Graph.Links[i]);
    if L = nil then
      Continue;

    Selected := AContext.RenderState.SelectedLink = L;
    Hovered := AContext.RenderState.HoveredLink = L;

    if not L.GetBezierWorldPoints(P0W, P1W, P2W, P3W) then
      Continue;

    P0 := WorldToScreen(P0W.X, P0W.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
    P1 := WorldToScreen(P1W.X, P1W.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
    P2 := WorldToScreen(P2W.X, P2W.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
    P3 := WorldToScreen(P3W.X, P3W.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);

    Handled := False;
    if Assigned(AContext.OnDrawLink) then
      AContext.OnDrawLink(AContext.Sender, AContext.EventCanvas, L,
        P0, P1, P2, P3, Selected, Hovered, Handled);

    if not Handled then
      L.Paint(AContext.EventCanvas, AContext.RenderState, Selected, Hovered);
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawSingleNode(const AContext: TRenderContext;
  ANode: TCustomNode);
var
  R: TRect;
  Handled: boolean;
begin
  if (ANode = nil) or (AContext.EventCanvas = nil) then
    Exit;

  R := ANode.GetScreenBounds(AContext.Zoom, AContext.OffsetX, AContext.OffsetY);

  Handled := False;
  if Assigned(AContext.OnDrawNode) then
    AContext.OnDrawNode(AContext.Sender, AContext.EventCanvas, ANode, R,
      AContext.Zoom, AContext.OffsetX, AContext.OffsetY, Handled);

  if not Handled then
    ANode.PaintBodyOnly(AContext.EventCanvas, AContext.RenderState);

  DrawNodePins(AContext, ANode);
end;

procedure TAbstractNodeEditorRenderer.DrawCommentNodes(const AContext: TRenderContext);
var
  i: integer;
  N: TCustomNode;
begin
  if AContext.PaintNodesSorted = nil then
    Exit;

  for i := 0 to AContext.PaintNodesSorted.Count - 1 do
  begin
    N := TCustomNode(AContext.PaintNodesSorted[i]);
    if (N = nil) or (N.VisualKind <> nvComment) then
      Continue;
    DrawSingleNode(AContext, N);
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawRegularNodes(const AContext: TRenderContext);
var
  i: integer;
  N: TCustomNode;
begin
  if AContext.PaintNodesSorted = nil then
    Exit;

  for i := 0 to AContext.PaintNodesSorted.Count - 1 do
  begin
    N := TCustomNode(AContext.PaintNodesSorted[i]);
    if (N = nil) or (N.VisualKind = nvComment) then
      Continue;
    DrawSingleNode(AContext, N);
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawTemporaryLink(const AContext: TRenderContext);
var
  FromPin: TNodePin;
  FromNode: TCustomNode;
  P0, P1, P2, P3: TPoint;
  P0W: TPointF;
  DX, DY, Dist, D: single;
begin
  if AContext.EventCanvas = nil then
    Exit;

  if AContext.RenderState.TempFromPin = nil then
    Exit;

  FromPin := TNodePin(AContext.RenderState.TempFromPin);
  if (FromPin = nil) or not (FromPin.OwnerNode is TCustomNode) then
    Exit;

  FromNode := TCustomNode(FromPin.OwnerNode);
  P0W := FromNode.GetPinWorldPosition(FromPin);
  P0 := WorldToScreen(P0W.X, P0W.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  P3 := AContext.RenderState.TempMousePos;

  DX := P3.X - P0.X;
  DY := P3.Y - P0.Y;
  Dist := Hypot(DX, DY);
  D := EnsureRange(Dist * 0.35, 30, 150);

  if FromPin.Direction = pdOutput then
  begin
    P1 := Point(P0.X + Round(D), P0.Y);
    P2 := Point(P3.X - Round(D), P3.Y);
  end
  else
  begin
    P1 := Point(P0.X - Round(D), P0.Y);
    P2 := Point(P3.X + Round(D), P3.Y);
  end;

  AContext.EventCanvas.Brush.Style := bsClear;
  AContext.EventCanvas.Pen.Style := psDash;
  AContext.EventCanvas.Pen.Color := clAqua;
  AContext.EventCanvas.Pen.Width := Max(1, Round(3 * AContext.Zoom));
  DrawCubicBezier(AContext.EventCanvas, P0, P1, P2, P3, 24);

  AContext.EventCanvas.Pen.Style := psSolid;
  AContext.EventCanvas.Pen.Width := 1;
  AContext.EventCanvas.Brush.Style := bsSolid;
end;

procedure TAbstractNodeEditorRenderer.DrawNodes(const AContext: TRenderContext);
begin
  DrawRegularNodes(AContext);
end;

procedure TAbstractNodeEditorRenderer.DrawPins(const AContext: TRenderContext);
var
  i: integer;
  N: TCustomNode;
begin
  if AContext.PaintNodesSorted = nil then
    Exit;

  for i := 0 to AContext.PaintNodesSorted.Count - 1 do
  begin
    N := TCustomNode(AContext.PaintNodesSorted[i]);
    if N = nil then
      Continue;
    DrawNodePins(AContext, N);
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawNodePins(const AContext: TRenderContext;
  ANode: TCustomNode);
var
  i: integer;
  P: TNodePin;
  Center: TPoint;
  Radius: integer;
  Selected: boolean;
  Hovered: boolean;
  Highlighted: boolean;
  Handled: boolean;
begin
  if (ANode = nil) or (AContext.EventCanvas = nil) then
    Exit;
  if ANode.VisualKind = nvComment then
    Exit;

  Radius := Max(2, Round(AContext.RenderState.PinRadius * AContext.Zoom));

  for i := 0 to ANode.InputCount - 1 do
  begin
    P := ANode.GetInput(i);
    if (P = nil) or P.Hidden then
      Continue;

    Center := ANode.GetPinScreenPosition(P, AContext.Zoom,
      Round(AContext.OffsetX), Round(AContext.OffsetY));

    Selected := TPinSelectionAccess.Contains(AContext.RenderState.PinSelection, P);
    Hovered := (AContext.RenderState.HoveredPin = P);

    Highlighted := ANode.Highlighted or ((AContext.RenderState.TempFromPin <> nil) and
      (AContext.RenderState.HoveredPin = P));

    Handled := False;
    if Assigned(AContext.OnDrawPin) then
      AContext.OnDrawPin(AContext.Sender, AContext.EventCanvas, P, Center, Radius,
        Selected, Hovered, Highlighted, Handled);

    if not Handled then
      ANode.PaintSinglePin(AContext.EventCanvas, P, Center, Radius,
        AContext.RenderState);

    ANode.PaintPinLabel(AContext.EventCanvas, P, Center, Radius, AContext.RenderState);
  end;

  for i := 0 to ANode.OutputCount - 1 do
  begin
    P := ANode.GetOutput(i);
    if (P = nil) or P.Hidden then
      Continue;

    Center := ANode.GetPinScreenPosition(P, AContext.Zoom,
      Round(AContext.OffsetX), Round(AContext.OffsetY));

    Selected := TPinSelectionAccess.Contains(AContext.RenderState.PinSelection, P);
    Hovered := (AContext.RenderState.HoveredPin = P) and
      (AContext.RenderState.TempFromPin = nil);
    Highlighted := ANode.Highlighted or
      ((AContext.RenderState.TempFromPin <> nil) and
      (AContext.RenderState.HoveredPin = P));

    Handled := False;
    if Assigned(AContext.OnDrawPin) then
      AContext.OnDrawPin(AContext.Sender, AContext.EventCanvas, P, Center, Radius,
        Selected, Hovered, Highlighted, Handled);

    if not Handled then
      ANode.PaintSinglePin(AContext.EventCanvas, P, Center, Radius,
        AContext.RenderState);

    ANode.PaintPinLabel(AContext.EventCanvas, P, Center, Radius, AContext.RenderState);
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawBoxSelect(const AContext: TRenderContext);
begin
  if not AContext.BoxSelecting then
    Exit;

  SetBrush(AContext, clNone, bsClear);
  SetPen(AContext, FStyle.BoxSelectColor, FStyle.BoxSelectWidth, FStyle.BoxSelectStyle);
  RectangleEx(AContext, AContext.BoxSelectRect);
end;

procedure TAbstractNodeEditorRenderer.DrawSnapGuides(const AContext: TRenderContext);
var
  SX, SY: integer;
  Handled: boolean;
begin
  if not AContext.ShowSnapGuides then
    Exit;

  Handled := False;
  if Assigned(AContext.OnDrawSnapGuides) then
    AContext.OnDrawSnapGuides(AContext.Sender, AContext.EventCanvas,
      AContext.GuideSnapXActive, AContext.GuideSnapYActive,
      AContext.GuideSnapX, AContext.GuideSnapY,
      AContext.Zoom, AContext.OffsetX, AContext.OffsetY, Handled);

  if Handled then
    Exit;

  SetPen(AContext, FStyle.GuideLineColor, FStyle.GuideLineWidth, FStyle.GuideLineStyle);

  if AContext.GuideSnapXActive then
  begin
    SX := Round(AContext.GuideSnapX * AContext.Zoom + AContext.OffsetX);
    MoveToEx(AContext, SX, 0);
    LineToEx(AContext, SX, AContext.ClientHeight);
  end;

  if AContext.GuideSnapYActive then
  begin
    SY := Round(AContext.GuideSnapY * AContext.Zoom + AContext.OffsetY);
    MoveToEx(AContext, 0, SY);
    LineToEx(AContext, AContext.ClientWidth, SY);
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawResizeHandles(const AContext: TRenderContext);
var
  i: integer;
  N: TCustomNode;
  R: TRect;
begin
  if not AContext.DrawResizeHandles then
    Exit;
  if (AContext.Graph = nil) or (AContext.Graph.Nodes = nil) then
    Exit;

  SetBrush(AContext, FStyle.ResizeHandleBrushColor, bsSolid);
  SetPen(AContext, FStyle.ResizeHandlePenColor, 1, psSolid);

  for i := 0 to AContext.Graph.Nodes.Count - 1 do
  begin
    N := TCustomNode(AContext.Graph.Nodes[i]);
    if (N = nil) or (N.VisualKind = nvReroute) or not N.Selected then
      Continue;
    R := GetResizeHandleRect(N, AContext);
    RectangleEx(AContext, R);
  end;
end;

procedure TAbstractNodeEditorRenderer.ResetCanvasState(const AContext: TRenderContext);
begin
  SetPen(AContext, clBlack, 1, psSolid);
  SetBrush(AContext, clWhite, bsSolid);
end;

procedure TAbstractNodeEditorRenderer.SetPen(const AContext: TRenderContext;
  AColor: TColor; AWidth: integer; AStyle: TPenStyle);
begin
  if AContext.HasGDI then
  begin
    AContext.GDICanvas.Pen.Color := AColor;
    AContext.GDICanvas.Pen.Width := AWidth;
    AContext.GDICanvas.Pen.Style := AStyle;
  end
  else if AContext.HasGL then
  begin
    AContext.GLCanvas.Pen.Color := AColor;
    AContext.GLCanvas.Pen.Width := AWidth;
    AContext.GLCanvas.Pen.Style := AStyle;
  end;
end;

procedure TAbstractNodeEditorRenderer.SetBrush(const AContext: TRenderContext;
  AColor: TColor; AStyle: TBrushStyle);
begin
  if AContext.HasGDI then
  begin
    AContext.GDICanvas.Brush.Color := AColor;
    AContext.GDICanvas.Brush.Style := AStyle;
  end
  else if AContext.HasGL then
  begin
    AContext.GLCanvas.Brush.Color := AColor;
    AContext.GLCanvas.Brush.Style := AStyle;
  end;
end;

procedure TAbstractNodeEditorRenderer.SetFont(const AContext: TRenderContext;
  AColor: TColor; ASize: integer);
begin
  if AContext.HasGDI then
  begin
    AContext.GDICanvas.Font.Color := AColor;
    AContext.GDICanvas.Font.Size := ASize;
  end
  else if AContext.HasGL then
  begin
    AContext.GLCanvas.Font.Color := AColor;
    AContext.GLCanvas.Font.Size := ASize;
  end;
end;

procedure TAbstractNodeEditorRenderer.MoveToEx(const AContext: TRenderContext;
  X, Y: integer);
begin
  if AContext.HasGDI then
    AContext.GDICanvas.MoveTo(X, Y)
  else if AContext.HasGL then
    AContext.GLCanvas.MoveTo(X, Y);
end;

procedure TAbstractNodeEditorRenderer.LineToEx(const AContext: TRenderContext;
  X, Y: integer);
begin
  if AContext.HasGDI then
    AContext.GDICanvas.LineTo(X, Y)
  else if AContext.HasGL then
    AContext.GLCanvas.LineTo(X, Y);
end;

procedure TAbstractNodeEditorRenderer.RectangleEx(const AContext: TRenderContext;
  const R: TRect);
begin
  if AContext.HasGDI then
    AContext.GDICanvas.Rectangle(R)
  else if AContext.HasGL then
    AContext.GLCanvas.Rectangle(R);
end;

procedure TAbstractNodeEditorRenderer.FillRectEx(const AContext: TRenderContext;
  const R: TRect);
begin
  if AContext.HasGDI then
    AContext.GDICanvas.FillRect(R)
  else if AContext.HasGL then
    AContext.GLCanvas.FillRect(R);
end;

function TAbstractNodeEditorRenderer.GetResizeHandleRect(ANode: TCustomNode;
  const AContext: TRenderContext): TRect;
var
  R: TRect;
  S: integer;
begin
  R := ANode.GetScreenBounds(AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  S := Max(10, Round(AContext.RenderState.ResizeHandleSize * AContext.Zoom));
  Result := Rect(R.Right - S, R.Bottom - S, R.Right + 1, R.Bottom + 1);
end;

function TAbstractNodeEditorRenderer.WorldToScreen(WX, WY: single;
  AZoom, AOffsetX, AOffsetY: double): TPoint;
begin
  Result.X := Round(WX * AZoom + AOffsetX);
  Result.Y := Round(WY * AZoom + AOffsetY);
end;

{ TGDIRenderer }

constructor TGDIRenderer.Create;
begin
  inherited Create(rbGDI);
end;

procedure TGDIRenderer.BeginFrame(const AContext: TRenderContext);
begin
  if AContext.GDICanvas <> nil then
  begin
    AContext.GDICanvas.Pen.Style := psSolid;
    AContext.GDICanvas.Pen.Width := 1;
    AContext.GDICanvas.Brush.Style := bsSolid;
    {$IFDEF LCL}
    AContext.GDICanvas.Font.Quality := fqAntialiased;
    AContext.GDICanvas.Pen.JoinStyle := pjsRound;
    AContext.GDICanvas.Pen.EndCap := pecRound;
    {$ENDIF}
  end;
end;

procedure TGDIRenderer.EndFrame(const AContext: TRenderContext);
begin
end;

{ TOpenGLNodeEditorRenderer }

constructor TOpenGLNodeEditorRenderer.Create;
begin
  inherited Create(rbOpenGL2D);
end;

procedure TOpenGLNodeEditorRenderer.BeginFrame(const AContext: TRenderContext);
begin
  if AContext.GLCanvas <> nil then
  begin
    AContext.GLCanvas.Pen.Style := psSolid;
    AContext.GLCanvas.Pen.Width := 1;
    AContext.GLCanvas.Brush.Style := bsSolid;
  end;
end;

procedure TOpenGLNodeEditorRenderer.EndFrame(const AContext: TRenderContext);
begin
end;

{ TNodeEditorRendererFactory }

class function TNodeEditorRendererFactory.CreateRenderer(
  ABackend: TRendererBackend): INodeEditorRenderer;
begin
  case ABackend of
    rbGDI: Result := TGDIRenderer.Create;
    rbOpenGL2D: Result := TOpenGLNodeEditorRenderer.Create;
    else
      Result := TGDIRenderer.Create;
  end;
end;

end.
