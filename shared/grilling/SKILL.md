---
name: grilling
description: Resolve unclear intent or decisions that materially affect scope, design, compatibility, or risk through rounds of questions. Use when a goal is confused with a proposed method, consequential choices remain open, or the user asks to grill or stress-test an idea. Do not interview clear, reversible tasks or reopen settled decisions.
---

Interview the user until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it. Match the interview depth to uncertainty and consequences; do not invent decisions to extend it.

Separate the desired outcome from a proposed tool or method. If the user says "I want X using Y" and the intent is unclear, establish what success means and whether Y is required. Challenge Y when it does not serve X, while preserving an explicitly required method.

## Rounds

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round, giving your recommended answer and the material trade-off for each question. Then wait for the user's answers before the next round.

A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one. Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round.

## How to ask a round

When the harness has a structured question tool (Claude Code's `AskUserQuestion`, or an equivalent that presents selectable options), put the round's **closed** questions in it:

- One tool call per round when the frontier fits the tool's limit (four questions in Claude Code). A larger frontier goes into several calls in the same round, most consequential first.
- Two to four concrete options per question. Each option label names a choice; its description states the material trade-off in a line.
- Your recommendation first, marked as recommended. The user can still type their own answer.
- Use multi-select only when the options are independent and several can hold at once.

An **open-ended** question, one whose answer is a description, a design, a set of constraints, or an explanation you cannot reduce to a short list of options without guessing, goes in chat in the same round, formatted like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body>

➡️ <your recommended answer>
```

Without a structured question tool, ask every question in that chat format, listing the options and trade-offs in the body.

## Facts and decisions

Finding _facts_ is your job, never the user's. If a fact can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking. Look it up again before _asserting_ it, in a question, a recommendation, or anything you write down for the user to keep. A remembered fact, including one from your own notes, is a guess until the repository confirms it.

Don't block a round on a lookup: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait; ask the rest of the frontier now. Delegate the lookup to a sub-agent when one is available and the search is large enough to justify it.

Closing a branch as impossible or infeasible is itself an assertion. Name the file, command, or source you checked before recording it, or leave the branch open.

The _decisions_ are the user's. Put each to them and wait.

## Closing

The session is done when the frontier is empty: every relevant branch of the design tree visited, nothing left silently assumed. Summarize the resolved intent and material constraints, then wait for confirmation of shared understanding before implementing. Keep independent, authorized investigation moving while answers are pending. Confirmation releases clear, reversible implementation; use a separate approved plan only when the consequences warrant it. Reopen a decision only when new evidence materially changes it.

An interview does not require documentation artifacts. Use domain-modeling when the task calls for maintaining domain terminology or architectural decisions, or when the user requests it.
