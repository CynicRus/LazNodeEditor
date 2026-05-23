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
unit GL2DCanvas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math,
  FPImage, FPCanvas, Graphics,
  GL, GLext, dglOpenGL, OpenGLContext, Generics.Collections,
  LCLType, LCLIntf, GraphType, LazLogger, Contnrs, IntfGraphics, Types;

const
  TEXT_CACHE_MAX = 1024;
  TEXT_CACHE_MAX_AGE = 300;

type
  TGL2DCanvas = class;

  TVec2 = packed record
    X, Y: single;
  end;

  TVec4 = packed record
    X, Y, Z, W: single;
  end;

  TPrimitiveKind = (
    pkSolid = 0,
    pkLine = 1,
    pkRectFill = 2,
    pkRectStroke = 3,
    pkEllipseFill = 4,
    pkEllipseStroke = 5,
    pkRoundRectFill = 6,
    pkRoundRectStroke = 7,
    pkTexture = 8
    );

  TAAColorVertex = packed record
    Position: TVec2;   // screen position in pixels
    Local: TVec2;      // local position for SDF evaluation OR UV coords for textures
    Data0: TVec4;      // primitive parameters (e.g. radius, sizes)
    Color: TVec4;      // rgba
    Kind: single;      // primitive kind as float
  end;

  TTexturedVertex = packed record
    Pos: TVec2;
    UV: TVec2;
    Col: TVec4;
  end;

  TTextCacheKey = record
    Text: string;
    FontName: string;
    FontSize: integer;
    FontStyle: TFontStyles;
    FontColor: TColor;
  end;

  TTextCacheEntry = record
    TexID: GLuint;
    Width: integer;
    Height: integer;
    LastUsedFrame: int64;
  end;

  { TGLCanvasControl }

  TGLCanvasControl = class(TOpenGLControl)
  private
    FCanvas: TGL2DCanvas;
    FOnDraw: TNotifyEvent;
  protected
    procedure DoOnPaint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Canvas: TGL2DCanvas read FCanvas;
    property OnDraw: TNotifyEvent read FOnDraw write FOnDraw;
  published
    property Align;
    property Anchors;
    property BorderStyle;
    property Color;
    property Enabled;
    property Visible;
  end;

  TTextCache = specialize TDictionary<string, TTextCacheEntry>;

  { TGL2DCanvas }

  TGL2DCanvas = class(TFPCustomCanvas)
  private
    FControl: TOpenGLControl;
    FWidth: integer;
    FHeight: integer;

    FClipRect: TRect;
    FClipping: boolean;

    FProgram: GLuint;
    FVAO: GLuint;
    FVBO: GLuint;

    FVertices: array of TAAColorVertex;
    FVertexCount: integer;

    FUniformProjection: GLint;
    FUniformTexture: GLint;
    FUniformHasTexture: GLint;

    FLazPen: TPen;
    FLazBrush: TBrush;
    FLazFont: TFont;

    FCurrentX: integer;
    FCurrentY: integer;

    FGLInitialized: boolean;
    FDrawing: boolean;

    FTextureList: TFPList;
    FTextureCache: TFPList;
    FImagePointers: TFPList;

    FTextureProgram: GLuint;
    FTextureVAO: GLuint;
    FTextureVBO: GLuint;
    FTextureUniformProjection: GLint;
    FTextureUniformTex: GLint;

    FTextCache: TTextCache;
    FCurrentFrame: int64;

    FVBOCapacity: integer;

    procedure PenChanged(Sender: TObject);
    procedure BrushChanged(Sender: TObject);
    procedure FontChanged(Sender: TObject);

    procedure EnsureGLReady;
    procedure LoadShaders;
    procedure CreateBuffers;
    procedure DestroyGLResources;
    function  MakeTextCacheKey(const AText: string): string;


    procedure SetProjection;
    procedure ApplyScissor;
    procedure EnsureVertexCapacity(AExtra: integer);
    procedure Flush;

    function ColorToVec4(const AColor: TColor; AAlpha: single = 1.0): TVec4;
    function AdjustColor(const AColor: TColor; AFactor: integer): TColor;
    function NormalizeRect(const R: TRect): TRect;

    procedure AddVertex(const APos, ALocal: TVec2; const AData0, AColor: TVec4;
      AKind: TPrimitiveKind);

    procedure AddTriangle(const A, B, C: TAAColorVertex);

    procedure AddQuad(const A, B, C, D: TAAColorVertex);

    procedure AddSolidRect(const X1, Y1, X2, Y2: single; const AColor: TVec4);
    procedure AddGradientRect(const X1, Y1, X2, Y2: single; const C1, C2: TVec4;
      ADirection: TGradientDirection);
    procedure AddAALine(const X1, Y1, X2, Y2: single; const AWidth: single;
      const AColor: TVec4);
    procedure AddAARectFill(const X1, Y1, X2, Y2: single; const AColor: TVec4);
    procedure AddAARectStroke(const X1, Y1, X2, Y2, AStrokeWidth: single;
      const AColor: TVec4);
    procedure AddAAEllipseFill(const X1, Y1, X2, Y2: single; const AColor: TVec4);
    procedure AddAAEllipseStroke(const X1, Y1, X2, Y2, AStrokeWidth: single;
      const AColor: TVec4);
    procedure AddAARoundRectFill(const X1, Y1, X2, Y2, ARadiusX, ARadiusY: single;
      const AColor: TVec4);
    procedure AddAARoundRectStroke(const X1, Y1, X2, Y2, ARadiusX,
      ARadiusY, AStrokeWidth: single; const AColor: TVec4);
    procedure AddTexturedQuad(const X1, Y1, X2, Y2: single;
      const U1, V1, U2, V2: single; ATexID: GLuint; const AColor: TVec4);


    function GetTexture(AImage: TFPCustomImage): GLuint;
    procedure LoadTextureShaders;
    procedure CreateTextureBuffers;
    procedure DrawTexturedQuad(Tex: GLuint; X, Y, W, H: integer;
      U1, V1, U2, V2: single; const AColor: TVec4);

    function Angle16ToRad(AAngle16: Integer): Single;
    function PointOnEllipse(const R: TRect; AAngleRad: Single): TPoint;
    procedure BuildArcPolyline(const R: TRect; AStartRad, ASweepRad: Single;
      out Points: array of TPoint; out ACount: Integer);
    procedure DrawArcInternal(const R: TRect; AStartRad, ASweepRad: Single;
      UpdatePenPos: Boolean);
    procedure DrawPieInternal(const R: TRect; AStartRad, ASweepRad: Single);
    procedure DrawChordInternal(const R: TRect; AStartRad, ASweepRad: Single);
    function GraphicToImage(ASrc: TGraphic): TFPCustomImage;
    function PointToEllipseAngle(const R: TRect; PX, PY: Integer): Single;
    {$IFDEF MSWINDOWS}
    function CreateTextTexture_Windows(const Text: ansistring; out W, H: Integer): GLuint;
    {$ELSE}
    function CreateTextTexture_Linux(const Text: ansistring; out W, H: Integer): GLuint;
    {$ENDIF}
    function CreateTextureFromRGBA(const Buf: Pointer; W, H: Integer): GLuint;
  protected
    function DoCreateDefaultFont: TFPCustomFont; override;
    function DoCreateDefaultPen: TFPCustomPen; override;
    function DoCreateDefaultBrush: TFPCustomBrush; override;

    procedure SetColor(x, y: integer; const Value: TFPColor); override;
    function GetColor(x, y: integer): TFPColor; override;

    procedure SetHeight(AValue: integer); override;
    function GetHeight: integer; override;
    procedure SetWidth(AValue: integer); override;
    function GetWidth: integer; override;

    procedure DoLine(x1, y1, x2, y2: integer); override;
    procedure DoMoveTo(X, Y: integer); override;
    procedure DoPolyline(const points: array of TPoint); override;
    procedure DoPolygon(const points: array of TPoint); override;
    procedure DoPolygonFill(const points: array of TPoint); override;
    procedure DoRectangle(const Bounds: TRect); override;
    procedure DoRectangleFill(const Bounds: TRect); override;
    procedure DoEllipse(const Bounds: TRect); override;
    procedure DoEllipseFill(const Bounds: TRect); override;

    procedure DoTextOut(x, y: integer; Text: ansistring); override;
    procedure DoGetTextSize(Text: ansistring; var w, h: integer); override;
    function DoGetTextHeight(Text: ansistring): integer; override;
    function DoGetTextWidth(Text: ansistring): integer; override;

    procedure DoFloodFill(x, y: integer); override;
    procedure DoCopyRect(x, y: integer; canvas: TFPCustomCanvas;
      const SourceRect: TRect); override;
    procedure DoDraw(x, y: integer; const image: TFPCustomImage); override;
    procedure DoRadialPie(x1, y1, x2, y2, StartAngle16Deg,
      Angle16DegLength: integer);
      override;
    procedure DoPolyBezier(Points: PPoint; NumPts: integer;
      Filled, Continuous: boolean); override;

    function GetClipRect: TRect; override;
    procedure SetClipRect(const AValue: TRect); override;
    function GetClipping: boolean; override;
    procedure SetClipping(const AValue: boolean); override;

    public
    constructor Create; overload;
    constructor Create(AControl: TOpenGLControl); overload;
    constructor CreateSize(AWidth, AHeight: integer); overload;
    destructor Destroy; override;

    procedure BeginDraw; virtual;
    procedure EndDraw; virtual;

    procedure MoveTo(X, Y: integer);
    procedure LineTo(X, Y: integer);

    procedure Arc(ALeft, ATop, ARight, ABottom, Angle16Deg, Angle16DegLength: Integer); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Arc(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: Integer); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure ArcTo(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: Integer); virtual;
    procedure AngleArc(X, Y: Integer; Radius: Longword; StartAngle, SweepAngle: Single);
    procedure BrushCopy(ADestRect: TRect; ABitmap: TBitmap; ASourceRect: TRect;
      ATransparentColor: TColor); virtual;
    procedure Chord(x1, y1, x2, y2, Angle16Deg, Angle16DegLength: Integer); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Chord(x1, y1, x2, y2, SX, SY, EX, EY: Integer); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure CopyRect(const Dest: TRect; SrcCanvas: TCanvas; const Source: TRect); virtual; reintroduce;
    procedure Draw(X, Y: Integer; SrcGraphic: TGraphic); virtual; reintroduce;
    procedure DrawFocusRect(const ARect: TRect); virtual;
    procedure StretchDraw(const DestRect: TRect; SrcGraphic: TGraphic); virtual; reintroduce;
    procedure StretchDraw(x, y, w, h: integer; Source: TFPCustomImage); overload;
    procedure Ellipse(const ARect: TRect); overload; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Ellipse(x1, y1, x2, y2: integer); overload; virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure FillRect(const ARect: TRect); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure FillRect(X1, Y1, X2, Y2: Integer); overload; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure FloodFill(X, Y: Integer; FillColor: TColor; FillStyle: TFillStyle); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Frame3d(var ARect: TRect; const FrameWidth: integer; const Style: TGraphicsBevelCut); virtual;
    procedure Frame3D(var ARect: TRect; TopColor, BottomColor: TColor; const FrameWidth: integer); overload;
    procedure Frame(const ARect: TRect); overload; virtual;
    procedure Frame(X1, Y1, X2, Y2: Integer); overload;
    procedure FrameRect(const ARect: TRect); overload; virtual;
    procedure FrameRect(X1, Y1, X2, Y2: Integer); overload;
    function GetTextMetrics(out TM: TLCLTextMetric): boolean; virtual;
    procedure GradientFill(ARect: TRect; AStart, AStop: TColor; ADirection: TGradientDirection); {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure RadialPie(x1, y1, x2, y2, StartAngle16Deg, Angle16DegLength: Integer); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2, StartX, StartY, EndX, EndY: Integer); virtual;
    procedure PolyBezier(Points: PPoint; NumPts: Integer; Filled: boolean = False; Continuous: boolean = True); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure PolyBezier(const Points: array of TPoint; Filled: boolean = False; Continuous: boolean = True); overload; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Polygon(const Points: array of TPoint; Winding: Boolean; StartIndex: Integer = 0; NumPts: Integer = -1); overload;
    procedure Polygon(Points: PPoint; NumPts: Integer; Winding: boolean = False); overload; virtual;
    procedure Polygon(const Points: array of TPoint); overload; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Polyline(const Points: array of TPoint; StartIndex: Integer; NumPts: Integer = -1); overload;
    procedure Polyline(Points: PPoint; NumPts: Integer); overload; virtual;
    procedure Polyline(const Points: array of TPoint); overload; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Rectangle(X1, Y1, X2, Y2: integer); overload; virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure Rectangle(const R: TRect); overload; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure RoundRect(X1, Y1, X2, Y2, RX, RY: integer); overload; virtual;
    procedure RoundRect(const Rect: TRect; RX, RY: Integer); overload;
    procedure TextOut(X, Y: integer; const Text: string); virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    procedure TextRect(const ARect: TRect; X, Y: integer; const Text: string); overload;
    procedure TextRect(ARect: TRect; X, Y: integer; const Text: string; const Style: TTextStyle); overload; virtual;
    function TextExtent(const Text: string): TSize; virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    function TextHeight(const Text: string): Integer; virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    function TextWidth(const Text: string): Integer; virtual; {$IFDEF HasFPCanvas1}reintroduce;{$ENDIF}
    function TextFitInfo(const Text: string; MaxWidth: Integer): Integer; virtual;
    function HandleAllocated: boolean; virtual;
    function GetUpdatedHandle(ReqState: TCanvasState): HDC; virtual;

    procedure SetSize(AWidth, AHeight: integer);

    property Pen: TPen read FLazPen;
    property Brush: TBrush read FLazBrush;
    property Font: TFont read FLazFont;
    property Width: integer read GetWidth;
    property Height: integer read GetHeight;
    end;

function LinkProgram(AVS, AFS: GLuint): GLuint;
function CompileShader(AShaderType: GLenum; ASource: pchar): GLuint;

implementation

const
  VertexShaderSrc: pchar =
    '#version 330 core'#10 + 'layout(location = 0) in vec2 aPosition;'#10 +
    'layout(location = 1) in vec2 aLocal;'#10 +
    'layout(location = 2) in vec4 aData0;'#10 +
    'layout(location = 3) in vec4 aColor;'#10 +
    'layout(location = 4) in float aKind;'#10 + 'uniform mat4 uProjection;'#10 +
    'out vec2 vLocal;'#10 + 'out vec4 vData0;'#10 + 'out vec4 vColor;'#10 +
    'flat out int vKind;'#10 + 'void main() {'#10 +
    '  gl_Position = uProjection * vec4(aPosition, 0.0, 1.0);'#10 +
    '  vLocal = aLocal;'#10 + '  vData0 = aData0;'#10 + '  vColor = aColor;'#10 +
    '  vKind = int(aKind + 0.5);'#10 + '}';

  TexturedVertexShaderSrc: pchar =
    '#version 330 core'#10 + 'layout(location = 0) in vec2 aPosition;'#10 +
    'layout(location = 1) in vec2 aUV;'#10 +
    'layout(location = 2) in vec4 aColor;'#10 + 'uniform mat4 uProjection;'#10 +
    'out vec2 vUV;'#10 + 'out vec4 vColor;'#10 + 'void main() {'#10 +
    '  gl_Position = uProjection * vec4(aPosition, 0.0, 1.0);'#10 +
    '  vUV = aUV;'#10 + '  vColor = aColor;'#10 + '}';

  TexturedFragmentShaderSrc: pchar =
    '#version 330 core'#10 + 'in vec2 vUV;'#10 + 'in vec4 vColor;'#10 +
    'uniform sampler2D uTex;'#10 + 'out vec4 FragColor;'#10 +
    'void main() {'#10 + '  FragColor = texture(uTex, vUV) * vColor;'#10 + '}';

  FragmentShaderSrc: pchar =
    '#version 330 core'#10 + 'in vec2 vLocal;'#10 + 'in vec4 vData0;'#10 +
    'in vec4 vColor;'#10 + 'flat in int vKind;'#10 + 'out vec4 FragColor;'#10 +
    'float sdSegment(vec2 p, vec2 a, vec2 b) {'#10 + '  vec2 pa = p - a;'#10 +
    '  vec2 ba = b - a;'#10 +
    '  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);'#10 +
    '  return length(pa - ba * h);'#10 + '}'#10 + 'float sdBox(vec2 p, vec2 b) {'#10 +
    '  vec2 d = abs(p) - b;'#10 +
    '  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);'#10 +
    '}'#10 + 'float sdEllipse(vec2 p, vec2 r) {'#10 +
    '  vec2 pr = p / max(r, vec2(1e-4));'#10 + '  float k = length(pr);'#10 +
    '  float m = min(r.x, r.y);'#10 + '  return (k - 1.0) * m;'#10 +
    '}'#10 + 'float sdRoundedBox(vec2 p, vec2 b, float r) {'#10 +
    '  vec2 q = abs(p) - b + r;'#10 +
    '  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;'#10 +
    '}'#10 + 'void main() {'#10 + '  float aa = 1.0;'#10 +
    '  float alpha = 1.0;'#10 + '  float dist;'#10 + '  if (vKind == 0) {'#10 +
    // solid
    '    FragColor = vColor;'#10 + '    return;'#10 + '  }'#10 +
    '  if (vKind == 1) {'#10 +          // line
    '    vec2 a = vec2(0.0, 0.0);'#10 + '    vec2 b = vData0.xy;'#10 +
    '    float halfW = vData0.z;'#10 +
    '    dist = sdSegment(vLocal, a, b) - halfW;'#10 +
    '    alpha = 1.0 - smoothstep(-aa, aa, dist);'#10 + '  }'#10 +
    '  else if (vKind == 2) {'#10 +     // rect fill
    '    vec2 halfSize = vData0.xy;'#10 + '    dist = sdBox(vLocal, halfSize);'#10 +
    '    alpha = 1.0 - smoothstep(-aa, aa, dist);'#10 + '  }'#10 +
    '  else if (vKind == 3) {'#10 +     // rect stroke
    '    vec2 halfSize = vData0.xy;'#10 + '    float halfW = vData0.z;'#10 +
    '    float d = abs(sdBox(vLocal, halfSize)) - halfW;'#10 +
    '    alpha = 1.0 - smoothstep(-aa, aa, d);'#10 + '  }'#10 +
    '  else if (vKind == 4) {'#10 +     // ellipse fill
    '    vec2 radius = vData0.xy;'#10 + '    dist = sdEllipse(vLocal, radius);'#10 +
    '    alpha = 1.0 - smoothstep(-aa, aa, dist);'#10 + '  }'#10 +
    '  else if (vKind == 5) {'#10 +     // ellipse stroke
    '    vec2 radius = vData0.xy;'#10 + '    float halfW = vData0.z;'#10 +
    '    float d = abs(sdEllipse(vLocal, radius)) - halfW;'#10 +
    '    alpha = 1.0 - smoothstep(-aa, aa, d);'#10 + '  }'#10 +
    '  else if (vKind == 6) {'#10 +     // roundrect fill
    '    vec2 halfSize = vData0.xy;'#10 + '    float radius = vData0.z;'#10 +
    '    dist = sdRoundedBox(vLocal, halfSize, radius);'#10 +
    '    alpha = 1.0 - smoothstep(-aa, aa, dist);'#10 + '  }'#10 +
    '  else if (vKind == 7) {'#10 +     // roundrect stroke
    '    vec2 halfSize = vData0.xy;'#10 + '    float radius = vData0.z;'#10 +
    '    float halfW  = vData0.w;'#10 +
    '    float d = abs(sdRoundedBox(vLocal, halfSize, radius)) - halfW;'#10 +
    '    alpha = 1.0 - smoothstep(-aa, aa, d);'#10 + '  }'#10 +
    '  else {'#10 + '    alpha = 1.0;'#10 + '  }'#10 +
    '  if (alpha <= 0.001) discard;'#10 +
    '  FragColor = vec4(vColor.rgb, vColor.a * alpha);'#10 + '}';

function MakeVec2(const X, Y: single): TVec2; inline;
begin
  Result.X := X;
  Result.Y := Y;
end;

function MakeVec4(const X, Y, Z, W: single): TVec4; inline;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
  Result.W := W;
end;

function FPColorToVec4(const C: TFPColor): TVec4; inline;
begin
  Result.X := C.red / 65535.0;
  Result.Y := C.green / 65535.0;
  Result.Z := C.blue / 65535.0;
  Result.W := C.alpha / 65535.0;
end;

function Vec4ToFPColor(const V: TVec4): TFPColor; inline;
begin
  Result.red := Round(EnsureRange(V.X, 0, 1) * 65535);
  Result.green := Round(EnsureRange(V.Y, 0, 1) * 65535);
  Result.blue := Round(EnsureRange(V.Z, 0, 1) * 65535);
  Result.alpha := Round(EnsureRange(V.W, 0, 1) * 65535);
end;

function BevelColor(const AColor: TColor; Delta: integer): TColor;
var
  C: TColor;
  R, G, B: integer;
begin
  C := ColorToRGB(AColor);
  R := EnsureRange(Red(C) + Delta, 0, 255);
  G := EnsureRange(Green(C) + Delta, 0, 255);
  B := EnsureRange(Blue(C) + Delta, 0, 255);
  Result := RGBToColor(R, G, B);
end;

procedure BuildProjection(const AWidth, AHeight: integer; out Proj: array of single);
begin
  if Length(Proj) < 16 then Exit;
  FillChar(Proj[0], SizeOf(single) * 16, 0);
  Proj[0] := 2.0 / AWidth;
  Proj[5] := -2.0 / AHeight;
  Proj[10] := -1.0;
  Proj[12] := -1.0;
  Proj[13] := 1.0;
  Proj[15] := 1.0;
end;

function CreateTextureFromImage(const Img: TFPCustomImage): GLuint;
var
  X, Y: integer;
  Buf: array of byte;
  C: TFPColor;
  P: integer;
begin
  Result := 0;
  if (Img = nil) or (Img.Width <= 0) or (Img.Height <= 0) then Exit;

  SetLength(Buf, Img.Width * Img.Height * 4);
  P := 0;
  for Y := 0 to Img.Height - 1 do
    for X := 0 to Img.Width - 1 do
    begin
      C := Img.Colors[X, Y];
      Buf[P + 0] := C.red shr 8;
      Buf[P + 1] := C.green shr 8;
      Buf[P + 2] := C.blue shr 8;
      Buf[P + 3] := C.alpha shr 8;
      Inc(P, 4);
    end;

  glGenTextures(1, @Result);
  glBindTexture(GL_TEXTURE_2D, Result);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, Img.Width, Img.Height,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Buf[0]);
  glBindTexture(GL_TEXTURE_2D, 0);
end;

procedure DeleteTexture(var Tex: GLuint);
begin
  if Tex <> 0 then
  begin
    glDeleteTextures(1, @Tex);
    Tex := 0;
  end;
end;

function CubicBezierPoint(const P0, P1, P2, P3: TPoint; T: single): TPoint;
var
  U, TT, UU, UUU, TTT: single;
  X, Y: single;
begin
  U := 1 - T;
  TT := T * T;
  UU := U * U;
  UUU := UU * U;
  TTT := TT * T;

  X := UUU * P0.X + 3 * UU * T * P1.X + 3 * U * TT * P2.X + TTT * P3.X;

  Y := UUU * P0.Y + 3 * UU * T * P1.Y + 3 * U * TT * P2.Y + TTT * P3.Y;

  Result := Point(Round(X), Round(Y));
end;

function CreateTextureFromLazIntfImage(const Img: TLazIntfImage): GLuint;
var
  X, Y: integer;
  Buf: array of byte;
  C: TFPColor;
  P: integer;
begin
  Result := 0;
  if (Img = nil) or (Img.Width <= 0) or (Img.Height <= 0) then
    Exit;

  SetLength(Buf, Img.Width * Img.Height * 4);
  P := 0;
  for Y := 0 to Img.Height - 1 do
    for X := 0 to Img.Width - 1 do
    begin
      C := Img.Colors[X, Y];
      Buf[P + 0] := C.red shr 8;
      Buf[P + 1] := C.green shr 8;
      Buf[P + 2] := C.blue shr 8;
      Buf[P + 3] := C.alpha shr 8;
      Inc(P, 4);
    end;

  glGenTextures(1, @Result);
  glBindTexture(GL_TEXTURE_2D, Result);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, Img.Width, Img.Height,
    0, GL_RGBA, GL_UNSIGNED_BYTE, @Buf[0]);
  glBindTexture(GL_TEXTURE_2D, 0);
end;

function CompileShader(AShaderType: GLenum; ASource: pchar): GLuint;
var
  Shader: GLuint;
  Status: GLint;
  LogLen: GLint;
  LogBuf: array of char;
  Msg: string;
begin
  Shader := glCreateShader(AShaderType);
  glShaderSource(Shader, 1, @ASource, nil);
  glCompileShader(Shader);

  glGetShaderiv(Shader, GL_COMPILE_STATUS, @Status);
  if Status = 0 then
  begin
    glGetShaderiv(Shader, GL_INFO_LOG_LENGTH, @LogLen);
    if LogLen > 0 then
    begin
      SetLength(LogBuf, LogLen);
      glGetShaderInfoLog(Shader, LogLen, nil, @LogBuf[0]);
      Msg := PChar(@LogBuf[0]);
    end
    else
      Msg := 'unknown';
    raise Exception.Create('Shader compile error: ' + Msg);
  end;

  Result := Shader;
end;

function LinkProgram(AVS, AFS: GLuint): GLuint;
var
  Prog: GLuint;
  Status: GLint;
  LogLen: GLint;
  LogBuf: array of char;
  Msg: string;
begin
  Prog := glCreateProgram();
  glAttachShader(Prog, AVS);
  glAttachShader(Prog, AFS);
  glLinkProgram(Prog);

  glGetProgramiv(Prog, GL_LINK_STATUS, @Status);
  if Status = 0 then
  begin
    glGetProgramiv(Prog, GL_INFO_LOG_LENGTH, @LogLen);
    if LogLen > 0 then
    begin
      SetLength(LogBuf, LogLen);
      glGetProgramInfoLog(Prog, LogLen, nil, @LogBuf[0]);
      Msg := PChar(@LogBuf[0]);
    end
    else
      Msg := 'unknown';
    raise Exception.Create('Program link error: ' + Msg);
  end;

  Result := Prog;
end;

{ TGL2DCanvas }

constructor TGL2DCanvas.Create;
begin
  inherited Create;

  FWidth := 800;
  FHeight := 600;
  FClipRect := Rect(0, 0, FWidth, FHeight);
  FClipping := False;

  FLazPen := TPen(inherited Pen);
  FLazBrush := TBrush(inherited Brush);
  FLazFont := TFont(inherited Font);

  FLazPen.Color := clBlack;
  FLazPen.Width := 1;
  FLazPen.OnChange := @PenChanged;

  FLazBrush.Color := clWhite;
  FLazBrush.Style := bsSolid;
  FLazBrush.OnChange := @BrushChanged;

  FLazFont.Color := clBlack;
  FLazFont.Size := 12;
  FLazFont.OnChange := @FontChanged;

  SetLength(FVertices, 8192);
  FVertexCount := 0;

  FCurrentX := 0;
  FCurrentY := 0;

  FProgram := 0;
  FVAO := 0;
  FVBO := 0;
  FUniformProjection := -1;
  FUniformTexture := -1;
  FUniformHasTexture := -1;
  FGLInitialized := False;
  FDrawing := False;

  FTextureList := TFPList.Create;
  FTextureCache := TFPList.Create;
  FImagePointers := TFPList.Create;
  FTextCache := TTextCache.Create(TEXT_CACHE_MAX);
end;

constructor TGL2DCanvas.Create(AControl: TOpenGLControl);
begin
  Create;
  FControl := AControl;
  if Assigned(FControl) then
  begin
    FWidth := FControl.Width;
    FHeight := FControl.Height;
    FClipRect := Rect(0, 0, FWidth, FHeight);
  end;
end;

constructor TGL2DCanvas.CreateSize(AWidth, AHeight: integer);
begin
  Create;
  FWidth := AWidth;
  FHeight := AHeight;
  FClipRect := Rect(0, 0, FWidth, FHeight);
end;

destructor TGL2DCanvas.Destroy;
begin
  if FGLInitialized and Assigned(FControl) then
  begin
    try
      DestroyGLResources;
    except

    end;
  end;

  FreeAndNil(FTextureList);
  FreeAndNil(FTextureCache);
  FreeAndNil(FImagePointers);
  FreeAndNil(FTextCache);

  FLazFont := nil;
  FLazBrush := nil;
  FLazPen := nil;

  inherited Destroy;
end;


procedure TGL2DCanvas.PenChanged(Sender: TObject);
begin
  if FDrawing then
    Flush;
end;

procedure TGL2DCanvas.BrushChanged(Sender: TObject);
begin
  if FDrawing then
    Flush;
end;

procedure TGL2DCanvas.FontChanged(Sender: TObject);
begin
  if FDrawing then
    Flush;
end;

function TGL2DCanvas.DoCreateDefaultFont: TFPCustomFont;
begin
  Result := TFont.Create;
end;

function TGL2DCanvas.DoCreateDefaultPen: TFPCustomPen;
begin
  Result := TPen.Create;
end;

function TGL2DCanvas.DoCreateDefaultBrush: TFPCustomBrush;
begin
  Result := TBrush.Create;
end;

procedure TGL2DCanvas.SetColor(x, y: integer; const Value: TFPColor);
var
  OldClip: TRect;
  OldClipping: boolean;
  OldBrushStyle: TBrushStyle;
  OldBrushColor: TColor;
begin
  if not Assigned(FControl) then
    Exit;

  if not FDrawing then
    BeginDraw;
  EnsureGLReady;

  OldClip := FClipRect;
  OldClipping := FClipping;
  OldBrushStyle := FLazBrush.Style;
  OldBrushColor := FLazBrush.Color;

  try
    FClipRect := Rect(x, y, x + 1, y + 1);
    FClipping := True;
    ApplyScissor;

    FLazBrush.Style := bsSolid;
    FLazBrush.Color := FPColorToTColor(Value);
    AddSolidRect(x, y, x + 1, y + 1, FPColorToVec4(Value));
    Flush;
  finally
    FLazBrush.Style := OldBrushStyle;
    FLazBrush.Color := OldBrushColor;
    FClipRect := OldClip;
    FClipping := OldClipping;
    ApplyScissor;
  end;
end;

function TGL2DCanvas.GetColor(x, y: integer): TFPColor;
var
  Pixel: array[0..3] of byte;
begin
  Result := colTransparent;

  if not Assigned(FControl) then
    Exit;

  FControl.MakeCurrent;
  EnsureGLReady;
  Flush;

  if (x < 0) or (y < 0) or (x >= FWidth) or (y >= FHeight) then
    Exit;

  glReadPixels(x, FHeight - 1 - y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, @Pixel[0]);

  Result.red := Pixel[0] * 257;
  Result.green := Pixel[1] * 257;
  Result.blue := Pixel[2] * 257;
  Result.alpha := Pixel[3] * 257;
end;

procedure TGL2DCanvas.SetWidth(AValue: integer);
begin
  FWidth := AValue;
  FClipRect := Rect(0, 0, FWidth, FHeight);
end;

function TGL2DCanvas.GetWidth: integer;
begin
  Result := FWidth;
end;

procedure TGL2DCanvas.SetHeight(AValue: integer);
begin
  FHeight := AValue;
  FClipRect := Rect(0, 0, FWidth, FHeight);
end;

function TGL2DCanvas.GetHeight: integer;
begin
  Result := FHeight;
end;

function TGL2DCanvas.NormalizeRect(const R: TRect): TRect;
begin
  Result.Left := Min(R.Left, R.Right);
  Result.Right := Max(R.Left, R.Right);
  Result.Top := Min(R.Top, R.Bottom);
  Result.Bottom := Max(R.Top, R.Bottom);
end;

function TGL2DCanvas.ColorToVec4(const AColor: TColor; AAlpha: single): TVec4;
var
  C: TColor;
begin
  C := ColorToRGB(AColor);
  Result.X := Red(C) / 255.0;
  Result.Y := Green(C) / 255.0;
  Result.Z := Blue(C) / 255.0;
  Result.W := AAlpha;
end;

function TGL2DCanvas.AdjustColor(const AColor: TColor; AFactor: integer): TColor;
var
  R, G, B: integer;
  C: TColor;
begin
  C := ColorToRGB(AColor);
  R := Red(C) + AFactor;
  G := Green(C) + AFactor;
  B := Blue(C) + AFactor;
  // Clamp
  if R < 0 then R := 0;
  if R > 255 then R := 255;
  if G < 0 then G := 0;
  if G > 255 then G := 255;
  if B < 0 then B := 0;
  if B > 255 then B := 255;
  Result := RGBToColor(R, G, B);
end;

procedure TGL2DCanvas.EnsureGLReady;
begin
  if FGLInitialized then
    Exit;

  if not Assigned(FControl) then
    raise Exception.Create('TGL2DCanvas requires TOpenGLControl');

  FControl.MakeCurrent;

  if not InitOpenGL then
    raise Exception.Create('InitOpenGL failed');

  ReadExtensions;
  ReadImplementationProperties;
  ReadOpenGLCore;

  LoadShaders;
  CreateBuffers;
  LoadTextureShaders;
  CreateTextureBuffers;

  FGLInitialized := True;
end;

procedure TGL2DCanvas.LoadShaders;
var
  VS, FS: GLuint;
begin
  VS := CompileShader(GL_VERTEX_SHADER, VertexShaderSrc);
  try
    FS := CompileShader(GL_FRAGMENT_SHADER, FragmentShaderSrc);
    try
      FProgram := LinkProgram(VS, FS);
    finally
      glDeleteShader(FS);
    end;
  finally
    glDeleteShader(VS);
  end;

  FUniformProjection := glGetUniformLocation(FProgram, 'uProjection');
  if FUniformProjection < 0 then
    raise Exception.Create('Uniform uProjection not found');

  FUniformTexture := glGetUniformLocation(FProgram, 'uTexture');
  FUniformHasTexture := glGetUniformLocation(FProgram, 'uHasTexture');
end;

procedure TGL2DCanvas.CreateBuffers;
var
  Stride: GLsizei;
begin
  glGenVertexArrays(1, @FVAO);
  glGenBuffers(1, @FVBO);

  glBindVertexArray(FVAO);
  glBindBuffer(GL_ARRAY_BUFFER, FVBO);
  glBufferData(GL_ARRAY_BUFFER, 0, nil, GL_DYNAMIC_DRAW);

  Stride := SizeOf(TAAColorVertex);

  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, Stride, Pointer(PtrUInt(0)));
  glEnableVertexAttribArray(0);

  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, Stride,
    Pointer(PtrUInt(SizeOf(TVec2))));
  glEnableVertexAttribArray(1);

  glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, Stride,
    Pointer(PtrUInt(SizeOf(TVec2) * 2)));
  glEnableVertexAttribArray(2);

  glVertexAttribPointer(3, 4, GL_FLOAT, GL_FALSE, Stride,
    Pointer(PtrUInt(SizeOf(TVec2) * 2 + SizeOf(TVec4))));
  glEnableVertexAttribArray(3);

  glVertexAttribPointer(4, 1, GL_FLOAT, GL_FALSE, Stride,
    Pointer(PtrUInt(SizeOf(TVec2) * 2 + SizeOf(TVec4) * 2)));
  glEnableVertexAttribArray(4);

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
end;

procedure TGL2DCanvas.DestroyGLResources;
var
  I: Integer;
  Pair: specialize TPair<string, TTextCacheEntry>;
begin
  if FTextureVAO <> 0 then
  begin
    glDeleteVertexArrays(1, @FTextureVAO);
    FTextureVAO := 0;
  end;
  if FTextureVBO <> 0 then
  begin
    glDeleteBuffers(1, @FTextureVBO);
    FTextureVBO := 0;
  end;
  if FTextureProgram <> 0 then
  begin
    glDeleteProgram(FTextureProgram);
    FTextureProgram := 0;
  end;

  if FVAO <> 0 then
  begin
    glDeleteVertexArrays(1, @FVAO);
    FVAO := 0;
  end;
  if FVBO <> 0 then
  begin
    glDeleteBuffers(1, @FVBO);
    FVBO := 0;
  end;
  if FProgram <> 0 then
  begin
    glDeleteProgram(FProgram);
    FProgram := 0;
  end;

  for I := 0 to FTextureList.Count - 1 do
    if PGLuint(FTextureList[I]) <> nil then
      glDeleteTextures(1, PGLuint(FTextureList[I]));

  for Pair in FTextCache do
    glDeleteTextures(1, @Pair.Value.TexID);

  FTextCache.Clear;

  FTextureList.Clear;
  FTextureCache.Clear;
  FImagePointers.Clear;

  FGLInitialized := False;
end;

function TGL2DCanvas.MakeTextCacheKey(const AText: string): string;
begin
  Result := Format('%s|%s|%d|%d',
    [AText,
     FLazFont.Name,
     FLazFont.Size,
     FLazFont.Color]);
end;


procedure TGL2DCanvas.SetProjection;
var
  Proj: array[0..15] of single;
begin
  FillChar(Proj, SizeOf(Proj), 0);

  Proj[0] := 2.0 / FWidth;
  Proj[5] := -2.0 / FHeight;
  Proj[10] := -1.0;
  Proj[12] := -1.0;
  Proj[13] := 1.0;
  Proj[15] := 1.0;

  glUniformMatrix4fv(FUniformProjection, 1, GL_FALSE, @Proj[0]);
end;

procedure TGL2DCanvas.ApplyScissor;
var
  R: TRect;
begin
  if FClipping then
  begin
    R := NormalizeRect(FClipRect);
    glEnable(GL_SCISSOR_TEST);
    glScissor(
      R.Left,
      FHeight - R.Bottom,
      Max(0, R.Right - R.Left),
      Max(0, R.Bottom - R.Top)
      );
  end
  else
    glDisable(GL_SCISSOR_TEST);
end;

procedure TGL2DCanvas.EnsureVertexCapacity(AExtra: integer);
var
  Required, NewCap: integer;
begin
  Required := FVertexCount + AExtra;
  if Required <= Length(FVertices) then Exit;

  NewCap := Length(FVertices);
  if NewCap < 1024 then NewCap := 1024;
  while NewCap < Required do
    NewCap := NewCap * 2;

  SetLength(FVertices, NewCap);
end;

procedure TGL2DCanvas.Flush;
var
  DataSize: integer;
begin
  if FVertexCount <= 0 then Exit;

  DataSize := SizeOf(TAAColorVertex) * FVertexCount;

  glUseProgram(FProgram);
  SetProjection;

  glBindVertexArray(FVAO);
  glBindBuffer(GL_ARRAY_BUFFER, FVBO);

  if DataSize > FVBOCapacity then
  begin
    FVBOCapacity := DataSize * 2;
    glBufferData(GL_ARRAY_BUFFER, FVBOCapacity, nil, GL_DYNAMIC_DRAW);
  end;

  glBufferSubData(GL_ARRAY_BUFFER, 0, DataSize, @FVertices[0]);

  glDrawArrays(GL_TRIANGLES, 0, FVertexCount);

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);

  FVertexCount := 0;
end;

procedure TGL2DCanvas.AddVertex(const APos, ALocal: TVec2;
  const AData0, AColor: TVec4; AKind: TPrimitiveKind);
begin
  if FVertexCount + 1 > Length(FVertices) then
    SetLength(FVertices, Length(FVertices) + 8192);

  FVertices[FVertexCount].Position := APos;
  FVertices[FVertexCount].Local := ALocal;
  FVertices[FVertexCount].Data0 := AData0;
  FVertices[FVertexCount].Color := AColor;
  FVertices[FVertexCount].Kind := Ord(AKind);
  Inc(FVertexCount);
end;

procedure TGL2DCanvas.AddTriangle(const A, B, C: TAAColorVertex);
begin
  EnsureVertexCapacity(3);
  FVertices[FVertexCount]     := A;
  FVertices[FVertexCount + 1] := B;
  FVertices[FVertexCount + 2] := C;
  Inc(FVertexCount, 3);
end;

procedure TGL2DCanvas.AddQuad(const A, B, C, D: TAAColorVertex);
begin
  AddTriangle(A, B, C);
  AddTriangle(A, C, D);
end;

procedure TGL2DCanvas.AddSolidRect(const X1, Y1, X2, Y2: single; const AColor: TVec4);
var
  V0, V1, V2, V3: TAAColorVertex;
  P, L: TVec2;
  D: TVec4;
begin
  D.X := 0;
  D.Y := 0;
  D.Z := 0;
  D.W := 0;
  L.X := 0;
  L.Y := 0;

  P.X := X1;
  P.Y := Y1;
  V0.Position := P;
  V0.Local := L;
  V0.Data0 := D;
  V0.Color := AColor;
  V0.Kind := Ord(pkSolid);
  P.X := X2;
  P.Y := Y1;
  V1.Position := P;
  V1.Local := L;
  V1.Data0 := D;
  V1.Color := AColor;
  V1.Kind := Ord(pkSolid);
  P.X := X2;
  P.Y := Y2;
  V2.Position := P;
  V2.Local := L;
  V2.Data0 := D;
  V2.Color := AColor;
  V2.Kind := Ord(pkSolid);
  P.X := X1;
  P.Y := Y2;
  V3.Position := P;
  V3.Local := L;
  V3.Data0 := D;
  V3.Color := AColor;
  V3.Kind := Ord(pkSolid);

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.AddGradientRect(const X1, Y1, X2, Y2: single;
  const C1, C2: TVec4; ADirection: TGradientDirection);
var
  V0, V1, V2, V3: TAAColorVertex;
  P, L: TVec2;
  D: TVec4;
begin
  D.X := 0;
  D.Y := 0;
  D.Z := 0;
  D.W := 0;
  L.X := 0;
  L.Y := 0;

  // Vertices: BL, BR, TR, TL (Counter Clockwise)
  // 0: BL (X1, Y2), 1: BR (X2, Y2), 2: TR (X2, Y1), 3: TL (X1, Y1)

  if ADirection = gdVertical then
  begin
    // Top C1, Bottom C2
    P.X := X1;
    P.Y := Y2;
    V0.Position := P;
    V0.Local := L;
    V0.Data0 := D;
    V0.Color := C2;
    V0.Kind := Ord(pkSolid);
    P.X := X2;
    P.Y := Y2;
    V1.Position := P;
    V1.Local := L;
    V1.Data0 := D;
    V1.Color := C2;
    V1.Kind := Ord(pkSolid);
    P.X := X2;
    P.Y := Y1;
    V2.Position := P;
    V2.Local := L;
    V2.Data0 := D;
    V2.Color := C1;
    V2.Kind := Ord(pkSolid);
    P.X := X1;
    P.Y := Y1;
    V3.Position := P;
    V3.Local := L;
    V3.Data0 := D;
    V3.Color := C1;
    V3.Kind := Ord(pkSolid);
  end
  else // gdHorizontal
  begin
    // Left C1, Right C2
    P.X := X1;
    P.Y := Y2;
    V0.Position := P;
    V0.Local := L;
    V0.Data0 := D;
    V0.Color := C1;
    V0.Kind := Ord(pkSolid);
    P.X := X2;
    P.Y := Y2;
    V1.Position := P;
    V1.Local := L;
    V1.Data0 := D;
    V1.Color := C2;
    V1.Kind := Ord(pkSolid);
    P.X := X2;
    P.Y := Y1;
    V2.Position := P;
    V2.Local := L;
    V2.Data0 := D;
    V2.Color := C2;
    V2.Kind := Ord(pkSolid);
    P.X := X1;
    P.Y := Y1;
    V3.Position := P;
    V3.Local := L;
    V3.Data0 := D;
    V3.Color := C1;
    V3.Kind := Ord(pkSolid);
  end;

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.AddAALine(const X1, Y1, X2, Y2: single;
  const AWidth: single; const AColor: TVec4);
var
  DX, DY, L: single;
  TX, TY: single;
  NX, NY: single;
  Pad, HalfW: single;
  P0, P1, P2, P3: TVec2;
  L0, L1, L2, L3: TVec2;
  D: TVec4;
  V0, V1, V2, V3: TAAColorVertex;
begin
  DX := X2 - X1;
  DY := Y2 - Y1;
  L := Hypot(DX, DY);
  if L < 0.0001 then
    Exit;

  TX := DX / L;
  TY := DY / L;
  NX := -TY;
  NY := TX;

  HalfW := Max(0.5, AWidth * 0.5);
  Pad := HalfW + 1.5;

  P0.X := X1 - TX * Pad - NX * Pad;
  P0.Y := Y1 - TY * Pad - NY * Pad;
  P1.X := X1 - TX * Pad + NX * Pad;
  P1.Y := Y1 - TY * Pad + NY * Pad;
  P2.X := X2 + TX * Pad + NX * Pad;
  P2.Y := Y2 + TY * Pad + NY * Pad;
  P3.X := X2 + TX * Pad - NX * Pad;
  P3.Y := Y2 + TY * Pad - NY * Pad;

  L0.X := -Pad;
  L0.Y := -Pad;
  L1.X := -Pad;
  L1.Y := Pad;
  L2.X := L + Pad;
  L2.Y := Pad;
  L3.X := L + Pad;
  L3.Y := -Pad;

  D.X := L;
  D.Y := 0;
  D.Z := HalfW;
  D.W := 0;

  V0.Position := P0;
  V0.Local := L0;
  V0.Data0 := D;
  V0.Color := AColor;
  V0.Kind := Ord(pkLine);
  V1.Position := P1;
  V1.Local := L1;
  V1.Data0 := D;
  V1.Color := AColor;
  V1.Kind := Ord(pkLine);
  V2.Position := P2;
  V2.Local := L2;
  V2.Data0 := D;
  V2.Color := AColor;
  V2.Kind := Ord(pkLine);
  V3.Position := P3;
  V3.Local := L3;
  V3.Data0 := D;
  V3.Color := AColor;
  V3.Kind := Ord(pkLine);

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.AddAARectFill(const X1, Y1, X2, Y2: single; const AColor: TVec4);
var
  CX, CY, HX, HY, Pad: single;
  P0, P1, P2, P3: TVec2;
  L0, L1, L2, L3: TVec2;
  D: TVec4;
  V0, V1, V2, V3: TAAColorVertex;
begin
  CX := (X1 + X2) * 0.5;
  CY := (Y1 + Y2) * 0.5;
  HX := Abs(X2 - X1) * 0.5;
  HY := Abs(Y2 - Y1) * 0.5;
  Pad := 1.5;

  P0.X := CX - HX - Pad;
  P0.Y := CY - HY - Pad;
  P1.X := CX + HX + Pad;
  P1.Y := CY - HY - Pad;
  P2.X := CX + HX + Pad;
  P2.Y := CY + HY + Pad;
  P3.X := CX - HX - Pad;
  P3.Y := CY + HY + Pad;

  L0.X := -HX - Pad;
  L0.Y := -HY - Pad;
  L1.X := HX + Pad;
  L1.Y := -HY - Pad;
  L2.X := HX + Pad;
  L2.Y := HY + Pad;
  L3.X := -HX - Pad;
  L3.Y := HY + Pad;

  D.X := HX;
  D.Y := HY;
  D.Z := 0;
  D.W := 0;

  V0.Position := P0;
  V0.Local := L0;
  V0.Data0 := D;
  V0.Color := AColor;
  V0.Kind := Ord(pkRectFill);
  V1.Position := P1;
  V1.Local := L1;
  V1.Data0 := D;
  V1.Color := AColor;
  V1.Kind := Ord(pkRectFill);
  V2.Position := P2;
  V2.Local := L2;
  V2.Data0 := D;
  V2.Color := AColor;
  V2.Kind := Ord(pkRectFill);
  V3.Position := P3;
  V3.Local := L3;
  V3.Data0 := D;
  V3.Color := AColor;
  V3.Kind := Ord(pkRectFill);

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.AddAARectStroke(const X1, Y1, X2, Y2, AStrokeWidth: single;
  const AColor: TVec4);
var
  CX, CY, HX, HY, Pad, HalfW: single;
  P0, P1, P2, P3: TVec2;
  L0, L1, L2, L3: TVec2;
  D: TVec4;
  V0, V1, V2, V3: TAAColorVertex;
begin
  CX := (X1 + X2) * 0.5;
  CY := (Y1 + Y2) * 0.5;
  HX := Abs(X2 - X1) * 0.5;
  HY := Abs(Y2 - Y1) * 0.5;
  HalfW := Max(0.5, AStrokeWidth * 0.5);
  Pad := HalfW + 1.5;

  P0.X := CX - HX - Pad;
  P0.Y := CY - HY - Pad;
  P1.X := CX + HX + Pad;
  P1.Y := CY - HY - Pad;
  P2.X := CX + HX + Pad;
  P2.Y := CY + HY + Pad;
  P3.X := CX - HX - Pad;
  P3.Y := CY + HY + Pad;

  L0.X := -HX - Pad;
  L0.Y := -HY - Pad;
  L1.X := HX + Pad;
  L1.Y := -HY - Pad;
  L2.X := HX + Pad;
  L2.Y := HY + Pad;
  L3.X := -HX - Pad;
  L3.Y := HY + Pad;

  D.X := HX;
  D.Y := HY;
  D.Z := HalfW;
  D.W := 0;

  V0.Position := P0;
  V0.Local := L0;
  V0.Data0 := D;
  V0.Color := AColor;
  V0.Kind := Ord(pkRectStroke);
  V1.Position := P1;
  V1.Local := L1;
  V1.Data0 := D;
  V1.Color := AColor;
  V1.Kind := Ord(pkRectStroke);
  V2.Position := P2;
  V2.Local := L2;
  V2.Data0 := D;
  V2.Color := AColor;
  V2.Kind := Ord(pkRectStroke);
  V3.Position := P3;
  V3.Local := L3;
  V3.Data0 := D;
  V3.Color := AColor;
  V3.Kind := Ord(pkRectStroke);

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.AddAAEllipseFill(const X1, Y1, X2, Y2: single;
  const AColor: TVec4);
var
  CX, CY, RX, RY, Pad: single;
  P0, P1, P2, P3: TVec2;
  L0, L1, L2, L3: TVec2;
  D: TVec4;
  V0, V1, V2, V3: TAAColorVertex;
begin
  CX := (X1 + X2) * 0.5;
  CY := (Y1 + Y2) * 0.5;
  RX := Abs(X2 - X1) * 0.5;
  RY := Abs(Y2 - Y1) * 0.5;
  Pad := 1.5;

  P0.X := CX - RX - Pad;
  P0.Y := CY - RY - Pad;
  P1.X := CX + RX + Pad;
  P1.Y := CY - RY - Pad;
  P2.X := CX + RX + Pad;
  P2.Y := CY + RY + Pad;
  P3.X := CX - RX - Pad;
  P3.Y := CY + RY + Pad;

  L0.X := -RX - Pad;
  L0.Y := -RY - Pad;
  L1.X := RX + Pad;
  L1.Y := -RY - Pad;
  L2.X := RX + Pad;
  L2.Y := RY + Pad;
  L3.X := -RX - Pad;
  L3.Y := RY + Pad;

  D.X := RX;
  D.Y := RY;
  D.Z := 0;
  D.W := 0;

  V0.Position := P0;
  V0.Local := L0;
  V0.Data0 := D;
  V0.Color := AColor;
  V0.Kind := Ord(pkEllipseFill);
  V1.Position := P1;
  V1.Local := L1;
  V1.Data0 := D;
  V1.Color := AColor;
  V1.Kind := Ord(pkEllipseFill);
  V2.Position := P2;
  V2.Local := L2;
  V2.Data0 := D;
  V2.Color := AColor;
  V2.Kind := Ord(pkEllipseFill);
  V3.Position := P3;
  V3.Local := L3;
  V3.Data0 := D;
  V3.Color := AColor;
  V3.Kind := Ord(pkEllipseFill);

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.AddAAEllipseStroke(const X1, Y1, X2, Y2, AStrokeWidth: single;
  const AColor: TVec4);
var
  CX, CY, RX, RY, Pad, HalfW: single;
  P0, P1, P2, P3: TVec2;
  L0, L1, L2, L3: TVec2;
  D: TVec4;
  V0, V1, V2, V3: TAAColorVertex;
begin
  CX := (X1 + X2) * 0.5;
  CY := (Y1 + Y2) * 0.5;
  RX := Abs(X2 - X1) * 0.5;
  RY := Abs(Y2 - Y1) * 0.5;
  HalfW := Max(0.5, AStrokeWidth * 0.5);
  Pad := HalfW + 1.5;

  P0.X := CX - RX - Pad;
  P0.Y := CY - RY - Pad;
  P1.X := CX + RX + Pad;
  P1.Y := CY - RY - Pad;
  P2.X := CX + RX + Pad;
  P2.Y := CY + RY + Pad;
  P3.X := CX - RX - Pad;
  P3.Y := CY + RY + Pad;

  L0.X := -RX - Pad;
  L0.Y := -RY - Pad;
  L1.X := RX + Pad;
  L1.Y := -RY - Pad;
  L2.X := RX + Pad;
  L2.Y := RY + Pad;
  L3.X := -RX - Pad;
  L3.Y := RY + Pad;

  D.X := RX;
  D.Y := RY;
  D.Z := HalfW;
  D.W := 0;

  V0.Position := P0;
  V0.Local := L0;
  V0.Data0 := D;
  V0.Color := AColor;
  V0.Kind := Ord(pkEllipseStroke);
  V1.Position := P1;
  V1.Local := L1;
  V1.Data0 := D;
  V1.Color := AColor;
  V1.Kind := Ord(pkEllipseStroke);
  V2.Position := P2;
  V2.Local := L2;
  V2.Data0 := D;
  V2.Color := AColor;
  V2.Kind := Ord(pkEllipseStroke);
  V3.Position := P3;
  V3.Local := L3;
  V3.Data0 := D;
  V3.Color := AColor;
  V3.Kind := Ord(pkEllipseStroke);

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.AddAARoundRectFill(
  const X1, Y1, X2, Y2, ARadiusX, ARadiusY: single; const AColor: TVec4);
var
  CX, CY, HX, HY, Pad, RX, RY: single;
  P0, P1, P2, P3: TVec2;
  L0, L1, L2, L3: TVec2;
  D: TVec4;
  V0, V1, V2, V3: TAAColorVertex;
begin
  CX := (X1 + X2) * 0.5;
  CY := (Y1 + Y2) * 0.5;
  HX := Abs(X2 - X1) * 0.5;
  HY := Abs(Y2 - Y1) * 0.5;

  // Clamp radius
  RX := Min(ARadiusX, HX);
  RY := Min(ARadiusY, HY);

  Pad := 1.5;

  P0.X := CX - HX - Pad;
  P0.Y := CY - HY - Pad;
  P1.X := CX + HX + Pad;
  P1.Y := CY - HY - Pad;
  P2.X := CX + HX + Pad;
  P2.Y := CY + HY + Pad;
  P3.X := CX - HX - Pad;
  P3.Y := CY + HY + Pad;

  L0.X := -HX - Pad;
  L0.Y := -HY - Pad;
  L1.X := HX + Pad;
  L1.Y := -HY - Pad;
  L2.X := HX + Pad;
  L2.Y := HY + Pad;
  L3.X := -HX - Pad;
  L3.Y := HY + Pad;

  // Pass radius in Z
  D.X := HX;
  D.Y := HY;
  D.Z := RX;
  D.W := 0;

  V0.Position := P0;
  V0.Local := L0;
  V0.Data0 := D;
  V0.Color := AColor;
  V0.Kind := Ord(pkRoundRectFill);
  V1.Position := P1;
  V1.Local := L1;
  V1.Data0 := D;
  V1.Color := AColor;
  V1.Kind := Ord(pkRoundRectFill);
  V2.Position := P2;
  V2.Local := L2;
  V2.Data0 := D;
  V2.Color := AColor;
  V2.Kind := Ord(pkRoundRectFill);
  V3.Position := P3;
  V3.Local := L3;
  V3.Data0 := D;
  V3.Color := AColor;
  V3.Kind := Ord(pkRoundRectFill);

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.AddAARoundRectStroke(
  const X1, Y1, X2, Y2, ARadiusX, ARadiusY, AStrokeWidth: single; const AColor: TVec4);
var
  CX, CY, HX, HY, Pad, HalfW, RX, RY: single;
  P0, P1, P2, P3: TVec2;
  L0, L1, L2, L3: TVec2;
  D: TVec4;
  V0, V1, V2, V3: TAAColorVertex;
begin
  CX := (X1 + X2) * 0.5;
  CY := (Y1 + Y2) * 0.5;
  HX := Abs(X2 - X1) * 0.5;
  HY := Abs(Y2 - Y1) * 0.5;
  HalfW := Max(0.5, AStrokeWidth * 0.5);

  // Clamp radius
  RX := Min(ARadiusX, HX);
  RY := Min(ARadiusY, HY);

  Pad := HalfW + 1.5;

  P0.X := CX - HX - Pad;
  P0.Y := CY - HY - Pad;
  P1.X := CX + HX + Pad;
  P1.Y := CY - HY - Pad;
  P2.X := CX + HX + Pad;
  P2.Y := CY + HY + Pad;
  P3.X := CX - HX - Pad;
  P3.Y := CY + HY + Pad;

  L0.X := -HX - Pad;
  L0.Y := -HY - Pad;
  L1.X := HX + Pad;
  L1.Y := -HY - Pad;
  L2.X := HX + Pad;
  L2.Y := HY + Pad;
  L3.X := -HX - Pad;
  L3.Y := HY + Pad;

  // Z = Radius, W = HalfWidth
  D.X := HX;
  D.Y := HY;
  D.Z := RX;
  D.W := HalfW;

  V0.Position := P0;
  V0.Local := L0;
  V0.Data0 := D;
  V0.Color := AColor;
  V0.Kind := Ord(pkRoundRectStroke);
  V1.Position := P1;
  V1.Local := L1;
  V1.Data0 := D;
  V1.Color := AColor;
  V1.Kind := Ord(pkRoundRectStroke);
  V2.Position := P2;
  V2.Local := L2;
  V2.Data0 := D;
  V2.Color := AColor;
  V2.Kind := Ord(pkRoundRectStroke);
  V3.Position := P3;
  V3.Local := L3;
  V3.Data0 := D;
  V3.Color := AColor;
  V3.Kind := Ord(pkRoundRectStroke);

  AddQuad(V0, V1, V2, V3);
end;

function TGL2DCanvas.GetTexture(AImage: TFPCustomImage): GLuint;
var
  i: Integer;
begin
  Result := 0;
  if AImage = nil then Exit;

  for i := 0 to FImagePointers.Count - 1 do
    if FImagePointers[i] = Pointer(AImage) then
    begin
      Result := GLuint(PtrUInt(FTextureCache[i]));
      Exit;
    end;

  EnsureGLReady;
  Result := CreateTextureFromImage(AImage);
  if Result <> 0 then
  begin
    FTextureList.Add(TObject(PtrUInt(Result)));
    FTextureCache.Add(TObject(PtrUInt(Result)));
    FImagePointers.Add(Pointer(AImage));
  end;
end;

procedure TGL2DCanvas.LoadTextureShaders;
var
  VS, FS: GLuint;
begin
  VS := CompileShader(GL_VERTEX_SHADER, TexturedVertexShaderSrc);
  try
    FS := CompileShader(GL_FRAGMENT_SHADER, TexturedFragmentShaderSrc);
    try
      FTextureProgram := LinkProgram(VS, FS);
    finally
      glDeleteShader(FS);
    end;
  finally
    glDeleteShader(VS);
  end;

  FTextureUniformProjection := glGetUniformLocation(FTextureProgram, 'uProjection');
  FTextureUniformTex := glGetUniformLocation(FTextureProgram, 'uTex');
end;

procedure TGL2DCanvas.CreateTextureBuffers;
var
  Stride: GLsizei;
begin
  glGenVertexArrays(1, @FTextureVAO);
  glGenBuffers(1, @FTextureVBO);

  glBindVertexArray(FTextureVAO);
  glBindBuffer(GL_ARRAY_BUFFER, FTextureVBO);
  glBufferData(GL_ARRAY_BUFFER, SizeOf(TTexturedVertex) * 6, nil, GL_DYNAMIC_DRAW);

  Stride := SizeOf(TTexturedVertex);

  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, Stride, Pointer(PtrUInt(0)));
  glEnableVertexAttribArray(0);

  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, Stride,
    Pointer(PtrUInt(SizeOf(TVec2))));
  glEnableVertexAttribArray(1);

  glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, Stride,
    Pointer(PtrUInt(SizeOf(TVec2) * 2)));
  glEnableVertexAttribArray(2);

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
end;

procedure TGL2DCanvas.DrawTexturedQuad(Tex: GLuint; X, Y, W, H: integer; U1,
  V1, U2, V2: single; const AColor: TVec4);
var
  V: array[0..5] of TTexturedVertex;
  Proj: array[0..15] of Single;
begin
  if Tex = 0 then Exit;

  BuildProjection(FWidth, FHeight, Proj);

  V[0].Pos := MakeVec2(X, Y);
  V[0].UV := MakeVec2(U1, V1);
  V[0].Col := AColor;

  V[1].Pos := MakeVec2(X + W, Y);
  V[1].UV := MakeVec2(U2, V1);
  V[1].Col := AColor;

  V[2].Pos := MakeVec2(X + W, Y + H);
  V[2].UV := MakeVec2(U2, V2);
  V[2].Col := AColor;

  V[3].Pos := MakeVec2(X, Y);
  V[3].UV := MakeVec2(U1, V1);
  V[3].Col := AColor;

  V[4].Pos := MakeVec2(X + W, Y + H);
  V[4].UV := MakeVec2(U2, V2);
  V[4].Col := AColor;

  V[5].Pos := MakeVec2(X, Y + H);
  V[5].UV := MakeVec2(U1, V2);
  V[5].Col := AColor;

  glUseProgram(FTextureProgram);
  glUniformMatrix4fv(FTextureUniformProjection, 1, GL_FALSE, @Proj[0]);
  glUniform1i(FTextureUniformTex, 0);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, Tex);

  glBindVertexArray(FTextureVAO);
  glBindBuffer(GL_ARRAY_BUFFER, FTextureVBO);
  glBufferSubData(GL_ARRAY_BUFFER, 0, SizeOf(V), @V[0]);

  glDrawArrays(GL_TRIANGLES, 0, 6);

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
  glBindTexture(GL_TEXTURE_2D, 0);
end;

procedure TGL2DCanvas.AddTexturedQuad(const X1, Y1, X2, Y2: single;
  const U1, V1, U2, V2: single; ATexID: GLuint; const AColor: TVec4);
var
  Proj: array[0..15] of single;
  W, H: integer;
begin
  if ATexID = 0 then
    Exit;

  Flush;
  EnsureGLReady;

  W := Round(X2 - X1);
  H := Round(Y2 - Y1);
  if (W <= 0) or (H <= 0) then
    Exit;

  BuildProjection(FWidth, FHeight, Proj);
  DrawTexturedQuad(ATexID, Round(X1), Round(Y1), W, H, U1, V1, U2, V2, AColor);
end;

procedure TGL2DCanvas.BeginDraw;
begin
  if not Assigned(FControl) then
    Exit;

  FControl.MakeCurrent;
  EnsureGLReady;

  FWidth := FControl.Width;
  FHeight := FControl.Height;

  glViewport(0, 0, FWidth, FHeight);

  glClearColor(0.95, 0.95, 0.95, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  ApplyScissor;

  FVertexCount := 0;
  FDrawing := True;
end;

procedure TGL2DCanvas.EndDraw;
begin
  if not FDrawing then
    Exit;

  Flush;
  glUseProgram(0);

  FDrawing := False;

  if Assigned(FControl) then
    FControl.SwapBuffers;
end;

procedure TGL2DCanvas.DoLine(x1, y1, x2, y2: integer);
begin
  if FLazPen.Style = psClear then
    Exit;

  AddAALine(x1, y1, x2, y2, Max(1, FLazPen.Width), ColorToVec4(FLazPen.Color));
end;

procedure TGL2DCanvas.DoMoveTo(X, Y: integer);
begin
  FCurrentX := X;
  FCurrentY := Y;
end;

procedure TGL2DCanvas.DoPolyline(const points: array of TPoint);
var
  i: integer;
begin
  if (Length(points) < 2) or (FLazPen.Style = psClear) then
    Exit;

  for i := 0 to High(points) - 1 do
    AddAALine(points[i].X, points[i].Y,
      points[i + 1].X, points[i + 1].Y,
      Max(1, FLazPen.Width), ColorToVec4(FLazPen.Color));

  FCurrentX := points[High(points)].X;
  FCurrentY := points[High(points)].Y;
end;

procedure TGL2DCanvas.DoPolygon(const points: array of TPoint);
var
  i: integer;
begin
  if (Length(points) < 2) or (FLazPen.Style = psClear) then
    Exit;

  for i := 0 to High(points) - 1 do
    AddAALine(points[i].X, points[i].Y,
      points[i + 1].X, points[i + 1].Y,
      Max(1, FLazPen.Width), ColorToVec4(FLazPen.Color));

  if Length(points) > 2 then
    AddAALine(points[High(points)].X, points[High(points)].Y,
      points[0].X, points[0].Y,
      Max(1, FLazPen.Width), ColorToVec4(FLazPen.Color));
end;

procedure TGL2DCanvas.DoPolygonFill(const points: array of TPoint);
var
  i: integer;
  A, B, C: TAAColorVertex;
  Col: TVec4;
  D: TVec4;
  Z: TVec2;
begin
  if (Length(points) < 3) or (FLazBrush.Style = bsClear) then
    Exit;

  Col := ColorToVec4(FLazBrush.Color);
  D.X := 0;
  D.Y := 0;
  D.Z := 0;
  D.W := 0;
  Z.X := 0;
  Z.Y := 0;

  A.Position.X := points[0].X;
  A.Position.Y := points[0].Y;
  A.Local := Z;
  A.Data0 := D;
  A.Color := Col;
  A.Kind := Ord(pkSolid);

  for i := 1 to High(points) - 1 do
  begin
    B.Position.X := points[i].X;
    B.Position.Y := points[i].Y;
    B.Local := Z;
    B.Data0 := D;
    B.Color := Col;
    B.Kind := Ord(pkSolid);

    C.Position.X := points[i + 1].X;
    C.Position.Y := points[i + 1].Y;
    C.Local := Z;
    C.Data0 := D;
    C.Color := Col;
    C.Kind := Ord(pkSolid);

    AddTriangle(A, B, C);
  end;
end;

procedure TGL2DCanvas.DoRectangle(const Bounds: TRect);
var
  R: TRect;
begin
  if FLazPen.Style = psClear then
    Exit;

  R := NormalizeRect(Bounds);
  AddAARectStroke(R.Left, R.Top, R.Right, R.Bottom,
    Max(1, FLazPen.Width), ColorToVec4(FLazPen.Color));
end;

procedure TGL2DCanvas.DoRectangleFill(const Bounds: TRect);
var
  R: TRect;
begin
  if FLazBrush.Style = bsClear then
    Exit;

  R := NormalizeRect(Bounds);
  AddAARectFill(R.Left, R.Top, R.Right, R.Bottom,
    ColorToVec4(FLazBrush.Color));
end;

procedure TGL2DCanvas.DoEllipse(const Bounds: TRect);
var
  R: TRect;
begin
  if FLazPen.Style = psClear then
    Exit;

  R := NormalizeRect(Bounds);
  AddAAEllipseStroke(R.Left, R.Top, R.Right, R.Bottom,
    Max(1, FLazPen.Width), ColorToVec4(FLazPen.Color));
end;

procedure TGL2DCanvas.DoEllipseFill(const Bounds: TRect);
var
  R: TRect;
begin
  if FLazBrush.Style = bsClear then
    Exit;

  R := NormalizeRect(Bounds);
  AddAAEllipseFill(R.Left, R.Top, R.Right, R.Bottom,
    ColorToVec4(FLazBrush.Color));
end;

{$IFDEF WINDOWS}
function TGL2DCanvas.CreateTextTexture_Windows(const Text: ansistring; out W, H: Integer): GLuint;
var
  Bmp: TBitmap;
  Img: TLazIntfImage;
  XX, YY: Integer;
  C: TFPColor;
  A: Word;
  FontCol: TColor;
  FR, FG, FB: Byte;
begin
  Result := 0;
  W := 0;
  H := 0;

  Bmp := TBitmap.Create;
  Img := nil;
  try
    Bmp.PixelFormat := pf32bit;
    Bmp.Canvas.Font.Assign(FLazFont);

    W := Bmp.Canvas.TextWidth(Text);
    H := Bmp.Canvas.TextHeight(Text);

    if W <= 0 then
      W := 1;
    if H <= 0 then
      H := Max(1, FLazFont.Size + 4);

    Bmp.SetSize(W, H);

    Bmp.Canvas.Brush.Style := bsSolid;
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.FillRect(0, 0, W, H);

    Bmp.Canvas.Font.Assign(FLazFont);
    Bmp.Canvas.Font.Color := clWhite;
    Bmp.Canvas.Brush.Style := bsClear;
    Bmp.Canvas.TextOut(0, 0, Text);

    Img := TLazIntfImage.Create(0, 0);
    Img.LoadFromBitmap(Bmp.Handle, Bmp.MaskHandle);

    FontCol := ColorToRGB(FLazFont.Color);
    FR := Red(FontCol);
    FG := Green(FontCol);
    FB := Blue(FontCol);

    for YY := 0 to Img.Height - 1 do
      for XX := 0 to Img.Width - 1 do
      begin
        C := Img.Colors[XX, YY];
        A := (C.Red + C.Green + C.Blue) div 3;
        C.Red   := FR * 257;
        C.Green := FG * 257;
        C.Blue  := FB * 257;
        C.Alpha := A;
        Img.Colors[XX, YY] := C;
      end;

    Result := CreateTextureFromLazIntfImage(Img);
  finally
    Img.Free;
    Bmp.Free;
  end;
end;

{$ENDIF}

function TGL2DCanvas.CreateTextureFromRGBA(const Buf: Pointer; W, H: Integer): GLuint;
begin
  Result := 0;
  glGenTextures(1, @Result);
  if Result = 0 then Exit;

  glBindTexture(GL_TEXTURE_2D, Result);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, Buf);
  glBindTexture(GL_TEXTURE_2D, 0);
end;

{$IFDEF LINUX}
function TGL2DCanvas.CreateTextTexture_Linux(const Text: ansistring; out W, H: Integer): GLuint;
var
  Bmp: TBitmap;
  Img: TLazIntfImage;
  XX, YY: Integer;
  C: TFPColor;
  FontCol: TColor;
  FR, FG, FB: Byte;
  Alpha: Byte;
  RGBA: PByte;
  P: PByte;
  BufSize: Integer;
begin
  Result := 0;
  W := 0;
  H := 0;

  Bmp := TBitmap.Create;
  Img := nil;
  RGBA := nil;
  try
    Bmp.PixelFormat := pf32bit;
    Bmp.Canvas.Font.Assign(FLazFont);

    W := Bmp.Canvas.TextWidth(Text);
    H := Bmp.Canvas.TextHeight(Text);

    if W <= 0 then
      W := 1;
    if H <= 0 then
      H := Max(1, FLazFont.Size + 4);

    Bmp.SetSize(W, H);

    Bmp.Canvas.Brush.Style := bsSolid;
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.FillRect(0, 0, W, H);

    Bmp.Canvas.Font.Assign(FLazFont);
    Bmp.Canvas.Font.Color := clWhite;
    Bmp.Canvas.Brush.Style := bsClear;
    Bmp.Canvas.TextOut(0, 0, Text);

    Img := Bmp.CreateIntfImage;
    if Img = nil then
      Exit;

    FontCol := ColorToRGB(FLazFont.Color);
    FR := Red(FontCol);
    FG := Green(FontCol);
    FB := Blue(FontCol);

    BufSize := W * H * 4;
    GetMem(RGBA, BufSize);
    P := RGBA;

    for YY := 0 to H - 1 do
      for XX := 0 to W - 1 do
      begin
        C := Img.Colors[XX, YY];
        Alpha := ((C.Red shr 8) + (C.Green shr 8) + (C.Blue shr 8)) div 3;

        P^ := FR; Inc(P);
        P^ := FG; Inc(P);
        P^ := FB; Inc(P);
        P^ := Alpha; Inc(P);
      end;

    Result := CreateTextureFromRGBA(RGBA, W, H);
  finally
    if Assigned(RGBA) then
      FreeMem(RGBA);
    Img.Free;
    Bmp.Free;
  end;
end;
{$ENDIF}

procedure TGL2DCanvas.DoTextOut(x, y: integer; Text: ansistring);
var
  Key: string;
  Entry: TTextCacheEntry;
  Found: Boolean;
  Tex: GLuint;
  W, H: Integer;
  ToDelete: specialize TList<string>;
  Pair: specialize TPair<string, TTextCacheEntry>;
  OldestKey: string;
  OldestFrame: Int64;
  DelKey: string;
begin
  if Text = '' then
    Exit;
  if not Assigned(FControl) then
    Exit;

  FControl.MakeCurrent;
  EnsureGLReady;
  Flush;

  Inc(FCurrentFrame);
  Key := MakeTextCacheKey(Text);

  Found := FTextCache.TryGetValue(Key, Entry);
  if Found then
  begin
    Entry.LastUsedFrame := FCurrentFrame;
    FTextCache[Key] := Entry;
    DrawTexturedQuad(Entry.TexID, x, y, Entry.Width, Entry.Height,
      0, 0, 1, 1, MakeVec4(1, 1, 1, 1));
    Exit;
  end;

  if FTextCache.Count >= TEXT_CACHE_MAX then
  begin
    ToDelete := specialize TList<string>.Create;
    try
      for Pair in FTextCache do
      begin
        if FCurrentFrame - Pair.Value.LastUsedFrame > TEXT_CACHE_MAX_AGE then
          ToDelete.Add(Pair.Key);
      end;

      if ToDelete.Count = 0 then
      begin
        OldestKey := '';
        OldestFrame := High(Int64);

        for Pair in FTextCache do
        begin
          if Pair.Value.LastUsedFrame < OldestFrame then
          begin
            OldestFrame := Pair.Value.LastUsedFrame;
            OldestKey := Pair.Key;
          end;
        end;

        if OldestKey <> '' then
          ToDelete.Add(OldestKey);
      end;

      for DelKey in ToDelete do
      begin
        if FTextCache.TryGetValue(DelKey, Entry) then
          glDeleteTextures(1, @Entry.TexID);
        FTextCache.Remove(DelKey);
      end;
    finally
      ToDelete.Free;
    end;
  end;

  {$IFDEF WINDOWS}
  Tex := CreateTextTexture_Windows(Text, W, H);
  {$ENDIF}

  {$IFDEF LINUX}
  Tex := CreateTextTexture_Linux(Text, W, H);
  {$ENDIF}

  if Tex <> 0 then
  begin
    Entry.TexID := Tex;
    Entry.Width := W;
    Entry.Height := H;
    Entry.LastUsedFrame := FCurrentFrame;
    FTextCache.Add(Key, Entry);

    DrawTexturedQuad(Tex, x, y, W, H, 0, 0, 1, 1, MakeVec4(1, 1, 1, 1));
  end;
end;

procedure TGL2DCanvas.DoGetTextSize(Text: ansistring; var w, h: integer);
var
  Bmp: TBitmap;
begin
  if Text = '' then
  begin
    w := 0;
    h := Max(1, FLazFont.Size + 4);
    Exit;
  end;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FLazFont);
    w := Bmp.Canvas.TextWidth(Text);
    h := Bmp.Canvas.TextHeight(Text);
    if h <= 0 then
      h := Max(1, FLazFont.Size + 4);
  finally
    Bmp.Free;
  end;
end;

function TGL2DCanvas.DoGetTextHeight(Text: ansistring): integer;
var
  W: integer;
begin
  DoGetTextSize(Text, W, Result);
end;

function TGL2DCanvas.DoGetTextWidth(Text: ansistring): integer;
var
  H: integer;
begin
  DoGetTextSize(Text, Result, H);
end;

procedure TGL2DCanvas.DoFloodFill(x, y: integer);
var
  R: TRect;
begin
  if FLazBrush.Style = bsClear then
    Exit;

  if FClipping then
    R := NormalizeRect(FClipRect)
  else
    R := Rect(0, 0, FWidth, FHeight);

  AddAARectFill(R.Left, R.Top, R.Right, R.Bottom, ColorToVec4(FLazBrush.Color));
end;

procedure TGL2DCanvas.DoCopyRect(x, y: integer; canvas: TFPCustomCanvas;
  const SourceRect: TRect);
var
  R: TRect;
  Img: TFPMemoryImage;
  SX, SY, DX, DY: integer;
begin
  if canvas = nil then
    Exit;

  R := NormalizeRect(SourceRect);
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  Img := TFPMemoryImage.Create(R.Right - R.Left, R.Bottom - R.Top);
  try
    for SY := 0 to Img.Height - 1 do
      for SX := 0 to Img.Width - 1 do
        Img.Colors[SX, SY] := canvas.Colors[R.Left + SX, R.Top + SY];

    for DY := 0 to Img.Height - 1 do
      for DX := 0 to Img.Width - 1 do
        Colors[x + DX, y + DY] := Img.Colors[DX, DY];
  finally
    Img.Free;
  end;
end;

// В DoDraw — использовать GetTexture вместо прямого создания:
procedure TGL2DCanvas.DoDraw(x, y: integer; const image: TFPCustomImage);
var
  Tex: GLuint;
begin
  if (image = nil) or (image.Width <= 0) or (image.Height <= 0) then Exit;
  if not Assigned(FControl) then Exit;

  FControl.MakeCurrent;
  EnsureGLReady;

  Tex := GetTexture(image);
  if Tex <> 0 then
    AddTexturedQuad(x, y, x + image.Width, y + image.Height,
      0, 0, 1, 1, Tex, MakeVec4(1, 1, 1, 1));
end;

procedure TGL2DCanvas.DoRadialPie(x1, y1, x2, y2, StartAngle16Deg,
  Angle16DegLength: integer);
var
  CX, CY, RX, RY: single;
  StartAngle, EndAngle, Angle: single;
  Steps, I: integer;
  P1, P2, Center: TVec2;
  C: TVec4;
  D: TVec4;
  Z: TVec2;
  V0, V1, V2: TAAColorVertex;

  function Deg16ToRad(A: integer): single;
  begin
    Result := (A / 16.0) * (Pi / 180.0);
  end;

begin
  if FLazBrush.Style = bsClear then Exit;

  CX := (x1 + x2) / 2;
  CY := (y1 + y2) / 2;
  RX := Abs(x2 - x1) / 2;
  RY := Abs(y2 - y1) / 2;

  StartAngle := Deg16ToRad(StartAngle16Deg);
  EndAngle := Deg16ToRad(StartAngle16Deg + Angle16DegLength);

  // Approximate curve
  Steps := Max(5, Ceil(Abs(EndAngle - StartAngle) * 20)); // Adaptive steps
  if Steps > 100 then Steps := 100;

  C := ColorToVec4(FLazBrush.Color);
  D.X := 0;
  D.Y := 0;
  D.Z := 0;
  D.W := 0;
  Z.X := 0;
  Z.Y := 0;

  Center.X := CX;
  Center.Y := CY;
  V0.Position := Center;
  V0.Local := Z;
  V0.Data0 := D;
  V0.Color := C;
  V0.Kind := Ord(pkSolid);

  P1.X := CX + Cos(StartAngle) * RX;
  P1.Y := CY + Sin(StartAngle) * RY;

  for I := 1 to Steps do
  begin
    Angle := StartAngle + (EndAngle - StartAngle) * (I / Steps);
    P2.X := CX + Cos(Angle) * RX;
    P2.Y := CY + Sin(Angle) * RY;

    V1.Position := P1;
    V1.Local := Z;
    V1.Data0 := D;
    V1.Color := C;
    V1.Kind := Ord(pkSolid);
    V2.Position := P2;
    V2.Local := Z;
    V2.Data0 := D;
    V2.Color := C;
    V2.Kind := Ord(pkSolid);

    AddTriangle(V0, V1, V2);
    P1 := P2;
  end;
end;

procedure TGL2DCanvas.DoPolyBezier(Points: PPoint; NumPts: integer;
  Filled, Continuous: boolean);
var
  i, j, Steps: integer;
  t, dt: single;
  p0, p1, p2, p3: TPoint;
  x, y: single;
  PolyPts: array of TPoint;
  Count: integer;

  procedure AddBezierPoint(P: TPoint);
  begin
    if Count >= Length(PolyPts) then SetLength(PolyPts, Length(PolyPts) + 100);
    PolyPts[Count] := P;
    Inc(Count);
  end;

begin
  if NumPts < 4 then Exit;

  SetLength(PolyPts, 100);
  Count := 0;

  i := 0;
  while i < NumPts - 1 do
  begin
    if Continuous then
    begin
      // Standard PolyBezier: P0 is start, P1,P2 controls, P3 is end (and next start)
      // NumPts must be 1 + 3n
      if i + 3 >= NumPts then Break;
      p0 := Points[i];
      p1 := Points[i + 1];
      p2 := Points[i + 2];
      p3 := Points[i + 3];
      Inc(i, 3);
    end
    else
    begin
      // Discrete segments (4 points per curve)
      if i + 3 >= NumPts then Break;
      p0 := Points[i];
      p1 := Points[i + 1];
      p2 := Points[i + 2];
      p3 := Points[i + 3];
      Inc(i, 4);
    end;

    // Add first point
    if Count = 0 then AddBezierPoint(p0);

    // Subdivide
    Steps := 20;
    dt := 1.0 / Steps;
    for j := 1 to Steps do
    begin
      t := j * dt;
      // Cubic Bezier formula
      x := Power(1 - t, 3) * p0.X + 3 * Power(1 - t, 2) * t * p1.X +
        3 * (1 - t) * t * t * p2.X + t * t * t * p3.X;
      y := Power(1 - t, 3) * p0.Y + 3 * Power(1 - t, 2) * t * p1.Y +
        3 * (1 - t) * t * t * p2.Y + t * t * t * p3.Y;
      AddBezierPoint(Point(Round(x), Round(y)));
    end;
  end;

  if Count > 1 then
  begin
    SetLength(PolyPts, Count);
    if Filled then
      DoPolygonFill(PolyPts)
    else
      DoPolyline(PolyPts);
  end;
end;

function TGL2DCanvas.GetClipRect: TRect;
begin
  Result := FClipRect;
end;

procedure TGL2DCanvas.SetClipRect(const AValue: TRect);
begin
  FClipRect := NormalizeRect(AValue);
  if FDrawing then
    ApplyScissor;
end;

function TGL2DCanvas.GetClipping: boolean;
begin
  Result := FClipping;
end;

procedure TGL2DCanvas.SetClipping(const AValue: boolean);
begin
  FClipping := AValue;
  if FDrawing then
    ApplyScissor;
end;

procedure TGL2DCanvas.RoundRect(X1, Y1, X2, Y2, RX, RY: integer);
begin
  if FLazBrush.Style <> bsClear then
    AddAARoundRectFill(X1, Y1, X2, Y2, RX, RY, ColorToVec4(FLazBrush.Color));
  if FLazPen.Style <> psClear then
    AddAARoundRectStroke(X1, Y1, X2, Y2, RX, RY, Max(1, FLazPen.Width),
      ColorToVec4(FLazPen.Color));
end;

procedure TGL2DCanvas.GradientFill(ARect: TRect; AStart, AStop: TColor;
  ADirection: TGradientDirection);
var
  R: TRect;
  V0, V1, V2, V3: TAAColorVertex;
  D: TVec4;
  Z: TVec2;
  C1, C2: TVec4;
begin
  R := NormalizeRect(ARect);
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  D := MakeVec4(0, 0, 0, 0);
  Z := MakeVec2(0, 0);
  C1 := ColorToVec4(AStart);
  C2 := ColorToVec4(AStop);

  V0.Position := MakeVec2(R.Left, R.Top);
  V0.Local := Z;
  V0.Data0 := D;
  V0.Kind := Ord(pkSolid);
  V1.Position := MakeVec2(R.Right, R.Top);
  V1.Local := Z;
  V1.Data0 := D;
  V1.Kind := Ord(pkSolid);
  V2.Position := MakeVec2(R.Right, R.Bottom);
  V2.Local := Z;
  V2.Data0 := D;
  V2.Kind := Ord(pkSolid);
  V3.Position := MakeVec2(R.Left, R.Bottom);
  V3.Local := Z;
  V3.Data0 := D;
  V3.Kind := Ord(pkSolid);

  case ADirection of
    gdVertical:
    begin
      V0.Color := C1;
      V1.Color := C1;
      V2.Color := C2;
      V3.Color := C2;
    end;
    gdHorizontal:
    begin
      V0.Color := C1;
      V3.Color := C1;
      V1.Color := C2;
      V2.Color := C2;
    end;
    else
    begin
      V0.Color := C1;
      V1.Color := C2;
      V2.Color := C2;
      V3.Color := C1;
    end;
  end;

  AddQuad(V0, V1, V2, V3);
end;

procedure TGL2DCanvas.StretchDraw(x, y, w, h: integer; Source: TFPCustomImage);
var
  Tex: GLuint;
begin
  if (Source = nil) or (Source.Width <= 0) or (Source.Height <= 0) then
    Exit;

  if not Assigned(FControl) then
    Exit;

  FControl.MakeCurrent;
  EnsureGLReady;

  Tex := CreateTextureFromImage(Source);
  try
    AddTexturedQuad(x, y, x + w, y + h, 0, 0, 1, 1,
      Tex, MakeVec4(1, 1, 1, 1));
  finally
    DeleteTexture(Tex);
  end;
end;

procedure TGL2DCanvas.Frame(const ARect: TRect);
begin
  DoRectangle(ARect);
end;

procedure TGL2DCanvas.Frame3d(var ARect: TRect; const FrameWidth: integer;
  const Style: TGraphicsBevelCut);
var
  R: TRect;
  OldPenColor: TColor;
  OldPenWidth: integer;
begin
  if (FrameWidth <= 0) or (Style = bvNone) then Exit;

  R := ARect;
  OldPenColor := FLazPen.Color;
  OldPenWidth := FLazPen.Width;

  FLazPen.Width := FrameWidth;

  case Style of
    bvRaised:
    begin
      FLazPen.Color := clBtnHighlight;
      DoRectangle(R);
      InflateRect(R, -FrameWidth, -FrameWidth);
      FLazPen.Color := clBtnShadow;
      DoRectangle(R);
    end;
    bvLowered:
    begin
      FLazPen.Color := clBtnShadow;
      DoRectangle(R);
      InflateRect(R, -FrameWidth, -FrameWidth);
      FLazPen.Color := clBtnHighlight;
      DoRectangle(R);
    end;
    bvSpace:
    begin
      InflateRect(R, -FrameWidth, -FrameWidth);
    end;
  end;

  FLazPen.Color := OldPenColor;
  FLazPen.Width := OldPenWidth;
  ARect := R;
end;

procedure TGL2DCanvas.TextOut(X, Y: integer; const Text: string);
begin
  DoTextOut(X, Y, Text);
end;

procedure TGL2DCanvas.Ellipse(x1, y1, x2, y2: integer);
begin
  if FLazBrush.Style <> bsClear then
    DoEllipseFill(Rect(x1, y1, x2, y2));
  if FLazPen.Style <> psClear then
    DoEllipse(Rect(x1, y1, x2, y2));
end;

procedure TGL2DCanvas.Polygon(const Points: array of TPoint);
begin
  DoPolygon(Points);
end;

procedure TGL2DCanvas.Polyline(const Points: array of TPoint);
begin
  DoPolyline(Points);
end;

procedure TGL2DCanvas.Rectangle(X1, Y1, X2, Y2: integer);
begin
  if FLazBrush.Style <> bsClear then
    DoRectangleFill(Rect(X1, Y1, X2, Y2));
  if FLazPen.Style <> psClear then
    DoRectangle(Rect(X1, Y1, X2, Y2));
end;

procedure TGL2DCanvas.Rectangle(const R: TRect);
begin
  if FLazBrush.Style <> bsClear then
    DoRectangleFill(R);
  if FLazPen.Style <> psClear then
    DoRectangle(R);
end;

procedure TGL2DCanvas.MoveTo(X, Y: integer);
begin
  DoMoveTo(X, Y);
end;

procedure TGL2DCanvas.LineTo(X, Y: integer);
begin
  DoLine(FCurrentX, FCurrentY, X, Y);
  FCurrentX := X;
  FCurrentY := Y;
end;

procedure TGL2DCanvas.SetSize(AWidth, AHeight: integer);
begin
  if AWidth < 1 then AWidth := 1;
  if AHeight < 1 then AHeight := 1;

  if (FWidth = AWidth) and (FHeight = AHeight) then
    Exit;

  FWidth := AWidth;
  FHeight := AHeight;
  FClipRect := Rect(0, 0, FWidth, FHeight);

  if FGLInitialized and Assigned(FControl) then
  begin
    FControl.MakeCurrent;
    glViewport(0, 0, FWidth, FHeight);
  end;
end;

{ TGLCanvasControl }

constructor TGLCanvasControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCanvas := TGL2DCanvas.Create(Self);
end;

destructor TGLCanvasControl.Destroy;
begin
  FreeAndNil(FCanvas);
  inherited Destroy;
end;

procedure TGLCanvasControl.DoOnPaint;
begin
  inherited DoOnPaint;

  if not Assigned(FCanvas) then
    Exit;

  FCanvas.BeginDraw;
  try
    if Assigned(FOnDraw) then
      FOnDraw(Self);
  finally
    FCanvas.EndDraw;
  end;
end;

procedure TGLCanvasControl.Resize;
begin
  inherited Resize;
  if Assigned(FCanvas) then
    FCanvas.SetSize(ClientWidth, ClientHeight);
end;

function TGL2DCanvas.Angle16ToRad(AAngle16: Integer): Single;
begin
  Result := (AAngle16 / 16.0) * (Pi / 180.0);
end;

function TGL2DCanvas.PointOnEllipse(const R: TRect; AAngleRad: Single): TPoint;
var
  RR: TRect;
  CX, CY, RX, RY: Single;
begin
  RR := NormalizeRect(R);
  CX := (RR.Left + RR.Right) * 0.5;
  CY := (RR.Top + RR.Bottom) * 0.5;
  RX := Abs(RR.Right - RR.Left) * 0.5;
  RY := Abs(RR.Bottom - RR.Top) * 0.5;

  Result.X := Round(CX + Cos(AAngleRad) * RX);
  Result.Y := Round(CY + Sin(AAngleRad) * RY);
end;

procedure TGL2DCanvas.BuildArcPolyline(const R: TRect; AStartRad, ASweepRad: Single;
  out Points: array of TPoint; out ACount: Integer);
var
  RR: TRect;
  I, Steps, MaxPts: Integer;
  A, T: Single;
begin
  RR := NormalizeRect(R);
  MaxPts := Length(Points);
  ACount := 0;

  if MaxPts <= 0 then
    Exit;

  Steps := Max(8, Ceil(Abs(ASweepRad) * 24));
  if Steps > MaxPts then
    Steps := MaxPts;
  if Steps < 2 then
    Steps := 2;

  for I := 0 to Steps - 1 do
  begin
    if Steps = 1 then
      T := 0
    else
      T := I / (Steps - 1);
    A := AStartRad + ASweepRad * T;
    Points[ACount] := PointOnEllipse(RR, A);
    Inc(ACount);
  end;
end;

procedure TGL2DCanvas.DrawArcInternal(const R: TRect; AStartRad, ASweepRad: Single;
  UpdatePenPos: Boolean);
var
  Pts: array[0..255] of TPoint;
  Count: Integer;
begin
  if FLazPen.Style = psClear then
    Exit;

  BuildArcPolyline(R, AStartRad, ASweepRad, Pts, Count);
  if Count > 1 then
    DoPolyline(Slice(Pts, Count));

  if UpdatePenPos and (Count > 0) then
  begin
    FCurrentX := Pts[Count - 1].X;
    FCurrentY := Pts[Count - 1].Y;
  end;
end;

procedure TGL2DCanvas.DrawPieInternal(const R: TRect; AStartRad, ASweepRad: Single);
begin
  DoRadialPie(R.Left, R.Top, R.Right, R.Bottom,
    Round(AStartRad * 180.0 / Pi * 16.0),
    Round(ASweepRad * 180.0 / Pi * 16.0));

  if FLazPen.Style <> psClear then
    DrawArcInternal(R, AStartRad, ASweepRad, False);
end;

procedure TGL2DCanvas.DrawChordInternal(const R: TRect; AStartRad, ASweepRad: Single);
var
  Pts: array of TPoint;
  Count, I: Integer;
begin
  BuildArcPolyline(R, AStartRad, ASweepRad, Pts, Count);
  if Count < 2 then
    Exit;

  if FLazBrush.Style <> bsClear then
  begin
    SetLength(Pts, Count + 1);
    Pts[Count] := Pts[0];
    DoPolygonFill(Pts);
    SetLength(Pts, Count);
  end;

  if FLazPen.Style <> psClear then
  begin
    DoPolyline(Slice(Pts, Count));
    AddAALine(
      Pts[Count - 1].X, Pts[Count - 1].Y,
      Pts[0].X, Pts[0].Y,
      Max(1, FLazPen.Width),
      ColorToVec4(FLazPen.Color)
    );
  end;
end;

function TGL2DCanvas.GraphicToImage(ASrc: TGraphic): TFPCustomImage;
var
  Bmp: TBitmap;
  Img: TFPMemoryImage;
  X, Y: Integer;
begin
  Result := nil;
  if (ASrc = nil) or (ASrc.Width <= 0) or (ASrc.Height <= 0) then
    Exit;

  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf32bit;
    Bmp.SetSize(ASrc.Width, ASrc.Height);
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.FillRect(0, 0, Bmp.Width, Bmp.Height);
    Bmp.Canvas.Draw(0, 0, ASrc);

    Img := TFPMemoryImage.Create(Bmp.Width, Bmp.Height);
    for Y := 0 to Bmp.Height - 1 do
      for X := 0 to Bmp.Width - 1 do
        Img.Colors[X, Y] := Bmp.Canvas.Colors[X, Y];

    Result := Img;
  finally
    Bmp.Free;
  end;
end;

procedure TGL2DCanvas.Arc(ALeft, ATop, ARight, ABottom, Angle16Deg,
  Angle16DegLength: Integer);
begin
  DrawArcInternal(
    Rect(ALeft, ATop, ARight, ABottom),
    Angle16ToRad(Angle16Deg),
    Angle16ToRad(Angle16DegLength),
    False
  );
end;

procedure TGL2DCanvas.Arc(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: Integer);
var
  R: TRect;
  CX, CY, RX, RY: Double;
  A1, A2, Sweep: Double;
begin
  R := NormalizeRect(Rect(ALeft, ATop, ARight, ABottom));
  CX := (R.Left + R.Right) * 0.5;
  CY := (R.Top + R.Bottom) * 0.5;
  RX := Abs(R.Right - R.Left) * 0.5;
  RY := Abs(R.Bottom - R.Top) * 0.5;

  if (RX <= 0) or (RY <= 0) then
    Exit;

  A1 := ArcTan2((SY - CY) / RY, (SX - CX) / RX);
  A2 := ArcTan2((EY - CY) / RY, (EX - CX) / RX);
  Sweep := A2 - A1;
  while Sweep <= -2 * Pi do Sweep := Sweep + 2 * Pi;
  while Sweep > 2 * Pi do Sweep := Sweep - 2 * Pi;

  DrawArcInternal(R, A1, Sweep, False);
end;

procedure TGL2DCanvas.ArcTo(ALeft, ATop, ARight, ABottom, SX, SY, EX, EY: Integer);
var
  R: TRect;
  CX, CY, RX, RY: Double;
  A1, A2, Sweep: Double;
begin
  R := NormalizeRect(Rect(ALeft, ATop, ARight, ABottom));
  CX := (R.Left + R.Right) * 0.5;
  CY := (R.Top + R.Bottom) * 0.5;
  RX := Abs(R.Right - R.Left) * 0.5;
  RY := Abs(R.Bottom - R.Top) * 0.5;

  if (RX <= 0) or (RY <= 0) then
    Exit;

  A1 := ArcTan2((SY - CY) / RY, (SX - CX) / RX);
  A2 := ArcTan2((EY - CY) / RY, (EX - CX) / RX);
  Sweep := A2 - A1;
  while Sweep <= -2 * Pi do Sweep := Sweep + 2 * Pi;
  while Sweep > 2 * Pi do Sweep := Sweep - 2 * Pi;

  DrawArcInternal(R, A1, Sweep, True);
end;

procedure TGL2DCanvas.AngleArc(X, Y: Integer; Radius: Longword; StartAngle,
  SweepAngle: Single);
begin
  DrawArcInternal(
    Rect(X - Integer(Radius), Y - Integer(Radius), X + Integer(Radius), Y + Integer(Radius)),
    StartAngle * Pi / 180.0,
    SweepAngle * Pi / 180.0,
    False
  );
end;

function TGL2DCanvas.PointToEllipseAngle(const R: TRect; PX, PY: Integer): Single;
var
  RR: TRect;
  CX, CY, RX, RY: Double;
begin
  RR := NormalizeRect(R);
  CX := (RR.Left + RR.Right) * 0.5;
  CY := (RR.Top + RR.Bottom) * 0.5;
  RX := Abs(RR.Right - RR.Left) * 0.5;
  RY := Abs(RR.Bottom - RR.Top) * 0.5;

  if (RX <= 0) or (RY <= 0) then
    Exit(0);

  Result := ArcTan2((PY - CY) / RY, (PX - CX) / RX);
end;

procedure TGL2DCanvas.BrushCopy(ADestRect: TRect; ABitmap: TBitmap;
  ASourceRect: TRect; ATransparentColor: TColor);
var
  SrcImg: TFPMemoryImage;
  TmpImg: TFPMemoryImage;
  X, Y: Integer;
  SX, SY: Integer;
  SrcR, DstR: TRect;
  SrcC: TFPColor;
  TransparentFP: TFPColor;
begin
  if (ABitmap = nil) then
    Exit;

  SrcR := NormalizeRect(ASourceRect);
  DstR := NormalizeRect(ADestRect);

  if (SrcR.Right <= SrcR.Left) or (SrcR.Bottom <= SrcR.Top) then
    Exit;
  if (DstR.Right <= DstR.Left) or (DstR.Bottom <= DstR.Top) then
    Exit;

  SrcImg := TFPMemoryImage.Create(ABitmap.Width, ABitmap.Height);
  try
    for Y := 0 to ABitmap.Height - 1 do
      for X := 0 to ABitmap.Width - 1 do
        SrcImg.Colors[X, Y] := ABitmap.Canvas.Colors[X, Y];

    TmpImg := TFPMemoryImage.Create(DstR.Right - DstR.Left, DstR.Bottom - DstR.Top);
    try
      TransparentFP := TColorToFPColor(ATransparentColor);

      for Y := 0 to TmpImg.Height - 1 do
        for X := 0 to TmpImg.Width - 1 do
        begin
          SX := SrcR.Left + MulDiv(X, SrcR.Right - SrcR.Left, TmpImg.Width);
          SY := SrcR.Top + MulDiv(Y, SrcR.Bottom - SrcR.Top, TmpImg.Height);

          if SX >= SrcImg.Width then SX := SrcImg.Width - 1;
          if SY >= SrcImg.Height then SY := SrcImg.Height - 1;
          if SX < 0 then SX := 0;
          if SY < 0 then SY := 0;

          SrcC := SrcImg.Colors[SX, SY];
          if (SrcC.red = TransparentFP.red) and
             (SrcC.green = TransparentFP.green) and
             (SrcC.blue = TransparentFP.blue) then
          begin
            SrcC.alpha := 0;
          end;

          TmpImg.Colors[X, Y] := SrcC;
        end;

      DoDraw(DstR.Left, DstR.Top, TmpImg);
    finally
      TmpImg.Free;
    end;
  finally
    SrcImg.Free;
  end;
end;

procedure TGL2DCanvas.Chord(x1, y1, x2, y2, Angle16Deg, Angle16DegLength: Integer);
begin
  DrawChordInternal(
    Rect(x1, y1, x2, y2),
    Angle16ToRad(Angle16Deg),
    Angle16ToRad(Angle16DegLength)
  );
end;

procedure TGL2DCanvas.Chord(x1, y1, x2, y2, SX, SY, EX, EY: Integer);
var
  R: TRect;
  A1, A2, Sweep: Double;
begin
  R := NormalizeRect(Rect(x1, y1, x2, y2));
  A1 := PointToEllipseAngle(R, SX, SY);
  A2 := PointToEllipseAngle(R, EX, EY);

  Sweep := A2 - A1;
  while Sweep <= -2 * Pi do Sweep := Sweep + 2 * Pi;
  while Sweep > 2 * Pi do Sweep := Sweep - 2 * Pi;

  DrawChordInternal(R, A1, Sweep);
end;

procedure TGL2DCanvas.CopyRect(const Dest: TRect; SrcCanvas: TCanvas;
  const Source: TRect);
var
  SrcImg: TFPMemoryImage;
  SrcR, DstR: TRect;
  X, Y: Integer;
  SX, SY: Integer;
begin
  if SrcCanvas = nil then
    Exit;

  SrcR := NormalizeRect(Source);
  DstR := NormalizeRect(Dest);

  if (SrcR.Right <= SrcR.Left) or (SrcR.Bottom <= SrcR.Top) then
    Exit;
  if (DstR.Right <= DstR.Left) or (DstR.Bottom <= DstR.Top) then
    Exit;

  SrcImg := TFPMemoryImage.Create(SrcR.Right - SrcR.Left, SrcR.Bottom - SrcR.Top);
  try
    for Y := 0 to SrcImg.Height - 1 do
      for X := 0 to SrcImg.Width - 1 do
      begin
        SX := SrcR.Left + X;
        SY := SrcR.Top + Y;
        SrcImg.Colors[X, Y] := SrcCanvas.Colors[SX, SY];
      end;

    StretchDraw(DstR.Left, DstR.Top, DstR.Right - DstR.Left, DstR.Bottom - DstR.Top, SrcImg);
  finally
    SrcImg.Free;
  end;
end;

procedure TGL2DCanvas.Draw(X, Y: Integer; SrcGraphic: TGraphic);
var
  Img: TFPCustomImage;
begin
  Img := GraphicToImage(SrcGraphic);
  try
    if Img <> nil then
      DoDraw(X, Y, Img);
  finally
    Img.Free;
  end;
end;

procedure TGL2DCanvas.DrawFocusRect(const ARect: TRect);
var
  R: TRect;
  OldColor: TColor;
  OldWidth: Integer;
  OldStyle: TPenStyle;
  Pts: array of TPoint;
  I: Integer;
begin
  R := NormalizeRect(ARect);
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  OldColor := FLazPen.Color;
  OldWidth := FLazPen.Width;
  OldStyle := FLazPen.Style;
  try
    FLazPen.Color := clBlack;
    FLazPen.Width := 1;
    FLazPen.Style := psSolid;

    SetLength(Pts, 0);

    for I := R.Left to R.Right - 1 do
      if ((I - R.Left) mod 2) = 0 then
      begin
        SetLength(Pts, Length(Pts) + 2);
        Pts[High(Pts) - 1] := Point(I, R.Top);
        Pts[High(Pts)] := Point(I + 1, R.Top);
      end;
    if Length(Pts) > 1 then
      DoPolyline(Pts);

    SetLength(Pts, 0);
    for I := R.Left to R.Right - 1 do
      if ((I - R.Left) mod 2) = 0 then
      begin
        SetLength(Pts, Length(Pts) + 2);
        Pts[High(Pts) - 1] := Point(I, R.Bottom - 1);
        Pts[High(Pts)] := Point(I + 1, R.Bottom - 1);
      end;
    if Length(Pts) > 1 then
      DoPolyline(Pts);

    SetLength(Pts, 0);
    for I := R.Top to R.Bottom - 1 do
      if ((I - R.Top) mod 2) = 0 then
      begin
        SetLength(Pts, Length(Pts) + 2);
        Pts[High(Pts) - 1] := Point(R.Left, I);
        Pts[High(Pts)] := Point(R.Left, I + 1);
      end;
    if Length(Pts) > 1 then
      DoPolyline(Pts);

    SetLength(Pts, 0);
    for I := R.Top to R.Bottom - 1 do
      if ((I - R.Top) mod 2) = 0 then
      begin
        SetLength(Pts, Length(Pts) + 2);
        Pts[High(Pts) - 1] := Point(R.Right - 1, I);
        Pts[High(Pts)] := Point(R.Right - 1, I + 1);
      end;
    if Length(Pts) > 1 then
      DoPolyline(Pts);
  finally
    FLazPen.Color := OldColor;
    FLazPen.Width := OldWidth;
    FLazPen.Style := OldStyle;
  end;
end;

procedure TGL2DCanvas.StretchDraw(const DestRect: TRect; SrcGraphic: TGraphic);
var
  Img: TFPCustomImage;
  R: TRect;
begin
  Img := GraphicToImage(SrcGraphic);
  try
    if Img = nil then
      Exit;
    R := NormalizeRect(DestRect);
    StretchDraw(R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, Img);
  finally
    Img.Free;
  end;
end;

procedure TGL2DCanvas.Ellipse(const ARect: TRect);
begin
  Ellipse(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
end;

procedure TGL2DCanvas.FillRect(const ARect: TRect);
begin
  DoRectangleFill(ARect);
end;

procedure TGL2DCanvas.FillRect(X1, Y1, X2, Y2: Integer);
begin
  DoRectangleFill(Rect(X1, Y1, X2, Y2));
end;

procedure TGL2DCanvas.FloodFill(X, Y: Integer; FillColor: TColor;
  FillStyle: TFillStyle);
var
  OldBrushColor: TColor;
begin
  OldBrushColor := FLazBrush.Color;
  try
    FLazBrush.Color := FillColor;
    DoFloodFill(X, Y);
  finally
    FLazBrush.Color := OldBrushColor;
  end;
end;

procedure TGL2DCanvas.Frame3D(var ARect: TRect; TopColor, BottomColor: TColor;
  const FrameWidth: integer);
var
  R: TRect;
  I: Integer;
  OldPenColor: TColor;
  OldPenWidth: Integer;
begin
  if FrameWidth <= 0 then
    Exit;

  R := NormalizeRect(ARect);
  OldPenColor := FLazPen.Color;
  OldPenWidth := FLazPen.Width;
  try
    FLazPen.Width := 1;

    for I := 0 to FrameWidth - 1 do
    begin
      FLazPen.Color := TopColor;
      AddAALine(R.Left + I, R.Bottom - 1 - I, R.Left + I, R.Top + I, 1, ColorToVec4(TopColor));
      AddAALine(R.Left + I, R.Top + I, R.Right - 1 - I, R.Top + I, 1, ColorToVec4(TopColor));

      FLazPen.Color := BottomColor;
      AddAALine(R.Right - 1 - I, R.Top + I, R.Right - 1 - I, R.Bottom - 1 - I, 1, ColorToVec4(BottomColor));
      AddAALine(R.Right - 1 - I, R.Bottom - 1 - I, R.Left + I, R.Bottom - 1 - I, 1, ColorToVec4(BottomColor));
    end;

    InflateRect(R, -FrameWidth, -FrameWidth);
    ARect := R;
  finally
    FLazPen.Color := OldPenColor;
    FLazPen.Width := OldPenWidth;
  end;
end;

procedure TGL2DCanvas.Frame(X1, Y1, X2, Y2: Integer);
begin
  Frame(Rect(X1, Y1, X2, Y2));
end;

procedure TGL2DCanvas.FrameRect(const ARect: TRect);
var
  R: TRect;
  BW: Integer;
  C: TVec4;
begin
  if FLazBrush.Style = bsClear then
    Exit;

  R := NormalizeRect(ARect);
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;

  BW := Max(1, FLazPen.Width);
  C := ColorToVec4(FLazBrush.Color);

  AddSolidRect(R.Left, R.Top, R.Right, R.Top + BW, C);
  AddSolidRect(R.Left, R.Bottom - BW, R.Right, R.Bottom, C);
  AddSolidRect(R.Left, R.Top + BW, R.Left + BW, R.Bottom - BW, C);
  AddSolidRect(R.Right - BW, R.Top + BW, R.Right, R.Bottom - BW, C);
end;

procedure TGL2DCanvas.FrameRect(X1, Y1, X2, Y2: Integer);
begin
  FrameRect(Rect(X1, Y1, X2, Y2));
end;

function TGL2DCanvas.GetTextMetrics(out TM: TLCLTextMetric): boolean;
var
  Bmp: TBitmap;
begin
  FillChar(TM, SizeOf(TM), 0);
  Result := False;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FLazFont);

    TM.Height := Bmp.Canvas.TextHeight('Mg');
    TM.Ascender := TM.Height;
    TM.Descender := 0;

    Result := True;
  finally
    Bmp.Free;
  end;
end;

procedure TGL2DCanvas.RadialPie(x1, y1, x2, y2, StartAngle16Deg,
  Angle16DegLength: Integer);
begin
  DoRadialPie(x1, y1, x2, y2, StartAngle16Deg, Angle16DegLength);
end;

procedure TGL2DCanvas.Pie(EllipseX1, EllipseY1, EllipseX2, EllipseY2, StartX,
  StartY, EndX, EndY: Integer);
var
  R: TRect;
  A1, A2, Sweep: Double;
begin
  R := NormalizeRect(Rect(EllipseX1, EllipseY1, EllipseX2, EllipseY2));
  A1 := PointToEllipseAngle(R, StartX, StartY);
  A2 := PointToEllipseAngle(R, EndX, EndY);

  Sweep := A2 - A1;
  while Sweep <= -2 * Pi do Sweep := Sweep + 2 * Pi;
  while Sweep > 2 * Pi do Sweep := Sweep - 2 * Pi;

  DrawPieInternal(R, A1, Sweep);
end;

procedure TGL2DCanvas.PolyBezier(Points: PPoint; NumPts: Integer;
  Filled: boolean; Continuous: boolean);
begin
  DoPolyBezier(Points, NumPts, Filled, Continuous);
end;

procedure TGL2DCanvas.PolyBezier(const Points: array of TPoint;
  Filled: boolean; Continuous: boolean);
begin
  if Length(Points) = 0 then
    Exit;
  DoPolyBezier(@Points[0], Length(Points), Filled, Continuous);
end;

procedure TGL2DCanvas.Polygon(const Points: array of TPoint; Winding: Boolean;
  StartIndex: Integer; NumPts: Integer);
var
  ActualCount, I: Integer;
  Tmp: array of TPoint;
begin
  if StartIndex < 0 then
    StartIndex := 0;
  if StartIndex >= Length(Points) then
    Exit;

  if NumPts < 0 then
    ActualCount := Length(Points) - StartIndex
  else
    ActualCount := Min(NumPts, Length(Points) - StartIndex);

  if ActualCount <= 0 then
    Exit;

  SetLength(Tmp, ActualCount);
  for I := 0 to ActualCount - 1 do
    Tmp[I] := Points[StartIndex + I];

  if FLazBrush.Style <> bsClear then
    DoPolygonFill(Tmp);
  if FLazPen.Style <> psClear then
    DoPolygon(Tmp);
end;

procedure TGL2DCanvas.Polygon(Points: PPoint; NumPts: Integer; Winding: boolean);
var
  Tmp: array of TPoint;
  I: Integer;
begin
  if (Points = nil) or (NumPts <= 0) then
    Exit;

  SetLength(Tmp, NumPts);
  for I := 0 to NumPts - 1 do
    Tmp[I] := Points[I];

  Polygon(Tmp, Winding, 0, NumPts);
end;

procedure TGL2DCanvas.Polyline(const Points: array of TPoint; StartIndex: Integer;
  NumPts: Integer);
var
  ActualCount, I: Integer;
  Tmp: array of TPoint;
begin
  if StartIndex < 0 then
    StartIndex := 0;
  if StartIndex >= Length(Points) then
    Exit;

  if NumPts < 0 then
    ActualCount := Length(Points) - StartIndex
  else
    ActualCount := Min(NumPts, Length(Points) - StartIndex);

  if ActualCount <= 0 then
    Exit;

  SetLength(Tmp, ActualCount);
  for I := 0 to ActualCount - 1 do
    Tmp[I] := Points[StartIndex + I];

  DoPolyline(Tmp);
end;

procedure TGL2DCanvas.Polyline(Points: PPoint; NumPts: Integer);
var
  Tmp: array of TPoint;
  I: Integer;
begin
  if (Points = nil) or (NumPts <= 0) then
    Exit;

  SetLength(Tmp, NumPts);
  for I := 0 to NumPts - 1 do
    Tmp[I] := Points[I];

  DoPolyline(Tmp);
end;

procedure TGL2DCanvas.RoundRect(const Rect: TRect; RX, RY: Integer);
begin
  RoundRect(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, RX, RY);
end;

procedure TGL2DCanvas.TextRect(const ARect: TRect; X, Y: integer; const Text: string);
begin
  TextRect(ARect, X, Y, Text, Default(TTextStyle));
end;

procedure TGL2DCanvas.TextRect(ARect: TRect; X, Y: integer; const Text: string;
  const Style: TTextStyle);
var
  R: TRect;
  TW, TH: Integer;
  TX, TY: Integer;
  OldClip: TRect;
  OldClipping: Boolean;
begin
  R := NormalizeRect(ARect);
  TW := TextWidth(Text);
  TH := TextHeight(Text);

  TX := X;
  TY := Y;

  if Style.Alignment = taCenter then
    TX := R.Left + ((R.Right - R.Left) - TW) div 2
  else
  if Style.Alignment = taRightJustify then
    TX := R.Right - TW;

  if Style.Layout = tlCenter then
    TY := R.Top + ((R.Bottom - R.Top) - TH) div 2
  else
  if Style.Layout = tlBottom then
    TY := R.Bottom - TH;

  OldClip := FClipRect;
  OldClipping := FClipping;
  try
    FClipRect := R;
    FClipping := True;
    if FDrawing then
      ApplyScissor;
    TextOut(TX, TY, Text);
  finally
    FClipRect := OldClip;
    FClipping := OldClipping;
    if FDrawing then
      ApplyScissor;
  end;
end;

function TGL2DCanvas.TextExtent(const Text: string): TSize;
begin
  Result.cx := TextWidth(Text);
  Result.cy := TextHeight(Text);
end;

function TGL2DCanvas.TextHeight(const Text: string): Integer;
begin
  Result := DoGetTextHeight(Text);
end;

function TGL2DCanvas.TextWidth(const Text: string): Integer;
begin
  Result := DoGetTextWidth(Text);
end;

function TGL2DCanvas.TextFitInfo(const Text: string; MaxWidth: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  if MaxWidth <= 0 then
    Exit;

  for I := 1 to Length(Text) do
  begin
    if TextWidth(Copy(Text, 1, I)) > MaxWidth then
      Exit(I - 1);
  end;

  Result := Length(Text);
end;

function TGL2DCanvas.HandleAllocated: boolean;
begin
  Result := Assigned(FControl) and FControl.HandleAllocated;
end;

function TGL2DCanvas.GetUpdatedHandle(ReqState: TCanvasState): HDC;
begin
  if HandleAllocated then
    Result := FControl.Handle
  else
    Result := 0;
end;

end.
