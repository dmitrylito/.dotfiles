#!/usr/bin/env bash
#
# Install 50-claude-diagnostics into /etc/sudoers.d.
#
# Purpose:       let non-interactive Claude Code sessions run a fixed set of
#                read-only root diagnostics without a password prompt.
# Usage:         sudo ./install-claude-sudoers.sh [--uninstall]
# Preconditions: run as root, from any cwd; 50-claude-diagnostics must sit
#                next to this script. Idempotent — safe to re-run.
#
# A malformed file in /etc/sudoers.d breaks sudo for every user, so the target
# is validated in place and removed again if the full tree fails to parse.

set -euo pipefail

src_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
src="$src_dir/50-claude-diagnostics"
dest=/etc/sudoers.d/50-claude-diagnostics

if [[ $EUID -ne 0 ]]; then
	echo "must run as root: sudo $0 $*" >&2
	exit 1
fi

if [[ ${1:-} == --uninstall ]]; then
	rm -f "$dest"
	visudo -c >/dev/null
	echo "removed $dest"
	exit 0
fi

[[ -f $src ]] || { echo "missing $src" >&2; exit 1; }

visudo -cf "$src" >/dev/null || { echo "refusing to install: $src does not parse" >&2; exit 1; }

backup=""
if [[ -f $dest ]]; then
	backup=$(mktemp)
	cp -a "$dest" "$backup"
fi

install -o root -g root -m 0440 "$src" "$dest"

if ! visudo -c >/dev/null; then
	if [[ -n $backup ]]; then
		cp -a "$backup" "$dest"
	else
		rm -f "$dest"
	fi
	echo "rolled back: /etc/sudoers.d tree failed to parse with the new file" >&2
	exit 1
fi

[[ -n $backup ]] && rm -f "$backup"

echo "installed $dest"
echo
echo "dmitrylito may now run without a password:"
sudo -l -U dmitrylito | sed -n '/NOPASSWD/,$p'
