local shell = require("modules.core.shell")

local M = {}

local function tmux_theme_for(theme, ctx)
  local item = ctx.resolve_external_theme(theme)
  local profile = ctx.sync_profile(item)
  local tmux_theme = profile.tmux
    or ctx.tmux_theme_by_scheme[item.scheme]
    or (ctx.theme_mode(item) == "light" and "latte" or "mocha")

  return item, tmux_theme
end

local function set_theme(theme_name, cache_key)
  if type(theme_name) ~= "string" or theme_name == "" then return end
  if vim.fn.executable("tmux") ~= 1 then return end
  local track = cache_key or theme_name
  if vim.g._pure_tmux_theme_last == track then return end

  vim.fn.system({ "tmux", "set-option", "-gq", "@tmux_theme", theme_name })
  if vim.v.shell_error ~= 0 then return end

  local tmux_plugin = vim.fn.expand("~/.tmux/plugins/tmux/scripts/plugin.sh")
  if vim.fn.filereadable(tmux_plugin) == 1 then
    vim.fn.system({ "bash", tmux_plugin })
  end

  vim.g._pure_tmux_theme_last = track
end

function M.sync(theme, ctx)
  local item, tmux_theme = tmux_theme_for(theme, ctx)
  set_theme(tmux_theme, item.key)
end

function M.sync_async(theme, ctx)
  local item, tmux_theme = tmux_theme_for(theme, ctx)

  if type(tmux_theme) ~= "string" or tmux_theme == "" then return end
  if vim.fn.executable("tmux") ~= 1 then return end
  if vim.g._pure_tmux_theme_last == item.key then return end

  shell.run_async({ "tmux", "set-option", "-gq", "@tmux_theme", tmux_theme }, { text = true }, function(result)
    if result.code ~= 0 then return end

    local tmux_plugin = vim.fn.expand("~/.tmux/plugins/tmux/scripts/plugin.sh")
    if vim.fn.filereadable(tmux_plugin) == 1 then
      shell.run_async({ "bash", tmux_plugin }, { text = true })
    end

    vim.g._pure_tmux_theme_last = item.key
  end)
end

return M
