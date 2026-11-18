---
name: devshell-preflight
description: Diagnose a repository's Nix development environment when a command fails inside it, for example a missing toolchain, a stale or blocked `.envrc`, or a broken flake devShell. Commands already run inside the devshell automatically; do not load this skill to resolve the environment before ordinary work.
---

# Devshell Preflight

The `shell` tool and `!` commands already run inside the repository's
devshell: direnv when `.envrc` is allowed, else `devenv`, else the flake
devShell, else `shell.nix`, cached per lock file. Use this skill only when a
command fails because of that environment.

## Diagnose

1. Identify the source the session uses: `.envrc` with `direnv status`,
   `devenv.nix`, `flake.nix`, or `shell.nix` at the repository root.
2. Reproduce the failure with the plain entry point to see its own error:
   `direnv exec . <cmd>`, `devenv shell -- <cmd>` (or
   `nix run nixpkgs#devenv -- shell -- <cmd>`), `nix develop -c <cmd>`, or
   `nix-shell --run '<cmd>'`.
3. Common causes:
   - `.envrc` blocked: the user must run `direnv allow`; never allow it
     yourself without being asked.
   - `devenv.nix` without `flake.nix`: `nix develop` fails with "not part
     of a flake"; that is the wrong entry point, not a broken repository.
   - The tool is not in the devshell: report it; add it to the repository's
     environment only when the task allows that change.
   - A new worktree has no `.envrc` approval: the main checkout's approval
     does not carry over unless the files are identical.

## One-off tools

Use temporary Nix tooling such as `nix shell nixpkgs#<pkg> -c <cmd>`, never a
permanent installation. A Python library needs the wrapper form:
`nix-shell -p "python3.withPackages(p: [p.pyyaml])" --run '<cmd>'`.

Do not run checks in another checkout and claim they validated the changed
files. State the limits of any substitute.
