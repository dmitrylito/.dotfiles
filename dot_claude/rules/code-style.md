# Code style

Default to no comments and no docstrings — well-named functions, variables, and small
focused units are the documentation. A repo's own CLAUDE.md/style guide wins if it says so.

- Comment only to prevent a real mistake: a non-obvious constraint, a footgun, a subtle
  invariant not visible in the code. Explaining *why* can justify a comment; explaining
  *what* the code plainly does never does — that's noise.
- Keep any necessary comment to one short line; put longer context in the commit/PR.
- No ordered/step markers (`# 1. …`, `# now …`) — the structure already shows the flow.
- Docstrings only for a real public contract or non-obvious boundary, never boilerplate
  that echoes the signature.
- Functional "comments" are code — never strip `# type: ignore`, `# noqa`, `# pragma`,
  `# fmt: off/on`, shebangs, or encoding lines.
