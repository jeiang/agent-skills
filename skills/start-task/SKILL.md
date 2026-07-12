---
name: start-task
description: Implement or modify a code feature through a model-pinned planner, implementer, and reviewer workflow with an automatic review-and-repair loop. Use when the user explicitly invokes $start-task or asks to run the structured feature workflow. Stop after reviewer approval or five completed review cycles.
---

# Start Task

Treat the user's request following the skill invocation as the feature request.

## Establish the baseline

1. Confirm that the working directory is a Git repository.
2. Record the initial Git status and diff so pre-existing user changes remain distinguishable.
3. Identify applicable `AGENTS.md` files and repository validation commands.
4. Do not commit, push, or open a pull request unless the user explicitly requests it.

## Plan and implement

1. Spawn the `feature_planner` custom agent with the feature request, repository context, applicable instructions, and baseline state.
2. Wait for the complete implementation plan.
3. Spawn the `feature_implementer` custom agent with the feature request and approved plan.
4. Wait for implementation and validation to finish.
5. Set the completed review-cycle count to zero.

## Review and repair

Repeat these steps sequentially:

1. Spawn `feature_reviewer` to review the entire accumulated feature diff, relevant surrounding code, and validation evidence.
2. Increment the completed review-cycle count.
3. If the reviewer returns `VERDICT: PASS`, stop successfully.
4. If five review cycles have completed, stop without further edits and report every remaining finding.
5. Send the complete reviewer findings to `feature_planner` and request a repair plan covering every finding. Reuse the existing planner thread when available; otherwise spawn another `feature_planner`.
6. Send the repair plan and original findings to `feature_implementer`. Reuse the existing implementer thread when available; otherwise spawn another `feature_implementer`.
7. Wait for the repair and validation to finish, then start the next review cycle.

## Coordination rules

- Run planner, implementer, and reviewer work sequentially.
- Never run multiple write-capable agents concurrently.
- Let only `feature_implementer` modify repository files.
- Re-review the entire accumulated feature diff after every repair.
- Count only completed reviewer passes toward the five-cycle limit.
- Preserve pre-existing user changes and avoid unrelated edits.
- Do not silently discard, downgrade, or summarize away reviewer findings when handing them to the planner.
- If an agent cannot run, report the exact blocker instead of silently substituting the parent model.

## Final report

Report the final verdict, completed review-cycle count, implemented changes, validation results, and any remaining findings or constraints.
