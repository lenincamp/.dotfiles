local M = {}

local IMPORT_EXCLUSIONS = {
  "**/node_modules/**",
  "**/.metadata/**",
  "**/archetype-resources/**",
  "**/META-INF/maven/**",
  "**/target/**",
  "**/build/**",
  "**/.gradle/**",
  "**/.idea/**",
  "**/.git/**",
  "**/dist/**",
  "**/out/**",
  "**/frontend/**",
  "**/cybo/**",
  "**/tools/**",
}

local FAVORITE_STATIC_MEMBERS = {
  "org.hamcrest.MatcherAssert.assertThat",
  "org.hamcrest.Matchers.*",
  "org.hamcrest.CoreMatchers.*",
  "org.junit.jupiter.api.Assertions.*",
  "java.util.Objects.requireNonNull",
  "java.util.Objects.requireNonNullElse",
  "org.mockito.Mockito.*",
  "org.mockito.ArgumentMatchers.*",
  "java.util.stream.Collectors.*",
  "java.util.Arrays.*",
  "java.util.Collections.*",
}

local FILTERED_TYPES = {
  "com.sun.*",
  "io.micrometer.shaded.*",
  "java.awt.*",
  "jdk.*",
  "sun.*",
}

function M.build(style_file, runtimes)
  return {
    java = {
      maven = { enabled = true, downloadSources = true, updateSnapshots = false },
      gradle = { enabled = false, downloadSources = true },
      contentProvider = { preferred = "fernflower" },
      references = { includeDecompiledSources = true },

      autobuild = { enabled = false },
      maxConcurrentBuilds = 1,

      import = {
        exclusions = vim.deepcopy(IMPORT_EXCLUSIONS),
        maven = { enabled = true },
        gradle = { enabled = false },
      },

      configuration = {
        updateBuildConfiguration = "interactive",
        runtimes = runtimes,
      },

      signatureHelp = { enabled = true, description = { enabled = true } },

      completion = {
        enabled = true,
        overwrite = false,
        guessMethodArguments = false,
        favoriteStaticMembers = vim.deepcopy(FAVORITE_STATIC_MEMBERS),
        filteredTypes = vim.deepcopy(FILTERED_TYPES),
        importOrder = { "java", "jakarta", "javax", "com", "org" },
      },

      format = {
        enabled = true,
        comments = { enabled = true },
        settings = {
          url = style_file,
          profile = "Patagonia-Style",
        },
      },

      implementationsCodeLens = { enabled = false },
      referencesCodeLens = { enabled = false },

      inlayHints = {
        parameterNames = {
          enabled = "literals",
          exclusions = {},
        },
      },

      saveActions = {
        organizeImports = true,
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
          codeStyle = "STRING_CONCATENATION",
          skipNullValues = false,
          listArrayContents = true,
        },
        hashCodeEquals = {
          useJava7Objects = true,
          useInstanceof = true,
        },
        useBlocks = true,
        addFinalForNewDeclaration = false,
        insertionLocation = "afterCursor",
      },

      project = {
        referencedLibraries = { "lib/**/*.jar" },
      },
    },
  }
end

return M