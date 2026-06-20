local M = {}

local function set(lhs, rhs, opts)
  vim.keymap.set("n", lhs, rhs, opts)
end

function M.setup(bufnr, actions)
  local opts = { buffer = bufnr, silent = true }
  set("q", actions.close, opts)
  set("<Esc>", actions.close, opts)
  set("<CR>", actions.jump, opts)
  set("o", actions.jump, opts)
  set("j", function() actions.move_cursor(1) end, opts)
  set("k", function() actions.move_cursor(-1) end, opts)
  set("<Down>", function() actions.move_cursor(1) end, opts)
  set("<Up>", function() actions.move_cursor(-1) end, opts)
  set("d", actions.remove_current, opts)
  set("n", actions.update_normal, opts)
  set("c", actions.update_condition, opts)
  set("l", actions.update_logpoint, opts)
  set("h", actions.update_hit_condition, opts)
  set("g", actions.update_group, opts)
  set("G", actions.update_group, opts)
  set("R", actions.rename_group, opts)
  set("s", actions.save, opts)
  set("<Tab>", actions.toggle_preview, opts)
  set("<A-f>", actions.toggle_fullscreen, opts)
  set("<A-l>", actions.toggle_layout, opts)
  set("?", actions.toggle_descriptions, opts)
end

return M
