local M = {}

local ansi_namespace = vim.api.nvim_create_namespace("native_ansi_preview")
local ansi_highlight_cache = {}

local function ansi_hex(red, green, blue)
  return string.format("#%02x%02x%02x", red or 0, green or 0, blue or 0)
end

local function ansi_group(style)
  local key = table.concat({ style.fg or "", style.bg or "", style.bold and "bold" or "" }, ":")
  if ansi_highlight_cache[key] then
    return ansi_highlight_cache[key]
  end

  local name = "NativeAnsi" .. tostring(vim.tbl_count(ansi_highlight_cache) + 1)
  vim.api.nvim_set_hl(0, name, {
    fg = style.fg,
    bg = style.bg,
    bold = style.bold or false,
  })
  ansi_highlight_cache[key] = name
  return name
end

local function parse_ansi_sgr(sequence, style)
  local values = {}
  for value in sequence:gmatch("%d+") do
    values[#values + 1] = tonumber(value)
  end
  if #values == 0 then
    values[1] = 0
  end

  local index = 1
  while index <= #values do
    local value = values[index]
    if value == 0 then
      style.fg, style.bg, style.bold = nil, nil, false
    elseif value == 1 then
      style.bold = true
    elseif value == 22 then
      style.bold = false
    elseif value == 39 then
      style.fg = nil
    elseif value == 49 then
      style.bg = nil
    elseif (value == 38 or value == 48) and values[index + 1] == 2 then
      local color = ansi_hex(values[index + 2], values[index + 3], values[index + 4])
      if value == 38 then
        style.fg = color
      else
        style.bg = color
      end
      index = index + 4
    end
    index = index + 1
  end
end

function M.ansi_to_lines(text)
  local lines = {}
  local highlights = {}
  local style = { bold = false }
  local line = ""
  local col = 0

  local function push_highlight(start_col, end_col, snapshot)
    if end_col <= start_col or (not snapshot.fg and not snapshot.bg and not snapshot.bold) then
      return
    end
    highlights[#highlights + 1] = {
      line = #lines + 1,
      start_col = start_col,
      end_col = end_col,
      group = ansi_group(snapshot),
    }
  end

  local index = 1
  while index <= #text do
    local esc_start, esc_end, sgr = text:find("\27%[([%d;]*)m", index)
    local chunk = esc_start and text:sub(index, esc_start - 1) or text:sub(index)
    for part, newline in chunk:gmatch("([^\n]*)(\n?)") do
      if part ~= "" then
        local start_col = col
        line = line .. part
        col = col + #part
        push_highlight(start_col, col, vim.deepcopy(style))
      end
      if newline ~= "" then
        lines[#lines + 1] = line
        line, col = "", 0
      end
      if part == "" and newline == "" then
        break
      end
    end
    if not esc_start then
      break
    end
    parse_ansi_sgr(sgr, style)
    index = esc_end + 1
  end

  if line ~= "" or text:sub(-1) ~= "\n" then
    lines[#lines + 1] = line
  end

  return lines, highlights
end

function M.apply_ansi_highlights(bufnr, highlights)
  if type(highlights) ~= "table" then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ansi_namespace, 0, -1)
  for _, mark in ipairs(highlights) do
    if mark.line and mark.group then
      pcall(vim.api.nvim_buf_set_extmark, bufnr, ansi_namespace, mark.line - 1, mark.start_col or 0, {
        end_col = mark.end_col,
        hl_group = mark.group,
      })
    end
  end
end

function M.set_syntax(bufnr, path)
  local filetype = vim.filetype.match({ filename = path }) or ""
  if filetype == "" then
    return
  end

  vim.bo[bufnr].syntax = filetype
end

function M.open_output_buffer(opts)
  opts = opts or {}
  local name = opts.name or "Output"
  local lines = opts.lines or {}
  local height = opts.height or 16
  local bufnr = nil

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].native_output_name == name then
      bufnr = buf
      break
    end
  end

  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
    pcall(vim.api.nvim_buf_set_name, bufnr, name)
  end

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buflisted = false
  vim.b[bufnr].native_output_name = name
  pcall(vim.treesitter.stop, bufnr)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, #lines > 0 and lines or { "No output" })
  vim.bo[bufnr].modifiable = false
  M.apply_ansi_highlights(bufnr, opts.highlights)
  if opts.syntax then
    vim.bo[bufnr].syntax = opts.syntax
  end

  local wins = vim.fn.win_findbuf(bufnr)
  if #wins > 0 and vim.api.nvim_win_is_valid(wins[1]) then
    vim.api.nvim_set_current_win(wins[1])
  else
    vim.cmd("botright " .. height .. "split")
    vim.api.nvim_win_set_buf(0, bufnr)
  end

  vim.wo.wrap = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.cursorline = true

  return bufnr
end

return M
