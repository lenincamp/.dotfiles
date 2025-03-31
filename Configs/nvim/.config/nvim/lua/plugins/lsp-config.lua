return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      kotlin_language_server = {},
      vtsls = {
        settings = {
          javascript = {
            preferences = {
              importModuleSpecifier = "absolute",
            },
          },
          typescript = {
            preferences = {
              importModuleSpecifier = "absolute",
            },
          },
        },
      },
      lemminx = {
        init_options = {
          settings = {
            xml = {
              format = {
                enabled = true,
                -- splitAttributes = "alignWithFirstAttr",
                joinContentLines = true,
                preservedNewlines = 1,
                insertSpaces = true,
                tabSize = 4,
              },
            },
          },
        },
      },
    },
  },
}
