-- nvim-dap-view: lightweight DAP UI (replaces nvim-dap-ui + nvim-nio).
-- Registers its own DAP listeners automatically on require().

local ok, dv = pcall(require, "dap-view")
if not ok then return end

local helpers = require("dap_helpers")

dv.setup({
  auto_toggle  = true,
  winbar       = {
    sections   = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "sessions", "console" },
    default_section = "scopes",
  },
  windows      = {
    size       = 12,
    position   = "below",
    terminal   = {
      position = "left",
      hide     = {},
    },
  },
  render = {
    breakpoints = {
      format = function(line, lnum, path)
        local icon = helpers.bp_icon_for(lnum, path)
        return {
          { text = icon,                  hl = "DapBreakpoint", separator = " " },
          { text = helpers.short_path(path), hl = "FileName" },
          { text = lnum,                  hl = "LineNumber" },
          { text = line,                  hl = true },
        }
      end,
      align = true,
    },
  },
})

-- ── Thread-sync patches ──────────────────────────────────────────────────────

local thread_sync = require("dap_thread_sync")
thread_sync.apply()
thread_sync.register_diag_command()

-- ── DAP-view buffer options ──────────────────────────────────────────────────

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dap-view",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.cursorline = false
  end,
})