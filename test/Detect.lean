/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Detect

open TermColor

private def expected : String → Option RenderTarget
  | "plain" => some .plain
  | "ansi16" => some .ansi16
  | "ansi256" => some .ansi256
  | "truecolor" => some .trueColor
  | _ => none

def main (argv : List String) : IO UInt32 := do
  let target ← targetWithTty .auto false
  match argv with
  | [caseName] =>
      match expected caseName with
      | none =>
          IO.eprintln "usage: detect plain|ansi16|ansi256|truecolor"
          return 2
      | some wanted =>
          if target == wanted then
            IO.println s!"OK: {caseName} -> {repr target}"
            return 0
          IO.eprintln s!"FAIL: {caseName} expected {repr wanted}, got {repr target}"
          return 1
  | _ =>
      IO.eprintln "usage: detect plain|ansi16|ansi256|truecolor"
      return 2
