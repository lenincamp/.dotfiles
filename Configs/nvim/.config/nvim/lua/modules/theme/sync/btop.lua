local common = require("modules.theme.sync.common")

local M = {}

function M.theme_for_mode(mode)
  return (mode == "light") and "catppuccin_latte" or "catppuccin_mocha"
end

function M.replace_color_theme(content, color_theme)
  return content:gsub('color_theme%s*=%s*"[^"]+"', 'color_theme = "' .. color_theme .. '"', 1)
end

function M.sync(theme, ctx)
  local item = ctx.current_theme(theme)
  local mode = ctx.theme_mode(item)
  local path = vim.fn.expand("~/.config/btop/btop.conf")
  local content = common.read_text_file(path)
  if type(content) ~= "string" then return end

  local updated = M.replace_color_theme(content, M.theme_for_mode(mode))
  pcall(common.write_text_file_if_changed, path, updated)
end

return M
