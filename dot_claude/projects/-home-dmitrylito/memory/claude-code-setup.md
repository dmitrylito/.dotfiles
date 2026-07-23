---
name: claude-code-setup
description: "Claude Code config on dlco — native install, auto mode, moshi-hook, plugins, lsp-marketplace experiment"
metadata: 
  node_type: memory
  type: project
  originSessionId: 21fdf514-e9ba-4f67-9cbb-ce792537d5e7
  modified: 2026-07-23T05:36:45.097Z
---

Claude Code on `dlco`: **native install** 2.1.218 (the `/usr/bin/claude` pacman package 2.1.201 is a stale shadow — remove with `sudo pacman -R claude-code`; conflicts with [[tooling-preferences]]). Auto mode is the default permission mode; **auto-compact is off** so the `remember` plugin's save pipeline can capture history. All user hooks are one native binary, `moshi-hook`. 12 plugins enabled (heavy use: pyright-lsp; also remember, security-guidance).

`~/lsp-marketplace` is a local plugin marketplace built for a 3-arm pyright/djlsp accuracy experiment; djlsp is its unique value (official `pyright-lsp` already covers pyright, so `pyright-plugin` was left disabled). See [[guidance-architecture]].
