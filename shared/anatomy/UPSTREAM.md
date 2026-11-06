# Upstream

- Repository: https://github.com/wheresryan22/anatomy
- Revision: `1482e8469b0a9e0d8cc18ea2740a01423d29ae80`
- Skill source: https://github.com/wheresryan22/anatomy/blob/1482e8469b0a9e0d8cc18ea2740a01423d29ae80/SKILL.md
- License: MIT; see `LICENSE` in this directory.
- Imported the complete repository snapshot, without Git history, so the kit, scripts, references, examples, fixtures, and README assets remain available.
- Local changes: moved the frontmatter `compatibility` value into `metadata.compatibility` to preserve the upstream requirements while using this repository's supported frontmatter fields. The Epic tier in `SKILL.md` builds a Hero version in the same turn instead of stopping at the estimate, after an omp run stalled there. `references/verify.md` adds a harness-browser fallback, with the line-end check injected from `scripts/line-ends.mjs`, for when the scripts cannot start Chrome, as happened under omp on macOS. All other upstream files are unchanged.
- Runtime requirements: Node.js 20.10 or later; Chrome or Chromium for browser checks. Installation links the skill but does not install these tools. The active harness and environment policies still govern tool installation, browser access, and publishing.
