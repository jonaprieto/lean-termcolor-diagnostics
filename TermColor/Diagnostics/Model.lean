/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Layout

/-!
# TermColor.Diagnostics.Model: structured diagnostic data

Positions are UTF-8 byte offsets and spans are half-open. The model contains no terminal styles or
IO; rendering assigns styles from a `ColorScheme` and returns `TermColor.Text`.
-/

namespace TermColor.Diagnostics

abbrev SourceId := Nat

structure Source where
  name : String
  text : String
  deriving BEq, DecidableEq, Repr, Inhabited

namespace Source

def named (name text : String) : Source := { name, text }

end Source

structure Span where
  source : SourceId
  start : Nat
  stop : Nat
  deriving BEq, DecidableEq, Repr

namespace Span

def point (source : SourceId) (offset : Nat) : Span :=
  { source, start := offset, stop := offset }

def range (source : SourceId) (start stop : Nat) : Span :=
  { source, start, stop }

def length (span : Span) : Nat := span.stop - span.start

end Span

inductive Severity where
  | error
  | warning
  | info
  | note
  | help
  deriving BEq, DecidableEq, Repr, Inhabited

inductive LabelKind where
  | primary
  | secondary
  deriving BEq, DecidableEq, Repr, Inhabited

structure Label where
  span : Span
  kind : LabelKind := .primary
  message : String := ""
  deriving BEq, DecidableEq, Repr

namespace Label

def primary (span : Span) (message : String := "") : Label :=
  { span, kind := .primary, message }

def secondary (span : Span) (message : String := "") : Label :=
  { span, kind := .secondary, message }

end Label

structure Diagnostic where
  severity : Severity := .error
  code : Option String := none
  title : String
  labels : List Label := []
  notes : List String := []
  helps : List String := []
  deriving BEq, DecidableEq, Repr

namespace Diagnostic

def error (title : String) : Diagnostic := { title }

def warning (title : String) : Diagnostic := { severity := .warning, title }

def info (title : String) : Diagnostic := { severity := .info, title }

def withCode (diagnostic : Diagnostic) (code : String) : Diagnostic :=
  { diagnostic with code := some code }

def withLabel (diagnostic : Diagnostic) (label : Label) : Diagnostic :=
  { diagnostic with labels := diagnostic.labels ++ [label] }

def withNote (diagnostic : Diagnostic) (note : String) : Diagnostic :=
  { diagnostic with notes := diagnostic.notes ++ [note] }

def withHelp (diagnostic : Diagnostic) (help : String) : Diagnostic :=
  { diagnostic with helps := diagnostic.helps ++ [help] }

end Diagnostic

structure RenderConfig where
  width : Nat := 80
  tabWidth : Nat := 4
  contextLines : Nat := 1
  unicode : Bool := true
  deriving BEq, DecidableEq, Repr, Inhabited

abbrev Sources := Array Source

end TermColor.Diagnostics
