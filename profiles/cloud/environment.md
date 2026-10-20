# Cloud sandbox environment

Sessions run in a disposable Linux container in Claude Code on the web. The
shell is bash running as root, and Nix with flakes is installed. Projects
include Rust, Zig, Go, JavaScript/TypeScript, and NixOS configuration for a
personal cluster.

The repository is a fresh clone and the container is reclaimed when the
session ends. Local commits survive only for the session; retaining work
beyond it requires an explicitly authorized push. Do not push without that
authorization. The user often follows the session from a phone and may not
answer a question for a while.

Outbound traffic goes through a proxy governed by the environment's network
policy. A blocked host, a TLS failure, or a 403 from the proxy is a policy
limit, not a fault in the repository; report it instead of working around it.
There is no access to the cluster, its hosts over `ssh`, local secrets, or
the user's machines. Do not ask for credentials to reach them.

Use `devshell-preflight` when the repository declares a Nix development
environment, and resolve that environment before running its commands.
`devenv` is not preinstalled; run it through Nix when the repository needs
it. Use `nixos-change-validation` for changes to Nix configuration. Evaluate
and build the affected outputs here, and hand activation, deploy, and
rollback commands to the user, since no host can be reached.

Temporary tooling through `nix shell` or `nix run` is allowed without
approval because the container is disposable. Do not create an ad hoc
substitute for a missing validator, and state what any temporary tool cannot
verify.

Checks must exercise the changed files. If the environment cannot run them,
report the limitation and the exact command or test still needed.
