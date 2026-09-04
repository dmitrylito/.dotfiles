# Look up documentation with context7

Use the context7 MCP for library, framework, SDK, API, CLI, or cloud-service docs — syntax,
config options, version migration, setup, library-specific errors. When to call it depends
on how well the tool is known AND how hard the task is:

- Unknown or unfamiliar tool → call context7, even for a simple task.
- Well-known tool, complex task (non-trivial API surface, version-specific behavior,
  migration, obscure config, anything you'd otherwise guess at) → call context7.
- Well-known tool, simple task (routine usage you'd get right from memory) → don't call it.

Mechanics:

- `mcp__context7__resolve-library-id` to get the library ID, then
  `mcp__context7__query-docs` with a specific question. Load both via ToolSearch
  (`select:mcp__context7__resolve-library-id,mcp__context7__query-docs`) if deferred.
- Fall back to WebFetch/WebSearch only when context7 has no entry or returns nothing useful,
  and say so in the answer.
- Exceptions: Claude Code / Anthropic API questions go to the `claude-code-guide` agent or the
  `claude-api` skill; HubSpot platform questions go to the HubSpotDev `search-docs` tool.
- Not for general programming concepts, refactoring, or business-logic debugging.
- Cite what context7 returned; never fill gaps from memory as if they were in the docs.
