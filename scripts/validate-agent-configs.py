#!/usr/bin/env python3
from pathlib import Path
import sys
import tomllib


ROOT = Path(__file__).resolve().parents[1]
AGENTS = ROOT / "agents"

EXPECTED = {
    "task-orchestrator.toml": ("task_orchestrator", "gpt-5.6-luna", "medium", "workspace-write"),
    "feature-planner.toml": ("feature_planner", "gpt-5.6-sol", "medium", "read-only"),
    "feature-implementer.toml": ("feature_implementer", "gpt-5.6-terra", "medium", "workspace-write"),
    "feature-reviewer.toml": ("feature_reviewer", "gpt-5.6-sol", "medium", "read-only"),
    "plan-reviewer.toml": ("plan_reviewer", "gpt-5.6-sol", "high", "read-only"),
    "task-researcher.toml": ("task_researcher", "gpt-5.6-luna", "high", "read-only"),
    "documentation-author.toml": ("documentation_author", "gpt-5.6-luna", "medium", "workspace-write"),
}

REQUIRED_BEHAVIOR = {
    "task-orchestrator.toml": (
        "Resolve discoverable facts before asking questions",
        "load and follow the grill-with-docs skill to validate the task request",
        "Do not start planning until the user confirms a shared understanding",
        "Present a concise scope interpretation and obtain confirmation",
        "multiple independently shippable outcomes",
        "If the worktree has staged, unstaged, or untracked changes",
        "material change to scope, architecture, interfaces, acceptance criteria, or required validation",
        "one conventional commit",
        "CHANGELOG.md",
        "invoke feature_reviewer once",
        "one repair pass",
        "FIXES_NOT_VERIFIED",
        "Never start another general review",
        "Ask before pushing",
    ),
    "feature-implementer.toml": (
        "load and follow the ponytail skill in full mode",
        "The approved requirements, acceptance criteria, and these developer instructions take precedence over Ponytail",
        "This plan gate takes precedence over Ponytail's runnable-check rule",
        "Do not add or modify tests unless",
        "Avoid excessive comments",
        "possible future value",
        "one conventional commit",
        "CHANGELOG.md",
    ),
    "feature-reviewer.toml": (
        "PASS, CHANGES_REQUIRED, or BLOCKED",
        "demonstrable merge-blocking defects",
        "FIXES_VERIFIED or FIXES_NOT_VERIFIED",
        "Do not reopen the general review",
    ),
}


def main() -> int:
    errors: list[str] = []
    present = {path.name for path in AGENTS.glob("*.toml")}
    expected = set(EXPECTED)
    for name in sorted(expected - present):
        errors.append(f"missing agent config: {name}")
    for name in sorted(present - expected):
        errors.append(f"unexpected agent config: {name}")

    for filename, expected_values in EXPECTED.items():
        path = AGENTS / filename
        if not path.exists():
            continue
        try:
            data = tomllib.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, tomllib.TOMLDecodeError) as error:
            errors.append(f"{filename}: {error}")
            continue

        values = (
            data.get("name"),
            data.get("model"),
            data.get("model_reasoning_effort"),
            data.get("sandbox_mode"),
        )
        if values != expected_values:
            errors.append(f"{filename}: expected {expected_values}, found {values}")
        instructions = data.get("developer_instructions")
        if not isinstance(instructions, str) or not instructions.strip():
            errors.append(f"{filename}: developer_instructions must be nonempty")
            continue
        for marker in REQUIRED_BEHAVIOR.get(filename, ()):
            if marker not in instructions:
                errors.append(f"{filename}: missing required behavior {marker!r}")

    if errors:
        print("Agent validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(EXPECTED)} agent configurations.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
