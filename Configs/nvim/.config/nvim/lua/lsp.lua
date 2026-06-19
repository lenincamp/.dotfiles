-- LSP bootstrap (Neovim 0.12 native API).
-- Servers are enabled on demand per FileType + server root_dir/root_markers.

local runtime = require("modules.core.runtime")
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

runtime.set_lsp_api({
  enable_for_buffer = start.enable_for_buffer,
})

diagnostics.setup()
code_actions.setup()
