local common = require("modules.theme.sync.common")

local M = {}

function M.config_paths(mode)
  local base = vim.fn.expand("~/Library/Application Support/lazydocker")
  local src = base .. ((mode == "light") and "/config-light.yml" or "/config-dark.yml")
  return src, base .. "/config.yml"
end

function M.sync(theme, ctx)
  local item = ctx.current_theme(theme)
  local mode = ctx.theme_mode(item)
  local src, target = M.config_paths(mode)
  pcall(common.copy_text_file_if_changed, src, target)
end

return M
