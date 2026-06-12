-- Minimal statusline: winbar handles file path, statusline stays hidden.
-- In Neovim 0.12, laststatus=0 means statusline is never shown.
-- Keep statusline content/highlights neutral in case a plugin mutates it.

vim.o.laststatus = 0
vim.o.statusline = " "
vim.o.cmdheight  = 1

-- Fill the statusline separator with a thin line (matches WinSeparator)
vim.opt.fillchars:append({ stl = "─", stlnc = "─" })

-- Force statusline separator to match WinSeparator exactly (same fg, no bg).
-- Must run after every colorscheme load.
vim.api.nvim_create_autocmd("ColorScheme", {
  group    = vim.api.nvim_create_augroup("statusline_no_bg", { clear = true }),
  callback = function()
    local sep = vim.api.nvim_get_hl(0, { name = "WinSeparator", link = false })
    local fg  = sep.fg
    vim.api.nvim_set_hl(0, "StatusLine",   { fg = fg, bg = "NONE" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { fg = fg, bg = "NONE" })
  end,
})
