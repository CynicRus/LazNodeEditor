unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, LCLIntf, LCLType, types,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Editor,
  LazNodeEditor.Inspector,
  LazNodeEditor.Controller;

type

  { TMathExprNode — кастомная нода с exec-пинами и values }
  TMathExprNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: Single;
      AWidth: Integer = 200; AHeight: Integer = 160); override;
    procedure SetupPins; override;
  end;

  { TMultiplyNode }
  TMultiplyNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: Single;
      AWidth: Integer = 180; AHeight: Integer = 130); override;
    procedure SetupPins; override;
  end;

  { TStringNode — нода со строковым значением }
  TStringNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: Single;
      AWidth: Integer = 180; AHeight: Integer = 100); override;
    procedure SetupPins; override;
  end;

  { TBranchNode — нода с exec-пинами }
  TBranchNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: Single;
      AWidth: Integer = 180; AHeight: Integer = 140); override;
    procedure SetupPins; override;
  end;

  { TForm1 }
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { UI — Layout }
    FTopPanel:        TPanel;
    FBottomPanel:     TPanel;
    FInspectorHost:   TPanel;
    FSplitter:        TSplitter;
    FEditor:          TLazNodeEditor;
    FInspector:       TLazNodeInspector;
    FStatusBar:       TStatusBar;

    { Toolbar — File }
    FBtnNew:          TButton;
    FBtnSave:         TButton;
    FBtnLoad:         TButton;

    { Toolbar — Edit }
    FBtnUndo:         TButton;
    FBtnRedo:         TButton;
    FBtnCopy:         TButton;
    FBtnPaste:        TButton;
    FBtnDuplicate:    TButton;
    FBtnDelete:       TButton;

    { Toolbar — View }
    FBtnFit:          TButton;
    FBtnFrame:        TButton;
    FBtnZoomReset:    TButton;

    { Toolbar — Graph }
    FBtnValidate:     TButton;
    FBtnClearSel:     TButton;

    { Toolbar — Order }
    FBtnBringFront:   TButton;
    FBtnSendBack:     TButton;

    { Toolbar — Settings }
    FChkSnap:         TCheckBox;
    FEdtGridSize:     TEdit;
    FLblGridSize:     TLabel;

    { Toolbar — Add Nodes }
    FBtnAddFloat:     TButton;
    FBtnAddAdd:       TButton;
    FBtnAddMul:       TButton;
    FBtnAddMath:      TButton;
    FBtnAddString:    TButton;
    FBtnAddBranch:    TButton;
    FBtnAddReroute:   TButton;
    FBtnAddComment:   TButton;
    FBtnAddDefault:   TButton;

    { Inspector header }
    FLblInspector:    TLabel;

    { Dialogs }
    FSaveDialog:      TSaveDialog;
    FOpenDialog:      TOpenDialog;

    FDidInitialFrame: Boolean;

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
    procedure EdtGridSizeChange(Sender: TObject);

    { Event handlers — editor }
    procedure OnSelectionChanged(Sender: TObject);
    procedure OnNodeChanged(Sender: TObject; ANode: TCustomNode);
    procedure OnEditorZoomChanged(Sender: TObject);

    { Helpers }
    procedure UpdateStatus;
    function  CenterWorldPos: TPointF;
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

constructor TMathExprNode.Create(ATitle: string; AX, AY: Single;
  AWidth, AHeight: Integer);
var
  V: TNodeValue;
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType     := 'math_expr';
  HeaderColor  := $004080FF;
  BodyColor    := $00F0F8FF;
  // Добавляем значения разных типов — чтобы показать все kinds в инспекторе
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
  // Exec-пины
  AddInput ('▶ Exec In',  'exec', pkExec, 35);
  AddOutput('▶ Exec Out', 'exec', pkExec, 35);
  // Data-пины
  AddInput ('A',      'float',   pkData, 75);
  AddInput ('B',      'float',   pkData, 105);
  AddInput ('C',      'float',   pkData, 135);
  AddOutput('Result', 'float',   pkData, 90);
  // IsRequired demo
  GetInput(1).IsRequired    := True;
  GetInput(2).IsRequired    := True;
  GetInput(1).DefaultValue  := '0.0';
  GetInput(1).Tooltip       := 'First operand';
end;

{ TMultiplyNode }

constructor TMultiplyNode.Create(ATitle: string; AX, AY: Single;
  AWidth, AHeight: Integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType    := 'multiply_node';
  HeaderColor := $0000A0FF;
end;

procedure TMultiplyNode.SetupPins;
begin
  ClearPins;
  AddInput ('A',      'float', pkData, 45);
  AddInput ('B',      'float', pkData, 75);
  AddOutput('Result', 'float', pkData, 60);
  GetInput(0).IsRequired := True;
  GetInput(1).IsRequired := True;
end;

{ TStringNode }

constructor TStringNode.Create(ATitle: string; AX, AY: Single;
  AWidth, AHeight: Integer);
var
  V: TNodeValue;
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType    := 'string_node';
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

constructor TBranchNode.Create(ATitle: string; AX, AY: Single;
  AWidth, AHeight: Integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType    := 'branch_node';
  HeaderColor := $00C04000;
end;

procedure TBranchNode.SetupPins;
begin
  ClearPins;
  AddInput ('▶ Exec',     'exec',    pkExec, 35);
  AddInput ('Condition',  'boolean', pkData, 75);
  AddOutput('▶ True',     'exec',    pkExec, 55);
  AddOutput('▶ False',    'exec',    pkExec, 90);
  GetInput(1).IsRequired := True;
end;

// =============================================================================
// TForm1
// =============================================================================

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption  := 'LazNodeEditor — Full Feature Demo';
  Width    := 1400;
  Height   := 860;
  Position := poScreenCenter;

  FSaveDialog := TSaveDialog.Create(Self);
  FSaveDialog.Filter     := 'JSON Graph|*.json|All Files|*.*';
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

  { StatusBar }
  FStatusBar := TStatusBar.Create(Self);
  FStatusBar.Parent := Self;
  FStatusBar.Align  := alBottom;
  FStatusBar.SimplePanel := False;
  FStatusBar.Panels.Add.Width := 200;  // selection
  FStatusBar.Panels.Add.Width := 180;  // nodes/links count
  FStatusBar.Panels.Add.Width := 150;  // zoom
  FStatusBar.Panels.Add.Width := 200;  // snap
  FStatusBar.Panels.Add.Width := 0;    // hints (stretch)
  UpdateStatus;
end;

procedure TForm1.BuildToolbar;
const
  BH = 26;
  BY =  7;
var
  X: Integer;

  function Btn(const Cap: string; AWidth: Integer): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent  := FTopPanel;
    Result.SetBounds(X, BY, AWidth, BH);
    Result.Caption := Cap;
    Inc(X, AWidth + 2);
  end;

  procedure Sep;
  var L: TLabel;
  begin
    L := TLabel.Create(Self);
    L.Parent  := FTopPanel;
    L.Caption := '│';
    L.Left    := X;
    L.Top     := BY + 4;
    Inc(X, 10);
  end;

begin
  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent     := Self;
  FTopPanel.Align      := alTop;
  FTopPanel.Height     := 42;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Color      := $00F0F0F0;

  X := 4;

  { File }
  FBtnNew  := Btn('New',       60); FBtnNew.OnClick  := @ClickNew;
  FBtnSave := Btn('Save JSON', 80); FBtnSave.OnClick := @ClickSave;
  FBtnLoad := Btn('Load JSON', 80); FBtnLoad.OnClick := @ClickLoad;
  Sep;

  { Edit }
  FBtnUndo      := Btn('Undo',      56); FBtnUndo.OnClick      := @ClickUndo;
  FBtnRedo      := Btn('Redo',      56); FBtnRedo.OnClick      := @ClickRedo;
  FBtnCopy      := Btn('Copy',      50); FBtnCopy.OnClick      := @ClickCopy;
  FBtnPaste     := Btn('Paste',     56); FBtnPaste.OnClick     := @ClickPaste;
  FBtnDuplicate := Btn('Dup',       46); FBtnDuplicate.OnClick := @ClickDuplicate;
  FBtnDelete    := Btn('Del',       42); FBtnDelete.OnClick    := @ClickDelete;
  Sep;

  { View }
  FBtnFit       := Btn('Fit Sel',   64); FBtnFit.OnClick       := @ClickFit;
  FBtnFrame     := Btn('Frame All', 78); FBtnFrame.OnClick     := @ClickFrame;
  FBtnZoomReset := Btn('Zoom 1:1',  68); FBtnZoomReset.OnClick := @ClickZoomReset;
  Sep;

  { Order }
  FBtnBringFront := Btn('▲ Front', 62); FBtnBringFront.OnClick := @ClickBringFront;
  FBtnSendBack   := Btn('▼ Back',  62); FBtnSendBack.OnClick   := @ClickSendBack;
  Sep;

  { Graph }
  FBtnValidate := Btn('Validate', 70); FBtnValidate.OnClick := @ClickValidate;
  FBtnClearSel := Btn('Desel',    54); FBtnClearSel.OnClick := @ClickClearSel;
  Sep;

  { Snap }
  FChkSnap := TCheckBox.Create(Self);
  FChkSnap.Parent  := FTopPanel;
  FChkSnap.SetBounds(X, BY + 2, 90, BH);
  FChkSnap.Caption := 'Snap Grid';
  FChkSnap.OnChange := @ChkSnapChange;
  Inc(X, 94);

  FLblGridSize := TLabel.Create(Self);
  FLblGridSize.Parent  := FTopPanel;
  FLblGridSize.Caption := 'Size:';
  FLblGridSize.Left    := X;
  FLblGridSize.Top     := BY + 6;
  Inc(X, 34);

  FEdtGridSize := TEdit.Create(Self);
  FEdtGridSize.Parent   := FTopPanel;
  FEdtGridSize.SetBounds(X, BY + 2, 36, BH);
  FEdtGridSize.Text     := '40';
  FEdtGridSize.OnChange := @EdtGridSizeChange;
  Inc(X, 42);
  Sep;

  { Add Nodes }
  FBtnAddFloat   := Btn('+ Float',   62); FBtnAddFloat.OnClick   := @ClickAddFloat;
  FBtnAddAdd     := Btn('+ Add',     50); FBtnAddAdd.OnClick     := @ClickAddAdd;
  FBtnAddMul     := Btn('+ Mul',     50); FBtnAddMul.OnClick     := @ClickAddMul;
  FBtnAddMath    := Btn('+ Math',    58); FBtnAddMath.OnClick    := @ClickAddMath;
  FBtnAddString  := Btn('+ String',  64); FBtnAddString.OnClick  := @ClickAddString;
  FBtnAddBranch  := Btn('+ Branch',  66); FBtnAddBranch.OnClick  := @ClickAddBranch;
  FBtnAddReroute := Btn('+ Reroute', 70); FBtnAddReroute.OnClick := @ClickAddReroute;
  FBtnAddComment := Btn('+ Comment', 76); FBtnAddComment.OnClick := @ClickAddComment;
  FBtnAddDefault := Btn('+ Default', 74); FBtnAddDefault.OnClick := @ClickAddDefault;
end;

procedure TForm1.BuildInspectorPanel;
begin
  FInspectorHost := TPanel.Create(Self);
  FInspectorHost.Parent     := Self;
  FInspectorHost.Align      := alLeft;
  FInspectorHost.Width      := 290;
  FInspectorHost.BevelOuter := bvNone;
  FInspectorHost.Caption    := '';
  FInspectorHost.Color      := $00F8F8F8;

  FLblInspector := TLabel.Create(Self);
  FLblInspector.Parent     := FInspectorHost;
  FLblInspector.Left       := 8;
  FLblInspector.Top        := 6;
  FLblInspector.Caption    := 'Node Inspector';
  FLblInspector.Font.Style := [fsBold];
  FLblInspector.Font.Size  := 10;

  FSplitter := TSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.Align  := alLeft;
  FSplitter.Width  := 4;

  FInspector := TLazNodeInspector.Create(Self);
  FInspector.Parent := FInspectorHost;
  FInspector.Align  := alClient;
  FInspector.BorderSpacing.Top   := 28;
  FInspector.BorderSpacing.Left  := 4;
  FInspector.BorderSpacing.Right := 4;
end;

procedure TForm1.BuildEditorArea;
begin
  FEditor := TLazNodeEditor.Create(Self);
  FEditor.Parent := Self;
  FEditor.Align  := alClient;
  FEditor.Color  := $00D8D8D8;
  FEditor.SnapToGrid := False;
  FEditor.GridSize   := 40;

  FInspector.Editor := FEditor;

  FEditor.OnSelectionChanged := @OnSelectionChanged;
  FEditor.OnNodeChanged      := @OnNodeChanged;
  FEditor.OnZoomChanged      := @OnEditorZoomChanged;
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
  // ── Float sources ──────────────────────────────────────────────
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

  // ── Add node ───────────────────────────────────────────────────
  NAdd := FEditor.Graph.Registry.CreateNode('add', 280, 160);
  NAdd.Title := 'A + B';
  FEditor.AddNode(NAdd);

  // ── Multiply node (custom) ─────────────────────────────────────
  NMul := FEditor.Graph.Registry.CreateNode('multiply_node', 280, 310);
  NMul.Title := '(A+B) × C';
  FEditor.AddNode(NMul);

  // ── Math Expression (exec + values) ───────────────────────────
  NMath := FEditor.Graph.Registry.CreateNode('math_expr', 520, 180);
  NMath.Title := 'Math Expr';
  FEditor.AddNode(NMath);

  // ── String node ────────────────────────────────────────────────
  NStr := FEditor.Graph.Registry.CreateNode('string_node', 520, 420);
  NStr.Title := 'Label';
  FEditor.AddNode(NStr);

  // ── Branch node (exec flow) ───────────────────────────────────
  NBranch := FEditor.Graph.Registry.CreateNode('branch_node', 760, 160);
  NBranch.Title := 'If Enabled?';
  FEditor.AddNode(NBranch);

  // ── Reroute ────────────────────────────────────────────────────
  NReroute := FEditor.Graph.Registry.CreateNode('reroute', 430, 370);
  FEditor.AddNode(NReroute);

  // ── Default node ───────────────────────────────────────────────
  NDefault := FEditor.Graph.Registry.CreateNode('default', 760, 360);
  NDefault.Title := 'Default Node';
  FEditor.AddNode(NDefault);

  // ── Comment / Frame 1 (Math block) ────────────────────────────
  NComment1 := FEditor.Graph.Registry.CreateNode('comment', 20, 80);
  NComment1.Title       := 'Math Block';
  NComment1.Width       := 460;
  NComment1.Height      := 360;
  NComment1.CommentText := 'Arithmetic: A+B then ×C';
  NComment1.HeaderColor := $0060A060;
  NComment1.BodyColor   := $00EEFFEE;
  FEditor.AddNode(NComment1);

  // ── Comment / Frame 2 (Flow block) ────────────────────────────
  NComment2 := FEditor.Graph.Registry.CreateNode('comment', 500, 120);
  NComment2.Title       := 'Flow Block';
  NComment2.Width       := 320;
  NComment2.Height      := 200;
  NComment2.CommentText := 'Exec pipeline: Expr → Branch';
  NComment2.HeaderColor := $00804000;
  NComment2.BodyColor   := $00FFF8E8;
  FEditor.AddNode(NComment2);

  // ── Links: Float → Add ─────────────────────────────────────────
  if FEditor.Graph.CanConnect(NFloat1.GetOutput(0), NAdd.GetInput(0)) then
    FEditor.Graph.AddLink(TNodeLink.Create(NFloat1.GetOutput(0), NAdd.GetInput(0)));

  if FEditor.Graph.CanConnect(NFloat2.GetOutput(0), NAdd.GetInput(1)) then
    FEditor.Graph.AddLink(TNodeLink.Create(NFloat2.GetOutput(0), NAdd.GetInput(1)));

  // ── Links: Add+Float3 → Mul ────────────────────────────────────
  if FEditor.Graph.CanConnect(NAdd.GetOutput(0), NMul.GetInput(0)) then
    FEditor.Graph.AddLink(TNodeLink.Create(NAdd.GetOutput(0), NMul.GetInput(0)));

  // Float3 → Reroute → Mul.B
  if (NReroute.InputCount > 0) and (NReroute.OutputCount > 0) then
  begin
    if FEditor.Graph.CanConnect(NFloat3.GetOutput(0), NReroute.GetInput(0)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NFloat3.GetOutput(0), NReroute.GetInput(0)));

    if FEditor.Graph.CanConnect(NReroute.GetOutput(0), NMul.GetInput(1)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NReroute.GetOutput(0), NMul.GetInput(1)));
  end;

  // ── Links: Mul → Math A, Float1 → Math B, Float2 → Math C ─────
  if NMath.InputCount >= 4 then // exec + A + B + C
  begin
    if FEditor.Graph.CanConnect(NMul.GetOutput(0), NMath.GetInput(1)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NMul.GetOutput(0), NMath.GetInput(1)));
    if FEditor.Graph.CanConnect(NFloat1.GetOutput(0), NMath.GetInput(2)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NFloat1.GetOutput(0), NMath.GetInput(2)));
    if FEditor.Graph.CanConnect(NFloat2.GetOutput(0), NMath.GetInput(3)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NFloat2.GetOutput(0), NMath.GetInput(3)));
  end;

  // ── Links: Math Exec Out → Branch Exec In ──────────────────────
  if (NMath.OutputCount >= 1) and (NBranch.InputCount >= 1) then
    if FEditor.Graph.CanConnect(NMath.GetOutput(0), NBranch.GetInput(0)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NMath.GetOutput(0), NBranch.GetInput(0)));

  // ── Links: Branch True → Default In ───────────────────────────
  if (NBranch.OutputCount >= 1) and (NDefault.InputCount >= 1) then
    if FEditor.Graph.CanConnect(NBranch.GetOutput(0), NDefault.GetInput(0)) then
      FEditor.Graph.AddLink(TNodeLink.Create(NBranch.GetOutput(0), NDefault.GetInput(0)));

  // ── Select Math node — демонстрируем все его values в инспекторе
  FEditor.SelectNode(NMath, False);
  FInspector.RefreshFromSelection;

  UpdateStatus;
end;

// =============================================================================
// Toolbar handlers
// =============================================================================

procedure TForm1.ClickNew(Sender: TObject);
begin
  if MessageDlg('New Graph', 'Clear current graph?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
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
  FStatusBar.Panels[4].Text := 'Copied ' + IntToStr(FEditor.SelectedNodeCount) + ' node(s)';
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
  i: Integer;
begin
  if FEditor.SelectedNodeCount = 0 then Exit;
  for i := 0 to FEditor.SelectedNodeCount - 1 do
    FEditor.Graph.BringNodeToFront(FEditor.GetSelectedNode(i));
  FEditor.Invalidate;
  FStatusBar.Panels[4].Text := 'Brought to front';
end;

procedure TForm1.ClickSendBack(Sender: TObject);
var
  i: Integer;
begin
  if FEditor.SelectedNodeCount = 0 then Exit;
  for i := 0 to FEditor.SelectedNodeCount - 1 do
    FEditor.Graph.SendNodeToBack(FEditor.GetSelectedNode(i));
  FEditor.Invalidate;
  FStatusBar.Panels[4].Text := 'Sent to back';
end;

// ── Add node helpers ──────────────────────────────────────────────────────────

function TForm1.CenterWorldPos: TPointF;
begin
  Result.X := (FEditor.ClientWidth  div 2 - 90);
  Result.Y := (FEditor.ClientHeight div 2 - 60);
  // грубое приближение без доступа к ScreenToWorld — достаточно для демки
  Result.X := (Result.X - 0) / FEditor.Zoom;
  Result.Y := (Result.Y - 0) / FEditor.Zoom;
end;

procedure TForm1.AddNodeAtCenter(const ANodeType: string);
var
  N: TCustomNode;
  W: TPointF;
begin
  W := CenterWorldPos;
  N := FEditor.Graph.Registry.CreateNode(ANodeType,
    W.X + Random(60) - 30,
    W.Y + Random(60) - 30);
  FEditor.AddNode(N);
  FEditor.SelectNode(N, False);
  FInspector.RefreshFromSelection;
  UpdateStatus;
end;

procedure TForm1.ClickAddFloat(Sender: TObject);
begin AddNodeAtCenter('float'); end;

procedure TForm1.ClickAddAdd(Sender: TObject);
begin AddNodeAtCenter('add'); end;

procedure TForm1.ClickAddMul(Sender: TObject);
begin AddNodeAtCenter('multiply_node'); end;

procedure TForm1.ClickAddMath(Sender: TObject);
begin AddNodeAtCenter('math_expr'); end;

procedure TForm1.ClickAddString(Sender: TObject);
begin AddNodeAtCenter('string_node'); end;

procedure TForm1.ClickAddBranch(Sender: TObject);
begin AddNodeAtCenter('branch_node'); end;

procedure TForm1.ClickAddReroute(Sender: TObject);
begin AddNodeAtCenter('reroute'); end;

procedure TForm1.ClickAddComment(Sender: TObject);
begin AddNodeAtCenter('comment'); end;

procedure TForm1.ClickAddDefault(Sender: TObject);
begin AddNodeAtCenter('default'); end;

// ── Settings ──────────────────────────────────────────────────────────────────

procedure TForm1.ChkSnapChange(Sender: TObject);
begin
  FEditor.SnapToGrid := FChkSnap.Checked;
  UpdateStatus;
end;

procedure TForm1.EdtGridSizeChange(Sender: TObject);
var
  V: Integer;
begin
  V := StrToIntDef(FEdtGridSize.Text, 40);
  if V > 4 then
  begin
    FEditor.GridSize := V;
    UpdateStatus;
  end;
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
    'Nodes: ' + IntToStr(FEditor.Graph.Nodes.Count) +
    '  Links: ' + IntToStr(FEditor.Graph.Links.Count);
  FStatusBar.Panels[2].Text := Format('Zoom: %.0f%%', [FEditor.Zoom * 100]);
  FStatusBar.Panels[3].Text :=
    'Snap: ' + BoolToStr(FEditor.SnapToGrid, 'ON', 'OFF') +
    '  Grid: ' + IntToStr(FEditor.GridSize);
end;

end.
