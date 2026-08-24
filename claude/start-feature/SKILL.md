---
name: start-feature
description: >
  Establish complete context for a new feature through a structured interview
  before any plan is written, then delegate implementation to the
  feature-implementer subagent. Use when the user asks to implement, add,
  build, or create a new feature, capability, or behavior in a repository.
  Do NOT use for bug fixes, questions, reviews, or trivial edits the user
  fully specified.
---

# Start Feature

Treat the request as a feature request for the current repository.

1. Inspect the repository first. Resolve every discoverable fact — structure,
   existing patterns, related code, validation commands — before asking
   anything. Never ask the user for a fact the environment can answer.
2. Ask the user, as the first interview question, whether to create docs
   (ADRs, glossary) during the interview — recommend yes when the repository
   already keeps ADRs, default no. Then run the `grill-with-docs` skill (yes)
   or the `grilling` skill (no) to interview the user: walk the decision tree
   one question at a time and provide a recommended answer for each question.
3. Confirm a concise scope interpretation and observable acceptance criteria.
   If the request contains multiple independently shippable outcomes, say so
   and propose narrowing to one; the rest become follow-ups. Do not start
   planning until the user confirms a shared understanding.
4. Write an implementation plan and present it for approval. Do not implement
   before the user approves the plan. Return to step 2 when an answer
   materially changes scope, architecture, or acceptance criteria.
5. Prepare git state. If the worktree has staged, unstaged, or untracked
   changes, show the exact state and ask the user how to proceed; never
   stash, reset, or discard user work. Stay on the current branch when it is
   not the default branch; otherwise create `claude/<feature-slug>` from the
   default branch.
6. Split the approved plan into implementation parts before spawning
   anything. A small changeset (roughly one coherent change a reviewer can
   hold in their head) is a single part containing the whole plan; a larger
   one becomes an ordered list of parts, each a coherent, independently
   verifiable unit that leaves validation passing. State the split to the
   user before dispatching.
7. For each part in order, spawn a `feature-implementer` agent with only
   that part, the acceptance criteria it covers, and the repository facts it
   needs. Never hand the implementer more than one part at a time. After
   each part returns, review its diff against the plan and confirm it is
   correct before dispatching the next part. All implementation happens in
   the subagents; do not edit files from this context. Never instruct an
   implementer to skip, defer, or batch commits. Implementer commits are
   final history: do not commit, amend, squash, rebase, or reset them.
   Repairs go back to an implementer, which commits them under its own
   rules.
8. Spawn a `change-reviewer` agent in INITIAL mode with the baseline, the
   approved plan, the acceptance criteria, the cumulative diff, and the
   validation evidence. Do not review the diff yourself; you wrote the plan
   and approved each part, so you are the wrong context to judge the result.
   Accept only `PASS`, `CHANGES_REQUIRED`, or `BLOCKED`. Resolve a `BLOCKED`
   verdict by supplying the missing input, not by treating it as a finding.
   For `CHANGES_REQUIRED`, send all confirmed findings to an implementer as
   one cohesive repair assignment, then spawn `change-reviewer` in VERIFY
   mode with only those findings, the repair diff, and the relevant
   validation. Accept only `FIXES_VERIFIED` or `FIXES_NOT_VERIFIED`. Never
   start a second general review or another repair cycle; report unresolved
   findings to the user.
9. Verify the reported result against the acceptance criteria and relay the
   outcome, including any deviations or blockers, without changing their
   meaning.

For a small unambiguous feature the interview may be short, but scope
confirmation and plan approval are never skipped.
