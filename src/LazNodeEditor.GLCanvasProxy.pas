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
unit LazNodeEditor.GLCanvasProxy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types,
  Graphics, FPCanvas, FPImage, GraphType, LCLType,
  GL2DCanvas;

type
  { TGLCanvasProxy
    Совместимый с TCanvas прокси, который перенаправляет рисование
    в TGL2DCanvas. }

  TGLCanvasProxy = class(TCanvas)
  private
    FGL: TGL2DCanvas;

    FProxyClipRect: TRect;
    FProxyClipping: boolean;


    procedure SyncStateToGL;
    procedure SyncClipToGL;

    procedure PenChanged(Sender: TObject);
    procedure BrushChanged(Sender: TObject);
    procedure FontChanged(Sender: TObject);

  protected
    function DoCreateDefaultFont: TFPCustomFont; override;
    function DoCreateDefaultPen: TFPCustomPen; override;
    function DoCreateDefaultBrush: TFPCustomBrush; override;

    procedure DoMoveTo(X, Y: integer); override;
    procedure DoLineTo(X, Y: integer); override;
    procedure DoLine(x1, y1, x2, y2: integer); override;
    procedure DoPolyline(const Points: array of TPoint); override;
    procedure DoPolygon(const Points: array of TPoint); override;
    procedure DoPolygonFill(const Points: array of TPoint); override;

    procedure DoRectangle(const Bounds: TRect); override;
    procedure DoRectangleFill(const Bounds: TRect); override;
    procedure DoRectangleAndFill(const Bounds: TRect); override;

    procedure DoEllipse(const Bounds: TRect); override;
    procedure DoEllipseFill(const Bounds: TRect); override;
    procedure DoEllipseAndFill(const Bounds: TRect); override;

    procedure DoTextOut(x, y: integer; Text: string); override;
    procedure DoGetTextSize(Text: string; var w, h: integer); override;
    function DoGetTextHeight(Text: string): integer; override;
    function DoGetTextWidth(Text: string): integer; override;

    procedure DoFloodFill(x, y: integer); override;
    procedure DoCopyRect(x, y: integer; SrcCanvas: TFPCustomCanvas;
      const SourceRect: TRect); override;
    procedure DoDraw(x, y: integer; const Image: TFPCustomImage); override;
    procedure DoPolyBezier(Points: PPoint; NumPts: integer;
      Filled: boolean = False; Continuous: boolean = False); override;

    procedure SetColor(x, y: integer; const Value: TFPColor); override;
    function GetColor(x, y: integer): TFPColor; override;

    procedure SetHeight(AValue: integer); override;
    function GetHeight: integer; override;
    procedure SetWidth(AValue: integer); override;
    function GetWidth: integer; override;

    function GetClipRect: TRect; override;
    procedure SetClipRect(const ARect: TRect); override;
    function GetClipping: boolean; override;
    procedure SetClipping(const AValue: boolean); override;

    procedure Changing; override;
    procedure Changed; override;

  public
    constructor Create(AGL: TGL2DCanvas); reintroduce;
    destructor Destroy; override;

    procedure Attach(AGL: TGL2DCanvas);

    procedure BeginDraw;
    procedure EndDraw;
    procedure SetSize(AWidth, AHeight: integer);

    procedure GradientFill(ARect: TRect; AStart, AStop: TColor;
      ADirection: TGradientDirection); reintroduce;
    procedure Frame(const ARect: TRect); reintroduce;
    procedure Frame3d(var ARect: TRect; const FrameWidth: integer;
      const Style: TGraphicsBevelCut); reintroduce;
    procedure Frame3D(var ARect: TRect; TopColor, BottomColor: TColor;
      const FrameWidth: integer); reintroduce;
    procedure DrawFocusRect(const ARect: TRect); override;

    procedure Arc(ALeft, ATop, ARight, ABottom, Angle16Deg,
      Angle16DegLength: integer);
      override;
    procedure Arc(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: integer); override;
    procedure ArcTo(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: integer); override;
    procedure AngleArc(X, Y: integer; Radius: longword;
      StartAngle, SweepAngle: single); reintroduce;
    procedure BrushCopy(ADestRect: TRect; ABitmap: TBitmap;
      ASourceRect: TRect; ATransparentColor: TColor); override;
    procedure Chord(x1, y1, x2, y2, Angle16Deg, Angle16DegLength: integer);
      override;
    procedure Chord(x1, y1, x2, y2, SX, SY, EX, EY: integer); override;
    procedure CopyRect(const Dest: TRect; SrcCanvas: TCanvas;
      const Source: TRect); override;
    procedure Draw(X, Y: integer; SrcGraphic: TGraphic); override;
    procedure Ellipse(const ARect: TRect); reintroduce;
    procedure Ellipse(x1, y1, x2, y2: integer);override;
    procedure StretchDraw(const DestRect: TRect; SrcGraphic: TGraphic); override;
    procedure FillRect(const ARect: TRect); override;
    procedure FillRect(X1, Y1, X2, Y2: integer); reintroduce;
    procedure FloodFill(X, Y: integer; FillColor: TColor;
      FillStyle: TFillStyle); override;
    function GetTextMetrics(out TM: TLCLTextMetric): boolean; override;
    procedure RadialPie(x1, y1, x2, y2, StartAngle16Deg, Angle16DegLength: integer);
      override;
    procedure Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2,
      StartX, StartY, EndX, EndY: integer); override;
    procedure PolyBezier(Points: PPoint; NumPts: integer;
      Filled: boolean = False; Continuous: boolean = True); override;
    procedure PolyBezier(const Points: array of TPoint; Filled: boolean = False;
      Continuous: boolean = True); reintroduce;
    procedure Polygon(const Points: array of TPoint; Winding: boolean;
      StartIndex: integer = 0; NumPts: integer = -1); reintroduce;
    procedure Polygon(Points: PPoint; NumPts: integer;
      Winding: boolean = False); override;
    procedure Polyline(const Points: array of TPoint; StartIndex: integer;
      NumPts: integer = -1); reintroduce;
    procedure Polyline(Points: PPoint; NumPts: integer); override;
    procedure Rectangle(X1, Y1, X2, Y2: integer); override;
    procedure Rectangle(const R: TRect); reintroduce;
    procedure RoundRect(X1, Y1, X2, Y2, RX, RY: integer); override;
    procedure RoundRect(const Rect: TRect; RX, RY: integer); reintroduce;
    procedure TextOut(X, Y: integer; const Text: string); override;
    procedure TextRect(const ARect: TRect; X, Y: integer; const Text: string);
      reintroduce;
    procedure TextRect(ARect: TRect; X, Y: integer; const Text: string;
      const Style: TTextStyle); override;
    function TextExtent(const Text: string): TSize; override;
    function TextHeight(const Text: string): integer; override;
    function TextWidth(const Text: string): integer; override;
    {$IF Defined(MSWINDOWS) and (not Defined(FPC) or (FPC_FULLVERSION >= 30301))}
    function TextFitInfo(const Text: string; MaxWidth: integer): integer; override;
    {$ENDIF}
    function HandleAllocated: boolean; override;
    function GetUpdatedHandle(ReqState: TCanvasState): HDC; override;

    property GLCanvas: TGL2DCanvas read FGL;
  end;

implementation

constructor TGLCanvasProxy.Create(AGL: TGL2DCanvas);
begin
  inherited Create;
  FGL := AGL;

  FProxyClipRect := Rect(0, 0, 0, 0);
  FProxyClipping := False;

  Pen.OnChange := @PenChanged;
  Brush.OnChange := @BrushChanged;
  Font.OnChange := @FontChanged;

  if Assigned(FGL) then
  begin
    if (FGL.Width > 0) and (FGL.Height > 0) then
      FProxyClipRect := Rect(0, 0, FGL.Width, FGL.Height);
    SyncStateToGL;
  end;
end;

destructor TGLCanvasProxy.Destroy;
begin
  inherited Destroy;
end;

procedure TGLCanvasProxy.Attach(AGL: TGL2DCanvas);
begin
  FGL := AGL;
  if Assigned(FGL) then
  begin
    if (FProxyClipRect.Right <= FProxyClipRect.Left) or
      (FProxyClipRect.Bottom <= FProxyClipRect.Top) then
      FProxyClipRect := Rect(0, 0, FGL.Width, FGL.Height);
    SyncStateToGL;
  end;
end;

procedure TGLCanvasProxy.SyncStateToGL;
begin
  if not Assigned(FGL) then
    Exit;

  FGL.Pen.Assign(Pen);
  FGL.Brush.Assign(Brush);
  FGL.Font.Assign(Font);
  SyncClipToGL;
end;

procedure TGLCanvasProxy.SyncClipToGL;
begin
  if not Assigned(FGL) then
    Exit;

  FGL.ClipRect := FProxyClipRect;
  FGL.Clipping := FProxyClipping;
end;

procedure TGLCanvasProxy.PenChanged(Sender: TObject);
begin
  SyncStateToGL;
end;

procedure TGLCanvasProxy.BrushChanged(Sender: TObject);
begin
  SyncStateToGL;
end;

procedure TGLCanvasProxy.FontChanged(Sender: TObject);
begin
  SyncStateToGL;
end;

procedure TGLCanvasProxy.Changing;
begin
  inherited Changing;
  SyncStateToGL;
end;

procedure TGLCanvasProxy.Changed;
begin
  inherited Changed;
  SyncStateToGL;
end;

function TGLCanvasProxy.DoCreateDefaultFont: TFPCustomFont;
begin
  Result := inherited DoCreateDefaultFont;
end;

function TGLCanvasProxy.DoCreateDefaultPen: TFPCustomPen;
begin
  Result := inherited DoCreateDefaultPen;
end;

function TGLCanvasProxy.DoCreateDefaultBrush: TFPCustomBrush;
begin
  Result := inherited DoCreateDefaultBrush;
end;

procedure TGLCanvasProxy.DoMoveTo(X, Y: integer);
begin
  if Assigned(FGL) then
    FGL.MoveTo(X, Y);
end;

procedure TGLCanvasProxy.DoLineTo(X, Y: integer);
begin
  if Assigned(FGL) then
    FGL.LineTo(X, Y);
end;

procedure TGLCanvasProxy.DoLine(x1, y1, x2, y2: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.MoveTo(x1, y1);
    FGL.LineTo(x2, y2);
  end;
end;

procedure TGLCanvasProxy.DoPolyline(const Points: array of TPoint);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Polyline(Points);
  end;
end;

procedure TGLCanvasProxy.DoPolygon(const Points: array of TPoint);
var
  SaveBrushStyle: TBrushStyle;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    SaveBrushStyle := FGL.Brush.Style;
    try
      FGL.Brush.Style := bsClear;
      FGL.Polygon(Points);
    finally
      FGL.Brush.Style := SaveBrushStyle;
    end;
  end;
end;

procedure TGLCanvasProxy.DoPolygonFill(const Points: array of TPoint);
var
  SavePenStyle: TPenStyle;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    SavePenStyle := FGL.Pen.Style;
    try
      FGL.Pen.Style := psClear;
      FGL.Polygon(Points, False, 0, Length(Points));
    finally
      FGL.Pen.Style := SavePenStyle;
    end;
  end;
end;

procedure TGLCanvasProxy.DoRectangle(const Bounds: TRect);
var
  SaveBrushStyle: TBrushStyle;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    SaveBrushStyle := FGL.Brush.Style;
    try
      FGL.Brush.Style := bsClear;
      FGL.Rectangle(Bounds);
    finally
      FGL.Brush.Style := SaveBrushStyle;
    end;
  end;
end;

procedure TGLCanvasProxy.DoRectangleFill(const Bounds: TRect);
var
  SavePenStyle: TPenStyle;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    SavePenStyle := FGL.Pen.Style;
    try
      FGL.Pen.Style := psClear;
      FGL.Rectangle(Bounds);
    finally
      FGL.Pen.Style := SavePenStyle;
    end;
  end;
end;

procedure TGLCanvasProxy.DoRectangleAndFill(const Bounds: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Rectangle(Bounds);
  end;
end;

procedure TGLCanvasProxy.DoEllipse(const Bounds: TRect);
var
  SaveBrushStyle: TBrushStyle;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    SaveBrushStyle := FGL.Brush.Style;
    try
      FGL.Brush.Style := bsClear;
      FGL.Ellipse(Bounds);
    finally
      FGL.Brush.Style := SaveBrushStyle;
    end;
  end;
end;

procedure TGLCanvasProxy.DoEllipseFill(const Bounds: TRect);
var
  SavePenStyle: TPenStyle;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    SavePenStyle := FGL.Pen.Style;
    try
      FGL.Pen.Style := psClear;
      FGL.Ellipse(Bounds);
    finally
      FGL.Pen.Style := SavePenStyle;
    end;
  end;
end;

procedure TGLCanvasProxy.DoEllipseAndFill(const Bounds: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Ellipse(Bounds);
  end;
end;

procedure TGLCanvasProxy.DoTextOut(x, y: integer; Text: string);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.TextOut(x, y, Text);
  end;
end;

procedure TGLCanvasProxy.DoGetTextSize(Text: string; var w, h: integer);
var
  S: TSize;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    S := FGL.TextExtent(Text);
    w := S.cx;
    h := S.cy;
  end
  else
    inherited DoGetTextSize(Text, w, h);
end;

function TGLCanvasProxy.DoGetTextHeight(Text: string): integer;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    Result := FGL.TextHeight(Text);
  end
  else
    Result := inherited DoGetTextHeight(Text);
end;

function TGLCanvasProxy.DoGetTextWidth(Text: string): integer;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    Result := FGL.TextWidth(Text);
  end
  else
    Result := inherited DoGetTextWidth(Text);
end;

procedure TGLCanvasProxy.DoFloodFill(x, y: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.FloodFill(x, y, Brush.Color, fsSurface);
  end;
end;

procedure TGLCanvasProxy.DoCopyRect(x, y: integer; SrcCanvas: TFPCustomCanvas;
  const SourceRect: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.CopyRect(
      Rect(x, y, x + (SourceRect.Right - SourceRect.Left), y +
      (SourceRect.Bottom - SourceRect.Top)),
      TCanvas(SrcCanvas),
      SourceRect
      );
  end;
end;

procedure TGLCanvasProxy.DoDraw(x, y: integer; const Image: TFPCustomImage);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.StretchDraw(x, y, Image.Width, Image.Height, Image);
  end;
end;

procedure TGLCanvasProxy.DoPolyBezier(Points: PPoint; NumPts: integer;
  Filled: boolean; Continuous: boolean);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.PolyBezier(Points, NumPts, Filled, Continuous);
  end
  else
    inherited DoPolyBezier(Points, NumPts, Filled, Continuous);
end;

procedure TGLCanvasProxy.SetColor(x, y: integer; const Value: TFPColor);
begin
  if Assigned(FGL) then
    FGL.Colors[x, y] := Value;
end;

function TGLCanvasProxy.GetColor(x, y: integer): TFPColor;
begin
  if Assigned(FGL) then
    Result := FGL.Colors[x, y]
  else
    Result := colTransparent;
end;

procedure TGLCanvasProxy.SetHeight(AValue: integer);
begin
  if Assigned(FGL) then
    FGL.SetSize(FGL.Width, AValue);
end;

function TGLCanvasProxy.GetHeight: integer;
begin
  if Assigned(FGL) then
    Result := FGL.Height
  else
    Result := 0;
end;

procedure TGLCanvasProxy.SetWidth(AValue: integer);
begin
  if Assigned(FGL) then
    FGL.SetSize(AValue, FGL.Height);
end;

function TGLCanvasProxy.GetWidth: integer;
begin
  if Assigned(FGL) then
    Result := FGL.Width
  else
    Result := 0;
end;

function TGLCanvasProxy.GetClipRect: TRect;
begin
  Result := FProxyClipRect;
end;

procedure TGLCanvasProxy.SetClipRect(const ARect: TRect);
begin
  FProxyClipRect := ARect;
  if Assigned(FGL) then
    FGL.ClipRect := ARect;
end;

function TGLCanvasProxy.GetClipping: boolean;
begin
  Result := FProxyClipping;
end;

procedure TGLCanvasProxy.SetClipping(const AValue: boolean);
begin
  FProxyClipping := AValue;
  if Assigned(FGL) then
    FGL.Clipping := AValue;
end;

procedure TGLCanvasProxy.BeginDraw;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.BeginDraw;
  end;
end;

procedure TGLCanvasProxy.EndDraw;
begin
  if Assigned(FGL) then
    FGL.EndDraw;
end;

procedure TGLCanvasProxy.SetSize(AWidth, AHeight: integer);
begin
  if Assigned(FGL) then
    FGL.SetSize(AWidth, AHeight);

  if not FProxyClipping then
    FProxyClipRect := Rect(0, 0, AWidth, AHeight);
end;

procedure TGLCanvasProxy.GradientFill(ARect: TRect; AStart, AStop: TColor;
  ADirection: TGradientDirection);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.GradientFill(ARect, AStart, AStop, ADirection);
  end;
end;

procedure TGLCanvasProxy.Frame(const ARect: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Frame(ARect);
  end;
end;

procedure TGLCanvasProxy.Frame3d(var ARect: TRect; const FrameWidth: integer;
  const Style: TGraphicsBevelCut);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Frame3d(ARect, FrameWidth, Style);
  end;
end;

procedure TGLCanvasProxy.Frame3D(var ARect: TRect; TopColor, BottomColor: TColor;
  const FrameWidth: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Frame3D(ARect, TopColor, BottomColor, FrameWidth);
  end;
end;

procedure TGLCanvasProxy.DrawFocusRect(const ARect: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.DrawFocusRect(ARect);
  end
  else
    inherited DrawFocusRect(ARect);
end;

procedure TGLCanvasProxy.Arc(ALeft, ATop, ARight, ABottom, Angle16Deg,
  Angle16DegLength: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Arc(ALeft, ATop, ARight, ABottom, Angle16Deg, Angle16DegLength);
  end
  else
    inherited Arc(ALeft, ATop, ARight, ABottom, Angle16Deg, Angle16DegLength);
end;

procedure TGLCanvasProxy.Arc(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Arc(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY);
  end
  else
    inherited Arc(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY);
end;

procedure TGLCanvasProxy.ArcTo(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.ArcTo(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY);
  end
  else
    inherited ArcTo(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY);
end;

procedure TGLCanvasProxy.AngleArc(X, Y: integer; Radius: longword;
  StartAngle, SweepAngle: single);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.AngleArc(X, Y, Radius, StartAngle, SweepAngle);
  end;
end;

procedure TGLCanvasProxy.BrushCopy(ADestRect: TRect; ABitmap: TBitmap;
  ASourceRect: TRect; ATransparentColor: TColor);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.BrushCopy(ADestRect, ABitmap, ASourceRect, ATransparentColor);
  end
  else
    inherited BrushCopy(ADestRect, ABitmap, ASourceRect, ATransparentColor);
end;

procedure TGLCanvasProxy.Chord(x1, y1, x2, y2, Angle16Deg, Angle16DegLength: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Chord(x1, y1, x2, y2, Angle16Deg, Angle16DegLength);
  end
  else
    inherited Chord(x1, y1, x2, y2, Angle16Deg, Angle16DegLength);
end;

procedure TGLCanvasProxy.Chord(x1, y1, x2, y2, SX, SY, EX, EY: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Chord(x1, y1, x2, y2, SX, SY, EX, EY);
  end
  else
    inherited Chord(x1, y1, x2, y2, SX, SY, EX, EY);
end;

procedure TGLCanvasProxy.CopyRect(const Dest: TRect; SrcCanvas: TCanvas;
  const Source: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.CopyRect(Dest, SrcCanvas, Source);
  end
  else
    inherited CopyRect(Dest, SrcCanvas, Source);
end;

procedure TGLCanvasProxy.Draw(X, Y: integer; SrcGraphic: TGraphic);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Draw(X, Y, SrcGraphic);
  end
  else
    inherited Draw(X, Y, SrcGraphic);
end;

procedure TGLCanvasProxy.Ellipse(const ARect: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Ellipse(ARect);
  end
  else
    inherited Ellipse(ARect);
end;

procedure TGLCanvasProxy.Ellipse(x1, y1, x2, y2: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Ellipse(x1,y1,x2,y2);
  end
  else
    inherited Ellipse(x1,y1,x2,y2);
end;

procedure TGLCanvasProxy.StretchDraw(const DestRect: TRect; SrcGraphic: TGraphic);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.StretchDraw(DestRect, SrcGraphic);
  end
  else
    inherited StretchDraw(DestRect, SrcGraphic);
end;

procedure TGLCanvasProxy.FillRect(const ARect: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.FillRect(ARect);
  end
  else
    inherited FillRect(ARect);
end;

procedure TGLCanvasProxy.FillRect(X1, Y1, X2, Y2: integer);
begin
  FillRect(Rect(X1, Y1, X2, Y2));
end;

procedure TGLCanvasProxy.FloodFill(X, Y: integer; FillColor: TColor;
  FillStyle: TFillStyle);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.FloodFill(X, Y, FillColor, FillStyle);
  end
  else
    inherited FloodFill(X, Y, FillColor, FillStyle);
end;

function TGLCanvasProxy.GetTextMetrics(out TM: TLCLTextMetric): boolean;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    Result := FGL.GetTextMetrics(TM);
  end
  else
    Result := inherited GetTextMetrics(TM);
end;

procedure TGLCanvasProxy.RadialPie(x1, y1, x2, y2, StartAngle16Deg,
  Angle16DegLength: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.RadialPie(x1, y1, x2, y2, StartAngle16Deg, Angle16DegLength);
  end
  else
    inherited RadialPie(x1, y1, x2, y2, StartAngle16Deg, Angle16DegLength);
end;

procedure TGLCanvasProxy.Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2,
  StartX, StartY, EndX, EndY: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2, StartX, StartY, EndX, EndY);
  end
  else
    inherited Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2, StartX,
      StartY, EndX, EndY);
end;

procedure TGLCanvasProxy.PolyBezier(Points: PPoint; NumPts: integer;
  Filled: boolean; Continuous: boolean);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.PolyBezier(Points, NumPts, Filled, Continuous);
  end
  else
    inherited PolyBezier(Points, NumPts, Filled, Continuous);
end;

procedure TGLCanvasProxy.PolyBezier(const Points: array of TPoint;
  Filled: boolean; Continuous: boolean);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.PolyBezier(Points, Filled, Continuous);
  end
  else
    inherited PolyBezier(Points, Filled, Continuous);
end;

procedure TGLCanvasProxy.Polygon(const Points: array of TPoint;
  Winding: boolean; StartIndex: integer; NumPts: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Polygon(Points, Winding, StartIndex, NumPts);
  end
  else
    inherited Polygon(Points, Winding, StartIndex, NumPts);
end;

procedure TGLCanvasProxy.Polygon(Points: PPoint; NumPts: integer; Winding: boolean);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Polygon(Points, NumPts, Winding);
  end
  else
    inherited Polygon(Points, NumPts, Winding);
end;

procedure TGLCanvasProxy.Polyline(const Points: array of TPoint;
  StartIndex: integer; NumPts: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Polyline(Points, StartIndex, NumPts);
  end
  else
    inherited Polyline(Points, StartIndex, NumPts);
end;

procedure TGLCanvasProxy.Polyline(Points: PPoint; NumPts: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Polyline(Points, NumPts);
  end
  else
    inherited Polyline(Points, NumPts);
end;

procedure TGLCanvasProxy.Rectangle(X1, Y1, X2, Y2: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Rectangle(X1, Y1, X2, Y2);
  end
  else
    inherited Rectangle(X1, Y1, X2, Y2);
end;

procedure TGLCanvasProxy.Rectangle(const R: TRect);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.Rectangle(R);
  end
  else
    inherited Rectangle(R);
end;

procedure TGLCanvasProxy.RoundRect(X1, Y1, X2, Y2, RX, RY: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.RoundRect(X1, Y1, X2, Y2, RX, RY);
  end
  else
    inherited RoundRect(X1, Y1, X2, Y2, RX, RY);
end;

procedure TGLCanvasProxy.RoundRect(const Rect: TRect; RX, RY: integer);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.RoundRect(Rect, RX, RY);
  end
  else
    inherited RoundRect(Rect, RX, RY);
end;

procedure TGLCanvasProxy.TextOut(X, Y: integer; const Text: string);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.TextOut(X,Y,Text);
  end
  else
    inherited TextOut(X,Y,Text);
end;

procedure TGLCanvasProxy.TextRect(const ARect: TRect; X, Y: integer;
  const Text: string);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.TextRect(ARect, X, Y, Text);
  end
  else
    inherited TextRect(ARect, X, Y, Text);
end;

procedure TGLCanvasProxy.TextRect(ARect: TRect; X, Y: integer;
  const Text: string; const Style: TTextStyle);
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    FGL.TextRect(ARect, X, Y, Text, Style);
  end
  else
    inherited TextRect(ARect, X, Y, Text, Style);
end;

function TGLCanvasProxy.TextExtent(const Text: string): TSize;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    Result := FGL.TextExtent(Text);
  end
  else
    Result := inherited TextExtent(Text);
end;

function TGLCanvasProxy.TextHeight(const Text: string): integer;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    Result := FGL.TextHeight(Text);
  end
  else
    Result := inherited TextHeight(Text);
end;

function TGLCanvasProxy.TextWidth(const Text: string): integer;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    Result := FGL.TextWidth(Text);
  end
  else
    Result := inherited TextWidth(Text);
end;

{$IF Defined(MSWINDOWS) and (not Defined(FPC) or (FPC_FULLVERSION >= 30301))}
function TGLCanvasProxy.TextFitInfo(const Text: string; MaxWidth: integer): integer;
begin
  if Assigned(FGL) then
  begin
    SyncStateToGL;
    Result := FGL.TextFitInfo(Text, MaxWidth);
  end
  else
    Result := inherited TextFitInfo(Text, MaxWidth);
end;
{$ENDIF}

function TGLCanvasProxy.HandleAllocated: boolean;
begin
  if Assigned(FGL) then
    Result := FGL.HandleAllocated
  else
    Result := inherited HandleAllocated;
end;

function TGLCanvasProxy.GetUpdatedHandle(ReqState: TCanvasState): HDC;
begin
  if Assigned(FGL) then
    Result := FGL.GetUpdatedHandle(ReqState)
  else
    Result := inherited GetUpdatedHandle(ReqState);
end;

end.
