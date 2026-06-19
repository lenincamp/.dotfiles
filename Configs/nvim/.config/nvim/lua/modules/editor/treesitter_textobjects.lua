local M = {}

local kinds = {
  function_ = {
    function_declaration = true,
    function_definition = true,
    function_item = true,
    function_expression = true,
    method_declaration = true,
    method_definition = true,
    arrow_function = true,
  },
  class = {
    class_declaration = true,
    class_definition = true,
    interface_declaration = true,
    enum_declaration = true,
    struct_item = true,
    trait_item = true,
  },
  parameter = {
    formal_parameter = true,
    parameter = true,
    parameter_declaration = true,
    required_parameter = true,
    optional_parameter = true,
    argument = true,
  },
}

local function contains(node, row, col)
  local start_row, start_col, end_row, end_col = node:range()
  if row < start_row or row > end_row then
    return false
  end
  if row == start_row and col < start_col then
    return false
  end
  if row == end_row and col > end_col then
    return false
  end
  return true
end

local function range_before(a, b)
  local a_row, a_col = a:range()
  local b_row, b_col = b:range()
  return a_row < b_row or (a_row == b_row and a_col < b_col)
end

local function root_node()
  local parser = vim.treesitter.get_parser(0)
  if not parser then
    return nil
  end
  local tree = parser:parse()[1]
  return tree and tree:root() or nil
end

local function collect(kind)
  local root = root_node()
  if not root then
    return {}
  end

  local matches = {}
  local wanted = kinds[kind] or {}
  local function visit(node)
    if wanted[node:type()] then
      matches[#matches + 1] = node
    end
    for child in node:iter_children() do
      visit(child)
    end
  end
  visit(root)
  table.sort(matches, range_before)
  return matches
end

local function current_node(kind)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local best = nil
  for _, node in ipairs(collect(kind)) do
    if contains(node, row, col) then
      local start_row, start_col, end_row, end_col = node:range()
      local best_start_row, best_start_col, best_end_row, best_end_col = best and best:range()
      local node_size = ((end_row - start_row) * 100000) + (end_col - start_col)
      local best_size = best and (((best_end_row - best_start_row) * 100000) + (best_end_col - best_start_col)) or math.huge
      if node_size <= best_size then
        best = node
      end
    end
  end
  return best
end

local function goto_node(node, end_position)
  if not node then
    return
  end
  local start_row, start_col, end_row, end_col = node:range()
  if end_position then
    vim.api.nvim_win_set_cursor(0, { end_row + 1, math.max(0, end_col - 1) })
  else
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  end
  vim.cmd("normal! zv")
end

local function goto_match(kind, direction, end_position)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local nodes = collect(kind)

  if direction > 0 then
    for _, node in ipairs(nodes) do
      local start_row, start_col, end_row, end_col = node:range()
      local target_row = end_position and end_row or start_row
      local target_col = end_position and end_col or start_col
      if target_row > row or (target_row == row and target_col > col) then
        goto_node(node, end_position)
        return
      end
    end
  else
    for index = #nodes, 1, -1 do
      local node = nodes[index]
      local start_row, start_col, end_row, end_col = node:range()
      local target_row = end_position and end_row or start_row
      local target_col = end_position and end_col or start_col
      if target_row < row or (target_row == row and target_col < col) then
        goto_node(node, end_position)
        return
      end
    end
  end
end

local function select_node(kind)
  local node = current_node(kind)
  if not node then
    return
  end
  local start_row, start_col, end_row, end_col = node:range()
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { end_row + 1, math.max(0, end_col - 1) })
end

local function node_text(node)
  return vim.treesitter.get_node_text(node, 0, { metadata = {} })
end

local function replace_node(node, text)
  local start_row, start_col, end_row, end_col = node:range()
  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, vim.split(text, "\n", { plain = true }))
end

local function swap_parameter(direction)
  local node = current_node("parameter")
  if not node then
    return
  end

  local params = collect("parameter")
  local index = nil
  for i, candidate in ipairs(params) do
    if candidate:id() == node:id() then
      index = i
      break
    end
  end
  if not index then
    return
  end

  local other = params[index + direction]
  if not other then
    return
  end

  local node_text_value = node_text(node)
  local other_text_value = node_text(other)
  if direction > 0 then
    replace_node(other, node_text_value)
    replace_node(node, other_text_value)
  else
    replace_node(node, other_text_value)
    replace_node(other, node_text_value)
  end
end

function M.setup()
  local map = vim.keymap.set

  map("n", "]f", function() goto_match("function_", 1, false) end, { desc = "Next function start" })
  map("n", "[f", function() goto_match("function_", -1, false) end, { desc = "Prev function start" })
  map("n", "]F", function() goto_match("function_", 1, true) end, { desc = "Next function end" })
  map("n", "[F", function() goto_match("function_", -1, true) end, { desc = "Prev function end" })

  map("n", "]c", function() goto_match("class", 1, false) end, { desc = "Next class start" })
  map("n", "[c", function() goto_match("class", -1, false) end, { desc = "Prev class start" })
  map("n", "]C", function() goto_match("class", 1, true) end, { desc = "Next class end" })
  map("n", "[C", function() goto_match("class", -1, true) end, { desc = "Prev class end" })

  map("n", "]a", function() goto_match("parameter", 1, false) end, { desc = "Next parameter" })
  map("n", "[a", function() goto_match("parameter", -1, false) end, { desc = "Prev parameter" })

  for _, mode in ipairs({ "o", "x" }) do
    map(mode, "af", function() select_node("function_") end, { desc = "Around function" })
    map(mode, "if", function() select_node("function_") end, { desc = "Inside function" })
    map(mode, "ac", function() select_node("class") end, { desc = "Around class" })
    map(mode, "ic", function() select_node("class") end, { desc = "Inside class" })
    map(mode, "aa", function() select_node("parameter") end, { desc = "Around parameter" })
    map(mode, "ia", function() select_node("parameter") end, { desc = "Inside parameter" })
  end

  map("n", "gsn", function() swap_parameter(1) end, { desc = "Swap param next" })
  map("n", "gsp", function() swap_parameter(-1) end, { desc = "Swap param prev" })
end

return M
