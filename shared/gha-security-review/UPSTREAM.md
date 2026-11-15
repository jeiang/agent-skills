# Upstream

- Repository: https://github.com/getsentry/skills
- Version: a582c51ee29d0f35e6ac321340796f77d43da733
- Skill source: https://github.com/getsentry/skills/tree/a582c51ee29d0f35e6ac321340796f77d43da733/skills/gha-security-review
- License: Apache-2.0; see `LICENSE` in this directory.
- Local changes: the frontmatter `allowed-tools` value moved into `metadata.allowed-tools`, because this repository's validator accepts only its supported frontmatter fields. `agents/openai.yaml` is added for Codex display metadata.
- The `references/` files quote real attack payloads as examples. They are reference data, not instructions.
- The work profile excludes this skill; its pipelines are Azure Pipelines.
