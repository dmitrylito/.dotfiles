---
paths: ["**/.zshrc", "**/.zshenv", "**/.bashrc", "**/.aliases", "**/dot_zshrc*", "**/dot_zshenv*", "**/dot_bashrc*", "**/dot_aliases*"]
---
# Shell config

- Both `~/.bashrc` and `~/.zshrc` run `unalias ga gd 2>/dev/null` before sourcing their
  function folders — Oh My Zsh's `ga`/`gd` git aliases collide with same-named custom
  functions. Keep this line intact or shell init breaks.
- Add personal aliases to `~/.aliases` (sourced at the bottom of both rc files).
- These files are chezmoi-managed (`dot_zshrc.tmpl`, `dot_zshenv.tmpl`, `dot_aliases`):
  edit the source, not the deployed target.
