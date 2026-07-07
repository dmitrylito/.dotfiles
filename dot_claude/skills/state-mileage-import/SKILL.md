---
name: state-mileage-import
description: Import production readings for specific vehicles into local dev and regenerate accurate state mileage reports (HourlyStateMileageRollup). Use when the user asks to import/sync vehicle readings, fix or regenerate state mileage / IFTA report data locally, or reprocess odometer miles for vehicles.
---

# State Mileage Import & Reprocess

Imports raw production readings for given vehicles into the local Bigtable
emulator, replays them through the vehicle state machine to regenerate
`tracker.Odometer` rows, and rebuilds `reports.HourlyStateMileageRollup` —
the table the State Mileage / IFTA report reads.

## Inputs to collect from the user

- Vehicle names (e.g. `R-01, DT-06`) or PKs, and the customer if names are ambiguous
- Report date range and its timezone (usually the customer's, e.g. `America/New_York`)

## Steps

### 1. Resolve vehicles and window

```sql
SELECT v.id, v.identifier, c.name, c.timezone
FROM vehicle_vehicle v JOIN accounting_customer c ON c.id = v.customer_id
WHERE v.identifier ILIKE 'R-01%' AND v.deleted IS NULL;
```

Vehicle identifiers often have VIN suffixes (`R-01 1M2AA18Y...`) and deleted
same-named duplicates — match by prefix, filter `deleted IS NULL`.

Convert the report range to a UTC import window (naive `--start/--end` params
are UTC; containers run UTC). E.g. Jul 1 2025 – Jun 30 2026 ET →
`"2025-07-01 00:00:00"` – `"2026-07-01 04:00:00"` (pad the start a few hours
early so the state machine warms up before the report window).

### 2. Run the pipeline (sequential, one vehicle at a time)

```bash
bash .claude/skills/state-mileage-import/run_pipeline.sh \
  "6508,7677,6507" "2025-07-01 00:00:00" "2026-07-01 04:00:00"
```

Run in the background (a year of one vehicle ≈ 200k–850k readings, ~5–15 min
each) and monitor the output. Optional args 4/5: source Bigtable instance
(default `fleetchaser-default-production`) and backend checkout path (default
main checkout; pass a worktree to run different code — the script copies the
gitignored `docker/.env` and GCP creds into it).

**Never parallelize imports**: the emulator is in-memory and gets OOM-killed
around ~2M rows (~10KB/row); every restart silently wipes ALL emulator data.
The pipeline restarts the emulator per vehicle deliberately — anything else in
the emulator is disposable.

### 3. Verify

Per vehicle, the replay log must show a readings count matching the import
(`import done` lines × 1000 ≈ readings) — a shortfall means data was lost
mid-replay; rerun that vehicle. Then check totals (hours are UTC):

```sql
SELECT v.identifier, h.state, sum(h.traveled) AS miles
FROM reports_hourlystatemileagerollup h JOIN vehicle_vehicle v ON v.id = h.vehicle_id
WHERE h.vehicle_id IN (...) AND h.hour >= '<utc_start>' AND h.hour < '<utc_end>'
GROUP BY 1, 2 ORDER BY 1, 3 DESC;
```

Sanity: max(traveled) per hour should be < ~80; a single huge hour means mile
numbering broke. A vehicle with readings but 0 miles may genuinely be parked —
check a sample: all `movement_type` parked + frozen `gps_meters_odometer`
means the truck really isn't moving.

### 4. Protect against the nightly DB refresh

The local dev DB is refreshed nightly, wiping regenerated rows. Offer to dump
them (`\copy` of `tracker_odometer` + `reports_hourlystatemileagerollup` for
the vehicles/window) with a restore script — see
`~/mileage-report-backup/restore.sh` for a working example (transactional
delete+copy, then `setval` both id sequences).

## Why this approach (don't "simplify" to these)

- `reprocess_vehicle_stats` requires a migration-reason TrackerInstall
  (`installs.get(reason='mig')` raises for most vehicles) and mutates installs.
- `pipeline.tasks.ReprocessVehicleInRange` does NOT regenerate odometer miles —
  for a list of readings, `ReadingIntake.process` never runs `OdometerProcessor`.
- The bundled `reprocess_state_mileage.py` replays through
  `VehicleStateManager` + `InMemoryBackend` (no live-state side effects),
  forces GPS odometer source (like `reprocess_vehicle_stats`), anchors mile
  numbers (devices can initialize with a one-time odometer jump; `Odometer`
  is unique on `(vehicle, mile)` so numbering continues from the last
  pre-window mile), and rebuilds rollups via `add_odometer` in created order.

## Viewing in the frontend

Report page: `https://console.dlco.us/reports/ifta` (Reports → State Mileage),
after logging in and switching into the vehicles' customer. If console.dlco.us
is 502: start the dev server (nginx proxies port 4200; `PORT=8083` is exported
in the shell, so unset it):
`cd ~/Projects/frontend && unset PORT && bunx ng serve frontend -c local --host 0.0.0.0 --port 4200`
(needs `allowedHosts: ["console.dlco.us"]` under the serve target options in
`angular.json`). If the main frontend checkout doesn't compile, serve from a
clean worktree and copy in the gitignored `src/environments/environment.local.ts`.
