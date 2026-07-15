# Changelog

## Unreleased

### Added

- Focused Kubernetes delivery, Kubernetes diagnosis, NixOS validation, and Azure Pipelines maintenance skills.
- A `check` command in the devenv shell for running repository validation.
- Ponytail v4.8.4 as a vendored skill with its upstream MIT license and source metadata.

### Changed

- The start-task coordinator now validates each request through Grill with Docs before planning, while its feature implementer continues to load Ponytail in full mode.
- Simplified the start-task agents around scoped clarification, practical implementation, one bounded review and repair pass, and required changelog maintenance.
- Replaced the installer and validation matrix with focused symlink installation, configuration preservation, structural checks, and smoke tests.
- Configured the feature implementer to use Ponytail in full mode while preserving approved requirements and test-plan precedence.

### Removed

- The prompt-validator and AGENTS.md-author roles, repeated adversarial review loops, exact-prose validators, and stale workflow progress log.
