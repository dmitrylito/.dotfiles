#!/usr/bin/env bash
# Automatically regenerates the package sync lists for Ansible

CHEZMOI_DIR="$HOME/.local/share/chezmoi"
OMARCHY_BASE="$CHEZMOI_DIR/packages/omarchy/base.packages"
OMARCHY_OTHER="$CHEZMOI_DIR/packages/omarchy/other.packages"

# The regex used to identify hardware-specific packages that shouldn't sync across machines
DRIVER_REGEX='nvidia|amd|intel|vulkan|apple|macbook|t2|tuxedo|firmware|dkms|kernel|modules|asus|broadcom|thermald|ptl|dfr|vpl|debug'
# Repo-/machine-specific packages that only exist in special repos not configured
# on every machine (e.g. the CachyOS kernel + its keyring/mirrorlists). Syncing
# these into the shared lists breaks `chezmoi apply` on machines without those
# repos ("target not found"), so they're dropped from every generated list —
# each machine manages its own kernel.
REPO_SPECIFIC_REGEX='^cachyos|^linux-cachyos'
# The regex used to identify pre-installed packages that can be removed
PREINSTALL_REGEX='aether|cliamp|typora|spotify|libreoffice-fresh|1password-beta|1password-cli|xournalpp|signal-desktop|pinta|obsidian|obs-studio|kdenlive|lazydocker|opencode|claude-code|alacritty|htop|nvim|dart|jdk-openjdk|sassc|libsass|intltool|autoconf-archive|webp-pixbuf-loader'

echo "Gathering current system state..."

# 1. Build the clean Omarchy reference (excluding hardware drivers and pre-installs)
grep -v '^#' "$OMARCHY_BASE" | grep -v '^$' | grep -vE "$DRIVER_REGEX" | grep -vE "$PREINSTALL_REGEX" > /tmp/omarchy_ref.txt
if [ -f "$OMARCHY_OTHER" ]; then
    grep -v '^#' "$OMARCHY_OTHER" | grep -v '^$' | grep -vE "$DRIVER_REGEX" | grep -vE "$PREINSTALL_REGEX" >> /tmp/omarchy_ref.txt
fi

# 2. Get current system state
# - Explicit packages (native and AUR) for "Added" lists
# - ALL installed packages AND provided symbols for "Removed" check
pacman -Qenq > /tmp/current_native_explicit.txt
pacman -Qemq > /tmp/current_aur_explicit.txt
expac -Q '%n %p' | tr ' ' '\n' | sort -u > /tmp/current_all_installed_and_provides.txt

echo "Calculating differences..."

# 3. Generate Drivers List (All explicit packages on THIS system matching the regex)
cat /tmp/current_native_explicit.txt /tmp/current_aur_explicit.txt | grep -iE "$DRIVER_REGEX" | grep -ivE "$REPO_SPECIFIC_REGEX" | sort > "$CHEZMOI_DIR/packages/omarchy/drivers.txt"

# 4. Generate Added Pacman (Native in current, NOT in Omarchy, NOT a driver, NOT a pre-install, NOT repo-specific)
grep -vxFf /tmp/omarchy_ref.txt /tmp/current_native_explicit.txt | grep -ivE "$DRIVER_REGEX" | grep -ivE "$PREINSTALL_REGEX" | grep -ivE "$REPO_SPECIFIC_REGEX" | sort > "$CHEZMOI_DIR/packages/omarchy/added-pacman.txt"

# 5. Generate Added AUR (AUR in current, NOT in Omarchy, NOT a driver, NOT a pre-install, NOT repo-specific)
grep -vxFf /tmp/omarchy_ref.txt /tmp/current_aur_explicit.txt | grep -ivE "$DRIVER_REGEX" | grep -ivE "$PREINSTALL_REGEX" | grep -ivE "$REPO_SPECIFIC_REGEX" | sort > "$CHEZMOI_DIR/packages/omarchy/added-aur.txt"

# 6. Generate Removed List (Omarchy packages NOT in current or provided by current)
grep -vxFf /tmp/current_all_installed_and_provides.txt /tmp/omarchy_ref.txt | sort > "$CHEZMOI_DIR/packages/omarchy/removed.txt"

# Cleanup
rm /tmp/omarchy_ref.txt /tmp/current_native_explicit.txt /tmp/current_aur_explicit.txt /tmp/current_all_installed_and_provides.txt

echo "======================================"
echo "✅ Package Lists Updated Successfully!"
echo "Added Pacman:  $(wc -l < "$CHEZMOI_DIR/packages/omarchy/added-pacman.txt") packages"
echo "Added AUR:     $(wc -l < "$CHEZMOI_DIR/packages/omarchy/added-aur.txt") packages"
echo "Removed:       $(wc -l < "$CHEZMOI_DIR/packages/omarchy/removed.txt") packages"
echo "Local Drivers: $(wc -l < "$CHEZMOI_DIR/packages/omarchy/drivers.txt") packages"
echo "======================================"
