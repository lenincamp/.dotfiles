local M = {}

local keywords = { "TODO", "FIX", "FIXME", "HACK", "WARN", "PERF", "NOTE", "TEST" }
local urgent_keywords = { "TODO", "FIX", "FIXME" }
local pattern = [[\v<(TODO|FIX|FIXME|HACK|WARN|PERF|NOTE|TEST)>]]

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "TODO" })
end

local function rg_pattern(items)
  return table.concat(items, "|")
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
    vim.fn.matchadd("Todo", pattern, 10, -1, { window = win }),
  }
end

local function refresh_current_window()
  add_matches(vim.api.nvim_get_current_win())
end

local function todo_qflist(items, title)
  local command = { "rg", "--vimgrep", "--hidden", "--glob", "!.git", "--glob", "!nvim.log", rg_pattern(items) }
  local result = vim.system(command, { cwd = vim.fn.getcwd(), text = true }):wait()
  local lines = vim.split(result.stdout or "", "\n", { plain = true, trimempty = true })
  local qf = {}

  for _, line in ipairs(lines) do
    local file, lnum, col, text = line:match("^([^:]+):(%d+):(%d+):(.*)$")
    if file then
      qf[#qf + 1] = {
        filename = vim.fs.normalize(vim.fn.getcwd() .. "/" .. file),
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
      }
    end
  end

  vim.fn.setqflist({}, " ", { title = title, items = qf })
  if #qf > 0 then
    vim.cmd("copen")
  else
    notify(title .. ": no results")
  end
end

local function jump(direction)
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

  vim.keymap.set("n", "<leader>st", function()
    todo_qflist(keywords, "TODO comments")
  end, { desc = "Search TODO" })

  vim.keymap.set("n", "<leader>sT", function()
    todo_qflist(urgent_keywords, "TODO/FIX/FIXME comments")
  end, { desc = "Search TODO/FIX/FIXME" })
end

return M
