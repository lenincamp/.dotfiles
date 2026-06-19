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
  -- Core dependencies
  "nvim-lua/plenary.nvim",
  "MunifTanjim/nui.nvim",
  -- LSP + completion
  "saghen/blink.lib",
  "saghen/blink.cmp",
  "milanglacier/minuet-ai.nvim",                          -- Claude/LLM source for blink.cmp + inline suggestions
  "tpope/vim-dadbod",
  "kristijanhusak/vim-dadbod-ui",
  "kristijanhusak/vim-dadbod-completion",
  "rafamadriz/friendly-snippets",
  -- Syntax + Markdown
  "nvim-treesitter/nvim-treesitter",
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
  "shortcuts/no-neck-pain.nvim",
  -- Git
  "lewis6991/gitsigns.nvim",
  -- Editing
  "folke/flash.nvim",                                     -- jump/search (s/S treesitter, r remote flash)
  "echasnovski/mini.surround",                            -- surround ops: add/delete/replace (gz prefix)
  "folke/ts-comments.nvim",                               -- treesitter-aware commentstring (JSX/TSX)
  -- Tools
  "mason-org/mason.nvim",
  -- Java
  "mfussenegger/nvim-jdtls",
  -- Salesforce (loaded on demand when sfdx-project.json detected)
  "jonathanmorris180/salesforce.nvim",
  -- Debug
  "mfussenegger/nvim-dap",
  "igorlfs/nvim-dap-view",                                -- DAP UI (replaces nvim-dap-ui + nvim-nio)
  -- AI
  "yetone/avante.nvim",
}

-- Returns the pack directory name for an entry.
-- String: last path segment ("user/example.nvim" -> "example.nvim").
-- Table: explicit first field ({ "catppuccin", "catppuccin/nvim" } → "catppuccin").
function M.name(p)
  if type(p) == "table" then return p[1] end
  local name = (p:match("[^/]+$") or p):gsub("%.git$", "")
  return name
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
