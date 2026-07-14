#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
codex_skills="$HOME/.codex/skills"
generic_skills="$HOME/.agents/skills"
agent_target="$HOME/.codex/agents"
config_file="$HOME/.codex/config.toml"
backup_root="$HOME/.codex/skill-backups"

link_directory() {
  source=$1
  target=$2

  if [ -L "$target" ]; then
    [ "$(readlink "$target")" = "$source" ] || {
      echo "Refusing conflicting symlink: $target" >&2
      return 1
    }
    return 0
  fi

  if [ -e "$target" ]; then
    if [ ! -d "$target" ] || ! diff -qr "$source" "$target" >/dev/null 2>&1; then
      echo "Refusing conflicting skill destination: $target" >&2
      return 1
    fi
    mkdir -p "$backup_root"
    backup="$backup_root/$(basename -- "$target").$(date +%Y%m%d%H%M%S)"
    [ ! -e "$backup" ] || backup="$backup.$$"
    mv "$target" "$backup"
    echo "Backed up existing skill: $backup"
  fi

  ln -s "$source" "$target"
  echo "Linked skill: $target -> $source"
}

link_file() {
  source=$1
  target=$2

  if [ -L "$target" ]; then
    [ "$(readlink "$target")" = "$source" ] || {
      echo "Refusing conflicting symlink: $target" >&2
      return 1
    }
    return 0
  fi

  if [ -e "$target" ]; then
    if [ ! -f "$target" ] || ! cmp -s "$source" "$target"; then
      echo "Refusing conflicting agent destination: $target" >&2
      return 1
    fi
    rm -f "$target"
  fi

  ln -s "$source" "$target"
  echo "Linked agent: $target -> $source"
}

remove_retired_agent() {
  target=$1
  [ -e "$target" ] || [ -L "$target" ] || return 0
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    echo "Refusing retired agent destination that is a directory: $target" >&2
    return 1
  fi
  rm -f "$target"
  echo "Removed retired agent: $target"
}

link_skills() {
  source_root=$1
  target_root=$2

  [ -d "$source_root" ] || return 0
  mkdir -p "$target_root"
  for source in "$source_root"/*; do
    [ -f "$source/SKILL.md" ] || continue
    link_directory "$source" "$target_root/$(basename -- "$source")"
  done
}

render_config() {
  input=$1
  output=$2

  awk '
    function add_missing() {
      if (!threads) print "max_threads = 4"
      if (!depth) print "max_depth = 2"
    }
    /^\[agents\][[:space:]]*(#.*)?$/ {
      if (seen_agents) {
        print "Duplicate [agents] table is unsupported" > "/dev/stderr"
        failed = 1
      }
      seen_agents = 1
      in_agents = 1
      print
      next
    }
    /^[[:space:]]*\[\[.*\]\][[:space:]]*(#.*)?$/ {
      if (in_agents) add_missing()
      in_agents = 0
      print
      next
    }
    /^[[:space:]]*\[[^]]+\][[:space:]]*(#.*)?$/ {
      if (in_agents) add_missing()
      in_agents = 0
      print
      next
    }
    in_agents && /^[[:space:]]*max_threads[[:space:]]*=/ {
      if (threads || $0 !~ /^[[:space:]]*max_threads[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*(#.*)?$/) {
        print "Unsupported agents.max_threads definition" > "/dev/stderr"
        failed = 1
        print
        next
      }
      threads = 1
      match($0, /[0-9]+/)
      if ((substr($0, RSTART, RLENGTH) + 0) < 4)
        $0 = substr($0, 1, RSTART - 1) "4" substr($0, RSTART + RLENGTH)
      print
      next
    }
    in_agents && /^[[:space:]]*max_depth[[:space:]]*=/ {
      if (depth || $0 !~ /^[[:space:]]*max_depth[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*(#.*)?$/) {
        print "Unsupported agents.max_depth definition" > "/dev/stderr"
        failed = 1
        print
        next
      }
      depth = 1
      match($0, /[0-9]+/)
      if ((substr($0, RSTART, RLENGTH) + 0) < 2)
        $0 = substr($0, 1, RSTART - 1) "2" substr($0, RSTART + RLENGTH)
      print
      next
    }
    { print }
    END {
      if (in_agents) add_missing()
      if (!seen_agents) {
        if (NR) print ""
        print "[agents]"
        print "max_threads = 4"
        print "max_depth = 2"
      }
      if (failed) exit 1
    }
  ' "$input" >"$output"
}

update_config() {
  mkdir -p "$(dirname -- "$config_file")"
  temporary=$(mktemp "${TMPDIR:-/tmp}/agent-skills-config.XXXXXX")
  trap 'rm -f "$temporary"' EXIT HUP INT TERM

  if [ -e "$config_file" ]; then
    [ -f "$config_file" ] && [ ! -L "$config_file" ] || {
      echo "Refusing non-regular Codex config: $config_file" >&2
      return 1
    }
    render_config "$config_file" "$temporary"
  else
    render_config /dev/null "$temporary"
  fi

  if [ ! -e "$config_file" ] || ! cmp -s "$temporary" "$config_file"; then
    if [ -e "$config_file" ]; then
      backup="$config_file.bak.$(date +%Y%m%d%H%M%S)"
      [ ! -e "$backup" ] || backup="$backup.$$"
      cp -p "$config_file" "$backup"
      echo "Backed up Codex config: $backup"
    fi
    install -m 0600 "$temporary" "$config_file"
    echo "Updated Codex agent limits: $config_file"
  fi

  rm -f "$temporary"
  trap - EXIT HUP INT TERM
}

mkdir -p "$agent_target"
link_skills "$repo_dir/codex" "$codex_skills"
link_skills "$repo_dir/generic" "$generic_skills"

for source in "$repo_dir"/agents/*.toml; do
  [ -f "$source" ] || continue
  link_file "$source" "$agent_target/$(basename -- "$source")"
done

remove_retired_agent "$agent_target/agents-md-author.toml"
remove_retired_agent "$agent_target/prompt-validator.toml"

update_config

echo "Installed skills and agents from: $repo_dir"
echo "Restart Codex if updated configuration is not detected immediately."
