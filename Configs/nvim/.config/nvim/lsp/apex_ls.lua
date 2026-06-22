local jar = vim.fn.stdpath("data") .. "/mason/share/apex-language-server/apex-jorje-lsp.jar"

return {
  cmd = { "java", "-jar", jar },
  filetypes = { "apex" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "sfdx-project.json" })
    if root then
      on_dir(root)
    end
  end,
  apex_jar_path = jar,
  apex_enable_semantic_errors = true,
  apex_enable_completion_statistics = false,
}
