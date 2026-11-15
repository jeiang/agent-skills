# Upstream

- Repository: https://github.com/getsentry/skills
- Version: a582c51ee29d0f35e6ac321340796f77d43da733
- Skill source: https://github.com/getsentry/skills/tree/a582c51ee29d0f35e6ac321340796f77d43da733/skills/iterate-pr
- License: Apache-2.0; see `LICENSE` in this directory.
- Local changes: none.
- Behavior to know: the skill commits and pushes fixes to the pull request branch and never merges. The installed instructions still govern authorization to push; the skill does not grant it.
- Runtime requirements: an authenticated `gh` and `uv` (the scripts use only the Python standard library). The work profile excludes this skill.
