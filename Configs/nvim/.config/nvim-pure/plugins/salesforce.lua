-- Salesforce development: apex, LWC, VisualForce, SOQL/SOSL.
-- Loaded ONLY when sfdx-project.json is detected in the project root.
-- Uses salesforce.nvim for org operations, tests, logs and component creation.
-- LSP servers (apex_ls, lwc_ls, visualforce_ls) are always enabled via lsp.lua
-- but only attach when sfdx-project.json is in the root.
--
-- Keymaps (all under <leader>S — Salesforce, like <leader>J for Java):
--   <leader>Sx  Execute anonymous Apex
--   <leader>Sp  Push file to org
--   <leader>Sr  Retrieve file from org
--   <leader>Sd  Diff with org
--   <leader>So  Set default org
--   <leader>Si  Refresh org info
--   <leader>Sl  View debug logs (tail in terminal)
--   <leader>SL  Toggle log file debug
--   <leader>Sc  Create LWC component
--   <leader>Sa  Create Apex class/trigger
-- Tests (also in <leader>t group):
--   <leader>ta  Apex: run test method (nearest)
--   <leader>tA  Apex: run test class

-- Only load in Salesforce projects
local is_sf = vim.fn.findfile("sfdx-project.json", vim.fn.getcwd() .. ";") ~= ""
if not is_sf then return end

vim.cmd.packadd("salesforce.nvim")
local ok, salesforce = pcall(require, "salesforce")
if not ok then return end

salesforce.setup({
  default_org    = "",     -- set via <leader>So
  popup_style    = {
    border = "rounded",
    width  = 80,
    height = 30,
  },
  enable_logging = false,  -- no auto-logging; toggle with <leader>SL
})

local map = vim.keymap.set

-- ── Org operations (<leader>S) ────────────────────────────────────────────────

map("n", "<leader>Sx", "<Cmd>SalesforceExecuteFile<CR>",          { desc = "SF: Execute anonymous Apex" })
map("n", "<leader>Sp", "<Cmd>SalesforcePushToOrg<CR>",            { desc = "SF: Push to org" })
map("n", "<leader>Sr", "<Cmd>SalesforceRetrieveFromOrg<CR>",      { desc = "SF: Retrieve from org" })
map("n", "<leader>Sd", "<Cmd>SalesforceDiffFile<CR>",             { desc = "SF: Diff with org" })
map("n", "<leader>So", "<Cmd>SalesforceSetDefaultOrg<CR>",        { desc = "SF: Set default org" })
map("n", "<leader>Si", "<Cmd>SalesforceRefreshOrgInfo<CR>",       { desc = "SF: Refresh org info" })
map("n", "<leader>SL", "<Cmd>SalesforceToggleLogFileDebug<CR>",   { desc = "SF: Toggle log file debug" })
map("n", "<leader>Sc", "<Cmd>SalesforceCreateLightningComponent<CR>", { desc = "SF: Create LWC component" })
map("n", "<leader>Sa", "<Cmd>SalesforceCreateApex<CR>",           { desc = "SF: Create Apex class/trigger" })

-- ── Salesforce debug logs ─────────────────────────────────────────────────────
-- Opens a terminal tailing the latest debug log via sf CLI

map("n", "<leader>Sl", function()
  local sf = vim.fn.exepath("sf") ~= "" and "sf" or "sfdx"
  vim.cmd("botright 20split | terminal " .. sf
    .. " apex tail log --color 2>&1")
  vim.cmd("norm G")
end, { desc = "SF: Tail debug log" })

-- ── Apex tests (also bound in <leader>t for unified test group) ───────────────

map("n", "<leader>ta", "<Cmd>SalesforceExecuteCurrentMethod<CR>",
  { desc = "Test: Apex method (nearest)" })
map("n", "<leader>tA", "<Cmd>SalesforceExecuteCurrentClass<CR>",
  { desc = "Test: Apex class" })

-- ── Notify that Salesforce mode is active ────────────────────────────────────

vim.notify("Salesforce project detected — <leader>S* enabled", vim.log.levels.INFO)
