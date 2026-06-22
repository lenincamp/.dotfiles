local M = {}

M._setup_done = false

function M.open_cwd()
  require("picker").open_terminal(vim.fn.getcwd())
end

function M.open_root()
  local picker = require("picker")
  picker.open_terminal(picker.root())
end

function M.setup()
  if M._setup_done then
    return
  end
  M._setup_done = true

  local map = vim.keymap.set

  map("n", "<leader>ft", M.open_cwd, { desc = "Terminal (cwd)" })
  map("n", "<leader>fT", M.open_root, { desc = "Terminal (root)" })
  map({ "n", "t" }, "<C-/>", M.open_root, { desc = "Terminal (root)" })
  map({ "n", "t" }, "<C-_>", M.open_root, { desc = "Terminal (root) [<C-/> compat]" })
end

return M
