---
name: frontend-fleetchaser
description: "~/Projects/frontend — Fleetchaser Angular 22 web app; package manager is bun (NOT npm), tests are vitest"
metadata: 
  node_type: memory
  type: project
  originSessionId: 21fdf514-e9ba-4f67-9cbb-ce792537d5e7
  modified: 2026-07-23T05:36:37.241Z
---

`~/Projects/frontend` is the Fleetchaser web app: **Angular 22** (standalone, signals, zoneless-leaning), TS 6, RxJS 7, Angular Material + CDK, Tailwind 4.

⚠️ Gotchas that differ from the usual defaults:
- Package manager is **`bun`** (mise-pinned, `bun.lock`) — NOT npm/pnpm.
- Tests are **vitest**, not Karma.
- Prefers a custom signal `Store<T>` over NgRx (and is **not** migrating to `@ngrx/signals`).
- Component prefix `fc-`, OnPush; `tsconfig` `strict: false`; ESLint intentionally lenient.
