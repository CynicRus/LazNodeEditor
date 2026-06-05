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
unit LazNodeEditor.Debugger;

{$mode objfpc}{$H+}

interface

uses
  Generics.Collections, Classes, SysUtils, Rtti,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Runtime,
  LazNodeEditor.DebugIntf;

type
  TStepMode = (smNone, smStepOver, smStepInto);

  { TExecutionStackFrame }
  TExecutionStackFrame = class
  public
    Node: TCustomNode;
    NodeTitle: string;
    NodeType: string;
    Depth: Integer;
    constructor Create(ANode: TCustomNode; ADepth: Integer);
  end;

  { TBreakpoint }
  TBreakpoint = class
  public
    Node: TCustomNode;
    Pin: TNodePin;
    Enabled: Boolean;
    HitCount: Integer;
    Condition: string;
    constructor Create(ANode: TCustomNode; APin: TNodePin = nil);
  end;

  { TWatchItem }
  TWatchItem = class
  public
    Expression: string;
    LastValue: TValue;
    HasValue: Boolean;
    constructor Create(const AExpression: string);
  end;

  { TExecutionTraceEntry }
  TExecutionTraceEntry = class
  public
    Step: Integer;
    Node: TCustomNode;
    Pin: TNodePin;
    NodeTitle: string;
    NodeType: string;
    PinName: string;
    EventKind: string;
    Timestamp: TDateTime;
    constructor Create(AStep: Integer; const AEventKind: string;
      ANode: TCustomNode; APin: TNodePin = nil);
  end;

  TDebuggerBreakpointEvent = procedure(BP: TBreakpoint;
    Context: INodeExecutionContext) of object;

  TDebuggerPauseEvent = procedure(ANode: TCustomNode; APin: TNodePin;
    Context: INodeExecutionContext) of object;

  { TGraphDebugger }
  TGraphDebugger = class(TNoRefCountObject, IGraphDebugger)
  private
    FGraph: TNodeGraph;
    FBreakpoints: specialize TObjectList<TBreakpoint>;
    FExecutionStack: specialize TObjectList<TExecutionStackFrame>;
    FWatches: specialize TObjectList<TWatchItem>;
    FTrace: specialize TObjectList<TExecutionTraceEntry>;

    FIsPaused: Boolean;
    FStepMode: TStepMode;
    FPauseRequested: Boolean;
    FLastSteppedNode: TCustomNode;

    FTraceEnabled: Boolean;
    FMaxTraceEntries: Integer;

    FOnBreakpointHit: TDebuggerBreakpointEvent;
    FOnPaused: TDebuggerPauseEvent;

    function FindBreakpoint(ANode: TCustomNode; APin: TNodePin = nil): TBreakpoint;
    function EvaluateCondition(BP: TBreakpoint;
      AContext: INodeExecutionContext): Boolean;
    procedure UpdateWatches(AContext: INodeExecutionContext);
    procedure TrimTrace;
  public
    constructor Create(AGraph: TNodeGraph);
    destructor Destroy; override;

    procedure ResetSession;

    { Breakpoints }
    procedure AddBreakpoint(ANode: TCustomNode; APin: TNodePin = nil;
      const ACondition: string = '');
    procedure RemoveBreakpoint(ANode: TCustomNode; APin: TNodePin = nil);
    function HasBreakpoint(ANode: TCustomNode; APin: TNodePin = nil): Boolean;
    procedure ClearAllBreakpoints;

    { Watches }
    procedure AddWatch(const Expression: string);
    procedure RemoveWatch(const Expression: string);
    procedure ClearWatches;
    property Watches: specialize TObjectList<TWatchItem> read FWatches;

    { Trace }
    procedure AddTraceEntry(const AEventKind: string; ANode: TCustomNode;
      APin: TNodePin = nil; const AContext: INodeExecutionContext = nil);
    property Trace: specialize TObjectList<TExecutionTraceEntry> read FTrace;
    property TraceEnabled: Boolean read FTraceEnabled write FTraceEnabled;
    property MaxTraceEntries: Integer read FMaxTraceEntries write FMaxTraceEntries;

    { Execution stack }
    procedure PushNode(ANode: TCustomNode);
    procedure PopNode(ANode: TCustomNode = nil);
    procedure ClearExecutionStack;
    property ExecutionStack: specialize TObjectList<TExecutionStackFrame> read FExecutionStack;

    { Execution control }
    procedure Pause;
    procedure Continue;
    procedure StepOver;
    procedure StepInto;

    function CheckPause(ANode: TCustomNode; APin: TNodePin = nil;
      const AContext: INodeExecutionContext = nil): Boolean;

    property IsPaused: Boolean read FIsPaused;
    property StepMode: TStepMode read FStepMode;
    property PauseRequested: Boolean read FPauseRequested;

    property OnBreakpointHit: TDebuggerBreakpointEvent
      read FOnBreakpointHit write FOnBreakpointHit;
    property OnPaused: TDebuggerPauseEvent
      read FOnPaused write FOnPaused;
  end;

implementation

function TryExtractOperator(const S: string; out AOperator: string): Boolean;
begin
  Result := True;
  if Pos('==', S) > 0 then AOperator := '=='
  else if Pos('!=', S) > 0 then AOperator := '!='
  else if Pos('>=', S) > 0 then AOperator := '>='
  else if Pos('<=', S) > 0 then AOperator := '<='
  else if Pos('>', S) > 0 then AOperator := '>'
  else if Pos('<', S) > 0 then AOperator := '<'
  else
    Result := False;
end;

{ TExecutionStackFrame }

constructor TExecutionStackFrame.Create(ANode: TCustomNode; ADepth: Integer);
begin
  inherited Create;
  Node := ANode;
  if ANode <> nil then
  begin
    NodeTitle := ANode.Title;
    NodeType := ANode.NodeType;
  end
  else
  begin
    NodeTitle := '';
    NodeType := '';
  end;
  Depth := ADepth;
end;

{ TBreakpoint }

constructor TBreakpoint.Create(ANode: TCustomNode; APin: TNodePin);
begin
  inherited Create;
  Node := ANode;
  Pin := APin;
  Enabled := True;
  HitCount := 0;
  Condition := '';
end;

{ TWatchItem }

constructor TWatchItem.Create(const AExpression: string);
begin
  inherited Create;
  Expression := AExpression;
  LastValue := Default(TValue);
  HasValue := False;
end;

{ TExecutionTraceEntry }

constructor TExecutionTraceEntry.Create(AStep: Integer; const AEventKind: string;
  ANode: TCustomNode; APin: TNodePin);
begin
  inherited Create;
  Step := AStep;
  EventKind := AEventKind;
  Node := ANode;
  Pin := APin;

  if ANode <> nil then
  begin
    NodeTitle := ANode.Title;
    NodeType := ANode.NodeType;
  end
  else
  begin
    NodeTitle := '';
    NodeType := '';
  end;

  if APin <> nil then
    PinName := APin.Name
  else
    PinName := '';

  Timestamp := Now;
end;

{ TGraphDebugger }

constructor TGraphDebugger.Create(AGraph: TNodeGraph);
begin
  inherited Create;
  FGraph := AGraph;
  FBreakpoints := specialize TObjectList<TBreakpoint>.Create(True);
  FExecutionStack := specialize TObjectList<TExecutionStackFrame>.Create(True);
  FWatches := specialize TObjectList<TWatchItem>.Create(True);
  FTrace := specialize TObjectList<TExecutionTraceEntry>.Create(True);

  FIsPaused := False;
  FPauseRequested := False;
  FStepMode := smNone;
  FLastSteppedNode := nil;

  FTraceEnabled := True;
  FMaxTraceEntries := 1000;
end;

destructor TGraphDebugger.Destroy;
begin
  FTrace.Free;
  FWatches.Free;
  FExecutionStack.Free;
  FBreakpoints.Free;
  inherited Destroy;
end;

procedure TGraphDebugger.ResetSession;
var
  BP: TBreakpoint;
begin
  FIsPaused := False;
  FPauseRequested := False;
  FStepMode := smNone;
  FLastSteppedNode := nil;
  FExecutionStack.Clear;
  FTrace.Clear;

  for BP in FBreakpoints do
    BP.HitCount := 0;
end;

function TGraphDebugger.FindBreakpoint(ANode: TCustomNode; APin: TNodePin): TBreakpoint;
var
  BP: TBreakpoint;
begin
  Result := nil;
  for BP in FBreakpoints do
    if (BP.Node = ANode) and (BP.Pin = APin) then
      Exit(BP);

  if APin <> nil then
    for BP in FBreakpoints do
      if (BP.Node = ANode) and (BP.Pin = nil) then
        Exit(BP);
end;

procedure TGraphDebugger.AddBreakpoint(ANode: TCustomNode; APin: TNodePin;
  const ACondition: string);
var
  BP: TBreakpoint;
begin
  if ANode = nil then
    Exit;

  BP := FindBreakpoint(ANode, APin);
  if (BP <> nil) and (BP.Pin = APin) then
  begin
    BP.Condition := ACondition;
    Exit;
  end;

  BP := TBreakpoint.Create(ANode, APin);
  BP.Condition := ACondition;
  FBreakpoints.Add(BP);
end;

procedure TGraphDebugger.RemoveBreakpoint(ANode: TCustomNode; APin: TNodePin);
var
  i: Integer;
  BP: TBreakpoint;
begin
  for i := FBreakpoints.Count - 1 downto 0 do
  begin
    BP := FBreakpoints[i];
    if (BP.Node = ANode) and (BP.Pin = APin) then
      FBreakpoints.Delete(i);
  end;
end;

function TGraphDebugger.HasBreakpoint(ANode: TCustomNode; APin: TNodePin): Boolean;
var
  BP: TBreakpoint;
begin
  BP := FindBreakpoint(ANode, APin);
  Result := BP <> nil;
end;

procedure TGraphDebugger.ClearAllBreakpoints;
begin
  FBreakpoints.Clear;
end;

procedure TGraphDebugger.AddWatch(const Expression: string);
begin
  if Trim(Expression) = '' then
    Exit;
  FWatches.Add(TWatchItem.Create(Expression));
end;

procedure TGraphDebugger.RemoveWatch(const Expression: string);
var
  i: Integer;
begin
  for i := FWatches.Count - 1 downto 0 do
    if SameText(FWatches[i].Expression, Expression) then
      FWatches.Delete(i);
end;

procedure TGraphDebugger.ClearWatches;
begin
  FWatches.Clear;
end;

procedure TGraphDebugger.TrimTrace;
begin
  while FTrace.Count > FMaxTraceEntries do
    FTrace.Delete(0);
end;

procedure TGraphDebugger.AddTraceEntry(const AEventKind: string;
  ANode: TCustomNode; APin: TNodePin; const AContext: INodeExecutionContext);
var
  Entry: TExecutionTraceEntry;
  StepNo: Integer;
begin
  if not FTraceEnabled then
    Exit;

  if AContext <> nil then
    StepNo := AContext.StepCounter
  else
    StepNo := FTrace.Count + 1;

  Entry := TExecutionTraceEntry.Create(StepNo, AEventKind, ANode, APin);
  FTrace.Add(Entry);
  TrimTrace;

  if AContext <> nil then
    UpdateWatches(AContext);
end;

procedure TGraphDebugger.PushNode(ANode: TCustomNode);
begin
  if ANode = nil then
    Exit;
  FExecutionStack.Add(TExecutionStackFrame.Create(ANode, FExecutionStack.Count));
end;

procedure TGraphDebugger.PopNode(ANode: TCustomNode);
var
  Last: TExecutionStackFrame;
begin
  if FExecutionStack.Count = 0 then
    Exit;

  Last := FExecutionStack[FExecutionStack.Count - 1];
  if (ANode = nil) or (Last.Node = ANode) then
    FExecutionStack.Delete(FExecutionStack.Count - 1);
end;

procedure TGraphDebugger.ClearExecutionStack;
begin
  FExecutionStack.Clear;
end;

procedure TGraphDebugger.Pause;
begin
  FPauseRequested := True;
end;

procedure TGraphDebugger.Continue;
begin
  FPauseRequested := False;
  FIsPaused := False;
  FStepMode := smNone;
  FLastSteppedNode := nil;
end;

procedure TGraphDebugger.StepOver;
begin
  FPauseRequested := False;
  FIsPaused := False;
  FStepMode := smStepOver;
  FLastSteppedNode := nil;
end;

procedure TGraphDebugger.StepInto;
begin
  FPauseRequested := False;
  FIsPaused := False;
  FStepMode := smStepInto;
  FLastSteppedNode := nil;
end;

function TGraphDebugger.EvaluateCondition(BP: TBreakpoint;
  AContext: INodeExecutionContext): Boolean;
var
  Cond, VarName, Op, ValueStr: string;
  P: SizeInt;
  ActualValue: TValue;
  ActualFloat, ExpectedFloat: Double;
  ActualStr, ExpectedStr: string;
  NumOk: Boolean;
begin
  Result := True;
  if (BP = nil) or (Trim(BP.Condition) = '') then
    Exit;

  if AContext = nil then
    Exit(False);

  Cond := Trim(BP.Condition);

  if SameText(Copy(Cond, 1, 8), 'HitCount') then
  begin
    if Pos('>=', Cond) > 0 then
      Exit(BP.HitCount >= StrToIntDef(Trim(Copy(Cond, Pos('>=', Cond) + 2, MaxInt)), 0));
    if Pos('<=', Cond) > 0 then
      Exit(BP.HitCount <= StrToIntDef(Trim(Copy(Cond, Pos('<=', Cond) + 2, MaxInt)), 0));
    if Pos('==', Cond) > 0 then
      Exit(BP.HitCount = StrToIntDef(Trim(Copy(Cond, Pos('==', Cond) + 2, MaxInt)), 0));
    if Pos('!=', Cond) > 0 then
      Exit(BP.HitCount <> StrToIntDef(Trim(Copy(Cond, Pos('!=', Cond) + 2, MaxInt)), 0));
    if Pos('>', Cond) > 0 then
      Exit(BP.HitCount > StrToIntDef(Trim(Copy(Cond, Pos('>', Cond) + 1, MaxInt)), 0));
    if Pos('<', Cond) > 0 then
      Exit(BP.HitCount < StrToIntDef(Trim(Copy(Cond, Pos('<', Cond) + 1, MaxInt)), 0));
    Exit(True);
  end;

  if not TryExtractOperator(Cond, Op) then
    Exit(True);

  P := Pos(Op, Cond);
  if P <= 0 then
    Exit(True);

  VarName := Trim(Copy(Cond, 1, P - 1));
  ValueStr := Trim(Copy(Cond, P + Length(Op), MaxInt));

  ActualValue := AContext.GetVariableValue(VarName);

  NumOk := TryStrToFloat(ValueStr, ExpectedFloat, DefaultFormatSettings);
  if NumOk then
  begin
    ActualFloat := NodeValueToFloatDef(ActualValue, 0.0);
    case Op of
      '==': Result := Abs(ActualFloat - ExpectedFloat) <= 1e-12;
      '!=': Result := Abs(ActualFloat - ExpectedFloat) > 1e-12;
      '>':  Result := ActualFloat > ExpectedFloat;
      '<':  Result := ActualFloat < ExpectedFloat;
      '>=': Result := ActualFloat >= ExpectedFloat;
      '<=': Result := ActualFloat <= ExpectedFloat;
    else
      Result := True;
    end;
    Exit;
  end;

  ActualStr := NodeValueToStringDef(ActualValue, '');
  ExpectedStr := ValueStr;

  case Op of
    '==': Result := SameText(ActualStr, ExpectedStr);
    '!=': Result := not SameText(ActualStr, ExpectedStr);
    '>':  Result := CompareText(ActualStr, ExpectedStr) > 0;
    '<':  Result := CompareText(ActualStr, ExpectedStr) < 0;
    '>=': Result := CompareText(ActualStr, ExpectedStr) >= 0;
    '<=': Result := CompareText(ActualStr, ExpectedStr) <= 0;
  else
    Result := True;
  end;
end;

procedure TGraphDebugger.UpdateWatches(AContext: INodeExecutionContext);
var
  W: TWatchItem;
  V: TValue;
begin
  if (AContext = nil) or (FWatches.Count = 0) then
    Exit;

  for W in FWatches do
  begin
    V := AContext.GetVariableValue(W.Expression);
    W.LastValue := V;
    W.HasValue := not V.IsEmpty;
  end;
end;

function TGraphDebugger.CheckPause(ANode: TCustomNode; APin: TNodePin;
  const AContext: INodeExecutionContext): Boolean;
var
  BP: TBreakpoint;
begin
  Result := False;

  if ANode = nil then
    Exit;

  AddTraceEntry('visit', ANode, APin, AContext);

  if FPauseRequested then
  begin
    FPauseRequested := False;
    FIsPaused := True;
    Result := True;
  end;

  BP := FindBreakpoint(ANode, APin);
  if (not Result) and (BP <> nil) and BP.Enabled then
  begin
    Inc(BP.HitCount);
    if (BP.Condition = '') or EvaluateCondition(BP, AContext) then
    begin
      Result := True;
      FIsPaused := True;
      if Assigned(FOnBreakpointHit) then
        FOnBreakpointHit(BP, AContext);
    end;
  end;

  if (not Result) and (FStepMode <> smNone) then
  begin
    case FStepMode of
      smStepInto:
        begin
          Result := True;
          FIsPaused := True;
          FStepMode := smNone;
        end;

      smStepOver:
        begin
          if FLastSteppedNode = nil then
            FLastSteppedNode := ANode
          else if FLastSteppedNode <> ANode then
          begin
            Result := True;
            FIsPaused := True;
            FStepMode := smNone;
            FLastSteppedNode := nil;
          end;
        end;
    end;
  end;

  if Result and Assigned(FOnPaused) then
    FOnPaused(ANode, APin, AContext);
end;

end.
