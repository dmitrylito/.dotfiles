# Dmitry's dotfiles

Chezmoi manages one shared configuration across `omarchy`, `server`, and `mac`
profiles. A separate `work` role enables Fleet Chaser tooling without encoding
work ownership in a hostname. The source of truth is this directory; do not edit
managed targets in `$HOME` directly.

## Bootstrap and safe daily use

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply dmitrylito
chezmoi status
chezmoi diff
chezmoi apply --dry-run -v
```

Initialization asks for a platform profile and whether the machine has the work
role. `ce <target>` is the shell alias for `chezmoi edit --apply <target>`.
Chezmoi Git auto-commit and auto-push are deliberately disabled so an apply
cannot publish unreviewed configuration or rewritten history.

## Configuration dimensions

| Profile | Platform layer | Shared layer |
|---|---|---|
| `omarchy` | Hyprland, Omarchy shell, Linux desktop apps | shell, editor, Herdr, Moshi, AI tooling |
| `server` | headless Arch packages and user services | shell, editor, Herdr/Moshi support |
| `mac` | AeroSpace, SketchyBar, Borders, macOS apps | shell, editor, Herdr/Moshi clients |

`work = true` adds the Fleet Chaser project environment, mypy/import helpers,
Claude work skills, work launchers, and the Omarchy work layout. `.chezmoiignore`
is the single deployment boundary for both profile and role.

## Package reconciliation

Package changes are explicit and separate from dotfile deployment:

```bash
scripts/update_package_lists.sh   # regenerate the current Omarchy host inventory
scripts/reconcile-packages.sh --check
scripts/reconcile-packages.sh     # install declared and remove removed.txt entries
```

`chezmoi apply` never invokes sudo or changes packages. The Ansible playbook:

- installs packages listed for the active profile;
- removes only names explicitly placed in an Omarchy host's `removed.txt`;
- never prunes undeclared packages or sweeps orphan dependencies;
- treats Omarchy base/other/driver snapshots as reference data only;
- temporarily permits the AUR build user to invoke `/usr/bin/pacman`, not an
  unrestricted root command.

See `packages/README.md` for list ownership and regeneration rules.

## Major subsystems

- `.chezmoi.toml.tmpl` and `.chezmoiignore`: profile/role selection and target
  routing.
- `dot_zshenv.tmpl`, `dot_zshrc.tmpl`, `dot_aliases.tmpl`: shared environment,
  interactive shell, and role-gated aliases.
- `dot_config/mise/config.toml`: authoritative runtimes and CLI tools.
- `dot_config/herdr/`: universal terminal workspace/multiplexer. tmux,
  Tmuxifier, and sesh are intentionally retired.
- `dot_local/bin/moshi-*`, Moshi hook modifiers, and Linux user units: keep
  Claude/Codex conversations bound to the correct Herdr pane. macOS receives
  the guards and config, but vendor pairing/service setup remains platform
  specific.
- `dot_config/nvim/`: LazyVim configuration, including the Sidekick `agy`
  adapter and one canonical remote clipboard implementation.
- `dot_config/hypr/` and `dot_config/omarchy/`: Omarchy-only desktop behavior.
  The Hyprland entrypoint is derived from Omarchy's installed default by a
  `modify_` script; chezmoi owns only the post-default `hypr.chezmoi` module.
- `dot_config/aerospace/`, `dot_config/sketchybar/`, `dot_config/borders/`:
  macOS-only desktop behavior.
- `dot_claude/`, `dot_codex/`, `dot_config/opencode/`: agent settings, hooks,
  rules, and plugins.
- `Projects/fleetchaser/`, Fleet Chaser helpers/skills, work launchers, and
  `work-mode`: work-role-only configuration.

## Local binary ownership

`docs/local-bin-audit.md` records every current `~/.local/bin` category, its
owner, its consumer, and the cleanup decision. New custom scripts should be
added under `dot_local/bin/executable_*`; vendor binaries stay vendor-owned and
CLI tools should be declared in mise instead of wrapped by ad-hoc scripts.

## Validation before applying

Render all six profile/role combinations, then preview only the active machine:

```bash
scripts/test-templates.sh
chezmoi apply --dry-run -v
```

The dry run matters because live target drift can be intentional. A global
apply should not be used to erase drift that was not part of the current task.

Git history still requires a separate coordinated rewrite to purge old
Elephant provider binaries. That operation changes commit IDs and requires an
intentional force-push plus fresh clones; it is not part of normal cleanup.
