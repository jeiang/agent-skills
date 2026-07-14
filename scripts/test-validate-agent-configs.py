#!/usr/bin/env python3
from dataclasses import dataclass
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from typing import Callable


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_AGENTS = REPO_ROOT / "agents"
VALIDATOR = REPO_ROOT / "scripts/validate-agent-configs.py"


@dataclass(frozen=True)
class Fixture:
    name: str
    filename: str
    mutate: Callable[[str], str]
    expected_error: str


def replace_once(old: str, new: str) -> Callable[[str], str]:
    def mutate(text: str) -> str:
        if text.count(old) != 1:
            raise AssertionError(
                f"mutation source must occur once, found {text.count(old)}: {old!r}"
            )
        return text.replace(old, new, 1)

    return mutate


def swap_once(first: str, second: str) -> Callable[[str], str]:
    def mutate(text: str) -> str:
        if text.count(first) != 1 or text.count(second) != 1:
            raise AssertionError("ordered mutation sources must each occur once")
        sentinel = "__START_TASK_MUTATION_SENTINEL__"
        return text.replace(first, sentinel, 1).replace(second, first, 1).replace(
            sentinel, second, 1
        )

    return mutate


FIXTURES = (
    Fixture(
        "omitted-plan-approval",
        "task-orchestrator.toml",
        replace_once(
            "6. Wait for explicit user approval of that complete plan.",
            "6. Record the complete plan without requesting approval.",
        ),
        "initial plan gate",
    ),
    Fixture(
        "reordered-branch-refresh",
        "task-orchestrator.toml",
        swap_once(
            "Recheck Git status, staged and unstaged diffs, and the untracked-file list",
            "Safely fetch the default branch's configured upstream",
        ),
        "per-part baseline gate",
    ),
    Fixture(
        "unsafe-guidance-branch-reuse",
        "task-orchestrator.toml",
        replace_once(
            "Create it only when neither branch exists.",
            "Reuse any existing local or remote branch.",
        ),
        "guidance prerequisite lifecycle",
    ),
    Fixture(
        "broad-guidance-staging",
        "task-orchestrator.toml",
        replace_once(
            "Stage only the approved `AGENTS.md` paths",
            "Stage the working tree",
        ),
        "guidance prerequisite lifecycle",
    ),
    Fixture(
        "unbounded-component-author-context",
        "task-orchestrator.toml",
        replace_once(
            "Exclude sibling components, future task or feature context, unrelated commits and conversation",
            "Include sibling components and future task context",
        ),
        "guidance prerequisite lifecycle",
    ),
    Fixture(
        "unverified-guidance-merge",
        "task-orchestrator.toml",
        replace_once(
            "Stop if merge status or equivalence cannot be proven.",
            "Continue when merge status cannot be proven.",
        ),
        "guidance prerequisite lifecycle",
    ),
    Fixture(
        "optional-plan-review",
        "task-orchestrator.toml",
        replace_once(
            "Send the resulting complete plan to `plan_reviewer` for adversarial review.",
            "Perform plan review when configured.",
        ),
        "plan review must not be optional",
    ),
    Fixture(
        "wrong-documentation-writer",
        "task-orchestrator.toml",
        replace_once(
            "or invoke `documentation_author` once for a documentation finding",
            "or invoke `feature_implementer` once for a documentation finding",
        ),
        "role ownership",
    ),
    Fixture(
        "omitted-minimal-context",
        "task-orchestrator.toml",
        replace_once(
            "Give the researcher only the unresolved repository facts",
            "Give the researcher the conversation and repository",
        ),
        "Give the researcher only the unresolved repository facts",
    ),
    Fixture(
        "omitted-threshold-stop",
        "task-orchestrator.toml",
        replace_once(
            "Do not stage or commit the partial change",
            "Continue with the partial change",
        ),
        "implementer replan gate",
    ),
    Fixture(
        "omitted-assignment-baseline",
        "task-orchestrator.toml",
        replace_once(
            "Record an assignment envelope in the control file containing `pre_HEAD`",
            "Record an assignment envelope in the control file",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "multiple-assignment-commits",
        "task-orchestrator.toml",
        replace_once(
            "Require exactly one conventional commit for the approved cohesive assignment.",
            "Allow one or more commits for the approved cohesive assignment.",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "committed-failed-assignment",
        "task-orchestrator.toml",
        replace_once(
            "For an ordinary implementation, validation, or self-review failure, keep all workflow work uncommitted.",
            "For an ordinary implementation, validation, or self-review failure, commit the partial workflow work.",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "edited-validated-snapshot",
        "task-orchestrator.toml",
        replace_once(
            "prohibit any edit unless the affected validation and complete self-review are rerun",
            "allow edits without rerunning validation or self-review",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "broad-assignment-staging",
        "task-orchestrator.toml",
        replace_once(
            "Stage only exact workflow-owned hunks within the assignment envelope",
            "Stage every changed file in the workspace",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "implementer-documentation-edit",
        "feature-implementer.toml",
        replace_once(
            "Do not create or edit documentation.",
            "Create or edit documentation when useful.",
        ),
        "Do not create or edit documentation",
    ),
    Fixture(
        "omitted-commit-parent-proof",
        "task-orchestrator.toml",
        replace_once(
            "its sole parent is `pre_HEAD`",
            "its parent is not checked",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "committed-diff-mismatch",
        "task-orchestrator.toml",
        replace_once(
            "its diff exactly equals the staged validated patch and the approved assignment",
            "its diff may differ from the staged validated patch and approved assignment",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "assignment-content-leakage",
        "task-orchestrator.toml",
        replace_once(
            "commits containing prior assignments, future assignments, repairs, user work, or changes outside the envelope",
            "commits may contain prior assignments, future assignments, repairs, user work, or changes outside the envelope",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "omitted-user-patch-proof",
        "task-orchestrator.toml",
        replace_once(
            "Recompute the user staged and unstaged patches and require byte identity with the envelope.",
            "Assume the user staged and unstaged patches were preserved.",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "residual-workflow-changes",
        "task-orchestrator.toml",
        replace_once(
            "Verify no residual workflow-owned staged or unstaged change remains",
            "Allow residual workflow-owned staged or unstaged changes",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "continuation-before-evidence",
        "task-orchestrator.toml",
        replace_once(
            "in the control file before continuing.",
            "in the control file after continuing.",
        ),
        "assignment completion transaction",
    ),
    Fixture(
        "contradictory-section-diff",
        "feature-reviewer.toml",
        replace_once(
            "Review only the declared section.",
            "Require the complete `baseline..HEAD` diff. Review only the declared section.",
        ),
        "SECTION must not contain whole-change requirement",
    ),
    Fixture(
        "omitted-aggregation-head",
        "task-orchestrator.toml",
        replace_once(
            "for the same current HEAD",
            "without confirming a common reviewed commit",
        ),
        "same current HEAD",
    ),
    Fixture(
        "shared-review-budget",
        "task-orchestrator.toml",
        replace_once(
            "the final counter is a new budget",
            "the counters use the existing five-verdict policy",
        ),
        "must not share a policy",
    ),
    Fixture(
        "omitted-documentation-audit-safety",
        "task-orchestrator.toml",
        replace_once(
            "Explicitly prohibit edits in this audit invocation.",
            "Allow edits during this audit invocation.",
        ),
        "post-repair documentation gate",
    ),
)


def run_validator(agents_dir: Path) -> subprocess.CompletedProcess[str]:
    environment = os.environ.copy()
    environment["START_TASK_AGENT_CONFIG_DIR"] = str(agents_dir)
    return subprocess.run(
        [sys.executable, str(VALIDATOR)],
        cwd=REPO_ROOT,
        env=environment,
        text=True,
        capture_output=True,
        check=False,
    )


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="start-task-agent-contracts-") as root:
        root_path = Path(root)
        baseline_agents = root_path / "baseline" / "agents"
        shutil.copytree(SOURCE_AGENTS, baseline_agents)
        baseline = run_validator(baseline_agents)
        if baseline.returncode != 0:
            sys.stderr.write("Unmodified disposable agent contracts failed validation.\n")
            sys.stderr.write(baseline.stdout + baseline.stderr)
            return 1

        for fixture in FIXTURES:
            agents_dir = root_path / fixture.name / "agents"
            shutil.copytree(SOURCE_AGENTS, agents_dir)
            path = agents_dir / fixture.filename
            path.write_text(
                fixture.mutate(path.read_text(encoding="utf-8")), encoding="utf-8"
            )
            result = run_validator(agents_dir)
            output = result.stdout + result.stderr
            if result.returncode == 0:
                print(f"Mutation fixture unexpectedly passed: {fixture.name}", file=sys.stderr)
                return 1
            if fixture.expected_error not in output:
                print(
                    f"Mutation fixture {fixture.name} did not report "
                    f"{fixture.expected_error!r}:\n{output}",
                    file=sys.stderr,
                )
                return 1

    print(f"Validated {len(FIXTURES)} agent contract mutation fixtures.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
