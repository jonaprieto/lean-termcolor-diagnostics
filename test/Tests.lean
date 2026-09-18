/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics

open TermColor
open TermColor.Diagnostics

private
def check
    (name : String)
    (condition : Bool)
    : Option String :=
  if condition then none else some name

private def source : Sources :=
  #[Source.named "input.txt" "a\tb\n界e\u0301\nlast"]

private def linkedSource : Sources :=
  #[Source.named "input.txt" "a\tb\n界e\u0301\nlast" |>.withUri "file:///tmp/input.txt"]

private def fixSource : Sources :=
  #[Source.named "input.txt" "timeout = 2x"]

private def simple : Diagnostic :=
  (Diagnostic.error "bad input")
    |>.withCode "E1"
    |>.withLabel (Label.primary (Span.point 0 2) "unexpected character")

private def ranged : Diagnostic :=
  (Diagnostic.warning "suspicious input")
    |>.withLabel (Label.primary (Span.range 0 0 3) "check this")
    |>.withLabel (Label.secondary (Span.range 0 4 8) "related text")
    |>.withNote "this is only a warning"
    |>.withHelp "remove the extra value"

private def fixItDiagnostic : Diagnostic :=
  (Diagnostic.error "invalid duration")
    |>.withLabel (Label.primary (Span.range 0 10 12) "expected a duration")
    |>.withFixIt { span := Span.range 0 10 12, replacement := "2m", message := "use minutes" }

private def many : List Diagnostic := [simple, ranged]

private def gallerySources : Sources :=
  #[source[0]!, Source.named "main.lean" "first\n\t界\nlast"]

private def multiline : Diagnostic :=
  (Diagnostic.error "multiline failure")
    |>.withLabel (Label.primary (Span.range 1 0 15) "check this block")
    |>.withLabel (Label.secondary (Span.range 0 0 3) "related input")

private def loaded : Diagnostic := Diagnostic.info "configuration loaded"

private def wideSource : Sources :=
  #[Source.named "wide.toml" "timeout = 2x and a value wider than the terminal"]

private def wide : Diagnostic :=
  (Diagnostic.error "line is too wide")
    |>.withLabel (Label.primary (Span.range 0 10 12) "invalid value")

private def httpReport : Report :=
  (Report.error "online prover request failed")
    |>.withCode "http.transport"
    |>.withField "transport" "curl"
    |>.withField "status" "503"
    |>.withField "artifacts" ".oatp/run-123"
    |>.withHelp "inspect response.html"

private def crlf : Source := Source.named "windows.toml" "first = 1\r\nsecond = 2"

private def empty : Source := Source.named "empty.toml" ""

private def invalidUtf8 : Source :=
  Source.fromBytes "broken.txt" (ByteArray.mk #[0x66, 0x80, 0x6F])

private def customScheme : ColorScheme :=
  { ColorScheme.catppuccin with red := .rgb 255 126 95, green := .rgb 40 200 80 }

private def fixItConfig : RenderConfig :=
  { contextLines := 0
    , fixIt :=
      { heading := "edit"
        , messageSeparator := " => "
        , removedPrefix := "old: "
        , addedPrefix := "new: "
        , contextPrefix := "same: " } }

private
def plain
    (diagnostic : Diagnostic)
    : String :=
  (render source diagnostic { width := 80 }).plainText

private
def renderOne
    (source : Source)
    (diagnostic : Diagnostic)
    (config : RenderConfig := {})
    : Text :=
  render #[source] diagnostic config

private def checks : List (Option String) :=
  [ check "point span has zero length" (Span.length (Span.point 0 4) == 0)
  , check "range span has length" (Span.length (Span.range 0 2 5) == 3)
  , check "fix-it applies UTF-8 byte offsets"
      (let source := Source.named "example" "a界b"
       let fixIt : FixIt := { span := Span.range 0 1 4, replacement := "x" }
       (Source.applyFixIt source fixIt).map (·.text) == some "axb")
  , check "source has three lines" ((Source.lines (source[0]!)).length == 3)
  , check "simple title is rendered" ((plain simple).contains "bad input")
  , check "diagnostic code is rendered" ((plain simple).contains "[E1]")
  , check "severity word underlines in ANSI"
      ((Text.render RenderTarget.trueColor (render source simple)).contains "\u001b[4;1;")
  , check "primary label is rendered" ((plain simple).contains "unexpected character")
  , check "secondary label is rendered" ((plain ranged).contains "related text")
  , check "note is rendered" ((plain ranged).contains "this is only a warning")
  , check "help is rendered" ((plain ranged).contains "remove the extra value")
  , check "note and help prefixes are semantic"
      (let output := (plain ranged)
       output.contains "note: this is only a warning" &&
         output.contains "help: remove the extra value" &&
         !output.contains "= note:" && !output.contains "= help:")
  , check "note and help labels underline in ANSI"
      ((Text.render RenderTarget.trueColor (render source ranged)).contains "\u001b[4;")
  , check "unicode source is preserved" ((plain ranged).contains "界e\u0301")
  , check "warning severity is rendered" ((plain ranged).startsWith "warning")
  , check "info severity is rendered"
      (((render source loaded).plainText).startsWith "info")
  , check "tabs expand to configured stops"
      (((render source simple { tabWidth := 4 }).plainText).contains "a   b")
  , check "multiline spans render every touched line"
      (let output := (render gallerySources multiline { contextLines := 0 }).plainText
       output.contains "main.lean" && output.contains "2 │" && output.contains "3 │")
  , check "multiple sources retain their source name"
      (let output := (render gallerySources multiline { contextLines := 0 }).plainText
       output.contains "main.lean" && output.contains "input.txt")
  , check "plain output has no escape" (!(plain ranged).contains "\u001b[")
  , check "unicode frame uses a Unicode gutter"
      (((render source simple { unicode := true }).plainText).contains "│")
  , check "unicode frame uses a Unicode location arrow"
      (((render source simple { unicode := true }).plainText).contains "╰─>")
  , check "unicode connector aligns with the source gutter"
      (let output := (render source simple).plainText
       output.contains "\n  │\n1 │" && !output.contains "\n   │\n1 │")
  , check "multiline labels show their message once"
      (let output := (render gallerySources multiline { contextLines := 0 }).plainText
       (output.splitOn "check this").length == 2)
  , check "unicode multiline frame uses Unicode gutters"
      (((render gallerySources multiline { contextLines := 0 }).plainText).contains "│")
  , check "ascii marker is rendered"
      (((render source simple { unicode := false }).plainText).contains " -->")
  , check "multiple diagnostics have a blank line"
      (((renderMany source many).plainText).contains "\n\n")
  , check "CRLF line endings are excluded from source text"
      (let lines := Source.lines crlf
       lines.length == 2 && lines.map (·.text) == ["first = 1", "second = 2"])
  , check "empty sources still expose one line"
      (let lines := Source.lines empty
       lines.length == 1 && lines.all fun line => line.byteStart == 0 && line.byteEnd == 0)
  , check "invalid UTF-8 falls back to replacement text"
      ((Source.lines invalidUtf8).map (·.text) == ["�"])
  , check "invalid UTF-8 preserves later byte columns"
      (let broken := Source.fromBytes "broken.txt" (ByteArray.mk #[0x66, 0x80, 0x6F])
       let diagnostic := (Diagnostic.error "bad").withLabel
         (Label.primary (Span.point 0 2) "bad")
       let output := renderOne broken diagnostic { contextLines := 0 }
       output.plainText.contains "broken.txt:1:3")
  , check "EOF point spans render"
      (let diagnostic := (Diagnostic.info "end of file")
          |>.withLabel (Label.primary (Span.point 0 source[0]!.text.toUTF8.size) "EOF")
       (render source diagnostic { contextLines := 0 }).plainText.contains "EOF")
  , check "note severity is rendered"
      ((render #[] (Diagnostic.note "hint")).plainText.startsWith "note")
  , check "help severity is rendered"
      ((render #[] (Diagnostic.help "usage")).plainText.startsWith "help")
  , check "fix-it renders configured markers and message"
      (let output := (render fixSource fixItDiagnostic fixItConfig).plainText
       output.contains "edit => use minutes" &&
         output.contains "old: timeout = 2x" && output.contains "new: timeout = 2m")
  , check "fix-it colors come from the supplied scheme"
      (let output := Text.render RenderTarget.trueColor
          (render fixSource fixItDiagnostic fixItConfig customScheme)
       output.contains "48;2;255;126;95" && output.contains "48;2;40;200;80")
  , check "fix-it styles accept explicit overrides"
      (let config := { fixItConfig with
        fixIt := { fixItConfig.fixIt with headingStyle := some Style.reverse } }
       let output := Text.render RenderTarget.ansi16
         (render fixSource fixItDiagnostic config)
       output.contains "\u001b[7m")
  , check "fix-it renders multiline replacements"
      (let sources := #[Source.named "example" "one\nold\nthree"]
       let diagnostic := (Diagnostic.error "bad").withFixIt
         { span := Span.range 0 4 7, replacement := "new\nline" }
       let output := (render sources diagnostic { contextLines := 0 }).plainText
       output.contains "- old" && output.contains "+ new" && output.contains "+ line")
  , check "source-free report renders fields"
      (let output := (renderReport httpReport).plainText
       output.contains "error [http.transport]: online prover request failed" &&
         output.contains "transport  curl" && output.contains "status     503" &&
         output.contains "help: inspect response.html")
  , check "source-free report respects width"
      (let lines := (renderReport httpReport { width := 24 }).plainText.splitOn "\n"
       lines.all (fun line => line.length ≤ 24))
  , check "fix-it respects configured width"
      (let sources := #[Source.named "example" "old line with tail"]
       let diagnostic := (Diagnostic.error "bad").withFixIt
         { span := Span.range 0 0 3, replacement := "new line with tail" }
       let output := (render sources diagnostic { width := 10, contextLines := 0 }).plainText
       output.contains "- old lin" && !output.contains "tail")
  , check "invalid fix-it is ignored"
      (let diagnostic := (Diagnostic.error "bad").withFixIt
          { span := Span.range 0 100 101, replacement := "x" }
       !(render source diagnostic { contextLines := 0 }).plainText.contains "suggested change")
  , check "width truncation drops the tail"
      (let output := (render wideSource wide { width := 32, contextLines := 0 }).plainText
       output.contains "timeout = 2x" && !output.contains "wider than the terminal")
  , check "direct tab expansion uses display stops"
      (Layout.expandTabs 4 "a\t界" == "a   界" && Layout.stringWidthWithTabs 4 "a\t界" == 6)
  , check "ANSI-16 emits styling"
      ((Text.render RenderTarget.ansi16 (render source simple)).contains "\u001b[")
  , check "ANSI-256 emits indexed styling"
      ((Text.render RenderTarget.ansi256 (render source simple)).contains "38;5;")
  , check "true color emits RGB styling"
      ((Text.render RenderTarget.trueColor
          (render source simple (scheme := customScheme))).contains "38;2;255;126;95")
  , check "source filename uses the scheme cyan"
      ((Text.render RenderTarget.trueColor (render linkedSource simple)).contains
        "38;2;148;226;213")
  , check "source hyperlinks are enabled by default"
      (let output := Text.render (RenderTarget.withHyperlinks RenderTarget.trueColor)
          (render linkedSource simple)
       output.contains "\u001b]8;;file:///tmp/input.txt\u001b\\" &&
         output.contains "input.txt" && output.contains ":1:5" &&
         output.contains "\u001b]8;;\u001b\\")
  ]

def main : IO UInt32 := do
  let failures := checks.filterMap id
  if failures.isEmpty then
    IO.println s!"OK: {checks.length} diagnostics checks"
    return 0
  for failure in failures do
    IO.eprintln s!"FAIL: {failure}"
  IO.eprintln s!"{failures.length} diagnostics checks failed"
  return 1
