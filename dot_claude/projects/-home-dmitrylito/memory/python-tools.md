---
name: python-tools
description: "Map of the smaller ~/Projects Python tools (billingapp, owlcam, spotify-cli, chat-export, openclaw)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 21fdf514-e9ba-4f67-9cbb-ce792537d5e7
  modified: 2026-07-23T05:36:41.097Z
---

Smaller tools under `~/Projects` (all uv):
- **billingapp** — Streamlit app (container-only) for reviewing billable hardware / generating billing payloads. ruff ll=100.
- **owlcam** — Textual TUI + CLI for the Owlcam/Xirgo DVR partner video API. ⚠️ talks to a **LIVE production API with a baked-in shared prod key**; deletes are destructive — **mock them**, don't run live. No test suite.
- **spotify-cli** — uv CLI managing Dmitry's own Spotify playlists via OAuth, meant to be driven through Claude Code (pairs with the Spotify connector).
- **chat-export** — single-file PEP 723 script pulling Fleetchaser chat DMs/channels over REST.
- **openclaw** — an AI-agent *workspace* (not a codebase); contains `auth-secrets/` — don't open.
