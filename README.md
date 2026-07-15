# Agent Skills

A Git-managed collection of Codex skills and custom agents.

## Layout

- `codex/` contains Codex-specific skills linked into `~/.codex/skills`.
- `generic/` is reserved for portable skills linked into `~/.agents/skills`.
- `agents/` contains custom-agent definitions linked into `~/.codex/agents`.
- `install.sh` installs the links and required Codex agent limits.

The included skills are:

- `actual-budget-import` for importing natural-language transactions through the Actual Budget CLI.
- `start-task` for a repository change with confirmed scope, approved planning, focused implementation, bounded review, and optional publication.
- `kubernetes-delivery` for preparing and validating Helm, Kubernetes, container, and delivery configuration without deploying it.
- `kubernetes-diagnose` for investigating Kubernetes workload and platform failures.
- `nixos-change-validation` for preparing and validating NixOS changes and safe activation instructions.
- `azure-pipelines-maintenance` for Azure Pipelines YAML, templates, conditions, artifacts, and deployments.
- `ponytail`, vendored from [DietrichGebert/ponytail v4.8.4](https://github.com/DietrichGebert/ponytail/tree/v4.8.4), for choosing the smallest correct implementation through YAGNI and reuse-first guidance.

Use the installed `gh-fix-ci`, `gh-address-comments`, and `yeet` skills directly for failing GitHub Actions, pull request feedback, and publication instead of routing those tasks through `start-task`.

## Installation

Run:

```sh
./install.sh
```

The installer:

1. links skills under `codex/` and `generic/` into their discovery directories;
2. links agent TOML files into `~/.codex/agents` so repository edits take effect without reinstalling;
3. backs up `~/.codex/config.toml` before changing it; and
4. sets `agents.max_threads` to at least 4 and `agents.max_depth` to at least 2 while preserving unrelated configuration.

Matching copied agents and skills from an older installation are migrated to links. A matching skill directory is moved to `~/.codex/skill-backups`. The installer refuses conflicting destinations or symlinks pointing elsewhere.

The installer also removes the retired `prompt-validator` and `agents-md-author` configurations from `~/.codex/agents`.

Restart Codex when updated configuration is not detected immediately.

## Start Task Behavior

Invoke the repository-change launcher from a Git repository:

```text
$start-task Add pagination to the activity feed
```

The coordinator inspects the repository before asking questions, confirms observable acceptance criteria and scope, and proposes independently shippable subtasks when the request is too broad. Approved subtasks are handled sequentially with separate plans, branches, reviews, and pull requests.

Each completed subtask updates the repository-root `CHANGELOG.md` under its existing unreleased section. The workflow creates a changelog with an `Unreleased` section when the repository does not have one.

Routine coordination, planning, implementation, and review use medium reasoning. Research and complex plan review remain high reasoning and run only when justified.

The implementer automatically uses the bundled Ponytail skill in full mode. It makes the smallest practical change, avoids speculative abstractions and excessive comments, and does not add tests unless the approved plan requires them. Approved requirements and the start-task plan gate take precedence over Ponytail. It runs relevant existing validation, self-reviews against the acceptance criteria, and creates one conventional commit per cohesive change.

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
