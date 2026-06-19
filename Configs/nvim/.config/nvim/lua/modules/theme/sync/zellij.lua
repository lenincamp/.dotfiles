local common = require("modules.theme.sync.common")

local M = {}

function M.theme_for_mode(mode)
  return (mode == "light") and "catppuccin-latte" or "catppuccin-macchiato"
end

function M.replace_theme(content, zellij_theme)
  return content:gsub('theme%s+"[^"]+"', 'theme "' .. zellij_theme .. '"', 1)
end

function M.sync(theme, ctx)
  local item = ctx.current_theme(theme)
  local mode = ctx.theme_mode(item)
  local path = vim.fn.expand("~/.config/zellij/config.kdl")
  local content = common.read_text_file(path)
  if type(content) ~= "string" then return end

  local updated = M.replace_theme(content, M.theme_for_mode(mode))
  pcall(common.write_text_file_if_changed, path, updated)
end

return M
