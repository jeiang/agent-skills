# Start Task Workflow Expansion

## Progress

- Current step: 5. Add adversarial plan review and simplify planner output.
- Completed steps: 1. Add progress tracking and the development shell; 2. Update installer support for nested orchestration; 3. Add repository-guidance generation; 4. Add orchestration, research, and prompt validation roles.
- Blockers: `devenv test` cannot evaluate on the current host because Lix rejects devenv's restricted client-specified `system` setting for an untrusted user. The equivalent pinned checks pass through `nix shell`.

## Implementation steps

1. **Add progress tracking and the development shell**
   - Add this progress record and a reproducible devenv shell containing the repository's validation dependencies.
   - Provide one validation entry point for skill, YAML, TOML, shell, formatting, and diff checks.
2. **Update installer support for nested orchestration**
   - Require `agents.max_depth >= 2`, preserve higher values and unrelated configuration, and retain `max_threads = 4`.
3. **Add repository-guidance generation**
   - Add the Luna-high `agents_md_author` and the startup workflow for approved root and component `AGENTS.md` generation.
4. **Add orchestration, research, and prompt validation roles**
   - Add the orchestrator, researcher, and prompt-validator agents and move workflow coordination to the orchestrator.
5. **Add adversarial plan review and simplify planner output**
   - Add the Sol-high plan reviewer and change plans from commit-level prescriptions to reviewed mid-level implementation guidance.
6. **Harden implementation behavior**
   - Enforce focused changes, static-analysis-first validation, risk-aware self-review, workaround scrutiny, and replanning thresholds.
7. **Strengthen code review and repair**
   - Make code review adversarial, repair findings independently, and escalate missed pre-existing issues.
8. **Add documentation generation and final cumulative review**
   - Add the Luna-high documentation author and sectional independent review for large cumulative changes.
9. **Rewrite the skill contract and public documentation**
   - Synchronize the skill state machine, agent definitions, UI metadata, installer behavior, and README documentation.
10. **Validate and forward-test**
    - Run the devenv checks and exercise installer and workflow scenarios in disposable repositories.

## Validation evidence

### Step 1

- `devenv update`: passed and generated `devenv.lock`.
- Official validation of `codex/start-task` and `codex/actual-budget-import`: passed.
- YAML and TOML parsing: passed.
- `sh -n` for `install.sh` and `scripts/check.sh`: passed.
- ShellCheck for `install.sh` and `scripts/check.sh`: passed. The repository's existing intentional `CDPATH= cd` idiom is excluded as SC1007.
- shfmt check for the new `scripts/check.sh`: passed. Formatting `install.sh` is deferred until its Step 2 edits.
- Taplo formatting check for `agents/*.toml`: passed.
- `git diff --check`: passed.
- Complete `scripts/check.sh` execution through Nix-provided Python with PyYAML, ShellCheck, shfmt, Taplo, and jq: passed.
- `devenv test`: blocked before project evaluation by the host Lix/devenv trust-setting incompatibility described above.

### Step 2

- `install.sh` now raises `agents.max_depth` values below 2, preserves higher values, and adds `max_threads = 4` only when absent.
- Installer configuration updates preserve inline comments, unrelated keys and tables, user-selected thread limits, and repeated-run idempotency.
- Temporary-home tests cover fresh configuration, depth upgrades, higher depths, missing settings, unrelated settings and nested tables, comment preservation, and repeated installation.
- Installer tests, POSIX syntax checks, ShellCheck, and strict shfmt checks are integrated into `scripts/check.sh`.
- Complete `scripts/check.sh` execution passed in the Nix-provided validation environment.

### Step 3

- Added `agents_md_author` with the required Luna high model and workspace-write sandbox.
- The author is restricted to one explicitly approved canonical `AGENTS.md` for its assigned root or component and cannot modify other files or manage Git publication.
- Author guidance requires repository-grounded structure, build, validation, and convention instructions; path and command verification; and a final self-review without invented policy.
- Added semantic agent-config validation for required names, models, reasoning efforts, sandbox modes, non-empty role instructions, and the repository-guidance safety contract.
- Integrated agent-config validation into `scripts/check.sh`.

### Step 4

- Added the Luna-high, workspace-write `task_orchestrator` as the workflow coordinator, with baseline and guidance discovery, prompt confirmation, research delegation, per-part state, dependency gates, isolated context, sequential writes, and publication approvals.
- Added the Luna-high, read-only `task_researcher`, restricted to bounded questions and concise findings cited to repository evidence or primary sources.
- Added the Sol-medium, read-only `prompt_validator`, which separates independently shippable concerns and reports acceptance criteria, dependencies, ambiguities, clarification questions, and explicit research signals without editing files.
- Extended semantic agent validation to assert all three roles' models, reasoning efforts, sandbox modes, and critical workflow boundaries.
