local M = {}
local runtime = require("modules.core.runtime")
local catalog = require("modules.theme.catalog")
local commands = require("modules.theme.colorschemes.commands")
local theme_model = require("modules.theme.colorschemes.model")
local theme_runtime = require("modules.theme.colorschemes.runtime")
local state_store = require("modules.theme.colorschemes.state")
local system_background = require("modules.theme.colorschemes.system_background")
local transparency = require("modules.theme.colorschemes.transparency")
local external_sync = require("modules.theme.external_sync")
local tool_sync = require("modules.theme.tool_sync")

local cyberdream_custom = catalog.extension

M.default = catalog.default

local state_file = vim.fn.stdpath("state") .. "/colorscheme.json"

M.themes = catalog.themes

local aliases = catalog.aliases
local transparent_groups = catalog.transparent_groups

M._theme_map = {}
for _, item in ipairs(M.themes) do
  M._theme_map[item.key] = item
end

local persisted_state = state_store.load(state_file, aliases, M._theme_map)
if persisted_state and persisted_state.key then
  M.default = persisted_state.key
end

if vim.g.transparent_background == nil and persisted_state and type(persisted_state.transparent) == "boolean" then
  vim.g.transparent_background = persisted_state.transparent
end

if vim.g.transparent_background == nil then
  vim.g.transparent_background = true
end

if type(vim.g.pure_colorscheme) ~= "string" or vim.g.pure_colorscheme == "" then
  vim.g.pure_colorscheme = M.default
end

M._last_dark_by_family = {}

local sync_profile_by_key = catalog.sync_profile_by_key
local tmux_theme_by_scheme = catalog.tmux_theme_by_scheme

local function sync_profile(item)
  return sync_profile_by_key[item.key] or {}
end

local function current_theme(theme)
  return M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
end

local function theme_mode(item, fallback)
  return (item.opts and item.opts.background) or fallback or "dark"
end

function M.theme_profile(theme)
  local item = current_theme(theme)
  local profile = sync_profile(item)
  return {
    key = item.key,
    scheme = item.scheme,
    plugin = item.plugin,
    tmux = profile.tmux,
    lualine = profile.lualine,
    delta = profile.delta,
    lazygit = profile.lazygit,
    iterm2 = profile.iterm2,
    terminal = profile.terminal,
  }
end

local function resolve_theme_for_external_sync(theme)
  local item = current_theme(theme)
  local item_mode = theme_mode(item, vim.o.background)
  local current_mode = vim.o.background or item_mode

  if item_mode ~= current_mode and type(vim.g.colors_name) == "string" and vim.g.colors_name ~= "" then
    local active_item = M.resolve(vim.g.colors_name)
    local active_mode = theme_mode(active_item, current_mode)
    if active_mode == current_mode then
      return active_item
    end
  end

  return item
end

tool_sync.setup({
  current_theme = current_theme,
  resolve_external_theme = resolve_theme_for_external_sync,
  sync_profile = sync_profile,
  theme_mode = theme_mode,
  tmux_theme_by_scheme = tmux_theme_by_scheme,
})

function M.request_external_sync(theme)
  local resolved = current_theme(theme)
  local immediate = (#vim.api.nvim_list_uis() == 0) and tool_sync.sync_tmux_theme or tool_sync.sync_tmux_theme_async
  external_sync.request(resolved, {
    immediate = immediate,
    runner = tool_sync.sync_external_tools,
    headless_inline = true,
  })
end

function M.lualine_theme(theme)
  local item = current_theme(theme)
  local profile = sync_profile(item)
  local lualine_profile = profile.lualine or { provider = "auto" }

  if lualine_profile.provider == "catppuccin" then
    local ok, cat_lualine = pcall(require, "catppuccin.utils.lualine")
    if ok and type(cat_lualine) == "function" then
      return cat_lualine(lualine_profile.flavour or "mocha")
    end
    return "auto"
  end

  if lualine_profile.provider == "builtin" and type(lualine_profile.name) == "string" then
    local ok = pcall(require, "lualine.themes." .. lualine_profile.name)
    if ok then return lualine_profile.name end
  end

  return "auto"
end

function M.is_transparent()
  return transparency.is_enabled()
end

function M.is_transparency_effective()
  return transparency.is_effective()
end

function M.apply_transparency()
  transparency.apply(transparent_groups)
end

function M.sync_with_system_background(opts)
  return system_background.sync(opts, {
    default = M.default,
    resolve = M.resolve,
    set_background_mode = M.set_background_mode,
  })
end

function M.setup_autocmd()
  if M._autocmd_ready then return end
  M._autocmd_ready = true

  local group = vim.api.nvim_create_augroup("PureTransparentColors", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if vim.g._pure_applying_colorscheme or vim.g._pure_vim_leaving then return end
      M.apply_transparency()
      M.request_external_sync(vim.g.pure_colorscheme or vim.g.colors_name)
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
    group = group,
    callback = function()
      M.sync_with_system_background()
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      system_background.stop_watcher(M)
      -- Prevent ColorScheme autocmd from syncing during exit (causes theme revert)
      vim.g._pure_vim_leaving = true
    end,
  })

  commands.setup({
    default = M.default,
    themes = M.themes,
    tool_sync = tool_sync,
  })

  system_background.start_watcher(M, M.sync_with_system_background)
  vim.schedule(function()
    M.sync_with_system_background({ force = true })
  end)
end

local theme_plugin_pack = catalog.theme_plugin_pack

function M.options()
  local picker_priority = (cyberdream_custom and cyberdream_custom.picker_priority) or {}
  return theme_model.options(M.themes, picker_priority)
end

function M.resolve(theme)
  local picker_priority = (cyberdream_custom and cyberdream_custom.picker_priority) or {}
  return theme_model.resolve(theme, {
    aliases = aliases,
    default = M.default,
    picker_priority = picker_priority,
    theme_map = M._theme_map,
    themes = M.themes,
  })
end

function M.is_dark_background()
  return vim.o.background == "dark"
end

function M.set_background_mode(mode, apply_opts)
  local current = M.resolve(vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local current_mode = ((current.opts and current.opts.background) or "dark")

  -- Builtin themes like default/unokai/habamax are intentionally dark-only.
  if current.fixed_background and mode ~= current_mode then
    return false
  end

  local target = theme_model.find_family_variant(M.themes, M._last_dark_by_family, current, mode)

  if target then
    return M.apply(target, apply_opts)
  end

  local fallback = {
    key = current.key .. "-" .. mode,
    label = current.label,
    scheme = current.scheme,
    plugin = current.plugin,
    opts = vim.tbl_extend("force", {}, current.opts or {}, { background = mode }),
  }
  return M.apply(fallback, apply_opts)
end

function M.toggle_background()
  if M.is_dark_background() then
    return M.set_background_mode("light")
  end
  return M.set_background_mode("dark")
end

function M.apply(theme, opts)
  opts = opts or {}
  if vim.g._pure_applying_colorscheme then return false end

  local item = M.resolve(theme)
  local previous_key = vim.g.pure_colorscheme
  local item_bg = (item.opts and item.opts.background) or "dark"
  local transparency_pref = M.is_transparent()
  vim.g._pure_applying_colorscheme = true
  theme_runtime.set_theme_globals(item, cyberdream_custom)
  -- Must be set before :colorscheme so ColorScheme autocmd consumers
  -- (e.g. lualine) resolve the new profile on first pass.
  vim.g.pure_colorscheme = item.key
  vim.o.background = item_bg

  local reload_key = table.concat({
    item.plugin or "",
    vim.json.encode(item.opts or {}),
    tostring(transparency_pref),
  }, "|")
  if vim.g._pure_theme_reload_key ~= reload_key then
    theme_runtime.reload_plugin(item.plugin, {
      runtime = runtime,
      theme_plugin_pack = theme_plugin_pack,
    })
    vim.g._pure_theme_reload_key = reload_key
  end

  local ok, err = pcall(vim.cmd.colorscheme, item.scheme)
  if not ok then
    vim.g.pure_colorscheme = previous_key
    vim.g.transparent_background = transparency_pref
    vim.g._pure_applying_colorscheme = false
    vim.notify("Colorscheme failed [" .. item.scheme .. "]: " .. tostring(err), vim.log.levels.WARN)
    return false
  end

  -- Keep user toggle state even if a colorscheme/plugin mutates globals.
  vim.g.transparent_background = transparency_pref

  if item_bg == "dark" then
    M._last_dark_by_family[theme_model.family_key(item)] = item.key
  end
  M.apply_transparency()
  state_store.persist(state_file, item.key, transparency_pref)
  if opts.sync_external == "defer" then
    local delay = tonumber(opts.sync_external_delay_ms) or 50
    vim.defer_fn(function()
      M.request_external_sync(item)
    end, math.max(delay, 0))
  elseif opts.sync_external ~= false then
    M.request_external_sync(item)
  end

  if opts.notify ~= false then
    vim.notify("Colorscheme: " .. item.label, vim.log.levels.INFO)
  end

  vim.g._pure_applying_colorscheme = false
  return true
end

function M.select()
  require("modules.editor.picker").select_items(M.options(), {
    prompt = "Colorscheme (High Contrast)",
    scope = "global",
    search_threshold = 0,
    format_item = function(item)
      if item.source == "header" then return item.label end
      return "★ " .. item.label
    end,
  }, function(item)
    if item and item.source ~= "header" then M.apply(item) end
  end)
end

function M.set_transparency(state)
  vim.g.transparent_background = state == true
  M.apply(vim.g.pure_colorscheme or M.default)
end

return M