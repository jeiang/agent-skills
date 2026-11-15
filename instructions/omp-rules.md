- Change a file with `edit` and create one with `write`. Do not rewrite a
  file from a Python, sed, or perl script in `bash`, except a file on
  another host.
- Run ad hoc Python in `eval`, not as `python -c` or a heredoc in `bash`.
  `eval` starts in the session directory: for a worktree, use absolute paths
  or start the cell with `%cd <worktree>`.
- Python in `bash` is for repository scripts, for a stage that reads piped
  input, and for code that needs a project interpreter or its packages.
- When your tool list has no `edit` or `eval`, `bash` is correct.
