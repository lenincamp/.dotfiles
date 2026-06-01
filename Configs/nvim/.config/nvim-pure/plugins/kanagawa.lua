local ok, kanagawa = pcall(require, "kanagawa")
if not ok then return end

local colorschemes = require("colorschemes")
local theme = vim.g.pure_kanagawa_theme or "wave"

kanagawa.setup({
  compile = false,
  transparent = colorschemes.is_transparent(),
  terminalColors = true,
  dimInactive = false,
  theme = theme,
  background = {
    dark = theme,
    light = "lotus",
  },
  colors = {
    theme = {
      all = {
        ui = { bg_gutter = "none" },
      },
    },
  },
  overrides = function(colors)
    local theme = colors.theme
    return {
      NormalFloat = { bg = "none" },
      FloatBorder = { fg = theme.ui.float.fg_border, bg = "none" },
      SignColumn = { bg = "none" },
      StatusLine = { bg = "none" },
      StatusLineNC = { bg = "none" },
    }
  end,
})