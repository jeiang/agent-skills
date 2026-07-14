#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"

python scripts/validate-skills.py codex/*
python scripts/test-validate-skills.py
python scripts/validate-agent-configs.py
python scripts/test-validate-agent-configs.py
python scripts/validate-start-task-skill.py
python scripts/validate-install-traps.py

python - <<'PY'
from pathlib import Path
import tomllib

import yaml

for path in sorted(Path(".").glob("**/*.toml")):
    if not {".devenv", ".git"}.intersection(path.parts):
        with path.open("rb") as stream:
            tomllib.load(stream)

for pattern in ("*.yaml", "*.yml"):
    for path in sorted(Path(".").glob(f"**/{pattern}")):
        if not {".devenv", ".git"}.intersection(path.parts):
            with path.open(encoding="utf-8") as stream:
                yaml.safe_load(stream)
PY

sh -n install.sh
sh -n scripts/test-install.sh
shellcheck --exclude=SC1007 install.sh
shellcheck scripts/check.sh
shellcheck scripts/test-install.sh
shfmt -d -i 2 -ci install.sh scripts/check.sh scripts/test-install.sh
taplo format --check agents/*.toml
scripts/test-install.sh
git diff --check
