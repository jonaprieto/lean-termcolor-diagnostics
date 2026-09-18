/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics
import TermColor.Detect

open TermColor
open TermColor.Diagnostics

private def configSource : Source :=
  Source.named "config.toml" "timeout = 2x\nworkers = 4\nretries = 3"

private def linkedConfigSource : Source :=
  configSource.withUri "file:///tmp/config.toml"

private def codeSource : Source :=
  Source.named "src/main.lean" "fn main() {\n\tlet name = \"界e\u0301\"\n\tparse config\n}"

private def sources : Sources := #[configSource, codeSource]

private def wideSource : Source :=
  Source.named "wide.toml" "timeout = 2x and a value wider than the terminal"

private def crlfSource : Source :=
  Source.named "windows.toml" "first = 1\r\nsecond = 2"

private def emptySource : Source := Source.named "empty.toml" ""

private def invalidSource : Source :=
  Source.fromBytes "broken.toml" (ByteArray.mk #[0x66, 0x80, 0x6F])

private def invalidDuration : Diagnostic :=
  (Diagnostic.error "invalid duration")
    |>.withCode "E1001"
    |>.withLabel (Label.primary (Span.range 0 10 12) "expected a duration")
    |>.withNote "durations use a number followed by s, m, or h"
    |>.withHelp "try timeout = 2m"

private def invalidDurationFix : Diagnostic :=
  invalidDuration.withFixIt
    { span := Span.range 0 10 12, replacement := "2m", message := "use minutes" }

private def unusedWorkers : Diagnostic :=
  (Diagnostic.warning "workers setting is ignored")
    |>.withLabel (Label.primary (Span.range 0 20 24) "this value has no effect")
    |>.withLabel (Label.secondary (Span.range 0 0 12) "related timeout setting")
    |>.withHelp "remove workers or enable parallel execution"

private def sourceParseError : Diagnostic :=
  (Diagnostic.error "cannot parse source file")
    |>.withCode "E2001"
    |>.withLabel (Label.primary (Span.range 1 0 46) "expected a closing expression")
    |>.withLabel (Label.secondary (Span.range 0 0 12) "related configuration")

private def loaded : Diagnostic :=
  (Diagnostic.info "configuration loaded")
    |>.withNote "three settings were read from config.toml"

private def noteSeverity : Diagnostic := Diagnostic.note "configuration hint"

private def helpSeverity : Diagnostic := Diagnostic.help "use --help for all options"

private def widthDiagnostic : Diagnostic :=
  (Diagnostic.error "line is too wide")
    |>.withLabel (Label.primary (Span.range 0 10 12) "invalid value")

private def crlfDiagnostic : Diagnostic :=
  (Diagnostic.warning "second setting is unexpected")
    |>.withLabel (Label.primary (Span.range 0 11 17) "remove this setting")

private def emptyDiagnostic : Diagnostic :=
  (Diagnostic.error "empty configuration")
    |>.withLabel (Label.primary (Span.point 0 0) "expected a setting")

private def eofDiagnostic : Diagnostic :=
  (Diagnostic.info "end of configuration")
    |>.withLabel (Label.primary (Span.point 0 configSource.text.toUTF8.size) "end of file")

private def invalidUtf8Diagnostic : Diagnostic :=
  (Diagnostic.error "invalid UTF-8 input")
    |>.withLabel (Label.primary (Span.range 0 0 3) "replacement text is shown")

private def customScheme : ColorScheme :=
  { ColorScheme.catppuccin with
    red := .rgb 255 126 95
    comment := .rgb 125 211 252 }

private
def diagnosticText
    (target : RenderTarget)
    (diagnostic : Diagnostic)
    (config : RenderConfig)
    (scheme : ColorScheme)
    : String :=
  Text.render target (TermColor.Diagnostics.render sources diagnostic config scheme)

private
def sourceDiagnosticText
    (target : RenderTarget)
    (sourceSet : Sources)
    (diagnostic : Diagnostic)
    (config : RenderConfig)
    (scheme : ColorScheme)
    : String :=
  Text.render target (TermColor.Diagnostics.render sourceSet diagnostic config scheme)

private
def manyText
    (target : RenderTarget)
    (config : RenderConfig)
    (scheme : ColorScheme)
    : String :=
  Text.render target (renderMany sources [invalidDuration, unusedWorkers, loaded] config scheme)

private
def printSection
    (title text : String)
    : IO Unit := do
  IO.println s!"\n── {title} ──"
  IO.println text

def main : IO Unit := do
  let normal : RenderConfig := { width := 72, tabWidth := 4, contextLines := 1 }
  let compact : RenderConfig := { width := 52, tabWidth := 8, contextLines := 0 }
  let asciiCompact : RenderConfig := { compact with unicode := false }
  let narrow : RenderConfig := { width := 32, tabWidth := 4, contextLines := 0 }
  let fixItConfig : RenderConfig := { normal with contextLines := 0 }

  printSection "ERROR + CODE + NOTE + HELP / CATPPUCCIN"
    (diagnosticText .trueColor invalidDuration normal ColorScheme.catppuccin)
  printSection "FIX-IT DIFF / DEFAULT - +"
    (diagnosticText .trueColor invalidDurationFix fixItConfig ColorScheme.catppuccin)
  printSection "WARNING + PRIMARY/SECONDARY LABELS / MONOKAI"
    (diagnosticText .trueColor unusedWorkers normal ColorScheme.monokai)
  printSection "MULTI-SOURCE + MULTILINE + TAB + CJK / CATPPUCCIN"
    (diagnosticText .trueColor sourceParseError compact ColorScheme.catppuccin)
  printSection "ASCII FRAME FALLBACK"
    (diagnosticText .trueColor sourceParseError asciiCompact ColorScheme.catppuccin)
  printSection "MULTIPLE DIAGNOSTICS / DRACULA"
    (manyText .trueColor normal ColorScheme.dracula)
  printSection "UNICODE FRAME + CUSTOM SCHEME"
    (diagnosticText .trueColor invalidDuration { normal with contextLines := 0 } customScheme)
  printSection "ANSI-16 TARGET"
    (diagnosticText .ansi16 invalidDuration normal ColorScheme.catppuccin)
  printSection "ANSI-256 TARGET"
    (diagnosticText .ansi256 invalidDuration normal ColorScheme.catppuccin)
  printSection "WIDTH TRUNCATION"
    (sourceDiagnosticText .plain #[wideSource] widthDiagnostic narrow ColorScheme.catppuccin)
  printSection "CRLF + EOF POINT"
    (Text.render .plain (render #[crlfSource] crlfDiagnostic { contextLines := 0 }) ++
      "\n\n" ++ Text.render .plain (render sources eofDiagnostic { contextLines := 0 }))
  printSection "EMPTY SOURCE + NOTE/HELP SEVERITIES"
    (Text.render .plain (render #[emptySource] emptyDiagnostic { contextLines := 0 }) ++
      "\n\n" ++ Text.render .plain
        (renderMany #[] [noteSeverity, helpSeverity] { contextLines := 0 }))
  printSection "INVALID UTF-8 FALLBACK"
    (sourceDiagnosticText .plain #[invalidSource] invalidUtf8Diagnostic
      { contextLines := 0 } ColorScheme.catppuccin)
  printSection "DIRECT TAB HELPERS"
    (let tabbed := "a\t界"
     s!"expandTabs={Layout.expandTabs 4 tabbed}\nwidth={Layout.stringWidthWithTabs 4 tabbed}")
  printSection "PLAIN TARGET"
    (diagnosticText .plain invalidDuration normal ColorScheme.catppuccin)
  printSection "CLICKABLE SOURCE LOCATION / OSC-8"
    (sourceDiagnosticText (RenderTarget.withHyperlinks .trueColor)
      #[linkedConfigSource] invalidDuration { normal with hyperlinks := true }
      ColorScheme.catppuccin)
  let detected ← TermColor.target
  printSection "AUTO-DETECTED TARGET"
    (diagnosticText detected loaded normal ColorScheme.catppuccin)
