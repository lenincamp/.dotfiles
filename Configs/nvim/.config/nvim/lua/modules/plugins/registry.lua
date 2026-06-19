local M = {}

M.pack_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt"
M.config_dir = vim.fn.stdpath("config") .. "/plugins"

M.configs = {
  ["avante"] = { path = "ai/avante.lua", packs = { "plenary.nvim", "nui.nvim", "avante.nvim" } },
  ["minuet"] = { path = "ai/minuet.lua", packs = "minuet-ai.nvim" },

  ["catppuccin"] = { path = "colorscheme/catppuccin.lua", packs = "catppuccin" },
  ["gruvbox"] = { path = "colorscheme/gruvbox.lua", packs = "gruvbox.nvim" },
  ["solarized-osaka"] = { path = "colorscheme/solarized-osaka.lua", packs = "solarized-osaka.nvim" },
  ["tokyonight"] = { path = "colorscheme/tokyonight.lua", packs = "tokyonight.nvim" },
  ["kanagawa"] = { path = "colorscheme/kanagawa.lua", packs = "kanagawa.nvim" },
  ["rose-pine"] = { path = "colorscheme/rose-pine.lua", packs = "rose-pine" },
  ["cyberdream"] = { path = "colorscheme/cyberdream.lua", packs = "cyberdream.nvim" },

  ["nvim-dap"] = { path = "debug/nvim-dap.lua", packs = "nvim-dap" },
  ["nvim-dap-view"] = { path = "debug/nvim-dap-view.lua", packs = "nvim-dap-view" },

  ["blink-cmp"] = { path = "editor/blink-cmp.lua", packs = { "blink.lib", "blink.cmp", "minuet-ai.nvim" } },
  ["dadbod"] = { path = "editor/dadbod.lua", packs = { "vim-dadbod", "vim-dadbod-ui", "vim-dadbod-completion" } },
  ["mini-surround"] = { path = "editor/mini-surround.lua", packs = "mini.surround" },
  ["no-neck-pain"] = { path = "editor/no-neck-pain.lua", packs = "no-neck-pain.nvim" },
  ["render-markdown"] = { path = "editor/render-markdown.lua", packs = "render-markdown.nvim" },
  ["ts-comments"] = { path = "editor/ts-comments.lua", packs = "ts-comments.nvim" },

  ["gitsigns"] = { path = "git/gitsigns.lua", packs = "gitsigns.nvim" },

  ["salesforce"] = { path = "language/salesforce.lua", packs = "salesforce.nvim" },

  ["mason"] = { path = "lsp/mason.lua", packs = "mason.nvim" },

  ["flash"] = { path = "motions/flash.lua", packs = "flash.nvim" },

  ["nvim-treesitter"] = { path = "syntax/nvim-treesitter.lua", packs = "nvim-treesitter" },
  ["treesitter-context"] = { path = "syntax/treesitter-context.lua", packs = "nvim-treesitter-context" },
}

M.diff_blocked_configs = {
  ["nvim-dap"] = true,
  ["nvim-dap-view"] = true,
}

M.mason_lazy_commands = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" }

M.dap_core_lazy_commands = {
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
}

M.dap_view_lazy_commands = {
  "DapViewOpen",
  "DapViewClose",
  "DapViewToggle",
  "DapViewWatch",
  "DapViewNavigate",
}

return M
