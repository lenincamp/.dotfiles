return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ts_ls = {
          settings = {
            javascript = {
              preferences = {
                importModuleSpecifier = "relative",
              },
            },
            typescript = {
              preferences = {
                importModuleSpecifier = "relative",
              },
            },
          },
        },
        -- vtsls = {
        --   settings = {
        --     javascript = {
        --       preferences = {
        --         importModuleSpecifier = "relative",
        --       },
        --     },
        --     typescript = {
        --       preferences = {
        --         importModuleSpecifier = "relative",
        --       },
        --     },
        --   },
        -- },
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
  },
}
