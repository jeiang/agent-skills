---
name: start-task
description: Implement or modify a code feature through a model-pinned, user-approved planner, implementer, and reviewer workflow with per-step commits and an automatic review-and-repair loop. Use when the user explicitly invokes $start-task or asks to run the structured feature workflow. Stop after reviewer approval or five completed review cycles.
---

# Start Task

Treat the user's request following the skill invocation as the feature request.

## Establish the baseline

1. Confirm that the working directory is a Git repository.
2. Record the baseline commit, current branch, initial Git status, and working-tree and staged diffs. Keep pre-existing user changes distinguishable throughout the workflow.
3. Identify the repository's default branch without changing branches, applicable `AGENTS.md` files, and validation commands.
4. If currently on the default branch, plan to create and switch to `codex/<task-slug>` only after the initial plan is approved and before implementation starts. If already on another branch, remain on it.

## Plan and obtain approval

1. Spawn the `feature_planner` custom agent with the feature request, repository context, applicable instructions, and complete baseline state.
2. Require a complete plan with ordered, commit-sized steps, intended conventional commit messages, per-step and final validation, risks, and expected manual follow-up.
3. Present the complete plan to the user and pause. Do not create a branch, edit files, or start the implementer before the user explicitly approves it.
4. If the user requests changes, send the request and current plan back to the same planner thread when available. Present the complete revised plan and repeat the approval gate until the user explicitly approves it.
5. After approval, create and switch to the planned `codex/<task-slug>` branch when the recorded branch was the default branch. Confirm the baseline state is still distinguishable before implementation.

## Implement and commit

1. Spawn the `feature_implementer` custom agent with the feature request, approved plan, baseline commit and changes, current branch, and applicable instructions.
2. Require the implementer to execute one approved plan step at a time. After each changed step, it must run proportionate validation, stage only workflow-owned changes, create the specified conventional commit, and report the commit SHA. Do not create empty commits.
3. Preserve pre-existing user changes and never include them in workflow commits. Keep an ordered list of every workflow commit SHA and its validation result.
4. Wait for all approved implementation steps and validation to finish, then set the completed review-cycle count to zero.

### Handle invalid planning assumptions

If the implementer reports that a material planning assumption is invalid:

1. Stop implementation immediately. Do not commit the current step's partial work or continue to later steps.
2. Preserve completed commits and record the implementer's evidence, uncommitted diff or affected files, and validation state.
3. Send the invalid assumption, evidence, approved plan, completed commits, and partial-work state to the planner. Require a corrected, commit-sized plan that explicitly handles the partial work.
4. Present the complete corrected plan and material changes to the user. Do not resume until the user explicitly approves it; route requested edits back to the planner and repeat as needed.
5. Send the approved corrected plan and prior implementation state to the same implementer thread when available, then resume its per-step commit workflow.

## Review and repair

Repeat these steps sequentially:

1. For the first pass, spawn `feature_reviewer` with the approved plan, recorded baseline commit, current `HEAD`, all feature commits, the complete `baseline..HEAD` diff, relevant surrounding code, and validation evidence.
2. For every later pass, spawn a new reviewer with the original baseline and feature plan, previous reviewed `HEAD`, current `HEAD`, every earlier finding, approved repair plan, intervening commits and `previous_reviewed_HEAD..current_HEAD` diff, cumulative feature context, and validation evidence.
3. Require later reviewers to verify the disposition of every prior issue, inspect the repair commits for regressions or new issues, and assess the resulting implementation against the original approved plan.
4. Increment the completed review-cycle count only after a reviewer returns a verdict. Record the reviewed `HEAD`.
5. If the reviewer returns `VERDICT: PASS`, stop the review loop successfully.
6. If five review cycles have completed, stop without further edits and report every remaining finding.
7. Otherwise, send the complete reviewer findings and implementation context to the planner. Require a commit-sized repair plan that covers every finding.
8. Present the complete repair plan to the user and pause for explicit approval. Route requested edits back to the planner and repeat the approval gate.
9. Send the approved repair plan and original findings to the same implementer thread when available. Require the per-step validation and commit workflow, then start the next review cycle.
10. Apply the invalid-assumption procedure to repair implementation too.

## Coordination rules

- Run planner, implementer, and reviewer work sequentially.
- Never run multiple write-capable agents concurrently.
- Let only `feature_implementer` modify repository files.
- Require explicit user approval for every materially revised implementation, repair, or assumption-correction plan.
- Preserve completed commits, pre-existing user changes, and unrelated work.
- Do not silently discard, downgrade, or summarize away reviewer findings when handing them to the planner.
- If an agent cannot run, report the exact blocker instead of silently substituting the parent model.
- Do not push or open a pull request until the final confirmation step.

## Complete the task

Report:

- final verdict and completed review-cycle count
- implemented changes
- ordered workflow commit list
- validation performed and results
- remaining findings or constraints
- a concise **Manual follow-up** list; write `None` when no manual work remains

Then ask whether to push the current branch and open a ready-for-review pull request. Do neither without affirmative confirmation. If confirmed, push the branch and open a non-draft pull request, then report their results.
