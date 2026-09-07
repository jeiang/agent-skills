# Agent Skills

Shared skills and working instructions for personal Codex/Claude Code and
work Copilot Chat in VS Code.

## Instructions and workflow

`instructions/common.md` owns behavior, communication, skill selection,
validation, and Git policy. `instructions/personal.md` and
`instructions/work.md` supply the environment rules. The installer combines
the common source and one policy into a self-contained native instruction
file. Edit the sources and rerun the installer to update that file.

Ordinary coding uses Ponytail. Grilling applies when intent is unclear or a
decision materially affects scope, design, compatibility, or risk. It
distinguishes goals from proposed tools and asks one question at a time.
Clear, reversible changes proceed directly; consequential changes need a
short approved plan. Research, implementation, and review use subagents only
when a separate context or parallel work will help.

Implementation requests authorize local commits unless the user says
otherwise. Each commit is a usable checkpoint in dependency order, not an
arbitrary module slice. Implementers commit their own checkpoints as work
progresses. Coordinators cannot defer commits on their own or rebuild a
commit sequence from a large uncommitted diff.

The retired `start-task`, `start-feature`, and `task_orchestrator` are no
longer needed. Use ordinary requests, or invoke a focused skill directly.

## Install one agent

Use a stable checkout. Skill and custom-agent symlinks point to this checkout,
so moving or deleting it breaks those links. Run only the target you use:

| Machine and agent | POSIX shell | PowerShell 7 |
| --- | --- | --- |
| Personal Codex | `./install.sh codex` | `./install.ps1 codex` |
| Personal Claude Code | `./install.sh claude` | `./install.ps1 claude` |
| Work Copilot Chat in VS Code | `./install.sh copilot` | `./install.ps1 copilot` |

Windows symlink creation requires Developer Mode or an authorized
administrator shell. The installer does not download tools or change the
selected model, reasoning effort, VS Code settings, or Codex agent limits.

| Agent | Installed instruction file | Skill directory |
| --- | --- | --- |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/skills/` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/` |
| Copilot | `~/.copilot/instructions/agent-skills.instructions.md` | `~/.copilot/skills/` |

Codex honors `CODEX_HOME` when set. `--home DIR` (PowerShell:
`-InstallHome DIR`) selects an isolated installation home and takes
precedence over it. Tests use this option without changing the real home.

This repository retains the Codex skill directory observed in the installed
client. Current OpenAI documentation lists `~/.agents/skills/`; verify
discovery in your client before moving the links. Do not install the same
skills into both directories. See the [research report](docs/skills-research.md)
for current platform sources and compatibility limits.

### Existing installations

Unmanaged instruction files are preserved by default. To adopt these
instructions, explicitly request replacement, for example:

```sh
./install.sh codex --replace-instructions
```

The PowerShell equivalent is
`./install.ps1 codex -ReplaceInstructions`. Replacement and later managed
updates create a backup beside the instruction file. Repeat installation
with identical content does not create another backup. Edit source policies,
not the generated installed file; managed local edits are backed up when
regenerated.

The installer updates only the selected agent. It relinks moved skills and
removes retired launchers or excluded personal skills only when their
symlinks point inside this checkout. Conflicting files, external symlinks,
and unmanaged retired entries are left intact with an error. Review those
entries before removing them. The POSIX installer can also migrate identical
copied skill directories into links, with a backup; PowerShell refuses
copied skill directories, which its previous installer did not create.

### Work boundary

Copilot receives common + work policy only. It receives no personal-policy
file, import, reference, or symlink. The full repository can remain checked
out on the work machine.

`instructions/personal-skills.txt` excludes Actual Budget, devshell, NixOS
validation, and Warp Skill Doctor from Copilot installation. The remaining
skills use the work policy: no missing-tool installation and no ad hoc
replacement validators. Edits can continue with available checks and tests;
the agent identifies testing still needed instead of claiming it ran.

VS Code can also discover existing `~/.claude/CLAUDE.md`,
`~/.claude/rules/`, and other configured instruction roots. A Copilot-only
install does not remove unrelated prior configuration. Use Chat Diagnostics
to verify loaded sources. If that home also contains personal Claude
instructions, review `chat.useClaudeMdFile` and
`chat.instructionsFilesLocations` in work settings. Disabling Claude-file
discovery also affects useful project Claude instructions. The installer
does not link personal policy into the repository root or modify settings.
See [VS Code instruction discovery](https://code.visualstudio.com/docs/agent-customization/custom-instructions).

## Skills and optional agents

Every maintained skill has one source under `shared/`. `generic/` remains
available for portable additions; it is installed into the selected agent's
skill directory rather than creating another global discovery path.

| Skills | When they apply |
| --- | --- |
| `ponytail`, `grilling` | Coding simplicity and unresolved intent or consequential decisions |
| `kubernetes-delivery`, `kubernetes-diagnose`, `azure-pipelines-maintenance` | The matching delivery, incident, or pipeline task |
| `devshell-preflight`, `nixos-change-validation` | Personal Nix environments and Nix configuration changes |
| `research`, `prototype`, `domain-modeling`, `diagram`, `eli5` | The specific research, design, documentation, or explanation request |
| `audit-your-codebase` | A requested whole-repository simplification audit |
| `actual-budget-import`, `warp-skill-doctor` | Personal budget imports or evaluation from supported local agent histories |
| `grill-with-docs`, `wayfinder`, `i-have-adhd` | Explicit invocation only, consistently across all three platforms |

Descriptions define automatic relevance. Claude/Copilot use
`disable-model-invocation` in skill frontmatter; Codex uses the inverse
`policy.allow_implicit_invocation` in `agents/openai.yaml`. Validation
checks that these settings agree. Automatic discovery does not authorize
external actions or override environment restrictions.

`agents/` contains optional Codex specialists; `claude-agents/` contains
optional Claude implementer, reviewer, and researcher definitions. They
retain their platform-specific model defaults. Copilot uses its selected
VS Code model and available agent tools.

Vendored skills retain their upstream notes and licenses beside the source.
`audit-your-codebase` has no stated upstream license; this existing
redistribution limitation is recorded in its `UPSTREAM.md`.

## Development and verification

Run the repository checks through its Nix environment:

```sh
devenv shell -- check
```

If `devenv` is not on PATH, use
`nix run nixpkgs#devenv -- shell -- check`. Inside the environment, run
`check` directly. The checks validate skill and agent structure, invocation
policy consistency, native installer isolation and migration, shell syntax
and formatting, and the Git diff. PowerShell execution runs when `pwsh` is
available; otherwise the suite reports that check as skipped.

Structural checks do not prove model behavior. Use the
[workflow scenarios](docs/workflow-scenarios.md) in a fresh conversation and
inspect tool use and artifacts, not only the final answer. The
[research report](docs/skills-research.md) separates platform documentation,
design recommendations, and work-client behavior that still needs checking.
