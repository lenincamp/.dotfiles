local util = require("lspconfig.util")
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tailwindcss = {
        root_dir = util.root_pattern("tailwind.config.js", "tailwind.config.ts"),
      },
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
      apex_ls = {
        apex_jar_path = vim.fn.stdpath("data") .. "/mason/share/apex-language-server/apex-jorje-lsp.jar",
        apex_enable_semantic_errors = true,
        apex_enable_completion_statistics = false,
      },
      lwc_ls = {
        cmd = { "lwc-language-server", "--stdio" },
        filetypes = { "javascript", "html" },
        root_markers = { "sfdx-project.json" },
        init_options = {
          embeddedLanguages = {
            javascript = true,
          },
        },
      },
      visualforce_ls = {
        filetypes = { "visualforce" },
        root_markers = { "sfdx-project.json" },
        init_options = {
          embeddedLanguages = {
            css = true,
            javascript = true,
          },
        },
      },
      vimls = {},
      eslint = {
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "html",
        },
        root_dir = util.root_pattern(".git", "package.json", "sfdx-project.json"),
        settings = {
          workingDirectories = {
            { directory = "${workspaceFolder}", changeProcessCWD = true },
            { directory = "./force-app/main/default/lwc", changeProcessCWD = true },
          },
        },
      },
    },
  },
}
