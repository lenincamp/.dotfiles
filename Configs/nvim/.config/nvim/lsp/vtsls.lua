local workspace = require("modules.lsp.workspace")

return {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  root_dir = function(bufnr, on_dir)
    if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
      return
    end

    local root = vim.fs.root(bufnr, { "tsconfig.json", "jsconfig.json" })
      or vim.fs.root(bufnr, { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb" })
      or vim.fs.root(bufnr, { ".git" })
      or vim.fn.getcwd()
    on_dir(root)
  end,
  before_init = workspace.ensure_workspace_folders,
  settings = {
    javascript = { preferences = { importModuleSpecifier = "non-relative" } },
    typescript = { preferences = { importModuleSpecifier = "non-relative" } },
  },
}
