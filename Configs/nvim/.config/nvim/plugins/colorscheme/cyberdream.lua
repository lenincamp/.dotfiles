local ok, cyberdream = pcall(require, "cyberdream")
if not ok then return end

local variant = vim.g.pure_cyberdream_variant or ((vim.o.background == "light") and "light" or "default")

cyberdream.setup({
  -- Keep cyberdream base opaque; global <leader>uA handles transparency
  -- consistently across themes via colorschemes.apply_transparency().
  transparent = false,
  variant = variant,
  italic_comments = true,
  overrides = function(colors)
    local bg = colors.bg
    return {
      Normal = { bg = bg },
      NormalNC = { bg = bg },
      NormalFloat = { bg = bg },
      FloatBorder = { bg = bg },
      SignColumn = { bg = bg },
      StatusLine = { bg = bg },
      StatusLineNC = { bg = bg },
      TabLine = { bg = bg },
      TabLineFill = { bg = bg },
      WinBar = { bg = bg },
      WinBarNC = { bg = bg },
    }
  end,
})
