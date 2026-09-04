# Look up documentation with context7 first

Whenever a task needs library, framework, SDK, API, CLI, or cloud-service documentation —
syntax, config options, version migration, setup, library-specific error messages — use the
context7 MCP before anything else, even for tools you think you know. Training data is stale;
context7 returns current docs.

- Call `mcp__context7__resolve-library-id` to get the library ID, then
  `mcp__context7__query-docs` with a specific question. Load both via ToolSearch
  (`select:mcp__context7__resolve-library-id,mcp__context7__query-docs`) if deferred.
- Fall back to WebFetch/WebSearch only when context7 has no entry for the library or returns
  nothing useful — and say so in the answer.
- Exceptions: Claude Code / Anthropic API questions go to the `claude-code-guide` agent or the
  `claude-api` skill; HubSpot platform questions go to the HubSpotDev `search-docs` tool.
- Not for general programming concepts, refactoring, or business-logic debugging — those need
  no doc lookup.
- Cite what context7 returned; never fill gaps from memory as if they were in the docs.
