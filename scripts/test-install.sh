#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

assert_link() {
  [ -L "$1" ]
  [ "$(readlink "$1")" = "$2" ]
}

assert_payload() {
  {
    cat "$repo_dir/instructions/common.md"
    printf '\n'
    cat "$repo_dir/instructions/$2.md"
  } >"$test_root/expected"
  tail -n "+$3" "$1" >"$test_root/payload"
  cmp "$test_root/expected" "$test_root/payload"
}

for agent in codex claude copilot; do
  test_home="$test_root/$agent"
  agent_root="$test_home/.$agent"
  mkdir -p "$agent_root/skills"
  ln -s "$repo_dir/codex/start-task" "$agent_root/skills/start-task"
  ln -s "$repo_dir/claude/start-feature" "$agent_root/skills/start-feature"
  ln -s "$repo_dir/codex/ponytail" "$agent_root/skills/ponytail"
  if [ "$agent" = codex ]; then
    mkdir -p "$agent_root/agents"
    ln -s "$repo_dir/agents/task-orchestrator.toml" "$agent_root/agents/task-orchestrator.toml"
    printf '%s\n' '[agents]' 'max_threads = 1' >"$agent_root/config.toml"
    cp "$agent_root/config.toml" "$test_root/original-config"
  elif [ "$agent" = copilot ]; then
    while IFS= read -r skill; do
      ln -s "$repo_dir/shared/$skill" "$agent_root/skills/$skill"
    done <"$repo_dir/instructions/personal-skills.txt"
  fi

  "$repo_dir/install.sh" "$agent" --home "$test_home" >/dev/null
  for skill_path in "$repo_dir/shared"/*; do
    skill=$(basename "$skill_path")
    if [ "$agent" = copilot ] && grep -Fxq "$skill" "$repo_dir/instructions/personal-skills.txt"; then
      [ ! -e "$agent_root/skills/$skill" ] && [ ! -L "$agent_root/skills/$skill" ]
    else
      assert_link "$agent_root/skills/$skill" "$skill_path"
    fi
  done
  [ ! -L "$agent_root/skills/start-task" ]
  [ ! -L "$agent_root/skills/start-feature" ]
  [ ! -e "$test_home/.agents" ]
  for other in codex claude copilot; do
    [ "$other" = "$agent" ] || [ ! -e "$test_home/.$other" ]
  done

  case $agent in
    codex)
      instruction_file="$agent_root/AGENTS.md"
      assert_payload "$instruction_file" personal 3
      assert_link "$agent_root/agents/feature-implementer.toml" "$repo_dir/agents/feature-implementer.toml"
      [ ! -L "$agent_root/agents/task-orchestrator.toml" ]
      cmp "$agent_root/config.toml" "$test_root/original-config"
      ;;
    claude)
      instruction_file="$agent_root/CLAUDE.md"
      assert_payload "$instruction_file" personal 3
      assert_link "$agent_root/agents/feature-implementer.md" "$repo_dir/claude-agents/feature-implementer.md"
      ;;
    copilot)
      instruction_file="$agent_root/instructions/agent-skills.instructions.md"
      assert_payload "$instruction_file" work 6
      head -n 3 "$instruction_file" >"$test_root/header"
      printf '%s\n' '---' 'applyTo: "**"' '---' >"$test_root/expected-header"
      cmp "$test_root/header" "$test_root/expected-header"
      [ ! -e "$agent_root/agents" ]
      ;;
  esac

  cp "$instruction_file" "$test_root/first-install"
  "$repo_dir/install.sh" "$agent" --home "$test_home" >/dev/null
  cmp "$instruction_file" "$test_root/first-install"
  for backup in "$instruction_file".bak.*; do
    [ ! -e "$backup" ]
  done
done

# Unknown or missing targets must not default to installing every agent.
if "$repo_dir/install.sh" >/dev/null 2>&1; then exit 1; fi
if "$repo_dir/install.sh" other --home "$test_root/invalid" >/dev/null 2>&1; then exit 1; fi
[ ! -e "$test_root/invalid" ]

# Existing user instructions require an explicit replacement and a backup.
test_home="$test_root/user-instructions"
mkdir -p "$test_home/.claude"
printf '%s\n' 'User-owned instructions.' >"$test_home/.claude/CLAUDE.md"
if "$repo_dir/install.sh" claude --home "$test_home" >/dev/null 2>&1; then exit 1; fi
[ ! -e "$test_home/.claude/skills" ]
"$repo_dir/install.sh" claude --home "$test_home" --replace-instructions >/dev/null
set -- "$test_home/.claude/CLAUDE.md".bak.*
[ "$#" -eq 1 ]
printf '%s\n' 'User-owned instructions.' >"$test_root/original-instructions"
cmp "$1" "$test_root/original-instructions"
assert_payload "$test_home/.claude/CLAUDE.md" personal 3

# Updates to a managed instruction file are backed up, including local edits.
printf '%s\n' 'Local edit.' >>"$test_home/.claude/CLAUDE.md"
cp "$test_home/.claude/CLAUDE.md" "$test_root/locally-edited"
"$repo_dir/install.sh" claude --home "$test_home" >/dev/null
matched=false
for backup in "$test_home/.claude/CLAUDE.md".bak.*; do
  if cmp -s "$backup" "$test_root/locally-edited"; then matched=true; fi
done
[ "$matched" = true ]

# Replacing linked instructions must preserve their source and backup content.
test_home="$test_root/linked-instructions"
mkdir -p "$test_home/.claude"
ln -s "$test_root/original-instructions" "$test_home/.claude/CLAUDE.md"
if "$repo_dir/install.sh" claude --home "$test_home" >/dev/null 2>&1; then exit 1; fi
"$repo_dir/install.sh" claude --home "$test_home" --replace-instructions >/dev/null
[ ! -L "$test_home/.claude/CLAUDE.md" ]
set -- "$test_home/.claude/CLAUDE.md".bak.*
[ "$#" -eq 1 ]
cmp "$1" "$test_root/original-instructions"
assert_payload "$test_home/.claude/CLAUDE.md" personal 3

# Matching copied Unix skills can migrate; conflicting content stays intact.
test_home="$test_root/copied"
mkdir -p "$test_home/.codex/skills"
cp -R "$repo_dir/shared/ponytail" "$test_home/.codex/skills/ponytail"
"$repo_dir/install.sh" codex --home "$test_home" >/dev/null
assert_link "$test_home/.codex/skills/ponytail" "$repo_dir/shared/ponytail"
set -- "$test_home/.codex/backups"/skill.*/original
[ -f "$1/SKILL.md" ]

test_home="$test_root/conflict"
mkdir -p "$test_home/.codex/skills/ponytail"
printf '%s\n' 'User-owned skill.' >"$test_home/.codex/skills/ponytail/SKILL.md"
if "$repo_dir/install.sh" codex --home "$test_home" >/dev/null 2>&1; then exit 1; fi
[ -f "$test_home/.codex/skills/ponytail/SKILL.md" ]

# Retirement must not delete external links, even when a path shares a prefix.
test_home="$test_root/foreign"
mkdir -p "$test_home/.copilot/skills"
ln -s "$repo_dir-foreign/devshell-preflight" "$test_home/.copilot/skills/devshell-preflight"
if "$repo_dir/install.sh" copilot --home "$test_home" >/dev/null 2>&1; then exit 1; fi
assert_link "$test_home/.copilot/skills/devshell-preflight" "$repo_dir-foreign/devshell-preflight"

echo "Installer isolation, migration, and repeat-run tests passed."
