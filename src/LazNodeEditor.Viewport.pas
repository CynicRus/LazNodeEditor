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
unit LazNodeEditor.Viewport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes;

type
  { TNodeViewport }
  TNodeViewport = class
  private
    FZoom: double;
    FOffsetX, FOffsetY: double;
    FMinZoom: double;
    FMaxZoom: double;
    FZoomStep: double;

    procedure SetZoom(AValue: double);
    procedure SetOffsetX(AValue: double);
    procedure SetOffsetY(AValue: double);
  public
    constructor Create;
    destructor Destroy; override;

    function WorldToScreen(WX, WY: single): TPoint; inline;
    function ScreenToWorld(SX, SY: integer): TPointF; inline;
    function GetVisibleWorldRect(const AClientWidth, AClientHeight: integer): TRectF;
    function GetPinWorldPosition(APin: TNodePin): TPointF;
    procedure GetLinkBezierWorldPoints(ALink: TNodeLink; out P0, P1, P2, P3: TPointF);

    // Zoom & Pan
    procedure ZoomAt(const AScreenX, AScreenY: integer; AFactor: double);
    procedure PanBy(ADeltaX, ADeltaY: integer);

    // Framing
    procedure FrameRect(const AWorldRect: TRectF; const AClientWidth, AClientHeight: integer;
      const AMargin: single = 40.0);
    procedure FrameAll(const AMinX, AMinY, AMaxX, AMaxY: single;
      const AClientWidth, AClientHeight: integer);

    // Properties
    property Zoom: double read FZoom write SetZoom;
    property OffsetX: double read FOffsetX write SetOffsetX;
    property OffsetY: double read FOffsetY write SetOffsetY;
    property MinZoom: double read FMinZoom write FMinZoom;
    property MaxZoom: double read FMaxZoom write FMaxZoom;
    property ZoomStep: double read FZoomStep write FZoomStep;
  end;

implementation

{ TNodeViewport }

constructor TNodeViewport.Create;
begin
  inherited Create;
  FZoom := 1.0;
  FOffsetX := 0.0;
  FOffsetY := 0.0;
  FMinZoom := 0.12;
  FMaxZoom := 6.0;
  FZoomStep := 1.15;
end;

destructor TNodeViewport.Destroy;
begin
  inherited Destroy;
end;

procedure TNodeViewport.SetZoom(AValue: double);
begin
  FZoom := EnsureRange(AValue, FMinZoom, FMaxZoom);
end;

procedure TNodeViewport.SetOffsetX(AValue: double);
begin
  FOffsetX := AValue;
end;

procedure TNodeViewport.SetOffsetY(AValue: double);
begin
  FOffsetY := AValue;
end;

function TNodeViewport.WorldToScreen(WX, WY: single): TPoint;
begin
  Result.X := Round(WX * FZoom + FOffsetX);
  Result.Y := Round(WY * FZoom + FOffsetY);
end;

function TNodeViewport.ScreenToWorld(SX, SY: integer): TPointF;
begin
  Result.X := (SX - FOffsetX) / FZoom;
  Result.Y := (SY - FOffsetY) / FZoom;
end;

function TNodeViewport.GetVisibleWorldRect(const AClientWidth, AClientHeight: integer): TRectF;
begin
  Result.Left := (0 - FOffsetX) / FZoom;
  Result.Top := (0 - FOffsetY) / FZoom;
  Result.Right := (AClientWidth - FOffsetX) / FZoom;
  Result.Bottom := (AClientHeight - FOffsetY) / FZoom;
end;

function TNodeViewport.GetPinWorldPosition(APin: TNodePin): TPointF;
begin
  if (APin = nil) or (APin.OwnerNode = nil) then
    Exit(PointF(0, 0));
  Result := TCustomNode(APin.OwnerNode).GetPinWorldPosition(APin);
end;

procedure TNodeViewport.GetLinkBezierWorldPoints(ALink: TNodeLink; out P0, P1,
  P2, P3: TPointF);
var
  DX, DY: single;
  Dist: single;
  D: single;
begin
  P0 := GetPinWorldPosition(ALink.FromPin);
  P3 := GetPinWorldPosition(ALink.ToPin);

  DX := P3.X - P0.X;
  DY := P3.Y - P0.Y;
  Dist := Hypot(DX, DY);

  D := Dist * 0.35;
  D := EnsureRange(D, 30, 150);

  P1 := P0;
  P1.X := P1.X + D;

  P2 := P3;
  P2.X := P2.X - D;
end;

procedure TNodeViewport.ZoomAt(const AScreenX, AScreenY: integer; AFactor: double);
var
  OldZoom: double;
  NewZoom: double;
begin
  OldZoom := FZoom;
  NewZoom := EnsureRange(OldZoom * AFactor, FMinZoom, FMaxZoom);

  if Abs(OldZoom - NewZoom) < 0.0001 then
    Exit;

  FOffsetX := AScreenX - ((AScreenX - FOffsetX) * (NewZoom / OldZoom));
  FOffsetY := AScreenY - ((AScreenY - FOffsetY) * (NewZoom / OldZoom));
  FZoom := NewZoom;
end;

procedure TNodeViewport.PanBy(ADeltaX, ADeltaY: integer);
begin
  FOffsetX := FOffsetX + ADeltaX;
  FOffsetY := FOffsetY + ADeltaY;
end;

procedure TNodeViewport.FrameRect(const AWorldRect: TRectF;
  const AClientWidth, AClientHeight: integer; const AMargin: single);
var
  W, H: single;
  ZX, ZY: double;
begin
  if (AWorldRect.Right <= AWorldRect.Left) or (AWorldRect.Bottom <= AWorldRect.Top) then
    Exit;

  W := AWorldRect.Right - AWorldRect.Left;
  H := AWorldRect.Bottom - AWorldRect.Top;

  ZX := (AClientWidth - 2 * AMargin) / W;
  ZY := (AClientHeight - 2 * AMargin) / H;

  FZoom := EnsureRange(Min(ZX, ZY), FMinZoom, FMaxZoom);

  FOffsetX := AClientWidth / 2 - (AWorldRect.Left + W / 2) * FZoom;
  FOffsetY := AClientHeight / 2 - (AWorldRect.Top + H / 2) * FZoom;
end;

procedure TNodeViewport.FrameAll(const AMinX, AMinY, AMaxX, AMaxY: single;
  const AClientWidth, AClientHeight: integer);
var
  R: TRectF;
begin
  R.Left := AMinX;
  R.Top := AMinY;
  R.Right := AMaxX;
  R.Bottom := AMaxY;
  FrameRect(R, AClientWidth, AClientHeight);
end;

end.
