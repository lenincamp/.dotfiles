local M = {}

local function debug_enabled()
  return vim.g.dap_method_jump_debug == true
end

local function debug_log(msg)
  if debug_enabled() then
    vim.notify("[dap-method-jump] " .. msg, vim.log.levels.INFO)
  end
end

local function get_enclosing_method_range(bufnr, line)
  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, "java")
  if not ok_parser or not parser then return nil, nil end

  local trees = parser:parse()
  if not trees or not trees[1] then return nil, nil end

  local root = trees[1]:root()
  if not root then return nil, nil end

  local node = root:named_descendant_for_range(line - 1, 0, line - 1, 0)
  while node do
    local node_type = node:type()
    if node_type == "method_declaration" or node_type == "constructor_declaration" then
      local start_row, _, end_row, _ = node:range()
      return start_row + 1, end_row + 1
    end
    node = node:parent()
  end

  return nil, nil
end

local function get_method_breakpoints(bufnr, start_line, end_line)
  local ok_breakpoints, dap_breakpoints = pcall(require, "dap.breakpoints")
  if not ok_breakpoints then return {} end

  local all = dap_breakpoints.get(bufnr)[bufnr] or {}
  local result = {}
  for _, breakpoint in ipairs(all) do
    if breakpoint.line >= start_line and breakpoint.line <= end_line then
      result[#result + 1] = breakpoint.line
    end
  end

  table.sort(result)
  return result
end

local function resolve_source_win(bufnr, preferred_win)
  if preferred_win and vim.api.nvim_win_is_valid(preferred_win)
      and vim.api.nvim_win_get_buf(preferred_win) == bufnr then
    return preferred_win
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      return win
    end
  end

  return nil
end

local function has_breakpoint_at(bufnr, line)
  local ok_breakpoints, dap_breakpoints = pcall(require, "dap.breakpoints")
  if not ok_breakpoints then return false end
  local breakpoints = dap_breakpoints.get(bufnr)[bufnr] or {}
  for _, breakpoint in ipairs(breakpoints) do
    if breakpoint.line == line then return true end
  end
  return false
end

local function set_breakpoint_at(dap, bufnr, line, source_win)
  local win = resolve_source_win(bufnr, source_win)
  if not win then
    vim.notify("Cannot find source window to set temporary breakpoint", vim.log.levels.WARN)
    return false
  end

  vim.api.nvim_win_call(win, function()
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    dap.set_breakpoint()
  end)
  return true
end

local function remove_breakpoint_at(dap, bufnr, line)
  local ok_breakpoints, dap_breakpoints = pcall(require, "dap.breakpoints")
  if not ok_breakpoints then return end
  dap_breakpoints.remove(bufnr, line)

  local session = dap.session()
  if session then
    local breakpoints = dap_breakpoints.get()
    session:set_breakpoints(breakpoints, function() end)
  end
end

local function continue_to_temp_breakpoint(dap, bufnr, target_line, source_win)
  local temp_added = false
  if not has_breakpoint_at(bufnr, target_line) then
    temp_added = set_breakpoint_at(dap, bufnr, target_line, source_win)
    if not temp_added then return end
    debug_log(string.format("temp breakpoint added at %d", target_line))
  else
    debug_log(string.format("reusing existing breakpoint at %d", target_line))
  end

  local cleanup_id = "nvim-pure-method-breakpoint-cleanup"
  local function cleanup()
    dap.listeners.before.event_stopped[cleanup_id] = nil
    dap.listeners.before.event_terminated[cleanup_id] = nil
    dap.listeners.before.event_exited[cleanup_id] = nil
    dap.listeners.before.disconnect[cleanup_id] = nil
    if temp_added then
      vim.schedule(function()
        remove_breakpoint_at(dap, bufnr, target_line)
        debug_log(string.format("temp breakpoint removed at %d", target_line))
      end)
    end
  end

  dap.listeners.before.event_stopped[cleanup_id] = cleanup
  dap.listeners.before.event_terminated[cleanup_id] = cleanup
  dap.listeners.before.event_exited[cleanup_id] = cleanup
  dap.listeners.before.disconnect[cleanup_id] = cleanup

  dap.continue()
end

local function current_frame_line(session)
  local frame = session and session.current_frame
  if frame and type(frame.line) == "number" then
    return frame.line
  end
  return nil
end

local function current_source_line(bufnr, source_win)
  local win = resolve_source_win(bufnr, source_win)
  if not win then return nil end
  if vim.api.nvim_win_get_buf(win) ~= bufnr then return nil end
  return vim.api.nvim_win_get_cursor(win)[1]
end

function M.run_to_cursor(dap)
  dap.run_to_cursor()
end

function M.run_to_method_breakpoint(dap)
  local session = dap.session()
  if not session or not session.stopped_thread_id then
    vim.notify("Debugger must be stopped to use method breakpoint picker", vim.log.levels.INFO)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local start_line, end_line = get_enclosing_method_range(bufnr, current_line)
  if not start_line or not end_line then
    vim.notify("No enclosing Java method found at cursor", vim.log.levels.WARN)
    return
  end

  local method_breakpoints = get_method_breakpoints(bufnr, start_line, end_line)
  if #method_breakpoints == 0 then
    vim.notify("No breakpoints found in current method", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, line in ipairs(method_breakpoints) do
    local mark = (line == current_line) and " (current)" or ""
    items[#items + 1] = { line = line, label = string.format("line %d%s", line, mark) }
  end

  require("modules.editor.picker").select_items(items, {
    prompt = "Run to method breakpoint",
    search_threshold = 0,
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    local target_line = choice.line
    debug_log(string.format("selected target=%d current=%d", target_line, current_line))

    if target_line == current_line then
      vim.notify("Already at selected breakpoint", vim.log.levels.INFO)
      return
    end

    if target_line > current_line then
      debug_log("forward jump via continue_to_temp_breakpoint")
      continue_to_temp_breakpoint(dap, bufnr, target_line, source_win)
      return
    end

    if not session.capabilities or not session.capabilities.supportsRestartFrame then
      vim.notify("Adapter does not support restart frame; rerun request to hit earlier breakpoint", vim.log.levels.WARN)
      return
    end

    local listener_id = "nvim-pure-run-to-method-breakpoint-restart"
    dap.listeners.after.event_stopped[listener_id] = function()
      dap.listeners.after.event_stopped[listener_id] = nil
      local function maybe_continue(attempt)
        local active = dap.session()
        local frame_line = current_frame_line(active)
        local source_line = current_source_line(bufnr, source_win)
        local observed_line = source_line or frame_line

        debug_log(string.format(
          "after restart attempt=%d frame=%s source=%s target=%d",
          attempt,
          tostring(frame_line),
          tostring(source_line),
          target_line
        ))

        if observed_line == target_line then
          debug_log("already at target after restart")
          return
        end

        if observed_line and observed_line > target_line then
          if attempt < 2 then
            vim.defer_fn(function() maybe_continue(attempt + 1) end, 30)
            return
          end
          debug_log("restart landed after target; aborting continue to avoid +1 overshoot")
          return
        end

        debug_log("backward jump continuing to temp breakpoint")
        continue_to_temp_breakpoint(dap, bufnr, target_line, source_win)
      end

      vim.schedule(function() maybe_continue(1) end)
    end

    debug_log("executing restart_frame")
    dap.restart_frame()
  end)
end

return M
