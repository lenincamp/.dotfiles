local M = {}

local alacritty_sync = require("modules.theme.sync.alacritty")
local btop_sync = require("modules.theme.sync.btop")
local delta_sync = require("modules.theme.sync.delta")
local eza_sync = require("modules.theme.sync.eza")
local iterm2_sync = require("modules.theme.sync.iterm2")
local lazydocker_sync = require("modules.theme.sync.lazydocker")
local lazygit_sync = require("modules.theme.sync.lazygit")
local shell_sync = require("modules.theme.sync.shell")
local starship_sync = require("modules.theme.sync.starship")
local tmux_sync = require("modules.theme.sync.tmux")
local zellij_sync = require("modules.theme.sync.zellij")

local deps = {}

function M.setup(opts)
  opts = opts or {}
  deps = {
    current_theme = assert(opts.current_theme, "tool_sync.current_theme is required"),
    resolve_external_theme = assert(opts.resolve_external_theme, "tool_sync.resolve_external_theme is required"),
    sync_profile = assert(opts.sync_profile, "tool_sync.sync_profile is required"),
    theme_mode = assert(opts.theme_mode, "tool_sync.theme_mode is required"),
    tmux_theme_by_scheme = opts.tmux_theme_by_scheme or {},
  }
end

function M.sync_tmux_theme(theme)
  return tmux_sync.sync(theme, deps)
end

function M.sync_tmux_theme_async(theme)
  return tmux_sync.sync_async(theme, deps)
end

function M.sync_git_delta_theme(theme)
  return delta_sync.sync(theme, deps)
end

function M.sync_lazygit_theme(theme)
  return lazygit_sync.sync(theme, deps)
end

function M.sync_lazydocker_theme(theme)
  return lazydocker_sync.sync(theme, deps)
end

function M.sync_btop_theme(theme)
  return btop_sync.sync(theme, deps)
end

function M.sync_zellij_theme(theme)
  return zellij_sync.sync(theme, deps)
end

function M.sync_shell_theme_runtime(theme)
  return shell_sync.sync_runtime(theme, deps)
end

function M.sync_eza_theme(theme)
  return eza_sync.sync(theme, deps)
end

function M.sync_alacritty_theme(theme)
  return alacritty_sync.sync(theme, deps)
end

function M.sync_starship_theme(theme)
  return starship_sync.sync(theme, deps)
end

function M.iterm2_set_primary_colors(colors)
  return iterm2_sync.set_primary_colors(colors)
end

function M.sync_iterm2_theme(theme)
  return iterm2_sync.sync(theme, deps)
end

function M.sync_external_tools(theme)
  M.sync_git_delta_theme(theme)
  M.sync_lazygit_theme(theme)
  M.sync_lazydocker_theme(theme)
  M.sync_btop_theme(theme)
  M.sync_zellij_theme(theme)
  M.sync_shell_theme_runtime(theme)
  M.sync_starship_theme(theme)
  M.sync_alacritty_theme(theme)
  M.sync_iterm2_theme(theme)
  M.sync_eza_theme(theme)
end

return M
