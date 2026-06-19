local M = {}

function M.setup()
  -- Minimal baseline: winbar carries file context, statusline starts hidden.
  vim.o.laststatus = 0
  vim.o.statusline = " "
  vim.o.cmdheight = 1

  vim.opt.fillchars:append({ stl = "─", stlnc = "─" })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("statusline_no_bg", { clear = true }),
    callback = function()
      local sep = vim.api.nvim_get_hl(0, { name = "WinSeparator", link = false })
      local fg = sep.fg
      vim.api.nvim_set_hl(0, "StatusLine", { fg = fg, bg = "NONE" })
      vim.api.nvim_set_hl(0, "StatusLineNC", { fg = fg, bg = "NONE" })
    end,
  })
end

return M
