-- Startup orchestrator.
-- Loads all packs, registers :Pack* commands, and sources plugin configs.
--

local packs    = require("packs")
local pack_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt"

-- ── Load packs ────────────────────────────────────────────────────────────────

-- vim-visual-multi globals must be set BEFORE packadd loads the plugin
local vm_cfg = vim.fn.stdpath("config") .. "/plugins/vim-visual-multi.lua"
if vim.fn.filereadable(vm_cfg) == 1 then pcall(dofile, vm_cfg) end

for _, pack in ipairs(packs.list) do
  local name = packs.name(pack)
  local ok, err = pcall(vim.cmd.packadd, name)
  if not ok then
    vim.notify("Pack load failed [" .. name .. "]: " .. tostring(err), vim.log.levels.WARN)
  end
end

vim.cmd("silent! helptags ALL")

-- ── Pack management commands ──────────────────────────────────────────────────

require("pack_manager").setup(packs, pack_dir)

-- ── Mason ─────────────────────────────────────────────────────────────────────
-- Config lives in plugins/mason.lua (ensure_installed + setup)

-- Fallback: reuse LSP servers installed in the main nvim instance
local main_mason_bin = vim.fn.expand("~/.local/share/nvim/mason/bin")
if vim.fn.isdirectory(main_mason_bin) == 1 and not vim.env.PATH:find(main_mason_bin, 1, true) then
  vim.env.PATH = main_mason_bin .. ":" .. vim.env.PATH
end

-- ── Plugin configs ────────────────────────────────────────────────────────────
-- SYNC: must be active before the editor is interactive.
-- DEFERRED: heavy or rarely-needed-at-startup — loaded after event-loop tick.

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
  "catppuccin",              -- colorscheme first — highlights must be set before any UI renders
  "gruvbox",
  "blink-cmp",               -- completion + snippet preset (needed from first keystroke)
  "mini-snippets",           -- snippet engine (friendly-snippets)
  "mini-pairs",              -- auto-close brackets
  "mini-indentscope",        -- animated indent scope indicator
  "mini-icons",              -- filetype icons for snacks picker
  "nvim-treesitter",         -- syntax / indent
  "treesitter-textobjects",  -- ]f/[f/]c/[c navigation + af/if text objects
  "treesitter-context",      -- sticky context header (after treesitter)
  "snacks",                  -- notifier, picker, lazygit, UI toggles (includes dashboard)
  "flash",                   -- flash.nvim keymaps (s/S jumps, gz surround complement)
  "mini-surround",           -- surround add/delete/replace (gz prefix, no flash conflict)
  "persistence",             -- session save/restore per cwd (<leader>p*)
  "smart-splits",            -- smart navigation between nvim/wezterm
  "mini-clue",               -- keymap hints (before other keymaps are set)
  "search",                  -- <leader>s / <leader>f / <leader>b / <leader>g pickers
  "mason",                   -- tool installer (ensure_installed)
  "conform",                 -- formatter per filetype (lightweight, needed on BufWritePre)
  "tests",                   -- universal test runner (<leader>tn/tf/tw/tl)
}

for _, name in ipairs(sync_configs) do load_cfg(name) end

-- gitsigns: only inside a git repository (non-blocking fs.find avoids git rev-parse overhead)
local function maybe_load_gitsigns()
  if vim.fs.find(".git", { upward = true, path = vim.fn.getcwd() })[1] then
    load_cfg("gitsigns")
  end
end

maybe_load_gitsigns()
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    if not package.loaded["gitsigns"] then maybe_load_gitsigns() end
  end,
})

-- lua_ls: on-demand — zero overhead until a Lua file is opened
vim.api.nvim_create_autocmd("FileType", {
  pattern  = "lua",
  once     = true,
  callback = function()
    if not vim.opt.diff:get() then vim.lsp.enable({ "lua_ls" }) end
  end,
})

-- Deferred: heavy / rarely-needed-at-startup
local deferred_configs = {
  "copilot",         -- Copilot + NES via copilot-lsp
  "avante",          -- Chat / agent UI backed by Copilot provider
  "nvim-dap",        -- DAP adapters + Java/Kotlin configurations
  "nvim-dap-view",   -- DAP UI (auto-registers its own listeners)
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
  for _, name in ipairs(deferred_configs) do load_cfg(name) end
end)
