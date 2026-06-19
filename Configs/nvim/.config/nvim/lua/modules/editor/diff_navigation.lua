local M = {}

function M.get_diff_windows()
  local diff_windows = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      diff_windows[#diff_windows + 1] = win
    end
  end
  return diff_windows
end

function M.is_diff_session()
  return #M.get_diff_windows() >= 2
end

function M.with_diff_window(action)
  return function(...)
    if not M.is_diff_session() then
      return
    end

    local args = { ... }
    if vim.wo.diff then
      action(unpack(args))
      return
    end

    local diff_windows = M.get_diff_windows()
    local target = diff_windows[1]
    if target and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_win_call(target, function()
        action(unpack(args))
      end)
    end
  end
end

local function raw_diff_jump_next()
  vim.cmd("normal! ]czz")
end

local function raw_diff_jump_prev()
  vim.cmd("normal! [czz")
end

M.diff_jump_next = M.with_diff_window(raw_diff_jump_next)
M.diff_jump_prev = M.with_diff_window(raw_diff_jump_prev)

return M
