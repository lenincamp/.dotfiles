return {
  {
    "danarth/sonarlint.nvim",
    lazy = true,
    ft = { "java" },
    opts = {
      server = {
        cmd = {
          "sonarlint-language-server",
          -- Ensure that sonarlint-language-server uses stdio channel
          "-stdio",
          "-analyzers",
          -- paths to the analyzers you need, using those for python and java in this example
          -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarpython.jar"),
          -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarcfamily.jar"),
          "/Users/lcampoverde/.local/share/nvim/mason/packages/sonarlint-language-server/extension/analyzers/sonarjava.jar",
          -- vim.fn.expand(
          --   os.getenv("HOME")
          --     .. "/.local/share/nvim/mason/packages/sonarlint-language-server/extension/analyzers/sonarjavasymbolicexecution.jar"
          -- ),
        },
        -- All settings are optional
        settings = {
          -- The default for sonarlint is {}, this is just an example
          sonarlint = {
            test = "test",
          },
        },
      },
      filetypes = {
        -- Tested and working
        -- "python",
        -- "cpp",
        -- Requires nvim-jdtls, otherwise an error message will be printed
        "java",
      },
    },
  },
}
