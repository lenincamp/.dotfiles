local M = {}

local function reveal_in_netrw(path, attempt)
  if not path or path == "" then
    return
  end

  local name = vim.fn.fnamemodify(path, ":t")
  if name == "" then
    return
  end

  if vim.bo.filetype ~= "netrw" then
    if (attempt or 1) <= 8 then
      vim.defer_fn(function()
        reveal_in_netrw(path, (attempt or 1) + 1)
      end, 20)
    end
    return
  end

  local found = pcall(vim.fn.search, "\\V" .. vim.fn.escape(name, "\\"), "w")
  if found then
    pcall(vim.cmd, "normal! zz")
  end
end

function M.open(cwd, reveal_path)
  local current_file = vim.api.nvim_buf_get_name(0)
  if type(reveal_path) ~= "string" and current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
    reveal_path = current_file
  end

  local target = vim.fs.normalize(cwd or (reveal_path and vim.fn.fnamemodify(reveal_path, ":p:h")) or vim.fn.getcwd())

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.w[win].native_netrw_sidebar then
      vim.api.nvim_set_current_win(win)
      if vim.w.native_netrw_dir == target then
        vim.cmd("close")
        return
      end
      vim.cmd("Explore " .. vim.fn.fnameescape(target))
      vim.w.native_netrw_dir = target
      reveal_in_netrw(reveal_path)
      return
    end
  end

  local width = tonumber(vim.g.netrw_winsize) or 25
  vim.cmd("botright vertical " .. width .. "Vexplore " .. vim.fn.fnameescape(target))
  vim.cmd("vertical resize " .. width)
  vim.wo.winfixwidth = true
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.w.native_netrw_sidebar = true
  vim.w.native_netrw_dir = target
  reveal_in_netrw(reveal_path)
end

return M
