-- mini.surround: add / delete / replace surrounding pairs.
-- Uses gz prefix (not s) to avoid collision with flash.nvim's s/S jump keys.
--
-- gza{motion}  add surround          e.g. gzaiw"  → "word"
-- gzd{sr}      delete surround       e.g. gzd"    → remove quotes
-- gzr{old}{new} replace surround     e.g. gzr"'   → swap " for '
-- gzf          find surrounding →
-- gzF          find surrounding ←
-- gzh          highlight surrounding
--
-- Supported pairs: () [] {} <> "" '' `` and tags t

local ok, surround = pcall(require, "mini.surround")
if not ok then return end

surround.setup({
  -- Number of lines within which surrounding is searched
  n_lines = 20,

  -- Highlight duration (ms)
  highlight_duration = 500,

  -- gz prefix — no conflict with flash (s) or treesitter-textobjects (gs)
  mappings = {
    add            = "gza",
    delete         = "gzd",
    replace        = "gzr",
    find           = "gzf",
    find_left      = "gzF",
    highlight      = "gzh",
    update_n_lines = "gzn",
  },

  -- Surrounding spec: custom pairs beyond the built-in defaults
  custom_surroundings = nil,

  -- Respect user mappings — don't create default which-key groups
  silent = false,
})
