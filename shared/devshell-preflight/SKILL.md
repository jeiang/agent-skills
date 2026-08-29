---
name: devshell-preflight
description: Resolve how to run a repository's own commands (just, make, test runners, linters, formatters, language tools) before running them, when those tools are not on the ambient PATH. Use before the first invocation of any repo-provided command in a Nix, devenv, direnv, or otherwise environment-managed repository, and whenever a repo command fails with "command not found".
---

# Devshell Preflight

Repository commands rarely live on the ambient PATH. Resolve the entry point
once, at the start of the session, and reuse it. Do not discover it from a
`command not found`.

## Resolve the entry point

Check in this order and stop at the first that matches:

1. `.envrc` present and `direnv status` reports the environment loaded: the
   commands already work, so run them directly.
2. `devenv.nix` at the repo root: `devenv shell -- <cmd>`. When `devenv` is
   not on PATH, use `nix run nixpkgs#devenv -- shell -- <cmd>`.
3. `flake.nix` at the repo root: `nix develop -c <cmd>`, adding `--impure`
   when the repo's own `justfile`, `.envrc`, or docs use it.
4. `shell.nix`: `nix-shell --run '<cmd>'`.
5. None of the above: the command is expected on PATH. If it is missing, say
   so rather than silently substituting a different tool.

A repo can have `devenv.nix` without `flake.nix`. `nix develop` fails there
with "not part of a flake"; that is the wrong entry point, not a broken repo.

Record the resolved prefix and use it for every repo command in the session.

## Git worktrees

A worktree under `.claude/worktrees/` may not be part of the flake even when
the main checkout is. If the entry point fails there, run from the main
checkout or use the `devenv` / `nix-shell` path.

## One-off tools the repo does not provide

Use `nix shell nixpkgs#<pkg> -c <cmd>` rather than installing into the ambient
environment. For a Python interpreter that needs a library, the package
attribute alone does not put the module on the interpreter's path. Use the
wrapper form:

```sh
nix-shell -p "python3.withPackages(p: [p.pyyaml])" --run '<cmd>'
```

## Do not

- Do not run the bare command first to see whether it happens to work, when
  any marker above is present.
- Do not fall back to the system interpreter or a hand-rolled equivalent
  without saying so in the report.
- Do not assume GNU coreutils on macOS. `timeout` is absent, and `sed -i`,
  `readlink -f`, and `date` take different arguments.
