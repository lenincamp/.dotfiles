local M = {}

local function peek_module()
  local ok, peek = pcall(require, "modules.editor.peek")
  if not ok or type(peek.preview_location) ~= "function" then
    return nil
  end
  return peek
end

function M.open_file(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.open_or_peek(location, opts)
  opts = opts or {}
  if not location or not location.filename then
    return false
  end

  local lnum = tonumber(location.lnum) or 1
  local col = tonumber(location.col) or 1

  if opts.peek then
    local peek = peek_module()
    if peek and peek.preview_location({
      filename = location.filename,
      lnum = lnum,
      col = col,
      title = opts.title,
    }) then
      return true
    end
  end

  M.open_file(location.filename)
  if lnum > 0 then
    vim.api.nvim_win_set_cursor(0, { lnum, math.max(0, col - 1) })
  end
  return true
end

function M.open_items_loclist(items, title, opts)
  opts = opts or {}
  if vim.tbl_isempty(items) then
    return false
  end

  vim.fn.setloclist(0, {}, " ", {
    title = title,
    items = items,
  })

  if opts.open_single and #items == 1 then
    vim.cmd("lfirst")
  else
    vim.cmd("lopen")
  end

  return true
end

return M
