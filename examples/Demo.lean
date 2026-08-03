/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics
import TermColor.Detect

open TermColor
open TermColor.Diagnostics

private def source : Sources :=
  #[Source.named "config.toml" "timeout = 2x\nworkers = 4"]

private def diagnostic : Diagnostic :=
  (Diagnostic.error "invalid duration")
    |>.withCode "E1001"
    |>.withLabel (Label.primary (Span.range 0 10 12) "expected a duration")
    |>.withNote "durations use a number followed by s, m, or h"
    |>.withHelp "try timeout = 2m"

private def render (unicode : Bool) (scheme : ColorScheme) : String :=
  Text.render RenderTarget.trueColor
    (TermColor.Diagnostics.render source diagnostic { width := 72, unicode } scheme)

def main : IO Unit := do
  IO.print (render true ColorScheme.catppuccin)
  IO.print "\n"
  IO.print (render false ColorScheme.monokai)
