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
  Classes, SysUtils, Graphics, Types, fpjson, jsonparser, Math,
  Generics.Collections,
  GenericDAG,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.LinkRouter,
  LazNodeEditor.GraphIntf,
  LazNodeEditor.GraphCommandIntf,
  LazNodeEditor.GraphCommands,
  LazNodeEditor.SpatialIndex;

type
  TNodeGraph = class;

  TNodeDAG = specialize TObjectDAG<TCustomNode>;

  { TNodeGraph — MODEL}
type
  TNodeGraph = class(TNoRefCountObject, INodeGraphView, INodeGraphCommandHost)
  private
    FDefaultLinkDrawStyle: TLinkDrawStyle;
    FLinkRouter: TNodeLinkRouter;
    FNodes: TNodeDAG;
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

    FNodeById: specialize TDictionary<string, TCustomNode>;
    FLinkById: specialize TDictionary<string, TNodeLink>;

    FNodeIndex: TSimpleRTree;
    FLinkIndex: TSimpleRTree;
    FStructureVersion: QWord;
    FSpatialVersion: QWord;

    procedure DoGraphChanged;
    procedure RemoveLinksToInput(APin: TNodePin);

    function PinHasIncomingLink(APin: TNodePin): boolean;
    function PinHasOutgoingLink(APin: TNodePin): boolean;
    procedure PushExecutedCommand(ACommand: TGraphCommand);

    function HasLinksBetweenNodes(ANodeA, ANodeB: TCustomNode): boolean;
    class function CompareNodeById(const A, B: TCustomNode): integer; static;

    function GetDefaultLinkDrawStyle: TLinkDrawStyle;
    function GetNodeCount: integer;
    function GetNode(AIndex: integer): TCustomNode;

    function GetNodeWorldBounds(ANode: TCustomNode): TRectF;
    function GetLinkWorldBounds(ALink: TNodeLink): TRectF;
    procedure InvalidateSpatial;
    procedure EnsureSpatialIndex;
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
    function NodesContains(ANode: TCustomNode): boolean;
    function GetNodeRegistry(): TNodeRegistry;

    function CheckInvariants(AErrors: TStrings = nil): boolean;
    function IsNodeIdUnique(const AId: string; AExcept: TCustomNode = nil): boolean;
    function IsPinIdUnique(const AId: string; AExcept: TNodePin = nil): boolean;

    function AddDynamicInputPin(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function AddDynamicOutputPin(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function RemoveDynamicPin(APin: TNodePin): boolean;

    function FindNodeById(const AId: string): TCustomNode;
    function FindPinById(const AId: string): TNodePin;
    function FindLinkById(const AId: string): TNodeLink;
    function CanConnect(P1, P2: TNodePin): boolean;
    function LinkExists(FromPin, ToPin: TNodePin): boolean;
    function GetLinks: TNodeLinkList;

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
    procedure LoadGraphFromJSONText(const S: string);
    procedure GraphChanged;

    function NextZOrder: integer;
    procedure BringNodeToFront(ANode: TCustomNode);
    procedure SendNodeToBack(ANode: TCustomNode);

    function StructureVersion: QWord;
    function QueryNodes(const R: TRectF; AList: TFPList): integer;
    function QueryLinks(const R: TRectF; AList: TFPList): integer;
    function QueryNodesAtPoint(const P: TPointF; Radius: single; AList: TFPList): integer;
    function QueryLinksAtPoint(const P: TPointF; Radius: single; AList: TFPList): integer;
    procedure NotifyNodeGeometryChanged(ANode: TCustomNode);
    procedure NotifyLinkGeometryChanged(ALink: TNodeLink);

    property Nodes: TNodeDAG read FNodes;
    property Links: TNodeLinkList read FLinks;
    property Registry: TNodeRegistry read FRegistry;
    property DefaultLinkDrawStyle: TLinkDrawStyle
      read FDefaultLinkDrawStyle write FDefaultLinkDrawStyle;
    property LinkRouter: TNodeLinkRouter read FLinkRouter;
    property OnNodeAdded: TGraphNodeEvent read FOnNodeAdded write FOnNodeAdded;
    property OnNodeRemoved: TGraphNodeEvent read FOnNodeRemoved write FOnNodeRemoved;
    property OnLinkAdded: TGraphLinkEvent read FOnLinkAdded write FOnLinkAdded;
    property OnLinkRemoved: TGraphLinkEvent read FOnLinkRemoved write FOnLinkRemoved;
    property OnGraphChanged: TGraphChangedEvent
      read FOnGraphChanged write FOnGraphChanged;
  end;


function NodePaintCompare(Item1, Item2: Pointer): integer;
procedure BuildSortedNodeList(AGraph: TNodeGraph; AList: TList);

implementation

function NodePaintCompare(Item1, Item2: Pointer): integer;
var
  A, B: TCustomNode;
begin
  A := TCustomNode(Item1);
  B := TCustomNode(Item2);
  if A.Selected and not B.Selected then
    Result := 1
  else if not A.Selected and B.Selected then
    Result := -1
  else if (A.ZOrder < B.ZOrder) then
    Result := -1
  else if (A.ZOrder > B.ZOrder) then
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
  FNodes := TNodeDAG.Create(True);
  FLinks := TNodeLinkList.Create(True);
  FRegistry := TNodeRegistry.Create;
  FUndoStack := TGraphCommandList.Create(True);
  FRedoStack := TGraphCommandList.Create(True);

  FDefaultLinkDrawStyle := ldsBezier;
  FLinkRouter := TNodeLinkRouter.Create(Self);

  FNodeById := specialize TDictionary<string, TCustomNode>.Create;
  FLinkById := specialize TDictionary<string, TNodeLink>.Create;

  FNodeIndex := TSimpleRTree.Create(16);
  FLinkIndex := TSimpleRTree.Create(16);
  FStructureVersion := 1;
  FSpatialVersion := 0;

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
  FLinkRouter.Free;
  FLinks.Free;
  FNodes.Free;
  FNodeById.Free;
  FLinkById.Free;
  FNodeIndex.Free;
  FLinkIndex.Free;
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

  if FNodes.Contains(ANode) then
    Exit;

  if ANode.ZOrder = 0 then
    ANode.ZOrder := NextZOrder;

  FNodes.Add(ANode);
  if Assigned(FNodeById) then
    FNodeById.AddOrSetValue(ANode.Id, ANode);

  InvalidateSpatial;

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

  if not FNodes.Contains(ANode) then
    Exit;

  if Assigned(FNodeById) then
    FNodeById.Remove(ANode.Id);

  for i := FLinks.Count - 1 downto 0 do
  begin
    L := FLinks[i];

    if (((L.FromPin <> nil) and (L.FromPin.OwnerNode = ANode)) or
      ((L.ToPin <> nil) and (L.ToPin.OwnerNode = ANode))) then
    begin
      if Assigned(FOnLinkRemoved) then
        FOnLinkRemoved(Self, L);
      if Assigned(FLinkById) then
        FLinkById.Remove(L.Id);
      FLinks.Delete(i);
    end;
  end;

  if Assigned(FOnNodeRemoved) then
    FOnNodeRemoved(Self, ANode);

  FNodes.Remove(ANode);

  InvalidateSpatial;

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

  if Assigned(FNodeById) then
    FNodeById.Remove(ANode.Id);

  for i := FLinks.Count - 1 downto 0 do
  begin
    L := FLinks[i];

    if (((L.FromPin <> nil) and (L.FromPin.OwnerNode = ANode)) or
      ((L.ToPin <> nil) and (L.ToPin.OwnerNode = ANode))) then
    begin
      if Assigned(FOnLinkRemoved) then
        FOnLinkRemoved(Self, L);

      if Assigned(FLinkById) then
        FLinkById.Remove(L.Id);
      FLinks.Delete(i);
    end;
  end;

  if Assigned(FOnNodeRemoved) then
    FOnNodeRemoved(Self, ANode);

  FNodes.Remove(ANode);

  InvalidateSpatial;

  DoGraphChanged;
end;

procedure TNodeGraph.AddLink(ALink: TNodeLink);
var
  OutPin, InPin: TNodePin;
  OutNode, InNode: TCustomNode;
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

  OutNode := TCustomNode(OutPin.OwnerNode);
  InNode := TCustomNode(InPin.OwnerNode);

  if LinkExists(OutPin, InPin) then
  begin
    ALink.Free;
    Exit;
  end;

  if not InPin.AllowMultipleConnections then
    RemoveLinksToInput(InPin);

  if FNodes.Contains(OutNode) and FNodes.Contains(InNode) then
  begin
    if not FNodes.HasEdge(OutNode, InNode) then
    begin
      if FNodes.CanCreateCycle(OutNode, InNode) then
      begin
        ALink.Free;
        Exit;
      end;
      FNodes.AddEdge(OutNode, InNode);
    end;
  end;

  FLinks.Add(ALink);
  if Assigned(FLinkById) then
    FLinkById.AddOrSetValue(ALink.Id, ALink);

  InvalidateSpatial;

  if Assigned(FOnLinkAdded) then
    FOnLinkAdded(Self, ALink);

  DoGraphChanged;
end;

procedure TNodeGraph.RemoveLink(ALink: TNodeLink);
var
  NFrom, NTo: TCustomNode;
begin
  if ALink = nil then
    Exit;

  NFrom := nil;
  NTo := nil;

  if (ALink.FromPin <> nil) and (ALink.FromPin.OwnerNode <> nil) then
    NFrom := TCustomNode(ALink.FromPin.OwnerNode);

  if (ALink.ToPin <> nil) and (ALink.ToPin.OwnerNode <> nil) then
    NTo := TCustomNode(ALink.ToPin.OwnerNode);

  if Assigned(FOnLinkRemoved) then
    FOnLinkRemoved(Self, ALink);

  if Assigned(FLinkById) and (ALink <> nil) then
    FLinkById.Remove(ALink.Id);
  if FLinks.Remove(ALink) >= 0 then
  begin
    if (NFrom <> nil) and (NTo <> nil) then
    begin
      if not HasLinksBetweenNodes(NFrom, NTo) then
        FNodes.RemoveEdge(NFrom, NTo);
    end;
    DoGraphChanged;
  end;

  InvalidateSpatial;
end;

function TNodeGraph.NodesContains(ANode: TCustomNode): boolean;
begin
  Result := FNodes.Contains(ANode);
end;

function TNodeGraph.GetNodeRegistry(): TNodeRegistry;
begin
  result := self.Registry;
end;

function TNodeGraph.HasLinksBetweenNodes(ANodeA, ANodeB: TCustomNode): boolean;
var
  i: integer;
  L: TNodeLink;
  OwnerA, OwnerB: TCustomNode;
begin
  Result := False;
  if (ANodeA = nil) or (ANodeB = nil) then Exit;

  for i := 0 to FLinks.Count - 1 do
  begin
    L := FLinks[i];
    if (L.FromPin = nil) or (L.ToPin = nil) then Continue;

    OwnerA := TCustomNode(L.FromPin.OwnerNode);
    OwnerB := TCustomNode(L.ToPin.OwnerNode);

    if (OwnerA = ANodeA) and (OwnerB = ANodeB) then
      Exit(True);
  end;
end;

class function TNodeGraph.CompareNodeById(const A, B: TCustomNode): integer;
begin
  if A = B then
    Exit(0);
  if A = nil then
    Exit(-1);
  if B = nil then
    Exit(1);
  Result := CompareText(A.Id, B.Id);
end;

function TNodeGraph.GetDefaultLinkDrawStyle: TLinkDrawStyle;
begin
  Result := FDefaultLinkDrawStyle;
end;

function TNodeGraph.GetNodeCount: integer;
begin
  Result := FNodes.Count;
end;

function TNodeGraph.GetNode(AIndex: integer): TCustomNode;
begin
  Result := FNodes[AIndex];
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
        (not FNodes.Contains(TCustomNode(L.FromPin.OwnerNode)))) then
        AddError('Link FromPin points to pin outside graph.');

      if (L.ToPin <> nil) and ((L.ToPin.OwnerNode = nil) or
        (not FNodes.Contains(TCustomNode(L.ToPin.OwnerNode)))) then
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
begin
  Result := nil;
  if (AId = '') or (FNodeById = nil) then
    Exit;
  FNodeById.TryGetValue(AId, Result);
end;

function TNodeGraph.FindPinById(const AId: string): TNodePin;
var
  i: integer;
  N: TCustomNode;
begin
  Result := nil;
  for i := 0 to FNodes.Count - 1 do
  begin
    N := FNodes[i];
    Result := N.FindPinById(AId);
    if Result <> nil then Exit;
  end;
end;

function TNodeGraph.FindLinkById(const AId: string): TNodeLink;
begin
  Result := nil;
  if (AId = '') or (FLinkById = nil) then
    Exit;
  FLinkById.TryGetValue(AId, Result);
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
    L := FLinks[i];
    if (L.FromPin = AFrom) and (L.ToPin = ATo) then
      Exit(True);
  end;
end;

function TNodeGraph.GetLinks: TNodeLinkList;
begin
  result := FLinks;
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
    L := FLinks[i];
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
    L := FLinks[i];
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
  FNodes.Clear; // TDAG.Clear
  if Assigned(FNodeById) then
    FNodeById.Clear;
  if Assigned(FLinkById) then
    FLinkById.Clear;

  InvalidateSpatial;
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

procedure TNodeGraph.LoadGraphFromJSONText(const S: string);
var
  Data: TJSONData;
begin
  if Trim(S) = '' then
    Exit;

  Data := GetJSON(S);
  try
    if Data.JSONType = jtObject then
      LoadGraphFromJSON(TJSONObject(Data));
  finally
    Data.Free;
  end;
end;

procedure TNodeGraph.GraphChanged;
begin
  DoGraphChanged;
end;

function TNodeGraph.NextZOrder: integer;
var
  i: integer;
  N: TCustomNode;
begin
  Result := 1;

  for i := 0 to FNodes.Count - 1 do
  begin
    N := FNodes[i];
    Result := Max(Result, N.ZOrder + 1);
  end;
end;

procedure TNodeGraph.BringNodeToFront(ANode: TCustomNode);
begin
  if ANode = nil then
    Exit;

  ANode.ZOrder := NextZOrder;
  InvalidateSpatial;
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
    N := FNodes[i];
    if N <> ANode then
      Inc(N.ZOrder);
  end;

  InvalidateSpatial;
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
      N := FNodes[i];
      NodeObj := TJSONObject.Create;
      N.SaveToJSON(NodeObj);
      NodesArr.Add(NodeObj);
    end;
    Result.Add('nodes', NodesArr);

    LinksArr := TJSONArray.Create;
    for i := 0 to FLinks.Count - 1 do
    begin
      L := FLinks[i];
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
        if Assigned(FNodeById) then
          FNodeById.AddOrSetValue(N.Id, N);
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
          // AddLink handles FLinks and FNodes sync
          AddLink(L);
        end;
      end;
      //NormalizeGraph;
    end;

  finally
    EndUpdate;
    DoGraphChanged;
  end;

  InvalidateSpatial;
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
    L := FLinks[i];

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
    N := FNodes[i];

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
begin
  // Используем встроенную проверку DAG
  Result := not FNodes.IsAcyclic;
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
    L := FLinks[i];
    if (L.FromPin = APin) or (L.ToPin = APin) then
      FLinks.Delete(i);
  end;

  Result := N.RemovePin(APin);

  AfterJSON := CaptureJSONText;
  ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Remove pin');

  DoGraphChanged;
end;

function TNodeGraph.GetNodeWorldBounds(ANode: TCustomNode): TRectF;
begin
  if ANode = nil then
    Exit(RectF(0, 0, 0, 0));
  Result := RectF(ANode.X, ANode.Y, ANode.X + ANode.Width, ANode.Y + ANode.Height);
end;

function TNodeGraph.GetLinkWorldBounds(ALink: TNodeLink): TRectF;
var
  Path: TLinkPath;
  i, k: integer;
  P: TPointF;

  procedure IncludePoint(const AP: TPointF);
  begin
    if AP.X < Result.Left then Result.Left := AP.X;
    if AP.Y < Result.Top then Result.Top := AP.Y;
    if AP.X > Result.Right then Result.Right := AP.X;
    if AP.Y > Result.Bottom then Result.Bottom := AP.Y;
  end;

begin
  Result := RectF(0, 0, 0, 0);

  if (ALink = nil) or (FLinkRouter = nil) then
    Exit;

  Path := FLinkRouter.GetPaintPath(ALink);
  if Length(Path.Points) = 0 then
    Exit;

  if Path.Kind = lpkBezier then
  begin
    if Length(Path.Points) < 4 then
      Exit;

    P := Path.Points[0];
    Result := RectF(P.X, P.Y, P.X, P.Y);

    for k := 1 to 24 do
      IncludePoint(CubicBezierPointF(
        Path.Points[0], Path.Points[1], Path.Points[2], Path.Points[3], k / 24
      ));
  end
  else
  begin
    Result := RectF(Path.Points[0].X, Path.Points[0].Y, Path.Points[0].X, Path.Points[0].Y);
    for i := 1 to High(Path.Points) do
    begin
      P := Path.Points[i];
      IncludePoint(P);
    end;
  end;

  InflateRect(Result, 12.0, 12.0);
end;

procedure TNodeGraph.InvalidateSpatial;
begin
  Inc(FStructureVersion);
  if Assigned(FLinkRouter) then
    FLinkRouter.InvalidateCache;
end;

procedure TNodeGraph.EnsureSpatialIndex;
var
  i: integer;
begin
  if FSpatialVersion = FStructureVersion then
    Exit;

  FNodeIndex.Clear;
  for i := 0 to FNodes.Count - 1 do
    FNodeIndex.Add(FNodes[i], GetNodeWorldBounds(FNodes[i]));
  FNodeIndex.Rebuild;

  FLinkIndex.Clear;
  for i := 0 to FLinks.Count - 1 do
    FLinkIndex.Add(FLinks[i], GetLinkWorldBounds(FLinks[i]));
  FLinkIndex.Rebuild;

  FSpatialVersion := FStructureVersion;
end;

function TNodeGraph.StructureVersion: QWord;
begin
  Result := FStructureVersion;
end;

function TNodeGraph.QueryNodes(const R: TRectF; AList: TFPList): integer;
begin
  Result := 0;
  if AList = nil then
    Exit;
  EnsureSpatialIndex;
  AList.Clear;
  FNodeIndex.Query(R, AList);
  Result := AList.Count;
end;

function TNodeGraph.QueryLinks(const R: TRectF; AList: TFPList): integer;
begin
  Result := 0;
  if AList = nil then
    Exit;
  EnsureSpatialIndex;
  AList.Clear;
  FLinkIndex.Query(R, AList);
  Result := AList.Count;
end;

function TNodeGraph.QueryNodesAtPoint(const P: TPointF; Radius: single;
  AList: TFPList): integer;
begin
  Result := QueryNodes(RectF(P.X - Radius, P.Y - Radius, P.X + Radius, P.Y + Radius), AList);
end;

function TNodeGraph.QueryLinksAtPoint(const P: TPointF; Radius: single;
  AList: TFPList): integer;
begin
  Result := QueryLinks(RectF(P.X - Radius, P.Y - Radius, P.X + Radius, P.Y + Radius), AList);
end;

procedure TNodeGraph.NotifyNodeGeometryChanged(ANode: TCustomNode);
begin
  InvalidateSpatial;
  if Assigned(FLinkRouter) then
    FLinkRouter.InvalidateCache;
end;

procedure TNodeGraph.NotifyLinkGeometryChanged(ALink: TNodeLink);
begin
  InvalidateSpatial;
  if Assigned(FLinkRouter) then
    FLinkRouter.InvalidateCache;
end;

end.
