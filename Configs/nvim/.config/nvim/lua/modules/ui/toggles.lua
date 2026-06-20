local M = {}
local dim = require("modules.ui.toggles.dim")
local runtime = require("modules.core.runtime")

local function notify(message)
  vim.notify(message, vim.log.levels.INFO, { title = "UI" })
end

local function bars_module()
  local ok, bars = pcall(require, "modules.ui.bars")
  if ok then
    return bars
  end
  return nil
end

local function each_window(callback)
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(window) then
      callback(window)
    end
  end
end

local function ensure_defaults()
  if vim.g.pure_ui_statusline_enabled == nil then
    vim.g.pure_ui_statusline_enabled = false
  end
  if vim.g.pure_ui_tabline_enabled == nil then
    vim.g.pure_ui_tabline_enabled = false
  end
  if vim.g.pure_tabline_mode == nil then
    vim.g.pure_tabline_mode = "tabs"
  end
  if vim.g.pure_ui_winbar_enabled == nil then
    vim.g.pure_ui_winbar_enabled = true
  end
end

local function clear_statusline()
  vim.o.statusline = " "
  each_window(function(window)
    vim.wo[window].statusline = " "
  end)
end

local function bool_text(enabled)
  return enabled and "ON" or "OFF"
end

function M.statusline_enabled()
  ensure_defaults()
  return vim.g.pure_ui_statusline_enabled == true
end

function M.tabline_enabled()
  ensure_defaults()
  return vim.g.pure_ui_tabline_enabled == true
end

function M.tabline_mode()
  ensure_defaults()
  return vim.g.pure_tabline_mode
end

function M.winbar_enabled()
  ensure_defaults()
  return vim.g.pure_ui_winbar_enabled == true
end

function M.apply_winbar_state()
  ensure_defaults()
  local bars = bars_module()
  if bars and type(bars.apply_winbar) == "function" then
    bars.apply_winbar(M.winbar_enabled())
    return
  end

  if not M.winbar_enabled() then
    vim.o.winbar = ""
    each_window(function(window)
      vim.wo[window].winbar = ""
    end)
  end
end

function M.apply_bars_state()
  ensure_defaults()

  local bars = bars_module()
  if bars and type(bars.apply) == "function" then
    bars.apply()
  end

  vim.o.laststatus = M.statusline_enabled() and 3 or 0
  vim.o.showtabline = M.tabline_enabled() and 2 or 0

  if not M.statusline_enabled() then
    clear_statusline()
  end

  M.apply_winbar_state()
  vim.cmd("redrawstatus")
end

function M.toggle_statusline()
  ensure_defaults()
  vim.g.pure_ui_statusline_enabled = not M.statusline_enabled()
  M.apply_bars_state()
  require("modules.ui.highlights").apply()
  notify("Statusline " .. (M.statusline_enabled() and "ON" or "OFF"))
end

function M.toggle_tabline()
  ensure_defaults()
  vim.g.pure_ui_tabline_enabled = not M.tabline_enabled()
  M.apply_bars_state()
  notify("Tabline " .. (M.tabline_enabled() and "ON" or "OFF"))
end

function M.cycle_tabline_mode()
  ensure_defaults()
  vim.g.pure_tabline_mode = M.tabline_mode() == "tabs" and "buffers" or "tabs"
  vim.g.pure_ui_tabline_enabled = true
  M.apply_bars_state()
  notify("Tabline mode: " .. M.tabline_mode())
end

function M.toggle_winbar()
  ensure_defaults()
  vim.g.pure_ui_winbar_enabled = not M.winbar_enabled()
  M.apply_winbar_state()
  notify("Winbar " .. bool_text(M.winbar_enabled()))
end

function M.toggle_option(option, label)
  local enabled = not vim.o[option]
  vim.o[option] = enabled
  notify((label or option) .. " " .. bool_text(enabled))
end

function M.toggle_window_option(option, label)
  local enabled = not vim.wo[option]
  vim.wo[option] = enabled
  if option == "relativenumber" and enabled then
    vim.wo.number = true
  elseif option == "number" and not enabled then
    vim.wo.relativenumber = false
  end
  notify((label or option) .. " " .. bool_text(enabled))
end

function M.toggle_diagnostics()
  local enabled = true
  if type(vim.diagnostic.is_enabled) == "function" then
    local ok, result = pcall(vim.diagnostic.is_enabled)
    if ok then
      enabled = result
    end
  end
  vim.diagnostic.enable(not enabled)
  notify("Diagnostics " .. bool_text(not enabled))
end

function M.toggle_treesitter()
  local buffer = vim.api.nvim_get_current_buf()
  local enabled = vim.b[buffer].pure_treesitter_enabled
  if enabled == nil then
    enabled = true
  end

  if enabled then
    pcall(vim.treesitter.stop, buffer)
  else
    pcall(vim.treesitter.start, buffer)
  end

  vim.b[buffer].pure_treesitter_enabled = not enabled
  notify("Treesitter " .. bool_text(not enabled))
end

function M.toggle_dark_background()
  local ok, colors = pcall(require, "modules.theme.colorschemes")
  if not ok then
    return
  end
  local dark = not colors.is_dark_background()
  colors.set_background_mode(dark and "dark" or "light")
  notify("Dark Background " .. bool_text(dark))
end

function M.toggle_transparent_background()
  local ok, colors = pcall(require, "modules.theme.colorschemes")
  if not ok then
    return
  end
  local transparent = not colors.is_transparent()
  colors.set_transparency(transparent)
  notify("Transparent Background " .. bool_text(transparent))
end

function M.toggle_dim()
  vim.g.pure_ui_dim_enabled = not vim.g.pure_ui_dim_enabled
  dim.apply(vim.g.pure_ui_dim_enabled)
  notify("Dim Inactive Windows " .. bool_text(vim.g.pure_ui_dim_enabled))
end

function M.toggle_zoom()
  if vim.t.pure_ui_zoom_tab then
    vim.cmd("tabclose")
    return
  end

  vim.cmd("tab split")
  vim.t.pure_ui_zoom_tab = true
end

function M.toggle_inlay_hints()
  if not vim.lsp.inlay_hint then
    return
  end

  local enabled = false
  if type(vim.lsp.inlay_hint.is_enabled) == "function" then
    local ok, result = pcall(vim.lsp.inlay_hint.is_enabled, { bufnr = 0 })
    enabled = ok and result or false
  end

  pcall(vim.lsp.inlay_hint.enable, not enabled, { bufnr = 0 })
  notify("Inlay Hints " .. bool_text(not enabled))
end

function M.toggle_format_global()
  vim.g.autoformat = vim.g.autoformat ~= true
  require("modules.editor.format").refresh_autoformat_autocmd()
  notify("Format on Save (global) " .. bool_text(vim.g.autoformat == true))
end

function M.toggle_format_buffer()
  if vim.g.autoformat == true then
    vim.b.autoformat = vim.b.autoformat == false and nil or false
    require("modules.editor.format").refresh_autoformat_autocmd()
    notify("Format on Save (buffer) " .. bool_text(vim.b.autoformat ~= false))
    return
  end

  vim.b.autoformat = vim.b.autoformat == true and nil or true
  require("modules.editor.format").refresh_autoformat_autocmd()
  notify("Format on Save (buffer) " .. bool_text(vim.b.autoformat == true))
end

function M.toggle_cmdline_info()
  local enabled = not vim.o.ruler
  vim.o.ruler = enabled
  vim.o.showcmd = enabled
  vim.o.showmode = enabled
  notify("Cmdline Info " .. bool_text(enabled))
end

function M.reload_config()
  local config = vim.fn.stdpath("config")
  for name in pairs(package.loaded) do
    if name == "configs" or name == "plugins" or name == "lsp" or name == "keymaps" or name == "statusline" or name == "autocmds"
      or name == "java" or name:match("^modules%.") or name:match("^lang%.") then
      package.loaded[name] = nil
    end
  end
  dofile(config .. "/init.lua")
  notify("Neovim config reloaded")
end

function M.toggle_intellij_grep()
  local ok, picker = pcall(require, "modules.editor.picker")
  if not ok then
    return
  end
  local enabled = not picker.is_intellij_grep_enabled()
  picker.set_intellij_grep(enabled)
  notify("Grep IntelliJ Layout " .. bool_text(enabled))
end

function M.toggle_treesitter_context()
  runtime.load_config("treesitter-context")
  local ok, context = pcall(require, "treesitter-context")
  if not ok then
    return
  end
  local enabled = not context.enabled()
  if enabled then
    context.enable()
  else
    context.disable()
  end
  notify("Treesitter Context " .. bool_text(enabled))
end

function M.toggle_render_markdown()
  runtime.load_config("render-markdown")
  local ok, render = pcall(require, "render-markdown")
  if not ok then
    return
  end
  local enabled = not render.get()
  render.set(enabled)
  notify("Render Markdown " .. bool_text(enabled))
end

function M.apply()
  ensure_defaults()
  M.apply_bars_state()

  vim.api.nvim_create_autocmd({ "UIEnter", "SessionLoadPost" }, {
    group = vim.api.nvim_create_augroup("pure_ui_bars_apply", { clear = true }),
    callback = M.apply_bars_state,
  })

  dim.configure_autocmd(vim.g.pure_ui_dim_enabled == true)
end

return M
