# Upstreams

This local synthesis combines three audit approaches. It is not an upstream copy.

- Simplification: Aaron Francis, `audit-your-codebase`, gist revision
  `959a2a9c1ed1648f39872885b2686ce5b576e78c`.
  https://gist.github.com/aarondfrancis/8735edbe48532f97ee5ea818db4dbd47/959a2a9c1ed1648f39872885b2686ce5b576e78c
  No license is stated upstream. The previous vendored skill recorded this
  redistribution limitation. This synthesis uses new prose rather than copying
  the unlicensed body; attribution does not grant an upstream license.
- Agent readability: caldoai/skills, `skills/untangle-codebase`, revision
  `f3cf47774975a7d9fca45730babf4ff7ad765ada`.
  https://github.com/caldoai/skills/tree/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase
  MIT, copyright 2026 Maze. See `LICENSE`.
- Module depth: mattpocock/skills,
  `skills/engineering/improve-codebase-architecture`, revision
  `abeeaf95660ba9e8b7c753eb38f441ca707a8823`.
  https://github.com/mattpocock/skills/tree/abeeaf95660ba9e8b7c753eb38f441ca707a8823/skills/engineering/improve-codebase-architecture
  MIT, copyright 2026 Matt Pocock. See `LICENSE`.
  This source was fetched at the pinned revision; it was not previously vendored.

## Local design

- Rank all three lenses by expected reduction in change burden and defect risk
  relative to effort, with evidence, maintenance relevance, and migration risk.
- Keep whole-scope coverage and explicit skips. Work inline unless repository
  size requires bounded read-only subagents.
- End at a ranked Markdown report. Remove implementation loops, interviews,
  glossary updates, HTML reports, browser opening, and CDN dependencies.
- Explicit-only invocation. The body stays below 900 words.
