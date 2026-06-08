-- persistence.nvim: automatic session save/restore per working directory.
-- Sessions are stored in stdpath("data")/sessions/ (one file per cwd path).
-- The snacks dashboard "Restore Session" button auto-detects this plugin.

local ok, persistence = pcall(require, "persistence")
if not ok then return end

persistence.setup({
  dir     = vim.fn.stdpath("data") .. "/sessions/",
  -- Session options: what to persist across restarts
  options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
})

-- ── Keymaps (<leader>p = Project / Sessions) ──────────────────────────────────

local map = vim.keymap.set

map("n", "<leader>ps", function() persistence.save() end,
  { desc = "Session: Save" })

map("n", "<leader>pl", function() persistence.load() end,
  { desc = "Session: Load (cwd)" })

map("n", "<leader>pS", function() persistence.select() end,
  { desc = "Session: Select" })

map("n", "<leader>pd", function() persistence.stop() end,
  { desc = "Session: Stop recording" })
