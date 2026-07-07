# Global instructions

## Docstrings and comments

Follow this for all code, in every project (a repo's own CLAUDE.md/style guide wins if it says otherwise):

- **Docstrings**: Write docstrings for public modules, functions, classes, and methods (PEP 257).
- **Comments**: Use comments only to explain complex or non-obvious code — the *why*, not the *what*. Avoid redundant comments that restate the code.
- **No ordered/step comments**: Don't use comments that imply sequence (e.g. `# 1. Download phase`, `# now filter`, `# return result`) when the code structure already makes the flow clear. Let the code speak for itself.

## Python package management

Use `uv` for all Python projects — never `pip` (a repo's own CLAUDE.md/tooling wins if it says otherwise):

- **Never `pip`**: Don't run `pip install`, `pip freeze`, or `python -m pip`. Use the `uv` equivalents.
- **Dependencies**: Add/remove with `uv add` / `uv remove`; install/sync from lockfile with `uv sync`. Keep `pyproject.toml` + `uv.lock` as the source of truth (no `requirements.txt` unless a project already uses one).
- **Running code**: Use `uv run <cmd>` instead of activating a venv and calling `python`/tools directly.
- **New projects**: Scaffold with `uv init`; manage Python versions with `uv python`.
