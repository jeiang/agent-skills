---
name: grilling
description: Resolve unclear intent or decisions that materially affect scope, design, compatibility, or risk through one question at a time. Use when a goal is confused with a proposed method, consequential choices remain open, or the user asks to grill or stress-test an idea. Do not interview clear, reversible tasks or reopen settled decisions.
---

Resolve the decisions needed for a shared understanding. Walk the relevant branches of the decision tree in dependency order. Match the interview depth to uncertainty and consequences; do not invent decisions to extend it. For each decision question, provide your recommended answer and the material trade-off.

Separate the desired outcome from a proposed tool or method. If the user says "I want X using Y" and the intent is unclear, establish what success means and whether Y is required. Challenge Y when it does not serve X, while preserving an explicitly required method.

Ask the questions one at a time, waiting for feedback on each question before continuing. Asking multiple questions at once is bewildering.

## How to ask

When the harness has a structured question tool (Claude Code's `AskUserQuestion`, or an equivalent that presents selectable options), ask each closed decision through it:

- One decision per call. Do not bundle questions to save a turn.
- Two to four concrete options. Each option label names a choice; its description states the material trade-off in a line.
- Your recommendation first, marked as recommended. The user can still type their own answer.
- Use multi-select only when the options are independent and several can hold at once.

Ask in chat instead when the question is open-ended: the answer is a description, a design, a set of constraints, or an explanation you cannot reduce to a short list of options without guessing. State your recommendation in the same message and wait.

If no such tool exists, ask in chat with the same shape: the question, the options with trade-offs, and the recommendation first.

## Facts and decisions

If a *fact* can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking me. Look it up again before *asserting* it, in a question, a recommendation, or anything you write down for me to keep. A remembered fact, including one from your own notes, is a guess until the repository confirms it.

Closing a branch as impossible or infeasible is itself an assertion. Name the file, command, or source you checked before recording it, or leave the branch open.

The *decisions*, though, are mine. Put each one to me and wait for my answer.

## Closing

Summarize the resolved intent and material constraints, then wait for confirmation of shared understanding before implementing the decision. Keep independent, authorized investigation moving while an answer is pending. Confirmation releases clear, reversible implementation; use a separate approved plan only when the consequences warrant it. Reopen a decision only when new evidence materially changes it.

An interview does not require documentation artifacts. Use domain-modeling when the task calls for maintaining domain terminology or architectural decisions, or when the user requests it.
