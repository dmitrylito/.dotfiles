#!/usr/bin/env bash
# Automatically regenerates the package sync lists for Ansible

CHEZMOI_DIR="$HOME/.local/share/chezmoi"
OMARCHY_BASE="$CHEZMOI_DIR/install/omarchy-base.packages"
OMARCHY_OTHER="$CHEZMOI_DIR/install/omarchy-other.packages"

# The regex used to identify hardware-specific packages that shouldn't sync across machines
DRIVER_REGEX='nvidia|amd|intel|vulkan|apple|macbook|t2|tuxedo|firmware|dkms|kernel|modules'

echo "Gathering current system state..."

# 1. Build the clean Omarchy reference (excluding hardware drivers)
grep -v '^#' "$OMARCHY_BASE" | grep -v '^$' | grep -vE "$DRIVER_REGEX" > /tmp/omarchy_ref.txt
if [ -f "$OMARCHY_OTHER" ]; then
    grep -v '^#' "$OMARCHY_OTHER" | grep -v '^$' | grep -vE "$DRIVER_REGEX" >> /tmp/omarchy_ref.txt
fi

# 2. Get current explicit packages
pacman -Qeq > /tmp/current_native.txt
pacman -Qmq > /tmp/current_aur.txt
cat /tmp/current_native.txt /tmp/current_aur.txt | sort -u > /tmp/current_all.txt

echo "Calculating differences..."

# 3. Generate Drivers List (All explicit packages on THIS system matching the regex)
grep -iE "$DRIVER_REGEX" /tmp/current_all.txt | sort > "$CHEZMOI_DIR/packages-drivers.txt"

# 4. Generate Added Pacman (Native in current, NOT in Omarchy, NOT a driver)
grep -vxFf /tmp/omarchy_ref.txt /tmp/current_native.txt | grep -ivE "$DRIVER_REGEX" | sort > "$CHEZMOI_DIR/packages-added-pacman.txt"

# 5. Generate Added AUR (AUR in current, NOT in Omarchy, NOT a driver)
grep -vxFf /tmp/omarchy_ref.txt /tmp/current_aur.txt | grep -ivE "$DRIVER_REGEX" | sort > "$CHEZMOI_DIR/packages-added-aur.txt"

# 6. Generate Removed List (Omarchy packages NOT in current)
grep -vxFf /tmp/current_all.txt /tmp/omarchy_ref.txt | sort > "$CHEZMOI_DIR/packages-removed.txt"

# Cleanup
rm /tmp/omarchy_ref.txt /tmp/current_native.txt /tmp/current_aur.txt /tmp/current_all.txt

echo "======================================"
echo "✅ Package Lists Updated Successfully!"
echo "Added Pacman:  $(wc -l < "$CHEZMOI_DIR/packages-added-pacman.txt") packages"
echo "Added AUR:     $(wc -l < "$CHEZMOI_DIR/packages-added-aur.txt") packages"
echo "Removed:       $(wc -l < "$CHEZMOI_DIR/packages-removed.txt") packages"
echo "Local Drivers: $(wc -l < "$CHEZMOI_DIR/packages-drivers.txt") packages"
echo "======================================"
