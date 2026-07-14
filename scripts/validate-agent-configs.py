#!/usr/bin/env python3
from pathlib import Path
import os
import sys
import tomllib


REPO_ROOT = Path(__file__).resolve().parents[1]
AGENTS_DIR = Path(
    os.environ.get("START_TASK_AGENT_CONFIG_DIR", REPO_ROOT / "agents")
).resolve()
DISPLAY_ROOT = AGENTS_DIR.parent if "START_TASK_AGENT_CONFIG_DIR" in os.environ else REPO_ROOT

EXPECTED = {
    "agents-md-author.toml": {
        "name": "agents_md_author",
        "model": "gpt-5.6-luna",
        "model_reasoning_effort": "high",
        "sandbox_mode": "workspace-write",
    },
    "documentation-author.toml": {
        "name": "documentation_author",
        "model": "gpt-5.6-luna",
        "model_reasoning_effort": "high",
        "sandbox_mode": "workspace-write",
    },
    "feature-implementer.toml": {
        "name": "feature_implementer",
        "model": "gpt-5.6-terra",
        "model_reasoning_effort": "medium",
        "sandbox_mode": "workspace-write",
    },
    "feature-planner.toml": {
        "name": "feature_planner",
        "model": "gpt-5.6-sol",
        "model_reasoning_effort": "high",
        "sandbox_mode": "read-only",
    },
    "plan-reviewer.toml": {
        "name": "plan_reviewer",
        "model": "gpt-5.6-sol",
        "model_reasoning_effort": "high",
        "sandbox_mode": "read-only",
    },
    "feature-reviewer.toml": {
        "name": "feature_reviewer",
        "model": "gpt-5.6-sol",
        "model_reasoning_effort": "medium",
        "sandbox_mode": "read-only",
    },
    "prompt-validator.toml": {
        "name": "prompt_validator",
        "model": "gpt-5.6-sol",
        "model_reasoning_effort": "medium",
        "sandbox_mode": "read-only",
    },
    "task-orchestrator.toml": {
        "name": "task_orchestrator",
        "model": "gpt-5.6-luna",
        "model_reasoning_effort": "high",
        "sandbox_mode": "workspace-write",
    },
    "task-researcher.toml": {
        "name": "task_researcher",
        "model": "gpt-5.6-luna",
        "model_reasoning_effort": "high",
        "sandbox_mode": "read-only",
    },
}

AUTHOR_CONTRACT = (
    "explicitly approved",
    "assigned canonical `AGENTS.md`",
    "exclusively owned",
    "Do not invent policy",
    "Verify every referenced path",
    "Do not create or switch branches, commit, push, or open a pull request",
)

DOCUMENTATION_AUTHOR_CONTRACT = (
    "after product-code review has reached a provisional pass",
    "stale, missing, contradictory, or invalid",
    "implementation, repository guidance, or verified user-facing behavior",
    "Do not create speculative guides, duplicate existing documentation",
    "Edit documentation files only",
    "Do not modify product code, configuration, tests",
    "Validate links, commands, paths, examples",
    "self-review the complete documentation diff",
    "focused conventional commit boundary",
    "Do not create or switch branches, commit, push, open a pull request",
)

ORCHESTRATOR_CONTRACT = (
    "Establish the baseline before delegation",
    "If the root `AGENTS.md` is missing",
    "Run authors sequentially",
    "wait for it to merge",
    "exact recorded guidance baseline",
    "Exclude sibling components, future task or feature context",
    "Stage only the approved `AGENTS.md` paths",
    "never publish an unapproved SHA",
    "normal non-force push",
    "approved `AGENTS.md` paths and blob contents exactly match",
    "Do not continue until the user confirms the scope",
    ".codex/start-task/<YYYY-MM-DD>_<task-slug>_PLAN.md",
    "never commit that control file",
    "Give the researcher only the unresolved repository facts",
    "Process only independently reviewable and shippable parts",
    "Process parts sequentially",
    "Never branch the next part from the previous part branch",
    "Before planning every part, establish a fresh part baseline in this order",
    "return to the recorded default branch",
    "Require a clean worktree except for the recorded untracked workflow control file",
    "Safely fetch the default branch's configured upstream",
    "fast-forward only",
    "verify from the refreshed default-branch history",
    "Record and confirm the refreshed default-branch tip",
    "After the reviewed plan receives explicit user approval",
    "Only from the reverified refreshed tip create and switch to `codex/<part-slug>`",
    "whenever `feature_implementer` reports either",
    "more than 500 non-generated changed lines",
    "material planning assumption is invalid",
    "Do not stage or commit the partial change",
    "complete workflow-owned partial uncommitted diff and affected-file list",
    "same `feature_planner` thread",
    "independently reviewable and shippable",
    "same `prompt_validator` thread",
    "obtain renewed user scope confirmation",
    "Do not switch branches while preserved partial work remains",
    "mandatory `plan_reviewer` correction loop until exact `PASS`",
    "obtain renewed explicit user approval before resuming implementation",
    "mandatory assignment-completion transaction",
    "byte-exact patches for all pre-existing user staged and unstaged changes",
    "Create exactly one nonempty conventional commit",
    "diff exactly equals the staged validated patch",
    "Verify no residual workflow-owned staged or unstaged change remains",
    "product_review_verdicts = 0",
    "Increment `product_review_verdicts` exactly once",
    "fifth product verdict",
    "Never reset, decrement, reuse, or transfer the product counter",
    "repair each finding independently in this order",
    "Require one focused repair plan",
    "Present the complete isolated repair plan to the user",
    "obtain explicit approval",
    "Only after approval, invoke `feature_implementer` once",
    "one separate conventional commit containing only that repair",
    "restart the full mandatory `plan_reviewer` correction loop",
    "repeat its separate user approval gate",
    "review the cumulative part again",
    "REPAIR_INTRODUCED",
    "PRE_EXISTING_MISSED",
    "exhaustive entire-part review",
    "require `plan_reviewer` to adversarially review and approve each resulting repair plan",
    "product-code review reaches a provisional `VERDICT: PASS`",
    "spawn `documentation_author`",
    "final_review_verdicts = 0",
    "final counter is a new budget",
    "final cumulative review across code, tests, configuration, and documentation",
    "exceeds 400 changed lines or exceeds 8 files",
    "partition the entire change into nonoverlapping cohesive sections",
    "`SECTION` mode for every recorded section",
    "`CROSS_INTERFACE` mode",
    "Do not create a global cumulative verdict until every recorded section",
    "same current HEAD",
    "No individual bounded reviewer may supply or imply the global verdict",
    "For every individual final-review finding",
    "Present the complete isolated repair plan to the user and obtain explicit approval",
    "invoke `feature_implementer` once",
    "invoke `documentation_author` once",
    "one separate conventional commit containing only that repair",
    "Before rerunning any final cumulative review after repairs",
    "changed product code, configuration, tests, generated user-facing behavior, or interface behavior",
    "spawn `documentation_author` in an audit-only invocation",
    "Explicitly prohibit edits in this audit invocation",
    "Process each necessary documentation finding independently",
    "documentation-only repairs",
    "For a mixed repair batch",
    "do not initialize, reset, increment, or otherwise alter `final_review_verdicts`",
    "Increment `final_review_verdicts` exactly once",
    "fifth final global verdict",
    "Never reset, decrement, reuse, transfer, or combine the final counter with the product counter",
    "never concurrently",
    "explicit approval",
)

ORCHESTRATOR_INITIAL_PLAN_GATE = (
    "Spawn `feature_planner` for the initial per-part plan",
    "Send the resulting complete plan to `plan_reviewer`",
    "return every finding to the same `feature_planner` thread",
    "Repeat planner correction and adversarial plan review",
    "returns exactly `PASS`",
    "present the complete reviewed plan to the user",
    "Wait for explicit user approval",
    "Only after that approval and the required baseline recheck",
    "directly from its confirmed refreshed default-branch tip",
    "invoke `feature_implementer`",
)

ORCHESTRATOR_GUIDANCE_LIFECYCLE = (
    "If files are approved, run this prerequisite lifecycle in order",
    "Ensure no write-capable agent is active",
    "return to the recorded default branch",
    "safely fetch its configured upstream",
    "update by fast-forward only",
    "record the refreshed default tip as the guidance baseline",
    "Inspect both local and remote `codex/add-agents-guidance` branch state",
    "Create it only when neither branch exists",
    "same workflow run created it from the exact recorded guidance baseline",
    "HEAD, parent, tree, index, worktree, and publication state match",
    "never delete, overwrite, force-update, or adopt an unrecorded local or remote branch",
    "Record the approved canonical `AGENTS.md` paths",
    "Run authors sequentially",
    "Give the root author only repository-wide structure, manifests, commands, and conventions",
    "Give each component author only its component files and commands plus applicable approved parent guidance",
    "Exclude sibling components, future task or feature context, unrelated commits and conversation",
    "verify every approved path exists as a nonempty regular `AGENTS.md`",
    "every changed path is an approved guidance file",
    "no other tracked or untracked path changed",
    "no changes are staged",
    "record each author's self-review and validation evidence",
    "Immediately before staging and committing",
    "repeat branch identity, exact guidance-baseline ancestry, clean index, approved-file-only diff",
    "Stage only the approved `AGENTS.md` paths",
    "one focused conventional documentation commit",
    "Record the guidance commit SHA, its exact parent, committed file list, complete committed diff, validation evidence, and branch identity",
    "Verify the committed files equal the approved paths",
    "Present the exact committed diff, SHA, parent, file list, and validation evidence",
    "obtain explicit approval for that exact commit before publication",
    "never publish an unapproved SHA",
    "Immediately before publication",
    "repeat preservation and identity gates",
    "Stop on drift or collision",
    "normal non-force push",
    "never force-push or silently replace an existing remote branch or pull request",
    "Record the pull request and wait for it to merge",
    "return to the default branch and safely refresh it by fast-forward only",
    "verify the refreshed default history contains the recorded guidance commit",
    "record evidence of an equivalent merged result",
    "approved `AGENTS.md` paths and blob contents exactly match the approved commit",
    "Stop if merge status or equivalence cannot be proven",
    "Only after that verification, rediscover every applicable root and component `AGENTS.md`",
)

ORCHESTRATOR_CORRECTED_PLAN_GATE = (
    "Use the same mandatory correction path when any other per-part plan needs a material correction",
    "stop implementation",
    "return the evidence and current plan to the same `feature_planner` thread",
    "run the complete corrected plan through `plan_reviewer` until exact `PASS`",
    "obtain renewed explicit user approval",
    "before implementation resumes",
)

ORCHESTRATOR_RESEARCH_BEFORE_CONFIRMATION = (
    "spawn `prompt_validator`",
    "If prompt validation signals material research",
    "spawn `task_researcher` with a bounded question before final scope confirmation",
    "return the cited findings to the same `prompt_validator` thread",
    "Relay the final proposed interpretation",
    "Do not continue until the user confirms the scope and the final proposed parts",
    "Persist the exact confirmed parts and workflow state",
)

ORCHESTRATOR_POST_CONFIRMATION_RESEARCH = (
    "If research occurs after scope confirmation",
    "classify its impact against scope, acceptance criteria, dependencies, feasibility, and risk",
    "If it changes any of them",
    "rerun `prompt_validator`",
    "obtain renewed user confirmation",
    "before planning or resuming planning",
    "Nonmaterial findings may proceed only after",
)

ORCHESTRATOR_PART_BASELINE_GATE = (
    "Before planning every part, establish a fresh part baseline in this order",
    "return to the recorded default branch",
    "confirm the current branch is exactly that default branch",
    "Recheck Git status, staged and unstaged diffs, and the untracked-file list",
    "Require a clean worktree except for the recorded untracked workflow control file",
    "preserve them and stop for user resolution",
    "never stash, reset, clean, overwrite, or otherwise discard them",
    "Safely fetch the default branch's configured upstream",
    "fast-forward only",
    "If the expected upstream is missing, fetch or authentication fails",
    "stop and report the exact refresh blocker",
    "verify from the refreshed default-branch history",
    "If any prerequisite is unmerged or unverifiable, stop before planning the part",
    "Record and confirm the refreshed default-branch tip",
    "give that exact commit to the planner and plan reviewer",
)

ORCHESTRATOR_PART_BRANCH_GATE = (
    "After the reviewed plan receives explicit user approval",
    "recheck that the worktree still satisfies the clean-state rule",
    "the current branch is still the recorded default branch",
    "its `HEAD` still equals the confirmed refreshed tip",
    "stop and repeat the safe baseline refresh",
    "Only from the reverified refreshed tip create and switch to `codex/<part-slug>`",
    "Refuse an existing branch name unless it is the recorded branch for the same part at the same baseline",
    "Never create a part branch from another part branch",
)

ORCHESTRATOR_IMPLEMENTER_REPLAN_GATE = (
    "whenever `feature_implementer` reports either",
    "exceeds a substantive threshold",
    "more than 500 non-generated changed lines",
    "more than 10 product files",
    "more than two independently testable architectural components",
    "material planning assumption is invalid",
    "Stop implementation immediately",
    "Do not stage or commit the partial change",
    "Capture the trigger and evidence",
    "every completed workflow commit",
    "the complete workflow-owned partial uncommitted diff and affected-file list",
    "substantive line and product-file counts",
    "separately reported generated files, lock files, and mechanical formatting",
    "all validation attempted with its results",
    "Record which files contain pre-existing user changes",
    "Record unrelated user changes by path and status only",
    "do not send their contents to the planner unless an overlapping edit makes that context necessary",
    "Preserve completed commits, partial work, and user work exactly as found",
    "Never discard, reset, clean, stash, overwrite, or silently commit partial work",
    "Update the control file to mark the part paused for replanning",
    "Return the evidence bundle, approved plan, and current part state to the same `feature_planner` thread",
    "corrected mid-level plan",
    "explicitly accounts for the preserved partial work",
    "classify every proposed subtask as inseparable from the current part or independently reviewable and shippable",
    "Keep inseparable subtasks in the current part and current branch",
    "Send every independently shippable proposed split back to the same `prompt_validator` thread",
    "Resolve any new research signal through the bounded researcher and validator loop",
    "obtain renewed user scope confirmation",
    "Each confirmed independent part must later use its own fresh-default baseline gate",
    "never implement it on the current part branch",
    "Do not switch branches while preserved partial work remains",
    "Queue confirmed independent parts for sequential processing only after the current part reaches a safe completed state",
    "Run the complete corrected current-part plan through the mandatory `plan_reviewer` correction loop until exact `PASS`",
    "obtain renewed explicit user approval before resuming implementation",
    "Update the control file with the approved plan and split dispositions",
    "Resume the same implementer thread when available with exactly one approved subtask",
)

PROMPT_VALIDATOR_CONTRACT = (
    "every distinct issue",
    "independently reviewable and shippable parts",
    "acceptance criteria",
    "dependencies",
    "missing or ambiguous requirements",
    "whether research is required",
    "clarification questions",
    "Do not edit files",
)

RESEARCHER_CONTRACT = (
    "bounded question",
    "Prefer repository evidence and primary sources",
    "verified findings",
    "source links as citations",
    "unresolved facts",
    "Do not edit files",
)

PLANNER_CONTRACT = (
    "mid-level plan",
    "affected subsystems and public or internal interfaces",
    "proportionate validation",
    "risks, edge cases",
    "Do not plan commits or commit messages",
    "Do not prescribe line-level edits, parameter-level changes",
    "each isolated finding",
    "invalid planning assumption",
    "Never edit files",
)

PLAN_REVIEWER_CONTRACT = (
    "adversarial plan reviewer",
    "completely solves the stated problem",
    "feasible in the current repository",
    "material risks, edge cases, compatibility concerns, and failure modes",
    "proportionate validation",
    "unnecessary changes, overengineering, or speculative abstractions",
    "one-line justification",
    "PASS",
    "ISSUES",
    "every issue found in one exhaustive pass",
    "until no issues remain",
    "Do not edit files",
)

IMPLEMENTER_CONTRACT = (
    "exactly one supplied, user-approved cohesive assignment",
    "create exactly one conventional commit when it succeeds",
    "assignment envelope containing `pre_HEAD`",
    "byte-exact pre-existing user staged and unstaged patches",
    "Do not create or edit documentation",
    "documentation agent",
    "unnecessary tests, CI changes, comments, or files",
    "Use repository-provided static tools first",
    "strict compiler, type-checker, and linter settings for touched code only",
    "more than 500 non-generated changed lines",
    "more than 10 product files",
    "more than two independently testable architectural components",
    "generated files, lock files, and mechanical formatting",
    "stop uncommitted and return the design to the planner",
    "material planning assumption is invalid",
    "Reassess every applicable risk",
    "Inspect the complete diff for unnecessary changes",
    "Re-run the relevant static tools and focused tests after the final edit",
    "one-line justification",
    "leave workflow work uncommitted",
    "Do not edit after this snapshot unless you rerun affected validation",
    "Stage only exact workflow-owned hunks inside the envelope",
    "isolated-index or equivalent exact-hunk procedure",
    "Create exactly one nonempty conventional commit whose sole parent is `pre_HEAD`",
    "Do not commit documentation, user work, mixed purposes, prior or future assignments",
    "After committing, stop editing and independently inspect the result",
    "absence of residual workflow-owned changes in every domain",
)

IMPLEMENTER_ASSIGNMENT_COMPLETION = (
    "Implement exactly one supplied, user-approved cohesive assignment",
    "Require an assignment envelope containing `pre_HEAD`",
    "exact approved plan slice",
    "applicable risks",
    "allowed behavior and file or hunk scope",
    "byte-exact pre-existing user staged and unstaged patches",
    "If any field is missing, stop before editing",
    "If ordinary implementation or validation fails, leave workflow work uncommitted",
    "never commit a failed or superseded snapshot",
    "perform a final self-review before staging",
    "Reassess every applicable risk",
    "Inspect the complete diff for unnecessary changes",
    "Re-run the relevant static tools and focused tests after the final edit",
    "Confirm the touched code follows repository style and conventions",
    "Confirm any workaround has a sufficient one-line justification",
    "Record the final validated workflow patch and fingerprint",
    "Do not edit after this snapshot unless you rerun affected validation and the complete self-review",
    "Stage only exact workflow-owned hunks inside the envelope",
    "preserve overlapping and nonoverlapping user staged and unstaged patches byte-for-byte",
    "Record staged paths, hunks, exact patch, and fingerprint",
    "Create exactly one nonempty conventional commit whose sole parent is `pre_HEAD`",
    "Do not commit documentation, user work, mixed purposes, prior or future assignments",
    "After committing, stop editing",
    "Verify the commit SHA and sole parent",
    "equality to the staged validated patch and approved assignment",
    "byte-identical user staged and unstaged patches",
    "absence of residual workflow-owned changes in every domain except the untracked workflow control file",
)

ORCHESTRATOR_ASSIGNMENT_COMPLETION = (
    "Apply this mandatory assignment-completion transaction to every normal or repair `feature_implementer` assignment",
    "Record an assignment envelope in the control file containing `pre_HEAD`",
    "exact approved plan slice",
    "applicable risks",
    "allowed behavior and file or hunk scope",
    "byte-exact patches for all pre-existing user staged and unstaged changes",
    "Require exactly one conventional commit for the approved cohesive assignment",
    "must not create documentation, empty commits, mixed-purpose commits, multiple commits",
    "commits containing prior assignments, future assignments, repairs, user work, or changes outside the envelope",
    "If a threshold is exceeded or a material planning assumption is invalid",
    "existing uncommitted replanning transition below",
    "For an ordinary implementation, validation, or self-review failure",
    "keep all workflow work uncommitted",
    "Never commit a failed or superseded snapshot",
    "Before staging, require successful final repository static checks and focused validation",
    "complete risk, scope, style, workaround, substantive and excluded counts, documentation queue, failure, and constraint self-review",
    "must not edit it",
    "Record the validated working patch and its fingerprint",
    "prohibit any edit unless the affected validation and complete self-review are rerun",
    "Stage only exact workflow-owned hunks within the assignment envelope",
    "Preserve overlapping and nonoverlapping user staged and unstaged patches byte-for-byte",
    "record staged paths, staged hunks, and the exact staged patch and fingerprint",
    "Create exactly one nonempty conventional commit, then stop editing",
    "report `pre_HEAD`, commit SHA and parent",
    "Independently verify that exactly one new commit exists",
    "its sole parent is `pre_HEAD`",
    "its diff exactly equals the staged validated patch and the approved assignment",
    "Recompute the user staged and unstaged patches and require byte identity with the envelope",
    "Verify no residual workflow-owned staged or unstaged change remains",
    "Permit only the untracked workflow control file and the byte-identical recorded user state",
    "do not start another assignment or review",
    "Record the verified SHA, parent, subject, committed files and diff fingerprint",
    "in the control file before continuing",
)

FEATURE_REVIEWER_CONTRACT = (
    "adversarial reviewer",
    "exactly one review mode: `FULL`, `SECTION`, or `CROSS_INTERFACE`",
    "Search exhaustively",
    "correctness, security, regression, compatibility, error-handling, plan-fulfillment, and required-validation defects",
    "Mode `FULL`",
    "complete `baseline..HEAD` diff",
    "whole-change `VERDICT: PASS` or `VERDICT: ISSUES`",
    "Mode `SECTION`",
    "declared bounded file list",
    "exact bounded diff for those files",
    "applicable approved-plan slice",
    "Return only `VERDICT: SECTION_PASS` or `VERDICT: SECTION_ISSUES`",
    "cannot claim global or whole-change approval",
    "Mode `CROSS_INTERFACE`",
    "identifiers and boundaries of every declared section",
    "declared interfaces and interactions between them",
    "Evaluate integration behavior only",
    "Return only `VERDICT: CROSS_INTERFACE_PASS` or `VERDICT: CROSS_INTERFACE_ISSUES`",
    "Pass timing and finding origins",
    "previous reviewed HEAD",
    "disposition of every supplied prior finding",
    "FEATURE_CHANGE",
    "REPAIR_INTRODUCED",
    "PRE_EXISTING_MISSED",
    "evidence from the tree at the previous reviewed HEAD",
    "exhaustive entire-part review",
    "MODE: INVALID",
    "VERDICT: PASS",
    "VERDICT: ISSUES",
    "severity",
    "file and line or symbol",
    "concrete evidence",
    "consequence",
    "required correction",
    "origin",
    "Do not edit files",
)

FEATURE_REVIEWER_FULL_MODE = (
    "Mode `FULL`",
    "recorded baseline commit",
    "complete approved plan",
    "complete `baseline..HEAD` diff",
    "Inspect the whole cumulative change",
    "only mode that may issue a whole-change `VERDICT: PASS` or `VERDICT: ISSUES`",
)

FEATURE_REVIEWER_SECTION_MODE = (
    "Mode `SECTION`",
    "section identifier",
    "declared bounded file list",
    "exact bounded diff for those files",
    "applicable approved-plan slice",
    "relevant supplied interfaces",
    "in-scope prior findings when applicable",
    "validation evidence",
    "Review only the declared section",
    "Do not require or inspect repository-wide diffs or unrelated files",
    "Return only `VERDICT: SECTION_PASS` or `VERDICT: SECTION_ISSUES`",
    "cannot claim global or whole-change approval",
)

FEATURE_REVIEWER_CROSS_INTERFACE_MODE = (
    "Mode `CROSS_INTERFACE`",
    "identifiers and boundaries of every declared section",
    "declared interfaces and interactions between them",
    "exact bounded interface diff and supplied interface context",
    "applicable integration requirements from the approved plan",
    "prior cross-interface findings when applicable",
    "validation evidence",
    "Evaluate integration behavior only",
    "Do not require or inspect repository-wide diffs",
    "Return only `VERDICT: CROSS_INTERFACE_PASS` or `VERDICT: CROSS_INTERFACE_ISSUES`",
    "cannot claim global or whole-change approval",
)

ORCHESTRATOR_SECTIONAL_REVIEW_GATE = (
    "If the substantive cumulative diff exceeds 400 changed lines or exceeds 8 files",
    "partition the entire change into nonoverlapping cohesive sections",
    "record every section identifier, bounded file list, diff boundary",
    "Spawn one independent `feature_reviewer` in `SECTION` mode for every recorded section",
    "Give each section reviewer only its recorded bounded inputs",
    "Spawn one separate `feature_reviewer` in `CROSS_INTERFACE` mode",
    "every section identifier and boundary",
    "exact bounded interface diff and context",
    "Do not create a global cumulative verdict until every recorded section",
    "same current HEAD",
    "missing, duplicate, stale-HEAD, wrong-mode, or input-error result blocks consolidation",
    "Emit global `VERDICT: PASS` only when every section returned `SECTION_PASS`",
    "cross-interface result is `CROSS_INTERFACE_PASS`",
    "otherwise emit global `VERDICT: ISSUES`",
    "No individual bounded reviewer may supply or imply the global verdict",
)

ORCHESTRATOR_PRODUCT_REPAIR_GATE = (
    "When product-code review reports issues",
    "repair each finding independently in this order",
    "Select exactly one finding",
    "Spawn `feature_planner` separately",
    "Require one focused repair plan",
    "If the missed-issue escalation already requires `plan_reviewer`",
    "run the focused repair plan through the required adversarial plan-review correction loop until exact `PASS`",
    "Present the complete isolated repair plan to the user",
    "obtain explicit approval",
    "Do not invoke a write-capable repair agent before that approval",
    "Only after approval, invoke `feature_implementer` once",
    "Require isolated validation, implementer self-review",
    "one separate conventional commit containing only that repair",
    "Record the finding disposition, approval, validation, and commit in the control file",
    "Do not combine findings in one plan, approval, writer invocation, validation boundary, or commit",
)

ORCHESTRATOR_MATERIAL_REPAIR_GATE = (
    "If a focused repair plan, a user-requested edit to it, or implementation evidence materially changes",
    "stop the isolated repair",
    "same original per-part `feature_planner` thread",
    "restart the full mandatory `plan_reviewer` correction loop until exact `PASS`",
    "present the complete corrected part plan",
    "obtain renewed explicit user approval",
    "regenerate or confirm the isolated repair plan",
    "repeat its separate user approval gate before invoking a writer",
)

ORCHESTRATOR_FINAL_REPAIR_GATE = (
    "For every individual final-review finding",
    "Select exactly one finding and classify its file domain",
    "Spawn `feature_planner` separately",
    "Require one focused repair plan",
    "If missed-issue escalation requires `plan_reviewer`",
    "run the focused plan through that adversarial correction loop until exact `PASS`",
    "Present the complete isolated repair plan to the user",
    "obtain explicit approval before invoking any writer",
    "Only after approval, invoke `feature_implementer` once",
    "invoke `documentation_author` once",
    "Require isolated validation, writer self-review",
    "one separate conventional commit containing only that repair",
    "Record the disposition, approval, validation, and commit in the control file",
    "If the repair becomes material",
    "repeat this finding's isolated approval gate",
)

ORCHESTRATOR_PRODUCT_REVIEW_BUDGET = (
    "initialize `product_review_verdicts = 0` in the control file immediately before the first product-code review",
    "do not initialize the final-review counter yet",
    "Increment `product_review_verdicts` exactly once only after a product `FULL` reviewer returns `VERDICT: PASS` or `VERDICT: ISSUES`",
    "repairs, planner results, and any other agent report do not count",
    "Record the reviewed HEAD and verdict with the counter value in the control file",
    "A product `VERDICT: PASS` freezes the product counter",
    "ends the product loop at provisional product pass",
    "If the fifth product verdict is `VERDICT: ISSUES`",
    "stop the part immediately without further repairs, documentation, final review, or publication",
    "Never reset, decrement, reuse, or transfer the product counter",
)

ORCHESTRATOR_FINAL_REVIEW_BUDGET = (
    "Only after the documentation stage completes",
    "initialize a distinct `final_review_verdicts = 0` in the control file",
    "Preserve the frozen `product_review_verdicts` value",
    "final counter is a new budget, not a reset, continuation, replacement, or reuse of the product counter",
    "Increment `final_review_verdicts` exactly once for either one final `FULL` verdict or one fully consolidated sectional-batch global verdict",
    "Individual `SECTION` and `CROSS_INTERFACE` reports, repairs, planner results, and writer reports do not count",
    "Record the reviewed HEAD, review form (`FULL` or `SECTIONAL_BATCH`), global verdict, and counter value in the control file",
    "A final global `VERDICT: PASS` freezes the final counter",
    "If the fifth final global verdict is `VERDICT: ISSUES`",
    "stop immediately without further repairs or publication",
    "Never reset, decrement, reuse, transfer, or combine the final counter with the product counter",
)

ORCHESTRATOR_POST_REPAIR_DOCUMENTATION_GATE = (
    "Before rerunning any final cumulative review after repairs",
    "classify the completed repair batch by changed behavior and file domain",
    "If at least one repair changed product code, configuration, tests, generated user-facing behavior, or interface behavior",
    "first finish every approved isolated product repair and commit",
    "Queue every new documentation impact or finding",
    "After those product repairs finish",
    "spawn `documentation_author` in an audit-only invocation",
    "Explicitly prohibit edits in this audit invocation",
    "focused report of every stale, missing, contradictory, or invalid document",
    "Process each necessary documentation finding independently through the final-review repair gate",
    "one focused planner-produced plan",
    "complete isolated-plan presentation",
    "explicit user approval",
    "one `documentation_author` repair invocation",
    "isolated documentation validation and self-review",
    "one documentation-only conventional commit",
    "Record the audit result and every documentation disposition, approval, validation, and commit in the control file",
    "Only after the documentation audit has no unresolved findings",
    "rerun final cumulative review at the new current HEAD",
    "If the completed batch contains documentation-only repairs",
    "proceed directly to cumulative re-review without a redundant documentation audit",
    "For a mixed repair batch",
    "complete all isolated product repairs first",
    "then the audit and all isolated documentation repairs",
    "Never run product and documentation writers concurrently",
    "do not initialize, reset, increment, or otherwise alter `final_review_verdicts`",
    "only the next qualifying cumulative global verdict consumes the existing final-review budget",
)


def require_ordered_markers(
    text: str, markers: tuple[str, ...], contract: str
) -> list[str]:
    errors: list[str] = []
    cursor = 0
    for marker in markers:
        position = text.find(marker, cursor)
        if position < 0:
            errors.append(f"{contract}: missing or out-of-order step {marker!r}")
            break
        cursor = position + len(marker)
    return errors


def text_between(text: str, start: str, end: str) -> str:
    start_position = text.find(start)
    if start_position < 0:
        return ""
    end_position = text.find(end, start_position + len(start))
    if end_position < 0:
        return ""
    return text[start_position:end_position]


def read_agent_instructions(filename: str) -> str:
    path = AGENTS_DIR / filename
    if not path.exists():
        return ""
    try:
        with path.open("rb") as stream:
            return tomllib.load(stream).get("developer_instructions", "")
    except (OSError, tomllib.TOMLDecodeError):
        return ""


def validate_cross_contract_audit() -> list[str]:
    errors: list[str] = []
    orchestrator = read_agent_instructions("task-orchestrator.toml")
    reviewer = read_agent_instructions("feature-reviewer.toml")
    implementer = read_agent_instructions("feature-implementer.toml")
    documentation_author = read_agent_instructions("documentation-author.toml")

    if not all((orchestrator, reviewer, implementer, documentation_author)):
        return errors

    ordered_gates = (
        ("guidance prerequisite", orchestrator, ORCHESTRATOR_GUIDANCE_LIFECYCLE),
        ("approval", orchestrator, ORCHESTRATOR_INITIAL_PLAN_GATE),
        ("branch freshness", orchestrator, ORCHESTRATOR_PART_BASELINE_GATE),
        ("threshold and invalid assumption", orchestrator, ORCHESTRATOR_IMPLEMENTER_REPLAN_GATE),
        ("assignment completion", orchestrator, ORCHESTRATOR_ASSIGNMENT_COMPLETION),
        ("product repair approval", orchestrator, ORCHESTRATOR_PRODUCT_REPAIR_GATE),
        ("final repair approval", orchestrator, ORCHESTRATOR_FINAL_REPAIR_GATE),
        ("review aggregation", orchestrator, ORCHESTRATOR_SECTIONAL_REVIEW_GATE),
        ("product budget", orchestrator, ORCHESTRATOR_PRODUCT_REVIEW_BUDGET),
        ("final budget", orchestrator, ORCHESTRATOR_FINAL_REVIEW_BUDGET),
        (
            "documentation rerun",
            orchestrator,
            ORCHESTRATOR_POST_REPAIR_DOCUMENTATION_GATE,
        ),
        ("reviewer full mode", reviewer, FEATURE_REVIEWER_FULL_MODE),
        ("reviewer section mode", reviewer, FEATURE_REVIEWER_SECTION_MODE),
        (
            "reviewer cross-interface mode",
            reviewer,
            FEATURE_REVIEWER_CROSS_INTERFACE_MODE,
        ),
        (
            "implementer assignment completion",
            implementer,
            IMPLEMENTER_ASSIGNMENT_COMPLETION,
        ),
    )
    for name, instructions, markers in ordered_gates:
        errors.extend(
            require_ordered_markers(
                instructions,
                markers,
                f"cross-contract audit {name}",
            )
        )

    role_markers = (
        (
            "minimal context",
            orchestrator,
            (
                "For every delegation, provide only the current role's necessary request",
                "Do not expose future-part context, unrelated commits, or unnecessary conversation history",
            ),
        ),
        (
            "implementer ownership",
            implementer,
            (
                "Do not create or edit documentation",
                "Never push or open a pull request",
            ),
        ),
        (
            "documentation ownership",
            documentation_author,
            (
                "Edit documentation files only",
                "Do not modify product code, configuration, tests",
            ),
        ),
    )
    for name, instructions, markers in role_markers:
        for marker in markers:
            if marker not in instructions:
                errors.append(
                    f"cross-contract audit {name}: missing contract text {marker!r}"
                )

    ownership_contradictions = (
        "`documentation_author` once for a code, test, or configuration finding",
        "`feature_implementer` once for a documentation finding",
    )
    for marker in ownership_contradictions:
        if marker in orchestrator:
            errors.append(
                f"cross-contract audit role ownership: contradictory assignment {marker!r}"
            )

    return errors


def main() -> int:
    errors: list[str] = []
    paths = sorted(AGENTS_DIR.glob("*.toml"))
    filenames = {path.name for path in paths}

    missing = set(EXPECTED) - filenames
    unexpected = filenames - set(EXPECTED)
    if missing:
        errors.append(f"missing agent configs: {', '.join(sorted(missing))}")
    if unexpected:
        errors.append(
            "agent configs missing validation expectations: "
            + ", ".join(sorted(unexpected))
        )

    for path in paths:
        try:
            with path.open("rb") as stream:
                config = tomllib.load(stream)
        except (OSError, tomllib.TOMLDecodeError) as error:
            errors.append(f"{path.relative_to(DISPLAY_ROOT)}: {error}")
            continue

        expected = EXPECTED.get(path.name)
        if expected is None:
            continue

        for field, value in expected.items():
            if config.get(field) != value:
                errors.append(
                    f"{path.relative_to(DISPLAY_ROOT)}: {field} must be {value!r}, "
                    f"got {config.get(field)!r}"
                )

        for field in ("description", "developer_instructions"):
            if not isinstance(config.get(field), str) or not config[field].strip():
                errors.append(
                    f"{path.relative_to(DISPLAY_ROOT)}: {field} must be a non-empty string"
                )

    author_path = AGENTS_DIR / "agents-md-author.toml"
    if author_path.exists():
        with author_path.open("rb") as stream:
            instructions = tomllib.load(stream).get("developer_instructions", "")
        for marker in AUTHOR_CONTRACT:
            if marker not in instructions:
                errors.append(
                    f"agents/agents-md-author.toml: missing contract text {marker!r}"
                )

    contract_markers = {
        "documentation-author.toml": DOCUMENTATION_AUTHOR_CONTRACT,
        "task-orchestrator.toml": ORCHESTRATOR_CONTRACT,
        "prompt-validator.toml": PROMPT_VALIDATOR_CONTRACT,
        "task-researcher.toml": RESEARCHER_CONTRACT,
        "feature-planner.toml": PLANNER_CONTRACT,
        "plan-reviewer.toml": PLAN_REVIEWER_CONTRACT,
        "feature-implementer.toml": IMPLEMENTER_CONTRACT,
        "feature-reviewer.toml": FEATURE_REVIEWER_CONTRACT,
    }
    for filename, markers in contract_markers.items():
        path = AGENTS_DIR / filename
        if not path.exists():
            continue
        with path.open("rb") as stream:
            instructions = tomllib.load(stream).get("developer_instructions", "")
        for marker in markers:
            if marker not in instructions:
                errors.append(
                    f"agents/{filename}: missing contract text {marker!r}"
                )

    orchestrator_path = AGENTS_DIR / "task-orchestrator.toml"
    if orchestrator_path.exists():
        with orchestrator_path.open("rb") as stream:
            instructions = tomllib.load(stream).get("developer_instructions", "")
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_GUIDANCE_LIFECYCLE,
                "agents/task-orchestrator.toml guidance prerequisite lifecycle",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_INITIAL_PLAN_GATE,
                "agents/task-orchestrator.toml initial plan gate",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_CORRECTED_PLAN_GATE,
                "agents/task-orchestrator.toml corrected plan gate",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_RESEARCH_BEFORE_CONFIRMATION,
                "agents/task-orchestrator.toml pre-confirmation research gate",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_POST_CONFIRMATION_RESEARCH,
                "agents/task-orchestrator.toml post-confirmation research gate",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_PART_BASELINE_GATE,
                "agents/task-orchestrator.toml per-part baseline gate",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_PART_BRANCH_GATE,
                "agents/task-orchestrator.toml per-part branch gate",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_IMPLEMENTER_REPLAN_GATE,
                "agents/task-orchestrator.toml implementer replan gate",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_ASSIGNMENT_COMPLETION,
                "agents/task-orchestrator.toml assignment completion transaction",
            )
        )
        errors.extend(
            require_ordered_markers(
                instructions,
                ORCHESTRATOR_SECTIONAL_REVIEW_GATE,
                "agents/task-orchestrator.toml sectional review gate",
            )
        )
        for markers, contract in (
            (ORCHESTRATOR_PRODUCT_REPAIR_GATE, "product repair gate"),
            (ORCHESTRATOR_MATERIAL_REPAIR_GATE, "material repair gate"),
            (ORCHESTRATOR_FINAL_REPAIR_GATE, "final repair gate"),
            (ORCHESTRATOR_PRODUCT_REVIEW_BUDGET, "product review budget"),
            (ORCHESTRATOR_FINAL_REVIEW_BUDGET, "final review budget"),
            (
                ORCHESTRATOR_POST_REPAIR_DOCUMENTATION_GATE,
                "post-repair documentation gate",
            ),
        ):
            errors.extend(
                require_ordered_markers(
                    instructions,
                    markers,
                    f"agents/task-orchestrator.toml {contract}",
                )
            )
        if "plan review when configured" in instructions:
            errors.append(
                "agents/task-orchestrator.toml: plan review must not be optional"
            )
        if "any required approval" in instructions:
            errors.append(
                "agents/task-orchestrator.toml: every isolated repair requires explicit user approval"
            )
        if "existing five-verdict policy" in instructions:
            errors.append(
                "agents/task-orchestrator.toml: product and final review budgets must not share a policy"
            )
        if instructions.find("product_review_verdicts = 0") > instructions.find(
            "final_review_verdicts = 0"
        ):
            errors.append(
                "agents/task-orchestrator.toml: product review counter must initialize before final review counter"
            )

    feature_reviewer_path = AGENTS_DIR / "feature-reviewer.toml"
    if feature_reviewer_path.exists():
        with feature_reviewer_path.open("rb") as stream:
            instructions = tomllib.load(stream).get("developer_instructions", "")
        for markers, contract in (
            (FEATURE_REVIEWER_FULL_MODE, "full mode"),
            (FEATURE_REVIEWER_SECTION_MODE, "section mode"),
            (FEATURE_REVIEWER_CROSS_INTERFACE_MODE, "cross-interface mode"),
        ):
            errors.extend(
                require_ordered_markers(
                    instructions,
                    markers,
                    f"agents/feature-reviewer.toml {contract}",
                )
            )

        section_instructions = text_between(
            instructions, "Mode `SECTION`:", "Mode `CROSS_INTERFACE`:"
        )
        cross_interface_instructions = text_between(
            instructions,
            "Mode `CROSS_INTERFACE`:",
            "Pass timing and finding origins:",
        )
        contradictory_bounded_requirements = (
            "require the complete `baseline..head` diff",
            "inspect the full baseline-to-current change",
            "review the complete change",
            "inspect every feature and repair commit",
        )
        for mode, bounded_instructions in (
            ("SECTION", section_instructions),
            ("CROSS_INTERFACE", cross_interface_instructions),
        ):
            if not bounded_instructions:
                errors.append(
                    f"agents/feature-reviewer.toml: could not isolate {mode} instructions"
                )
                continue
            for marker in contradictory_bounded_requirements:
                if marker in bounded_instructions.lower():
                    errors.append(
                        "agents/feature-reviewer.toml: "
                        f"{mode} must not contain whole-change requirement {marker!r}"
                    )

    implementer_path = AGENTS_DIR / "feature-implementer.toml"
    if implementer_path.exists():
        with implementer_path.open("rb") as stream:
            instructions = tomllib.load(stream).get("developer_instructions", "")
        errors.extend(
            require_ordered_markers(
                instructions,
                IMPLEMENTER_ASSIGNMENT_COMPLETION,
                "agents/feature-implementer.toml assignment completion transaction",
            )
        )

    errors.extend(validate_cross_contract_audit())

    if errors:
        print("Agent configuration validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(paths)} agent configurations.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
