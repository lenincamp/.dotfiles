local M = {}

local function marker_for(node, opts)
  opts = opts or {}
  if node.loading then
    return opts.loading_marker or "..."
  end
  if node.children == nil then
    return opts.unresolved_marker or ">"
  end
  if #node.children > 0 then
    return node.expanded and (opts.expanded_marker or "v") or (opts.collapsed_marker or ">")
  end
  return opts.leaf_marker or " "
end

local function append(lines, line_nodes, node, opts)
  local depth = tonumber(node.depth) or 0
  local indent = string.rep(opts.indent or "  ", depth)
  local label = opts.label and opts.label(node) or tostring(node.label or "")

  lines[#lines + 1] = string.format("%s%s %s", indent, marker_for(node, opts), label)
  line_nodes[#lines] = node

  if node.expanded and node.children then
    for _, child in ipairs(node.children) do
      append(lines, line_nodes, child, opts)
    end
  end
end

function M.lines(root, opts)
  opts = opts or {}
  if not root then
    return {}, {}
  end

  local lines = {}
  local line_nodes = {}
  append(lines, line_nodes, root, opts)
  return lines, line_nodes
end

return M
