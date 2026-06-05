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
unit LazNodeEditor.DebugIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Rtti,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes;

type
  TStepMode = (smNone, smStepOver, smStepInto);

  INodeExecutionContext = interface
    ['{D1F0D7A1-8D62-4D8A-8D74-2B2C537D0A11}']
    function GetStepCounter: Integer;
    function GetVariableValue(const AName: string): TValue;
    property StepCounter: Integer read GetStepCounter;
  end;

  IDebugBreakpoint = interface
    ['{00D5E5A1-BD49-4D05-AB2B-26D7475F7B12}']
    function GetNode: TCustomNode;
    function GetPin: TNodePin;
    function GetEnabled: Boolean;
    function GetHitCount: Integer;
    function GetCondition: string;

    procedure SetEnabled(AValue: Boolean);
    procedure SetHitCount(AValue: Integer);
    procedure SetCondition(const AValue: string);

    property Node: TCustomNode read GetNode;
    property Pin: TNodePin read GetPin;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property HitCount: Integer read GetHitCount write SetHitCount;
    property Condition: string read GetCondition write SetCondition;
  end;

  TDebuggerBreakpointEvent = procedure(const ABreakpoint: IDebugBreakpoint;
    const AContext: INodeExecutionContext) of object;

  TDebuggerPauseEvent = procedure(ANode: TCustomNode; APin: TNodePin;
    const AContext: INodeExecutionContext) of object;

  IGraphDebugger = interface
    ['{A4386D75-84E4-43D5-8D1D-13A4CB2F5E13}']
    procedure ResetSession;

    procedure AddTraceEntry(const AEventKind: string; ANode: TCustomNode;
      APin: TNodePin = nil; const AContext: INodeExecutionContext = nil);

    procedure PushNode(ANode: TCustomNode);
    procedure PopNode(ANode: TCustomNode = nil);
    procedure ClearExecutionStack;

    procedure Pause;
    procedure Continue;
    procedure StepOver;
    procedure StepInto;

    function CheckPause(ANode: TCustomNode; APin: TNodePin = nil;
      const AContext: INodeExecutionContext = nil): Boolean;
  end;

implementation

end.
