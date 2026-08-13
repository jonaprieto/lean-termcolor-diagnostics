# Changelog

## 0.1.15 — 2026-08-13

- Publish the dependency-graph README cleanup.

## 0.1.14 — 2026-08-12

- Adopt Lean v4.33.0 and precommit-lean v0.1.6.

## 0.1.13

- Add source-free structured reports with aligned fields for transport and service failures.

## 0.1.11

- Add byte-ranged fix-it edits with configurable removed, added, and context rendering.
- Use scheme-derived red and green backgrounds for default removed and added lines.
- Add executable, machine-checked, README, and demo coverage for fix-it output.

## 0.1.8

- Underline only severity words such as `error`, `note`, and `help`, leaving codes, punctuation,
  and messages plain.
- Highlight source filenames with the active scheme and support opt-in OSC-8 clickable locations.

## 0.1.7

- Render multiline label messages once at the label's starting line.
- Use Unicode framing consistently in the multi-source demo.
- Add an explicit ASCII frame fallback section.
- Use clear `note:` and `help:` metadata prefixes without the rustc-style `=`.
- Expand the executable suite to 35 diagnostics checks.
- Underline the `note:` and `help:` labels in styled output.

## 0.1.6

- Add Unicode `╰─` connectors between label markers and their messages.
- Keep ASCII marker separators unchanged.
- Expand the executable suite to 33 diagnostics checks.

## 0.1.5

- Add a complete edge-case demo gallery and 31 executable rendering checks.
- Add raw-byte sources with invalid UTF-8 replacement fallback.
- Add ANSI target and environment-policy checks for CI.
- Add README screenshots, coverage audit, and private dependency authentication.

## 0.1.4

- Make Unicode mode render `╰─>` locations and `│` gutters.
- Keep the ASCII fallback as `-->` and `|`.

## 0.1.3

- Make the demo render labels from both source files in its multi-source section.

## 0.1.2

- Expand the executable demo into a renderer feature gallery.
- Add executable checks for severity, tabs, multiline spans, and multiple sources.

## 0.1.0

- Add pure source-annotated diagnostics for Lean 4.
- Add primary and secondary labels, notes, help, codes, and multiple sources.
- Add Unicode/ASCII rendering, context lines, display-width-aware tabs, and color schemes.
- Add executable tests, machine-checked properties, API docs, demo, and CI audit.
