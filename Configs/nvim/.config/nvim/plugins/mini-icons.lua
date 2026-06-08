local ok, icons = pcall(require, "mini.icons")
if not ok then return end

icons.setup({
  -- Use nerd fonts style (same variant as blink.cmp)
  style = "glyph",
})

-- Make mini.icons the provider for any plugin that checks for nvim-web-devicons
-- (snacks already checks mini.icons first, this covers other integrations)
icons.mock_nvim_web_devicons()
