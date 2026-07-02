local M = {}

--- Gutter defaults. Avante/popups theming lives in
--- colorscheme-sync's integrations, so nothing colorscheme-specific here.
function M.after_lazy()
  local gutter = require("config.gutter")
  vim.opt.signcolumn = gutter.SIGNCOLUMN
  vim.opt.statuscolumn = gutter.STATUSCOLUMN
end

return M
