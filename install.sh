#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
agent_target="$HOME/.codex/agents"
config_file="$HOME/.codex/config.toml"
backup_root="$HOME/.codex/skill-backups"
legacy_start_task="$HOME/.agents/skills/start-task"

workspace=''
lock_dir=''
workspace_owned=0
lock_owned=0
resource_transition=0
pending_signal=0
cleanup_active=0
cleanup_status=0

handle_termination() {
  signal_status=$1
  if [ "$cleanup_active" -eq 1 ]; then
    return 0
  fi
  if [ "$resource_transition" -eq 1 ]; then
    if [ "$pending_signal" -eq 0 ]; then
      pending_signal=$signal_status
    fi
    return 0
  fi
  exit "$signal_status"
}

finish_resource_transition() {
  resource_transition=0
  if [ "$pending_signal" -ne 0 ]; then
    signal_status=$pending_signal
    pending_signal=0
    exit "$signal_status"
  fi
}

cleanup_workspace() {
  initiating_status=$?
  if [ "$cleanup_active" -eq 1 ]; then
    return 0
  fi
  cleanup_active=1
  cleanup_status=$initiating_status
  trap - EXIT
  trap '' HUP INT TERM
  if [ "$workspace_owned" -eq 1 ]; then
    if ! rm -rf "$workspace"; then
      echo "Warning: unable to remove installer workspace: $workspace" >&2
    fi
    workspace_owned=0
  fi
  if [ "$lock_owned" -eq 1 ]; then
    if ! rmdir "$lock_dir" 2>/dev/null; then
      echo "Warning: unable to remove installer lock: $lock_dir" >&2
    fi
    lock_owned=0
  fi
  exit "$cleanup_status"
}

trap cleanup_workspace EXIT
trap 'handle_termination 129' HUP
trap 'handle_termination 130' INT
trap 'handle_termination 143' TERM

create_workspace() {
  temporary_root=${TMPDIR:-/tmp}
  case "$temporary_root/" in
    "$HOME"/*) temporary_root=/tmp ;;
  esac

  saved_umask=$(umask)
  umask 077
  resource_transition=1
  if ! workspace=$(mktemp -d "$temporary_root/agent-skills-install.XXXXXX"); then
    umask "$saved_umask"
    finish_resource_transition
    echo "Unable to create installer workspace in: $temporary_root" >&2
    exit 1
  fi
  workspace_owned=1
  finish_resource_transition
  chmod 0700 "$workspace"
  lock_key=$(printf '%s' "$HOME" | cksum | awk '{ print $1 "-" $2 }')
  lock_dir="$temporary_root/agent-skills-install-lock.$lock_key"
  resource_transition=1
  if ! mkdir -m 0700 "$lock_dir" 2>/dev/null; then
    umask "$saved_umask"
    finish_resource_transition
    echo "Refusing concurrent agent-skills installation for HOME=$HOME. Wait for the cooperating installer to finish." >&2
    exit 1
  fi
  lock_owned=1
  finish_resource_transition
  umask "$saved_umask"

  manifest="$workspace/manifest"
  mkdir "$manifest" "$workspace/reserved-backups" "$workspace/frozen-agents"
  planned_directories="$workspace/planned-directories"
  : >"$planned_directories"
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

add_action() {
  action_count=$((action_count + 1))
  record=$(printf '%s/%06d' "$manifest" "$action_count")
  mkdir "$record"
  printf '%s' "$1" >"$record/type"
  printf '%s' "${2-}" >"$record/source"
  printf '%s' "${3-}" >"$record/target"
  printf '%s' "${4-}" >"$record/extra"
  printf '%s' "${5-}" >"$record/mode"
}

regular_file_mode() {
  mode_path=$1
  case $(uname -s) in
    Darwin) mode_value=$(/usr/bin/stat -f '%Lp' "$mode_path" 2>/dev/null) || mode_value='' ;;
    *) mode_value=$(stat -c '%a' "$mode_path" 2>/dev/null) || mode_value='' ;;
  esac
  case "$mode_value" in
    '' | *[!0-7]*)
      echo "Unsupported POSIX mode for Codex config: $mode_path" >&2
      return 1
      ;;
  esac
  printf '%s\n' "$mode_value"
}

refuse_blocking_config_metadata() {
  metadata_path=$1

  bsd_flags=''
  if [ "$(uname -s)" = Darwin ]; then
    bsd_flags=$(/usr/bin/stat -f '%Sf' "$metadata_path" 2>/dev/null) || bsd_flags=''
  fi
  if [ -n "$bsd_flags" ]; then
    case ",$bsd_flags," in
      *,uchg,* | *,schg,* | *,uappnd,* | *,sappnd,*)
        echo "Refusing immutable or append-only Codex config: $metadata_path. Remove the blocking file flag before installing." >&2
        return 1
        ;;
    esac
  fi

  if command -v lsattr >/dev/null 2>&1; then
    linux_attributes=$(lsattr -d -- "$metadata_path" 2>/dev/null | awk 'NR == 1 { print $1 }') || linux_attributes=''
    case "$linux_attributes" in
      *i* | *a*)
        echo "Refusing immutable or append-only Codex config: $metadata_path. Remove the blocking file attribute before installing." >&2
        return 1
        ;;
    esac
  fi
}

require_real_directory_ancestry() {
  ancestry_path=$1
  ancestry_operation=$2

  case "$ancestry_path" in
    /*) ;;
    *)
      echo "Cannot $ancestry_operation: destination path is not absolute: $ancestry_path" >&2
      return 1
      ;;
  esac

  ancestry_remaining=${ancestry_path#/}
  ancestry_current=''
  ancestry_missing=0
  while [ -n "$ancestry_remaining" ]; do
    ancestry_component=${ancestry_remaining%%/*}
    if [ "$ancestry_remaining" = "$ancestry_component" ]; then
      ancestry_remaining=''
    else
      ancestry_remaining=${ancestry_remaining#*/}
    fi
    [ -n "$ancestry_component" ] || continue
    case "$ancestry_component" in
      . | ..)
        echo "Cannot $ancestry_operation: destination path contains a non-literal component: $ancestry_path" >&2
        return 1
        ;;
    esac

    ancestry_current="$ancestry_current/$ancestry_component"
    if [ "$ancestry_missing" -eq 0 ] && [ -L "$ancestry_current" ]; then
      echo "Refusing installer destination ancestry symlink: $ancestry_current. Replace it with a real directory." >&2
      return 1
    fi
    if [ "$ancestry_missing" -eq 0 ] && [ -e "$ancestry_current" ]; then
      if [ ! -d "$ancestry_current" ]; then
        echo "Refusing installer destination with a non-directory ancestor: $ancestry_current" >&2
        return 1
      fi
    else
      ancestry_missing=1
    fi
  done
}

plan_directory() {
  require_real_directory_ancestry "$1" "plan directory $1" || exit 1
  if [ -L "$1" ]; then
    echo "Refusing installer destination ancestry symlink: $1. Replace it with a real directory." >&2
    exit 1
  fi
  if [ -e "$1" ]; then
    if [ ! -d "$1" ]; then
      echo "Refusing installer destination with a non-directory ancestor: $1" >&2
      exit 1
    fi
    return 0
  fi
  if grep -Fqx "$1" "$planned_directories"; then
    return 0
  fi
  parent=$(dirname -- "$1")
  if [ "$parent" = "$1" ]; then
    echo "Unable to find an existing real directory ancestor for: $1" >&2
    exit 1
  fi
  plan_directory "$parent"
  if ! grep -Fqx "$1" "$planned_directories"; then
    add_action mkdir '' "$1"
    printf '%s\n' "$1" >>"$planned_directories"
  fi
}

nearest_existing_directory() {
  ancestor_candidate=$1
  require_real_directory_ancestry "$ancestor_candidate" "inspect destination ancestry $ancestor_candidate" || return 1
  while [ ! -e "$ancestor_candidate" ] && [ ! -L "$ancestor_candidate" ]; do
    ancestor_parent=$(dirname -- "$ancestor_candidate")
    [ "$ancestor_parent" != "$ancestor_candidate" ] || break
    ancestor_candidate=$ancestor_parent
  done
  if [ -L "$ancestor_candidate" ]; then
    echo "Refusing installer destination ancestry symlink: $ancestor_candidate. Replace it with a real directory." >&2
    return 1
  fi
  if [ ! -d "$ancestor_candidate" ]; then
    echo "Refusing installer destination with a non-directory ancestor: $ancestor_candidate" >&2
    return 1
  fi
  printf '%s\n' "$ancestor_candidate"
}

require_searchable_ancestry() {
  ancestry_candidate=$(nearest_existing_directory "$1") || return 1
  while :; do
    if [ ! -x "$ancestry_candidate" ]; then
      echo "Cannot $2: destination ancestry is not searchable: $ancestry_candidate" >&2
      return 1
    fi
    ancestry_parent=$(dirname -- "$ancestry_candidate")
    [ "$ancestry_parent" != "$ancestry_candidate" ] || break
    ancestry_candidate=$ancestry_parent
  done
}

require_mutable_parent() {
  mutation_parent=$(dirname -- "$1")
  require_searchable_ancestry "$mutation_parent" "$2" || return 1
  existing_mutation_parent=$(nearest_existing_directory "$mutation_parent") || return 1
  if [ ! -w "$existing_mutation_parent" ] || [ ! -x "$existing_mutation_parent" ]; then
    echo "Cannot $2: nearest existing destination parent requires write and search access: $existing_mutation_parent" >&2
    return 1
  fi
}

require_readable_source() {
  source=$1
  operation=$2
  if [ -d "$source" ] && [ ! -L "$source" ]; then
    if ! tar -cf "$workspace/readability.tar" -C "$(dirname -- "$source")" "$(basename -- "$source")" 2>/dev/null; then
      echo "Cannot $operation: source tree is not fully readable and searchable: $source" >&2
      return 1
    fi
    rm -f "$workspace/readability.tar"
  elif [ ! -f "$source" ] || [ ! -r "$source" ]; then
    echo "Cannot $operation: source file is not readable: $source" >&2
    return 1
  fi
}

filesystem_id() {
  df -P "$1" 2>/dev/null | awk 'NR == 2 { print $1 }'
}

validate_manifest_feasibility() {
  for record in "$manifest"/*; do
    [ -d "$record" ] || continue
    action=$(cat "$record/type")
    source=$(cat "$record/source")
    target=$(cat "$record/target")
    extra=$(cat "$record/extra")
    mode=$(cat "$record/mode")
    case "$action" in
      mkdir)
        [ ! -e "$target" ] && [ ! -L "$target" ] || {
          echo "Cannot create planned directory because the destination now exists: $target" >&2
          return 1
        }
        require_mutable_parent "$target" "create directory $target" || return 1
        ;;
      link_skill)
        require_readable_source "$source" "link skill $target" || return 1
        require_mutable_parent "$target" "link skill $target" || return 1
        ;;
      replace_link)
        require_readable_source "$source" "replace skill link $target" || return 1
        require_mutable_parent "$target" "replace skill link $target" || return 1
        ;;
      migrate_skill)
        require_readable_source "$source" "migrate skill $target" || return 1
        require_mutable_parent "$target" "remove migration source $target" || return 1
        require_mutable_parent "$extra" "create migration backup $extra" || return 1
        destination_parent=$(nearest_existing_directory "$(dirname -- "$extra")") || return 1
        source_filesystem=$(filesystem_id "$target")
        destination_filesystem=$(filesystem_id "$destination_parent")
        if [ -z "$source_filesystem" ] || [ "$source_filesystem" != "$destination_filesystem" ]; then
          echo "Cannot migrate skill atomically across filesystems: $target -> $extra" >&2
          return 1
        fi
        ;;
      install_agent)
        require_readable_source "$source" "install agent $target" || return 1
        require_mutable_parent "$target" "install agent $target" || return 1
        ;;
      write_config)
        require_readable_source "$source" "write Codex config $target" || return 1
        if [ "$(dirname -- "$target")" != "$(dirname -- "$extra")" ]; then
          echo "Cannot write Codex config: frozen temporary file is not a sibling of $target" >&2
          return 1
        fi
        if [ -e "$extra" ] || [ -L "$extra" ]; then
          echo "Cannot write Codex config: frozen temporary path already exists: $extra" >&2
          return 1
        fi
        require_mutable_parent "$extra" "create temporary Codex config $extra" || return 1
        case "$mode" in
          '' | *[!0-7]*)
            echo "Cannot write Codex config: invalid frozen POSIX mode: $mode" >&2
            return 1
            ;;
        esac
        ;;
      remove_legacy)
        require_mutable_parent "$target" "remove legacy link $target" || return 1
        ;;
      *)
        echo "Invalid frozen installer action during feasibility validation: $action" >&2
        return 1
        ;;
    esac
  done
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
  plan_directory "$target_parent"

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
    plan_directory "$backup_root"
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
  plan_directory "$agent_target"
  for source in "$repo_dir"/agents/*.toml; do
    [ -f "$source" ] || continue
    name=$(basename -- "$source")
    frozen="$workspace/frozen-agents/$name"
    if ! dd if="$source" of="$frozen" bs=65536 2>/dev/null; then
      echo "Unable to freeze agent configuration: $source" >&2
      exit 1
    fi
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
  plan_directory "$(dirname -- "$config_file")"
  input="$config_file"
  if [ ! -e "$config_file" ]; then
    input="$workspace/empty-config"
    : >"$input"
  elif [ ! -f "$config_file" ]; then
    echo "Refusing non-regular Codex config: $config_file" >&2
    exit 1
  fi

  rendered="$workspace/rendered-config"
  render_agents_config "$input" "$rendered"
  if [ ! -e "$config_file" ] || ! cmp -s "$rendered" "$config_file"; then
    if [ -e "$config_file" ]; then
      refuse_blocking_config_metadata "$config_file" || exit 1
      config_mode=$(regular_file_mode "$config_file") || exit 1
    else
      config_mode=0600
    fi
    temporary_config="$config_file.agent-skills-install.tmp"
    if [ -e "$temporary_config" ] || [ -L "$temporary_config" ]; then
      echo "Refusing existing Codex config temporary path: $temporary_config. Remove it before installing." >&2
      exit 1
    fi
    add_action write_config "$rendered" "$config_file" "$temporary_config" "$config_mode"
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
    mode=$(cat "$record/mode")
    case "$action" in
      mkdir)
        mkdir "$target"
        ;;
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
        mv "$target" "$extra"
        ln -s "$source" "$target"
        echo "Moved matching existing skill to migration backup: $extra"
        ;;
      install_agent)
        rm -f "$target"
        install -m 0644 "$source" "$target"
        ;;
      write_config)
        install -m "$mode" "$source" "$extra"
        mv "$extra" "$target"
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

require_real_directory_ancestry "$HOME" "use configured HOME $HOME" || exit 1
create_workspace
snapshot_relevant_state "$workspace/initial-state"

# Codex-only skills live under codex/ and are discovered from ~/.codex/skills.
plan_skill_tree "$repo_dir/codex" "$HOME/.codex/skills"

# Future portable agent skills may live under generic/.
plan_skill_tree "$repo_dir/generic" "$HOME/.agents/skills"
plan_agents
plan_config
plan_legacy_cleanup
validate_manifest_feasibility

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
