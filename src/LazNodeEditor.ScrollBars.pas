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
unit LazNodeEditor.ScrollBars;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math,
  LazNodeEditor.Renderer,
  LazNodeEditor.Viewport;

type
  TNodeEditorScrollBars = class
  private
    FVisible: boolean;
    FThickness: integer;
    FMode: TScrollBarsMode;

    FHVisible: boolean;
    FVVisible: boolean;

    FHThumbRect: TRect;
    FVThumbRect: TRect;
    FHTrackRect: TRect;
    FVTrackRect: TRect;

    FHHot: boolean;
    FVHot: boolean;

    FHDragging: boolean;
    FVDragging: boolean;

    FDragStartMouse: TPoint;
    FDragStartOffsetX: double;
    FDragStartOffsetY: double;
    FDragThumbOffset: integer;

    FWorldRangeLeft: double;
    FWorldRangeTop: double;
    FWorldRangeRight: double;
    FWorldRangeBottom: double;

    procedure CalcScrollWorldRange(const AGraphBounds, AVisibleWorld: TRectF;
      out ARangeLeft, ARangeTop, ARangeRight, ARangeBottom: double);

    function GetHorizontalScrollEnabled: boolean; inline;
    function GetVerticalScrollEnabled: boolean; inline;
    function NeedHorizontalInAuto(const AGraphBounds, AVisibleWorld: TRectF): boolean; inline;
    function NeedVerticalInAuto(const AGraphBounds, AVisibleWorld: TRectF): boolean; inline;
  public
    constructor Create;

    procedure Reset;

    procedure Update(const AViewport: TNodeViewport;
      const AGraphBounds: TRectF; AHasGraphBounds: boolean;
      AClientWidth, AClientHeight: integer);

    function HitTestHThumb(X, Y: integer): boolean;
    function HitTestVThumb(X, Y: integer): boolean;
    function HitTestHTrack(X, Y: integer): boolean;
    function HitTestVTrack(X, Y: integer): boolean;

    function MouseDown(const AViewport: TNodeViewport;
      const AGraphBounds: TRectF; AHasGraphBounds: boolean;
      AClientWidth, AClientHeight: integer;
      X, Y: integer): boolean;

    function MouseMove(const AViewport: TNodeViewport;
      const AGraphBounds: TRectF; AHasGraphBounds: boolean;
      AClientWidth, AClientHeight: integer;
      X, Y: integer; out ANeedInvalidate: boolean): boolean;

    function MouseUp(out ANeedInvalidate: boolean): boolean;

    function UpdateHotState(X, Y: integer): boolean;

    function ScrollPageToClick(const AViewport: TNodeViewport;
      const AGraphBounds: TRectF; AHasGraphBounds: boolean;
      AClientWidth, AClientHeight: integer;
      X, Y: integer): boolean;

    property Visible: boolean read FVisible write FVisible;
    property Thickness: integer read FThickness write FThickness;
    property Mode: TScrollBarsMode read FMode write FMode;

    property HVisible: boolean read FHVisible;
    property VVisible: boolean read FVVisible;

    property HThumbRect: TRect read FHThumbRect;
    property VThumbRect: TRect read FVThumbRect;
    property HTrackRect: TRect read FHTrackRect;
    property VTrackRect: TRect read FVTrackRect;

    property HHot: boolean read FHHot;
    property VHot: boolean read FVHot;

    property HDragging: boolean read FHDragging;
    property VDragging: boolean read FVDragging;

    property DragStartMouse: TPoint read FDragStartMouse;
    property DragStartOffsetX: double read FDragStartOffsetX;
    property DragStartOffsetY: double read FDragStartOffsetY;
    property DragThumbOffset: integer read FDragThumbOffset;
  end;

implementation

constructor TNodeEditorScrollBars.Create;
begin
  inherited Create;
  FVisible := True;
  FThickness := 12;
  FMode := sbmAuto;
  Reset;
end;

procedure TNodeEditorScrollBars.Reset;
begin
  FHVisible := False;
  FVVisible := False;

  FHThumbRect := Rect(0, 0, 0, 0);
  FVThumbRect := Rect(0, 0, 0, 0);
  FHTrackRect := Rect(0, 0, 0, 0);
  FVTrackRect := Rect(0, 0, 0, 0);

  FHHot := False;
  FVHot := False;

  FHDragging := False;
  FVDragging := False;

  FDragStartMouse := Point(0, 0);
  FDragStartOffsetX := 0;
  FDragStartOffsetY := 0;
  FDragThumbOffset := 0;
end;

procedure TNodeEditorScrollBars.CalcScrollWorldRange(
  const AGraphBounds, AVisibleWorld: TRectF;
  out ARangeLeft, ARangeTop, ARangeRight, ARangeBottom: double);
var
  PadX, PadY: double;
begin
  ARangeLeft := Min(AGraphBounds.Left, AVisibleWorld.Left);
  ARangeTop := Min(AGraphBounds.Top, AVisibleWorld.Top);
  ARangeRight := Max(AGraphBounds.Right, AVisibleWorld.Right);
  ARangeBottom := Max(AGraphBounds.Bottom, AVisibleWorld.Bottom);

  PadX := (AVisibleWorld.Right - AVisibleWorld.Left) * 0.5;
  PadY := (AVisibleWorld.Bottom - AVisibleWorld.Top) * 0.5;

  if PadX < 50 then PadX := 50;
  if PadY < 50 then PadY := 50;

  ARangeLeft := ARangeLeft - PadX;
  ARangeTop := ARangeTop - PadY;
  ARangeRight := ARangeRight + PadX;
  ARangeBottom := ARangeBottom + PadY;
end;

function TNodeEditorScrollBars.GetHorizontalScrollEnabled: boolean; inline;
begin
  case FMode of
    sbmNone: Result := False;
    sbmHorizontal: Result := True;
    sbmVertical: Result := False;
    sbmBoth: Result := True;
    sbmAuto: Result := True;
    else
      Result := True;
  end;
end;

function TNodeEditorScrollBars.GetVerticalScrollEnabled: boolean; inline;
begin
  case FMode of
    sbmNone: Result := False;
    sbmHorizontal: Result := False;
    sbmVertical: Result := True;
    sbmBoth: Result := True;
    sbmAuto: Result := True;
    else
      Result := True;
  end;
end;

function TNodeEditorScrollBars.NeedHorizontalInAuto(
  const AGraphBounds, AVisibleWorld: TRectF): boolean; inline;
const
  Eps = 1e-3;
begin
  Result :=
    (AGraphBounds.Left < AVisibleWorld.Left - Eps) or
    (AGraphBounds.Right > AVisibleWorld.Right + Eps);
end;

function TNodeEditorScrollBars.NeedVerticalInAuto(
  const AGraphBounds, AVisibleWorld: TRectF): boolean; inline;
const
  Eps = 1e-3;
begin
  Result :=
    (AGraphBounds.Top < AVisibleWorld.Top - Eps) or
    (AGraphBounds.Bottom > AVisibleWorld.Bottom + Eps);
end;

procedure TNodeEditorScrollBars.Update(const AViewport: TNodeViewport;
  const AGraphBounds: TRectF; AHasGraphBounds: boolean;
  AClientWidth, AClientHeight: integer);
var
  VW: TRectF;
  GraphW, GraphH: single;
  ViewW, ViewH: single;
  Ratio: double;
  ThumbSize: integer;
  TrackLen: integer;
  ThumbPos: integer;
  NeedH, NeedV: boolean;
  WorkClientW, WorkClientH: integer;
  RangeLeft, RangeRight, RangeTop, RangeBottom: double;
  RangeW, RangeH, ScrollW, ScrollH: double;
begin
  FHVisible := False;
  FVVisible := False;
  FHThumbRect := Rect(0, 0, 0, 0);
  FVThumbRect := Rect(0, 0, 0, 0);
  FHTrackRect := Rect(0, 0, 0, 0);
  FVTrackRect := Rect(0, 0, 0, 0);

  if not FVisible then
    Exit;

  if not AHasGraphBounds then
    Exit;

  if (AClientWidth <= 0) or (AClientHeight <= 0) then
    Exit;

  NeedH := GetHorizontalScrollEnabled;
  NeedV := GetVerticalScrollEnabled;

  WorkClientW := AClientWidth;
  WorkClientH := AClientHeight;

  VW := AViewport.GetVisibleWorldRect(WorkClientW, WorkClientH);

  GraphW := AGraphBounds.Right - AGraphBounds.Left;
  GraphH := AGraphBounds.Bottom - AGraphBounds.Top;
  ViewW := VW.Right - VW.Left;
  ViewH := VW.Bottom - VW.Top;

  if FMode = sbmAuto then
  begin
    NeedH := NeedHorizontalInAuto(AGraphBounds, VW) and (WorkClientW > 30);
    NeedV := NeedVerticalInAuto(AGraphBounds, VW) and (WorkClientH > 30);

    if NeedV then
      Dec(WorkClientW, FThickness);
    if NeedH then
      Dec(WorkClientH, FThickness);

    VW := AViewport.GetVisibleWorldRect(WorkClientW, WorkClientH);
    ViewW := VW.Right - VW.Left;
    ViewH := VW.Bottom - VW.Top;

    NeedH := NeedHorizontalInAuto(AGraphBounds, VW) and (WorkClientW > 30);
    NeedV := NeedVerticalInAuto(AGraphBounds, VW) and (WorkClientH > 30);
  end
  else
  begin
    if NeedV then
      Dec(WorkClientW, FThickness);
    if NeedH then
      Dec(WorkClientH, FThickness);

    VW := AViewport.GetVisibleWorldRect(WorkClientW, WorkClientH);
    ViewW := VW.Right - VW.Left;
    ViewH := VW.Bottom - VW.Top;
  end;

  FHVisible := NeedH;
  FVVisible := NeedV;

  if FHVisible then
  begin
    FHTrackRect := Rect(
      0,
      AClientHeight - FThickness,
      AClientWidth - IfThen(FVVisible, FThickness, 0),
      AClientHeight
    );

    TrackLen := FHTrackRect.Right - FHTrackRect.Left;

    CalcScrollWorldRange(AGraphBounds, VW, FWorldRangeLeft, FWorldRangeTop, FWorldRangeRight, FWorldRangeBottom);

    RangeLeft := FWorldRangeLeft;
    RangeRight := FWorldRangeRight;
    RangeW := RangeRight - RangeLeft;

    if RangeW <= 0.001 then
      ThumbSize := TrackLen
    else
    begin
      Ratio := ViewW / RangeW;
      ThumbSize := Max(24, Round(TrackLen * Ratio));
      if ThumbSize > TrackLen then
        ThumbSize := TrackLen;
    end;

    ScrollW := RangeW - ViewW;

    if ScrollW > 0.001 then
      ThumbPos := FHTrackRect.Left + Round(
        (VW.Left - RangeLeft) / ScrollW * (TrackLen - ThumbSize)
      )
    else
      ThumbPos := FHTrackRect.Left;

    if ThumbPos < FHTrackRect.Left then
      ThumbPos := FHTrackRect.Left;
    if ThumbPos > FHTrackRect.Right - ThumbSize then
      ThumbPos := FHTrackRect.Right - ThumbSize;

    FHThumbRect := Rect(
      ThumbPos,
      FHTrackRect.Top,
      ThumbPos + ThumbSize,
      FHTrackRect.Bottom
    );
  end;

  if FVVisible then
  begin
    FVTrackRect := Rect(
      AClientWidth - FThickness,
      0,
      AClientWidth,
      AClientHeight - IfThen(FHVisible, FThickness, 0)
    );

    TrackLen := FVTrackRect.Bottom - FVTrackRect.Top;

    CalcScrollWorldRange(AGraphBounds, VW, FWorldRangeLeft, FWorldRangeTop, FWorldRangeRight, FWorldRangeBottom);

    RangeTop := FWorldRangeTop;
    RangeBottom := FWorldRangeBottom;
    RangeH := RangeBottom - RangeTop;

    if RangeH <= 0.001 then
      ThumbSize := TrackLen
    else
    begin
      Ratio := ViewH / RangeH;
      ThumbSize := Max(24, Round(TrackLen * Ratio));
      if ThumbSize > TrackLen then
        ThumbSize := TrackLen;
    end;

    ScrollH := RangeH - ViewH;

    if ScrollH > 0.001 then
      ThumbPos := FVTrackRect.Top + Round(
        (VW.Top - RangeTop) / ScrollH * (TrackLen - ThumbSize)
      )
    else
      ThumbPos := FVTrackRect.Top;

    if ThumbPos < FVTrackRect.Top then
      ThumbPos := FVTrackRect.Top;
    if ThumbPos > FVTrackRect.Bottom - ThumbSize then
      ThumbPos := FVTrackRect.Bottom - ThumbSize;

    FVThumbRect := Rect(
      FVTrackRect.Left,
      ThumbPos,
      FVTrackRect.Right,
      ThumbPos + ThumbSize
    );
  end;
end;

function TNodeEditorScrollBars.HitTestHThumb(X, Y: integer): boolean;
begin
  Result := FHVisible and PtInRect(FHThumbRect, Point(X, Y));
end;

function TNodeEditorScrollBars.HitTestVThumb(X, Y: integer): boolean;
begin
  Result := FVVisible and PtInRect(FVThumbRect, Point(X, Y));
end;

function TNodeEditorScrollBars.HitTestHTrack(X, Y: integer): boolean;
begin
  Result := FHVisible and PtInRect(FHTrackRect, Point(X, Y));
end;

function TNodeEditorScrollBars.HitTestVTrack(X, Y: integer): boolean;
begin
  Result := FVVisible and PtInRect(FVTrackRect, Point(X, Y));
end;

function TNodeEditorScrollBars.MouseDown(const AViewport: TNodeViewport;
  const AGraphBounds: TRectF; AHasGraphBounds: boolean;
  AClientWidth, AClientHeight: integer;
  X, Y: integer): boolean;
begin
  Result := False;

  Update(AViewport, AGraphBounds, AHasGraphBounds, AClientWidth, AClientHeight);

  if HitTestHThumb(X, Y) then
  begin
    FHDragging := True;
    FDragStartMouse := Point(X, Y);
    FDragStartOffsetX := AViewport.OffsetX;
    FDragThumbOffset := X - FHThumbRect.Left;
    Exit(True);
  end;

  if HitTestVThumb(X, Y) then
  begin
    FVDragging := True;
    FDragStartMouse := Point(X, Y);
    FDragStartOffsetY := AViewport.OffsetY;
    FDragThumbOffset := Y - FVThumbRect.Top;
    Exit(True);
  end;
end;

function TNodeEditorScrollBars.MouseMove(const AViewport: TNodeViewport;
  const AGraphBounds: TRectF; AHasGraphBounds: boolean;
  AClientWidth, AClientHeight: integer;
  X, Y: integer; out ANeedInvalidate: boolean): boolean;
var
  VW: TRectF;
  TrackLen: integer;
  ThumbSize: integer;
  WorldLeft, WorldTop: double;
  ThumbLeft, ThumbTop: integer;
  WorkClientW, WorkClientH: integer;
  ScrollW, ScrollH: double;
  ThumbK: double;
begin
  Result := False;
  ANeedInvalidate := False;

  if not AHasGraphBounds then
    Exit;

  if FHDragging then
  begin
    WorkClientW := AClientWidth - IfThen(FVVisible, FThickness, 0);
    WorkClientH := AClientHeight - IfThen(FHVisible, FThickness, 0);
    VW := AViewport.GetVisibleWorldRect(WorkClientW, WorkClientH);

    TrackLen := FHTrackRect.Right - FHTrackRect.Left;
    ThumbSize := FHThumbRect.Right - FHThumbRect.Left;

    if TrackLen - ThumbSize > 0 then
    begin
      ThumbLeft := EnsureRange(X - FDragThumbOffset,
        FHTrackRect.Left, FHTrackRect.Right - ThumbSize);

      ScrollW := (FWorldRangeRight - FWorldRangeLeft) - (VW.Right - VW.Left);
      if ScrollW < 0 then
        ScrollW := 0;

      ThumbK := (ThumbLeft - FHTrackRect.Left) / (TrackLen - ThumbSize);

      WorldLeft := FWorldRangeLeft + ThumbK * ScrollW;
      AViewport.OffsetX := -WorldLeft * AViewport.Zoom;

      Update(AViewport, AGraphBounds, AHasGraphBounds, AClientWidth, AClientHeight);
      ANeedInvalidate := True;
    end;

    Exit(True);
  end;

  if FVDragging then
  begin
    WorkClientW := AClientWidth - IfThen(FVVisible, FThickness, 0);
    WorkClientH := AClientHeight - IfThen(FHVisible, FThickness, 0);
    VW := AViewport.GetVisibleWorldRect(WorkClientW, WorkClientH);

    TrackLen := FVTrackRect.Bottom - FVTrackRect.Top;
    ThumbSize := FVThumbRect.Bottom - FVThumbRect.Top;

    if TrackLen - ThumbSize > 0 then
    begin
      ThumbTop := EnsureRange(Y - FDragThumbOffset,
        FVTrackRect.Top, FVTrackRect.Bottom - ThumbSize);

      ScrollH := (FWorldRangeBottom - FWorldRangeTop) - (VW.Bottom - VW.Top);
      if ScrollH < 0 then
        ScrollH := 0;

      ThumbK := (ThumbTop - FVTrackRect.Top) / (TrackLen - ThumbSize);

      WorldTop := FWorldRangeTop + ThumbK * ScrollH;
      AViewport.OffsetY := -WorldTop * AViewport.Zoom;

      Update(AViewport, AGraphBounds, AHasGraphBounds, AClientWidth, AClientHeight);
      ANeedInvalidate := True;
    end;

    Exit(True);
  end;
end;

function TNodeEditorScrollBars.MouseUp(out ANeedInvalidate: boolean): boolean;
begin
  Result := FHDragging or FVDragging;
  ANeedInvalidate := Result;

  FHDragging := False;
  FVDragging := False;
end;

function TNodeEditorScrollBars.UpdateHotState(X, Y: integer): boolean;
var
  NewHHot, NewVHot: boolean;
begin
  NewHHot := HitTestHThumb(X, Y);
  NewVHot := HitTestVThumb(X, Y);

  Result := (NewHHot <> FHHot) or (NewVHot <> FVHot);

  FHHot := NewHHot;
  FVHot := NewVHot;
end;

function TNodeEditorScrollBars.ScrollPageToClick(const AViewport: TNodeViewport;
  const AGraphBounds: TRectF; AHasGraphBounds: boolean;
  AClientWidth, AClientHeight: integer;
  X, Y: integer): boolean;
var
  VW: TRectF;
  TrackLen: integer;
  ThumbSize: integer;
  NewWorldLeft, NewWorldTop: double;
  WorkClientW, WorkClientH: integer;
  ClickPos: double;
  ScrollW, ScrollH: double;
begin
  Result := False;

  if not AHasGraphBounds then
    Exit;

  if HitTestHTrack(X, Y) and not HitTestHThumb(X, Y) then
  begin
    WorkClientW := AClientWidth - IfThen(FVVisible, FThickness, 0);
    WorkClientH := AClientHeight - IfThen(FHVisible, FThickness, 0);
    VW := AViewport.GetVisibleWorldRect(WorkClientW, WorkClientH);

    TrackLen := FHTrackRect.Right - FHTrackRect.Left;
    ThumbSize := FHThumbRect.Right - FHThumbRect.Left;

    if TrackLen - ThumbSize > 0 then
    begin
      ClickPos := EnsureRange(X - FHTrackRect.Left - ThumbSize * 0.5, 0, TrackLen - ThumbSize);
      ScrollW := (FWorldRangeRight - FWorldRangeLeft) - (VW.Right - VW.Left);
      if ScrollW < 0 then
        ScrollW := 0;

      NewWorldLeft := FWorldRangeLeft + (ClickPos / (TrackLen - ThumbSize)) * ScrollW;
      AViewport.OffsetX := -NewWorldLeft * AViewport.Zoom;

      Update(AViewport, AGraphBounds, AHasGraphBounds, AClientWidth, AClientHeight);
      Exit(True);
    end;
  end;

  if HitTestVTrack(X, Y) and not HitTestVThumb(X, Y) then
  begin
    WorkClientW := AClientWidth - IfThen(FVVisible, FThickness, 0);
    WorkClientH := AClientHeight - IfThen(FHVisible, FThickness, 0);
    VW := AViewport.GetVisibleWorldRect(WorkClientW, WorkClientH);

    TrackLen := FVTrackRect.Bottom - FVTrackRect.Top;
    ThumbSize := FVThumbRect.Bottom - FVThumbRect.Top;

    if TrackLen - ThumbSize > 0 then
    begin
      ClickPos := EnsureRange(Y - FVTrackRect.Top - ThumbSize * 0.5, 0, TrackLen - ThumbSize);
      ScrollH := (FWorldRangeBottom - FWorldRangeTop) - (VW.Bottom - VW.Top);
      if ScrollH < 0 then
        ScrollH := 0;

      NewWorldTop := FWorldRangeTop + (ClickPos / (TrackLen - ThumbSize)) * ScrollH;
      AViewport.OffsetY := -NewWorldTop * AViewport.Zoom;

      Update(AViewport, AGraphBounds, AHasGraphBounds, AClientWidth, AClientHeight);
      Exit(True);
    end;
  end;
end;

end.
