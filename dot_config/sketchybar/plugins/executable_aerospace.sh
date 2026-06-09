#!/bin/sh

# $1 is the workspace number passed from sketchybarrc (e.g., "1", "2", ...)
# $FOCUSED_WORKSPACE is passed from AeroSpace's event trigger

# If FOCUSED_WORKSPACE is not set (e.g., at sketchybar startup), fetch it directly from aerospace
if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.drawing=on
else
    sketchybar --set "$NAME" background.drawing=off
fi
