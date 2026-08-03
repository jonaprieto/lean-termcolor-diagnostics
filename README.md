# termcolor-diagnostics

[![CI](https://github.com/jonaprieto/lean-termcolor-diagnostics/actions/workflows/ci.yml/badge.svg)](https://github.com/jonaprieto/lean-termcolor-diagnostics/actions/workflows/ci.yml)
[![Lean 4](https://img.shields.io/badge/Lean%204-library-5f5f5f)](lean-toolchain)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

Source-annotated diagnostics and rich error reporting for Lean 4 command-line tools.

termcolor-diagnostics keeps diagnostic data separate from terminal IO. A diagnostic contains
source spans, labels, notes, and help text; rendering returns TermColor.Text, so callers can
choose plain output, ANSI-16, ANSI-256, or true color with the existing termcolor stack.

## Install

Add the package to lakefile.toml:

~~~toml
[[require]]
name = "termcolor-diagnostics"
git = "https://github.com/jonaprieto/lean-termcolor-diagnostics"
rev = "v0.1.4"
~~~

## Quick start

~~~lean
import TermColor.Diagnostics
import TermColor.Detect

open TermColor
open TermColor.Diagnostics

def sources : Sources :=
  #[Source.named "settings.toml" "timeout = 2x"]

def diagnostic : Diagnostic :=
  (Diagnostic.error "invalid duration")
    |>.withCode "E1001"
    |>.withLabel (Label.primary (Span.range 0 10 12) "expected a duration")
    |>.withHelp "try timeout = 2m"

#eval Text.render RenderTarget.plain (render sources diagnostic)
~~~

The pure renderer produces a source annotation such as:

~~~text
error [E1001]: invalid duration
  ╰─> settings.toml:1:11
   │
1 │ timeout = 2x
  │           ^^ expected a duration
   │
= help: try timeout = 2m
~~~

For terminal output, pass the returned Text to TermColor.print or
TermColor.Terminal.writeText. Terminal detection remains outside this package.

## Model

Spans use UTF-8 byte offsets and half-open ranges. This matches byte-oriented parsers such as
grip and avoids repeatedly converting parser positions into line and column pairs.

~~~lean
structure Source where
  name : String
  text : String

structure Span where
  source : SourceId
  start : Nat
  stop : Nat

structure Label where
  span : Span
  kind : LabelKind
  message : String
~~~

Line numbers and display columns are derived while rendering. Tabs use configurable tab stops;
Unicode display width is supplied by termcolor-layout.

## Features

- primary and secondary labels;
- single-line and multiline source spans;
- multiple source files and diagnostics;
- configurable width, context lines, tab width, and ASCII/Unicode decorations;
- notes and help messages;
- semantic palettes from ColorScheme.catppuccin, dracula, and monokai;
- pure Text output with existing ANSI and non-TTY policies;
- separate machine-checked properties and executable rendering tests.

## Package stack

~~~text
termcolor
  -> termcolor-layout
      -> termcolor-diagnostics
      -> termcolor-widgets
  -> termcolor-terminal
  -> argus
~~~

The diagnostics renderer depends on styled text and layout, not terminal IO. argus uses it for
structured command-line errors, while grip remains independent of terminal packages.

The demo is a feature gallery: `lake exe demo` shows errors, warnings, primary and secondary
labels, multiline and multi-source spans, tabs, CJK text, batched diagnostics, color schemes,
plain output, and auto-detected terminal output.

## Development

~~~sh
lake build TermColor.Diagnostics TermColor.Diagnostics.Properties tests readme demo
lake exe tests
python3 scripts/check-axioms.py
python3 scripts/style-check.py
lake exe demo
~~~

TermColor.Diagnostics.Properties is separate from the runtime package. The properties package
checks span and source-indexing laws; executable tests cover the complete visual layout and
Unicode cases. The CI workflow runs the same audit on every push and pull request.

## Limitations

The first release does not include fix-it edits, JSON/SARIF output, syntax highlighting, or
grapheme-cluster shaping. The data model leaves room for those additions without changing the
source-span convention.

## License

Apache-2.0.
