require("modules.autocmds.editor").setup()
require("modules.autocmds.java").setup()
require("modules.autocmds.diff").setup()
require("modules.autocmds.large_files").setup()
require("modules.git.commands").setup()

vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "silent !zellij action switch-mode normal",
})