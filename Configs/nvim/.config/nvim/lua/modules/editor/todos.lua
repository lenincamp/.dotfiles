local M = {}

local DEFAULT_KEYWORDS = { "TODO", "FIX", "FIXME", "HACK", "WARN", "PERF", "NOTE", "TEST" }

local function highlight_pattern()
  return [[\v<(]] .. table.concat(DEFAULT_KEYWORDS, "|") .. [[)>]]
end

local function clear_matches(win)
  local ids = vim.w[win].pure_todo_match_ids
  if type(ids) == "table" then
    for _, id in ipairs(ids) do
      pcall(vim.fn.matchdelete, id, win)
    end
  end
  vim.w[win].pure_todo_match_ids = nil
end

local function add_matches(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then
    clear_matches(win)
    return
  end

  clear_matches(win)
  vim.w[win].pure_todo_match_ids = {
    vim.fn.matchadd("Todo", highlight_pattern(), 10, -1, { window = win }),
  }
end

local function refresh_current_window()
  add_matches(vim.api.nvim_get_current_win())
end

local function jump(direction)
  local pattern = highlight_pattern()
  local flags = direction < 0 and "bW" or "W"
  if vim.fn.search(pattern, flags) == 0 then
    vim.cmd(direction < 0 and "normal! G$" or "normal! gg0")
    vim.fn.search(pattern, flags)
  end
  vim.cmd("normal! zv")
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = vim.api.nvim_create_augroup("pure_native_todo_matches", { clear = true }),
    callback = refresh_current_window,
  })

  vim.keymap.set("n", "]t", function()
    jump(1)
  end, { desc = "Next TODO" })

  vim.keymap.set("n", "[t", function()
    jump(-1)
  end, { desc = "Prev TODO" })
end

M.setup()

return M
