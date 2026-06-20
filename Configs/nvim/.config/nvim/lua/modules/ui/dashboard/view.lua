local M = {}

local ns = vim.api.nvim_create_namespace("pure_dashboard")

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#39FFB6", bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardSpecial", { fg = "#19E3FF", bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = "#9AFBFF", bold = true })
end

function M.apply_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for row, line in ipairs(lines) do
    local line_index = row - 1
    if line:find("%[.%]") then
      local key_start, key_end = line:find("%[.%]")
      local nonblank = line:find("%S") or 1
      if nonblank < key_start then
        vim.api.nvim_buf_add_highlight(bufnr, ns, "SnacksDashboardSpecial", line_index, nonblank - 1, key_start - 1)
      end
      vim.api.nvim_buf_add_highlight(bufnr, ns, "SnacksDashboardKey", line_index, key_start - 1, key_end)
      if key_end < #line then
        vim.api.nvim_buf_add_highlight(bufnr, ns, "SnacksDashboardSpecial", line_index, key_end, -1)
      end
    elseif line:find("%S") then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "SnacksDashboardHeader", line_index, 0, -1)
    end
  end
end

return M
