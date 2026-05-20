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
  Menus, Clipbrd, fpjson, jsonparser, Forms, StdCtrls, Dialogs,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Controller;

type
  TNodeSelectionChangedEvent = procedure(Sender: TObject) of object;
  TNodeChangedEvent = procedure(Sender: TObject; ANode: TCustomNode) of object;

  { TLazNodeEditor — VIEW + CONTROLLER }
  TLazNodeEditor = class(TCustomControl)
  private
    FGraph: TNodeGraph;
    FController: TNodeEditorController;
    FOnZoomChanged: TEditorZoomChangedEvent;

    FZoom: double;
    FOffsetX, FOffsetY: integer;

    FSelectedNode: TCustomNode;
    FSelectedLink: TNodeLink;           // primary selected link (first one)
    FSelectedLinks: TNodeLinkList;      // support for multiple selected links
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

    procedure GetLinkBezierPoints(ALink: TNodeLink; out P0, P1, P2, P3: TPoint);

    procedure DrawGrid;
    procedure DrawLinks;
    procedure DrawTempLink;
    procedure DrawBoxSelect;

    function WorldToScreen(WX, WY: single): TPoint;
    function ScreenToWorld(SX, SY: integer): TPointF;

    function GetNodeUnderMouse(SX, SY: integer): TCustomNode;
    function IsLinkInsideScreenRect(ALink: TNodeLink; const R: TRect): boolean;
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
    function CreateCompatibleNodeForPin(APin: TNodePin; AX, AY: single): TCustomNode;
    procedure ResetStateAfterGraphReload;
    procedure ClearHoverStates;
    procedure UpdateHoverStates(SX, SY: integer);

    function SnapWorldValue(V: single): single;
    function SnapWorldPoint(const P: TPointF): TPointF;
    procedure OnPopupClose(Sender: TObject);

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

    property OnSelectionChanged: TNodeSelectionChangedEvent
      read FOnSelectionChanged write FOnSelectionChanged;
    property OnNodeChanged: TNodeChangedEvent read FOnNodeChanged write FOnNodeChanged;
    property OnZoomChanged: TEditorZoomChangedEvent
      read FOnZoomChanged write FOnZoomChanged;
  end;

implementation

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
  FOffsetX := 0;
  FOffsetY := 0;

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
  FGraph.ExecuteCommand(TAddNodeCommand.Create(FGraph, ANode));
  Invalidate;
end;

procedure TLazNodeEditor.RemoveNode(ANode: TCustomNode);
var
  BeforeJSON, AfterJSON: string;
begin
  if ANode = nil then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;

  FSelectedNodes.Remove(ANode);
  if FSelectedNode = ANode then
    FSelectedNode := nil;

  FGraph.RemoveNode(ANode);

  AfterJSON := FGraph.CaptureJSONText;
  FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Remove node');

  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.RemoveLink(ALink: TNodeLink);
begin
  if ALink = nil then
    Exit;

  if FSelectedLink = ALink then
    FSelectedLink := nil;

  FGraph.ExecuteCommand(TRemoveLinkCommand.Create(FGraph, ALink));

  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.Clear;
begin
  FGraph.Clear;
  FSelectedNodes.Clear;
  FSelectedNode := nil;
  FSelectedLink := nil;
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
var
  Root: TJSONObject;
  GraphObj: TJSONObject;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('version', 2);
    Root.Add('zoom', FZoom);
    Root.Add('offsetX', FOffsetX);
    Root.Add('offsetY', FOffsetY);

    GraphObj := FGraph.SaveGraphToJSON;
    Root.Add('graph', GraphObj);

    Result := Root.AsJSON;
  finally
    Root.Free;
  end;
end;

procedure TLazNodeEditor.LoadFromJSONText(const S: string);
var
  Data: TJSONData;
  Root: TJSONObject;
  GraphObj: TJSONObject;
  BeforeJSON, AfterJSON: string;
begin
  if Trim(S) = '' then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;

  Data := GetJSON(S);
  try
    Root := TJSONObject(Data);

    FZoom := Root.Get('zoom', 1.0);
    FOffsetX := Root.Get('offsetX', 0);
    FOffsetY := Root.Get('offsetY', 0);

    GraphObj := Root.Objects['graph'];
    if GraphObj <> nil then
      FGraph.LoadGraphFromJSON(GraphObj);

    AfterJSON := FGraph.CaptureJSONText;
    FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Load graph');

    ResetStateAfterGraphReload;
    Invalidate;
  finally
    Data.Free;
  end;
end;

procedure TLazNodeEditor.SaveToFile(const AFileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := SaveToJSONText;
    SL.SaveToFile(AFileName);
  finally
    SL.Free;
  end;
end;

procedure TLazNodeEditor.LoadFromFile(const AFileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    LoadFromJSONText(SL.Text);
  finally
    SL.Free;
  end;
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
    FController.Selection.HasLink) then
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

  // Update primary link
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
  P0, P1, P2, P3: TPoint;
  D0, D1: double;
begin
  Result := False;

  if (ALink = nil) or (ALink.FromPin = nil) or (ALink.ToPin = nil) then
    Exit;

  GetLinkBezierPoints(ALink, P0, P1, P2, P3);

  D0 := Sqrt(Sqr(SX - P0.X) + Sqr(SY - P0.Y));
  D1 := Sqrt(Sqr(SX - P3.X) + Sqr(SY - P3.Y));

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

function TLazNodeEditor.IsLinkInsideScreenRect(ALink: TNodeLink;
  const R: TRect): boolean;
var
  P0, P1, P2, P3: TPoint;
  Prev, Cur: TPointF;
  k: integer;
begin
  Result := False;

  if (ALink = nil) or (ALink.FromPin = nil) or (ALink.ToPin = nil) then
    Exit;

  if (ALink.FromPin.OwnerNode = nil) or (ALink.ToPin.OwnerNode = nil) then
    Exit;

  GetLinkBezierPoints(ALink, P0, P1, P2, P3);

  if PtInRect(R, P0) or PtInRect(R, P3) then
    Exit(True);

  Prev := PointF(P0.X, P0.Y);
  for k := 1 to 32 do
  begin
    Cur := CubicBezierPoint(P0, P1, P2, P3, k / 32);

    if PtInRect(R, Point(Round(Cur.X), Round(Cur.Y))) then
      Exit(True);

    if LineIntersectsRect(Round(Prev.X), Round(Prev.Y),
      Round(Cur.X), Round(Cur.Y), R) then
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
  R: TRect;
  Sorted: TList;
  Radius: integer;
begin
  Result := False;
  Node := nil;
  Pin := nil;

  Sorted := TList.Create;
  try
    BuildSortedNodeList(FGraph, Sorted);

    for i := Sorted.Count - 1 downto 0 do
    begin
      N := TCustomNode(Sorted[i]);

      if N.VisualKind = nvComment then
        Continue;

      if N.VisualKind = nvReroute then
        Radius := Max(7, Round(9 * FZoom))
      else
        Radius := Max(10, Round(10 * FZoom));

      for j := 0 to N.InputCount - 1 do
      begin
        P := N.GetInput(j);

        if P.Hidden then
          Continue;

        R := N.GetPinScreenRect(P, FZoom, FOffsetX, FOffsetY, Radius);

        if PtInRect(R, Point(SX, SY)) then
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

        R := N.GetPinScreenRect(P, FZoom, FOffsetX, FOffsetY, Radius);

        if PtInRect(R, Point(SX, SY)) then
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

procedure TLazNodeEditor.GetLinkBezierPoints(ALink: TNodeLink;
  out P0, P1, P2, P3: TPoint);
var
  S0, S1: TPoint;
  DX, DY: single;
  Dist: single;
  D: integer;
begin
  S0 := TCustomNode(ALink.FromPin.OwnerNode).GetPinScreenPosition(
    ALink.FromPin, FZoom, FOffsetX, FOffsetY);
  S1 := TCustomNode(ALink.ToPin.OwnerNode).GetPinScreenPosition(ALink.ToPin,
    FZoom, FOffsetX, FOffsetY);
  P0 := S0;
  P3 := S1;

  DX := P3.X - P0.X;
  DY := P3.Y - P0.Y;

  Dist := Hypot(DX, DY);

  D := Round(Dist * 0.35);
  D := EnsureRange(D, 30, 150);

  P1 := P0;
  P1.X := P1.X + D;

  P2 := P3;
  P2.X := P2.X - D;
end;

function TLazNodeEditor.GetLinkUnderMouse(SX, SY: integer; out Link: TNodeLink): boolean;
var
  i, k: integer;
  L: TNodeLink;
  P0, P1, P2, P3: TPoint;
  M, Prev, Cur: TPointF;
  Dist: double;
begin
  Result := False;
  Link := nil;

  M := PointF(SX, SY);

  for i := FGraph.Links.Count - 1 downto 0 do
  begin
    L := TNodeLink(FGraph.Links[i]);

    if (L = nil) or (L.FromPin = nil) or (L.ToPin = nil) then
      Continue;

    if (L.FromPin.OwnerNode = nil) or (L.ToPin.OwnerNode = nil) then
      Continue;

    GetLinkBezierPoints(L, P0, P1, P2, P3);

    Prev := PointF(P0.X, P0.Y);

    for k := 1 to 32 do
    begin
      Cur := CubicBezierPoint(P0, P1, P2, P3, k / 32);
      Dist := DistancePointToSegment(M, Prev, Cur);

      if Dist <= Max(8, Round(8 * FZoom)) then
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
  x, y, Step: integer;
begin
  Canvas.Pen.Color := $00E0E0E0;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
  Step := Round(FGridSize * FZoom);
  if Step < 8 then Step := 8;
  x := FOffsetX mod Step;
  if x < 0 then x := x + Step;
  while x < ClientWidth do
  begin
    Canvas.MoveTo(x, 0);
    Canvas.LineTo(x, ClientHeight);
    Inc(x, Step);
  end;
  y := FOffsetY mod Step;
  if y < 0 then y := y + Step;
  while y < ClientHeight do
  begin
    Canvas.MoveTo(0, y);
    Canvas.LineTo(ClientWidth, y);
    Inc(y, Step);
  end;
end;

procedure TLazNodeEditor.DrawLinks;
var
  i: integer;
  Link: TNodeLink;
  P0, P1, P2, P3: TPoint;
begin
  for i := 0 to FGraph.Links.Count - 1 do
  begin
    Link := TNodeLink(FGraph.Links[i]);
    if (Link.FromPin = nil) or (Link.ToPin = nil) then Continue;
    GetLinkBezierPoints(Link, P0, P1, P2, P3);

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
  FixedPos: TPoint;
begin
  if FTempFromPin = nil then
    Exit;

  Canvas.Pen.Color := clYellow;
  Canvas.Pen.Width := 3;
  Canvas.Pen.Style := psDot;

  if FReconnectingLink and (FReconnectFixedPin <> nil) then
  begin
    FixedPos := TCustomNode(FReconnectFixedPin.OwnerNode).GetPinScreenPosition(
      FReconnectFixedPin, FZoom, FOffsetX, FOffsetY);

    if FReconnectMovingFromSide then
    begin
      P0 := FTempMousePos;
      P3 := FixedPos;
    end
    else
    begin
      P0 := FixedPos;
      P3 := FTempMousePos;
    end;

    P1 := P0;
    P2 := P3;

    P1.X := P1.X + Round(60 * FZoom);
    P2.X := P2.X - Round(60 * FZoom);
  end
  else
  begin
    P0 := TCustomNode(FTempFromPin.OwnerNode).GetPinScreenPosition(
      FTempFromPin, FZoom, FOffsetX, FOffsetY);

    if FTempFromPin.Direction = pdOutput then
    begin
      P1 := P0;
      P1.X := P1.X + Round(60 * FZoom);
      P2 := FTempMousePos;
      P2.X := P2.X - Round(60 * FZoom);
    end
    else
    begin
      P1 := P0;
      P1.X := P1.X - Round(60 * FZoom);
      P2 := FTempMousePos;
      P2.X := P2.X + Round(60 * FZoom);
    end;

    P3 := FTempMousePos;
  end;

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
  Txt: String;
  TX,TY: integer;
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

    Txt := Format('X: %.1f   Y: %.1f   (Δ %.1f, %.1f)',
      [CX, CY, DX, DY]);

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
  BeforeJSON, AfterJSON: string;
begin
  if FSelectedLink = nil then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;

  N := FGraph.CreateRerouteForLink(FSelectedLink, SnapWorldValue(FContextWorldPos.X),
    SnapWorldValue(FContextWorldPos.Y));

  FSelectedLink := nil;

  AfterJSON := FGraph.CaptureJSONText;
  FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Insert reroute');

  if N <> nil then
    SelectNodeInternal(N, False);

  NotifySelectionChanged;
  Invalidate;
end;

procedure TLazNodeEditor.OnContextAddComment(Sender: TObject);
var
  N: TCustomNode;
begin
  N := FGraph.Registry.CreateNode('comment', SnapWorldValue(FContextWorldPos.X),
    SnapWorldValue(FContextWorldPos.Y));
  AddNode(N);
  SelectNodeInternal(N, False);
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

function TLazNodeEditor.CreateCompatibleNodeForPin(APin: TNodePin;
  AX, AY: single): TCustomNode;
var
  i, j: integer;
  It: TNodeRegistryItem;
  TestNode: TCustomNode;
  TestPin: TNodePin;
  NeedDir: TPinDirection;
begin
  Result := nil;

  if APin = nil then Exit;

  if APin.Direction = pdOutput then
    NeedDir := pdInput
  else
    NeedDir := pdOutput;

  for i := 0 to FGraph.Registry.Count - 1 do
  begin
    It := FGraph.Registry.Item(i);

    if SameText(It.NodeType, 'comment') then
      Continue;

    TestNode := FGraph.Registry.CreateNode(It.NodeType, AX, AY);
    try
      if NeedDir = pdInput then
      begin
        for j := 0 to TestNode.InputCount - 1 do
        begin
          TestPin := TestNode.GetInput(j);
          if FGraph.CanConnect(APin, TestPin) then
          begin
            Result := FGraph.Registry.CreateNode(It.NodeType, AX, AY);
            Exit;
          end;
        end;
      end
      else
      begin
        for j := 0 to TestNode.OutputCount - 1 do
        begin
          TestPin := TestNode.GetOutput(j);
          if FGraph.CanConnect(APin, TestPin) then
          begin
            Result := FGraph.Registry.CreateNode(It.NodeType, AX, AY);
            Exit;
          end;
        end;
      end;
    finally
      TestNode.Free;
    end;
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
var
  Issues: TList;
  i: integer;
  Issue: TGraphValidationIssue;
  Prefix: string;
begin
  Issues := TList.Create;
  try
    Result := FGraph.ValidateGraphIssues(Issues);

    if AStrings <> nil then
    begin
      AStrings.Clear;

      if Issues.Count = 0 then
        AStrings.Add('Graph is valid.');

      for i := 0 to Issues.Count - 1 do
      begin
        Issue := TGraphValidationIssue(Issues[i]);

        if Issue.Kind = gviError then
          Prefix := 'Error: '
        else
          Prefix := 'Warning: ';

        AStrings.Add(Prefix + Issue.MessageText);
      end;
    end;

    for i := 0 to Issues.Count - 1 do
      TObject(Issues[i]).Free;
  finally
    Issues.Free;
  end;
end;

function TLazNodeEditor.AddInputPinToNode(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
begin
  Result := nil;

  if (FGraph = nil) or (ANode = nil) then
    Exit;

  Result := FGraph.AddDynamicInputPin(ANode, AName, ADataType, AKind);

  if Assigned(FOnNodeChanged) then
    FOnNodeChanged(Self, ANode);

  Invalidate;
end;

function TLazNodeEditor.AddOutputPinToNode(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
begin
  Result := nil;

  if (FGraph = nil) or (ANode = nil) then
    Exit;

  Result := FGraph.AddDynamicOutputPin(ANode, AName, ADataType, AKind);

  if Assigned(FOnNodeChanged) then
    FOnNodeChanged(Self, ANode);

  Invalidate;
end;

function TLazNodeEditor.RemovePinFromNode(APin: TNodePin): boolean;
var
  N: TCustomNode;
begin
  Result := False;

  if (FGraph = nil) or (APin = nil) then
    Exit;

  N := TCustomNode(APin.OwnerNode);

  Result := FGraph.RemoveDynamicPin(APin);

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
        // Normal click on link → select only this link (clear nodes and other links)
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

      // Remember initial position of the primary node for delta display
      if FSelectedNode <> nil then
        FDragStartWorldPos := PointF(FSelectedNode.X, FSelectedNode.Y)
      else if FSelectedNodes.Count > 0 then
        FDragStartWorldPos := PointF(TCustomNode(FSelectedNodes[0]).X, TCustomNode(FSelectedNodes[0]).Y);

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
    if FSnapToGrid and not (ssAlt in Shift) then
    begin
      Dx := (X - FDragAnchorX) / FZoom;
      Dy := (Y - FDragAnchorY) / FZoom;

      for i := 0 to FDragCommandNodes.Count - 1 do
      begin
        N := TCustomNode(FDragCommandNodes[i]);
        BaseX := FDragOldPositions[i].X;
        BaseY := FDragOldPositions[i].Y;

        N.X := SnapWorldValue(BaseX + Dx);
        N.Y := SnapWorldValue(BaseY + Dy);

        if Assigned(FOnNodeChanged) then
          FOnNodeChanged(Self, N);
      end;
    end
    else
    begin
      Dx := (X - FDragStartX) / FZoom;
      Dy := (Y - FDragStartY) / FZoom;

      for i := 0 to FSelectedNodes.Count - 1 do
      begin
        N := TCustomNode(FSelectedNodes[i]);
        N.X := N.X + Dx;
        N.Y := N.Y + Dy;

        if Assigned(FOnNodeChanged) then
          FOnNodeChanged(Self, N);
      end;

      FDragStartX := X;
      FDragStartY := Y;
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
    Invalidate;
  end;
end;

procedure TLazNodeEditor.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  TargetNode: TCustomNode;
  TargetPin: TNodePin;
  L: TNodeLink;
  R: TRect;
  i: integer;
  N: TCustomNode;
  NewPositions: array of TPointF;
  Moved: boolean;
  K: integer;
  DN: TCustomNode;
  BeforeJSON, AfterJSON: string;
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
          BeforeJSON := FGraph.CaptureJSONText;

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

          AfterJSON := FGraph.CaptureJSONText;
          FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Reconnect link');
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
        TargetNode := CreateCompatibleNodeForPin(FTempFromPin,
          SnapWorldValue(ScreenToWorld(X, Y).X),
          SnapWorldValue(ScreenToWorld(X, Y).Y));

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

    if FBoxSelecting then
    begin
      R := NormalizeRect(Rect(FBoxStart.X, FBoxStart.Y, FBoxCurrent.X, FBoxCurrent.Y));

      if not (ssCtrl in Shift) and not (ssShift in Shift) then
        ClearSelectionInternal;

      if ssShift in Shift then
      begin
        // Shift + box: only nodes
        for i := 0 to FGraph.Nodes.Count - 1 do
        begin
          N := TCustomNode(FGraph.Nodes[i]);
          if RectIntersects(R, N.GetScreenBounds(FZoom, FOffsetX, FOffsetY)) then
            AddNodeToSelection(N);
        end;
      end
      else if ssCtrl in Shift then
      begin
        // Ctrl + box: only links
        for i := 0 to FGraph.Links.Count - 1 do
        begin
          L := TNodeLink(FGraph.Links[i]);
          if IsLinkInsideScreenRect(L, R) then
            AddLinkToSelection(L);
        end;
      end
      else
      begin
        for i := 0 to FGraph.Nodes.Count - 1 do
        begin
          N := TCustomNode(FGraph.Nodes[i]);
          if RectIntersects(R, N.GetScreenBounds(FZoom, FOffsetX, FOffsetY)) then
            AddNodeToSelection(N);
        end;

        for i := 0 to FGraph.Links.Count - 1 do
        begin
          L := TNodeLink(FGraph.Links[i]);
          if IsLinkInsideScreenRect(L, R) then
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
    // Ctrl + Shift + A -> only nodes
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
    // Ctrl + A -> nodes + links
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
    // Shift + A -> only links
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
