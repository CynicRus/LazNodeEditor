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
unit LazNodeEditor.ExecutionThread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  LazNodeEditor.Types,
  LazNodeEditor.Graph,
  LazNodeEditor.Executor,
  LazNodeEditor.Runtime,
  LazNodeEditor.Nodes,
  LazNodeEditor.Debugger,
  LazNodeEditor.DebugIntf;

type
  TNodeExecutionEvent = procedure(Sender: TObject; ANode: TExecutableNode) of object;
  TExecutionFinishedEvent = procedure(Sender: TObject; Success: boolean;
    const ErrorMessage: string) of object;
  TDebuggerPauseThreadEvent = procedure(Sender: TObject; ANode: TCustomNode;
    APin: TNodePin; Context: INodeExecutionContext) of object;

  TThreadErrorInfo = record
    ErrorCode: integer;
    Message: string;
    Node: TExecutableNode;
    NodeTitle: string;
    NodeType: string;
  end;

  TThreadErrorEvent = procedure(Sender: TObject;
    const ErrorInfo: TThreadErrorInfo) of object;

  { TGraphExecutionThread }

  TGraphExecutionThread = class(TThread)
  private
    FExecutor: TGraphExecutor;
    FStartNode: TExecutableNode;
    FSuccess: boolean;
    FErrorMessage: string;
    FErrorInfo: TThreadErrorInfo;

    FOnStarted: TNotifyEvent;
    FOnNodeExecuted: TNodeExecutionEvent;
    FOnFinished: TExecutionFinishedEvent;
    FOnError: TThreadErrorEvent;
    FOnDebuggerPaused: TDebuggerPauseThreadEvent;

    FSyncNode: TExecutableNode;
    FPausedNode: TCustomNode;
    FPausedPin: TNodePin;

    procedure ClearErrorInfo;
    procedure FillErrorInfo(AErrorCode: integer; const AMessage: string;
      ANode: TExecutableNode);

    procedure DoStarted;
    procedure DoNodeExecuted;
    procedure DoFinished;
    procedure DoError;
    procedure DoDebuggerPaused;

    procedure HandleContextNodeExecuted(AContext: TNodeExecutionContext;
      ANode: TExecutableNode);
    procedure HandleDebuggerPaused(ANode: TCustomNode; APin: TNodePin;
      Context: INodeExecutionContext);

  protected
    procedure Execute; override;

  public
    constructor Create(AGraph: TNodeGraph; AStartNode: TExecutableNode;
      ADebugger: TGraphDebugger = nil);
    destructor Destroy; override;

    procedure Pause;
    procedure Stop;
    procedure Continue;
    procedure StepInto;
    procedure StepOver;

    property OnStarted: TNotifyEvent read FOnStarted write FOnStarted;
    property OnNodeExecuted: TNodeExecutionEvent
      read FOnNodeExecuted write FOnNodeExecuted;
    property OnFinished: TExecutionFinishedEvent read FOnFinished write FOnFinished;
    property OnError: TThreadErrorEvent read FOnError write FOnError;
    property OnDebuggerPaused: TDebuggerPauseThreadEvent
      read FOnDebuggerPaused write FOnDebuggerPaused;

    property Executor: TGraphExecutor read FExecutor;
    property ErrorInfo: TThreadErrorInfo read FErrorInfo;
  end;

implementation

constructor TGraphExecutionThread.Create(AGraph: TNodeGraph;
  AStartNode: TExecutableNode; ADebugger: TGraphDebugger);
begin
  inherited Create(True);
  FreeOnTerminate := True;

  FExecutor := TGraphExecutor.Create(AGraph);
  FExecutor.Debugger := ADebugger;

  FStartNode := AStartNode;
  FSuccess := True;
  FErrorMessage := '';
  FSyncNode := nil;
  FPausedNode := nil;
  FPausedPin := nil;

  ClearErrorInfo;

  if ADebugger <> nil then
    ADebugger.OnPaused := @HandleDebuggerPaused;
end;

destructor TGraphExecutionThread.Destroy;
begin
  if (FExecutor <> nil) and (FExecutor.Debugger <> nil) and
    (FExecutor.Debugger.OnPaused = @HandleDebuggerPaused) then
    FExecutor.Debugger.OnPaused := nil;

  FExecutor.Free;
  inherited Destroy;
end;

procedure TGraphExecutionThread.Pause;
begin
  if (FExecutor <> nil) and (FExecutor.Debugger <> nil) then
    FExecutor.Debugger.Pause;
end;

procedure TGraphExecutionThread.Stop;
begin
  Terminate;

  if (FExecutor <> nil) and (FExecutor.Debugger <> nil) then
    FExecutor.Debugger.Continue;
  // очищает внутреннее состояние отладчика
end;

procedure TGraphExecutionThread.Continue;
begin
  if (FExecutor <> nil) and (FExecutor.Debugger <> nil) then
    FExecutor.Debugger.Continue;
end;

procedure TGraphExecutionThread.StepInto;
begin
  if (FExecutor <> nil) and (FExecutor.Debugger <> nil) then
    FExecutor.Debugger.StepInto;
end;

procedure TGraphExecutionThread.StepOver;
begin
  if (FExecutor <> nil) and (FExecutor.Debugger <> nil) then
    FExecutor.Debugger.StepOver;
end;

procedure TGraphExecutionThread.ClearErrorInfo;
begin
  FErrorInfo.ErrorCode := 0;
  FErrorInfo.Message := '';
  FErrorInfo.Node := nil;
  FErrorInfo.NodeTitle := '';
  FErrorInfo.NodeType := '';
end;

procedure TGraphExecutionThread.FillErrorInfo(AErrorCode: integer;
  const AMessage: string; ANode: TExecutableNode);
begin
  FErrorInfo.ErrorCode := AErrorCode;
  FErrorInfo.Message := AMessage;
  FErrorInfo.Node := ANode;

  if ANode <> nil then
  begin
    FErrorInfo.NodeType := ANode.ClassName;
    try
      FErrorInfo.NodeTitle := ANode.Title;
    except
      FErrorInfo.NodeTitle := '';
    end;
  end
  else
  begin
    FErrorInfo.NodeTitle := '';
    FErrorInfo.NodeType := '';
  end;
end;

procedure TGraphExecutionThread.DoStarted;
begin
  if Assigned(FOnStarted) then
    FOnStarted(Self);
end;

procedure TGraphExecutionThread.DoNodeExecuted;
begin
  if Assigned(FOnNodeExecuted) and (FSyncNode <> nil) then
    FOnNodeExecuted(Self, FSyncNode);
end;

procedure TGraphExecutionThread.DoFinished;
begin
  if Assigned(FOnFinished) then
    FOnFinished(Self, FSuccess, FErrorMessage);
end;

procedure TGraphExecutionThread.DoError;
begin
  if Assigned(FOnError) then
    FOnError(Self, FErrorInfo);
end;

procedure TGraphExecutionThread.DoDebuggerPaused;
begin
  if Assigned(FOnDebuggerPaused) then
    FOnDebuggerPaused(Self, FPausedNode, FPausedPin, FExecutor.Context);
end;

procedure TGraphExecutionThread.HandleContextNodeExecuted(
  AContext: TNodeExecutionContext; ANode: TExecutableNode);
begin
  FSyncNode := ANode;
  Synchronize(@DoNodeExecuted);
end;

procedure TGraphExecutionThread.HandleDebuggerPaused(ANode: TCustomNode;
  APin: TNodePin; Context: INodeExecutionContext);
begin
  FPausedNode := ANode;
  FPausedPin := APin;
  Synchronize(@DoDebuggerPaused);
end;

procedure TGraphExecutionThread.Execute;
var
  FailedNode: TExecutableNode;
begin
  FSuccess := True;
  FErrorMessage := '';
  ClearErrorInfo;
  FailedNode := nil;

  try
    Synchronize(@DoStarted);

    if FStartNode = nil then
    begin
      FSuccess := False;
      FErrorMessage := 'Start node is nil';
      FillErrorInfo(integer(geeInvalidStartNode), FErrorMessage, nil);
      Synchronize(@DoError);
      Exit;
    end;

    FExecutor.Context.OnNodeExecuted := @HandleContextNodeExecuted;

    FSuccess := FExecutor.ExecuteFromNode(FStartNode);
    if not FSuccess then
    begin
      FErrorMessage := FExecutor.LastErrorMessage;
      if FErrorMessage = '' then
        FErrorMessage := 'Graph execution failed';

      if FExecutor.Context <> nil then
      begin
        if FExecutor.Context.LastExecutedNode is TExecutableNode then
          FailedNode := TExecutableNode(FExecutor.Context.LastExecutedNode)
        else
          FailedNode := nil;
      end;

      FillErrorInfo(integer(FExecutor.LastError), FErrorMessage, FailedNode);
      Synchronize(@DoError);
    end;
  except
    on E: ENodeDebuggerPause do
    begin
      FSuccess := True;
      FErrorMessage := '';
      ClearErrorInfo;
      // Не ошибка. Поток завершился из-за паузы.
    end;
    on E: ENodeExecutionStopped do
    begin
      FSuccess := False;
      FErrorMessage := 'Execution stopped';
      ClearErrorInfo;
      // Остановка пользователем
    end;
    on E: Exception do
    begin
      FSuccess := False;
      FErrorMessage := E.Message;

      if (FExecutor <> nil) and (FExecutor.Context <> nil) and
        (FExecutor.Context.LastExecutedNode is TExecutableNode) then
        FailedNode := TExecutableNode(FExecutor.Context.LastExecutedNode)
      else
        FailedNode := nil;

      FillErrorInfo(-1, FErrorMessage, FailedNode);
      Synchronize(@DoError);
    end;
  end;

  Synchronize(@DoFinished);
end;

end.
