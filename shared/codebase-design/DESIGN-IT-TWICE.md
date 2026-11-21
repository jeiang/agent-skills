# Design It Twice

When the user wants to explore alternative interfaces for a new module, compare alternatives inline by default. Based on "Design It Twice" (Ousterhout): your first idea is unlikely to be the best.

Uses the vocabulary in [SKILL.md](SKILL.md): **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Before exploring alternatives, write a user-facing explanation of the problem space for the new module:

- The constraints any new interface would need to satisfy
- The dependencies it would rely on, and which category they fall into (see [DEEPENING.md](DEEPENING.md))
- A rough illustrative code sketch to ground the constraints, not a proposal, just a way to make the constraints concrete

Show this to the user, then immediately proceed to Step 2. Keep the exploration inline unless read-only subagents would add useful independent perspectives.

### 2. Explore alternatives

Design contrasting interfaces inline. Optionally use read-only subagents for independent alternatives; choose their number based on the question, with no minimum. Each alternative must offer a **radically different** interface for the new module.

If delegating, give each read-only subagent a separate technical brief (file paths, coupling details, dependency category from [DEEPENING.md](DEEPENING.md), what sits behind the seam). The brief is independent of the user-facing problem-space explanation in Step 1. Use different design constraints:

- Minimal surface: "Minimize the interface: aim for 1–3 entry points max. Maximize leverage per entry point."
- Flexibility: "Maximize flexibility: support many use cases and extension."
- Common caller: "Optimize for the most common caller: make the default case trivial."
- Dependencies (if applicable): "Design around ports & adapters for cross-seam dependencies."

Include both [SKILL.md](SKILL.md) vocabulary and GLOSSARY.md vocabulary in the brief so each sub-agent names things consistently with the architecture language and the project's domain language.

Each sub-agent outputs:

1. Interface (types, methods, params, plus invariants, ordering, error modes)
2. Usage example showing how callers use it
3. What the implementation hides behind the seam
4. Dependency strategy and adapters (see [DEEPENING.md](DEEPENING.md))
5. Trade-offs: where leverage is high, where it's thin

### 3. Present and compare

Present designs sequentially so the user can absorb each one, then compare them in prose. Contrast by **depth** (leverage at the interface), **locality** (where change concentrates), and **seam placement**.

After comparing, give your own recommendation: which design you think is strongest and why. If elements from different designs would combine well, propose a hybrid. Be opinionated: the user wants a strong read, not a menu.
