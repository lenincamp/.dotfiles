local M = {}

local ok_cyberdream_custom, cyberdream_custom = pcall(require, "modules.theme.extensions.cyberdream")
if not ok_cyberdream_custom then
  cyberdream_custom = nil
end

M.extension = cyberdream_custom
M.default = "default"

M.themes = {
  { key = "default", label = "Default (Vim)", scheme = "default", opts = { background = "dark" }, fixed_background = true },
  { key = "unokai", label = "Unokai (Vim)", scheme = "unokai", opts = { background = "dark" }, fixed_background = true },
  { key = "habamax", label = "Habamax (Vim)", scheme = "habamax", opts = { background = "dark" }, fixed_background = true },

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

M.aliases = {
  deafult = "default",
  unokai = "unokai",
  habamax = "habamax",
  catppuccin = "catppuccin-mocha",
  gruvbox = "gruvbox-hard",
  tokyonight = "tokyonight-night",
  ["solarized-osaka"] = "solarized-osaka-night",
  kanagawa = "kanagawa-dragon",
  ["rose-pine"] = "rose-pine-moon",
}

if cyberdream_custom and type(cyberdream_custom.aliases) == "table" then
  for key, value in pairs(cyberdream_custom.aliases) do
    M.aliases[key] = value
  end
end

M.transparent_groups = {
  "Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle",
  "SignColumn", "FoldColumn", "LineNr", "CursorLineNr", "StatusLine",
  "StatusLineNC", "TabLine", "TabLineFill", "WinBar", "WinBarNC",
  "WinSeparator", "Pmenu", "PmenuBorder", "TelescopeNormal", "TelescopeBorder",
}

M.sync_profile_by_key = {
  ["default"] = {
    tmux = "nord",
    delta = "ansi",
    iterm2 = "Dark High Contrast",
    lualine = { provider = "auto" },
  },
  ["unokai"] = {
    tmux = "dracula",
    delta = "ansi",
    iterm2 = "Dark High Contrast",
    lualine = { provider = "auto" },
  },
  ["habamax"] = {
    tmux = "gruvbox",
    delta = "ansi",
    iterm2 = "Dark High Contrast",
    lualine = { provider = "auto" },
  },
  ["catppuccin-mocha"] = {
    tmux = "mocha",
    delta = "catppuccin-mocha",
    iterm2 = "Catppuccin Mocha",
    terminal = { background = "#1e1e2e", foreground = "#cdd6f4" },
    lualine = { provider = "catppuccin", flavour = "mocha" },
  },
  ["catppuccin-latte"] = {
    tmux = "latte",
    delta = "catppuccin-latte",
    iterm2 = "Catppuccin Latte",
    terminal = { background = "#eff1f5", foreground = "#4c4f69" },
    lualine = { provider = "catppuccin", flavour = "latte" },
  },
  ["gruvbox-hard"] = {
    tmux = "gruvbox",
    delta = "gruvbox-dark",
    iterm2 = "Gruvbox Dark",
    terminal = { background = "#1d2021", foreground = "#ebdbb2" },
    lualine = { provider = "builtin", name = "gruvbox" },
  },
  ["gruvbox-light"] = {
    tmux = "gruvbox",
    delta = "gruvbox-light",
    iterm2 = "Gruvbox Light",
    terminal = { background = "#fbf1c7", foreground = "#3c3836" },
    lualine = { provider = "builtin", name = "gruvbox" },
  },
  ["tokyonight-night"] = {
    tmux = "tokyo-night",
    delta = "tokyonight-night",
    iterm2 = "TokyoNight",
    terminal = { background = "#1a1b26", foreground = "#c0caf5" },
    lualine = { provider = "builtin", name = "tokyonight" },
  },
  ["tokyonight-day"] = {
    tmux = "tokyo-night",
    delta = "tokyonight-day",
    iterm2 = "TokyoNight Day",
    terminal = { background = "#e1e2e7", foreground = "#3760bf" },
    lualine = { provider = "builtin", name = "tokyonight" },
  },
  ["solarized-osaka-night"] = {
    tmux = "nord",
    delta = "Solarized (dark)",
    iterm2 = "Solarized Dark",
    terminal = { background = "#00141a", foreground = "#839496" },
    lualine = { provider = "auto" },
  },
  ["solarized-osaka-day"] = {
    tmux = "nord",
    delta = "Solarized (light)",
    iterm2 = "Solarized Light",
    terminal = { background = "#fdf6e3", foreground = "#657b83" },
    lualine = { provider = "auto" },
  },
  ["kanagawa-dragon"] = {
    tmux = "nord",
    delta = "kanagawa",
    iterm2 = "Kanagawa",
    terminal = { background = "#181616", foreground = "#c5c9c5" },
    lualine = { provider = "auto" },
  },
  ["kanagawa-lotus"] = {
    tmux = "nord",
    delta = "kanagawa-lotus",
    iterm2 = "Kanagawa Lotus",
    terminal = { background = "#f2ecbc", foreground = "#545464" },
    lualine = { provider = "auto" },
  },
  ["rose-pine-moon"] = {
    tmux = "dracula",
    delta = "rose-pine-moon",
    iterm2 = "Rose Pine Moon",
    terminal = { background = "#232136", foreground = "#e0def4" },
    lualine = { provider = "builtin", name = "rose-pine" },
  },
  ["rose-pine-dawn"] = {
    tmux = "dracula",
    delta = "rose-pine-dawn",
    iterm2 = "Rose Pine Dawn",
    terminal = { background = "#faf4ed", foreground = "#575279" },
    lualine = { provider = "builtin", name = "rose-pine" },
  },
}

if cyberdream_custom and type(cyberdream_custom.sync_profile_by_key) == "table" then
  for key, value in pairs(cyberdream_custom.sync_profile_by_key) do
    M.sync_profile_by_key[key] = value
  end
end

M.tmux_theme_by_scheme = {
  default = "nord",
  unokai = "dracula",
  habamax = "gruvbox",
  catppuccin = "mocha",
  gruvbox = "gruvbox",
  tokyonight = "tokyo-night",
  ["solarized-osaka"] = "nord",
  ["kanagawa"] = "nord",
  ["rose-pine"] = "dracula",
}

if cyberdream_custom and type(cyberdream_custom.tmux_theme_by_scheme) == "table" then
  for key, value in pairs(cyberdream_custom.tmux_theme_by_scheme) do
    M.tmux_theme_by_scheme[key] = value
  end
end

M.theme_plugin_pack = {
  ["catppuccin"] = "catppuccin",
  ["gruvbox"] = "gruvbox.nvim",
  ["solarized-osaka"] = "solarized-osaka.nvim",
  ["tokyonight"] = "tokyonight.nvim",
  ["kanagawa"] = "kanagawa.nvim",
  ["rose-pine"] = "rose-pine",
  ["cyberdream"] = "cyberdream.nvim",
}

return M