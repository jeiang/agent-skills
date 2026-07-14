#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
agent_target="$HOME/.codex/agents"
config_file="$HOME/.codex/config.toml"
backup_root="$HOME/.codex/skill-backups"
legacy_start_task="$HOME/.agents/skills/start-task"

create_workspace() {
  temporary_root=${TMPDIR:-/tmp}
  case "$temporary_root/" in
    "$HOME"/*) temporary_root=/tmp ;;
  esac

  saved_umask=$(umask)
  umask 077
  workspace=$(mktemp -d "$temporary_root/agent-skills-install.XXXXXX")
  chmod 0700 "$workspace"
  lock_key=$(printf '%s' "$HOME" | cksum | awk '{ print $1 "-" $2 }')
  lock_dir="$temporary_root/agent-skills-install-lock.$lock_key"
  if ! mkdir -m 0700 "$lock_dir" 2>/dev/null; then
    rm -rf "$workspace"
    umask "$saved_umask"
    echo "Refusing concurrent agent-skills installation for HOME=$HOME. Wait for the cooperating installer to finish." >&2
    exit 1
  fi
  umask "$saved_umask"
  trap 'rm -rf "$workspace"; rmdir "$lock_dir" 2>/dev/null || :' EXIT HUP INT TERM

  manifest="$workspace/manifest"
  mkdir "$manifest" "$workspace/reserved-backups" "$workspace/frozen-agents"
  action_count=0
}

snapshot_path() {
  label=$1
  path=$2
  archive="$workspace/state.tar"

  printf '%s\t%s\t' "$label" "$path"
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    echo MISSING
    return 0
  fi
  parent=$(dirname -- "$path")
  name=$(basename -- "$path")
  rm -f "$archive"
  if ! tar -cf "$archive" -C "$parent" "$name" 2>/dev/null; then
    echo "Unable to fingerprint installer state: $path" >&2
    return 1
  fi
  cksum "$archive"
}

snapshot_relevant_state() {
  output=$1
  {
    snapshot_path source_codex "$repo_dir/codex"
    snapshot_path source_generic "$repo_dir/generic"
    snapshot_path source_agents "$repo_dir/agents"
    snapshot_path codex_skills "$HOME/.codex/skills"
    snapshot_path generic_skills "$HOME/.agents/skills"
    snapshot_path backups "$backup_root"
    snapshot_path agents "$agent_target"
    snapshot_path config "$config_file"
  } >"$output"
}

require_creatable_parent() {
  target=$1
  parent=$(dirname -- "$target")
  while [ ! -e "$parent" ] && [ ! -L "$parent" ]; do
    next_parent=$(dirname -- "$parent")
    [ "$next_parent" != "$parent" ] || break
    parent=$next_parent
  done
  if [ ! -d "$parent" ]; then
    echo "Refusing installer target with a non-directory ancestor: $target" >&2
    return 1
  fi
}

add_action() {
  action_count=$((action_count + 1))
  record=$(printf '%s/%06d' "$manifest" "$action_count")
  mkdir "$record"
  printf '%s' "$1" >"$record/type"
  printf '%s' "${2-}" >"$record/source"
  printf '%s' "${3-}" >"$record/target"
  printf '%s' "${4-}" >"$record/extra"
}

refuse_symlinked_config() {
  if [ ! -L "$config_file" ]; then
    return 0
  fi

  if link_target=$(readlink "$config_file" 2>/dev/null); then
    :
  else
    link_target='<unreadable link target>'
  fi
  echo "Refusing symlinked Codex config: $config_file -> $link_target. Replace the link with a regular config file before installing." >&2
  exit 1
}

refuse_multiline_toml_strings() {
  config=$1

  if ! awk '
    function refuse(reason) {
      print "Refusing unsupported TOML string syntax in " FILENAME ":" FNR ": " reason ". Use closed single-line basic or literal strings before installing." > "/dev/stderr"
      exit 1
    }

    {
      state = "structural"
      escaped = 0

      for (position = 1; position <= length($0); position++) {
        character = substr($0, position, 1)

        if (state == "structural") {
          if (character == "#") {
            break
          }
          if (character == "\"") {
            if (substr($0, position, 3) == "\"\"\"") {
              refuse("multiline basic string delimiters are not supported")
            }
            state = "basic"
          } else if (character == single_quote) {
            if (substr($0, position, 3) == single_quote single_quote single_quote) {
              refuse("multiline literal string delimiters are not supported")
            }
            state = "literal"
          }
        } else if (state == "basic") {
          if (escaped) {
            escaped = 0
          } else if (character == "\\") {
            escaped = 1
          } else if (character == "\"") {
            state = "structural"
          }
        } else if (character == single_quote) {
          state = "structural"
        }
      }

      if (state == "basic") {
        refuse("unterminated ordinary basic string")
      }
      if (state == "literal") {
        refuse("unterminated ordinary literal string")
      }
    }

    BEGIN {
      single_quote = sprintf("%c", 39)
    }
  ' "$config"; then
    return 1
  fi
}

render_agents_config() {
  input=$1
  output=$2

  refuse_multiline_toml_strings "$input" || return 1

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
  ' "$input" >"$output"; then
    return 1
  fi
}

plan_skill() {
  source=$1
  target_parent=$2
  name=$(basename -- "$source")
  target="$target_parent/$name"
  backup="$backup_root/$name"

  [ -f "$source/SKILL.md" ] || return 0
  require_creatable_parent "$target"

  if [ -L "$target" ]; then
    current_target=$(readlink "$target")
    if [ "$current_target" != "$source" ]; then
      if [ ! -e "$target" ]; then
        add_action replace_link "$source" "$target"
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

    if [ -e "$backup" ] || [ -L "$backup" ]; then
      echo "Refusing to overwrite existing migration backup: $backup" >&2
      exit 1
    fi
    require_creatable_parent "$backup"
    reservation="$workspace/reserved-backups/$name"
    if ! mkdir "$reservation" 2>/dev/null; then
      echo "Refusing multiple migrations to shared backup name: $name" >&2
      exit 1
    fi
    add_action migrate_skill "$source" "$target" "$backup"
    return 0
  fi

  add_action link_skill "$source" "$target"
}

plan_skill_tree() {
  source_parent=$1
  target_parent=$2

  [ -d "$source_parent" ] || return 0
  for source in "$source_parent"/*; do
    [ -d "$source" ] || continue
    plan_skill "$source" "$target_parent"
  done
}

plan_agents() {
  require_creatable_parent "$agent_target/placeholder"
  for source in "$repo_dir"/agents/*.toml; do
    [ -f "$source" ] || continue
    name=$(basename -- "$source")
    frozen="$workspace/frozen-agents/$name"
    cp -p "$source" "$frozen"
    target="$agent_target/$name"
    if [ -d "$target" ] && [ ! -L "$target" ]; then
      echo "Refusing agent destination that is a directory: $target" >&2
      exit 1
    fi
    if [ -f "$target" ] && [ ! -L "$target" ] && cmp -s "$frozen" "$target"; then
      continue
    fi
    add_action install_agent "$frozen" "$target"
  done
}

plan_config() {
  refuse_symlinked_config
  require_creatable_parent "$config_file"
  input="$config_file"
  if [ ! -e "$config_file" ]; then
    input="$workspace/empty-config"
    : >"$input"
  elif [ ! -f "$config_file" ]; then
    echo "Refusing non-regular Codex config: $config_file" >&2
    exit 1
  fi

  rendered="$workspace/rendered-config"
  cp -p "$input" "$rendered"
  render_agents_config "$input" "$rendered"
  if [ ! -e "$config_file" ] || ! cmp -s "$rendered" "$config_file"; then
    add_action write_config "$rendered" "$config_file"
  fi
}

plan_legacy_cleanup() {
  if [ -L "$legacy_start_task" ] && [ ! -e "$legacy_start_task" ]; then
    if [ -d "$repo_dir/generic/start-task" ] && [ -f "$repo_dir/generic/start-task/SKILL.md" ]; then
      return 0
    fi
    add_action remove_legacy '' "$legacy_start_task"
  fi
}

execute_manifest() {
  for record in "$manifest"/*; do
    [ -d "$record" ] || continue
    action=$(cat "$record/type")
    source=$(cat "$record/source")
    target=$(cat "$record/target")
    extra=$(cat "$record/extra")
    mkdir -p "$(dirname -- "$target")"
    case "$action" in
      link_skill)
        ln -s "$source" "$target"
        echo "Linked skill: $target -> $source"
        ;;
      replace_link)
        rm "$target"
        ln -s "$source" "$target"
        echo "Replaced broken skill symlink: $target -> $source"
        ;;
      migrate_skill)
        mkdir -p "$(dirname -- "$extra")"
        mv "$target" "$extra"
        ln -s "$source" "$target"
        echo "Moved matching existing skill to migration backup: $extra"
        ;;
      install_agent)
        rm -f "$target"
        install -m 0644 "$source" "$target"
        ;;
      write_config)
        temporary_config="$target.tmp.$$"
        cp -p "$source" "$temporary_config"
        mv "$temporary_config" "$target"
        ;;
      remove_legacy)
        rm "$target"
        echo "Removed broken legacy skill symlink: $target"
        ;;
      *)
        echo "Invalid frozen installer action: $action" >&2
        exit 1
        ;;
    esac
  done
}

create_workspace
snapshot_relevant_state "$workspace/initial-state"

# Codex-only skills live under codex/ and are discovered from ~/.codex/skills.
plan_skill_tree "$repo_dir/codex" "$HOME/.codex/skills"

# Future portable agent skills may live under generic/.
plan_skill_tree "$repo_dir/generic" "$HOME/.agents/skills"
plan_agents
plan_config
plan_legacy_cleanup

snapshot_relevant_state "$workspace/checkpoint-state"
if ! cmp -s "$workspace/initial-state" "$workspace/checkpoint-state"; then
  echo "Refusing installation because relevant source or HOME state changed during preflight. Retry after concurrent changes stop." >&2
  exit 1
fi

execute_manifest

echo "Installed Codex skills from: $repo_dir/codex"
echo "Installed custom agents into: $agent_target"
echo "Invoke the feature workflow with: \$start-task <feature request>"
echo "Restart Codex if updated skills do not appear immediately."
