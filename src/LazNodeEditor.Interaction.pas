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
unit LazNodeEditor.Interaction;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, LCLType, Types, Math,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.GraphCommands,
  LazNodeEditor.Controller,
  LazNodeEditor.Viewport,
  LazNodeEditor.InteractionIntf;

type
  { Forward }
  TInteractionStateMachine = class;

  TEditorInteractionState = class
  protected
    FMachine: TInteractionStateMachine;
    function Editor: INodeEditorInteractionHost; inline;
    function Graph: TNodeGraph; inline;
    function Controller: TNodeEditorController; inline;
    function Viewport: TNodeViewport; inline;
  public
    constructor Create(AMachine: TInteractionStateMachine); virtual;
    procedure Enter; virtual;
    procedure Exit; virtual;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); virtual;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); virtual;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); virtual;
    procedure KeyDown(var Key: word; Shift: TShiftState); virtual;
    procedure Cancel; virtual;

    function GetName: string; virtual;
  end;

  TIdleState = class(TEditorInteractionState)
  public
    procedure Enter; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    function GetName: string; override;
  end;

  TNodeDragState = class(TEditorInteractionState)
  private
    FOldPositions: array of TPointF;
    FDraggedComment: TCustomNode;
    FCommentChildren: TCustomNodeList;
    FCommentChildrenOldPositions: array of TPointF;
    FDraggedCommentIndex: integer;
  public
    procedure Enter; override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure Cancel; override;
    function GetName: string; override;
  end;

  TLinkDrawState = class(TEditorInteractionState)
  public
    procedure Enter; override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure Cancel; override;
    function GetName: string; override;
  end;

  TReconnectLinkState = class(TEditorInteractionState)
  public
    procedure Enter; override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure Cancel; override;
    function GetName: string; override;
  end;

  TBoxSelectState = class(TEditorInteractionState)
  public
    procedure Enter; override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure Cancel; override;
    function GetName: string; override;
  end;

  TPanState = class(TEditorInteractionState)
  public
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure Cancel; override;
    function GetName: string; override;
  end;

  TResizeState = class(TEditorInteractionState)
  public
    procedure Enter; override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    procedure Cancel; override;
    function GetName: string; override;
  end;

  TInteractionStateMachine = class
  private
    FCurrentState: TEditorInteractionState;
    FEditor: INodeEditorInteractionHost;
    FController: TNodeEditorController;
    FViewport: TNodeViewport;
    FGraph: TNodeGraph;

    FLeftButtonDown: boolean;
    FRightButtonDown: boolean;
    FRightMouseMoved: boolean;
    FStartMouseX, FStartMouseY: integer;
    FLastMouseX, FLastMouseY: integer;

    FTempFromPin: TNodePin;
    FTempMousePos: TPoint;
    FTempStartMousePos: TPoint;
    FDraggingLink: boolean;

    FDragCommandNodes: TCustomNodeList;
    FDragOldPositions: array of TPointF;
    FDragStartWorldPos: TPointF;
    FShowDragCoordinates: boolean;

    FBoxStart: TPoint;
    FBoxCurrent: TPoint;
    FBoxStartWorld: TPointF;
    FBoxCurrentWorld: TPointF;

    FResizeNode: TCustomNode;
    FResizeStartMouseX: integer;
    FResizeStartMouseY: integer;
    FResizeStartWidth: integer;
    FResizeStartHeight: integer;
    FResizeOldWidth: integer;
    FResizeOldHeight: integer;

    FReconnectLink: TNodeLink;
    FReconnectFixedPin: TNodePin;
    FReconnectMovingFromSide: boolean;

    function GetIsReconnecting: boolean;
    function GetIsBoxSelecting: boolean;
    function GetIsDraggingNode: boolean;
    function GetIsOperationActive: boolean;

  public
    constructor Create(AHost: INodeEditorInteractionHost;
      AController: TNodeEditorController; AViewport: TNodeViewport; AGraph: TNodeGraph);
    destructor Destroy; override;

    procedure ChangeState(ANewState: TEditorInteractionState);

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure MouseMove(Shift: TShiftState; X, Y: integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure KeyDown(var Key: word; Shift: TShiftState);
    procedure CancelCurrentOperation;

    property Editor: INodeEditorInteractionHost read FEditor;
    property Controller: TNodeEditorController read FController;
    property Viewport: TNodeViewport read FViewport;
    property Graph: TNodeGraph read FGraph;
    property CurrentState: TEditorInteractionState read FCurrentState;

    property LeftButtonDown: boolean read FLeftButtonDown write FLeftButtonDown;
    property RightButtonDown: boolean read FRightButtonDown write FRightButtonDown;
    property RightMouseMoved: boolean read FRightMouseMoved write FRightMouseMoved;
    property StartMouseX: integer read FStartMouseX write FStartMouseX;
    property StartMouseY: integer read FStartMouseY write FStartMouseY;
    property LastMouseX: integer read FLastMouseX write FLastMouseX;
    property LastMouseY: integer read FLastMouseY write FLastMouseY;

    property TempFromPin: TNodePin read FTempFromPin write FTempFromPin;
    property TempMousePos: TPoint read FTempMousePos write FTempMousePos;
    property TempStartMousePos: TPoint read FTempStartMousePos write FTempStartMousePos;
    property DraggingLink: boolean read FDraggingLink write FDraggingLink;

    property DragCommandNodes: TCustomNodeList read FDragCommandNodes;
    property DragOldPositions: TPointfArray read FDragOldPositions;
    property DragStartWorldPos: TPointF read FDragStartWorldPos
      write FDragStartWorldPos;
    property ShowDragCoordinates: boolean read FShowDragCoordinates
      write FShowDragCoordinates;

    property BoxStart: TPoint read FBoxStart write FBoxStart;
    property BoxCurrent: TPoint read FBoxCurrent write FBoxCurrent;
    property BoxStartWorld: TPointF read FBoxStartWorld write FBoxStartWorld;
    property BoxCurrentWorld: TPointF read FBoxCurrentWorld write FBoxCurrentWorld;

    property ResizeNode: TCustomNode read FResizeNode write FResizeNode;
    property ResizeStartMouseX: integer read FResizeStartMouseX
      write FResizeStartMouseX;
    property ResizeStartMouseY: integer read FResizeStartMouseY
      write FResizeStartMouseY;
    property ResizeStartWidth: integer read FResizeStartWidth write FResizeStartWidth;
    property ResizeStartHeight: integer read FResizeStartHeight
      write FResizeStartHeight;
    property ResizeOldWidth: integer read FResizeOldWidth write FResizeOldWidth;
    property ResizeOldHeight: integer read FResizeOldHeight write FResizeOldHeight;

    property ReconnectLink: TNodeLink read FReconnectLink write FReconnectLink;
    property ReconnectFixedPin: TNodePin read FReconnectFixedPin
      write FReconnectFixedPin;
    property ReconnectMovingFromSide: boolean
      read FReconnectMovingFromSide write FReconnectMovingFromSide;

    property IsReconnecting: boolean read GetIsReconnecting;
    property IsBoxSelecting: boolean read GetIsBoxSelecting;
    property IsDraggingNode: boolean read GetIsDraggingNode;
    property IsOperationActive: boolean read GetIsOperationActive;
  end;

implementation

function NormalizeRectF(const R: TRectF): TRectF; inline;
begin
  Result.Left := Min(R.Left, R.Right);
  Result.Top := Min(R.Top, R.Bottom);
  Result.Right := Max(R.Left, R.Right);
  Result.Bottom := Max(R.Top, R.Bottom);
end;

function RectFIntersects(const R1, R2: TRectF): boolean; inline;
begin
  Result := not ((R1.Right < R2.Left) or (R1.Left > R2.Right) or
    (R1.Bottom < R2.Top) or (R1.Top > R2.Bottom));
end;

constructor TEditorInteractionState.Create(AMachine: TInteractionStateMachine);
begin
  inherited Create;
  FMachine := AMachine;
end;

function TEditorInteractionState.Editor: INodeEditorInteractionHost;
begin
  Result := FMachine.Editor;
end;

function TEditorInteractionState.Graph: TNodeGraph;
begin
  Result := FMachine.Graph;
end;

function TEditorInteractionState.Controller: TNodeEditorController;
begin
  Result := FMachine.Controller;
end;

function TEditorInteractionState.Viewport: TNodeViewport;
begin
  Result := FMachine.Viewport;
end;

procedure TEditorInteractionState.Enter;
begin
end;

procedure TEditorInteractionState.Exit;
begin
end;

procedure TEditorInteractionState.Cancel;
begin
end;

procedure TEditorInteractionState.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
end;

procedure TEditorInteractionState.MouseMove(Shift: TShiftState; X, Y: integer);
begin
end;

procedure TEditorInteractionState.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
end;

procedure TEditorInteractionState.KeyDown(var Key: word; Shift: TShiftState);
begin
end;

function TEditorInteractionState.GetName: string;
begin
  Result := ClassName;
end;

procedure TIdleState.Enter;
begin
  inherited;
  Editor.ClearSnapGuides;
end;

procedure TIdleState.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  Node: TCustomNode;
  Pin: TNodePin;
  Link: TNodeLink;
  WorldPos: TPointF;
  i: integer;
begin
  WorldPos := Editor.ScreenToWorld(X, Y);

  if Button = mbLeft then
  begin
    FMachine.LeftButtonDown := True;
    FMachine.StartMouseX := X;
    FMachine.StartMouseY := Y;
    FMachine.LastMouseX := X;
    FMachine.LastMouseY := Y;

    Node := Editor.HitTestResizeHandleAt(X, Y);
    if Node <> nil then
    begin
      if not Controller.Selection.ContainsNode(Node) then
      begin
        Editor.SelectNodeInternal(Node, False);
        Editor.NotifySelectionChanged;
      end;
      FMachine.ResizeNode := Node;
      FMachine.ResizeStartMouseX := X;
      FMachine.ResizeStartMouseY := Y;
      FMachine.ResizeStartWidth := Node.Width;
      FMachine.ResizeStartHeight := Node.Height;
      FMachine.ResizeOldWidth := Node.Width;
      FMachine.ResizeOldHeight := Node.Height;
      FMachine.ChangeState(TResizeState.Create(FMachine));
      System.Exit;
    end;

    Pin := Editor.HitTestPinAt(X, Y, Node);
    if Pin <> nil then
    begin
      if Editor.GetOnPinClickAssigned then
        Editor.DoPinClick(Pin);

      if ssCtrl in Shift then
      begin
        Editor.TogglePinSelection(Pin);
        Editor.NotifySelectionChanged;
        Editor.Invalidate;
        Exit;
      end
      else if ssShift in Shift then
      begin
        Editor.SelectPinInternal(Pin, True);
        Editor.NotifySelectionChanged;
        Editor.Invalidate;
        Exit;
      end;

      if not Editor.CanPinAcceptMoreConnections(Pin) then
      begin
        Editor.ClearPinSelection;
        Editor.SelectPinInternal(Pin, False);
        Editor.NotifySelectionChanged;
        Editor.Invalidate;
        Exit;
      end;

      Editor.ClearPinSelection;
      FMachine.TempFromPin := Pin;
      FMachine.TempMousePos := Point(X, Y);
      FMachine.TempStartMousePos := Point(X, Y);
      FMachine.DraggingLink := False;
      FMachine.ChangeState(TLinkDrawState.Create(FMachine));
      System.Exit;
    end;

    Link := Editor.HitTestLinkAt(X, Y);
    if Link <> nil then
    begin
      if Editor.GetOnLinkClickAssigned then
        Editor.DoLinkClick(Link);

      if (ssCtrl in Shift) or (ssShift in Shift) then
        Editor.ToggleLinkSelection(Link)
      else
      begin
        Editor.ClearSelectionInternal;
        Controller.Selection.SelectLink(Link, False);
      end;

      FMachine.ReconnectLink := Link;
      FMachine.ReconnectMovingFromSide := Editor.IsMouseNearLinkStart(Link, X, Y);
      if FMachine.ReconnectMovingFromSide then
        FMachine.ReconnectFixedPin := Link.ToPin
      else
        FMachine.ReconnectFixedPin := Link.FromPin;

      FMachine.TempFromPin := nil;
      FMachine.TempMousePos := Point(X, Y);
      FMachine.TempStartMousePos := Point(X, Y);
      FMachine.DraggingLink := False;
      Editor.NotifySelectionChanged;
      Editor.RequestRepaint(true);
      System.Exit;
    end;

    Node := Editor.HitTestNodeAt(X, Y);
    if Node <> nil then
    begin
      if (ssCtrl in Shift) or (ssShift in Shift) then
        Editor.ToggleNodeSelection(Node)
      else if not Controller.Selection.ContainsNode(Node) then
        Editor.SelectNodeInternal(Node, False);

      FMachine.ShowDragCoordinates := True;

      if Controller.Selection.NodeCount > 0 then
        FMachine.DragStartWorldPos :=
          PointF(Controller.Selection.GetNode(0).X,
          Controller.Selection.GetNode(0).Y)
      else
        FMachine.DragStartWorldPos := PointF(Node.X, Node.Y);

      FMachine.DragCommandNodes.Clear;
      SetLength(FMachine.FDragOldPositions, Controller.Selection.NodeCount);
      for i := 0 to Controller.Selection.NodeCount - 1 do
      begin
        FMachine.DragCommandNodes.Add(Controller.Selection.GetNode(i));
        FMachine.FDragOldPositions[i] :=
          PointF(Controller.Selection.GetNode(i).X,
          Controller.Selection.GetNode(i).Y);
      end;

      Editor.NotifySelectionChanged;
      FMachine.ChangeState(TNodeDragState.Create(FMachine));
      System.Exit;
    end;

    if not (ssShift in Shift) then
      Editor.ClearSelectionInternal;

    FMachine.BoxStart := Point(X, Y);
    FMachine.BoxCurrent := Point(X, Y);
    FMachine.BoxStartWorld := WorldPos;
    FMachine.BoxCurrentWorld := WorldPos;
    Editor.NotifySelectionChanged;
    FMachine.ChangeState(TBoxSelectState.Create(FMachine));
    System.Exit;
  end
  else if Button = mbRight then
  begin
    FMachine.RightButtonDown := True;
    FMachine.RightMouseMoved := False;
    FMachine.StartMouseX := X;
    FMachine.StartMouseY := Y;
    FMachine.LastMouseX := X;
    FMachine.LastMouseY := Y;
    Editor.SetContextWorldPos(WorldPos);
    FMachine.ChangeState(TPanState.Create(FMachine));
    System.Exit;
  end;
end;

procedure TIdleState.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  if Editor.HitTestResizeHandleAt(X, Y) <> nil then
    Editor.SetCursor(crSizeNWSE)
  else
    Editor.SetCursor(crDefault);

  if Editor.IsHoverPosChanged(X, Y) then
  begin
    Editor.SetLastHoverPos(X, Y);
    Editor.UpdateHoverStates(X, Y);
  end;
end;

function TIdleState.GetName: string;
begin
  Result := 'Idle';
end;

procedure TNodeDragState.Enter;
var
  i: integer;
  N: TCustomNode;
begin
  inherited;
  FDraggedComment := nil;
  FCommentChildren := nil;
  SetLength(FCommentChildrenOldPositions, 0);
  FDraggedCommentIndex := -1;

  if Controller.Selection.NodeCount = 0 then
    Exit;

  SetLength(FOldPositions, Controller.Selection.NodeCount);
  for i := 0 to Controller.Selection.NodeCount - 1 do
  begin
    N := Controller.Selection.GetNode(i);
    FOldPositions[i] := PointF(N.X, N.Y);
  end;

  if (Controller.Selection.NodeCount = 1) then
  begin
    N := Controller.Selection.GetNode(0);
    if (N <> nil) and (N.VisualKind = nvComment) then
    begin
      FDraggedComment := N;
      FDraggedCommentIndex := 0;
    end;
  end;

  if FDraggedComment <> nil then
  begin
    FCommentChildren := TCustomNodeList.Create(False);
    for i := 0 to Graph.Nodes.Count - 1 do
    begin
      N := Graph.Nodes[i];
      if (N <> FDraggedComment) and
         (N.X >= FDraggedComment.X) and
         (N.Y >= FDraggedComment.Y) and
         (N.X + N.Width <= FDraggedComment.X + FDraggedComment.Width) and
         (N.Y + N.Height <= FDraggedComment.Y + FDraggedComment.Height) then
        FCommentChildren.Add(N);
    end;

    SetLength(FCommentChildrenOldPositions, FCommentChildren.Count);
    for i := 0 to FCommentChildren.Count - 1 do
    begin
      N := FCommentChildren[i];
      FCommentChildrenOldPositions[i] := PointF(N.X, N.Y);
    end;
  end;

  Editor.RequestRepaint(True);
end;

procedure TNodeDragState.MouseMove(Shift: TShiftState; X, Y: integer);
var
  i: integer;
  N, OverlayNode: TCustomNode;
  Dx, Dy: single;
  SX, SY: boolean;
begin
  if Controller.Selection.NodeCount = 0 then
    Exit;

  Dx := (X - FMachine.StartMouseX) / Viewport.Zoom;
  Dy := (Y - FMachine.StartMouseY) / Viewport.Zoom;

  if FDraggedComment <> nil then
  begin
    FDraggedComment.X := FOldPositions[FDraggedCommentIndex].X + Dx;
    FDraggedComment.Y := FOldPositions[FDraggedCommentIndex].Y + Dy;

    if FCommentChildren <> nil then
      for i := 0 to FCommentChildren.Count - 1 do
      begin
        N := FCommentChildren[i];
        N.X := FCommentChildrenOldPositions[i].X + Dx;
        N.Y := FCommentChildrenOldPositions[i].Y + Dy;
      end;

    OverlayNode := FDraggedComment;
  end
  else
  begin
    Editor.ApplyNodeSnap(Dx, Dy, SX, SY);

    for i := 0 to Controller.Selection.NodeCount - 1 do
    begin
      N := Controller.Selection.GetNode(i);
      N.X := FOldPositions[i].X + Dx;
      N.Y := FOldPositions[i].Y + Dy;
    end;

    OverlayNode := Controller.Selection.GetNode(0);
  end;

  if (ssAlt in Shift) and (OverlayNode <> nil) then
    Editor.UpdateDragCoordinateOverlay(
      OverlayNode,
      OverlayNode.X, OverlayNode.Y,
      OverlayNode.X - FOldPositions[0].X,
      OverlayNode.Y - FOldPositions[0].Y,
      True
    )
  else
    Editor.UpdateDragCoordinateOverlay(nil, 0, 0, 0, 0, False);

  Editor.RequestRepaint(True);
end;

procedure TNodeDragState.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  NewPositions: array of TPointF;
  i: integer;
  Moved: boolean;
  N: TCustomNode;
begin
  if Button <> mbLeft then Exit;

  SetLength(NewPositions, Controller.Selection.NodeCount);
  Moved := False;

  for i := 0 to Controller.Selection.NodeCount - 1 do
  begin
    N := Controller.Selection.GetNode(i);
    NewPositions[i] := PointF(N.X, N.Y);
    if (Abs(NewPositions[i].X - FOldPositions[i].X) > 0.01) or
      (Abs(NewPositions[i].Y - FOldPositions[i].Y) > 0.01) then
      Moved := True;
  end;

  if Moved then
  begin
    for i := 0 to Controller.Selection.NodeCount - 1 do
    begin
      N := Controller.Selection.GetNode(i);
      N.X := FOldPositions[i].X;
      N.Y := FOldPositions[i].Y;
    end;

    Graph.ExecuteCommand(TMoveNodesCommand.Create(Graph,
      Controller.GetSelectedNodes, FOldPositions, NewPositions));
  end;

  FDraggedComment := nil;
  FreeAndNil(FCommentChildren);
  SetLength(FOldPositions, 0);
  FMachine.ShowDragCoordinates := False;
  Editor.UpdateDragCoordinateOverlay(nil, 0, 0, 0, 0, False);
  FMachine.ChangeState(TIdleState.Create(FMachine));
end;

procedure TNodeDragState.Cancel;
var
  i: integer;
  N: TCustomNode;
begin
  for i := 0 to Controller.Selection.NodeCount - 1 do
  begin
    N := Controller.Selection.GetNode(i);
    N.X := FOldPositions[i].X;
    N.Y := FOldPositions[i].Y;
  end;

  if FCommentChildren <> nil then
    for i := 0 to FCommentChildren.Count - 1 do
    begin
      N := FCommentChildren[i];
      N.X := FCommentChildrenOldPositions[i].X;
      N.Y := FCommentChildrenOldPositions[i].Y;
    end;

  FDraggedComment := nil;
  FreeAndNil(FCommentChildren);
  SetLength(FOldPositions, 0);
  SetLength(FCommentChildrenOldPositions, 0);
  Editor.UpdateDragCoordinateOverlay(nil, 0, 0, 0, 0, False);
  Editor.Invalidate;
end;

function TNodeDragState.GetName: string;
begin
  Result := specialize IfThen<string>(FDraggedComment <> nil, 'CommentDrag', 'NodeDrag');
end;

procedure TLinkDrawState.Enter;
begin
  inherited;
  Editor.Invalidate;
end;

procedure TLinkDrawState.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  FMachine.TempMousePos := Point(X, Y);
  if (Abs(X - FMachine.TempStartMousePos.X) > 4) or
    (Abs(Y - FMachine.TempStartMousePos.Y) > 4) then
    FMachine.DraggingLink := True;
  Editor.UpdateHoverStates(X, Y);
  Editor.RequestRepaint;
end;

procedure TLinkDrawState.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  TargetNode: TCustomNode;
  TargetPin: TNodePin;
  i: integer;
  AllowConnect: boolean;
  DropWorld: TPointF;
begin
  if Button <> mbLeft then Exit;

  DropWorld := Editor.ScreenToWorld(X, Y);
  TargetPin := Editor.HitTestPinAt(X, Y, TargetNode);

  if TargetPin <> nil then
  begin
    if Editor.CanPinAcceptMoreConnections(FMachine.TempFromPin) and
      Editor.CanPinAcceptMoreConnections(TargetPin) and
      Graph.CanConnect(FMachine.TempFromPin, TargetPin) then
    begin
      if FMachine.TempFromPin.Direction = pdOutput then
      begin
        AllowConnect := Editor.BeforeConnectPins(FMachine.TempFromPin, TargetPin);
        if AllowConnect and not Graph.LinkExists(FMachine.TempFromPin, TargetPin) then
        begin
          Graph.ExecuteCommand(TAddLinkCommand.Create(Graph,
            FMachine.TempFromPin, TargetPin));
          Editor.AfterConnectPins(FMachine.TempFromPin, TargetPin);
        end;
      end
      else
      begin
        AllowConnect := Editor.BeforeConnectPins(TargetPin, FMachine.TempFromPin);
        if AllowConnect and not Graph.LinkExists(TargetPin, FMachine.TempFromPin) then
        begin
          Graph.ExecuteCommand(TAddLinkCommand.Create(Graph,
            TargetPin, FMachine.TempFromPin));
          Editor.AfterConnectPins(TargetPin, FMachine.TempFromPin);
        end;
      end;
    end;
  end
  else if FMachine.DraggingLink then
  begin
    TargetNode := nil;
    if Controller <> nil then
      TargetNode := Controller.CreateCompatibleNodeForPin(
        FMachine.TempFromPin, Editor.SnapWorldValue(DropWorld.X),
        Editor.SnapWorldValue(DropWorld.Y));

    if TargetNode <> nil then
    begin
      Graph.ExecuteCommand(TAddNodeCommand.Create(Graph, TargetNode));
      if FMachine.TempFromPin.Direction = pdOutput then
      begin
        for i := 0 to TargetNode.InputCount - 1 do
        begin
          TargetPin := TargetNode.GetInput(i);
          if Editor.CanPinAcceptMoreConnections(FMachine.TempFromPin) and
            Editor.CanPinAcceptMoreConnections(TargetPin) and
            Graph.CanConnect(FMachine.TempFromPin, TargetPin) then
          begin
            AllowConnect := Editor.BeforeConnectPins(FMachine.TempFromPin, TargetPin);
            if AllowConnect then
            begin
              Graph.ExecuteCommand(TAddLinkCommand.Create(Graph,
                FMachine.TempFromPin, TargetPin));
              Editor.AfterConnectPins(FMachine.TempFromPin, TargetPin);
            end;
            Break;
          end;
        end;
      end
      else
      begin
        for i := 0 to TargetNode.OutputCount - 1 do
        begin
          TargetPin := TargetNode.GetOutput(i);
          if Graph.CanConnect(TargetPin, FMachine.TempFromPin) then
          begin
            AllowConnect := Editor.BeforeConnectPins(TargetPin, FMachine.TempFromPin);
            if AllowConnect then
            begin
              Graph.ExecuteCommand(TAddLinkCommand.Create(Graph,
                TargetPin, FMachine.TempFromPin));
              Editor.AfterConnectPins(TargetPin, FMachine.TempFromPin);
            end;
            Break;
          end;
        end;
      end;
      Editor.SelectNodeInternal(TargetNode, False);
      Editor.NotifySelectionChanged;
    end
    else
    begin
      Editor.ShowNodeSearchPopup(
        Mouse.CursorPos.X, Mouse.CursorPos.Y,
        DropWorld.X, DropWorld.Y);
    end;
  end;

  FMachine.TempFromPin := nil;
  FMachine.DraggingLink := False;
  Editor.ClearSnapGuides;
  FMachine.ChangeState(TIdleState.Create(FMachine));
  System.Exit;
end;

procedure TLinkDrawState.Cancel;
begin
  FMachine.TempFromPin := nil;
  FMachine.DraggingLink := False;
  Editor.ClearSnapGuides;
  Editor.Invalidate;
end;

function TLinkDrawState.GetName: string;
begin
  Result := 'LinkDraw';
end;

procedure TReconnectLinkState.Enter;
begin
  inherited;
  Editor.Invalidate;
end;

procedure TReconnectLinkState.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  FMachine.TempMousePos := Point(X, Y);
  if (Abs(X - FMachine.TempStartMousePos.X) > 4) or
    (Abs(Y - FMachine.TempStartMousePos.Y) > 4) then
    FMachine.DraggingLink := True;
  Editor.UpdateHoverStates(X, Y);
  Editor.RequestRepaint;
end;

procedure TReconnectLinkState.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  TargetNode: TCustomNode;
  TargetPin: TNodePin;
  OldPin: TNodePin;
  AllowConnect: boolean;
begin
  if Button <> mbLeft then Exit;

  TargetPin := Editor.HitTestPinAt(X, Y, TargetNode);

  if (TargetPin <> nil) and (FMachine.ReconnectLink <> nil) and
    (FMachine.ReconnectFixedPin <> nil) then
  begin
    // Определяем, какой пин был старым на реконнекте
    if FMachine.ReconnectMovingFromSide then
      OldPin := FMachine.ReconnectLink.FromPin
    else
      OldPin := FMachine.ReconnectLink.ToPin;

    if FMachine.ReconnectMovingFromSide then
    begin
      if Editor.CanPinAcceptMoreConnections(TargetPin) and
        Editor.CanPinAcceptMoreConnections(FMachine.ReconnectFixedPin) and
        Graph.CanConnect(TargetPin, FMachine.ReconnectFixedPin) then
      begin
        AllowConnect := Editor.BeforeConnectPins(TargetPin, FMachine.ReconnectFixedPin);
        if AllowConnect then
        begin
          Graph.ExecuteCommand(TReconnectLinkCommand.Create(
            Graph, FMachine.ReconnectLink, OldPin, TargetPin));

          Editor.UpdatePinsConnectedState;
          Editor.AfterConnectPins(TargetPin, FMachine.ReconnectFixedPin);
        end;
      end;
    end
    else
    begin
      if Editor.CanPinAcceptMoreConnections(FMachine.ReconnectFixedPin) and
        Editor.CanPinAcceptMoreConnections(TargetPin) and
        Graph.CanConnect(FMachine.ReconnectFixedPin, TargetPin) then
      begin
        AllowConnect := Editor.BeforeConnectPins(FMachine.ReconnectFixedPin, TargetPin);
        if AllowConnect then
        begin
          Graph.ExecuteCommand(TReconnectLinkCommand.Create(
            Graph, FMachine.ReconnectLink, OldPin, TargetPin));

          Editor.UpdatePinsConnectedState;
          Editor.AfterConnectPins(FMachine.ReconnectFixedPin, TargetPin);
        end;
      end;
    end;
  end;

  FMachine.TempFromPin := nil;
  FMachine.DraggingLink := False;
  FMachine.ReconnectLink := nil;
  FMachine.ReconnectFixedPin := nil;
  FMachine.ReconnectMovingFromSide := False;
  Editor.ClearSnapGuides;
  FMachine.ChangeState(TIdleState.Create(FMachine));
end;

procedure TReconnectLinkState.Cancel;
begin
  FMachine.TempFromPin := nil;
  FMachine.DraggingLink := False;
  FMachine.ReconnectLink := nil;
  FMachine.ReconnectFixedPin := nil;
  FMachine.ReconnectMovingFromSide := False;
  Editor.ClearSnapGuides;
  Editor.Invalidate;
end;

function TReconnectLinkState.GetName: string;
begin
  Result := 'ReconnectLink';
end;

procedure TBoxSelectState.Enter;
begin
  inherited;
  Editor.RequestRepaint(True);
end;

procedure TBoxSelectState.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  FMachine.BoxCurrent := Point(X, Y);
  FMachine.BoxCurrentWorld := Editor.ScreenToWorld(X, Y);
  Editor.RequestRepaint(True);
end;

procedure TBoxSelectState.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: integer);
var
  R: TRectF;
  i: integer;
  N: TCustomNode;
  L: TNodeLink;
begin
  if Button <> mbLeft then Exit;

  R := NormalizeRectF(RectF(FMachine.BoxStartWorld.X, FMachine.BoxStartWorld.Y,
    FMachine.BoxCurrentWorld.X, FMachine.BoxCurrentWorld.Y));

  if not (ssCtrl in Shift) and not (ssShift in Shift) then
    Editor.ClearSelectionInternal;

  Controller.Selection.BeginUpdate;
  try
    if ssShift in Shift then
    begin
      for i := 0 to Graph.Nodes.Count - 1 do
      begin
        N := TCustomNode(Graph.Nodes[i]);
        if RectFIntersects(R, RectF(N.X, N.Y, N.X + N.Width, N.Y + N.Height)) then
          Controller.Selection.AddNodeToSelection(N);
      end;
    end
    else if ssCtrl in Shift then
    begin
      for i := 0 to Graph.Links.Count - 1 do
      begin
        L := TNodeLink(Graph.Links[i]);
        if Editor.IsLinkInsideWorldRect(L, R) then
          Controller.Selection.AddLinkToSelection(L);
      end;
    end
    else
    begin
      for i := 0 to Graph.Nodes.Count - 1 do
      begin
        N := TCustomNode(Graph.Nodes[i]);
        if RectFIntersects(R, RectF(N.X, N.Y, N.X + N.Width, N.Y + N.Height)) then
          Controller.Selection.AddNodeToSelection(N);
      end;
      for i := 0 to Graph.Links.Count - 1 do
      begin
        L := TNodeLink(Graph.Links[i]);
        if Editor.IsLinkInsideWorldRect(L, R) then
          Controller.Selection.AddLinkToSelection(L);
      end;
    end;
  finally
    Controller.Selection.EndUpdate;
  end;

  Editor.NotifySelectionChanged;
  FMachine.ChangeState(TIdleState.Create(FMachine));
  System.Exit;
end;

procedure TBoxSelectState.Cancel;
begin
  Editor.Invalidate;
end;

function TBoxSelectState.GetName: string;
begin
  Result := 'BoxSelect';
end;

procedure TPanState.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  if not FMachine.RightButtonDown then Exit;

  if not FMachine.RightMouseMoved then
  begin
    if (Abs(X - FMachine.StartMouseX) > 2) or
      (Abs(Y - FMachine.StartMouseY) > 2) then
    begin
      FMachine.RightMouseMoved := True;
      Editor.SetMouseCapture(True);
      Editor.SetCursor(crSizeAll);
    end;
  end;

  if FMachine.RightMouseMoved then
  begin
    Viewport.PanBy(X - FMachine.LastMouseX, Y - FMachine.LastMouseY);
    FMachine.LastMouseX := X;
    FMachine.LastMouseY := Y;
    Editor.RequestRepaint(True);
  end;
end;

procedure TPanState.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  if Button <> mbRight then Exit;

  FMachine.RightButtonDown := False;
  if not FMachine.RightMouseMoved then
  begin
    Editor.SetContextWorldPos(Editor.ScreenToWorld(X, Y));
    Editor.SetMouseCapture(False);
    Editor.SetCursor(crDefault);
    Editor.PopupContextMenu(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end
  else
  begin
    Editor.SetMouseCapture(False);
    Editor.SetCursor(crDefault);
  end;

  FMachine.RightMouseMoved := False;
  FMachine.ChangeState(TIdleState.Create(FMachine));
  System.Exit;
end;

procedure TPanState.Cancel;
begin
  FMachine.RightButtonDown := False;
  FMachine.RightMouseMoved := False;
  Editor.SetMouseCapture(False);
  Editor.SetCursor(crDefault);
  Editor.Invalidate;
end;

function TPanState.GetName: string;
begin
  Result := 'Pan';
end;

procedure TResizeState.Enter;
begin
  inherited;
  Editor.Invalidate;
end;

procedure TResizeState.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  if FMachine.ResizeNode = nil then Exit;
  FMachine.ResizeNode.Width :=
    Max(40, FMachine.ResizeStartWidth + Round(
    (X - FMachine.ResizeStartMouseX) / Viewport.Zoom));
  FMachine.ResizeNode.Height :=
    Max(28, FMachine.ResizeStartHeight + Round(
    (Y - FMachine.ResizeStartMouseY) / Viewport.Zoom));
  if FMachine.ResizeNode.VisualKind = nvReroute then
  begin
    FMachine.ResizeNode.Width := Max(12, FMachine.ResizeNode.Width);
    FMachine.ResizeNode.Height := FMachine.ResizeNode.Width;
  end;
  Editor.RequestRepaint(True);
end;

procedure TResizeState.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  NewW, NewH: integer;
begin
  if Button <> mbLeft then Exit;
  if (FMachine.ResizeNode <> nil) and
    ((FMachine.ResizeNode.Width <> FMachine.ResizeOldWidth) or
    (FMachine.ResizeNode.Height <> FMachine.ResizeOldHeight)) then
  begin
    NewW := FMachine.ResizeNode.Width;
    NewH := FMachine.ResizeNode.Height;
    FMachine.ResizeNode.Width := FMachine.ResizeOldWidth;
    FMachine.ResizeNode.Height := FMachine.ResizeOldHeight;
    Graph.ExecuteCommand(TResizeNodeCommand.Create(Graph, FMachine.ResizeNode,
      FMachine.ResizeOldWidth, FMachine.ResizeOldHeight, NewW, NewH));
    Editor.DoNodeChanged(FMachine.ResizeNode);
  end;
  FMachine.ResizeNode := nil;
  Editor.ClearSnapGuides;
  FMachine.ChangeState(TIdleState.Create(FMachine));
  System.Exit;
end;

procedure TResizeState.Cancel;
begin
  if FMachine.ResizeNode <> nil then
  begin
    FMachine.ResizeNode.Width := FMachine.ResizeOldWidth;
    FMachine.ResizeNode.Height := FMachine.ResizeOldHeight;
  end;
  FMachine.ResizeNode := nil;
  Editor.ClearSnapGuides;
  Editor.Invalidate;
end;

function TResizeState.GetName: string;
begin
  Result := 'Resize';
end;

constructor TInteractionStateMachine.Create(AHost: INodeEditorInteractionHost;
  AController: TNodeEditorController; AViewport: TNodeViewport; AGraph: TNodeGraph);
begin
  inherited Create;
  FEditor := AHost;
  FController := AController;
  FViewport := AViewport;
  FGraph := AGraph;
  FDragCommandNodes := TCustomNodeList.Create(False);
  FCurrentState := TIdleState.Create(Self);
  FCurrentState.Enter;
end;

destructor TInteractionStateMachine.Destroy;
begin
  if FCurrentState <> nil then
  begin
    FCurrentState.Exit;
    FCurrentState.Free;
  end;
  FDragCommandNodes.Free;
  inherited Destroy;
end;

procedure TInteractionStateMachine.ChangeState(ANewState: TEditorInteractionState);
begin
  if FCurrentState <> nil then
  begin
    FCurrentState.Exit;
    FCurrentState.Free;
  end;
  FCurrentState := ANewState;
  if FCurrentState <> nil then FCurrentState.Enter;
end;

procedure TInteractionStateMachine.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if FCurrentState <> nil then FCurrentState.MouseDown(Button, Shift, X, Y);
end;

procedure TInteractionStateMachine.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  if FCurrentState <> nil then FCurrentState.MouseMove(Shift, X, Y);
end;

procedure TInteractionStateMachine.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if FCurrentState <> nil then FCurrentState.MouseUp(Button, Shift, X, Y);
end;

procedure TInteractionStateMachine.KeyDown(var Key: word; Shift: TShiftState);
begin
  if FCurrentState <> nil then FCurrentState.KeyDown(Key, Shift);
  if Key = VK_ESCAPE then
  begin
    CancelCurrentOperation;
    Key := 0;
  end;
end;

procedure TInteractionStateMachine.CancelCurrentOperation;
begin
  if FCurrentState <> nil then FCurrentState.Cancel;
  ChangeState(TIdleState.Create(Self));
end;

function TInteractionStateMachine.GetIsReconnecting: boolean;
begin
  Result := FCurrentState is TReconnectLinkState;
end;

function TInteractionStateMachine.GetIsBoxSelecting: boolean;
begin
  Result := FCurrentState is TBoxSelectState;
end;

function TInteractionStateMachine.GetIsDraggingNode: boolean;
begin
  Result := FCurrentState is TNodeDragState;
end;

function TInteractionStateMachine.GetIsOperationActive: boolean;
begin
  Result := not (FCurrentState is TIdleState);
end;

end.
