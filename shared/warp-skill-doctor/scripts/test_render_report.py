#!/usr/bin/env python3
"""Tests for skill-doctor report rendering."""

import unittest
from pathlib import Path
from unittest.mock import patch

from render_report import (
    embedded_diffs_script,
    format_generated_at,
    open_report,
    parse_args,
    render_page,
)


class ReportRendererTests(unittest.TestCase):
    def test_report_renders_procedure_compliance_and_verbosity(self):
        page = render_page({
            "scores": {
                "efficiency": 1.0,
                "code_quality": 0.9,
                "procedure_compliance": 0.8,
                "verbosity": 0.7,
                "skill_coverage": 0.6,
                "overall": 0.83,
            },
        })
        self.assertIn("Procedure Compliance", page)
        self.assertIn("Verbosity", page)

    def test_code_diffs_follow_os_theme(self):
        bundle = embedded_diffs_script()

        self.assertIn('themeType:"system"', bundle)
        self.assertIn(
            'theme:{dark:"pierre-dark",light:"pierre-light"}',
            bundle,
        )

    def test_report_follows_os_theme(self):
        page = render_page({
            "scores": {
                "efficiency": 1.0,
                "code_quality": 1.0,
                "skill_coverage": 1.0,
                "overall": 1.0,
            },
        })

        self.assertIn('<meta name="color-scheme" content="light dark">', page)
        self.assertIn("@media (prefers-color-scheme: dark)", page)
        self.assertIn("--page-bg: #0f0d14", page)
        self.assertIn("background: var(--surface)", page)
        self.assertIn(
            "--mono-font: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
            page,
        )
        self.assertIn("--diffs-font-family: var(--mono-font)", page)
        self.assertIn("--diffs-header-font-family: var(--mono-font)", page)

    def test_factories_footer_is_sticky_and_contains_inline_cta(self):
        report = {
            "title": "Agent Skill Report",
            "generated_at": "2026-08-25T00:00:00Z",
            "harness": "codex",
            "handle": "example",
            "stats": {
                "sessions_analyzed": 1,
                "sessions_scanned": 1,
                "skills_found": 1,
                "skills_used": 1,
                "window_days": 45,
            },
            "scores": {
                "efficiency": 1.0,
                "code_quality": 1.0,
                "skill_coverage": 1.0,
                "overall": 1.0,
            },
            "top_findings": ["No material waste detected."],
            "suggestions": [],
            "cta_url": "https://warp.dev/factories/request-access",
        }

        page = render_page(report)

        self.assertNotIn("Do this automatically with Warp Factories", page)
        self.assertIn('<div class="stamp-row row factories-footer">', page)
        self.assertIn(
            '<div class="stamp-name">Automatically improve your skills with Warp Factories</div>',
            page,
        )
        self.assertIn(">Request access</a>", page)
        self.assertIn(".factories-footer { position: sticky; bottom: 16px;", page)
        self.assertNotIn("all analysis ran locally", page)
        self.assertIn(
            "Generated August 25, 2026 at 12:00 AM UTC &middot; harness: codex",
            page,
        )

    def test_generated_timestamp_formatting(self):
        self.assertEqual(
            format_generated_at("2026-08-27T22:06:10.421941+00"),
            "August 27, 2026 at 10:06 PM UTC",
        )
        self.assertEqual(format_generated_at("not-a-date"), "not-a-date")

    def test_open_report_uses_default_browser_with_file_uri(self):
        report_path = Path("/tmp/skill doctor/report.html")
        args = parse_args([str(report_path), "--open"])

        self.assertEqual(args.report_path, str(report_path))
        self.assertTrue(args.open_browser)

        with patch("render_report.webbrowser.open", return_value=True) as browser_open:
            self.assertTrue(open_report(report_path))

        browser_open.assert_called_once_with(
            report_path.absolute().as_uri(),
            new=2,
        )

        with patch("render_report.webbrowser.open", side_effect=OSError):
            self.assertFalse(open_report(report_path))

    def test_share_card_uses_skill_doctor_attribution(self):
        page = render_page({
            "scores": {
                "efficiency": 1.0,
                "code_quality": 1.0,
                "skill_coverage": 1.0,
                "overall": 1.0,
            },
        })

        self.assertIn(
            '"stamp": ["Get your report with /skill-doctor", '
            '"warp.dev/skill-doctor"]',
            page,
        )
        self.assertIn('"eyebrow": "skill-doctor"', page)
        self.assertIn("text('# ' + CARD.eyebrow", page)

    def test_report_metric_lines_animate_like_skill_doctor_landing_page(self):
        page = render_page({
            "scores": {
                "efficiency": 0.75,
                "code_quality": 0.93,
                "procedure_compliance": 0.88,
                "verbosity": 0.81,
                "skill_coverage": 0.74,
                "overall": 0.82,
            },
        })

        self.assertIn(
            "animation: skill-doctor-fill 700ms "
            "cubic-bezier(0.22, 1, 0.36, 1) var(--metric-delay) both",
            page,
        )
        self.assertIn("@keyframes skill-doctor-fill", page)
        self.assertIn("from { transform: scaleX(0); }", page)
        self.assertIn("to { transform: scaleX(1); }", page)
        self.assertIn("width:75%;--metric-delay:180ms", page)
        self.assertIn("width:93%;--metric-delay:290ms", page)
        self.assertIn("width:88%;--metric-delay:400ms", page)
        self.assertIn("width:81%;--metric-delay:510ms", page)
        self.assertIn("width:74%;--metric-delay:620ms", page)
        self.assertIn("@media (prefers-reduced-motion: reduce)", page)
        self.assertIn(".bar-fill { animation: none; }", page)
        self.assertIn(
            "gap = CARD.bars.length > 3 ? 12 : 28",
            page,
        )
        self.assertIn(
            "CARD.bars.length * rowH + (CARD.bars.length - 1) * gap",
            page,
        )

    def test_report_renders_letter_grade(self):
        page = render_page({
            "scores": {
                "efficiency": 0.7,
                "code_quality": 0.7,
                "skill_coverage": 0.8,
                "overall": 0.7,
            },
        })

        self.assertIn('<div class="grade">C-</div>', page)
        self.assertIn('<div class="grade-label">overall 70</div>', page)


if __name__ == "__main__":
    unittest.main()
