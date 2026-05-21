unit LazNodeEditor.Editor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, ExtCtrls, LCLIntf, LCLType, Math, Types,
  Menus, Clipbrd, Forms, StdCtrls, Dialogs,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Controller;

type
  TNodeSelectionChangedEvent = procedure(Sender: TObject) of object;
  TNodeChangedEvent = procedure(Sender: TObject; ANode: TCustomNode) of object;

  { TLazNodeEditor — VIEW + CONTROLLER WRAPPER }
  TLazNodeEditor = class(TCustomControl)
  private
    FGraph: TNodeGraph;
    FController: TNodeEditorController;
    FOnZoomChanged: TEditorZoomChangedEvent;

    FZoom: double;
    FOffsetX, FOffsetY: integer;

    FSelectedNode: TCustomNode;
    FSelectedLink: TNodeLink;
    FSelectedLinks: TNodeLinkList;
    FSelectedNodes: TCustomNodeList;

    FDraggingNode: boolean;
    FDragStartX, FDragStartY: integer;
    FDragAnchorX, FDragAnchorY: integer;
    FDragUndoPushed: boolean;

    FDragCommandNodes: TCustomNodeList;
    FDragOldPositions: array of TPointF;


    FDragStartWorldPos: TPointF;
    FShowDragCoordinates: boolean;

    FPanning: boolean;
    FPanStartX, FPanStartY: integer;
    FRightMouseMoved: boolean;
    FRightButtonDown: boolean;

    FTempFromPin: TNodePin;
    FTempMousePos: TPoint;

    FBoxSelecting: boolean;
    FBoxStart: TPoint;
    FBoxCurrent: TPoint;
    FBoxStartWorld: TPointF;
    FBoxCurrentWorld: TPointF;

    FPopupMenu: TPopupMenu;
    FContextWorldPos: TPointF;

    FDraggingLink: boolean;
    FTempStartMousePos: TPoint;

    FHoveredNode: TCustomNode;
    FHoveredPin: TNodePin;
    FHoveredLink: TNodeLink;

    FReconnectingLink: boolean;
    FReconnectLink: TNodeLink;
    FReconnectFixedPin: TNodePin;
    FReconnectMovingFromSide: boolean;

    FOnSelectionChanged: TNodeSelectionChangedEvent;
    FOnNodeChanged: TNodeChangedEvent;

    FResizingNode: boolean;
    FResizeNode: TCustomNode;
    FResizeStartMouseX, FResizeStartMouseY: integer;
    FResizeStartWidth, FResizeStartHeight: integer;
    FResizeStartX, FResizeStartY: single;
    FResizeEdgeSize: integer;
    FResizeOldWidth, FResizeOldHeight: integer;

    FSnapToGrid: boolean;
    FGridSize: integer;
    FSnapToNodes: boolean;
    FNodeSnapDistance: single;

    FShowSnapGuides: boolean;
    FGuideSnapXActive: boolean;
    FGuideSnapYActive: boolean;
    FGuideSnapX: single;
    FGuideSnapY: single;

    // Axes properties
    FShowAxes: boolean;
    FAxesColor: TColor;
    FAxesThickness: integer;

    procedure NotifySelectionChanged;
    procedure ControllerSelectionChanged(Sender: TObject);
    procedure SetZoom(AValue: double);
    procedure SyncControllerSelectionToView;

    function GetResizeHandleRect(ANode: TCustomNode): TRect;
    function GetNodeResizeUnderMouse(SX, SY: integer): TCustomNode;

    procedure BuildContextMenu;
    procedure OnAddRegisteredNodeClick(Sender: TObject);
    procedure OnContextCopy(Sender: TObject);
    procedure OnContextPaste(Sender: TObject);
    procedure OnContextDuplicate(Sender: TObject);
    procedure OnContextDelete(Sender: TObject);
    procedure OnContextSearchNode(Sender: TObject);
    procedure OnContextInsertReroute(Sender: TObject);
    procedure OnContextAddComment(Sender: TObject);

    // World-Space Logic
    function GetVisibleWorldRect: TRectF;
    function NormalizeRectF(const R: TRectF): TRectF;
    function GetPinWorldPosition(APin: TNodePin): TPointF;
    procedure GetLinkBezierWorldPoints(ALink: TNodeLink; out P0, P1, P2, P3: TPointF);

    // Rendering
    procedure DrawGrid;
    procedure DrawAxes;
    procedure DrawLinks;
    procedure DrawTempLink;
    procedure DrawBoxSelect;

    function WorldToScreen(WX, WY: single): TPoint;
    function ScreenToWorld(SX, SY: integer): TPointF;

    function GetNodeUnderMouse(SX, SY: integer): TCustomNode;
    function IsLinkInsideWorldRect(ALink: TNodeLink; const R: TRectF): boolean;
    function GetPinUnderMouse(SX, SY: integer; out Node: TCustomNode;
      out Pin: TNodePin): boolean;
    function GetLinkUnderMouse(SX, SY: integer; out Link: TNodeLink): boolean;

    procedure ClearSelectionInternal;
    procedure SelectNodeInternal(ANode: TCustomNode; AAppend: boolean);
    procedure SelectLinkInternal(ALink: TNodeLink; AKeepNodes: boolean = False);
    procedure ToggleNodeSelection(ANode: TCustomNode);
    procedure AddNodeToSelection(ANode: TCustomNode);
    procedure RemoveNodeFromSelection(ANode: TCustomNode);
    procedure ToggleLinkSelection(ALink: TNodeLink);
    procedure AddLinkToSelection(ALink: TNodeLink);
    procedure RemoveLinkFromSelection(ALink: TNodeLink);
    function IsMouseNearLinkStart(ALink: TNodeLink; SX, SY: integer): boolean;

    procedure ShowNodeSearchPopup(AScreenX, AScreenY: integer; AWorldX, AWorldY: single);
    procedure ResetStateAfterGraphReload;
    procedure ClearHoverStates;
    procedure UpdateHoverStates(SX, SY: integer);

    function SnapWorldValue(V: single): single;
    function SnapWorldPoint(const P: TPointF): TPointF;
    procedure OnPopupClose(Sender: TObject);

    function IsNodeInDragSelection(ANode: TCustomNode): boolean;
    function GetDraggedSelectionBoundsAtOffset(const AOffsetX, AOffsetY: single): TRectF;
    procedure ApplyNodeSnap(var AOffsetX, AOffsetY: single);

    procedure ClearSnapGuides;
    procedure DrawSnapGuides;

  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: integer;
      MousePos: TPoint): boolean; override;
    procedure CancelMouseOperations(const KeepSelectionRect: boolean = False);
    procedure DoExit; override;
    procedure MouseLeave; override;
    procedure KeyDown(var Key: word; Shift: TShiftState); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AddNode(ANode: TCustomNode);
    procedure RemoveNode(ANode: TCustomNode);
    procedure RemoveLink(ALink: TNodeLink);
    procedure Clear;

    procedure ClearSelection;
    procedure DeleteSelection;
    function SelectedNodeCount: integer;
    function SelectedLinkCount: integer;
    function GetSelectedNode(Index: integer): TCustomNode;
    procedure SelectNode(ANode: TCustomNode; AAppend: boolean);
    procedure SelectLink(ALink: TNodeLink);

    procedure FitToSelection;
    procedure FrameAll;

    function SaveToJSONText: string;
    procedure LoadFromJSONText(const S: string);
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);

    procedure Undo;
    procedure Redo;
    procedure CopySelectionToClipboard;
    procedure PasteFromClipboard;
    procedure DuplicateSelection;

    function ValidateGraphToStrings(AStrings: TStrings): boolean;

    function AddInputPinToNode(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function AddOutputPinToNode(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function RemovePinFromNode(APin: TNodePin): boolean;

    property Graph: TNodeGraph read FGraph;
    property Zoom: double read FZoom write SetZoom;

  published
    property Align;
    property Anchors;
    property Color;
    property TabStop default True;
    property PopupMenu;
    property SnapToGrid: boolean read FSnapToGrid write FSnapToGrid default False;
    property GridSize: integer read FGridSize write FGridSize default 40;
    property ShowSnapGuides: boolean
      read FShowSnapGuides write FShowSnapGuides default True;
    property SnapToNodes: boolean read FSnapToNodes write FSnapToNodes default True;
    property NodeSnapDistance: single read FNodeSnapDistance write FNodeSnapDistance;

    // New Axes Properties
    property ShowAxes: boolean read FShowAxes write FShowAxes default False;
    property AxesColor: TColor read FAxesColor write FAxesColor default clSilver;
    property AxesThickness: integer read FAxesThickness write FAxesThickness default 2;

    property OnSelectionChanged: TNodeSelectionChangedEvent
      read FOnSelectionChanged write FOnSelectionChanged;
    property OnNodeChanged: TNodeChangedEvent read FOnNodeChanged write FOnNodeChanged;
    property OnZoomChanged: TEditorZoomChangedEvent
      read FOnZoomChanged write FOnZoomChanged;
  end;

implementation

function PtInRectF(const Pt: TPointF; const R: TRectF): Boolean; inline;
begin
  Result := (Pt.X >= R.Left) and (Pt.X <= R.Right) and
            (Pt.Y >= R.Top) and (Pt.Y <= R.Bottom);
end;

function RectFIntersects(const R1, R2: TRectF): Boolean;
begin
  Result := not ((R1.Right < R2.Left) or (R1.Left > R2.Right) or
                 (R1.Bottom < R2.Top) or (R1.Top > R2.Bottom));
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

  Result.X := UUU * P0.X +
              3 * UU * T * P1.X +
              3 * U * TT * P2.X +
              TTT * P3.X;

  Result.Y := UUU * P0.Y +
              3 * UU * T * P1.Y +
              3 * U * TT * P2.Y +
              TTT * P3.Y;
end;

function LineIntersectsRectF(P1, P2: TPointF; const R: TRectF): Boolean;
var
  N: TRectF;
  Dx, Dy: Single;
  T0, T1: Single;

  function ClipTest(P, Q: Single; var T0, T1: Single): Boolean;
  var
    Rr: Single;
  begin
    if Abs(P) < 1e-6 then
      Exit(Q >= 0);

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
  N := R;
  N.NormalizeRect;

  if PtInRectF(P1, N) or PtInRectF(P2, N) then
    Exit(True);

  Dx := P2.X - P1.X;
  Dy := P2.Y - P1.Y;
  T0 := 0.0;
  T1 := 1.0;

  Result :=
    ClipTest(-Dx, P1.X - N.Left,  T0, T1) and
    ClipTest( Dx, N.Right - P1.X, T0, T1) and
    ClipTest(-Dy, P1.Y - N.Top,   T0, T1) and
    ClipTest( Dy, N.Bottom - P1.Y, T0, T1);
end;

constructor TLazNodeEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FGraph := TNodeGraph.Create;
  FController := TNodeEditorController.Create(FGraph);
  FController.Selection.OnChanged := @ControllerSelectionChanged;

  FSelectedNodes := TCustomNodeList.Create(False);
  FSelectedLinks := TNodeLinkList.Create(False);
  FDragCommandNodes := TCustomNodeList.Create(False);

  FZoom := 1.0;
  FSnapToGrid := False;
  FGridSize := 40;
  FSnapToNodes := True;
  FNodeSnapDistance := 10.0;
  FOffsetX := 0;
  FOffsetY := 0;

  FShowSnapGuides := True;
  FGuideSnapXActive := False;
  FGuideSnapYActive := False;
  FGuideSnapX := 0;
  FGuideSnapY := 0;

  // Axes defaults
  FShowAxes := False;
  FAxesColor := clSilver;
  FAxesThickness := 2;

  Color := $00F0F8FF;
  DoubleBuffered := True;
  TabStop := True;

  FResizingNode := False;
  FResizeNode := nil;
  FResizeEdgeSize := 12;

  FReconnectingLink := False;
  FReconnectLink := nil;
  FReconnectFixedPin := nil;
  FReconnectMovingFromSide := False;

  FDraggingLink := False;
  FTempStartMousePos := Point(0, 0);

  FPanning := False;
  FRightMouseMoved := False;
  FRightButtonDown := False;

  FPopupMenu := TPopupMenu.Create(Self);
  FPopupMenu.OnClose := @OnPopupClose;
  BuildContextMenu;
end;

destructor TLazNodeEditor.Destroy;
begin
  FController.Free;
  FSelectedNodes.Free;
  FSelectedLinks.Free;
  FDragCommandNodes.Free;
  FGraph.Free;
  inherited Destroy;
end;

procedure TLazNodeEditor.AddNode(ANode: TCustomNode);
begin
  if FController <> nil then
    FController.AddNode(ANode)
  else if (FGraph <> nil) and (ANode <> nil) then
    FGraph.ExecuteCommand(TAddNodeCommand.Create(FGraph, ANode));

  Invalidate;
end;

procedure TLazNodeEditor.RemoveNode(ANode: TCustomNode);
begin
  if ANode = nil then
    Exit;

  if FController <> nil then
    FController.RemoveNode(ANode)
  else
    FGraph.RemoveNode(ANode);

  SyncControllerSelectionToView;
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.RemoveLink(ALink: TNodeLink);
begin
  if ALink = nil then
    Exit;

  if FController <> nil then
    FController.RemoveLink(ALink)
  else
    FGraph.ExecuteCommand(TRemoveLinkCommand.Create(FGraph, ALink));

  SyncControllerSelectionToView;
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.Clear;
begin
  if FController <> nil then
    FController.Clear
  else
    FGraph.Clear;

  ResetStateAfterGraphReload;
  Invalidate;
end;

procedure TLazNodeEditor.Undo;
begin
  if FController <> nil then
    FController.Undo
  else
    FGraph.Undo;
  ResetStateAfterGraphReload;
  Invalidate;
end;

procedure TLazNodeEditor.Redo;
begin
  if FController <> nil then
    FController.Redo
  else
    FGraph.Redo;
  ResetStateAfterGraphReload;
  Invalidate;
end;

function TLazNodeEditor.SaveToJSONText: string;
begin
  if FController <> nil then
    Result := FController.SaveToJSONText(FZoom, FOffsetX, FOffsetY)
  else
    Result := '';
end;

procedure TLazNodeEditor.LoadFromJSONText(const S: string);
var
  Z: double;
  OX, OY: integer;
begin
  if Trim(S) = '' then
    Exit;

  if FController <> nil then
  begin
    FController.LoadFromJSONText(S, Z, OX, OY);
    FZoom := Z;
    FOffsetX := OX;
    FOffsetY := OY;
  end;

  ResetStateAfterGraphReload;
  Invalidate;
end;

procedure TLazNodeEditor.SaveToFile(const AFileName: string);
begin
  if FController <> nil then
    FController.SaveToFile(AFileName, FZoom, FOffsetX, FOffsetY);
end;

procedure TLazNodeEditor.LoadFromFile(const AFileName: string);
var
  Z: double;
  OX, OY: integer;
begin
  if FController <> nil then
  begin
    FController.LoadFromFile(AFileName, Z, OX, OY);
    FZoom := Z;
    FOffsetX := OX;
    FOffsetY := OY;
  end;

  ResetStateAfterGraphReload;
  Invalidate;
end;

procedure TLazNodeEditor.ClearSelectionInternal;
var
  i: integer;
begin
  for i := 0 to FSelectedNodes.Count - 1 do
    if FSelectedNodes[i] <> nil then
      TCustomNode(FSelectedNodes[i]).Selected := False;

  FSelectedNodes.Clear;
  FSelectedNode := nil;
  FSelectedLink := nil;
  FSelectedLinks.Clear;

  if (FController <> nil) and ((FController.Selection.NodeCount > 0) or
    (FController.Selection.LinkCount > 0)) then
    FController.Selection.Clear;
end;

procedure TLazNodeEditor.ClearSelection;
begin
  ClearSelectionInternal;
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.DeleteSelection;
begin
  if FController = nil then
    Exit;

  FController.DeleteSelection;
  SyncControllerSelectionToView;
  Invalidate;
end;

procedure TLazNodeEditor.SelectNodeInternal(ANode: TCustomNode; AAppend: boolean);
var
  i: integer;
begin
  if ANode = nil then
    Exit;

  if not AAppend then
  begin
    for i := 0 to FSelectedNodes.Count - 1 do
      if FSelectedNodes[i] <> nil then
        TCustomNode(FSelectedNodes[i]).Selected := False;

    FSelectedNodes.Clear;
    FSelectedNode := nil;
    FSelectedLink := nil;
  end
  else
    FSelectedLink := nil;

  if FSelectedNodes.IndexOf(ANode) < 0 then
    FSelectedNodes.Add(ANode);

  ANode.Selected := True;
  FSelectedNode := ANode;
  FSelectedLink := nil;

  if FController <> nil then
    FController.Selection.SelectNode(ANode, AAppend);
end;

procedure TLazNodeEditor.SelectLinkInternal(ALink: TNodeLink;
  AKeepNodes: boolean = False);
var
  i: integer;
begin
  if not AKeepNodes then
  begin
    for i := 0 to FSelectedNodes.Count - 1 do
      if FSelectedNodes[i] <> nil then
        TCustomNode(FSelectedNodes[i]).Selected := False;

    FSelectedNodes.Clear;
    FSelectedNode := nil;
  end;

  FSelectedLink := ALink;

  if FController <> nil then
    FController.Selection.SelectLink(ALink);
end;

procedure TLazNodeEditor.ToggleNodeSelection(ANode: TCustomNode);
begin
  if ANode = nil then Exit;

  if FSelectedNodes.IndexOf(ANode) >= 0 then
  begin
    RemoveNodeFromSelection(ANode);
  end
  else
  begin
    AddNodeToSelection(ANode);
  end;

  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.AddNodeToSelection(ANode: TCustomNode);
begin
  if ANode = nil then Exit;

  if FSelectedNodes.IndexOf(ANode) < 0 then
  begin
    FSelectedNodes.Add(ANode);
    ANode.Selected := True;
  end;

  FSelectedNode := ANode;
  FSelectedLink := nil;

  if FController <> nil then
    FController.Selection.SelectNode(ANode, True);
end;

procedure TLazNodeEditor.RemoveNodeFromSelection(ANode: TCustomNode);
var
  idx: integer;
begin
  if ANode = nil then Exit;

  idx := FSelectedNodes.IndexOf(ANode);
  if idx >= 0 then
  begin
    ANode.Selected := False;
    FSelectedNodes.Delete(idx);
  end;

  if FSelectedNode = ANode then
  begin
    if FSelectedNodes.Count > 0 then
      FSelectedNode := TCustomNode(FSelectedNodes[FSelectedNodes.Count - 1])
    else
      FSelectedNode := nil;
  end;

  if FController <> nil then
    FController.Selection.RemoveNode(ANode);
end;

procedure TLazNodeEditor.ToggleLinkSelection(ALink: TNodeLink);
begin
  if ALink = nil then Exit;

  if FSelectedLinks.IndexOf(ALink) >= 0 then
    RemoveLinkFromSelection(ALink)
  else
    AddLinkToSelection(ALink);

  if FSelectedLinks.Count > 0 then
    FSelectedLink := FSelectedLinks[0]
  else
    FSelectedLink := nil;

  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.AddLinkToSelection(ALink: TNodeLink);
begin
  if (ALink = nil) or (FSelectedLinks.IndexOf(ALink) >= 0) then Exit;

  FSelectedLinks.Add(ALink);
  if FSelectedLink = nil then
    FSelectedLink := ALink;

  if FController <> nil then
    FController.Selection.AddLinkToSelection(ALink);
end;

procedure TLazNodeEditor.RemoveLinkFromSelection(ALink: TNodeLink);
begin
  if ALink = nil then Exit;

  FSelectedLinks.Remove(ALink);

  if FSelectedLink = ALink then
  begin
    if FSelectedLinks.Count > 0 then
      FSelectedLink := FSelectedLinks[0]
    else
      FSelectedLink := nil;
  end;

  if FController <> nil then
    FController.Selection.RemoveLinkFromSelection(ALink);
end;

function TLazNodeEditor.IsMouseNearLinkStart(ALink: TNodeLink; SX, SY: integer): boolean;
var
  P0, P1: TPointF; // Using World points now
  D0, D1: double;
  MouseW: TPointF;
begin
  Result := False;

  if (ALink = nil) or (ALink.FromPin = nil) or (ALink.ToPin = nil) then
    Exit;

  MouseW := ScreenToWorld(SX, SY);
  P0 := GetPinWorldPosition(ALink.FromPin);
  P1 := GetPinWorldPosition(ALink.ToPin);

  D0 := Hypot(MouseW.X - P0.X, MouseW.Y - P0.Y);
  D1 := Hypot(MouseW.X - P1.X, MouseW.Y - P1.Y);

  Result := D0 <= D1;
end;

procedure TLazNodeEditor.NotifySelectionChanged;
begin
  if Assigned(FOnSelectionChanged) then FOnSelectionChanged(Self);
end;

procedure TLazNodeEditor.ControllerSelectionChanged(Sender: TObject);
begin
  SyncControllerSelectionToView;
end;

procedure TLazNodeEditor.SetZoom(AValue: double);
begin
  if FZoom = AValue then Exit;
  FZoom := AValue;
  if Assigned(FOnZoomChanged) then FOnZoomChanged(Self);
  Invalidate;
end;

procedure TLazNodeEditor.SyncControllerSelectionToView;
var
  i: integer;
  N: TCustomNode;
  L: TNodeLink;
begin
  if FController = nil then
    Exit;

  for i := 0 to FGraph.Nodes.Count - 1 do
    TCustomNode(FGraph.Nodes[i]).Selected := False;

  FSelectedNodes.Clear;
  FSelectedLinks.Clear;
  FSelectedNode := nil;
  FSelectedLink := nil;

  for i := 0 to FController.Selection.NodeCount - 1 do
  begin
    N := FController.Selection.GetNode(i);
    if N <> nil then
    begin
      N.Selected := True;
      FSelectedNodes.Add(N);
      FSelectedNode := N;
    end;
  end;

  for i := 0 to FController.Selection.LinkCount - 1 do
  begin
    L := FController.Selection.GetLink(i);
    if L <> nil then
      FSelectedLinks.Add(L);
  end;

  if FSelectedLinks.Count > 0 then
    FSelectedLink := FSelectedLinks[0];

  NotifySelectionChanged;
  Invalidate;
end;

function TLazNodeEditor.SelectedNodeCount: integer;
begin
  Result := FSelectedNodes.Count;
end;

function TLazNodeEditor.SelectedLinkCount: integer;
begin
  Result := FSelectedLinks.Count;
end;

function TLazNodeEditor.GetSelectedNode(Index: integer): TCustomNode;
begin
  if (Index >= 0) and (Index < FSelectedNodes.Count) then
    Result := TCustomNode(FSelectedNodes[Index])
  else
    Result := nil;
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

function TLazNodeEditor.WorldToScreen(WX, WY: single): TPoint;
begin
  Result.X := Round(WX * FZoom) + FOffsetX;
  Result.Y := Round(WY * FZoom) + FOffsetY;
end;

function TLazNodeEditor.ScreenToWorld(SX, SY: integer): TPointF;
begin
  Result.X := (SX - FOffsetX) / FZoom;
  Result.Y := (SY - FOffsetY) / FZoom;
end;

function TLazNodeEditor.GetVisibleWorldRect: TRectF;
var
  P0, P1: TPointF;
begin
  P0 := ScreenToWorld(0, 0);
  P1 := ScreenToWorld(ClientWidth, ClientHeight);

  Result.Left := Min(P0.X, P1.X);
  Result.Top := Min(P0.Y, P1.Y);
  Result.Right := Max(P0.X, P1.X);
  Result.Bottom := Max(P0.Y, P1.Y);
end;

function TLazNodeEditor.NormalizeRectF(const R: TRectF): TRectF;
begin
  Result.Left := Min(R.Left, R.Right);
  Result.Top := Min(R.Top, R.Bottom);
  Result.Right := Max(R.Left, R.Right);
  Result.Bottom := Max(R.Top, R.Bottom);
end;

function TLazNodeEditor.GetPinWorldPosition(APin: TNodePin): TPointF;
begin
  if (APin = nil) or (APin.OwnerNode = nil) then
    Exit(PointF(0, 0));
  Result := TCustomNode(APin.OwnerNode).GetPinWorldPosition(APin);
end;

procedure TLazNodeEditor.GetLinkBezierWorldPoints(ALink: TNodeLink;
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

  // Divide by FZoom to keep the visual curve consistent
  D := Dist * 0.35;
  D := EnsureRange(D, 30 / FZoom, 150 / FZoom);

  P1 := P0;
  P1.X := P1.X + D;

  P2 := P3;
  P2.X := P2.X - D;
end;

function TLazNodeEditor.SnapWorldValue(V: single): single;
begin
  if FSnapToGrid and (FGridSize > 1) then
    Result := Round(V / FGridSize) * FGridSize
  else
    Result := V;
end;

function TLazNodeEditor.SnapWorldPoint(const P: TPointF): TPointF;
begin
  Result.X := SnapWorldValue(P.X);
  Result.Y := SnapWorldValue(P.Y);
end;

procedure TLazNodeEditor.OnPopupClose(Sender: TObject);
begin
  CancelMouseOperations(False);
end;

function TLazNodeEditor.IsNodeInDragSelection(ANode: TCustomNode): boolean;
begin
  Result := (ANode <> nil) and (FDragCommandNodes.IndexOf(ANode) >= 0);
end;

function TLazNodeEditor.GetDraggedSelectionBoundsAtOffset(
  const AOffsetX, AOffsetY: single): TRectF;
var
  i: integer;
  N: TCustomNode;
  L, T, R, B: single;
  First: boolean;
begin
  Result := RectF(0, 0, 0, 0);
  First := True;

  for i := 0 to FDragCommandNodes.Count - 1 do
  begin
    N := TCustomNode(FDragCommandNodes[i]);
    if N = nil then
      Continue;

    L := FDragOldPositions[i].X + AOffsetX;
    T := FDragOldPositions[i].Y + AOffsetY;
    R := L + N.Width;
    B := T + N.Height;

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

procedure TLazNodeEditor.ApplyNodeSnap(var AOffsetX, AOffsetY: single);
var
  DragBounds: TRectF;
  OtherBounds: TRectF;
  DragLeft, DragRight, DragTop, DragBottom: single;
  DragCenterX, DragCenterY: single;
  OtherLeft, OtherRight, OtherTop, OtherBottom: single;
  OtherCenterX, OtherCenterY: single;
  BestDX, BestDY: single;
  CandDX, CandDY: single;
  BestAbsDX, BestAbsDY: single;
  D: single;
  i: integer;
  N: TCustomNode;
  BestGuideX, BestGuideY: single;
begin
  ClearSnapGuides;

  if FDragCommandNodes.Count = 0 then
    Exit;

  DragBounds := GetDraggedSelectionBoundsAtOffset(AOffsetX, AOffsetY);

  DragLeft := DragBounds.Left;
  DragRight := DragBounds.Right;
  DragTop := DragBounds.Top;
  DragBottom := DragBounds.Bottom;
  DragCenterX := (DragLeft + DragRight) * 0.5;
  DragCenterY := (DragTop + DragBottom) * 0.5;

  BestDX := 0;
  BestDY := 0;
  BestGuideX := 0;
  BestGuideY := 0;
  BestAbsDX := FNodeSnapDistance + 1;
  BestAbsDY := FNodeSnapDistance + 1;

  for i := 0 to FGraph.Nodes.Count - 1 do
  begin
    N := TCustomNode(FGraph.Nodes[i]);
    if (N = nil) or IsNodeInDragSelection(N) then
      Continue;

    OtherBounds := RectF(N.X, N.Y, N.X + N.Width, N.Y + N.Height);

    OtherLeft := OtherBounds.Left;
    OtherRight := OtherBounds.Right;
    OtherTop := OtherBounds.Top;
    OtherBottom := OtherBounds.Bottom;
    OtherCenterX := (OtherLeft + OtherRight) * 0.5;
    OtherCenterY := (OtherTop + OtherBottom) * 0.5;

    CandDX := OtherLeft - DragLeft;
    D := Abs(CandDX);
    if D < BestAbsDX then
    begin
      BestAbsDX := D;
      BestDX := CandDX;
      BestGuideX := OtherLeft;
    end;

    CandDX := OtherRight - DragRight;
    D := Abs(CandDX);
    if D < BestAbsDX then
    begin
      BestAbsDX := D;
      BestDX := CandDX;
      BestGuideX := OtherRight;
    end;

    CandDX := OtherCenterX - DragCenterX;
    D := Abs(CandDX);
    if D < BestAbsDX then
    begin
      BestAbsDX := D;
      BestDX := CandDX;
      BestGuideX := OtherCenterX;
    end;

    CandDY := OtherTop - DragTop;
    D := Abs(CandDY);
    if D < BestAbsDY then
    begin
      BestAbsDY := D;
      BestDY := CandDY;
      BestGuideY := OtherTop;
    end;

    CandDY := OtherBottom - DragBottom;
    D := Abs(CandDY);
    if D < BestAbsDY then
    begin
      BestAbsDY := D;
      BestDY := CandDY;
      BestGuideY := OtherBottom;
    end;

    CandDY := OtherCenterY - DragCenterY;
    D := Abs(CandDY);
    if D < BestAbsDY then
    begin
      BestAbsDY := D;
      BestDY := CandDY;
      BestGuideY := OtherCenterY;
    end;
  end;

  if BestAbsDX <= FNodeSnapDistance then
  begin
    FGuideSnapXActive := True;
    FGuideSnapX := BestGuideX;

    if FSnapToNodes then
      AOffsetX := AOffsetX + BestDX;
  end;

  if BestAbsDY <= FNodeSnapDistance then
  begin
    FGuideSnapYActive := True;
    FGuideSnapY := BestGuideY;

    if FSnapToNodes then
      AOffsetY := AOffsetY + BestDY;
  end;
end;

procedure TLazNodeEditor.ClearSnapGuides;
begin
  FGuideSnapXActive := False;
  FGuideSnapYActive := False;
  FGuideSnapX := 0;
  FGuideSnapY := 0;
end;

procedure TLazNodeEditor.DrawSnapGuides;
var
  SX, SY: integer;
begin
  if not FShowSnapGuides then
    Exit;

  Canvas.Pen.Style := psDash;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := clAqua;

  if FGuideSnapXActive then
  begin
    SX := Round(FGuideSnapX * FZoom) + FOffsetX;
    Canvas.MoveTo(SX, 0);
    Canvas.LineTo(SX, ClientHeight);
  end;

  if FGuideSnapYActive then
  begin
    SY := Round(FGuideSnapY * FZoom) + FOffsetY;
    Canvas.MoveTo(0, SY);
    Canvas.LineTo(ClientWidth, SY);
  end;

  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
end;

function TLazNodeEditor.GetNodeUnderMouse(SX, SY: integer): TCustomNode;
var
  i: integer;
  W: TPointF;
  N: TCustomNode;
  Sorted: TList;
begin
  Result := nil;
  W := ScreenToWorld(SX, SY);

  Sorted := TList.Create;
  try
    BuildSortedNodeList(FGraph, Sorted);

    for i := Sorted.Count - 1 downto 0 do
    begin
      N := TCustomNode(Sorted[i]);
      if (N.VisualKind <> nvComment) and N.HitTest(W.X, W.Y) then
        Exit(N);
    end;

    for i := Sorted.Count - 1 downto 0 do
    begin
      N := TCustomNode(Sorted[i]);
      if (N.VisualKind = nvComment) and N.HitTest(W.X, W.Y) then
        Exit(N);
    end;
  finally
    Sorted.Free;
  end;
end;

function TLazNodeEditor.IsLinkInsideWorldRect(ALink: TNodeLink; const R: TRectF): boolean;
var
  P0, P1, P2, P3: TPointF;
  Prev, Cur: TPointF;
  k: integer;
begin
  Result := False;

  if (ALink = nil) or (ALink.FromPin = nil) or (ALink.ToPin = nil) then
    Exit;

  if (ALink.FromPin.OwnerNode = nil) or (ALink.ToPin.OwnerNode = nil) then
    Exit;

  GetLinkBezierWorldPoints(ALink, P0, P1, P2, P3);

  if PtInRectF(P0, R) or PtInRectF(P3, R) then
    Exit(True);

  Prev := P0;
  for k := 1 to 32 do
  begin
    Cur := CubicBezierPointF(P0, P1, P2, P3, k / 32);

    if PtInRectF(Cur, R) then
      Exit(True);

    if LineIntersectsRectF(Prev, Cur, R) then
      Exit(True);

    Prev := Cur;
  end;
end;

function TLazNodeEditor.GetPinUnderMouse(SX, SY: integer; out Node: TCustomNode;
  out Pin: TNodePin): boolean;
var
  i, j: integer;
  N: TCustomNode;
  P: TNodePin;
  Sorted: TList;
  W, PW: TPointF;
  HitRadiusWorld: single;
begin
  Result := False;
  Node := nil;
  Pin := nil;

  W := ScreenToWorld(SX, SY);

  Sorted := TList.Create;
  try
    BuildSortedNodeList(FGraph, Sorted);

    for i := Sorted.Count - 1 downto 0 do
    begin
      N := TCustomNode(Sorted[i]);

      if N.VisualKind = nvComment then
        Continue;

      if N.VisualKind = nvReroute then
        HitRadiusWorld := 9 / FZoom
      else
        HitRadiusWorld := 10 / FZoom;

      for j := 0 to N.InputCount - 1 do
      begin
        P := N.GetInput(j);
        if P.Hidden then
          Continue;

        PW := GetPinWorldPosition(P);
        if Hypot(W.X - PW.X, W.Y - PW.Y) <= HitRadiusWorld then
        begin
          Node := N;
          Pin := P;
          Exit(True);
        end;
      end;

      for j := 0 to N.OutputCount - 1 do
      begin
        P := N.GetOutput(j);
        if P.Hidden then
          Continue;

        PW := GetPinWorldPosition(P);
        if Hypot(W.X - PW.X, W.Y - PW.Y) <= HitRadiusWorld then
        begin
          Node := N;
          Pin := P;
          Exit(True);
        end;
      end;
    end;
  finally
    Sorted.Free;
  end;
end;

function TLazNodeEditor.GetLinkUnderMouse(SX, SY: integer; out Link: TNodeLink): boolean;
var
  i, k: integer;
  L: TNodeLink;
  P0, P1, P2, P3: TPointF;
  M, Prev, Cur: TPointF;
  Dist: double;
  TolWorld: single;
begin
  Result := False;
  Link := nil;

  M := ScreenToWorld(SX, SY);
  TolWorld := Max(4 / FZoom, 8 / FZoom);

  for i := FGraph.Links.Count - 1 downto 0 do
  begin
    L := TNodeLink(FGraph.Links[i]);

    if (L = nil) or (L.FromPin = nil) or (L.ToPin = nil) then
      Continue;

    if (L.FromPin.OwnerNode = nil) or (L.ToPin.OwnerNode = nil) then
      Continue;

    GetLinkBezierWorldPoints(L, P0, P1, P2, P3);

    Prev := P0;
    for k := 1 to 32 do
    begin
      Cur := CubicBezierPointF(P0, P1, P2, P3, k / 32);
      Dist := DistancePointToSegment(M, Prev, Cur);

      if Dist <= TolWorld then
      begin
        Link := L;
        Exit(True);
      end;

      Prev := Cur;
    end;
  end;
end;

procedure TLazNodeEditor.DrawGrid;
var
  VR: TRectF;
  GX, GY: single;
  SX, SY: integer;
  StartX, StartY: single;
begin
  if FGridSize <= 0 then
    Exit;

  VR := GetVisibleWorldRect;

  Canvas.Pen.Color := $00E0E0E0;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;

  StartX := Floor(VR.Left / FGridSize) * FGridSize;
  GX := StartX;
  while GX <= VR.Right do
  begin
    SX := WorldToScreen(GX, 0).X;
    Canvas.MoveTo(SX, 0);
    Canvas.LineTo(SX, ClientHeight);
    GX := GX + FGridSize;
  end;

  StartY := Floor(VR.Top / FGridSize) * FGridSize;
  GY := StartY;
  while GY <= VR.Bottom do
  begin
    SY := WorldToScreen(0, GY).Y;
    Canvas.MoveTo(0, SY);
    Canvas.LineTo(ClientWidth, SY);
    GY := GY + FGridSize;
  end;
end;

procedure TLazNodeEditor.DrawAxes;
var
  VR: TRectF;
  SX, SY: integer;
begin
  if not FShowAxes then
    Exit;

  VR := GetVisibleWorldRect;

  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := FAxesColor;
  Canvas.Pen.Width := FAxesThickness;

  if (VR.Left <= 0) and (VR.Right >= 0) then
  begin
    SX := WorldToScreen(0, 0).X;
    Canvas.MoveTo(SX, 0);
    Canvas.LineTo(SX, ClientHeight);
  end;

  if (VR.Top <= 0) and (VR.Bottom >= 0) then
  begin
    SY := WorldToScreen(0, 0).Y;
    Canvas.MoveTo(0, SY);
    Canvas.LineTo(ClientWidth, SY);
  end;

  Canvas.Pen.Width := 1;
end;

procedure TLazNodeEditor.DrawLinks;
var
  i: integer;
  Link: TNodeLink;
  W0, W1, W2, W3: TPointF;
  P0, P1, P2, P3: TPoint;
begin
  for i := 0 to FGraph.Links.Count - 1 do
  begin
    Link := TNodeLink(FGraph.Links[i]);
    if (Link.FromPin = nil) or (Link.ToPin = nil) then Continue;

    GetLinkBezierWorldPoints(Link, W0, W1, W2, W3);

    P0 := WorldToScreen(W0.X, W0.Y);
    P1 := WorldToScreen(W1.X, W1.Y);
    P2 := WorldToScreen(W2.X, W2.Y);
    P3 := WorldToScreen(W3.X, W3.Y);

    if FSelectedLinks.IndexOf(Link) >= 0 then
    begin
      Canvas.Pen.Color := clRed;
      Canvas.Pen.Width := 5;
    end
    else if Link = FHoveredLink then
    begin
      Canvas.Pen.Color := clAqua;
      Canvas.Pen.Width := 5;
    end
    else
    begin
      Canvas.Pen.Color := clYellow;
      Canvas.Pen.Width := 4;
    end;

    Canvas.Pen.Style := psSolid;
    DrawCubicBezier(Canvas, P0, P1, P2, P3);
  end;
  Canvas.Pen.Width := 1;
end;

procedure TLazNodeEditor.DrawTempLink;
var
  P0, P1, P2, P3: TPoint;
  W0, W1, W2, W3: TPointF;
  StartPin: TNodePin;
  FixedPosW: TPointF;
  DX, DY, Dist, D: Single;
begin
  if FTempFromPin = nil then
    Exit;

  Canvas.Pen.Color := clYellow;
  Canvas.Pen.Width := 3;
  Canvas.Pen.Style := psDot;

  StartPin := FTempFromPin;

  if FReconnectingLink and (FReconnectFixedPin <> nil) then
  begin
    FixedPosW := GetPinWorldPosition(FReconnectFixedPin);

    if FReconnectMovingFromSide then
    begin
      W0 := ScreenToWorld(FTempMousePos.X, FTempMousePos.Y);
      W3 := FixedPosW;
    end
    else
    begin
      W0 := FixedPosW;
      W3 := ScreenToWorld(FTempMousePos.X, FTempMousePos.Y);
      StartPin := FReconnectFixedPin;
    end;
  end
  else
  begin
    W0 := GetPinWorldPosition(FTempFromPin);
    W3 := ScreenToWorld(FTempMousePos.X, FTempMousePos.Y);
  end;

  DX := W3.X - W0.X;
  DY := W3.Y - W0.Y;
  Dist := Hypot(DX, DY);
  D := EnsureRange(Dist * 0.35, 30 / FZoom, 150 / FZoom);

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

  P0 := WorldToScreen(W0.X, W0.Y);
  P1 := WorldToScreen(W1.X, W1.Y);
  P2 := WorldToScreen(W2.X, W2.Y);
  P3 := WorldToScreen(W3.X, W3.Y);

  DrawCubicBezier(Canvas, P0, P1, P2, P3, 24);

  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
end;

procedure TLazNodeEditor.DrawBoxSelect;
var
  R: TRect;
begin
  if not FBoxSelecting then Exit;
  R := NormalizeRect(Rect(FBoxStart.X, FBoxStart.Y, FBoxCurrent.X, FBoxCurrent.Y));
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := clBlue;
  Canvas.Pen.Style := psDash;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(R);
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Style := bsSolid;
end;

procedure TLazNodeEditor.Paint;
var
  i: integer;
  N: TCustomNode;
  R: TRect;
  Sorted: TList;
  CX, CY, DX, DY: single;
  Txt: string;
  TX, TY: integer;
  ScreenPos: TPoint;

  procedure PaintResizeHandles;
  var
    k: integer;
    SN: TCustomNode;
    HR: TRect;
  begin
    for k := 0 to FGraph.Nodes.Count - 1 do
    begin
      SN := TCustomNode(FGraph.Nodes[k]);

      if SN.VisualKind = nvReroute then
        Continue;

      if SN.Selected then
      begin
        HR := GetResizeHandleRect(SN);

        Canvas.Brush.Style := bsSolid;
        Canvas.Brush.Color := clGray;
        Canvas.Pen.Style := psSolid;
        Canvas.Pen.Color := clBlack;
        Canvas.Pen.Width := 1;
        Canvas.Rectangle(HR);
      end;
    end;
  end;

begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  DrawGrid;
  DrawAxes;

  Sorted := TList.Create;
  try
    BuildSortedNodeList(FGraph, Sorted);

    for i := 0 to Sorted.Count - 1 do
    begin
      N := TCustomNode(Sorted[i]);
      if (N.VisualKind = nvComment) and not N.Selected then
        N.Paint(Canvas, FZoom, FOffsetX, FOffsetY);
    end;

    for i := 0 to Sorted.Count - 1 do
    begin
      N := TCustomNode(Sorted[i]);
      if (N.VisualKind = nvComment) and N.Selected then
        N.Paint(Canvas, FZoom, FOffsetX, FOffsetY);
    end;

    DrawLinks;

    for i := 0 to Sorted.Count - 1 do
    begin
      N := TCustomNode(Sorted[i]);
      if (N.VisualKind <> nvComment) and not N.Selected then
        N.Paint(Canvas, FZoom, FOffsetX, FOffsetY);
    end;

    for i := 0 to Sorted.Count - 1 do
    begin
      N := TCustomNode(Sorted[i]);
      if (N.VisualKind <> nvComment) and N.Selected then
        N.Paint(Canvas, FZoom, FOffsetX, FOffsetY);
    end;

    PaintResizeHandles;
  finally
    Sorted.Free;
  end;

  if FDraggingNode then
    DrawSnapGuides;

  DrawTempLink;
  DrawBoxSelect;

  if FDraggingNode and FShowDragCoordinates and (FSelectedNode <> nil) and
    ((GetKeyState(VK_MENU) and $8000) <> 0) then
  begin
    Canvas.Font.Color := clBlack;
    Canvas.Font.Size := 9;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := $00FFFFCC;

    CX := FSelectedNode.X;
    CY := FSelectedNode.Y;
    DX := CX - FDragStartWorldPos.X;
    DY := CY - FDragStartWorldPos.Y;

    Txt := Format('X: %.1f   Y: %.1f   (Δ %.1f, %.1f)', [CX, CY, DX, DY]);

    ScreenPos := WorldToScreen(CX, CY);
    TX := ScreenPos.X + Round(10 * FZoom);
    TY := ScreenPos.Y - Round(25 * FZoom);

    Canvas.FillRect(Rect(TX - 4, TY - 2, TX + Canvas.TextWidth(Txt) + 6, TY + 16));
    Canvas.TextOut(TX, TY, Txt);

    Canvas.Brush.Style := bsSolid;
  end;
end;

function TLazNodeEditor.GetResizeHandleRect(ANode: TCustomNode): TRect;
var
  R: TRect;
  S: integer;
begin
  Result := Rect(0, 0, 0, 0);
  if ANode = nil then
    Exit;

  R := ANode.GetScreenBounds(FZoom, FOffsetX, FOffsetY);
  S := Max(10, Round(FResizeEdgeSize * FZoom));
  Result := Rect(R.Right - S, R.Bottom - S, R.Right + 1, R.Bottom + 1);
end;

function TLazNodeEditor.GetNodeResizeUnderMouse(SX, SY: integer): TCustomNode;
var
  i: integer;
  N: TCustomNode;
  HR: TRect;
begin
  Result := nil;

  for i := FGraph.Nodes.Count - 1 downto 0 do
  begin
    N := TCustomNode(FGraph.Nodes[i]);

    if N.VisualKind = nvReroute then
      Continue;

    HR := GetResizeHandleRect(N);
    if PtInRect(HR, Point(SX, SY)) then
      Exit(N);
  end;
end;

procedure TLazNodeEditor.BuildContextMenu;
var
  AddRoot: TMenuItem;
  Item: TMenuItem;
  Sep: TMenuItem;
  i: integer;
  RegItem: TNodeRegistryItem;
begin
  FPopupMenu.Items.Clear;

  Item := TMenuItem.Create(FPopupMenu);
  Item.Caption := 'Search Node...';
  Item.OnClick := @OnContextSearchNode;
  FPopupMenu.Items.Add(Item);

  Sep := TMenuItem.Create(FPopupMenu);
  Sep.Caption := '-';
  FPopupMenu.Items.Add(Sep);

  AddRoot := TMenuItem.Create(FPopupMenu);
  AddRoot.Caption := 'Add Node';
  FPopupMenu.Items.Add(AddRoot);
  for i := 0 to FGraph.Registry.Count - 1 do
  begin
    RegItem := FGraph.Registry.Item(i);
    Item := TMenuItem.Create(FPopupMenu);
    Item.Caption := RegItem.Caption;
    Item.Tag := PtrInt(RegItem);
    Item.OnClick := @OnAddRegisteredNodeClick;
    AddRoot.Add(Item);
  end;

  Sep := TMenuItem.Create(FPopupMenu);
  Sep.Caption := '-';
  FPopupMenu.Items.Add(Sep);

  Item := TMenuItem.Create(FPopupMenu);
  Item.Caption := 'Copy';
  Item.ShortCut := ShortCut(Ord('C'), [ssCtrl]);
  Item.OnClick := @OnContextCopy;
  FPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FPopupMenu);
  Item.Caption := 'Paste';
  Item.ShortCut := ShortCut(Ord('V'), [ssCtrl]);
  Item.OnClick := @OnContextPaste;
  FPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FPopupMenu);
  Item.Caption := 'Duplicate';
  Item.ShortCut := ShortCut(Ord('D'), [ssCtrl]);
  Item.OnClick := @OnContextDuplicate;
  FPopupMenu.Items.Add(Item);

  Sep := TMenuItem.Create(FPopupMenu);
  Sep.Caption := '-';
  FPopupMenu.Items.Add(Sep);

  Item := TMenuItem.Create(FPopupMenu);
  Item.Caption := 'Insert Reroute On Selected Link';
  Item.OnClick := @OnContextInsertReroute;
  FPopupMenu.Items.Add(Item);

  Item := TMenuItem.Create(FPopupMenu);
  Item.Caption := 'Add Comment / Frame';
  Item.OnClick := @OnContextAddComment;
  FPopupMenu.Items.Add(Item);

  Sep := TMenuItem.Create(FPopupMenu);
  Sep.Caption := '-';
  FPopupMenu.Items.Add(Sep);

  Item := TMenuItem.Create(FPopupMenu);
  Item.Caption := 'Delete';
  Item.OnClick := @OnContextDelete;
  FPopupMenu.Items.Add(Item);
end;

procedure TLazNodeEditor.OnAddRegisteredNodeClick(Sender: TObject);
var
  It: TNodeRegistryItem;
  N: TCustomNode;
begin
  It := TNodeRegistryItem(TMenuItem(Sender).Tag);
  if It = nil then Exit;
  N := FGraph.Registry.CreateNode(It.NodeType, SnapWorldValue(FContextWorldPos.X),
    SnapWorldValue(FContextWorldPos.Y));
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
var
  P: TPoint;
begin
  P := Mouse.CursorPos;
  ShowNodeSearchPopup(P.X, P.Y, FContextWorldPos.X, FContextWorldPos.Y);
end;

procedure TLazNodeEditor.OnContextInsertReroute(Sender: TObject);
var
  N: TCustomNode;
begin
  if (FController = nil) or (FSelectedLink = nil) then
    Exit;

  N := FController.InsertRerouteOnLink(FSelectedLink,
    SnapWorldValue(FContextWorldPos.X), SnapWorldValue(FContextWorldPos.Y));

  SyncControllerSelectionToView;

  if N <> nil then
    FSelectedLink := nil;

  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.OnContextAddComment(Sender: TObject);
begin
  if FController = nil then
    Exit;

  FController.AddCommentNode(
    SnapWorldValue(FContextWorldPos.X),
    SnapWorldValue(FContextWorldPos.Y));

  SyncControllerSelectionToView;
  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.CopySelectionToClipboard;
begin
  if FController <> nil then
    FController.CopySelectionToClipboard;
end;

procedure TLazNodeEditor.PasteFromClipboard;
begin
  if FController <> nil then
  begin
    FController.PasteFromClipboard(
      SnapWorldValue(FContextWorldPos.X),
      SnapWorldValue(FContextWorldPos.Y)
      );
    SyncControllerSelectionToView;
    Invalidate;
  end;
end;

procedure TLazNodeEditor.DuplicateSelection;
var
  W: TPointF;
begin
  if FController = nil then
    Exit;

  W := ScreenToWorld(ClientWidth div 2, ClientHeight div 2);

  FController.DuplicateSelection(
    SnapWorldValue(W.X + 25),
    SnapWorldValue(W.Y + 25)
    );

  SyncControllerSelectionToView;
  Invalidate;
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

procedure TLazNodeEditor.ResetStateAfterGraphReload;
var
  OldHandler: TNotifyEvent;
begin
  FSelectedNodes.Clear;
  FSelectedNode := nil;
  FSelectedLink := nil;

  if FController <> nil then
  begin
    OldHandler := FController.Selection.OnChanged;
    FController.Selection.OnChanged := nil;
    try
      FController.Selection.Clear;
    finally
      FController.Selection.OnChanged := OldHandler;
    end;
  end;

  FHoveredNode := nil;
  FHoveredPin := nil;
  FHoveredLink := nil;

  FTempFromPin := nil;
  FDraggingLink := False;
  FDraggingNode := False;
  FShowDragCoordinates := False;
  FBoxSelecting := False;
  FResizingNode := False;
  FResizeNode := nil;

  FReconnectingLink := False;
  FReconnectLink := nil;
  FReconnectFixedPin := nil;

  FPanning := False;
  FRightMouseMoved := False;
  FRightButtonDown := False;
  MouseCapture := False;
  Cursor := crDefault;
  ClearSnapGuides;
  ClearHoverStates;
  NotifySelectionChanged;
end;

procedure TLazNodeEditor.ClearHoverStates;
var
  i: integer;
begin
  for i := 0 to FGraph.Nodes.Count - 1 do
  begin
    TCustomNode(FGraph.Nodes[i]).Hovered := False;
    TCustomNode(FGraph.Nodes[i]).Highlighted := False;
  end;

  FHoveredNode := nil;
  FHoveredPin := nil;
  FHoveredLink := nil;
end;

procedure TLazNodeEditor.UpdateHoverStates(SX, SY: integer);
var
  N: TCustomNode;
  P: TNodePin;
  L: TNodeLink;
  i: integer;
begin
  ClearHoverStates;

  if GetPinUnderMouse(SX, SY, N, P) then
  begin
    FHoveredNode := N;
    FHoveredPin := P;
    N.Highlighted := True;

    if FTempFromPin <> nil then
    begin
      for i := 0 to FGraph.Nodes.Count - 1 do
        TCustomNode(FGraph.Nodes[i]).Highlighted := False;

      if FGraph.CanConnect(FTempFromPin, P) then
        N.Highlighted := True;
    end;

    Exit;
  end;

  if GetLinkUnderMouse(SX, SY, L) then
  begin
    FHoveredLink := L;
    Exit;
  end;

  N := GetNodeUnderMouse(SX, SY);
  if N <> nil then
  begin
    FHoveredNode := N;
    N.Hovered := True;
  end;
end;

procedure TLazNodeEditor.FitToSelection;
var
  i: integer;
  N: TCustomNode;
  R, NR: TRect;
  First: boolean;
  W, H: double;
  Margin: integer;
begin
  if FSelectedNodes.Count = 0 then Exit;

  First := True;

  for i := 0 to FSelectedNodes.Count - 1 do
  begin
    N := TCustomNode(FSelectedNodes[i]);
    NR := Rect(Round(N.X), Round(N.Y), Round(N.X + N.Width), Round(N.Y + N.Height));

    if First then
    begin
      R := NR;
      First := False;
    end
    else
      R := UnionRectSafe(R, NR);
  end;

  W := Max(1, R.Right - R.Left);
  H := Max(1, R.Bottom - R.Top);

  Margin := 60;

  FZoom := Min((ClientWidth - Margin * 2) / W, (ClientHeight - Margin * 2) / H);
  FZoom := EnsureRange(FZoom, 0.25, 3.0);

  FOffsetX := Margin - Round(R.Left * FZoom);
  FOffsetY := Margin - Round(R.Top * FZoom);

  Invalidate;
end;

procedure TLazNodeEditor.FrameAll;
var
  i: integer;
  N: TCustomNode;
  MinX, MinY, MaxX, MaxY: double;
  W, H: double;
  ViewW, ViewH: double;
  Margin: integer;
  Cx, Cy: double;
  First: boolean;
begin
  if FGraph.Nodes.Count = 0 then
    Exit;

  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;

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
      MinX := Min(MinX, N.X);
      MinY := Min(MinY, N.Y);
      MaxX := Max(MaxX, N.X + N.Width);
      MaxY := Max(MaxY, N.Y + N.Height);
    end;
  end;

  W := Max(1, MaxX - MinX);
  H := Max(1, MaxY - MinY);

  Margin := 60;
  ViewW := Max(1, ClientWidth - Margin * 2);
  ViewH := Max(1, ClientHeight - Margin * 2);

  FZoom := Min(ViewW / W, ViewH / H);
  FZoom := EnsureRange(FZoom, 0.25, 3.0);

  Cx := (MinX + MaxX) * 0.5;
  Cy := (MinY + MaxY) * 0.5;

  FOffsetX := Round(ClientWidth * 0.5 - Cx * FZoom);
  FOffsetY := Round(ClientHeight * 0.5 - Cy * FZoom);

  Invalidate;
end;

function TLazNodeEditor.ValidateGraphToStrings(AStrings: TStrings): boolean;
begin
  if FController <> nil then
    Result := FController.ValidateGraphToStrings(AStrings)
  else
    Result := False;
end;

function TLazNodeEditor.AddInputPinToNode(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
begin
  Result := nil;

  if FController <> nil then
    Result := FController.AddInputPinToNode(ANode, AName, ADataType, AKind);

  if (Result <> nil) and Assigned(FOnNodeChanged) then
    FOnNodeChanged(Self, ANode);

  Invalidate;
end;

function TLazNodeEditor.AddOutputPinToNode(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
begin
  Result := nil;

  if FController <> nil then
    Result := FController.AddOutputPinToNode(ANode, AName, ADataType, AKind);

  if (Result <> nil) and Assigned(FOnNodeChanged) then
    FOnNodeChanged(Self, ANode);

  Invalidate;
end;

function TLazNodeEditor.RemovePinFromNode(APin: TNodePin): boolean;
var
  N: TCustomNode;
begin
  Result := False;
  N := nil;

  if APin <> nil then
    N := TCustomNode(APin.OwnerNode);

  if FController <> nil then
    Result := FController.RemovePinFromNode(APin);

  if Result and Assigned(FOnNodeChanged) and (N <> nil) then
    FOnNodeChanged(Self, N);

  Invalidate;
end;

procedure TLazNodeEditor.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  Node: TCustomNode;
  Pin: TNodePin;
  Link: TNodeLink;
  i: integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  SetFocus;

  if Button = mbLeft then
  begin
    ClearSnapGuides;
    Node := GetNodeResizeUnderMouse(X, Y);
    if Node <> nil then
    begin
      if FSelectedNodes.IndexOf(Node) < 0 then
      begin
        SelectNodeInternal(Node, False);
        NotifySelectionChanged;
      end;

      FResizingNode := True;
      FResizeNode := Node;
      FResizeStartMouseX := X;
      FResizeStartMouseY := Y;
      FResizeStartWidth := Node.Width;
      FResizeStartHeight := Node.Height;
      FResizeStartX := Node.X;
      FResizeStartY := Node.Y;
      FResizeOldWidth := Node.Width;
      FResizeOldHeight := Node.Height;
      FDragUndoPushed := False;
      Invalidate;
      Exit;
    end;

    if GetPinUnderMouse(X, Y, Node, Pin) then
    begin
      FTempFromPin := Pin;
      FTempMousePos := Point(X, Y);
      FTempStartMousePos := Point(X, Y);
      FDraggingLink := False;
      Invalidate;
      Exit;
    end;

    if GetLinkUnderMouse(X, Y, Link) then
    begin
      if (ssCtrl in Shift) or (ssShift in Shift) then
      begin
        ToggleLinkSelection(Link);
      end
      else
      begin
        ClearSelectionInternal;
        FSelectedLinks.Clear;
        FSelectedLink := Link;
        FSelectedLinks.Add(Link);
        if FController <> nil then
          FController.Selection.SelectLink(Link, False);
      end;

      FDraggingNode := False;

      FReconnectingLink := True;
      FReconnectLink := Link;
      FReconnectMovingFromSide := IsMouseNearLinkStart(Link, X, Y);

      if FReconnectMovingFromSide then
      begin
        FTempFromPin := Link.FromPin;
        FReconnectFixedPin := Link.ToPin;
      end
      else
      begin
        FTempFromPin := Link.ToPin;
        FReconnectFixedPin := Link.FromPin;
      end;

      FTempMousePos := Point(X, Y);
      FTempStartMousePos := Point(X, Y);
      FDraggingLink := False;

      NotifySelectionChanged;
      Invalidate;
      Exit;
    end;

    Node := GetNodeUnderMouse(X, Y);
    if Node <> nil then
    begin
      if (ssCtrl in Shift) or (ssShift in Shift) then
      begin
        ToggleNodeSelection(Node);
      end
      else
      begin
        if FSelectedNodes.IndexOf(Node) < 0 then
          SelectNodeInternal(Node, False)
        else
          FSelectedNode := Node;
      end;

      FDraggingNode := True;
      FDragUndoPushed := False;
      FDragStartX := X;
      FDragStartY := Y;
      FDragAnchorX := X;
      FDragAnchorY := Y;
      FShowDragCoordinates := True;

      if FSelectedNode <> nil then
        FDragStartWorldPos := PointF(FSelectedNode.X, FSelectedNode.Y)
      else if FSelectedNodes.Count > 0 then
        FDragStartWorldPos := PointF(TCustomNode(FSelectedNodes[0]).X,
          TCustomNode(FSelectedNodes[0]).Y);

      FDragCommandNodes.Clear;
      SetLength(FDragOldPositions, FSelectedNodes.Count);

      for i := 0 to FSelectedNodes.Count - 1 do
      begin
        FDragCommandNodes.Add(FSelectedNodes[i]);
        FDragOldPositions[i] :=
          PointF(TCustomNode(FSelectedNodes[i]).X,
          TCustomNode(FSelectedNodes[i]).Y);
      end;

      NotifySelectionChanged;
      Invalidate;
      Exit;
    end;

    if not (ssShift in Shift) then
      ClearSelectionInternal;

    FBoxSelecting := True;
    FBoxStart := Point(X, Y);
    FBoxCurrent := Point(X, Y);
    FBoxStartWorld := ScreenToWorld(X, Y);
    FBoxCurrentWorld := FBoxStartWorld;
    NotifySelectionChanged;
    Invalidate;
  end
  else if Button = mbRight then
  begin
    FContextWorldPos := ScreenToWorld(X, Y);

    if GetLinkUnderMouse(X, Y, Link) then
    begin
      SelectLinkInternal(Link);
      NotifySelectionChanged;
      Invalidate;
    end;

    FRightButtonDown := True;
    FRightMouseMoved := False;
    FPanning := False;
    FPanStartX := X;
    FPanStartY := Y;
  end;
end;

procedure TLazNodeEditor.MouseMove(Shift: TShiftState; X, Y: integer);
var
  i: integer;
  N: TCustomNode;
  Dx, Dy: single;
  BaseX, BaseY: single;
begin
  inherited MouseMove(Shift, X, Y);

  UpdateHoverStates(X, Y);

  if (not FPanning) and (not FDraggingNode) and (not FBoxSelecting) and
    (not FResizingNode) and (FTempFromPin = nil) then
  begin
    if GetNodeResizeUnderMouse(X, Y) <> nil then
      Cursor := crSizeNWSE
    else
      Cursor := crDefault;
  end;

  if FRightButtonDown and (not FPanning) then
  begin
    if (Abs(X - FPanStartX) > 2) or (Abs(Y - FPanStartY) > 2) then
    begin
      FPanning := True;
      FRightMouseMoved := True;
      MouseCapture := True;
      Cursor := crSizeAll;
    end;
  end;

  if FPanning then
  begin
    FOffsetX := FOffsetX + (X - FPanStartX);
    FOffsetY := FOffsetY + (Y - FPanStartY);
    FPanStartX := X;
    FPanStartY := Y;
    Invalidate;
  end
  else if FResizingNode and (FResizeNode <> nil) then
  begin
    FResizeNode.Width := Max(40, FResizeStartWidth + Round(
      (X - FResizeStartMouseX) / FZoom));
    FResizeNode.Height := Max(28, FResizeStartHeight + Round(
      (Y - FResizeStartMouseY) / FZoom));

    if FResizeNode.VisualKind = nvReroute then
    begin
      FResizeNode.Width := Max(12, FResizeNode.Width);
      FResizeNode.Height := FResizeNode.Width;
    end;

    if Assigned(FOnNodeChanged) then
      FOnNodeChanged(Self, FResizeNode);

    Invalidate;
  end
  else if FDraggingNode and (FSelectedNodes.Count > 0) then
  begin
    Dx := (X - FDragAnchorX) / FZoom;
    Dy := (Y - FDragAnchorY) / FZoom;

    if FSnapToGrid and not (ssAlt in Shift) then
    begin
      if FDragCommandNodes.Count > 0 then
      begin
        BaseX := FDragOldPositions[0].X;
        BaseY := FDragOldPositions[0].Y;

        Dx := SnapWorldValue(BaseX + Dx) - BaseX;
        Dy := SnapWorldValue(BaseY + Dy) - BaseY;
      end;
    end;

    ApplyNodeSnap(Dx, Dy);

    for i := 0 to FDragCommandNodes.Count - 1 do
    begin
      N := TCustomNode(FDragCommandNodes[i]);
      BaseX := FDragOldPositions[i].X;
      BaseY := FDragOldPositions[i].Y;

      N.X := BaseX + Dx;
      N.Y := BaseY + Dy;

      if Assigned(FOnNodeChanged) then
        FOnNodeChanged(Self, N);
    end;

    Invalidate;
  end
  else if FTempFromPin <> nil then
  begin
    FTempMousePos := Point(X, Y);

    if (Abs(X - FTempStartMousePos.X) > 4) or (Abs(Y - FTempStartMousePos.Y) > 4) then
      FDraggingLink := True;

    Invalidate;
  end
  else if FBoxSelecting then
  begin
    FBoxCurrent := Point(X, Y);
    FBoxCurrentWorld := ScreenToWorld(X, Y);
    Invalidate;
  end;
end;

procedure TLazNodeEditor.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  TargetNode: TCustomNode;
  TargetPin: TNodePin;
  L: TNodeLink;
  R: TRectF; // World Rect
  i: integer;
  N: TCustomNode;
  NewPositions: array of TPointF;
  Moved: boolean;
  K: integer;
  DN: TCustomNode;
begin
  inherited MouseUp(Button, Shift, X, Y);

  if Button = mbLeft then
  begin
    if FResizingNode then
    begin
      if (FResizeNode <> nil) and ((FResizeNode.Width <> FResizeOldWidth) or
        (FResizeNode.Height <> FResizeOldHeight)) then
      begin
        K := FResizeNode.Width;
        i := FResizeNode.Height;

        FResizeNode.Width := FResizeOldWidth;
        FResizeNode.Height := FResizeOldHeight;

        FGraph.ExecuteCommand(TResizeNodeCommand.Create(FGraph,
          FResizeNode, FResizeOldWidth, FResizeOldHeight, K, i));
      end;

      FResizingNode := False;
      FResizeNode := nil;
      FDragUndoPushed := False;
      Invalidate;
      Exit;
    end;

    if FTempFromPin <> nil then
    begin
      if FReconnectingLink then
      begin
        if GetPinUnderMouse(X, Y, TargetNode, TargetPin) and
          (TargetPin <> nil) and (FReconnectFixedPin <> nil) then
        begin
          if FReconnectMovingFromSide then
          begin
            if FGraph.CanConnect(TargetPin, FReconnectFixedPin) then
            begin
              FGraph.RemoveLink(FReconnectLink);
              FGraph.AddLink(TNodeLink.Create(TargetPin, FReconnectFixedPin));
            end;
          end
          else
          begin
            if FGraph.CanConnect(FReconnectFixedPin, TargetPin) then
            begin
              FGraph.RemoveLink(FReconnectLink);
              FGraph.AddLink(TNodeLink.Create(FReconnectFixedPin, TargetPin));
            end;
          end;
        end;

        FTempFromPin := nil;
        FDraggingLink := False;
        FReconnectingLink := False;
        FReconnectLink := nil;
        FReconnectFixedPin := nil;

        Invalidate;
        Exit;
      end;

      if GetPinUnderMouse(X, Y, TargetNode, TargetPin) and
        FGraph.CanConnect(FTempFromPin, TargetPin) then
      begin
        if FTempFromPin.Direction = pdOutput then
        begin
          if not FGraph.LinkExists(FTempFromPin, TargetPin) then
            FGraph.ExecuteCommand(TAddLinkCommand.Create(FGraph,
              FTempFromPin, TargetPin));
        end
        else
        begin
          if not FGraph.LinkExists(TargetPin, FTempFromPin) then
            FGraph.ExecuteCommand(TAddLinkCommand.Create(FGraph,
              TargetPin, FTempFromPin));
        end;
      end
      else if FDraggingLink then
      begin
        if FController <> nil then
          TargetNode := FController.CreateCompatibleNodeForPin(FTempFromPin,
            SnapWorldValue(ScreenToWorld(X, Y).X),
            SnapWorldValue(ScreenToWorld(X, Y).Y))
        else
          TargetNode := nil;

        if TargetNode <> nil then
        begin
          FGraph.ExecuteCommand(TAddNodeCommand.Create(FGraph, TargetNode));

          if FTempFromPin.Direction = pdOutput then
          begin
            for i := 0 to TargetNode.InputCount - 1 do
            begin
              TargetPin := TargetNode.GetInput(i);
              if FGraph.CanConnect(FTempFromPin, TargetPin) then
              begin
                FGraph.ExecuteCommand(TAddLinkCommand.Create(FGraph,
                  FTempFromPin, TargetPin));
                Break;
              end;
            end;
          end
          else
          begin
            for i := 0 to TargetNode.OutputCount - 1 do
            begin
              TargetPin := TargetNode.GetOutput(i);
              if FGraph.CanConnect(TargetPin, FTempFromPin) then
              begin
                FGraph.ExecuteCommand(TAddLinkCommand.Create(FGraph,
                  TargetPin, FTempFromPin));
                Break;
              end;
            end;
          end;

          SelectNodeInternal(TargetNode, False);
          NotifySelectionChanged;
        end
        else
        begin
          ShowNodeSearchPopup(Mouse.CursorPos.X, Mouse.CursorPos.Y,
            ScreenToWorld(X, Y).X, ScreenToWorld(X, Y).Y);
        end;
      end;

      FTempFromPin := nil;
      FDraggingLink := False;
      Invalidate;
    end;

    if FDraggingNode and (FDragCommandNodes.Count > 0) then
    begin
      SetLength(NewPositions, FDragCommandNodes.Count);
      Moved := False;

      for K := 0 to FDragCommandNodes.Count - 1 do
      begin
        DN := TCustomNode(FDragCommandNodes[K]);
        NewPositions[K] := PointF(DN.X, DN.Y);

        if (Abs(NewPositions[K].X - FDragOldPositions[K].X) > 0.01) or
          (Abs(NewPositions[K].Y - FDragOldPositions[K].Y) > 0.01) then
          Moved := True;
      end;

      if Moved then
      begin
        for K := 0 to FDragCommandNodes.Count - 1 do
        begin
          DN := TCustomNode(FDragCommandNodes[K]);
          DN.X := FDragOldPositions[K].X;
          DN.Y := FDragOldPositions[K].Y;
        end;

        FGraph.ExecuteCommand(TMoveNodesCommand.Create(FGraph,
          FDragCommandNodes, FDragOldPositions, NewPositions));
      end;
    end;

    FDraggingNode := False;
    FDragUndoPushed := False;
    FShowDragCoordinates := False;
    FDragCommandNodes.Clear;
    SetLength(FDragOldPositions, 0);
    ClearSnapGuides;

    if FBoxSelecting then
    begin
      // Use World Rect for selection
      R := NormalizeRectF(RectF(FBoxStartWorld.X, FBoxStartWorld.Y, FBoxCurrentWorld.X, FBoxCurrentWorld.Y));

      if not (ssCtrl in Shift) and not (ssShift in Shift) then
        ClearSelectionInternal;

      if ssShift in Shift then
      begin
        for i := 0 to FGraph.Nodes.Count - 1 do
        begin
          N := TCustomNode(FGraph.Nodes[i]);
          if RectFIntersects(R, RectF(N.X, N.Y, N.X + N.Width, N.Y + N.Height)) then
            AddNodeToSelection(N);
        end;
      end
      else if ssCtrl in Shift then
      begin
        for i := 0 to FGraph.Links.Count - 1 do
        begin
          L := TNodeLink(FGraph.Links[i]);
          if IsLinkInsideWorldRect(L, R) then
            AddLinkToSelection(L);
        end;
      end
      else
      begin
        for i := 0 to FGraph.Nodes.Count - 1 do
        begin
          N := TCustomNode(FGraph.Nodes[i]);
          if RectFIntersects(R, RectF(N.X, N.Y, N.X + N.Width, N.Y + N.Height)) then
            AddNodeToSelection(N);
        end;

        for i := 0 to FGraph.Links.Count - 1 do
        begin
          L := TNodeLink(FGraph.Links[i]);
          if IsLinkInsideWorldRect(L, R) then
            AddLinkToSelection(L);
        end;
      end;

      FBoxSelecting := False;
      NotifySelectionChanged;
      Invalidate;
    end;
  end
  else if Button = mbRight then
  begin
    FRightButtonDown := False;

    if not FRightMouseMoved then
    begin
      FContextWorldPos := ScreenToWorld(X, Y);

      FPanning := False;
      MouseCapture := False;
      Cursor := crDefault;

      FPopupMenu.PopUp(Mouse.CursorPos.X, Mouse.CursorPos.Y);

      FPanning := False;
      FRightMouseMoved := False;
      MouseCapture := False;
      Cursor := crDefault;
    end
    else
    begin
      FPanning := False;
      FRightMouseMoved := False;
      MouseCapture := False;
      Cursor := crDefault;
    end;

    Invalidate;
  end;
end;

function TLazNodeEditor.DoMouseWheel(Shift: TShiftState; WheelDelta: integer;
  MousePos: TPoint): boolean;
var
  OldZoom: double;
begin
  inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  Result := True;
  OldZoom := FZoom;
  if WheelDelta > 0 then FZoom := FZoom * 1.15
  else
    FZoom := FZoom / 1.15;
  FZoom := EnsureRange(FZoom, 0.25, 3.0);
  FOffsetX := MousePos.X - Round((MousePos.X - FOffsetX) * (FZoom / OldZoom));
  FOffsetY := MousePos.Y - Round((MousePos.Y - FOffsetY) * (FZoom / OldZoom));
  if Assigned(FOnZoomChanged) then
    FOnZoomChanged(Self);
  Invalidate;
end;

procedure TLazNodeEditor.CancelMouseOperations(const KeepSelectionRect: boolean);
begin
  FPanning := False;
  FRightButtonDown := False;
  FRightMouseMoved := False;

  FDraggingNode := False;
  FDragUndoPushed := False;
  FDragCommandNodes.Clear;
  SetLength(FDragOldPositions, 0);

  FTempFromPin := nil;
  FDraggingLink := False;
  FReconnectingLink := False;
  FReconnectLink := nil;
  FReconnectFixedPin := nil;
  FReconnectMovingFromSide := False;

  FResizingNode := False;
  FResizeNode := nil;

  if not KeepSelectionRect then
    FBoxSelecting := False;

  ClearSnapGuides;
  MouseCapture := False;
  Cursor := crDefault;
  Invalidate;
end;

procedure TLazNodeEditor.DoExit;
begin
  CancelMouseOperations;
  inherited DoExit;
end;

procedure TLazNodeEditor.MouseLeave;
begin
  inherited MouseLeave;

  if not (csDesigning in ComponentState) then
    CancelMouseOperations(False);
end;

procedure TLazNodeEditor.KeyDown(var Key: word; Shift: TShiftState);
var
  i: integer;
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_DELETE) then
  begin
    DeleteSelection;
    Key := 0;
    Exit;
  end;
  if (Key = Ord('Z')) and (ssCtrl in Shift) then
  begin
    Undo;
    Key := 0;
    Exit;
  end;
  if (Key = Ord('Y')) and (ssCtrl in Shift) then
  begin
    Redo;
    Key := 0;
    Exit;
  end;
  if (Key = Ord('C')) and (ssCtrl in Shift) then
  begin
    CopySelectionToClipboard;
    Key := 0;
    Exit;
  end;
  if (Key = Ord('V')) and (ssCtrl in Shift) then
  begin
    FContextWorldPos := ScreenToWorld(ClientWidth div 2, ClientHeight div 2);
    PasteFromClipboard;
    Key := 0;
    Exit;
  end;
  if (Key = Ord('D')) and (ssCtrl in Shift) then
  begin
    DuplicateSelection;
    Key := 0;
    Exit;
  end;
  if (Key = Ord('F')) then
  begin
    if FSelectedNodes.Count > 0 then
      FitToSelection
    else
      FrameAll;

    Key := 0;
    Exit;
  end;

  if (Key = Ord('A')) and (ssCtrl in Shift) and (ssShift in Shift) then
  begin
    ClearSelectionInternal;

    for i := 0 to FGraph.Nodes.Count - 1 do
      AddNodeToSelection(TCustomNode(FGraph.Nodes[i]));

    NotifySelectionChanged;
    Invalidate;
    Key := 0;
    Exit;
  end;

  if (Key = Ord('A')) and (ssCtrl in Shift) then
  begin
    ClearSelectionInternal;

    for i := 0 to FGraph.Nodes.Count - 1 do
      AddNodeToSelection(TCustomNode(FGraph.Nodes[i]));

    for i := 0 to FGraph.Links.Count - 1 do
      AddLinkToSelection(TNodeLink(FGraph.Links[i]));

    NotifySelectionChanged;
    Invalidate;
    Key := 0;
    Exit;
  end;

  if (Key = Ord('A')) and (ssShift in Shift) then
  begin
    ClearSelectionInternal;

    for i := 0 to FGraph.Links.Count - 1 do
      AddLinkToSelection(TNodeLink(FGraph.Links[i]));

    NotifySelectionChanged;
    Invalidate;
    Key := 0;
    Exit;
  end;

  if Key = VK_ESCAPE then
  begin
    ClearSelection;
    Key := 0;
    Exit;
  end;
end;

end.
