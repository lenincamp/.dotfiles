-- mini.surround: add / delete / replace surrounding pairs.
-- Standard s-prefix mappings:
--
-- sa{motion}   add surround          e.g. saiw"  -> "word"
-- sd{sr}       delete surround       e.g. sd"    -> remove quotes
-- sr{old}{new} replace surround      e.g. sr"'   -> swap " for '
-- sf           find surrounding ->
-- sF           find surrounding <-
-- sh           highlight surrounding
--
-- Supported pairs: () [] {} <> "" '' `` and tags t

local ok, surround = pcall(require, "mini.surround")
if not ok then return end

surround.setup({
  -- Number of lines within which surrounding is searched
  n_lines = 20,

  -- Highlight duration (ms)
  highlight_duration = 500,

  -- Standard surround mappings
  mappings = {
    add            = "sa",
    delete         = "sd",
    replace        = "sr",
    find           = "sf",
    find_left      = "sF",
    highlight      = "sh",
    update_n_lines = "sn",
  },

  -- Surrounding spec: custom pairs beyond the built-in defaults
  custom_surroundings = nil,

  -- Respect user mappings — don't create default which-key groups
  silent = false,
})
