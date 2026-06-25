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

-- LSP folding: override treesitter foldexpr per-buffer when server supports foldingRange.
-- BufWinEnter re-applies when the buffer enters a window where LspAttach already ran
-- (e.g. opening a previously-attached buffer via picker in a different window).
local function apply_lsp_fold(winid, bufnr)
  if not vim.api.nvim_win_is_valid(winid) then return end
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.api.nvim_win_get_buf(winid) ~= bufnr then return end
  if vim.bo[bufnr].buftype ~= "" then return end
  if vim.wo[winid].diff then return end

  vim.wo[winid][0].foldmethod = "expr"
  vim.wo[winid][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
  vim.wo[winid][0].foldlevel = 99
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PureLspFolding", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/foldingRange", ev.buf) then
      for _, winid in ipairs(vim.fn.win_findbuf(ev.buf)) do
        apply_lsp_fold(winid, ev.buf)
      end
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = "PureLspFolding",
  callback = function(ev)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
      if client:supports_method("textDocument/foldingRange", ev.buf) then
        apply_lsp_fold(vim.api.nvim_get_current_win(), ev.buf)
        break
      end
    end
  end,
})
