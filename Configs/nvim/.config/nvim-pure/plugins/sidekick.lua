-- sidekick.nvim: AI-powered CLI assistant + NES (Next Edit Suggestions).
--
-- NES requires the Copilot Language Server (separate from copilot.lua).
-- Install once: :MasonInstall copilot-language-server
-- Then add "copilot_ls" to vim.lsp.enable() in lsp.lua.

local ok, sidekick = pcall(require, "sidekick")
if not ok then return end

sidekick.setup({
  nes = { enabled = true },
})

-- ── NES: <Tab> in normal mode — apply/jump suggestion, else next buffer ───────

vim.keymap.set("n", "<Tab>", function()
  if sidekick.nes_jump_or_apply() then return end
  -- vim.cmd("bn")
end, { noremap = true, desc = "Sidekick NES" })

-- Manual NES controls (mirrors original nvim config)
vim.keymap.set("n", "<leader>an", function()
  local Nes = require("sidekick.nes")
  if Nes.have() then Nes.apply() end
end, { desc = "Sidekick: apply NES" })

vim.keymap.set("n", "<leader>au", function()
  require("sidekick.nes").update()
end, { desc = "Sidekick: fetch NES suggestions" })

-- Toggle NES on/off via snacks toggle
local ok_snacks, Snacks = pcall(require, "snacks")
if ok_snacks and Snacks.toggle then
  Snacks.toggle({
    name = "Sidekick NES",
    get  = function() return require("sidekick.nes").enabled end,
    set  = function(state) require("sidekick.nes").enable(state) end,
  }):map("<leader>uN")
end

-- ── CLI: terminal AI assistant ────────────────────────────────────────────────

local map = vim.keymap.set

-- Open / close in any mode
map({ "n", "t", "i", "x" }, "<C-.>", function()
  require("sidekick.cli").toggle()
end, { desc = "Sidekick: toggle CLI" })

map("n",         "<leader>aa", function() require("sidekick.cli").toggle()        end, { desc = "Sidekick: toggle CLI" })
map("n",         "<leader>as", function() require("sidekick.cli").select()        end, { desc = "Sidekick: select tool" })
map("n",         "<leader>ad", function() require("sidekick.cli").close()         end, { desc = "Sidekick: detach CLI session" })
map({ "n", "x" },"<leader>at", function() require("sidekick.cli").send({ msg = "{this}" })      end, { desc = "Sidekick: send this" })
map("n",         "<leader>af", function() require("sidekick.cli").send({ msg = "{file}" })      end, { desc = "Sidekick: send file" })
map("x",         "<leader>av", function() require("sidekick.cli").send({ msg = "{selection}" }) end, { desc = "Sidekick: send selection" })
map({ "n", "x" },"<leader>ap", function() require("sidekick.cli").prompt()        end, { desc = "Sidekick: select prompt" })
