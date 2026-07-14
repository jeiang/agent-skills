#!/usr/bin/env python3
"""Validate that installer cleanup traps claim cleanup before doing other work."""

import re
from pathlib import Path


source = Path("install.sh").read_text(encoding="utf-8")
trap_lines = [line for line in source.splitlines() if line.startswith("trap '")]
expected = {
    "EXIT": "$?",
    "HUP": "129",
    "INT": "130",
    "TERM": "143",
}

if len(trap_lines) != len(expected):
    raise SystemExit(f"expected {len(expected)} production traps, found {len(trap_lines)}")

first_trap = source.index("trap '")
initialization = source[:first_trap]
for variable in ("cleanup_status", "cleanup_active", "resource_transition", "cleanup_pending"):
    if not re.search(rf"^{variable}=[0-9]+$", initialization, re.MULTILINE):
        raise SystemExit(f"{variable} must be initialized to a literal before traps are installed")

for line in trap_lines:
    match = re.fullmatch(r"trap '([^']*)' (EXIT|HUP|INT|TERM)", line)
    if match is None:
        raise SystemExit(f"trap must use one literal single-quoted action: {line}")
    action, signal = match.groups()
    first_command = action.split(";", 1)[0]
    required = (
        f'cleanup_status={expected[signal]} cleanup_active=1 '
        'trap "" HUP INT TERM'
    )
    if first_command != required:
        raise SystemExit(
            f"{signal} trap must begin with the inline cleanup claim: {required}"
        )

    if not re.fullmatch(
        r'cleanup_status=(?:\$\?|129|130|143) cleanup_active=1 trap "" HUP INT TERM',
        first_command,
    ):
        raise SystemExit(f"{signal} cleanup claim contains an unsafe expression")

print("Installer trap validation passed.")
