#!/bin/bash
# Sequential per-vehicle pipeline: restart emulator -> import -> replay -> next.
# One vehicle at a time: the local Bigtable emulator (cbtemulator) is in-memory
# and gets OOM-killed by parallel year-long imports (~10KB RAM per reading row).
#
# Usage:
#   run_pipeline.sh <vehicle_ids_csv> <utc_start> <utc_end> [src_instance] [backend_checkout]
# Example:
#   run_pipeline.sh 6508,7677 "2025-07-01 00:00:00" "2026-07-01 04:00:00"
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
VEHICLES="$1"
START="$2"
END="$3"
SRC_INSTANCE="${4:-fleetchaser-default-production}"
CHECKOUT="${5:-/home/dmitrylito/Projects/backend}"
LOG_DIR="${LOG_DIR:-/tmp/state-mileage-import}"
mkdir -p "$LOG_DIR"

export COMPOSE_FILE="$CHECKOUT/docker/docker-compose.yml"
# Worktrees miss gitignored files the containers need.
[ -f "$CHECKOUT/docker/.env" ] || cp /home/dmitrylito/Projects/backend/docker/.env "$CHECKOUT/docker/.env"
[ -f "$CHECKOUT/fc-staging-media.json" ] || cp /home/dmitrylito/Projects/backend/fc-staging-media.json "$CHECKOUT/"
cp "$SKILL_DIR/reprocess_state_mileage.py" "$CHECKOUT/reprocess_state_mileage.py"

IFS=',' read -ra IDS <<< "$VEHICLES"
for id in "${IDS[@]}"; do
  echo "===== vehicle $id: restarting emulator (wipes ALL emulator data) ====="
  docker restart fleetchaser-bigtable-1
  sleep 8

  echo "===== vehicle $id: importing readings ====="
  docker compose run --rm --no-deps backend ./manage.py dev_sync_readings \
    --vehicles="$id" --start="$START" --end="$END" \
    --src-instance-id "$SRC_INSTANCE" \
    > "$LOG_DIR/sync_${id}.log" 2>&1
  echo "import done: $(grep -c Synced "$LOG_DIR/sync_${id}.log" || true) progress lines"

  echo "===== vehicle $id: replaying odometer + rollups ====="
  docker compose run --rm --no-deps \
    -e REPLAY_VEHICLE_IDS="$id" -e REPLAY_LOWER="$START" -e REPLAY_UPPER="$END" \
    backend python manage.py shell -c "exec(open('reprocess_state_mileage.py').read())" \
    > "$LOG_DIR/replay_${id}.log" 2>&1
  grep -E "readings$|miles traveled|deleted|base mile|rollups rebuilt|ALL DONE" "$LOG_DIR/replay_${id}.log"
done

echo "PIPELINE COMPLETE"
