#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"

set -- codex/* shared/*
for skill_dir in claude/*/ generic/*/; do
  [ -d "$skill_dir" ] || continue
  set -- "$@" "${skill_dir%/}"
done
python scripts/validate-skills.py "$@"
python scripts/validate-agent-configs.py

python - <<'PY'
from pathlib import Path
import tomllib
import yaml

for path in sorted(Path("agents").glob("*.toml")):
    with path.open("rb") as stream:
        tomllib.load(stream)

for root in ("codex", "shared"):
    for path in sorted(Path(root).glob("*/agents/openai.yaml")):
        with path.open(encoding="utf-8") as stream:
            yaml.safe_load(stream)
PY

sh -n install.sh scripts/check.sh scripts/test-install.sh
shellcheck install.sh scripts/check.sh scripts/test-install.sh
shfmt -d -i 2 -ci install.sh scripts/check.sh scripts/test-install.sh
taplo format --check agents/*.toml
scripts/test-install.sh
git diff --check
