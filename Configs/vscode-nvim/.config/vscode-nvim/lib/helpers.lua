-- Shared helpers for the isolated VSCode/Cursor Neovim config.
-- This file is NOT loaded by ~/.config/nvim.

local M = {}

M.root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

function M.vscode()
  return require("vscode")
end

function M.action(cmd)
  return function()
    M.vscode().action(cmd)
  end
end

function M.notify(cmd)
  return function()
    vim.fn.VSCodeNotify(cmd)
  end
end

function M.notify_range(cmd)
  return function()
    vim.fn.VSCodeNotifyRange(cmd, vim.fn.line("v"), vim.fn.line("."), 1)
  end
end

---@param specs table[]
function M.apply_specs(specs)
  for _, spec in ipairs(specs) do
    if spec.condition == nil or spec.condition() then
      local rhs = spec.rhs or spec.action
      if rhs then
        local opts = vim.tbl_extend("force", spec.opts or {}, { desc = spec.desc, silent = true })
        vim.keymap.set(spec.mode, spec.lhs, rhs, opts)
      end
    end
  end
end

function M.map_both(lhs, rhs, opts)
  opts = vim.tbl_extend("force", opts or {}, { noremap = true, silent = true })
  vim.keymap.set("n", lhs, rhs, opts)
  vim.keymap.set("v", lhs, rhs, opts)
end

return M
