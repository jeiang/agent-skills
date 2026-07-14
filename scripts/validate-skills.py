#!/usr/bin/env python3
from pathlib import Path
import re
import sys

import yaml


NAME_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
REQUIRED_FIELDS = {"name", "description"}


class UniqueKeyLoader(yaml.SafeLoader):
    pass


def construct_unique_mapping(
    loader: UniqueKeyLoader, node: yaml.MappingNode, deep: bool = False
) -> dict[object, object]:
    mapping: dict[object, object] = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in mapping:
            raise yaml.constructor.ConstructorError(
                "while constructing a mapping",
                node.start_mark,
                f"found duplicate key {key!r}",
                key_node.start_mark,
            )
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


UniqueKeyLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_unique_mapping
)


def split_skill(text: str) -> tuple[str, str]:
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        raise ValueError("SKILL.md must start with YAML frontmatter")

    for index, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            return "".join(lines[1:index]), "".join(lines[index + 1 :])
    raise ValueError("SKILL.md frontmatter must have a closing delimiter")


def validate_skill(skill_dir: Path) -> list[str]:
    errors: list[str] = []
    skill_file = skill_dir / "SKILL.md"
    try:
        text = skill_file.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        return [f"cannot read {skill_file}: {error}"]

    try:
        raw_frontmatter, body = split_skill(text)
    except ValueError as error:
        return [f"{skill_file}: {error}"]

    try:
        frontmatter = yaml.load(raw_frontmatter, Loader=UniqueKeyLoader)
    except yaml.YAMLError as error:
        errors.append(f"{skill_file}: invalid YAML frontmatter: {error}")
        frontmatter = None

    if not isinstance(frontmatter, dict):
        errors.append(f"{skill_file}: frontmatter must be a YAML mapping")
    else:
        fields = set(frontmatter)
        missing = REQUIRED_FIELDS - fields
        extra = fields - REQUIRED_FIELDS
        if missing:
            errors.append(f"{skill_file}: missing fields: {', '.join(sorted(missing))}")
        if extra:
            errors.append(f"{skill_file}: extra fields: {', '.join(map(str, sorted(extra, key=str)))}")

        name = frontmatter.get("name")
        if not isinstance(name, str) or not name:
            errors.append(f"{skill_file}: name must be a nonempty string")
        else:
            if len(name) >= 64 or not NAME_PATTERN.fullmatch(name):
                errors.append(
                    f"{skill_file}: name must be fewer than 64 lowercase letters, digits, and single hyphens"
                )
            if name != skill_dir.name:
                errors.append(
                    f"{skill_file}: name {name!r} must match directory {skill_dir.name!r}"
                )

        description = frontmatter.get("description")
        if not isinstance(description, str) or not description.strip():
            errors.append(f"{skill_file}: description must be a nonempty string")

    if not body.strip():
        errors.append(f"{skill_file}: body must be nonempty")

    return errors


def main(arguments: list[str]) -> int:
    if not arguments:
        print("Usage: validate-skills.py SKILL_DIR...", file=sys.stderr)
        return 2

    errors: list[str] = []
    for argument in arguments:
        errors.extend(validate_skill(Path(argument)))

    if errors:
        print("Skill validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(arguments)} skill directories.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
