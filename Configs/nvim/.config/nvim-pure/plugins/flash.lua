-- flash.nvim: fast jump / search with labels.
-- s  → jump to label        (normal, visual, op-pending)
-- S  → treesitter node jump (normal, op-pending)
-- r  → remote flash         (op-pending: e.g. yr<flash> yanks remote word)
-- R  → treesitter search    (op-pending, visual)
-- <C-s> in search/cmdline → toggle flash on current search

local ok, flash = pcall(require, "flash")
if not ok then return end

flash.setup({
  labels = "asdfghjklqwertyuiopzxcvbnm",
  search = {
    multi_window = true,
    forward      = true,
    wrap         = true,
  },
  jump = {
    jumplist = true,   -- add jump to jumplist so <C-o> goes back
    pos      = "start",
    history  = false,
    register = false,
    nohlsearch = false,
    autojump   = false,
  },
  label = {
    uppercase    = false,
    exclude      = "",
    current      = true,
    after        = true,
    before       = false,
    style        = "overlay",
    reuse        = "lowercase",
    distance     = true,
    min_pattern_length = 0,
    rainbow = { enabled = false },
    format = function(opts)
      return { { opts.match.label, opts.hl_group } }
    end,
  },
  highlight = {
    backdrop = true,
    matches  = true,
    priority = 5000,
    groups = {
      match    = "FlashMatch",
      current  = "FlashCurrent",
      backdrop = "FlashBackdrop",
      label    = "FlashLabel",
    },
  },
  -- Disable in these filetypes (flash would only get in the way)
  modes = {
    search = {
      enabled = true,
      highlight = { backdrop = false },
      jump      = { history = true, register = true, nohlsearch = true },
      search    = { forward = true, wrap = true, multi_window = false },
    },
    char = {
      -- Keep native f/t/F/T behaviour — don't override char motions
      enabled = false,
    },
    treesitter = {
      labels          = "abcdefghijklmnopqrstuvwxyz",
      jump            = { pos = "range" },
      search          = { incremental = false },
      label           = { before = true, after = true, style = "inline" },
      highlight       = { backdrop = false, matches = false },
    },
    treesitter_search = {
      jump    = { pos = "range" },
      search  = { multi_window = true, wrap = true, incremental = false },
      remote_op = { restore = true, motion = true },
      label   = { before = true, after = true, style = "inline" },
    },
  },
  remote_op = { restore = true, motion = true },
})

-- ── Keymaps ───────────────────────────────────────────────────────────────────

local map = vim.keymap.set

-- s — jump forward/backward with labels (replaces the useless `cl`)
map({ "n", "x", "o" }, "s", function() flash.jump() end,
  { desc = "Flash jump" })

-- S — treesitter-aware jump (select by node type)
map({ "n", "o" }, "S", function() flash.treesitter() end,
  { desc = "Flash Treesitter" })

-- r — remote flash: select target, execute operator there, return (op-pending only)
map("o", "r", function() flash.remote() end,
  { desc = "Remote Flash" })

-- R — treesitter search (op-pending + visual)
map({ "o", "x" }, "R", function() flash.treesitter_search() end,
  { desc = "Treesitter Search" })

-- <C-s> in search / command mode → toggle flash highlighting on current search
map("c", "<C-s>", function() flash.toggle() end,
  { desc = "Toggle Flash Search" })
