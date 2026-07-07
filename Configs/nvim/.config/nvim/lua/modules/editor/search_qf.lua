local M = {}

--- Get git root (simple git rev-parse)
local function git_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] then
    return out[1]
  end
  return vim.fn.getcwd()
end

local fd = require("modules.editor.fd")

--- fd files → quickfix (with excludes)
local function fd_to_qf(args, title, opts)
  opts = opts or {}
  local cmd = { "fd", "--type", "f" }
  local excl = opts.ignored and fd.ignored() or fd.basic()
  vim.list_extend(cmd, excl)
  vim.list_extend(cmd, args)
  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 or #lines == 0 then
    vim.notify("No files found", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, f in ipairs(lines) do
    items[#items + 1] = { filename = f, lnum = 1, text = "" }
  end
  vim.fn.setqflist({}, "r", { title = title or "Files", items = items })
  vim.cmd.copen(10)
end

--- <leader>fF: find files root (fd → quickfix)
function M.find_files_root()
  local root = git_root()
  local old_cwd = vim.fn.getcwd()
  vim.fn.chdir(root)
  fd_to_qf({ "." }, "Find Files (root)")
  vim.fn.chdir(old_cwd)
end

--- <leader>fG: find git-ignored files → quickfix
function M.find_files_ignored()
  fd_to_qf({ "." }, "Ignored Files", { ignored = true })
end

--- <leader>fg: git tracked files → quickfix
function M.git_files()
  local lines = vim.fn.systemlist({ "git", "ls-files" })
  if vim.v.shell_error ~= 0 or #lines == 0 then
    vim.notify("No git files found", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, f in ipairs(lines) do
    items[#items + 1] = { filename = f, lnum = 1, text = "" }
  end
  vim.fn.setqflist({}, "r", { title = "Git Files", items = items })
  vim.cmd.copen(10)
end

--- Run rg with args → quickfix
local function rg_to_qf(args, title)
  local cmd = { "rg", "--vimgrep", "-F" }
  vim.list_extend(cmd, args)
  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 and #lines == 0 then
    vim.notify("No matches found", vim.log.levels.INFO)
    return
  end
  vim.fn.setqflist({}, "r", {
    title = title or "Search",
    lines = lines,
  })
  vim.cmd.copen(10)
end

--- <leader>sg: grep cwd (input)
function M.grep_cwd()
  vim.ui.input({ prompt = "Grep (cwd): " }, function(input)
    if not input or input == "" then
      return
    end
    rg_to_qf({ input }, "Grep (cwd): " .. input)
  end)
end

--- <leader>sG: grep root (input)
function M.grep_root()
  vim.ui.input({ prompt = "Grep (root): " }, function(input)
    if not input or input == "" then
      return
    end
    local root = git_root()
    vim.fn.chdir(root)
    rg_to_qf({ input }, "Grep (root): " .. input)
  end)
end

--- <leader>sw: grep word under cursor cwd
function M.grep_word_cwd()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  rg_to_qf({ word }, "Word (cwd): " .. word)
end

--- <leader>sW: grep word under cursor root
function M.grep_word_root()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  local root = git_root()
  local old_cwd = vim.fn.getcwd()
  vim.fn.chdir(root)
  rg_to_qf({ word }, "Word (root): " .. word)
  vim.fn.chdir(old_cwd)
end

--- <leader>si: grep ignored cwd (no-ignore)
function M.grep_ignored_cwd()
  vim.ui.input({ prompt = "Grep ignored (cwd): " }, function(input)
    if not input or input == "" then
      return
    end
    rg_to_qf({ "--no-ignore", input }, "Grep ignored (cwd): " .. input)
  end)
end

--- <leader>sI: grep ignored root
function M.grep_ignored_root()
  vim.ui.input({ prompt = "Grep ignored (root): " }, function(input)
    if not input or input == "" then
      return
    end
    local root = git_root()
    local old_cwd = vim.fn.getcwd()
    vim.fn.chdir(root)
    rg_to_qf({ "--no-ignore", input }, "Grep ignored (root): " .. input)
    vim.fn.chdir(old_cwd)
  end)
end

--- <leader>/: search in current buffer
function M.grep_buffer()
  vim.ui.input({ prompt = "Search buffer: " }, function(input)
    if not input or input == "" then
      return
    end
    local lines = vim.fn.getbufline("%", 1, "$")
    local matches = {}
    local pattern = vim.fn.escape(input, "\\")
    for i, line in ipairs(lines) do
      if line:find(pattern, 1, true) then
        matches[#matches + 1] = {
          filename = vim.fn.expand("%:p"),
          lnum = i,
          col = 1,
          text = line,
        }
      end
    end
    if #matches == 0 then
      vim.notify("No matches in buffer", vim.log.levels.INFO)
      return
    end
    vim.fn.setqflist({}, "r", {
      title = "Buffer search: " .. input,
      items = matches,
    })
    vim.cmd.copen(10)
  end)
end

--- <leader>s/: grep root literal
function M.grep_root_literal()
  vim.ui.input({ prompt = "Grep literal (root): " }, function(input)
    if not input or input == "" then
      return
    end
    local root = git_root()
    local old_cwd = vim.fn.getcwd()
    vim.fn.chdir(root)
    rg_to_qf({ input }, "Grep literal (root): " .. input)
    vim.fn.chdir(old_cwd)
  end)
end

--- <leader>sq: open quickfix list
function M.open_qflist()
  vim.cmd.copen(10)
end

--- <leader>sl: open location list
function M.open_loclist()
  vim.cmd.lopen(10)
end

--- <leader>sb: search buffers
function M.search_buffers()
  local bufs = vim.fn.getbufinfo({ buflisted = 1, nofile = 0 })
  if #bufs == 0 then
    vim.notify("No listed buffers", vim.log.levels.INFO)
    return
  end
  vim.ui.select(bufs, {
    prompt = "Buffers",
    format_item = function(item)
      return vim.fn.fnamemodify(item.name, ":~:.")
    end,
  }, function(choice)
    if choice then
      vim.cmd("buffer " .. choice.bufnr)
    end
  end)
end

--- <leader>sy: registers
function M.search_registers()
  local regs = {}
  for i = 34, 126 do
    local name = vim.fn.nr2char(i)
    local val = vim.fn.getreg(name, 1)
    if val ~= "" then
      regs[#regs + 1] = { name = name, value = val }
    end
  end
  if #regs == 0 then
    vim.notify("No registers with content", vim.log.levels.INFO)
    return
  end
  vim.ui.select(regs, {
    prompt = "Registers",
    format_item = function(item)
      return '"' .. item.name .. "  " .. item.value:sub(1, 80)
    end,
  }, function(choice)
    if choice then
      vim.fn.setreg(vim.v.register, choice.value)
      vim.notify("Copied register " .. choice.name, vim.log.levels.INFO)
    end
  end)
end

--- <leader>sc: command history
function M.command_history()
  local hist = {}
  for i = 1, vim.fn.histnr("cmd") do
    local cmd = vim.fn.histget("cmd", i)
    if cmd ~= "" then
      hist[#hist + 1] = cmd
    end
  end
  if #hist == 0 then
    vim.notify("No command history", vim.log.levels.INFO)
    return
  end
  vim.ui.select(hist, { prompt = "Command History" }, function(choice)
    if choice then
      vim.cmd(choice)
    end
  end)
end

--- <leader>sC: commands
function M.commands()
  local cmds = vim.api.nvim_get_commands({ builtin = true })
  local list = {}
  for _, cmd in pairs(cmds) do
    list[#list + 1] = { name = cmd.name, definition = cmd.definition or "" }
  end
  table.sort(list, function(a, b) return a.name < b.name end)
  vim.ui.select(list, {
    prompt = "Commands",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      vim.cmd(choice.name)
    end
  end)
end

--- <leader>sd: document diagnostics
function M.diagnostics_buf()
  local diags = vim.diagnostic.get(0)
  if #diags == 0 then
    vim.notify("No diagnostics in buffer", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, d in ipairs(diags) do
    items[#items + 1] = {
      filename = vim.fn.expand("%:p"),
      lnum = d.lnum + 1,
      col = d.col + 1,
      text = d.message,
      type = d.severity == vim.diagnostic.severity.ERROR and "E"
        or d.severity == vim.diagnostic.severity.WARN and "W"
        or "I",
    }
  end
  vim.fn.setqflist({}, "r", { title = "Buffer Diagnostics", items = items })
  vim.cmd.copen(10)
end

--- <leader>sD: workspace diagnostics
function M.diagnostics_all()
  local diags = vim.diagnostic.get()
  if #diags == 0 then
    vim.notify("No workspace diagnostics", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, d in ipairs(diags) do
    items[#items + 1] = {
      filename = vim.api.nvim_buf_get_name(d.bufnr),
      lnum = d.lnum + 1,
      col = d.col + 1,
      text = d.message,
      type = d.severity == vim.diagnostic.severity.ERROR and "E"
        or d.severity == vim.diagnostic.severity.WARN and "W"
        or "I",
    }
  end
  vim.fn.setqflist({}, "r", { title = "Workspace Diagnostics", items = items })
  vim.cmd.copen(10)
end

--- <leader>sh: help
function M.help()
  vim.ui.input({ prompt = "Help: " }, function(input)
    if input and input ~= "" then
      vim.cmd("help " .. input)
    end
  end)
end

--- <leader>sk: keymaps
function M.keymaps()
  local maps = vim.api.nvim_get_keymap("n")
  local items = {}
  for _, m in ipairs(maps) do
    if m.lhs then
      items[#items + 1] = {
        lhs = m.lhs:gsub("\xff", ""),
        desc = m.desc or "",
        rhs = type(m.rhs) == "string" and m.rhs or "",
      }
    end
  end
  vim.ui.select(items, {
    prompt = "Keymaps",
    format_item = function(item)
      return item.lhs .. "  " .. (item.desc or item.rhs)
    end,
  }, function(choice)
    if choice then
      local keys = vim.api.nvim_replace_termcodes(choice.lhs, true, false, true)
      vim.api.nvim_feedkeys(keys, "m", false)
    end
  end)
end

--- <leader>sm: marks
function M.marks()
  local raw = vim.fn.execute("marks")
  local marks = {}
  for line in raw:gmatch("[^\r\n]+") do
    local name, file, lnum = line:match("^%s*(%S)%s+(%S+)%s+(%d+)")
    if name and file and name ~= "mark" then
      marks[#marks + 1] = { name = name, file = file, lnum = tonumber(lnum) }
    end
  end
  if #marks == 0 then
    vim.notify("No marks set", vim.log.levels.INFO)
    return
  end
  vim.ui.select(marks, {
    prompt = "Marks",
    format_item = function(item)
      return item.name .. "  " .. item.file .. ":" .. item.lnum
    end,
  }, function(choice)
    if choice then
      vim.cmd("'" .. choice.name)
    end
  end)
end

--- <leader>sn: notifications (stub)
function M.notifications()
  vim.notify("No notifications to show", vim.log.levels.INFO)
end

--- <leader>sq: quickfix list as picker
function M.qflist()
  local qf = vim.fn.getqflist()
  if #qf == 0 then
    vim.notify("Quickfix list empty", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, entry in ipairs(qf) do
    items[#items + 1] = {
      filename = vim.api.nvim_buf_get_name(entry.bufnr),
      lnum = entry.lnum,
      col = entry.col,
      text = entry.text,
    }
  end
  vim.ui.select(items, {
    prompt = "Quickfix",
    format_item = function(item)
      return vim.fn.fnamemodify(item.filename, ":~:.") .. ":" .. item.lnum .. "  " .. item.text
    end,
  }, function(choice)
    if choice then
      vim.cmd("edit " .. vim.fn.fnameescape(choice.filename))
      vim.api.nvim_win_set_cursor(0, { choice.lnum, math.max(0, choice.col - 1) })
    end
  end)
end

--- <leader>su: undo history
function M.undo_history()
  local undolist = vim.fn.undofile(vim.fn.expand("%"))
  if not undolist or undolist == "" then
    vim.notify("No undo history", vim.log.levels.INFO)
    return
  end
  vim.cmd("undolist")
end

return M
