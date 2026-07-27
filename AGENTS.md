# System Guide for AI Agents

Welcome! This system is heavily customized and uses specific configuration tools. Before making any modifications, read this guide to ensure you do not break the environment or cause conflicts.

---

## 🚀 Critical Rule: Dotfiles Management (Chezmoi)

This home directory uses **[chezmoi](https://www.chezmoi.io/)** to manage dotfiles.

* **Managed Files:** Most core configuration files (such as `.zshrc`, `.zshenv`, `.config/waybar/`, `.config/walker/`, and `.config/yazi/`) are managed by `chezmoi`.
* **The Golden Rule:** **DO NOT** edit managed files directly in their target locations (e.g., `~/.zshrc`). Any direct edits will be wiped out next time `chezmoi apply` is run.
* **How to Edit Managed Files:**
  * Use the alias: `ce <file>` (which expands to `chezmoi edit --apply <file>`).
  * Alternatively, modify the source file inside the chezmoi source directory: `~/.local/share/chezmoi/`.
  * After editing source files directly, run `chezmoi apply` to deploy changes.
  * To add a new or modified untracked/local file to chezmoi management, run `chezmoi add <file_path>`.
* **Unmanaged Files:** `~/.bashrc` is **not** managed by chezmoi and can be edited directly if needed (though the primary shell is Zsh).

---

## 👑 Omarchy Linux Framework

This system runs **[Omarchy](https://omarchy.org/)**—an opinionated, beautiful Arch Linux distribution using Hyprland.

* **Never Modify the Core:** Do **not** edit files inside `~/.local/share/omarchy/`. These are read-only source files managed by git. Any changes will break system updates.
* **User Customizations:** Make all user-level customizations in `~/.config/` (such as `~/.config/hypr/` for Hyprland rules/keybindings, or `~/.config/omarchy/`).
* **Sourcing Rules & Reloads:**
  * **Hyprland:** Config files auto-reload on save. Always validate changes by running `hyprctl reload` followed by `hyprctl configerrors`.
  * **Waybar / Walker / Terminals:** These do **not** auto-reload. You must run `omarchy restart waybar` (or `walker`, `terminal`) after making changes.
* **Helpful CLI Tools:**
  * `omarchy commands` — lists all built-in commands.
  * `omarchy theme set "<Theme Name>"` — changes the system theme safely.
  * `omarchy refresh <app>` — resets the config of `<app>` to defaults (creating a timestamped backup first).
  * `omarchy debug --no-sudo --print` — prints system debug logs (always use these flags to prevent interactive hangs).

---

## 🛠️ Toolchains & Environments (Mise)

We use **[mise](https://mise.jdx.dev/)** to manage language runtimes and environments.

* **Active Tools:** Managed via `~/.config/mise/config.toml` (e.g. Node.js).
* **Trusting Environments:** If you create a new folder or worktree that contains environment configs, make sure to run `mise trust <directory_path>`.

---

## 🐚 Shells, Aliases, & Git Plugins

* **Primary Shell:** Interactive shell is **Zsh** with **Oh My Zsh**.
* **OMZ Git Plugin Conflict:**
  * Oh My Zsh defines standard short-hand aliases (e.g., `ga='git add'`, `gd='git diff'`).
  * Omarchy defines custom workspace helper functions of the same names (`ga()`, `gd()`).
  * To prevent parse/syntax errors during shell initialization, both `~/.bashrc` and `~/.zshrc` explicitly run `unalias ga gd 2>/dev/null` right before sourcing Omarchy's function folders. Keep this pattern intact.
* **User Aliases:** Custom user aliases should be added to `~/.aliases` (which is sourced at the bottom of both `~/.bashrc` and `~/.zshrc`).

---

## 📂 Key Directory Layout

* `~/Projects/` — Base projects directory (e.g., contains `BulkBid`).
* `~/.local/bin/` — User-specific custom binaries.
* `~/.local/share/chezmoi/` — Chezmoi source files (Git-backed dotfiles repository).
* `~/.local/share/omarchy/` — Omarchy core source repository (**Read-Only**).

---

## 📝 Guidelines for AI Collaborators

1. **Check Status First:** Run `chezmoi status` to see if there are any unapplied local changes before making edits.
2. **Be Careful Sudoing:** Avoid commands that trigger interactive `sudo` prompts unless requested. Use `omarchy debug --no-sudo --print` rather than raw systemctl debugs where possible.
3. **Respect Backups:** If modifying a file that is not under Chezmoi/Git, copy it to `<filename>.bak.<timestamp>` first.
