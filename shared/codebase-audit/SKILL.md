---
name: codebase-audit
description: "Rank evidence-backed codebase improvements. Invoke for simplification, agent readability, or deeper module interfaces."
disable-model-invocation: true
argument-hint: "[optional subsystem or concern]"
---

# Codebase Audit

Audit the requested scope and end with a ranked Markdown report. Stay read-only:
inspect source and history, but do not edit repository files, run tests, install
tools, commit, or push. Deliver the report in the reply unless the user requests
a saved Markdown file. Use no HTML, browser, or CDN assets.

Work as one agent by default. Use bounded read-only subagents only when the
repository does not fit one context. Give each a distinct ownership scope and
verify its findings yourself. Delegation does not reduce the coverage required.

## 1. Establish coverage

Read repository instructions, manifests, entry points, any `GLOSSARY.md`, and
relevant ADRs. Respect intentional constraints. A conflict with an ADR is a
finding only when concrete evidence warrants revisiting that decision.

Inventory each identifiable subsystem with an ID, exact ownership scope, key
files, public interfaces, major callers, and tests. Include delivery and tooling
where relevant. Mark each queued, reviewed with findings, or reviewed with an
explicit skip reason. Generated files belong with their source owner.

Use the user's named concern first. Otherwise, recent changes and repeated
maintenance hotspots guide review order, not coverage exclusions. For a
whole-repository request, review every subsystem. State exclusions and unreadable
areas rather than treating them as reviewed.

## 2. Inspect three kinds of friction

For every subsystem, read implementation, interfaces, callers, and existing tests.
Look for evidence in these three lenses:

- **Simplification:** contradictory states, scattered booleans, repeated shape
  assumptions, duplicate branching, unclear ownership, lifecycle races, and
  repeated transformations that a better representation would remove.
- **Agent readability:** hidden links between things that must change together;
  needless links between things that change for different reasons; dead code,
  pass-through wrappers, speculative extension points, and caller-specific
  exceptions that obscure the underlying requirements.
- **Module depth:** behavior spread across shallow modules, caller knowledge of
  internals, ordering conventions, and tests that must bypass the interface.
  A module is deep when a small interface hides substantial behavior. Its
  interface includes invariants, ordering, errors, and configuration, not just
  types. A seam is where behavior can vary; an adapter satisfies that interface.

Ask what a typical change requires reading and editing. Use callers and history
to substantiate coupling; a folder layout alone is not evidence. Apply the
deletion test: if removing a module also removes complexity, it may be surplus;
if that complexity reappears across callers, the module earns its keep.

Group symptoms under the smallest root-cause change that removes them. Preserve
necessary special cases and explain why they remain. Reject cosmetic uniformity,
hypothetical extensibility, line-count wins alone, and abstractions that merely
move branching. Tests and comments are evidence, not automatic cleanup targets.

## 3. Verify and rank

Check each candidate against current source, callers, tests, and ADRs. Deduplicate
cross-subsystem findings under one owner. Record explicit skips when no material
improvement survives scrutiny. Do not fill a quota.

Use one ranking across all three lenses: **expected reduction in change burden
and defect risk per unit of implementation cost**. Explain the comparison in
plain terms, not a fabricated numeric score. Assess each candidate's:

- concrete impact: invalid states removed, facts callers stop knowing, files a
  common change stops touching, and behavior testable through one interface;
- evidence confidence and relevance to real maintenance or recent changes;
- effort, migration risk, blast radius, and prerequisites.

This rewards simpler representations, less searching and hidden coupling, and
deeper interfaces for the same reason: less knowledge spread across a change.
Rank high-confidence, frequently exercised improvements ahead of speculative
redesigns. Break ties with lower migration risk and smaller implementation scope.
Show dependencies even when they prevent the highest-impact item going first.

## 4. Report and stop

Return a ranked Markdown report containing:

1. Scope, coverage table, explicit skips, and any evidence gaps.
2. Each finding's rank, owner, exact file and line evidence, present friction,
   proposed representation or module change, and concrete benefit across the
   relevant lenses.
3. Smallest credible implementation scope, affected callers and interfaces,
   retained special cases, risks, confidence, prerequisites, and required
   validation. Distinguish existing checks from suggested checks not run.
4. The best first item and why it wins under the shared ranking.

Before reporting, check coverage, duplicates, materiality, and dependency order
against the inventory. Stop at the report. Do not start an interview, update the
domain model, or implement recommendations. Each item the user accepts becomes
ordinary work under the repository's normal instructions, outside this audit.
