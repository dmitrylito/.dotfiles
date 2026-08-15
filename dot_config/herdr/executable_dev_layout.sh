#!/usr/bin/env bash
# Recreate the tmuxifier "Dev" layout in herdr: nvim (top-left), shell
# (bottom-left, 20%), agent (right, 35%). Bound to `prefix+shift+t` in
# config.toml as a shell command; herdr sets HERDR_ACTIVE_PANE_CWD.
# Requires: herdr, jq.

set -euo pipefail

cwd="${HERDR_ACTIVE_PANE_CWD:-$PWD}"

tab=$(herdr tab create --cwd "$cwd" --label Dev --focus)
main=$(jq -r '.result.root_pane.pane_id' <<<"$tab")

right=$(herdr pane split "$main" --direction right --ratio 0.35 --cwd "$cwd" --no-focus |
	jq -r '.result | .. | .pane_id? // empty' | head -1)
herdr pane split "$main" --direction down --ratio 0.20 --cwd "$cwd" --no-focus >/dev/null

sleep 0.5
herdr pane run "$main" nvim >/dev/null
herdr pane run "$right" gemini >/dev/null
herdr pane focus "$main" >/dev/null 2>&1 || true
