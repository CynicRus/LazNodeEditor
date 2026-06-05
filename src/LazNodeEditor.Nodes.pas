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
unit LazNodeEditor.Nodes;

{$mode objfpc}{$H+}

interface

uses
  Generics.Collections, Classes, SysUtils, Graphics, Controls, Types, fpjson, LazUTF8, Math,
  LazNodeEditor.Types;

type
  TCustomNode = class;
  TCustomNodeClass = class of TCustomNode;
  TCustomNodeList = specialize TObjectList<TCustomNode>;

  TPinSelectionAccess = class
  public
    class function Contains(APinSelection: TObject; APin: TNodePin): boolean; static;
  end;

  { TCustomNode }
  TCustomNode = class
  private
    FInputs: TList;
    FOutputs: TList;
    FValues: TList;
  protected
    function GetDefaultHeaderColor: TColor; virtual;
    function GetDefaultBodyColor: TColor; virtual;
    function GetHeaderHeight(Zoom: double): integer; virtual;
    function GetPinHitRadiusWorld(Zoom: double): single; virtual;
    function GetResizeHandleRectScreen(const AState: TNodeRenderState): TRect; virtual;

  public
    Id: string;
    NodeType: string;
    Title: string;
    X, Y: single;
    Width, Height: integer;
    HeaderColor: TColor;
    BodyColor: TColor;
    Selected: boolean;
    PinTextColor: TColor;
    BodyTextColor: TColor;

    VisualKind: TNodeVisualKind;
    CommentText: string;
    Hovered: boolean;
    Highlighted: boolean;

    Collapsed: boolean;
    ZOrder: integer;
    Connected: boolean;

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
    procedure SetPinSide(APin: TNodePin; ASide: TPinSide);
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
    function GetPinWorldPosition(APin: TNodePin): TPointF;
    function GetPinScreenRect(APin: TNodePin; Zoom: double;
      OffsetX, OffsetY: integer; Radius: integer = 8): TRect;

    function HitTestNode(WX, WY: single): boolean; virtual;
    function HitTestPin(WX, WY: single; Zoom: double): TNodePin; virtual;
    function HitTestResizeHandle(WX, WY: single;
      const AState: TNodeRenderState): boolean; virtual;

    function GetScreenBounds(Zoom: double; OffsetX, OffsetY: double): TRect;

    procedure ClearValues;
    function AddValue(const AName: string; AKind: TNodeValueKind): TNodeValue;
    function FindValue(const AName: string): TNodeValue;
    function ValueCount: integer;
    function GetValue(Index: integer): TNodeValue;

    procedure Paint(Canvas: TCanvas; const AState: TNodeRenderState); virtual;
    procedure PaintBody(Canvas: TCanvas; const ARect: TRect;
      const AState: TNodeRenderState); virtual;
    procedure PaintPins(Canvas: TCanvas; const ARect: TRect;
      const AState: TNodeRenderState); virtual;
    procedure PaintPin(Canvas: TCanvas; APin: TNodePin; const ACenter: TPoint;
      ARadius: integer; const AState: TNodeRenderState); virtual;
    procedure PaintBodyOnly(Canvas: TCanvas; const AState: TNodeRenderState); virtual;
    procedure PaintSinglePin(Canvas: TCanvas; APin: TNodePin;
      const ACenter: TPoint; ARadius: integer; const AState: TNodeRenderState); virtual;
    procedure PaintPinLabel(Canvas: TCanvas; APin: TNodePin;
      const ACenter: TPoint; ARadius: integer; const AState: TNodeRenderState); virtual;
    procedure PaintResizeHandle(Canvas: TCanvas; const ARect: TRect;
      const AState: TNodeRenderState); virtual;

    procedure SaveToJSON(AObj: TJSONObject); virtual;
    procedure LoadFromJSON(AObj: TJSONObject); virtual;
    procedure LoadFromJSONText(const S: string); virtual;
  end;

  TDefaultNode = class(TCustomNode)
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 120); override;
    procedure SetupPins; override;
  end;

  TRerouteNode = class(TCustomNode)
  protected
    function GetPinHitRadiusWorld(Zoom: double): single; override;
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

implementation

uses
  LazNodeEditor.Selection;

  { TPinSelectionAccess }

class function TPinSelectionAccess.Contains(APinSelection: TObject;
  APin: TNodePin): boolean;
begin
  Result := (APinSelection is TPinSelectionModel) and
    TPinSelectionModel(APinSelection).Contains(APin);
end;

{ TCustomNode }

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
  Connected := False;
  BodyTextColor := clBlack;
  PinTextColor := clBlack;
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

function TCustomNode.GetHeaderHeight(Zoom: double): integer;
begin
  Result := Max(20, Round(28 * Zoom));
end;

function TCustomNode.GetPinHitRadiusWorld(Zoom: double): single;
begin
  Result := 10 / Zoom;
end;

function TCustomNode.GetResizeHandleRectScreen(const AState: TNodeRenderState): TRect;
var
  R: TRect;
  S: integer;
begin
  R := GetScreenBounds(AState.Zoom, AState.OffsetX, AState.OffsetY);
  S := Max(10, Round(AState.ResizeHandleSize * AState.Zoom));
  Result := Rect(R.Right - S, R.Bottom - S, R.Right + 1, R.Bottom + 1);
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
  if (APin = nil) or (APin.OwnerNode <> Self) then
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

procedure TCustomNode.SetPinSide(APin: TNodePin; ASide: TPinSide);
begin
  if (APin = nil) or (APin.OwnerNode <> Self) then
    Exit;
  APin.Side := ASide;
  AutoLayoutPins;
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
  i, HeaderH, BottomPad, WorkH: integer;
  InLeftCount, InTopCount, OutRightCount, OutBottomCount: integer;
  InLeftIndex, InTopIndex, OutRightIndex, OutBottomIndex: integer;
  P: TNodePin;
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

  HeaderH := 28;
  BottomPad := 18;
  WorkH := Height - HeaderH - BottomPad;
  if WorkH <= 0 then
    WorkH := 1;

  InLeftCount := 0;
  InTopCount := 0;
  OutRightCount := 0;
  OutBottomCount := 0;

  for i := 0 to FInputs.Count - 1 do
  begin
    P := TNodePin(FInputs[i]);
    case P.Side of
      psTop: Inc(InTopCount);
      else
        Inc(InLeftCount);
    end;
  end;

  for i := 0 to FOutputs.Count - 1 do
  begin
    P := TNodePin(FOutputs[i]);
    case P.Side of
      psBottom: Inc(OutBottomCount);
      else
        Inc(OutRightCount);
    end;
  end;

  InLeftIndex := 0;
  InTopIndex := 0;
  for i := 0 to FInputs.Count - 1 do
  begin
    P := TNodePin(FInputs[i]);
    case P.Side of
      psTop:
      begin
        P.SortIndex := InTopIndex;
        Inc(InTopIndex);
      end;
      else
      begin
        P.Side := psLeft;
        P.LocalY := HeaderH + (InLeftIndex + 1) * WorkH div (InLeftCount + 1);
        P.SortIndex := InLeftIndex;
        Inc(InLeftIndex);
      end;
    end;
  end;

  OutRightIndex := 0;
  OutBottomIndex := 0;
  for i := 0 to FOutputs.Count - 1 do
  begin
    P := TNodePin(FOutputs[i]);
    case P.Side of
      psBottom:
      begin
        P.SortIndex := OutBottomIndex;
        Inc(OutBottomIndex);
      end;
      else
      begin
        P.Side := psRight;
        P.LocalY := HeaderH + (OutRightIndex + 1) * WorkH div (OutRightCount + 1);
        P.SortIndex := OutRightIndex;
        Inc(OutRightIndex);
      end;
    end;
  end;
end;

procedure TCustomNode.AddInput(AName, ADataType: string; AKind: TPinKind;
  ALocalY: integer);
var
  P: TNodePin;
begin
  P := TNodePin.Create(AName, pdInput, AKind, ALocalY);
  P.OwnerNode := Self;
  P.SetTypeId(ADataType);
  P.AllowMultipleConnections := False;
  P.SortIndex := FInputs.Count;
  FInputs.Add(P);
  ReindexPins;
end;

procedure TCustomNode.AddOutput(AName, ADataType: string; AKind: TPinKind;
  ALocalY: integer);
var
  P: TNodePin;
begin
  P := TNodePin.Create(AName, pdOutput, AKind, ALocalY);
  P.OwnerNode := Self;
  P.SetTypeId(ADataType);
  P.AllowMultipleConnections := True;
  P.SortIndex := FOutputs.Count;
  FOutputs.Add(P);
  ReindexPins;
end;

function TCustomNode.InputCount: integer;
begin
  if FInputs <> nil then
    Result := FInputs.Count
  else
    Result := 0;
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
var
  XPos: integer;
begin
  if APin = nil then
    Exit(Point(0, 0));

  case APin.Side of
    psLeft:
      Result := Point(0, APin.LocalY);

    psRight:
      Result := Point(Width, APin.LocalY);

    psTop:
    begin
      XPos := APin.SortIndex + 1;
      Result := Point((Width * XPos) div
        (Max(1, IfThen(APin.Direction = pdInput, InputCount, OutputCount)) + 1), 0);
    end;

    psBottom:
    begin
      XPos := APin.SortIndex + 1;
      Result := Point((Width * XPos) div
        (Max(1, IfThen(APin.Direction = pdInput, InputCount, OutputCount)) +
        1), Height);
    end;

    else
      Result := Point(0, APin.LocalY);
  end;
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

function TCustomNode.GetPinWorldPosition(APin: TNodePin): TPointF;
var
  Local: TPoint;
begin
  if (APin = nil) or (APin.OwnerNode <> Self) then
    Exit(PointF(0, 0));
  Local := GetPinLocalPosition(APin);
  Result := PointF(X + Local.X, Y + Local.Y);
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

function TCustomNode.HitTestNode(WX, WY: single): boolean;
var
  CX, CY, RX, RY, DX, DY, RX2, RY2, L, T, R, B: single;
begin
  if VisualKind = nvReroute then
  begin
    CX := X + Width * 0.5;
    CY := Y + Height * 0.5;
    RX := Max(16, Width * 0.5 + 8);
    RY := Max(16, Height * 0.5 + 8);

    L := CX - RX;
    T := CY - RY;
    R := CX + RX;
    B := CY + RY;

    if (WX < L) or (WY < T) or (WX > R) or (WY > B) then
      Exit(False);

    DX := WX - CX;
    DY := WY - CY;
    RX2 := RX * RX;
    RY2 := RY * RY;
    Exit((DX * DX * RY2 + DY * DY * RX2) <= (RX2 * RY2));
  end;

  Result := (WX >= X) and (WY >= Y) and (WX <= X + Width) and (WY <= Y + Height);
end;

function TCustomNode.HitTestPin(WX, WY: single; Zoom: double): TNodePin;
var
  i: integer;
  P: TNodePin;
  PW: TPointF;
  R: single;
begin
  Result := nil;
  if VisualKind = nvComment then
    Exit;

  R := GetPinHitRadiusWorld(Zoom);

  for i := 0 to InputCount - 1 do
  begin
    P := GetInput(i);
    if (P = nil) or P.Hidden then Continue;
    PW := GetPinWorldPosition(P);
    if Hypot(WX - PW.X, WY - PW.Y) <= R then
      Exit(P);
  end;

  for i := 0 to OutputCount - 1 do
  begin
    P := GetOutput(i);
    if (P = nil) or P.Hidden then Continue;
    PW := GetPinWorldPosition(P);
    if Hypot(WX - PW.X, WY - PW.Y) <= R then
      Exit(P);
  end;
end;

function TCustomNode.HitTestResizeHandle(WX, WY: single;
  const AState: TNodeRenderState): boolean;
var
  R: TRect;
  SX, SY: integer;
begin
  if VisualKind = nvReroute then
    Exit(False);

  R := GetResizeHandleRectScreen(AState);
  SX := Round(WX * AState.Zoom + AState.OffsetX);
  SY := Round(WY * AState.Zoom + AState.OffsetY);
  Result := PointInRectInclusive(R, SX, SY);
end;

function TCustomNode.GetScreenBounds(Zoom: double; OffsetX, OffsetY: double): TRect;
begin
  Result.Left := Round(X * Zoom + OffsetX);
  Result.Top := Round(Y * Zoom + OffsetY);
  Result.Right := Round((X + Width) * Zoom + OffsetX);
  Result.Bottom := Round((Y + Height) * Zoom + OffsetY);
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

procedure TCustomNode.PaintBody(Canvas: TCanvas; const ARect: TRect;
  const AState: TNodeRenderState);
var
  R, HeaderR, BodyR: TRect;
  HeaderH: integer;
begin
  R := ARect;
  HeaderH := GetHeaderHeight(AState.Zoom);

  if Collapsed and (VisualKind = nvNormal) then
    R.Bottom := R.Top + HeaderH;

  if VisualKind = nvReroute then
  begin
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsSolid;

    if Selected then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.Pen.Width := Max(2, Round(3 * AState.Zoom));
      Canvas.Ellipse(R.Left - 5, R.Top - 5, R.Right + 5, R.Bottom + 5);
    end
    else if Highlighted then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clAqua;
      Canvas.Pen.Width := Max(2, Round(3 * AState.Zoom));
      Canvas.Ellipse(R.Left - 4, R.Top - 4, R.Right + 4, R.Bottom + 4);
    end
    else if Hovered then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clBlue;
      Canvas.Pen.Width := Max(1, Round(2 * AState.Zoom));
      Canvas.Ellipse(R.Left - 3, R.Top - 3, R.Right + 3, R.Bottom + 3);
    end;

    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := $00F8F8F8;
    Canvas.Pen.Color := $00404040;
    Canvas.Pen.Width := Max(1, Round(2 * AState.Zoom));
    Canvas.Ellipse(R.Left, R.Top, R.Right, R.Bottom);

    Canvas.Brush.Color := $00FFFFFF;
    Canvas.Pen.Color := $00808080;
    Canvas.Pen.Width := 1;
    Canvas.Ellipse(
      R.Left + Round(6 * AState.Zoom),
      R.Top + Round(6 * AState.Zoom),
      R.Right - Round(6 * AState.Zoom),
      R.Bottom - Round(6 * AState.Zoom)
      );

    Canvas.Pen.Color := $00505050;
    Canvas.Pen.Width := Max(1, Round(2 * AState.Zoom));
    Canvas.MoveTo(R.Left - Round(10 * AState.Zoom), (R.Top + R.Bottom) div 2);
    Canvas.LineTo(R.Left + Round(5 * AState.Zoom), (R.Top + R.Bottom) div 2);
    Canvas.MoveTo(R.Right - Round(5 * AState.Zoom), (R.Top + R.Bottom) div 2);
    Canvas.LineTo(R.Right + Round(10 * AState.Zoom), (R.Top + R.Bottom) div 2);

    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsSolid;
    Exit;
  end;

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

    HeaderR := Rect(R.Left, R.Top, R.Right, R.Top + Max(18, Round(24 * AState.Zoom)));
    Canvas.Brush.Color := HeaderColor;
    Canvas.FillRect(HeaderR);

    Canvas.Font.Color := BodyTextColor;
    Canvas.Font.Size := Max(7, Round(10 * AState.Zoom));
    Canvas.Brush.Style := bsClear;
    if AState.ShowNodeTitle then
      Canvas.TextOut(R.Left + 8, R.Top + 5, Title);

    if (CommentText <> '') and (AState.ShowNodeTitle) then
      Canvas.TextOut(R.Left + 8, HeaderR.Bottom + 6, CommentText);

    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Width := 1;
    Exit;
  end;

  BodyR := R;
  Canvas.Brush.Color := BodyColor;
  Canvas.Pen.Style := psClear;
  Canvas.Rectangle(BodyR);

  HeaderR := Rect(R.Left, R.Top, R.Right, R.Top + HeaderH);
  Canvas.Brush.Color := HeaderColor;
  Canvas.Rectangle(HeaderR);

  if AState.ShowNodeTitle then
  begin
    Canvas.Font.Color := clBlack;
    Canvas.Font.Size := Max(7, Min(14, Round(10 * AState.Zoom)));
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(R.Left + 8, R.Top + Max(4, Round(6 * AState.Zoom)), Title);
  end;

  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psSolid;
  if Selected then
    Canvas.Pen.Color := clRed
  else if Highlighted then
    Canvas.Pen.Color := clAqua
  else if Hovered then
    Canvas.Pen.Color := clBlue
  else
    Canvas.Pen.Color := clBlack;

  Canvas.Pen.Width := IfThen(Selected or Highlighted, 3, 1);
  Canvas.Rectangle(R);

  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsSolid;
end;

procedure TCustomNode.PaintPin(Canvas: TCanvas; APin: TNodePin;
  const ACenter: TPoint; ARadius: integer; const AState: TNodeRenderState);
var
  FillColor: TColor;
  InnerRadius: integer;
  IsSelected: boolean;
  IsHovered: boolean;
begin
  if (Canvas = nil) or (APin = nil) or APin.Hidden then
    Exit;

  IsSelected := TPinSelectionAccess.Contains(AState.PinSelection, APin);
  IsHovered := (AState.HoveredPin = APin) and (AState.TempFromPin = nil);

  if APin.Kind = pkExec then
    FillColor := clWhite
  else if APin.PinType <> nil then
    FillColor := APin.PinType.Color
  else
    FillColor := clLime;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FillColor;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 1;

  Canvas.Ellipse(
    ACenter.X - ARadius, ACenter.Y - ARadius,
    ACenter.X + ARadius, ACenter.Y + ARadius
    );

  if APin.Connected then
  begin
    InnerRadius := Max(2, ARadius div 2);
    if APin.AllowMultipleConnections then
      Canvas.Brush.Color := clWhite
    else
      Canvas.Brush.Color := clBlack;

    Canvas.Pen.Style := psClear;
    Canvas.Ellipse(
      ACenter.X - InnerRadius, ACenter.Y - InnerRadius,
      ACenter.X + InnerRadius, ACenter.Y + InnerRadius
      );
    Canvas.Pen.Style := psSolid;
  end;

  if IsSelected then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := clLime;
    Canvas.Pen.Width := 2;
    Canvas.Ellipse(
      ACenter.X - ARadius - 3, ACenter.Y - ARadius - 3,
      ACenter.X + ARadius + 3, ACenter.Y + ARadius + 3
      );
  end
  else if IsHovered or Highlighted then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := clAqua;
    Canvas.Pen.Width := 2;
    Canvas.Ellipse(
      ACenter.X - ARadius - 2, ACenter.Y - ARadius - 2,
      ACenter.X + ARadius + 2, ACenter.Y + ARadius + 2
      );
  end;

  if (AState.TempFromPin <> nil) and (AState.HoveredPin = APin) then
  begin
    Canvas.Brush.Style := bsClear;
    if AState.HoveredPinCompatible then
      Canvas.Pen.Color := clAqua
    else
      Canvas.Pen.Color := clRed;
    Canvas.Pen.Width := 2;

    Canvas.Ellipse(
      ACenter.X - ARadius - 5, ACenter.Y - ARadius - 5,
      ACenter.X + ARadius + 5, ACenter.Y + ARadius + 5
      );
  end;

  Canvas.Font.Color := clBlack;
  Canvas.Font.Size := Max(6, Round(10 * AState.Zoom));
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Width := 1;
end;

procedure TCustomNode.PaintBodyOnly(Canvas: TCanvas; const AState: TNodeRenderState);
var
  R: TRect;
begin
  if Canvas = nil then
    Exit;
  R := GetScreenBounds(AState.Zoom, AState.OffsetX, AState.OffsetY);
  PaintBody(Canvas, R, AState);
end;

procedure TCustomNode.PaintSinglePin(Canvas: TCanvas; APin: TNodePin;
  const ACenter: TPoint; ARadius: integer; const AState: TNodeRenderState);
begin
  PaintPin(Canvas, APin, ACenter, ARadius, AState);
end;

procedure TCustomNode.PaintPinLabel(Canvas: TCanvas; APin: TNodePin;
  const ACenter: TPoint; ARadius: integer; const AState: TNodeRenderState);
var
  S: string;
  TX, TY: integer;
begin
  if (Canvas = nil) or (APin = nil) or APin.Hidden then
    Exit;
  if VisualKind = nvComment then
    Exit;
  if VisualKind = nvReroute then
    Exit;

  if not AState.ShowPinLabels then
    Exit;

  S := APin.EffectiveDisplayName;
  if S = '' then
    Exit;

  Canvas.Font.Color := PinTextColor;
  Canvas.Font.Size := Max(6, Round(10 * AState.Zoom));
  Canvas.Brush.Style := bsClear;

  case APin.Side of
    psLeft:
    begin
      TX := ACenter.X + ARadius + 6;
      TY := ACenter.Y - Canvas.TextHeight(S) div 2;
    end;

    psRight:
    begin
      TX := ACenter.X - Canvas.TextWidth(S) - ARadius - 6;
      TY := ACenter.Y - Canvas.TextHeight(S) div 2;
    end;

    psTop:
    begin
      TX := ACenter.X - Canvas.TextWidth(S) div 2;
      TY := ACenter.Y + ARadius + 4;
    end;

    psBottom:
    begin
      TX := ACenter.X - Canvas.TextWidth(S) div 2;
      TY := ACenter.Y - Canvas.TextHeight(S) - ARadius - 4;
    end;

    else
    begin
      TX := ACenter.X + ARadius + 6;
      TY := ACenter.Y - Canvas.TextHeight(S) div 2;
    end;
  end;

  Canvas.TextOut(TX, TY, S);
end;

procedure TCustomNode.PaintResizeHandle(Canvas: TCanvas; const ARect: TRect;
  const AState: TNodeRenderState);
var
  HR: TRect;
begin
  if (Canvas = nil) or (VisualKind = nvReroute) or (VisualKind = nvComment) then
    Exit;
  if not Selected then
    Exit;

  HR := GetResizeHandleRectScreen(AState);

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clGray;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(HR);
end;

procedure TCustomNode.PaintPins(Canvas: TCanvas; const ARect: TRect;
  const AState: TNodeRenderState);
var
  i, Radius: integer;
  P: TNodePin;
  LocalPos: TPoint;
  Center: TPoint;
begin
  if (Canvas = nil) or (VisualKind = nvComment) then
    Exit;

  Radius := Max(2, Round(AState.PinRadius * AState.Zoom));

  for i := 0 to InputCount - 1 do
  begin
    P := GetInput(i);
    if (P = nil) or P.Hidden then
      Continue;

    LocalPos := GetPinLocalPosition(P);
    Center := Point(ARect.Left + Round(LocalPos.X * AState.Zoom),
      ARect.Top + Round(LocalPos.Y * AState.Zoom));

    PaintSinglePin(Canvas, P, Center, Radius, AState);
    PaintPinLabel(Canvas, P, Center, Radius, AState);
  end;

  for i := 0 to OutputCount - 1 do
  begin
    P := GetOutput(i);
    if (P = nil) or P.Hidden then
      Continue;

    LocalPos := GetPinLocalPosition(P);
    Center := Point(ARect.Left + Round(LocalPos.X * AState.Zoom),
      ARect.Top + Round(LocalPos.Y * AState.Zoom));

    PaintSinglePin(Canvas, P, Center, Radius, AState);
    PaintPinLabel(Canvas, P, Center, Radius, AState);
  end;
end;

procedure TCustomNode.Paint(Canvas: TCanvas; const AState: TNodeRenderState);
var
  R: TRect;
begin
  if Canvas = nil then
    Exit;
  R := GetScreenBounds(AState.Zoom, AState.OffsetX, AState.OffsetY);
  PaintBody(Canvas, R, AState);
  PaintPins(Canvas, R, AState);
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
    PinObj.Add('side', Ord(P.Side));
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
    PinObj.Add('side', Ord(P.Side));
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
      P.Side := TPinSide(PinObj.Get('side', Ord(
        IfThen(Dir = pdInput, integer(psLeft), integer(psRight)))));
      P.Id := PinObj.Get('id', P.Id);
      P.DisplayName := PinObj.Get('displayName', P.Name);
      P.DataType := PinObj.Get('dataType', '');
      P.SetTypeId(P.DataType);

      PinTypeObj := PinObj.Objects['pinType'];
      if (PinTypeObj <> nil) and (P.PinType <> nil) then
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

procedure TCustomNode.LoadFromJSONText(const S: string);
var
  Data: TJSONData;
begin

  if Trim(S) = '' then
    Exit;

  Data := GetJSON(S);
  try
    if Data.JSONType = jtObject then
      LoadFromJSON(TJSONObject(Data));
  finally
    Data.Free;
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

function TRerouteNode.GetPinHitRadiusWorld(Zoom: double): single;
begin
  Result := 9 / Zoom;
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

end.
