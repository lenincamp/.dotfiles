local M = {}

local function qf_items()
  return vim.fn.getqflist({ items = 1 }).items or {}
end

local function set_items(items, title)
  vim.fn.setqflist({}, " ", { title = title, items = items })
  if #items > 0 then vim.cmd("copen") end
end

local function current_file_only()
  local current = vim.fs.normalize(vim.fn.expand("%:p"))
  local filtered = {}
  for _, item in ipairs(qf_items()) do
    local name = item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr)) or ""
    if vim.fs.normalize(name) == current then filtered[#filtered + 1] = item end
  end
  set_items(filtered, "Quickfix current file")
end

local function copy_entries()
  local lines = {}
  for _, item in ipairs(qf_items()) do
    local name = item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr)) or ""
    lines[#lines + 1] = string.format("%s:%s:%s:%s", name, item.lnum or 0, item.col or 0, item.text or "")
  end
  vim.fn.setreg("+", table.concat(lines, "\n"))
  vim.notify("Copied " .. #lines .. " quickfix entries", vim.log.levels.INFO)
end

local function preview_items()
  local items = {}
  for index, item in ipairs(qf_items()) do
    local name = item.filename or (item.bufnr and vim.api.nvim_buf_get_name(item.bufnr)) or ""
    items[#items + 1] = { index = index, label = string.format("%s:%s  %s", vim.fn.fnamemodify(name, ":~:."), item.lnum or 0, item.text or "") }
  end
  require("modules.editor.picker").select_items(items, {
    prompt = "Quickfix Items",
    scope = "session",
    search_threshold = 0,
    format_item = function(entry) return entry.label end,
  }, function(entry)
    if entry then vim.cmd("cc " .. entry.index) end
  end)
end

local actions = {
  { label = "Open quickfix", run = function() vim.cmd("copen") end },
  { label = "Close quickfix", run = function() vim.cmd("cclose") end },
  { label = "Preview/select item", run = preview_items },
  { label = "Keep current file only", run = current_file_only },
  { label = "Copy entries", run = copy_entries },
  { label = "Older list", run = function() pcall(vim.cmd, "colder") end },
  { label = "Newer list", run = function() pcall(vim.cmd, "cnewer") end },
}

function M.select()
  require("modules.editor.picker").select_items(actions, {
    prompt = "Quickfix Cockpit",
    scope = "session",
    search_threshold = 0,
    format_item = function(item) return item.label end,
  }, function(item)
    if item then item.run() end
  end)
end

return M
