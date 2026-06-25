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

    highlights.register("avante_float_chrome", function()
      local mode = vim.o.background == "light" and "light" or "dark"
      local ok_palette, palette = pcall(require, "colorscheme-sync.palette")
      local colors = ok_palette and palette.build(mode) or {
        fg = mode == "light" and "#4c4f69" or "#cdd6f4",
        bg = mode == "light" and "#eff1f5" or "#1e1e2e",
        border = mode == "light" and "#9ca0b0" or "#6c7086",
        accent = mode == "light" and "#1e66f5" or "#89b4fa",
      }

      vim.api.nvim_set_hl(0, "AvantePromptInput", { fg = colors.fg, bg = colors.bg })
      vim.api.nvim_set_hl(0, "AvantePromptInputBorder", { fg = colors.accent, bg = colors.bg })
      vim.api.nvim_set_hl(0, "AvantePopupHint", { fg = colors.border, bg = colors.bg })
      vim.api.nvim_set_hl(0, "AvanteSidebarNormal", { fg = colors.fg, bg = colors.bg })
      vim.api.nvim_set_hl(0, "AvanteSidebarWinSeparator", { fg = colors.border, bg = colors.bg })
      vim.api.nvim_set_hl(0, "AvanteSidebarWinHorizontalSeparator", { fg = colors.border, bg = colors.bg })
    end)
  end
end

return M
