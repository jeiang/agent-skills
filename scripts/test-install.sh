#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-install.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

run_installer() {
  home=$1
  config="$home/.codex/config.toml"
  if [ -e "$config" ]; then
    assert_toml "$config"
  fi
  if ! HOME="$home" "$repo_dir/install.sh" >/dev/null; then
    return 1
  fi
  assert_toml "$config"
}

assert_toml() {
  CONFIG_FILE=$1 python - <<'PY'
import os
from pathlib import Path
import tomllib

with Path(os.environ["CONFIG_FILE"]).open("rb") as stream:
    tomllib.load(stream)
PY
}

assert_refused_unchanged() {
  home=$1
  expected_error=$2
  config="$home/.codex/config.toml"
  fixture=$(basename -- "$home")
  before="$test_root/$fixture.before"
  error="$test_root/$fixture.stderr"

  assert_toml "$config"
  cp "$config" "$before"
  if run_installer "$home" 2>"$error"; then
    echo "Installer accepted unsupported agents TOML in $fixture" >&2
    exit 1
  fi
  cmp "$before" "$config"
  assert_toml "$config"
  grep -F "$expected_error" "$error" >/dev/null
}

assert_lexical_refused_unchanged() {
  home=$1
  expected_error=$2
  config="$home/.codex/config.toml"
  fixture=$(basename -- "$home")
  before="$test_root/$fixture.before"
  error="$test_root/$fixture.stderr"

  cp "$config" "$before"
  if HOME="$home" "$repo_dir/install.sh" >"$test_root/$fixture.stdout" 2>"$error"; then
    echo "Installer accepted unsupported TOML string syntax in $fixture" >&2
    exit 1
  fi
  cmp "$before" "$config"
  grep -F "$expected_error" "$error" >/dev/null
}

assert_symlink_refused() {
  home=$1
  expected_link_target=$2
  target_file=$3
  config="$home/.codex/config.toml"
  fixture=$(basename -- "$home")
  error="$test_root/$fixture.stderr"

  [ -L "$config" ]
  [ "$(readlink "$config")" = "$expected_link_target" ]
  if [ "$target_file" != '-' ]; then
    cp "$target_file" "$test_root/$fixture.target.before"
  fi

  if HOME="$home" "$repo_dir/install.sh" >"$test_root/$fixture.stdout" 2>"$error"; then
    echo "Installer accepted symlinked config in $fixture" >&2
    exit 1
  fi

  [ -L "$config" ]
  [ "$(readlink "$config")" = "$expected_link_target" ]
  grep -F "Refusing symlinked Codex config: $config -> $expected_link_target" "$error" >/dev/null
  [ ! -e "$home/.codex/skills" ]
  [ ! -e "$home/.codex/agents" ]
  [ ! -e "$home/.agents" ]

  if [ "$target_file" = '-' ]; then
    [ ! -e "$config" ]
  else
    cmp "$test_root/$fixture.target.before" "$target_file"
    assert_toml "$target_file"
  fi
}

assert_agents() {
  config=$1
  expected_depth=$2
  expected_threads=$3

  CONFIG_FILE="$config" EXPECTED_DEPTH="$expected_depth" EXPECTED_THREADS="$expected_threads" python - <<'PY'
import os
from pathlib import Path
import tomllib

path = Path(os.environ["CONFIG_FILE"])
with path.open("rb") as stream:
    config = tomllib.load(stream)

agents = config["agents"]
assert agents["max_threads"] == int(os.environ["EXPECTED_THREADS"]), agents
assert agents["max_depth"] == int(os.environ["EXPECTED_DEPTH"]), agents
PY

  count=$(grep -Ec '^[[:space:]]*\[agents\][[:space:]]*(#.*)?$' "$config")
  [ "$count" -eq 1 ]
}

new_home() {
  name=$1
  home="$test_root/$name"
  mkdir -p "$home/.codex"
  printf '%s\n' "$home"
}

# Config symlinks are refused before any installation mutation.
home=$(new_home relative_symlink)
printf '%s\n' '[identity]' 'name = "relative"' >"$home/.codex/config-target.toml"
ln -s 'config-target.toml' "$home/.codex/config.toml"
assert_symlink_refused "$home" 'config-target.toml' "$home/.codex/config-target.toml"

home=$(new_home absolute_symlink)
printf '%s\n' '[identity]' 'name = "absolute"' >"$home/absolute-config.toml"
ln -s "$home/absolute-config.toml" "$home/.codex/config.toml"
assert_symlink_refused "$home" "$home/absolute-config.toml" "$home/absolute-config.toml"

home=$(new_home dangling_symlink)
ln -s 'missing-config.toml' "$home/.codex/config.toml"
assert_symlink_refused "$home" 'missing-config.toml' '-'

# A regular config remains supported.
home=$(new_home regular_config)
printf '%s\n' '[identity]' 'name = "regular"' >"$home/.codex/config.toml"
run_installer "$home"
[ ! -L "$home/.codex/config.toml" ]
assert_agents "$home/.codex/config.toml" 2 4

# Fresh configuration receives both required settings.
home=$(new_home fresh)
run_installer "$home"
assert_agents "$home/.codex/config.toml" 2 4

# Low limits are raised while inline comments and unrelated settings remain.
home=$(new_home shallow)
printf '%s\n' \
  '# leading comment' \
  '[agents] # agent settings' \
  'max_threads = 2 # raise this value' \
  'max_depth = 1 # raise this value' \
  'max_jobs = 3' \
  '' \
  '[features]' \
  'experimental = true' >"$home/.codex/config.toml"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 2 4
grep -Fqx 'max_threads = 4 # raise this value' "$home/.codex/config.toml"
grep -Fqx 'max_depth = 2 # raise this value' "$home/.codex/config.toml"
grep -Fqx 'max_jobs = 3' "$home/.codex/config.toml"
grep -Fqx 'experimental = true' "$home/.codex/config.toml"

# Exact thread limits are preserved.
home=$(new_home exact_threads)
printf '%s\n' '[agents]' 'max_depth = 2' 'max_threads = 4 # exact minimum' >"$home/.codex/config.toml"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 2 4
grep -Fqx 'max_threads = 4 # exact minimum' "$home/.codex/config.toml"

# Higher depths and thread limits are preserved.
home=$(new_home higher)
printf '%s\n' '[agents]' 'max_depth = 5' 'max_threads = 9' >"$home/.codex/config.toml"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 5 9
grep -Fqx 'max_threads = 9' "$home/.codex/config.toml"

# Missing settings are added inside the agents table without disturbing later tables.
home=$(new_home missing)
printf '%s\n' \
  '[identity]' \
  'name = "example"' \
  '' \
  '[agents]' \
  '# retain this comment' \
  '' \
  '[agents.roles]' \
  'enabled = true' >"$home/.codex/config.toml"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 2 4
grep -Fqx 'name = "example"' "$home/.codex/config.toml"
grep -Fqx '# retain this comment' "$home/.codex/config.toml"
grep -Fqx '[agents.roles]' "$home/.codex/config.toml"
grep -Fqx 'enabled = true' "$home/.codex/config.toml"

# An existing depth with no thread setting receives only max_threads.
home=$(new_home missing_threads)
printf '%s\n' '[agents]' 'max_depth = 3' >"$home/.codex/config.toml"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 3 4

# Malformed direct thread values are refused without modifying the configuration.
home=$(new_home malformed_threads)
printf '%s\n' '[agents]' 'max_depth = 3' 'max_threads = "4" # invalid direct value' >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'Unsupported agents.max_threads value'

# Valid noncanonical agents representations are refused atomically.
home=$(new_home quoted_table)
printf '%s\n' '["agents"]' 'max_threads = 4' 'max_depth = 2' >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'agents must be declared first as a top-level bare [agents] table'

home=$(new_home quoted_key)
printf '%s\n' '[agents]' '"max_threads" = 4' 'max_depth = 2' >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'max_threads and max_depth must be direct bare keys'

home=$(new_home dotted_root)
printf '%s\n' 'agents.max_threads = 4' 'agents.max_depth = 2' >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'dotted, quoted, or inline root agents keys are not supported'

home=$(new_home inline_root)
printf '%s\n' 'agents = { max_threads = 4, max_depth = 2 }' >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'dotted, quoted, or inline root agents keys are not supported'

home=$(new_home agents_array)
printf '%s\n' '[agents]' 'max_threads = 4' 'max_depth = 2' '[[agents.roles]]' 'name = "reviewer"' >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'array-of-tables form for agents is not supported'

# Multiline strings are valid TOML but are refused before the line-oriented rewrite.
home=$(new_home multiline_basic)
printf '%s\n' \
  '[notes]' \
  'content = """' \
  '[agents]' \
  'max_threads = 1' \
  'max_depth = 1' \
  '"""' >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'multiline basic string delimiters are not supported'

home=$(new_home multiline_literal)
printf '%s\n' \
  '[notes]' \
  "content = '''" \
  '[agents]' \
  'max_threads = 1' \
  'max_depth = 1' \
  "'''" >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'multiline literal string delimiters are not supported'

# Delimiter text outside structural syntax remains supported.
home=$(new_home multiline_delimiter_text)
printf '%s\n' \
  "# comment has \"\"\" and '''" \
  '[notes]' \
  "basic_opposite = \"'''\"" \
  "literal_opposite = '\"\"\"'" \
  'escaped_basic = "\"\"\""' \
  'hash_basic = "# remains basic string data"' \
  "hash_literal = '# remains literal string data'" \
  "closed_basic = \"done\" # comment has \"\"\" and '''" \
  "closed_literal = 'done' # comment has \"\"\" and '''" \
  '' \
  '[agents]' \
  'max_threads = 1 # raise safely' \
  'max_depth = 1 # raise safely' >"$home/.codex/config.toml"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 2 4
grep -Fqx "# comment has \"\"\" and '''" "$home/.codex/config.toml"
grep -Fqx "basic_opposite = \"'''\"" "$home/.codex/config.toml"
grep -Fqx "literal_opposite = '\"\"\"'" "$home/.codex/config.toml"
grep -Fqx 'escaped_basic = "\"\"\""' "$home/.codex/config.toml"
grep -Fqx 'hash_basic = "# remains basic string data"' "$home/.codex/config.toml"
grep -Fqx "hash_literal = '# remains literal string data'" "$home/.codex/config.toml"
grep -Fqx "closed_basic = \"done\" # comment has \"\"\" and '''" "$home/.codex/config.toml"
grep -Fqx "closed_literal = 'done' # comment has \"\"\" and '''" "$home/.codex/config.toml"
grep -Fqx 'max_threads = 4 # raise safely' "$home/.codex/config.toml"
grep -Fqx 'max_depth = 2 # raise safely' "$home/.codex/config.toml"
cp "$home/.codex/config.toml" "$test_root/multiline_delimiter_text.after"
run_installer "$home"
cmp "$test_root/multiline_delimiter_text.after" "$home/.codex/config.toml"

# Unterminated ordinary strings are refused without modifying their invalid TOML.
home=$(new_home unterminated_basic)
printf '%s\n' '[notes]' 'content = "unterminated' >"$home/.codex/config.toml"
assert_lexical_refused_unchanged "$home" 'unterminated ordinary basic string'

home=$(new_home unterminated_literal)
printf '%s\n' '[notes]' "content = 'unterminated" >"$home/.codex/config.toml"
assert_lexical_refused_unchanged "$home" 'unterminated ordinary literal string'

home=$(new_home nested_before_root)
printf '%s\n' '[agents.roles]' 'enabled = true' >"$home/.codex/config.toml"
assert_refused_unchanged "$home" 'agents must be declared first as a top-level bare [agents] table'

# Duplicate canonical definitions are invalid TOML but are still refused atomically.
home=$(new_home duplicate_agents)
printf '%s\n' '[agents]' 'max_threads = 4' '[agents]' 'max_depth = 2' >"$home/.codex/config.toml"
cp "$home/.codex/config.toml" "$test_root/duplicate_agents.before"
if HOME="$home" "$repo_dir/install.sh" >"$test_root/duplicate_agents.stdout" 2>"$test_root/duplicate_agents.stderr"; then
  echo "Installer accepted a duplicate [agents] table" >&2
  exit 1
fi
cmp "$test_root/duplicate_agents.before" "$home/.codex/config.toml"
grep -F 'duplicate [agents] table' "$test_root/duplicate_agents.stderr" >/dev/null

# Quoted and dotted TOML outside the agents namespace remains untouched.
home=$(new_home unrelated_noncanonical)
printf '%s\n' \
  '["service.settings"]' \
  'agents.mode = "unrelated"' \
  '' \
  '[agents]' \
  'max_threads = 4' \
  'max_depth = 2' \
  '' \
  '[agents.roles]' \
  'enabled = true' >"$home/.codex/config.toml"
cp "$home/.codex/config.toml" "$test_root/unrelated.before"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 2 4
cmp "$test_root/unrelated.before" "$home/.codex/config.toml"

# Repeated runs are idempotent.
home=$(new_home idempotent)
printf '%s\n' '[agents]' 'max_depth = 3' 'max_threads = 1 # raise once' >"$home/.codex/config.toml"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 3 4
grep -Fqx 'max_threads = 4 # raise once' "$home/.codex/config.toml"
cp "$home/.codex/config.toml" "$test_root/config.before"
run_installer "$home"
cmp "$test_root/config.before" "$home/.codex/config.toml"
