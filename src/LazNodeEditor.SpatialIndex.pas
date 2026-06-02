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
unit LazNodeEditor.SpatialIndex;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math;

type
  PSpatialItem = ^TSpatialItem;
  TSpatialItem = record
    Bounds: TRectF;
    Data: Pointer;
  end;

  TSpatialVisitProc = procedure(AData: Pointer) of object;

  { TSimpleRTreeNode }

  TSimpleRTreeNode = class
  public
    Bounds: TRectF;
    Children: array of TSimpleRTreeNode;
    Items: array of TSpatialItem;
    IsLeaf: boolean;
    destructor Destroy; override;
  end;

  { TSimpleRTree }

  TSimpleRTree = class
  private
    FRoot: TSimpleRTreeNode;
    FItems: array of TSpatialItem;
    FCount: integer;
    FLeafSize: integer;
    FDirty: boolean;

    class function RectEmpty: TRectF; static;
    class function RectUnion(const A, B: TRectF): TRectF; static;
    class function RectIntersects(const A, B: TRectF): boolean; static;
    class function RectArea(const R: TRectF): single; static;
    class function RectCenterX(const R: TRectF): single; static;
    class function RectCenterY(const R: TRectF): single; static;

    procedure ClearTree;
    procedure EnsureCapacity(ACapacity: integer);
    procedure BuildTree;
    function BuildNode(var AItems: array of TSpatialItem; AIndex, ACount: integer;
      ADepth: integer): TSimpleRTreeNode;
    procedure QueryNode(ANode: TSimpleRTreeNode; const R: TRectF;
      AList: TFPList);
    procedure QueryNodeProc(ANode: TSimpleRTreeNode; const R: TRectF;
      AProc: TSpatialVisitProc);
  public
    constructor Create(ALeafSize: integer = 16);
    destructor Destroy; override;

    procedure Clear;
    procedure Add(AData: Pointer; const ABounds: TRectF);
    procedure Remove(AData: Pointer);
    procedure Update(AData: Pointer; const ABounds: TRectF);
    procedure Rebuild;

    function Count: integer;

    procedure Query(const R: TRectF; AList: TFPList); overload;
    procedure Query(const R: TRectF; AProc: TSpatialVisitProc); overload;
  end;

implementation

type
  TSpatialItemArray = array of TSpatialItem;

destructor TSimpleRTreeNode.Destroy;
var
  i: integer;
begin
  for i := 0 to High(Children) do
    Children[i].Free;
  inherited Destroy;
end;

constructor TSimpleRTree.Create(ALeafSize: integer);
begin
  inherited Create;
  FLeafSize := EnsureRange(ALeafSize, 4, 64);
  FDirty := True;
end;

destructor TSimpleRTree.Destroy;
begin
  ClearTree;
  inherited Destroy;
end;

class function TSimpleRTree.RectEmpty: TRectF;
begin
  Result := RectF(0, 0, 0, 0);
end;

class function TSimpleRTree.RectUnion(const A, B: TRectF): TRectF;
begin
  Result.Left := Min(A.Left, B.Left);
  Result.Top := Min(A.Top, B.Top);
  Result.Right := Max(A.Right, B.Right);
  Result.Bottom := Max(A.Bottom, B.Bottom);
end;

class function TSimpleRTree.RectIntersects(const A, B: TRectF): boolean;
begin
  Result := not ((A.Right < B.Left) or (A.Left > B.Right) or
    (A.Bottom < B.Top) or (A.Top > B.Bottom));
end;

class function TSimpleRTree.RectArea(const R: TRectF): single;
begin
  Result := Max(0, R.Right - R.Left) * Max(0, R.Bottom - R.Top);
end;

class function TSimpleRTree.RectCenterX(const R: TRectF): single;
begin
  Result := (R.Left + R.Right) * 0.5;
end;

class function TSimpleRTree.RectCenterY(const R: TRectF): single;
begin
  Result := (R.Top + R.Bottom) * 0.5;
end;

procedure TSimpleRTree.ClearTree;
begin
  FreeAndNil(FRoot);
end;

procedure TSimpleRTree.EnsureCapacity(ACapacity: integer);
var
  NewCap: integer;
begin
  if Length(FItems) >= ACapacity then
    Exit;
  NewCap := Max(16, Length(FItems));
  while NewCap < ACapacity do
    NewCap := NewCap * 2;
  SetLength(FItems, NewCap);
end;

procedure QuickSortByCenterX(var A: array of TSpatialItem; L, R: integer);
var
  i, j: integer;
  P: single;
  T: TSpatialItem;
begin
  i := L;
  j := R;
  P := (A[(L + R) shr 1].Bounds.Left + A[(L + R) shr 1].Bounds.Right) * 0.5;
  repeat
    while ((A[i].Bounds.Left + A[i].Bounds.Right) * 0.5) < P do Inc(i);
    while ((A[j].Bounds.Left + A[j].Bounds.Right) * 0.5) > P do Dec(j);
    if i <= j then
    begin
      T := A[i];
      A[i] := A[j];
      A[j] := T;
      Inc(i);
      Dec(j);
    end;
  until i > j;
  if L < j then QuickSortByCenterX(A, L, j);
  if i < R then QuickSortByCenterX(A, i, R);
end;

procedure QuickSortByCenterY(var A: array of TSpatialItem; L, R: integer);
var
  i, j: integer;
  P: single;
  T: TSpatialItem;
begin
  i := L;
  j := R;
  P := (A[(L + R) shr 1].Bounds.Top + A[(L + R) shr 1].Bounds.Bottom) * 0.5;
  repeat
    while ((A[i].Bounds.Top + A[i].Bounds.Bottom) * 0.5) < P do Inc(i);
    while ((A[j].Bounds.Top + A[j].Bounds.Bottom) * 0.5) > P do Dec(j);
    if i <= j then
    begin
      T := A[i];
      A[i] := A[j];
      A[j] := T;
      Inc(i);
      Dec(j);
    end;
  until i > j;
  if L < j then QuickSortByCenterY(A, L, j);
  if i < R then QuickSortByCenterY(A, i, R);
end;

function TSimpleRTree.BuildNode(var AItems: array of TSpatialItem; AIndex,
  ACount, ADepth: integer): TSimpleRTreeNode;
var
  i, ChildCount, ChunkSize, StartIdx, ThisCount: integer;
  R: TRectF;
  SplitX: boolean;
  Child: TSimpleRTreeNode;
begin
  Result := TSimpleRTreeNode.Create;

  if ACount <= 0 then
  begin
    Result.IsLeaf := True;
    Exit;
  end;

  R := AItems[AIndex].Bounds;
  for i := 1 to ACount - 1 do
    R := RectUnion(R, AItems[AIndex + i].Bounds);
  Result.Bounds := R;

  if ACount <= FLeafSize then
  begin
    Result.IsLeaf := True;
    SetLength(Result.Items, ACount);
    for i := 0 to ACount - 1 do
      Result.Items[i] := AItems[AIndex + i];
    Exit;
  end;

  Result.IsLeaf := False;

  SplitX := ((R.Right - R.Left) >= (R.Bottom - R.Top));
  if SplitX then
    QuickSortByCenterX(AItems, AIndex, AIndex + ACount - 1)
  else
    QuickSortByCenterY(AItems, AIndex, AIndex + ACount - 1);

  ChildCount := Ceil(ACount / FLeafSize);
  ChildCount := Max(2, ChildCount);
  ChunkSize := Ceil(ACount / ChildCount);

  SetLength(Result.Children, ChildCount);
  StartIdx := AIndex;

  i := 0;
  while (StartIdx < AIndex + ACount) and (i < ChildCount) do
  begin
    ThisCount := Min(ChunkSize, (AIndex + ACount) - StartIdx);
    Child := BuildNode(AItems, StartIdx, ThisCount, ADepth + 1);
    Result.Children[i] := Child;
    Inc(StartIdx, ThisCount);
    Inc(i);
  end;

  if i < Length(Result.Children) then
    SetLength(Result.Children, i);
end;

procedure TSimpleRTree.BuildTree;
var
  Tmp: TSpatialItemArray;
  i: integer;
begin
  ClearTree;

  if FCount <= 0 then
  begin
    FDirty := False;
    Exit;
  end;

  SetLength(Tmp, FCount);
  for i := 0 to FCount - 1 do
    Tmp[i] := FItems[i];

  FRoot := BuildNode(Tmp, 0, FCount, 0);
  FDirty := False;
end;

procedure TSimpleRTree.QueryNode(ANode: TSimpleRTreeNode; const R: TRectF;
  AList: TFPList);
var
  i: integer;
begin
  if (ANode = nil) or not RectIntersects(ANode.Bounds, R) then
    Exit;

  if ANode.IsLeaf then
  begin
    for i := 0 to High(ANode.Items) do
      if RectIntersects(ANode.Items[i].Bounds, R) then
        AList.Add(ANode.Items[i].Data);
    Exit;
  end;

  for i := 0 to High(ANode.Children) do
    QueryNode(ANode.Children[i], R, AList);
end;

procedure TSimpleRTree.QueryNodeProc(ANode: TSimpleRTreeNode; const R: TRectF;
  AProc: TSpatialVisitProc);
var
  i: integer;
begin
  if (ANode = nil) or not RectIntersects(ANode.Bounds, R) then
    Exit;

  if ANode.IsLeaf then
  begin
    for i := 0 to High(ANode.Items) do
      if RectIntersects(ANode.Items[i].Bounds, R) then
        AProc(ANode.Items[i].Data);
    Exit;
  end;

  for i := 0 to High(ANode.Children) do
    QueryNodeProc(ANode.Children[i], R, AProc);
end;

procedure TSimpleRTree.Clear;
begin
  FCount := 0;
  SetLength(FItems, 0);
  ClearTree;
  FDirty := False;
end;

procedure TSimpleRTree.Add(AData: Pointer; const ABounds: TRectF);
begin
  EnsureCapacity(FCount + 1);
  FItems[FCount].Data := AData;
  FItems[FCount].Bounds := ABounds;
  Inc(FCount);
  FDirty := True;
end;

procedure TSimpleRTree.Remove(AData: Pointer);
var
  i: integer;
begin
  for i := 0 to FCount - 1 do
    if FItems[i].Data = AData then
    begin
      if i < FCount - 1 then
        Move(FItems[i + 1], FItems[i], (FCount - i - 1) * SizeOf(TSpatialItem));
      Dec(FCount);
      FDirty := True;
      Exit;
    end;
end;

procedure TSimpleRTree.Update(AData: Pointer; const ABounds: TRectF);
var
  i: integer;
begin
  for i := 0 to FCount - 1 do
    if FItems[i].Data = AData then
    begin
      FItems[i].Bounds := ABounds;
      FDirty := True;
      Exit;
    end;
  Add(AData, ABounds);
end;

procedure TSimpleRTree.Rebuild;
begin
  BuildTree;
end;

function TSimpleRTree.Count: integer;
begin
  Result := FCount;
end;

procedure TSimpleRTree.Query(const R: TRectF; AList: TFPList);
begin
  if AList = nil then
    Exit;
  if FDirty then
    BuildTree;
  QueryNode(FRoot, R, AList);
end;

procedure TSimpleRTree.Query(const R: TRectF; AProc: TSpatialVisitProc);
begin
  if not Assigned(AProc) then
    Exit;
  if FDirty then
    BuildTree;
  QueryNodeProc(FRoot, R, AProc);
end;

end.
