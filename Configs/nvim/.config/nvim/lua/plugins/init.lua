-- Plugin specs for lazy.nvim.
-- Personal plugins: GitHub (lenincamp/*) by default; local dev via vim.g.pure_local_plugins in init.lua.

local conf = vim.fn.stdpath("config") .. "/plugins"
local ps = require("config.plugins_source")

local function cfg(path)
  return function()
    dofile(conf .. "/" .. path)
  end
end

local function p(repo, name, opts)
  return ps.spec(repo, name, opts)
end

local function lazy_keys(name, relpath)
  local mod = ps.dofile_lua(name, relpath)
  return (mod and mod.lazy_keys) and mod.lazy_keys() or {}
end

local diff_startup = vim.tbl_contains(vim.v.argv or {}, "-d")
local function not_diff()
  return not diff_startup and not vim.opt.diff:get()
end

local csync_themes = ps.dofile_lua("colorscheme-sync.nvim", "lua/colorscheme-sync/lazy_themes.lua") or {}

return vim.list_extend(csync_themes, {
  { "nvim-lua/plenary.nvim", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },
  p("lenincamp/picker.nvim", "picker.nvim", {
    lazy = true,
    dependencies = { "preview.nvim" },
    keys = lazy_keys("picker.nvim", "lua/picker/user_keymaps.lua"),
    config = cfg("editor/picker.lua"),
  }),
  p("lenincamp/preview.nvim", "preview.nvim", {
    lazy = true,
  }),
  p("lenincamp/pure-ui.nvim", "pure-ui.nvim", {
    lazy = false,
    dependencies = { "colorscheme-sync.nvim" },
    config = function()
      require("pure-ui").setup()
    end,
  }),

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
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    cond = not_diff,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = cfg("syntax/treesitter-textobjects.lua"),
  },

  p("lenincamp/colorscheme-sync.nvim", "colorscheme-sync.nvim", {
    lazy = false,
    priority = 1000,
    config = function()
      local csync = require("colorscheme-sync")
      if not csync._initialized then
        csync.setup({
          system_sync = true,
          delta_config_path = vim.fn.expand("~/.dotfiles/Configs/gitconfig/delta-generated.gitconfig"),
        })
      end
      local target = csync.current_theme(vim.g.pure_colorscheme)
      csync.apply(target, { notify = false, sync_external = "defer" })
    end,
  }),

  { "saghen/blink.lib", lazy = true },
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    cond = not_diff,
    dependencies = {
      "saghen/blink.lib",
      "Kaiser-Yang/blink-cmp-avante",
      "milanglacier/minuet-ai.nvim",
      "rafamadriz/friendly-snippets",
      "mayromr/blink-cmp-dap",
    },
    build = function()
      -- build the fuzzy matcher, optionally add a timeout to `pwait(timeout_ms)`
      -- you can use `gb` in `:Lazy` to rebuild the plugin as needed
      require("blink.cmp").build():pwait()
    end,
    config = cfg("editor/blink-cmp.lua"),
  },
  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    cond = not_diff,
    config = cfg("ai/minuet.lua"),
  },
  { "rafamadriz/friendly-snippets", lazy = true },

  { "tpope/vim-obsession", lazy = true, cmd = "Obsession" },
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
    cmd = {
      "DB",
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
      "DBUIRenameBuffer",
      "DBUIDeleteBuffer",
      "DBUILastQueryInfo",
    },
    dependencies = { "tpope/vim-dadbod", "kristijanhusak/vim-dadbod-completion" },
    config = cfg("editor/dadbod.lua"),
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante" },
    config = cfg("editor/render-markdown.lua"),
  },

  {
    "shortcuts/no-neck-pain.nvim",
    cmd = { "NoNeckPain", "NoNeckPainResize", "NoNeckPainToggleSide" },
    config = cfg("editor/no-neck-pain.lua"),
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = cfg("git/gitsigns.lua"),
  },

  {
    "folke/flash.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cond = not_diff,
    config = cfg("motions/flash.lua"),
  },
  {
    "echasnovski/mini.clue",
    event = "VeryLazy",
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
    config = function()
      require("ts-comments").setup()
    end,
  },

  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    config = cfg("lsp/mason.lua"),
  },
  p("lenincamp/lsp-nav.nvim", "lsp-nav.nvim", {
    lazy=true,
    event = "LspAttach",
    config = function()
      require("lsp-nav").setup({})
    end,
  }),

  { "mfussenegger/nvim-jdtls", ft = "java" },
  p("lenincamp/jdtls.nvim", "jdtls.nvim", {
    ft = "java",
    dependencies = { "nvim-jdtls" },
    config = cfg("lsp/jdtls.lua"),
  }),
  p("lenincamp/mybatis.nvim", "mybatis.nvim", {
    ft = { "java", "xml" },
    config = function()
      require("mybatis").setup()
    end,
  }),

  {
    "nvim-neotest/neotest",
    name = "neotest",
    lazy = true,
    cond = not_diff,
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "marilari88/neotest-vitest",
      "haydenmeade/neotest-jest",
    },
    config = function()
      require("config.test").setup()
    end,
  },

  {
    "jonathanmorris180/salesforce.nvim",
    ft = { "apex", "visualforce", "html", "javascript" },
    cond = function()
      return vim.fn.findfile("sfdx-project.json", vim.fn.getcwd() .. ";") ~= ""
    end,
    config = cfg("language/salesforce.lua"),
  },

  p("lenincamp/dap-controls.nvim", "dap-controls.nvim", {
    lazy = true,
    cond = not_diff,
    dependencies = { "breakpoints.nvim", "picker.nvim" },
  }),
  {
    "mfussenegger/nvim-dap",
    keys = lazy_keys("dap-controls.nvim", "lua/dap-controls/keymaps.lua"),
    cmd = {
      "DapContinue",
      "DapRunToCursor",
      "DapStepInto",
      "DapStepOut",
      "DapStepOver",
      "DapPause",
      "DapToggleBreakpoint",
      "DapSetLogPoint",
      "DapClearBreakpoints",
      "DapTerminate",
      "DapDisconnect",
      "DapRestartFrame",
      "DapEval",
    },
    cond = not_diff,
    dependencies = { "igorlfs/nvim-dap-view", "breakpoints.nvim", "dap-controls.nvim" },
    config = cfg("debug/nvim-dap.lua"),
  },
  {
    "igorlfs/nvim-dap-view",
    cmd = { "DapViewOpen", "DapViewClose", "DapViewToggle", "DapViewWatch", "DapViewNavigate" },
    cond = not_diff,
    dependencies = { "dap-controls.nvim" },
    -- Setup via dap-controls in plugins/debug/nvim-dap.lua
  },
  p("lenincamp/breakpoints.nvim", "breakpoints.nvim", {
    lazy = true,
    cond = not_diff,
  }),

  {
    "yetone/avante.nvim",
    build = "make",
    version = false,
    keys = {
      { "<leader>aa", mode = { "n", "x" }, desc = "Avante: ask" },
      { "<leader>at", desc = "Avante: toggle" },
      { "<leader>ae", mode = { "n", "x" }, desc = "Avante: edit" },
      { "<leader>an", desc = "Avante: new chat" },
      { "<leader>ah", desc = "Avante: history" },
      { "<leader>aS", desc = "Avante: stop" },
      { "<leader>ar", desc = "Avante: refresh" },
      { "<leader>af", desc = "Avante: focus" },
      { "<leader>a?", desc = "Avante: select model" },
      { "<leader>aM", desc = "Avante: select ACP model" },
      { "<leader>ai", desc = "Avante: select ACP mode" },
      { "<leader>aP", desc = "Avante: switch provider" },
      { "<leader>aC", desc = "Avante: clear" },
      { "<leader>aR", desc = "Avante: repo map" },
      { "<leader>ac", desc = "Avante: add current buffer" },
      { "<leader>aB", desc = "Avante: add all buffers" },
      { "<leader>az", desc = "Avante: zen mode" },
      { "<leader>ad", desc = "Avante: toggle debug" },
      { "<leader>as", desc = "Avante: toggle suggestion" },
    },
    cmd = { "AvanteAsk", "AvanteChat", "AvanteToggle" },
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    config = cfg("ai/avante.lua"),
  },
  {
    "stevearc/quicker.nvim",
    ft = "qf",
    opts = {},
  },
  {
    "debsishu/floatodo.nvim",
    lazy = true,
    config = function()
      require("floatodo").setup({
        path = "~/todo.md",
        width_percent = 0.8,
        height_percent = 0.8,
        insert_on_open = false,
      })
    end,
  },
})
