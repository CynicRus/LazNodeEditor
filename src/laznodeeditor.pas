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
unit LazNodeEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, ExtCtrls, LCLIntf, LCLType, Math, Types,
  Menus, Clipbrd, fpjson, jsonparser, Forms, StdCtrls, Grids, Dialogs, LazUTF8,
  Generics.Collections;

type
  TCustomNode = class;
  TNodeGraph = class;
  TLazNodeEditor = class;
  TLazNodeInspector = class;
  TNodeLink = class;
  TGraphCommand = class;
  TNodeDefinition = class;
  TNodeValue = class;
  TNodePin = class;
  TNodeEditorController = class;
  TCustomNodeList = specialize TObjectList<TCustomNode>;
  TNodeLinkList = specialize TObjectList<TNodeLink>;
  TGraphCommandList = specialize TObjectList<TGraphCommand>;
  TNodeValueList = specialize TObjectList<TNodeValue>;
  TNodePinList = specialize TObjectList<TNodePin>;

  TPinKind = (pkData, pkExec);
  TPinDirection = (pdInput, pdOutput);

  TNodeValueKind = (
    nvkNull,
    nvkFloat,
    nvkInteger,
    nvkString,
    nvkBoolean,
    nvkJSON
    );

  TNodePinTypeFlag = (
    ptfAny,
    ptfArray,
    ptfList,
    ptfMap,
    ptfObject,
    ptfNullable,
    ptfOptional,
    ptfGeneric,
    ptfWildcard
    );

  TNodePinTypeFlags = set of TNodePinTypeFlag;

  TNodeVisualKind = (nvNormal, nvReroute, nvComment);
  TGraphValidationIssueKind = (gviError, gviWarning);

  TGraphNodeEvent = procedure(Sender: TObject; ANode: TCustomNode) of object;
  TGraphLinkEvent = procedure(Sender: TObject; ALink: TNodeLink) of object;
  TGraphChangedEvent = procedure(Sender: TObject) of object;

  TNodePinType = class
  public
    TypeId: string;
    Category: string;
    DisplayName: string;
    Color: TColor;
    Flags: TNodePinTypeFlags;

    constructor Create(const ATypeId: string = 'any'; const ACategory: string = '';
      AColor: TColor = clLime);

    function IsAny: boolean;
    function IsCompatibleWith(AOther: TNodePinType): boolean;
    function Clone: TNodePinType;

    procedure SaveToJSON(AObj: TJSONObject);
    procedure LoadFromJSON(AObj: TJSONObject);
  end;

  TNodeValue = class
  public
    Name: string;
    Kind: TNodeValueKind;
    FloatValue: double;
    IntegerValue: int64;
    StringValue: string;
    BooleanValue: boolean;
    JSONValue: string;

    constructor Create(const AName: string = ''; AKind: TNodeValueKind = nvkNull);

    procedure SaveToJSON(AObj: TJSONObject);
    procedure LoadFromJSON(AObj: TJSONObject);
  end;

  { TNodePin }
  TNodePin = class
  public
    Id: string;
    Name: string;
    DisplayName: string;
    Kind: TPinKind;
    Direction: TPinDirection;

    // Legacy
    DataType: string;

    PinType: TNodePinType;

    LocalY: integer;
    OwnerNode: TCustomNode;

    IsRequired: boolean;
    DefaultValue: string;
    Tooltip: string;
    Hidden: boolean;
    Advanced: boolean;
    AllowMultipleConnections: boolean;
    SortIndex: integer;

    constructor Create(AName: string; ADir: TPinDirection; AKind: TPinKind;
      ALocalY: integer);
    destructor Destroy; override;

    function EffectiveDisplayName: string;
    procedure SetTypeId(const ATypeId: string);
  end;

  { TNodeLink }
  TNodeLink = class
  public
    Id: string;
    FromPin: TNodePin;
    ToPin: TNodePin;
    constructor Create(AFrom, ATo: TNodePin);
  end;

  { TGraphValidationIssue }
  TGraphValidationIssue = class
  public
    Kind: TGraphValidationIssueKind;
    MessageText: string;
    Node: TCustomNode;
    Link: TNodeLink;
  end;

  TCustomNodeClass = class of TCustomNode;

  { TCustomNode }
  TCustomNode = class
  private
    FInputs: TList;
    FOutputs: TList;
    FValues: TList;
  protected
    function GetDefaultHeaderColor: TColor; virtual;
    function GetDefaultBodyColor: TColor; virtual;
  public
    Id: string;
    NodeType: string;
    Title: string;
    X, Y: single;
    Width, Height: integer;
    HeaderColor: TColor;
    BodyColor: TColor;
    Selected: boolean;

    VisualKind: TNodeVisualKind;
    CommentText: string;
    Hovered: boolean;
    Highlighted: boolean;

    Collapsed: boolean;
    ZOrder: integer;

    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 120); virtual;
    destructor Destroy; override;

    procedure SetupPins; virtual;

    procedure AddInput(AName, ADataType: string; AKind: TPinKind; ALocalY: integer);
    procedure AddOutput(AName, ADataType: string; AKind: TPinKind; ALocalY: integer);
    procedure ClearPins;

    function AddInputPin(const AName, ADataType: string;
      AKind: TPinKind = pkData; ALocalY: integer = -1): TNodePin;
    function AddOutputPin(const AName, ADataType: string;
      AKind: TPinKind = pkData; ALocalY: integer = -1): TNodePin;
    function RemovePin(APin: TNodePin): boolean;
    procedure ReindexPins;
    procedure AutoLayoutPins;

    function InputCount: integer;
    function OutputCount: integer;
    function GetInput(Index: integer): TNodePin;
    function GetOutput(Index: integer): TNodePin;
    function FindPinById(const AId: string): TNodePin;

    function GetPinLocalPosition(APin: TNodePin): TPoint;
    function GetPinScreenPosition(APin: TNodePin; Zoom: double;
      OffsetX, OffsetY: integer): TPoint;
    function GetPinScreenRect(APin: TNodePin; Zoom: double;
      OffsetX, OffsetY: integer; Radius: integer = 8): TRect;

    function GetPinAt(LocalX, LocalY: integer): TNodePin;
    function HitTest(WX, WY: single): boolean;
    function GetScreenBounds(Zoom: double; OffsetX, OffsetY: integer): TRect;

    procedure ClearValues;
    function AddValue(const AName: string; AKind: TNodeValueKind): TNodeValue;
    function FindValue(const AName: string): TNodeValue;
    function ValueCount: integer;
    function GetValue(Index: integer): TNodeValue;

    procedure Paint(Canvas: TCanvas; Zoom: double; OffsetX, OffsetY: integer); virtual;

    procedure SaveToJSON(AObj: TJSONObject); virtual;
    procedure LoadFromJSON(AObj: TJSONObject); virtual;
  end;

  { Default Nodes }
  TDefaultNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 120); override;
    procedure SetupPins; override;
  end;

  TFloatNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 100); override;
    procedure SetupPins; override;
  end;

  TAddNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure SetupPins; override;
  end;

  TRerouteNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 28;
      AHeight: integer = 28); override;
    procedure SetupPins; override;
  end;

  TCommentNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 320;
      AHeight: integer = 200); override;
    procedure SetupPins; override;
  end;

  { TNodeDefinition }

  TNodeDefinition = class
  public
    NodeType: string;
    Caption: string;
    Category: string;
    Description: string;
    Tags: TStringList;
    NodeClass: TCustomNodeClass;
    Version: integer;
    Hidden: boolean;
    Deprecated: boolean;
    Color: TColor;

    constructor Create;
    destructor Destroy; override;

    function MatchesFilter(const AFilter: string): boolean;
  end;

  TNodeRegistryItem = TNodeDefinition;

  { TNodeRegistry }
  TNodeRegistry = class
  private
    FItems: TList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterNode(const ANodeType, ACaption: string; AClass: TCustomNodeClass);
    procedure RegisterNodeEx(const ANodeType, ACaption, ACategory,
      ADescription, ATags: string; AClass: TCustomNodeClass;
      AColor: TColor = clNone; AHidden: boolean = False;
      ADeprecated: boolean = False; AVersion: integer = 1);
    function CreateNode(const ANodeType: string; AX, AY: single): TCustomNode;
    function FindItem(const ANodeType: string): TNodeRegistryItem;
    function Count: integer;
    function Item(Index: integer): TNodeRegistryItem;
  end;

  { TNodeGraph — MODEL}
  TNodeGraph = class
  private
    FNodes: TCustomNodeList;
    FLinks: TNodeLinkList;
    FRegistry: TNodeRegistry;
    FUndoStack: TGraphCommandList;
    FRedoStack: TGraphCommandList;
    FUndoLock: boolean;
    FExecutingCommand: boolean;
    FOnNodeAdded: TGraphNodeEvent;
    FOnNodeRemoved: TGraphNodeEvent;
    FOnLinkAdded: TGraphLinkEvent;
    FOnLinkRemoved: TGraphLinkEvent;
    FOnGraphChanged: TGraphChangedEvent;
    FUpdateLock: integer;

    procedure DoGraphChanged;
    procedure RemoveLinksToInput(APin: TNodePin);

    function PinHasIncomingLink(APin: TNodePin): boolean;
    function PinHasOutgoingLink(APin: TNodePin): boolean;
    procedure PushExecutedCommand(ACommand: TGraphCommand);
  public
    constructor Create;
    destructor Destroy; override;

    procedure BeginUpdate;
    procedure EndUpdate;

    procedure AddNode(ANode: TCustomNode);
    function DetachNode(ANode: TCustomNode): boolean;
    procedure RemoveNode(ANode: TCustomNode);
    procedure AddLink(ALink: TNodeLink);
    procedure RemoveLink(ALink: TNodeLink);

    function CheckInvariants(AErrors: TStrings = nil): boolean;
    procedure NormalizeGraph;
    function IsNodeIdUnique(const AId: string; AExcept: TCustomNode = nil): boolean;
    function IsPinIdUnique(const AId: string; AExcept: TNodePin = nil): boolean;

    function AddDynamicInputPin(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function AddDynamicOutputPin(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function RemoveDynamicPin(APin: TNodePin): boolean;

    function FindNodeById(const AId: string): TCustomNode;
    function FindPinById(const AId: string): TNodePin;
    function CanConnect(P1, P2: TNodePin): boolean;
    function LinkExists(FromPin, ToPin: TNodePin): boolean;

    procedure Clear;
    procedure PushUndoSnapshot;
    procedure Undo;
    procedure Redo;

    function SaveGraphToJSON: TJSONObject;
    procedure LoadGraphFromJSON(AObj: TJSONObject);

    function ValidateGraph: boolean;
    function ValidateGraphIssues(AIssues: TList): boolean;
    function HasCycle: boolean;
    function CreateRerouteForLink(ALink: TNodeLink; AX, AY: single): TCustomNode;
    function GetCompatibleNodesForPin(APin: TNodePin): TStringList;

    procedure ExecuteCommand(ACommand: TGraphCommand);
    procedure ClearUndoRedo;
    function CaptureJSONText: string;
    procedure ExecuteJSONSnapshotCommand(
      const ABeforeJSON, AAfterJSON, ADescription: string);

    function NextZOrder: integer;
    procedure BringNodeToFront(ANode: TCustomNode);
    procedure SendNodeToBack(ANode: TCustomNode);

    property Nodes: TCustomNodeList read FNodes;
    property Links: TNodeLinkList read FLinks;
    property Registry: TNodeRegistry read FRegistry;
    property OnNodeAdded: TGraphNodeEvent read FOnNodeAdded write FOnNodeAdded;
    property OnNodeRemoved: TGraphNodeEvent read FOnNodeRemoved write FOnNodeRemoved;
    property OnLinkAdded: TGraphLinkEvent read FOnLinkAdded write FOnLinkAdded;
    property OnLinkRemoved: TGraphLinkEvent read FOnLinkRemoved write FOnLinkRemoved;
    property OnGraphChanged: TGraphChangedEvent
      read FOnGraphChanged write FOnGraphChanged;
  end;

  { TGraphCommand }

  TGraphCommand = class
  protected
    FGraph: TNodeGraph;
    FDescription: string;
  public
    constructor Create(AGraph: TNodeGraph; const ADescription: string = ''); virtual;
    destructor Destroy; override;

    procedure DoExecute; virtual; abstract;
    procedure Undo; virtual; abstract;

    property Description: string read FDescription;
  end;

  { TJSONSnapshotCommand }

  TJSONSnapshotCommand = class(TGraphCommand)
  private
    FBeforeJSON: string;
    FAfterJSON: string;
  public
    constructor Create(AGraph: TNodeGraph; const ABeforeJSON, AAfterJSON: string;
      const ADescription: string = 'Snapshot'); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TAddNodeCommand }

  TAddNodeCommand = class(TGraphCommand)
  private
    FNode: TCustomNode;
    FOwnsNode: boolean;
  public
    constructor Create(AGraph: TNodeGraph; ANode: TCustomNode); reintroduce;
    destructor Destroy; override;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TRemoveNodeCommand }

  TRemoveNodeCommand = class(TGraphCommand)
  private
    FNodeId: string;
    FNodeJSON: string;
    FGraphBeforeJSON: string;
    FGraphAfterJSON: string;
  public
    constructor Create(AGraph: TNodeGraph; ANode: TCustomNode); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TAddLinkCommand }

  TAddLinkCommand = class(TGraphCommand)
  private
    FFromPinId: string;
    FToPinId: string;
    FLinkId: string;
  public
    constructor Create(AGraph: TNodeGraph; AFromPin, AToPin: TNodePin); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TRemoveLinkCommand }

  TRemoveLinkCommand = class(TGraphCommand)
  private
    FFromPinId: string;
    FToPinId: string;
    FLinkId: string;
  public
    constructor Create(AGraph: TNodeGraph; ALink: TNodeLink); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TMoveNodesCommand }

  TMoveNodesCommand = class(TGraphCommand)
  private
    FNodeIds: TStringList;
    FOldX: array of single;
    FOldY: array of single;
    FNewX: array of single;
    FNewY: array of single;
  public
    constructor Create(AGraph: TNodeGraph; ANodes: TCustomNodeList;
      const AOldPositions, ANewPositions: array of TPointF); reintroduce;
    destructor Destroy; override;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TResizeNodeCommand }

  TResizeNodeCommand = class(TGraphCommand)
  private
    FNodeId: string;
    FOldWidth: integer;
    FOldHeight: integer;
    FNewWidth: integer;
    FNewHeight: integer;
  public
    constructor Create(AGraph: TNodeGraph; ANode: TCustomNode;
      AOldWidth, AOldHeight, ANewWidth, ANewHeight: integer); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TChangeNodePropertyCommand }

  TChangeNodePropertyCommand = class(TGraphCommand)
  private
    FNodeId: string;
    FOldJSON: string;
    FNewJSON: string;
  public
    constructor Create(AGraph: TNodeGraph; ANode: TCustomNode;
      const AOldNodeJSON, ANewNodeJSON: string); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TLazNodeInspector }
  TLazNodeInspector = class(TCustomControl)
  private
    FEditor: TLazNodeEditor;

    FScrollBox: TScrollBox;

    FGrpInfo: TGroupBox;
    FLblType: TLabel;
    FLblTypeVal: TLabel;

    FGrpBasic: TGroupBox;
    FLblTitle: TLabel;
    FTitleEdit: TEdit;
    FLblX: TLabel;
    FXEdit: TEdit;
    FLblY: TLabel;
    FYEdit: TEdit;
    FLblWidth: TLabel;
    FWidthEdit: TEdit;
    FLblHeight: TLabel;
    FHeightEdit: TEdit;

    FGrpVisual: TGroupBox;
    FLblHeaderColor: TLabel;
    FHeaderColorPanel: TPanel;
    FLblBodyColor: TLabel;
    FBodyColorPanel: TPanel;
    FCollapsedCheck: TCheckBox;

    FGrpComment: TGroupBox;
    FLblComment: TLabel;
    FCommentMemo: TMemo;

    FGrpPins: TGroupBox;
    FPinsGrid: TStringGrid;

    FGrpValues: TGroupBox;
    FValuesGrid: TStringGrid;

    FApplyButton: TButton;
    FRevertButton: TButton;

    FUpdating: boolean;

    procedure BuildControls;
    procedure BuildInfoSection(AParent: TWinControl; var ATop: integer);
    procedure BuildBasicSection(AParent: TWinControl; var ATop: integer);
    procedure BuildVisualSection(AParent: TWinControl; var ATop: integer);
    procedure BuildCommentSection(AParent: TWinControl; var ATop: integer);
    procedure BuildPinsSection(AParent: TWinControl; var ATop: integer);
    procedure BuildValuesSection(AParent: TWinControl; var ATop: integer);
    procedure BuildButtonBar(AParent: TWinControl; var ATop: integer);

    procedure ApplyClick(Sender: TObject);
    procedure RevertClick(Sender: TObject);
    procedure HeaderColorClick(Sender: TObject);
    procedure BodyColorClick(Sender: TObject);

    procedure SetEditor(AValue: TLazNodeEditor);
    procedure ClearAllSections;
    procedure ShowNoSelection;

    function MakeLabel(AParent: TWinControl; const AText: string;
      ALeft, ATop, AWidth: integer): TLabel;
    function MakeEdit(AParent: TWinControl; ALeft, ATop, AWidth: integer): TEdit;
    function MakeColorPanel(AParent: TWinControl;
      ALeft, ATop, AWidth: integer): TPanel;
    procedure ValuesGridSelectCell(Sender: TObject; ACol, ARow: integer;
      var CanSelect: boolean);
    function SafeClientWidth(AControl: TWinControl; ADefault: integer = 270): integer;
    function EditWidth(AParent: TWinControl; ALeft: integer): integer;
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshFromSelection;
    property Editor: TLazNodeEditor read FEditor write SetEditor;
  end;

  TNodeSelectionChangedEvent = procedure(Sender: TObject) of object;
  TNodeChangedEvent = procedure(Sender: TObject; ANode: TCustomNode) of object;

  { TLazNodeEditor — VIEW + CONTROLLER }
  TLazNodeEditor = class(TCustomControl)
  private
    FGraph: TNodeGraph;
    FController: TNodeEditorController;

    FZoom: double;
    FOffsetX, FOffsetY: integer;

    FSelectedNode: TCustomNode;
    FSelectedLink: TNodeLink;
    FSelectedNodes: TCustomNodeList;

    FDraggingNode: boolean;
    FDragStartX, FDragStartY: integer;
    FDragUndoPushed: boolean;

    FDragCommandNodes: TCustomNodeList;
    FDragOldPositions: array of TPointF;

    FPanning: boolean;
    FPanStartX, FPanStartY: integer;
    FRightMouseMoved: boolean;

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
    function GetPinUnderMouse(SX, SY: integer; out Node: TCustomNode;
      out Pin: TNodePin): boolean;
    function GetLinkUnderMouse(SX, SY: integer; out Link: TNodeLink): boolean;

    procedure ClearSelectionInternal;
    procedure SelectNodeInternal(ANode: TCustomNode; AAppend: boolean);
    procedure SelectLinkInternal(ALink: TNodeLink);
    function IsMouseNearLinkStart(ALink: TNodeLink; SX, SY: integer): boolean;

    procedure ShowNodeSearchPopup(AScreenX, AScreenY: integer; AWorldX, AWorldY: single);
    function CreateCompatibleNodeForPin(APin: TNodePin; AX, AY: single): TCustomNode;
    procedure ResetStateAfterGraphReload;
    procedure ClearHoverStates;
    procedure UpdateHoverStates(SX, SY: integer);

    function SnapWorldValue(V: single): single;
    function SnapWorldPoint(const P: TPointF): TPointF;


  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: integer;
      MousePos: TPoint): boolean; override;
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
    property Zoom: double read FZoom;

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
  end;


  { TNodeSelectionModel }
  TNodeSelectionModel = class
  private
    FNodes: TCustomNodeList;
    FSelectedLink: TNodeLink;
    FOnChanged: TNotifyEvent;
    procedure NotifyChanged;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure SelectNode(ANode: TCustomNode; AAppend: boolean);
    procedure SelectLink(ALink: TNodeLink);
    procedure RemoveNode(ANode: TCustomNode);

    function NodeCount: integer;
    function GetNode(Index: integer): TCustomNode;
    function HasLink: boolean;
    function SelectedLink: TNodeLink;

    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  { TNodeClipboardService }
  TNodeClipboardService = class
  public
    function NodesToJSONText(ANodes: TCustomNodeList; AGraph: TNodeGraph): string;
    procedure PasteNodesFromJSONText(const AJSON: string; AGraph: TNodeGraph;
      AX, AY: single; ASelection: TNodeSelectionModel);
  end;

  { TNodeEditorController }
  TNodeEditorController = class
  private
    FGraph: TNodeGraph;
    FSelection: TNodeSelectionModel;
    FClipboard: TNodeClipboardService;
  public
    constructor Create(AGraph: TNodeGraph);
    destructor Destroy; override;

    procedure ExecuteCommand(ACmd: TGraphCommand);
    procedure Undo;
    procedure Redo;
    procedure ClearUndoRedo;

    procedure DeleteSelection;
    procedure CopySelectionToClipboard;
    procedure PasteFromClipboard(AX, AY: single);
    procedure DuplicateSelection(AX, AY: single);

    property Graph: TNodeGraph read FGraph;
    property Selection: TNodeSelectionModel read FSelection;
    property ClipboardService: TNodeClipboardService read FClipboard;
  end;

  TNodeSearchForm = class(TForm)
  private
    FEdit: TEdit;
    FList: TListBox;
    FRegistry: TNodeRegistry;
    procedure EditChange(Sender: TObject);
    procedure ListDblClick(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure RebuildList;
  public
    SelectedNodeType: string;
    constructor CreateSearch(AOwner: TComponent; ARegistry: TNodeRegistry);
      reintroduce;
  end;

procedure Register;

implementation

// =============================================================================
// Helpers
// =============================================================================

function NewId: string;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result := GUIDToString(G);
end;

function PinKindToStr(AKind: TPinKind): string;
begin
  if AKind = pkExec then
    Result := 'exec'
  else
    Result := 'data';
end;

function StrToPinKind(const S: string): TPinKind;
begin
  if SameText(S, 'exec') then
    Result := pkExec
  else
    Result := pkData;
end;

function PinDirectionToStr(ADir: TPinDirection): string;
begin
  if ADir = pdInput then
    Result := 'input'
  else
    Result := 'output';
end;

function StrToPinDirection(const S: string): TPinDirection;
begin
  if SameText(S, 'output') then
    Result := pdOutput
  else
    Result := pdInput;
end;

function NormalizeRect(const R: TRect): TRect;
begin
  Result.Left := Min(R.Left, R.Right);
  Result.Right := Max(R.Left, R.Right);
  Result.Top := Min(R.Top, R.Bottom);
  Result.Bottom := Max(R.Top, R.Bottom);
end;

function RectIntersects(const A, B: TRect): boolean;
begin
  Result := not ((A.Right < B.Left) or (A.Left > B.Right) or
    (A.Bottom < B.Top) or (A.Top > B.Bottom));
end;

function UnionRectSafe(const A, B: TRect): TRect;
begin
  Result.Left := Min(A.Left, B.Left);
  Result.Top := Min(A.Top, B.Top);
  Result.Right := Max(A.Right, B.Right);
  Result.Bottom := Max(A.Bottom, B.Bottom);
end;

function CubicBezierPoint(const P0, P1, P2, P3: TPoint; t: double): TPointF;
var
  it, t2, t3, it2, it3: double;
begin
  it := 1 - t;
  t2 := t * t;
  t3 := t2 * t;
  it2 := it * it;
  it3 := it2 * it;

  Result.X := it3 * P0.X + 3 * it2 * t * P1.X + 3 * it * t2 * P2.X + t3 * P3.X;
  Result.Y := it3 * P0.Y + 3 * it2 * t * P1.Y + 3 * it * t2 * P2.Y + t3 * P3.Y;
end;

function DistancePointToSegment(const P, A, B: TPointF): double;
var
  ABx, ABy, APx, APy, T, Dx, Dy: double;
begin
  ABx := B.X - A.X;
  ABy := B.Y - A.Y;
  APx := P.X - A.X;
  APy := P.Y - A.Y;

  if (ABx = 0) and (ABy = 0) then
  begin
    Dx := P.X - A.X;
    Dy := P.Y - A.Y;
    Exit(Sqrt(Dx * Dx + Dy * Dy));
  end;

  T := (APx * ABx + APy * ABy) / (ABx * ABx + ABy * ABy);
  T := EnsureRange(T, 0, 1);

  Dx := P.X - (A.X + T * ABx);
  Dy := P.Y - (A.Y + T * ABy);
  Result := Sqrt(Dx * Dx + Dy * Dy);
end;

function PointDistance(const A, B: TPoint): double;
begin
  Result := Sqrt(Sqr(A.X - B.X) + Sqr(A.Y - B.Y));
end;

procedure DrawCubicBezier(C: TCanvas; P0, P1, P2, P3: TPoint; Steps: integer = 32);
var
  i: integer;
  t, it, t2, it2, t3, it3, x, y: double;
begin
  C.MoveTo(P0.X, P0.Y);
  for i := 1 to Steps do
  begin
    t := i / Steps;
    it := 1 - t;
    t2 := t * t;
    it2 := it * it;
    t3 := t2 * t;
    it3 := it2 * it;

    x := it3 * P0.X + 3 * it2 * t * P1.X + 3 * it * t2 * P2.X + t3 * P3.X;
    y := it3 * P0.Y + 3 * it2 * t * P1.Y + 3 * it * t2 * P2.Y + t3 * P3.Y;

    C.LineTo(Round(x), Round(y));
  end;
end;

procedure LoadGraphFromJSONText(AGraph: TNodeGraph; const S: string);
var
  Data: TJSONData;
begin
  if AGraph = nil then
    Exit;

  if Trim(S) = '' then
    Exit;

  Data := GetJSON(S);
  try
    if Data.JSONType = jtObject then
      AGraph.LoadGraphFromJSON(TJSONObject(Data));
  finally
    Data.Free;
  end;
end;

function NodePaintCompare(Item1, Item2: Pointer): integer;
var
  A, B: TCustomNode;
begin
  A := TCustomNode(Item1);
  B := TCustomNode(Item2);

  if A.ZOrder < B.ZOrder then
    Result := -1
  else if A.ZOrder > B.ZOrder then
    Result := 1
  else
    Result := 0;
end;

procedure BuildSortedNodeList(AGraph: TNodeGraph; AList: TList);
var
  i: integer;
begin
  AList.Clear;

  if AGraph = nil then
    Exit;

  for i := 0 to AGraph.Nodes.Count - 1 do
    AList.Add(AGraph.Nodes[i]);

  AList.Sort(@NodePaintCompare);
end;

// =============================================================================
// TNodePinType
// =============================================================================

function NodeValueKindToStr(AKind: TNodeValueKind): string;
begin
  case AKind of
    nvkFloat: Result := 'float';
    nvkInteger: Result := 'integer';
    nvkString: Result := 'string';
    nvkBoolean: Result := 'boolean';
    nvkJSON: Result := 'json';
    else
      Result := 'null';
  end;
end;

function StrToNodeValueKind(const S: string): TNodeValueKind;
begin
  if SameText(S, 'float') then
    Result := nvkFloat
  else if SameText(S, 'integer') then
    Result := nvkInteger
  else if SameText(S, 'string') then
    Result := nvkString
  else if SameText(S, 'boolean') then
    Result := nvkBoolean
  else if SameText(S, 'json') then
    Result := nvkJSON
  else
    Result := nvkNull;
end;

function TypeFlagsToInt(AFlags: TNodePinTypeFlags): integer;
var
  F: TNodePinTypeFlag;
begin
  Result := 0;
  for F := Low(TNodePinTypeFlag) to High(TNodePinTypeFlag) do
    if F in AFlags then
      Result := Result or (1 shl Ord(F));
end;

function IntToTypeFlags(AValue: integer): TNodePinTypeFlags;
var
  F: TNodePinTypeFlag;
begin
  Result := [];
  for F := Low(TNodePinTypeFlag) to High(TNodePinTypeFlag) do
    if (AValue and (1 shl Ord(F))) <> 0 then
      Include(Result, F);
end;

constructor TNodePinType.Create(const ATypeId: string; const ACategory: string;
  AColor: TColor);
begin
  inherited Create;

  TypeId := LowerCase(Trim(ATypeId));
  if TypeId = '' then
    TypeId := 'any';

  Category := ACategory;
  DisplayName := TypeId;
  Color := AColor;
  Flags := [];

  if SameText(TypeId, 'any') then
    Include(Flags, ptfAny);
end;

function TNodePinType.IsAny: boolean;
begin
  Result := SameText(TypeId, 'any') or (ptfAny in Flags) or (ptfWildcard in Flags);
end;

function TNodePinType.IsCompatibleWith(AOther: TNodePinType): boolean;
begin
  Result := False;

  if AOther = nil then
    Exit;

  if IsAny or AOther.IsAny then
    Exit(True);

  if SameText(TypeId, AOther.TypeId) then
    Exit(True);

  if SameText(TypeId, 'integer') and SameText(AOther.TypeId, 'float') then
    Exit(True);

  if SameText(TypeId, 'float') and SameText(AOther.TypeId, 'integer') then
    Exit(True);

  if (ptfNullable in Flags) and SameText(TypeId, AOther.TypeId) then
    Exit(True);

  if (ptfNullable in AOther.Flags) and SameText(TypeId, AOther.TypeId) then
    Exit(True);
end;

function TNodePinType.Clone: TNodePinType;
begin
  Result := TNodePinType.Create(TypeId, Category, Color);
  Result.DisplayName := DisplayName;
  Result.Flags := Flags;
end;

procedure TNodePinType.SaveToJSON(AObj: TJSONObject);
begin
  if AObj = nil then
    Exit;

  AObj.Add('typeId', TypeId);
  AObj.Add('category', Category);
  AObj.Add('displayName', DisplayName);
  AObj.Add('color', integer(Color));
  AObj.Add('flags', TypeFlagsToInt(Flags));
end;

procedure TNodePinType.LoadFromJSON(AObj: TJSONObject);
begin
  if AObj = nil then
    Exit;

  TypeId := AObj.Get('typeId', TypeId);
  Category := AObj.Get('category', Category);
  DisplayName := AObj.Get('displayName', DisplayName);
  Color := TColor(AObj.Get('color', integer(Color)));
  Flags := IntToTypeFlags(AObj.Get('flags', TypeFlagsToInt(Flags)));

  if TypeId = '' then
    TypeId := 'any';
end;


// =============================================================================
// TNodeValue
// =============================================================================

constructor TNodeValue.Create(const AName: string; AKind: TNodeValueKind);
begin
  inherited Create;

  Name := AName;
  Kind := AKind;
  FloatValue := 0;
  IntegerValue := 0;
  StringValue := '';
  BooleanValue := False;
  JSONValue := '';
end;

procedure TNodeValue.SaveToJSON(AObj: TJSONObject);
begin
  if AObj = nil then
    Exit;

  AObj.Add('name', Name);
  AObj.Add('kind', NodeValueKindToStr(Kind));

  case Kind of
    nvkFloat:
      AObj.Add('value', FloatValue);

    nvkInteger:
      AObj.Add('value', IntegerValue);

    nvkString:
      AObj.Add('value', StringValue);

    nvkBoolean:
      AObj.Add('value', BooleanValue);

    nvkJSON:
      AObj.Add('value', JSONValue);
    else
      AObj.Add('value', '');
  end;
end;

procedure TNodeValue.LoadFromJSON(AObj: TJSONObject);
begin
  if AObj = nil then
    Exit;

  Name := AObj.Get('name', Name);
  Kind := StrToNodeValueKind(AObj.Get('kind', 'null'));

  case Kind of
    nvkFloat:
      FloatValue := AObj.Get('value', FloatValue);

    nvkInteger:
      IntegerValue := AObj.Get('value', IntegerValue);

    nvkString:
      StringValue := AObj.Get('value', StringValue);

    nvkBoolean:
      BooleanValue := AObj.Get('value', BooleanValue);

    nvkJSON:
      JSONValue := AObj.Get('value', JSONValue);
  end;
end;

// =============================================================================
// TNodePin
// =============================================================================

constructor TNodePin.Create(AName: string; ADir: TPinDirection;
  AKind: TPinKind; ALocalY: integer);
begin
  inherited Create;

  Id := NewId;
  Name := AName;
  DisplayName := AName;

  Direction := ADir;
  Kind := AKind;
  LocalY := ALocalY;

  DataType := '';
  PinType := TNodePinType.Create('any', '', clLime);

  OwnerNode := nil;

  IsRequired := False;
  DefaultValue := '';
  Tooltip := '';
  Hidden := False;
  Advanced := False;
  AllowMultipleConnections := ADir = pdOutput;
  SortIndex := 0;
end;

destructor TNodePin.Destroy;
begin
  PinType.Free;
  inherited Destroy;
end;

function TNodePin.EffectiveDisplayName: string;
begin
  if DisplayName <> '' then
    Result := DisplayName
  else
    Result := Name;
end;

procedure TNodePin.SetTypeId(const ATypeId: string);
begin
  DataType := ATypeId;

  if PinType = nil then
    PinType := TNodePinType.Create(ATypeId)
  else
  begin
    PinType.TypeId := LowerCase(Trim(ATypeId));
    if PinType.TypeId = '' then
      PinType.TypeId := 'any';

    PinType.DisplayName := PinType.TypeId;
    PinType.Flags := [];

    if SameText(PinType.TypeId, 'any') then
      Include(PinType.Flags, ptfAny);
  end;
end;

// =============================================================================
// TNodeLink
// =============================================================================

constructor TNodeLink.Create(AFrom, ATo: TNodePin);
begin
  inherited Create;
  Id := NewId;
  FromPin := AFrom;
  ToPin := ATo;
end;

// =============================================================================
// TCustomNode
// =============================================================================

constructor TCustomNode.Create(ATitle: string; AX, AY: single;
  AWidth: integer; AHeight: integer);
begin
  inherited Create;

  Id := NewId;
  NodeType := 'default';
  Title := ATitle;

  X := AX;
  Y := AY;
  Width := AWidth;
  Height := AHeight;

  HeaderColor := GetDefaultHeaderColor;
  BodyColor := GetDefaultBodyColor;

  FInputs := TList.Create;
  FOutputs := TList.Create;
  FValues := TList.Create;

  Selected := False;

  VisualKind := nvNormal;
  CommentText := '';
  Hovered := False;
  Highlighted := False;
  Collapsed := False;
  ZOrder := 0;
end;

destructor TCustomNode.Destroy;
begin
  ClearValues;
  ClearPins;
  FValues.Free;
  FInputs.Free;
  FOutputs.Free;
  inherited Destroy;
end;

function TCustomNode.GetDefaultHeaderColor: TColor;
begin
  Result := $00C8C800;
end;

function TCustomNode.GetDefaultBodyColor: TColor;
begin
  Result := clWhite;
end;

procedure TCustomNode.SetupPins;
begin
end;

procedure TCustomNode.ClearPins;
var
  i: integer;
begin
  for i := 0 to FInputs.Count - 1 do
    TObject(FInputs[i]).Free;

  for i := 0 to FOutputs.Count - 1 do
    TObject(FOutputs[i]).Free;

  FInputs.Clear;
  FOutputs.Clear;
end;

function TCustomNode.AddInputPin(const AName, ADataType: string;
  AKind: TPinKind; ALocalY: integer): TNodePin;
begin
  if ALocalY < 0 then
    ALocalY := 44 + FInputs.Count * 26;

  Result := TNodePin.Create(AName, pdInput, AKind, ALocalY);
  Result.OwnerNode := Self;
  Result.SetTypeId(ADataType);
  Result.AllowMultipleConnections := False;
  Result.SortIndex := FInputs.Count;
  FInputs.Add(Result);

  AutoLayoutPins;
end;

function TCustomNode.AddOutputPin(const AName, ADataType: string;
  AKind: TPinKind; ALocalY: integer): TNodePin;
begin
  if ALocalY < 0 then
    ALocalY := 44 + FOutputs.Count * 26;

  Result := TNodePin.Create(AName, pdOutput, AKind, ALocalY);
  Result.OwnerNode := Self;
  Result.SetTypeId(ADataType);
  Result.AllowMultipleConnections := True;
  Result.SortIndex := FOutputs.Count;
  FOutputs.Add(Result);

  AutoLayoutPins;
end;

function TCustomNode.RemovePin(APin: TNodePin): boolean;
begin
  Result := False;

  if APin = nil then
    Exit;

  if APin.OwnerNode <> Self then
    Exit;

  if APin.Direction = pdInput then
  begin
    if FInputs.Remove(APin) >= 0 then
    begin
      APin.Free;
      Result := True;
    end;
  end
  else
  begin
    if FOutputs.Remove(APin) >= 0 then
    begin
      APin.Free;
      Result := True;
    end;
  end;

  if Result then
  begin
    ReindexPins;
    AutoLayoutPins;
  end;
end;

procedure TCustomNode.ReindexPins;
var
  i: integer;
begin
  for i := 0 to FInputs.Count - 1 do
    TNodePin(FInputs[i]).SortIndex := i;

  for i := 0 to FOutputs.Count - 1 do
    TNodePin(FOutputs[i]).SortIndex := i;
end;

procedure TCustomNode.AutoLayoutPins;
var
  i: integer;
  MaxCount: integer;
  NeededHeight: integer;
begin
  if VisualKind = nvReroute then
  begin
    for i := 0 to FInputs.Count - 1 do
      TNodePin(FInputs[i]).LocalY := Height div 2;

    for i := 0 to FOutputs.Count - 1 do
      TNodePin(FOutputs[i]).LocalY := Height div 2;

    Exit;
  end;

  if VisualKind = nvComment then
    Exit;

  for i := 0 to FInputs.Count - 1 do
    TNodePin(FInputs[i]).LocalY := 44 + i * 26;

  for i := 0 to FOutputs.Count - 1 do
    TNodePin(FOutputs[i]).LocalY := 44 + i * 26;

  MaxCount := Max(FInputs.Count, FOutputs.Count);
  NeededHeight := 44 + MaxCount * 26 + 18;

  if NeededHeight > Height then
    Height := NeededHeight;
end;

procedure TCustomNode.AddInput(AName, ADataType: string; AKind: TPinKind;
  ALocalY: integer);
var
  p: TNodePin;
begin
  p := TNodePin.Create(AName, pdInput, AKind, ALocalY);
  p.OwnerNode := Self;
  p.SetTypeId(ADataType);
  p.AllowMultipleConnections := False;
  p.SortIndex := FInputs.Count;
  FInputs.Add(p);
  ReindexPins;
end;

procedure TCustomNode.AddOutput(AName, ADataType: string; AKind: TPinKind;
  ALocalY: integer);
var
  p: TNodePin;
begin
  p := TNodePin.Create(AName, pdOutput, AKind, ALocalY);
  p.OwnerNode := Self;
  p.SetTypeId(ADataType);
  p.AllowMultipleConnections := True;
  p.SortIndex := FOutputs.Count;
  FOutputs.Add(p);
  ReindexPins;
end;

function TCustomNode.InputCount: integer;
begin
  Result := FInputs.Count;
end;

function TCustomNode.OutputCount: integer;
begin
  Result := FOutputs.Count;
end;

function TCustomNode.GetInput(Index: integer): TNodePin;
begin
  if (Index >= 0) and (Index < FInputs.Count) then
    Result := TNodePin(FInputs[Index])
  else
    Result := nil;
end;

function TCustomNode.GetOutput(Index: integer): TNodePin;
begin
  if (Index >= 0) and (Index < FOutputs.Count) then
    Result := TNodePin(FOutputs[Index])
  else
    Result := nil;
end;

function TCustomNode.FindPinById(const AId: string): TNodePin;
var
  i: integer;
begin
  Result := nil;

  for i := 0 to InputCount - 1 do
    if GetInput(i).Id = AId then
      Exit(GetInput(i));

  for i := 0 to OutputCount - 1 do
    if GetOutput(i).Id = AId then
      Exit(GetOutput(i));
end;

function TCustomNode.GetPinLocalPosition(APin: TNodePin): TPoint;
begin
  if APin = nil then
    Exit(Point(0, 0));

  if APin.Direction = pdInput then
    Result := Point(0, APin.LocalY)
  else
    Result := Point(Width, APin.LocalY);
end;

function TCustomNode.GetPinScreenPosition(APin: TNodePin; Zoom: double;
  OffsetX, OffsetY: integer): TPoint;
var
  P: TPoint;
begin
  P := GetPinLocalPosition(APin);
  Result.X := Round((X + P.X) * Zoom) + OffsetX;
  Result.Y := Round((Y + P.Y) * Zoom) + OffsetY;
end;

function TCustomNode.GetPinScreenRect(APin: TNodePin; Zoom: double;
  OffsetX, OffsetY: integer; Radius: integer): TRect;
var
  P: TPoint;
  R: integer;
begin
  P := GetPinScreenPosition(APin, Zoom, OffsetX, OffsetY);

  if VisualKind = nvReroute then
    R := Max(5, Radius)
  else
    R := Radius;

  Result := Rect(P.X - R, P.Y - R, P.X + R, P.Y + R);
end;

function TCustomNode.GetPinAt(LocalX, LocalY: integer): TNodePin;
var
  i: integer;
  p: TNodePin;
  CX, CY: integer;
  R: integer;
begin
  Result := nil;

  if VisualKind = nvReroute then
  begin
    R := 10;

    for i := 0 to FInputs.Count - 1 do
    begin
      p := TNodePin(FInputs[i]);
      CX := 0;
      CY := p.LocalY;
      if Sqrt(Sqr(LocalX - CX) + Sqr(LocalY - CY)) <= R then
        Exit(p);
    end;

    for i := 0 to FOutputs.Count - 1 do
    begin
      p := TNodePin(FOutputs[i]);
      CX := Width;
      CY := p.LocalY;
      if Sqrt(Sqr(LocalX - CX) + Sqr(LocalY - CY)) <= R then
        Exit(p);
    end;

    Exit;
  end;

  for i := 0 to FInputs.Count - 1 do
  begin
    p := TNodePin(FInputs[i]);
    if (Abs(LocalX) < 14) and (Abs(LocalY - p.LocalY) < 14) then
      Exit(p);
  end;

  for i := 0 to FOutputs.Count - 1 do
  begin
    p := TNodePin(FOutputs[i]);
    if (Abs(LocalX - Width) < 14) and (Abs(LocalY - p.LocalY) < 14) then
      Exit(p);
  end;
end;

function TCustomNode.HitTest(WX, WY: single): boolean;
var
  CX, CY, RX, RY: single;
begin
  if VisualKind = nvReroute then
  begin
    CX := X + Width * 0.5;
    CY := Y + Height * 0.5;
    RX := Max(16, Width * 0.5 + 8);
    RY := Max(16, Height * 0.5 + 8);

    Result :=
      (Sqr((WX - CX) / RX) + Sqr((WY - CY) / RY)) <= 1.0;
    Exit;
  end;

  Result := (WX >= X) and (WY >= Y) and (WX <= X + Width) and (WY <= Y + Height);
end;

function TCustomNode.GetScreenBounds(Zoom: double; OffsetX, OffsetY: integer): TRect;
begin
  Result.Left := Round(X * Zoom) + OffsetX;
  Result.Top := Round(Y * Zoom) + OffsetY;
  Result.Right := Result.Left + Round(Width * Zoom);
  Result.Bottom := Result.Top + Round(Height * Zoom);
end;

procedure TCustomNode.ClearValues;
var
  i: integer;
begin
  for i := 0 to FValues.Count - 1 do
    TObject(FValues[i]).Free;

  FValues.Clear;
end;

function TCustomNode.AddValue(const AName: string; AKind: TNodeValueKind): TNodeValue;
begin
  Result := FindValue(AName);

  if Result <> nil then
  begin
    Result.Kind := AKind;
    Exit;
  end;

  Result := TNodeValue.Create(AName, AKind);
  FValues.Add(Result);
end;

function TCustomNode.FindValue(const AName: string): TNodeValue;
var
  i: integer;
  V: TNodeValue;
begin
  Result := nil;

  for i := 0 to FValues.Count - 1 do
  begin
    V := TNodeValue(FValues[i]);
    if SameText(V.Name, AName) then
      Exit(V);
  end;
end;

function TCustomNode.ValueCount: integer;
begin
  Result := FValues.Count;
end;

function TCustomNode.GetValue(Index: integer): TNodeValue;
begin
  if (Index >= 0) and (Index < FValues.Count) then
    Result := TNodeValue(FValues[Index])
  else
    Result := nil;
end;

procedure TCustomNode.Paint(Canvas: TCanvas; Zoom: double; OffsetX, OffsetY: integer);
var
  R, HeaderR, BodyR: TRect;
  i: integer;
  p: TNodePin;
  PX, PY: integer;
  HeaderH: integer;
  PinRadius: integer;
begin
  R := GetScreenBounds(Zoom, OffsetX, OffsetY);

  HeaderH := Max(20, Round(28 * Zoom));
  PinRadius := Max(4, Round(8 * Zoom));

  if Collapsed and (VisualKind = nvNormal) then
  begin
    R.Bottom := R.Top + HeaderH;
  end;

  // ---------------------------------------------------------------------------
  // REROUTE NODE
  // ---------------------------------------------------------------------------
  if VisualKind = nvReroute then
  begin
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsSolid;

    if Selected then
    begin
      Canvas.Brush.Color := clNone;
      Canvas.Pen.Color := clRed;
      Canvas.Pen.Width := Max(2, Round(3 * Zoom));
      Canvas.Ellipse(R.Left - 5, R.Top - 5, R.Right + 5, R.Bottom + 5);
    end
    else if Highlighted then
    begin
      Canvas.Brush.Color := clNone;
      Canvas.Pen.Color := clAqua;
      Canvas.Pen.Width := Max(2, Round(3 * Zoom));
      Canvas.Ellipse(R.Left - 4, R.Top - 4, R.Right + 4, R.Bottom + 4);
    end
    else if Hovered then
    begin
      Canvas.Brush.Color := clNone;
      Canvas.Pen.Color := clBlue;
      Canvas.Pen.Width := Max(1, Round(2 * Zoom));
      Canvas.Ellipse(R.Left - 3, R.Top - 3, R.Right + 3, R.Bottom + 3);
    end;

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := $00F8F8F8;
    Canvas.Pen.Color := $00404040;
    Canvas.Pen.Width := Max(1, Round(2 * Zoom));
    Canvas.Ellipse(R.Left, R.Top, R.Right, R.Bottom);

    Canvas.Brush.Color := $00FFFFFF;
    Canvas.Pen.Color := $00808080;
    Canvas.Pen.Width := 1;
    Canvas.Ellipse(
      R.Left + Round(6 * Zoom),
      R.Top + Round(6 * Zoom),
      R.Right - Round(6 * Zoom),
      R.Bottom - Round(6 * Zoom)
      );

    Canvas.Pen.Color := $00505050;
    Canvas.Pen.Width := Max(1, Round(2 * Zoom));
    Canvas.MoveTo(R.Left - Round(10 * Zoom), (R.Top + R.Bottom) div 2);
    Canvas.LineTo(R.Left + Round(5 * Zoom), (R.Top + R.Bottom) div 2);
    Canvas.MoveTo(R.Right - Round(5 * Zoom), (R.Top + R.Bottom) div 2);
    Canvas.LineTo(R.Right + Round(10 * Zoom), (R.Top + R.Bottom) div 2);

    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Style := psSolid;
    Exit;
  end;

  // ---------------------------------------------------------------------------
  // COMMENT NODE
  // ---------------------------------------------------------------------------
  if VisualKind = nvComment then
  begin
    if Selected then
    begin
      Canvas.Pen.Color := clRed;
      Canvas.Pen.Width := 3;
    end
    else if Highlighted then
    begin
      Canvas.Pen.Color := clAqua;
      Canvas.Pen.Width := 2;
    end
    else if Hovered then
    begin
      Canvas.Pen.Color := clBlue;
      Canvas.Pen.Width := 2;
    end
    else
    begin
      Canvas.Pen.Color := HeaderColor;
      Canvas.Pen.Width := 2;
    end;

    Canvas.Brush.Color := BodyColor;
    Canvas.Rectangle(R);

    HeaderR := Rect(R.Left, R.Top, R.Right, R.Top + Max(18, Round(24 * Zoom)));
    Canvas.Brush.Color := HeaderColor;
    Canvas.FillRect(HeaderR);

    Canvas.Font.Color := clBlack;
    Canvas.Font.Size := Max(7, Round(10 * Zoom));
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(R.Left + 8, R.Top + 5, Title);

    if CommentText <> '' then
      Canvas.TextOut(R.Left + 8, HeaderR.Bottom + 6, CommentText);

    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Width := 1;
    Exit;
  end;

  // ---------------------------------------------------------------------------
  // NORMAL NODE
  // ---------------------------------------------------------------------------

  BodyR := R;
  Canvas.Brush.Color := BodyColor;
  Canvas.Pen.Style := psClear;
  Canvas.Rectangle(BodyR);

  HeaderR := Rect(R.Left, R.Top, R.Right, R.Top + HeaderH);
  Canvas.Brush.Color := HeaderColor;
  Canvas.Pen.Style := psClear;
  Canvas.Rectangle(HeaderR);

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psSolid;

  if Selected then
  begin
    Canvas.Pen.Color := clRed;
    Canvas.Pen.Width := 3;
  end
  else if Highlighted then
  begin
    Canvas.Pen.Color := clAqua;
    Canvas.Pen.Width := 3;
  end
  else if Hovered then
  begin
    Canvas.Pen.Color := clBlue;
    Canvas.Pen.Width := 1;
  end
  else
  begin
    Canvas.Pen.Color := clBlack;
    Canvas.Pen.Width := 1;
  end;

  Canvas.Rectangle(R);

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := clBlack;
  Canvas.Font.Size := Max(6, Round(10 * Zoom));
  Canvas.TextOut(R.Left + 8, R.Top + Max(4, Round(6 * Zoom)), Title);

  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 1;

  for i := 0 to InputCount - 1 do
  begin
    p := GetInput(i);
    if Collapsed and (p.LocalY > HeaderH / Zoom) then
      Continue;
    PX := R.Left;
    PY := R.Top + Round(p.LocalY * Zoom);

    if p.Kind = pkExec then
      Canvas.Brush.Color := clWhite
    else if p.PinType <> nil then
      Canvas.Brush.Color := p.PinType.Color
    else
      Canvas.Brush.Color := clLime;

    Canvas.Brush.Style := bsSolid;
    Canvas.Ellipse(PX - PinRadius, PY - PinRadius, PX + PinRadius, PY + PinRadius);

    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(PX + PinRadius + 6, PY - Canvas.TextHeight(p.Name) div 2, p.Name);
  end;

  for i := 0 to OutputCount - 1 do
  begin
    p := GetOutput(i);
    if Collapsed and (p.LocalY > HeaderH / Zoom) then
      Continue;
    PX := R.Right;
    PY := R.Top + Round(p.LocalY * Zoom);

    if p.Kind = pkExec then
      Canvas.Brush.Color := clWhite
    else if p.PinType <> nil then
      Canvas.Brush.Color := p.PinType.Color
    else
      Canvas.Brush.Color := clLime;

    Canvas.Brush.Style := bsSolid;
    Canvas.Ellipse(PX - PinRadius, PY - PinRadius, PX + PinRadius, PY + PinRadius);

    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(PX - Canvas.TextWidth(p.Name) - PinRadius - 6,
      PY - Canvas.TextHeight(p.Name) div 2, p.Name);
  end;

  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
end;

procedure TCustomNode.SaveToJSON(AObj: TJSONObject);
var
  PinsArr, ValuesArr: TJSONArray;
  PinObj, ValueObj, PinTypeObj: TJSONObject;
  i: integer;
  P: TNodePin;
  V: TNodeValue;
begin
  if AObj = nil then Exit;

  AObj.Add('id', Id);
  AObj.Add('type', NodeType);
  AObj.Add('title', Title);
  AObj.Add('x', X);
  AObj.Add('y', Y);
  AObj.Add('width', Width);
  AObj.Add('height', Height);
  AObj.Add('headerColor', integer(HeaderColor));
  AObj.Add('bodyColor', integer(BodyColor));
  AObj.Add('visualKind', Ord(VisualKind));
  AObj.Add('commentText', CommentText);
  AObj.Add('collapsed', Collapsed);
  AObj.Add('zOrder', ZOrder);

  // === PINS ===
  PinsArr := TJSONArray.Create;
  for i := 0 to InputCount - 1 do
  begin
    P := GetInput(i);
    PinObj := TJSONObject.Create;

    PinObj.Add('id', P.Id);
    PinObj.Add('name', P.Name);
    PinObj.Add('displayName', P.DisplayName);
    PinObj.Add('kind', PinKindToStr(P.Kind));
    PinObj.Add('direction', PinDirectionToStr(P.Direction));
    PinObj.Add('dataType', P.DataType);
    PinObj.Add('localY', P.LocalY);

    PinObj.Add('isRequired', P.IsRequired);
    PinObj.Add('defaultValue', P.DefaultValue);
    PinObj.Add('tooltip', P.Tooltip);
    PinObj.Add('hidden', P.Hidden);
    PinObj.Add('advanced', P.Advanced);
    PinObj.Add('allowMultipleConnections', P.AllowMultipleConnections);
    PinObj.Add('sortIndex', P.SortIndex);

    if P.PinType <> nil then
    begin
      PinTypeObj := TJSONObject.Create;
      P.PinType.SaveToJSON(PinTypeObj);
      PinObj.Add('pinType', PinTypeObj);
    end;

    PinsArr.Add(PinObj);
  end;

  for i := 0 to OutputCount - 1 do
  begin
    P := GetOutput(i);
    PinObj := TJSONObject.Create;

    PinObj.Add('id', P.Id);
    PinObj.Add('name', P.Name);
    PinObj.Add('displayName', P.DisplayName);
    PinObj.Add('kind', PinKindToStr(P.Kind));
    PinObj.Add('direction', PinDirectionToStr(P.Direction));
    PinObj.Add('dataType', P.DataType);
    PinObj.Add('localY', P.LocalY);
    PinObj.Add('allowMultipleConnections', P.AllowMultipleConnections);
    PinObj.Add('sortIndex', P.SortIndex);

    if P.PinType <> nil then
    begin
      PinTypeObj := TJSONObject.Create;
      P.PinType.SaveToJSON(PinTypeObj);
      PinObj.Add('pinType', PinTypeObj);
    end;

    PinsArr.Add(PinObj);
  end;

  AObj.Add('pins', PinsArr);

  // === VALUES ===
  ValuesArr := TJSONArray.Create;
  for i := 0 to ValueCount - 1 do
  begin
    V := GetValue(i);
    ValueObj := TJSONObject.Create;
    V.SaveToJSON(ValueObj);
    ValuesArr.Add(ValueObj);
  end;
  AObj.Add('values', ValuesArr);
end;

procedure TCustomNode.LoadFromJSON(AObj: TJSONObject);
var
  PinsArr, ValuesArr: TJSONArray;
  PinObj, PinTypeObj, ValueObj: TJSONObject;
  i: integer;
  P: TNodePin;
  V: TNodeValue;
  Dir: TPinDirection;
  Kind: TPinKind;
begin
  if AObj = nil then Exit;

  Id := AObj.Get('id', Id);
  NodeType := AObj.Get('type', NodeType);
  Title := AObj.Get('title', Title);
  X := AObj.Get('x', X);
  Y := AObj.Get('y', Y);
  Width := AObj.Get('width', Width);
  Height := AObj.Get('height', Height);
  HeaderColor := TColor(AObj.Get('headerColor', integer(HeaderColor)));
  BodyColor := TColor(AObj.Get('bodyColor', integer(BodyColor)));

  VisualKind := TNodeVisualKind(AObj.Get('visualKind', Ord(nvNormal)));
  CommentText := AObj.Get('commentText', CommentText);
  Collapsed := AObj.Get('collapsed', False);
  ZOrder := AObj.Get('zOrder', 0);

  // Pins
  ClearPins;
  PinsArr := AObj.Arrays['pins'];
  if PinsArr <> nil then
  begin
    for i := 0 to PinsArr.Count - 1 do
    begin
      PinObj := PinsArr.Objects[i];

      Dir := StrToPinDirection(PinObj.Get('direction', 'input'));
      Kind := StrToPinKind(PinObj.Get('kind', 'data'));

      P := TNodePin.Create(PinObj.Get('name', ''), Dir, Kind, PinObj.Get('localY', 40));

      P.Id := PinObj.Get('id', P.Id);
      P.DisplayName := PinObj.Get('displayName', P.Name);
      P.DataType := PinObj.Get('dataType', '');
      P.SetTypeId(P.DataType);

      PinTypeObj := PinObj.Objects['pinType'];
      if PinTypeObj <> nil then
        P.PinType.LoadFromJSON(PinTypeObj);

      P.IsRequired := PinObj.Get('isRequired', False);
      P.DefaultValue := PinObj.Get('defaultValue', '');
      P.Tooltip := PinObj.Get('tooltip', '');
      P.Hidden := PinObj.Get('hidden', False);
      P.Advanced := PinObj.Get('advanced', False);
      P.AllowMultipleConnections :=
        PinObj.Get('allowMultipleConnections', Dir = pdOutput);
      P.SortIndex := PinObj.Get('sortIndex', 0);

      P.OwnerNode := Self;

      if Dir = pdInput then
        FInputs.Add(P)
      else
        FOutputs.Add(P);
    end;
  end
  else
    SetupPins;

  // Values
  ClearValues;
  ValuesArr := AObj.Arrays['values'];
  if ValuesArr <> nil then
  begin
    for i := 0 to ValuesArr.Count - 1 do
    begin
      ValueObj := ValuesArr.Objects[i];
      V := TNodeValue.Create;
      V.LoadFromJSON(ValueObj);
      FValues.Add(V);
    end;
  end;
end;

constructor TDefaultNode.Create(ATitle: string; AX, AY: single;
  AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'default';
end;

procedure TDefaultNode.SetupPins;
begin
  ClearPins;
  AddInput('In', 'float', pkData, 45);
  AddOutput('Out', 'float', pkData, 45);
end;

constructor TFloatNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'float';
  HeaderColor := clMoneyGreen;
end;

procedure TFloatNode.SetupPins;
var
  V: TNodeValue;
begin
  ClearPins;
  AddOutput('Value', 'float', pkData, 45);

  if FindValue('value') = nil then
  begin
    V := AddValue('value', nvkFloat);
    V.FloatValue := 0.0;
  end;
end;

constructor TAddNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'add';
  HeaderColor := $00D0A0FF;
end;

procedure TAddNode.SetupPins;
begin
  ClearPins;

  AddInput('A', 'float', pkData, 45);
  GetInput(InputCount - 1).IsRequired := True;

  AddInput('B', 'float', pkData, 75);
  GetInput(InputCount - 1).IsRequired := True;

  AddOutput('Result', 'float', pkData, 60);
end;

constructor TRerouteNode.Create(ATitle: string; AX, AY: single;
  AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, Max(28, AWidth), Max(28, AHeight));
  NodeType := 'reroute';
  VisualKind := nvReroute;
  Title := '';
  HeaderColor := clWhite;
  BodyColor := clWhite;
end;

procedure TRerouteNode.SetupPins;
begin
  ClearPins;
  AddInput('', 'any', pkData, Height div 2);
  AddOutput('', 'any', pkData, Height div 2);

  if InputCount > 0 then
    GetInput(0).AllowMultipleConnections := False;

  if OutputCount > 0 then
    GetOutput(0).AllowMultipleConnections := True;
end;

constructor TCommentNode.Create(ATitle: string; AX, AY: single;
  AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'comment';
  VisualKind := nvComment;
  HeaderColor := $00B0B0B0;
  BodyColor := $00FFFFCC;
  CommentText := 'Comment';
end;

procedure TCommentNode.SetupPins;
begin
  ClearPins;
end;

// =============================================================================
// TNodeDefinition
// =============================================================================

constructor TNodeDefinition.Create;
begin
  inherited Create;
  Tags := TStringList.Create;
  Version := 1;
  Hidden := False;
  Deprecated := False;
  Color := clNone;
end;

destructor TNodeDefinition.Destroy;
begin
  Tags.Free;
  inherited Destroy;
end;

function TNodeDefinition.MatchesFilter(const AFilter: string): boolean;
var
  F: string;
  i: integer;
begin
  F := UTF8LowerCase(Trim(AFilter));

  if F = '' then
    Exit(True);

  Result :=
    (Pos(F, UTF8LowerCase(NodeType)) > 0) or (Pos(F, UTF8LowerCase(Caption)) > 0) or
    (Pos(F, UTF8LowerCase(Category)) > 0) or (Pos(F, UTF8LowerCase(Description)) > 0);

  if Result then
    Exit;

  for i := 0 to Tags.Count - 1 do
    if Pos(F, UTF8LowerCase(Tags[i])) > 0 then
      Exit(True);
end;

// =============================================================================
// TNodeRegistry
// =============================================================================

constructor TNodeRegistry.Create;
begin
  inherited Create;
  FItems := TList.Create;
end;

destructor TNodeRegistry.Destroy;
var
  i: integer;
begin
  for i := 0 to FItems.Count - 1 do
    TObject(FItems[i]).Free;

  FItems.Free;
  inherited Destroy;
end;

procedure TNodeRegistry.RegisterNode(const ANodeType, ACaption: string;
  AClass: TCustomNodeClass);
begin
  RegisterNodeEx(ANodeType, ACaption, '', '', '', AClass);
end;

procedure TNodeRegistry.RegisterNodeEx(
  const ANodeType, ACaption, ACategory, ADescription, ATags: string;
  AClass: TCustomNodeClass; AColor: TColor; AHidden: boolean;
  ADeprecated: boolean; AVersion: integer);
var
  It: TNodeDefinition;
  TagsSL: TStringList;
  i: integer;
begin
  if FindItem(ANodeType) <> nil then
    Exit;

  It := TNodeDefinition.Create;
  It.NodeType := ANodeType;
  It.Caption := ACaption;
  It.Category := ACategory;
  It.Description := ADescription;
  It.NodeClass := AClass;
  It.Color := AColor;
  It.Hidden := AHidden;
  It.Deprecated := ADeprecated;
  It.Version := AVersion;

  TagsSL := TStringList.Create;
  try
    TagsSL.Delimiter := ',';
    TagsSL.StrictDelimiter := True;
    TagsSL.DelimitedText := ATags;

    for i := 0 to TagsSL.Count - 1 do
      if Trim(TagsSL[i]) <> '' then
        It.Tags.Add(Trim(TagsSL[i]));
  finally
    TagsSL.Free;
  end;

  FItems.Add(It);
end;

function TNodeRegistry.FindItem(const ANodeType: string): TNodeRegistryItem;
var
  i: integer;
  It: TNodeRegistryItem;
begin
  Result := nil;

  for i := 0 to FItems.Count - 1 do
  begin
    It := TNodeRegistryItem(FItems[i]);
    if SameText(It.NodeType, ANodeType) then
      Exit(It);
  end;
end;

function TNodeRegistry.CreateNode(const ANodeType: string; AX, AY: single): TCustomNode;
var
  It: TNodeRegistryItem;
begin
  It := FindItem(ANodeType);

  if It <> nil then
  begin
    Result := It.NodeClass.Create(It.Caption, AX, AY);
    Result.NodeType := It.NodeType;
    Result.SetupPins;
  end
  else
  begin
    Result := TDefaultNode.Create('Unknown: ' + ANodeType, AX, AY);
    Result.NodeType := ANodeType;
    Result.SetupPins;
  end;
end;

function TNodeRegistry.Count: integer;
begin
  Result := FItems.Count;
end;

function TNodeRegistry.Item(Index: integer): TNodeRegistryItem;
begin
  if (Index >= 0) and (Index < FItems.Count) then
    Result := TNodeRegistryItem(FItems[Index])
  else
    Result := nil;
end;

// =============================================================================
// TNodeGraph
// =============================================================================

constructor TNodeGraph.Create;
begin
  inherited Create;
  FNodes := TCustomNodeList.Create(True); // Owns objects
  FLinks := TNodeLinkList.Create(True);
  FRegistry := TNodeRegistry.Create;
  FUndoStack := TGraphCommandList.Create(True);
  FRedoStack := TGraphCommandList.Create(True);

  FRegistry.RegisterNodeEx('default', 'Default Node', 'Basic',
    'Generic test node.', 'default,test', TDefaultNode);

  FRegistry.RegisterNodeEx('float', 'Float Value', 'Values',
    'Constant float value.', 'float,number,value,const', TFloatNode);

  FRegistry.RegisterNodeEx('add', 'Add Float', 'Math',
    'Adds two float values.', 'add,plus,math,float', TAddNode);

  FRegistry.RegisterNodeEx('reroute', 'Reroute', 'Utility',
    'Reroute connection wire.', 'reroute,wire', TRerouteNode);

  FRegistry.RegisterNodeEx('comment', 'Comment / Frame', 'Utility',
    'Visual comment frame.', 'comment,frame,group', TCommentNode);
end;

destructor TNodeGraph.Destroy;
begin
  Clear;
  ClearUndoRedo;
  FUndoStack.Free;
  FRedoStack.Free;
  FRegistry.Free;
  FLinks.Free;
  FNodes.Free;
  inherited Destroy;
end;

procedure TNodeGraph.BeginUpdate;
begin
  Inc(FUpdateLock);
end;

procedure TNodeGraph.EndUpdate;
begin
  if FUpdateLock > 0 then
    Dec(FUpdateLock);

  if FUpdateLock = 0 then
    DoGraphChanged;
end;

procedure TNodeGraph.AddNode(ANode: TCustomNode);
begin
  if ANode = nil then
    Exit;

  if FNodes.IndexOf(ANode) >= 0 then
    Exit;

  if ANode.ZOrder = 0 then
    ANode.ZOrder := NextZOrder;

  FNodes.Add(ANode);

  if Assigned(FOnNodeAdded) then
    FOnNodeAdded(Self, ANode);

  DoGraphChanged;
end;

function TNodeGraph.DetachNode(ANode: TCustomNode): boolean;
var
  i: integer;
  L: TNodeLink;
begin
  Result := False;

  if ANode = nil then
    Exit;

  if FNodes.IndexOf(ANode) < 0 then
    Exit;

  for i := FLinks.Count - 1 downto 0 do
  begin
    L := FLinks[i];

    if (((L.FromPin <> nil) and (L.FromPin.OwnerNode = ANode)) or
      ((L.ToPin <> nil) and (L.ToPin.OwnerNode = ANode))) then
    begin
      if Assigned(FOnLinkRemoved) then
        FOnLinkRemoved(Self, L);

      FLinks.Delete(i);
    end;
  end;

  if Assigned(FOnNodeRemoved) then
    FOnNodeRemoved(Self, ANode);

  FNodes.Extract(ANode);

  Result := True;
  DoGraphChanged;
end;

procedure TNodeGraph.RemoveNode(ANode: TCustomNode);
var
  i: integer;
  L: TNodeLink;
begin
  if ANode = nil then
    Exit;

  for i := FLinks.Count - 1 downto 0 do
  begin
    L := FLinks[i];

    if (((L.FromPin <> nil) and (L.FromPin.OwnerNode = ANode)) or
      ((L.ToPin <> nil) and (L.ToPin.OwnerNode = ANode))) then
    begin
      if Assigned(FOnLinkRemoved) then
        FOnLinkRemoved(Self, L);

      FLinks.Delete(i);
    end;
  end;

  if Assigned(FOnNodeRemoved) then
    FOnNodeRemoved(Self, ANode);

  FNodes.Remove(ANode);

  DoGraphChanged;
end;

procedure TNodeGraph.AddLink(ALink: TNodeLink);
var
  OutPin, InPin: TNodePin;
begin
  if ALink = nil then
    Exit;

  if (ALink.FromPin = nil) or (ALink.ToPin = nil) then
  begin
    ALink.Free;
    Exit;
  end;

  if not CanConnect(ALink.FromPin, ALink.ToPin) then
  begin
    ALink.Free;
    Exit;
  end;

  if ALink.FromPin.Direction = pdOutput then
  begin
    OutPin := ALink.FromPin;
    InPin := ALink.ToPin;
  end
  else
  begin
    OutPin := ALink.ToPin;
    InPin := ALink.FromPin;
  end;

  ALink.FromPin := OutPin;
  ALink.ToPin := InPin;

  if LinkExists(OutPin, InPin) then
  begin
    ALink.Free;
    Exit;
  end;

  if not InPin.AllowMultipleConnections then
    RemoveLinksToInput(InPin);

  FLinks.Add(ALink);

  if Assigned(FOnLinkAdded) then
    FOnLinkAdded(Self, ALink);

  DoGraphChanged;
end;

procedure TNodeGraph.RemoveLink(ALink: TNodeLink);
begin
  if ALink = nil then
    Exit;

  if Assigned(FOnLinkRemoved) then
    FOnLinkRemoved(Self, ALink);

  if FLinks.Remove(ALink) >= 0 then
    DoGraphChanged;
end;

function TNodeGraph.CheckInvariants(AErrors: TStrings): boolean;

  procedure AddError(const S: string);
  begin
    Result := False;
    if AErrors <> nil then
      AErrors.Add(S);
  end;

var
  i, j: integer;
  N: TCustomNode;
  P: TNodePin;
  L: TNodeLink;
  NodeIds: TStringList;
  PinIds: TStringList;
begin
  Result := True;

  if AErrors <> nil then
    AErrors.Clear;

  NodeIds := TStringList.Create;
  PinIds := TStringList.Create;
  try
    NodeIds.CaseSensitive := False;
    PinIds.CaseSensitive := False;

    for i := 0 to FNodes.Count - 1 do
    begin
      N := FNodes[i];

      if N = nil then
      begin
        AddError('Node list contains nil node.');
        Continue;
      end;

      if N.Id = '' then
        AddError('Node "' + N.Title + '" has empty Id.');

      if NodeIds.IndexOf(N.Id) >= 0 then
        AddError('Duplicate node Id: ' + N.Id)
      else
        NodeIds.Add(N.Id);

      for j := 0 to N.InputCount - 1 do
      begin
        P := N.GetInput(j);

        if P = nil then
        begin
          AddError('Node "' + N.Title + '" contains nil input pin.');
          Continue;
        end;

        if P.OwnerNode <> N then
          AddError('Input pin "' + P.Name + '" has invalid OwnerNode.');

        if P.Direction <> pdInput then
          AddError('Pin "' + P.Name + '" in input list has non-input direction.');

        if P.SortIndex <> j then
          AddError('Input pin "' + P.Name + '" has invalid SortIndex.');

        if P.Id = '' then
          AddError('Input pin "' + P.Name + '" has empty Id.');

        if PinIds.IndexOf(P.Id) >= 0 then
          AddError('Duplicate pin Id: ' + P.Id)
        else
          PinIds.Add(P.Id);
      end;

      for j := 0 to N.OutputCount - 1 do
      begin
        P := N.GetOutput(j);

        if P = nil then
        begin
          AddError('Node "' + N.Title + '" contains nil output pin.');
          Continue;
        end;

        if P.OwnerNode <> N then
          AddError('Output pin "' + P.Name + '" has invalid OwnerNode.');

        if P.Direction <> pdOutput then
          AddError('Pin "' + P.Name + '" in output list has non-output direction.');

        if P.SortIndex <> j then
          AddError('Output pin "' + P.Name + '" has invalid SortIndex.');

        if P.Id = '' then
          AddError('Output pin "' + P.Name + '" has empty Id.');

        if PinIds.IndexOf(P.Id) >= 0 then
          AddError('Duplicate pin Id: ' + P.Id)
        else
          PinIds.Add(P.Id);
      end;
    end;

    for i := 0 to FLinks.Count - 1 do
    begin
      L := FLinks[i];

      if L = nil then
      begin
        AddError('Link list contains nil link.');
        Continue;
      end;

      if L.FromPin = nil then
        AddError('Link has nil FromPin.');

      if L.ToPin = nil then
        AddError('Link has nil ToPin.');

      if (L.FromPin <> nil) and (L.FromPin.Direction <> pdOutput) then
        AddError('Link FromPin is not output.');

      if (L.ToPin <> nil) and (L.ToPin.Direction <> pdInput) then
        AddError('Link ToPin is not input.');

      if (L.FromPin <> nil) and ((L.FromPin.OwnerNode = nil) or
        (FNodes.IndexOf(L.FromPin.OwnerNode) < 0)) then
        AddError('Link FromPin points to pin outside graph.');

      if (L.ToPin <> nil) and ((L.ToPin.OwnerNode = nil) or
        (FNodes.IndexOf(L.ToPin.OwnerNode) < 0)) then
        AddError('Link ToPin points to pin outside graph.');

      if (L.FromPin <> nil) and (L.ToPin <> nil) and
        (not CanConnect(L.FromPin, L.ToPin)) then
        AddError('Link violates CanConnect rule.');
    end;
  finally
    PinIds.Free;
    NodeIds.Free;
  end;
end;

procedure TNodeGraph.NormalizeGraph;
var
  i, j: integer;
  N: TCustomNode;
  P: TNodePin;
  L: TNodeLink;
  UsedNodeIds: TStringList;
  UsedPinIds: TStringList;
begin
  UsedNodeIds := TStringList.Create;
  UsedPinIds := TStringList.Create;
  try
    UsedNodeIds.CaseSensitive := False;
    UsedPinIds.CaseSensitive := False;

    for i := 0 to FNodes.Count - 1 do
    begin
      N := FNodes[i];

      if (N.Id = '') or (UsedNodeIds.IndexOf(N.Id) >= 0) then
        N.Id := NewId;

      UsedNodeIds.Add(N.Id);

      N.ReindexPins;

      for j := 0 to N.InputCount - 1 do
      begin
        P := N.GetInput(j);
        P.OwnerNode := N;
        P.Direction := pdInput;

        if (P.Id = '') or (UsedPinIds.IndexOf(P.Id) >= 0) then
          P.Id := NewId;

        UsedPinIds.Add(P.Id);
      end;

      for j := 0 to N.OutputCount - 1 do
      begin
        P := N.GetOutput(j);
        P.OwnerNode := N;
        P.Direction := pdOutput;

        if (P.Id = '') or (UsedPinIds.IndexOf(P.Id) >= 0) then
          P.Id := NewId;

        UsedPinIds.Add(P.Id);
      end;
    end;

    for i := FLinks.Count - 1 downto 0 do
    begin
      L := FLinks[i];

      if (L = nil) or (L.FromPin = nil) or (L.ToPin = nil) or
        (L.FromPin.OwnerNode = nil) or (L.ToPin.OwnerNode = nil) then
      begin
        FLinks.Delete(i);
        Continue;
      end;

      if (FNodes.IndexOf(L.FromPin.OwnerNode) < 0) or
        (FNodes.IndexOf(L.ToPin.OwnerNode) < 0) then
      begin
        FLinks.Delete(i);
        Continue;
      end;

      if (L.FromPin.Direction = pdInput) and (L.ToPin.Direction = pdOutput) then
      begin
        P := L.FromPin;
        L.FromPin := L.ToPin;
        L.ToPin := P;
      end;

      if (L.FromPin.Direction <> pdOutput) or (L.ToPin.Direction <> pdInput) or
        (not CanConnect(L.FromPin, L.ToPin)) then
      begin
        FLinks.Delete(i);
        Continue;
      end;
    end;
  finally
    UsedPinIds.Free;
    UsedNodeIds.Free;
  end;
end;

function TNodeGraph.IsNodeIdUnique(const AId: string; AExcept: TCustomNode): boolean;
var
  i: integer;
  N: TCustomNode;
begin
  Result := True;

  if AId = '' then
    Exit(False);

  for i := 0 to FNodes.Count - 1 do
  begin
    N := FNodes[i];

    if N = AExcept then
      Continue;

    if SameText(N.Id, AId) then
      Exit(False);
  end;
end;

function TNodeGraph.IsPinIdUnique(const AId: string; AExcept: TNodePin): boolean;
var
  i, j: integer;
  N: TCustomNode;
  P: TNodePin;
begin
  Result := True;

  if AId = '' then
    Exit(False);

  for i := 0 to FNodes.Count - 1 do
  begin
    N := FNodes[i];

    for j := 0 to N.InputCount - 1 do
    begin
      P := N.GetInput(j);

      if P = AExcept then
        Continue;

      if SameText(P.Id, AId) then
        Exit(False);
    end;

    for j := 0 to N.OutputCount - 1 do
    begin
      P := N.GetOutput(j);

      if P = AExcept then
        Continue;

      if SameText(P.Id, AId) then
        Exit(False);
    end;
  end;
end;

function TNodeGraph.FindNodeById(const AId: string): TCustomNode;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to FNodes.Count - 1 do
    if TCustomNode(FNodes[i]).Id = AId then
      Exit(TCustomNode(FNodes[i]));
end;

function TNodeGraph.FindPinById(const AId: string): TNodePin;
var
  i: integer;
  N: TCustomNode;
begin
  Result := nil;
  for i := 0 to FNodes.Count - 1 do
  begin
    N := TCustomNode(FNodes[i]);
    Result := N.FindPinById(AId);
    if Result <> nil then Exit;
  end;
end;

function TNodeGraph.CanConnect(P1, P2: TNodePin): boolean;
var
  OutPin, InPin: TNodePin;
begin
  Result := False;

  if not Assigned(P1) or not Assigned(P2) then
    Exit;

  if P1 = P2 then
    Exit;

  if P1.Direction = P2.Direction then
    Exit;

  if P1.OwnerNode = nil then
    Exit;

  if P2.OwnerNode = nil then
    Exit;

  if P1.OwnerNode = P2.OwnerNode then
    Exit;

  if P1.Kind <> P2.Kind then
    Exit;

  if P1.Direction = pdOutput then
  begin
    OutPin := P1;
    InPin := P2;
  end
  else
  begin
    OutPin := P2;
    InPin := P1;
  end;

  if OutPin.Direction <> pdOutput then
    Exit;

  if InPin.Direction <> pdInput then
    Exit;

  if OutPin.Kind = pkExec then
  begin
    Result := True;
    Exit;
  end;

  if (OutPin.PinType <> nil) and (InPin.PinType <> nil) then
  begin
    Result := OutPin.PinType.IsCompatibleWith(InPin.PinType);
    Exit;
  end;

  Result :=
    SameText(OutPin.DataType, InPin.DataType) or SameText(OutPin.DataType, 'any') or
    SameText(InPin.DataType, 'any') or (OutPin.DataType = '') or
    (InPin.DataType = '');
end;

function TNodeGraph.LinkExists(FromPin, ToPin: TNodePin): boolean;
var
  i: integer;
  L: TNodeLink;
  AFrom, ATo: TNodePin;
begin
  Result := False;

  if (FromPin = nil) or (ToPin = nil) then
    Exit;

  if FromPin.Direction = pdOutput then
  begin
    AFrom := FromPin;
    ATo := ToPin;
  end
  else
  begin
    AFrom := ToPin;
    ATo := FromPin;
  end;

  for i := 0 to FLinks.Count - 1 do
  begin
    L := TNodeLink(FLinks[i]);
    if (L.FromPin = AFrom) and (L.ToPin = ATo) then
      Exit(True);
  end;
end;

procedure TNodeGraph.DoGraphChanged;
begin
  if FUpdateLock > 0 then
    Exit;

  if Assigned(FOnGraphChanged) then
    FOnGraphChanged(Self);
end;

procedure TNodeGraph.RemoveLinksToInput(APin: TNodePin);
var
  i: integer;
  L: TNodeLink;
begin
  if APin = nil then Exit;
  for i := FLinks.Count - 1 downto 0 do
    if FLinks[i].ToPin = APin then
      RemoveLink(FLinks[i]);
end;


function TNodeGraph.PinHasIncomingLink(APin: TNodePin): boolean;
var
  i: integer;
  L: TNodeLink;
begin
  Result := False;

  if APin = nil then
    Exit;

  for i := 0 to FLinks.Count - 1 do
  begin
    L := TNodeLink(FLinks[i]);
    if L.ToPin = APin then
      Exit(True);
  end;
end;

function TNodeGraph.PinHasOutgoingLink(APin: TNodePin): boolean;
var
  i: integer;
  L: TNodeLink;
begin
  Result := False;

  if APin = nil then
    Exit;

  for i := 0 to FLinks.Count - 1 do
  begin
    L := TNodeLink(FLinks[i]);
    if L.FromPin = APin then
      Exit(True);
  end;
end;

procedure TNodeGraph.PushExecutedCommand(ACommand: TGraphCommand);
begin
  if ACommand = nil then
    Exit;

  if FUndoLock then
  begin
    ACommand.Free;
    Exit;
  end;

  FUndoStack.Add(ACommand);
  FRedoStack.Clear;

  while FUndoStack.Count > 100 do
    FUndoStack.Delete(0);

  DoGraphChanged;
end;

procedure TNodeGraph.Clear;
begin
  FLinks.Clear;
  FNodes.Clear;
  DoGraphChanged;
end;

procedure TNodeGraph.ClearUndoRedo;
begin
  FUndoStack.Clear;
  FRedoStack.Clear;
end;

procedure TNodeGraph.ExecuteCommand(ACommand: TGraphCommand);
var
  i: integer;
begin
  if ACommand = nil then
    Exit;

  if FUndoLock then
  begin
    ACommand.DoExecute;
    ACommand.Free;
    Exit;
  end;

  FExecutingCommand := True;
  try
    ACommand.DoExecute;
  finally
    FExecutingCommand := False;
  end;

  FUndoStack.Add(ACommand);
  FRedoStack.Clear;

  while FUndoStack.Count > 100 do
    FUndoStack.Delete(0);

  DoGraphChanged;
end;

procedure TNodeGraph.PushUndoSnapshot;
var
  Obj: TJSONObject;
  Cmd: TJSONSnapshotCommand;
begin
  if FUndoLock then
    Exit;

  Obj := SaveGraphToJSON;
  try
    Cmd := TJSONSnapshotCommand.Create(Self, Obj.AsJSON, Obj.AsJSON, 'Snapshot');
    FUndoStack.Add(Cmd);
  finally
    Obj.Free;
  end;

  while FUndoStack.Count > 100 do
  begin
    TObject(FUndoStack[0]).Free;
    FUndoStack.Delete(0);
  end;
end;

function TNodeGraph.CaptureJSONText: string;
var
  Obj: TJSONObject;
begin
  Obj := SaveGraphToJSON;
  try
    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

procedure TNodeGraph.ExecuteJSONSnapshotCommand(
  const ABeforeJSON, AAfterJSON, ADescription: string);
begin
  if ABeforeJSON = AAfterJSON then
    Exit;

  PushExecutedCommand(TJSONSnapshotCommand.Create(Self, ABeforeJSON,
    AAfterJSON, ADescription));
end;

function TNodeGraph.NextZOrder: integer;
var
  i: integer;
  N: TCustomNode;
begin
  Result := 1;

  for i := 0 to FNodes.Count - 1 do
  begin
    N := TCustomNode(FNodes[i]);
    Result := Max(Result, N.ZOrder + 1);
  end;
end;

procedure TNodeGraph.BringNodeToFront(ANode: TCustomNode);
begin
  if ANode = nil then
    Exit;

  ANode.ZOrder := NextZOrder;
  DoGraphChanged;
end;

procedure TNodeGraph.SendNodeToBack(ANode: TCustomNode);
var
  i: integer;
  N: TCustomNode;
begin
  if ANode = nil then
    Exit;

  ANode.ZOrder := 1;

  for i := 0 to FNodes.Count - 1 do
  begin
    N := TCustomNode(FNodes[i]);
    if N <> ANode then
      Inc(N.ZOrder);
  end;

  DoGraphChanged;
end;

procedure TNodeGraph.Undo;
var
  Cmd: TGraphCommand;
begin
  if FUndoStack.Count = 0 then
    Exit;

  FUndoLock := True;
  try
    Cmd := TGraphCommand(FUndoStack.Extract(FUndoStack[FUndoStack.Count - 1]));
    Cmd.Undo;
    FRedoStack.Add(Cmd);
  finally
    FUndoLock := False;
  end;

  DoGraphChanged;
end;

procedure TNodeGraph.Redo;
var
  Cmd: TGraphCommand;
begin
  if FRedoStack.Count = 0 then
    Exit;

  FUndoLock := True;
  try
    Cmd := TGraphCommand(FRedoStack.Extract(FRedoStack[FRedoStack.Count - 1]));
    Cmd.DoExecute;
    FUndoStack.Add(Cmd);
  finally
    FUndoLock := False;
  end;

  DoGraphChanged;
end;

function TNodeGraph.SaveGraphToJSON: TJSONObject;
var
  NodesArr, LinksArr: TJSONArray;
  NodeObj, LinkObj: TJSONObject;
  i: integer;
  N: TCustomNode;
  L: TNodeLink;
begin
  Result := TJSONObject.Create;
  try
    NodesArr := TJSONArray.Create;
    for i := 0 to FNodes.Count - 1 do
    begin
      N := TCustomNode(FNodes[i]);
      NodeObj := TJSONObject.Create;
      N.SaveToJSON(NodeObj);
      NodesArr.Add(NodeObj);
    end;
    Result.Add('nodes', NodesArr);

    LinksArr := TJSONArray.Create;
    for i := 0 to FLinks.Count - 1 do
    begin
      L := TNodeLink(FLinks[i]);
      if (L.FromPin = nil) or (L.ToPin = nil) then Continue;

      LinkObj := TJSONObject.Create;
      LinkObj.Add('id', L.Id);
      LinkObj.Add('fromPinId', L.FromPin.Id);
      LinkObj.Add('toPinId', L.ToPin.Id);
      LinksArr.Add(LinkObj);
    end;
    Result.Add('links', LinksArr);
  except
    Result.Free;
    raise;
  end;
end;

procedure TNodeGraph.LoadGraphFromJSON(AObj: TJSONObject);
var
  NodesArr, LinksArr: TJSONArray;
  NodeObj, LinkObj: TJSONObject;
  i: integer;
  N: TCustomNode;
  L: TNodeLink;
  FromPin, ToPin: TNodePin;
  NodeType: string;
begin
  BeginUpdate;
  try
    Clear;

    NodesArr := AObj.Arrays['nodes'];
    if NodesArr <> nil then
    begin
      for i := 0 to NodesArr.Count - 1 do
      begin
        NodeObj := NodesArr.Objects[i];
        NodeType := NodeObj.Get('type', 'default');

        N := FRegistry.CreateNode(NodeType, NodeObj.Get('x', 0.0), NodeObj.Get('y', 0.0));
        N.LoadFromJSON(NodeObj);
        FNodes.Add(N);
      end;
    end;

    LinksArr := AObj.Arrays['links'];
    if LinksArr <> nil then
    begin
      for i := 0 to LinksArr.Count - 1 do
      begin
        LinkObj := LinksArr.Objects[i];
        FromPin := FindPinById(LinkObj.Get('fromPinId', ''));
        ToPin := FindPinById(LinkObj.Get('toPinId', ''));

        if (FromPin <> nil) and (ToPin <> nil) and CanConnect(FromPin, ToPin) then
        begin
          L := TNodeLink.Create(FromPin, ToPin);
          L.Id := LinkObj.Get('id', L.Id);
          FLinks.Add(L);
        end;
      end;
      NormalizeGraph;
    end;

  finally
    EndUpdate;
    DoGraphChanged;
  end;
end;

function TNodeGraph.ValidateGraph: boolean;
var
  Issues: TList;
  i: integer;
begin
  Issues := TList.Create;
  try
    Result := ValidateGraphIssues(Issues);
    for i := 0 to Issues.Count - 1 do
      TObject(Issues[i]).Free;
  finally
    Issues.Free;
  end;
end;

function TNodeGraph.ValidateGraphIssues(AIssues: TList): boolean;

  procedure AddIssue(AKind: TGraphValidationIssueKind; const AMsg: string;
    ANode: TCustomNode; ALink: TNodeLink);
  var
    Issue: TGraphValidationIssue;
  begin
    Issue := TGraphValidationIssue.Create;
    Issue.Kind := AKind;
    Issue.MessageText := AMsg;
    Issue.Node := ANode;
    Issue.Link := ALink;

    if AIssues <> nil then
      AIssues.Add(Issue)
    else
      Issue.Free;
  end;

var
  i, j: integer;
  N: TCustomNode;
  P: TNodePin;
  L: TNodeLink;
begin
  Result := True;

  for i := 0 to FLinks.Count - 1 do
  begin
    L := TNodeLink(FLinks[i]);

    if (L.FromPin = nil) or (L.ToPin = nil) then
    begin
      AddIssue(gviError, 'Broken link: nil pin.', nil, L);
      Result := False;
      Continue;
    end;

    if not CanConnect(L.FromPin, L.ToPin) then
    begin
      AddIssue(gviError, 'Invalid link type/direction.', nil, L);
      Result := False;
    end;
  end;

  for i := 0 to FNodes.Count - 1 do
  begin
    N := TCustomNode(FNodes[i]);

    for j := 0 to N.InputCount - 1 do
    begin
      P := N.GetInput(j);

      if P.IsRequired then
      begin
        if not PinHasIncomingLink(P) and (Trim(P.DefaultValue) = '') then
        begin
          AddIssue(
            gviWarning,
            'Required input "' + P.Name + '" is not connected on node "' +
            N.Title + '".',
            N,
            nil
            );
        end;
      end;
    end;
  end;

  if HasCycle then
  begin
    AddIssue(gviError, 'Graph contains cycle.', nil, nil);
    Result := False;
  end;
end;

function TNodeGraph.HasCycle: boolean;
var
  Visited: TList;
  Stack: TList;

  function Visit(N: TCustomNode): boolean;
  var
    i: integer;
    L: TNodeLink;
    NextNode: TCustomNode;
  begin
    Result := False;

    if Stack.IndexOf(N) >= 0 then
      Exit(True);

    if Visited.IndexOf(N) >= 0 then
      Exit(False);

    if N.VisualKind = nvComment then
      Exit(False);

    Visited.Add(N);
    Stack.Add(N);

    for i := 0 to FLinks.Count - 1 do
    begin
      L := TNodeLink(FLinks[i]);

      if (L.FromPin <> nil) and (L.ToPin <> nil) and
        (L.FromPin.OwnerNode = N) then
      begin
        NextNode := L.ToPin.OwnerNode;

        if (NextNode <> nil) and (NextNode.VisualKind <> nvComment) then
        begin
          if Visit(NextNode) then
            Exit(True);
        end;
      end;
    end;

    Stack.Remove(N);
  end;

var
  i: integer;
begin
  Result := False;

  Visited := TList.Create;
  Stack := TList.Create;
  try
    for i := 0 to FNodes.Count - 1 do
    begin
      if Visit(TCustomNode(FNodes[i])) then
        Exit(True);
    end;
  finally
    Stack.Free;
    Visited.Free;
  end;
end;

function TNodeGraph.CreateRerouteForLink(ALink: TNodeLink; AX, AY: single): TCustomNode;
var
  N: TCustomNode;
  OldFrom: TNodePin;
  OldTo: TNodePin;
begin
  Result := nil;

  if (ALink = nil) or (ALink.FromPin = nil) or (ALink.ToPin = nil) then
    Exit;

  OldFrom := ALink.FromPin;
  OldTo := ALink.ToPin;

  N := FRegistry.CreateNode('reroute', AX, AY);

  if (N.InputCount > 0) and (N.OutputCount > 0) then
  begin
    N.GetInput(0).Kind := OldFrom.Kind;
    N.GetInput(0).DataType := OldFrom.DataType;
    N.GetInput(0).SetTypeId(OldFrom.DataType);

    if OldFrom.PinType <> nil then
    begin
      N.GetInput(0).PinType.Free;
      N.GetInput(0).PinType := OldFrom.PinType.Clone;
    end;

    N.GetOutput(0).Kind := OldFrom.Kind;
    N.GetOutput(0).DataType := OldFrom.DataType;
    N.GetOutput(0).SetTypeId(OldFrom.DataType);

    if OldFrom.PinType <> nil then
    begin
      N.GetOutput(0).PinType.Free;
      N.GetOutput(0).PinType := OldFrom.PinType.Clone;
    end;
  end;

  RemoveLink(ALink);
  AddNode(N);

  AddLink(TNodeLink.Create(OldFrom, N.GetInput(0)));
  AddLink(TNodeLink.Create(N.GetOutput(0), OldTo));

  Result := N;
end;

function TNodeGraph.GetCompatibleNodesForPin(APin: TNodePin): TStringList;
var
  i, j: integer;
  N: TCustomNode;
  RegItem: TNodeRegistryItem;
begin
  Result := TStringList.Create;
  for i := 0 to FRegistry.Count - 1 do
  begin
    RegItem := FRegistry.Item(i);
    Result.Add(RegItem.NodeType);
  end;
end;

function TNodeGraph.AddDynamicInputPin(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
var
  BeforeJSON, AfterJSON: string;
begin
  Result := nil;

  if ANode = nil then
    Exit;

  BeforeJSON := CaptureJSONText;
  Result := ANode.AddInputPin(AName, ADataType, AKind);
  AfterJSON := CaptureJSONText;

  ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Add input pin');
  DoGraphChanged;
end;

function TNodeGraph.AddDynamicOutputPin(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
var
  BeforeJSON, AfterJSON: string;
begin
  Result := nil;

  if ANode = nil then
    Exit;

  BeforeJSON := CaptureJSONText;
  Result := ANode.AddOutputPin(AName, ADataType, AKind);
  AfterJSON := CaptureJSONText;

  ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Add output pin');
  DoGraphChanged;
end;

function TNodeGraph.RemoveDynamicPin(APin: TNodePin): boolean;
var
  BeforeJSON, AfterJSON: string;
  N: TCustomNode;
  i: integer;
  L: TNodeLink;
begin
  Result := False;

  if APin = nil then
    Exit;

  N := APin.OwnerNode;
  if N = nil then
    Exit;

  BeforeJSON := CaptureJSONText;

  for i := FLinks.Count - 1 downto 0 do
  begin
    L := TNodeLink(FLinks[i]);
    if (L.FromPin = APin) or (L.ToPin = APin) then
      FLinks.Delete(i);
  end;

  Result := N.RemovePin(APin);

  AfterJSON := CaptureJSONText;
  ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Remove pin');

  DoGraphChanged;
end;

// =============================================================================
// Commands
// =============================================================================

constructor TGraphCommand.Create(AGraph: TNodeGraph; const ADescription: string);
begin
  inherited Create;
  FGraph := AGraph;
  FDescription := ADescription;
end;

destructor TGraphCommand.Destroy;
begin
  inherited Destroy;
end;

constructor TJSONSnapshotCommand.Create(AGraph: TNodeGraph;
  const ABeforeJSON, AAfterJSON: string; const ADescription: string);
begin
  inherited Create(AGraph, ADescription);
  FBeforeJSON := ABeforeJSON;
  FAfterJSON := AAfterJSON;
end;

procedure TJSONSnapshotCommand.DoExecute;
begin
  LoadGraphFromJSONText(FGraph, FAfterJSON);
end;

procedure TJSONSnapshotCommand.Undo;
begin
  LoadGraphFromJSONText(FGraph, FBeforeJSON);
end;

constructor TAddNodeCommand.Create(AGraph: TNodeGraph; ANode: TCustomNode);
begin
  inherited Create(AGraph, 'Add node');
  FNode := ANode;
  FOwnsNode := True;
end;

destructor TAddNodeCommand.Destroy;
begin
  if FOwnsNode and (FNode <> nil) then
    FNode.Free;

  inherited Destroy;
end;

procedure TAddNodeCommand.DoExecute;
begin
  if (FGraph = nil) or (FNode = nil) then
    Exit;

  if FGraph.Nodes.IndexOf(FNode) < 0 then
  begin
    FGraph.AddNode(FNode);
    FOwnsNode := False;
  end;
end;

procedure TAddNodeCommand.Undo;
begin
  if (FGraph = nil) or (FNode = nil) then
    Exit;

  if FGraph.DetachNode(FNode) then
    FOwnsNode := True;
end;

constructor TRemoveNodeCommand.Create(AGraph: TNodeGraph; ANode: TCustomNode);
var
  Obj: TJSONObject;
begin
  inherited Create(AGraph, 'Remove node');

  if ANode <> nil then
    FNodeId := ANode.Id;

  if AGraph <> nil then
  begin
    Obj := AGraph.SaveGraphToJSON;
    try
      FGraphBeforeJSON := Obj.AsJSON;
    finally
      Obj.Free;
    end;
  end;

  FNodeJSON := '';
end;

procedure TRemoveNodeCommand.DoExecute;
var
  N: TCustomNode;
begin
  if FGraph = nil then
    Exit;

  if FGraphAfterJSON <> '' then
  begin
    LoadGraphFromJSONText(FGraph, FGraphAfterJSON);
    Exit;
  end;

  N := FGraph.FindNodeById(FNodeId);
  if N <> nil then
    FGraph.RemoveNode(N);

  FGraphAfterJSON := FGraph.CaptureJSONText;
end;

procedure TRemoveNodeCommand.Undo;
begin
  if (FGraph = nil) or (FGraphBeforeJSON = '') then
    Exit;

  LoadGraphFromJSONText(FGraph, FGraphBeforeJSON);
end;

constructor TAddLinkCommand.Create(AGraph: TNodeGraph; AFromPin, AToPin: TNodePin);
begin
  inherited Create(AGraph, 'Add link');

  if AFromPin <> nil then
    FFromPinId := AFromPin.Id;

  if AToPin <> nil then
    FToPinId := AToPin.Id;

  FLinkId := NewId;
end;

procedure TAddLinkCommand.DoExecute;
var
  FromPin, ToPin: TNodePin;
  L: TNodeLink;
begin
  if FGraph = nil then
    Exit;

  FromPin := FGraph.FindPinById(FFromPinId);
  ToPin := FGraph.FindPinById(FToPinId);

  if (FromPin = nil) or (ToPin = nil) then
    Exit;

  L := TNodeLink.Create(FromPin, ToPin);
  L.Id := FLinkId;
  FGraph.AddLink(L);
end;

procedure TAddLinkCommand.Undo;
var
  i: integer;
  L: TNodeLink;
begin
  if FGraph = nil then
    Exit;

  for i := FGraph.Links.Count - 1 downto 0 do
  begin
    L := TNodeLink(FGraph.Links[i]);
    if L.Id = FLinkId then
    begin
      FGraph.RemoveLink(L);
      Break;
    end;
  end;
end;

constructor TRemoveLinkCommand.Create(AGraph: TNodeGraph; ALink: TNodeLink);
begin
  inherited Create(AGraph, 'Remove link');

  if ALink <> nil then
  begin
    FLinkId := ALink.Id;

    if ALink.FromPin <> nil then
      FFromPinId := ALink.FromPin.Id;

    if ALink.ToPin <> nil then
      FToPinId := ALink.ToPin.Id;
  end;
end;

procedure TRemoveLinkCommand.DoExecute;
var
  i: integer;
  L: TNodeLink;
begin
  if FGraph = nil then
    Exit;

  for i := FGraph.Links.Count - 1 downto 0 do
  begin
    L := TNodeLink(FGraph.Links[i]);
    if L.Id = FLinkId then
    begin
      FGraph.RemoveLink(L);
      Break;
    end;
  end;
end;

procedure TRemoveLinkCommand.Undo;
var
  FromPin, ToPin: TNodePin;
  L: TNodeLink;
begin
  if FGraph = nil then
    Exit;

  FromPin := FGraph.FindPinById(FFromPinId);
  ToPin := FGraph.FindPinById(FToPinId);

  if (FromPin = nil) or (ToPin = nil) then
    Exit;

  L := TNodeLink.Create(FromPin, ToPin);
  L.Id := FLinkId;
  FGraph.AddLink(L);
end;

constructor TMoveNodesCommand.Create(AGraph: TNodeGraph; ANodes: TCustomNodeList;
  const AOldPositions, ANewPositions: array of TPointF);
var
  i, C: integer;
  N: TCustomNode;
begin
  inherited Create(AGraph, 'Move nodes');

  FNodeIds := TStringList.Create;

  if ANodes = nil then
    Exit;

  C := ANodes.Count;

  SetLength(FOldX, C);
  SetLength(FOldY, C);
  SetLength(FNewX, C);
  SetLength(FNewY, C);

  for i := 0 to C - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    FNodeIds.Add(N.Id);

    FOldX[i] := AOldPositions[i].X;
    FOldY[i] := AOldPositions[i].Y;
    FNewX[i] := ANewPositions[i].X;
    FNewY[i] := ANewPositions[i].Y;
  end;
end;

destructor TMoveNodesCommand.Destroy;
begin
  FNodeIds.Free;
  inherited Destroy;
end;

procedure TMoveNodesCommand.DoExecute;
var
  i: integer;
  N: TCustomNode;
begin
  if FGraph = nil then
    Exit;

  for i := 0 to FNodeIds.Count - 1 do
  begin
    N := FGraph.FindNodeById(FNodeIds[i]);
    if N <> nil then
    begin
      N.X := FNewX[i];
      N.Y := FNewY[i];
    end;
  end;

  FGraph.DoGraphChanged;
end;

procedure TMoveNodesCommand.Undo;
var
  i: integer;
  N: TCustomNode;
begin
  if FGraph = nil then
    Exit;

  for i := 0 to FNodeIds.Count - 1 do
  begin
    N := FGraph.FindNodeById(FNodeIds[i]);
    if N <> nil then
    begin
      N.X := FOldX[i];
      N.Y := FOldY[i];
    end;
  end;

  FGraph.DoGraphChanged;
end;

constructor TResizeNodeCommand.Create(AGraph: TNodeGraph; ANode: TCustomNode;
  AOldWidth, AOldHeight, ANewWidth, ANewHeight: integer);
begin
  inherited Create(AGraph, 'Resize node');

  if ANode <> nil then
    FNodeId := ANode.Id;

  FOldWidth := AOldWidth;
  FOldHeight := AOldHeight;
  FNewWidth := ANewWidth;
  FNewHeight := ANewHeight;
end;

procedure TResizeNodeCommand.DoExecute;
var
  N: TCustomNode;
begin
  if FGraph = nil then
    Exit;

  N := FGraph.FindNodeById(FNodeId);
  if N = nil then
    Exit;

  N.Width := FNewWidth;
  N.Height := FNewHeight;

  FGraph.DoGraphChanged;
end;

procedure TResizeNodeCommand.Undo;
var
  N: TCustomNode;
begin
  if FGraph = nil then
    Exit;

  N := FGraph.FindNodeById(FNodeId);
  if N = nil then
    Exit;

  N.Width := FOldWidth;
  N.Height := FOldHeight;

  FGraph.DoGraphChanged;
end;

constructor TChangeNodePropertyCommand.Create(AGraph: TNodeGraph;
  ANode: TCustomNode; const AOldNodeJSON, ANewNodeJSON: string);
begin
  inherited Create(AGraph, 'Change node property');

  if ANode <> nil then
    FNodeId := ANode.Id;

  FOldJSON := AOldNodeJSON;
  FNewJSON := ANewNodeJSON;
end;

procedure TChangeNodePropertyCommand.DoExecute;
var
  N: TCustomNode;
  Data: TJSONData;
begin
  if FGraph = nil then
    Exit;

  N := FGraph.FindNodeById(FNodeId);
  if N = nil then
    Exit;

  Data := GetJSON(FNewJSON);
  try
    N.LoadFromJSON(TJSONObject(Data));
  finally
    Data.Free;
  end;

  FGraph.DoGraphChanged;
end;

procedure TChangeNodePropertyCommand.Undo;
var
  N: TCustomNode;
  Data: TJSONData;
begin
  if FGraph = nil then
    Exit;

  N := FGraph.FindNodeById(FNodeId);
  if N = nil then
    Exit;

  Data := GetJSON(FOldJSON);
  try
    N.LoadFromJSON(TJSONObject(Data));
  finally
    Data.Free;
  end;

  FGraph.DoGraphChanged;
end;


// =============================================================================
// TLazNodeInspector
// =============================================================================

constructor TLazNodeInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetInitialBounds(0, 0, 260, 600);
  FUpdating := False;
  BuildControls;
  ShowNoSelection;
end;

function TLazNodeInspector.MakeLabel(AParent: TWinControl; const AText: string;
  ALeft, ATop, AWidth: integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, 18);
  Result.Caption := AText;
  Result.Anchors := [akLeft, akTop];
end;

function TLazNodeInspector.MakeEdit(AParent: TWinControl;
  ALeft, ATop, AWidth: integer): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, 22);
  Result.Anchors := [akLeft, akTop, akRight];
end;

function TLazNodeInspector.MakeColorPanel(AParent: TWinControl;
  ALeft, ATop, AWidth: integer): TPanel;
begin
  Result := TPanel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, 22);
  Result.Anchors := [akLeft, akTop, akRight];
  Result.BevelOuter := bvLowered;
  Result.Cursor := crHandPoint;
end;

procedure TLazNodeInspector.ValuesGridSelectCell(Sender: TObject;
  ACol, ARow: integer; var CanSelect: boolean);
begin
  if (ARow > 0) and (ACol = 2) then
    FValuesGrid.Options := FValuesGrid.Options + [goEditing]
  else
    FValuesGrid.Options := FValuesGrid.Options - [goEditing];
  CanSelect := True;
end;

function TLazNodeInspector.SafeClientWidth(AControl: TWinControl;
  ADefault: integer): integer;
begin
  Result := AControl.ClientWidth;

  if Result <= 20 then
    Result := AControl.Width;

  if Result <= 20 then
    Result := ADefault;
end;

function TLazNodeInspector.EditWidth(AParent: TWinControl; ALeft: integer): integer;
begin
  Result := SafeClientWidth(AParent) - ALeft - 10;

  if Result < 40 then
    Result := 40;
end;

procedure TLazNodeInspector.ClearAllSections;
begin
  FLblTypeVal.Caption := '—';
  FTitleEdit.Text := '';
  FXEdit.Text := '';
  FYEdit.Text := '';
  FWidthEdit.Text := '';
  FHeightEdit.Text := '';
  FHeaderColorPanel.Color := clBtnFace;
  FBodyColorPanel.Color := clBtnFace;
  FCollapsedCheck.Checked := False;
  FCommentMemo.Text := '';

  FPinsGrid.RowCount := 1;

  FValuesGrid.RowCount := 1;
end;

procedure TLazNodeInspector.ShowNoSelection;
begin
  FUpdating := True;
  try
    ClearAllSections;
    FLblTypeVal.Caption := '(no selection)';
    FApplyButton.Enabled := False;
    FRevertButton.Enabled := False;
  finally
    FUpdating := False;
  end;
end;

procedure TLazNodeInspector.SetEditor(AValue: TLazNodeEditor);
begin
  if FEditor = AValue then Exit;
  FEditor := AValue;
  RefreshFromSelection;
end;

procedure TLazNodeInspector.RefreshFromSelection;
var
  N: TCustomNode;
  i: integer;
  P: TNodePin;
  V: TNodeValue;
  VStr: string;
begin
  if (FEditor = nil) or (FEditor.SelectedNodeCount <> 1) then
  begin
    ShowNoSelection;
    Exit;
  end;

  N := FEditor.GetSelectedNode(0);
  if N = nil then
  begin
    ShowNoSelection;
    Exit;
  end;

  FUpdating := True;
  try
    // --- Info ---
    FLblTypeVal.Caption := N.NodeType;

    // --- Basic ---
    FTitleEdit.Text := N.Title;
    FXEdit.Text := FormatFloat('0.##', N.X);
    FYEdit.Text := FormatFloat('0.##', N.Y);
    FWidthEdit.Text := IntToStr(N.Width);
    FHeightEdit.Text := IntToStr(N.Height);

    // --- Visual ---
    FHeaderColorPanel.Color := N.HeaderColor;
    FBodyColorPanel.Color := N.BodyColor;
    FCollapsedCheck.Checked := N.Collapsed;

    // --- Comment ---
    FCommentMemo.Text := N.CommentText;

    // --- Pins ---
    FPinsGrid.RowCount := Max(2, 1 + N.InputCount + N.OutputCount);
    for i := 0 to N.InputCount - 1 do
    begin
      P := N.GetInput(i);
      FPinsGrid.Cells[0, i + 1] := P.EffectiveDisplayName;
      FPinsGrid.Cells[1, i + 1] := 'In';
      FPinsGrid.Cells[2, i + 1] :=
        specialize IfThen<string>(P.PinType <> nil, P.PinType.TypeId, P.DataType);
      FPinsGrid.Cells[3, i + 1] :=
        specialize IfThen<string>(P.Kind = pkExec, 'exec', 'data');
    end;
    for i := 0 to N.OutputCount - 1 do
    begin
      P := N.GetOutput(i);
      FPinsGrid.Cells[0, N.InputCount + i + 1] := P.EffectiveDisplayName;
      FPinsGrid.Cells[1, N.InputCount + i + 1] := 'Out';
      FPinsGrid.Cells[2, N.InputCount + i + 1] :=
        specialize IfThen<string>(P.PinType <> nil, P.PinType.TypeId, P.DataType);
      FPinsGrid.Cells[3, N.InputCount + i + 1] :=
        specialize IfThen<string>(P.Kind = pkExec, 'exec', 'data');
    end;

    // --- Values ---
    if N.ValueCount > 0 then
    begin
      FValuesGrid.RowCount := 1 + N.ValueCount;
      for i := 0 to N.ValueCount - 1 do
      begin
        V := N.GetValue(i);
        FValuesGrid.Cells[0, i + 1] := V.Name;
        FValuesGrid.Cells[1, i + 1] := NodeValueKindToStr(V.Kind);

        case V.Kind of
          nvkFloat: VStr := FormatFloat('0.######', V.FloatValue);
          nvkInteger: VStr := IntToStr(V.IntegerValue);
          nvkString: VStr := V.StringValue;
          nvkBoolean: VStr := specialize IfThen<string>(V.BooleanValue, 'true', 'false');
          nvkJSON: VStr := V.JSONValue;
          else
            VStr := '';
        end;

        FValuesGrid.Cells[2, i + 1] := VStr;
      end;
    end
    else
      FValuesGrid.RowCount := 1;

    FApplyButton.Enabled := True;
    FRevertButton.Enabled := True;
  finally
    FUpdating := False;
  end;
end;

// ---------------------------------------------------------------------------
// Color pickers
// ---------------------------------------------------------------------------

procedure TLazNodeInspector.HeaderColorClick(Sender: TObject);
var
  D: TColorDialog;
begin
  if (FEditor = nil) or (FEditor.SelectedNodeCount <> 1) then Exit;

  D := TColorDialog.Create(nil);
  try
    D.Color := FHeaderColorPanel.Color;
    if D.Execute then
    begin
      FHeaderColorPanel.Color := D.Color;
    end;
  finally
    D.Free;
  end;
end;

procedure TLazNodeInspector.BodyColorClick(Sender: TObject);
var
  D: TColorDialog;
begin
  if (FEditor = nil) or (FEditor.SelectedNodeCount <> 1) then Exit;

  D := TColorDialog.Create(nil);
  try
    D.Color := FBodyColorPanel.Color;
    if D.Execute then
    begin
      FBodyColorPanel.Color := D.Color;
    end;
  finally
    D.Free;
  end;
end;

// ---------------------------------------------------------------------------
// Apply / Revert
// ---------------------------------------------------------------------------

procedure TLazNodeInspector.ApplyClick(Sender: TObject);
var
  N: TCustomNode;
  OldObj, NewObj: TJSONObject;
  OldJSON, NewJSON: string;
  i: integer;
  V: TNodeValue;
  VStr: string;
begin
  if FUpdating then Exit;
  if (FEditor = nil) or (FEditor.SelectedNodeCount <> 1) then Exit;

  N := FEditor.GetSelectedNode(0);
  if N = nil then Exit;

  OldObj := TJSONObject.Create;
  try
    N.SaveToJSON(OldObj);
    OldJSON := OldObj.AsJSON;
  finally
    OldObj.Free;
  end;

  N.Title := FTitleEdit.Text;
  N.X := StrToFloatDef(FXEdit.Text, N.X);
  N.Y := StrToFloatDef(FYEdit.Text, N.Y);
  N.Width := StrToIntDef(FWidthEdit.Text, N.Width);
  N.Height := StrToIntDef(FHeightEdit.Text, N.Height);

  N.HeaderColor := FHeaderColorPanel.Color;
  N.BodyColor := FBodyColorPanel.Color;
  N.Collapsed := FCollapsedCheck.Checked;

  N.CommentText := FCommentMemo.Text;

  for i := 0 to N.ValueCount - 1 do
  begin
    if (i + 1) < FValuesGrid.RowCount then
    begin
      V := N.GetValue(i);
      VStr := Trim(FValuesGrid.Cells[2, i + 1]);

      case V.Kind of
        nvkFloat: V.FloatValue := StrToFloatDef(VStr, V.FloatValue);
        nvkInteger: V.IntegerValue := StrToInt64Def(VStr, V.IntegerValue);
        nvkString: V.StringValue := VStr;
        nvkBoolean: V.BooleanValue := SameText(VStr, 'true') or (VStr = '1');
        nvkJSON: V.JSONValue := VStr;
      end;
    end;
  end;

  NewObj := TJSONObject.Create;
  try
    N.SaveToJSON(NewObj);
    NewJSON := NewObj.AsJSON;
  finally
    NewObj.Free;
  end;

  if OldJSON <> NewJSON then
  begin
    FEditor.Graph.ExecuteCommand(
      TChangeNodePropertyCommand.Create(FEditor.Graph, N, OldJSON, NewJSON));
  end;

  if Assigned(FEditor.OnNodeChanged) then
    FEditor.OnNodeChanged(FEditor, N);

  FEditor.Invalidate;

  RefreshFromSelection;
end;

procedure TLazNodeInspector.RevertClick(Sender: TObject);
begin
  RefreshFromSelection;
end;


// ---------------------------------------------------------------------------
// BuildControls
// ---------------------------------------------------------------------------

procedure TLazNodeInspector.BuildControls;
var
  YPos: integer;
begin
  FScrollBox := TScrollBox.Create(Self);
  FScrollBox.Parent := Self;
  FScrollBox.Align := alClient;
  FScrollBox.BorderStyle := bsNone;
  FScrollBox.HorzScrollBar.Visible := False;
  FScrollBox.VertScrollBar.Tracking := True;

  YPos := 6;

  BuildInfoSection(FScrollBox, YPos);
  BuildBasicSection(FScrollBox, YPos);
  BuildVisualSection(FScrollBox, YPos);
  BuildCommentSection(FScrollBox, YPos);
  BuildPinsSection(FScrollBox, YPos);
  BuildValuesSection(FScrollBox, YPos);
  BuildButtonBar(FScrollBox, YPos);
end;

// ---------------------------------------------------------------------------
// Section builders
// ---------------------------------------------------------------------------

procedure TLazNodeInspector.BuildInfoSection(AParent: TWinControl; var ATop: integer);
const
  LW = 70;
  EX = 78;
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  ROW_H = 28;
var
  GH: integer;
begin
  GH := CAPTION_H + ROW_H + 8;

  FGrpInfo := TGroupBox.Create(Self);
  FGrpInfo.Parent := AParent;
  FGrpInfo.Caption := 'Node Info';
  FGrpInfo.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
    );
  FGrpInfo.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  MakeLabel(FGrpInfo, 'Type:', 8, CAPTION_H div 2, LW);

  FLblTypeVal := TLabel.Create(Self);
  FLblTypeVal.Parent := FGrpInfo;
  FLblTypeVal.SetBounds(
    EX,
    CAPTION_H div 2,
    EditWidth(FGrpInfo, EX),
    20
    );
  FLblTypeVal.Anchors := [akLeft, akTop, akRight];
  FLblTypeVal.Caption := '—';
  FLblTypeVal.Font.Style := [fsBold];
end;

procedure TLazNodeInspector.BuildBasicSection(AParent: TWinControl; var ATop: integer);
const
  LW = 52;
  EX = 64;
  ROW = 40;
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  BOTTOM_PAD = 10;
var
  EW: integer;
  GH: integer;
  Y: integer;
begin
  GH := CAPTION_H + ROW * 5 + BOTTOM_PAD;

  FGrpBasic := TGroupBox.Create(Self);
  FGrpBasic.Parent := AParent;
  FGrpBasic.Caption := 'Transform';
  FGrpBasic.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
    );
  FGrpBasic.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  EW := EditWidth(FGrpBasic, EX);
  Y := CAPTION_H;

  MakeLabel(FGrpBasic, 'Title:', 8, Y + 4, LW);
  FTitleEdit := MakeEdit(FGrpBasic, EX, Y, EW);
  Inc(Y, ROW);

  MakeLabel(FGrpBasic, 'X:', 8, Y + 4, LW);
  FXEdit := MakeEdit(FGrpBasic, EX, Y, EW);
  Inc(Y, ROW);

  MakeLabel(FGrpBasic, 'Y:', 8, Y + 4, LW);
  FYEdit := MakeEdit(FGrpBasic, EX, Y, EW);
  Inc(Y, ROW);

  MakeLabel(FGrpBasic, 'Width:', 8, Y + 4, LW);
  FWidthEdit := MakeEdit(FGrpBasic, EX, Y, EW);
  Inc(Y, ROW);

  MakeLabel(FGrpBasic, 'Height:', 8, Y + 4, LW);
  FHeightEdit := MakeEdit(FGrpBasic, EX, Y, EW);
end;

procedure TLazNodeInspector.BuildVisualSection(AParent: TWinControl; var ATop: integer);
const
  LW = 90;
  EX = 100;
  ROW = 40;
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  BOTTOM_PAD = 10;
var
  EW: integer;
  GH: integer;
  Y: integer;
begin
  GH := CAPTION_H + ROW * 3 + BOTTOM_PAD;

  FGrpVisual := TGroupBox.Create(Self);
  FGrpVisual.Parent := AParent;
  FGrpVisual.Caption := 'Visual';
  FGrpVisual.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
    );
  FGrpVisual.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  EW := EditWidth(FGrpVisual, EX);
  Y := CAPTION_H;

  MakeLabel(FGrpVisual, 'Header Color:', 8, Y + 4, LW);
  FHeaderColorPanel := MakeColorPanel(FGrpVisual, EX, Y, EW);
  FHeaderColorPanel.OnClick := @HeaderColorClick;
  Inc(Y, ROW);

  MakeLabel(FGrpVisual, 'Body Color:', 8, Y + 4, LW);
  FBodyColorPanel := MakeColorPanel(FGrpVisual, EX, Y, EW);
  FBodyColorPanel.OnClick := @BodyColorClick;
  Inc(Y, ROW);

  FCollapsedCheck := TCheckBox.Create(Self);
  FCollapsedCheck.Parent := FGrpVisual;
  FCollapsedCheck.SetBounds(
    8,
    Y + 2,
    SafeClientWidth(FGrpVisual) - 16,
    22
    );
  FCollapsedCheck.Caption := 'Collapsed';
  FCollapsedCheck.Anchors := [akLeft, akTop, akRight];
end;

procedure TLazNodeInspector.BuildCommentSection(AParent: TWinControl;
  var ATop: integer);
const
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  MEMO_H = 50;
  BOTTOM_PAD = 10;
var
  GH: integer;
begin
  GH := CAPTION_H + MEMO_H + (BOTTOM_PAD * 2);

  FGrpComment := TGroupBox.Create(Self);
  FGrpComment.Parent := AParent;
  FGrpComment.Caption := 'Comment';
  FGrpComment.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
    );
  FGrpComment.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  FCommentMemo := TMemo.Create(Self);
  FCommentMemo.Parent := FGrpComment;
  FCommentMemo.SetBounds(
    8,
    CAPTION_H div 2,
    SafeClientWidth(FGrpComment) - 16,
    MEMO_H
    );
  FCommentMemo.Anchors := [akLeft, akTop, akRight];
  FCommentMemo.ScrollBars := ssVertical;
  FCommentMemo.WordWrap := True;
end;

procedure TLazNodeInspector.BuildPinsSection(AParent: TWinControl; var ATop: integer);
const
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  GRID_H = 100;
  BOTTOM_PAD = 10;
var
  GH: integer;
begin
  GH := CAPTION_H + GRID_H + (BOTTOM_PAD * 2);

  FGrpPins := TGroupBox.Create(Self);
  FGrpPins.Parent := AParent;
  FGrpPins.Caption := 'Pins';
  FGrpPins.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
    );
  FGrpPins.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  FPinsGrid := TStringGrid.Create(Self);
  FPinsGrid.Parent := FGrpPins;
  FPinsGrid.SetBounds(
    8,
    CAPTION_H div 2,
    SafeClientWidth(FGrpPins) - 16,
    GRID_H
    );
  FPinsGrid.Anchors := [akLeft, akTop, akRight];
  FPinsGrid.RowCount := 1;
  FPinsGrid.ColCount := 4;
  FPinsGrid.FixedRows := 1;
  FPinsGrid.FixedCols := 0;
  FPinsGrid.Options := [goRowSizing, goColSizing, goDrawFocusSelected,
    goRowSelect, goThumbTracking];
  FPinsGrid.ScrollBars := ssVertical;
  FPinsGrid.DefaultRowHeight := 20;
  FPinsGrid.Cells[0, 0] := 'Name';
  FPinsGrid.Cells[1, 0] := 'Dir';
  FPinsGrid.Cells[2, 0] := 'Type';
  FPinsGrid.Cells[3, 0] := 'Kind';
  FPinsGrid.ColWidths[0] := 80;
  FPinsGrid.ColWidths[1] := 42;
  FPinsGrid.ColWidths[2] := 60;
  FPinsGrid.ColWidths[3] := 44;
end;

procedure TLazNodeInspector.BuildValuesSection(AParent: TWinControl; var ATop: integer);
const
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  GRID_H = 90;
  BOTTOM_PAD = 10;
var
  GH: integer;
begin
  GH := CAPTION_H + GRID_H + (BOTTOM_PAD * 2);

  FGrpValues := TGroupBox.Create(Self);
  FGrpValues.Parent := AParent;
  FGrpValues.Caption := 'Values';
  FGrpValues.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
    );
  FGrpValues.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  FValuesGrid := TStringGrid.Create(Self);
  FValuesGrid.Parent := FGrpValues;
  FValuesGrid.SetBounds(
    8,
    CAPTION_H div 2,
    SafeClientWidth(FGrpValues) - 16,
    GRID_H
    );
  FValuesGrid.Anchors := [akLeft, akTop, akRight];
  FValuesGrid.RowCount := 1;
  FValuesGrid.ColCount := 3;
  FValuesGrid.FixedRows := 1;
  FValuesGrid.FixedCols := 0;
  FValuesGrid.Options := [goRowSizing, goColSizing, goDrawFocusSelected,
    goRowSelect, goThumbTracking, goEditing];
  FValuesGrid.ScrollBars := ssVertical;
  FValuesGrid.DefaultRowHeight := 20;
  FValuesGrid.Cells[0, 0] := 'Name';
  FValuesGrid.Cells[1, 0] := 'Kind';
  FValuesGrid.Cells[2, 0] := 'Value';
  FValuesGrid.ColWidths[0] := 72;
  FValuesGrid.ColWidths[1] := 52;
  FValuesGrid.ColWidths[2] := 80;
  FValuesGrid.OnSelectCell := @ValuesGridSelectCell;
end;

procedure TLazNodeInspector.BuildButtonBar(AParent: TWinControl; var ATop: integer);
const
  LEFT_PAD = 4;
  GAP = 8;
  BUTTON_H = 30;
var
  BW: integer;
  W: integer;
begin
  W := SafeClientWidth(AParent);
  BW := (W - LEFT_PAD * 2 - GAP) div 2;

  if BW < 60 then
    BW := 60;

  FApplyButton := TButton.Create(Self);
  FApplyButton.Parent := AParent;
  FApplyButton.SetBounds(LEFT_PAD, ATop, BW, BUTTON_H);
  FApplyButton.Caption := 'Apply';
  FApplyButton.Anchors := [akLeft, akTop];
  FApplyButton.OnClick := @ApplyClick;

  FRevertButton := TButton.Create(Self);
  FRevertButton.Parent := AParent;
  FRevertButton.SetBounds(LEFT_PAD + BW + GAP, ATop, BW, BUTTON_H);
  FRevertButton.Caption := 'Revert';
  FRevertButton.Anchors := [akLeft, akTop];
  FRevertButton.OnClick := @RevertClick;

  Inc(ATop, BUTTON_H + 8);
end;


// =============================================================================
// TLazNodeEditor (View/Controller)
// =============================================================================

constructor TLazNodeEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FGraph := TNodeGraph.Create;
  FController := TNodeEditorController.Create(FGraph);
  FController.Selection.OnChanged := @ControllerSelectionChanged;

  FSelectedNodes := TCustomNodeList.Create(False); // does not own nodes
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

  FPopupMenu := TPopupMenu.Create(Self);
  BuildContextMenu;
  PopupMenu := FPopupMenu;
end;

destructor TLazNodeEditor.Destroy;
begin
  FController.Free;
  FSelectedNodes.Free;
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

// === View Logic ===

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
  if FController <> nil then
  begin
    FController.DeleteSelection;
    SyncControllerSelectionToView;
    Invalidate;
  end;
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

procedure TLazNodeEditor.SelectLinkInternal(ALink: TNodeLink);
var
  i: integer;
begin
  for i := 0 to FSelectedNodes.Count - 1 do
    if FSelectedNodes[i] <> nil then
      TCustomNode(FSelectedNodes[i]).Selected := False;

  FSelectedNodes.Clear;
  FSelectedNode := nil;
  FSelectedLink := ALink;

  if FController <> nil then
    FController.Selection.SelectLink(ALink);
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

procedure TLazNodeEditor.SyncControllerSelectionToView;
var
  i: integer;
  N: TCustomNode;
begin
  if FController = nil then
    Exit;

  for i := 0 to FGraph.Nodes.Count - 1 do
    TCustomNode(FGraph.Nodes[i]).Selected := False;

  FSelectedNodes.Clear;
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

  if FController.Selection.HasLink then
    FSelectedLink := FController.Selection.SelectedLink;

  NotifySelectionChanged;
  Invalidate;
end;

function TLazNodeEditor.SelectedNodeCount: integer;
begin
  Result := FSelectedNodes.Count;
end;

function TLazNodeEditor.SelectedLinkCount: integer;
begin
  if FSelectedLink <> nil then Result := 1
  else
    Result := 0;
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
  DX, DY: integer;
  Dist: single;
  D: integer;
begin
  S0 := ALink.FromPin.OwnerNode.GetPinScreenPosition(ALink.FromPin,
    FZoom, FOffsetX, FOffsetY);
  S1 := ALink.ToPin.OwnerNode.GetPinScreenPosition(ALink.ToPin, FZoom,
    FOffsetX, FOffsetY);
  P0 := S0;
  P3 := S1;

  DX := P3.X - P0.X;
  DY := P3.Y - P0.Y;

  Dist := Sqrt(DX * DX + DY * DY);

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

    if Link = FSelectedLink then
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
    FixedPos := FReconnectFixedPin.OwnerNode.GetPinScreenPosition(
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
    P0 := FTempFromPin.OwnerNode.GetPinScreenPosition(
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
  FBoxSelecting := False;
  FResizingNode := False;
  FResizeNode := nil;

  FReconnectingLink := False;
  FReconnectLink := nil;
  FReconnectFixedPin := nil;

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

  N := APin.OwnerNode;

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
      SelectLinkInternal(Link);
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
      if ssCtrl in Shift then
        SelectNodeInternal(Node, True)
      else if FSelectedNodes.IndexOf(Node) < 0 then
        SelectNodeInternal(Node, False)
      else
        FSelectedNode := Node;
      FDraggingNode := True;
      FDragUndoPushed := False;
      FDragStartX := X;
      FDragStartY := Y;

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
    if not (ssShift in Shift) then ClearSelectionInternal;
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

    FPanning := True;
    FRightMouseMoved := False;
    FPanStartX := X;
    FPanStartY := Y;
  end;
end;

procedure TLazNodeEditor.MouseMove(Shift: TShiftState; X, Y: integer);
var
  i: integer;
  N: TCustomNode;
  Dx, Dy: single;
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

  if FPanning then
  begin
    if (Abs(X - FPanStartX) > 1) or (Abs(Y - FPanStartY) > 1) then
      FRightMouseMoved := True;
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
    Dx := (X - FDragStartX) / FZoom;
    Dy := (Y - FDragStartY) / FZoom;
    for i := 0 to FSelectedNodes.Count - 1 do
    begin
      N := TCustomNode(FSelectedNodes[i]);
      N.X := N.X + Dx;
      N.Y := N.Y + Dy;

      if FSnapToGrid and not (ssAlt in Shift) then
      begin
        N.X := SnapWorldValue(N.X);
        N.Y := SnapWorldValue(N.Y);
      end;

      if Assigned(FOnNodeChanged) then FOnNodeChanged(Self, N);
    end;
    FDragStartX := X;
    FDragStartY := Y;
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
    FDragCommandNodes.Clear;
    SetLength(FDragOldPositions, 0);

    if FBoxSelecting then
    begin
      R := NormalizeRect(Rect(FBoxStart.X, FBoxStart.Y, FBoxCurrent.X, FBoxCurrent.Y));
      if not (ssShift in Shift) then ClearSelectionInternal;
      for i := 0 to FGraph.Nodes.Count - 1 do
      begin
        N := TCustomNode(FGraph.Nodes[i]);
        if RectIntersects(R, N.GetScreenBounds(FZoom, FOffsetX, FOffsetY)) then
          SelectNodeInternal(N, True);
      end;
      FBoxSelecting := False;
      NotifySelectionChanged;
      Invalidate;
    end;
  end
  else if Button = mbRight then
  begin
    FPanning := False;

    if not FRightMouseMoved then
    begin
      FContextWorldPos := ScreenToWorld(X, Y);
      FPopupMenu.PopUp(Mouse.CursorPos.X, Mouse.CursorPos.Y);
    end;
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
  Invalidate;
end;

procedure TLazNodeEditor.KeyDown(var Key: word; Shift: TShiftState);
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
end;

// =============================================================================
// TNodeSearchForm
// =============================================================================


constructor TNodeSearchForm.CreateSearch(AOwner: TComponent; ARegistry: TNodeRegistry);
begin
  inherited CreateNew(AOwner);

  FRegistry := ARegistry;
  SelectedNodeType := '';

  BorderStyle := bsToolWindow;
  Position := poDesigned;
  Width := 260;
  Height := 300;
  Caption := 'Add Node';

  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.Align := alTop;
  FEdit.OnChange := @EditChange;
  FEdit.OnKeyDown := @EditKeyDown;

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := alClient;
  FList.OnDblClick := @ListDblClick;

  RebuildList;
end;

procedure TNodeSearchForm.RebuildList;
var
  i: integer;
  It: TNodeRegistryItem;
  FilterText: string;
begin
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    FilterText := UTF8LowerCase(FEdit.Text);

    for i := 0 to FRegistry.Count - 1 do
    begin
      It := FRegistry.Item(i);

      if (FilterText = '') or (Pos(FilterText, UTF8LowerCase(It.Caption)) > 0) or
        (Pos(FilterText, UTF8LowerCase(It.NodeType)) > 0) or
        (TNodeDefinition(It).MatchesFilter(FilterText)) then
      begin
        FList.Items.AddObject(It.Caption + ' [' + It.NodeType + ']', It);
      end;
    end;

    if FList.Items.Count > 0 then
      FList.ItemIndex := 0;
  finally
    FList.Items.EndUpdate;
  end;
end;

procedure TNodeSearchForm.EditChange(Sender: TObject);
begin
  RebuildList;
end;

procedure TNodeSearchForm.ListDblClick(Sender: TObject);
var
  It: TNodeRegistryItem;
begin
  if FList.ItemIndex < 0 then Exit;

  It := TNodeRegistryItem(FList.Items.Objects[FList.ItemIndex]);
  if It = nil then Exit;

  SelectedNodeType := It.NodeType;
  ModalResult := mrOk;
end;

procedure TNodeSearchForm.EditKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
var
  It: TNodeRegistryItem;
begin
  if Key = VK_RETURN then
  begin
    if FList.ItemIndex >= 0 then
    begin
      It := TNodeRegistryItem(FList.Items.Objects[FList.ItemIndex]);
      if It <> nil then
      begin
        SelectedNodeType := It.NodeType;
        ModalResult := mrOk;
      end;
    end;
    Key := 0;
  end
  else if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Key := 0;
  end
  else if Key = VK_DOWN then
  begin
    if FList.ItemIndex < FList.Items.Count - 1 then
      FList.ItemIndex := FList.ItemIndex + 1;
    Key := 0;
  end
  else if Key = VK_UP then
  begin
    if FList.ItemIndex > 0 then
      FList.ItemIndex := FList.ItemIndex - 1;
    Key := 0;
  end;
end;

// =============================================================================
// Implementation of new service classes (TNodeSelectionModel, etc.)
// =============================================================================

constructor TNodeSelectionModel.Create;
begin
  inherited Create;
  FNodes := TCustomNodeList.Create(False);
end;

destructor TNodeSelectionModel.Destroy;
begin
  FNodes.Free;
  inherited Destroy;
end;

procedure TNodeSelectionModel.NotifyChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TNodeSelectionModel.Clear;
var
  i: integer;
begin
  for i := 0 to FNodes.Count - 1 do
    if FNodes[i] <> nil then
      FNodes[i].Selected := False;
  FNodes.Clear;
  FSelectedLink := nil;
  NotifyChanged;
end;

procedure TNodeSelectionModel.SelectNode(ANode: TCustomNode; AAppend: boolean);
var
  i: integer;
begin
  if ANode = nil then Exit;

  if not AAppend then
  begin
    for i := 0 to FNodes.Count - 1 do
      if FNodes[i] <> nil then
        FNodes[i].Selected := False;

    FNodes.Clear;
    FSelectedLink := nil;
  end
  else
    FSelectedLink := nil;

  if FNodes.IndexOf(ANode) < 0 then
  begin
    FNodes.Add(ANode);
    ANode.Selected := True;
  end;

  NotifyChanged;
end;

procedure TNodeSelectionModel.SelectLink(ALink: TNodeLink);
var
  i: integer;
begin
  for i := 0 to FNodes.Count - 1 do
    if FNodes[i] <> nil then
      FNodes[i].Selected := False;

  FNodes.Clear;
  FSelectedLink := ALink;

  NotifyChanged;
end;

procedure TNodeSelectionModel.RemoveNode(ANode: TCustomNode);
begin
  if ANode = nil then Exit;
  FNodes.Remove(ANode);
  if FSelectedLink <> nil then
  begin
    if (((FSelectedLink.FromPin <> nil) and
      (FSelectedLink.FromPin.OwnerNode = ANode)) or
      ((FSelectedLink.ToPin <> nil) and (FSelectedLink.ToPin.OwnerNode =
      ANode))) then
      FSelectedLink := nil;
  end;
  NotifyChanged;
end;

function TNodeSelectionModel.NodeCount: integer;
begin
  Result := FNodes.Count;
end;

function TNodeSelectionModel.GetNode(Index: integer): TCustomNode;
begin
  if (Index >= 0) and (Index < FNodes.Count) then
    Result := FNodes[Index]
  else
    Result := nil;
end;

function TNodeSelectionModel.HasLink: boolean;
begin
  Result := FSelectedLink <> nil;
end;

function TNodeSelectionModel.SelectedLink: TNodeLink;
begin
  Result := FSelectedLink;
end;

// --- TNodeClipboardService ---

function TNodeClipboardService.NodesToJSONText(ANodes: TCustomNodeList;
  AGraph: TNodeGraph): string;
var
  Root: TJSONObject;
  NodesArr, LinksArr: TJSONArray;
  NodeObj, LinkObj: TJSONObject;
  i: integer;
  N: TCustomNode;
  L: TNodeLink;
begin
  Result := '';
  if (ANodes = nil) or (ANodes.Count = 0) then Exit;

  Root := TJSONObject.Create;
  try
    Root.Add('version', 1);
    NodesArr := TJSONArray.Create;
    for i := 0 to ANodes.Count - 1 do
    begin
      N := ANodes[i];
      NodeObj := TJSONObject.Create;
      N.SaveToJSON(NodeObj);
      NodesArr.Add(NodeObj);
    end;
    Root.Add('nodes', NodesArr);

    LinksArr := TJSONArray.Create;
    for i := 0 to AGraph.Links.Count - 1 do
    begin
      L := AGraph.Links[i];
      if (L.FromPin = nil) or (L.ToPin = nil) then Continue;
      if (ANodes.IndexOf(L.FromPin.OwnerNode) >= 0) and
        (ANodes.IndexOf(L.ToPin.OwnerNode) >= 0) then
      begin
        LinkObj := TJSONObject.Create;
        LinkObj.Add('id', L.Id);
        LinkObj.Add('fromPinId', L.FromPin.Id);
        LinkObj.Add('toPinId', L.ToPin.Id);
        LinksArr.Add(LinkObj);
      end;
    end;
    Root.Add('links', LinksArr);
    Result := Root.AsJSON;
  finally
    Root.Free;
  end;
end;

procedure TNodeClipboardService.PasteNodesFromJSONText(const AJSON: string;
  AGraph: TNodeGraph; AX, AY: single; ASelection: TNodeSelectionModel);
var
  Data: TJSONData;
  Root: TJSONObject;
  NodesArr, LinksArr: TJSONArray;
  NodeObj, LinkObj: TJSONObject;
  OldToNewNodeIds, OldToNewPinIds: TStringList;
  i, j: integer;
  N: TCustomNode;
  NodeType, OldNodeId, NewNodeId, NewPinId: string;
  P: TNodePin;
  MinX, MinY: single;
  First: boolean;
  FromPin, ToPin: TNodePin;
  NewFromId, NewToId: string;
begin
  if Trim(AJSON) = '' then Exit;

  if ASelection <> nil then
    ASelection.Clear;

  Data := GetJSON(AJSON);
  try
    Root := TJSONObject(Data);
    NodesArr := Root.Arrays['nodes'];
    if NodesArr = nil then Exit;

    OldToNewNodeIds := TStringList.Create;
    OldToNewPinIds := TStringList.Create;
    OldToNewNodeIds.NameValueSeparator := '=';
    OldToNewPinIds.NameValueSeparator := '=';

    try
      First := True;
      for i := 0 to NodesArr.Count - 1 do
      begin
        NodeObj := NodesArr.Objects[i];
        if First then
        begin
          MinX := NodeObj.Get('x', 0.0);
          MinY := NodeObj.Get('y', 0.0);
          First := False;
        end
        else
        begin
          MinX := Min(MinX, NodeObj.Get('x', 0.0));
          MinY := Min(MinY, NodeObj.Get('y', 0.0));
        end;
      end;

      for i := 0 to NodesArr.Count - 1 do
      begin
        NodeObj := NodesArr.Objects[i];
        NodeType := NodeObj.Get('type', 'default');
        OldNodeId := NodeObj.Get('id', '');

        N := AGraph.Registry.CreateNode(NodeType, NodeObj.Get('x', 0.0),
          NodeObj.Get('y', 0.0));
        N.LoadFromJSON(NodeObj);
        NewNodeId := NewId;
        N.Id := NewNodeId;
        N.X := AX + (N.X - MinX);
        N.Y := AY + (N.Y - MinY);

        OldToNewNodeIds.Values[OldNodeId] := NewNodeId;

        for j := 0 to N.InputCount - 1 do
        begin
          P := N.GetInput(j);
          NewPinId := NewId;
          OldToNewPinIds.Values[P.Id] := NewPinId;
          P.Id := NewPinId;
        end;
        for j := 0 to N.OutputCount - 1 do
        begin
          P := N.GetOutput(j);
          NewPinId := NewId;
          OldToNewPinIds.Values[P.Id] := NewPinId;
          P.Id := NewPinId;
        end;

        AGraph.AddNode(N);
        if ASelection <> nil then
          ASelection.SelectNode(N, True);
      end;

      LinksArr := Root.Arrays['links'];
      if LinksArr <> nil then
      begin
        for i := 0 to LinksArr.Count - 1 do
        begin
          LinkObj := LinksArr.Objects[i];
          NewFromId := OldToNewPinIds.Values[LinkObj.Get('fromPinId', '')];
          NewToId := OldToNewPinIds.Values[LinkObj.Get('toPinId', '')];
          FromPin := AGraph.FindPinById(NewFromId);
          ToPin := AGraph.FindPinById(NewToId);
          if (FromPin <> nil) and (ToPin <> nil) and
            AGraph.CanConnect(FromPin, ToPin) then
            AGraph.AddLink(TNodeLink.Create(FromPin, ToPin));
        end;
      end;
    finally
      OldToNewNodeIds.Free;
      OldToNewPinIds.Free;
    end;
  finally
    Data.Free;
  end;
end;

// --- TNodeEditorController ---

constructor TNodeEditorController.Create(AGraph: TNodeGraph);
begin
  inherited Create;
  FGraph := AGraph;
  FSelection := TNodeSelectionModel.Create;
  FClipboard := TNodeClipboardService.Create;
end;

destructor TNodeEditorController.Destroy;
begin
  FClipboard.Free;
  FSelection.Free;
  inherited Destroy;
end;

procedure TNodeEditorController.ExecuteCommand(ACmd: TGraphCommand);
begin
  if ACmd = nil then
    Exit;

  if FGraph = nil then
  begin
    ACmd.Free;
    Exit;
  end;

  FGraph.ExecuteCommand(ACmd);
end;

procedure TNodeEditorController.Undo;
begin
  if FGraph <> nil then
    FGraph.Undo;
end;

procedure TNodeEditorController.Redo;
begin
  if FGraph <> nil then
    FGraph.Redo;
end;

procedure TNodeEditorController.ClearUndoRedo;
begin
  if FGraph <> nil then
    FGraph.ClearUndoRedo;
end;

procedure TNodeEditorController.DeleteSelection;
var
  i: integer;
  BeforeJSON, AfterJSON: string;
  NodeToRemove: TCustomNode;
  LinkToRemove: TNodeLink;
begin
  if (FGraph = nil) or (FSelection = nil) then
    Exit;

  if (FSelection.NodeCount = 0) and (not FSelection.HasLink) then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;

  if FSelection.HasLink then
  begin
    LinkToRemove := FSelection.SelectedLink;
    FGraph.RemoveLink(LinkToRemove);
  end
  else
  begin
    for i := FSelection.NodeCount - 1 downto 0 do
    begin
      NodeToRemove := FSelection.GetNode(i);
      FGraph.RemoveNode(NodeToRemove);
    end;
  end;

  FSelection.Clear;
  AfterJSON := FGraph.CaptureJSONText;
  FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Delete selection');
end;

procedure TNodeEditorController.CopySelectionToClipboard;
begin
  if (FGraph = nil) or (FSelection = nil) or (FSelection.NodeCount = 0) then
    Exit;

  Clipboard.AsText := FClipboard.NodesToJSONText(FSelection.FNodes, FGraph);
end;

procedure TNodeEditorController.PasteFromClipboard(AX, AY: single);
var
  BeforeJSON, AfterJSON: string;
begin
  if FGraph = nil then
    Exit;

  if Trim(Clipboard.AsText) = '' then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;
  FClipboard.PasteNodesFromJSONText(Clipboard.AsText, FGraph, AX, AY, FSelection);
  AfterJSON := FGraph.CaptureJSONText;

  FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Paste nodes');
end;

procedure TNodeEditorController.DuplicateSelection(AX, AY: single);
var
  BeforeJSON, AfterJSON: string;
  S: string;
begin
  if (FGraph = nil) or (FSelection = nil) or (FSelection.NodeCount = 0) then
    Exit;

  S := FClipboard.NodesToJSONText(FSelection.FNodes, FGraph);
  if Trim(S) = '' then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;
  FClipboard.PasteNodesFromJSONText(S, FGraph, AX, AY, FSelection);
  AfterJSON := FGraph.CaptureJSONText;

  FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Duplicate selection');
end;


// =============================================================================

procedure Register;
begin
  RegisterComponents('Custom', [TLazNodeEditor, TLazNodeInspector]);
end;

end.
