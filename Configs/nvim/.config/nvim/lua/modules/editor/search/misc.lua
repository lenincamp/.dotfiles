local M = {}

local core = require("modules.editor.search.core")
local picker = require("modules.editor.picker")

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
      core.notify("Loaded register " .. item.name)
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

return M
