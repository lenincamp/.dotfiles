-- nvim-dap-view: lightweight DAP UI (replaces nvim-dap-ui + nvim-nio).
-- Registers its own DAP listeners automatically on require().
--
-- Layout tuned for devs coming from IntelliJ / WebStorm / VS Code:
--   • Bottom panel at 28% editor height — matches IntelliJ Debug tool window
--   • Default tab = scopes (Variables), like IntelliJ/VSCode "Variables" pane
--   • Tab order: Variables → Watch → Breakpoints → Call Stack → REPL → Console → Exceptions → Sessions
--     (mirrors IntelliJ tab order; left-to-right = most → least used)
--   • In the dap-view buffer: 1..8 jump to a tab — analogue of IntelliJ Alt+<N>
--   • Tab / Shift-Tab cycle tabs (uses DapViewNavigate)
--   • cursorline ON — easier to track the active variable row
--
-- Adapter coverage for terminal split:
--   • java / kotlin                  → server-side eval, no pty   → hide
--   • apex / apex-replay-debugger    → server-side eval, no pty   → hide
--   • pwa-node                       → Node stdout needs pty      → show
--   • pwa-chrome (React browser)     → no local pty spawned       → show (no-op)
--   Apex Replay Debugger has partial `evaluate` support — floating eval works
--   but `setExpression` is rejected; falls back to evaluate automatically.

local ok, dv = pcall(require, "dap-view")
if not ok then return end

local helpers = require("dap_helpers")

dv.setup({
  auto_toggle = true,
  follow_tab  = true,
  switchbuf   = "usetab,uselast",
  winbar = {
    show              = true,
    show_keymap_hints = true,
    -- IntelliJ-ish order. Console kept; exceptions/sessions pushed to the end.
    sections          = { "scopes", "watches", "breakpoints", "threads", "repl", "console", "exceptions", "sessions" },
    default_section   = "scopes",
    -- Single-key shortcut shown in winbar AND active inside the dap-view buffer.
    -- Numbers mimic IntelliJ Alt+<N> tab switching.
    base_sections = {
      scopes      = { label = "󰫧 Variables",   keymap = "1" },
      watches     = { label = "󰈈 Watch",       keymap = "2" },
      breakpoints = { label = "󰃤 Breakpoints", keymap = "3" },
      threads     = { label = "󱍢 Call Stack",  keymap = "4" },
      repl        = { label = "󰞷 REPL",        keymap = "5" },
      console     = { label = "󰆍 Console",     keymap = "6" },
      exceptions  = { label = "󰀦 Exceptions",  keymap = "7" },
      sessions    = { label = "󰒋 Sessions",    keymap = "8" },
    },
  },
  windows = {
    -- 0..1 = % of editor height; 28% feels right next to a code buffer.
    size     = 0.28,
    position = "below",
    terminal = {
      -- Right-side terminal split keeps program stdout out of REPL/Console rows.
      -- Hide for adapters that don't spawn a local pty (server-side eval).
      size     = 0.4,
      position = "right",
      hide     = { "java", "kotlin", "apex", "apex-replay-debugger" },
    },
  },
  render = {
    breakpoints = {
      format = function(line, lnum, path)
        local icon = helpers.bp_icon_for(lnum, path)
        return {
          { text = icon,                     hl = "DapBreakpoint", separator = " " },
          { text = helpers.short_path(path), hl = "FileName" },
          { text = lnum,                     hl = "LineNumber" },
          { text = line,                     hl = true },
        }
      end,
      align = true,
    },
  },
  -- Inline variable values next to the source line — like IntelliJ "show values inline".
  virtual_text = {
    enabled  = true,
    position = "eol",
  },
})

-- ── Thread-sync patches ──────────────────────────────────────────────────────
local thread_sync = require("dap_thread_sync")
thread_sync.apply()
thread_sync.register_diag_command()

-- ── dap-repl: multi-line paste safety ───────────────────────────────────────
-- DAP `evaluate` is single-line. Pasting multi-line directly into the REPL
-- triggers one `evaluate` call per line → errors. Solution: in dap-repl buffer
-- `p`, `P`, `<C-v>` open the floating eval pre-filled with clipboard contents,
-- so user can review/edit and submit as a single joined expression.
local function open_eval_with_clipboard()
  local helpers_mod = require("dap_helpers")
  local clip = vim.fn.getreg("+")
  if clip == "" or clip == nil then clip = vim.fn.getreg("*") end
  if clip == "" or clip == nil then clip = vim.fn.getreg('"') end
  local lines = vim.split(clip or "", "\n", { plain = true })
  helpers_mod._open_eval_floating(lines, vim.bo.filetype)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dap-repl",
  callback = function(args)
    local opts = { buffer = args.buf, silent = true, desc = "DAP REPL: paste → floating eval" }
    vim.keymap.set("n", "p",     open_eval_with_clipboard, opts)
    vim.keymap.set("n", "P",     open_eval_with_clipboard, opts)
    vim.keymap.set("i", "<C-v>", open_eval_with_clipboard, opts)
    vim.keymap.set("n", "<leader>dE", open_eval_with_clipboard, opts)
  end,
})

-- ── DAP-view buffer options + IDE-style in-panel keys ───────────────────────
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dap-view",
  callback = function(args)
    local opt = vim.opt_local
    opt.number         = false
    opt.relativenumber = false
    opt.cursorline     = true   -- track active row (IntelliJ-style)
    opt.signcolumn     = "no"
    opt.foldcolumn     = "0"
    opt.wrap           = false
    opt.list           = false

    local kmap = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
    end
    kmap("q",       "<cmd>DapViewClose<cr>",        "Debug: Close panel")
    kmap("<Tab>",   "<cmd>DapViewNavigate! 1<cr>",  "Debug: Next tab")
    kmap("<S-Tab>", "<cmd>DapViewNavigate! -1<cr>", "Debug: Prev tab")
  end,
})
