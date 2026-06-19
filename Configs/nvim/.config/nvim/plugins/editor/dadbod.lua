vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_execute_on_save = 0
vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod-ui"

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sql", "mysql", "plsql" },
  callback = function()
    vim.bo.omnifunc = "vim_dadbod_completion#omni"
  end,
})

local map = vim.keymap.set
map("n", "<leader>Du", "<cmd>DBUIToggle<CR>", { desc = "Dadbod: toggle UI" })
map("n", "<leader>Df", "<cmd>DBUIFindBuffer<CR>", { desc = "Dadbod: find buffer" })
map("n", "<leader>Da", "<cmd>DBUIAddConnection<CR>", { desc = "Dadbod: add connection" })
map("n", "<leader>Dr", "<cmd>DBUIRenameBuffer<CR>", { desc = "Dadbod: rename buffer" })
