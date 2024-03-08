local status, onedark = pcall(require, "onedark")
if (not status) then return end

onedark.setup {
  style = 'deep',
  transparent = true, -- Show/hide background
  term_colors = true,
  lualine = {
    transparent = false, -- lualine center bar transparency
  },
}
onedark.load()
