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

Ad hoc tooling is allowed with user approval. Before fetching tools outside
the repository's declared environment or creating an ad hoc substitute,
obtain approval unless that use is already authorized in this task. Prefer
temporary Nix tooling to permanent installation. Explain what the tool or
substitute will establish and what it cannot verify.

Do not switch to a different checkout to make validation pass. Checks must
exercise the changed files. If the environment cannot run them, report the
limitation and the appropriate follow-up.
