local M = {}
local core = require("modules.integrations.avante.core")

local function avante_sidebar()
  local avante = core.get()
  if not avante then
    return nil
  end

  local sidebar = avante.get()
  if sidebar:is_open() then
    return sidebar
  end

  require("avante.api").ask()
  return avante.get()
end

function M.add_file(filepath)
  if not filepath or filepath == "" then
    return
  end

  local ok_utils, utils = pcall(require, "avante.utils")
  if not ok_utils then
    return
  end

  local sidebar = avante_sidebar()
  if not sidebar then
    return
  end

  sidebar.file_selector:add_selected_file(utils.relative_path(filepath))
end

function M.add_files(filepaths)
  local count = 0
  for _, filepath in ipairs(filepaths or {}) do
    if filepath and filepath ~= "" then
      M.add_file(filepath)
      count = count + 1
    end
  end
  if count > 0 then
    vim.notify("Avante context: added " .. count .. " file" .. (count == 1 and "" or "s"), vim.log.levels.INFO)
  end
end

function M.add_current_buffer()
  M.add_file(vim.api.nvim_buf_get_name(0))
end

function M.add_open_buffers()
  local filepaths = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted then
      filepaths[#filepaths + 1] = vim.api.nvim_buf_get_name(bufnr)
    end
  end
  M.add_files(filepaths)
end

return M
