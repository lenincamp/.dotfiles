return {
  filetypes = { "dockerfile" },
  root_dir = function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      return
    end

    local name = vim.fn.fnamemodify(path, ":t")
    if name:match("^Dockerfile") then
      on_dir(vim.fs.dirname(path))
    end
  end,
  settings = {
    docker = {
      languageserver = {
        formatter = {
          ignoreMultilineInstructions = true,
        },
      },
    },
  },
}