/-
Copyright (c) 2026 Jonathan Prieto-Cubides. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

import TermColor.Diagnostics.Model

/-!
# TermColor.Diagnostics.Source: byte-aware source lines

The renderer works from UTF-8 byte offsets so parser errors can be passed through without
line/column remapping. Line text is decoded only after byte boundaries have been found.
-/

namespace TermColor.Diagnostics

structure Line where
  number : Nat
  byteStart : Nat
  byteEnd : Nat
  text : String
  deriving BEq, DecidableEq, Repr

namespace Source

private def lineRanges (bytes : ByteArray) : List (Nat × Nat) :=
  let rec go (index start : Nat) (ranges : List (Nat × Nat)) : List (Nat × Nat) :=
    if index >= bytes.size then
      (start, bytes.size) :: ranges
    else if bytes[index]! == 0x0A then
      let stop := if index > start && bytes[index - 1]! == 0x0D then index - 1 else index
      go (index + 1) (index + 1) ((start, stop) :: ranges)
    else
      go (index + 1) start ranges
  termination_by bytes.size - index
  (go 0 0 []).reverse

private def decode (bytes : ByteArray) (start stop : Nat) : String :=
  match String.fromUTF8? (bytes.extract start stop) with
  | some text => text
  | none => "�"

/-- Source lines with one-based line numbers and UTF-8 byte boundaries. -/
def lines (source : Source) : List Line :=
  let bytes := source.utf8Bytes
  (lineRanges bytes).mapIdx fun index (start, stop) =>
    { number := index + 1
      byteStart := start
      byteEnd := stop
      text := decode bytes start stop }

/-- Return the line containing an offset, clamping EOF to the final line. -/
def lineAt (source : Source) (offset : Nat) : Option Line :=
  let safeOffset := min offset source.utf8Bytes.size
  (lines source).find? fun line => line.byteStart ≤ safeOffset && safeOffset ≤ line.byteEnd

end Source

end TermColor.Diagnostics
