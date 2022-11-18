local status, monokai = pcall(require, "monokai")
if (not status) then return end
monokai.setup {
  lualine = {
    transparent = false, -- lualine center bar transparency
  },
}
