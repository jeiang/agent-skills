# Activation, State, and Remote Deployment

The failure modes that survive a green `nix build` and only appear on the
host. Nix CLI flags move between releases — confirm anything version-specific
against the installed `nix --version` rather than assuming.

## What each activation actually does

| Command | Activates now | Survives reboot |
|---|---|---|
| `nixos-rebuild test` | Yes | No — no bootloader entry |
| `nixos-rebuild boot` | No | Yes |
| `nixos-rebuild switch` | Yes | Yes |

`test` is the safe probe: if it wedges the machine, a reboot returns to the
previous generation. That safety is also its limit.

**`test` cannot prove**: bootloader changes, kernel or initrd changes, LUKS or
early-boot changes, filesystem and mount changes, `fileSystems` entries,
impermanence bind mounts, and anything that only runs at boot. A change
touching those is only validated by an actual reboot, and it must be called
out as such rather than reported as tested.

Rollback is `nixos-rebuild switch --rollback`, or picking the previous
generation in the bootloader. List generations with
`nixos-rebuild list-generations`, or
`nix-env --list-generations --profile /nix/var/nix/profiles/system`.

## Impermanence

Anything not declared in `environment.persistence` is gone at the next boot.
This fails quietly: the service starts, works all week, and loses its state on
the next reboot, far from the change that caused it.

So: adding any service that keeps state means adding its state directory in
the same change. Check what the package actually writes — `StateDirectory` in
its unit, its `WorkingDirectory`, its data path — rather than assuming
`/var/lib/<name>`. Ownership and mode on a persisted directory must be set
too; a bind mount over a directory the service cannot write to fails at start,
not at activation.

Reboot is the only real test of a persistence change.

## Secrets

sops-nix and agenix decrypt during activation, into a tmpfs, not into the
store. Consequences:

- A host whose key is missing or rotated fails **at activation**, after the
  build succeeded. The build proving nothing about decryption is the point.
- Secrets are not readable at evaluation time. A module that needs a secret's
  *value* to compute configuration cannot work; it needs the path instead.
- A service that reads its secret at start needs the ordering to hold; the
  secret unit must be active first.

Never print a decrypted value while diagnosing.

## Purity and evaluation

- `system.stateVersion` records the release the host was first installed at.
  It is not a version to bump. Changing it to "update" a host silently changes
  stateful defaults.
- Prove evaluation without a full build:
  `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`.
  Build with `nixos-rebuild build --flake .#<host>` or
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
- `nix flake check` evaluates every output and builds the checks. On a
  multi-host flake it is slow and often builds far more than the change
  touched. Prefer the narrowest evaluation that proves the affected output,
  then widen only when justified.
- Updating one input rather than all of them differs by Nix version: newer
  releases take `nix flake update <input>`, older ones
  `nix flake lock --update-input <input>`. Check which applies before
  churning the whole lock file.
- Building for another architecture needs a remote builder or `binfmt`
  emulation. Without either, the build fails on the host's own architecture
  and the error names the missing system.

## deploy-rs

- Magic rollback works by confirming connectivity to the host *after*
  activation. A change that intentionally alters networking, firewall, or SSH
  will therefore look like a failed deploy and roll itself back. That is
  correct behavior and needs `--magic-rollback false` (or an out-of-band plan)
  when the disruption is deliberate.
- Auto-rollback and the activation timeout mean an activation slower than the
  timeout is reverted even though it would have succeeded. Slow-starting
  services need the timeout raised, not the check removed.
- deploy-rs pushes a closure over SSH. A large closure over a slow link is the
  usual cause of a deploy that appears to hang with no output.
- Deploying to the machine you are on, or to the machine routing your
  connection, can cut the connection mid-activation. Say so before doing it.

## Handing off

Give the exact command for the intended host, whether it is `test`, `boot`, or
`switch`, and why. State explicitly when a reboot is required for the change
to take effect or to be validated at all. Give the rollback command and the
post-activation checks — the changed unit's status, mounts, persistence,
networking, and remote access — before the connection is needed again.
