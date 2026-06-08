-- Leader keys must be set before any plugin or keymap loads
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- Disable netrw before anything loads (snacks.explorer replaces it)
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

require("plugins")
require("configs")
require("lsp")
require("keymaps")
require("statusline")
require("autocmds")
