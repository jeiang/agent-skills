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
for manifest in claude/*/.claude-plugin/plugin.json; do
  python -c 'import json, sys; json.load(open(sys.argv[1]))["name"]' "$manifest"
done
python scripts/test-validate-skills.py
python scripts/validate-agent-configs.py
python scripts/render.py --check

python - <<'PY'
from pathlib import Path
import re
import sys
import tomllib
import yaml

def frontmatter(path):
    text = path.read_text(encoding="utf-8")
    match = re.match(r"---\n(.*?)\n---\n(.*)", text, re.DOTALL)
    if match is None:
        sys.exit(f"{path}: must start with YAML frontmatter")
    if not match.group(2).strip():
        sys.exit(f"{path}: body must be nonempty")
    return yaml.safe_load(match.group(1))

claude_agents = sorted(Path("agents/claude").glob("*.md")) + sorted(Path("dist/agents/claude").glob("*.md"))
for path in claude_agents:
    data = frontmatter(path)
    for field in ("name", "description", "model"):
        value = data.get(field)
        if not isinstance(value, str) or not value.strip():
            sys.exit(f"{path}: frontmatter field {field!r} must be a nonempty string")
    if data["name"] != path.stem:
        sys.exit(f"{path}: name {data['name']!r} must match filename")

copilot_model = yaml.safe_load(Path("agents/agents.yaml").read_text(encoding="utf-8"))["copilot"]["model"]
copilot_agents = sorted(Path("dist/agents/copilot").glob("*.agent.md"))
if len(copilot_agents) != 2:
    sys.exit(f"dist/agents/copilot: expected exactly two agents, found {len(copilot_agents)}")
for path in copilot_agents:
    data = frontmatter(path)
    if not isinstance(data.get("description"), str) or not data["description"].strip():
        sys.exit(f"{path}: description must be a nonempty string")
    if data.get("model") != copilot_model:
        sys.exit(f"{path}: model must be {copilot_model!r}")
    if data.get("agents") != []:
        sys.exit(f"{path}: agents must be [] so subagents cannot nest")
    for tool in data.get("tools", []):
        if tool in ("editFiles", "createFile", "createDirectory", "createAndRunTask"):
            sys.exit(f"{path}: read-only agent must not use {tool}")

for root in ("codex", "shared"):
    for path in sorted(Path(root).glob("*/agents/openai.yaml")):
        with path.open(encoding="utf-8") as stream:
            yaml.safe_load(stream)
PY

sh -n install.sh scripts/check.sh scripts/test-install.sh
shellcheck install.sh scripts/check.sh scripts/test-install.sh
shfmt -d -i 2 -ci install.sh scripts/check.sh scripts/test-install.sh
taplo format --check agents/codex/*.toml dist/agents/codex/*.toml
scripts/test-install.sh
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -NonInteractive -File scripts/test-install.ps1
else
  echo "Skipping PowerShell installer test: pwsh not found" >&2
fi
git diff --check
