local M = {}

local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  return M
end

local widgets = require("dap.ui.widgets")
local WATCH_QUEUE_LISTENER_ID = "nvim-pure-watch-queue"
local pending_watch_exprs = {}

local function method_jump_debug_enabled()
  return vim.g.dap_method_jump_debug == true
end

local function method_jump_debug(msg)
  if method_jump_debug_enabled() then
    vim.notify("[dap-method-jump] " .. msg, vim.log.levels.INFO)
  end
end

local function is_debugger_stopped()
  local session = dap.session()
  return session ~= nil and session.stopped_thread_id ~= nil
end

local function flush_pending_watches()
  if next(pending_watch_exprs) == nil then return end

  local ok_dv, dv = pcall(require, "dap-view")
  if not ok_dv then return end

  for expr, _ in pairs(pending_watch_exprs) do
    dv.add_expr(expr, true)
    pending_watch_exprs[expr] = nil
  end
end

dap.listeners.after.event_stopped[WATCH_QUEUE_LISTENER_ID] = function()
  vim.schedule(flush_pending_watches)
end

dap.listeners.before.event_terminated[WATCH_QUEUE_LISTENER_ID] = function()
  pending_watch_exprs = {}
end

dap.listeners.before.event_exited[WATCH_QUEUE_LISTENER_ID] = function()
  pending_watch_exprs = {}
end

local function save_breakpoints_async()
  vim.schedule(function()
    pcall(function()
      local bp = require("breakpoints")
      bp.mark_dirty()
      bp.save()
    end)
  end)
end

function M.run_to_cursor()
  dap.run_to_cursor()
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
    local typ = node:type()
    if typ == "method_declaration" or typ == "constructor_declaration" then
      local start_row, _, end_row, _ = node:range()
      return start_row + 1, end_row + 1
    end
    node = node:parent()
  end

  return nil, nil
end

local function get_method_breakpoints(bufnr, start_line, end_line)
  local ok_bp, dap_bp = pcall(require, "dap.breakpoints")
  if not ok_bp then return {} end

  local all = dap_bp.get(bufnr)[bufnr] or {}
  local result = {}
  for _, bp in ipairs(all) do
    if bp.line >= start_line and bp.line <= end_line then
      result[#result + 1] = bp.line
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

local function run_to_line(bufnr, target_line, source_win)
  local win = resolve_source_win(bufnr, source_win)
  if not win then
    vim.notify("Cannot find source window for run-to-breakpoint", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_win_call(win, function()
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_win_set_cursor(0, { target_line, 0 })
    dap.run_to_cursor()
  end)
end

local function has_breakpoint_at(bufnr, line)
  local ok_bp, dap_bp = pcall(require, "dap.breakpoints")
  if not ok_bp then return false end
  local bps = dap_bp.get(bufnr)[bufnr] or {}
  for _, bp in ipairs(bps) do
    if bp.line == line then return true end
  end
  return false
end

local function set_breakpoint_at(bufnr, line, source_win)
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

local function remove_breakpoint_at(bufnr, line)
  local ok_bp, dap_bp = pcall(require, "dap.breakpoints")
  if not ok_bp then return end
  dap_bp.remove(bufnr, line)

  local session = dap.session()
  if session then
    local bps = dap_bp.get()
    session:set_breakpoints(bps, function() end)
  end
end

local function continue_to_temp_breakpoint(bufnr, target_line, source_win)
  local temp_added = false
  if not has_breakpoint_at(bufnr, target_line) then
    temp_added = set_breakpoint_at(bufnr, target_line, source_win)
    if not temp_added then return end
    method_jump_debug(string.format("temp breakpoint added at %d", target_line))
  else
    method_jump_debug(string.format("reusing existing breakpoint at %d", target_line))
  end

  local cleanup_id = "nvim-pure-method-breakpoint-cleanup"
  local function cleanup()
    dap.listeners.before.event_stopped[cleanup_id] = nil
    dap.listeners.before.event_terminated[cleanup_id] = nil
    dap.listeners.before.event_exited[cleanup_id] = nil
    dap.listeners.before.disconnect[cleanup_id] = nil
    if temp_added then
      vim.schedule(function()
        remove_breakpoint_at(bufnr, target_line)
        method_jump_debug(string.format("temp breakpoint removed at %d", target_line))
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
  local row = vim.api.nvim_win_get_cursor(win)[1]
  return row
end

function M.run_to_method_breakpoint()
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

  vim.ui.select(items, {
    prompt = "Run to method breakpoint",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    local target_line = choice.line
    method_jump_debug(string.format("selected target=%d current=%d", target_line, current_line))

    if target_line == current_line then
      vim.notify("Already at selected breakpoint", vim.log.levels.INFO)
      return
    end

    if target_line > current_line then
      method_jump_debug("forward jump via continue_to_temp_breakpoint")
      continue_to_temp_breakpoint(bufnr, target_line, source_win)
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

        method_jump_debug(string.format(
          "after restart attempt=%d frame=%s source=%s target=%d",
          attempt,
          tostring(frame_line),
          tostring(source_line),
          target_line
        ))

        if observed_line == target_line then
          method_jump_debug("already at target after restart")
          return
        end

        if observed_line and observed_line > target_line then
          if attempt < 2 then
            vim.defer_fn(function() maybe_continue(attempt + 1) end, 30)
            return
          end
          method_jump_debug("restart landed after target; aborting continue to avoid +1 overshoot")
          return
        end

        method_jump_debug("backward jump continuing to temp breakpoint")
        continue_to_temp_breakpoint(bufnr, target_line, source_win)
      end

      vim.schedule(function() maybe_continue(1) end)
    end

    method_jump_debug("executing restart_frame")
    dap.restart_frame()
  end)
end

function M.toggle_breakpoint_and_save()
  dap.toggle_breakpoint()
  save_breakpoints_async()
end

function M.conditional_breakpoint_prompt()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
  save_breakpoints_async()
end

function M.logpoint_prompt()
  dap.set_breakpoint(nil, nil, vim.fn.input("Logpoint message: "))
  save_breakpoints_async()
end

function M.show_session()
  dap.session()
end

function M.hover_widget()
  widgets.hover()
end

function M.eval_expression_prompt()
  vim.ui.input({ prompt = "Debug eval/set expression: " }, function(expr)
    if not expr or vim.trim(expr) == "" then return end
    dap.repl.execute(expr, { context = "repl" })
    M.open_repl_view()
  end)
end

local function add_watch_expression(expr)
  if not expr or vim.trim(expr) == "" then return end
  expr = vim.trim(expr):gsub("%s+", " ")

  if not is_debugger_stopped() then
    pending_watch_exprs[expr] = true
    vim.notify("Watch queued: it will be added on next debugger stop", vim.log.levels.INFO)
    return
  end

  local ok_dv, dv = pcall(require, "dap-view")
  if not ok_dv then
    vim.notify("dap-view is not available", vim.log.levels.WARN)
    return
  end
  dv.add_expr(expr, true)
end

function M.add_watch_prompt()
  vim.ui.input({ prompt = "Watch expression: " }, function(expr)
    add_watch_expression(expr)
  end)
end

local function visual_selection_text()
  local srow, scol = unpack(vim.api.nvim_buf_get_mark(0, "<"))
  local erow, ecol = unpack(vim.api.nvim_buf_get_mark(0, ">"))
  if srow == 0 or erow == 0 then return nil end
  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  if #lines == 0 then return nil end
  lines[1] = string.sub(lines[1], scol + 1)
  lines[#lines] = string.sub(lines[#lines], 1, ecol + 1)
  return vim.trim(table.concat(lines, "\n"))
end

function M.add_watch_from_visual_selection()
  add_watch_expression(visual_selection_text())
end

function M.open_repl_view()
  local ok_dv, dv = pcall(require, "dap-view")
  if ok_dv then
    dv.open()
    dv.show_view("repl")
    return
  end
  dap.repl.toggle()
end

function M.eval_visual_selection_in_repl()
  local expr = visual_selection_text()
  if not expr or expr == "" then return end
  dap.repl.execute(expr, { context = "repl" })
  M.open_repl_view()
end

function M.goto_line_prompt()
  dap.goto_(tonumber(vim.fn.input("Line: ")))
end

function M.continue_with_args_prompt()
  dap.continue({
    before = function(config)
      local args = vim.fn.input("Args: ")
      config.args = vim.split(args, " ")
      return config
    end,
  })
end

function M.toggle_dap_view()
  local ok_dv, dv = pcall(require, "dap-view")
  if ok_dv then dv.toggle() end
end

function M.breakpoints_save()
  local bp = require("breakpoints")
  bp.mark_dirty()
  bp.save()
end

function M.breakpoints_load()
  require("breakpoints").load()
end

function M.breakpoints_assign_group()
  require("breakpoints").assign_group()
end

function M.breakpoints_picker()
  require("breakpoints").picker()
end

-- ── Breakpoint format helpers (used by dap-view render config) ───────────────

-- Resolve breakpoint type icon by looking up dap.breakpoints metadata.
function M.bp_icon_for(lnum_str, path)
  local ok_bp, dap_bp = pcall(require, "dap.breakpoints")
  if not ok_bp then return "●" end
  local lnum = tonumber(lnum_str)
  for bufnr, entries in pairs(dap_bp.get() or {}) do
    local bname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
    if bname == path then
      for _, bp in ipairs(entries) do
        if bp.line == lnum then
          if bp.logMessage and bp.logMessage ~= "" then return "◉" end
          if bp.condition and bp.condition ~= "" then return "◆" end
          if bp.hitCondition and bp.hitCondition ~= "" then return "◇" end
          return "●"
        end
      end
    end
  end
  return "●"
end

-- Shorten path: last 2 components for deep paths, full for short ones.
function M.short_path(path)
  local parts = vim.split(path, "/")
  if #parts <= 3 then return path end
  return parts[#parts - 1] .. "/" .. parts[#parts]
end

return M
