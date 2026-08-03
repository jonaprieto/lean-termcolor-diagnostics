/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics

namespace TermColor.Diagnostics.Properties

open TermColor

theorem point_span_length (source offset : Nat) :
    Span.length (Span.point source offset) = 0 := by
  simp [Span.length, Span.point]

theorem range_span_length (source start stop : Nat) :
    Span.length (Span.range source start stop) = stop - start := by
  simp [Span.length, Span.range]

end TermColor.Diagnostics.Properties
