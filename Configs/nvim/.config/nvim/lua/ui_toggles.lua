-- UI toggles for statusline/tabline and tabline mode.

local M = {}

local function notify(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "UI" })
end

local function lualine_refresh()
  local ok, lualine = pcall(require, "lualine")
  if ok and lualine.refresh then
    lualine.refresh({ place = { "statusline", "tabline", "winbar" } })
  end
end

local function lualine_set_statusline_visible(enable)
  local ok, lualine = pcall(require, "lualine")
  if ok and type(lualine.hide) == "function" then
    pcall(lualine.hide, { place = { "statusline" }, unhide = enable })
  end
end

local function lualine_set_tabline_visible(enable)
  local ok, lualine = pcall(require, "lualine")
  if ok and type(lualine.hide) == "function" then
    pcall(lualine.hide, { place = { "tabline" }, unhide = enable })
  end
end

local function statusline_enabled_target()
  if vim.g.pure_ui_statusline_enabled == nil then
    vim.g.pure_ui_statusline_enabled = (vim.o.laststatus ~= 0)
  end
  return vim.g.pure_ui_statusline_enabled
end

local function tabline_enabled_target()
  if vim.g.pure_ui_tabline_enabled == nil then
    vim.g.pure_ui_tabline_enabled = (vim.o.showtabline ~= 0)
  end
  return vim.g.pure_ui_tabline_enabled
end

local function each_win(fn)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then fn(win) end
  end
end

local function enforce_statusline_off()
  if M.statusline_enabled() then return end

  -- Keep global statusline hard-disabled even if plugin UIs try to re-enable it.
  vim.o.laststatus = 0
  vim.o.statusline = " "

  -- Some plugin windows set a local statusline; blank them as well.
  each_win(function(win)
    vim.wo[win].statusline = " "
  end)
end

local function enforce_tabline_off()
  if M.tabline_enabled() then return end
  vim.o.showtabline = 0
end

local statusline_guard_busy = false

local function enforce_statusline_off_for_laststatus_change()
  if statusline_guard_busy then return end
  if M.statusline_enabled() then return end

  statusline_guard_busy = true
  if vim.o.laststatus ~= 0 then
    vim.o.laststatus = 0
  end

  if vim.o.statusline ~= " " then
    vim.o.statusline = " "
  end

  statusline_guard_busy = false
end

function M.statusline_enabled()
  return statusline_enabled_target()
end

function M.tabline_enabled()
  return tabline_enabled_target()
end

function M.tabline_mode()
  return vim.g.pure_tabline_mode or "tabs"
end

function M.winbar_enabled()
  if vim.g.pure_ui_winbar_enabled == nil then
    vim.g.pure_ui_winbar_enabled = (vim.o.winbar ~= "")
  end
  return vim.g.pure_ui_winbar_enabled
end

function M.apply_winbar_state()
  local enable = M.winbar_enabled()
  if type(_G.PureLualineApply) == "function" then
    _G.PureLualineApply()
    lualine_refresh()
    return
  end

  local ok, lualine = pcall(require, "lualine")
  if ok and type(lualine.hide) == "function" then
    pcall(lualine.hide, { place = { "winbar" }, unhide = enable })
  end

  -- Fallback for setups where lualine.hide is unavailable.
  if not enable then
    vim.o.winbar = ""
    each_win(function(win)
      vim.wo[win].winbar = ""
    end)
  elseif type(vim.g.pure_ui_saved_winbar) == "string" and vim.g.pure_ui_saved_winbar ~= "" then
    vim.o.winbar = vim.g.pure_ui_saved_winbar
    each_win(function(win)
      vim.wo[win].winbar = vim.g.pure_ui_saved_winbar
    end)
  end

  lualine_refresh()
end

function M.toggle_statusline()
  local enable = not M.statusline_enabled()
  vim.g.pure_ui_statusline_enabled = enable

  -- statusline.lua sets a blank fallback statusline; restore lualine when enabling.
  if enable and type(_G.PureLualineApply) == "function" then
    _G.PureLualineApply()
  else
    M.apply_bars_state()
    enforce_statusline_off()
  end

  notify("Statusline " .. (vim.o.laststatus == 0 and "OFF" or "ON"))
  lualine_refresh()
end

function M.toggle_tabline()
  vim.g.pure_ui_tabline_enabled = not M.tabline_enabled()
  M.apply_bars_state()
  notify("Tabline " .. (vim.o.showtabline == 0 and "OFF" or "ON"))
  lualine_refresh()
end

function M.cycle_tabline_mode()
  local mode = M.tabline_mode()
  mode = (mode == "tabs") and "buffers" or "tabs"
  vim.g.pure_tabline_mode = mode
  vim.g.pure_ui_tabline_enabled = true
  M.apply_bars_state()
  notify("Tabline mode: " .. mode)
  lualine_refresh()
end

function M.apply_bars_state()
  local statusline_on = M.statusline_enabled()
  vim.o.laststatus = statusline_on and 3 or 0
  vim.o.showtabline = M.tabline_enabled() and 2 or 0
  lualine_set_statusline_visible(statusline_on)
  lualine_set_tabline_visible(M.tabline_enabled())

  if not statusline_on then
    enforce_statusline_off_for_laststatus_change()
    enforce_statusline_off()
  end

  if not M.tabline_enabled() then
    enforce_tabline_off()
  end
end

function M.toggle_winbar()
  if vim.g.pure_ui_saved_winbar == nil and vim.o.winbar ~= "" then
    vim.g.pure_ui_saved_winbar = vim.o.winbar
  end

  vim.g.pure_ui_winbar_enabled = not M.winbar_enabled()

  notify("Winbar " .. (M.winbar_enabled() and "ON" or "OFF"))
  M.apply_winbar_state()
end

function M.apply()
  -- Always-default startup UI: winbar ON, statusline OFF, tabline OFF.
  vim.g.pure_ui_statusline_enabled = false
  vim.g.pure_ui_tabline_enabled = false
  vim.g.pure_tabline_mode = "tabs"
  vim.g.pure_ui_winbar_enabled = true

  if vim.g.pure_ui_saved_winbar == nil and vim.o.winbar ~= "" then
    vim.g.pure_ui_saved_winbar = vim.o.winbar
  end

  M.apply_bars_state()
  enforce_statusline_off()
  M.apply_winbar_state()

  -- Enforce desired startup state after late plugin/session hooks.
  vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter", "SessionLoadPost" }, {
    group = vim.api.nvim_create_augroup("pure_ui_enforce_startup", { clear = true }),
    callback = function()
      M.apply_bars_state()
      M.apply_winbar_state()
    end,
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = vim.api.nvim_create_augroup("pure_ui_bars_guard", { clear = true }),
    pattern = { "laststatus", "statusline", "showtabline" },
    callback = function()
      enforce_statusline_off_for_laststatus_change()
      enforce_tabline_off()
    end,
  })

end

return M
