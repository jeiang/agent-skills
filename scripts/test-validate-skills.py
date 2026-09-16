#!/usr/bin/env python3
"""Check cross-platform invocation consistency and discovery limits."""
from pathlib import Path
import runpy
import tempfile
import unittest


validate = runpy.run_path(str(Path(__file__).with_name("validate-skills.py")))[
    "validate_skill"
]


class SkillValidationTests(unittest.TestCase):
    def test_invocation_policy(self):
        for manual, implicit, valid in (
            (False, True, True),
            (True, False, True),
            (False, False, False),
            (True, True, False),
            (False, None, True),
            (True, None, False),
        ):
            with self.subTest(manual=manual, implicit=implicit):
                with tempfile.TemporaryDirectory() as root:
                    skill = Path(root) / "example"
                    (skill / "agents").mkdir(parents=True)
                    (skill / "SKILL.md").write_text(
                        "---\nname: example\ndescription: Example task\n"
                        f"disable-model-invocation: {str(manual).lower()}\n"
                        "---\nDo the example task.\n"
                    )
                    if implicit is not None:
                        (skill / "agents/openai.yaml").write_text(
                            "policy:\n"
                            f"  allow_implicit_invocation: {str(implicit).lower()}\n"
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
