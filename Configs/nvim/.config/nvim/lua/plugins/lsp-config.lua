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
      ["apex_ls"] = {
        apex_jar_path = vim.fn.stdpath("data") .. "/mason/share/apex-language-server/apex-jorje-lsp.jar",
        apex_enable_semantic_errors = true,
        apex_enable_completion_statistics = false,
      },
      ["lwc_ls"] = {},
      eslint = {
        filetypes = {
          -- Mantenemos los filetypes de React y LWC
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "html",
        },

        -- 1. Detección de Raíz (para React y Salesforce)
        -- Busca el .git, package.json (React/Node) o sfdx-project.json (Salesforce)
        root_dir = require("lspconfig.util").root_pattern(".git", "package.json", "sfdx-project.json"),

        -- 2. Configuración de Directorios de Trabajo
        settings = {
          workingDirectories = {
            -- A. DIRECTORIO PRINCIPAL (Para React y Roots Generales)
            -- ${workspaceFolder} es la ruta que detectó root_dir.
            -- Esto asegura que los proyectos React lean su .eslintrc.json de la raíz.
            { directory = "${workspaceFolder}", changeProcessCWD = true },

            -- B. SUB-DIRECTORIO ESPECÍFICO (Para LWC)
            -- Esto añade el subdirectorio de LWC, que es necesario en proyectos SFDX.
            { directory = "./force-app/main/default/lwc", changeProcessCWD = true },
          },
        },
      },
    },
  },
}
