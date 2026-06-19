local M = {}

function M.detect_mode()
  if vim.fn.executable("defaults") == 1 then
    local output = vim.fn.system({ "defaults", "read", "-g", "AppleInterfaceStyle" })
    if vim.v.shell_error == 0 then
      output = vim.trim((output or ""):lower())
      if output:find("dark", 1, true) then return "dark" end
      return "light"
    end
    return "light"
  end

  if vim.fn.executable("osascript") ~= 1 then return nil end
  local script = 'tell application "System Events" to tell appearance preferences to return dark mode'
  local output = vim.fn.system({ "osascript", "-e", script })
  if vim.v.shell_error ~= 0 then return nil end

  output = vim.trim((output or ""):lower())
  if output == "true" then return "dark" end
  if output == "false" then return "light" end
  return nil
end

function M.sync(opts, callbacks)
  opts = opts or {}
  if vim.g._pure_applying_colorscheme then return false end

  local wanted = M.detect_mode()
  if wanted == nil then return false end

  local previous_system = vim.g._pure_system_mode_last
  if opts.force ~= true and wanted == previous_system then
    return false
  end

  vim.g._pure_system_mode_last = wanted

  local current = callbacks.resolve(vim.g.pure_colorscheme or vim.g.colors_name or callbacks.default)
  local current_mode = (((current.opts and current.opts.background) or vim.o.background or "dark") == "light") and "light" or "dark"

  if current_mode == wanted then return false end

  if opts.force ~= true and previous_system ~= nil and current_mode ~= previous_system then
    return false
  end

  return callbacks.set_background_mode(wanted, { sync_external = "defer" })
end

function M.start_watcher(owner, sync_callback)
  if owner._system_theme_timer then return end
  if vim.g.pure_system_theme_auto == false then return end

  local uv = vim.uv
  if not uv or not uv.new_timer then return end

  local interval = tonumber(vim.g.pure_system_theme_poll_ms) or 8000
  if interval <= 0 then return end
  if interval < 1000 then interval = 1000 end

  local timer = uv.new_timer()
  if not timer then return end

  timer:start(interval, interval, vim.schedule_wrap(function()
    pcall(sync_callback)
  end))

  owner._system_theme_timer = timer
end

function M.stop_watcher(owner)
  local timer = owner._system_theme_timer
  if not timer then return end
  pcall(function()
    timer:stop()
    timer:close()
  end)
  owner._system_theme_timer = nil
end

return M
