unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, LCLIntf, LCLType, Types, Math,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Editor,
  LazNodeEditor.Inspector,
  LAzNodeEditor.LinkRouter,
  LazNodeEditor.Controller, LazNodeEditor.GLCanvasProxy;

type

  { TMathExprNode — кастомная нода с exec-пинами и values }
  TMathExprNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 200;
      AHeight: integer = 160); override;
    procedure SetupPins; override;
  end;

  { TMultiplyNode }
  TMultiplyNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure SetupPins; override;
  end;

  { TStringNode — нода со строковым значением }
  TStringNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 100); override;
    procedure SetupPins; override;
  end;

  { TBranchNode — нода с exec-пинами }
  TBranchNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 140); override;
    procedure SetupPins; override;
  end;

  { TForm1 }
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { UI — Layout }
    FTopPanel: TPanel;
    FBottomPanel: TPanel;
    FInspectorHost: TPanel;
    FSplitter: TSplitter;
    FEditor: TLazNodeEditor;
    FInspector: TLazNodeInspector;
    FStatusBar: TStatusBar;

    { Toolbar — File }
    FBtnNew: TButton;
    FBtnSave: TButton;
    FBtnLoad: TButton;

    { Toolbar — Edit }
    FBtnUndo: TButton;
    FBtnRedo: TButton;
    FBtnCopy: TButton;
    FBtnPaste: TButton;
    FBtnDuplicate: TButton;
    FBtnDelete: TButton;

    { Toolbar — View }
    FBtnFit: TButton;
    FBtnFrame: TButton;
    FBtnZoomReset: TButton;

    { Toolbar — Graph }
    FBtnValidate: TButton;
    FBtnClearSel: TButton;

    { Toolbar — Order }
    FBtnBringFront: TButton;
    FBtnSendBack: TButton;

    { Toolbar — Settings }
    FChkSnap: TCheckBox;
    FChkSnapNodes: TCheckBox;
    FEdtGridSize: TEdit;
    FLblGridSize: TLabel;

    { Toolbar — Add Nodes }
    FBtnAddFloat: TButton;
    FBtnAddAdd: TButton;
    FBtnAddMul: TButton;
    FBtnAddMath: TButton;
    FBtnAddString: TButton;
    FBtnAddBranch: TButton;
    FBtnAddReroute: TButton;
    FBtnAddComment: TButton;
    FBtnAddDefault: TButton;

    { Inspector header }
    FLblInspector: TLabel;

    { Dialogs }
    FSaveDialog: TSaveDialog;
    FOpenDialog: TOpenDialog;

    FDidInitialFrame: boolean;

    procedure BuildUI;
    procedure BuildToolbar;
    procedure BuildInspectorPanel;
    procedure BuildEditorArea;
    procedure InitDemoGraph;
    procedure RegisterCustomNodes;

    { Event handlers — toolbar }
    procedure ClickNew(Sender: TObject);
    procedure ClickSave(Sender: TObject);
    procedure ClickLoad(Sender: TObject);
    procedure ClickUndo(Sender: TObject);
    procedure ClickRedo(Sender: TObject);
    procedure ClickCopy(Sender: TObject);
    procedure ClickPaste(Sender: TObject);
    procedure ClickDuplicate(Sender: TObject);
    procedure ClickDelete(Sender: TObject);
    procedure ClickFit(Sender: TObject);
    procedure ClickFrame(Sender: TObject);
    procedure ClickZoomReset(Sender: TObject);
    procedure ClickValidate(Sender: TObject);
    procedure ClickClearSel(Sender: TObject);
    procedure ClickBringFront(Sender: TObject);
    procedure ClickSendBack(Sender: TObject);
    procedure ClickAddFloat(Sender: TObject);
    procedure ClickAddAdd(Sender: TObject);
    procedure ClickAddMul(Sender: TObject);
    procedure ClickAddMath(Sender: TObject);
    procedure ClickAddString(Sender: TObject);
    procedure ClickAddBranch(Sender: TObject);
    procedure ClickAddReroute(Sender: TObject);
    procedure ClickAddComment(Sender: TObject);
    procedure ClickAddDefault(Sender: TObject);
    procedure ChkSnapChange(Sender: TObject);
    procedure ChkSnapNodesChange(Sender: TObject);
    procedure EdtGridSizeChange(Sender: TObject);

    procedure NodeEditorDrawGrid(Sender: TObject; ACanvas: TCanvas;
      const VisibleWorldRect: TRectF; Zoom, OffsetX, OffsetY: double;
      var AHandled: boolean);

    procedure EditorDrawNode(Sender: TObject; ACanvas: TCanvas;
      ANode: TCustomNode; const ARect: TRect; Zoom: double;
      OffsetX, OffsetY: double; var AHandled: boolean);

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


    { Event handlers — editor }
    procedure OnSelectionChanged(Sender: TObject);
    procedure OnNodeChanged(Sender: TObject; ANode: TCustomNode);
    procedure OnEditorZoomChanged(Sender: TObject);

    { Helpers }
    procedure UpdateStatus;
    function CenterWorldPos: TPointF;
    procedure AddNodeAtCenter(const ANodeType: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

// =============================================================================
// Custom node implementations
// =============================================================================

{ TMathExprNode }

constructor TMathExprNode.Create(ATitle: string; AX, AY: single;
  AWidth, AHeight: integer);
var
  V: TNodeValue;
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'math_expr';
  HeaderColor := $004080FF;
  BodyColor := $00F0F8FF;

  V := AddValue('expression', nvkString);
  V.StringValue := 'A + B * C';

  V := AddValue('precision', nvkInteger);
  V.IntegerValue := 6;

  V := AddValue('scale', nvkFloat);
  V.FloatValue := 1.0;

  V := AddValue('enabled', nvkBoolean);
  V.BooleanValue := True;

  V := AddValue('meta', nvkJSON);
  V.JSONValue := '{"mode":"fast"}';
end;

procedure TMathExprNode.SetupPins;
begin
  ClearPins;
  AddInput('▶ Exec In', 'exec', pkExec, 35);
  AddOutput('▶ Exec Out', 'exec', pkExec, 35);

  AddInput('A', 'float', pkData, 75);
  AddInput('B', 'float', pkData, 105);
  AddInput('C', 'float', pkData, 135);
  AddOutput('Result', 'float', pkData, 90);

  GetInput(1).IsRequired := True;
  GetInput(2).IsRequired := True;
  GetInput(1).DefaultValue := '0.0';
  GetInput(1).Tooltip := 'First operand';
end;

{ TMultiplyNode }

constructor TMultiplyNode.Create(ATitle: string; AX, AY: single;
  AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'multiply_node';
  HeaderColor := $0000A0FF;
end;

procedure TMultiplyNode.SetupPins;
begin
  ClearPins;
  AddInput('A', 'float', pkData, 45);
  AddInput('B', 'float', pkData, 75);
  AddOutput('Result', 'float', pkData, 60);
  GetInput(0).IsRequired := True;
  GetInput(1).IsRequired := True;
end;

{ TStringNode }

constructor TStringNode.Create(ATitle: string; AX, AY: single;
  AWidth, AHeight: integer);
var
  V: TNodeValue;
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'string_node';
  HeaderColor := $0000C080;
  V := AddValue('text', nvkString);
  V.StringValue := 'Hello, Node!';
end;

procedure TStringNode.SetupPins;
begin
  ClearPins;
  AddOutput('Text', 'string', pkData, 45);
end;

{ TBranchNode }

constructor TBranchNode.Create(ATitle: string; AX, AY: single;
  AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'branch_node';
  HeaderColor := $00C04000;
end;

procedure TBranchNode.SetupPins;
begin
  ClearPins;
  AddInput('▶ Exec', 'exec', pkExec, 35);
  AddInput('Condition', 'boolean', pkData, 75);
  AddOutput('▶ True', 'exec', pkExec, 55);
  AddOutput('▶ False', 'exec', pkExec, 90);
  GetInput(1).IsRequired := True;
end;

// =============================================================================
// TForm1
// =============================================================================

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'LazNodeEditor — Full Feature Demo';
  Width := 1400;
  Height := 860;
  Position := poScreenCenter;

  FSaveDialog := TSaveDialog.Create(Self);
  FSaveDialog.Filter := 'JSON Graph|*.json|All Files|*.*';
  FSaveDialog.DefaultExt := 'json';

  FOpenDialog := TOpenDialog.Create(Self);
  FOpenDialog.Filter := 'JSON Graph|*.json|All Files|*.*';

  BuildUI;
  RegisterCustomNodes;
  InitDemoGraph;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  LCLIntf.ShowWindow(Form1.Handle, SW_MAXIMIZE);
  if not FDidInitialFrame then
  begin
    FDidInitialFrame := True;
    FEditor.FrameAll;
  end;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  UpdateStatus;
end;

// =============================================================================
// UI Construction
// =============================================================================

procedure TForm1.BuildUI;
begin
  BuildToolbar;
  BuildInspectorPanel;
  BuildEditorArea;

  FStatusBar := TStatusBar.Create(Self);
  FStatusBar.Parent := Self;
  FStatusBar.Align := alBottom;
  FStatusBar.SimplePanel := False;
  FStatusBar.Panels.Add.Width := 200;
  FStatusBar.Panels.Add.Width := 180;
  FStatusBar.Panels.Add.Width := 150;
  FStatusBar.Panels.Add.Width := 260;
  FStatusBar.Panels.Add.Width := 0;
  UpdateStatus;
end;

procedure TForm1.BuildToolbar;
const
  BH = 26;
  BY = 7;
var
  X: integer;

  function Btn(const Cap: string; AWidth: integer): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := FTopPanel;
    Result.SetBounds(X, BY, AWidth, BH);
    Result.Caption := Cap;
    Inc(X, AWidth + 2);
  end;

  procedure Sep;
  var
    L: TLabel;
  begin
    L := TLabel.Create(Self);
    L.Parent := FTopPanel;
    L.Caption := '│';
    L.Left := X;
    L.Top := BY + 4;
    Inc(X, 10);
  end;

begin
  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 42;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Color := $00F0F0F0;

  X := 4;

  { File }
  FBtnNew := Btn('New', 60);
  FBtnNew.OnClick := @ClickNew;
  FBtnSave := Btn('Save JSON', 80);
  FBtnSave.OnClick := @ClickSave;
  FBtnLoad := Btn('Load JSON', 80);
  FBtnLoad.OnClick := @ClickLoad;
  Sep;

  { Edit }
  FBtnUndo := Btn('Undo', 56);
  FBtnUndo.OnClick := @ClickUndo;
  FBtnRedo := Btn('Redo', 56);
  FBtnRedo.OnClick := @ClickRedo;
  FBtnCopy := Btn('Copy', 50);
  FBtnCopy.OnClick := @ClickCopy;
  FBtnPaste := Btn('Paste', 56);
  FBtnPaste.OnClick := @ClickPaste;
  FBtnDuplicate := Btn('Dup', 46);
  FBtnDuplicate.OnClick := @ClickDuplicate;
  FBtnDelete := Btn('Del', 42);
  FBtnDelete.OnClick := @ClickDelete;
  Sep;

  { View }
  FBtnFit := Btn('Fit Sel', 64);
  FBtnFit.OnClick := @ClickFit;
  FBtnFrame := Btn('Frame All', 78);
  FBtnFrame.OnClick := @ClickFrame;
  FBtnZoomReset := Btn('Zoom 1:1', 68);
  FBtnZoomReset.OnClick := @ClickZoomReset;
  Sep;

  { Order }
  FBtnBringFront := Btn('▲ Front', 62);
  FBtnBringFront.OnClick := @ClickBringFront;
  FBtnSendBack := Btn('▼ Back', 62);
  FBtnSendBack.OnClick := @ClickSendBack;
  Sep;

  { Graph }
  FBtnValidate := Btn('Validate', 70);
  FBtnValidate.OnClick := @ClickValidate;
  FBtnClearSel := Btn('Desel', 54);
  FBtnClearSel.OnClick := @ClickClearSel;
  Sep;

  { Snap }
  FChkSnap := TCheckBox.Create(Self);
  FChkSnap.Parent := FTopPanel;
  FChkSnap.SetBounds(X, BY + 2, 78, BH);
  FChkSnap.Caption := 'Snap to grid';
  FChkSnap.Checked := False;
  FChkSnap.OnChange := @ChkSnapChange;
  Inc(X, 82);

  FChkSnapNodes := TCheckBox.Create(Self);
  FChkSnapNodes.Parent := FTopPanel;
  FChkSnapNodes.SetBounds(X, BY + 2, 92, BH);
  FChkSnapNodes.Caption := 'Snap to node';
  FChkSnapNodes.Checked := False;
  FChkSnapNodes.OnChange := @ChkSnapNodesChange;
  Inc(X, 96);

  FLblGridSize := TLabel.Create(Self);
  FLblGridSize.Parent := FTopPanel;
  FLblGridSize.Caption := 'Size:';
  FLblGridSize.Left := X;
  FLblGridSize.Top := BY + 6;
  Inc(X, 34);

  FEdtGridSize := TEdit.Create(Self);
  FEdtGridSize.Parent := FTopPanel;
  FEdtGridSize.SetBounds(X, BY + 2, 36, BH);
  FEdtGridSize.Text := '40';
  FEdtGridSize.OnChange := @EdtGridSizeChange;
  Inc(X, 42);
  Sep;

  { Add Nodes }
  FBtnAddFloat := Btn('+ Float', 62);
  FBtnAddFloat.OnClick := @ClickAddFloat;
  FBtnAddAdd := Btn('+ Add', 50);
  FBtnAddAdd.OnClick := @ClickAddAdd;
  FBtnAddMul := Btn('+ Mul', 50);
  FBtnAddMul.OnClick := @ClickAddMul;
  FBtnAddMath := Btn('+ Math', 58);
  FBtnAddMath.OnClick := @ClickAddMath;
  FBtnAddString := Btn('+ String', 64);
  FBtnAddString.OnClick := @ClickAddString;
  FBtnAddBranch := Btn('+ Branch', 66);
  FBtnAddBranch.OnClick := @ClickAddBranch;
  FBtnAddReroute := Btn('+ Reroute', 70);
  FBtnAddReroute.OnClick := @ClickAddReroute;
  FBtnAddComment := Btn('+ Comment', 76);
  FBtnAddComment.OnClick := @ClickAddComment;
  FBtnAddDefault := Btn('+ Default', 74);
  FBtnAddDefault.OnClick := @ClickAddDefault;
end;

procedure TForm1.BuildInspectorPanel;
begin
  FInspectorHost := TPanel.Create(Self);
  FInspectorHost.Parent := Self;
  FInspectorHost.Align := alLeft;
  FInspectorHost.Width := 290;
  FInspectorHost.BevelOuter := bvNone;
  FInspectorHost.Caption := '';
  FInspectorHost.Color := $00F8F8F8;

  FLblInspector := TLabel.Create(Self);
  FLblInspector.Parent := FInspectorHost;
  FLblInspector.Left := 8;
  FLblInspector.Top := 6;
  FLblInspector.Caption := 'Node Inspector';
  FLblInspector.Font.Style := [fsBold];
  FLblInspector.Font.Size := 10;

  FSplitter := TSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.Align := alLeft;
  FSplitter.Width := 4;

  FInspector := TLazNodeInspector.Create(Self);
  FInspector.Parent := FInspectorHost;
  FInspector.Align := alClient;
  FInspector.BorderSpacing.Top := 28;
  FInspector.BorderSpacing.Left := 4;
  FInspector.BorderSpacing.Right := 4;
end;

procedure TForm1.BuildEditorArea;
begin
  FEditor := TLazNodeEditor.Create(Self);
  FEditor.Parent := Self;
  FEditor.Align := alClient;
  FEditor.Color := $00D8D8D8;
  FEditor.SnapToGrid := False;
  FEditor.SnapToNodes := False;
  FEditor.Style.GridSize := 40;

  FInspector.Editor := FEditor;
  FEditor.AntiAliasing := True;
  FEditor.LinkDrawStyle := ldsOrthogonal;

  FEditor.OnSelectionChanged := @OnSelectionChanged;
  FEditor.OnNodeChanged := @OnNodeChanged;
  FEditor.OnZoomChanged := @OnEditorZoomChanged;

  FEditor.OnDrawGrid := @NodeEditorDrawGrid;
  FEditor.OnDrawNode := @EditorDrawNode;
  FEditor.OnDrawPin := @EditorDrawPin;
  FEditor.OnDrawLink := @EditorDrawLink;
  FEditor.OnDrawSnapGuides := @EditorDrawSnapGuides;

 { FEditor.LinkColor := $00FF9A2E;
  FEditor.LinkHoverColor := $00FFD080;
  FEditor.LinkSelectedColor := clWhite;

  FEditor.PinBorderColor := $00D0D0D0;
  FEditor.PinHoverColor := clWhite;
  FEditor.PinSelectedColor := clWhite; }

  //FEditor.ShowAxes := False;
end;

// =============================================================================
// Register custom node types
// =============================================================================

procedure TForm1.RegisterCustomNodes;
begin
  FEditor.Graph.Registry.RegisterNodeEx(
    'multiply_node', 'Multiply', 'Math',
    'Multiplies two float values.', 'multiply,mul,math,float',
    TMultiplyNode, $0000A0FF);

  FEditor.Graph.Registry.RegisterNodeEx(
    'math_expr', 'Math Expression', 'Math',
    'Evaluates a math expression A+B*C with exec pins and multiple value types.',
    'math,expr,expression,exec',
    TMathExprNode, $004080FF);

  FEditor.Graph.Registry.RegisterNodeEx(
    'string_node', 'String Value', 'Values',
    'Constant string value.', 'string,text,value',
    TStringNode, $0000C080);

  FEditor.Graph.Registry.RegisterNodeEx(
    'branch_node', 'Branch', 'Flow',
    'Conditional exec branch (if/else).', 'branch,if,else,exec,flow',
    TBranchNode, $00C04000);
end;

// =============================================================================
// Demo graph — covers all visual node types + pins + values
// =============================================================================

procedure TForm1.InitDemoGraph;
var
  NFloat1, NFloat2, NFloat3: TCustomNode;
  NAdd, NMul, NMath: TCustomNode;
  NStr: TCustomNode;
  NBranch: TCustomNode;
  NReroute: TCustomNode;
  NComment1, NComment2: TCustomNode;
  NDefault: TCustomNode;
  V: TNodeValue;
begin
  NFloat1 := FEditor.Graph.Registry.CreateNode('float', 40, 120);
  NFloat1.Title := 'Value A';
  TFloatNode(NFloat1).SetupPins;
  V := NFloat1.FindValue('value');
  if V <> nil then V.FloatValue := 3.14;
  FEditor.AddNode(NFloat1);

  NFloat2 := FEditor.Graph.Registry.CreateNode('float', 40, 240);
  NFloat2.Title := 'Value B';
  TFloatNode(NFloat2).SetupPins;
  V := NFloat2.FindValue('value');
  if V <> nil then V.FloatValue := 2.71;
  FEditor.AddNode(NFloat2);

  NFloat3 := FEditor.Graph.Registry.CreateNode('float', 40, 360);
  NFloat3.Title := 'Value C';
  TFloatNode(NFloat3).SetupPins;
  V := NFloat3.FindValue('value');
  if V <> nil then V.FloatValue := 10.0;
  FEditor.AddNode(NFloat3);

  NAdd := FEditor.Graph.Registry.CreateNode('add', 280, 160);
  NAdd.Title := 'A + B';
  FEditor.AddNode(NAdd);

  NMul := FEditor.Graph.Registry.CreateNode('multiply_node', 280, 310);
  NMul.Title := '(A+B) × C';
  FEditor.AddNode(NMul);

  NMath := FEditor.Graph.Registry.CreateNode('math_expr', 520, 180);
  NMath.Title := 'Math Expr';
  FEditor.AddNode(NMath);

  NStr := FEditor.Graph.Registry.CreateNode('string_node', 520, 420);
  NStr.Title := 'Label';
  FEditor.AddNode(NStr);

  NBranch := FEditor.Graph.Registry.CreateNode('branch_node', 760, 160);
  NBranch.Title := 'If Enabled?';
  FEditor.AddNode(NBranch);

  NReroute := FEditor.Graph.Registry.CreateNode('reroute', 430, 370);
  FEditor.AddNode(NReroute);

  NDefault := FEditor.Graph.Registry.CreateNode('default', 760, 360);
  NDefault.Title := 'Default Node';
  FEditor.AddNode(NDefault);

  NComment1 := FEditor.Graph.Registry.CreateNode('comment', 20, 80);
  NComment1.Title := 'Math Block';
  NComment1.Width := 460;
  NComment1.Height := 360;
  NComment1.CommentText := 'Arithmetic: A+B then ×C';
  NComment1.HeaderColor := $0060A060;
  NComment1.BodyColor := $00EEFFEE;
  FEditor.AddNode(NComment1);

  NComment2 := FEditor.Graph.Registry.CreateNode('comment', 500, 120);
  NComment2.Title := 'Flow Block';
  NComment2.Width := 320;
  NComment2.Height := 200;
  NComment2.CommentText := 'Exec pipeline: Expr → Branch';
  NComment2.HeaderColor := $00804000;
  NComment2.BodyColor := $00FFF8E8;
  FEditor.AddNode(NComment2);

  if FEditor.Graph.CanConnect(NFloat1.GetOutput(0), NAdd.GetInput(0)) then
    FEditor.Graph.AddLink(TNodeLink.Create(NFloat1.GetOutput(0), NAdd.GetInput(0)));

  if FEditor.Graph.CanConnect(NFloat2.GetOutput(0), NAdd.GetInput(1)) then
    FEditor.Graph.AddLink(TNodeLink.Create(NFloat2.GetOutput(0), NAdd.GetInput(1)));

  if FEditor.Graph.CanConnect(NAdd.GetOutput(0), NMul.GetInput(0)) then
    FEditor.Graph.AddLink(TNodeLink.Create(NAdd.GetOutput(0), NMul.GetInput(0)));

  if (NReroute.InputCount > 0) and (NReroute.OutputCount > 0) then
  begin
    if FEditor.Graph.CanConnect(NFloat3.GetOutput(0), NReroute.GetInput(0)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NFloat3.GetOutput(0),
        NReroute.GetInput(0)));

    if FEditor.Graph.CanConnect(NReroute.GetOutput(0), NMul.GetInput(1)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NReroute.GetOutput(0), NMul.GetInput(1)));
  end;

  if NMath.InputCount >= 4 then
  begin
    if FEditor.Graph.CanConnect(NMul.GetOutput(0), NMath.GetInput(1)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NMul.GetOutput(0), NMath.GetInput(1)));
    if FEditor.Graph.CanConnect(NFloat1.GetOutput(0), NMath.GetInput(2)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NFloat1.GetOutput(0), NMath.GetInput(2)));
    if FEditor.Graph.CanConnect(NFloat2.GetOutput(0), NMath.GetInput(3)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NFloat2.GetOutput(0), NMath.GetInput(3)));
  end;

  if (NMath.OutputCount >= 1) and (NBranch.InputCount >= 1) then
    if FEditor.Graph.CanConnect(NMath.GetOutput(0), NBranch.GetInput(0)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NMath.GetOutput(0), NBranch.GetInput(0)));

  if (NBranch.OutputCount >= 1) and (NDefault.InputCount >= 1) then
    if FEditor.Graph.CanConnect(NBranch.GetOutput(0), NDefault.GetInput(0)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NBranch.GetOutput(0),
        NDefault.GetInput(0)));

  FEditor.SelectNode(NMath, False);
  FInspector.RefreshFromSelection;

  UpdateStatus;
end;

// =============================================================================
// Toolbar handlers
// =============================================================================

procedure TForm1.ClickNew(Sender: TObject);
begin
  if MessageDlg('New Graph', 'Clear current graph?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    FEditor.Clear;
    FInspector.RefreshFromSelection;
    UpdateStatus;
  end;
end;

procedure TForm1.ClickSave(Sender: TObject);
begin
  if FSaveDialog.Execute then
  begin
    FEditor.SaveToFile(FSaveDialog.FileName);
    FStatusBar.Panels[4].Text := 'Saved: ' + ExtractFileName(FSaveDialog.FileName);
  end;
end;

procedure TForm1.ClickLoad(Sender: TObject);
begin
  if FOpenDialog.Execute then
  begin
    FEditor.LoadFromFile(FOpenDialog.FileName);
    FInspector.RefreshFromSelection;
    FEditor.FrameAll;
    FStatusBar.Panels[4].Text := 'Loaded: ' + ExtractFileName(FOpenDialog.FileName);
    UpdateStatus;
  end;
end;

procedure TForm1.ClickUndo(Sender: TObject);
begin
  FEditor.Undo;
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.ClickRedo(Sender: TObject);
begin
  FEditor.Redo;
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.ClickCopy(Sender: TObject);
begin
  FEditor.CopySelectionToClipboard;
  FStatusBar.Panels[4].Text :=
    'Copied ' + IntToStr(FEditor.SelectedNodeCount) + ' node(s)';
end;

procedure TForm1.ClickPaste(Sender: TObject);
begin
  FEditor.PasteFromClipboard;
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.ClickDuplicate(Sender: TObject);
begin
  FEditor.DuplicateSelection;
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.ClickDelete(Sender: TObject);
begin
  FEditor.DeleteSelection;
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.ClickFit(Sender: TObject);
begin
  if FEditor.SelectedNodeCount > 0 then
    FEditor.FitToSelection
  else
    FEditor.FrameAll;
  UpdateStatus;
end;

procedure TForm1.ClickFrame(Sender: TObject);
begin
  FEditor.FrameAll;
  UpdateStatus;
end;

procedure TForm1.ClickZoomReset(Sender: TObject);
begin
  FEditor.FrameAll;
  FEditor.Zoom := 1.0;
  UpdateStatus;
end;

procedure TForm1.ClickValidate(Sender: TObject);
var
  Msgs: TStringList;
begin
  Msgs := TStringList.Create;
  try
    if FEditor.ValidateGraphToStrings(Msgs) then
      ShowMessage('✔ Graph is valid.' + LineEnding + LineEnding + Msgs.Text)
    else
      MessageDlg('Validation Errors', Msgs.Text, mtError, [mbOK], 0);
  finally
    Msgs.Free;
  end;
end;

procedure TForm1.ClickClearSel(Sender: TObject);
begin
  FEditor.ClearSelection;
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.ClickBringFront(Sender: TObject);
var
  i: integer;
begin
  if FEditor.SelectedNodeCount = 0 then Exit;
  for i := 0 to FEditor.SelectedNodeCount - 1 do
    FEditor.Graph.BringNodeToFront(FEditor.GetSelectedNode(i));
  FEditor.Invalidate;
  FStatusBar.Panels[4].Text := 'Brought to front';
end;

procedure TForm1.ClickSendBack(Sender: TObject);
var
  i: integer;
begin
  if FEditor.SelectedNodeCount = 0 then Exit;
  for i := 0 to FEditor.SelectedNodeCount - 1 do
    FEditor.Graph.SendNodeToBack(FEditor.GetSelectedNode(i));
  FEditor.Invalidate;
  FStatusBar.Panels[4].Text := 'Sent to back';
end;

function TForm1.CenterWorldPos: TPointF;
begin
  Result.X := (FEditor.ClientWidth div 2 - 90);
  Result.Y := (FEditor.ClientHeight div 2 - 60);
  Result.X := Result.X / FEditor.Zoom;
  Result.Y := Result.Y / FEditor.Zoom;
end;

procedure TForm1.AddNodeAtCenter(const ANodeType: string);
var
  N: TCustomNode;
  W: TPointF;
begin
  W := CenterWorldPos;
  N := FEditor.Graph.Registry.CreateNode(ANodeType, W.X + Random(60) -
    30, W.Y + Random(60) - 30);
  FEditor.AddNode(N);
  FEditor.SelectNode(N, False);
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.ClickAddFloat(Sender: TObject);
begin
  AddNodeAtCenter('float');
end;

procedure TForm1.ClickAddAdd(Sender: TObject);
begin
  AddNodeAtCenter('add');
end;

procedure TForm1.ClickAddMul(Sender: TObject);
begin
  AddNodeAtCenter('multiply_node');
end;

procedure TForm1.ClickAddMath(Sender: TObject);
begin
  AddNodeAtCenter('math_expr');
end;

procedure TForm1.ClickAddString(Sender: TObject);
begin
  AddNodeAtCenter('string_node');
end;

procedure TForm1.ClickAddBranch(Sender: TObject);
begin
  AddNodeAtCenter('branch_node');
end;

procedure TForm1.ClickAddReroute(Sender: TObject);
begin
  AddNodeAtCenter('reroute');
end;

procedure TForm1.ClickAddComment(Sender: TObject);
begin
  AddNodeAtCenter('comment');
end;

procedure TForm1.ClickAddDefault(Sender: TObject);
begin
  AddNodeAtCenter('default');
end;

// =============================================================================
// Settings
// =============================================================================

procedure TForm1.ChkSnapChange(Sender: TObject);
begin
  FEditor.SnapToGrid := FChkSnap.Checked;
  UpdateStatus;
end;

procedure TForm1.ChkSnapNodesChange(Sender: TObject);
begin
  FEditor.SnapToNodes := FChkSnapNodes.Checked;
  UpdateStatus;
end;

procedure TForm1.EdtGridSizeChange(Sender: TObject);
var
  V: integer;
begin
  V := StrToIntDef(FEdtGridSize.Text, 40);
  if V > 4 then
  begin
    FEditor.Style.GridSize := V;
    UpdateStatus;
  end;
end;

procedure TForm1.NodeEditorDrawGrid(Sender: TObject; ACanvas: TCanvas;
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
procedure TForm1.DrawSelectionGlow(ACanvas: TCanvas; const R: TRect;
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

function TForm1.ClampByte(Value: integer): byte;
begin
  if Value < 0 then
    Result := 0
  else if Value > 255 then
    Result := 255
  else
    Result := byte(Value);
end;

procedure TForm1.EditorDrawNode(Sender: TObject; ACanvas: TCanvas;
  ANode: TCustomNode; const ARect: TRect; Zoom: double; OffsetX, OffsetY: double;
  var AHandled: boolean);
var
  R, HeaderR: TRect;
  HeaderH: integer;
  BorderColor: TColor;
  BodyColor: TColor;
  HeaderColor: TColor;
  Radius: integer;
  TxtY, CX,CY,HW,HH: integer;
  GlowColor: TColor;
  GlowPts: array[0..3] of TPoint;
  i: integer;
  DiamondPts: array[0..3] of TPoint;

// Рисует прямоугольник со скруглёнными только верхними углами
  procedure DrawRoundedTopRect(ACanvas: TCanvas; const HR: TRect;
    ARadius: integer; AFillColor: TColor; APenColor: TColor);
  const
    Steps = 20;
  var
    i, idx: integer;
    Pts: array of TPoint;
    Angle: double;
    cx, cy: integer;
  begin
    SetLength(Pts, Steps * 2 + 4);
    idx := 0;

    // Верхняя левая дуга (180° → 270°)
    cx := HR.Left + ARadius;
    cy := HR.Top + ARadius;
    for i := 0 to Steps do
    begin
      Angle := Pi + (Pi / 2) * (i / Steps);
      Pts[idx].X := cx + Round(ARadius * Cos(Angle));
      Pts[idx].Y := cy + Round(ARadius * Sin(Angle));
      Inc(idx);
    end;

    // Верхняя правая дуга (270° → 360°)
    cx := HR.Right - ARadius;
    cy := HR.Top + ARadius;
    for i := 0 to Steps do
    begin
      Angle := (3 * Pi / 2) + (Pi / 2) * (i / Steps);
      Pts[idx].X := cx + Round(ARadius * Cos(Angle));
      Pts[idx].Y := cy + Round(ARadius * Sin(Angle));
      Inc(idx);
    end;

    // Нижний правый угол (прямой)
    Pts[idx] := Point(HR.Right, HR.Bottom);
    Inc(idx);
    // Нижний левый угол (прямой)
    Pts[idx] := Point(HR.Left, HR.Bottom);
    Inc(idx);

    ACanvas.Brush.Color := AFillColor;
    ACanvas.Pen.Color := APenColor;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 1;
    ACanvas.Polygon(Pts);
  end;

begin
  if ANode = nil then Exit;

  R := ARect;
  Radius := Max(6, Round(8 * Zoom));   // UE — скругление небольшое
  HeaderH := Max(24, Round(30 * Zoom));

  if ANode.Collapsed and (ANode.VisualKind = nvNormal) then
    R.Bottom := R.Top + HeaderH;

  // ── nvComment ─────────────────────────────────────────────────────────────
  if ANode.VisualKind = nvComment then
  begin
    BorderColor := MixColor(ANode.HeaderColor, clBlack, 60);
    if ANode.Selected then BorderColor := clWhite
    else if ANode.Hovered then BorderColor := MixColor(ANode.HeaderColor, clWhite, 80);

    // Свечение только при выделении
    if ANode.Selected then
      DrawSelectionGlow(ACanvas, R, Radius, clWhite, Zoom);

    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 1;
    ACanvas.Pen.Color := BorderColor;
    // Полупрозрачное тело: смешиваем с фоном
    ACanvas.Brush.Color := MixColor($00161616, ANode.BodyColor, 35);
    RoundRectEx(ACanvas, R, Radius);

    // Шапка комментария
    HeaderR := Rect(R.Left, R.Top, R.Right, R.Top + HeaderH);
    DrawRoundedTopRect(ACanvas, HeaderR, Radius,
      MixColor(ANode.HeaderColor, clBlack, 30), BorderColor);

    // Тонкая цветная полоска-акцент по верхнему краю (как в UE)
    ACanvas.Pen.Color := MixColor(ANode.HeaderColor, clWhite, 60);
    ACanvas.Pen.Width := Max(1, Round(2 * Zoom));
    ACanvas.Brush.Style := bsClear;
    ACanvas.MoveTo(R.Left + Radius, R.Top);
    ACanvas.LineTo(R.Right - Radius, R.Top);

    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := clWhite;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Size := Max(7, Round(9 * Zoom));
    ACanvas.TextOut(R.Left + 10, R.Top + 7, ANode.Title);

    ACanvas.Font.Style := [];
    ACanvas.Font.Color := $00C8C8C8;
    if ANode.CommentText <> '' then
      ACanvas.TextOut(R.Left + 10, HeaderR.Bottom + 8, ANode.CommentText);

    ACanvas.Brush.Style := bsSolid;
    AHandled := True;
    Exit;
  end;

  // ── nvReroute ─────────────────────────────────────────────────────────────
  // В UE reroute — маленький ромб, а не круг; делаем ромб
  if ANode.VisualKind = nvReroute then
  begin
    CX := (R.Left + R.Right) div 2;
    CY := (R.Top + R.Bottom) div 2;
    HW := (R.Right - R.Left) div 2;
    HH := (R.Bottom - R.Top) div 2;

    // Свечение при выделении
    if ANode.Selected then
    begin
      ACanvas.Brush.Style := bsClear;
      ACanvas.Pen.Width := 1;

      for i := 5 downto 1 do
      begin
        GlowPts[0] := Point(CX, CY - HH - i * 2);
        GlowPts[1] := Point(CX + HW + i * 2, CY);
        GlowPts[2] := Point(CX, CY + HH + i * 2);
        GlowPts[3] := Point(CX - HW - i * 2, CY);
        ACanvas.Pen.Color := RGB($16 + i * 18, $16 + i * 18, $16 + i * 18);
        ACanvas.Polygon(GlowPts);
      end;
    end;

    // Тело ромба
    DiamondPts[0] := Point(CX, CY - HH);
    DiamondPts[1] := Point(CX + HW, CY);
    DiamondPts[2] := Point(CX, CY + HH);
    DiamondPts[3] := Point(CX - HW, CY);

    // Граница
    if ANode.Selected and ANode.Hovered then
    begin
      ACanvas.Pen.Color := clWhite;
      ACanvas.Pen.Width := 3;
    end
    else if ANode.Selected then
    begin
      ACanvas.Pen.Color := clWhite;
      ACanvas.Pen.Width := 2;
    end
    else if ANode.Hovered then
    begin
      ACanvas.Pen.Color := $00A0E0FF;
      ACanvas.Pen.Width := 2;
    end
    else
    begin
      ACanvas.Pen.Color := $00909090;
      ACanvas.Pen.Width := 1;
    end;

    ACanvas.Brush.Color := $002A2A2A;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Polygon(DiamondPts);

    // Внутренний центральный пиксель-акцент
    ACanvas.Pen.Color := $00E0E0E0;
    ACanvas.Brush.Color := $00E0E0E0;
    ACanvas.Ellipse(CX - 2, CY - 2, CX + 2, CY + 2);

    AHandled := True;
    Exit;
  end;

  // ── nvNormal ──────────────────────────────────────────────────────────────
  // Цвета в духе UE Blueprint
  BodyColor := $001E1E1E;   // тело — почти чёрное
  HeaderColor := ANode.HeaderColor;

  // Граница: в UE тонкая, чуть светлее шапки
  BorderColor := MixColor(HeaderColor, clBlack, 70);
  if ANode.Selected then
    BorderColor := clWhite
  else if ANode.Hovered then
    BorderColor := MixColor(HeaderColor, clWhite, 100);

  // ── 0. Glow при выделении ─────────────────────────────────────────────────
  if ANode.Selected then
  begin
    GlowColor := IfThen(ANode.Hovered, clWhite,
      MixColor(HeaderColor, clWhite, 80));
    DrawSelectionGlow(ACanvas, R, Radius, GlowColor, Zoom);
  end;

  // ── 1. Тело узла ──────────────────────────────────────────────────────────
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Color := BorderColor;
  ACanvas.Brush.Color := BodyColor;
  RoundRectEx(ACanvas, R, Radius);

  // ── 2. Шапка (скруглена сверху, прямые углы снизу) ───────────────────────
  HeaderR := Rect(R.Left + 1, R.Top + 1, R.Right - 1, R.Top + HeaderH);
  DrawRoundedTopRect(ACanvas, HeaderR, Radius - 1, HeaderColor, HeaderColor);

  // ── 3. Тонкая яркая полоска по верхнему краю шапки (акцент UE) ───────────
  ACanvas.Pen.Color := MixColor(HeaderColor, clWhite, 80);
  ACanvas.Pen.Width := Max(1, Round(2 * Zoom));
  ACanvas.Brush.Style := bsClear;
  ACanvas.MoveTo(R.Left + Radius, R.Top + 1);
  ACanvas.LineTo(R.Right - Radius, R.Top + 1);

  // ── 4. Тёмная разделительная линия между шапкой и телом ──────────────────
  ACanvas.Pen.Color := $00101010;
  ACanvas.Pen.Width := 1;
  ACanvas.MoveTo(R.Left + 1, R.Top + HeaderH);
  ACanvas.LineTo(R.Right - 1, R.Top + HeaderH);

  // ── 5. Финальная обводка поверх всего ────────────────────────────────────
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Color := BorderColor;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Width := IfThen(ANode.Selected or ANode.Hovered, 2, 1);
  RoundRectEx(ACanvas, R, Radius);

  // ── 6. Заголовок ──────────────────────────────────────────────────────────
  ACanvas.Font.Color := clWhite;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Size := Max(7, Round(9 * Zoom));
  TxtY := R.Top + Max(6, Round(7 * Zoom));
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(R.Left + 12, TxtY, ANode.Title);

  ACanvas.Font.Style := [];
  ACanvas.Brush.Style := bsSolid;

  AHandled := True;
end;

// ─────────────────────────────────────────────────────────────────────────────
procedure TForm1.EditorDrawPin(Sender: TObject; ACanvas: TCanvas;
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
procedure TForm1.EditorDrawLink(Sender: TObject; ACanvas: TCanvas;
  ALink: TNodeLink; const APath: TLinkPath; ASelected, AHovered: boolean;
  Zoom, OffsetX, OffsetY: double; var AHandled: boolean);
var
  BaseColor: TColor;
  i: integer;
  ScreenPts: array of TPoint;
  P: TPoint;

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

begin
  AHandled := True;
  if (ALink = nil) or (Length(APath.Points) = 0) then Exit;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Style := psSolid;

  if (ALink.FromPin <> nil) and (ALink.FromPin.PinType <> nil) then
    BaseColor := ALink.FromPin.PinType.Color
  else
    BaseColor := $00F0B040;

  case APath.Kind of
    lpkBezier:
      begin
        if Length(APath.Points) < 4 then Exit;

        if ASelected then
        begin
          for i := 4 downto 1 do
          begin
            ACanvas.Pen.Color := RGB(
              ClampByte($16 + Round((GetRValue(clWhite) - $16) * i / 5 * 0.4)),
              ClampByte($16 + Round((GetGValue(clWhite) - $16) * i / 5 * 0.4)),
              ClampByte($16 + Round((GetBValue(clWhite) - $16) * i / 5 * 0.4)));
            ACanvas.Pen.Width := 2 + i * 2;
            DrawCubicBezier(ACanvas,
              WorldToScreenPt(APath.Points[0]),
              WorldToScreenPt(APath.Points[1]),
              WorldToScreenPt(APath.Points[2]),
              WorldToScreenPt(APath.Points[3]));
          end;

          ACanvas.Pen.Color := clWhite;
          ACanvas.Pen.Width := 3;
          DrawCubicBezier(ACanvas,
            WorldToScreenPt(APath.Points[0]),
            WorldToScreenPt(APath.Points[1]),
            WorldToScreenPt(APath.Points[2]),
            WorldToScreenPt(APath.Points[3]));
        end
        else if AHovered then
        begin
          ACanvas.Pen.Color := MixColor(BaseColor, clWhite, 40);
          ACanvas.Pen.Width := 6;
          DrawCubicBezier(ACanvas,
            WorldToScreenPt(APath.Points[0]),
            WorldToScreenPt(APath.Points[1]),
            WorldToScreenPt(APath.Points[2]),
            WorldToScreenPt(APath.Points[3]));

          ACanvas.Pen.Color := MixColor(BaseColor, clWhite, 80);
          ACanvas.Pen.Width := 3;
          DrawCubicBezier(ACanvas,
            WorldToScreenPt(APath.Points[0]),
            WorldToScreenPt(APath.Points[1]),
            WorldToScreenPt(APath.Points[2]),
            WorldToScreenPt(APath.Points[3]));
        end
        else
        begin
          ACanvas.Pen.Color := MixColor(BaseColor, clBlack, 80);
          ACanvas.Pen.Width := 5;
          DrawCubicBezier(ACanvas,
            WorldToScreenPt(APath.Points[0]),
            WorldToScreenPt(APath.Points[1]),
            WorldToScreenPt(APath.Points[2]),
            WorldToScreenPt(APath.Points[3]));

          ACanvas.Pen.Color := BaseColor;
          ACanvas.Pen.Width := 3;
          DrawCubicBezier(ACanvas,
            WorldToScreenPt(APath.Points[0]),
            WorldToScreenPt(APath.Points[1]),
            WorldToScreenPt(APath.Points[2]),
            WorldToScreenPt(APath.Points[3]));

          ACanvas.Pen.Color := MixColor(BaseColor, clWhite, 60);
          ACanvas.Pen.Width := 1;
          DrawCubicBezier(ACanvas,
            WorldToScreenPt(PointF(APath.Points[0].X, APath.Points[0].Y - 1 / Zoom)),
            WorldToScreenPt(PointF(APath.Points[1].X, APath.Points[1].Y - 1 / Zoom)),
            WorldToScreenPt(PointF(APath.Points[2].X, APath.Points[2].Y - 1 / Zoom)),
            WorldToScreenPt(PointF(APath.Points[3].X, APath.Points[3].Y - 1 / Zoom)));
        end;
      end;

    lpkPolyline:
      begin
        SetLength(ScreenPts, Length(APath.Points));
        for i := 0 to High(APath.Points) do
          ScreenPts[i] := WorldToScreenPt(APath.Points[i]);

        if ASelected then
        begin
          for i := 4 downto 1 do
          begin
            ACanvas.Pen.Color := RGB(
              ClampByte($16 + Round((GetRValue(clWhite) - $16) * i / 5 * 0.4)),
              ClampByte($16 + Round((GetGValue(clWhite) - $16) * i / 5 * 0.4)),
              ClampByte($16 + Round((GetBValue(clWhite) - $16) * i / 5 * 0.4)));
            ACanvas.Pen.Width := 2 + i * 2;
            DrawPolyline(ScreenPts);
          end;

          ACanvas.Pen.Color := clWhite;
          ACanvas.Pen.Width := 3;
          DrawPolyline(ScreenPts);
        end
        else if AHovered then
        begin
          ACanvas.Pen.Color := MixColor(BaseColor, clWhite, 40);
          ACanvas.Pen.Width := 6;
          DrawPolyline(ScreenPts);

          ACanvas.Pen.Color := MixColor(BaseColor, clWhite, 80);
          ACanvas.Pen.Width := 3;
          DrawPolyline(ScreenPts);
        end
        else
        begin
          ACanvas.Pen.Color := MixColor(BaseColor, clBlack, 80);
          ACanvas.Pen.Width := 5;
          DrawPolyline(ScreenPts);

          ACanvas.Pen.Color := BaseColor;
          ACanvas.Pen.Width := 3;
          DrawPolyline(ScreenPts);

          ACanvas.Pen.Color := MixColor(BaseColor, clWhite, 60);
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
procedure TForm1.EditorDrawSnapGuides(Sender: TObject; ACanvas: TCanvas;
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

function TForm1.MixColor(C1, C2: TColor; A: byte): TColor;
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

procedure TForm1.RoundRectEx(ACanvas: TCanvas; const R: TRect; Radius: integer);
begin
  ACanvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, Radius, Radius);
end;


// =============================================================================
// Editor event handlers
// =============================================================================

procedure TForm1.OnSelectionChanged(Sender: TObject);
begin
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.OnNodeChanged(Sender: TObject; ANode: TCustomNode);
begin
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.OnEditorZoomChanged(Sender: TObject);
begin
  UpdateStatus;
end;

// =============================================================================
// Status helpers
// =============================================================================

procedure TForm1.UpdateStatus;
var
  SelStr: string;
begin
  if FEditor.SelectedNodeCount > 1 then
    SelStr := 'Selected: ' + IntToStr(FEditor.SelectedNodeCount) + ' nodes'
  else if FEditor.SelectedNodeCount = 1 then
    SelStr := 'Selected: ' + FEditor.GetSelectedNode(0).Title
  else if FEditor.SelectedLinkCount > 0 then
    SelStr := 'Selected: 1 link'
  else
    SelStr := 'No selection';

  FStatusBar.Panels[0].Text := SelStr;
  FStatusBar.Panels[1].Text :=
    'Nodes: ' + IntToStr(FEditor.Graph.Nodes.Count) + '  Links: ' +
    IntToStr(FEditor.Graph.Links.Count);
  FStatusBar.Panels[2].Text := Format('Zoom: %.0f%%', [FEditor.Zoom * 100]);
  FStatusBar.Panels[3].Text :=
    'Grid: ' + BoolToStr(FEditor.SnapToGrid, 'ON', 'OFF') + '  Node: ' +
    BoolToStr(FEditor.SnapToNodes, 'ON', 'OFF') + '  Size: ' +
    IntToStr(FEditor.Style.GridSize);
end;

end.
