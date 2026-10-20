# Upstream

- Repository: https://github.com/DietrichGebert/ponytail
- Version: v5.3.2
- Skill source: https://github.com/DietrichGebert/ponytail/blob/v5.3.2/skills/ponytail/SKILL.md
- License: MIT; see `LICENSE` in this directory.
- Not adopted: the `shortcut: <limit>, <when to upgrade>` code-comment form, the closing "end your reply with one or two lines" output rule, the assert-based self-check requirement, the hardware-calibration item in the "Never cut" list, and the `off` argument; this copy keeps its plain-comment, no-output-limit, repository-tests, and explicit-invocation behavior.
- Local changes: scope persistence to coding, preserve intent and approval boundaries, remove mandatory comments and output limits, use repository tests under the installed environment policy, and drop the hardware-calibration aside.
- Local description: limited to explicit invocation and level selection, because `scripts/render.py` inlines this body into the rendered instructions. Keep the `# Ponytail` title; the renderer drops it and nests the remaining headings one level deeper.
