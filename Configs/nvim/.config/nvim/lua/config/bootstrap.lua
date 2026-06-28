local M = {}

--- Gutter defaults (needs picker on rtp). Avante/popups theming lives in
--- colorscheme-sync's integrations, so nothing colorscheme-specific here.
function M.after_lazy()
  local ok_gutter, gutter = pcall(require, "picker.gutter")
  if ok_gutter then
    vim.opt.signcolumn = gutter.SIGNCOLUMN
    vim.opt.statuscolumn = gutter.STATUSCOLUMN
  end
end

return M
