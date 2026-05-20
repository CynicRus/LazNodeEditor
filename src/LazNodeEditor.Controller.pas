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
