local M = {}

function M.supports_method(client, method, bufnr)
  if type(client) ~= "table" or type(method) ~= "string" then
    return false
  end

  local ok, supported = pcall(function()
    return client:supports_method(method, bufnr)
  end)
  return ok and supported == true
end

function M.detach_all(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    pcall(vim.lsp.buf_detach_client, bufnr, client.id)
  end
end

function M.set_diagnostics(bufnr, enabled)
  pcall(vim.diagnostic.enable, enabled == true, { bufnr = bufnr })
end

function M.disable_for_buffer(bufnr)
  M.detach_all(bufnr)
  M.set_diagnostics(bufnr, false)
  vim.b[bufnr].diff_lsp_disabled = true
end

return M
