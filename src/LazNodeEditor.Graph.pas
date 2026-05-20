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
unit LazNodeEditor.Graph;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, fpjson, jsonparser, math,
  Generics.Collections,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes;

type
  TNodeGraph = class;
  TGraphCommand = class;


  TCustomNodeList = specialize TObjectList<TCustomNode>;
  TNodeLinkList = specialize TObjectList<TNodeLink>;
  TGraphCommandList = specialize TObjectList<TGraphCommand>;

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
    property Nodes: TCustomNodeList read FNodes;
  end;

  { TNodeClipboardService }
  TNodeClipboardService = class
  public
    function NodesToJSONText(ANodes: TCustomNodeList; AGraph: TNodeGraph): string;
    procedure PasteNodesFromJSONText(const AJSON: string; AGraph: TNodeGraph;
      AX, AY: single; ASelection: TNodeSelectionModel);
  end;


function NodePaintCompare(Item1, Item2: Pointer): integer;
procedure BuildSortedNodeList(AGraph: TNodeGraph; AList: TList);
procedure LoadGraphFromJSONText(AGraph: TNodeGraph; const S: string);

implementation

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

{ TNodeGraph }

constructor TNodeGraph.Create;
begin
  inherited Create;
  FNodes := TCustomNodeList.Create(True);
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
        (FNodes.IndexOf(TCustomNode(L.FromPin.OwnerNode)) < 0)) then
        AddError('Link FromPin points to pin outside graph.');

      if (L.ToPin <> nil) and ((L.ToPin.OwnerNode = nil) or
        (FNodes.IndexOf(TCustomNode(L.ToPin.OwnerNode)) < 0)) then
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

      if (FNodes.IndexOf(TCustomNode(L.FromPin.OwnerNode)) < 0) or
        (FNodes.IndexOf(TCustomNode(L.ToPin.OwnerNode)) < 0) then
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

        N := FRegistry.CreateNode(NodeType, NodeObj.Get('x', 0.0),
          NodeObj.Get('y', 0.0));
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
        NextNode := TCustomNode(L.ToPin.OwnerNode);

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

  N := TCustomNode(APin.OwnerNode);
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

{ Commands }

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

{ TNodeSelectionModel }

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

{ TNodeClipboardService }

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
      if (ANodes.IndexOf(TCustomNode(L.FromPin.OwnerNode)) >= 0) and
        (ANodes.IndexOf(TCustomNode(L.ToPin.OwnerNode)) >= 0) then
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

end.
