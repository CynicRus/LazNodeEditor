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
unit LazNodeEditor.DebuggerController;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Editor,
  LazNodeEditor.Graph,
  LazNodeEditor.Debugger,
  LazNodeEditor.Executor,
  LazNodeEditor.ExecutionThread,
  LazNodeEditor.Runtime,
  LazNodeEditor.DebugIntf;

type
  TDebugState = (dsStopped, dsRunning, dsPaused, dsError);

  { TNodeEditorDebugger }

  TNodeEditorDebugger = class
  private
    FEditor: TLazNodeEditor;
    FGraph: TNodeGraph;
    FDebugger: TGraphDebugger;
    FExecutor: TGraphExecutor;
    FThread: TGraphExecutionThread;
    FState: TDebugState;

    FOnStateChanged: TNotifyEvent;

    procedure SetState(AValue: TDebugState);
    procedure OnThreadFinished(Sender: TObject; Success: Boolean; const ErrorMessage: string);
    procedure OnThreadError(Sender: TObject; const ErrorInfo: TThreadErrorInfo);
    procedure OnDebuggerPaused(ANode: TCustomNode; APin: TNodePin; Context: INodeExecutionContext);
    procedure HandleThreadDebuggerPaused(Sender: TObject; ANode: TCustomNode;
      APin: TNodePin; Context: INodeExecutionContext);
  public
    constructor Create(AEditor: TLazNodeEditor);
    destructor Destroy; override;

    procedure Run;
    procedure Pause;
    procedure ContinueExecution;
    procedure StepOver;
    procedure StepInto;
    procedure Stop;

    procedure ToggleBreakpoint(ANode: TCustomNode);
    procedure SetBreakpoint(ANode: TCustomNode; const Condition: string = '');

    property Editor: TLazNodeEditor read FEditor;
    property Debugger: TGraphDebugger read FDebugger;
    property Executor: TGraphExecutor read FExecutor;
    property State: TDebugState read FState;

    property OnStateChanged: TNotifyEvent read FOnStateChanged write FOnStateChanged;
  end;

implementation

constructor TNodeEditorDebugger.Create(AEditor: TLazNodeEditor);
begin
  inherited Create;
  FEditor := AEditor;
  FGraph := AEditor.Graph;

  FDebugger := TGraphDebugger.Create(FGraph);
  FExecutor := TGraphExecutor.Create(FGraph);
  FExecutor.Debugger := FDebugger;
end;

destructor TNodeEditorDebugger.Destroy;
begin
  Stop;
  FExecutor.Free;
  FDebugger.Free;
  inherited Destroy;
end;

procedure TNodeEditorDebugger.SetState(AValue: TDebugState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  if Assigned(FOnStateChanged) then
    FOnStateChanged(Self);
end;

procedure TNodeEditorDebugger.Run;
var
  i: integer;
  StartNode: TExecutableNode;
  N: TCustomNode;
begin
  Stop;

  StartNode := nil;

  if (FEditor <> nil) and (FEditor.SelectedNodeCount > 0) then
  begin
    N := FEditor.GetSelectedNode(0);
    if N is TExecutableNode then
      StartNode := TExecutableNode(N);
  end;

  if StartNode = nil then
    for i := 0 to FGraph.Nodes.Count - 1 do
    begin
      N := TCustomNode(FGraph.Nodes[i]);
      if N is TExecutableNode then
      begin
        StartNode := TExecutableNode(N);
        Break;
      end;
    end;

  if StartNode = nil then
  begin
    SetState(dsError);
    Exit;
  end;

  FThread := TGraphExecutionThread.Create(FGraph, StartNode, FDebugger);
  FThread.OnFinished := @OnThreadFinished;
  FThread.OnError := @OnThreadError;
  FThread.OnDebuggerPaused := @HandleThreadDebuggerPaused;

  SetState(dsRunning);
  FThread.Start;
end;

procedure TNodeEditorDebugger.Pause;
begin
  if FThread <> nil then
    FThread.Pause
  else if FDebugger <> nil then
    FDebugger.Pause;

  SetState(dsPaused);
end;

procedure TNodeEditorDebugger.ContinueExecution;
begin
  if FThread <> nil then
    FThread.Continue
  else if FDebugger <> nil then
    FDebugger.Continue;

  SetState(dsRunning);
end;

procedure TNodeEditorDebugger.StepOver;
begin
  if FThread <> nil then
  begin
    FThread.StepOver;
    SetState(dsRunning);
  end
  else if FDebugger <> nil then
    FDebugger.StepOver;
end;

procedure TNodeEditorDebugger.StepInto;
begin
  if FThread <> nil then
  begin
    FThread.StepInto;
    SetState(dsRunning);
  end
  else if FDebugger <> nil then
    FDebugger.StepInto;
end;

procedure TNodeEditorDebugger.Stop;
begin
  if FThread <> nil then
  begin
    FThread.Stop;
    FreeAndNil(FThread);
  end;

  if FDebugger <> nil then
    FDebugger.Continue; // сбрасываем состояние паузы

  SetState(dsStopped);
end;

procedure TNodeEditorDebugger.ToggleBreakpoint(ANode: TCustomNode);
begin
  if ANode = nil then Exit;

  if FDebugger.HasBreakpoint(ANode) then
    FDebugger.RemoveBreakpoint(ANode)
  else
    FDebugger.AddBreakpoint(ANode);

  if FEditor <> nil then
    FEditor.Invalidate;
end;

procedure TNodeEditorDebugger.SetBreakpoint(ANode: TCustomNode; const Condition: string);
begin
  if ANode = nil then Exit;

  FDebugger.AddBreakpoint(ANode, nil, Condition);

  if FEditor <> nil then
    FEditor.Invalidate;
end;

procedure TNodeEditorDebugger.OnThreadFinished(Sender: TObject; Success: Boolean; const ErrorMessage: string);
begin
  SetState(dsStopped);
end;

procedure TNodeEditorDebugger.OnThreadError(Sender: TObject; const ErrorInfo: TThreadErrorInfo);
begin
  SetState(dsError);
  // Здесь можно показать сообщение об ошибке в UI
end;

procedure TNodeEditorDebugger.OnDebuggerPaused(ANode: TCustomNode; APin: TNodePin; Context: INodeExecutionContext);
begin
  if FEditor <> nil then
  begin
    FEditor.CurrentDebugNode := ANode;
    FEditor.DebugViewMode := True;
    FEditor.Invalidate;
  end;

  SetState(dsPaused);
end;

procedure TNodeEditorDebugger.HandleThreadDebuggerPaused(Sender: TObject;
  ANode: TCustomNode; APin: TNodePin; Context: INodeExecutionContext);
begin
  OnDebuggerPaused(ANode, APin, Context);
end;

end.
