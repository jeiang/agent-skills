---
name: devshell-preflight
description: Resolve repository commands inside a declared Nix development environment on personal macOS or Linux systems with Nix available. Use at the start of any task in a repository that has devenv.nix, flake.nix, shell.nix, or .envrc, before the first just, statix, formatter, build, or test command, and when diagnosing that environment. Do not use on the work machine, in environments without Nix, or for arbitrary missing commands.
---

# Devshell Preflight

First confirm the personal environment policy applies, the system is macOS
or Linux, Nix is available, and the repository declares a Nix environment.
Otherwise this skill does not apply. A missing command alone is not a trigger.
Resolve the entry point once and reuse it for the affected checkout.

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

Record the resolved prefix and use it for every repo command in the session.
When a repo command still fails inside the prefix, read its `--help` or the
`justfile` recipe once instead of guessing argument order.

## Git worktrees

If a worktree entry point fails, inspect the repository's environment setup
and resolve it for that worktree. Do not run checks in another checkout and
claim they validated the changed files. Report the limitation if the intended
worktree cannot be checked.

## One-off tools the repo does not provide

Get user approval before fetching tools outside the declared repository
environment or creating an ad hoc substitute, unless that use is already
authorized. Prefer `nix shell nixpkgs#<pkg> -c <cmd>` to permanent installation.
For an approved Python interpreter that needs a library, the package
attribute alone does not put the module on the interpreter's path. Use the
wrapper form:

```sh
nix-shell -p "python3.withPackages(p: [p.pyyaml])" --run '<cmd>'
```

## Do not

- Do not run the bare command first to see whether it happens to work, when
  any marker above is present.
- Do not treat disclosure as approval for a substitute. Explain its limits;
  do not claim it is equivalent to the intended check without evidence.
- Do not assume GNU coreutils on macOS. `timeout` is absent, and `sed -i`,
  `readlink -f`, and `date` take different arguments.
