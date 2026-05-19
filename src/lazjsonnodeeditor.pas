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
unit LazJsonNodeEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, Graphics, Dialogs,
  fpjson, jsonparser, LazNodeEditor, Generics.Collections;

type
  TJSONNodeKind = (
    jnkObject,
    jnkArray,
    jnkString,
    jnkNumber,
    jnkBoolean,
    jnkNull
  );

  { TJsonNode }

  TJsonNode = class(TCustomNode)
  private
    FJsonKind: TJSONNodeKind;
  public
    JsonName: string;

    constructor Create(ATitle: string; AX, AY: single;
      AWidth: integer = 220; AHeight: integer = 120); override;

    procedure SetupPins; override;

    function AddJsonChildOutput(const AName: string): TNodePin;
    function AddJsonInput: TNodePin;
    function GetMainOutput: TNodePin;

    procedure SaveToJSON(AObj: TJSONObject); override;
    procedure LoadFromJSON(AObj: TJSONObject); override;

    property JsonKind: TJSONNodeKind read FJsonKind write FJsonKind;
  end;

  { TJsonObjectNode }

  TJsonObjectNode = class(TJsonNode)
  public
    constructor Create(ATitle: string; AX, AY: single;
      AWidth: integer = 240; AHeight: integer = 120); override;
    procedure SetupPins; override;
  end;

  { TJsonArrayNode }

  TJsonArrayNode = class(TJsonNode)
  public
    constructor Create(ATitle: string; AX, AY: single;
      AWidth: integer = 240; AHeight: integer = 120); override;
    procedure SetupPins; override;
  end;

  { TJsonStringNode }

  TJsonStringNode = class(TJsonNode)
  public
    constructor Create(ATitle: string; AX, AY: single;
      AWidth: integer = 220; AHeight: integer = 95); override;
    procedure SetupPins; override;
  end;

  { TJsonNumberNode }

  TJsonNumberNode = class(TJsonNode)
  public
    constructor Create(ATitle: string; AX, AY: single;
      AWidth: integer = 220; AHeight: integer = 95); override;
    procedure SetupPins; override;
  end;

  { TJsonBooleanNode }

  TJsonBooleanNode = class(TJsonNode)
  public
    constructor Create(ATitle: string; AX, AY: single;
      AWidth: integer = 220; AHeight: integer = 95); override;
    procedure SetupPins; override;
  end;

  { TJsonNullNode }

  TJsonNullNode = class(TJsonNode)
  public
    constructor Create(ATitle: string; AX, AY: single;
      AWidth: integer = 200; AHeight: integer = 80); override;
    procedure SetupPins; override;
  end;

  TJsonEditorChangedEvent = procedure(Sender: TObject) of object;

  { TLazJsonEditor }

  TLazJsonEditor = class(TCustomControl)
  private
    FNodeEditor: TLazNodeEditor;
    FInspector: TLazNodeInspector;
    FSplitter: TSplitter;

    FShowInspector: boolean;
    FOnChanged: TJsonEditorChangedEvent;

    procedure BuildControls;
    procedure RegisterJsonNodes;
    procedure EditorSelectionChanged(Sender: TObject);
    procedure EditorNodeChanged(Sender: TObject; ANode: TCustomNode);

    procedure SetShowInspector(AValue: boolean);

    function JsonKindToNodeType(AData: TJSONData): string;
    function CreateNodeFromJSONData(const AName: string; AData: TJSONData;
      AX, AY: single; ADepth, AIndex: integer): TJsonNode;

    procedure BuildGraphFromJSONData(AParent: TJsonNode; AData: TJSONData;
      ADepth: integer; var ARow: integer);

    function FindLinkedChildNode(AFromPin: TNodePin): TJsonNode;
    function BuildJSONFromNode(ANode: TJsonNode): TJSONData;
    function GetRootJsonNode: TJsonNode;

    procedure DoChanged;
  public
    constructor Create(AOwner: TComponent); override;

    procedure Clear;

    procedure LoadJSONText(const AText: string);
    function SaveJSONText(AFormatted: boolean = True): string;

    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string; AFormatted: boolean = True);

    property NodeEditor: TLazNodeEditor read FNodeEditor;
    property Inspector: TLazNodeInspector read FInspector;
  published
    property Align;
    property Anchors;
    property Color;
    property ShowInspector: boolean read FShowInspector write SetShowInspector default True;

    property OnChanged: TJsonEditorChangedEvent read FOnChanged write FOnChanged;
  end;

procedure Register;

implementation

function JsonKindToStr(AKind: TJSONNodeKind): string;
begin
  case AKind of
    jnkObject: Result := 'object';
    jnkArray: Result := 'array';
    jnkString: Result := 'string';
    jnkNumber: Result := 'number';
    jnkBoolean: Result := 'boolean';
    jnkNull: Result := 'null';
  else
    Result := 'null';
  end;
end;

function StrToJsonKind(const S: string): TJSONNodeKind;
begin
  if SameText(S, 'object') then
    Result := jnkObject
  else if SameText(S, 'array') then
    Result := jnkArray
  else if SameText(S, 'string') then
    Result := jnkString
  else if SameText(S, 'number') then
    Result := jnkNumber
  else if SameText(S, 'boolean') then
    Result := jnkBoolean
  else
    Result := jnkNull;
end;

function JSONTypeToJsonKind(AData: TJSONData): TJSONNodeKind;
begin
  if AData = nil then
    Exit(jnkNull);

  case AData.JSONType of
    jtObject: Result := jnkObject;
    jtArray: Result := jnkArray;
    jtString: Result := jnkString;
    jtNumber: Result := jnkNumber;
    jtBoolean: Result := jnkBoolean;
    jtNull: Result := jnkNull;
  else
    Result := jnkNull;
  end;
end;

{ TJsonNode }

constructor TJsonNode.Create(ATitle: string; AX, AY: single;
  AWidth: integer; AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'json.base';
  JsonName := '';
  FJsonKind := jnkNull;
  HeaderColor := $00D8D8D8;
  BodyColor := $00FFFFFF;
end;

procedure TJsonNode.SetupPins;
begin
  ClearPins;
end;

function TJsonNode.AddJsonInput: TNodePin;
begin
  Result := AddInputPin('In', 'json', pkData);
  Result.DisplayName := 'In';
  Result.PinType.Color := $00FFAA44;
end;

function TJsonNode.GetMainOutput: TNodePin;
begin
  if OutputCount > 0 then
    Result := GetOutput(0)
  else
    Result := AddOutputPin('Value', 'json', pkData);

  Result.PinType.Color := $00FFAA44;
end;

function TJsonNode.AddJsonChildOutput(const AName: string): TNodePin;
begin
  Result := AddOutputPin(AName, 'json', pkData);
  Result.DisplayName := AName;
  Result.PinType.Color := $00FFAA44;
end;

procedure TJsonNode.SaveToJSON(AObj: TJSONObject);
begin
  inherited SaveToJSON(AObj);
  AObj.Add('jsonName', JsonName);
  AObj.Add('jsonKind', JsonKindToStr(FJsonKind));
end;

procedure TJsonNode.LoadFromJSON(AObj: TJSONObject);
begin
  inherited LoadFromJSON(AObj);
  JsonName := AObj.Get('jsonName', '');
  FJsonKind := StrToJsonKind(AObj.Get('jsonKind', 'null'));
end;

{ TJsonObjectNode }

constructor TJsonObjectNode.Create(ATitle: string; AX, AY: single;
  AWidth: integer; AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'json.object';
  FJsonKind := jnkObject;
  HeaderColor := $00FFD28A;
end;

procedure TJsonObjectNode.SetupPins;
begin
  ClearPins;
  AddJsonInput;
  AddOutputPin('Object', 'json', pkData).PinType.Color := $00FFAA44;
end;

{ TJsonArrayNode }

constructor TJsonArrayNode.Create(ATitle: string; AX, AY: single;
  AWidth: integer; AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'json.array';
  FJsonKind := jnkArray;
  HeaderColor := $00B8D7FF;
end;

procedure TJsonArrayNode.SetupPins;
begin
  ClearPins;
  AddJsonInput;
  AddOutputPin('Array', 'json', pkData).PinType.Color := $00FFAA44;
end;

{ TJsonStringNode }

constructor TJsonStringNode.Create(ATitle: string; AX, AY: single;
  AWidth: integer; AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'json.string';
  FJsonKind := jnkString;
  HeaderColor := $00B8FFB8;
end;

procedure TJsonStringNode.SetupPins;
var
  V: TNodeValue;
begin
  ClearPins;
  AddJsonInput;
  AddOutputPin('String', 'json', pkData).PinType.Color := $00FFAA44;

  V := AddValue('value', nvkString);
  V.StringValue := '';
end;

{ TJsonNumberNode }

constructor TJsonNumberNode.Create(ATitle: string; AX, AY: single;
  AWidth: integer; AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'json.number';
  FJsonKind := jnkNumber;
  HeaderColor := $00D0A0FF;
end;

procedure TJsonNumberNode.SetupPins;
var
  V: TNodeValue;
begin
  ClearPins;
  AddJsonInput;
  AddOutputPin('Number', 'json', pkData).PinType.Color := $00FFAA44;

  V := AddValue('value', nvkFloat);
  V.FloatValue := 0;
end;

{ TJsonBooleanNode }

constructor TJsonBooleanNode.Create(ATitle: string; AX, AY: single;
  AWidth: integer; AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'json.boolean';
  FJsonKind := jnkBoolean;
  HeaderColor := $00FFFFB8;
end;

procedure TJsonBooleanNode.SetupPins;
var
  V: TNodeValue;
begin
  ClearPins;
  AddJsonInput;
  AddOutputPin('Boolean', 'json', pkData).PinType.Color := $00FFAA44;

  V := AddValue('value', nvkBoolean);
  V.BooleanValue := False;
end;

{ TJsonNullNode }

constructor TJsonNullNode.Create(ATitle: string; AX, AY: single;
  AWidth: integer; AHeight: integer);
begin
  inherited Create(ATitle, AX, AY, AWidth, AHeight);
  NodeType := 'json.null';
  FJsonKind := jnkNull;
  HeaderColor := $00CCCCCC;
end;

procedure TJsonNullNode.SetupPins;
begin
  ClearPins;
  AddJsonInput;
  AddOutputPin('Null', 'json', pkData).PinType.Color := $00FFAA44;
end;

{ TLazJsonEditor }

constructor TLazJsonEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FShowInspector := True;
  Color := clBtnFace;
  BuildControls;
  RegisterJsonNodes;
end;

procedure TLazJsonEditor.BuildControls;
begin
  FInspector := TLazNodeInspector.Create(Self);
  FInspector.Parent := Self;
  FInspector.Align := alRight;
  FInspector.Width := 300;

  FSplitter := TSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.Align := alRight;
  FSplitter.Width := 5;

  FNodeEditor := TLazNodeEditor.Create(Self);
  FNodeEditor.Parent := Self;
  FNodeEditor.Align := alClient;
  FNodeEditor.SnapToGrid := True;
  FNodeEditor.GridSize := 40;
  FNodeEditor.OnSelectionChanged := @EditorSelectionChanged;
  FNodeEditor.OnNodeChanged := @EditorNodeChanged;

  FInspector.Editor := FNodeEditor;
end;

procedure TLazJsonEditor.RegisterJsonNodes;
begin
  FNodeEditor.Graph.Registry.RegisterNodeEx(
    'json.object',
    'JSON Object',
    'JSON',
    'JSON object node.',
    'json,object,dictionary,map',
    TJsonObjectNode,
    $00FFD28A
  );

  FNodeEditor.Graph.Registry.RegisterNodeEx(
    'json.array',
    'JSON Array',
    'JSON',
    'JSON array node.',
    'json,array,list',
    TJsonArrayNode,
    $00B8D7FF
  );

  FNodeEditor.Graph.Registry.RegisterNodeEx(
    'json.string',
    'JSON String',
    'JSON',
    'JSON string value.',
    'json,string,text',
    TJsonStringNode,
    $00B8FFB8
  );

  FNodeEditor.Graph.Registry.RegisterNodeEx(
    'json.number',
    'JSON Number',
    'JSON',
    'JSON number value.',
    'json,number,float,int',
    TJsonNumberNode,
    $00D0A0FF
  );

  FNodeEditor.Graph.Registry.RegisterNodeEx(
    'json.boolean',
    'JSON Boolean',
    'JSON',
    'JSON boolean value.',
    'json,bool,boolean,true,false',
    TJsonBooleanNode,
    $00FFFFB8
  );

  FNodeEditor.Graph.Registry.RegisterNodeEx(
    'json.null',
    'JSON Null',
    'JSON',
    'JSON null value.',
    'json,null',
    TJsonNullNode,
    $00CCCCCC
  );
end;

procedure TLazJsonEditor.EditorSelectionChanged(Sender: TObject);
begin
  if FInspector <> nil then
    FInspector.RefreshFromSelection;
end;

procedure TLazJsonEditor.EditorNodeChanged(Sender: TObject; ANode: TCustomNode);
begin
  DoChanged;
end;

procedure TLazJsonEditor.DoChanged;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TLazJsonEditor.SetShowInspector(AValue: boolean);
begin
  if FShowInspector = AValue then
    Exit;

  FShowInspector := AValue;

  if FInspector <> nil then
    FInspector.Visible := FShowInspector;

  if FSplitter <> nil then
    FSplitter.Visible := FShowInspector;
end;

procedure TLazJsonEditor.Clear;
begin
  FNodeEditor.Clear;
end;

function TLazJsonEditor.JsonKindToNodeType(AData: TJSONData): string;
begin
  case JSONTypeToJsonKind(AData) of
    jnkObject: Result := 'json.object';
    jnkArray: Result := 'json.array';
    jnkString: Result := 'json.string';
    jnkNumber: Result := 'json.number';
    jnkBoolean: Result := 'json.boolean';
    jnkNull: Result := 'json.null';
  else
    Result := 'json.null';
  end;
end;

function TLazJsonEditor.CreateNodeFromJSONData(const AName: string;
  AData: TJSONData; AX, AY: single; ADepth, AIndex: integer): TJsonNode;
var
  NodeType: string;
  V: TNodeValue;
  TitleText: string;
begin
  NodeType := JsonKindToNodeType(AData);

  if AName <> '' then
    TitleText := AName
  else if ADepth = 0 then
    TitleText := 'root'
  else
    TitleText := '[' + IntToStr(AIndex) + ']';

  Result := TJsonNode(FNodeEditor.Graph.Registry.CreateNode(NodeType, AX, AY));
  Result.JsonName := AName;

  case Result.JsonKind of
    jnkObject:
      Result.Title := TitleText + ' { }';

    jnkArray:
      Result.Title := TitleText + ' [ ]';

    jnkString:
      begin
        Result.Title := TitleText + ' : string';
        V := Result.FindValue('value');
        if V <> nil then
          V.StringValue := AData.AsString;
      end;

    jnkNumber:
      begin
        Result.Title := TitleText + ' : number';
        V := Result.FindValue('value');
        if V <> nil then
          V.FloatValue := AData.AsFloat;
      end;

    jnkBoolean:
      begin
        Result.Title := TitleText + ' : boolean';
        V := Result.FindValue('value');
        if V <> nil then
          V.BooleanValue := AData.AsBoolean;
      end;

    jnkNull:
      Result.Title := TitleText + ' : null';
  end;

  FNodeEditor.AddNode(Result);
end;

procedure TLazJsonEditor.BuildGraphFromJSONData(AParent: TJsonNode;
  AData: TJSONData; ADepth: integer; var ARow: integer);
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  I: integer;
  ChildData: TJSONData;
  ChildNode: TJsonNode;
  ParentOut: TNodePin;
  ChildIn: TNodePin;
  FieldName: string;
  X, Y: single;
begin
  if (AParent = nil) or (AData = nil) then
    Exit;

  if AData.JSONType = jtObject then
  begin
    Obj := TJSONObject(AData);

    for I := 0 to Obj.Count - 1 do
    begin
      FieldName := Obj.Names[I];
      ChildData := Obj.Items[I];

      X := 80 + ADepth * 280;
      Y := 60 + ARow * 140;
      Inc(ARow);

      ChildNode := CreateNodeFromJSONData(FieldName, ChildData, X, Y, ADepth + 1, I);

      ParentOut := AParent.AddJsonChildOutput(FieldName);
      ChildIn := ChildNode.GetInput(0);

      FNodeEditor.Graph.AddLink(TNodeLink.Create(ParentOut, ChildIn));

      BuildGraphFromJSONData(ChildNode, ChildData, ADepth + 1, ARow);
    end;
  end
  else if AData.JSONType = jtArray then
  begin
    Arr := TJSONArray(AData);

    for I := 0 to Arr.Count - 1 do
    begin
      FieldName := IntToStr(I);
      ChildData := Arr.Items[I];

      X := 80 + ADepth * 280;
      Y := 60 + ARow * 140;
      Inc(ARow);

      ChildNode := CreateNodeFromJSONData(FieldName, ChildData, X, Y, ADepth + 1, I);

      ParentOut := AParent.AddJsonChildOutput(FieldName);
      ParentOut.DisplayName := '[' + IntToStr(I) + ']';

      ChildIn := ChildNode.GetInput(0);

      FNodeEditor.Graph.AddLink(TNodeLink.Create(ParentOut, ChildIn));

      BuildGraphFromJSONData(ChildNode, ChildData, ADepth + 1, ARow);
    end;
  end;
end;

procedure TLazJsonEditor.LoadJSONText(const AText: string);
var
  Data: TJSONData;
  RootNode: TJsonNode;
  Row: integer;
begin
  Clear;

  if Trim(AText) = '' then
    Exit;

  Data := GetJSON(AText);
  try
    Row := 0;

    RootNode := CreateNodeFromJSONData('root', Data, 40, 60, 0, 0);
    BuildGraphFromJSONData(RootNode, Data, 1, Row);

    FNodeEditor.FrameAll;
    DoChanged;
  finally
    Data.Free;
  end;
end;

function TLazJsonEditor.FindLinkedChildNode(AFromPin: TNodePin): TJsonNode;
var
  I: integer;
  L: TNodeLink;
begin
  Result := nil;

  if AFromPin = nil then
    Exit;

  for I := 0 to FNodeEditor.Graph.Links.Count - 1 do
  begin
    L := FNodeEditor.Graph.Links[I];

    if L.FromPin = AFromPin then
    begin
      if (L.ToPin <> nil) and (L.ToPin.OwnerNode is TJsonNode) then
        Exit(TJsonNode(L.ToPin.OwnerNode));
    end;
  end;
end;

function TLazJsonEditor.BuildJSONFromNode(ANode: TJsonNode): TJSONData;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  I: integer;
  P: TNodePin;
  ChildNode: TJsonNode;
  V: TNodeValue;
begin
  Result := nil;

  if ANode = nil then
    Exit(TJSONNull.Create);

  case ANode.JsonKind of
    jnkObject:
      begin
        Obj := TJSONObject.Create;

        for I := 1 to ANode.OutputCount - 1 do
        begin
          P := ANode.GetOutput(I);
          ChildNode := FindLinkedChildNode(P);

          if ChildNode <> nil then
            Obj.Add(P.Name, BuildJSONFromNode(ChildNode))
          else
            Obj.Add(P.Name, TJSONNull.Create);
        end;

        Result := Obj;
      end;

    jnkArray:
      begin
        Arr := TJSONArray.Create;

        for I := 1 to ANode.OutputCount - 1 do
        begin
          P := ANode.GetOutput(I);
          ChildNode := FindLinkedChildNode(P);

          if ChildNode <> nil then
            Arr.Add(BuildJSONFromNode(ChildNode))
          else
            Arr.Add(TJSONNull.Create);
        end;

        Result := Arr;
      end;

    jnkString:
      begin
        V := ANode.FindValue('value');
        if V <> nil then
          Result := TJSONString.Create(V.StringValue)
        else
          Result := TJSONString.Create('');
      end;

    jnkNumber:
      begin
        V := ANode.FindValue('value');
        if V <> nil then
          Result := TJSONFloatNumber.Create(V.FloatValue)
        else
          Result := TJSONFloatNumber.Create(0);
      end;

    jnkBoolean:
      begin
        V := ANode.FindValue('value');
        if V <> nil then
          Result := TJSONBoolean.Create(V.BooleanValue)
        else
          Result := TJSONBoolean.Create(False);
      end;

    jnkNull:
      Result := TJSONNull.Create;
  end;

  if Result = nil then
    Result := TJSONNull.Create;
end;

function TLazJsonEditor.GetRootJsonNode: TJsonNode;
var
  I: integer;
  N: TCustomNode;
begin
  Result := nil;

  for I := 0 to FNodeEditor.Graph.Nodes.Count - 1 do
  begin
    N := FNodeEditor.Graph.Nodes[I];

    if N is TJsonNode then
    begin
      if SameText(TJsonNode(N).JsonName, 'root') then
        Exit(TJsonNode(N));
    end;
  end;

  for I := 0 to FNodeEditor.Graph.Nodes.Count - 1 do
  begin
    N := FNodeEditor.Graph.Nodes[I];

    if N is TJsonNode then
      Exit(TJsonNode(N));
  end;
end;

function TLazJsonEditor.SaveJSONText(AFormatted: boolean): string;
var
  RootNode: TJsonNode;
  Data: TJSONData;
begin
  Result := '';

  RootNode := GetRootJsonNode;
  if RootNode = nil then
    Exit;

  Data := BuildJSONFromNode(RootNode);
  try
    if AFormatted then
      Result := Data.FormatJSON
    else
      Result := Data.AsJSON;
  finally
    Data.Free;
  end;
end;

procedure TLazJsonEditor.LoadFromFile(const AFileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    LoadJSONText(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TLazJsonEditor.SaveToFile(const AFileName: string; AFormatted: boolean);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := SaveJSONText(AFormatted);
    SL.SaveToFile(AFileName);
  finally
    SL.Free;
  end;
end;

procedure Register;
begin
  RegisterComponents('Custom', [TLazJsonEditor]);
end;

end.
