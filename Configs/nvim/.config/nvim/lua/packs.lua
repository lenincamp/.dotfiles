-- Plugin registry.
-- To add a plugin:
--   1. Add "user/repo" (or a full URL) to M.list below.
--   2. Run :PackInstall, or restart on Neovim 0.12+ to let vim.pack install it.
--   3. Restart nvim.
--
-- Entry formats:
--   "user/repo"                  → GitHub shorthand; dir name = repo name
--   "https://host.tld/user/repo" → full URL for non-GitHub hosts
--   { "dir-name", "origin" }     → explicit dir when repo name ≠ intended dir

local M = {}

M.list = {
  "mrjones2014/smart-splits.nvim",
  -- Core dependencies
  "nvim-lua/plenary.nvim",
  "MunifTanjim/nui.nvim",
  -- LSP + completion
  "neovim/nvim-lspconfig",
  "saghen/blink.lib",
  "saghen/blink.cmp",
  "fang2hou/blink-copilot",                               -- Copilot source for blink.cmp
  "echasnovski/mini.snippets",
  "rafamadriz/friendly-snippets",
  -- Syntax + Markdown
  "nvim-treesitter/nvim-treesitter",
  "nvim-treesitter/nvim-treesitter-textobjects",          -- ]f/[f/]c/[c + af/if text objects
  "nvim-treesitter/nvim-treesitter-context",              -- sticky context header
  "MeanderingProgrammer/render-markdown.nvim",
  -- Colorscheme
  { "catppuccin", "catppuccin/nvim" },                    -- repo name ≠ dir name
  "ellisonleao/gruvbox.nvim",
  "craftzdog/solarized-osaka.nvim",
  "folke/tokyonight.nvim",
  { "kanagawa.nvim", "rebelot/kanagawa.nvim" },
  { "rose-pine", "rose-pine/neovim" },
  "scottmckendry/cyberdream.nvim",
  -- UI
  "folke/snacks.nvim",
  "shortcuts/no-neck-pain.nvim",
  "echasnovski/mini.icons",                               -- filetype icons (snacks picker)
  "echasnovski/mini.clue",                                -- keymap hints (replaces which-key)
  "echasnovski/mini.pairs",                               -- auto-close brackets
  "echasnovski/mini.indentscope",                         -- animated indent scope indicator
  "nvim-lualine/lualine.nvim",                            -- winbar/statusline framework
  -- Git
  "lewis6991/gitsigns.nvim",
  -- Editing
  "folke/flash.nvim",                                     -- jump/search (s/S treesitter, r remote flash)
  "echasnovski/mini.surround",                            -- surround ops: add/delete/replace (gz prefix)
  "mg979/vim-visual-multi",                               -- multi-cursor (<C-n>, <C-Up/Down>)
  "folke/ts-comments.nvim",                               -- treesitter-aware commentstring (JSX/TSX)
  "folke/todo-comments.nvim",                             -- TODO/FIXME/HACK/NOTE highlighting
  -- Tools
  "mason-org/mason.nvim",
  "stevearc/conform.nvim",
  -- Java
  "mfussenegger/nvim-jdtls",
  "https://gitlab.com/schrieveslaach/sonarlint.nvim",     -- on-demand static analysis (<leader>uS)
  -- Salesforce (loaded on demand when sfdx-project.json detected)
  "jonathanmorris180/salesforce.nvim",
  -- Sessions
  "folke/persistence.nvim",                               -- per-cwd save/restore (<leader>p*)
  -- Debug
  "mfussenegger/nvim-dap",
  "igorlfs/nvim-dap-view",                                -- DAP UI (replaces nvim-dap-ui + nvim-nio)
  -- AI
  "zbirenbaum/copilot.lua",
  "copilotlsp-nvim/copilot-lsp",
  "yetone/avante.nvim",
}

-- Returns the pack directory name for an entry.
-- String: last path segment ("folke/snacks.nvim" → "snacks.nvim").
-- Table: explicit first field ({ "catppuccin", "catppuccin/nvim" } → "catppuccin").
function M.name(p)
  if type(p) == "table" then return p[1] end
  return (p:match("[^/]+$") or p):gsub("%.git$", "")
end

-- Returns the clone origin for an entry (full URL or "user/repo" shorthand).
function M.origin(p)
  return type(p) == "table" and p[2] or p
end

function M.url(p)
  local origin = M.origin(p)
  return origin:match("^https?://") and origin or ("https://github.com/" .. origin)
end

function M.spec(p)
  return { name = M.name(p), src = M.url(p) }
end

function M.specs(list)
  local specs = {}
  for _, pack in ipairs(list or M.list) do
    table.insert(specs, M.spec(pack))
  end
  return specs
end

return M
