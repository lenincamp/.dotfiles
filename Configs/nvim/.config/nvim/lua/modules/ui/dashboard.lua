local M = {}
local dashboard_ns = vim.api.nvim_create_namespace("pure_dashboard")

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

local MENU_ICON_BY_KEY = {
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

local function dashboard_menu_lines()
  local rows = {}
  local max_prefix = 0

  for _, btn in ipairs(M.buttons) do
    local icon = MENU_ICON_BY_KEY[btn.key] or "•"
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

local function dashboard_window_height()
  local ok_win, win = pcall(vim.api.nvim_get_current_win)
  if ok_win and win and vim.api.nvim_win_is_valid(win) then
    local ok_h, height = pcall(vim.api.nvim_win_get_height, win)
    if ok_h and type(height) == "number" and height > 0 then
      return height
    end
  end
  return vim.o.lines
end

local function dashboard_window_width()
  local ok_win, win = pcall(vim.api.nvim_get_current_win)
  if ok_win and win and vim.api.nvim_win_is_valid(win) then
    local ok_w, width = pcall(vim.api.nvim_win_get_width, win)
    if ok_w and type(width) == "number" and width > 0 then
      return width
    end
  end
  return vim.o.columns
end

local function dashboard_content_lines()
  local menu_lines = dashboard_menu_lines()
  local max_height = dashboard_window_height()
  local full_height = #M.header + 1 + #menu_lines

  local header = M.header
  if full_height > max_height then
    local header_room = math.max(0, max_height - #menu_lines - 1)
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

  for _, line in ipairs(menu_lines) do
    lines[#lines + 1] = line
  end

  return lines
end

local function dashboard_top_padding_lines(content_lines)
  return math.max(0, math.floor((dashboard_window_height() - #content_lines) / 2))
end

function M.centered_header_lines()
  local content_lines = dashboard_content_lines()
  local lines = {}
  local content_width = max_display_width(content_lines)
  local window_width = dashboard_window_width()
  local block_pad = math.max(0, math.floor((window_width - content_width) / 2))

  for _ = 1, dashboard_top_padding_lines(content_lines) do
    lines[#lines + 1] = ""
  end

  for _, line in ipairs(content_lines) do
    local inner_pad = math.max(0, math.floor((content_width - display_width(line)) / 2))
    lines[#lines + 1] = string.rep(" ", block_pad + inner_pad) .. line
  end

  return lines
end

function M.effective_width()
  local content_width = math.max(40, max_display_width(dashboard_content_lines()) + 4)
  local max_for_screen = math.max(40, vim.o.columns - 2)
  return math.min(content_width, max_for_screen)
end

local function set_dashboard_neon_hl()
  vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#39FFB6", bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardSpecial", { fg = "#19E3FF", bold = true })
  vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = "#9AFBFF", bold = true })
end

local function apply_dashboard_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, dashboard_ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for row, line in ipairs(lines) do
    local line_index = row - 1
    if line:find("%[.%]") then
      local key_start, key_end = line:find("%[.%]")
      local nonblank = line:find("%S") or 1
      if nonblank < key_start then
        vim.api.nvim_buf_add_highlight(bufnr, dashboard_ns, "SnacksDashboardSpecial", line_index, nonblank - 1, key_start - 1)
      end
      vim.api.nvim_buf_add_highlight(bufnr, dashboard_ns, "SnacksDashboardKey", line_index, key_start - 1, key_end)
      if key_end < #line then
        vim.api.nvim_buf_add_highlight(bufnr, dashboard_ns, "SnacksDashboardSpecial", line_index, key_end, -1)
      end
    elseif line:find("%S") then
      vim.api.nvim_buf_add_highlight(bufnr, dashboard_ns, "SnacksDashboardHeader", line_index, 0, -1)
    end
  end
end

local function cleanup_dashboard_shadow_buffers()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local bt = vim.bo[buf].buftype
      local modified = vim.bo[buf].modified
      if name == "" and bt == "" and not modified then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

local function project_roots()
  local roots = {}
  local seen = {}
  for _, path in ipairs(vim.v.oldfiles or {}) do
    local dir = vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(path, ":p")))
    local root = dir and vim.fs.root(dir, { ".git", "pom.xml", "package.json", "sfdx-project.json", "build.gradle", "build.gradle.kts" }) or nil
    root = root or dir
    if root and root ~= "" and not seen[root] and vim.fn.isdirectory(root) == 1 then
      seen[root] = true
      roots[#roots + 1] = { label = vim.fn.fnamemodify(root, ":~"), path = root }
    end
  end
  table.sort(roots, function(a, b) return a.label < b.label end)
  return roots
end

local function select_recent_project()
  local projects = project_roots()
  if #projects == 0 then
    vim.notify("No recent projects", vim.log.levels.INFO)
    return
  end
  require("modules.editor.picker").select_items(projects, {
    prompt = "Recent Projects",
    scope = "global",
    search_threshold = 0,
    format_item = function(item) return item.label end,
  }, function(item)
    if item then
      vim.cmd("cd " .. vim.fn.fnameescape(item.path))
      require("modules.editor.search").find_files({ cwd = item.path, title = "Find Files: " .. item.label })
    end
  end)
end

local function run_dashboard_action(action)
  local search = require("modules.editor.search")

  if action == "files" then
    search.find_files({ title = "Find File" })
  elseif action == "grep" then
    search.grep({ cwd = search.root(), regex = false, title = "Search in Files" })
  elseif action == "recent" then
    search.recent_files({ title = "Recent Files" })
  elseif action == "projects" then
    select_recent_project()
  elseif action == "config" then
    search.find_files({ cwd = vim.fn.stdpath("config"), title = "Config Files" })
  elseif action == "session" then
    local ok_s, sessions = pcall(require, "modules.editor.sessions")
    if ok_s then sessions.load_last() end
  elseif action == "new" then
    vim.cmd("enew")
    vim.cmd("startinsert")
  elseif action == "quit" then
    vim.cmd("qa")
  end
end

local function apply_dashboard_keymaps(bufnr)
  if vim.b[bufnr].pure_dashboard_keymaps_applied then
    return
  end

  for _, btn in ipairs(M.buttons) do
    vim.keymap.set("n", btn.key, function()
      run_dashboard_action(btn.action)
    end, {
      buffer = bufnr,
      silent = true,
      nowait = true,
      noremap = true,
      desc = "Dashboard: " .. btn.desc,
    })
  end

  vim.b[bufnr].pure_dashboard_keymaps_applied = true
end

local function setup_dashboard_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if vim.bo[bufnr].filetype ~= "snacks_dashboard" and vim.bo[bufnr].filetype ~= "pure_dashboard" then
    return
  end

  apply_dashboard_keymaps(bufnr)

  if not vim.b[bufnr].pure_dashboard_cleanup_done then
    vim.b[bufnr].pure_dashboard_cleanup_done = true
    vim.schedule(cleanup_dashboard_shadow_buffers)
  end
end

local function should_open()
  if vim.fn.argc() > 0 then return false end
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(bufnr) ~= "" then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end
  if vim.api.nvim_buf_line_count(bufnr) > 1 then return false end
  return vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == ""
end

local function restore_dashboard_number_options(window)
  window = window or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(window) then
    return
  end

  vim.wo[window].number = vim.o.number
  vim.wo[window].relativenumber = vim.o.relativenumber
  require("modules.ui.gutter").apply_window(window)
end

function M.open()
  set_dashboard_neon_hl()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "snacks_dashboard"
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, M.centered_header_lines())
  vim.bo[bufnr].modifiable = false
  apply_dashboard_highlights(bufnr)

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.list = false
  vim.wo.foldcolumn = "0"
  vim.wo.signcolumn = "no"
  vim.wo.winbar = ""

  setup_dashboard_buffer(bufnr)
end

function M.setup()
  if M._setup_done then return end
  M._setup_done = true

  set_dashboard_neon_hl()

  vim.api.nvim_create_user_command("Dashboard", M.open, { desc = "Open native dashboard" })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("PureDashboardNeon", { clear = true }),
    callback = set_dashboard_neon_hl,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("PureDashboardBufferCleanup", { clear = true }),
    pattern = { "snacks_dashboard", "pure_dashboard" },
    callback = function(args) setup_dashboard_buffer(args.buf) end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("PureDashboardBufEnter", { clear = true }),
    callback = function(args) setup_dashboard_buffer(args.buf) end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("PureDashboardBufLeave", { clear = true }),
    callback = function(args)
      if vim.bo[args.buf].filetype ~= "snacks_dashboard" and vim.bo[args.buf].filetype ~= "pure_dashboard" then
        return
      end

      vim.schedule(function()
        restore_dashboard_number_options(vim.api.nvim_get_current_win())
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("PureNativeDashboard", { clear = true }),
    callback = function()
      if should_open() then M.open() end
    end,
  })
end

return M
