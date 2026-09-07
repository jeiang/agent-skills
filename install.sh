#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 codex|claude|copilot [--home DIR] [--replace-instructions]" >&2
  exit 2
}

[ "$#" -gt 0 ] || usage
agent=$1
shift
home_dir=$HOME
home_override=false
replace_instructions=false
while [ "$#" -gt 0 ]; do
  case $1 in
    --home)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage
      home_dir=$2
      home_override=true
      shift 2
      ;;
    --replace-instructions)
      replace_instructions=true
      shift
      ;;
    *) usage ;;
  esac
done

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
case $agent in
  codex)
    agent_root="$home_dir/.codex"
    if [ "$home_override" = false ] && [ -n "${CODEX_HOME:-}" ]; then
      agent_root=$CODEX_HOME
    fi
    profile=personal
    instruction_file="$agent_root/AGENTS.md"
    agent_source="$repo_dir/agents"
    ;;
  claude)
    agent_root="$home_dir/.claude"
    profile=personal
    instruction_file="$agent_root/CLAUDE.md"
    agent_source="$repo_dir/claude-agents"
    ;;
  copilot)
    agent_root="$home_dir/.copilot"
    profile=work
    instruction_file="$agent_root/instructions/agent-skills.instructions.md"
    agent_source=
    ;;
  *) usage ;;
esac

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
marker='<!-- Managed by agent-skills; rerun the installer to update. -->'
{
  if [ "$agent" = copilot ]; then
    printf '%s\n' '---' 'applyTo: "**"' '---'
  fi
  printf '%s\n\n' "$marker"
  cat "$repo_dir/instructions/common.md"
  printf '\n'
  cat "$repo_dir/instructions/$profile.md"
} >"$scratch/instructions"

# Check the instruction destination before changing any installation links.
if [ -e "$instruction_file" ] || [ -L "$instruction_file" ]; then
  [ -f "$instruction_file" ] || {
    echo "Refusing non-file instructions: $instruction_file" >&2
    exit 1
  }
  if [ "$replace_instructions" = false ]; then
    if [ -L "$instruction_file" ] || ! grep -Fqx "$marker" "$instruction_file"; then
      echo "Refusing unmanaged instructions: $instruction_file. Use --replace-instructions to back up and replace them." >&2
      exit 1
    fi
  fi
fi

remove_owned_link() {
  retired=$1
  [ -e "$retired" ] || [ -L "$retired" ] || return 0
  if [ -L "$retired" ]; then
    case $(readlink "$retired") in
      "$repo_dir"/*)
        rm "$retired"
        echo "Removed retired link: $retired"
        return 0
        ;;
    esac
  fi
  echo "Refusing unmanaged retired entry: $retired. Review and remove it manually." >&2
  exit 1
}

link_path() {
  source_path=$1
  target_path=$2
  if [ -L "$target_path" ]; then
    existing_link=$(readlink "$target_path")
    [ "$existing_link" = "$source_path" ] && return 0
    case $existing_link in
      "$repo_dir"/*) rm "$target_path" ;;
      *)
        echo "Refusing conflicting symlink: $target_path" >&2
        exit 1
        ;;
    esac
  fi
  if [ -e "$target_path" ]; then
    if [ -d "$source_path" ] && [ -d "$target_path" ] && diff -qr "$source_path" "$target_path" >/dev/null 2>&1; then
      mkdir -p "$agent_root/backups"
      backup_dir=$(mktemp -d "$agent_root/backups/skill.XXXXXX")
      mv "$target_path" "$backup_dir/original"
      echo "Backed up copied skill: $backup_dir/original"
    elif [ -f "$source_path" ] && [ -f "$target_path" ] && cmp -s "$source_path" "$target_path"; then
      rm "$target_path"
    else
      echo "Refusing conflicting destination: $target_path" >&2
      exit 1
    fi
  fi
  ln -s "$source_path" "$target_path"
  echo "Linked: $target_path -> $source_path"
}

mkdir -p "$agent_root/skills"
remove_owned_link "$agent_root/skills/start-task"
remove_owned_link "$agent_root/skills/start-feature"
if [ "$profile" = work ]; then
  while IFS= read -r personal_skill; do
    [ -n "$personal_skill" ] || continue
    remove_owned_link "$agent_root/skills/$personal_skill"
  done <"$repo_dir/instructions/personal-skills.txt"
fi

for source_root in "$repo_dir/shared" "$repo_dir/generic" "$repo_dir/$agent"; do
  [ -d "$source_root" ] || continue
  for source_path in "$source_root"/*; do
    [ -f "$source_path/SKILL.md" ] || continue
    skill_name=$(basename -- "$source_path")
    if [ "$profile" = work ] && grep -Fxq "$skill_name" "$repo_dir/instructions/personal-skills.txt"; then
      continue
    fi
    link_path "$source_path" "$agent_root/skills/$skill_name"
  done
done

if [ -n "$agent_source" ]; then
  mkdir -p "$agent_root/agents"
  if [ "$agent" = codex ]; then
    for retired_name in task-orchestrator.toml prompt-validator.toml agents-md-author.toml; do
      remove_owned_link "$agent_root/agents/$retired_name"
    done
  fi
  for source_path in "$agent_source"/*; do
    [ -f "$source_path" ] || continue
    link_path "$source_path" "$agent_root/agents/$(basename -- "$source_path")"
  done
fi

mkdir -p "$(dirname -- "$instruction_file")"
if [ -L "$instruction_file" ] || ! cmp -s "$scratch/instructions" "$instruction_file"; then
  if [ -e "$instruction_file" ] || [ -L "$instruction_file" ]; then
    backup_file=$(mktemp "$instruction_file.bak.XXXXXX")
    rm "$backup_file"
    cp -Pp "$instruction_file" "$backup_file"
    rm "$instruction_file"
    echo "Backed up instructions: $backup_file"
  fi
  install -m 0600 "$scratch/instructions" "$instruction_file"
fi

echo "Installed $agent with common + $profile instructions: $instruction_file"
echo "Restart the agent or open a new chat to reload instructions."
