-- snacks.nvim: enable all modules used by this config.
-- Includes LazyVim-compatible Snacks.toggle keymaps for UI options.

local ok, Snacks = pcall(require, "snacks")
if not ok then return end

-- Keep Snacks.words available for [[/]] but off by default.
vim.g.snacks_words = false

Snacks.setup({
  -- ── Dashboard ─────────────────────────────────────────────────────────────
  dashboard = {
    enabled  = true,
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      { section = "recent_files", indent = 2, padding = 1, limit = 5 },
    },
    preset = {
      keys = {
        { icon = " ", key = "f", desc = "Find File",
          action = ":lua Snacks.picker.files()" },
        { icon = " ", key = "r", desc = "Recent Files",
          action = ":lua Snacks.picker.recent()" },
        { icon = " ", key = "g", desc = "Search in Files",
          action = ":lua Snacks.picker.grep()" },
        { icon = " ", key = "s", desc = "Restore Session",
          action = function()
            local ok_p, p = pcall(require, "persistence")
            if ok_p then p.load() end
          end },
        { icon = " ", key = "n", desc = "New File",
          action = ":ene | startinsert" },
        { icon = " ", key = "q", desc = "Quit",
          action = ":qa" },
      },
    },
  },

  explorer  = { enabled = true },
  picker    = {
    enabled = true,

    -- ── Named layouts ──────────────────────────────────────────────────────────
    -- Reference by name with layout = "intellij_grep" or via <a-l> toggle.
    layouts = {
      intellij_grep = {
        layout = {
          backdrop  = false,
          width     = 0.85,
          min_width = 100,
          height    = 0.8,
          box       = "vertical",
          border    = true,
          title     = "{title} {live} {flags}",
          title_pos = "center",
          { win = "input",   height = 1, border = "bottom" },
          { win = "list",    height = 5, border = "none" },
          { win = "preview", title = "{preview}", flex = 1, border = "top" },
        },
      },
    },

    -- ── Custom actions ─────────────────────────────────────────────────────────
    actions = {
      -- Sidekick: send picker context to the CLI with <Alt-a>
      sidekick_send = function(...)
        local ok_cli, cli = pcall(require, "sidekick.cli.picker.snacks")
        if ok_cli then return cli.send(...) end
      end,
      -- Toggle between default and IntelliJ grep layout with <Alt-l>
      grep_layout_toggle = function(picker)
        local acts = require("snacks.picker.actions")
        if picker._intellij_layout then
          acts.layout(picker, nil, { action = "layout", layout = "default" })
          picker._intellij_layout = false
        else
          acts.layout(picker, nil, { action = "layout", layout = "intellij_grep" })
          picker._intellij_layout = true
        end
      end,
    },

    -- ── Key bindings ───────────────────────────────────────────────────────────
    win = {
      input = {
        keys = {
          ["<a-a>"] = { "sidekick_send",      mode = { "n", "i" } },
          ["<a-l>"] = { "grep_layout_toggle", mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<a-l>"] = "grep_layout_toggle",
        },
      },
    },
  },
  notifier  = { enabled = true },
  bigfile   = { enabled = true },
  quickfile = { enabled = true },
  lazygit   = { enabled = true },
  terminal  = { enabled = true },
  toggle    = { enabled = true },
  bufdelete = { enabled = true },
  gitbrowse = { enabled = true },
  zen       = { enabled = true },
  dim       = { enabled = true },
  statuscolumn = { enabled = false }, -- using custom statusline
  words        = { enabled = true },   -- highlight + navigate word references ([[/]])
})

-- ── UI toggles (LazyVim-compatible Snacks.toggle keymaps) ────────────────────

Snacks.toggle.option("spell",          { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap",           { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.dim():map("<leader>uD")
Snacks.toggle.zen():map("<leader>uz")
Snacks.toggle.zoom():map("<leader>uZ"):map("<leader>wm")

if vim.lsp.inlay_hint then
  Snacks.toggle.inlay_hints():map("<leader>uh")
end

-- Format toggle (global / buffer)
Snacks.toggle({
  name = "Format on Save (global)",
  get  = function() return vim.g.autoformat ~= false end,
  set  = function(v) vim.g.autoformat = v end,
}):map("<leader>uf")

Snacks.toggle({
  name = "Format on Save (buffer)",
  get  = function() return vim.b.autoformat ~= false end,
  set  = function(v) vim.b.autoformat = v end,
}):map("<leader>uF")

-- Cmdline info toggle: ruler (Top/line,col) + showcmd (partial keys) + showmode
-- Off by default (set in configs.lua); winbar already shows line:col.
Snacks.toggle({
  name = "Cmdline Info (ruler/showcmd)",
  get  = function() return vim.o.ruler end,
  set  = function(v)
    vim.o.ruler    = v
    vim.o.showcmd  = v
    vim.o.showmode = v
  end,
}):map("<leader>ui")

-- Colorscheme picker (<leader>uC — consistent with LazyVim)
vim.keymap.set("n", "<leader>uC", function() Snacks.picker.colorschemes() end,
  { desc = "Colorscheme" })
