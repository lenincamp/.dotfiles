return {
  cmd = { "lemminx" },
  filetypes = { "xml", "xsd", "xslt", "svg" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { ".git" })
    if root then
      on_dir(root)
    end
  end,
  init_options = {
    settings = {
      xml = {
        format = {
          enabled = true,
          joinContentLines = true,
          preservedNewlines = 1,
          insertSpaces = true,
          tabSize = 4,
        },
      },
    },
  },
}
