-- Startup orchestrator.
-- Wires pack commands, resolves installed opt packages on demand,
-- and loads plugin runtime/config only when needed by event, command, or keymap.

local packs = require("packs")
local registry = require("modules.plugins.registry")
local runtime = require("modules.core.runtime")

local pack_dir = registry.pack_dir
local conf_dir = registry.config_dir
local resolved_config_paths = {}

local function resolve_config_path(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  local cached = resolved_config_paths[name]
  if cached ~= nil then
    return cached or nil
  end

  local spec = registry.configs[name]
  if spec and type(spec.path) == "string" then
    local path = conf_dir .. "/" .. spec.path
    if vim.fn.filereadable(path) == 1 then
      resolved_config_paths[name] = path
      return path
    end
  end

  resolved_config_paths[name] = false
  return nil
end

-- Pack management commands (:PackInstall, :PackUpdate, ...)
require("pack_manager").setup(packs, pack_dir)

-- Fallback: reuse LSP servers installed in the main nvim instance.
local main_mason_bin = vim.fn.expand("~/.local/share/nvim/mason/bin")
if vim.fn.isdirectory(main_mason_bin) == 1 and not vim.env.PATH:find(main_mason_bin, 1, true) then
  vim.env.PATH = main_mason_bin .. ":" .. vim.env.PATH
end

local loaded_configs = {}
local loaded_packs = {}
local mason_lazy_commands = registry.mason_lazy_commands
local diff_blocked_configs = registry.diff_blocked_configs

-- During `nvim -d ...`, FileType events can fire before `vim.opt.diff` settles.
-- Keep DAP configs blocked during this startup window to preserve diff-mode policy.
local startup_diff_pending = false
for _, arg in ipairs(vim.v.argv or {}) do
  if arg == "-d" then
    startup_diff_pending = true
    break
  end
end

if startup_diff_pending then
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("PureDiffStartupWindow", { clear = true }),
    once = true,
    callback = function()
      startup_diff_pending = false
    end,
  })
end

local function load_pack(name)
  if type(name) ~= "string" or name == "" then
    return true
  end

  if loaded_packs[name] then
    return true
  end

  local ok, err = pcall(vim.cmd.packadd, name)
  if not ok then
    vim.notify("Pack load failed [" .. name .. "]: " .. tostring(err), vim.log.levels.WARN)
    return false
  end

  loaded_packs[name] = true
  return true
end

local function load_packs_for_config(name)
  local spec = registry.configs[name]
  local target = spec and spec.packs or nil
  if not target then
    return true
  end

  if type(target) == "string" then
    return load_pack(target)
  end

  if type(target) ~= "table" then
    return true
  end

  for _, pack_name in ipairs(target) do
    if not load_pack(pack_name) then
      return false
    end
  end

  return true
end

local function is_diff_context_active()
  return startup_diff_pending or vim.opt.diff:get()
end

local function should_skip_config(name)
  if not diff_blocked_configs[name] then
    return false
  end

  return is_diff_context_active()
end

local function load_cfg(name)
  if name == "mason" then
    for _, cmd_name in ipairs(mason_lazy_commands) do
      pcall(vim.api.nvim_del_user_command, cmd_name)
    end
  end

  if should_skip_config(name) then
    return false
  end

  if not load_packs_for_config(name) then
    return false
  end

  local path = resolve_config_path(name)
  if not path then
    return false
  end

  local ok, result = pcall(dofile, path)
  if not ok then
    vim.notify("Plugin config error [" .. name .. "]: " .. tostring(result), vim.log.levels.WARN)
    return false
  end

  -- Config scripts may return false to indicate deferred setup (e.g. async build).
  if result == false then
    return false
  end

  return true
end

local function load_cfg_once(name)
  if loaded_configs[name] then
    return true
  end

  local ok = load_cfg(name)
  if ok then
    loaded_configs[name] = true
  end
  return ok
end

runtime.set_loader_api({
  load_config = load_cfg_once,
  load_pack = load_pack,
  resolve_config_path = resolve_config_path,
})

pcall(function()
  require("modules.dap.signs").setup()
end)

if not is_diff_context_active() then
  load_cfg_once("nvim-treesitter")
end

local function active_theme_config_name()
  local ok_colors, colors = pcall(require, "modules.theme.colorschemes")
  if not ok_colors or type(colors.resolve) ~= "function" then
    return nil
  end

  local theme = colors.resolve(vim.g.pure_colorscheme or colors.default)
  if type(theme) == "table" and type(theme.plugin) == "string" and theme.plugin ~= "" then
    return theme.plugin
  end

  return nil
end

local function ensure_theme_runtime()
  local ok_colors, colors = pcall(require, "modules.theme.colorschemes")
  if not ok_colors then
    return
  end

  if type(colors.setup_autocmd) == "function" then
    colors.setup_autocmd()
  end

  if type(colors.apply) ~= "function" then
    return
  end

  local target = colors.resolve(vim.g.pure_colorscheme or colors.default)
  colors.apply(target, { notify = false, sync_external = "defer" })
end

local theme_cfg = active_theme_config_name()
if theme_cfg then
  load_cfg_once(theme_cfg)
end

ensure_theme_runtime()

local function setup_native_startup_modules()
  local native_modules = {
    { module = "modules.ui.bars", method = "setup" },
    { module = "modules.ui.dashboard", method = "setup" },
    { module = "modules.editor.search_keymaps", method = "setup" },
    { module = "modules.editor.sessions", method = "setup" },
  }

  for _, item in ipairs(native_modules) do
    local ok, mod = pcall(require, item.module)
    if ok and type(mod[item.method]) == "function" then
      mod[item.method]()
    end
  end
end

setup_native_startup_modules()

require("modules.plugins.events").setup(load_cfg_once)

local ok_lazy_keymaps, lazy_keymaps = pcall(require, "modules.editor.lazy_keymaps")
if ok_lazy_keymaps then
  lazy_keymaps.setup(load_cfg_once)
end

local ok_warmup, warmup = pcall(require, "modules.editor.warmup")
if ok_warmup then
  warmup.setup(load_cfg_once)
end

require("modules.plugins.commands").setup(registry, load_cfg_once)

local ok_avante_lazy, avante_lazy = pcall(require, "modules.integrations.avante_lazy")
if ok_avante_lazy then
  avante_lazy.setup(load_cfg_once)
end
