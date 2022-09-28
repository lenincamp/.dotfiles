vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.winblend = 0
vim.opt.wildoptions = 'pum'
vim.opt.pumblend = 5
vim.opt.background = 'dark'


local augroup = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  pattern = '*',
  group = augroup,
  desc = 'Show highlight when copy text',
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 400, on_visual = true }
  end
})

-- Highlight on yank
-- vim.cmd([[
--   " augroup YankHighlight
--   "   autocmd!
--   "   autocmd TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=400, on_visual=true}
--   " augroup end
--   " augroup AuBufWritePre
--   "   autocmd!
--   "   autocmd BufWritePre * let current_pos = getpos(".")
--   "   autocmd BufWritePre * silent! undojoin | %s/\s\+$//e
--   "   autocmd BufWritePre * silent! undojoin | %s/\n\+\%$//e
--   "   autocmd BufWritePre * call setpos(".", current_pos)
--   "   autocmd BufWritePre,FileWritePre * silent! call mkdir(expand('<afile>:p:h'), 'p')
--   " augroup end
--   " set noswapfile
--   " set nobackup
--   " set nowritebackup
-- ]])


vim.cmd([[
  autocmd BufNewFile,BufRead *.apxc,*.apxt,*.cls,*.trigger,*.tgr set filetype=apex
  autocmd BufNewFile,BufRead *.vfp,*.vfc,*.page,*.component set filetype=visualforce
  autocmd BufNewFile,BufRead *.log set filetype=apexlog
  autocmd BufNewFile,BufRead *.approvalProcess,*.globalValueSet,*.layout,*.obj,*.objectTranslation,*.permissionSet,*.tab,*.translation set filetype=xml
]])

vim.cmd([[
" aura files
augroup aura
	au!
	au BufRead,BufNewFile */aura/*.app set filetype=aura-xml | set syntax=aura-xml
	au BufRead,BufNewFile */aura/*.cmp set filetype=aura-xml | set syntax=aura-xml
	au BufRead,BufNewFile */aura/*.evt set filetype=aura-xml | set syntax=aura-xml
	au BufRead,BufNewFile */aura/*.design set filetype=aura-xml | set syntax=aura-xml
	au BufRead,BufNewFile */aura/*.intf set filetype=apex.aura.html | set syntax=html
	au BufRead,BufNewFile */aura/*.auradoc set filetype=apex.aura.html | set syntax=html
augroup END
]])

vim.cmd([[
" basic detection for non code files (detecting these allows loading the
" plugin when one of such files is opened)
augroup apexXml
	au!
    au BufRead,BufNewFile */objects/*.object set filetype=apex.xml | set syntax=xml
    au BufRead,BufNewFile */profiles/*.profile set filetype=apex.xml | set syntax=xml
    au BufRead,BufNewFile */layouts/*.layout set filetype=apex.xml | set syntax=xml
    au BufRead,BufNewFile */workflows/*.workflow set filetype=apex.xml | set syntax=xml
    au BufRead,BufNewFile */package.xml set filetype=apexe.xml | set syntax=xml
    au BufRead,BufNewFile */customMetadata/*.md set filetype=apex.xml | set syntax=xml
augroup END
]])
