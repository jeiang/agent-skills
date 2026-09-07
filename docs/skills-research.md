# Cross-agent instructions and skills

Research date: 2026-09-07. Sources are official product documentation and the Agent Skills project. This report records verified guidance and the agreed design rationale. It does not establish that an installation or evaluation has passed.

## Policy and workflow

The agreed design has common instructions plus separate personal and work policies. Codex and Claude Code use common plus personal policy. VS Code Copilot Chat uses common plus work policy. The source checkout may contain personal policy. The Copilot installation must not include, link to, or reference that policy. The user's work model remains 5.6 luna at max effort; this change requires no model migration.

Persistent instructions should contain rules needed in every session. Skills should hold procedures needed for a specific task. Claude's documentation distinguishes these loading patterns: `CLAUDE.md` supplies session context, while skills load on demand. This supports a small shared policy rather than a workflow manual loaded for every request. [Claude Code feature guidance](https://code.claude.com/docs/en/features-overview)

Our recommendation is to use ponytail for ordinary coding and grilling when unclear intent or a material scope, design, or risk question needs resolution. Routine work needs no launcher, plan approval ceremony, or compulsory subagent. Claude's guidance favors the main conversation for quick changes and work that shares substantial context; separate agents help with independent work or large intermediate outputs. Delegate only when that benefit exceeds coordination cost. [Claude Code subagent guidance](https://code.claude.com/docs/en/subagents)

## Native instruction files

| Client | Personal or user instruction location | Relevant loading rule |
| --- | --- | --- |
| Codex | `$CODEX_HOME/AGENTS.md`, normally `~/.codex/AGENTS.md` | A nonempty `AGENTS.override.md` replaces it. Project files load from repository root to working directory, at most one per directory. |
| Claude Code | `~/.claude/CLAUDE.md`; rules under `~/.claude/rules/` | Ancestor instructions concatenate. `@path` imports load additional files. |
| VS Code Copilot Chat | `~/.copilot/instructions/*.instructions.md` | Use `applyTo: "**"` for guidance that applies to all files. |

Codex has a default combined instruction limit of 32 KiB. Its documentation does not define Claude-style imports. Generate a self-contained common-plus-personal file instead of assuming cross-client import syntax. [Official OpenAI instruction guidance](https://learn.chatgpt.com/docs/agent-configuration/agents-md)

Claude Code does not directly load `AGENTS.md`; a `CLAUDE.md` import or symlink provides compatibility. Relative imports resolve from the importing file. Instructions imported through `/import` are a one-time copy, not a synchronized source. [Claude Code memory guidance](https://code.claude.com/docs/en/memory)

VS Code also automatically reads workspace `AGENTS.md`, `.github/copilot-instructions.md`, and supported `CLAUDE.md` locations. User instruction directories include `~/.claude/rules`; `~/.claude/CLAUDE.md` can also supply persistent personal instructions. A work file in `~/.copilot` therefore does not, by itself, exclude an existing personal Claude setup. [VS Code instruction guidance](https://code.visualstudio.com/docs/agent-customization/custom-instructions)

## Skill discovery and invocation

Current OpenAI documentation lists user skills in `~/.agents/skills/` and repository `.agents/skills/` directories between the working directory and repository root. Symlinked skill directories work. Duplicate names are not merged and can both appear in selectors. The current task's supplied skill catalog shows `~/.codex/skills/` compatibility; that is an observation from task context, not a directory documented by the current guide. Preserve a working installation until client discovery is checked. Do not install the same skill into both roots to cover uncertainty. [Official OpenAI skill guidance](https://learn.chatgpt.com/docs/build-skills)

Claude uses `~/.claude/skills/<name>/SKILL.md` and repository `.claude/skills/<name>/SKILL.md`. Individual skill folders can be symlinks. Same-name precedence is enterprise, personal, then project. Plugin skills receive a namespace. [Claude Code skill guidance](https://code.claude.com/docs/en/skills)

VS Code lists `.github/skills`, `.claude/skills`, and `.agents/skills` in repositories, plus `~/.copilot/skills`, `~/.claude/skills`, and `~/.agents/skills` at user scope. Its guide does not specify duplicate-name precedence. Keep one discoverable copy per client. [VS Code skill guidance](https://code.visualstudio.com/docs/agent-customization/agent-skills)

| Intent | Codex | Claude Code and VS Code Copilot |
| --- | --- | --- |
| Automatic use permitted | Default; `policy.allow_implicit_invocation: true` in `agents/openai.yaml` | Default; `disable-model-invocation: false` in `SKILL.md` frontmatter |
| Explicit invocation only | `policy.allow_implicit_invocation: false` | `disable-model-invocation: true` |
| Hide command but retain automatic use | No equivalent established here | `user-invocable: false` |
| Explicit command | `$skill-name` | `/skill-name` |

These controls are client-specific, not interchangeable fields. Defaults permit automatic use; they do not guarantee a trigger. Avoid `context: fork` in ordinary shared skills because it requests a separate agent context. [OpenAI metadata](https://learn.chatgpt.com/docs/build-skills), [Claude frontmatter](https://code.claude.com/docs/en/skills), [VS Code frontmatter](https://code.visualstudio.com/docs/agent-customization/agent-skills)

## Work installation boundary

Generate one self-contained common-plus-work instruction artifact and install only selected skills. Keep personal source files outside automatic discovery paths. Do not place personal policy in the checkout's root `AGENTS.md` if Copilot will open that checkout. Review links from installed skills as well as the instruction artifact.

For a shared machine, relevant controls include `chat.instructionsFilesLocations`, `chat.agentSkillsLocations`, and `chat.useClaudeMdFile`. Disabling Claude instruction loading also removes useful project Claude instructions, so document that tradeoff. The latter setting defaults to `true`. The AI settings reference omits `.agents` paths from its default skills example although the skills guide lists them. This discrepancy requires a client check. [VS Code AI settings](https://code.visualstudio.com/docs/agents/reference/ai-settings)

A VS Code profile is insufficient isolation: Agent Host reads home-directory customizations instead of profile user data. Migrated files do not roam through Settings Sync; retained originals and migrated copies do not stay synchronized. Prefer one managed source and explicit installation targets. [VS Code customization scope](https://code.visualstudio.com/docs/agent-customization/overview)

## Evaluation and remaining checks

Test triggering separately from output quality. Use realistic positive prompts and close negative cases, then inspect whether the client loaded the skill. Repeat ambiguous cases because triggering can vary. Keep some prompts out of description tuning to check that improvements generalize. [Agent Skills trigger evaluation](https://agentskills.io/skill-creation/optimizing-descriptions)

Compare behavior with a baseline in clean contexts. Check observable outcomes, inspect traces, and record time and token cost where available. Exact-phrase assertions can fail correct behavior and reward empty compliance. Static checks remain useful for file structure, metadata, and prohibited installation links; they cannot establish that an agent asked the right question or avoided unnecessary delegation. [Agent Skills output evaluation](https://agentskills.io/skill-creation/evaluating-skills)

No work-client loading or behavior has been verified here. Before relying on that installation, check its version, effective discovery settings, loaded instruction sources, and representative tasks. Local implementation should use independently useful commits in dependency order. These are agreed design requirements, not claims of completed implementation.
