local M = {}

local function each_window(callback)
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(window) then
      callback(window)
    end
  end
end

function M.set(enabled)
  each_window(function(window)
    if enabled and window ~= vim.api.nvim_get_current_win() then
      if vim.w[window].pure_dim_saved_winhighlight == nil then
        vim.w[window].pure_dim_saved_winhighlight = vim.wo[window].winhighlight
      end
      vim.wo[window].winhighlight = "Normal:Comment,NormalNC:Comment,EndOfBuffer:Comment"
    elseif vim.w[window].pure_dim_saved_winhighlight ~= nil then
      vim.wo[window].winhighlight = vim.w[window].pure_dim_saved_winhighlight
      vim.w[window].pure_dim_saved_winhighlight = nil
    end
  end)
end

function M.configure_autocmd(enabled)
  local group = vim.api.nvim_create_augroup("pure_ui_dim_refresh", { clear = true })
  if not enabled then
    return
  end

  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      M.set(true)
    end,
  })
end

function M.apply(enabled)
  M.configure_autocmd(enabled == true)
  M.set(enabled == true)
end

return M
