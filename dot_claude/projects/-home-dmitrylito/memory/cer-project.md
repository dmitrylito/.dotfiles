---
name: cer-project
description: "cer-backend (+ -production) — roofing-estimate service, Django 6 + Django Ninja, dev vs prod checkouts"
metadata: 
  node_type: memory
  type: project
  originSessionId: 21fdf514-e9ba-4f67-9cbb-ce792537d5e7
  modified: 2026-07-23T05:36:29.529Z
---

`~/Projects/cer-backend` and `~/Projects/cer-backend-production` are **dev and prod checkouts of the same "cer" app**: a roofing-estimate service (Django 6 + Django Ninja; Google Geocoding/Solar → WeasyPrint PDF → email). `cer-backend` is the bind-mounted auto-reload staging env (cer-staging.dlco.us); `cer-backend-production` is baked into the prod gunicorn image. Python 3.14, basedpyright (standard), settings module `config.settings`. Identical CLAUDE.md in both — edit them in lockstep.
