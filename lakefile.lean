import Lake
open Lake DSL

package «termcolor-diagnostics» where
  version := v!"0.1.3"
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`relaxedAutoImplicit, false⟩]

require «termcolor-layout» from git
  "https://github.com/jonaprieto/lean-termcolor-layout.git"
  @ "d8c68e5f32ebd21a85c834923c95e113599da7a6"

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
