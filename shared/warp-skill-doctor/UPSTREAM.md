# Upstream

- Repository: https://github.com/warpdotdev/common-skills
- Version: acb107ab1096bd62243952878d8a09a40cc9e1b9
- Skill source: https://github.com/warpdotdev/common-skills/tree/acb107ab1096bd62243952878d8a09a40cc9e1b9/.agents/skills/skill-doctor
- License: MIT; see `LICENSE` in this directory.

## Local adaptation

Renamed from `skill-doctor` to `warp-skill-doctor` because Claude Code ships a
built-in `/skill-doctor` command. Only the skill identity changed: frontmatter
name, directory, heading, scratch-directory prefix, and the harness reference's
stop message, including the harness list in that message. The scorers and report branding are upstream's; the scripts are upstream's except for the collector changes listed below.
- Workflow alignment: describe the supported harness boundary in discovery metadata and omit the promotional output footer.
- Test alignment: `scripts/test_render_report.py` omits upstream's source-text tests that assert `SKILL.md`, reference, and scorer prose (startup contract, scoring formulas, scorer references, promotional output labels); the report-rendering behavior tests are kept.
- omp alignment: the harness table and description list Oh My Pi, which the Pi collector reads with `--pi-home ~/.omp/agent --skills-dir ~/.omp/agent/skills` (without `--skills-dir` it finds no skills). Step 4 drafts against the skill's source repository when the inventory path is an installed copy, because a draft cut from a Nix store snapshot reverted newer source changes.
- Collector changes in `scripts/collect_sessions.py`: skill detection also matches `skill://<name>` reads; the Pi parser counts omp `skill-prompt` slash invocations, marks sessions whose header has `parentSession` as subagents and skips them without `--include-subagents`; with that flag the Pi file finder also collects omp's nested subagent sessions. `scripts/test_collect_sessions.py` adds a test for this.
