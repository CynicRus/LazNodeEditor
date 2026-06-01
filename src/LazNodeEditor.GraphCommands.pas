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
unit LazNodeEditor.GraphCommands;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, fpjson, jsonparser, Math,
  Generics.Collections,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.GraphCommandIntf;

type


  { TGraphCommand }

  TGraphCommand = class
  protected
    FGraph: INodeGraphCommandHost;
    FDescription: string;
  public
    constructor Create(AGraph: INodeGraphCommandHost;
      const ADescription: string = ''); virtual;
    destructor Destroy; override;

    procedure DoExecute; virtual; abstract;
    procedure Undo; virtual; abstract;

    property Description: string read FDescription;
  end;

  TGraphCommandList = specialize TObjectList<TGraphCommand>;


  { TJSONSnapshotCommand }

  TJSONSnapshotCommand = class(TGraphCommand)
  private
    FBeforeJSON: string;
    FAfterJSON: string;
  public
    constructor Create(AGraph: INodeGraphCommandHost; const ABeforeJSON,
      AAfterJSON: string; const ADescription: string = 'Snapshot'); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TAddNodeCommand }

  TAddNodeCommand = class(TGraphCommand)
  private
    FNode: TCustomNode;
    FOwnsNode: boolean;
  public
    constructor Create(AGraph: INodeGraphCommandHost; ANode: TCustomNode); reintroduce;
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
    constructor Create(AGraph: INodeGraphCommandHost; ANode: TCustomNode); reintroduce;

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
    constructor Create(AGraph: INodeGraphCommandHost; AFromPin, AToPin: TNodePin); reintroduce;

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
    constructor Create(AGraph: INodeGraphCommandHost; ALink: TNodeLink); reintroduce;

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
    constructor Create(AGraph: INodeGraphCommandHost; ANodes: TCustomNodeList;
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
    constructor Create(AGraph: INodeGraphCommandHost; ANode: TCustomNode;
      AOldWidth, AOldHeight, ANewWidth, ANewHeight: integer); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  TReconnectLinkCommand = class(TGraphCommand)
  private
    FOldPinId: string;
    FNewPinId: string;
    FLinkId: string;
    FFrom: boolean;
  public
    constructor Create(AGraph: INodeGraphCommandHost; ALink: TNodeLink;
      AOldPin, ANewPin: TNodePin); reintroduce;

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
    constructor Create(AGraph: INodeGraphCommandHost; ANode: TCustomNode;
      const AOldNodeJSON, ANewNodeJSON: string); reintroduce;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

procedure LoadGraphFromJSONText(AGraph: INodeGraphCommandHost; const S: string);
procedure ApplyNodePropertiesFromJSON(ANode: TCustomNode; AObj: TJSONObject);

implementation

procedure LoadGraphFromJSONText(AGraph: INodeGraphCommandHost; const S: string);
begin
  if AGraph = nil then
    Exit;
  if Trim(S) = '' then
    Exit;
  AGraph.LoadGraphFromJSONText(S);
end;

procedure ApplyNodePropertiesFromJSON(ANode: TCustomNode; AObj: TJSONObject);
var
  i: integer;
  ValuesArr: TJSONArray;
  VObj: TJSONObject;
  V: TNodeValue;
  S: string;
begin
  if (ANode = nil) or (AObj = nil) then
    Exit;

  ANode.Title := AObj.Get('title', ANode.Title);
  ANode.X := AObj.Get('x', ANode.X);
  ANode.Y := AObj.Get('y', ANode.Y);
  ANode.Width := AObj.Get('width', ANode.Width);
  ANode.Height := AObj.Get('height', ANode.Height);
  ANode.HeaderColor := TColor(AObj.Get('headerColor', integer(ANode.HeaderColor)));
  ANode.BodyColor := TColor(AObj.Get('bodyColor', integer(ANode.BodyColor)));
  ANode.Collapsed := AObj.Get('collapsed', ANode.Collapsed);
  ANode.CommentText := AObj.Get('comment', ANode.CommentText);

  ValuesArr := AObj.Arrays['values'];
  if ValuesArr <> nil then
  begin
    for i := 0 to Min(ANode.ValueCount, ValuesArr.Count) - 1 do
    begin
      V := ANode.GetValue(i);
      VObj := ValuesArr.Objects[i];
      if (V = nil) or (VObj = nil) then
        Continue;

      case V.Kind of
        nvkFloat:   V.FloatValue := VObj.Get('value', V.FloatValue);
        nvkInteger: V.IntegerValue := VObj.Get('value', V.IntegerValue);
        nvkString:  V.StringValue := VObj.Get('value', V.StringValue);
        nvkBoolean: V.BooleanValue := VObj.Get('value', V.BooleanValue);
        nvkJSON:
          begin
            S := VObj.Get('value', V.JSONValue);
            V.JSONValue := S;
          end;
      end;
    end;
  end;
end;

constructor TGraphCommand.Create(AGraph: INodeGraphCommandHost;
  const ADescription: string);
begin
  inherited Create;
  FGraph := AGraph;
  FDescription := ADescription;
end;

destructor TGraphCommand.Destroy;
begin
  inherited Destroy;
end;

constructor TJSONSnapshotCommand.Create(AGraph: INodeGraphCommandHost;
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

constructor TAddNodeCommand.Create(AGraph: INodeGraphCommandHost;
  ANode: TCustomNode);
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

  if not FGraph.NodesContains(FNode) then
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

constructor TRemoveNodeCommand.Create(AGraph: INodeGraphCommandHost;
  ANode: TCustomNode);
begin
  inherited Create(AGraph, 'Remove node');

  if ANode <> nil then
    FNodeId := ANode.Id;

  if AGraph <> nil then
    FGraphBeforeJSON := AGraph.CaptureJSONText;

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

constructor TAddLinkCommand.Create(AGraph: INodeGraphCommandHost; AFromPin,
  AToPin: TNodePin);
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
  Links: specialize TObjectList<TNodeLink>;
begin
  if FGraph = nil then
    Exit;

  Links := FGraph.GetLinks;
  for i := Links.Count - 1 downto 0 do
  begin
    L := Links[i];
    if L.Id = FLinkId then
    begin
      FGraph.RemoveLink(L);
      Break;
    end;
  end;
end;

constructor TRemoveLinkCommand.Create(AGraph: INodeGraphCommandHost;
  ALink: TNodeLink);
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
  Links: specialize TObjectList<TNodeLink>;
begin
  if FGraph = nil then
    Exit;

  Links := FGraph.GetLinks;
  for i := Links.Count - 1 downto 0 do
  begin
    L := Links[i];
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

constructor TMoveNodesCommand.Create(AGraph: INodeGraphCommandHost;
  ANodes: TCustomNodeList; const AOldPositions, ANewPositions: array of TPointF
  );
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

  FGraph.GraphChanged;
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

  FGraph.GraphChanged;
end;

constructor TResizeNodeCommand.Create(AGraph: INodeGraphCommandHost;
  ANode: TCustomNode; AOldWidth, AOldHeight, ANewWidth, ANewHeight: integer);
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
  FGraph.GraphChanged;
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
  FGraph.GraphChanged;
end;

constructor TReconnectLinkCommand.Create(AGraph: INodeGraphCommandHost; ALink: TNodeLink;
  AOldPin, ANewPin: TNodePin);
begin
  inherited Create(AGraph, 'Reconnect link');

  if (ALink = nil) or (AOldPin = nil) or (ANewPin = nil) then
    Exit;

  FFrom := ALink.FromPin = AOldPin;
  FOldPinId := AOldPin.Id;
  FNewPinId := ANewPin.Id;
  FLinkId := ALink.Id;
end;

procedure TReconnectLinkCommand.DoExecute;
var
  NewPin: TNodePin;
  L: TNodeLink;
begin
  if FGraph = nil then
    Exit;

  NewPin := FGraph.FindPinById(FNewPinId);
  if NewPin = nil then
    Exit;

  L := FGraph.FindLinkById(FLinkId);
  if L = nil then
    Exit;

  if FFrom then
    L.FromPin := NewPin
  else
    L.ToPin := NewPin;

  FGraph.GraphChanged;
end;

procedure TReconnectLinkCommand.Undo;
var
  OldPin: TNodePin;
  L: TNodeLink;
begin
  if FGraph = nil then
    Exit;

  OldPin := FGraph.FindPinById(FOldPinId);
  if OldPin = nil then
    Exit;

  L := FGraph.FindLinkById(FLinkId);
  if L = nil then
    Exit;

  if FFrom then
    L.FromPin := OldPin
  else
    L.ToPin := OldPin;

  FGraph.GraphChanged;
end;

constructor TChangeNodePropertyCommand.Create(AGraph: INodeGraphCommandHost;
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
    if Data.JSONType = jtObject then
      ApplyNodePropertiesFromJSON(N, TJSONObject(Data));
  finally
    Data.Free;
  end;

  FGraph.GraphChanged;
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
    if Data.JSONType = jtObject then
      ApplyNodePropertiesFromJSON(N, TJSONObject(Data));
  finally
    Data.Free;
  end;

  FGraph.GraphChanged;
end;

end.
