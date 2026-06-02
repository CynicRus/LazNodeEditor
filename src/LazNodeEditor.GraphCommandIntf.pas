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
unit LazNodeEditor.GraphCommandIntf;

{$mode objfpc}{$H+}

interface

uses
  Generics.Collections, Classes, Types,
  LazNodeEditor.Types,
  LazNodeEditor.Nodes;

type

  INodeGraphCommandHost = interface
    ['{A8D1D8F1-4A47-4B3C-9F3D-0D68D1F4A001}']
    function FindNodeById(const AId: string): TCustomNode;
    function FindPinById(const AId: string): TNodePin;
    function FindLinkById(const AId: string): TNodeLink;

    function GetLinks: specialize TObjectList<TNodeLink>;
    function GetNodeRegistry(): TNodeRegistry;
    function NodesContains(ANode: TCustomNode): boolean;

    procedure AddNode(ANode: TCustomNode);
    function DetachNode(ANode: TCustomNode): boolean;
    procedure RemoveNode(ANode: TCustomNode);
    procedure AddLink(ALink: TNodeLink);
    procedure RemoveLink(ALink: TNodeLink);

    procedure GraphChanged;

    function CaptureJSONText: string;
    procedure LoadGraphFromJSONText(const S: string);
  end;

implementation


end.
