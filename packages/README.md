# Synced package inventory

Grouped view of everything the Ansible playbook actually installs per profile, so
duplication and dead weight are visible at a glance.

Scope: `omarchy/added-{pacman,aur}.txt`, `server/{pacman,aur}.txt`, `mac/{brew,casks,taps}.txt`.
`omarchy/base.packages` + `other.packages` are Omarchy's *shipped* reference lists (the
diff baseline, never installed by the playbook) and `omarchy/drivers.txt` is reference-only
— none of the three are covered here.

Columns: **O** = omarchy, **S** = server, **M** = mac. `·` = absent, `—` = N/A on that platform.

## Shell

| tool | O | S | M | note |
|---|---|---|---|---|
| zsh | ✓ | ✓ | ✓ | |
| starship | — | ✓ | ✓ | omarchy gets it from base.packages |
| zsh-autocomplete / -autosuggestions / -syntax-highlighting | ✓ | · | · | **redundant** — the playbook clones all four as oh-my-zsh custom plugins |
| zsh-you-should-use (AUR) | ✓ | · | · | **redundant** — same |
| zsh-completions | ✓ | · | · | **unused** — not in the `plugins=()` list |
| zsh-uv-env-git (AUR) | ✓ | · | · | **unused** — `.zshrc` uses omz's `uv` plugin |
| direnv | ✓ | ✓ | ✓ | |
| sesh / sesh-bin | ✓ | ✓ | ✓ | |

## Editor & code intelligence

| tool | O | S | M | note |
|---|---|---|---|---|
| bob | ✓ | ✓ | ✓ | the neovim version manager — owns `nvim` |
| neovim | ✓ | · | · | **conflicts with bob**; `/usr/bin/nvim` is shadowed |
| tree-sitter(-cli) | — | ✓ | ✓ | omarchy: base.packages |
| luarocks | — | ✓ | ✓ | omarchy: base.packages |
| ast-grep | ✓ | ✓ | ✓ | |
| ripgrep / ripgrep-all | — | ✓ | ✓ | omarchy: base.packages |
| pre-commit | ✓ | · | ✓ | |

## Files, viewers, navigation

`yazi`, `bat`, `eza`, `fd`, `zoxide`, `fzf` — all three profiles (omarchy mostly via base.packages).
Server adds `ncdu`, `pv`, `lsof`, `rsync`. Yazi previewer deps on mac/server: `ghostscript`,
`imagemagick`, `poppler`, `resvg`, `sevenzip`, `ffmpeg`.

## Git & VCS

`git`, `git-delta`, `lazygit` everywhere. `chezmoi` everywhere. `gh` (mac) / `github-cli`
(omarchy base). `stow` (mac only) — superseded by chezmoi.

## Terminal

`tmux` everywhere (+ tmuxifier cloned by the playbook). `ghostty` on omarchy;
`ghostty-terminfo` on server; `ghostty` cask on mac. `mosh` on omarchy/server/mac.

## AI CLIs

| tool | O | S | M | note |
|---|---|---|---|---|
| claude (`~/.local/bin`) | playbook | playbook | playbook | installed by SECTION 6 curl script |
| `claude` (AUR) | ✓ | · | · | **duplicate** of the above, 478 MB |
| codex (`~/.local/bin`) | playbook | playbook | playbook | SECTION 6 |
| `openai-codex-bin` | ✓ | · | · | **duplicate**, 341 MB, `/usr/bin/codex` shadowed |
| `gemini-cli` | ✓ | · | · | **duplicate** — `gemini` resolves to the mise/npm copy |
| ollama / ollama-cuda | · | ✓ | · | |
| llama.cpp-cuda (AUR) | · | ✓ | · | |

## Runtimes & build

| tool | O | S | M | note |
|---|---|---|---|---|
| mise | — | ✓ | ✓ | omarchy: base.packages. Owns node/python/bun/pnpm |
| node | · | · | ✓ | **violates the mise rule** |
| uv | ✓ | ✓ (`python-uv`) | ✓ | omarchy also has the astral installer copy in `~/.local/bin` |
| go | ✓ | ✓ | ✓ | |
| cmake | ✓ | — | ✓ | server: `base-devel` |
| jdk17-openjdk | ✓ | · | · | only JDK, default java (Android Studio / Gradle) |
| gcc / base-devel | — | ✓ | — | |
| cpio | ✓ | · | · | nothing depends on it — leftover |
| pigz | ✓ | ✓ | · | |

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

## GUI apps (omarchy)

`telegram-desktop`, `slack-desktop`, `android-studio`, `steam`, `discordupdater`,
`etcher-bin`, `ventoy-bin`, `gogcli`. Mac casks: `aerospace`, `slack`, `telegram`,
`keymapp`, `ghostty`, nerd fonts.

## Server-only data stack

`python-pandas`, `python-pip`, `gdal`, `geos`, `libvips`, `lua`, `zram-generator`,
`cups`/`cups-filters`, `linux`/`linux-lts` kernels, `nvidia-open-lts`,
`nvidia-container-toolkit`, `yay-bin`.

## Cross-machine gaps worth knowing

- Mac has no container runtime and no `btop`; omarchy/server both do.
- `taps.txt` carries `barutsrb/tap`, whose only formula is `omniwm` — nothing in
  `brew.txt`/`casks.txt` references it.
- ROCm (`migraphx` → `rocm-llvm`, `miopen-hip`, `hipblaslt`, …) is installed on omarchy,
  which has an NVIDIA-only GPU. ~15 GB, zero reverse dependencies outside its own tree.
