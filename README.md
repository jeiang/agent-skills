# Agent Skills

A Git-managed collection of Codex and Claude Code skills and custom agents.

## Layout

- `codex/` contains Codex-specific skills linked into `~/.codex/skills`.
- `claude/` contains Claude Code-specific skills linked into `~/.claude/skills`.
- `shared/` contains skills used by every tool, linked into `~/.codex/skills`, `~/.claude/skills`, and `~/.copilot/skills` (GitHub Copilot CLI's personal skills directory).
- `generic/` is reserved for portable skills linked into `~/.agents/skills`, which GitHub Copilot CLI also reads.
- `agents/` contains custom-agent definitions linked into `~/.codex/agents`.
- `claude-agents/` contains Claude Code subagent definitions linked into `~/.claude/agents`.
- `install.sh` installs the links and required Codex agent limits; `install.ps1` is the PowerShell equivalent for Windows.

The included skills are:

- `actual-budget-import` for importing natural-language transactions through the Actual Budget CLI.
- `start-task` for a repository change with confirmed scope, approved planning, focused implementation, bounded review, and optional publication.
- `start-feature` (Claude Code) for establishing feature context through a grilling interview with domain-modeling documentation before planning, then delegating implementation to the Sonnet `feature-implementer` subagent, which loads Ponytail in full mode.
- `kubernetes-delivery` for preparing and validating Helm, Kubernetes, container, and delivery configuration without deploying it.
- `kubernetes-diagnose` for investigating Kubernetes workload and platform failures.
- `nixos-change-validation` for preparing and validating NixOS changes and safe activation instructions.
- `azure-pipelines-maintenance` for Azure Pipelines YAML, templates, conditions, artifacts, and deployments.
- `eli5` for explaining code, systems, errors, or concepts at the altitude the reader is actually standing at, grounded in the real implementation rather than the general pattern. Takes an optional `eli5`, `colleague`, or `expert` level.
- `devshell-preflight` for resolving how a repository's own commands are run (direnv, devenv, flake, or `shell.nix`) before the first one is invoked, instead of discovering it from a `command not found`.
- `diagram` for deriving a Mermaid diagram from the repository and committing it beside what it describes, with the Azure DevOps wiki's reduced Mermaid dialect accounted for.
- `ponytail`, vendored from [DietrichGebert/ponytail v4.8.4](https://github.com/DietrichGebert/ponytail/tree/v4.8.4), for choosing the smallest correct implementation through YAGNI and reuse-first guidance.
- `audit-your-codebase`, vendored from [aarondfrancis's gist](https://gist.github.com/aarondfrancis/8735edbe48532f97ee5ea818db4dbd47), for a read-only, agent-orchestrated audit of a whole repository for simplifications in data structures, state representation, and ownership. Unlike every other vendored skill here, its upstream states no license, so it is redistributed in this public repository without an express grant. Remove it or seek permission from the author if that matters to you.
- `i-have-adhd`, vendored from [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd/tree/0241185d6c7f2d0763a988ce52eceb13ea9f5c1f), for explicit action-first output that is easier for ADHD readers to follow.
- `grill-with-docs`, vendored from [mattpocock/skills](https://github.com/mattpocock/skills/tree/e9fcdf95b402d360f90f1db8d776d5dd450f9234), for a user-invoked design interview that records domain vocabulary and ADRs. Its `grilling` and `domain-modeling` dependencies are included as installed skills.
- `warp-skill-doctor`, vendored from [warpdotdev/common-skills](https://github.com/warpdotdev/common-skills/tree/f589e224907eda566c13755529f59db563090d14/.agents/skills/skill-doctor), for grading installed skills by scoring recent local Warp, Claude Code, and Codex conversations against efficiency and code-quality rubrics, then drafting the skill edits the evidence justifies. It reads conversation history locally and never uploads transcripts. Renamed from upstream's `skill-doctor` because Claude Code ships a built-in `/skill-doctor` command.
- `wayfinder`, vendored from [mattpocock/skills](https://github.com/mattpocock/skills/tree/8b36d4fb2635b3c21998dcd8144439c9e5ba7302), for planning work too big for one agent session as a shared map of decision tickets on the repo's issue tracker, resolved one at a time. Its `research` and `prototype` dependencies are included as installed skills, and it reuses the installed `grilling` and `domain-modeling` skills. Tracker conventions for GitHub, GitLab, and local markdown are bundled in its `trackers/` directory.

All of these live in `shared/` and are installed for both Codex and Claude Code, except `start-task`, which stays in `codex/` because it drives the custom agents in `agents/`, and `start-feature`, which stays in `claude/` because it drives the subagents in `claude-agents/`.

`claude-agents/` also provides `researcher`, a read-only Sonnet (high effort) subagent that Claude Code uses automatically for information gathering — repository facts, code lookups, web searches. Deep research is split across parallel researchers (at most 4 unless the user sets a different limit), and the agent cannot spawn subagents of its own.

It also provides `change-reviewer`, a read-only Sonnet (high effort) subagent that reviews a completed change once for demonstrable merge-blocking defects and verifies one repair pass. `start-feature` delegates its review step to this agent rather than reviewing its own plan's output in the context that wrote it. It mirrors the Codex `feature_reviewer` agent: fixed `PASS`/`CHANGES_REQUIRED`/`BLOCKED` and `FIXES_VERIFIED`/`FIXES_NOT_VERIFIED` verdicts, and no second general review or automatic repair cycle.

Use the installed `gh-fix-ci`, `gh-address-comments`, and `yeet` skills directly for failing GitHub Actions, pull request feedback, and publication instead of routing those tasks through `start-task`.

## Installation

Run:

```sh
./install.sh
```

On Windows, run the PowerShell equivalent instead (symlink creation requires Developer Mode or an administrator shell):

```powershell
./install.ps1
```

The installer:

1. links skills under `codex/`, `claude/`, `shared/`, and `generic/` into their discovery directories;
2. links agent definitions into `~/.codex/agents` and `~/.claude/agents` so repository edits take effect without reinstalling;
3. backs up `~/.codex/config.toml` before changing it; and
4. sets `agents.max_threads` to at least 4 and `agents.max_depth` to at least 2 while preserving unrelated configuration.

Matching copied agents and skills from an older installation are migrated to links, and skill links pointing at former locations inside this repository are relinked. A matching skill directory is moved to `~/.codex/skill-backups`. The installer refuses conflicting destinations or symlinks pointing outside the repository. The PowerShell installer skips the copied-install migration, which only ever applied to Unix installations.

The installer also removes the retired `prompt-validator` and `agents-md-author` configurations from `~/.codex/agents`.

Restart Codex when updated configuration is not detected immediately.

## Start Task Behavior

Invoke the repository-change launcher from a Git repository:

```text
$start-task Add pagination to the activity feed
```

The coordinator inspects the repository, asks first whether to record docs during the interview, then uses `grill-with-docs` (yes) or plain `grilling` (no) to validate the request one decision at a time before confirming observable acceptance criteria and scope. Resolved domain terminology and significant architectural decisions are documented lazily in the target repository. It proposes independently shippable subtasks when the request is too broad. Approved subtasks are handled sequentially with separate plans, branches, reviews, and pull requests.

Each completed subtask updates the repository-root `CHANGELOG.md` under its existing unreleased section. The workflow creates a changelog with an `Unreleased` section when the repository does not have one.

Routine coordination, planning, implementation, and review use medium reasoning. Research and complex plan review remain high reasoning and run only when justified.

The implementer uses Ponytail in full mode and follows the supplied requirements and environment policy. It adds useful regression tests within scope and runs available validation, reporting missing checks. It commits each coherent working checkpoint as it is completed, in dependency order. A coordinator cannot defer commits on its own; an explicit user instruction to leave work uncommitted takes precedence. Checkpoints follow usable behavior, so mutually dependent changes stay together and a small feature can be one commit. Implementers preserve unrelated work and own their changes and commits.

Review has a fixed termination rule:

1. One initial review reports only demonstrable merge-blocking defects introduced by the change.
2. Confirmed findings receive one cohesive repair pass where practical.
3. One targeted verification checks those findings and direct repair regressions.
4. Unresolved defects are reported to the user. No second general review or automatic repair cycle starts.

The coordinator asks before committing a dirty worktree, materially replanning, pushing, or opening a pull request.

## Development

Run all checks through the devenv-provided `check` command:

```sh
devenv shell -- check
```

Inside an existing `devenv shell`, run `check`. `devenv test` uses the same command.

The suite validates skill and agent structure, parses YAML and TOML, checks shell formatting and syntax, runs focused installer smoke tests, and checks the Git diff.
