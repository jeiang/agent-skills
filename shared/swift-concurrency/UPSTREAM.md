# Upstream

- Repository: https://github.com/AvdLee/Swift-Concurrency-Agent-Skill
- Version: 3b1580d8398e0b5408b3bf0bada0e941a1cfc642
- Skill source: https://github.com/AvdLee/Swift-Concurrency-Agent-Skill/tree/3b1580d8398e0b5408b3bf0bada0e941a1cfc642/skills/swift-concurrency
- License: MIT; see `LICENSE` in this directory.
- Local changes: removed every reference to the author's paid Swift Concurrency Course. That is the 67 "Course Deep Dive" lines in `references/`, the 13 course links in the "Further Learning" lists (a section whose only entry was the course is removed with its heading), the guardrail in `SKILL.md` about course references, and the `SKILL.md` footer note. Four of the "Course Deep Dive" lines sat inside code blocks. The links to Apple documentation, the author's free videos, and public GitHub repositories stay. All other text is unchanged.
- Updating: after copying upstream, search for `swiftconcurrencycourse` and `Course` and remove those lines again.
- Security scan on 2026-11-15 (getsentry `skill-scanner` at `a582c51`): one high finding, text metadata in `assets/logo-small.png`. It is an XMP block that holds only the image's pixel dimensions.
