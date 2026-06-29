local opt = vim.opt
opt.guicursor = "n-v-c:block-Cursor," .. "i-ci:ver35-iCursor," .. "r-cr:hor25-rCursor"

vim.api.nvim_set_hl(0, "Cursor", {
  reverse = true,
})

opt.colorcolumn = ""
opt.termguicolors = true
opt.ignorecase = true
opt.smartcase = true
opt.swapfile = false
opt.autoindent = true
opt.smartindent = true -- auto-indent on new lines for C-like syntax
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.shiftround = true
opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
opt.number = true
opt.relativenumber = true
opt.numberwidth = 2
opt.wrap = false
opt.cursorline = true
opt.cursorlineopt = "number" -- highlight only the line-number column, not the full line
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.smoothscroll = true
opt.jumpoptions = "clean,view" -- 0.12: restore window view on jumps and tagstack pops
opt.fillchars = { fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " ", eob = " " }
opt.inccommand = "split"
opt.undodir = vim.fn.expand("~/.vim/undodir")
opt.undofile = true
opt.fileencodings = "utf-8"
opt.winborder = "rounded"
opt.hlsearch = false
opt.incsearch = true
opt.autoread = true
opt.cmdheight = 1

-- Fast grep backend + quickfix-compatible format.
opt.grepprg = "rg --vimgrep --smart-case --hidden --glob !.git"
opt.grepformat = "%f:%l:%c:%m"

-- ── Folding ───────────────────────────────────────────────────────────────────
-- Single global foldexpr that dispatches per-buffer: LSP foldingRange when the
-- buffer has a capable client (flag set in lsp.lua), otherwise treesitter.
-- Deciding at eval time (not via window-local overrides) avoids the pre-attach
-- race where an inherited lsp-foldexpr wedges the folding state on a buffer
-- whose client has not attached yet.
vim.treesitter.language.register("tsx", { "javascriptreact", "typescriptreact" })

function _G.SmartFoldexpr()
  if vim.b._has_lsp_folding then
    return vim.lsp.foldexpr(vim.v.lnum)
  end
  return vim.treesitter.foldexpr(vim.v.lnum)
end

opt.foldmethod = "expr"
opt.foldexpr = "v:lua.SmartFoldexpr()"
opt.foldlevel = 99 -- keep folds open by default
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldminlines = 1

-- Folds only open with fold commands (za/zo/zO/zR), NOT when navigating j/k/search
opt.foldopen = ""

-- IDE-style foldtext: shows opening line + closing brace + line count
-- e.g.  public void run() { ··· } — 25 lines
function _G.FoldText()
  local start_line = vim.fn.getline(vim.v.foldstart)
  local end_line = vim.fn.getline(vim.v.foldend):match("^%s*(.-)%s*$") -- trim
  local lines = vim.v.foldend - vim.v.foldstart

  -- Append closing brace/bracket/paren if the fold ends with one
  local suffix = ""
  if end_line:match("^[%)%]%}]") then
    suffix = " ··· " .. end_line
  end

  return start_line .. suffix .. " — " .. lines .. " lines"
end

opt.foldtext = "v:lua.FoldText()"
opt.clipboard = "unnamedplus" -- yank/paste uses system clipboard

vim.filetype.add({
  filename = {
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
  },
})

vim.cmd.filetype("plugin indent on")

-- ── Display ───────────────────────────────────────────────────────────────────

-- Cmdline info off by default — ruler shows "Top/line,col", showcmd shows
-- partial keystrokes. Both are already visible in the winbar; toggle via Command Center.
opt.ruler = true
opt.showcmd = false
opt.showmode = true

opt.pumblend = 0      -- no popup blend (crisp completion menu)
opt.winblend = 0      -- no floating-window blend
opt.splitright = true -- new vertical splits open to the right
opt.splitbelow = true -- new horizontal splits open below
opt.showtabline = 0   -- never show the tabline

-- Undercurl support (for diagnostic underlines in capable terminals)
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Disable Python 3 provider (speeds up startup when Python is unused)
vim.cmd([[let g:loaded_python3_provider = 0]])

-- Large file defaults (will be overridden per-buffer in autocmds.lua)
opt.lazyredraw = false -- enable per-buffer when large file detected
opt.updatetime = 100   -- default (1000ms when large file detected)
opt.undolevels = 1000  -- default (100 when large file detected)

-- ── Diff / Merge ergonomics (Neovim 0.12-friendly) ──────────────────────────

local diffopt = {
  "internal",            -- use Neovim's built-in diff
  "filler",              -- keep filler lines for context alignment
  "closeoff",            -- close diff when only one window remains
  "foldcolumn:1",        -- fold column in diff mode
  "context:8",           -- keep nearby context while collapsing distant unchanged blocks
  "vertical",            -- default to vertical split
  "algorithm:histogram", -- better block matching than Myers for code
  "indent-heuristic",    -- indentation-aware diff
  "linematch:120",       -- stronger moved-line detection for large refactors
  "inline:word",         -- 0.12: word-level change highlighting (merges adjacent blocks)
}
opt.diffopt:append(table.concat(diffopt, ","))

-- ── Ghostty: show project name in window title ────────────────────────────────

if vim.fn.getenv("TERM_PROGRAM") == "ghostty" then
  opt.title = true
  opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end

-- ── Statusline (native 0.12 default: file, diagnostics, busy ◐, ruler) ────────

opt.laststatus = 2

-- ── Experimental native message/cmdline UI (Neovim 0.12 "ui2") ────────────────
-- Removes "Press ENTER" interruptions, highlights the cmdline as you type, and
-- exposes the pager as a real buffer/window (open full message history with g<).
-- Guarded so it is a no-op on older Nvim or if the private module path changes.
pcall(function()
  require("vim._core.ui2").enable()
end)

require("config.editor")
