#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
agent_target="$HOME/.codex/agents"
config_file="$HOME/.codex/config.toml"
backup_root="$HOME/.codex/skill-backups"

configure_agents() {
  config=$1
  temporary_config="$config.tmp.$$"

  trap 'rm -f "$temporary_config"' EXIT HUP INT TERM
  cp "$config" "$temporary_config"
  if ! awk '
    function add_missing_settings() {
      if (!found_threads) {
        print "max_threads = 4"
      }
      if (!found_depth) {
        print "max_depth = 2"
      }
    }

    function is_table(line) {
      return line ~ /^[[:space:]]*\[[^]]+\][[:space:]]*(#.*)?$/
    }

    function is_agents_table(line) {
      return line ~ /^[[:space:]]*\[agents\][[:space:]]*(#.*)?$/
    }

    BEGIN {
      in_agents = 0
      found_agents = 0
      found_threads = 0
      found_depth = 0
      invalid = 0
    }

    {
      if (is_table($0)) {
        if (in_agents) {
          add_missing_settings()
          in_agents = 0
        }

        if (is_agents_table($0)) {
          found_agents = 1
          found_threads = 0
          found_depth = 0
          in_agents = 1
        }
      }

      if (in_agents && $0 ~ /^[[:space:]]*max_threads[[:space:]]*=/) {
        found_threads = 1
      }

      if (in_agents && $0 ~ /^[[:space:]]*max_depth[[:space:]]*=/) {
        found_depth = 1
        if ($0 !~ /^[[:space:]]*max_depth[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*(#.*)?$/) {
          print "Unsupported agents.max_depth value in " FILENAME > "/dev/stderr"
          invalid = 1
        } else {
          value = $0
          sub(/^[^=]*=[[:space:]]*/, "", value)
          if ((value + 0) < 2) {
            match($0, /[0-9]+/)
            $0 = substr($0, 1, RSTART - 1) "2" substr($0, RSTART + RLENGTH)
          }
        }
      }

      print
    }

    END {
      if (in_agents) {
        add_missing_settings()
      } else if (!found_agents) {
        print ""
        print "[agents]"
        print "max_threads = 4"
        print "max_depth = 2"
      }

      if (invalid) {
        exit 1
      }
    }
  ' "$config" >"$temporary_config"; then
    return 1
  fi

  mv "$temporary_config" "$config"
  trap - EXIT HUP INT TERM
}

link_skill() {
  source=$1
  target_parent=$2
  name=$(basename -- "$source")
  target="$target_parent/$name"

  [ -f "$source/SKILL.md" ] || return 0
  mkdir -p "$target_parent"

  if [ -L "$target" ]; then
    current_target=$(readlink "$target")
    if [ "$current_target" != "$source" ]; then
      if [ ! -e "$target" ]; then
        rm "$target"
        ln -s "$source" "$target"
        echo "Replaced broken skill symlink: $target -> $source"
        return 0
      fi
      echo "Refusing to replace skill symlink pointing elsewhere: $target -> $current_target" >&2
      exit 1
    fi
    return 0
  fi

  if [ -e "$target" ]; then
    if [ ! -d "$target" ] || ! diff -qr "$source" "$target" >/dev/null 2>&1; then
      echo "Refusing to replace different existing skill: $target" >&2
      exit 1
    fi

    mkdir -p "$backup_root"
    backup="$backup_root/$name"
    if [ -e "$backup" ] || [ -L "$backup" ]; then
      echo "Refusing to overwrite existing migration backup: $backup" >&2
      exit 1
    fi
    mv "$target" "$backup"
    echo "Moved matching existing skill to migration backup: $backup"
  fi

  ln -s "$source" "$target"
  echo "Linked skill: $target -> $source"
}

install_skill_tree() {
  source_parent=$1
  target_parent=$2

  [ -d "$source_parent" ] || return 0
  for source in "$source_parent"/*; do
    [ -d "$source" ] || continue
    link_skill "$source" "$target_parent"
  done
}

# Codex-only skills live under codex/ and are discovered from ~/.codex/skills.
install_skill_tree "$repo_dir/codex" "$HOME/.codex/skills"

# Future portable agent skills may live under generic/.
install_skill_tree "$repo_dir/generic" "$HOME/.agents/skills"

mkdir -p "$agent_target" "$(dirname -- "$config_file")"
for source in "$repo_dir"/agents/*.toml; do
  [ -f "$source" ] || continue
  install -m 0644 "$source" "$agent_target/$(basename -- "$source")"
done

if [ ! -e "$config_file" ]; then
  : >"$config_file"
fi

configure_agents "$config_file"

legacy_start_task="$HOME/.agents/skills/start-task"
if [ -L "$legacy_start_task" ] && [ ! -e "$legacy_start_task" ]; then
  rm "$legacy_start_task"
  echo "Removed broken legacy skill symlink: $legacy_start_task"
fi

echo "Installed Codex skills from: $repo_dir/codex"
echo "Installed custom agents into: $agent_target"
echo "Invoke the feature workflow with: \$start-task <feature request>"
echo "Restart Codex if updated skills do not appear immediately."
