-- Plugin specs for lazy.nvim.
-- Replaces: packs.lua, pack_manager/, modules/plugins/, lazy_keymaps, warmup.

local conf = vim.fn.stdpath("config") .. "/plugins"

local function cfg(path)
  return function() dofile(conf .. "/" .. path) end
end

-- Diff startup detection (block DAP in diff mode)
local diff_startup = vim.tbl_contains(vim.v.argv or {}, "-d")
local function not_diff() return not diff_startup and not vim.opt.diff:get() end

-- Theme specs owned by colorscheme-sync (loaded on demand via require("lazy").load)
local csync_themes = dofile(vim.fn.expand("~/workspace/plugins/colorscheme-sync.nvim/lua/colorscheme-sync/lazy_themes.lua"))

return vim.list_extend(csync_themes, {
  -- ── Core dependencies ───────────────────────────────────────────────────────
  { "nvim-lua/plenary.nvim", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    dir = "~/workspace/plugins/picker.nvim",
    name = "picker.nvim",
    lazy = false,
    dependencies = { "preview.nvim" },
    config = cfg("editor/picker.lua"),
  },
  {
    dir = "~/workspace/plugins/preview.nvim",
    name = "preview.nvim",
    lazy = false,
  },

  -- ── Treesitter ──────────────────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cond = not_diff,
    config = cfg("syntax/nvim-treesitter.lua"),
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    cond = not_diff,
    config = cfg("syntax/treesitter-context.lua"),
  },

  -- ── Colorscheme ─────────────────────────────────────────────────────────────
  {
    dir = "~/workspace/plugins/colorscheme-sync.nvim",
    name = "colorscheme-sync.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local csync = require("colorscheme-sync")
      if not csync._initialized then csync.setup({ system_sync = true }) end
      local target = csync.current_theme(vim.g.pure_colorscheme)
      csync.apply(target, { notify = false, sync_external = "defer" })
    end,
  },

  -- ── Completion ──────────────────────────────────────────────────────────────
  { "saghen/blink.lib", lazy = true },
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    cond = not_diff,
    dependencies = { "saghen/blink.lib", "milanglacier/minuet-ai.nvim", "rafamadriz/friendly-snippets" },
    config = cfg("editor/blink-cmp.lua"),
  },
  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    cond = not_diff,
    config = cfg("ai/minuet.lua"),
  },
  { "rafamadriz/friendly-snippets", lazy = true },

  -- ── Database ────────────────────────────────────────────────────────────────
  { "tpope/vim-dadbod", lazy = true },
  { "kristijanhusak/vim-dadbod-completion", lazy = true },
  {
    "kristijanhusak/vim-dadbod-ui",
    keys = {
      { "<leader>Du", desc = "Dadbod: toggle UI" },
      { "<leader>Df", desc = "Dadbod: find buffer" },
      { "<leader>Da", desc = "Dadbod: add connection" },
      { "<leader>Dr", desc = "Dadbod: rename buffer" },
    },
    cmd = { "DB", "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer",
      "DBUIRenameBuffer", "DBUIDeleteBuffer", "DBUILastQueryInfo" },
    dependencies = { "tpope/vim-dadbod", "kristijanhusak/vim-dadbod-completion" },
    config = cfg("editor/dadbod.lua"),
  },

  -- ── Markdown rendering ──────────────────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante" },
    config = cfg("editor/render-markdown.lua"),
  },

  -- ── UI ──────────────────────────────────────────────────────────────────────
  {
    "shortcuts/no-neck-pain.nvim",
    cmd = { "NoNeckPain", "NoNeckPainResize", "NoNeckPainToggleSide" },
    config = cfg("editor/no-neck-pain.lua"),
  },

  -- ── Git ─────────────────────────────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = cfg("git/gitsigns.lua"),
  },

  -- ── Editing ─────────────────────────────────────────────────────────────────
  {
    "folke/flash.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cond = not_diff,
    config = cfg("motions/flash.lua"),
  },
  {
    "echasnovski/mini.clue",
    event = { "BufReadPost", "BufNewFile" },
    cond = not_diff,
    config = cfg("editor/mini-clue.lua"),
  },
  {
    "echasnovski/mini.surround",
    event = { "BufReadPost", "BufNewFile" },
    cond = not_diff,
    config = cfg("editor/mini-surround.lua"),
  },
  {
    "folke/ts-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cond = not_diff,
    config = function() require("ts-comments").setup() end,
  },

  -- ── Tools ───────────────────────────────────────────────────────────────────
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    config = cfg("lsp/mason.lua"),
  },
  -- ── LSP Navigation ──────────────────────────────────────────────────────
  {
    dir = "~/workspace/plugins/lsp-nav.nvim",
    name = "lsp-nav.nvim",
    event = "LspAttach",
    config = function() require("lsp-nav").setup({}) end,
  },
  -- ── Java ────────────────────────────────────────────────────────────────────
  { "mfussenegger/nvim-jdtls", ft = "java" },
  { dir = "~/workspace/plugins/jdtls.nvim", name = "jdtls.nvim", ft = "java" },
  {
    dir = "~/workspace/plugins/mybatis.nvim",
    name = "mybatis.nvim",
    ft = { "java", "xml" },
    config = function() require("mybatis").setup() end,
  },

  -- ── Salesforce ──────────────────────────────────────────────────────────────
  {
    "jonathanmorris180/salesforce.nvim",
    ft = { "apex", "visualforce", "html", "javascript" },
    cond = function()
      return vim.fn.findfile("sfdx-project.json", vim.fn.getcwd() .. ";") ~= ""
    end,
    config = cfg("language/salesforce.lua"),
  },

  -- ── Debug ───────────────────────────────────────────────────────────────────
  {
    dir = "~/workspace/plugins/dap-controls.nvim",
    name = "dap-controls.nvim",
    lazy = true,
    cond = not_diff,
    dependencies = { "breakpoints.nvim", "picker.nvim" },
  },
  {
    "mfussenegger/nvim-dap",
    keys = require("dap-controls.keymaps").lazy_keys(),
    cmd = { "DapContinue", "DapRunToCursor", "DapStepInto", "DapStepOut",
      "DapStepOver", "DapPause", "DapToggleBreakpoint", "DapSetLogPoint",
      "DapClearBreakpoints", "DapTerminate", "DapDisconnect", "DapRestartFrame", "DapEval" },
    cond = not_diff,
    dependencies = { "igorlfs/nvim-dap-view", "breakpoints.nvim", "dap-controls.nvim" },
    config = cfg("debug/nvim-dap.lua"),
  },
  {
    "igorlfs/nvim-dap-view",
    cmd = { "DapViewOpen", "DapViewClose", "DapViewToggle", "DapViewWatch", "DapViewNavigate" },
    cond = not_diff,
    dependencies = { "dap-controls.nvim" },
    config = cfg("debug/nvim-dap-view.lua"),
  },
  {
    dir = "~/workspace/plugins/breakpoints.nvim",
    name = "breakpoints.nvim",
    lazy = true,
    cond = not_diff,
  },

  -- ── AI ──────────────────────────────────────────────────────────────────────
  {
    "yetone/avante.nvim",
    keys = {
      { "<leader>aa", mode = { "n", "x" } }, { "<leader>at" }, { "<leader>ae", mode = { "n", "x" } },
      { "<leader>an" }, { "<leader>ah" }, { "<leader>aS" }, { "<leader>ar" },
      { "<leader>af" }, { "<leader>a?" }, { "<leader>aM" }, { "<leader>aP" },
      { "<leader>aC" }, { "<leader>aR" }, { "<leader>ac" }, { "<leader>aB" }, { "<leader>az" },
    },
    cmd = { "AvanteAsk", "AvanteChat", "AvanteToggle" },
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    config = cfg("ai/avante.lua"),
  },

})
