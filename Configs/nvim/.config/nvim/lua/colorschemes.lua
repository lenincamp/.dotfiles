local M = {}

local ok_cyberdream_custom, cyberdream_custom = pcall(require, "custom.cyberdream")
if not ok_cyberdream_custom then cyberdream_custom = nil end

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

if cyberdream_custom and type(cyberdream_custom.themes) == "table" then
  vim.list_extend(M.themes, cyberdream_custom.themes)
end

local aliases = {
  catppuccin = "catppuccin-mocha",
  gruvbox = "gruvbox-hard",
  tokyonight = "tokyonight-night",
  ["solarized-osaka"] = "solarized-osaka-night",
  kanagawa = "kanagawa-dragon",
  ["rose-pine"] = "rose-pine-moon",
}

if cyberdream_custom and type(cyberdream_custom.aliases) == "table" then
  for key, value in pairs(cyberdream_custom.aliases) do
    aliases[key] = value
  end
end

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
M._external_sync = { pending = false, theme = nil }

-- Single source of truth for cross-tool theme synchronization.
-- Keep this table in dotfiles so theme behavior is fully replicable.
local sync_profile_by_key = {
  ["catppuccin-mocha"] = {
    tmux = "mocha",
    delta = "catppuccin-mocha",
    iterm2 = "Catppuccin Mocha",
    lualine = { provider = "catppuccin", flavour = "mocha" },
  },
  ["catppuccin-latte"] = {
    tmux = "latte",
    delta = "catppuccin-latte",
    iterm2 = "Catppuccin Latte",
    lualine = { provider = "catppuccin", flavour = "latte" },
  },
  ["gruvbox-hard"] = {
    tmux = "gruvbox",
    delta = "gruvbox-dark",
    iterm2 = "Gruvbox Dark",
    lualine = { provider = "builtin", name = "gruvbox" },
  },
  ["gruvbox-light"] = {
    tmux = "gruvbox",
    delta = "gruvbox-light",
    iterm2 = "Gruvbox Light",
    lualine = { provider = "builtin", name = "gruvbox" },
  },
  ["tokyonight-night"] = {
    tmux = "tokyo-night",
    delta = "tokyonight-night",
    iterm2 = "TokyoNight",
    lualine = { provider = "builtin", name = "tokyonight" },
  },
  ["tokyonight-day"] = {
    tmux = "tokyo-night",
    delta = "tokyonight-day",
    iterm2 = "TokyoNight Day",
    lualine = { provider = "builtin", name = "tokyonight" },
  },
  ["solarized-osaka-night"] = {
    tmux = "nord",
    delta = "Solarized (dark)",
    iterm2 = "Solarized Dark",
    lualine = { provider = "auto" },
  },
  ["solarized-osaka-day"] = {
    tmux = "nord",
    delta = "Solarized (light)",
    iterm2 = "Solarized Light",
    lualine = { provider = "auto" },
  },
  ["kanagawa-dragon"] = {
    tmux = "nord",
    delta = "kanagawa",
    iterm2 = "Kanagawa",
    lualine = { provider = "auto" },
  },
  ["kanagawa-lotus"] = {
    tmux = "nord",
    delta = "kanagawa-lotus",
    iterm2 = "Kanagawa Lotus",
    lualine = { provider = "auto" },
  },
  ["rose-pine-moon"] = {
    tmux = "dracula",
    delta = "rose-pine-moon",
    iterm2 = "Rose Pine Moon",
    lualine = { provider = "builtin", name = "rose-pine" },
  },
  ["rose-pine-dawn"] = {
    tmux = "dracula",
    delta = "rose-pine-dawn",
    iterm2 = "Rose Pine Dawn",
    lualine = { provider = "builtin", name = "rose-pine" },
  },
}

if cyberdream_custom and type(cyberdream_custom.sync_profile_by_key) == "table" then
  for key, value in pairs(cyberdream_custom.sync_profile_by_key) do
    sync_profile_by_key[key] = value
  end
end

local tmux_theme_by_scheme = {
  catppuccin = "mocha",
  gruvbox = "gruvbox",
  tokyonight = "tokyo-night",
  ["solarized-osaka"] = "nord",
  ["kanagawa"] = "nord",
  ["rose-pine"] = "dracula",
}

if cyberdream_custom and type(cyberdream_custom.tmux_theme_by_scheme) == "table" then
  for key, value in pairs(cyberdream_custom.tmux_theme_by_scheme) do
    tmux_theme_by_scheme[key] = value
  end
end

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
    lazygit = profile.lazygit,
    iterm2 = profile.iterm2,
  }
end

local function resolve_theme_for_external_sync(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local item_mode = ((item.opts and item.opts.background) or vim.o.background or "dark")
  local current_mode = vim.o.background or item_mode

  -- If current UI mode differs from persisted key, trust the active colorscheme
  -- name (set by :colorscheme) to avoid stale tmux sync.
  if item_mode ~= current_mode and type(vim.g.colors_name) == "string" and vim.g.colors_name ~= "" then
    local active_item = M.resolve(vim.g.colors_name)
    local active_mode = ((active_item.opts and active_item.opts.background) or current_mode)
    if active_mode == current_mode then
      return active_item
    end
  end

  return item
end

local function num_to_hex(color)
  if type(color) ~= "number" then return nil end
  return string.format("#%06x", color)
end

local function read_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if not ok or type(hl) ~= "table" then return {} end
  return hl
end

local function first_hex(...)
  for i = 1, select("#", ...) do
    local hex = num_to_hex(select(i, ...))
    if hex then return hex end
  end
  return nil
end

local function first_hl_fg(names)
  for _, name in ipairs(names or {}) do
    local hl = read_hl(name)
    local hex = first_hex(hl.fg)
    if hex then return hex end
  end
  return nil
end

local function first_hl_bg(names)
  for _, name in ipairs(names or {}) do
    local hl = read_hl(name)
    local hex = first_hex(hl.bg)
    if hex then return hex end
  end
  return nil
end

local function hex_to_rgb(hex)
  if type(hex) ~= "string" then return nil end
  local r, g, b = hex:match("#?(%x%x)(%x%x)(%x%x)")
  if not r or not g or not b then return nil end
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

--- Blend a foreground color toward a base at a given alpha (0.0–1.0).
--- Used to create subtle background tints from saturated foreground colors.
local function blend_hex(fg_hex, bg_hex, alpha)
  local fr, fg, fb = hex_to_rgb(fg_hex)
  local br, bg_r, bb = hex_to_rgb(bg_hex)
  if not fr or not br then return fg_hex end
  local r = math.floor(fr * alpha + br * (1 - alpha) + 0.5)
  local g = math.floor(fg * alpha + bg_r * (1 - alpha) + 0.5)
  local b = math.floor(fb * alpha + bb * (1 - alpha) + 0.5)
  return string.format("#%02x%02x%02x", r, g, b)
end

local function is_legible_diff_green(hex)
  local r, g, b = hex_to_rgb(hex)
  if not r then return false end
  return g >= 120 and g > r and g > b and r <= 210 and b <= 210
end

local function is_legible_diff_red(hex)
  local r, g, b = hex_to_rgb(hex)
  if not r then return false end
  return r >= 140 and r > g and r > b and g <= 150 and b <= 150
end

local function build_palette(mode)
  local dark = mode ~= "light"
  local normal = read_hl("Normal")
  local visual = read_hl("Visual")
  local title = read_hl("Title")
  local keyword = read_hl("Keyword")
  local identifier = read_hl("Identifier")
  local comment = read_hl("Comment")
  local diff_add = read_hl("DiffAdd")
  local diff_delete = read_hl("DiffDelete")
  local diag_warn = read_hl("DiagnosticWarn")
  local diag_error = read_hl("DiagnosticError")
  local diag_info = read_hl("DiagnosticInfo")

  -- bg: transparency clears Normal.bg → use theme item opts to derive real bg.
  -- Fallback chain: Normal.bg > known dark/light defaults.
  local raw_bg = first_hex(normal.bg)
  local bg_color
  if not raw_bg or raw_bg == "#000000" then
    -- Transparency is active — use the theme's canonical bg from the item.
    bg_color = dark and "#1e1e2e" or "#eff1f5"
    -- Try to get bg from groups that transparency doesn't always clear.
    local pmenu_bg = first_hl_bg({ "Pmenu", "NormalFloat" })
    if pmenu_bg and pmenu_bg ~= "#000000" then
      bg_color = pmenu_bg
    end
  else
    bg_color = raw_bg
  end

  -- accent: prefer vivid semantic colors that transparency doesn't clear.
  local accent = first_hex(keyword.fg, title.fg, identifier.fg, diag_info and diag_info.fg)
    or (dark and "#89b4fa" or "#1e66f5")

  -- border/inactive: Comment.fg is always preserved by transparency.
  local border_color = first_hex(comment.fg)
    or first_hl_fg({ "NonText", "LineNr" })
    or (dark and "#6c7086" or "#9ca0b0")

  -- Prefer semantic VCS colors from the active theme. If unavailable, use
  -- standard git-like green/red so diffs remain readable across themes.
  local add_fg = first_hl_fg({ "GitSignsAdd", "Added", "DiffAdded" })
    or first_hex(diff_add.fg)
  if not is_legible_diff_green(add_fg) then
    add_fg = dark and "#98c379" or "#22863a"
  end

  local del_fg = first_hl_fg({ "DiagnosticError", "ErrorMsg", "GitSignsDelete", "Removed", "DiffRemoved" })
    or first_hex(diag_error.fg)
    or first_hex(diff_delete.fg)
  if not is_legible_diff_red(del_fg) then
    del_fg = dark and "#e06c75" or "#cb2431"
  end

  local selection_bg = first_hex(visual.bg)
    or first_hl_bg({ "CursorLine", "DiffChange" })
    or (dark and "#313244" or "#ccd0da")

  -- Background tints for diff views (delta, lazygit):
  -- Blend the add/delete foreground toward bg at low opacity so text remains readable.
  local add_bg = first_hl_bg({ "DiffAdd", "GitSignsAddLn" })
    or blend_hex(add_fg, bg_color, dark and 0.12 or 0.10)
  local del_bg = first_hl_bg({ "DiffDelete", "GitSignsDeleteLn" })
    or blend_hex(del_fg, bg_color, dark and 0.12 or 0.10)
  local add_emph_bg = blend_hex(add_fg, bg_color, dark and 0.25 or 0.20)
  local del_emph_bg = blend_hex(del_fg, bg_color, dark and 0.25 or 0.20)

  return {
    fg = first_hex(normal.fg) or (dark and "#cdd6f4" or "#4c4f69"),
    bg = bg_color,
    border = border_color,
    accent = accent,
    selection = selection_bg,
    ok = add_fg,
    ok_bg = add_bg,
    ok_emph_bg = add_emph_bg,
    warn = first_hex(diag_warn.fg, title.fg) or (dark and "#f9e2af" or "#df8e1d"),
    error = del_fg,
    error_bg = del_bg,
    error_emph_bg = del_emph_bg,
  }
end

local function sanitize_key(key)
  return (key or "theme"):gsub("[^a-zA-Z0-9%-_]+", "-")
end

local function lazygit_base_dir()
  local candidates = {
    vim.fn.expand("~/.dotfiles/Configs/lazygit/Library/Application Support/lazygit"),
    vim.fn.expand("~/Library/Application Support/lazygit"),
  }

  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(dir) == 1 then return dir end
  end

  return candidates[1]
end

local function lazygit_generated_path(theme_key)
  local base = lazygit_base_dir()
  return string.format("%s/config-generated-%s.yml", base, sanitize_key(theme_key))
end

local function write_lazygit_generated_config(path, palette, delta_palette)
  local features = delta_palette
  if type(features) ~= "string" or features == "" then
    features = "catppuccin-mocha"
  end

  local delta_features = table.concat({
    features,
    "side-by-side",
    "line-numbers",
    "decorations",
  }, " ")

  local lines = {
    "# Auto-generated by nvim-pure colorschemes.lua",
    "gui:",
    "  theme:",
    "    activeBorderColor:",
    "      - \"" .. palette.border .. "\"",
    "      - bold",
    "    inactiveBorderColor:",
    "      - \"" .. palette.accent .. "\"",
    "    optionsTextColor:",
    "      - \"" .. palette.accent .. "\"",
    "    selectedLineBgColor:",
    "      - \"" .. palette.selection .. "\"",
    "    cherryPickedCommitBgColor:",
    "      - \"" .. palette.selection .. "\"",
    "    cherryPickedCommitFgColor:",
    "      - \"" .. palette.ok .. "\"",
    "    unstagedChangesColor:",
    "      - \"" .. palette.error .. "\"",
    "    defaultFgColor:",
    "      - \"" .. palette.fg .. "\"",
    "    searchingActiveBorderColor:",
    "      - \"" .. palette.warn .. "\"",
    "  authorColors:",
    "    \"*\": \"" .. palette.accent .. "\"",
    "git:",
    "  pagers:",
    "    - pager: delta --paging=never --features=\"" .. delta_features .. "\"",
  }

  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(lines, path)
end

local function git_set_global(key, value)
  if vim.fn.executable("git") ~= 1 then return false end
  vim.fn.system({ "git", "config", "--global", key, value })
  return vim.v.shell_error == 0
end

local function write_delta_generated_config(theme_key, palette, delta_features)
  local path = vim.fn.expand("~/.dotfiles/Configs/gitconfig/delta-generated.gitconfig")
  
  -- Default features if not provided
  if type(delta_features) ~= "string" or delta_features == "" then
    delta_features = theme_key .. " side-by-side line-numbers decorations"
  end
  
  local lines = {
    "# Auto-generated by nvim colorschemes.lua",
    "# Theme key: " .. sanitize_key(theme_key),
    "[delta]",
    "\tfeatures = " .. delta_features,
    "\tsyntax-theme = none",
    "\tplus-style = syntax \"" .. palette.ok_bg .. "\"",
    "\tminus-style = syntax \"" .. palette.error_bg .. "\"",
    "\tplus-emph-style = bold syntax \"" .. palette.ok_emph_bg .. "\"",
    "\tminus-emph-style = bold syntax \"" .. palette.error_emph_bg .. "\"",
    "\thunk-header-style = syntax \"" .. palette.selection .. "\"",
    "\thunk-header-decoration-style = \"" .. palette.accent .. "\" box",
    "\tfile-style = bold \"" .. palette.accent .. "\"",
    "\tfile-decoration-style = \"" .. palette.accent .. "\" ul",
    "\tline-numbers-left-style = \"" .. palette.error .. "\"",
    "\tline-numbers-right-style = \"" .. palette.ok .. "\"",
    "\tline-numbers-left-format = \"{nm:>3}│\"",
    "\tline-numbers-right-format = \"{np:>3}│\"",
    "\tline-numbers-plus-style = \"" .. palette.ok .. "\"",
    "\tline-numbers-minus-style = \"" .. palette.error .. "\"",
    "\tline-numbers-zero-style = \"" .. palette.selection .. "\"",
  }

  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(lines, path)
end

local function apply_delta_generated_palette(theme_key, palette, delta_features)
  -- Only write to delta-generated.gitconfig, do NOT modify .gitconfig directly
  -- .gitconfig includes delta-generated.gitconfig via [include]
  pcall(write_delta_generated_config, theme_key, palette, delta_features)
end

local function hex_to_rgb_components(hex)
  if type(hex) ~= "string" then return 0, 0, 0 end
  local r, g, b = hex:match("#?(%x%x)(%x%x)(%x%x)")
  if not r or not g or not b then return 0, 0, 0 end
  return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end

local function iterm_color_dict_lines(name, hex)
  local r, g, b = hex_to_rgb_components(hex)
  return {
    "  <key>" .. name .. "</key>",
    "  <dict>",
    string.format("    <key>Red Component</key><real>%.6f</real>", r),
    string.format("    <key>Green Component</key><real>%.6f</real>", g),
    string.format("    <key>Blue Component</key><real>%.6f</real>", b),
    "  </dict>",
  }
end

local function write_iterm2_generated_profile(theme_key, palette)
  local path = vim.fn.expand("~/.dotfiles/Configs/iterm2/generated/" .. sanitize_key(theme_key) .. ".itermcolors")
  local lines = {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
    "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
    "<plist version=\"1.0\">",
    "<dict>",
  }

  local entries = {
    { "Background Color", palette.bg },
    { "Foreground Color", palette.fg },
    { "Bold Color", palette.fg },
    { "Cursor Color", palette.accent },
    { "Cursor Text Color", palette.bg },
    { "Selection Color", palette.selection },
    { "Selected Text Color", palette.fg },
    { "Ansi 1 Color", palette.error },
    { "Ansi 2 Color", palette.ok },
    { "Ansi 3 Color", palette.warn },
    { "Ansi 4 Color", palette.accent },
    { "Ansi 5 Color", palette.accent },
    { "Ansi 6 Color", palette.border },
    { "Ansi 7 Color", palette.fg },
    { "Ansi 8 Color", palette.selection },
  }

  for _, entry in ipairs(entries) do
    vim.list_extend(lines, iterm_color_dict_lines(entry[1], entry[2]))
  end

  table.insert(lines, "</dict>")
  table.insert(lines, "</plist>")

  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(lines, path)
end

local function tmux_set_theme(theme_name, cache_key)
  if type(theme_name) ~= "string" or theme_name == "" then return end
  if vim.fn.executable("tmux") ~= 1 then return end
  local track = cache_key or theme_name
  if vim.g._pure_tmux_theme_last == track then return end

  vim.fn.system({ "tmux", "set-option", "-gq", "@tmux_theme", theme_name })
  if vim.v.shell_error ~= 0 then return end

  local tmux_plugin = vim.fn.expand("~/.tmux/plugins/tmux/scripts/plugin.sh")
  if vim.fn.filereadable(tmux_plugin) == 1 then
    vim.fn.system({ "bash", tmux_plugin })
  end

  vim.g._pure_tmux_theme_last = track
end

function M.sync_tmux_theme(theme)
  local item = resolve_theme_for_external_sync(theme)
  local profile = sync_profile(item)
  local tmux_theme = profile.tmux
    or tmux_theme_by_scheme[item.scheme]
    or (((item.opts and item.opts.background) or "dark") == "light" and "latte" or "mocha")

  tmux_set_theme(tmux_theme, item.key)
end

local function git_set_delta_features(features)
  -- Do NOT modify delta.features in .gitconfig
  -- The features are now written to delta-generated.gitconfig instead
  -- This prevents .gitconfig from being modified on theme changes
  return
end

function M.sync_git_delta_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local profile = sync_profile(item)
  local mode = ((item.opts and item.opts.background) or "dark")
  local palette_colors = build_palette(mode)

  local delta_palette = profile.delta
  if type(delta_palette) ~= "string" or delta_palette == "" then
    delta_palette = (mode == "light") and "catppuccin-latte" or "catppuccin-mocha"
  end

  local delta_features = table.concat({
    delta_palette,
    "side-by-side",
    "line-numbers",
    "decorations",
  }, " ")

  apply_delta_generated_palette(item.key, palette_colors, delta_features)
end

function M.sync_lazygit_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local profile = sync_profile(item)
  local mode = ((item.opts and item.opts.background) or "dark")
  local palette = build_palette(mode)
  local delta_palette = profile.delta

  if type(delta_palette) ~= "string" or delta_palette == "" then
    delta_palette = (mode == "light") and "catppuccin-latte" or "catppuccin-mocha"
  end

  local generated = lazygit_generated_path(item.key)
  local ok_write = pcall(write_lazygit_generated_config, generated, palette, delta_palette)
  if ok_write and vim.fn.filereadable(generated) == 1 then
    vim.env.LG_CONFIG_FILE = generated
    return
  end

  local base = lazygit_base_dir()
  local dark_cfg = base .. "/config.yml"
  local light_cfg = base .. "/config-light.yml"

  local target = (mode == "light") and light_cfg or dark_cfg
  if vim.fn.filereadable(target) == 1 then
    vim.env.LG_CONFIG_FILE = target
  end
end

local function copy_text_file_if_changed(src, dst)
  if vim.fn.filereadable(src) ~= 1 then return false end
  local ok_read_src, src_lines = pcall(vim.fn.readfile, src)
  if not ok_read_src or type(src_lines) ~= "table" then return false end

  local src_text = table.concat(src_lines, "\n")
  local dst_text = ""
  if vim.fn.filereadable(dst) == 1 then
    local ok_read_dst, dst_lines = pcall(vim.fn.readfile, dst)
    if ok_read_dst and type(dst_lines) == "table" then
      dst_text = table.concat(dst_lines, "\n")
    end
  end

  if src_text == dst_text then return false end

  local dir = vim.fn.fnamemodify(dst, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(src_lines, dst)
  return true
end

local function read_text_file_safe(path)
  if vim.fn.filereadable(path) ~= 1 then return nil end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then return nil end
  return table.concat(lines, "\n") .. "\n"
end

local function write_text_file_if_changed_safe(path, text)
  if type(text) ~= "string" then return false end
  local current = read_text_file_safe(path)
  if current == text then return false end

  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(vim.split(text, "\n", { plain = true }), path)
  return true
end

function M.sync_lazydocker_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local mode = ((item.opts and item.opts.background) or "dark")
  local base = vim.fn.expand("~/Library/Application Support/lazydocker")
  local src = base .. ((mode == "light") and "/config-light.yml" or "/config-dark.yml")
  local dst = base .. "/config.yml"
  pcall(copy_text_file_if_changed, src, dst)
end

function M.sync_btop_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local mode = ((item.opts and item.opts.background) or "dark")
  local color_theme = (mode == "light") and "catppuccin_latte" or "catppuccin_mocha"

  local path = vim.fn.expand("~/.config/btop/btop.conf")
  local content = read_text_file_safe(path)
  if type(content) ~= "string" then return end

  local updated = content:gsub('color_theme%s*=%s*"[^"]+"', 'color_theme = "' .. color_theme .. '"', 1)
  pcall(write_text_file_if_changed_safe, path, updated)
end

function M.sync_zellij_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local mode = ((item.opts and item.opts.background) or "dark")
  local zellij_theme = (mode == "light") and "catppuccin-latte" or "catppuccin-macchiato"

  local path = vim.fn.expand("~/.config/zellij/config.kdl")
  local content = read_text_file_safe(path)
  if type(content) ~= "string" then return end

  local updated = content:gsub('theme%s+"[^"]+"', 'theme "' .. zellij_theme .. '"', 1)
  pcall(write_text_file_if_changed_safe, path, updated)
end

function M.sync_shell_theme_runtime(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local mode = ((item.opts and item.opts.background) or "dark")
  local theme_key = item.key

  local bat_theme = (mode == "light") and "Catppuccin Latte" or "Catppuccin Mocha"
  local zsh_theme_file = (mode == "light")
      and "$ZSH/custom/themes/catppuccin_latte-zsh-syntax-highlighting.zsh"
      or "$ZSH/custom/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh"

  local fzf_opts = (mode == "light")
      and "--layout=reverse --no-height --color=bg+:#e6e9ef,bg:#eff1f5,spinner:#515c7a,hl:#ea76cb --color=fg:#4c4f69,header:#ea76cb,info:#8839ef,pointer:#515c7a --color=marker:#1e66f5,fg+:#4c4f69,prompt:#8839ef,hl+:#ea76cb --color=selected-bg:#ccd0da --color=border:#e6e9ef,label:#4c4f69"
      or "--layout=reverse --no-height --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --color=border:#313244,label:#cdd6f4"

  local lazygit_base = lazygit_base_dir()
  local lazygit_generated = lazygit_base .. "/config-generated-" .. sanitize_key(theme_key) .. ".yml"
  local lazygit_fallback = lazygit_base .. ((mode == "light") and "/config-light.yml" or "/config.yml")
  local lazygit_cfg = (vim.fn.filereadable(lazygit_generated) == 1) and lazygit_generated or lazygit_fallback

  local lines = {
    "# Auto-generated by nvim-pure colorschemes.lua",
    "export PURE_THEME_FROM_NVIM=1",
    "export PURE_THEME_AUTHORITY=nvim",
    "export PURE_NVIM_THEME_KEY=\"" .. theme_key .. "\"",
    "export PURE_THEME_MODE=\"" .. mode .. "\"",
    "export BAT_THEME=\"" .. bat_theme .. "\"",
    "export FZF_DEFAULT_OPTS=\"" .. fzf_opts .. "\"",
    "export LG_CONFIG_FILE=\"" .. lazygit_cfg .. "\"",
    "if [[ -n \"$ZSH\" && -f \"" .. zsh_theme_file .. "\" ]]; then",
    "  source \"" .. zsh_theme_file .. "\"",
    "fi",
  }

  local path = vim.fn.expand("~/.cache/nvim/theme-sync.zsh")
  pcall(write_text_file_if_changed_safe, path, table.concat(lines, "\n") .. "\n")
end

local function write_eza_generated_theme(path, palette)
  local p = {
    fg = palette.fg,
    accent = palette.accent,
    border = palette.border,
    selection = palette.selection,
    ok = palette.ok,
    warn = palette.warn,
    err = palette.error,
  }

  local lines = {
    "colourful: true",
    "",
    "filekinds:",
    "  normal: { foreground: \"" .. p.fg .. "\" }",
    "  directory: { foreground: \"" .. p.accent .. "\" }",
    "  symlink: { foreground: \"" .. p.border .. "\" }",
    "  pipe: { foreground: \"" .. p.selection .. "\" }",
    "  block_device: { foreground: \"" .. p.err .. "\" }",
    "  char_device: { foreground: \"" .. p.err .. "\" }",
    "  socket: { foreground: \"" .. p.selection .. "\" }",
    "  special: { foreground: \"" .. p.accent .. "\" }",
    "  executable: { foreground: \"" .. p.ok .. "\" }",
    "  mount_point: { foreground: \"" .. p.border .. "\" }",
    "",
    "perms:",
    "  user_read: { foreground: \"" .. p.fg .. "\" }",
    "  user_write: { foreground: \"" .. p.warn .. "\" }",
    "  user_execute_file: { foreground: \"" .. p.ok .. "\" }",
    "  user_execute_other: { foreground: \"" .. p.ok .. "\" }",
    "  group_read: { foreground: \"" .. p.fg .. "\" }",
    "  group_write: { foreground: \"" .. p.warn .. "\" }",
    "  group_execute: { foreground: \"" .. p.ok .. "\" }",
    "  other_read: { foreground: \"" .. p.selection .. "\" }",
    "  other_write: { foreground: \"" .. p.warn .. "\" }",
    "  other_execute: { foreground: \"" .. p.ok .. "\" }",
    "  special_user_file: { foreground: \"" .. p.accent .. "\" }",
    "  special_other: { foreground: \"" .. p.selection .. "\" }",
    "  attribute: { foreground: \"" .. p.selection .. "\" }",
    "",
    "size:",
    "  major: { foreground: \"" .. p.selection .. "\" }",
    "  minor: { foreground: \"" .. p.border .. "\" }",
    "  number_byte: { foreground: \"" .. p.fg .. "\" }",
    "  number_kilo: { foreground: \"" .. p.fg .. "\" }",
    "  number_mega: { foreground: \"" .. p.accent .. "\" }",
    "  number_giga: { foreground: \"" .. p.accent .. "\" }",
    "  number_huge: { foreground: \"" .. p.border .. "\" }",
    "  unit_byte: { foreground: \"" .. p.selection .. "\" }",
    "  unit_kilo: { foreground: \"" .. p.accent .. "\" }",
    "  unit_mega: { foreground: \"" .. p.accent .. "\" }",
    "  unit_giga: { foreground: \"" .. p.accent .. "\" }",
    "  unit_huge: { foreground: \"" .. p.border .. "\" }",
    "",
    "users:",
    "  user_you: { foreground: \"" .. p.fg .. "\" }",
    "  user_root: { foreground: \"" .. p.err .. "\" }",
    "  user_other: { foreground: \"" .. p.accent .. "\" }",
    "  group_yours: { foreground: \"" .. p.fg .. "\" }",
    "  group_other: { foreground: \"" .. p.selection .. "\" }",
    "  group_root: { foreground: \"" .. p.err .. "\" }",
    "",
    "links:",
    "  normal: { foreground: \"" .. p.border .. "\" }",
    "  multi_link_file: { foreground: \"" .. p.border .. "\" }",
    "",
    "git:",
    "  new: { foreground: \"" .. p.ok .. "\" }",
    "  modified: { foreground: \"" .. p.warn .. "\" }",
    "  deleted: { foreground: \"" .. p.err .. "\" }",
    "  renamed: { foreground: \"" .. p.border .. "\" }",
    "  typechange: { foreground: \"" .. p.accent .. "\" }",
    "  ignored: { foreground: \"" .. p.selection .. "\" }",
    "  conflicted: { foreground: \"" .. p.err .. "\" }",
    "",
    "git_repo:",
    "  branch_main: { foreground: \"" .. p.fg .. "\" }",
    "  branch_other: { foreground: \"" .. p.accent .. "\" }",
    "  git_clean: { foreground: \"" .. p.ok .. "\" }",
    "  git_dirty: { foreground: \"" .. p.err .. "\" }",
    "",
    "security_context:",
    "  colon: { foreground: \"" .. p.selection .. "\" }",
    "  user: { foreground: \"" .. p.fg .. "\" }",
    "  role: { foreground: \"" .. p.accent .. "\" }",
    "  typ: { foreground: \"" .. p.selection .. "\" }",
    "  range: { foreground: \"" .. p.accent .. "\" }",
    "",
    "file_type:",
    "  image: { foreground: \"" .. p.warn .. "\" }",
    "  video: { foreground: \"" .. p.err .. "\" }",
    "  music: { foreground: \"" .. p.ok .. "\" }",
    "  lossless: { foreground: \"" .. p.border .. "\" }",
    "  crypto: { foreground: \"" .. p.selection .. "\" }",
    "  document: { foreground: \"" .. p.fg .. "\" }",
    "  compressed: { foreground: \"" .. p.accent .. "\" }",
    "  temp: { foreground: \"" .. p.err .. "\" }",
    "  compiled: { foreground: \"" .. p.border .. "\" }",
    "  build: { foreground: \"" .. p.selection .. "\" }",
    "  source: { foreground: \"" .. p.accent .. "\" }",
    "",
    "punctuation: { foreground: \"" .. p.selection .. "\" }",
    "date: { foreground: \"" .. p.warn .. "\" }",
    "inode: { foreground: \"" .. p.selection .. "\" }",
    "blocks: { foreground: \"" .. p.selection .. "\" }",
    "header: { foreground: \"" .. p.fg .. "\" }",
    "octal: { foreground: \"" .. p.border .. "\" }",
    "flags: { foreground: \"" .. p.accent .. "\" }",
    "",
    "symlink_path: { foreground: \"" .. p.border .. "\" }",
    "control_char: { foreground: \"" .. p.border .. "\" }",
    "broken_symlink: { foreground: \"" .. p.err .. "\" }",
    "broken_path_overlay: { foreground: \"" .. p.selection .. "\" }",
  }

  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(lines, path)
end

function M.sync_eza_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local mode = ((item.opts and item.opts.background) or vim.o.background or "dark")
  local palette = build_palette(mode)

  local target = vim.fn.expand("~/.config/eza/theme.yml")
  local ok_write = pcall(write_eza_generated_theme, target, palette)
  if not ok_write then
    vim.notify("eza theme sync failed: " .. target, vim.log.levels.WARN)
  end
end

local function read_text_file(path)
  if vim.fn.filereadable(path) ~= 1 then return nil end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then return nil end
  return table.concat(lines, "\n") .. "\n"
end

local function write_text_file_if_changed(path, text)
  if type(text) ~= "string" then return false end
  local current = read_text_file(path)
  if current == text then return false end

  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(vim.split(text, "\n", { plain = true }), path)
  return true
end

local function replace_first(content, pattern, replacement)
  local updated, n = content:gsub(pattern, replacement, 1)
  if n == 0 then return content, false end
  return updated, true
end

local function replace_section_value(content, section, key, value)
  local pattern = string.format("(%%[%s%%][%%s%%S]-\n%s%%s*=%%s*\")[^\"]+(\"[^\n]*\n?)", section, key)
  local updated, n = content:gsub(pattern, "%1" .. value .. "%2", 1)
  if n == 0 then return content, false end
  return updated, true
end

local function upsert_palette_block(content, palette_name, block_lines)
  local header = "[palettes." .. palette_name .. "]"
  local lines = vim.split(content, "\n", { plain = true })

  local start_idx = nil
  for i, line in ipairs(lines) do
    if line == header then
      start_idx = i
      break
    end
  end

  if not start_idx then
    local trimmed = content:gsub("%s*$", "")
    return trimmed .. "\n\n" .. table.concat(block_lines, "\n") .. "\n"
  end

  local end_idx = #lines
  for i = start_idx + 1, #lines do
    if lines[i]:match("^%[.+%]$") then
      end_idx = i - 1
      break
    end
  end

  local merged = {}
  for i = 1, start_idx - 1 do
    table.insert(merged, lines[i])
  end
  vim.list_extend(merged, block_lines)
  for i = end_idx + 1, #lines do
    table.insert(merged, lines[i])
  end

  return table.concat(merged, "\n")
end

function M.sync_starship_theme(theme)
  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local mode = ((item.opts and item.opts.background) or vim.o.background or "dark")
  local palette = build_palette(mode)
  local palette_name = sanitize_key(item.key):gsub("-", "_")

  local starship_path = vim.fn.expand("~/.config/starship.toml")
  local content = read_text_file(starship_path)
  if type(content) ~= "string" then return end

  local updated = content

  updated = (replace_first(updated, 'palette%s*=%s*"[^"]+"', 'palette = "' .. palette_name .. '"'))

  updated = (replace_section_value(updated, "directory", "style", "bold " .. palette.accent))
  updated = (replace_section_value(updated, "git_branch", "style", "bold " .. palette.border))
  updated = (replace_section_value(updated, "git_status", "style", "bold " .. palette.warn))
  updated = (replace_section_value(updated, "nodejs", "style", "bold " .. palette.ok))
  updated = (replace_section_value(updated, "cmd_duration", "style", "bold " .. palette.warn))
  updated = (replace_section_value(updated, "status", "success_style", "bold " .. palette.ok))
  updated = (replace_section_value(updated, "status", "failure_style", "bold " .. palette.error))

  local palette_lines = {
    "[palettes." .. palette_name .. "]",
    "text = \"" .. palette.fg .. "\"",
    "surface0 = \"" .. palette.selection .. "\"",
    "surface1 = \"" .. palette.border .. "\"",
    "base = \"" .. palette.bg .. "\"",
    "blue = \"" .. palette.accent .. "\"",
    "green = \"" .. palette.ok .. "\"",
    "yellow = \"" .. palette.warn .. "\"",
    "red = \"" .. palette.error .. "\"",
  }

  updated = upsert_palette_block(updated, palette_name, palette_lines)

  local ok_write = pcall(write_text_file_if_changed, starship_path, updated)
  if not ok_write then
    vim.notify("starship theme sync failed: " .. starship_path, vim.log.levels.WARN)
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
    return true
  end
  return false
end

local function iterm2_apply_first_preset(candidates)
  if type(candidates) ~= "table" then return false end
  for _, preset in ipairs(candidates) do
    if type(preset) == "string" and preset ~= "" then
      local ok = iterm2_set_preset(preset)
      if ok then return true end
    end
  end
  return false
end

local function iterm2_preset_candidates(mode)
  if mode == "light" then
    return {
      "Light High Contrast",
      "High Contrast Light",
    }
  end

  return {
    "Dark High Contrast",
    "High Contrast Dark",
  }
end

local function iterm2_get_current_preset()
  if vim.fn.executable("osascript") ~= 1 then return nil end
  local script = table.concat({
    'tell application "iTerm2"',
    "if (count of windows) > 0 then",
    "return color preset of current session of current tab of current window",
    "end if",
    "return \"\"",
    "end tell",
  }, "\n")

  local out = vim.fn.system({ "osascript", "-e", script })
  if vim.v.shell_error ~= 0 then return nil end
  out = vim.trim(out or "")
  if out == "" then return nil end
  return out
end

local function parse_rgb_csv(s)
  if type(s) ~= "string" then return nil end
  local r, g, b = s:match("^%s*(%-?%d+%.?%d*)%s*,%s*(%-?%d+%.?%d*)%s*,%s*(%-?%d+%.?%d*)%s*$")
  if not r or not g or not b then return nil end
  return tonumber(r), tonumber(g), tonumber(b)
end

local function iterm2_get_background_rgb()
  if vim.fn.executable("osascript") ~= 1 then return nil end
  local script = table.concat({
    'tell application "iTerm2"',
    "if (count of windows) > 0 then",
    "tell current session of current tab of current window",
    "set c to background color",
    "return ((item 1 of c) as string) & \",\" & ((item 2 of c) as string) & \",\" & ((item 3 of c) as string)",
    "end tell",
    "end if",
    "return \"\"",
    "end tell",
  }, "\n")

  local out = vim.fn.system({ "osascript", "-e", script })
  if vim.v.shell_error ~= 0 then return nil end
  out = vim.trim(out or "")
  if out == "" then return nil end
  return parse_rgb_csv(out)
end

local function rgb_is_light(r, g, b)
  if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return nil end
  local threshold = 32767 * 3
  return (r + g + b) >= threshold
end

local function iterm2_mode_matches(mode)
  local r, g, b = iterm2_get_background_rgb()
  if not r then return nil end
  local is_light = rgb_is_light(r, g, b)
  if is_light == nil then return nil end
  return (mode == "light" and is_light) or (mode ~= "light" and not is_light)
end

local function iterm2_apply_high_contrast_mode(mode)
  if vim.fn.executable("osascript") ~= 1 then return false end

  local bg = (mode == "light") and "{65535, 65535, 65535, 65535}" or "{0, 0, 0, 65535}"
  local fg = (mode == "light") and "{0, 0, 0, 65535}" or "{65535, 65535, 65535, 65535}"
  local cursor = fg
  local cursor_text = bg
  local selection = (mode == "light") and "{49151, 49151, 49151, 65535}" or "{16384, 16384, 16384, 65535}"

  local script = table.concat({
    'tell application "iTerm2"',
    "if (count of windows) > 0 then",
    "tell current session of current tab of current window",
    "set background color to " .. bg,
    "set foreground color to " .. fg,
    "set bold color to " .. fg,
    "set cursor color to " .. cursor,
    "set cursor text color to " .. cursor_text,
    "set selection color to " .. selection,
    "set selected text color to " .. fg,
    "end tell",
    "end if",
    "end tell",
  }, "\n")

  vim.fn.system({ "osascript", "-e", script })
  if vim.v.shell_error ~= 0 then return false end
  local ok = iterm2_mode_matches(mode)
  return ok ~= false
end

function M.sync_iterm2_theme(theme)
  local in_iterm2 = (vim.env.TERM_PROGRAM == "iTerm.app")
    or (type(vim.env.ITERM_SESSION_ID) == "string" and vim.env.ITERM_SESSION_ID ~= "")
  local force_sync = (vim.g.pure_iterm2_sync_always == true)

  -- Avoid noisy startup warnings when Neovim is running outside iTerm2
  -- (VS Code terminal, tmux in other terminals, headless runs, etc.).
  if not in_iterm2 and not force_sync then return end

  local item = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local mode = (((item.opts and item.opts.background) or vim.o.background or "dark") == "light") and "light" or "dark"
  if vim.g._pure_iterm2_mode_last == mode then return end
  local palette = build_palette(mode)

  pcall(write_iterm2_generated_profile, item.key, palette)

  local candidates = iterm2_preset_candidates(mode)

  local preset_applied = iterm2_apply_first_preset(candidates)
  local mode_ok = preset_applied and (iterm2_mode_matches(mode) ~= false)

  if not mode_ok then
    local fallback_ok = iterm2_apply_high_contrast_mode(mode)
    if not fallback_ok then
      if vim.g.pure_iterm2_sync_notify ~= false then
        vim.notify("iTerm2 sync not applied. Check AppleScript permissions and active iTerm window.", vim.log.levels.WARN)
      end
      return
    end
  end

  vim.g._pure_iterm2_mode_last = mode
end

function M.sync_external_tools(theme)
  M.sync_tmux_theme(theme)
  M.sync_git_delta_theme(theme)
  M.sync_lazygit_theme(theme)
  M.sync_lazydocker_theme(theme)
  M.sync_btop_theme(theme)
  M.sync_zellij_theme(theme)
  M.sync_shell_theme_runtime(theme)
  M.sync_starship_theme(theme)
  M.sync_iterm2_theme(theme)
  M.sync_eza_theme(theme)
end

function M.request_external_sync(theme)
  local resolved = M.resolve(theme or vim.g.pure_colorscheme or vim.g.colors_name or M.default)

  -- Tmux sync is fast and critical — run it immediately so the user sees
  -- the bar update without waiting for the next event-loop iteration.
  pcall(M.sync_tmux_theme, resolved)

  -- In headless runs there is no active UI loop to reliably drain scheduled
  -- callbacks before `+qa`, so run remaining sync inline.
  if #vim.api.nvim_list_uis() == 0 then
    M.sync_external_tools(resolved)
    return
  end

  M._external_sync.theme = resolved
  if M._external_sync.pending then return end

  M._external_sync.pending = true
  vim.schedule(function()
    M._external_sync.pending = false
    local target = M._external_sync.theme
    M._external_sync.theme = nil
    if target then
      pcall(M.sync_external_tools, target)
    end
  end)
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

local function detect_system_background_mode()
  -- Fast path on macOS without AppleScript permission overhead.
  if vim.fn.executable("defaults") == 1 then
    local out = vim.fn.system({ "defaults", "read", "-g", "AppleInterfaceStyle" })
    if vim.v.shell_error == 0 then
      out = vim.trim((out or ""):lower())
      if out:find("dark", 1, true) then return "dark" end
      return "light"
    end
    -- When key doesn't exist, macOS is in Light mode.
    return "light"
  end

  if vim.fn.executable("osascript") ~= 1 then return nil end
  local script = 'tell application "System Events" to tell appearance preferences to return dark mode'
  local out = vim.fn.system({ "osascript", "-e", script })
  if vim.v.shell_error ~= 0 then return nil end

  out = vim.trim((out or ""):lower())
  if out == "true" then return "dark" end
  if out == "false" then return "light" end
  return nil
end

function M.sync_with_system_background(opts)
  opts = opts or {}
  if vim.g._pure_applying_colorscheme then return false end

  local wanted = detect_system_background_mode()
  if wanted == nil then return false end

  -- Track the previous system mode before updating
  local previous_system = vim.g._pure_system_mode_last
  
  -- Only react when the SYSTEM mode actually changes
  if opts.force ~= true and wanted == previous_system then
    return false
  end

  -- Update the tracked system mode
  vim.g._pure_system_mode_last = wanted

  local current = M.resolve(vim.g.pure_colorscheme or vim.g.colors_name or M.default)
  local current_mode = (((current.opts and current.opts.background) or vim.o.background or "dark") == "light") and "light" or "dark"

  -- If already in the desired mode, nothing to do
  if current_mode == wanted then return false end
  
  -- Only auto-switch if we were previously in sync with the system.
  -- If user chose a mode different from the previous system mode, respect that.
  if opts.force ~= true and previous_system ~= nil and current_mode ~= previous_system then
    return false
  end

  return M.set_background_mode(wanted)
end

local function start_system_background_watcher()
  if M._system_theme_timer then return end
  if vim.g.pure_system_theme_auto == false then return end

  local uv = vim.uv or vim.loop
  if not uv or not uv.new_timer then return end

  local interval = tonumber(vim.g.pure_system_theme_poll_ms) or 8000
  if interval <= 0 then return end
  if interval < 1000 then interval = 1000 end

  local timer = uv.new_timer()
  if not timer then return end

  timer:start(interval, interval, vim.schedule_wrap(function()
    pcall(M.sync_with_system_background)
  end))

  M._system_theme_timer = timer
end

local function stop_system_background_watcher()
  local timer = M._system_theme_timer
  if not timer then return end
  pcall(function()
    timer:stop()
    timer:close()
  end)
  M._system_theme_timer = nil
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
      stop_system_background_watcher()
      -- Prevent ColorScheme autocmd from syncing during exit (causes theme revert)
      vim.g._pure_vim_leaving = true
    end,
  })

  vim.api.nvim_create_user_command("ItermPresetTest", function(opts)
    local arg = vim.trim((opts.args or ""):lower())
    local mode = (arg == "light" or arg == "dark") and arg or (M.is_dark_background() and "dark" or "light")
    local before = iterm2_get_current_preset() or "<unknown>"
    local candidates = iterm2_preset_candidates(mode)

    local winner = nil
    for _, preset in ipairs(candidates) do
      if iterm2_set_preset(preset) then
        winner = preset
        break
      end
    end

    local after = iterm2_get_current_preset() or "<unknown>"
    if winner then
      vim.notify(
        string.format("ItermPresetTest: mode=%s winner=%s before=%s after=%s", mode, winner, before, after),
        vim.log.levels.INFO
      )
      return
    end

    vim.notify(
      "ItermPresetTest: no preset applied. Candidates: " .. table.concat(candidates, ", "),
      vim.log.levels.WARN
    )
  end, {
    nargs = "?",
    desc = "Test iTerm2 preset candidates",
    complete = function()
      return { "dark", "light" }
    end,
    force = true,
  })

  vim.api.nvim_create_user_command("TmuxSync", function()
    vim.g._pure_tmux_theme_last = nil
    local theme = vim.g.pure_colorscheme or vim.g.colors_name or M.default
    M.sync_tmux_theme(theme)
    local result = vim.fn.system({ "tmux", "show-option", "-gqv", "@tmux_theme" })
    vim.notify("TmuxSync: theme=" .. theme .. " → tmux @tmux_theme=" .. vim.trim(result), vim.log.levels.INFO)
  end, { desc = "Force tmux theme sync", force = true })

  start_system_background_watcher()
  vim.schedule(function()
    M.sync_with_system_background({ force = true })
  end)
end

local function set_theme_globals(theme)
  local opts = (theme and theme.opts) or {}
  vim.g.pure_catppuccin_flavour = opts.flavour or "mocha"
  vim.g.pure_gruvbox_contrast = opts.contrast or "hard"
  vim.g.pure_tokyonight_style = opts.style or "moon"
  vim.g.pure_solarized_osaka_style = opts.style or "night"
  vim.g.pure_kanagawa_theme = opts.theme or "wave"
  vim.g.pure_rose_pine_variant = opts.variant or "moon"
  if cyberdream_custom and type(cyberdream_custom.apply_theme_globals) == "function" then
    cyberdream_custom.apply_theme_globals(opts)
  end
end

local function reload_theme_plugin(plugin)
  if not plugin then return end
  local path = vim.fn.stdpath("config") .. "/plugins/" .. plugin .. ".lua"
  if vim.fn.filereadable(path) == 1 then pcall(dofile, path) end
end

function M.options()
  local dark_items = {}
  local light_items = {}
  local picker_priority = (cyberdream_custom and cyberdream_custom.picker_priority) or {}

  for _, theme in ipairs(M.themes) do
    local item = vim.tbl_extend("force", {}, theme, { source = "favorite" })
    if (theme.opts and theme.opts.background) == "light" then
      table.insert(light_items, item)
    else
      table.insert(dark_items, item)
    end
  end

  local function by_priority_then_label(a, b)
    local pa = picker_priority[a.key] or 999
    local pb = picker_priority[b.key] or 999
    if pa ~= pb then return pa < pb end
    return a.label < b.label
  end

  table.sort(dark_items, by_priority_then_label)
  table.sort(light_items, by_priority_then_label)

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
  M.request_external_sync(item)

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