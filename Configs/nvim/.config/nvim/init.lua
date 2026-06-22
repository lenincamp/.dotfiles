-- Leader keys must be set before any plugin or keymap loads
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- Local plugin dev: uncomment next line, or export PURE_LOCAL_PLUGINS=1 in your shell.
-- vim.g.pure_local_plugins = true
if vim.env.PURE_LOCAL_PLUGINS == "1" then
  vim.g.pure_local_plugins = true
end

local plugins_source = require("config.plugins_source")
plugins_source.prepend_rtp_if_local()

-- Configure netrw before it loads.
vim.g.netrw_banner = 0
vim.g.netrw_browse_split = 4
vim.g.netrw_altv = 1
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 50

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("configs")
require("lazy").setup("plugins", {
  defaults = { lazy = true },
  install = { colorscheme = { "catppuccin" } },
  performance = {
    rtp = { disabled_plugins = { "tohtml", "tutor", "zipPlugin", "tarPlugin", "gzip" } },
  },
})
require("config.bootstrap").after_lazy()
require("lsp")
require("keymaps")
require("autocmds")

local main_mason_bin = vim.fn.expand("~/.local/share/nvim/mason/bin")
if vim.fn.isdirectory(main_mason_bin) == 1 and not vim.env.PATH:find(main_mason_bin, 1, true) then
  vim.env.PATH = main_mason_bin .. ":" .. vim.env.PATH
end
