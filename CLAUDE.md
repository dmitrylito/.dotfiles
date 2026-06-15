# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is the **chezmoi source directory** (`~/.local/share/chezmoi`) — the Git-backed source of truth for Dmitry's dotfiles across three machine profiles: **omarchy** (Arch/Hyprland desktop), **mac**, and **server**. There is no build or test suite; "running" this repo means deploying its files into `$HOME` with chezmoi.

`AGENTS.md` (deployed to `~/AGENTS.md`) is the broader home-directory agent guide covering Omarchy, mise, and shell conventions. Read it for rules about operating *in the live home directory*. This file covers working *on the source repo itself*.

## Critical mechanics

- **Files here are templates/sources, not the live files.** A source file named `dot_zshrc.tmpl` becomes `~/.zshrc`. Editing a source file does nothing until you `chezmoi apply`.
- **`autoCommit` and `autoPush` are enabled** (`.chezmoi.toml.tmpl`). `chezmoi apply`/`chezmoi edit` auto-commit and push to GitHub. Direct file edits with other tools do **not** auto-commit — commit manually only when asked.
- **Source naming conventions** (chezmoi): `dot_` → leading `.`; `.tmpl` → rendered as a Go template; `executable_` → `+x`; `run_onchange_` → a script chezmoi executes (not deployed as a file) whenever its rendered content changes.
- **The active profile** is chosen at `chezmoi init` (prompt in `.chezmoi.toml.tmpl`) and read as `.profile`. Templates and `.chezmoiignore` branch on `.profile | lower`.

## Common commands

```bash
chezmoi apply                 # render sources + deploy to $HOME (auto-commits/pushes)
chezmoi apply --dry-run -v    # preview as a diff without touching $HOME — always do this first
chezmoi diff                  # show pending changes
chezmoi managed               # list every target path chezmoi controls
chezmoi status                # unapplied local changes
chezmoi execute-template < file.tmpl   # test that a .tmpl renders (e.g. .chezmoiignore, run_onchange script)
ce <file>                     # alias: chezmoi edit --apply <file> (edit source, deploy on save)
```

After moving/renaming source files, verify with `chezmoi execute-template` (templates) and `chezmoi managed | grep ...` (deployment), and confirm `chezmoi apply --dry-run` is clean before considering a change done.

## Deployment gating (`.chezmoiignore`)

`.chezmoiignore` is itself a template and uses **target ($HOME) paths**, not source paths. It does two jobs:
1. **Per-profile config gating** — e.g. `.config/hypr/`, `.config/waybar/` only deploy on omarchy; `.config/aerospace/`, `.config/sketchybar/` only on mac. If you add a profile-specific config, gate it here or it deploys everywhere.
2. **Keeping repo tooling out of `$HOME`** — `packages/`, `scripts/`, `playbook.yml`, `package-lock.json`, `README.md`, and `.config/tmux/plugins/` live in the repo but must never be deployed. tmux plugins are owned by **tpm**, not chezmoi. `AGENTS.md`/`GEMINI.md` are intentionally *not* ignored (they deploy as global agent guides).

When adding a new top-level tooling file or directory, add it to `.chezmoiignore` or it will land in `$HOME`.

## Package management architecture

Cross-machine package sync is an Ansible-over-chezmoi pipeline:

- **`run_onchange_executable_install-packages.sh.tmpl`** — the entry point. Its header embeds `sha256sum` hashes of `playbook.yml` and every list under `packages/`. When any of those change, the rendered script changes, so chezmoi re-runs it on the next `apply`. It installs Ansible if missing, then runs the playbook (with `sudo` on Linux profiles, without on mac).
- **`playbook.yml`** — profile-aware Ansible playbook. Reads the package lists via `lookup('file', ...)` (paths are `vars` at the top), installs via pacman/yay (omarchy/server) or homebrew (mac), and also bootstraps Oh My Zsh + custom plugins, tmuxifier, and the Claude/Antigravity/Codex CLIs.
- **`packages/{omarchy,mac,server}/`** — the package lists, grouped by platform. `omarchy/base.packages` + `omarchy/other.packages` are Omarchy's shipped reference; the `.txt` files are auto-generated diffs/snapshots.
- **`scripts/update_package_lists.sh`** (run on the omarchy desktop) and **`scripts/update_server_package_lists.sh`** (run on the server, refuses to run off-profile) regenerate the `.txt` lists from the live system.

**If you move or rename anything under `packages/`, update all three reference sites in lockstep:** the `vars` paths in `playbook.yml`, the output paths in `scripts/*.sh`, and the `include "packages/..."` hash lines in the `run_onchange` script. A path mismatch silently breaks installs (Ansible `lookup` errors or the installer never re-triggers).
