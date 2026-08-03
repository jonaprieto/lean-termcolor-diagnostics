/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics

open TermColor
open TermColor.Diagnostics

private def check (name : String) (condition : Bool) : Option String :=
  if condition then none else some name

private def source : Sources :=
  #[Source.named "input.txt" "a\tb\n界e\u0301\nlast"]

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

private def many : List Diagnostic := [simple, ranged]

private def gallerySources : Sources :=
  #[source[0]!, Source.named "main.lean" "first\n\t界\nlast"]

private def multiline : Diagnostic :=
  (Diagnostic.error "multiline failure")
    |>.withLabel (Label.primary (Span.range 1 0 15) "check this block")
    |>.withLabel (Label.secondary (Span.range 0 0 3) "related input")

private def loaded : Diagnostic := Diagnostic.info "configuration loaded"

private def plain (diagnostic : Diagnostic) : String :=
  (render source diagnostic { width := 80 }).plainText

private def checks : List (Option String) :=
  [ check "point span has zero length" (Span.length (Span.point 0 4) == 0)
  , check "range span has length" (Span.length (Span.range 0 2 5) == 3)
  , check "source has three lines" ((Source.lines (source[0]!)).length == 3)
  , check "simple title is rendered" ((plain simple).contains "bad input")
  , check "diagnostic code is rendered" ((plain simple).contains "[E1]")
  , check "primary label is rendered" ((plain simple).contains "unexpected character")
  , check "secondary label is rendered" ((plain ranged).contains "related text")
  , check "note is rendered" ((plain ranged).contains "this is only a warning")
  , check "help is rendered" ((plain ranged).contains "remove the extra value")
  , check "unicode source is preserved" ((plain ranged).contains "界e\u0301")
  , check "warning severity is rendered" ((plain ranged).startsWith "warning")
  , check "info severity is rendered"
      (((render source loaded).plainText).startsWith "info")
  , check "tabs expand to configured stops"
      (((render source simple { tabWidth := 4 }).plainText).contains "a   b")
  , check "multiline spans render every touched line"
      (let output := (render gallerySources multiline { contextLines := 0 }).plainText
       output.contains "main.lean" && output.contains "2 |" && output.contains "3 |")
  , check "multiple sources retain their source name"
      (let output := (render gallerySources multiline { contextLines := 0 }).plainText
       output.contains "main.lean" && output.contains "input.txt")
  , check "plain output has no escape" (!(plain ranged).contains "\u001b[")
  , check "ascii marker is rendered"
      (((render source simple { unicode := false }).plainText).contains "|")
  , check "multiple diagnostics have a blank line"
      (((renderMany source many).plainText).contains "\n\n")
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
