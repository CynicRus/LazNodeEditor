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
unit LazNodeEditor.GraphIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, Types,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes;

type
  INodeGraphView = interface
    ['{7D1D0A68-5D7E-4A6D-8D41-2A66A2C1D901}']
    function GetDefaultLinkDrawStyle: TLinkDrawStyle;
    function GetNodeCount: integer;
    function GetNode(AIndex: integer): TCustomNode;

    function StructureVersion: QWord;
    function QueryNodes(const R: TRectF; AList: TFPList): integer;
    function QueryLinks(const R: TRectF; AList: TFPList): integer;
    function QueryNodesAtPoint(const P: TPointF; Radius: single;
      AList: TFPList): integer;
    function QueryLinksAtPoint(const P: TPointF; Radius: single;
      AList: TFPList): integer;
    procedure NotifyNodeGeometryChanged(ANode: TCustomNode);
    procedure NotifyLinkGeometryChanged(ALink: TNodeLink);

    property DefaultLinkDrawStyle: TLinkDrawStyle read GetDefaultLinkDrawStyle;
    property NodeCount: integer read GetNodeCount;
    property Nodes[AIndex: integer]: TCustomNode read GetNode;
  end;



implementation


end.
