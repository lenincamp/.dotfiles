-- copilot.lua + copilot-lsp: completion backend and NES.

vim.g.copilot_nes_debounce = 500

local ok_copilot_lsp, copilot_lsp = pcall(require, "copilot-lsp")
if ok_copilot_lsp then
  copilot_lsp.setup({
    nes = {
      move_count_threshold = 3,
    },
  })
end

local ok_copilot, copilot = pcall(require, "copilot")
if not ok_copilot then return end

copilot.setup({
  suggestion = { enabled = false },
  panel      = { enabled = false },
--   copilot_model = "gpt-4o-copilot",
  root_dir   = function()
    return vim.fn.getcwd(-1, -1)
  end,
  should_attach = function(bufnr, bufname)
    if not vim.bo[bufnr].buflisted then return false end
    if vim.bo[bufnr].buftype ~= "" then return false end
    if bufname:match("%.env") or bufname:match("/%.env") then return false end
    return true
  end,
  server_opts_overrides = {
    settings = {
      editor = {
        enableAutoCompletions = true,
        showEditorCompletions = true,
        delayCompletions = false,
      },
      advanced = {
        inlineSuggestCount = 3,
        listCount = 10,
      },
    },
  },
  nes = {
    enabled = true,
    keymap = {
      accept_and_goto = "<Tab>",
      accept = false,
      dismiss = "<Esc>",
    },
  },
})