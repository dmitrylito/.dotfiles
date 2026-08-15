#!/usr/bin/env bash
# Automatically regenerates the package sync lists for Ansible

CHEZMOI_DIR="$HOME/.local/share/chezmoi"

# Refresh the tracked reference from the installed Omarchy. Without this the
# reference stays at whatever version it was copied from, and every package a
# later Omarchy release adds to its defaults looks like one the user installed
# (the v4 update alone put 31 of its own defaults into added-*.txt).
# Lists are per host: every Omarchy box regenerates them from its own system, so
# a single shared copy would make each machine's run overwrite the other's, and
# the playbook's prune would then uninstall whatever the last writer lacked.
HOST="$(hostname -s 2>/dev/null || uname -n)"
OUT_DIR="$CHEZMOI_DIR/packages/omarchy/$HOST"
mkdir -p "$OUT_DIR"

OMARCHY_BASE="$OUT_DIR/base.packages"
OMARCHY_OTHER="$OUT_DIR/other.packages"
OMARCHY_SRC="/usr/share/omarchy/install"
[ -f "$OMARCHY_SRC/omarchy-base.packages" ] && cp "$OMARCHY_SRC/omarchy-base.packages" "$OMARCHY_BASE"
[ -f "$OMARCHY_SRC/omarchy-other.packages" ] && cp "$OMARCHY_SRC/omarchy-other.packages" "$OMARCHY_OTHER"

# The regex used to identify hardware-specific packages that shouldn't sync across machines.
# GPU compute stacks (CUDA, ROCm/HIP) count as drivers: they're multi-GB and only valid on
# the vendor whose card the machine actually has, so they belong in drivers.txt (reference
# only, never installed by the playbook) rather than in the shared added-* lists.
# The ROCm/HIP tokens are anchored — an unanchored `hip` also matches `starship`.
DRIVER_REGEX='nvidia|amd|intel|vulkan|apple|macbook|t2|tuxedo|firmware|dkms|kernel|modules|asus|broadcom|thermald|ptl|dfr|vpl|debug|cuda|cudnn|migraphx|miopen|comgr|nccl|rccl|^roc|^hip(-|$)|^hipblas|^hipcub|^hipfft|^hiprand|^hipsolver|^hipsparse|^hsa-|^hsakmt'
# Repo-/machine-specific packages that only exist in special repos not configured
# on every machine (e.g. the CachyOS kernel + its keyring/mirrorlists). Syncing
# these into the shared lists breaks `chezmoi apply` on machines without those
# repos ("target not found"), so they're dropped from every generated list —
# each machine manages its own kernel.
REPO_SPECIFIC_REGEX='^cachyos|^linux-cachyos'
# Debug split-packages (e.g. `gputest-debug`) are local build artifacts created
# by makepkg when building from the AUR with debug options. They're registered
# in the local pacman DB but exist in NO repo, so syncing them makes the install
# fail on other machines ("could not find or read package"). Drop them from every
# generated list. NOTE: matched by suffix so it also strips them out of drivers.txt
# even though they'd otherwise match the `debug` token in DRIVER_REGEX.
DEBUG_PKG_REGEX='\-debug$'
# The regex used to identify pre-installed packages that can be removed
PREINSTALL_REGEX='aether|cliamp|typora|spotify|libreoffice-fresh|1password-beta|1password-cli|xournalpp|signal-desktop|pinta|obsidian|obs-studio|kdenlive|lazydocker|opencode|claude-code|alacritty|htop|nvim|dart|jdk-openjdk|sassc|libsass|intltool|autoconf-archive|webp-pixbuf-loader'

echo "Gathering current system state..."

grep -v '^#' "$OMARCHY_BASE" | grep -v '^$' | grep -vE "$DRIVER_REGEX" | grep -vE "$PREINSTALL_REGEX" > /tmp/omarchy_ref.txt
if [ -f "$OMARCHY_OTHER" ]; then
    grep -v '^#' "$OMARCHY_OTHER" | grep -v '^$' | grep -vE "$DRIVER_REGEX" | grep -vE "$PREINSTALL_REGEX" >> /tmp/omarchy_ref.txt
fi

# -Qet, not -Qe: a package that something else hard-depends on is not a choice,
# it is a dependency that happens to be flagged explicit. Tracking those put 71
# packages (zsh, neovim, fontconfig, ...) into the "I installed this" lists; the
# dependency graph reinstalls them on a new machine anyway.
pacman -Qetnq > /tmp/current_native_explicit.txt
pacman -Qetmq > /tmp/current_aur_explicit.txt
# drivers.txt is reference only and never installed, so it wants every hardware
# package present — including the ones -Qet hides because something depends on
# them (vulkan-radeon <- steam, cuda <- cudnn).
cat <(pacman -Qenq) <(pacman -Qemq) > /tmp/all_explicit.txt
expac -Q '%n %p' | tr ' ' '\n' | sort -u > /tmp/current_all_installed_and_provides.txt

echo "Calculating differences..."

grep -iE "$DRIVER_REGEX" /tmp/all_explicit.txt | grep -ivE "$REPO_SPECIFIC_REGEX" | grep -ivE "$DEBUG_PKG_REGEX" | sort > "$OUT_DIR/drivers.txt"

grep -vxFf /tmp/omarchy_ref.txt /tmp/current_native_explicit.txt | grep -ivE "$DRIVER_REGEX" | grep -ivE "$PREINSTALL_REGEX" | grep -ivE "$REPO_SPECIFIC_REGEX" | grep -ivE "$DEBUG_PKG_REGEX" | sort > "$OUT_DIR/added-pacman.txt"

grep -vxFf /tmp/omarchy_ref.txt /tmp/current_aur_explicit.txt | grep -ivE "$DRIVER_REGEX" | grep -ivE "$PREINSTALL_REGEX" | grep -ivE "$REPO_SPECIFIC_REGEX" | grep -ivE "$DEBUG_PKG_REGEX" | sort > "$OUT_DIR/added-aur.txt"

grep -vxFf /tmp/current_all_installed_and_provides.txt /tmp/omarchy_ref.txt | sort > "$OUT_DIR/removed.txt"

# Everything the lists above deliberately exclude. The playbook's prune must
# treat "untracked on purpose" as protected, or it would remove this machine's
# drivers, its kernel, and the pre-installs (spotify, dart, ...) that are
# filtered out of added-*.txt by design. Emitted rather than duplicated in the
# playbook so the patterns have one definition; they match names, not this
# machine's packages, so the file is portable to the other Omarchy box.
printf '%s\n' "$DRIVER_REGEX" "$REPO_SPECIFIC_REGEX" "$DEBUG_PKG_REGEX" "$PREINSTALL_REGEX" \
    > "$OUT_DIR/untracked.regex"

rm /tmp/omarchy_ref.txt /tmp/current_native_explicit.txt /tmp/current_aur_explicit.txt /tmp/all_explicit.txt /tmp/current_all_installed_and_provides.txt

echo "======================================"
echo "✅ Package Lists Updated Successfully!"
echo "Added Pacman:  $(wc -l < "$OUT_DIR/added-pacman.txt") packages"
echo "Added AUR:     $(wc -l < "$OUT_DIR/added-aur.txt") packages"
echo "Removed:       $(wc -l < "$OUT_DIR/removed.txt") packages"
echo "Local Drivers: $(wc -l < "$OUT_DIR/drivers.txt") packages"
echo "======================================"
