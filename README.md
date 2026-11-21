# Agent Skills

Shared skills and four full installations: omp personal, omp work, Copilot
work, and Claude cloud. pi consumes shared skills only. Its instructions,
agents, and harness-specific skills live in pi-extensions.

## Packages and entries

The flake lists exactly these packages for each supported system:

| Package | Contents |
| --- | --- |
| `omp-personal` | Personal instructions, skills, agents, and `RULES.md` |
| `omp-work` | Work instructions, skills, agents, and `RULES.md` |
| `copilot-work` | Work instructions, skills, and agents |
| `claude-cloud` | Cloud instructions, skills, and agents |
| `pi-personal` | `skills/` only, with personal exclusions |

`lib.entries.<harness>.<profile>` lists `instructions`, `skills`, and
`agents`, plus `rules` for omp. `lib.entries.pi.personal` has only `skills`.
Consumers can link individual entries so the client directories stay writable.
The pi package includes shared `devshell-preflight`. The pi consumer skips
that name and uses its harness-specific copy from pi-extensions.

Set `inputs.agent-skills.inputs.nixpkgs.follows = "nixpkgs"` to share nixpkgs.
Packages read committed `dist/`; render source changes before committing.
Do not mix a flake installation and the installer in one harness home.

## Install

Use a stable checkout because skill and agent symlinks point into it.
Both arguments are required. Only these full installations are supported:

```sh
./install.sh omp personal
./install.sh omp work
./install.sh copilot work
./install.sh claude cloud
```

PowerShell 7 supports the same pairs through `install.ps1`. Windows needs
Developer Mode or an authorized administrator shell for symlinks.
`--home DIR` or `-InstallHome DIR` selects an isolated home.

| Harness | Instructions | Skills and agents |
| --- | --- | --- |
| omp | `~/.omp/agent/AGENTS.md` | `~/.omp/agent/{skills,agents}/` |
| Copilot | `~/.copilot/instructions/agent-skills.instructions.md` | `~/.copilot/{skills,agents}/` |
| Claude | `~/.claude/CLAUDE.md` | `~/.claude/{skills,agents}/` |

Unmanaged instructions require `--replace-instructions` or
`-ReplaceInstructions`. Replacement and managed updates preserve a backup.
Identical repeat installations make no backup. External symlinks and
conflicting files are refused. Identical copied skill directories can migrate
with a backup on POSIX; PowerShell refuses copied directories.

omp task agents receive `RULES.md`, not `AGENTS.md`. Keep
`instructions/omp-rules.md` short. The installer does not honor
`PI_CODING_AGENT_DIR`, since task-agent discovery uses the native agent home.

## Sources and profiles

`instructions/common.md` owns shared behavior and communication.
`profiles/<profile>/environment.md` supplies environment policy;
`excluded-skills.txt` selects shared skills. Personal assumes macOS or Linux
with Nix. Work forbids tool installation and personal policy. Cloud assumes
a disposable Claude container with Nix and no host or cluster access.
`instructions/<harness>-<profile>.md` can replace rendered instructions.

`scripts/render.py` renders instructions and shared agents into committed
`dist/`. Ponytail's body is inlined into instructions for ordinary coding.

Every maintained skill lives under `shared/`. Descriptions define automatic
relevance. `disable-model-invocation: true` makes a skill explicit-only.
Invoke such skills directly through the harness. Discovery never authorizes
external actions or overrides environment restrictions.

Reviewer and researcher bodies live in `agents/bodies/`, with harness
settings in `agents/agents.yaml`. Claude keeps its implementer and rendered
agents. Copilot installs exactly reviewer and researcher with read-only tools
and no nested agents. omp keeps its existing agents and model roles.

Vendored skills retain `UPSTREAM.md` and required licenses beside the source.
Local deviations belong in the upstream note. `audit-your-codebase` has no
stated upstream license; its upstream note records that limitation.

## Development and verification

```sh
devenv shell -- python scripts/render.py
devenv shell -- scripts/check.sh
```

When devenv is absent, prefix commands with
`nix run nixpkgs#devenv -- shell --`. Checks validate skills and retained
agents, rendered output, installer isolation and migration, shell syntax and
formatting, and whitespace. PowerShell tests run only when `pwsh` is available.
CI runs the same checks. Work machines must use available tools or the normal
pipeline and report checks that could not run.

Structural checks do not prove model behavior. See
[workflow scenarios](docs/workflow-scenarios.md) for fresh-session checks.
