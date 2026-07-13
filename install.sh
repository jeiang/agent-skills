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
    function reject_agents_form(reason) {
      print "Unsupported agents configuration in " FILENAME ": " reason ". Use a top-level bare [agents] table with direct bare max_threads and max_depth integer keys." > "/dev/stderr"
      invalid = 1
    }

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

    function is_array_table(line) {
      return line ~ /^[[:space:]]*\[\[/
    }

    function first_table_key_is_agents(line, body) {
      body = line
      sub(/^[[:space:]]*\[\[?[[:space:]]*/, "", body)
      return body ~ /^agents[[:space:]]*(\.|\])/ || index(body, "\"agents\"") == 1 || index(body, single_quote "agents" single_quote) == 1
    }

    function root_key_is_agents(line, body) {
      body = line
      sub(/^[[:space:]]*/, "", body)
      return body ~ /^agents[[:space:]]*(\.|=)/ || index(body, "\"agents\"") == 1 || index(body, single_quote "agents" single_quote) == 1
    }

    function is_noncanonical_limit_key(line, body) {
      body = line
      sub(/^[[:space:]]*/, "", body)
      return body ~ /^(max_threads|max_depth)[[:space:]]*\./ || index(body, "\"max_threads\"") == 1 || index(body, "\"max_depth\"") == 1 || index(body, single_quote "max_threads" single_quote) == 1 || index(body, single_quote "max_depth" single_quote) == 1
    }

    BEGIN {
      single_quote = sprintf("%c", 39)
      at_root = 1
      in_agents = 0
      found_agents = 0
      found_threads = 0
      found_depth = 0
      invalid = 0
    }

    {
      if (is_array_table($0)) {
        if (first_table_key_is_agents($0)) {
          reject_agents_form("array-of-tables form for agents is not supported")
        }
        at_root = 0
      } else if (is_table($0)) {
        if (first_table_key_is_agents($0) && !is_agents_table($0)) {
          if ($0 ~ /^[[:space:]]*\[[[:space:]]*agents[[:space:]]*\./ && found_agents) {
            # A bare nested table after canonical [agents] is safe to preserve.
          } else {
            reject_agents_form("agents must be declared first as a top-level bare [agents] table")
          }
        }

        at_root = 0
      } else if (at_root && root_key_is_agents($0)) {
        reject_agents_form("dotted, quoted, or inline root agents keys are not supported")
      }

      if (is_table($0)) {
        if (in_agents) {
          add_missing_settings()
          in_agents = 0
        }

        if (is_agents_table($0)) {
          if (found_agents) {
            reject_agents_form("duplicate [agents] table")
          }
          found_agents = 1
          found_threads = 0
          found_depth = 0
          in_agents = 1
        }
      }

      if (in_agents && is_noncanonical_limit_key($0)) {
        reject_agents_form("max_threads and max_depth must be direct bare keys")
      }

      if (in_agents && $0 ~ /^[[:space:]]*max_threads[[:space:]]*=/) {
        if (found_threads) {
          reject_agents_form("duplicate max_threads definition")
        }
        found_threads = 1
        if ($0 !~ /^[[:space:]]*max_threads[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*(#.*)?$/) {
          print "Unsupported agents.max_threads value in " FILENAME > "/dev/stderr"
          invalid = 1
        } else {
          value = $0
          sub(/^[^=]*=[[:space:]]*/, "", value)
          if ((value + 0) < 4) {
            match($0, /[0-9]+/)
            $0 = substr($0, 1, RSTART - 1) "4" substr($0, RSTART + RLENGTH)
          }
        }
      }

      if (in_agents && $0 ~ /^[[:space:]]*max_depth[[:space:]]*=/) {
        if (found_depth) {
          reject_agents_form("duplicate max_depth definition")
        }
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
