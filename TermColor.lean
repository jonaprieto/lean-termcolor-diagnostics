/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics.Model
import TermColor.Diagnostics.Source
import TermColor.Diagnostics.Render

/-!
# termcolor-diagnostics

Pure source-annotated diagnostics for Lean 4 command-line tools. The package returns
`TermColor.Text`; callers choose the terminal target with `TermColor.Text.render` or the existing
`TermColor.Detect`/`TermColor.Terminal` layers.
-/
