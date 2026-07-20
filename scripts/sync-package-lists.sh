#!/usr/bin/env bash
# Pacman PostTransaction hook target (installed by playbook.yml SECTION 7).
# Regenerates the package lists for this machine's profile and commits the
# result, so manual installs/removals flow back into the repo automatically.
# The push is best-effort with a short timeout so the hook never blocks a
# pacman transaction on a dead network; an unpushed commit rides along with
# chezmoi's autoPush on the next chezmoi operation.
set -uo pipefail

# pacman runs PostTransaction hooks SYNCHRONOUSLY and waits for this script
# before handing control back. An AUR install with yay fires several
# transactions back-to-back (build-dep install/remove, then the package), and
# the git push below can stall on the network — doing all that inline made
# pacman/yay hang for seconds after every AUR build. So on first entry we
# re-exec ourselves detached into a new session and return immediately, moving
# the regen/commit/push off pacman's critical path.
if [ -z "${CHEZMOI_SYNC_DETACHED:-}" ]; then
    CHEZMOI_SYNC_DETACHED=1 setsid -f "$0" "$@" </dev/null >/dev/null 2>&1
    exit 0
fi

HOME="$(getent passwd "$(id -un)" | cut -d: -f6)"
export HOME
CHEZMOI_DIR="$HOME/.local/share/chezmoi"

# Serialize concurrent syncs. Wait (rather than skip) so the worker spawned by
# the LAST transaction of a multi-transaction AUR build still runs and captures
# the final package state; a run that finds nothing changed just commits nothing.
# Backgrounded, so this wait never blocks pacman.
exec 9>"/tmp/chezmoi-package-sync-$(id -u).lock"
flock -w 60 9 || exit 0

# The rendered chezmoi config records the machine profile chosen at init.
profile="$(grep -oP '^\s*profile\s*=\s*"\K[^"]+' "$HOME/.config/chezmoi/chezmoi.toml" 2>/dev/null | head -1)"

case "${profile}" in
    omarchy)
        # Without expac the removed-list diff would be silently wrong — bail
        # rather than auto-commit a bogus regeneration.
        command -v expac >/dev/null 2>&1 || exit 0
        "$CHEZMOI_DIR/scripts/update_package_lists.sh" >/dev/null
        ;;
    server)
        "$CHEZMOI_DIR/scripts/update_server_package_lists.sh" >/dev/null
        ;;
    *)
        exit 0
        ;;
esac

cd "$CHEZMOI_DIR" || exit 0
if [ -n "$(git status --porcelain -- packages/)" ]; then
    git add packages/
    git commit -q -m "Auto-sync package lists (pacman hook)"
    timeout 15 git push -q >/dev/null 2>&1 || true
fi
