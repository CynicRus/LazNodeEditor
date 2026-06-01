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
unit LazNodeEditor.Editor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, ExtCtrls, LCLIntf, LCLType, Math, Types,
  Menus, Clipbrd, Forms, StdCtrls, Dialogs,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.GraphCommands,
  LazNodeEditor.Selection,
  LazNodeEditor.Controller,
  LazNodeEditor.Viewport,
  LazNodeEditor.Renderer,
  LazNodeEditor.InteractionIntf,
  LazNodeEditor.Interaction,
  LazNodeEditor.LinkRouter,
  GL2DCanvas, LazNodeEditor.GLCanvasProxy;

type
  TEditorAction = (
    eaNone,
    eaDeleteSelection,
    eaUndo,
    eaRedo,
    eaCopy,
    eaPaste,
    eaDuplicate,
    eaFrame,
    eaConnectPins,
    eaSelectAll,
    eaSelectAllLinks,

    eaAlignLeft,
    eaAlignRight,
    eaAlignTop,
    eaAlignBottom,
    eaAlignCenterH,
    eaAlignCenterV,

    eaDistributeH,
    eaDistributeV,

    eaSameWidth,
    eaSameHeight,
    eaSameSize
  );

  TNodeSelectionChangedEvent = procedure(Sender: TObject) of object;
  TNodeChangedEvent = procedure(Sender: TObject; ANode: TCustomNode) of object;
  TNodePinEvent = procedure(Sender: TObject; APin: TNodePin) of object;
  TNodeLinkEvent = procedure(Sender: TObject; ALink: TNodeLink) of object;
  TEditorConnectPinsEvent = procedure(Sender: TObject; AFromPin, AToPin: TNodePin;
    var AAllow: boolean) of object;
  TEditorPinsConnectedEvent = procedure(Sender: TObject;
    AFromPin, AToPin: TNodePin) of object;
  TEditorZoomChangedEvent = procedure(Sender: TObject) of object;

  { TLazNodeEditor }

  TLazNodeEditor = class(TCustomControl, INodeEditorInteractionHost)
  private
    FGraph: TNodeGraph;
    FController: TNodeEditorController;
    FMinDetailZoom: double;
    FMinPinLabelZoom: double;
    FMinTitleZoom: double;
    FViewport: TNodeViewport;
    FRenderer: INodeEditorRenderer;
    FRenderContext: TRenderContext;
    FInteraction: TInteractionStateMachine;

    FHoveredNode: TCustomNode;
    FHoveredPin: TNodePin;
    FHoveredLink: TNodeLink;
    FHoveredPinCompatible: boolean;
    FLastHoverX, FLastHoverY: integer;

    FEditorPopupMenu: TPopupMenu;
    FContextWorldPos: TPointF;

    FSnapToGrid: boolean;
    FSnapToNodes: boolean;
    FNodeSnapDistance: single;
    FShowSnapGuides: boolean;
    FGuideSnapXActive: boolean;
    FGuideSnapYActive: boolean;
    FGuideSnapX: single;
    FGuideSnapY: single;

    FPaintNodesSorted: TList;
    FPaintNodesDirty: boolean;
    FLastPaintTick: QWord;

    FAntiAliasing: boolean;
    FGLControl: TGLCanvasControl;
    FGLCanvasProxy: TGLCanvasProxy;

    FOnDrawNode: TRenderNodeDrawEvent;
    FOnDrawPin: TRenderPinDrawEvent;
    FOnDrawLink: TRenderLinkDrawEvent;
    FOnDrawGrid: TRenderGridDrawEvent;
    FOnDrawSnapGuides: TRenderSnapGuidesDrawEvent;

    FOnSelectionChanged: TNodeSelectionChangedEvent;
    FOnZoomChanged: TEditorZoomChangedEvent;
    FOnNodeChanged: TNodeChangedEvent;
    FOnPinSelectionChanged: TNotifyEvent;
    FOnPinClick: TNodePinEvent;
    FOnLinkClick: TNodeLinkEvent;
    FOnBeforeConnectPins: TEditorConnectPinsEvent;
    FOnAfterConnectPins: TEditorPinsConnectedEvent;

    function GetLinkDrawStyle: TLinkDrawStyle;
    function GetRendererStyle: TRenderStyle;
    function GetZoom: double;
    function GetZoomStep: double;
    procedure SetLinkDrawStyle(AValue: TLinkDrawStyle);
    procedure SetOnDrawGrid(AValue: TRenderGridDrawEvent);
    procedure SetOnDrawLink(AValue: TRenderLinkDrawEvent);
    procedure SetOnDrawNode(AValue: TRenderNodeDrawEvent);
    procedure SetOnDrawPin(AValue: TRenderPinDrawEvent);
    procedure SetZoom(AValue: double);
    procedure SetZoomStep(AValue: double);
    procedure SetAntiAliasing(AValue: boolean);

    procedure BuildRenderContext;
    procedure GLControlPaint(Sender: TObject);
    procedure NodeGraphChanged(Sender: TObject);
    procedure ControllerSelectionChanged(Sender: TObject); deprecated;
    procedure DoPinSelectionChanged(Sender: TObject);

    procedure InvalidateSortedNodes;
    procedure EnsureSortedNodes;

    procedure BuildContextMenu;
    procedure OnAddRegisteredNodeClick(Sender: TObject);
    procedure OnContextCopy(Sender: TObject);
    procedure OnContextPaste(Sender: TObject);
    procedure OnContextDuplicate(Sender: TObject);
    procedure OnContextDelete(Sender: TObject);
    procedure OnContextSearchNode(Sender: TObject);
    procedure OnContextInsertReroute(Sender: TObject);
    procedure OnContextAddComment(Sender: TObject);
    procedure OnPopupClose(Sender: TObject);

    {$IFNDEF MSWINDOWS}
    procedure GLMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure GLMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure GLMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure GLMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: integer; MousePos: TPoint; var Handled: boolean);
    procedure GLMouseEnter(Sender: TObject);
    procedure GLMouseLeave(Sender: TObject);
    {$ENDIF}

  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: integer;
      MousePos: TPoint): boolean; override;
    procedure KeyDown(var Key: word; Shift: TShiftState); override;
    procedure DoExit; override;
    procedure MouseLeave; override;
    procedure Resize; override;
    function ResolveShortcut(Key: Word; Shift: TShiftState): TEditorAction; virtual;
    function ExecuteEditorAction(AAction: TEditorAction): Boolean; virtual;
    procedure SelectNodeInternal(ANode: TCustomNode; AAppend: boolean);
    procedure SelectLinkInternal(ALink: TNodeLink; AKeepNodes: boolean = False);
    procedure ClearSelectionInternal;
    procedure AddNodeToSelection(ANode: TCustomNode);
    procedure RemoveNodeFromSelection(ANode: TCustomNode);
    procedure AddLinkToSelection(ALink: TNodeLink);
    procedure RemoveLinkFromSelection(ALink: TNodeLink);
    procedure ToggleNodeSelection(ANode: TCustomNode);
    procedure ToggleLinkSelection(ALink: TNodeLink);
    procedure SelectPinInternal(APin: TNodePin; AAppend: boolean);
    procedure TogglePinSelection(APin: TNodePin);
    procedure ClearPinSelection;

    procedure NotifySelectionChanged;

    function SnapWorldValue(V: single): single;
    function SnapWorldPoint(const P: TPointF): TPointF;
    procedure ApplyNodeSnap(var AOffsetX, AOffsetY: single;
      out ASnappedX, ASnappedY: boolean);
    procedure ClearSnapGuides;

    procedure UpdateHoverStates(SX, SY: integer);
    procedure ClearHoverStates;
    function IsHoverPosChanged(X, Y: integer): boolean; inline;
    procedure SetLastHoverPos(X, Y: integer); inline;

    function ScreenToWorld(SX, SY: integer): TPointF; inline;

    procedure SetCursor(ACursor: TCursor);
    procedure SetMouseCapture(AValue: boolean);

    function GetOnPinClickAssigned: boolean;
    procedure DoPinClick(APin: TNodePin);
    function GetOnLinkClickAssigned: boolean;
    procedure DoLinkClick(ALink: TNodeLink);
    function BeforeConnectPins(AFromPin, AToPin: TNodePin): boolean;
    procedure AfterConnectPins(AFromPin, AToPin: TNodePin);
    procedure DoNodeChanged(ANode: TCustomNode);

    function GetContextWorldPos: TPointF;
    procedure SetContextWorldPos(const AValue: TPointF);
    procedure PopupContextMenu(AScreenX, AScreenY: integer);
    function GetSnapToGrid(): boolean;
    function GetSnapToNodes(): boolean;

    function HitTestNodeAt(SX, SY: integer): TCustomNode;
    function HitTestPinAt(SX, SY: integer; out ANode: TCustomNode): TNodePin;
    function HitTestLinkAt(SX, SY: integer): TNodeLink;
    function HitTestResizeHandleAt(SX, SY: integer): TCustomNode;
    function IsLinkInsideWorldRect(ALink: TNodeLink; const R: TRectF): boolean;
    function IsMouseNearLinkStart(ALink: TNodeLink; SX, SY: integer): boolean;

    procedure UpdatePinsConnectedState;
    function CanPinAcceptMoreConnections(APin: TNodePin): boolean;

    procedure ShowNodeSearchPopup(AScreenX, AScreenY: integer;
      AWorldX, AWorldY: single);
    procedure SyncControllerSelectionToView; deprecated;
    procedure SyncNodeSelectedFlags;

    function GetPrimarySelectedNode: TCustomNode;
    function GetPrimarySelectedLink: TNodeLink;
    function CanConnectSelectedPins: boolean;
    procedure ConnectSelectedPins;

    procedure RequestRepaint(const AForce: boolean = False);

    procedure ResetStateAfterGraphReload;

    property EditorPopupMenu: TPopupMenu read FEditorPopupMenu;
    property ContextWorldPos: TPointF read FContextWorldPos write FContextWorldPos;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddNode(ANode: TCustomNode);
    procedure RemoveNode(ANode: TCustomNode);
    procedure RemoveLink(ALink: TNodeLink);
    procedure Clear;

    procedure ClearSelection;
    procedure DeleteSelection;
    procedure SelectNode(ANode: TCustomNode; AAppend: boolean);
    procedure SelectLink(ALink: TNodeLink);
    function SelectedNodeCount: integer;
    function SelectedLinkCount: integer;
    function GetSelectedNode(Index: integer): TCustomNode;
    function IsLinkSelected(ALink: TNodeLink): boolean;

    procedure FitToSelection;
    procedure FrameAll;
    procedure Undo;
    procedure Redo;

    procedure CopySelectionToClipboard;
    procedure PasteFromClipboard;
    procedure DuplicateSelection;

    function SaveToJSONText: string;
    procedure LoadFromJSONText(const S: string);
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);

    function ValidateGraphToStrings(AStrings: TStrings): boolean;

    function AddInputPinToNode(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function AddOutputPinToNode(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function RemovePinFromNode(APin: TNodePin): boolean;

    procedure Invalidate; override;

    property Graph: TNodeGraph read FGraph;
    property Zoom: double read GetZoom write SetZoom;
    property ZoomStep: double read GetZoomStep write SetZoomStep;
    property Controller: TNodeEditorController read FController;
    property Viewport: TNodeViewport read FViewport;
    property Renderer: INodeEditorRenderer read FRenderer;

  published
    property Align;
    property Anchors;
    property Color;
    property TabStop default True;
    property PopupMenu;
    property AntiAliasing: boolean
      read FAntiAliasing write SetAntiAliasing default False;
    property Style: TRenderStyle read GetRendererStyle;
    property SnapToGrid: boolean read FSnapToGrid write FSnapToGrid default False;
    property ShowSnapGuides: boolean read FShowSnapGuides
      write FShowSnapGuides default True;
    property SnapToNodes: boolean read FSnapToNodes write FSnapToNodes default True;
    property NodeSnapDistance: single read FNodeSnapDistance write FNodeSnapDistance;
    property MinTitleZoom: double read FMinTitleZoom write FMinTitleZoom;
    property MinPinLabelZoom: double read FMinPinLabelZoom
      write FMinPinLabelZoom;
    property MinDetailLevelZoom: double read FMinDetailZoom write FMinDetailZoom;

    property OnSelectionChanged: TNodeSelectionChangedEvent
      read FOnSelectionChanged write FOnSelectionChanged;
    property OnZoomChanged: TEditorZoomChangedEvent
      read FOnZoomChanged write FOnZoomChanged;
    property OnNodeChanged: TNodeChangedEvent read FOnNodeChanged write FOnNodeChanged;
    property OnDrawNode: TRenderNodeDrawEvent read FOnDrawNode write SetOnDrawNode;
    property OnDrawPin: TRenderPinDrawEvent read FOnDrawPin write SetOnDrawPin;
    property OnDrawLink: TRenderLinkDrawEvent read FOnDrawLink write SetOnDrawLink;
    property OnDrawGrid: TRenderGridDrawEvent read FOnDrawGrid write SetOnDrawGrid;
    property OnDrawSnapGuides: TRenderSnapGuidesDrawEvent
      read FOnDrawSnapGuides write FOnDrawSnapGuides;
    property OnPinSelectionChanged: TNotifyEvent
      read FOnPinSelectionChanged write FOnPinSelectionChanged;
    property OnPinClick: TNodePinEvent read FOnPinClick write FOnPinClick;
    property OnLinkClick: TNodeLinkEvent read FOnLinkClick write FOnLinkClick;
    property OnBeforeConnectPins: TEditorConnectPinsEvent
      read FOnBeforeConnectPins write FOnBeforeConnectPins;
    property OnAfterConnectPins: TEditorPinsConnectedEvent
      read FOnAfterConnectPins write FOnAfterConnectPins;
    property LinkDrawStyle: TLinkDrawStyle read GetLinkDrawStyle
      write SetLinkDrawStyle default ldsBezier;

  end;

function NodeVisualLayer(ANode: TCustomNode): integer; inline;
function NodePaintCompare(Item1, Item2: Pointer): integer;
function LinkSortKey(ALink: TNodeLink): integer; inline;

implementation

function PtInRectF(const Pt: TPointF; const R: TRectF): boolean; inline;
begin
  Result := (Pt.X >= R.Left) and (Pt.X <= R.Right) and (Pt.Y >= R.Top) and
    (Pt.Y <= R.Bottom);
end;

function RectFIntersects(const R1, R2: TRectF): boolean; inline;
begin
  Result := not ((R1.Right < R2.Left) or (R1.Left > R2.Right) or
    (R1.Bottom < R2.Top) or (R1.Top > R2.Bottom));
end;

function LineIntersectsRectF(P1, P2: TPointF; const R: TRectF): boolean;
var
  Dx, Dy, T0, T1: single;

  function Clip(P, Q: single; var T0, T1: single): boolean;
  var
    Rr: single;
  begin
    if Abs(P) < 1e-6 then Exit(Q >= 0);
    Rr := Q / P;
    if P < 0 then
    begin
      if Rr > T1 then Exit(False);
      if Rr > T0 then T0 := Rr;
    end
    else
    begin
      if Rr < T0 then Exit(False);
      if Rr < T1 then T1 := Rr;
    end;
    Result := True;
  end;

begin
  if PtInRectF(P1, R) or PtInRectF(P2, R) then Exit(True);
  Dx := P2.X - P1.X;
  Dy := P2.Y - P1.Y;
  T0 := 0;
  T1 := 1;
  Result :=
    Clip(-Dx, P1.X - R.Left, T0, T1) and Clip(Dx, R.Right - P1.X, T0, T1) and
    Clip(-Dy, P1.Y - R.Top, T0, T1) and Clip(Dy, R.Bottom - P1.Y, T0, T1);
end;

function NodeVisualLayer(ANode: TCustomNode): integer; inline;
begin
  if ANode = nil then
    Exit(0);

  case ANode.VisualKind of
    nvComment: Result := 0;
    nvNormal: Result := 1;
    nvReroute: Result := 2;
    else
      Result := 1;
  end;
end;

function NodePaintCompare(Item1, Item2: Pointer): integer;
var
  N1, N2: TCustomNode;
  L1, L2: integer;
begin
  N1 := TCustomNode(Item1);
  N2 := TCustomNode(Item2);
  if N1 = N2 then Exit(0);
  if N1 = nil then Exit(-1);
  if N2 = nil then Exit(1);

  L1 := NodeVisualLayer(N1);
  L2 := NodeVisualLayer(N2);

  Result := L1 - L2;
  if Result = 0 then
    Result := N1.ZOrder - N2.ZOrder;
  if Result = 0 then
    Result := PtrUInt(N1) - PtrUInt(N2);
end;

function LinkSortKey(ALink: TNodeLink): integer; inline;
var
  N1, N2: TCustomNode;
begin
  Result := 0;
  if ALink = nil then
    Exit;

  N1 := nil;
  N2 := nil;

  if (ALink.FromPin <> nil) and (ALink.FromPin.OwnerNode is TCustomNode) then
    N1 := TCustomNode(ALink.FromPin.OwnerNode);
  if (ALink.ToPin <> nil) and (ALink.ToPin.OwnerNode is TCustomNode) then
    N2 := TCustomNode(ALink.ToPin.OwnerNode);

  if (N1 <> nil) and (N2 <> nil) then
    Result := Max(N1.ZOrder, N2.ZOrder)
  else if N1 <> nil then
    Result := N1.ZOrder
  else if N2 <> nil then
    Result := N2.ZOrder;
end;

constructor TLazNodeEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FGraph := TNodeGraph.Create;
  FGraph.OnGraphChanged := @NodeGraphChanged;

  FController := TNodeEditorController.Create(FGraph);
  FController.Selection.OnChanged := @ControllerSelectionChanged;
  FController.PinSelection.OnChanged := @DoPinSelectionChanged;

  FViewport := TNodeViewport.Create;
  FRenderer := TNodeEditorRendererFactory.CreateRenderer(rbGDI);

  FRenderContext := TRenderContext.Create;
  FRenderContext.Sender := Self;

  FInteraction := TInteractionStateMachine.Create(Self, FController, FViewport, FGraph);

  FPaintNodesSorted := TList.Create;
  FPaintNodesDirty := True;

  FSnapToGrid := False;
  FSnapToNodes := True;
  FNodeSnapDistance := 10.0;
  FShowSnapGuides := True;

  FMinTitleZoom := 0.45;
  FMinPinLabelZoom := 0.75;
  FMinDetailZoom := 0.25;

  FLastHoverX := Low(integer);
  FLastHoverY := Low(integer);

  Color := FRenderer.Style.BackgroundColor;
  DoubleBuffered := True;
  TabStop := True;

  FEditorPopupMenu := TPopupMenu.Create(Self);
  FEditorPopupMenu.OnClose := @OnPopupClose;

  FAntiAliasing := False;
  FGLControl := nil;
  FGLCanvasProxy := nil;

  UpdatePinsConnectedState;
  BuildContextMenu;
end;

destructor TLazNodeEditor.Destroy;
begin
  FInteraction.Free;
  FPaintNodesSorted.Free;
  FController.Free;
  FViewport.Free;
  FRenderContext.Free;
  FGraph.Free;
  FreeAndNil(FGLControl);
  FreeAndNil(FGLCanvasProxy);
  inherited Destroy;
end;

function TLazNodeEditor.ScreenToWorld(SX, SY: integer): TPointF;
begin
  Result := FViewport.ScreenToWorld(SX, SY);
end;

procedure TLazNodeEditor.SetCursor(ACursor: TCursor);
begin
  Cursor := ACursor;
  if Assigned(FGLControl) then
    FGLControl.Cursor := ACursor;
end;

procedure TLazNodeEditor.SetMouseCapture(AValue: boolean);
begin
  MouseCapture := AValue;
end;

function TLazNodeEditor.GetOnPinClickAssigned: boolean;
begin
  Result := Assigned(FOnPinClick);
end;

procedure TLazNodeEditor.DoPinClick(APin: TNodePin);
begin
  if Assigned(FOnPinClick) then
    FOnPinClick(Self, APin);
end;

function TLazNodeEditor.GetOnLinkClickAssigned: boolean;
begin
  Result := Assigned(FOnLinkClick);
end;

procedure TLazNodeEditor.DoLinkClick(ALink: TNodeLink);
begin
  if Assigned(FOnLinkClick) then
    FOnLinkClick(Self, ALink);
end;

function TLazNodeEditor.BeforeConnectPins(AFromPin, AToPin: TNodePin): boolean;
begin
  Result := True;
  if Assigned(FOnBeforeConnectPins) then
    FOnBeforeConnectPins(Self, AFromPin, AToPin, Result);
end;

procedure TLazNodeEditor.AfterConnectPins(AFromPin, AToPin: TNodePin);
begin
  if Assigned(FOnAfterConnectPins) then
    FOnAfterConnectPins(Self, AFromPin, AToPin);
end;

procedure TLazNodeEditor.DoNodeChanged(ANode: TCustomNode);
begin
  if Assigned(FOnNodeChanged) then
    FOnNodeChanged(Self, ANode);
end;

function TLazNodeEditor.GetContextWorldPos: TPointF;
begin
  Result := FContextWorldPos;
end;

procedure TLazNodeEditor.SetContextWorldPos(const AValue: TPointF);
begin
  FContextWorldPos := AValue;
end;

procedure TLazNodeEditor.PopupContextMenu(AScreenX, AScreenY: integer);
begin
  if Assigned(FEditorPopupMenu) then
    FEditorPopupMenu.PopUp(AScreenX, AScreenY);
end;

function TLazNodeEditor.GetSnapToGrid(): boolean;
begin
  Result := FSnapToGrid;
end;

function TLazNodeEditor.GetSnapToNodes(): boolean;
begin
  Result := FSnapToNodes;
end;

function TLazNodeEditor.IsHoverPosChanged(X, Y: integer): boolean;
begin
  Result := (X <> FLastHoverX) or (Y <> FLastHoverY);
end;

procedure TLazNodeEditor.SetLastHoverPos(X, Y: integer);
begin
  FLastHoverX := X;
  FLastHoverY := Y;
end;

function TLazNodeEditor.GetRendererStyle: TRenderStyle;
begin
  Result := FRenderer.Style;
end;

function TLazNodeEditor.GetLinkDrawStyle: TLinkDrawStyle;
begin
  Result := FGraph.DefaultLinkDrawStyle;
end;

procedure TLazNodeEditor.SetLinkDrawStyle(AValue: TLinkDrawStyle);
begin
  if FGraph.DefaultLinkDrawStyle = AValue then
    Exit;
  FGraph.DefaultLinkDrawStyle := AValue;
  Invalidate;
end;

function TLazNodeEditor.GetZoom: double;
begin
  Result := FViewport.Zoom;
end;

function TLazNodeEditor.GetZoomStep: double;
begin
  Result := FViewport.ZoomStep;
end;

procedure TLazNodeEditor.SetOnDrawGrid(AValue: TRenderGridDrawEvent);
begin
  if FOnDrawGrid = AValue then Exit;
  FOnDrawGrid := AValue;
end;

procedure TLazNodeEditor.SetOnDrawLink(AValue: TRenderLinkDrawEvent);
begin
  if FOnDrawLink = AValue then Exit;
  FOnDrawLink := AValue;
end;

procedure TLazNodeEditor.SetOnDrawNode(AValue: TRenderNodeDrawEvent);
begin
  if FOnDrawNode = AValue then Exit;
  FOnDrawNode := AValue;
end;

procedure TLazNodeEditor.SetOnDrawPin(AValue: TRenderPinDrawEvent);
begin
  if FOnDrawPin = AValue then Exit;
  FOnDrawPin := AValue;
end;

procedure TLazNodeEditor.SetZoom(AValue: double);
begin
  if Abs(FViewport.Zoom - AValue) < 0.0001 then Exit;
  FViewport.Zoom := AValue;
  if Assigned(FOnZoomChanged) then
    FOnZoomChanged(Self);
  Invalidate;
end;

procedure TLazNodeEditor.SetZoomStep(AValue: double);
begin
  FViewport.ZoomStep := AValue;
end;

procedure TLazNodeEditor.SetAntiAliasing(AValue: boolean);
var
  OldStyle: TRenderStyle;
begin
  if FAntiAliasing = AValue then Exit;
  FAntiAliasing := AValue;
  OldStyle := FRenderer.Style;

  if FAntiAliasing then
  begin
    FRenderer := TNodeEditorRendererFactory.CreateRenderer(rbOpenGL2D);

    if FGLControl = nil then
    begin
      FGLControl := TGLCanvasControl.Create(Self);
      FGLControl.Parent := Self;
      FGLControl.Align := alClient;
      FGLControl.Enabled := False;
      FGLControl.OnDraw := @GLControlPaint;
      FGLControl.DoubleBuffered := True;
      FGLControl.Color := Self.Color;

      {$IFNDEF MSWINDOWS}
      FGLControl.Enabled      := True;
      FGLControl.OnMouseDown  := @GLMouseDown;
      FGLControl.OnMouseMove  := @GLMouseMove;
      FGLControl.OnMouseUp    := @GLMouseUp;
      FGLControl.OnMouseWheel := @GLMouseWheel;
      FGLControl.OnMouseEnter := @GLMouseEnter;
      FGLControl.OnMouseLeave := @GLMouseLeave;
      {$ENDIF}
    end;

    if FGLCanvasProxy = nil then
      FGLCanvasProxy := TGLCanvasProxy.Create(FGLControl.Canvas)
    else
      FGLCanvasProxy.Attach(FGLControl.Canvas);

    FGLControl.BringToFront;
    FGLControl.Invalidate;
  end
  else
  begin
    FRenderer := TNodeEditorRendererFactory.CreateRenderer(rbGDI);
    FreeAndNil(FGLCanvasProxy);
    FreeAndNil(FGLControl);
  end;

  FRenderer.Style.Assign(OldStyle);
  Invalidate;
end;

procedure TLazNodeEditor.GLControlPaint(Sender: TObject);
begin
  BuildRenderContext;
  FRenderer.Render(FRenderContext);
end;

procedure TLazNodeEditor.Invalidate;
begin
  if FAntiAliasing and Assigned(FGLControl) then
    FGLControl.Invalidate
  else
    inherited Invalidate;
end;

procedure TLazNodeEditor.Resize;
begin
  inherited Resize;
  if Assigned(FGLControl) then
    FGLControl.Invalidate;
end;

function TLazNodeEditor.ResolveShortcut(Key: Word; Shift: TShiftState): TEditorAction;
begin
  Result := eaNone;

  if Key = VK_DELETE then Exit(eaDeleteSelection);
  if Key = VK_ESCAPE then Exit(eaNone);

  if (Key = Ord('Z')) and (Shift = [ssCtrl]) then Exit(eaUndo);
  if (Key = Ord('Y')) and (Shift = [ssCtrl]) then Exit(eaRedo);
  if (Key = Ord('C')) and (Shift = [ssCtrl]) then Exit(eaCopy);
  if (Key = Ord('V')) and (Shift = [ssCtrl]) then Exit(eaPaste);
  if (Key = Ord('D')) and (Shift = [ssCtrl]) then Exit(eaDuplicate);
  if (Key = Ord('L')) and (Shift = [ssCtrl]) then Exit(eaConnectPins);
  if (Key = Ord('A')) and (Shift = [ssCtrl]) then Exit(eaSelectAll);
  if (Key = Ord('A')) and (Shift = [ssShift]) then Exit(eaSelectAllLinks);

  if Key = Ord('F') then Exit(eaFrame);

  if Shift = [ssCtrl, ssShift] then
    case Key of
      Ord('L'): Exit(eaAlignLeft);
      Ord('R'): Exit(eaAlignRight);
      Ord('T'): Exit(eaAlignTop);
      Ord('B'): Exit(eaAlignBottom);
      Ord('H'): Exit(eaAlignCenterH);
      Ord('V'): Exit(eaAlignCenterV);
      Ord('W'): Exit(eaSameWidth);
      Ord('E'): Exit(eaSameHeight);
      Ord('S'): Exit(eaSameSize);
    end;

  if Shift = [ssCtrl, ssAlt] then
    case Key of
      Ord('H'): Exit(eaDistributeH);
      Ord('V'): Exit(eaDistributeV);
    end;
end;

function TLazNodeEditor.ExecuteEditorAction(AAction: TEditorAction): Boolean;
var
  i: Integer;
begin
  Result := True;

  case AAction of
    eaDeleteSelection:
      DeleteSelection;

    eaUndo:
      Undo;

    eaRedo:
      Redo;

    eaCopy:
      CopySelectionToClipboard;

    eaPaste:
      begin
        FContextWorldPos := FViewport.ScreenToWorld(ClientWidth div 2, ClientHeight div 2);
        PasteFromClipboard;
      end;

    eaDuplicate:
      DuplicateSelection;

    eaFrame:
      begin
        if FController.Selection.NodeCount > 0 then
          FitToSelection
        else
          FrameAll;
      end;

    eaConnectPins:
      ConnectSelectedPins;

    eaSelectAll:
      begin
        ClearSelectionInternal;
        FController.Selection.BeginUpdate;
        try
          for i := 0 to FGraph.Nodes.Count - 1 do
            FController.Selection.AddNodeToSelection(TCustomNode(FGraph.Nodes[i]));
          for i := 0 to FGraph.Links.Count - 1 do
            FController.Selection.AddLinkToSelection(TNodeLink(FGraph.Links[i]));
        finally
          FController.Selection.EndUpdate;
        end;
        NotifySelectionChanged;
        Invalidate;
      end;

    eaSelectAllLinks:
      begin
        ClearSelectionInternal;
        FController.Selection.BeginUpdate;
        try
          for i := 0 to FGraph.Links.Count - 1 do
            FController.Selection.AddLinkToSelection(TNodeLink(FGraph.Links[i]));
        finally
          FController.Selection.EndUpdate;
        end;
        NotifySelectionChanged;
        Invalidate;
      end;

    eaAlignLeft:      Controller.AlignSelectedNodes(amLeft);
    eaAlignRight:     Controller.AlignSelectedNodes(amRight);
    eaAlignTop:       Controller.AlignSelectedNodes(amTop);
    eaAlignBottom:    Controller.AlignSelectedNodes(amBottom);
    eaAlignCenterH:   Controller.AlignSelectedNodes(amCenterHorizontal);
    eaAlignCenterV:   Controller.AlignSelectedNodes(amCenterVertical);

    eaDistributeH:    Controller.DistributeSelectedNodes(dmHorizontal);
    eaDistributeV:    Controller.DistributeSelectedNodes(dmVertical);

    eaSameWidth:      Controller.MakeSelectedNodesSameSize(msmWidth);
    eaSameHeight:     Controller.MakeSelectedNodesSameSize(msmHeight);
    eaSameSize:       Controller.MakeSelectedNodesSameSize(msmBoth);

    else
      Result := False;
  end;
end;

procedure TLazNodeEditor.InvalidateSortedNodes;
begin
  FPaintNodesDirty := True;
end;

procedure TLazNodeEditor.EnsureSortedNodes;
var
  i: integer;
begin
  if not FPaintNodesDirty then Exit;
  FPaintNodesSorted.Clear;
  for i := 0 to FGraph.Nodes.Count - 1 do
    FPaintNodesSorted.Add(FGraph.Nodes[i]);
  FPaintNodesSorted.Sort(@NodePaintCompare);
  FPaintNodesDirty := False;
end;

procedure TLazNodeEditor.RequestRepaint(const AForce: boolean);
var
  T: QWord;
begin
  if (FGraph <> nil) and (FGraph.LinkRouter <> nil) then
    (FGraph.LinkRouter as TNodeLinkRouter).InvalidateCache;
  if AForce then
  begin
    Invalidate;
    Exit;
  end;
  T := GetTickCount64;
  if (T - FLastPaintTick) >= 16 then
  begin
    FLastPaintTick := T;
    Invalidate;
  end;
end;

procedure TLazNodeEditor.NodeGraphChanged(Sender: TObject);
begin
  UpdatePinsConnectedState;
  InvalidateSortedNodes;
  RequestRepaint(True);
end;

procedure TLazNodeEditor.ControllerSelectionChanged(Sender: TObject);
begin
  SyncControllerSelectionToView;
end;

procedure TLazNodeEditor.DoPinSelectionChanged(Sender: TObject);
begin
  if Assigned(FOnPinSelectionChanged) then
    FOnPinSelectionChanged(Self);
end;

function TLazNodeEditor.HitTestNodeAt(SX, SY: integer): TCustomNode;
var
  i: integer;
  W: TPointF;
  N: TCustomNode;
begin
  Result := nil;
  W := ScreenToWorld(SX, SY);
  EnsureSortedNodes;
  for i := FPaintNodesSorted.Count - 1 downto 0 do
  begin
    N := TCustomNode(FPaintNodesSorted[i]);
    if (N <> nil) and N.HitTestNode(W.X, W.Y) then
      Exit(N);
  end;
end;

function TLazNodeEditor.HitTestPinAt(SX, SY: integer; out ANode: TCustomNode): TNodePin;
var
  i: integer;
  W: TPointF;
  N: TCustomNode;
begin
  Result := nil;
  ANode := nil;
  W := ScreenToWorld(SX, SY);
  EnsureSortedNodes;
  for i := FPaintNodesSorted.Count - 1 downto 0 do
  begin
    N := TCustomNode(FPaintNodesSorted[i]);
    if N = nil then
      Continue;
    Result := N.HitTestPin(W.X, W.Y, FViewport.Zoom);
    if Result <> nil then
    begin
      ANode := N;
      Exit;
    end;
  end;
end;

function TLazNodeEditor.HitTestLinkAt(SX, SY: integer): TNodeLink;
var
  i: integer;
  W: TPointF;
  L: TNodeLink;
  Tol: single;
begin
  Result := nil;
  W := ScreenToWorld(SX, SY);
  Tol := 8 / Max(FViewport.Zoom, 0.001);

  for i := FGraph.Links.Count - 1 downto 0 do
  begin
    L := TNodeLink(FGraph.Links[i]);
    if L = nil then
      Continue;

    if (FGraph.LinkRouter <> nil) then
    begin
      if FGraph.LinkRouter.HitTest(L, W, Tol) then
        Exit(L);
    end
    else if L.HitTest(W, Tol) then
      Exit(L);
  end;
end;

function TLazNodeEditor.HitTestResizeHandleAt(SX, SY: integer): TCustomNode;
var
  i: integer;
  W: TPointF;
  N: TCustomNode;
  RS: TNodeRenderState;
begin
  Result := nil;
  W := ScreenToWorld(SX, SY);

  RS.Zoom := FViewport.Zoom;
  RS.OffsetX := FViewport.OffsetX;
  RS.OffsetY := FViewport.OffsetY;
  RS.PinRadius := 8;
  RS.ResizeHandleSize := 12;
  RS.HoveredNode := FHoveredNode;
  RS.HoveredPin := FHoveredPin;
  RS.HoveredLink := FHoveredLink;
  RS.SelectedLink := GetPrimarySelectedLink;
  RS.PinSelection := FController.PinSelection;
  RS.TempFromPin := FInteraction.TempFromPin;
  RS.HoveredPinCompatible := FHoveredPinCompatible;

  EnsureSortedNodes;
  for i := FPaintNodesSorted.Count - 1 downto 0 do
  begin
    N := TCustomNode(FPaintNodesSorted[i]);
    if (N <> nil) and N.HitTestResizeHandle(W.X, W.Y, RS) then
      Exit(N);
  end;
end;

function TLazNodeEditor.IsLinkInsideWorldRect(ALink: TNodeLink;
  const R: TRectF): boolean;
begin
  Result := False;
  if ALink = nil then
    Exit;

  if FGraph.LinkRouter <> nil then
    Result := FGraph.LinkRouter.IsInsideRect(ALink, R)
  else
    Result := False;
end;

function TLazNodeEditor.IsMouseNearLinkStart(ALink: TNodeLink; SX, SY: integer): boolean;
var
  P0, P3, M: TPointF;
begin
  Result := False;
  if (ALink = nil) or (ALink.FromPin = nil) or (ALink.ToPin = nil) then
    Exit;

  M := ScreenToWorld(SX, SY);
  P0 := TCustomNode(ALink.FromPin.OwnerNode).GetPinWorldPosition(ALink.FromPin);
  P3 := TCustomNode(ALink.ToPin.OwnerNode).GetPinWorldPosition(ALink.ToPin);

  Result := Hypot(M.X - P0.X, M.Y - P0.Y) <= Hypot(M.X - P3.X, M.Y - P3.Y);
end;

function TLazNodeEditor.SnapWorldValue(V: single): single;
begin
  if FSnapToGrid and (FRenderer.Style.GridSize > 1) then
    Result := Round(V / FRenderer.Style.GridSize) * FRenderer.Style.GridSize
  else
    Result := V;
end;

function TLazNodeEditor.SnapWorldPoint(const P: TPointF): TPointF;
begin
  Result.X := SnapWorldValue(P.X);
  Result.Y := SnapWorldValue(P.Y);
end;

procedure TLazNodeEditor.ClearSnapGuides;
begin
  FGuideSnapXActive := False;
  FGuideSnapYActive := False;
end;

procedure TLazNodeEditor.ApplyNodeSnap(var AOffsetX, AOffsetY: single;
  out ASnappedX, ASnappedY: boolean);
var
  SM: TInteractionStateMachine;
  Bounds, OtherB: TRectF;
  DL, DR, DT, DB, DCX, DCY: single;
  OL, OR_, OT, OB, OCX, OCY: single;
  BestDX, BestDY, BestAbsDX, BestAbsDY, D, Cand: single;
  i: integer;
  N: TCustomNode;

  function InDrag(ANode: TCustomNode): boolean;
  begin
    Result := SM.DragCommandNodes.IndexOf(ANode) >= 0;
  end;

  function DragBounds(OffX, OffY: single): TRectF;
  var
    j: integer;
    NN: TCustomNode;
    L, T, R, B: single;
    First: boolean;
  begin
    Result := RectF(0, 0, 0, 0);
    First := True;
    for j := 0 to SM.DragCommandNodes.Count - 1 do
    begin
      NN := TCustomNode(SM.DragCommandNodes[j]);
      if NN = nil then Continue;
      L := SM.DragOldPositions[j].X + OffX;
      T := SM.DragOldPositions[j].Y + OffY;
      R := L + NN.Width;
      B := T + NN.Height;
      if First then
      begin
        Result := RectF(L, T, R, B);
        First := False;
      end
      else
      begin
        if L < Result.Left then Result.Left := L;
        if T < Result.Top then Result.Top := T;
        if R > Result.Right then Result.Right := R;
        if B > Result.Bottom then Result.Bottom := B;
      end;
    end;
  end;

begin
  FGuideSnapXActive := False;
  FGuideSnapYActive := False;
  ASnappedX := False;
  ASnappedY := False;
  if not FSnapToNodes or (FNodeSnapDistance <= 0) then Exit;

  SM := FInteraction;
  if SM.DragCommandNodes.Count = 0 then Exit;

  Bounds := DragBounds(AOffsetX, AOffsetY);
  DL := Bounds.Left;
  DR := Bounds.Right;
  DT := Bounds.Top;
  DB := Bounds.Bottom;
  DCX := (DL + DR) * 0.5;
  DCY := (DT + DB) * 0.5;

  BestDX := 0;
  BestDY := 0;
  BestAbsDX := FNodeSnapDistance + 1;
  BestAbsDY := FNodeSnapDistance + 1;

  for i := 0 to FGraph.Nodes.Count - 1 do
  begin
    N := TCustomNode(FGraph.Nodes[i]);
    if (N = nil) or InDrag(N) then Continue;
    OtherB := RectF(N.X, N.Y, N.X + N.Width, N.Y + N.Height);

    OL := OtherB.Left;
    OR_ := OtherB.Right;
    OT := OtherB.Top;
    OB := OtherB.Bottom;
    OCX := (OL + OR_) * 0.5;
    OCY := (OT + OB) * 0.5;

    for Cand in [OL - DL, OR_ - DR, OCX - DCX] do
    begin
      D := Abs(Cand);
      if D < BestAbsDX then
      begin
        BestAbsDX := D;
        BestDX := Cand;
        if SameValue(Cand, OL - DL, 1e-4) then FGuideSnapX := OL
        else if SameValue(Cand, OR_ - DR, 1e-4) then FGuideSnapX := OR_
        else
          FGuideSnapX := OCX;
      end;
    end;

    for Cand in [OT - DT, OB - DB, OCY - DCY] do
    begin
      D := Abs(Cand);
      if D < BestAbsDY then
      begin
        BestAbsDY := D;
        BestDY := Cand;
        if SameValue(Cand, OT - DT, 1e-4) then FGuideSnapY := OT
        else if SameValue(Cand, OB - DB, 1e-4) then FGuideSnapY := OB
        else
          FGuideSnapY := OCY;
      end;
    end;
  end;

  if BestAbsDX <= FNodeSnapDistance then
  begin
    AOffsetX := AOffsetX + BestDX;
    FGuideSnapXActive := True;
    ASnappedX := True;
  end;

  if BestAbsDY <= FNodeSnapDistance then
  begin
    AOffsetY := AOffsetY + BestDY;
    FGuideSnapYActive := True;
    ASnappedY := True;
  end;
end;

procedure TLazNodeEditor.ClearHoverStates;
var
  i: integer;
  N: TCustomNode;
begin
  for i := 0 to FGraph.Nodes.Count - 1 do
  begin
    N := TCustomNode(FGraph.Nodes[i]);
    if N <> nil then
    begin
      N.Hovered := False;
      N.Highlighted := False;
    end;
  end;
  FHoveredNode := nil;
  FHoveredPin := nil;
  FHoveredLink := nil;
  FHoveredPinCompatible := False;
end;

procedure TLazNodeEditor.UpdateHoverStates(SX, SY: integer);
var
  N: TCustomNode;
  P: TNodePin;
  L: TNodeLink;
  OldNode: TCustomNode;
  OldPin: TNodePin;
  OldLink: TNodeLink;
  NeedRepaint: boolean;
begin
  OldNode := FHoveredNode;
  OldPin := FHoveredPin;
  OldLink := FHoveredLink;

  if FHoveredNode <> nil then
  begin
    FHoveredNode.Hovered := False;
    FHoveredNode.Highlighted := False;
  end;

  FHoveredNode := nil;
  FHoveredPin := nil;
  FHoveredLink := nil;
  FHoveredPinCompatible := False;

  P := HitTestPinAt(SX, SY, N);
  if P <> nil then
  begin
    FHoveredNode := N;
    FHoveredPin := P;
    if FInteraction.TempFromPin <> nil then
      FHoveredPinCompatible :=
        CanPinAcceptMoreConnections(FInteraction.TempFromPin) and
        CanPinAcceptMoreConnections(P) and FGraph.CanConnect(
        FInteraction.TempFromPin, P)
    else if N <> nil then
      N.Hovered := True;
  end
  else
  begin
    L := HitTestLinkAt(SX, SY);
    if L <> nil then
      FHoveredLink := L
    else
    begin
      N := HitTestNodeAt(SX, SY);
      if N <> nil then
      begin
        FHoveredNode := N;
        N.Hovered := True;
      end;
    end;
  end;

  NeedRepaint := (OldNode <> FHoveredNode) or (OldPin <> FHoveredPin) or
    (OldLink <> FHoveredLink);
  if NeedRepaint then
    RequestRepaint;
end;

procedure TLazNodeEditor.ClearPinSelection;
begin
  if FController.PinSelection <> nil then
    FController.PinSelection.Clear;
end;

procedure TLazNodeEditor.SelectPinInternal(APin: TNodePin; AAppend: boolean);
begin
  if FController.PinSelection <> nil then
    FController.PinSelection.SelectPin(APin, AAppend);
end;

procedure TLazNodeEditor.TogglePinSelection(APin: TNodePin);
begin
  if FController.PinSelection <> nil then
    FController.PinSelection.TogglePin(APin);
end;

procedure TLazNodeEditor.ClearSelectionInternal;
begin
  if FController.Selection <> nil then
    FController.Selection.Clear;
  ClearPinSelection;
  SyncNodeSelectedFlags;
end;

procedure TLazNodeEditor.SelectNodeInternal(ANode: TCustomNode; AAppend: boolean);
begin
  if ANode = nil then Exit;
  if not AAppend then
    ClearPinSelection
  else if FController.Selection.LinkCount > 0 then
    FController.Selection.Links.Clear;
  FController.Selection.SelectNode(ANode, AAppend);
  SyncNodeSelectedFlags;
  InvalidateSortedNodes;
end;

procedure TLazNodeEditor.SelectLinkInternal(ALink: TNodeLink; AKeepNodes: boolean);
begin
  if (ALink = nil) or (FController.Selection = nil) then Exit;
  if not AKeepNodes then
  begin
    FController.Selection.Clear;
    ClearPinSelection;
  end;
  FController.Selection.SelectLink(ALink, True);
  SyncNodeSelectedFlags;
end;

procedure TLazNodeEditor.AddNodeToSelection(ANode: TCustomNode);
begin
  if ANode = nil then Exit;
  FController.Selection.SelectNode(ANode, True);
  ClearPinSelection;
  SyncNodeSelectedFlags;
  InvalidateSortedNodes;
end;

procedure TLazNodeEditor.RemoveNodeFromSelection(ANode: TCustomNode);
begin
  if ANode = nil then Exit;
  FController.Selection.RemoveNode(ANode);
  SyncNodeSelectedFlags;
  InvalidateSortedNodes;
end;

procedure TLazNodeEditor.AddLinkToSelection(ALink: TNodeLink);
begin
  if (ALink = nil) or (FController.Selection = nil) then Exit;
  FController.Selection.AddLinkToSelection(ALink);
  ClearPinSelection;
end;

procedure TLazNodeEditor.RemoveLinkFromSelection(ALink: TNodeLink);
begin
  if (ALink = nil) or (FController.Selection = nil) then Exit;
  FController.Selection.RemoveLinkFromSelection(ALink);
end;

procedure TLazNodeEditor.ToggleNodeSelection(ANode: TCustomNode);
begin
  if ANode = nil then Exit;
  if FController.Selection.ContainsNode(ANode) then
    RemoveNodeFromSelection(ANode)
  else
    AddNodeToSelection(ANode);
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.ToggleLinkSelection(ALink: TNodeLink);
begin
  if ALink = nil then Exit;
  if FController.Selection.ContainsLink(ALink) then
    RemoveLinkFromSelection(ALink)
  else
    AddLinkToSelection(ALink);
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.SyncNodeSelectedFlags;
var
  i: integer;
  N: TCustomNode;
begin
  for i := 0 to FGraph.Nodes.Count - 1 do
  begin
    N := TCustomNode(FGraph.Nodes[i]);
    if N <> nil then
      N.Selected := FController.Selection.ContainsNode(N);
  end;
end;

procedure TLazNodeEditor.NotifySelectionChanged;
begin
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

procedure TLazNodeEditor.SyncControllerSelectionToView;
begin
  SyncNodeSelectedFlags;
  InvalidateSortedNodes;
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.UpdatePinsConnectedState;
var
  i, j: integer;
  N: TCustomNode;
  P: TNodePin;
  L: TNodeLink;
begin
  for i := 0 to FGraph.Nodes.Count - 1 do
  begin
    N := TCustomNode(FGraph.Nodes[i]);
    if N = nil then Continue;

    for j := 0 to N.InputCount - 1 do
    begin
      P := N.GetInput(j);
      if P <> nil then P.Connected := False;
    end;

    for j := 0 to N.OutputCount - 1 do
    begin
      P := N.GetOutput(j);
      if P <> nil then P.Connected := False;
    end;
  end;

  for i := 0 to FGraph.Links.Count - 1 do
  begin
    L := TNodeLink(FGraph.Links[i]);
    if L = nil then Continue;
    if L.FromPin <> nil then L.FromPin.Connected := True;
    if L.ToPin <> nil then L.ToPin.Connected := True;
  end;
end;

function TLazNodeEditor.CanPinAcceptMoreConnections(APin: TNodePin): boolean;
begin
  Result := (APin <> nil) and ((not APin.Connected) or APin.AllowMultipleConnections);
end;

function TLazNodeEditor.GetPrimarySelectedNode: TCustomNode;
begin
  if (FController.Selection <> nil) and (FController.Selection.NodeCount > 0) then
    Result := FController.Selection.GetNode(0)
  else
    Result := nil;
end;

function TLazNodeEditor.GetPrimarySelectedLink: TNodeLink;
begin
  if (FController.Selection <> nil) and (FController.Selection.LinkCount > 0) then
    Result := FController.Selection.GetLink(0)
  else
    Result := nil;
end;

function TLazNodeEditor.CanConnectSelectedPins: boolean;
var
  P1, P2: TNodePin;
begin
  Result := False;
  if FController.PinSelection.Count <> 2 then Exit;
  P1 := FController.PinSelection.GetPin(0);
  P2 := FController.PinSelection.GetPin(1);
  if (P1 = nil) or (P2 = nil) then Exit;
  if not CanPinAcceptMoreConnections(P1) then Exit;
  if not CanPinAcceptMoreConnections(P2) then Exit;
  Result := FGraph.CanConnect(P1, P2);
end;

procedure TLazNodeEditor.ConnectSelectedPins;
var
  P1, P2, FromPin, ToPin: TNodePin;
  Allow: boolean;
begin
  if FController.PinSelection.Count <> 2 then Exit;
  P1 := FController.PinSelection.GetPin(0);
  P2 := FController.PinSelection.GetPin(1);
  if (P1 = nil) or (P2 = nil) then Exit;

  if P1.Direction = pdOutput then
  begin
    FromPin := P1;
    ToPin := P2;
  end
  else
  begin
    FromPin := P2;
    ToPin := P1;
  end;

  if not CanPinAcceptMoreConnections(FromPin) or not
    CanPinAcceptMoreConnections(ToPin) then Exit;

  Allow := True;
  if Assigned(FOnBeforeConnectPins) then
    FOnBeforeConnectPins(Self, FromPin, ToPin, Allow);
  if not Allow then Exit;
  if not FGraph.CanConnect(FromPin, ToPin) then Exit;

  if not FGraph.LinkExists(FromPin, ToPin) then
    FGraph.ExecuteCommand(TAddLinkCommand.Create(FGraph, FromPin, ToPin));

  if Assigned(FOnAfterConnectPins) then
    FOnAfterConnectPins(Self, FromPin, ToPin);

  ClearPinSelection;
  Invalidate;
end;

procedure TLazNodeEditor.BuildRenderContext;
begin
  if FAntiAliasing and Assigned(FGLControl) then
  begin
    FRenderContext.CanvasKind := rckGL2D;
    FRenderContext.GLCanvas := FGLControl.Canvas;
    FRenderContext.GLCanvasProxy := FGLCanvasProxy;
    FRenderContext.GDICanvas := nil;
  end
  else
  begin
    FRenderContext.CanvasKind := rckGDI;
    FRenderContext.GDICanvas := Canvas;
    FRenderContext.GLCanvas := nil;
    FRenderContext.GLCanvasProxy := nil;
  end;

  FRenderContext.ClientRect := ClientRect;
  FRenderContext.ClientWidth := ClientWidth;
  FRenderContext.ClientHeight := ClientHeight;

  FRenderContext.Graph := FGraph;
  EnsureSortedNodes;
  FRenderContext.PaintNodesSorted := FPaintNodesSorted;

  FRenderContext.Zoom := FViewport.Zoom;
  FRenderContext.OffsetX := FViewport.OffsetX;
  FRenderContext.OffsetY := FViewport.OffsetY;
  FRenderContext.VisibleWorldRect :=
    FViewport.GetVisibleWorldRect(ClientWidth, ClientHeight);

  FRenderContext.RenderState.Zoom := FViewport.Zoom;
  FRenderContext.RenderState.OffsetX := FViewport.OffsetX;
  FRenderContext.RenderState.OffsetY := FViewport.OffsetY;

  FRenderContext.RenderState.Zoom := FViewport.Zoom;
  FRenderContext.RenderState.OffsetX := FViewport.OffsetX;
  FRenderContext.RenderState.OffsetY := FViewport.OffsetY;

  with FRenderContext.RenderState do
  begin
    if FViewport.Zoom >= FMinPinLabelZoom then
    begin
      DetailLevel := 3;     // full
      ShowNodeTitle := True;
      ShowPinLabels := True;
    end
    else if FViewport.Zoom >= FMinTitleZoom then
    begin
      DetailLevel := 2;     // medium
      ShowNodeTitle := True;
      ShowPinLabels := False;
    end
    else if FViewport.Zoom >= FMinDetailZoom then
    begin
      DetailLevel := 1;     // minimal
      ShowNodeTitle := True;
      ShowPinLabels := False;
    end
    else
    begin
      DetailLevel := 0;     // tiny (only color blocks)
      ShowNodeTitle := False;
      ShowPinLabels := False;
    end;
  end;

  FRenderContext.RenderState.PinRadius := 8;
  FRenderContext.RenderState.ResizeHandleSize := 12;
  FRenderContext.RenderState.HoveredNode := FHoveredNode;
  FRenderContext.RenderState.HoveredPin := FHoveredPin;
  FRenderContext.RenderState.HoveredLink := FHoveredLink;
  FRenderContext.RenderState.SelectedLink := GetPrimarySelectedLink;
  FRenderContext.RenderState.IsLinkSelected := @IsLinkSelected;
  FRenderContext.RenderState.PinSelection := FController.PinSelection;
  FRenderContext.RenderState.TempFromPin := FInteraction.TempFromPin;
  FRenderContext.RenderState.TempMousePos := FInteraction.TempMousePos;
  FRenderContext.RenderState.HoveredPinCompatible := FHoveredPinCompatible;


  FRenderContext.BoxSelecting := FInteraction.IsBoxSelecting;
  if FInteraction.IsBoxSelecting then
    FRenderContext.BoxSelectRect :=
      NormalizeRect(Rect(FInteraction.BoxStart.X, FInteraction.BoxStart.Y,
      FInteraction.BoxCurrent.X, FInteraction.BoxCurrent.Y));

  FRenderContext.ShowSnapGuides := FShowSnapGuides and FInteraction.IsDraggingNode;
  FRenderContext.GuideSnapXActive := FGuideSnapXActive;
  FRenderContext.GuideSnapYActive := FGuideSnapYActive;
  FRenderContext.GuideSnapX := FGuideSnapX;
  FRenderContext.GuideSnapY := FGuideSnapY;

  FRenderContext.DraggingNode := FInteraction.IsDraggingNode;
  FRenderContext.DrawResizeHandles := True;

  FRenderContext.OnDrawNode := FOnDrawNode;
  FRenderContext.OnDrawPin := FOnDrawPin;
  FRenderContext.OnDrawLink := FOnDrawLink;
  FRenderContext.OnDrawGrid := FOnDrawGrid;
  FRenderContext.OnDrawSnapGuides := FOnDrawSnapGuides;
end;

procedure TLazNodeEditor.Paint;
begin
  if FAntiAliasing then Exit;
  BuildRenderContext;
  FRenderer.Render(FRenderContext);
end;

procedure TLazNodeEditor.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  SetFocus;
  FInteraction.MouseDown(Button, Shift, X, Y);
end;

procedure TLazNodeEditor.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  inherited MouseMove(Shift, X, Y);
  FInteraction.MouseMove(Shift, X, Y);
end;

procedure TLazNodeEditor.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  FInteraction.MouseUp(Button, Shift, X, Y);
end;

function TLazNodeEditor.DoMouseWheel(Shift: TShiftState; WheelDelta: integer;
  MousePos: TPoint): boolean;
var
  Factor: double;
begin
  inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  Result := True;
  Factor := Power(FViewport.ZoomStep, WheelDelta / 120.0);
  if ssCtrl in Shift then
    Factor := Power(Factor, 1.7)
  else if ssShift in Shift then
    Factor := Power(Factor, 0.4);
  FViewport.ZoomAt(MousePos.X, MousePos.Y, Factor);
  if Assigned(FOnZoomChanged) then
    FOnZoomChanged(Self);
  Invalidate;
end;

procedure TLazNodeEditor.KeyDown(var Key: word; Shift: TShiftState);
var
  AAction: TEditorAction;
begin
  inherited KeyDown(Key, Shift);

  AAction := ResolveShortcut(Key, Shift);
  if ExecuteEditorAction(AAction) then
  begin
    Key := 0;
    Exit;
  end;

  FInteraction.KeyDown(Key, Shift);
  if Key = 0 then
    Exit;

  if Key = VK_ESCAPE then
  begin
    ClearSelection;
    Key := 0;
  end;
end;

procedure TLazNodeEditor.DoExit;
begin
  FInteraction.CancelCurrentOperation;
  ClearHoverStates;
  inherited DoExit;
end;

procedure TLazNodeEditor.MouseLeave;
begin
  inherited MouseLeave;
  if csDesigning in ComponentState then Exit;
  if not FInteraction.IsOperationActive then
  begin
    ClearHoverStates;
    Invalidate;
  end;
end;

procedure TLazNodeEditor.ResetStateAfterGraphReload;
var
  OldHandler: TNotifyEvent;
begin
  OldHandler := FController.Selection.OnChanged;
  FController.Selection.OnChanged := nil;
  try
    FController.Selection.Clear;
  finally
    FController.Selection.OnChanged := OldHandler;
  end;
  ClearPinSelection;
  FInteraction.CancelCurrentOperation;
  ClearHoverStates;
  NotifySelectionChanged;
  InvalidateSortedNodes;
  SyncNodeSelectedFlags;
end;

procedure TLazNodeEditor.ShowNodeSearchPopup(AScreenX, AScreenY: integer;
  AWorldX, AWorldY: single);
var
  F: TNodeSearchForm;
  N: TCustomNode;
begin
  F := TNodeSearchForm.CreateSearch(Self, FGraph.Registry);
  try
    F.Left := AScreenX;
    F.Top := AScreenY;
    if F.ShowModal = mrOk then
    begin
      if F.SelectedNodeType <> '' then
      begin
        N := FGraph.Registry.CreateNode(F.SelectedNodeType,
          SnapWorldValue(AWorldX), SnapWorldValue(AWorldY));
        AddNode(N);
        SelectNodeInternal(N, False);
        NotifySelectionChanged;
        Invalidate;
      end;
    end;
  finally
    F.Free;
  end;
end;

procedure TLazNodeEditor.AddNode(ANode: TCustomNode);
begin
  if ANode = nil then Exit;
  FController.AddNode(ANode);
  Invalidate;
end;

procedure TLazNodeEditor.RemoveNode(ANode: TCustomNode);
begin
  if ANode = nil then Exit;
  FController.RemoveNode(ANode);
  UpdatePinsConnectedState;
  SyncControllerSelectionToView;
end;

procedure TLazNodeEditor.RemoveLink(ALink: TNodeLink);
begin
  if ALink = nil then Exit;
  FController.RemoveLink(ALink);
  UpdatePinsConnectedState;
  SyncControllerSelectionToView;
end;

procedure TLazNodeEditor.Clear;
begin
  FController.Clear;
  UpdatePinsConnectedState;
  ResetStateAfterGraphReload;
  Invalidate;
end;

procedure TLazNodeEditor.ClearSelection;
begin
  ClearSelectionInternal;
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.DeleteSelection;
begin
  FController.DeleteSelection;
  SyncControllerSelectionToView;
  Invalidate;
end;

procedure TLazNodeEditor.SelectNode(ANode: TCustomNode; AAppend: boolean);
begin
  SelectNodeInternal(ANode, AAppend);
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.SelectLink(ALink: TNodeLink);
begin
  SelectLinkInternal(ALink);
  NotifySelectionChanged;
  Invalidate;
end;

function TLazNodeEditor.SelectedNodeCount: integer;
begin
  Result := FController.Selection.NodeCount;
end;

function TLazNodeEditor.SelectedLinkCount: integer;
begin
  Result := FController.Selection.LinkCount;
end;

function TLazNodeEditor.GetSelectedNode(Index: integer): TCustomNode;
begin
  Result := FController.Selection.GetNode(Index);
end;

function TLazNodeEditor.IsLinkSelected(ALink: TNodeLink): boolean;
begin
  Result := (FController <> nil) and (FController.Selection <> nil) and
    FController.Selection.ContainsLink(ALink);
end;

procedure TLazNodeEditor.FitToSelection;
var
  i: integer;
  N: TCustomNode;
  R: TRectF;
  First: boolean;
begin
  if FController.Selection.NodeCount = 0 then Exit;
  First := True;
  for i := 0 to FController.Selection.NodeCount - 1 do
  begin
    N := FController.Selection.GetNode(i);
    if First then
    begin
      R := RectF(N.X, N.Y, N.X + N.Width, N.Y + N.Height);
      First := False;
    end
    else
    begin
      if N.X < R.Left then R.Left := N.X;
      if N.Y < R.Top then R.Top := N.Y;
      if N.X + N.Width > R.Right then R.Right := N.X + N.Width;
      if N.Y + N.Height > R.Bottom then R.Bottom := N.Y + N.Height;
    end;
  end;
  FViewport.FrameRect(R, ClientWidth, ClientHeight, 60);
  Invalidate;
end;

procedure TLazNodeEditor.FrameAll;
var
  i: integer;
  N: TCustomNode;
  MinX, MinY, MaxX, MaxY: single;
  First: boolean;
begin
  if FGraph.Nodes.Count = 0 then Exit;
  First := True;
  for i := 0 to FGraph.Nodes.Count - 1 do
  begin
    N := TCustomNode(FGraph.Nodes[i]);
    if First then
    begin
      MinX := N.X;
      MinY := N.Y;
      MaxX := N.X + N.Width;
      MaxY := N.Y + N.Height;
      First := False;
    end
    else
    begin
      if N.X < MinX then MinX := N.X;
      if N.Y < MinY then MinY := N.Y;
      if N.X + N.Width > MaxX then MaxX := N.X + N.Width;
      if N.Y + N.Height > MaxY then MaxY := N.Y + N.Height;
    end;
  end;
  FViewport.FrameAll(MinX, MinY, MaxX, MaxY, ClientWidth, ClientHeight);
  Invalidate;
end;

procedure TLazNodeEditor.Undo;
begin
  FController.Undo;
  UpdatePinsConnectedState;
  ResetStateAfterGraphReload;
  Invalidate;
end;

procedure TLazNodeEditor.Redo;
begin
  FController.Redo;
  UpdatePinsConnectedState;
  ResetStateAfterGraphReload;
  Invalidate;
end;

procedure TLazNodeEditor.CopySelectionToClipboard;
begin
  FController.CopySelectionToClipboard;
end;

procedure TLazNodeEditor.PasteFromClipboard;
begin
  FController.PasteFromClipboard(
    SnapWorldValue(FContextWorldPos.X), SnapWorldValue(FContextWorldPos.Y));
  SyncControllerSelectionToView;
  Invalidate;
end;

procedure TLazNodeEditor.DuplicateSelection;
var
  W: TPointF;
begin
  W := FViewport.ScreenToWorld(ClientWidth div 2, ClientHeight div 2);
  FController.DuplicateSelection(SnapWorldValue(W.X + 25), SnapWorldValue(W.Y + 25));
  SyncControllerSelectionToView;
  Invalidate;
end;

function TLazNodeEditor.SaveToJSONText: string;
begin
  Result := FController.SaveToJSONText(FViewport.Zoom, FViewport.OffsetX,
    FViewport.OffsetY);
end;

procedure TLazNodeEditor.LoadFromJSONText(const S: string);
var
  Z, OX, OY: double;
begin
  if Trim(S) = '' then Exit;
  FController.LoadFromJSONText(S, Z, OX, OY);
  FViewport.Zoom := Z;
  FViewport.OffsetX := OX;
  FViewport.OffsetY := OY;
  UpdatePinsConnectedState;
  ResetStateAfterGraphReload;
  Invalidate;
end;

procedure TLazNodeEditor.SaveToFile(const AFileName: string);
begin
  FController.SaveToFile(AFileName,
    FViewport.Zoom, FViewport.OffsetX, FViewport.OffsetY);
end;

procedure TLazNodeEditor.LoadFromFile(const AFileName: string);
var
  Z, OX, OY: double;
begin
  FController.LoadFromFile(AFileName, Z, OX, OY);
  FViewport.Zoom := Z;
  FViewport.OffsetX := OX;
  FViewport.OffsetY := OY;
  UpdatePinsConnectedState;
  ResetStateAfterGraphReload;
  Invalidate;
end;

function TLazNodeEditor.ValidateGraphToStrings(AStrings: TStrings): boolean;
begin
  Result := FController.ValidateGraphToStrings(AStrings);
end;

function TLazNodeEditor.AddInputPinToNode(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
begin
  Result := FController.AddInputPinToNode(ANode, AName, ADataType, AKind);
  if (Result <> nil) and Assigned(FOnNodeChanged) then
    FOnNodeChanged(Self, ANode);
  Invalidate;
end;

function TLazNodeEditor.AddOutputPinToNode(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
begin
  Result := FController.AddOutputPinToNode(ANode, AName, ADataType, AKind);
  if (Result <> nil) and Assigned(FOnNodeChanged) then
    FOnNodeChanged(Self, ANode);
  Invalidate;
end;

function TLazNodeEditor.RemovePinFromNode(APin: TNodePin): boolean;
var
  N: TCustomNode;
begin
  N := nil;
  if APin <> nil then
    N := TCustomNode(APin.OwnerNode);
  Result := FController.RemovePinFromNode(APin);
  if Result and Assigned(FOnNodeChanged) and (N <> nil) then
    FOnNodeChanged(Self, N);
  Invalidate;
end;

procedure TLazNodeEditor.BuildContextMenu;
var
  AddRoot, Item, Sep: TMenuItem;
  i: integer;
  Reg: TNodeRegistryItem;
begin
  FEditorPopupMenu.Items.Clear;

  Item := TMenuItem.Create(FEditorPopupMenu);
  Item.Caption := 'Search Node...';
  Item.OnClick := @OnContextSearchNode;
  FEditorPopupMenu.Items.Add(Item);

  Sep := TMenuItem.Create(FEditorPopupMenu);
  Sep.Caption := '-';
  FEditorPopupMenu.Items.Add(Sep);

  AddRoot := TMenuItem.Create(FEditorPopupMenu);
  AddRoot.Caption := 'Add Node';
  FEditorPopupMenu.Items.Add(AddRoot);

  for i := 0 to FGraph.Registry.Count - 1 do
  begin
    Reg := FGraph.Registry.Item(i);
    Item := TMenuItem.Create(FEditorPopupMenu);
    Item.Caption := Reg.Caption;
    Item.Tag := PtrInt(Reg);
    Item.OnClick := @OnAddRegisteredNodeClick;
    AddRoot.Add(Item);
  end;

  Sep := TMenuItem.Create(FEditorPopupMenu);
  Sep.Caption := '-';
  FEditorPopupMenu.Items.Add(Sep);

  Item := TMenuItem.Create(FEditorPopupMenu);
  Item.Caption := 'Copy';
  Item.ShortCut := ShortCut(Ord('C'), [ssCtrl]);
  Item.OnClick := @OnContextCopy;
  FEditorPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FEditorPopupMenu);
  Item.Caption := 'Paste';
  Item.ShortCut := ShortCut(Ord('V'), [ssCtrl]);
  Item.OnClick := @OnContextPaste;
  FEditorPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FEditorPopupMenu);
  Item.Caption := 'Duplicate';
  Item.ShortCut := ShortCut(Ord('D'), [ssCtrl]);
  Item.OnClick := @OnContextDuplicate;
  FEditorPopupMenu.Items.Add(Item);

  Sep := TMenuItem.Create(FEditorPopupMenu);
  Sep.Caption := '-';
  FEditorPopupMenu.Items.Add(Sep);

  Item := TMenuItem.Create(FEditorPopupMenu);
  Item.Caption := 'Insert Reroute On Selected Link';
  Item.OnClick := @OnContextInsertReroute;
  FEditorPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FEditorPopupMenu);
  Item.Caption := 'Add Comment / Frame';
  Item.OnClick := @OnContextAddComment;
  FEditorPopupMenu.Items.Add(Item);

  Sep := TMenuItem.Create(FEditorPopupMenu);
  Sep.Caption := '-';
  FEditorPopupMenu.Items.Add(Sep);

  Item := TMenuItem.Create(FEditorPopupMenu);
  Item.Caption := 'Delete';
  Item.OnClick := @OnContextDelete;
  FEditorPopupMenu.Items.Add(Item);
end;

procedure TLazNodeEditor.OnPopupClose(Sender: TObject);
begin
  FInteraction.CancelCurrentOperation;
end;

procedure TLazNodeEditor.OnAddRegisteredNodeClick(Sender: TObject);
var
  N: TCustomNode;
begin
  N := FGraph.Registry.CreateNode(TNodeRegistryItem(TMenuItem(Sender).Tag).NodeType,
    SnapWorldValue(FContextWorldPos.X), SnapWorldValue(FContextWorldPos.Y));
  AddNode(N);
  SelectNodeInternal(N, False);
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.OnContextCopy(Sender: TObject);
begin
  CopySelectionToClipboard;
end;

procedure TLazNodeEditor.OnContextPaste(Sender: TObject);
begin
  PasteFromClipboard;
end;

procedure TLazNodeEditor.OnContextDuplicate(Sender: TObject);
begin
  DuplicateSelection;
end;

procedure TLazNodeEditor.OnContextDelete(Sender: TObject);
begin
  DeleteSelection;
end;

procedure TLazNodeEditor.OnContextSearchNode(Sender: TObject);
begin
  ShowNodeSearchPopup(Mouse.CursorPos.X, Mouse.CursorPos.Y,
    FContextWorldPos.X, FContextWorldPos.Y);
end;

procedure TLazNodeEditor.OnContextInsertReroute(Sender: TObject);
var
  N: TCustomNode;
begin
  if GetPrimarySelectedLink = nil then Exit;
  N := FController.InsertRerouteOnLink(GetPrimarySelectedLink,
    SnapWorldValue(FContextWorldPos.X), SnapWorldValue(FContextWorldPos.Y));
  SyncControllerSelectionToView;
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.OnContextAddComment(Sender: TObject);
begin
  FController.AddCommentNode(
    SnapWorldValue(FContextWorldPos.X), SnapWorldValue(FContextWorldPos.Y));
  SyncControllerSelectionToView;
  NotifySelectionChanged;
  Invalidate;
end;

{$IFNDEF MSWINDOWS}
procedure TLazNodeEditor.GLMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  MouseDown(Button, Shift, X, Y);
end;

procedure TLazNodeEditor.GLMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
begin
  MouseMove(Shift, X, Y);
end;

procedure TLazNodeEditor.GLMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  MouseUp(Button, Shift, X, Y);
end;

procedure TLazNodeEditor.GLMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: integer; MousePos: TPoint; var Handled: boolean);
begin
  Handled := DoMouseWheel(Shift, WheelDelta, MousePos);
end;

procedure TLazNodeEditor.GLMouseEnter(Sender: TObject);
begin
  SetFocus;
end;

procedure TLazNodeEditor.GLMouseLeave(Sender: TObject);
begin
  MouseLeave;
end;
{$ENDIF}

end.
