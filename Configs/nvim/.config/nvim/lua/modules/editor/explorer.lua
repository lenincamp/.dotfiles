local M = {}

function M.lexp_is_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "netrw" then
      return true
    end
  end
  return false
end

function M.get_file_dir()
  local file = vim.api.nvim_buf_get_name(0)

  if file == "" then
    return vim.fn.getcwd()
  end

  return vim.fn.fnamemodify(file, ":p:h"), file
end

function M.get_project_root(dir)
  return vim.fs.root(dir, { ".git" }) or vim.fn.getcwd()
end

function M.reveal_in_netrw(path)
  if not path or path == "" then
    return
  end

  local name = vim.fs.basename(path)

  vim.defer_fn(function()
    if vim.bo.filetype ~= "netrw" then
      return
    end

    pcall(vim.fn.search, "\\V" .. vim.fn.escape(name, "\\"))
    pcall(vim.cmd.normal, { "zz", bang = true })
  end, 50)
end
return M
