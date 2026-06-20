local M = {}

function M.calculate(opts)
  opts = opts or {}
  local fullscreen = opts.fullscreen == true
  local preview_enabled = opts.preview_enabled ~= false
  local layout = opts.layout or "intellij"
  local item_count = opts.item_count or 0
  local result = {}

  if fullscreen then
    result.width = math.max(80, vim.o.columns - 4)
    result.height = math.max(14, vim.o.lines - vim.o.cmdheight - 4)
    result.row = 1
    result.col = 2
  else
    result.width = math.min(130, math.max(88, math.floor(vim.o.columns * 0.86)))
    result.height = math.min(math.max(14, item_count + 4), math.max(14, math.floor(vim.o.lines * 0.68)))
    result.row = math.max(0, math.floor((vim.o.lines - result.height) / 2) - 1)
    result.col = math.max(0, math.floor((vim.o.columns - result.width) / 2))
  end

  if not preview_enabled then
    result.list_width = result.width
    result.list_height = result.height
    result.list_row = result.row
    result.list_col = result.col
    result.preview_width = 0
    result.preview_height = 0
    result.preview_row = result.row
    result.preview_col = result.col
    return result
  end

  if layout == "intellij" then
    result.preview_width = result.width
    result.preview_height = math.max(6, math.floor(result.height * 0.58))
    result.preview_row = result.row
    result.preview_col = result.col
    result.list_width = result.width
    result.list_height = math.max(8, result.height - result.preview_height - 1)
    result.list_row = result.row + result.preview_height + 1
    result.list_col = result.col
    return result
  end

  result.preview_width = math.max(36, math.floor(result.width * 0.44))
  result.list_width = result.width - result.preview_width - 1
  result.preview_height = result.height
  result.preview_row = result.row
  result.preview_col = result.col + result.list_width + 1
  result.list_height = result.height
  result.list_row = result.row
  result.list_col = result.col
  return result
end

function M.list_config(layout, mode, fullscreen)
  return {
    relative = "editor",
    row = layout.list_row,
    col = layout.list_col,
    width = layout.list_width,
    height = layout.list_height,
    style = "minimal",
    border = "rounded",
    title = string.format(" Breakpoints %s%s ", mode, fullscreen and " fullscreen" or ""),
    title_pos = "center",
  }
end

function M.preview_config(layout)
  return {
    relative = "editor",
    row = layout.preview_row,
    col = layout.preview_col,
    width = layout.preview_width,
    height = layout.preview_height,
    style = "minimal",
    border = "rounded",
    title = " Preview ",
    title_pos = "center",
  }
end

function M.apply_list_options(win)
  vim.wo[win].cursorline = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
end

function M.apply_preview_options(win)
  vim.wo[win].cursorline = true
  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
end

return M
