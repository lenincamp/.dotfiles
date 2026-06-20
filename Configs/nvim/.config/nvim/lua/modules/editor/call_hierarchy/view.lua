local M = {}

local model = require("modules.editor.call_hierarchy.model")
local tree_view = require("modules.editor.tree_view")

local PREPARE = "textDocument/prepareCallHierarchy"

function M.lines(state)
  if not state.root then
    return nil, {}
  end

  local direction = state.direction == "outgoing" and "outgoing" or "incoming"
  local lines = {
    "Call Hierarchy [" .. direction .. "]",
    "<CR> jump  o/<Tab> expand  i incoming  O outgoing  r refresh  Q quickfix  q close  ? help",
    "",
  }
  local line_nodes = {}

  if state.help then
    lines[#lines + 1] = "Native LSP methods: " .. PREPARE .. ", " .. model.call_method(state.direction)
    lines[#lines + 1] = "The tree is resolved lazily; expand a node to request its children."
    lines[#lines + 1] = ""
  end

  local tree_lines, tree_nodes = tree_view.lines(state.root, {
    label = function(node)
      return model.item_label(node.item)
    end,
  })
  local offset = #lines
  vim.list_extend(lines, tree_lines)
  for line, node in pairs(tree_nodes) do
    line_nodes[offset + line] = node
  end
  return lines, line_nodes
end

return M
