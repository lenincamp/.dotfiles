local workspace = require("modules.lsp.workspace")

return {
  cmd = { "lwc-language-server", "--stdio" },
  filetypes = { "javascript", "html" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "sfdx-project.json" })
    if not root then
      return
    end
    on_dir(root)
  end,
  before_init = workspace.ensure_workspace_folders,
  init_options = { embeddedLanguages = { javascript = true } },
}
