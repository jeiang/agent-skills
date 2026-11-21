# Upstream

- Repository: https://github.com/mattpocock/skills
- Version: 5863806dd4e15c63174bee4e7515a4256792ecfa
- Skill source: https://github.com/mattpocock/skills/tree/5863806dd4e15c63174bee4e7515a4256792ecfa/skills/engineering/wayfinder
- Dependencies: `grilling`, `domain-modeling`, `research`, and `prototype`, vendored alongside this skill.
- Local changes: the tracker-doc reference in `SKILL.md` points at the bundled `trackers/` directory instead of the upstream `/setup-matt-pocock-skills` skill, which is not vendored. The `trackers/` docs are copied from `skills/engineering/setup-matt-pocock-skills` at the same version, and the GitHub tracker adds a bulk-creation rule (batch timeout, resumable by title). The ticket-resolution step also says to read a map's research fact sheets with the harness's file-reading tool rather than a shell `cat`. Ticket sizing drops the fixed 100K-token session figure.
- Local changes: with no tracker provided, the map defaults to GitHub when `gh repo view` works and otherwise asks, instead of defaulting to the local-markdown tracker; every observed map was moved to GitHub by the user. Recording a resolution confirms a subagent's reported comment and close on the tracker first, because a subagent once reported a ticket closed that was still open.
- License: MIT; see `LICENSE` in this directory.

- Discovery metadata: shortened to a one-line description; explicit-only flags follow the local skill list. Codex discovery metadata is omitted. Skill bodies are unchanged by this metadata update.
