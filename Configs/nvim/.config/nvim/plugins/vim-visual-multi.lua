-- vim-visual-multi: multi-cursor editing.
-- Key shortcuts (VM defaults + custom):
--   <C-n>      Find word under cursor / add cursor
--   <C-Up/Down> Add cursor above/below
--   \\A        Select All occurrences
--   \\/        Start regex search
--   \\         Add cursor at position
--   n/N        Next/prev occurrence (in VM mode)
--   q          Skip current, go to next
--   Q          Remove current cursor

-- Use leader backslash as VM leader (default)
vim.g.VM_leader = "\\"

-- Theme that works with catppuccin
vim.g.VM_theme = "codedark"

-- Keymaps
vim.g.VM_maps = {
  ["Find Under"]         = "<C-n>",
  ["Find Subword Under"] = "<C-n>",
  ["Add Cursor Up"]      = "<C-Up>",
  ["Add Cursor Down"]    = "<C-Down>",
  ["Select All"]         = "\\A",
  ["Start Regex Search"] = "\\/",
  ["Add Cursor At Pos"]  = "\\\\",
  ["Select h"]           = "<S-Left>",
  ["Select l"]           = "<S-Right>",
}

-- Disable default mappings that conflict with our config
vim.g.VM_default_mappings = 1
vim.g.VM_mouse_mappings   = 0
