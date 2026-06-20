local M = {}

local core = require("modules.editor.search.core")

function M.lazygit(cwd)
  if vim.fn.executable("lazygit") ~= 1 then
    core.notify("lazygit is not available", vim.log.levels.WARN)
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].native_lazygit then
      if core.focus_buffer_window(buf) then
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
  require("modules.editor.git_picker").git_log(cwd or core.root())
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
