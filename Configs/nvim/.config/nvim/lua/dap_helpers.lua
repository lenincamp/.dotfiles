local M = {}

local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  return M
end

local widgets = require("dap.ui.widgets")
local WATCH_QUEUE_LISTENER_ID = "nvim-pure-watch-queue"
local pending_watch_exprs = {}
local java_project_name_cache = {}

local function normalize_path(path)
  if type(path) ~= "string" or path == "" then return nil end
  return (vim.fs.normalize(path)):gsub("/+$", "")
end

local function path_has_prefix(path, prefix)
  path = normalize_path(path)
  prefix = normalize_path(prefix)
  if not path or not prefix then return false end
  if path == prefix then return true end
  return path:sub(1, #prefix + 1) == (prefix .. "/")
end

local function best_jdtls_root(path_hint)
  local ok_clients, clients = pcall(vim.lsp.get_clients, { name = "jdtls" })
  if not ok_clients or type(clients) ~= "table" then return nil end

  local normalized_hint = normalize_path(path_hint)
  local best_root = nil
  local best_len = -1

  for _, client in ipairs(clients) do
    local root = normalize_path(client and client.config and client.config.root_dir)
    if root then
      if not normalized_hint then
        if #root > best_len then
          best_root = root
          best_len = #root
        end
      elseif path_has_prefix(normalized_hint, root) and #root > best_len then
        best_root = root
        best_len = #root
      end
    end
  end

  return best_root
end

local function nearest_java_root(path)
  local marker = vim.fs.find({ "mvnw", "pom.xml", "settings.gradle", "build.gradle", ".git" }, {
    path = path or vim.fn.getcwd(),
    upward = true,
  })[1]
  return marker and vim.fs.dirname(marker) or nil
end

function M.java_project_name(path_hint)
  local root = best_jdtls_root(path_hint)
  if root then
    local cached = java_project_name_cache[root]
    if cached then return cached end
    local resolved = vim.fn.fnamemodify(root, ":t")
    java_project_name_cache[root] = resolved
    return resolved
  end

  local global_name = vim.g.nvim_pure_java_project_name
  if type(global_name) == "string" and global_name ~= "" then
    return global_name
  end

  local normalized_hint = normalize_path(path_hint)
  if not normalized_hint then normalized_hint = normalize_path(vim.fn.expand("%:p:h")) end
  if not normalized_hint then normalized_hint = normalize_path(vim.fn.getcwd()) end
  local guessed_root = nearest_java_root(normalized_hint) or nearest_java_root(vim.fn.getcwd())
  guessed_root = normalize_path(guessed_root)
  if guessed_root then
    local cached = java_project_name_cache[guessed_root]
    if cached then return cached end
    local resolved = vim.fn.fnamemodify(guessed_root, ":t")
    java_project_name_cache[guessed_root] = resolved
    return resolved
  end

  return nil
end

local function session_capabilities(session)
  return (session and session.capabilities) or {}
end

local function normalize_dap_error(err)
  if not err then return nil end
  if type(err) == "string" then return err end
  if type(err) ~= "table" then return tostring(err) end

  local msg = err.message
  if not msg and err.body and err.body.error then
    msg = err.body.error.message
  end
  if not msg and err.error then
    msg = err.error.message or err.error
  end
  return msg or vim.inspect(err)
end

local function notify_java_eval_hint(msg)
  if not msg then return end
  local lowered = msg:lower()
  if lowered:find("classnotfound")
      or lowered:find("noclassdeffound")
      or lowered:find("library")
      or lowered:find("module") then
    vim.notify(
      "Java DAP: possible classpath/module issue. Prefer JDTLS main-class config (not Current File), then :JdtUpdateConfig and restart debug session.",
      vim.log.levels.WARN
    )
  end

  if lowered:find("specify projectname") then
    vim.notify(
      "Java DAP: missing projectName on attach session. Auto-retry is enabled; if it persists, run :JdtUpdateConfig and re-attach.",
      vim.log.levels.WARN
    )
  end
end

local function is_missing_project_name_error(msg)
  if not msg then return false end
  return msg:lower():find("specify projectname") ~= nil
end

local function maybe_set_java_project_name(session)
  if not session or not session.config or session.config.type ~= "java" then return false end
  if type(session.config.projectName) == "string" and session.config.projectName ~= "" then return true end

  local frame_source_path = session.current_frame
    and session.current_frame.source
    and session.current_frame.source.path
  local buf_path = vim.api.nvim_buf_get_name(0)
  local hint = frame_source_path or (buf_path ~= "" and buf_path or nil)

  local resolved = M.java_project_name(hint)
  if not resolved then return false end
  session.config.projectName = resolved
  return true
end

local function run_dap_request(session, command, args, on_success, retry_count)
  if not session then
    vim.notify("No active DAP session", vim.log.levels.WARN)
    return
  end

  session:request(command, args, function(err, response)
    if err then
      local msg = normalize_dap_error(err)
      if (retry_count or 0) < 1 and is_missing_project_name_error(msg) and maybe_set_java_project_name(session) then
        run_dap_request(session, command, args, on_success, 1)
        return
      end
      vim.schedule(function()
        notify_java_eval_hint(msg)
        vim.notify(string.format("DAP %s error: %s", command, msg), vim.log.levels.ERROR)
      end)
      return
    end
    if on_success then on_success(response) end
  end)
end

local function current_frame_id(session)
  local frame = session and session.current_frame
  return frame and frame.id or nil
end

local function eval_in_repl(session, expr)
  local frame_id = current_frame_id(session)
  run_dap_request(session, "evaluate", {
    expression = expr,
    context = "repl",
    frameId = frame_id,
  }, function(response)
    local result = response and response.result
    if result and result ~= "" then
      dap.repl.append(result)
      dap.repl.append("\n")
    end
  end)
end

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

-- Collapse multi-line expression to single physical line (DAP evaluate requires it).
local function flatten_expr(text)
  if not text or text == "" then return "" end
  -- Strip line comments (// ...) before joining so two slashes don't kill the rest.
  local cleaned = {}
  for _, ln in ipairs(vim.split(text, "\n", { plain = true })) do
    cleaned[#cleaned + 1] = ln:gsub("//[^\n]*$", "")
  end
  local joined = table.concat(cleaned, " ")
  joined = joined:gsub("%s+", " ")
  return vim.trim(joined)
end

local function eval_or_set(expr)
  expr = flatten_expr(expr)
  if expr == "" then return end

  local session = dap.session()
  if not session or not session.stopped_thread_id then
    vim.notify("Debugger must be stopped to eval/set expression", vim.log.levels.INFO)
    return
  end

  local caps = session_capabilities(session)
  local lhs, rhs = expr:match("^([%w_%.$%[%]%(%)]+)%s*=%s*(.+)$")

  if lhs and rhs and caps.supportsSetExpression then
    run_dap_request(session, "setExpression", {
      expression = vim.trim(lhs),
      value = vim.trim(rhs),
      frameId = current_frame_id(session),
    })
  else
    eval_in_repl(session, expr)
  end
  M.open_repl_view()
end

-- Floating scratch buffer for multi-line paste / edit (IntelliJ "Evaluate Expression").
-- Submit joins lines into one DAP expression; bypasses dap.repl.execute line-splitting.
local function open_eval_floating(initial_lines, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype   = "nofile"
  if ft and ft ~= "" then
    pcall(function() vim.bo[buf].filetype = ft end)
  end
  if initial_lines and #initial_lines > 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_lines)
  end

  local width  = math.min(100, math.floor(vim.o.columns * 0.8))
  local height = math.min(15,  math.max(6, math.floor(vim.o.lines * 0.35)))
  local row    = math.floor((vim.o.lines   - height) / 2) - 1
  local col    = math.floor((vim.o.columns - width)  / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    row       = row,
    col       = col,
    width     = width,
    height    = height,
    style     = "minimal",
    border    = "rounded",
    title     = " Debug · Evaluate  (<C-CR>/<C-s> submit · q close) ",
    title_pos = "center",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    close()
    eval_or_set(table.concat(lines, "\n"))
  end

  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set({ "n", "i" }, "<C-CR>",  submit, opts)
  vim.keymap.set({ "n", "i" }, "<C-s>",   submit, opts)
  vim.keymap.set({ "n", "i" }, "<D-CR>",  submit, opts)
  vim.keymap.set("n",          "q",       close,  opts)
  vim.keymap.set("n",          "<Esc>",   close,  opts)
end

M._open_eval_floating = open_eval_floating
M._flatten_expr       = flatten_expr

function M.eval_expression_prompt()
  open_eval_floating(nil, vim.bo.filetype)
end

function M.set_expression_prompt()
  vim.ui.input({ prompt = "Set expression (name=value): " }, function(expr)
    if not expr or vim.trim(expr) == "" then return end

    local session = dap.session()
    if not session or not session.stopped_thread_id then
      vim.notify("Debugger must be stopped to set variable", vim.log.levels.INFO)
      return
    end

    local trimmed = vim.trim(expr)
    local lhs, rhs = trimmed:match("^([%w_%.$%[%]%(%)]+)%s*=%s*(.+)$")
    if not lhs or not rhs then
      vim.notify("Use format: variable=value", vim.log.levels.WARN)
      return
    end

    local caps = session_capabilities(session)
    if caps.supportsSetExpression then
      run_dap_request(session, "setExpression", {
        expression = vim.trim(lhs),
        value = vim.trim(rhs),
        frameId = current_frame_id(session),
      })
      return
    end

    eval_in_repl(session, string.format("%s = %s", vim.trim(lhs), vim.trim(rhs)))
  end)
end

function M.show_dap_capabilities()
  local session = dap.session()
  if not session then
    vim.notify("No active DAP session", vim.log.levels.WARN)
    return
  end

  local caps = session_capabilities(session)
  vim.notify(vim.inspect({
    adapter = session.config and session.config.type,
    supportsSetExpression = caps.supportsSetExpression,
    supportsSetVariable = caps.supportsSetVariable,
    supportsEvaluateForHovers = caps.supportsEvaluateForHovers,
    supportsRestartFrame = caps.supportsRestartFrame,
  }), vim.log.levels.INFO)
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
  local raw = visual_selection_text()
  if not raw or raw == "" then return end

  -- If selection has newlines, route through floating eval — gives user a chance
  -- to inspect/edit. If it's already one line, just submit.
  if raw:find("\n") then
    open_eval_floating(vim.split(raw, "\n", { plain = true }), vim.bo.filetype)
  else
    eval_or_set(raw)
  end
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
