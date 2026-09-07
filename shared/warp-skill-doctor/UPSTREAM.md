# Upstream

- Repository: https://github.com/warpdotdev/common-skills
- Version: f589e224907eda566c13755529f59db563090d14
- Skill source: https://github.com/warpdotdev/common-skills/tree/f589e224907eda566c13755529f59db563090d14/.agents/skills/skill-doctor
- License: MIT; see `LICENSE` in this directory.

## Local adaptation

Renamed from `skill-doctor` to `warp-skill-doctor` because Claude Code ships a
built-in `/skill-doctor` command. Only the skill identity changed: frontmatter
name, directory, heading, scratch-directory prefix, and the harness reference's
stop message. The scripts, scorers, and report branding are upstream's.
- Workflow alignment: describe the supported harness boundary in discovery metadata and omit the promotional output footer.
