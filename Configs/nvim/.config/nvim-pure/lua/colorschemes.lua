local M = {}

M.default = "catppuccin-mocha"

M.themes = {
  { key = "catppuccin-mocha", label = "Catppuccin Mocha", scheme = "catppuccin", plugin = "catppuccin", opts = { flavour = "mocha", background = "dark" } },
  { key = "catppuccin-latte", label = "Catppuccin Latte", scheme = "catppuccin", plugin = "catppuccin", opts = { flavour = "latte", background = "light" } },

  { key = "gruvbox-hard", label = "Gruvbox Hard", scheme = "gruvbox", plugin = "gruvbox", opts = { contrast = "hard", background = "dark" } },
  { key = "gruvbox-light", label = "Gruvbox Light", scheme = "gruvbox", plugin = "gruvbox", opts = { contrast = "soft", background = "light" } },

  { key = "tokyonight-night", label = "TokyoNight Night", scheme = "tokyonight", plugin = "tokyonight", opts = { style = "night", background = "dark" } },
  { key = "tokyonight-day", label = "TokyoNight Day", scheme = "tokyonight", plugin = "tokyonight", opts = { style = "day", background = "light" } },

  { key = "solarized-osaka-night", label = "Solarized Osaka Night", scheme = "solarized-osaka", plugin = "solarized-osaka", opts = { style = "night", background = "dark" } },
  { key = "solarized-osaka-day", label = "Solarized Osaka Day", scheme = "solarized-osaka", plugin = "solarized-osaka", opts = { style = "day", background = "light" } },

  { key = "kanagawa-dragon", label = "Kanagawa Dragon", scheme = "kanagawa-dragon", plugin = "kanagawa", opts = { theme = "dragon", background = "dark" } },
  { key = "kanagawa-lotus", label = "Kanagawa Lotus", scheme = "kanagawa-lotus", plugin = "kanagawa", opts = { theme = "lotus", background = "light" } },

  { key = "rose-pine-moon", label = "Rose Pine Moon", scheme = "rose-pine", plugin = "rose-pine", opts = { variant = "moon", background = "dark" } },
  { key = "rose-pine-dawn", label = "Rose Pine Dawn", scheme = "rose-pine", plugin = "rose-pine", opts = { variant = "dawn", background = "light" } },
}

local aliases = {
  catppuccin = "catppuccin-mocha",
  gruvbox = "gruvbox-hard",
  tokyonight = "tokyonight-moon",
  ["solarized-osaka"] = "solarized-osaka-night",
  kanagawa = "kanagawa-wave",
  ["rose-pine"] = "rose-pine-moon",
}

local transparent_groups = {
  "Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle",
  "SignColumn", "FoldColumn", "LineNr", "CursorLineNr", "StatusLine",
  "StatusLineNC", "TabLine", "TabLineFill", "WinBar", "WinBarNC",
  "WinSeparator", "Pmenu", "PmenuBorder", "TelescopeNormal", "TelescopeBorder",
  "SnacksPicker", "SnacksPickerBorder", "SnacksPickerInput", "SnacksPickerInputBorder",
  "SnacksNotifierInfo", "SnacksNotifierWarn", "SnacksNotifierError",
}

M._theme_map = {}
for _, item in ipairs(M.themes) do
  M._theme_map[item.key] = item
end

M._last_dark_by_family = {}

function M.is_transparent()
  if vim.g.transparent_background == nil then vim.g.transparent_background = true end
  return vim.g.transparent_background == true
end

function M.is_transparency_effective()
  return M.is_transparent()
end

function M.apply_transparency()
  if not M.is_transparent() then return end

  for _, group in ipairs(transparent_groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok then
      hl.bg = nil
      hl.ctermbg = nil
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

function M.setup_autocmd()
  if M._autocmd_ready then return end
  M._autocmd_ready = true

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("PureTransparentColors", { clear = true }),
    callback = function()
      M.apply_transparency()
    end,
  })
end

local function set_theme_globals(theme)
  local opts = (theme and theme.opts) or {}
  vim.g.pure_catppuccin_flavour = opts.flavour or "mocha"
  vim.g.pure_gruvbox_contrast = opts.contrast or "hard"
  vim.g.pure_tokyonight_style = opts.style or "moon"
  vim.g.pure_solarized_osaka_style = opts.style or "night"
  vim.g.pure_kanagawa_theme = opts.theme or "wave"
  vim.g.pure_rose_pine_variant = opts.variant or "moon"
end

local function reload_theme_plugin(plugin)
  if not plugin then return end
  local path = vim.fn.stdpath("config") .. "/plugins/" .. plugin .. ".lua"
  if vim.fn.filereadable(path) == 1 then pcall(dofile, path) end
end

function M.options()
  local dark_items = {}
  local light_items = {}

  for _, theme in ipairs(M.themes) do
    local item = vim.tbl_extend("force", {}, theme, { source = "favorite" })
    if (theme.opts and theme.opts.background) == "light" then
      table.insert(light_items, item)
    else
      table.insert(dark_items, item)
    end
  end

  table.sort(dark_items, function(a, b)
    return a.label < b.label
  end)

  table.sort(light_items, function(a, b)
    return a.label < b.label
  end)

  local items = {}
  table.insert(items, { key = "_header_dark", label = "──────── High Contrast Dark ────────", source = "header" })
  vim.list_extend(items, dark_items)
  table.insert(items, { key = "_header_light", label = "──────── High Contrast Light ───────", source = "header" })
  vim.list_extend(items, light_items)

  return items
end

function M.resolve(theme)
  if type(theme) == "table" then return theme end

  local key = aliases[theme] or theme or M.default
  if M._theme_map[key] then return M._theme_map[key] end

  for _, item in ipairs(M.options()) do
    if item.key == key or item.scheme == key then return item end
  end

  return M._theme_map[M.default]
end

local function family_key(item)
  return item.plugin or ("builtin:" .. item.scheme)
end

function M.is_dark_background()
  return vim.o.background == "dark"
end

local function find_family_variant(item, mode)
  local family = family_key(item)
  local wanted = mode == "light" and "light" or "dark"
  local options = {}

  for _, t in ipairs(M.themes) do
    if family_key(t) == family and ((t.opts and t.opts.background) or "dark") == wanted then
      table.insert(options, t)
    end
  end

  if #options == 0 then return nil end

  if wanted == "dark" then
    local remembered = M._last_dark_by_family[family]
    if remembered then
      for _, t in ipairs(options) do
        if t.key == remembered then return t end
      end
    end
  end

  return options[1]
end

function M.set_background_mode(mode)
  local current = M.resolve(vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local target = find_family_variant(current, mode)

  if target then
    return M.apply(target)
  end

  local fallback = {
    key = current.key .. "-" .. mode,
    label = current.label,
    scheme = current.scheme,
    plugin = current.plugin,
    opts = vim.tbl_extend("force", {}, current.opts or {}, { background = mode }),
  }
  return M.apply(fallback)
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
  local item_bg = (item.opts and item.opts.background) or "dark"
  local transparency_pref = M.is_transparent()
  vim.g._pure_applying_colorscheme = true
  set_theme_globals(item)
  vim.o.background = item_bg
  reload_theme_plugin(item.plugin)

  local ok, err = pcall(vim.cmd.colorscheme, item.scheme)
  if not ok then
    vim.g.transparent_background = transparency_pref
    vim.g._pure_applying_colorscheme = false
    vim.notify("Colorscheme failed [" .. item.scheme .. "]: " .. tostring(err), vim.log.levels.WARN)
    return false
  end

  -- Keep user toggle state even if a colorscheme/plugin mutates globals.
  vim.g.transparent_background = transparency_pref

  vim.g.pure_colorscheme = item.key
  if item_bg == "dark" then
    M._last_dark_by_family[family_key(item)] = item.key
  end
  M.apply_transparency()

  if opts.notify ~= false then
    vim.notify("Colorscheme: " .. item.label, vim.log.levels.INFO)
  end

  vim.g._pure_applying_colorscheme = false
  return true
end

function M.select()
  vim.ui.select(M.options(), {
    prompt = "Colorscheme (High Contrast)",
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