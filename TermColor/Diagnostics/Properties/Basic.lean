/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics

namespace TermColor.Diagnostics.Properties

open TermColor

theorem point_span_length
    (source offset : Nat)
    : Span.length (Span.point source offset) = 0 := by
  simp [Span.length, Span.point]

theorem range_span_length
    (source start stop : Nat)
    : Span.length (Span.range source start stop) = stop - start := by
  simp [Span.length, Span.range]

theorem fix_it_replaces_utf8_bytes :
    (Source.applyFixIt (Source.named "example" "a界b")
      { span := Span.range 0 1 4, replacement := "x" }).map (·.text) = some "axb" := by
  native_decide

end TermColor.Diagnostics.Properties
