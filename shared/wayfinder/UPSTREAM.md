# Upstream

- Repository: https://github.com/mattpocock/skills
- Version: 5beb35b040e3de97e54fa9e386d7e42d15c295c2
- Skill source: https://github.com/mattpocock/skills/tree/5beb35b040e3de97e54fa9e386d7e42d15c295c2/skills/engineering/wayfinder
- Dependencies: `grilling`, `domain-modeling`, `research`, and `prototype`, vendored alongside this skill.
- Local changes: the tracker-doc reference in `SKILL.md` points at the bundled `trackers/` directory instead of the upstream `/setup-matt-pocock-skills` skill, which is not vendored. The `trackers/` docs are copied from `skills/engineering/setup-matt-pocock-skills` at the same version. The ticket-resolution step also says to read a map's research fact sheets with the harness's file-reading tool rather than a shell `cat`. Ticket sizing drops the fixed 100K-token session figure.
- License: MIT; see `LICENSE` in this directory.
