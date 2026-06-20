local M = {}

function M.is_dashboard_buffer(bufnr)
  return vim.bo[bufnr].filetype == "snacks_dashboard" or vim.bo[bufnr].filetype == "pure_dashboard"
end

function M.should_open()
  if vim.fn.argc() > 0 then return false end
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(bufnr) ~= "" then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end
  if vim.api.nvim_buf_line_count(bufnr) > 1 then return false end
  return vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == ""
end

function M.apply_options(window)
  window = window or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(window) then
    return
  end

  vim.api.nvim_set_option_value("number", false, { scope = "local", win = window })
  vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = window })
  vim.wo[window].cursorline = false
  vim.wo[window].list = false
  vim.wo[window].foldcolumn = "0"
  vim.wo[window].signcolumn = "no"
  vim.wo[window].statuscolumn = ""
  vim.wo[window].winbar = ""
end

function M.save_restore_state(window)
  window = window or vim.api.nvim_get_current_win()
  vim.w[window].pure_dashboard_restore_number = vim.go.number
  vim.w[window].pure_dashboard_restore_relativenumber = vim.go.relativenumber
end

function M.restore_options(window)
  window = window or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(window) then
    return
  end
  if M.is_dashboard_buffer(vim.api.nvim_win_get_buf(window)) then
    M.apply_options(window)
    return
  end

  local restore_number = vim.w[window].pure_dashboard_restore_number
  local restore_relativenumber = vim.w[window].pure_dashboard_restore_relativenumber
  if restore_number == nil then
    restore_number = vim.go.number
  end
  if restore_relativenumber == nil then
    restore_relativenumber = vim.go.relativenumber
  end

  vim.api.nvim_set_option_value("number", restore_number, { scope = "local", win = window })
  vim.api.nvim_set_option_value("relativenumber", restore_relativenumber, { scope = "local", win = window })
  require("modules.ui.gutter").apply_window(window)
  vim.w[window].pure_dashboard_restore_number = nil
  vim.w[window].pure_dashboard_restore_relativenumber = nil
end

return M
