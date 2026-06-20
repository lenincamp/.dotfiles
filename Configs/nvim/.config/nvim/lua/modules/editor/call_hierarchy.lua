local M = {}

local keymaps = require("modules.editor.call_hierarchy.keymaps")
local lsp_core = require("modules.core.lsp")
local model = require("modules.editor.call_hierarchy.model")
local view = require("modules.editor.call_hierarchy.view")

local PREPARE = "textDocument/prepareCallHierarchy"

local state = {
  bufnr = nil,
  win = nil,
  source_bufnr = nil,
  source_win = nil,
  client = nil,
  root = nil,
  direction = "incoming",
  line_nodes = {},
  help = false,
}

local function is_valid_buf(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function is_valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function direction_label()
  return state.direction == "outgoing" and "outgoing" or "incoming"
end

local function call_method()
  return model.call_method(state.direction)
end

local function call_item(call)
  return model.call_item(state.direction, call)
end

local function make_node(item, depth, parent)
  return model.make_node(item, depth, parent)
end

local function clients_with_call_hierarchy(bufnr)
  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if lsp_core.supports_method(client, PREPARE, bufnr) then
      clients[#clients + 1] = client
    end
  end
  return clients
end

local function select_client(bufnr, on_choice)
  local clients = clients_with_call_hierarchy(bufnr)
  if #clients == 0 then
    vim.notify("No LSP client supports call hierarchy for this buffer", vim.log.levels.WARN)
    return
  end

  if #clients == 1 then
    on_choice(clients[1])
    return
  end

  require("modules.editor.picker").select_items(clients, {
    prompt = "Call hierarchy client:",
    scope = "buffer",
    search_threshold = 0,
    format_item = function(client)
      return client.name
    end,
  }, on_choice)
end

local function select_prepare_item(items, on_choice)
  if type(items) ~= "table" or #items == 0 then
    vim.notify("No call hierarchy item at cursor", vim.log.levels.INFO)
    return
  end

  if #items == 1 then
    on_choice(items[1])
    return
  end

  require("modules.editor.picker").select_items(items, {
    prompt = "Call hierarchy item:",
    scope = "cursor",
    search_threshold = 0,
    format_item = model.item_label,
  }, on_choice)
end

local function ensure_buffer()
  if is_valid_buf(state.bufnr) then
    return state.bufnr
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  state.bufnr = bufnr
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].filetype = "call_hierarchy"
  pcall(vim.api.nvim_buf_set_name, bufnr, "Call Hierarchy")
  return bufnr
end

local function ensure_window()
  local bufnr = ensure_buffer()
  if is_valid_win(state.win) then
    return state.win
  end

  vim.cmd("botright new")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, bufnr)
  vim.api.nvim_win_set_height(state.win, math.min(18, math.max(10, math.floor(vim.o.lines * 0.28))))
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].wrap = false
  vim.wo[state.win].cursorline = true
  return state.win
end

local function render()
  if not state.root then
    return
  end

  local bufnr = ensure_buffer()
  local lines, line_nodes = view.lines(state)
  state.line_nodes = line_nodes

  local win = is_valid_win(state.win) and state.win or nil
  local cursor_line = win and vim.api.nvim_win_get_cursor(win)[1] or 1

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  if win then
    pcall(vim.api.nvim_win_set_cursor, win, { math.min(cursor_line, #lines), 0 })
  end
end

local function request_children(node)
  if not state.client or node.loading then
    return
  end

  node.loading = true
  node.expanded = true
  render()

  state.client:request(call_method(), { item = node.item }, function(err, result)
    vim.schedule(function()
      node.loading = false

      if err then
        node.children = {}
        vim.notify("Call hierarchy request failed: " .. tostring(err.message or err), vim.log.levels.WARN)
        render()
        return
      end

      node.children = {}
      for _, call in ipairs(result or {}) do
        local item = call_item(call)
        if item then
          node.children[#node.children + 1] = make_node(item, node.depth + 1, node)
        end
      end

      node.expanded = #node.children > 0
      render()
    end)
  end, state.source_bufnr)
end

local function selected_node()
  if not is_valid_win(state.win) then
    return nil
  end

  local lnum = vim.api.nvim_win_get_cursor(state.win)[1]
  return state.line_nodes[lnum]
end

local function make_source_position_params(bufnr, win, cursor, position_encoding)
  if is_valid_win(win) and vim.api.nvim_win_get_buf(win) == bufnr then
    return vim.lsp.util.make_position_params(win, position_encoding)
  end

  if not is_valid_buf(bufnr) then
    return nil
  end

  local row = cursor and cursor[1] or 1
  local byte_col = cursor and cursor[2] or 0
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  local ok_col, character = pcall(vim.str_utfindex, line, position_encoding, byte_col, false)
  if not ok_col then
    character = byte_col
  end

  return {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = {
      line = row - 1,
      character = character,
    },
  }
end

local function jump_to_item(item)
  if not item or type(item.uri) ~= "string" then
    return false
  end

  local loc = {
    uri = item.uri,
    range = model.item_range(item),
  }

  local ok = false
  if is_valid_win(state.source_win) then
    vim.api.nvim_set_current_win(state.source_win)
  end

  if state.client then
    ok = pcall(vim.lsp.util.show_document, loc, state.client.offset_encoding or "utf-16", { focus = true })
  end

  if ok then
    return true
  end

  local bufnr = vim.uri_to_bufnr(item.uri)
  vim.fn.bufload(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  pcall(vim.api.nvim_win_set_cursor, 0, { model.item_line(item), model.item_col(item) })
  return true
end

function M.jump()
  local node = selected_node()
  if node then
    jump_to_item(node.item)
  end
end

function M.toggle_node()
  local node = selected_node()
  if not node then
    return
  end

  if node.children == nil then
    request_children(node)
    return
  end

  if #node.children == 0 then
    return
  end

  node.expanded = not node.expanded
  render()
end

function M.set_direction(direction)
  direction = direction == "outgoing" and "outgoing" or "incoming"
  if state.direction == direction and state.root and state.root.children ~= nil then
    return
  end

  state.direction = direction
  if state.root then
    state.root.children = nil
    state.root.expanded = false
    request_children(state.root)
  end
end

function M.refresh()
  if not state.root then
    return
  end

  state.root.children = nil
  state.root.expanded = false
  request_children(state.root)
end

function M.toggle_help()
  state.help = not state.help
  render()
end

function M.close()
  if is_valid_win(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  state.win = nil
end

function M.to_quickfix()
  local items = {}
  local line_count = is_valid_buf(state.bufnr) and vim.api.nvim_buf_line_count(state.bufnr) or 0
  for lnum = 1, line_count do
    local node = state.line_nodes[lnum]
    local item = node and node.item or nil
    if item and item.uri then
      items[#items + 1] = {
        filename = model.item_file(item),
        lnum = model.item_line(item),
        col = model.item_col(item) + 1,
        text = string.rep("  ", node.depth) .. model.item_label(item),
      }
    end
  end

  if #items == 0 then
    vim.notify("Call hierarchy has no visible nodes", vim.log.levels.INFO)
    return
  end

  vim.fn.setqflist({}, "r", { title = "Call Hierarchy [" .. direction_label() .. "]", items = items })
  vim.cmd("copen")
end

function M.open(direction)
  direction = direction == "outgoing" and "outgoing" or "incoming"
  local source_bufnr = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  local source_cursor = vim.api.nvim_win_get_cursor(source_win)

  select_client(source_bufnr, function(client)
    if not client then
      return
    end

    local params = make_source_position_params(source_bufnr, source_win, source_cursor, client.offset_encoding or "utf-16")
    if not params then
      vim.notify("Call hierarchy source buffer is no longer available", vim.log.levels.WARN)
      return
    end

    client:request(PREPARE, params, function(err, result)
      vim.schedule(function()
        if err then
          vim.notify("Call hierarchy prepare failed: " .. tostring(err.message or err), vim.log.levels.WARN)
          return
        end

        select_prepare_item(result, function(item)
          if not item then
            return
          end

          state.source_bufnr = source_bufnr
          state.source_win = source_win
          state.client = client
          state.direction = direction
          state.root = make_node(item, 0, nil)

          local bufnr = ensure_buffer()
          keymaps.setup(bufnr, {
            close = M.close,
            jump = M.jump,
            refresh = M.refresh,
            set_direction = M.set_direction,
            to_quickfix = M.to_quickfix,
            toggle_help = M.toggle_help,
            toggle_node = M.toggle_node,
          })
          ensure_window()
          render()
          request_children(state.root)
        end)
      end)
    end, source_bufnr)
  end)
end

function M.incoming()
  M.open("incoming")
end

function M.outgoing()
  M.open("outgoing")
end

return M
