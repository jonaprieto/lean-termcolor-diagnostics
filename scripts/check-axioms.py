import re
import subprocess
import sys

allowed = {"propext", "Classical.choice", "Quot.sound"}
native_axioms = {"Lean.ofReduceBool", "Lean.trustCompiler"}
native = {"line_split_example", "fix_it_replaces_utf8_bytes", "fix_it_render_example"}


def is_native_decide_axiom(decl, axiom):
    """Since Lean v4.29, `native_decide` names its axiom after the declaration it
    closes (`<decl>._native.native_decide.ax_1_1`) instead of reusing
    `Lean.ofReduceBool`. Accept it for the declarations already allowed to use it."""
    return decl in native and "._native.native_decide.ax" in axiom

result = subprocess.run(
    ["lake", "build", "TermColor.Diagnostics.Properties"],
    text=True,
    capture_output=True,
)
sys.stdout.write(result.stdout)
sys.stderr.write(result.stderr)
if result.returncode:
    raise SystemExit(result.returncode)

current = None
block = []
failures = []
for line in (result.stdout + result.stderr).splitlines():
    match = re.search(r"'TermColor\.Diagnostics\.Properties\.([^']+)' depends on axioms:", line)
    if match:
        current = match.group(1)
        block = [line.split("depends on axioms:", 1)[1]]
    elif current:
        block.append(line)
    if current and "]" in "".join(block):
        joined = "".join(block)
        axioms = {a.strip() for a in joined[: joined.index("]")].strip(" [").split(",")}
        axioms.discard("")
        permitted = allowed | (native_axioms if current in native else set())
        unexpected = {a for a in axioms - permitted if not is_native_decide_axiom(current, a)}
        if unexpected:
            failures.append((current, unexpected))
        current = None
        block = []

if failures:
    for name, axioms in failures:
        print(f"unexpected axioms in {name}: {sorted(axioms)}", file=sys.stderr)
    raise SystemExit(1)
