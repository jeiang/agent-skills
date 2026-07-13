#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-install.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

run_installer() {
  home=$1
  HOME="$home" "$repo_dir/install.sh" >/dev/null
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
}

new_home() {
  name=$1
  home="$test_root/$name"
  mkdir -p "$home/.codex"
  printf '%s\n' "$home"
}

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
cp "$home/.codex/config.toml" "$test_root/malformed.before"
if run_installer "$home" 2>/dev/null; then
  echo "Installer accepted a malformed agents.max_threads value" >&2
  exit 1
fi
cmp "$test_root/malformed.before" "$home/.codex/config.toml"

# Repeated runs are idempotent.
home=$(new_home idempotent)
printf '%s\n' '[agents]' 'max_depth = 3' 'max_threads = 1 # raise once' >"$home/.codex/config.toml"
run_installer "$home"
assert_agents "$home/.codex/config.toml" 3 4
grep -Fqx 'max_threads = 4 # raise once' "$home/.codex/config.toml"
cp "$home/.codex/config.toml" "$test_root/config.before"
run_installer "$home"
cmp "$test_root/config.before" "$home/.codex/config.toml"
