-- conform.nvim: formatter-per-filetype configuration.
-- Java uses LSP format (no external formatter needed).

local ok, conform = pcall(require, "conform")
if not ok then return end

conform.setup({
  formatters_by_ft = {
    kotlin     = { "ktlint" },
    javascript = { "eslint_d", "prettier" },
    typescript = { "eslint_d", "prettier" },
    html       = { "prettier" },
    css        = { "prettier" },
    xml        = { "prettier", "lemminx" },
    apex       = { "prettier", "prettier-plugin-apex" },
    java       = {}, -- no external formatter; handled by JDTLS LSP
  },
})
