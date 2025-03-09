return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "diff",
        "dockerfile",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "query",
        "regex",
        "tsx",
        "typescript",
        "java",
        "vim",
        "vimdoc",
        "regex",
        "sql",
        "toml",
        "xml",
        "yaml",
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "bash-language-server",
        "docker-compose-language-service",
        "dockerfile-language-server",
        "eslint-lsp",
        "hadolint",
        "java-debug-adapter",
        "java-test",
        "lua-language-server",
        "prettier",
        "shellcheck",
        "shfmt",
        "sonarlint-language-server",
        "sqlfluff",
        "stylua",
        "tailwindcss-language-server",
        "taplo",
        "typescript-language-server",
        "yaml-language-server",
      },
    },
  },
  -- Incremental rename
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },
  -- {
  --   "nvim-cmp",
  --   dependencies = { "hrsh7th/cmp-emoji" },
  --   opts = function(_, opts)
  --     table.insert(opts.sources, { name = "emoji" })
  --   end,
  -- },
  {
    "rmagatti/goto-preview",
    event = "BufEnter",
    config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
    default_mappings = true,
  },
  {
    "mg979/vim-visual-multi",
  },
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
          vim.fn.expand("$MASON/share/sonarlint-analyzers/sonarjava.jar"),
        },
        -- All settings are optional
        settings = {
          -- The default for sonarlint is {}, this is just an example
          sonarlint = {},
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
