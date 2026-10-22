# Agent Skills

Shared skills, subagents, and working instructions for Codex, Claude Code,
Copilot Chat in VS Code, and Oh My Pi (`omp`), installed as one harness plus
one profile.

## Instructions, profiles, and rendering

`instructions/common.md` owns behavior, communication, skill selection,
validation, and Git policy. It is a Jinja2 template; its variables are the
profile and the Ponytail rules. Each profile under `profiles/<name>/` supplies `environment.md`
with the environment rules and `excluded-skills.txt` with skills that are
not installed for it:

| Profile | Environment | Excluded skills |
| --- | --- | --- |
| `personal` | macOS and Linux with Nix, the personal stack and cluster | none |
| `work` | Copilot Chat, no Nix, no tool installation; Ponytail always on; existing delivery patterns over general best practices | `devshell-preflight`, `nixos-change-validation`, `warp-skill-doctor` |
| `generic` | No assumed OS, stack, or tools; ask before installing tools | `devshell-preflight`, `nixos-change-validation` |
| `cloud` | Disposable Claude Code on the web container with Nix; no cluster or host access; temporary Nix tooling allowed; work and pushes on the session's designated branch | `warp-skill-doctor` |

`scripts/render.py` renders the combined instructions and the shared
subagents into `dist/`, which is committed. The installers copy or link
rendered files and need no runtime beyond a shell. After editing a template,
profile, or agent source, run the renderer inside the devenv shell and commit
`dist/` with the change; `check` and CI fail when `dist/` is stale:

```sh
devenv shell -- python scripts/render.py
```

Ordinary coding uses Ponytail, whose rules the renderer inlines from
`shared/ponytail/SKILL.md` into the instructions, so no session spends a
turn loading the skill. Grilling applies when intent is unclear or a
decision materially affects scope, design, compatibility, or risk. It
distinguishes goals from proposed tools and interviews round by round.
Clear, reversible changes proceed directly; consequential changes need a
short approved plan. Research, implementation, and review use subagents only
when a separate context or parallel work will help.
Research returns source-cited findings by default; repository notes are
written only when the requested deliverable includes them.

Implementation requests authorize local commits unless the user says
otherwise. Each commit is a usable checkpoint in dependency order, not an
arbitrary module slice. Implementers commit their own checkpoints as work
progresses. Coordinators cannot defer commits on their own or rebuild a
commit sequence from a large uncommitted diff.

The retired `start-task`, `start-feature`, and `task_orchestrator` are no
longer needed. Use ordinary requests, or invoke a focused skill directly.

## Install one harness with one profile

Use a stable checkout. Skill and custom-agent symlinks point to this checkout,
so moving or deleting it breaks those links. Both arguments are required, and
any harness accepts any profile:

| Machine and harness | POSIX shell | PowerShell 7 |
| --- | --- | --- |
| Personal Codex | `./install.sh codex personal` | `./install.ps1 codex personal` |
| Personal Claude Code | `./install.sh claude personal` | `./install.ps1 claude personal` |
| Work Copilot Chat in VS Code | `./install.sh copilot work` | `./install.ps1 copilot work` |
| Another person's machine | `./install.sh claude generic` | `./install.ps1 claude generic` |
| Claude Code on the web | `./install.sh claude cloud` | n/a |
| Personal Oh My Pi | `./install.sh omp personal` | `./install.ps1 omp personal` |

Reinstalling with a different profile regenerates the instruction file and
removes links to skills that the new profile excludes. Installations made
before profiles existed upgrade in place: links that point at former agent
locations inside this checkout are relinked to `dist/`.

Windows symlink creation requires Developer Mode or an authorized
administrator shell. The installer does not download tools or change the
selected model, reasoning effort, VS Code settings, or Codex agent limits.

| Harness | Installed instruction file | Skills | Agents |
| --- | --- | --- | --- |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/skills/` | `~/.codex/agents/` |
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/` | `~/.claude/agents/` |
| Copilot | `~/.copilot/instructions/agent-skills.instructions.md` | `~/.copilot/skills/` | `~/.copilot/agents/` |
| Oh My Pi | `~/.omp/agent/AGENTS.md` | `~/.omp/agent/skills/` | `~/.omp/agent/agents/` |

Codex honors `CODEX_HOME` when set. `--home DIR` (PowerShell:
`-InstallHome DIR`) selects an isolated installation home and takes
precedence over it. Tests use this option without changing the real home.

Oh My Pi reads its native user directory only. `~/.omp/agent/AGENTS.md`
shadows every other user-level context file it would otherwise discover
(`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and the like), so an `omp`
install alongside a Claude or Codex install loads this repository's
instructions once. Skills with `disable-model-invocation` stay loaded but are
hidden from the skill list; invoke them with `/skill:<name>`. The installer
does not honor `PI_CODING_AGENT_DIR`: `omp` relocates skills and context
files with it, but task-agent discovery still reads `~/.omp/agent/agents`.

This repository retains the Codex skill directory observed in the installed
client. Current OpenAI documentation lists `~/.agents/skills/`; verify
discovery in your client before moving the links. Do not install the same
skills into both directories.

### Nix flake

Nix configurations can consume the same content without running the
installer. The flake exposes one package per harness and profile,
`packages.<system>.<harness>-<profile>`, for example `claude-personal`. Each
package is a store path with the layout the installer creates under the
harness home: the instruction file (`CLAUDE.md`, `AGENTS.md`, or
`instructions/agent-skills.instructions.md`), `skills/`, and `agents/`, with
the profile's excluded skills left out. The `omp` harness home is
`~/.omp/agent`. Link its entries into place, for
example with home-manager:

```nix
let
  home = inputs.agent-skills.packages.${pkgs.system}.claude-personal;
in
{
  home.file.".claude/CLAUDE.md".source = "${home}/CLAUDE.md";
  home.file.".claude/skills".source = "${home}/skills";
  home.file.".claude/agents".source = "${home}/agents";
}
```

A client that keeps its own entries in these directories (Claude Code syncs
plugin skills into `~/.claude/skills`, Codex ships `~/.codex/skills/.system`)
needs the directory itself to stay writable, so link one entry at a time.
`lib.entries.<harness>.<profile>` lists the entry names for that, alongside
the harness instruction path, without building the package:

```nix
let
  entries = inputs.agent-skills.lib.entries.claude.personal;
  home = inputs.agent-skills.packages.${pkgs.system}.claude-personal;
in
lib.genAttrs (map (name: ".claude/skills/${name}") entries.skills) (...);
```

Set `inputs.agent-skills.inputs.nixpkgs.follows = "nixpkgs"` to avoid a
second nixpkgs. The packages read the committed `dist/`, so render before
committing as usual. Do not mix the flake and the installer in one harness
home. `nix flake check` builds every package.

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

The installer updates only the selected harness. It relinks moved skills and
agents and removes retired launchers or excluded skills only when their
symlinks point inside this checkout. Conflicting files, external symlinks,
and unmanaged retired entries are left intact with an error. Review those
entries before removing them. The POSIX installer can also migrate identical
copied skill directories into links, with a backup; PowerShell refuses
copied skill directories, which its previous installer did not create.

### Work boundary

The work profile receives common + work policy only. It receives no
personal-policy file, import, reference, or symlink. The full repository can
remain checked out on the work machine.

`profiles/work/excluded-skills.txt` excludes devshell, NixOS validation, and
Warp Skill Doctor from a work installation. The remaining
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

### Claude Code on the web

Each cloud session starts in a fresh container, so the installation runs from
the environment's setup script (environment menu, Edit, Setup script). The
checkout lives outside the session's working directory so the skill links
stay valid whichever repository the session opens:

```sh
#!/bin/sh
set -eu
ref=main
dir=/opt/agent-skills
if [ ! -d "$dir/.git" ]; then
  git clone --depth 1 --branch "$ref" https://github.com/jeiang/agent-skills "$dir"
else
  git -C "$dir" fetch --depth 1 origin "$ref"
  git -C "$dir" checkout -q --detach FETCH_HEAD
fi
"$dir/install.sh" claude cloud
```

Every new session installs whatever `ref` names at that moment; set it to a
tag to update deliberately. The environment's network policy must allow
github.com.

## Skills and optional agents

Every maintained skill has one source under `shared/`. `generic/` remains
available for portable additions; it is installed into the selected agent's
skill directory rather than creating another global discovery path.

| Skills | When they apply |
| --- | --- |
| `ponytail` | Explicit invocation to select a level; its full-mode rules are already in the instructions |
| `grilling` | Unresolved intent or consequential decisions |
| `kubernetes-delivery`, `kubernetes-diagnose`, `azure-pipelines-maintenance` | The matching delivery, incident, or pipeline task |
| `devshell-preflight`, `nixos-change-validation` | Personal Nix environments and Nix configuration changes |
| `research`, `prototype`, `domain-modeling`, `diagram`, `eli5` | The specific research, design, documentation, or explanation request |
| `anatomy` | Detailed interactive isometric SVG explainers, with optional WebGL and 3D |
| `audit-your-codebase` | A requested whole-repository simplification audit |
| `warp-skill-doctor` | Evaluation from supported local agent histories |
| `grill-with-docs`, `wayfinder`, `i-have-adhd` | Explicit invocation only, consistently across all platforms |

Descriptions define automatic relevance. Claude/Copilot/omp use
`disable-model-invocation` in skill frontmatter; Codex uses the inverse
`policy.allow_implicit_invocation` in `agents/openai.yaml`. Validation
checks that these settings agree. Automatic discovery does not authorize
external actions or override environment restrictions.

The reviewer and researcher subagents have one body each under
`agents/bodies/`, with per-harness names, models, and tools in
`agents/agents.yaml`, rendered through `agents/templates/` into
`dist/agents/<harness>/`. Harness-specific agents that are not shared stay
as plain files under `agents/codex/` (implementer, planner, plan reviewer,
documentation author), `agents/claude/` (implementer), and `agents/omp/`
(designer, fast, smol, max-reasoning). The Claude `change-reviewer` runs
on `opus` and the `researcher` and `feature-implementer` on `sonnet`, all at
high effort; the `researcher` starts without CLAUDE.md because its caller
passes the environment policy. The
omp `change-reviewer` and `researcher` pin no model, so they run on the
parent session's model at `thinking-level: high` with read-only tools
(`bash` for inspection commands) and cannot spawn further subagents;
`change-reviewer` is named to avoid shadowing omp's bundled `reviewer`. The
omp `designer` is the UI/UX subagent omp bundled until upstream removed it
(can1357/oh-my-pi `2493ba99c4`, MIT); it keeps that prompt, runs on the
parent session's model in place of the removed `@designer` role, and can
edit files. The omp `fast`, `smol`, and `max-reasoning` agents are
general-purpose workers that run on the model role of the same name
(`model: "@<role>"`); the consumer assigns each role a model and thinking
level in `modelRoles`.

Copilot installs exactly two agents, `reviewer` and `researcher`. Both are
pinned to GPT-6 Luna, cannot spawn further subagents, and use read-only
tools plus the terminal for inspection commands. Reasoning effort is a
global Copilot setting, not a per-agent field. The reviewer reports only
demonstrable merge-blocking defects and is instructed not to be pedantic.

Vendored skills retain their upstream notes and licenses beside the source.
When updating one, upstream content wins unless the deviation is recorded in
the skill's `UPSTREAM.md`. If upstream conflicts with a repository check or a
local rule, ask before dropping either side; do not resolve it silently.
`audit-your-codebase` has no stated upstream license; this existing
redistribution limitation is recorded in its `UPSTREAM.md`.

## Development and verification

Where the active environment policy permits Nix, run the repository checks
through its Nix environment:

```sh
devenv shell -- check
```

If `devenv` is not on PATH, use
`nix run nixpkgs#devenv -- shell -- check`. Inside the environment, run
`check` directly. The checks validate skill and agent structure, invocation
policy consistency, that `dist/` matches its sources, native installer
isolation and migration, shell syntax and formatting, and the Git diff. The
same checks run in GitHub Actions on pull requests and pushes to `main`. PowerShell execution runs when `pwsh` is
available; otherwise the suite reports that check as skipped.
The work profile must not fetch Nix or missing tools to run these commands;
use available checks and the normal pipeline, and report checks still needed.

Structural checks do not prove model behavior. Use the
[workflow scenarios](docs/workflow-scenarios.md) in a fresh conversation and
inspect tool use and artifacts, not only the final answer.
