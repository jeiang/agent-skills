---
name: research
description: "Primary-source research with cited findings. Invoke for bounded topic research, documentation, API facts, or delegated reading."
disable-model-invocation: true
---

Research directly for a small question. Use a background agent when the
question is independently bounded, delegation is available, and useful work
can continue alongside it. Start it with a fresh context window. Pass the
environment and tool restrictions; do not require a particular agent tool or
model.

The research task:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Return the findings in the requested form, citing each claim's source. For read-only or delegated research, return the findings to the caller without editing the repository unless the assignment explicitly requests saved notes.
3. Only when the requested deliverable includes persistent research notes, write a single Markdown file. Save it where the repo already keeps such notes; match the existing convention, and if there is none, put it somewhere sensible and say where.
