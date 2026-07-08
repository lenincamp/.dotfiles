# AGENTS.md

macOS dotfiles repo. Managed by **Tuckr** (not symlinks directly, not bare git repo).

## Key commands

```bash
# Deploy ALL configs with hooks (preferred)
tuckr set Configs/*

# Deploy single tool
tuckr set nvim
tuckr set zsh tmux

# Deploy symlinks only (no hooks)
tuckr add Configs/*

# Check deployment status
tuckr status

# Export Brewfile from current system
brew bundle dump --force

# Apply skip-worktree to theme files
./scripts/theme-tools/skip-theme-tracking.sh

# Full new-Mac setup
./scripts/quick-setup.sh
```

**tuckr set** vs **tuckr add**: `set` runs pre/post hooks. `add` only creates symlinks. Hooks install plugins, start services, apply theme skip-worktree. Almost always want `set`.

## Structure

- `Configs/` — tool configs, symlinked by Tuckr to `$HOME`
  - `nvim/.config/nvim/` — Neovim config (pure Lua, lazy.nvim, no framework)
  - `zsh/` — shell aliases, completions, plugins
  - `tmux/` — tmux + tmuxinator
  - `gitconfig/` — git config + delta themes
  - `iterm2/` — iTerm2 settings + generated theme files
  - `opencode/` — OpenCode config (opencode.jsonc, AGENTS.md, skills)
- `Hooks/` — Tuckr hooks (pre/post per tool), see `Hooks/README.md`
- `scripts/` — setup, export, theme sync scripts
- `Brewfile` — Homebrew package manifest

## Theme system

Neovim is the theme source. Changing theme in Neovim auto-propagates to: iTerm2, Lazygit, Starship, Delta, Tmux, btop, eza.

Generated files use `git update-index --skip-worktree` to avoid noise in commits. If you need to commit a generated theme file, restore tracking first:
```bash
./scripts/theme-tools/restore-theme-tracking.sh
# ... commit ...
./scripts/theme-tools/skip-theme-tracking.sh
```

Generated files are also in `.gitignore` — new ones won't be tracked automatically.

## Git gotchas

- Theme-generated files (iterm2, delta, starship, lazygit) are skip-worktree'd and gitignored
- `Configs/zsh/zsh_config/local-secrets.zsh` is gitignored — never commit secrets
- `system-settings/defaults/*.plist` is gitignored — review before committing exports
- `Configs/agents/.agents/projects/` and skill locks are gitignored

## Neovim config

Pure Lua, lazy.nvim plugin manager, catppuccin theme. Entry: `Configs/nvim/.config/nvim/init.lua`.

Local plugin dev: set `PURE_LOCAL_PLUGINS=1` env var or uncomment line in init.lua.

Stylua for formatting: `Configs/nvim/.config/nvim/stylua.toml`.

## Hooks

All hooks live in `Hooks/<tool>/pre.sh` or `post.sh`. Must be executable (`chmod +x`).

Key hooks:
- `global/post.sh` — applies skip-worktree to theme files after every deploy
- `tmux/post.sh` — installs TPM + plugins
- `zsh/post.sh` — installs fzf-tab, zsh-syntax-highlighting, zsh-autosuggestions
- `nvim/post.sh` — verifies bob, tree-sitter CLI dependencies

## Language

Docs are in Spanish. Code and configs are in English. Match the language of the file you're editing.
