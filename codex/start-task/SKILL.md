---
name: start-task
description: Run a repository-aware implementation workflow with AGENTS.md guidance, prompt validation and research, user-approved planning, focused implementation, adversarial review, documentation maintenance, and one pull request per independently shippable part. Use when the user invokes $start-task or asks for the structured multi-agent feature or issue workflow.
---

# Start Task

Treat the user's request following the skill invocation as the task request.

## Launch the workflow

1. Confirm that the working directory exists and is a Git repository. If either check fails, stop and report the exact blocker.
2. Record only the invocation baseline needed to identify the task: working directory, task request, current branch, `HEAD`, concise Git status, and applicable top-level instructions. Do not inspect or plan the implementation in the launcher.
3. Spawn the `task_orchestrator` custom agent with that invocation baseline. The orchestrator owns repository-guidance discovery, prompt validation, research, planning and plan review, implementation and adversarial review, documentation maintenance, workflow state, branches, commits, and per-part publication.

## Relay and stop

- Relay the orchestrator's questions, scope confirmations, plan approvals, publication approvals, progress, blockers, and final results without changing their meaning.
- Return each user answer to the same orchestrator thread and wait for its next result.
- Do not spawn or instruct specialist agents directly. Do not perform specialist work in the parent model or substitute another agent when a required custom agent cannot run.
- Do not add workflow rules, implementation context, or repository context that the orchestrator did not request.
- If the orchestrator or a required specialist cannot run, stop and report the exact blocker.
- Finish only when the orchestrator reports completion or a terminal blocker.
