-- nvim-treesitter (main branch): parser manager only.
-- Highlighting / indent / folding are enabled via Neovim's built-in treesitter API.

-- ── Parser install directory ────────────────────────────────────────────────
require("nvim-treesitter").setup()

-- The new main-branch nvim-treesitter stores highlight/indent/fold queries
-- in runtime/queries/ instead of queries/. Add runtime/ to rtp so Neovim
-- can find them.
local ts_runtime = vim.fn.stdpath("data") .. "/site/pack/core/opt/nvim-treesitter/runtime"
if vim.fn.isdirectory(ts_runtime) == 1 then
  vim.opt.runtimepath:prepend(ts_runtime)
end

-- ── Auto-enable treesitter highlighting ─────────────────────────────────────
-- vim.treesitter.start() attaches the TS highlighter to the buffer,
-- replacing regex-based syntax.  pcall guards against missing parsers.

vim.api.nvim_create_autocmd("FileType", {
  group    = vim.api.nvim_create_augroup("ts_highlight", { clear = true }),
  callback = function(args)
    -- skip special buffers (terminal, help already has syntax, etc.)
    if vim.bo[args.buf].buftype ~= "" then return end
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- ── Treesitter-based indent — mirrors LazyVim approach ────────────────────
-- Uses require("nvim-treesitter").indentexpr() (nvim-treesitter's OWN
-- implementation) instead of vim.treesitter.indentexpr() (Neovim native).
-- LazyVim uses this same function; it is battle-tested for Java and handles
-- method chains, switch expressions, annotations, and continuation lines.
--
-- Guards (same logic as LazyVim):
--   1. Parser must be installed for the filetype
--   2. "indents" query must exist (via vim.treesitter.query.get)
-- If either is missing, indentexpr is left unchanged (falls back to cindent
-- or Vim's built-in Java indent from $VIMRUNTIME/indent/java.vim).

vim.api.nvim_create_autocmd("FileType", {
  group    = vim.api.nvim_create_augroup("ts_indent", { clear = true }),
  callback = function(args)
    local buf = args.buf
    if vim.bo[buf].buftype ~= "" then return end

    local ft   = vim.bo[buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if not lang then return end

    -- Verify parser is loadable
    local ok_parser = pcall(vim.treesitter.language.inspect, lang)
    if not ok_parser then return end

    -- Verify indents query exists (same check LazyVim does via have_query)
    local has_indents = vim.treesitter.query.get(lang, "indents") ~= nil
    if not has_indents then return end

    -- Use nvim-treesitter's indent, not the native vim.treesitter one
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- ── Incremental selection (manual, since the module was removed) ────────────

local function ts_select_node(grow)
  local node = vim.treesitter.get_node()
  if not node then return end

  if grow then
    -- In visual mode, try to expand to parent node
    local parent = node:parent()
    if parent then node = parent end
  end

  local sr, sc, er, ec = node:range()
  -- Move to start, enter visual, move to end
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { er + 1, math.max(0, ec - 1) })
end

vim.keymap.set("n", "gnn", function() ts_select_node(false) end, { desc = "TS: init selection" })
vim.keymap.set("x", "grn", function() ts_select_node(true) end,  { desc = "TS: grow selection" })
vim.keymap.set("x", "grm", "<Esc>gv",                            { desc = "TS: shrink selection" })
