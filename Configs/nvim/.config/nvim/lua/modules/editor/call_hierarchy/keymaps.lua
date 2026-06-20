local M = {}

local function set(lhs, rhs, opts, desc)
  vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
end

function M.setup(bufnr, actions)
  if vim.b[bufnr].call_hierarchy_keymaps then
    return
  end

  local opts = { buffer = bufnr, silent = true, nowait = true }
  set("<CR>", actions.jump, opts, "Call hierarchy: jump")
  set("o", actions.toggle_node, opts, "Call hierarchy: expand")
  set("<Tab>", actions.toggle_node, opts, "Call hierarchy: expand")
  set("za", actions.toggle_node, opts, "Call hierarchy: expand")
  set("i", function() actions.set_direction("incoming") end, opts, "Call hierarchy: incoming")
  set("O", function() actions.set_direction("outgoing") end, opts, "Call hierarchy: outgoing")
  set("r", actions.refresh, opts, "Call hierarchy: refresh")
  set("q", actions.close, opts, "Call hierarchy: close")
  set("?", actions.toggle_help, opts, "Call hierarchy: help")
  set("Q", actions.to_quickfix, opts, "Call hierarchy: quickfix")

  vim.b[bufnr].call_hierarchy_keymaps = true
end

return M
