-- mini.pairs: auto-close brackets, quotes, etc.
-- Enabled only in insert mode; command/terminal modes left alone.

local ok, pairs = pcall(require, "mini.pairs")
if not ok then return end

pairs.setup({
  modes = { insert = true, command = false, terminal = false },

  -- Pairs to auto-close (default set covers most cases)
  mappings = {
    ["("]  = { action = "open",  pair = "()",  neigh_pattern = "[^\\]." },
    ["["]  = { action = "open",  pair = "[]",  neigh_pattern = "[^\\]." },
    ["{"]  = { action = "open",  pair = "{}",  neigh_pattern = "[^\\]." },
    [")"]  = { action = "close", pair = "()",  neigh_pattern = "[^\\]." },
    ["]"]  = { action = "close", pair = "[]",  neigh_pattern = "[^\\]." },
    ["}"]  = { action = "close", pair = "{}",  neigh_pattern = "[^\\]." },
    ['"']  = { action = "closeopen", pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
    ["'"]  = { action = "closeopen", pair = "''", neigh_pattern = "[^%a\\].", register = { cr = false } },
    ["`"]  = { action = "closeopen", pair = "``", neigh_pattern = "[^\\].",   register = { cr = false } },
  },
})
