/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics.Properties.Basic

namespace TermColor.Diagnostics.Properties

open TermColor

theorem line_split_example :
    (Source.lines (Source.named "example" "one\ntwo")).map (·.text) = ["one", "two"] := by
  native_decide

theorem diagnostic_code_example :
    ((Diagnostic.error "bad").withCode "E1").code = some "E1" := by
  rfl

end TermColor.Diagnostics.Properties
