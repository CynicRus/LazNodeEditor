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
unit LazNodeEditor.InteractionIntf;

{$mode objfpc}{$H+}

interface

uses
  Controls, Types,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph;

type
  INodeEditorInteractionHost = interface
    ['{D17F5C22-9B4D-4A62-A6A8-7D31EFD2A001}']
    // HitTest & Coordinates
    function HitTestNodeAt(SX, SY: integer): TCustomNode;
    function HitTestPinAt(SX, SY: integer; out ANode: TCustomNode): TNodePin;
    function HitTestLinkAt(SX, SY: integer): TNodeLink;
    function HitTestResizeHandleAt(SX, SY: integer): TCustomNode;
    function ScreenToWorld(SX, SY: integer): TPointF;
    function IsMouseNearLinkStart(ALink: TNodeLink; SX, SY: integer): boolean;
    function IsLinkInsideWorldRect(ALink: TNodeLink; const R: TRectF): boolean;

    // Selection
    procedure SelectNodeInternal(ANode: TCustomNode; AAppend: boolean);
    procedure SelectLinkInternal(ALink: TNodeLink; AKeepNodes: boolean = False);
    procedure ClearSelectionInternal;
    procedure AddNodeToSelection(ANode: TCustomNode);
    procedure AddLinkToSelection(ALink: TNodeLink);
    procedure ToggleNodeSelection(ANode: TCustomNode);
    procedure ToggleLinkSelection(ALink: TNodeLink);
    procedure SelectPinInternal(APin: TNodePin; AAppend: boolean);
    procedure TogglePinSelection(APin: TNodePin);
    procedure ClearPinSelection;

    // Pin logic
    function CanPinAcceptMoreConnections(APin: TNodePin): boolean;
    procedure UpdatePinsConnectedState;

    // Snap & Guides
    function SnapWorldValue(V: single): single;
    procedure ApplyNodeSnap(var AOffsetX, AOffsetY: single;
      out ASnappedX, ASnappedY: boolean);
    procedure ClearSnapGuides;
    function GetSnapToGrid(): boolean;
    function GetSnapToNodes(): boolean;

    // Notifications & UI
    procedure NotifySelectionChanged;
    procedure RequestRepaint(const AForce: boolean = False);
    procedure ShowNodeSearchPopup(AScreenX, AScreenY: integer;
      AWorldX, AWorldY: single);
    procedure Invalidate;
    procedure SetCursor(ACursor: TCursor);
    procedure SetMouseCapture(AValue: boolean);

    // Events
    function GetOnPinClickAssigned: boolean;
    procedure DoPinClick(APin: TNodePin);
    function GetOnLinkClickAssigned: boolean;
    procedure DoLinkClick(ALink: TNodeLink);
    function BeforeConnectPins(AFromPin, AToPin: TNodePin): boolean;
    procedure AfterConnectPins(AFromPin, AToPin: TNodePin);
    procedure DoNodeChanged(ANode: TCustomNode);

    // Context
    function GetContextWorldPos: TPointF;
    procedure SetContextWorldPos(const AValue: TPointF);
    procedure PopupContextMenu(AScreenX, AScreenY: integer);

    // Hover
    function IsHoverPosChanged(X, Y: integer): boolean;
    procedure SetLastHoverPos(X, Y: integer);
    procedure UpdateHoverStates(X, Y: integer);
  end;

implementation

end.
