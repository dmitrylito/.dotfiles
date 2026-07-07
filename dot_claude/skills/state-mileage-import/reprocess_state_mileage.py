"""Regenerate odometer miles and hourly state mileage rollups from imported readings.

Replays readings (imported into the local Bigtable emulator via dev_sync_readings)
through the vehicle state machine with an in-memory backend — modeled on
reprocess_vehicle_stats, but works for any vehicle (no migration install needed).

Parameterized via environment variables:
    REPLAY_VEHICLE_IDS  comma-separated vehicle PKs (required)
    REPLAY_LOWER        UTC start "YYYY-MM-DD HH:MM:SS" (required, match import --start)
    REPLAY_UPPER        UTC end   "YYYY-MM-DD HH:MM:SS" (required, match import --end)

Run inside the backend container (repo root must contain this file):
    python manage.py shell -c "exec(open('reprocess_state_mileage.py').read())"
"""

import os
from datetime import datetime, UTC

import united_states

from pipeline.tasks.utils import reprocess_readings
from reports.models import HourlyStateMileageRollup
from tracker.models import Odometer
from vehicle.models import Vehicle
from vehicle.state.backends import InMemoryBackend
from vehicle.state.manager import VehicleStateManager
from vehicle.state.models import OdometerSource
from vehicle.state.processors.odometer import OdometerProcessor

us = united_states.UnitedStates()


def _env_dt(name: str) -> datetime:
    return datetime.strptime(os.environ[name], "%Y-%m-%d %H:%M:%S").replace(tzinfo=UTC)


IMPORT_LOWER = _env_dt("REPLAY_LOWER")
IMPORT_UPPER = _env_dt("REPLAY_UPPER")
VEHICLE_IDS = [int(v) for v in os.environ["REPLAY_VEHICLE_IDS"].split(",")]


def state_at(point):
    try:
        return us.from_coords(point.y, point.x)[0].abbr
    except IndexError:
        return None


def replay_vehicle(vehicle: Vehicle) -> None:
    collected: list[dict] = []

    class CollectingOdometerProcessor(OdometerProcessor):
        def on_mile(self, source, reading, state, miles):
            collected.append(
                {"reading": reading, "mile": miles - state.starting_odometer}
            )

    backend = InMemoryBackend()
    state = backend.get_state(vehicle.pk)
    # Same forced source as reprocess_vehicle_stats: GPS is always present.
    state.odometer_source = OdometerSource.gps
    backend.save_state(state)
    manager = VehicleStateManager(vehicle, backend=backend)

    readings = reprocess_readings(vehicle, IMPORT_LOWER, IMPORT_UPPER)
    print(f"[{vehicle.pk}] {vehicle.identifier}: {len(readings)} readings", flush=True)

    for reading in readings:
        if not reading.is_traveling:
            continue
        with manager.process_reading(reading) as (active_reading, _):
            if active_reading:
                CollectingOdometerProcessor(manager.state).process(active_reading)

    print(f"[{vehicle.pk}] {len(collected)} miles traveled in window", flush=True)

    # The state machine can initialize the device odometer with a one-time jump,
    # uniformly offsetting every collected mile number. Deltas are what matter:
    # anchor the first mile at 1 (same idea as reprocess_vehicle_stats' MAX anchor).
    if collected:
        offset = min(c["mile"] for c in collected) - 1
        for c in collected:
            c["mile"] -= offset

    # mile is unique per vehicle; continue numbering from the last pre-window mile.
    base = (
        Odometer.objects.filter(vehicle=vehicle, created__lt=IMPORT_LOWER)
        .order_by("-mile")
        .values_list("mile", flat=True)
        .first()
    ) or 0

    deleted = Odometer.objects.filter(
        vehicle=vehicle, created__gte=IMPORT_LOWER
    ).delete()
    print(
        f"[{vehicle.pk}] deleted {deleted[0]} stale odometer rows, base mile {base}",
        flush=True,
    )

    Odometer.objects.bulk_create(
        [
            Odometer(
                vehicle=vehicle,
                source=OdometerSource.gps,
                created=m["reading"].ts,
                point=m["reading"].point,
                mile=base + m["mile"],
                state=state_at(m["reading"].point),
                reading_key=m["reading"].pk,
            )
            for m in collected
        ],
        batch_size=1000,
    )

    rollups_deleted = HourlyStateMileageRollup.objects.filter(
        vehicle=vehicle, hour__gte=IMPORT_LOWER
    ).delete()
    print(f"[{vehicle.pk}] deleted {rollups_deleted[0]} stale rollups", flush=True)

    for odom in (
        vehicle.odometer.filter(created__gte=IMPORT_LOWER)
        .order_by("created")
        .iterator()
    ):
        HourlyStateMileageRollup.objects.add_odometer(odom)

    print(f"[{vehicle.pk}] rollups rebuilt", flush=True)


for vehicle_id in VEHICLE_IDS:
    replay_vehicle(Vehicle.objects.get(pk=vehicle_id))

print("ALL DONE", flush=True)
