-- Pure Neovim 0.11 package loader.
-- Packages live in: ~/.local/share/nvim-pure/site/pack/core/opt/
-- To add a plugin:
--   git clone --depth 1 https://github.com/USER/REPO \
--     ~/.local/share/nvim-pure/site/pack/core/opt/REPO
-- Then add its name to the packs list below and restart.
--
-- Removed vs original LazyVim setup:
--   nvim-dap-ui + nvim-nio  → nvim-dap-view  (−10 K lines, −2 plugins)
--   which-key.nvim          → mini.clue       (−2.3 K lines)
--   Added: mini.pairs (auto-close brackets)

-- ── Package list ──────────────────────────────────────────────────────────────

local packs = {
  "smart-splits.nvim",
  -- Core dependencies
  "plenary.nvim",
  "nui.nvim",
  -- LSP + completion
  "nvim-lspconfig",
  "blink.cmp",
  "blink-copilot",  -- Copilot source for blink.cmp
  "mini.snippets",
  "friendly-snippets",
  -- Syntax + Markdown
  "nvim-treesitter",
  "nvim-treesitter-textobjects", -- ]f/[f/]c/[c navigation + af/if text objects
  "nvim-treesitter-context",     -- sticky context header (class/function you're in)
  "render-markdown.nvim",
  -- Colorscheme
  "catppuccin",
  -- UI
  "snacks.nvim",
  "mini.icons",     -- file/filetype icons (used by snacks picker)
  "mini.clue",      -- keymap hints (replaces which-key)
  "mini.pairs",     -- auto-close brackets
  -- Git
  "gitsigns.nvim",
  -- Editing
  "flash.nvim",        -- jump/search (s/S treesitter, r remote flash)
  "mini.surround",     -- surround ops: add/delete/replace (gz prefix)
  "vim-visual-multi",  -- multi-cursor (<C-n>, <C-Up/Down>)
  "ts-comments.nvim",  -- treesitter-aware commentstring (JSX/TSX)
  "todo-comments.nvim", -- TODO/FIXME/HACK/NOTE highlighting
  -- Tools
  "mason.nvim",
  "conform.nvim",
  -- Java
  "nvim-jdtls",
  "sonarlint.nvim",  -- on-demand static analysis (<leader>uS)
  -- Salesforce (loaded on demand when sfdx-project.json detected)
  "salesforce.nvim",
  -- Sessions
  "persistence.nvim",  -- per-directory session save/restore (<leader>p*)
  -- Debug
  "nvim-dap",
  "nvim-dap-view",  -- DAP UI (replaces nvim-dap-ui + nvim-nio)
  -- AI
  "copilot.lua",
  "CopilotChat.nvim",
  "sidekick.nvim",
}

-- vim-visual-multi globals must be set BEFORE packadd loads the plugin
local vm_cfg = vim.fn.stdpath("config") .. "/plugins/vim-visual-multi.lua"
if vim.fn.filereadable(vm_cfg) == 1 then pcall(dofile, vm_cfg) end

for _, pack in ipairs(packs) do
  local ok, err = pcall(vim.cmd.packadd, pack)
  if not ok then
    vim.notify("Pack load failed [" .. pack .. "]: " .. tostring(err), vim.log.levels.WARN)
  end
end

-- Generate help tags for all packadd'd plugins (fixes E486 on :help)
vim.cmd("silent! helptags ALL")

-- ── Pack management commands ──────────────────────────────────────────────────

local pack_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt"

vim.api.nvim_create_user_command("PackUpdate", function()
  local dirs = vim.fn.glob(pack_dir .. "/*", false, true)
  local total, done, errors = #dirs, 0, {}
  vim.notify("PackUpdate: updating " .. total .. " plugins…", vim.log.levels.INFO)
  for _, dir in ipairs(dirs) do
    local name = vim.fn.fnamemodify(dir, ":t")
    local update_cmd = {
      "sh", "-c",
      "cd " .. dir .. " && git fetch origin && git reset --hard origin/$(git rev-parse --abbrev-ref origin/HEAD | cut -d'/' -f2)"
    }
    vim.system(update_cmd, { text = true }, function(out)
      done = done + 1
      local ok = out.code == 0
      local msg = ok and "Updated" or vim.trim(out.stderr)
      if not ok then table.insert(errors, name .. ": " .. msg) end
      if done == total then
        vim.schedule(function()
          if #errors == 0 then
            vim.notify("PackUpdate: all " .. total .. " plugins up to date ✓", vim.log.levels.INFO)
          else
            vim.notify("PackUpdate: " .. #errors .. " error(s):\n" .. table.concat(errors, "\n"), vim.log.levels.WARN)
          end
          vim.cmd("silent! helptags ALL")
        end)
      end
    end)
  end
end, { desc = "Git pull all plugins, handling detached HEAD" })

vim.api.nvim_create_user_command("PackList", function()
  local dirs = vim.fn.glob(pack_dir .. "/*", false, true)
  table.sort(dirs)
  local lines = {}
  for _, dir in ipairs(dirs) do
    table.insert(lines, vim.fn.fnamemodify(dir, ":t"))
  end
  vim.notify("Plugins (" .. #lines .. "):\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "List installed plugins" })

-- Mason: initialise before LSP servers can start
local ok_mason, mason = pcall(require, "mason")
if ok_mason then mason.setup() end

-- Fallback: add main nvim's Mason bin to PATH so nvim-pure can reuse installed servers
local main_mason_bin = vim.fn.expand("~/.local/share/nvim/mason/bin")
if vim.fn.isdirectory(main_mason_bin) == 1 and not vim.env.PATH:find(main_mason_bin, 1, true) then
  vim.env.PATH = main_mason_bin .. ":" .. vim.env.PATH
end

-- ── Plugin configs ────────────────────────────────────────────────────────────
-- SYNC: needed before the editor is interactive.
-- DEFERRED: heavy / rarely-needed-at-startup — loaded after event-loop tick.

local conf_dir = vim.fn.stdpath("config") .. "/plugins/"

local function load_cfg(name)
  local path = conf_dir .. name .. ".lua"
  if vim.fn.filereadable(path) == 1 then
    local ok, err = pcall(dofile, path)
    if not ok then
      vim.notify("Plugin config error [" .. name .. "]: " .. tostring(err), vim.log.levels.WARN)
    end
  end
end

local sync_configs = {
  "catppuccin",      -- colorscheme first — highlights must be set before any UI renders
  "blink-cmp",       -- completion + snippet preset (needed from first keystroke)
  "mini-snippets",   -- snippet engine (friendly-snippets)
  "mini-pairs",      -- auto-close brackets
  "mini-icons",      -- filetype icons for snacks picker
  "nvim-treesitter",              -- syntax / indent
  "treesitter-textobjects",       -- ]f/[f/]c/[c navigation + af/if text objects
  "treesitter-context",        -- sticky context header (after treesitter)
  "snacks",          -- notifier, picker, lazygit, UI toggles (includes dashboard)
  "flash",           -- flash.nvim keymaps (s/S jumps, gz surround complement)
  "mini-surround",   -- surround add/delete/replace (gz prefix, no flash conflict)
  "persistence",     -- session save/restore per cwd (<leader>p*)
  "smart-splits",    -- smart navigation between nvim/wezterm
  "mini-clue",       -- keymap hints (before other keymaps are set)
  "search",          -- <leader>s / <leader>f / <leader>b / <leader>g pickers
  "conform",         -- formatter per filetype (lightweight, needed on BufWritePre)
  "tests",           -- universal test runner (<leader>tn/tf/tw/tl)
}

for _, name in ipairs(sync_configs) do
  load_cfg(name)
end

-- gitsigns: conditional — only load when inside a git repository
-- Uses vim.fs.find (non-blocking) to avoid the 30ms+ of `git rev-parse`
local function maybe_load_gitsigns()
  local root = vim.fs.find(".git", { upward = true, path = vim.fn.getcwd() })[1]
  if root then load_cfg("gitsigns") end
end
-- Check at startup and again when entering a new directory
maybe_load_gitsigns()
vim.api.nvim_create_autocmd("DirChanged", {
  once     = false,
  callback = function()
    if not package.loaded["gitsigns"] then maybe_load_gitsigns() end
  end,
})

-- lua_ls: conditional — enable only when a Lua file is opened
-- Activation: FileType lua → enable lua_ls server on-demand
-- Performance benefit: zero overhead until lua files are needed
local lua_lsp_enabled = false
vim.api.nvim_create_autocmd("FileType", {
  pattern  = "lua",
  once     = true,  -- only need to enable once per session
  callback = function()
    if vim.opt.diff:get() then return end
    if not lua_lsp_enabled then
      vim.lsp.enable({ "lua_ls" })
      lua_lsp_enabled = true
    end
  end,
})

-- Deferred: heavy / rarely-needed-at-startup
local deferred_configs = {
  "copilot-chat",    -- CopilotChat prompts + keymaps
  "nvim-dap",        -- DAP adapters + Java/Kotlin configurations
  "nvim-dap-view",   -- DAP UI (auto-registers its own listeners)
  "sidekick",        -- Sidekick CLI + NES (<Tab> override)
  -- FileType-gated: only meaningful when a relevant buffer is opened
  "ts-comments",     -- commentstring context (activates on FileType)
  "todo-comments",   -- TODO highlight scan (activates on BufRead/BufEnter)
  "render-markdown", -- markdown rendering (activates on FileType markdown)
  -- On-demand tools: register toggle keymaps but DON'T start the server
  "sonarlint",       -- <leader>uS toggle; server starts only when enabled
  -- Salesforce: only loads when sfdx-project.json is detected
  "salesforce",      -- <leader>S* org ops, Apex tests, LWC creation, logs
}

vim.schedule(function()
  for _, name in ipairs(deferred_configs) do
    load_cfg(name)
  end
end)
