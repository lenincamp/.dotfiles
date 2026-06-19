local M = {}

function M.show_session(dap)
  dap.session()
end

function M.hover_widget(widgets)
  widgets.hover()
end

function M.open_repl_view(dap)
  local ok_dv, dap_view = pcall(require, "dap-view")
  if ok_dv then
    dap_view.open()
    dap_view.show_view("repl")
    return
  end
  dap.repl.toggle()
end

function M.toggle_dap_view(runtime, action)
  if not package.loaded["dap-view"] then
    runtime.load_config("nvim-dap-view")
  end

  local ok_dv, dap_view = pcall(require, "dap-view")
  if not ok_dv then return end
  dap_view[action or "toggle"]()
  if action == "open" then dap_view.show_view("scopes") end
end

return M
