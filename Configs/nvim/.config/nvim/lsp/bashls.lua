return {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash", "zsh" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { ".git" })
    if root then
      on_dir(root)
    end
  end,
}
