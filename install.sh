#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
skill_source="$repo_dir/skills/start-task"
skill_parent="$HOME/.agents/skills"
skill_target="$skill_parent/start-task"
agent_target="$HOME/.codex/agents"
config_file="$HOME/.codex/config.toml"

mkdir -p "$skill_parent" "$agent_target" "$(dirname -- "$config_file")"

if [ -e "$skill_target" ] && [ ! -L "$skill_target" ]; then
  echo "Refusing to replace existing non-symlink skill: $skill_target" >&2
  exit 1
fi

if [ -L "$skill_target" ]; then
  current_target=$(readlink "$skill_target")
  if [ "$current_target" != "$skill_source" ]; then
    echo "Refusing to replace skill symlink pointing elsewhere: $skill_target -> $current_target" >&2
    exit 1
  fi
else
  ln -s "$skill_source" "$skill_target"
fi

for source in "$repo_dir"/agents/*.toml; do
  install -m 0644 "$source" "$agent_target/$(basename -- "$source")"
done

if [ ! -e "$config_file" ]; then
  : > "$config_file"
fi

if ! grep -Eq '^\[agents\][[:space:]]*$' "$config_file"; then
  printf '\n[agents]\nmax_threads = 4\nmax_depth = 1\n' >> "$config_file"
else
  echo "Existing [agents] configuration left unchanged in $config_file"
fi

echo "Installed start-task skill: $skill_target"
echo "Installed custom agents: $agent_target"
echo "Invoke with: \$start-task <feature request>"
echo "Restart Codex if the skill does not appear immediately."
