local M = {}

local eval_helpers = require("modules.dap.helpers.eval")

local LISTENER_ID = "nvim-pure-watch-queue"
local pending_watch_exprs = {}
local setup_done = false

local function is_debugger_stopped(dap)
  local session = dap.session()
  return session ~= nil and session.stopped_thread_id ~= nil
end

local function flush_pending_watches()
  if next(pending_watch_exprs) == nil then return end

  local ok_dap_view, dap_view = pcall(require, "dap-view")
  if not ok_dap_view then return end

  for expr, _ in pairs(pending_watch_exprs) do
    dap_view.add_expr(expr, true)
    pending_watch_exprs[expr] = nil
  end
end

function M.setup(dap)
  if setup_done then return end
  setup_done = true

  dap.listeners.after.event_stopped[LISTENER_ID] = function()
    vim.schedule(flush_pending_watches)
  end

  dap.listeners.before.event_terminated[LISTENER_ID] = function()
    pending_watch_exprs = {}
  end

  dap.listeners.before.event_exited[LISTENER_ID] = function()
    pending_watch_exprs = {}
  end
end

function M.add_expression(dap, expr)
  if not expr or vim.trim(expr) == "" then return end
  expr = vim.trim(expr):gsub("%s+", " ")

  if not is_debugger_stopped(dap) then
    pending_watch_exprs[expr] = true
    vim.notify("Watch queued: it will be added on next debugger stop", vim.log.levels.INFO)
    return
  end

  local ok_dap_view, dap_view = pcall(require, "dap-view")
  if not ok_dap_view then
    vim.notify("dap-view is not available", vim.log.levels.WARN)
    return
  end
  dap_view.add_expr(expr, true)
end

function M.add_prompt(dap)
  vim.ui.input({ prompt = "Watch expression: ", scope = "cursor" }, function(expr)
    M.add_expression(dap, expr)
  end)
end

function M.add_from_visual_selection(dap)
  M.add_expression(dap, eval_helpers.visual_selection_text())
end

return M
