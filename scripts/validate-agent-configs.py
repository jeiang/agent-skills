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
    "only when unresolved repository facts",
    "Process only independently reviewable and shippable parts",
    "Process parts sequentially",
    "Count a completed review cycle only when a reviewer returns a verdict",
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
    "partition it by cohesive subsystem or concern",
    "independent `feature_reviewer` for each subsection",
    "cross-section interfaces and interactions",
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
    "Only after that approval, create and switch to",
    "invoke `feature_implementer`",
)

ORCHESTRATOR_CORRECTED_PLAN_GATE = (
    "When a per-part plan needs a material correction",
    "return the evidence and current plan to the same `feature_planner` thread",
    "run the complete corrected plan through the same mandatory `plan_reviewer` loop",
    "obtain explicit user approval again",
    "before implementation resumes",
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
    "Search exhaustively",
    "correctness, security, regression, compatibility, error-handling, plan-fulfillment, and required-validation defects",
    "complete `baseline..HEAD` diff",
    "previous reviewed HEAD",
    "disposition of every prior finding",
    "cumulative result",
    "REPAIR_INTRODUCED",
    "PRE_EXISTING_MISSED",
    "evidence from the tree at the previous reviewed HEAD",
    "exhaustive entire-part review",
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
        if "plan review when configured" in instructions:
            errors.append(
                "agents/task-orchestrator.toml: plan review must not be optional"
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
