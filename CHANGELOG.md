# Changelog

## Unreleased

### Added

- A `devshell-preflight` skill for resolving a repository's command entry point (direnv, `devenv.nix`, `flake.nix`, `shell.nix`) before running its commands, including the `devenv.nix`-without-`flake.nix` case where `nix develop` is the wrong entry point, git worktrees that are not part of the flake, and the `python3.withPackages` wrapper needed to put a library on the interpreter's path.
- An `activation-and-state.md` reference for `nixos-change-validation` covering what `nixos-rebuild test` cannot validate, impermanence and secret-decryption failures that appear only at activation, evaluation scope, and deploy-rs magic-rollback behavior.
- An `immutability-and-rollout.md` reference for `kubernetes-delivery` covering in-place-immutable fields, verified image pull policy defaults, rollout and probe semantics, and the Helm rendering and upgrade behavior that local validation cannot prove.
- A `failure-signatures.md` reference for `kubernetes-diagnose` mapping pod, traffic, and rollout failure signatures to the check that discriminates between their plausible causes.
- An `expressions-and-variables.md` reference for `azure-pipelines-maintenance` covering the three expression syntaxes, output-variable reference forms per producer/consumer distance, the deployment-job double-name quirk, and condition semantics for skipped and canceled upstreams.
- Codex display metadata for `ponytail` and `audit-your-codebase`, the only shared skills that were missing an `agents/openai.yaml`.
- An `eli5` skill for explaining something at the reader's actual level, grounded in the real implementation, with optional `eli5`, `colleague`, and `expert` altitudes.
- A `diagram` skill for deriving Mermaid diagrams from repository evidence and committing them beside their subject, including the Azure DevOps wiki's Mermaid limitations.
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
- `warp-skill-doctor` as a vendored skill from warpdotdev/common-skills, renamed from upstream's `skill-doctor` to avoid clashing with Claude Code's built-in `/skill-doctor` command, with its upstream MIT license, Codex display metadata, and source metadata, for grading installed skills against recent local Warp, Claude Code, and Codex conversations.
- `wayfinder` as a vendored skill from mattpocock/skills, with its `research` and `prototype` dependencies vendored alongside and the upstream issue-tracker docs bundled in its `trackers/` directory in place of the un-vendored `setup-matt-pocock-skills` skill.

### Changed

- `nixos-change-validation` now triggers on repo-wide mechanical `.nix` edits such as formatting, comment, or refactor sweeps; requires resolving the repository's development shell before running its commands; requires proving a behavior-preserving change by comparing derivation paths rather than asserting it; and warns that piping a long check through `tail` discards the error that made it fail.
- The README now states that `audit-your-codebase` is vendored from a gist with no stated license, unlike the other vendored skills.
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
