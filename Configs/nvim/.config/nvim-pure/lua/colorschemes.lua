local M = {}

M.default = "catppuccin-mocha"

local state_file = vim.fn.stdpath("state") .. "/colorscheme.json"

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
  tokyonight = "tokyonight-night",
  ["solarized-osaka"] = "solarized-osaka-night",
  kanagawa = "kanagawa-dragon",
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

local function load_state_key()
  if vim.fn.filereadable(state_file) ~= 1 then return nil end

  local ok_read, lines = pcall(vim.fn.readfile, state_file)
  if not ok_read or type(lines) ~= "table" or #lines == 0 then return nil end

  local ok_decode, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_decode or type(data) ~= "table" then return nil end

  local key = data.key
  if type(key) ~= "string" or key == "" then return nil end

  key = aliases[key] or key
  if M._theme_map[key] then return key end
  return nil
end

local function persist_state_key(key)
  if type(key) ~= "string" or key == "" then return end

  local ok_encode, payload = pcall(vim.json.encode, {
    key = key,
    updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  })
  if not ok_encode or type(payload) ~= "string" then return end

  local dir = vim.fn.fnamemodify(state_file, ":h")
  vim.fn.mkdir(dir, "p")
  pcall(vim.fn.writefile, vim.split(payload, "\n"), state_file)
end

local persisted_default = load_state_key()
if persisted_default then M.default = persisted_default end
if type(vim.g.pure_colorscheme) ~= "string" or vim.g.pure_colorscheme == "" then
  vim.g.pure_colorscheme = M.default
end

M._last_dark_by_family = {}

-- Single source of truth for cross-tool theme synchronization.
-- Keep this table in dotfiles so theme behavior is fully replicable.
local sync_profile_by_key = {
  ["catppuccin-mocha"] = {
    tmux = "mocha",
    lualine = { provider = "catppuccin", flavour = "mocha" },
  },
  ["catppuccin-latte"] = {
    tmux = "latte",
    lualine = { provider = "catppuccin", flavour = "latte" },
  },
  ["gruvbox-hard"] = {
    tmux = "gruvbox",
    lualine = { provider = "builtin", name = "gruvbox" },
  },
  ["gruvbox-light"] = {
    tmux = "gruvbox",
    lualine = { provider = "builtin", name = "gruvbox" },
  },
  ["tokyonight-night"] = {
    tmux = "tokyo-night",
    lualine = { provider = "builtin", name = "tokyonight" },
  },
  ["tokyonight-day"] = {
    tmux = "tokyo-night",
    lualine = { provider = "builtin", name = "tokyonight" },
  },
  ["solarized-osaka-night"] = {
    tmux = "nord",
    lualine = { provider = "auto" },
  },
  ["solarized-osaka-day"] = {
    tmux = "latte",
    lualine = { provider = "auto" },
  },
  ["kanagawa-dragon"] = {
    tmux = "nord",
    lualine = { provider = "auto" },
  },
  ["kanagawa-lotus"] = {
    tmux = "latte",
    lualine = { provider = "auto" },
  },
  ["rose-pine-moon"] = {
    tmux = "dracula",
    lualine = { provider = "builtin", name = "rose-pine" },
  },
  ["rose-pine-dawn"] = {
    tmux = "latte",
    lualine = { provider = "builtin", name = "rose-pine" },
  },
}

local tmux_theme_by_scheme = {
  catppuccin = "mocha",
  gruvbox = "gruvbox",
  tokyonight = "tokyo-night",
  ["solarized-osaka"] = "nord",
  ["kanagawa"] = "nord",
  ["rose-pine"] = "dracula",
}

local function sync_profile(item)
  return sync_profile_by_key[item.key] or {}
end

function M.theme_profile(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local profile = sync_profile(item)
  return {
    key = item.key,
    scheme = item.scheme,
    plugin = item.plugin,
    tmux = profile.tmux,
    lualine = profile.lualine,
    delta = profile.delta,
    iterm2 = profile.iterm2,
  }
end

local function tmux_set_theme(theme)
  if type(theme) ~= "string" or theme == "" then return end
  if vim.fn.executable("tmux") ~= 1 then return end
  if vim.g._pure_tmux_theme_last == theme then return end

  local ok, success = pcall(function()
    vim.fn.system({ "tmux", "set-option", "-gq", "@tmux_theme", theme })
    if vim.v.shell_error ~= 0 then return false end

    -- armando-rios/tmux reads options when plugin.sh runs; re-run it directly.
    local tmux_plugin = vim.fn.expand("~/.tmux/plugins/tmux/scripts/plugin.sh")
    if vim.fn.filereadable(tmux_plugin) == 1 then
      vim.fn.system({ "tmux", "run-shell", tmux_plugin })
    else
      -- Fallback for other setups.
      local tmux_conf = vim.fn.expand("~/.tmux.conf")
      if vim.fn.filereadable(tmux_conf) == 1 then
        vim.fn.system({ "tmux", "source-file", tmux_conf })
      end
    end

    vim.fn.system({ "tmux", "refresh-client", "-S" })
    return vim.v.shell_error == 0
  end)

  if ok and success then vim.g._pure_tmux_theme_last = theme end
end

function M.sync_tmux_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local strict = (vim.g.pure_tmux_theme_strict ~= false)
  local profile = sync_profile(item)
  local tmux_theme

  if strict then
    -- Strict mode (default): only explicit per-theme mappings are allowed.
    tmux_theme = profile.tmux
  else
    -- Relaxed mode: allow family and background fallbacks.
    tmux_theme = profile.tmux
      or tmux_theme_by_scheme[item.scheme]
      or (((item.opts and item.opts.background) or "dark") == "light" and "latte" or "mocha")
  end

  if not tmux_theme then return end
  tmux_set_theme(tmux_theme)
end

local function git_set_delta_features(features)
  if type(features) ~= "string" or features == "" then return end
  if vim.fn.executable("git") ~= 1 then return end
  if vim.g._pure_delta_features_last == features then return end

  vim.fn.system({ "git", "config", "--global", "--replace-all", "delta.features", features })
  if vim.v.shell_error == 0 then
    vim.g._pure_delta_features_last = features
  end
end

function M.sync_git_delta_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local profile = sync_profile(item)
  local mode = ((item.opts and item.opts.background) or "dark")

  local palette = profile.delta
  if type(palette) ~= "string" or palette == "" then
    palette = (mode == "light") and "catppuccin-latte" or "catppuccin-mocha"
  end

  git_set_delta_features(table.concat({
    palette,
    "side-by-side",
    "line-numbers",
    "decorations",
  }, " "))
end

function M.sync_lazygit_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local mode = ((item.opts and item.opts.background) or "dark")

  local base = vim.fn.expand("~/.dotfiles/Configs/lazygit/Library Application Support/lazygit")
  local dark_cfg = base .. "/config.yml"
  local light_cfg = base .. "/config-light.yml"

  local target = (mode == "light") and light_cfg or dark_cfg
  if vim.fn.filereadable(target) == 1 then
    vim.env.LG_CONFIG_FILE = target
  end
end

local function iterm2_set_preset(preset)
  if type(preset) ~= "string" or preset == "" then return end
  if vim.fn.executable("osascript") ~= 1 then return end
  if vim.g._pure_iterm2_preset_last == preset then return end

  local script = table.concat({
    'tell application "iTerm2"',
    "if (count of windows) > 0 then",
    'tell current session of current tab of current window to set color preset to "' .. preset .. '"',
    "end if",
    "end tell",
  }, "\n")

  vim.fn.system({ "osascript", "-e", script })
  if vim.v.shell_error == 0 then
    vim.g._pure_iterm2_preset_last = preset
  end
end

function M.sync_iterm2_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local profile = sync_profile(item)
  local mode = ((item.opts and item.opts.background) or "dark")

  local preset = profile.iterm2
  if type(preset) ~= "string" or preset == "" then
    preset = (mode == "light") and "Catppuccin Latte" or "Catppuccin Mocha"
  end

  iterm2_set_preset(preset)
end

function M.lualine_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
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

  local group = vim.api.nvim_create_augroup("PureTransparentColors", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      M.apply_transparency()
      M.sync_tmux_theme(vim.g.pure_colorscheme or vim.g.colors_name)
      M.sync_git_delta_theme(vim.g.pure_colorscheme or vim.g.colors_name)
      M.sync_lazygit_theme(vim.g.pure_colorscheme or vim.g.colors_name)
      M.sync_iterm2_theme(vim.g.pure_colorscheme or vim.g.colors_name)
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.sync_tmux_theme(vim.g.pure_colorscheme or vim.g.colors_name or M.default)
      M.sync_git_delta_theme(vim.g.pure_colorscheme or vim.g.colors_name or M.default)
      M.sync_lazygit_theme(vim.g.pure_colorscheme or vim.g.colors_name or M.default)
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
  local previous_key = vim.g.pure_colorscheme
  local item_bg = (item.opts and item.opts.background) or "dark"
  local transparency_pref = M.is_transparent()
  vim.g._pure_applying_colorscheme = true
  set_theme_globals(item)
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
    reload_theme_plugin(item.plugin)
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
    M._last_dark_by_family[family_key(item)] = item.key
  end
  M.apply_transparency()
  persist_state_key(item.key)
  M.sync_tmux_theme(item)
  M.sync_git_delta_theme(item)
  M.sync_lazygit_theme(item)
  M.sync_iterm2_theme(item)

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