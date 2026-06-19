return {
  filetypes = { "lua" },
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      completion = {
        callSnippet = "Replace",
      },
      telemetry = {
        enable = false,
      },
    },
  },
}
