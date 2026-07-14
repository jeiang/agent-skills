#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys
import tempfile


VALIDATOR = Path(__file__).with_name("validate-skills.py")


def write_skill(root: Path, directory: str, frontmatter: str, body: str) -> Path:
    skill_dir = root / directory
    skill_dir.mkdir()
    (skill_dir / "SKILL.md").write_text(
        f"---\n{frontmatter}---\n{body}", encoding="utf-8"
    )
    return skill_dir


def run(skill_dir: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(VALIDATOR), str(skill_dir)],
        check=False,
        capture_output=True,
        text=True,
    )


def assert_pass(skill_dir: Path) -> None:
    result = run(skill_dir)
    assert result.returncode == 0, result.stderr


def assert_fail(skill_dir: Path, marker: str) -> None:
    result = run(skill_dir)
    assert result.returncode == 1, (result.stdout, result.stderr)
    assert marker in result.stderr, result.stderr


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="agent-skills-validator-") as temporary:
        root = Path(temporary)

        assert_pass(
            write_skill(
                root,
                "valid-skill",
                "name: valid-skill\ndescription: A useful skill.\n",
                "\n# Valid skill\n",
            )
        )

        assert_fail(
            write_skill(
                root,
                "malformed-yaml",
                "name: malformed-yaml\ndescription: [unterminated\n",
                "\n# Body\n",
            ),
            "invalid YAML frontmatter",
        )
        assert_fail(
            write_skill(root, "missing-name", "description: Missing name.\n", "\n# Body\n"),
            "missing fields: name",
        )
        assert_fail(
            write_skill(root, "missing-description", "name: missing-description\n", "\n# Body\n"),
            "missing fields: description",
        )
        assert_fail(
            write_skill(
                root,
                "extra-field",
                "name: extra-field\ndescription: Extra field.\nversion: 1\n",
                "\n# Body\n",
            ),
            "extra fields: version",
        )
        assert_fail(
            write_skill(
                root,
                "path-name",
                "name: different-name\ndescription: Mismatch.\n",
                "\n# Body\n",
            ),
            "must match directory",
        )
        assert_fail(
            write_skill(
                root,
                "invalid_name",
                "name: invalid_name\ndescription: Invalid name.\n",
                "\n# Body\n",
            ),
            "name must be fewer than 64 lowercase",
        )
        long_name = "a" * 64
        assert_fail(
            write_skill(
                root,
                long_name,
                f"name: {long_name}\ndescription: Name is too long.\n",
                "\n# Body\n",
            ),
            "name must be fewer than 64 lowercase",
        )
        assert_fail(
            write_skill(
                root,
                "empty-description",
                "name: empty-description\ndescription: '   '\n",
                "\n# Body\n",
            ),
            "description must be a nonempty string",
        )
        assert_fail(
            write_skill(
                root,
                "typed-description",
                "name: typed-description\ndescription: 42\n",
                "\n# Body\n",
            ),
            "description must be a nonempty string",
        )
        assert_fail(
            write_skill(
                root,
                "duplicate-field",
                "name: duplicate-field\nname: duplicate-field\ndescription: Duplicate.\n",
                "\n# Body\n",
            ),
            "duplicate key 'name'",
        )
        assert_fail(
            write_skill(
                root,
                "missing-body",
                "name: missing-body\ndescription: Missing body.\n",
                "",
            ),
            "body must be nonempty",
        )
        assert_fail(
            write_skill(
                root,
                "empty-body",
                "name: empty-body\ndescription: Empty body.\n",
                "\n \t\n",
            ),
            "body must be nonempty",
        )

        missing_file = root / "missing-skill-file"
        missing_file.mkdir()
        assert_fail(missing_file, "cannot read")

    print("Validated generic skill validator fixtures.")


if __name__ == "__main__":
    main()
