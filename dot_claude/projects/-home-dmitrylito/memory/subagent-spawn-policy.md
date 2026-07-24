---
name: subagent-spawn-policy
description: Dmitry wants agents to self-judge whether a subagent spawn is worth it, not ask permission or follow a blanket model pin
metadata:
  node_type: memory
  type: feedback
---

Dmitry wants subagent use governed by an **autonomous cost/benefit judgement**, not by a
prohibition he has to override each time and not by a global model pin. Encoded as
`~/.claude/rules/subagents.md` plus a haiku-backed `lookup` agent (dotfiles PR #2,
July 2026).

**Why:** he was burning tokens on subagents spawned for trivial lookups, but "never spawn
unless asked" (the gate the background-job launcher injects) made every legitimate fan-out
manual. He explicitly wants "less manual, but better and faster, and use less tokens."
`CLAUDE_CODE_SUBAGENT_MODEL` was rejected on inspection: it short-circuits *before* the
per-call `model` param, so it pins rather than caps — it would make Haiku unreachable for
the cheap lookups and would override the `code-simplifier` plugin's deliberate `model: opus`.

**How to apply:** decide each spawn against the test in the rule (does delegating spare me
from reading material I'd discard?) and act on it silently — do not ask, and do not narrate
spawns ruled out. Prefer `lookup` for mechanical location. Note the real cost driver is the
per-spawn cold-start context, not the model tier. See [[claude-code-setup]] and
[[guidance-architecture]].
