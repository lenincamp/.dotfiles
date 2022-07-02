" colorscheme molokai
" Better gitcommit messages
" colorscheme
set t_Co=256
syntax enable
colorscheme slate
set clipboard=unnamedplus
hi diffAdded   ctermbg=NONE ctermfg=46  cterm=NONE guibg=NONE guifg=#00FF00 gui=NONE
hi diffRemoved ctermbg=NONE ctermfg=196 cterm=NONE guibg=NONE guifg=#FF0000 gui=NONE
hi link diffLine String
hi link diffSubname Normal
highlight CursorLine term=bold cterm=NONE ctermbg=none  ctermfg=none
highlight lineNr term=bold cterm=NONE ctermbg=none  ctermfg=none
highlight CursorLineNr term=bold cterm=none ctermbg=none ctermfg=yellow
highlight ColorColumn guibg=Grey30
set bg=dark
