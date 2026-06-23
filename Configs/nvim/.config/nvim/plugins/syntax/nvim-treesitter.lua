-- nvim-treesitter (main branch): parser manager only.
-- Highlighting / indent / folding are enabled via Neovim's built-in treesitter API.

-- ── Parser install directory ────────────────────────────────────────────────
require("nvim-treesitter").setup({
  ensure_installed = {
    -- Shell / config
    "bash", "zsh", "ssh_config", "tmux",
    -- Git
    "diff", "git_config", "git_rebase", "gitattributes", "gitcommit", "gitignore",
    -- Web
    "css", "html", "http", "javascript", "jsdoc", "json", "scss", "tsx", "typescript",
    -- Lua
    "lua", "luadoc", "luap", "query",
    -- JVM
    "java", "javadoc", "kotlin",
    -- Python
    "python",
    -- Data / markup
    "csv", "graphql", "jq", "markdown", "markdown_inline", "nginx",
    "properties", "regex", "sql", "toml", "xml", "yaml",
    -- Misc
    "comment", "dockerfile", "latex",
    -- Salesforce
    "apex", "soql", "sosl",
    -- Vim
    "vim", "vimdoc",
  },
})

-- The new main-branch nvim-treesitter stores highlight/indent/fold queries
-- in runtime/queries/ instead of queries/. Add runtime/ to rtp so Neovim
-- can find them.
local ts_runtime = vim.fn.stdpath("data") .. "/site/pack/core/opt/nvim-treesitter/runtime"
if vim.fn.isdirectory(ts_runtime) == 1 then
  vim.opt.runtimepath:prepend(ts_runtime)
end

local function is_regular_treesitter_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  if vim.b[buf].huge_code_profile_active then
    return false
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      return false
    end
  end

  return vim.bo[buf].filetype ~= ""
end

-- ── Auto-enable treesitter highlighting ─────────────────────────────────────
-- vim.treesitter.start() attaches the TS highlighter to the buffer,
-- replacing regex-based syntax.  pcall guards against missing parsers.

local function enable_highlight(buf)
  if not is_regular_treesitter_buffer(buf) then return end
  if not pcall(vim.treesitter.start, buf) then return end
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    for _, winid in ipairs(vim.fn.win_findbuf(buf)) do
      if vim.api.nvim_win_is_valid(winid) and vim.wo[winid].foldmethod == "expr" then
        vim._foldupdate(winid, 0, vim.api.nvim_buf_line_count(buf))
      end
    end
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  group    = vim.api.nvim_create_augroup("ts_highlight", { clear = true }),
  callback = function(args)
    enable_highlight(args.buf)
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

local function enable_indent(buf)
  if not is_regular_treesitter_buffer(buf) then return end

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
end

vim.api.nvim_create_autocmd("FileType", {
  group    = vim.api.nvim_create_augroup("ts_indent", { clear = true }),
  callback = function(args)
    enable_indent(args.buf)
  end,
})

vim.schedule(function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    enable_highlight(buf)
    enable_indent(buf)
  end
end)

-- ── Incremental selection ───────────────────────────────────────────────────

vim.keymap.set("n", "gnn", function() vim.treesitter.select("parent") end, { desc = "TS: init selection" })
vim.keymap.set("x", "grn", function() vim.treesitter.select("parent") end, { desc = "TS: grow selection" })
vim.keymap.set("x", "grm", function() vim.treesitter.select("child") end, { desc = "TS: shrink selection" })
