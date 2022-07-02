local set = vim.opt
vim.g.netrw_keepdir = 0
-- vim.g.netrw_winsize = -28
vim.g.netrw_localcopydircmd = "cp -r"
-- vim.g.netrw_browse_split = 4
vim.g.netrw_altv = 1
-- vim.g.netrw_liststyle = 3 --tree-view
vim.cmd([[
  let g:netrw_list_hide = '\(^\|\s\s\)\zs\.\S\+'
  let g:netrw_sort_sequence = '[\/]$,*'
  hi! link netrwMarkFile Search
  " Change directory to the current buffer when opening files.
  "set autochdir
]])
-- set.shell = "/bin/sh"

set.expandtab = true
set.smarttab = true
set.shiftwidth = 2
set.tabstop = 2

set.hlsearch = true
set.incsearch = true
set.ignorecase = true
set.smartcase = true

set.termguicolors = true
set.showmode = false
set.splitbelow = true
set.splitright = true
set.wrap = true
set.breakindent = true
set.scrolloff = 5
set.fileencoding = "utf-8"
set.conceallevel = 2

set.relativenumber = true
set.cursorline = true
set.wildmenu = true
set.completeopt = "menu,menuone,noselect"

set.hidden = true
set.mouse = "a"
set.mousefocus = true

set.smartcase = true -- but don't ignore it, when search string contains uppercase letters
--set.nocompatible = true
set.backspace = "indent,eol,start" --allow backspacing over everything in insert mode
set.clipboard = "unnamed"
set.lazyredraw = true
set.undofile = true
--set.noswapfile = true
--set.nobackup = true
--set.nowritebackup = true
set.number = true

set.ai = true --auto ident
set.si = true --smart ident
set.syntax = "on"
set.inccommand = "split"
set.colorcolumn:append({ "101" })
set.wildignore = { "*/cache/*", "*/tmp/*", "*/node_modules/*" }
set.foldmethod = "indent"
set.foldnestmax = 10
set.foldlevel = 3
set.foldenable = true
set.path:append({ "**" })

-- Highlight on yank
vim.cmd([[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=400, on_visual=true}
  augroup end
  augroup AuBufWritePre
    autocmd!
    autocmd BufWritePre * let current_pos = getpos(".")
    autocmd BufWritePre * silent! undojoin | %s/\s\+$//e
    autocmd BufWritePre * silent! undojoin | %s/\n\+\%$//e
    autocmd BufWritePre * call setpos(".", current_pos)
    autocmd BufWritePre,FileWritePre * silent! call mkdir(expand('<afile>:p:h'), 'p')
  augroup end
  set noswapfile
  set nobackup
  set nowritebackup
]])

require("options/salesforce")
require("options/colorscheme")
vim.notify = require("notify")
