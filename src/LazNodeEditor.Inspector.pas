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

unit LazNodeEditor.Inspector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, Forms, ExtCtrls, StdCtrls, Grids,
  Dialogs, StrUtils, Math, fpjson,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes,
  LazNodeEditor.Graph,
  LazNodeEditor.Editor,
  LazNodeEditor.Controller;

type
  { TLazNodeInspector }
  TLazNodeInspector = class(TCustomControl)
  private
    FEditor: TLazNodeEditor;

    FScrollBox: TScrollBox;

    FGrpInfo: TGroupBox;
    FLblType: TLabel;
    FLblTypeVal: TLabel;

    FGrpBasic: TGroupBox;
    FLblTitle: TLabel;
    FTitleEdit: TEdit;
    FLblX: TLabel;
    FXEdit: TEdit;
    FLblY: TLabel;
    FYEdit: TEdit;
    FLblWidth: TLabel;
    FWidthEdit: TEdit;
    FLblHeight: TLabel;
    FHeightEdit: TEdit;

    FGrpVisual: TGroupBox;
    FLblHeaderColor: TLabel;
    FHeaderColorPanel: TPanel;
    FLblBodyColor: TLabel;
    FBodyColorPanel: TPanel;
    FCollapsedCheck: TCheckBox;

    FGrpComment: TGroupBox;
    FLblComment: TLabel;
    FCommentMemo: TMemo;

    FGrpPins: TGroupBox;
    FPinsGrid: TStringGrid;

    FGrpValues: TGroupBox;
    FValuesGrid: TStringGrid;

    FApplyButton: TButton;
    FRevertButton: TButton;

    FUpdating: boolean;

    procedure BuildControls;
    procedure BuildInfoSection(AParent: TWinControl; var ATop: integer);
    procedure BuildBasicSection(AParent: TWinControl; var ATop: integer);
    procedure BuildVisualSection(AParent: TWinControl; var ATop: integer);
    procedure BuildCommentSection(AParent: TWinControl; var ATop: integer);
    procedure BuildPinsSection(AParent: TWinControl; var ATop: integer);
    procedure BuildValuesSection(AParent: TWinControl; var ATop: integer);
    procedure BuildButtonBar(AParent: TWinControl; var ATop: integer);

    procedure ApplyClick(Sender: TObject);
    procedure RevertClick(Sender: TObject);
    procedure HeaderColorClick(Sender: TObject);
    procedure BodyColorClick(Sender: TObject);

    procedure SetEditor(AValue: TLazNodeEditor);
    procedure ClearAllSections;
    procedure ShowNoSelection;
    procedure ExecuteNodePropertyChange(AEditor: TLazNodeEditor; ANode: TCustomNode;
      const AOldJSON, ANewJSON: string);

    function MakeLabel(AParent: TWinControl; const AText: string;
      ALeft, ATop, AWidth: integer): TLabel;
    function MakeEdit(AParent: TWinControl; ALeft, ATop, AWidth: integer): TEdit;
    function MakeColorPanel(AParent: TWinControl;
      ALeft, ATop, AWidth: integer): TPanel;
    procedure ValuesGridSelectCell(Sender: TObject; ACol, ARow: integer;
      var CanSelect: boolean);
    function SafeClientWidth(AControl: TWinControl; ADefault: integer = 270): integer;
    function EditWidth(AParent: TWinControl; ALeft: integer): integer;
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefreshFromSelection;
    property Editor: TLazNodeEditor read FEditor write SetEditor;
  end;

implementation

constructor TLazNodeInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetInitialBounds(0, 0, 260, 600);
  FUpdating := False;
  BuildControls;
  ShowNoSelection;
end;

function TLazNodeInspector.MakeLabel(AParent: TWinControl; const AText: string;
  ALeft, ATop, AWidth: integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, 18);
  Result.Caption := AText;
  Result.Anchors := [akLeft, akTop];
end;

function TLazNodeInspector.MakeEdit(AParent: TWinControl;
  ALeft, ATop, AWidth: integer): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, 22);
  Result.Anchors := [akLeft, akTop, akRight];
end;

function TLazNodeInspector.MakeColorPanel(AParent: TWinControl;
  ALeft, ATop, AWidth: integer): TPanel;
begin
  Result := TPanel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, 22);
  Result.Anchors := [akLeft, akTop, akRight];
  Result.BevelOuter := bvLowered;
  Result.Cursor := crHandPoint;
end;

procedure TLazNodeInspector.ValuesGridSelectCell(Sender: TObject;
  ACol, ARow: integer; var CanSelect: boolean);
begin
  if (ARow > 0) and (ACol = 2) then
    FValuesGrid.Options := FValuesGrid.Options + [goEditing]
  else
    FValuesGrid.Options := FValuesGrid.Options - [goEditing];

  CanSelect := True;
end;

function TLazNodeInspector.SafeClientWidth(AControl: TWinControl;
  ADefault: integer): integer;
begin
  Result := AControl.ClientWidth;

  if Result <= 20 then
    Result := AControl.Width;

  if Result <= 20 then
    Result := ADefault;
end;

function TLazNodeInspector.EditWidth(AParent: TWinControl; ALeft: integer): integer;
begin
  Result := SafeClientWidth(AParent) - ALeft - 10;
  if Result < 40 then
    Result := 40;
end;

procedure TLazNodeInspector.ClearAllSections;
begin
  FLblTypeVal.Caption := '—';

  FTitleEdit.Text := '';
  FXEdit.Text := '';
  FYEdit.Text := '';
  FWidthEdit.Text := '';
  FHeightEdit.Text := '';

  FHeaderColorPanel.Color := clBtnFace;
  FBodyColorPanel.Color := clBtnFace;
  FCollapsedCheck.Checked := False;

  FCommentMemo.Text := '';

  FPinsGrid.RowCount := 1;
  if FPinsGrid.ColCount >= 4 then
  begin
    FPinsGrid.Cells[0, 0] := 'Name';
    FPinsGrid.Cells[1, 0] := 'Dir';
    FPinsGrid.Cells[2, 0] := 'Type';
    FPinsGrid.Cells[3, 0] := 'Kind';
  end;

  FValuesGrid.RowCount := 1;
  if FValuesGrid.ColCount >= 3 then
  begin
    FValuesGrid.Cells[0, 0] := 'Name';
    FValuesGrid.Cells[1, 0] := 'Kind';
    FValuesGrid.Cells[2, 0] := 'Value';
  end;
end;

procedure TLazNodeInspector.ShowNoSelection;
begin
  FUpdating := True;
  try
    ClearAllSections;
    FLblTypeVal.Caption := '(no selection)';
    FApplyButton.Enabled := False;
    FRevertButton.Enabled := False;
  finally
    FUpdating := False;
  end;
end;

procedure TLazNodeInspector.SetEditor(AValue: TLazNodeEditor);
begin
  if FEditor = AValue then
    Exit;

  FEditor := AValue;
  RefreshFromSelection;
end;

procedure TLazNodeInspector.ExecuteNodePropertyChange(AEditor: TLazNodeEditor;
  ANode: TCustomNode; const AOldJSON, ANewJSON: string);
begin
  if (AEditor = nil) or (ANode = nil) then
    Exit;

  if AOldJSON = ANewJSON then
    Exit;

  if AEditor.Controller <> nil then
    AEditor.Controller.ExecuteCommand(
      TChangeNodePropertyCommand.Create(AEditor.Graph, ANode, AOldJSON, ANewJSON))
  else if AEditor.Graph <> nil then
    AEditor.Graph.ExecuteCommand(
      TChangeNodePropertyCommand.Create(AEditor.Graph, ANode, AOldJSON, ANewJSON));
end;

procedure TLazNodeInspector.RefreshFromSelection;
var
  N: TCustomNode;
  i: integer;
  P: TNodePin;
  V: TNodeValue;
  VStr: string;
  RowIndex: integer;
begin
  if (FEditor = nil) or (FEditor.SelectedNodeCount <> 1) then
  begin
    ShowNoSelection;
    Exit;
  end;

  N := FEditor.GetSelectedNode(0);
  if N = nil then
  begin
    ShowNoSelection;
    Exit;
  end;

  FUpdating := True;
  try
    ClearAllSections;

    FLblTypeVal.Caption := N.NodeType;

    FTitleEdit.Text := N.Title;
    FXEdit.Text := FormatFloat('0.##', N.X);
    FYEdit.Text := FormatFloat('0.##', N.Y);
    FWidthEdit.Text := IntToStr(N.Width);
    FHeightEdit.Text := IntToStr(N.Height);

    FHeaderColorPanel.Color := N.HeaderColor;
    FBodyColorPanel.Color := N.BodyColor;
    FCollapsedCheck.Checked := N.Collapsed;

    FCommentMemo.Text := N.CommentText;

    FPinsGrid.RowCount := Max(2, 1 + N.InputCount + N.OutputCount);

    RowIndex := 1;
    for i := 0 to N.InputCount - 1 do
    begin
      P := N.GetInput(i);
      if P = nil then
        Continue;

      FPinsGrid.Cells[0, RowIndex] := P.EffectiveDisplayName;
      FPinsGrid.Cells[1, RowIndex] := 'In';

      if P.PinType <> nil then
        FPinsGrid.Cells[2, RowIndex] := P.PinType.TypeId
      else
        FPinsGrid.Cells[2, RowIndex] := P.DataType;

      if P.Kind = pkExec then
        FPinsGrid.Cells[3, RowIndex] := 'exec'
      else
        FPinsGrid.Cells[3, RowIndex] := 'data';

      Inc(RowIndex);
    end;

    for i := 0 to N.OutputCount - 1 do
    begin
      P := N.GetOutput(i);
      if P = nil then
        Continue;

      FPinsGrid.Cells[0, RowIndex] := P.EffectiveDisplayName;
      FPinsGrid.Cells[1, RowIndex] := 'Out';

      if P.PinType <> nil then
        FPinsGrid.Cells[2, RowIndex] := P.PinType.TypeId
      else
        FPinsGrid.Cells[2, RowIndex] := P.DataType;

      if P.Kind = pkExec then
        FPinsGrid.Cells[3, RowIndex] := 'exec'
      else
        FPinsGrid.Cells[3, RowIndex] := 'data';

      Inc(RowIndex);
    end;

    if N.ValueCount > 0 then
    begin
      FValuesGrid.RowCount := 1 + N.ValueCount;

      for i := 0 to N.ValueCount - 1 do
      begin
        V := N.GetValue(i);
        if V = nil then
          Continue;

        FValuesGrid.Cells[0, i + 1] := V.Name;
        FValuesGrid.Cells[1, i + 1] := NodeValueKindToStr(V.Kind);

        case V.Kind of
          nvkFloat:
            VStr := FormatFloat('0.######', V.FloatValue);
          nvkInteger:
            VStr := IntToStr(V.IntegerValue);
          nvkString:
            VStr := V.StringValue;
          nvkBoolean:
            if V.BooleanValue then
              VStr := 'true'
            else
              VStr := 'false';
          nvkJSON:
            VStr := V.JSONValue;
        else
          VStr := '';
        end;

        FValuesGrid.Cells[2, i + 1] := VStr;
      end;
    end
    else
      FValuesGrid.RowCount := 1;

    FApplyButton.Enabled := True;
    FRevertButton.Enabled := True;
  finally
    FUpdating := False;
  end;
end;

procedure TLazNodeInspector.HeaderColorClick(Sender: TObject);
var
  D: TColorDialog;
begin
  if (FEditor = nil) or (FEditor.SelectedNodeCount <> 1) then
    Exit;

  D := TColorDialog.Create(nil);
  try
    D.Color := FHeaderColorPanel.Color;
    if D.Execute then
      FHeaderColorPanel.Color := D.Color;
  finally
    D.Free;
  end;
end;

procedure TLazNodeInspector.BodyColorClick(Sender: TObject);
var
  D: TColorDialog;
begin
  if (FEditor = nil) or (FEditor.SelectedNodeCount <> 1) then
    Exit;

  D := TColorDialog.Create(nil);
  try
    D.Color := FBodyColorPanel.Color;
    if D.Execute then
      FBodyColorPanel.Color := D.Color;
  finally
    D.Free;
  end;
end;

procedure TLazNodeInspector.ApplyClick(Sender: TObject);
var
  N: TCustomNode;
  OldObj, NewObj: TJSONObject;
  OldJSON, NewJSON: string;
  i: integer;
  V: TNodeValue;
  VStr: string;
begin
  if FUpdating then
    Exit;

  if (FEditor = nil) or (FEditor.SelectedNodeCount <> 1) then
    Exit;

  N := FEditor.GetSelectedNode(0);
  if N = nil then
    Exit;

  OldObj := TJSONObject.Create;
  try
    N.SaveToJSON(OldObj);
    OldJSON := OldObj.AsJSON;
  finally
    OldObj.Free;
  end;

  N.Title := FTitleEdit.Text;
  N.X := StrToFloatDef(FXEdit.Text, N.X);
  N.Y := StrToFloatDef(FYEdit.Text, N.Y);
  N.Width := StrToIntDef(FWidthEdit.Text, N.Width);
  N.Height := StrToIntDef(FHeightEdit.Text, N.Height);

  N.HeaderColor := FHeaderColorPanel.Color;
  N.BodyColor := FBodyColorPanel.Color;
  N.Collapsed := FCollapsedCheck.Checked;

  N.CommentText := FCommentMemo.Text;

  for i := 0 to N.ValueCount - 1 do
  begin
    if (i + 1) >= FValuesGrid.RowCount then
      Continue;

    V := N.GetValue(i);
    if V = nil then
      Continue;

    VStr := Trim(FValuesGrid.Cells[2, i + 1]);

    case V.Kind of
      nvkFloat:
        V.FloatValue := StrToFloatDef(VStr, V.FloatValue);
      nvkInteger:
        V.IntegerValue := StrToInt64Def(VStr, V.IntegerValue);
      nvkString:
        V.StringValue := VStr;
      nvkBoolean:
        V.BooleanValue := SameText(VStr, 'true') or (VStr = '1');
      nvkJSON:
        V.JSONValue := VStr;
    end;
  end;

  NewObj := TJSONObject.Create;
  try
    N.SaveToJSON(NewObj);
    NewJSON := NewObj.AsJSON;
  finally
    NewObj.Free;
  end;

  ExecuteNodePropertyChange(FEditor, N, OldJSON, NewJSON);

  if Assigned(FEditor.OnNodeChanged) then
    FEditor.OnNodeChanged(FEditor, N);

  FEditor.Invalidate;
  RefreshFromSelection;
end;

procedure TLazNodeInspector.RevertClick(Sender: TObject);
begin
  RefreshFromSelection;
end;

procedure TLazNodeInspector.BuildControls;
var
  YPos: integer;
begin
  FScrollBox := TScrollBox.Create(Self);
  FScrollBox.Parent := Self;
  FScrollBox.Align := alClient;
  FScrollBox.BorderStyle := bsNone;
  FScrollBox.HorzScrollBar.Visible := False;
  FScrollBox.VertScrollBar.Tracking := True;

  YPos := 6;

  BuildInfoSection(FScrollBox, YPos);
  BuildBasicSection(FScrollBox, YPos);
  BuildVisualSection(FScrollBox, YPos);
  BuildCommentSection(FScrollBox, YPos);
  BuildPinsSection(FScrollBox, YPos);
  BuildValuesSection(FScrollBox, YPos);
  BuildButtonBar(FScrollBox, YPos);
end;

procedure TLazNodeInspector.BuildInfoSection(AParent: TWinControl; var ATop: integer);
const
  LW = 70;
  EX = 78;
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  ROW_H = 28;
var
  GH: integer;
begin
  GH := CAPTION_H + ROW_H + 8;

  FGrpInfo := TGroupBox.Create(Self);
  FGrpInfo.Parent := AParent;
  FGrpInfo.Caption := 'Node Info';
  FGrpInfo.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
  );
  FGrpInfo.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  FLblType := MakeLabel(FGrpInfo, 'Type:', 8, CAPTION_H div 2, LW);

  FLblTypeVal := TLabel.Create(Self);
  FLblTypeVal.Parent := FGrpInfo;
  FLblTypeVal.SetBounds(
    EX,
    CAPTION_H div 2,
    EditWidth(FGrpInfo, EX),
    20
  );
  FLblTypeVal.Anchors := [akLeft, akTop, akRight];
  FLblTypeVal.Caption := '—';
  FLblTypeVal.Font.Style := [fsBold];
end;

procedure TLazNodeInspector.BuildBasicSection(AParent: TWinControl; var ATop: integer);
const
  LW = 52;
  EX = 64;
  ROW = 40;
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  BOTTOM_PAD = 10;
var
  EW: integer;
  GH: integer;
  Y: integer;
begin
  GH := CAPTION_H + ROW * 5 + BOTTOM_PAD;

  FGrpBasic := TGroupBox.Create(Self);
  FGrpBasic.Parent := AParent;
  FGrpBasic.Caption := 'Transform';
  FGrpBasic.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
  );
  FGrpBasic.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  EW := EditWidth(FGrpBasic, EX);
  Y := CAPTION_H;

  FLblTitle := MakeLabel(FGrpBasic, 'Title:', 8, Y + 4, LW);
  FTitleEdit := MakeEdit(FGrpBasic, EX, Y, EW);
  Inc(Y, ROW);

  FLblX := MakeLabel(FGrpBasic, 'X:', 8, Y + 4, LW);
  FXEdit := MakeEdit(FGrpBasic, EX, Y, EW);
  Inc(Y, ROW);

  FLblY := MakeLabel(FGrpBasic, 'Y:', 8, Y + 4, LW);
  FYEdit := MakeEdit(FGrpBasic, EX, Y, EW);
  Inc(Y, ROW);

  FLblWidth := MakeLabel(FGrpBasic, 'Width:', 8, Y + 4, LW);
  FWidthEdit := MakeEdit(FGrpBasic, EX, Y, EW);
  Inc(Y, ROW);

  FLblHeight := MakeLabel(FGrpBasic, 'Height:', 8, Y + 4, LW);
  FHeightEdit := MakeEdit(FGrpBasic, EX, Y, EW);
end;

procedure TLazNodeInspector.BuildVisualSection(AParent: TWinControl; var ATop: integer);
const
  LW = 90;
  EX = 100;
  ROW = 40;
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  BOTTOM_PAD = 10;
var
  EW: integer;
  GH: integer;
  Y: integer;
begin
  GH := CAPTION_H + ROW * 3 + BOTTOM_PAD;

  FGrpVisual := TGroupBox.Create(Self);
  FGrpVisual.Parent := AParent;
  FGrpVisual.Caption := 'Visual';
  FGrpVisual.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
  );
  FGrpVisual.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  EW := EditWidth(FGrpVisual, EX);
  Y := CAPTION_H;

  FLblHeaderColor := MakeLabel(FGrpVisual, 'Header Color:', 8, Y + 4, LW);
  FHeaderColorPanel := MakeColorPanel(FGrpVisual, EX, Y, EW);
  FHeaderColorPanel.OnClick := @HeaderColorClick;
  Inc(Y, ROW);

  FLblBodyColor := MakeLabel(FGrpVisual, 'Body Color:', 8, Y + 4, LW);
  FBodyColorPanel := MakeColorPanel(FGrpVisual, EX, Y, EW);
  FBodyColorPanel.OnClick := @BodyColorClick;
  Inc(Y, ROW);

  FCollapsedCheck := TCheckBox.Create(Self);
  FCollapsedCheck.Parent := FGrpVisual;
  FCollapsedCheck.SetBounds(
    8,
    Y + 2,
    SafeClientWidth(FGrpVisual) - 16,
    22
  );
  FCollapsedCheck.Caption := 'Collapsed';
  FCollapsedCheck.Anchors := [akLeft, akTop, akRight];
end;

procedure TLazNodeInspector.BuildCommentSection(AParent: TWinControl;
  var ATop: integer);
const
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  MEMO_H = 50;
  BOTTOM_PAD = 10;
var
  GH: integer;
begin
  GH := CAPTION_H + MEMO_H + (BOTTOM_PAD * 2);

  FGrpComment := TGroupBox.Create(Self);
  FGrpComment.Parent := AParent;
  FGrpComment.Caption := 'Comment';
  FGrpComment.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
  );
  FGrpComment.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  FCommentMemo := TMemo.Create(Self);
  FCommentMemo.Parent := FGrpComment;
  FCommentMemo.SetBounds(
    8,
    CAPTION_H div 2,
    SafeClientWidth(FGrpComment) - 16,
    MEMO_H
  );
  FCommentMemo.Anchors := [akLeft, akTop, akRight];
  FCommentMemo.ScrollBars := ssVertical;
  FCommentMemo.WordWrap := True;
end;

procedure TLazNodeInspector.BuildPinsSection(AParent: TWinControl; var ATop: integer);
const
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  GRID_H = 100;
  BOTTOM_PAD = 10;
var
  GH: integer;
begin
  GH := CAPTION_H + GRID_H + (BOTTOM_PAD * 2);

  FGrpPins := TGroupBox.Create(Self);
  FGrpPins.Parent := AParent;
  FGrpPins.Caption := 'Pins';
  FGrpPins.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
  );
  FGrpPins.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  FPinsGrid := TStringGrid.Create(Self);
  FPinsGrid.Parent := FGrpPins;
  FPinsGrid.SetBounds(
    8,
    CAPTION_H div 2,
    SafeClientWidth(FGrpPins) - 16,
    GRID_H
  );
  FPinsGrid.Anchors := [akLeft, akTop, akRight];
  FPinsGrid.RowCount := 1;
  FPinsGrid.ColCount := 4;
  FPinsGrid.FixedRows := 1;
  FPinsGrid.FixedCols := 0;
  FPinsGrid.Options := [goRowSizing, goColSizing, goDrawFocusSelected,
    goRowSelect, goThumbTracking];
  FPinsGrid.ScrollBars := ssVertical;
  FPinsGrid.DefaultRowHeight := 20;
  FPinsGrid.Cells[0, 0] := 'Name';
  FPinsGrid.Cells[1, 0] := 'Dir';
  FPinsGrid.Cells[2, 0] := 'Type';
  FPinsGrid.Cells[3, 0] := 'Kind';
  FPinsGrid.ColWidths[0] := 80;
  FPinsGrid.ColWidths[1] := 42;
  FPinsGrid.ColWidths[2] := 60;
  FPinsGrid.ColWidths[3] := 44;
end;

procedure TLazNodeInspector.BuildValuesSection(AParent: TWinControl; var ATop: integer);
const
  GROUP_LEFT = 4;
  GROUP_RIGHT = 8;
  CAPTION_H = 22;
  GRID_H = 90;
  BOTTOM_PAD = 10;
var
  GH: integer;
begin
  GH := CAPTION_H + GRID_H + (BOTTOM_PAD * 2);

  FGrpValues := TGroupBox.Create(Self);
  FGrpValues.Parent := AParent;
  FGrpValues.Caption := 'Values';
  FGrpValues.SetBounds(
    GROUP_LEFT,
    ATop,
    SafeClientWidth(AParent) - GROUP_RIGHT,
    GH
  );
  FGrpValues.Anchors := [akLeft, akTop, akRight];

  Inc(ATop, GH + 6);

  FValuesGrid := TStringGrid.Create(Self);
  FValuesGrid.Parent := FGrpValues;
  FValuesGrid.SetBounds(
    8,
    CAPTION_H div 2,
    SafeClientWidth(FGrpValues) - 16,
    GRID_H
  );
  FValuesGrid.Anchors := [akLeft, akTop, akRight];
  FValuesGrid.RowCount := 1;
  FValuesGrid.ColCount := 3;
  FValuesGrid.FixedRows := 1;
  FValuesGrid.FixedCols := 0;
  FValuesGrid.Options := [goRowSizing, goColSizing, goDrawFocusSelected,
    goRowSelect, goThumbTracking, goEditing];
  FValuesGrid.ScrollBars := ssVertical;
  FValuesGrid.DefaultRowHeight := 20;
  FValuesGrid.Cells[0, 0] := 'Name';
  FValuesGrid.Cells[1, 0] := 'Kind';
  FValuesGrid.Cells[2, 0] := 'Value';
  FValuesGrid.ColWidths[0] := 72;
  FValuesGrid.ColWidths[1] := 52;
  FValuesGrid.ColWidths[2] := 80;
  FValuesGrid.OnSelectCell := @ValuesGridSelectCell;
end;

procedure TLazNodeInspector.BuildButtonBar(AParent: TWinControl; var ATop: integer);
const
  LEFT_PAD = 4;
  GAP = 8;
  BUTTON_H = 30;
var
  BW: integer;
  W: integer;
begin
  W := SafeClientWidth(AParent);
  BW := (W - LEFT_PAD * 2 - GAP) div 2;

  if BW < 60 then
    BW := 60;

  FApplyButton := TButton.Create(Self);
  FApplyButton.Parent := AParent;
  FApplyButton.SetBounds(LEFT_PAD, ATop, BW, BUTTON_H);
  FApplyButton.Caption := 'Apply';
  FApplyButton.Anchors := [akLeft, akTop];
  FApplyButton.OnClick := @ApplyClick;

  FRevertButton := TButton.Create(Self);
  FRevertButton.Parent := AParent;
  FRevertButton.SetBounds(LEFT_PAD + BW + GAP, ATop, BW, BUTTON_H);
  FRevertButton.Caption := 'Revert';
  FRevertButton.Anchors := [akLeft, akTop];
  FRevertButton.OnClick := @RevertClick;

  Inc(ATop, BUTTON_H + 8);
end;

end.
