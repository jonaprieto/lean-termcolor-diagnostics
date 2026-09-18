/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics.Properties.Basic

namespace TermColor.Diagnostics.Properties

open TermColor

theorem line_split_example
    : (Source.lines (Source.named "example" "one\ntwo")).map (·.text) = ["one", "two"] := by
  native_decide

theorem diagnostic_code_example
    : ((Diagnostic.error "bad").withCode "E1").code = some "E1" := by
  rfl

theorem report_field_example :
    ((Report.error "request failed").withField "status" "503").fields =
      [{ label := "status", value := "503" }] := by
  rfl

theorem fix_it_render_example :
    let source := #[Source.named "config.toml" "timeout = 2x"]
    let diagnostic := (Diagnostic.error "invalid duration").withFixIt
      { span := Span.range 0 10 12, replacement := "2m" }
    (render source diagnostic { contextLines := 0 }).plainText.contains "timeout = 2m" := by
  native_decide

end TermColor.Diagnostics.Properties
