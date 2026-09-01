# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is the **chezmoi source directory** (`~/.local/share/chezmoi`) — the Git-backed source of truth for Dmitry's dotfiles across three machine profiles: **omarchy** (Arch/Hyprland desktop), **mac**, and **server**. There is no build or test suite; "running" this repo means deploying its files into `$HOME` with chezmoi.

`AGENTS.md` (deployed to `~/AGENTS.md`) is the broader home-directory agent guide covering Omarchy, mise, and shell conventions. Read it for rules about operating *in the live home directory*. This file covers working *on the source repo itself*.

## Critical mechanics

- **Files here are templates/sources, not the live files.** A source file named `dot_zshrc.tmpl` becomes `~/.zshrc`. Editing a source file does nothing until you `chezmoi apply`.
- **`autoCommit` and `autoPush` are disabled** (`.chezmoi.toml.tmpl`). Applying dotfiles must never publish unreviewed changes or rewritten history. Commit and push deliberately.
- **Source naming conventions** (chezmoi): `dot_` → leading `.`; `.tmpl` → rendered as a Go template; `executable_` → `+x`; `run_onchange_` → a script chezmoi executes (not deployed as a file) whenever its rendered content changes; `modify_` → a script chezmoi runs with the current target on stdin, whose stdout becomes the target.
- **`~/.claude/settings.json` is a `modify_` script, not a tracked file** (`dot_claude/modify_settings.json.tmpl`). Claude Code rewrites that file at runtime (`/model`, `/config`, `/plugin`) and `moshi-hook service install` rewrites its whole hooks block, so tracking it as a file meant permanent drift, an overwrite prompt on every apply, and lost settings. The script merges instead: baseline keys are defaults (`model` is seed-only on purpose), the moshi guard hook wiring is enforced. Do not convert it back to a plain file. `--exclude scripts` does **not** skip `modify_` entries, so `chezmoi-autoupdate` still repairs the wiring.
- **Three files feed Claude Code's config, each via its own `modify_` script.** `dot_claude/modify_settings.json.tmpl` → `~/.claude/settings.json`; `dot_claude/modify_settings.local.json.tmpl` → `~/.claude/settings.local.json`; `modify_private_dot_claude.json.tmpl` → `~/.claude.json` (90KB of per-machine state — machineID, userID, per-project history — so only enforced keys are touched and it writes with no trailing newline and `ensure_ascii=False` to avoid rewriting the whole file every apply). Settings that must be identical everywhere go in `ENFORCED_SCALARS`, not `BASELINE`: `BASELINE` only fills keys the live file lacks, so a box that already wrote the key keeps its old value forever. `outputStyle` is enforced in settings.json **and** stripped from settings.local.json, because `/config` writes it to the Local tier, which outranks User.
- **The active profile and role** are chosen at `chezmoi init`: `.profile` is `omarchy`, `server`, or `mac`; `.work` gates Fleet Chaser tooling independently of platform. Templates and `.chezmoiignore` must respect both dimensions.

## Common commands

```bash
chezmoi apply                 # render sources + deploy to $HOME; never changes packages
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
1. **Per-profile config gating** — e.g. `.config/hypr/` only deploys on omarchy; `.config/aerospace/`, `.config/sketchybar/` only on mac. If you add a profile-specific config, gate it here or it deploys everywhere.
2. **Keeping repo tooling out of `$HOME`** — `packages/`, `scripts/`, `docs/`, `playbook.yml`, `package-lock.json`, and `README.md` live in the repo but must never be deployed. `AGENTS.md` is intentionally *not* ignored (it deploys as the global agent guide).

When adding a new top-level tooling file or directory, add it to `.chezmoiignore` or it will land in `$HOME`.

Hyprland's `hyprland.lua` is a special ownership boundary: `dot_config/hypr/modify_hyprland.lua`
reads Omarchy's currently installed entrypoint and injects `require("hypr.chezmoi")` after
the standard toggles. Keep custom post-default behavior in `dot_config/hypr/chezmoi.lua`;
do not copy Omarchy's entrypoint back into the repository.

## Package management architecture

Package reconciliation is explicit and independent of Chezmoi deployment:

- **`scripts/reconcile-packages.sh`** is the only entry point. It reads the current profile/role and runs the Ansible playbook; Linux uses sudo, macOS does not. Always use `--check` before a real run when lists changed substantially.
- **`playbook.yml`** installs declared packages and removes only names explicitly present in an Omarchy host's `removed.txt`. It never infers deletion from absence and never sweeps orphan dependencies. The AUR block's temporary sudoers rule is restricted to `/usr/bin/pacman *` and removed in `always`.
- **`packages/omarchy/<hostname>/`** contains host-specific desired additions, explicit removals, and reference snapshots. `base.packages`, `other.packages`, and `drivers.txt` are never installed. There is no `untracked.regex` because there is no automatic prune.
- **`packages/server/`** and **`packages/mac/`** hold the corresponding desired sets.
- **`scripts/update_package_lists.sh`** and **`scripts/update_server_package_lists.sh`** regenerate inventories manually. Review their diffs; generation is observation, not policy.

The pacman post-transaction hook, automatic list commit/push, and package `run_onchange` script were intentionally removed. If paths under `packages/` change, update the playbook and generator scripts together. `packages/README.md` is the canonical ownership summary.
