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

-- LSP folding: use vim.lsp.foldexpr() buffer-locally when the server supports it.
-- Applies to all filetypes (Java via jdtls, web via vtsls, etc.).
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PureLspFolding", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/foldingRange", ev.buf) then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldmethod = "expr"
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
    end
  end,
})
