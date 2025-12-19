return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters_by_ft = {
      kotlin = { "ktlint" },
      javascript = { "eslint_d", "prettier" },
      typescript = { "eslint_d", "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      --xml = { "prettier", "plugin-xml" },
      xml = { "prettier", "lemminx" },
      apex = { "prettier", "prettier-plugin-apex" },
    },
  },
}
