# Upstream

- Repository: https://github.com/zaxified/zig-skills
- Version: 87c299c3448e7bb09750d7de48d326d1f076d43b (Zig 0.17.1)
- Skill source: https://github.com/zaxified/zig-skills/tree/87c299c3448e7bb09750d7de48d326d1f076d43b/skills/zig
- License: MIT; see `LICENSE` in this directory.
- Local changes, all in the `SKILL.md` frontmatter: `name` is `zig` instead of `zig-0.17`, because a skill name holds only lowercase letters, digits, and hyphens and must match its directory. The description is shortened from 1,893 to under 1,024 characters; it keeps the trigger and drops part of the list of covered changes. `compatibility` moved into `metadata.compatibility`. `agents/openai.yaml` is added for Codex display metadata. The body and `references/` are unchanged.
- Verification on 2026-11-15 with upstream's own checkers against Zig 0.17.1 from nixpkgs: `scripts/check-std-paths.py` found 1,128 of 1,129 `std` paths (`std.elf.AT.PLATFORM` is missing on macOS), and `scripts/check-examples.py` compiled all 31 standalone examples.
- Security scan on 2026-11-15 (getsentry `skill-scanner` at `a582c51`, plus a search of `SKILL.md` and `references/` for instructions aimed at the agent, install commands, and URLs): no findings. The agent-directed lines all say to ask the user before adding a dependency or changing the toolchain. Re-run both after each upstream update; the repository has one author.
- Updating: upstream tracks one Zig release per version of this skill. When the projects move to a new Zig release, replace the directory with upstream's copy for that release and re-apply the frontmatter changes.

- Discovery metadata: shortened to a one-line description; explicit-only flags follow the local skill list. Codex discovery metadata is omitted. Skill bodies are unchanged by this metadata update.
