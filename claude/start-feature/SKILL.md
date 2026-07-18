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
2. Run a `/grilling` interview using the `/domain-modeling` skill: walk the
   decision tree one question at a time, provide a recommended answer for
   each question, and record resolved domain vocabulary and significant
   architectural decisions lazily in the target repository. Create no
   artifact when there is nothing to record.
3. Confirm a concise scope interpretation and observable acceptance criteria.
   Do not start planning until the user confirms a shared understanding.
4. Write an implementation plan and present it for approval. Do not implement
   before the user approves the plan. Return to step 2 when an answer
   materially changes scope, architecture, or acceptance criteria.
5. Spawn the `feature-implementer` agent with the approved plan, the
   acceptance criteria, and the repository facts it needs. All implementation
   happens in that subagent; do not edit files from this context.
6. Verify the reported result against the acceptance criteria and relay the
   outcome, including any deviations or blockers, without changing their
   meaning.

For a small unambiguous feature the interview may be short, but scope
confirmation and plan approval are never skipped.
