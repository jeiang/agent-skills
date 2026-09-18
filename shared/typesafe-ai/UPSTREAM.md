# Upstream

- Repository: https://github.com/typesafe-ai/skills
- Version: 65a39f393687675ce170e6094757de20370365b9
- Skill source: https://github.com/typesafe-ai/skills/tree/65a39f393687675ce170e6094757de20370365b9/skills/typesafe-ai
- License: MIT; see `LICENSE` in this directory.
- Local changes: a "Check the API key" section is added to `SKILL.md`. Before running or generating code that calls the API, the agent checks for `TYPESAFE_API_KEY` and tells the user how to create and set it when it is missing. Upstream never names the variable. The Codex display metadata in `agents/openai.yaml` is added here, as for the other vendored skills.
- Upstream also publishes this skill as the Claude Code plugin `typesafe@typesafe-ai`. This vendored copy replaces that plugin; do not install both, or Claude Code loads two copies.
