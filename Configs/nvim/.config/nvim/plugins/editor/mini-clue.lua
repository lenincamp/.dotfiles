-- mini.clue: key clue popup showing available keymaps after prefix keys.

local ok, clue = pcall(require, "mini.clue")
if not ok then return end

-- ── Triggers: prefix keys that activate mini-clue popup ─────────────────────

local triggers = {
  { mode = "n", keys = "<Leader>" },
  { mode = "x", keys = "<Leader>" },
  { mode = "n", keys = "g" },
  { mode = "x", keys = "g" },
  { mode = "n", keys = "s" },
  { mode = "x", keys = "s" },
  { mode = "o", keys = "s" },
  { mode = "n", keys = "z" },
  { mode = "n", keys = "[" },
  { mode = "n", keys = "]" },
}

-- ── Group clues: submenu labels (desc starts with "+") ──────────────────────

local group_clues = {
  { mode = "n", keys = "<Leader>a", desc = "+AI" },
  { mode = "x", keys = "<Leader>a", desc = "+AI" },
  { mode = "n", keys = "<Leader>am", desc = "+Minuet/NES" },
  { mode = "n", keys = "<Leader>b", desc = "+Buffers" },
  { mode = "n", keys = "<Leader>c", desc = "+Code" },
  { mode = "x", keys = "<Leader>c", desc = "+Code" },
  { mode = "n", keys = "<Leader>d", desc = "+Debug" },
  { mode = "x", keys = "<Leader>d", desc = "+Debug" },
  { mode = "n", keys = "<Leader>D", desc = "+Database" },
  { mode = "n", keys = "<Leader>f", desc = "+Files/Terminal" },
  { mode = "n", keys = "<Leader>g", desc = "+Git" },
  { mode = "x", keys = "<Leader>g", desc = "+Git" },
  { mode = "n", keys = "<Leader>J", desc = "+Java" },
  { mode = "x", keys = "<Leader>J", desc = "+Java" },
  { mode = "n", keys = "<Leader>Jd", desc = "+Decompiled Jars" },
  { mode = "n", keys = "<Leader>Je", desc = "+Escape/Extract" },
  { mode = "x", keys = "<Leader>Je", desc = "+Escape/Extract" },
  { mode = "n", keys = "<Leader>Jt", desc = "+Tools/Spring" },
  { mode = "n", keys = "<Leader>m", desc = "+MyBatis" },
  { mode = "n", keys = "<Leader>p", desc = "+Project/Sessions" },
  { mode = "n", keys = "<Leader>q", desc = "+Quit" },
  { mode = "n", keys = "<Leader>r", desc = "+Refactor" },
  { mode = "x", keys = "<Leader>r", desc = "+Refactor" },
  { mode = "n", keys = "<Leader>s", desc = "+Search" },
  { mode = "x", keys = "<Leader>s", desc = "+Search" },
  { mode = "n", keys = "<Leader>S", desc = "+Salesforce" },
  { mode = "n", keys = "<Leader>t", desc = "+Tests" },
  { mode = "n", keys = "<Leader>u", desc = "+UI" },
  { mode = "n", keys = "<Leader>w", desc = "+Windows" },
  { mode = "n", keys = "<Leader>x", desc = "+Lists" },
  { mode = "n", keys = "<Leader><Tab>", desc = "+Tabs" },
  { mode = "n", keys = "gc", desc = "+Comment" },
  { mode = "n", keys = "gp", desc = "+Quick Preview" },
  { mode = "n", keys = "s", desc = "+Surround/Flash" },
  { mode = "x", keys = "s", desc = "+Surround/Flash" },
  { mode = "o", keys = "s", desc = "+Surround/Flash" },
}

clue.setup({
  triggers = triggers,
  clues = {
    group_clues,
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
  },
  window = {
    delay = 300,
    config = {
      width = "auto",
      border = "rounded",
    },
  },
})

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyLoad",
  desc = "Refresh mini.clue triggers after lazy-loaded plugins",
  callback = function()
    vim.schedule(function()
      local ok_clue, mini_clue = pcall(require, "mini.clue")
      if ok_clue then
        mini_clue.ensure_buf_triggers()
      end
    end)
  end,
})
