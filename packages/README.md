# Synced package inventory

Grouped view of everything the Ansible playbook actually installs per profile, so
duplication and dead weight are visible at a glance.

Scope: `omarchy/added-{pacman,aur}.txt`, `server/{pacman,aur}.txt`, `mac/{brew,casks,taps}.txt`.
`omarchy/base.packages` + `other.packages` are Omarchy's *shipped* reference lists (the
diff baseline, never installed by the playbook) and `omarchy/drivers.txt` is reference-only
— none of the three are covered here.

Columns: **O** = omarchy, **S** = server, **M** = mac. `·` = absent, `—` = N/A on that platform.

## Shell

`zsh` on all three. `starship` on server + mac (omarchy: base.packages). `direnv` and
`sesh`/`sesh-bin` on all three.

The four zsh plugins (`zsh-autocomplete`, `zsh-autosuggestions`, `zsh-syntax-highlighting`,
`you-should-use`) are **not** packages on any profile — the playbook clones them as oh-my-zsh
custom plugins, which is what `.zshrc`'s `plugins=()` loads. Don't re-add the distro packages.

## Editor & code intelligence

| tool | O | S | M | note |
|---|---|---|---|---|
| bob | ✓ | ✓ | ✓ | the neovim version manager — owns `nvim` on every profile |
| tree-sitter(-cli) | — | ✓ | ✓ | omarchy: base.packages (`tree-sitter-cli`) |
| luarocks | — | ✓ | ✓ | omarchy: base.packages |
| ast-grep | ✓ | ✓ | ✓ | |
| ripgrep / ripgrep-all | — | ✓ | ✓ | omarchy: base.packages |
| pre-commit | ✓ | · | ✓ | |

Distro `neovim` must stay off every list — bob owns `nvim` and a packaged copy just gets
shadowed in `PATH`.

## Files, viewers, navigation

`yazi`, `bat`, `eza`, `fd`, `zoxide`, `fzf` — all three profiles (omarchy mostly via base.packages).
Server adds `ncdu`, `pv`, `lsof`, `rsync`. Yazi previewer deps on mac/server: `ghostscript`,
`imagemagick`, `poppler`, `resvg`, `sevenzip`, `ffmpeg`.

## Git & VCS

`git`, `git-delta`, `lazygit` everywhere. `chezmoi` everywhere. `gh` (mac) / `github-cli`
(omarchy base). `stow` is gone from every profile — chezmoi replaced it.

## Terminal

`tmux` everywhere (+ tmuxifier cloned by the playbook). `ghostty` on omarchy;
`ghostty-terminfo` on server; `ghostty` cask on mac. `mosh` on omarchy/server/mac.

## AI CLIs

| tool | O | S | M | note |
|---|---|---|---|---|
| claude CLI (`~/.local/bin`) | playbook | playbook | playbook | installed by the playbook's AI-CLI section |
| codex CLI (`~/.local/bin`) | playbook | playbook | playbook | same |
| `claude` (AUR) | ✓ | · | · | the **desktop app**, not the CLI — intentional, keep |
| ollama / ollama-cuda | · | ✓ | · | |
| llama.cpp-cuda (AUR) | · | ✓ | · | |

The CLIs come from vendor install scripts, so `openai-codex-bin` and `gemini-cli` packages
must stay off the lists — they shadow `~/.local/bin` copies. `gemini` comes from mise/npm.

## Runtimes & build

| tool | O | S | M | note |
|---|---|---|---|---|
| mise | — | ✓ | ✓ | omarchy: base.packages. Owns node/python/bun/pnpm |
| uv | · | ✓ (`python-uv`) | ✓ | omarchy uses the astral installer copy in `~/.local/bin` |
| go | ✓ | ✓ | ✓ | |
| cmake | ✓ | — | ✓ | server: `base-devel` |
| jdk17-openjdk | ✓ | · | · | only JDK, default java (Android Studio / Gradle) |
| gcc / base-devel | — | ✓ | — | |
| pigz | ✓ | ✓ | · | |

No `node` package on any profile — mise owns it.

## Cloud, remote, sync

`ansible`, `tailscale`, `rclone` (omarchy + mac), `google-cloud-cli` + `-gsutil` (omarchy) /
`gcloud-cli` cask (mac), `wayvnc` (omarchy), `openssh` + `samba` + `nfs-utils` (server),
`wget` (all).

## Containers & infra

Server: `docker`, `docker-buildx`, `docker-compose`, `podman-compose`, `firewalld`,
`cockpit*` (+ `cockpit-sensors` AUR), `packagekit`, `networkmanager`.
Omarchy gets docker from base.packages. Mac: `lazydocker` only — no container runtime.

## Hardware, firmware, peripherals (omarchy)

`dmidecode`, `efibootmgr`, `fwupd`, `i2c-tools`, `tpm2-tools`, `sbctl`, `pesign`,
`nvtop`, `openrgb`, `solaar`, `coolercontrol-bin`, `zsa-keymapp-bin`, `stress-ng`, `gputest`.
Server equivalents: `smartmontools`, `ethtool`, `lsof`, `pcp`, `udisks2`, `quota-tools`.

## Wayland / desktop tooling (omarchy only)

`swaync`, `nwg-displays`, `wlr-randr`, `hyprmon-bin`, `omazed`, `wev`, `wtype`, `dotool`,
`voxtype-bin`, `kdeconnect`, `easyeffects`, `noisetorch-bin`, `gamescope`.

## Media & imaging

`tesseract` + `tesseract-data-eng` (omarchy) / `tesseract` + `tesseract-lang` (mac),
`webcamoid` (omarchy), `gimp` (omarchy), `ffmpeg`/`imagemagick` (server + mac),
`tectonic` (server + mac).

## GUI apps

Omarchy: `telegram-desktop`, `slack-desktop`, `android-studio`, `steam`, `discordupdater`,
`etcher-bin`, `ventoy-bin`, `gogcli`.
Mac casks are deliberately limited to things the dotfiles configure — `aerospace`, `ghostty`,
the nerd fonts — plus `gcloud-cli`. Chat/media apps are installed by hand on mac, not synced.

## GPU compute stacks are drivers, not packages

CUDA (`cuda`, `cudnn`) and ROCm (`migraphx`, `rocm-*`, `hip*`, `miopen-hip`, `comgr`, `hsa-*`)
are matched by `DRIVER_REGEX` in `scripts/update_package_lists.sh`, so on omarchy they land in
`drivers.txt` — tracked for reference, never installed by the playbook. They're multi-GB and
only valid for the GPU vendor a given machine actually has, so syncing them is wrong.

The server script (`update_server_package_lists.sh`) has no driver filter by design: its
`ollama-cuda` / `llama.cpp-cuda` / `nvidia-open-lts` entries are wanted there.

## Server-only data stack

`python-pandas`, `python-pip`, `gdal`, `geos`, `libvips`, `lua`, `zram-generator`,
`cups`/`cups-filters`, `linux`/`linux-lts` kernels, `nvidia-open-lts`,
`nvidia-container-toolkit`, `yay-bin`.

## Known rough edges

- `taps.txt` carries `barutsrb/tap`, whose only formula is `omniwm` — nothing in
  `brew.txt`/`casks.txt` references it.
- `DRIVER_REGEX`'s pre-existing unanchored `t2` token also matches `libgit2`, `libxfont2`,
  and `webkit2gtk-4.1`. Harmless today because none of them are explicitly installed, but it
  would misfile them as drivers if any ever were.
- Mac has no container runtime.
