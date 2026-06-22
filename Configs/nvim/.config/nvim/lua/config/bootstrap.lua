local M = {}

--- Gutter defaults and baseline highlights (needs picker + colorscheme-sync on rtp).
function M.after_lazy()
  local ok_gutter, gutter = pcall(require, "picker.gutter")
  if ok_gutter then
    vim.opt.signcolumn = gutter.SIGNCOLUMN
    vim.opt.statuscolumn = gutter.STATUSCOLUMN
  end

  local ok_hl, highlights = pcall(require, "colorscheme-sync.highlights")
  if ok_hl then
    highlights.register("baseline_statusline", function()
      if vim.g.pure_ui_statusline_enabled ~= true then
        return
      end
      local sep = vim.api.nvim_get_hl(0, { name = "WinSeparator", link = false })
      vim.api.nvim_set_hl(0, "StatusLine", { fg = sep.fg, bg = "NONE" })
      vim.api.nvim_set_hl(0, "StatusLineNC", { fg = sep.fg, bg = "NONE" })
    end)
  end
end

return M
