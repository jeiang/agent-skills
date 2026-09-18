#!/usr/bin/env python3
"""Render the committed dist/ output from instruction and agent templates.

Sources:
- instructions/common.md: Jinja template shared by every profile.
- profiles/<profile>/environment.md: appended after the common instructions.
- agents/agents.yaml, agents/bodies/, agents/templates/: shared subagents
  rendered into each harness's native definition format.

Run without arguments to write dist/. Run with --check to fail when dist/
differs from what the sources render to.
"""
from __future__ import annotations

import argparse
import difflib
import sys
from pathlib import Path

import jinja2
import yaml

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
HARNESSES = {
    "claude": ("claude.md", "{name}.md"),
    "codex": ("codex.toml", "{name}.toml"),
    "copilot": ("copilot.agent.md", "{name}.agent.md"),
    "omp": ("omp.md", "{name}.md"),
}

env = jinja2.Environment(
    loader=jinja2.FileSystemLoader(ROOT),
    undefined=jinja2.StrictUndefined,
    keep_trailing_newline=True,
    trim_blocks=True,
    lstrip_blocks=True,
)


def profiles() -> list[str]:
    return sorted(
        path.name for path in (ROOT / "profiles").iterdir() if (path / "environment.md").is_file()
    )


def render_instructions() -> dict[Path, str]:
    common = env.get_template("instructions/common.md")
    outputs: dict[Path, str] = {}
    for profile in profiles():
        environment = (ROOT / "profiles" / profile / "environment.md").read_text(encoding="utf-8")
        outputs[DIST / "instructions" / f"{profile}.md"] = (
            common.render(profile=profile) + "\n" + environment
        )
    return outputs


def render_agents() -> dict[Path, str]:
    config_path = ROOT / "agents" / "agents.yaml"
    if not config_path.is_file():
        return {}
    config = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    outputs: dict[Path, str] = {}
    for agent_id, agent in config["agents"].items():
        for harness, (template_name, filename) in HARNESSES.items():
            harness_config = agent.get(harness)
            if harness_config is None:
                continue
            body = env.get_template(f"agents/bodies/{agent['body']}").render(harness=harness)
            if harness == "codex" and "'''" in body:
                sys.exit(f"{agent_id}: body cannot contain ''' inside a TOML literal string")
            template = env.get_template(f"agents/templates/{template_name}")
            rendered = template.render(
                agent=agent,
                harness=harness_config,
                description=agent["description"],
                body=body.rstrip("\n"),
                defaults=config.get(harness, {}),
            )
            name = harness_config["name"].replace("_", "-")
            outputs[DIST / "agents" / harness / filename.format(name=name)] = rendered
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="fail when dist/ is stale")
    args = parser.parse_args()

    outputs = render_instructions() | render_agents()
    existing = {path for path in DIST.rglob("*") if path.is_file()}
    stale: list[str] = []
    for path, content in sorted(outputs.items()):
        current = path.read_text(encoding="utf-8") if path.is_file() else None
        if current == content:
            continue
        if args.check:
            diff = difflib.unified_diff(
                (current or "").splitlines(keepends=True),
                content.splitlines(keepends=True),
                fromfile=str(path.relative_to(ROOT)),
                tofile="rendered",
            )
            stale.append("".join(diff) or f"missing: {path.relative_to(ROOT)}\n")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
            print(f"Rendered {path.relative_to(ROOT)}")
    for path in sorted(existing - set(outputs)):
        if args.check:
            stale.append(f"unexpected file in dist/: {path.relative_to(ROOT)}\n")
        else:
            path.unlink()
            print(f"Removed {path.relative_to(ROOT)}")
    if stale:
        sys.stderr.write("".join(stale))
        sys.stderr.write("dist/ is stale; run: python scripts/render.py\n")
        return 1
    if args.check:
        print(f"dist/ is up to date ({len(outputs)} files).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
