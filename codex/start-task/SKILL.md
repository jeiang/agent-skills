---
name: start-task
description: Coordinate a repository change through repository-grounded clarification, user-approved planning, focused implementation, one bounded review and repair pass, and optional publication. Use when the user invokes $start-task or asks for the structured repository-change launcher.
---

# Start Task

Treat the request following the skill invocation as the task request.

1. Confirm the working directory is a Git repository. Record the task request, branch, HEAD, concise status, and applicable top-level instructions.
2. Spawn the `task_orchestrator` custom agent with that invocation baseline. The coordinator owns repository inspection, clarification, task sizing, planning, implementation, changelog maintenance, bounded review, Git state, and publication approval.
3. Relay the coordinator's questions, scope confirmation, plan approval, material replan, dirty-worktree commit approval, publication approval, progress, blockers, and final result without changing their meaning.
4. Return each user answer to the same coordinator thread. Do not perform specialist work in the launcher or start another review or repair path.
5. Stop when the coordinator reports completion, unresolved review defects, or a terminal blocker.

The coordinator must inspect before asking questions, split oversized requests into user-approved independently shippable subtasks, and process each subtask on its own branch and pull request. Every completed subtask must add or update the repository-root `CHANGELOG.md` with a concise entry under its existing unreleased section, preserving the repository's established changelog format. Create `CHANGELOG.md` with an `Unreleased` section when none exists. Review is limited to one initial pass, one cohesive repair pass when needed, and targeted verification of those repairs.
