return {
  "folke/noice.nvim",
  require("noice").setup({
    presets = {
      lsp_doc_border = true,
    },
    routes = {
      {
        filter = {
          event = "lsp",
          kind = "progress",
          find = "jdtls",
        },
        opts = { skip = true },
      },
    },
  }),
}
