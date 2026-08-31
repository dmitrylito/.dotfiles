#!/usr/bin/env bash
# Render every platform/role combination without changing the live home.

set -euo pipefail

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-render.XXXXXXXX")"
trap 'rm -rf -- "$scratch"' EXIT

for profile in omarchy server mac; do
  for work in false true; do
    destination="$scratch/$profile-$work"
    mkdir -p "$destination"
    printf 'rendering profile=%s work=%s\n' "$profile" "$work"
    chezmoi \
      --source "$source_dir" \
      --destination "$destination" \
      --override-data "{\"profile\":\"$profile\",\"work\":$work}" \
      --no-tty apply --dry-run >/dev/null
  done
done

printf 'all template combinations rendered successfully\n'
