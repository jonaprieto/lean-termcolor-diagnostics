import Lake
open Lake DSL

package «termcolor-diagnostics» where
  version := v!"0.1.0"
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩]

require «termcolor-layout» from git
  "https://github.com/jonaprieto/lean-termcolor-layout.git" @ "ec0f5df"

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

lean_exe «readme» where
  root := `Readme
  srcDir := "test"
