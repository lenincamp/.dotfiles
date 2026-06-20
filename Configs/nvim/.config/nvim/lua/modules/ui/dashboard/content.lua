local M = {}

M.header = {
  [[                        .,,cc,,,.]],
  [[                   ,c$$$$$$$$$$$$cc,]],
  [[                ,c$$$$$$$$$$??""??$?? ..]],
  [[             ,z$$$$$$$$$$$P xdMMbx  nMMMMMb]],
  [[            r")$$$$??$$$$" dMMMMMMb "MMMMMMb]],
  [[          r",d$$$$$>;$$$$ dMMMMMMMMb MMMMMMM.]],
  [[         d'z$$$$$$$>'"""" 4MMMMMMMMM MMMMMMM>]],
  [[        d'z$$$$$$$$h $$$$r`MMMMMMMMM "MMMMMM]],
  [[        P $$$$$$$$$$.`$$$$.'"MMMMMP',c,"""'..]],
  [[       d',$$$$$$$$$$$.`$$$$$c,`""_,c$$$$$$$$h]],
  [[       $ $$$$$$$$$$$$$.`$$$$$$$$$$$"     "$$$h]],
  [[      ,$ $$$$$$$$$$$$$$ $$$$$$$$$$%       `$$$L]],
  [[      d$c`?$$$$$$$$$$P'z$$$$$$$$$$c       ,$$$$.]],
  [[      $$$cc,"""""""".zd$$$$$$$$$$$$c,  .,c$$$$$F]],
  [[     ,$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$]],
  [[     d$$$$$$$$$$$$$$$$c`?$$$$$$$$$$$$$$$$$$$$$$$]],
  [[     ?$$$$$$$$$."$$$$$$c,`..`?$$$$$$$$$$$$$$$$$$.]],
  [[     <$$$$$$$$$$. ?$$$$$$$$$h $$$$$$$$$$$$$$$$$$>]],
  [[      $$$$$$$$$$$h."$$$$$$$$P $$$$$$$$$$$$$$$$$$>]],
  [[      `$$$$$$$$$$$$ $$$$$$$",d$$$$$$$$$$$$$$$$$$>]],
  [[       $$$$$$$$$$$$c`""""',c$$$$$$$$$$$$$$$$$$$$']],
  [[       "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$F]],
  [[        "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$']],
  [[        ."?$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$P'  FOR FUCK'S SAKE!]],
  [[     ,c$$c,`?$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"  THE TIME HE WASTES]],
  [[   z$$$$$P"   ""??$$$$$$$$$$$$$$$$$$$$$$$"  IN RICING NVIM IS]],
  [[,c$$$$$P"          .`""????????$$$$$$$$$$c  DRIVING ME CRAZY.]],
  [[`"""              ,$$$L.        "?$$$$$$$$$.   WHAT'S THE MATTER]],
  [[               ,cd$$$$$$$$$hc,    ?$$$$$$$$$c    WITH HIM ??????]],
  [[              `$$$$$$$$$$$$$$$.    ?$$$$$$$$$h]],
  [[               `?$$$$$$$$$$$$P      ?$$$$$$$$$]],
  [[                 `?$$$$$$$$$P        ?$$$$$$$$$$$$hc]],
  [[                   "?$$$$$$"         <$$$$$$$$$$$$$$r   FUCKING]],
  [[                     `""""           <$$$$$$$$$$$$$$F   KILL IT]],
  [[                                      $$$$$$$$$$$$$F]],
  [[                                      `?$$$$$$$$P"]],
  [[                                        "????"]],
}

M.buttons = {
  { key = "f", desc = "Find File", action = "files" },
  { key = "g", desc = "Search in Files", action = "grep" },
  { key = "r", desc = "Recent Files", action = "recent" },
  { key = "p", desc = "Recent Projects", action = "projects" },
  { key = "c", desc = "Config Files", action = "config" },
  { key = "s", desc = "Restore Last Session", action = "session" },
  { key = "n", desc = "New File", action = "new" },
  { key = "q", desc = "Quit", action = "quit" },
}

local menu_icon_by_key = {
  f = "",
  g = "󱎸",
  r = "󰄉",
  p = "󰉋",
  c = "",
  s = "",
  n = "󰝒",
  q = "󰈆",
}

local function display_width(text)
  return vim.fn.strdisplaywidth(text)
end

local function max_display_width(lines)
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, display_width(line))
  end
  return max_width
end

local function menu_lines()
  local rows = {}
  local max_prefix = 0

  for _, btn in ipairs(M.buttons) do
    local icon = menu_icon_by_key[btn.key] or "•"
    local prefix = string.format("%s  [%s]", icon, btn.key)
    max_prefix = math.max(max_prefix, display_width(prefix))
    rows[#rows + 1] = { prefix = prefix, desc = btn.desc }
  end

  local lines = {}
  local max_width = 0
  for _, row in ipairs(rows) do
    local pad = math.max(1, max_prefix - display_width(row.prefix) + 2)
    local line = row.prefix .. string.rep(" ", pad) .. row.desc
    lines[#lines + 1] = line
    max_width = math.max(max_width, display_width(line))
  end

  for i, line in ipairs(lines) do
    local trailing = max_width - display_width(line)
    if trailing > 0 then
      lines[i] = line .. string.rep(" ", trailing)
    end
  end

  return lines
end

local function window_height()
  local ok_win, win = pcall(vim.api.nvim_get_current_win)
  if ok_win and win and vim.api.nvim_win_is_valid(win) then
    local ok_h, height = pcall(vim.api.nvim_win_get_height, win)
    if ok_h and type(height) == "number" and height > 0 then
      return height
    end
  end
  return vim.o.lines
end

local function window_width()
  local ok_win, win = pcall(vim.api.nvim_get_current_win)
  if ok_win and win and vim.api.nvim_win_is_valid(win) then
    local ok_w, width = pcall(vim.api.nvim_win_get_width, win)
    if ok_w and type(width) == "number" and width > 0 then
      return width
    end
  end
  return vim.o.columns
end

local function content_lines()
  local menu = menu_lines()
  local max_height = window_height()
  local full_height = #M.header + 1 + #menu

  local header = M.header
  if full_height > max_height then
    local header_room = math.max(0, max_height - #menu - 1)
    local start = math.max(1, #M.header - header_room + 1)
    header = {}
    for i = start, #M.header do
      header[#header + 1] = M.header[i]
    end
  end

  local lines = vim.deepcopy(header)
  if #lines > 0 then
    lines[#lines + 1] = ""
  end

  for _, line in ipairs(menu) do
    lines[#lines + 1] = line
  end

  return lines
end

local function top_padding_lines(lines)
  return math.max(0, math.floor((window_height() - #lines) / 2))
end

function M.centered_lines()
  local lines = content_lines()
  local centered = {}
  local content_width = max_display_width(lines)
  local block_pad = math.max(0, math.floor((window_width() - content_width) / 2))

  for _ = 1, top_padding_lines(lines) do
    centered[#centered + 1] = ""
  end

  for _, line in ipairs(lines) do
    local inner_pad = math.max(0, math.floor((content_width - display_width(line)) / 2))
    centered[#centered + 1] = string.rep(" ", block_pad + inner_pad) .. line
  end

  return centered
end

function M.effective_width()
  local content_width = math.max(40, max_display_width(content_lines()) + 4)
  local max_for_screen = math.max(40, vim.o.columns - 2)
  return math.min(content_width, max_for_screen)
end

return M
