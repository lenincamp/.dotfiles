local ok, mason = pcall(require, "mason")
if not ok then return end

mason.setup({
  ensure_installed = {
    -- LSP servers
    "apex-language-server",
    "bash-language-server",
    "docker-compose-language-service",
    "dockerfile-language-server",
    "eslint-lsp",
    "kotlin-language-server",
    "lemminx",
    "lua-language-server",
    "lwc-language-server",
    "marksman",
    "sonarlint-language-server",
    "tailwindcss-language-server",
    "taplo",
    "vim-language-server",
    "visualforce-language-server",
    "vtsls",
    "yaml-language-server",
    -- Java DAP
    "java-debug-adapter",
    "java-test",
    "jdtls",
    -- Formatters / linters
    "eslint_d",
    "hadolint",
    "ktlint",
    "prettier",
    "shellcheck",
    "shfmt",
    "sqlfluff",
    "stylua",
    -- Tools
    "tree-sitter-cli",
  },
})
