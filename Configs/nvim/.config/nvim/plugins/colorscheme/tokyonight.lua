local ok, tokyonight = pcall(require, "tokyonight")
if not ok then return end

local colorschemes = require("modules.theme.colorschemes")
local style = vim.g.pure_tokyonight_style or "moon"

tokyonight.setup({
  style = style,
  transparent = colorschemes.is_transparent(),
  terminal_colors = true,
  styles = {
    comments = { italic = true },
    keywords = { italic = true },
    functions = {},
    variables = {},
    sidebars = "transparent",
    floats = "transparent",
  },
  on_highlights = function(hl)
    hl.NormalFloat = { bg = "none" }
    hl.FloatBorder = { bg = "none" }
    hl.SignColumn = { bg = "none" }
    hl.StatusLine = { bg = "none" }
    hl.StatusLineNC = { bg = "none" }
  end,
})