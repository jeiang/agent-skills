# Upstream

- Repository: https://github.com/warpdotdev/common-skills
- Version: 82d2bd940298dc53efc6694370268fb910c22396
- Skill source: https://github.com/warpdotdev/common-skills/tree/82d2bd940298dc53efc6694370268fb910c22396/.agents/skills/skill-doctor
- License: MIT; see `LICENSE` in this directory.

## Local adaptation

Renamed from `skill-doctor` to `warp-skill-doctor` because Claude Code ships a
built-in `/skill-doctor` command. Only the skill identity changed: frontmatter
name, directory, heading, scratch-directory prefix, and the harness reference's
stop message, including the harness list in that message. The scripts, scorers, and report branding are upstream's.
- Workflow alignment: describe the supported harness boundary in discovery metadata and omit the promotional output footer.
