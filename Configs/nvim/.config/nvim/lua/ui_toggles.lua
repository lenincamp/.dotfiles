-- UI toggles for statusline/tabline and tabline mode.

local M = {}
local state_file = vim.fn.stdpath("state") .. "/ui_toggles.json"

local function read_state()
  if vim.fn.filereadable(state_file) == 0 then return nil end
  local lines = vim.fn.readfile(state_file)
  if not lines or #lines == 0 then return nil end
  local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok or type(decoded) ~= "table" then return nil end
  return decoded
end

local function write_state(state)
  local ok, encoded = pcall(vim.json.encode, state)
  if not ok or type(encoded) ~= "string" then return end
  vim.fn.mkdir(vim.fn.stdpath("state"), "p")
  vim.fn.writefile({ encoded }, state_file)
end

local function snapshot_state()
  return {
    statusline_enabled = vim.o.laststatus ~= 0,
    tabline_enabled = vim.o.showtabline ~= 0,
    tabline_mode = vim.g.pure_tabline_mode or "tabs",
    winbar_enabled = vim.g.pure_ui_winbar_enabled ~= false,
    saved_winbar = vim.g.pure_ui_saved_winbar,
  }
end

local function notify(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "UI" })
end

local function lualine_refresh()
  local ok, lualine = pcall(require, "lualine")
  if ok and lualine.refresh then
    lualine.refresh({ place = { "statusline", "tabline", "winbar" } })
  end
end

local function each_win(fn)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then fn(win) end
  end
end

function M.statusline_enabled()
  return vim.o.laststatus ~= 0
end

function M.tabline_enabled()
  return vim.o.showtabline ~= 0
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
  vim.o.laststatus = M.statusline_enabled() and 0 or 3
  notify("Statusline " .. (vim.o.laststatus == 0 and "OFF" or "ON"))
  write_state(snapshot_state())
  lualine_refresh()
end

function M.toggle_tabline()
  vim.o.showtabline = M.tabline_enabled() and 0 or 2
  notify("Tabline " .. (vim.o.showtabline == 0 and "OFF" or "ON"))
  write_state(snapshot_state())
  lualine_refresh()
end

function M.cycle_tabline_mode()
  local mode = M.tabline_mode()
  mode = (mode == "tabs") and "buffers" or "tabs"
  vim.g.pure_tabline_mode = mode
  vim.o.showtabline = 2
  notify("Tabline mode: " .. mode)
  write_state(snapshot_state())
  lualine_refresh()
end

function M.toggle_winbar()
  if vim.g.pure_ui_saved_winbar == nil and vim.o.winbar ~= "" then
    vim.g.pure_ui_saved_winbar = vim.o.winbar
  end

  vim.g.pure_ui_winbar_enabled = not M.winbar_enabled()

  notify("Winbar " .. (M.winbar_enabled() and "ON" or "OFF"))
  M.apply_winbar_state()
  write_state(snapshot_state())
end

function M.apply()
  local state = read_state()

  -- Default: start hidden until user decides otherwise.
  vim.o.laststatus = 0
  vim.o.showtabline = 0
  vim.g.pure_tabline_mode = "tabs"

  if vim.g.pure_ui_saved_winbar == nil and vim.o.winbar ~= "" then
    vim.g.pure_ui_saved_winbar = vim.o.winbar
  end
  if vim.g.pure_ui_winbar_enabled == nil then
    vim.g.pure_ui_winbar_enabled = (vim.o.winbar ~= "")
  end

  if type(state) == "table" then
    if type(state.saved_winbar) == "string" then
      vim.g.pure_ui_saved_winbar = state.saved_winbar
    end
    if type(state.tabline_mode) == "string" then
      vim.g.pure_tabline_mode = state.tabline_mode
    end
    if type(state.statusline_enabled) == "boolean" then
      vim.o.laststatus = state.statusline_enabled and 3 or 0
    end
    if type(state.tabline_enabled) == "boolean" then
      vim.o.showtabline = state.tabline_enabled and 2 or 0
    end

    if type(state.winbar_enabled) == "boolean" then
      vim.g.pure_ui_winbar_enabled = state.winbar_enabled
    end
  end

  M.apply_winbar_state()
end

return M
