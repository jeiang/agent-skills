# Personal environment

Personal development uses macOS and Linux with Nix. Projects include Rust,
Zig, Go, JavaScript/TypeScript, and a personal NixOS cluster.

The agent's shell tool runs under zsh with unmatched globs treated as errors,
and the login shell on this machine and on cluster hosts is fish. Quote every
glob argument, such as `--include='*.nix'`. Wrap POSIX constructs such as
`for` loops, `$(...)`, and heredocs in `bash -c '...'` when a command runs
over `ssh`.

Use `devshell-preflight` when Nix is available and the repository declares a
Nix development environment. Resolve that environment before running its
commands. Use `nixos-change-validation` for changes to Nix configuration,
with checks proportional to the affected behavior.

Ad hoc tooling is allowed without user approval. Use tools outside the
repository's declared environment, or create an ad hoc substitute, when the
task needs it. After the work, report each ad hoc tool or substitute used
and what it was used for.

Never install tools permanently: no global package managers (`brew install`,
`npm -g`, `cargo install`, `pip install --user`, `go install`), no
`nix profile install` or `nix-env -i`, and no changes to system or user
profiles. Use temporary Nix tooling such as `nix shell` or `nix run`. When a
missing tool will be reused often in a repository, add it to that
repository's declared environment, such as its devshell, instead.

Do not switch to a different checkout to make validation pass. Checks must
exercise the changed files. If the environment cannot run them, report the
limitation and the appropriate follow-up.
