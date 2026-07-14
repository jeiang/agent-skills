#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"

python scripts/validate-skills.py codex/*
python scripts/validate-agent-configs.py

python - <<'PY'
from pathlib import Path
import tomllib
import yaml

for path in sorted(Path("agents").glob("*.toml")):
    with path.open("rb") as stream:
        tomllib.load(stream)

for path in sorted(Path("codex").glob("*/agents/openai.yaml")):
    with path.open(encoding="utf-8") as stream:
        yaml.safe_load(stream)
PY

sh -n install.sh scripts/check.sh scripts/test-install.sh
shellcheck install.sh scripts/check.sh scripts/test-install.sh
shfmt -d -i 2 -ci install.sh scripts/check.sh scripts/test-install.sh
taplo format --check agents/*.toml
scripts/test-install.sh
git diff --check
