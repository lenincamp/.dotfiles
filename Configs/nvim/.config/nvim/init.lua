-- Leader keys must be set before any plugin or keymap loads
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- Configure netrw before it loads.
vim.g.netrw_banner = 0
vim.g.netrw_browse_split = 4
vim.g.netrw_altv = 1
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 34

require("configs")
require("plugins")
require("lsp")
require("keymaps")
require("statusline")
require("autocmds")
