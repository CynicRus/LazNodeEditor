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
  Classes, SysUtils, Math, Types, Graphics, FPCanvas,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Selection,
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

  { TRenderStyle }

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

    FPinRadius: integer;
    FPinBorderWidth: integer;
    FPinBorderColor: TColor;
    FPinDefaultColor: TColor;
    FPinExecColor: TColor;
    FPinSelectedColor: TColor;
    FPinHoverColor: TColor;
    FPinCompatibleColor: TColor;
    FPinIncompatibleColor: TColor;

    FLinkColor: TColor;
    FLinkSelectedColor: TColor;
    FLinkHoverColor: TColor;
    FLinkThickness: integer;
    FLinkSelectedThickness: integer;
    FTempLinkColor: TColor;
    FTempLinkThickness: integer;
    FTempLinkStyle: TPenStyle;

    FBoxSelectColor: TColor;
    FBoxSelectStyle: TPenStyle;
    FBoxSelectWidth: integer;

    FGuideLineColor: TColor;
    FGuideLineStyle: TPenStyle;
    FGuideLineWidth: integer;

    FNodeBorderColor: TColor;
    FNodeHoverBorderColor: TColor;
    FNodeHighlightBorderColor: TColor;
    FNodeSelectedBorderColor: TColor;

    FCommentHoverBorderColor: TColor;
    FCommentHighlightBorderColor: TColor;
    FCommentSelectedBorderColor: TColor;

    FRerouteOuterColor: TColor;
    FRerouteInnerColor: TColor;
    FRerouteBorderColor: TColor;
    FRerouteCenterBorderColor: TColor;
    FRerouteLineColor: TColor;

    FDragInfoFontColor: TColor;
    FDragInfoBackgroundColor: TColor;

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

    property PinRadius: integer read FPinRadius write FPinRadius default 8;
    property PinBorderWidth: integer read FPinBorderWidth write FPinBorderWidth default 1;
    property PinBorderColor: TColor read FPinBorderColor write FPinBorderColor default clBlack;
    property PinDefaultColor: TColor read FPinDefaultColor write FPinDefaultColor default clLime;
    property PinExecColor: TColor read FPinExecColor write FPinExecColor default clWhite;
    property PinSelectedColor: TColor read FPinSelectedColor write FPinSelectedColor default clLime;
    property PinHoverColor: TColor read FPinHoverColor write FPinHoverColor default clAqua;
    property PinCompatibleColor: TColor read FPinCompatibleColor write FPinCompatibleColor default clAqua;
    property PinIncompatibleColor: TColor read FPinIncompatibleColor write FPinIncompatibleColor default clRed;

    property LinkColor: TColor read FLinkColor write FLinkColor default clYellow;
    property LinkSelectedColor: TColor read FLinkSelectedColor write FLinkSelectedColor default clRed;
    property LinkHoverColor: TColor read FLinkHoverColor write FLinkHoverColor default clAqua;
    property LinkThickness: integer read FLinkThickness write FLinkThickness default 4;
    property LinkSelectedThickness: integer read FLinkSelectedThickness write FLinkSelectedThickness default 5;
    property TempLinkColor: TColor read FTempLinkColor write FTempLinkColor default clYellow;
    property TempLinkThickness: integer read FTempLinkThickness write FTempLinkThickness default 3;
    property TempLinkStyle: TPenStyle read FTempLinkStyle write FTempLinkStyle default psDot;

    property BoxSelectColor: TColor read FBoxSelectColor write FBoxSelectColor default clBlue;
    property BoxSelectStyle: TPenStyle read FBoxSelectStyle write FBoxSelectStyle default psDash;
    property BoxSelectWidth: integer read FBoxSelectWidth write FBoxSelectWidth default 1;

    property GuideLineColor: TColor read FGuideLineColor write FGuideLineColor default clAqua;
    property GuideLineStyle: TPenStyle read FGuideLineStyle write FGuideLineStyle default psDash;
    property GuideLineWidth: integer read FGuideLineWidth write FGuideLineWidth default 1;

    property NodeBorderColor: TColor read FNodeBorderColor write FNodeBorderColor default clBlack;
    property NodeHoverBorderColor: TColor read FNodeHoverBorderColor write FNodeHoverBorderColor default clBlue;
    property NodeHighlightBorderColor: TColor read FNodeHighlightBorderColor write FNodeHighlightBorderColor default clAqua;
    property NodeSelectedBorderColor: TColor read FNodeSelectedBorderColor write FNodeSelectedBorderColor default clRed;

    property CommentHoverBorderColor: TColor read FCommentHoverBorderColor write FCommentHoverBorderColor default clBlue;
    property CommentHighlightBorderColor: TColor read FCommentHighlightBorderColor write FCommentHighlightBorderColor default clAqua;
    property CommentSelectedBorderColor: TColor read FCommentSelectedBorderColor write FCommentSelectedBorderColor default clRed;

    property RerouteOuterColor: TColor read FRerouteOuterColor write FRerouteOuterColor default $00F8F8F8;
    property RerouteInnerColor: TColor read FRerouteInnerColor write FRerouteInnerColor default $00FFFFFF;
    property RerouteBorderColor: TColor read FRerouteBorderColor write FRerouteBorderColor default $00404040;
    property RerouteCenterBorderColor: TColor read FRerouteCenterBorderColor write FRerouteCenterBorderColor default $00808080;
    property RerouteLineColor: TColor read FRerouteLineColor write FRerouteLineColor default $00505050;

    property DragInfoFontColor: TColor read FDragInfoFontColor write FDragInfoFontColor default clBlack;
    property DragInfoBackgroundColor: TColor read FDragInfoBackgroundColor write FDragInfoBackgroundColor default $00FFFFCC;

    property ResizeHandleBrushColor: TColor read FResizeHandleBrushColor write FResizeHandleBrushColor default clGray;
    property ResizeHandlePenColor: TColor read FResizeHandlePenColor write FResizeHandlePenColor default clBlack;
  end;

  { TRenderContext }

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

    HoveredNode: TCustomNode;
    HoveredPin: TNodePin;
    HoveredLink: TNodeLink;
    SelectedLink: TNodeLink;
    PinSelectionModel: TPinSelectionModel;

    TempFromPin: TNodePin;
    TempMousePos: TPoint;
    DraggingLink: boolean;

    ReconnectingLink: boolean;
    ReconnectLink: TNodeLink;
    ReconnectFixedPin: TNodePin;
    ReconnectMovingFromSide: boolean;

    BoxSelecting: boolean;
    BoxSelectRect: TRect;

    ShowSnapGuides: boolean;
    GuideSnapXActive: boolean;
    GuideSnapYActive: boolean;
    GuideSnapX: single;
    GuideSnapY: single;
    HoveredPinCompatible: boolean;

    DraggingNode: boolean;
    ShowDragCoordinates: boolean;
    PrimarySelectedNode: TCustomNode;
    DragStartWorldPos: TPointF;
    AltPressed: boolean;

    DrawResizeHandles: boolean;
    ResizeHandleSize: integer;

    OnDrawNode: TRenderNodeDrawEvent;
    OnDrawPin: TRenderPinDrawEvent;
    OnDrawLink: TRenderLinkDrawEvent;
    OnDrawGrid: TRenderGridDrawEvent;
    OnDrawSnapGuides: TRenderSnapGuidesDrawEvent;

    function HasGDI: boolean; inline;
    function HasGL: boolean; inline;
    function EventCanvas: TCanvas; inline;
  end;

  { INodeEditorRenderer }

  INodeEditorRenderer = interface
    ['{78A5B326-4D99-4C84-B7B4-0A1D2F5A1D9A}']
    function GetBackend: TRendererBackend;
    function GetStyle: TRenderStyle;
    procedure SetStyle(AValue: TRenderStyle);

    procedure Render(const AContext: TRenderContext);

    function WorldToScreen(WX, WY: single; AZoom, AOffsetX, AOffsetY: double): TPoint;
    function GetPinWorldPosition(APin: TNodePin): TPointF;
    procedure GetLinkBezierWorldPoints(ALink: TNodeLink; out P0, P1, P2, P3: TPointF);

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

  protected
    procedure BeginFrame(const AContext: TRenderContext); virtual; abstract;
    procedure EndFrame(const AContext: TRenderContext); virtual; abstract;

    procedure FillBackground(const AContext: TRenderContext); virtual;
    procedure RenderComments(const AContext: TRenderContext; ASelectedPass: boolean); virtual;
    procedure RenderRegularNodes(const AContext: TRenderContext; ASelectedPass: boolean); virtual;
    procedure RenderLinks(const AContext: TRenderContext); virtual;
    procedure RenderTempLink(const AContext: TRenderContext); virtual;
    procedure RenderBoxSelect(const AContext: TRenderContext); virtual;
    procedure RenderSnapGuides(const AContext: TRenderContext); virtual;
    procedure RenderResizeHandles(const AContext: TRenderContext); virtual;
    procedure RenderDragInfo(const AContext: TRenderContext); virtual;

    procedure ResetCanvasState(const AContext: TRenderContext); virtual;

    procedure DrawGrid(const AContext: TRenderContext); virtual;
    procedure DrawAxes(const AContext: TRenderContext); virtual;

    procedure DrawNode(ANode: TCustomNode; const AContext: TRenderContext); virtual;
    procedure DrawNodePins(ANode: TCustomNode; const AContext: TRenderContext); virtual;
    procedure DrawNodeWithPins(ANode: TCustomNode; const AContext: TRenderContext); virtual;
    procedure DrawLink(ALink: TNodeLink; const AContext: TRenderContext;
      ASelected, AHovered: boolean); virtual;
    procedure DrawTempBezier(const AContext: TRenderContext;
      const P0, P1, P2, P3: TPoint); virtual;
    procedure DrawBoxSelectRect(const AContext: TRenderContext; const R: TRect); virtual;
    procedure DrawSnapGuideLines(const AContext: TRenderContext); virtual;
    procedure DrawResizeHandle(const AContext: TRenderContext; const R: TRect); virtual;

    procedure DefaultDrawNode(ANode: TCustomNode; const ARect: TRect;
      const AContext: TRenderContext); virtual;
    procedure DefaultDrawPin(APin: TNodePin; const Center: TPoint; Radius: integer;
      ASelected, AHovered, AHighlighted: boolean; const AContext: TRenderContext); virtual;
    procedure DefaultDrawLink(ALink: TNodeLink; const P0, P1, P2, P3: TPoint;
      ASelected, AHovered: boolean; const AContext: TRenderContext); virtual;

    procedure DrawBezierPolyline(const AContext: TRenderContext;
      const P0, P1, P2, P3: TPoint; ASteps: integer = 24); virtual;

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
    procedure EllipseEx(const AContext: TRenderContext; L, T, R, B: integer); inline;
    procedure TextOutEx(const AContext: TRenderContext; X, Y: integer; const S: string); inline;
    function TextWidthEx(const AContext: TRenderContext; const S: string): integer; inline;
    function TextHeightEx(const AContext: TRenderContext; const S: string): integer; inline;

    function GetNodeScreenBounds(ANode: TCustomNode; const AContext: TRenderContext): TRect;
    function GetResizeHandleRect(ANode: TCustomNode; const AContext: TRenderContext): TRect;
    function GetPinScreenCenter(APin: TNodePin; const AContext: TRenderContext): TPoint;

  public
    constructor Create(ABackend: TRendererBackend); virtual;
    destructor Destroy; override;

    procedure Render(const AContext: TRenderContext);

    function WorldToScreen(WX, WY: single; AZoom, AOffsetX, AOffsetY: double): TPoint;
    function GetPinWorldPosition(APin: TNodePin): TPointF;
    procedure GetLinkBezierWorldPoints(ALink: TNodeLink; out P0, P1, P2, P3: TPointF);

    property Backend: TRendererBackend read GetBackend;
    property Style: TRenderStyle read GetStyle write SetStyle;
  end;

  { TGDIRenderer }

  TGDIRenderer = class(TAbstractNodeEditorRenderer)
  protected
    procedure BeginFrame(const AContext: TRenderContext); override;
    procedure EndFrame(const AContext: TRenderContext); override;
  public
    constructor Create; reintroduce;
  end;

  { TOpenGLNodeEditorRenderer }

  TOpenGLNodeEditorRenderer = class(TAbstractNodeEditorRenderer)
  protected
    procedure BeginFrame(const AContext: TRenderContext); override;
    procedure EndFrame(const AContext: TRenderContext); override;
  public
    constructor Create; reintroduce;
  end;

  { TNodeEditorRendererFactory }

  TNodeEditorRendererFactory = class
  public
    class function CreateRenderer(ABackend: TRendererBackend): INodeEditorRenderer; static;
  end;

implementation

function PtInRectF(const Pt: TPointF; const R: TRectF): boolean; inline;
begin
  Result := (Pt.X >= R.Left) and (Pt.X <= R.Right) and
            (Pt.Y >= R.Top) and (Pt.Y <= R.Bottom);
end;

function CubicBezierPointF(const P0, P1, P2, P3: TPointF; T: single): TPointF;
var
  U, TT, UU, UUU, TTT: single;
begin
  U := 1 - T;
  TT := T * T;
  UU := U * U;
  UUU := UU * U;
  TTT := TT * T;

  Result.X := UUU * P0.X + 3 * UU * T * P1.X + 3 * U * TT * P2.X + TTT * P3.X;
  Result.Y := UUU * P0.Y + 3 * UU * T * P1.Y + 3 * U * TT * P2.Y + TTT * P3.Y;
end;

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

  FPinRadius := 8;
  FPinBorderWidth := 1;
  FPinBorderColor := clBlack;
  FPinDefaultColor := clLime;
  FPinExecColor := clWhite;
  FPinSelectedColor := clLime;
  FPinHoverColor := clAqua;
  FPinCompatibleColor := clAqua;
  FPinIncompatibleColor := clRed;

  FLinkColor := clYellow;
  FLinkSelectedColor := clRed;
  FLinkHoverColor := clAqua;
  FLinkThickness := 4;
  FLinkSelectedThickness := 5;
  FTempLinkColor := clYellow;
  FTempLinkThickness := 3;
  FTempLinkStyle := psDot;

  FBoxSelectColor := clBlue;
  FBoxSelectStyle := psDash;
  FBoxSelectWidth := 1;

  FGuideLineColor := clAqua;
  FGuideLineStyle := psDash;
  FGuideLineWidth := 1;

  FNodeBorderColor := clBlack;
  FNodeHoverBorderColor := clBlue;
  FNodeHighlightBorderColor := clAqua;
  FNodeSelectedBorderColor := clRed;

  FCommentHoverBorderColor := clBlue;
  FCommentHighlightBorderColor := clAqua;
  FCommentSelectedBorderColor := clRed;

  FRerouteOuterColor := $00F8F8F8;
  FRerouteInnerColor := $00FFFFFF;
  FRerouteBorderColor := $00404040;
  FRerouteCenterBorderColor := $00808080;
  FRerouteLineColor := $00505050;

  FDragInfoFontColor := clBlack;
  FDragInfoBackgroundColor := $00FFFFCC;

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

    FPinRadius := S.FPinRadius;
    FPinBorderWidth := S.FPinBorderWidth;
    FPinBorderColor := S.FPinBorderColor;
    FPinDefaultColor := S.FPinDefaultColor;
    FPinExecColor := S.FPinExecColor;
    FPinSelectedColor := S.FPinSelectedColor;
    FPinHoverColor := S.FPinHoverColor;
    FPinCompatibleColor := S.FPinCompatibleColor;
    FPinIncompatibleColor := S.FPinIncompatibleColor;

    FLinkColor := S.FLinkColor;
    FLinkSelectedColor := S.FLinkSelectedColor;
    FLinkHoverColor := S.FLinkHoverColor;
    FLinkThickness := S.FLinkThickness;
    FLinkSelectedThickness := S.FLinkSelectedThickness;
    FTempLinkColor := S.FTempLinkColor;
    FTempLinkThickness := S.FTempLinkThickness;
    FTempLinkStyle := S.FTempLinkStyle;

    FBoxSelectColor := S.FBoxSelectColor;
    FBoxSelectStyle := S.FBoxSelectStyle;
    FBoxSelectWidth := S.FBoxSelectWidth;

    FGuideLineColor := S.FGuideLineColor;
    FGuideLineStyle := S.FGuideLineStyle;
    FGuideLineWidth := S.FGuideLineWidth;

    FNodeBorderColor := S.FNodeBorderColor;
    FNodeHoverBorderColor := S.FNodeHoverBorderColor;
    FNodeHighlightBorderColor := S.FNodeHighlightBorderColor;
    FNodeSelectedBorderColor := S.FNodeSelectedBorderColor;

    FCommentHoverBorderColor := S.FCommentHoverBorderColor;
    FCommentHighlightBorderColor := S.FCommentHighlightBorderColor;
    FCommentSelectedBorderColor := S.FCommentSelectedBorderColor;

    FRerouteOuterColor := S.FRerouteOuterColor;
    FRerouteInnerColor := S.FRerouteInnerColor;
    FRerouteBorderColor := S.FRerouteBorderColor;
    FRerouteCenterBorderColor := S.FRerouteCenterBorderColor;
    FRerouteLineColor := S.FRerouteLineColor;

    FDragInfoFontColor := S.FDragInfoFontColor;
    FDragInfoBackgroundColor := S.FDragInfoBackgroundColor;

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
  if AValue = nil then
    Exit;
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

    RenderComments(AContext, False);
    RenderComments(AContext, True);

    RenderLinks(AContext);

    RenderRegularNodes(AContext, False);
    RenderRegularNodes(AContext, True);

    RenderResizeHandles(AContext);
    RenderSnapGuides(AContext);
    RenderTempLink(AContext);
    RenderBoxSelect(AContext);
    RenderDragInfo(AContext);
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

procedure TAbstractNodeEditorRenderer.RenderComments(const AContext: TRenderContext;
  ASelectedPass: boolean);
var
  i: integer;
  N: TCustomNode;
begin
  if AContext.PaintNodesSorted = nil then
    Exit;

  for i := 0 to AContext.PaintNodesSorted.Count - 1 do
  begin
    N := TCustomNode(AContext.PaintNodesSorted[i]);
    if (N <> nil) and (N.VisualKind = nvComment) and (N.Selected = ASelectedPass) then
      DrawNode(N, AContext);
  end;
end;

procedure TAbstractNodeEditorRenderer.RenderRegularNodes(const AContext: TRenderContext;
  ASelectedPass: boolean);
var
  i: integer;
  N: TCustomNode;
begin
  if AContext.PaintNodesSorted = nil then
    Exit;

  for i := 0 to AContext.PaintNodesSorted.Count - 1 do
  begin
    N := TCustomNode(AContext.PaintNodesSorted[i]);
    if (N <> nil) and (N.VisualKind <> nvComment) and (N.Selected = ASelectedPass) then
      DrawNodeWithPins(N, AContext);
  end;
end;

procedure TAbstractNodeEditorRenderer.RenderLinks(const AContext: TRenderContext);
var
  i: integer;
  L: TNodeLink;
  Selected, Hovered: boolean;
begin
  if (AContext.Graph = nil) or (AContext.Graph.Links = nil) then
    Exit;

  for i := 0 to AContext.Graph.Links.Count - 1 do
  begin
    L := TNodeLink(AContext.Graph.Links[i]);
    if (L = nil) or (L.FromPin = nil) or (L.ToPin = nil) then
      Continue;

    Selected := L = AContext.SelectedLink;
    Hovered := L = AContext.HoveredLink;
    if AContext.ReconnectLink = L then
      Hovered := False;

    DrawLink(L, AContext, Selected, Hovered);
  end;
end;

procedure TAbstractNodeEditorRenderer.RenderTempLink(const AContext: TRenderContext);
var
  P0, P1, P2, P3: TPoint;
  W0, W1, W2, W3: TPointF;
  StartPin: TNodePin;
  FixedPosW: TPointF;
  DX, DY, Dist, D: single;
begin
  if AContext.TempFromPin = nil then
    Exit;

  StartPin := AContext.TempFromPin;

  if AContext.ReconnectingLink and (AContext.ReconnectFixedPin <> nil) then
  begin
    FixedPosW := GetPinWorldPosition(AContext.ReconnectFixedPin);

    if AContext.ReconnectMovingFromSide then
    begin
      W0.X := (AContext.TempMousePos.X - AContext.OffsetX) / AContext.Zoom;
      W0.Y := (AContext.TempMousePos.Y - AContext.OffsetY) / AContext.Zoom;
      W3 := FixedPosW;
    end
    else
    begin
      W0 := FixedPosW;
      W3.X := (AContext.TempMousePos.X - AContext.OffsetX) / AContext.Zoom;
      W3.Y := (AContext.TempMousePos.Y - AContext.OffsetY) / AContext.Zoom;
      StartPin := AContext.ReconnectFixedPin;
    end;
  end
  else
  begin
    W0 := GetPinWorldPosition(AContext.TempFromPin);
    W3.X := (AContext.TempMousePos.X - AContext.OffsetX) / AContext.Zoom;
    W3.Y := (AContext.TempMousePos.Y - AContext.OffsetY) / AContext.Zoom;
  end;

  DX := W3.X - W0.X;
  DY := W3.Y - W0.Y;
  Dist := Hypot(DX, DY);
  D := EnsureRange(Dist * 0.35, 30, 150);

  W1 := W0;
  W2 := W3;

  if (StartPin <> nil) and (StartPin.Direction = pdInput) then
  begin
    W1.X := W0.X - D;
    W2.X := W3.X + D;
  end
  else
  begin
    W1.X := W0.X + D;
    W2.X := W3.X - D;
  end;

  W1.Y := W0.Y;
  W2.Y := W3.Y;

  P0 := WorldToScreen(W0.X, W0.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  P1 := WorldToScreen(W1.X, W1.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  P2 := WorldToScreen(W2.X, W2.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  P3 := WorldToScreen(W3.X, W3.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);

  DrawTempBezier(AContext, P0, P1, P2, P3);
end;

procedure TAbstractNodeEditorRenderer.RenderBoxSelect(const AContext: TRenderContext);
begin
  if not AContext.BoxSelecting then
    Exit;
  DrawBoxSelectRect(AContext, AContext.BoxSelectRect);
end;

procedure TAbstractNodeEditorRenderer.RenderSnapGuides(const AContext: TRenderContext);
begin
  if not AContext.ShowSnapGuides then
    Exit;
  if not AContext.DraggingNode then
    Exit;
  DrawSnapGuideLines(AContext);
end;

procedure TAbstractNodeEditorRenderer.RenderResizeHandles(const AContext: TRenderContext);
var
  i: integer;
  N: TCustomNode;
begin
  if not AContext.DrawResizeHandles then
    Exit;
  if (AContext.Graph = nil) or (AContext.Graph.Nodes = nil) then
    Exit;

  for i := 0 to AContext.Graph.Nodes.Count - 1 do
  begin
    N := TCustomNode(AContext.Graph.Nodes[i]);
    if (N = nil) or (N.VisualKind = nvReroute) then
      Continue;
    if N.Selected then
      DrawResizeHandle(AContext, GetResizeHandleRect(N, AContext));
  end;
end;

procedure TAbstractNodeEditorRenderer.RenderDragInfo(const AContext: TRenderContext);
var
  CX, CY, DX, DY: single;
  Txt: string;
  TX, TY: integer;
  ScreenPos: TPoint;
  W, H: integer;
  R: TRect;
begin
  if not AContext.DraggingNode then
    Exit;
  if not AContext.ShowDragCoordinates then
    Exit;
  if AContext.PrimarySelectedNode = nil then
    Exit;
  if not AContext.AltPressed then
    Exit;

  CX := AContext.PrimarySelectedNode.X;
  CY := AContext.PrimarySelectedNode.Y;
  DX := CX - AContext.DragStartWorldPos.X;
  DY := CY - AContext.DragStartWorldPos.Y;

  Txt := Format('X: %.1f   Y: %.1f   (Δ %.1f, %.1f)', [CX, CY, DX, DY]);

  ScreenPos := WorldToScreen(CX, CY, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  TX := ScreenPos.X + Round(10 * AContext.Zoom);
  TY := ScreenPos.Y - Round(25 * AContext.Zoom);

  SetFont(AContext, FStyle.DragInfoFontColor, 9);
  SetBrush(AContext, FStyle.DragInfoBackgroundColor, bsSolid);

  W := TextWidthEx(AContext, Txt);
  H := Max(16, TextHeightEx(AContext, Txt));
  R := Rect(TX - 4, TY - 2, TX + W + 6, TY + H + 2);

  FillRectEx(AContext, R);
  TextOutEx(AContext, TX, TY, Txt);
end;

procedure TAbstractNodeEditorRenderer.ResetCanvasState(const AContext: TRenderContext);
begin
  SetPen(AContext, clBlack, 1, psSolid);
  SetBrush(AContext, clWhite, bsSolid);
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
  if Assigned(AContext.OnDrawGrid)  then
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

  if (AContext.VisibleWorldRect.Left <= 0) and (AContext.VisibleWorldRect.Right >= 0) then
  begin
    SX := WorldToScreen(0, 0, AContext.Zoom, AContext.OffsetX, AContext.OffsetY).X;
    MoveToEx(AContext, SX, 0);
    LineToEx(AContext, SX, AContext.ClientHeight);
  end;

  if (AContext.VisibleWorldRect.Top <= 0) and (AContext.VisibleWorldRect.Bottom >= 0) then
  begin
    SY := WorldToScreen(0, 0, AContext.Zoom, AContext.OffsetX, AContext.OffsetY).Y;
    MoveToEx(AContext, 0, SY);
    LineToEx(AContext, AContext.ClientWidth, SY);
  end;
end;

procedure TAbstractNodeEditorRenderer.DrawNode(ANode: TCustomNode;
  const AContext: TRenderContext);
var
  Handled: boolean;
  R: TRect;
begin
  if ANode = nil then
    Exit;

  R := GetNodeScreenBounds(ANode, AContext);

  Handled := False;
  if Assigned(AContext.OnDrawNode) then
    AContext.OnDrawNode(AContext.Sender, AContext.EventCanvas, ANode, R,
      AContext.Zoom, AContext.OffsetX, AContext.OffsetY, Handled);

  if not Handled then
    DefaultDrawNode(ANode, R, AContext);
end;

procedure TAbstractNodeEditorRenderer.DrawNodePins(ANode: TCustomNode;
  const AContext: TRenderContext);
var
  i: integer;
  PinRadiusScaled: integer;

  procedure DrawSinglePin(const APin: TNodePin; const AIsInput: boolean);
  var
    PX, PY: integer;
    Center: TPoint;
    IsSelected: boolean;
    IsHovered: boolean;
    Handled: boolean;
    R: TRect;
  begin
    if (APin = nil) or APin.Hidden then
      Exit;

    R := GetNodeScreenBounds(ANode, AContext);

    if AIsInput then
      PX := R.Left
    else
      PX := R.Right;

    PY := R.Top + Round(APin.LocalY * AContext.Zoom);
    Center := Point(PX, PY);

    IsSelected := AContext.PinSelectionModel.Contains(APin);
    IsHovered := (AContext.HoveredPin = APin) and (AContext.TempFromPin = nil);

    Handled := False;
    if Assigned(AContext.OnDrawPin) then
      AContext.OnDrawPin(AContext.Sender, AContext.EventCanvas, APin, Center,
        PinRadiusScaled, IsSelected, IsHovered, ANode.Highlighted, Handled);

    if not Handled then
      DefaultDrawPin(APin, Center, PinRadiusScaled, IsSelected, IsHovered,
        ANode.Highlighted, AContext);

    if (AContext.TempFromPin <> nil) and (AContext.HoveredPin = APin) then
    begin
      SetBrush(AContext, clNone, bsClear);
      SetPen(AContext,
        IfThen(AContext.HoveredPinCompatible, FStyle.PinCompatibleColor, FStyle.PinIncompatibleColor),
        Max(2, FStyle.PinBorderWidth + 2), psSolid);

      EllipseEx(AContext,
        Center.X - PinRadiusScaled - 5,
        Center.Y - PinRadiusScaled - 5,
        Center.X + PinRadiusScaled + 5,
        Center.Y + PinRadiusScaled + 5);
    end;

    SetBrush(AContext, clNone, bsClear);
    SetFont(AContext, clBlack, Max(6, Round(10 * AContext.Zoom)));

    if AIsInput then
      TextOutEx(AContext, PX + PinRadiusScaled + 6,
        PY - TextHeightEx(AContext, APin.Name) div 2, APin.Name)
    else
      TextOutEx(AContext, PX - TextWidthEx(AContext, APin.Name) - PinRadiusScaled - 6,
        PY - TextHeightEx(AContext, APin.Name) div 2, APin.Name);
  end;

begin
  if ANode = nil then
    Exit;
  if ANode.VisualKind = nvComment then
    Exit;

  PinRadiusScaled := Max(2, Round(FStyle.PinRadius * AContext.Zoom));

  for i := 0 to ANode.InputCount - 1 do
    DrawSinglePin(ANode.GetInput(i), True);

  for i := 0 to ANode.OutputCount - 1 do
    DrawSinglePin(ANode.GetOutput(i), False);
end;

procedure TAbstractNodeEditorRenderer.DrawNodeWithPins(ANode: TCustomNode;
  const AContext: TRenderContext);
begin
  DrawNode(ANode, AContext);
  if ANode.VisualKind <> nvComment then
    DrawNodePins(ANode, AContext);
end;

procedure TAbstractNodeEditorRenderer.DrawLink(ALink: TNodeLink;
  const AContext: TRenderContext; ASelected, AHovered: boolean);
var
  W0, W1, W2, W3: TPointF;
  P0, P1, P2, P3: TPoint;
  Handled: boolean;
begin
  if (ALink = nil) or (ALink.FromPin = nil) or (ALink.ToPin = nil) then
    Exit;

  GetLinkBezierWorldPoints(ALink, W0, W1, W2, W3);

  P0 := WorldToScreen(W0.X, W0.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  P1 := WorldToScreen(W1.X, W1.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  P2 := WorldToScreen(W2.X, W2.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
  P3 := WorldToScreen(W3.X, W3.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);

  Handled := False;
  if Assigned(AContext.OnDrawLink) then
    AContext.OnDrawLink(AContext.Sender, AContext.EventCanvas, ALink,
      P0, P1, P2, P3, ASelected, AHovered, Handled);

  if not Handled then
    DefaultDrawLink(ALink, P0, P1, P2, P3, ASelected, AHovered, AContext);
end;

procedure TAbstractNodeEditorRenderer.DrawTempBezier(const AContext: TRenderContext;
  const P0, P1, P2, P3: TPoint);
begin
  SetPen(AContext, FStyle.TempLinkColor, FStyle.TempLinkThickness, FStyle.TempLinkStyle);
  DrawBezierPolyline(AContext, P0, P1, P2, P3);
end;

procedure TAbstractNodeEditorRenderer.DrawBoxSelectRect(const AContext: TRenderContext;
  const R: TRect);
begin
  SetBrush(AContext, clNone, bsClear);
  SetPen(AContext, FStyle.BoxSelectColor, FStyle.BoxSelectWidth, FStyle.BoxSelectStyle);
  RectangleEx(AContext, R);
end;

procedure TAbstractNodeEditorRenderer.DrawSnapGuideLines(const AContext: TRenderContext);
var
  SX, SY: integer;
  Handled: boolean;
begin
  Handled := False;
  if Assigned(AContext.OnDrawSnapGuides) and Assigned(AContext.GDICanvas) then
    AContext.OnDrawSnapGuides(AContext.Sender, AContext.GDICanvas,
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

procedure TAbstractNodeEditorRenderer.DrawResizeHandle(const AContext: TRenderContext;
  const R: TRect);
begin
  SetBrush(AContext, FStyle.ResizeHandleBrushColor, bsSolid);
  SetPen(AContext, FStyle.ResizeHandlePenColor, 1, psSolid);
  RectangleEx(AContext, R);
end;

procedure TAbstractNodeEditorRenderer.DefaultDrawNode(ANode: TCustomNode;
  const ARect: TRect; const AContext: TRenderContext);
var
  R, HeaderR, BodyR: TRect;
  HeaderH: integer;
begin
  if ANode = nil then
    Exit;

  R := ARect;
  HeaderH := Max(20, Round(28 * AContext.Zoom));

  if ANode.Collapsed and (ANode.VisualKind = nvNormal) then
    R.Bottom := R.Top + HeaderH;

  if ANode.VisualKind = nvReroute then
  begin
    SetPen(AContext, clBlack, 1, psSolid);
    SetBrush(AContext, clWhite, bsSolid);

    if ANode.Selected then
    begin
      SetBrush(AContext, clNone, bsClear);
      SetPen(AContext, FStyle.NodeSelectedBorderColor, Max(2, Round(3 * AContext.Zoom)), psSolid);
      EllipseEx(AContext, R.Left - 5, R.Top - 5, R.Right + 5, R.Bottom + 5);
    end
    else if ANode.Highlighted then
    begin
      SetBrush(AContext, clNone, bsClear);
      SetPen(AContext, FStyle.NodeHighlightBorderColor, Max(2, Round(3 * AContext.Zoom)), psSolid);
      EllipseEx(AContext, R.Left - 4, R.Top - 4, R.Right + 4, R.Bottom + 4);
    end
    else if ANode.Hovered then
    begin
      SetBrush(AContext, clNone, bsClear);
      SetPen(AContext, FStyle.NodeHoverBorderColor, Max(1, Round(2 * AContext.Zoom)), psSolid);
      EllipseEx(AContext, R.Left - 3, R.Top - 3, R.Right + 3, R.Bottom + 3);
    end;

    SetBrush(AContext, FStyle.RerouteOuterColor, bsSolid);
    SetPen(AContext, FStyle.RerouteBorderColor, Max(1, Round(2 * AContext.Zoom)), psSolid);
    EllipseEx(AContext, R.Left, R.Top, R.Right, R.Bottom);

    SetBrush(AContext, FStyle.RerouteInnerColor, bsSolid);
    SetPen(AContext, FStyle.RerouteCenterBorderColor, 1, psSolid);
    EllipseEx(AContext,
      R.Left + Round(6 * AContext.Zoom),
      R.Top + Round(6 * AContext.Zoom),
      R.Right - Round(6 * AContext.Zoom),
      R.Bottom - Round(6 * AContext.Zoom));

    SetPen(AContext, FStyle.RerouteLineColor, Max(1, Round(2 * AContext.Zoom)), psSolid);
    MoveToEx(AContext, R.Left - Round(10 * AContext.Zoom), (R.Top + R.Bottom) div 2);
    LineToEx(AContext, R.Left + Round(5 * AContext.Zoom), (R.Top + R.Bottom) div 2);
    MoveToEx(AContext, R.Right - Round(5 * AContext.Zoom), (R.Top + R.Bottom) div 2);
    LineToEx(AContext, R.Right + Round(10 * AContext.Zoom), (R.Top + R.Bottom) div 2);

    ResetCanvasState(AContext);
    Exit;
  end;

  if ANode.VisualKind = nvComment then
  begin
    if ANode.Selected then
      SetPen(AContext, FStyle.CommentSelectedBorderColor, 3, psSolid)
    else if ANode.Highlighted then
      SetPen(AContext, FStyle.CommentHighlightBorderColor, 2, psSolid)
    else if ANode.Hovered then
      SetPen(AContext, FStyle.CommentHoverBorderColor, 2, psSolid)
    else
      SetPen(AContext, ANode.HeaderColor, 2, psSolid);

    SetBrush(AContext, ANode.BodyColor, bsSolid);
    RectangleEx(AContext, R);

    HeaderR := Rect(R.Left, R.Top, R.Right, R.Top + Max(18, Round(24 * AContext.Zoom)));
    SetBrush(AContext, ANode.HeaderColor, bsSolid);
    FillRectEx(AContext, HeaderR);

    SetFont(AContext, clBlack, Max(7, Round(10 * AContext.Zoom)));
    SetBrush(AContext, clNone, bsClear);
    TextOutEx(AContext, R.Left + 8, R.Top + 5, ANode.Title);

    if ANode.CommentText <> '' then
      TextOutEx(AContext, R.Left + 8, HeaderR.Bottom + 6, ANode.CommentText);

    ResetCanvasState(AContext);
    Exit;
  end;

  BodyR := R;
  SetBrush(AContext, ANode.BodyColor, bsSolid);
  SetPen(AContext, clNone, 1, psClear);
  RectangleEx(AContext, BodyR);

  HeaderR := Rect(R.Left, R.Top, R.Right, R.Top + HeaderH);
  SetBrush(AContext, ANode.HeaderColor, bsSolid);
  SetPen(AContext, clNone, 1, psClear);
  RectangleEx(AContext, HeaderR);

  SetBrush(AContext, clNone, bsClear);

  if ANode.Selected then
    SetPen(AContext, FStyle.NodeSelectedBorderColor, 3, psSolid)
  else if ANode.Highlighted then
    SetPen(AContext, FStyle.NodeHighlightBorderColor, 3, psSolid)
  else if ANode.Hovered then
    SetPen(AContext, FStyle.NodeHoverBorderColor, 1, psSolid)
  else
    SetPen(AContext, FStyle.NodeBorderColor, 1, psSolid);

  RectangleEx(AContext, R);

  SetFont(AContext, clBlack, Max(6, Round(10 * AContext.Zoom)));
  SetBrush(AContext, clNone, bsClear);
  TextOutEx(AContext, R.Left + 8, R.Top + Max(4, Round(6 * AContext.Zoom)), ANode.Title);

  ResetCanvasState(AContext);
end;

procedure TAbstractNodeEditorRenderer.DefaultDrawPin(APin: TNodePin;
  const Center: TPoint; Radius: integer; ASelected, AHovered, AHighlighted: boolean;
  const AContext: TRenderContext);
var
  FillColor: TColor;
  InnerRadius: integer;
begin
  if APin = nil then
    Exit;

  if APin.Kind = pkExec then
    FillColor := FStyle.PinExecColor
  else if APin.PinType <> nil then
    FillColor := APin.PinType.Color
  else
    FillColor := FStyle.PinDefaultColor;

  SetBrush(AContext, FillColor, bsSolid);
  SetPen(AContext, FStyle.PinBorderColor, FStyle.PinBorderWidth, psSolid);

  EllipseEx(AContext,
    Center.X - Radius, Center.Y - Radius,
    Center.X + Radius, Center.Y + Radius);

  if APin.Connected then
  begin
    InnerRadius := Max(2, Radius div 2);

    if APin.AllowMultipleConnections then
      SetBrush(AContext, clWhite, bsSolid)
    else
      SetBrush(AContext, FStyle.PinBorderColor, bsSolid);

    SetPen(AContext, clNone, 1, psClear);
    EllipseEx(AContext,
      Center.X - InnerRadius, Center.Y - InnerRadius,
      Center.X + InnerRadius, Center.Y + InnerRadius);
  end;

  if ASelected then
  begin
    SetBrush(AContext, clNone, bsClear);
    SetPen(AContext, FStyle.PinSelectedColor, Max(2, FStyle.PinBorderWidth + 1), psSolid);
    EllipseEx(AContext,
      Center.X - Radius - 3, Center.Y - Radius - 3,
      Center.X + Radius + 3, Center.Y + Radius + 3);
  end
  else if AHovered or AHighlighted then
  begin
    SetBrush(AContext, clNone, bsClear);
    SetPen(AContext, FStyle.PinHoverColor, Max(2, FStyle.PinBorderWidth + 1), psSolid);
    EllipseEx(AContext,
      Center.X - Radius - 2, Center.Y - Radius - 2,
      Center.X + Radius + 2, Center.Y + Radius + 2);
  end;

  ResetCanvasState(AContext);
end;

procedure TAbstractNodeEditorRenderer.DefaultDrawLink(ALink: TNodeLink;
  const P0, P1, P2, P3: TPoint; ASelected, AHovered: boolean;
  const AContext: TRenderContext);
begin
  if ASelected then
    SetPen(AContext, FStyle.LinkSelectedColor, FStyle.LinkSelectedThickness, psSolid)
  else if AHovered then
    SetPen(AContext, FStyle.LinkHoverColor, FStyle.LinkSelectedThickness, psSolid)
  else
    SetPen(AContext, FStyle.LinkColor, FStyle.LinkThickness, psSolid);

  DrawBezierPolyline(AContext, P0, P1, P2, P3);
  ResetCanvasState(AContext);
end;

procedure TAbstractNodeEditorRenderer.DrawBezierPolyline(const AContext: TRenderContext;
  const P0, P1, P2, P3: TPoint; ASteps: integer);
var
  i: integer;
  pts: array of TPoint;
  t: single;
begin
  SetLength(pts, ASteps + 1);
  for i := 0 to ASteps do
  begin
    t := i / ASteps;
    pts[i] := Point(
      Round(Power(1 - t, 3) * P0.X + 3 * Power(1 - t, 2) * t * P1.X +
            3 * (1 - t) * t * t * P2.X + Power(t, 3) * P3.X),
      Round(Power(1 - t, 3) * P0.Y + 3 * Power(1 - t, 2) * t * P1.Y +
            3 * (1 - t) * t * t * P2.Y + Power(t, 3) * P3.Y)
    );
  end;

  if AContext.HasGDI then
    AContext.GDICanvas.Polyline(pts)
  else if AContext.HasGL then
    AContext.GLCanvas.Polyline(pts);
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

procedure TAbstractNodeEditorRenderer.MoveToEx(const AContext: TRenderContext; X, Y: integer);
begin
  if AContext.HasGDI then
    AContext.GDICanvas.MoveTo(X, Y)
  else if AContext.HasGL then
    AContext.GLCanvas.MoveTo(X, Y);
end;

procedure TAbstractNodeEditorRenderer.LineToEx(const AContext: TRenderContext; X, Y: integer);
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

procedure TAbstractNodeEditorRenderer.EllipseEx(const AContext: TRenderContext;
  L, T, R, B: integer);
begin
  if AContext.HasGDI then
    AContext.GDICanvas.Ellipse(L, T, R, B)
  else if AContext.HasGL then
    AContext.GLCanvas.Ellipse(L, T, R, B);
end;

procedure TAbstractNodeEditorRenderer.TextOutEx(const AContext: TRenderContext;
  X, Y: integer; const S: string);
begin
  if AContext.HasGDI then
    AContext.GDICanvas.TextOut(X, Y, S)
  else if AContext.HasGL then
    AContext.GLCanvas.TextOut(X, Y, S);
end;

function TAbstractNodeEditorRenderer.TextWidthEx(const AContext: TRenderContext;
  const S: string): integer;
begin
  if AContext.HasGDI then
    Result := AContext.GDICanvas.TextWidth(S)
  else if AContext.HasGL then
    Result := AContext.GLCanvas.TextWidth(S)
  else
    Result := 0;
end;

function TAbstractNodeEditorRenderer.TextHeightEx(const AContext: TRenderContext;
  const S: string): integer;
begin
  if AContext.HasGDI then
    Result := AContext.GDICanvas.TextHeight(S)
  else if AContext.HasGL then
    Result := AContext.GLCanvas.TextHeight(S)
  else
    Result := 0;
end;

function TAbstractNodeEditorRenderer.GetNodeScreenBounds(ANode: TCustomNode;
  const AContext: TRenderContext): TRect;
begin
  Result := ANode.GetScreenBounds(AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
end;

function TAbstractNodeEditorRenderer.GetResizeHandleRect(ANode: TCustomNode;
  const AContext: TRenderContext): TRect;
var
  R: TRect;
  S: integer;
begin
  R := GetNodeScreenBounds(ANode, AContext);
  S := Max(10, Round(AContext.ResizeHandleSize * AContext.Zoom));
  Result := Rect(R.Right - S, R.Bottom - S, R.Right + 1, R.Bottom + 1);
end;

function TAbstractNodeEditorRenderer.GetPinScreenCenter(APin: TNodePin;
  const AContext: TRenderContext): TPoint;
var
  P: TPointF;
begin
  P := GetPinWorldPosition(APin);
  Result := WorldToScreen(P.X, P.Y, AContext.Zoom, AContext.OffsetX, AContext.OffsetY);
end;

function TAbstractNodeEditorRenderer.WorldToScreen(WX, WY: single; AZoom,
  AOffsetX, AOffsetY: double): TPoint;
begin
  Result.X := Round(WX * AZoom + AOffsetX);
  Result.Y := Round(WY * AZoom + AOffsetY);
end;

function TAbstractNodeEditorRenderer.GetPinWorldPosition(APin: TNodePin): TPointF;
begin
  if (APin = nil) or (APin.OwnerNode = nil) then
    Exit(PointF(0, 0));
  Result := TCustomNode(APin.OwnerNode).GetPinWorldPosition(APin);
end;

procedure TAbstractNodeEditorRenderer.GetLinkBezierWorldPoints(ALink: TNodeLink;
  out P0, P1, P2, P3: TPointF);
var
  DX, DY: single;
  Dist: single;
  D: single;
begin
  P0 := GetPinWorldPosition(ALink.FromPin);
  P3 := GetPinWorldPosition(ALink.ToPin);

  DX := P3.X - P0.X;
  DY := P3.Y - P0.Y;
  Dist := Hypot(DX, DY);

  D := Dist * 0.35;
  D := EnsureRange(D, 30, 150);

  P1 := P0;
  P1.X := P1.X + D;

  P2 := P3;
  P2.X := P2.X - D;
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
    rbGDI:
      Result := TGDIRenderer.Create;
    rbOpenGL2D:
      Result := TOpenGLNodeEditorRenderer.Create;
  else
    Result := TGDIRenderer.Create;
  end;
end;

end.
