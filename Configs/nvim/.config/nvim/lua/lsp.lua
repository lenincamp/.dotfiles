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
-- Sets foldlevel explicitly to avoid it resetting to 0 when creating the buffer-local context.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PureLspFolding", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/foldingRange", ev.buf) then
      for _, winid in ipairs(vim.fn.win_findbuf(ev.buf)) do
        if vim.api.nvim_win_is_valid(winid) then
          vim.wo[winid][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
          vim.wo[winid][0].foldlevel = 99
        end
      end
    end
  end,
})
