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

unit LazNodeEditor.Types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, Math, fpjson, jsonparser;

type
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

  TGraphNodeEvent = procedure(Sender: TObject; ANode: TObject) of object;
  TGraphLinkEvent = procedure(Sender: TObject; ALink: TObject) of object;
  TGraphChangedEvent = procedure(Sender: TObject) of object;
  TEditorZoomChangedEvent = procedure(Sender: TObject) of object;

  { TNodePinType }
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

  { TNodeValue }
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
    OwnerNode: TObject;

    IsRequired: boolean;
    DefaultValue: string;
    Tooltip: string;
    Hidden: boolean;
    Advanced: boolean;
    AllowMultipleConnections: boolean;
    SortIndex: integer;
    Connected: boolean;

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
    Node: TObject; // TCustomNode
    Link: TNodeLink;
  end;

function NewId: string;
function PinKindToStr(AKind: TPinKind): string;
function StrToPinKind(const S: string): TPinKind;
function PinDirectionToStr(ADir: TPinDirection): string;
function StrToPinDirection(const S: string): TPinDirection;

function NodeValueKindToStr(AKind: TNodeValueKind): string;
function StrToNodeValueKind(const S: string): TNodeValueKind;

function TypeFlagsToInt(AFlags: TNodePinTypeFlags): integer;
function IntToTypeFlags(AValue: integer): TNodePinTypeFlags;

function NormalizeRect(const R: TRect): TRect;
function RectIntersects(const A, B: TRect): boolean;
function UnionRectSafe(const A, B: TRect): TRect;

function CubicBezierPoint(const P0, P1, P2, P3: TPoint; t: double): TPointF;
function DistancePointToSegment(const P, A, B: TPointF): double;
function PointDistance(const A, B: TPoint): double;
procedure DrawCubicBezier(C: TCanvas; P0, P1, P2, P3: TPoint; Steps: integer = 32);
function PointInRectInclusive(const R: TRect; X, Y: integer): boolean;
function Cross(const AX, AY, BX, BY, CX, CY: integer): Int64;
function OnSegment(const AX, AY, BX, BY, PX, PY: integer): boolean;
function SegmentsIntersect(
  AX, AY, BX, BY, CX, CY, DX, DY: integer): boolean;
function LineIntersectsRect(X1, Y1, X2, Y2: integer; const R: TRect): boolean;

implementation

uses
  LCLIntf;

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

{ TNodePinType }

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

{ TNodeValue }

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

{ TNodePin }

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

{ TNodeLink }

constructor TNodeLink.Create(AFrom, ATo: TNodePin);
begin
  inherited Create;
  Id := NewId;
  FromPin := AFrom;
  ToPin := ATo;
end;

{ Geometry helpers }

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

function PointInRectInclusive(const R: TRect; X, Y: integer): boolean;
begin
  Result := (X >= R.Left) and (X <= R.Right) and (Y >= R.Top) and (Y <= R.Bottom);
end;

function Cross(const AX, AY, BX, BY, CX, CY: integer): Int64;
begin
  Result := Int64(BX - AX) * Int64(CY - AY) - Int64(BY - AY) * Int64(CX - AX);
end;

function OnSegment(const AX, AY, BX, BY, PX, PY: integer): boolean;
begin
  Result :=
    (Min(AX, BX) <= PX) and (PX <= Max(AX, BX)) and
    (Min(AY, BY) <= PY) and (PY <= Max(AY, BY));
end;

function SegmentsIntersect(
  AX, AY, BX, BY, CX, CY, DX, DY: integer): boolean;
var
  C1, C2, C3, C4: Int64;
begin
  C1 := Cross(AX, AY, BX, BY, CX, CY);
  C2 := Cross(AX, AY, BX, BY, DX, DY);
  C3 := Cross(CX, CY, DX, DY, AX, AY);
  C4 := Cross(CX, CY, DX, DY, BX, BY);

  if (((C1 > 0) and (C2 < 0)) or ((C1 < 0) and (C2 > 0))) and
     (((C3 > 0) and (C4 < 0)) or ((C3 < 0) and (C4 > 0))) then
    Exit(True);

  if (C1 = 0) and OnSegment(AX, AY, BX, BY, CX, CY) then Exit(True);
  if (C2 = 0) and OnSegment(AX, AY, BX, BY, DX, DY) then Exit(True);
  if (C3 = 0) and OnSegment(CX, CY, DX, DY, AX, AY) then Exit(True);
  if (C4 = 0) and OnSegment(CX, CY, DX, DY, BX, BY) then Exit(True);

  Result := False;
end;

function LineIntersectsRect(X1, Y1, X2, Y2: integer; const R: TRect): boolean;
begin
  if PointInRectInclusive(R, X1, Y1) or PointInRectInclusive(R, X2, Y2) then
    Exit(True);

  Result :=
    SegmentsIntersect(X1, Y1, X2, Y2, R.Left,  R.Top,    R.Right, R.Top) or
    SegmentsIntersect(X1, Y1, X2, Y2, R.Right, R.Top,    R.Right, R.Bottom) or
    SegmentsIntersect(X1, Y1, X2, Y2, R.Right, R.Bottom, R.Left,  R.Bottom) or
    SegmentsIntersect(X1, Y1, X2, Y2, R.Left,  R.Bottom, R.Left,  R.Top);
end;

end.
