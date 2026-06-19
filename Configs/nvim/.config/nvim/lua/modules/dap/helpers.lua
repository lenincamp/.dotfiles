local M = {}

local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  return M
end

local widgets = require("dap.ui.widgets")
local breakpoints = require("modules.dap.breakpoints")
local eval_helpers = require("modules.dap.helpers.eval")
local run_to_helpers = require("modules.dap.helpers.run_to")
local session_helpers = require("modules.dap.helpers.session")
local view_helpers = require("modules.dap.helpers.view")
local watch_helpers = require("modules.dap.helpers.watch")
local runtime = require("modules.core.runtime")

watch_helpers.setup(dap)

function M.java_project_name(path_hint)
  return session_helpers.java_project_name(path_hint)
end

function M.run_to_cursor()
  run_to_helpers.run_to_cursor(dap)
end

function M.run_to_method_breakpoint()
  run_to_helpers.run_to_method_breakpoint(dap)
end

function M.toggle_breakpoint_and_save()
  dap.toggle_breakpoint()
  breakpoints.save_async()
end

function M.conditional_breakpoint_prompt()
  vim.ui.input({ prompt = "Breakpoint condition: ", scope = "line" }, function(condition)
    if condition == nil then return end
    dap.set_breakpoint(condition)
    breakpoints.save_async()
  end)
end

function M.logpoint_prompt()
  vim.ui.input({ prompt = "Logpoint message: ", scope = "line" }, function(message)
    if message == nil then return end
    dap.set_breakpoint(nil, nil, message)
    breakpoints.save_async()
  end)
end

function M.clear_breakpoints_and_save()
  dap.clear_breakpoints()
  breakpoints.save_async()
end

function M.show_session()
  view_helpers.show_session(dap)
end

function M.hover_widget()
  view_helpers.hover_widget(widgets)
end

M._open_eval_floating = function(initial_lines, ft) eval_helpers.open_floating(dap, initial_lines, ft) end
M._flatten_expr = eval_helpers.flatten_expr

function M.eval_expression_prompt()
  eval_helpers.eval_expression_prompt(dap)
end

function M.set_expression_prompt()
  eval_helpers.set_expression_prompt(dap)
end

function M.show_dap_capabilities()
  local session = dap.session()
  if not session then
    vim.notify("No active DAP session", vim.log.levels.WARN)
    return
  end

  local caps = session_helpers.capabilities(session)
  vim.notify(vim.inspect({
    adapter = session.config and session.config.type,
    supportsSetExpression = caps.supportsSetExpression,
    supportsSetVariable = caps.supportsSetVariable,
    supportsEvaluateForHovers = caps.supportsEvaluateForHovers,
    supportsRestartFrame = caps.supportsRestartFrame,
  }), vim.log.levels.INFO)
end

function M.add_watch_prompt()
  watch_helpers.add_prompt(dap)
end

function M.add_watch_from_visual_selection()
  watch_helpers.add_from_visual_selection(dap)
end

function M.open_repl_view()
  view_helpers.open_repl_view(dap)
end

function M.eval_visual_selection_in_repl()
  eval_helpers.eval_visual_selection_in_repl(dap)
end

function M.goto_line_prompt()
  vim.ui.input({ prompt = "Line: ", scope = "buffer" }, function(line)
    if line == nil then return end
    dap.goto_(tonumber(line))
  end)
end

function M.continue_with_args_prompt()
  vim.ui.input({ prompt = "Args: ", scope = "project" }, function(args)
    if args == nil then return end
    dap.continue({
      before = function(config)
        config.args = vim.split(args or "", " ")
        return config
      end,
    })
  end)
end

function M.toggle_dap_view(action)
  view_helpers.toggle_dap_view(runtime, action)
end

function M.breakpoints_save()
  breakpoints.mark_dirty()
  breakpoints.save()
end

function M.breakpoints_load()
  breakpoints.load()
end

function M.breakpoints_assign_group()
  breakpoints.assign_group()
end

function M.breakpoints_picker()
  breakpoints.picker()
end

-- ── Breakpoint format helpers (used by dap-view render config) ───────────────

-- Resolve breakpoint type icon by looking up dap.breakpoints metadata.
function M.bp_icon_for(lnum_str, path)
  return breakpoints.icon_for(lnum_str, path)
end

-- Shorten path: last 2 components for deep paths, full for short ones.
function M.short_path(path)
  return breakpoints.short_path(path)
end

return M
