vim.cmd([[
  runtime ./indent/*.vim
  runtime ./syntax/*.vim
]])
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
