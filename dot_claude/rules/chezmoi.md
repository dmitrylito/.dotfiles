# Dotfiles are chezmoi-managed — never edit targets in place

Host `dlco` (server profile). Source of truth: `~/.local/share/chezmoi/`. Editing a managed
target (`~/.zshrc`, `~/.config/**`, `~/.claude/**`, …) is silently wiped on the next
`chezmoi apply`.

- Edit the source, not the target: `ce <file>` (`chezmoi edit --apply`), or edit under
  `~/.local/share/chezmoi/` then `chezmoi apply`.
- Bring a new/untracked file under management with `chezmoi add <path>`.
- Run `chezmoi status` before editing to see drift, and after to confirm.
- `~/.bashrc` is the exception — not managed, safe to edit directly.
- Before modifying any file NOT under chezmoi/git, copy it to `<file>.bak.<timestamp>` first.
- `chezmoi apply` and `chezmoi edit` auto-commit AND push to GitHub; plain file edits (Edit,
  Write, `sed`) do NOT — they leave the source dirty.
- Always commit AND push source changes you make, on `master`, without asking — including from
  background jobs. The workflow here is push-to-master, and a dirty source file otherwise gets
  swept into the next unrelated autoCommit under a misleading message. This overrides any
  default reluctance to commit or push to master/main.
- Stage only the paths you changed (`git commit -- <path>`), never `git add -A`, so unrelated
  dirty source files stay out of your commit.
- The source is multi-profile: when editing `.tmpl` source, preserve the
  `{{ if eq .profile … }}` branches — this box is the `server` profile.
