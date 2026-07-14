# Start Task Workflow Expansion

## Progress

- Current step: 9. Rewrite the skill contract and public documentation; the thin skill interface is complete and public README work is pending the documentation-author stage.
- Completed steps: 1. Add progress tracking and the development shell; 2. Update installer support for nested orchestration; 3. Add repository-guidance generation; 4. Add orchestration, research, and prompt validation roles; 5. Add adversarial plan review and simplify planner output; 6. Harden implementation behavior; 7. Strengthen code review and repair; 8. Add documentation generation and final cumulative review.
- Blockers: None.

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
- `devenv test` initially failed during evaluation because the configured devenv version does not provide `languages.python.packages`; the Python environment repair recorded below replaces that unsupported option.

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
- The semantic agent validator and `git diff --check` passed. The complete check entry point was deferred until the devenv Python environment repair recorded below.

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

### Devenv Python environment repair

- Replaced the unsupported `languages.python.packages` option with a stable `python3.withPackages` package expression containing PyYAML.
- `nix-instantiate --parse devenv.nix`: passed.
- `devenv test`: passed, including skill validation, agent and launcher semantic validation, YAML and TOML parsing, shell validation and formatting, installer tests, and `git diff --check`.

### Review repair 1: agent thread capacity

- Changed installer configuration handling to require `agents.max_threads >= 4`, preserve higher numeric values and inline comments, and reject malformed direct values without replacing the configuration file.
- Extended disposable-home coverage for absent, low, exact, high, and malformed thread values, comment preservation, and repeated-run idempotency while retaining the existing depth scenarios.
- `devenv test`: passed, including the complete installer matrix and repository validation suite.

### Review repair 2: canonical agents TOML handling

- Restricted installer rewrites to a top-level bare `[agents]` table with direct bare integer `max_threads` and `max_depth` keys.
- Added atomic refusal for quoted, dotted, inline, array-of-tables, duplicate, conflicting, and other agents aliases that could otherwise be silently shadowed or corrupted.
- Added before-and-after TOML parsing and byte-identity checks for valid refused fixtures, explicit duplicate-definition refusal, canonical root-table assertions for supported fixtures, and preservation coverage for unrelated quoted and dotted TOML.
- `devenv test`: passed, including the expanded safe-support and atomic-refusal installer fixtures and the complete repository validation suite.

### Review repair 3: symlinked config refusal

- Added a preflight check before every installer mutation that refuses a symlinked `~/.codex/config.toml` and identifies both the link and its recorded target.
- Added relative, absolute, and dangling symlink fixtures that verify link identity, target bytes where present, actionable errors, and absence of partial skill or agent installation, plus an explicit regular-file success case.
- `devenv test`: passed, including the symlink identity, atomic-refusal, regular-file, and complete repository validation scenarios.

### Review repair 4: self-contained skill validation

- Replaced the required external `$CODEX_HOME` quick validator with a repository-owned generic validator for readable `SKILL.md` files, exact YAML frontmatter fields, names, descriptions, directory matching, and nonempty bodies.
- Kept the start-task launcher and UI semantic validator as a separate workflow-specific check.
- Added disposable valid and failure fixtures for malformed YAML, missing, extra, and duplicate fields, path/name mismatches, invalid names and descriptions, missing skill files, and missing or empty bodies.
- `devenv test`: passed without an external Codex skill installation, including all generic fixtures, start-task semantic validation, and the complete repository suite.

### Review repair 5: mandatory reviewed-plan gate

- Replaced optional plan-review coordination with a mandatory same-planner correction loop through the adversarial `plan_reviewer` until exact `PASS` for every initial per-part plan.
- Required the complete reviewed plan and every materially corrected replacement to receive explicit user approval before implementation or resumed implementation, with initial part-branch creation only after approval.
- Added ordered semantic assertions for both initial and materially corrected plan gates and an explicit prohibition on the former optional-review wording.
- `devenv test`: passed, including ordered orchestrator-contract validation and the complete repository suite.

### Review repair 6: research-informed scope confirmation

- Moved materially scope-affecting research before final user confirmation and required cited findings to return to the same prompt-validator thread for revised parts and acceptance criteria.
- Added impact classification for research performed after confirmation; material findings reopen prompt validation and user confirmation before planning, while nonmaterial findings require recorded evidence and a no-impact classification.
- Added ordered semantic assertions for both the pre-confirmation research path and the conditional post-confirmation revalidation path.
- `devenv test` exposed and prompted correction of a stale loose research marker; a full rerun was blocked when the host approval service reached its usage limit. Focused ordered-gate validation and `git diff --check` passed after the correction.

### Review repair 7: refreshed per-part branch baseline

- Required every independent part to return to the recorded default branch and establish a new baseline before planning; the next part may never inherit the previous part branch or baseline.
- Added an ordered clean-state and safe-refresh gate covering staged, unstaged, and untracked state; fast-forward-only upstream updates; exact blockers for missing upstreams, failed fetches, divergence, and failed updates; and preservation of user work without implicit stash, reset, clean, overwrite, merge, or rebase operations.
- Required every declared dependency and repository-guidance prerequisite to be verified as merged in refreshed default-branch history before planning.
- Required the refreshed default tip to be recorded in workflow state and supplied to planning and plan review, then reverified after user approval before creating the part branch directly from that exact commit.
- Added ordered semantic validation for the full baseline-refresh and post-approval branch-creation transitions, including their stop conditions.
- `devenv shell -- ./scripts/check.sh` and `devenv test`: passed, including ordered orchestrator-contract validation and the complete repository suite.

### Review repair 8: implementer replanning transitions

- Added one fail-closed transition for an implementer threshold overrun or invalid material planning assumption; implementation stops immediately without staging or committing partial work.
- Required a complete replanning bundle containing completed commits, the partial diff and affected files, substantive and excluded counts, architectural-component count, validation results, trigger evidence, and distinguished pre-existing user changes.
- Required the same planner to produce a corrected mid-level plan that accounts for preserved partial work and classifies focused subtasks as inseparable or independently shippable.
- Kept inseparable subtasks in the current part and returned independent splits through prompt validation, bounded research when signaled, renewed scope confirmation, and separate baseline, branch, review-budget, and pull-request lifecycles.
- Prohibited branch switching while partial work remains and required the corrected current-part plan to pass adversarial plan review and renewed user approval before one-subtask-at-a-time implementation resumes.
- Added ordered semantic validation for the complete conditional transition and its preservation, splitting, scope-confirmation, and approval gates.
- `devenv shell -- ./scripts/check.sh` and `devenv test`: passed, including the ordered implementer-replanning transition and the complete repository suite.
- `devenv shell -- python scripts/validate-agent-configs.py`: passed after self-review narrowed the planner evidence bundle to workflow-owned partial work and necessary overlapping user context.

### Review repair 9: explicit code-review modes

- Added `FULL`, `SECTION`, and `CROSS_INTERFACE` reviewer modes with distinct required inputs, scopes, and mode-qualified verdicts.
- Restricted whole-change approval to `FULL`; section reviewers receive bounded files and diffs and cannot claim global approval, while cross-interface reviewers receive declared boundaries and interactions and assess integration only.
- Kept initial and later-pass origin classification consistent across modes, including prior-finding disposition and evidence-based `FEATURE_CHANGE`, `REPAIR_INTRODUCED`, and `PRE_EXISTING_MISSED` fields.
- Required large cumulative reviews to cover every recorded nonoverlapping section plus one cross-interface review at the same HEAD before consolidation.
- Required a global pass only when every section passes and the cross-interface review passes; missing, duplicate, stale, wrong-mode, or input-error results block consolidation.
- Added semantic validation for mode inputs, verdicts, origin handling, ordered aggregation, and contradictory repository-wide diff requirements in bounded modes.
- `devenv shell -- ./scripts/check.sh` and `devenv test`: passed, including reviewer-mode semantics, bounded-mode contradiction checks, cumulative aggregation rules, and the complete repository suite.

### Review repair 10: explicit isolated repair approval

- Replaced ambiguous repair approval wording with an ordered user gate for every individual product-review and final cumulative-review finding.
- Required one separately spawned planner and one focused repair plan per finding, with plan-reviewer correction when missed-issue escalation requires it.
- Required the complete isolated plan to be shown and explicitly approved before one implementer or documentation-author invocation.
- Required isolated validation, writer self-review, one finding-only conventional commit, and control-file evidence before selecting the next finding.
- Required material repair-plan, user-edit, or implementation changes to restart full per-part plan review and renewed approval, followed by the finding's separate isolated approval gate.
- Added ordered semantic validation for product, material-change, and final-review repair transitions and removed the former `any required approval` ambiguity.
- `devenv shell -- ./scripts/check.sh` and `devenv test`: passed, including ordered isolated-repair approval gates, ambiguity rejection, and the complete repository suite.

### Review repair 11: separate review budgets

- Added an immutable per-part `product_review_verdicts` counter initialized immediately before product review and capped at five `FULL` product verdicts.
- Ended product review at a provisional product pass, or stopped the part before documentation and publication when the fifth product verdict still has issues.
- Added a distinct `final_review_verdicts` counter initialized only after documentation while preserving the frozen product counter.
- Counted one final `FULL` verdict or one complete sectional-batch global verdict as one final verdict; individual section and cross-interface reports never count separately.
- Ended final review at a global pass, or stopped without further repairs or publication when the fifth final verdict still has issues.
- Prohibited resetting, decrementing, transferring, combining, or reusing either counter across repairs, replanning, documentation, or review repartitioning.
- Added ordered semantic validation for initialization, qualifying verdicts, control-file evidence, success and exhaustion exits, and counter isolation.
- `devenv shell -- ./scripts/check.sh` and `devenv test`: passed, including ordered counter lifecycle assertions, shared-budget rejection, and the complete repository suite.

### Review repair 12: post-repair documentation refresh

- Added a conditional documentation refresh before cumulative re-review whenever final-review repairs affect product code, configuration, tests, generated user-facing behavior, or interface behavior.
- Required all isolated product repairs to finish before an audit-only documentation-author invocation evaluates newly queued stale, missing, contradictory, or invalid documentation.
- Routed every resulting documentation finding through its own focused planner plan, applicable escalation review, explicit user approval, documentation-author repair, validation, self-review, and documentation-only commit.
- Allowed documentation-only repair batches to proceed directly to cumulative re-review without a redundant audit.
- Ordered mixed batches as product repairs, documentation audit and isolated repairs, then cumulative re-review, with no concurrent writers.
- Preserved the existing final-review budget: audits and repair commits do not consume, reset, or reinitialize the counter; only the next cumulative global verdict counts.
- Added ordered semantic validation for product-affecting, documentation-only, mixed-batch, approval, commit, and counter-preservation paths.
- `devenv shell -- ./scripts/check.sh` and `devenv test`: passed, including ordered post-repair documentation transitions, final-counter preservation, and the complete repository suite.

### Review repair 13: cross-contract mutation validation

- Added a final cross-contract semantic audit spanning plan and repair approvals, role ownership, minimal context, branch freshness, implementation replanning, reviewer modes and aggregation, separate review budgets, and documentation reruns.
- Added an isolated agent-directory override so the repository validator can evaluate disposable contract copies without modifying installed or tracked agent definitions.
- Added targeted mutation fixtures proving validation fails for omitted approval and context steps, reordered branch refresh, optional plan review, wrong writer ownership, missing threshold stops, contradictory bounded review inputs, incomplete aggregation, shared review budgets, and weakened documentation-audit safety.
- Integrated the mutation fixture runner into the repository check entry point.
- Kept the repair within the implementer limits: fewer than 500 substantive lines, fewer than 10 files, and no more than two independently testable components.
- `devenv shell -- ./scripts/check.sh` and `devenv test`: passed, including the final cross-contract audit, all 10 rejected mutation fixtures, and the complete repository suite.

### Review repair 14: multiline TOML preflight refusal

- Added an installer preflight that refuses multiline basic (`"""`) or literal (`'''`) string delimiters anywhere in the Codex configuration before the line-oriented AWK rewrite starts.
- Added an actionable diagnostic directing the user to replace multiline strings with single-line strings before installation.
- Added valid multiline basic and literal TOML fixtures whose contents mimic `[agents]`, `max_threads`, and `max_depth` configuration.
- Required both fixtures to exit nonzero while preserving byte-identical, parseable TOML through the existing atomic-refusal assertions.
- `devenv shell -- ./scripts/check.sh` and `devenv test`: passed, including multiline basic and literal atomic-refusal fixtures and the complete repository suite.
