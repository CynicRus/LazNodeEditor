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
  Generics.Collections, Classes, SysUtils, Graphics, Types, fpjson, jsonparser, Math,
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
    FNodeId: string;
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

  { TResizeNodesCommand — Group resize }

  TResizeNodesCommand = class(TGraphCommand)
  private
    FNodeIds: TStringList;
    FOldWidths: array of integer;
    FOldHeights: array of integer;
    FNewWidths: array of integer;
    FNewHeights: array of integer;
  public
    constructor Create(AGraph: INodeGraphCommandHost; ANodes: TCustomNodeList;
      const AOldW, AOldH, ANewW, ANewH: array of integer); reintroduce;
    destructor Destroy; override;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TReconnectLinkCommand }

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

  TAlignMode = (amLeft, amRight, amTop, amBottom, amCenterHorizontal, amCenterVertical);
  TDistributeMode = (dmHorizontal, dmVertical);
  TMatchSizeMode = (msmWidth, msmHeight, msmBoth);

  { TAlignNodesCommand }

  TAlignNodesCommand = class(TGraphCommand)
  private
    FNodeIds: TStringList;
    FOldX: array of single;
    FOldY: array of single;
    FNewX: array of single;
    FNewY: array of single;
  public
    constructor Create(AGraph: INodeGraphCommandHost; ANodes: TCustomNodeList;
      Mode: TAlignMode); reintroduce;
    destructor Destroy; override;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TDistributeNodesCommand }

  TDistributeNodesCommand = class(TGraphCommand)
  private
    FNodeIds: TStringList;
    FOldX: array of single;
    FOldY: array of single;
    FNewX: array of single;
    FNewY: array of single;
  public
    constructor Create(AGraph: INodeGraphCommandHost; ANodes: TCustomNodeList;
      Mode: TDistributeMode); reintroduce;
    destructor Destroy; override;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TMakeSameSizeCommand }

  TMakeSameSizeCommand = class(TGraphCommand)
  private
    FNodeIds: TStringList;
    FOldWidths: array of integer;
    FOldHeights: array of integer;
    FNewWidths: array of integer;
    FNewHeights: array of integer;
  public
    constructor Create(AGraph: INodeGraphCommandHost; ANodes: TCustomNodeList;
      Mode: TMatchSizeMode); reintroduce;
    destructor Destroy; override;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TFrameSelectedCommand }
  TFrameSelectedCommand = class(TGraphCommand)
  private
    FCommentId: string;
    FCommentJSON: string;
    FSelectedNodeIds: TStringList;
  public
    constructor Create(AGraph: INodeGraphCommandHost; ASelectedNodes: TCustomNodeList); reintroduce;
    destructor Destroy; override;

    procedure DoExecute; override;
    procedure Undo; override;
  end;

  { TAutoLayoutSelectedCommand }
  TAutoLayoutSelectedCommand = class(TGraphCommand)
  private
    FNodeIds: TStringList;
    FOldX, FOldY: array of single;
    FNewX, FNewY: array of single;
  public
    constructor Create(AGraph: INodeGraphCommandHost; ANodes: TCustomNodeList); reintroduce;
    destructor Destroy; override;
    procedure DoExecute; override;
    procedure Undo; override;
  end;

procedure LoadGraphFromJSONText(AGraph: INodeGraphCommandHost; const S: string);
procedure ApplyNodePropertiesFromJSON(ANode: TCustomNode; AObj: TJSONObject);

implementation

function CompareNodeByX(A, B: Pointer): integer;
begin
  if A = B then
    Exit(0);
  if A = nil then
    Exit(-1);
  if B = nil then
    Exit(1);

  if TCustomNode(A).X < TCustomNode(B).X then
    Result := -1
  else if TCustomNode(A).X > TCustomNode(B).X then
    Result := 1
  else
    Result := 0;
end;

function CompareNodeByY(A, B: Pointer): integer;
begin
  if A = B then
    Exit(0);
  if A = nil then
    Exit(-1);
  if B = nil then
    Exit(1);

  if TCustomNode(A).Y < TCustomNode(B).Y then
    Result := -1
  else if TCustomNode(A).Y > TCustomNode(B).Y then
    Result := 1
  else
    Result := 0;
end;

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
  FNodeId := ANode.Id;
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
    FNode := nil;
    FOwnsNode := False;
  end;
end;

procedure TAddNodeCommand.Undo;
begin
  if (FGraph = nil) then
    Exit;

  FNode := FGraph.FindNodeById(FNodeId);

  if Assigned(FNode) then
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
  ANodes: TCustomNodeList; const AOldPositions, ANewPositions: array of TPointF);
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

constructor TResizeNodesCommand.Create(AGraph: INodeGraphCommandHost;
  ANodes: TCustomNodeList; const AOldW, AOldH, ANewW, ANewH: array of integer);
var
  i: integer;
  N: TCustomNode;
begin
  inherited Create(AGraph, 'Resize nodes');

  FNodeIds := TStringList.Create;
  if ANodes = nil then
    Exit;

  SetLength(FOldWidths, ANodes.Count);
  SetLength(FOldHeights, ANodes.Count);
  SetLength(FNewWidths, ANodes.Count);
  SetLength(FNewHeights, ANodes.Count);

  for i := 0 to ANodes.Count - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    FNodeIds.Add(N.Id);
    FOldWidths[i] := AOldW[i];
    FOldHeights[i] := AOldH[i];
    FNewWidths[i] := ANewW[i];
    FNewHeights[i] := ANewH[i];
  end;
end;

destructor TResizeNodesCommand.Destroy;
begin
  FNodeIds.Free;
  inherited Destroy;
end;

procedure TResizeNodesCommand.DoExecute;
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
      N.Width := FNewWidths[i];
      N.Height := FNewHeights[i];
    end;
  end;

  FGraph.GraphChanged;
end;

procedure TResizeNodesCommand.Undo;
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
      N.Width := FOldWidths[i];
      N.Height := FOldHeights[i];
    end;
  end;

  FGraph.GraphChanged;
end;

constructor TReconnectLinkCommand.Create(AGraph: INodeGraphCommandHost;
  ALink: TNodeLink; AOldPin, ANewPin: TNodePin);
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

constructor TAlignNodesCommand.Create(AGraph: INodeGraphCommandHost;
  ANodes: TCustomNodeList; Mode: TAlignMode);
var
  i: integer;
  N: TCustomNode;
  MinX, MinY, MaxX, MaxY: single;
  CenterX, CenterY: single;
begin
  inherited Create(AGraph, 'Align nodes');
  FNodeIds := TStringList.Create;

  if (ANodes = nil) or (ANodes.Count < 2) then
    Exit;

  SetLength(FOldX, ANodes.Count);
  SetLength(FOldY, ANodes.Count);
  SetLength(FNewX, ANodes.Count);
  SetLength(FNewY, ANodes.Count);

  MinX := TCustomNode(ANodes[0]).X;
  MinY := TCustomNode(ANodes[0]).Y;
  MaxX := TCustomNode(ANodes[0]).X + TCustomNode(ANodes[0]).Width;
  MaxY := TCustomNode(ANodes[0]).Y + TCustomNode(ANodes[0]).Height;

  for i := 1 to ANodes.Count - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    if N.X < MinX then MinX := N.X;
    if N.Y < MinY then MinY := N.Y;
    if N.X + N.Width > MaxX then MaxX := N.X + N.Width;
    if N.Y + N.Height > MaxY then MaxY := N.Y + N.Height;
  end;

  CenterX := (MinX + MaxX) * 0.5;
  CenterY := (MinY + MaxY) * 0.5;

  for i := 0 to ANodes.Count - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    FNodeIds.Add(N.Id);
    FOldX[i] := N.X;
    FOldY[i] := N.Y;

    FNewX[i] := N.X;
    FNewY[i] := N.Y;

    case Mode of
      amLeft:
        FNewX[i] := MinX;

      amRight:
        FNewX[i] := MaxX - N.Width;

      amTop:
        FNewY[i] := MinY;

      amBottom:
        FNewY[i] := MaxY - N.Height;

      amCenterHorizontal:
        FNewX[i] := CenterX - N.Width / 2;

      amCenterVertical:
        FNewY[i] := CenterY - N.Height / 2;
    end;
  end;
end;

destructor TAlignNodesCommand.Destroy;
begin
  FNodeIds.Free;
  inherited Destroy;
end;

procedure TAlignNodesCommand.DoExecute;
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

procedure TAlignNodesCommand.Undo;
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

constructor TDistributeNodesCommand.Create(AGraph: INodeGraphCommandHost;
  ANodes: TCustomNodeList; Mode: TDistributeMode);
var
  i: Integer;
  N: TCustomNode;
  Sorted: TList;
  MinCenter, MaxCenter, Step, Center: Single;
begin
  inherited Create(AGraph, 'Distribute nodes');
  FNodeIds := TStringList.Create;

  if (ANodes = nil) or (ANodes.Count < 3) then
    Exit;

  Sorted := TList.Create;
  try
    for i := 0 to ANodes.Count - 1 do
      Sorted.Add(ANodes[i]);

    if Mode = dmHorizontal then
      Sorted.Sort(@CompareNodeByX)
    else
      Sorted.Sort(@CompareNodeByY);

    SetLength(FOldX, Sorted.Count);
    SetLength(FOldY, Sorted.Count);
    SetLength(FNewX, Sorted.Count);
    SetLength(FNewY, Sorted.Count);

    if Mode = dmHorizontal then
    begin
      MinCenter := TCustomNode(Sorted[0]).X +
        TCustomNode(Sorted[0]).Width / 2;
      MaxCenter := TCustomNode(Sorted[Sorted.Count - 1]).X +
        TCustomNode(Sorted[Sorted.Count - 1]).Width / 2;
    end
    else
    begin
      MinCenter := TCustomNode(Sorted[0]).Y +
        TCustomNode(Sorted[0]).Height / 2;
      MaxCenter := TCustomNode(Sorted[Sorted.Count - 1]).Y +
        TCustomNode(Sorted[Sorted.Count - 1]).Height / 2;
    end;

    Step := (MaxCenter - MinCenter) / (Sorted.Count - 1);

    for i := 0 to Sorted.Count - 1 do
    begin
      N := TCustomNode(Sorted[i]);
      FNodeIds.Add(N.Id);
      FOldX[i] := N.X;
      FOldY[i] := N.Y;

      FNewX[i] := N.X;
      FNewY[i] := N.Y;

      Center := MinCenter + i * Step;

      if Mode = dmHorizontal then
        FNewX[i] := Center - N.Width / 2
      else
        FNewY[i] := Center - N.Height / 2;
    end;
  finally
    Sorted.Free;
  end;
end;

destructor TDistributeNodesCommand.Destroy;
begin
  FNodeIds.Free;
  inherited Destroy;
end;

procedure TDistributeNodesCommand.DoExecute;
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

procedure TDistributeNodesCommand.Undo;
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

constructor TMakeSameSizeCommand.Create(AGraph: INodeGraphCommandHost;
  ANodes: TCustomNodeList; Mode: TMatchSizeMode);
var
  i: integer;
  N: TCustomNode;
  MaxW, MaxH: integer;
begin
  inherited Create(AGraph, 'Make same size');

  FNodeIds := TStringList.Create;
  if (ANodes = nil) or (ANodes.Count < 2) then
    Exit;

  SetLength(FOldWidths, ANodes.Count);
  SetLength(FOldHeights, ANodes.Count);
  SetLength(FNewWidths, ANodes.Count);
  SetLength(FNewHeights, ANodes.Count);

  MaxW := 0;
  MaxH := 0;
  for i := 0 to ANodes.Count - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    if N.Width > MaxW then
      MaxW := N.Width;
    if N.Height > MaxH then
      MaxH := N.Height;
  end;

  for i := 0 to ANodes.Count - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    FNodeIds.Add(N.Id);
    FOldWidths[i] := N.Width;
    FOldHeights[i] := N.Height;

    case Mode of
      msmWidth:
        begin
          FNewWidths[i] := MaxW;
          FNewHeights[i] := N.Height;
        end;

      msmHeight:
        begin
          FNewWidths[i] := N.Width;
          FNewHeights[i] := MaxH;
        end;

      msmBoth:
        begin
          FNewWidths[i] := MaxW;
          FNewHeights[i] := MaxH;
        end;
    end;
  end;
end;

destructor TMakeSameSizeCommand.Destroy;
begin
  FNodeIds.Free;
  inherited Destroy;
end;

procedure TMakeSameSizeCommand.DoExecute;
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
      N.Width := FNewWidths[i];
      N.Height := FNewHeights[i];
    end;
  end;

  FGraph.GraphChanged;
end;

procedure TMakeSameSizeCommand.Undo;
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
      N.Width := FOldWidths[i];
      N.Height := FOldHeights[i];
    end;
  end;

  FGraph.GraphChanged;
end;

{ TFrameSelectedCommand }

constructor TFrameSelectedCommand.Create(AGraph: INodeGraphCommandHost; ASelectedNodes: TCustomNodeList);
var
  i: integer;
  N: TCustomNode;
  MinX, MinY, MaxX, MaxY: single;
  Comment: TCommentNode;
  Obj: TJSONObject;
begin
  inherited Create(AGraph, 'Frame selected nodes');

  FSelectedNodeIds := TStringList.Create;
  FCommentId := NewId;

  if (ASelectedNodes = nil) or (ASelectedNodes.Count = 0) then Exit;

  MinX := MaxSingle; MinY := MaxSingle;
  MaxX := -MaxSingle; MaxY := -MaxSingle;

  for i := 0 to ASelectedNodes.Count - 1 do
  begin
    N := TCustomNode(ASelectedNodes[i]);
    FSelectedNodeIds.Add(N.Id);

    if N.X < MinX then MinX := N.X;
    if N.Y < MinY then MinY := N.Y;
    if N.X + N.Width > MaxX then MaxX := N.X + N.Width;
    if N.Y + N.Height > MaxY then MaxY := N.Y + N.Height;
  end;

  Comment := TCommentNode.Create('Frame', MinX - 20, MinY - 40, Round(MaxX - MinX + 60), Round(MaxY - MinY + 80));
  Comment.Id := FCommentId;
  Comment.CommentText := 'Frame';

  Obj := TJSONObject.Create;
  Comment.SaveToJSON(Obj);
  FCommentJSON := Obj.AsJSON;
  Obj.Free;
end;

destructor TFrameSelectedCommand.Destroy;
begin
  FSelectedNodeIds.Free;
  inherited Destroy;
end;

procedure TFrameSelectedCommand.DoExecute;
var
  Comment: TCustomNode;
  Reg: TNodeRegistry;
begin
  if FGraph = nil then Exit;
  Reg := FGraph.GetNodeRegistry();
  Comment := Reg.CreateNode('comment', 0, 0);
  Comment.Id := FCommentId;
  Comment.LoadFromJSONText(FCommentJSON);

  FGraph.AddNode(Comment);

  FGraph.GraphChanged;
end;

procedure TFrameSelectedCommand.Undo;
var
  Comment: TCustomNode;
begin
  if FGraph = nil then Exit;

  Comment := FGraph.FindNodeById(FCommentId);
  if Comment <> nil then
    FGraph.RemoveNode(Comment);

  FGraph.GraphChanged;
end;

{ TAutoLayoutSelectedCommand }

constructor TAutoLayoutSelectedCommand.Create(AGraph: INodeGraphCommandHost; ANodes: TCustomNodeList);
var
  i, Cols, Rows: integer;
  N: TCustomNode;
  BaseX, BaseY, SpacingX, SpacingY: single;
  MaxWidth, MaxHeight: single;
begin
  inherited Create(AGraph, 'Auto layout selected');

  FNodeIds := TStringList.Create;
  if (ANodes = nil) or (ANodes.Count = 0) then Exit;

  SetLength(FOldX, ANodes.Count);
  SetLength(FOldY, ANodes.Count);
  SetLength(FNewX, ANodes.Count);
  SetLength(FNewY, ANodes.Count);

  for i := 0 to ANodes.Count - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    FNodeIds.Add(N.Id);
    FOldX[i] := N.X;
    FOldY[i] := N.Y;
  end;

  Cols := Ceil(Sqrt(ANodes.Count));
  Rows := (ANodes.Count + Cols - 1) div Cols;

  BaseX := ANodes[0].X;
  BaseY := ANodes[0].Y;
  SpacingX := 40;
  SpacingY := 40;

  MaxWidth := 0;
  MaxHeight := 0;
  for i := 0 to ANodes.Count - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    if N.Width > MaxWidth then MaxWidth := N.Width;
    if N.Height > MaxHeight then MaxHeight := N.Height;
  end;

  for i := 0 to ANodes.Count - 1 do
  begin
    N := TCustomNode(ANodes[i]);
    FNewX[i] := BaseX + (i mod Cols) * (MaxWidth + SpacingX);
    FNewY[i] := BaseY + (i div Cols) * (MaxHeight + SpacingY);
  end;
end;

destructor TAutoLayoutSelectedCommand.Destroy;
begin
  FNodeIds.Free;
  inherited Destroy;
end;

procedure TAutoLayoutSelectedCommand.DoExecute;
var
  i: integer;
  N: TCustomNode;
begin
  if FGraph = nil then Exit;
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

procedure TAutoLayoutSelectedCommand.Undo;
var
  i: integer;
  N: TCustomNode;
begin
  if FGraph = nil then Exit;
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

end.
