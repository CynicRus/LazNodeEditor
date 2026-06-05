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
unit LazNodeEditor.Runtime;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections, Rtti,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.DebugIntf;

type
  TNodeExecutionContext = class;
  TExecutableNode = class;

  ENodeExecutionError = class(Exception);
  ENodeBreakSignal = class(ENodeExecutionError);
  ENodeContinueSignal = class(ENodeExecutionError);
  ENodeDebuggerPause = class(ENodeExecutionError);
  ENodeExecutionStopped = class(ENodeExecutionError);

  TNodeValueState = (
    nvsMissing,
    nvsEvaluating,
    nvsReady
  );

  TNodeExecutedEvent = procedure(AContext: TNodeExecutionContext;
    ANode: TExecutableNode) of object;

  { TExecutableNode }

  TExecutableNode = class(TCustomNode)
  public
    function GetExecInputPin: TNodePin; virtual;
    procedure Execute(AContext: TNodeExecutionContext); virtual;
  end;

  { TPinRuntimeValue }

  TPinRuntimeValue = class
  public
    State: TNodeValueState;
    Value: TValue;
    constructor Create;
  end;

  { TNodeExecutionContext }

  TNodeExecutionContext = class(TNoRefCountObject, INodeExecutionContext)
  private
    FGraph: TNodeGraph;
    FPinValues: specialize TObjectDictionary<TNodePin, TPinRuntimeValue>;
    FVariables: specialize TDictionary<string, TValue>;
    FEventQueue: specialize TDictionary<string, TValue>;
    FEventListeners: specialize TDictionary<string, string>;
    FTriggeredListeners: specialize TDictionary<string, TValue>;
    FStepCounter: Integer;
    FMaxStepCount: Integer;
    FLastExecutedNode: TCustomNode;
    FLastExecOutputPin: TNodePin;
    FDebugger: IGraphDebugger;
    FOnNodeExecuted: TNodeExecutedEvent;
    function GetPinEntry(APin: TNodePin; ACreate: Boolean): TPinRuntimeValue;
    function GetStepCounter: Integer;
  public
    constructor Create(AGraph: TNodeGraph);
    destructor Destroy; override;

    procedure Clear;

    property Graph: TNodeGraph read FGraph;
    property LastExecutedNode: TCustomNode read FLastExecutedNode write FLastExecutedNode;
    property LastExecOutputPin: TNodePin read FLastExecOutputPin write FLastExecOutputPin;
    property StepCounter: Integer read FStepCounter;
    property MaxStepCount: Integer read FMaxStepCount write FMaxStepCount;

    property Debugger: IGraphDebugger read FDebugger write FDebugger;
    property OnNodeExecuted: TNodeExecutedEvent
      read FOnNodeExecuted write FOnNodeExecuted;

    function HasPinValue(APin: TNodePin): Boolean;
    function TryGetPinValue(APin: TNodePin; out AValue: TValue): Boolean;
    procedure SetPinValue(APin: TNodePin; const AValue: TValue);

    function GetPinState(APin: TNodePin): TNodeValueState;
    procedure SetPinState(APin: TNodePin; AState: TNodeValueState);

    function TryGetVariable(const AName: string; out AValue: TValue): Boolean;
    procedure SetVariable(const AName: string; const AValue: TValue);

    function GetVariableValue(const AName: string): TValue;
    function GetVariableStr(const AName, ADefault: string): string;
    function GetVariableFloat(const AName: string; const ADefault: Double = 0.0): Double;
    function GetVariableBool(const AName: string; const ADefault: Boolean = False): Boolean;

    procedure SetVariableStr(const AName, AValue: string);
    procedure SetVariableFloat(const AName: string; const AValue: Double);
    procedure SetVariableBool(const AName: string; const AValue: Boolean);

    function GetInputValue(APin: TNodePin): TValue;
    procedure SetOutputValue(APin: TNodePin; const AValue: TValue);

    procedure RaiseEvent(const AEventName: string; const AData: TValue);
    procedure RegisterEventListener(const AListenerId, AEventName: string);
    function WasListenerTriggered(const AListenerId: string; out AData: TValue): Boolean;

    procedure IncStep;
    procedure SelectExecOutput(APin: TNodePin);
  end;

  { TNodeGraphRuntimeHelper }

  TNodeGraphRuntimeHelper = class helper for TNodeGraph
  public
    function FindIncomingLink(APin: TNodePin): TNodeLink;
    function FindOutgoingLinks(APin: TNodePin; AList: TList): integer;

    function EvaluatePinValue(APin: TNodePin; AContext: TNodeExecutionContext): TValue;
    function EvaluateNodeOutput(ANode: TCustomNode; APin: TNodePin;
      AContext: TNodeExecutionContext): TValue;

    function GetInputPinValue(APin: TNodePin; AContext: TNodeExecutionContext): TValue;
    function GetInputPinValueByIndex(ANode: TCustomNode; AIndex: integer;
      AContext: TNodeExecutionContext): TValue;

    function ExecuteDataFlow(AContext: TNodeExecutionContext = nil): boolean;
    function FindExecOutgoingLinks(APin: TNodePin; AList: TList): integer;
    function FindFirstConnectedExecOutput(ANode: TCustomNode): TNodePin;
    function ExecuteExecPin(APin: TNodePin; AContext: TNodeExecutionContext): boolean;
    function ExecuteFromNode(ANode: TCustomNode; AContext: TNodeExecutionContext): boolean;
  end;

function NodeValueToFloatDef(const AValue: TValue; const ADefault: double = 0.0): double;
function NodeValueToStringDef(const AValue: TValue; const ADefault: string = ''): string;
function MakeFloatValue(const AValue: double): TValue;
function MakeBoolValue(const AValue: boolean): TValue;
function MakeIntValue(const AValue: int64): TValue;
function MakeStringValue(const AValue: string): TValue;
function NodeValueToBoolDef(const AValue: TValue; const ADefault: boolean = False): boolean;
function NodeValueToIntDef(const AValue: TValue; const ADefault: Int64 = 0): Int64;
procedure CheckThreadStopped;

implementation

function NodeValueToFloatDef(const AValue: TValue; const ADefault: double): double;
begin
  Result := ADefault;

  if AValue.IsEmpty then
    Exit;

  case AValue.Kind of
    tkFloat:
      Result := AValue.AsExtended;
    tkInteger:
      Result := AValue.AsInteger;
    tkInt64:
      Result := AValue.AsInt64;
    tkQWord:
      Result := AValue.AsUInt64;
    tkBool:
      if AValue.AsBoolean then
        Result := 1.0
      else
        Result := 0.0;
    tkAString, tkLString, tkWString, tkUString:
    begin
      if not TryStrToFloat(AValue.AsString, Result, DefaultFormatSettings) then
        Result := ADefault;
    end;
  end;
end;

function NodeValueToStringDef(const AValue: TValue; const ADefault: string): string;
begin
  if AValue.IsEmpty then
    Exit(ADefault);

  case AValue.Kind of
    tkAString, tkLString, tkWString, tkUString:
      Result := AValue.AsString;
    tkInteger:
      Result := IntToStr(AValue.AsInteger);
    tkInt64:
      Result := IntToStr(AValue.AsInt64);
    tkQWord:
      Result := UIntToStr(AValue.AsUInt64);
    tkFloat:
      Result := FloatToStr(AValue.AsExtended, DefaultFormatSettings);
    tkBool:
      if AValue.AsBoolean then
        Result := 'True'
      else
        Result := 'False';
    else
      Result := ADefault;
  end;
end;

function MakeFloatValue(const AValue: double): TValue;
begin
  Result := AValue;
end;

function MakeBoolValue(const AValue: boolean): TValue;
begin
  Result := AValue;
end;

function MakeIntValue(const AValue: int64): TValue;
begin
  Result := AValue;
end;

function MakeStringValue(const AValue: string): TValue;
begin
  Result := AValue;
end;

function NodeValueToBoolDef(const AValue: TValue; const ADefault: boolean): boolean;
var
  S: string;
begin
  if AValue.IsEmpty then
    Exit(ADefault);

  case AValue.Kind of
    tkBool:
      Result := AValue.AsBoolean;
    tkInteger:
      Result := AValue.AsInteger <> 0;
    tkInt64:
      Result := AValue.AsInt64 <> 0;
    tkQWord:
      Result := AValue.AsUInt64 <> 0;
    tkFloat:
      Result := Abs(AValue.AsExtended) > 1e-12;
    tkAString, tkLString, tkWString, tkUString:
    begin
      S := Trim(LowerCase(AValue.AsString));
      Result := (S = 'true') or (S = '1') or (S = 'yes');
    end;
  else
    Result := ADefault;
  end;
end;

function NodeValueToIntDef(const AValue: TValue; const ADefault: Int64): Int64;
begin
  if AValue.IsEmpty then
    Exit(ADefault);

  case AValue.Kind of
    tkInteger:
      Result := AValue.AsInteger;
    tkInt64:
      Result := AValue.AsInt64;
    tkQWord:
      Result := AValue.AsUInt64;
    tkFloat:
      Result := Trunc(AValue.AsExtended);
    tkBool:
      if AValue.AsBoolean then
        Result := 1
      else
        Result := 0;
    tkAString, tkLString, tkWString, tkUString:
    begin
      if not TryStrToInt64(AValue.AsString, Result) then
        Result := ADefault;
    end;
  else
    Result := ADefault;
  end;
end;

procedure CheckThreadStopped;
begin
  if (TThread.CurrentThread <> nil) and TThread.CurrentThread.CheckTerminated then
    raise ENodeExecutionStopped.Create('Execution stopped');
end;

{ TPinRuntimeValue }

constructor TPinRuntimeValue.Create;
begin
  inherited Create;
  State := nvsMissing;
  Value := Default(TValue);
end;

{ TNodeExecutionContext }

constructor TNodeExecutionContext.Create(AGraph: TNodeGraph);
begin
  inherited Create;
  FGraph := AGraph;
  FPinValues := specialize TObjectDictionary<TNodePin, TPinRuntimeValue>.Create([doOwnsValues]);
  FVariables := specialize TDictionary<string, TValue>.Create;
  FEventQueue := specialize TDictionary<string, TValue>.Create;
  FEventListeners := specialize TDictionary<string, string>.Create;
  FTriggeredListeners := specialize TDictionary<string, TValue>.Create;
  FMaxStepCount := 10000;
  FStepCounter := 0;
  FLastExecutedNode := nil;
  FLastExecOutputPin := nil;
  FDebugger := nil;
  FOnNodeExecuted := nil;
end;

destructor TNodeExecutionContext.Destroy;
begin
  FTriggeredListeners.Free;
  FEventListeners.Free;
  FEventQueue.Free;
  FVariables.Free;
  FPinValues.Free;
  inherited Destroy;
end;

procedure TNodeExecutionContext.Clear;
begin
  FPinValues.Clear;
  FVariables.Clear;
  FEventQueue.Clear;
  FEventListeners.Clear;
  FTriggeredListeners.Clear;
  FStepCounter := 0;
  FLastExecutedNode := nil;
  FLastExecOutputPin := nil;
end;

function TNodeExecutionContext.GetPinEntry(APin: TNodePin; ACreate: Boolean
  ): TPinRuntimeValue;
begin
  Result := nil;
  if APin = nil then
    Exit;

  if not FPinValues.TryGetValue(APin, Result) then
  begin
    if ACreate then
    begin
      Result := TPinRuntimeValue.Create;
      FPinValues.Add(APin, Result);
    end;
  end;
end;

function TNodeExecutionContext.GetStepCounter: Integer;
begin
  Result := FStepCounter;
end;

function TNodeExecutionContext.HasPinValue(APin: TNodePin): Boolean;
var
  E: TPinRuntimeValue;
begin
  E := GetPinEntry(APin, False);
  Result := (E <> nil) and (E.State = nvsReady);
end;

function TNodeExecutionContext.TryGetPinValue(APin: TNodePin; out AValue: TValue
  ): Boolean;
var
  E: TPinRuntimeValue;
begin
  E := GetPinEntry(APin, False);
  Result := (E <> nil) and (E.State = nvsReady);
  if Result then
    AValue := E.Value
  else
    AValue := Default(TValue);
end;

procedure TNodeExecutionContext.SetPinValue(APin: TNodePin; const AValue: TValue);
var
  E: TPinRuntimeValue;
begin
  if APin = nil then
    Exit;
  E := GetPinEntry(APin, True);
  E.Value := AValue;
  E.State := nvsReady;
end;

function TNodeExecutionContext.GetPinState(APin: TNodePin): TNodeValueState;
var
  E: TPinRuntimeValue;
begin
  E := GetPinEntry(APin, False);
  if E = nil then
    Result := nvsMissing
  else
    Result := E.State;
end;

procedure TNodeExecutionContext.SetPinState(APin: TNodePin; AState: TNodeValueState);
var
  E: TPinRuntimeValue;
begin
  if APin = nil then
    Exit;
  E := GetPinEntry(APin, True);
  E.State := AState;
  if AState <> nvsReady then
    E.Value := Default(TValue);
end;

function TNodeExecutionContext.TryGetVariable(const AName: string; out
  AValue: TValue): Boolean;
begin
  Result := FVariables.TryGetValue(AName, AValue);
end;

procedure TNodeExecutionContext.SetVariable(const AName: string; const AValue: TValue);
begin
  if AName = '' then
    Exit;
  FVariables.AddOrSetValue(AName, AValue);
end;

function TNodeExecutionContext.GetVariableValue(const AName: string): TValue;
begin
  if not TryGetVariable(AName, Result) then
    Result := Default(TValue);
end;

function TNodeExecutionContext.GetVariableStr(const AName, ADefault: string): string;
begin
  Result := NodeValueToStringDef(GetVariableValue(AName), ADefault);
end;

function TNodeExecutionContext.GetVariableFloat(const AName: string;
  const ADefault: Double): Double;
begin
  Result := NodeValueToFloatDef(GetVariableValue(AName), ADefault);
end;

function TNodeExecutionContext.GetVariableBool(const AName: string;
  const ADefault: Boolean): Boolean;
var
  V: TValue;
  S: string;
begin
  V := GetVariableValue(AName);
  if V.IsEmpty then
    Exit(ADefault);

  case V.Kind of
    tkBool:
      Result := V.AsBoolean;
    tkInteger:
      Result := V.AsInteger <> 0;
    tkInt64:
      Result := V.AsInt64 <> 0;
    tkFloat:
      Result := Abs(V.AsExtended) > 1e-12;
    tkAString, tkLString, tkWString, tkUString:
    begin
      S := Trim(LowerCase(V.AsString));
      Result := (S = 'true') or (S = '1') or (S = 'yes');
    end;
  else
    Result := ADefault;
  end;
end;

procedure TNodeExecutionContext.SetVariableStr(const AName, AValue: string);
begin
  SetVariable(AName, MakeStringValue(AValue));
end;

procedure TNodeExecutionContext.SetVariableFloat(const AName: string;
  const AValue: Double);
begin
  SetVariable(AName, MakeFloatValue(AValue));
end;

procedure TNodeExecutionContext.SetVariableBool(const AName: string;
  const AValue: Boolean);
begin
  SetVariable(AName, MakeBoolValue(AValue));
end;

function TNodeExecutionContext.GetInputValue(APin: TNodePin): TValue;
begin
  if FGraph = nil then
    raise ENodeExecutionError.Create('Execution context has no graph');
  Result := FGraph.GetInputPinValue(APin, Self);
end;

procedure TNodeExecutionContext.SetOutputValue(APin: TNodePin; const AValue: TValue);
begin
  if APin = nil then
    Exit;
  if APin.Direction <> pdOutput then
    raise ENodeExecutionError.Create('SetOutputValue expects output pin');
  SetPinValue(APin, AValue);
end;

procedure TNodeExecutionContext.RaiseEvent(const AEventName: string; const AData: TValue);
var
  Pair: specialize TPair<string, string>;
begin
  if Trim(AEventName) = '' then
    Exit;

  FEventQueue.AddOrSetValue(AEventName, AData);

  for Pair in FEventListeners do
    if SameText(Pair.Value, AEventName) then
      FTriggeredListeners.AddOrSetValue(Pair.Key, AData);
end;

procedure TNodeExecutionContext.RegisterEventListener(
  const AListenerId, AEventName: string);
var
  Data: TValue;
begin
  if (Trim(AListenerId) = '') or (Trim(AEventName) = '') then
    Exit;

  FEventListeners.AddOrSetValue(AListenerId, AEventName);

  if FEventQueue.TryGetValue(AEventName, Data) then
    FTriggeredListeners.AddOrSetValue(AListenerId, Data);
end;

function TNodeExecutionContext.WasListenerTriggered(const AListenerId: string;
  out AData: TValue): Boolean;
begin
  Result := FTriggeredListeners.TryGetValue(AListenerId, AData);
end;

procedure TNodeExecutionContext.IncStep;
begin
  CheckThreadStopped;
  Inc(FStepCounter);
  if (FMaxStepCount > 0) and (FStepCounter > FMaxStepCount) then
    raise ENodeExecutionError.CreateFmt(
      'Execution step limit exceeded (%d)', [FMaxStepCount]);
end;

procedure TNodeExecutionContext.SelectExecOutput(APin: TNodePin);
begin
  if (APin <> nil) and (APin.Direction <> pdOutput) then
    raise ENodeExecutionError.Create('Selected exec output must be output pin');
  FLastExecOutputPin := APin;
end;

{ TExecutableNode }

function TExecutableNode.GetExecInputPin: TNodePin;
var
  i: integer;
  P: TNodePin;
begin
  Result := nil;
  for i := 0 to InputCount - 1 do
  begin
    P := GetInput(i);
    if (P <> nil) and (P.Kind = pkExec) then
      Exit(P);
  end;
end;

procedure TExecutableNode.Execute(AContext: TNodeExecutionContext);
begin
end;

{ TNodeGraphRuntimeHelper }

function TNodeGraphRuntimeHelper.FindIncomingLink(APin: TNodePin): TNodeLink;
var
  i: integer;
  L: TNodeLink;
begin
  Result := nil;
  if APin = nil then
    Exit;

  for i := 0 to Links.Count - 1 do
  begin
    L := Links[i];
    if (L <> nil) and (L.ToPin = APin) then
      Exit(L);
  end;
end;

function TNodeGraphRuntimeHelper.FindOutgoingLinks(APin: TNodePin;
  AList: TList): integer;
var
  i: integer;
  L: TNodeLink;
begin
  Result := 0;
  if (APin = nil) or (AList = nil) then
    Exit;

  AList.Clear;
  for i := 0 to Links.Count - 1 do
  begin
    L := Links[i];
    if (L <> nil) and (L.FromPin = APin) then
      AList.Add(L);
  end;
  Result := AList.Count;
end;

function TNodeGraphRuntimeHelper.GetInputPinValue(APin: TNodePin;
  AContext: TNodeExecutionContext): TValue;
var
  L: TNodeLink;
  DefValue: double;
begin
  Result := Default(TValue);

  if APin = nil then
    Exit;

  if APin.Direction <> pdInput then
    raise ENodeExecutionError.Create('GetInputPinValue expects input pin: ' + APin.Name);

  L := FindIncomingLink(APin);
  if (L <> nil) and (L.FromPin <> nil) then
    Exit(EvaluatePinValue(L.FromPin, AContext));

  if Trim(APin.DefaultValue) <> '' then
  begin
    if SameText(APin.DataType, 'float') then
    begin
      if TryStrToFloat(APin.DefaultValue, DefValue, DefaultFormatSettings) then
        Exit(MakeFloatValue(DefValue));
    end
    else if SameText(APin.DataType, 'string') then
      Exit(MakeStringValue(APin.DefaultValue))
    else if SameText(APin.DataType, 'bool') then
      Exit(MakeBoolValue(SameText(APin.DefaultValue, 'true') or
        (APin.DefaultValue = '1')));
  end;

  if SameText(APin.DataType, 'float') then
    Exit(MakeFloatValue(0.0));

  if SameText(APin.DataType, 'bool') then
    Exit(MakeBoolValue(False));

  if SameText(APin.DataType, 'string') then
    Exit(MakeStringValue(''));
end;

function TNodeGraphRuntimeHelper.GetInputPinValueByIndex(ANode: TCustomNode;
  AIndex: integer; AContext: TNodeExecutionContext): TValue;
var
  P: TNodePin;
begin
  if ANode = nil then
    raise ENodeExecutionError.Create('Node is nil');

  P := ANode.GetInput(AIndex);
  if P = nil then
    raise ENodeExecutionError.CreateFmt('Input pin index %d out of range for node "%s"',
      [AIndex, ANode.Title]);

  Result := GetInputPinValue(P, AContext);
end;

function TNodeGraphRuntimeHelper.EvaluatePinValue(APin: TNodePin;
  AContext: TNodeExecutionContext): TValue;
var
  Cached: TValue;
  OwnerNode: TCustomNode;
begin
  CheckThreadStopped;
  Result := Default(TValue);

  if APin = nil then
    Exit;

  if AContext = nil then
    raise ENodeExecutionError.Create('Execution context is nil');

  if AContext.TryGetPinValue(APin, Cached) then
    Exit(Cached);

  if AContext.GetPinState(APin) = nvsEvaluating then
    raise ENodeExecutionError.CreateFmt(
      'Cycle detected while evaluating pin "%s" of node "%s"',
      [APin.Name, specialize IfThen<string>(APin.OwnerNode <> nil,
      TCustomNode(APin.OwnerNode).Title, '?')]);

  if APin.Direction = pdInput then
    Exit(GetInputPinValue(APin, AContext));

  OwnerNode := TCustomNode(APin.OwnerNode);
  if OwnerNode = nil then
    raise ENodeExecutionError.Create('Output pin has no owner node');

  AContext.SetPinState(APin, nvsEvaluating);
  try
    Result := EvaluateNodeOutput(OwnerNode, APin, AContext);
    AContext.SetPinValue(APin, Result);
  except
    AContext.SetPinState(APin, nvsMissing);
    raise;
  end;
end;

function TNodeGraphRuntimeHelper.EvaluateNodeOutput(ANode: TCustomNode;
  APin: TNodePin; AContext: TNodeExecutionContext): TValue;
var
  V: TNodeValue;
  AValue, BValue: TValue;
  AFloat, BFloat: double;
  ExecNode: TExecutableNode;
begin
  Result := Default(TValue);

  if (ANode = nil) or (APin = nil) then
    Exit;

  if AContext = nil then
    raise ENodeExecutionError.Create('Execution context is nil');

  if AContext.TryGetPinValue(APin, Result) then
    Exit;

  if ANode is TExecutableNode then
  begin
    ExecNode := TExecutableNode(ANode);

    AContext.IncStep;
    AContext.LastExecutedNode := ANode;
    AContext.LastExecOutputPin := nil;

    ExecNode.Execute(AContext);

    if AContext.TryGetPinValue(APin, Result) then
      Exit;

    if APin.Kind = pkData then
      raise ENodeExecutionError.CreateFmt(
        'Node "%s" did not produce value for output pin "%s"',
        [ANode.Title, APin.Name]);

    Exit(Default(TValue));
  end;

  if SameText(ANode.NodeType, 'float') then
  begin
    if not SameText(APin.Name, 'Value') and (ANode.OutputCount > 0) and
      (APin <> ANode.GetOutput(0)) then
      raise ENodeExecutionError.CreateFmt('Unsupported output pin "%s" for node "%s"',
        [APin.Name, ANode.Title]);

    V := ANode.FindValue('value');
    if V = nil then
      Exit(MakeFloatValue(0.0));

    case V.Kind of
      nvkFloat:
        Result := MakeFloatValue(V.FloatValue);
      nvkInteger:
        Result := MakeIntValue(V.IntegerValue);
      nvkBoolean:
        Result := MakeBoolValue(V.BooleanValue);
      nvkString:
        Result := MakeStringValue(V.StringValue);
      else
        Result := MakeFloatValue(0.0);
    end;
    Exit;
  end;

  if SameText(ANode.NodeType, 'add') then
  begin
    AValue := GetInputPinValueByIndex(ANode, 0, AContext);
    BValue := GetInputPinValueByIndex(ANode, 1, AContext);

    AFloat := NodeValueToFloatDef(AValue, 0.0);
    BFloat := NodeValueToFloatDef(BValue, 0.0);

    Result := MakeFloatValue(AFloat + BFloat);
    Exit;
  end;

  if SameText(ANode.NodeType, 'reroute') then
  begin
    Result := GetInputPinValueByIndex(ANode, 0, AContext);
    Exit;
  end;

  if SameText(ANode.NodeType, 'default') then
  begin
    if ANode.InputCount > 0 then
      Result := GetInputPinValueByIndex(ANode, 0, AContext)
    else
      Result := Default(TValue);
    Exit;
  end;

  if SameText(ANode.NodeType, 'comment') then
  begin
    Result := Default(TValue);
    Exit;
  end;

  raise ENodeExecutionError.CreateFmt(
    'Runtime evaluator for node type "%s" is not implemented', [ANode.NodeType]);
end;

function TNodeGraphRuntimeHelper.ExecuteDataFlow(AContext:
  TNodeExecutionContext): boolean;
var
  OwnContext: boolean;
  Ctx: TNodeExecutionContext;
  Order: TList;
  i, j: integer;
  N: TCustomNode;
  P: TNodePin;
begin
  Result := False;

  if HasCycle then
    raise ENodeExecutionError.Create('Graph contains cycle');

  OwnContext := AContext = nil;
  if OwnContext then
    Ctx := TNodeExecutionContext.Create(Self)
  else
    Ctx := AContext;

  Order := TList.Create;
  try
    TopologicalSortDataNodes(Order);

    for i := 0 to Order.Count - 1 do
    begin
      CheckThreadStopped;
      N := TCustomNode(Order[i]);
      if (N = nil) or (N.VisualKind = nvComment) then
        Continue;

      if (Ctx.Debugger <> nil) and Ctx.Debugger.CheckPause(N, nil, Ctx) then
        raise ENodeDebuggerPause.Create('Execution paused by debugger');

      for j := 0 to N.OutputCount - 1 do
      begin
        CheckThreadStopped;
        P := N.GetOutput(j);
        if (P <> nil) and (P.Kind = pkData) then
          EvaluatePinValue(P, Ctx);
      end;
    end;

    Result := True;
  finally
    Order.Free;
    if OwnContext then
      Ctx.Free;
  end;
end;

function TNodeGraphRuntimeHelper.FindExecOutgoingLinks(APin: TNodePin;
  AList: TList): integer;
var
  i: integer;
  L: TNodeLink;
begin
  Result := 0;
  if (APin = nil) or (AList = nil) then
    Exit;

  AList.Clear;
  for i := 0 to Links.Count - 1 do
  begin
    L := Links[i];
    if (L <> nil) and (L.FromPin = APin) and (L.FromPin.Kind = pkExec) and
       (L.ToPin <> nil) and (L.ToPin.Kind = pkExec) then
      AList.Add(L);
  end;
  Result := AList.Count;
end;

function TNodeGraphRuntimeHelper.FindFirstConnectedExecOutput(
  ANode: TCustomNode): TNodePin;
var
  i: integer;
  P: TNodePin;
  Tmp: TList;
begin
  Result := nil;
  if ANode = nil then
    Exit;

  Tmp := TList.Create;
  try
    for i := 0 to ANode.OutputCount - 1 do
    begin
      P := ANode.GetOutput(i);
      if (P <> nil) and (P.Kind = pkExec) then
      begin
        if FindExecOutgoingLinks(P, Tmp) > 0 then
          Exit(P);
      end;
    end;
  finally
    Tmp.Free;
  end;
end;

function TNodeGraphRuntimeHelper.ExecuteExecPin(APin: TNodePin;
  AContext: TNodeExecutionContext): boolean;
var
  L: TList;
  Link: TNodeLink;
  NextNode: TCustomNode;
begin
  CheckThreadStopped;
  Result := False;

  if (APin = nil) or (AContext = nil) then
    Exit;

  if APin.Kind <> pkExec then
    raise ENodeExecutionError.Create('ExecuteExecPin expects exec output pin');

  AContext.LastExecOutputPin := APin;

  if AContext.Debugger <> nil then
    AContext.Debugger.AddTraceEntry('exec-out', TCustomNode(APin.OwnerNode), APin, AContext);

  L := TList.Create;
  try
    FindExecOutgoingLinks(APin, L);
    if L.Count = 0 then
      Exit(True);

    Link := TNodeLink(L[0]);
    if (Link <> nil) and (Link.ToPin <> nil) then
    begin
      NextNode := TCustomNode(Link.ToPin.OwnerNode);
      if NextNode <> nil then
      begin
        if AContext.Debugger <> nil then
          AContext.Debugger.AddTraceEntry('exec-in', NextNode, Link.ToPin, AContext);
        Result := ExecuteFromNode(NextNode, AContext);
      end
      else
        Result := True;
    end
    else
      Result := True;
  finally
    L.Free;
  end;
end;

function TNodeGraphRuntimeHelper.ExecuteFromNode(ANode: TCustomNode;
  AContext: TNodeExecutionContext): boolean;
var
  ExecNode: TExecutableNode;
  NextExecPin: TNodePin;
begin
  CheckThreadStopped;
  Result := False;

  if (ANode = nil) or (AContext = nil) then
    Exit;

  if AContext.Debugger <> nil then
  begin
    if AContext.Debugger.CheckPause(ANode, nil, AContext) then
      raise ENodeDebuggerPause.Create('Execution paused by debugger');
    AContext.Debugger.PushNode(ANode);
    AContext.Debugger.AddTraceEntry('enter-node', ANode, nil, AContext);
  end;

  try
    AContext.IncStep;
    AContext.LastExecutedNode := ANode;
    AContext.LastExecOutputPin := nil;

    if not (ANode is TExecutableNode) then
      Exit(True);

    ExecNode := TExecutableNode(ANode);
    ExecNode.Execute(AContext);

    if Assigned(AContext.OnNodeExecuted) then
      AContext.OnNodeExecuted(AContext, ExecNode);

    if AContext.Debugger <> nil then
      AContext.Debugger.AddTraceEntry('executed', ANode, nil, AContext);

    NextExecPin := AContext.LastExecOutputPin;
    if (NextExecPin = nil) or (NextExecPin.OwnerNode <> ANode) then
      NextExecPin := FindFirstConnectedExecOutput(ANode);

    if NextExecPin <> nil then
      Result := ExecuteExecPin(NextExecPin, AContext)
    else
      Result := True;
  finally
    if AContext.Debugger <> nil then
    begin
      AContext.Debugger.AddTraceEntry('leave-node', ANode, nil, AContext);
      AContext.Debugger.PopNode(ANode);
    end;
  end;
end;

end.
