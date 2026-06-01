local ok, gruvbox = pcall(require, "gruvbox")
if not ok then return end

local colorschemes = require("colorschemes")
local contrast = vim.g.pure_gruvbox_contrast or "hard"
local transparent = colorschemes.is_transparent()

gruvbox.setup({
  terminal_colors = true, -- add neovim terminal colors
  undercurl = true,
  underline = true,
  bold = true,
  italic = {
    strings = true,
    emphasis = true,
    comments = true,
    operators = false,
    folds = true,
  },
  strikethrough = true,
  invert_selection = false,
  invert_signs = false,
  invert_tabline = false,
  inverse = true, -- invert background for search, diffs, statuslines and errors
  contrast = contrast, -- can be "hard", "soft" or empty string
  palette_overrides = {},
  overrides = transparent and {
    Normal = { bg = "none" },
    NormalFloat = { bg = "none" },
    FloatBorder = { bg = "none" },
    SignColumn = { bg = "none" },
    StatusLine = { bg = "none" },
    StatusLineNC = { bg = "none" },
  } or {},
  dim_inactive = false,
  transparent_mode = transparent,
})
