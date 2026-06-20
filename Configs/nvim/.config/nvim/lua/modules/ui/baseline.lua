local M = {}

local highlights = require("modules.ui.highlights")

local function setup_statusline_highlights()
  if vim.g.pure_ui_statusline_enabled ~= true then
    return
  end

  local sep = vim.api.nvim_get_hl(0, { name = "WinSeparator", link = false })
  local fg = sep.fg
  vim.api.nvim_set_hl(0, "StatusLine", { fg = fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = fg, bg = "NONE" })
end

function M.setup()
  -- Minimal baseline: winbar carries file context, statusline starts hidden.
  vim.o.laststatus = 0
  vim.o.statusline = " "
  vim.o.cmdheight = 1

  vim.opt.fillchars:append({ stl = "─", stlnc = "─" })

  highlights.register("baseline_statusline", setup_statusline_highlights)
end

return M
