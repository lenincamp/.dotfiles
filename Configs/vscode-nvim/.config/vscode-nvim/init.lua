-- VSCode/Cursor isolated Neovim config.
-- Loaded only by vscode-neovim (see Cursor settings: vscode-neovim.neovimInitVimPaths.darwin).
-- Do NOT symlink with ~/.config/nvim — they are separate environments.

if not vim.g.vscode then
  return
end

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
package.path = root .. "/?.lua;" .. root .. "/lib/?.lua;" .. package.path

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Which Key: bare <leader> fires after this delay (many <leader>x maps exist).
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 50

-- ── Plugins (minimal set compatible with vscode-neovim) ─────────────────────

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  { "tpope/vim-surround" },
  { "tpope/vim-repeat" },
  { "justinmk/vim-sneak" },
  { "vscode-neovim/vscode-multi-cursor.nvim" },
  { "folke/flash.nvim" },
})

require("vscode-multi-cursor").setup({
  default_mappings = false,
  no_selection = false,
})

-- ── Editor options (subset aligned with ~/.config/nvim/lua/configs.lua) ─────

vim.notify = vim.schedule_wrap(function(msg, level, opts)
  if vim.in_fast_event() then
    return vim.schedule_wrap(vim.notify)(msg, level, opts)
  end
  local ok, vscode = pcall(require, "vscode")
  if ok and vscode.notify then
    vscode.notify(msg, level, opts)
  end
end)

vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.compatible = false
vim.opt.wildignore:append({ "*/node_modules/*" })
vim.opt.path:append({ "**" })
vim.opt.wildmenu = true
vim.cmd("syntax enable")

-- ── Keymaps migrated from native Neovim config ──────────────────────────────

dofile(root .. "/keymaps.lua")

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({
      higroup = "Visual",
      timeout = 120,
    })
  end,
})
