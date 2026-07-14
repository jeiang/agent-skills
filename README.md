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
- `codex/start-task/` — runs a repository-aware, approval-gated workflow for
  prompt validation, research, planning, implementation, adversarial review,
  documentation maintenance, and per-part pull requests.

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
4. configures Codex for nested agent workflows with `agents.max_depth >= 2` and
   `agents.max_threads >= 4` while preserving higher values and unrelated
   configuration.

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

The parent launches a Luna-high orchestrator, which coordinates specialized
agents with only the context needed for their assignments. The workflow checks
repository guidance, validates and confirms the requested scope, performs
bounded research when needed, and splits independently shippable work into
separate branches and pull requests.

Each part receives a mid-level implementation plan from a Sol-high planner. An
adversarial Sol-high plan reviewer must pass the plan before the user approves
implementation. A Terra-medium implementer receives one focused change at a
time, uses repository static tooling, reviews plan risks and its own diff, and
stops for replanning when the change exceeds the workflow thresholds or exposes
an invalid assumption.

A Sol-medium adversarial reviewer checks correctness, security, regressions,
compatibility, error handling, plan fulfillment, and validation. Findings are
repaired independently. After product review passes, a Luna-high documentation
agent updates only documentation required by the completed behavior. Large
cumulative reviews are split by cohesive concern before publication.

The workflow preserves unrelated work and requires explicit approval before
creating each branch, resuming materially revised implementation, pushing, or
opening a pull request. It never force-pushes as part of the workflow.

## Development

Enter the reproducible development shell:

```sh
devenv shell
```

Run the complete validation suite:

```sh
devenv test
```

The suite validates skills and agent contracts, parses YAML and TOML, checks
shell syntax and formatting, exercises installer fixtures, and runs
`git diff --check`.

## Updating

After pulling repository changes, activate the updated skills and custom agents
by running:

```sh
./install.sh
```

Then restart Codex. Symlinked skill files update immediately, but rerunning the
installer refreshes the copied custom-agent definitions and restarting Codex
ensures the updated skill and agents are loaded.
