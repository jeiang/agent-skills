---
name: nixos-change-validation
description: Prepare and validate NixOS flake, module, package, host, home-manager, impermanence, and deploy-rs changes. Use when the agent needs to modify Nix configuration, including repo-wide or mechanical edits such as formatting, comment, or refactor sweeps across .nix files; evaluate or build affected outputs; or provide safe activation and rollback instructions for a NixOS host.
---

# NixOS Change Validation

Read `references/activation-and-state.md` before proposing an activation command or claiming a change is validated. It covers what `nixos-rebuild test` cannot prove, impermanence and secret failures that appear only at activation, and deploy-rs rollback behavior.

Inspect the flake outputs, module imports, host composition, overlays, package definitions, deployment tooling, state-version policy, and applicable AGENTS.md files before editing.

## Change

- Follow the repository's existing option, module, formatting, and host-ownership patterns.
- Keep evaluation pure where the repository expects it and avoid unnecessary input or lock-file churn.
- Preserve bootability, remote access, persistent state, secret delivery, and rollback capability for host-affecting changes.
- Prefer standard NixOS options and small module composition over custom abstractions.
- Add tests only when they provide useful evidence for changed behavior, using existing conventions. Avoid new helpers, generalized modules, or comments that do not explain a relevant invariant.

## Validate

Repository commands (`just`, `statix`, formatters, test runners) usually exist only inside the repository's development shell. Resolve how to enter it (`direnv`, `devenv shell`, `nix develop`, `nix develop --impure`) before running one, rather than discovering it from a `command not found`.

Run the narrowest repository-supported evaluation or build that proves the affected output, then broader checks only when justified. Depending on the repository, this may include formatter checks, `nix flake check`, targeted `nix eval`, a host `system.build.toplevel` build, package builds, or deploy-rs checks.

When a change is intended to preserve behavior, prove it rather than asserting it: compare the affected derivation paths (`nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`) before and after, and state what the comparison cannot cover.

Capture a check's full output. Piping a long-running check through `tail` discards the error that made it fail and forces a second run.

If the Nix daemon, remote builder, required system, cache, or secret is unavailable, report the limitation and do not claim runtime validation.

## Activate safely

Do not activate or deploy automatically. Provide the repository's exact test, switch, deploy, or rollback command and post-activation checks for the changed service, generation, mounts, persistence, networking, and remote access as applicable. Call out changes that require reboot or cannot be safely tested with `nixos-rebuild test`.
