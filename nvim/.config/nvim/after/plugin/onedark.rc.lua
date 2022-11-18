local status, onedark = pcall(require, "onedark")
if (not status) then return end

onedark.setup {
  style = 'darker',
  --[[ transparent = true, -- Show/hide background ]]
  lualine = {
    transparent = false, -- lualine center bar transparency
  },
}
onedark.load()
