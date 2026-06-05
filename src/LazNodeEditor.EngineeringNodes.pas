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
unit LazNodeEditor.EngineeringNodes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Rtti,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Runtime;

type
  { executable math node }
  TExecMathNode = class(TExecutableNode)
  protected
    FExecIn: TNodePin;
    FExecOut: TNodePin;
    procedure AddExecPins;
  end;

  { Константы / переменные }

  TIntConstNode = class(TExecutableNode)
  private
    FExecIn, FExecOut: TNodePin;
    FValueOut: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 110); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TBoolConstNode = class(TExecutableNode)
  private
    FExecIn, FExecOut: TNodePin;
    FValueOut: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 110); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TStringConstNode = class(TExecutableNode)
  private
    FExecIn, FExecOut: TNodePin;
    FValueOut: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 200;
      AHeight: integer = 110); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TSetVariableNode = class(TExecutableNode)
  private
    FExecIn, FExecOut: TNodePin;
    FNamePin, FValuePin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 220;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TGetVariableNode = class(TExecutableNode)
  private
    FExecIn, FExecOut: TNodePin;
    FNamePin: TNodePin;
    FValueOut: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 220;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { Арифметика }

  TAddExecNode = class(TExecMathNode)
  private
    FA, FB, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 190;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TSubExecNode = class(TExecMathNode)
  private
    FA, FB, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 190;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TMulExecNode = class(TExecMathNode)
  private
    FA, FB, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 190;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TDivExecNode = class(TExecMathNode)
  private
    FA, FB, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 190;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TModExecNode = class(TExecMathNode)
  private
    FA, FB, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 190;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TPowExecNode = class(TExecMathNode)
  private
    FBasePin, FExpPin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 200;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { Тригонометрия }

  TSinExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TCosExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TTanExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { Инженерные функции }

  TSqrtExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TAbsExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TLogExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TLnExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TFloorExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TCeilExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TRoundExecNode = class(TExecMathNode)
  private
    FValuePin, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 180;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { Сравнения }

  TGreaterNode = class(TExecMathNode)
  private
    FA, FB, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 190;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TLessNode = class(TExecMathNode)
  private
    FA, FB, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 190;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TEqualNode = class(TExecMathNode)
  private
    FA, FB, FResult: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 190;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  { Узлы под решето }

  TIsPrimeFlagNode = class(TExecutableNode)
  private
    FExecIn, FExecOut: TNodePin;
    FIndexPin: TNodePin;
    FValueOut: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 220;
      AHeight: integer = 130); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TSetPrimeFlagNode = class(TExecutableNode)
  private
    FExecIn, FExecOut: TNodePin;
    FIndexPin, FValuePin: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 220;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

  TCollectPrimeNode = class(TExecutableNode)
  private
    FExecIn, FExecOut: TNodePin;
    FPrimePin: TNodePin;
    FListOut: TNodePin;
  protected
    procedure SetupPins; override;
  public
    constructor Create(ATitle: string; AX, AY: single; AWidth: integer = 230;
      AHeight: integer = 140); override;
    procedure Execute(AContext: TNodeExecutionContext); override;
  end;

procedure RegisterEngineeringNodes(ARegistry: TNodeRegistry);

implementation

procedure TExecMathNode.AddExecPins;
begin
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
end;

{ TIntConstNode }

constructor TIntConstNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'intconst';
  HeaderColor := $00C8E6C9;
end;

procedure TIntConstNode.SetupPins;
var
  V: TNodeValue;
begin
  ClearPins;
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
  FValueOut := AddOutputPin('Value', 'integer', pkData);

  if FindValue('value') = nil then
  begin
    V := AddValue('value', nvkInteger);
    V.IntegerValue := 0;
  end;
end;

procedure TIntConstNode.Execute(AContext: TNodeExecutionContext);
var
  V: TNodeValue;
begin
  V := FindValue('value');
  if V <> nil then
    AContext.SetOutputValue(FValueOut, MakeIntValue(V.IntegerValue))
  else
    AContext.SetOutputValue(FValueOut, MakeIntValue(0));
  AContext.SelectExecOutput(FExecOut);
end;

{ TBoolConstNode }

constructor TBoolConstNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'boolconst';
  HeaderColor := $00FFF59D;
end;

procedure TBoolConstNode.SetupPins;
var
  V: TNodeValue;
begin
  ClearPins;
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
  FValueOut := AddOutputPin('Value', 'bool', pkData);

  if FindValue('value') = nil then
  begin
    V := AddValue('value', nvkBoolean);
    V.BooleanValue := False;
  end;
end;

procedure TBoolConstNode.Execute(AContext: TNodeExecutionContext);
var
  V: TNodeValue;
begin
  V := FindValue('value');
  if V <> nil then
    AContext.SetOutputValue(FValueOut, MakeBoolValue(V.BooleanValue))
  else
    AContext.SetOutputValue(FValueOut, MakeBoolValue(False));
  AContext.SelectExecOutput(FExecOut);
end;

{ TStringConstNode }

constructor TStringConstNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'stringconst';
  HeaderColor := $00B3E5FC;
end;

procedure TStringConstNode.SetupPins;
var
  V: TNodeValue;
begin
  ClearPins;
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
  FValueOut := AddOutputPin('Value', 'string', pkData);

  if FindValue('value') = nil then
  begin
    V := AddValue('value', nvkString);
    V.StringValue := '';
  end;
end;

procedure TStringConstNode.Execute(AContext: TNodeExecutionContext);
var
  V: TNodeValue;
begin
  V := FindValue('value');
  if V <> nil then
    AContext.SetOutputValue(FValueOut, MakeStringValue(V.StringValue))
  else
    AContext.SetOutputValue(FValueOut, MakeStringValue(''));
  AContext.SelectExecOutput(FExecOut);
end;

{ TSetVariableNode }

constructor TSetVariableNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'setvar';
  HeaderColor := $00D1C4E9;
end;

procedure TSetVariableNode.SetupPins;
begin
  ClearPins;
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FNamePin := AddInputPin('Name', 'string', pkData);
  FValuePin := AddInputPin('Value', 'any', pkData);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
end;

procedure TSetVariableNode.Execute(AContext: TNodeExecutionContext);
var
  N: string;
  V: TValue;
begin
  N := NodeValueToStringDef(AContext.GetInputValue(FNamePin), '');
  V := AContext.GetInputValue(FValuePin);
  if N <> '' then
    AContext.SetVariable(N, V);
  AContext.SelectExecOutput(FExecOut);
end;

{ TGetVariableNode }

constructor TGetVariableNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'getvar';
  HeaderColor := $00D1C4E9;
end;

procedure TGetVariableNode.SetupPins;
begin
  ClearPins;
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FNamePin := AddInputPin('Name', 'string', pkData);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
  FValueOut := AddOutputPin('Value', 'any', pkData);
end;

procedure TGetVariableNode.Execute(AContext: TNodeExecutionContext);
var
  N: string;
begin
  N := NodeValueToStringDef(AContext.GetInputValue(FNamePin), '');
  AContext.SetOutputValue(FValueOut, AContext.GetVariableValue(N));
  AContext.SelectExecOutput(FExecOut);
end;

{ Арифметика }

constructor TAddExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'addexec';
  HeaderColor := $00D0A0FF;
end;

procedure TAddExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FA := AddInputPin('A', 'float', pkData);
  FB := AddInputPin('B', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TAddExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeFloatValue(
    NodeValueToFloatDef(AContext.GetInputValue(FA), 0.0) +
    NodeValueToFloatDef(AContext.GetInputValue(FB), 0.0)
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TSubExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'subexec';
  HeaderColor := $00D0A0FF;
end;

procedure TSubExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FA := AddInputPin('A', 'float', pkData);
  FB := AddInputPin('B', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TSubExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeFloatValue(
    NodeValueToFloatDef(AContext.GetInputValue(FA), 0.0) -
    NodeValueToFloatDef(AContext.GetInputValue(FB), 0.0)
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TMulExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'mulexec';
  HeaderColor := $00D0A0FF;
end;

procedure TMulExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FA := AddInputPin('A', 'float', pkData);
  FB := AddInputPin('B', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TMulExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeFloatValue(
    NodeValueToFloatDef(AContext.GetInputValue(FA), 0.0) *
    NodeValueToFloatDef(AContext.GetInputValue(FB), 0.0)
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TDivExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'divexec';
  HeaderColor := $00D0A0FF;
end;

procedure TDivExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FA := AddInputPin('A', 'float', pkData);
  FB := AddInputPin('B', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TDivExecNode.Execute(AContext: TNodeExecutionContext);
var
  B: Double;
begin
  B := NodeValueToFloatDef(AContext.GetInputValue(FB), 0.0);
  if Abs(B) < 1e-12 then
    raise ENodeExecutionError.Create('Division by zero');
  AContext.SetOutputValue(FResult, MakeFloatValue(
    NodeValueToFloatDef(AContext.GetInputValue(FA), 0.0) / B
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TModExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'modexec';
  HeaderColor := $00D0A0FF;
end;

procedure TModExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FA := AddInputPin('A', 'integer', pkData);
  FB := AddInputPin('B', 'integer', pkData);
  FResult := AddOutputPin('Result', 'integer', pkData);
end;

procedure TModExecNode.Execute(AContext: TNodeExecutionContext);
var
  AInt, BInt: Int64;
begin
  AInt := NodeValueToIntDef(AContext.GetInputValue(FA), 0);
  BInt := NodeValueToIntDef(AContext.GetInputValue(FB), 1);
  if BInt = 0 then
    raise ENodeExecutionError.Create('Modulo by zero');
  AContext.SetOutputValue(FResult, MakeIntValue(AInt mod BInt));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TPowExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'powexec';
  HeaderColor := $00D0A0FF;
end;

procedure TPowExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FBasePin := AddInputPin('Base', 'float', pkData);
  FExpPin := AddInputPin('Exponent', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TPowExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeFloatValue(
    Power(
      NodeValueToFloatDef(AContext.GetInputValue(FBasePin), 0.0),
      NodeValueToFloatDef(AContext.GetInputValue(FExpPin), 0.0)
    )
  ));
  AContext.SelectExecOutput(FExecOut);
end;

{ trig }

constructor TSinExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'sinexec';
  HeaderColor := $00FFCC80;
end;

procedure TSinExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Radians', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TSinExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeFloatValue(
    Sin(NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 0.0))
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TCosExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'cosexec';
  HeaderColor := $00FFCC80;
end;

procedure TCosExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Radians', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TCosExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeFloatValue(
    Cos(NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 0.0))
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TTanExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'tanexec';
  HeaderColor := $00FFCC80;
end;

procedure TTanExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Radians', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TTanExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeFloatValue(
    Tan(NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 0.0))
  ));
  AContext.SelectExecOutput(FExecOut);
end;

{ engineering }

constructor TSqrtExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'sqrtexec';
  HeaderColor := $00AED581;
end;

procedure TSqrtExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Value', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TSqrtExecNode.Execute(AContext: TNodeExecutionContext);
var
  V: Double;
begin
  V := NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 0.0);
  if V < 0 then
    raise ENodeExecutionError.Create('SQRT from negative number');
  AContext.SetOutputValue(FResult, MakeFloatValue(Sqrt(V)));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TAbsExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'absexec';
  HeaderColor := $00AED581;
end;

procedure TAbsExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Value', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TAbsExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeFloatValue(
    Abs(NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 0.0))
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TLogExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'logexec';
  HeaderColor := $00AED581;
end;

procedure TLogExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Value', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TLogExecNode.Execute(AContext: TNodeExecutionContext);
var
  V: Double;
begin
  V := NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 1.0);
  if V <= 0 then
    raise ENodeExecutionError.Create('LOG10 argument must be > 0');
  AContext.SetOutputValue(FResult, MakeFloatValue(Log10(V)));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TLnExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'lnexec';
  HeaderColor := $00AED581;
end;

procedure TLnExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Value', 'float', pkData);
  FResult := AddOutputPin('Result', 'float', pkData);
end;

procedure TLnExecNode.Execute(AContext: TNodeExecutionContext);
var
  V: Double;
begin
  V := NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 1.0);
  if V <= 0 then
    raise ENodeExecutionError.Create('LN argument must be > 0');
  AContext.SetOutputValue(FResult, MakeFloatValue(Ln(V)));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TFloorExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'floorexec';
  HeaderColor := $00AED581;
end;

procedure TFloorExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Value', 'float', pkData);
  FResult := AddOutputPin('Result', 'integer', pkData);
end;

procedure TFloorExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeIntValue(
    Floor(NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 0.0))
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TCeilExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'ceilexec';
  HeaderColor := $00AED581;
end;

procedure TCeilExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Value', 'float', pkData);
  FResult := AddOutputPin('Result', 'integer', pkData);
end;

procedure TCeilExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeIntValue(
    Ceil(NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 0.0))
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TRoundExecNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'roundexec';
  HeaderColor := $00AED581;
end;

procedure TRoundExecNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FValuePin := AddInputPin('Value', 'float', pkData);
  FResult := AddOutputPin('Result', 'integer', pkData);
end;

procedure TRoundExecNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeIntValue(
    Round(NodeValueToFloatDef(AContext.GetInputValue(FValuePin), 0.0))
  ));
  AContext.SelectExecOutput(FExecOut);
end;

{ compare }

constructor TGreaterNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'greater';
  HeaderColor := $00EF9A9A;
end;

procedure TGreaterNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FA := AddInputPin('A', 'float', pkData);
  FB := AddInputPin('B', 'float', pkData);
  FResult := AddOutputPin('Result', 'bool', pkData);
end;

procedure TGreaterNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeBoolValue(
    NodeValueToFloatDef(AContext.GetInputValue(FA), 0.0) >
    NodeValueToFloatDef(AContext.GetInputValue(FB), 0.0)
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TLessNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'less';
  HeaderColor := $00EF9A9A;
end;

procedure TLessNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FA := AddInputPin('A', 'float', pkData);
  FB := AddInputPin('B', 'float', pkData);
  FResult := AddOutputPin('Result', 'bool', pkData);
end;

procedure TLessNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeBoolValue(
    NodeValueToFloatDef(AContext.GetInputValue(FA), 0.0) <
    NodeValueToFloatDef(AContext.GetInputValue(FB), 0.0)
  ));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TEqualNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'equal';
  HeaderColor := $00EF9A9A;
end;

procedure TEqualNode.SetupPins;
begin
  ClearPins;
  AddExecPins;
  FA := AddInputPin('A', 'float', pkData);
  FB := AddInputPin('B', 'float', pkData);
  FResult := AddOutputPin('Result', 'bool', pkData);
end;

procedure TEqualNode.Execute(AContext: TNodeExecutionContext);
begin
  AContext.SetOutputValue(FResult, MakeBoolValue(
    SameValue(
      NodeValueToFloatDef(AContext.GetInputValue(FA), 0.0),
      NodeValueToFloatDef(AContext.GetInputValue(FB), 0.0),
      1e-9
    )
  ));
  AContext.SelectExecOutput(FExecOut);
end;

{ решето }

constructor TIsPrimeFlagNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'isprimeflag';
  HeaderColor := $00B2DFDB;
end;

procedure TIsPrimeFlagNode.SetupPins;
begin
  ClearPins;
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FIndexPin := AddInputPin('Index', 'integer', pkData);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
  FValueOut := AddOutputPin('IsPrime', 'bool', pkData);
end;

procedure TIsPrimeFlagNode.Execute(AContext: TNodeExecutionContext);
var
  Idx: Int64;
  B: Boolean;
begin
  Idx := NodeValueToIntDef(AContext.GetInputValue(FIndexPin), 0);
  B := AContext.GetVariableBool('prime_' + IntToStr(Idx), False);

  AContext.SetVariable('last_prime_check_index', MakeIntValue(Idx));
  AContext.SetVariableBool('last_prime_check_value', B);

  AContext.SetOutputValue(FValueOut, MakeBoolValue(B));
  AContext.SelectExecOutput(FExecOut);
end;

constructor TSetPrimeFlagNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'setprimeflag';
  HeaderColor := $00B2DFDB;
end;

procedure TSetPrimeFlagNode.SetupPins;
begin
  ClearPins;
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FIndexPin := AddInputPin('Index', 'integer', pkData);
  FValuePin := AddInputPin('Value', 'bool', pkData);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
end;

procedure TSetPrimeFlagNode.Execute(AContext: TNodeExecutionContext);
var
  Idx: Int64;
  B: Boolean;
begin
  Idx := NodeValueToIntDef(AContext.GetInputValue(FIndexPin), 0);
  B := NodeValueToBoolDef(AContext.GetInputValue(FValuePin), False);

  AContext.SetVariable('last_set_prime_index', MakeIntValue(Idx));
  AContext.SetVariableBool('last_set_prime_value', B);

  AContext.SetVariableBool('prime_' + IntToStr(Idx), B);
  AContext.SelectExecOutput(FExecOut);
end;

constructor TCollectPrimeNode.Create(ATitle: string; AX, AY: single; AWidth,
  AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'collectprime';
  HeaderColor := $00B39DDB;
end;

procedure TCollectPrimeNode.SetupPins;
begin
  ClearPins;
  FExecIn := AddInputPin('Exec', 'exec', pkExec);
  FPrimePin := AddInputPin('Prime', 'integer', pkData);
  FExecOut := AddOutputPin('Next', 'exec', pkExec);
  FListOut := AddOutputPin('List', 'string', pkData);
end;

procedure TCollectPrimeNode.Execute(AContext: TNodeExecutionContext);
var
  P: Int64;
  S: string;
begin
  P := NodeValueToIntDef(AContext.GetInputValue(FPrimePin), 0);
  S := AContext.GetVariableStr('primes', '');

  if S = '' then
    S := IntToStr(P)
  else
    S := S + ', ' + IntToStr(P);

  AContext.SetVariable('last_collected_prime', MakeIntValue(P));
  AContext.SetVariableStr('primes', S);
  AContext.SetOutputValue(FListOut, MakeStringValue(S));
  AContext.SelectExecOutput(FExecOut);
end;

procedure RegisterEngineeringNodes(ARegistry: TNodeRegistry);
begin
  if ARegistry = nil then Exit;

  ARegistry.RegisterNodeEx('intconst', 'Int Constant', 'Engineering',
    'Integer constant node', 'int,constant,number', TIntConstNode, $00C8E6C9);
  ARegistry.RegisterNodeEx('boolconst', 'Bool Constant', 'Engineering',
    'Boolean constant node', 'bool,constant,logic', TBoolConstNode, $00FFF59D);
  ARegistry.RegisterNodeEx('stringconst', 'String Constant', 'Engineering',
    'String constant node', 'string,text,constant', TStringConstNode, $00B3E5FC);

  ARegistry.RegisterNodeEx('setvar', 'Set Variable', 'Engineering',
    'Set runtime variable', 'variable,set,assign', TSetVariableNode, $00D1C4E9);
  ARegistry.RegisterNodeEx('getvar', 'Get Variable', 'Engineering',
    'Get runtime variable', 'variable,get,read', TGetVariableNode, $00D1C4E9);

  ARegistry.RegisterNodeEx('addexec', 'Add', 'Engineering',
    'A + B', 'math,add,sum', TAddExecNode, $00D0A0FF);
  ARegistry.RegisterNodeEx('subexec', 'Subtract', 'Engineering',
    'A - B', 'math,sub', TSubExecNode, $00D0A0FF);
  ARegistry.RegisterNodeEx('mulexec', 'Multiply', 'Engineering',
    'A * B', 'math,mul', TMulExecNode, $00D0A0FF);
  ARegistry.RegisterNodeEx('divexec', 'Divide', 'Engineering',
    'A / B', 'math,div', TDivExecNode, $00D0A0FF);
  ARegistry.RegisterNodeEx('modexec', 'Modulo', 'Engineering',
    'A mod B', 'math,mod', TModExecNode, $00D0A0FF);
  ARegistry.RegisterNodeEx('powexec', 'Power', 'Engineering',
    'Base ^ Exponent', 'math,pow', TPowExecNode, $00D0A0FF);

  ARegistry.RegisterNodeEx('sinexec', 'Sin', 'Engineering',
    'sin(x)', 'math,trig,sin', TSinExecNode, $00FFCC80);
  ARegistry.RegisterNodeEx('cosexec', 'Cos', 'Engineering',
    'cos(x)', 'math,trig,cos', TCosExecNode, $00FFCC80);
  ARegistry.RegisterNodeEx('tanexec', 'Tan', 'Engineering',
    'tan(x)', 'math,trig,tan', TTanExecNode, $00FFCC80);

  ARegistry.RegisterNodeEx('sqrtexec', 'Sqrt', 'Engineering',
    'sqrt(x)', 'math,sqrt', TSqrtExecNode, $00AED581);
  ARegistry.RegisterNodeEx('absexec', 'Abs', 'Engineering',
    'abs(x)', 'math,abs', TAbsExecNode, $00AED581);
  ARegistry.RegisterNodeEx('logexec', 'Log10', 'Engineering',
    'log10(x)', 'math,log', TLogExecNode, $00AED581);
  ARegistry.RegisterNodeEx('lnexec', 'Ln', 'Engineering',
    'ln(x)', 'math,ln', TLnExecNode, $00AED581);
  ARegistry.RegisterNodeEx('floorexec', 'Floor', 'Engineering',
    'floor(x)', 'math,floor', TFloorExecNode, $00AED581);
  ARegistry.RegisterNodeEx('ceilexec', 'Ceil', 'Engineering',
    'ceil(x)', 'math,ceil', TCeilExecNode, $00AED581);
  ARegistry.RegisterNodeEx('roundexec', 'Round', 'Engineering',
    'round(x)', 'math,round', TRoundExecNode, $00AED581);

  ARegistry.RegisterNodeEx('greater', 'Greater', 'Engineering',
    'A > B', 'compare,greater', TGreaterNode, $00EF9A9A);
  ARegistry.RegisterNodeEx('less', 'Less', 'Engineering',
    'A < B', 'compare,less', TLessNode, $00EF9A9A);
  ARegistry.RegisterNodeEx('equal', 'Equal', 'Engineering',
    'A = B', 'compare,equal', TEqualNode, $00EF9A9A);

  ARegistry.RegisterNodeEx('isprimeflag', 'Is Prime Flag', 'Engineering',
    'Read prime_i variable', 'prime,sieve,bool', TIsPrimeFlagNode, $00B2DFDB);
  ARegistry.RegisterNodeEx('setprimeflag', 'Set Prime Flag', 'Engineering',
    'Write prime_i variable', 'prime,sieve,set', TSetPrimeFlagNode, $00B2DFDB);
  ARegistry.RegisterNodeEx('collectprime', 'Collect Prime', 'Engineering',
    'Append prime to list', 'prime,sieve,collect', TCollectPrimeNode, $00B39DDB);
end;

end.
