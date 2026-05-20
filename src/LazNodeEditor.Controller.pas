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
unit LazNodeEditor.Controller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, StdCtrls, Controls, Clipbrd, LazUTF8, LCLType,
  fpjson, jsonparser,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph;

type

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

    procedure AddNode(ANode: TCustomNode);
    procedure RemoveNode(ANode: TCustomNode);
    procedure RemoveLink(ALink: TNodeLink);
    procedure Clear;

    procedure DeleteSelection;
    procedure CopySelectionToClipboard;
    procedure PasteFromClipboard(AX, AY: single);
    procedure DuplicateSelection(AX, AY: single);

    function SaveToJSONText(AZoom: double; AOffsetX, AOffsetY: integer): string;
    procedure LoadFromJSONText(const S: string; out AZoom: double;
      out AOffsetX, AOffsetY: integer);
    procedure SaveToFile(const AFileName: string; AZoom: double;
      AOffsetX, AOffsetY: integer);
    procedure LoadFromFile(const AFileName: string; out AZoom: double;
      out AOffsetX, AOffsetY: integer);

    function ValidateGraphToStrings(AStrings: TStrings): boolean;

    function AddInputPinToNode(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function AddOutputPinToNode(ANode: TCustomNode; const AName, ADataType: string;
      AKind: TPinKind = pkData): TNodePin;
    function RemovePinFromNode(APin: TNodePin): boolean;

    function CreateCompatibleNodeForPin(APin: TNodePin; AX, AY: single): TCustomNode;

    function InsertRerouteOnLink(ALink: TNodeLink; AX, AY: single): TCustomNode;
    function AddCommentNode(AX, AY: single): TCustomNode;

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

implementation

{ TNodeEditorController }

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

procedure TNodeEditorController.AddNode(ANode: TCustomNode);
begin
  if (FGraph = nil) or (ANode = nil) then
    Exit;

  FGraph.ExecuteCommand(TAddNodeCommand.Create(FGraph, ANode));
end;

procedure TNodeEditorController.RemoveNode(ANode: TCustomNode);
var
  BeforeJSON, AfterJSON: string;
begin
  if (FGraph = nil) or (ANode = nil) then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;

  if FSelection <> nil then
    FSelection.RemoveNode(ANode);

  FGraph.RemoveNode(ANode);

  AfterJSON := FGraph.CaptureJSONText;
  FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Remove node');
end;

procedure TNodeEditorController.RemoveLink(ALink: TNodeLink);
begin
  if (FGraph = nil) or (ALink = nil) then
    Exit;

  if FSelection <> nil then
    FSelection.RemoveLinkFromSelection(ALink);

  FGraph.ExecuteCommand(TRemoveLinkCommand.Create(FGraph, ALink));
end;

procedure TNodeEditorController.Clear;
begin
  if FGraph = nil then
    Exit;

  FGraph.Clear;

  if FSelection <> nil then
    FSelection.Clear;
end;

function TNodeEditorController.SaveToJSONText(AZoom: double; AOffsetX,
  AOffsetY: integer): string;
var
  Root: TJSONObject;
  GraphObj: TJSONObject;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('version', 2);
    Root.Add('zoom', AZoom);
    Root.Add('offsetX', AOffsetX);
    Root.Add('offsetY', AOffsetY);

    GraphObj := FGraph.SaveGraphToJSON;
    Root.Add('graph', GraphObj);

    Result := Root.AsJSON;
  finally
    Root.Free;
  end;
end;

procedure TNodeEditorController.LoadFromJSONText(const S: string; out AZoom: double;
  out AOffsetX, AOffsetY: integer);
var
  Data: TJSONData;
  Root: TJSONObject;
  GraphObj: TJSONObject;
  BeforeJSON, AfterJSON: string;
begin
  AZoom := 1.0;
  AOffsetX := 0;
  AOffsetY := 0;

  if (FGraph = nil) or (Trim(S) = '') then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;

  Data := GetJSON(S);
  try
    Root := TJSONObject(Data);

    AZoom := Root.Get('zoom', 1.0);
    AOffsetX := Root.Get('offsetX', 0);
    AOffsetY := Root.Get('offsetY', 0);

    GraphObj := Root.Objects['graph'];
    if GraphObj <> nil then
      FGraph.LoadGraphFromJSON(GraphObj);

    AfterJSON := FGraph.CaptureJSONText;
    FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Load graph');

    if FSelection <> nil then
      FSelection.Clear;
  finally
    Data.Free;
  end;
end;

procedure TNodeEditorController.SaveToFile(const AFileName: string; AZoom: double;
  AOffsetX, AOffsetY: integer);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := SaveToJSONText(AZoom, AOffsetX, AOffsetY);
    SL.SaveToFile(AFileName);
  finally
    SL.Free;
  end;
end;

procedure TNodeEditorController.LoadFromFile(const AFileName: string; out AZoom: double;
  out AOffsetX, AOffsetY: integer);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    LoadFromJSONText(SL.Text, AZoom, AOffsetX, AOffsetY);
  finally
    SL.Free;
  end;
end;

function TNodeEditorController.ValidateGraphToStrings(AStrings: TStrings): boolean;
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

function TNodeEditorController.AddInputPinToNode(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
begin
  Result := nil;

  if (FGraph = nil) or (ANode = nil) then
    Exit;

  Result := FGraph.AddDynamicInputPin(ANode, AName, ADataType, AKind);
end;

function TNodeEditorController.AddOutputPinToNode(ANode: TCustomNode;
  const AName, ADataType: string; AKind: TPinKind): TNodePin;
begin
  Result := nil;

  if (FGraph = nil) or (ANode = nil) then
    Exit;

  Result := FGraph.AddDynamicOutputPin(ANode, AName, ADataType, AKind);
end;

function TNodeEditorController.RemovePinFromNode(APin: TNodePin): boolean;
begin
  Result := False;

  if (FGraph = nil) or (APin = nil) then
    Exit;

  Result := FGraph.RemoveDynamicPin(APin);
end;

function TNodeEditorController.CreateCompatibleNodeForPin(APin: TNodePin;
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
          if FGraph.CanConnect(TestPin, APin) then
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

function TNodeEditorController.InsertRerouteOnLink(ALink: TNodeLink;
  AX, AY: single): TCustomNode;
var
  BeforeJSON, AfterJSON: string;
begin
  Result := nil;

  if (FGraph = nil) or (ALink = nil) then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;
  Result := FGraph.CreateRerouteForLink(ALink, AX, AY);
  AfterJSON := FGraph.CaptureJSONText;

  FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Insert reroute');

  if FSelection <> nil then
  begin
    FSelection.Clear;
    if Result <> nil then
      FSelection.SelectNode(Result, False);
  end;
end;

function TNodeEditorController.AddCommentNode(AX, AY: single): TCustomNode;
begin
  Result := nil;

  if FGraph = nil then
    Exit;

  Result := FGraph.Registry.CreateNode('comment', AX, AY);
  if Result <> nil then
  begin
    AddNode(Result);

    if FSelection <> nil then
    begin
      FSelection.Clear;
      FSelection.SelectNode(Result, False);
    end;
  end;
end;

procedure TNodeEditorController.DeleteSelection;
var
  i: integer;
  BeforeJSON, AfterJSON: string;
  NodeToRemove: TCustomNode;
  LinkToRemove: TNodeLink;
  LinksToDelete: TNodeLinkList;
begin
  if (FGraph = nil) or (FSelection = nil) then
    Exit;

  if (FSelection.NodeCount = 0) and (FSelection.LinkCount = 0) then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;
  LinksToDelete := TNodeLinkList.Create(False);
  try
    for i := 0 to FSelection.LinkCount - 1 do
    begin
      LinkToRemove := FSelection.GetLink(i);
      if LinkToRemove <> nil then
        LinksToDelete.Add(LinkToRemove);
    end;

    for i := LinksToDelete.Count - 1 downto 0 do
      FGraph.RemoveLink(LinksToDelete[i]);

    for i := FSelection.NodeCount - 1 downto 0 do
    begin
      NodeToRemove := FSelection.GetNode(i);
      if NodeToRemove <> nil then
        FGraph.RemoveNode(NodeToRemove);
    end;

    FSelection.Clear;
    AfterJSON := FGraph.CaptureJSONText;
    FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Delete selection');
  finally
    LinksToDelete.Free;
  end;
end;

procedure TNodeEditorController.CopySelectionToClipboard;
begin
  if (FGraph = nil) or (FSelection = nil) or (FSelection.NodeCount = 0) then
    Exit;

  Clipboard.AsText := FClipboard.NodesToJSONText(FSelection.Nodes, FGraph);
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

  S := FClipboard.NodesToJSONText(FSelection.Nodes, FGraph);
  if Trim(S) = '' then
    Exit;

  BeforeJSON := FGraph.CaptureJSONText;
  FClipboard.PasteNodesFromJSONText(S, FGraph, AX, AY, FSelection);
  AfterJSON := FGraph.CaptureJSONText;

  FGraph.ExecuteJSONSnapshotCommand(BeforeJSON, AfterJSON, 'Duplicate selection');
end;

{ TNodeSearchForm }

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

end.
