---
name: fleetchaser-backend
description: ~/Projects/backend is the Fleetchaser core Django app; backend-investigate + investigate MCP query a nightly prod-mirror DB
metadata: 
  node_type: memory
  type: project
  originSessionId: 21fdf514-e9ba-4f67-9cbb-ce792537d5e7
  modified: 2026-07-23T05:36:26.525Z
---

`~/Projects/backend` is the **Fleetchaser core** — a multi-tenant Django SaaS (40+ apps): PostGIS + a separate telemetry DB, multi-tier Redis, an NSQ "Fleet Worker" queue (**not Celery**), Meilisearch, GCS. Responses camelCase / requests snake_case. Ruff targets py312 (avoid >3.12 syntax) though runtime is 3.14; tests run `manage.py test --keepdb` **inside Docker** with `FCTestCase` + model-bakery `Recipe`s. Has its own CLAUDE.md / AGENTS.md / GEMINI.md.

`~/Projects/backend-investigate` is a near-identical scratch fork (pyproject `name = "backend"`) with an extra `investigate/` app; paired with the `investigate` MCP server (`run_sql`) against a prod-mirror DB refreshed nightly from GCS (`~/import_db.sh`).

See [[server-chezmoi-setup]], [[ops-center]] (contrasting Celery vs NSQ).
