local ROOT_MARKERS = { ".taplo.toml", "taplo.toml", "Cargo.toml", "pyproject.toml" }

return {
  cmd = { "taplo", "lsp", "stdio" },
  filetypes = { "toml" },
  root_dir = function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      return
    end

    local root = vim.fs.root(bufnr, ROOT_MARKERS)
    if root then
      on_dir(root)
    end
  end,
}