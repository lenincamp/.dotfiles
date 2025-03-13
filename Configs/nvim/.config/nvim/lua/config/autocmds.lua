-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  command = "set nopaste",
})

-- Fix canceallevel for json files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.wo.spell = false
    vim.wo.canceallevel = 0
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.g.autoformat = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  group = vim.api.nvim_create_augroup("java", { clear = true }),
  callback = function(opts)
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.g.autoformat = false
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = { "*.java" },
  callback = function()
    local _, _ = pcall(vim.lsp.codelens.refresh)
  end,
})

local function apply_folds()
  vim.cmd("normal! zM")
  vim.cmd("normal! 3zr")
  local import_line = vim.fn.search("^import", "n")
  if import_line > 0 then
    vim.api.nvim_win_set_cursor(0, { import_line, 0 })
    vim.cmd("normal! zc")
  end
end

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = { "*.java", "*.js", "*.jsx", "*.ts", "*.tsx" },
  callback = apply_folds,
})
