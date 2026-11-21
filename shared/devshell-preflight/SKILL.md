---
name: devshell-preflight
description: "Resolve Nix development environments. Use before repository commands or environment diagnosis; skip known command prefixes."
---

# Devshell Preflight

First confirm the environment policy allows Nix, the system is macOS or
Linux, Nix is available, and the repository declares a Nix environment.
Otherwise this skill does not apply. A missing command alone is not a trigger.
If the assignment or the repository's AGENTS.md already names the entry
point, use it and skip resolution. Otherwise resolve it once and reuse it for
the affected checkout.

## Resolve the entry point

Check in this order and stop at the first that matches:

1. `.envrc` present and `direnv status` reports the environment loaded: the
   commands already work, so run them directly.
2. `devenv.nix` at the repo root: `devenv shell -- <cmd>`. When `devenv` is
   not on PATH, use `nix run nixpkgs#devenv -- shell -- <cmd>`.
3. `flake.nix` at the repo root: `nix develop -c <cmd>`, adding `--impure`
   when the repo's own `justfile`, `.envrc`, or docs use it.
4. `shell.nix`: `nix-shell --run '<cmd>'`.
5. None of the above: no Nix entry point was established. Use the repository's
   documented tooling and report missing commands.

A repo can have `devenv.nix` without `flake.nix`. `nix develop` fails there
with "not part of a flake"; that is the wrong entry point, not a broken repo.

Record the resolved prefix and use it for toolchain commands: builds, tests,
linters, formatters, and `just` recipes. Do not wrap commands that do not
need the shell, such as `git status`, `git fetch`, `git worktree`, `gh`, or
`ssh`; each wrapper costs a shell start.
When a repo command still fails inside the prefix, read its `--help` or the
`justfile` recipe once instead of guessing argument order.

## Git worktrees

If a worktree entry point fails, inspect the repository's environment setup
and resolve it for that worktree. Do not run checks in another checkout and
claim they validated the changed files. Report the limitation if the intended
worktree cannot be checked.

## One-off tools the repo does not provide

Follow the environment policy for tools outside the declared repository
environment or an ad hoc substitute. Use temporary Nix tooling such as
`nix shell nixpkgs#<pkg> -c <cmd>`, never a permanent installation. For a
Python interpreter that needs a library, the package attribute alone does not
put the module on the interpreter's path. Use the wrapper form:

```sh
nix-shell -p "python3.withPackages(p: [p.pyyaml])" --run '<cmd>'
```

## Do not

- Do not run the bare command first to see whether it happens to work, when
  any marker above is present.
- Do not claim a substitute is equivalent to the intended check without
  evidence; state its limits.
