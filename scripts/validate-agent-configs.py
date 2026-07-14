#!/usr/bin/env python3
from pathlib import Path
import sys
import tomllib


REPO_ROOT = Path(__file__).resolve().parents[1]
AGENTS_DIR = REPO_ROOT / "agents"

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
    "Count a completed review cycle only when a full reviewer returns its verdict",
    "five reviewer verdicts",
    "repair each finding independently",
    "invoke the planner separately",
    "invoke the implementer separately",
    "review the cumulative part again",
    "REPAIR_INTRODUCED",
    "PRE_EXISTING_MISSED",
    "exhaustive entire-part review",
    "require `plan_reviewer` to adversarially review and approve each resulting repair plan",
    "product-code review reaches a provisional `VERDICT: PASS`",
    "spawn `documentation_author`",
    "final cumulative review across code, tests, configuration, and documentation",
    "exceeds 400 changed lines or exceeds 8 files",
    "partition the entire change into nonoverlapping cohesive sections",
    "`SECTION` mode for every recorded section",
    "`CROSS_INTERFACE` mode",
    "Do not create a global cumulative verdict until every recorded section",
    "same current HEAD",
    "No individual bounded reviewer may supply or imply the global verdict",
    "Route each final-review finding independently",
    "five-verdict policy",
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
    "exactly one supplied, user-approved cohesive change",
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
    "sensible conventional commit boundaries",
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
            errors.append(f"{path.relative_to(REPO_ROOT)}: {error}")
            continue

        expected = EXPECTED.get(path.name)
        if expected is None:
            continue

        for field, value in expected.items():
            if config.get(field) != value:
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}: {field} must be {value!r}, "
                    f"got {config.get(field)!r}"
                )

        for field in ("description", "developer_instructions"):
            if not isinstance(config.get(field), str) or not config[field].strip():
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}: {field} must be a non-empty string"
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
                ORCHESTRATOR_SECTIONAL_REVIEW_GATE,
                "agents/task-orchestrator.toml sectional review gate",
            )
        )
        if "plan review when configured" in instructions:
            errors.append(
                "agents/task-orchestrator.toml: plan review must not be optional"
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

    if errors:
        print("Agent configuration validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(paths)} agent configurations.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
