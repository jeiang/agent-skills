#!/usr/bin/env python3
"""Validate Codex agent structure without treating prompt wording as behavior.

Static definitions live in agents/codex/; rendered shared agents in
dist/agents/codex/. Both are installed into the same directory.
"""
from pathlib import Path
import sys
import tomllib


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    errors: list[str] = []
    paths = sorted((ROOT / "agents" / "codex").glob("*.toml")) + sorted(
        (ROOT / "dist" / "agents" / "codex").glob("*.toml")
    )
    names: set[str] = set()
    if not paths:
        errors.append("no agent configurations found")
    for path in paths:
        try:
            data = tomllib.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, tomllib.TOMLDecodeError) as error:
            errors.append(f"{path.name}: {error}")
            continue
        for field in ("name", "description", "model", "developer_instructions"):
            value = data.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{path.name}: {field} must be a nonempty string")
        name = data.get("name")
        if not isinstance(name, str):
            continue
        if name != path.stem.replace("-", "_"):
            errors.append(f"{path.name}: name must match the filename")
        if name in names:
            errors.append(f"{path.name}: duplicate agent name {name}")
        names.add(name)
        if data.get("sandbox_mode") not in ("read-only", "workspace-write"):
            errors.append(f"{path.name}: invalid sandbox_mode")
        if data.get("model_reasoning_effort") not in (
            "minimal", "low", "medium", "high", "xhigh", "max", "ultra"
        ):
            errors.append(f"{path.name}: invalid model_reasoning_effort")
    if errors:
        print("Agent validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Validated {len(paths)} agent configurations.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
