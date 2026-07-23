---
name: ops-center
description: "~/Projects/ops-center (\"fcops\") — Django + Celery ops command center, pgvector RAG, pytest"
metadata: 
  node_type: memory
  type: project
  originSessionId: 21fdf514-e9ba-4f67-9cbb-ce792537d5e7
  modified: 2026-07-23T05:36:33.609Z
---

`~/Projects/ops-center` ("fcops"; formerly fcbot, migrated from FastAPI Jul 2026) is an ops command center: Django + **Celery**, Postgres/pgvector RAG, local Gemma triage, Linear/HubSpot/Sentry MCP. Python 3.14 (<3.15), ruff ll=80, tests via **pytest** (`uv run pytest`, `fcops.test_settings`), `make deploy`, served at fcbot.dlco.us. Heaviest pre-commit of the repos; large operational CLAUDE.md.

⚠️ Unlike [[fleetchaser-backend]] (NSQ, Docker `manage.py test`), this repo uses Celery + pytest — never assume one queue or test runner across the Django repos.
