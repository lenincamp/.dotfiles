local M = {}
local picker = require("modules.editor.picker")
local root_cache = {}
local root_markers = { ".git", "pom.xml", "package.json", "build.gradle" }
local root_cache_group_initialized = false

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

local function ensure_root_cache_autocmd()
  if root_cache_group_initialized then
    return
  end
  root_cache_group_initialized = true

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("root_cache", { clear = true }),
    callback = function(args)
      root_cache[args.buf] = nil
    end,
  })
end

local function run(command, opts)
  opts = opts or {}
  local result = vim.system(command, { cwd = opts.cwd, text = true }):wait()
  local stdout = result and result.stdout or ""
  local stderr = result and result.stderr or ""
  local lines = vim.split(stdout, "\n", { plain = true, trimempty = true })
  return lines, result and result.code or 1, stderr
end

local function focus_buffer_window(bufnr)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
        vim.api.nvim_set_current_tabpage(tab)
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end
  return false
end

local function make_file_item(cwd, path)
  return {
    label = path,
    path = vim.fs.normalize(cwd .. "/" .. path),
  }
end

local function item_path(item)
  return type(item) == "table" and (item.path or item.filename or item.label or "") or tostring(item or "")
end

local function path_has_extension(path, extensions)
  path = path:lower()
  for _, extension in ipairs(extensions) do
    if path:sub(-#extension) == extension then
      return true
    end
  end
  return false
end

local function picker_file_filters()
  return {
    { key = "J", label = "Java", predicate = function(item) return path_has_extension(item_path(item), { ".java" }) end },
    { key = "j", label = "JS/TS", predicate = function(item) return path_has_extension(item_path(item), { ".js", ".ts" }) end },
    { key = "x", label = "JSX/TSX", predicate = function(item) return path_has_extension(item_path(item), { ".jsx", ".tsx" }) end },
    {
      key = "S",
      label = "Salesforce",
      predicate = function(item)
        local path = item_path(item):lower()
        return path:find("force%-app/", 1, false) ~= nil
            or path_has_extension(path, { ".cls", ".trigger", ".page", ".component", ".cmp", ".app", ".design", ".object", ".field-meta.xml", ".js-meta.xml" })
      end,
    },
    { key = "X", label = "XML", predicate = function(item) return path_has_extension(item_path(item), { ".xml" }) end },
    { key = "n", label = "JSON", predicate = function(item) return path_has_extension(item_path(item), { ".json", ".jsonc" }) end },
    { key = "y", label = "YAML/TOML/properties", predicate = function(item) return path_has_extension(item_path(item), { ".yml", ".yaml", ".toml", ".properties" }) end },
  }
end

local function file_glob_args(globs)
  local args = {}
  for _, glob in ipairs(globs or {}) do
    args[#args + 1] = "--glob"
    args[#args + 1] = glob
  end
  return args
end

local function regex_escape(text)
  return (text:gsub("([\\%^%$%(%)%%%.%[%]%*%+%-%?%|{}])", "\\%1"))
end

local function selected_text_or_word()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local saved = vim.fn.getreg("z")
    local saved_type = vim.fn.getregtype("z")
    vim.cmd([[silent normal! "zy]])
    local text = vim.fn.getreg("z")
    vim.fn.setreg("z", saved, saved_type)
    return vim.trim(text)
  end
  return vim.fn.expand("<cword>")
end

function M.root()
  ensure_root_cache_autocmd()

  local buf = vim.api.nvim_get_current_buf()
  if not root_cache[buf] then
    root_cache[buf] = vim.fs.root(buf, root_markers) or vim.fn.getcwd()
  end
  return root_cache[buf]
end

function M.open_explorer(cwd, reveal_path)
  require("modules.editor.explorer").open(cwd, reveal_path)
end

function M.find_files(opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local command = { "rg", "--files", "--hidden", "--glob", "!.git" }
  vim.list_extend(command, file_glob_args(opts.glob))

  local lines, code, stderr = run(command, { cwd = cwd })
  if code ~= 0 and #lines == 0 then
    notify(vim.trim(stderr) ~= "" and vim.trim(stderr) or "No files found", vim.log.levels.WARN)
    return
  end

  local items = vim.tbl_map(function(path)
    return make_file_item(cwd, path)
  end, lines)

  picker.select_items(items, {
    prompt = opts.title or "Find files",
    scope = "project",
    search_threshold = 0,
    query = opts.query,
    filters = picker_file_filters(),
    preview = function(item) return item.path end,
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    end
  end)
end

function M.git_files(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or M.root()
  require("modules.editor.git_picker").git_files(opts)
end

function M.recent_files(opts)
  opts = opts or {}
  local cwd = not opts.global and vim.fs.normalize(opts.cwd or vim.fn.getcwd()) or nil
  local items = {}
  for _, path in ipairs(vim.v.oldfiles or {}) do
    local normalized = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    local in_cwd = not cwd or normalized == cwd or normalized:sub(1, #cwd + 1) == (cwd .. "/")
    if vim.fn.filereadable(normalized) == 1 and in_cwd then
      items[#items + 1] = {
        label = cwd and vim.fn.fnamemodify(normalized, ":.") or vim.fn.fnamemodify(normalized, ":~:."),
        path = normalized,
      }
    end
  end

  picker.select_items(items, {
    prompt = opts.title or "Recent files",
    scope = cwd and "project" or "global",
    search_threshold = 0,
    query = opts.query,
    filters = picker_file_filters(),
    preview = function(item) return item.path end,
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    end
  end)
end

function M.open_terminal(cwd)
  vim.cmd("botright 15split")
  local buffer = vim.api.nvim_get_current_buf()
  vim.fn.termopen(vim.o.shell, { cwd = cwd or vim.fn.getcwd() })
  vim.bo[buffer].buflisted = false
  vim.cmd("startinsert")
end

function M.grep(opts)
  opts = opts or {}
  local cwd = opts.cwd or M.root()
  local query = opts.query
  if not query or query == "" then
    vim.ui.input({ prompt = opts.regex and "Grep regex: " or "Grep literal: ", scope = "project" }, function(input)
      if input and input ~= "" then
        opts.query = input
        M.grep(opts)
      end
    end)
    return
  end

  local dirs = opts.dirs or { cwd }
  local items = {}
  local pattern = opts.word and ("\\b" .. regex_escape(query) .. "\\b") or query

  for _, dir in ipairs(dirs) do
    local command = { "rg", "--vimgrep", "--smart-case", "--hidden", "--glob", "!.git" }
    if not opts.regex and not opts.word then
      command[#command + 1] = "-F"
    end
    vim.list_extend(command, file_glob_args(opts.glob))
    command[#command + 1] = pattern

    local lines = run(command, { cwd = dir })
    for _, line in ipairs(lines) do
      local file, lnum, col, text = line:match("^([^:]+):(%d+):(%d+):(.*)$")
      if file then
        items[#items + 1] = {
          filename = vim.fs.normalize(dir .. "/" .. file),
          lnum = tonumber(lnum),
          col = tonumber(col),
          text = text,
        }
      end
    end
  end

  local title = opts.title or "Grep: " .. query
  vim.fn.setqflist({}, " ", { title = title, items = items })

  picker.select_items(items, {
    prompt = title,
    scope = opts.scope or "project",
    filters = picker_file_filters(),
    search_threshold = 0,
    preview = function(item) return item.filename end,
    preview_lnum = function(item) return item.lnum end,
    preview_match = function(item)
      return {
        lnum = item.lnum,
        col = item.col,
        length = (opts.regex and not opts.word) and nil or #query,
      }
    end,
    format_item = function(item)
      return string.format("%s:%d:%d  %s", vim.fn.fnamemodify(item.filename, ":~:."), item.lnum or 0, item.col or 0, item.text or "")
    end,
  }, function(item)
    if item then
      vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
      vim.api.nvim_win_set_cursor(0, { item.lnum or 1, math.max((item.col or 1) - 1, 0) })
    end
  end)
end

function M.grep_word(opts)
  opts = opts or {}
  opts.query = selected_text_or_word()
  opts.regex = true
  opts.word = true
  M.grep(opts)
end

function M.buffers()
  local infos = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(infos, function(a, b)
    return a.bufnr < b.bufnr
  end)

  picker.select_items(infos, {
    prompt = "Buffers",
    scope = "session",
    format_item = function(info)
      local name = info.name ~= "" and vim.fn.fnamemodify(info.name, ":~:.") or "[No Name]"
      return string.format("%d %s%s", info.bufnr, name, info.changed == 1 and " [+]" or "")
    end,
  }, function(info)
    if info then
      vim.cmd("buffer " .. info.bufnr)
    end
  end)
end

function M.delete_buffer()
  vim.cmd("bdelete")
end

function M.delete_other_buffers()
  local current = vim.api.nvim_get_current_buf()
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if info.bufnr ~= current then
      pcall(vim.cmd, "bdelete " .. info.bufnr)
    end
  end
end

function M.registers()
  local names = vim.split('"0123456789abcdefghijklmnopqrstuvwxyz/-:.%#=*+', "", { plain = true, trimempty = true })
  local items = {}
  for _, name in ipairs(names) do
    local value = vim.fn.getreg(name)
    if value ~= "" then
      items[#items + 1] = { name = name, value = value:gsub("\n", "\\n") }
    end
  end

  picker.select_items(items, {
    prompt = "Registers",
    scope = "session",
    format_item = function(item)
      return string.format('"%s  %s', item.name, item.value)
    end,
  }, function(item)
    if item then
      vim.fn.setreg('"', vim.fn.getreg(item.name), vim.fn.getregtype(item.name))
      notify("Loaded register " .. item.name)
    end
  end)
end

function M.command_history()
  local items = {}
  local last = vim.fn.histnr(":")
  for index = last, math.max(1, last - 80), -1 do
    local command = vim.fn.histget(":", index)
    if command ~= "" then
      items[#items + 1] = command
    end
  end
  picker.select_items(items, { prompt = "Command history", scope = "session" }, function(command)
    if command then
      vim.fn.feedkeys(":" .. command, "n")
    end
  end)
end

function M.commands()
  local commands = vim.fn.getcompletion("", "command")
  picker.select_items(commands, { prompt = "Commands", scope = "global" }, function(command)
    if command then
      vim.cmd(command)
    end
  end)
end

function M.diagnostics(opts)
  opts = opts or {}
  if opts.buffer then
    vim.diagnostic.setqflist({ bufnr = 0, title = "Document Diagnostics", open = true })
  else
    vim.diagnostic.setqflist({ title = "Workspace Diagnostics", open = true })
  end
end

function M.help()
  picker.select_items(vim.fn.getcompletion("", "help"), { prompt = "Help", scope = "global" }, function(topic)
    if topic then
      vim.cmd("help " .. vim.fn.fnameescape(topic))
    end
  end)
end

function M.keymaps()
  require("modules.editor.keymap_docs").select()
end

function M.loclist()
  vim.cmd("lopen")
end

function M.qflist()
  vim.cmd("copen")
end

function M.marks()
  local items = {}
  for _, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark and mark.pos and mark.pos[2] > 0 then
      items[#items + 1] = mark
    end
  end
  picker.select_items(items, {
    prompt = "Marks",
    scope = "session",
    format_item = function(mark)
      return string.format("%s %s:%d", mark.mark, vim.fn.fnamemodify(mark.file or "", ":~:."), mark.pos[2])
    end,
  }, function(mark)
    if mark then
      vim.cmd("edit " .. vim.fn.fnameescape(mark.file))
      vim.api.nvim_win_set_cursor(0, { mark.pos[2], math.max(mark.pos[3] - 1, 0) })
    end
  end)
end

function M.notifications()
  vim.cmd("messages")
end

function M.undo_history()
  vim.cmd("undolist")
end

function M.lazygit(cwd)
  if vim.fn.executable("lazygit") ~= 1 then
    notify("lazygit is not available", vim.log.levels.WARN)
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].native_lazygit then
      if focus_buffer_window(buf) then
        vim.cmd("startinsert")
        return
      end
    end
  end

  vim.cmd("tabnew")
  local buffer = vim.api.nvim_get_current_buf()
  vim.bo[buffer].buflisted = false
  vim.bo[buffer].bufhidden = "wipe"
  vim.b[buffer].native_lazygit = true
  vim.fn.termopen({ "lazygit" }, {
    cwd = cwd or vim.fn.getcwd(),
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buffer) then
          pcall(vim.api.nvim_buf_delete, buffer, { force = true })
        end
        if vim.fn.tabpagenr("$") > 1 then
          pcall(vim.cmd, "tabclose")
        end
      end)
    end,
  })
  vim.cmd("startinsert")
end

function M.git_log(cwd)
  require("modules.editor.git_picker").git_log(cwd or M.root())
end

function M.git_blame_line()
  require("modules.editor.git_picker").git_blame_line()
end

function M.git_file_history()
  require("modules.editor.git_picker").git_file_history()
end

function M.git_browse(copy_only)
  require("modules.editor.git_picker").git_browse(copy_only)
end

return M
