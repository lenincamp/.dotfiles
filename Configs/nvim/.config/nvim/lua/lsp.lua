-- LSP bootstrap (Neovim 0.12 native API).
-- Servers are enabled on demand per FileType + server root_dir/root_markers.

local registry = require("modules.bootstrap.registry")
local code_actions = require("modules.lsp.code_actions")
local diagnostics = require("modules.lsp.diagnostics")
local start = require("modules.lsp.start")

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("PureLazyLspEnable", { clear = true }),
  callback = function(args)
    start.request_enable_for_buffer(args.buf)
  end,
})

vim.schedule(function()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      start.request_enable_for_buffer(bufnr)
    end
  end
end)

registry.set_lsp_api({
  enable_for_buffer = start.enable_for_buffer,
})

diagnostics.setup()
code_actions.setup()

-- LSP folding: flip a per-buffer flag that the global SmartFoldexpr (configs.lua)
-- reads to choose LSP foldingRange over treesitter. foldexpr stays a single global
-- setting; the flag is the only source of truth for "this buffer uses LSP folds".
local fold_group = vim.api.nvim_create_augroup("PureLspFolding", { clear = true })

local function buffer_has_folding(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client:supports_method("textDocument/foldingRange", bufnr) then
      return true
    end
  end
  return false
end

-- Recompute folds in every window showing bufnr (the flag flip alone does not
-- invalidate already-computed treesitter folds).
local function refresh_folds(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.api.nvim_win_call(winid, function()
      if vim.wo.foldmethod == "expr" then
        vim.cmd("silent! normal! zx")
      end
    end)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = fold_group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/foldingRange", ev.buf) then
      vim.b[ev.buf]._has_lsp_folding = true
      refresh_folds(ev.buf)
    end
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = fold_group,
  callback = function(ev)
    -- The detaching client is still listed during the event; recheck next tick.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) and not buffer_has_folding(ev.buf) then
        vim.b[ev.buf]._has_lsp_folding = nil
        refresh_folds(ev.buf)
      end
    end)
  end,
})
