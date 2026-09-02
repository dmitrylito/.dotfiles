# Package inventory

Package deployment is intentionally decoupled from `chezmoi apply`. Run
`scripts/reconcile-packages.sh` explicitly after reviewing the current profile's
lists. On Linux, use `--check` first when package state has changed substantially.

## Ownership

- `omarchy/<hostname>/added-pacman.txt`: native packages intentionally added on
  that host.
- `omarchy/<hostname>/added-aur.txt`: AUR packages intentionally added there.
- `omarchy/<hostname>/removed.txt`: the only automatic removal list.
- `omarchy/<hostname>/{base,other}.packages`: snapshots of Omarchy-owned
  packages; reference only.
- `omarchy/<hostname>/drivers.txt`: hardware-specific reference; never
  installed automatically.
- `server/{pacman,aur}.txt`: desired headless Arch package set.
- `mac/{brew,casks,taps}.txt`: desired Homebrew set.

The old `untracked.regex` files were only safety rails for automatic pruning.
They are gone because undeclared packages and orphan dependencies are no longer
removed automatically.

## Regeneration

- Run `scripts/update_package_lists.sh` on an Omarchy host.
- Run `scripts/update_server_package_lists.sh` on the server.
- Review the diff before committing; generation is not package policy.
- Do not hand-edit Omarchy base/other snapshots.

The previous pacman hook, auto-commit/push script, and package onchange runner
were removed. Package transactions no longer mutate the dotfiles repository.

## Deliberate exclusions

- tmux and sesh are retired. Omarchy still ships tmux in its base snapshot, so
  `removed.txt` overrides it on each known host.
- Herdr is the supported multiplexer; its package/vendor installer owns it.
- `claude`, `codex`, GitHub CLI, Hey, Grok, Pi, Node, and Gemini-style npm tools
  belong to the managed mise configuration, not duplicate distro packages.
- `zsh-sage` and the other shell plugins are cloned by `playbook.yml`;
  do not add duplicate distro packages.
- distro Neovim stays off the desired lists because Bob owns `nvim`.
- `stow` is obsolete; Chezmoi owns dotfiles.
- GPU stacks remain in `drivers.txt` because they are host-specific and large.

## Reconciliation guarantees

The playbook installs missing declared packages and removes only explicit
`removed.txt` entries. It does not infer deletion from absence, does not remove
orphans, and does not install `drivers.txt`. During an AUR build, its temporary
sudoers entry permits only `/usr/bin/pacman *` and is removed in an `always`
block.
