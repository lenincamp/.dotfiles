local java_filetypes = { "java" }
local home = os.getenv("HOME")
local brew_path = "/opt/homebrew/Cellar"

return {
  "mfussenegger/nvim-jdtls",
  dependencies = { "folke/which-key.nvim" },
  ft = java_filetypes,
  opts = function(_, opts)
    opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
      java = vim.tbl_deep_extend("force", opts.settings and opts.settings.java or {}, {
        eclipse = {
          downloadSources = true,
        },
        format = {
          enabled = true,
          settings = {
            url = home .. "/.config/nvim/SofiProjectsStyle.xml",
            profile = "Patagonia-Style",
          },
        },
        signatureHelp = { enabled = true },
        contentProvider = { preferred = "fernflower" },
        completion = {
          favoriteStaticMembers = {
            "org.hamcrest.MatcherAssert.assertThat",
            "org.hamcrest.Matchers.*",
            "org.hamcrest.CoreMatchers.*",
            "org.junit.jupiter.api.Assertions.*",
            "java.util.Objects.requireNonNull",
            "java.util.Objects.requireNonNullElse",
            "org.mockito.Mockito.*",
          },
          filteredTypes = {
            "com.sun.*",
            "io.micrometer.shaded.*",
            "java.awt.*",
            "jdk.*",
            "sun.*",
          },
          importOrder = {
            "java",
            "jakarta",
            "javax",
            "com",
            "org",
          },
        },
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
        codeGeneration = {
          toString = {
            template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
          },
          hashCodeEquals = {
            useJava7Objects = true,
          },
          useBlocks = true,
        },
        configuration = {
          updateBuildConfiguration = "interactive",
          runtimes = {
            {
              name = "Java-17",
              path = home .. "Library/Java/JavaVirtualMachines/azul-17.0.10/Contents/Home",
            },
            {
              name = "Java-21",
              path = brew_path .. "/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home",
              default = true,
            },
            {
              name = "Java-1.8",
              path = "/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home",
            },
          },
        },
        maven = {
          downloadSources = true,
        },
        grade = {
          enabled = true,
          downloadSources = true,
        },
        implementationsCodeLens = {
          enabled = true,
        },
        referencesCodeLens = {
          enabled = true,
        },
        references = {
          includeDecompiledSources = true,
        },
        inlayHints = {
          parameterNames = {
            enabled = "all",
          },
        },
      }),
    })

    -- Extends flags
    opts.flags = vim.tbl_deep_extend("force", opts.flags or {}, {
      debounce_text_changes = 80,
      allow_incremental_sync = true,
    })

    -- ========== BETTER SETTINGS FOR DEBUG ==========
    opts.dap = vim.tbl_deep_extend("force", opts.dap or {}, {
      hotcodereplace = "auto", -- Habilita hot code replace automático
      config_overrides = vim.tbl_deep_extend("force", opts.dap and opts.dap.config_overrides or {}, {
        -- Increase memory for the debugger (useful for large applications)
        vmArgs = "-Xmx2g -XX:+UseG1GC",

        -- Optional: If you work with Spring Boot, you can uncomment this
        -- vmArgs = "-Xmx2g -XX:+UseG1GC -Dspring.profiles.active=dev",

        -- Additional useful configuration for debugging
        console = "integratedTerminal", -- Use integrated terminal
        stopOnEntry = false, -- Do not stop automatically at the entry point
      }),
    })

    -- ========== CONFIGURATION FOR TESTS ==========
    -- Extend test configuration without overwriting
    if type(opts.test) == "boolean" then
      opts.test = {
        config_overrides = {
          vmArgs = "-ea -Xmx1g", -- Enable assertions and memory for tests
        },
      }
    elseif type(opts.test) == "table" then
      opts.test.config_overrides = vim.tbl_deep_extend("force", opts.test.config_overrides or {}, {
        vmArgs = "-ea -Xmx1g", -- Enable assertions and memory for tests

        -- Optional: For integration tests with Spring Boot
        -- vmArgs = "-ea -Xmx1g -Dspring.profiles.active=test",
      })
    end

    -- ========== CONFIGURATION FOR DAP MAIN CLASS ==========
    -- This improves automatic detection of main classes
    if type(opts.dap_main) == "boolean" then
      opts.dap_main = {
        config_overrides = {
          vmArgs = "-Xmx2g -XX:+UseG1GC",

          -- Optional: Add program arguments
          -- args = "${command:SpecifyProgramArgs}",
        },
      }
    elseif type(opts.dap_main) == "table" then
      opts.dap_main.config_overrides = vim.tbl_deep_extend("force", opts.dap_main.config_overrides or {}, {
        vmArgs = "-Xmx2g -XX:+UseG1GC",
      })
    end

    local original_on_attach = opts.on_attach
    opts.on_attach = function(args)
      if original_on_attach then
        original_on_attach(args)
      end

      require("config.java").java_keymaps(args.buf)
    end

    return opts
  end,
}
