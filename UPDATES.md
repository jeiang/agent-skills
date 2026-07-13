# Start Task Workflow Expansion

## Progress

- Current step: 9. Rewrite the skill contract and public documentation; the thin skill interface is complete and public README work is pending the documentation-author stage.
- Completed steps: 1. Add progress tracking and the development shell; 2. Update installer support for nested orchestration; 3. Add repository-guidance generation; 4. Add orchestration, research, and prompt validation roles; 5. Add adversarial plan review and simplify planner output; 6. Harden implementation behavior; 7. Strengthen code review and repair; 8. Add documentation generation and final cumulative review.
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

### Step 5

- Added the Sol-high, read-only `plan_reviewer`, which adversarially checks complete problem coverage, feasibility, requirements, risks, validation, scope, workarounds, and overengineering.
- Defined an exact `PASS` or `ISSUES` verdict protocol and require exhaustive, concrete findings to return to the planner until none remain.
- Reframed planner output around mid-level outcomes, behavior, subsystems, interfaces, risks, edge cases, and proportionate validation.
- Prohibited commit planning, commit-message prescriptions, and unnecessary line-, parameter-, or symbol-level implementation minutiae.
- Required isolated treatment of reviewer findings and evidence-based replanning for invalid implementation assumptions.
- Extended semantic agent validation to protect the planner and plan-reviewer contracts.

### Step 6

- Restricted the implementer to one approved cohesive change and only the context needed for that change.
- Prohibited implementer documentation edits and required documentation needs to be queued for the dedicated documentation agent.
- Required repository static tooling first, with language-standard formatting and strict compiler, type-checker, and linter settings for touched code when no repository style policy exists.
- Added explicit limits of 500 substantive non-generated lines, 10 product files, or two independently testable architectural components; exceeding a limit stops work uncommitted for planner-directed splitting.
- Required one-line workaround justification and planner rework or replanning when a workaround cannot be justified concisely.
- Added final self-review of approved risks, diff necessity and scope, static and focused validation, style, conventions, and workaround justification.
- Let the implementer select sensible conventional commit boundaries while preserving staged-file isolation and the prohibition on empty or rewritten commits.
- Extended semantic agent validation to protect the hardened implementer contract.

### Step 7

- Made the Sol-medium, read-only feature reviewer adversarial and exhaustive across correctness, security, regressions, compatibility, error handling, plan fulfillment, and required validation.
- Required complete baseline-to-HEAD review on the first pass and prior-finding disposition, repair-range inspection, and cumulative assessment on later passes.
- Added evidence-based `REPAIR_INTRODUCED` and `PRE_EXISTING_MISSED` classifications for new findings, with exact verdict and issue-reporting fields.
- Required a separate planner and implementer invocation, validation, self-review, and conventional commit for every review finding before cumulative re-review.
- Added escalation from the first missed pre-existing issue to exhaustive entire-part review, then to adversarial plan-reviewer approval if another pre-existing issue is missed.
- Preserved the five-completed-verdict limit and stop-without-publication behavior for unresolved findings.
- Extended semantic agent validation to protect the adversarial review and isolated repair-loop contracts.
- The semantic agent validator and `git diff --check` passed. The complete check entry point could not run in this shell because the ambient Python lacks `tomllib` and the available fallback Nix environments did not provide both the `python` executable and PyYAML together.

### Step 8

- Added the Luna-high, workspace-write `documentation_author`, restricted to necessary documentation changes after a provisional product-code pass.
- Required a repository-grounded audit for stale, missing, contradictory, or invalid documentation without speculative guides, duplicate content, or changes to code, configuration, tests, workflow state, or Git publication state.
- Required documentation validation, complete-diff self-review, and a focused conventional documentation commit boundary.
- Added orchestration for queued documentation findings, a focused documentation stage, and final cumulative review across code, tests, configuration, and documentation.
- Added sectional review when the substantive cumulative diff exceeds 400 lines or 8 files, using independent reviewers for cohesive subsections plus a separate cross-section interface review.
- Required all distinct findings to be retained and routed independently through implementer or documentation-author repairs according to file domain, followed by another cumulative review within the five-verdict policy.

### Step 9

- Replaced the legacy parent-managed planner, implementer, and reviewer procedure in `codex/start-task/SKILL.md` with a thin launcher that records the minimum invocation baseline and spawns only `task_orchestrator`.
- Restricted the launcher to relaying orchestrator questions, approvals, blockers, progress, and results through the same orchestrator thread; specialist work cannot be performed or substituted by the parent.
- Updated the skill trigger description and UI metadata to cover repository guidance, prompt validation and research, approved planning, focused implementation, adversarial review, documentation maintenance, and per-part publication.
- Added semantic validation for the thin-launcher boundary, trigger description, and UI contract, and integrated it into `scripts/check.sh`.
- Public README synchronization remains pending for the dedicated documentation-author stage.
