if (not vim.fn.has('clipboard')) then
  print('ERROR: please install clipboard')
end
if vim.fn.has('unnamedplus') then
  vim.opt.clipboard:append { 'unnamedplus' }
else
  vim.opt.clipboard:append { 'unnamed' }
end
