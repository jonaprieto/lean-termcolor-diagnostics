import TermColor.Style

/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

/-!
# TermColor.Diagnostics.Model: structured diagnostic data

Positions are UTF-8 byte offsets and spans are half-open. The model contains no terminal styles or
IO; rendering assigns styles from a `ColorScheme` and returns `TermColor.Text`. Optional fix-it
style overrides live in `FixItRenderConfig`.
-/

namespace TermColor.Diagnostics

abbrev SourceId := Nat

structure Source where
  name : String
  text : String
  rawBytes : Option (Array UInt8) := none
  /-- Optional absolute URI used for OSC-8 terminal hyperlinks. -/
  uri : Option String := none
  deriving BEq, DecidableEq, Repr, Inhabited

namespace Source

def named (name text : String) : Source := { name, text }

/-- Associate an absolute URI with a source without changing its contents. -/
def withUri (source : Source) (uri : String) : Source := { source with uri := some uri }

/-- Build a source from raw bytes, replacing invalid UTF-8 with `�` when rendered. -/
def fromBytes (name : String) (bytes : ByteArray) : Source :=
  { name, text := (String.fromUTF8? bytes).getD "�", rawBytes := some bytes.data }

def utf8Bytes (source : Source) : ByteArray :=
  match source.rawBytes with
  | some bytes => ByteArray.mk bytes
  | none => source.text.toUTF8

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

/-- One source edit suggested by a diagnostic. The span uses UTF-8 byte offsets. -/
structure FixIt where
  span : Span
  replacement : String
  message : String := ""
  deriving BEq, DecidableEq, Repr

namespace Source

/-- Apply a byte-ranged fix-it, returning none when its span is outside the source. -/
def applyFixIt (source : Source) (fixIt : FixIt) : Option Source :=
  let bytes := source.utf8Bytes
  if fixIt.span.start > fixIt.span.stop || fixIt.span.stop > bytes.size then none
  else
    let updatedBytes := bytes.extract 0 fixIt.span.start ++ fixIt.replacement.toUTF8 ++
      bytes.extract fixIt.span.stop bytes.size
    let updated := Source.fromBytes source.name updatedBytes
    match source.uri with
    | some uri => some (updated.withUri uri)
    | none => some updated

end Source

structure Diagnostic where
  severity : Severity := .error
  code : Option String := none
  title : String
  labels : List Label := []
  fixIts : List FixIt := []
  notes : List String := []
  helps : List String := []
  deriving BEq, DecidableEq, Repr

namespace Diagnostic

def error (title : String) : Diagnostic := { title }

def warning (title : String) : Diagnostic := { severity := .warning, title }

def info (title : String) : Diagnostic := { severity := .info, title }

def note (title : String) : Diagnostic := { severity := .note, title }

def help (title : String) : Diagnostic := { severity := .help, title }

def withCode (diagnostic : Diagnostic) (code : String) : Diagnostic :=
  { diagnostic with code := some code }

def withLabel (diagnostic : Diagnostic) (label : Label) : Diagnostic :=
  { diagnostic with labels := diagnostic.labels ++ [label] }

def withFixIt (diagnostic : Diagnostic) (fixIt : FixIt) : Diagnostic :=
  { diagnostic with fixIts := diagnostic.fixIts ++ [fixIt] }

def withNote (diagnostic : Diagnostic) (note : String) : Diagnostic :=
  { diagnostic with notes := diagnostic.notes ++ [note] }

def withHelp (diagnostic : Diagnostic) (help : String) : Diagnostic :=
  { diagnostic with helps := diagnostic.helps ++ [help] }

end Diagnostic

structure ReportField where
  label : String
  value : String
  deriving BEq, DecidableEq, Repr

structure Report where
  severity : Severity := .error
  code : Option String := none
  title : String
  fields : List ReportField := []
  notes : List String := []
  helps : List String := []
  deriving BEq, DecidableEq, Repr

namespace Report

def error (title : String) : Report := { title }

def warning (title : String) : Report := { severity := .warning, title }

def info (title : String) : Report := { severity := .info, title }

def withCode (report : Report) (code : String) : Report :=
  { report with code := some code }

def withField (report : Report) (label value : String) : Report :=
  { report with fields := report.fields ++ [{ label, value }] }

def withNote (report : Report) (note : String) : Report :=
  { report with notes := report.notes ++ [note] }

def withHelp (report : Report) (help : String) : Report :=
  { report with helps := report.helps ++ [help] }

end Report

/-- Textual choices for rendering suggested source edits. Colors come from the supplied scheme. -/
structure FixItRenderConfig where
  heading : String := "suggested change"
  messageSeparator : String := ": "
  removedPrefix : String := "- "
  addedPrefix : String := "+ "
  contextPrefix : String := "  "
  headingStyle : Option Style := none
  removedStyle : Option Style := none
  addedStyle : Option Style := none
  contextStyle : Option Style := none
  deriving BEq, DecidableEq, Repr, Inhabited

structure RenderConfig where
  width : Nat := 80
  tabWidth : Nat := 4
  contextLines : Nat := 1
  unicode : Bool := true
  /-- Attach source-location hyperlinks when a source has a URI. -/
  hyperlinks : Bool := true
  fixIt : FixItRenderConfig := {}
  deriving BEq, DecidableEq, Repr, Inhabited

abbrev Sources := Array Source

end TermColor.Diagnostics
