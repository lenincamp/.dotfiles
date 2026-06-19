local M = {}

local function num_to_hex(color)
  if type(color) ~= "number" then return nil end
  return string.format("#%06x", color)
end

local function read_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if not ok or type(hl) ~= "table" then return {} end
  return hl
end

local function first_hex(...)
  for i = 1, select("#", ...) do
    local hex = num_to_hex(select(i, ...))
    if hex then return hex end
  end
  return nil
end

local function first_hl_fg(names)
  for _, name in ipairs(names or {}) do
    local hl = read_hl(name)
    local hex = first_hex(hl.fg)
    if hex then return hex end
  end
  return nil
end

local function first_hl_bg(names)
  for _, name in ipairs(names or {}) do
    local hl = read_hl(name)
    local hex = first_hex(hl.bg)
    if hex then return hex end
  end
  return nil
end

local function hex_to_rgb(hex)
  if type(hex) ~= "string" then return nil end
  local r, g, b = hex:match("#?(%x%x)(%x%x)(%x%x)")
  if not r or not g or not b then return nil end
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

local function blend_hex(fg_hex, bg_hex, alpha)
  local fr, fg, fb = hex_to_rgb(fg_hex)
  local br, bg_r, bb = hex_to_rgb(bg_hex)
  if not fr or not br then return fg_hex end
  local r = math.floor(fr * alpha + br * (1 - alpha) + 0.5)
  local g = math.floor(fg * alpha + bg_r * (1 - alpha) + 0.5)
  local b = math.floor(fb * alpha + bb * (1 - alpha) + 0.5)
  return string.format("#%02x%02x%02x", r, g, b)
end

local function is_legible_diff_green(hex)
  local r, g, b = hex_to_rgb(hex)
  if not r then return false end
  return g >= 120 and g > r and g > b and r <= 210 and b <= 210
end

local function is_legible_diff_red(hex)
  local r, g, b = hex_to_rgb(hex)
  if not r then return false end
  return r >= 140 and r > g and r > b and g <= 150 and b <= 150
end

function M.build(mode)
  local dark = mode ~= "light"
  local normal = read_hl("Normal")
  local visual = read_hl("Visual")
  local title = read_hl("Title")
  local keyword = read_hl("Keyword")
  local identifier = read_hl("Identifier")
  local comment = read_hl("Comment")
  local diff_add = read_hl("DiffAdd")
  local diff_delete = read_hl("DiffDelete")
  local diag_warn = read_hl("DiagnosticWarn")
  local diag_error = read_hl("DiagnosticError")
  local diag_info = read_hl("DiagnosticInfo")

  local raw_bg = first_hex(normal.bg)
  local bg_color
  if not raw_bg or raw_bg == "#000000" then
    bg_color = dark and "#1e1e2e" or "#eff1f5"
    local pmenu_bg = first_hl_bg({ "Pmenu", "NormalFloat" })
    if pmenu_bg and pmenu_bg ~= "#000000" then
      bg_color = pmenu_bg
    end
  else
    bg_color = raw_bg
  end

  local accent = first_hex(keyword.fg, title.fg, identifier.fg, diag_info and diag_info.fg)
    or (dark and "#89b4fa" or "#1e66f5")

  local border_color = first_hex(comment.fg)
    or first_hl_fg({ "NonText", "LineNr" })
    or (dark and "#6c7086" or "#9ca0b0")

  local add_fg = first_hl_fg({ "GitSignsAdd", "Added", "DiffAdded" })
    or first_hex(diff_add.fg)
  if not is_legible_diff_green(add_fg) then
    add_fg = dark and "#98c379" or "#22863a"
  end

  local del_fg = first_hl_fg({ "DiagnosticError", "ErrorMsg", "GitSignsDelete", "Removed", "DiffRemoved" })
    or first_hex(diag_error.fg)
    or first_hex(diff_delete.fg)
  if not is_legible_diff_red(del_fg) then
    del_fg = dark and "#e06c75" or "#cb2431"
  end

  local selection_bg = first_hex(visual.bg)
    or first_hl_bg({ "CursorLine", "DiffChange" })
    or (dark and "#313244" or "#ccd0da")

  local add_bg = first_hl_bg({ "DiffAdd", "GitSignsAddLn" })
    or blend_hex(add_fg, bg_color, dark and 0.12 or 0.10)
  local del_bg = first_hl_bg({ "DiffDelete", "GitSignsDeleteLn" })
    or blend_hex(del_fg, bg_color, dark and 0.12 or 0.10)
  local add_emph_bg = blend_hex(add_fg, bg_color, dark and 0.25 or 0.20)
  local del_emph_bg = blend_hex(del_fg, bg_color, dark and 0.25 or 0.20)

  return {
    fg = first_hex(normal.fg) or (dark and "#cdd6f4" or "#4c4f69"),
    bg = bg_color,
    border = border_color,
    accent = accent,
    selection = selection_bg,
    ok = add_fg,
    ok_bg = add_bg,
    ok_emph_bg = add_emph_bg,
    warn = first_hex(diag_warn.fg, title.fg) or (dark and "#f9e2af" or "#df8e1d"),
    error = del_fg,
    error_bg = del_bg,
    error_emph_bg = del_emph_bg,
  }
end

return M