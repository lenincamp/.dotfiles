vim.cmd([[
if exists("&termguicolors") && exists("&winblend")
  set winblend=0
  set wildoptions=pum
  set pumblend=5
  set background=dark
  filetype plugin indent on
endif
runtime ./colors/OneHalfDark.vim
runtime ./colors/NeoSolarized.vim
]])

-- vim.cmd([[
--   let output =  system("defaults read -g AppleInterfaceStyle")
--   if v:shell_error != 0
--       set background=light
--   else
--     set background=dark
--   endif
-- ]])

vim.cmd([[
  augroup BgHighlight
    autocmd!
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
  augroup END
  "if &term =~ "screen"
  "  autocmd BufEnter * if bufname("") !~ "^?[A-Za-z0-9?]*://" | silent! exe '!echo -n "\ek[`hostname`:`basename $PWD`/`basename %`]\e\\"' | endif
  "  autocmd VimLeave * silent!  exe '!echo -n "\ek[`hostname`:`basename $PWD`]\e\\"'
  "endif

]])

vim.cmd([[
"colorscheme desert
"set t_Co=256
"highlight CursorLine term=bold cterm=NONE ctermbg=none  ctermfg=none
"highlight lineNr term=bold cterm=NONE ctermbg=none  ctermfg=none
"highlight CursorLineNr term=bold cterm=none ctermbg=none ctermfg=yellow
"highlight ColorColumn guibg=Grey30
]])

vim.cmd([[
let g:gruvbox_material_cursor='green'
let g:gruvbox_material_background = 'hard'
"let g:gruvbox_material_transparent_background=1
"let g:gruvbox_material_enable_italic = 1
"let g:gruvbox_material_disable_italic_comment = 1
"colorscheme gruvbox-material
"--hi Normal guibg=NONE ctermbg=NONE
"hi Visual gui=NONE guibg=Gray40 guifg=NONE
"hi MatchParen ctermbg=985450 guibg=Gray40 term=none cterm=none gui=italic
]])
vim.cmd([[
if &diff
  "set noreadonly
  "set foldmethod=diff
  augroup saveupdatediff
    autocmd!
    autocmd BufWritePost * diffupdate
  augroup END
endif
]])

vim.cmd([[
let g:PaperColor_Theme_Options = {
  \   'theme': {
  \     'default.dark': {
  \       'transparent_background': 1,
  \       'allow_italic': 1,
  \       'allow_bold': 0
  \     }
  \   }
  \ }
]])
-- vim.cmd([[ colorscheme PaperColor ]])
-- vim.g.solarized_statusline = "normal"

vim.g.solarized_termtrans = 1
vim.g.neosolarized_termtrans = 1

-- vim.cmd([[
--   colorscheme solarized-flat
--   hi CursorLine ctermbg=23 guifg=none guibg=#073642 guisp=#eee8d5
-- ]])
require("nightfox").setup({
	options = {
		transparent = true, -- Disable setting the background color
		terminal_colors = true,
	},
})

vim.cmd([[
  "colorscheme terafox
  colorscheme NeoSolarized
]])

require("notify").setup({
	-- Animation style (see below for details)
	stages = "fade_in_slide_out",
	-- Function called when a new window is opened, use for changing win settings/config
	on_open = nil,
	-- Function called when a window is closed
	on_close = nil,
	-- Render function for notifications. See notify-render()
	render = "default",
	-- Default timeout for notifications
	timeout = 5000,
	-- Max number of columns for messages
	max_width = nil,
	-- Max number of lines for a message
	max_height = nil,
	-- For stages that change opacity this is treated as the highlight behind the window
	-- Set this to either a highlight group, an RGB hex value e.g. "#000000" or a function returning an RGB code for dynamic values
	background_colour = "#000000",
	-- Minimum width for notification windows
	minimum_width = 50,
})
