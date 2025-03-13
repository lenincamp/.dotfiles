return {
  url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
  lazy = true,
  ft = { "java" },
  config = function()
    require("sonarlint").setup({
      server = {
        cmd = {
          "java",
          "-jar",
          vim.fn.expand("$MASON/packages/sonarlint-language-server/extension/server/sonarlint-ls.jar"),
          "-stdio",
          "-analyzers",
          -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarpython.jar"),
          vim.fn.expand(
            "$HOME/.local/share/nvim/mason/packages/sonarlint-language-server/extension/analyzers/sonarjava.jar"
          ),
          -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarhtml.jar"),
          -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarxml.jar"),
          -- vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjs.jar"),
        },
      },
      filetypes = {
        -- Tested and working
        -- "python",
        -- Requires nvim-jdtls, otherwise an error message will be printed
        "java",
        -- "html",
        -- "xml",
        -- "js",
      },
    })
  end,
}
