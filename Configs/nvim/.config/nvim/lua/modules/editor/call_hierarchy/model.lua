local M = {}

function M.call_method(direction)
  return direction == "outgoing" and "callHierarchy/outgoingCalls" or "callHierarchy/incomingCalls"
end

function M.call_item(direction, call)
  if direction == "outgoing" then
    return call.to
  end
  return call.from
end

function M.item_range(item)
  return item and (item.selectionRange or item.range) or nil
end

function M.item_line(item)
  local range = M.item_range(item)
  return range and range.start and (range.start.line + 1) or 1
end

function M.item_col(item)
  local range = M.item_range(item)
  return range and range.start and range.start.character or 0
end

function M.item_file(item)
  if not item or type(item.uri) ~= "string" then
    return ""
  end

  local ok, name = pcall(vim.uri_to_fname, item.uri)
  if not ok or type(name) ~= "string" then
    return item.uri
  end

  return vim.fn.fnamemodify(name, ":~:.")
end

function M.item_label(item)
  if not item then
    return "<unknown>"
  end

  local name = item.name or "<anonymous>"
  local detail = item.detail and vim.trim(item.detail) or ""
  local file = M.item_file(item)
  local file_part = file ~= "" and ("  " .. vim.fn.fnamemodify(file, ":t") .. ":" .. M.item_line(item)) or ""

  if detail ~= "" and detail ~= name then
    return name .. "  " .. detail .. file_part
  end
  return name .. file_part
end

function M.node_id(item)
  if not item then
    return ""
  end

  local range = M.item_range(item)
  local line = range and range.start and range.start.line or 0
  local col = range and range.start and range.start.character or 0
  return table.concat({ item.uri or "", item.name or "", tostring(line), tostring(col) }, "|")
end

function M.make_node(item, depth, parent)
  return {
    id = M.node_id(item),
    item = item,
    depth = depth or 0,
    parent = parent,
    expanded = false,
    loading = false,
    children = nil,
  }
end

return M
