# Personal environment

Personal development uses macOS and Linux with Nix. Projects include Rust,
Zig, Go, JavaScript/TypeScript, and a personal NixOS cluster.

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
