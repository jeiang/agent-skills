#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-install.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

home="$test_root/home"
mkdir -p "$home/.codex/agents" "$home/.codex/skills"
ln -s "$repo_dir/codex/ponytail" "$home/.codex/skills/ponytail"
printf '%s\n' 'retired' >"$home/.codex/agents/prompt-validator.toml"
cat >"$home/.codex/config.toml" <<'EOF'
[ui]
theme = "dark"

[agents]
max_threads = 1

[[agents.roles]]
name = "reviewer"
EOF

HOME="$home" "$repo_dir/install.sh" >/dev/null

[ -L "$home/.codex/skills/start-task" ]
[ "$(readlink "$home/.codex/skills/start-task")" = "$repo_dir/codex/start-task" ]
for skills_root in "$home/.codex/skills" "$home/.claude/skills"; do
  [ -L "$skills_root/ponytail" ]
  [ "$(readlink "$skills_root/ponytail")" = "$repo_dir/shared/ponytail" ]
  [ -L "$skills_root/grill-with-docs" ]
  [ "$(readlink "$skills_root/grill-with-docs")" = "$repo_dir/shared/grill-with-docs" ]
  [ -L "$skills_root/grilling" ]
  [ "$(readlink "$skills_root/grilling")" = "$repo_dir/shared/grilling" ]
  [ -L "$skills_root/domain-modeling" ]
  [ "$(readlink "$skills_root/domain-modeling")" = "$repo_dir/shared/domain-modeling" ]
done
[ ! -e "$home/.claude/skills/start-task" ]
[ -L "$home/.claude/skills/start-feature" ]
[ "$(readlink "$home/.claude/skills/start-feature")" = "$repo_dir/claude/start-feature" ]
[ ! -e "$home/.codex/skills/start-feature" ]
[ -L "$home/.claude/agents/feature-implementer.md" ]
[ "$(readlink "$home/.claude/agents/feature-implementer.md")" = "$repo_dir/claude-agents/feature-implementer.md" ]
[ -L "$home/.codex/agents/feature-implementer.toml" ]
[ "$(readlink "$home/.codex/agents/feature-implementer.toml")" = "$repo_dir/agents/feature-implementer.toml" ]
[ ! -e "$home/.codex/agents/prompt-validator.toml" ]
grep -F 'theme = "dark"' "$home/.codex/config.toml" >/dev/null
grep -F 'max_threads = 4' "$home/.codex/config.toml" >/dev/null
grep -F 'max_depth = 2' "$home/.codex/config.toml" >/dev/null
grep -F '[[agents.roles]]' "$home/.codex/config.toml" >/dev/null
grep -F 'name = "reviewer"' "$home/.codex/config.toml" >/dev/null

backup_count=$(find "$home/.codex" -maxdepth 1 -name 'config.toml.bak.*' | wc -l | tr -d ' ')
[ "$backup_count" -eq 1 ]

HOME="$home" "$repo_dir/install.sh" >/dev/null
repeat_backup_count=$(find "$home/.codex" -maxdepth 1 -name 'config.toml.bak.*' | wc -l | tr -d ' ')
[ "$repeat_backup_count" -eq "$backup_count" ]

conflict_home="$test_root/conflict-home"
mkdir -p "$conflict_home/.codex/skills/start-task"
if HOME="$conflict_home" "$repo_dir/install.sh" >/dev/null 2>"$test_root/conflict.err"; then
  echo "Installer accepted a conflicting skill destination" >&2
  exit 1
fi
grep -F 'Refusing conflicting skill destination' "$test_root/conflict.err" >/dev/null

echo "Installer smoke tests passed."
