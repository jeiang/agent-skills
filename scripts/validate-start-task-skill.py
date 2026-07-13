#!/usr/bin/env python3
from pathlib import Path
import sys

import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILL_PATH = REPO_ROOT / "codex/start-task/SKILL.md"
UI_PATH = REPO_ROOT / "codex/start-task/agents/openai.yaml"

SKILL_MARKERS = (
    "Treat the user's request following the skill invocation as the task request.",
    "working directory exists and is a Git repository",
    "working directory, task request, current branch, `HEAD`, concise Git status",
    "applicable top-level instructions",
    "Spawn the `task_orchestrator` custom agent",
    "Do not inspect or plan the implementation in the launcher.",
    "Relay the orchestrator's questions, scope confirmations, plan approvals, publication approvals",
    "Return each user answer to the same orchestrator thread",
    "Do not spawn or instruct specialist agents directly.",
    "Do not perform specialist work in the parent model",
    "stop and report the exact blocker",
)

DESCRIPTION_MARKERS = (
    "AGENTS.md guidance",
    "prompt validation and research",
    "user-approved planning",
    "focused implementation",
    "adversarial review",
    "documentation maintenance",
    "one pull request per independently shippable part",
    "$start-task",
)

UI_MARKERS = (
    "$start-task",
    "validate",
    "plan",
    "implement",
    "adversarially review",
    "document",
    "publish",
    "independently shippable parts",
)

FORBIDDEN_LAUNCHER_MARKERS = (
    "`feature_planner`",
    "`feature_implementer`",
    "`feature_reviewer`",
    "## Plan and obtain approval",
    "## Implement and commit",
    "## Review and repair",
)


def main() -> int:
    errors: list[str] = []
    skill = SKILL_PATH.read_text(encoding="utf-8")
    if not skill.startswith("---\n"):
        errors.append("SKILL.md must start with YAML frontmatter")
        frontmatter = {}
    else:
        _, raw_frontmatter, _ = skill.split("---", 2)
        frontmatter = yaml.safe_load(raw_frontmatter) or {}

    description = frontmatter.get("description", "")
    for marker in DESCRIPTION_MARKERS:
        if marker not in description:
            errors.append(f"SKILL.md description missing {marker!r}")
    for marker in SKILL_MARKERS:
        if marker not in skill:
            errors.append(f"SKILL.md launcher contract missing {marker!r}")
    for marker in FORBIDDEN_LAUNCHER_MARKERS:
        if marker in skill:
            errors.append(f"SKILL.md thin launcher must not contain {marker!r}")

    ui = yaml.safe_load(UI_PATH.read_text(encoding="utf-8")) or {}
    interface = ui.get("interface", {})
    if interface.get("display_name") != "Start Task":
        errors.append("openai.yaml display_name must be 'Start Task'")
    prompt = interface.get("default_prompt", "")
    for marker in UI_MARKERS:
        if marker not in prompt:
            errors.append(f"openai.yaml default_prompt missing {marker!r}")
    short_description = interface.get("short_description", "")
    if "multi-agent" not in short_description or "workflow" not in short_description:
        errors.append("openai.yaml short_description must describe a multi-agent workflow")

    if errors:
        print("Start-task skill validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Validated start-task launcher and UI contract.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
