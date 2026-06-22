return {
  cmd = { "visualforce-language-server", "--stdio" },
  filetypes = { "visualforce" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "sfdx-project.json" })
    if root then
      on_dir(root)
    end
  end,
  init_options = { embeddedLanguages = { css = true, javascript = true } },
}
