# Upstream

- Repository: https://github.com/ayghri/i-have-adhd
- Version: 0a84de401019a3a822248df586d88a2b56f8c6af
- Skill source: https://github.com/ayghri/i-have-adhd/tree/0a84de401019a3a822248df586d88a2b56f8c6af/skills/i-have-adhd
- License: MIT; see `LICENSE` in this directory.

## Local adaptation

This copy adds adaptive expertise calibration: use personalization and prior
context to preserve action-first ADHD guidance without explaining familiar
tools or routine mechanics to experienced readers.
- Upstream's `metadata:` frontmatter block (tags, category) is dropped because this repository's skill validator does not allow the field; `license: MIT` is kept.
- The upstream `agents/gemini.toml` Gemini CLI command is vendored unmodified; no installer here uses it.
- Invocation alignment: Codex now uses the same explicit-only setting as Claude and Copilot.
