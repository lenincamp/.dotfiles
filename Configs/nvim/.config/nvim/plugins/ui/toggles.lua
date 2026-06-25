-- Editor toggles: delegates to pure-ui, colorscheme-sync, picker, and config modules.

local M = {}
local lazy_bootstrap = require("modules.bootstrap.lazy")
local chrome = require("pure-ui.chrome")
local dim = require("pure-ui.dim")

local function notify(message)
  vim.notify(message, vim.log.levels.INFO, { title = "UI" })
end

local function bool_text(enabled)
  return enabled and "ON" or "OFF"
end

function M.toggle_statusline()
  chrome.toggle_statusline()
  notify("Statusline " .. bool_text(chrome.statusline_enabled()))
end

function M.toggle_tabline()
  chrome.toggle_tabline()
  notify("Tabline " .. bool_text(chrome.tabline_enabled()))
end

function M.cycle_tabline_mode()
  chrome.cycle_tabline_mode()
  notify("Tabline mode: " .. chrome.tabline_mode())
end

function M.toggle_winbar()
  chrome.toggle_winbar()
  notify("Winbar " .. bool_text(chrome.winbar_enabled()))
end

function M.statusline_enabled()
  return chrome.statusline_enabled()
end

function M.tabline_enabled()
  return chrome.tabline_enabled()
end

function M.tabline_mode()
  return chrome.tabline_mode()
end

function M.winbar_enabled()
  return chrome.winbar_enabled()
end

function M.apply_bars_state()
  chrome.apply_bars_state()
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
  local ok, csync = pcall(require, "colorscheme-sync")
  if not ok then
    return
  end
  local dark = csync.toggle_dark_background()
  notify("Dark Background " .. bool_text(dark))
end

function M.toggle_transparent_background()
  local ok, csync = pcall(require, "colorscheme-sync")
  if not ok then
    return
  end
  local transparent = csync.toggle_transparent_background()
  notify("Transparent Background " .. bool_text(transparent))
end

function M.toggle_dim()
  local enabled = dim.toggle()
  notify("Dim Inactive Windows " .. bool_text(enabled))
end

function M.toggle_zoom()
  if vim.t.pure_ui_zoom_tab then
    vim.cmd("tabclose!")
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
    if
      name == "configs"
      or name == "plugins"
      or name == "lsp"
      or name == "keymaps"
      or name == "statusline"
      or name == "autocmds"
      or name == "java"
      or name:match("^modules%.")
      or name:match("^lang%.")
      or name:match("^config%.")
      or name:match("^pure%-ui")
      or name:match("^picker")
      or name:match("^colorscheme%-sync")
    then
      package.loaded[name] = nil
    end
  end
  dofile(config .. "/init.lua")
  notify("Neovim config reloaded")
end

function M.toggle_intellij_grep()
  local ok, picker = pcall(require, "picker")
  if not ok then
    return
  end
  local enabled = picker.toggle_intellij_grep()
  notify("Grep IntelliJ Layout " .. bool_text(enabled))
end

function M.toggle_treesitter_context()
  lazy_bootstrap.load("nvim-treesitter-context")
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
  lazy_bootstrap.load("render-markdown.nvim")
  local ok, render = pcall(require, "render-markdown")
  if not ok then
    return
  end
  local enabled = not render.get()
  render.set(enabled)
  notify("Render Markdown " .. bool_text(enabled))
end

function M.toggle_zen_mode()
  lazy_bootstrap.load("no-neck-pain.nvim")
  local ok, zen = pcall(require, "no-neck-pain")
  if not ok then
    vim.notify("no-neck-pain is not available", vim.log.levels.WARN)
    return
  end
  zen.toggle()
end

return M
