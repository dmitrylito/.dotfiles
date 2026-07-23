# Global instructions

You're working with **Dmitry** on host `dlco` — a headless Arch **server** that's both a
homelab (Docker/Podman stacks, ZFS, GPUs) and the dev host for several Fleetchaser apps.
It's the `server` profile of a multi-machine chezmoi setup; desktop tooling (Omarchy,
Hyprland, Ghostty) is NOT present here.

Behavioral rules live in `~/.claude/rules/` (auto-loaded): code style, chezmoi, tooling,
python, shell, and memory. This file is orientation, not a rule dump.

## How I like to work
- **Verify, don't guess** — especially Claude Code, library, and API facts. Check the docs
  or the code before asserting, and flag anything still unverified.
- **Smallest change that works** — don't restructure, rename, or add abstraction unprompted.
- **Match the surrounding code** — its naming, comment density, and idioms beat defaults.

## Where things live
- Behavioral rules → `~/.claude/rules/`
- Server operations (stacks, ports, ZFS, DB refresh, cleanup) → `~/SERVER.md`
- Persistent facts about me and my projects → auto memory (`MEMORY.md` index)
