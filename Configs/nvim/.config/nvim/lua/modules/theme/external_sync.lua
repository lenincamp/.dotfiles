local M = {}

local state = {
  pending = false,
  theme = nil,
}

function M.request(theme, opts)
  opts = opts or {}

  if type(opts.immediate) == "function" then
    pcall(opts.immediate, theme)
  end

  if type(opts.runner) ~= "function" then
    return
  end

  if #vim.api.nvim_list_uis() == 0 then
    if opts.headless_inline ~= false then
      opts.runner(theme)
    end
    return
  end

  state.theme = theme
  if state.pending then
    return
  end

  state.pending = true
  local delay = tonumber(vim.g.pure_external_sync_delay_ms) or 20
  if delay < 0 then
    delay = 0
  end

  vim.defer_fn(function()
    state.pending = false
    local target = state.theme
    state.theme = nil
    if target then
      pcall(opts.runner, target)
    end
  end, delay)
end

return M
