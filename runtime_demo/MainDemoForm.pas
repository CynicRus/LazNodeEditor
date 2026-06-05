unit MainDemoForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls, Types,
  StdCtrls, Menus, ActnList, math, LCLIntf, LCLType, LazNodeEditor.Editor,
  LazNodeEditor.Nodes, LazNodeEditor.Types, LazNodeEditor.LinkRouter, LazNodeEditor.Graph, LazNodeEditor.Inspector,
  LazNodeEditor.Controller, LazNodeEditor.Runtime, LazNodeEditor.Debugger,
  LazNodeEditor.ControlFlowNodes, LazNodeEditor.EngineeringNodes;

type
  { TMainDemoFrm }
  TIconDrawProc = procedure(C: TCanvas; cx, cy: integer) of object;

  TMainDemoFrm = class(TForm)
    ActionList1: TActionList;
    ImageList1: TImageList;
    actRun: TAction;
    actPause: TAction;
    actStop: TAction;
    actStepInto: TAction;
    actStepOver: TAction;
    actContinue: TAction;
    actToggleBreakpoint: TAction;
    actClearBreakpoints: TAction;
    actAddComment: TAction;
    actSearchNode: TAction;
    actFrameSelected: TAction;
    actAlignLeft: TAction;
    actAlignCenterH: TAction;
    actDistributeH: TAction;
    actAutoLayout: TAction;
    actUndo: TAction;
    actRedo: TAction;
    actDelete: TAction;
    actSave: TAction;
    actLoad: TAction;
    actNew: TAction;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    pnlTop: TPanel;
    pnlRight: TPanel;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    ToolButton16: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    procedure AddToolbarIcon(AColor: TColor; ADrawProc: TIconDrawProc);
    procedure DrawIconNew(C: TCanvas; cx, cy: integer);
    procedure DrawIconSave(C: TCanvas; cx, cy: integer);
    procedure DrawIconLoad(C: TCanvas; cx, cy: integer);
    procedure DrawIconUndo(C: TCanvas; cx, cy: integer);
    procedure DrawIconRedo(C: TCanvas; cx, cy: integer);
    procedure DrawIconRun(C: TCanvas; cx, cy: integer);
    procedure DrawIconPause(C: TCanvas; cx, cy: integer);
    procedure DrawIconStop(C: TCanvas; cx, cy: integer);
    procedure DrawIconStepInto(C: TCanvas; cx, cy: integer);
    procedure DrawIconStepOver(C: TCanvas; cx, cy: integer);
    procedure DrawIconContinue(C: TCanvas; cx, cy: integer);
    procedure DrawIconToggleBreakpoint(C: TCanvas; cx, cy: integer);
    procedure DrawIconClearBreakpoints(C: TCanvas; cx, cy: integer);
    procedure DrawIconAddComment(C: TCanvas; cx, cy: integer);
    procedure DrawIconSearch(C: TCanvas; cx, cy: integer);
    procedure DrawIconFrameSelected(C: TCanvas; cx, cy: integer);
    procedure DrawIconAlignLeft(C: TCanvas; cx, cy: integer);
    procedure DrawIconAlignCenterH(C: TCanvas; cx, cy: integer);
    procedure DrawIconDistributeH(C: TCanvas; cx, cy: integer);
    procedure DrawIconAutoLayout(C: TCanvas; cx, cy: integer);
    procedure DrawIconDelete(C: TCanvas; cx, cy: integer);
    procedure actAddCommentExecute(Sender: TObject);
    procedure actAlignCenterHExecute(Sender: TObject);
    procedure actAlignLeftExecute(Sender: TObject);
    procedure actAutoLayoutExecute(Sender: TObject);
    procedure actClearBreakpointsExecute(Sender: TObject);
    procedure actContinueExecute(Sender: TObject);
    procedure actDeleteExecute(Sender: TObject);
    procedure actDistributeHExecute(Sender: TObject);
    procedure actFrameSelectedExecute(Sender: TObject);
    procedure actLoadExecute(Sender: TObject);
    procedure actNewExecute(Sender: TObject);
    procedure actPauseExecute(Sender: TObject);
    procedure actRedoExecute(Sender: TObject);
    procedure actRunExecute(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
    procedure actSearchNodeExecute(Sender: TObject);
    procedure actStepIntoExecute(Sender: TObject);
    procedure actStepOverExecute(Sender: TObject);
    procedure actStopExecute(Sender: TObject);
    procedure actToggleBreakpointExecute(Sender: TObject);
    procedure actUndoExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FEditor: TLazNodeEditor;
    FInspector: TLazNodeInspector;
    FController: TNodeEditorController;
    SplitterLog: TSplitter;
    FMemoLog: TMemo;
    FSampleGraphLoaded: boolean;

    procedure NodeEditorDrawGrid(Sender: TObject; ACanvas: TCanvas;
      const VisibleWorldRect: TRectF; Zoom, OffsetX, OffsetY: double;
      var AHandled: boolean);

    procedure EditorDrawPin(Sender: TObject; ACanvas: TCanvas;
      APin: TNodePin; const ACenter: TPoint; ARadius: integer;
      ASelected, AHovered, AHighlighted: boolean; var AHandled: boolean);

    procedure EditorDrawLink(Sender: TObject; ACanvas: TCanvas;
      ALink: TNodeLink; const APath: TLinkPath; ASelected, AHovered: boolean;
      Zoom, OffsetX, OffsetY: double; var AHandled: boolean);

    procedure EditorDrawSnapGuides(Sender: TObject; ACanvas: TCanvas;
      GuideSnapXActive, GuideSnapYActive: boolean; GuideSnapX, GuideSnapY: single;
      Zoom, OffsetX, OffsetY: double; var AHandled: boolean);

    function MixColor(C1, C2: TColor; A: byte): TColor;
    procedure RoundRectEx(ACanvas: TCanvas; const R: TRect; Radius: integer);
    procedure DrawSelectionGlow(ACanvas: TCanvas; const R: TRect;
      ARadius: integer; AGlowColor: TColor; AZoom: double);
    function ClampByte(Value: integer): byte;

    procedure CreateEditor;
    procedure CreateInspector;
    procedure CreateToolbarIcons;
    procedure SetupSampleGraph;
    procedure UpdateUIState;
    procedure OnEditorSelectionChanged(Sender: TObject);
    procedure OnZoomChanged(Sender: TObject);
    procedure OnExecutionStateChanged;
    procedure OnEditorExecutionStateChanged(Sender: TObject);
    procedure OnEditorExecutionNodeChanged(Sender: TObject; ANode: TExecutableNode);
    procedure OnEditorExecutionFinished(Sender: TObject; Success: boolean;
      const ErrorMessage: string);
    function GetNodeRuntimeInfo(ANode: TExecutableNode): string;
    procedure Log(const Msg: string);
  public
  end;


var
  MainDemoFrm: TMainDemoFrm;

implementation

{$R *.lfm}

{ TMainDemoFrm }

procedure TMainDemoFrm.FormCreate(Sender: TObject);
begin
  Caption := 'LazNodeEditor - Runtime & Debug Demo';
  Width := 1280;
  Height := 800;

  CreateEditor;
  FEditor.LinkDrawStyle := {ldsBezier}{ldsOrthogonal}ldsStraight;

  FEditor.OnExecutionStateChanged := @OnEditorExecutionStateChanged;
  FEditor.OnExecutionNodeChanged := @OnEditorExecutionNodeChanged;
  FEditor.OnExecutionFinished := @OnEditorExecutionFinished;

  CreateToolbarIcons;

  ActionList1.Images := ImageList1;
  ToolBar1.Images := ImageList1;

  actNew.ImageIndex := 0;
  actSave.ImageIndex := 1;
  actLoad.ImageIndex := 2;
  actUndo.ImageIndex := 3;
  actRedo.ImageIndex := 4;
  actRun.ImageIndex := 5;
  actPause.ImageIndex := 6;
  actStop.ImageIndex := 7;
  actStepInto.ImageIndex := 8;
  actStepOver.ImageIndex := 9;
  actContinue.ImageIndex := 10;
  actToggleBreakpoint.ImageIndex := 11;
  actClearBreakpoints.ImageIndex := 12;
  actAddComment.ImageIndex := 13;
  actSearchNode.ImageIndex := 14;
  actFrameSelected.ImageIndex := 15;
  actAlignLeft.ImageIndex := 16;
  actAlignCenterH.ImageIndex := 17;
  actDistributeH.ImageIndex := 18;
  actAutoLayout.ImageIndex := 19;
  actDelete.ImageIndex := 20;

  // Set nice hints (shown on hover)
  actNew.Hint := 'New graph';
  actSave.Hint := 'Save graph to JSON';
  actLoad.Hint := 'Load graph from JSON';
  actUndo.Hint := 'Undo last action';
  actRedo.Hint := 'Redo last action';
  actRun.Hint := 'Run graph execution (F9)';
  actPause.Hint := 'Pause execution (F10)';
  actStop.Hint := 'Stop execution (Esc)';
  actStepInto.Hint := 'Step Into (F11)';
  actStepOver.Hint := 'Step Over (F12)';
  actContinue.Hint := 'Continue execution (F8)';
  actToggleBreakpoint.Hint := 'Toggle breakpoint on selected node';
  actClearBreakpoints.Hint := 'Clear all breakpoints';
  actAddComment.Hint := 'Add comment node';
  actSearchNode.Hint := 'Search nodes (Ctrl+K)';
  actFrameSelected.Hint := 'Frame selected nodes';
  actAlignLeft.Hint := 'Align selected nodes to left';
  actAlignCenterH.Hint := 'Center selected nodes horizontally';
  actDistributeH.Hint := 'Distribute selected nodes horizontally';
  actAutoLayout.Hint := 'Automatic layout of the graph';
  actDelete.Hint := 'Delete selected nodes/links';

  CreateInspector;

  // Connect inspector
  FInspector.Editor := FEditor;

  // Events
  FEditor.OnSelectionChanged := @OnEditorSelectionChanged;
  FEditor.OnZoomChanged := @OnZoomChanged;
  FEditor.OnDrawGrid := @NodeEditorDrawGrid;
  FEditor.OnDrawPin := @EditorDrawPin;
  FEditor.OnDrawLink := @EditorDrawLink;
  FEditor.OnDrawSnapGuides := @EditorDrawSnapGuides;


  SetupSampleGraph;
  UpdateUIState;

  Log('Demo started. Use toolbar to run/debug the graph.');
end;

procedure TMainDemoFrm.FormDestroy(Sender: TObject);
begin
  if Assigned(FController) then
    FController.Free;
end;

procedure TMainDemoFrm.NodeEditorDrawGrid(Sender: TObject; ACanvas: TCanvas;
  const VisibleWorldRect: TRectF; Zoom, OffsetX, OffsetY: double;
  var AHandled: boolean);
var
  X, Y: single;
  SX, SY: integer;
  Editor: TLazNodeEditor;
  SmallStep, LargeStep: single;
begin
  Editor := TLazNodeEditor(Sender);

  // Фон — тёмно-серый как в UE
  ACanvas.Brush.Color := $00161616;
  ACanvas.FillRect(Editor.ClientRect);

  SmallStep := 16;   // мелкая сетка UE — каждые ~16 ед.
  LargeStep := 128;  // крупная сетка — каждые 8 клеток

  // ── Мелкая сетка ─────────────────────────────────────────────────────────
  ACanvas.Pen.Color := $00222222;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Style := psSolid; ;

  X := Floor(VisibleWorldRect.Left / SmallStep) * SmallStep;
  while X <= VisibleWorldRect.Right do
  begin
    SX := Round(X * Zoom + OffsetX);
    ACanvas.MoveTo(SX, 0);
    ACanvas.LineTo(SX, Editor.ClientHeight);
    X := X + SmallStep;
  end;

  Y := Floor(VisibleWorldRect.Top / SmallStep) * SmallStep;
  while Y <= VisibleWorldRect.Bottom do
  begin
    SY := Round(Y * Zoom + OffsetY);
    ACanvas.MoveTo(0, SY);
    ACanvas.LineTo(Editor.ClientWidth, SY);
    Y := Y + SmallStep;
  end;

  // ── Крупная сетка ─────────────────────────────────────────────────────────
  ACanvas.Pen.Color := $00303030;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Style := psSolid;

  X := Floor(VisibleWorldRect.Left / LargeStep) * LargeStep;
  while X <= VisibleWorldRect.Right do
  begin
    SX := Round(X * Zoom + OffsetX);
    ACanvas.MoveTo(SX, 0);
    ACanvas.LineTo(SX, Editor.ClientHeight);
    X := X + LargeStep;
  end;

  Y := Floor(VisibleWorldRect.Top / LargeStep) * LargeStep;
  while Y <= VisibleWorldRect.Bottom do
  begin
    SY := Round(Y * Zoom + OffsetY);
    ACanvas.MoveTo(0, SY);
    ACanvas.LineTo(Editor.ClientWidth, SY);
    Y := Y + LargeStep;
  end;

  AHandled := True;
end;

// ─────────────────────────────────────────────────────────────────────────────
// Вспомогательная процедура: рисует тонкое "glow"-свечение вокруг прямоугольника
// путём нескольких полупрозрачных колец (имитация blur без GDI+)
// ─────────────────────────────────────────────────────────────────────────────
procedure TMainDemoFrm.DrawSelectionGlow(ACanvas: TCanvas; const R: TRect;
  ARadius: integer; AGlowColor: TColor; AZoom: double);

var
  i, Layers: integer;
  Expand, Alpha: integer;
  BlendR, BlendG, BlendB: byte;
  BaseR, BaseG, BaseB: byte;
  BgR, BgG, BgB: byte;
  GlowR: TRect;
  PenColor: TColor;
  Factor: double;
begin
  Layers := 6;
  BaseR := GetRValue(AGlowColor);
  BaseG := GetGValue(AGlowColor);
  BaseB := GetBValue(AGlowColor);
  // Фон сетки — $161616
  BgR := $16;
  BgG := $16;
  BgB := $16;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;

  for i := Layers downto 1 do
  begin
    Expand := i * 2;
    // Затухание от края к центру (слой 1 = самый дальний = наиболее прозрачный)
    Factor := i / Layers;           // 1/6 .. 6/6
    Alpha := Round(Factor * 60);  // 10..60 — лёгкое свечение

    BlendR := ClampByte(BgR + Round((BaseR - BgR) * Alpha / 255));
    BlendG := ClampByte(BgG + Round((BaseG - BgG) * Alpha / 255));
    BlendB := ClampByte(BgB + Round((BaseB - BgB) * Alpha / 255));
    PenColor := RGB(BlendR, BlendG, BlendB);

    GlowR := Rect(R.Left - Expand, R.Top -
      Expand, R.Right + Expand, R.Bottom + Expand);

    ACanvas.Pen.Color := PenColor;
    RoundRectEx(ACanvas, GlowR, ARadius + Expand div 2);
  end;

  ACanvas.Brush.Style := bsSolid;
end;

function TMainDemoFrm.ClampByte(Value: integer): byte;
begin
  if Value < 0 then
    Result := 0
  else if Value > 255 then
    Result := 255
  else
    Result := byte(Value);
end;


// ─────────────────────────────────────────────────────────────────────────────
procedure TMainDemoFrm.EditorDrawPin(Sender: TObject; ACanvas: TCanvas;
  APin: TNodePin; const ACenter: TPoint; ARadius: integer;
  ASelected, AHovered, AHighlighted: boolean; var AHandled: boolean);
var
  FillColor: TColor;
  OuterColor: TColor;
  R: integer;
  // Ромб-форма для exec-пина (как в UE)
  DiamondPts: array[0..4] of TPoint;
  GlowPts: array[0..4] of TPoint;
  i: integer;
begin
  if APin = nil then Exit;

  if APin.Kind = pkExec then
    FillColor := clWhite
  else if APin.PinType <> nil then
    FillColor := APin.PinType.Color
  else
    FillColor := $00A0A0A0;

  OuterColor := MixColor(FillColor, clWhite, 80);
  R := Max(5, ARadius);

  // ── Exec-пин — стрелка/ромб, как в UE ────────────────────────────────────
  if APin.Kind = pkExec then
  begin
    // Пятиугольная стрелка вправо (упрощённо — пятиугольник)
    DiamondPts[0] := Point(ACenter.X - R, ACenter.Y - R);
    DiamondPts[1] := Point(ACenter.X, ACenter.Y - R);
    DiamondPts[2] := Point(ACenter.X + R, ACenter.Y);
    DiamondPts[3] := Point(ACenter.X, ACenter.Y + R);
    DiamondPts[4] := Point(ACenter.X - R, ACenter.Y + R);

    ACanvas.Pen.Color := OuterColor;
    ACanvas.Pen.Width := 1;

    if AHovered or AHighlighted or ASelected then
    begin
      // Свечение вокруг exec-пина
      ACanvas.Brush.Style := bsClear;
      ACanvas.Pen.Color := RGB(ClampByte(GetRValue(FillColor) + 60),
        ClampByte(GetGValue(FillColor) + 60),
        ClampByte(GetBValue(FillColor) + 60));
      ACanvas.Pen.Width := 2;
      for i := 0 to 4 do
      begin
        GlowPts[i].X := DiamondPts[i].X + IfThen(DiamondPts[i].X > ACenter.X, 3, -3);
        GlowPts[i].Y := DiamondPts[i].Y + IfThen(DiamondPts[i].Y > ACenter.Y, 3, -3);
      end;
      ACanvas.Polygon(GlowPts);
    end;

    if APin.Connected then
      ACanvas.Brush.Color := FillColor  // залитый если подключён
    else
      ACanvas.Brush.Color := $001E1E1E; // пустой если нет }

    ACanvas.Pen.Color := OuterColor;
    ACanvas.Pen.Width := 1;
    ACanvas.Polygon(DiamondPts);
    AHandled := True;
    Exit;
  end;

  // ── Обычный пин — круг ────────────────────────────────────────────────────
  if ASelected then
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Color := $00FFFFFF;
    ACanvas.Pen.Width := 2;
    ACanvas.Ellipse(ACenter.X - R - 4, ACenter.Y - R - 4,
      ACenter.X + R + 4, ACenter.Y + R + 4);
  end
  else if AHovered or AHighlighted then
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Color := MixColor(FillColor, clWhite, 120);
    ACanvas.Pen.Width := 2;
    ACanvas.Ellipse(ACenter.X - R - 3, ACenter.Y - R - 3,
      ACenter.X + R + 3, ACenter.Y + R + 3);
  end;

  // Внешний круг (тёмный ободок)
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := $001E1E1E;
  ACanvas.Pen.Color := OuterColor;
  ACanvas.Pen.Width := 2;
  ACanvas.Ellipse(ACenter.X - R, ACenter.Y - R,
    ACenter.X + R, ACenter.Y + R);

  // Внутренний круг: залит если Connected, пустой (тёмный) если нет
  if APin.Connected then
  begin
    ACanvas.Brush.Color := FillColor;
    ACanvas.Pen.Color := FillColor;
    ACanvas.Ellipse(ACenter.X - (R - 3), ACenter.Y - (R - 3),
      ACenter.X + (R - 3), ACenter.Y + (R - 3));
  end
  else
  begin
    // Незаполненный пин — только тёмный кружок внутри
    ACanvas.Brush.Color := $001E1E1E;
    ACanvas.Pen.Color := OuterColor;
    ACanvas.Pen.Width := 1;
    ACanvas.Ellipse(ACenter.X - (R - 3), ACenter.Y - (R - 3),
      ACenter.X + (R - 3), ACenter.Y + (R - 3));
  end;

  AHandled := True;
end;

// ─────────────────────────────────────────────────────────────────────────────
procedure TMainDemoFrm.EditorDrawLink(Sender: TObject; ACanvas: TCanvas;
  ALink: TNodeLink; const APath: TLinkPath; ASelected, AHovered: boolean;
  Zoom, OffsetX, OffsetY: double; var AHandled: boolean);
var
  BaseColor, CoreColor, ShadowColor, HighlightColor: TColor;
  i: integer;
  ScreenPts: array of TPoint;

  function WorldToScreenPt(const PF: TPointF): TPoint;
  begin
    Result := Point(
      Round(PF.X * Zoom + OffsetX),
      Round(PF.Y * Zoom + OffsetY)
    );
  end;

  procedure DrawPolyline(const Pts: array of TPoint);
  var
    j: integer;
  begin
    if Length(Pts) < 2 then Exit;
    ACanvas.MoveTo(Pts[0].X, Pts[0].Y);
    for j := 1 to High(Pts) do
      ACanvas.LineTo(Pts[j].X, Pts[j].Y);
  end;

  procedure DrawPolylineShifted(const Pts: array of TPoint; DX, DY: integer);
  var
    j: integer;
  begin
    if Length(Pts) < 2 then Exit;
    ACanvas.MoveTo(Pts[0].X + DX, Pts[0].Y + DY);
    for j := 1 to High(Pts) do
      ACanvas.LineTo(Pts[j].X + DX, Pts[j].Y + DY);
  end;

  procedure DrawBezier(const P0, P1, P2, P3: TPoint);
  begin
    DrawCubicBezier(ACanvas, P0, P1, P2, P3);
  end;

  procedure DrawBezierShifted(const P0, P1, P2, P3: TPoint; DX, DY: integer);
  begin
    DrawCubicBezier(ACanvas,
      Point(P0.X + DX, P0.Y + DY),
      Point(P1.X + DX, P1.Y + DY),
      Point(P2.X + DX, P2.Y + DY),
      Point(P3.X + DX, P3.Y + DY));
  end;

var
  P0, P1, P2, P3: TPoint;
begin
  AHandled := True;
  if (ALink = nil) or (Length(APath.Points) = 0) then Exit;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psSolid;

  if (ALink.FromPin <> nil) and (ALink.FromPin.Kind = pkExec) then
  begin
    BaseColor := $00CFCFCF;
    CoreColor := $00F5F5F5;
    ShadowColor := $002A2A2A;
    HighlightColor := clWhite;
  end
  else if (ALink.FromPin <> nil) and (ALink.FromPin.PinType <> nil) then
  begin
    BaseColor := ALink.FromPin.PinType.Color;
    CoreColor := MixColor(BaseColor, clWhite, 70);
    ShadowColor := MixColor(BaseColor, clBlack, 170);
    HighlightColor := MixColor(BaseColor, clWhite, 120);
  end
  else
  begin
    BaseColor := $00D8A040;
    CoreColor := $00F0C060;
    ShadowColor := $00302010;
    HighlightColor := $00FFD080;
  end;

  case APath.Kind of
    lpkBezier:
      begin
        if Length(APath.Points) < 4 then Exit;

        P0 := WorldToScreenPt(APath.Points[0]);
        P1 := WorldToScreenPt(APath.Points[1]);
        P2 := WorldToScreenPt(APath.Points[2]);
        P3 := WorldToScreenPt(APath.Points[3]);

        if ASelected then
        begin
          ACanvas.Pen.Color := MixColor(CoreColor, clWhite, 140);
          ACanvas.Pen.Width := 8;
          DrawBezier(P0, P1, P2, P3);

          ACanvas.Pen.Color := clWhite;
          ACanvas.Pen.Width := 4;
          DrawBezier(P0, P1, P2, P3);
        end
        else if AHovered then
        begin
          ACanvas.Pen.Color := MixColor(CoreColor, clWhite, 70);
          ACanvas.Pen.Width := 7;
          DrawBezier(P0, P1, P2, P3);

          ACanvas.Pen.Color := HighlightColor;
          ACanvas.Pen.Width := 4;
          DrawBezier(P0, P1, P2, P3);
        end
        else
        begin
          // тень
          ACanvas.Pen.Color := ShadowColor;
          ACanvas.Pen.Width := 6;
          DrawBezierShifted(P0, P1, P2, P3, 0, 1);

          // основная линия
          ACanvas.Pen.Color := BaseColor;
          ACanvas.Pen.Width := 4;
          DrawBezier(P0, P1, P2, P3);

          // светлый блик
          ACanvas.Pen.Color := HighlightColor;
          ACanvas.Pen.Width := 1;
          DrawBezierShifted(P0, P1, P2, P3, 0, -1);
        end;
      end;

    lpkPolyline:
      begin
        SetLength(ScreenPts, Length(APath.Points));
        for i := 0 to High(APath.Points) do
          ScreenPts[i] := WorldToScreenPt(APath.Points[i]);

        if ASelected then
        begin
          ACanvas.Pen.Color := MixColor(CoreColor, clWhite, 140);
          ACanvas.Pen.Width := 8;
          DrawPolyline(ScreenPts);

          ACanvas.Pen.Color := clWhite;
          ACanvas.Pen.Width := 4;
          DrawPolyline(ScreenPts);
        end
        else if AHovered then
        begin
          ACanvas.Pen.Color := MixColor(CoreColor, clWhite, 70);
          ACanvas.Pen.Width := 7;
          DrawPolyline(ScreenPts);

          ACanvas.Pen.Color := HighlightColor;
          ACanvas.Pen.Width := 4;
          DrawPolyline(ScreenPts);
        end
        else
        begin
          ACanvas.Pen.Color := ShadowColor;
          ACanvas.Pen.Width := 6;
          DrawPolylineShifted(ScreenPts, 0, 1);

          ACanvas.Pen.Color := BaseColor;
          ACanvas.Pen.Width := 4;
          DrawPolyline(ScreenPts);

          ACanvas.Pen.Color := HighlightColor;
          ACanvas.Pen.Width := 1;
          DrawPolylineShifted(ScreenPts, 0, -1);
        end;
      end;
  end;

  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Brush.Style := bsSolid;
end;

// ─────────────────────────────────────────────────────────────────────────────
procedure TMainDemoFrm.EditorDrawSnapGuides(Sender: TObject; ACanvas: TCanvas;
  GuideSnapXActive, GuideSnapYActive: boolean; GuideSnapX, GuideSnapY: single;
  Zoom, OffsetX, OffsetY: double; var AHandled: boolean);
var
  SX, SY: integer;
  Editor: TLazNodeEditor;
begin
  Editor := TLazNodeEditor(Sender);

  // В UE snap-линии — тонкие голубоватые пунктиры
  ACanvas.Pen.Color := $00FFB040;  // оранжевый акцент, как в UE
  ACanvas.Pen.Style := psDash;
  ACanvas.Pen.Width := 1;

  if GuideSnapXActive then
  begin
    SX := Round(GuideSnapX * Zoom + OffsetX);
    // Тонкое свечение
    ACanvas.Pen.Color := $00604820;
    ACanvas.Pen.Width := 3;
    ACanvas.Pen.Style := psSolid;
    ACanvas.MoveTo(SX, 0);
    ACanvas.LineTo(SX, Editor.ClientHeight);
    // Основная линия
    ACanvas.Pen.Color := $00FFB040;
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Style := psDash;
    ACanvas.MoveTo(SX, 0);
    ACanvas.LineTo(SX, Editor.ClientHeight);
  end;

  if GuideSnapYActive then
  begin
    SY := Round(GuideSnapY * Zoom + OffsetY);
    ACanvas.Pen.Color := $00604820;
    ACanvas.Pen.Width := 3;
    ACanvas.Pen.Style := psSolid;
    ACanvas.MoveTo(0, SY);
    ACanvas.LineTo(Editor.ClientWidth, SY);
    ACanvas.Pen.Color := $00FFB040;
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Style := psDash;
    ACanvas.MoveTo(0, SY);
    ACanvas.LineTo(Editor.ClientWidth, SY);
  end;

  AHandled := True;
end;

function TMainDemoFrm.MixColor(C1, C2: TColor; A: byte): TColor;
var
  r1, g1, b1: byte;
  r2, g2, b2: byte;
  r, g, b: byte;
begin
  C1 := ColorToRGB(C1);
  C2 := ColorToRGB(C2);

  r1 := Red(C1);
  g1 := Green(C1);
  b1 := Blue(C1);
  r2 := Red(C2);
  g2 := Green(C2);
  b2 := Blue(C2);

  r := (r1 * (255 - A) + r2 * A) div 255;
  g := (g1 * (255 - A) + g2 * A) div 255;
  b := (b1 * (255 - A) + b2 * A) div 255;

  Result := RGBToColor(r, g, b);
end;

procedure TMainDemoFrm.RoundRectEx(ACanvas: TCanvas; const R: TRect; Radius: integer);
begin
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, Radius, Radius);
end;


procedure TMainDemoFrm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if Assigned(FEditor) and FEditor.IsExecutionRunning then
  begin
    if MessageDlg('Execution is running. Stop it?', mtConfirmation,
      [mbYes, mbNo], 0) = mrYes then
      FEditor.StopExecution
    else
      CanClose := False;
  end;
end;

procedure TMainDemoFrm.CreateEditor;
begin
  FEditor := TLazNodeEditor.Create(Self);
  FEditor.Parent := Self;
  FEditor.Align := alClient;
  FEditor.AntiAliasing := True;           // Beautiful OpenGL rendering
  FEditor.DebugMode := True;              // Enable debug visualization
  FEditor.DebugViewMode := False;
  FEditor.SnapToGrid := True;
  FEditor.ShowSnapGuides := True;
  FEditor.SnapToNodes := True;
  FEditor.NodeSnapDistance := 12;
  FEditor.MinDetailLevelZoom := 0.25;
  FEditor.MinTitleZoom := 0.45;
  FEditor.MinPinLabelZoom := 0.75;
  FEditor.ScrollBarsVisible := True;
  FEditor.ReadOnly := False;

  // Create controller for easier access
  FController := TNodeEditorController.Create(FEditor.Graph);
  RegisterControlFlowNodes(FEditor.Graph.Registry);
  RegisterEngineeringNodes(FEditor.Graph.Registry);
end;

procedure TMainDemoFrm.CreateInspector;
begin
  // Inspector сверху
  FInspector := TLazNodeInspector.Create(Self);
  FInspector.Parent := pnlRight;
  FInspector.Align := alTop;
  FInspector.Height := 320;
  FInspector.Editor := FEditor;

  // Splitter между инспектором и логом
  SplitterLog := TSplitter.Create(Self);
  SplitterLog.Parent := pnlRight;
  SplitterLog.Align := alTop;
  SplitterLog.Height := 6;
  SplitterLog.ResizeControl := FInspector;

  // Memo Log снизу
  FMemoLog := TMemo.Create(Self);
  FMemoLog.Parent := pnlRight;
  FMemoLog.Align := alClient;
  FMemoLog.ReadOnly := True;
  FMemoLog.ScrollBars := ssVertical;
  FMemoLog.Font.Name := 'Consolas';
  FMemoLog.Font.Size := 9;
  FMemoLog.Color := $1E1E1E;           // тёмный фон
  FMemoLog.Font.Color := $00E0E0E0;    // светлый текст
  FMemoLog.WantReturns := False;
  FMemoLog.WantTabs := False;
end;

procedure TMainDemoFrm.AddToolbarIcon(AColor: TColor; ADrawProc: TIconDrawProc);
var
  Bmp: TBitmap;
  C: TCanvas;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(24, 24);
    C := Bmp.Canvas;

    C.Brush.Style := bsSolid;
    C.Brush.Color := clBtnFace;
    C.FillRect(0, 0, 24, 24);

    C.Pen.Color := AColor;
    C.Brush.Color := AColor;
    C.Pen.Width := 2;

    ADrawProc(C, 12, 12);

    ImageList1.Add(Bmp, nil);
  finally
    Bmp.Free;
  end;
end;

procedure TMainDemoFrm.DrawIconNew(C: TCanvas; cx, cy: integer);
begin
  C.Pen.Color := $4CAF50;
  C.Brush.Style := bsClear;
  C.Rectangle(cx - 7, cy - 8, cx + 7, cy + 8);
  C.MoveTo(cx, cy - 8);
  C.LineTo(cx, cy + 8);
  C.MoveTo(cx - 7, cy);
  C.LineTo(cx + 7, cy);
  C.Brush.Style := bsSolid;
  C.Brush.Color := $4CAF50;
  C.Ellipse(cx + 3, cy - 6, cx + 9, cy);
end;

procedure TMainDemoFrm.DrawIconSave(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Rectangle(cx - 8, cy - 8, cx + 8, cy + 8);
  C.Brush.Style := bsSolid;
  C.Brush.Color := clWhite;
  C.Rectangle(cx - 5, cy - 2, cx + 5, cy + 6);
  C.Brush.Color := $2196F3;
  C.Rectangle(cx - 3, cy - 7, cx + 3, cy - 3);
end;

procedure TMainDemoFrm.DrawIconLoad(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Rectangle(cx - 9, cy - 3, cx + 9, cy + 8);
  C.Rectangle(cx - 6, cy - 8, cx + 2, cy - 3);
  C.MoveTo(cx + 3, cy - 5);
  C.LineTo(cx + 8, cy - 5);
end;

procedure TMainDemoFrm.DrawIconUndo(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Arc(cx - 8, cy - 6, cx + 4, cy + 6, cx + 2, cy - 8, cx - 6, cy + 2);
  C.MoveTo(cx - 3, cy - 1);
  C.LineTo(cx + 6, cy - 1);
  C.MoveTo(cx - 1, cy - 4);
  C.LineTo(cx - 1, cy + 2);
end;

procedure TMainDemoFrm.DrawIconRedo(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Arc(cx - 4, cy - 6, cx + 8, cy + 6, cx - 2, cy - 8, cx + 6, cy + 2);
  C.MoveTo(cx - 6, cy - 1);
  C.LineTo(cx + 3, cy - 1);
  C.MoveTo(cx + 1, cy - 4);
  C.LineTo(cx + 1, cy + 2);
end;

procedure TMainDemoFrm.DrawIconRun(C: TCanvas; cx, cy: integer);
var
  P: array[0..2] of TPoint;
begin
  C.Pen.Color := $4CAF50;
  C.Brush.Color := $4CAF50;
  P[0] := Point(cx - 6, cy - 7);
  P[1] := Point(cx - 6, cy + 7);
  P[2] := Point(cx + 7, cy);
  C.Polygon(P);
end;

procedure TMainDemoFrm.DrawIconPause(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Rectangle(cx - 6, cy - 7, cx - 1, cy + 7);
  C.Rectangle(cx + 1, cy - 7, cx + 6, cy + 7);
end;

procedure TMainDemoFrm.DrawIconStop(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Rectangle(cx - 6, cy - 6, cx + 6, cy + 6);
end;

procedure TMainDemoFrm.DrawIconStepInto(C: TCanvas; cx, cy: integer);
var
  P: array[0..2] of TPoint;
begin
  C.Brush.Style := bsClear;
  C.MoveTo(cx, cy - 7);
  C.LineTo(cx, cy + 3);
  C.MoveTo(cx - 5, cy - 2);
  C.LineTo(cx + 5, cy - 2);
  C.Brush.Style := bsSolid;
  P[0] := Point(cx - 4, cy + 3);
  P[1] := Point(cx + 4, cy + 3);
  P[2] := Point(cx, cy + 8);
  C.Polygon(P);
end;

procedure TMainDemoFrm.DrawIconStepOver(C: TCanvas; cx, cy: integer);
var
  P: array[0..2] of TPoint;
begin
  C.Brush.Style := bsClear;
  C.MoveTo(cx - 7, cy);
  C.LineTo(cx + 3, cy);
  C.MoveTo(cx - 2, cy - 5);
  C.LineTo(cx - 2, cy + 5);
  C.Brush.Style := bsSolid;
  P[0] := Point(cx + 3, cy - 4);
  P[1] := Point(cx + 3, cy + 4);
  P[2] := Point(cx + 8, cy);
  C.Polygon(P);
end;

procedure TMainDemoFrm.DrawIconContinue(C: TCanvas; cx, cy: integer);
var
  P1: array[0..2] of TPoint;
  P2: array[0..2] of TPoint;
begin
  C.Brush.Style := bsSolid;
  P1[0] := Point(cx - 7, cy - 5);
  P1[1] := Point(cx - 7, cy + 5);
  P1[2] := Point(cx - 1, cy);
  C.Polygon(P1);

  P2[0] := Point(cx + 1, cy - 5);
  P2[1] := Point(cx + 1, cy + 5);
  P2[2] := Point(cx + 7, cy);
  C.Polygon(P2);
end;

procedure TMainDemoFrm.DrawIconToggleBreakpoint(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Pen.Width := 3;
  C.Ellipse(cx - 7, cy - 7, cx + 7, cy + 7);
  C.Pen.Width := 2;
  C.MoveTo(cx - 3, cy - 3);
  C.LineTo(cx + 3, cy + 3);
  C.MoveTo(cx + 3, cy - 3);
  C.LineTo(cx - 3, cy + 3);
end;

procedure TMainDemoFrm.DrawIconClearBreakpoints(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Pen.Color := $795548;
  C.MoveTo(cx - 6, cy - 6);
  C.LineTo(cx + 6, cy + 6);
  C.MoveTo(cx + 6, cy - 6);
  C.LineTo(cx - 6, cy + 6);
  C.MoveTo(cx, cy - 8);
  C.LineTo(cx, cy + 8);
end;

procedure TMainDemoFrm.DrawIconAddComment(C: TCanvas; cx, cy: integer);
var
  P: array[0..2] of TPoint;
begin
  C.Brush.Style := bsClear;
  C.RoundRect(cx - 8, cy - 7, cx + 8, cy + 5, 6, 6);
  C.Brush.Style := bsSolid;
  P[0] := Point(cx - 3, cy + 5);
  P[1] := Point(cx + 3, cy + 5);
  P[2] := Point(cx, cy + 9);
  C.Polygon(P);
end;

procedure TMainDemoFrm.DrawIconSearch(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Ellipse(cx - 7, cy - 7, cx + 3, cy + 3);
  C.Pen.Width := 2;
  C.MoveTo(cx + 1, cy + 1);
  C.LineTo(cx + 8, cy + 8);
  C.Pen.Width := 3;
  C.MoveTo(cx + 4, cy + 4);
  C.LineTo(cx + 7, cy + 7);
  C.Pen.Width := 2;
end;

procedure TMainDemoFrm.DrawIconFrameSelected(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Rectangle(cx - 7, cy - 7, cx + 7, cy + 7);
  C.MoveTo(cx - 3, cy - 7);
  C.LineTo(cx - 3, cy + 7);
  C.MoveTo(cx + 3, cy - 7);
  C.LineTo(cx + 3, cy + 7);
end;

procedure TMainDemoFrm.DrawIconAlignLeft(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.MoveTo(cx - 8, cy - 5);
  C.LineTo(cx + 8, cy - 5);
  C.MoveTo(cx - 8, cy);
  C.LineTo(cx + 4, cy);
  C.MoveTo(cx - 8, cy + 5);
  C.LineTo(cx + 8, cy + 5);
  C.MoveTo(cx - 8, cy - 8);
  C.LineTo(cx - 8, cy + 8);
end;

procedure TMainDemoFrm.DrawIconAlignCenterH(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.MoveTo(cx - 8, cy - 5);
  C.LineTo(cx + 8, cy - 5);
  C.MoveTo(cx - 5, cy);
  C.LineTo(cx + 5, cy);
  C.MoveTo(cx - 8, cy + 5);
  C.LineTo(cx + 8, cy + 5);
  C.MoveTo(cx, cy - 8);
  C.LineTo(cx, cy + 8);
end;

procedure TMainDemoFrm.DrawIconDistributeH(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.MoveTo(cx - 8, cy - 6);
  C.LineTo(cx + 8, cy - 6);
  C.MoveTo(cx - 8, cy);
  C.LineTo(cx + 8, cy);
  C.MoveTo(cx - 8, cy + 6);
  C.LineTo(cx + 8, cy + 6);
end;

procedure TMainDemoFrm.DrawIconAutoLayout(C: TCanvas; cx, cy: integer);
begin
  C.Brush.Style := bsClear;
  C.Rectangle(cx - 7, cy - 7, cx - 1, cy - 1);
  C.Rectangle(cx + 1, cy - 7, cx + 7, cy - 1);
  C.Rectangle(cx - 7, cy + 1, cx - 1, cy + 7);
  C.Rectangle(cx + 1, cy + 1, cx + 7, cy + 7);
  C.MoveTo(cx - 1, cy);
  C.LineTo(cx + 1, cy);
  C.MoveTo(cx, cy - 1);
  C.LineTo(cx, cy + 1);
end;

procedure TMainDemoFrm.DrawIconDelete(C: TCanvas; cx, cy: integer);
begin
  C.Pen.Color := $F44336;
  C.Pen.Width := 3;
  C.MoveTo(cx - 5, cy - 5);
  C.LineTo(cx + 5, cy + 5);
  C.MoveTo(cx + 5, cy - 5);
  C.LineTo(cx - 5, cy + 5);
  C.Pen.Width := 2;
end;

procedure TMainDemoFrm.CreateToolbarIcons;
begin
  ImageList1.Clear;
  ImageList1.Width := 24;
  ImageList1.Height := 24;

  AddToolbarIcon($4CAF50, @DrawIconNew);               // 0
  AddToolbarIcon($2196F3, @DrawIconSave);              // 1
  AddToolbarIcon($FF9800, @DrawIconLoad);              // 2
  AddToolbarIcon($607D8B, @DrawIconUndo);              // 3
  AddToolbarIcon($607D8B, @DrawIconRedo);              // 4
  AddToolbarIcon($4CAF50, @DrawIconRun);               // 5
  AddToolbarIcon($FF9800, @DrawIconPause);             // 6
  AddToolbarIcon($F44336, @DrawIconStop);              // 7
  AddToolbarIcon($9C27B0, @DrawIconStepInto);          // 8
  AddToolbarIcon($9C27B0, @DrawIconStepOver);          // 9
  AddToolbarIcon($00BCD4, @DrawIconContinue);          // 10
  AddToolbarIcon($F44336, @DrawIconToggleBreakpoint);  // 11
  AddToolbarIcon($795548, @DrawIconClearBreakpoints);  // 12
  AddToolbarIcon($FFC107, @DrawIconAddComment);        // 13
  AddToolbarIcon($00BCD4, @DrawIconSearch);            // 14
  AddToolbarIcon($607D8B, @DrawIconFrameSelected);     // 15
  AddToolbarIcon($607D8B, @DrawIconAlignLeft);         // 16
  AddToolbarIcon($607D8B, @DrawIconAlignCenterH);      // 17
  AddToolbarIcon($607D8B, @DrawIconDistributeH);       // 18
  AddToolbarIcon($4CAF50, @DrawIconAutoLayout);        // 19
  AddToolbarIcon($F44336, @DrawIconDelete);            // 20
end;

procedure TMainDemoFrm.SetupSampleGraph;
var
  Seq: TSequenceNode;
  NConst, TwoConst: TIntConstNode;
  BoolTrue, BoolFalse: TBoolConstNode;
  PrimesNameConst, EmptyStrConst: TStringConstNode;
  ClearPrimes: TSetVariableNode;
  InitLoop, OuterLoop, InnerLoop, CollectLoop: TForLoopNode;
  SetPrimeInit: TSetPrimeFlagNode;
  ReadPrimeOuter, ReadPrimeCollect: TIsPrimeFlagNode;
  OuterBranch, CollectBranch: TBranchNode;
  MulP2: TMulExecNode;
  SetComposite: TSetPrimeFlagNode;
  CollectPrime: TCollectPrimeNode;
  Comment: TCommentNode;
begin
  if FSampleGraphLoaded then
    Exit;

  FEditor.BeginUpdate;
  try
    FEditor.Clear;

    NConst := TIntConstNode.Create('N = 50', 80, 80);
    NConst.SetupPins;
    NConst.FindValue('value').IntegerValue := 50;
    FEditor.AddNode(NConst);

    TwoConst := TIntConstNode.Create('2', 80, 200);
    TwoConst.SetupPins;
    TwoConst.FindValue('value').IntegerValue := 2;
    FEditor.AddNode(TwoConst);

    BoolTrue := TBoolConstNode.Create('True', 80, 320);
    BoolTrue.SetupPins;
    BoolTrue.FindValue('value').BooleanValue := True;
    FEditor.AddNode(BoolTrue);

    BoolFalse := TBoolConstNode.Create('False', 80, 440);
    BoolFalse.SetupPins;
    BoolFalse.FindValue('value').BooleanValue := False;
    FEditor.AddNode(BoolFalse);

    PrimesNameConst := TStringConstNode.Create('"primes"', 80, 560);
    PrimesNameConst.SetupPins;
    PrimesNameConst.FindValue('value').StringValue := 'primes';
    FEditor.AddNode(PrimesNameConst);

    EmptyStrConst := TStringConstNode.Create('""', 80, 680);
    EmptyStrConst.SetupPins;
    EmptyStrConst.FindValue('value').StringValue := '';
    FEditor.AddNode(EmptyStrConst);

    Seq := TSequenceNode.Create('Start / Main Sequence', 320, 80);
    Seq.SetupPins;
    while Seq.StepCount < 3 do
      Seq.AddStep;
    FEditor.AddNode(Seq);

    ClearPrimes := TSetVariableNode.Create('Set primes = ""', 600, 80);
    ClearPrimes.SetupPins;
    FEditor.AddNode(ClearPrimes);

    InitLoop := TForLoopNode.Create('Init i = 2..N', 600, 260);
    InitLoop.SetupPins;
    FEditor.AddNode(InitLoop);

    SetPrimeInit := TSetPrimeFlagNode.Create('Set prime_i = True', 880, 260);
    SetPrimeInit.SetupPins;
    FEditor.AddNode(SetPrimeInit);

    OuterLoop := TForLoopNode.Create('For p = 2..N', 600, 480);
    OuterLoop.SetupPins;
    FEditor.AddNode(OuterLoop);

    ReadPrimeOuter := TIsPrimeFlagNode.Create('Read prime_p', 880, 480);
    ReadPrimeOuter.SetupPins;
    FEditor.AddNode(ReadPrimeOuter);

    OuterBranch := TBranchNode.Create('If prime_p', 1140, 480);
    OuterBranch.SetupPins;
    FEditor.AddNode(OuterBranch);

    MulP2 := TMulExecNode.Create('p * 2', 1400, 440);
    MulP2.SetupPins;
    FEditor.AddNode(MulP2);

    InnerLoop := TForLoopNode.Create('For m = p*2 .. N step p', 1680, 440);
    InnerLoop.SetupPins;
    FEditor.AddNode(InnerLoop);

    SetComposite := TSetPrimeFlagNode.Create('Set prime_m = False', 1960, 440);
    SetComposite.SetupPins;
    FEditor.AddNode(SetComposite);

    CollectLoop := TForLoopNode.Create('Collect p = 2..N', 600, 760);
    CollectLoop.SetupPins;
    FEditor.AddNode(CollectLoop);

    ReadPrimeCollect := TIsPrimeFlagNode.Create('Read prime_p', 880, 760);
    ReadPrimeCollect.SetupPins;
    FEditor.AddNode(ReadPrimeCollect);

    CollectBranch := TBranchNode.Create('If prime_p', 1140, 760);
    CollectBranch.SetupPins;
    FEditor.AddNode(CollectBranch);

    CollectPrime := TCollectPrimeNode.Create('Collect prime', 1400, 760);
    CollectPrime.SetupPins;
    FEditor.AddNode(CollectPrime);

    Comment := TCommentNode.Create('Runtime-compatible sieve demo', 20, 10);
    Comment.CommentText :=
      'Полный exec-flow:' + sLineBreak +
      '1) очистка строки primes' + sLineBreak +
      '2) инициализация prime_i=True для i=2..N' +
      sLineBreak + '3) внешний цикл по p' + sLineBreak +
      '4) если prime_p=True, то mark multiples' + sLineBreak +
      '5) сбор результата в переменную primes';
    Comment.Width := 520;
    Comment.Height := 170;
    FEditor.AddNode(Comment);

    // DATA
    FEditor.Graph.AddLink(TNodeLink.Create(PrimesNameConst.GetOutput(1),
      ClearPrimes.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(EmptyStrConst.GetOutput(1),
      ClearPrimes.GetInput(2)));

    FEditor.Graph.AddLink(TNodeLink.Create(TwoConst.GetOutput(1), InitLoop.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(NConst.GetOutput(1), InitLoop.GetInput(2)));
    FEditor.Graph.AddLink(TNodeLink.Create(InitLoop.GetOutput(2),
      SetPrimeInit.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(BoolTrue.GetOutput(1),
      SetPrimeInit.GetInput(2)));

    FEditor.Graph.AddLink(TNodeLink.Create(TwoConst.GetOutput(1),
      OuterLoop.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(NConst.GetOutput(1), OuterLoop.GetInput(2)));
    FEditor.Graph.AddLink(TNodeLink.Create(OuterLoop.GetOutput(2),
      ReadPrimeOuter.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(ReadPrimeOuter.GetOutput(1),
      OuterBranch.GetInput(1)));

    FEditor.Graph.AddLink(TNodeLink.Create(OuterLoop.GetOutput(2), MulP2.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(TwoConst.GetOutput(1), MulP2.GetInput(2)));

    FEditor.Graph.AddLink(TNodeLink.Create(MulP2.GetOutput(1), InnerLoop.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(NConst.GetOutput(1), InnerLoop.GetInput(2)));
    FEditor.Graph.AddLink(TNodeLink.Create(OuterLoop.GetOutput(2),
      InnerLoop.GetInput(3)));

    FEditor.Graph.AddLink(TNodeLink.Create(InnerLoop.GetOutput(2),
      SetComposite.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(BoolFalse.GetOutput(1),
      SetComposite.GetInput(2)));

    FEditor.Graph.AddLink(TNodeLink.Create(TwoConst.GetOutput(1),
      CollectLoop.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(NConst.GetOutput(1),
      CollectLoop.GetInput(2)));
    FEditor.Graph.AddLink(TNodeLink.Create(CollectLoop.GetOutput(2),
      ReadPrimeCollect.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(ReadPrimeCollect.GetOutput(1),
      CollectBranch.GetInput(1)));
    FEditor.Graph.AddLink(TNodeLink.Create(CollectLoop.GetOutput(2),
      CollectPrime.GetInput(1)));

    // EXEC
    FEditor.Graph.AddLink(TNodeLink.Create(Seq.GetOutput(0), ClearPrimes.GetInput(0)));
    FEditor.Graph.AddLink(TNodeLink.Create(Seq.GetOutput(1), InitLoop.GetInput(0)));
    FEditor.Graph.AddLink(TNodeLink.Create(Seq.GetOutput(2), OuterLoop.GetInput(0)));

    FEditor.Graph.AddLink(TNodeLink.Create(InitLoop.GetOutput(0),
      SetPrimeInit.GetInput(0)));

    FEditor.Graph.AddLink(TNodeLink.Create(OuterLoop.GetOutput(0),
      ReadPrimeOuter.GetInput(0)));
    FEditor.Graph.AddLink(TNodeLink.Create(ReadPrimeOuter.GetOutput(0),
      OuterBranch.GetInput(0)));
    FEditor.Graph.AddLink(TNodeLink.Create(OuterBranch.GetOutput(0), MulP2.GetInput(0)));
    FEditor.Graph.AddLink(TNodeLink.Create(MulP2.GetOutput(0), InnerLoop.GetInput(0)));
    FEditor.Graph.AddLink(TNodeLink.Create(InnerLoop.GetOutput(0),
      SetComposite.GetInput(0)));

    FEditor.Graph.AddLink(TNodeLink.Create(OuterLoop.GetOutput(1),
      CollectLoop.GetInput(0)));

    FEditor.Graph.AddLink(TNodeLink.Create(CollectLoop.GetOutput(0),
      ReadPrimeCollect.GetInput(0)));
    FEditor.Graph.AddLink(TNodeLink.Create(ReadPrimeCollect.GetOutput(0),
      CollectBranch.GetInput(0)));
    FEditor.Graph.AddLink(TNodeLink.Create(CollectBranch.GetOutput(0),
      CollectPrime.GetInput(0)));

    FEditor.SelectNode(Seq, False);
    FSampleGraphLoaded := True;
  finally
    FEditor.EndUpdate;
  end;

  FEditor.FrameAll;
  Log('Полный exec-граф решета загружен.');
end;

procedure TMainDemoFrm.UpdateUIState;
var
  IsRunning, IsPaused: boolean;
begin
  if not Assigned(FEditor) then Exit;

  IsRunning := FEditor.IsExecutionRunning;
  IsPaused := FEditor.IsExecutionPaused;

  actRun.Enabled := not IsRunning or IsPaused;
  actPause.Enabled := IsRunning and not IsPaused;
  actStop.Enabled := IsRunning or IsPaused;
  actStepInto.Enabled := IsPaused;
  actStepOver.Enabled := IsPaused;
  actContinue.Enabled := IsPaused;

  actToggleBreakpoint.Enabled := FEditor.SelectedNodeCount > 0;
  actClearBreakpoints.Enabled := True;

  StatusBar1.Panels[0].Text := Format('Zoom: %.0f%%', [FEditor.Zoom * 100]);
  StatusBar1.Panels[1].Text :=
    specialize IfThen<string>(IsRunning, 'RUNNING',
    specialize IfThen<string>(IsPaused, 'PAUSED', 'STOPPED'));
end;

procedure TMainDemoFrm.OnEditorSelectionChanged(Sender: TObject);
begin
  UpdateUIState;
  if Assigned(FInspector) then
    FInspector.RefreshFromSelection;
end;

procedure TMainDemoFrm.OnZoomChanged(Sender: TObject);
begin
  UpdateUIState;
end;

procedure TMainDemoFrm.OnExecutionStateChanged;
begin
  UpdateUIState;
end;

procedure TMainDemoFrm.OnEditorExecutionStateChanged(Sender: TObject);
begin
  UpdateUIState;
end;

procedure TMainDemoFrm.OnEditorExecutionNodeChanged(Sender: TObject;
  ANode: TExecutableNode);
begin
  UpdateUIState;
  if ANode <> nil then
    Log('Executing: ' + GetNodeRuntimeInfo(ANode));
end;

procedure TMainDemoFrm.OnEditorExecutionFinished(Sender: TObject;
  Success: boolean; const ErrorMessage: string);
var
  S: string;
begin
  UpdateUIState;

  if Success then
  begin
    S := '';
    if Assigned(FEditor.Debugger) and Assigned(FEditor.ExecutionContext) then
      S := FEditor.ExecutionContext.GetVariableStr('primes', '');

    if S <> '' then
      Log('Execution finished. Collected: ' + S)
    else
      Log('Execution finished successfully');
  end
  else
    Log('Execution failed: ' + ErrorMessage);
end;

function TMainDemoFrm.GetNodeRuntimeInfo(ANode: TExecutableNode): string;
var
  Idx: int64;
  B: boolean;
  S: string;
begin
  Result := ANode.Title;

  if (ANode = nil) or (FEditor = nil) or (FEditor.Debugger = nil) then
    Exit;

  with FEditor.ExecutionContext do
  begin
    if ANode is TForLoopNode then
    begin
      Idx := NodeValueToIntDef(GetVariableValue('last_for_index_' + ANode.Id), -1);
      if Idx >= 0 then
        Result := ANode.Title + ' [i=' + IntToStr(Idx) + ']';
    end
    else if ANode is TIsPrimeFlagNode then
    begin
      Idx := NodeValueToIntDef(GetVariableValue('last_prime_check_index'), -1);
      B := GetVariableBool('last_prime_check_value', False);
      Result := Format('%s [index=%d, isPrime=%s]',
        [ANode.Title, Idx, BoolToStr(B, True)]);
    end
    else if ANode is TSetPrimeFlagNode then
    begin
      Idx := NodeValueToIntDef(GetVariableValue('last_set_prime_index'), -1);
      B := GetVariableBool('last_set_prime_value', False);
      Result := Format('%s [index=%d, value=%s]', [ANode.Title, Idx,
        BoolToStr(B, True)]);
    end
    else if ANode is TCollectPrimeNode then
    begin
      Idx := NodeValueToIntDef(GetVariableValue('last_collected_prime'), -1);
      S := GetVariableStr('primes', '');
      Result := Format('%s [prime=%d, list=%s]', [ANode.Title, Idx, S]);
    end
    else if ANode is TBranchNode then
    begin
      B := GetVariableBool('BranchResult_' + ANode.Id, False);
      Result := Format('%s [condition=%s]', [ANode.Title, BoolToStr(B, True)]);
    end;
  end;
end;

procedure TMainDemoFrm.Log(const Msg: string);
var
  TimeStamp: string;
begin
  TimeStamp := FormatDateTime('hh:nn:ss', Now);
  StatusBar1.Panels[2].Text := Msg;
  // старый вывод в статусбар

  if Assigned(FMemoLog) then
  begin
    FMemoLog.Lines.Add(Format('[%s] %s', [TimeStamp, Msg]));
    // Автоскролл вниз
    FMemoLog.SelStart := Length(FMemoLog.Text);
    FMemoLog.SelLength := 0;
  end;
end;

// ==================== ACTIONS ====================

procedure TMainDemoFrm.actRunExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
  begin
    if FEditor.ExecuteGraph then
    begin
      Log('Graph execution started...');
      FEditor.DebugViewMode := True;
    end
    else
      Log('Failed to start: ' + FEditor.GetLastRuntimeError);
  end;
end;

procedure TMainDemoFrm.actPauseExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
  begin
    FEditor.PauseExecution;
    Log('Execution paused');
  end;
end;

procedure TMainDemoFrm.actStopExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
  begin
    FEditor.StopExecution;
    Log('Execution stopped');
    FEditor.DebugViewMode := False;
    FEditor.CurrentDebugNode := nil;
  end;
end;

procedure TMainDemoFrm.actStepIntoExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.StepIntoExecution;
end;

procedure TMainDemoFrm.actStepOverExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.StepOverExecution;
end;

procedure TMainDemoFrm.actContinueExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.ContinueExecution;
end;

procedure TMainDemoFrm.actToggleBreakpointExecute(Sender: TObject);
var
  Node: TCustomNode;
begin
  if Assigned(FEditor) and (FEditor.SelectedNodeCount > 0) then
  begin
    Node := FEditor.GetSelectedNode(0);
    FEditor.ToggleBreakpoint(Node);
    Log('Breakpoint toggled on node: ' + Node.Title);
  end;
end;

procedure TMainDemoFrm.actClearBreakpointsExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
  begin
    FEditor.ClearAllBreakpoints;
    Log('All breakpoints cleared');
  end;
end;

procedure TMainDemoFrm.actAddCommentExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
  begin
    FEditor.OnContextAddComment(nil); // reuse internal
    Log('Comment node added');
  end;
end;

procedure TMainDemoFrm.actSearchNodeExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
  begin
    FEditor.ShowNodeSearchPopup(
      Mouse.CursorPos.X,
      Mouse.CursorPos.Y,
      FEditor.Viewport.ScreenToWorld(ClientWidth div 2, ClientHeight div 2).X,
      FEditor.Viewport.ScreenToWorld(ClientWidth div 2, ClientHeight div 2).Y
      );
  end;
end;

procedure TMainDemoFrm.actFrameSelectedExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.ExecuteEditorAction(eaFrameSelected);
end;

procedure TMainDemoFrm.actAlignLeftExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.ExecuteEditorAction(eaAlignLeft);
end;

procedure TMainDemoFrm.actAlignCenterHExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.ExecuteEditorAction(eaAlignCenterH);
end;

procedure TMainDemoFrm.actDistributeHExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.ExecuteEditorAction(eaDistributeH);
end;

procedure TMainDemoFrm.actAutoLayoutExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.ExecuteEditorAction(eaAutoLayoutSelected);
end;

procedure TMainDemoFrm.actUndoExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.Undo;
end;

procedure TMainDemoFrm.actRedoExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.Redo;
end;

procedure TMainDemoFrm.actDeleteExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
    FEditor.DeleteSelection;
end;

procedure TMainDemoFrm.actNewExecute(Sender: TObject);
begin
  if Assigned(FEditor) then
  begin
    FEditor.Clear;
    FSampleGraphLoaded := False;
    SetupSampleGraph;
    Log('New graph created');
  end;
end;

procedure TMainDemoFrm.actSaveExecute(Sender: TObject);
var
  Dlg: TSaveDialog;
begin
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := 'Node Graph (*.json)|*.json';
    Dlg.DefaultExt := '.json';
    if Dlg.Execute then
    begin
      FEditor.SaveToFile(Dlg.FileName);
      Log('Graph saved to ' + Dlg.FileName);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TMainDemoFrm.actLoadExecute(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'Node Graph (*.json)|*.json';
    if Dlg.Execute then
    begin
      FEditor.LoadFromFile(Dlg.FileName);
      Log('Graph loaded from ' + Dlg.FileName);
      FSampleGraphLoaded := True;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
