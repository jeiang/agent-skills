# Changelog

## Unreleased

### Added

- Claude Code skill support: a `claude/` directory linked into `~/.claude/skills` and a `shared/` directory linked into both `~/.codex/skills` and `~/.claude/skills`.
- A Claude Code `start-feature` skill that establishes feature context through a grilling interview with domain-modeling documentation before planning, then delegates implementation to the Sonnet `feature-implementer` subagent, which loads Ponytail in full mode.
- Installer links and structural validation for Claude Code subagent definitions in `claude-agents/`.
- Focused Kubernetes delivery, Kubernetes diagnosis, NixOS validation, and Azure Pipelines maintenance skills.
- A `check` command in the devenv shell for running repository validation.
- Ponytail v4.8.4 as a vendored skill with its upstream MIT license and source metadata.

### Changed

- Moved every skill except the Codex-specific `start-task` from `codex/` to `shared/` so Codex and Claude Code reuse them, and reworded skill descriptions to be agent-neutral. The installer relinks existing skill links that point at former locations inside the repository.
- The start-task coordinator now validates each request through Grill with Docs before planning, while its feature implementer continues to load Ponytail in full mode.
- Simplified the start-task agents around scoped clarification, practical implementation, one bounded review and repair pass, and required changelog maintenance.
- Replaced the installer and validation matrix with focused symlink installation, configuration preservation, structural checks, and smoke tests.
- Configured the feature implementer to use Ponytail in full mode while preserving approved requirements and test-plan precedence.

### Fixed

- Added git to the devenv shell so the `check` command can run its final `git diff --check` step.

### Removed

- The prompt-validator and AGENTS.md-author roles, repeated adversarial review loops, exact-prose validators, and stale workflow progress log.
