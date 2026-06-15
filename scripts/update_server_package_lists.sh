#!/usr/bin/env bash
# Automatically regenerates the server package sync lists for Ansible.
# Run this ON THE SERVER after installing or removing packages, then
# commit/push the chezmoi repo so the server stays reproducible.

set -euo pipefail

CHEZMOI_DIR="$HOME/.local/share/chezmoi"
PACMAN_LIST="$CHEZMOI_DIR/packages/server/pacman.txt"
AUR_LIST="$CHEZMOI_DIR/packages/server/aur.txt"

if ! command -v pacman >/dev/null 2>&1; then
    echo "❌ pacman not found — this script must run on the Arch server." >&2
    exit 1
fi

# Refuse to run on the wrong machine: running this on the Omarchy desktop
# would overwrite the server lists with desktop packages.
profile="$(chezmoi data 2>/dev/null | jq -r '.profile // empty' | tr '[:upper:]' '[:lower:]')"
if [ "$profile" != "server" ]; then
    echo "❌ Refusing to run: chezmoi profile is '${profile:-unset}', not 'server'." >&2
    exit 1
fi

echo "Gathering current system state..."

{
    echo "# Explicitly installed native packages (auto-generated, do not edit by hand)"
    echo "# Regenerate with: scripts/update_server_package_lists.sh"
    pacman -Qenq | sort
} > "$PACMAN_LIST"

{
    echo "# Explicitly installed AUR/foreign packages (auto-generated, do not edit by hand)"
    echo "# Regenerate with: scripts/update_server_package_lists.sh"
    pacman -Qemq | sort
} > "$AUR_LIST"

echo "======================================"
echo "✅ Server Package Lists Updated!"
echo "Pacman: $(grep -cv '^#' "$PACMAN_LIST") packages"
echo "AUR:    $(grep -cv '^#' "$AUR_LIST") packages"
echo "======================================"
