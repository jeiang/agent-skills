# Changelog

## Unreleased

### Added

- A Claude Code `change-reviewer` subagent: read-only review of a completed change for demonstrable merge-blocking defects on Sonnet at high effort, with fixed verdicts and one bounded verification pass. `start-feature` now delegates its review step to this agent instead of reviewing its own plan's output.
- GitHub Copilot CLI skill support: `shared/` skills are now also linked into `~/.copilot/skills`, and Copilot reads `generic/` skills from `~/.agents/skills` natively.
- A PowerShell installer (`install.ps1`) for Windows, with a `pwsh` smoke test that `check` runs when PowerShell is available.
- Claude Code skill support: a `claude/` directory linked into `~/.claude/skills` and a `shared/` directory linked into both `~/.codex/skills` and `~/.claude/skills`.
- A Claude Code `start-feature` skill that establishes feature context through a grilling interview with domain-modeling documentation before planning, then delegates implementation to the Sonnet `feature-implementer` subagent, which loads Ponytail in full mode.
- Installer links and structural validation for Claude Code subagent definitions in `claude-agents/`.
- Focused Kubernetes delivery, Kubernetes diagnosis, NixOS validation, and Azure Pipelines maintenance skills.
- A `check` command in the devenv shell for running repository validation.
- Ponytail v4.8.4 as a vendored skill with its upstream MIT license and source metadata.
- `i-have-adhd` as a vendored skill with its upstream MIT license, Codex display metadata, and source metadata.
- A Claude Code `researcher` subagent: read-only information gathering (repo facts, code lookups, web searches) on Sonnet at high effort, used automatically, fanned out in parallel (capped at 4 unless the user sets a limit) for deep research, and unable to spawn subagents.
- `audit-your-codebase` as a vendored skill from aarondfrancis's gist, for a read-only, agent-orchestrated audit of a whole repository for simplifications in data structures, state representation, and ownership.
- `wayfinder` as a vendored skill from mattpocock/skills, with its `research` and `prototype` dependencies vendored alongside and the upstream issue-tracker docs bundled in its `trackers/` directory in place of the un-vendored `setup-matt-pocock-skills` skill.

### Changed

- The start-task coordinator now asks whether to record docs before the interview (choosing `grill-with-docs` or plain `grilling`), splits each approved plan into ordered implementation parts dispatched one at a time, and treats implementer commits as final history it never amends, squashes, rebases, or resets.
- The Codex `feature_implementer` agent now commits after each logical change rather than once per assignment, stages only touched files, and its commit rules take precedence over the task prompt — matching the Claude `feature-implementer` subagent.
- Calibrated `i-have-adhd` to the reader's stated expertise and context while preserving its action-first, command-by-command guidance.
- Moved every skill except the Codex-specific `start-task` from `codex/` to `shared/` so Codex and Claude Code reuse them, and reworded skill descriptions to be agent-neutral. The installer relinks existing skill links that point at former locations inside the repository.
- The start-task coordinator now validates each request through Grill with Docs before planning, while its feature implementer continues to load Ponytail in full mode.
- Simplified the start-task agents around scoped clarification, practical implementation, one bounded review and repair pass, and required changelog maintenance.
- Replaced the installer and validation matrix with focused symlink installation, configuration preservation, structural checks, and smoke tests.
- Configured the feature implementer to use Ponytail in full mode while preserving approved requirements and test-plan precedence.
- The start-feature skill now invokes `grill-with-docs` by name (model invocation enabled on that skill), flags multi-outcome requests during scope confirmation, prepares branch and dirty-worktree state before spawning the implementer, and reviews the cumulative diff with at most one repair assignment.
- The Claude `feature-implementer` subagent now commits in logical targeted chunks — one conventional commit per plan step with validation passing — stages only touched files, and keeps an existing repository-root `CHANGELOG.md` current, while still never pushing or switching branches.
- The Claude `feature-implementer` subagent now commits after each logical change (a plan step may yield several commits), and its commit rules take precedence over the task prompt: a prompt telling it not to commit is disobeyed and reported.
- The start-feature skill now asks whether to create docs before the interview (choosing `grill-with-docs` or plain `grilling`) and forbids the main agent from countermanding, amending, squashing, rebasing, or resetting the implementer's commits.

### Fixed

- Added git to the devenv shell so the `check` command can run its final `git diff --check` step.

### Removed

- The prompt-validator and AGENTS.md-author roles, repeated adversarial review loops, exact-prose validators, and stale workflow progress log.
