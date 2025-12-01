#!/bin/bash
set -e

# 1. Cross-Platform Home Directory Logic
# 'getent' is Linux-only. We use 'eval echo' to expand the tilde,
# which works on macOS (Darwin), Ubuntu, and Arch.
if [ -n "${SUDO_USER}" ]; then
  REAL_HOME=$(eval echo "~${SUDO_USER}")
else
  REAL_HOME="${HOME}"
fi

# 2. Define Paths
ZSH_CUSTOM="${ZSH_CUSTOM:-${REAL_HOME}/.oh-my-zsh-custom/custom}"
THEME_DIR="$ZSH_CUSTOM/themes/spaceship-prompt"
THEME_LINK="$ZSH_CUSTOM/themes/spaceship.zsh-theme"
THEME_TARGET="$THEME_DIR/spaceship.zsh-theme"

echo "Targeting User Home: ${REAL_HOME}"

# 3. Clean up existing Repo
if [ -d "$THEME_DIR" ]; then
  echo "Removing existing spaceship-prompt directory at $THEME_DIR"
  rm -rf "$THEME_DIR"
fi

# 4. Clean up existing Link/File
# We remove it proactively to ensure the ln -s command doesn't fail or nest inside a folder
if [ -e "$THEME_LINK" ] || [ -L "$THEME_LINK" ]; then
  echo "Removing existing theme file/link..."
  rm -f "$THEME_LINK"
fi

# 5. Clone Repo
echo "Cloning spaceship-prompt..."
if git clone https://github.com/spaceship-prompt/spaceship-prompt.git \
  "$THEME_DIR" --depth=1; then
  echo "Cloned spaceship-prompt repo successfully."
else
  echo "Failed to clone spaceship-prompt repo" >&2
  exit 1
fi

# 6. Create Symlink
ln -s "$THEME_TARGET" "$THEME_LINK"
echo "Created symlink: $THEME_LINK -> $THEME_TARGET"
