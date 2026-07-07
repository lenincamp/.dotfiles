local M = {}

M._setup_done = false

local function git_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] then
    return out[1]
  end
  return vim.fn.getcwd()
end

local function open_terminal(cwd)
  vim.cmd("botright 15split")
  vim.fn.termopen({ vim.o.shell }, { cwd = cwd })
  vim.cmd("startinsert")
end

function M.open_cwd()
  open_terminal(vim.fn.getcwd())
end

function M.open_root()
  open_terminal(git_root())
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
