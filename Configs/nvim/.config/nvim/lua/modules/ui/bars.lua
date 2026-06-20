local M = {}
local highlights = require("modules.ui.highlights")

local mode_names = {
  n = "NORMAL",
  no = "O-PEND",
  nov = "O-PEND",
  noV = "O-PEND",
  ["no\22"] = "O-PEND",
  niI = "NORMAL",
  niR = "NORMAL",
  niV = "NORMAL",
  nt = "NORMAL",
  v = "VISUAL",
  vs = "VISUAL",
  V = "V-LINE",
  Vs = "V-LINE",
  ["\22"] = "V-BLOCK",
  ["\22s"] = "V-BLOCK",
  s = "SELECT",
  S = "S-LINE",
  ["\19"] = "S-BLOCK",
  i = "INSERT",
  ic = "INSERT",
  ix = "INSERT",
  R = "REPLACE",
  Rc = "REPLACE",
  Rx = "REPLACE",
  Rv = "V-REPLACE",
  c = "COMMAND",
  cv = "EX",
  ce = "EX",
  r = "PROMPT",
  rm = "MORE",
  ["r?"] = "CONFIRM",
  ["!"] = "SHELL",
  t = "TERMINAL",
}

local winbar_apply_events = {
  BufEnter = true,
  BufFilePost = true,
  BufWinEnter = true,
  WinNew = true,
}

local function should_refresh_for_event(event)
  if vim.g.pure_ui_statusline_enabled == true then
    return true
  end
  if vim.g.pure_ui_tabline_enabled == true then
    return true
  end
  if vim.g.pure_ui_winbar_enabled ~= false then
    return event ~= "DiagnosticChanged" and event ~= "DirChanged" and event ~= "TabEnter"
  end
  return false
end

local function esc_status(text)
  return tostring(text or ""):gsub("%%", "%%%%")
end

local function current_window_buffer()
  local window = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(window) then
    window = vim.api.nvim_get_current_win()
  end
  return window, vim.api.nvim_win_get_buf(window)
end

local function buffer_label(buffer)
  local name = vim.api.nvim_buf_get_name(buffer)
  if name ~= "" then
    return vim.fn.fnamemodify(name, ":~:.")
  end

  local filetype = vim.bo[buffer].filetype
  if filetype ~= "" then
    return "[" .. filetype .. "]"
  end

  return "[No Name]"
end

local function buffer_name(buffer)
  local name = vim.api.nvim_buf_get_name(buffer)
  if name == "" then
    return buffer_label(buffer), ""
  end

  local filename = vim.fn.fnamemodify(name, ":t")
  local parent = vim.fn.fnamemodify(name, ":~:.:h")
  if parent == "." then
    parent = ""
  end
  return filename, parent
end

local function shorten(text, max_width)
  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end

  local shortened = vim.fn.pathshorten(text)
  if vim.fn.strdisplaywidth(shortened) <= max_width then
    return shortened
  end

  if max_width <= 4 then
    return string.rep(".", max_width)
  end

  return "..." .. shortened:sub(-(max_width - 3))
end

local function diagnostics_text(buffer, width)
  if width < 90 then
    return ""
  end

  local counts = vim.diagnostic.count(buffer)
  local error_count = counts[vim.diagnostic.severity.ERROR] or 0
  local warning_count = counts[vim.diagnostic.severity.WARN] or 0
  local parts = {}

  if error_count > 0 then
    parts[#parts + 1] = "%#DiagnosticError#E" .. error_count .. "%#StatusLine#"
  end
  if warning_count > 0 then
    parts[#parts + 1] = "%#DiagnosticWarn#W" .. warning_count .. "%#StatusLine#"
  end

  return table.concat(parts, " ")
end

local function tab_modified(tabpage)
  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local buffer = vim.api.nvim_win_get_buf(window)
    if vim.api.nvim_buf_is_valid(buffer) and vim.bo[buffer].modified then
      return true
    end
  end
  return false
end

local function tab_label(tabpage)
  local windows = vim.api.nvim_tabpage_list_wins(tabpage)
  if #windows == 0 then
    return "[No Window]"
  end

  local buffer = vim.api.nvim_win_get_buf(windows[1])
  return vim.fn.fnamemodify(buffer_label(buffer), ":t")
end

local function render_tabs()
  local current = vim.api.nvim_get_current_tabpage()
  local segments = {}

  for index, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local highlight = tabpage == current and "%#TabLineSel#" or "%#TabLine#"
    local modified = tab_modified(tabpage) and " +" or ""
    segments[#segments + 1] = string.format("%s %d:%s%s ", highlight, index, esc_status(tab_label(tabpage)), modified)
  end

  return table.concat(segments)
end

local function render_buffers()
  local infos = vim.fn.getbufinfo({ buflisted = 1 })
  if #infos == 0 then
    return "%#TabLine# [No Buffers] "
  end

  local current = vim.api.nvim_get_current_buf()
  local segments = {}

  for _, info in ipairs(infos) do
    local highlight = info.bufnr == current and "%#TabLineSel#" or "%#TabLine#"
    local label = info.name ~= "" and vim.fn.fnamemodify(info.name, ":t") or "[No Name]"
    local modified = info.changed == 1 and " +" or ""
    segments[#segments + 1] = string.format("%s %d:%s%s ", highlight, info.bufnr, esc_status(label), modified)
  end

  return table.concat(segments)
end

function M.winbar()
  local window, buffer = current_window_buffer()
  if vim.bo[buffer].buftype ~= "" then
    return ""
  end

  local width = vim.api.nvim_win_get_width(window)
  local full_label = buffer_label(buffer)
  local filename, parent = buffer_name(buffer)
  local modified = vim.bo[buffer].modified and " +" or ""
  local budget = math.max(12, width - vim.fn.strdisplaywidth(modified) - 4)
  local left
  if vim.fn.strdisplaywidth(full_label) <= budget then
    left = "%#WinBarFile# " .. esc_status(full_label) .. "%#WinBarMod#" .. modified
  elseif parent ~= "" and width >= 48 and vim.fn.strdisplaywidth(filename .. "  " .. parent) <= budget then
    left = "%#WinBarFile# " .. esc_status(filename) .. "%#WinBarPath#  " .. esc_status(parent) .. "%#WinBarMod#" .. modified
  else
    left = "%#WinBarFile# " .. esc_status(shorten(full_label, budget)) .. "%#WinBarMod#" .. modified
  end

  return left .. " "
end

local function setup_highlights()
  local pmenu = vim.api.nvim_get_hl(0, { name = "Pmenu", link = false })
  local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  local winbar_fg = pmenu.fg or comment.fg
  local path_fg = comment.fg or winbar_fg

  vim.api.nvim_set_hl(0, "WinBar", { fg = winbar_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { fg = path_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarFile", { fg = winbar_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarPath", { fg = path_fg, bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarMod", { fg = path_fg, bg = "NONE" })
end

function M.statusline()
  local window, buffer = current_window_buffer()
  local buftype = vim.bo[buffer].buftype
  if buftype ~= "" then
    local label = vim.bo[buffer].filetype ~= "" and vim.bo[buffer].filetype or buftype
    return " " .. esc_status(label) .. " "
  end

  local width = vim.api.nvim_win_get_width(window)
  local mode = mode_names[vim.api.nvim_get_mode().mode] or "UNKNOWN"
  local label = shorten(buffer_label(buffer), math.max(20, math.floor(width * 0.45)))
  local modified = vim.bo[buffer].modified and " [+]" or ""
  local cursor = vim.api.nvim_win_get_cursor(window)
  local line = cursor[1]
  local column = cursor[2] + 1
  local total = math.max(vim.api.nvim_buf_line_count(buffer), 1)
  local percent = math.floor((line / total) * 100)
  local right = diagnostics_text(buffer, width)

  if right ~= "" then
    right = right .. "  "
  end

  if width >= 72 then
    right = right .. string.format("%s  %d:%d  %d%%%%", vim.bo[buffer].filetype ~= "" and vim.bo[buffer].filetype or "text", line, column, percent)
  else
    right = right .. string.format("%d:%d", line, column)
  end

  return string.format(" %%#StatusLine#%s  %%<%s%s %%=%s ", mode, esc_status(label), modified, right)
end

function M.tabline()
  local mode = vim.g.pure_tabline_mode or "tabs"
  local left = mode == "buffers" and render_buffers() or render_tabs()
  local cwd = esc_status(vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))
  return "%<" .. left .. "%#TabLineFill#%=%#TabLine# cwd: " .. cwd .. " "
end

function M.refresh()
  vim.cmd("redrawstatus")
end

function M.apply_winbar(enable)
  local value = enable and "%{%v:lua.PureUIBars.winbar()%}" or ""
  vim.o.winbar = value

  for _, window in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(window) then
      local buffer = vim.api.nvim_win_get_buf(window)
      vim.wo[window].winbar = (enable and vim.bo[buffer].buftype == "") and value or ""
    end
  end
end

function M.apply_winbar_for_window(window)
  if not vim.api.nvim_win_is_valid(window) then
    return
  end

  local enable = vim.g.pure_ui_winbar_enabled ~= false
  local value = enable and "%{%v:lua.PureUIBars.winbar()%}" or ""
  local buffer = vim.api.nvim_win_get_buf(window)
  vim.wo[window].winbar = (enable and vim.bo[buffer].buftype == "") and value or ""
end

function M.apply()
  vim.o.statusline = "%!v:lua.PureUIBars.statusline()"
  vim.o.tabline = "%!v:lua.PureUIBars.tabline()"
  M.apply_winbar(vim.g.pure_ui_winbar_enabled ~= false)
  M.refresh()
end

function M.setup()
  setup_highlights()

  _G.PureUIBars = {
    statusline = M.statusline,
    tabline = M.tabline,
    winbar = M.winbar,
  }

  _G.PureUIBarsApply = M.apply

  highlights.register("bars", setup_highlights)

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufFilePost",
    "BufWinEnter",
    "BufModifiedSet",
    "BufWritePost",
    "DiagnosticChanged",
    "DirChanged",
    "TabEnter",
    "VimResized",
    "WinNew",
  }, {
    group = vim.api.nvim_create_augroup("pure_native_bars_refresh", { clear = true }),
    callback = function(args)
      if winbar_apply_events[args.event] then
        M.apply_winbar_for_window(vim.api.nvim_get_current_win())
      end
      if should_refresh_for_event(args.event) then
        M.refresh()
      end
    end,
  })

  M.apply()
end

return M
