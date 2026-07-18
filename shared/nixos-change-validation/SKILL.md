---
name: nixos-change-validation
description: Prepare and validate NixOS flake, module, package, host, home-manager, impermanence, and deploy-rs changes. Use when the agent needs to modify Nix configuration, evaluate or build affected outputs, or provide safe activation and rollback instructions for a NixOS host.
---

# NixOS Change Validation

Inspect the flake outputs, module imports, host composition, overlays, package definitions, deployment tooling, state-version policy, and applicable AGENTS.md files before editing.

## Change

- Follow the repository's existing option, module, formatting, and host-ownership patterns.
- Keep evaluation pure where the repository expects it and avoid unnecessary input or lock-file churn.
- Preserve bootability, remote access, persistent state, secret delivery, and rollback capability for host-affecting changes.
- Prefer standard NixOS options and small module composition over custom abstractions.
- Do not add tests, helpers, generalized modules, or comments unless the approved task requires them or a non-obvious invariant needs explanation.

## Validate

Run the narrowest repository-supported evaluation or build that proves the affected output, then broader checks only when justified. Depending on the repository, this may include formatter checks, `nix flake check`, targeted `nix eval`, a host `system.build.toplevel` build, package builds, or deploy-rs checks.

If the Nix daemon, remote builder, required system, cache, or secret is unavailable, report the limitation and do not claim runtime validation.

## Activate safely

Do not activate or deploy automatically. Provide the repository's exact test, switch, deploy, or rollback command and post-activation checks for the changed service, generation, mounts, persistence, networking, and remote access as applicable. Call out changes that require reboot or cannot be safely tested with `nixos-rebuild test`.
