# Diagnostics coverage

This checklist is the release audit for `lake exe demo`, `lake exe tests`, and the terminal-policy
probe. A check belongs in the executable suite when it protects behavior; a visual case belongs
in the demo when a user should be able to inspect the result directly.

| Requirement | Demo | Executable check | Status |
| --- | --- | --- | --- |
| ANSI-16 and ANSI-256 | `ANSI-16 TARGET`, `ANSI-256 TARGET` | `tests` | covered |
| True color, plain, and auto detection | sections at the end | `detect`, `tests` | covered |
| `NO_COLOR`, `FORCE_COLOR`, `TERM=dumb` | `detect` commands in README | `detect` | covered |
| Width truncation and tab stops | `WIDTH TRUNCATION`, `DIRECT TAB HELPERS` | `tests` | covered |
| CJK and combining characters | multiline source section | `tests` | covered |
| CRLF line endings | `CRLF + EOF POINT` | `tests` | covered |
| Empty source and EOF/point spans | `EMPTY SOURCE`, `CRLF + EOF POINT` | `tests` | covered |
| Error, warning, info, note, and help | gallery sections | `tests` | covered |
| Primary, secondary, unlabeled, and uncoded diagnostics | gallery sections | `tests` | covered |
| Multiple sources and multiline labels | multi-source section | `tests` | covered |
| Built-in and custom color schemes | palette sections | `tests` | covered |
| Highlighted filenames and OSC-8 locations | `CLICKABLE SOURCE LOCATION / OSC-8` | `tests` | covered |
| Invalid UTF-8 fallback | `INVALID UTF-8 FALLBACK` | `tests` | covered |
| Argus integration | linked Argus demo | Argus `Help.renderErrors` tests | covered |
| JSON/SARIF output | documented limitation | not implemented | planned |
| Fix-it edits | documented limitation | not implemented | planned |
| Grapheme-cluster shaping | documented limitation | not implemented | planned |

Every source change is gated by style, whitespace, build, executable tests, README evaluation,
and the properties axiom audit in CI. The workflow uses `ECOSYSTEM_READ_TOKEN` for the private
ecosystem dependencies and falls back to the default GitHub token when those dependencies are
public.
