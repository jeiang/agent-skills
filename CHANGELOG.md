# Changelog

## Unreleased

### Added

- `fast-jev-compaction` as a vendored Claude Code plugin from tamaratran/fast-jev-compaction under `claude/`, installed by the personal profile into `~/.claude/skills/` where Claude Code loads it as `fast-jev-compaction@skills-dir`. The installers and the flake now link a `claude/` directory carrying `.claude-plugin/plugin.json` for the Claude harness only. It needs Claude Code 2.1.274+, `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1`, and `TYPESAFE_API_KEY`; the README says where to set them.
- `typesafe-ai` as a vendored skill from typesafe-ai/skills, with its upstream MIT license, Codex display metadata, and source metadata, for designing TypeSafe System One judgments (Choice, Noul, Score) against the live TypeSafe docs. A local section makes the agent check for `TYPESAFE_API_KEY` before running API calls, and the README says where each harness sets it. It replaces upstream's `typesafe@typesafe-ai` Claude Code plugin and is excluded from the work profile.
- A Nix flake exposing `packages.<system>.<harness>-<profile>`: store paths with the instruction file, skills, and agents laid out as the installer would, so Nix configurations can link them without running the installer.
- Explicit installation profiles. `install.sh <harness> <profile>` and `install.ps1 <harness> <profile>` pair any harness with `personal`, `work`, or a new `generic` profile that assumes no operating system, stack, or tools. Each profile owns its environment policy and excluded-skill list under `profiles/`.
- A Jinja2 renderer (`scripts/render.py`) that writes the combined instructions and the shared subagents into a committed `dist/` directory; `check` fails when `dist/` is stale.
- Copilot custom agents: exactly `reviewer` and `researcher`, pinned to GPT-5.6 Luna, unable to nest subagents, rendered from the same bodies as the Claude and Codex reviewer and researcher.
- A GitHub Actions workflow that runs `devenv test` on pull requests and pushes to `main`.
- `lib.entries.<harness>.<profile>`, the skill and agent entry names and the instruction path each flake package installs, so a consumer that links one entry at a time does not have to enumerate the built tree.

- Common working instructions with separate personal and work policies, a dated platform research report, and reproducible workflow scenarios.

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

- The skill validator accepts an optional `metadata` frontmatter mapping, as upstream skills such as `i-have-adhd` ship it.
- `grilling` adopts upstream's round-by-round frontier interview and asks each round's closed questions through the harness's structured question tool when one exists (Claude Code's `AskUserQuestion`), with two to four options, a one-line trade-off each, and the recommendation first; open-ended questions stay in chat. The common instructions and README no longer prescribe one decision per turn and defer to the skill.
- Vendored skills updated to their current upstreams: mattpocock/skills `959a8e9` (`grilling`, `grill-with-docs`, `domain-modeling`, `wayfinder`, `research`, `prototype`, and the bundled tracker docs), ayghri/i-have-adhd `0a84de4`, ponytail v4.10.0, and warpdotdev/common-skills `82d2bd9`. Local adaptations are re-applied and listed in each `UPSTREAM.md`; `i-have-adhd` gains upstream's persistence section, harness-precedence exceptions, and Gemini CLI command, `domain-modeling` triggers on CONTEXT.md and ADR edits, and `warp-skill-doctor` collects Pi, Grok Build, and ZCode sessions.
- The work profile keeps Ponytail in full mode without an opt-out; the personal and generic profiles keep the existing opt-out.
- The reviewer body now states that it is not pedantic and shares one source across Claude, Codex, and Copilot. Codex and Claude agent files that are not shared moved to `agents/codex/` and `agents/claude/`; the installers relink existing links from the former locations.
- `instructions/personal-skills.txt` moved to `profiles/work/excluded-skills.txt`; the generic profile keeps `warp-skill-doctor`.

- Install one selected agent at a time, with self-contained common plus environment instructions, explicit backup-and-replace migration for unmanaged instructions, and preserved unrelated configuration. Copilot Chat in VS Code receives only work-compatible skills and policy.

- Aligned Ponytail, Grilling, domain validation skills, and optional agents with selective clarification, environment restrictions, useful testing, and dependency-ordered working commits.
- Replaced exact prompt-wording validation with structural agent checks and cross-platform skill invocation consistency checks.

- `nixos-change-validation` now triggers on repo-wide mechanical `.nix` edits such as formatting, comment, or refactor sweeps; requires resolving the repository's development shell before running its commands; requires proving a behavior-preserving change by comparing derivation paths rather than asserting it; and warns that piping a long check through `tail` discards the error that made it fail.
- `grilling` now extends its look-up-the-fact rule to facts the interview asserts, not only ones it would otherwise ask about, and requires naming the source checked before closing a branch as impossible or infeasible.
- `wayfinder`'s ticket-resolution step now says to read a map's research fact sheets with the harness's file-reading tool rather than a shell `cat`, and to change tools rather than re-issue a read that came back truncated.
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

- The `start-task` and `start-feature` launchers, mandatory task coordinator, and automatic Codex concurrency configuration. Ordinary requests use the shared dynamic workflow.

- The prompt-validator and AGENTS.md-author roles, repeated adversarial review loops, exact-prose validators, and stale workflow progress log.
