---
name: guidance-architecture
description: "How guidance/memory is organized on dlco — rules/, global CLAUDE.md, auto-memory, and the remember plugin"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 21fdf514-e9ba-4f67-9cbb-ce792537d5e7
  modified: 2026-07-23T05:58:14.784Z
---

Guidance layers on `dlco`, chezmoi-tracked where static:
- **`~/.claude/rules/`** (auto-loaded; chezmoi `dot_claude/rules/`): `code-style`, `chezmoi`, `system`, `memory` (always-on); `python`, `shell`, `django` (path-scoped via `paths:` frontmatter). The `memory` rule tells me to proactively save durable facts. `code-style` requires agent-authored tooling to document itself; `django` requires thin entry points + class-driven services.
- **`~/.claude/CLAUDE.md`** (chezmoi `dot_claude/CLAUDE.md`): orientation + "how I like to work" (verify don't guess; smallest change; match surrounding code).
- **Built-in auto-memory** (this dir): curated FACTS I write. Slug-keyed to the cwd path, so it auto-loads on the machine where that path matches — effectively the server.
- **`remember` plugin**: automatic session continuity via Haiku. External mode `~/.remember/{slug}`, `model: sonnet`, `REMEMBER_BRANCH={{ .profile }}` per machine (server/omarchy/mac). Config in chezmoi `dot_remember/config.json`.

Sibling guides in `~`: AGENTS.md / GEMINI.md (desktop/omarchy/mac-focused — not applicable to this server), SERVER.md (canonical server ops).
