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
  Classes, SysUtils, Graphics, Controls, Types, fpjson, LazUTF8, Math,
  LazNodeEditor.Types;

type
  TCustomNode = class;
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
    function GetPinWorldPosition(APin: TNodePin): TPointF;

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

implementation

uses
  Generics.Collections;

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
  DX, DY: single;
  RX2, RY2: single;
  L, T, R, B: single;
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

    Result := (DX * DX * RY2 + DY * DY * RX2) <= (RX2 * RY2);
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
  HeaderH: integer;
begin
  R := GetScreenBounds(Zoom, OffsetX, OffsetY);

  HeaderH := Max(20, Round(28 * Zoom));

  if Collapsed and (VisualKind = nvNormal) then
  begin
    R.Bottom := R.Top + HeaderH;
  end;

  // REROUTE NODE
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

  // COMMENT NODE
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

  // NORMAL NODE
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

  // Pin rendering removed from here. Handled by Editor.

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

  // PINS
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

  // VALUES
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

{ Default node implementations }

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

{ TNodeDefinition }

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

{ TNodeRegistry }

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
