local opt = vim.opt
-- opt.guicursor = "n-v-c:ver250,i-ci-ve:ver25,r-cr:hor20,o:hor50"
-- opt.guicursor = {
--   "n-v-c:block",        -- block cursor in Normal, Visual, Command
--   "i-ci:ver25",         -- vertical cursor (25% width) in Insert
--   "r-cr:hor20",         -- horizontal cursor in Replace
--   "o:hor50",
--   "a:blinkwait700-blinkoff400-blinkon250",
-- }

opt.guicursor =
  "n-v-c:block-Cursor," ..
  "i-ci:ver35-iCursor," ..
  "r-cr:hor25-rCursor"

vim.api.nvim_set_hl(0, "Cursor", {
    reverse = true
})

opt.colorcolumn = ""
opt.signcolumn = "yes:1"
opt.termguicolors = true
opt.ignorecase = true
opt.swapfile = false
opt.autoindent  = true
opt.smartindent = true   -- auto-indent on new lines for C-like syntax
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
opt.cursorline    = true
opt.cursorlineopt = "number"   -- highlight only the line-number column, not the full line
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.smoothscroll = true
opt.fillchars = { fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " ", eob = " " }
opt.inccommand = "nosplit"
opt.undodir = vim.fn.expand("~/.vim/undodir")
opt.undofile = true
opt.winborder = "rounded"
opt.hlsearch = false

-- ── Folding (treesitter-based) ──────────────────────────────────────────────
opt.foldmethod     = "expr"
opt.foldexpr       = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel      = 99        -- start with all folds open
opt.foldlevelstart = 99
opt.foldenable     = true
opt.foldminlines   = 1

-- Folds only open with fold commands (za/zo/zO/zR), NOT when navigating j/k/search
opt.foldopen = ""

-- IDE-style foldtext: shows opening line + closing brace + line count
-- e.g.  public void run() { ··· } — 25 lines
function _G.FoldText()
  local start_line = vim.fn.getline(vim.v.foldstart)
  local end_line   = vim.fn.getline(vim.v.foldend):match("^%s*(.-)%s*$") -- trim
  local lines      = vim.v.foldend - vim.v.foldstart

  -- Append closing brace/bracket/paren if the fold ends with one
  local suffix = ""
  if end_line:match("^[%)%]%}]") then
    suffix = " ··· " .. end_line
  end

  return start_line .. suffix .. " — " .. lines .. " lines"
end

opt.foldtext = "v:lua.FoldText()"
opt.clipboard = "unnamedplus"  -- yank/paste uses system clipboard

vim.cmd.filetype("plugin indent on")
vim.g.copilot_no_tab_map = true
-- netrw disabled in init.lua (before plugins load)

-- ── Display ───────────────────────────────────────────────────────────────────

-- Cmdline info off by default — ruler shows "Top/line,col", showcmd shows
-- partial keystrokes. Both are already visible in the winbar; toggle via <leader>ui.
opt.ruler   = false
opt.showcmd = false
opt.showmode = false

opt.pumblend  = 0   -- no popup blend (crisp completion menu)
opt.winblend  = 0   -- no floating-window blend
opt.splitright = true  -- new vertical splits open to the right
opt.splitbelow = true  -- new horizontal splits open below
opt.showtabline = 0    -- never show the tabline

-- Undercurl support (for diagnostic underlines in capable terminals)
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Disable Python 3 provider (speeds up startup when Python is unused)
vim.cmd([[let g:loaded_python3_provider = 0]])

-- Large file defaults (will be overridden per-buffer in autocmds.lua)
opt.lazyredraw = false  -- enable per-buffer when large file detected
opt.updatetime = 200    -- default (1000ms when large file detected)
opt.undolevels = 1000   -- default (100 when large file detected)

-- ── Diff algorithm ────────────────────────────────────────────────────────────

local diffopt = {
  "internal",           -- use Neovim's built-in diff
  "filler",             -- keep filler lines for context alignment
  "closeoff",           -- close diff when only one window remains
  "hiddenoff",          -- disable diff when buffer is hidden
  "foldcolumn:1",       -- fold column in diff mode
  "context:999999",     -- show all context (don't collapse unchanged lines)
  "vertical",           -- default to vertical split
  "algorithm:histogram", -- semantic diff (better than Myers)
  "indent-heuristic",   -- indentation-aware diff
  "linematch:60",       -- detect moved lines (Neovim 0.9+)
}
opt.diffopt:append(table.concat(diffopt, ","))

-- ── Ghostty: show project name in window title ────────────────────────────────

if vim.fn.getenv("TERM_PROGRAM") == "ghostty" then
  opt.title       = true
  opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end

-- ── Winbar: breadcrumb + filetype icon + line:col ────────────────────────────
--
-- Layout (active):    [ft-icon] … > dir > file.java ●          42:15
-- Layout (inactive):  [ft-icon] … > dir > file.java  (dimmer via WinBarNC)
--
-- Highlight groups (catppuccin.lua):
--   WinBarIcon — filetype icon (blue)
--   WinBarPath — directory parts (dimmed)
--   WinBarSep  — ">" separator (subtle)
--   WinBarFile — filename (bold)
--   WinBarMod  — modified "●" (peach)
--   WinBarLine — line:col (very subtle, right side)

-- Filetype icon lookup (nerd fonts v3)
local ft_icons = {
  java       = "󰬷", javascript = "󰌞", typescript = "󰛦",
  javascriptreact = "󰜈", typescriptreact = "󰜈",
  lua        = "󰢱", python     = "󰌠", html       = "󰌝",
  css        = "󰌜", scss       = "󰌜", json       = "󰘦",
  markdown   = "󰍔", xml        = "󰗀", yaml       = "󰈙",
  toml       = "󰈙", sh         = "󰆍", bash       = "󰆍",
  vim        = "󰕷", sql        = "󰆼", kotlin     = "󱈙",
  rust       = "󱘗", go         = "󰟓", c          = "󰙱",
  cpp        = "󰙲", cs         = "󰌛", ruby       = "󰴭",
  php        = "󰌟", swift      = "󰛥",
}

local function ft_icon(buf)
  local ft  = vim.bo[buf].filetype
  local ico = ft_icons[ft]
  if ico then return "%#WinBarIcon#" .. ico .. " " end
  -- Fallback: try extension from filename
  local name = vim.api.nvim_buf_get_name(buf)
  local ext  = name:match("%.(%w+)$")
  ico = ext and ft_icons[ext:lower()]
  return ico and ("%#WinBarIcon#" .. ico .. " ") or "%#WinBarIcon#󰈙 "
end

local function build_winbar_path(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then return "" end
  path = vim.fn.fnamemodify(path, ":~:.")

  local parts = vim.split(path, "/", { plain = true })
  if #parts == 0 then return "" end

  local max_dirs = 3
  local truncated = false
  if #parts > max_dirs + 1 then
    local kept = {}
    for i = #parts - max_dirs, #parts do kept[#kept + 1] = parts[i] end
    parts     = kept
    truncated = true
  end

  local sep    = " %#WinBarSep#› %#WinBarPath#"
  local crumbs = {}
  if truncated then crumbs[#crumbs + 1] = "%#WinBarSep#…" end
  for i, part in ipairs(parts) do
    crumbs[#crumbs + 1] = (i == #parts)
      and ("%#WinBarFile#" .. part)
      or  ("%#WinBarPath#" .. part)
  end
  return ft_icon(buf) .. table.concat(crumbs, sep)
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "FileType", "WinEnter" }, {
  group    = vim.api.nvim_create_augroup("winbar_cache", { clear = true }),
  callback = function(args)
    if vim.bo[args.buf].buftype == "" then
      vim.b[args.buf].winbar_path = build_winbar_path(args.buf)
    end
  end,
})

function _G.WinbarBreadcrumb()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then return "" end
  -- Compute lazily if cache is missing (e.g. first render in a new split)
  local cached = vim.b[buf].winbar_path
  if cached == nil then
    cached = build_winbar_path(buf)
    vim.b[buf].winbar_path = cached
  end
  if cached == "" then return "" end
  local mod = vim.bo[buf].modified and " %#WinBarMod#●%#WinBar# " or " "
  return " " .. cached .. mod
end

opt.winbar = "%{%v:lua.WinbarBreadcrumb()%}"
