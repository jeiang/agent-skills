# Upstream

- Repository: https://github.com/tamaratran/fast-jev-compaction
- Version: e3f262a7f4d42bd8dd32ced30d26176f7cb545b0 (plugin 0.3.0)
- License: MIT; see `LICENSE` in this directory.
- Local changes: none to the copied files.
- Copied: `.claude-plugin/plugin.json`, `hooks/`, `src/`, `LICENSE`. The hook imports only `../src` and type-only declarations, so this is the whole runtime.
- Left out: `.claude-plugin/marketplace.json` (upstream marketplace listing), `types/claude-code.d.ts` (typecheck only), `package.json`, `package-lock.json`, `tests/`, `examples/`, `demo/`, and the root `README.md`. Read the upstream README for the library and option details.
- This is a Claude Code function-hook plugin, not a skill. It is installed for the Claude harness only, under `~/.claude/skills/`, where Claude Code loads it as `fast-jev-compaction@skills-dir`. It needs Claude Code 2.1.274 or later with `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` and `TYPESAFE_API_KEY` in the environment. Do not also install `fast-jev-compaction@fast-jev-compaction` from the upstream marketplace.
