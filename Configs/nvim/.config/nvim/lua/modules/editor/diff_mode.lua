local M = {}
local registry = require("modules.bootstrap.registry")

-- Diff navigation (merged from diff_navigation.lua)
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
    if not M.is_diff_session() then return end
    local args = { ... }
    if vim.wo.diff then
      action(unpack(args))
      return
    end
    local diff_windows = M.get_diff_windows()
    local target = diff_windows[1]
    if target and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_win_call(target, function() action(unpack(args)) end)
    end
  end
end

M.diff_jump_next = M.with_diff_window(function() vim.cmd("normal! ]czz") end)
M.diff_jump_prev = M.with_diff_window(function() vim.cmd("normal! [czz") end)

function M.enable_diff_mode()
  vim.cmd("diffthis")
  registry.setup_diff_mappings()
end

function M.disable_diff_mode()
  vim.cmd("diffoff")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      registry.cleanup_diff_mappings(buf)
    end
  end
end

function M.toggle_diff_mode()
  if M.is_diff_session() then
    M.disable_diff_mode()
  else
    M.enable_diff_mode()
  end
end

local function replace_diffopt_entry(opts, prefix, value)
  local out, replaced = {}, false
  for _, item in ipairs(opts) do
    if vim.startswith(item, prefix .. ":") then
      if not replaced then
        table.insert(out, prefix .. ":" .. tostring(value))
        replaced = true
      end
    else
      table.insert(out, item)
    end
  end
  if not replaced then
    table.insert(out, prefix .. ":" .. tostring(value))
  end
  return out
end

local function current_diff_profile()
  local context = 8
  for _, item in ipairs(vim.opt.diffopt:get()) do
    local val = item:match("^context:(%d+)$")
    if val then
      context = tonumber(val) or context
      break
    end
  end
  if context <= 2 then
    return "focused"
  end
  return "review"
end

function M.toggle_diff_profile()
  local profile = current_diff_profile()
  local next_profile = (profile == "review") and "focused" or "review"

  local cfg = {
    review = { context = 8, linematch = 120 },
    focused = { context = 2, linematch = 60 },
  }

  local opts = vim.opt.diffopt:get()
  opts = replace_diffopt_entry(opts, "context", cfg[next_profile].context)
  opts = replace_diffopt_entry(opts, "linematch", cfg[next_profile].linematch)
  vim.opt.diffopt = opts
  vim.g.pure_diff_profile = next_profile

  vim.notify(
    string.format("Diff profile: %s (context:%d, linematch:%d)", next_profile, cfg[next_profile].context, cfg[next_profile].linematch),
    vim.log.levels.INFO
  )
end

return M
