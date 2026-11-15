---
name: tigerstyle
description: Add TigerBeetle's TigerStyle guide to a repository, adapt its rules to that project, or review code against it. Use when the user names TigerStyle or Tiger Style.
---

# TigerStyle

[`TIGER_STYLE.md`](TIGER_STYLE.md) is TigerBeetle's style guide, copied
unchanged. [`UPSTREAM.md`](UPSTREAM.md) records its commit. The guide is
under the Apache License 2.0 in [`LICENSE`](LICENSE), whatever license the
target repository uses.

A repository that already has the guide (`docs/TIGER_STYLE.md`, or style
rules in `AGENTS.md` that name Tiger Style) keeps its own copy and its own
adaptations. Read those, not the bundled file.

## Add the guide to a repository

1. Copy `TIGER_STYLE.md` to `docs/TIGER_STYLE.md`. Start the copy with a note
   that names the source URL at the commit in `UPSTREAM.md` and the Apache
   License 2.0. When the repository's license is not Apache-2.0, also copy
   `LICENSE` to `docs/TIGER_STYLE.LICENSE` and name it in the README's
   license section.
2. Read the repository's code and build files, then list every rule the
   project cannot follow as written. Check each of these, which need a
   decision in most applications: dependencies, static allocation after
   startup, assertion scope (programmer errors versus data from disk, the
   network, or a person), explicitly sized integers versus `usize`, error
   handling tiers, naming where the language's standard library differs
   (Zig functions are camelCase), recursion, and the 70-line and 100-column
   limits for generated tables.
3. Show the user that list with a recommended adaptation for each rule and
   wait for the decisions. A rule with no adaptation applies as written.
4. Record the decisions in a section named "How <project> applies
   TigerStyle" between the note and "The Essence Of Style". Write one bullet
   for each adapted rule: the rule's name, `(adapted)`, `(scoped)`, or
   `(narrowed)`, the reason, and what replaces the rule. Leave the copied
   text below it unchanged.
5. Put the rules a machine can check into the repository's lint step
   (formatter check, line length, function length, a reason on each empty
   `catch`). Use the build tool the repository already has; in a Zig
   repository that is a `zig build lint` step.
6. Point to the guide from `AGENTS.md` and the README in one line each.

Done when the copy has its source note, each adapted rule has a recorded
decision from the user, the lint step runs, and both pointers exist.

## Review code against the guide

Read the repository's adaptation section first; an adapted rule is checked
in its adapted form. Report each violation with the rule's name, the file
and line, and the smallest change that fixes it. Group the findings under
the guide's order: safety, performance, developer experience. Do not report
a style preference that the guide does not state.
