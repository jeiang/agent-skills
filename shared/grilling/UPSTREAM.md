# Upstream

- Repository: https://github.com/mattpocock/skills
- Version: 959a8e9f1edc3adbe2f7e3054bb6fbefa6696260
- Skill source: https://github.com/mattpocock/skills/tree/959a8e9f1edc3adbe2f7e3054bb6fbefa6696260/skills/productivity/grilling
- Used by: `grill-with-docs` and `wayfinder`.
- Local changes: the look-up-the-fact rule is extended to facts the interview *asserts*, not only ones it would otherwise ask about, and closing a branch as infeasible now requires naming the source checked.
- Not adopted: upstream's round-by-round frontier interview (several numbered questions per turn with a fixed emoji format). This copy keeps one decision per turn, which the working agreements require; multiple questions per turn is the failure mode the original text warned about.
- Local changes: a closed decision is asked through the harness's structured question tool when one exists (Claude Code's `AskUserQuestion`), with two to four options, a one-line trade-off each, and the recommendation first. Open-ended questions stay in chat.
- License: MIT; see `LICENSE` in this directory.
- Workflow alignment: trigger on unclear intent or consequential decisions, separate goals from proposed methods, avoid reopening settled questions, and reserve extra plan approval for consequential work.
