import Lake
open Lake DSL

package «termcolor-diagnostics» where
  version := v!"0.1.8"
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩]

require «termcolor-layout» from git
  "https://github.com/jonaprieto/lean-termcolor-layout.git"
  @ "56dfeb9bfc906c20ba79d2c9b0ab95152d532f0a"

@[default_target]
lean_lib «TermColor.Diagnostics» where
  roots := #[`TermColor.Diagnostics]
  globs := #[.andSubmodules `TermColor.Diagnostics]

lean_lib «TermColor.Diagnostics.Properties» where
  roots := #[`TermColor.Diagnostics.Properties]
  globs := #[.andSubmodules `TermColor.Diagnostics.Properties]

lean_exe «demo» where
  root := `Demo
  srcDir := "examples"

lean_exe «tests» where
  root := `Tests
  srcDir := "test"

lean_exe «detect» where
  root := `Detect
  srcDir := "test"

lean_exe «readme» where
  root := `Readme
  srcDir := "test"
