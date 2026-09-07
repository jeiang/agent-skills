#!/bin/sh
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"

set --
for skill_dir in codex/* shared/* claude/* generic/*; do
  [ -f "$skill_dir/SKILL.md" ] || continue
  set -- "$@" "$skill_dir"
done
python scripts/validate-skills.py "$@"
python scripts/test-validate-skills.py
python scripts/validate-agent-configs.py

python - <<'PY'
from pathlib import Path
import re
import sys
import tomllib
import yaml

for path in sorted(Path("agents").glob("*.toml")):
    with path.open("rb") as stream:
        tomllib.load(stream)

for path in sorted(Path("claude-agents").glob("*.md")):
    text = path.read_text(encoding="utf-8")
    match = re.match(r"---\n(.*?)\n---\n(.*)", text, re.DOTALL)
    if match is None:
        sys.exit(f"{path}: must start with YAML frontmatter")
    frontmatter = yaml.safe_load(match.group(1))
    for field in ("name", "description", "model"):
        value = frontmatter.get(field)
        if not isinstance(value, str) or not value.strip():
            sys.exit(f"{path}: frontmatter field {field!r} must be a nonempty string")
    if frontmatter["name"] != path.stem:
        sys.exit(f"{path}: name {frontmatter['name']!r} must match filename")
    if not match.group(2).strip():
        sys.exit(f"{path}: body must be nonempty")

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
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File scripts/test-install.ps1
else
  echo "Skipping PowerShell installer test: pwsh not found" >&2
fi
git diff --check
