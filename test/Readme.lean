/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics
import TermColor.Detect

open TermColor
open TermColor.Diagnostics

def readmeSource : Sources :=
  #[Source.named "settings.toml" "timeout = 2x"]

def readmeDiagnostic : Diagnostic :=
  (Diagnostic.error "invalid duration")
    |>.withCode "E1001"
    |>.withLabel (Label.primary (Span.range 0 10 12) "expected a duration")
    |>.withFixIt { span := Span.range 0 10 12, replacement := "2m" }
    |>.withHelp "try timeout = 2m"

#eval Text.render RenderTarget.plain (render readmeSource readmeDiagnostic)

def main : IO Unit := pure ()
