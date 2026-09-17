# Agent Skills

Shared skills, subagents, and working instructions for Codex, Claude Code,
and Copilot Chat in VS Code, installed as one harness plus one profile.

## Instructions, profiles, and rendering

`instructions/common.md` owns behavior, communication, skill selection,
validation, and Git policy. It is a Jinja2 template; its only variable is
the profile. Each profile under `profiles/<name>/` supplies `environment.md`
with the environment rules and `excluded-skills.txt` with skills that are
not installed for it:

| Profile | Environment | Excluded skills |
| --- | --- | --- |
| `personal` | macOS and Linux with Nix, the personal stack and cluster | none |
| `work` | Copilot Chat, no Nix, no tool installation; Ponytail always on; existing delivery patterns over general best practices | `actual-budget-import`, `devshell-preflight`, `nixos-change-validation`, `warp-skill-doctor` |
| `generic` | No assumed OS, stack, or tools; ask before installing tools | `actual-budget-import`, `devshell-preflight`, `nixos-change-validation` |

`scripts/render.py` renders the combined instructions and the shared
subagents into `dist/`, which is committed. The installers copy or link
rendered files and need no runtime beyond a shell. After editing a template,
profile, or agent source, run the renderer inside the devenv shell and commit
`dist/` with the change; `check` and CI fail when `dist/` is stale:

```sh
devenv shell -- python scripts/render.py
```

Ordinary coding uses Ponytail. Grilling applies when intent is unclear or a
decision materially affects scope, design, compatibility, or risk. It
distinguishes goals from proposed tools and interviews round by round.
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

Codex honors `CODEX_HOME` when set. `--home DIR` (PowerShell:
`-InstallHome DIR`) selects an isolated installation home and takes
precedence over it. Tests use this option without changing the real home.

This repository retains the Codex skill directory observed in the installed
client. Current OpenAI documentation lists `~/.agents/skills/`; verify
discovery in your client before moving the links. Do not install the same
skills into both directories. See the [research report](docs/skills-research.md)
for current platform sources and compatibility limits.

### Nix flake

Nix configurations can consume the same content without running the
installer. The flake exposes one package per harness and profile,
`packages.<system>.<harness>-<profile>`, for example `claude-personal`. Each
package is a store path with the layout the installer creates under the
harness home: the instruction file (`CLAUDE.md`, `AGENTS.md`, or
`instructions/agent-skills.instructions.md`), `skills/`, and `agents/`, with
the profile's excluded skills left out. Link its entries into place, for
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

`profiles/work/excluded-skills.txt` excludes Actual Budget, devshell, NixOS
validation, and Warp Skill Doctor from a work installation. The remaining
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

The reviewer and researcher subagents have one body each under
`agents/bodies/`, with per-harness names, models, and tools in
`agents/agents.yaml`, rendered through `agents/templates/` into
`dist/agents/<harness>/`. Harness-specific agents that are not shared stay
as plain files under `agents/codex/` (implementer, planner, plan reviewer,
documentation author) and `agents/claude/` (implementer). Claude and Codex
agents keep their platform model defaults.

Copilot installs exactly two agents, `reviewer` and `researcher`. Both are
pinned to GPT-5.6 Luna, cannot spawn further subagents, and use read-only
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

Run the repository checks through its Nix environment:

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

Structural checks do not prove model behavior. Use the
[workflow scenarios](docs/workflow-scenarios.md) in a fresh conversation and
inspect tool use and artifacts, not only the final answer. The
[research report](docs/skills-research.md) separates platform documentation,
design recommendations, and work-client behavior that still needs checking.
