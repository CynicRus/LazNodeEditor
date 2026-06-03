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
unit LazNodeEditor.ClipboardService;

{$mode objfpc}{$H+}

interface

uses
  Generics.Collections, Classes, SysUtils, fpjson, jsonparser, math,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Selection;

type

  { TNodeClipboardService }
  TNodeClipboardService = class
  public
    function NodesToJSONText(ANodes: TList; AGraph: TNodeGraph): string;
    procedure PasteNodesFromJSONText(const AJSON: string; AGraph: TNodeGraph;
      AX, AY: single; ASelection: TNodeSelectionModel);
  end;


implementation

{ TNodeClipboardService }

function TNodeClipboardService.NodesToJSONText(ANodes: TList; AGraph: TNodeGraph): string;
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
      N := TCustomNode(ANodes[i]);
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
