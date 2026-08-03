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

private def codeSource : Source :=
  Source.named "src/main.lean" "fn main() {\n\tlet name = \"界\"\n\tparse config\n}"

private def sources : Sources := #[configSource, codeSource]

private def invalidDuration : Diagnostic :=
  (Diagnostic.error "invalid duration")
    |>.withCode "E1001"
    |>.withLabel (Label.primary (Span.range 0 10 12) "expected a duration")
    |>.withNote "durations use a number followed by s, m, or h"
    |>.withHelp "try timeout = 2m"

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

private def diagnosticText (target : RenderTarget) (diagnostic : Diagnostic)
    (config : RenderConfig) (scheme : ColorScheme) : String :=
  Text.render target (TermColor.Diagnostics.render sources diagnostic config scheme)

private def manyText (target : RenderTarget) (config : RenderConfig)
    (scheme : ColorScheme) : String :=
  Text.render target (renderMany sources [invalidDuration, unusedWorkers, loaded] config scheme)

private def printSection (title text : String) : IO Unit := do
  IO.println s!"\n── {title} ──"
  IO.println text

def main : IO Unit := do
  let normal : RenderConfig := { width := 72, tabWidth := 4, contextLines := 1 }
  let compact : RenderConfig := { width := 52, tabWidth := 8, contextLines := 0, unicode := false }

  printSection "ERROR + CODE + NOTE + HELP / CATPPUCCIN"
    (diagnosticText .trueColor invalidDuration normal ColorScheme.catppuccin)
  printSection "WARNING + PRIMARY/SECONDARY LABELS / MONOKAI"
    (diagnosticText .trueColor unusedWorkers normal ColorScheme.monokai)
  printSection "MULTI-SOURCE + MULTILINE + TAB + CJK / CATPPUCCIN"
    (diagnosticText .trueColor sourceParseError compact ColorScheme.catppuccin)
  printSection "MULTIPLE DIAGNOSTICS / DRACULA"
    (manyText .trueColor normal ColorScheme.dracula)
  printSection "PLAIN TARGET"
    (diagnosticText .plain invalidDuration normal ColorScheme.catppuccin)
  let detected ← TermColor.target
  printSection "AUTO-DETECTED TARGET"
    (diagnosticText detected loaded normal ColorScheme.catppuccin)
