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
unit GenericDAG;

{$mode objfpc}{$H+}

interface

uses
  Generics.Collections, Classes, SysUtils;

type

  { TDAG }

  generic TDAG<T> = class
  public
  type
    TCompareFunc = function(const A, B: T): integer;
    TEqualityFunc = function(const A, B: T): boolean;
  private
  type
    TIntList = specialize TList<integer>;

    TEdgeList = class(TIntList)
    public
      function BinarySearchValue(AValue: integer; out AIndex: integer): boolean;
      function AddSortedUnique(AValue: integer): boolean;
      function RemoveSortedValue(AValue: integer): boolean;
    end;

    TIndexMap = specialize TDictionary<T, integer>;
  private
    FItems: array of T;
    FEdges: array of TEdgeList;
    FCount: integer;
    FCapacity: integer;
    FComparer: TCompareFunc;
    FIndex: TIndexMap;
    FIndexValid: boolean;
    FOwnsIndex: boolean;
    function GetItem(AIndex: integer): T;
    procedure SetItem(AIndex: integer; const AValue: T);
    procedure CheckIndex(AIndex: integer);
    procedure CheckInsertIndex(AIndex: integer);
    procedure Grow;
    procedure SetCapacityInternal(ANewCapacity: integer);
    procedure FreeEdgesFrom(AFrom, AToExclusive: integer);
    procedure EnsureIndex;
    procedure RebuildIndex;
    procedure InvalidateIndex;
    function DefaultEquals(const A, B: T): boolean;
    function InternalIndexOfLinear(const AValue: T): integer;
    function TryFindIndex(const AValue: T; out AIndex: integer): boolean;
    procedure InsertRaw(AIndex: integer; const AValue: T);
    procedure DeleteRaw(AIndex: integer);
    procedure RemapEdgesAfterInsert(AIndex: integer);
    procedure RemapEdgesAfterDelete(AIndex: integer);
    procedure RemapEdgesByPermutation(const OldToNew: array of integer);
    function HasPathIndex(AFrom, ATo: integer): boolean;
    function WouldCreateCycle(AFrom, ATo: integer): boolean;
  public
    constructor Create;
    constructor Create(AComparer: TCompareFunc);
    destructor Destroy; override;
    property Count: integer read FCount;
    property Capacity: integer read FCapacity write SetCapacityInternal;
    property Items[AIndex: integer]: T read GetItem write SetItem; default;
    procedure Clear;
    procedure TrimExcess;
    function Add(const AValue: T): integer;
    procedure AddRange(const AValues: array of T);
    procedure Insert(AIndex: integer; const AValue: T);
    procedure Delete(AIndex: integer);
    procedure DeleteRange(AIndex, ACount: integer);
    function Remove(const AValue: T): integer;
    procedure Extract(AIndex: integer; out AValue: T);
    function First: T;
    function Last: T;
    function IndexOf(const AValue: T): integer;
    function Contains(const AValue: T): boolean;
    procedure Exchange(AIndex1, AIndex2: integer);
    procedure Move(ACurIndex, ANewIndex: integer);
    procedure Reverse;
    procedure Sort;
    procedure Sort(AComparer: TCompareFunc);
    procedure Assign(const ASource: specialize TDAG<T>);
    procedure CopyTo(var ADest: array of T);
    procedure AddEdge(const AFromValue, AToValue: T);
    procedure AddEdgeByIndex(AFrom, ATo: integer);
    function RemoveEdge(const AFromValue, AToValue: T): boolean;
    function RemoveEdgeByIndex(AFrom, ATo: integer): boolean;
    function HasEdge(const AFromValue, AToValue: T): boolean;
    function HasEdgeByIndex(AFrom, ATo: integer): boolean;
    function HasPath(const AFromValue, AToValue: T): boolean;
    function HasPathByIndex(AFrom, ATo: integer): boolean;
    function OutDegree(AIndex: integer): integer;
    function EdgeTo(AIndex, AEdgeNo: integer): integer;
    function CanCreateCycle(const AFromValue, AToValue: T): boolean;
    function IsAcyclic: boolean;
    function TopologicalSort: specialize TList<integer>;
  end;

  { TObjectDAG }

  generic TObjectDAG<T: class> = class(specialize TDAG<T>)
  private
    FOwnsObjects: boolean;
  public
    constructor Create(AOwnsObjects: boolean = False);
    destructor Destroy; override;
    function Remove(const AValue: T): integer;reintroduce;
  end;

implementation

{ TDAG.TEdgeList }

function TDAG.TEdgeList.BinarySearchValue(AValue: integer; out AIndex: integer): boolean;
var
  L, H, M, V: integer;
begin
  Result := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    M := (L + H) shr 1;
    V := Items[M];
    if V < AValue then
      L := M + 1
    else if V > AValue then
      H := M - 1
    else
    begin
      AIndex := M;
      Exit(True);
    end;
  end;
  AIndex := L;
end;

function TDAG.TEdgeList.AddSortedUnique(AValue: integer): boolean;
var
  P: integer;
begin
  if BinarySearchValue(AValue, P) then
    Exit(False);
  Insert(P, AValue);
  Result := True;
end;

function TDAG.TEdgeList.RemoveSortedValue(AValue: integer): boolean;
var
  P: integer;
begin
  if not BinarySearchValue(AValue, P) then
    Exit(False);
  Delete(P);
  Result := True;
end;

{ TObjectDAG }

constructor TObjectDAG.Create(AOwnsObjects: boolean);
begin
  inherited Create;
  FOwnsObjects := AOwnsObjects;
end;

destructor TObjectDAG.Destroy;
var
  I: Integer;
begin
  if FOwnsObjects then
  begin
    for I := 0 to Count - 1 do
      Items[I].Free;
  end;
  inherited Destroy;
end;

function TObjectDAG.Remove(const AValue: T): integer;
begin
  Result := IndexOf(AValue);
  if Result >= 0 then
  begin
   if FOwnsObjects then
      Items[Result].Free;
    Delete(Result);
  end;
end;

{ TDAG }

constructor TDAG.Create;
begin
  inherited Create;
  FCount := 0;
  FCapacity := 0;
  FComparer := nil;
  FIndex := nil;
  FIndexValid := False;
  FOwnsIndex := False;
end;

constructor TDAG.Create(AComparer: TCompareFunc);
begin
  Create;
  FComparer := AComparer;
  if not Assigned(FComparer) then
  begin
    FIndex := TIndexMap.Create;
    FOwnsIndex := True;
  end;
end;

destructor TDAG.Destroy;
begin
  Clear;
  if FOwnsIndex then
    FreeAndNil(FIndex);
  inherited Destroy;
end;

function TDAG.DefaultEquals(const A, B: T): boolean;
begin
  if Assigned(FComparer) then
    Result := FComparer(A, B) = 0
  else
    Result := A = B;
end;

procedure TDAG.CheckIndex(AIndex: integer);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EListError.CreateFmt('Index out of bounds: %d', [AIndex]);
end;

procedure TDAG.CheckInsertIndex(AIndex: integer);
begin
  if (AIndex < 0) or (AIndex > FCount) then
    raise EListError.CreateFmt('Insert index out of bounds: %d', [AIndex]);
end;

function TDAG.GetItem(AIndex: integer): T;
begin
  CheckIndex(AIndex);
  Result := FItems[AIndex];
end;

procedure TDAG.SetItem(AIndex: integer; const AValue: T);
begin
  CheckIndex(AIndex);
  FItems[AIndex] := AValue;
  InvalidateIndex;
end;

procedure TDAG.Grow;
var
  NewCap: integer;
begin
  if FCapacity = 0 then
    NewCap := 4
  else if FCapacity < 64 then
    NewCap := FCapacity * 2
  else
    NewCap := FCapacity + FCapacity div 2;
  SetCapacityInternal(NewCap);
end;

procedure TDAG.SetCapacityInternal(ANewCapacity: integer);
var
  I: integer;
begin
  if ANewCapacity < FCount then
    raise EListError.Create('Capacity cannot be less than Count');
  if ANewCapacity = FCapacity then
    Exit;

  if ANewCapacity < FCapacity then
    FreeEdgesFrom(ANewCapacity, FCapacity);

  SetLength(FItems, ANewCapacity);
  SetLength(FEdges, ANewCapacity);

  if ANewCapacity > FCapacity then
    for I := FCapacity to ANewCapacity - 1 do
      FEdges[I] := nil;

  FCapacity := ANewCapacity;
end;

procedure TDAG.FreeEdgesFrom(AFrom, AToExclusive: integer);
var
  I: integer;
begin
  for I := AFrom to AToExclusive - 1 do
    FreeAndNil(FEdges[I]);
end;

procedure TDAG.Clear;
begin
  FreeEdgesFrom(0, FCapacity);
  SetLength(FItems, 0);
  SetLength(FEdges, 0);
  FCount := 0;
  FCapacity := 0;
  InvalidateIndex;
end;

procedure TDAG.TrimExcess;
begin
  SetCapacityInternal(FCount);
end;

procedure TDAG.InvalidateIndex;
begin
  FIndexValid := False;
end;

procedure TDAG.EnsureIndex;
begin
  if Assigned(FIndex) and not FIndexValid then
    RebuildIndex;
end;

procedure TDAG.RebuildIndex;
var
  I: integer;
begin
  if not Assigned(FIndex) then
    Exit;
  FIndex.Clear;
  for I := 0 to FCount - 1 do
    FIndex.Add(FItems[I], I);
  FIndexValid := True;
end;

function TDAG.InternalIndexOfLinear(const AValue: T): integer;
var
  I: integer;
begin
  for I := 0 to FCount - 1 do
    if DefaultEquals(FItems[I], AValue) then
      Exit(I);
  Result := -1;
end;

function TDAG.TryFindIndex(const AValue: T; out AIndex: integer): boolean;
begin
  if Assigned(FIndex) then
  begin
    EnsureIndex;
    Result := FIndex.TryGetValue(AValue, AIndex);
  end
  else
  begin
    AIndex := InternalIndexOfLinear(AValue);
    Result := AIndex >= 0;
  end;
end;

function TDAG.IndexOf(const AValue: T): integer;
begin
  if not TryFindIndex(AValue, Result) then
    Result := -1;
end;

function TDAG.Contains(const AValue: T): boolean;
begin
  Result := IndexOf(AValue) >= 0;
end;

procedure TDAG.InsertRaw(AIndex: integer; const AValue: T);
var
  I: integer;
begin
  if FCount = FCapacity then
    Grow;
  for I := FCount downto AIndex + 1 do
  begin
    FItems[I] := FItems[I - 1];
    FEdges[I] := FEdges[I - 1];
  end;
  FItems[AIndex] := AValue;
  FEdges[AIndex] := TEdgeList.Create;
  Inc(FCount);
  InvalidateIndex;
end;

procedure TDAG.DeleteRaw(AIndex: integer);
var
  I: integer;
begin
  FreeAndNil(FEdges[AIndex]);
  for I := AIndex to FCount - 2 do
  begin
    FItems[I] := FItems[I + 1];
    FEdges[I] := FEdges[I + 1];
  end;
  FEdges[FCount - 1] := nil;
  Dec(FCount);
  InvalidateIndex;
end;

function TDAG.Add(const AValue: T): integer;
begin
  Result := FCount;
  InsertRaw(FCount, AValue);
end;

procedure TDAG.AddRange(const AValues: array of T);
var
  I: integer;
begin
  for I := Low(AValues) to High(AValues) do
    Add(AValues[I]);
end;

procedure TDAG.Insert(AIndex: integer; const AValue: T);
begin
  CheckInsertIndex(AIndex);
  InsertRaw(AIndex, AValue);
  RemapEdgesAfterInsert(AIndex);
end;

procedure TDAG.Delete(AIndex: integer);
begin
  CheckIndex(AIndex);
  DeleteRaw(AIndex);
  RemapEdgesAfterDelete(AIndex);
end;

procedure TDAG.DeleteRange(AIndex, ACount: integer);
var
  I: integer;
begin
  if ACount < 0 then
    raise EListError.Create('Negative delete count');
  if ACount = 0 then
    Exit;
  if (AIndex < 0) or (AIndex + ACount > FCount) then
    raise EListError.Create('DeleteRange out of bounds');
  for I := ACount downto 1 do
    Delete(AIndex);
end;

function TDAG.Remove(const AValue: T): integer;
begin
  Result := IndexOf(AValue);
  if Result >= 0 then
    Delete(Result);
end;

procedure TDAG.Extract(AIndex: integer; out AValue: T);
begin
  CheckIndex(AIndex);
  AValue := FItems[AIndex];
  Delete(AIndex);
end;

function TDAG.First: T;
begin
  if FCount = 0 then
    raise EListError.Create('List is empty');
  Result := FItems[0];
end;

function TDAG.Last: T;
begin
  if FCount = 0 then
    raise EListError.Create('List is empty');
  Result := FItems[FCount - 1];
end;

procedure TDAG.RemapEdgesAfterInsert(AIndex: integer);
var
  I, J, V: integer;
begin
  for I := 0 to FCount - 1 do
  begin
    if FEdges[I] = nil then
      Continue;
    for J := 0 to FEdges[I].Count - 1 do
    begin
      V := FEdges[I][J];
      if V >= AIndex then
        FEdges[I][J] := V + 1;
    end;
    FEdges[I].Sort;
    // восстанавливаем сортировку (TList<Integer>.Sort использует дефолтный comparer)
  end;
end;

procedure TDAG.RemapEdgesAfterDelete(AIndex: integer);
var
  I, J, V: integer;
begin
  for I := 0 to FCount - 1 do
  begin
    if FEdges[I] = nil then
      Continue;
    J := FEdges[I].Count - 1;
    while J >= 0 do
    begin
      V := FEdges[I][J];
      if V = AIndex then
        FEdges[I].Delete(J)
      else if V > AIndex then
        FEdges[I][J] := V - 1;
      Dec(J);
    end;
    FEdges[I].Sort;
  end;
end;

procedure TDAG.RemapEdgesByPermutation(const OldToNew: array of integer);
var
  NewEdges: array of TEdgeList;
  OldI, NewI, J: integer;
begin
  SetLength(NewEdges, FCapacity);
  for OldI := 0 to FCount - 1 do
  begin
    NewI := OldToNew[OldI];
    NewEdges[NewI] := TEdgeList.Create;
    for J := 0 to FEdges[OldI].Count - 1 do
      NewEdges[NewI].AddSortedUnique(OldToNew[FEdges[OldI][J]]);
  end;

  for OldI := 0 to FCount - 1 do
    FreeAndNil(FEdges[OldI]);

  for NewI := 0 to FCount - 1 do
    FEdges[NewI] := NewEdges[NewI];

  InvalidateIndex;
end;

procedure TDAG.Exchange(AIndex1, AIndex2: integer);
var
  Tmp: T;
  OldToNew: array of integer;
  I: integer;
begin
  CheckIndex(AIndex1);
  CheckIndex(AIndex2);
  if AIndex1 = AIndex2 then
    Exit;

  SetLength(OldToNew, FCount);
  for I := 0 to FCount - 1 do
    OldToNew[I] := I;

  OldToNew[AIndex1] := AIndex2;
  OldToNew[AIndex2] := AIndex1;

  Tmp := FItems[AIndex1];
  FItems[AIndex1] := FItems[AIndex2];
  FItems[AIndex2] := Tmp;

  RemapEdgesByPermutation(OldToNew);
end;

procedure TDAG.Move(ACurIndex, ANewIndex: integer);
var
  OldItems: array of T;
  OldToNew: array of integer;
  I, K: integer;
begin
  CheckIndex(ACurIndex);
  CheckIndex(ANewIndex);
  if ACurIndex = ANewIndex then
    Exit;

  SetLength(OldItems, FCount);
  SetLength(OldToNew, FCount);
  for I := 0 to FCount - 1 do
    OldItems[I] := FItems[I];

  K := 0;
  for I := 0 to FCount - 1 do
  begin
    if I = ANewIndex then
    begin
      FItems[K] := OldItems[ACurIndex];
      OldToNew[ACurIndex] := K;
      Inc(K);
    end;
    if I <> ACurIndex then
    begin
      FItems[K] := OldItems[I];
      OldToNew[I] := K;
      Inc(K);
    end;
  end;

  RemapEdgesByPermutation(OldToNew);
end;

procedure TDAG.Reverse;
var
  OldToNew: array of integer;
  OldItems: array of T;
  I: integer;
begin
  SetLength(OldToNew, FCount);
  SetLength(OldItems, FCount);
  for I := 0 to FCount - 1 do
  begin
    OldItems[I] := FItems[I];
    OldToNew[I] := FCount - 1 - I;
  end;

  for I := 0 to FCount - 1 do
    FItems[FCount - 1 - I] := OldItems[I];

  RemapEdgesByPermutation(OldToNew);
end;

procedure TDAG.Sort;
begin
  if not Assigned(FComparer) then
    raise EListError.Create('Comparer is not assigned');
  Sort(FComparer);
end;

procedure TDAG.Sort(AComparer: TCompareFunc);
var
  Idx: array of integer;
  NewItems: array of T;
  OldToNew: array of integer;

  procedure QuickSort(L, R: integer);
  var
    I, J, P, TIdx: integer;
    Pivot: T;
  begin
    I := L;
    J := R;
    P := Idx[(L + R) shr 1];
    Pivot := FItems[P];
    repeat
      while AComparer(FItems[Idx[I]], Pivot) < 0 do
        Inc(I);
      while AComparer(FItems[Idx[J]], Pivot) > 0 do
        Dec(J);
      if I <= J then
      begin
        TIdx := Idx[I];
        Idx[I] := Idx[J];
        Idx[J] := TIdx;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(L, J);
    if I < R then
      QuickSort(I, R);
  end;

var
  I: integer;
begin
  if not Assigned(AComparer) then
    raise EListError.Create('Comparer is not assigned');
  if FCount <= 1 then
    Exit;

  SetLength(Idx, FCount);
  SetLength(NewItems, FCount);
  SetLength(OldToNew, FCount);
  for I := 0 to FCount - 1 do
    Idx[I] := I;

  QuickSort(0, FCount - 1);

  for I := 0 to FCount - 1 do
  begin
    NewItems[I] := FItems[Idx[I]];
    OldToNew[Idx[I]] := I;
  end;

  for I := 0 to FCount - 1 do
    FItems[I] := NewItems[I];

  RemapEdgesByPermutation(OldToNew);
end;

procedure TDAG.Assign(const ASource: specialize TDAG<T>);
var
  I, J: integer;
begin
  Clear;
  Capacity := ASource.Count;
  for I := 0 to ASource.Count - 1 do
    Add(ASource[I]);
  for I := 0 to ASource.Count - 1 do
    if ASource.FEdges[I] <> nil then
      for J := 0 to ASource.FEdges[I].Count - 1 do
        AddEdgeByIndex(I, ASource.FEdges[I][J]);
end;

procedure TDAG.CopyTo(var ADest: array of T);
var
  I: integer;
begin
  if Length(ADest) < FCount then
    raise EListError.Create('Destination array is too small');
  for I := 0 to FCount - 1 do
    ADest[I] := FItems[I];
end;

procedure TDAG.AddEdge(const AFromValue, AToValue: T);
var
  A, B: integer;
begin
  if not TryFindIndex(AFromValue, A) then
    raise EListError.Create('Source vertex not found');
  if not TryFindIndex(AToValue, B) then
    raise EListError.Create('Target vertex not found');
  AddEdgeByIndex(A, B);
end;

procedure TDAG.AddEdgeByIndex(AFrom, ATo: integer);
begin
  CheckIndex(AFrom);
  CheckIndex(ATo);
  if AFrom = ATo then
    raise EListError.Create('Self-loop is not allowed in DAG');
  if HasEdgeByIndex(AFrom, ATo) then
    Exit;
  if WouldCreateCycle(AFrom, ATo) then
    raise EListError.Create('Edge would create a cycle');
  FEdges[AFrom].AddSortedUnique(ATo);
end;

function TDAG.RemoveEdge(const AFromValue, AToValue: T): boolean;
var
  A, B: integer;
begin
  if not TryFindIndex(AFromValue, A) then
    Exit(False);
  if not TryFindIndex(AToValue, B) then
    Exit(False);
  Result := RemoveEdgeByIndex(A, B);
end;

function TDAG.RemoveEdgeByIndex(AFrom, ATo: integer): boolean;
begin
  CheckIndex(AFrom);
  CheckIndex(ATo);
  Result := FEdges[AFrom].RemoveSortedValue(ATo);
end;

function TDAG.HasEdge(const AFromValue, AToValue: T): boolean;
var
  A, B: integer;
begin
  if not TryFindIndex(AFromValue, A) then
    Exit(False);
  if not TryFindIndex(AToValue, B) then
    Exit(False);
  Result := HasEdgeByIndex(A, B);
end;

function TDAG.HasEdgeByIndex(AFrom, ATo: integer): boolean;
var
  P: integer;
begin
  CheckIndex(AFrom);
  CheckIndex(ATo);
  Result := FEdges[AFrom].BinarySearchValue(ATo, P);
end;

function TDAG.HasPathIndex(AFrom, ATo: integer): boolean;
var
  Stack: array of integer;
  Visited: array of boolean;
  SP, V, I, N: integer;
begin
  if AFrom = ATo then
    Exit(True);

  SetLength(Stack, FCount);
  SetLength(Visited, FCount);
  SP := 0;
  Stack[SP] := AFrom;
  Inc(SP);
  Visited[AFrom] := True;

  while SP > 0 do
  begin
    Dec(SP);
    V := Stack[SP];
    for I := 0 to FEdges[V].Count - 1 do
    begin
      N := FEdges[V][I];
      if N = ATo then
        Exit(True);
      if not Visited[N] then
      begin
        Visited[N] := True;
        Stack[SP] := N;
        Inc(SP);
      end;
    end;
  end;
  Result := False;
end;

function TDAG.WouldCreateCycle(AFrom, ATo: integer): boolean;
begin
  Result := HasPathIndex(ATo, AFrom);
end;

function TDAG.HasPath(const AFromValue, AToValue: T): boolean;
var
  A, B: integer;
begin
  if not TryFindIndex(AFromValue, A) then
    Exit(False);
  if not TryFindIndex(AToValue, B) then
    Exit(False);
  Result := HasPathIndex(A, B);
end;

function TDAG.HasPathByIndex(AFrom, ATo: integer): boolean;
begin
  CheckIndex(AFrom);
  CheckIndex(ATo);
  Result := HasPathIndex(AFrom, ATo);
end;

function TDAG.OutDegree(AIndex: integer): integer;
begin
  CheckIndex(AIndex);
  Result := FEdges[AIndex].Count;
end;

function TDAG.EdgeTo(AIndex, AEdgeNo: integer): integer;
begin
  CheckIndex(AIndex);
  if (AEdgeNo < 0) or (AEdgeNo >= FEdges[AIndex].Count) then
    raise EListError.CreateFmt('Edge index out of bounds: %d', [AEdgeNo]);
  Result := FEdges[AIndex][AEdgeNo];
end;

function TDAG.CanCreateCycle(const AFromValue, AToValue: T): boolean;
var
  A, B: integer;
begin
  if not TryFindIndex(AFromValue, A) then
    raise EListError.Create('Source vertex not found');
  if not TryFindIndex(AToValue, B) then
    raise EListError.Create('Target vertex not found');

  Result := WouldCreateCycle(A, B);
end;

function TDAG.IsAcyclic: boolean;
begin
  try
    TopologicalSort.Free;
    Result := True;
  except
    on E: Exception do
      Result := False;
  end;
end;

function TDAG.TopologicalSort: specialize TList<integer>;
var
  InDeg: array of integer;
  Queue: array of integer;
  Head, Tail: integer;
  I, J, V, N, Seen: integer;
begin
  Result := TIntList.Create;
  try
    SetLength(InDeg, FCount);
    SetLength(Queue, FCount);

    for I := 0 to FCount - 1 do
      for J := 0 to FEdges[I].Count - 1 do
        Inc(InDeg[FEdges[I][J]]);

    Head := 0;
    Tail := 0;
    for I := 0 to FCount - 1 do
      if InDeg[I] = 0 then
      begin
        Queue[Tail] := I;
        Inc(Tail);
      end;

    Seen := 0;
    while Head < Tail do
    begin
      V := Queue[Head];
      Inc(Head);
      Result.Add(V);
      Inc(Seen);
      for J := 0 to FEdges[V].Count - 1 do
      begin
        N := FEdges[V][J];
        Dec(InDeg[N]);
        if InDeg[N] = 0 then
        begin
          Queue[Tail] := N;
          Inc(Tail);
        end;
      end;
    end;

    if Seen <> FCount then
    begin
      Result.Free;
      raise EListError.Create('Graph contains a cycle');
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
