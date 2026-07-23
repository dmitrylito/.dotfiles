---
name: tooling-preferences
description: Dmitry manages language runtimes via mise and neovim via bob; no pacman node/editor packages
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5d264ace-55b3-4b44-88ee-eec1feec251a
---

On the Arch server (host `dlco`), language runtimes (node, python, uv, and on-demand pnpm/bun) are managed exclusively through **mise**, and neovim is managed exclusively through **bob** (`~/.local/share/bob`, nightly active, `$EDITOR` points there). Pacman's nodejs/npm/pnpm/bun/neovim/vim were deliberately removed (June 2026 audit).

**Why:** avoids duplicate version managers fighting over binaries; was a finding of the package audit.

**How to apply:** never suggest installing node tooling or editors via pacman on this host; use `mise use -g <tool>` or `bob install`. See [[server-chezmoi-setup]].
