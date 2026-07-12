# Codex Skills

A Git-managed collection of reusable skills and custom agents.

## Layout

- `codex/` contains skills intended specifically for Codex. Every skill in this
  directory is linked into `~/.codex/skills` by the installer.
- `generic/` is reserved for future portable agent skills. Skills added there
  are linked into `~/.agents/skills`.
- `agents/` contains Codex custom-agent definitions installed into
  `~/.codex/agents`.
- `install.sh` installs or updates the links and custom-agent files.

The repository currently includes:

- `codex/actual-budget-import/` — imports natural-language transactions through
  the configured Actual Budget CLI.
- `codex/start-task/` — routes feature work through dedicated planning,
  implementation, and review agents until approval or five review cycles.

System-managed skills under `~/.codex/skills/.system` and runtime-managed
entries are intentionally excluded from this repository.

## Installation

Run:

```sh
./install.sh
```

The installer:

1. links every valid skill under `codex/` into `~/.codex/skills`;
2. links future skills under `generic/` into `~/.agents/skills`;
3. copies custom-agent definitions into `~/.codex/agents`; and
4. adds a default `[agents]` section to `~/.codex/config.toml` when none exists.

If an existing skill directory exactly matches the repository copy, the
installer moves it to `~/.codex/skill-backups` before replacing it with a
symlink. It refuses to replace differing content or unrelated symlinks.

Restart Codex after installation if skill changes do not appear immediately.

## Usage

Import Actual Budget transactions:

```text
$actual-budget-import Save these transactions to my budget: ...
```

Run the feature workflow from a Git repository:

```text
$start-task Add pagination to the activity feed
```

The feature workflow uses `gpt-5.6-sol` at extra-high reasoning for planning,
`gpt-5.6-terra` at high reasoning for implementation, and `gpt-5.6-sol` at high
reasoning for review. Only the implementer may edit repository files.

## Updating

After pulling repository changes, rerun:

```sh
./install.sh
```

Symlinked skill updates are otherwise visible immediately. Rerunning the
installer refreshes the copied custom-agent definitions.
