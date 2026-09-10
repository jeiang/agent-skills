# Generic environment

No operating system, language stack, or tool availability is assumed. Inspect
the repository and the shell before relying on a tool or a convention.

When the repository declares a development environment, such as a Nix shell,
a container definition, or a version manager file, resolve that environment
before running its commands. Use the tools it provides.

Before fetching tools outside the declared environment or creating an ad hoc
substitute for a missing validator, obtain the user's approval unless that use
is already authorized in this task. Prefer temporary use to permanent
installation. Explain what the tool or substitute will establish and what it
cannot verify.

Checks must exercise the changed files. If the environment cannot run them,
report the limitation and the exact command or test still needed.
