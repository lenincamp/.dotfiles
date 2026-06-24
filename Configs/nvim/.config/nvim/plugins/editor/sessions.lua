-- sessions.lua – powered by tpope/vim-obsession.
-- obsession auto-saves to Session.vim in the project cwd on every relevant event.

local M = {}

local data_dir  = vim.fn.stdpath("data") .. "/sessions"
local last_file = data_dir .. "/.last"
M._setup_done = false

local function read_last_path()
  if vim.fn.filereadable(last_file) == 0 then return nil end
  local lines = vim.fn.readfile(last_file)
  return lines and lines[1] and lines[1] ~= "" and lines[1] or nil
end

local function write_last_path(path)
  vim.fn.mkdir(data_dir, "p")
  vim.fn.writefile({ path }, last_file)
end

local function cwd_session_path()
  return vim.fn.getcwd() .. "/Session.vim"
end

local function obsession(suffix)
  local ok, err = pcall(vim.cmd, "Obsession" .. (suffix or ""))
  if not ok then
    vim.notify("Session recording failed: " .. tostring(err), vim.log.levels.WARN)
  end
  return ok
end

-- Start obsession tracking for the cwd Session.vim (idempotent if already tracking).
function M.save()
  local path = cwd_session_path()
  if vim.v.this_session ~= path then
    if not obsession(" " .. vim.fn.fnameescape(path)) then
      return false
    end
  end
  write_last_path(path)
  vim.notify("Session recording: " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO)
  return true
end

function M.load(path, opts)
  opts = opts or {}
  local target = path or cwd_session_path()
  if vim.fn.filereadable(target) == 0 then
    if not opts.silent then
      vim.notify("No session found", vim.log.levels.INFO)
    end
    return false
  end
  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(target))
  if not ok then
    if not opts.silent then
      vim.notify("Session load failed: " .. tostring(err), vim.log.levels.WARN)
    end
    return false
  end
  write_last_path(target)
  if not opts.silent then
    vim.notify("Session loaded", vim.log.levels.INFO)
  end
  return true
end

function M.load_cwd()
  return M.load(nil)
end

function M.load_last()
  local last = read_last_path()
  if last and last ~= "" and M.load(last, { silent = true }) then
    vim.notify("Session loaded (last)", vim.log.levels.INFO)
    return true
  end
  return M.load_cwd()
end

function M.select()
  local seen  = {}
  local items = {}

  for _, path in ipairs(vim.v.oldfiles or {}) do
    local dir     = vim.fn.fnamemodify(path, ":h")
    local session = dir .. "/Session.vim"
    if not seen[session] and vim.fn.filereadable(session) == 1 then
      seen[session] = true
      items[#items + 1] = { path = session, label = vim.fn.fnamemodify(dir, ":~") }
    end
  end

  local cwd_session = cwd_session_path()
  if not seen[cwd_session] and vim.fn.filereadable(cwd_session) == 1 then
    seen[cwd_session] = true
    items[#items + 1] = { path = cwd_session, label = vim.fn.fnamemodify(vim.fn.getcwd(), ":~") }
  end

  table.sort(items, function(a, b)
    return vim.fn.getftime(a.path) > vim.fn.getftime(b.path)
  end)

  if #items == 0 then
    vim.notify("No sessions available", vim.log.levels.INFO)
    return
  end

  require("picker").select_items(items, {
    prompt           = "Session: Select",
    scope            = "project",
    search_threshold = 0,
    format_item      = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    M.load(choice.path)
  end)
end

function M.stop()
  if not obsession("!") then return false end
  vim.notify("Session recording stopped", vim.log.levels.INFO)
  return true
end

function M.setup()
  if M._setup_done then return end
  M._setup_done = true

  local map = vim.keymap.set
  map("n", "<leader>ps", function() M.save() end,      { desc = "Session: Save" })
  map("n", "<leader>pl", function() M.load_cwd() end,  { desc = "Session: Load (cwd)" })
  map("n", "<leader>pL", function() M.load_last() end, { desc = "Session: Load (last)" })
  map("n", "<leader>pS", function() M.select() end,    { desc = "Session: Select" })
  map("n", "<leader>pd", function() M.stop() end,      { desc = "Session: Stop recording" })
end

return M
