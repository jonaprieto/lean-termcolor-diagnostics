/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics.Source
import TermColor.ColorScheme
import TermColor.Layout

/-!
# TermColor.Diagnostics.Render: source-annotated terminal output

Rendering is pure and returns `TermColor.Text`. Terminal detection and ANSI emission remain in the
existing `TermColor.Detect` and `TermColor.Terminal` layers.
-/

namespace TermColor.Diagnostics

open TermColor
open scoped TermColor.Style

private def spaces (count : Nat) : String :=
  String.ofList (List.replicate count ' ')

private def repeatChar (character : Char) (count : Nat) : String :=
  String.ofList (List.replicate count character)

private def padLeft (width : Nat) (text : String) : String :=
  spaces (width - text.length) ++ text

private def severityName : Severity → String
  | .error => "error"
  | .warning => "warning"
  | .info => "info"
  | .note => "note"
  | .help => "help"

private def severityColor (scheme : ColorScheme) : Severity → Color
  | .error => scheme.red
  | .warning => scheme.yellow
  | .info => scheme.blue
  | .note => scheme.comment
  | .help => scheme.green

private def severityStyle (scheme : ColorScheme) (severity : Severity) : Style :=
  Style.bold <+> Style.fg (severityColor scheme severity)

private def gutterStyle (scheme : ColorScheme) : Style :=
  Style.fg scheme.comment

private def labelStyle (scheme : ColorScheme) (severity : Severity) (kind : LabelKind) : Style :=
  match kind with
  | .primary => Style.bold <+> Style.fg (severityColor scheme severity)
  | .secondary => Style.fg scheme.blue

private def decoration : LabelKind → Char
  | .primary => '^'
  | .secondary => '~'

private def gutter (unicode : Bool) : String :=
  if unicode then "│" else "|"

private def locationArrow (unicode : Bool) : String :=
  if unicode then "╰─>" else "-->"

private def sourceBytes (source : Source) : ByteArray := source.utf8Bytes

private def prefixText (source : Source) (line : Line) (offset : Nat) : String :=
  let bytes := sourceBytes source
  let stop := min (max offset line.byteStart) line.byteEnd
  match String.fromUTF8? (bytes.extract line.byteStart stop) with
  | some text => text
  | none => ""

private def displayColumn (source : Source) (line : Line) (offset tabWidth : Nat) : Nat :=
  Layout.stringWidthWithTabs tabWidth (prefixText source line offset)

private def lineTouches (line : Line) (span : Span) : Bool :=
  if span.start == span.stop then
    line.byteStart ≤ span.start && span.start ≤ line.byteEnd
  else
    span.start < line.byteEnd && line.byteStart < span.stop

private def labelTouches (sourceId : SourceId) (line : Line) (label : Label) : Bool :=
  label.span.source == sourceId && lineTouches line label.span

private def sourceLabels (sourceId : SourceId) (labels : List Label) : List Label :=
  labels.filter fun label => label.span.source == sourceId

private def firstLabel (labels : List Label) : Option Label :=
  labels.head?

private def lineNumberOf (source : Source) (label : Label) : Nat :=
  (Source.lineAt source label.span.start).map (·.number) |>.getD 1

private def endLineNumberOf (source : Source) (label : Label) : Nat :=
  let offset := if label.span.stop > label.span.start then label.span.stop - 1 else label.span.stop
  (Source.lineAt source offset).map (·.number) |>.getD 1

private def minLineNumber (source : Source) (labels : List Label) : Nat :=
  labels.foldl (fun result label => min result (lineNumberOf source label))
    (Nat.succ source.text.length)

private def maxLineNumber (source : Source) (labels : List Label) : Nat :=
  labels.foldl (fun result label => max result (endLineNumberOf source label)) 0

private def lineIsShown (source : Source) (config : RenderConfig) (labels : List Label)
    (line : Line) : Bool :=
  let low := minLineNumber source labels
  let high := maxLineNumber source labels
  line.number + config.contextLines ≥ low && line.number ≤ high + config.contextLines

private def lineText (config : RenderConfig) (line : Line) : String :=
  Layout.expandTabs config.tabWidth line.text

private def renderLine (scheme : ColorScheme) (config : RenderConfig) (line : Line)
    (numberWidth : Nat) : Text :=
  let available := max 1 (config.width - numberWidth - 3)
  let text := Layout.truncate available (Text.plain (lineText config line))
  Text.styled (padLeft numberWidth (toString line.number) ++ " " ++ gutter config.unicode ++ " ")
      (gutterStyle scheme) ++ text

private def markerBounds (source : Source) (config : RenderConfig) (line : Line) (label : Label) :
    Nat × Nat :=
  let start := displayColumn source line label.span.start config.tabWidth
  let stop :=
    if label.span.start == label.span.stop then
      start + 1
    else
      max (start + 1) (displayColumn source line label.span.stop config.tabWidth)
  (start, stop)

private def renderMarker (scheme : ColorScheme) (config : RenderConfig)
    (source : Source) (severity : Severity) (line : Line) (numberWidth : Nat)
    (label : Label) : Text :=
  let (start, stop) := markerBounds source config line label
  let mark := decoration label.kind
  let body := spaces start ++ repeatChar mark (stop - start)
  let message := if label.message.isEmpty then "" else " " ++ label.message
  Text.styled (spaces numberWidth ++ " " ++ gutter config.unicode ++ " ") (gutterStyle scheme) ++
    Text.styled body (labelStyle scheme severity label.kind) ++ Text.plain message

private def sourceLocation (source : Source) (config : RenderConfig) (label : Label) : String :=
  let line := Source.lineAt source label.span.start
  let lineNumber := line.map (·.number) |>.getD 1
  let column := match line with
    | some line => displayColumn source line label.span.start config.tabWidth + 1
    | none => 1
  s!"  {locationArrow config.unicode} {source.name}:{lineNumber}:{column}"

private def renderSourceLine (scheme : ColorScheme) (config : RenderConfig) (sourceId : SourceId)
    (source : Source) (severity : Severity) (line : Line) (numberWidth : Nat)
    (labels : List Label) : List Text :=
  let visibleLabels := labels.filter (labelTouches sourceId line)
  let sourceText := renderLine scheme config line numberWidth
  let markers := visibleLabels.map (renderMarker scheme config source severity line numberWidth)
  sourceText :: markers

private def uniqueIds (labels : List Label) : List SourceId :=
  labels.foldl
    (fun ids label => if ids.contains label.span.source then ids else ids ++ [label.span.source]) []

private def renderSource (sources : Sources) (scheme : ColorScheme) (config : RenderConfig)
    (diagnostic : Diagnostic) (sourceId : SourceId) : Text :=
  match sources[sourceId]? with
  | none => Text.empty
  | some source =>
    let labels := sourceLabels sourceId diagnostic.labels
    let sourceLines := Source.lines source
    let numberWidth := (sourceLines.map fun line => line.number).foldl
      (fun width n => max width (toString n).length) 1
    let shown := sourceLines.filter (lineIsShown source config labels)
    let location := match firstLabel labels with
      | some label => Text.plain (sourceLocation source config label)
      | none => Text.plain s!"  {locationArrow config.unicode} {source.name}"
    let body := shown.flatMap fun line =>
      renderSourceLine scheme config sourceId source diagnostic.severity line numberWidth labels
    Layout.joinLines
      ([location, Text.styled ("   " ++ gutter config.unicode) (gutterStyle scheme)] ++ body)

private def renderNotes (scheme : ColorScheme) (diagnostic : Diagnostic) : List Text :=
  let notes := diagnostic.notes.map fun note =>
    Text.styled "= note: " (Style.fg scheme.comment) ++ Text.plain note
  let helps := diagnostic.helps.map fun help =>
    Text.styled "= help: " (Style.bold <+> Style.fg scheme.green) ++ Text.plain help
  notes ++ helps

private def renderHeader (scheme : ColorScheme) (diagnostic : Diagnostic) : Text :=
  let code := diagnostic.code.map (fun value => s!" [{value}]") |>.getD ""
  Text.styled (severityName diagnostic.severity ++ code)
      (severityStyle scheme diagnostic.severity) ++ Text.plain (": " ++ diagnostic.title)

/-- Render one diagnostic as pure styled text. -/
def render (sources : Sources) (diagnostic : Diagnostic) (config : RenderConfig := {})
    (scheme : ColorScheme := ColorScheme.catppuccin) : Text :=
  let ids := uniqueIds diagnostic.labels
  let sourcesText := ids.map (renderSource sources scheme config diagnostic)
  Layout.joinLines
    ([renderHeader scheme diagnostic] ++ sourcesText ++ renderNotes scheme diagnostic)

/-- Render diagnostics in input order, separated by a blank line. -/
def renderMany (sources : Sources) (diagnostics : List Diagnostic) (config : RenderConfig := {})
    (scheme : ColorScheme := ColorScheme.catppuccin) : Text :=
  let rec join : List Text → Text
    | [] => Text.empty
    | [diagnostic] => diagnostic
    | diagnostic :: rest => diagnostic ++ Text.plain "\n\n" ++ join rest
  join (diagnostics.map fun diagnostic => render sources diagnostic config scheme)

end TermColor.Diagnostics
