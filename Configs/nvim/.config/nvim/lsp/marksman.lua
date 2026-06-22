return {
  cmd = { "marksman", "server" },
  filetypes = { "markdown", "markdown.mdx" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { ".marksman.toml", ".git" })
    if root then
      on_dir(root)
    end
  end,
}
