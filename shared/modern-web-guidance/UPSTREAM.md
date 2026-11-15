# Upstream

- Repository: https://github.com/GoogleChrome/modern-web-guidance
- Version: v1.0.0 (`4dd968349e54ca45a05dd5c818fb035c9054b022`), skill version `2026_11_09-5bcc021b`
- Skill source: https://github.com/GoogleChrome/modern-web-guidance/tree/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance
- License: Apache-2.0; see `LICENSE` in this directory.
- Not vendored: the upstream `guides/` directory (210 files, 2.3 MB). `SKILL.md` never reads it; the `modern-web-guidance` npm package that the skill runs carries the same guides with its search index. The sibling `chrome-extensions` skill is also not vendored.
- Local changes: every command in `SKILL.md` sets `DISABLE_TELEMETRY=1`, and the "Using npx / pnpx" section has a bullet that says to keep it set. The CLI otherwise sends each search query, each retrieved guide ID, the operating system, and the detected agent name to Google (`play.googleapis.com/log`). All other text is unchanged.
- Updating: copy upstream `SKILL.md`, re-apply the telemetry change, and keep the `--skill-version` value upstream ships. The CLI prints an update notice when that value is older than the published package.
- Runtime requirements: Node.js 22 or later with `npx` or `pnpx`, and network access to the npm registry on first use. Installation links the skill but does not install these tools; the active environment policy governs how a missing `npx` is supplied. The work profile excludes this skill because it fetches an undeclared tool.
