program NodeEditorDemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazopenglcontext,
  MainDemoForm, LazNodeEditor.Editor, LazNodeEditor.EngineeringNodes;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainDemoFrm, MainDemoFrm);
  Application.Run;
end.
