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
unit LazNodeEditor.ControlFlowNodes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Rtti,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Runtime;

type
  { TBranchNode }
  TBranchNode = class(TExecutableNode)
  private
    FConditionPin: TNodePin;
    FTrueExecPin, FFalseExecPin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180; AHeight: integer = 120); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { TLoopNode }
  TLoopNode = class(TExecutableNode)
  private
    FConditionPin: TNodePin;
    FBodyExecPin, FExitExecPin: TNodePin;
    FIndexPin, FFirstIterationPin, FLastIterationPin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 220; AHeight: integer = 160); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { TForLoopNode }
  TForLoopNode = class(TExecutableNode)
  private
    FStartPin, FEndPin, FStepPin: TNodePin;
    FBodyExecPin, FExitExecPin: TNodePin;
    FIndexPin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 200; AHeight: integer = 150); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { TSequenceNode }
  TSequenceNode = class(TExecutableNode)
  private
    FSteps: array of TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 200; AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
    procedure AddStep;
    procedure RemoveLastStep;
    function StepCount: integer;
  end;

  { TBreakNode }
  TBreakNode = class(TExecutableNode)
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 140; AHeight: integer = 80); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { TContinueNode }
  TContinueNode = class(TExecutableNode)
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 140; AHeight: integer = 80); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { TSwitchNode }
  TSwitchNode = class(TExecutableNode)
  private
    FValuePin: TNodePin;
    FCases: array of record
      ValuePin: TNodePin;
      ExecPin: TNodePin;
    end;
    FDefaultExecPin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 220; AHeight: integer = 180); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
    procedure AddCase;
  end;

  { TWaitNode }
  TWaitNode = class(TExecutableNode)
  private
    FDurationPin: TNodePin;
    FDoneExecPin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 160; AHeight: integer = 100); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { TEventNode }
  TEventNode = class(TExecutableNode)
  private
    FTriggerExecPin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 160; AHeight: integer = 100); override;
    procedure Trigger(AContext: TNodeExecutionContext = nil);
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { TEventCallNode }
  TEventCallNode = class(TExecutableNode)
  private
    FEventNamePin: TNodePin;
    FDataPin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180; AHeight: integer = 110); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { TEventListenerNode }
  TEventListenerNode = class(TExecutableNode)
  private
    FEventNamePin: TNodePin;
    FDataOutputPin: TNodePin;
    FTriggeredExecPin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 200; AHeight: integer = 120); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

procedure RegisterControlFlowNodes(ARegistry: TNodeRegistry);

implementation

procedure RegisterControlFlowNodes(ARegistry: TNodeRegistry);
begin
  if ARegistry = nil then
    Exit;

  ARegistry.RegisterNodeEx('branch', 'Branch', 'Control Flow',
    'Conditional branch by boolean condition',
    'if,branch,condition,true,false',
    TBranchNode, $00FFE082);

  ARegistry.RegisterNodeEx('loop', 'Loop', 'Control Flow',
    'While-like loop with condition input and body/exit exec outputs',
    'loop,while,cycle,iteration',
    TLoopNode, $00FFCC80);

  ARegistry.RegisterNodeEx('forloop', 'For Loop', 'Control Flow',
    'For loop with start, end and step',
    'for,loop,cycle,iteration,index',
    TForLoopNode, $00FFCC80);

  ARegistry.RegisterNodeEx('sequence', 'Sequence', 'Control Flow',
    'Executes several exec outputs one by one',
    'sequence,steps,order,exec',
    TSequenceNode, $00B39DDB);

  ARegistry.RegisterNodeEx('break', 'Break', 'Control Flow',
    'Break current loop',
    'break,loop,stop',
    TBreakNode, $00EF9A9A);

  ARegistry.RegisterNodeEx('continue', 'Continue', 'Control Flow',
    'Continue current loop iteration',
    'continue,loop,skip',
    TContinueNode, $0090CAF9);

  ARegistry.RegisterNodeEx('switch', 'Switch', 'Control Flow',
    'Selects exec output by input value',
    'switch,case,branch,select',
    TSwitchNode, $00CE93D8);

  ARegistry.RegisterNodeEx('wait', 'Wait', 'Control Flow',
    'Wait for specified duration in milliseconds',
    'wait,delay,sleep,timer',
    TWaitNode, $00A5D6A7);

  ARegistry.RegisterNodeEx('event', 'Event', 'Events',
    'Event source node',
    'event,trigger,signal',
    TEventNode, $0080CBC4);

  ARegistry.RegisterNodeEx('eventcall', 'Call Event', 'Events',
    'Raise named event with payload',
    'event,call,emit,signal',
    TEventCallNode, $0080CBC4);

  ARegistry.RegisterNodeEx('eventlistener', 'Event Listener', 'Events',
    'Listen named event and output payload when triggered',
    'event,listener,subscribe,signal',
    TEventListenerNode, $0080CBC4);
end;

{ ==================== TBranchNode ==================== }
constructor TBranchNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'branch';
end;

procedure TBranchNode.SetupPins;
begin
  ClearPins;
  AddInputPin('Exec', 'exec', pkExec);
  FConditionPin := AddInputPin('Condition', 'bool', pkData);
  FTrueExecPin := AddOutputPin('True', 'exec', pkExec);
  FFalseExecPin := AddOutputPin('False', 'exec', pkExec);
end;

procedure TBranchNode.Execute(AContext: TNodeExecutionContext);
var
  Cond: boolean;
begin
  if AContext = nil then Exit;

  Cond := NodeValueToBoolDef(AContext.GetInputValue(FConditionPin), False);
  AContext.SetVariableBool('BranchResult_' + Self.Id, Cond);

  if Cond then
    AContext.SelectExecOutput(FTrueExecPin)
  else
    AContext.SelectExecOutput(FFalseExecPin);
end;

{ ==================== TLoopNode ==================== }
constructor TLoopNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'loop';
end;

procedure TLoopNode.SetupPins;
begin
  ClearPins;
  AddInputPin('Enter', 'exec', pkExec);
  FConditionPin := AddInputPin('Condition', 'bool', pkData);
  FBodyExecPin := AddOutputPin('Body', 'exec', pkExec);
  FExitExecPin := AddOutputPin('Exit', 'exec', pkExec);
  FIndexPin := AddOutputPin('Index', 'integer', pkData);
  FFirstIterationPin := AddOutputPin('First', 'bool', pkData);
  FLastIterationPin := AddOutputPin('Last', 'bool', pkData);
end;

procedure TLoopNode.Execute(AContext: TNodeExecutionContext);
var
  Iter: Int64;
  Cond: Boolean;
begin
  if AContext = nil then
    Exit;

  Iter := 0;
  while True do
  begin
    CheckThreadStopped;

    Cond := NodeValueToBoolDef(AContext.GetInputValue(FConditionPin), False);
    if not Cond then
      Break;

    AContext.SetOutputValue(FIndexPin, MakeIntValue(Iter));
    AContext.SetOutputValue(FFirstIterationPin, MakeBoolValue(Iter = 0));
    AContext.SetOutputValue(FLastIterationPin, MakeBoolValue(False));

    try
      AContext.Graph.ExecuteExecPin(FBodyExecPin, AContext);
    except
      on E: ENodeContinueSignal do
      begin
      end;
      on E: ENodeBreakSignal do
        Break;
    end;

    Inc(Iter);
  end;

  AContext.SetOutputValue(FLastIterationPin, MakeBoolValue(True));
  AContext.SelectExecOutput(FExitExecPin);
end;

{ ==================== TForLoopNode ==================== }
constructor TForLoopNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'forloop';
end;

procedure TForLoopNode.SetupPins;
begin
  ClearPins;
  AddInputPin('Enter', 'exec', pkExec);
  FStartPin := AddInputPin('Start', 'integer', pkData);
  FEndPin := AddInputPin('End', 'integer', pkData);
  FStepPin := AddInputPin('Step', 'integer', pkData);
  FBodyExecPin := AddOutputPin('Body', 'exec', pkExec);
  FExitExecPin := AddOutputPin('Exit', 'exec', pkExec);
  FIndexPin := AddOutputPin('Index', 'integer', pkData);
end;

procedure TForLoopNode.Execute(AContext: TNodeExecutionContext);
var
  StartVal, EndVal, StepVal, I: Int64;
begin
  if AContext = nil then
    Exit;

  StartVal := NodeValueToIntDef(AContext.GetInputValue(FStartPin), 0);
  EndVal := NodeValueToIntDef(AContext.GetInputValue(FEndPin), 0);
  StepVal := NodeValueToIntDef(AContext.GetInputValue(FStepPin), 1);

  if StepVal = 0 then
    StepVal := 1;

  I := StartVal;
  while (((StepVal > 0) and (I <= EndVal)) or
         ((StepVal < 0) and (I >= EndVal))) do
  begin
    CheckThreadStopped;

    AContext.SetVariable('last_for_index_' + Self.Id, MakeIntValue(I));
    AContext.SetVariable('last_for_index', MakeIntValue(I));
    AContext.SetOutputValue(FIndexPin, MakeIntValue(I));
    try
      AContext.Graph.ExecuteExecPin(FBodyExecPin, AContext);
    except
      on E: ENodeContinueSignal do
      begin
      end;
      on E: ENodeBreakSignal do
        Break;
    end;

    Inc(I, StepVal);
  end;

  AContext.SelectExecOutput(FExitExecPin);
end;

{ ==================== TSequenceNode ==================== }
constructor TSequenceNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'sequence';
end;

procedure TSequenceNode.SetupPins;
begin
  ClearPins;
  SetLength(FSteps, 0);
  AddInputPin('Exec', 'exec', pkExec);
  AddStep;
  AddStep;
  AddStep;
end;

procedure TSequenceNode.AddStep;
var
  NewPin: TNodePin;
begin
  NewPin := AddOutputPin('Step ' + IntToStr(Length(FSteps) + 1), 'exec', pkExec);
  SetLength(FSteps, Length(FSteps) + 1);
  FSteps[High(FSteps)] := NewPin;
end;

procedure TSequenceNode.RemoveLastStep;
begin
  if Length(FSteps) = 0 then Exit;
  RemovePin(FSteps[High(FSteps)]);
  SetLength(FSteps, Length(FSteps) - 1);
end;

function TSequenceNode.StepCount: integer;
begin
  Result := Length(FSteps);
end;

procedure TSequenceNode.Execute(AContext: TNodeExecutionContext);
var
  i: Integer;
begin
  if AContext = nil then
    Exit;

  for i := 0 to High(FSteps) do
  begin
    CheckThreadStopped;
    if FSteps[i] <> nil then
      AContext.Graph.ExecuteExecPin(FSteps[i], AContext);
  end;

  AContext.SelectExecOutput(nil);
end;

{ ==================== TBreakNode ==================== }
constructor TBreakNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'break';
end;

procedure TBreakNode.SetupPins;
begin
  ClearPins;
  AddInputPin('Exec', 'exec', pkExec);
end;

procedure TBreakNode.Execute(AContext: TNodeExecutionContext);
begin
  raise ENodeBreakSignal.Create('Break');
end;

{ ==================== TContinueNode ==================== }
constructor TContinueNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'continue';
end;

procedure TContinueNode.SetupPins;
begin
  ClearPins;
  AddInputPin('Exec', 'exec', pkExec);
end;

procedure TContinueNode.Execute(AContext: TNodeExecutionContext);
begin
  raise ENodeContinueSignal.Create('Continue');
end;

{ ==================== TSwitchNode ==================== }
constructor TSwitchNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'switch';
end;

procedure TSwitchNode.SetupPins;
begin
  ClearPins;
  SetLength(FCases, 0);
  AddInputPin('Exec', 'exec', pkExec);
  FValuePin := AddInputPin('Value', 'any', pkData);
  FDefaultExecPin := AddOutputPin('Default', 'exec', pkExec);
  AddCase;
  AddCase;
end;

procedure TSwitchNode.AddCase;
var
  Idx: Integer;
begin
  Idx := Length(FCases);
  SetLength(FCases, Idx + 1);
  FCases[Idx].ValuePin := AddInputPin('CaseValue' + IntToStr(Idx), 'any', pkData);
  FCases[Idx].ExecPin := AddOutputPin('Case' + IntToStr(Idx), 'exec', pkExec);
end;

procedure TSwitchNode.Execute(AContext: TNodeExecutionContext);
var
  Value, CaseValue: string;
  i: Integer;
begin
  if AContext = nil then
    Exit;

  CheckThreadStopped;
  Value := NodeValueToStringDef(AContext.GetInputValue(FValuePin), '');

  for i := 0 to High(FCases) do
  begin
    CaseValue := NodeValueToStringDef(AContext.GetInputValue(FCases[i].ValuePin), '');
    if SameText(CaseValue, Value) then
    begin
      AContext.SetVariable('SwitchCase_' + Self.Id, MakeIntValue(i));
      AContext.SelectExecOutput(FCases[i].ExecPin);
      Exit;
    end;
  end;

  AContext.SetVariable('SwitchCase_' + Self.Id, MakeIntValue(-1));
  AContext.SelectExecOutput(FDefaultExecPin);
end;

{ ==================== TWaitNode ==================== }
constructor TWaitNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'wait';
end;

procedure TWaitNode.SetupPins;
begin
  ClearPins;
  AddInputPin('Exec', 'exec', pkExec);
  FDurationPin := AddInputPin('Duration (ms)', 'float', pkData);
  FDoneExecPin := AddOutputPin('Done', 'exec', pkExec);
end;

procedure TWaitNode.Execute(AContext: TNodeExecutionContext);
var
  Duration: Double;
begin
  if AContext = nil then
    Exit;

  Duration := NodeValueToFloatDef(AContext.GetInputValue(FDurationPin), 0);
  if Duration > 0 then
  begin
    CheckThreadStopped;
    Sleep(Trunc(Duration));
    CheckThreadStopped;
  end;

  AContext.SetVariableFloat('WaitDuration_' + Self.Id, Duration);
  AContext.SelectExecOutput(FDoneExecPin);
end;

{ ==================== TEventNode ==================== }
constructor TEventNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'event';
end;

procedure TEventNode.SetupPins;
begin
  ClearPins;
  FTriggerExecPin := AddOutputPin('Trigger', 'exec', pkExec);
end;

procedure TEventNode.Trigger(AContext: TNodeExecutionContext);
begin
  if AContext = nil then
    Exit;
  AContext.SetVariableBool('EventFired_' + Self.Id, True);
  AContext.Graph.ExecuteExecPin(FTriggerExecPin, AContext);
end;

procedure TEventNode.Execute(AContext: TNodeExecutionContext);
begin
  if AContext <> nil then
    AContext.SetVariableBool('EventExecuted_' + Self.Id, True);
end;

{ ==================== TEventCallNode ==================== }
constructor TEventCallNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'eventcall';
end;

procedure TEventCallNode.SetupPins;
begin
  ClearPins;
  AddInputPin('Exec', 'exec', pkExec);
  FEventNamePin := AddInputPin('Event Name', 'string', pkData);
  FDataPin := AddInputPin('Data', 'any', pkData);
end;

procedure TEventCallNode.Execute(AContext: TNodeExecutionContext);
var
  EventName: string;
  EventData: TValue;
begin
  if AContext = nil then Exit;

  EventName := NodeValueToStringDef(AContext.GetInputValue(FEventNamePin), '');
  EventData := AContext.GetInputValue(FDataPin);

  if EventName <> '' then
    AContext.RaiseEvent(EventName, EventData);

  AContext.SelectExecOutput(nil);
end;

{ ==================== TEventListenerNode ==================== }
constructor TEventListenerNode.Create(ATitle: string; AX, AY: single; AWidth, AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'eventlistener';
end;

procedure TEventListenerNode.SetupPins;
begin
  ClearPins;
  AddInputPin('Activate', 'exec', pkExec);
  FEventNamePin := AddInputPin('Event Name', 'string', pkData);
  FTriggeredExecPin := AddOutputPin('Triggered', 'exec', pkExec);
  FDataOutputPin := AddOutputPin('Data', 'any', pkData);
end;

procedure TEventListenerNode.Execute(AContext: TNodeExecutionContext);
var
  EventName: string;
  ReceivedData: TValue;
begin
  if AContext = nil then Exit;

  EventName := NodeValueToStringDef(AContext.GetInputValue(FEventNamePin), '');
  if EventName = '' then Exit;

  AContext.RegisterEventListener(Self.Id, EventName);

  if AContext.WasListenerTriggered(Self.Id, ReceivedData) then
  begin
    AContext.SetOutputValue(FDataOutputPin, ReceivedData);
    AContext.SetVariableBool('ListenerTriggered_' + Self.Id, True);
    AContext.SelectExecOutput(FTriggeredExecPin);
  end
  else
    AContext.SelectExecOutput(nil);
end;

end.
