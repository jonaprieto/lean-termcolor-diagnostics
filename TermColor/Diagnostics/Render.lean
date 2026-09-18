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

private
def spaces
    (count : Nat)
    : String :=
  String.ofList (List.replicate count ' ')

private
def repeatChar
    (character : Char)
    (count : Nat)
    : String :=
  String.ofList (List.replicate count character)

private
def padLeft
    (width : Nat)
    (text : String)
    : String :=
  spaces (width - text.length) ++ text

private
def padRight
    (width : Nat)
    (text : String)
    : String :=
  text ++ spaces (width - text.length)

private
def severityName
    : Severity →
      String
  | .error => "error"
  | .warning => "warning"
  | .info => "info"
  | .note => "note"
  | .help => "help"

private
def severityColor
    (scheme : ColorScheme)
    : Severity →
      Color
  | .error => scheme.red
  | .warning => scheme.yellow
  | .info => scheme.blue
  | .note => scheme.comment
  | .help => scheme.green

private
def severityStyle
    (scheme : ColorScheme)
    (severity : Severity)
    : Style :=
  Style.bold <+> Style.fg (severityColor scheme severity)

private
def gutterStyle
    (scheme : ColorScheme)
    : Style :=
  Style.fg scheme.comment

private
def labelStyle
    (scheme : ColorScheme)
    (severity : Severity)
    (kind : LabelKind)
    : Style :=
  match kind with
  | .primary => Style.bold <+> Style.fg (severityColor scheme severity)
  | .secondary => Style.fg scheme.blue

private
def decoration
    : LabelKind →
      Char
  | .primary => '^'
  | .secondary => '~'

private
def gutter
    (unicode : Bool)
    : String :=
  if unicode then "│" else "|"

private
def locationArrow
    (unicode : Bool)
    : String :=
  if unicode then "╰─>" else "-->"

private structure SourceView where
  source : Source
  bytes : ByteArray
  lines : List Line

private
def sourceView
    (source : Source)
    : SourceView :=
  let bytes := source.utf8Bytes
  { source, bytes, lines := Source.lines source }

private
def lineAt
    (view : SourceView)
    (offset : Nat)
    : Option Line :=
  let safeOffset := min offset view.bytes.size
  view.lines.find? fun line => line.byteStart ≤ safeOffset && safeOffset ≤ line.byteEnd

private
def prefixText
    (view : SourceView)
    (line : Line)
    (offset : Nat)
    : String :=
  let stop := min (max offset line.byteStart) line.byteEnd
  Source.decodePrefix (view.bytes.extract line.byteStart stop)

private
def displayColumn
    (view : SourceView)
    (line : Line)
    (offset tabWidth : Nat)
    : Nat :=
  Layout.stringWidthWithTabs tabWidth (prefixText view line offset)

private
def lineTouches
    (line : Line)
    (span : Span)
    : Bool :=
  if span.start == span.stop then
    line.byteStart ≤ span.start && span.start ≤ line.byteEnd
  else
    span.start < line.byteEnd && line.byteStart < span.stop

private
def labelTouches
    (sourceId : SourceId)
    (line : Line)
    (label : Label)
    : Bool :=
  label.span.source == sourceId && lineTouches line label.span

private
def sourceLabels
    (sourceId : SourceId)
    (labels : List Label)
    : List Label :=
  labels.filter fun label => label.span.source == sourceId

private
def firstLabel
    (labels : List Label)
    : Option Label :=
  labels.head?

private
def lineNumberOf
    (view : SourceView)
    (label : Label)
    : Nat :=
  (lineAt view label.span.start).map (·.number) |>.getD 1

private
def endLineNumberOf
    (view : SourceView)
    (label : Label)
    : Nat :=
  let offset := if label.span.stop > label.span.start then label.span.stop - 1 else label.span.stop
  (lineAt view offset).map (·.number) |>.getD 1

private
def minLineNumber
    (view : SourceView)
    (labels : List Label)
    : Nat :=
  labels.foldl (fun result label => min result (lineNumberOf view label))
    (Nat.succ view.lines.length)

private
def maxLineNumber
    (view : SourceView)
    (labels : List Label)
    : Nat :=
  labels.foldl (fun result label => max result (endLineNumberOf view label)) 0

private
def lineIsShown
    (config : RenderConfig)
    (low high : Nat)
    (line : Line)
    : Bool :=
  line.number + config.contextLines ≥ low && line.number ≤ high + config.contextLines

private
def lineText
    (config : RenderConfig)
    (line : Line)
    : String :=
  Layout.expandTabs config.tabWidth line.text

private inductive DiffLine where
  | context (text : String)
  | removed (text : String)
  | added (text : String)

-- ponytail: line prefix/suffix diff keeps fix-it rendering small; extract a general diff
-- algorithm if callers need arbitrary large-document diffs.
private
def commonPrefix
    : List String →
      List String →
      List String
  | left :: rest, right :: rest' =>
      if left == right then left :: commonPrefix rest rest' else []
  | _, _ => []

private
def trailing
    (count : Nat)
    (lines : List String)
    : List String :=
  lines.drop (lines.length - min count lines.length)

private
def fixItDiffLines
    (config : RenderConfig)
    (source updated : Source)
    : List DiffLine :=
  let oldLines := (Source.lines source).map (·.text)
  let newLines := (Source.lines updated).map (·.text)
  if oldLines == newLines then []
  else
    let shared := commonPrefix oldLines newLines
    let oldRest := oldLines.drop shared.length
    let newRest := newLines.drop shared.length
    let suffix := (commonPrefix oldRest.reverse newRest.reverse).reverse
    let oldChanged := oldRest.take (oldRest.length - suffix.length)
    let newChanged := newRest.take (newRest.length - suffix.length)
    let before := (trailing config.contextLines shared).map DiffLine.context
    let after := (suffix.take config.contextLines).map DiffLine.context
    before ++ oldChanged.map DiffLine.removed ++ newChanged.map DiffLine.added ++ after

private
def fixItStyle
    (configured : Option Style)
    (fallback : Style)
    : Style :=
  configured.getD fallback

private
def fitDiffLine
    (config : RenderConfig)
    (line : Text)
    : Text :=
  Layout.truncate config.width line

private
def renderDiffLine
    (scheme : ColorScheme)
    (config : RenderConfig)
    : DiffLine →
      Text
  | .context text =>
      fitDiffLine config <| Text.styled
        (config.fixIt.contextPrefix ++ Layout.expandTabs config.tabWidth text)
        (fixItStyle config.fixIt.contextStyle (Style.fg scheme.comment))
  | .removed text =>
      fitDiffLine config <| Text.styled
        (config.fixIt.removedPrefix ++ Layout.expandTabs config.tabWidth text)
        (fixItStyle config.fixIt.removedStyle
          (Style.fg scheme.background <+> Style.bg scheme.red))
  | .added text =>
      fitDiffLine config <| Text.styled
        (config.fixIt.addedPrefix ++ Layout.expandTabs config.tabWidth text)
        (fixItStyle config.fixIt.addedStyle
          (Style.fg scheme.background <+> Style.bg scheme.green))

private
def renderFixIt
    (scheme : ColorScheme)
    (config : RenderConfig)
    (source : Source)
    (fixIt : FixIt)
    : Text :=
  match Source.applyFixIt source fixIt with
  | none => Text.empty
  | some updated =>
      let lines := fixItDiffLines config source updated
      if lines.isEmpty then Text.empty
      else
        let title := if fixIt.message.isEmpty then config.fixIt.heading
          else config.fixIt.heading ++ config.fixIt.messageSeparator ++ fixIt.message
        let heading := if title.isEmpty then Text.empty
          else Text.styled title (fixItStyle config.fixIt.headingStyle (Style.fg scheme.green))
        Layout.joinLines ([heading] ++ lines.map (renderDiffLine scheme config))

private
def renderFixIts
    (sources : Sources)
    (scheme : ColorScheme)
    (config : RenderConfig)
    (diagnostic : Diagnostic)
    : List Text :=
  diagnostic.fixIts.filterMap fun fixIt =>
    match sources[fixIt.span.source]? with
    | none => none
    | some source =>
        let rendered := renderFixIt scheme config source fixIt
        if rendered.segments.isEmpty then none else some rendered

private
def renderLine
    (scheme : ColorScheme)
    (config : RenderConfig)
    (line : Line)
    (numberWidth : Nat)
    : Text :=
  let available := max 1 (config.width - numberWidth - 3)
  let text := Layout.truncate available (Text.plain (lineText config line))
  Text.styled (padLeft numberWidth (toString line.number) ++ " " ++ gutter config.unicode ++ " ")
      (gutterStyle scheme) ++ text

private
def markerBounds
    (view : SourceView)
    (config : RenderConfig)
    (line : Line)
    (label : Label)
    : Nat × Nat :=
  let start := displayColumn view line label.span.start config.tabWidth
  let stop :=
    if label.span.start == label.span.stop then
      start + 1
    else
      max (start + 1) (displayColumn view line label.span.stop config.tabWidth)
  (start, stop)

private
def renderMarker
    (scheme : ColorScheme)
    (config : RenderConfig)
    (view : SourceView)
    (severity : Severity)
    (line : Line)
    (numberWidth : Nat)
    (label : Label)
    (showMessage : Bool)
    : Text :=
  let (start, stop) := markerBounds view config line label
  let mark := decoration label.kind
  let body := spaces start ++ repeatChar mark (stop - start)
  let message := if showMessage && !label.message.isEmpty then " " ++ label.message else ""
  Text.styled (spaces numberWidth ++ " " ++ gutter config.unicode ++ " ") (gutterStyle scheme) ++
    Text.styled body (labelStyle scheme severity label.kind) ++ Text.plain message

private
def sourceNameText
    (scheme : ColorScheme)
    (source : Source)
    : Text :=
  Text.styled source.name (Style.bold <+> Style.fg scheme.cyan)

private
def sourceLocation
    (scheme : ColorScheme)
    (view : SourceView)
    (config : RenderConfig)
    (label : Label)
    : Text :=
  let line := lineAt view label.span.start
  let lineNumber := line.map (·.number) |>.getD 1
  let column := match line with
    | some line => displayColumn view line label.span.start config.tabWidth + 1
    | none => 1
  let target := sourceNameText scheme view.source ++ Text.plain s!":{lineNumber}:{column}"
  let target := if config.hyperlinks then
      match view.source.uri with
      | some uri => Text.hyperlink uri target
      | none => target
    else target
  Text.plain s!"  {locationArrow config.unicode} " ++ target

private
def renderSourceLine
    (scheme : ColorScheme)
    (config : RenderConfig)
    (sourceId : SourceId)
    (view : SourceView)
    (severity : Severity)
    (line : Line)
    (numberWidth : Nat)
    (labels : List Label)
    : List Text :=
  let visibleLabels := labels.filter (labelTouches sourceId line)
  let sourceText := renderLine scheme config line numberWidth
  let markers := visibleLabels.map fun label =>
    renderMarker scheme config view severity line numberWidth label
      (line.number == lineNumberOf view label)
  sourceText :: markers

private
def uniqueIds
    (labels : List Label)
    : List SourceId :=
  labels.foldl
    (fun ids label => if ids.contains label.span.source then ids else ids ++ [label.span.source]) []

private
def renderSource
    (sources : Sources)
    (scheme : ColorScheme)
    (config : RenderConfig)
    (diagnostic : Diagnostic)
    (sourceId : SourceId)
    : Text :=
  match sources[sourceId]? with
  | none => Text.empty
  | some source =>
    let view := sourceView source
    let labels := sourceLabels sourceId diagnostic.labels
    let sourceLines := view.lines
    let numberWidth := (sourceLines.map fun line => line.number).foldl
      (fun width n => max width (toString n).length) 1
    let low := minLineNumber view labels
    let high := maxLineNumber view labels
    let shown := sourceLines.filter (lineIsShown config low high)
    let location := match firstLabel labels with
      | some label => sourceLocation scheme view config label
      | none =>
          let name := sourceNameText scheme source
          let name := if config.hyperlinks then
              match source.uri with
              | some uri => Text.hyperlink uri name
              | none => name
            else name
          Text.plain s!"  {locationArrow config.unicode} " ++ name
    let body := shown.flatMap fun line =>
      renderSourceLine scheme config sourceId view diagnostic.severity line numberWidth labels
    Layout.joinLines
      ([location, Text.styled
          ((if config.unicode then "  " else "   ") ++ gutter config.unicode)
          (gutterStyle scheme)] ++ body)

private
def renderNotes
    (scheme : ColorScheme)
    (diagnostic : Diagnostic)
    : List Text :=
  let notes := diagnostic.notes.map fun note =>
    Text.styled "note" (Style.underline <+> Style.fg scheme.comment) ++
      Text.plain ": " ++ Text.plain note
  let helps := diagnostic.helps.map fun help =>
    Text.styled "help" (Style.underline <+> Style.bold <+> Style.fg scheme.green) ++
      Text.plain ": " ++ Text.plain help
  notes ++ helps

private
def renderHeader
    (scheme : ColorScheme)
    (diagnostic : Diagnostic)
    : Text :=
  let code := diagnostic.code.map (fun value => s!" [{value}]") |>.getD ""
  let style := severityStyle scheme diagnostic.severity
  Text.styled (severityName diagnostic.severity) (Style.underline <+> style) ++
    Text.styled code style ++ Text.plain (": " ++ diagnostic.title)

/-- Render one diagnostic as pure styled text. -/
def render
    (sources : Sources)
    (diagnostic : Diagnostic)
    (config : RenderConfig := {})
    (scheme : ColorScheme := ColorScheme.catppuccin) : Text :=
  let ids := uniqueIds diagnostic.labels
  let sourcesText := ids.map (renderSource sources scheme config diagnostic)
  let fixItsText := renderFixIts sources scheme config diagnostic
  Layout.joinLines
    ([renderHeader scheme diagnostic] ++ sourcesText ++ fixItsText ++ renderNotes scheme diagnostic)

/-- Render diagnostics in input order, separated by a blank line. -/
def renderMany
    (sources : Sources)
    (diagnostics : List Diagnostic)
    (config : RenderConfig := {})
    (scheme : ColorScheme := ColorScheme.catppuccin) : Text :=
  let rec join : List Text → Text
    | [] => Text.empty
    | [diagnostic] => diagnostic
    | diagnostic :: rest => diagnostic ++ Text.plain "\n\n" ++ join rest
  join (diagnostics.map fun diagnostic => render sources diagnostic config scheme)

private
def reportFieldWidth
    (fields : List ReportField)
    : Nat :=
  fields.foldl (fun width field => max width field.label.length) 0

private
def renderReportHeader
    (scheme : ColorScheme)
    (config : RenderConfig)
    (report : Report)
    : Text :=
  let code := report.code.map (fun value => s!" [{value}]") |>.getD ""
  let style := severityStyle scheme report.severity
  let header := Text.styled (severityName report.severity) (Style.underline <+> style) ++
    Text.styled code style ++ Text.plain (": " ++ report.title)
  Layout.truncate config.width header

private
def renderReportField
    (scheme : ColorScheme)
    (config : RenderConfig)
    (labelWidth : Nat)
    (field : ReportField)
    : Text :=
  let label := Text.styled (padRight labelWidth field.label)
    (Style.bold <+> Style.fg scheme.cyan)
  let value := Text.plain "  " ++ label ++ Text.plain "  " ++ Text.plain field.value
  Layout.truncate config.width value

private
def renderReportMeta
    (scheme : ColorScheme)
    (config : RenderConfig)
    (report : Report)
    : List Text :=
  let notes := report.notes.map fun note =>
    Layout.truncate config.width <| Text.styled "note"
      (Style.underline <+> Style.fg scheme.comment) ++ Text.plain ": " ++ Text.plain note
  let helps := report.helps.map fun help =>
    Layout.truncate config.width <| Text.styled "help"
      (Style.underline <+> Style.bold <+> Style.fg scheme.green) ++
        Text.plain ": " ++ Text.plain help
  notes ++ helps

/-- Render a source-free report with aligned labeled fields. -/
def renderReport
    (report : Report)
    (config : RenderConfig := {})
    (scheme : ColorScheme := ColorScheme.catppuccin) : Text :=
  let width := max 1 config.width
  let fieldWidth := reportFieldWidth report.fields
  let fields := report.fields.map (renderReportField scheme { config with width } fieldWidth)
  Layout.joinLines ([renderReportHeader scheme { config with width } report] ++ fields ++
    renderReportMeta scheme { config with width } report)

end TermColor.Diagnostics
