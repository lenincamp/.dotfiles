local M = {}

local loaded_theme_packs = {}

function M.set_theme_globals(theme, extension)
  local opts = (theme and theme.opts) or {}
  vim.g.pure_catppuccin_flavour = opts.flavour or "mocha"
  vim.g.pure_gruvbox_contrast = opts.contrast or "hard"
  vim.g.pure_tokyonight_style = opts.style or "moon"
  vim.g.pure_solarized_osaka_style = opts.style or "night"
  vim.g.pure_kanagawa_theme = opts.theme or "wave"
  vim.g.pure_rose_pine_variant = opts.variant or "moon"
  if extension and type(extension.apply_theme_globals) == "function" then
    extension.apply_theme_globals(opts)
  end
end

function M.ensure_pack_loaded(plugin, theme_plugin_pack)
  local pack_name = theme_plugin_pack[plugin]
  if not pack_name or loaded_theme_packs[pack_name] then
    return true
  end

  local ok, err = pcall(vim.cmd.packadd, pack_name)
  if not ok then
    vim.notify("Theme pack load failed [" .. pack_name .. "]: " .. tostring(err), vim.log.levels.WARN)
    return false
  end

  loaded_theme_packs[pack_name] = true
  return true
end

function M.reload_plugin(plugin, opts)
  opts = opts or {}
  if not plugin then return end
  if not M.ensure_pack_loaded(plugin, opts.theme_plugin_pack or {}) then
    return
  end

  local path = opts.runtime.resolve_plugin_config(plugin)
  if not path then
    path = vim.fn.stdpath("config") .. "/plugins/" .. plugin .. ".lua"
  end

  if vim.fn.filereadable(path) == 1 then pcall(dofile, path) end
end

return M
