#!/usr/bin/env bash

sketchybar --set "$NAME" label="${INFO:-$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null | head -1)}"
