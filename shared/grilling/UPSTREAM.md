# Upstream

- Repository: https://github.com/mattpocock/skills
- Version: 959a8e9f1edc3adbe2f7e3054bb6fbefa6696260
- Skill source: https://github.com/mattpocock/skills/tree/959a8e9f1edc3adbe2f7e3054bb6fbefa6696260/skills/productivity/grilling
- Used by: `grill-with-docs` and `wayfinder`.
- Local changes: the look-up-the-fact rule is extended to facts the interview *asserts*, not only ones it would otherwise ask about, and closing a branch as infeasible now requires naming the source checked.
- Local changes: a round's closed questions are asked through the harness's structured question tool when one exists (Claude Code's `AskUserQuestion`), each with two to four options, a one-line trade-off each, and the recommendation first. Open-ended questions use upstream's chat format. Sub-agent fact finding is optional rather than required.
- License: MIT; see `LICENSE` in this directory.
- Workflow alignment: trigger on unclear intent or consequential decisions, separate goals from proposed methods, avoid reopening settled questions, and reserve extra plan approval for consequential work.
