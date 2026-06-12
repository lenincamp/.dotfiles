local M = {}

M.themes = {
  {
    key = "cyberdream",
    label = "Cyberdream",
    scheme = "cyberdream",
    plugin = "cyberdream",
    opts = { variant = "default", background = "dark" },
  },
  {
    key = "cyberdream-light",
    label = "Cyberdream Light",
    scheme = "cyberdream",
    plugin = "cyberdream",
    opts = { variant = "light", background = "light" },
  },
}

M.aliases = {
  cyberdream = "cyberdream",
}

M.sync_profile_by_key = {
  ["cyberdream"] = {
    tmux = "tokyo-night",
    delta = "tokyonight-night",
    iterm2 = "Cyberdream",
    lualine = { provider = "auto" },
  },
  ["cyberdream-light"] = {
    tmux = "tokyo-night",
    delta = "tokyonight-day",
    iterm2 = "Cyberdream Light",
    lualine = { provider = "auto" },
  },
}

M.tmux_theme_by_scheme = {
  ["cyberdream"] = "tokyo-night",
}

M.picker_priority = {
  cyberdream = 1,
  ["cyberdream-light"] = 1,
}

function M.apply_theme_globals(opts)
  vim.g.pure_cyberdream_variant = (opts and opts.variant) or "default"
end

return M
