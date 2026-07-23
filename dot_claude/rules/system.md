# Host dlco (Arch server) — runtimes, packages, sudo

- Runtimes via mise (`mise use -g <tool>`): node, python, uv, on-demand pnpm/bun.
  Neovim via bob. NEVER install node tooling or editors via pacman — pacman's
  node/npm/pnpm/bun/neovim/vim were deliberately removed. (claude-code is a native
  install, not the pacman package.)
- Run `mise trust <dir>` after creating a new folder/worktree that carries env config.
- Packages are tracked in chezmoi: after installing/removing system packages, re-run
  `~/.local/share/chezmoi/scripts/update_server_package_lists.sh` (server profile only)
  and commit, so `packages-server-{pacman,aur}.txt` stay reproducible.
- Avoid commands that trigger interactive `sudo` prompts unless asked.
