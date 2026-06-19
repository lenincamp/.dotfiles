local M = {}

function M.is_enabled()
  if vim.g.transparent_background == nil then vim.g.transparent_background = true end
  return vim.g.transparent_background == true
end

function M.is_effective()
  return M.is_enabled()
end

function M.apply(groups)
  if M.is_enabled() then
    for _, group in ipairs(groups or {}) do
      local ok, highlight = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
      if ok then
        highlight.bg = nil
        highlight.ctermbg = nil
        vim.api.nvim_set_hl(0, group, highlight)
      end
    end
  end

  local ok_blink, blink_selection = pcall(vim.api.nvim_get_hl, 0, { name = "BlinkCmpMenuSelection", link = false })
  if ok_blink and next(blink_selection) ~= nil then return end

  local ok_pmenu, pmenu_selection = pcall(vim.api.nvim_get_hl, 0, { name = "PmenuSel", link = false })
  if ok_pmenu and next(pmenu_selection) ~= nil then
    vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { link = "PmenuSel" })
    return
  end

  local ok_cursor, cursor_line = pcall(vim.api.nvim_get_hl, 0, { name = "CursorLine", link = false })
  if ok_cursor and next(cursor_line) ~= nil then
    vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { link = "CursorLine" })
  end
end

return M
