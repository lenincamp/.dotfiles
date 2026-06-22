local M = {}

local session_dir = vim.fn.stdpath("data") .. "/sessions"
local index_file = session_dir .. "/index.json"
local last_file = session_dir .. "/.last"
local session_options = "blank,buffers,curdir,folds,help,tabpages,winsize,globals"

M._setup_done = false
M._recording_enabled = true

local function ensure_session_dir()
  vim.fn.mkdir(session_dir, "p")
end

local function read_file(path)
  if vim.fn.filereadable(path) == 0 then return nil end
  local lines = vim.fn.readfile(path)
  if not lines or #lines == 0 then return nil end
  return table.concat(lines, "\n")
end

local function write_file(path, content)
  vim.fn.writefile(vim.split(content, "\n", { plain = true }), path)
end

local function read_index()
  local raw = read_file(index_file)
  if not raw or raw == "" then return {} end

  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

local function write_index(index)
  local ok, encoded = pcall(vim.json.encode, index)
  if not ok then return end
  write_file(index_file, encoded)
end

local function current_cwd()
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
end

local function session_name(cwd)
  if type(vim.fn.sha256) == "function" then
    return vim.fn.sha256(cwd) .. ".vim"
  end
  local safe = cwd:gsub("[^%w%-_.]", "_")
  return safe .. ".vim"
end

local function session_path_for_cwd(cwd)
  return session_dir .. "/" .. session_name(cwd)
end

local function read_last_path()
  return read_file(last_file)
end

local function write_last_path(path)
  write_file(last_file, path)
end

local function update_index(path, cwd)
  local index = read_index()
  index[vim.fn.fnamemodify(path, ":t")] = cwd
  write_index(index)
end

function M.save(opts)
  opts = opts or {}

  if vim.opt.diff:get() then
    if not opts.silent then
      vim.notify("Session save skipped in diff mode", vim.log.levels.INFO)
    end
    return false
  end

  ensure_session_dir()

  local cwd = current_cwd()
  local path = session_path_for_cwd(cwd)
  local previous_opts = vim.o.sessionoptions

  local ok, err = pcall(function()
    vim.o.sessionoptions = session_options
    vim.cmd("silent! mksession! " .. vim.fn.fnameescape(path))
  end)

  vim.o.sessionoptions = previous_opts

  if not ok then
    if not opts.silent then
      vim.notify("Session save failed: " .. tostring(err), vim.log.levels.WARN)
    end
    return false
  end

  write_last_path(path)
  update_index(path, cwd)

  if not opts.silent then
    vim.notify("Session saved", vim.log.levels.INFO)
  end
  return true
end

function M.load(path, opts)
  opts = opts or {}

  ensure_session_dir()
  local target = path or session_path_for_cwd(current_cwd())

  if vim.fn.filereadable(target) == 0 then
    if not opts.silent then
      vim.notify("No session found", vim.log.levels.INFO)
    end
    return false
  end

  local ok, err = pcall(vim.cmd, "silent! source " .. vim.fn.fnameescape(target))
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
  local last_path = read_last_path()
  if last_path and last_path ~= "" and M.load(last_path, { silent = true }) then
    vim.notify("Session loaded (last)", vim.log.levels.INFO)
    return true
  end
  return M.load_cwd()
end

function M.select()
  ensure_session_dir()

  local files = vim.fn.globpath(session_dir, "*.vim", false, true)
  if #files == 0 then
    vim.notify("No sessions available", vim.log.levels.INFO)
    return
  end

  table.sort(files, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)

  local index = read_index()
  local items = {}

  for _, path in ipairs(files) do
    local name = vim.fn.fnamemodify(path, ":t")
    local label = index[name] or name
    table.insert(items, { path = path, label = label })
  end

  require("picker").select_items(items, {
    prompt = "Session: Select",
    scope = "project",
    search_threshold = 0,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then return end
    M.load(choice.path)
  end)
end

function M.stop()
  M._recording_enabled = false
  vim.notify("Session recording stopped", vim.log.levels.INFO)
end

function M.setup()
  if M._setup_done then return end
  M._setup_done = true

  local map = vim.keymap.set

  map("n", "<leader>ps", function()
    M.save()
  end, { desc = "Session: Save" })

  map("n", "<leader>pl", function()
    M.load_cwd()
  end, { desc = "Session: Load (cwd)" })

  map("n", "<leader>pL", function()
    M.load_last()
  end, { desc = "Session: Load (last)" })

  map("n", "<leader>pS", function()
    M.select()
  end, { desc = "Session: Select" })

  map("n", "<leader>pd", function()
    M.stop()
  end, { desc = "Session: Stop recording" })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("NativeSessionAutoSave", { clear = true }),
    callback = function()
      if not M._recording_enabled then return end
      M.save({ silent = true })
    end,
  })
end

return M
