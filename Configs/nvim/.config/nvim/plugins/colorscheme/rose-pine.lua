local ok, rose_pine = pcall(require, "rose-pine")
if not ok then return end

local colorschemes = require("modules.theme.colorschemes")
local variant = vim.g.pure_rose_pine_variant or "moon"
local transparent = colorschemes.is_transparent()

rose_pine.setup({
  variant = variant,
  dark_variant = variant,
  dim_inactive_windows = false,
  extend_background_behind_borders = false,
  styles = {
    bold = true,
    italic = true,
    transparency = transparent,
  },
  highlight_groups = transparent and {
    Normal = { bg = "none" },
    NormalFloat = { bg = "none" },
    FloatBorder = { bg = "none" },
    SignColumn = { bg = "none" },
    StatusLine = { bg = "none" },
    StatusLineNC = { bg = "none" },
  } or {},
})