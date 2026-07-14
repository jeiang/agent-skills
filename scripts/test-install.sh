#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-install.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM
installer_tmp="$test_root/external-tmp"
mkdir "$installer_tmp"
TMPDIR="$installer_tmp"
export TMPDIR

assert_installer_temp_clean() {
  if find "$installer_tmp" -mindepth 1 -maxdepth 1 -print | grep . >/dev/null; then
    echo "Installer left external workspace or lock state behind" >&2
    find "$installer_tmp" -mindepth 1 -maxdepth 1 -print >&2
    exit 1
  fi
}

snapshot_home() {
  home=$1
  output=$2
  tar -cf "$output" -C "$home" .
}

run_installer() {
  home=$1
  installer=${2:-$repo_dir/install.sh}
  config="$home/.codex/config.toml"
  if [ -e "$config" ]; then
    assert_toml "$config"
  fi
  if ! HOME="$home" "$installer" >/dev/null; then
    assert_installer_temp_clean
    return 1
  fi
  assert_toml "$config"
  assert_installer_temp_clean
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
  installer=${3:-$repo_dir/install.sh}
  config="$home/.codex/config.toml"
  fixture=$(basename -- "$home")
  before="$test_root/$fixture.before"
  home_before="$test_root/$fixture.home.before"
  home_after="$test_root/$fixture.home.after"
  error="$test_root/$fixture.stderr"

  assert_toml "$config"
  cp "$config" "$before"
  snapshot_home "$home" "$home_before"
  if run_installer "$home" "$installer" 2>"$error"; then
    echo "Installer accepted unsupported agents TOML in $fixture" >&2
    exit 1
  fi
  cmp "$before" "$config"
  snapshot_home "$home" "$home_after"
  cmp "$home_before" "$home_after"
  assert_toml "$config"
  grep -F "$expected_error" "$error" >/dev/null
}

assert_lexical_refused_unchanged() {
  home=$1
  expected_error=$2
  config="$home/.codex/config.toml"
  fixture=$(basename -- "$home")
  before="$test_root/$fixture.before"
  home_before="$test_root/$fixture.home.before"
  home_after="$test_root/$fixture.home.after"
  error="$test_root/$fixture.stderr"

  cp "$config" "$before"
  snapshot_home "$home" "$home_before"
  if HOME="$home" "$repo_dir/install.sh" >"$test_root/$fixture.stdout" 2>"$error"; then
    echo "Installer accepted unsupported TOML string syntax in $fixture" >&2
    exit 1
  fi
  cmp "$before" "$config"
  snapshot_home "$home" "$home_after"
  cmp "$home_before" "$home_after"
  grep -F "$expected_error" "$error" >/dev/null
  assert_installer_temp_clean
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
  assert_installer_temp_clean
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

assert_permission_refusal() {
  home=$1
  expected_error=$2
  control=$3
  fixture=$(basename -- "$home")
  if sh -c "$control" 2>/dev/null; then
    echo "Skipping $fixture because the matching external operation bypassed the intended permission denial."
    return 0
  fi
  assert_refused_unchanged "$home" "$expected_error"
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

# A cooperating installer lock refuses before HOME mutation.
home=$(new_home cooperating_lock)
printf '%s\n' '[identity]' 'name = "locked"' >"$home/.codex/config.toml"
snapshot_home "$home" "$test_root/cooperating_lock.home.before"
lock_key=$(printf '%s' "$home" | cksum | awk '{ print $1 "-" $2 }')
lock_dir="$installer_tmp/agent-skills-install-lock.$lock_key"
mkdir -m 0700 "$lock_dir"
if HOME="$home" "$repo_dir/install.sh" >"$test_root/cooperating_lock.stdout" 2>"$test_root/cooperating_lock.stderr"; then
  echo "Installer ignored a cooperating lock" >&2
  exit 1
fi
snapshot_home "$home" "$test_root/cooperating_lock.home.after"
cmp "$test_root/cooperating_lock.home.before" "$test_root/cooperating_lock.home.after"
grep -F 'Refusing concurrent agent-skills installation' "$test_root/cooperating_lock.stderr" >/dev/null
rmdir "$lock_dir"
assert_installer_temp_clean

# A late skill conflict refuses before earlier planned links or agents mutate HOME.
home=$(new_home skill_conflict)
printf '%s\n' '[identity]' 'name = "skill conflict"' >"$home/.codex/config.toml"
mkdir -p "$home/.codex/skills/start-task"
printf '%s\n' 'different content' >"$home/.codex/skills/start-task/SKILL.md"
assert_refused_unchanged "$home" 'Refusing to replace different existing skill'

# A migration backup collision is detected during simulation.
home=$(new_home backup_conflict)
printf '%s\n' '[identity]' 'name = "backup conflict"' >"$home/.codex/config.toml"
mkdir -p "$home/.codex/skills" "$home/.codex/skill-backups/actual-budget-import"
cp -R "$repo_dir/codex/actual-budget-import" "$home/.codex/skills/actual-budget-import"
printf '%s\n' 'reserved' >"$home/.codex/skill-backups/actual-budget-import/marker"
assert_refused_unchanged "$home" 'Refusing to overwrite existing migration backup'

# Agent destination conflicts are refused before any planned HOME changes execute.
home=$(new_home agent_destination_directory)
printf '%s\n' '[identity]' 'name = "agent conflict"' >"$home/.codex/config.toml"
mkdir -p "$home/.codex/agents/task-orchestrator.toml"
assert_refused_unchanged "$home" 'Refusing agent destination that is a directory'

# Destination ancestry must contain only real searchable directories.
home=$(new_home destination_ancestry_symlink)
printf '%s\n' '[identity]' 'name = "ancestry symlink"' >"$home/.codex/config.toml"
mkdir "$home/skills-target"
ln -s "$home/skills-target" "$home/.codex/skills"
assert_refused_unchanged "$home" 'Refusing installer destination ancestry symlink'

# Permission fixtures run only when the matching external operation is denied.
home=$(new_home mkdir_permission)
printf '%s\n' '[identity]' 'name = "mkdir permission"' >"$home/.codex/config.toml"
chmod 0555 "$home/.codex"
assert_permission_refusal "$home" 'Cannot create directory' "mkdir '$home/.codex/control-directory'"
chmod 0755 "$home/.codex"

home=$(new_home link_permission)
run_installer "$home"
rm "$home/.codex/skills/start-task"
chmod 0555 "$home/.codex/skills"
assert_permission_refusal "$home" 'Cannot link skill' "ln -s '$repo_dir/codex/start-task' '$home/.codex/skills/control-link'"
chmod 0755 "$home/.codex/skills"

home=$(new_home agent_permission)
run_installer "$home"
printf '%s\n' 'outdated agent' >"$home/.codex/agents/task-orchestrator.toml"
chmod 0555 "$home/.codex/agents"
assert_permission_refusal "$home" 'Cannot install agent' "install -m 0644 '$repo_dir/agents/task-orchestrator.toml' '$home/.codex/agents/control-agent.toml'"
chmod 0755 "$home/.codex/agents"

home=$(new_home config_permission)
run_installer "$home"
printf '%s\n' '[agents]' 'max_threads = 4' 'max_depth = 1' >"$home/.codex/config.toml"
chmod 0555 "$home/.codex"
assert_permission_refusal "$home" 'Cannot create temporary Codex config' "cp '$home/.codex/config.toml' '$home/.codex/control-config.tmp'"
chmod 0755 "$home/.codex"

home=$(new_home legacy_remove_permission)
run_installer "$home"
mkdir -p "$home/.agents/skills"
ln -s missing-start-task "$home/.agents/skills/start-task"
ln -s missing-control "$home/.agents/skills/control-link"
chmod 0555 "$home/.agents/skills"
assert_permission_refusal "$home" 'Cannot remove legacy link' "rm '$home/.agents/skills/control-link'"
chmod 0755 "$home/.agents/skills"

home=$(new_home migration_permission)
run_installer "$home"
rm "$home/.codex/skills/actual-budget-import"
cp -R "$repo_dir/codex/actual-budget-import" "$home/.codex/skills/actual-budget-import"
mkdir -p "$home/.codex/skill-backups"
chmod 0555 "$home/.codex/skill-backups"
assert_permission_refusal "$home" 'Cannot create migration backup' "mkdir '$home/.codex/skill-backups/control-backup'"
chmod 0755 "$home/.codex/skill-backups"

# A disposable source tree exercises generic installation and shared backup planning.
fixture_repo="$test_root/source-repository"
mkdir -p "$fixture_repo/codex" "$fixture_repo/generic" "$fixture_repo/agents"
cp "$repo_dir/install.sh" "$fixture_repo/install.sh"
cp -R "$repo_dir/codex/actual-budget-import" "$fixture_repo/codex/actual-budget-import"
cp -R "$repo_dir/codex/start-task" "$fixture_repo/codex/start-task"
cp "$repo_dir"/agents/*.toml "$fixture_repo/agents/"
cp -R "$repo_dir/codex/start-task" "$fixture_repo/generic/portable-task"

home=$(new_home generic_success)
run_installer "$home" "$fixture_repo/install.sh"
[ "$(readlink "$home/.agents/skills/portable-task")" = "$fixture_repo/generic/portable-task" ]
assert_agents "$home/.codex/config.toml" 2 4

cp -R "$repo_dir/codex/start-task" "$fixture_repo/generic/start-task"
home=$(new_home shared_backup_collision)
printf '%s\n' '[identity]' 'name = "shared backup"' >"$home/.codex/config.toml"
mkdir -p "$home/.codex/skills" "$home/.agents/skills"
cp -R "$fixture_repo/codex/start-task" "$home/.codex/skills/start-task"
cp -R "$fixture_repo/generic/start-task" "$home/.agents/skills/start-task"
assert_refused_unchanged "$home" 'Refusing multiple migrations to shared backup name' "$fixture_repo/install.sh"

# A regular config remains supported.
home=$(new_home regular_config)
printf '%s\n' '[identity]' 'name = "regular"' >"$home/.codex/config.toml"
run_installer "$home"
[ ! -L "$home/.codex/config.toml" ]
assert_agents "$home/.codex/config.toml" 2 4

# A feasible same-filesystem migration remains supported.
home=$(new_home migration_success)
printf '%s\n' '[identity]' 'name = "migration success"' >"$home/.codex/config.toml"
mkdir -p "$home/.codex/skills"
cp -R "$repo_dir/codex/actual-budget-import" "$home/.codex/skills/actual-budget-import"
run_installer "$home"
[ -L "$home/.codex/skills/actual-budget-import" ]
[ -d "$home/.codex/skill-backups/actual-budget-import" ]
diff -qr "$repo_dir/codex/actual-budget-import" "$home/.codex/skill-backups/actual-budget-import" >/dev/null

# Fresh configuration receives both required settings.
home=$(new_home fresh)
run_installer "$home"
assert_agents "$home/.codex/config.toml" 2 4
[ -L "$home/.codex/skills/start-task" ]
[ -f "$home/.codex/agents/task-orchestrator.toml" ]

# Successful frozen execution removes only the previously planned broken legacy link.
home=$(new_home legacy_cleanup)
mkdir -p "$home/.agents/skills"
ln -s missing-start-task "$home/.agents/skills/start-task"
run_installer "$home"
[ ! -L "$home/.agents/skills/start-task" ]
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
snapshot_home "$home" "$test_root/idempotent.home.before"
run_installer "$home"
cmp "$test_root/config.before" "$home/.codex/config.toml"
snapshot_home "$home" "$test_root/idempotent.home.after"
cmp "$test_root/idempotent.home.before" "$test_root/idempotent.home.after"
