local M = {}

local function lsp_clients_for(method)
  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    local ok, supported = pcall(function()
      return client:supports_method(method)
    end)
    if ok and supported then
      clients[#clients + 1] = client
    end
  end
  return clients
end

local function notify_will_rename(from, to)
  local changes = { files = { { oldUri = vim.uri_from_fname(from), newUri = vim.uri_from_fname(to) } } }

  for _, client in ipairs(lsp_clients_for("workspace/willRenameFiles")) do
    local response = client.request_sync("workspace/willRenameFiles", changes, 1000, 0)
    if response and response.result ~= nil then
      vim.lsp.util.apply_workspace_edit(response.result, client.offset_encoding)
    end
  end

  return changes
end

local function notify_did_rename(changes)
  for _, client in ipairs(lsp_clients_for("workspace/didRenameFiles")) do
    client.notify("workspace/didRenameFiles", changes)
  end
end

function M.copy_path()
  local paths = {
    ["Absolute path"] = "%:p",
    ["Relative path"] = "%:.",
    ["File name only"] = "%:t",
  }

  vim.ui.select(
    { "Absolute path", "Relative path", "File name only" },
    { prompt = "Copy to clipboard:" },
    function(choice)
      if choice then
        local path = vim.fn.expand(paths[choice])
        vim.fn.setreg("+", path)
        vim.notify("Copied: " .. path)
      end
    end
  )
end

function M.rename_file()
  local old_path = vim.fn.expand("%:p")
  if old_path == "" then
    vim.notify("Current buffer has no file name", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "New name: ", default = vim.fn.expand("%:t"), scope = "buffer" }, function(new_name)
    if not new_name or new_name == "" then
      return
    end

    local new_path = new_name:sub(1, 1) == "/" and new_name or (vim.fn.expand("%:p:h") .. "/" .. new_name)
    new_path = vim.fs.normalize(new_path)

    if new_path == old_path then
      return
    end

    if vim.fn.filereadable(new_path) == 1 then
      vim.notify("Target already exists: " .. new_path, vim.log.levels.WARN)
      return
    end

    local changes = notify_will_rename(old_path, new_path)
    local ok, error_message = vim.uv.fs_rename(old_path, new_path)
    if not ok then
      vim.notify("Rename failed: " .. tostring(error_message), vim.log.levels.ERROR)
      return
    end

    vim.cmd("file " .. vim.fn.fnameescape(new_path))
    notify_did_rename(changes)
    vim.notify("Renamed: " .. vim.fn.fnamemodify(new_path, ":~:."), vim.log.levels.INFO)
  end)
end

function M.format()
  require("modules.editor.format").format({ notify = true })
end

function M.open_quickfix_playbook()
  local path = vim.fn.stdpath("config") .. "/QUICKFIX_REFACTOR_PLAYBOOK.md"
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("Quickfix playbook not found: " .. path, vim.log.levels.WARN)
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))
end
function M.quickfix_oldfiles_cwd()
  local cwd = vim.fn.getcwd()
  local oldfiles = vim.v.oldfiles
  local items = {}

  for _, file in ipairs(oldfiles) do
    if file:find(cwd, 1, true) and vim.fn.filereadable(file) == 1 then
      table.insert(items, { filename = file, lnum=1, col=1, text="" })
    end
  end

  vim.fn.setqflist({}, "r", { title = "Recent Files (CWD)", items = items })
  vim.cmd("copen")
end

function M.find_oldfiles()
  local cwd = vim.fn.getcwd()

  local candidates = vim
    .iter(vim.v.oldfiles)
    :filter(function(file)
      return file:find(cwd, 1, true)
        and vim.uv.fs_stat(file)
    end)
    :totable()

  vim.ui.select(candidates, {
    prompt = "Oldfiles",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":~:.")
    end,
  }, function(choice)
    if choice then
      vim.cmd.edit(vim.fn.fnameescape(choice))
    end
  end)
end

return M
