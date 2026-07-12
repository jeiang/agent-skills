# Codex Skills

A small collection of reusable workflows and custom agents for Codex. The
current workflow, `$start-task`, routes feature work through dedicated planning,
implementation, and review agents, then repeats review and repair until the
change passes or reaches the five-review limit.

## What is included

- `skills/start-task/` — the workflow definition and Codex UI metadata
- `agents/feature-planner.toml` — a read-only implementation planner
- `agents/feature-implementer.toml` — a workspace-write coding agent
- `agents/feature-reviewer.toml` — a read-only correctness reviewer
- `install.sh` — installs the skill and agent definitions for the current user

The configured agents use model routing appropriate to their roles: the planner
and reviewer use `gpt-5.6-sol`, while the implementer uses `gpt-5.6-terra`.

## Installation

Clone or download this repository, then run:

```sh
./install.sh
```

The installer:

1. symlinks the skill to `~/.agents/skills/start-task`;
2. copies the agent definitions to `~/.codex/agents`;
3. creates `~/.codex/config.toml` if needed; and
4. adds a default `[agents]` section with a four-thread, one-level limit when
   that section does not already exist.

Existing agent configuration is left unchanged. The installer also refuses to
replace an existing skill directory or a skill symlink pointing elsewhere.

Restart Codex after installation if the skill does not appear immediately.

## Usage

From a Git repository, invoke the skill with a feature request:

```text
$start-task Add pagination to the activity feed
```

The workflow runs these stages sequentially:

1. records the repository baseline and applicable instructions;
2. asks the planner for a concrete implementation plan;
3. asks the implementer to make and validate the changes;
4. asks the reviewer to inspect the complete accumulated diff; and
5. plans, implements, and reviews repairs until approval or five completed
   review cycles.

Only the implementer is allowed to edit repository files. The workflow
preserves pre-existing changes and does not commit, push, or open a pull request
unless explicitly requested.

## Customization

Edit the files under `agents/` to change models, reasoning effort, sandbox mode,
or role instructions. Run `./install.sh` again to copy updated agent definitions
into `~/.codex/agents`.

Changes made under `skills/start-task/` are available immediately through the
installed symlink.

## Uninstalling

Remove the installed skill and agents:

```sh
rm ~/.agents/skills/start-task
rm ~/.codex/agents/feature-planner.toml
rm ~/.codex/agents/feature-implementer.toml
rm ~/.codex/agents/feature-reviewer.toml
```

If the installer added the `[agents]` section to `~/.codex/config.toml`, remove
that section manually only if it is no longer used by other custom agents.
