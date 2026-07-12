# Agent Skills

A Git-managed collection of reusable agent skills and Codex custom agents.

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
- `codex/start-task/` — routes feature work through user-approved planning,
  commit-sized implementation, and commit-range review until approval or five
  review cycles.

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
symlink. It recreates broken skill symlinks, such as after this repository is
renamed or moved, and refuses to replace differing content or active symlinks
pointing elsewhere.

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

The feature workflow uses `gpt-5.6-sol` at high reasoning for planning,
`gpt-5.6-terra` at medium reasoning for implementation, and `gpt-5.6-sol` at
medium reasoning for review. Only the implementer may edit repository files.

Before implementation, the workflow records the Git baseline, presents a
commit-sized plan, and waits for explicit approval. Requested plan edits are
returned to the planner and presented again before work starts. When starting
from the default branch, the workflow creates a `codex/` feature branch after
approval.

The implementer validates and commits each changed plan step separately. The
first review covers every feature commit from the baseline; later reviews focus
on new repair commits while verifying prior findings and the cumulative result.
An invalid planning assumption stops implementation and returns the evidence to
the planner for a revised plan and renewed approval. On completion, the workflow
lists any manual follow-up and asks before pushing or opening a ready pull
request.

## Updating

After pulling repository changes, activate the updated skills and custom agents
by running:

```sh
./install.sh
```

Then restart Codex. Symlinked skill files update immediately, but rerunning the
installer refreshes the copied custom-agent definitions and restarting Codex
ensures the updated skill and agents are loaded.
