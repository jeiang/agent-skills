# Upstream

- Repository: https://github.com/ayghri/i-have-adhd
- Version: 1ecea1993b7fce257ffbd686c070948b5e07eda6
- Skill source: https://github.com/ayghri/i-have-adhd/tree/1ecea1993b7fce257ffbd686c070948b5e07eda6/skills/i-have-adhd
- License: MIT; see `LICENSE` in this directory.

## Local adaptation

This copy adds adaptive expertise calibration: use personalization and prior
context to preserve action-first ADHD guidance without explaining familiar
tools or routine mechanics to experienced readers.
- The upstream `agents/gemini.toml` Gemini CLI command is vendored unmodified; no installer here uses it.
- Output shaping: the banned opener/closer phrase lists and the five-item list cap are restated as the behavior they aimed at.
- Invocation alignment: Codex now uses the same explicit-only setting as Claude and Copilot.
