#!/usr/bin/env python3
"""Check invocation types and discovery limits."""
from pathlib import Path
import runpy
import tempfile
import unittest


validate = runpy.run_path(str(Path(__file__).with_name("validate-skills.py")))[
    "validate_skill"
]


class SkillValidationTests(unittest.TestCase):
    def test_invocation_policy(self):
        for value, valid in (("true", True), ("false", True), ("nope", False)):
            with self.subTest(value=value), tempfile.TemporaryDirectory() as root:
                skill = Path(root) / "example"
                skill.mkdir()
                (skill / "SKILL.md").write_text(
                    "---\nname: example\ndescription: Example task\n"
                    f"disable-model-invocation: {value}\n"
                    "---\nDo the example task.\n"
                )
                self.assertEqual(not validate(skill), valid)

    def test_description_limit(self):
        with tempfile.TemporaryDirectory() as root:
            skill = Path(root) / "example"
            skill.mkdir()
            for length, valid in ((1024, True), (1025, False)):
                (skill / "SKILL.md").write_text(
                    "---\nname: example\ndescription: " + "a" * length
                    + "\n---\nDo the example task.\n"
                )
                self.assertEqual(not validate(skill), valid)

    def test_metadata_field_allowed(self):
        with tempfile.TemporaryDirectory() as root:
            skill = Path(root) / "example"
            skill.mkdir()
            for field, valid in (("metadata:\n  category: productivity\n", True), ("unknown: x\n", False)):
                (skill / "SKILL.md").write_text(
                    "---\nname: example\ndescription: Example task\n" + field
                    + "---\nDo the example task.\n"
                )
                self.assertEqual(not validate(skill), valid)


if __name__ == "__main__":
    unittest.main()
